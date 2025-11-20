# Harjutus 4: Docker Volumes

**Kestus:** 45 minutit
**Eesmärk:** Säilita andmed volumes'iga ja õpi data persistence

**Eeldus:** [Harjutus 3: Networking](03-networking.md) läbitud ✅
💡 **Märkus:** Kui base pildid (images) (`user-service:1.0`, `todo-service:1.0`) puuduvad, käivita `./setup.sh` ja vali `Y`

---

## 📋 Ülevaade

**Mäletad Harjutus 3-st?** Me käivitasime 4 containerit (2 PostgreSQL + 2 teenust) custom network'is. Aga mis juhtub, kui container kustutatakse? **Kõik andmed kaovad!** 😱

**Probleem:**
```bash
docker stop postgres-todo postgres-user
docker rm postgres-todo postgres-user
# Kõik andmed (users JA todos) on KADUNUD!
```

**Lahendus: Docker Volumes!**
- Volumes säilitavad andmed väljaspool containerit
- Container võib kustuda, aga andmed jäävad alles
- Võid kasutada sama volume'i uue containeriga
- **Selles harjutuses:** Lisame volumes MÕLEMALE PostgreSQL containerile!

---

## 🎯 Õpieesmärgid

- ✅ Luua named volumes (2 volumes: User Service + Todo Service)
- ✅ Mount volume containerisse
- ✅ Testida data persistence (container kustutatakse, andmed jäävad!)
- ✅ Backup ja restore mitmikut volumes
- ✅ Inspekteerida volumes
- ✅ Mõista, miks volumes on kriitiline tootmises
- ✅ Testida disaster recovery stsenaariumi

---

## 📝 Sammud

### Samm 1: Demonstreeri Probleemi (10 min)

**Esmalt näitame, mis juhtub ILMA volume'ita - MÕLEMAS andmebaasis:**

```bash
# Kui sul on Harjutus 3 containerid töös, kasuta neid
# Muidu käivita kaks PostgreSQL containerit (ILMA volumes'ita):

# PostgreSQL User Service'ile (ILMA volume'ita)
docker run -d \
  --name postgres-user \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  postgres:16-alpine

# PostgreSQL Todo Service'ile (ILMA volume'ita)
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  postgres:16-alpine

sleep 5

# Loo tabelid ja lisa testandmed

# User Service andmebaas
docker exec -i postgres-user psql -U postgres -d user_service_db <<EOF
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user'
);
INSERT INTO users (name, email, password, role) VALUES
('Test User', 'test@example.com', 'hashed_password', 'user');
EOF

# Todo Service andmebaas
docker exec -i postgres-todo psql -U postgres -d todo_service_db <<EOF
CREATE TABLE todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    priority VARCHAR(20) DEFAULT 'medium'
);
INSERT INTO todos (user_id, title, description, priority) VALUES
(1, 'Test TODO', 'See kustub varsti!', 'high');
EOF

# Kontrolli, et andmed on olemas
echo "=== User Service andmed ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "SELECT * FROM users;"

echo -e "\n=== Todo Service andmed ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;"

# Nüüd KUSTUTA mõlemad containerid
docker stop postgres-user postgres-todo
docker rm postgres-user postgres-todo

# Käivita UUS PostgreSQL (ILMA volume'ita)
docker run -d --name postgres-user --network todo-network \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db postgres:16-alpine

docker run -d --name postgres-todo --network todo-network \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db postgres:16-alpine

sleep 5

# Proovi andmeid lugeda
echo "=== Proovi User Service andmeid lugeda ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "SELECT * FROM users;" 2>&1
# ERROR: relation "users" does not exist

echo -e "\n=== Proovi Todo Service andmeid lugeda ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;" 2>&1
# ERROR: relation "todos" does not exist

# KÕIK ANDMED on KADUNUD! 💥
```

**See on SUUR PROBLEEM tootmises!** Lahendame selle nüüd volumes'iga.

### Samm 2: Loo Named Volumes (5 min)

