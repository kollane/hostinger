# Harjutus 1: Docker Compose Alused

**Kestus:** 60 minutit
**Eesmärk:** Konverteeri Lab 1 lõpuseisu (4 konteinerit) docker-compose.yml failiks

---

## 📋 Ülevaade

Selles harjutuses võtad **Labor 1 lõpuseisu** (4 töötavat konteinerit manuaalsete `docker run` käskudega) ja konverteerid need üheks docker-compose.yml failiks. Õpid Docker Compose põhimõisteid: services, networks, volumes,  ja depends_on.

**Enne vs Peale:**
- **Enne (Lab 1):** 4 käsku `docker run` iga konteineri jaoks
- **Peale (Lab 2):** Üks käsk `docker compose up` kogu süsteemi jaoks

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Konverteerida `docker run` käske docker-compose.yml failiks
- ✅ Defineerida teenuseid (services)
- ✅ Kasutada olemasolevaid pilte (images)
- ✅ Konfigureerida võrke (networks) ja andmehoidlaid (volumes)
- ✅ Hallata teenuste sõltuvusi (`depends_on`)
- ✅ Kasutada `docker compose` põhikäske
- ✅ Testida End-to-End JWT workflow

---

## 🏗️ Mis Konverteerime?

### Lab 1 Lõpuseisu (Stardipunkt)

Lab 1 lõpus käivitasid sa **4 konteinerit** manuaalselt:

```bash
# 1. PostgreSQL kasutajate jaoks
docker run -d --name postgres-user \
  --network todo-network \
  -v postgres-user-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=user_service_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:16-alpine

# 2. PostgreSQL todo'de jaoks
docker run -d --name postgres-todo \
  --network todo-network \
  -v postgres-todo-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=todo_service_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5433:5432 \
  postgres:16-alpine

# 3. User Service
docker run -d --name user-service \
  --network todo-network \
  -e DB_HOST=postgres-user \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=shared-secret-key \
  -e NODE_ENV=production \
  -e PORT=3000 \
  -p 3000:3000 \
  user-service:1.0-optimized

# 4. Todo Service
docker run -d --name todo-service \
  --network todo-network \
  -e DB_HOST=postgres-todo \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=shared-secret-key \
  -e SPRING_PROFILES_ACTIVE=prod \
  -p 8081:8081 \
  todo-service:1.0-optimized
```

**Probleemid:**
- ❌ Pikad käsud
- ❌ Raske meeles pidada
- ❌ Kui midagi muutub, pead käsitsi muutma
- ❌ Raske jagada teiste meeskonnaliikmetega

### Lab 2 Sihtoluk (Eesmärk)

Üks lühike käsk:

```bash
docker compose up -d
```

**Eelised:**
- ✅ Kogu konfiguratsioon ühes failis
- ✅ Versioonihaldus (Git)
- ✅ Lihtne jagada (commit & push)
- ✅ Kergelt muudetav

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Labor 1 ressursid on olemas:**

```bash
# 1. Kontrolli pilte (images)
docker images | grep -E "user-service.*optimized|todo-service.*optimized"
# Oodatud: user-service:1.0-optimized ja todo-service:1.0-optimized

# 2. Kontrolli andmehoidlaid (volumes)
docker volume ls | grep -E "postgres-user-data|postgres-todo-data"
# Oodatud: postgres-user-data ja postgres-todo-data

# 3. Kontrolli võrku (network)
docker network ls | grep todo-network
# Oodatud: todo-network
```

**Kui midagi puudub:**
- 🔗 Mine tagasi Lab 1 juurde: `cd ../01-docker-lab`
- 🔗 Vaata [Lab 1 README](../../01-docker-lab/README.md)

**✅ Kui kõik ülalpool on OK, võid jätkatakatama!**

---

## 📝 Sammud

### Samm 1: Peata Lab 1 Konteinerid (5 min)

Enne docker-compose.yml loomist, peata kõik Lab 1 käsitsi loodud konteinerid:

```bash
# Vaata töötavaid konteinereid
docker ps

# Peata kõik Lab 1 konteinerid
docker stop user-service todo-service postgres-user postgres-todo todo-service-opt user-service-opt

# Eemalda konteinerid (andmehoidlad (volumes) ja võrk (network) jäävad alles!)
docker rm user-service todo-service postgres-user postgres-todo todo-service-opt user-service-opt

# Kontrolli, et konteinerid on eemaldatud
docker ps -a | grep -E "user-service|todo-service|postgres"
# Peaks olema tühi
```

