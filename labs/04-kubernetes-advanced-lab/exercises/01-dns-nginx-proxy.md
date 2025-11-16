# Harjutus 01: DNS + Nginx Reverse Proxy

**Kestus:** 90 minutit
**Tee:** Path A (Algaja)
**Eesmärk:** Seadistada DNS A-kirje ning Nginx reverse proxy, et suunata liiklust domeenist mikroteenustele

---

## 📋 Ülevaade

Selles harjutuses õpid traditsioonilist viisi, kuidas suunata liiklust domeenist (nt `kirjakast.cloud`) oma VPS serveris töötavatele mikroteenustele. See on ajalooliselt levinud lähenemine, mida kasutatakse siiani paljudes väiksemates ja keskmise suurusega projektides.

**Arhitektuur, mida loome:**

```
Internet
    ↓
DNS A-kirje: kirjakast.cloud → 93.127.213.242 (VPS IP)
    ↓
VPS Server (kirjakast) - Port 80
    ↓
Nginx Reverse Proxy
    ↓
    ├─→ /                → Frontend (Docker port 8080)
    ├─→ /todo            → Frontend (Docker port 8080)
    ├─→ /api/todos       → Todo Service (Docker port 8081)
    ├─→ /api/users       → User Service (Docker port 3000)
    ├─→ /api/auth        → User Service (Docker port 3000)
    └─→ /health/*        → Health endpoints
```

---

## 🎯 Õpieesmärgid

Selle harjutuse lõpuks sa:

- ✅ Mõistad DNS A-kirje rolli domeeni IP aadressile suunamisel
- ✅ Oskad paigaldada ja seadistada Nginx reverse proxy'd
- ✅ Mõistad virtual hosts (server blocks) kontseptsiooni
- ✅ Oskad defineerida upstream servereid Nginx'is
- ✅ Oskad seadistada path-based routing'ut
- ✅ Tead kuidas proxy header'eid edastada backend teenustele
- ✅ Oskad testida ja debugida Nginx konfiguratsiooni

---

## 📚 Teoreetiline Taust

### Mis on DNS A-kirje?

DNS A-kirje (Address Record) on DNS-i kirje tüüp, mis seob domeeni nime IPv4 aadressiga.

```
kirjakast.cloud.  3600  IN  A  93.127.213.242
     ↑             ↑    ↑   ↑        ↑
  domeen          TTL  klass tüüp   IP aadress
```

### Mis on Reverse Proxy?

**Forward proxy** vahendab klientide päringuid välistele serveritele (nt VPN).
**Reverse proxy** vahendab väliste klientide päringuid sisemistele serveritele.

```
Forward Proxy:
Klient → Proxy → Internet (klient on kaitstud)

Reverse Proxy:
Internet → Proxy → Serverid (serverid on kaitstud)
```

### Nginx kui Reverse Proxy

Nginx on kõrge jõudlusega veebiserver ja reverse proxy. Selle tugevused:
- Madal mälu kasutus
- Suur võime paralleelselt päringuid käsitleda
- Lihtne konfiguratsioon
- Load balancing
- Caching
- SSL termination

---

## 🔧 Eeltingimused

### 1. Kontrolli VPS juurdepääsu

```bash
ssh janek@kirjakast
# või
ssh janek@93.127.213.242
```

### 2. Kontrolli kas Nginx on paigaldatud

```bash
nginx -v
```

**Oodatav väljund:**
```
nginx version: nginx/1.24.0 (Ubuntu)
```

Kui Nginx pole paigaldatud:
```bash
sudo apt update
sudo apt install -y nginx
```

### 3. Kontrolli Docker Compose stack'i

```bash
cd /home/janek/projects/hostinger/labs/apps
docker compose ps
```

**Oodatav väljund:** 5 teenust (STATUS: Up (healthy))
```
NAME              IMAGE              STATUS
frontend          nginx:alpine       Up (healthy)
postgres-todo     postgres:16-alpine Up (healthy)
postgres-user     postgres:16-alpine Up (healthy)
todo-service      ...                Up (healthy)
user-service      ...                Up (healthy)
```

