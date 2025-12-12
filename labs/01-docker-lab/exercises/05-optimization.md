# Harjutus 5: Tõmmise optimeerimine

**Eesmärk:** Optimeeri Docker tõmmise suurust ja ehituse kiirust

---

## ⚠️ Enne alustamist kontrolli eeldusi.

**Veendu, et süsteem on valmis:**

```bash
# 1. Kontrolli, et MÕLEMAD PostgreSQL konteinerid töötavad
docker ps | grep postgres
# Oodatud: postgres-user (5432) ja postgres-todo (5433)

# 2. Kontrolli, et andmebaasides on tabelid
docker exec postgres-user psql -U postgres -d user_service_db -c "\dt"
docker exec postgres-todo psql -U postgres -d todo_service_db -c "\dt"
# Oodatud: "users" ja "todos" tabelid

# 3. Kontrolli olemasolevaid tõmmiseid
docker images | grep -E 'user-service|todo-service'
# Oodatud: user-service:1.0 ja todo-service:1.0
```

**Kui midagi puudub: ** käivita `lab1-setup`

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📋 Harjutuse ülevaade

**Mäletad Harjutus 1-st?** Lõime lihtsa Dockerfile'i, mis toimis. Aga nüüd õpime, kuidas teha seda **paremaks**!

**Praegune Dockerfile (Harjutus 1) probleemid - MÕLEMAS teenuses:**
- ❌ Liiga suur tõmmis (docker image)
- ❌ Ehitus on aeglane (rebuild iga source muudatuse korral)
- ❌ Ei kasuta kihtide vahemälu efektiivselt
- ❌ Töötab root'ina (turvarisk!)
- ❌ Pole tervisekontrolli

**Selles harjutuses - optimeerime MÕLEMAT teenust:**
- ✅ **Node.js (User Service):** Mitmeastmeline ehitus (sõltuvused → runtime)
- ✅ **Java (Todo Service):** Mitmeastmeline ehitus (JDK build → JRE runtime)
- ✅ Kihtide vahemälu optimeerimine (sõltuvused on vahemälus)
- ✅ Turvalisus (mitte-juurkasutajad: nodejs:1001, spring:1001)
- ✅ Tervisekontrollid

**📖 Põhjalik selgitus - Milleks Docker image optimeerimist kasutame?**

Kui soovid mõista optimeerimise 5 peamist eesmärki (layer caching, multi-stage, turvalisus, portaabelsus, CI/CD), loe:
- 👉 **[Koodiselgitus: Docker Image Optimeerimise 5 Eesmärki](../../../resource/code-explanations/Docker-Image-Optimization-Explained.md)**
  
---

## 📝 Sammud

### Samm 1: Optimeeri mõlema rakenduse Dockerfaili

Loome optimeeritud Dockerfailid mõlemale teenusele.

**📖 Proxy konfiguratsioon:**

Kui soovid mõista ARG-põhist proxy konfiguratsiooni (miks ettevõtted kasutavad proxy serverit, kuidas ARG vs ENV töötab, proxy leakage verifitseerimine), loe:
- 👉 **[Koodiselgitus: Docker ARG-põhine Proxy Best Practices](../../../resource/code-explanations/Docker-ARG-Proxy-Best-Practices.md)**

---

#### 1a. User Service (Node.js) optimeerimine


```bash
cd ~/labs/apps/backend-nodejs
```
```bash
vim Dockerfile.optimized.proxy
```

**Dockerfile loomine:**

```dockerfile
# syntax=docker/dockerfile:1.4
# ☝️ BuildKit syntax versiooni määrang - vähendab UndefinedVar hoiatusi

# ARG deklaratsioonid ENNE esimest FROM (proksi tugi)
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG NO_PROXY=""

# Stage 1: Dependencies
FROM node:22-slim AS dependencies

# ENV ainult selles stage'is - npm ci kasutab neid
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY}

WORKDIR /app

# Kopeeri dependency files (caching jaoks)
COPY package*.json ./

# Installi AINULT production dependencies
RUN npm ci --only=production

# Stage 2: Runtime
FROM node:22-slim
WORKDIR /app

# Loo non-root user (Debian käsud!)
RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs nodejs

# Kopeeri dependencies builder stage'ist
COPY --from=dependencies --chown=nodejs:nodejs /app/node_modules ./node_modules

# Kopeeri application code
COPY --chown=nodejs:nodejs . .

# Kasuta non-root userit
USER nodejs:nodejs

EXPOSE 3000

# Tervisekontroll
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD node healthcheck.js || exit 1

CMD ["node", "server.js"]
```

