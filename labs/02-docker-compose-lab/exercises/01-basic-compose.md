# Harjutus 1: Lihtne Docker Compose Stack

**Kestus:** 60 minutit
**Eesmärk:** Käivita User Service + PostgreSQL ühe docker-compose.yml failiga

---

## 📋 Ülevaade

Selles harjutuses lood oma esimese `docker-compose.yml` faili, mis käivitab kaks teenust: PostgreSQL andmebaasi ja Node.js backend'i. Õpid Docker Compose põhimõisteid: services, networks, volumes, ja environment variables.

**Labor 1 vs Labor 2:**
- **Labor 1:** Käivitasid iga konteineri eraldi käsuga (`docker run`)
- **Labor 2:** Käivitad kogu stack'i ühe käsuga (`docker compose up`)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Kirjutada `docker-compose.yml` faili
- ✅ Defineerida teenuseid (services)
- ✅ Kasutada named volumes andmete püsivuseks
- ✅ Konfigureerida networks't ja service discovery'd
- ✅ Hallata environment variables'eid
- ✅ Kasutada `docker compose` käske (up, down, logs, ps)
- ✅ Debuggida multi-container rakendusi

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────────────────────────┐
│   Docker Compose Stack                          │
│                                                  │
│   ┌────────────────────┐   ┌────────────────┐  │
│   │  Backend Service   │   │  PostgreSQL    │  │
│   │  (Node.js)         │──▶│  Database      │  │
│   │  Port: 3000        │   │  Port: 5432    │  │
│   └────────────────────┘   └────────────────┘  │
│            │                        │           │
│            │                   postgres-data   │
│            │                     (volume)       │
└────────────┼────────────────────────────────────┘
             │
      localhost:3000
```

---

## 📝 Sammud

### Samm 1: Loo Töökausta (5 min)

Loo eraldi kataloog Docker Compose projektile:

```bash
# SSH VPS-i
ssh janek@kirjakast

# Loo töökaust
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab
mkdir -p my-compose-project
cd my-compose-project
```

---

### Samm 2: Kirjuta docker-compose.yml (20 min)

Loo `docker-compose.yml` fail:

```bash
vim docker-compose.yml
```

Vajuta `i` (insert mode) ja lisa:

```yaml
version: '3.8'

services:
  # PostgreSQL andmebaas
  postgres:
    image: postgres:16-alpine
    container_name: my-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: user_service_db
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: securepass123
      POSTGRES_INITDB_ARGS: "-E UTF8 --locale=C"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Node.js Backend
  backend:
    build:
      context: ../../apps/backend-nodejs
      dockerfile: Dockerfile
    container_name: my-backend
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      NODE_ENV: production
      PORT: 3000
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: user_service_db
      DB_USER: appuser
      DB_PASSWORD: securepass123
      JWT_SECRET: my-super-secret-jwt-key-123
      JWT_EXPIRES_IN: 7d
    ports:
      - "3000:3000"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  postgres-data:
    driver: local

networks:
  app-network:
    driver: bridge
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 3: Mõista Struktuuri (10 min)

**Võta aega ja analüüsi:**

#### Services blokk

```yaml
services:
  postgres:
    # PostgreSQL service konfiguratsioon
  backend:
    # Backend service konfiguratsioon
```

**Küsimused:**
- Mitu teenust (service) on defineeritud? (**2 teenust:** postgres ja backend)
- Milliseid image'id kasutatakse? (**postgres:16-alpine** ja **build from Dockerfile**)

#### Volumes blokk

```yaml
volumes:
  postgres-data:
    driver: local
```

**Miks?** Andmebaasi andmed peavad püsima ka peale `docker compose down`

#### Networks blokk

```yaml
networks:
  app-network:
    driver: bridge
```

**Service Discovery:** Backend saab ühenduda PostgreSQL-ga hostname'i `postgres` abil (service nimi)

#### depends_on

```yaml
depends_on:
  postgres:
    condition: service_healthy
```