Kui teenused ei tööta:
```bash
docker compose up -d
```

---

## 📝 Samm 1: DNS A-kirje Seadistamine

### 1.1 Kontrolli oma VPS IP aadressi

```bash
# Kontrolli avalikku IP aadressi
ip addr show
# või
curl ifconfig.me
```

**Sinu VPS IP:** `93.127.213.242`

### 1.2 Loo DNS A-kirje

Mine oma domeeni registraatori/DNS pakkuja juhtpaneeli (nt Hostinger, Cloudflare, GoDaddy).

**Lisa järgmine A-kirje:**

| Tüüp | Nimi | Väärtus | TTL |
|------|------|---------|-----|
| A | @ | 93.127.213.242 | 3600 |
| A | www | 93.127.213.242 | 3600 |

**Selgitus:**
- `@` - root domeen (kirjakast.cloud)
- `www` - www subdomain (www.kirjakast.cloud)
- `93.127.213.242` - sinu VPS IP
- `3600` - TTL sekundites (1 tund)

### 1.3 Oota DNS levikut

DNS muudatused võivad võtta **5-60 minutit**. Seni saad jätkata Nginx seadistamisega.

### 1.4 Kontrolli DNS levikut

```bash
# Kontrolli kas DNS on värskendatud
dig kirjakast.cloud

# Lihtsam variant
nslookup kirjakast.cloud
```

**Oodatav väljund:**
```
kirjakast.cloud.        3600    IN      A       93.127.213.242
```

**Vihje:** Kui sa näed vana IP'd, oota veel 10-15 minutit ja proovi uuesti.

---

## 📝 Samm 2: Nginx Virtual Host Seadistamine

### 2.1 Mõista Nginx kataloogistruktuuri

```
/etc/nginx/
├── nginx.conf                    # Põhikonfiguratsioon
├── sites-available/              # Kõik saadaolevad virtual hostid
│   ├── default                   # Vaikimisi konfiguratsioon
│   └── kirjakast.cloud          # Sinu kohandatud konfiguratsioon
└── sites-enabled/                # Aktiivsed virtual hostid (symlink'id)
    └── kirjakast.cloud -> ../sites-available/kirjakast.cloud
```

### 2.2 Loo Nginx konfiguratsioonifail

```bash
sudo vim /etc/nginx/sites-available/kirjakast.cloud
```

**Lisa järgmine konfiguratsioon:**