**📖 Põhjalik koodi selgitus:**

Kui vajad koodi täpset rea-haaval selgitust (BuildKit syntax, ARG vs ENV, stage'd, non-root kasutaja, HEALTHCHECK), loe:
- 👉 **[Koodiselgitus: Node.js Mitmeastmeline Dockerfile](../../../resource/code-explanations/Node.js-Multi-Stage-Dockerfile-Explained.md)**

---

**⚠️ OLULINE: Lisa `healthcheck.js` fail rakenduse juurkataloogi**

See fail on vajalik HEALTHCHECK käsu jaoks Dockerfile'is. Ilma selleta ei käivitu container korralikult.

Loo fail `healthcheck.js`:

```bash
vim healthcheck.js
```

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
    process.exit(0);
  } else {
    process.exit(1);
  }
});

req.on('error', () => process.exit(1));
req.end();
```

#### 1b. Todo Service (Java) optimeerimine

```bash
cd ~/labs/apps/backend-java-spring
```

```bash
vim Dockerfile.optimized.proxy
```

**Dockerfile loomine:**

```dockerfile
# syntax=docker/dockerfile:1.4
# ☝️ BuildKit syntax versiooni määrang - vähendab UndefinedVar hoiatusi

# ARG deklaratsioonid ENNE esimest FROM (proksi tugi)
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG NO_PROXY=""

# Stage 1: Build
FROM gradle:8.11-jdk21-alpine AS builder

# ENV ainult selles stage'is
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY}

WORKDIR /app

# Kopeeri Gradle failid (dependencies caching jaoks)
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Download dependencies (Gradle vajab GRADLE_OPTS proxy jaoks!)
RUN if [ -n "$HTTP_PROXY" ]; then \
        PROXY_HOST=$(echo "$HTTP_PROXY" | sed -e 's|http://||' -e 's|https://||' -e 's|:[0-9]*$||'); \
        PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
        export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT"; \
        gradle dependencies --no-daemon; \
    else \
        gradle dependencies --no-daemon; \
    fi

# Kopeeri source code ja build JAR
COPY src ./src
RUN if [ -n "$HTTP_PROXY" ]; then \
        PROXY_HOST=$(echo "$HTTP_PROXY" | sed -e 's|http://||' -e 's|https://||' -e 's|:[0-9]*$||'); \
        PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
        export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT"; \
        gradle bootJar --no-daemon; \
    else \
        gradle bootJar --no-daemon; \
    fi

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Loo non-root user
RUN addgroup -g 1001 -S spring && \
    adduser -S spring -u 1001 -G spring

# Kopeeri ainult JAR fail builder stage'ist
COPY --from=builder --chown=spring:spring /app/build/libs/todo-service.jar app.jar

# Kasuta non-root userit
USER spring:spring

EXPOSE 8081

# Health check (kontrollib iga 30s, timeout 3s, start grace period 40s)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/health || exit 1

# Käivita rakendus JVM memory tuning'uga (container-aware)
CMD ["java", \
    "-XX:InitialRAMPercentage=80", \
    "-XX:MaxRAMPercentage=80", \
    "-jar", \
    "app.jar"]
```

**📖 Põhjalik koodi selgitus:**

Kui vajad koodi täpset rea-haaval selgitust (Gradle proxy parsing, GRADLE_OPTS, JDK→JRE multi-stage, JVM memory tuning), loe:
- 👉 **[Koodiselgitus: Java Spring Boot Mitmeastmeline Dockerfile](../../../resource/code-explanations/Java-SpringBoot-Multi-Stage-Dockerfile-Explained.md)**
---

### Samm 2: Ehita mõlemad optimeeritud Docker tõmmised

**Rakenduse juurkataloog (User Service):** `~/labs/apps/backend-nodejs`

**⚠️ Oluline:** Docker tõmmise ehitamiseks pead olema rakenduse juurkataloogis (kus asub `Dockerfile.optimized`).

```bash
# === Seadista proksi väärtused (Intel võrk) ===
export HTTP_PROXY=http://proxy-chain.intel.com:911
export HTTPS_PROXY=http://proxy-chain.intel.com:912
export NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16

# Kontrolli
echo "HTTP_PROXY=$HTTP_PROXY"
echo "HTTPS_PROXY=$HTTPS_PROXY"

