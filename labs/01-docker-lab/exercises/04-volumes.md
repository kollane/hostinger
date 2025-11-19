# Harjutus 4: Docker Volumes

**Kestus:** 45 minutit
**Eesmärk:** Säilita andmed volumes'iga ja õpi data persistence

**Eeldus:** [Harjutus 3: Networking](03-networking.md) läbitud ✅

---

## 📋 Ülevaade

**Mäletad Harjutus 3-st?** Me käivitasime PostgreSQL ja Todo Service containerid. Aga mis juhtub, kui container kustutatakse? **Kõik andmed kaovad!** 😱

**Probleem:**
```bash
docker stop postgres-todo
docker rm postgres-todo
# Kõik TODO'de andmed on läinud!
```

**Lahendus: Docker Volumes!**
- Volumes säilitavad andmed väljaspool containerit
- Container võib kustuda, aga andmed jäävad alles
- Võid kasutada sama volume'i uue containeriga

---

## 🎯 Õpieesmärgid

- ✅ Luua named volumes
- ✅ Mount volume containerisse
- ✅ Testida data persistence (container kustutatakse, andmed jäävad!)
- ✅ Backup ja restore
- ✅ Inspekteerida volumes
- ✅ Mõista, miks volumes on kriitiline

---

## 📝 Sammud

### Samm 1: Demonstreeri Probleemi (5 min)

**Esmalt näitame, mis juhtub ILMA volume'ita:**

```bash
# Lisa test andmed PostgreSQL'i (kasutades Harjutus 3 containerit)
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "
INSERT INTO todos (user_id, title, description, priority) VALUES
(1, 'Test TODO', 'See kustub varsti!', 'high');"

# Kontrolli, et andmed on olemas
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;"
# Näed 1 rida

# Nüüd kustuta container
docker stop postgres-todo
docker rm postgres-todo

# Käivita uus PostgreSQL container (ILMA volume'ita)
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  postgres:16-alpine

# Proovi andmeid lugeda
sleep 5
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;"
# ERROR: relation "todos" does not exist
# Kõik andmed on KADUNUD! 💥
```

**See on PROBLEEM!** Lahendame selle nüüd volumes'iga.

### Samm 2: Loo Named Volume (5 min)

```bash
# Puhasta eelmine test
docker stop postgres-todo
docker rm postgres-todo

# Loo dedicated volume PostgreSQL andmete jaoks
docker volume create postgres-todo-data

# Vaata kõiki volumes
docker volume ls
# Peaks näitama: postgres-todo-data

# Inspekteeri volume detaile
docker volume inspect postgres-todo-data
# Näitab:
# - Mountpoint: /var/lib/docker/volumes/postgres-todo-data/_data
# - Driver: local
# - Created timestamp
```

### Samm 3: Käivita PostgreSQL Volume'iga (10 min)

```bash
# Käivita PostgreSQL container volume'iga
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  -v postgres-todo-data:/var/lib/postgresql/data \
  postgres:16-alpine

# Kontrolli
docker ps | grep postgres-todo
# STATUS peaks olema "Up"
```

**Oluline:** `-v postgres-todo-data:/var/lib/postgresql/data`
- `postgres-todo-data` = volume nimi
- `/var/lib/postgresql/data` = PostgreSQL andmete kataloog containeris
- Docker mount'ib volume sinna kataloogi

### Samm 4: Seadista Andmebaas ja Lisa Testandmeid (10 min)

```bash
# Oota, et PostgreSQL on valmis
sleep 5

# Loo todos tabel
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "
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
);"

# Lisa testandmed
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "
INSERT INTO todos (user_id, title, description, priority) VALUES
(1, 'Õpi Docker Volumes', 'Tee harjutus 4 lõpuni', 'high'),
(1, 'Testi data persistence', 'Kustuta container ja vaata, kas andmed jäävad alles', 'high'),
(2, 'Lisa backup strateegia', 'Õpi volume backup tegemist', 'medium');"

# Kontrolli andmeid
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, title, priority, created_at FROM todos ORDER BY id;"
# Peaks näitama 3 rida
```

### Samm 5: Testi Data Persistence - KÕIGE OLULISEM TEST! (10 min)

**See on see hetk, kus volume'i väärtus selgub:**

```bash
# 1. Stopp container
docker stop postgres-todo
# Container on peatatud

# 2. KUSTUTA container täielikult
docker rm postgres-todo
# Container on KADUNUD!

# 3. Kontrolli, et container on tõesti kadunud
docker ps -a | grep postgres-todo
# Tühi - container ei eksisteeri enam!

# 4. AGA VOLUME ON ALLES!
docker volume ls | grep postgres-todo-data
# postgres-todo-data on endiselt olemas ✅

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

# 6. MOMENT OF TRUTH: Kas andmed on alles?
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "
SELECT id, title, priority FROM todos ORDER BY id;"
```

**TULEMUS:** Andmed on alles! 🎉🎉🎉

**Mida see tähendab?**
- ✅ Container KUSTUTATI täielikult
- ✅ Uus container on TÄIESTI ERALDI instance
- ✅ Aga andmed on ALLES, sest need on volume'is!
- ✅ Volume elab containerist sõltumatult!

### Samm 6: Backup Volume (Bonus - 5 min)

**Õpi, kuidas volume'i andmeid backupida:**

```bash
# Loo backup todo-service andmebaasist
# Kasutame väikest alpine containerit, et kopeerida volume sisu
docker run --rm \
  -v postgres-todo-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-todo-backup.tar.gz -C /data .

# Kontrolli backup faili
ls -lh postgres-todo-backup.tar.gz
# Peaks olema ~1-10MB (sõltub andmete hulgast)

# Vaata backup sisu (optional)
tar -tzf postgres-todo-backup.tar.gz | head -20
```

**Mida see teeb?**
- `-v postgres-todo-data:/data` - Mount volume containerisse
- `-v $(pwd):/backup` - Mount praegune kaust containerisse
- `alpine tar czf` - Kasuta alpine image'i et teha tar.gz archive
- `--rm` - Kustuta container pärast töö lõppu

### Samm 7: Vaata Volume Detaile (5 min)

```bash
# Volume täielik info
docker volume inspect postgres-todo-data

# Kõigi volumes'i suurus
docker system df -v

# Vaata ainult volume'ide sektsiooni
docker system df -v | grep -A 10 "Local Volumes"
```

**Huvitav fakt:**
```bash
# Volume asub host masinas siin:
sudo ls -la /var/lib/docker/volumes/postgres-todo-data/_data/
# Näed PostgreSQL failisüsteemi struktuuri
```

---

## ✅ Kontrolli

- [x] Volume `postgres-todo-data` on loodud (`docker volume ls`)
- [x] PostgreSQL kasutab volume'i (`-v postgres-todo-data:/var/lib/postgresql/data`)
- [x] **Andmed jäävad alles pärast container kustutamist!** (See on kõige olulisem! ✨)
- [x] Backup on loodud (`postgres-todo-backup.tar.gz`)
- [x] Oskad inspekteerida volume'i (`docker volume inspect`)

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

**Järgmine:** [Harjutus 5: Optimization](05-optimization.md) - Optimeeri image suurust ja kiirust!
