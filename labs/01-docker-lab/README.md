# Labor 1: Docker Põhitõed

**Kestus:** 4 tundi
**Eeldused:** Peatükk 12 (Docker põhimõtted) läbitud
**Eesmärk:** Õppida Docker image'ite ja containerite haldamist hands-on

---

## 📋 Ülevaade

Selles laboris õpid konteineriseerima kolme mikroteenust, haldama volumes ja networks ning optimeerima Docker image'id production'i jaoks.

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

✅ Luua Dockerfile'e erinevatele rakendustele
✅ Build'ida Docker image'id
✅ Käivitada ja hallata containereid
✅ Seadistada Docker networks
✅ Kasutada volumes andmete säilitamiseks
✅ Optimeerida image suurust
✅ Kasutada multi-stage builds

---

## 🏗️ Arhitektuur

**Lab 1 katab MÕLEMAD mikroteenust:**

```
┌────────────────────────┐        ┌────────────────────────┐
│   User Service         │        │   Todo Service         │
│   (Node.js 18)         │        │   (Java 17 + Spring)   │
│   Port: 3000           │        │   Port: 8081           │
│                        │        │                        │
│   - POST /auth/register│        │   - GET /api/todos     │
│   - POST /auth/login   │        │   - POST /api/todos    │
│   - GET /api/users     │        │   - PATCH /api/todos/:id│
│   - GET /health        │        │   - DELETE /api/todos/:id│
└──────────┬─────────────┘        └──────────┬─────────────┘
           │                                 │
           ▼                                 ▼
    ┌─────────────┐                  ┌─────────────┐
    │  PostgreSQL │                  │  PostgreSQL │
    │  Port: 5432 │                  │  Port: 5433 │
    │             │                  │             │
    │  - users    │                  │  - todos    │
    └─────────────┘                  └─────────────┘
```

**Mikroteenuste arhitektuur:**
- User Service: JWT autentimine, kasutajate haldus
- Todo Service: Ülesannete haldus, kasutab User Service'i JWT token'eid
- Eraldatud andmebaasid: igal teenustel oma PostgreSQL instants

---

## 📂 Labori Struktuur

```
01-docker-lab/
├── README.md              # See fail
├── setup.sh               # Automaatne setup ja image'de ehitamine
├── reset.sh               # Labori ressursside puhastamine
├── exercises/             # Harjutused (6 harjutust)
│   ├── 01a-single-container-nodejs.md        # User Service (Node.js)
│   ├── 01b-single-container-java.md          # Todo Service (Java)
│   ├── 02-multi-container.md                 # Multi-service + PostgreSQL
│   ├── 03-networking.md                      # Docker networks
│   ├── 04-volumes.md                         # Andmete säilitamine
│   └── 05-optimization.md                    # Multi-stage builds
└── solutions/             # Lahendused
    ├── backend-nodejs/        # User Service lahendused
    │   ├── Dockerfile             # Lihtne Dockerfile
    │   ├── Dockerfile.optimized   # Multi-stage build
    │   ├── .dockerignore          # Build context optimeerimine
    │   └── healthcheck.js         # Health check script
    └── backend-java-spring/   # Todo Service lahendused
        ├── Dockerfile             # Lihtne Dockerfile
        ├── Dockerfile.optimized   # Multi-stage build
        └── .dockerignore          # Build context optimeerimine
```

---

## 🔧 Eeldused

### Eelnevad labid:
- ❌ **Puuduvad** - See on esimene labor

