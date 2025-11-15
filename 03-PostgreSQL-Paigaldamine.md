# Peatükk 3: PostgreSQL Paigaldamine - MÕLEMAD VARIANDID ⭐

**Kestus:** 4 tundi
**Eeldused:** Peatükid 1-2 läbitud
**Eesmärk:** Paigaldada PostgreSQL kahes variandis ja mõista nende erinevusi

---

## Sisukord

1. [PostgreSQL Ülevaade](#1-postgresql-ülevaade)
2. [Docker Põhimõtted](#2-docker-põhimõtted)
3. [Docker Paigaldamine VPS-ile](#3-docker-paigaldamine-vps-ile)
4. [PRIMAARNE: PostgreSQL Dockeris](#4-primaarne-postgresql-dockeris)
5. [ALTERNATIIV: PostgreSQL VPS-ile](#5-alternatiiv-postgresql-vps-ile)
6. [Variantide Võrdlus](#6-variantide-võrdlus)
7. [Andmebaasi Algne Seadistamine](#7-andmebaasi-algne-seadistamine)
8. [PostgreSQL Põhikäsud ja SQL](#8-postgresql-põhikäsud-ja-sql)
9. [Harjutused](#9-harjutused)
10. [Kontrolliküsimused](#10-kontrolliküsimused)
11. [Lisamaterjalid](#11-lisamaterjalid)

---

## 1. PostgreSQL Ülevaade

### 1.1. Mis on PostgreSQL?

**PostgreSQL** (tuntud ka kui "Postgres") on võimas, avatud lähtekoodiga **relatsiooniline andmebaasisüsteem** (RDBMS).

#### Analoogia: Andmebaas kui Organiseeritud Ladu

Kujutame ette suurt laohoonet:

**Ilma andmebaasita:**
- Kõik asjad vedelevad põrandal segamini
- Ei tea, kus miski asub
- Otsimine võtab tunde

**Andmebaasiga (PostgreSQL):**
- Kõik asjad on riiulitel (tabelid)
- Iga asi on märgistatud (primary key)
- Kiire otsing (index)
- Reeglid, mis asju võib kuhu panna (constraints)
- Ajalugu, kes mida tegi (transactions, audit)

---

### 1.2. Miks PostgreSQL?

#### Võrdlus Teiste Andmebaasidega

| Omadus | PostgreSQL | MySQL | SQLite | MongoDB |
|--------|-----------|--------|---------|---------|
| **Tüüp** | Relatsiooniline | Relatsiooniline | Relatsiooniline | NoSQL/Dokument |
| **ACID** | ✅ Täielik | ✅ InnoDB'ga | ✅ Piiratud | ⚠️ Valikuline |
| **SQL Standard** | ✅ Väga hea | ⚠️ Hea | ⚠️ Piiratud | ❌ Ei kasuta SQL |
| **JSON Tugi** | ✅ Native | ⚠️ Põhiline | ⚠️ Põhiline | ✅ Native |
| **Täiustatud Funktsioonid** | ✅ Palju | ⚠️ Mõõdukalt | ❌ Vähe | ⚠️ Erinevad |
| **Skaleeritavus** | ✅ Väga hea | ✅ Hea | ❌ Väike | ✅ Väga hea |
| **Litsents** | ✅ BSD (vaba) | ⚠️ GPL/Dual | ✅ Public domain | ⚠️ SSPL |
| **Populaarsus** | 🥈 2. koht | 🥇 1. koht | 🥉 3. koht | 🥉 4. koht |

---

### 1.3. PostgreSQL Peamised Eelised

✅ **ACID Compliance** - Andmete terviklikkus on garanteeritud
✅ **Täiustatud Andmetüübid** - JSON, Array, hstore, UUID, ja palju muud
✅ **Võimas SQL** - Window functions, CTE, full-text search
✅ **Extensiblity** - Laiendused (PostGIS, pg_trgm, pgcrypto)
✅ **MVCC** - Multi-Version Concurrency Control (paremad lukkud)
✅ **Replication** - Master-slave, logical replication
✅ **Täielik ACID** - Isegi keerulistel juhtudel
✅ **Aktiivne Kogukond** - Regulaarsed uuendused ja tugi

---

### 1.4. PostgreSQL Arhitektuur (lihtsustatud)

```
┌─────────────────────────────────────────────────┐
│           PostgreSQL Server                      │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │   Postmaster (Main Process)              │  │
│  └────────────┬─────────────────────────────┘  │
│               │                                  │
│               ├─▶ Backend Process 1             │
│               ├─▶ Backend Process 2             │
│               ├─▶ Backend Process 3             │
│               │   ...                            │
│               │                                  │
│  ┌────────────▼─────────────────────────────┐  │
│  │   Shared Memory                          │  │
│  │   - Shared buffers                       │  │
│  │   - WAL buffers                          │  │
│  │   - Lock tables                          │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │   Background Processes                   │  │
│  │   - WAL writer                           │  │
│  │   - Checkpointer                         │  │
│  │   - Autovacuum                           │  │
│  │   - Stats collector                      │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
         ┌─────────────────┐
         │   Data Files    │
         │   (PGDATA)      │
         └─────────────────┘
```

---

## 2. Docker Põhimõtted

### 2.1. Mis on Docker?

**Docker** on platvorm, mis võimaldab pakkida, levitada ja käivitada rakendusi **konteinerites**.

#### Analoogia: Shipping Container

**Enne konteinereid (1950-ndad):**
- Laevad laaditi käsitsi
- Iga kaup oli erineva suuruse ja kujuga
- Aeganõudev ja kallis

**Pärast konteinerite leiutamist:**
- Standardsed konteinerid (20ft, 40ft)
- Mahuvad kõigile laevadele, rongidele, veoautodele
- Kiire ja efektiivne

**Docker teeb sama tarkvaraga:**
- **Standardne formaat** - Docker image
- **Töötab kõikjal** - arendaja laptop, test server, produktsioon
- **Isoleeritud** - ei sega teisi rakendusi
- **Kerge** - jagab OS kerneli (ei ole VM)

---

### 2.2. Docker vs Virtuaalmasin

```
┌─────────────────────────────────────────────┐
│        VIRTUAL MACHINE APPROACH             │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │  App A   │  │  App B   │  │  App C   │ │
│  ├──────────┤  ├──────────┤  ├──────────┤ │
│  │  Bins/   │  │  Bins/   │  │  Bins/   │ │
│  │  Libs    │  │  Libs    │  │  Libs    │ │
│  ├──────────┤  ├──────────┤  ├──────────┤ │
│  │ Guest OS │  │ Guest OS │  │ Guest OS │ │  <-- Raiskab ressursse
│  └──────────┘  └──────────┘  └──────────┘ │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │         Hypervisor (ESXi, KVM)      │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │         Host Operating System       │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │         Physical Hardware           │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│           DOCKER APPROACH                   │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │  App A   │  │  App B   │  │  App C   │ │
│  ├──────────┤  ├──────────┤  ├──────────┤ │
│  │  Bins/   │  │  Bins/   │  │  Bins/   │ │
│  │  Libs    │  │  Libs    │  │  Libs    │ │
│  └──────────┘  └──────────┘  └──────────┘ │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │         Docker Engine               │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │         Host Operating System       │   │  <-- Ühine OS
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │         Physical Hardware           │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

**Docker Eelised:**
- ✅ Kergemad (jagavad OS kerneli)
- ✅ Kiirem käivitamine (sekundid vs minutid)
- ✅ Väiksem ressursivajadus
- ✅ Lihtsam haldamine

---

### 2.3. Docker Põhimõisted

#### 2.3.1. Docker Image

**Image** on "tempel" (template), millest luuakse konteinerid.

- Sisaldab OS-i, rakendust, sõltuvusi
- Read-only (ei muutu)
- Kihiline struktuur (layers)
- Salvestatud registry-s (Docker Hub)

```
Näide: postgres:16-alpine
         ↑       ↑     ↑
         │       │     └─ Variant (alpine = väike)
         │       └─ Versioon
         └─ Image nimi
```

#### 2.3.2. Docker Container

**Container** on käimasolev image instance.

- Isoleeritud protsess
- Oma failisüsteem (overlay)
- Oma võrk
- Read-write kiht
- Ajutine (kustudes kaovad muudatused)

```
Image → Container Relationship
  📦 postgres:16 (image)
      ↓
      ├─▶ 🏃 postgres-prod (container)
      ├─▶ 🏃 postgres-test (container)
      └─▶ 🏃 postgres-dev (container)
```

#### 2.3.3. Docker Volume

**Volume** on püsiv andmesalvestus konteinerite jaoks.

- Andmed ei kao, kui konteiner kustutatakse
- Jagatud mitme konteineri vahel
- Backup-itav
- Haldab Docker

```
Container (ephemeral)  →  Volume (persistent)
     💾 /var/lib/postgresql/data
                    ↓
         🗄️ postgres_data (volume)
```

#### 2.3.4. Docker Network

**Network** võimaldab konteineritel omavahel suhelda.

```
┌─────────────────────────────────────┐
│      Docker Network: app-net        │
├─────────────────────────────────────┤
│                                     │
│  postgres (10.0.1.2)                │
│      ↕                              │
│  backend (10.0.1.3)                 │
│      ↕                              │
│  frontend (10.0.1.4)                │
│                                     │
└─────────────────────────────────────┘
```

---

## 3. Docker Paigaldamine VPS-ile

### 3.1. Eelduste Kontrollimine

```bash
# Logi VPS-i sisse
ssh hostinger-vps

# Kontrolli, kas Docker on juba paigaldatud
docker --version
# Kui saad versiooni, on Docker juba olemas
# Kui "command not found", jätkame paigaldamisega
```

---

### 3.2. Docker Engine Paigaldamine (Ametlik Meetod)

#### Samm 1: Eemalda Vanad Versioonid

```bash
# Eemalda vanad või konflikteeruvad paketid
sudo apt remove docker docker-engine docker.io containerd runc 2>/dev/null || true
```

#### Samm 2: Paigalda Sõltuvused

```bash
sudo apt update
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

#### Samm 3: Lisa Docker GPG Võti

```bash
# Loo directory GPG võtmete jaoks
sudo install -m 0755 -d /etc/apt/keyrings

# Lae alla Docker GPG võti
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Seadista õigused
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

#### Samm 4: Lisa Docker Repository

```bash
# Lisa Docker apt repositoorium
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### Samm 5: Paigalda Docker Engine

```bash
# Uuenda pakettide nimekirja
sudo apt update

# Paigalda Docker Engine, CLI ja Containerd
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Selgitus:
# docker-ce              : Docker Engine (community edition)
# docker-ce-cli          : Docker käsurida
# containerd.io          : Container runtime
# docker-buildx-plugin   : Extended build capabilities
# docker-compose-plugin  : Docker Compose V2
```

---

### 3.3. Docker Teenuse Kontrollimine

```bash
# Kontrolli Docker teenuse staatust
sudo systemctl status docker

# Väljund:
# ● docker.service - Docker Application Container Engine
#      Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
#      Active: active (running) since Thu 2024-11-14 11:00:00 EET; 2min ago
#        Docs: https://docs.docker.com
#    Main PID: 12345 (dockerd)
#       Tasks: 8
#      Memory: 35.2M
#         CPU: 450ms
#      CGroup: /system.slice/docker.service
#              └─12345 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
```

**Kui ei ole käivitatud:**
```bash
sudo systemctl start docker
sudo systemctl enable docker  # Käivita automaatselt boot-imisel
```

---

### 3.4. Docker Kasutaja Gruppi Lisamine

Vaikimisi saab Dockerit kasutada ainult root või sudo'ga. Lisame oma kasutaja Docker gruppi:

```bash
# Lisa oma kasutaja docker gruppi
sudo usermod -aG docker $USER

# Logi välja ja uuesti sisse, et grupp rakenduda
exit
```

**Logi uuesti sisse:**
```bash
ssh hostinger-vps
```

**Kontrolli grupi kuuluvust:**
```bash
groups
# Väljund peaks sisaldama "docker"
```

---

### 3.5. Docker Testimine

```bash
# Test: Käivita "hello-world" konteiner
docker run hello-world

# Väljund:
# Unable to find image 'hello-world:latest' locally
# latest: Pulling from library/hello-world
# ...
# Status: Downloaded newer image for hello-world:latest
#
# Hello from Docker!
# This message shows that your installation appears to be working correctly.
```

✅ **Docker on paigaldatud ja töötab!**

---

### 3.6. Docker Info ja Versioon

```bash
# Docker versioon
docker --version
# Väljund: Docker version 24.0.7, build afdd53b

# Põhjalik info
docker info

# Väljund (lühendatud):
# Client: Docker Engine - Community
#  Version:    24.0.7
#  Context:    default
#
# Server:
#  Containers: 1
#   Running: 0
#   Paused: 0
#   Stopped: 1
#  Images: 1
#  Server Version: 24.0.7
#  Storage Driver: overlay2
#  ...
```

---

## 4. PRIMAARNE: PostgreSQL Dockeris 🐳

### 4.1. Miks PostgreSQL Dockeris?

#### Eelised

✅ **Lihtne paigaldamine** - Üks käsk, valmis
✅ **Isolatsioon** - Ei sega host süsteemi
✅ **Versioonihaldus** - Kerge vahetada versioone
✅ **Reprodutseeritav** - Sama käitub kõikjal
✅ **Kergesti kustutatav** - `docker rm`, valmis
✅ **Kubernetes ready** - Kerge migreerida K8s-i

#### Puudused

⚠️ **Natuke keerulisem backup** - Vaja volume'e hallata
⚠️ **Overhead** - Väike (aga märgatav)
⚠️ **Volume'ide haldus** - Ekstra samm

---

### 4.2. PostgreSQL Image Valimine

Docker Hub-is on mitu PostgreSQL image varianti:

```bash
# Offitsiaalne image
docker pull postgres:16

# Alpine variant (väiksem)
docker pull postgres:16-alpine

# Konkreetne minor versioon
docker pull postgres:16.1-alpine
```

**Soovitus:** Kasutame `postgres:16-alpine`
- ✅ Väiksem size (~240 MB vs ~420 MB)
- ✅ Vähem turvaauke (vähem pakette)
- ✅ Sama funktsionaalsus

---

### 4.3. PostgreSQL Konteineri Käivitamine (põhiline)

#### 4.3.1. Lihtne Käivitamine (testimiseks)

```bash
# Käivita PostgreSQL konteiner
docker run --name postgres-test \
  -e POSTGRES_PASSWORD=mypassword \
  -p 5432:5432 \
  -d postgres:16-alpine

# Selgitus:
# --name          : Konteineri nimi
# -e              : Environment variable (keskkonnamuutuja)
# -p 5432:5432    : Port mapping (host:container)
# -d              : Detached mode (taustal)
# postgres:16-alpine : Image
```

**Kontrolli:**
```bash
docker ps

# Väljund:
# CONTAINER ID   IMAGE                COMMAND                  CREATED          STATUS          PORTS                    NAMES
# a1b2c3d4e5f6   postgres:16-alpine   "docker-entrypoint.s…"   10 seconds ago   Up 9 seconds    0.0.0.0:5432->5432/tcp   postgres-test
```

---

#### 4.3.2. Tootmiseks Sobiv Käivitamine (volume'iga)

```bash
# 1. Loo Docker volume andmete jaoks
docker volume create postgres_data

# 2. Käivita PostgreSQL volume'iga
docker run --name postgres-prod \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=StrongPassword123! \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_INITDB_ARGS="-E UTF8 --locale=C" \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --restart unless-stopped \
  -d postgres:16-alpine

# Selgitus:
# -e POSTGRES_USER     : Loo kasutaja (vaikimisi: postgres)
# -e POSTGRES_PASSWORD : Parool (KOHUSTUSLIK!)
# -e POSTGRES_DB       : Loo algne andmebaas
# -e POSTGRES_INITDB_ARGS : Initsialiseerimise parameetrid
# -v postgres_data:... : Mount volume (PÜSIV ANDMESALVESTUS!)
# --restart unless-stopped : Taaskäivita automaatselt
```

**Kontrolli:**
```bash
# Vaata konteinerit
docker ps

# Vaata loge
docker logs postgres-prod

# Väljund peaks sisaldama:
# ...
# PostgreSQL init process complete; ready for start up.
# ...
# database system is ready to accept connections
```

✅ **PostgreSQL töötab!**

---

### 4.4. PostgreSQL Volume'ide Haldamine

#### 4.4.1. Volume'ide Loend

```bash
# Kõik volume'id
docker volume ls

# Väljund:
# DRIVER    VOLUME NAME
# local     postgres_data
```

#### 4.4.2. Volume Inspekteerimine

```bash
# Volume'i detailne info
docker volume inspect postgres_data

# Väljund (JSON):
# [
#     {
#         "CreatedAt": "2024-11-14T11:30:00Z",
#         "Driver": "local",
#         "Labels": null,
#         "Mountpoint": "/var/lib/docker/volumes/postgres_data/_data",
#         "Name": "postgres_data",
#         "Options": null,
#         "Scope": "local"
#     }
# ]
```

**Oluline:** Mountpoint on kus andmed päriselt on host masinas.

---

### 4.5. PostgreSQL Konteineriga Ühendamine

#### 4.5.1. psql CLI Konteineris

```bash
# Ühenda PostgreSQL-iga psql kaudu
docker exec -it postgres-prod psql -U appuser -d appdb

# Väljund:
# psql (16.1)
# Type "help" for help.
#
# appdb=#
```

**Oled nüüd PostgreSQL CLI-s!** 🎉

---

#### 4.5.2. Põhilised psql Käsud

```sql
-- Andmebaaside loend
\l

-- Tabelite loend
\dt

-- Ühenda teise andmebaasiga
\c postgres

-- Kasutajate loend
\du

-- Väljumine
\q
```

---

### 4.6. PostgreSQL Konfiguratsiooni Muutmine

#### 4.6.1. Postgresql.conf Custom Seaded

Loo konfiguratsioonifail host masinas:

```bash
# Loo kataloog konfiguratsioonile
mkdir -p ~/postgres-config

# Loo custom konfiguratsioon
nano ~/postgres-config/custom.conf
```

**Lisa sisu:**
```ini
# Custom PostgreSQL Configuration

# Connections
max_connections = 200

# Memory
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
work_mem = 5MB

# Checkpoints
checkpoint_completion_target = 0.9
wal_buffers = 16MB

# Query Planning
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'mod'
log_duration = on
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

**Salvesta** (Ctrl+O, Enter) ja **välju** (Ctrl+X)

---

#### 4.6.2. Käivita PostgreSQL Custom Konfiguratsiooniga

```bash
# Peata ja eemalda vana konteiner
docker stop postgres-prod
docker rm postgres-prod

# Käivita uuesti custom konfiguratsiooniga
docker run --name postgres-prod \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=StrongPassword123! \
  -e POSTGRES_DB=appdb \
  -v postgres_data:/var/lib/postgresql/data \
  -v ~/postgres-config/custom.conf:/etc/postgresql/postgresql.conf \
  -p 5432:5432 \
  --restart unless-stopped \
  -d postgres:16-alpine \
  postgres -c config_file=/etc/postgresql/postgresql.conf
```

---

### 4.7. Docker Network'iga PostgreSQL

Kui tahad, et ainult teised konteinerid saaksid PostgreSQL-iga ühenduda:

```bash
# Loo custom network
docker network create app-network

# Käivita PostgreSQL selles network'is (ilma port mapping'uta)
docker run --name postgres-prod \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=StrongPassword123! \
  -e POSTGRES_DB=appdb \
  -v postgres_data:/var/lib/postgresql/data \
  --network app-network \
  --restart unless-stopped \
  -d postgres:16-alpine

# Nüüd on PostgreSQL kättesaadav ainult app-network'is
# Hostname: postgres-prod
# Port: 5432 (default)
```

**Backend konteiner saab ühenduda:**
```javascript
const connectionString = 'postgresql://appuser:password@postgres-prod:5432/appdb';
```

---

## 5. ALTERNATIIV: PostgreSQL VPS-ile 🖥️

### 5.1. Miks PostgreSQL VPS-ile?

#### Eelised

✅ **Maksimaalne jõudlus** - Ei ole Docker overhead'i
✅ **Traditsiooniline** - Tuttav DBAdministraatoritele
✅ **Lihtsam backup** - Standardsed PostgreSQL tööriistad
✅ **Streaming replication** - Lihtsam seadistada
✅ **Suur produktsioon** - Sobilik kõrge koormuse jaoks

#### Puudused

⚠️ **Keerulisem paigaldamine** - Rohkem samme
⚠️ **OS sõltuv** - Seotud host OS-iga
⚠️ **Keerulisem versioonihaldus** - Ei saa nii lihtsalt vahetada
⚠️ **Jagab ressursse** - Host OS'iga

---

### 5.2. PostgreSQL Paigaldamine APT-ga

#### Samm 1: Lisa PostgreSQL Official Repository

```bash
# Impordi PostgreSQL signing key
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  sudo gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg

# Lisa repositoorium
echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | \
  sudo tee /etc/apt/sources.list.d/pgdg.list
```

#### Samm 2: Uuenda ja Paigalda PostgreSQL 16

```bash
# Uuenda pakettide nimekirja
sudo apt update

# Paigalda PostgreSQL 16
sudo apt install -y postgresql-16 postgresql-contrib-16

# Selgitus:
# postgresql-16        : PostgreSQL server ja klient
# postgresql-contrib-16: Lisafunktsioonid (extensions)
```

**Paigaldamine võtab 1-2 minutit...**

---

### 5.3. PostgreSQL Teenuse Kontrollimine

```bash
# Kontrolli teenuse staatust
sudo systemctl status postgresql

# Väljund:
# ● postgresql.service - PostgreSQL RDBMS
#      Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
#      Active: active (exited) since Thu 2024-11-14 12:00:00 EET; 1min ago
#    Main PID: 23456 (code=exited, status=0/SUCCESS)
#         CPU: 2ms
```

**PostgreSQL teenus käivitub automaatselt!**

---

### 5.4. PostgreSQL Kasutaja ja Andmebaasi Loomine

#### 5.4.1. Vaheta postgres Kasutajaks

PostgreSQL loob automaatselt `postgres` süsteemikasutaja:

```bash
# Vaheta postgres kasutajaks
sudo -i -u postgres

# Oled nüüd postgres kasutaja
postgres@hostinger-ubuntu:~$
```

---

#### 5.4.2. Loo Rakenduse Kasutaja

```bash
# Käivita psql
psql

# PostgreSQL CLI
postgres=#
```

**Nüüd PostgreSQL CLI-s:**

```sql
-- Loo uus kasutaja (roll)
CREATE ROLE appuser WITH LOGIN PASSWORD 'StrongPassword123!';

-- Anna kasutajale õigus andmebaase luua
ALTER ROLE appuser CREATEDB;

-- Kontrolli kasutajat
\du

-- Väljund:
--                                    List of roles
--  Role name |                         Attributes
-- -----------+------------------------------------------------------------
--  appuser   | Create DB
--  postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
```

---

#### 5.4.3. Loo Andmebaas

```sql
-- Loo andmebaas
CREATE DATABASE appdb OWNER appuser;

-- Andmebaasi detailid
\l appdb

-- Väljund:
--   Name  | Owner   | Encoding | Collate |  Ctype  | Access privileges
-- --------+---------+----------+---------+---------+-------------------
--  appdb  | appuser | UTF8     | C.UTF-8 | C.UTF-8 |

-- Ühenda loodud andmebaasiga
\c appdb

-- Väljund:
-- You are now connected to database "appdb" as user "postgres".

-- Väljumine
\q
```

**Välju postgres kasutajast:**
```bash
exit
# Oled tagasi oma tavakasutajana
```

---

### 5.5. PostgreSQL Võrguühenduste Seadistamine

Vaikimisi PostgreSQL kuulab ainult `localhost`. Kui tahad, et kaugühendused oleksid võimalikud:

#### 5.5.1. Muuda postgresql.conf

```bash
# Leia konfiguratsioonifail
sudo -u postgres psql -c "SHOW config_file;"

# Väljund:
#                config_file
# ------------------------------------------
#  /etc/postgresql/16/main/postgresql.conf

# Redigeeri konfiguratsioonifaili
sudo nano /etc/postgresql/16/main/postgresql.conf
```

**Leia ja muuda rida:**
```ini
# Enne:
#listen_addresses = 'localhost'

# Pärast (luba kõik liidesed):
listen_addresses = '*'

# VÕI ainult konkreetne IP:
# listen_addresses = '192.168.1.100,127.0.0.1'
```

**Salvesta** (Ctrl+O, Enter) ja **välju** (Ctrl+X)

---

#### 5.5.2. Muuda pg_hba.conf (autentimine)

```bash
# Redigeeri pg_hba.conf
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

**Lisa faili lõppu:**
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Luba lokaalsed ühendused
local   all             all                                     peer

# Luba kõik ühendused localhost-ist parooliga
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256

# Luba ühendused Docker network'ist (kui Docker konteinerid peavad ühenduma)
host    all             all             172.17.0.0/16           scram-sha-256

# ALTERNATIIV: Luba kõik (AINULT TESTIMISEKS!)
# host    all             all             0.0.0.0/0               scram-sha-256

# Selgitus:
# peer          : Süsteemi kasutaja == PostgreSQL kasutaja (lokaalne)
# scram-sha-256 : Krüpteeritud parool autentimine
# md5           : Vanem (vähem turvaline) parool autentimine
```

**Salvesta** (Ctrl+O, Enter) ja **välju** (Ctrl+X)

---

#### 5.5.3. Taaskäivita PostgreSQL

```bash
# Taaskäivita teenus
sudo systemctl restart postgresql

# Kontrolli staatust
sudo systemctl status postgresql

# Kontrolli, kas kuulab õigel pordil
sudo ss -tlnp | grep 5432

# Väljund:
# LISTEN 0      200          0.0.0.0:5432       0.0.0.0:*    users:(("postgres",pid=12345,fd=5))
# LISTEN 0      200             [::]:5432          [::]:*    users:(("postgres",pid=12345,fd=6))
```

✅ **PostgreSQL kuulab nüüd kõigil interface'idel!**

---

### 5.6. Firewall'i Reeglid (kui vajalik)

Kui tahad lubada välised ühendused PostgreSQL-iga:

```bash
# Luba PostgreSQL port (5432)
sudo ufw allow 5432/tcp comment 'PostgreSQL'

# Kontrolli
sudo ufw status | grep 5432
```

**HOIATUS:** Ainult tee seda, kui sa päriselt vajad väliseid ühendusi. Turvalisem on hoida PostgreSQL ligipääsetavana ainult lokaalselt või läbi SSH tunnel'i.

---

### 5.7. Testimine

#### Test 1: Lokaalne Ühendus

```bash
# Ühenda appuser'ina
psql -U appuser -d appdb -h localhost

# Palub parooli:
# Password for user appuser:
# (sisesta: StrongPassword123!)

# Kui õnnestub:
# appdb=>
```

#### Test 2: Uuesti Süsteemikasutajana

```bash
# Vaheta postgres kasutajaks
sudo -i -u postgres

# Ühenda ilma paroolita (peer auth)
psql

# postgres=#
```

✅ **Mõlemad meetodid töötavad!**

---

## 6. Variantide Võrdlus

### 6.1. Üksikasjalik Võrdlus

| Aspekt | Docker PostgreSQL | Väline PostgreSQL |
|--------|-------------------|-------------------|
| **Paigaldamine** | `docker run` (1 käsk) | `apt install` + konfig (3-5 sammu) |
| **Ressursid (RAM)** | ~200 MB + andmed | ~150 MB + andmed |
| **Ressursid (Disk)** | Image ~240 MB + andmed | ~300 MB + andmed |
| **Käivitusaeg** | 2-3 sekundit | 1-2 sekundit |
| **Isolatsioon** | Täielik (oma failisüsteem) | Jagab host OS-iga |
| **Versioon upgrade** | Uus konteiner, migrate data | `apt upgrade`, riskantsem |
| **Backup** | Volume snapshot/export | pg_dump, pg_basebackup |
| **Restore** | Volume restore | psql < backup.sql |
| **Monitoring** | Docker stats + logs | systemctl status, native logs |
| **Networking** | Docker network | Host network |
| **Port Conflicts** | Port mapping lahendab | Peab olema vaba 5432 |
| **Multi-version** | Mitu versiooni paralleelselt | Keeruline (tuleb erinevad pordid) |
| **Konfiguratsiooni Haldus** | Volume mount või env vars | /etc/postgresql/... |
| **Turvalisus** | Isoleeritud namespace | OS-level permissions |
| **Sobib Kubernetes-ele** | ✅ Otse kasutatav | ❌ Peab bridge'ima |
| **DBA Sobivus** | ⚠️ Uus lähenemine | ✅ Traditsiooniline |
| **Arenduskeskkond** | ✅ Ideaalne | ⚠️ Päris tootmise simulatsioon |
| **Tootmine (väike)** | ✅ Väga hea | ✅ Väga hea |
| **Tootmine (suur)** | ⚠️ OK | ✅ Ideaalne |

---

### 6.2. Millal Valida Kumma?

#### Vali Docker PostgreSQL Kui:

✅ Õpid konteinerisatsiooni või Kubernetes'it
✅ Tahad kergesti erinevaid versioone testida
✅ Vajad kiiresti dev/test keskkonda
✅ Liigud Kubernetes'e suunas tulevikus
✅ Tahad isoleeritud keskkonda
✅ Sul on piisavalt mälu (8 GB+)

---

#### Vali Väline PostgreSQL Kui:

✅ Sul on kogenud DBA meeskonnas
✅ Suur produktsioonisüsteem kõrge koormaga
✅ Maksimaalse jõudluse vajadus
✅ Traditsiooniline taristu
✅ Streaming replication on prioriteet
✅ Ei plaani Kubernetes'i kasutada

---

### 6.3. Meie Koolituses

**Primaarselt kasutame Docker PostgreSQL:**
- Ideaalne õppimiseks
- Lihtne cleanup
- Kubernetes native
- Kaasaegne DevOps approach

**Alternatiivina õpime välist:**
- Päriselu stsenaarium
- Traditsiooniline approach
- Hybrid arhitektuur võimalus

---

## 7. Andmebaasi Algne Seadistamine

### 7.1. Esimese Tabeli Loomine

**Ühenda PostgreSQL-iga** (mõlemas variandis):

**Docker:**
```bash
docker exec -it postgres-prod psql -U appuser -d appdb
```

**Väline:**
```bash
psql -U appuser -d appdb -h localhost
```

---

### 7.2. Loo Testtabel

```sql
-- Loo tabel kasutajate jaoks
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lisa kommentaar tabelile
COMMENT ON TABLE users IS 'Rakenduse kasutajad';

-- Kontrolli tabelit
\d users
```

**Väljund:**
```
                                          Table "public.users"
    Column     |            Type             | Collation | Nullable |              Default
---------------+-----------------------------+-----------+----------+-----------------------------------
 id            | integer                     |           | not null | nextval('users_id_seq'::regclass)
 username      | character varying(50)       |           | not null |
 email         | character varying(100)      |           | not null |
 password_hash | character varying(255)      |           | not null |
 created_at    | timestamp without time zone |           |          | CURRENT_TIMESTAMP
 updated_at    | timestamp without time zone |           |          | CURRENT_TIMESTAMP
Indexes:
    "users_pkey" PRIMARY KEY, btree (id)
    "users_email_key" UNIQUE CONSTRAINT, btree (email)
    "users_username_key" UNIQUE CONSTRAINT, btree (username)
```

---

### 7.3. Lisa Testadmeid

```sql
-- Lisa kasutajaid
INSERT INTO users (username, email, password_hash) VALUES
    ('alice', 'alice@example.com', '$2b$12$hash1...'),
    ('bob', 'bob@example.com', '$2b$12$hash2...'),
    ('charlie', 'charlie@example.com', '$2b$12$hash3...');

-- Kontrolli andmeid
SELECT id, username, email, created_at FROM users;
```

**Väljund:**
```
 id | username |       email        |       created_at
----+----------+--------------------+-------------------------
  1 | alice    | alice@example.com  | 2024-11-14 12:30:00
  2 | bob      | bob@example.com    | 2024-11-14 12:30:00
  3 | charlie  | charlie@example.com| 2024-11-14 12:30:00
(3 rows)
```

---

## 8. PostgreSQL Põhikäsud ja SQL

### 8.1. psql Meta-käsud

```sql
-- Andmebaaside loend
\l

-- Tabelite loend
\dt

-- Tabeli struktuur
\d users

-- Indeksite loend
\di

-- Kasutajate loend
\du

-- Ühenda teise andmebaasiga
\c postgres

-- Näita käsu täitmisaega
\timing on

-- Laienda väljund (vertical)
\x

-- Abi
\?

-- SQL käskude abi
\h CREATE TABLE

-- Väljumine
\q
```

---

### 8.2. Põhilised SQL Päringud

```sql
-- SELECT (lugemine)
SELECT * FROM users;
SELECT username, email FROM users WHERE id = 1;

-- INSERT (lisamine)
INSERT INTO users (username, email, password_hash)
VALUES ('david', 'david@example.com', 'hash...');

-- UPDATE (uuendamine)
UPDATE users SET email = 'newemail@example.com' WHERE username = 'alice';

-- DELETE (kustutamine)
DELETE FROM users WHERE username = 'david';

-- COUNT (loendamine)
SELECT COUNT(*) FROM users;

-- ORDER BY (sorteerimine)
SELECT * FROM users ORDER BY created_at DESC;

-- LIMIT (piiramine)
SELECT * FROM users LIMIT 2;
```

---

### 8.3. Transaktsiooonid

```sql
-- Alusta transaktsiooni
BEGIN;

-- Tee muudatusi
INSERT INTO users (username, email, password_hash)
VALUES ('eve', 'eve@example.com', 'hash...');

UPDATE users SET username = 'alice_new' WHERE username = 'alice';

-- Kontrolli (ei ole veel commited)
SELECT * FROM users;

-- ROLLBACK (tühista kõik muudatused)
ROLLBACK;

-- VÕI COMMIT (salvesta muudatused)
-- COMMIT;
```

---

## 9. Harjutused

### Harjutus 3.1: Docker Paigaldamine ja Testimine

**Eesmärk:** Paigaldada Docker VPS-ile

**Sammud:**
1. Paigalda Docker (järgi sektsiooni 3.2)
2. Lisa oma kasutaja docker gruppi
3. Testi `docker run hello-world`
4. Kontrolli `docker --version`
5. Vaata Docker info: `docker info`

**Oodatav tulemus:** "Hello from Docker!" sõnum

---

### Harjutus 3.2: PostgreSQL Dockeris (Primaarne)

**Eesmärk:** Käivitada PostgreSQL Docker konteineris

**Sammud:**
1. Loo Docker volume: `postgres_data`
2. Käivita PostgreSQL konteiner volume'iga
3. Kontrolli, kas konteiner töötab: `docker ps`
4. Vaata loge: `docker logs postgres-prod`
5. Ühenda psql: `docker exec -it postgres-prod psql -U appuser -d appdb`

**Kontrolli:**
```sql
SELECT version();
```

---

### Harjutus 3.3: PostgreSQL VPS-ile (Alternatiiv)

**Eesmärk:** Paigaldada PostgreSQL otse VPS-ile

**Sammud:**
1. Lisa PostgreSQL repositoorium
2. Paigalda PostgreSQL 16
3. Kontrolli teenuse staatust
4. Loo kasutaja `appuser`
5. Loo andmebaas `appdb`
6. Ühenda: `psql -U appuser -d appdb -h localhost`

---

### Harjutus 3.4: Esimene Tabel ja Andmed

**Eesmärk:** Luua tabel ja lisada andmeid

**Sammud:**
1. Ühenda PostgreSQL-iga (Docker või väline)
2. Loo tabel `products`:
```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
3. Lisa 3 toodet
4. Tee SELECT päring
5. Uuenda ühe toote hinda
6. Kustuta üks toode

---

### Harjutus 3.5: Variantide Võrdlus

**Eesmärk:** Võrrelda mõlemat varianti praktikas

**Ülesanne:**
1. Käivita PostgreSQL mõlemas variandis (Docker + Väline)
2. Mõõda ressursikasutust:
   - Docker: `docker stats postgres-prod`
   - Väline: `ps aux | grep postgres`
3. Võrdle mälu ja CPU kasutust
4. Täida tabel:

| Aspekt | Docker | Väline |
|--------|--------|--------|
| RAM kasutus | _____ MB | _____ MB |
| Käivitusaeg | _____ s | _____ s |
| Lihtsus (1-10) | _____ | _____ |

---

## 10. Kontrolliküsimused

### Teoreetilised Küsimused

1. **Mis on Docker ja miks on see kasulik andmebaaside jaoks?**
   <details>
   <summary>Vastus</summary>
   Docker on konteinerisatsiooniplatvorm, mis pakib rakenduse ja sõltuvused isoleeritud konteinerisse. Andmebaaside puhul annab see: lihtsa paigaldamise, isolatsiooni, kerge versioonihalduse, reprodutseeritavuse ja Kubernetes-readiness.
   </details>

2. **Mis on Docker Volume ja miks on see oluline PostgreSQL jaoks?**
   <details>
   <summary>Vastus</summary>
   Docker Volume on püsiv andmesalvestus, mis eksisteerib ka pärast konteineri kustutamist. PostgreSQL jaoks on see kriitiline, sest andmed ei tohi kaduda, kui konteiner uueneb või taaskäivitatakse.
   </details>

3. **Mis vahe on Docker Image ja Container vahel?**
   <details>
   <summary>Vastus</summary>
   Docker Image on read-only template (mall), millest luuakse konteinereid. Container on käimasolev image instance - isoleeritud protsess koos oma failisüsteemiga.
   </details>

4. **Miks on postgres:16-alpine image väiksem kui postgres:16?**
   <details>
   <summary>Vastus</summary>
   Alpine Linux on minimalistlik Linux distributsioon (~5 MB), mis sisaldab ainult vajalikku. Standardne postgres image põhineb Debian/Ubuntu-l, mis on palju suurem (~100 MB base).
   </details>

5. **Mis on pg_hba.conf fail ja mis otstarvet see täidab?**
   <details>
   <summary>Vastus</summary>
   pg_hba.conf (Host-Based Authentication) määrab, kes ja kust võib PostgreSQL-iga ühenduda ning millist autentimismeetodit kasutada. See on PostgreSQL turvalisuse kriitiline osa.
   </details>

6. **Millal kasutada Docker PostgreSQL vs välist PostgreSQL-i?**
   <details>
   <summary>Vastus</summary>
   Docker: õppimine, dev/test, Kubernetes, mikrotenvused, kerge versioonihaldus. Väline: suur produktsioon, maksimaalne jõudlus, traditsiooniline DBA, streaming replication.
   </details>

---

### Praktilised Küsimused

7. **Kuidas käivitada PostgreSQL Docker konteiner, mis taaskäivitub automaatselt?**
   <details>
   <summary>Vastus</summary>
   ```bash
   docker run --name postgres-prod \
     -e POSTGRES_PASSWORD=password \
     -v postgres_data:/var/lib/postgresql/data \
     --restart unless-stopped \
     -d postgres:16-alpine
   ```
   </details>

8. **Kuidas ühenduda psql-iga Docker PostgreSQL konteineris?**
   <details>
   <summary>Vastus</summary>
   ```bash
   docker exec -it postgres-prod psql -U postgres
   ```
   </details>

9. **Kuidas vaadata Docker konteineri loge?**
   <details>
   <summary>Vastus</summary>
   ```bash
   docker logs postgres-prod
   # VÕI live:
   docker logs -f postgres-prod
   ```
   </details>

10. **Kuidas muuta PostgreSQL konfiguratsioonifail välises PostgreSQL-is?**
    <details>
    <summary>Vastus</summary>
    ```bash
    # Leia konfifail
    sudo -u postgres psql -c "SHOW config_file;"
    # Redigeeri
    sudo nano /etc/postgresql/16/main/postgresql.conf
    # Taaskäivita
    sudo systemctl restart postgresql
    ```
    </details>

11. **Kuidas luua uus kasutaja PostgreSQL-is?**
    <details>
    <summary>Vastus</summary>
    ```sql
    CREATE ROLE username WITH LOGIN PASSWORD 'password';
    ALTER ROLE username CREATEDB;
    ```
    </details>

12. **Kuidas kontrollida PostgreSQL versiooni?**
    <details>
    <summary>Vastus</summary>
    ```sql
    SELECT version();
    ```
    VÕI käsurealt:
    ```bash
    psql --version
    ```
    </details>

---

## 11. Lisamaterjalid

### 📚 Soovitatud Lugemine

#### PostgreSQL
- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)
- [PostgreSQL Exercises](https://pgexercises.com/)

#### Docker
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker PostgreSQL Image](https://hub.docker.com/_/postgres)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

### 🛠️ Kasulikud Tööriistad

#### Database Clients
- **psql** - Command-line (built-in)
- **DBeaver** - GUI (free, cross-platform)
- **pgAdmin** - Web-based GUI (official)
- **TablePlus** - Modern GUI (macOS/Windows/Linux)

#### Monitoring
- **pg_top** - PostgreSQL top
- **pg_stat_statements** - Query statistics

```bash
# pg_top paigaldamine
sudo apt install ptop
sudo -u postgres pg_top
```

---

### 🎥 Video Ressursid

- **Hussein Nasser** - PostgreSQL internals
- **Traversy Media** - PostgreSQL crash course
- **DatabaseStar** - SQL tutorials

---

## Kokkuvõte

Selles peatükis said:

✅ **Õppisid Docker põhimõtteid** ja konteinerisatsiooni
✅ **Paigaldasid Docker Engine** VPS-ile
✅ **Käivitasid PostgreSQL Dockeris** (primaarne variant)
✅ **Paigaldasid PostgreSQL VPS-ile** (alternatiivne variant)
✅ **Võrdlesid mõlemat lähenemist** - plussid ja miinused
✅ **Lõid esimese andmebaasi, kasutaja ja tabeli**
✅ **Õppisid PostgreSQL põhikäske** (psql ja SQL)

---

## Järgmine Peatükk

**Peatükk 4: Git ja Versioonihaldus**

Järgmises peatükis:
- Git põhimõtted ja töövoog
- Git konfiguratsioon ja seadistamine
- Repositooriumi loomine
- Commit, push, pull, branch, merge
- .gitignore seadistamine
- GitHub/GitLab integratsioon
- Best practices

---

## Troubleshooting

### Probleem 1: Docker konteiner ei käivitu

**Sümptom:** `docker ps` ei näita konteinerit

**Lahendus:**
```bash
# Vaata kõiki konteinereid (sh peatatud)
docker ps -a

# Vaata loge
docker logs postgres-prod

# Levinud põhjused:
# - Port 5432 on juba kasutusel
# - POSTGRES_PASSWORD ei ole määratud
# - Volume õiguste probleem
```

---

### Probleem 2: "Permission denied" Docker volume'iga

**Lahendus:**
```bash
# Kontrolli volume'i õigusi
docker volume inspect postgres_data

# Loo volume uuesti
docker volume rm postgres_data
docker volume create postgres_data
```

---

### Probleem 3: PostgreSQL ei kuula väliseid ühendusi

**Lahendus:**
```bash
# Kontrolli listen_addresses
sudo grep listen_addresses /etc/postgresql/16/main/postgresql.conf

# Peaks olema: listen_addresses = '*'

# Kontrolli pg_hba.conf
sudo nano /etc/postgresql/16/main/pg_hba.conf

# Taaskäivita
sudo systemctl restart postgresql
```

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-14
**Järgmine uuendus:** Peatükk 4 lisamine
