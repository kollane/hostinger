# Proksi selgitus: Build-time vs Runtime

## Põhiküsimus

**Kas build stage'is konteiner saab proksi kätte ja pöördub ise interneti poole, host'ist ükskõik?**

**Vastus:** Jah, täpselt! Aga laseme lahti seletada täpsemalt, sest siin on mitu kihti:

---

## Build-time vs Runtime

### Build-time (docker build)

```dockerfile
FROM node:20-alpine AS builder
ARG HTTP_PROXY=http://proxy:911
ARG HTTPS_PROXY=http://proxy:912

RUN npm install  # ← Kasutab proksi interneti päringuteks
```

**Mis juhtub:**
1. Docker build protsess töötab **host'i peal** (mitte konteineris!)
2. `RUN` käsud täidetakse **ajutistes konteinerites**
3. Need ajutised konteinerid kasutavad `ARG HTTP_PROXY` väärtust
4. Pärast `RUN` käsku konteiner kustutatakse, jääb ainult **layer** (kiht)

**Tulemus:**
- ✅ Build ajal konteiner pöördub internetti läbi proksi
- ✅ Host'i proksi seadistus on **täiesti ükskõik** (Docker ignoreerib seda)
- ✅ Ainult `--build-arg` väärtused loevad

---

### Runtime (docker run / docker-compose up)

```bash
docker run -p 3000:3000 user-service:1.0
```

**Mis juhtub:**
1. Konteiner käivitatakse ja töötab **isoleeritult**
2. Konteiner kasutab **Docker võrku** (network)
3. Konteiner pöördub internetti läbi **host'i võrguliidese**

