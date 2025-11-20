# Harjutus 5: Image Optimization

**Kestus:** 45 minutit
**Eesmärk:** Optimeeri Docker image suurust ja build kiirust

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et süsteem on valmis:**

```bash
# 1. Kontrolli, et MÕLEMAD PostgreSQL containerid töötavad
docker ps | grep postgres
# Oodatud: postgres-user (5432) ja postgres-todo (5433)

# 2. Kontrolli, et andmebaasides on tabelid
docker exec postgres-user psql -U postgres -d user_service_db -c "\dt"
docker exec postgres-todo psql -U postgres -d todo_service_db -c "\dt"
# Oodatud: "users" ja "todos" tabelid

# 3. Kontrolli olemasolevaid image'eid
docker images | grep -E 'user-service|todo-service'
# Oodatud: user-service:1.0 ja todo-service:1.0
```

**Kui midagi puudub:**
- 🔗 Network `todo-network` → [Harjutus 3, Samm 2](03-networking.md)
- 🔗 PostgreSQL setup (volumes + tabelid) → [Harjutus 4, Sammud 2-4](04-volumes.md)
- 🔗 Base image'd → [Harjutus 1A](01a-single-container-nodejs.md) ja [Harjutus 1B](01b-single-container-java.md) või käivita `./setup.sh`

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📋 Ülevaade

**Mäletad Harjutus 1-st?** Lõime lihtsa Dockerfile'i, mis toimis. Aga nüüd õpime, kuidas teha seda **PALJU paremaks**!

**Praegune Dockerfile (Harjutus 1) probleemid - MÕLEMAS teenuses:**
- ❌ Liiga suur pilt (image) (~200-230MB)
- ❌ Build on aeglane (rebuild iga source muudatuse korral)
- ❌ Ei kasuta layer caching'ut efektiivselt
- ❌ Töötab root'ina (security risk!)
- ❌ Pole health check'i

**Selles harjutuses - optimeerime MÕLEMAT teenust:**
- ✅ **Node.js (User Service):** Multi-stage build (dependencies → runtime)
- ✅ **Java (Todo Service):** Multi-stage build (JDK build → JRE runtime)
- ✅ Layer caching optimization (dependencies cached)
- ✅ Security (non-root users: nodejs:1001, spring:1001)
- ✅ Health checks
- ⚠️ **Märkus:** User Service kasutab `node:18-slim` (mitte alpine) bcrypt native moodulite tõttu

---

## 🎯 Õpieesmärgid

- ✅ Implementeerida multi-stage builds (Node.js ja Java)
- ✅ Optimeerida layer caching (dependencies eraldi)
- ✅ Parandada .dockerignore faile
- ✅ Lisa health check'id mõlemasse teenusesse
- ✅ Kasuta non-root users (nodejs:1001, spring:1001)
- ✅ Mõista Alpine vs Debian (slim) trade-off'e native moodulitega
- ✅ Võrrelda Node.js vs Java optimization tulemusi
- ✅ Testida End-to-End workflow optimeeritud süsteemiga

---

## 📝 Sammud

### Samm 1: Mõõda MÕLEMA Teenuse Algne Suurus (10 min)

```bash
# Vaata MÕLEMA Harjutus 1-st loodud image suurust
docker images | grep -E 'user-service|todo-service'

# Oodatud väljund:
# REPOSITORY       TAG    IMAGE ID      CREATED        SIZE
# user-service     1.0    abc123def     2 hours ago    180MB (Node.js)
# todo-service     1.0    def456ghi     2 hours ago    230MB (Java)
```

**Analyseer MÕLEMAT:**

```bash
# === USER SERVICE (Node.js) ===
docker history user-service:1.0
# Näed: FROM node:18-slim, WORKDIR, COPY package*.json, RUN npm install, COPY ., CMD

# === TODO SERVICE (Java) ===
docker history todo-service:1.0
# Näed: FROM eclipse-temurin:17-jre-alpine, WORKDIR, COPY JAR, CMD
```