# === BUILD User Service (Node.js) ===
cd ~/labs/apps/backend-nodejs

# Build optimeeritud tõmmis PROKSIGA
docker build \
  --build-arg HTTP_PROXY=$HTTP_PROXY \
  --build-arg HTTPS_PROXY=$HTTPS_PROXY \
  --build-arg NO_PROXY=$NO_PROXY \
  -f Dockerfile.optimized.proxy \
  -t user-service:1.0-optimized \
  .

# === BUILD Todo Service (Java) ===
cd ~/labs/apps/backend-java-spring

# Build optimeeritud tõmmis PROKSIGA (mitmeastmeline ehitus teeb ka JAR'i)
docker build \
  --build-arg HTTP_PROXY=$HTTP_PROXY \
  --build-arg HTTPS_PROXY=$HTTPS_PROXY \
  --build-arg NO_PROXY=$NO_PROXY \
  -f Dockerfile.optimized.proxy \
  -t todo-service:1.0-optimized \
  .

# === VÕRDLE SUURUSI ===
docker images | grep -E 'user-service|todo-service'

# Oodatud väljund:
# REPOSITORY       TAG             SIZE
# user-service     1.0             ~305MB (vana, slim, single-stage)
# user-service     1.0-optimized   ~305MB (uus, slim, multi-stage + proxy)
# todo-service     1.0             ~230MB (vana)
# todo-service     1.0-optimized   ~180MB (uus + proxy) 📉 -22%
```

### Samm 3: Testi MÕLEMAD optimeeritud tõmmised

```bash
# Genereeri JWT_SECRET (kui pole veel)
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET=$JWT_SECRET"
export JWT_SECRET

# === KÄIVITA User Service (optimeeritud) ===
docker run -d \
  --name user-service-opt \
  --network todo-network \
  -p 3001:3000 \
  -e DB_HOST=postgres-user \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=$JWT_SECRET \
  -e JWT_EXPIRES_IN=24h \
  -e NODE_ENV=production \
  -e PORT=3000 \
  user-service:1.0-optimized

# === KÄIVITA Todo Service (optimeeritud) ===
docker run -d \
  --name todo-service-opt \
  --network todo-network \
  -p 8082:8081 \
  -e DB_HOST=postgres-todo \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=$JWT_SECRET \
  -e SPRING_PROFILES_ACTIVE=prod \
  todo-service:1.0-optimized

# Vaata logisid
docker logs -f user-service-opt
# Vajuta Ctrl+C kui näed: "Server running on port 3000"

docker logs -f todo-service-opt
# Vajuta Ctrl+C kui näed: "Started TodoApplication"

# === TESTI TERVISEKONTROLLE ===
echo "=== User Service'i Health ==="
curl http://localhost:3001/health
# Oodatud: {"status":"OK","database":"connected"}

echo -e "\n=== Todo Service'i Health ==="
curl http://localhost:8082/health
# Oodatud: {"status":"UP"}

# Vaata tervisekontrolli staatust
docker ps --format "table {{.Names}}\t{{.Status}}"
# user-service-opt    Up X seconds (healthy)
# todo-service-opt    Up X seconds (healthy)
```

**Võrdle vana vs uus:**
```bash
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

# Oodatud väljund:
# NAMES                IMAGE                           STATUS
# todo-service-opt     todo-service:1.0-optimized      Up (healthy)
# user-service-opt     user-service:1.0-optimized      Up (healthy)
# todo-service         todo-service:1.0                Up
# user-service         user-service:1.0                Up
```

### Samm 4: Testi End-to-End JWT töövoogu optimeeritud süsteemiga

**See on KÕIGE OLULISEM TEST - kinnitame, et optimeeritud süsteem töötab identselt!**

```bash
# 1. Registreeri kasutaja User Service'is (optimeeritud!)
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Optimized User",
    "email": "optimized@example.com",
    "password": "test123"
  }'

# Oodatud: {"token": "eyJhbGci...", "user": {...}}

# 2. Login ja salvesta JWT "token"
TOKEN=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"optimized@example.com","password":"test123"}' \
  | jq -r '.token')

echo "JWT Token: $TOKEN"

# 3. Kasuta "token"-it Todo Service'is (optimeeritud!)
curl -X POST http://localhost:8082/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Optimeeritud süsteem töötab!",
    "description": "Tõmmis on väiksem, kiirem ja turvalisem!",
    "priority": "high"
  }' | jq

