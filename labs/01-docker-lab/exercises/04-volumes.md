# Harjutus 4: Docker andmeköited (Volumes)

**Eesmärk:** Säilita andmed andmeköidetega ja õpi andmete püsivust

**Eeldused:**
- ✅ [Harjutus 3: Docker võrgundus](03-networking.md) läbitud
- 💡 **Märkus:** Kui baastõmmised (`user-service:1.0`, `todo-service:1.0`) puuduvad, käivita `lab1-setup` ja vali `Y`

---

## 📋 Harjutuse ülevaade

**Mäletad Harjutus 3-st?** Me käivitasime 4 konteinerit (2 PostgreSQL + 2 teenust) kohandatud võrgus. Aga mis juhtub, kui konteiner kustutatakse? **Kõik andmed kaovad!** 😱

**Probleem:**
```bash
docker stop postgres-todo postgres-user
docker rm postgres-todo postgres-user
# Kõik andmed (users JA todos) on KADUNUD!
```

**Lahendus: Docker andmeköited (Docker volumes)!**
- Andmeköited säilitavad andmed väljaspool konteinerit
- Konteiner võib kustuda, aga andmed jäävad alles
- Võid kasutada sama andmeköidet uue konteineriga
- **Selles harjutuses:** Lisame andmeköited MÕLEMALE PostgreSQL konteinerile!

---

## 📝 Sammud

**ℹ️ Portide turvalisus:**

Selles harjutuses PostgreSQL **EI kasuta** `-p` (ainult `todo-network` võrgus).
- ✅ **See on PARIM PRAKTIKA:** Andmebaasid peaksid olema isoleeritud sisevõrgus
- ✅ **Antud laboreid tehes turvatud sisevõrk kaitseb**
- 📚 **Kui vaja testida:** `docker exec -it postgres-user psql -U postgres -d user_service_db`
- 🎯 **Lab 7 käsitleb:** Võrguturvalisust põhjalikumalt

**Hetkel keskendume andmete püsivusele!**

---

### Samm 1: Demonstreeri probleemi

**Esmalt näitame, mis juhtub ILMA andmeköideteta - MÕLEMAS andmebaasis:**

```bash
# Kui sul on Harjutus 3 konteinerid töös, kasuta neid
# Muidu käivita kaks PostgreSQL konteinerit (ILMA andmeköideteta):

# PostgreSQL User teenusele (ILMA andmeköiteta)
docker run -d \
  --name postgres-user \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  postgres:16-alpine

# PostgreSQL Todo teenusele (ILMA andmeköiteta)
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  postgres:16-alpine

sleep 5

# Loo tabelid ja lisa testandmed

# User teenuse andmebaas
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

# Todo teenuse andmebaas
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
echo "=== User teenuse andmed ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "SELECT * FROM users;"

echo -e "\n=== Todo teenuse andmed ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;"

# Nüüd KUSTUTA mõlemad konteinerid
docker stop postgres-user postgres-todo
docker rm postgres-user postgres-todo

# Käivita UUS PostgreSQL (ILMA andmeköiteta)
docker run -d --name postgres-user --network todo-network \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db postgres:16-alpine

docker run -d --name postgres-todo --network todo-network \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db postgres:16-alpine

sleep 5

# Proovi andmeid lugeda
echo "=== Proovi User teenuse andmeid lugeda ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "SELECT * FROM users;" 2>&1
# ERROR: relation "users" does not exist

echo -e "\n=== Proovi Todo teenuse andmeid lugeda ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;" 2>&1
# ERROR: relation "todos" does not exist

# KÕIK ANDMED on KADUNUD! 💥
```

**See on SUUR PROBLEEM tootmises!** Lahendame selle nüüd andmeköidetega.

### Samm 2: Loo nimega andmeköited

```bash
# Puhasta eelmine test
docker stop postgres-user postgres-todo 2>/dev/null || true
docker rm postgres-user postgres-todo 2>/dev/null || true

# Loo KAKS andmeköidet - üks igale andmebaasile!
docker volume create postgres-user-data
docker volume create postgres-todo-data

# Vaata kõiki andmeköiteid
docker volume ls
# Peaks näitama:
# - postgres-user-data
# - postgres-todo-data

# Inspekteeri mõlemat andmeköidet
docker volume inspect postgres-user-data
docker volume inspect postgres-todo-data

# Näitab:
# - Mountpoint: /var/lib/docker/volumes/postgres-user-data/_data
# - Driver: local
# - Created timestamp
```

