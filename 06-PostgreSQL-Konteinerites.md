# Peatükk 6: PostgreSQL Konteinerites

**Kestus:** 2-4 tundi
**Tase:** Keskmine
**Eeldused:** Peatükk 4-5 läbitud, Docker volumes mõistetud

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist oskad:

1. ✅ Selgitada stateful vs stateless rakenduste erinevusi
2. ✅ Mõista volume lifecycle management'i andmebaasidele
3. ✅ Selgitada PostgreSQL konteineriseerimise eeliseid ja kompromisse
4. ✅ Mõista data persistence strateegiaid
5. ✅ Selgitada backup/restore arhitektuure
6. ✅ Rakendada observability PostgreSQL'ile (connections, queries, size)
7. ✅ Debuggida ühenduse probleeme (network, authentication)
8. ✅ Mõista containerized vs external PostgreSQL trade-off'e

---

## 🎯 1. Stateful Applications: PostgreSQL DevOps Kontekstis

### 1.1 Stateless vs Stateful Applications

**Stateless (Frontend, Backend API):**
- Ei hoia state'i (iga request on independent)
- Container restart → no data loss
- Scalable: 10 identical replicas

 (load balance)
- Ephemeral filesystem OK

**Stateful (Database):**
- Hoiab critical state (database files)
- Container restart → **PEAB SÄILITAMA DATA**
- Scaling: complex (replication, sharding)
- **REQUIRES persistent storage (volumes)**

**Miks see on oluline DevOps'ile?**

Stateless apps: "Cattle" - identne, asendatav, skaleeritav
Stateful apps: "Pets" - unique, hooldust vajav, data on critical

**PostgreSQL in our architecture:**

```
Frontend (Stateless) → Backend (Stateless) → PostgreSQL (Stateful)
   ↓                        ↓                      ↓
Ei vaja volume          Ei vaja volume        VOLUME KRITILINE!
```

---

### 1.2 DevOps Administraatori Roll PostgreSQL'i Jaoks

**DevOps responsibilities:**

1. **Infrastructure management:**
   - Provision PostgreSQL containers/servers
   - Configure networking (port mapping, DNS)
   - Manage volumes (create, backup, restore)

2. **Operational tasks:**
   - Monitor performance (connections, query times, disk usage)
   - Execute backups (automated schedules)
   - Troubleshoot connectivity (network, authentication)
   - Scale (replicas, read-only slaves)

3. **Security:**
   - Manage credentials (environment variables, secrets)
   - Configure access control (pg_hba.conf)
   - SSL/TLS for connections

**DevOps EI TEE:**
- ❌ SQL query writing (developer responsibility)
- ❌ Schema design (developer/DBA responsibility)
- ❌ ORM configuration (developer responsibility)
- ❌ Query optimization (DBA/developer responsibility)

**Analogy:**

```
DevOps : PostgreSQL = Datacenter Engineer : Server Hardware

Datacenter Engineer:
- Provisions servers
- Monitors power, cooling, network
- Replaces failed hardware
- Does NOT write software

DevOps:
- Provisions PostgreSQL containers
- Monitors connections, performance
- Manages backups, restores
- Does NOT write SQL queries
```

---

## 🐳 2. PostgreSQL Containerization: Architecture and Trade-offs

### 2.1 Miks Konteineriseerida PostgreSQL?

**Benefits:**

1. **Rapid provisioning:**
   - Traditional: Install PostgreSQL, configure, initialize (hours)
   - Container: One command (seconds)

2. **Environment consistency:**
   - Dev PostgreSQL 16 = Staging PostgreSQL 16 = Prod PostgreSQL 16
   - Same configuration (postgresql.conf as code)

3. **Isolation:**
   - Multiple PostgreSQL versions on same host (different containers)
   - User Service DB (port 5432) + Todo Service DB (port 5433)

4. **Version management:**
   - Easy upgrades: `postgres:14` → `postgres:16`
   - Rollback: Keep old container stopped (failover)

5. **Resource limits:**
   - cgroups enforce memory/CPU limits
   - Prevents runaway queries from killing host

