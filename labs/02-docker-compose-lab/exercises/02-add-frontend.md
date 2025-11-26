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

### Teenuste URL-id

**SSH Sessioonis (VPS sees):**
- Kõik `curl http://localhost:...` käsud töötavad

**Brauserist (oma arvutist):**

| Õpilane | Frontend | User Service API | Todo Service API |
|---------|----------|------------------|------------------|
| student1 | http://93.127.213.242:8080 | http://93.127.213.242:3000 | http://93.127.213.242:8081 |
| student2 | http://93.127.213.242:8180 | http://93.127.213.242:3100 | http://93.127.213.242:8181 |
| student3 | http://93.127.213.242:8280 | http://93.127.213.242:3200 | http://93.127.213.242:8281 |

### Kus kasutada millist URL-i?

- ✅ **SSH sessioonis (VPS sees):** `curl http://localhost:3000/health`
- ✅ **Brauseris (oma arvutist):** `http://93.127.213.242:3000/health`
- ✅ **Docker konteinerite vahel:** Service nimed (`http://user-service:3000`, Docker võrgus)

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
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://127.0.0.1"]
      interval: 30s
      timeout: 3s
      retries: 3
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 2.5: Lisa Nginx Reverse Proxy Konfiguratsioon (10 min)

**Miks see on vajalik?**

Frontend JavaScript teeb API päringuid relatiivse URL-iga `/api`, aga backend teenused töötavad erinevatel portidel. **Nginx peab proxy-ma API päringud õigetesse portidesse.**

**📚 Põhjalik teooria:**
👉 **Loe põhjalikku selgitust:** [Peatükk 08B: Nginx Reverse Proxy Docker Keskkonnas](../../../resource/08B-Nginx-Reverse-Proxy-Docker-Keskkonnas.md)

**See peatükk käsitleb:**
- ✅ Reverse proxy kontseptsioon (forward vs reverse)
- ✅ Kuidas lahendada CORS probleeme
- ✅ Turvalisuse aspektid (backend'id peidetud)
- ✅ proxy_pass direktiiv ja header'id
- ✅ Troubleshooting ja best practices

---

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

### 🎓 Reverse Proxy Töö Sinu Keskkonnas

**OLULINE:** Ülal olev nginx.conf konfiguratsioon töötab **täpselt ühtemoodi** kõigile kolmele kasutajale (student1, student2, student3).

#### Kuidas See Töötab?

**1. Docker võrgus (container to container):**
```nginx
proxy_pass http://user-service:3000/api/auth/;
proxy_pass http://todo-service:8081/api/todos;
```
- Nginx kasutab **Docker service nimesid** (`user-service`, `todo-service`)
- See on võrgu sisene suhtlus Docker'i `todo-network` võrgus
- **Sama kõigile kasutajatele** - service nimed on identsed

**2. Brauseri päringud:**

Sinu brauserist tuleb päring vastavalt sinu kasutajale:

| Kasutaja | Brauseri URL | LXD Port Mapping | Jõuab Nginx'ni |
|----------|--------------|------------------|----------------|
| student1 | `http://93.127.213.242:8080/api/auth/login` | Host:8080 → Container:80 | ✅ Port 80 |
| student2 | `http://93.127.213.242:8180/api/auth/login` | Host:8180 → Container:80 | ✅ Port 80 |
| student3 | `http://93.127.213.242:8280/api/auth/login` | Host:8280 → Container:80 | ✅ Port 80 |

**3. Mis juhtub sammhaaval (student1 näitel):**

```
1. Brauseris sisestada: http://93.127.213.242:8080/api/auth/login
                           ↓
2. LXD port mapping: Host port 8080 → devops-student1 konteiner port 8080
                           ↓
3. Docker port mapping: Host port 8080 → frontend konteiner port 80
                           ↓
4. Nginx (frontend konteiner) saab: GET /api/auth/login
                           ↓
5. Nginx proxy_pass reegel: location /api/auth/ → http://user-service:3000
                           ↓
6. user-service konteiner vastab: 200 OK + JWT token
                           ↓
7. Vastus tagasi läbi sama tee: user-service → Nginx → Docker → LXD → Brauser
```

#### Miks See Töötab Kõigile Ühtemoodi?

✅ **nginx.conf konfiguratsioon on identne** - kasutab Docker service nimesid
✅ **LXD port mapping** eristab kasutajaid (8080/8180/8280)
✅ **Docker võrk siseselt** on sama kõigile (todo-network)

**Järeldus:** Sa ei pea nginx.conf faili muutma oma kasutaja järgi! LXD port mapping teeb eristamise sinu eest.

---

### Samm 3: Mõista Frontend Konfiguratsiooni (3 min)

**Analüüsi olulisemad osad docker-compose.yml'ist:**

#### `image: nginx:alpine`
- Kerge Nginx pilt (~10MB)

#### `volumes:`
```yaml
- ../../apps/frontend:/usr/share/nginx/html:ro    # Frontend failid (HTML/CSS/JS)
- ./nginx.conf:/etc/nginx/conf.d/default.conf:ro  # Nginx konfiguratsioon
```
- `:ro` = read-only (turvalisus)

#### `ports: - "8080:80"`
- Ainult port 8080 on avalik
- Backend portid (3000, 8081) pole avalikud → Turvalisem

**Nginx teeb kaks asja:**
1. Serveerib frontend faile (`location /`)
2. Proxy'b API päringud backend'itele (`location /api/`)

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

**Brauseris (oma arvutist):**

Ava üks järgnevatest URL-idest vastavalt oma kasutajale (vaata "Sinu Testimise Konfiguratsioon" sektsiooni üleval):

- **student1:** `http://93.127.213.242:8080`
- **student2:** `http://93.127.213.242:8180`
- **student3:** `http://93.127.213.242:8280`

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
