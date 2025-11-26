# Harjutus 5: Pildi (Image) Optimeerimine

**Kestus:** 45 minutit
**Eesmärk:** Optimeeri Docker pildi (image) suurust ja ehituse (build) kiirust

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

# 3. Kontrolli olemasolevaid pilte (images)
docker images | grep -E 'user-service|todo-service'
# Oodatud: user-service:1.0 ja todo-service:1.0
```

**Kui midagi puudub:**
- 🔗 Võrk (Network) `todo-network` → [Harjutus 3, Samm 2](03-networking.md)
- 🔗 PostgreSQL seadistus (setup) (andmehoidlad (volumes) + tabelid) → [Harjutus 4, Sammud 2-4](04-volumes.md)
- 🔗 Baaspildid (base images) → [Harjutus 1A](01a-single-container-nodejs.md) ja [Harjutus 1B](01b-single-container-java.md) või käivita `./setup.sh`

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📋 Ülevaade

**Mäletad Harjutus 1-st?** Lõime lihtsa Dockerfile'i, mis toimis. Aga nüüd õpime, kuidas teha seda **paremaks**!

**Praegune Dockerfile (Harjutus 1) probleemid - MÕLEMAS teenuses (service):**
- ❌ Liiga suur pilt (image) (~200-230MB)
- ❌ Ehitus (build) on aeglane (rebuild iga source muudatuse korral)
- ❌ Ei kasuta kihtide vahemälu (layer caching) efektiivselt
- ❌ Töötab root'ina (turvarisk!)
- ❌ Pole seisukorra kontrolli (health check)

**Selles harjutuses - optimeerime MÕLEMAT teenust (service):**
- ✅ **Node.js (User Teenus (Service)):** Mitme-sammuline (multi-stage) ehitus (build) (sõltuvused (dependencies) → runtime)
- ✅ **Java (Todo Teenus (Service)):** Mitme-sammuline (multi-stage) ehitus (build) (JDK build → JRE runtime)
- ✅ Kihtide vahemälu (layer caching) optimeerimine (sõltuvused (dependencies) on vahemälus (cached))
- ✅ Turvalisus (mitte-juurkasutajad (non-root users): nodejs:1001, spring:1001)
- ✅ Seisukorra kontrollid (health checks)

---

## 🎯 Õpieesmärgid

- ✅ Implementeerida mitme-sammulised (multi-stage) ehitused (builds) (Node.js ja Java)
- ✅ Optimeerida kihtide vahemälu (layer caching) (sõltuvused (dependencies) eraldi)
- ✅ Parandada .dockerignore faile
- ✅ Lisa seisukorra kontrollid (health checks) mõlemasse teenusesse (service)
- ✅ Kasuta mitte-juurkasutajaid (non-root users) (nodejs:1001, spring:1001)
- ✅ Võrrelda Node.js vs Java optimeerimise tulemusi
- ✅ Testida End-to-End workflow optimeeritud süsteemiga

---

## 🖥️ Sinu Testimise Konfiguratsioon

### SSH Ühendus VPS-iga
```bash
ssh labuser@93.127.213.242 -p [SINU-PORT]
```

| Õpilane | SSH Port | Password |
|---------|----------|----------|
| student1 | 2201 | student1 |
| student2 | 2202 | student2 |
| student3 | 2203 | student3 |

### Testimine

**SSH Sessioonis (VPS sees):**
- Kõik `curl http://localhost:...` käsud käivita siin
- Näide: `curl http://localhost:3000/health`

💡 **Frontend ja brauserist testimine tuleb Lab 2 Exercise 2-s**

---

## 📝 Sammud

### Samm 1: Uuri mõlema teenuse algset suurust (10 min)

```bash
# Vaata mõlema Harjutus 1-st loodud pildi (image) suurust
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
- Kui suur on User Service image? (~180MB)
- Kui suur on Todo Service image? (~230MB)
- Mitu layer'it on igal? (5-6 layer'it)
- Kui kiire on rebuild, kui muudad source code'i? (Aeglane - kõik rebuilditakse!)

### Samm 2: Optimeeri mõlema rakenduse Dockerfaili (30 min)

Loome optimeeritud Dockerfailid mõlemale teenusele.

#### 2a. User Service (Node.js) Optimization

**⚠️ Oluline:** Dockerfile asub rakenduse juurkataloogis.

**Rakenduse juurkataloog:** `/hostinger/labs/apps/backend-nodejs`

```bash
cd ../apps/backend-nodejs
```

Loo uus `Dockerfile.optimized`:

```bash
vim Dockerfile.optimized
```

**💡 Abi vajadusel:**
Vaata näidislahendust: `/hostinger/labs/01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized`

**📖 Multi-stage builds ja Node.js optimeerimine:**
- [Peatükk 06: Dockerfile - Multi-stage Builds](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md) selgitab multi-stage build'ide põhitõed
- [Peatükk 06A: Node.js Konteineriseerimise Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md) selgitab `npm ci`, dependency caching, non-root users

**Näidis:**

```dockerfile
# Stage 1: Dependencies
FROM node:22-slim AS dependencies
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

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s \
  CMD node healthcheck.js || exit 1

