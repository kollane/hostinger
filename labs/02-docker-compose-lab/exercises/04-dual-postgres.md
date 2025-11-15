# Harjutus 4: Dual PostgreSQL Deployment Pattern

**Kestus:** 45 minutit
**Eesmärk:** Õpi kahte PostgreSQL deployment mustrit: Containerized vs External

---

## 📋 Ülevaade

Selles harjutuses õpid kahte peamist PostgreSQL deployment pattern'i:

1. **PRIMAARNE: Containerized PostgreSQL** (StatefulSet pattern)
   - PostgreSQL töötab Docker container'is
   - Andmed salvestatakse Docker volume'is
   - Ideaalne: Microservices, Cloud-native, DevOps-driven projects

2. **ALTERNATIIV: External PostgreSQL** (Traditional VPS pattern)
   - PostgreSQL töötab välisel serveril (VPS, RDS, managed DB)
   - Docker Compose käivitab ainult backend + frontend
   - Ideaalne: Large production, dedicated DBA teams, legacy systems

**Õpid:**
- Millal kasutada kumba pattern'i
- Kuidas konfigureerida mõlemat
- Backup/restore strateegiad mõlema jaoks
- Plussid ja miinused

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Konfigureerida containerized PostgreSQL-i
- ✅ Konfigureerida external PostgreSQL-i
- ✅ Valida õiget pattern'i vastavalt situatsioonile
- ✅ Hallata andmebaasi migratsioone mõlemas pattern'is
- ✅ Teha backup'e ja restore'e
- ✅ Mõista mõlema pattern'i turvalisust

---

## 🏗️ Arhitektuur

### Pattern 1: Containerized PostgreSQL (PRIMARY)

```
┌─────────────────────────────────────────────┐
│   Docker Compose Stack                      │
│                                             │
│   ┌──────────┐   ┌──────────┐   ┌────────┐│
│   │ Frontend │──▶│ Backend  │──▶│Postgres││
│   │  (Nginx) │   │ (Node.js)│   │ (16)   ││
│   └──────────┘   └──────────┘   └────┬───┘│
│                                       │    │
│                                  postgres- │
│                                    data    │
│                                  (volume)  │
└─────────────────────────────────────────────┘
```

### Pattern 2: External PostgreSQL (ALTERNATIVE)

```
┌─────────────────────────────────────────────┐
│   Docker Compose Stack                      │
│                                             │
│   ┌──────────┐   ┌──────────┐              │
│   │ Frontend │──▶│ Backend  │──┐           │
│   │  (Nginx) │   │ (Node.js)│  │           │
│   └──────────┘   └──────────┘  │           │
│                                 │           │
└─────────────────────────────────┼───────────┘
                                  │
                                  ▼
                    ┌──────────────────────────┐
                    │  External PostgreSQL     │
                    │  (VPS / RDS / Managed)   │
                    │  93.127.213.242:5432     │
                    └──────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Pattern 1 - Containerized PostgreSQL (15 min)

See on pattern, mida kasutasime eelmistes harjutustes.

Loo `docker-compose.containerized.yml`:

```bash
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/my-compose-project

vim docker-compose.containerized.yml
```

Lisa:

```yaml
version: '3.8'

services:
  # PostgreSQL CONTAINERIZED
  postgres:
    image: postgres:16-alpine
    container_name: postgres-containerized
    restart: always
    environment:
      POSTGRES_DB: ${DB_NAME:-user_service_db}
      POSTGRES_USER: ${DB_USER:-appuser}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_INITDB_ARGS: "-E UTF8 --locale=C"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d  # Optional: init SQL scripts
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-appuser}"]
      interval: 10s
      timeout: 5s
      retries: 5
    # Backup CronJob (optional)
    labels:
      - "com.example.backup.enable=true"
      - "com.example.backup.schedule=0 2 * * *"  # Daily at 2 AM

  backend:
    build:
      context: ../../apps/backend-nodejs
      dockerfile: Dockerfile
    container_name: backend-containerized
    restart: always
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      NODE_ENV: production
      PORT: 3000
      # CONTAINERIZED DB CONNECTION
      DB_HOST: postgres  # Service name!
      DB_PORT: 5432
      DB_NAME: ${DB_NAME:-user_service_db}
      DB_USER: ${DB_USER:-appuser}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_SSL: "false"  # No SSL needed inside Docker network
      JWT_SECRET: ${JWT_SECRET}
      JWT_EXPIRES_IN: 7d
    ports:
      - "3000:3000"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  frontend:
    build:
      context: ../../apps/frontend
      dockerfile: Dockerfile
    container_name: frontend-containerized
    restart: always
    depends_on:
      - backend
    ports:
      - "8080:80"
    networks:
      - app-network

volumes:
  postgres-data:
    driver: local
    # Optional: specify location
    # driver_opts:
    #   type: none
    #   device: /mnt/postgres-data
    #   o: bind

networks:
  app-network:
    driver: bridge
