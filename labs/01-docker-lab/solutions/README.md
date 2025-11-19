# Labor 1 Lahendused

See kaust sisaldab näidis-lahendusi Labor 1 harjutustele **mõlema teenuse** jaoks.

---

## 📂 Struktuur

```
solutions/
├── README.md                    # See fail
├── backend-nodejs/              # User Service (Node.js)
│   ├── Dockerfile               # Lihtne Dockerfile (Harjutus 1)
│   ├── Dockerfile.optimized     # Optimeeritud (Harjutus 5)
│   ├── .dockerignore
│   └── healthcheck.js           # Health check script
└── backend-java-spring/         # Todo Service (Java)
    ├── Dockerfile               # Lihtne Dockerfile (Harjutus 1)
    ├── Dockerfile.optimized     # Optimeeritud (Harjutus 5)
    └── .dockerignore
```

---

## 🚀 Kasutamine

### User Service (Node.js)

#### Lihtne Dockerfile (Harjutus 1)

```bash
# Mine apps/backend-nodejs kausta
cd ../../apps/backend-nodejs

# Kopeeri Dockerfile
cp ../../01-docker-lab/solutions/backend-nodejs/Dockerfile .
cp ../../01-docker-lab/solutions/backend-nodejs/.dockerignore .

# Build Docker image
docker build -t user-service:1.0 .

# Käivita
docker run -d --name user-service -p 3000:3000 \
  -e DB_HOST=postgres-user \
  -e JWT_SECRET=test-secret \
  user-service:1.0
```

#### Optimeeritud Dockerfile (Harjutus 5)

```bash
# Kopeeri optimeeritud versioon
cp ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized .
cp ../../01-docker-lab/solutions/backend-nodejs/healthcheck.js .

# Build (multi-stage build)
docker build -f Dockerfile.optimized -t user-service:1.0-optimized .

# Võrdle suurusi
docker images | grep user-service
# user-service:1.0            ~180MB
# user-service:1.0-optimized  ~120MB (-33%)
```

### Todo Service (Java)

#### Lihtne Dockerfile (Harjutus 1)

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

#### Optimeeritud Dockerfile (Harjutus 5)

```bash
# Kopeeri optimeeritud versioon
cp ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized .

# Build (multi-stage build teeb ka JAR'i)
docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .

# Võrdle suurusi
docker images | grep todo-service
# todo-service:1.0            ~230MB
# todo-service:1.0-optimized  ~180MB (-22%)
```

---

## 📊 Image Suuruste Võrdlus

### User Service (Node.js)

| Versioon | Suurus | Kirjeldus |
|----------|--------|-----------|
| **Lihtne** | ~180MB | node:18-alpine + npm install |
| **Optimeeritud** | ~120MB | Multi-stage (dependencies → runtime) + non-root |

**Parandused optimeeritud versioonis:**
- Multi-stage build (dependencies cached eraldi)
- Non-root user (nodejs:1001)
- Health check (healthcheck.js)
- `npm ci --only=production` (väiksem suurus)

### Todo Service (Java)

| Versioon | Suurus | Kirjeldus |
|----------|--------|-----------|
| **Lihtne** | ~230MB | eclipse-temurin:17-jre-alpine + JAR |
| **Optimeeritud** | ~180MB | Multi-stage (Gradle build → JRE runtime) + non-root |

**Parandused optimeeritud versioonis:**
- Multi-stage build (Gradle JDK → JRE runtime)
- Non-root user (spring:1001)
- Health check (wget-based)
- Layer caching (dependencies cached eraldi)
- Gradle --no-daemon (vähem memory kasutust)

---

## 💡 Märkused

- ⚠️ Need on **näidis-lahendused** - proovi esmalt ise!
- 💪 Õppimine toimub läbi proovimise ja vigade parandamise
- 📚 Kasuta neid ainult kui jääd hätta
- ✅ Mõlemad teenused on production-ready:
  - Alpine base images (väiksem suurus)
  - Non-root users (security)
  - Health checks (monitoring)
  - Layer caching (kiirem rebuild)

---

**Edu harjutustega! 🐳**