**Miks kaks andmeköidet?**
- ✅ Igal mikroteenusel oma andmebaas (mikroteenuste parim praktika!)
- ✅ Sõltumatu andmete haldamine
- ✅ Eraldi varundamise strateegia
- ✅ Paindlik skaleeritavus

### Samm 3: Käivita MÕLEMAD PostgreSQL konteinerid andmeköidetega

```bash
# PostgreSQL User teenusele andmeköitega
docker run -d \
  --name postgres-user \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -v postgres-user-data:/var/lib/postgresql/data \
  postgres:16-alpine

# PostgreSQL Todo teenusele andmeköitega
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
- `postgres-user-data` = andmeköite nimi
- `/var/lib/postgresql/data` = PostgreSQL andmete kataloog konteineris
- Docker paigaldab (mounts) andmeköite sinna kataloogi

**Mida just juhtus?**
- ✅ Lõime 2 eraldi andmeköidet
- ✅ Käivitasime 2 PostgreSQL konteinerit
- ✅ Iga konteiner kasutab oma andmeköidet
- ✅ Andmed salvestatakse nüüd andmeköidetesse, MITTE konteineritesse!

### Samm 4: Seadista andmebaasid ja lisa testandmeid

```bash
# Oota, et PostgreSQL on valmis
sleep 5

# === USER TEENUSE ANDMEBAAS ===
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

# Lisa testandmed User teenusesse
docker exec -i postgres-user psql -U postgres -d user_service_db <<EOF
INSERT INTO users (name, email, password, role) VALUES
('Alice Admin', 'alice@example.com', 'hashed_password_1', 'admin'),
('Bob User', 'bob@example.com', 'hashed_password_2', 'user'),
('Charlie User', 'charlie@example.com', 'hashed_password_3', 'user');
EOF

# Kontrolli User teenuse andmeid
echo "=== USER TEENUSE ANDMED ==="
docker exec postgres-user psql -U postgres -d user_service_db -c "
SELECT id, name, email, role FROM users ORDER BY id;"
# Peaks näitama 3 kasutajat

# === TODO TEENUSE ANDMEBAAS ===
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

# Lisa testandmed Todo teenusesse
docker exec -i postgres-todo psql -U postgres -d todo_service_db <<EOF
INSERT INTO todos (user_id, title, description, priority) VALUES
(1, 'Õpi Docker Andmehoidlaid (Volumes)', 'Tee harjutus 4 lõpuni', 'high'),
(1, 'Testi andmete püsivust (data persistence)', 'Kustuta konteiner ja vaata, kas andmed jäävad alles', 'high'),
(2, 'Lisa varundamise (backup) strateegia', 'Õpi andmehoidla (volume) varundamist (backup) tegema', 'medium'),
(3, 'Deploy to production', 'Kasuta andmehoidlaid (volumes) tootmises', 'high');
EOF

# Kontrolli Todo teenuse andmeid
echo -e "\n=== TODO TEENUSE ANDMED ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, user_id, title, priority, created_at FROM todos ORDER BY id;"
# Peaks näitama 4 todo'd

echo -e "\n✅ Mõlemad andmebaasid on seadistatud ja sisaldavad andmeid!"
```

### Samm 5: Testi andmete püsivust - KÕIGE OLULISEM TEST!

**See on see hetk, kus andmeköite väärtus selgub - testime MÕLEMAT teenust!**

```bash
# === PART 1: TODO TEENUSE PÜSIVUSE TEST ===
echo "=== TESTIB TODO TEENUSE ANDMETE PÜSIVUST ==="

# 1. Stopp konteiner
docker stop postgres-todo
echo "✅ Konteiner peatatud"

# 2. KUSTUTA konteiner täielikult
docker rm postgres-todo
echo "✅ Konteiner KUSTUTATUD!"

# 3. Kontrolli, et konteiner on tõesti kadunud
docker ps -a | grep postgres-todo
echo "✅ Konteiner ei eksisteeri enam!"

# 4. AGA ANDMEKÖIDE ON ALLES!
docker volume ls | grep postgres-todo-data
echo "✅ Andmeköide on endiselt olemas!"

