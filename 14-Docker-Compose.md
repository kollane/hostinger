# Peatükk 14: Docker Compose

**Kestus:** 4 tundi
**Eeldused:** Peatükk 12-13 läbitud
**Eesmärk:** Õppida multi-container rakenduste haldamist Docker Compose'iga

---

## Sisukord

1. [Mis on Docker Compose?](#1-mis-on-docker-compose)
2. [Docker Compose Paigaldamine](#2-docker-compose-paigaldamine)
3. [docker-compose.yml Struktuur](#3-docker-composeyml-struktuur)
4. [Services (Teenused)](#4-services-teenused)
5. [Networks ja Service Discovery](#5-networks-ja-service-discovery)
6. [Volumes ja Andmete Püsivus](#6-volumes-ja-andmete-püsivus)
7. [Environment Variables](#7-environment-variables)
8. [PRIMAARNE: PostgreSQL + Backend + Frontend](#8-primaarne-postgresql--backend--frontend)
9. [ALTERNATIIV: Väline PostgreSQL + Backend + Frontend](#9-alternatiiv-väline-postgresql--backend--frontend)
10. [Docker Compose Käsud](#10-docker-compose-käsud)
11. [Health Checks](#11-health-checks)
12. [Skaleeritavus](#12-skaleeritavus)
13. [Harjutused](#13-harjutused)

---

## 1. Mis on Docker Compose?

### 1.1. Definitsioon

**Docker Compose** on tööriist multi-container Dockerrakenduste defineerimiseks ja käivitamiseks.

**Probleem ilma Docker Compose'ita:**
```bash
# Käivita PostgreSQL
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=mypass \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:16-alpine

# Loo network
docker network create app-network

# Ühenda PostgreSQL network'iga
docker network connect app-network postgres

# Käivita backend
docker run -d --name backend \
  -e DB_HOST=postgres \
  -e DB_PASSWORD=mypass \
  --network app-network \
  -p 3000:3000 \
  backend:1.0

# Käivita frontend
docker run -d --name frontend \
  --network app-network \
  -p 8080:80 \
  frontend:1.0

# Palju käske! Keeruline! Vigadele avatud!
```

**Lahendus - Docker Compose:**
```bash
# Kõik ühe käsuga!
docker compose up -d
```

---

### 1.2. Docker Compose Eelised

✅ **Deklaratiivne:** Kirjelda mida tahad, mitte kuidas
✅ **Versioonitav:** docker-compose.yml on Gitis
✅ **Reprodutseeritav:** Sama config töötab kõikjal
✅ **Lihtne:** Üks käsk kõigi konteinerite jaoks
✅ **Environment Management:** Dev, test, prod configs

---

## 2. Docker Compose Paigaldamine

### 2.1. Kontrolli Olemasolevat

Docker Compose on juba paigaldatud VPS-is `kirjakast`:

```bash
# SSH VPS-i
ssh janek@kirjakast

# Kontrolli versiooni
docker compose version

# Väljund:
# Docker Compose version v2.40.3
```

✅ **Docker Compose V2 on paigaldatud!**

**MÄRKUS:** Docker Compose V2 on built-in Docker CLI'sse. Varasem versioon (V1) oli eraldi tool `docker-compose` (miinusega).

```bash
# V1 (vana - deprecated):
docker-compose up

# V2 (uus - soovitatud):
docker compose up
```

---

### 2.2. Alternatiiv: Eraldi Paigaldamine (kui puudub)

```bash
# Kui Docker Compose puudub (Ubuntu):
sudo apt update
sudo apt install docker-compose-plugin

# Kontrolli
docker compose version
```

---

## 3. docker-compose.yml Struktuur

### 3.1. Põhistruktuur

```yaml
version: '3.8'  # Compose file version

services:       # Konteinerid/teenused
  service1:
    image: ...
    # konfiguratsioon

  service2:
    build: ...
    # konfiguratsioon

volumes:        # Named volumes
  volume1:

networks:       # Custom networks
  network1:
```

---

### 3.2. YAML Süntaks

**MÄRKUS:** YAML on range taanete (indentation) suhtes. Kasuta **2 tühikut** (mitte tab).

```yaml
# Õige:
services:
  backend:
    image: node:18-alpine
    ports:
      - "3000:3000"

# Vale (tab):
services:
<TAB>backend:
    ...  # ERROR!
```

---

### 3.3. Lihtne Näide

Loo testkataloog:

```bash
cd /home/janek/projects/hostinger
mkdir -p test-compose
cd test-compose
```

Loo `docker-compose.yml`:

```bash
vim docker-compose.yml
```

Vajuta `i` (insert mode) ja lisa:

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
```

Salvesta: `Esc`, siis `:wq`, `Enter`

Käivita:

```bash
docker compose up -d

# Väljund:
# [+] Running 2/2
#  ✔ Network test-compose_default  Created
#  ✔ Container test-compose-web-1  Started

# Testi
curl http://localhost:8080
# Peaks tagastama Nginx welcome page

# Peata
docker compose down
```

---

## 4. Services (Teenused)

### 4.1. Image-based Service

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: mypass
```

### 4.2. Build-based Service

```yaml
services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
```

### 4.3. Service Konfiguratsioon

**Täielik näide:**

```yaml
services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        NODE_ENV: production
    image: backend:1.0
    container_name: my-backend
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      DB_HOST: postgres
    depends_on:
      - postgres
    networks:
      - app-network
    volumes:
      - ./logs:/app/logs
    command: node server.js
```

**Parameetrid:**
- `build`: Build image Dockerfile'ist
- `image`: Image nimi (build või pull)
- `container_name`: Konteineri nimi
- `restart`: Restart policy
- `ports`: Port mapping
- `environment`: Keskkonnamuutujad
- `depends_on`: Sõltuvused
- `networks`: Networks
- `volumes`: Volume mounts
- `command`: Override CMD

---

## 5. Networks ja Service Discovery

### 5.1. Default Network

Docker Compose loob automaatselt bridge network'i:

```yaml
version: '3.8'

services:
  backend:
    image: backend:1.0

  postgres:
    image: postgres:16-alpine
```

**Võrk:** `projectname_default` (nt `test-compose_default`)

**Service Discovery:** Containerid näevad üksteist service name järgi:
- `backend` → saab ühenduda → `postgres:5432`
- `postgres` → saab ühenduda → `backend:3000`

---

### 5.2. Custom Network

```yaml
version: '3.8'

services:
  backend:
    image: backend:1.0
    networks:
      - app-network

  postgres:
    image: postgres:16-alpine
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

---

### 5.3. Multiple Networks

```yaml
services:
  backend:
    networks:
      - frontend-network
      - backend-network

  postgres:
    networks:
      - backend-network

  nginx:
    networks:
      - frontend-network

networks:
  frontend-network:
  backend-network:
```

**Tulemus:**
- nginx ↔ backend ✅
- backend ↔ postgres ✅
- nginx ↔ postgres ❌ (erinevad networkid)

---

## 6. Volumes ja Andmete Püsivus

### 6.1. Named Volumes

```yaml
services:
  postgres:
    image: postgres:16-alpine
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
    driver: local
```

**Kus andmed on:**
```bash
docker volume inspect projectname_postgres-data

# Mountpoint: /var/lib/docker/volumes/projectname_postgres-data/_data
```

---

### 6.2. Bind Mounts

```yaml
services:
  backend:
    image: backend:1.0
    volumes:
      - ./backend:/app            # Kood
      - ./logs:/app/logs           # Logid
      - ./config.json:/app/config.json:ro  # Read-only
```

**Kasutusjuhtumid:**
- **Development:** Koodi muutused konteineris kohe nähtavad
- **Logid:** Konteiner kirjutab host'i
- **Konfiguratsioon:** Host failid konteineris

---

### 6.3. Anonymous Volumes

```yaml
services:
  app:
    volumes:
      - /app/node_modules  # Anonymous volume
```

Kasulik, kui tahad välistada kataloogi bind mount'ist.

---

## 7. Environment Variables

### 7.1. Environment Blokk

```yaml
services:
  backend:
    environment:
      NODE_ENV: production
      DB_HOST: postgres
      DB_PORT: 5432
      DEBUG: "true"
```

---

### 7.2. .env Fail

Loo `.env` fail:

```bash
vim .env
```

Lisa:

```env
DB_PASSWORD=MyStrongPassword123!
JWT_SECRET=MySecretKey456
NODE_ENV=production
```

`docker-compose.yml`:

```yaml
services:
  backend:
    environment:
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      NODE_ENV: ${NODE_ENV}
```

**MÄRKUS:** Lisa `.env` `.gitignore`-sse:

```bash
echo ".env" >> .gitignore
```

---

### 7.3. env_file

```yaml
services:
  backend:
    env_file:
      - .env
      - .env.production
```

Kõik muutujad failist laetakse automaatselt.

---

## 8. PRIMAARNE: PostgreSQL + Backend + Frontend

### 8.1. Projekti Struktuur

```bash
cd /home/janek/projects/hostinger/labs/apps
tree -L 2

# Struktuur:
# apps/
# ├── backend-nodejs/
# │   ├── Dockerfile
# │   ├── server.js
# │   └── ...
# ├── frontend/
# │   ├── Dockerfile
# │   └── ...
# └── docker-compose.yml  # Loome selle
```

---

### 8.2. docker-compose.yml (Täielik Stack)

```bash
cd /home/janek/projects/hostinger/labs/apps
vim docker-compose.yml
```

Vajuta `i` ja lisa:

```yaml
version: '3.8'

services:
  # PostgreSQL andmebaas
  postgres:
    image: postgres:16-alpine
    container_name: app-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${DB_PASSWORD:-defaultpass123}
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
      context: ./backend-nodejs
      dockerfile: Dockerfile
    container_name: app-backend
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      NODE_ENV: production
      PORT: 3000
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: appdb
      DB_USER: appuser
      DB_PASSWORD: ${DB_PASSWORD:-defaultpass123}
      JWT_SECRET: ${JWT_SECRET:-defaultsecret456}
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

  # Frontend (Nginx)
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: app-frontend
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - "8080:80"
    networks:
      - app-network

volumes:
  postgres-data:
    driver: local

networks:
  app-network:
    driver: bridge
```

Salvesta: `Esc`, `:wq`, `Enter`

---

### 8.3. .env Fail Loomine

```bash
vim .env
```

Lisa:

```env
DB_PASSWORD=MyStrongPassword123!
JWT_SECRET=MyJWTSecret789ForAuthToken
```

Salvesta ja määra õigused:

```bash
chmod 600 .env
```

---

### 8.4. Käivitamine

```bash
# Build ja start
docker compose up -d

# Väljund:
# [+] Running 5/5
#  ✔ Network apps_app-network           Created
#  ✔ Volume "apps_postgres-data"        Created
#  ✔ Container app-postgres             Started
#  ✔ Container app-backend              Started
#  ✔ Container app-frontend             Started

# Kontrolli
docker compose ps

# Väljund:
# NAME            IMAGE               STATUS          PORTS
# app-postgres    postgres:16-alpine  Up (healthy)    5432/tcp
# app-backend     apps-backend        Up (healthy)    0.0.0.0:3000->3000/tcp
# app-frontend    apps-frontend       Up              0.0.0.0:8080->80/tcp
```

---

### 8.5. Testimine

```bash
# Backend health check
curl http://localhost:3000/health

# Väljund:
# {"status":"ok","database":"connected"}

# Frontend
curl http://localhost:8080

# Peaks tagastama HTML
```

---

### 8.6. Logid

```bash
# Kõigi teenuste logid
docker compose logs

# Ühe teenuse logid
docker compose logs backend

# Follow mode (real-time)
docker compose logs -f backend

# Viimased 100 rida
docker compose logs --tail=100 backend
```

---

## 9. ALTERNATIIV: Väline PostgreSQL + Backend + Frontend

### 9.1. Stsenaarium

PostgreSQL töötab **välisel serveril** (näiteks dedikeeritud DB server).

---

### 9.2. docker-compose.yml (Ilma PostgreSQL-ita)

```yaml
version: '3.8'

services:
  # Backend - ühendub välise DB-ga
  backend:
    build:
      context: ./backend-nodejs
      dockerfile: Dockerfile
    container_name: app-backend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      PORT: 3000
      # Väline PostgreSQL
      DB_HOST: ${EXTERNAL_DB_HOST}  # nt db.example.com või 93.127.213.242
      DB_PORT: ${EXTERNAL_DB_PORT:-5432}
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_SSL: "true"  # Väline DB nõuab SSL
      JWT_SECRET: ${JWT_SECRET}
      JWT_EXPIRES_IN: 7d
    ports:
      - "3000:3000"
    networks:
      - app-network

  # Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: app-frontend
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - "8080:80"
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

---

### 9.3. .env Fail (Väline DB)

```env
# Väline PostgreSQL
EXTERNAL_DB_HOST=db.example.com
EXTERNAL_DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=ExternalDBPassword123!

# Backend
JWT_SECRET=MyJWTSecret789
```

---

### 9.4. Backend Kood (SSL Ühendus)

`backend-nodejs/config/database.js`:

```javascript
const { Pool } = require('pg');
const fs = require('fs');

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? {
    rejectUnauthorized: true,
    ca: fs.readFileSync('/path/to/ca-cert.crt').toString()
  } : false
});

module.exports = pool;
```

---

## 10. Docker Compose Käsud

### 10.1. Põhikäsud

```bash
# Start teenused (build kui vajalik)
docker compose up

# Start taustal
docker compose up -d

# Rebuild images
docker compose up --build

# Stop teenused (konteinerid jäävad)
docker compose stop

# Start peatatud teenused
docker compose start

# Restart teenused
docker compose restart

# Stop ja eemalda konteinerid, networks
docker compose down

# Stop, eemalda kõik (+ volumes)
docker compose down -v

# Stop, eemalda kõik (+ images)
docker compose down --rmi all
```

---

### 10.2. Teenuste Haldamine

```bash
# Konkreetne teenus
docker compose up backend
docker compose stop backend
docker compose restart backend

# Scale teenust
docker compose up -d --scale backend=3

# Vaata töötavaid teenuseid
docker compose ps

# Vaata kõiki (ka peatatud)
docker compose ps -a
```

---

### 10.3. Logid ja Debug

```bash
# Logid
docker compose logs

# Konkreetse teenuse logid
docker compose logs backend

# Follow
docker compose logs -f

# Viimased N rida
docker compose logs --tail=50 backend

# Vaata konfiguratsioon
docker compose config

# Valideeri compose fail
docker compose config --quiet
```

---

### 10.4. Exec ja Run

```bash
# Käivita käsk töötavas konteineris
docker compose exec backend sh
docker compose exec backend npm test
docker compose exec postgres psql -U appuser -d appdb

# Käivita uus konteiner
docker compose run backend node --version
docker compose run --rm backend npm install
```

---

## 11. Health Checks

### 11.1. Mis on Health Check?

**Health check** kontrollib, kas konteiner on tõesti töövalmis (mitte ainult running).

---

### 11.2. PostgreSQL Health Check

```yaml
services:
  postgres:
    image: postgres:16-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser"]
      interval: 10s      # Kontrolli iga 10 sekundi järel
      timeout: 5s        # Timeout 5 sekundit
      retries: 5         # 5 ebaõnnestumist = unhealthy
      start_period: 30s  # Oota 30 sek enne kontrolli
```

---

### 11.3. Backend Health Check

```yaml
services:
  backend:
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

**Backend peab pakkuma `/health` endpoint-i:**

`server.js`:

```javascript
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

---

### 11.4. depends_on + condition

```yaml
services:
  backend:
    depends_on:
      postgres:
        condition: service_healthy  # Oota kuni postgres on healthy
```

---

## 12. Skaleeritavus

### 12.1. Scale Teenust

```bash
# Käivita 3 backend koopiat
docker compose up -d --scale backend=3

# Kontrolli
docker compose ps

# Väljund:
# NAME              STATUS
# app-backend-1     Up
# app-backend-2     Up
# app-backend-3     Up
# app-postgres      Up
# app-frontend      Up
```

---

### 12.2. Load Balancing

Docker Compose teeb automaatselt round-robin load balancing DNS-iga:

```yaml
services:
  backend:
    # Ei määra container_name-i (laseb Compose nummerdada)
    build: ./backend

  frontend:
    # Frontend saab backend-ile ligi service name järgi
    environment:
      BACKEND_URL: http://backend:3000
```

Kui backend on scaled 3-ks, siis `backend:3000` roteerib kõigi vahel.

---

## 13. Harjutused

### Harjutus 14.1: Lihtne Stack

**Eesmärk:** Käivita Nginx + PostgreSQL

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: test123
```

**Ülesanded:**
1. Loo `docker-compose.yml`
2. Käivita: `docker compose up -d`
3. Testi: `curl localhost:8080`
4. Ühenda DB-ga: `docker compose exec db psql -U postgres`

---

### Harjutus 14.2: Backend + PostgreSQL

**Eesmärk:** Käivita backend-nodejs koos PostgreSQL-iga

1. Kasuta `labs/apps/backend-nodejs/` koodi
2. Loo `docker-compose.yml` (kasuta sektsiooni 8.2 näidet)
3. Käivita stack
4. Testi API: `curl localhost:3000/health`
5. Registreeri kasutaja: `POST /api/auth/register`

---

### Harjutus 14.3: Täis Stack (PostgreSQL + Backend + Frontend)

1. Kasuta täielikku näidet (sektsioon 8.2)
2. Build ja käivita kõik 3 teenust
3. Ava frontend brauseris: `http://kirjakast:8080`
4. Registreeri ja logi sisse
5. Vaata loge: `docker compose logs -f`

---

### Harjutus 14.4: Väline PostgreSQL

1. Paigalda PostgreSQL otse VPS-ile (Peatükk 3)
2. Loo compose fail ilma PostgreSQL teenuseta (sektsioon 9.2)
3. Seadista .env väline DB jaoks
4. Käivita ainult backend + frontend
5. Testi ühendust

---

### Harjutus 14.5: Scaling

1. Scale backend 3-ks: `docker compose up -d --scale backend=3`
2. Testi load balancing-ut: tee mitu API päringu
3. Vaata logisid: `docker compose logs backend`
4. Scale down: `docker compose up -d --scale backend=1`

---

## 14. Troubleshooting

### Probleem 1: "Service 'X' failed to build"

```bash
# Vaata build loge
docker compose build backend

# Force rebuild (no cache)
docker compose build --no-cache backend
```

---

### Probleem 2: "Port already in use"

```bash
# Vaata, mis kasutab porti
sudo lsof -i :3000

# Muuda port
# docker-compose.yml:
ports:
  - "3001:3000"  # Host port 3001
```

---

### Probleem 3: "Backend can't connect to PostgreSQL"

```bash
# 1. Kontrolli, kas postgres töötab
docker compose ps postgres

# 2. Vaata postgres loge
docker compose logs postgres

# 3. Testi ühendust backend-ist
docker compose exec backend ping postgres

# 4. Testi psql
docker compose exec backend sh
# (shell-is:)
apk add postgresql-client
psql -h postgres -U appuser -d appdb
```

---

### Probleem 4: "Changes not reflected"

```bash
# Rebuild images
docker compose up --build -d

# VÕI force recreate
docker compose up -d --force-recreate
```

---

## Kokkuvõte

Selles peatükis said:

✅ **Õppisid Docker Compose põhimõtteid**
✅ **Kirjutasid docker-compose.yml faile**
✅ **Käivitasid multi-container stack-e** (PostgreSQL + Backend + Frontend)
✅ **Mõistsid variantide erinevusi** (Dockeriseeritud vs väline PostgreSQL)
✅ **Õppisid networks, volumes, env variables-t**
✅ **Kasutasid health checks ja dependencies-t**
✅ **Skaleerisid teenuseid**

---

## Järgmine Peatükk

**Peatükk 15: Docker Registry ja Image Haldamine**

Järgmises peatükis:
- Docker Hub kasutamine
- Private registry loomine
- Image tagging strateegiad
- CI/CD integratsioon

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
**VPS:** kirjakast (Ubuntu 24.04 LTS)
