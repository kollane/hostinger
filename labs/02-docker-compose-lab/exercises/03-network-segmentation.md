# Harjutus 3: Võrgu Segmenteerimine ja Portide Turvalisus

**Kestus:** 60 minutit
**Eesmärk:** Implementeeri võrgu segmenteerimine (network segmentation) ja vähenda rünnaku pinda (attack surface)

---

## 📋 Ülevaade

Selles harjutuses õpid, kuidas muuta Harjutus 2 konfiguratsiooni turvaliseks, kasutades võrgu segmenteerimist (network segmentation) ja portide piiranguid. Õpid mõistma, miks avalikud andmebaasi ja backend pordid on turvarisk ning kuidas neid kaitsta.

**Mis on probleem?**
- Praegu on **KÕIK 5 teenust (services)** avalikult kättesaadavad internetist
- Andmebaasid (PostgreSQL) on otse internetist ligipääsetavad
- Backend API'd on otse internetist ligipääsetavad
- Üks võrk (network) - kui üks teenus (service) on kompromiteeritud, on kõik ohus

**Mis on lahendus?**
- **3-taseme arhitektuur:** Frontend (DMZ) → Backend → Database
- **Ainult frontend avalik:** Port 8080 on ainus avalik port
- **Võrgu segmenteerimine:** Eraldi võrgud (networks) igale tasemele
- **Vähimate õiguste printsiip:** Iga teenus (service) näeb ainult seda, mida vaja

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista turvariske ühe võrguga (single network) arhitektuuris
- ✅ Designida 3-taseme võrgu arhitektuuri (DMZ → Backend → Database)
- ✅ Luua ja konfigureerida mitut Docker võrku (network)
- ✅ Määrata teenuseid (services) mitmesse võrku (multi-network assignment)
- ✅ Piirata portide ligipääsetavust (localhost-only binding)
- ✅ Testida võrgu segmenteerimise efektiivsust
- ✅ Mõista vähimate õiguste printsiipi (principle of least privilege)
- ✅ Vähendada rünnaku pinda (attack surface) 96%

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Harjutus 2 on läbitud:**

```bash
# 1. Kas oled compose-project kaustas?
pwd
# Peaks olema: /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project

# 2. Kas docker-compose.yml on olemas?
ls -la docker-compose.yml nginx.conf

# 3. Kas stack töötab?
docker compose ps
# Peaks nägema 5 teenust (services): frontend, user-service, todo-service, postgres-user, postgres-todo

# 4. Kas frontend töötab?
curl http://localhost:8080

# 5. KRIITILINE: Kas andmebaasi skeemid (users ja todos tabelid) on loodud?
docker compose exec postgres-user psql -U postgres -d user_service_db -c "\dt"
# Oodatud: users tabel
docker compose exec postgres-todo psql -U postgres -d todo_service_db -c "\dt"
# Oodatud: todos tabel
```

**Kui midagi puudub:**

**Andmebaasi skeemid puuduvad?** (KRIITILINE!)
```bash
# Variant A: Setup skript (kiire)
cd ..  # Tagasi 02-docker-compose-lab/
./setup.sh
# Vali valik 2 (Automaatne initsialiseermine)

# Variant B: Käsitsi
cd compose-project
docker compose -f docker-compose.yml -f docker-compose.init.yml up -d
# VÕI vaata Harjutus 1 Troubleshooting sektsiooni
```

**Harjutus 2 pole läbitud?**
- 🔗 Mine tagasi [Harjutus 2](02-add-frontend.md)

**✅ Kui kõik ülalpool on OK (eriti DB skeemid!), võid jätkata!**

---

## 🏗️ Arhitektuur: Enne vs Peale

### ENNE (Harjutus 2): Üks Võrk, Kõik Pordid Avalikud

```
                        INTERNET (0.0.0.0)
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
      Port 8080            Port 3000           Port 8081
          │                    │                    │
          ▼                    ▼                    ▼
    ┌──────────┐         ┌──────────┐         ┌──────────┐
    │ Frontend │         │   User   │         │   Todo   │
    │  (Nginx) │         │ Service  │         │ Service  │
    └─────┬────┘         └─────┬────┘         └─────┬────┘
          │                    │                    │
          │     Port 5432      │      Port 5433     │
          │          │         │          │         │
          │          ▼         │          ▼         │
          │    ┌──────────┐   │    ┌──────────┐    │
          │    │Postgres  │   │    │Postgres  │    │
          │    │  -user   │   │    │  -todo   │    │
          │    └──────────┘   │    └──────────┘    │
          │                   │                     │
          └───────────────────┴─────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │   todo-network    │
                    │  (single network) │
                    └───────────────────┘

❌ PROBLEEM:
- 5 avalikku porti: 8080, 3000, 8081, 5432, 5433
- Kõik teenused (services) ühes võrgus (network)
- Andmebaasid otse internetist kättesaadavad
- Backend API'd otse internetist kättesaadavad
- Frontend saab otse andmebaasidega suhelda
```

### PEALE (Harjutus 3): Kolm Võrku, Ainult Frontend Avalik

