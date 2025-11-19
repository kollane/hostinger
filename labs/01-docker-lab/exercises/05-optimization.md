# Harjutus 5: Image Optimization

**Kestus:** 45 minutit
**Eesmärk:** Optimeeri Docker image suurust ja build kiirust

**Eeldus:** [Harjutus 1: Single Container](01-single-container.md) läbitud ✅

---

## 📋 Ülevaade

**Mäletad Harjutus 1-st?** Lõime lihtsa Dockerfile'i, mis toimis. Aga nüüd õpime, kuidas teha seda **PALJU paremaks**!

**Praegune Dockerfile (Harjutus 1) probleemid:**
- ❌ Liiga suur image (~200-250MB)
- ❌ Build on aeglane (rebuild iga source muudatuse korral)
- ❌ Ei kasuta layer caching'ut efektiivselt
- ❌ Runs as root (security risk!)
- ❌ Pole health check'i

**Selles harjutuses:**
- ✅ Multi-stage build (JDK build → JRE runtime)
- ✅ Layer caching optimization (dependencies cached)
- ✅ Väiksem image suurus (alpine images)
- ✅ Security (non-root user)
- ✅ Health check

---

## 🎯 Õpieesmärgid

- ✅ Kasutada alpine base images
- ✅ Implementeerida multi-stage builds
- ✅ Optimeerida layer caching (dependencies eraldi)
- ✅ Kasutada .dockerignore (juba Harjutus 1-s!)
- ✅ Lisa health check
- ✅ Kasuta non-root user
- ✅ Skanneerida image turvaauke (bonus)

---

## 📝 Sammud

### Samm 1: Mõõda Algne Suurus (5 min)

```bash
cd ../apps/backend-java-spring

# Vaata Harjutus 1-st loodud image suurust
docker images todo-service:1.0

# Peaks olema ~200-250MB
# Näiteks:
# REPOSITORY      TAG    IMAGE ID      CREATED        SIZE
# todo-service    1.0    abc123def     2 hours ago    230MB
```

**Analyseer:**
- Kui suur on image?
- Mitu layer'it on (vaata `docker history todo-service:1.0`)?
- Kui kiire on rebuild, kui muudad source code'i?

```bash
# Vaata layer'eid
docker history todo-service:1.0
# Näed: FROM, WORKDIR, COPY, EXPOSE, CMD layers
```

### Samm 2: Optimeeri Dockerfile (20 min)

Loo uus `Dockerfile.optimized` mis lahendab KÕIK probleemid:

**💡 Abi vajadusel:**
```bash
# Vaata näidislahendust
cat ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized
```

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
COPY --from=builder /app/build/libs/todo-service.jar app.jar

# Kasuta non-root userit
USER spring:spring

EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/health || exit 1

CMD ["java", "-jar", "app.jar"]
```

### Samm 3: Build Optimeeritud Image

```bash
# Build uus image (multi-stage build teeb ka JAR'i)
docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .

# Võrdle suurusi
docker images | grep todo-service
```

### Samm 4: Testi Optimeeritud Image (10 min)

```bash
# Genereeri JWT_SECRET (kui pole veel)
openssl rand -base64 32
# Kopeeri väljund

# Loo todo-network, kui pole veel olemas (Harjutus 3-st)
docker network create todo-network 2>/dev/null || true

# Veendu, et postgres-todo töötab (Harjutus 4-st)
docker ps | grep postgres-todo
# Kui ei tööta, käivita:
# docker run -d --name postgres-todo --network todo-network \
#   -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
#   -e POSTGRES_DB=todo_service_db \
#   -v postgres-todo-data:/var/lib/postgresql/data postgres:16-alpine

# Käivita optimeeritud image
docker run -d \
  --name todo-service-opt \
  --network todo-network \
  -p 8082:8081 \
  -e DB_HOST=postgres-todo \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=<sinu-genereeritud-secret-siia> \
  todo-service:1.0-optimized

# Vaata logisid
docker logs -f todo-service-opt
# Peaks nägema: "Started TodoApplication"

# Testi (teises terminalis)
curl http://localhost:8082/health
# Oodatud: {"status":"UP"}