**Trade-offs:**

1. **Performance overhead:**
   - Container layer adds ~2-5% overhead (minimal)
   - Volume I/O slightly slower than native filesystem (minimal in practice)

2. **Operational complexity:**
   - Must manage volumes separately (data persists beyond container)
   - Backup/restore workflow different from traditional

3. **Not suitable for all scenarios:**
   - Very large databases (multi-TB) - dedicated hardware better
   - Specialized hardware requirements (NVMe, RAID controllers)
   - Legacy systems without container orchestration

---

### 2.2 Volume Architecture: Data Persistence

**Container ephemeral filesystem problem:**

```
Container: /var/lib/postgresql/data (inside container layer)
    ↓
Container deleted → Data LOST!
```

**Solution: Volume mounting**

```
Host Volume: /var/lib/docker/volumes/pgdata/_data
    ↓ (mount)
Container: /var/lib/postgresql/data
    ↓
Container deleted → Volume PERSISTS!
```

**Volume lifecycle:**

1. **Create:** `docker volume create pgdata` (one-time)
2. **Mount:** Container starts, mounts volume to `/var/lib/postgresql/data`
3. **Use:** PostgreSQL writes data files to volume
4. **Persist:** Container stops/deleted → volume remains
5. **Reuse:** New container mounts same volume → data intact

**Why this architecture?**

- **Decoupling:** Storage lifecycle independent of container lifecycle
- **Portability:** Volume can be backed up, migrated to another host
- **Kubernetes alignment:** PersistentVolume (PV) + PersistentVolumeClaim (PVC) same pattern

---

### 2.3 PostgreSQL Configuration via Environment Variables

**12-Factor App: Configuration as environment variables**

**PostgreSQL image environment variables:**

```
POSTGRES_PASSWORD (required)    - Superuser password
POSTGRES_USER (optional)        - Custom superuser name (default: postgres)
POSTGRES_DB (optional)          - Initial database name (default: $POSTGRES_USER)
POSTGRES_INITDB_ARGS (optional) - initdb arguments (encoding, locale)
```

**Why environment variables?**

1. **No hardcoded secrets:** Password not in Dockerfile (security)
2. **Environment parity:** Same image, different config (dev vs prod)
3. **Orchestration-friendly:** Kubernetes ConfigMap/Secret integration
4. **Immutable containers:** Config change = restart container (not rebuild image)

**Configuration hierarchy:**

```
1. Dockerfile ENV (defaults)
2. docker run -e (runtime override)
3. Docker Compose environment section
4. Kubernetes ConfigMap/Secret
```

**Example use case:**

```
Development: POSTGRES_PASSWORD=dev123
Staging: POSTGRES_PASSWORD=staging-secret-from-vault
Production: POSTGRES_PASSWORD=<injected from AWS Secrets Manager>
```

📖 **Praktika:** Labor 2, Harjutus 1 - PostgreSQL container setup

---

### 2.4 Networking: Port Mapping and DNS Resolution

**Port mapping for external access:**

```
Host port 5432 → Container port 5432
    ↓
psql -h localhost -p 5432 (from host)
    ↓
NAT (Docker daemon iptables rules)
    ↓
Container PostgreSQL on 172.17.0.2:5432
```

**Multiple PostgreSQL containers:**

```
Container 1: Host 5432 → Container 5432 (User Service DB)
Container 2: Host 5433 → Container 5432 (Todo Service DB)
```

**Custom network for container-to-container communication:**

```
Backend container:
DB_HOST=postgres (container name)
DB_PORT=5432

Docker DNS:
postgres → 172.18.0.2 (automatic resolution)

Backend connects to 172.18.0.2:5432 (PostgreSQL container)
```

**Why custom network?**

- **DNS resolution:** Container names resolve automatically
- **Isolation:** Backend and DB in private network (frontend cannot access DB directly)
- **Security:** Defense in depth (network segmentation)

📖 **Praktika:** Labor 2, Harjutus 2 - Multi-container networking

---

