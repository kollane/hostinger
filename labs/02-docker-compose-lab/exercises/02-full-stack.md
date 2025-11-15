# Harjutus 2: Täielik Full-Stack Compose

**Kestus:** 60 minutit
**Eesmärk:** Käivita 3-tier rakendus: Frontend + Backend + PostgreSQL

---

## 📋 Ülevaade

Selles harjutuses laiendad eelmise harjutuse docker-compose.yml faili, lisades **Frontend** teenuse. Lood täieliku full-stack rakenduse koos kasutajaliidesega.

**Mis on uut:**
- Frontend teenus (Nginx + Vanilla JS)
- 3-tier arhitektuur (Presentation → Application → Data)
- Port mappingud kõigile teenustele
- Teenuste vaheline suhtlus

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Lisada Frontend teenust Docker Compose stack'i
- ✅ Konfigureerida 3-tier arhitektuuri
- ✅ Hallata mitut port mappingut
- ✅ Mõista teenuste vahelisi sõltuvusi
- ✅ Testida täielikku rakendust brauseris
- ✅ Debuggida multi-tier rakendusi

---

## 🏗️ Arhitektuur

```
        Browser (http://kirjakast:8080)
              │
              ▼
    ┌──────────────────────┐
    │  Frontend Service    │
    │  (Nginx)             │
    │  Port: 8080          │
    └──────────┬───────────┘
               │ API calls
               ▼
    ┌──────────────────────┐
    │  Backend Service     │
    │  (Node.js/Express)   │
    │  Port: 3000          │
    └──────────┬───────────┘
               │ SQL queries
               ▼
    ┌──────────────────────┐
    │  PostgreSQL          │
    │  Database            │
    │  Port: 5432          │
    └──────────────────────┘
               │
         postgres-data
           (volume)
```

---

## 📝 Sammud

### Samm 1: Loo Frontend Dockerfile (10 min)

Esmalt peame looma Dockerfile'i frontend'ile (kui see puudub).

```bash
# Mine frontend kausta
cd /home/janek/projects/hostinger/labs/apps/frontend

# Kontrolli, kas Dockerfile on olemas
ls -la Dockerfile
```

Kui Dockerfile **puudub**, loo see:

```bash
vim Dockerfile
```

Lisa:

```dockerfile
FROM nginx:alpine

# Kopeeri frontend failid Nginx default html kausta
COPY . /usr/share/nginx/html

# Kopeeri Nginx konfiguratsioon (kui on custom config)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

Salvesta: `Esc`, `:wq`, `Enter`

---

### Samm 2: Laienda docker-compose.yml (15 min)

Mine tagasi compose projekti kausta:

```bash
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/my-compose-project
```

Muuda `docker-compose.yml`:

```bash
vim docker-compose.yml
```

Lisa frontend teenus (peale backend blokki):

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

  # Frontend (Nginx + Vanilla JS)
  frontend:
    build:
      context: ../../apps/frontend
      dockerfile: Dockerfile
    container_name: my-frontend
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - "8080:80"
    networks:
      - app-network
    environment:
      BACKEND_URL: http://backend:3000

volumes:
  postgres-data:
    driver: local

networks:
  app-network:
    driver: bridge
```

Salvesta: `Esc`, `:wq`, `Enter`

---

### Samm 3: Konfigureeri Frontend API Endpoint (10 min)

Frontend peab teadma, kus backend asub. Kontrolli frontend koodi:

```bash
vim ../../apps/frontend/app.js
```

**Otsi rida:**

```javascript
const API_URL = 'http://localhost:3000';
```

**Probleem:** Container sees ei tööta `localhost:3000`!

**Lahendused:**

#### Variant A: Kasuta VPS IP aadressi (lihtne)

```javascript
const API_URL = 'http://93.127.213.242:3000';
```

#### Variant B: Kasuta relatiivset path'i + proxy (parem)

Frontend fail:
```javascript
const API_URL = '/api';
```

Nginx config (`nginx.conf`):
```nginx
server {
    listen 80;

    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Selles harjutuses kasutame Varianti A (lihtsam).**

---

### Samm 4: Käivita Täielik Stack (10 min)

```bash
# Kui eelmine stack töötab, peata see
docker compose down

