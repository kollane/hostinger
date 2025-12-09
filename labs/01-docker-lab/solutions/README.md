# Labor 1 Lahendused

See kaust sisaldab näidis-lahendusi Labor 1 harjutustele **mõlema teenuse (service)** jaoks.

---

## 📂 Struktuur

```
solutions/
├── README.md                        # See fail
├── backend-nodejs/                  # User Teenus (Service) (Node.js)
│   ├── Dockerfile                   # Lihtne 1-stage (VPS) (Harjutus 1 - HARVA)
│   ├── Dockerfile.simple            # 2-stage ARG proksiga (Harjutus 1 - PRIMAARNE)
│   ├── Dockerfile.vps-simple        # 1-stage VPS näidis
│   ├── Dockerfile.optimized         # Optimeeritud (Harjutus 5)
│   ├── Dockerfile.optimized.proxy   # Optimeeritud + proxy (Harjutus 5)
│   ├── .dockerignore
│   ├── healthcheck.js               # Seisukorra kontrolli (health check) skript
│   └── README-PROXY.md              # Põhjalik proxy juhend
└── backend-java-spring/             # Todo Teenus (Service) (Java)
    ├── Dockerfile                   # Lihtne 1-stage pre-built JAR (Harjutus 1 - HARVA)
    ├── Dockerfile.simple            # 2-stage Gradle containeris (Harjutus 1 - PRIMAARNE)
    ├── Dockerfile.vps-simple        # 1-stage VPS näidis
    ├── Dockerfile.optimized         # Optimeeritud (Harjutus 5)
    ├── Dockerfile.optimized.proxy   # Optimeeritud + proxy (Harjutus 5)
    ├── .dockerignore
    └── README-PROXY.md              # Põhjalik Gradle proxy juhend
```

---

## 🚀 Kasutamine

### User Teenus (Service) (Node.js)

#### Variant A: VPS Lihtne (HARVA KASUTATAV)

```bash
# Mine apps/backend-nodejs kausta
cd ~/labs/apps/backend-nodejs

# Kopeeri VPS versioon
cp ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.vps-simple Dockerfile
cp ../../01-docker-lab/solutions/backend-nodejs/.dockerignore .

# Ehita (build) Docker pilt (image) - AINULT AVALIKUS VÕRGUS!
docker build -t user-service:1.0 .

# Käivita
docker run -d --name user-service -p 3000:3000 \
  -e DB_HOST=postgres-user \
  -e JWT_SECRET=test-secret \
  user-service:1.0
```

#### Variant B: Corporate Keskkond (PRIMAARNE) ⭐

**Enamik õpilasi kasutab seda!**

```bash
# Mine apps/backend-nodejs kausta
cd ~/labs/apps/backend-nodejs

# Kopeeri 2-stage ARG proksiga versioon
cp ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.simple Dockerfile
cp ../../01-docker-lab/solutions/backend-nodejs/.dockerignore .

# Ehita PROKSIGA (corporate võrk)
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -t user-service:1.0 .

# VÕI ehita ILMA proksita (avalik võrk)
docker build -t user-service:1.0 .

# Kontrolli: Kas proxy leak'ib?
docker run --rm user-service:1.0 env | grep -i proxy
# Oodatud: TÜHI! ✅

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

#### Variant A: VPS Lihtne (HARVA KASUTATAV)

**Eeldab pre-built JAR'i host'is!**

```bash
# Mine apps/backend-java-spring kausta
cd ~/labs/apps/backend-java-spring

# Kopeeri VPS versioon
cp ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.vps-simple Dockerfile
cp ../../01-docker-lab/solutions/backend-java-spring/.dockerignore .

# Ehita JAR HOST'IS
./gradlew clean bootJar

# Ehita Docker pilt (image) - AINULT AVALIKUS VÕRGUS!
docker build -t todo-service:1.0 .

# Käivita
docker run -d --name todo-service -p 8081:8081 \
  -e DB_HOST=postgres-todo \
  -e JWT_SECRET=test-secret \
  todo-service:1.0
```

#### Variant B: Corporate Keskkond (PRIMAARNE) ⭐

**Enamik õpilasi kasutab seda! Gradle build containeris.**

```bash
# Mine apps/backend-java-spring kausta
cd ~/labs/apps/backend-java-spring

# Kopeeri 2-stage Gradle containeris versioon
cp ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.simple Dockerfile
cp ../../01-docker-lab/solutions/backend-java-spring/.dockerignore .

# Ehita PROKSIGA (corporate võrk) - Gradle build containeris!
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -t todo-service:1.0 .

# VÕI ehita ILMA proksita (avalik võrk)
docker build -t todo-service:1.0 .

# Kontrolli: Kas proxy leak'ib?
docker run --rm todo-service:1.0 env | grep -i proxy
# Oodatud: TÜHI! ✅

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