### Tööriistad:
- [x] Docker paigaldatud (`docker --version`)
- [x] Docker daemon töötab (`docker ps`)
- [x] Vähemalt 4GB vaba kettaruumi
- [x] Internet ühendus (image'ite allalaadimiseks)

### Teadmised:
- [x] **Peatükk 12:** Docker põhimõtted ja konteineriseerimise alused
- [x] Bash/terminal põhikäsud
- [x] Text editor kasutamine (vim soovitatud)

---

## 📚 Progressiivne Õppetee

```
Labor 1 (Docker) ← Oled siin
  ↓ Docker image'd →
Labor 2 (Compose)
  ↓ Multi-container kogemus →
Labor 3 (K8s Basics)
  ↓ K8s manifests + deployed apps →
Labor 4 (K8s Advanced)
  ↓ Ingress + Helm →
Labor 5 (CI/CD)
  ↓ Automated deployments →
Labor 6 (Monitoring)
```

---

## 📝 Harjutused

### Harjutus 1A: Single Container - User Service (45 min)
**Fail:** [exercises/01a-single-container-nodejs.md](exercises/01a-single-container-nodejs.md)

Konteinerise User Service (Node.js):
- Loo Dockerfile
- Build user-service:1.0 image
- Käivita container
- Testi REST API (/api/auth/*, /api/users)
- Debug logs

### Harjutus 1B: Single Container - Todo Service (45 min)
**Fail:** [exercises/01b-single-container-java.md](exercises/01b-single-container-java.md)

Konteinerise Todo Service (Java Spring Boot):
- Loo Dockerfile
- Build JAR file
- Build todo-service:1.0 image
- Käivita container
- Testi REST API (/api/todos)

💡 **Kiirvalik:** Käivita `./setup.sh` ja vali `Y` → ehitab mõlemad image'd automaatselt

### Harjutus 2: Multi-Container Setup (90 min)
**Fail:** [exercises/02-multi-container.md](exercises/02-multi-container.md)

Käivita User Service + Todo Service + 2x PostgreSQL:
- Käivita 2 PostgreSQL containerit (portid 5432, 5433)
- Ühenda mõlemad teenused oma andmebaasidega
- Testi mikroteenuste suhtlust (JWT workflow)
- Troubleshoot connectivity

### Harjutus 3: Docker Networking (45 min)
**Fail:** [exercises/03-networking.md](exercises/03-networking.md)

Loo custom network (4 containerit):
- Loo todo-network
- Käivita kõik containerid samas network'is
- Testi DNS resolution
- Test End-to-End JWT workflow

### Harjutus 4: Docker Volumes (45 min)
**Fail:** [exercises/04-volumes.md](exercises/04-volumes.md)

Andmete säilitamine (2 volume'd):
- Loo postgres-user-data ja postgres-todo-data
- Mount volume'd PostgreSQL'idele
- Testi andmete persistence
- Backup ja restore mõlemast andmebaasist

### Harjutus 5: Image Optimization (45 min)
**Fail:** [exercises/05-optimization.md](exercises/05-optimization.md)

Optimeeri mõlema teenuse image'd:
- Node.js: Multi-stage build (200MB → 50MB)
- Java: Multi-stage build (370MB → 180MB)
- Health checks
- Layer caching
- .dockerignore

---

## ⚡ Kiirstart Setup

### Variant A: Automaatne Seadistus (Soovitatud)

Käivita setup script, mis kontrollib kõik eeldused ja valmistab labori ette:

```bash
# Käivita setup script
chmod +x setup.sh
./setup.sh
```

**Script kontrollib:**
- ✅ Docker'i paigaldust ja versiooni
- ✅ Docker daemon'i staatust
- ✅ Vaba kettaruumi (>5GB soovitatud)
- ✅ Java ja Node.js olemasolu
- ✅ Rakenduste kättesaadavust
- ✅ Harjutuste ja lahenduste olemasolu

**Script pakub:**
- 💡 Automaatset base image'de ehitamist (`user-service:1.0`, `todo-service:1.0`)
- 💡 Võimalust vahele jätta Harjutus 1 ja alustada otse Harjutus 2'st

**Kuidas kasutada:**

```bash
./setup.sh

# Kui küsitakse: "Kas soovid ehitada base image'd KOHE?"
# Vali Y → Ehitab image'd automaatselt (~2-5 min)
#       → Saad alustada otse Harjutus 2'st
# Vali N → Alustad Harjutus 1'st (soovitatud õppimiseks)
#       → Õpid Dockerfile'i loomist algusest
```

---

## 🔄 Labori Ressursside Haldamine

### reset.sh - Puhasta ja Alusta Uuesti

Kui soovid labori ressursse puhastada ja alustada uuesti:

```bash
chmod +x reset.sh
./reset.sh
```

**Script kustutab:**
- 🗑️ Kõik Lab 1 containerid (user-service*, todo-service*, postgres-*)
- 🗑️ Lab 1 network'id (todo-network)
- 🗑️ Lab 1 volume'd (postgres-user-data, postgres-todo-data)
- 🗑️ Apps kaustadest harjutuste failid (Dockerfile, .dockerignore)

**Interaktiivne valik: Image'de Kustutamine**

Script küsib, kas kustutada ka Docker image'd:

```
Kas soovid kustutada ka Docker image'd?
  [N] Ei, jäta base image'd alles (user-service:1.0, todo-service:1.0)
      → Saad alustada otse Harjutus 2'st ilma uuesti buildimata
      → Kiire restart Harjutuste 2-5 jaoks
  [Y] Jah, kustuta KÕIK image'd (täielik reset)
      → Pead alustama Harjutus 1'st ja buildima image'd uuesti
      → Täielik "puhas leht" algusest
```

**Kasutusstsenaariume:**

```bash
# Stsenaarium 1: Kiire restart (säilita image'd)
./reset.sh
# Vali: N
# → Containerid/networks/volumes kustutatakse
# → Base image'd säilitatakse
# → Alusta uuesti Harjutus 2'st või 3'st

# Stsenaarium 2: Täielik reset (kustuta kõik)
./reset.sh
# Vali: Y
# → Kõik kustutatakse (sh image'd)
# → Alusta päris algusest (Harjutus 1)

# Stsenaarium 3: Automaatne reset (sh image'd)
echo "y" | ./reset.sh  # Kustutab KÕIK
```

---

### Variant B: Manuaalne Seadistus

Kui eelistad samm-sammult:

#### 1. Kontrolli Docker Paigaldust

```bash
# Docker versioon (peaks olema 20.x või uuem)
docker --version

# Kas Docker daemon töötab?
docker ps

# Testi Hello World
docker run hello-world
```

**Kui Docker puudub:**
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. Kontrolli Süsteemi Ressursse

```bash
# Vaba kettaruum (peaks olema vähemalt 4GB)
df -h

# Vaba RAM (soovitavalt 4GB+)
free -h
```

#### 3. Valmista Ette Töökeskkond

```bash
# Mine labori kataloogi
cd /home/janek/projects/hostinger/labs/01-docker-lab

# Kontrolli rakenduste kättesaadavust
ls ../apps/backend-java-spring
ls ../apps/backend-nodejs  # Lab 2 jaoks
ls ../apps/frontend  # Lab 2 jaoks
```

#### 4. Alusta Harjutus 1'st

```bash
cat exercises/01-single-container.md
```

---

### ⚡ Kiirkontroll: Kas Oled Valmis?

Enne labori alustamist veendu, et kõik on korras:

```bash
# Käivita kiirkontroll
docker --version && \
docker ps && \
df -h | grep -E "/$|/home" && \
echo "✅ Kõik eeldused on täidetud!"
```

---

## ✅ Kontrolli Tulemusi

Peale labori läbimist pead omama:

### Docker Image'd:

- [ ] `user-service:1.0` (Node.js backend, ~200MB)
- [ ] `user-service:1.0-optimized` (multi-stage build, ~50MB)
- [ ] `todo-service:1.0` (Java Spring Boot backend, ~370MB)
- [ ] `todo-service:1.0-optimized` (multi-stage build, ~180MB)

### Töötavad Containerid (Harjutus 4 lõpus):

- [ ] User Service (port 3000)
- [ ] Todo Service (port 8081)
- [ ] PostgreSQL User DB (port 5432)
- [ ] PostgreSQL Todo DB (port 5433)

### Volume'd:

- [ ] `postgres-user-data` (kasutajate andmebaas)
- [ ] `postgres-todo-data` (ülesannete andmebaas)

### Network:

- [ ] `todo-network` (custom bridge network)

### Testimine:

**User Service:**
- [ ] `POST /api/auth/register` - kasutaja registreerimine
- [ ] `POST /api/auth/login` - JWT token genereerimine
- [ ] `GET /api/users` - kasutajate nimekiri (vajab JWT)
- [ ] `GET /health` - tagastab OK

**Todo Service:**
- [ ] `POST /api/todos` - loo todo (vajab User Service JWT)
- [ ] `GET /api/todos` - loe todos
- [ ] `PATCH /api/todos/:id/complete` - märgi tehtud
- [ ] `DELETE /api/todos/:id` - kustuta
- [ ] `GET /health` - tagastab OK

**End-to-End JWT Workflow:**
- [ ] User Service genereerib JWT token
- [ ] Todo Service valideerib sama JWT token'it
- [ ] Mikroteenuste suhtlus toimib

---

## 📊 Progressi Jälgimine

- [ ] Harjutus 1A: Single Container (User Service - Node.js)
- [ ] Harjutus 1B: Single Container (Todo Service - Java)
- [ ] Harjutus 2: Multi-Container (2 teenust + 2 DB)
- [ ] Harjutus 3: Networking (Custom network, 4 containerit)
- [ ] Harjutus 4: Volumes (Data persistence, 2 volume'd)
- [ ] Harjutus 5: Optimization (Multi-stage builds, 2 teenust)

---

## 🆘 Troubleshooting

### Container ei käivitu?
```bash
docker logs <container-name>
docker inspect <container-name>
```

### Port on juba kasutusel?
```bash
# Vaata, mis kasutab porti
sudo lsof -i :3000

# Või kasuta teist porti
docker run -p 3001:3000 ...
```

### Image build ebaõnnestub?
```bash
# Kontrolli Dockerfile syntax
docker build --no-cache -t test .

# Vaata build logs
docker build -t test . 2>&1 | tee build.log
```

---

## 📚 Viited

### Koolituskava:
- **Peatükk 12:** Docker põhimõtted

### Docker Dokumentatsioon:
- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Docker CLI reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [Best practices](https://docs.docker.com/develop/dev-best-practices/)

---

## 🎯 Järgmine Labor

Peale selle labori edukat läbimist, jätka:
- **Labor 2:** Docker Compose

---

## 🎓 Kokkuvõte

Peale selle labori läbimist oled:
- ✅ Konteineriseerinud 2 mikroteenust (Node.js ja Java)
- ✅ Loonud 4 Docker image't (2 lihtsat + 2 optimeeritud)
- ✅ Hallanud multi-container süsteemi (4 containerit)
- ✅ Kasutanud Docker networks ja volumes
- ✅ Testinud End-to-End mikroteenuste suhtlust
- ✅ Optimeerinud image suurust (kuni 75% väiksemad!)

**Edu laboriga! 🚀**

---

## 📌 Lisainfo

**Abiskriptid:**
- `./setup.sh` - Automaatne setup ja image'de ehitamine
- `./reset.sh` - Labori ressursside puhastamine

**Harjutused:**
- 6 harjutust: 2x Single Container, Multi-Container, Networking, Volumes, Optimization
- Kokku: ~4.5 tundi

**Staatus:** ✅ 100% valmis
**Viimane uuendus:** 2025-11-19
