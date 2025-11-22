# Peatükk 4: Docker Põhimõtted

**Kestus:** 4 tundi
**Tase:** Algaja
**Eeldused:** Peatükk 1-3 läbitud, VPS juurdepääs

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist oskad:

1. ✅ Selgitada konteinerite ja VM'ide erinevusi
2. ✅ Mõista Docker arhitektuuri (daemon, client, images)
3. ✅ Hallata Docker lifecycle'i (pull → run → stop → rm)
4. ✅ Eristada Docker image'eid ja containereid
5. ✅ Kasutada port mapping'ut (-p)
6. ✅ Kasutada volume mounting'ut (-v)
7. ✅ Seadistada environment variables (-e)
8. ✅ Mõista Docker võrke (networks)
9. ✅ Debuggida containereid (logs, exec)

---

## 🎯 1. Mis On Docker ja Miks Me Seda Vajame?

### 1.1 Klassikaline Probleem: "Mul Töötab!"

**Stsenaarium:**
```
Arendaja: "Kood on valmis! Mul töötab!"
   ↓
DevOps: "Panen production'i..."
   ↓
Production: 💥 CRASH 💥
   ↓
DevOps: "See ei tööta!"
   ↓
Arendaja: "Aga mul töötab!"
```

**Miks see juhtub?**
```bash
# Arendaja masin:
- Node.js 18.0.0
- Ubuntu 22.04
- PostgreSQL 14
- PORT=3000

# Production server:
- Node.js 16.0.0  ← Vana versioon!
- Ubuntu 20.04
- PostgreSQL 12   ← Vana versioon!
- PORT=8080       ← Erinev port!

→ Dependency hell 😱
→ Versioonide konfliktid
→ Keskkonnapõhised vead
```

---

### 1.2 Docker Lahendus

**Docker filosoofia:**
```
"Kui see töötab konteine ris, siis töötab kõikjal!"
```

**Kuidas Docker seda lahendab:**
```bash
# Arendaja loob Docker image:
FROM node:18-alpine
COPY package.json .
RUN npm install
COPY src/ ./src/
CMD ["node", "src/index.js"]

# See IMAGE on identne:
- Arendaja masinas
- Staging serveris
- Production serveris
- Teise arendaja masinas

✅ Sama keskkond → sama tulemus
✅ Ei ole "aga mul töötab" probleemi
```

---

## 🖥️ 2. Konteinerid vs Virtuaalmasinad

### 2.1 Virtuaalmasin (VM)

```
+-----------------------------------+
|    App A    |    App B            |
|-------------|---------------------|
|  Libraries  |   Libraries         |
|-------------|---------------------|
|   Guest OS  |    Guest OS         |   ← Iga VM = Täielik OS!
|   (Ubuntu)  |    (CentOS)         |
+===================================+
|         Hypervisor (VMware, VirtualBox)
+===================================+
|         Host OS (Windows, Linux)
+===================================+
|         Hardware (CPU, RAM)
+-----------------------------------+
```

