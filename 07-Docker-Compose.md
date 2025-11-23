# Peatükk 7: Docker Compose - Multi-Container Orkestratsioon

**Kestus:** 4 tundi
**Eeldused:** Peatükk 4-6 (Docker, Dockerfile, PostgreSQL konteinerites)
**Eesmärk:** Hallata multi-container rakendusi deklaratiivse konfiguratsiooniga

---

## Õpieesmärgid

Selle peatüki lõpuks oskad:
- Mõista Docker Compose rolli multi-container orkestratsiooniks
- Kirjutada `docker-compose.yml` faile Infrastructure as Code'ina
- Seadistada service discovery, networks ja volumes
- Hallata environment variables turvaliselt (.env)
- Kasutada healthchecks ja dependencies

---

## 7.1 Miks Docker Compose?

### Probleem: Manuaalsed Docker Käsud

**Stsenaarium:** Full-stack rakendus (frontend + backend + PostgreSQL)

**Manuaalne lähenemine:**

```bash
# 1. Create network
docker network create app-network

# 2. Create volume
docker volume create postgres-data

# 3. Start PostgreSQL
docker run -d \
  --name postgres \
  --network app-network \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=user_service_db \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:16-alpine

# 4. Start backend
docker run -d \
  --name backend \
  --network app-network \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=appuser \
  -e DB_PASSWORD=secret \
  -e JWT_SECRET=my-jwt-secret \
  -p 3000:3000 \
  backend-nodejs:1.0

# 5. Start frontend
docker run -d \
  --name frontend \
  --network app-network \
  -p 8080:80 \
  frontend:1.0
```

