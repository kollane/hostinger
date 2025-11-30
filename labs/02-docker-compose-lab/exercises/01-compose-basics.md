# Harjutus 1: Docker Compose alused

**Eesmärk:** Konverteeri Lab 1 lõpuseis (4 konteinerit) docker-compose.yml failiks

---

## 📋 Harjutuse ülevaade

Selles harjutuses võtad **Lab 1 lõpuseisu** (4 töötavat konteinerit manuaalsete `docker run` käskudega) ja konverteerid need üheks docker-compose.yml failiks. Õpid Docker Compose põhimõisteid: teenused, võrgud, andmeköited ja depends_on.

**Enne vs Peale:**

- **Enne (Lab 1):** 4 käsku `docker run` iga konteineri jaoks
- **Peale (Lab 2):** Üks käsk `docker compose up` kogu süsteemi jaoks

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Konverteerida `docker run` käske `docker-compose.yml` failiks
- ✅ Defineerida **teenuseid (services)**
- ✅ Kasutada olemasolevaid **tõmmiseid (docker images)**
- ✅ Konfigureerida **võrke (docker networks)** ja **andmeköiteid (docker volumes)**
- ✅ Hallata teenuste **sõltuvusi (dependencies)** (`depends_on`)
- ✅ Kasutada `docker compose` põhikäske
- ✅ Testida End-to-End JWT töövoogu

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

## ⚠️ TURVAHOIATUS: Avalikud Pordid!

**🚨 OLULINE:** Selles harjutuses on KÕIK 4 teenuse porti avalikud (0.0.0.0). **See on kriitiline turvarisk toote keskkonnas!**

| Port | Teenus | Oht |
|------|--------|-----|
| 3000 | "User Service" API | ⚠️ "backend" peaks olema kaitstud |
| 8081 | "Todo Service" API | ⚠️ "backend" peaks olema kaitstud |
| 5432 | PostgreSQL (users) | 🚨 **KRIITILINE TURVARISK!** |
| 5433 | PostgreSQL (todos) | 🚨 **KRIITILINE TURVARISK!** |

Käesolev labor on õppe-eesmärkidel loodud testimiskeskkond. Tootmiskeskkonnas on selline portide avalikustamine vastuvõetamatu. Hostmasina tulemüür (nt UFW) katab selle ohu hetkel, piirates väljastpoolt ligipääsu. Kuid Docker Compose konfiguratsioonis on pordid endiselt avalikud.

### 🛡️ Lahendus (Harjutus 3)

👉 **Harjutus 3 (Võrgu Segmenteerimine) õpetab, kuidas seda turvaliselt seadistada:**

- ✅ Võrgu segmenteerimine - 3-kihiline arhitektuur
- ✅ Portide 127.0.0.1 binding (localhost-only)
- ✅ Vähenda rünnaku pinda
- ✅ Ainult "frontend" port 8080 jääb avalikuks

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Labor 1 ressursid on olemas:**

```bash
# 1. Kontrolli tõmmiseid
docker images | grep -E "user-service.*optimized|todo-service.*optimized"
# Oodatud: user-service:1.0-optimized ja todo-service:1.0-optimized

# 2. Kontrolli andmeköiteid
docker volume ls | grep -E "postgres-user-data|postgres-todo-data"
# Oodatud: postgres-user-data ja postgres-todo-data

# 3. Kontrolli võrku
docker network ls | grep todo-network
# Oodatud: todo-network

# 4. VALIKULINE: Kontrolli andmebaasi skeeme (tabelid)
# See harjutus eeldab, et andmebaasid on tühjad või sisaldavad õigeid tabeleid
# Kui soovid testimisandmeid, kasuta setup.sh skripti (valik 2)
```

**Kui midagi puudub:**

**Variant A: Setup Skript (Kiire)**
```bash
cd ..  # Tagasi 02-docker-compose-lab/ kausta
./setup.sh
# Skript loob puuduvad ressursid ja võimaldab valida DB init'i
```

**Variant B: Käsitsi (Pedagoogiline)**

- 🔗 **Läbi Labor 1**

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📝 Sammud

### Samm 1: Peata Lab 1 Konteinerid (5 min)