**Küsimused:**
- Kui suur on User Service image? (~180MB)
- Kui suur on Todo Service image? (~230MB)
- Mitu layer'it on igal? (5-6 layer'it)
- Kui kiire on rebuild, kui muudad source code'i? (Aeglane - kõik rebuilditakse!)

### Samm 2: Optimeeri MÕLEMAT Dockerfaili (30 min)

Loome optimeeritud Dockerfailid mõlemale teenusele.

#### 2a. User Service (Node.js) Optimization

**Asukoht:** `/hostinger/labs/apps/backend-nodejs`

```bash
cd ../apps/backend-nodejs
```

Loo uus `Dockerfile.optimized`:

**💡 Abi vajadusel:**
Vaata näidislahendust: `/hostinger/labs/01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized`

**⚠️ OLULINE: Alpine vs Debian (Slim) Valik**

**Miks kasutame `node:18-slim` asemel `node:18-alpine`?**

User Service kasutab **bcrypt** teeki paroolide hashing'uks. Bcrypt sisaldab native C++ mooduleid, mis peavad olema kompileeritud konkreetse operatsioonisüsteemi jaoks.

**Probleem Alpine'iga:**
- Alpine Linux kasutab `musl libc` asemel `glibc`
- bcrypt native binaarid crashivad (exit code 139 - segmentation fault)
- Lahendus oleks installida build tools (python3, make, g++), AGA see suurendab pildi (image) suurust ~100MB võrra

**Lahendus: Debian Slim**
- `node:18-slim` on Debian-based minimalistlik pilt (image)
- bcrypt native moodulid töötavad out-of-the-box
- Pisut suurem kui Alpine (~305MB vs ~180MB), AGA töötab kindlalt

**Trade-off:**
```
Alpine + build tools:   ~280MB (ei tööta stabiilselt)
Debian Slim:            ~305MB (✅ töötab perfektselt)
Alpine ilma bcrypt'ita: ~120MB (aga bcrypt on kohustuslik!)
```

**Järeldus:** Kaotame ~100MB suurust, aga **saame töökindla ja turvalise lahenduse**.

```dockerfile
# Stage 1: Dependencies
FROM node:18-slim AS dependencies
WORKDIR /app

# Kopeeri dependency files (caching jaoks)
COPY package*.json ./

# Installi AINULT production dependencies
RUN npm ci --only=production

# Stage 2: Runtime
FROM node:18-slim
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

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD node healthcheck.js || exit 1

CMD ["node", "server.js"]
```

**Märkused:**
- ⚠️ Kasutame `groupadd`/`useradd` (Debian) asemel `addgroup`/`adduser` (Alpine)
- ✅ bcrypt töötab natively ilma lisatööriistu
- ✅ Production-ready ja testitud lahendus

**⚠️ OLULINE: Lisa `healthcheck.js` fail rakenduse juurkataloogi enne Docker build'i!**

See fail on vajalik HEALTHCHECK käsu jaoks Dockerfile'is. Ilma selleta ei käivitu container korralikult.

```bash
cat > healthcheck.js <<'EOF'
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
EOF
```

#### 2b. Todo Service (Java) Optimization

**Asukoht:** `/hostinger/labs/apps/backend-java-spring`

```bash
cd ../backend-java-spring
```

Loo uus `Dockerfile.optimized`:

**💡 Abi vajadusel:**
Vaata näidislahendust: `/hostinger/labs/01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized`

```dockerfile
# Stage 1: Build
FROM gradle:8.5-jdk17-alpine AS builder
WORKDIR /app

# Kopeeri Gradle failid (caching jaoks)
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Download dependencies (cached kui build.gradle ei muutu)
RUN gradle dependencies --no-daemon

# Kopeeri source code ja build
COPY src ./src
RUN gradle bootJar --no-daemon

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Loo non-root user
RUN addgroup -g 1001 -S spring && \
    adduser -S spring -u 1001 -G spring

# Kopeeri ainult JAR fail builder stage'ist
COPY --from=builder --chown=spring:spring /app/build/libs/todo-service.jar app.jar

# Kasuta non-root userit
USER spring:spring

EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/health || exit 1

CMD ["java", "-jar", "app.jar"]
```
## Ülevaade sammude järjestusest

