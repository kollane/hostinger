# Harjutus 8: Legacy Integration - Docker + Olemasolev Infrastruktuur

**Eesmärk:** Õppida integreerima Dockeriseeritud rakendusi olemasoleva (legacy) infrastruktuuriga, mis on tavaline stsenaarium suurettevõtetes

**Kestus:** 60-75 minutit

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Ühendada Docker konteinereid **välistele andmebaasidele** (legacy PostgreSQL, AWS RDS, Azure Database)
- ✅ Konfigureerida Docker rakendusi töötama **olemasoleva reverse proxy** taga
- ✅ Kasutada `host.docker.internal` host masina teenustega suhtlemiseks
- ✅ Eksponeerida porte legacy süsteemidele turvaliselt
- ✅ Simuleerida **3-tier enterprise arhitektuuri** ilma kõike Dockerisse viimata
- ✅ Mõista **hübriid-infrastruktuuri** (hybrid infrastructure) mustreid
- ✅ Debuggida **cross-boundary** network probleeme (Docker ↔ Host)

---

## 🏢 Stsenaarium: Järkjärguline Docker Migratsioon

### Tüüpiline Ettevõtte Olukord:

Sinu ettevõttel on **olemasolev infrastruktuur:**

```
┌─────────────────────────────────────────────────────────────┐
│ PRAEGUNE INFRASTRUKTUUR (Legacy / Bare-Metal)               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │ PostgreSQL DB    │      │ Nginx Load       │            │
│  │ Cluster          │      │ Balancer         │            │
│  │ (VM / Bare Metal)│      │ (Eraldi server)  │            │
│  │ Port: 5432, 5433 │      │ Port: 80, 443    │            │
│  └──────────────────┘      └──────────────────┘            │
│         ▲                           │                       │
│         │                           ▼                       │
│  ┌──────────────────────────────────────────┐              │
│  │ VANAD Rakendused (Monolith)              │              │
│  │ - PHP / Java WAR / Legacy Stack          │              │
│  └──────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

### Sinu ülesanne:

**Migratsioon Plaan:**
1. ❌ **EI SAA** kohe kõike Dockerisse viia (risk, ressursid, aeg)
2. ✅ **Alusta väikestest:** Dockerise ainult **uued mikroteenused**
3. ✅ **Kasuta olemasolevat:** Legacy andmebaas ja load balancer jäävad paika
4. ✅ **Integreeri:** Docker rakendused peavad töötama legacy infrastruktuuriga

### Siht-arhitektuur (Hübriid):

```
┌────────────────────────────────────────────────────────────────────┐
│ HÜBRIID-INFRASTRUKTUUR (Legacy + Docker)                           │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│ Tier 1: Database Layer (LEGACY - ei puutu, töötab juba)           │
│ ┌────────────────────────────────────────────────────────────┐    │
│ │ PostgreSQL Server (Bare-Metal VM / AWS RDS / Azure DB)     │    │
│ │ - postgres-user  : 5432   ← eksponeeritud võrgule          │    │
│ │ - postgres-todo  : 5433   ← eksponeeritud võrgule          │    │
│ └────────────────────────────────────────────────────────────┘    │
│                           ▲                                        │
│                           │ TCP/IP Connection                      │
│                           │ DATABASE_URL=<legacy-host>:5432        │
│                           │                                        │
│ Tier 2: Application Layer (UUED DOCKERISED MIKROTEENUSED)         │
│ ┌────────────────────────────────────────────────────────────┐    │
│ │ Docker Compose Stack (compose-project/)                    │    │
│ │ ┌──────────────────┐      ┌──────────────────┐             │    │
│ │ │ user-service     │      │ todo-service     │             │    │
│ │ │ (Node.js)        │      │ (Java Spring)    │             │    │
│ │ │ Port: 3000       │      │ Port: 8081       │             │    │
│ │ │ (eksponeeritud)  │      │ (eksponeeritud)  │             │    │
│ │ └──────────────────┘      └──────────────────┘             │    │
│ └────────────────────────────────────────────────────────────┘    │
│                           ▲                                        │
│                           │ HTTP API Calls                         │
│                           │ upstream http://<docker-host>:3000     │
│                           │                                        │
│ Tier 3: Load Balancer (LEGACY - olemasolev Nginx)                 │
│ ┌────────────────────────────────────────────────────────────┐    │
│ │ Nginx Reverse Proxy (Bare-Metal / Eraldi VM)               │    │
│ │ - Avalik Internet: 80, 443                                 │    │
│ │ - Upstream: http://<docker-host>:3000 (user-service)       │    │
│ │ - Upstream: http://<docker-host>:8081 (todo-service)       │    │
│ └────────────────────────────────────────────────────────────┘    │
│                           ▲                                        │
│                           │                                        │
│                      Internet Traffic                              │
└────────────────────────────────────────────────────────────────────┘
```

### Miks see oluline?

**Realistlikud stsenaariumid:**
- 🏢 **Enterprise:** Legacy andmebaas klaster (Oracle, PostgreSQL, SQL Server) on eraldi DBA tiimi hallatav
- ☁️ **Cloud Hybrid:** AWS RDS / Azure Database + Dockerised apps EC2's
- 🔐 **Compliance:** Andmebaas peab olema eraldi network zone's (security policy)
- 💰 **Kulude optimeerimine:** Legacy hardware amortiseerunud, aga töötab veel
- ⏱️ **Järkjärguline migratsioon:** Ei saa big-bang migration'it teha (risk)

---

## 📋 Harjutuse Ülevaade

### Simulatsiooni Lähenemine:

Kuna me ei saa harjutuses kasutada 3 erinevat füüsilist serverit, **simuleerime legacy infrastruktuuri**:

**Kuidas simuleerida legacy süsteeme ühes masinas?**

1. **Tier 1 (Legacy DB):**
   - Käivitame PostgreSQL Dockeris, aga **eraldi Compose projektis**
   - Eksponeerime portid `5432:5432` ja `5433:5432` hostile
   - **Simuleerib:** Eraldi DB serverit, millele on ligipääs IP aadressiga

2. **Tier 2 (Docker Apps):**
   - Käivitame mikroteenused **teises Compose projektis**
   - Kasutame `host.docker.internal` host masina portidele (5432, 5433) ligipääsuks
   - **Simuleerib:** Docker rakendusi, mis ühenduvad välistele teenustele

3. **Tier 3 (Legacy Nginx):**
   - Käivitame Nginx **kolmandas Compose projektis**
   - Kasutame `host.docker.internal` Docker rakenduste portidele (3000, 8081) ligipääsuks
   - **Simuleerib:** Eraldi load balancer serverit

**Tulemus:**
- ✅ 3 sõltumatut Docker Compose stack'i
- ✅ Omavahel suhtlevad **host masina võrgu kaudu** (mitte Docker võrgu kaudu)
- ✅ Realistlik simulatsioon multi-server arhitektuurist

---

## 📂 Failide Struktuur

Harjutuse jooksul loome järgmise struktuuri:

```
02-docker-compose-lab/
└── exercises/
    └── 08-legacy-integration/
        ├── README.md                    # Juhised
        ├── tier1-legacy-db/             # Simuleerib legacy andmebaasi
        │   └── docker-compose.yml
        ├── tier2-docker-apps/           # Uued Dockerised mikroteenused
        │   ├── docker-compose.yml
        │   └── .env
        └── tier3-legacy-nginx/          # Simuleerib legacy load balancer
            ├── docker-compose.yml
            └── nginx.conf