**Proksi pole vaja, sest:**
- ✅ Konteiner kasutab host'i võrguliidest (Docker NAT)
- ✅ Host tegeleb proksi päringutega (kui host'il on proksi seadistatud)
- ✅ Konteiner lihtsalt teeb HTTP/HTTPS päringuid, host edastab

---

## Näide

### Stsenaarium: Intel korporatiivne võrk

**Host masinas:**
```bash
# Host'i proksi seadistus (Intel proxy)
export HTTP_PROXY=http://proxy-chain.intel.com:911
export HTTPS_PROXY=http://proxy-chain.intel.com:912
```

**Build-time:**
```bash
# Ehitame Node.js rakenduse
docker build \
  --build-arg HTTP_PROXY=$HTTP_PROXY \
  --build-arg HTTPS_PROXY=$HTTPS_PROXY \
  -t user-service:1.0 \
  -f Dockerfile.optimized.proxy .
```

```dockerfile
FROM node:20-alpine AS builder
ARG HTTP_PROXY
ARG HTTPS_PROXY

# npm install vajab internetti (npmjs.org)
# Kasutab HTTP_PROXY=http://proxy-chain.intel.com:911
RUN npm install
# ← Ajutine konteiner pöördub npmjs.org läbi Intel proksi
# ← Pärast npm install'i konteiner KUSTUTATAKSE
# ← Jääb ainult layer: /app/node_modules/
```

**Runtime:**
```bash
# Käivitame konteineri (ilma proksi ENV muutujateta!)
docker run -p 3000:3000 user-service:1.0
```

**Mis juhtub runtime'il:**
- Konteiner töötab **isoleeritult**
- Kui konteiner teeb HTTP päringu välisesse API'sse (nt `fetch('https://api.example.com')`):
  1. Konteiner saadab päringu → Docker võrgu bridge
  2. Docker bridge edastab → Host'i võrguliides
  3. **Host'i proksi seadistus hoolitseb edasi** → Intel proxy → internet
  4. Vastus tuleb tagasi samast teest

**Konteiner EI TEA proksi olemasolust!**
- Konteineris **pole** `HTTP_PROXY` environment muutujat
- Konteiner lihtsalt teeb `fetch('https://...')` ja see töötab
- Host OS tegeleb proksi suhtlusega

---

## Võrdlus: Host proksi vs Docker ARG proksi

| Aspekt | Build-time (ARG) | Runtime (Host proksi) |
|--------|------------------|----------------------|
| **Kus töötab?** | Ajutised build konteinerid | Töötav konteiner |
| **Kes kasutab proksi?** | `RUN npm install`, `RUN apt-get`, jne | Host OS (konteiner ei tea) |
| **Kas konteiner teab proksi olemasolust?** | ✅ Jah (`ARG HTTP_PROXY` on nähtav) | ❌ Ei (kui ENV'i pole lisatud) |
| **Kas host'i proksi mõjutab?** | ❌ Ei (Docker ignoreerib) | ✅ Jah (host edastab liikluse) |
| **Millal vajalik?** | Pakettide allalaadimisel build'i ajal | Väliste API'de poole pöördumisel runtime'il |

---

## Konkreetne näide: npm install

### Build-time:

```dockerfile
ARG HTTP_PROXY=http://proxy:911

# Build konteineris (ajutine, kustutatakse pärast)
RUN npm install
# Protsess:
# 1. npm pöördub registry.npmjs.org
# 2. Kasutab HTTP_PROXY=http://proxy:911
# 3. Proxy edastab päringu npmjs.org
# 4. Paketid laetakse alla
# 5. Konteiner kustutatakse, jääb /app/node_modules/ layer
```

### Runtime:

```bash
docker run user-service:1.0
# Konteineris:
# - node_modules/ on juba olemas (build'itud)
# - npm install'i EI käivitata
# - Kui rakendus teeb fetch('https://api.example.com'):
#   → Docker võrk → Host võrguliides → Host proksi → internet
# - Konteiner EI TEA proksi olemasolust!
```

---

## Erandid: Millal runtime vajab proksi?

### Kui rakendus ise teeb väliseid HTTP päringuid JA host'il pole proksi:

```javascript
// user-service runtime kood
const response = await fetch('https://external-api.com/data');
```

**Tavaliselt:**
- ✅ Host'il on proksi seadistus → töötab automaatselt
- ✅ Host edastab liikluse läbi proksi

**Aga kui host'il POLE proksi:**
- ⚠️ Konteiner ei saa otse internetti (kui firewall blokeerib)
- ❌ Lahendus: Lisa `HTTP_PROXY` ENV konteinerisse

```dockerfile
# AINULT kui host'il pole proksi seadistust!
ENV HTTP_PROXY=http://proxy:911
ENV HTTPS_PROXY=http://proxy:912
```

Või docker-compose.yml:
```yaml
services:
  user-service:
    environment:
      - HTTP_PROXY=http://proxy:911  # Konteiner kasutab proksi
```

---

## Kokkuvõte 🎯

**Build-time:**
- ✅ `--build-arg HTTP_PROXY` on vajalik `npm install`, `apt-get`, jne jaoks
- ✅ Host'i proksi seadistus on **täiesti ükskõik**
- ✅ Docker ARG väärtused määravad proksi

**Runtime:**
- ✅ Host'i proksi seadistus **edastab liikluse** automaatselt
- ✅ Konteiner **ei tea** proksi olemasolust (kui ENV pole lisatud)
- ✅ Töötab "lihtsalt" (host hoolitseb proksi eest)

**Selle repo kontekstis:**
- Lab 1 & Lab 2 `setup.sh` kasutavad `--build-arg HTTP_PROXY` ✅
- Runtime'il proksi ENV **pole lisatud** ✅ (nagu peabki!)
- Host'i proksi seadistus edastab runtime liikluse (kui vaja)

---

## Visualiseerimine

### Build-time liiklus:
```
npm install päring
    ↓
Ajutine build konteiner (ARG HTTP_PROXY=proxy:911)
    ↓
Docker daemon
    ↓
Proxy server (proxy:911)
    ↓
Internet (npmjs.org)
    ↓
Vastus tagasi → layer salvestatakse → konteiner kustutatakse
```

### Runtime liiklus:
```
Rakenduse HTTP päring
    ↓
Töötav konteiner (ENV HTTP_PROXY pole!)
    ↓
Docker bridge network
    ↓
Host OS võrguliides (host'i HTTP_PROXY=proxy:911)
    ↓
Proxy server (proxy:911)
    ↓
Internet (api.example.com)
    ↓
Vastus tagasi samast teest
```

---

**Viimane uuendus:** 2025-12-05
