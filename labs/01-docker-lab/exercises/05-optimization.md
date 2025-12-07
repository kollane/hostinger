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

**Kui midagi puudub:**
- 🔗 Võrk `todo-network` → [Harjutus 3, Samm 2](03-networking.md)
- 🔗 PostgreSQL seadistus (andmeköited + tabelid) → [Harjutus 4, Sammud 2-4](04-volumes.md)
- 🔗 Baastõmmised → [Harjutus 1A](01a-single-container-nodejs.md) ja [Harjutus 1B](01b-single-container-java.md) või käivita `lab1-setup`

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


## 📝 Sammud

### Samm 1: Uuri mõlema teenuse algset suurust

```bash
# Vaata mõlema Harjutus 1-st loodud tõmmise suurust
docker images | grep -E 'user-service|todo-service'

# Oodatud väljund:
# REPOSITORY       TAG    IMAGE ID      CREATED        SIZE
# user-service     1.0    abc123def     2 hours ago    180MB (Node.js)
# todo-service     1.0    def456ghi     2 hours ago    230MB (Java)
```

**Uuri kummagi teenuse ajalugu:**

```bash
# === USER SERVICE (Node.js) ===
docker history user-service:1.0
# Näed: FROM node:22-slim, WORKDIR, COPY package*.json, RUN npm install, COPY ., CMD

# === TODO SERVICE (Java) ===
docker history todo-service:1.0
# Näed: FROM eclipse-temurin:21-jre-alpine, WORKDIR, COPY JAR, CMD
```

**Küsimused:**
- Kui suur on User Service tõmmis? 
- Kui suur on Todo Service tõmmis? 
- Mitu kihti (layer'it) on igal? (5-6 kihti)
- Kui kiire on rebuild, kui muudad lähtekoodi? (Aeglane - kõik ehitatakse uuesti!)

### Samm 2: Optimeeri mõlema rakenduse Dockerfaili

Loome optimeeritud Dockerfailid mõlemale teenusele.

#### 2a. User Service (Node.js) optimeerimine

**⚠️ Oluline:** Dockerfile asub rakenduse juurkataloogis.

**Rakenduse juurkataloog:** `~/labs/apps/backend-nodejs`

```bash
cd ~/labs/apps/backend-nodejs
```

Loo uus `Dockerfile.optimized.proxy`:

```bash
vim Dockerfile.optimized.proxy
```

**💡 Abi vajadusel:**
Vaata täielikku näidislahendust: `~/labs/01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized.proxy`

**📖 Mitmeastmelised ehitused ja Node.js optimeerimine:**
- [Peatükk 06: Dockerfile - Multi-stage Builds](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md) selgitab mitmeastmeliste ehituste põhitõed
- [Peatükk 06A: Node.js Konteineriseerimise Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md) selgitab `npm ci`, sõltuvuste vahemälu, mitte-juurkasutajad, ARG-põhine proxy

**Lühendatud näidis (põhistruktuur):**

```dockerfile
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

**ℹ️ Märkus proksi kohta:**
- ARG väärtused on AINULT build-time'il (määratakse `--build-arg` kaudu)
- ENV on AINULT dependencies stage'is (runtime on "clean" - proxy ei leki!)
- Täielik selgitus kommentaaridega: Vaata `Dockerfile.optimized.proxy` faili

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

#### 2b. Todo Service (Java) optimeerimine

**Rakenduse juurkataloog:** `~/labs/apps/backend-java-spring`

```bash
cd ~/labs/apps/backend-java-spring
```

Loo uus `Dockerfile.optimized.proxy`:

```bash
vim Dockerfile.optimized.proxy
```

**💡 Abi vajadusel:**
Vaata täielikku näidislahendust: `~/labs/01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized.proxy`

**📖 Mitmeastmelised ehitused ja Java optimeerimine:**
- [Peatükk 06: Dockerfile - Multi-stage Builds](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md) selgitab mitmeastmeliste ehituste põhitõed (JDK → JRE)
- [Peatükk 06A: Java Spring Boot Konteineriseerimise Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md) selgitab Gradle sõltuvuste vahemälu, JVM mäluhaldust, mitte-juurkasutajaid, Gradle proxy konfiguratsioon

**Lühendatud näidis (põhistruktuur):**

```dockerfile
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

**ℹ️ Märkus proksi kohta:**
- ARG väärtused on AINULT build-time'il (määratakse `--build-arg` kaudu)
- ENV on AINULT builder stage'is (runtime on "clean" - proxy ei leki!)
- **ERINEVUS npm'ist:** Gradle EI kasuta HTTP_PROXY otse, vajab GRADLE_OPTS parsing'ut
- Täielik selgitus kommentaaridega: Vaata `Dockerfile.optimized.proxy` faili
## Ülevaade sammude järjestusest

Multi-stage build koosneb kahest põhietapist:

**Stage 1: Build (Gradle + JDK)**
1. **Gradle base image** - Build-keskkond koos kõigi vajalike tööriistadega
2. **COPY Gradle failid** - Dependency cache'i säilitamiseks (kiirema build'i jaoks)
3. **RUN dependencies** - Sõltuvuste allalaadimine (cache'itakse eraldi kihina)
4. **COPY src** - Lähtekoodi lisamine (muutub kõige sagedamini)
5. **RUN bootJar** - JAR-faili ehitamine

**Stage 2: Runtime (JRE ainult)**
1. **Temurin base image** - Kompaktne JVM runtime ilma build-tööriistadeta
2. **Non-root user** - Turvalisuse parendamine (`spring:spring` user)
3. **COPY jar** - Ainult valmis JAR-fail builder stage'ist (väike pilt)
4. **USER spring:spring** - Rakendus töötab non-root kasutajana
5. **EXPOSE 8081** - Dokumenteeri kasutatav port
6. **HEALTHCHECK** - Automaatne tervise kontroll orkestreerijale
7. **CMD** - JAR-faili käivitamine

Tulemus: efektiivne, turvaline ja skaleeritav konteineripilt.

### Samm 3: Ehita mõlemad optimeeritud Docker tõmmised

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

**ℹ️ Märkused proksi kohta:**
- `--build-arg` määrab ARG väärtused build-time'il
- Proxy on AINULT builder stage'is (npm/gradle download'id)
- Runtime konteinerid on "clean" (proxy ei leki!)
- Sama image töötab Intel võrgus JA väljaspool (portaabel)

