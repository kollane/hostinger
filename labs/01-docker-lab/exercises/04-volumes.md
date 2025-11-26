# Harjutus 4: Docker Andmehoidlad (Volumes)

**Kestus:** 45 minutit
**Eesmärk:** Säilita andmed andmehoidlatega (volumes) ja õpi andmete püsivust (data persistence)

**Eeldus:** [Harjutus 3: Võrgundus (Networking)](03-networking.md) läbitud ✅
💡 **Märkus:** Kui baaspildid (base images) (`user-service:1.0`, `todo-service:1.0`) puuduvad, käivita `./setup.sh` ja vali `Y`

---

## 📋 Ülevaade

**Mäletad Harjutus 3-st?** Me käivitasime 4 konteinerit (2 PostgreSQL + 2 teenust (services)) kohandatud võrgus (custom network). Aga mis juhtub, kui konteiner kustutatakse? **Kõik andmed kaovad!** 😱

**Probleem:**
```bash
docker stop postgres-todo postgres-user
docker rm postgres-todo postgres-user
# Kõik andmed (users JA todos) on KADUNUD!
```

**Lahendus: Docker Andmehoidlad (Volumes)!**
- Andmehoidlad (volumes) säilitavad andmed väljaspool konteinerit
- Konteiner võib kustuda, aga andmed jäävad alles
- Võid kasutada sama andmehoidlat (volume) uue konteineriga
- **Selles harjutuses:** Lisame andmehoidlad (volumes) MÕLEMALE PostgreSQL konteinerile!

---

## 🎯 Õpieesmärgid

- ✅ Luua nimega andmehoidlad (named volumes) (2 andmehoidlat (volumes): User Teenus (Service) + Todo Teenus (Service))
- ✅ Paigaldada (mount) andmehoidla (volume) konteinerisse
- ✅ Testida andmete püsivust (data persistence) (konteiner kustutatakse, andmed jäävad!)
- ✅ Varundada (backup) ja taastada (restore) mitut andmehoidlat (volumes)
- ✅ Inspekteerida andmehoidlaid (volumes)
- ✅ Mõista, miks andmehoidlad (volumes) on kriitilised tootmises
- ✅ Testida katastroofist taastumise (disaster recovery) stsenaariumi

---

## 📝 Sammud

### Samm 1: Demonstreeri Probleemi (10 min)

**Esmalt näitame, mis juhtub ILMA andmehoidlateta (volumes) - MÕLEMAS andmebaasis:**

```bash
# Kui sul on Harjutus 3 konteinerid töös, kasuta neid
# Muidu käivita kaks PostgreSQL konteinerit (ILMA andmehoidlateta (volumes)):

# PostgreSQL User Teenusele (Service) (ILMA andmehoidlata (volume))
docker run -d \
  --name postgres-user \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  postgres:16-alpine

# PostgreSQL Todo Teenusele (Service) (ILMA andmehoidlata (volume))
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  postgres:16-alpine

sleep 5

# Loo tabelid ja lisa testandmed

# User Teenuse (Service) andmebaas
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

# Todo Teenuse (Service) andmebaas
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
echo "=== User Teenuse (Service) andmed ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "SELECT * FROM users;"

echo -e "\n=== Todo Teenuse (Service) andmed ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;"

# Nüüd KUSTUTA mõlemad konteinerid
docker stop postgres-user postgres-todo
docker rm postgres-user postgres-todo

# Käivita UUS PostgreSQL (ILMA andmehoidlata (volume))
docker run -d --name postgres-user --network todo-network \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db postgres:16-alpine

docker run -d --name postgres-todo --network todo-network \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db postgres:16-alpine

sleep 5

# Proovi andmeid lugeda
echo "=== Proovi User Teenuse (Service) andmeid lugeda ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "SELECT * FROM users;" 2>&1
# ERROR: relation "users" does not exist

echo -e "\n=== Proovi Todo Teenuse (Service) andmeid lugeda ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;" 2>&1
# ERROR: relation "todos" does not exist

# KÕIK ANDMED on KADUNUD! 💥
```

**See on SUUR PROBLEEM tootmises!** Lahendame selle nüüd andmehoidlatega (volumes).

