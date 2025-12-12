# Lab 2: Harjutuste 4-9 Uuendamise Plaan

**Eesmärk:** Viia harjutused 4-9 kooskõlla parima praktikaga (multi-environment pattern)

**Kuupäev:** 2025-12-11

**Staatus:** 📋 PLAAN (pole veel rakendatud)

---

## 🎯 Ülevaade

### Probleem
Harjutused 4-9 õpetavad Docker Compose keskkondade haldamist, aga ei järgi järjepidevalt **parima praktika mudelit**:
- Base config + environment overrides
- `.env.{test,prelive,prod}` failid
- Composite käsud: `-f docker-compose.yml -f docker-compose.prod.yml`

### Lahendus
Uuendame 6 harjutust (4-9), et need järgiksid `compose-project/` näidismudelit.

### Harjutused 1-3
✅ **EI VAJA MUUDATUSI** - need õpetavad põhitõdesid õigesti (single-file approach)

---

## 📊 Uuendamiste Prioriteet

| Prioriteet | Harjutus | Muudatuse Tüüp | Mõju | Aeg |
|-----------|----------|----------------|------|-----|
| **P1 🔴** | Harjutus 4 | Suur ümberkirjutamine | Kriitiline - loob aluse | ~3h |
| **P1 🔴** | Harjutus 6 | Keskmise refaktoring | Oluline - näitab prod pattern'i | ~2h |
| **P1 🔴** | Harjutus 9 | Suur ümberkirjutamine | Oluline - production näidis | ~3h |
| **P2 🟡** | Harjutus 5 | Väike parandus | Parandab head praktikat | ~1h |
| **P2 🟡** | Harjutus 7 | Väike täiendus | Lisab env-spetsiifilisi seadistusi | ~1h |
| **P2 🟡** | Harjutus 8 | Keskmine täiendus | Integreerib legacy + multi-env | ~1.5h |
| **P3 🟢** | Lab 2 ENVIRONMENTS.md | Uus fail | Ühtne juhend | ~1h |

**Kokku:** ~12.5h tööd

---

## 🔧 Detailsed Sammud

---

## PRIORITEET 1: Kriitilised Muudatused

---

### 📝 HARJUTUS 4: Environment Management

**Fail:** `exercises/04-environment-management.md`

**Praegune olukord:**
- Õpetab ainult `.env` ja `docker-compose.override.yml`
- Ei õpeta multi-environment pattern'i (test, prelive, prod)
- Composite käsud mainimata

**Eesmärk:**
Lisa multi-environment pattern õpetamine (best practice)

---

#### Muudatused Samm-Sammult

##### 1. Lisa Uus Sektsioon: "Multi-Environment Architecture" (pärast Samm 2)

**Asukoht:** Pärast `.env` faili loomist (~rida 250)

**Lisatav sisu:**
```markdown
## Samm 3: Multi-Environment Arhitektuur (30 min)

### 3.1. Probleemi Kirjeldus

Seni kasutasime ühte `.env` faili ja `docker-compose.override.yml` failid.
See töötab **local development'is**, aga **mitte production'is**:

❌ Probleemid:
- Sama parool kõikides keskkondades (test, prod)
- `docker-compose.override.yml` laetakse ALATI (automaatne)
- Ei saa kontrollida, millist konfiguratsiooni kasutatakse

✅ Lahendus: **Environment-spetsiifilised failid**

### 3.2. Best Practice: 3-Taseme Arhitektuur

```
compose-project/
├── docker-compose.yml              # BASE (kõigile ühine)
├── docker-compose.test.yml         # TEST overrides
├── docker-compose.prelive.yml      # PRELIVE overrides
├── docker-compose.prod.yml         # PRODUCTION overrides
│
├── .env.test.example               # TEST template
├── .env.prelive.example            # PRELIVE template
└── .env.prod.example               # PRODUCTION template
```

**Põhimõte:**
1. **BASE** = Ühine konfiguratsioon (kõik teenused, võrgud, volumes)
2. **OVERRIDE** = Keskkonna-spetsiifilised erinevused (pordid, limits, secrets)
3. **ENV FILES** = Paroolid ja saladused (git ignore!)

**💡 Töötab Nii Lokaalselt Kui Mitmete Serveritega:**

Sama pattern töötab kahes stsenaariumis:

**Stsenaarium A: Lokaalne Arendus (1 masin)**
```bash
# Sinu laptop'is - vahelduvad keskkondade vahel
docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d    # TEST
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d   # PROD
```

**Stsenaarium B: Eraldi Serverid (tavaline production)**
```
Server A (test.company.com)     → TEST keskkond + .env.test
Server B (prelive.company.com)  → PRELIVE keskkond + .env.prelive
Server C (app.company.com)      → PRODUCTION keskkond + .env.prod
```

Iga server:
- ✅ Sama git repository (docker-compose.yml ja docker-compose.*.yml failid)
- ✅ Oma `.env.{env}` fail (server-spetsiifilised paroolid, DB host'id)
- ✅ Käivitab ainult oma keskkonna config'i

**Näide: Server C (PRODUCTION)**
```bash
# Server C'l on ainult .env.prod (mitte .env.test!)
cd /opt/app
git pull origin main
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
```

**Tulemus:** Sama kood (git'is), erinevad paroolid ja seadistused (igas serveris).

### 3.3. Loo Environment Override Failid

#### docker-compose.test.yml

```yaml
# TEST keskkond - kõik pordid avatud (debugging)
services:
  postgres-user:
    ports:
      - "127.0.0.1:5432:5432"

  postgres-todo:
    ports:
      - "127.0.0.1:5433:5432"

  user-service:
    environment:
      NODE_ENV: development
      LOG_LEVEL: debug
    ports:
      - "127.0.0.1:3000:3000"

  todo-service:
    environment:
      SPRING_PROFILES_ACTIVE: dev
      LOGGING_LEVEL_ROOT: DEBUG
    ports:
      - "127.0.0.1:8081:8081"

networks:
  database-network:
    internal: false  # Luba host ligipääs
```

**Salvesta:** `docker-compose.test.yml`

#### docker-compose.prod.yml

```yaml
# PRODUCTION keskkond - range seadistus
services:
  postgres-user:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  postgres-todo:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  user-service:
    restart: always
    environment:
      NODE_ENV: production
      LOG_LEVEL: warn
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  todo-service:
    restart: always
    environment:
      SPRING_PROFILES_ACTIVE: prod
      LOGGING_LEVEL_ROOT: WARN
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G

  frontend:
    restart: always
    ports:
      - "80:80"  # HTTP (production)
```

**Salvesta:** `docker-compose.prod.yml`

### 3.4. Loo Environment Variable Failid

#### .env.test.example

```bash
# TEST Environment
POSTGRES_USER=postgres
POSTGRES_PASSWORD=test123
POSTGRES_USER_DB=user_service_db
POSTGRES_TODO_DB=todo_service_db

JWT_SECRET=test-secret-not-for-production

USER_SERVICE_PORT=3000
TODO_SERVICE_PORT=8081
FRONTEND_PORT=8080

LOG_LEVEL=debug
SPRING_LOG_LEVEL=DEBUG
```

**Salvesta:** `.env.test.example`

#### .env.prod.example

```bash
# PRODUCTION Environment
# ⚠️ MUUDA KÕIK PAROOLID JA SECRETID!

POSTGRES_USER=postgres
POSTGRES_PASSWORD=CHANGE_ME_TO_STRONG_PASSWORD_MIN_32_CHARS
POSTGRES_USER_DB=user_service_db
POSTGRES_TODO_DB=todo_service_db

# Genereeri: openssl rand -base64 32
JWT_SECRET=CHANGE_ME_TO_RANDOM_BASE64_STRING