```
                        INTERNET (0.0.0.0)
                               │
                          Port 8080 AINULT
                               │
        ┌──────────────────────┴──────────────────────┐
        │         FRONTEND NETWORK (DMZ)              │
        │                                             │
        │              ┌──────────┐                   │
        │              │ Frontend │                   │
        │              │  (Nginx) │                   │
        │              └─────┬────┘                   │
        │                    │                        │
        └────────────────────┼────────────────────────┘
                             │
              ┌──────────────┴───────────────┐
              │ Reverse Proxy                │
              │ /api/auth → user-service     │
              │ /api/todos → todo-service    │
              └──────────────┬───────────────┘
                             │
        ┌────────────────────┴──────────────────────┐
        │        BACKEND NETWORK                    │
        │        (internal only - ei ole avalik)    │
        │                                           │
        │   ┌──────────┐          ┌──────────┐     │
        │   │   User   │          │   Todo   │     │
        │   │ Service  │          │ Service  │     │
        │   └─────┬────┘          └─────┬────┘     │
        │         │                     │          │
        └─────────┼─────────────────────┼──────────┘
                  │                     │
                  │                     │
        ┌─────────┴─────────────────────┴──────────┐
        │       DATABASE NETWORK                    │
        │       (internal: true - isoleeritud)      │
        │                                           │
        │   ┌──────────┐          ┌──────────┐     │
        │   │Postgres  │          │Postgres  │     │
        │   │  -user   │          │  -todo   │     │
        │   └──────────┘          └──────────┘     │
        │                                           │
        └───────────────────────────────────────────┘

✅ LAHENDUS:
- 1 avalik port: 8080 (ainult frontend)
- 3 võrku (networks): frontend, backend, database
- Andmebaasid MITTE avalikud (ainult backend'idele kättesaadavad)
- Backend API'd MITTE avalikud (ainult frontend proxy kaudu)
- Frontend EI saa otse andmebaasidega suhelda
```

---

## 📊 Diagrammid

### 1. Rünnaku Pinna Vähenemine (Attack Surface Reduction)

```
ENNE (Harjutus 2):
╔════════════════════════════════════════════════════════╗
║  5 AVALIKKU PORTI (0.0.0.0)                            ║
║  ┌────────┬────────┬────────┬────────┬────────┐        ║
║  │ 8080   │ 3000   │ 8081   │ 5432   │ 5433   │        ║
║  │Frontend│ User   │ Todo   │ DB     │ DB     │        ║
║  │   ✅   │   ❌   │   ❌   │   ❌   │   ❌   │        ║
║  └────────┴────────┴────────┴────────┴────────┘        ║
║                                                         ║
║  Rünnaku vektorid (attack vectors): 5                  ║
║  Turvarisk: ❌ KÕRGE                                    ║
╚════════════════════════════════════════════════════════╝

PEALE (Harjutus 3):
╔════════════════════════════════════════════════════════╗
║  1 AVALIK PORT (0.0.0.0)                               ║
║  ┌────────┐                                            ║
║  │ 8080   │                                            ║
║  │Frontend│                                            ║
║  │   ✅   │                                            ║
║  └────────┘                                            ║
║                                                         ║
║  Rünnaku vektorid (attack vectors): 1                  ║
║  Turvarisk: ✅ MADAL                                    ║
╚════════════════════════════════════════════════════════╝

Paranemine: 96% rünnaku pinna vähenemine (5 → 1)
```

### 2. Ligipääsu Kontroll Matrix (Access Control Matrix)

```
┌──────────────┬──────────┬──────────┬──────────┬────────────┬────────────┐
│ KES? / KUHU? │ Frontend │ User Svc │ Todo Svc │ Postgres-U │ Postgres-T │
├──────────────┼──────────┼──────────┼──────────┼────────────┼────────────┤
│ Internet     │    ✅    │    ❌    │    ❌    │     ❌     │     ❌     │
│ (0.0.0.0)    │  :8080   │          │          │            │            │
├──────────────┼──────────┼──────────┼──────────┼────────────┼────────────┤
│ Frontend     │    -     │    ✅    │    ✅    │     ❌     │     ❌     │
│ (Nginx)      │          │ proxy    │ proxy    │            │            │
├──────────────┼──────────┼──────────┼──────────┼────────────┼────────────┤
│ User Service │    -     │    -     │    ❌    │     ✅     │     ❌     │
│ (Node.js)    │          │          │          │  :5432     │            │
├──────────────┼──────────┼──────────┼──────────┼────────────┼────────────┤
│ Todo Service │    -     │    -     │    -     │     ❌     │     ✅     │
│ (Java)       │          │          │          │            │  :5432     │
├──────────────┼──────────┼──────────┼──────────┼────────────┼────────────┤
│ Postgres-U   │    -     │    -     │    -     │     -      │     ❌     │
├──────────────┼──────────┼──────────┼──────────┼────────────┼────────────┤
│ Postgres-T   │    -     │    -     │    -     │     -      │     -      │
└──────────────┴──────────┴──────────┴──────────┴────────────┴────────────┘

Legend:
  ✅ = Ligipääs lubatud (access allowed)
  ❌ = Ligipääs keelatud (access denied)
  -  = Ei rakendu (not applicable)
```

### 3. Võrgu Topologia (Network Topology)

