# Peatükk 6: Dockerfile ja Rakenduste Konteineriseerimise Detailid

## Õpieesmärgid

Peale selle peatüki läbimist oskad:
- ✅ Kirjutada Dockerfile'i rakenduse konteineriseerimiseks
- ✅ Mõista ja kasutada Dockerfile peamisi instruktsioone (FROM, RUN, COPY, CMD, ENTRYPOINT jne)
- ✅ Luua multi-stage builds rakenduste optimeerimiseks
- ✅ Valida sobivat base image'i (Alpine vs Debian vs Distroless)
- ✅ Optimeerida image layer'ite caching'u
- ✅ Rakendada security best practices (non-root users, minimal images)
- ✅ Kasutada .dockerignore faili

## Põhimõisted

- **Dockerfile:** Tekstifail, mis sisaldab järjestikusid instruktsioone Docker image'i ehitamiseks. Iga instruktsioon loob uue layer'i.
- **Build context:** Kataloog, mille sisu saadetakse Docker daemon'ile image ehitamise ajal (tavaliselt juurkataloog, kus Dockerfile asub).
- **Layer (kiht):** Dockerfile'i iga instruktsioon (FROM, RUN, COPY) loob uue read-only layer'i. Layer'd on cacheable.
- **Base image:** Lähtepilt, millele image ehitatakse (FROM instruktsioon). Näiteks `ubuntu:22.04`, `node:18-alpine`.
- **Multi-stage build:** Dockerfile mitme FROM instruktsiooni kasutamine, et ehitada vahepeal ja kopeerida ainult vajalik lõplikku image'isse.
- **.dockerignore:** Fail, mis määrab, milliseid faile/katalooge EI kopeerita build context'i (sarnane .gitignore'ile).
- **Entrypoint:** Peamine käsk, mis käivitatakse konteineri startimisel. Ei ole lihtne override'ida.
- **CMD:** Default argumendid ENTRYPOINT'ile või default käsk, kui ENTRYPOINT puudub. Lihtne override'ida.

## Teooria

### Dockerfile Struktuur ja Põhimõtted