```

---

## 📝 Sammud

### Samm 1: Ettevalmistus (5 min)

#### 1.1 Loo harjutuse kataloog

```bash
cd ~/labs/02-docker-compose-lab/exercises
mkdir -p 08-legacy-integration
cd 08-legacy-integration

# Loo tier kataloogid
mkdir -p tier1-legacy-db tier2-docker-apps tier3-legacy-nginx
```

#### 1.2 Kontrolli eeldusi

**Veendu, et Lab 1 image'd on olemas:**

```bash
docker images | grep -E "user-service|todo-service"

# Pead nägema:
# user-service    1.0-optimized   ...
# todo-service    1.0-optimized   ...
```

**Kui image'd puuduvad:**

```bash
# Käivita Lab 2 setup skript (ehitab automaatselt)
cd ~/labs/02-docker-compose-lab
./setup.sh
```

---

### Samm 2: Tier 1 - Legacy Andmebaas (15 min)

#### 2.1 Mõista Tier 1 rolli

**Simulatsioon:**
- Käivitame PostgreSQL Dockeris, aga **eraldi projekt**
- Eksponeerime portid hostile (`5432:5432`, `5433:5432`)
- **EI OLE** ühes võrgus Tier 2 rakenduste ga

**Reaalses maailmas:**
- PostgreSQL töötaks bare-metal VM'il või AWS RDS'is
- Ligipääs oleks IP aadressi kaudu (nt `db.company.internal:5432`)

#### 2.2 Loo Tier 1 Compose fail

```bash
cd tier1-legacy-db
vim docker-compose.yml
```

**Fail: `tier1-legacy-db/docker-compose.yml`**

```yaml
# Tier 1: Legacy Database Layer
# Simuleerib: Eraldi PostgreSQL serverit (bare-metal VM / AWS RDS / Azure DB)
# Reaalses maailmas: See ei oleks Dockeris, vaid eraldi infrastruktuuris

services:
  # ==========================================================================
  # Legacy PostgreSQL - Users Database
  # ==========================================================================
  legacy-postgres-user:
    image: postgres:16-alpine
    container_name: legacy-postgres-user
    restart: unless-stopped
    environment:
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD: dbpass123
      POSTGRES_DB: user_service_db
    ports:
      # OLULINE: Eksponeerime hostile (simuleerib legacy DB serverit)
      - "5432:5432"
    volumes:
      - legacy-postgres-user-data:/var/lib/postgresql/data
    networks:
      - legacy-db-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dbuser -d user_service_db"]
      interval: 10s
      timeout: 3s
      retries: 3

  # ==========================================================================
  # Legacy PostgreSQL - Todos Database
  # ==========================================================================
  legacy-postgres-todo:
    image: postgres:16-alpine
    container_name: legacy-postgres-todo
    restart: unless-stopped
    environment:
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD: dbpass123
      POSTGRES_DB: todo_service_db
    ports:
      # OLULINE: Eksponeerime erinevale hostile pordile (5433 → 5432)
      - "5433:5432"
    volumes:
      - legacy-postgres-todo-data:/var/lib/postgresql/data
    networks:
      - legacy-db-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dbuser -d todo_service_db"]
      interval: 10s
      timeout: 3s
      retries: 3

volumes:
  legacy-postgres-user-data:
    name: legacy-postgres-user-data
  legacy-postgres-todo-data:
    name: legacy-postgres-todo-data

