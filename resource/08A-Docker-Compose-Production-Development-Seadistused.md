# 08A. Docker Compose: Production vs Development Seadistused

**Peatükk 8A: Turvalisuse Mustrid ja Keskkonnad**

---

## 📋 Ülevaade

Üheks olulisemaks otsuseks Docker Compose rakenduste juurutamisel on **portide haldamine** ja **keskkondade vahelised erinevused**. See peatükk käsitleb kahte põhilist lähenemist:

1. **Production lähenemine** - Maksimaalne turvalisus (pole avalikke porte)
2. **Development lähenemine** - Turvalisus + Debug'imine (localhost-only pordid)

**Õpieesmärgid:**
- ✅ Mõista erinevusi production ja development konfiguratsioonide vahel
- ✅ Oskad valida sobivat portide haldamise strateegiat
- ✅ Kasutad `docker-compose.override.yml` mustreid
- ✅ Rakendasd turvalisuse parimaid praktikaid

---

## 🏗️ Kolm Port Binding Strateegiat

Docker Compose võimaldab teenuseid (services) siduda hostiga kolmel erineval viisil:

### 1. Avalik Port Binding (0.0.0.0) ⚠️ OHTLIK

```yaml
services:
  user-service:
    ports:
      - "3000:3000"           # Sama mis "0.0.0.0:3000:3000"
      - "0.0.0.0:3000:3000"   # Eksplitsiitne kuju
```

**Tähendus:**
- Port `3000` on kättesaadav **kõikidelt network interface'idelt**
- Avalik internet saab ligi, kui VPS firewall lubab

**Millal kasutada:**
- ❌ **MITTE KUNAGI** production'is backend/database teenustele
- ⚠️ Ainult frontend teenustele koos tulemüüri/reverse proxy'ga
- ⚠️ Ainult local development'is (localhost, mitte VPS)

**Turvarisk:** 🔴 **KÕRGE**
- Teenus on avalikult kättesaadav
- Võimalik: DDoS, brute-force, data leak

---

### 2. Localhost-Only Port Binding (127.0.0.1) ✅ TURVALINE DEBUG

```yaml
services:
  user-service:
    ports:
      - "127.0.0.1:3000:3000"   # Ainult localhost
```

**Tähendus:**
- Port `3000` on kättesaadav **ainult localhost'ilt** (127.0.0.1)
- Välisvõrk (internet) ei pääse ligi
- SSH sessioonis saab debug'ida

**Millal kasutada:**
- ✅ Development/debugging VPS'is
- ✅ SSH kaudu ligipääsuks
- ✅ Kui vajad otseühendust teenustele

**Turvarisk:** 🟢 **MADAL**
- Ainult local loopback interface
- Välisvõrk ei saa ligi

**Näide kasutamisest:**

```bash
# SSH sessioonis (TÖÖTAB):
curl http://localhost:3000/health
psql -h localhost -p 5432 -U postgres

# Väliselt (FAILIB):
curl http://kirjakast.cloud:3000/health  # Connection refused
```

---

### 3. Pole Porte (Puudub ports:) ✅ MAKSIMAALNE TURVALISUS

```yaml
services:
  user-service:
    # ❌ POLE ports: sektsiooni
    networks:
      - backend-network
```

**Tähendus:**
- Teenus on kättesaadav **ainult Docker võrgu (network) sees**
- Host masinal pole ühtegi porti avatud
- Teenused suhtlevad omavahel service name'ide kaudu

**Millal kasutada:**
- ✅ **Production** (alati!)
- ✅ **Staging**
- ✅ Kui ei vaja otseühendust teenustele

**Turvarisk:** 🟢 **NULL** (portide puudumine)

**Näide kasutamisest:**

```bash
# Debug'imine ilma portideta:
docker compose logs user-service
docker compose exec user-service curl localhost:3000/health
docker compose exec postgres-user psql -U postgres
```

---

## 🔀 Production vs Development: Võrdlus