# Build ja start kõik 3 teenust
docker compose up -d --build

# Väljund:
# [+] Running 4/4
#  ✔ Network my-compose-project_app-network       Created
#  ✔ Container my-postgres                        Healthy
#  ✔ Container my-backend                         Started
#  ✔ Container my-frontend                        Started
```

**Kontrolli:**

```bash
docker compose ps

# Väljund:
# NAME          IMAGE                       STATUS          PORTS
# my-postgres   postgres:16-alpine          Up (healthy)    5432/tcp
# my-backend    my-compose-project-backend  Up (healthy)    0.0.0.0:3000->3000/tcp
# my-frontend   my-compose-project-frontend Up              0.0.0.0:8080->80/tcp
```

---

### Samm 5: Testi Backend API (5 min)

```bash
# Backend health check
curl http://localhost:3000/health

# Registreeri kasutaja
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Smith",
    "email": "alice@example.com",
    "password": "alice123"
  }'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@example.com",
    "password": "alice123"
  }'
```

---

### Samm 6: Testi Frontend Brauseris (10 min)

#### Ava Frontend

Ava brauser ja mine:

```
http://kirjakast:8080
```

VÕI kui kasutad local masinal:

```
http://93.127.213.242:8080
```

**Peaks nägema:**
- Registreerimise vorm
- Login vorm
- Kasutajate nimekiri

#### Testi Funktsionaalsust

1. **Registreeri uus kasutaja:**
   - Nimi: Bob Johnson
   - Email: bob@example.com
   - Parool: bob123
   - Vajuta "Register"

2. **Logi sisse:**
   - Email: bob@example.com
   - Parool: bob123
   - Vajuta "Login"

3. **Vaata kasutajate nimekirja:**
   - Peaks näitama Alice ja Bob

---

### Samm 7: Vaata Loge (5 min)

Jälgi, mis backend ja frontend teevad:

```bash
# Kõigi teenuste logid korraga
docker compose logs -f

# Ainult backend
docker compose logs -f backend

# Ainult frontend (Nginx access log)
docker compose logs -f frontend
```

**Tee API päring brauseris ja vaata, kuidas logid ilmuvad!**

---

### Samm 8: Debug Network't (5 min)

#### Test 1: Kas Frontend Näeb Backend'i?

```bash
# Sisene frontend konteinerisse
docker compose exec frontend sh

# Shell sees:
apk add curl
curl http://backend:3000/health

# Peaks tagastama:
# {"status":"ok","database":"connected"}

exit
```

#### Test 2: Kas Backend Näeb PostgreSQL-i?

```bash
docker compose exec backend sh

# Shell sees:
apk add postgresql-client
psql -h postgres -U appuser -d user_service_db

# SQL console:
SELECT * FROM users;
\q

exit
```

#### Test 3: Vaata Network Infot

```bash
# Näita network detaile
docker network inspect my-compose-project_app-network

# Peaks näitama kõiki 3 containerit:
# - my-postgres
# - my-backend
# - my-frontend
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **3 teenust** docker-compose.yml failis
- [ ] **Kõik töötavad** (`docker compose ps`)
- [ ] **Frontend kättesaadav** brauseris (port 8080)
- [ ] **Backend API toimib** (port 3000)
- [ ] **PostgreSQL töötab** ja andmed püsivad
- [ ] Oskad registreerida ja sisse logida läbi UI
- [ ] Mõistad 3-tier arhitektuuri

---

## 🧪 Testimine

### End-to-End Test:

```bash
# 1. Kas kõik 3 teenust töötavad?
docker compose ps
# Kõik peaksid olema UP

# 2. Backend API
curl http://localhost:3000/health

# 3. Frontend
curl http://localhost:8080
# Peaks tagastama HTML

# 4. Brauseris
# Ava http://kirjakast:8080
# Registreeri kasutaja → Login → Vaata nimekirja
```

---

## 🎓 Õpitud Mõisted

### 3-Tier Arhitektuur:

1. **Presentation Tier** - Frontend (Nginx + HTML/CSS/JS)
2. **Application Tier** - Backend (Node.js + Express)
3. **Data Tier** - Database (PostgreSQL)