Enne docker-compose.yml loomist, peata kõik Lab 1 käsitsi loodud konteinerid:

```bash
# Vaata töötavaid konteinereid
docker ps

# Peata kõik Lab 1 konteinerid
docker stop user-service todo-service postgres-user postgres-todo todo-service-opt user-service-opt

# Eemalda konteinerid (andmeköited ja võrk jäävad alles!)
docker rm user-service todo-service postgres-user postgres-todo todo-service-opt user-service-opt

# Kontrolli, et konteinerid on eemaldatud
docker ps -a | grep -E "user-service|todo-service|postgres"
# Peaks olema tühi
```

**TÄHTIS:** Me EI kustuta:

- ❌ Tõmmiseid - kasutame neid uuesti
- ❌ Andmeköiteid - andmed peavad püsima
- ❌ Võrku - kasutame seda uuesti

---

### Samm 2: Loo Töökaust (5 min)

Loo eraldi kataloog Docker Compose projektile:

```bash
# SSH VPS-i (kui pole juba ühendatud)
ssh labuser@93.127.213.242 -p [SINU-PORT]

# Mine Lab 2 juurde
cd ~/labs/02-docker-compose-lab

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
# - 2x PostgreSQL andmebaasi (eraldi andmeköidetega)
# - User Service (Node.js)
# - Todo Service (Java Spring Boot)
# ==========================================================================

# MÄRKUS: Docker Compose v2 (2025)
# version: '3.8' on VALIKULINE (optional) Compose v2's!
# Compose v2 ei nõua enam version väljaanni, kuid see on siin backwards compatibility jaoks.
# Võid selle ära jätta - Compose v2 kasutab automaatselt uusimat versiooni.
#version: '3.8'

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
      JWT_SECRET: VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
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
      JWT_SECRET: VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
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
# Volumes - Kasutame Lab 1'st loodud andmeköiteid
# ==========================================================================
volumes:
    external: true  # Kasutame Lab 1-s loodud andmeköidet
  postgres-todo-data:
    external: true  # Kasutame Lab 1'st loodud andmeköidet

# ==========================================================================
# Networks - Kasutame Lab 1'st loodud võrku
# ==========================================================================
networks:
  todo-network:
    external: true  # Kasutame Lab 1-s loodud võrku
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 4: Mõista struktuuri

**Võta aega ja analüüsi faili:**

#### `version: '3.8'`

Docker Compose faili versiooni number. Versioon 3.8 toetab kõiki uuemaid funktsioone.

#### `services:` Blokk

Defineerib 4 teenust:

- `postgres-user` - PostgreSQL kasutajate andmebaasile
- `postgres-todo` - PostgreSQL todo'de andmebaasile
- `user-service` - Node.js backend (User Service)
- `todo-service` - Java Spring Boot backend (Todo Service)

**Iga teenus sisaldab:**

- `image:` - Mis tõmmist kasutada
- `container_name:` - Konteineri nimi
- `environment:` - Keskkonnamuutujad
- `ports:` - Pordivastendus
- `networks:` - Mis võrgus käivitada
- `volumes:` - Andmeköited
- `depends_on:` - Sõltuvused teistest teenustest
- `healthcheck:` - Tervisekontroll
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

- Node.js 22-slim tõmmis **EI sisalda** `wget` ega `curl` tööriistu
- `healthcheck.js` fail on juba konteineris olemas (Lab 1'st)
- Node on garanteeritult olemas (kuna see on Node.js konteiner)
- Docker Compose healthcheck **kirjutab üle** Dockerfile HEALTHCHECK'i

**Todo Service healthcheck:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8081/health"]
```

**Miks todo-service võib kasutada `wget`?**