| Aspekt | **Production** | **Development** |
|--------|----------------|-----------------|
| **Portide konfiguratsioon** | ❌ Pole üldse `ports:` sektsiooni | ✅ `127.0.0.1:3000:3000` (localhost-only) |
| **Väline ligipääs** | ❌ Täiesti blokeeritud | ❌ Blokeeritud |
| **SSH sessioon** | ❌ Ei pääse ligi | ✅ Saab debug'ida |
| **Turvarisk** | ✅ Null (puuduvad pordid) | ✅ Madal (localhost-only) |
| **Debug'imine** | ❌ Raskem (logs, exec) | ✅ Lihtne (curl, psql) |
| **Compliance** | ✅ PCI-DSS, GDPR | ⚠️ Sõltub poliitikast |
| **Kasutusjuht** | Production, staging | Development, troubleshooting |

---

## 🏭 Production Lähenemine (Maksimaalne Turvalisus)

### Põhimõte

**Ära avalda ühtegi porti backend või database teenustele.**

Ainult frontend (reverse proxy/Nginx) tohib olla avalik. Kõik muu suhtleb Docker võrgu sees.

### Konfiguratsioon

**docker-compose.yml:**

```yaml
# ==========================================================================
# Production Configuration - NO PORTS
# ==========================================================================

services:
  # ==========================================================================
  # PostgreSQL Database - NO PORTS
  # ==========================================================================
  postgres-user:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres123
      POSTGRES_DB: user_service_db
    volumes:
      - postgres-user-data:/var/lib/postgresql/data
    networks:
      - database-network
    # ❌ POLE ports: sektsiooni

  # ==========================================================================
  # User Service (Backend) - NO PORTS
  # ==========================================================================
  user-service:
    image: user-service:1.0
    environment:
      DATABASE_URL: postgresql://postgres:postgres123@postgres-user:5432/user_service_db
      JWT_SECRET: VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
    depends_on:
      - postgres-user
    networks:
      - backend-network
      - database-network
    # ❌ POLE ports: sektsiooni

  # ==========================================================================
  # Frontend (Nginx) - PUBLIC PORT
  # ==========================================================================
  frontend:
    image: frontend:1.0
    ports:
      - "8080:80"  # Ainult frontend on avalik
    networks:
      - backend-network

networks:
  database-network:
  backend-network:

volumes:
  postgres-user-data:
```

### Eelised

- ✅ **Maksimaalne turvalisus** - pordid ei eksisteeri host'is üldse
- ✅ **Compliance** - vastab PCI-DSS, GDPR, HIPAA nõuetele
- ✅ **Lihtsam firewall** - ei pea porte blokeerima (neid ei ole)
- ✅ **Defense in depth** - lisaturvakiht
- ✅ **Attack surface minimaalne** - ainult frontend on exposed

### Puudused

- ❌ **Raskem debug'ida** - ei saa SSH kaudu otse teenustele ligi
- ❌ **Vajalikud alternatiivsed meetodid:**

  ```bash
  # Logide vaatamine
  docker compose logs -f user-service

  # Konteinerisse sisenemise
  docker compose exec user-service sh

  # Käskude käivitamine konteineris
  docker compose exec user-service curl localhost:3000/health
  docker compose exec postgres-user psql -U postgres -d user_service_db

  # Andmebaasi backup
  docker compose exec postgres-user pg_dump -U postgres user_service_db > backup.sql
  ```

### Millal kasutada

- ✅ **Production** keskkonnas (alati!)
- ✅ **Staging** keskkonnas
- ✅ Kui compliance nõuded kehtivad (PCI-DSS, GDPR)
- ✅ Kui maksimaalne turvalisus on prioriteet
- ✅ Kui ei vaja otseühendust teenustele

---

## 💻 Development Lähenemine (Turvalisus + Debug'imine)

### Põhimõte

**Kasuta `docker-compose.override.yml` faili, et lisada localhost-only pordid development'is.**

Base fail (`docker-compose.yml`) jääb production-ready (pole porte). Override fail lisab debug'imise võimaluse.

### Konfiguratsioon

**docker-compose.yml** (base fail - production-ready):

