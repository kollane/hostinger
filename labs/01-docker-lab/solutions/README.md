# Labor 1 Lahendused

See kaust sisaldab näidis-lahendusi Labor 1 harjutustele.

---

## 📂 Struktuur

```
solutions/
├── README.md                    # See fail
└── backend-java-spring/
    ├── Dockerfile               # Lihtne Dockerfile (Harjutus 1)
    ├── Dockerfile.optimized     # Optimeeritud (Harjutus 5)
    └── .dockerignore
```

---

## 🚀 Kasutamine

### Lihtne Dockerfile

```bash
# Mine apps/backend-java-spring kausta
cd ../../apps/backend-java-spring

# Kopeeri Dockerfile
cp ../../01-docker-lab/solutions/backend-java-spring/Dockerfile .
cp ../../01-docker-lab/solutions/backend-java-spring/.dockerignore .

# Build JAR
./gradlew clean bootJar

# Build Docker image
docker build -t todo-service:1.0 .

# Käivita
docker run -d --name todo-service -p 8081:8081 \
  -e DB_HOST=postgres-todo \
  -e JWT_SECRET=test-secret \
  todo-service:1.0
```

### Optimeeritud Dockerfile

```bash
# Kopeeri optimeeritud versioon
cp ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized .

# Build (multi-stage build teeb ka JAR'i)
docker build -f Dockerfile.optimized -t todo-service:1.0-opt .

# Võrdle suurusi
docker images | grep todo-service
```

---

## 📊 Image Suuruste Võrdlus

| Versioon | Suurus | Kirjeldus |
|----------|--------|-----------|
| **Lihtne** | ~200-250MB | eclipse-temurin:17-jre-alpine + JAR |
| **Optimeeritud** | ~180MB | Multi-stage (Gradle build → JRE runtime) + non-root |

---

## 💡 Märkused

- Need on **näidis-lahendused** - proovi esmalt ise!
- Optimeeritud versioon sisaldab:
  - Multi-stage build (Gradle JDK → JRE runtime)
  - Non-root user (spring:spring)
  - Health check
  - Layer caching (dependencies cached eraldi)
  - Gradle --no-daemon (vähem memory kasutust)

---

**Kasuta neid ainult kui jääd hätta! Õppimine toimub läbi proovimise. 💪**