|Samm|Eesmärk|Tähendus|
|---|---|---|
|Gradle base image|Build- ja dependency-keskkond|Alustab pildi ehitust vajalikul build-keskkonnal|
|COPY Gradle failid|Dependency caching|Väliste pakendite cache säilitamine Docker build’i jaoks|
|RUN dependencies|Sõltuvuste allalaadimine|Kiirem build, kui ainult lähtekood muutub|
|COPY src|Lähtekoodi lisamine|Kopeerib projekti Java lähtekoodi|
|RUN bootJar|Rakenduse ehitamine|Teeb käivitatava JAR-faili|
|Temurin base image|Kompaktne runtime-keskkond|Toodangut optimeeriv ja turvaline JVM|
|Non-root user|Turvalisuse parendamine|Kaitseb konteinerit privilege escalation’i eest|
|COPY jar|Ainult production artefakti kopeerimine|Vähendab pildi suurust ja turvariske|
|USER spring:spring|Non-root konteineri jooksutamine|Turvalisuse tagamine|
|EXPOSE 8081|Porta kuulamine|Võimaldab teenusele ligi pääseda väljastpoolt|
|HEALTHCHECK|Kontroll teenuse elususe üle|Tervisekontroll info orkestreerijale (nt Docker Swarm, Kubernetes)|
|CMD|Teenuse käivitamine|Käivitab Spring Boot JAR-faili|

Iga samm on vajalik, et saavutada efektiivne, turvaline ja skaleeritav konteineripilt Java Spring Boot rakendusele.

### Samm 3: Build MÕLEMAD Optimeeritud Images (15 min)

**Asukoht (User Service):** `/hostinger/labs/apps/backend-nodejs`

**⚠️ Oluline:** Docker image'i ehitamiseks pead olema rakenduse juurkataloogis (kus asub `Dockerfile.optimized`).

```bash
# === BUILD USER SERVICE (Node.js) ===
cd ../apps/backend-nodejs

# Build optimeeritud image
docker build -f Dockerfile.optimized -t user-service:1.0-optimized .

# === BUILD TODO SERVICE (Java) ===
# Asukoht: /hostinger/labs/apps/backend-java-spring
cd ../backend-java-spring

# Build optimeeritud image (multi-stage build teeb ka JAR'i)
docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .

# === VÕRDLE SUURUSI ===
docker images | grep -E 'user-service|todo-service'

# Oodatud väljund:
# REPOSITORY       TAG             SIZE
# user-service     1.0             ~305MB (vana, slim, single-stage)
# user-service     1.0-optimized   ~305MB (uus, slim, multi-stage)
# todo-service     1.0             ~230MB (vana)
# todo-service     1.0-optimized   ~180MB (uus) 📉 -22%
```

**ℹ️ Märkus User Service suuruse kohta:**
User Service pilt (image) jääb samaks (~305MB), sest MÕLEMAD versioonid kasutavad `node:18-slim`:
- Baasversioon (`1.0`): ~305MB - `node:18-slim`, single-stage
- Optimeeritud (`1.0-optimized`): ~305MB - `node:18-slim`, multi-stage

**Miks kasutame slim, mitte alpine?**
- Alpine crashib bcrypt native moodulitega (exit 139)
- Slim on suurem (~105MB vs ~5MB), aga töötab stabiilselt

**Mida võitsime optimeeritud versiooniga:**
✅ Multi-stage build (dependencies cached)
✅ Non-root user (security)
✅ Health check
✅ -60% kiirem rebuild
⚠️ Suurus jääb samaks (mõlemad ~305MB)

### Samm 4: Testi MÕLEMAD Optimeeritud Images (20 min)