```yaml
# ==========================================================================
# Base Configuration - Production Ready
# ==========================================================================

services:
  postgres-user:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres123
      POSTGRES_DB: user_service_db
    volumes:
      - postgres-user-data:/var/lib/postgresql/data
    networks:
      - database-network
    # ❌ POLE ports: sektsiooni

  user-service:
    image: user-service:1.0
    environment:
      DATABASE_URL: postgresql://postgres:postgres123@postgres-user:5432/user_service_db
      JWT_SECRET: VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
    depends_on:
      - postgres-user
    networks:
      - backend-network
      - database-network
    # ❌ POLE ports: sektsiooni

  frontend:
    image: frontend:1.0
    ports:
      - "8080:80"
    networks:
      - backend-network

networks:
  database-network:
  backend-network:

volumes:
  postgres-user-data:
```

**docker-compose.override.yml** (automaatselt laetakse development'is):

```yaml
# ==========================================================================
# Development Override - Localhost-Only Port Binding
# ==========================================================================
# See fail laetakse AUTOMAATSELT, kui käivitad: docker compose up
#
# Eesmärk: Võimalda debug'imist SSH sessioonis, aga EI avalda porte
# välismaailmale (internet).
#
# Kasutamine:
#   docker compose up -d    # Laeb automaatselt override faili
#
# Production'is ÄRA kasuta:
#   docker compose -f docker-compose.yml up -d  # Override ei laeta
# ==========================================================================

services:
  # ==========================================================================
  # Backend Services - Localhost-only Port Binding
  # ==========================================================================

  user-service:
    ports:
      - "127.0.0.1:3000:3000"    # ✅ Localhost-only (NOT 0.0.0.0)
    # Kasutamine:
    #   Debug: curl http://localhost:3000/health (SSH kaudu)
    #   Secure: curl http://kirjakast.cloud:3000 → CONNECTION REFUSED

  # ==========================================================================
  # Database - Localhost-only Port Binding
  # ==========================================================================

  postgres-user:
    ports:
      - "127.0.0.1:5432:5432"    # ✅ Localhost-only
    # Kasutamine:
    #   Debug: psql -h localhost -p 5432 -U postgres -d user_service_db
    #   Secure: psql -h kirjakast.cloud -p 5432 → CONNECTION REFUSED
```

### Eelised

- ✅ **Lihtne debug'ida** SSH sessioonis
  ```bash
  # SSH sessioonis töötab:
  curl http://localhost:3000/health
  psql -h localhost -p 5432 -U postgres
  ```
- ✅ **Ikkagi turvaline** - väliselt ei ole ligipääs
  ```bash
  # Väliselt FAILIB:
  curl http://kirjakast.cloud:3000/health  # Connection refused
  ```
- ✅ **Parim mõlemast maailmast** - turvalisus + mugavus
- ✅ **Production-ready base** - docker-compose.yml jääb production-ready

### Puudused

- ❌ **Veidi keerukam** - vajab override faili
- ❌ **Võimalik vale kasutus** - kui unustada maha production'is

### Kuidas Docker Compose laadib override faili

**Automaatne laadimine:**

```bash
# Override laetakse AUTOMAATSELT:
docker compose up -d

# Compose otsib järgmised failid järjekorras:
# 1. docker-compose.yml (base)
# 2. docker-compose.override.yml (kui eksisteerib)
# Merge'ib mõlemad kokku
```

**Eksplitsiitne laadimine:**

```bash
# Lae ainult base fail (production):
docker compose -f docker-compose.yml up -d

# Lae custom override:
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Millal kasutada

- ✅ **Development** keskkonnas (arenduses)
- ✅ **Debug'imisel** ja troubleshooting'ul
- ✅ Kui vajad otseühendust SSH kaudu
- ✅ Kui töötad VPS'is, aga tahad debuggida

### Testimine

```bash
# SSH sessioonis (peaks töötama):
curl http://localhost:3000/health
psql -h localhost -p 5432 -U postgres

# Väliselt (peaks failima):
curl http://kirjakast.cloud:3000
psql -h kirjakast.cloud -p 5432

# Kontrolli portide binding'ut:
docker compose ps
netstat -tuln | grep 3000
# Peaks nägema: 127.0.0.1:3000 (MITTE 0.0.0.0:3000)
```

---

## 🎯 Kuidas Valida?

### Otsustuspuu

```
Kas production/staging keskkond?
│
├─ JAH → Kasuta Production lähenemist (pole porte)
│        ✅ Maksimaalne turvalisus
│        ✅ Compliance
│
└─ EI → Kas vajad debug'imist SSH kaudu?
         │
         ├─ JAH → Kasuta Development lähenemist (127.0.0.1)
         │        ✅ Turvaline + mugav debug
         │        ✅ Override fail
         │
         └─ EI → Kasuta Production lähenemist (pole porte)
                  ✅ Lihtsam konfiguratsioon
```

### Soovitatav lähenemine

1. **Alusta Production lähenemisega** (pole porte)
   - Õpi maksimaalselt turvalise konfiguratsiooni loomist
   - Mõista, kuidas teenused suhtlevad Docker võrgus
   - See on best practice

2. **Lisa Development override vajadusel**
   - Kui vajad SSH kaudu debug'imist
   - Kui töötad VPS'is ja tahad testimist lihtsustada
   - Looge `docker-compose.override.yml` ainult local development'i jaoks

3. **Production'is:**
   - ❌ **ÄRA kasuta** `docker-compose.override.yml`
   - ✅ **Kasuta ainult** base fail (docker-compose.yml)
   - ✅ Käivita: `docker compose -f docker-compose.yml up -d`
   - ✅ Või kustuta override fail production serverist

4. **Development'is:**
   - ✅ **Kasuta mõlemat** - base + override
   - ✅ Override fail annab debug'imise võimaluse
   - ✅ Käivita lihtsalt: `docker compose up -d`

---

## 🔒 Turvalisuse Parimad Tavad

### 1. Defense in Depth

Rakenda mitu turvakihti:

```
┌──────────────────────────────────────────┐
│ 1. Firewall (VPS level)                 │  ← Blokeeri mittevajalikud pordid
├──────────────────────────────────────────┤
│ 2. Port Binding (Docker level)          │  ← Ainult 127.0.0.1 või pole porte
├──────────────────────────────────────────┤
│ 3. Network Segmentation (Docker network)│  ← Eraldi võrgud (backend, database)
├──────────────────────────────────────────┤
│ 4. Authentication (Application level)   │  ← JWT tokens, RBAC
└──────────────────────────────────────────┘
```

### 2. Principle of Least Privilege

- Avalda ainult **minimaalne** ports arv
- Ainult frontend peaks olema avalik (8080)
- Backend ja database **mitte kunagi** avalikud

### 3. Network Segmentation

Kasuta erinevaid võrke (networks):

```yaml
networks:
  frontend-network:  # Frontend → Backend
  backend-network:   # Backend ↔ Backend
  database-network:  # Backend → Database

services:
  frontend:
    networks:
      - frontend-network

  user-service:
    networks:
      - frontend-network   # Suhtleb frontend'iga
      - backend-network    # Suhtleb teiste backend'idega
      - database-network   # Suhtleb database'iga

  postgres-user:
    networks:
      - database-network   # Ainult backend pääseb ligi
```

### 4. Regulaarne Auditeerimine

```bash
# Kontrolli, mis pordid on avatud:
netstat -tuln | grep LISTEN

# Kontrolli Docker port binding'ut:
docker compose ps
docker port <container-name>

# Testi väliselt:
nmap -p 1-10000 your-vps-ip

# Vaata tulemüüri reegleid:
sudo ufw status verbose
```

### 5. Logging ja Monitoring

Logi kõik port access katsed:

```yaml
services:
  user-service:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

Monitoori:
- Ebanormaalseid connection attempt'e
- Port scan'e (nmap, masscan)
- Brute-force katseid

---

## 📊 Näited Reaalsest Maailmast

### Näide 1: E-commerce Stack

**Production konfiguratsioon:**

```yaml
services:
  # ✅ Avalik
  nginx:
    ports:
      - "80:80"
      - "443:443"

  # ❌ Mitte avalik
  api-gateway:
    # POLE ports:

  product-service:
    # POLE ports:

  order-service:
    # POLE ports:

  postgres:
    # POLE ports:

  redis:
    # POLE ports:
```

**Tulemus:**
- Ainult Nginx on exposed (80, 443)
- Kõik muu suhtleb Docker võrgu sees
- Minimaalne attack surface

### Näide 2: Microservices Development

**docker-compose.yml** (base):

```yaml
services:
  api-gateway:
    # POLE ports:

  user-service:
    # POLE ports:

  product-service:
    # POLE ports:
```

**docker-compose.override.yml** (development):

```yaml
services:
  api-gateway:
    ports:
      - "127.0.0.1:8000:8000"  # Debug'imiseks

  user-service:
    ports:
      - "127.0.0.1:3000:3000"

  product-service:
    ports:
      - "127.0.0.1:3001:3001"
```

**Tulemus:**
- Production: Pole porte (maksimaalne turvalisus)
- Development: Localhost-only (turvaline debug)
- Parim mõlemast maailmast

---

## 🧪 Praktiline Harjutus

**Ülesanne:** Loo turvaline Docker Compose konfiguratsioon kolmele teenusele (frontend, backend, database).

**Nõuded:**
1. Frontend peab olema avalik (port 8080)
2. Backend ei tohi olla avalik
3. Database ei tohi olla avalik
4. Development'is peab saama debug'ida SSH kaudu
5. Production'is peab olema maksimaalselt turvaline

**Lahendus:**

**docker-compose.yml:**

```yaml
services:
  postgres:
    image: postgres:15-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - database-network
    # ❌ POLE ports:

  backend:
    image: backend:1.0
    depends_on:
      - postgres
    networks:
      - backend-network
      - database-network
    # ❌ POLE ports:

  frontend:
    image: nginx:alpine
    ports:
      - "8080:80"  # ✅ Ainult frontend on avalik
    networks:
      - backend-network

networks:
  database-network:
  backend-network:

volumes:
  pgdata:
```

**docker-compose.override.yml:**

```yaml
services:
  backend:
    ports:
      - "127.0.0.1:3000:3000"  # ✅ Localhost-only debug

  postgres:
    ports:
      - "127.0.0.1:5432:5432"  # ✅ Localhost-only debug
```

**Testimine:**

```bash
# Development (SSH sessioonis):
curl http://localhost:3000/health  # ✅ Töötab
psql -h localhost -p 5432          # ✅ Töötab

# Production (väliselt):
curl http://your-vps:3000          # ❌ Connection refused
psql -h your-vps -p 5432           # ❌ Connection refused
curl http://your-vps:8080          # ✅ Frontend töötab
```

---

## 📝 Kokkuvõte

### Production Lähenemine

**Millal:** Production, staging, compliance keskkonnad

**Konfiguratsioon:**
- ❌ Pole `ports:` sektsiooni backend/database teenustel
- ✅ Ainult frontend on exposed

**Eelised:**
- ✅ Maksimaalne turvalisus
- ✅ Compliance (PCI-DSS, GDPR)
- ✅ Attack surface minimaalne

**Debug'imine:**
```bash
docker compose logs -f user-service
docker compose exec user-service curl localhost:3000/health
docker compose exec postgres-user psql -U postgres
```

---

### Development Lähenemine

**Millal:** Development, debug'imine, troubleshooting

**Konfiguratsioon:**
- ✅ Base fail (docker-compose.yml) ilma portideta
- ✅ Override fail (docker-compose.override.yml) localhost-only binding'uga

**Eelised:**
- ✅ Turvaline debug'imine SSH kaudu
- ✅ Production-ready base fail
- ✅ Parim mõlemast maailmast

**Kasutamine:**
```bash
# Development (automaatne override):
docker compose up -d

# Production (ainult base):
docker compose -f docker-compose.yml up -d
```

---

### Põhireegel

> **"Avalda ainult see, mis PEAB olema avalik. Kõik muu peida Docker võrgu taha."**

**Avalik (exposed):**
- ✅ Frontend (Nginx, reverse proxy)
- ✅ Load balancer

**Mitte avalik (internal):**
- ❌ Backend API'd
- ❌ Andmebaasid
- ❌ Cache (Redis)
- ❌ Message queues (RabbitMQ)

---

## 🔗 Seotud Materjalid

- **[05-Docker-Pohimotted.md](05-Docker-Pohimotted.md)** - Docker võrgustik (networking) põhitõed
- **[06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md](06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md)** - Container security best practices
- **[25-Security-Best-Practices.md](25-Security-Best-Practices.md)** - Üldine security guidance

---

## 📚 Viited

- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [Docker Compose Override](https://docs.docker.com/compose/extends/)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

---

**Viimane uuendus:** 2025-01-25