USER_SERVICE_PORT=3000
TODO_SERVICE_PORT=8081
FRONTEND_PORT=80

LOG_LEVEL=warn
SPRING_LOG_LEVEL=WARN
```

**Salvesta:** `.env.prod.example`

### 3.5. Uuenda .gitignore

```bash
# Actual .env files (CONTAINS SECRETS!)
.env
.env.local
.env.*.local
.env.test
.env.prelive
.env.prod

# Example files are OK (templates)
!.env*.example

# Local dev override
docker-compose.override.yml
```

**Salvesta:** `.gitignore`

### 3.6. Kasutamine: Composite Commands

#### TEST Keskkond

```bash
# 1. Loo .env.test fail template'ist
cp .env.test.example .env.test

# 2. Käivita TEST keskkonnaga
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d

# 3. Kontrolli
docker ps
docker-compose -f docker-compose.yml -f docker-compose.test.yml logs -f

# 4. Ühenda andmebaasidega (DBeaver)
# User DB: localhost:5432, postgres / test123
# Todo DB: localhost:5433, postgres / test123
```

#### PRODUCTION Keskkond

```bash
# 1. Loo .env.prod fail ja muuda paroole
cp .env.prod.example .env.prod
nano .env.prod  # MUUDA paroolid!

# Genereeri tugevad paroolid
openssl rand -base64 48  # PostgreSQL password
openssl rand -base64 32  # JWT secret

# 2. Käivita PRODUCTION keskkonnaga
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# 3. Kontrolli
docker ps  # Vaata (healthy) staatust
docker stats  # Vaata resource kasutust

# ❌ Andmebaasid ei ole kättesaadavad host'ilt (isoleeritud)
```

### 3.7. Võrdlus: Erinevused Keskkondade Vahel

| Aspekt | TEST | PRODUCTION |
|--------|------|------------|
| **DB Pordid** | ✅ 5432, 5433 (localhost) | ❌ Isoleeritud (internal network) |
| **Backend Pordid** | ✅ 3000, 8081 (localhost) | ❌ Sisevõrk ainult |
| **Frontend Port** | 8080 | 80 (või 443 SSL'iga) |
| **Paroolid** | `test123` (lihtne) | Tugevad (48 bytes) |
| **Logging** | DEBUG (verbose) | WARN (minimal) |
| **Resource Limits** | ❌ Pole | ✅ Strict (CPU, memory) |
| **Restart Policy** | unless-stopped | always |
| **Database Network** | internal: false | internal: true |

### 3.8. Alias'ed (Valikuline)

Lisa `~/.bashrc`:

```bash
alias dc-test='docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test'
alias dc-prod='docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod'
```

**Kasutamine:**
```bash
dc-test up -d
dc-prod logs -f
```

### ✅ Kontrollküsimused

1. Miks ei saa kasutada sama `.env` faili test ja production'is?
2. Miks `docker-compose.override.yml` ei sobi production'i?
3. Kuidas käivitada teenuseid TEST keskkonnaga?
4. Kuidas genereerida tugevaid paroole production'i jaoks?
5. Mis vahe on BASE config'il ja OVERRIDE config'il?

---

## Samm 4: (Endine Samm 3 - Nummerdus muutub)
[Jätka endise sisuga...]
```

---

##### 2. Uuenda docker-compose.yml (BASE config)

**Asukoht:** Samm 2 (~rida 150-250)

**Muudatus:** Lisa environment variable substitution

**Enne:**
```yaml
environment:
  POSTGRES_PASSWORD: postgres
  JWT_SECRET: VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
```

**Pärast:**
```yaml
environment:
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}  # ⚠️ Muuda production'is!
  JWT_SECRET: ${JWT_SECRET:-VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=}  # ⚠️ Muuda!
```

---

##### 3. Lisa Viited ENVIRONMENTS.md ja PASSWORDS.md Failidele

**Asukoht:** Harjutuse lõpus (enne "Kokkuvõte")

```markdown
## 📚 Täiendavad Juhendid

### Keskkondade Haldamine

👉 **Detailne juhend:** [compose-project/ENVIRONMENTS.md](../compose-project/ENVIRONMENTS.md)

**Sisaldab:**
- 4 keskkonna võrdlus (local dev, test, prelive, prod)
- Käivitamise käsud
- Troubleshooting
- Alias'ed

### Paroolide Turvalisus

👉 **Turvalisuse juhend:** [compose-project/PASSWORDS.md](../compose-project/PASSWORDS.md)

**Sisaldab:**
- Tugevate paroolide genereerimine
- `.env` failide haldamine
- Secrets rotation
- Best practices
```

---

##### 4. Uuenda Kokkuvõtet

**Lisa:**
```markdown
## Kokkuvõte

Selles harjutuses õppisid:
- ✅ `.env` failide kasutamine (environment variables)
- ✅ `docker-compose.override.yml` (local dev)
- ✅ **Multi-environment arhitektuur** (test, prelive, prod)
- ✅ **Composite käsud** (`-f docker-compose.yml -f docker-compose.prod.yml`)
- ✅ Environment-spetsiifilised `.env.{env}` failid
- ✅ Paroolide ja secretide turvalisus
- ✅ BASE config + OVERRIDE pattern

**Järgmine samm:** Harjutus 5 - Database Migrations
```

---

#### Testimine (Harjutus 4)

```bash
# 1. Testi TEST keskkonda
cd compose-project/
cp .env.test.example .env.test
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d
docker ps  # Kontrolli, et pordid on avatud

# 2. Testi PROD keskkonda
cp .env.prod.example .env.prod
nano .env.prod  # Muuda paroole
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
docker ps  # Kontrolli, et ainult frontend port 80 on avatud

# 3. Cleanup
docker-compose -f docker-compose.yml -f docker-compose.test.yml down
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
```

---

### 📝 HARJUTUS 5: Database Migrations (Liquibase)

**Fail:** `exercises/05-database-migrations.md`

**Praegune olukord:**
- Liquibase kasutab hardcoded paroole: `dbuser` / `dbpass123`
- Ei näita, kuidas migratsioone käivitada erinevates keskkondades