- Java runtime tõmmis (eclipse-temurin) sisaldab `wget` tööriista
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
- Mitmeastmeline ehitus (multi-stage build) keerulisem (wget mõlemas stage'is)

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

- Docker Compose EI loo uut andmeköidet
- Kasutab Lab 1'st juba loodud andmeköidet
- Kui andmeköide ei eksisteeri, saad vea (error)

#### `networks:` Blokk

```yaml
networks:
  todo-network:
    external: true
```

**`external: true` tähendab:**

- Docker Compose EI loo uut võrku
- Kasutab Lab 1'st juba loodud võrku
- Kui võrk ei eksisteeri, saad vea (error)

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

### Samm 6: Käivita Stack

```bash
# Käivita kõik teenused
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
- Docker Compose käivitab teenused õiges järjekorras (depends_on)

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

### Samm 7: Vaata Loge

```bash
# Kõigi teenuste logid
docker compose logs

# Konkreetse teenuse logid
docker compose logs user-service

# Follow mode (reaalajas)
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

### Samm 9: Kontrolli andmete püsivust

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

**MÄRKUS:** Andmeköited ja võrk EI kustutatud (external: true)!

```bash
# Kontrolli andmeköidete olemasolu
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

# Rebuild ja restart (kui muutsid tõmmist)
docker compose up -d --build user-service
```

---

## ✅ Kontrolli tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **docker-compose.yml** fail 4 teenusega
- [ ] **Töötav stack** (vaata `docker compose ps`)
- [ ] **Healthy status** kõigi teenuste jaoks
- [ ] **Andmed püsivad** peale restart'i (Lab 1 andmeköited)
- [ ] Oskad käivitada: `docker compose up -d`
- [ ] Oskad peatada: `docker compose down`
- [ ] Oskad vaadata loge: `docker compose logs`
- [ ] Mõistad teenuste sõltuvusi (depends_on)
- [ ] End-to-End JWT töövoog toimib

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas stack töötab?
docker compose ps
# Kõik peaksid olema UP ja HEALTHY

# 2. Kas andmeköited on ühendatud?
docker volume ls | grep postgres
# Peaks leidma: postgres-user-data ja postgres-todo-data

# 3. Kas võrk on ühendatud?
docker network ls | grep todo-network
# Peaks leidma: todo-network

# 4. Kas API'd töötavad?
curl http://localhost:3000/health
curl http://localhost:8081/health
# Mõlemad peaksid tagastama {"status":"ok"}
```

---

## 🎓 Õpitud mõisted

### Docker Compose mõisted:

- **version:** Compose faili versiooni number
- **services:** Konteinerite definitsioonid
- **image:** Valmis tõmmis mida kasutada
- **environment:** Keskkonnamuutujad
- **ports:** Pordivastendus
- **networks:** Võrgud teenuste vahel
- **volumes:** Andmeköited andmete püsivuseks
- **depends_on:** Teenuste sõltuvused
- **healthcheck:** Tervisekontroll
- **restart:** Restart poliitika
- **external:** Kasuta olemasolevat ressurssi

### Docker Compose käsud:

- `docker compose up -d` - Käivita stack taustal
- `docker compose down` - Peata ja eemalda konteinerid
- `docker compose ps` - Vaata teenuste staatust
- `docker compose logs` - Vaata logisid
- `docker compose exec` - Käivita käsk konteineris
- `docker compose config` - Valideeri ja vaata konfiguratsioon
- `docker compose restart` - Taaskäivita teenused

### Service Discovery:

Backend saab ühenduda PostgreSQL-ga kasutades **teenuse nime**:
```yaml
DB_HOST: postgres-user  # Mitte IP aadress!
```

Docker Compose loob automaatselt DNS-i, kus teenuse nimi (`postgres-user`) lahendatakse õigesse IP-sse.

---

## 💡 Parimad tavad

1. **Kasuta external volumes'eid ja networks'e** - Kui ressursid on juba loodud
2. **Määra health checks** - Tead, millal teenus on valmis
3. **Kasuta depends_on + condition** - Õige käivitusjärjekord
4. **Määra restart: unless-stopped** - Auto-restart peale krahhe
5. **Kommenteeri faili** - Teised (ja tulevane sina) tänab sind
6. **Versioonihalda** - Commit docker-compose.yml Git'i

---

## 🐛 Levinud Probleemid

### Probleem 1: "network todo-network declared as external, but could not be found"

```bash
# Loo võrk
docker network create todo-network

# VÕI muuda docker-compose.yml:
networks:
  todo-network:
    # Eemalda "external: true" rida
    driver: bridge
```

### Probleem 2: "volume postgres-user-data declared as external, but could not be found"

```bash
# Loo andmeköide
docker volume create postgres-user-data
docker volume create postgres-todo-data

# VÕI muuda docker-compose.yml:
volumes:
  postgres-user-data:
    # Eemalda "external: true" rida
    driver: local
```

### Probleem 3: "relation \"users\" does not exist" või "relation \"todos\" does not exist"

**Põhjus:** Andmebaasi skeemid (tabelid) puuduvad.

**Lahendus A: Setup Skript (Automaatne)**
```bash
cd ..  # Tagasi 02-docker-compose-lab/
lab2-setup
# Vali valik 2 (Automaatne initsialiseermine)
# või
docker compose -f compose-project/docker-compose.yml -f compose-project/docker-compose.init.yml up -d
```

**Lahendus B: Käsitsi (Pedagoogiline)**
```bash
# User Service database
docker compose exec postgres-user psql -U postgres -d user_service_db <<EOF
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Todo Service database
docker compose exec postgres-todo psql -U postgres -d todo_service_db <<EOF
CREATE TABLE todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    priority VARCHAR(20) DEFAULT 'medium',
    due_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
EOF
```

### Probleem 4: "Backend can't connect to database"

```bash
# Kontrolli, kas DB on healthy
docker compose ps

# Vaata DB loge
docker compose logs postgres-user

# Kontrolli DB_HOST keskkonnamuutujat
docker compose exec user-service env | grep DB_HOST
# Peaks olema: DB_HOST=postgres-user (teenuse nimi)
```

### Probleem 5: "Port already in use"

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

**Põhjus:** Tervisekontroll kasutab `wget` käsku, aga Node.js 22-slim tõmmises ei ole `wget` installitud.

**Diagnoos:**
```bash
# Kontrolli tervisekontrolli viga
docker inspect user-service --format='{{json .State.Health}}' | jq

# Peaks nägema:
# "Output": "exec: \"wget\": executable file not found in $PATH"
```

**Lahendus:**

Docker Compose healthcheck peab kasutama `node healthcheck.js` asemel `wget`:

```yaml
# VALE (ei tööta Node.js slim tõmmises):
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

- Node.js 22-slim tõmmis on minimalistlik (ei sisalda wget/curl)
- `healthcheck.js` fail on juba konteineris (Lab 1'st)
- Docker Compose healthcheck kirjutab üle Dockerfile HEALTHCHECK'i

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

Tehniliselt jah, aga see on **anti-pattern** production tõmmistele:

```dockerfile
# ❌ EI SOOVITATA (AVOID)
FROM node:22-slim
RUN apt-get update && apt-get install -y wget
# Probleem: +5-10MB, rohkem CVE'd, aeglasem build
```

**Production tõmmised peavad olema minimalistlikud:**

- Väiksem rünnakupind (vähem koodi = vähem vigu)
- Vähem turvanõrkusi (iga pakett võib tuua CVE'd)
- Kiiremad paigaldused (väiksem tõmmis = kiirem allalaadimine)
- Odavam salvestusruum/võrguliiklus

**DevOps parim praktika:** Kasuta seda, mis juba on - `node`, `npm`, `healthcheck.js`

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd käivitad 4 teenust ühe docker-compose.yml failiga.

**Mis edasi?**

- ✅ Konverteris Lab 1 → docker-compose.yml
- ✅ 4 teenust töötavad
- ✅ Andmed püsivad
- ⏭️ **Järgmine:** Lisa Frontend (5. teenus)

**Jätka:** [Harjutus 2: Lisa frontend teenus](02-add-frontend.md)

---

## 📚 Viited

- [Docker Compose dokumentatsioon](https://docs.docker.com/compose/)
- [Compose file reference](https://docs.docker.com/compose/compose-file/)
- [depends_on reference](https://docs.docker.com/compose/compose-file/05-services/#depends_on)
- [Healthcheck reference](https://docs.docker.com/compose/compose-file/05-services/#healthcheck)

---

**Õnnitleme! Oled edukalt konverteerinud Lab 1 docker-compose.yml failiks! 🎉**