networks:
  legacy-db-network:
    name: legacy-db-network
    driver: bridge
```

**Salvesta** (`:wq`)

#### 2.3 Käivita Legacy Andmebaas

```bash
# Käivita Tier 1
docker compose up -d

# Kontrolli
docker compose ps

# Pead nägema:
# NAME                   STATUS    PORTS
# legacy-postgres-user   Up        0.0.0.0:5432->5432/tcp
# legacy-postgres-todo   Up        0.0.0.0:5433->5432/tcp
```

#### 2.4 Testi ühenduvust hostist

```bash
# Testi User DB (port 5432)
docker exec -it legacy-postgres-user psql -U dbuser -d user_service_db -c "\dt"

# Testi Todo DB (port 5433)
docker exec -it legacy-postgres-todo psql -U dbuser -d todo_service_db -c "\dt"

# Mõlemad peaksid näitama tühja skeemi (veel tabeleid pole)
```

**✅ Tier 1 on valmis! Simuleerib legacy andmebaasi serverit.**

---

### Samm 3: Tier 2 - Docker Mikroteenused (20 min)

#### 3.1 Mõista Tier 2 rolli

**Eesmärk:**
- Dockerised mikroteenused (user-service, todo-service)
- **Ühenduvad Tier 1 andmebaasidega** (host masina portide kaudu)
- Eksponeerivad API'd hostile (3000, 8081)

**Võtmeküsimus:** Kuidas Docker konteiner ühendub host masina pordiga?

**Vastus:** `host.docker.internal` (Docker Desktop) või host IP aadress (Linux)

#### 3.2 Loo Tier 2 Compose fail

```bash
cd ../tier2-docker-apps
vim docker-compose.yml
```

**Fail: `tier2-docker-apps/docker-compose.yml`**

```yaml
# Tier 2: Dockerised Application Layer
# Uued mikroteenused, mis ühenduvad legacy infrastruktuuriga

services:
  # ==========================================================================
  # User Service (Node.js)
  # ==========================================================================
  user-service:
    image: user-service:1.0-optimized
    container_name: docker-user-service
    restart: unless-stopped
    environment:
      # OLULINE: Kasutame host.docker.internal legacy DB'ga ühendumiseks
      # Docker Desktop (Mac/Windows): host.docker.internal töötab automaatselt
      # Linux: Vajab extra_hosts konfiguratsiooni (vt allpool)
      DATABASE_URL: postgresql://dbuser:dbpass123@host.docker.internal:5432/user_service_db
      JWT_SECRET: ${JWT_SECRET:-super-secret-jwt-key-change-in-production}
      NODE_ENV: production
      PORT: 3000
    ports:
      # Eksponeerime hostile (legacy Nginx saab ligi)
      - "3000:3000"
    # Linux: Lisa host.docker.internal support
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s

  # ==========================================================================
  # Todo Service (Java Spring Boot)
  # ==========================================================================
  todo-service:
    image: todo-service:1.0-optimized
    container_name: docker-todo-service
    restart: unless-stopped
    environment:
      # OLULINE: Kasutame host.docker.internal:5433 legacy DB'ga ühendumiseks
      DATABASE_URL: postgresql://dbuser:dbpass123@host.docker.internal:5433/todo_service_db
      JWT_SECRET: ${JWT_SECRET:-super-secret-jwt-key-change-in-production}
      SPRING_PROFILES_ACTIVE: prod
      SERVER_PORT: 8081
    ports:
      # Eksponeerime hostile (legacy Nginx saab ligi)
      - "8081:8081"
    # Linux: Lisa host.docker.internal support
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8081/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 60s
    depends_on:
      - user-service

# MÄRKUS: ME EI DEFINEERI networks: sektsiooni!
# Need konteinerid kasutavad vaikimisi bridge võrku, aga ühenduvad
# legacy süsteemidega host võrgu kaudu
```

**Salvesta** (`:wq`)

#### 3.3 Loo .env fail (valikuline)

```bash
vim .env
```

**Fail: `tier2-docker-apps/.env`**

```bash
# JWT Secret (peaks olema turvaliselt hallatud)
JWT_SECRET=my-super-secret-jwt-key-for-legacy-integration
```

**Salvesta** (`:wq`)

#### 3.4 Initsialiseeri andmebaasi skeemid

**Enne mikroteenuste käivitamist, loo tabelid:**

```bash
# User Service tabel (legacy-postgres-user @ port 5432)
docker exec -it legacy-postgres-user psql -U dbuser -d user_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Todo Service tabel (legacy-postgres-todo @ port 5433)
docker exec -it legacy-postgres-todo psql -U dbuser -d todo_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Kontrolli
docker exec -it legacy-postgres-user psql -U dbuser -d user_service_db -c "\dt"
docker exec -it legacy-postgres-todo psql -U dbuser -d todo_service_db -c "\dt"
```

#### 3.5 Käivita Tier 2 mikroteenused

```bash
# Käivita Tier 2
docker compose up -d

# Vaata logisid (kontrolli andmebaasi ühendust)
docker compose logs -f

# Peaks nägema:
# docker-user-service | Database connected successfully
# docker-todo-service | Database connected successfully
```

#### 3.6 Testi API'd

```bash
# Health check'id
curl http://localhost:3000/health
# {"status":"healthy","database":"connected"}

curl http://localhost:8081/health
# {"status":"healthy","database":"connected"}

