# Peatükk 6: PostgreSQL Konteinerites

**Kestus:** 2-4 tundi
**Tase:** Keskmine
**Eeldused:** Peatükk 4-5 läbitud, Docker volumes mõistetud

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist oskad:

1. ✅ Käivitada PostgreSQL Docker konteineris
2. ✅ Hallata andmete püsivust (volumes)
3. ✅ Seadistada PostgreSQL environment variables
4. ✅ Kasutada psql klienti containeris
5. ✅ Teha backup'e ja restore'e
6. ✅ Monitoorida PostgreSQL performance'i
7. ✅ Debuggida ühenduse probleeme
8. ✅ Mõista konteineriseeritud vs väline PostgreSQL

---

## 🎯 1. Miks PostgreSQL DevOps Kontekstis?

### 1.1 PostgreSQL Rakenduses

**Meie mikroteenused:**
```
Frontend (Port 8080)
    │
    ├──> User Service (Node.js:3000) ──> PostgreSQL (5432)
    └──> Todo Service (Java:8081) ──> PostgreSQL (5433)
```

**Miks PostgreSQL?**
- ✅ Open-source ja tasuta
- ✅ ACID compliance (reliable)
- ✅ Rich features (JSON, full-text search)
- ✅ Excellent Docker support
- ✅ Industry standard (Twitter, Instagram, Spotify)

---

### 1.2 DevOps Administraatori Roll

**Mida DevOps Administraator TEEB:**
```bash
✅ Käivitab PostgreSQL konteinereid
✅ Haldab volumes (data persistence)
✅ Seadistab environment variables
✅ Teeb backup'e ja restore'e
✅ Monitoorib performance'i (connections, queries)
✅ Debuggib ühenduse probleeme
✅ Skaleerib andmebaasi (replicas, sharding - advanced)
```

**Mida DevOps Administraator EI TEE:**
```bash
❌ Ei kirjuta SQL päringuid (arendaja töö)
❌ Ei disaini database skeeme (arendaja/DBA töö)
❌ Ei implementeeri ORM logic'ut (arendaja töö)
```

**Analoogia:**
```
DevOps Administraator : PostgreSQL = Automehhaanik : Mootor

Mehhaanik:
✅ Hooldab mootorit
✅ Vahetab õli
✅ Debuggib probleeme
❌ Ei disaini mootorit
❌ Ei tooda mootorit

DevOps:
✅ Haldab PostgreSQL konteinerit
✅ Teeb backup'e
✅ Monitoorib performance'i
❌ Ei kirjuta SQL päringuid
❌ Ei disaini skeeme
```

---

## 🐳 2. PostgreSQL Docker Konteineris - PRIMAARNE Lähenemine

### 2.1 Miks Konteineriseerida PostgreSQL?

**Eelised:**
- ✅ Kiire setup (1 käsk vs mitu sammu)
- ✅ Isolatsioon (eraldi konteinerid dev/test/prod)
- ✅ Portability (töötab kõikjal)
- ✅ Easy cleanup (docker rm = kõik kadunud)
- ✅ Version management (postgres:14, postgres:15, postgres:16)