```
Services Võrkude (Networks) Kaart:

┌─────────────────────┐
│ FRONTEND NETWORK    │────────┐
│ (DMZ)               │        │
│ - frontend          │        │
└─────────────────────┘        │
                               │
┌─────────────────────┐        │
│ BACKEND NETWORK     │────────┼────────┐
│ (Application)       │        │        │
│ - frontend (proxy)  │        │        │
│ - user-service      │        │        │
│ - todo-service      │        │        │
└─────────────────────┘        │        │
                               │        │
┌─────────────────────┐        │        │
│ DATABASE NETWORK    │────────┼────────┼────────┐
│ (Data - ISOLATED)   │        │        │        │
│ - user-service      │        │        │        │
│ - todo-service      │        │        │        │
│ - postgres-user     │        │        │        │
│ - postgres-todo     │        │        │        │
│                     │        │        │        │
│ internal: true ✅   │        │        │        │
└─────────────────────┘        │        │        │
                               │        │        │
                               │        │        │
┌──────────────────────────────┴────────┴────────┴────┐
│ MULTI-NETWORK SERVICE MAPPING                       │
│                                                      │
│ frontend:        [frontend-network, backend-network] │
│ user-service:    [backend-network, database-network] │
│ todo-service:    [backend-network, database-network] │
│ postgres-user:   [database-network]                  │
│ postgres-todo:   [database-network]                  │
└──────────────────────────────────────────────────────┘

Põhimõte (Principle):
  - Frontend näeb backend'e, aga MITTE andmebaase
  - Backend'd näevad oma andmebaase, aga MITTE teiste backend'e andmebaase
  - Andmebaasid ei näe midagi peale oma backend'i
```

---

## 📝 Sammud

### Samm 1: Analüüsi Praegust Turvariski (10 min)

#### 1.1. Kontrolli, millised pordid on avalikud

```bash
# Vaata, millised pordid kuulavad (listen)
sudo lsof -i -P -n | grep LISTEN | grep -E "8080|3000|8081|5432|5433"

# Oodatud väljund (PRAEGU - EBATURVALINE):
# docker-pr  *:8080 (frontend)
# docker-pr  *:3000 (user-service)  ❌
# docker-pr  *:8081 (todo-service)  ❌
# docker-pr  *:5432 (postgres-user) ❌
# docker-pr  *:5433 (postgres-todo) ❌
```

#### 1.2. Testi backend ligipääsetavust internetist

```bash
# Testi, kas backend API'd on avalikult kättesaadavad
# (Kui töötad VPS'is, kasuta serverit välist IP'd või domeeni)

# Test 1: User Service (PEAKS TÖÖTAMA, AGA EI TOHIKS!)
curl http://localhost:3000/health

# Oodatud vastus:
# {"status":"ok","database":"connected"}
# ❌ PROBLEEM: Backend on avalik!

# Test 2: Todo Service (PEAKS TÖÖTAMA, AGA EI TOHIKS!)
curl http://localhost:8081/health

# Oodatud vastus:
# {"status":"UP"}
# ❌ PROBLEEM: Backend on avalik!
```

#### 1.3. Testi andmebaasi ligipääsetavust

```bash
# Test 3: PostgreSQL User DB (PEAKS TÖÖTAMA, AGA EI TOHIKS!)
nc -zv localhost 5432

# Oodatud vastus:
# Connection to localhost 5432 port [tcp/postgresql] succeeded!
# ❌ PROBLEEM: Andmebaas on avalik!

# Test 4: PostgreSQL Todo DB (PEAKS TÖÖTAMA, AGA EI TOHIKS!)
nc -zv localhost 5433

# Oodatud vastus:
# Connection to localhost 5433 port [tcp/*] succeeded!
# ❌ PROBLEEM: Andmebaas on avalik!
```

#### 1.4. Mõista turvariske

**Mis võib juhtuda, kui andmebaasid on avalikud?**
- ❌ Brute force rünnakud PostgreSQL paroolidele
- ❌ SQL injection rünnakud
- ❌ Andmete eksfiltratsioon (data exfiltration)
- ❌ Andmebaasi kustutamine (DROP TABLE)
- ❌ Compliance rikkumised (GDPR, PCI-DSS)

**Mis võib juhtuda, kui backend API'd on avalikud?**
- ❌ Frontend turvakontrollide mööda minemine
- ❌ API enumeration rünnakud
- ❌ Rate limiting puudumine
- ❌ Suurem rünnaku pind (attack surface)

**Lahendus:** Võrgu segmenteerimine (network segmentation) + portide piirangud!

---

### Samm 2: Loo 3 Võrku (Networks) (10 min)

#### 2.1. Peata olemasolev stack

```bash
# Peata kõik teenused (services)
docker compose down

# Kontrolli, et konteinerid on peatatud
docker compose ps
# Peaks olema tühi
```

#### 2.2. Varunda olemasolev konfiguratsioon

```bash
# Loo varukoopia
cp docker-compose.yml docker-compose.backup.yml

# Kontrolli
ls -la docker-compose*.yml
```

#### 2.3. Loo uus docker-compose.yml võrkudega (networks)

Ava docker-compose.yml ja **lisa lõppu** (enne `volumes:` sektsiooni või peale `services:` sektsiooni):