**Probleemid:**
- ❌ 5 käsku → error-prone (unustasid `--network`? → ei tööta!)
- ❌ Ei ole reproducible (teises serveris pead kõike uuesti tippima)
- ❌ Ei ole version controlled (käsud ei ole Git'is)
- ❌ Startup order probleem (backend käivitub enne PostgreSQL'i → crash!)
- ❌ Ei ole Infrastructure as Code

---

### Lahendus: Docker Compose

**Sama rakendus Docker Compose'iga:**

**`docker-compose.yml`:**
```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: user_service_db
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network

  backend:
    image: backend-nodejs:1.0
    depends_on:
      - postgres
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: user_service_db
      DB_USER: appuser
      DB_PASSWORD: secret
      JWT_SECRET: my-jwt-secret
    ports:
      - "3000:3000"
    networks:
      - app-network

  frontend:
    image: frontend:1.0
    ports:
      - "8080:80"
    networks:
      - app-network

volumes:
  postgres-data:

networks:
  app-network:
```

**Käivitamine:**
```bash
docker compose up -d
```

**Plussid:**
- ✅ Üks käsk → käivitab kõik teenused
- ✅ Deklaratiivne (WHAT, not HOW)
- ✅ Infrastructure as Code (Git version control)
- ✅ Dependencies (depends_on) → õige startup order
- ✅ Reproducible (git clone → docker compose up)

**DevOps perspektive:**
> "Docker Compose on Kubernetes enne Kubernetes'e. Multi-container orchestration local ja small-scale production environments."

---

## 7.2 Docker Compose Architecture

### Compose vs Standalone Docker

**Standalone Docker:**
```
You → docker run → Docker Daemon → Container
     (imperative)     (API call)
```

**Docker Compose:**
```
You → docker compose up → Compose CLI → Docker Daemon → Containers
     (declarative)         (reads YAML)   (API calls)   (multiple)
```

**Key difference:**
- Docker: Imperative (HOW to create containers)
- Compose: Declarative (WHAT containers should exist)

---

### Compose File Structure

```yaml
version: "3.9"  # Optional (modern Compose ei vaja)

services:       # REQUIRED: konteinerite definitsioonid
  service1:
    image: ...
    build: ...
    environment: ...
    volumes: ...
    networks: ...
    ports: ...
    depends_on: ...

  service2:
    ...

volumes:        # OPTIONAL: named volumes
  volume1:
  volume2:

networks:       # OPTIONAL: custom networks
  network1:
  network2:
```

**Service = Container Definition**
- Compose terminoloogias "service" = "container definition"
- `docker compose up` → creates containers from service definitions
- `docker compose scale backend=3` → creates 3 backend containers

---

## 7.3 Service Definitsioonid

### Image vs Build

**Variant A: Use pre-built image**
```yaml
services:
  backend:
    image: backend-nodejs:1.0  # Already built
```

**Mille jaoks:**
- Production (image on built CI/CD'ga)
- External images (postgres:16-alpine)

---

**Variant B: Build image locally**
```yaml
services:
  backend:
    build:
      context: ./backend-nodejs       # Where Dockerfile is
      dockerfile: Dockerfile.prod     # Optional (default: Dockerfile)
      args:                            # Build args
        NODE_VERSION: 18
```

**Mille jaoks:**
- Development (build locally → test → iterate)
- Monorepo structure (erinevad Dockerfile'id samas repo's)

---

**Hybrid: Build + Tag**
```yaml
services:
  backend:
    build: ./backend-nodejs
    image: backend-nodejs:latest  # Tag built image
```

**Mida see teeb:**
```bash
docker compose build
→ Builds image from ./backend-nodejs/Dockerfile
→ Tags it as backend-nodejs:latest
→ Stores in local Docker registry
```

---

### Ports - Host to Container Mapping

```yaml
services:
  backend:
    ports:
      - "3000:3000"      # HOST:CONTAINER
      - "3001:3000"      # Multiple mappings
      - "127.0.0.1:3002:3000"  # Bind to specific IP
```

**Formaat:**
```
"HOST_IP:HOST_PORT:CONTAINER_PORT"
```

**Näited:**

```yaml
# Backend kuulab port 3000 container'is
# Accessible host'is: localhost:3000
ports:
  - "3000:3000"

# PostgreSQL kuulab port 5432 container'is
# Accessible AINULT localhost'il (not external network)
ports:
  - "127.0.0.1:5432:5432"

# Frontend kuulab port 80 container'is
# Accessible host'is: localhost:8080
ports:
  - "8080:80"
```

**Port conflicts:**
```yaml
# ❌ ERROR: Host port 3000 already in use
services:
  backend1:
    ports:
      - "3000:3000"
  backend2:
    ports:
      - "3000:3000"  # CONFLICT!

# ✅ LAHENDUS: Erinevad host pordid
services:
  backend1:
    ports:
      - "3000:3000"
  backend2:
    ports:
      - "3001:3000"  # OK
```

---

### Environment Variables

**Inline definition:**
```yaml
services:
  backend:
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      NODE_ENV: production
```

**Kasutamine env_file'ist (.env):**
```yaml
services:
  backend:
    env_file:
      - .env            # Default .env file
      - .env.production # Additional file
```

**`.env` fail:**
```bash
DB_HOST=postgres
DB_PORT=5432
DB_NAME=user_service_db
DB_USER=appuser
DB_PASSWORD=super-secret-password
JWT_SECRET=my-jwt-secret-key
NODE_ENV=production
```

**Miks .env file?**
1. **Secrets isolation:** .env ei lähe Git'i (.gitignore)
2. **Environment-specific:** .env.dev, .env.staging, .env.prod
3. **DRY principle:** Ühes kohas defineeritud → kõik teenused saavad kasutada

**Variable substitution:**
```yaml
services:
  backend:
    image: backend-nodejs:${VERSION:-latest}  # Default: latest
    environment:
      DB_HOST: ${DB_HOST}  # From .env
```

**`.env`:**
```bash
VERSION=1.2.3
DB_HOST=postgres-prod
```

**Result:**
```yaml
services:
  backend:
    image: backend-nodejs:1.2.3
    environment:
      DB_HOST: postgres-prod
```

📖 **Praktika:** Labor 2, Harjutus 1 - Environment variables ja .env failid

---

## 7.4 Networks - Service Discovery

### Default Network Behavior

**Automatic network creation:**
```bash
docker compose up
→ Creates network: <project-name>_default
→ All services join this network
```

**Service discovery:**
```yaml
services:
  postgres:
    image: postgres:16-alpine

  backend:
    image: backend-nodejs:1.0
    environment:
      DB_HOST: postgres  # ← Service name = DNS name!
```

**Kuidas see töötab?**

```
Backend container:
→ Resolve DNS: postgres
→ Compose internal DNS: postgres = 172.20.0.2 (postgres container IP)
→ Connect to 172.20.0.2:5432
→ SUCCESS!
```

**DevOps perspektive:**
> "Ma ei pea teadma IP addressi. Service name on DNS name. Compose lahendab automaatselt."

---

### Custom Networks

**Multi-network isolation:**
```yaml
services:
  frontend:
    networks:
      - frontend-network

  backend:
    networks:
      - frontend-network  # Can talk to frontend
      - backend-network   # Can talk to DB

  postgres:
    networks:
      - backend-network   # Can talk to backend ONLY

networks:
  frontend-network:
  backend-network:
```

**Network topology:**
```
Frontend (frontend-network)
    ↓
Backend (frontend-network + backend-network)
    ↓
PostgreSQL (backend-network)

Frontend CANNOT directly connect to PostgreSQL (different networks)
```

**Miks see oluline?**
- Security: Frontend ei saa otse andmebaasi pihta
- Isolation: Mikroteenused on isoleeritud

---

### External Networks

```yaml
services:
  backend:
    networks:
      - app-network

networks:
  app-network:
    external: true  # Network already exists (created manually)
```

**Kasutamine:**
```bash
# 1. Create network manually
docker network create app-network

# 2. Compose uses existing network
docker compose up
```

**Mille jaoks?**
- Shared network mitme Compose project'i vahel
- Integration legacy containers'iga

---

## 7.5 Volumes - Data Persistence

### Named Volumes

```yaml
services:
  postgres:
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:  # Compose creates and manages
```

**Lifecycle:**
```bash
# 1. First time
docker compose up
→ Creates volume: <project>_postgres-data

# 2. Container deleted
docker compose down
→ Volume PERSISTS (not deleted)

# 3. Restart
docker compose up
→ Reuses existing volume → DATA INTACT!

# 4. Delete volume explicitly
docker compose down -v
→ Volume DELETED → DATA LOST!
```

---

### Bind Mounts - Development Workflow

```yaml
services:
  backend:
    volumes:
      - ./backend-nodejs:/app  # HOST:CONTAINER
      - /app/node_modules       # Anonymous volume (override)
```

**Development workflow:**

```
1. Edit code in host: vim backend-nodejs/src/index.js
2. nodemon (in container) detects change
3. Auto-restart → see changes IMMEDIATELY
4. No need to rebuild image!
```

**Miks `/app/node_modules` override?**

```
Problem:
- Host: macOS (ARM architecture)
- Container: Linux (AMD64 architecture)
- node_modules contains native binaries (incompatible!)

Solution:
- Bind mount: ./backend-nodejs → /app
- Anonymous volume: /app/node_modules
→ node_modules stays INSIDE container (not overwritten by host)
```

---

### Volume Drivers

**Local driver (default):**
```yaml
volumes:
  postgres-data:
    driver: local
```

**NFS driver (shared storage):**
```yaml
volumes:
  shared-data:
    driver: local
    driver_opts:
      type: nfs
      o: addr=192.168.1.100,rw
      device: ":/mnt/shared"
```

**DevOps kasutus:**
- Local: Single-server deployments
- NFS: Multi-server (cluster) → shared data

---

## 7.6 Dependencies ja Startup Order

### depends_on - Basic Ordering

```yaml
services:
  postgres:
    image: postgres:16-alpine

  backend:
    image: backend-nodejs:1.0
    depends_on:
      - postgres  # Start postgres BEFORE backend
```

**Mida see teeb:**

```bash
docker compose up

1. Start postgres
2. Wait until postgres container is CREATED (NOT ready!)
3. Start backend

Problem:
→ Backend starts → tries to connect to DB
→ PostgreSQL still initializing (not accepting connections)
→ Backend connection error → crash!
```

**depends_on Limitation:**
> `depends_on` waits for container to START, not for service to be READY.

---

### Healthchecks - Wait for Service Ready

```yaml
services:
  postgres:
    image: postgres:16-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser"]
      interval: 5s     # Check every 5 seconds
      timeout: 3s      # Timeout after 3 seconds
      retries: 5       # Retry 5 times before unhealthy
      start_period: 10s  # Grace period (don't fail during init)

  backend:
    image: backend-nodejs:1.0
    depends_on:
      postgres:
        condition: service_healthy  # Wait for HEALTHY, not just started!
```

**Workflow:**

```
1. Start postgres container
2. Wait 10s (start_period)
3. Run: pg_isready -U appuser
   → Exit code 0 (success) → healthy
   → Exit code 1 (fail) → unhealthy
4. Retry every 5s for max 5 attempts
5. Once healthy → start backend
```

**Healthcheck status:**
```bash
docker compose ps

# Output:
postgres   healthy    Up 30 seconds
backend    running    Up 10 seconds
```

📖 **Praktika:** Labor 2, Harjutus 2 - Dependencies ja healthchecks

---

### Alternative: Retry Logic in Application

**Backend code (better approach):**
```javascript
const connectDB = async () => {
  const maxRetries = 10;
  for (let i = 0; i < maxRetries; i++) {
    try {
      await pool.connect();
      console.log('PostgreSQL connected');
      return;
    } catch (err) {
      console.log(`DB connection failed (attempt ${i+1}/${maxRetries}), retrying in 5s...`);
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
  throw new Error('Could not connect to PostgreSQL');
};
```

**DevOps perspektive:**
> "Application retry logic on parem kui Compose healthchecks. Rakendus peab olema resilient (taaskäivitub iseseisvalt)."

---

## 7.7 Multi-Container Orkestratsioon - Full Example

### Praktiline Näide: Full-Stack Rakendus

**Project structure:**
```
project/
├── docker-compose.yml
├── .env
├── .env.example
├── backend-nodejs/
│   ├── Dockerfile
│   └── src/
├── frontend/
│   ├── Dockerfile
│   └── public/
└── database/
    └── init.sql
```

---

**`docker-compose.yml`:**
```yaml
services:
  # Database
  postgres:
    image: postgres:16-alpine
    container_name: postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - backend-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Backend (Node.js + Express)
  backend:
    build:
      context: ./backend-nodejs
      dockerfile: Dockerfile.prod
    container_name: backend
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      NODE_ENV: production
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${POSTGRES_DB}
      DB_USER: ${POSTGRES_USER}
      DB_PASSWORD: ${POSTGRES_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      PORT: 3000
    ports:
      - "3000:3000"
    networks:
      - backend-network
      - frontend-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

  # Frontend (Nginx + Static Files)
  frontend:
    build: ./frontend
    container_name: frontend
    depends_on:
      - backend
    ports:
      - "8080:80"
    networks:
      - frontend-network
    restart: unless-stopped

volumes:
  postgres-data:
    driver: local

networks:
  backend-network:
    driver: bridge
  frontend-network:
    driver: bridge
```

---

**`.env` (not committed to Git):**
```bash
# PostgreSQL
POSTGRES_USER=appuser
POSTGRES_PASSWORD=super-secret-password-xyz
POSTGRES_DB=user_service_db

# Backend
JWT_SECRET=my-super-secret-jwt-key-production
```

**`.env.example` (committed to Git):**
```bash
# PostgreSQL
POSTGRES_USER=appuser
POSTGRES_PASSWORD=CHANGE_ME
POSTGRES_DB=user_service_db

# Backend
JWT_SECRET=CHANGE_ME
```

---

**Käivitamine:**

```bash
# 1. Clone repo
git clone https://github.com/company/fullstack-app.git
cd fullstack-app

# 2. Copy .env template
cp .env.example .env
vim .env  # Set real secrets

# 3. Build and start
docker compose up --build -d

# 4. Check logs
docker compose logs -f

# 5. Check health
curl http://localhost:3000/health
curl http://localhost:8080
```

---

## 7.8 Development vs Production Configs

### Separate Compose Files

**`docker-compose.yml` (base):**
```yaml
services:
  backend:
    build: ./backend-nodejs
    environment:
      DB_HOST: postgres
```

**`docker-compose.dev.yml` (development overrides):**
```yaml
services:
  backend:
    build:
      target: development  # Multi-stage build target
    volumes:
      - ./backend-nodejs:/app  # Bind mount for hot reload
      - /app/node_modules
    environment:
      NODE_ENV: development
    command: npm run dev  # nodemon
```

**`docker-compose.prod.yml` (production overrides):**
```yaml
services:
  backend:
    build:
      target: production
    environment:
      NODE_ENV: production
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
```

---

**Kasutamine:**

```bash
# Development
docker compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

**Alias'ed (lihtsustamiseks):**
```bash
# .bashrc or .zshrc
alias dc-dev="docker compose -f docker-compose.yml -f docker-compose.dev.yml"
alias dc-prod="docker compose -f docker-compose.yml -f docker-compose.prod.yml"

# Kasutamine:
dc-dev up
dc-prod up -d
```

---

### Override Pattern

**Default: docker-compose.yml**
```yaml
services:
  backend:
    image: backend:latest
    environment:
      NODE_ENV: production
```

**Auto-override: docker-compose.override.yml (development)**
```yaml
services:
  backend:
    build: ./backend-nodejs  # Override image → build locally
    volumes:
      - ./backend-nodejs:/app
    environment:
      NODE_ENV: development  # Override NODE_ENV
```

**Behavior:**
```bash
# Development (automatic override)
docker compose up
→ Uses: docker-compose.yml + docker-compose.override.yml
→ Builds locally, NODE_ENV=development

# Production (ignore override)
docker compose -f docker-compose.yml up
→ Uses ONLY docker-compose.yml
→ Uses image:latest, NODE_ENV=production
```

📖 **Praktika:** Labor 2, Harjutus 3 - Development vs production configs

---

## 7.9 Docker Compose CLI - Põhikäsud

### Lifecycle Management

```bash
# Start all services (detached)
docker compose up -d

# Start + rebuild images
docker compose up --build -d

# Start specific service
docker compose up backend

# Stop all services (containers persist)
docker compose stop

# Stop + remove containers (volumes persist)
docker compose down

# Stop + remove containers + volumes (DATA LOST!)
docker compose down -v

# Restart all services
docker compose restart

# Restart specific service
docker compose restart backend
```

---

### Monitoring ja Debugging

```bash
# View logs (all services)
docker compose logs

# Follow logs real-time
docker compose logs -f

# Logs for specific service
docker compose logs -f backend

# Last 50 lines
docker compose logs --tail=50 backend

# List running services
docker compose ps

# View resource usage
docker compose top

# Execute command in running container
docker compose exec backend sh
docker compose exec postgres psql -U appuser -d user_service_db
```

---

### Scaling

```bash
# Scale backend to 3 instances
docker compose up -d --scale backend=3

# View scaled services
docker compose ps

# Output:
# backend-1   running
# backend-2   running
# backend-3   running
```

**Note:** Ports conflict!
```yaml
# ❌ DOESN'T work with scaling
services:
  backend:
    ports:
      - "3000:3000"  # Port conflict when scaling!

# ✅ Solution: No host port mapping (use nginx load balancer)
services:
  backend:
    expose:
      - 3000  # Accessible only within Docker network
```

---

## Kokkuvõte

### Mida sa õppisid?

**Docker Compose fundamentals:**
- Multi-container orchestration deklaratiivse YAML'iga
- Infrastructure as Code (Git version control)
- Reproducible environments (git clone → docker compose up)

**Service definitsioonid:**
- image vs build
- ports, environment, volumes
- depends_on + healthchecks

**Networking:**
- Automatic service discovery (service name = DNS)
- Custom networks (isolation)
- Multi-network topologies

**Data persistence:**
- Named volumes (managed by Compose)
- Bind mounts (development workflow)
- Volume lifecycle (persist across restarts)

**Best practices:**
- .env files for secrets (not committed)
- Healthchecks for proper startup order
- Development vs production configs
- Separate Compose files (dev, prod)

---

### DevOps Administraatori Vaatenurk

**Iga päev:**
```bash
docker compose up -d        # Start application
docker compose logs -f      # Monitor logs
docker compose ps           # Check status
docker compose restart backend  # Restart specific service
```

**Troubleshooting:**
```bash
docker compose logs backend  # Check backend errors
docker compose exec backend sh  # Debug inside container
docker compose down && docker compose up -d  # Full restart
```

**Updates:**
```bash
git pull                     # Fetch latest configs
docker compose pull          # Pull latest images
docker compose up -d         # Recreate containers with new images
```

---

### Järgmised Sammud

**Peatükk 8:** Docker Registry ja Image Haldamine
**Peatükk 9:** Kubernetes Alused (production orchestration!)

---

**Kestus kokku:** ~4 tundi teooriat + praktilised harjutused labides

📖 **Praktika:** Labor 2 - Docker Compose multi-container orchestration
