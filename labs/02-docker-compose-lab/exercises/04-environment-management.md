# Harjutus 4: Keskkondade haldus (.env ja muutujad)

**Eesmärk:** Halda keskkonnamuutujaid .env failidega turvaliselt

---

## 📋 Harjutuse ülevaade

Selles harjutuses õpid eraldama saladused docker-compose.yml failist ja haldama neid turvaliselt `.env` failidega. Samuti õpid kasutama **multi-file pattern'i** (4 tüüpi override faile) erinevate keskkondade (dev, test, prod) jaoks.

**Probleem praegu:**

- ❌ Saladused (JWT_SECRET, DB_PASSWORD) on "hardcoded" docker-compose.yml'is
- ❌ Sama konfiguratsioon arendus- (dev) ja toote- (prod) keskkondade jaoks
- ❌ Raske jagada docker-compose.yml ilma saladusteta

**Lahendus:**

- ✅ .env failid saladuste haldamiseks (.env.test, .env.prod)
- ✅ Multi-file pattern (docker-compose.test.yml, docker-compose.prod.yml, docker-compose.override.yml)
- ✅ Versioonihaldus (.env.example, mitte .env)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua ja kasutada **.env faile**
- ✅ Kasutada **keskkonnamuutujaid (environment variables)** `docker-compose.yml` failis
- ✅ Implementeerida **multi-file pattern'i** (4 tüüpi override faile: test.yml, prod.yml, override.yml)
- ✅ Eraldada arenduse (dev), testimise (test) ja toote keskkonna (prod) konfiguratsioone
- ✅ Turvaliselt kasutada **versioonihaldust (version control)** (`.gitignore`)
- ✅ Jagada **malle (templates)** (`.env.example`)

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Harjutus 3 tulemus on olemas:**

```bash
# 1. Mine töökausta
cd ~/labs/02-docker-compose-lab/compose-project

# 2. Kontrolli, kas Harjutus 3 failid on olemas
ls -la docker-compose.yml nginx.conf
```

**Kui failid PUUDUVAD (Harjutus 3 pole läbitud):**

```bash
# VARIANT A: Kopeeri Harjutus 3 lahendus (kiire start)
cp ../solutions/03-network-segmentation/docker-compose.secure.yml docker-compose.yml
cp ../solutions/03-network-segmentation/nginx.conf .

# VARIANT B: Läbi Harjutus 3 esmalt
# 🔗 [Harjutus 3: Võrgu segmenteerimine](03-network-segmentation.md)
```

**Kontrolli, et docker-compose.yml sisaldab hardcoded väärtusi:**

```bash
# Peaks nägema hardcoded väärtusi (mitte ${VAR})
grep "JWT_SECRET\|DB_PASSWORD" docker-compose.yml

# Oodatud tulemus:
#   DB_PASSWORD: postgres
#   JWT_SECRET: VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
```

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📝 Sammud

### Samm 1: Analüüsi praegust probleemi

Vaata praegust docker-compose.yml faili (Harjutus 3 lõpptulemus):

```bash
cat docker-compose.yml | grep -A 3 "JWT_SECRET"
```

**Näed:**
```yaml
# user-service:
JWT_SECRET: VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=

# todo-service:
JWT_SECRET: VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
```

**Samuti vaata andmebaasi paroole:**
```bash
cat docker-compose.yml | grep "DB_PASSWORD"
```

**Näed:**
```yaml
DB_PASSWORD: postgres
```

**Probleemid:**

- ❌ Saladused on hardcoded (nähtavad failis)
- ❌ Sama parool kõikides keskkondades (dev, test, prod)
- ❌ Kui commit'id Git'i, saladus on avalik
- ❌ Raske muuta (pead muutma 4 kohas: user-service, todo-service, postgres-user, postgres-todo)

---

### Samm 2: Loo .env.test.example template

**Eesmärk:** Loo template fail (.env.test.example), mis sisaldab kõiki vajalikke keskkonnamuutujaid. Seda saab kasutada näidisena teiste keskkondade .env failide loomiseks.

Loo `.env.test.example` fail:

```bash
vim .env.test.example
```

Lisa järgmine sisu:

```bash
# ==========================================================================
# TEST Environment Variables Template
# ==========================================================================
# See on TEMPLATE fail, mida saab kasutada aluseks:
#   - TEST keskkond: cp .env.test.example .env.test
#   - PROD keskkond: cp .env.test.example .env.prod (muuda seadistusi!)
#
# ⚠️ TÄHTIS: .env.test ja .env.prod failid sisaldavad saladusi!
#            EI TOHI commit'ida Git'i! Lisa .gitignore'i!
# ==========================================================================

# PostgreSQL Credentials
# MÄRKUS: Kasutab Docker Compose teenuseid (service names):
#   - postgres-user:5432  (User Service andmebaas)
#   - postgres-todo:5432  (Todo Service andmebaas)
# Parool peab olema SAMA mis Harjutus 3's (volume'id säilitavad seda!)
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Database Names
USER_DB_NAME=user_service_db
TODO_DB_NAME=todo_service_db

# JWT Configuration
# ⚠️ OLULINE: PEAB olema Base64 encoded, min 256-bit (32 bytes)!
# Spring Boot JwtTokenProvider nõuab tugevat Base64 secret'i.
# Lihtne string "test-secret-not-for-production" EI TÖÖTA - põhjustab crash'i!
#
# TEST keskkond: kasuta sama secret'i mis Harjutus 3's (volume'id säilitavad seda)
# PRODUCTION: genereeri UUS tugev secret: openssl rand -base64 32
JWT_SECRET=VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=
JWT_EXPIRES_IN=1h

# Application Ports
USER_SERVICE_PORT=3000
TODO_SERVICE_PORT=8081
FRONTEND_PORT=8080
POSTGRES_USER_PORT=5432
POSTGRES_TODO_PORT=5433

# Node.js Environment
NODE_ENV=development

# Java Options
JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0

# Spring Profile
SPRING_PROFILE=dev

# Logging
LOG_LEVEL=debug
SPRING_LOG_LEVEL=DEBUG
```

Salvesta: `Esc`, siis `:wq`, `Enter`

**📖 Põhjalik koodi selgitus:**

Kui vajad `.env` faili täpset selgitust (miks seda kasutatakse, kuidas Docker Compose seda loeb, turvalisus), loe:
- 👉 **[Koodiselgitus: Docker Compose .env File](../../../resource/code-explanations/Docker-Compose-Env-File-Explained.md)**

**💡 Mida õppisid:**
- ✅ Template fail on alus kõigile keskkondadele
- ✅ Commit'id Git'i `.env.test.example` (template), MITTE `.env.test` (saladused)
- ✅ Järgmises sammus lood `.env.test` faili template'i alusel

---

### Samm 3: Loo .env.test fail template'ist

**Eesmärk:** Kopeeri template fail ja veendu, et see sisaldaks TEST keskkonna väärtuseid

Kopeeri template fail:

```bash
# Kopeeri .env.test.example → .env.test
cp .env.test.example .env.test
```

**Kontrolli, et fail loodi:**

```bash
ls -la .env.test
# Peaks nägema: .env.test (sama sisu mis .env.test.example)
```

**💡 Mida õppisid:**
- ✅ `.env.test` fail on valmis TEST keskkonna jaoks
- ✅ Ei pea käsitsi muutma (kasutab Harjutus 3 väärtusi)
- ✅ Järgmises sammus õpid, kuidas luua PRODUCTION keskkonnal erinev `.env.prod` fail

---

### Samm 4: Uuenda docker-compose.yml (BASE config)

**Eesmärk:** Nüüd kui .env.test fail on olemas, muuda olemasolev `compose-project/docker-compose.yml` fail kasutama neid muutujaid.

Ava olemasolev docker-compose.yml fail:

```bash
vim docker-compose.yml
```

**Asenda "hardcoded" väärtused `${VARIABLE}` süntaksiga:**

```yaml
# Näide: PostgreSQL
postgres-user:
  environment:
    POSTGRES_DB: ${USER_DB_NAME}             # .env failist
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # .env failist (oli: postgres)

# Näide: User Service
user-service:
  environment:
    JWT_SECRET: ${JWT_SECRET}                # .env failist (oli: VXCkL39y...)
    DB_PASSWORD: ${POSTGRES_PASSWORD}        # .env failist
    NODE_ENV: ${NODE_ENV}                    # .env failist
```