**Tähendus:** Backend käivitub alles siis, kui PostgreSQL on healthy

---

### Samm 4: Käivita Stack (10 min)

```bash
# Build ja start kõik teenused
docker compose up -d

# Väljund:
# [+] Running 4/4
#  ✔ Network my-compose-project_app-network       Created
#  ✔ Volume "my-compose-project_postgres-data"    Created
#  ✔ Container my-postgres                        Healthy
#  ✔ Container my-backend                         Started
```

**Märkused:**
- `-d` = detached mode (taustal)
- Docker Compose loob automaatselt prefixi (kausta nimi)
- Volume ja network saavad prefiksi: `my-compose-project_`

**Kontrolli staatust:**

```bash
docker compose ps

# Väljund:
# NAME          IMAGE                      STATUS          PORTS
# my-postgres   postgres:16-alpine         Up (healthy)    5432/tcp
# my-backend    my-compose-project-backend Up (healthy)    0.0.0.0:3000->3000/tcp
```

---

### Samm 5: Vaata Loge (5 min)

```bash
# Kõigi teenuste logid
docker compose logs

# Konkreetse teenuse logid
docker compose logs backend

# Follow mode (real-time)
docker compose logs -f backend

# Viimased 50 rida
docker compose logs --tail=50 backend

# Mõlema teenuse logid korraga
docker compose logs -f postgres backend
```

**Oota, kuni näed:**
```
my-backend   | Server running on port 3000
my-backend   | Database connected successfully
```

---

### Samm 6: Testi Rakendust (10 min)

#### Test 1: Health Check

```bash
curl http://localhost:3000/health

# Oodatud vastus:
# {
#   "status": "ok",
#   "database": "connected",
#   "timestamp": "2025-11-15T..."
# }
```

#### Test 2: Registreeri Kasutaja

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "test123"
  }'

# Oodatud vastus:
# {
#   "message": "User registered successfully",
#   "userId": 1
# }
```

#### Test 3: Login ja Saa JWT Token

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123"
  }'

# Oodatud vastus:
# {
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": {
#     "id": 1,
#     "name": "Test User",
#     "email": "test@example.com"
#   }
# }
```

#### Test 4: Kasuta Token'it (kopeeri eelmine token)

```bash
TOKEN="<kopeeri token siia>"

curl http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN"

# Oodatud vastus:
# {
#   "users": [
#     {
#       "id": 1,
#       "name": "Test User",
#       "email": "test@example.com",
#       "role": "user"
#     }
#   ],
#   "pagination": {...}
# }
```

---

### Samm 7: Kontrolli Andmete Püsivust (5 min)

**Küsimus:** Kas andmed püsivad peale restart'i?

```bash
# Peata stack
docker compose down

# Väljund:
# [+] Running 3/3
#  ✔ Container my-backend   Removed
#  ✔ Container my-postgres  Removed
#  ✔ Network my-compose-project_app-network  Removed
```

**MÄRKUS:** Volume'it EI kustutatud!

```bash
# Kontrolli volume'i olemasolu
docker volume ls | grep postgres-data

# Käivita uuesti
docker compose up -d

# Testi - kas kasutaja on ikka olemas?
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Peaks töötama! Andmed on salvestatud volume'i!
```

---

### Samm 8: Debug ja Troubleshoot (5 min)

#### Sisene Konteinerisse

```bash
# PostgreSQL konteiner
docker compose exec postgres sh

# Shell sees:
psql -U appuser -d user_service_db

# SQL console:
\dt              # Näita tabelid
SELECT * FROM users;
\q               # Välju psql-ist
exit             # Välju container-ist

# Backend konteiner
docker compose exec backend sh

# Shell sees:
ls -la
cat package.json
env | grep DB
exit
```

#### Vaata Konfiguratsioon

```bash
# Vaata parsed docker-compose.yml
docker compose config

# Kontrolli süntaksit
docker compose config --quiet

# Kui viga, siis näitab error'it
```

#### Kontrolli Network't