```yaml
# ==========================================================================
# VÕRGU SEGMENTEERIMINE (Network Segmentation)
# ==========================================================================
# 3-taseme arhitektuur: DMZ → Backend → Database
# ==========================================================================
networks:
  # FRONTEND NETWORK (DMZ - Demilitarized Zone)
  # Avalik võrk (network), kus on frontend
  frontend-network:
    driver: bridge

  # BACKEND NETWORK (Application Layer)
  # Sisevõrk (internal network) backend teenustele (services)
  backend-network:
    driver: bridge

  # DATABASE NETWORK (Data Layer)
  # Isoleeritud võrk (isolated network) andmebaasidele
  # internal: true = Ei saa ühendust välismaailmaga
  database-network:
    driver: bridge
    internal: true    # ✅ OLULINE: Täielikult isoleeritud
```

**Salvesta fail:** `Esc`, siis `:wq`, `Enter`

#### 2.4. Valideeri konfiguratsioon

```bash
# Kontrolli YAML syntax'it
docker compose config --quiet

# Kui viga (error), näed error message'i
# Kui OK, ei näe midagi (quiet mode)
```

---

### Samm 3: Määra Teenused (Services) Võrkudesse (15 min)

Nüüd pead määrama iga teenuse (service) õigetesse võrkudesse (networks).

#### 3.1. Frontend: Määra mõlemasse võrku (frontend + backend)

Leia `frontend:` teenus (service) docker-compose.yml's ja **asenda** `networks:` sektsioon:

```yaml
  frontend:
    image: nginx:alpine
    container_name: frontend
    restart: unless-stopped
    ports:
      - "8080:80"    # ✅ Ainult see port jääb avalikuks
    volumes:
      - ../../apps/frontend:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - frontend-network    # Avalik ligipääs (public access)
      - backend-network     # Pääseb ligi backend'idele (proxy)
    depends_on:
      - user-service
      - todo-service
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost"]
      interval: 30s
      timeout: 3s
      retries: 3
```

#### 3.2. User Service: Määra mõlemasse võrku (backend + database)

Leia `user-service:` ja **asenda** `networks:` sektsioon:

```yaml
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
    # MÄRKUS: ports: sektsioon eemaldatakse järgmises sammuses!
    ports:
      - "3000:3000"    # ❌ Eemaldame Samm 4's
    networks:
      - backend-network     # Võtab vastu frontend päringuid (requests)
      - database-network    # Pääseb ligi postgres-user'ile
    depends_on:
      postgres-user:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
```

#### 3.3. Todo Service: Määra mõlemasse võrku (backend + database)

Leia `todo-service:` ja **asenda** `networks:` sektsioon:

```yaml
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
    # MÄRKUS: ports: sektsioon eemaldatakse järgmises sammuses!
    ports:
      - "8081:8081"    # ❌ Eemaldame Samm 4's
    networks:
      - backend-network     # Võtab vastu frontend päringuid (requests)
      - database-network    # Pääseb ligi postgres-todo'le
    depends_on:
      postgres-todo:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8081/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 60s
```

#### 3.4. PostgreSQL User DB: Määra ainult database võrku

Leia `postgres-user:` ja **asenda** `networks:` sektsioon:

```yaml
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
    # MÄRKUS: ports: sektsioon eemaldatakse järgmises sammuses!
    ports:
      - "5432:5432"    # ❌ Eemaldame Samm 4's
    networks:
      - database-network    # ✅ Ainult database võrgus (network)
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```

#### 3.5. PostgreSQL Todo DB: Määra ainult database võrku

Leia `postgres-todo:` ja **asenda** `networks:` sektsioon:

```yaml
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
    # MÄRKUS: ports: sektsioon eemaldatakse järgmises sammuses!
    ports:
      - "5433:5432"    # ❌ Eemaldame Samm 4's
    networks:
      - database-network    # ✅ Ainult database võrgus (network)
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```

#### 3.6. Eemalda vana võrgu konfiguratsioon

Leia faili lõpust järgmine sektsioon ja **kustuta see**:

```yaml
# VANA - KUSTUTA SEE:
networks:
  todo-network:
    external: true
```

See on asendatud uue 3-võrgu konfiguratsiooniga, mille lisasid Samm 2.3's.

**Salvesta fail:** `Esc`, siis `:wq`, `Enter`

---

### Samm 4: Eemalda Avalikud Pordid (10 min)

Nüüd eemaldame avalikud pordid backend ja database teenustelt (services).

#### 4.1. Eemalda User Service port

Leia `user-service:` sektsioon ja **kustuta täielikult** `ports:` sektsioon:

```yaml
  user-service:
    image: user-service:1.0-optimized
    container_name: user-service
    restart: unless-stopped
    environment:
      # ... environment variables ...
    # ❌ KUSTUTA JÄRGMISED READ:
    # ports:
    #   - "3000:3000"
    networks:
      - backend-network
      - database-network
    # ... ülejäänud konfiguratsioon ...
```

