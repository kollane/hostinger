# Harjutus 3: Environment Management

**Kestus:** 45 minutit
**Eesmärk:** Halda keskkonna muutujaid (environment variables) .env failidega turvaliselt

---

## 📋 Ülevaade

Selles harjutuses õpid eraldama salajased andmed (secrets) docker-compose.yml failist ja haldama neid turvaliselt `.env` failidega. Samuti õpid kasutama `docker-compose.override.yml` pattern'i erinevate keskkondade (dev, prod) jaoks.

**Probleem praegu:**
- ❌ Salajased (JWT_SECRET, DB_PASSWORD) on hardcoded docker-compose.yml's
- ❌ Sama konfiguratsioon dev ja prod keskkondade jaoks
- ❌ Raske jagada docker-compose.yml ilma salajasteta

**Lahendus:**
- ✅ .env fail salajaste haldamiseks
- ✅ docker-compose.override.yml dev seadistuste jaoks
- ✅ Versioonihaldus (.env.example, mitte .env)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua ja kasutada .env faile
- ✅ Kasutada keskkonna muutujaid (environment variables) docker-compose.yml's
- ✅ Implementeerida docker-compose.override.yml pattern'i
- ✅ Eraldada dev ja prod konfiguratsioone
- ✅ Turvaliselt versioonihaldusega (.gitignore)
- ✅ Jagada template'eid (.env.example)

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

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Harjutus 2 on läbitud:**

```bash
# 1. Kas 5 teenust (services) töötavad?
cd compose-project
docker compose ps
# Peaks nägema 5 teenust (services)

# 2. Kas docker-compose.yml on olemas?
ls -la docker-compose.yml
```

**Kui midagi puudub:**
- 🔗 Mine tagasi [Harjutus 2](02-add-frontend.md)

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📝 Sammud

### Samm 1: Analüüsi Praegust Probleemi (5 min)

Vaata praegust docker-compose.yml faili:

```bash
cat docker-compose.yml | grep -A 3 "JWT_SECRET"
```

**Näed:**
```yaml
JWT_SECRET: shared-secret-key-change-this-in-production-must-be-at-least-256-bits
```

**Probleemid:**
- ❌ Salajane on nähtav failis
- ❌ Sama salajane dev ja prod's
- ❌ Kui commit'id Git'i, salajane on avalik
- ❌ Raske muuta (pead muutma 2 kohas: user-service ja todo-service)

---

### Samm 2: Loo .env Fail (10 min)

Loo `.env` fail salajastele:

```bash
vim .env
```

Lisa järgmine sisu:

```bash
# ==========================================================================
# Environment Variables - Docker Compose
# ==========================================================================
# TÄHTIS: See fail sisaldab salajaseid andmeid!
# EI TOHI commit'ida Git'i! Lisa .gitignore'i!
# ==========================================================================

# PostgreSQL Credentials
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secure-db-password-change-me-in-production-12345

# JWT Configuration
JWT_SECRET=super-secret-jwt-key-change-this-in-production-must-be-at-least-256-bits-long
JWT_EXPIRES_IN=1h

# Application Ports
USER_SERVICE_PORT=3000
TODO_SERVICE_PORT=8081
FRONTEND_PORT=8080
POSTGRES_USER_PORT=5432
POSTGRES_TODO_PORT=5433

# Database Names
USER_DB_NAME=user_service_db
TODO_DB_NAME=todo_service_db

# Node.js Environment
NODE_ENV=production

# Java Options
JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0

# Spring Profile
SPRING_PROFILE=prod
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 3: Uuenda docker-compose.yml (15 min)

Nüüd muuda docker-compose.yml, et kasutada .env faili muutujaid:

```bash
vim docker-compose.yml
```

**Asenda hardcoded väärtused ${VARIABLE} süntaksiga:**

```yaml
services:
  postgres-user:
    image: postgres:16-alpine
    container_name: postgres-user
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${USER_DB_NAME}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # .env'ist
    volumes:
      - postgres-user-data:/var/lib/postgresql/data
    ports:
      - "${POSTGRES_USER_PORT}:5432"  # .env'ist
    networks:
      - todo-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgres-todo:
    image: postgres:16-alpine
    container_name: postgres-todo
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${TODO_DB_NAME}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}  # .env'ist
    volumes:
      - postgres-todo-data:/var/lib/postgresql/data
    ports:
      - "${POSTGRES_TODO_PORT}:5432"  # .env'ist
    networks:
      - todo-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  user-service:
    image: user-service:1.0-optimized
    container_name: user-service
    restart: unless-stopped
    environment:
      DB_HOST: postgres-user
      DB_PORT: 5432
      DB_NAME: ${USER_DB_NAME}
      DB_USER: ${POSTGRES_USER}
      DB_PASSWORD: ${POSTGRES_PASSWORD}  # .env'ist
      JWT_SECRET: ${JWT_SECRET}  # .env'ist
      JWT_EXPIRES_IN: ${JWT_EXPIRES_IN}
      PORT: ${USER_SERVICE_PORT}
      NODE_ENV: ${NODE_ENV}
    ports:
      - "${USER_SERVICE_PORT}:${USER_SERVICE_PORT}"  # .env'ist
    networks:
      - todo-network
    depends_on:
      postgres-user:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:${USER_SERVICE_PORT}/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s

  todo-service:
    image: todo-service:1.0-optimized
    container_name: todo-service
    restart: unless-stopped
    environment:
      DB_HOST: postgres-todo
      DB_PORT: 5432
      DB_NAME: ${TODO_DB_NAME}
      DB_USER: ${POSTGRES_USER}
      DB_PASSWORD: ${POSTGRES_PASSWORD}  # .env'ist
      JWT_SECRET: ${JWT_SECRET}  # .env'ist
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILE}
      JAVA_OPTS: ${JAVA_OPTS}
    ports:
      - "${TODO_SERVICE_PORT}:${TODO_SERVICE_PORT}"  # .env'ist
    networks:
      - todo-network
    depends_on:
      postgres-todo:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:${TODO_SERVICE_PORT}/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 60s

  frontend:
    image: nginx:alpine
    container_name: frontend
    restart: unless-stopped
    ports:
      - "${FRONTEND_PORT}:80"  # .env'ist
    volumes:
      - ../../apps/frontend:/usr/share/nginx/html:ro
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

# ... volumes ja networks jäävad samaks
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 4: Loo .env.example Template (5 min)

Loo template fail, mida saab commit'ida Git'i:

```bash
vim .env.example
```

Lisa järgmine sisu (ilma päris salajasteta):

```bash
# ==========================================================================
# Environment Variables Template
# ==========================================================================
# Kopeeri see fail .env failiks ja täida päris väärtustega:
#   cp .env.example .env
#   vim .env
# ==========================================================================

# PostgreSQL Credentials
POSTGRES_USER=postgres
POSTGRES_PASSWORD=change-me-in-production

# JWT Configuration
JWT_SECRET=change-this-to-a-strong-random-secret-at-least-256-bits
JWT_EXPIRES_IN=1h

# Application Ports
USER_SERVICE_PORT=3000
TODO_SERVICE_PORT=8081
FRONTEND_PORT=8080
POSTGRES_USER_PORT=5432
POSTGRES_TODO_PORT=5433

# Database Names
USER_DB_NAME=user_service_db
TODO_DB_NAME=todo_service_db

# Node.js Environment
NODE_ENV=production

# Java Options
JAVA_OPTS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0

# Spring Profile
SPRING_PROFILE=prod
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 5: Loo .gitignore (5 min)

Loo .gitignore fail, et mitte commit'ida salajaseid:

```bash
vim .gitignore
```

Lisa:

```
# Environment files with secrets
.env

# Docker Compose overrides (optional - depends on your workflow)
# docker-compose.override.yml

# Logs
*.log

# OS files
.DS_Store
Thumbs.db
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 6: Valideeri ja Testi (5 min)

```bash
# Valideeri, et .env fail loetakse
docker compose config | grep JWT_SECRET

# Peaks nägema .env'ist loetud väärtust:
# JWT_SECRET: super-secret-jwt-key-...

# Restart stack uute muutujatega
docker compose down
docker compose up -d

# Kontrolli staatust
docker compose ps

# Kõik peaksid olema UP ja HEALTHY
```

**Testi API'd:**

```bash
# Health checks
curl http://localhost:3000/health
curl http://localhost:8081/health

# Registreeri kasutaja (peaks töötama)
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Env Test","email":"env@test.com","password":"test123"}'
```

---