## 🔧 3. PostgreSQL Client (psql): Observability Interface

### 3.1 psql Role in DevOps Workflow

**psql is the interactive terminal for PostgreSQL.**

**DevOps use cases:**

1. **Verification:**
   - Database created? (`\l`)
   - Tables exist? (`\dt`)
   - User permissions correct? (`\du`)

2. **Troubleshooting:**
   - Active connections? (`SELECT * FROM pg_stat_activity`)
   - Lock contention? (`SELECT * FROM pg_locks`)
   - Query performance? (pg_stat_statements)

3. **Operational tasks:**
   - Create databases/users
   - Grant permissions
   - Reset passwords

**psql access methods:**

1. **Inside container:** `docker exec -it postgres psql -U postgres`
2. **From host:** `psql -h localhost -p 5432 -U postgres` (requires psql installed)
3. **Scripted:** `docker exec postgres psql -U postgres -c "SELECT 1;"`

**Meta-commands (DevOps essentials):**

```
\l              - List databases (verify DB exists)
\c <database>   - Connect to database (switch context)
\dt             - List tables (verify schema applied)
\d <table>      - Describe table (check columns, indexes)
\du             - List users/roles (verify permissions)
```

---

### 3.2 Connection Management

**Active connections monitoring:**

```sql
SELECT pid, usename, application_name, client_addr, state, query
FROM pg_stat_activity
WHERE state != 'idle';
```

**Why monitor connections?**

1. **Capacity planning:** How many connections does app need?
2. **Troubleshooting:** "Too many connections" error → identify leak
3. **Performance:** Idle connections consume resources

**max_connections configuration:**

- Default: 100 connections
- Each connection consumes ~10MB RAM
- Formula: max_connections = (Available RAM - Shared Buffers) / 10MB

**Connection pooling (application-side):**

- **Problem:** Opening connection = expensive (auth, SSL handshake)
- **Solution:** Connection pool (HikariCP for Java, pg-pool for Node.js)
- Pool maintains N connections, reuses them

**DevOps responsibility:**

- Configure max_connections based on workload
- Monitor connection usage (pg_stat_activity)
- Alert on >80% capacity

---

## 💾 4. Backup and Restore: Data Protection Strategies

### 4.1 Backup Architecture: Logical vs Physical

**Logical backups (pg_dump):**

```
Database → pg_dump → SQL file → Restore with psql
```

**Characteristics:**
- **Portable:** SQL is database-agnostic (can restore to different PostgreSQL version)
- **Selective:** Can backup single table, schema, or database
- **Slow:** Dumps data row-by-row
- **Use case:** Development, small databases, cross-version migration

**Physical backups (pg_basebackup):**

```
Database file directory → Copy files → Restore by replacing data directory
```

**Characteristics:**
- **Fast:** File-level copy (no SQL parsing)
- **Version-specific:** Must restore to same PostgreSQL version
- **All-or-nothing:** Cannot restore single table
- **Use case:** Production, large databases, PITR (Point-In-Time Recovery)

**DevOps choice:**

- **Development/testing:** Logical backups (pg_dump) - flexibility
- **Production:** Physical backups (pg_basebackup) - speed, PITR

---

### 4.2 Backup Strategies

**Full backup:**

```
pg_dump entire database → backup.sql (or backup.dump)
```

**Incremental backup:**

```
WAL (Write-Ahead Logging) files → Archive WAL segments
```

**PITR (Point-In-Time Recovery):**

```
Full backup (Sunday) + WAL archive (Monday-Saturday)
    ↓
Can restore to ANY point in time (e.g., Thursday 14:35)
```

**Backup schedule (production example):**

```
Daily: Full backup (2 AM)
Continuous: WAL archiving (every 16MB WAL segment)
Weekly: Offsite copy (S3, cloud storage)
Retention: 7 days local, 30 days offsite
```

**Automation:**

- **Cron:** Host-level scheduled backups
- **Kubernetes CronJob:** Cluster-level backup jobs
- **Managed services:** AWS RDS automated backups

---

### 4.3 Restore Scenarios