# Registreeri kasutaja
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Legacy Test User",
    "email": "legacy@test.com",
    "password": "test123"
  }'

# Login (saad JWT token)
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"legacy@test.com","password":"test123"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Token: $TOKEN"

# Loo todo
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test legacy integration",
    "description": "Docker apps connected to legacy DB"
  }'

# Kontrolli andmebaasis
docker exec -it legacy-postgres-user psql -U dbuser -d user_service_db -c "SELECT id, name, email FROM users;"
docker exec -it legacy-postgres-todo psql -U dbuser -d todo_service_db -c "SELECT id, title, completed FROM todos;"
```

**✅ Tier 2 on valmis! Dockerised rakendused ühenduvad legacy andmebaasiga.**

---

### Samm 4: Tier2 Multi-Environment Setup (20 min)

#### 4.1. Probleemi Kirjeldus

**Olukord:**

Tier2 (Docker apps) peab töötama **erinevates keskkondades:**

- **TEST:** Debug logging, pordid avatud localhost'ile, leebemad resource limits
- **PRODUCTION:** Warn logging, pordid ainult Docker võrgus, ranged resource limits

**Lahendus: BASE + OVERRIDE Pattern**

```
tier2-docker-apps/
├── docker-compose.yml              # BASE (Tier1 ühenduvus, image'id)
├── docker-compose.test.yml         # TEST overrides (debug, ports)
├── docker-compose.prod.yml         # PRODUCTION overrides (limits, logging)
├── .env.test.example               # TEST template
└── .env.prod.example               # PRODUCTION template
```

**Võrdlus:**

| Aspekt | TEST | PRODUCTION |
|--------|------|------------|
| **Logging** | DEBUG level | WARN level |
| **Ports** | `127.0.0.1:3000:3000` (avatud) | Ainult Docker võrgus |
| **Resource Limits** | Leebemad (dev masinas) | Ranged (512MB, 1CPU) |
| **Paroolid** | `test123` (lihtne) | Tugevad (48+ bytes) |
| **Restart Policy** | `unless-stopped` | `always` |

---

#### 4.2. Loo Tier2 Override Failid

**Kataloog:** `tier2-docker-apps/`

##### docker-compose.test.yml

```bash
cd tier2-docker-apps/
vim docker-compose.test.yml
```

**Fail: `tier2-docker-apps/docker-compose.test.yml`**

```yaml
# TEST Environment Overrides - Tier 2 (Docker Apps)
# Kasutamine: docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d

services:
  user-service:
    environment:
      LOG_LEVEL: debug           # TEST: Debug logging
      NODE_ENV: development      # TEST: Development mode
    ports:
      - "127.0.0.1:3000:3000"    # TEST: Avatud localhost'ile (legacy Nginx ligi)

  todo-service:
    environment:
      SPRING_PROFILES_ACTIVE: test      # TEST: Spring test profile
      LOGGING_LEVEL_ROOT: DEBUG         # TEST: Debug logging
    ports:
      - "127.0.0.1:8081:8081"            # TEST: Avatud localhost'ile
```

**Salvesta** (`:wq`)

##### docker-compose.prod.yml

```bash
vim docker-compose.prod.yml
```

**Fail: `tier2-docker-apps/docker-compose.prod.yml`**

```yaml
# PRODUCTION Environment Overrides - Tier 2 (Docker Apps)
# Kasutamine: docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

services:
  user-service:
    environment:
      LOG_LEVEL: warn            # PRODUCTION: Warn logging ainult
      NODE_ENV: production
    restart: always              # PRODUCTION: Alati restart
    deploy:
      resources:
        limits:
          cpus: '1.0'           # PRODUCTION: CPU limit
          memory: 512M          # PRODUCTION: Memory limit
        reservations:
          cpus: '0.5'
          memory: 256M
    # MÄRKUS: Ported EI ole siin - jäävad BASE config'ist (3000:3000)
    # Legacy Nginx kasutab host.docker.internal:3000

  todo-service:
    environment:
      SPRING_PROFILES_ACTIVE: prod      # PRODUCTION: Spring prod profile
      LOGGING_LEVEL_ROOT: WARN          # PRODUCTION: Warn logging ainult
    restart: always                      # PRODUCTION: Alati restart
    deploy:
      resources:
        limits:
          cpus: '2.0'                   # PRODUCTION: CPU limit (Java vajab rohkem)
          memory: 1G                    # PRODUCTION: Memory limit
        reservations:
          cpus: '1.0'
          memory: 512M
    # MÄRKUS: Ported EI ole siin - jäävad BASE config'ist (8081:8081)
```

**Salvesta** (`:wq`)

---

#### 4.3. Loo .env Failid Tier2 Jaoks

##### .env.test (tier2)

```bash
vim .env.test.example
```

**Fail: `tier2-docker-apps/.env.test.example`**

```bash
# Tier2 TEST Environment
# Loo oma .env.test fail: cp .env.test.example .env.test

# Legacy DB Connection (Tier1)
DB_HOST=host.docker.internal  # Viitab Tier1 legacy baasidele
DB_USER_PORT=5432             # legacy-postgres-user
DB_TODO_PORT=5433             # legacy-postgres-todo
POSTGRES_PASSWORD=test123     # TEST: Lihtne parool

# JWT Secret
JWT_SECRET=test-secret-jwt-key-for-testing

