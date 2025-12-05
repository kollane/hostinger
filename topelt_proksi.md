# Topelt Proksi Analüüs: Host + Docker

## Lühike vastus

**Ei, see tavaliselt EI tekita probleeme**, kuid on nüansse:

## Detailne analüüs

### ✅ Mis töötab hästi:

**1. Host proksi + Docker build-time proksi (ARG)**
```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
RUN apt-get update && apt-get install -y curl
```

```bash
# Host level
export HTTP_PROXY=http://proxy:911

# Docker build kasutab host'i väärtusi
docker build --build-arg HTTP_PROXY=$HTTP_PROXY .
```

**Tulemus:** ✅ Töötab sujuvalt
- Docker build stage'id kasutavad proksi väärtusi ARG'idest
- Host proksi ei sega (Docker ignoreerib host'i environment'i build'i ajal)

---

### ⚠️ Potentsiaalsed konfliktid:

**Stsenaarium 1: Topelt proksi (kui mõlemad on erinevad)**

```bash
# Host level
export HTTP_PROXY=http://proxy-A:8080

# Docker build
docker build --build-arg HTTP_PROXY=http://proxy-B:3128 .
```

**Tulemus:** ✅ Docker ARG võidab (host'i ignoreeritakse)

---

**Stsenaarium 2: Docker daemon proksi + build-time proksi**

```json
// /etc/docker/daemon.json
{
  "proxies": {
    "http-proxy": "http://proxy-daemon:911"
  }
}
```

```bash
docker build --build-arg HTTP_PROXY=http://proxy-build:911 .
```

**Tulemus:** ⚠️ Sõltub operatsioonist
- `RUN apt-get install`: Kasutab `--build-arg` proksi
- `docker pull` (image'ite tõmbamine): Kasutab daemon proksi
- Mõlemad võivad olla erinevad, ei tekita konflikti (erinevad kontekstid)

---

**Stsenaarium 3: Multi-stage build + proksi pärimine**

```dockerfile
# Stage 1
ARG HTTP_PROXY=http://proxy:911
RUN npm install

# Stage 2
FROM nginx:alpine
# HTTP_PROXY ei päri automaatselt!
```

**Tulemus:** ⚠️ Iga stage vajab eraldi ARG deklaratsiooni

**Lahendus:**
```dockerfile
# Stage 1
ARG HTTP_PROXY
RUN npm install

# Stage 2
ARG HTTP_PROXY  # ← Pead uuesti deklareerima!
RUN apk add --no-cache curl
```

---

### ❌ Probleemid, mis VÕIVAD tekkida:

**1. Runtime konteiner pärib host proksi (kui ei filtreeri)**

```bash
# Host level
export HTTP_PROXY=http://proxy:911

# Docker run ilma filtreeritud env'ita
docker run -it node:20-alpine sh
# Konteiner VÕIB pärida host'i HTTP_PROXY (sõltub Docker versioonist)
```

**Probleem:** Runtime konteineris pole proksi vaja (või on vale proksi)

**Lahendus:**
```bash
# Filtreeri proksi väärtused runtime'il
docker run --env HTTP_PROXY= --env HTTPS_PROXY= node:20-alpine
```

Või compose fail:
```yaml
services:
  app:
    environment:
      - HTTP_PROXY=  # Tühista proksi runtime'il
```

---

**2. Java/Gradle + Docker proksi konflikt**

```dockerfile
ARG HTTP_PROXY=http://proxy:911

# Gradle võib ignoreerida HTTP_PROXY, vajab Java süsteemiparameetreid
RUN ./gradlew build  # ← Võib ebaõnnestuda!
```

**Lahendus:**
```dockerfile
ARG HTTP_PROXY=http://proxy:911
ENV GRADLE_OPTS="-Dhttp.proxyHost=proxy -Dhttp.proxyPort=911"
RUN ./gradlew build
```

---

## Best Practices 🎯

### ✅ DO:

```dockerfile
# 1. Deklareeri ARG igas stage'is eraldi
FROM node:20-alpine AS builder
ARG HTTP_PROXY
ARG HTTPS_PROXY
RUN npm install

FROM nginx:alpine
ARG HTTP_PROXY  # ← Uuesti vajalik!
RUN apk add curl
```

```bash
# 2. Build-time: kasuta ARG'e
docker build \
  --build-arg HTTP_PROXY=$HTTP_PROXY \
  --build-arg HTTPS_PROXY=$HTTPS_PROXY \
  -t app:latest .

# 3. Runtime: ära kasuta proksi (kui pole vaja)
docker run -e HTTP_PROXY= -e HTTPS_PROXY= app:latest
```

---

### ❌ DON'T:

```dockerfile
# ❌ Ära hardcode proksi Dockerfile'is
ENV HTTP_PROXY=http://proxy:911  # ← Paha!
# Probleem: Ei saa muuta ilma rebuild'ita

# ✅ Kasuta ARG'e
ARG HTTP_PROXY
# Build käsus: --build-arg HTTP_PROXY=...
```

---

## Kokkuvõte

| Stsenaarium | Tulemus | Selgitus |
|-------------|---------|-----------|
| Host proksi + Docker ARG | ✅ OK | Docker ARG võidab, host ignoreeritakse |
| Docker daemon proksi + ARG | ✅ OK | Erinevad kontekstid (pull vs build) |
| Multi-stage ilma ARG deklaratsioonita | ❌ Fail | Iga stage vajab ARG'i |
| Runtime pärib host proksi | ⚠️ Risk | Filtreeri env runtime'il |
| Java/Gradle + HTTP_PROXY | ⚠️ Nõuab GRADLE_OPTS | Java ignoreerib HTTP_PROXY |

---

## Selle repo kontekstis

Vaadates `setup.sh` faile:

```bash
# Lab 1 & Lab 2 setup.sh
HTTP_PROXY="${HTTP_PROXY:-}"
HTTPS_PROXY="${HTTPS_PROXY:-}"

docker build \
  --build-arg HTTP_PROXY="$HTTP_PROXY" \
  --build-arg HTTPS_PROXY="$HTTPS_PROXY" \
  ...
```

**Hinnang:** ✅ **Hästi tehtud!**
- Host proksi ja Docker ARG ei konflikteeri
- Vaikeväärtus `:-""` võimaldab proksi puudumist
- Runtime'il proksi ei kasutata (nagu peabki)

**Ainus soovitus:** Lisa dokumentatsiooni selgitama, et runtime'il proksi POLE vaja (vt `08B-Nginx-Reverse-Proxy` peatükk CORS kontekstis).

---

**Viimane uuendus:** 2025-12-05