# Oodatud vastus:
# {
#   "id": 1,
#   "userId": 1,  <-- ekstraktitud JWT "token"-ist!
#   "title": "Optimeeritud süsteem töötab!",
#   ...
# }

# 4. Loe todos
curl -X GET http://localhost:8082/api/todos \
  -H "Authorization: Bearer $TOKEN" | jq

# 5. Võrdle resource kasutust

# Vana vs uus tõmmis
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}"

# Oodatud: Optimeeritud konteinerid kasutavad VÄHEM mälu
```

**🎉 KUI KÕIK TOIMIS - ÕNNITLEME!**

**Mida sa just saavutasid:**
1. ✅ User Service (optimeeritud) genereeris JWT "token"-i
2. ✅ Todo Service (optimeeritud) valideeris "token"-it (SAMA JWT_SECRET!)
3. ✅ Optimeeritud süsteem töötab IDENTSENALT vanaga
4. ✅ AGA: Väiksemad tõmmised (-25-33%), tervisekontrollid, mitte-juurkasutajad!
5. ✅ TOOTMISEKS VALMIS mikroteenuste süsteem! 🚀

### Samm 5: Kihtide vahemälu test

**Testime, kui hästi kihtide vahemälu töötab uuesti ehitamisel (rebuild):**

**Rakenduse juurkataloog (User Service):** `~/labs/apps/backend-nodejs`

```bash
# === TEST 1: Rebuild ILMA muudatusteta ===
cd ~/labs/apps/backend-nodejs
pwd  # Veendu, et oled õiges kataloogis

# Rebuild User Service (peaks olema VÄGA kiire!)
time docker build -f Dockerfile.optimized.proxy -t user-service:1.0-optimized .
# Oodatud: "CACHED" iga kihi jaoks, build ~2-5s

# Asukoht: ~/labs/apps/backend-java-spring
cd ~/labs/apps/backend-java-spring
pwd  # Veendu, et oled õiges kataloogis

# Rebuild Todo Service (peaks olema VÄGA kiire!)
time docker build -f Dockerfile.optimized.proxy -t todo-service:1.0-optimized .
# Oodatud: "CACHED" enamuse kihtide jaoks, build ~10-20s

# === TEST 2: Rebuild KUI lähtekood muutub ===

# User Service - muuda source code
# Asukoht: ~/labs/apps/backend-nodejs
cd ~/labs/apps/backend-nodejs
pwd  # Veendu, et oled õiges kataloogis
echo "// test comment" >> server.js

# Rebuild
time docker build -f Dockerfile.optimized.proxy -t user-service:1.0-optimized .
# Oodatud: Sõltuvuste kiht CACHED, ainult COPY . ja pärast rebuilditakse (~10-15s)

# Todo Service - muuda source code
# Asukoht: ~/labs/apps/backend-java-spring
cd ~/labs/apps/backend-java-spring
pwd  # Veendu, et oled õiges kataloogis
echo "// test comment" >> src/main/java/com/hostinger/todoapp/TodoApplication.java