CMD ["node", "server.js"]
```

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

#### 2b. Todo Service (Java) Optimization

**Rakenduse juurkataloog:** `/hostinger/labs/apps/backend-java-spring`

```bash
cd ../backend-java-spring
```

Loo uus `Dockerfile.optimized`:

```bash
vim Dockerfile.optimized
```

**💡 Abi vajadusel:**
Vaata näidislahendust: `/hostinger/labs/01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized`

**📖 Multi-stage builds ja Java optimeerimine:**
- [Peatükk 06: Dockerfile - Multi-stage Builds](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md) selgitab multi-stage build'ide põhitõed (JDK → JRE)
- [Peatükk 06A: Java Spring Boot Konteineriseerimise Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md) selgitab Gradle dependency caching, JVM memory tuning, non-root users

**Näidis:**

```dockerfile
# Optimeeritud Dockerfile Todo Service jaoks (Harjutus 5)
# Multi-stage build: Gradle build → JRE runtime
# Eelised: väiksem image, layer caching, non-root user, health check

# Stage 1: Build
FROM gradle:8.11-jdk21-alpine AS builder

WORKDIR /app

# Kopeeri Gradle failid (dependencies caching jaoks)
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Download dependencies (cached kui build.gradle ei muutu)
RUN gradle dependencies --no-daemon

# Kopeeri source code ja build JAR
COPY src ./src
RUN gradle bootJar --no-daemon

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

### Samm 3: Ehita mõlemad optimeeritud Docker pildid (Images) (15 min)

**Rakenduse juurkataloog (User Service):** `/hostinger/labs/apps/backend-nodejs`

**⚠️ Oluline:** Docker pildi (image) ehitamiseks pead olema rakenduse juurkataloogis (kus asub `Dockerfile.optimized`).

```bash
# === BUILD USER SERVICE (Node.js) ===
cd ../backend-nodejs

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
User Service pilt (image) jääb samaks (~305MB), sest mõlemad versioonid kasutavad `node:21-slim`.

**Mida võitsime optimeeritud versiooniga:**
✅ Multi-stage build (dependencies cached eraldi kihina)
✅ Non-root user (security parandus)
✅ Health check (automaatne tervise kontroll)
✅ -60% kiirem rebuild (dependency cache)

### Samm 4: Testi MÕLEMAD Optimeeritud Images (20 min)

```bash
# Genereeri JWT_SECRET (kui pole veel)
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET=$JWT_SECRET"
export JWT_SECRET

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

### Samm 6: Security Scan ja Vulnerability Assessment (10 min)

**Image'i turvaaukude (vulnerabilities) skannimine on KRIITILINE tootmises!**

**📖 Põhjalik käsitlus:** [Peatükk 06B: Docker Image Security ja Vulnerability Scanning](../../../resource/06B-Docker-Image-Security-ja-Vulnerability-Scanning.md) selgitab:
- CVE ja CVSS skoorid (mis on turvaaugud, kuidas neid hinnata)
- Docker Scout ja Trivy kasutamine (installimise juhised, kõik käsud, raportid)
- Security best practices (non-root users, minimal base images, health checks, base image uuendamise strateegia)
- CI/CD integratsioon (GitHub Actions, GitLab CI näited)

**Siin on kiired käsud testimiseks:**

#### Docker Scout (sisseehitatud, kiire)

```bash
# Skanni mõlemat optimeeritud pilti
docker scout cves user-service:1.0-optimized
docker scout cves todo-service:1.0-optimized

# Võrdle vana vs uus
docker scout compare user-service:1.0 --to user-service:1.0-optimized

# Soovitused (recommendations)
docker scout recommendations user-service:1.0-optimized
```

#### Trivy (põhjalikum, CI/CD jaoks)

```bash
# Variant A: Lokaalne binaar (kui installitud)
trivy image --severity HIGH,CRITICAL user-service:1.0-optimized
trivy image --severity HIGH,CRITICAL todo-service:1.0-optimized

# Variant B: Docker konteiner (no installation needed!)
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
- ✅ Optimeeritud image'd võivad sisaldada vähem vulnerabilities't (sõltub base image'i versioonist)
- ✅ Non-root users on kasutuses (nodejs:1001, spring:1001) ✅
- ✅ Health checks lisatud ✅

**Järgmised sammud:**
1. Loe [Peatükk 06B](../../../resource/06B-Docker-Image-Security-ja-Vulnerability-Scanning.md) põhjalikuks uurimiseks
2. Parandanud CRITICAL ja HIGH CVE'd enne production'i
3. Lisa automaatne skannimine CI/CD pipeline'i (juhised peatükis 06B)

### Samm 7: Layer Caching Test (10 min)

**Testime, kui hästi layer caching töötab rebuild'imisel:**

**Rakenduse juurkataloog (User Service):** `/hostinger/labs/apps/backend-nodejs`

```bash
# === TEST 1: Rebuild ILMA muudatusteta ===
cd ../apps/backend-nodejs
pwd  # Veendu, et oled õiges kataloogis