### Depends_on Hierarhia:

```yaml
frontend:
  depends_on:
    - backend      # Frontend sõltub backend'ist

backend:
  depends_on:
    postgres:
      condition: service_healthy  # Backend sõltub DB-st
```

**Käivitusjärjekord:**
1. PostgreSQL (kõigepealt)
2. Backend (kui PostgreSQL on healthy)
3. Frontend (kui backend on käivitatud)

### Port Mapping:

- **8080:80** - Frontend (host port 8080 → container port 80)
- **3000:3000** - Backend (host port 3000 → container port 3000)
- **5432** - PostgreSQL (ainult internal, ei ole exposed)

---

## 💡 Parimad Tavad

### Port Management:

```yaml
# Frontend - exposed
ports:
  - "8080:80"

# Backend - exposed (API jaoks)
ports:
  - "3000:3000"

# PostgreSQL - MITTE exposed (turvalisem)
# Ainult backend saab ühenduda
```

### Service Discovery:

Frontend → Backend:
```javascript
// Kui frontend calls backend VÄLJASTPOOLT Docker't:
const API_URL = 'http://kirjakast:3000';

// Kui frontend calls backend SEEST (läbi Nginx proxy):
const API_URL = '/api';
```

Backend → PostgreSQL:
```yaml
environment:
  DB_HOST: postgres  # Service nimi!
```

---

## 🐛 Levinud Probleemid

### Probleem 1: "Frontend can't connect to backend"

**Sümptom:** Login ei tööta, console error "Failed to fetch"

**Lahendus:**

```javascript
// Frontend app.js - kontrolli API URL
const API_URL = 'http://93.127.213.242:3000';  // Kasuta VPS IP

// VÕI
const API_URL = 'http://kirjakast:3000';  // Kasuta hostname'i
```

### Probleem 2: "CORS error"

**Sümptom:** Browser console: "CORS policy blocked"

**Lahendus:** Backend peab lubama frontend origin:

```javascript
// backend-nodejs/server.js
const cors = require('cors');

app.use(cors({
  origin: ['http://kirjakast:8080', 'http://93.127.213.242:8080'],
  credentials: true
}));
```

### Probleem 3: "Port 8080 already in use"

```bash
# Kontrolli, mis kasutab porti
sudo lsof -i :8080

# Muuda porti
ports:
  - "8081:80"  # Kasuta 8081 asemel
```

---

## 🔧 Täiendavad Ülesanded (Valikuline)

### Ülesanne 1: Lisa Teine Backend Instants (Scaling)

```bash
# Scale backend 2-ks
docker compose up -d --scale backend=2

# Probleem: container_name konflikt!
# Lahendus: eemalda container_name backend'ist
```

### Ülesanne 2: Lisa Nginx Reverse Proxy

Muuda frontend Nginx config, et proxy backend calls:

```nginx
location /api {
  proxy_pass http://backend:3000;
}
```

### Ülesanne 3: Lisa pgAdmin

Lisa pgAdmin teenus PostgreSQL haldamiseks:

```yaml
pgadmin:
  image: dpage/pgadmin4
  environment:
    PGADMIN_DEFAULT_EMAIL: admin@example.com
    PGADMIN_DEFAULT_PASSWORD: admin
  ports:
    - "5050:80"
  networks:
    - app-network
```

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd on sul töötav full-stack rakendus.

Aga **probleem:** Kõik konfiguratsioon on production jaoks. Mis arenduse ajal?

Järgmises harjutuses lood **eraldi dev ja prod keskkonnad**!

**Jätka:** [Harjutus 3: Dev ja Prod Keskkonnad](03-dev-prod-envs.md)

---

## 📚 Viited

- [Multi-container apps with Compose](https://docs.docker.com/compose/gettingstarted/)
- [Networking in Compose](https://docs.docker.com/compose/networking/)
- [Using depends_on](https://docs.docker.com/compose/compose-file/05-services/#depends_on)

---

**Õnnitleme! Sul on nüüd töötav full-stack rakendus Docker Compose'is! 🚀**
