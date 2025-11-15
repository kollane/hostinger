# Lab 2: Docker Compose - Lahendused

See kaust sisaldab Lab 2 harjutuste lahendusi.

---

## 📂 Failide Ülevaade

### Docker Compose Failid

| Fail | Harjutus | Kirjeldus |
|------|----------|-----------|
| `docker-compose.yml` | 1-2 | Base konfiguratsioon (postgres + backend + frontend) |
| `docker-compose.dev.yml` | 3 | Development override (hot reload, debug ports) |
| `docker-compose.prod.yml` | 3 | Production override (optimized, secure, resource limits) |
| `docker-compose.external-db.yml` | 4 | External PostgreSQL pattern (no postgres service) |

### Environment Failid

| Fail | Kirjeldus |
|------|-----------|
| `.env.example` | Template kõigile environment variables |
| `.env.dev` | Development environment variables |
| `.env.prod` | Production environment variables |
| `.env.external` | External PostgreSQL environment variables |

---

## 🚀 Kasutamine

### Harjutus 1-2: Basic Full Stack

```bash
# Kopeeri environment variables
cp .env.example .env
vim .env  # Muuda salasõnad

# Start stack
docker compose up -d

# Kontrolli
docker compose ps
curl http://localhost:3000/health
curl http://localhost:8080

# Vaata loge
docker compose logs -f

# Peata
docker compose down
```

---

### Harjutus 3: Development Environment

```bash
# Start development mode
docker compose -f docker-compose.yml -f docker-compose.dev.yml --env-file .env.dev up -d

# Kontrolli
docker compose -f docker-compose.yml -f docker-compose.dev.yml ps

# Vaata loge (peaks näitama nodemon)
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f backend

# Test hot reload - muuda backend-nodejs/server.js faili
# Backend peaks automaatselt restartima!

# Peata
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
```

---

### Harjutus 3: Production Environment

```bash
# Start production mode
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d --build

# Kontrolli
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps

# Kontrolli resource usage
docker stats prod-backend prod-postgres prod-frontend

# Test health checks
curl http://localhost:3000/health

# Peata
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
```

---

### Harjutus 4: External PostgreSQL

#### Samm 1: Paigalda PostgreSQL VPS-ile

```bash
# SSH VPS-i
ssh janek@kirjakast

# Paigalda PostgreSQL
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Loo andmebaas ja kasutaja
sudo -u postgres psql

# SQL console:
CREATE DATABASE user_service_external;
CREATE USER externaluser WITH PASSWORD 'ExternalPass123!';
GRANT ALL PRIVILEGES ON DATABASE user_service_external TO externaluser;
\q
```

#### Samm 2: Konfigureeri PostgreSQL

```bash
# Muuda postgresql.conf
sudo vim /etc/postgresql/16/main/postgresql.conf
# Muuda: listen_addresses = '*'

# Muuda pg_hba.conf
sudo vim /etc/postgresql/16/main/pg_hba.conf
# Lisa: host    user_service_external    externaluser    0.0.0.0/0    scram-sha-256

# Restart
sudo systemctl restart postgresql

# Kontrolli
sudo ss -tlnp | grep 5432
```

#### Samm 3: Start Docker Compose (ilma PostgreSQL-ita)

```bash
# Start backend + frontend (DB on external)
docker compose -f docker-compose.external-db.yml --env-file .env.external up -d

# Kontrolli
docker compose -f docker-compose.external-db.yml ps

# Test
curl http://localhost:3000/health

# Peata
docker compose -f docker-compose.external-db.yml down
```

---

## 🔧 Kasulikud Käsud

### Üldised Käsud

```bash
# Build images
docker compose build

# Build ilma cache'ita
docker compose build --no-cache

# Start taustal
docker compose up -d

# Start ja jälgi loge
docker compose up

# Peata
docker compose stop

# Start uuesti
docker compose start

# Restart
docker compose restart

# Peata ja eemalda konteinerid
docker compose down

# Peata ja eemalda konteinerid + volumes
docker compose down -v

# Vaata staatust
docker compose ps

# Vaata loge
docker compose logs
docker compose logs -f backend
docker compose logs --tail=100 backend
```

### Debug Käsud

```bash
# Sisene konteinerisse
docker compose exec backend sh
docker compose exec postgres psql -U appuser -d user_service_db

# Vaata konfiguratsioon
docker compose config

# Valideeri compose fail
docker compose config --quiet

# Kontrolli network't
docker network ls
docker network inspect <network-name>

# Kontrolli volume'id
docker volume ls
docker volume inspect <volume-name>
```

### Backup ja Restore

#### PostgreSQL Backup (Containerized)