```bash
# Näita networks
docker network ls

# Inspekteeri network'i
docker network inspect my-compose-project_app-network

# Peaks näitama mõlemat containerit
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **docker-compose.yml** fail 2 teenusega
- [ ] **Töötav stack** (vaata `docker compose ps`)
- [ ] **Healthy status** mõlema teenuse jaoks
- [ ] **Andmed püsivad** peale restart'i
- [ ] Oskad käivitada: `docker compose up -d`
- [ ] Oskad peatada: `docker compose down`
- [ ] Oskad vaadata loge: `docker compose logs`
- [ ] Mõistad service discovery'd (backend → postgres)

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas stack töötab?
docker compose ps
# Mõlemad peaksid olema UP ja HEALTHY

# 2. Kas volume on loodud?
docker volume ls | grep postgres-data
# Peaks leidma: my-compose-project_postgres-data

# 3. Kas network on loodud?
docker network ls | grep app-network
# Peaks leidma: my-compose-project_app-network

# 4. Kas API töötab?
curl http://localhost:3000/health
# Peaks tagastama: {"status":"ok"}
```

---

## 🎓 Õpitud Mõisted

### Docker Compose mõisted:

- **version:** Compose file versiooni number
- **services:** Konteinerite definitsioonid
- **volumes:** Named volumes andmete püsivuseks
- **networks:** Custom network'd teenuste vahel
- **depends_on:** Teenuste sõltuvused
- **healthcheck:** Tervisekontrool
- **restart:** Restart poliitika

### Docker Compose käsud:

- `docker compose up -d` - Käivita stack taustal
- `docker compose down` - Peata ja eemalda stack
- `docker compose ps` - Vaata teenuste staatust
- `docker compose logs` - Vaata logisid
- `docker compose exec` - Käivita käsk konteineris
- `docker compose config` - Valideeri ja vaata konfiguratsioon

### Service Discovery:

Backend saab ühenduda PostgreSQL-ga kasutades **service nime**:
```javascript
DB_HOST: postgres  // Mitte IP aadress!
```

Docker Compose loob automaatselt DNS-i, kus teenuse nimi (`postgres`) resolvib õigesse IP-sse.

---

## 💡 Parimad Tavad

1. **Kasuta named volumes** - Andmed püsivad
2. **Määra health checks** - Tead, millal teenus on valmis
3. **Kasuta depends_on + condition** - Õige käivitusjärjekord
4. **Väldi container_name** - Laseb Compose'il hallata nimesid
5. **Kasuta restart: unless-stopped** - Auto-restart peale crashe
6. **Ära hard-code saladusi** - Kasuta .env faili (järgmine harjutus!)

---

## 🐛 Levinud Probleemid

### Probleem 1: "Port already in use"

```bash
# Vaata, mis kasutab porti 3000
sudo lsof -i :3000

# Lahendus: muuda port
ports:
  - "3001:3000"
```

### Probleem 2: "Backend can't connect to database"

```bash
# Kontrolli DB_HOST
docker compose config | grep DB_HOST
# Peaks olema: DB_HOST: postgres (service nimi)

# Kontrolli, kas postgres on healthy
docker compose ps
```

### Probleem 3: "Image build failed"

```bash
# Rebuild ilma cache'ita
docker compose build --no-cache backend

# VÕI kontrolli Dockerfile path'i
build:
  context: ../../apps/backend-nodejs  # Õige path?
```

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd käivitad PostgreSQL + Backend edukalt.

Järgmises harjutuses lisame **Frontend** teenuse ja lood täieliku 3-tier stack'i!

**Jätka:** [Harjutus 2: Full-Stack Compose](02-full-stack.md)

---

## 📚 Viited

- [Docker Compose dokumentatsioon](https://docs.docker.com/compose/)
- [Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Networking in Compose](https://docs.docker.com/compose/networking/)
- [Volumes in Compose](https://docs.docker.com/storage/volumes/)

---

**Õnnitleme! Oled loonud oma esimese Docker Compose stack'i! 🎉**