### Samm 2: Loo Nimega Andmehoidlad (Named Volumes) (5 min)

```bash
# Puhasta eelmine test
docker stop postgres-user postgres-todo 2>/dev/null || true
docker rm postgres-user postgres-todo 2>/dev/null || true

# Loo KAKS andmehoidlat (volumes) - üks igale andmebaasile!
docker volume create postgres-user-data
docker volume create postgres-todo-data

# Vaata kõiki andmehoidlaid (volumes)
docker volume ls
# Peaks näitama:
# - postgres-user-data
# - postgres-todo-data

# Inspekteeri mõlemat andmehoidlat (volume)
docker volume inspect postgres-user-data
docker volume inspect postgres-todo-data

# Näitab:
# - Mountpoint: /var/lib/docker/volumes/postgres-user-data/_data
# - Driver: local
# - Created timestamp
```

**Miks kaks andmehoidlat (volumes)?**
- ✅ Igal mikroteenusel (microservice) oma andmebaas (mikroteenuste (microservices) parim praktika (best practice)!)
- ✅ Sõltumatu andmete haldamine
- ✅ Eraldi varundamise (backup) strateegia
- ✅ Paindlik skaleeritavus

### Samm 3: Käivita MÕLEMAD PostgreSQL Konteinerid Andmehoidlatega (Volumes) (10 min)

```bash
# PostgreSQL User Teenusele (Service) andmehoidlaga (volume)
docker run -d \
  --name postgres-user \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -v postgres-user-data:/var/lib/postgresql/data \
  postgres:16-alpine

# PostgreSQL Todo Teenusele (Service) andmehoidlaga (volume)
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
- `postgres-user-data` = andmehoidla (volume) nimi
- `/var/lib/postgresql/data` = PostgreSQL andmete kataloog konteineris
- Docker paigaldab (mounts) andmehoidla (volume) sinna kataloogi

**Mida just juhtus?**
- ✅ Lõime 2 eraldi andmehoidlat (volumes)
- ✅ Käivitasime 2 PostgreSQL konteinerit
- ✅ Iga konteiner kasutab oma andmehoidlat (volume)
- ✅ Andmed salvestatakse nüüd andmehoidlatesse (volumes), MITTE konteineritesse!

### Samm 4: Seadista MÕLEMAD Andmebaasid ja Lisa Testandmeid (15 min)

```bash
# Oota, et PostgreSQL on valmis
sleep 5

# === USER TEENUSE (SERVICE) ANDMEBAAS ===
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

# Lisa testandmed User Teenusesse (Service)
docker exec -i postgres-user psql -U postgres -d user_service_db <<EOF
INSERT INTO users (name, email, password, role) VALUES
('Alice Admin', 'alice@example.com', 'hashed_password_1', 'admin'),
('Bob User', 'bob@example.com', 'hashed_password_2', 'user'),
('Charlie User', 'charlie@example.com', 'hashed_password_3', 'user');
EOF

# Kontrolli User Teenuse (Service) andmeid
echo "=== USER TEENUSE (SERVICE) ANDMED ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "
SELECT id, name, email, role FROM users ORDER BY id;"
# Peaks näitama 3 kasutajat

# === TODO TEENUSE (SERVICE) ANDMEBAAS ===
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

# Lisa testandmed Todo Teenusesse (Service)
docker exec -i postgres-todo psql -U postgres -d todo_service_db <<EOF
INSERT INTO todos (user_id, title, description, priority) VALUES
(1, 'Õpi Docker Andmehoidlaid (Volumes)', 'Tee harjutus 4 lõpuni', 'high'),
(1, 'Testi andmete püsivust (data persistence)', 'Kustuta konteiner ja vaata, kas andmed jäävad alles', 'high'),
(2, 'Lisa varundamise (backup) strateegia', 'Õpi andmehoidla (volume) varundamist (backup) tegema', 'medium'),
(3, 'Deploy to production', 'Kasuta andmehoidlaid (volumes) tootmises', 'high');
EOF

# Kontrolli Todo Teenuse (Service) andmeid
echo -e "\n=== TODO TEENUSE (SERVICE) ANDMED ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, user_id, title, priority, created_at FROM todos ORDER BY id;"
# Peaks näitama 4 todo'd