```

Salvesta: `Esc`, `:wq`, `Enter`

**Käivita:**

```bash
# Loo .env fail
vim .env.containerized
```

```env
DB_NAME=user_service_db
DB_USER=appuser
DB_PASSWORD=ContainerizedPass123!
JWT_SECRET=containerized-jwt-secret-key
```

```bash
# Start
docker compose -f docker-compose.containerized.yml --env-file .env.containerized up -d

# Kontrolli
docker compose -f docker-compose.containerized.yml ps

# Testi
curl http://localhost:3000/health
```

---

### Samm 2: Backup Containerized PostgreSQL (5 min)

```bash
# Manual backup
docker compose -f docker-compose.containerized.yml exec postgres \
  pg_dump -U appuser -d user_service_db > backup_$(date +%Y%m%d_%H%M%S).sql

# VÕI backup container volume
docker run --rm \
  -v my-compose-project_postgres-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-data-backup.tar.gz -C /data .

# Restore
cat backup_20251115_120000.sql | \
  docker compose -f docker-compose.containerized.yml exec -T postgres \
  psql -U appuser -d user_service_db
```

---

### Samm 3: Pattern 2 - External PostgreSQL Setup (10 min)

#### 3.1. Paigalda PostgreSQL VPS-ile (kui pole juba)

```bash
# SSH VPS-i
ssh janek@kirjakast

# Paigalda PostgreSQL
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Kontrolli
sudo systemctl status postgresql

# Loo andmebaas ja kasutaja
sudo -u postgres psql

# SQL console:
CREATE DATABASE user_service_external;
CREATE USER externaluser WITH PASSWORD 'ExternalPass123!';
GRANT ALL PRIVILEGES ON DATABASE user_service_external TO externaluser;
\q
```

#### 3.2. Konfigureeri PostgreSQL Väliseks Ühenduseks

```bash
# Muuda postgresql.conf
sudo vim /etc/postgresql/16/main/postgresql.conf

# Otsi rida:
listen_addresses = 'localhost'

# Muuda:
listen_addresses = '*'  # VÕI '93.127.213.242'

# Salvesta
```

```bash
# Muuda pg_hba.conf
sudo vim /etc/postgresql/16/main/pg_hba.conf

# Lisa faili lõppu:
host    user_service_external    externaluser    0.0.0.0/0    scram-sha-256
```

```bash
# Restart PostgreSQL
sudo systemctl restart postgresql

# Kontrolli port
sudo ss -tlnp | grep 5432
# Peaks näitama: 0.0.0.0:5432
```

#### 3.3. Testi Ühendust

```bash
# Lokaalselt
psql -h localhost -U externaluser -d user_service_external

# Väljastpoolt (local masinalt)
psql -h 93.127.213.242 -U externaluser -d user_service_external
```

---

### Samm 4: Loo Compose Fail External DB Jaoks (10 min)

```bash
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/my-compose-project

vim docker-compose.external.yml
```

Lisa:

```yaml
version: '3.8'

services:
  # NO POSTGRES SERVICE - using external!

  backend:
    build:
      context: ../../apps/backend-nodejs
      dockerfile: Dockerfile
    container_name: backend-external
    restart: always
    environment:
      NODE_ENV: production
      PORT: 3000
      # EXTERNAL DB CONNECTION
      DB_HOST: ${EXTERNAL_DB_HOST}  # VPS IP or hostname
      DB_PORT: ${EXTERNAL_DB_PORT:-5432}
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_SSL: ${DB_SSL:-false}  # SSL for external DB (recommended)
      JWT_SECRET: ${JWT_SECRET}
      JWT_EXPIRES_IN: 7d
    ports:
      - "3000:3000"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    # Extra hosts (kui DB on samal VPS-il)
    extra_hosts:
      - "kirjakast:93.127.213.242"

  frontend:
    build:
      context: ../../apps/frontend
      dockerfile: Dockerfile
    container_name: frontend-external
    restart: always
    depends_on:
      - backend
    ports:
      - "8080:80"
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

# NO VOLUMES for PostgreSQL!
```

Salvesta: `Esc`, `:wq`, `Enter`

**Loo .env.external:**

```bash
vim .env.external
```

```env
# External PostgreSQL
EXTERNAL_DB_HOST=93.127.213.242
EXTERNAL_DB_PORT=5432
DB_NAME=user_service_external
DB_USER=externaluser
DB_PASSWORD=ExternalPass123!
DB_SSL=false

# JWT
JWT_SECRET=external-jwt-secret-key
```

```bash
# Start
docker compose -f docker-compose.external.yml --env-file .env.external up -d

# Kontrolli
docker compose -f docker-compose.external.yml ps