**Eesmärk:**
Muuda kasutama environment variable (kooskõlas Harjutus 4'ga)

---

#### Muudatused

##### 1. Uuenda Liquibase Service Environment Variables

**Asukoht:** Samm 2.1, Liquibase teenuse definitsioon (~rida 360-395)

**Enne:**
```yaml
liquibase-user:
  image: liquibase/liquibase:4.24-alpine
  environment:
    LIQUIBASE_COMMAND_URL: jdbc:postgresql://postgres-user:5432/user_service_db
    LIQUIBASE_COMMAND_USERNAME: dbuser
    LIQUIBASE_COMMAND_PASSWORD: dbpass123
```

**Pärast:**
```yaml
liquibase-user:
  image: liquibase/liquibase:4.24-alpine
  environment:
    LIQUIBASE_COMMAND_URL: jdbc:postgresql://postgres-user:5432/${POSTGRES_USER_DB:-user_service_db}
    LIQUIBASE_COMMAND_USERNAME: ${POSTGRES_USER:-postgres}
    LIQUIBASE_COMMAND_PASSWORD: ${POSTGRES_PASSWORD:-postgres}  # Tuleb .env failist!
```

**Lisa märkus:**
```markdown
**💡 Environment Variables:**
Liquibase kasutab samu paroole nagu PostgreSQL teenused (tuleb `.env` failist).

TEST keskkonnas:
- Username: `postgres`
- Password: `test123`

PRODUCTION keskkonnas:
- Username: `postgres`
- Password: (tugev, genereeritud parool `.env.prod` failist)
```

---

##### 2. Lisa Sektsioon: Migrations Erinevates Keskkondades

**Asukoht:** Pärast Samm 4 (~rida 600)

```markdown
## Samm 5: Migrations Erinevates Keskkondades (15 min)

### 5.1. Probleemi Kirjeldus

Liquibase changelog'id on samad kõikides keskkondades (test, prod),
aga **ühenduse andmed erinevad**:

| Keskkond | Parool | Andmebaas Asukoht |
|----------|--------|-------------------|
| TEST | `test123` | localhost:5432 |
| PRODUCTION | Tugev (48 bytes) | Isoleeritud võrk |

### 5.2. Lahendus: .env Failid

Liquibase teenus kasutab `.env` failist paroole:

```yaml
# docker-compose.yml
services:
  liquibase-user:
    environment:
      LIQUIBASE_COMMAND_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      #                             ↑ Tuleb .env failist
```

### 5.3. Käivitamine TEST Keskkonnas

```bash
# 1. Kasuta .env.test faili
cp .env.test.example .env.test

# 2. Käivita migrations TEST'is
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up liquibase-user

# 3. Kontrolli tulemust
docker logs liquibase-user
```

### 5.4. Käivitamine PRODUCTION Keskkonnas

```bash
# 1. Kasuta .env.prod faili (tugevad paroolid!)
cp .env.prod.example .env.prod
nano .env.prod  # Muuda POSTGRES_PASSWORD

# 2. Käivita migrations PRODUCTION'is
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up liquibase-user

# 3. Kontrolli tulemust
docker logs liquibase-user
```

### ✅ Best Practice

✅ **DO:**
- Kasuta samu changelog faile kõikides keskkondades
- Ühenduse andmed (paroolid) tuleb `.env.{env}` failist
- Testi migratsioone TEST keskkonnas enne PRODUCTION'i

❌ **DON'T:**
- Ära hardcode paroole changelog'idesse
- Ära loo eraldi changelog'e igale keskkonnale
```

---

#### Testimine (Harjutus 5)

```bash
# 1. Testi TEST keskkonnas
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up liquibase-user
docker logs liquibase-user | grep "successfully applied"

# 2. Kontrolli, et parool on õige
docker exec postgres-user psql -U postgres -d user_service_db -c "\dt"
```

---

### 📝 HARJUTUS 6: Production Patterns

**Fail:** `exercises/06-production-patterns.md`

**Praegune olukord:**
- Näitab `docker-compose.prod.yml` kui täielikku faili
- Composite pattern mainitud (rida 71), aga ei ole selgelt õpetatud
- Puudub `.env.prod` failide haldamine

**Eesmärk:**
Selgelt õpetada `docker-compose.prod.yml` kui **OVERRIDE** faili (mitte täielik config)

---

#### Muudatused

##### 1. Uuenda Sissejuhatust

**Asukoht:** Pärast õpieesmärke (~rida 50)

**Lisa:**
```markdown
## Enne Alustamist

**Eeldus:** Oled läbinud **Harjutus 4: Environment Management**

Selles harjutuses kasutame:
- **BASE config:** `docker-compose.yml` (Harjutus 1-4'st)
- **PRODUCTION override:** `docker-compose.prod.yml` (loome siin)
- **Secrets:** `.env.prod` fail (loome siin)

**Pattern:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
#               ↑ BASE               ↑ OVERRIDE                  ↑ SECRETS
```

**Märkus:** `docker-compose.prod.yml` ei ole täielik config, vaid **ainult production-spetsiifilised muudatused** (resource limits, restart policies, port bindings).
```

---

##### 2. Refaktoreeri Samm 1: Production Override Fail

**Asukoht:** Samm 1 (~rida 70-300)

**Enne:** Näitas suurt `docker-compose.prod.yml` faili (200+ rida)

**Pärast:** Näita ainult OVERRIDE'e (väike fail)

```markdown
## Samm 1: Loo Production Override Fail (20 min)

### 1.1. Mis on Override Fail?

Override fail sisaldab **ainult production-spetsiifilisi muudatusi**:
- Resource limits (CPU, memory)
- Restart policies (`always`)
- Port bindings (80 vs 8080)
- Logging levels (warn vs debug)

**BASE config** (`docker-compose.yml`) jääb samaks!

### 1.2. Loo docker-compose.prod.yml

**Fail:** `docker-compose.prod.yml`

```yaml
# ==========================================================================
# PRODUCTION Overrides
# ==========================================================================
# Käivitamine:
#   docker-compose -f docker-compose.yml -f docker-compose.prod.yml \
#     --env-file .env.prod up -d
# ==========================================================================

services:
  # PostgreSQL - Resource Limits
  postgres-user:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          memory: 256M

  postgres-todo:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          memory: 256M

  # User Service - Strict Limits + Production Logging
  user-service:
    restart: always
    environment:
      NODE_ENV: production
      LOG_LEVEL: warn  # Minimal logging
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          memory: 256M
    healthcheck:
      interval: 15s  # Tihedam kontroll production'is
      timeout: 5s
      retries: 3

  # Todo Service - Strict Limits
  todo-service:
    restart: always
    environment:
      SPRING_PROFILES_ACTIVE: prod
      LOGGING_LEVEL_ROOT: WARN  # Minimal logging
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          memory: 512M
    healthcheck:
      interval: 15s
      timeout: 5s
      retries: 3

  # Frontend - Production Port (80 instead of 8080)
  frontend:
    restart: always
    ports:
      - "80:80"      # HTTP
      # - "443:443"  # HTTPS (uncomment when SSL ready)
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
```

**Salvesta:** `docker-compose.prod.yml`

### 1.3. Võrdlus: BASE vs OVERRIDE

| Service | BASE (docker-compose.yml) | PRODUCTION Override |
|---------|---------------------------|---------------------|
| **postgres-user** | image, environment, volumes, networks | restart, resource limits |
| **user-service** | image, environment (base), networks | restart, LOG_LEVEL, resource limits |
| **frontend** | image, volumes, port 8080 | restart, **port 80**, resource limits |

**Printsiibb:** BASE sisaldab struktuuri, OVERRIDE muudab käitumist.
```

---

##### 3. Lisa Samm: .env.prod Faili Loomine

**Asukoht:** Uus samm 2

```markdown
## Samm 2: Loo .env.prod Fail (15 min)

### 2.1. Loo Template'ist

```bash
cp .env.prod.example .env.prod
```

### 2.2. Genereeri Tugevad Paroolid

```bash
# PostgreSQL password (48 bytes)
openssl rand -base64 48

# JWT Secret (32 bytes)
openssl rand -base64 32
```

**Näide:**
```bash
$ openssl rand -base64 48
kJ8xN2vL9mR3qW5tY8pF7nH6zX4cV1bM9sA2dG5hT3jK8lP0oI9uY7eR6tW4qX3zN2
```

### 2.3. Muuda .env.prod

```bash
nano .env.prod
```

**Fail:** `.env.prod`
```bash
# PRODUCTION Environment
POSTGRES_USER=postgres
POSTGRES_PASSWORD=kJ8xN2vL9mR3qW5tY8pF7nH6zX4cV1bM9sA2dG5hT3jK8lP0oI9uY7eR6tW4qX3zN2
POSTGRES_USER_DB=user_service_db
POSTGRES_TODO_DB=todo_service_db

JWT_SECRET=VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=

USER_SERVICE_PORT=3000
TODO_SERVICE_PORT=8081
FRONTEND_PORT=80

LOG_LEVEL=warn
SPRING_LOG_LEVEL=WARN
```

**⚠️ OLULINE:** `.env.prod` on `.gitignore`'is - ei lähe git'i!

### 2.4. Kontrolli .gitignore

```bash
cat .gitignore | grep .env
```

**Peaks sisaldama:**
```
.env.prod
.env.test
.env.prelive
```
```

---

##### 4. Uuenda Samm 3: Käivitamine (endine Samm 2)

**Muuda käivitamise käsk:**

**Enne:**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

**Pärast:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
#               ↑ BASE config         ↑ PROD override            ↑ PROD secrets
```

---

#### Testimine (Harjutus 6)

```bash
# 1. Loo .env.prod fail
cp .env.prod.example .env.prod
nano .env.prod  # Muuda paroole

# 2. Käivita production config'iga
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# 3. Kontrolli
docker ps  # Vaata port 80 (mitte 8080)
docker stats  # Vaata resource limits

# 4. Testi
curl http://localhost  # Frontend (port 80)

# 5. Cleanup
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
```

---

### 📝 HARJUTUS 7: Monitoring & Health Checks

**Fail:** `exercises/07-monitoring-health-checks.md`

**Praegune olukord:**
- Hea monitoring setup (Prometheus, Grafana)
- Puuduvad environment-spetsiifilised seadistused

**Eesmärk:**
Lisa environment-spetsiifilised health check intervallid ja monitoring configs

---

#### Muudatused

##### 1. Lisa Env-spetsiifilised Health Check Intervallid

**Asukoht:** Samm 2 (Health Checks) (~rida 200)

**Lisa märkus:**
```markdown
### 💡 Health Check Intervallid Keskkonniti

| Keskkond | Interval | Timeout | Retries | Põhjendus |
|----------|----------|---------|---------|-----------|
| **Development** | 30s | 3s | 3 | Vähem koormust |
| **TEST** | 30s | 5s | 3 | Sarnane development'ile |
| **PRODUCTION** | 15s | 5s | 3 | Kiirem failure detection |

**Konfiguratsioon:**

TEST (`docker-compose.test.yml`):
```yaml
services:
  user-service:
    healthcheck:
      interval: 30s  # Piisav test'imiseks
```

PRODUCTION (`docker-compose.prod.yml`):
```yaml
services:
  user-service:
    healthcheck:
      interval: 15s  # Kiirem reageerimine
```
```

---

##### 2. Lisa Prometheus Retention Environment Variable

**Asukoht:** Samm 4 (Prometheus Setup) (~rida 500)

**Muuda Prometheus command:**

**Enne:**
```yaml
services:
  prometheus:
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
```

**Pärast:**
```yaml
services:
  prometheus:
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=${PROMETHEUS_RETENTION:-30d}'  # Env var
```

**Lisa .env failidesse:**

`.env.test.example`:
```bash
PROMETHEUS_RETENTION=7d  # TEST: 7 päeva
```

`.env.prod.example`:
```bash
PROMETHEUS_RETENTION=90d  # PRODUCTION: 90 päeva
```

---

#### Testimine (Harjutus 7)

```bash
# 1. Testi TEST keskkonnas (7 päeva retention)
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d
docker logs prometheus | grep retention

# 2. Testi PROD keskkonnas (90 päeva retention)
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
docker logs prometheus | grep retention
```

---

### 📝 HARJUTUS 8: Legacy Integration

**Fail:** `exercises/08-legacy-integration.md`

**Praegune olukord:**
- 3-tier arhitektuur (tier1, tier2, tier3) eraldi projektid
- tier2 (Docker apps) ei kasuta multi-env pattern'i

**Eesmärk:**
Näita, kuidas tier2 (Docker apps) kasutab multi-environment pattern'i

---

#### Muudatused

##### 1. Lisa Sektsioon: Tier2 Multi-Environment Setup

**Asukoht:** Pärast Samm 3 (~rida 400)

```markdown
## Samm 4: Tier2 Multi-Environment Setup (20 min)

### 4.1. Probleemi Kirjeldus

Tier2 (Docker apps) peab töötama erinevates keskkondades:
- **TEST:** Debug logging, pordid avatud
- **PRODUCTION:** Warn logging, isoleeritud

### 4.2. Loo Tier2 Override Failid

**Kataloog:** `tier2-docker-apps/`

#### docker-compose.test.yml

```yaml
# TEST: Debug logging + avatud pordid
services:
  user-service:
    environment:
      LOG_LEVEL: debug
    ports:
      - "127.0.0.1:3000:3000"

  todo-service:
    environment:
      SPRING_LOG_LEVEL: DEBUG
    ports:
      - "127.0.0.1:8081:8081"
```

#### docker-compose.prod.yml

```yaml
# PRODUCTION: Minimal logging + resource limits
services:
  user-service:
    environment:
      LOG_LEVEL: warn
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  todo-service:
    environment:
      SPRING_LOG_LEVEL: WARN
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
```

### 4.3. Loo .env Failid Tier2 Jaoks

#### .env.test (tier2)

```bash
# Tier2 TEST Environment
DB_HOST=host.docker.internal  # Viitab Tier1 baasidele
DB_USER_PORT=5432
DB_TODO_PORT=5433
POSTGRES_PASSWORD=test123

JWT_SECRET=test-secret
LOG_LEVEL=debug
```

#### .env.prod (tier2)

```bash
# Tier2 PRODUCTION Environment
DB_HOST=host.docker.internal
DB_USER_PORT=5432
DB_TODO_PORT=5433
POSTGRES_PASSWORD=<strong-password-from-tier1>

JWT_SECRET=<strong-jwt-secret>
LOG_LEVEL=warn
```

### 4.4. Käivitamine

#### TEST Keskkond (kõik 3 tier'i)

```bash
# Tier1: Legacy DB (test)
cd tier1-legacy-db/
docker-compose up -d

# Tier2: Docker Apps (TEST config)
cd ../tier2-docker-apps/
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d

# Tier3: Legacy Nginx
cd ../tier3-legacy-nginx/
docker-compose up -d
```

#### PRODUCTION Keskkond

```bash
# Tier1: Legacy DB (prod)
cd tier1-legacy-db/
docker-compose --env-file .env.prod up -d

# Tier2: Docker Apps (PROD config)
cd ../tier2-docker-apps/
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# Tier3: Legacy Nginx (prod)
cd ../tier3-legacy-nginx/
docker-compose --env-file .env.prod up -d
```

### ✅ Põhimõte

- **Tier1** (legacy DB): Üks config (harva muudetav)
- **Tier2** (Docker apps): Multi-environment pattern (test, prod overrides)
- **Tier3** (legacy Nginx): Üks config või env-specific nginx.conf
```

---

#### Testimine (Harjutus 8)

```bash
# Testi tier2 TEST config'iga
cd tier2-docker-apps/
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d
docker logs user-service | grep -i debug  # Peaks näitama debug log'e

# Testi tier2 PROD config'iga
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
docker logs user-service | grep -i warn  # Peaks näitama warn log'e ainult
```

---

### 📝 HARJUTUS 9: Production Readiness

**Fail:** `exercises/09-production-readiness.md`

**Praegune olukord:**
- Suur `docker-compose.prod.yml` (330 rida) sisaldab kõike
- Peaks olema: väike override fail

**Eesmärk:**
Refaktoreeri struktuuri: base config + prod override

---

#### Muudatused

##### 1. Uuenda Sissejuhatust

**Asukoht:** Algus (~rida 50)

**Lisa:**
```markdown
## Arhitektuur

**Pattern:** BASE config + PRODUCTION override

```
compose-project/
├── docker-compose.yml              # BASE (services, volumes, networks)
├── docker-compose.prod.yml         # PROD overrides (SSL, HA, monitoring)
└── .env.prod                       # PROD secrets (paroolid)
```

**Käivitamine:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
```

**Märkus:** Selles harjutuses loome **täieliku production stack'i**, mis sisaldab:
- SSL/TLS (Nginx)
- High Availability (2 replicas per service)
- Monitoring (Prometheus + Grafana)
- Resource limits
- Health checks

Eeldame, et BASE config (`docker-compose.yml`) on olemas Harjutusest 1-4.
```

---

##### 2. Refaktoreeri Samm 2: Production Override Fail

**Asukoht:** Samm 2 (~rida 500-840)

**Enne:** 330-realine `docker-compose.prod.yml` täielik config

**Pärast:** Jaga kaheks:
1. **BASE services** → eelda olemasolevaks
2. **PROD overrides** → ainult production-spetsiifilised muudatused

```markdown
## Samm 2: Production Override Fail (45 min)

### 2.1. Arhitektuuri Ülevaade

**BASE config** (`docker-compose.yml`) sisaldab juba:
- postgres-user, postgres-todo (baaside)
- user-service, todo-service (backend)
- frontend (Nginx)

**PRODUCTION override** lisab:
- SSL/TLS termination (Nginx)
- 2 replicas per service (HA)
- Prometheus + Grafana (monitoring)
- Strict resource limits
- Advanced health checks

### 2.2. Loo docker-compose.prod.yml

**Fail:** `docker-compose.prod.yml`

```yaml
# ==========================================================================
# PRODUCTION Stack - SSL, HA, Monitoring
# ==========================================================================
# Käivitamine:
#   docker-compose -f docker-compose.yml -f docker-compose.prod.yml \
#     --env-file .env.prod up -d
# ==========================================================================

services:
  # ==========================================================================
  # Existing Services - Production Overrides
  # ==========================================================================

  postgres-user:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  postgres-todo:
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  # High Availability: 2 Replicas
  user-service-1:
    extends:
      service: user-service
      file: docker-compose.yml
    container_name: user-service-1
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  user-service-2:
    extends:
      service: user-service
      file: docker-compose.yml
    container_name: user-service-2
    restart: always
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  todo-service-1:
    extends:
      service: todo-service
      file: docker-compose.yml
    container_name: todo-service-1
    restart: always
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G

  todo-service-2:
    extends:
      service: todo-service
      file: docker-compose.yml
    container_name: todo-service-2
    restart: always
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G

  # Frontend with SSL
  frontend:
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/ssl:/etc/nginx/ssl:ro  # SSL sertifikaadid
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M

  # ==========================================================================
  # Monitoring Services (NEW)
  # ==========================================================================

  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: prometheus
    restart: always
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=90d'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:10.2.0
    container_name: grafana
    restart: always
    ports:
      - "3001:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-admin}
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - monitoring
    depends_on:
      - prometheus

volumes:
  prometheus-data:
  grafana-data:

networks:
  monitoring:
    driver: bridge
```

**Märkus:** See fail eeldab, et BASE config on olemas!

### 2.3. Võrdlus: BASE vs PROD

| Komponent | BASE (docker-compose.yml) | PROD Override |
|-----------|---------------------------|---------------|
| **postgres-user** | Service definition | restart, resource limits |
| **user-service** | 1 instance | **2 instances** (HA) |
| **todo-service** | 1 instance | **2 instances** (HA) |
| **frontend** | Port 8080 | **Ports 80+443 (SSL)** |
| **prometheus** | - | **NEW service** |
| **grafana** | - | **NEW service** |
```

---

##### 3. Lisa .env.prod Näidis

**Asukoht:** Uus samm

```markdown
## Samm 3: Production Environment Variables (10 min)

### 3.1. Loo .env.prod

```bash
cp .env.prod.example .env.prod
nano .env.prod
```

**Fail:** `.env.prod`
```bash
# PRODUCTION Secrets
POSTGRES_PASSWORD=<strong-48-byte-password>
JWT_SECRET=<strong-32-byte-secret>

# Grafana
GRAFANA_PASSWORD=<strong-admin-password>

# Prometheus
PROMETHEUS_RETENTION=90d

# Logging
LOG_LEVEL=warn
SPRING_LOG_LEVEL=WARN
```

### 3.2. Genereeri Paroolid

```bash
openssl rand -base64 48  # POSTGRES_PASSWORD
openssl rand -base64 32  # JWT_SECRET
openssl rand -base64 24  # GRAFANA_PASSWORD
```
```

---

##### 4. Uuenda Käivitamise Samme

**Muuda kõik käivitamise käsud:**

**Enne:**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

**Pärast:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
```

---

#### Testimine (Harjutus 9)

```bash
# 1. Genereeri SSL sertifikaat
cd nginx/ssl/
./generate-ssl.sh

# 2. Loo .env.prod
cd ../..
cp .env.prod.example .env.prod
nano .env.prod  # Muuda paroole

# 3. Käivita production stack
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# 4. Kontrolli
docker ps  # Peaks näitama 9 teenust
docker stats  # Resource kasutus

# 5. Testi
curl -k https://localhost  # SSL frontend
curl http://localhost:9090  # Prometheus
curl http://localhost:3001  # Grafana (admin / <GRAFANA_PASSWORD>)

# 6. Cleanup
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
```

---

## PRIORITEET 3: Täiendavad Dokumendid

---

### 📝 LEGACY-TO-KUBERNETES-ROADMAP.MD

**Fail:** `LEGACY-TO-KUBERNETES-ROADMAP.md` (Lab 2 juurkataloogis)

**Eesmärk:**
Detailne roadmap ettevõtetele, kes migratsioonivad **Tomcat/Java/Spring Boot** legacy süsteemidest Docker Compose'i ja hiljem Kubernetes'ele.

**Sihtrühm:**
- Legacy stack: Tomcat 8/9 + Java 8/11/17 + Spring Boot
- Build tool: Gradle (peamiselt), Maven
- Deploy: Manuaalsed WAR deploy'd, Jenkins copy-war
- Rakendusi: 5-20
- Keskkonnad: 3-4 (dev, test, prelive, prod)

---

#### Dokumendi Struktuur

```markdown
# Legacy → Docker → Kubernetes: Roadmap

## 1. Alguspunkt: Legacy Maailm

### 1.1. Tüüpiline Legacy Stack (2015-2020)
- Tomcat 8/9 serverid (test, prelive, prod)
- Java 8/11 rakendused
- Spring Boot 2.x (osad rakendused)
- Gradle build (peamiselt), mõned Maven
- PostgreSQL/Oracle andmebaasid (eraldi serverites)
- Manuaalsed deploy'd (Jenkins → FTP/SCP → Tomcat restart)

### 1.2. Probleemid
- Deploy aeg: 30-60 min
- Downtime: 5-15 min
- Konfiguratsioon: server.xml, context.xml (iga server erinev)
- Skaleerimise: Raske (vajab uut serverit + manuaalset setup'i)
- Keskkondade erinevused: Dev ≠ Test ≠ Prod
- Dependencies: WAR fail sisaldab kõike → suur (50-150 MB)

### 1.3. Näidisrakendus (CRM System)
```
Tomcat 8 Server (prod-app-01):
├─ /opt/tomcat/webapps/crm.war (120 MB)
├─ /opt/tomcat/conf/server.xml (port 8080, DB config)
├─ /opt/tomcat/conf/context.xml (JNDI datasource)
└─ Deploy: scp crm.war → restart Tomcat (10 min downtime)
```

---

## 2. Etapp 1: Konteinerise (Lab 1) - 3-6 kuud

### 2.1. Pilootprojekt (2 rakendust, 3 kuud)

#### 2.1.1. Vali Lihtsaimad Rakendused
Kriteeriumid:
- ✅ Spring Boot (soovitav) - embedded Tomcat
- ✅ Minimaalsed dependencies (vähe XML config'i)
- ✅ PostgreSQL (mitte Oracle - lihtne konteineriseerida)
- ✅ Mitte-kriitilised (võib tundide downtime'i lubada)

**Näide:**
- App 1: Internal Admin Panel (Spring Boot 2.7, Gradle, PostgreSQL)
- App 2: Analytics Dashboard (Spring Boot 2.5, Gradle, PostgreSQL)

#### 2.1.2. Tomcat + Gradle Rakenduse Konteinermine

**Variant A: Spring Boot Embedded Tomcat (Lihtsaim)**

```dockerfile
# Dockerfile (admin-panel - Spring Boot Gradle)
FROM gradle:7.6-jdk11 AS build
WORKDIR /app

# Kopeeri Gradle konfiguratsioon
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Download dependencies (cache layer)
RUN gradle dependencies --no-daemon

# Kopeeri source code
COPY src ./src

# Build JAR (skip tests for faster build)
RUN gradle bootJar --no-daemon

# Runtime stage
FROM eclipse-temurin:11-jre-alpine
WORKDIR /app

# Kopeeri JAR from build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Environment variables (asenda application.properties)
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV SPRING_PROFILES_ACTIVE=${SPRING_PROFILE:-prod}
ENV SERVER_PORT=${SERVER_PORT:-8080}

# Database config
ENV SPRING_DATASOURCE_URL=${DB_URL:-jdbc:postgresql://localhost:5432/admin_db}
ENV SPRING_DATASOURCE_USERNAME=${DB_USER:-postgres}
ENV SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD:-changeme}

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --spider --quiet http://localhost:8080/actuator/health || exit 1

# Run Spring Boot app
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

**Build ja test:**
```bash
# 1. Build Docker image
docker build -t admin-panel:1.0 .

# 2. Run lokaalse (connects to existing dev DB)
docker run -d --name admin-panel \
  -p 8080:8080 \
  -e SPRING_PROFILE=dev \
  -e DB_URL=jdbc:postgresql://192.168.1.50:5432/admin_dev \
  -e DB_USER=devuser \
  -e DB_PASSWORD=devpass123 \
  admin-panel:1.0

# 3. Test
curl http://localhost:8080/actuator/health
curl http://localhost:8080/api/users

# 4. Logs
docker logs -f admin-panel
```

---

**Variant B: Tomcat WAR Deployment (Legacy App)**

```dockerfile
# Dockerfile (crm-app - Tomcat 9 + Gradle WAR)
FROM gradle:7.6-jdk11 AS build
WORKDIR /app

COPY build.gradle settings.gradle ./
COPY gradle ./gradle
RUN gradle dependencies --no-daemon

COPY src ./src
RUN gradle war --no-daemon

# Runtime stage
FROM tomcat:9-jdk11-alpine
WORKDIR /usr/local/tomcat

# Remove default webapps
RUN rm -rf webapps/*

# Copy WAR from build stage
COPY --from=build /app/build/libs/*.war webapps/ROOT.war

# Environment variables
ENV JAVA_OPTS="-Xmx1024m -Xms512m -Dspring.profiles.active=${SPRING_PROFILE:-prod}"
ENV CATALINA_OPTS="-Ddb.host=${DB_HOST:-localhost} -Ddb.port=${DB_PORT:-5432}"

# Tomcat config (asenda server.xml)
ENV DB_HOST=${DB_HOST:-localhost}
ENV DB_PORT=${DB_PORT:-5432}
ENV DB_NAME=${DB_NAME:-crm_db}
ENV DB_USER=${DB_USER:-postgres}
ENV DB_PASSWORD=${DB_PASSWORD:-changeme}

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --spider --quiet http://localhost:8080/ || exit 1

CMD ["catalina.sh", "run"]
```

---

**Variant C: Gradle Build Optimization (Multi-Stage)**

```dockerfile
# Dockerfile (optimized - Gradle cache layers)
FROM gradle:7.6-jdk11 AS build
WORKDIR /app

# Cache Gradle wrapper ja dependencies (muutub harva)
COPY gradle ./gradle
COPY gradlew build.gradle settings.gradle ./
RUN ./gradlew dependencies --no-daemon || true

# Source code (muutub tihti)
COPY src ./src

# Build JAR
RUN ./gradlew bootJar --no-daemon

# Runtime (väike image)
FROM eclipse-temurin:11-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar

# Non-root user (security)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

**Result:**
- Image size: ~150 MB (vs 600 MB kui kaasad Gradle ja JDK)
- Build time: 2-5 min (Gradle cache)
- Security: Non-root user

---

#### 2.1.3. Konfiguratsioon Migration

**Enne (Tomcat server.xml):**
```xml
<!-- server.xml -->
<Resource name="jdbc/MyDB"
          auth="Container"
          type="javax.sql.DataSource"
          driverClassName="org.postgresql.Driver"
          url="jdbc:postgresql://prod-db-01:5432/crm_db"
          username="crmuser"
          password="ProdPassword123!"
          maxTotal="20" />
```

**Pärast (Docker ENV vars + application.yml):**
```yaml
# application.yml (JAR'is, defaults)
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:postgresql://localhost:5432/crm_db}
    username: ${SPRING_DATASOURCE_USERNAME:postgres}
    password: ${SPRING_DATASOURCE_PASSWORD:changeme}
    hikari:
      maximum-pool-size: ${DB_POOL_SIZE:20}
```

```bash
# .env.prod (Docker Compose)
SPRING_DATASOURCE_URL=jdbc:postgresql://prod-db-01:5432/crm_db
SPRING_DATASOURCE_USERNAME=crmuser
SPRING_DATASOURCE_PASSWORD=ProdPassword123!
DB_POOL_SIZE=20
```

---

### 2.2. Tulemus (Etapp 1)
- ✅ 2 rakendust konteinerisse (admin-panel, analytics)
- ✅ Dockerfile'id valmis (multi-stage, Gradle cache)
- ✅ Deploy aeg: 60 min → 5 min (Docker build + run)
- ✅ Dev = Prod (same image, different ENV vars)
- ✅ Õppinud: Gradle multi-stage builds, ENV vars vs XML config

---

## 3. Etapp 2: Orkestreerimise (Lab 2) - 3-6 kuud

### 3.1. Konverteeri Kõik 15 Rakendust

**Grupeeri rakendused projektideks:**

```
Project 1: CRM (3 rakendust)
├─ crm-frontend (Tomcat WAR)
├─ crm-backend (Spring Boot JAR)
└─ crm-reports (Spring Boot JAR)

Project 2: ERP (5 rakendust)
├─ erp-inventory (Tomcat WAR)
├─ erp-orders (Spring Boot JAR)
├─ erp-billing (Spring Boot JAR)
├─ erp-shipping (Spring Boot JAR)
└─ erp-analytics (Spring Boot JAR)

Project 3: Analytics (2 rakendust)
├─ analytics-etl (Spring Boot Batch JAR)
└─ analytics-dashboard (Spring Boot Web JAR)

Project 4: Portal (3 rakendust)
├─ portal-web (Tomcat WAR)
├─ portal-api (Spring Boot JAR)
└─ portal-admin (Spring Boot JAR)

Project 5: Internal Tools (2 rakendust)
├─ monitoring-dashboard (Spring Boot JAR)
└─ admin-tools (Spring Boot JAR)
```

---

### 3.2. Docker Compose Pattern (iga projekt)

**CRM Project docker-compose.yml:**

```yaml
# docker-compose.yml (base config)
services:
  crm-frontend:
    image: crm-frontend:${VERSION:-1.0}
    environment:
      BACKEND_URL: http://crm-backend:8080
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILE:-prod}
    networks:
      - crm-network
    depends_on:
      crm-backend:
        condition: service_healthy

  crm-backend:
    image: crm-backend:${VERSION:-1.0}
    environment:
      DB_URL: ${CRM_DB_URL}
      DB_USER: ${CRM_DB_USER}
      DB_PASSWORD: ${CRM_DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
    networks:
      - crm-network
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  crm-reports:
    image: crm-reports:${VERSION:-1.0}
    environment:
      BACKEND_URL: http://crm-backend:8080
      DB_URL: ${CRM_DB_URL}
    networks:
      - crm-network

networks:
  crm-network:
    driver: bridge
```

**docker-compose.test.yml (test overrides):**
```yaml
services:
  crm-frontend:
    ports:
      - "127.0.0.1:8080:8080"  # Debug access
    environment:
      LOG_LEVEL: DEBUG

  crm-backend:
    ports:
      - "127.0.0.1:8081:8080"
      - "127.0.0.1:5005:5005"  # Java debug port
    environment:
      JAVA_OPTS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
      LOG_LEVEL: DEBUG
```

**docker-compose.prod.yml (production overrides):**
```yaml
services:
  crm-frontend:
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
    restart: always

  crm-backend:
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
    restart: always
    environment:
      JAVA_OPTS: "-Xmx768m -XX:+UseContainerSupport"
      LOG_LEVEL: WARN
```

**.env.test (test secrets):**
```bash
CRM_DB_URL=jdbc:postgresql://test-db.internal:5432/crm_test
CRM_DB_USER=testuser
CRM_DB_PASSWORD=test123
JWT_SECRET=test-jwt-secret-not-for-prod
SPRING_PROFILE=test
VERSION=latest
```

**.env.prod (production secrets):**
```bash
CRM_DB_URL=jdbc:postgresql://prod-db.internal:5432/crm_prod
CRM_DB_USER=crmuser
CRM_DB_PASSWORD=<STRONG-PASSWORD-48-BYTES>
JWT_SECRET=<STRONG-JWT-SECRET-32-BYTES>
SPRING_PROFILE=prod
VERSION=1.5.2
```

---

### 3.3. Deploy Strategy

**Test Server:**
```bash
cd /opt/crm
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d
```

**Production Server (3 CRM apps × 2-3 replicas = 8 containers):**
```bash
cd /opt/crm
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# Rolling update (zero downtime)
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d --no-deps --build crm-backend
```

---

### 3.4. Tulemus (Etapp 2)
- ✅ Kõik 15 rakendust Docker Compose'is (5 projektis)
- ✅ Multi-environment pattern (test, prelive, prod)
- ✅ Deploy: 5 min per project
- ✅ Zero downtime (rolling restart)
- ✅ Identical config across environments (.env failid)

---

## 4. Etapp 2B: Production (12-18 kuud)

### 4.1. Production Topology

```
Server A (test.company.com):
├─ Project 1: CRM (docker-compose)
├─ Project 2: ERP (docker-compose)
├─ Project 3: Analytics (docker-compose)
├─ Project 4: Portal (docker-compose)
└─ Project 5: Tools (docker-compose)

Server B (prelive.company.com):
└─ Same 5 projects (docker-compose.prelive.yml)

Server C (prod.company.com):
└─ Same 5 projects (docker-compose.prod.yml + 2-3 replicas)
```

---

### 4.2. Monitoring & Logging

**Prometheus + Grafana (lisatud igale projektile):**

```yaml
# docker-compose.prod.yml (monitoring)
services:
  prometheus:
    image: prom/prometheus:v2.48.0
    ports:
      - "127.0.0.1:9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro

  grafana:
    image: grafana/grafana:10.2.0
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
```

---

### 4.3. CI/CD Pipeline (Jenkins)

**Jenkinsfile (CRM project):**
```groovy
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh './gradlew clean bootJar'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t crm-backend:${BUILD_NUMBER} .'
                sh 'docker tag crm-backend:${BUILD_NUMBER} crm-backend:latest'
            }
        }

        stage('Deploy to Test') {
            steps {
                sshagent(['test-server']) {
                    sh '''
                        ssh user@test.company.com "
                            cd /opt/crm &&
                            docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d --no-deps crm-backend
                        "
                    '''
                }
            }
        }
    }
}
```

---

### 4.4. Tulemus (Etapp 2B)
- ✅ Production stable (12-18 kuud)
- ✅ Deploy: Automated (Jenkins → Docker Compose)
- ✅ Monitoring: Prometheus + Grafana
- ✅ Logging: Centralized (Loki)
- ✅ High Availability: 2-3 replicas per app

---

## 5. Etapp 3: Kubernetes (Valikuline)

### 5.1. Signaalid Migratsiooniks

**Jah, minge Kubernetes'ele kui:**
- 15 rakendust → 30+ rakendust
- 3 serverit → 10+ serverit
- Manual scaling ei jõua (traffic spikes)
- Multi-region deployment (DR)

**Ei, jääge Docker Compose'i juurde kui:**
- 15 rakendust on stabiilne
- 3 serverit on piisav
- Manual scaling töötab (2-3 replicas per app)
- Downtime 99.5% on OK (mõned tunnid aastas)

---

### 5.2. Migration Path (kui otsustate)

**Docker Compose → Kubernetes Manifest:**

```yaml
# docker-compose.yml
services:
  crm-backend:
    image: crm-backend:1.0
    deploy:
      replicas: 3
    environment:
      DB_URL: ${DB_URL}