echo -e "\n✅ Mõlemad andmebaasid on seadistatud ja sisaldavad andmeid!"
```

### Samm 5: Testi Andmete Püsivust (Data Persistence) - KÕIGE OLULISEM TEST! (15 min)

**See on see hetk, kus andmehoidla (volume) väärtus selgub - testime MÕLEMAT teenust (service)!**

```bash
# === PART 1: TODO TEENUSE (SERVICE) PÜSIVUSE (PERSISTENCE) TEST ===
echo "=== TESTIB TODO TEENUSE (SERVICE) ANDMETE PÜSIVUST (DATA PERSISTENCE) ==="

# 1. Stopp konteiner
docker stop postgres-todo
echo "✅ Konteiner peatatud"

# 2. KUSTUTA konteiner täielikult
docker rm postgres-todo
echo "✅ Konteiner KUSTUTATUD!"

# 3. Kontrolli, et konteiner on tõesti kadunud
docker ps -a | grep postgres-todo
echo "✅ Konteiner ei eksisteeri enam!"

# 4. AGA ANDMEHOIDLA (VOLUME) ON ALLES!
docker volume ls | grep postgres-todo-data
echo "✅ Andmehoidla (volume) on endiselt olemas!"

# 5. Käivita TÄIESTI UUS konteiner SAMA andmehoidlaga (volume)
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

# 6. TÕE HETK: Kas TODO andmed on alles?
echo "=== KONTROLLIB TODO ANDMEID ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, title, priority FROM todos ORDER BY id;"

echo -e "\n✅ TODO TEENUSE (SERVICE) ANDMED ON ALLES! 🎉\n"

# === PART 2: USER TEENUSE (SERVICE) PÜSIVUSE (PERSISTENCE) TEST ===
echo "=== TESTIB USER TEENUSE (SERVICE) ANDMETE PÜSIVUST (DATA PERSISTENCE) ==="

# 1. Stopp konteiner
docker stop postgres-user
echo "✅ Konteiner peatatud"

# 2. KUSTUTA konteiner täielikult
docker rm postgres-user
echo "✅ Konteiner KUSTUTATUD!"

# 3. AGA ANDMEHOIDLA (VOLUME) ON ALLES!
docker volume ls | grep postgres-user-data
echo "✅ Andmehoidla (volume) on endiselt olemas!"

# 4. Käivita TÄIESTI UUS konteiner SAMA andmehoidlaga (volume)
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

# 5. TÕE HETK: Kas USER andmed on alles?
echo "=== KONTROLLIB USER ANDMEID ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "
SELECT id, name, email, role FROM users ORDER BY id;"

echo -e "\n✅ USER TEENUSE (SERVICE) ANDMED ON ALLES! 🎉\n"
```

**🎉 TULEMUS: MÕLEMAD ANDMEBAASID ON ALLES!**

**Mida see tähendab?**
- ✅ MÕLEMAD konteinerid KUSTUTATI täielikult
- ✅ Uued konteinerid on TÄIESTI ERALDI instantsid
- ✅ Aga KÕIK andmed on ALLES, sest need on andmehoidlates (volumes)!
- ✅ Andmehoidlad (volumes) elavad konteineritest sõltumatult!
- ✅ See on TÄPSELT see, mis tootmises vaja - konteinerid on efemeersed (ephemeral), andmed on püsivad (persistent)!

### Samm 6: Varunda (Backup) MÕLEMAD Andmehoidlad (Volumes) (10 min)

**Õpi, kuidas MITME andmehoidla (volume) andmeid varundada (backup) paralleelselt:**

```bash
# === VARUNDA (BACKUP) USER TEENUSE (SERVICE) ANDMEHOIDLA (VOLUME) ===
echo "=== Varundab (backup) User Teenuse (Service) andmehoidlat (volume) ==="
docker run --rm \
  -v postgres-user-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-user-backup.tar.gz -C /data .

# === VARUNDA (BACKUP) TODO TEENUSE (SERVICE) ANDMEHOIDLA (VOLUME) ===
echo "=== Varundab (backup) Todo Teenuse (Service) andmehoidlat (volume) ==="
docker run --rm \
  -v postgres-todo-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-todo-backup.tar.gz -C /data .