```bash
# Genereeri JWT_SECRET (kui pole veel)
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET=$JWT_SECRET"
export JWT_SECRET

# Loo todo-network, kui pole veel olemas (Harjutus 3-st)
docker network create todo-network 2>/dev/null || true

# Veendu, et MÕLEMAD PostgreSQL containerid töötavad (Harjutus 4-st volumes'itega)
docker ps | grep postgres

# Kui ei tööta, käivita:
# docker run -d --name postgres-user --network todo-network \
#   -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
#   -e POSTGRES_DB=user_service_db \
#   -v postgres-user-data:/var/lib/postgresql/data postgres:16-alpine

# docker run -d --name postgres-todo --network todo-network \
#   -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
#   -e POSTGRES_DB=todo_service_db \
#   -v postgres-todo-data:/var/lib/postgresql/data postgres:16-alpine

# === KÄIVITA USER SERVICE (optimeeritud) ===
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

# === KÄIVITA TODO SERVICE (optimeeritud) ===
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

# === TESTI HEALTH CHECK'E ===
echo "=== User Service Health ==="
curl http://localhost:3001/health
# Oodatud: {"status":"OK","database":"connected"}

echo -e "\n=== Todo Service Health ==="
curl http://localhost:8082/health
# Oodatud: {"status":"UP"}

# Vaata health check'i status
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

### Samm 5: Testi End-to-End JWT Workflow Optimeeritud Süsteemiga (15 min)

**See on KÕIGE OLULISEM TEST - kinnitame, et optimeeritud süsteem töötab identitsioonilt!**

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

# 2. Login ja salvesta JWT token
TOKEN=$(curl -s -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"optimized@example.com","password":"test123"}' \
  | jq -r '.token')

echo "JWT Token: $TOKEN"

# 3. Kasuta tokenit Todo Service'is (optimeeritud!)
curl -X POST http://localhost:8082/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Optimeeritud süsteem töötab!",
    "description": "Image on väiksem, kiirem ja turvalisem!",
    "priority": "high"
  }' | jq

# Oodatud vastus:
# {
#   "id": 1,
#   "userId": 1,  <-- ekstraktitud JWT tokenist!
#   "title": "Optimeeritud süsteem töötab!",
#   ...
# }

# 4. Loe todos
curl -X GET http://localhost:8082/api/todos \
  -H "Authorization: Bearer $TOKEN" | jq

# 5. Võrdle resource kasutust

# Vana vs uus image
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}"

# Oodatud: Optimeeritud containerid kasutavad VÄHEM memory't
```

**🎉 KUI KÕIK TOIMIS - ÕNNITLEME!**

**Mida sa just saavutasid:**
1. ✅ User Service (optimeeritud) genereeris JWT tokeni
2. ✅ Todo Service (optimeeritud) valideeris tokenit (SAMA JWT_SECRET!)
3. ✅ Optimeeritud süsteem töötab IDENTITSIOONILT vanaga
4. ✅ AGA: Väiksemad images (-25-33%), health checks, non-root users!
5. ✅ TOOTMISEKS VALMIS mikroteenuste süsteem! 🚀

### Samm 6: Security Scan (Bonus - 10 min)

```bash
# Installi trivy (kui pole)
# sudo apt install trivy  # või
# brew install trivy

# Skanni MÕLEMAT optimeeritud image'i
echo "=== User Service Security Scan ==="
trivy image user-service:1.0-optimized

echo -e "\n=== Todo Service Security Scan ==="
trivy image todo-service:1.0-optimized

# Võrdle vana vs uus
trivy image user-service:1.0 > vana-user.txt
trivy image user-service:1.0-optimized > uus-user.txt

# Oodatud: Vähem turvaauke optimeeritud images (alpine + non-root)
```

### Samm 7: Layer Caching Test (10 min)

**Testime, kui hästi layer caching töötab rebuild'imisel:**

**Asukoht (User Service):** `/hostinger/labs/apps/backend-nodejs`