# 5. Käivita TÄIESTI UUS konteiner SAMA andmeköitega
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

echo -e "\n✅ TODO TEENUSE ANDMED ON ALLES! 🎉\n"

# === PART 2: USER TEENUSE PÜSIVUSE TEST ===
echo "=== TESTIB USER TEENUSE ANDMETE PÜSIVUST ==="

# 1. Stopp konteiner
docker stop postgres-user
echo "✅ Konteiner peatatud"

# 2. KUSTUTA konteiner täielikult
docker rm postgres-user
echo "✅ Konteiner KUSTUTATUD!"

# 3. AGA ANDMEKÖIDE ON ALLES!
docker volume ls | grep postgres-user-data
echo "✅ Andmeköide on endiselt olemas!"

# 4. Käivita TÄIESTI UUS konteiner SAMA andmeköitega
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

echo -e "\n✅ USER TEENUSE ANDMED ON ALLES! 🎉\n"
```

**🎉 TULEMUS: MÕLEMAD ANDMEBAASID ON ALLES!**

**Mida see tähendab?**
- ✅ MÕLEMAD konteinerid KUSTUTATI täielikult
- ✅ Uued konteinerid on TÄIESTI ERALDI instantsid
- ✅ Aga KÕIK andmed on ALLES, sest need on andmeköidetes!
- ✅ Andmeköited elavad konteineritest sõltumatult!
- ✅ See on TÄPSELT see, mis tootmises vaja - konteinerid on efemeersed (ephemeral), andmed on püsivad (persistent)!

### Samm 6: Varunda MÕLEMAD andmeköited

**Õpi, kuidas MITME andmeköite andmeid varundada paralleelselt:**

```bash
# === VARUNDA USER TEENUSE ANDMEKÖIDE ===
echo "=== Varundab User teenuse andmeköidet ==="
docker run --rm \
  -v postgres-user-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-user-backup.tar.gz -C /data .

# === VARUNDA TODO TEENUSE ANDMEKÖIDE ===
echo "=== Varundab Todo teenuse andmeköidet ==="
docker run --rm \
  -v postgres-todo-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-todo-backup.tar.gz -C /data .

# Kontrolli MÕLEMAT varukoopia faili
echo -e "\n=== Varukoopia failid ==="
ls -lh postgres-*-backup.tar.gz

# Oodatud väljund:
# postgres-user-backup.tar.gz  ~5MB
# postgres-todo-backup.tar.gz  ~3MB

# Vaata varukoopia sisu (optional)
echo -e "\n=== User teenuse varukoopia sisu ==="
tar -tzf postgres-user-backup.tar.gz | head -10

echo -e "\n=== Todo teenuse varukoopia sisu ==="
tar -tzf postgres-todo-backup.tar.gz | head -10
```

**Mida see teeb?**
- `-v postgres-user-data:/data` - Paigalda andmeköide konteinerisse
- `-v $(pwd):/backup` - Paigalda praegune kaust konteinerisse
- `alpine tar czf` - Kasuta alpine tõmmist, et teha tar.gz arhiiv
- `--rm` - Kustuta konteiner pärast töö lõppu

**Miks kaks eraldi varukoopiat?**
- ✅ Igal mikroteenusel oma varundamise strateegia
- ✅ Saad taastada ainult ühe teenuse (kui vaja)
- ✅ Väiksemad varukoopia failid (kiirem)

### Samm 7: Taasta andmeköide varukoopiast - Tõrkest taastumine (Disaster Recovery)

**Simuleerime "tõrkest taastumist" (disaster recovery):**

```bash
# === KATASTROOFI STSENAARIUM: Todo teenuse andmeköide KUSTUB täielikult ===
echo "=== SIMULEERIB KATASTROOFI: Andmeköide kustutatakse! ==="

# 1. Stopp ja kustuta konteiner
docker stop postgres-todo
docker rm postgres-todo

# 2. KUSTUTA ANDMEKÖIDE TÄIELIKULT (simuleerib ketta riket)
docker volume rm postgres-todo-data
echo "💥 Andmeköide on KADUNUD! (Simuleeritud ketta rike)"

# 3. Kontrolli, et andmeköide on tõesti kadunud
docker volume ls | grep postgres-todo-data
# Tühi - andmeköide on KADUNUD!

