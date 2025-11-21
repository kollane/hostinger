# Labor 1 Lahendused

See kaust sisaldab näidis-lahendusi Labor 1 harjutustele **mõlema teenuse (service)** jaoks.

---

## 📂 Struktuur

```
solutions/
├── README.md                    # See fail
├── backend-nodejs/              # User Teenus (Service) (Node.js)
│   ├── Dockerfile               # Lihtne Dockerfile (Harjutus 1)
│   ├── Dockerfile.optimized     # Optimeeritud (Harjutus 5)
│   ├── .dockerignore
│   └── healthcheck.js           # Seisukorra kontrolli (health check) skript
└── backend-java-spring/         # Todo Teenus (Service) (Java)
    ├── Dockerfile               # Lihtne Dockerfile (Harjutus 1)
    ├── Dockerfile.optimized     # Optimeeritud (Harjutus 5)
    └── .dockerignore
```

---

## 🚀 Kasutamine

### User Teenus (Service) (Node.js)

#### Lihtne Dockerfile (Harjutus 1)

```bash
# Mine apps/backend-nodejs kausta
cd ../../apps/backend-nodejs

# Kopeeri Dockerfile
cp ../../01-docker-lab/solutions/backend-nodejs/Dockerfile .
cp ../../01-docker-lab/solutions/backend-nodejs/.dockerignore .

# Ehita (build) Docker pilt (image)
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

# Ehita (build) (mitme-sammuline (multi-stage) ehitus (build))
docker build -f Dockerfile.optimized -t user-service:1.0-optimized .

# Võrdle suurusi
docker images | grep user-service
# user-service:1.0            ~305MB
# user-service:1.0-optimized  ~305MB (sama suurus, kuid kiirem uuesti ehitamine (rebuild) ja seisukorra kontroll (health check))
```

### Todo Teenus (Service) (Java)

#### Lihtne Dockerfile (Harjutus 1)

```bash
# Mine apps/backend-java-spring kausta
cd ../../apps/backend-java-spring

# Kopeeri Dockerfile
cp ../../01-docker-lab/solutions/backend-java-spring/Dockerfile .
cp ../../01-docker-lab/solutions/backend-java-spring/.dockerignore .

# Ehita (build) JAR
./gradlew clean bootJar

# Ehita (build) Docker pilt (image)
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

# Ehita (build) (mitme-sammuline (multi-stage) ehitus (build) teeb ka JAR'i)
docker build -f Dockerfile.optimized -t todo-service:1.0-optimized .

# Võrdle suurusi
docker images | grep todo-service
# todo-service:1.0            ~230MB
# todo-service:1.0-optimized  ~180MB (-22%)
```

---

## 📊 Piltide (Images) Suuruste Võrdlus

### User Teenus (Service) (Node.js)

| Versioon | Suurus | Kirjeldus |
|----------|--------|-----------|
| **Lihtne** | ~305MB | node:18-slim + npm install |
| **Optimeeritud** | ~305MB | Mitme-sammuline (multi-stage) + mitte-juurkasutaja (non-root) + seisukorra kontroll (health check) (sama suurus, kuid kiirem uuesti ehitamine (rebuild)) |

**Parandused optimeeritud versioonis:**
- Mitme-sammuline (multi-stage) ehitus (build) (sõltuvused (dependencies) on vahemälus (cached) eraldi - kiirem uuesti ehitamine (rebuild)!)
- Mitte-juurkasutaja (non-root user) (nodejs:1001)
- Seisukorra kontroll (health check) (healthcheck.js)
- `npm ci --only=production` (väiksemad sõltuvused (dependencies))
- ⚠️ Suurus jääb samaks: bcrypt natiivmoodulid nõuavad node:18-slim baaspilti (base image)

### Todo Teenus (Service) (Java)

| Versioon | Suurus | Kirjeldus |
|----------|--------|-----------|
| **Lihtne** | ~230MB | eclipse-temurin:17-jre-alpine + JAR |
| **Optimeeritud** | ~180MB | Mitme-sammuline (multi-stage) (Gradle ehitus (build) → JRE runtime) + mitte-juurkasutaja (non-root) |

**Parandused optimeeritud versioonis:**
- Mitme-sammuline (multi-stage) ehitus (build) (Gradle JDK → JRE runtime)
- Mitte-juurkasutaja (non-root user) (spring:1001)
- Seisukorra kontroll (health check) (wget-based)
- Kihtide vahemälu (layer caching) (sõltuvused (dependencies) on vahemälus (cached) eraldi)
- Gradle --no-daemon (vähem mälu kasutust)

---

## 💡 Märkused

- ⚠️ Need on **näidis-lahendused** - proovi esmalt ise!
- 💪 Õppimine toimub läbi proovimise ja vigade parandamise
- 📚 Kasuta neid ainult kui jääd hätta
- ✅ Mõlemad teenused (services) on tootmisvalmis (production-ready):
  - Alpine baaspildid (base images) (väiksem suurus)
  - Mitte-juurkasutajad (non-root users) (turvalisus)
  - Seisukorra kontrollid (health checks) (monitooring)
  - Kihtide vahemälu (layer caching) (kiirem uuesti ehitamine (rebuild))

---

**Edu harjutustega! 🐳**