**Scenario 1: Database corruption**

```
Problem: Table deleted accidentally
Solution: Restore from last night's backup (lose today's changes)
```

**Scenario 2: Application bug deployed**

```
Problem: Bug corrupted data at 14:30
Solution: PITR to 14:29 (recover everything before corruption)
```

**Scenario 3: Disaster recovery**

```
Problem: Server crashed, volume lost
Solution: Restore backup to new server, resume from last backup point
```

**RTO (Recovery Time Objective):**
- How quickly can you restore? (e.g., 1 hour)
- Depends on: Backup size, network speed, storage I/O

**RPO (Recovery Point Objective):**
- How much data can you afford to lose? (e.g., 1 hour of transactions)
- Depends on: Backup frequency, WAL archiving

**DevOps responsibility:**

- Define RTO/RPO requirements (with business stakeholders)
- Implement backup strategy meeting RTO/RPO
- **TEST RESTORES REGULARLY** (backup is useless if restore fails!)

📖 **Praktika:** Labor 2, Harjutus 3 - Backup and restore workflow

---

## 📊 5. Observability: Performance and Capacity Monitoring

### 5.1 Key Metrics for PostgreSQL

**1. Connection metrics:**
- **active_connections:** Currently executing queries
- **idle_connections:** Connected but not executing
- **max_connections:** Configured limit

**Why important:** Too many connections → "too many clients" error

**2. Query performance:**
- **mean_exec_time:** Average query execution time
- **total_exec_time:** Total time spent in queries
- **calls:** Number of times query executed

**Why important:** Slow queries → application timeouts, poor UX

**3. Database size:**
- **database_size:** Total database size (GB)
- **table_size:** Individual table sizes

**Why important:** Disk space planning, backup duration estimation

**4. Cache hit ratio:**
- **cache_hit_ratio:** % of data served from RAM vs disk
- Target: >99% (if <90%, increase shared_buffers)

**Why important:** Low cache hit = slow queries (disk I/O bottleneck)

---

### 5.2 pg_stat_activity: Real-Time Connection View

**What it shows:**

- PID of backend process
- Connected user and database
- Client IP address
- Current query being executed
- State (active, idle, idle in transaction)
- Query start time

**DevOps use cases:**

1. **Troubleshoot "too many connections":**
   - Query pg_stat_activity → count connections
   - Identify which app/user consuming connections

2. **Find long-running queries:**
   - Filter by query_start > 1 minute ago
   - Identify slow queries blocking others

3. **Detect connection leaks:**
   - "Idle in transaction" for long time = app not closing transactions
   - Fix: Application connection pool configuration

---

### 5.3 pg_stat_statements: Query Performance Analysis

**What it tracks:**

- Every unique query (normalized)
- Execution count (calls)
- Total execution time
- Mean execution time
- Rows returned/affected

**Example insight:**

```
Query: SELECT * FROM users WHERE email = ?
Calls: 10,000
Mean exec time: 500ms
Total time: 5,000,000ms (5000 seconds!)

Action: Add index on email column → mean exec time drops to 5ms
```

**DevOps responsibility:**

- Enable pg_stat_statements extension
- Monitor top slow queries
- **Collaborate with developers:** "Query X is slow, can you optimize?"

📖 **Praktika:** Labor 2, Harjutus 4 - Performance monitoring

---

## 🐛 6. Troubleshooting Common Issues

### 6.1 Connection Refused

**Symptom:**

```
Application logs: Error: connect ECONNREFUSED postgres:5432
```

**Diagnostic workflow:**

1. **Is PostgreSQL running?**
   - `docker ps | grep postgres` → Container status
   - `docker logs postgres` → Check startup errors

2. **Is PostgreSQL ready?**
   - PostgreSQL takes 5-10 seconds to initialize
   - Use HEALTHCHECK in Dockerfile (wait for readiness)

3. **Network connectivity?**
   - `docker exec backend ping postgres` → DNS resolution works?
   - Are containers in same network? (`docker network inspect`)