```bash
# Backup database
docker compose exec postgres pg_dump -U appuser -d user_service_db > backup.sql

# Backup volume
docker run --rm \
  -v <project>_postgres-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-data-backup.tar.gz -C /data .

# Restore database
cat backup.sql | docker compose exec -T postgres psql -U appuser -d user_service_db

# Restore volume
docker run --rm \
  -v <project>_postgres-data:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/postgres-data-backup.tar.gz"
```

#### PostgreSQL Backup (External)

```bash
# Backup
pg_dump -h 93.127.213.242 -U externaluser -d user_service_external > backup.sql

# Restore
psql -h 93.127.213.242 -U externaluser -d user_service_external < backup.sql
```

---

## 📊 Võrdlus: Dev vs Prod

| Aspekt | Development | Production |
|--------|-------------|------------|
| **Volumes** | ✅ Mounted (hot reload) | ❌ No volumes |
| **Ports** | ✅ Exposed (9229 debug) | ⚠️  Only necessary |
| **Restart** | `unless-stopped` | `always` |
| **Security** | Minimal | Max (read-only, no-new-privileges) |
| **Resources** | Unlimited | Limited (CPU/Memory) |
| **Logging** | Verbose (debug) | Minimal (info/warn/error) |
| **Build** | Development target | Production target (optimized) |

---

## 📊 Võrdlus: Containerized vs External PostgreSQL

| Aspekt | Containerized | External |
|--------|---------------|----------|
| **Setup** | ✅ Lihtne | ⚠️  Keerulisem |
| **Deployment** | `docker compose up` | Eraldi PostgreSQL paigaldus |
| **Data Persistence** | Docker volume | VPS disk / Cloud storage |
| **Backup** | Volume backup, pg_dump | pg_dump, WAL archiving |
| **Scaling** | StatefulSet (K8s) | Managed DB (RDS, CloudSQL) |
| **Cost** | ✅ Madal (sama VPS) | ⚠️  Kõrgem (dedicated DB) |
| **Use Case** | Microservices, DevOps | Large production, DBA teams |

---

## 🛡️ Turvalisus

### Environment Variables

❌ **MITTE KUNAGI:**
```yaml
environment:
  DB_PASSWORD: hardcoded123  # NEVER!
```

✅ **ALATI:**
```yaml
environment:
  DB_PASSWORD: ${DB_PASSWORD}  # From .env file
```

```bash
# .gitignore
.env
.env.*
!.env.example
```

### Production Best Practices

```yaml
# docker-compose.prod.yml
services:
  backend:
    restart: always
    read_only: true  # Read-only filesystem
    security_opt:
      - no-new-privileges:true
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
```

---

## 🐛 Troubleshooting

### Probleem: Port already in use

```bash
# Kontrolli, mis kasutab porti
sudo lsof -i :3000
sudo lsof -i :8080

# Muuda port compose fail'is
ports:
  - "3001:3000"  # Kasuta 3001 asemel
```

### Probleem: Can't connect to database

```bash
# Kontrolli DB_HOST
docker compose config | grep DB_HOST
# Peaks olema service nimi (postgres), mitte localhost!

# Kontrolli postgres health
docker compose ps postgres

# Vaata postgres loge
docker compose logs postgres
```

### Probleem: Changes not reflected

```bash
# Rebuild images
docker compose up --build -d

# Force recreate
docker compose up -d --force-recreate
```

### Probleem: Permission denied (volumes)

```bash
# Kontrolli permissions
ls -la ../../apps/backend-nodejs

# Exclude node_modules
volumes:
  - ../../apps/backend-nodejs:/app
  - /app/node_modules  # Important!
```

---

## 📚 Ressursid

- [Docker Compose dokumentatsioon](https://docs.docker.com/compose/)
- [Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Best practices](https://docs.docker.com/compose/production/)
- [Networking](https://docs.docker.com/compose/networking/)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)

---

## ✅ Checklist

Peale Lab 2 läbimist peaksid oskama:

- [ ] Kirjutada `docker-compose.yml` faile
- [ ] Defineerida services, networks, volumes
- [ ] Kasutada environment variables't
- [ ] Luua dev ja prod keskkondi
- [ ] Hallata containerized PostgreSQL-i
- [ ] Konfigureerida external PostgreSQL-i
- [ ] Teha backup'e ja restore'e
- [ ] Debuggida multi-container rakendusi
- [ ] Mõista Docker Compose override pattern'i
- [ ] Rakendada production best practices't

---

**Labor 2 Lahendused Valmis! 🎉**

**Järgmine Labor:** [Lab 3: Kubernetes Basics](../../03-kubernetes-basics-lab/README.md)