# Testi
curl http://localhost:3000/health
```

---

### Samm 5: Võrdle Patterne (5 min)

#### Tee Tabel:

| **Aspekt**              | **Containerized**                      | **External**                           |
|-------------------------|----------------------------------------|----------------------------------------|
| **Setup**               | Lihtne (docker-compose.yml)            | Keerulisem (VPS config)                |
| **Data Persistence**    | Docker volume                          | VPS disk                               |
| **Backup**              | Volume backup / pg_dump                | pg_dump / Cloud backup                 |
| **Scaling**             | Raske (StatefulSet Kubernetes'es)      | Lihtne (managed DB)                    |
| **Performance**         | Hea (sama network)                     | Võib olla väiksem latency (SSL, network)|
| **Cost**                | Väike (sama VPS)                       | Suurem (dedicated DB server)           |
| **Use Case**            | Microservices, DevOps, arendus        | Large production, legacy, DBA teams    |

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **docker-compose.containerized.yml** (Pattern 1)
- [ ] **docker-compose.external.yml** (Pattern 2)
- [ ] **.env.containerized** ja **.env.external**
- [ ] Töötav external PostgreSQL VPS-il
- [ ] Oskad käivitada mõlemat pattern'i
- [ ] Oskad teha backup'e mõlemale
- [ ] Mõistad, millal kasutada kumba

---

## 🧪 Testimine

### Test 1: Containerized Pattern

```bash
# Start
docker compose -f docker-compose.containerized.yml --env-file .env.containerized up -d

# Registreeri kasutaja
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Container User","email":"container@test.com","password":"test123"}'

# Kontrolli DB-s
docker compose -f docker-compose.containerized.yml exec postgres \
  psql -U appuser -d user_service_db -c "SELECT * FROM users;"

# Cleanup
docker compose -f docker-compose.containerized.yml down
```

### Test 2: External Pattern

```bash
# Start
docker compose -f docker-compose.external.yml --env-file .env.external up -d

# Registreeri kasutaja
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"External User","email":"external@test.com","password":"test123"}'

# Kontrolli DB-s (VPS-il)
psql -h localhost -U externaluser -d user_service_external -c "SELECT * FROM users;"

# Cleanup
docker compose -f docker-compose.external.yml down
```

---

## 🎓 Õpitud Mõisted

### Pattern Selection Decision Tree:

```
Kas on suur production rakendus? (1000+ users)
├─ JAH → External PostgreSQL
│         - Managed DB (AWS RDS, Google Cloud SQL)
│         - Dedicated DBA team
│         - Automatic backups, HA, replication
│
└─ EI → Kas on DevOps-driven microservices?
         ├─ JAH → Containerized PostgreSQL
         │         - Kubernetes StatefulSet
         │         - Cloud-native
         │         - Easy scaling
         │
         └─ EI → Kas on legacy system?
                  └─ JAH → External PostgreSQL
                            - Traditional VPS
                            - Separate DB tier
```

### Backup Strategies:

**Containerized:**
```bash
# 1. Logical backup (pg_dump)
docker exec postgres pg_dump -U user db > backup.sql

# 2. Physical backup (volume)
docker run --rm -v postgres-data:/data -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz -C /data .
```

**External:**
```bash
# 1. pg_dump
pg_dump -h 93.127.213.242 -U user db > backup.sql

# 2. Continuous archiving (WAL)
# 3. Cloud provider snapshots (AWS RDS, etc)
```

---

## 💡 Parimad Tavad

### Containerized PostgreSQL:

✅ Kasuta named volumes
✅ Määra health checks
✅ Planeeri backup strateegia
✅ Kubernetes'es kasuta StatefulSet
✅ Monitor disk usage

### External PostgreSQL:

✅ Kasuta SSL/TLS
✅ Piira IP whitelist (firewall)
✅ Kasuta connection pooling (PgBouncer)
✅ Monitor performance
✅ Automatic backups (cron või cloud)

---

## 🐛 Levinud Probleemid

### Probleem 1: "Can't connect to external DB"

```bash
# 1. Kontrolli PostgreSQL kuulab
sudo ss -tlnp | grep 5432

# 2. Kontrolli firewall
sudo ufw status
sudo ufw allow 5432/tcp

# 3. Kontrolli pg_hba.conf
sudo cat /etc/postgresql/16/main/pg_hba.conf
```

### Probleem 2: "Password authentication failed"

```bash
# Kontrolli pg_hba.conf authentication method
# Peaks olema: scram-sha-256 või md5

# Reset password
sudo -u postgres psql
ALTER USER externaluser WITH PASSWORD 'NewPassword123!';
```

### Probleem 3: "SSL required"

```yaml
# Backend environment
environment:
  DB_SSL: "true"
```

Backend kood:
```javascript
const pool = new Pool({
  host: process.env.DB_HOST,
  ssl: process.env.DB_SSL === 'true' ? {
    rejectUnauthorized: false
  } : false
});
```

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd mõistad mõlemat PostgreSQL deployment pattern'i.

**Labor 2 on lõpetatud!**

Järgmises laboris liigume **Kubernetes**'e, kus kasutatakse StatefulSet pattern'i PostgreSQL jaoks!

**Jätka:** [Labor 3: Kubernetes Basics](../../03-kubernetes-basics-lab/README.md)

---

## 📚 Viited

- [PostgreSQL Docker Official Image](https://hub.docker.com/_/postgres)
- [PostgreSQL Administration](https://www.postgresql.org/docs/current/admin.html)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

---

**Õnnitleme! Oskad nüüd hallata PostgreSQL-i nii containerized kui ka external pattern'iga! 🗄️**