# Rebuild
time docker build -f Dockerfile.optimized.proxy -t todo-service:1.0-optimized .
# Oodatud: Gradle sõltuvuste kiht CACHED, ainult COPY src ja pärast rebuilditakse (~30-40s)
```

**Mida õppisid?**
- ✅ Sõltuvused on vahemälus (ei rebuildi kui `package.json` või `build.gradle` ei muutu!)
- ✅ Lähtekoodi muudatused ehitavad uuesti ainult viimased kihid
- ✅ Rebuild on **-60-80% kiirem** kui optimeeritud Dockerfile!

---

## 📊 Optimeerimise võrdlus

### Võrdle tõmmise suurusi

```bash
# Võrdle MÕLEMA teenuse tõmmise suurusi
docker images | grep -E 'user-service|todo-service' | sort
```

### Node.js (User Service) võrdlus

| Aspekt | Enne (Harjutus 1) | Pärast (Optimeeritud) | Parandus |
| ------ | ------------------- | ----------------- | ----------- |
| **Suurus** | ~305MB | ~305MB | ⚠️ Sama (mõlemad slim) |
| **Baastõmmis** | node:22-slim | node:22-slim (multi-stage) | ✅ |
| **Kihid** | 5-6 | 8-10 (aga vahemälus!) | ✅ |
| **Ehituse aeg (1.)** | 30s | 40s | ❌ +10s |
| **Ehituse aeg (rebuild)** | 30s | 10s | 📉 -66% |
| **Turvalisus** | root kasutaja | mitte-juurkasutaja (nodejs:1001) | ✅ |
| **Tervisekontroll** | ❌ | ✅ `healthcheck.js` | ✅ |
| **Vahemälu** | ❌ Halb | ✅ Suurepärane (npm ci cached) | ✅ |
| **Stabiilsus** | ✅ töötab (bcrypt OK) | ✅ töötab (bcrypt OK) | ✅ |

**Selgitus:** Mõlemad kasutavad `node:18-slim`. Optimeeritud versioon ei vähenda suurust, aga annab **palju kiiremad rebuild'id** (-66%) ja **parema turvalisuse** (mitte-juurkasutaja).

### Java (Todo Service) võrdlus

| Aspekt | Enne (Harjutus 1) | Pärast (Optimeeritud) | Parandus |
| ------ | ------------------- | ----------------- | ----------- |
| **Suurus** | ~230MB | ~180MB | 📉 -22% |
| **Baastõmmis** | Ainult JRE | Mitmeastmeline (JDK → JRE) | ✅ |
| **Kihid** | 5-6 | 10-12 (aga vahemälus!) | ✅ |
| **Ehituse aeg (1.)** | 60s | 90s | ❌ +30s |
| **Ehituse aeg (rebuild)** | 60s | 20s | 📉 -66% |
| **Turvalisus** | root kasutaja | mitte-juurkasutaja (spring:1001) | ✅ |
| **Tervisekontroll** | ❌ | ✅ `/health` endpoint | ✅ |
| **Vahemälu** | ❌ Halb | ✅ Suurepärane (gradle deps cached) | ✅ |

### Node.js vs Java võrdlus

| Meeterika | Node.js (User Service) | Java (Todo Service) |
|--------|------------------------|---------------------|
| **Algne suurus** | ~305MB | ~230MB |
| **Optimeeritud suurus** | ~305MB ⚠️ | ~180MB ✅ |
| **Suuruse muutus** | ⚠️ 0% (sama) | 📉 -22% |
| **Ehituse aeg (1.)** | 40s | 90s |
| **Ehituse aeg (rebuild)** | 10s | 20s |
| **Mitmeastmelise eelis** | Sõltuvuste kiht | JDK → JRE eraldamine |
| **Mitte-juurkasutaja** | nodejs:1001 | spring:1001 |
| **Tervisekontroll** | Custom JS skript | Sisseehitatud /health endpoint |
| **Baastõmmis** | node:22-slim (mõlemad) | eclipse-temurin:21-jre-alpine |

**Järeldus:**
- ⚠️ User Service: suurus jääb samaks (~305MB), sest mõlemad versioonid kasutavad sama baastõmmist
- ✅ Todo Service: tõmmis väiksem (-50MB) mitmeastmelise ehituse tõttu (JDK → JRE)
- ✅ Mõlemad on production-ready ja töötavad stabiilselt
- ✅ **Rebuild -60-80% kiirem mõlemas teenuses!** (sõltuvuste vahemälu)
- ✅ Turvalisus (mitte-juurkasutajad) ja tervisekontrollid mõlemas
- 📚 **Õppetund:** Mitmeastmeline ehitus annab kiiremad rebuild'id ja parema turvalisuse, isegi kui suurus jääb samaks

---

## Samm 6: Image Quality Verification (5-Step Quality Gate)

**Eesmärk:** Verifitseeri, et tõmmis vastab tootmiskvaliteedi (production quality) standarditele.

**📖 Põhjalikud selgitused:**
- 👉 **[Koodiselgitus: Docker Image Quality Verification Roadmap](../../../resource/code-explanations/Docker-Image-Quality-Verification-Roadmap.md)**
- 👉 **[Koodiselgitus: Dive Tool](../../../resource/code-explanations/Dive-Tool-Explained.md)**

**Mis on kvaliteedikontroll?**

Pärast image'i ehitamist ja optimeerimist on oluline verifitseerida 5 kvaliteedi aspekti:
1. **Efficiency (Efektiivsus):** Kas image on minimaalne? Ei ole raisatud ruumi?
2. **Privacy (Privaatsus):** Kas proxy/secrets ei leki runtime'i?
3. **Security (Turvalisus):** Kas on CVE'd (turvaaugud)?
4. **User (Kasutaja):** Kas töötab non-root kasutajana?
5. **Size (Suurus):** Kas suurus on mõistlik?

---

### 6.1. Dive - Image Efficiency Analüüs

**Dive** näitab:
- Kihtide (layers) struktuuri
- Raisatud ruumi (wasted space)
- Efektiivsuse skoori (efficiency score)
- Failide muudatused kihtide vahel

**Installi Dive (Docker konteinerina):**

```bash
# Alias mugavaks kasutamiseks
alias dive='docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive:latest'

