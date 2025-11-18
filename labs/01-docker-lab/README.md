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

**Peamine fookus: Todo Service (Java Spring Boot Backend)**

```
┌────────────────────────┐
│   Todo Service         │
│   (Java 17 + Spring Boot 3)│
│   Port: 8081           │
│                        │
│   - GET /api/todos     │
│   - POST /api/todos    │
│   - PUT /api/todos/{id}│
│   - DELETE /api/todos/{id}│
│   - GET /health        │
└──────────┬─────────────┘
           │
           ▼
    ┌─────────────┐
    │  PostgreSQL │
    │  Port: 5433 │
    │             │
    │  - todos    │
    └─────────────┘
```

**Märkus:** User Service (Node.js) ja Frontend on valikulised ning kaetakse Lab 2's (Docker Compose).

---

## 📂 Labori Struktuur

```
01-docker-lab/
├── README.md              # See fail
├── setup.sh               # Automaatne setup script
├── exercises/             # Harjutused (5 harjutust)
│   ├── 01-single-container.md     # Todo Service konteineriseerimine
│   ├── 02-multi-container.md      # Todo Service + PostgreSQL
│   ├── 03-networking.md           # Docker networks
│   ├── 04-volumes.md              # Andmete säilitamine
│   └── 05-optimization.md         # Multi-stage build
└── solutions/             # Lahendused
    └── backend-java-spring/   # Todo Service lahendused
        ├── Dockerfile             # Põhiline Dockerfile
        ├── Dockerfile.optimized   # Multi-stage build
        └── .dockerignore          # Image optimeerimiseks
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

### Harjutus 1: Single Container (45 min)
**Fail:** [exercises/01-single-container.md](exercises/01-single-container.md)

Konteinerise Todo Service (Java Spring Boot):
- Loo Dockerfile
- Build todo-service image
- Käivita container
- Testi REST API (/api/todos)
- Debug logs

### Harjutus 2: Multi-Container (60 min)
**Fail:** [exercises/02-multi-container.md](exercises/02-multi-container.md)

Käivita Todo Service + PostgreSQL:
- Käivita PostgreSQL container (port 5433)
- Ühenda Todo Service andmebaasiga
- Testi CRUD operatsioonid (todos)
- Troubleshoot connectivity

### Harjutus 3: Networking (45 min)
**Fail:** [exercises/03-networking.md](exercises/03-networking.md)

Loo custom network:
- Loo Docker network
- Käivita containerid samas network'is
- Testi hostname resolution
- Inspekteeri network

### Harjutus 4: Volumes (45 min)
**Fail:** [exercises/04-volumes.md](exercises/04-volumes.md)

Andmete säilitamine:
- Loo named volume
- Mount volume PostgreSQL'ile
- Testi andmete persistence
- Backup ja restore

### Harjutus 5: Optimization (45 min)
**Fail:** [exercises/05-optimization.md](exercises/05-optimization.md)

Optimeeri image suurust:
- Kasuta alpine base images
- Multi-stage build
- Layer caching
- .dockerignore
- Image security scan

---

## ⚡ Kiirstart Setup

### Variant A: Automaatne Seadistus (Soovitatud)

Käivita setup script, mis kontrollib kõik eeldused automaatselt:

```bash
# Käivita setup script
chmod +x setup.sh
./setup.sh
```

**Script teeb:**
- ✅ Kontrollib Docker'i paigaldust ja versiooni
- ✅ Kontrollib Docker daemon'i staatust
- ✅ Kontrollib vaba kettaruumi
- ✅ Testib Docker'i (hello-world)
- ✅ Valmistab ette töökeskkonna

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
ls ../apps/backend-nodejs
ls ../apps/frontend
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

### Kohustuslik (Lab 1 põhiulatus):

- [ ] **Docker image:**
  - [ ] `todo-service:1.0` (Java Spring Boot backend)
  - [ ] `todo-service:1.0-optimized` (multi-stage build)

- [ ] **Töötav container:**
  - [ ] Todo Service (port 8081)
  - [ ] PostgreSQL (port 5433)

- [ ] **Volume:**
  - [ ] `postgres-todos-data` (andmete säilitamine)

- [ ] **Network:**
  - [ ] `app-network` (container'ite omavaheline suhtlus)

- [ ] **Testimine:**
  - [ ] `GET /api/todos` töötab
  - [ ] `POST /api/todos` loob uue todo
  - [ ] `GET /health` tagastab OK

### Valikuline (tehakse Lab 2's):

- [ ] `user-service:1.0` (Node.js backend - töötab portil 3000)
- [ ] `frontend:1.0` (Nginx - töötab portil 8080)
- [ ] `postgres-users-data` volume (user-service jaoks)

---

## 📊 Progressi Jälgimine

- [ ] Harjutus 1: Single Container
- [ ] Harjutus 2: Multi-Container
- [ ] Harjutus 3: Networking
- [ ] Harjutus 4: Volumes
- [ ] Harjutus 5: Optimization

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

**Edu laboriga! 🚀**

*Sisustame selle labori exercises/ ja solutions/ kaustad hiljem.*

---

**Staatus:** 📝 Framework valmis, sisu lisatakse
**Viimane uuendus:** 2025-11-15
