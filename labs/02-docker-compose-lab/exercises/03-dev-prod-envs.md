# Harjutus 3: Development ja Production Keskkonnad

**Kestus:** 45 minutit
**Eesmärk:** Loo eraldi Docker Compose konfiguratsioonid arenduse ja produktsiooni jaoks

---

## 📋 Ülevaade

Selles harjutuses lood kaks erinevat `docker-compose` faili:
- **docker-compose.dev.yml** - Arenduskeskkond (hot reload, debug, volumes)
- **docker-compose.prod.yml** - Produktsioonikeskkond (optimeeritud, turvaline, read-only)

**Miks see oluline on:**
- Arenduses tahad kiiret iteratsiooni (nodemon, volume mounts)
- Produktsioonis tahad turvalisust ja stabiilsust (optimized images, restart policies)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua eraldi compose faile eri keskkondade jaoks
- ✅ Kasutada `.env` faile salajaste haldamiseks
- ✅ Konfigureerida development mode (hot reload)
- ✅ Konfigureerida production mode (optimized)
- ✅ Kasutada `docker compose -f` flagi
- ✅ Kasutada `extends` ja `override` pattern'e

---

## 🏗️ Arhitektuur

```
Development Environment          Production Environment
┌─────────────────────┐         ┌─────────────────────┐
│ - nodemon           │         │ - node (optimized)  │
│ - volume mounts     │         │ - no volumes        │
│ - debug ports       │         │ - health checks     │
│ - verbose logs      │         │ - restart policies  │
└─────────────────────┘         └─────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Loo Base Compose Fail (10 min)

Loo üldine `docker-compose.yml` fail, mis sisaldab ühiseid konfiguratsioone:

```bash
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/my-compose-project

vim docker-compose.yml
```

**Base konfiguratsioon** (ühine dev ja prod jaoks):

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME:-user_service_db}
      POSTGRES_USER: ${DB_USER:-appuser}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_INITDB_ARGS: "-E UTF8 --locale=C"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network

  backend:
    build:
      context: ../../apps/backend-nodejs
      dockerfile: Dockerfile
    environment:
      NODE_ENV: ${NODE_ENV:-production}
      PORT: 3000
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${DB_NAME:-user_service_db}
      DB_USER: ${DB_USER:-appuser}
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      JWT_EXPIRES_IN: ${JWT_EXPIRES_IN:-7d}
    networks:
      - app-network

  frontend:
    build:
      context: ../../apps/frontend
      dockerfile: Dockerfile
    networks:
      - app-network

volumes:
  postgres-data:

networks:
  app-network:
    driver: bridge
```

Salvesta: `Esc`, `:wq`, `Enter`

---

### Samm 2: Loo .env.dev Fail (5 min)

Loo development keskonna environment variables:

```bash
vim .env.dev
```

Lisa:

```env
# Environment
NODE_ENV=development

# Database
DB_NAME=user_service_dev
DB_USER=devuser
DB_PASSWORD=devpass123

# JWT
JWT_SECRET=dev-secret-key-not-for-production
JWT_EXPIRES_IN=24h

# Debug
DEBUG=true
LOG_LEVEL=debug
```

Salvesta: `Esc`, `:wq`, `Enter`

---

### Samm 3: Loo .env.prod Fail (5 min)

Loo production keskonna environment variables:

```bash
vim .env.prod
```

Lisa:

```env
# Environment
NODE_ENV=production

# Database
DB_NAME=user_service_prod
DB_USER=produser
DB_PASSWORD=ProductionSecurePass123!ChangeME

# JWT
JWT_SECRET=production-super-secret-jwt-key-CHANGE-THIS
JWT_EXPIRES_IN=7d

# Logging
DEBUG=false
LOG_LEVEL=info
```

Salvesta: `Esc`, `:wq`, `Enter`

**TURVALISUS:**

```bash
# Määra õigused ainult read
chmod 600 .env.dev .env.prod

# Lisa .gitignore
echo ".env.*" >> .gitignore
```

---

### Samm 4: Loo docker-compose.dev.yml (10 min)

Development override fail:

```bash
vim docker-compose.dev.yml
```

Lisa:

```yaml
version: '3.8'

services:
  postgres:
    container_name: dev-postgres
    ports:
      - "5432:5432"  # Exposed, et saad psql-iga ühenduda
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-devuser}"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    container_name: dev-backend
    build:
      target: development  # Kui kasutad multi-stage Dockerfile
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "3000:3000"
      - "9229:9229"  # Node.js debug port
    volumes:
      # HOT RELOAD - koodi muutused kohe nähtavad
      - ../../apps/backend-nodejs:/app
      - /app/node_modules  # Exclude node_modules
    environment:
      NODE_ENV: development
      DEBUG: "true"
    command: npm run dev  # Kasutab nodemon

  frontend:
    container_name: dev-frontend
    ports:
      - "8080:80"
    volumes:
      # HOT RELOAD frontend jaoks
      - ../../apps/frontend:/usr/share/nginx/html
```

Salvesta: `Esc`, `:wq`, `Enter`

---

### Samm 5: Loo docker-compose.prod.yml (10 min)

Production override fail:

```bash
vim docker-compose.prod.yml
```

Lisa:

```yaml
version: '3.8'

services:
  postgres:
    container_name: prod-postgres
    restart: always
    # NO port exposure (turvalisem)
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-produser}"]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 60s
    volumes:
      - postgres-data:/var/lib/postgresql/data:rw
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M

  backend:
    container_name: prod-backend
    build:
      target: production  # Multi-stage Dockerfile optimized stage
      args:
        NODE_ENV: production
    restart: always
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "3000:3000"
    # NO volume mounts (read-only image)
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
    security_opt:
      - no-new-privileges:true
    read_only: true  # Read-only filesystem
    tmpfs:
      - /tmp

  frontend:
    container_name: prod-frontend
    restart: always
    depends_on:
      - backend
    ports:
      - "8080:80"
    # NO volume mounts
    deploy:
      resources:
        limits:
          cpus: '0.25'
          memory: 128M
    security_opt:
      - no-new-privileges:true
```

Salvesta: `Esc`, `:wq`, `Enter`

---

### Samm 6: Käivita Development Keskkond (5 min)

```bash
# Käivita dev mode
docker compose -f docker-compose.yml -f docker-compose.dev.yml --env-file .env.dev up -d

# Kontrolli
docker compose -f docker-compose.yml -f docker-compose.dev.yml ps

# Vaata loge
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f backend
```

**Peaks nägema:**
```
dev-backend | [nodemon] starting `node server.js`
dev-backend | Server running in DEVELOPMENT mode
```

**Testi hot reload:**

```bash
# Muuda midagi backend koodis
vim ../../apps/backend-nodejs/server.js

# Lisa kommentaar või muuda sõnumit
# Salvesta

# Vaata loge - backend peaks automaatselt restartima!
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f backend
# [nodemon] restarting due to changes...
```

---

### Samm 7: Käivita Production Keskkond (5 min)

**Kõigepealt peata dev:**

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
```

**Käivita prod mode:**

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d --build

# Kontrolli
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps

# Vaata loge
docker compose -f docker-compose.yml -f docker-compose.prod.yml logs backend
```

**Peaks nägema:**
```
prod-backend | Server running in PRODUCTION mode
prod-backend | Security features enabled
```

**Testi:**

```bash
curl http://localhost:3000/health

# Peaks tagastama:
# {"status":"ok","environment":"production"}
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **docker-compose.yml** (base config)
- [ ] **docker-compose.dev.yml** (dev overrides)
- [ ] **docker-compose.prod.yml** (prod overrides)
- [ ] **.env.dev** (dev environment variables)
- [ ] **.env.prod** (prod environment variables)
- [ ] Oskad käivitada dev mode: `docker compose -f ... -f ... --env-file .env.dev up`
- [ ] Oskad käivitada prod mode: `docker compose -f ... -f ... --env-file .env.prod up`
- [ ] Mõistad erinevusi dev ja prod vahel

---

## 🧪 Testimine

### Test 1: Development Mode

```bash
# Start dev
docker compose -f docker-compose.yml -f docker-compose.dev.yml --env-file .env.dev up -d

# Kontrolli port 9229 (debug)
docker compose -f docker-compose.yml -f docker-compose.dev.yml ps | grep 9229

