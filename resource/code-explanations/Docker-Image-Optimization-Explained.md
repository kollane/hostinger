# Docker Image Optimeerimise 5 Eesmärki

Docker image optimeerimise peamised eesmärgid tootmiskõlbuliku rakenduse jaoks.

---

## 1️⃣ Kiire Arendusprotsess - Layer Caching

### Probleem: Aeglane rebuild

**Mitteoptimeeritud Dockerfile:**
```dockerfile
FROM node:22-slim
WORKDIR /app

# ❌ PROBLEEM: Kopeerin koodi enne sõltuvusi
COPY . .                    # ← Muudad üht JS faili → see kiht muutub
RUN npm install             # ← npm install käib ALATI uuesti! (30-60s)

CMD ["node", "server.js"]
```

**Miks see on aeglane?**
- Docker salvestab iga käsu (RUN, COPY, etc) eraldi **kihina (layer)**
- Docker kasutab vahemälu (cache): kui kiht ei muutu, kasutatakse cached versiooni
- **Aga:** kui `COPY . .` muutub (muutsid koodi), siis **kõik järgnevad kihid** rebuilditakse!
- Tulemus: npm install käib IGAL build'il uuesti, isegi kui package.json ei muutunud

### Lahendus: Sõltuvused eraldi kihina

**Optimeeritud Dockerfile:**
```dockerfile
FROM node:22-slim
WORKDIR /app

# ✅ LAHENDUS: Kopeeri sõltuvuste failid ENNE koodi
COPY package*.json ./       # ← Muutub HARVA (kiht cached)
RUN npm install             # ← Cached! Rebuild 5 sekundit

COPY . .                    # ← Muutub TIHTI, aga kiire (ei käivita npm install uuesti)

CMD ["node", "server.js"]
```

**Miks see on kiire?**
- package.json muutub harva (ainult kui lisad/uuendad sõltuvusi)
- npm install kiht on **cached** → ei käivita uuesti
- Muudad lähtekoodi (server.js) → ainult COPY . . käib uuesti (millisekund!)

### Mõõdetav mõju