```nginx
# ==========================================================================
# Nginx Reverse Proxy - kirjakast.cloud
# ==========================================================================
# Suunab liiklust domeenist kirjakast.cloud Docker Compose teenustele
# ==========================================================================

# Defini upstream serverid (backend teenused)
upstream frontend {
    server localhost:8080;
}

upstream user-service {
    server localhost:3000;
}

upstream todo-service {
    server localhost:8081;
}

# HTTP Server Block
server {
    listen 80;
    listen [::]:80;

    server_name kirjakast.cloud www.kirjakast.cloud;

    # Logging
    access_log /var/log/nginx/kirjakast.cloud-access.log;
    error_log /var/log/nginx/kirjakast.cloud-error.log;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # ======================================================================
    # API Routes - Backend Services
    # ======================================================================

    # Todo Service API
    location /api/todos {
        proxy_pass http://todo-service;

        # Proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # User Service API - Users
    location /api/users {
        proxy_pass http://user-service;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # User Service API - Authentication
    location /api/auth {
        proxy_pass http://user-service;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # ======================================================================
    # Health Check Routes
    # ======================================================================

    location /health/user {
        proxy_pass http://user-service/health;
        access_log off;
    }

    location /health/todo {
        proxy_pass http://todo-service/health;
        access_log off;
    }

    # ======================================================================
    # Frontend Routes
    # ======================================================================

    # Todo page
    location /todo {
        proxy_pass http://frontend/;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Root - Frontend
    location / {
        proxy_pass http://frontend;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Cache static files
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
            proxy_pass http://frontend;
            expires 7d;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### 2.3 Mõista konfiguratsiooni

**Upstream Blocks:**
```nginx
upstream frontend {
    server localhost:8080;
}
```
Definerib backend serveri rühma. Siin on ainult üks server, kuid tootmises võib olla mitu (load balancing).

**Server Block:**
```nginx
server {
    listen 80;
    server_name kirjakast.cloud www.kirjakast.cloud;
    ...
}
```
Vastutab päringute vastuvõtmise eest portil 80 ja suunab need vastavalt location reeglistele.

**Location Blocks:**
```nginx
location /api/todos {
    proxy_pass http://todo-service;
    ...
}
```
Path-based routing: kui URL algab `/api/todos`, suuna `todo-service` upstream'ile.

**Proxy Headers:**
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
```
Edastab originaalse kliendi info backend teenusele (muidu näeb backend Nginx IP'd).

---

## 📝 Samm 3: Aktiveeri Konfiguratsioon

### 3.1 Testi konfiguratsiooni süntaksit

```bash
sudo nginx -t
```

**Oodatav väljund:**
```
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

**Kui on vigu:**
- Kontrolli faili süntaksit (puuduvad semikoolonid, vale asukoht, jne)
- Vaata täpset veateadet

### 3.2 Loo symlink sites-enabled kataloogi

```bash
sudo ln -s /etc/nginx/sites-available/kirjakast.cloud /etc/nginx/sites-enabled/
```

### 3.3 Keela vaikimisi konfiguratsioon (valikuline)

```bash
sudo rm /etc/nginx/sites-enabled/default
```

### 3.4 Taaslae Nginx konfiguratsioon

```bash
sudo systemctl reload nginx
```

**Või restardi teenus:**
```bash
sudo systemctl restart nginx
```

### 3.5 Kontrolli Nginx staatust

```bash
sudo systemctl status nginx
```

**Oodatav väljund:**
```
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded
     Active: active (running)
```

---

## 📝 Samm 4: Testimine

### 4.1 Testi localhost'ist

```bash
# Testi frontend'i
curl -I http://localhost/

# Testi todo API
curl http://localhost/api/todos

# Testi user API
curl http://localhost/api/users

# Testi health check'e
curl http://localhost/health/user
curl http://localhost/health/todo
```

### 4.2 Testi domeenist

Kui DNS on levinud (kontrolli `dig kirjakast.cloud`):

```bash
# Frontend
curl -I http://kirjakast.cloud/

# Todo page
curl -I http://kirjakast.cloud/todo

# API endpoints
curl http://kirjakast.cloud/api/todos
curl http://kirjakast.cloud/api/users
curl http://kirjakast.cloud/health/user
```

### 4.3 Testi brauserist

Ava brauser ja külasta:

1. `http://kirjakast.cloud` - Peaks näitama frontend'i
2. `http://kirjakast.cloud/todo` - Peaks näitama todo rakendust
3. `http://kirjakast.cloud/api/users` - Peaks tagastama JSON (võib olla tühi list)

### 4.4 Testi täielik workflow

**Registreeru kasutaja:**
```bash
curl -X POST http://kirjakast.cloud/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "test123"
  }'
```

**Logi sisse:**
```bash
curl -X POST http://kirjakast.cloud/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123"
  }' | tee /tmp/login-response.json
```

**Ekstrakti JWT token:**
```bash
TOKEN=$(cat /tmp/login-response.json | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo $TOKEN > /tmp/token.txt
echo "Token salvestatud: /tmp/token.txt"
```

**Loo todo:**
```bash
curl -X POST http://kirjakast.cloud/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(cat /tmp/token.txt)" \
  -d '{
    "title": "Õpi Nginx reverse proxy",
    "description": "Seadista DNS ja Nginx",
    "priority": "high"
  }'
```

**Loe todos:**
```bash
curl http://kirjakast.cloud/api/todos \
  -H "Authorization: Bearer $(cat /tmp/token.txt)"
```

---

## 📝 Samm 5: Nginx Logide Vaatamine

### 5.1 Vaata access log'i

```bash
sudo tail -f /var/log/nginx/kirjakast.cloud-access.log
```

**Oodatav formaat:**
```
93.127.213.242 - - [16/Nov/2025:10:30:15 +0000] "GET /api/todos HTTP/1.1" 200 1234 "-" "curl/7.81.0"
```

### 5.2 Vaata error log'i

```bash
sudo tail -f /var/log/nginx/kirjakast.cloud-error.log
```

**Kui on vigu:**
- `502 Bad Gateway` - Backend teenus ei vasta (kontrolli `docker compose ps`)
- `504 Gateway Timeout` - Backend teenus aeglane (suurenda timeout'e)
- `404 Not Found` - Vale path (kontrolli location blokke)

---

## 🐛 Troubleshooting

### Probleem 1: DNS ei tööta

**Sümptomid:**
```bash
dig kirjakast.cloud
# Tagastab vale IP või ei leia kirjet
```

**Lahendus:**
1. Kontrolli DNS pakkuja juhtpaneeli (kas kirje on salvestatud?)
2. Oota 10-60 minutit (DNS propagatsioon)
3. Puhasta kohalik DNS cache: `sudo systemd-resolve --flush-caches`
4. Kasuta teist DNS serverit testimiseks: `dig @8.8.8.8 kirjakast.cloud`

### Probleem 2: Nginx annab 502 Bad Gateway

**Sümptomid:**
```
curl http://kirjakast.cloud/api/todos
<html>
<head><title>502 Bad Gateway</title></head>
...
```

**Lahendus:**
```bash
# 1. Kontrolli kas backend teenused töötavad
docker compose ps

# 2. Kontrolli kas portid on õiged
docker compose ps | grep -E "3000|8080|8081"

# 3. Testi otse backend'i
curl http://localhost:3000/health
curl http://localhost:8081/health

# 4. Vaata Nginx error logi
sudo tail -20 /var/log/nginx/kirjakast.cloud-error.log

# 5. Vaata backend logisid
docker compose logs user-service
docker compose logs todo-service
```

### Probleem 3: Nginx konfiguratsioon ei laadi

**Sümptomid:**
```bash
sudo nginx -t
# Syntax error
```

**Lahendus:**
1. Kontrolli semikoolonide olemasolu iga direktiivi lõpus
2. Kontrolli aaltulgude paare `{ }`
3. Kontrolli stringide jutumärke
4. Kasuta `nginx -t` täpse vea asukoha leidmiseks

### Probleem 4: CORS vead brauseris

**Sümptomid:**
Browser console:
```
Access to fetch at 'http://kirjakast.cloud/api/todos' from origin 'http://localhost:8080'
has been blocked by CORS policy
```

**Lahendus:**
Lisa Nginx konfiguratsiooni location blokkidesse:
```nginx
location /api/todos {
    # CORS headers
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;

    # Handle preflight
    if ($request_method = 'OPTIONS') {
        return 204;
    }

    proxy_pass http://todo-service;
    ...
}
```

---

## ✅ Valideerimise Checklist

Märgi ära kui oled täitnud:

- [ ] DNS A-kirje loodud ja levinud (`dig kirjakast.cloud` näitab VPS IP'd)
- [ ] Nginx on paigaldatud ja töötab (`systemctl status nginx`)
- [ ] Virtual host konfiguratsioon loodud (`/etc/nginx/sites-available/kirjakast.cloud`)
- [ ] Konfiguratsioon aktiveeritud (`sites-enabled/kirjakast.cloud` symlink)
- [ ] Nginx konfiguratsioon kehtiv (`nginx -t` edukalt)
- [ ] Nginx on restaritud (`systemctl reload nginx`)
- [ ] Frontend kättesaadav: `http://kirjakast.cloud` annab HTTP 200
- [ ] Todo page kättesaadav: `http://kirjakast.cloud/todo` annab HTTP 200
- [ ] Todo API kättesaadav: `http://kirjakast.cloud/api/todos` annab JSON vastuse
- [ ] User API kättesaadav: `http://kirjakast.cloud/api/users` annab JSON vastuse
- [ ] Health check'id töötavad: `/health/user` ja `/health/todo`
- [ ] Täielik workflow tehtud: registreerimine → login → JWT token → todo loomine
- [ ] Logid töötavad: näed päringuid `access.log` failis

---

## 🎓 Mida Sa Õppisid?

Selle harjutuse käigus õppisid:

### DNS Kontseptsioonid
- ✅ Kuidas DNS A-kirjed suunavad domeeni IP aadressile
- ✅ DNS TTL mõiste ja leviku aeg
- ✅ DNS debugging tööriistad (`dig`, `nslookup`)

### Nginx Reverse Proxy
- ✅ Virtual hosts (server blocks) seadistamine
- ✅ Upstream serverite defineerimine
- ✅ Path-based routing (`location` direktiivid)
- ✅ Proxy header'ite edastamine
- ✅ Timeout'ide konfiguratsioon
- ✅ Static file'ide caching

### Tootmise Praktikad
- ✅ Konfiguratsioonifailide struktuur sites-available/sites-enabled
- ✅ Nginx konfiguratsiooni testimine (`nginx -t`)
- ✅ Logide monitoorimine ja analüüsimine
- ✅ Troubleshooting tehnikad (502, 504 vead)
- ✅ Security header'id (X-Frame-Options, X-Content-Type-Options)

### Mikroteenuste Routing
- ✅ Ühe domeeni suunamine mitmele teenusele
- ✅ API vs frontend routing
- ✅ Health check endpoint'ide konfiguratsioon

---

## 🔄 Võrdlus: Nginx vs Kubernetes Ingress

Nüüd kui sa tead kuidas Nginx reverse proxy töötab, on sul lihtsam mõista Kubernetes Ingress'i (harjutus 02). Siin on lühike võrdlus:

| Aspekt | Nginx (sinu lahendus) | Kubernetes Ingress (järgmine) |
|--------|----------------------|------------------------------|
| **Konfiguratsioon** | `/etc/nginx/sites-available/kirjakast.cloud` | YAML manifest (Ingress resource) |
| **Backend teenused** | Käsitsi: `upstream ... { server localhost:3000; }` | Automaatne: viitad K8s Service'ile |
| **Muudatused** | SSH + vim + nginx reload | kubectl apply -f ingress.yaml |
| **Load balancing** | Käsitsi konfiguratsioon | Automaatne (Service'i taga olevad pod'id) |
| **Skaleerumine** | Üks Nginx instance | Mitu Ingress Controller pod'i |
| **Tõrge** | Kui Nginx crashib, kõik seiskub | K8s restartib automaatselt |

**Järgmises harjutuses** näed kuidas Kubernetes Ingress pakub sama funktsionaalsust, aga automaatselt ja skaaleeritavalt.

---

## 🎯 Järgmised Sammud

### Edasi Path A:
➡️ **Harjutus 02: Kubernetes Ingress** - õpi kaasaegset cloud-native lähenemist

### Valikuline:
- Lisa SSL/TLS sertifikaadid Let's Encrypt'iga (harjutus 03 esimene pool)
- Seadista rate limiting (DoS kaitse)
- Lisa load balancing (mitme backend serveri vahel)
- Seadista gzip compression

---

**Õnnitleme!** 🎉

Sa oled nüüd seadistanud töötava DNS + Nginx reverse proxy lahenduse, mis suunab liiklust domeenist `kirjakast.cloud` oma mikroteenustele. See on traditsiooniline, aga väga levinud ja tootmises kasutatud lähenemine.

**Harjutuse lõpp**

---

**Viimane uuendus:** 2025-11-16
**Autor:** DevOps Training Labs
