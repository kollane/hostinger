# Peatükk 12: Docker Põhimõtted

**Kestus:** 4 tundi
**Eeldused:** Peatükid 1-11 läbitud
**Eesmärk:** Õppida Dockeri põhitõed ja konteinerite haldamine

---

## Sisukord

1. [Mis on Docker?](#1-mis-on-docker)
2. [Docker Arhitektuur](#2-docker-arhitektuur)
3. [Docker Paigaldamine](#3-docker-paigaldamine)
4. [Images vs Containers](#4-images-vs-containers)
5. [Docker Images](#5-docker-images)
6. [Docker Containers](#6-docker-containers)
7. [Dockerfile](#7-dockerfile)
8. [Docker Build](#8-docker-build)
9. [Docker Volumes](#9-docker-volumes)
10. [Docker Networks](#10-docker-networks)
11. [Container Lifecycle](#11-container-lifecycle)
12. [Docker Hub](#12-docker-hub)
13. [Best Practices](#13-best-practices)
14. [Harjutused](#14-harjutused)

---

## 1. Mis on Docker?

### 1.1. Definitsioon

**Docker** on konteineriseerimise platvorm, mis võimaldab rakendusi ja nende sõltuvusi pakendada standardsesse konteinerisse.

**Probleemid, mida Docker lahendab:**
- "Works on my machine" - rakendus töötab arendaja masinas, aga mitte serveris
- Sõltuvuste konflikid (erinevad Node.js versioonid, lib'id)
- Aeganõudev keskkonna seadistamine
- Ebaühtlane deploy erinevates keskkondades

---

### 1.2. Docker vs Virtual Machines

```
Virtual Machines:                  Docker Containers:
┌────────────────────┐            ┌────────────────────┐
│   App A   App B    │            │   App A   App B    │
│  ┌────┐  ┌────┐    │            │  ┌────┐  ┌────┐    │
│  │Libs│  │Libs│    │            │  │Libs│  │Libs│    │
│  └────┘  └────┘    │            │  └────┘  └────┘    │
│  Guest OS  Guest OS│            │   Docker Engine    │
├────────────────────┤            ├────────────────────┤
│    Hypervisor      │            │     Host OS        │
├────────────────────┤            └────────────────────┘
│     Host OS        │
└────────────────────┘

Heavy (~GB each)                  Lightweight (~MB each)
Slow startup (minutes)            Fast startup (seconds)
```

---

### 1.3. Docker Eelised

✅ **Portable:** Töötab igal pool (dev, test, prod)
✅ **Lightweight:** Ei vaja täielikku OS-i
✅ **Fast:** Käivitub sekundite jooksul
✅ **Scalable:** Hõlbus skaleerida (mitmed containerid)
✅ **Isolated:** Iga container on isoleeritud
✅ **Version Control:** Images on versioonitavad

---

## 2. Docker Arhitektuur

### 2.1. Docker Komponendid

```
┌─────────────────────────────────────────────┐
│          Docker Client (CLI)                │
│            docker run, build...             │
└─────────────┬───────────────────────────────┘
              │ REST API
              ▼
┌─────────────────────────────────────────────┐
│          Docker Daemon (dockerd)            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │Container │  │Container │  │Container │  │
│  │    1     │  │    2     │  │    3     │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │         Images (local)               │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│          Docker Registry (Docker Hub)       │
│         Public/Private Image Storage        │
└─────────────────────────────────────────────┘
```

**Komponendid:**
- **Docker Client:** CLI, mida kasutame käskude andmiseks
- **Docker Daemon:** Teenus, mis haldab containereid
- **Docker Images:** Read-only templates containerite jaoks
- **Docker Containers:** Töötavad instantsid image'itest
- **Docker Registry:** Image'ite storage (Docker Hub, Private Registry)

---

## 3. Docker Paigaldamine

### 3.1. Paigaldamine Zorin OS / Ubuntu

```bash
# Uuenda süsteemi
sudo apt update
sudo apt upgrade -y

# Eemalda vanad versioonid (kui on)
sudo apt remove docker docker-engine docker.io containerd runc

# Paigalda sõltuvused
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Lisa Docker GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Lisa Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Paigalda Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Kontrolli versiooni
docker --version
# Output: Docker version 24.0.7, build afdd53b
```

---

### 3.2. Docker Ilma sudo-ta

```bash
# Lisa oma kasutaja docker gruppi
sudo usermod -aG docker $USER

# Logi välja ja tagasi (või reboot)
# Või käivita uus shell:
newgrp docker

# Testi
docker run hello-world
```

---

### 3.3. Docker Daemon Käivitamine

```bash
# Käivita Docker teenus
sudo systemctl start docker

# Luba autostart
sudo systemctl enable docker

# Kontrolli staatust
sudo systemctl status docker

# Output peaks olema "active (running)"
```

---

## 4. Images vs Containers

### 4.1. Docker Image

**Image** = Read-only template, mis sisaldab:
- OS (base layer)
- Rakenduse koodi
- Sõltuvusi (dependencies)
- Konfiguratsiooni

```
┌─────────────────────┐
│   Your App Code     │  ← Layer 4
├─────────────────────┤
│   npm install       │  ← Layer 3
├─────────────────────┤
│   Node.js 18        │  ← Layer 2
├─────────────────────┤
│   Ubuntu 22.04      │  ← Layer 1 (Base)
└─────────────────────┘
```

---

### 4.2. Docker Container

**Container** = Töötav instantsi image'ist

```
Image (Template)        Container (Running Instance)
┌──────────────┐        ┌──────────────┐
│ node:18      │  ───>  │ Container 1  │ (Running)
│              │        ├──────────────┤
│ Ubuntu       │  ───>  │ Container 2  │ (Running)
│ Node.js      │        ├──────────────┤
│ App Code     │  ───>  │ Container 3  │ (Stopped)
└──────────────┘        └──────────────┘

1 Image → Many Containers
```

---

## 5. Docker Images

### 5.1. Image'ite Otsimine

```bash
# Otsi Docker Hub'ist
docker search node

# Output:
# NAME                DESCRIPTION                     STARS
# node                Node.js is a JavaScript ...     13000+
# node-alpine         Minimal Node.js image           500+
```

---

### 5.2. Image'ite Allalaadimine

```bash
# Pull (lae alla) image
docker pull node:18

# Pull konkreetne versioon
docker pull node:18-alpine

# Pull PostgreSQL
docker pull postgres:15

# Kontrolli lokaalseid image'id
docker images

# Output:
# REPOSITORY   TAG          IMAGE ID       CREATED       SIZE
# node         18           a1b2c3d4e5f6   2 days ago    1.1GB
# node         18-alpine    b2c3d4e5f6a7   2 days ago    180MB
# postgres     15           c3d4e5f6a7b8   1 week ago    379MB
```

---

### 5.3. Image'ite Kustutamine

```bash
# Kustuta image
docker rmi node:18

# Kustuta kõik kasutamata image'd
docker image prune

# Kustuta kõik image'd (force)
docker rmi $(docker images -q) -f
```

---

## 6. Docker Containers

### 6.1. Container'i Käivitamine

```bash
# Käivita container interaktiivses režiimis
docker run -it node:18 /bin/bash

# Selgitus:
# -i  = interactive (keep STDIN open)
# -t  = terminal (allocate pseudo-TTY)
# /bin/bash = käsk, mis käivitatakse

# Container'is:
node --version
# v18.19.0

exit  # Välja
```

---

### 6.2. Container Detached Režiimis

```bash
# Käivita taustal (detached)
docker run -d --name my-node-app node:18 sleep infinity

# Selgitus:
# -d         = detached (taustal)
# --name     = anna nimi containerile
# sleep infinity = hoia container töötamas

# Kontrolli töötavaid containereid
docker ps

# Output:
# CONTAINER ID   IMAGE      COMMAND            STATUS
# a1b2c3d4e5f6   node:18    "sleep infinity"   Up 10 seconds
```

---

### 6.3. Container'i Peatamine ja Käivitamine

```bash
# Peata container
docker stop my-node-app

# Käivita uuesti
docker start my-node-app

# Restart
docker restart my-node-app

# Kustuta container
docker rm my-node-app

# Force kustutamine (ka töötav)
docker rm -f my-node-app
```

---

### 6.4. Container'i Sees Käskude Käivitamine

```bash
# Käivita käsk töötavas container'is
docker exec my-node-app node --version

# Ava shell töötavas container'is
docker exec -it my-node-app /bin/bash

# Container'is:
ls
pwd
exit
```

---

### 6.5. Container Logid

```bash
# Vaata container logisid
docker logs my-node-app

# Follow logs (real-time)
docker logs -f my-node-app

# Viimased 100 rida
docker logs --tail 100 my-node-app
```

---

## 7. Dockerfile

### 7.1. Mis on Dockerfile?

**Dockerfile** = Tekstifail, mis sisaldab instruktioone Docker image'i loomiseks.

---

### 7.2. Lihtne Dockerfile

**Dockerfile:**
```dockerfile
# Base image
FROM node:18-alpine

# Töökaust container'is
WORKDIR /app

# Kopeeri package files
COPY package*.json ./

# Paigalda dependencies
RUN npm install

# Kopeeri rakenduse kood
COPY . .

# Port, mida rakendus kasutab
EXPOSE 3000

# Käivitamise käsk
CMD ["node", "server.js"]
```

---

### 7.3. Dockerfile Instruktsioonid

### Baaspilt ja efektiivsus
Selline Dockerfile on üles ehitatud kindla loogikaga, et hoida konteineri ehitamine puhtana, tõhusana ja hõlpsasti hooldatavana. Allpool on iga sammu põhjendus ja miks neid just nii tehakse.

Valitakse **node:18-alpine** baaspilt, kuna see on väikese mahuga ja sisaldab vaid olulist Node.js'i käitamiseks. Vähem installitud pakette tähendab väiksemat pinda, turvalisemat konteinerit ja kiirem ehitamine.

### Töökataloogi määramine

Käsuga `WORKDIR /app` liigub töökeskkond soovitud kataloogi. Kõik järgnevad käsud täidetakse selles kataloogis, mis aitab hoida projekti failid struktureeritult ja väldib segadust erinevate failide asukohtadega.

### Package failide esmalt kopeerimine

`COPY package*.json ./` kopeerib ainult package.json ja package-lock.json (või yarn.lock) enne kogu rakenduskoodi kopeerimist. See annab võimaluse järgmises etapis (`RUN npm install`) paigaldada npm-i sõltuvused enne koodifailide lisamist. Nii salvestab Docker ehitusprotsessi vahemälusse ja kui sõltuvused pole muutunud, ei pea iga muudatuse puhul uuesti installima, mis kiirendab ehitamist.

### Sõltuvuste installimine

`RUN npm install` paigaldab vajalikud Node.js'i moodulid. Kuna package failid on eraldi kopeeritud, võetakse see pilt tavaliselt vahemälust — kiire ja efektiivne.

### Rakenduse koodi kopeerimine

Nüüd alles kopeeritakse kogu ülejäänud kood (`COPY . .`). Nii saab sõltuvused installida võimalikult vara ja koodimuudatused ei põhjusta npm installi iga ehitusega.

### Pordi avalikustamine

`EXPOSE 3000` väljendab, millist porti rakendus konteineris kasutab, et arendaja teaks, millega ühendada või kuhu pöörata liiklus.

### Käivituskäsk

`CMD ["node", "server.js"]` määrab, millise käsuga konteiner käivitub; siin alustatakse Node.js serverit.

***

Selline järjekord ja tööviis aitab tagada kiire ehituse, korras failisüsteemi ning väikse pildi suuruse. Häid põhjusi on nii kiiruses, turvalisuses kui ka praktilises konteinerite halduses.

***

---

### 7.4. Node.js Rakenduse Dockerfile

**backend/Dockerfile:**
```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Kopeeri package files
COPY package*.json ./

# Paigalda dependencies
RUN npm ci --only=production

# Stage 2: Production
FROM node:18-alpine

WORKDIR /app

# Kopeeri node_modules from builder
COPY --from=builder /app/node_modules ./node_modules

# Kopeeri rakenduse kood
COPY . .

# Loo non-root kasutaja
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Muuda omanikku
RUN chown -R nodejs:nodejs /app

# Kasuta non-root kasutajat
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Käivita rakendus
CMD ["node", "server.js"]
```

---

### 7.5. .dockerignore

**.dockerignore:**
```
node_modules
npm-debug.log
.env
.git
.gitignore
README.md
.vscode
.idea
coverage
.nyc_output
*.log
```

---

## 8. Docker Build

### 8.1. Image'i Ehitamine

```bash
# Build image Dockerfile'ist
cd backend
docker build -t my-node-app:1.0 .

# Selgitus:
# -t          = tag (nimi:versioon)
# .           = build context (praegune kaust)

# Output:
# [+] Building 45.3s (12/12) FINISHED
# => [internal] load build definition
# => [internal] load .dockerignore
# => [1/5] FROM docker.io/library/node:18-alpine
# => [2/5] WORKDIR /app
# => [3/5] COPY package*.json ./
# => [4/5] RUN npm install
# => [5/5] COPY . .
# => exporting to image
# => => writing image sha256:a1b2c3...
# => => naming to docker.io/library/my-node-app:1.0
```

---

### 8.2. Build Cache

Docker kasutab layer cache'i:

```dockerfile
# ✅ ÕIGE (cache-friendly):
COPY package*.json ./
RUN npm install
COPY . .

# ❌ VALE (cache inefficient):
COPY . .
RUN npm install
```

Miks? Kui muudad koodi, ei pea npm install uuesti käivitama (cache'ist).

---

### 8.3. Multi-Stage Build

```dockerfile
# Build stage
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
CMD ["node", "dist/server.js"]
```

**Eelised:**
- Väiksem final image (ei sisalda build tool'e)
- Turvalisem (vähem attack surface)

---

## 9. Docker Volumes

### 9.1. Mis on Volumes?

**Volume** = Persistent storage container'ile.

**Probleem ilma volumes'ta:**
```bash
docker run postgres:15
# Container loob andmebaasi
docker stop postgres
docker rm postgres
# ❌ Andmed KADUVAD!
```

**Lahendus - Volume:**
```bash
docker run -v postgres-data:/var/lib/postgresql/data postgres:15
# Andmed salvestatakse host'i volume'i
docker stop postgres
docker rm postgres
docker run -v postgres-data:/var/lib/postgresql/data postgres:15
# ✅ Andmed SÄILIVAD!
```

---

### 9.2. Volume Tüübid

**1. Named Volume (soovitav):**
```bash
docker run -v my-volume:/app/data my-app
```

**2. Host Path (bind mount):**
```bash
docker run -v /host/path:/container/path my-app
```

**3. Anonymous Volume:**
```bash
docker run -v /app/data my-app
```

---

### 9.3. Volume Käsud

```bash
# Loo volume
docker volume create postgres-data

# Listita volumes
docker volume ls

# Inspekteeri volume
docker volume inspect postgres-data

# Output:
# [
#     {
#         "Name": "postgres-data",
#         "Driver": "local",
#         "Mountpoint": "/var/lib/docker/volumes/postgres-data/_data"
#     }
# ]

# Kustuta volume
docker volume rm postgres-data

# Kustuta kasutamata volumes
docker volume prune
```

---

### 9.4. PostgreSQL Volume Näide

```bash
# Käivita PostgreSQL volume'iga
docker run -d \
  --name postgres \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypass \
  -e POSTGRES_DB=mydb \
  -v postgres-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15

# Testi
docker exec -it postgres psql -U myuser -d mydb

# Loo tabel
CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT);
INSERT INTO users (name) VALUES ('Alice');

# Välja
\q

# Kustuta container (volume jääb!)
docker stop postgres
docker rm postgres

# Käivita uuesti
docker run -d \
  --name postgres \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypass \
  -e POSTGRES_DB=mydb \
  -v postgres-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15

# Kontrolli andmeid
docker exec -it postgres psql -U myuser -d mydb -c "SELECT * FROM users;"

# Output:
#  id | name
# ----+-------
#   1 | Alice
# (1 row)
```

---

## 10. Docker Networks

### 10.1. Network Tüübid

**1. Bridge (default):**
- Isoleeritud network
- Container'id saavad omavahel rääkida

**2. Host:**
- Kasutab host masina network'i
- Ei ole isoleeritud

**3. None:**
- Ei ole network'i
- Täielikult isoleeritud

---

### 10.2. Network Käsud

```bash
# Loo network
docker network create my-network

# Listita networks
docker network ls

# Inspekteeri network
docker network inspect my-network

# Kustuta network
docker network rm my-network
```

---

### 10.3. Container'id Samas Network'is

```bash
# Loo network
docker network create app-network

# Käivita PostgreSQL
docker run -d \
  --name postgres \
  --network app-network \
  -e POSTGRES_PASSWORD=mypass \
  postgres:15

# Käivita Node.js app
docker run -d \
  --name node-app \
  --network app-network \
  -e DATABASE_URL=postgresql://postgres:mypass@postgres:5432/postgres \
  my-node-app:1.0

# Node.js app saab ühenduda PostgreSQL'iga hostname'iga "postgres"
```

---

## 11. Container Lifecycle

### 11.1. Container'i Elutsükkel

```
   docker run
      ↓
┌─────────────┐
│   CREATED   │
└──────┬──────┘
       │ docker start
       ↓
┌─────────────┐
│   RUNNING   │ ←─── docker restart
└──────┬──────┘
       │ docker stop
       ↓
┌─────────────┐
│   STOPPED   │
└──────┬──────┘
       │ docker rm
       ↓
┌─────────────┐
│   DELETED   │
└─────────────┘
```

---

### 11.2. Container Staatused

```bash
# Vaata kõiki containereid (ka peatatud)
docker ps -a

# Output:
# CONTAINER ID   STATUS
# a1b2c3d4e5f6   Up 2 hours          # RUNNING
# b2c3d4e5f6a7   Exited (0) 1 hour   # STOPPED
# c3d4e5f6a7b8   Created             # CREATED

# Filtreeri staatuse järgi
docker ps -f "status=running"
docker ps -f "status=exited"
```

---

### 11.3. Container Stats

```bash
# Vaata container'ite ressursikasutust
docker stats

# Output:
# CONTAINER ID   CPU %   MEM USAGE / LIMIT   MEM %   NET I/O
# a1b2c3d4e5f6   0.50%   50MB / 8GB          0.62%   1.2kB / 0B

# Konkreetse container stats
docker stats my-node-app
```

---

### 11.4. Container Inspect

```bash
# Vaata container'i detailset infot
docker inspect my-node-app

# Output: JSON (IP address, volumes, env vars, jne)

# Get IP address
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-node-app
```

---

## 12. Docker Hub

### 12.1. Docker Hub Registry

**Docker Hub** = Avalik registry Docker image'ite jaoks.

URL: https://hub.docker.com

---

### 12.2. Login Docker Hub'i

```bash
# Login
docker login

# Sisesta username ja password

# Logout
docker logout
```

---

### 12.3. Push Image'i Docker Hub'i

```bash
# Tag image with your username
docker tag my-node-app:1.0 username/my-node-app:1.0

# Push
docker push username/my-node-app:1.0

# Teised saavad nüüd alla laadida:
docker pull username/my-node-app:1.0
```

---

### 12.4. Private Registry

```bash
# Käivita lokaalne registry
docker run -d -p 5000:5000 --name registry registry:2

# Tag image
docker tag my-node-app:1.0 localhost:5000/my-node-app:1.0

# Push
docker push localhost:5000/my-node-app:1.0

# Pull
docker pull localhost:5000/my-node-app:1.0
```

---

## 13. Best Practices

### 13.1. Dockerfile Best Practices

✅ **Kasuta väikeseid base image'id:**
```dockerfile
# ✅ Alpine (180MB)
FROM node:18-alpine

# ❌ Full (1.1GB)
FROM node:18
```

✅ **Multi-stage builds:**
```dockerfile
FROM node:18 AS build
# ... build steps ...

FROM node:18-alpine
COPY --from=build /app/dist ./dist
```

✅ **Kasuta .dockerignore:**
```
node_modules
.git
.env
```

✅ **Non-root kasutaja:**
```dockerfile
USER nodejs
```

✅ **Specific versions:**
```dockerfile
# ✅ Specific
FROM node:18.19.0-alpine

# ❌ Generic
FROM node:latest
```

---

### 13.2. Security Best Practices

✅ **Scan image'id:**
```bash
docker scan my-node-app:1.0
```

✅ **Ära salvesta secrets image'sse:**
```dockerfile
# ❌ VALE
ENV DATABASE_PASSWORD=secret123

# ✅ ÕIGE (kasuta runtime env vars)
docker run -e DATABASE_PASSWORD=secret123 my-app
```

✅ **Read-only filesystem:**
```bash
docker run --read-only my-app
```

---

### 13.3. Performance Best Practices

✅ **Layer cache:**
```dockerfile
# Kopeeri package.json enne koodi
COPY package*.json ./
RUN npm install
COPY . .
```

✅ **Combine RUN statements:**
```dockerfile
# ✅ ÕIGE (1 layer)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# ❌ VALE (3 layers)
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*
```

✅ **Minimize image size:**
```dockerfile
# Kustuta cache ja temp files
RUN npm ci --only=production && npm cache clean --force
```

---

## 14. Harjutused

### Harjutus 12.1: Docker Paigaldamine
1. Paigalda Docker Zorin OS'i
2. Lisa kasutaja docker gruppi
3. Testi `docker run hello-world`

### Harjutus 12.2: Node.js Container
1. Loo Dockerfile Node.js rakendusele
2. Build image
3. Käivita container ja testi

### Harjutus 12.3: PostgreSQL Volume
1. Käivita PostgreSQL container volume'iga
2. Loo tabel ja lisa andmeid
3. Kustuta container ja taasta andmed uuest container'ist

### Harjutus 12.4: Multi-Container Network
1. Loo custom network
2. Käivita PostgreSQL ja Node.js app samas network'is
3. Testi ühenduvust

### Harjutus 12.5: Docker Hub
1. Loo Docker Hub konto
2. Push oma image Docker Hub'i
3. Pull image teisest masinast

---

## Quiz

**1. Mis on Docker image?**
- a) Töötav container
- b) Read-only template container'ite jaoks
- c) Virtual machine
- d) Network

<details>
<summary>Vastus</summary>
b) Docker image on read-only template, mis sisaldab OS, koodi ja sõltuvusi
</details>

---

**2. Kuidas käivitada container taustal?**
- a) docker run my-app
- b) docker run -d my-app
- c) docker run -it my-app
- d) docker start my-app

<details>
<summary>Vastus</summary>
b) -d flag (detached) käivitab container'i taustal
</details>

---

**3. Mis on volume?**
- a) Network
- b) Persistent storage container'ile
- c) CPU limit
- d) Memory limit

<details>
<summary>Vastus</summary>
b) Volume on persistent storage, mis säilib ka pärast container'i kustutamist
</details>

---

**4. Mis käsk ehitab Docker image'i?**
- a) docker create
- b) docker make
- c) docker build
- d) docker run