```bash
# Puhasta eelmine test
docker stop postgres-user postgres-todo 2>/dev/null || true
docker rm postgres-user postgres-todo 2>/dev/null || true

# Loo KAKS volumes - üks igale andmebaasile!
docker volume create postgres-user-data
docker volume create postgres-todo-data

# Vaata kõiki volumes
docker volume ls
# Peaks näitama:
# - postgres-user-data
# - postgres-todo-data

# Inspekteeri mõlemat volume'i
docker volume inspect postgres-user-data
docker volume inspect postgres-todo-data

# Näitab:
# - Mountpoint: /var/lib/docker/volumes/postgres-user-data/_data
# - Driver: local
# - Created timestamp
```

**Miks kaks volumes?**
- ✅ Iga mikroteenusel oma andmebaas (mikroteenuste best practice!)
- ✅ Sõltumatu andmete haldamine
- ✅ Eraldi backup strateegia
- ✅ Paindlik skaleeritavus

### Samm 3: Käivita MÕLEMAD PostgreSQL Containerid Volume'itega (10 min)

```bash
# PostgreSQL User Service'ile volume'iga
docker run -d \
  --name postgres-user \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -v postgres-user-data:/var/lib/postgresql/data \
  postgres:16-alpine

# PostgreSQL Todo Service'ile volume'iga
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  -v postgres-todo-data:/var/lib/postgresql/data \
  postgres:16-alpine

# Kontrolli mõlemat
docker ps | grep postgres
# STATUS peaks olema "Up" mõlemal
```

**Oluline:** `-v postgres-user-data:/var/lib/postgresql/data`
- `postgres-user-data` = volume nimi
- `/var/lib/postgresql/data` = PostgreSQL andmete kataloog containeris
- Docker mount'ib volume sinna kataloogi

**Mida just juhtus?**
- ✅ Lõime 2 eraldi volumes
- ✅ Käivitasime 2 PostgreSQL containerit
- ✅ Iga container kasutab oma volume'i
- ✅ Andmed salvestatakse nüüd volume'itesse, MITTE containeritesse!

### Samm 4: Seadista MÕLEMAD Andmebaasid ja Lisa Testandmeid (15 min)

```bash
# Oota, et PostgreSQL on valmis
sleep 5

# === USER SERVICE ANDMEBAAS ===
# Loo users tabel
docker exec -i postgres-user psql -U postgres -d user_service_db <<EOF
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Lisa testandmed User Service'i
docker exec -i postgres-user psql -U postgres -d user_service_db <<EOF
INSERT INTO users (name, email, password, role) VALUES
('Alice Admin', 'alice@example.com', 'hashed_password_1', 'admin'),
('Bob User', 'bob@example.com', 'hashed_password_2', 'user'),
('Charlie User', 'charlie@example.com', 'hashed_password_3', 'user');
EOF

# Kontrolli User Service andmeid
echo "=== USER SERVICE ANDMED ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "
SELECT id, name, email, role FROM users ORDER BY id;"
# Peaks näitama 3 kasutajat

# === TODO SERVICE ANDMEBAAS ===
# Loo todos tabel
docker exec -i postgres-todo psql -U postgres -d todo_service_db <<EOF
CREATE TABLE todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    priority VARCHAR(20) DEFAULT 'medium',
    due_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Lisa testandmed Todo Service'i
docker exec -i postgres-todo psql -U postgres -d todo_service_db <<EOF
INSERT INTO todos (user_id, title, description, priority) VALUES
(1, 'Õpi Docker Volumes', 'Tee harjutus 4 lõpuni', 'high'),
(1, 'Testi data persistence', 'Kustuta container ja vaata, kas andmed jäävad alles', 'high'),
(2, 'Lisa backup strateegia', 'Õpi volume backup tegemist', 'medium'),
(3, 'Deploy to production', 'Kasuta volumes tootmises', 'high');
EOF

# Kontrolli Todo Service andmeid
echo -e "\n=== TODO SERVICE ANDMED ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, user_id, title, priority, created_at FROM todos ORDER BY id;"
# Peaks näitama 4 todo'd

echo -e "\n✅ Mõlemad andmebaasid on seadistatud ja sisaldavad andmeid!"
```