# Veendu, et alias töötab
dive --version
```

**Analüüsi User Service:**

```bash
dive user-service:1.0-optimized
```

**Dive kasutajaliides (UI):**
```
╔═══════════════════════════════════════════════════════════╗
║  Layers (Vasakul)      │  File Tree (Paremal)            ║
║                        │                                  ║
║  Kiht 1: base         │  / (root)                        ║
║  ├─ 180 MB            │  ├─ usr/                         ║
║  │  Added: 234 files  │  │  ├─ bin/                      ║
║  │                    │  │  └─ lib/                      ║
║  Kiht 2: dependencies │  ├─ app/                         ║
║  ├─ 125 MB            │  │  ├─ node_modules/ (prod)      ║
║  │  Added: 1024 files │  │  └─ server.js                 ║
║  │                    │  └─ home/                        ║
║  Kiht 3: runtime      │     └─ nodejs/ (user)            ║
║  ├─ 0.5 MB            │                                  ║
║  │  Added: 5 files    │  Legend:                         ║
║  │  Removed: 0 files  │  [deleted] = kustutatakse        ║
║                       │  [modified] = muudatakse         ║
║ Efficiency: 99%       │  [new] = lisatakse               ║
║ Wasted Space: 0 MB    │                                  ║
╚═══════════════════════════════════════════════════════════╝
```

**Klaviatuuri lühikäsud:**
- `↑/↓` - navigeeri kihtide vahel
- `←/→` - navigeeri failipuus
- `Space` - laienda/sulge kaust
- `Ctrl+L` - näita AINULT wasted faile (kriitiliselt oluline!)
- `Ctrl+Q` - välju

**Mida kontrollida:**

1. **Efficiency Score:** > 98% ✅
   - Kui madalam, on raisatud ruumi (wasted space)
   - Vaata `Ctrl+L` - millised failid on deleted/wasted?

2. **Wasted Space:** ≈ 0 MB ✅
   - Kui suur, tähendab et lisasid faile ühes kihis ja kustutasid teises
   - Multi-stage build peaks seda vältima!

3. **File Tree (paremal paneel):**
   - ❌ **EI tohi näha:** `src/`, `build/`, `target/`, `.gradle/`, `node_modules/devDependencies`
   - ✅ **Peab nägema:** AINULT runtime failid (`app.jar`, `node_modules/` production-only, `server.js`)

**Analüüsi Todo Service:**

```bash
dive todo-service:1.0-optimized
```

**Oodatud tulemus (Java):**
- Efficiency: 99%
- Wasted Space: 0 MB
- Failipuus: `/app/app.jar`, JRE runtime, spring user (1001)
- **PUUDUB:** Gradle, JDK, source code, Maven cache

---

### 6.2. Quality Gate - 5 Kontrolli

**Enne production'i, veendu, et kõik 5 kontrolli on ✅:**

#### 1️⃣ Efficiency (Dive)

```bash
# User Service
dive user-service:1.0-optimized
# Oodatud: Efficiency > 98%, Wasted Space < 1 MB

# Todo Service
dive todo-service:1.0-optimized
# Oodatud: Efficiency > 98%, Wasted Space < 1 MB
```

**Kui efektiivsus < 98%:**
- Vaata `Ctrl+L` Dive'is - millised failid on wasted?
- Kontrolli Dockerfile: kas kustutad faile pärast kopeerimat (vale!)
- Kasuta multi-stage build'i õigesti (kopeeri AINULT vajalikud failid)

---

#### 2️⃣ Privacy (Proxy/Secrets Leak)

**Kontrolli history (ei tohi näidata proxy paroole):**

```bash
# User Service
docker history --no-trunc user-service:1.0-optimized | grep -E "ARG|ENV|proxy"