**TÄHTIS:**
- Jäta võrgud samaks nagu Harjutus 3's! (frontend-network, backend-network, database-network)
- Asenda kõik hardcoded väärtused: `POSTGRES_PASSWORD`, `JWT_SECRET`, `USER_DB_NAME`, jne
- Kasuta `${VARIABLE}` süntaksit

**📖 Täielik näidisfail:**

Vaata täielikku näidisfaili solution kaustas:

```bash
cat ../solutions/04-environment-management/docker-compose.yml
```

Salvesta: `Esc`, siis `:wq`, `Enter`

**Testi, et BASE config kasutab .env.test faili:**

```bash
# Kontrolli, et muutujad substituteeruvad õigesti (.env.test fail loetakse automaatselt)
docker compose config | grep JWT_SECRET
# Peaks nägema: JWT_SECRET: VXCkL39yz/6xw7JFpHdLpP8xgBFUSKbnNJWdAaeWDiM=

docker compose config | grep POSTGRES_PASSWORD
# Peaks nägema: POSTGRES_PASSWORD: postgres

# Kontrolli, et võrgud on samad nagu Harjutus 3's
docker compose config | grep -A 5 "^networks:"
# Peaks nägema: frontend-network, backend-network, database-network
```

**💡 Mida õppisid:**
- ✅ BASE config kasutab `${VARIABLE}` süntaksit
- ✅ `.env.test` fail täidab need muutujad
- ✅ Saad testida kohe (docker compose config)
- ✅ Järgmises sammus õpid multi-environment pattern'i (TEST vs PROD)

---

### Samm 5: Multi-Environment Setup (30 min)

**Eesmärk:** Nüüd kui BASE config on olemas, õpi eraldama TEST ja PRODUCTION keskkondade konfiguratsioone.

#### 5.1. Best Practice: Multi-File Pattern (4 Tüüpi Override Faile)

**Docker Compose toetab mitut override faili tüüpi:**

```
compose-project/
├── docker-compose.yml              # BASE (kõigile ühine)
│
├── docker-compose.test.yml         # TEST overrides (explicit -f flag)
├── docker-compose.prelive.yml      # PRELIVE overrides (explicit -f flag)
├── docker-compose.prod.yml         # PRODUCTION overrides (explicit -f flag)
├── docker-compose.override.yml     # LOCAL DEV overrides (AUTOMAATNE, VALIKULINE)
│
├── .env.test.example               # TEST template
├── .env.prelive.example            # PRELIVE template
└── .env.prod.example               # PRODUCTION template
```

**4 Faili Tüüpi:**

| Fail | Käivitamine | Kasutus | Git Commit? |
|------|-------------|---------|-------------|
| **docker-compose.yml** | Alati (BASE) | Ühine config (services, networks, volumes) | ✅ Jah |
| **docker-compose.test.yml** | `-f docker-compose.yml -f docker-compose.test.yml` | TEST: pordid avatud, debug logging | ✅ Jah |
| **docker-compose.prod.yml** | `-f docker-compose.yml -f docker-compose.prod.yml` | PRODUCTION: isoleeritud, resource limits | ✅ Jah |
| **docker-compose.override.yml** | Automaatne (kui eksisteerib) | LOCAL DEV: hot reload, volumes | ⚠️ Valikuline |

**Põhimõte:**
1. **BASE** = Ühine konfiguratsioon (kõik teenused, võrgud, volumes)
2. **EXPLICIT OVERRIDES** = Keskkonna-spetsiifilised (test.yml, prod.yml) - kasutatakse `-f` flagiga
3. **AUTOMATIC OVERRIDE** = `docker-compose.override.yml` - laetakse automaatselt, VALIKULINE
4. **ENV FILES** = Paroolid ja saladused (git ignore!)

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

#### 5.2. Loo Override Failid

Selles sammus loome 3 override faili (vaata Samm 5.1 tabelit):