**TÄHTIS:** Me EI kustuta:
- ❌ Pilte (images) - kasutame neid uuesti
- ❌ Andmehoidlaid (volumes) - andmed peavad püsima
- ❌ Võrku (network) - kasutame seda uuesti

---

### Samm 2: Loo Töökaust (5 min)

Loo eraldi kataloog Docker Compose projektile:

```bash
# SSH VPS-i (kui pole juba ühendatud)
ssh janek@kirjakast

# Mine Lab 2 juurde
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab

# Loo töökaust
mkdir -p compose-project
cd compose-project
```

---

### Samm 3: Kirjuta docker-compose.yml (30 min)

Loo `docker-compose.yml` fail:

```bash
vim docker-compose.yml
```

Vajuta `i` (insert mode) ja lisa järgmine sisu:

```yaml
# ==========================================================================
# Docker Compose - Lab 1 Lõpuseisu Konversioon
# ==========================================================================
# Käivitab 4 teenust:
# - 2x PostgreSQL (users ja todos)
# - User Service (Node.js)
# - Todo Service (Java Spring Boot)
# ==========================================================================

# MÄRKUS: Docker Compose v2 (2025)
# version: '3.8' on VALIKULINE (optional) Compose v2's!
# Compose v2 ei nõua enam version väljaanni, kuid see on siin backwards compatibility jaoks.
# Võid selle ära jätta - Compose v2 kasutab automaatselt uusimat versiooni.
version: '3.8'

services:
  # ==========================================================================
  # PostgreSQL - User Service Database
  # ==========================================================================
  postgres-user:
    image: postgres:16-alpine
    container_name: postgres-user
    restart: unless-stopped
    environment:
      POSTGRES_DB: user_service_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres-user-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - todo-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ==========================================================================
  # PostgreSQL - Todo Service Database
  # ==========================================================================
  postgres-todo:
    image: postgres:16-alpine
    container_name: postgres-todo
    restart: unless-stopped
    environment:
      POSTGRES_DB: todo_service_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres-todo-data:/var/lib/postgresql/data
    ports:
      - "5433:5432"
    networks:
      - todo-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ==========================================================================
  # User Service - Node.js + Express + PostgreSQL
  # ==========================================================================
  user-service:
    image: user-service:1.0-optimized
    container_name: user-service
    restart: unless-stopped
    environment:
      DB_HOST: postgres-user
      DB_PORT: 5432
      DB_NAME: user_service_db
      DB_USER: postgres
      DB_PASSWORD: postgres
      JWT_SECRET: shared-secret-key-change-this-in-production-must-be-at-least-256-bits
      JWT_EXPIRES_IN: 1h
      PORT: 3000
      NODE_ENV: production
    ports:
      - "3000:3000"
    networks:
      - todo-network
    depends_on:
      postgres-user:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s

  # ==========================================================================
  # Todo Service - Java Spring Boot + PostgreSQL
  # ==========================================================================
  todo-service:
    image: todo-service:1.0-optimized
    container_name: todo-service
    restart: unless-stopped
    environment:
      DB_HOST: postgres-todo
      DB_PORT: 5432
      DB_NAME: todo_service_db
      DB_USER: postgres
      DB_PASSWORD: postgres
      JWT_SECRET: shared-secret-key-change-this-in-production-must-be-at-least-256-bits
      SPRING_PROFILES_ACTIVE: prod
      JAVA_OPTS: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
    ports:
      - "8081:8081"
    networks:
      - todo-network
    depends_on:
      postgres-todo:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8081/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 60s

# ==========================================================================
# Volumes - Kasutame Lab 1'st loodud andmehoidlaid
# ==========================================================================
volumes:
  postgres-user-data:
    external: true  # Kasutame Lab 1'st loodud volume'i
  postgres-todo-data:
    external: true  # Kasutame Lab 1'st loodud volume'i

# ==========================================================================
# Networks - Kasutame Lab 1'st loodud võrku
# ==========================================================================
networks:
  todo-network:
    external: true  # Kasutame Lab 1'st loodud network'i
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 4: Mõista Struktuuri (10 min)

**Võta aega ja analüüsi faili:**

#### `version: '3.8'`

Docker Compose faili versiooni number. Versioon 3.8 toetab kõiki uuemaid funktsioone.

#### `services:` Blokk

Defineerib 4 teenust (service):
- `postgres-user` - PostgreSQL kasutajate andmebaasile
- `postgres-todo` - PostgreSQL todo'de andmebaasile
- `user-service` - Node.js backend
- `todo-service` - Java Spring Boot backend

**Iga teenus (service) sisaldab:**
- `image:` - Mis pilti (image) kasutada
- `container_name:` - Konteineri nimi
- `environment:` - Keskkonna muutujad (environment variables)
- `ports:` - Portide vastendamine (port mapping)
- `networks:` - Mis võrgus (network) käivitada
- `volumes:` - Andmehoidlad (volumes)
- `depends_on:` - Sõltuvused teistest teenustest
- `healthcheck:` - Seisukorra kontroll (health check)
- `restart:` - Restart poliitika

#### `healthcheck:` - Oluline!

**User Service healthcheck:**
```yaml
healthcheck:
  test: ["CMD", "node", "healthcheck.js"]
  interval: 30s
  timeout: 3s
  retries: 3
  start_period: 40s