```

↓ **converts to** ↓

```yaml
# deployment.yaml (Kubernetes)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crm-backend
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: crm-backend
        image: crm-backend:1.0
        env:
        - name: DB_URL
          valueFrom:
            secretKeyRef:
              name: crm-secrets
              key: db-url
```

---

### 5.3. Tulemus (Etapp 3)
- ✅ Auto-scaling (HPA: CPU/memory based)
- ✅ Multi-cluster (DR, multi-region)
- ✅ Advanced networking (Service Mesh)
- ✅ Zero-downtime deployments (rolling updates)

---

## 6. Kokkuvõte

| Etapp | Aeg | Rakendused | Deploy Aeg | Downtime | Keerukus |
|-------|-----|------------|------------|----------|----------|
| **Legacy (Tomcat)** | - | 15 | 60 min | 10 min | ⭐⭐ |
| **Etapp 1 (Piloot)** | 3 kuud | 2/15 | 5 min | 0 min | ⭐⭐⭐ |
| **Etapp 2 (Compose)** | 6 kuud | 15/15 | 5 min | 0 min | ⭐⭐⭐⭐ |
| **Etapp 2B (Prod)** | 12-18 kuud | 15 | 3 min | 0 min | ⭐⭐⭐⭐ |
| **Etapp 3 (K8s)** | Valikuline | 30+ | 2 min | 0 min | ⭐⭐⭐⭐⭐ |

**Võtmepunkt:** Paljud ettevõtted jäävad **Etapp 2B** juurde ja see on OK!

---

**Viimane uuendus:** 2025-12-11
```