**VM omadused:**
- ✅ Täielik isolatsioon (omaette kernel)
- ✅ Erinevad OS'id samal hostil
- ❌ Suur ressursikulu (GB'id RAM'i)
- ❌ Aeglane käivitamine (minutid)
- ❌ Suur image suurus (GB'id)

---

### 2.2 Konteiner (Docker)

```
+-----------------------------------+
|  App A  |  App B  |  App C        |
|---------|---------|---------------|
|  Libs   |  Libs   |  Libs         |
+===================================+
|       Docker Engine               |   ← Jagatud kernel!
+===================================+
|       Host OS (Linux)
+===================================+
|       Hardware (CPU, RAM)
+-----------------------------------+
```

**Konteineri omadused:**
- ✅ Kerge (MB'id, mitte GB'id)
- ✅ Kiire käivitamine (sekundid)
- ✅ Väike ressursikulu
- ✅ Portability (töötab kõikjal)
- ❌ Jagatud kernel (kõik peavad olema Linux)

---

### 2.3 Võrdlus Tabelis

| Aspekt | Virtuaalmasin | Konteiner |
|--------|---------------|-----------|
| **Boot aeg** | 1-5 minutit | < 1 sekund |
| **Image suurus** | GB'id (5-20 GB) | MB'id (5-500 MB) |
| **RAM kasutus** | GB'id (1-8 GB) | MB'id (10-500 MB) |
| **Isolatsioon** | Täielik (omaette kernel) | Protsessi tasemel |
| **OS support** | Erinevad OS'id | Ainult Linux (jagatud kernel) |
| **Tihedus** | 10-20 VM'i serveris | 100-1000 containerit serveris |
| **Kasutus** | Toodetakse isolation, legacy | Mikroteenused, DevOps, cloud |

**Analoogia:**
```
VM = Maja (kõigega komplekt: köök, vannituba, magamistuba)
Konteiner = Korter (jagatud taristu: lift, küte, elekter)
```

---

## 🐳 3. Docker Arhitektuur

### 3.1 Docker Komponendid

```
+------------------+
|  Docker Client   |  ← docker build, docker run, docker push
+------------------+
        |
        | (REST API)
        ↓
+------------------+
|  Docker Daemon   |  ← dockerd (taustprotsess)
|  (dockerd)       |
+------------------+
        |
        ├─→ Images (read-only templates)
        ├─→ Containers (running instances)
        ├─→ Volumes (persistent data)
        └─→ Networks (container communication)
```

**Komponendid:**

1. **Docker Client (`docker` käsk):**
   - Käsurea tööriist
   - Saadab käsud Docker Daemon'ile

2. **Docker Daemon (`dockerd`):**
   - Taustprotsess
   - Haldab image'eid, containereid, võrke, volume'e
   - Kuulab REST API päringuid

3. **Docker Registry (Docker Hub):**
   - Image'ide salvestus
   - Public registry: hub.docker.com
   - Private registry: oma server

---

### 3.2 Docker Workflow

```bash
# 1. PULL - Lae image Docker Hub'ist
docker pull nginx:1.25-alpine
   ↓
# 2. RUN - Käivita container image'ist
docker run -d -p 80:80 --name webserver nginx:1.25-alpine
   ↓
# 3. Konteiner töötab
   ↓
# 4. STOP - Peata container
docker stop webserver
   ↓
# 5. RM - Kustuta container
docker rm webserver
```

---

## 📦 4. Images vs Containers

### 4.1 Docker Image

**Image** = read-only template, millest luuakse containerid

```bash
# Analoogia:
Image = Klass (programmeerimises)
Container = Objekt (instance)

# Näide:
nginx:1.25-alpine = Image (template)
   ↓
webserver1, webserver2, webserver3 = Containers (instances)
```

**Image layers:**
```
nginx:1.25-alpine image:
+-------------------------+
| Layer 4: CMD (start nginx)
+-------------------------+
| Layer 3: COPY nginx.conf
+-------------------------+
| Layer 2: RUN apk add nginx
+-------------------------+
| Layer 1: FROM alpine:3.19   ← Base image
+-------------------------+
```

**Miks layers?**
- ✅ Reusability (layers shared across images)
- ✅ Efficiency (cache layers)
- ✅ Fast builds

---

### 4.2 Docker Container

**Container** = running instance of an image

```bash
# Loo container image'ist
docker run nginx:1.25-alpine

# Üks image → mitu containerit
docker run --name web1 nginx:1.25-alpine
docker run --name web2 nginx:1.25-alpine
docker run --name web3 nginx:1.25-alpine

# Kõik 3 containerit kasutavad SAMA image'i
# Iga containeril on oma:
- ID
- Nimi
- Protsessid
- Network
- Failisüsteem (writable layer)
```

---

## 🚀 5. Docker Põhikäsud ja Lifecycle

### 5.1 Image'ide Haldamine

**Otsi image'eid:**
```bash
docker search nginx

# Output:
# NAME                DESCRIPTION                     STARS     OFFICIAL
# nginx               Official build of Nginx.        20000+    [OK]
# bitnami/nginx       Bitnami nginx Docker Image      150+
```

**Lae image:**
```bash
# Lae latest tag (default)
docker pull nginx

# Lae konkreetne versioon
docker pull nginx:1.25-alpine

# Lae kõik tag'id (harv)
docker pull --all-tags nginx
```

**Vaata image'eid:**
```bash
docker images

# Output:
# REPOSITORY    TAG           IMAGE ID       CREATED        SIZE
# nginx         1.25-alpine   a64a6e03b055   2 weeks ago    41MB
# postgres      16-alpine     f9b577fb5d74   3 weeks ago    238MB
# node          18-alpine     f9dc63c30bee   1 month ago    174MB
```

**Kustuta image:**
```bash
docker rmi nginx:1.25-alpine

# VÕI ID järgi:
docker rmi a64a6e03b055

# Sunni kustutamine (isegi kui containerid kasutavad):
docker rmi -f nginx:1.25-alpine
```

---

### 5.2 Containerite Haldamine

**Käivita container (interaktiivne):**
```bash
# -it = interactive + TTY (terminal)
docker run -it ubuntu:22.04 bash

# Nüüd oled containeris!
root@abc123:/# ls
root@abc123:/# exit  # Välju
```

**Käivita container (detached):**
```bash
# -d = detached (background)
docker run -d --name webserver nginx:1.25-alpine

# Output: container ID
# 5f3e2b1a9c4d...
```

**Vaata running containereid:**
```bash
docker ps

# Output:
# CONTAINER ID   IMAGE             COMMAND                  STATUS        PORTS     NAMES
# 5f3e2b1a9c4d   nginx:1.25-alpine "/docker-entrypoint.…"   Up 10 sec     80/tcp    webserver
```

**Vaata KÕIKI containereid (ka stopped):**
```bash
docker ps -a

# Output:
# CONTAINER ID   IMAGE             STATUS                     NAMES
# 5f3e2b1a9c4d   nginx:1.25-alpine Up 2 minutes               webserver
# 8a1b3c4d5e6f   ubuntu:22.04      Exited (0) 10 minutes ago  test-ubuntu
```

**Peata container:**
```bash
docker stop webserver

# VÕI ID järgi:
docker stop 5f3e2b1a9c4d

# Timeout (default 10s):
docker stop -t 30 webserver  # Oota 30s enne SIGKILL
```

**Käivita uuesti:**
```bash
docker start webserver
```

**Taaskäivita:**
```bash
docker restart webserver
```

**Kustuta container:**
```bash
# Peab olema stopped!
docker rm webserver

# Sunni kustutamine (isegi kui running):
docker rm -f webserver
```

---

### 5.3 Docker Lifecycle Ülevaade

```
+-------------+
| docker pull |  Lae image Docker Hub'ist
+-------------+
      ↓
+-------------+
| docker run  |  Loo container ja käivita
+-------------+
      ↓
+-------------+
|   Running   |  Container töötab
+-------------+
      ↓
+-------------+
| docker stop |  Peata container (graceful)
+-------------+
      ↓
+-------------+
|   Stopped   |  Container on peatatud (data säilib)
+-------------+
      ↓
+-------------+
| docker rm   |  Kustuta container (data kaob!)
+-------------+
```

---

## 🔌 6. Port Mapping

### 6.1 Miks Port Mapping?

**Probleem:**
```bash
# Container port ≠ Host port
Container: Nginx kuulab port 80
Host: Port 80 võib olla hõivatud

# Kuidas host'ist container'i jõuda?
```

**Lahendus: Port Mapping (-p)**
```
Host            Container
Port 8080  →    Port 80

http://localhost:8080 → Container Nginx:80
```

---

### 6.2 Port Mapping Süntaks

**Baas formaat:**
```bash
docker run -p HOST_PORT:CONTAINER_PORT image

# Näide:
docker run -p 8080:80 nginx:1.25-alpine

# Tähendus:
# Host port 8080 → Container port 80
```

**Näited:**
```bash
# Nginx: Host 80 → Container 80
docker run -d -p 80:80 --name web nginx:1.25-alpine

# PostgreSQL: Host 5432 → Container 5432
docker run -d -p 5432:5432 --name db postgres:16-alpine

# Node.js app: Host 3000 → Container 3000
docker run -d -p 3000:3000 --name api node-app

# Mitu mapping'ut:
docker run -d \
  -p 80:80 \
  -p 443:443 \
  --name web nginx
```

**Dynamic port (random host port):**
```bash
# -P (capital) = publish all exposed ports to random host ports
docker run -d -P nginx:1.25-alpine

# Vaata, millisele portile map'iti:
docker port <container>
```

---

### 6.3 Port Mapping Testimine

```bash
# 1. Käivita Nginx container
docker run -d -p 8080:80 --name webserver nginx:1.25-alpine

# 2. Testi localhost'ist
curl http://localhost:8080

# Output:
# <!DOCTYPE html>
# <html>
# <head><title>Welcome to nginx!</title></head>
# ...

# 3. Testi VPS väljastpoolt (local machine)
curl http://YOUR_VPS_IP:8080

# ⚠️ ENNE testi, veendu et UFW lubab port 8080:
# sudo ufw allow 8080/tcp
```

---

## 💾 7. Volume Mounting (Persistent Data)

### 7.1 Container Filesystem Probleem

**Container filesystem on EPHEMERAL (ajutine):**
```bash
# 1. Käivita PostgreSQL container
docker run -d --name db postgres:16-alpine

# 2. Loo andmebaas ja tabel
docker exec -it db psql -U postgres
CREATE DATABASE mydb;
\c mydb
CREATE TABLE users (id SERIAL, name TEXT);
INSERT INTO users (name) VALUES ('Alice');

# 3. Peata ja kustuta container
docker stop db
docker rm db

# 4. Käivita uus container
docker run -d --name db postgres:16-alpine

# 5. Vaata andmebaasi:
docker exec -it db psql -U postgres -c "\l"

# ❌ mydb puudub! Kõik data on KADUNUD!
```

**Probleem:**
Containerid on _stateless_. Kui container kustutatakse, kaob ka kõik data.

---

### 7.2 Docker Volumes Lahendus

**Volume** = persistent storage, mis elab containerist kauem

```
Host Filesystem          Container Filesystem
/var/lib/docker/volumes/
  pgdata/
    _data/              →   /var/lib/postgresql/data
      (persistent)              (container sees)
```

**Loo volume:**
```bash
docker volume create pgdata

# Vaata volume'e:
docker volume ls

# Output:
# DRIVER    VOLUME NAME
# local     pgdata
```

**Kasuta volume'i:**
```bash
docker run -d \
  --name db \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# -v VOLUME_NAME:CONTAINER_PATH
```

**Testi andmete püsimist:**
```bash
# 1. Loo data
docker exec -it db psql -U postgres -c "CREATE DATABASE mydb;"

# 2. Kustuta container
docker rm -f db

# 3. Käivita UUS container SAMA volume'iga
docker run -d \
  --name db-new \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# 4. Kontrolli data
docker exec -it db-new psql -U postgres -c "\l"

# ✅ mydb on olemas! Data säilis!
```

---

### 7.3 Bind Mounts (Host Directory)

**Bind mount** = mount host directory konteinerisse

```bash
# Mount host /home/user/data → container /data
docker run -d \
  -v /home/user/app:/app \
  node:18-alpine

# Näide: Development workflow
# Muudad faile host'is → Muudatused kohe containeris!
```

**Named volume vs Bind mount:**

| Aspekt | Named Volume | Bind Mount |
|--------|--------------|------------|
| **Asukoht** | Docker haldab | Host path (nt /home/user/data) |
| **Portability** | ✅ Portable | ❌ Hostiga seotud |
| **Performance** | ✅ Optimeeritud | ⚠️ Aeglasem (macOS/Windows) |
| **Kasutus** | Production data | Development (koodi muutmine) |

---

## 🌐 8. Environment Variables

### 8.1 Miks Environment Variables?

**12-Factor App** põhimõte: Configuration comes from environment, not hardcoded.

```javascript
// ❌ VALE - Hardcoded config
const dbHost = "localhost";
const dbPassword = "secret123";

// ✅ ÕIGE - Environment variables
const dbHost = process.env.DB_HOST;
const dbPassword = process.env.DB_PASSWORD;
```

---

### 8.2 Environment Variables Docker'is

**Edasta -e flag'iga:**
```bash
docker run -d \
  --name db \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=secret123 \
  -e POSTGRES_DB=myapp \
  postgres:16-alpine
```

**Edasta --env-file'iga:**
```bash
# Loo .env fail
cat > .env <<EOF
POSTGRES_USER=appuser
POSTGRES_PASSWORD=secret123
POSTGRES_DB=myapp
EOF

# Kasuta .env faili
docker run -d \
  --name db \
  --env-file .env \
  postgres:16-alpine
```

**Vaata container'i environment'i:**
```bash
docker exec db env

# Output:
# PATH=/usr/local/sbin:/usr/local/bin:...
# POSTGRES_USER=appuser
# POSTGRES_PASSWORD=secret123
# POSTGRES_DB=myapp
```

---

## 🌍 9. Docker Networks

### 9.1 Network Tüübid

Docker loob automaatselt 3 network'i:

```bash
docker network ls

# Output:
# NETWORK ID     NAME      DRIVER    SCOPE
# 1a2b3c4d5e6f   bridge    bridge    local   ← Default
# 7g8h9i0j1k2l   host      host      local
# 3m4n5o6p7q8r   none      null      local
```

**Bridge (default):**
- Containerid saavad üksteisega rääkida
- Containerid ühendatud host'iga virtuaalse bridge kaudu
- Kasutatakse enamiku rakenduste puhul

**Host:**
- Container kasutab host'i network stack'i otse
- Ei ole isolatsioon
- Performance boost (network overhead puudub)

**None:**
- Ei ole network'i
- Täielik isolatsioon

---

### 9.2 Container Network Communication

**Loo custom network:**
```bash
docker network create app-network
```

**Käivita containerid samas network'is:**
```bash
# PostgreSQL
docker run -d \
  --name postgres \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  postgres:16-alpine

# Node.js app (saab ühendada "postgres" hostname'i järgi!)
docker run -d \
  --name api \
  --network app-network \
  -e DB_HOST=postgres \
  -e DB_PASSWORD=secret \
  node-app
```

**DNS resolution:**
```bash
# Container "api" sees:
ping postgres  # ✅ Töötab! Docker DNS resolve "postgres" → container IP
```

---

## 🐛 10. Debugging ja Logid

### 10.1 Container Logid

**Vaata logisid:**
```bash
# Kõik logid
docker logs webserver

# Viimased 50 rida
docker logs --tail 50 webserver

# Reaalajas (follow)
docker logs -f webserver

# Ajatemplitega
docker logs -t webserver

# Kombinatsioon:
docker logs --tail 100 -f webserver
```

---

### 10.2 Exec - Containerisse Sisenemine

**Käivita käsk containeris:**
```bash
# Bash shell
docker exec -it webserver bash

# VÕI sh (Alpine image'itel bash puudub)
docker exec -it webserver sh

# Üks käsk (ilma shell'ita)
docker exec webserver ls -la /usr/share/nginx/html
```

**Näide: PostgreSQL debug:**
```bash
# Logi psql'i containeris
docker exec -it postgres psql -U postgres

# Käivita SQL
\l  # List databases
\dt # List tables
SELECT * FROM users;
```

---

### 10.3 Container Inspect

**Vaata container'i detailset infot:**
```bash
docker inspect webserver

# JSON output (lai)
```

**Filtreeri väljund:**
```bash
# IP aadress
docker inspect -f '{{.NetworkSettings.IPAddress}}' webserver

# Env variables
docker inspect -f '{{.Config.Env}}' webserver

# Mounts
docker inspect -f '{{.Mounts}}' webserver
```

---

### 10.4 Stats - Resource Kasutus

**Vaata container'i resource kasutust:**
```bash
docker stats

# Output (reaalajas):
# CONTAINER ID   NAME    CPU %   MEM USAGE / LIMIT    MEM %    NET I/O
# 5f3e2b1a9c4d   web     0.05%   12.5MiB / 7.8GiB     0.16%    1.2kB / 0B
# 8a1b3c4d5e6f   db      0.50%   45.2MiB / 7.8GiB     0.58%    5.4kB / 2.1kB
```

**Üks container:**
```bash
docker stats webserver
```

---

## 📝 11. Praktilised Harjutused

### Harjutus 1: Esimene Docker Container (20 min)

**Eesmärk:** Käivita Nginx veebiserver Docker'is

**Sammud:**
```bash
# 1. Lae Nginx image
docker pull nginx:1.25-alpine

# 2. Käivita container
docker run -d -p 8080:80 --name my-nginx nginx:1.25-alpine

# 3. Testi browser'is või curl'iga
curl http://localhost:8080

# 4. Vaata logisid
docker logs my-nginx

# 5. Peata ja käivita uuesti
docker stop my-nginx
docker start my-nginx

# 6. Sisene containerisse
docker exec -it my-nginx sh
ls /usr/share/nginx/html
cat /etc/nginx/nginx.conf
exit

# 7. Kustuta
docker rm -f my-nginx
```

**Kontrolli:**
- [ ] Nginx container käivitub
- [ ] Saad ligi http://localhost:8080
- [ ] Oskad vaadata logisid
- [ ] Oskad containerisse siseneda

---

### Harjutus 2: PostgreSQL Persistent Data (30 min)

**Eesmärk:** Õpi volume'ite kasutamist andmete säilitamiseks

**Sammud:**
```bash
# 1. Loo volume
docker volume create pgdata

# 2. Käivita PostgreSQL volume'iga
docker run -d \
  --name postgres \
  -e POSTGRES_PASSWORD=mysecret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# 3. Loo andmebaas ja tabel
docker exec -it postgres psql -U postgres <<EOF
CREATE DATABASE testdb;
\c testdb
CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT);
INSERT INTO users (name) VALUES ('Alice'), ('Bob'), ('Charlie');
SELECT * FROM users;
EOF

# 4. Kustuta container (aga mitte volume!)
docker rm -f postgres

# 5. Käivita UUS container SAMA volume'iga
docker run -d \
  --name postgres-new \
  -e POSTGRES_PASSWORD=mysecret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16-alpine

# 6. Kontrolli, et data säilis
docker exec -it postgres-new psql -U postgres -d testdb -c "SELECT * FROM users;"

# Output peaks näitama Alice, Bob, Charlie ✅
```

**Kontrolli:**
- [ ] Volume on loodud
- [ ] Data säilib pärast container'i kustutamist
- [ ] Uus container näeb vana data

---

### Harjutus 3: Multi-Container Network (40 min)

**Eesmärk:** Ühenda kaks containerit custom network'i kaudu

**Sammud:**
```bash
# 1. Loo custom network
docker network create myapp-network

# 2. Käivita PostgreSQL
docker run -d \
  --name db \
  --network myapp-network \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=myapp \
  postgres:16-alpine

# 3. Käivita Node.js container, mis ühendub "db" hostname'iga
docker run -d \
  --name api \
  --network myapp-network \
  -p 3000:3000 \
  -e DB_HOST=db \
  -e DB_PORT=5432 \
  -e DB_USER=appuser \
  -e DB_PASSWORD=secret \
  -e DB_NAME=myapp \
  node:18-alpine \
  sh -c "while true; do echo 'API running'; sleep 10; done"

# 4. Test network connectivity
docker exec api ping -c 3 db

# 5. Vaata network'i detaile
docker network inspect myapp-network
```

**Kontrolli:**
- [ ] Mõlemad containerid on samas network'is
- [ ] "api" saab ping'ida "db"
- [ ] DNS resolution töötab (db hostname)

---

### Harjutus 4: Environment Variables ja Debugging (30 min)

**Eesmärk:** Õpi env variables ja debugging'u

**Sammud:**
```bash
# 1. Loo .env fail
cat > app.env <<EOF
NODE_ENV=production
PORT=3000
DB_HOST=database.example.com
DB_PORT=5432
API_KEY=secret-api-key-12345
EOF

# 2. Käivita container env file'iga
docker run -d \
  --name envtest \
  --env-file app.env \
  node:18-alpine \
  sh -c "env; sleep 3600"

# 3. Vaata env variables
docker exec envtest env | grep NODE_ENV

# 4. Inspect container
docker inspect envtest | grep -A 10 "Env"

# 5. Vaata resource kasutust
docker stats envtest --no-stream

# 6. Vaata logisid
docker logs envtest
```

**Kontrolli:**
- [ ] Env variables on edastatud
- [ ] Oskad neid vaadata (exec env, inspect)
- [ ] Oskad resource kasutust monitoorida

---

### Harjutus 5: Cleanup (15 min)

**Eesmärk:** Õpi puhastama containereid, image'eid, volume'e

**Sammud:**
```bash
# 1. Peata KÕIK running containerid
docker stop $(docker ps -q)

# 2. Kustuta KÕIK containerid
docker rm $(docker ps -a -q)

# 3. Kustuta kasutamata image'id
docker image prune -a

# 4. Kustuta kasutamata volume'id
docker volume prune

# 5. Kustuta kasutamata network'id
docker network prune

# 6. Kustuta KÕIK (OHTLIK!)
docker system prune -a --volumes

# ⚠️ Confirmation: Are you sure? YES
```

**Kontrolli:**
- [ ] Kõik containerid on kustutatud
- [ ] Kasutamata image'id on kustutatud
- [ ] Kasutamata volume'id on kustutatud

---

## 🎓 12. Mida Sa Õppisid?

### Omandatud Teadmised

✅ **Kontseptsioonid:**
- Konteinerite vs VM'ide erinevused
- Docker arhitektuur (client, daemon, registry)
- Image vs Container
- Ephemeral vs Persistent storage

✅ **Docker Lifecycle:**
- docker pull - image'ide allalaadimine
- docker run - containerite käivitamine
- docker stop/start - seiskamine/käivitamine
- docker rm - kustutamine

✅ **Port Mapping:**
- -p HOST:CONTAINER süntaks
- Portide publish'imine
- Network isolation

✅ **Volumes:**
- Named volumes (docker volume create)
- Bind mounts (host directory)
- Data persistence
- Volume lifecycle

✅ **Environment Variables:**
- -e flag
- --env-file
- 12-Factor App configuration

✅ **Networks:**
- Bridge network (default)
- Custom networks
- Container DNS resolution
- Container-to-container communication

✅ **Debugging:**
- docker logs
- docker exec
- docker inspect
- docker stats

---

## 🚀 13. Järgmised Sammud

**Peatükk 5: Dockerfile ja Rakenduste Konteineriseerimise Detailid** 📦
- Dockerfile süntaks ja best practices
- Node.js rakenduste konteineriseerimise detailid
- Java/Spring Boot konteineriseerimise detailid
- Multi-stage builds
- Image optimiseerimine
- **SIIN ÕPIME, KUIDAS OMA RAKENDUSI KONTEINERISEERIDA!**

**Labid:**
- **Lab 1: Docker Basics** - Containerite haldamine, volumes, networks
- **Lab 2: Docker Compose** - Multi-container rakendused

---

## 📖 14. Lisaressursid

**Dokumentatsioon:**
- [Docker Official Docs](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

**Labid:**
- `labs/01-docker-lab/` - Hands-on Docker exercises
- `labs/apps/backend-nodejs/` - Sample Node.js app containerization

**Järgmised peatükid:**
- Peatükk 5: Dockerfile ja Image Loomine
- Peatükk 6: PostgreSQL Konteinerites
- Peatükk 7: Docker Compose

---

## ✅ Kontrolli Ennast

Enne järgmisele peatükile liikumist, veendu et:

- [ ] Mõistad konteinerite eeliseid VM'ide ees
- [ ] Oskad Docker image'eid laadida ja hallata
- [ ] Oskad containereid käivitada, peatada, kustutada
- [ ] Mõistad port mapping'u (-p)
- [ ] Oskad kasutada volume'eid (-v)
- [ ] Oskad edastada environment variables (-e)
- [ ] Mõistad Docker network'e
- [ ] Oskad containereid debuggida (logs, exec, inspect)
- [ ] Oled läbinud kõik 5 praktilist harjutust

**Kui kõik on ✅, oled valmis Peatükiks 5!** 🚀

---

**Peatükk 4 lõpp**
**Järgmine:** Peatükk 5 - Dockerfile ja Rakenduste Konteineriseerimise Detailid

**Õnnitleme!** Oled nüüd konteinerisatsiooni maailmas! 🐳