### Samm 5: Testi Data Persistence - KÕIGE OLULISEM TEST! (15 min)

**See on see hetk, kus volume'i väärtus selgub - testime MÕLEMAT teenust!**

```bash
# === PART 1: TODO SERVICE PERSISTENCE TEST ===
echo "=== TESTIB TODO SERVICE DATA PERSISTENCE ==="

# 1. Stopp container
docker stop postgres-todo
echo "✅ Container peatatud"

# 2. KUSTUTA container täielikult
docker rm postgres-todo
echo "✅ Container KUSTUTATUD!"

# 3. Kontrolli, et container on tõesti kadunud
docker ps -a | grep postgres-todo
echo "✅ Container ei eksisteeri enam!"

# 4. AGA VOLUME ON ALLES!
docker volume ls | grep postgres-todo-data
echo "✅ Volume on endiselt olemas!"

# 5. Käivita TÄIESTI UUS container SAMA volume'iga
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  -v postgres-todo-data:/var/lib/postgresql/data \
  postgres:16-alpine

# Oota, et PostgreSQL käivitub
sleep 5

# 6. MOMENT OF TRUTH: Kas TODO andmed on alles?
echo "=== KONTROLLIB TODO ANDMEID ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, title, priority FROM todos ORDER BY id;"

echo -e "\n✅ TODO SERVICE ANDMED ON ALLES! 🎉\n"

# === PART 2: USER SERVICE PERSISTENCE TEST ===
echo "=== TESTIB USER SERVICE DATA PERSISTENCE ==="

# 1. Stopp container
docker stop postgres-user
echo "✅ Container peatatud"

# 2. KUSTUTA container täielikult
docker rm postgres-user
echo "✅ Container KUSTUTATUD!"

# 3. AGA VOLUME ON ALLES!
docker volume ls | grep postgres-user-data
echo "✅ Volume on endiselt olemas!"

# 4. Käivita TÄIESTI UUS container SAMA volume'iga
docker run -d \
  --name postgres-user \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -v postgres-user-data:/var/lib/postgresql/data \
  postgres:16-alpine

# Oota, et PostgreSQL käivitub
sleep 5

# 5. MOMENT OF TRUTH: Kas USER andmed on alles?
echo "=== KONTROLLIB USER ANDMEID ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "
SELECT id, name, email, role FROM users ORDER BY id;"

echo -e "\n✅ USER SERVICE ANDMED ON ALLES! 🎉\n"
```

**🎉 TULEMUS: MÕLEMAD ANDMEBAASID ON ALLES!**

**Mida see tähendab?**
- ✅ MÕLEMAD containerid KUSTUTATI täielikult
- ✅ Uued containerid on TÄIESTI ERALDI instance'd
- ✅ Aga KÕIK andmed on ALLES, sest need on volumes'ites!
- ✅ Volumes elavad containeritest sõltumatult!
- ✅ See on TÄPSELT see, mis tootmises vaja - containers are ephemeral, data is persistent!

### Samm 6: Backup MÕLEMAD Volumes (10 min)

**Õpi, kuidas MITMIKUTE volumes'i andmeid backupida paralleelselt:**

```bash
# === BACKUP USER SERVICE VOLUME ===
echo "=== Backup User Service volume ==="
docker run --rm \
  -v postgres-user-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-user-backup.tar.gz -C /data .

# === BACKUP TODO SERVICE VOLUME ===
echo "=== Backup Todo Service volume ==="
docker run --rm \
  -v postgres-todo-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-todo-backup.tar.gz -C /data .

# Kontrolli MÕLEMAT backup faili
echo -e "\n=== Backup failid ==="
ls -lh postgres-*-backup.tar.gz

# Oodatud väljund:
# postgres-user-backup.tar.gz  ~5MB
# postgres-todo-backup.tar.gz  ~3MB

# Vaata backup sisu (optional)
echo -e "\n=== User Service backup sisu ==="
tar -tzf postgres-user-backup.tar.gz | head -10

echo -e "\n=== Todo Service backup sisu ==="
tar -tzf postgres-todo-backup.tar.gz | head -10
```