```bash
# === TEST 1: Rebuild ILMA muudatusteta ===
cd ../apps/backend-nodejs

# Rebuild User Service (peaks olema VÄGA kiire!)
time docker build -f Dockerfile.optimized -t user-service:1.0-optimized .
# Oodatud: "CACHED" iga layer jaoks, build ~2-5s

# Asukoht: /hostinger/labs/apps/backend-java-spring
cd ../backend-java-spring

# Rebuild Todo Service (peaks olema VÄGA kiire!)
time docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .
# Oodatud: "CACHED" enamuse layers jaoks, build ~10-20s

# === TEST 2: Rebuild KUI source code muutub ===

# User Service - muuda source code
# Asukoht: /hostinger/labs/apps/backend-nodejs
cd ../backend-nodejs
echo "// test comment" >> server.js

# Rebuild
time docker build -f Dockerfile.optimized -t user-service:1.0-optimized .
# Oodatud: Dependencies layer CACHED, ainult COPY . ja pärast rebuilditakse (~10-15s)

# Todo Service - muuda source code
# Asukoht: /hostinger/labs/apps/backend-java-spring
cd ../backend-java-spring
echo "// test comment" >> src/main/java/com/hostinger/todoapp/TodoApplication.java

# Rebuild
time docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .
# Oodatud: Gradle dependencies layer CACHED, ainult COPY src ja pärast rebuilditakse (~30-40s)
```

**Mida õppisid?**
- ✅ Dependencies on cached (ei rebuild kui `package.json` või `build.gradle` ei muutu!)
- ✅ Source code muudatused rebuiltavad ainult viimased layers
- ✅ Rebuild on **-60-80% kiirem** kui optimeeritud Dockerfile!

---

## 📊 Optimisatsioonide Võrdlus

### Võrdle Image Suurusi

```bash
# Võrdle MÕLEMA teenuse image suurusi
docker images | grep -E 'user-service|todo-service' | sort
```

### Node.js (User Service) Võrdlus

| Aspekt | Before (Harjutus 1) | After (Optimized) | Improvement |
| ------ | ------------------- | ----------------- | ----------- |
| **Size** | ~305MB | ~305MB | ⚠️ Same (both slim) |
| **Base image** | node:18-slim | node:18-slim (multi-stage) | ✅ |
| **Layers** | 5-6 | 8-10 (but cached!) | ✅ |
| **Build time (1st)** | 30s | 40s | ❌ +10s |
| **Build time (rebuild)** | 30s | 10s | 📉 -66% |
| **Security** | root user | non-root (nodejs:1001) | ✅ |
| **Health check** | ❌ | ✅ `healthcheck.js` | ✅ |
| **Caching** | ❌ Poor | ✅ Excellent (npm ci cached) | ✅ |
| **Stability** | ✅ töötab (bcrypt OK) | ✅ töötab (bcrypt OK) | ✅ |

**Selgitus:** Mõlemad kasutavad `node:18-slim` (sest bcrypt native moodulid). Optimeeritud versioon ei vähenda suurust, aga annab **palju kiiremad rebuild'id** (-66%) ja **parema security** (non-root user).

### Java (Todo Service) Võrdlus

| Aspekt | Before (Harjutus 1) | After (Optimized) | Improvement |
| ------ | ------------------- | ----------------- | ----------- |
| **Size** | ~230MB | ~180MB | 📉 -22% |
| **Base image** | JRE only | Multi-stage (JDK → JRE) | ✅ |
| **Layers** | 5-6 | 10-12 (but cached!) | ✅ |
| **Build time (1st)** | 60s | 90s | ❌ +30s |
| **Build time (rebuild)** | 60s | 20s | 📉 -66% |
| **Security** | root user | non-root (spring:1001) | ✅ |
| **Health check** | ❌ | ✅ `/health` endpoint | ✅ |
| **Caching** | ❌ Poor | ✅ Excellent (gradle deps cached) | ✅ |

### Node.js vs Java Võrdlus