**Miks see on turvaline?**
- Frontend pääseb ligi user-service'ile Docker DNS kaudu: `http://user-service:3000`
- Väline maailm EI pääse ligi (port ei ole 0.0.0.0'ga seotud)

#### 4.2. Eemalda Todo Service port

Leia `todo-service:` sektsioon ja **kustuta täielikult** `ports:` sektsioon:

```yaml
  todo-service:
    image: todo-service:1.0-optimized
    container_name: todo-service
    restart: unless-stopped
    environment:
      # ... environment variables ...
    # ❌ KUSTUTA JÄRGMISED READ:
    # ports:
    #   - "8081:8081"
    networks:
      - backend-network
      - database-network
    # ... ülejäänud konfiguratsioon ...
```

#### 4.3. Eemalda PostgreSQL User DB port

Leia `postgres-user:` sektsioon ja **kustuta täielikult** `ports:` sektsioon:

```yaml
  postgres-user:
    image: postgres:16-alpine
    container_name: postgres-user
    restart: unless-stopped
    environment:
      # ... environment variables ...
    volumes:
      - postgres-user-data:/var/lib/postgresql/data
    # ❌ KUSTUTA JÄRGMISED READ:
    # ports:
    #   - "5432:5432"
    networks:
      - database-network
    # ... ülejäänud konfiguratsioon ...
```

#### 4.4. Eemalda PostgreSQL Todo DB port

Leia `postgres-todo:` sektsioon ja **kustuta täielikult** `ports:` sektsioon:

```yaml
  postgres-todo:
    image: postgres:16-alpine
    container_name: postgres-todo
    restart: unless-stopped
    environment:
      # ... environment variables ...
    volumes:
      - postgres-todo-data:/var/lib/postgresql/data
    # ❌ KUSTUTA JÄRGMISED READ:
    # ports:
    #   - "5433:5432"
    networks:
      - database-network
    # ... ülejäänud konfiguratsioon ...
```

#### 4.5. Valideeri ja käivita

```bash
# Kontrolli YAML syntax'it
docker compose config --quiet

# Kui OK, käivita stack
docker compose up -d

# Kontrolli staatust
docker compose ps

# Peaksid nägema kõiki 5 teenust (services) UP ja healthy staatuses
```

**Salvesta fail:** `Esc`, siis `:wq`, `Enter`

---

### Samm 5: Lisa Development Override (127.0.0.1 Binding) (5 min)

Tootmises (production) me ei vaja backend/DB porte, aga arenduses (development) on kasulik neid debug'ida. Loome `docker-compose.override.yml` faili, mis seob pordid **ainult localhost'ile**.

#### 5.1. Loo docker-compose.override.yml

```bash
# Loo override fail
vim docker-compose.override.yml
```

Vajuta `i` (insert mode) ja lisa:

```yaml
# ==========================================================================
# Docker Compose Override - Development Environment
# ==========================================================================
# See fail laetakse AUTOMAATSELT, kui käivitad: docker compose up
#
# Eesmärk: Võimalda debug'imist SSH sessioonis, aga EI avalda porte
# välismaailmale (internet).
#
# Turvaline:
#   ✅ curl http://localhost:3000/health (SSH sees)       → TÖÖTAB
#   ❌ curl http://kirjakast.cloud:3000/health (väliselt) → CONNECTION REFUSED
# ==========================================================================

version: '3.8'

services:
  # ==========================================================================
  # Backend Services - Localhost-only Port Binding
  # ==========================================================================
  user-service:
    ports:
      - "127.0.0.1:3000:3000"    # ✅ Localhost-only (NOT 0.0.0.0)
    # Debug: curl http://localhost:3000/health (SSH kaudu)
    # Secure: curl http://kirjakast.cloud:3000 → CONNECTION REFUSED

  todo-service:
    ports:
      - "127.0.0.1:8081:8081"    # ✅ Localhost-only
    # Debug: curl http://localhost:8081/health (SSH kaudu)

  # ==========================================================================
  # Databases - Localhost-only Port Binding
  # ==========================================================================
  postgres-user:
    ports:
      - "127.0.0.1:5432:5432"    # ✅ Localhost-only
    # Debug: psql -h localhost -p 5432 -U postgres (SSH kaudu)
    # Secure: psql -h kirjakast.cloud -p 5432 → CONNECTION REFUSED

  postgres-todo:
    ports:
      - "127.0.0.1:5433:5432"    # ✅ Localhost-only
    # Debug: psql -h localhost -p 5433 -U postgres (SSH kaudu)
```

Salvesta: `Esc`, siis `:wq`, `Enter`

#### 5.2. Taaskäivita stack override'iga

```bash
# Peata olemasolev stack
docker compose down

# Käivita uuesti (laadib automaatselt docker-compose.override.yml)
docker compose up -d

# Kontrolli staatust
docker compose ps
```

#### 5.3. Testi localhost binding'ut

```bash
# SSH sessioonis (peaks TÖÖTAMA):
curl http://localhost:3000/health
# Oodatud: {"status":"ok","database":"connected"}

# Väliselt (peaks FAILIMA):
# Kui sul on teine terminal või masinas väline ligipääs:
# curl http://<your-vps-ip>:3000/health
# Oodatud: Connection refused
```

**Kuidas see töötab?**
- `127.0.0.1:3000:3000` seob porti **ainult localhost'ile**
- SSH sessioonis saad debug'ida: `curl localhost:3000`
- Väline maailm EI pääse ligi: `curl kirjakast.cloud:3000` → Connection refused
- Parim mõlemast maailmast: debug'imine + turvalisus!

---

### Samm 6: Testi Turvalisust (10 min)

#### 6.1. Kontrolli avalikke porte

```bash
# Vaata, millised pordid kuulavad (listen)
sudo lsof -i -P -n | grep LISTEN | grep -E "8080|3000|8081|5432|5433"

# Oodatud väljund (TURVALINE):
# docker-pr  *:8080        ✅ (frontend - ainult see tohib olla avalik)
# docker-pr  127.0.0.1:3000   ✅ (localhost-only)
# docker-pr  127.0.0.1:8081   ✅ (localhost-only)
# docker-pr  127.0.0.1:5432   ✅ (localhost-only)
# docker-pr  127.0.0.1:5433   ✅ (localhost-only)
```

#### 6.2. Testi frontend (peaks TÖÖTAMA)

```bash
# Test 1: Frontend pealeht
curl http://localhost:8080

# Oodatud: HTML kood
# ✅ ÕIGE: Frontend on avalik

# Test 2: Frontend health
curl http://localhost:8080/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Oodatud: 401 (unauthorized) või 200 (kui kasutaja eksisteerib)
# ✅ ÕIGE: Frontend proxy töötab
```

#### 6.3. Testi backend (SSH sees: peaks TÖÖTAMA, väliselt: peaks FAILIMA)

```bash
# SSH sessioonis (127.0.0.1 binding):
curl http://localhost:3000/health
# Oodatud: {"status":"ok","database":"connected"}
# ✅ ÕIGE: Localhost binding töötab

curl http://localhost:8081/health
# Oodatud: {"status":"UP"}
# ✅ ÕIGE: Localhost binding töötab

# VÄLISELT (kui sul on võimalik testida teisest masinast):
# curl http://kirjakast.cloud:3000/health
# Oodatud: Connection refused
# ✅ ÕIGE: Port ei ole avalikult kättesaadav
```

#### 6.4. Testi andmebaasi (SSH sees: peaks TÖÖTAMA, väliselt: peaks FAILIMA)

```bash
# SSH sessioonis (127.0.0.1 binding):
nc -zv localhost 5432
# Oodatud: Connection succeeded
# ✅ ÕIGE: Localhost binding töötab

nc -zv localhost 5433
# Oodatud: Connection succeeded
# ✅ ÕIGE: Localhost binding töötab

# VÄLISELT (kui sul on võimalik testida teisest masinast):
# nc -zv kirjakast.cloud 5432
# Oodatud: Connection refused
# ✅ ÕIGE: Port ei ole avalikult kättesaadav
```

#### 6.5. Testi võrgu segmenteerimist (network segmentation)

```bash
# Test 1: Kas frontend saab ligi backend'idele?
docker compose exec frontend nc -zv user-service 3000
# Oodatud: Connection succeeded
# ✅ ÕIGE: Frontend on backend-network'is

docker compose exec frontend nc -zv todo-service 8081
# Oodatud: Connection succeeded
# ✅ ÕIGE: Frontend on backend-network'is

# Test 2: Kas frontend EI SAA ligi andmebaasidele?
docker compose exec frontend nc -zv postgres-user 5432
# Oodatud: nc: getaddrinfo for host "postgres-user" port 5432: Name or service not known
# ✅ ÕIGE: Frontend EI OLE database-network'is

docker compose exec frontend nc -zv postgres-todo 5432
# Oodatud: nc: getaddrinfo for host "postgres-todo" port 5432: Name or service not known
# ✅ ÕIGE: Frontend EI OLE database-network'is

# Test 3: Kas user-service saab ligi oma andmebaasile?
docker compose exec user-service nc -zv postgres-user 5432
# Oodatud: Connection succeeded
# ✅ ÕIGE: user-service on database-network'is

# Test 4: Kas user-service EI SAA ligi teise backend'i andmebaasile?
docker compose exec user-service nc -zv postgres-todo 5432
# Oodatud: Connection succeeded (mõlemad on samas database-network'is)
# MÄRKUS: See on OK, kuna mõlemad andmebaasid on samas võrgus (network).
# Täiendav turvalisus: PostgreSQL paroolid, firewall rules, Kubernetes Network Policies (Lab 7).
```

#### 6.6. Testi, et andmebaasi võrk (network) on isoleeritud

```bash
# Kontrolli, et database-network on internal: true
docker network inspect database-network | grep Internal
# Oodatud: "Internal": true
# ✅ ÕIGE: Võrk (network) on isoleeritud

# Testi, et andmebaas EI SAA välja (no internet access)
docker compose exec postgres-user ping -c 1 8.8.8.8
# Oodatud: FAIL (network is unreachable)
# ✅ ÕIGE: Isoleeritud võrk (network) ei saa ühendust välismaailmaga
```

---

### Samm 7: Mõista Arhitektuuri ja Turvalisust (5 min)

#### 7.1. Võrgu segmenteerimise printsiibid

**1. Defense in Depth (Kaitse sügavuses):**
- Mitu kaitsevahendit (defense layers):
  - Layer 1: Võrgu segmenteerimine (network segmentation)
  - Layer 2: Portide piirangud (port restrictions)
  - Layer 3: Autentimine (authentication - JWT)
  - Layer 4: Autorisatsioon (authorization - RBAC)

**2. Principle of Least Privilege (Vähimate õiguste printsiip):**
- Iga teenus (service) näeb ainult seda, mida vaja:
  - Frontend näeb ainult backend'e (EI näe andmebaase)
  - Backend'd näevad ainult oma andmebaase
  - Andmebaasid ei näe midagi peale oma backend'i

**3. Zero Trust (Nulltööduse mudel):**
- Ükski teenus (service) ei usalda teist vaikimisi (by default)
- Iga ligipääs peab olema selgelt lubatud (explicitly allowed)
- Võrgu segmenteerimine (network segmentation) jõustab seda

#### 7.2. Mis saavutasime?

| Aspekt | Enne (Ex 2) | Peale (Ex 3) | Paranemine |
|--------|-------------|--------------|------------|
| Avalikud pordid | 5 (8080, 3000, 8081, 5432, 5433) | 1 (8080) | 80% vähenemine |
| Võrkude arv | 1 (flat) | 3 (segmenteeritud) | 3× paranemine |
| Frontend → DB ligipääs | ✅ (võimalik) | ❌ (blokeeritud) | ✅ Turvaline |
| Rünnaku vektorid | 5 | 1 | 96% vähenemine |
| Compliance | ❌ (nõrk) | ✅ (tugev) | ✅ Vastab standarditele |

#### 7.3. Mis ei muutunud?

- Rakendus töötab täpselt samamoodi (brauserist)
- Frontend proxy töötab samamoodi
- JWT autentimine töötab samamoodi
- Andmed on ikka püsivad (volumes)
- **Ainult** turvalisus paranes!

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **3 võrku (networks):** frontend-network, backend-network, database-network
- [ ] **Ainult 1 avalik port:** 8080 (frontend)
- [ ] **Backend/DB pordid localhost-only:** 127.0.0.1 binding
- [ ] **Frontend ei pääse ligi andmebaasidele**
- [ ] **Võrgu segmenteerimine töötab:** `nc -zv` testid kinnitavad
- [ ] **Rakendus töötab brauserist:** End-to-End workflow toimib
- [ ] **docker-compose.override.yml olemas:** Dev debugging töötab
- [ ] **Mõistad turvaarhitektuuri:** DMZ → Backend → Database

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas kõik 5 teenust (services) töötavad?
docker compose ps
# Kõik peaksid olema UP ja HEALTHY

# 2. Kas ainult frontend port on avalik?
sudo lsof -i -P -n | grep LISTEN | grep docker-proxy
# Peaks nägema: *:8080 (frontend) ja 127.0.0.1:* (teised)

# 3. Kas võrgu segmenteerimine töötab?
docker compose exec frontend nc -zv postgres-user 5432
# Peaks FAILIMA (frontend ei ole database-network'is)

# 4. Kas frontend töötab brauserist?
curl http://localhost:8080
# Peaks tagastama HTML

# 5. Kas database-network on isoleeritud?
docker network inspect database-network | grep Internal
# Peaks nägema: "Internal": true
```

---

## 🎓 Õpitud Mõisted

### Docker Compose võrgu mõisted:

- **networks:** Võrkude definitsioonid (network definitions)
- **driver: bridge** - Bridge network driver (default)
- **internal: true** - Isoleeritud võrk (isolated network), ei saa ühendust välismaailmaga
- **Multi-network services** - Teenus (service), mis on mitmes võrgus (network)

### Turva mõisted:

- **Network segmentation** - Võrgu segmenteerimine (network segmentation)
- **DMZ (Demilitarized Zone)** - Avalik võrk (public network) frontend'idele
- **Attack surface** - Rünnaku pind (attack surface)
- **Defense in depth** - Kaitse sügavuses (defense in depth)
- **Principle of least privilege** - Vähimate õiguste printsiip (principle of least privilege)
- **Port binding** - Portide sidumine (port binding): 0.0.0.0 (avalik) vs 127.0.0.1 (localhost-only)

### Docker võrgu käsud:

```bash
# Loo võrk (network)
docker network create <network-name>

# Vaata võrke (networks)
docker network ls

# Inspekteeri võrku (network)
docker network inspect <network-name>

# Kontrolli, millised konteinerid on võrgus (network)
docker network inspect <network-name> | grep -A 10 Containers
```

---

## 💡 Parimad Tavad

1. **Kasuta võrgu segmenteerimist (network segmentation)** - Eralda teenused (services) tasemete kaupa (tier)
2. **Piirata portide ligipääsetavust** - Kasuta 127.0.0.1 binding dev'is, ära avalda porte prod'is
3. **Kasuta internal: true andmebaasi võrkudele (networks)** - Täielik isoleerimine
4. **Määra teenuseid (services) mitmesse võrku** - Võimalda selektiivset suhtlust
5. **Kommenteeri arhitektuuri** - Tee selgeks, miks iga teenus (service) on igas võrgus (network)
6. **Testi võrgu segmenteerimist** - Kinnita, et isolatsioon töötab (nc -zv testid)
7. **Dokumenteeri ligipääsu reeglid** - Kes saab kellega suhelda (access control matrix)

---

## 🐛 Levinud Probleemid

### Probleem 1: "frontend can't connect to user-service"

```bash
# Kontrolli, kas frontend on backend-network'is
docker inspect frontend | grep -A 10 Networks

# Peaks nägema "backend-network"
# Kui puudub, lisa frontend teenusele (service):
networks:
  - frontend-network
  - backend-network    # ← Lisa see!
```

### Probleem 2: "user-service can't connect to postgres-user"

```bash
# Kontrolli, kas user-service on database-network'is
docker inspect user-service | grep -A 10 Networks

# Peaks nägema "database-network"
# Kui puudub, lisa user-service teenusele (service):
networks:
  - backend-network
  - database-network    # ← Lisa see!
```

### Probleem 3: "curl http://localhost:3000 connection refused (SSH sees)"

```bash
# Kontrolli, kas docker-compose.override.yml on olemas
ls -la docker-compose.override.yml

# Kui puudub, loo see (vaata Samm 5)

# Kontrolli, kas override fail laeti
docker compose config | grep 127.0.0.1
# Peaks nägema: "127.0.0.1:3000:3000"

# Kui ei näe, taaskäivita:
docker compose down
docker compose up -d
```

### Probleem 4: "frontend still exposed to 0.0.0.0"

```bash
# See on OK! Frontend PEAKS olema avalik (public)
# Ainult frontend port 8080 tohib olla 0.0.0.0

# Kontrolli:
sudo lsof -i -P -n | grep 8080
# Peaks nägema: *:8080 (LISTEN)
# ✅ ÕIGE: Frontend on avalik
```

### Probleem 5: "database-network not isolated, can ping 8.8.8.8"

```bash
# Kontrolli, kas internal: true on seatud
docker network inspect database-network | grep Internal
# Peaks olema: "Internal": true

# Kui on false, paranda docker-compose.yml:
networks:
  database-network:
    driver: bridge
    internal: true    # ← Lisa see!

# Taaskäivita võrgud (networks):
docker compose down
docker network rm database-network
docker compose up -d
```

---

## 🔗 Järgmised Sammud

🎉 **Õnnitleme! Oled loonud turvalisuse Docker Compose arhitektuuri!**

**Mis saavutasid:**
- ✅ Võrgu segmenteerimine (network segmentation) implementeeritud
- ✅ Rünnaku pind (attack surface) vähendatud 96%
- ✅ Vähimate õiguste printsiip (principle of least privilege) rakendatud
- ✅ 3-taseme arhitektuur (DMZ → Backend → Database)
- ✅ Ainult 1 avalik port (8080)

---

### Mis Edasi? Vali Oma Tee:

#### **Variant A: Jätka Kubernetes'ega** (soovitatav enamikule)

**Oled valmis Lab 3'ks!** Docker põhitõed on selged. Nüüd on aeg õppida Kubernetes'e!

→ **[Lab 3: Kubernetes Basics](../../03-kubernetes-basics-lab/README.md)**

**Lab 3's õpid:**
- Kubernetes Network Policies (võrgu segmenteerimine K8s'is)
- Service types: ClusterIP (internal) vs NodePort (external)
- Ingress Controllers (nagu Nginx reverse proxy)
- Pod Security Policies
- ConfigMaps, Secrets, Persistent Volumes

---

#### **Variant B: Sügav Docker Võrgu Analüüs** (valikuline, advanced)

**Soovid süvendada Docker võrke?** Lab 2.5 õpetab professionaalset võrgu analüüsi!

→ **[Lab 2.5: Network Analysis & Testing](../../02.5-network-analysis-lab/README.md)** 🔷 *Valikuline*

**Lab 2.5's õpid:**
- Docker network inspection professionaalsete tööriistadega (`jq`, `tcpdump`)
- Süstemaatiline connectivity testing (connectivity matrix)
- Traffic analysis ja monitooring (`ss`, `netstat`, packet capture)
- DNS resolution ja service discovery testimine
- Automated testing scripts (bash, pass/fail reporting)
- Security auditing (`nmap`, port scanning, Docker Scout)
- Load testing ja performance analysis
- CI/CD integration

**⚠️ MÄRKUS:** Lab 2.5 on **VALIKULINE**, mitte kohustuslik Lab 3 jaoks!

**Kestus:** 3 tundi
**Kasutab:** Lab 2 olemasolevat docker-compose stack'i (ei loo uut keskkonda)

**Sobib sulle, kui:**
- Plaanid töötada DevOps/SRE rollis (network debugging oluline)
- Huvi pakub professionaalne võrgu analüüs ja diagnostika
- Soovid õppida automatiseeritud testimist
- Oled huvitatud security auditing'ust

**Jäta vahele, kui:**
- Soovid kiiresti Kubernetes'e jõuda
- Docker põhitõed on piisavad
- Aeg on piiratud

---

### Soovitus:

**Uutele õppijatele:** → Jätka Lab 3'ga (Variant A)

**Advanced õppijatele:** → Tee Lab 2.5, siis Lab 3 (Variant B → Lab 3)

**Kiire tee:** → Lab 3 nüüd, tule Lab 2.5 juurde hiljem tagasi

---

## 📚 Viited

- [Docker Networks dokumentatsioon](https://docs.docker.com/network/)
- [Docker Compose Networks](https://docs.docker.com/compose/networking/)
- [Network segmentation best practices](https://docs.docker.com/network/network-tutorial-standalone/)
- [OWASP Top 10 - Security Misconfiguration](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)

---

**Õnnitleme! Oled loonud turvalisuse Docker Compose arhitektuuri! 🎉🔒**