# Rebuild User Service (peaks olema VÄGA kiire!)
time docker build -f Dockerfile.optimized -t user-service:1.0-optimized .
# Oodatud: "CACHED" iga layer jaoks, build ~2-5s

# Asukoht: /hostinger/labs/apps/backend-java-spring
cd ../backend-java-spring
pwd  # Veendu, et oled õiges kataloogis

# Rebuild Todo Service (peaks olema VÄGA kiire!)
time docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .
# Oodatud: "CACHED" enamuse layers jaoks, build ~10-20s

# === TEST 2: Rebuild KUI source code muutub ===

# User Service - muuda source code
# Asukoht: /hostinger/labs/apps/backend-nodejs
cd ../backend-nodejs
pwd  # Veendu, et oled õiges kataloogis
echo "// test comment" >> server.js

# Rebuild
time docker build -f Dockerfile.optimized -t user-service:1.0-optimized .
# Oodatud: Dependencies layer CACHED, ainult COPY . ja pärast rebuilditakse (~10-15s)

# Todo Service - muuda source code
# Asukoht: /hostinger/labs/apps/backend-java-spring
cd ../backend-java-spring
pwd  # Veendu, et oled õiges kataloogis
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
| **Base image** | node:22-slim | node:22-slim (multi-stage) | ✅ |
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
| **Base image** | node:22-slim (both) | eclipse-temurin:21-jre-alpine |

**Järeldus:**
- ⚠️ User Service: suurus jääb samaks (~305MB), sest mõlemad versioonid kasutavad sama baaspilti (base image)
- ✅ Todo Service: pilt (image) väiksem (-50MB) multi-stage build'i tõttu (JDK → JRE)
- ✅ Mõlemad on production-ready ja töötavad stabiilselt
- ✅ **Rebuild -60-80% kiirem mõlemas teenuses!** (dependency caching)
- ✅ Security (non-root users) ja health checks mõlemas
- 📚 **Õppetund:** Multi-stage build annab kiiremad rebuild'id ja parema security, isegi kui suurus jääb samaks

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [x] **2 optimeeritud pilti (images)** loodud
  - user-service:1.0-optimized (~305MB, sama kui 1.0)
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
- [x] Security scan läbitud (Docker Scout + Trivy)

---

## 🎓 Parimad Tavad

1. ✅ Multi-stage builds (JDK → JRE, dependencies → runtime)
2. ✅ Layer caching (COPY dependencies enne source code'i)
3. ✅ .dockerignore fail (välistab tarbetud failid)
4. ✅ Non-root user (security)
5. ✅ Health check Dockerfile'is (monitoring)
6. ✅ Gradle/npm --no-daemon (vähem memory, kiirem build)
7. ✅ Testi optimeeritud pilte (images) end-to-end workflow'ga

---

## 🎉 Õnnitleme! Mida Sa Õppisid?

### ✅ Tehnilised Oskused

**Docker Optimization:**
- ✅ Multi-stage builds (Node.js: deps → runtime, Java: JDK → JRE)
- ✅ Layer caching optimization (dependencies eraldi layer)
- ✅ .dockerignore optimization (väiksem build context)
- ✅ Non-root users (security)
- ✅ Health checks (monitoring)

**Võrdlus Enne vs Pärast:**
- 📉 Todo Service: -22% väiksem pilt (image)
- ⚠️ User Service: sama suurus, mõlemad kasutavad `node:21-slim`
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
- ⚠️ Mõlemad User Service versioonid kasutavad `node:21-slim` (bcrypt native moodulid)
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
- 📚 **Õppetund:** Töökindlus > pildi (image) suurus

**See on TÄIELIK production-ready mikroteenuste süsteem!** 🎉🚀

---

## 🚀 Järgmised Sammud

Sa oskad nüüd:
1. ✅ Ehitada Docker pilte (images)
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
- 📚 **Praktiline õppetund:** Multi-stage builds ja layer caching optimeerimiseks

**Järgmine:** [Lab 2: Docker Compose](../../02-docker-compose-lab/README.md)

Seal õpid:
- 🚀 Halda multi-container setup'e YAML failidega
- 🚀 Üks käsk käivitab KOGU süsteemi: `docker compose up`
- 🚀 Development vs Production konfiguratsioonid
- 🚀 Scaling (käivita 3 Todo Service instance't korraga!)

**Näeme Lab 2-s!** 🐳