| Metric | Node.js (User Service) | Java (Todo Service) |
|--------|------------------------|---------------------|
| **Base size (before)** | ~305MB | ~230MB |
| **Optimized size (after)** | ~305MB ⚠️ | ~180MB ✅ |
| **Size change** | ⚠️ 0% (same) | 📉 -22% |
| **Build time (1st)** | 40s | 90s |
| **Build time (rebuild)** | 10s | 20s |
| **Multi-stage benefit** | Dependencies layer | JDK → JRE separation |
| **Non-root user** | nodejs:1001 | spring:1001 |
| **Health check** | Custom JS script | Built-in /health endpoint |
| **Base image** | node:18-slim (both) | eclipse-temurin:17-jre-alpine |

**Järeldus:**
- ⚠️ User Service: suurus jääb samaks (~305MB), mõlemad kasutavad `node:18-slim` bcrypt'i tõttu
- ✅ Todo Service: pilt (image) väiksem (-50MB) multi-stage build'i tõttu
- ✅ Mõlemad on **production-ready ja töötavad stabiilselt**
- ✅ **Rebuild -60-80% kiirem mõlemas teenuses!**
- ✅ Security (non-root users) ja health checks mõlemas
- 📚 **Õppetund:** User Service optimisatsioon ei vähenda suurust (sama base image), aga annab **kiiremad rebuild'id** ja **parema security**

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [x] **2 optimeeritud pilti (images)** loodud
  - user-service:1.0-optimized (~305MB, sama kui 1.0 ⚠️ mõlemad slim)
  - todo-service:1.0-optimized (~180MB, -22% ✅)
- [x] Multi-stage builds töötavad (Node.js: deps → runtime, Java: JDK → JRE)
- [x] Layer caching toimib SUUREPÄRASELT (rebuild -60-80% kiirem!)
- [x] Non-root users kasutusel
  - User Service: nodejs:1001
  - Todo Service: spring:1001
- [x] Health checks lisatud MÕLEMASSE teenusesse
  - User Service: healthcheck.js
  - Todo Service: /health endpoint
- [x] Optimeeritud konteinerid töötavad (`docker ps` näitab "healthy")
- [x] End-to-End JWT workflow töötab identitsioonilt
- [x] .dockerignore failid on optimeeritud
- [x] Mõistad Alpine vs Debian (slim) trade-off'e native moodulitega
- [ ] Security scan läbitud (bonus, kui trivy installitud)

---

## 🎓 Parimad Tavad

