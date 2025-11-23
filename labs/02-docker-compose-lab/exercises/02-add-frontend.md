# Harjutus 2: Lisa Frontend Teenus

**Kestus:** 45 minutit
**Eesmärk:** Lisa Frontend teenus (service) Nginx'iga (5. komponent)

---

## 📋 Ülevaade

Selles harjutuses laiendad Harjutus 1 docker-compose.yml faili, lisades **Frontend teenuse (service)**. Lood täieliku full-stack rakenduse koos kasutajaliidesega, mis suhtleb mõlema backend'iga.

**Mis on uut:**
- Frontend teenus (service) (Nginx + staatiline HTML/CSS/JS)
- 5-tier arhitektuur (Presentation → Application → Data)
- Volume mount staatiliste failide (static files) jaoks
- Teenuste vaheline suhtlus brauseri kaudu

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Lisada Frontend teenust (service) Docker Compose stack'i
- ✅ Konfigureerida Nginx teenust (service)
- ✅ Mount'ida staatilisi faile (static files) volume'iga
- ✅ Hallata 5-tier arhitektuuri
- ✅ Testida täielikku rakendust brauseris
- ✅ Debuggida frontend-backend suhtlust

---

## 🏗️ Arhitektuur

### Enne (Harjutus 1):

```
┌─────────────────┐    ┌─────────────────┐
│  User Service   │    │  Todo Service   │
│  Port: 3000     │    │  Port: 8081     │
└────────┬────────┘    └────────┬────────┘
         │                      │
         ▼                      ▼
┌─────────────────┐    ┌─────────────────┐
│  PostgreSQL     │    │  PostgreSQL     │
│  Port: 5432     │    │  Port: 5433     │
└─────────────────┘    └─────────────────┘
```

### Peale (Harjutus 2):

```
               Browser (http://kirjakast:8080)
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Frontend (Nginx)              │
        │  Port: 8080                    │
        │  Staatiline HTML/CSS/JS        │
        └────┬──────────────────────┬────┘
             │                      │
             │ API Calls            │
             ▼                      ▼
    ┌─────────────────┐    ┌─────────────────┐
    │  User Service   │    │  Todo Service   │
    │  Port: 3000     │    │  Port: 8081     │
    └────────┬────────┘    └────────┬────────┘
             │                      │
             ▼                      ▼
    ┌─────────────────┐    ┌─────────────────┐
    │  PostgreSQL     │    │  PostgreSQL     │
    │  Port: 5432     │    │  Port: 5433     │
    └─────────────────┘    └─────────────────┘
```

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Harjutus 1 on läbitud:**

```bash
# 1. Kas docker-compose.yml on olemas?
ls -la compose-project/docker-compose.yml

# 2. Kas stack töötab?
cd compose-project
docker compose ps
# Peaks nägema 4 teenust (services): postgres-user, postgres-todo, user-service, todo-service

# 3. Kas backend API'd töötavad?
curl http://localhost:3000/health
curl http://localhost:8081/health
```

**Kui midagi puudub:**
- 🔗 Mine tagasi [Harjutus 1](01-compose-basics.md)

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📝 Sammud

### Samm 1: Tutvu Frontend Lähtekoodiga (5 min)

Frontend rakendus on juba valmis kirjutatud (`labs/apps/frontend/`):

```bash
# Vaata frontend struktuuri
ls -la ../../apps/frontend/

# Peaks nägema:
# index.html   - Pealeht (login/register vorm)
# app.js       - JavaScript (API calls, JWT handling)
# styles.css   - Stiilid
```