**Mida see teeb?**
- `-v postgres-user-data:/data` - Mount volume containerisse
- `-v $(pwd):/backup` - Mount praegune kaust containerisse
- `alpine tar czf` - Kasuta alpine image'i et teha tar.gz archive
- `--rm` - Kustuta container pärast töö lõppu

**Miks kaks eraldi backup'i?**
- ✅ Iga mikroteenusel oma backup strateegia
- ✅ Saad restore'ida ainult ühe teenuse (kui vaja)
- ✅ Väiksemad backup failid (kiirem)

### Samm 7: Restore Volume Backup'ist - Disaster Recovery (Bonus - 15 min)

**Simuleerime "katastroofist taastumist" (disaster recovery):**

```bash
# === DISASTER SCENARIO: Todo Service volume KUSTUB täielikult ===
echo "=== SIMULEERIB DISASTER: Volume kustutatakse! ==="

# 1. Stopp ja kustuta container
docker stop postgres-todo
docker rm postgres-todo

# 2. KUSTUTA VOLUME TÄIELIKULT (simuleerib disk failure)
docker volume rm postgres-todo-data
echo "💥 Volume on KADUNUD! (Simuleeritud disk failure)"

# 3. Kontrolli, et volume on tõesti kadunud
docker volume ls | grep postgres-todo-data
# Tühi - volume on KADUNUD!

echo -e "\n=== ALUSTAB DISASTER RECOVERY ==="

# 4. Loo UUS tühi volume
docker volume create postgres-todo-data
echo "✅ Uus tühi volume loodud"

# 5. RESTORE backup
echo "=== Restore backup ==="
docker run --rm \
  -v postgres-todo-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/postgres-todo-backup.tar.gz -C /data

echo "✅ Backup restored!"

# 6. Käivita PostgreSQL uue (restored) volume'iga
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  -v postgres-todo-data:/var/lib/postgresql/data \
  postgres:16-alpine

sleep 5

# 7. MOMENT OF TRUTH: Kas andmed on TAGASI?
echo "=== Kontrollib, kas andmed on restored ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, title, priority FROM todos ORDER BY id;"

echo -e "\n🎉 DISASTER RECOVERY ÕNNESTUS! Andmed on TAGASI!"
```

**Mida sa just õppisid?**
- ✅ Volume kustutamine on PÖÖRDUMATU
- ✅ Backup on KRITILINE tootmises
- ✅ Restore protsess töötab (katastroof ei ole lõplik!)
- ✅ Alati tee backup ENNE riskantset operatsiooni

### Samm 8: Vaata Volume Detaile (5 min)

```bash
# MÕLEMA volume täielik info
docker volume inspect postgres-user-data
docker volume inspect postgres-todo-data

# Kõigi volumes'i suurus
docker system df -v

# Vaata ainult volume'ide sektsiooni
docker system df -v | grep -A 15 "Local Volumes"
```