echo -e "\n=== ALUSTAB TÕRKEST TAASTUMIST (DISASTER RECOVERY) ==="

# 4. Loo UUS tühi andmeköide
docker volume create postgres-todo-data
echo "✅ Uus tühi andmeköide loodud"

# 5. TAASTA varukoopia
echo "=== Taastab varukoopia ==="
docker run --rm \
  -v postgres-todo-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/postgres-todo-backup.tar.gz -C /data

echo "✅ Varukoopia taastatud!"

# 6. Käivita PostgreSQL uue (taastatud) andmeköitega
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
echo "=== Kontrollib, kas andmed on taastatud ==="
docker exec postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, title, priority FROM todos ORDER BY id;"

echo -e "\n🎉 TÕRKEST TAASTUMINE (DISASTER RECOVERY) ÕNNESTUS! Andmed on TAGASI!"
```

**Mida sa just õppisid?**
- ✅ Andmeköite kustutamine on PÖÖRDUMATU
- ✅ Varundamine on KRIITILINE tootmises
- ✅ Taastamise protsess töötab (katastroof ei ole lõplik!)
- ✅ Alati tee varukoopia ENNE riskantset operatsiooni

### Samm 8: Vaata andmeköite detaile

```bash
# MÕLEMA andmeköite täielik info
docker volume inspect postgres-user-data
docker volume inspect postgres-todo-data

# Kõigi andmeköidete suurus
docker system df -v

# Vaata ainult andmeköidete sektsiooni
docker system df -v | grep -A 15 "Local Volumes"
```

**Huvitav fakt:**
```bash
# Andmeköited asuvad host masinas siin:
sudo ls -la /var/lib/docker/volumes/postgres-user-data/_data/
sudo ls -la /var/lib/docker/volumes/postgres-todo-data/_data/
# Näed PostgreSQL failisüsteemi struktuuri
```

---

## 💡 Millal andmeköiteid kasutada?

✅ **Kasuta andmeköiteid kui:**
- Andmebaas (PostgreSQL, MySQL, MongoDB)
- Üleslaaditud failid (kasutajate üleslaadimised, pildid)
- Logifailid (kui tahad säilitada)
- Konfiguratsioonid (mis ei muutu tihti)

❌ **Ära kasuta andmeköiteid kui:**
- Lähtekood (kasuta siduspaigaldusi (bind mounts) arenduses)
- Saladused (kasuta Docker saladusi või keskkonnamuutujaid)
- Ajutised andmed (kasuta `/tmp` konteineris)

---

## 🔄 Võrreldes Harjutus 3-ga

**Harjutus 3 (ILMA andmeköideteta):**
- ❌ Andmed kaovad kui konteiner kustutatakse
- ❌ Ei saa teha varukoopiat
- ❌ Tõrkest taastumine võimatu
- ❌ MITTE tootmiseks sobiv!

**Harjutus 4 (andmeköidetega):**
- ✅ Andmed püsivad (konteinerid võivad ebaõnnestuda, andmed jäävad alles!)
- ✅ Varundamise/taastamise strateegia olemas
- ✅ Tõrkest taastumine võimalik
- ✅ TOOTMISEKS VALMIS!

### 🚀 Järgmised Sammud

**Harjutus 5: Tõmmise optimeerimine (Optimization)** õpetab:
- Kuidas vähendada tõmmise suurust (mitmeastmelised buildid)
- Kuidas kiirendada ehitamise protsessi (kihtide vahemälu)
- Kuidas lisada turvalisust (mitte-juurkasutajad)

**Jätka:** [Harjutus 5: Tõmmise optimeerimine (Optimization)](05-optimization.md)

---

## 📚 Viited

- [Docker Volumes Overview](https://docs.docker.com/storage/volumes/)
- [Manage data in Docker](https://docs.docker.com/storage/)
- [Backup, restore, or migrate data volumes](https://docs.docker.com/storage/volumes/#back-up-restore-or-migrate-data-volumes)
- [PostgreSQL Docker Image - Data Persistence](https://hub.docker.com/_/postgres)

---

**Õnnitleme! Oled loonud production-ready andmete püsivuse lahenduse! 🎉**

**Järgmine:** [Harjutus 5: Tõmmise optimeerimine (Optimization)](05-optimization.md) - Optimeeri tõmmise suurust ja kiirust!