```

**Miks `node healthcheck.js`, mitte `wget` või `curl`?**
- Node.js 22-slim pilt (image) **EI sisalda** `wget` ega `curl` tööriistu
- `healthcheck.js` fail on juba konteineris olemas (Lab 1'st)
- Node on garanteeritult olemas (kuna see on Node.js konteiner)
- Docker Compose healthcheck **override'ib** Dockerfile HEALTHCHECK'i

**Todo Service healthcheck:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8081/health"]
```

**Miks todo-service võib kasutada `wget`?**
- Java runtime pilt (eclipse-temurin) sisaldab `wget` tööriista
- Kui `wget` puuduks, kasutaks `curl` või Java HTTP klienti

**Healthcheck parameetrid:**
- `interval: 30s` - Kontrolli iga 30 sekundi tagant
- `timeout: 3s` - Ühendus timeout (katse ebaõnnestub peale 3s)
- `retries: 3` - Mitme ebaõnnestumise järel märgitakse unhealthy
- `start_period: 40s` - Grace period startup'il (ei loe failures)

#### Miks mitte installida wget konteinerisse?

**Küsimus:** Kas võiks lihtsalt installida wget Node.js konteinerisse?

**Vastus:** Jah, tehniliselt võimalik, aga **EI OLE best practice**:

❌ **Vale lähenemine (AVOID):**
```dockerfile
FROM node:22-slim
RUN apt-get update && apt-get install -y wget  # Lisab 5-10MB
HEALTHCHECK CMD wget --spider http://localhost:3000/health
```