<details>
<summary>Vastus</summary>
c) docker build -t name:tag .
</details>

---

**5. Miks kasutada multi-stage build?**
- a) Kiirem build
- b) Väiksem final image
- c) Rohkem cache
- d) Rohkem layers

<details>
<summary>Vastus</summary>
b) Multi-stage build jätab build tool'id final image'ist välja, tehes selle väiksemaks
</details>

---

## Kokkuvõte

Selles peatükis õppisid:

✅ **Docker Põhimõtted:**
- Mis on Docker ja miks seda kasutada
- Images vs Containers
- Docker arhitektuur

✅ **Docker Paigaldamine:**
- Docker install Zorin OS / Ubuntu
- Docker daemon seadistamine
- Kasutaja õigused

✅ **Images ja Containers:**
- Image'ite allalaadimine ja haldamine
- Container'ite käivitamine ja haldamine
- Container lifecycle

✅ **Dockerfile:**
- Dockerfile kirjutamine
- Image'i ehitamine
- Multi-stage builds
- Best practices

✅ **Volumes ja Networks:**
- Persistent storage
- Container'ite omavaheline suhtlus
- Network'ide loomine

✅ **Docker Hub:**
- Image'ite push/pull
- Private registry

---

**Järgmine peatükk:** Docker Compose - multi-container rakenduste haldamine

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