# Vaata health check'i status
docker ps
# HEALTH peaks näitama: "healthy" (mitte "starting" või "unhealthy")
```

**Võrdle:**
```bash
# Vana vs uus
docker ps -a --format "table {{.Names}}\t{{.Status}}"
# todo-service        Up (Harjutus 1 image)
# todo-service-opt    Up (healthy) - näed health status!
```

### Samm 5: Security Scan (Bonus)

```bash
# Installi trivy (kui pole)
# sudo apt install trivy  # või
# brew install trivy

# Skanni image
trivy image todo-service:1.0-optimized

# Vaata turvaauke
```

### Samm 6: Layer Caching Test

```bash
# Rebuild ilma muudatusteta
docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .
# Peaks kasutama cached layers!

# Muuda midagi source code'is
echo "// test comment" >> src/main/java/com/hostinger/todoapp/TodoApplication.java

# Rebuild
docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .
# Ainult viimased layer'id rebuilditakse (dependencies on cached!)
```

---

## 📊 Optimisatsioonide Võrdlus

Vaatame numbrid:

```bash
# Võrdle image suurusi
docker images | grep todo-service
```

| Aspekt | Before (Harjutus 1) | After (Optimized) | Improvement |
| ------ | ------------------- | ----------------- | ----------- |
| **Size** | ~230-250MB | ~180-200MB | 📉 -30% |
| **Base image** | JRE only | Multi-stage (JDK → JRE) | ✅ |
| **Layers** | 5-6 | 10-12 (but cached!) | ✅ |
| **Build time (1st)** | 60s | 90s | ❌ (longer) |
| **Build time (rebuild)** | 60s | 20s | 📉 -66% |
| **Security** | root user | non-root (spring:1001) | ✅ |
| **Health check** | ❌ | ✅ `/health` endpoint | ✅ |
| **Caching** | ❌ Poor | ✅ Excellent | ✅ |

**Järeldus:**
- ✅ Väiksem image
- ✅ Kiirem rebuild (dependencies cached!)
- ✅ Turvalisem (non-root)
- ✅ Health monitoring
- ❌ Esimene build pisut aeglasem (aga see on OK!)

---

## ✅ Kontrolli

- [x] Optimeeritud image on väiksem (võrdle `docker images`)
- [x] Multi-stage build töötab (JDK build → JRE runtime)
- [x] Layer caching toimib (rebuild on kiire!)
- [x] Non-root user kasutusel (`USER spring:spring`)
- [x] Health check lisatud (`docker ps` näitab "healthy")
- [x] Container töötab korrektselt (`/health` endpoint vastab)
- [ ] Security scan läbitud (bonus, kui trivy installitud)

---

## 🎓 Parimad Tavad

1. ✅ Kasuta alpine images
2. ✅ Multi-stage builds (JDK → JRE)
3. ✅ Layer caching (COPY build.gradle enne src/)
4. ✅ .dockerignore fail
5. ✅ Non-root user
6. ✅ Gradle --no-daemon (vähem memory)
7. ✅ Health check Dockerfile'is

---

## 🎓 Mida Õppisime?

### Progressioon läbi kõigi 5 harjutuse:

**Harjutus 1:** Algne Dockerfile
- ✅ Lihtne, toimib
- ❌ Ei optimeeri midagi

**Harjutus 2:** Multi-container
- ✅ Lisasime PostgreSQL
- ❌ Kasutasime deprecated --link

**Harjutus 3:** Custom networks
- ✅ Proper networking DNS-iga
- ❌ Andmed kaovad container kustutamisel

**Harjutus 4:** Volumes
- ✅ Data persistence!
- ❌ Image siiski optimeerimata

**Harjutus 5:** Optimization (PRAEGU)
- ✅ Optimeeritud image
- ✅ Multi-stage build
- ✅ Layer caching
- ✅ Security (non-root)
- ✅ Health check

**TULEMUS:** Production-ready Docker setup! 🎉

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

**Vastus: Docker Compose!** (Labor 2)

---

**Õnnitleme! Oled läbinud Lab 1! 🎉**

**Järgmine:** [Lab 2: Docker Compose](../../02-docker-compose-lab/README.md) - Halda multi-container setup'e YAML failidega!