**Miks see on halb?**
- Suurem image (+5-10MB wget + dependencies)
- Aeglasem build (apt-get update/install)
- Rohkem security vulnerabilities (lisapakettide CVE'd)
- Multi-stage build keerulisem (wget mõlemas stage'is)

✅ **Õige lähenemine (BEST PRACTICE):**
```dockerfile
FROM node:22-slim
# Kasuta tööriistu mis juba on
HEALTHCHECK CMD node healthcheck.js
```

**Miks see on parem?**
- Minimal image size (slim jääb slim'iks)
- Vähem dependencies = vähem vulnerabilities
- Kiirem build ja deploy
- Production-ready approach

**DevOps põhimõte:**
> "Don't install tools just for healthchecks. Use what's already in the container."

**Millal siiski installida wget?**
- Kui rakendusel endal on vaja wget'i (debugging, scripting)
- Kui healthcheck PEAB olema wget (legacy süsteemid)
- Development image'ites (mitte production!)

#### `volumes:` Blokk

```yaml
volumes:
  postgres-user-data:
    external: true
  postgres-todo-data:
    external: true
```

**`external: true` tähendab:**
- Docker Compose EI loo uut andmehoidlat (volume)
- Kasutab Lab 1'st juba loodud andmehoidlat (volume)
- Kui andmehoidla (volume) ei eksisteeri, saad vea (error)

#### `networks:` Blokk

```yaml
networks:
  todo-network:
    external: true
```

**`external: true` tähendab:**
- Docker Compose EI loo uut võrku (network)
- Kasutab Lab 1'st juba loodud võrku (network)
- Kui võrk (network) ei eksisteeri, saad vea (error)

#### `depends_on` + `condition`

```yaml
depends_on:
  postgres-user:
    condition: service_healthy
```

**Tähendus:**
- User Service käivitub alles siis, kui postgres-user on `healthy`
- Docker Compose kontrollib `healthcheck` staatust
- Kui healthcheck ebaõnnestub, ei käivitu user-service

---

### Samm 5: Valideeri YAML Syntax (2 min)

Kontrolli, et YAML on korrektne:

```bash
# Kontrolli syntax'it
docker compose config

# Kui OK, näed parsed output'i
# Kui viga (error), näed error message'i
```

**Levinud vead (errors):**
- Valed taandused (indentation) - YAML on tundlik!
- Puuduvad koolonid (`:`)
- Vale kasutamine `true` vs `"true"`

---

### Samm 6: Käivita Stack (5 min)

```bash
# Käivita kõik teenused (services)
docker compose up -d

# Väljund:
# [+] Running 4/4
#  ✔ Container postgres-user   Healthy
#  ✔ Container postgres-todo    Healthy
#  ✔ Container user-service     Started
#  ✔ Container todo-service     Started
```

**Märkused:**
- `-d` = detached mode (taustal)
- Docker Compose käivitab teenused (services) õiges järjekorras (depends_on)

**Kontrolli staatust:**

```bash
docker compose ps

# Väljund:
# NAME            IMAGE                        STATUS          PORTS
# postgres-user   postgres:16-alpine           Up (healthy)    0.0.0.0:5432->5432/tcp
# postgres-todo   postgres:16-alpine           Up (healthy)    0.0.0.0:5433->5432/tcp
# user-service    user-service:1.0-optimized   Up (healthy)    0.0.0.0:3000->3000/tcp
# todo-service    todo-service:1.0-optimized   Up (healthy)    0.0.0.0:8081->8081/tcp
```

---

### Samm 7: Vaata Loge (3 min)

```bash
# Kõigi teenuste (services) logid
docker compose logs

# Konkreetse teenuse (service) logid
docker compose logs user-service

# Follow mode (real-time)
docker compose logs -f user-service

# Viimased 50 rida
docker compose logs --tail=50 user-service

# Mõlema backend'i logid korraga
docker compose logs -f user-service todo-service
```

**Oota, kuni näed:**
```
user-service   | Server running on port 3000
user-service   | Database connected successfully
todo-service   | Started TodoApplication in 5.123 seconds
```

---

### Samm 8: Testi Rakendust (End-to-End) (10 min)

#### Test 1: Health Checks

```bash
# User Service
curl http://localhost:3000/health

# Oodatud vastus:
# {"status":"ok","database":"connected"}

# Todo Service
curl http://localhost:8081/health

# Oodatud vastus:
# {"status":"UP"}
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
#   "message": "User created successfully",
#   "user": {
#     "id": 1,
#     "name": "Test User",
#     "email": "test@example.com",
#     "role": "user"
#   }
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
#   "user": { ... }
# }
```

#### Test 4: Loo Todo (kasutades JWT token'it)

```bash
# Kopeeri token eelmisest vastusest
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Loo todo
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Õpi Docker Compose",
    "description": "Läbi töötada Lab 2",
    "priority": "high"
  }'

# Oodatud vastus:
# {
#   "id": 1,
#   "title": "Õpi Docker Compose",
#   "description": "Läbi töötada Lab 2",
#   "priority": "high",
#   "completed": false,
#   ...
# }
```

#### Test 5: Loe Todo'd

```bash
curl http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN"

# Oodatud vastus:
# {
#   "content": [
#     {
#       "id": 1,
#       "title": "Õpi Docker Compose",
#       ...
#     }
#   ],
#   "totalElements": 1
# }
```

**🎉 Kui kõik ülalpool töötab, on End-to-End workflow edukiselt!**

---

### Samm 9: Kontrolli Andmete Püsivust (5 min)

**Küsimus:** Kas andmed püsivad peale restart'i?

```bash
# Peata stack
docker compose down

# Väljund:
# [+] Running 4/4
#  ✔ Container user-service   Removed
#  ✔ Container todo-service   Removed
#  ✔ Container postgres-user  Removed
#  ✔ Container postgres-todo  Removed
```

**MÄRKUS:** Andmehoidlad (volumes) ja võrk (network) EI kustutatud (external: true)!

```bash
# Kontrolli andmehoidlate (volumes) olemasolu
docker volume ls | grep postgres
# Peaks nägema: postgres-user-data ja postgres-todo-data

# Käivita uuesti
docker compose up -d

# Testi - kas kasutaja ja todo on ikka olemas?
TOKEN="<sama token mis enne>"
curl http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN"

# Peaks nägema sama todo't kui enne!
```

---

### Samm 10: Debug ja Troubleshoot (5 min)

#### Sisene Konteinerisse

```bash
# PostgreSQL konteiner
docker compose exec postgres-user sh

# Shell sees:
psql -U postgres -d user_service_db

# SQL console:
\dt              # Näita tabelid
SELECT * FROM users;
\q               # Välju psql-ist
exit             # Välju container-ist

# Backend konteiner
docker compose exec user-service sh

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

# Kontrolli syntax'it (ei trüki midagi kui OK)
docker compose config --quiet
```

#### Restart Konkreetset Teenust

```bash
# Restart user-service
docker compose restart user-service

# Rebuild ja restart (kui muutsid pilti (image))
docker compose up -d --build user-service
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **docker-compose.yml** fail 4 teenusega (service)
- [ ] **Töötav stack** (vaata `docker compose ps`)
- [ ] **Healthy status** kõigi teenuste (services) jaoks
- [ ] **Andmed püsivad** peale restart'i (Lab 1 andmehoidlad (volumes))
- [ ] Oskad käivitada: `docker compose up -d`
- [ ] Oskad peatada: `docker compose down`
- [ ] Oskad vaadata loge: `docker compose logs`
- [ ] Mõistad teenuste sõltuvusi (service dependencies) (depends_on)
- [ ] End-to-End JWT workflow toimib

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas stack töötab?
docker compose ps
# Kõik peaksid olema UP ja HEALTHY

# 2. Kas andmehoidlad (volumes) on ühendatud?
docker volume ls | grep postgres
# Peaks leidma: postgres-user-data ja postgres-todo-data

# 3. Kas võrk (network) on ühendatud?
docker network ls | grep todo-network
# Peaks leidma: todo-network

# 4. Kas API'd töötavad?
curl http://localhost:3000/health
curl http://localhost:8081/health
# Mõlemad peaksid tagastama {"status":"ok"}
```

---

## 🎓 Õpitud Mõisted

### Docker Compose mõisted:

- **version:** Compose faili versiooni number
- **services:** Konteinerite definitsioonid
- **image:** Valmis pilt (image) mida kasutada
- **environment:** Keskkonna muutujad (environment variables)
- **ports:** Portide vastendamine (port mapping)
- **networks:** Võrgud (networks) teenuste vahel
- **volumes:** Andmehoidlad (volumes) andmete püsivuseks
- **depends_on:** Teenuste sõltuvused
- **healthcheck:** Seisukorra kontroll (health check)
- **restart:** Restart poliitika
- **external:** Kasuta olemasolevat ressurssi

### Docker Compose käsud:

- `docker compose up -d` - Käivita stack taustal
- `docker compose down` - Peata ja eemalda konteinerid
- `docker compose ps` - Vaata teenuste (services) staatust
- `docker compose logs` - Vaata logisid
- `docker compose exec` - Käivita käsk konteineris
- `docker compose config` - Valideeri ja vaata konfiguratsioon
- `docker compose restart` - Taaskäivita teenused (services)

### Service Discovery:

Backend saab ühenduda PostgreSQL-ga kasutades **teenuse nime (service name)**:
```yaml
DB_HOST: postgres-user  # Mitte IP aadress!
```

Docker Compose loob automaatselt DNS-i, kus teenuse nimi (service name) (`postgres-user`) resolvib õigesse IP-sse.

---

## 💡 Parimad Tavad

1. **Kasuta external volumes'eid ja networks'e** - Kui ressursid on juba loodud
2. **Määra health checks** - Tead, millal teenus (service) on valmis
3. **Kasuta depends_on + condition** - Õige käivitusjärjekord
4. **Määra restart: unless-stopped** - Auto-restart peale crashe
5. **Kommenteeri faili** - Teised (ja tulevane sina) tänab sind
6. **Versioonihalda** - Commit docker-compose.yml Git'i

---

## 🐛 Levinud Probleemid

### Probleem 1: "network todo-network declared as external, but could not be found"

```bash
# Loo võrk (network)
docker network create todo-network

# VÕI muuda docker-compose.yml:
networks:
  todo-network:
    # Eemalda "external: true" rida
    driver: bridge
```

### Probleem 2: "volume postgres-user-data declared as external, but could not be found"

```bash
# Loo andmehoidla (volume)
docker volume create postgres-user-data
docker volume create postgres-todo-data

# VÕI muuda docker-compose.yml:
volumes:
  postgres-user-data:
    # Eemalda "external: true" rida
    driver: local
```

### Probleem 3: "Backend can't connect to database"

```bash
# Kontrolli, kas DB on healthy
docker compose ps

# Vaata DB loge
docker compose logs postgres-user

# Kontrolli DB_HOST keskkonna muutujat (environment variable)
docker compose exec user-service env | grep DB_HOST
# Peaks olema: DB_HOST=postgres-user (teenuse nimi (service name))
```

### Probleem 4: "Port already in use"

```bash
# Vaata, mis kasutab porti
sudo lsof -i :3000

# Lahendus 1: Peata konfliktis olev konteiner
docker ps
docker stop <container-id>

# Lahendus 2: Muuda porti docker-compose.yml's
ports:
  - "3001:3000"  # Host port 3001, konteiner port 3000
```

### Probleem 5: "user-service on unhealthy staatuses"

**Sümptomid:**
```bash
docker compose ps
# user-service    Up (unhealthy)    # ← Probleem!
```

**Põhjus:** Healthcheck kasutab `wget` käsku, aga Node.js 22-slim pildis ei ole `wget` installitud.

**Diagnoos:**
```bash
# Kontrolli healthcheck viga
docker inspect user-service --format='{{json .State.Health}}' | jq

# Peaks nägema:
# "Output": "exec: \"wget\": executable file not found in $PATH"
```

**Lahendus:**

Docker Compose healthcheck peab kasutama `node healthcheck.js` asemel `wget`:

```yaml
# VALE (ei tööta Node.js slim pildis):
user-service:
  healthcheck:
    test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]

# ÕIGE (töötab alati):
user-service:
  healthcheck:
    test: ["CMD", "node", "healthcheck.js"]
    interval: 30s
    timeout: 3s
    retries: 3
    start_period: 40s
```

**Miks see juhtub?**
- Node.js 22-slim pilt on minimalistlik (ei sisalda wget/curl)
- `healthcheck.js` fail on juba konteineris (Lab 1'st)
- Docker Compose healthcheck override'ib Dockerfile HEALTHCHECK'i

**Rakenda parandus:**
```bash
# 1. Paranda docker-compose.yml (muuda wget → node healthcheck.js)
vim docker-compose.yml

# 2. Taaskäivita user-service
docker compose up -d --force-recreate user-service

# 3. Oota ~40 sekundit (start_period) ja kontrolli
docker compose ps
# user-service    Up (healthy)    # ← Parandatud!
```

**Alternatiiv: Kas võiks installida wget?**

Tehniliselt jah, aga see on **anti-pattern** production image'itele:

```dockerfile
# ❌ EI SOOVITATA (AVOID)
FROM node:22-slim
RUN apt-get update && apt-get install -y wget
# Probleem: +5-10MB, rohkem CVE'd, aeglasem build
```

**Production image'id peavad olema minimalistlikud:**
- Väiksem attack surface (vähem koodi = vähem bugs)
- Vähem security vulnerabilities (iga pakett võib tuua CVE'd)
- Kiiremad deployments (väiksem image = kiirem download)
- Odavam storage/bandwidth

**DevOps best practice:** Kasuta seda, mis juba on - `node`, `npm`, `healthcheck.js`

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd käivitad 4 teenust (services) ühe docker-compose.yml failiga.

**Mis edasi?**
- ✅ Konverteris Lab 1 → docker-compose.yml
- ✅ 4 teenust (services) töötavad
- ✅ Andmed püsivad
- ⏭️ **Järgmine:** Lisa Frontend (5. teenus (service))

**Jätka:** [Harjutus 2: Lisa Frontend Teenus](02-add-frontend.md)

---

## 📚 Viited

- [Docker Compose dokumentatsioon](https://docs.docker.com/compose/)
- [Compose file reference](https://docs.docker.com/compose/compose-file/)
- [depends_on reference](https://docs.docker.com/compose/compose-file/05-services/#depends_on)
- [Healthcheck reference](https://docs.docker.com/compose/compose-file/05-services/#healthcheck)

---

**Õnnitleme! Oled edukalt konverteerinud Lab 1 docker-compose.yml failiks! 🎉**