1. ✅ **docker-compose.test.yml** (TEST) - Kohustuslik
2. ✅ **docker-compose.prod.yml** (PRODUCTION) - Kohustuslik
3. ⚠️ **docker-compose.override.yml** (LOCAL DEV) - VALIKULINE

---

##### 5.2.1. TEST Override (docker-compose.test.yml)

Loo **docker-compose.test.yml**:

```bash
vim docker-compose.test.yml
```

Lisa sisu:

```yaml
# ==========================================================================
# Docker Compose - TEST Environment Overrides
# ==========================================================================
# Käivitamine:
#   docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d
# ==========================================================================

services:
  postgres-user:
    ports:
      - "127.0.0.1:5432:5432"  # Ava port debugging'uks

  postgres-todo:
    ports:
      - "127.0.0.1:5433:5432"  # Ava port debugging'uks

  user-service:
    environment:
      NODE_ENV: development
      LOG_LEVEL: debug
    ports:
      - "127.0.0.1:3000:3000"  # Ava port debugging'uks

  todo-service:
    environment:
      SPRING_PROFILES_ACTIVE: dev
      LOGGING_LEVEL_ROOT: DEBUG
    ports:
      - "127.0.0.1:8081:8081"  # Ava port debugging'uks

networks:
  database-network:
    internal: false  # Luba host ligipääs (andmebaasidele DBeaver'iga)
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

##### 5.2.2. PRODUCTION Override (docker-compose.prod.yml)

Loo **docker-compose.prod.yml**:

```bash
vim docker-compose.prod.yml
```

Lisa sisu:

```yaml
# ==========================================================================
# Docker Compose - PRODUCTION Environment Overrides
# ==========================================================================
# Käivitamine:
#   docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
# ==========================================================================

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
      - "80:80"  # HTTP (production port)
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

##### 5.2.3. LOCAL DEV Override (docker-compose.override.yml) - VALIKULINE

**💡 Viide:** See on 4. override faili tüüp, mida käsitleti Samm 5.1-s (Multi-File Pattern).

**Märkus:** See samm on VALIKULINE. Kui ei tee aktiivset arendust (volume mounts, hot reload), võid vahele jätta.