# Todo Service
docker history --no-trunc todo-service:1.0-optimized | grep -E "ARG|ENV|proxy|GRADLE"
```

**Oodatud tulemus:**
- ARG muutujad võivad näha olla, AGA **tühjad** (ilma väärtusteta)
- ❌ **Kui näed:** `HTTP_PROXY=http://user:password@proxy.company.com` → **PROBLEEM!**
- ✅ **Kui näed:** `ARG HTTP_PROXY=""` → **OK!**

**Kontrolli runtime env (ei tohi olla proxy muutujaid):**

```bash
# User Service
docker run --rm user-service:1.0-optimized env | grep -i proxy

# Todo Service
docker run --rm todo-service:1.0-optimized env | grep -E "proxy|GRADLE"
```

**Oodatud tulemus:** Tühi väljund ✅ (proxy ei leki runtime'i!)

**Kui leiad proxy muutujaid runtime'is:**
- ❌ **Probleem:** Rakendus püüab kasutada ettevõtte sisevõrgu proxyt (ei tööta production'is!)
- ✅ **Lahendus:** Kasuta ARG (build-time), mitte ENV (runtime) Dockerfile'is

---

#### 3️⃣ Security (Trivy - Vulnerability Scanning)

**Tõmmise turvaaukude (vulnerabilities) skannimine on KRIITILINE tootmises!**

**📖 Põhjalik käsitlus:** [Peatükk 06B: Docker Image Security ja Vulnerability Scanning](../../../resource/06B-Docker-Image-Security-ja-Vulnerability-Scanning.md) selgitab:
- CVE ja CVSS skoorid (mis on turvaaugud, kuidas neid hinnata)
- Trivy kasutamine (installimise juhised, kõik käsud, raportid)
- Turvalisuse parimad praktikad (mitte-juurkasutajad, minimaalsed baastõmmised, tervisekontrollid, baastõmmise uuendamise strateegia)
- CI/CD integratsioon (GitHub Actions, GitLab CI näited)

**Trivy (vulnerability scanner):**

**ℹ️ Märkus:** Trivy lokaalne binaar (`trivy`) ei ole paigaldatud. Kasutame Docker konteinerit.

```bash
# Seadista proksi (Intel võrk)
export HTTP_PROXY=http://proxy-chain.intel.com:911
export HTTPS_PROXY=http://proxy-chain.intel.com:912
export NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16

# Skanni User Service (Node.js)
docker run --rm \
  -e HTTP_PROXY=$HTTP_PROXY \
  -e HTTPS_PROXY=$HTTPS_PROXY \
  -e NO_PROXY=$NO_PROXY \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL user-service:1.0-optimized

# Skanni Todo Service (Java)
docker run --rm \
  -e HTTP_PROXY=$HTTP_PROXY \
  -e HTTPS_PROXY=$HTTPS_PROXY \
  -e NO_PROXY=$NO_PROXY \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL todo-service:1.0-optimized
```

**Mida need käsud teevad:**
- `-e HTTP_PROXY=$HTTP_PROXY` - edastab proksi seadistused Trivy konteinerile
- `-v /var/run/docker.sock` - lubab Trivy-l pääseda Docker image'itele
- `--severity HIGH,CRITICAL` - näitab ainult kriitilisi haavatavusi
- Trivy laadib alla vulnerability DB läbi proksi (mirror.gcr.io)

**Quality Gate kriteerium:** 0 CRITICAL CVE'd ✅

**Kui leiad CRITICAL CVE'd:**
1. Uuenda base image: `node:22-slim` → `node:22.x.x-slim` (latest patch)
2. Uuenda dependencies: `npm audit fix` või `gradle dependencyUpdates`
3. Rebuild image ja skanni uuesti

**Järgmised sammud:**
- Loe [Peatükk 06B](../../../resource/06B-Docker-Image-Security-ja-Vulnerability-Scanning.md) põhjalikuks uurimiseks
- Parandanud CRITICAL ja HIGH CVE'd enne toote keskkonda (production)
- Lisa automaatne skannimine CI/CD pipeline'i (juhised peatükis 06B)

---

#### 4️⃣ User (Non-root)

**Kontrolli, kas töötab non-root kasutajana:**

```bash
# User Service
docker run --rm user-service:1.0-optimized id
# Oodatud: uid=1001(nodejs) gid=1001(nodejs) ✅

# Todo Service
docker run --rm todo-service:1.0-optimized id
# Oodatud: uid=1001(spring) gid=1001(spring) ✅
```

**Kui näed `uid=0(root)`:**
- ❌ **Probleem:** Rakendus töötab root kasutajana (turvarisk!)
- ✅ **Lahendus:** Lisa Dockerfile'i `USER nodejs:nodejs` või `USER spring:spring`

---

#### 5️⃣ Size (Mõistlik suurus)

```bash
# Võrdle mõlema teenuse suurusi
docker images | grep -E 'user-service|todo-service'
```

**Oodatud tulemused:**

| Image | Suurus | Hinnang |
|-------|--------|---------|
| `user-service:1.0-optimized` | ~305 MB | ✅ OK (Node.js + slim) |
| `todo-service:1.0-optimized` | ~180 MB | ✅ OK (Java JRE + alpine) |

**Suuruse standardid:**
- Node.js (slim): 200-350 MB ✅
- Node.js (alpine): 100-200 MB ✅✅
- Java JRE (alpine): 150-250 MB ✅
- Java JDK (ubuntu): 400-600 MB ⚠️ (liiga suur!)
- Go (alpine): 10-30 MB ✅✅✅

**Kui suurus on liiga suur:**
- Kasuta väiksemat base image'i (`alpine` vs `slim` vs `ubuntu`)
- Kasuta multi-stage build'i (JDK → JRE, dependencies → runtime)
- Eemalda development dependencies (`npm ci --only=production`)

---

### 6.3. Quality Gate Kokkuvõte

**✅ KUI KÕIK 5 KONTROLLI ON ROHELINE:**

| Kontroll | Status | Kriteerium |
|----------|--------|------------|
| 1️⃣ **Efficiency** | ✅ | > 98%, Wasted Space < 1 MB |
| 2️⃣ **Privacy** | ✅ | Proxy EI leki (env, history) |
| 3️⃣ **Security** | ✅ | 0 CRITICAL CVE'd |
| 4️⃣ **User** | ✅ | Non-root (nodejs:1001, spring:1001) |
| 5️⃣ **Size** | ✅ | Node.js < 350 MB, Java < 250 MB |

🎉 **Tõmmis on production-ready!**
- Minimaalne suurus
- Turvaline (CVE-free, non-root)
- Ei leki saladusi
- Efektiivne (no wasted space)

**Järgmised sammud:**
1. Push image Docker registry'sse (Harbor, AWS ECR, Azure ACR)
2. Deploy Kubernetes'e (Lab 3-4)
3. Setup CI/CD pipeline (Lab 5) - automatiseeri need 5 kontrolli!

---

## 🎓 Parimad tavad

1. ✅ Mitmeastmelised ehitused (JDK → JRE, sõltuvused → runtime)
2. ✅ Kihtide vahemälu (COPY sõltuvused enne lähtekoodi)
3. ✅ .dockerignore fail (välistab tarbetud failid)
4. ✅ Mitte-juurkasutaja (turvalisus)
5. ✅ Tervisekontroll Dockerfile'is (monitooring)
6. ✅ Gradle/npm --no-daemon (vähem mälu, kiirem ehitus)
7. ✅ Testi optimeeritud tõmmiseid end-to-end töövooga
8. ✅ **Kvaliteedikontroll (Quality Gate)** - Verifitseeri image 5 aspekti: Efficiency (Dive), Privacy (no proxy leak), Security (Trivy), User (non-root), Size

**See on TÄIELIK tootmiskõlbulik (production-ready) mikroteenuste süsteem!** 🎉🚀

---

## 🚀 Järgmised sammud

Sa oskad nüüd:
1. ✅ Ehitada Docker tõmmiseid
2. ✅ Käivitada mitme konteineri seadistusi
3. ✅ Kasutada kohandatud võrke
4. ✅ Säilitada andmeid andmeköidetega
5. ✅ Optimeerida tõmmise suurust ja ehituse kiirust
6. ✅ **Verifitseerida image kvaliteeti** (Dive, privacy check, security scan, non-root, size)

**Aga...**
- Kas pead käivitama 10 `docker run` käsku iga kord?
- Kuidas hallata mitut teenust korraga?
- Kuidas teha development/production konfiguratsioonid?

**Vastus: Docker Compose!** (Lab 2)

---

## 📚 Viited

- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Security - Non-root User](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user)
- [Docker HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck)
- [Layer Caching](https://docs.docker.com/build/cache/)
- [Node.js Docker Best Practices](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)
- [Spring Boot Docker Best Practices](https://spring.io/guides/topicals/spring-boot-docker/)

---

**Järgmine:** [Lab 2: Docker Compose](../../02-docker-compose-lab/README.md)