# Logging
LOG_LEVEL=debug
```

**Salvesta** (`:wq`)

```bash
# Loo oma .env.test fail
cp .env.test.example .env.test
```

##### .env.prod (tier2)

```bash
vim .env.prod.example
```

**Fail: `tier2-docker-apps/.env.prod.example`**

```bash
# Tier2 PRODUCTION Environment
# Loo oma .env.prod fail: cp .env.prod.example .env.prod

# Legacy DB Connection (Tier1)
DB_HOST=host.docker.internal  # Viitab Tier1 legacy baasidele
DB_USER_PORT=5432             # legacy-postgres-user
DB_TODO_PORT=5433             # legacy-postgres-todo
POSTGRES_PASSWORD=<GENERATE-STRONG-PASSWORD>  # GENEREERI: openssl rand -base64 48

# JWT Secret
JWT_SECRET=<GENERATE-STRONG-JWT-SECRET>       # GENEREERI: openssl rand -base64 32

# Logging
LOG_LEVEL=warn
```

**Salvesta** (`:wq`)

```bash
# Loo oma .env.prod fail ja genereeri paroolid
cp .env.prod.example .env.prod
vim .env.prod

# Genereeri paroolid:
openssl rand -base64 48  # POSTGRES_PASSWORD
openssl rand -base64 32  # JWT_SECRET
```

**Lisa .gitignore:**

```bash
cd tier2-docker-apps/
echo ".env.test" >> .gitignore
echo ".env.prod" >> .gitignore
git add .env.test.example .env.prod.example docker-compose.test.yml docker-compose.prod.yml
```

---

#### 4.4. Käivitamine Erinevates Keskkondades

##### TEST Keskkond (kõik 3 tier'i)

```bash
# Tier1: Legacy DB (base config, test paroolidega)
cd ~/labs/02-docker-compose-lab/solutions/08-legacy-integration/tier1-legacy-db/
docker-compose up -d

# Tier2: Docker Apps (TEST config)
cd ../tier2-docker-apps/
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d

# Kontrolli log level'i
docker logs docker-user-service | grep -i debug   # Peaks näitama DEBUG log'e
docker logs docker-todo-service | grep -i debug   # Peaks näitama DEBUG log'e

# Tier3: Legacy Nginx (base config)
cd ../tier3-legacy-nginx/
docker-compose up -d
```

##### PRODUCTION Keskkond

```bash
# Tier1: Legacy DB (base config, production paroolidega)
cd ~/labs/02-docker-compose-lab/solutions/08-legacy-integration/tier1-legacy-db/
docker-compose --env-file .env.prod up -d

# Tier2: Docker Apps (PROD config)
cd ../tier2-docker-apps/
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# Kontrolli log level'i ja resource limits
docker logs docker-user-service | grep -i warn    # Peaks näitama ainult WARN log'e
docker stats docker-user-service docker-todo-service  # Memory/CPU limits aktiivsed

# Tier3: Legacy Nginx (prod config või base)
cd ../tier3-legacy-nginx/
docker-compose --env-file .env.prod up -d
```

---

#### 4.5. ✅ Põhimõte: 3-Tier Multi-Environment

| Tier | Komponent | Multi-Environment Strategy |
|------|-----------|---------------------------|
| **Tier1** (DB) | Legacy PostgreSQL | Üks config (BASE), env-specific passwords |
| **Tier2** (Apps) | Docker mikroteenused | **BASE + OVERRIDE** (test.yml, prod.yml) |
| **Tier3** (LB) | Legacy Nginx | Üks config või env-specific nginx.conf |

**Võtmepunkt:**

- **Tier2** (Docker apps) kasutab **täielikku multi-env pattern'i** (BASE + OVERRIDE)
- Tier1 ja Tier3 on legacy (lihtsamad konfid)
- Kõik kolm tier'i saavad erinevaid `.env` faile (test vs prod paroolid)

**Viited:**
- 📖 [Harjutus 4: Multi-Environment Arhitektuur](04-environment-management.md#samm-3-multi-environment-arhitektuur) - Täielik pattern selgitus
- 📖 [ENVIRONMENTS.md](../compose-project/ENVIRONMENTS.md) - Environment guide
- 📖 [PASSWORDS.md](../compose-project/PASSWORDS.md) - Paroolide haldamine

**✅ Tier 2 Multi-Environment Setup valmis!**

---

### Samm 5: Tier 3 - Legacy Nginx Reverse Proxy (20 min)

#### 5.1 Mõista Tier 3 rolli

**Eesmärk:**
- Simuleerib legacy Nginx load balancer'it
- Proksimine Tier 2 mikroteenustele (host.docker.internal:3000, :8081)
- Avalik endpoint (port 8080)

#### 5.2 Loo Nginx konfiguratsioon

```bash
cd ../tier3-legacy-nginx
vim nginx.conf
```

**Fail: `tier3-legacy-nginx/nginx.conf`**

```nginx
# Legacy Nginx Reverse Proxy Configuration
# Simuleerib: Eraldi load balancer serverit (bare-metal / VM / AWS ALB)

events {
    worker_connections 1024;
}