Dockerfile on lihtne tekstifail nimega `Dockerfile` (pole file extension'it). See sisaldab instruktsioone, mida Docker Engine täidab järjest iga image'i ehitamisel.

**Põhiline struktuur:**

```dockerfile
# Kommentaar: Alusta base image'iga
FROM base-image:tag

# Metadata
LABEL maintainer="yourname@example.com"

# Töökataloog
WORKDIR /app

# Kopeeri failid
COPY package.json .
COPY src/ ./src/

# Käivita käsud (install dependencies)
RUN npm install --production

# Environment variables
ENV NODE_ENV=production

# Expose port
EXPOSE 3000

# Määra non-root user
USER node

# Peamine käsk konteineri käivitamiseks
CMD ["node", "src/server.js"]
```

**Oluline:** Iga instruktsioon loob **uue layer'i**. Layer'd on cacheable, mis tähendab, et kui muudad Dockerfile'i viimast rida, pole vaja rebuild'ida kogu image'i - eelnevad layer'd tuleb cache'ist.

### Dockerfile Põhilised Instruktsoonid

#### FROM - Base Image

**Mis see teeb lihtsustatult?**

FROM valib "aluse" (base image), millele sinu rakendus ehitatakse. See on nagu operatsioonisüsteem + vajalikud tööriistad (Node.js, Python, Java jne) juba paigaldatud.

**Näide:** `FROM node:18-alpine` annab sulle Alpine Linux + Node.js 18 valmis paigaldatud.

---

**Süntaks:** `FROM <image>[:<tag>] [AS <name>]`

FROM määrab base image'i, millele su image ehitatakse. **Iga Dockerfile peab algama FROM'iga** (va multi-stage build'id).

```dockerfile
# Official Node.js image
FROM node:18

# Alpine variant (väiksem)
FROM node:18-alpine

# Ubuntu base
FROM ubuntu:22.04

# Multi-stage build (nimega stage)
FROM gradle:8-jdk17 AS builder
```

**Best practices:**
- Kasuta **official image'id** Docker Hub'ist (node, python, openjdk)
- Kasuta **specific tag'e** (mitte `latest`) - `node:18.19.0` vs `node:latest`
- Kasuta **Alpine variants** väiksemate image'ite jaoks - `node:18-alpine` (50MB) vs `node:18` (1GB)

#### WORKDIR - Töökataloog

**Mis see teeb lihtsustatult?**

WORKDIR määrab konteineri sees kausta, kus su rakendus elab. Kõik järgnevad käsud (COPY, RUN, CMD) töötavad selles kaustas.

**Näide:** `WORKDIR /app` tähendab, et kõik failid lähevad konteineri `/app/` kausta.

---

**Süntaks:** `WORKDIR /path/to/directory`

Seab töötava kataloogi järgnevatele instrumentsioonidele (RUN, CMD, ENTRYPOINT, COPY, ADD).

```dockerfile
FROM node:18-alpine

# Loo ja määra /app kui töökataloog
WORKDIR /app

# Nüüd kõik COPY, RUN käsud töötavad /app kontekstis
COPY package.json .
# Kopeerib -> /app/package.json

RUN npm install
# Käivitub /app kataloogis
```

**Miks oluline:**
- Hoiab failid organiseeritud (`/app`, `/usr/src/app`)
- Väldi root kataloogi (`/`) prügistamist
- Igal RUN/COPY käsul pole vaja `cd /app &&`

#### COPY vs ADD - Failide Kopeerimine

**Mis COPY teeb lihtsustatult?**

COPY kopeerib faile **sinu arvutist (host masina rakenduse kataloog)** → **konteineri failisüsteemi sisse**.

**Visuaalne näide:**

```
Sinu arvuti (host):                     Docker konteiner:
/home/labuser/labs/apps/backend-nodejs/ /app/
├── package.json          COPY →        ├── package.json
├── src/                  COPY →        ├── src/
│   └── server.js                       │   └── server.js
├── Dockerfile            (ei kopeerita)
└── node_modules/         (ei kopeerita, .dockerignore)
```

**Build context:** See on kataloog, kus sinu `Dockerfile` asub. Tavaliselt on see rakenduse juurkataloog (`~/labs/apps/backend-nodejs/`). Kõik COPY käsud töötavad sellest kataloogist.

**Kuidas COPY töötab sammhaaval:**

```dockerfile
FROM node:18-alpine
WORKDIR /app                          # Konteineri töökataloog on nüüd /app

COPY package.json /app/package.json   # Host: ./package.json → Konteiner: /app/package.json
COPY src/ /app/src/                   # Host: ./src/* → Konteiner: /app/src/*
COPY . .                              # Host: ./* → Konteiner: /app/* (kõik failid)
```

**Täpsemalt:**
- **COPY package.json /app/package.json**
  - **KUST:** Build context'ist (kus Dockerfile asub): `./package.json`
  - **KUHU:** Konteineri sisse: `/app/package.json`

- **COPY . .**
  - **KUST:** Build context'i juurkataloog (`.` = kõik failid praeguses kataloogis)
  - **KUHU:** WORKDIR (`.` = `/app`, sest WORKDIR /app on seatud)

**Miks see oluline on:**
- COPY ei kopeeri faile **konteineri seest konteinerisse** - see kopeerib **sinu arvutist konteinerisse**
- Kui `docker build` käivitad kataloogis `~/labs/apps/backend-nodejs/`, siis COPY käsud näevad ainult selle kataloogi faile

---

**COPY süntaks:** `COPY <src> <dest>`
**ADD süntaks:** `ADD <src> <dest>`

```dockerfile
# COPY - lihtne failide kopeerimine
COPY package.json /app/
COPY src/ /app/src/
COPY . .

# ADD - nagu COPY, aga lisafunktsioonidega
ADD https://example.com/file.tar.gz /app/  # Download URL
ADD archive.tar.gz /app/                    # Auto-extract archives
```

**COPY vs ADD võrdlus:**

| Funktsioon | COPY | ADD |
|-----------|------|-----|
| Kopeeri lokaal faile | ✅ | ✅ |
| Auto-extract tar/gzip | ❌ | ✅ (auto) |
| Download URL'idest | ❌ | ✅ |
| **Best practice** | **✅ Kasuta COPY** | ❌ Väldi (välja arvatud special cases) |

**Best practice:** Kasuta **COPY**, mitte ADD (vähem "magic", predictable behavior).

```dockerfile
# GOOD: Eksplicitne
COPY package.json .
RUN tar -xzf archive.tar.gz && rm archive.tar.gz

# BAD: ADD "magic" behavior võib üllatada
ADD archive.tar.gz .
```

#### RUN - Käskude Käivitamine Build Ajal

**Mis see teeb lihtsustatult?**

RUN käivitab käsu **siis, kui Docker image't ehitatakse** (`docker build`), mitte siis, kui konteiner käivitub. Kasuta seda dependencies installimisel, failide seadistamisel jne.

**Näide:** `RUN npm install` installib Node.js paketid image'i ehitamise ajal (üks kord). Iga kord kui konteiner käivitub, on need juba olemas.

**RUN vs CMD erinevus:**
- **RUN:** Käivitub build ajal (üks kord, image'i loomise ajal)
- **CMD:** Käivitub runtime ajal (iga kord, kui konteiner käivitub)

---

**Süntaks:**
- **Shell form:** `RUN <command>` (käivitatakse `/bin/sh -c` kaudu)
- **Exec form:** `RUN ["executable", "param1", "param2"]`

RUN käivitab käsud **build time'il** (image'i loomise ajal), mitte runtime'il (konteineri käivitamisel).

```dockerfile
# Shell form (tavaline)
RUN apt-get update && apt-get install -y curl

# Exec form (no shell)
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "-y", "curl"]

# Multi-line (loetavam)
RUN apt-get update && \
    apt-get install -y \
        curl \
        wget \
        vim && \
    rm -rf /var/lib/apt/lists/*
```

**Best practices:**

1. **Chain käsud `&&` abil** (vähendab layer'ite arvu):
```dockerfile
# BAD: 3 layer'i
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# GOOD: 1 layer
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*
```

2. **Puhasta cache** (vähendab image size):
```dockerfile
# Debian/Ubuntu
RUN apt-get update && \
    apt-get install -y package && \
    rm -rf /var/lib/apt/lists/*

# Alpine
RUN apk add --no-cache package

# Node.js
RUN npm install --production && \
    npm cache clean --force
```

#### ENV - Environment Variables

**Mis see teeb lihtsustatult?**

ENV määrab muutujad (environment variables), mis on konteineri sees alati kättesaadavad - nii image'i ehitamise ajal kui ka konteineri käivitamisel.

**Näide:** `ENV NODE_ENV=production` määrab, et rakendus töötab "production" režiimis.

**ENV vs tavalised shell variable'd:**
- Tavalised shell variables (`export VAR=value`) kaovad pärast selle käsu lõppu
- ENV variable'd jäävad püsima ja on kättesaadavad kõigis järgnevates käskudes

---

**Süntaks:** `ENV <key>=<value>` või `ENV <key> <value>`

Määrab environment variable'id, mis on kättesaadavad **build time'il JA runtime'il**.

```dockerfile
# Single variable
ENV NODE_ENV=production

# Multiple variables
ENV NODE_ENV=production \
    PORT=3000 \
    LOG_LEVEL=info

# Kasutamine
ENV APP_DIR=/usr/src/app
WORKDIR $APP_DIR
COPY . $APP_DIR
```

**Build time vs Runtime:**
```dockerfile
ENV NODE_ENV=production

# Build time: RUN käsud näevad ENV
RUN echo "Building for $NODE_ENV"

# Runtime: CMD/ENTRYPOINT näevad ENV
CMD ["node", "-e", "console.log(process.env.NODE_ENV)"]
```

#### ARG - Build Arguments

**Mis see teeb lihtsustatult?**

ARG määrab muutuja, mida saad kasutada **ainult image'i ehitamise ajal**. Pärast seda see kaob. Kasulik erinevate versioonide ehitamiseks (nt dev vs prod).

**Näide:** `ARG NODE_VERSION=18` võimaldab: `docker build --build-arg NODE_VERSION=20`

**ARG vs ENV erinevus:**
- **ARG:** Kättesaadav ainult build ajal → kaob pärast `docker build`
- **ENV:** Kättesaadav build + runtime → püsib konteineris

---

**Süntaks:** `ARG <name>[=<default value>]`

ARG määrab variable, mis on kättesaadavad **AINULT build time'il** (mitte runtime'il).

```dockerfile
# Defineeri ARG default väärtusega
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine

ARG APP_ENV=development
RUN echo "Building for environment: $APP_ENV"

# Runtime'il APP_ENV pole kättesaadav (erinevalt ENV'ist)
```

**Kasutamine build ajal:**
```bash
# Kasuta default'i
docker build -t myapp .

# Override build argument
docker build --build-arg NODE_VERSION=20 --build-arg APP_ENV=production -t myapp .
```

**ARG vs ENV:**

| Aspekt | ARG | ENV |
|--------|-----|-----|
| Build time | ✅ | ✅ |
| Runtime | ❌ | ✅ |
| Override buildil | ✅ (`--build-arg`) | ❌ |
| Override runtime'il | ❌ | ✅ (`docker run -e`) |

#### EXPOSE - Portide Deklareerimine

**Mis see teeb lihtsustatult?**

EXPOSE on **dokumentatsioon** - see ütleb, et su rakendus kuulab seda porti. See EI ava porti automaatselt!

**Näide:** `EXPOSE 3000` dokumenteerib, et rakendus kasutab porti 3000.

**OLULINE levinud viga:**
- `EXPOSE 3000` **EI TEE** porti kättesaadavaks host'is
- Pordile ligipääsuks kasuta: `docker run -p 8080:3000 myapp`

---

**Süntaks:** `EXPOSE <port> [<port>/<protocol>...]`

EXPOSE dokumenteerib, milliseid porte konteiner kuulab. **See EI avalda porte automaatselt** (see on ainult dokumentatsioon).

```dockerfile
# HTTP port
EXPOSE 3000

# Multiple ports
EXPOSE 8080 8443

# Protocol määramine
EXPOSE 53/udp
EXPOSE 53/tcp
```

**OLULINE:** EXPOSE on **ainult dokumentatsioon**. Portide avamiseks kasuta `-p` flag'i:
```bash
docker run -p 8080:3000 myapp
# Host port 8080 -> Container port 3000
```

#### USER - Non-Root User

**Mis see teeb lihtsustatult?**

USER määrab, millise kasutajana rakendus käivitub. Vaikimisi on see **root** (OHTLIK!). Alati vaheta non-root kasutajale turvalisuse nimel.

**Näide:** `USER node` käivitab rakenduse "node" kasutajana (mitte root).

**Miks oluline:**
- Root konteineris = turvaoht (kui keegi häkkib sinu rakendust, on tal root õigused)
- Non-root = piiratud õigused (turvalisem)

---

**Süntaks:** `USER <username|UID>[:<groupname|GID>]`

Määrab user'i (ja optionally group'i), millega järgnevad RUN, CMD, ENTRYPOINT käsud käivitatakse.

```dockerfile
FROM node:18-alpine

# Default: kõik käsud jooksevad root'ina (OHTLIK!)

WORKDIR /app
COPY package.json .
RUN npm install

# Vaheta non-root user'ile (TURVALISEM)
USER node

# Nüüd CMD jookseb node user'ina (mitte root)
CMD ["node", "server.js"]
```

**Best practice:** Ära käivita rakendusi **root user'ina** (security risk).

**Node.js official image'il on juba `node` user olemas:**
```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY --chown=node:node . .
# --chown määrab omanikuks node:node (mitte root)

USER node
CMD ["node", "server.js"]
```

**Ubuntu/Debian base image'il loo user:**
```dockerfile
FROM ubuntu:22.04

# Loo non-root user
RUN groupadd -r appuser && \
    useradd -r -g appuser appuser

WORKDIR /app
COPY --chown=appuser:appuser . .

USER appuser
CMD ["./my-app"]
```

#### CMD vs ENTRYPOINT - Konteineri Käivituskäsk

**Mis CMD teeb lihtsustatult?**

CMD määrab käsu, mis **käivitub iga kord, kui konteiner starditakse** (`docker run`). See on su rakenduse "start" nupp.

**Näide:** `CMD ["node", "server.js"]` käivitab Node.js serveri iga kord, kui konteiner käivitub.

**CMD vs RUN erinevus:**
- **RUN npm install** → Käivitub 1x image'i ehitamisel
- **CMD ["node", "server.js"]** → Käivitub iga kord konteineri käivitumisel

---

**CMD süntaks:**
- **Exec form (soovitatav):** `CMD ["executable", "param1", "param2"]`
- **Shell form:** `CMD command param1 param2`

**ENTRYPOINT süntaks:**
- **Exec form:** `ENTRYPOINT ["executable", "param1"]`
- **Shell form:** `ENTRYPOINT command param1`

**CMD - Default käsk:**
CMD määrab default käsu, mis käivitatakse konteineri startimisel. **Lihtne override'ida** `docker run` käsuga.

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .
CMD ["node", "server.js"]
```

```bash
# Kasutab CMD default'i
docker run myapp
# Käivitab: node server.js

# Override CMD
docker run myapp node worker.js
# Käivitab: node worker.js (mitte server.js!)
```

**ENTRYPOINT - Peamine executable:**
ENTRYPOINT määrab peamise käsu, mis **alati käivitatakse**. CMD argumendid lisatakse ENTRYPOINT'ile.

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .
ENTRYPOINT ["node"]
CMD ["server.js"]
```

```bash
# Käivitab: node server.js
docker run myapp

# Override ainult CMD (node jääb alles)
docker run myapp worker.js
# Käivitab: node worker.js

# Override ENTRYPOINT (harv)
docker run --entrypoint sh myapp
# Käivitab: sh (ignore'ib node)
```

**CMD vs ENTRYPOINT kombinatsioonid:**

| Dockerfile | `docker run myapp` | `docker run myapp arg1` |
|------------|-------------------|------------------------|
| `CMD ["node", "server.js"]` | `node server.js` | `arg1` (override!) |
| `ENTRYPOINT ["node"]`<br>`CMD ["server.js"]` | `node server.js` | `node arg1` |
| `ENTRYPOINT ["node", "server.js"]` | `node server.js` | `node server.js arg1` (lisab lõppu) |

**Best practice:**
- Kui konteiner on **rakendus** (nt web server), kasuta **CMD**
- Kui konteiner on **tool/utility** (nt CLI), kasuta **ENTRYPOINT + CMD**

```dockerfile
# Rakendus (web server)
CMD ["node", "server.js"]

# Tool (CLI utility)
ENTRYPOINT ["aws"]
CMD ["--help"]
# Võimaldab: docker run myaws s3 ls
```

#### HEALTHCHECK - Tervise Kontroll

**Mis see teeb lihtsustatult?**

HEALTHCHECK käivitab perioodiliselt käsu, mis kontrollib, kas su rakendus töötab korralikult. Kui ei tööta, märgitakse konteiner "unhealthy".

**Näide:** `HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1`

**Miks oluline:**
- Docker/Kubernetes näeb, kui rakendus on "unhealthy"
- Automaatne restart või traffic suunamine ära unhealthy konteinerist

---

**Süntaks:** `HEALTHCHECK [OPTIONS] CMD command`

Määrab käsu, mis kontrollib konteineri tervist (health).

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .

# Health check: curl http://localhost:3000/health
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
```

**Optsioonid:**
- `--interval=30s`: Kui tihti kontrollida (default 30s)
- `--timeout=5s`: Max aeg vastuse ootamiseks (default 30s)
- `--retries=3`: Mitu korda proovida enne "unhealthy" staatust (default 3)
- `--start-period=60s`: Kui kaua oodata enne esimest kontrolli (default 0s)

**Exit code'd:**
- `0`: Healthy (success)
- `1`: Unhealthy (failure)

```bash
# Vaata health state'i
docker ps
# STATUS: Up 2 minutes (healthy)

docker inspect --format='{{.State.Health.Status}}' my-container
# healthy
```

### Multi-Stage Builds - Image Optimeerimine

Multi-stage build võimaldab kasutada **mitut FROM instruktsiooni** Dockerfile'is. Eesmärk: **ehita** rakendus suuremas image'is (build tools) ja **kopeeri** ainult lõplik binary/artifact väiksemasse runtime image'isse.

**Probleem (ilma multi-stage):**
```dockerfile
# Sisaldab KÕIKE: build tools + runtime + source code + dependencies
FROM node:18
WORKDIR /app
COPY package.json package-lock.json .
RUN npm install  # Installib ka dev dependencies (jest, webpack, eslint)
COPY . .
RUN npm run build  # Build production assets

CMD ["node", "dist/server.js"]
# Image size: 1.2GB (node_modules sisaldab dev deps, source code on kaasas)
```

**Lahendus (multi-stage build):**
```dockerfile
# ========== BUILD STAGE ==========
FROM node:18 AS builder

WORKDIR /app
COPY package.json package-lock.json .
RUN npm ci  # Clean install (kõik dependencies)

COPY . .
RUN npm run build  # Build production (dist/ kataloog)

# ========== RUNTIME STAGE ==========
FROM node:18-alpine

WORKDIR /app

# Kopeeri AINULT production dependencies
COPY package.json package-lock.json .
RUN npm ci --only=production && npm cache clean --force

# Kopeeri AINULT built assets (dist/) builder stage'ist
COPY --from=builder /app/dist ./dist

USER node
CMD ["node", "dist/server.js"]

# Image size: 250MB (ainult runtime deps + built code)
```

**Kasu:**
- **70-90% väiksem image:** 1.2GB → 250MB
- **Turvalisem:** Source code, dev tools pole lõplikus image'is
- **Kiirem deployment:** Väiksem image = kiirem push/pull

**Multi-stage build'i stages nimetamine:**
```dockerfile
FROM gradle:8-jdk17 AS build-stage
FROM openjdk:17-jre AS runtime-stage
FROM alpine:latest AS final

# Kopeeri teisest stage'ist
COPY --from=build-stage /app/build/libs/app.jar .
COPY --from=runtime-stage /opt/java/openjdk .
```

**Näide: Java Spring Boot rakendus (Gradle):**
```dockerfile
# ========== BUILD STAGE ==========
FROM gradle:8-jdk17 AS builder

WORKDIR /app
COPY build.gradle settings.gradle ./
COPY src ./src

# Build executable JAR
RUN gradle bootJar --no-daemon

# ========== RUNTIME STAGE ==========
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Kopeeri JAR builder stage'ist
COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8080

# Non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

CMD ["java", "-jar", "app.jar"]

# Image size: ~250MB (vs ~800MB ilma multi-stage'ita)
```

### Base Image'i Valik: Alpine vs Debian vs Distroless

Õige base image'i valik mõjutab **image size, security, compatibility**.

#### Alpine Linux

**Omadused:**
- **Väga väike:** 5-7MB base image
- **musl libc:** Ei kasuta glibc (võib põhjustada compatibility issues)
- **apk package manager:** `apk add --no-cache package`

**Image sizes (Node.js näide):**
- `node:18`: ~1GB (Debian)
- `node:18-alpine`: ~120MB

**Plussid:**
- ✅ Väike size (kiire pull/push)
- ✅ Vähem attack surface (vähem packages)
- ✅ Security-focused distro

**Miinused:**
- ❌ Compatibility issues (musl vs glibc)
- ❌ Mõned native Node.js packages ei tööta (nt bcrypt vajab rebuild'i)
- ❌ Debugging on raskem (vähem tools)

**Kasutamine:**
```dockerfile
FROM node:18-alpine

# Vajad build tools native modules jaoks
RUN apk add --no-cache python3 make g++

WORKDIR /app
COPY package.json .
RUN npm install  # Rebuild native modules Alpine jaoks

COPY . .
CMD ["node", "server.js"]
```

#### Debian/Ubuntu (slim variants)

**Omadused:**
- **Keskmine size:** 50-80MB (slim variant)
- **glibc:** Laialt toetatud (compatibility)
- **apt package manager:** `apt-get install`

**Image sizes:**
- `node:18`: ~1GB (full Debian)
- `node:18-slim`: ~240MB
- `node:18-bullseye-slim`: ~240MB (Debian 11)

**Plussid:**
- ✅ Laiem compatibility (glibc)
- ✅ Rohkem pakette saadaval (apt)
- ✅ Native modules töötavad out-of-the-box

**Miinused:**
- ❌ Suurem size kui Alpine
- ❌ Rohkem potential vulnerabilities

**Kasutamine:**
```dockerfile
FROM node:18-slim

WORKDIR /app
COPY package.json .
RUN npm install  # Native modules töötavad ilma rebuild'ita

COPY . .
CMD ["node", "server.js"]
```

#### Distroless Images (Google)

**Omadused:**
- **Minimaalne:** Sisaldab AINULT runtime'i (nt Java JRE), pole shell'i, package manager'i
- **Ultra-secure:** Pole vulnerabilities (pole packages)

**Image sizes:**
- `gcr.io/distroless/java17`: ~150MB
- `gcr.io/distroless/nodejs18`: ~120MB

**Plussid:**
- ✅ Ultra-secure (minimal attack surface)
- ✅ Väike size
- ✅ Production best practice

**Miinused:**
- ❌ Pole shell'i (debugging on raske: `docker exec -it container sh` ei tööta)
- ❌ Pole package manager'i

**Kasutamine (Java):**
```dockerfile
# Build stage
FROM gradle:8-jdk17 AS builder
WORKDIR /app
COPY . .
RUN gradle bootJar

# Runtime stage (distroless)
FROM gcr.io/distroless/java17

COPY --from=builder /app/build/libs/*.jar /app.jar

EXPOSE 8080
USER nonroot:nonroot

CMD ["app.jar"]

# Pole shell'i, ainult Java runtime!
```

**Võrdlus:**

| Base Image | Size | Security | Compatibility | Use Case |
|-----------|------|----------|---------------|----------|
| **Alpine** | 120MB | ✅ Hea | ⚠️ musl libc | Size-optimized apps |
| **Debian Slim** | 240MB | ✅ OK | ✅ glibc | General purpose |
| **Debian** | 1GB | ❌ Suur | ✅ Full | Development/debugging |
| **Distroless** | 150MB | ✅✅ Parim | ✅ Runtime-only | Production (max security) |

**Soovitus:**
- **Development:** Debian (full) - debugging tools
- **Production (general):** Alpine või Debian Slim
- **Production (max security):** Distroless

### .dockerignore Fail

.dockerignore töötab nagu .gitignore - määrab, milliseid faile **EI kopeerita** build context'i.

**Miks oluline:**
- **Kiirem build:** Vähem faile context'is = kiirem upload Docker daemon'ile
- **Väiksem image:** Ei kopeeri prügi image'isse
- **Security:** Ei kopeeri `.env`, `secrets.json`, `.git`

**Näide .dockerignore:**
```
# Dependencies (need installitakse image'is RUN npm install)
node_modules/
npm-debug.log

# Build artifacts
build/
dist/
*.log

# Git
.git/
.gitignore

# Environment files (SECRETS!)
.env
.env.local
*.pem
*.key

# Documentation
README.md
docs/

# Tests
tests/
*.test.js
coverage/

# IDE
.vscode/
.idea/
*.swp
```

**Kuidas töötab:**
```dockerfile
# Ilma .dockerignore
COPY . .
# Kopeerib KÕIK (node_modules, .git, .env, tests, 500MB+)

# .dockerignore'iga
COPY . .
# Kopeerib ainult source code (10MB)
```

### Layer Caching Optimeerimine

Docker cache'ib layer'id. Kui layer pole muutunud, kasutatakse cache'i (ei rebuild'i).

**Probleem (halb layer järjekord):**
```dockerfile
FROM node:18-alpine

WORKDIR /app

# BAD: Kopeerid kõik failid esimesena
COPY . .

# Igakord kui muudad üht faili, rebuild'itakse npm install (aeglane!)
RUN npm install

CMD ["node", "server.js"]
```

**Build behavior:**
```bash
# Esimene build
docker build -t myapp .
# COPY . . -> cache miss (kopeerib kõik)
# RUN npm install -> cache miss (5 min)

# Muuda server.js faili
# Teine build
docker build -t myapp .
# COPY . . -> cache miss (server.js muutus!)
# RUN npm install -> cache miss (rebuild! 5 min uuesti!!!)
```

**Lahendus (hea layer järjekord):**
```dockerfile
FROM node:18-alpine

WORKDIR /app

# GOOD: Kopeeri package.json ESIMESENA (see muutub harva)
COPY package.json package-lock.json ./

# npm install jookseb ainult kui package.json muutub
RUN npm install

# Kopeeri source code VIIMASENA (see muutub tihti)
COPY . .

CMD ["node", "server.js"]
```

**Build behavior (optimeeritud):**
```bash
# Esimene build
docker build -t myapp .
# COPY package.json -> cache miss
# RUN npm install -> cache miss (5 min)
# COPY . . -> cache miss

# Muuda server.js faili (package.json POLE muutunud)
# Teine build
docker build -t myapp .
# COPY package.json -> cache HIT ✅
# RUN npm install -> cache HIT ✅ (ei rebuild!)
# COPY . . -> cache miss (ainult source code kopeeritakse uuesti)
# Build aeg: 5 sekundit! (vs 5 minutit)
```

**Reegel:** Pane **harva muutuvad asjad ALGUSSE**, **tihti muutuvad asjad LÕPPU**.

```dockerfile
# Layer järjekord (harva -> tihti muutuv)
FROM node:18-alpine             # 1. Base image (muutub MITTE KUNAGI build'i ajal)
WORKDIR /app                    # 2. Metadata (muutub harva)
COPY package.json .             # 3. Dependencies manifest (muutub harva)
RUN npm install                 # 4. Install dependencies (cache'itav)
COPY . .                        # 5. Source code (muutub TIHTI)
CMD ["node", "server.js"]       # 6. Metadata (muutub harva)
```

## Praktilised Näited

### Näide 1: Lihtne Node.js Express Rakendus

**Projekt struktuur:**
```
my-app/
├── Dockerfile
├── .dockerignore
├── package.json
├── package-lock.json
└── src/
    └── server.js
```

**Dockerfile:**
```dockerfile
# Base image: Node.js 18 Alpine
FROM node:18-alpine

# Metadata
LABEL maintainer="yourname@example.com"
LABEL version="1.0"

# Set working directory
WORKDIR /app

# Copy dependency manifests FIRST (caching)
COPY package.json package-lock.json ./

# Install production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy source code
COPY src/ ./src/

# Expose port
EXPOSE 3000

# Non-root user (node user exists in official image)
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "src/server.js"]
```

**.dockerignore:**
```
node_modules/
npm-debug.log
.git/
.env
README.md
tests/
```

**Build ja run:**
```bash
# Build image
docker build -t my-express-app:1.0 .

# Run container
docker run -d -p 3000:3000 --name my-app my-express-app:1.0

# Test
curl http://localhost:3000
# Hello World!

# View logs
docker logs -f my-app

# Check health
docker inspect --format='{{.State.Health.Status}}' my-app
# healthy
```

### Näide 2: Multi-Stage Build - React Frontend

**Projekt struktuur:**
```
react-app/
├── Dockerfile
├── .dockerignore
├── package.json
├── package-lock.json
├── public/
└── src/
    ├── App.js
    └── index.js
```

**Dockerfile (multi-stage):**
```dockerfile
# ========== BUILD STAGE ==========
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build
# Tulemus: /app/build/ kataloog (static HTML/JS/CSS)

# ========== PRODUCTION STAGE ==========
FROM nginx:1.25-alpine

# Copy built assets from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Custom Nginx config (optional)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Nginx runs as root by default, but we can change it
# RUN chown -R nginx:nginx /usr/share/nginx/html
# USER nginx

# Health check
HEALTHCHECK --interval=30s --timeout=5s \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Nginx starts automatically (default CMD from nginx image)
```

**nginx.conf:**
```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # SPA routing (React Router)
    location / {
        try_files $uri /index.html;
    }

    # Caching for static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

**Build:**
```bash
docker build -t my-react-app:1.0 .

# Image size: ~50MB (Alpine Nginx + React build artifacts)
# vs ~1.2GB (ilma multi-stage, sisaldaks Node.js + node_modules)

docker run -d -p 8080:80 --name react-app my-react-app:1.0
# Ava brauseris: http://localhost:8080
```

### Näide 3: Python Flask Rakendus (Optimeeritud)

**Dockerfile:**
```dockerfile
FROM python:3.11-slim

# Install system dependencies (kui vaja)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first (caching)
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=5s \
  CMD python -c "import requests; requests.get('http://localhost:5000/health').raise_for_status()"

# Run Flask app
CMD ["python", "app.py"]
```

### Näide 4: Debugging Dockerfile (Build Args)

Kasuta **ARG** erinevate build variant'ide jaoks:

```dockerfile
# Debugging variant (dev) vs Production (prod)
ARG BUILD_ENV=production

FROM node:18-alpine

WORKDIR /app

COPY package.json package-lock.json ./

# Install dev dependencies ainult development build'is
RUN if [ "$BUILD_ENV" = "development" ]; then \
        npm ci; \
    else \
        npm ci --only=production; \
    fi

COPY . .

# Expose port (default 3000)
ARG PORT=3000
ENV PORT=$PORT
EXPOSE $PORT

USER node

CMD ["node", "server.js"]
```

**Build variants:**
```bash
# Production build (default)
docker build -t myapp:prod .

# Development build (dev dependencies included)
docker build --build-arg BUILD_ENV=development -t myapp:dev .

# Custom port
docker build --build-arg PORT=8080 -t myapp:8080 .
```

## Levinud Probleemid ja Lahendused

### Probleem 1: "COPY failed: no such file or directory"

**Sümptom:**
```dockerfile
COPY src/server.js .
# Error: COPY failed: file not found in build context
```

**Põhjus:** Fail on .dockerignore'is või pole build context'is.

**Lahendus:**
```bash
# Kontrolli, mis on build context'is
docker build --no-cache --progress=plain -t myapp . 2>&1 | grep "COPY"

# Vaata .dockerignore
cat .dockerignore

# Eemalda src/ .dockerignore'ist (kui ekslikult seal)
```

### Probleem 2: npm install failing (native modules)

**Sümptom (Alpine):**
```dockerfile
RUN npm install
# node-gyp rebuild fails (bcrypt, sharp, etc.)
```

**Põhjus:** Alpine kasutab musl libc, mitte glibc. Native modules vajad rebuild'i.

**Lahendus:**
```dockerfile
FROM node:18-alpine

# Install build tools
RUN apk add --no-cache python3 make g++

WORKDIR /app
COPY package.json .
RUN npm install  # Rebuilds native modules

COPY . .
CMD ["node", "server.js"]
```

**Alternatiiv:** Kasuta Debian slim (native modules töötavad out-of-the-box):
```dockerfile
FROM node:18-slim
# npm install töötab ilma build tools'ita
```

### Probleem 3: Image size on liiga suur

**Sümptom:**
```bash
docker images
# myapp   latest   1.5GB
```

**Põhjus:** Dev dependencies, build tools, cache jne.

**Lahendus:**

1. **Kasuta multi-stage build:**
```dockerfile
FROM node:18 AS builder
RUN npm ci && npm run build

FROM node:18-alpine
COPY --from=builder /app/dist ./dist
RUN npm ci --only=production
```

2. **Alpine base image:**
```dockerfile
FROM node:18-alpine  # 120MB vs node:18 (1GB)
```

3. **Puhasta cache:**
```dockerfile
RUN npm install && npm cache clean --force
RUN apt-get update && apt-get install -y package && rm -rf /var/lib/apt/lists/*
```

4. **Vaata, mis on suured layer'd:**
```bash
docker history myapp:latest
# Näitab iga layer'i size'i
```

### Probleem 4: Build on aeglane (iga kord rebuild npm install)

**Põhjus:** Vale layer järjekord (source code kopeeritakse enne dependencies).

**Lahendus:** Kopeeri package.json ESIMESENA:
```dockerfile
# BAD: Aeglane
COPY . .
RUN npm install

# GOOD: Cache-friendly
COPY package.json package-lock.json ./
RUN npm install
COPY . .
```

### Probleem 5: Permission denied (konteineri sees)

**Sümptom:**
```
Error: EACCES: permission denied, open '/app/data.json'
```

**Põhjus:** Fail/kataloog kuulub root'ile, aga rakendus jookseb node user'ina.

**Lahendus:**
```dockerfile
# Kopeeri failid ja määra omanikuks node user
COPY --chown=node:node . .

# Või muuda ownership pärast kopeerimist
COPY . .
RUN chown -R node:node /app

USER node
```

## Best Practices

### DO's (Tee nii):

- ✅ **Kasuta official base image'id:** `FROM node:18-alpine` (turvalisem)
- ✅ **Kasuta specific tag'e:** `node:18.19.0` vs `node:latest` (predictable)
- ✅ **Multi-stage builds:** Build stage → Runtime stage (väike image)
- ✅ **Layer caching:** Kopeeri package.json enne source code'i
- ✅ **.dockerignore fail:** Väldi node_modules, .git, tests, .env kopeerimist
- ✅ **Non-root user:** `USER node` (security)
- ✅ **Cleanup cache:** `npm cache clean`, `rm -rf /var/lib/apt/lists/*`
- ✅ **Chain RUN käsud:** `RUN apt-get update && apt-get install` (vähem layer'id)
- ✅ **EXPOSE dokumentatsioon:** `EXPOSE 3000` (clarity)
- ✅ **HEALTHCHECK:** Võimalda orkestreerijatel (Kubernetes) tervise kontroll
- ✅ **WORKDIR määramine:** `/app`, `/usr/src/app` (mitte root `/`)
- ✅ **Metadata (LABEL):** `LABEL maintainer="..."`, `LABEL version="1.0"`

### DON'Ts (Väldi):

- ❌ **Ära kasuta `latest` tag production'is:** Versioon muutub (unpredictable)
- ❌ **Ära käivita root user'ina:** `USER root` on security risk
- ❌ **Ära kopeeri secrets image'isse:** `.env`, API keys (kasuta runtime env variables)
- ❌ **Ära install dev dependencies production'is:** `npm ci --only=production`
- ❌ **Ära unusta .dockerignore:** `node_modules`, `.git` suurendavad image'i
- ❌ **Ära kasuta ADD kui vaja COPY:** ADD on less predictable
- ❌ **Ära loo tarbetuid layer'id:** Chain RUN käsud `&&` abil
- ❌ **Ära install debug tools production image'isse:** `vim`, `curl`, `wget` (attack surface)
- ❌ **Ära hard-code konfiguratsioonivalues:** Kasuta ENV või ARG

## Kokkuvõte

Dockerfile on **image'i blueprint** - definerib, kuidas rakendus konteineritakse.

**Võtmepunktid:**
1. **Dockerfile instruktsoonid:** FROM, WORKDIR, COPY, RUN, ENV, EXPOSE, USER, CMD/ENTRYPOINT, HEALTHCHECK
2. **Multi-stage builds:** Build stage (suur, tools) → Runtime stage (väike, ainult vajalik) - **70-90% size vähenemine**
3. **Base image valik:** Alpine (väike, security) vs Debian Slim (compatibility) vs Distroless (max security)
4. **Layer caching:** Harva muutuvad asjad ALGUSSE (package.json), tihti muutuvad LÕPPU (source code)
5. **.dockerignore:** Väldi node_modules, .git, .env kopeerimist (kiirus, security, size)
6. **Security:** Non-root user (`USER node`), no secrets in image, minimal packages
7. **Best practice pattern:**
   ```dockerfile
   FROM node:18-alpine
   WORKDIR /app
   COPY package.json .
   RUN npm ci --only=production
   COPY . .
   USER node
   CMD ["node", "server.js"]
   ```

**Viide laboratooriumidele:**
- **Lab 1:** Dockerize User Service (Node.js), Todo Service (Java Spring Boot), Frontend - praktiline Dockerfile loomine
- **Lab 2:** Docker Compose - mitme Dockerfile'i kombineerimine

**Järgmised sammud:**
- **Peatükk 6A:** Java/Spring Boot ja Node.js konteineriseerimise spetsiifika (Tomcat vs Spring Boot, JVM tuning, practical examples)
- **Peatükk 7:** Docker image'ite haldamine, optimeerimine, registry workflow

## Viited ja Edasine Lugemine

### Ametlik dokumentatsioon:
- **Dockerfile reference:** https://docs.docker.com/engine/reference/builder/
- **Best practices:** https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- **Multi-stage builds:** https://docs.docker.com/build/building/multi-stage/
- **.dockerignore:** https://docs.docker.com/engine/reference/builder/#dockerignore-file

### Base images:
- **Official images:** https://hub.docker.com/search?q=&type=image&image_filter=official
- **Alpine Linux:** https://alpinelinux.org/
- **Distroless images:** https://github.com/GoogleContainerTools/distroless

### Tools:
- **Dive:** Image layer analüüs - https://github.com/wagoodman/dive
- **Hadolint:** Dockerfile linter - https://github.com/hadolint/hadolint
- **Docker Slim:** Image optimeerimistööriist - https://dockersl.im/

### Security:
- **Dockerfile security best practices:** https://snyk.io/blog/10-docker-image-security-best-practices/
- **CIS Docker Benchmark:** https://www.cisecurity.org/benchmark/docker

---

**Viimane uuendus:** 2025-11-23
**Seos laboritega:** Lab 1 (Docker Põhitõed - Dockerfile loomine)
**Eelmine peatükk:** 05-Docker-Pohimotted.md
**Järgmine peatükk:** 06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md