---

#### Failinimetus ja Asukoht

**Fail:** `/labs/02-docker-compose-lab/LEGACY-TO-KUBERNETES-ROADMAP.md`

**Seotud failid:**
- `README.md` - Viitab sellele failile (lühike ülevaade + link)
- `EXERCISE-UPDATES-PLAN.md` - See fail (implementeerimise plaan)

---

#### Testimine

Kontrolli:
- [ ] Gradle multi-stage build näited töötavad
- [ ] Tomcat WAR deployment näited töötavad
- [ ] Spring Boot embedded Tomcat näited töötavad
- [ ] ENV vars asendavad server.xml/context.xml config'i
- [ ] docker-compose.{test,prod}.yml pattern on selge
- [ ] Ajad on realistlikud (3-6 kuud per etapp)

---

### 📝 LAB 2 ENVIRONMENTS.MD

**Fail:** `README-ENVIRONMENTS.md` (Lab 2 juurkataloogis)

**Eesmärk:**
Ühtne viide kõikidele keskkondadele ja nende kasutamisele

---

#### Sisu

```markdown
# Lab 2: Keskkondade Haldamine - Ülevaade

**Eesmärk:** Selles dokumendis on ühtne ülevaade kõikidest keskkondadest (dev, test, prelive, prod) ja nende kasutamisest Lab 2 harjutustes.

---

## 🎯 Keskkondade Mudel

Lab 2 kasutab **4-keskkonna arhitektuuri**:

| Keskkond | Fail Pattern | Kasutus | Harjutus |
|----------|--------------|---------|----------|
| **Local Dev** | `docker-compose.override.yml` | Automaatne (local dev) | Harjutus 1-3 |
| **TEST** | `docker-compose.test.yml + .env.test` | Käsitsi (debugging) | Harjutus 4+ |
| **PRELIVE** | `docker-compose.prelive.yml + .env.prelive` | Käsitsi (prod test) | Harjutus 6+ |
| **PRODUCTION** | `docker-compose.prod.yml + .env.prod` | Käsitsi (live) | Harjutus 6, 9 |

---

## 📋 Detailne Viide

### Põhiline Pattern

```
compose-project/
├── docker-compose.yml              # BASE (kõigile ühine)
├── docker-compose.test.yml         # TEST overrides
├── docker-compose.prelive.yml      # PRELIVE overrides
├── docker-compose.prod.yml         # PRODUCTION overrides
│
├── .env.test.example               # TEST template (git'is)
├── .env.prelive.example            # PRELIVE template (git'is)
├── .env.prod.example               # PRODUCTION template (git'is)
│
├── .env.test                       # TEST secrets (git ignore)
├── .env.prelive                    # PRELIVE secrets (git ignore)
└── .env.prod                       # PRODUCTION secrets (git ignore)
```

---

## 🚀 Kasutamine

### LOCAL DEV (Harjutus 1-3)

```bash
# Automaatne (docker-compose.override.yml laetakse)
docker-compose up -d

