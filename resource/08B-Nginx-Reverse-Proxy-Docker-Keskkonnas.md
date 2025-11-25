# 08B. Nginx Reverse Proxy Docker Keskkonnas

**Peatükk 8B: API Gateway ja Mikroteenuste Routing**

---

## 📋 Ülevaade

**Nginx reverse proxy** on üks olulisemaid mustreid mikroteenuste arhitektuuris. See toimib vahendajana (intermediary) klientide ja backend teenuste vahel, pakkudes ühte sissepääsupunkti (single entry point), turvalisust ja lihtsamat haldamist.

**Õpieesmärgid:**
- ✅ Mõista, mis on reverse proxy ja kuidas see erineb forward proxy'st
- ✅ Oskad konfigureerida Nginx'i reverse proxy'na Docker Compose keskkonnas
- ✅ Tead, kuidas lahendada CORS probleeme reverse proxy abil
- ✅ Rakendad turvalisuse parimaid praktikaid (backend'id pole avalikud)
- ✅ Oskad debuggida reverse proxy probleeme

---

## 🔄 Mis on Reverse Proxy?

### Forward Proxy vs Reverse Proxy

**Forward Proxy** (tavaliselt lihtsalt "proxy"):
- Klient teab proxy olemasolust
- Proxy esindab **klienti** server'i poole
- Kasutusjuhud: anonüümsus, firewalli'de möödumine, caching

```
[Klient] → [Forward Proxy] → [Internet] → [Server]
   ↑              ↓
Klient teab    Proxy peidab
proxy'st       kliendi IP
```

**Reverse Proxy**:
- Klient EI tea proxy olemasolust
- Proxy esindab **server'it** kliendi poole
- Kasutusjuhud: load balancing, SSL termination, security, caching

```
[Klient] → [Reverse Proxy] → [Backend Server 1]
                           → [Backend Server 2]
                           → [Backend Server 3]
   ↑              ↓
Klient arvab,  Proxy jagab
et suhtleb     koormust,
server'iga     peidab backend'e
```

### Nginx kui Reverse Proxy

**Nginx** on kõrgperformantslik veebiserver ja reverse proxy, mis on eriti populaarne:
- ✅ Kerge ja kiire (event-driven arhitektuur)
- ✅ Väike mälukasutus (väiksemad ressursid kui Apache)
- ✅ Suurepärane reverse proxy ja load balancer
- ✅ Lihtne konfigureerida
- ✅ Töötab hästi Docker'is (nginx:alpine ~10MB)

---

## 🏗️ Reverse Proxy Arhitektuur Docker Compose's

### Probleem: Ilma Reverse Proxy'ta

**Stsenaarium:** Frontend + 2 Backend teenust

```
Browser
  ├─ http://myapp.com:8080        → Frontend (HTML/CSS/JS)
  ├─ http://myapp.com:3000/api    → User Service (Auth, Users)
  └─ http://myapp.com:8081/api    → Todo Service (Todos)
```

**Probleemid:**
- ❌ **CORS vead** - Erinevad pordid = erinevad origin'id
- ❌ **Mitmed avalikud pordid** - Turvaoht (3000, 8080, 8081)
- ❌ **Keeruline frontend** - Peab teadma kõiki backend URL-e
- ❌ **Firewall reeglid** - Pead avama mitu porti
- ❌ **Keeruline deploy** - URL-id muutuvad keskkonniti

### Lahendus: Nginx Reverse Proxy

```
Browser
  ↓ http://myapp.com:8080
Nginx (Port 8080) ← AINULT AVALIK PORT
  ├─ location / → Frontend failid (HTML/CSS/JS)
  ├─ location /api/auth/ → User Service (port 3000)
  ├─ location /api/users → User Service (port 3000)
  └─ location /api/todos → Todo Service (port 8081)
```

**Eelised:**
- ✅ **Üks avalik port** (8080) - Lihtsam firewall
- ✅ **Ei ole CORS'i** - Kõik päringud sama origin'ist
- ✅ **Backend'id peidetud** - Portid 3000, 8081 pole avalikud
- ✅ **Lihtne frontend** - Ainult `/api` (relatiivne URL)
- ✅ **Keskne konfiguratsioon** - Routing ühes kohas
- ✅ **Skaleeritav** - Lihtne lisada load balancing'ut

---

## 🔧 Nginx Reverse Proxy Konfiguratsioon

### Põhiline nginx.conf Struktuur

```nginx
server {
    listen 80;                    # Kuula port 80
    server_name _;                # Aktsepteeri kõiki hostname'e

    # 1. FRONTEND - Staatilised failid
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }

    # 2. API ROUTING - Reverse Proxy
    location /api/ {
        proxy_pass http://backend:3000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Location Block'id

**`location /` - Frontend Staatilised Failid**

```nginx
location / {
    root /usr/share/nginx/html;
    index index.html;
    try_files $uri $uri/ /index.html;
}
```

**Tähendus:**
- `root` - Kus asuvad HTML/CSS/JS failid
- `index` - Default fail (index.html)
- `try_files` - Proovi faili, siis kausta, siis fallback index.html
  - Vajalik Single Page Application'itele (SPA)
  - Browser URL: `/dashboard` → server serveerib `index.html`
  - JavaScript router võtab üle ja näitab õiget lehte

**`location /api/` - API Reverse Proxy**

```nginx
location /api/auth/ {
    proxy_pass http://user-service:3000/api/auth/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

**Direktiivide selgitus:**

| Direktiiv | Tähendus | Näide |
|-----------|----------|-------|
| `proxy_pass` | Backend URL, kuhu päringu edastada | `http://user-service:3000/api/auth/` |
| `proxy_http_version 1.1` | Kasuta HTTP/1.1 (vajalik WebSocket'itele) | - |
| `proxy_set_header Host` | Säilita originaalne Host header | `Host: myapp.com` |
| `proxy_set_header X-Real-IP` | Kliendi päris IP aadress | `X-Real-IP: 192.168.1.100` |
| `proxy_set_header X-Forwarded-For` | IP chain (läbib proxy'd) | `X-Forwarded-For: 192.168.1.100` |
| `proxy_set_header X-Forwarded-Proto` | Originaalne protokoll (http/https) | `X-Forwarded-Proto: https` |

### Trailing Slash `/` Tähtsus

**⚠️ OLULINE:** Trailing slash `/` mõjutab URL-i rewrite'imist!

**Näide 1: Trailing slash olemas (RECOMMENDED)**

```nginx
location /api/ {
    proxy_pass http://backend:3000/api/;
}
```

- Brauser: `GET /api/users`
- Backend saab: `GET /api/users`
- ✅ URL säilib täpselt

**Näide 2: Trailing slash puudub**

```nginx
location /api {
    proxy_pass http://backend:3000;
}
```

- Brauser: `GET /api/users`
- Backend saab: `GET /api/users`
- ✅ URL säilib (kuna proxy_pass ka ilma `/`)

**Näide 3: Erinev trailing slash (VALE!)**

```nginx
location /api/ {
    proxy_pass http://backend:3000;  # ❌ Puudub trailing /
}
```

- Brauser: `GET /api/users`
- Backend saab: `GET /api/users` (kaasab `/api/`)
- ⚠️ Töötab, aga inconsistent

**Best Practice:**
> **Kasuta trailing slash'i mõlemas kohas või mitte kumbagi - ole konsistentne!**

---

## 🐳 Docker Compose Integratsioon

### Nginx Teenuse Definitsioon

```yaml
services:
  frontend:
    image: nginx:alpine
    container_name: frontend
    ports:
      - "8080:80"              # ✅ Ainult see port on avalik
    volumes:
      # Frontend failid (HTML/CSS/JS)
      - ../../apps/frontend:/usr/share/nginx/html:ro
      # Nginx konfiguratsioon
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - user-service
      - todo-service
    networks:
      - frontend-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://127.0.0.1"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s

  user-service:
    image: user-service:1.0
    # ❌ POLE ports: sektsiooni - EI OLE AVALIK
    networks:
      - frontend-network
      - backend-network

  todo-service:
    image: todo-service:1.0
    # ❌ POLE ports: sektsiooni - EI OLE AVALIK
    networks:
      - frontend-network
      - backend-network
```

**Võrgud (Networks):**

```yaml
networks:
  frontend-network:  # Nginx ↔ Backend'id
  backend-network:   # Backend'id ↔ Database
```

**Arhitektuur:**

```
┌─────────────────────────────────────────┐
│          INTERNET (Avalik)              │
└─────────────────┬───────────────────────┘
                  │
                  ↓ Port 8080
          ┌───────────────┐
          │     Nginx     │  ← AINULT SEE ON AVALIK
          │ (frontend)    │
          └───────┬───────┘
                  │ frontend-network
        ┌─────────┴─────────┐
        ↓                   ↓
┌───────────────┐   ┌───────────────┐
│ user-service  │   │ todo-service  │
│ (port 3000)   │   │ (port 8081)   │
└───────┬───────┘   └───────┬───────┘
        │ backend-network   │
        └─────────┬─────────┘
                  ↓
          ┌───────────────┐
          │   PostgreSQL  │
          └───────────────┘
```

### Volume Mount'id

**Frontend failid:**
```yaml
volumes:
  - ../../apps/frontend:/usr/share/nginx/html:ro
```

- `:ro` = **read-only** (best practice)
- Nginx ei vaja write õigusi staatiliste failide jaoks

**Nginx konfiguratsioon:**
```yaml
volumes:
  - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

- `/etc/nginx/conf.d/default.conf` - Nginx'i default server block
- `:ro` = read-only (turvaline)

---

## 🌐 CORS Probleemide Lahendamine

### Mis on CORS?

**CORS (Cross-Origin Resource Sharing)** - Browser'i turvafunktsioon, mis piirab erinevate origin'ite vahelisi päringuid.

**Origin** koosneb: `protocol://hostname:port`

| URL | Origin | Kas sama origin? |
|-----|--------|------------------|
| `http://myapp.com:8080/index.html` | `http://myapp.com:8080` | ✅ Sama |
| `http://myapp.com:8080/api/users` | `http://myapp.com:8080` | ✅ Sama |
| `http://myapp.com:3000/api/users` | `http://myapp.com:3000` | ❌ Erinev port |
| `https://myapp.com:8080/api` | `https://myapp.com:8080` | ❌ Erinev protokoll |

### CORS Viga Ilma Reverse Proxy'ta

**Frontend (port 8080):**
```javascript
fetch('http://myapp.com:3000/api/users')  // ❌ Erinev origin
  .then(res => res.json())
```

**Browser console:**
```
Access to fetch at 'http://myapp.com:3000/api/users' from origin
'http://myapp.com:8080' has been blocked by CORS policy:
No 'Access-Control-Allow-Origin' header is present.
```

**Lahendus 1: CORS header'id Backend'is (❌ EI OLE BEST PRACTICE)**

```javascript
// user-service (Node.js)
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');  // ⚠️ Ohtlik
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  next();
});
```

**Probleemid:**
- ❌ Backend peab teadma CORS'ist
- ❌ `*` wildcard on turvaoht (lubab kõik)
- ❌ Keeruline mitme backend'iga
- ❌ Raskesti hallatav

**Lahendus 2: Reverse Proxy (✅ BEST PRACTICE)**

```nginx
# Nginx
location /api/ {
    proxy_pass http://user-service:3000/api/;
}
```

**Frontend:**
```javascript
fetch('/api/users')  // ✅ Sama origin (relatiivne URL)
  .then(res => res.json())
```

**Miks see töötab:**
- ✅ Frontend ja API on **sama origin'ist** (`http://myapp.com:8080`)
- ✅ Browser ei näe erinevaid porte (Nginx proxy'b)
- ✅ Backend ei pea teadma CORS'ist
- ✅ Lihtne ja turvaline

---

## 🔒 Turvalisuse Aspektid

### Backend'id Pole Avalikud

**Production seadistus:**

```yaml
services:
  frontend:
    ports:
      - "8080:80"  # ✅ Avalik

  user-service:
    # ❌ POLE ports: sektsiooni
    # Kättesaadav AINULT Docker võrgus
```

**Tulemus:**
```bash
# Väliselt (internet):
curl http://myapp.com:8080          # ✅ Frontend töötab
curl http://myapp.com:3000          # ❌ Connection refused
curl http://myapp.com:8081          # ❌ Connection refused

# Docker võrgus (konteinerite vahel):
docker exec frontend curl http://user-service:3000/health  # ✅ Töötab
```

### Defense in Depth

**Turvakihtid:**

```
┌─────────────────────────────────────────┐
│ 1. Firewall (VPS level)                │  ← Blokeeri 3000, 8081
├─────────────────────────────────────────┤
│ 2. Docker Port Binding                 │  ← Pole porte backend'itel
├─────────────────────────────────────────┤
│ 3. Nginx Reverse Proxy                 │  ← API routing, filtering
├─────────────────────────────────────────┤
│ 4. Authentication (JWT tokens)         │  ← Backend level auth
└─────────────────────────────────────────┘
```

### Rate Limiting

```nginx
# Piira päringute arvu (DDoS kaitse)
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

server {
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://backend:3000/api/;
    }
}
```

**Tähendus:**
- Max 10 päringut sekundis IP kohta
- `burst=20` - Lubab lühiajalisi tippkoormusi (burst)
- `nodelay` - Ei hoia päringuid järjekorras

### IP Filtering

```nginx
# Luba ainult teatud IP'd (admin endpoints)
location /api/admin/ {
    allow 192.168.1.0/24;  # Lubatud subnet
    deny all;              # Bloki kõik teised

    proxy_pass http://backend:3000/api/admin/;
}
```

---

## 🎯 Praktiline Näide: Mikroteenuste Stack

### Arhitektuur

```
Browser
  ↓ http://myapp.com
Nginx (Port 80)
  ├─ / → Frontend (React SPA)
  ├─ /api/auth/* → Auth Service (port 3001)
  ├─ /api/users/* → User Service (port 3002)
  ├─ /api/products/* → Product Service (port 3003)
  └─ /api/orders/* → Order Service (port 3004)
```

### nginx.conf

```nginx
server {
    listen 80;
    server_name myapp.com;

    # Frontend (React)
    location / {
        root /usr/share/nginx/html;
        try_files $uri /index.html;  # SPA routing
    }

    # Auth Service
    location /api/auth/ {
        proxy_pass http://auth-service:3001/api/auth/;
        include /etc/nginx/proxy_params;
    }

    # User Service
    location /api/users/ {
        proxy_pass http://user-service:3002/api/users/;
        include /etc/nginx/proxy_params;
    }

    # Product Service
    location /api/products/ {
        proxy_pass http://product-service:3003/api/products/;
        include /etc/nginx/proxy_params;
    }

    # Order Service
    location /api/orders/ {
        proxy_pass http://order-service:3004/api/orders/;
        include /etc/nginx/proxy_params;
    }
}
```

### Proxy Params (DRY Principle)

**proxy_params fail:**

```nginx
# /etc/nginx/proxy_params
proxy_http_version 1.1;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Port $server_port;

# WebSocket support
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";

# Timeouts
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
```

**Kasutamine:**

```nginx
location /api/auth/ {
    include /etc/nginx/proxy_params;  # ✅ DRY
    proxy_pass http://auth-service:3001/api/auth/;
}
```

---

## 🐛 Levinud Probleemid ja Lahendused

### Probleem 1: 502 Bad Gateway

**Sümptom:**
```
Browser: 502 Bad Gateway
Nginx logs: connect() failed (111: Connection refused) while connecting to upstream
```

**Põhjus:**
- Backend teenus ei tööta
- Vale hostname/port `proxy_pass` direktiivis
- Backend ei ole võrgus (network), kus Nginx asub

**Lahendus:**

```bash
# Kontrolli backend'i staatust
docker compose ps

# Kontrolli võrku
docker network inspect frontend-network

# Vaata backend loge
docker compose logs user-service

# Testi ühenduvust Nginx konteinerist
docker exec frontend curl http://user-service:3000/health
```

### Probleem 2: 404 Not Found API Päringutele

**Sümptom:**
```
GET /api/users → 404 Not Found
Backend töötab, aga Nginx ei leia
```

**Põhjus:**
- Location block ei matchi päringuga
- Trailing slash probleem

**Lahendus:**

```nginx
# ❌ Vale - ei matchi /api/users
location /api/ {
    proxy_pass http://backend:3000/;
}

# ✅ Õige - matchi /api/*
location /api/ {
    proxy_pass http://backend:3000/api/;
}

# või

location ~ ^/api/ {  # Regex matching
    proxy_pass http://backend:3000$request_uri;
}
```

### Probleem 3: CORS Vead Hoolimata Reverse Proxy'st

**Sümptom:**
```
Frontend: CORS error
Aga kasutan reverse proxy'd!
```

**Põhjus:**
- Frontend teeb päringuid ABSOLUUTSE URL-iga

**Vale frontend kood:**
```javascript
// ❌ VALE - Absoluutne URL (erinev origin)
fetch('http://myapp.com:3000/api/users')
```

**Õige frontend kood:**
```javascript
// ✅ ÕIGE - Relatiivne URL (sama origin)
fetch('/api/users')
```

### Probleem 4: Backend Saab Vale Host Header

**Sümptom:**
```
Backend: "Invalid host header"
Backend ei töötle päringut
```

**Põhjus:**
- Puudub `proxy_set_header Host`

**Lahendus:**

```nginx
location /api/ {
    proxy_pass http://backend:3000/api/;
    proxy_set_header Host $host;  # ✅ Säilita originaalne Host
}
```

### Probleem 5: Aeglased API Päringud

**Sümptom:**
```
API vastused aeglased
Timeout'id
```

**Põhjus:**
- Vaikimisi timeout'id liiga lühikesed
- DNS resolution aeglane

**Lahendus:**

```nginx
location /api/ {
    proxy_pass http://backend:3000/api/;

    # Suurenda timeout'e
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;

    # Buffering (parandab performance'i)
    proxy_buffering on;
    proxy_buffer_size 4k;
    proxy_buffers 8 4k;
}
```

---

## 💡 Parimad Tavad

### 1. Kasuta Read-Only Mount'e

```yaml
volumes:
  - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro  # ✅ :ro
```

### 2. Ei Avalda Backend Porte

```yaml
# ✅ Õige
user-service:
  # POLE ports: sektsiooni

# ❌ Vale
user-service:
  ports:
    - "3000:3000"  # Backend pole vaja avalikustada
```

### 3. Kasuta Healthcheck'e

```yaml
healthcheck:
  test: ["CMD", "wget", "--spider", "http://127.0.0.1"]
  interval: 30s
  timeout: 3s
  retries: 3
```

### 4. Logi API Päringuid

```nginx
# Custom access log formaat
log_format api_log '$remote_addr - $remote_user [$time_local] '
                   '"$request" $status $body_bytes_sent '
                   '"$http_referer" "$http_user_agent" '
                   'upstream: $upstream_addr';

server {
    access_log /var/log/nginx/api_access.log api_log;

    location /api/ {
        proxy_pass http://backend:3000/api/;
    }
}
```

### 5. Valideeri Nginx Konfiguratsiooni

```bash
# Test syntax'it ENNE restart'i
docker exec frontend nginx -t

# Reload ilma downtime'ita
docker exec frontend nginx -s reload
```

### 6. Kasuta DRY Printsiipi

```nginx
# ❌ Vale - Kordamine
location /api/auth/ {
    proxy_pass http://auth:3001/api/auth/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    # ... 10 rida
}

location /api/users/ {
    proxy_pass http://users:3002/api/users/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    # ... 10 rida (DUPLICATION!)
}

# ✅ Õige - Include proxy params
include /etc/nginx/proxy_params;

location /api/auth/ {
    include /etc/nginx/proxy_params;
    proxy_pass http://auth:3001/api/auth/;
}
```

---

## 📊 Performance Optimeerimised

### Caching

```nginx
# API responses cache
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=1g inactive=60m;

location /api/products/ {
    proxy_cache api_cache;
    proxy_cache_valid 200 10m;       # Cache 200 responses 10 minutit
    proxy_cache_valid 404 1m;        # Cache 404 responses 1 minut
    proxy_cache_use_stale error timeout updating;

    add_header X-Cache-Status $upstream_cache_status;  # Debug

    proxy_pass http://product-service:3003/api/products/;
}
```

### Gzip Compression

```nginx
# Kompresseeri responses
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml application/json application/javascript;
```

### Connection Pooling

```nginx
upstream backend_pool {
    server user-service:3000 max_fails=3 fail_timeout=30s;
    keepalive 32;  # Hoia 32 ühendust elus
}

location /api/users/ {
    proxy_pass http://backend_pool/api/users/;
    proxy_http_version 1.1;
    proxy_set_header Connection "";  # Keep-alive
}
```

---

## 🎓 Kokkuvõte

### Mida Õppisime

1. **Reverse Proxy põhimõte:**
   - Vahendaja kliendi ja backend'i vahel
   - Peidab backend'e, pakub ühte sissepääsupunkti

2. **Nginx Docker Compose's:**
   - Nginx kui frontend konteiner
   - Backend'id pole avalikud (pole porte)
   - Volume mount'id nginx.conf jaoks

3. **CORS lahendamine:**
   - Reverse proxy lahendab CORS probleemid
   - Frontend kasutab relatiivset URL-i (`/api`)

4. **Turvalisus:**
   - Ainult Nginx on avalik
   - Backend'id Docker võrgus
   - Defense in depth

5. **Best practices:**
   - Read-only mount'id
   - Healthcheck'id
   - Logging ja monitoring
   - DRY printsiip

### Järgmised Sammud

- **Lab 2, Exercise 2:** Rakenda Nginx reverse proxy praktikas
- **Lab 3:** Kubernetes Ingress (sarnane kontseptsioon)
- **Lab 4:** Load balancing mitme backend replica'ga

---

## 📚 Viited ja Edasine Lugemine

### Ametlik Dokumentatsioon
- [Nginx Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Nginx Docker Image](https://hub.docker.com/_/nginx)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)

### Best Practices
- [Nginx Security Hardening](https://www.nginx.com/blog/mitigating-ddos-attacks-with-nginx-and-nginx-plus/)
- [Nginx Performance Tuning](https://www.nginx.com/blog/tuning-nginx/)
- [12-Factor App: Port Binding](https://12factor.net/port-binding)

### Sarnased Tehnoloogiad
- **Traefik** - Modern reverse proxy Docker'ile
- **HAProxy** - High-performance load balancer
- **Envoy** - Service mesh proxy (Kubernetes)
- **Kubernetes Ingress** - K8s native reverse proxy

---

**Viimane uuendus:** 2025-01-25
**Seos laboritega:** Lab 2 Exercise 2 (Frontend + Nginx), Lab 3 (Kubernetes Ingress)
**Eelmine peatükk:** [08A-Docker-Compose-Production-Development-Seadistused.md](08A-Docker-Compose-Production-Development-Seadistused.md)
**Järgmine peatükk:** 09-PostgreSQL-Konteinerites.md