**Millal kasutada:**
- ✅ **docker-compose.override.yml** - Kui teed aktiivset arendust (hot reload, volume mounts, `npm run dev`)
- ✅ **docker-compose.test.yml** - Kui testid teenuseid (stabiilsed image'd, debugging pordid)

**Erinevus:**

| Aspekt | override.yml (5.2.3) | test.yml (5.2.1) |
|--------|----------------------|------------------|
| **Käivitamine** | `docker-compose up -d` (automaatne) | `-f docker-compose.yml -f docker-compose.test.yml` (explicit) |
| **Kasutus** | Aktiivne arendus (volume mounts, hot reload) | Testimine (built images, pordid avatud) |
| **Git Commit** | ⚠️ Valikuline (sõltub workflow'st) | ✅ Jah (team-wide config) |

Loo override fail development seadistustele:

```bash
vim docker-compose.override.yml
```

Lisa:

```yaml
# ==========================================================================
# Docker Compose Override - Development Environment
# ==========================================================================
# See fail rakendub automaatselt üle docker-compose.yml
# Kasutamine:
#   docker compose up -d  # Rakendab nii docker-compose.yml kui override.yml
# ==========================================================================

# MÄRKUS: Docker Compose v2 (2025)
# version: '3.8' on VALIKULINE (optional) Compose v2's!
# Võid selle ära jätta - Compose v2 kasutab automaatselt uusimat versiooni.
#version: '3.8'

services:
  user-service:
    environment:
      NODE_ENV: development
      LOG_LEVEL: debug
    # Development volume mount (hot reload)
    volumes:
      - ../../apps/backend-nodejs:/app
    # Override command for development
    command: npm run dev

  todo-service:
    environment:
      SPRING_PROFILES_ACTIVE: dev
      LOGGING_LEVEL_ROOT: DEBUG

  frontend:
    # Development: enable directory listing for debugging (veatuvastus)
    # (Remove :ro to allow writing)
    volumes:
      - ../../apps/frontend:/usr/share/nginx/html
```

Salvesta: `Esc`, siis `:wq`, `Enter`

**Testimine:**

```bash
# Ilma override'ita (production mode)
docker compose -f docker-compose.yml up -d

# Override'iga (development mode)
docker compose up -d  # Rakendab mõlemat

# Vaata, mis konfiguratsioon rakendus
docker compose config
```

---

#### 5.3. Loo .env.prod fail PRODUCTION keskkonna jaoks

**Eesmärk:** Loo PRODUCTION keskkonna .env fail template'i alusel ja muuda ainult vajalikke seadistusi.

**Märkus:** `.env.test.example` template loodi juba Samm 2's. Kasuta seda aluseks PRODUCTION keskkonna jaoks.

Loo `.env.prod` fail template'i alusel:

```bash
# 1. Kopeeri template → .env.prod
cp .env.test.example .env.prod

# 2. Genereeri tugev JWT_SECRET PRODUCTION'i jaoks
openssl rand -base64 32

# 3. Muuda .env.prod failis järgmised väärtused
vim .env.prod
```

**Muuda `.env.prod` failis järgmised read:**

```bash
# Muuda JWT_SECRET → uus väärtus openssl'ist (erinev TEST'ist!)
JWT_SECRET=<kopeeri openssl rand -base64 32 tulemus siia>

# Muuda logging tasemed → production level
LOG_LEVEL=warn
SPRING_LOG_LEVEL=WARN

# Muuda environment → production
NODE_ENV=production
SPRING_PROFILE=prod

# POSTGRES_PASSWORD jääb samaks: postgres (harjutuse lihtsustus)
# 📚 HARJUTUSE LIHTSUSTUS: sama DB parool kui TEST'is
#    Põhjus: Sama volume → PostgreSQL ignoreerib uut parooli
# 🏢 REAALSES PRODUCTION'IS: eraldi server → erinev tugev parool!
```

**Näide täielikust `.env.prod` failist:**

Vaata täielikku näidisfaili solution kaustas:

```bash
cat ../solutions/04-environment-management/.env.prod.example
```

Salvesta: `Esc`, siis `:wq`, `Enter`

**💡 Mida õppisid:**
- ✅ Kasutad sama template'i (`.env.test.example`) aluseks kõigile keskkondadele
- ✅ Muudad ainult keskkonnapõhiseid seadistusi (JWT_SECRET, LOG_LEVEL, NODE_ENV)
- ✅ Ei pea kopeerima tervet faili käsitsi (vähem vigu)
- ✅ Template on commit'itud Git'i, `.env.prod` on ignored

---

#### 5.4. Uuenda .gitignore

```bash
vim .gitignore
```

Asenda sisu:

```
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

# Logs
*.log

# OS files
.DS_Store
Thumbs.db
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

#### 5.5. Kasutamine: Composite Commands

**TEST Keskkond:**

```bash
# 1. Loo .env.test fail template'ist
cp .env.test.example .env.test

# 2. Käivita TEST keskkonnaga
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d

# 3. Kontrolli
docker ps
docker-compose -f docker-compose.yml -f docker-compose.test.yml logs -f

# 4. Ühenda andmebaasidega (DBeaver - TEST keskkonnas pordid on avatud!)
# MÄRKUS: Ühenda õige keskkonna andmebaasiga:
#   - TEST: localhost:5432 ja localhost:5433 (pordid avatud)
#   - PROD: Andmebaasid isoleeritud (pordid suletud, internal network)
#
# User DB: localhost:5432
#   Host: localhost, Port: 5432
#   Database: user_service_db
#   Username: postgres
#   Password: postgres  (sama mis .env.test failis!)
#
# Todo DB: localhost:5433
#   Host: localhost, Port: 5433
#   Database: todo_service_db
#   Username: postgres
#   Password: postgres  (sama mis .env.test failis!)
```

**PRODUCTION Keskkond:**

```bash
# 1. Loo .env.prod fail
cp .env.prod.example .env.prod

# 📚 HARJUTUSES: Kasutame sama parooli mis TEST'is (postgres)
# 🏢 REAALSES ELUS: Kasutaksid ERINEVAT tugevat parooli eraldi serveris!

# VALIKULINE: Genereeri tugev JWT_SECRET (erinev TEST'ist)
STRONG_JWT=$(openssl rand -base64 32)
sed -i "s/8K+9fR3mL7vN2pQ6xW1yZ4tH5jB0cE8fG9aD3sK7mL1=/$STRONG_JWT/" .env.prod

# 2. Käivita PRODUCTION keskkonnaga
# MÄRKUS: Kasutab samu volume'id mis TEST (harjutuse lihtsustus!)
# Reaalses elus: Eraldi server → eraldi volume'id → erinevad paroolid
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# 3. Kontrolli teenuseid
docker ps  # Vaata (healthy) staatust
docker stats  # Vaata resource kasutust

# ❌ Andmebaasid ei ole kättesaadavad host'ilt (isoleeritud - internal network)
# ✅ Ainult frontend port 80 on avatud
```

---

#### 5.6. Võrdlus: Erinevused Keskkondade Vahel

| Aspekt | TEST | PRODUCTION |
|--------|------|------------|
| **DB Pordid** | ✅ 5432, 5433 (localhost) | ❌ Isoleeritud (internal network) |
| **Backend Pordid** | ✅ 3000, 8081 (localhost) | ❌ Sisevõrk ainult |
| **Frontend Port** | 8080 | 80 (või 443 SSL'iga) |
| **DB Paroolid** | `postgres` (harjutuses sama) | `postgres` (harjutuses sama¹) |
| **JWT Secret** | `VXCkL39yz...` (Base64, 256-bit) | ERINEV tugev hash (32+ bytes, `openssl rand -base64 32`) |
| **Logging** | DEBUG (verbose) | WARN (minimal) |
| **Resource Limits** | ❌ Pole | ✅ Strict (CPU, memory) |
| **Restart Policy** | unless-stopped | always |
| **Database Network** | internal: false | internal: true |

**¹ Märkus:** Harjutuses kasutame sama DB parooli, sest kasutame samu volume'id. Reaalses production keskkonnas oleksid eraldi serverid → eraldi volume'id → ERINEVAD tugevad paroolid!

---

#### 5.7. Alias'ed (Valikuline)

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

---

#### ✅ Kontrollküsimused

1. Miks ei saa kasutada sama `.env` faili test ja production'is?
2. Miks `docker-compose.override.yml` ei sobi production'i?
3. Kuidas käivitada teenuseid TEST keskkonnaga?
4. Kuidas genereerida tugevaid paroole production'i jaoks?
5. Mis vahe on BASE config'il ja OVERRIDE config'il?

---

### Samm 6: Valideeri ja Testi Multi-Environment Setup (10 min)

**TEST Keskkond:**

```bash
# 1. Loo .env.test fail (kui pole veel)
cp .env.test.example .env.test

# 2. Käivita TEST keskkonnaga
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d

# 3. Kontrolli
docker ps
docker compose -f docker-compose.yml -f docker-compose.test.yml logs

# Kontrolli, et andmebaasi pordid on avatud
docker ps | grep postgres
# Peaks nägema: 127.0.0.1:5432->5432/tcp ja 127.0.0.1:5433->5432/tcp

# 4. Testi API'd
curl http://localhost:3000/health  # User Service
curl http://localhost:8081/health  # Todo Service

# 5. Registreeri kasutaja (peaks töötama)
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"test123"}'
```

**Cleanup (valikuline):**

```bash
# Seiska TEST keskkond
docker-compose -f docker-compose.yml -f docker-compose.test.yml down

# Või kui tahad andmed säilitada:
docker-compose -f docker-compose.yml -f docker-compose.test.yml stop
```

---

## 📚 Täiendavad Juhendid

### Keskkondade Haldamine (Multi-Environment)

👉 **Detailne juhend:** [solutions/04-environment-management/ENVIRONMENTS.md](../solutions/04-environment-management/ENVIRONMENTS.md)

**Sisaldab:**
- 3 keskkonna võrdlus (local dev, test, prod)
- Composite käskude näited
- Alias'ed (.bashrc)
- Troubleshooting
- Harjutuse lihtsustus vs reaalse elu praktika

### Paroolide ja Saladuste Turvalisus

👉 **Turvalisuse juhend:** [solutions/04-environment-management/PASSWORDS.md](../solutions/04-environment-management/PASSWORDS.md)

**Sisaldab:**
- JWT Secret'i genereerimine (openssl)
- `.env` failide turvalisus
- Harjutuse lihtsustus (sama DB parool)
- Reaalse production praktika
- Troubleshooting

---

## ✅ Kontrolli tulemusi

Peale selle harjutuse läbimist peaksid omama:

### Failid (Multi-Environment Setup):
- [ ] **docker-compose.yml** - BASE config (env vars: `${VAR:-default}`)
- [ ] **docker-compose.test.yml** - TEST overrides (Samm 5.2.1)
- [ ] **docker-compose.prod.yml** - PRODUCTION overrides (Samm 5.2.2)
- [ ] **docker-compose.override.yml** - LOCAL DEV overrides (Samm 5.2.3 - VALIKULINE)
- [ ] **.env.test.example** - TEST template (commit'itud, Samm 2)
- [ ] **.env.test** - TEST secrets (git ignored, lokaalselt loodud, Samm 3)
- [ ] **.env.prod** - PRODUCTION secrets (git ignored, lokaalselt loodud, Samm 5.3)
- [ ] **.gitignore** - Actual .env files ignored
- [ ] **ENVIRONMENTS.md** viide olemas
- [ ] **PASSWORDS.md** viide olemas

### Oskused:
- [ ] Oskad käivitada TEST keskkonda: `docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d`
- [ ] Oskad käivitada PROD keskkonda: `docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d`
- [ ] Mõistad BASE + OVERRIDE pattern'i
- [ ] Oskad genereerida tugevaid paroole (openssl rand -base64)
- [ ] **End-to-End töövoog** toimib

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas .env.test fail eksisteerib?
ls -la .env.test
# Peaks nägema .env.test faili

# 2. Kas .env.test loetakse?
docker compose config | grep JWT_SECRET
# Peaks nägema .env.test'ist väärtust

# 3. Kas .gitignore toimib?
git status
# .env.test EI PEAKS olema nimekirjas (ainult .env.test.example)

# 4. Kas override rakendub (TEST keskkond)?
docker compose -f docker-compose.yml -f docker-compose.test.yml config | grep NODE_ENV
# TEST mode'is peaks olema: NODE_ENV: development
```

---

## 🎓 Õpitud Mõisted

### .env Fail:

```bash
# Süntaks:
VARIABLE_NAME=value

# Docker Compose kasutamine:
${VARIABLE_NAME}

# Vaikeväärtus (Default value):
${VARIABLE_NAME:-default_value}
```

### Multi-Environment Pattern (Best Practice):

**Multi-File Pattern (4 Tüüpi):**
1. **BASE** = `docker-compose.yml` (ühine config, env vars: `${VAR:-default}`)
2. **EXPLICIT OVERRIDES** = `docker-compose.{env}.yml` (test.yml, prod.yml - käivitamine `-f` flagiga)
3. **AUTOMATIC OVERRIDE** = `docker-compose.override.yml` (local dev - automaatne, VALIKULINE)
4. **SECRETS** = `.env.{env}` failid (paroolid, git ignored!)

**Composite käsud:**
```bash
docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
```

**Alias'ed:**
```bash
alias dc-test='docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test'
alias dc-prod='docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod'
```

### Volume'id ja Paroolid (Harjutuse lihtsustus):

**Selles harjutuses:**
- ✅ TEST ja PROD kasutavad **samu volume'id** (`postgres-user-data`, `postgres-todo-data`)
- ✅ Sama DB parool mõlemas keskkonnas: `postgres`
- ✅ ERINEV JWT_SECRET (TEST vs PROD)

**Põhjus:**
- Sama volume → PostgreSQL ignoreerib teist parooli (juba initsialiseeritud)
- Lihtsam harjutuseks (fokus: multi-environment pattern, mitte volume haldus)

**🏢 Reaalses production keskkonnas:**

```
Test Server (test.company.com):
  └─ Volume: /mnt/postgres-data-test
  └─ Parool: test_password_123

Production Server (prod.company.com):
  └─ Volume: /mnt/postgres-data-prod  ← ERINEV server, ERINEV volume!
  └─ Parool: Sx8K3mL9pQ2vN7wR5t...    ← TUGEV, ERINEV parool!
```

**Tulemus:**
- ✅ Harjutuses: Õpid multi-environment pattern'i (compose failid, .env failid)
- ✅ Reaalses elus: Eraldi serverid → eraldi volume'id → erinevad paroolid

### docker-compose.override.yml (Lokaalne Dev):

**📖 Vaata:** Samm 5.2.3 (LOCAL DEV Override) - VALIKULINE

- Rakendub **automaatselt** peale docker-compose.yml (kui fail eksisteerib)
- Kasutatakse lokaalseks development'iks (hot reload, volume mounts)
- VALIKULINE (ei ole vajalik multi-environment setup'is)
- Ei commit'i Git'i (optional - sõltub workflow'st)

### Versioonihaldus Best Practices:

✅ **Commit Git'i:**

- `docker-compose.yml` (BASE config)
- `docker-compose.test.yml` (TEST overrides)
- `docker-compose.prod.yml` (PRODUCTION overrides)
- `.env.test.example` (TEST template - Samm 2)
- `.gitignore`

❌ **EI commit Git'i:**

- `.env.test`, `.env.prod` (sisaldavad päris paroole!)
- `docker-compose.override.yml` (optional lokaalne dev)

**💡 Märkus:**
- `.env.test.example` on template, mida kasutad aluseks nii TEST kui PROD keskkondade jaoks
- `.env.prod.example` on näidisfail solution kaustas (täielik näide)

---

## 💡 Parimad tavad

### Multi-Environment Setup:

1. **Ära kunagi commit'i .env faile** - Lisa .gitignore'i (`.env.test`, `.env.prod`)
2. **Commit template fail** - `.env.test.example` (template kõigile keskkondadele)
3. **Genereeri tugevad saladused PRODUCTION'is** - JWT_SECRET peab olema juhuslik (openssl rand -base64 32)
4. **Kasuta template'i aluseks** - Kopeeri `.env.test.example` → `.env.prod`, muuda ainult vajalikud seadistused
5. **Kasuta ERINEVAID JWT_SECRET'e** - Test vs Prod (KUNAGI mitte sama secret!)
6. **Dokumenteeri template fail** - Lisa kommentaarid ja näited (`.env.test.example`)
7. **Multi-server setup** - Iga server kasutab oma `.env.{env}` faili, sama git repo
8. **Alias'ed** - Lisa `~/.bashrc`: `alias dc-test='...'`, `alias dc-prod='...'`

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd haldad saladusi turvaliselt multi-environment pattern'iga.

**Mis õppisid:**

- ✅ `.env.test.example` template loomine (ühine alus kõigile keskkondadele)
- ✅ Template'i kasutamine keskkondade jaoks (cp .env.test.example → .env.test/prod)
- ✅ Multi-file pattern (4 tüüpi override faile: BASE + test.yml + prod.yml + override.yml)
- ✅ Composite käsud (`-f docker-compose.yml -f docker-compose.test.yml --env-file .env.test`)
- ✅ Environment-spetsiifilised konfiguratsioonid (test vs prod)
- ✅ docker-compose.override.yml automaatne käitumine (VALIKULINE local dev)
- ✅ Tugevate paroolide genereerimine (openssl rand -base64 32)
- ✅ Multi-server deployment muster
- ⏭️ **Järgmine:** Andmebaasi migratsioonid (Liquibase)

**Jätka:** [Harjutus 5: Andmebaasi migratsioonid](05-database-migrations.md)

---

## 📚 Viited

- [Docker Compose environment variables](https://docs.docker.com/compose/environment-variables/)
- [Compose file .env file](https://docs.docker.com/compose/env-file/)
- [Docker Compose override](https://docs.docker.com/compose/extends/)
- [Best practices for secrets](https://docs.docker.com/compose/use-secrets/)

---

**Õnnitleme! Oled õppinud turvaliselt saladusi haldama! 🎉**