4. **Port mapping correct?**
   - Host: `psql -h localhost -p 5432` works?
   - Container: Different port mapping? (5432 vs 5433)

**Common causes:**

- PostgreSQL not ready yet (startup race condition)
- Wrong hostname (typo: "postgre" instead of "postgres")
- Different networks (backend in app-network, DB in default bridge)

**Solution:**

- Add healthcheck to PostgreSQL container
- Use `depends_on` + `condition: service_healthy` (Docker Compose)

---

### 6.2 Authentication Failed

**Symptom:**

```
psql: error: FATAL: password authentication failed for user "appuser"
```

**Causes:**

1. **Wrong password:**
   - Environment variable typo (POSTGRES_PASSWORD vs DB_PASSWORD)
   - Password changed, app config not updated

2. **User doesn't exist:**
   - Database initialized without custom user
   - Check: `docker exec postgres psql -U postgres -c "\du"`

3. **pg_hba.conf restrictions:**
   - PostgreSQL access control file
   - Default: Allow all from Docker network
   - Custom config: May block certain IPs/users

**Diagnostic:**

```
1. Verify env vars: docker inspect postgres | grep POSTGRES
2. List users: \du (check user exists)
3. Check pg_hba.conf: docker exec postgres cat /var/lib/postgresql/data/pg_hba.conf
```

**Solution:**

- Correct environment variables
- Create user if missing
- Adjust pg_hba.conf (allow host IP range)

---

### 6.3 Too Many Connections

**Symptom:**

```
FATAL: sorry, too many clients already
```

**Root cause analysis:**

1. **Application connection leak:**
   - App opens connections but doesn't close them
   - Verify: `SELECT count(*) FROM pg_stat_activity WHERE application_name = 'myapp';`

2. **Insufficient max_connections:**
   - Default: 100
   - Calculate needed: (App replicas × Connections per replica) + Admin connections

3. **No connection pooling:**
   - Every request opens new connection (expensive!)
   - Solution: Use connection pool (HikariCP, pg-pool)

**Solutions:**

1. **Fix application leak:** Ensure connections closed after use
2. **Increase max_connections:**
   - Trade-off: More RAM usage (10MB per connection)
   - Better: Fix leak first, then increase if needed
3. **Implement connection pooling:** Reuse connections (faster, less overhead)

📖 **Praktika:** Labor 2, Harjutus 5 - Troubleshooting scenarios

---

## 🎓 7. Containerized vs External PostgreSQL

### 7.1 Containerized PostgreSQL (Taught in This Chapter)

**Architecture:**

```
Kubernetes Pod:
  ├── Backend Container
  └── PostgreSQL Container (StatefulSet)
      └── PersistentVolume
```

**Pros:**
- ✅ Infrastructure as Code (declarative YAML)
- ✅ Auto-scaling, self-healing (Kubernetes)
- ✅ Easy dev/staging environments (spin up quickly)
- ✅ Version management (postgres:14 → postgres:16 upgrade)

**Cons:**
- ❌ Volume management complexity (PV provisioning)
- ❌ Backup orchestration (CronJobs, external storage)
- ❌ Not ideal for multi-TB databases

**Use cases:**
- Microservices architectures
- Cloud-native applications
- Development/staging environments
- Small-to-medium production databases

---

### 7.2 External PostgreSQL (Production Pattern)

**Architecture:**

```
Kubernetes Cluster:
  ├── Backend Pods
  └── ExternalName Service → External PostgreSQL (VPS/AWS RDS)
```

**External PostgreSQL deployment options:**

1. **Dedicated VPS:**
   - PostgreSQL installed on Ubuntu server (traditional)
   - DevOps manages: OS, PostgreSQL config, backups

2. **Managed service (AWS RDS, Azure Database, GCP Cloud SQL):**
   - Cloud provider manages: OS, backups, HA, patches
   - DevOps manages: Connection config, monitoring

**Pros:**
- ✅ Better performance (dedicated hardware, tuned OS)
- ✅ Managed backups (automated, tested restores)
- ✅ High availability (multi-AZ replication)
- ✅ Less operational overhead (for managed services)