http {
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;

    # Upstream: User Service (Docker konteiner @ host masinas)
    upstream user_service_backend {
        # OLULINE: host.docker.internal viitab host masina portidele
        # Reaalses maailmas: server 192.168.1.100:3000;
        server host.docker.internal:3000 max_fails=3 fail_timeout=30s;
    }

    # Upstream: Todo Service (Docker konteiner @ host masinas)
    upstream todo_service_backend {
        # OLULINE: host.docker.internal viitab host masina portidele
        # Reaalses maailmas: server 192.168.1.100:8081;
        server host.docker.internal:8081 max_fails=3 fail_timeout=30s;
    }

    # Virtual Server - Avalik endpoint
    server {
        listen 80;
        server_name localhost;

        # User Service API
        location /api/auth/ {
            proxy_pass http://user_service_backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # CORS headers (kui frontend on erinevast domeenist)
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;

            if ($request_method = 'OPTIONS') {
                return 204;
            }
        }

        location /api/users {
            proxy_pass http://user_service_backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Todo Service API
        location /api/todos {
            proxy_pass http://todo_service_backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # CORS headers
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;

            if ($request_method = 'OPTIONS') {
                return 204;
            }
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "Legacy Nginx LB: Healthy\n";
            add_header Content-Type text/plain;
        }

        # Status page (valikuline)
        location /nginx-status {
            stub_status on;
            access_log off;
        }
    }
}
```

**Salvesta** (`:wq`)

#### 5.3 Loo Tier 3 Compose fail

```bash
vim docker-compose.yml
```

**Fail: `tier3-legacy-nginx/docker-compose.yml`**

```yaml
# Tier 3: Legacy Nginx Load Balancer
# Simuleerib: Eraldi Nginx reverse proxy serverit (bare-metal / AWS ALB)

services:
  legacy-nginx:
    image: nginx:1.25-alpine
    container_name: legacy-nginx-lb
    restart: unless-stopped
    ports:
      # Avalik endpoint (Internet → Load Balancer)
      - "8080:80"
    volumes:
      # Mount custom nginx konfiguratsioon
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    # Linux: Lisa host.docker.internal support
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/health"]
      interval: 10s
      timeout: 3s
      retries: 3

# MÄRKUS: ME EI DEFINEERI networks: sektsiooni!
# Legacy LB on eraldi, ühendub Docker rakenduste ga host võrgu kaudu
```

**Salvesta** (`:wq`)

#### 5.4 Käivita Tier 3

```bash
# Käivita Tier 3
docker compose up -d

# Vaata logisid
docker compose logs -f

# Kontrolli
docker compose ps
```

#### 5.5 Testi Legacy Load Balancer'it

```bash
# Health check
curl http://localhost:8080/health
# Legacy Nginx LB: Healthy

# Nginx status
curl http://localhost:8080/nginx-status

# TÄIELIK END-TO-END TEST läbi Legacy LB:

# 1. Registreeri kasutaja (läbi Nginx)
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Legacy LB Test",
    "email": "lb@test.com",
    "password": "test123"
  }'

# 2. Login (läbi Nginx)
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"lb@test.com","password":"test123"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Token: $TOKEN"

# 3. Loo todo (läbi Nginx)
curl -X POST http://localhost:8080/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test via Legacy LB",
    "description": "Full stack: Legacy Nginx → Docker Apps → Legacy DB"
  }'

# 4. Too todo'd (läbi Nginx)
curl http://localhost:8080/api/todos \
  -H "Authorization: Bearer $TOKEN"
```

**✅ Tier 3 on valmis! Terve hübriid-arhitektuur töötab!**

---

### Samm 6: Ülevaade ja Analüüs (10 min)

#### 6.1 Visualiseeri arhitektuur

**Praegune olukord:**

```bash
# Vaata kõiki töötavaid teenuseid
docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

# Peaks nägema:
# NAME                   PORTS                    STATUS
# legacy-nginx-lb        0.0.0.0:8080->80/tcp     Up
# docker-todo-service    0.0.0.0:8081->8081/tcp   Up
# docker-user-service    0.0.0.0:3000->3000/tcp   Up
# legacy-postgres-todo   0.0.0.0:5433->5432/tcp   Up
# legacy-postgres-user   0.0.0.0:5432->5432/tcp   Up
```

**Andmevoog:**

```
Internet
   │
   ▼
┌──────────────────────────────────────┐
│ Tier 3: legacy-nginx-lb (port 8080) │ ← Simuleerib legacy LB
└──────────────────┬───────────────────┘
                   │ http://host.docker.internal:3000, :8081
                   ▼
┌──────────────────────────────────────────────────────────┐
│ Tier 2: docker-user-service (3000), docker-todo-service │ ← Dockerised apps
│         (8081)                                           │
└──────────────────┬───────────────────────────────────────┘
                   │ postgresql://host.docker.internal:5432, :5433
                   ▼
┌──────────────────────────────────────────────────────────┐
│ Tier 1: legacy-postgres-user (5432), legacy-postgres-   │ ← Simuleerib legacy DB
│         todo (5433)                                      │
└──────────────────────────────────────────────────────────┘
```

#### 6.2 Kontrolli logisid

```bash
# Tier 1: Andmebaasi ühendused
cd ~/labs/02-docker-compose-lab/exercises/08-legacy-integration/tier1-legacy-db
docker compose logs | grep "connection"

# Tier 2: API päringud
cd ../tier2-docker-apps
docker compose logs | grep -E "POST|GET"

# Tier 3: Nginx access log
cd ../tier3-legacy-nginx
docker compose logs legacy-nginx-lb | tail -20
```

#### 6.3 Analüüsi võrgu ühenduvust

```bash
# Vaata, milliseid porte host kuulab
netstat -tuln | grep -E "3000|5432|5433|8080|8081"

# Linux alternatiiv:
ss -tuln | grep -E "3000|5432|5433|8080|8081"