# Muuda koodi ja vaata automaatset restart'i
vim ../../apps/backend-nodejs/server.js
# Lisa kommentaar
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f backend

# Cleanup
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
```

### Test 2: Production Mode

```bash
# Start prod
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

# Kontrolli health checks
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps

# Kontrolli resource limits
docker stats prod-backend

# Cleanup
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
```

---

## 🎓 Õpitud Mõisted

### Compose File Override Pattern:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up
#              └─ BASE CONFIG ─┘  └─ OVERRIDE CONFIG ──┘
```

Docker Compose **mergib** kaks faili:
- Base defineerib ühised asjad
- Override lisab/muudab dev või prod spetsiifilisi asju

### Environment Files:

```bash
--env-file .env.dev   # Development variables
--env-file .env.prod  # Production variables
```

`.env` failid **ei lähe** Git'i! Hoiad saladusi turvaliselt.

### Volume Mounts vs No Volumes:

**Development:**
```yaml
volumes:
  - ../../apps/backend-nodejs:/app  # Hot reload
```

**Production:**
```yaml
# NO volumes - image is read-only
read_only: true
```

---

## 💡 Parimad Tavad

### 1. Base + Override Pattern

✅ **Hea:**
```
docker-compose.yml        # Base (ühine)
docker-compose.dev.yml    # Dev overrides
docker-compose.prod.yml   # Prod overrides
```

❌ **Halb:**
```
docker-compose.yml        # Kõik dev-specific asjad
docker-compose.prod.yml   # Täiesti eraldiseisev copy-paste
```

### 2. Environment Variables

✅ **Hea:**
```yaml
environment:
  DB_PASSWORD: ${DB_PASSWORD}  # From .env file
```

❌ **Halb:**
```yaml
environment:
  DB_PASSWORD: hardcodedpass123  # NEVER!
```

### 3. Production Security

```yaml
# Production best practices:
restart: always
read_only: true
security_opt:
  - no-new-privileges:true
deploy:
  resources:
    limits:
      memory: 512M
```

---

## 🐛 Levinud Probleemid

### Probleem 1: "Permission denied" volume mounts

**Sümptom:** Dev mode - nodemon ei näe faile

**Lahendus:**
```yaml
volumes:
  - ../../apps/backend-nodejs:/app
  - /app/node_modules  # Exclude node_modules!
```

### Probleem 2: "Environment variable not set"

**Sümptom:** `WARNING: The DB_PASSWORD variable is not set`

**Lahendus:**
```bash
# Määra --env-file!
docker compose --env-file .env.dev up
```

### Probleem 3: "Changes not reflected"

**Sümptom:** Koodi muutused ei ilmu dev mode'is

**Lahendus:**
```yaml
command: npm run dev  # Veendu, et kasutab nodemon
```

---

## 🔧 Täiendavad Ülesanded (Valikuline)

### Ülesanne 1: Lisa Test Environment

Loo `docker-compose.test.yml` ja `.env.test`:

```yaml
services:
  backend:
    command: npm test
    environment:
      NODE_ENV: test
```

### Ülesanne 2: Lisa Makefile

Loo `Makefile` lihtsustamaks käske:

```makefile
.PHONY: dev prod test

dev:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml --env-file .env.dev up -d

prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d

down-dev:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml down

down-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml down
```

Kasutamine:
```bash
make dev    # Start dev
make prod   # Start prod
make down-dev
```

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd oskad hallata erinevaid keskkondi.

Aga seni kasutasime **Dockeriseeritud PostgreSQL-i**. Mis siis, kui tahad kasutada **välist PostgreSQL serverit**?

Järgmises harjutuses õpid **mõlemat deployment pattern'i**!

**Jätka:** [Harjutus 4: Dual PostgreSQL Deployment](04-dual-postgres.md)

---

## 📚 Viited

- [Compose file merging](https://docs.docker.com/compose/extends/)
- [Environment variables in Compose](https://docs.docker.com/compose/environment-variables/)
- [Production best practices](https://docs.docker.com/compose/production/)

---

**Õnnitleme! Oskad nüüd hallata dev ja prod keskkondi professionaalselt! 🎯**