**Cons:**
- ❌ Higher cost (managed services expensive)
- ❌ Less portability (vendor lock-in)
- ❌ Separation from application (network latency)

**Use cases:**
- Large production databases (>100GB)
- Regulated industries (need managed backups, compliance)
- Legacy applications (already using external DB)

---

### 7.3 Hybrid Approach (Common in Practice)

**Strategy:**

```
Development: Containerized PostgreSQL (docker-compose)
Staging: Containerized PostgreSQL (Kubernetes StatefulSet)
Production: External PostgreSQL (AWS RDS)
```

**Why hybrid?**

- **Dev/staging:** Speed, cost (spin up/down easily)
- **Production:** Reliability, managed backups, HA

**Connection configuration:**

```
# Development/Staging
DB_HOST=postgres (container name)

# Production
DB_HOST=prod-db.us-east-1.rds.amazonaws.com (external DNS)
```

**Same application code, different config** (12-Factor App principle III)

---

## 🎓 8. Mida Sa Õppisid?

### Põhilised Kontseptsioonid

✅ **Stateful Applications:**
- Stateless vs stateful architecture erinevused
- Volume lifecycle management (create, mount, persist, reuse)
- Data persistence beyond container lifecycle

✅ **PostgreSQL Containerization:**
- Containerization benefits (rapid provisioning, consistency, isolation)
- Trade-offs (performance overhead, operational complexity)
- Volume architecture (decoupled storage)

✅ **Configuration:**
- Environment variables (12-Factor App config)
- Port mapping ja networking (DNS resolution)
- Connection management (max_connections, pooling)

✅ **Backup and Restore:**
- Logical vs physical backups (pg_dump vs pg_basebackup)
- Backup strategies (full, incremental, PITR)
- RTO/RPO requirements

✅ **Observability:**
- Key metrics (connections, query performance, database size, cache hit ratio)
- pg_stat_activity (real-time connection view)
- pg_stat_statements (query performance analysis)

✅ **Troubleshooting:**
- Connection refused (readiness, networking)
- Authentication failed (credentials, pg_hba.conf)
- Too many connections (leaks, max_connections, pooling)

✅ **Deployment Patterns:**
- Containerized PostgreSQL (Kubernetes StatefulSet)
- External PostgreSQL (dedicated VPS, managed service)
- Hybrid approach (dev/staging containerized, prod external)

---

## 🚀 9. Järgmised Sammud

**Peatükk 7: Docker Compose** 🐳

Nüüd kui mõistad, kuidas PostgreSQL containeris töötab, on aeg õppida **multi-container orchestration**:

- Declarative multi-container applications
- Service dependencies (backend depends_on postgres)
- Shared networks and volumes
- Environment variable management
- docker-compose.yml as Infrastructure as Code

**Peatükk 9: Kubernetes Alused** ☸️

Järgmine evolutsioon konteinerite orkestreerimisel:

- Kubernetes vs Docker Compose
- StatefulSets for databases
- PersistentVolumes and PersistentVolumeClaims
- Services and DNS
- Auto-scaling, self-healing

📖 **Praktika:** Labor 2 pakub hands-on harjutusi PostgreSQL containers'i, volumes'i, networking'u ja backup/restore workflow'de kohta.

---

## ✅ Kontrolli Ennast

Enne järgmisele peatükile liikumist, veendu et:

- [ ] Mõistad stateful vs stateless application erinevusi
- [ ] Oskad selgitada volume lifecycle management'i (create, mount, persist, reuse)
- [ ] Mõistad PostgreSQL containerization benefits ja trade-offs
- [ ] Oskad selgitada backup/restore strategies (logical vs physical)
- [ ] Mõistad observability metrics (connections, query performance)
- [ ] Oskad diagnosteerida connection probleeme (refused, auth failed)
- [ ] Mõistad containerized vs external PostgreSQL deployment patterns

**Kui kõik on ✅, oled valmis Peatükiks 7!** 🚀

---

**Peatükk 6 lõpp**
**Järgmine:** Peatükk 7 - Docker Compose