**⚠️ Docker BuildKit hoiatused (normaalne!):**
Võid näha 3 hoiatust:
```
UndefinedVar: Usage of undefined variable '$HTTP_PROXY'
```

**Miks need tulevad?** Docker BuildKit parsib Dockerfile'i ja näeb `ENV HTTP_PROXY=${HTTP_PROXY}`. Ta hoiatab: "muutuja võib olla undefined". Tegelikult on kõik korras - ARG vaikeväärtus on `""` (tühi string).

**Lahendus:** Ignoreeri neid - build õnnestub ja proxy töötab! Kui tahad hoiatusi vältida, lisa Dockerfile'i esimesele reale: `# syntax=docker/dockerfile:1.4`

**ℹ️ Märkus User Service'i suuruse kohta:**
User Service tõmmis jääb samaks (~305MB), sest mõlemad versioonid kasutavad `node:21-slim`.

**Mida võitsime optimeeritud versiooniga:**
✅ Mitmeastmeline ehitus (sõltuvused cached eraldi kihina)
✅ Mitte-juurkasutaja (security parandus)
✅ Tervisekontroll (automaatne)
✅ -60% kiirem rebuild (sõltuvuste vahemälu)

### Samm 4: Testi MÕLEMAD optimeeritud tõmmised

**ℹ️ Portide turvalisus:**

Kasutame lihtsustatud portide vastendust (koos erinevate portidega, sest vanad on kasutusel).
- ✅ **Host'i tulemüür kaitseb:** VPS-is on UFW tulemüür, mis blokeerib pordid internetist
- 📚 **Tootmises oleks õige:** `-p 127.0.0.1:3001:3000` jne
- 🎯 **Lab 7 käsitleb:** Võrguturvalisust põhjalikumalt