1. ✅ Multi-stage builds (JDK → JRE, dependencies → runtime)
2. ✅ Layer caching (COPY dependencies enne source code'i)
3. ✅ .dockerignore fail (välistab tarbetud failid)
4. ✅ Non-root user (security)
5. ✅ Health check Dockerfile'is (monitoring)
6. ⚠️ **Alpine vs Debian:** Vali native moodulite järgi
   - ✅ Alpine: väiksem, kui pole native dependencies
   - ✅ Debian Slim: suurem, AGA töötab native moodulitega (bcrypt, node-gyp)
   - 📚 **Reegel:** Töökindlus > pildi (image) suurus
7. ✅ Gradle/npm --no-daemon (vähem memory, kiirem build)
8. ✅ Testi optimeeritud pilte (images) end-to-end workflow'ga

---

## 🎉 Õnnitleme! Mida Sa Õppisid?

### ✅ Tehnilised Oskused

**Docker Optimization:**
- ✅ Multi-stage builds (Node.js: deps → runtime, Java: JDK → JRE)
- ✅ Layer caching optimization (dependencies eraldi layer)
- ✅ .dockerignore optimization (väiksem build context)
- ✅ Non-root users (security)
- ✅ Health checks (monitoring)
- ⚠️ **Alpine vs Debian trade-off'id** (native moodulite tõttu)

**Võrdlus Enne vs Pärast:**
- 📉 Todo Service: -22% väiksem pilt (image)
- ⚠️ User Service: sama suurus (~305MB), mõlemad kasutavad `node:18-slim`
- 📉 Rebuild kiirus: -60-80% MÕLEMAS teenuses
- ✅ Security: root → non-root
- ✅ Monitoring: ❌ → health checks
- ✅ Caching: halb → suurepärane (dependencies cached)

### 🔄 Progressioon Läbi Kõigi 5 Harjutuse

**Harjutus 1: Single Container**
- ✅ Lõime esimesed Dockerfile'id (User Service + Todo Service)
- ✅ Build'isime Docker images
- ✅ Õppisid, miks containerid crashivad (andmebaas puudub)
- ❌ Ei optimeeri midagi

**Harjutus 2: Multi-Container**
- ✅ Käivitasime 4 containerit koos (2 DB + 2 teenust)
- ✅ Implementeerisime JWT-põhise autentimise
- ✅ End-to-End mikroteenuste workflow
- ❌ Kasutasime deprecated --link

**Harjutus 3: Custom Networks**
- ✅ Lõime custom Docker network
- ✅ Proper networking DNS-iga (automaatne!)
- ✅ Network isolation (security)
- ❌ Andmed kaovad container kustutamisel

**Harjutus 4: Volumes**
- ✅ Data persistence! (containers can fail, data survives)
- ✅ Backup/restore strateegia
- ✅ Disaster recovery
- ❌ Images siiski optimeerimata

**Harjutus 5: Optimization (PRAEGU)**
- ✅ Multi-stage builds (mõlemas teenuses)
- ✅ Layer caching (-60-80% kiirem rebuild)
- ✅ Security (non-root users)
- ✅ Health checks
- ⚠️ Mõlemad User Service versioonid kasutavad `node:18-slim` (bcrypt native moodulid)
- ✅ Todo Service: -22% väiksem pilt (image)
- ⚠️ User Service: sama suurus (~305MB), optimisatsioon annab kiiremad rebuild'id
- ✅ End-to-End test optimeeritud süsteemiga

### 🏆 LÕPPTULEMUS: Production-Ready Docker Setup!

**Mis sul nüüd on:**
- ✅ 2 optimeeritud mikroteenust (User Service + Todo Service)
- ✅ 2 andmebaasi andmehoidlate (volumes) abil (data persistence)
- ✅ Kohandatud võrk (custom network) (proper DNS resolution)
- ✅ Health monitoring (healthy konteinerid)
- ✅ Security (non-root users)
- ✅ Fast rebuilds (layer caching - 60-80% kiirem!)
- ✅ End-to-End tested (JWT workflow töötab!)
- 📚 **Õppetund:** Töökindlus > pildi (image) suurus (Alpine vs Debian)

**See on TÄIELIK production-ready mikroteenuste süsteem!** 🎉🚀

---

## 🚀 Järgmised Sammud

Sa oskad nüüd:
1. ✅ Build'ida Docker image'eid
2. ✅ Käivitada multi-container setup'e
3. ✅ Kasutada custom networks
4. ✅ Säilitada andmeid volumes'iga
5. ✅ Optimeerida image suurust ja build kiirust

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

**🎉 ÕNNITLEME! OLED EDUKALT LÄBINUD LAB 01! 🎉**

**Mida saavutasid 5 harjutusega:**
- ✅ Docker põhitõed (pildid/images, konteinerid, võrgud/networks, andmehoidlad/volumes)
- ✅ Mikroteenuste arhitektuur (User Service + Todo Service)
- ✅ Production best practices (optimization, security, monitoring)
- ✅ End-to-End tested süsteem (JWT workflow)
- 📚 **Praktiline õppetund:** Alpine vs Debian trade-off'id native moodulitega

**Järgmine:** [Lab 2: Docker Compose](../../02-docker-compose-lab/README.md)

Seal õpid:
- 🚀 Halda multi-container setup'e YAML failidega
- 🚀 Üks käsk käivitab KOGU süsteemi: `docker compose up`
- 🚀 Development vs Production konfiguratsioonid
- 🚀 Scaling (käivita 3 Todo Service instance't korraga!)

**Näeme Lab 2-s!** 🐳