# Kõik pordid avatud localhost'ile
# Andmebaasid: localhost:5432, localhost:5433
```

### TEST (Harjutus 4+)

```bash
# 1. Loo .env.test
cp .env.test.example .env.test

# 2. Käivita
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d

# Features:
# - Kõik pordid avatud (debugging)
# - Debug logging
# - Lihtsamad paroolid
```

### PRODUCTION (Harjutus 6, 9)

```bash
# 1. Loo .env.prod ja muuda paroole
cp .env.prod.example .env.prod
nano .env.prod

# Genereeri tugevad paroolid
openssl rand -base64 48  # POSTGRES_PASSWORD
openssl rand -base64 32  # JWT_SECRET

# 2. Käivita
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# Features:
# - Isoleeritud baaside
# - Resource limits
# - Minimal logging (warn)
# - Restart policy: always
```

---

## 📊 Võrdlus: Erinevused Keskkondade Vahel

| Aspekt | LOCAL DEV | TEST | PRELIVE | PRODUCTION |
|--------|-----------|------|---------|------------|
| **DB Pordid** | ✅ 5432, 5433 | ✅ 5432, 5433 | ❌ Isoleeritud | ❌ Isoleeritud |
| **Backend Pordid** | ✅ 3000, 8081 | ✅ 3000, 8081 | ❌ Sisevõrk | ❌ Sisevõrk |
| **Frontend Port** | 8080 | 8080 | 8080 | 80 (443 SSL) |
| **Paroolid** | `postgres` | `test123` | Tugevad | Väga tugevad (48b) |
| **JWT Secret** | Default | Test secret | Tugev | Väga tugev (32b) |
| **Logging** | INFO | DEBUG | INFO | WARN |
| **Resource Limits** | ❌ | Moderate | Strict | Very Strict |
| **Restart Policy** | unless-stopped | unless-stopped | unless-stopped | always |
| **Database Network** | internal: false | internal: false | internal: true | internal: true |
| **Health Checks** | 30s | 30s | 15s | 15s |

---

## 📚 Viited

### Harjutused
- **Harjutus 4:** Environment Management (õpetab pattern'i)
- **Harjutus 5:** Database Migrations (env-spetsiifilised migrations)
- **Harjutus 6:** Production Patterns (prod override)
- **Harjutus 7:** Monitoring (env-spetsiifilised health checks)
- **Harjutus 8:** Legacy Integration (tier2 multi-env)
- **Harjutus 9:** Production Readiness (täielik prod stack)

### Dokumendid
- **compose-project/ENVIRONMENTS.md:** Detailne ülevaade 4 keskkonnast
- **compose-project/PASSWORDS.md:** Paroolide turvalisus ja haldamine

---

**Viimane uuendus:** 2025-12-11
```