**Portide valik:**
- User Service: `3001:3000` (port 3001 host'is, sest 3000 on juba kasutusel vanast)
- Todo Service: `8082:8081` (port 8082 host'is, sest 8081 on juba kasutusel vanast)

**Hetkel keskendume optimeerimisele!**

---

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

### Samm 5: Testi End-to-End JWT töövoogu optimeeritud süsteemiga

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

### Samm 6: Turvaskannimine ja haavatavuse hindamine

**Tõmmise turvaaukude (vulnerabilities) skannimine on KRIITILINE tootmises!**

**📖 Põhjalik käsitlus:** [Peatükk 06B: Docker Image Security ja Vulnerability Scanning](../../../resource/06B-Docker-Image-Security-ja-Vulnerability-Scanning.md) selgitab:
- CVE ja CVSS skoorid (mis on turvaaugud, kuidas neid hinnata)
- Docker Scout ja Trivy kasutamine (installimise juhised, kõik käsud, raportid)
- Turvalisuse parimad praktikad (mitte-juurkasutajad, minimaalsed baastõmmised, tervisekontrollid, baastõmmise uuendamise strateegia)
- CI/CD integratsioon (GitHub Actions, GitLab CI näited)

**Siin on kiired käsud testimiseks:**

#### Docker Scout (sisseehitatud, kiire)

```bash
# Skanni mõlemat optimeeritud tõmmist
docker scout cves user-service:1.0-optimized
docker scout cves todo-service:1.0-optimized

# Võrdle vana vs uus
docker scout compare user-service:1.0 --to user-service:1.0-optimized

# Soovitused
docker scout recommendations user-service:1.0-optimized
```

#### Trivy (põhjalikum, CI/CD jaoks)

```bash
# Variant A: Lokaalne binaar (kui installitud)
trivy image --severity HIGH,CRITICAL user-service:1.0-optimized
trivy image --severity HIGH,CRITICAL todo-service:1.0-optimized

# Variant B: Docker konteiner (pole installi vaja!)
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL user-service:1.0-optimized

docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL todo-service:1.0-optimized
```

**Oodatud tulemused:**
- ✅ Optimeeritud tõmmised võivad sisaldada vähem haavatavusi (sõltub baastõmmise versioonist)
- ✅ Mitte-juurkasutajad on kasutuses (nodejs:1001, spring:1001) ✅
- ✅ Tervisekontrollid lisatud ✅

**Järgmised sammud:**
1. Loe [Peatükk 06B](../../../resource/06B-Docker-Image-Security-ja-Vulnerability-Scanning.md) põhjalikuks uurimiseks
2. Parandanud CRITICAL ja HIGH CVE'd enne toote keskkonda (production)
3. Lisa automaatne skannimine CI/CD pipeline'i (juhised peatükis 06B)

### Samm 7: Kihtide vahemälu test

**Testime, kui hästi kihtide vahemälu töötab uuesti ehitamisel (rebuild):**

**Rakenduse juurkataloog (User Service):** `~/labs/apps/backend-nodejs`

```bash
# === TEST 1: Rebuild ILMA muudatusteta ===
cd ~/labs/apps/backend-nodejs
pwd  # Veendu, et oled õiges kataloogis

# Rebuild User Service (peaks olema VÄGA kiire!)
time docker build -f Dockerfile.optimized -t user-service:1.0-optimized .
# Oodatud: "CACHED" iga kihi jaoks, build ~2-5s

# Asukoht: ~/labs/apps/backend-java-spring
cd ~/labs/apps/backend-java-spring
pwd  # Veendu, et oled õiges kataloogis

# Rebuild Todo Service (peaks olema VÄGA kiire!)
time docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .
# Oodatud: "CACHED" enamuse kihtide jaoks, build ~10-20s

# === TEST 2: Rebuild KUI lähtekood muutub ===

# User Service - muuda source code
# Asukoht: ~/labs/apps/backend-nodejs
cd ~/labs/apps/backend-nodejs
pwd  # Veendu, et oled õiges kataloogis
echo "// test comment" >> server.js

# Rebuild
time docker build -f Dockerfile.optimized -t user-service:1.0-optimized .
# Oodatud: Sõltuvuste kiht CACHED, ainult COPY . ja pärast rebuilditakse (~10-15s)

# Todo Service - muuda source code
# Asukoht: ~/labs/apps/backend-java-spring
cd ~/labs/apps/backend-java-spring
pwd  # Veendu, et oled õiges kataloogis
echo "// test comment" >> src/main/java/com/hostinger/todoapp/TodoApplication.java

# Rebuild
time docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .
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

### Samm 8: Proxy Konfiguratsiooni Põhjalik Selgitus (10 min)

**Eesmärk:** Mõista, kuidas ARG-põhine proxy konfiguratsioon töötab ja miks see on parim praktika.

**ℹ️ Märkus:** Selles sammus kasutatakse juba Sammudes 2-3 loodud `.proxy` variante. See selgitab põhjalikult, kuidas need töötavad.

#### 8.1 Kuidas ARG-põhine Proxy Töötab

**Sammudes 2-3 lõite juba `Dockerfile.optimized.proxy` failid. Vaatame, kuidas need töötavad:**

**Node.js (User Service) proxy struktuur:**

```dockerfile
# ARG ENNE esimest FROM - nähtav kõigis stage'ides
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""

# Stage 1: Dependencies
FROM node:22-slim AS dependencies

# ENV AINULT selles stage'is - npm kasutab neid
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY}

RUN npm ci --only=production  # npm kasutab HTTP_PROXY automaatselt

# Stage 2: Runtime
FROM node:22-slim  # <-- Uus FROM nullib ENV muutujad!
# Proxy ei ole siin - runtime on "clean"!
```

**Mida õppisid:**
- ✅ ARG on build-time (määratakse `--build-arg` kaudu)
- ✅ ENV on AINULT dependencies stage'is
- ✅ Runtime stage EI OLE proxy keskkonda (turvalisem!)
- ✅ Sama Dockerfile töötab Intel võrgus JA väljaspool

#### 8.2 Verifitseeri: Proxy Ei Leki Runtime'i

**KRIITILINE TEST:** Kontrolli, et proxy muutujad EI OLE runtime konteineris!

```bash
# Test: runtime konteineris EI TOHI olla proksi muutujaid
docker run --rm user-service:1.0-optimized env | grep -i proxy

# OODATUD: Tühi väljund (ei leia midagi) ✅
# Kui näed HTTP_PROXY=..., siis proxy leak'is! ⚠️ VIGA!

# Test Gradle muutujate jaoks (Java)
docker run --rm todo-service:1.0-optimized env | grep -i gradle

# OODATUD: Tühi väljund (GRADLE_OPTS ei ole runtime'is) ✅
```

**Miks see on oluline?**
- ✅ Runtime konteiner on "clean" (ei sõltu proksist)
- ✅ Image on portaabel (töötab AWS, GCP, Azure, kodus)
- ✅ Turvalisem (proxy info ei leki tootmisse)

#### 8.3 Gradle vs npm Proxy Erinevus

**TÄHTIS ERINEVUS:** Gradle ja npm käituvad erinevalt!

**npm (Node.js):**
```bash
# npm kasutab HTTP_PROXY keskkonna muutujat OTSE
ENV HTTP_PROXY=http://proxy-chain.intel.com:911
RUN npm ci --only=production  # ✅ Töötab automaatselt!
```

**Gradle (Java):**
```bash
# Gradle EI KASUTA HTTP_PROXY otse! ❌
# Vajab: -Dhttp.proxyHost=HOST -Dhttp.proxyPort=PORT

# Seega parsime HTTP_PROXY stringi:
RUN if [ -n "$HTTP_PROXY" ]; then \
        PROXY_HOST=$(echo "$HTTP_PROXY" | sed -e 's|http://||' -e 's|:[0-9]*$||'); \
        PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
        export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT"; \
        gradle dependencies --no-daemon; \
    fi
```

**Miks see on oluline?**
- ✅ npm: lihtne (kasutab HTTP_PROXY otse)
- ⚠️ Gradle: keeruline (vajab parsing'ut ja GRADLE_OPTS)
- 📖 Täielik selgitus: Vaata `Dockerfile.optimized.proxy` kommentaare

#### 8.4 Parimad Praktikad (Best Practices)

**✅ DO (KASUTA):**
1. **ARG-põhine proxy** (see Dockerfile) - portaabel, turvaline
2. **ENV ainult builder stage'is** - runtime on "clean"
3. **Vaikeväärtused tühjad** (`ARG HTTP_PROXY=""`) - töötab ilma proksita
4. **Test runtime leakage** - `docker run --rm ... env | grep -i proxy`

**❌ DON'T (ÄRA KASUTA):**
1. **Hardcoded ENV** - ei ole portaabel, ei tööta väljaspool Intel võrku
2. **ENV runtime stage'is** - proxy leak'ib tootmisse!
3. **Proxy ilma vaikeväärtuseta** - ei tööta ilma `--build-arg`

**📖 Põhjalik dokumentatsioon:**
- Node.js: [README-PROXY.md](../../solutions/backend-nodejs/README-PROXY.md)
- Java/Gradle: [README-PROXY.md](../../solutions/backend-java-spring/README-PROXY.md)
- Teooria: [Peatükk 06A](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)

---

**Kokkuvõte (Samm 8):** ARG-põhine proxy konfiguratsioon:
- ✅ Töötab Intel võrgus JA väljaspool (portaabel)
- ✅ Ei leki runtime'i (turvalisem)
- ✅ Ei suurenda image suurust
- ✅ Production-ready (sama Dockerfile mõlemas keskkonnas)

---

## 🎓 Parimad tavad

1. ✅ Mitmeastmelised ehitused (JDK → JRE, sõltuvused → runtime)
2. ✅ Kihtide vahemälu (COPY sõltuvused enne lähtekoodi)
3. ✅ .dockerignore fail (välistab tarbetud failid)
4. ✅ Mitte-juurkasutaja (turvalisus)
5. ✅ Tervisekontroll Dockerfile'is (monitooring)
6. ✅ Gradle/npm --no-daemon (vähem mälu, kiirem ehitus)
7. ✅ Testi optimeeritud tõmmiseid end-to-end töövooga

---

**Harjutus 5: Optimeerimine (PRAEGU)**
- ✅ Mitmeastmelised ehitused (mõlemas teenuses)
- ✅ Kihtide vahemälu (-60-80% kiirem rebuild)
- ✅ Turvalisus (mitte-juurkasutajad)
- ✅ Tervisekontrollid
- ⚠️ Mõlemad User Service versioonid kasutavad `node:21-slim`
- ✅ Todo Service: -22% väiksem tõmmis
- ⚠️ User Service: sama suurus, optimisatsioon annab kiiremad rebuild'id
- ✅ End-to-End test optimeeritud süsteemiga

### 🏆 LÕPPTULEMUS: Tootmiskõlbulik (Production-Ready) Docker seadistus!

**Mis sul nüüd on:**
- ✅ 2 optimeeritud mikroteenust (User Service + Todo Service)
- ✅ 2 andmebaasi andmeköidetega (andmete püsivus)
- ✅ Kohandatud võrk (korrektne DNS lahendus)
- ✅ Tervise monitooring (terved konteinerid)
- ✅ Turvalisus (mitte-juurkasutajad)
- ✅ Kiired "uuesti ehitamised" (rebuilds) (kihtide vahemälu - 60-80% kiirem!)
- ✅ End-to-End testitud (JWT töövoog töötab!)
- 📚 **Õppetund:** Töökindlus > tõmmise suurus

**See on TÄIELIK tootmiskõlbulik (production-ready) mikroteenuste süsteem!** 🎉🚀

---

## 🚀 Järgmised sammud

Sa oskad nüüd:
1. ✅ Ehitada Docker tõmmiseid
2. ✅ Käivitada mitme konteineri seadistusi
3. ✅ Kasutada kohandatud võrke
4. ✅ Säilitada andmeid andmeköidetega
5. ✅ Optimeerida tõmmise suurust ja ehituse kiirust

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
