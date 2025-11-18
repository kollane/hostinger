# Harjutus 5: Image Optimization

**Kestus:** 45 minutit
**Eesmärk:** Optimeeri Docker image suurust ja build kiirust

---

## 🎯 Õpieesmärgid

- ✅ Kasutada alpine base images
- ✅ Implementeerida multi-stage builds
- ✅ Optimeerida layer caching
- ✅ Kasutada .dockerignore
- ✅ Skanneerida image turvaauke

---

## 📝 Sammud

### Samm 1: Mõõda Algne Suurus

```bash
cd ../../apps/backend-java-spring

# Vaata praeguse image suurust
docker images todo-service:1.0

# Peaks olema ~200-250MB
```

### Samm 2: Optimeeri Dockerfile

Loo uus `Dockerfile.optimized`:

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

### Samm 4: Testi Optimeeritud Image

```bash
# Käivita
docker run -d \
  --name todo-service-opt \
  --network todo-network \
  -p 8082:8081 \
  -e DB_HOST=postgres-todo \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-secret-key \
  todo-service:1.0-optimized

# Testi
curl http://localhost:8082/health

# Vaata health check'i
docker ps  # Peaks näitama health status
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

| Aspect         | Before    | After         |
| -------------- | --------- | ------------- |
| **Size**       | ~250MB    | ~180MB        |
| **Layers**     | 8+        | 10-12 (but optimized) |
| **Build time** | 60s       | 20s (cached)  |
| **Security**   | root user | non-root user |
| **Health check** | ❌      | ✅            |

---

## ✅ Kontrolli

- [x] Optimeeritud image on väiksem
- [x] Multi-stage build töötab (JDK build → JRE runtime)
- [x] Layer caching toimib (dependencies cached)
- [x] Non-root user kasutusel
- [x] Health check lisatud
- [ ] Security scan läbitud

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

**Õnnitleme! Oled läbinud Labor 1! 🎉**

**Järgmine:** [Labor 2: Docker Compose](../../02-docker-compose-lab/README.md)