**Millal MITTE kasutada:**
- ❌ VÄGA suur production database (TB'id)
- ❌ Legacy systeem ilma containeriteta
- ❌ Spetsiifilised performance requirements (dedicated hardware)

---

### 2.2 Lihtne PostgreSQL Container (Testimiseks)

```bash
# ⚠️ EPHEMERAL - Data kaob pärast container'i kustutamist!
docker run -d \
  --name postgres-test \
  -e POSTGRES_PASSWORD=mysecret \
  -p 5432:5432 \
  postgres:16-alpine

# Test connection
docker exec -it postgres-test psql -U postgres
# postgres=# \l
# postgres=# \q

# ❌ PROBLEEM: Kui container kustutatakse, DATA KAOB!
docker rm -f postgres-test  # Kõik data KADUNUD!
```

---

### 2.3 PostgreSQL Container Volume'iga (SOOVITATUD)

**Volume lifecycle:**
```
Container (ephemeral)  ←→  Volume (persistent)
     ↓                           ↓
Container kustub          Volume jääb alles!
```

**Loo volume ja käivita PostgreSQL:**
```bash
# 1. Loo dedicated volume
docker volume create pgdata

# 2. Käivita PostgreSQL volume'iga
docker run -d \
  --name postgres \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=secret123 \
  -e POSTGRES_DB=myapp_db \
  -v pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16-alpine

# 3. Verify running
docker ps | grep postgres

# 4. Loo test data
docker exec -it postgres psql -U appuser -d myapp_db <<EOF
CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT);
INSERT INTO users (name) VALUES ('Alice'), ('Bob'), ('Charlie');
SELECT * FROM users;
EOF

# 5. Kustuta container (aga mitte volume!)
docker rm -f postgres

# 6. Käivita UUS container SAMA volume'iga
docker run -d \
  --name postgres-new \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=secret123 \
  -e POSTGRES_DB=myapp_db \
  -v pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16-alpine

# 7. Kontrolli, et data säilis
docker exec -it postgres-new psql -U appuser -d myapp_db \
  -c "SELECT * FROM users;"

# ✅ Alice, Bob, Charlie on olemas! DATA SÄILIS!
```

---

### 2.4 PostgreSQL Environment Variables

**Põhilised environment variables:**

```bash
# Kohustuslikud:
POSTGRES_PASSWORD=secret123       # Superuser (postgres) parool

# Soovi valikud (muidu defaults):
POSTGRES_USER=appuser            # Custom user (default: postgres)
POSTGRES_DB=myapp_db             # Initial database (default: $POSTGRES_USER)

# Täiendavad:
POSTGRES_INITDB_ARGS="--encoding=UTF8 --locale=en_US.UTF-8"
PGDATA=/var/lib/postgresql/data  # Data directory (default)
```

**Näide koos kõigiga:**
```bash
docker run -d \
  --name postgres \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=very-secret-password \
  -e POSTGRES_DB=production_db \
  -e POSTGRES_INITDB_ARGS="--encoding=UTF8" \
  -v pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16-alpine
```

---

### 2.5 PostgreSQL Ports ja Networking

**Port mapping:**
```bash
# Host port 5432 → Container port 5432
docker run -p 5432:5432 postgres:16-alpine

# Mitu PostgreSQL konteinerit? Erinev host port!
docker run -p 5432:5432 --name pg1 postgres:16-alpine  # User Service DB
docker run -p 5433:5432 --name pg2 postgres:16-alpine  # Todo Service DB
                 ↑
           Erinev host port
```

**Custom network (multi-container):**
```bash
# 1. Loo network
docker network create app-network

# 2. PostgreSQL samas network'is
docker run -d \
  --name postgres \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  postgres:16-alpine

# 3. Backend ühendub "postgres" hostname'i järgi
docker run -d \
  --name backend \
  --network app-network \
  -e DB_HOST=postgres \   # ← Hostname = container name!
  -e DB_PORT=5432 \
  backend-app

# 4. Test network connection
docker exec backend ping -c 3 postgres  # ✅ Töötab!
```

---

## 🔧 3. psql Klient - PostgreSQL CLI

### 3.1 psql Põhikäsud

**Ühenda PostgreSQL'iga (containeris):**
```bash
# Variant 1: exec -it
docker exec -it postgres psql -U appuser -d myapp_db

# Variant 2: exec ilma -it (scripting)
docker exec postgres psql -U appuser -d myapp_db -c "SELECT * FROM users;"

# Variant 3: Kui psql on host'is installitud
psql -h localhost -p 5432 -U appuser -d myapp_db
```

**psql meta-käsud:**
```sql
-- List databases
\l

-- Connect to database
\c myapp_db

-- List tables
\dt

-- Describe table
\d users

-- List users/roles
\du

-- Quit
\q

-- Help
\?
```

---

### 3.2 Praktilised psql Näited

**Create database:**
```bash
docker exec -it postgres psql -U postgres <<EOF
CREATE DATABASE user_service_db;
CREATE DATABASE todo_service_db;
\l
EOF
```

**Create user and grant permissions:**
```bash
docker exec -it postgres psql -U postgres <<EOF
CREATE USER appuser WITH PASSWORD 'secret123';
GRANT ALL PRIVILEGES ON DATABASE myapp_db TO appuser;
\du
EOF
```

**Check connections:**
```bash
docker exec postgres psql -U postgres -c \
  "SELECT pid, usename, application_name, client_addr, state
   FROM pg_stat_activity
   WHERE datname = 'myapp_db';"
```

---

## 💾 4. Backup ja Restore

### 4.1 pg_dump - Logical Backup

**Single database backup:**
```bash
# 1. Loo backup
docker exec postgres pg_dump -U appuser myapp_db > backup.sql

# 2. Verify backup
ls -lh backup.sql
# -rw-r--r-- 1 user staff  1.5M  backup.sql

# 3. Vaata sisu (optional)
head -n 20 backup.sql
```

**Backup koos kompressiooniga:**
```bash
# Gzip compression
docker exec postgres pg_dump -U appuser myapp_db | gzip > backup.sql.gz

# Output: backup.sql.gz (10x väiksem!)
```

**Custom format (recommended):**
```bash
# Custom format (fast restore, parallel)
docker exec postgres pg_dump -U appuser -Fc myapp_db > backup.dump

# -Fc = custom format
# -Ft = tar format
# -Fp = plain SQL (default)
```

---

### 4.2 Restore

**Plain SQL restore:**
```bash
# 1. Loo uus database
docker exec postgres psql -U postgres -c "CREATE DATABASE myapp_db_restore;"

# 2. Restore backup
docker exec -i postgres psql -U appuser myapp_db_restore < backup.sql

# 3. Verify
docker exec postgres psql -U appuser myapp_db_restore -c "\dt"
```

**Custom format restore:**
```bash
# pg_restore with custom format
cat backup.dump | docker exec -i postgres pg_restore -U appuser -d myapp_db_restore

# Parallel restore (faster!)
cat backup.dump | docker exec -i postgres pg_restore -U appuser -d myapp_db_restore -j 4

# -j 4 = 4 parallel jobs
```

---

### 4.3 Automated Backup (Cron Job)

**Host machine cron job:**
```bash
# 1. Loo backup script
cat > /usr/local/bin/postgres-backup.sh <<'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=/backups/postgres
mkdir -p $BACKUP_DIR

docker exec postgres pg_dump -U appuser myapp_db | \
  gzip > $BACKUP_DIR/myapp_db_$DATE.sql.gz

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup completed: myapp_db_$DATE.sql.gz"
EOF

chmod +x /usr/local/bin/postgres-backup.sh

# 2. Lisa crontab (iga päev 2AM)
crontab -e
# 0 2 * * * /usr/local/bin/postgres-backup.sh >> /var/log/postgres-backup.log 2>&1

# 3. Test
/usr/local/bin/postgres-backup.sh
ls -lh /backups/postgres/
```

---

## 📊 5. Performance Monitoring

### 5.1 pg_stat_activity - Active Connections

```bash
# Vaata active connections
docker exec postgres psql -U postgres <<EOF
SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start,
  LEFT(query, 50) as query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;
EOF
```

---

### 5.2 Database Size

```bash
# Vaata database suurusi
docker exec postgres psql -U postgres -c \
  "SELECT
     pg_database.datname,
     pg_size_pretty(pg_database_size(pg_database.datname)) AS size
   FROM pg_database
   ORDER BY pg_database_size(pg_database.datname) DESC;"

# Output:
#     datname      |  size
# -----------------+---------
#  myapp_db        | 15 MB
#  postgres        | 8537 kB
#  template1       | 8393 kB
```

---

### 5.3 Table Sizes

```bash
# Vaata table suurusi
docker exec postgres psql -U appuser -d myapp_db -c \
  "SELECT
     schemaname,
     tablename,
     pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
   FROM pg_tables
   WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
   ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

---

### 5.4 Slow Queries (pg_stat_statements)

**Enable pg_stat_statements:**
```bash
# 1. Restart PostgreSQL with shared_preload_libraries
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_INITDB_ARGS="-c shared_preload_libraries=pg_stat_statements" \
  postgres:16-alpine

# 2. Enable extension
docker exec postgres psql -U postgres -c \
  "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"

# 3. Vaata slow queries
docker exec postgres psql -U postgres -c \
  "SELECT
     calls,
     total_exec_time,
     mean_exec_time,
     LEFT(query, 60) as query
   FROM pg_stat_statements
   ORDER BY mean_exec_time DESC
   LIMIT 10;"
```

---

## 🐛 6. Troubleshooting

### 6.1 "Connection Refused"

**Probleem:**
```bash
docker logs backend
# Error: connect ECONNREFUSED postgres:5432
```

**Troubleshooting sammud:**

```bash
# 1. Kontrolli, et PostgreSQL töötab
docker ps | grep postgres

# 2. Kontrolli PostgreSQL logisid
docker logs postgres

# 3. Testi connection host'ist
docker exec postgres psql -U postgres -c "SELECT 1;"

# 4. Kontrolli network'i
docker network inspect app-network | grep postgres

# 5. Testi DNS resolution
docker exec backend ping -c 3 postgres
docker exec backend nslookup postgres

# Levinud põhjused:
# - PostgreSQL pole veel valmis (kasuta healthcheck)
# - Vale hostname (peaks olema container name)
# - Eri network'id (peavad olema samas network'is)
```

---

### 6.2 "Password Authentication Failed"

**Probleem:**
```bash
psql: error: FATAL: password authentication failed for user "appuser"
```

**Lahendus:**
```bash
# 1. Kontrolli environment variables
docker inspect postgres | grep POSTGRES

# 2. Kontrolli pg_hba.conf
docker exec postgres cat /var/lib/postgresql/data/pg_hba.conf | tail -5

# 3. Reset password
docker exec postgres psql -U postgres -c \
  "ALTER USER appuser WITH PASSWORD 'new-password';"

# 4. Test
docker exec postgres psql -U appuser -c "SELECT 1;"
```

---

### 6.3 "Too Many Connections"

**Probleem:**
```bash
FATAL: sorry, too many clients already
```

**Lahendus:**
```bash
# 1. Vaata current connections
docker exec postgres psql -U postgres -c \
  "SELECT count(*) FROM pg_stat_activity;"

# 2. Vaata max_connections
docker exec postgres psql -U postgres -c "SHOW max_connections;"
# max_connections: 100 (default)

# 3. Suurenda max_connections
# Variant A: Environment variable
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=secret \
  -c max_connections=200 \
  postgres:16-alpine

# Variant B: Custom postgresql.conf (advanced)
# - Mount custom conf file
```

**Parem lahendus: Connection pooling (PgBouncer)** - Hiljem Kubernetes peatükis!

---

## 🆚 7. Konteineriseeritud vs Väline PostgreSQL

### 7.1 Konteineriseeritud PostgreSQL (PRIMARY)

**Millal kasutada:**
- ✅ Mikroteenused (iga service oma DB)
- ✅ Development ja testing
- ✅ Kubernetes orkestratsioon (StatefulSet)
- ✅ Cloud-native rakendused
- ✅ Auto-scaling environments

**Plussid:**
- ✅ Kiire setup ja cleanup
- ✅ Isolatsioon
- ✅ Version control (image tags)
- ✅ Portability

**Miinused:**
- ❌ Volume management (NFS, cloud storage)
- ❌ Performance overhead (volume drivers)

---

### 7.2 Väline PostgreSQL (ALTERNATIVE)

**Millal kasutada:**
- ✅ Legacy süsteemid
- ✅ Väga suur database (TB'id)
- ✅ Dedicated DBA team
- ✅ Spetsiifilised compliance requirements

**Setup:**
```bash
# 1. Install PostgreSQL host'is
sudo apt install postgresql-16 -y

# 2. Configure
sudo vim /etc/postgresql/16/main/postgresql.conf
# listen_addresses = '*'

sudo vim /etc/postgresql/16/main/pg_hba.conf
# host  all  all  0.0.0.0/0  scram-sha-256

# 3. Restart
sudo systemctl restart postgresql

# 4. Backend ühendub IP'ga
docker run -d \
  --name backend \
  -e DB_HOST=YOUR_VPS_IP \
  -e DB_PORT=5432 \
  backend-app
```

---

## 📝 8. Praktilised Harjutused

### Harjutus 1: PostgreSQL Volume Lifecycle (30 min)

**Eesmärk:** Õpi volume'ite kasutamist

**Sammud:**
```bash
# 1. Loo volume
docker volume create mydata

# 2. Käivita PostgreSQL
docker run -d --name db1 \
  -e POSTGRES_PASSWORD=secret \
  -v mydata:/var/lib/postgresql/data \
  postgres:16-alpine

# 3. Loo data
docker exec db1 psql -U postgres -c \
  "CREATE TABLE test (id INT, name TEXT); \
   INSERT INTO test VALUES (1, 'Alice');"

# 4. Kustuta container
docker rm -f db1

# 5. Käivita UUS container sama volume'iga
docker run -d --name db2 \
  -e POSTGRES_PASSWORD=secret \
  -v mydata:/var/lib/postgresql/data \
  postgres:16-alpine

# 6. Verify data säilis
docker exec db2 psql -U postgres -c "SELECT * FROM test;"
```

**Kontrolli:**
- [ ] Data säilis pärast container'i kustutamist
- [ ] Uus container näeb vana data
- [ ] Volume jääb alles pärast rm

---

### Harjutus 2: Multi-Database Setup (30 min)

**Eesmärk:** Loo 2 eraldi PostgreSQL instantsi

**Sammud:**
```bash
# 1. User Service DB
docker run -d \
  --name postgres-user \
  -e POSTGRES_DB=user_service_db \
  -e POSTGRES_USER=userapp \
  -e POSTGRES_PASSWORD=secret1 \
  -v pgdata-user:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16-alpine

# 2. Todo Service DB
docker run -d \
  --name postgres-todo \
  -e POSTGRES_DB=todo_service_db \
  -e POSTGRES_USER=todoapp \
  -e POSTGRES_PASSWORD=secret2 \
  -v pgdata-todo:/var/lib/postgresql/data \
  -p 5433:5432 \
  postgres:16-alpine

# 3. Test mõlemat
docker exec postgres-user psql -U userapp -d user_service_db -c "SELECT version();"
docker exec postgres-todo psql -U todoapp -d todo_service_db -c "SELECT version();"

# 4. Vaata porte
docker ps | grep postgres
```

**Kontrolli:**
- [ ] Kaks eraldi PostgreSQL konteinerit
- [ ] Erinevad host portid (5432, 5433)
- [ ] Erinevad volumes

---

### Harjutus 3: Backup ja Restore (40 min)

**Eesmärk:** Õpi backup/restore workflow

**Sammud:**
```bash
# 1. Loo test data
docker exec postgres psql -U postgres -c \
  "CREATE DATABASE testdb; \
   \c testdb \
   CREATE TABLE products (id SERIAL, name TEXT, price DECIMAL); \
   INSERT INTO products (name, price) VALUES ('Laptop', 999.99), ('Mouse', 29.99);"

# 2. Backup
docker exec postgres pg_dump -U postgres testdb > testdb_backup.sql
ls -lh testdb_backup.sql

# 3. "Kustuta" database
docker exec postgres psql -U postgres -c "DROP DATABASE testdb;"

# 4. Verify kustutatud
docker exec postgres psql -U postgres -c "\l" | grep testdb
# Ei peaks leidma!

# 5. Restore
docker exec postgres psql -U postgres -c "CREATE DATABASE testdb;"
docker exec -i postgres psql -U postgres testdb < testdb_backup.sql

# 6. Verify restored
docker exec postgres psql -U postgres testdb -c "SELECT * FROM products;"
```

**Kontrolli:**
- [ ] Backup fail on loodud
- [ ] Restore töötab
- [ ] Data on täpselt sama

---

### Harjutus 4: Performance Monitoring (30 min)

**Eesmärk:** Õpi monitoorima PostgreSQL'i

**Sammud:**
```bash
# 1. Enable pg_stat_statements
docker exec postgres psql -U postgres -c \
  "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"

# 2. Genereeri fake load
for i in {1..100}; do
  docker exec postgres psql -U postgres -c \
    "SELECT * FROM pg_database;" > /dev/null
done

# 3. Vaata connections
docker exec postgres psql -U postgres -c \
  "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"

# 4. Vaata database sizes
docker exec postgres psql -U postgres -c \
  "SELECT datname, pg_size_pretty(pg_database_size(datname))
   FROM pg_database
   ORDER BY pg_database_size(datname) DESC;"

# 5. Vaata slow queries
docker exec postgres psql -U postgres -c \
  "SELECT calls, mean_exec_time, LEFT(query, 50)
   FROM pg_stat_statements
   ORDER BY mean_exec_time DESC
   LIMIT 5;"
```

**Kontrolli:**
- [ ] pg_stat_statements on enabled
- [ ] Oskad vaadata active connections
- [ ] Oskad vaadata database sizes
- [ ] Oskad analüüsida slow queries

---

## 🎓 9. Mida Sa Õppisid?

✅ **PostgreSQL Konteineriseerimise:**
- Docker run with environment variables
- Volume lifecycle ja data persistence
- Port mapping (5432:5432)
- Multi-database setup

✅ **psql Klient:**
- Meta-käsud (\l, \dt, \d, \du)
- SQL päringute käivitamine
- Scripting (exec -i)

✅ **Backup ja Restore:**
- pg_dump (logical backup)
- pg_restore (custom format)
- Automated backups (cron)
- Compression (gzip)

✅ **Performance Monitoring:**
- pg_stat_activity (connections)
- Database sizes
- Table sizes
- pg_stat_statements (slow queries)

✅ **Troubleshooting:**
- Connection refused
- Authentication failed
- Too many connections
- Network debugging

---

## 🚀 10. Järgmised Sammud

**Peatükk 7: Docker Compose** 🐳
- Multi-container orchestration
- Frontend + Backend + PostgreSQL koos
- Networks ja service discovery
- depends_on ja healthchecks
- **LIHTSAM VIIS MITME KONTEINERI HALDAMISEKS!**

**Peatükk 9: Kubernetes Alused** ☸️
- PostgreSQL StatefulSet
- PersistentVolumeClaims
- Production-ready database deployment

---

## ✅ Kontrolli Ennast

- [ ] Oskad käivitada PostgreSQL Docker konteineris
- [ ] Mõistad volume lifecycle'i ja data persistence
- [ ] Oskad kasutada psql klienti
- [ ] Oskad teha backup'e ja restore'e
- [ ] Oskad monitoorida PostgreSQL performance'i
- [ ] Oskad debuggida ühenduse probleeme
- [ ] Oled läbinud kõik 4 praktilist harjutust

**Kui kõik on ✅, oled valmis Peatükiks 7!** 🚀

---

**Peatükk 6 lõpp**
**Järgmine:** Peatükk 7 - Docker Compose

**Õnnitleme!** Oskad nüüd hallata PostgreSQL'i konteinerites! 🐘🐳