# Tulemus:
# tcp  0.0.0.0:5432   # legacy-postgres-user
# tcp  0.0.0.0:5433   # legacy-postgres-todo
# tcp  0.0.0.0:3000   # docker-user-service
# tcp  0.0.0.0:8081   # docker-todo-service
# tcp  0.0.0.0:8080   # legacy-nginx-lb
```

---

### Samm 7: Realismile Lähedane Stsenaarium (VALIKULINE - 10 min)

#### 7.1 Simuleeri AWS RDS ühendus

**Reaalses maailmas:** AWS RDS endpoint on midagi sellist:
```
mydb.c9akciq32.eu-west-1.rds.amazonaws.com:5432
```

**Kuidas simuleerida?**

Lisa `/etc/hosts` faili (või kasuta DNS'i):

```bash
# Lisame fake RDS endpointi
echo "127.0.0.1 rds-users.eu-west-1.rds.amazonaws.com" | sudo tee -a /etc/hosts
echo "127.0.0.1 rds-todos.eu-west-1.rds.amazonaws.com" | sudo tee -a /etc/hosts
```

**Uuenda Tier 2 konfiguratsioon:**

```bash
cd tier2-docker-apps
vim docker-compose.yml
```

Muuda `DATABASE_URL`:

```yaml
environment:
  # User Service
  DATABASE_URL: postgresql://dbuser:dbpass123@rds-users.eu-west-1.rds.amazonaws.com:5432/user_service_db

  # Todo Service
  DATABASE_URL: postgresql://dbuser:dbpass123@rds-todos.eu-west-1.rds.amazonaws.com:5433/todo_service_db
```

```bash
# Taaskäivita
docker compose up -d

# Testi
docker compose logs -f
```

**Tulemus:** Looks täpselt nagu AWS RDS! (aga tegelikult on localhost)

#### 7.2 Simuleeri load balancer failover

**Lisame 2. user-service instantsi (high availability):**

```bash
cd tier2-docker-apps
vim docker-compose.yml
```

Lisa teine teenus:

```yaml
  user-service-2:
    image: user-service:1.0-optimized
    container_name: docker-user-service-2
    restart: unless-stopped
    environment:
      DATABASE_URL: postgresql://dbuser:dbpass123@host.docker.internal:5432/user_service_db
      JWT_SECRET: ${JWT_SECRET:-super-secret-jwt-key-change-in-production}
      NODE_ENV: production
      PORT: 3000
    ports:
      - "3001:3000"  # Erinev host port!
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

**Uuenda Nginx upstream:**

```bash
cd ../tier3-legacy-nginx
vim nginx.conf
```

Muuda `upstream user_service_backend`:

```nginx
upstream user_service_backend {
    # Load balancing 2 instantsi vahel
    server host.docker.internal:3000 max_fails=3 fail_timeout=30s;
    server host.docker.internal:3001 max_fails=3 fail_timeout=30s;
}
```

```bash
# Taaskäivita kõik
cd ../tier2-docker-apps && docker compose up -d
cd ../tier3-legacy-nginx && docker compose restart

# Testi load balancing'ut
for i in {1..10}; do
  curl -s http://localhost:8080/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"lb@test.com","password":"test123"}' \
    | grep -o '"token"' && echo " Request $i"
done

# Vaata nginx logisid - näed round-robin load balancing'ut
docker compose logs -f legacy-nginx-lb
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Tier 1:** 2 PostgreSQL konteinerit (port 5432, 5433) → simuleerib legacy DB
- [ ] **Tier 2:** 2 mikroteenust (port 3000, 8081) → ühenduvad legacy DB'ga
- [ ] **Tier 3:** Nginx reverse proxy (port 8080) → proksimine Docker rakenduste le
- [ ] **End-to-end:** Saad teha API päringuid läbi Nginx → Docker Apps → Legacy DB
- [ ] **Realism:** Mõistad, kuidas Docker integreerib legacy infrastruktuuriga

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kõik 5 konteinerit töötavad?
docker ps --filter "name=legacy" --filter "name=docker" --format "{{.Names}}: {{.Status}}"

# 2. Portid on eksponeeritud?
netstat -tuln | grep -E "3000|5432|5433|8080|8081"

# 3. Health check'id?
curl http://localhost:3000/health
curl http://localhost:8081/health
curl http://localhost:8080/health

# 4. Andmebaasi ühenduvus?
docker exec -it legacy-postgres-user psql -U dbuser -d user_service_db -c "SELECT COUNT(*) FROM users;"
docker exec -it legacy-postgres-todo psql -U dbuser -d todo_service_db -c "SELECT COUNT(*) FROM todos;"

# 5. End-to-end test?
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"lb@test.com","password":"test123"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

curl http://localhost:8080/api/todos -H "Authorization: Bearer $TOKEN"
```

---

## 🐛 Levinud Probleemid

### Probleem 1: "Could not connect to database"

**Sümptom:**
```
docker-user-service | Error: connection to database failed
```

**Põhjus:** `host.docker.internal` ei tööta (Linux)

**Lahendus:**

```bash
# Kontrolli, kas extra_hosts on defineeritud
cd tier2-docker-apps
docker compose config | grep extra_hosts

# Peaks nägema:
# extra_hosts:
#   host.docker.internal: host-gateway

# Kui puudub, lisa docker-compose.yml'i
```

**Alternatiiv (Linux):**