**Esimene build (ilma cache'ita):**
- Mitteoptimeeritud: 45 sekundit
- Optimeeritud: 50 sekundit (+5s, sest 2 COPY käsku)

**Rebuild (muutsid server.js):**
- Mitteoptimeeritud: 45 sekundit (npm install uuesti!)
- Optimeeritud: 2 sekundit (ainult COPY . .)

**Tulemus:** Arendaja muudab koodi → rebuild **95% kiirem** (45s → 2s)

### Praktiline näide

**Tüüpiline arendusprotsess:**
1. Muuda koodi (nt. lisa endpoint)
2. Rebuild Docker image
3. Käivita konteiner
4. Testi
5. Korda 1-4 (10-50 korda päevas!)

**Ilma layer caching'uta:** 10 rebuild × 45s = **7.5 minutit ootamist**
**Layer caching'uga:** 10 rebuild × 2s = **20 sekundit ootamist**

**Ajakasu päevas:** 7-8 minutit (× 5 päeva = 35-40 min nädalas!)

---

## 2️⃣ Väiksem Image Suurus - Multi-stage Build

### Probleem: Liiga suur runtime image

**Mitteoptimeeritud Dockerfile (Java):**
```dockerfile
FROM gradle:8-jdk21-alpine
WORKDIR /app

# Kopeeri kõik (source code + build tools)
COPY . .

# Ehita JAR
RUN gradle bootJar

# Käivita JAR
CMD ["java", "-jar", "build/libs/app.jar"]
```

**Miks see on suur?**
- Runtime image sisaldab:
  - ✅ JRE (Java Runtime Environment) - VAJALIK (200MB)
  - ❌ JDK (Java Development Kit) - EI OLE VAJALIK (400MB)
  - ❌ Gradle - EI OLE VAJALIK (150MB)
  - ❌ Source code - EI OLE VAJALIK (50MB)
- **Kokku:** ~800MB image, millest ainult 25% on runtime'is vajalik!

**Turvarisk:**
- Build tools (gradle, javac) runtime'is → võimalik kompileerida pahavara
- Source code runtime'is → intellektuaalne omand leak'ib

### Lahendus: Multi-stage Build

**Optimeeritud Dockerfile (Java):**
```dockerfile
# syntax=docker/dockerfile:1.4

# =====================================
# STAGE 1: BUILD (JDK + Gradle)
# =====================================
FROM gradle:8-jdk21-alpine AS builder
WORKDIR /app

# Kopeeri Gradle failid (dependency caching)
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Lae sõltuvused (cached eraldi kihina)
RUN gradle dependencies --no-daemon

# Kopeeri source code ja ehita JAR
COPY src ./src
RUN gradle bootJar --no-daemon

# =====================================
# STAGE 2: RUNTIME (ainult JRE)
# =====================================
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Kopeeri AINULT JAR builder stage'ist
COPY --from=builder /app/build/libs/*.jar app.jar

# Käivita JAR
CMD ["java", "-jar", "app.jar"]
```

**Miks see on väike?**
- **Stage 1 (builder):** 800MB - sisaldab JDK + Gradle + source
  - Kasutatakse AINULT build'imiseks
  - Ei jää lõplikku image'isse!
- **Stage 2 (runtime):** 250MB - sisaldab AINULT JRE + JAR
  - Ainult see stage eksporditakse
  - Pole build tools'e ega source code'i

### Mõõdetav mõju

**Image suurused:**
- Mitteoptimeeritud (single-stage): 800MB
- Optimeeritud (multi-stage): 250MB
- **Vähendamine:** 550MB (-69%)

**Deployment mõju (Kubernetes 3 replicat):**
- Mitteoptimeeritud: 3 × 800MB = 2.4GB allalaadida
- Optimeeritud: 3 × 250MB = 750MB allalaadida
- **Aeg säästetud (100Mbps võrk):** ~3 minutit

**Kõvaketas (10 microservice'it):**
- Mitteoptimeeritud: 10 × 800MB = 8GB
- Optimeeritud: 10 × 250MB = 2.5GB
- **Kokkuhoid:** 5.5GB (vähem layer cache ruumi vaja)

### Node.js vs Java multi-stage erinevus

**Node.js:**
```dockerfile
# Stage 1: Dependencies
FROM node:22-slim AS dependencies
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime (sama base image!)
FROM node:22-slim
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
```

**Miks Node.js multi-stage ei vähenda suurust?**
- Mõlemad stage'id kasutavad SAMA base image'it (node:22-slim)
- Suuruse vähendamine: ~0% (mõlemad ~305MB)
- **Aga:** Kihtide vahemälu on PAREM (dependencies eraldi kihis)

**Java vs Node.js:**
- Java: JDK (800MB) → JRE (250MB) = **69% väiksem** ✅
- Node.js: node:22-slim → node:22-slim = **0% väiksem** ⚠️

**Õppetund:** Multi-stage build annab Node.js'ile **kiiremad rebuildid**, aga mitte väiksemat image'it

---

## 3️⃣ Turvalisus - Non-root User + Health Checks

### Probleem: Rakendus töötab root'ina

**Mitteoptimeeritud Dockerfile:**
```dockerfile
FROM node:22-slim
WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

CMD ["node", "server.js"]
# ↑ Töötab root kasutajana (UID 0)!
```

**Miks see on ohtlik?**
- Konteiner töötab **root** kasutajana (UID 0)
- Kui ründaja saab konteineri üle:
  - ❌ Võib kirjutada süsteemifaile host masinas (kui volume mount on)
  - ❌ Võib escalada õigusi (privilege escalation)
  - ❌ Võib kompromiteerida teisi konteinereid
- **OWASP Top 10:** "Security Misconfiguration"

### Lahendus 1: Non-root User

**Optimeeritud Dockerfile (Debian/Ubuntu base):**
```dockerfile
FROM node:22-slim
WORKDIR /app

# Kopeeri ja installi sõltuvused (veel root'ina, ok)
COPY package*.json ./
RUN npm ci --only=production

# Kopeeri rakenduse kood
COPY . .

# ✅ LOO MITTE-JUURKASUTAJA
RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs nodejs

# ✅ MUUDA FAILIDE OMANIK
RUN chown -R nodejs:nodejs /app

# ✅ LÜLITU MITTE-JUURKASUTAJALE
USER nodejs:nodejs

EXPOSE 3000
CMD ["node", "server.js"]
```

**Alpine Linux variant:**
```dockerfile
FROM node:22-alpine
WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# ✅ Alpine kasutab adduser/addgroup
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs

RUN chown -R nodejs:nodejs /app

USER nodejs:nodejs

EXPOSE 3000
CMD ["node", "server.js"]
```

**Miks see on turvalisem?**
- Rakendus töötab UID 1001 (mitte-root)
- Ei saa kirjutada süsteemifaile
- Väiksem attack surface

### Lahendus 2: Health Check

**Ilma health check'ita:**
```dockerfile
FROM node:22-slim
WORKDIR /app

# ... install dependencies, copy code ...

CMD ["node", "server.js"]
# ❌ Docker ei tea, kas rakendus töötab korrektselt!
```

**Probleem:**
- Konteiner on "Up", aga rakendus ei vasta (hang/deadlock)
- Docker Compose/Kubernetes ei tea, et midagi on valesti
- Liiklus suunatakse vigasesse konteinerisse

**Health check'iga:**
```dockerfile
FROM node:22-slim
WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs nodejs
RUN chown -R nodejs:nodejs /app

USER nodejs:nodejs

EXPOSE 3000

# ✅ TERVISEKONTROLL
HEALTHCHECK --interval=30s \      # Kontrolli iga 30 sekundi tagant
            --timeout=3s \         # Maksimaalne vastuse aeg
            --start-period=10s \   # Lubab 10s startup aega
            --retries=3 \          # 3 ebaõnnestumist → unhealthy
  CMD node healthcheck.js || exit 1

CMD ["node", "server.js"]
```

**healthcheck.js fail:**
```javascript
const http = require('http');

const options = {
  host: 'localhost',
  port: 3000,
  path: '/health',
  timeout: 2000
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    process.exit(0);  // Healthy
  } else {
    process.exit(1);  // Unhealthy
  }
});

req.on('error', () => process.exit(1));  // Unhealthy
req.end();
```

### Mõõdetav mõju

**Turvalisus:**
- Root exploit võimalus: 80% → 20% (limited user permissions)
- Container escape: Raskem (pole root õigusi)

**Monitooring:**
- Docker Compose:
  ```bash
  docker ps
  # STATUS
  # Up (healthy)  ← Näed kohe, et rakendus töötab!
  ```
- Kubernetes: Readiness/Liveness probe kasutab HEALTHCHECK tulemust
- Automaatne restart: Kui 3 healthcheck ebaõnnestub → restart

**Näide stsenaarium:**
1. Rakendus hangub (memory leak, deadlock)
2. HEALTHCHECK ebaõnnestub 3 korda (30s × 3 = 90s)
3. Docker restart'ib konteineri automaatselt
4. **Downtime:** 90s (ilma health check'ita: ∞)

---

## 4️⃣ Portaabelsus - Corporate Proxy Tugi

### Probleem: Dockerfile ei tööta corporate võrgus

**Mitteoptimeeritud Dockerfile:**
```dockerfile
FROM node:22-slim
WORKDIR /app

COPY package*.json ./
RUN npm install  # ❌ EBAÕNNESTUB corporate võrgus!
# Error: getaddrinfo ENOTFOUND registry.npmjs.org

COPY . .
CMD ["node", "server.js"]
```

**Miks see ebaõnnestub?**
- Corporate võrk (nt. Intel, bank, government) blokeerib otsese interneti ligipääsu
- Kõik HTTP/HTTPS päringud peavad minema läbi proksi serveri (nt. `http://proxy-chain.intel.com:911`)
- npm install ei tea proksi aadressist → ei saa packages'eid alla laadida

**Vale lahendus: Hardcoded proxy**
```dockerfile
FROM node:22-slim
WORKDIR /app

# ❌ VALE: Hardcoded proxy
ENV HTTP_PROXY=http://proxy-chain.intel.com:911
ENV HTTPS_PROXY=http://proxy-chain.intel.com:912

COPY package*.json ./
RUN npm install

COPY . .
CMD ["node", "server.js"]
```

**Miks see on halb?**
- ✅ Töötab Intel võrgus
- ❌ **EI tööta AWS/GCP/Azure** (pole proxy'd!)
- ❌ Proxy **leak'ib runtime'i** → rakendus proovib kasutada Intel proxy'd production'is
- ❌ **Security risk:** Proxy credentials võivad olla URL'is (`http://user:pass@proxy:911`)

### Lahendus: ARG-põhine proxy (portaabel)

**Optimeeritud Dockerfile:**
```dockerfile
# syntax=docker/dockerfile:1.4

# ✅ ARG deklaratsioonid ENNE FROM (globaalsed)
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG NO_PROXY=""

# Stage 1: Dependencies
FROM node:22-slim AS dependencies

# ✅ ENV AINULT selles stage'is
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY}

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production  # Kasutab HTTP_PROXY, kui määratud

# Stage 2: Runtime
FROM node:22-slim
WORKDIR /app

# ✅ PROXY EI OLE SIIN! Uus FROM nullib ENV muutujad
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs nodejs
RUN chown -R nodejs:nodejs /app

USER nodejs:nodejs

EXPOSE 3000
CMD ["node", "server.js"]
```

**Kuidas kasutada?**

**Intel võrgus (proksi keskkonnas):**
```bash
docker build \
  --build-arg HTTP_PROXY=http://proxy-chain.intel.com:911 \
  --build-arg HTTPS_PROXY=http://proxy-chain.intel.com:912 \
  -t user-service:1.0 \
  .
```

**AWS/GCP/Azure (ilma proksita):**
```bash
docker build -t user-service:1.0 .
# ARG vaikeväärtused on "" → töötab ilma proksita!
```

**Miks see on parem?**
- ✅ **Portaabel:** Sama Dockerfile töötab mõlemas keskkonnas
- ✅ **Turvaline:** Proxy EI leak runtime'i (multi-stage eraldab)
- ✅ **Production-ready:** Image töötab AWS/GCP ilma Intel proksita

### Java/Gradle eripära

**Gradle EI kasuta HTTP_PROXY otse!**

**Vale lähenemine:**
```dockerfile
ARG HTTP_PROXY=""
ENV HTTP_PROXY=${HTTP_PROXY}

RUN gradle bootJar  # ❌ Gradle ignoorib HTTP_PROXY!
```

**Õige lähenemine (GRADLE_OPTS):**
```dockerfile
# syntax=docker/dockerfile:1.4

ARG HTTP_PROXY=""

FROM gradle:8-jdk21-alpine AS builder
ENV HTTP_PROXY=${HTTP_PROXY}

WORKDIR /app
COPY build.gradle settings.gradle ./

# ✅ Gradle vajab GRADLE_OPTS
RUN if [ -n "$HTTP_PROXY" ]; then \
        PROXY_HOST=$(echo "$HTTP_PROXY" | sed -e 's|http://||' -e 's|:[0-9]*$||'); \
        PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
        export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT"; \
        gradle dependencies --no-daemon; \
    else \
        gradle dependencies --no-daemon; \
    fi

COPY src ./src
RUN gradle bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine
# Runtime on clean (proxy pole siin)
COPY --from=builder /app/build/libs/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

### Mõõdetav mõju

**Portaabelsus:**
- Sama Dockerfile töötab 3 keskkonnas:
  1. ✅ Intel corporate võrk (proxy)
  2. ✅ AWS/GCP/Azure (ilma proksita)
  3. ✅ Arendaja masinas (ilma proksita)

**Deployment:**
- Ilma ARG proxy'ta: 2 erinevat Dockerfile'i (Intel vs Cloud)
- ARG proxy'ga: 1 Dockerfile (portaabel!)

**Turvarisk vähenemine:**
- Proxy leak runtime'i: 0% (multi-stage eraldab)
- Credentials leak: 0% (ARG on build-time ainult)

---

## 5️⃣ CI/CD Kiirus - Reproducible Builds

### Probleem: Mittedeterministlikud build'id

**Mitteoptimeeritud Dockerfile:**
```dockerfile
FROM node:22-slim
WORKDIR /app

COPY package.json ./  # ❌ Ainult package.json, pole package-lock.json!
RUN npm install       # ❌ Installib UUSIMAD versioonid!

COPY . .
CMD ["node", "server.js"]
```

**Probleem:**
- `npm install` (ilma lock file'ita) installib UUSIMAD sõltuvuste versioonid
- **Täna:** express@4.18.2
- **Homme:** express@4.18.3 (uus patch release)
- **Tulemus:** Eri build'id annavad ERINEVAID images'eid!

**Miks see on halb?**
- ❌ **Development vs Production:** Image development'is ≠ image production'is
- ❌ **Debugging:** "Töötab minu masinas, aga mitte production'is"
- ❌ **Rollback:** Rollback versioonile v1.2.3 võib tuua ERINEVAID sõltuvusi
- ❌ **CI/CD:** Cache ei tööta (sõltuvused muutuvad IGAL build'il)

### Lahendus 1: package-lock.json (Node.js)

**Optimeeritud Dockerfile:**
```dockerfile
FROM node:22-slim
WORKDIR /app

# ✅ Kopeeri MÕLEMAD failid
COPY package*.json ./

# ✅ npm ci (mitte npm install!)
RUN npm ci --only=production

COPY . .

USER nodejs:nodejs
CMD ["node", "server.js"]
```

**npm ci vs npm install:**

| Aspekt | npm install | npm ci |
|--------|-------------|--------|
| Kasutab package-lock.json? | ⚠️ Jah, aga uuendab seda | ✅ Jah, RANGELT |
| Deterministlik? | ❌ Ei (installib uuemaid) | ✅ Jah (täpselt package-lock) |
| Kiirem CI/CD's? | ❌ Aeglane (kontrollib updates) | ✅ Kiire (skip updates) |
| Production'ile? | ❌ EI SOOVITATUD | ✅ SOOVITATAV |

**npm ci garanteerib:**
- Täpselt SAMA sõltuvused igal build'il
- Sama express versioon (4.18.2), mitte uuem (4.18.3)
- Reproducible builds

### Lahendus 2: Gradle Lock File (Java)

**Gradle lockfile genereerimise:**
```bash
# Genereeri gradle.lockfile
gradle dependencies --write-locks
```

**build.gradle konfiguratsioon:**
```gradle
dependencyLocking {
    lockAllConfigurations()
}
```

**Dockerfile:**
```dockerfile
FROM gradle:8-jdk21-alpine AS builder
WORKDIR /app

COPY build.gradle settings.gradle gradle.lockfile ./
COPY gradle ./gradle

# ✅ --refresh-dependencies uuendab cache'i, aga respekteerib lockfile'i
RUN gradle dependencies --no-daemon --refresh-dependencies

COPY src ./src
RUN gradle bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine
COPY --from=builder /app/build/libs/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

### Mõõdetav mõju CI/CD's

**Stsenaarium: GitHub Actions pipeline (10 build'i päevas)**

**Ilma reproducible builds'ita:**
```yaml
# .github/workflows/build.yml
jobs:
  build:
    - docker build -t app:latest .  # npm install
    # ❌ Cache miss IGAL build'il (sõltuvused muutuvad)
    # Aeg: 3 minutit × 10 = 30 minutit
```

**Reproducible builds'iga:**
```yaml
jobs:
  build:
    - docker build -t app:latest .  # npm ci
    # ✅ Cache hit (package-lock.json ei muutu)
    # Aeg: 30 sekundit × 10 = 5 minutit
```

**Ajakasu:** 25 minutit päevas = **2 tundi nädalas**!

### Docker Layer Cache CI/CD's

**GitHub Actions näide:**
```yaml
name: Build Docker Image

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      # ✅ Cache Docker layers
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Build
        uses: docker/build-push-action@v4
        with:
          context: .
          cache-from: type=gha  # GitHub Actions cache
          cache-to: type=gha,mode=max
          tags: user-service:latest
```

**Tulemus:**
- **Esimene build:** 3 minutit (pole cache'i)
- **Järgmised build'id (muutsid koodi):** 30 sekundit (sõltuvused cached!)
- **Ajakasu:** 2.5 minutit IGAL build'il

### Reprodutseeritavuse kontrollimine

**Test: Ehita kaks korda, võrdle**
```bash
# Build 1
docker build -t test:v1 .
IMAGE1=$(docker inspect test:v1 --format='{{.Id}}')

# Build 2 (sama kood, sama Dockerfile)
docker build -t test:v2 .
IMAGE2=$(docker inspect test:v2 --format='{{.Id}}')

# Võrdle
if [ "$IMAGE1" = "$IMAGE2" ]; then
    echo "✅ Reproducible! Sama image ID"
else
    echo "❌ EI OLE reproducible! Erinevad image ID'd"
fi
```

**Reproducible build eeldused:**
- ✅ npm ci (mitte npm install)
- ✅ package-lock.json olemas
- ✅ --only=production (pole dev dependencies)
- ✅ Dockerfile kuupäevad/ajad ei muutu (nt. `RUN date > /tmp/build-time`)

---

## Kokkuvõte

| Optimeerimine | Peamine kasu | Mõõdetav mõju |
|---------------|--------------|---------------|
| **1. Layer Caching** | Kiiremad rebuildid | 95% kiirem (45s → 2s) |
| **2. Multi-stage** | Väiksem image | 69% väiksem (800MB → 250MB Java) |
| **3. Non-root + Health** | Turvalisus + Monitooring | 80% vähem exploit riski, 90s downtime → 0s |
| **4. Proxy tugi** | Portaabelsus | 1 Dockerfile (vs 2), 0% proxy leak |
| **5. Reproducible** | CI/CD kiirus | 25 min → 5 min (80% kiirem pipeline) |

**Kumulatiivne mõju (microservices projekt, 10 teenust):**
- **Arendus:** 40 min ootamist päevas → 8 min (80% vähem)
- **Deployment:** 8GB images → 2.5GB (69% vähem)
- **CI/CD:** 2h pipeline → 30 min (75% kiirem)
- **Turvalisus:** Root exploitid 80% → 20% vähem

**Tulemus:** Production-ready Docker images! 🚀

---

**Viimane uuendus:** 2025-01-25
**Tüüp:** Koodiselgitus
**Kasutatakse:** Lab 1 (Harjutus 05 - Image Optimeerimine)