### Samm 7: Loo docker-compose.override.yml Dev Jaoks (10 min)

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
    # Development: enable directory listing for debugging
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

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **.env** fail salajastega (EI commit'i Git'i)
- [ ] **.env.example** template (commit'id Git'i)
- [ ] **.gitignore** fail (.env on ignoreeritud)
- [ ] **docker-compose.yml** kasutab ${VARIABLE} süntaksit
- [ ] **docker-compose.override.yml** dev seadistustega
- [ ] **Stack töötab** .env väärtustega
- [ ] **End-to-End workflow** toimib

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas .env fail eksisteerib?
ls -la .env
# Peaks nägema .env faili

# 2. Kas .env loetakse?
docker compose config | grep JWT_SECRET
# Peaks nägema .env'ist väärtust

# 3. Kas .gitignore toimib?
git status
# .env EI PEAKS olema nimekirjas

# 4. Kas override rakendub?
docker compose config | grep NODE_ENV
# Development mode'is peaks olema: NODE_ENV: development
```

---

## 🎓 Õpitud Mõisted

### .env Fail:

```bash
# Süntaks:
VARIABLE_NAME=value

# Docker Compose kasutamine:
${VARIABLE_NAME}

# Default väärtus:
${VARIABLE_NAME:-default_value}
```

### docker-compose.override.yml:

- Rakendub **automaatselt** peale docker-compose.yml
- Kasutatakse development seadistustele
- Ei commit'i Git'i (optional)
- Override'ib docker-compose.yml väärtusi

### Versioonihaldus Best Practices:

✅ **Commit:**
- docker-compose.yml
- .env.example (template)
- .gitignore

❌ **EI commit:**
- .env (sisaldab salajaseid)
- docker-compose.override.yml (optional - sõltub workflow'st)

---

## 💡 Parimad Tavad

1. **Ära kunagi commit'i .env faili** - Lisa .gitignore'i
2. **Kasuta .env.example template'i** - Teised saavad kergesti seadistada
3. **Genereeri tugevad salajased** - JWT_SECRET peab olema random
4. **Kasuta erinevaid salajaseid** - Dev vs Prod
5. **Dokumenteeri .env.example** - Lisa kommentaarid

### Tugeva JWT_SECRET Genereerimine:

```bash
# Linux/Mac:
openssl rand -base64 64

# Või Node.js:
node -e "console.log(require('crypto').randomBytes(64).toString('base64'))"

# Kopeeri tulemus .env faili:
JWT_SECRET=<genereeritud-väärtus>
```

---

## 🐛 Levinud Probleemid

### Probleem 1: "Variable not set: JWT_SECRET"

```bash
# Kontrolli, kas .env fail on olemas
ls -la .env

# Kui puudub, kopeeri .env.example
cp .env.example .env
vim .env  # Lisa päris väärtused
```

### Probleem 2: ".env fail ei loeta"

```bash
# .env peab olema samas kataloogis docker-compose.yml'iga
ls -la
# Peaks nägema:
# docker-compose.yml
# .env

# Kontrolli faili õigusi
chmod 644 .env
```

### Probleem 3: "Override ei rakendu"

```bash
# Kontrolli, et docker-compose.override.yml on olemas
ls -la docker-compose.override.yml

# Vaata, mis konfiguratsioon rakendub
docker compose config

# Force override
docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### Probleem 4: "Muutujad ei substitueeru"

```bash
# Vale süntaks:
$VARIABLE  # ❌

# Õige süntaks:
${VARIABLE}  # ✅

# Default väärtusega:
${VARIABLE:-default}  # ✅
```

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd haldad salajaseid turvaliselt .env failidega.

**Mis edasi?**
- ✅ Salajased on eraldatud docker-compose.yml'ist
- ✅ .env.example template on loodud
- ✅ Development override rakendub
- ⏭️ **Järgmine:** Database Migrations (Liquibase)

**Jätka:** [Harjutus 4: Database Migrations](04-database-migrations.md)

---

## 📚 Viited

- [Docker Compose environment variables](https://docs.docker.com/compose/environment-variables/)
- [Compose file .env file](https://docs.docker.com/compose/env-file/)
- [Docker Compose override](https://docs.docker.com/compose/extends/)
- [Best practices for secrets](https://docs.docker.com/compose/use-secrets/)

---

**Õnnitleme! Oled õppinud turvaliselt salajaseid haldama! 🎉**