**Frontend funktsioonid:**
- Login vorm (suhtleb User Service'iga)
- Register vorm (suhtleb User Service'iga)
- Todo list (suhtleb Todo Service'iga)
- JWT token'i haldamine (localStorage)

**Ava ja vaata faile:**

```bash
# Vaata peahel (index.html)
head -30 ../../apps/frontend/index.html

# Vaata JavaScripti
head -50 ../../apps/frontend/app.js
```

---

### Samm 2: Lisa Frontend Teenus docker-compose.yml'i (15 min)

Ava docker-compose.yml fail:

```bash
cd compose-project
vim docker-compose.yml
```

Lisa **frontend teenus (service)** järgmise struktuuri järgi (peale todo-service'i, enne volumes:):

```yaml
  # ==========================================================================
  # Frontend - Nginx Static Files
  # ==========================================================================
  frontend:
    image: nginx:alpine
    container_name: frontend
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      # Mount frontend failid (read-only)
      - ../../apps/frontend:/usr/share/nginx/html:ro
      # Mount Nginx konfiguratsioon (reverse proxy API päringutele)
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - todo-network
    depends_on:
      - user-service
      - todo-service
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost"]
      interval: 30s
      timeout: 3s
      retries: 3
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 2.5: Lisa Nginx Reverse Proxy Konfiguratsioon (10 min)

**Miks see on vajalik?**

Frontend JavaScript (`app.js`) teeb API päringuid relatiivse URL-iga `/api`:
- Brauser saadab: `http://kirjakast.cloud:8080/api/auth/login`
- Backend API'd töötavad: `http://user-service:3000` ja `http://todo-service:8081`
- **Nginx peab proxy-ma API päringud õigetesse portidesse**

**Arhitektuur:**

```
Browser
  ↓ http://kirjakast.cloud:8080/api/auth/login
Nginx (port 8080)
  ↓ proxy_pass
  ├─ /api/auth/*  → user-service:3000
  ├─ /api/users*  → user-service:3000
  └─ /api/todos*  → todo-service:8081
```

**Loo nginx.conf fail:**

```bash
vim nginx.conf
```

Vajuta `i` (insert mode) ja lisa:

```nginx
server {
    listen 80;
    server_name _;

    # Frontend staatilised failid
    root /usr/share/nginx/html;
    index index.html;

    # Frontend staatilised failid (HTML, CSS, JS)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # ===========================================
    # API Reverse Proxy - User Service (Port 3000)
    # ===========================================

    # Auth endpoints (/api/auth/register, /api/auth/login)
    location /api/auth/ {
        proxy_pass http://user-service:3000/api/auth/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # User endpoints (/api/users, /api/users/me)
    location /api/users {
        proxy_pass http://user-service:3000/api/users;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ===========================================
    # API Reverse Proxy - Todo Service (Port 8081)
    # ===========================================

    # Todo endpoints (/api/todos)
    location /api/todos {
        proxy_pass http://todo-service:8081/api/todos;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Salvesta: `Esc`, siis `:wq`, `Enter`

**Kontrolli:**

```bash
# Kas nginx.conf on olemas?
ls -la nginx.conf

# Kas docker-compose.yml mount'ib seda?
grep "nginx.conf" docker-compose.yml
# Peaksid nägema: - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

---

### Samm 3: Mõista Frontend Konfiguratsiooni (5 min)

**Analüüsi lisatud teenust (service):**

#### `image: nginx:alpine`
- Kasutab Nginx Alpine pilti (image) (väike, ~10MB)
- Nginx on veebiserver staatiliste failide (static files) jaoks

#### `volumes: - ../../apps/frontend:/usr/share/nginx/html:ro`
- Mount'ib `labs/apps/frontend/` kausta konteinerisse
- `:ro` = read-only (konteiner ei saa faile muuta)
- Nginx serveerib neid faile portist 80

#### `ports: - "8080:80"`
- Host port 8080 vastendub (maps to) konteineri port 80
- Brauserist: `http://kirjakast:8080` → Nginx port 80

#### `depends_on: - user-service - todo-service`
- Frontend käivitub peale mõlemat backend'i
- Ei vaja `condition: service_healthy` (frontend ei kontrolli backend'i startup'il)

#### `healthcheck`
- Kontrollib, kas Nginx vastab HTTP päringutele
- Tagab, et teenus (service) on valmis päringuid vastu võtma

#### `volumes: - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro`
- Mount'ib Nginx konfiguratsiooni konteinerisse
- `/etc/nginx/conf.d/default.conf` on Nginx vaikimisi konfiguratsioon
- **Võimaldab reverse proxy funktsionaalsust**

**Nginx Reverse Proxy tööloogika:**

1. **Frontend failid (HTML/CSS/JS):**
   - `location /` → serveerib `/usr/share/nginx/html`
   - Brauser laeb: `http://kirjakast.cloud:8080/index.html`

2. **API päringud (JavaScript):**
   - Frontend teeb: `fetch('/api/auth/login')`
   - Brauser saadab: `http://kirjakast.cloud:8080/api/auth/login`
   - Nginx proxy_pass: `http://user-service:3000/api/auth/login`
   - User Service vastab → Nginx edastab → Brauser

3. **Miks see on oluline:**
   - ✅ Üks port (8080) kõigile päringutele
   - ✅ Ei ole CORS probleeme (sama origin)
   - ✅ Backend portid (3000, 8081) pole avalikult kättesaadavad
   - ✅ Lihtne URL struktuur frontend'is (`/api`)

**Ilma reverse proxy'ta:**
- Frontend peaks teadma backend URL-e: `http://kirjakast.cloud:3000`, `http://kirjakast.cloud:8081`
- CORS vead (cross-origin requests)
- Keerulisem turvalisuse haldamine

---

### Samm 4: Valideeri ja Käivita (5 min)

```bash
# Valideeri YAML syntax'it
docker compose config

# Peata olemasolev stack
docker compose down

# Käivita uuesti 5 teenusega (service)
docker compose up -d

# Kontrolli staatust
docker compose ps

# Peaksid nägema 5 teenust (services):
# NAME            IMAGE                        STATUS
# frontend        nginx:alpine                 Up (healthy)
# postgres-todo   postgres:16-alpine           Up (healthy)
# postgres-user   postgres:16-alpine           Up (healthy)
# todo-service    todo-service:1.0-optimized   Up (healthy)
# user-service    user-service:1.0-optimized   Up (healthy)
```

**Kontrolli frontend loge:**

```bash
docker compose logs frontend

# Peaks nägema:
# frontend  | ... Nginx started successfully
```

---

### Samm 5: Testi Brauseris (10 min)

#### Test 1: Ava Frontend

Ava brauseris:
```
http://kirjakast:8080
```

või kui töötad lokaalselt:
```
http://localhost:8080
```

**Peaksid nägema:**
- Login / Register vorm
- Pealkiri: "Todo Application"
- Stiilitud liides

#### Test 2: Registreeri Uus Kasutaja

1. Kliki "Register" tab'i
2. Sisesta:
   - Name: `Frontend Test`
   - Email: `frontend@example.com`
   - Password: `test123`
3. Kliki "Register"

**Oodatud:**
- Eduka registreerimise sõnum
- Automaatne login
- Suunamine todo listi lehele

#### Test 3: Loo Todo

1. Sisesta todo pealkiri: `Õpi Docker Compose Frontend'iga`
2. Sisesta kirjeldus: `Lisasin frontend teenuse edukalt!`
3. Vali priority: `High`
4. Kliki "Add Todo"

**Oodatud:**
- Todo ilmub nimekirja
- Saad märkida completed'ks
- Saad kustutada

#### Test 4: Logout ja Login

1. Kliki "Logout"
2. Logisõrgu sisse:
   - Email: `frontend@example.com`
   - Password: `test123`

**Oodatud:**
- Edukas login
- Todo nimekiri näitab eelnevalt loodud todo'd

---

### Samm 6: Debug Frontend-Backend Suhtlust (5 min)

#### Kontrolli Brauseri Console'i

Vajuta `F12` ja ava "Console" tab.

**Peaksid nägema:**
```
API Request: POST http://kirjakast.cloud:8080/api/auth/register
API Response: { message: "User created successfully", ... }
API Request: GET http://kirjakast.cloud:8080/api/todos
API Response: { content: [...], totalElements: 1 }
```

**Oluline:** Kõik API päringud lähevad läbi Nginx (port 8080), mitte otse backend portidesse!

#### Kontrolli Network Tab'i

Vajuta `F12` → "Network" tab → refresh leht.

**Peaksid nägema päringuid (requests):**
- `http://kirjakast.cloud:8080/api/auth/login` (POST)
- `http://kirjakast.cloud:8080/api/todos` (GET)
- Response koodid: `200 OK` või `201 Created`

**Network tab'is näed:**
1. Request URL: `http://kirjakast.cloud:8080/api/...` (läbi Nginx)
2. Status: 200 või 201
3. Response Headers: `X-Forwarded-For`, `X-Real-IP` (Nginx lisab need)

#### Vaata Loge

```bash
# Nginx access logid (kõik sissetulevad päringud)
docker compose logs frontend | tail -20
# Peaksid nägema:
# GET /api/auth/login HTTP/1.1" 200
# GET /api/todos HTTP/1.1" 200

# User Service logid (proxy'd päringud)
docker compose logs user-service | tail -20
# Peaksid nägema API päringuid (requests):
# user-service  | POST /api/auth/register 201
# user-service  | POST /api/auth/login 200

# Todo Service logid (proxy'd päringud)
docker compose logs todo-service | tail -20
# todo-service  | GET /api/todos 200

# Kogu süsteemi logid
docker compose logs -f
# Vaata reaalajas, kuidas päringud liiguvad läbi Nginx → Backend
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **docker-compose.yml** fail 5 teenusega (service)
- [ ] **Frontend** käivitub ja on kättesaadav portis 8080
- [ ] **Brauserist saab:**
  - [ ] Registreerida uut kasutajat
  - [ ] Logida sisse
  - [ ] Luua todo'sid
  - [ ] Märkida todo'd completed'ks
  - [ ] Kustutada todo'sid
  - [ ] Välja logida
- [ ] **Frontend suhtleb edukalt:**
  - [ ] User Service'iga (port 3000)
  - [ ] Todo Service'iga (port 8081)
- [ ] **End-to-End workflow toimib brauserist**

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas kõik 5 teenust (services) töötavad?
docker compose ps
# Kõik peaksid olema UP ja HEALTHY

# 2. Kas frontend on kättesaadav?
curl http://localhost:8080
# Peaks tagastama HTML

# 3. Kas staatilised failid (static files) on õigesti mount'itud?
docker compose exec frontend ls /usr/share/nginx/html
# Peaks nägema: index.html, app.js, styles.css

# 4. Kas Nginx konfiguratsioon on OK?
docker compose exec frontend nginx -t
# Peaks nägema: "syntax is ok"
```

---

## 🎓 Õpitud Mõisted

### Nginx Mõisted:

- **nginx:alpine** - Kerge Nginx pilt (image) (~10MB)
- **/usr/share/nginx/html** - Nginx vaikimisi web root kataloog
- **:ro** (read-only) - Konteiner ei saa mount'itud faile muuta

### Docker Compose Volume Mount:

```yaml
volumes:
  - <host-path>:<container-path>:<options>
  - ../../apps/frontend:/usr/share/nginx/html:ro
```

**Tähendus:**
- `../../apps/frontend` - Host masina kataloog
- `/usr/share/nginx/html` - Konteineri kataloog
- `:ro` - Read-only (optional)

### Frontend-Backend Suhtlus:

```
Browser → Frontend (Nginx:8080)
  → JavaScript (app.js) teeb API calls:
    → User Service (3000) - auth, users
    → Todo Service (8081) - todos
  ← JSON vastused (responses)
← Renderdab UI
```

---

## 💡 Parimad Tavad

1. **Kasuta read-only mount'e** - Nginx ei vaja write õigusi
2. **Kasuta alpine pilte (images)** - Väiksemad, kiiremad
3. **Määra depends_on** - Frontend vajab backend'i
4. **Lisa healthcheck** - Tea, millal Nginx on valmis
5. **Eraldi frontend ja backend portid** - Selgem debug

---

## 🐛 Levinud Probleemid

### Probleem 1: "Cannot GET /"

```bash
# Kontrolli, kas failid on õigesti mount'itud
docker compose exec frontend ls /usr/share/nginx/html

# Kui tühi:
# Kontrolli volume path'i docker-compose.yml's
volumes:
  - ../../apps/frontend:/usr/share/nginx/html:ro  # Õige path?
```

### Probleem 2: "CORS error in browser console"

```bash
# User Service peaks lubama CORS'i
# Kontrolli backend-nodejs/server.js:
docker compose exec user-service cat server.js | grep cors

# Peaks nägema:
# app.use(cors());
```

### Probleem 3: "Failed to fetch API"

```bash
# Kontrolli, kas backend API'd töötavad
curl http://localhost:3000/health
curl http://localhost:8081/health

# Kontrolli browser console'i:
# - Õige URL?
# - Õige port?
```

### Probleem 4: "Port 8080 already in use"

```bash
# Vaata, mis kasutab porti 8080
sudo lsof -i :8080

# Lahendus: Muuda porti docker-compose.yml's
ports:
  - "8090:80"  # Kasuta porti 8090 host'is
```

### Probleem 5: "API calls fail - Network error" või "ERR_CONNECTION_REFUSED"

**Põhjus:** Nginx reverse proxy konfiguratsioon puudub või on valesti mount'itud.

```bash
# Kontrolli, kas nginx.conf fail on olemas
ls -la compose-project/nginx.conf

# Kui puudub:
# Loo nginx.conf fail (vaata Samm 2.5)

# Kontrolli, kas nginx.conf on mount'itud konteinerisse
docker compose exec frontend cat /etc/nginx/conf.d/default.conf

# Kui fail puudub või on tühi:
# Kontrolli docker-compose.yml volumes sektsiooni:
volumes:
  - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro  # See rida peab olemas olema!

# Taaskäivita frontend
docker compose up -d --force-recreate frontend
```

### Probleem 6: "502 Bad Gateway" API päringutele

**Põhjus:** Nginx ei saa ühendust backend teenustega (user-service või todo-service).

```bash
# Kontrolli, kas backend teenused töötavad
docker compose ps

# Peaksid nägema:
# user-service    Up (healthy)
# todo-service    Up (healthy)

# Kui mõni on unhealthy või stopped:
docker compose logs user-service
docker compose logs todo-service

# Kontrolli Nginx error loge
docker compose logs frontend | grep error

# Tüüpilised vead:
# "connect() failed (111: Connection refused) while connecting to upstream"
# → Backend teenus ei tööta, kontrolli healthcheck'i

# "no resolver defined to resolve user-service"
# → Teenused peavad olema samas network'is (todo-network)

# Lahendus: Taaskäivita kogu stack
docker compose down
docker compose up -d
```

### Probleem 7: "Login töötab, aga todo'sid ei saa luua"

**Põhjus:** JWT_SECRET ei ole sama mõlemas backend teenuses.

```bash
# Kontrolli JWT_SECRET väärtusi
docker compose exec user-service printenv | grep JWT_SECRET
docker compose exec todo-service printenv | grep JWT_SECRET

# Mõlemad peavad olema TÄPSELT SAMAD!

# Kui erinevad:
# Uuenda docker-compose.yml:
# user-service:
#   environment:
#     JWT_SECRET: sama-secret-key
# todo-service:
#   environment:
#     JWT_SECRET: sama-secret-key  # Täpselt sama!

docker compose up -d --force-recreate user-service todo-service
```

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd on sul täielik full-stack rakendus Docker Compose'iga!

**Mis edasi?**
- ✅ 5 teenust (services) töötavad
- ✅ Frontend suhtleb backend'idega
- ✅ End-to-End workflow brauserist
- ⏭️ **Järgmine:** Environment Management (.env failid)

**Jätka:** [Harjutus 3: Environment Management](03-environment-management.md)

---

## 📚 Viited

- [Nginx Docker dokumentatsioon](https://hub.docker.com/_/nginx)
- [Docker volumes](https://docs.docker.com/storage/volumes/)
- [Compose file volumes](https://docs.docker.com/compose/compose-file/05-services/#volumes)

---

**Õnnitleme! Oled lisanud Frontend teenuse edukalt! 🎉**