# Kontrolli MÕLEMAT varukoopia (backup) faili
echo -e "\n=== Varukoopia (backup) failid ==="
ls -lh postgres-*-backup.tar.gz

# Oodatud väljund:
# postgres-user-backup.tar.gz  ~5MB
# postgres-todo-backup.tar.gz  ~3MB

# Vaata varukoopia (backup) sisu (optional)
echo -e "\n=== User Teenuse (Service) varukoopia (backup) sisu ==="
tar -tzf postgres-user-backup.tar.gz | head -10

echo -e "\n=== Todo Teenuse (Service) varukoopia (backup) sisu ==="
tar -tzf postgres-todo-backup.tar.gz | head -10
```

**Mida see teeb?**
- `-v postgres-user-data:/data` - Paigalda (mount) andmehoidla (volume) konteinerisse
- `-v $(pwd):/backup` - Paigalda (mount) praegune kaust konteinerisse
- `alpine tar czf` - Kasuta alpine pilti (image), et teha tar.gz arhiiv
- `--rm` - Kustuta konteiner pärast töö lõppu

**Miks kaks eraldi varukoopiat (backup)?**
- ✅ Igal mikroteenusel (microservice) oma varundamise (backup) strateegia
- ✅ Saad taastada (restore) ainult ühe teenuse (service) (kui vaja)
- ✅ Väiksemad varukoopia (backup) failid (kiirem)

### Samm 7: Taasta (Restore) Andmehoidla (Volume) Varukoopiast (Backup) - Katastroofist Taastumine (Disaster Recovery) (Bonus - 15 min)

**Simuleerime "katastroofist taastumist" (disaster recovery):**

```bash
# === KATASTROOFI STSENAARIUM: Todo Teenuse (Service) andmehoidla (volume) KUSTUB täielikult ===
echo "=== SIMULEERIB KATASTROOFI: Andmehoidla (volume) kustutatakse! ==="

# 1. Stopp ja kustuta konteiner
docker stop postgres-todo
docker rm postgres-todo

# 2. KUSTUTA ANDMEHOIDLA (VOLUME) TÄIELIKULT (simuleerib ketta riket (disk failure))
docker volume rm postgres-todo-data
echo "💥 Andmehoidla (volume) on KADUNUD! (Simuleeritud ketta rike (disk failure))"

# 3. Kontrolli, et andmehoidla (volume) on tõesti kadunud
docker volume ls | grep postgres-todo-data
# Tühi - andmehoidla (volume) on KADUNUD!

echo -e "\n=== ALUSTAB KATASTROOFIST TAASTUMIST (DISASTER RECOVERY) ==="

# 4. Loo UUS tühi andmehoidla (volume)
docker volume create postgres-todo-data
echo "✅ Uus tühi andmehoidla (volume) loodud"

# 5. TAASTA (RESTORE) varukoopia (backup)
echo "=== Taastab (restore) varukoopia (backup) ==="
docker run --rm \
  -v postgres-todo-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/postgres-todo-backup.tar.gz -C /data

echo "✅ Varukoopia (backup) taastatud!"

# 6. Käivita PostgreSQL uue (taastatud (restored)) andmehoidlaga (volume)
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  -v postgres-todo-data:/var/lib/postgresql/data \
  postgres:16-alpine

sleep 5

# 7. TÕE HETK: Kas andmed on TAGASI?
echo "=== Kontrollib, kas andmed on taastatud (restored) ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, title, priority FROM todos ORDER BY id;"

echo -e "\n🎉 KATASTROOFIST TAASTUMINE (DISASTER RECOVERY) ÕNNESTUS! Andmed on TAGASI!"
```

**Mida sa just õppisid?**
- ✅ Andmehoidla (volume) kustutamine on PÖÖRDUMATU
- ✅ Varundamine (backup) on KRIITILINE tootmises
- ✅ Taastamise (restore) protsess töötab (katastroof ei ole lõplik!)
- ✅ Alati tee varukoopia (backup) ENNE riskantset operatsiooni

### Samm 8: Vaata Andmehoidla (Volume) Detaile (5 min)

```bash
# MÕLEMA andmehoidla (volume) täielik info
docker volume inspect postgres-user-data
docker volume inspect postgres-todo-data