---

## ✅ Testimise Plaan

### Testimise Järjekord

1. **Harjutus 4** (alus)
   - Loo `.env.{test,prod}.example` failid
   - Testi composite käske
   - Kontrolli, et pordid on õigesti avatud/isoleeritud

2. **Harjutus 5** (sõltub 4'st)
   - Testi Liquibase env var'idega
   - Kontrolli migrations TEST ja PROD keskkonnas

3. **Harjutus 6** (sõltub 4'st)
   - Testi prod override'i
   - Kontrolli resource limits

4. **Harjutus 7** (sõltub 6'st)
   - Testi health check intervalle
   - Kontrolli Prometheus retention

5. **Harjutus 8** (sõltub 4'st)
   - Testi tier2 multi-env
   - Kontrolli legacy integration

6. **Harjutus 9** (sõltub 6'st)
   - Testi täielik production stack
   - Kontrolli SSL, monitoring, HA

7. **Lab 2 ENVIRONMENTS.md**
   - Kontrolli, et viited töötavad
   - Testi kõik näidiskäsud

---

## 🔍 Kvaliteedikontroll

### Checklist

Iga harjutuse jaoks:
- [ ] Multi-environment pattern järgitud
- [ ] Composite käsud õigesti kasutatud
- [ ] `.env.{env}.example` failid olemas
- [ ] `.gitignore` kaitseb secreteid
- [ ] Viited teistele harjutustele ja dokumentidele õiged
- [ ] Kõik käsud testitud
- [ ] Kokkuvõte uuendatud

Lab 2 üldine:
- [ ] Harjutused 1-3 jäid muutmata
- [ ] Harjutused 4-9 järgivad sama pattern'i
- [ ] ENVIRONMENTS.md viitab kõikidele harjutustele
- [ ] compose-project/ näidis töötab

---

## 📝 Märkmed

### Kriitilised Otsused

1. **Harjutused 1-3 jäävad muutmata**
   - Pedagoogiline progressioon: lihtne → keeruline
   - Single-file approach sobib algajatele

2. **Harjutus 4 loob aluse**
   - Õpetab multi-environment pattern'i
   - Kõik järgnevad harjutused kasutavad seda

3. **compose-project/ on referents**
   - Näitab töötavat näidist
   - Harjutused viitavad sellele

4. **Järjepidevus on võti**
   - Kõik harjutused järgivad sama mudelit
   - Terminoloogia on ühtne

---

**Plaani looja:** Claude Sonnet 4.5
**Kuupäev:** 2025-12-11
**Staatus:** PLAAN (rakendamine järgnevalt)
**Järgmine samm:** Alusta Harjutus 4 uuendamisest