**Huvitav fakt:**
```bash
# Volumes asuvad host masinas siin:
sudo ls -la /var/lib/docker/volumes/postgres-user-data/_data/
sudo ls -la /var/lib/docker/volumes/postgres-todo-data/_data/
# Näed PostgreSQL failisüsteemi struktuuri
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [x] **2 named volumes** loodud (`docker volume ls`)
  - postgres-user-data
  - postgres-todo-data
- [x] MÕLEMAD PostgreSQL containerid kasutavad volumes (`-v <volume>:/var/lib/postgresql/data`)
- [x] **MÕLEMAD andmebaasid jäävad alles pärast container kustutamist!** (KÕIGE OLULISEM! ✨)
- [x] **2 backup faili** loodud (postgres-user-backup.tar.gz, postgres-todo-backup.tar.gz)
- [x] Oskad restore'ida backup'ist (disaster recovery)
- [x] Oskad inspekteerida volumes (`docker volume inspect`)
- [x] Mõistad, miks volumes on KRIITILISED tootmises

---

## 🎓 Õpitud Mõisted

### Named Volumes:
- `docker volume create <nimi>` - Loo volume
- `docker volume ls` - Näita kõiki volumes
- `docker volume inspect <nimi>` - Vaata detaile
- `docker volume rm <nimi>` - Kustuta volume (ettevaatust!)
- `-v <volume>:<path>` - Mount volume containerisse

### Data Persistence:
- **Container on ephemeral (ajutine)** - võib kustuda
- **Volume on persistent (püsiv)** - jääb alles
- Container + Volume = Töötav rakendus koos püsivate andmetega

### Volume Mounting:
- Named volume: `-v postgres-todo-data:/var/lib/postgresql/data`
- Bind mount: `-v /host/path:/container/path` (host kausta mount)
- Anonymous volume: `-v /container/path` (Docker loob automaatselt)

### Backup Strateegia:
- Kasuta temporary containerit backup'imiseks
- `--rm` flag kustutab backup container automaatselt
- tar.gz on hea formaat PostgreSQL andmete backupiks

---

## 💡 Millal Volumes Kasutada?

✅ **Kasuta volumes kui:**
- Andmebaas (PostgreSQL, MySQL, MongoDB)
- Uploaded failid (user uploads, images)
- Log failid (kui tahad säilitada)
- Konfiguratsioonid (mis ei muutu tihti)

❌ **Ära kasuta volumes kui:**
- Source code (kasuta bind mounts development'il)
- Secrets (kasuta Docker secrets või environment variables)
- Temporary data (kasuta `/tmp` containeris)

---

## 🎉 Õnnitleme! Mida Sa Õppisid?

### ✅ Tehnilised Oskused

**Docker Volumes:**
- ✅ Lõid named volumes (`docker volume create`)
- ✅ Käivitasid containerid volumes'itega (`-v volume:/path`)
- ✅ Testisid data persistence (container kustutatakse, andmed jäävad!)
- ✅ Inspekteerisid volumes (`docker volume inspect`)
- ✅ Backup ja restore strateegia

**Mikroteenuste Data Management:**
- ✅ Iga mikroteenusel oma volume (postgres-user-data, postgres-todo-data)
- ✅ Sõltumatu andmete haldamine
- ✅ Eraldi backup strateegia igale teenusele
- ✅ Disaster recovery (restore backup'ist)

**Production Best Practices:**
- ✅ Containers are ephemeral (võivad kustuda)
- ✅ Data is persistent (volumes säilitavad)
- ✅ Backup on KRITILINE
- ✅ Teste disaster recovery regulaarselt

### 🔄 Võrreldes Harjutus 3-ga

**Harjutus 3 (ILMA volumes'ita):**
- ❌ Andmed kaovad kui container kustutatakse
- ❌ Ei saa teha backup'i
- ❌ Disaster recovery võimatu
- ❌ MITTE tootmiseks sobiv!

**Harjutus 4 (volumes'itega):**
- ✅ Andmed püsivad (containers can fail, data survives!)
- ✅ Backup/restore strateegia olemas
- ✅ Disaster recovery võimalik
- ✅ TOOTMISEKS VALMIS!

### 🚀 Järgmised Sammud

**Harjutus 5: Optimization** õpetab:
- Kuidas vähendada image suurust (multi-stage builds)
- Kuidas kiirendada build protsessi (layer caching)
- Kuidas lisada security (non-root users)

**Jätka:** [Harjutus 5: Optimization](05-optimization.md)

---

## 📚 Viited

- [Docker Volumes Overview](https://docs.docker.com/storage/volumes/)
- [Manage data in Docker](https://docs.docker.com/storage/)
- [Backup, restore, or migrate data volumes](https://docs.docker.com/storage/volumes/#back-up-restore-or-migrate-data-volumes)
- [PostgreSQL Docker Image - Data Persistence](https://hub.docker.com/_/postgres)

---

**Õnnitleme! Oled loonud production-ready data persistence lahenduse! 🎉**

**Järgmine:** [Harjutus 5: Optimization](05-optimization.md) - Optimeeri image suurust ja kiirust!