# Kõigi andmehoidlate (volumes) suurus
docker system df -v

# Vaata ainult andmehoidlate (volumes) sektsiooni
docker system df -v | grep -A 15 "Local Volumes"
```

**Huvitav fakt:**
```bash
# Andmehoidlad (volumes) asuvad host masinas siin:
sudo ls -la /var/lib/docker/volumes/postgres-user-data/_data/
sudo ls -la /var/lib/docker/volumes/postgres-todo-data/_data/
# Näed PostgreSQL failisüsteemi struktuuri
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [x] **2 nimega andmehoidlat (named volumes)** loodud (`docker volume ls`)
  - postgres-user-data
  - postgres-todo-data
- [x] MÕLEMAD PostgreSQL konteinerid kasutavad andmehoidlaid (volumes) (`-v <volume>:/var/lib/postgresql/data`)
- [x] **MÕLEMAD andmebaasid jäävad alles pärast konteineri kustutamist!** (KÕIGE OLULISEM! ✨)
- [x] **2 varukoopia (backup) faili** loodud (postgres-user-backup.tar.gz, postgres-todo-backup.tar.gz)
- [x] Oskad taastada (restore) varukoopiast (backup) (katastroofist taastumine (disaster recovery))
- [x] Oskad inspekteerida andmehoidlaid (volumes) (`docker volume inspect`)
- [x] Mõistad, miks andmehoidlad (volumes) on KRIITILISED tootmises

---

## 💡 Millal Andmehoidlaid (Volumes) Kasutada?

✅ **Kasuta andmehoidlaid (volumes) kui:**
- Andmebaas (PostgreSQL, MySQL, MongoDB)
- Üleslaaditud failid (kasutajate üleslaadimised (user uploads), pildid (images))
- Logifailid (kui tahad säilitada)
- Konfiguratsioonid (mis ei muutu tihti)

❌ **Ära kasuta andmehoidlaid (volumes) kui:**
- Lähtekood (kasuta siduspaigaldusi (bind mounts) arenduses (development))
- Saladused (secrets) (kasuta Docker saladusi (secrets) või keskkonna muutujaid (environment variables))
- Ajutised andmed (kasuta `/tmp` konteineris)

---

## 🔄 Võrreldes Harjutus 3-ga

**Harjutus 3 (ILMA andmehoidlateta (volumes)):**
- ❌ Andmed kaovad kui konteiner kustutatakse
- ❌ Ei saa teha varukoopiat (backup)
- ❌ Katastroofist taastumine (disaster recovery) võimatu
- ❌ MITTE tootmiseks sobiv!

**Harjutus 4 (andmehoidlatega (volumes)):**
- ✅ Andmed püsivad (konteinerid võivad ebaõnnestuda, andmed jäävad alles!)
- ✅ Varundamise/taastamise (backup/restore) strateegia olemas
- ✅ Katastroofist taastumine (disaster recovery) võimalik
- ✅ TOOTMISEKS VALMIS!

### 🚀 Järgmised Sammud

**Harjutus 5: Optimeerimine (Optimization)** õpetab:
- Kuidas vähendada pildi (image) suurust (mitme-sammulised (multi-stage) buildid)
- Kuidas kiirendada ehitamise (build) protsessi (kihtide vahemälu (layer caching))
- Kuidas lisada turvalisust (mitte-juurkasutajad (non-root users))

**Jätka:** [Harjutus 5: Optimeerimine (Optimization)](05-optimization.md)

---

## 📚 Viited

- [Docker Volumes Overview](https://docs.docker.com/storage/volumes/)
- [Manage data in Docker](https://docs.docker.com/storage/)
- [Backup, restore, or migrate data volumes](https://docs.docker.com/storage/volumes/#back-up-restore-or-migrate-data-volumes)
- [PostgreSQL Docker Image - Data Persistence](https://hub.docker.com/_/postgres)

---

**Õnnitleme! Oled loonud production-ready andmete püsivuse (data persistence) lahenduse! 🎉**

**Järgmine:** [Harjutus 5: Optimeerimine (Optimization)](05-optimization.md) - Optimeeri pildi (image) suurust ja kiirust!