```bash
# Kasuta host masina IP aadressi
ip addr show docker0 | grep "inet "
# inet 172.17.0.1/16

# Uuenda DATABASE_URL:
DATABASE_URL: postgresql://dbuser:dbpass123@172.17.0.1:5432/user_service_db
```

### Probleem 2: "502 Bad Gateway" Nginx'ist

**Sümptom:**
```
curl http://localhost:8080/api/todos
# <html>502 Bad Gateway</html>
```

**Põhjus:** Tier 2 teenused ei ole käivitunud või Nginx ei saa ühendust

**Lahendus:**

```bash
# 1. Kontrolli, kas Tier 2 töötab
cd tier2-docker-apps
docker compose ps

# 2. Kontrolli Nginx upstream'i
cd ../tier3-legacy-nginx
docker compose logs legacy-nginx-lb | grep "upstream"

# 3. Testi otse Tier 2 (mööda Nginx'i)
curl http://localhost:3000/health
curl http://localhost:8081/health

# 4. Kui need töötavad, probleem on Nginx konfis
vim nginx.conf
# Kontrolli: server host.docker.internal:3000;
```

### Probleem 3: "CORS error" brauseris

**Sümptom:** Frontend saab CORS vea

**Lahendus:** Kontrolli nginx.conf CORS header'eid:

```nginx
add_header 'Access-Control-Allow-Origin' '*' always;
add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;
```

### Probleem 4: "Table does not exist"

**Sümptom:**
```
docker-user-service | ERROR: relation "users" does not exist
```

**Põhjus:** Andmebaasi skeemid ei ole loodud

**Lahendus:**

```bash
# Lisa tabelid (Samm 3.4)
docker exec -it legacy-postgres-user psql -U dbuser -d user_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
```

---

## 🎓 Õpitud Mõisted

### 1. host.docker.internal

**Mis see on?**
- Spetsiaalne DNS nimi, mis viitab **host masina localhost'ile**
- Docker Desktop (Mac/Windows): Töötab automaatselt
- Linux: Vajab `extra_hosts` konfiguratsiooni

**Kasutamine:**

```yaml
environment:
  DATABASE_URL: postgresql://user:pass@host.docker.internal:5432/db
extra_hosts:
  - "host.docker.internal:host-gateway"
```

### 2. Legacy Integration Pattern

**Muster:** Dockerised rakendused + Legacy infrastruktuur

**Komponendid:**
- **Legacy DB:** Eksponeeritud port hostile (`5432:5432`)
- **Docker Apps:** Kasutavad `host.docker.internal` legacy teenuste ga ühendumiseks
- **Legacy LB:** Proksimine `host.docker.internal` Docker rakenduste le

### 3. Port Mapping Strateegiad

**Legacy Tier (eksponeerib porte):**
```yaml
ports:
  - "5432:5432"  # Eksponeerib hostile
```

**Docker Tier (kasutab hosti porte):**
```yaml
environment:
  DATABASE_URL: postgresql://...@host.docker.internal:5432/db
```

---

## 💡 Parimad Tavad

### 1. Järkjärguline Migratsioon

```
Samm 1: Dockerise ainult uued mikroteenused
  ↓
Samm 2: Kasuta olemasolevat DB ja LB
  ↓
Samm 3: Migrate andmebaas Kubernetes'e (kui valmis)
  ↓
Samm 4: Migrate LB → Ingress controller
```

### 2. Keskkonna Konfiguratsioon

**Development:**
```yaml
DATABASE_URL: postgresql://localhost:5432/db
```

**Staging:**
```yaml
DATABASE_URL: postgresql://staging-db.company.internal:5432/db
```

**Production:**
```yaml
DATABASE_URL: postgresql://rds-prod.eu-west-1.rds.amazonaws.com:5432/db
```

### 3. Turvalisus

**✅ DO:**
- Kasuta turvakanaleid (SSL/TLS)
- Halda salasõnu Secrets management'iga (Vault, AWS Secrets Manager)
- Piira võrgu ligipääsu (firewall, security groups)

**❌ DON'T:**
- Ära pane salasõnu koodi sisse
- Ära eksponeeri andmebaasi avalikku internetti
- Ära kasuta vaikimisi paroole

---

## 🔗 Järgmine Samm

**Õnnitleme! Oled õppinud legacy integration pattern'it!**

**Järgmised harjutused:**

- 🎯 **Harjutus 9:** Production Readiness (SSL/TLS, Health Checks, Monitoring, Failover)

---

## 📚 Viited

- [Docker host.docker.internal](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)
- [Docker extra_hosts](https://docs.docker.com/compose/compose-file/compose-file-v3/#extra_hosts)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Nginx upstream](http://nginx.org/en/docs/http/ngx_http_upstream_module.html)
- [AWS RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)

---

**Puhastamine (kui tahad alustada uuesti):**

```bash
# Peata ja eemalda kõik tier'id
cd ~/labs/02-docker-compose-lab/exercises/08-legacy-integration/tier1-legacy-db
docker compose down -v

cd ../tier2-docker-apps
docker compose down

cd ../tier3-legacy-nginx
docker compose down

# Eemalda volumes (kui tahad puhast algust)
docker volume rm legacy-postgres-user-data legacy-postgres-todo-data
```

---

**Viimane uuendus:** 2025-12-11
**Seotud harjutused:** Lab 2 Harjutus 3 (Network Segmentation), Lab 2 Harjutus 9 (Production Readiness)
**Eeldusteadmised:** Docker Compose, PostgreSQL, Nginx reverse proxy
