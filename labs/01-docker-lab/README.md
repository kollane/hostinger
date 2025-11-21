# Labor 1: Docker Põhitõed

**Kestus:** 4 tundi
**Eeldused:** Peatükk 12 (Docker põhimõtted) läbitud
**Eesmärk:** Õppida Docker piltide (images) ja konteinerite haldamist hands-on

---

## 📋 Ülevaade

Selles laboris õpid paigaldama kolme mikroteenust (services) konteineritesse, haldama andmehoidlaid (volumes) ja võrke (networks) ning optimeerima Docker pilte (images) production'i jaoks.

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

✅ Luua Dockerfile'e erinevatele rakendustele (applications)
✅ Ehitada (build) Docker pilte (images)
✅ Käivitada ja hallata konteinereid
✅ Seadistada Docker võrke (networks)
✅ Kasutada andmehoidlaid (volumes) andmete säilitamiseks
✅ Optimeerida pildi (image) suurust
✅ Kasutada mitme-sammulisi (multi-stage) builde

---

## 🏗️ Arhitektuur

**Lab 1 katab MÕLEMAD mikroteenust (services):**

```
┌────────────────────────┐        ┌────────────────────────┐
│   User Teenus (Service)         │        │   Todo Teenus (Service)         │
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

**Mikroteenuste (microservices) arhitektuur:**
- User Teenus (Service): JWT autentimine, kasutajate haldus
- Todo Teenus (Service): Ülesannete haldus, kasutab User Teenuse (Service) JWT tokeneid
- Eraldatud andmebaasid: igal teenusel (service) oma PostgreSQL instants

---

## 📂 Labori Struktuur

```
01-docker-lab/
├── README.md              # See fail
├── setup.sh               # Automaatne seadistus (setup) ja piltide (images) ehitamine
├── reset.sh               # Labori ressursside puhastamine
├── exercises/             # Harjutused (6 harjutust)
│   ├── 01a-single-container-nodejs.md        # User Teenus (Service) (Node.js)
│   ├── 01b-single-container-java.md          # Todo Teenus (Service) (Java)
│   ├── 02-multi-container.md                 # Mitme-teenuse (multi-service) + PostgreSQL
│   ├── 03-networking.md                      # Docker võrgud (networks)
│   ├── 04-volumes.md                         # Andmete säilitamine
│   └── 05-optimization.md                    # Mitme-sammulised (multi-stage) buildid
└── solutions/             # Lahendused
    ├── backend-nodejs/        # User Teenuse (Service) lahendused
    │   ├── Dockerfile             # Lihtne Dockerfile
    │   ├── Dockerfile.optimized   # Mitme-sammuline (multi-stage) build
    │   ├── .dockerignore          # Ehita (build) context optimeerimine
    │   └── healthcheck.js         # Seisukorra kontrolli (health check) skript
    └── backend-java-spring/   # Todo Teenuse (Service) lahendused
        ├── Dockerfile             # Lihtne Dockerfile
        ├── Dockerfile.optimized   # Mitme-sammuline (multi-stage) build
        └── .dockerignore          # Ehita (build) context optimeerimine
```

---

## 🔧 Eeldused

### Eelnevad labid:
- ❌ **Puuduvad** - See on esimene labor

### Tööriistad:
- [x] Docker paigaldatud (`docker --version`)
- [x] Docker daemon töötab (`docker ps`)
- [x] Vähemalt 4GB vaba kettaruumi
- [x] Internet ühendus (piltide (images) allalaadimiseks)

### Teadmised:
- [x] **Peatükk 12:** Docker põhimõtted ja konteineriseerimise alused
- [x] Bash/terminal põhikäsud
- [x] Text editor kasutamine (vim soovitatud)

---

## 📚 Progressiivne Õppetee

```
Labor 1 (Docker) ← Oled siin
  ↓ Docker pildid (images) →
Labor 2 (Compose)
  ↓ Mitme-konteineri (multi-container) kogemus →
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

### Harjutus 1A: Üksik Konteiner (Single Container) - User Teenus (Service) (45 min)
**Fail:** [exercises/01a-single-container-nodejs.md](exercises/01a-single-container-nodejs.md)

Konteineriseeri User Teenus (Service) (Node.js):
- Loo Dockerfile
- Ehita (build) user-service:1.0 pilt (image)
- Käivita konteiner
- Testi REST API (/api/auth/*, /api/users)
- Debug logs

### Harjutus 1B: Üksik Konteiner (Single Container) - Todo Teenus (Service) (45 min)
**Fail:** [exercises/01b-single-container-java.md](exercises/01b-single-container-java.md)

Konteineriseeri Todo Teenus (Service) (Java Spring Boot):
- Loo Dockerfile
- Ehita (build) JAR fail
- Ehita (build) todo-service:1.0 pilt (image)
- Käivita konteiner
- Testi REST API (/api/todos)

💡 **Kiirvalik:** Käivita `./setup.sh` ja vali `Y` → ehitab mõlemad pildid (images) automaatselt

### Harjutus 2: Mitme-Konteineri (Multi-Container) Seadistus (Setup) (90 min)
**Fail:** [exercises/02-multi-container.md](exercises/02-multi-container.md)

Käivita User Teenus (Service) + Todo Teenus (Service) + 2x PostgreSQL:
- Käivita 2 PostgreSQL konteinerit (portid 5432, 5433)
- Ühenda mõlemad teenused (services) oma andmebaasidega
- Testi mikroteenuste (microservices) suhtlust (JWT workflow)
- Troubleshoot connectivity

### Harjutus 3: Docker Võrgundus (Networking) (45 min)
**Fail:** [exercises/03-networking.md](exercises/03-networking.md)

Loo kohandatud võrk (custom network) (4 konteinerit):
- Loo todo-network
- Käivita kõik konteinerid samas võrgus (network)
- Testi DNS lahendust (resolution)
- Test End-to-End JWT workflow

### Harjutus 4: Docker Andmehoidlad (Volumes) (45 min)
**Fail:** [exercises/04-volumes.md](exercises/04-volumes.md)

Andmete säilitamine (2 andmehoidlat (volumes)):
- Loo postgres-user-data ja postgres-todo-data
- Paigalda (mount) andmehoidlad (volumes) PostgreSQL'idele
- Testi andmete püsivust (persistence)
- Backup ja restore mõlemast andmebaasist

### Harjutus 5: Pildi (Image) Optimeerimine (45 min)
**Fail:** [exercises/05-optimization.md](exercises/05-optimization.md)

Optimeeri mõlema teenuse (service) pildid (images):
- Node.js: Mitme-sammuline (multi-stage) ehitus (build) (200MB → 50MB)
- Java: Mitme-sammuline (multi-stage) ehitus (build) (370MB → 180MB)
- Seisukorra kontrollid (Health checks)
- Kihtide vahemälu (Layer caching)
- .dockerignore

---

## ⚡ Kiirstart Seadistus (Setup)

### Variant A: Automaatne Seadistus (Setup) (Soovitatud)

Käivita seadistus (setup) skript, mis kontrollib kõik eeldused ja valmistab labori ette:

```bash
# Käivita seadistus (setup) skript
chmod +x setup.sh
./setup.sh
```

**Script kontrollib:**
- ✅ Docker'i paigaldust ja versiooni
- ✅ Docker daemon'i staatust
- ✅ Vaba kettaruumi (>5GB soovitatud)
- ✅ Java ja Node.js olemasolu
- ✅ Rakenduste (applications) kättesaadavust
- ✅ Harjutuste ja lahenduste olemasolu

**Script pakub:**
- 💡 Automaatset baaspiltide (base images) ehitamist (`user-service:1.0`, `todo-service:1.0`)
- 💡 Võimalust vahele jätta Harjutus 1 ja alustada otse Harjutus 2'st

**Kuidas kasutada:**

```bash
./setup.sh

# Kui küsitakse: "Kas soovid ehitada baaspilte (base images) KOHE?"
# Vali Y → Ehitab pildid (images) automaatselt (~2-5 min)
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
- 🗑️ Kõik Lab 1 konteinerid (user-service*, todo-service*, postgres-*)
- 🗑️ Lab 1 võrgud (networks) (todo-network)
- 🗑️ Lab 1 andmehoidlad (volumes) (postgres-user-data, postgres-todo-data)
- 🗑️ Apps kaustadest harjutuste failid (Dockerfile, .dockerignore)

**Interaktiivne valik: Piltide (Images) Kustutamine**

Script küsib, kas kustutada ka Docker pildid (images):

```
Kas soovid kustutada ka Docker pilte (images)?
  [N] Ei, jäta base pildid (images) alles (user-service:1.0, todo-service:1.0)
      → Saad alustada otse Harjutus 2'st ilma uuesti ehitamata (build)
      → Kiire restart Harjutuste 2-5 jaoks
  [Y] Jah, kustuta KÕIK pildid (images) (täielik reset)
      → Pead alustama Harjutus 1'st ja ehitama (build) pilte (images) uuesti
      → Täielik "puhas leht" algusest
```

**Kasutusstsenaariume:**

```bash
# Stsenaarium 1: Kiire restart (säilita pildid (images))
./reset.sh
# Vali: N
# → Konteinerid/võrgud (networks)/andmehoidlad (volumes) kustutatakse
# → Baaspildid (base images) säilitatakse
# → Alusta uuesti Harjutus 2'st või 3'st

# Stsenaarium 2: Täielik reset (kustuta kõik)
./reset.sh
# Vali: Y
# → Kõik kustutatakse (sh pildid (images))
# → Alusta päris algusest (Harjutus 1)

# Stsenaarium 3: Automaatne reset (sh pildid (images))
echo "y" | ./reset.sh  # Kustutab KÕIK
```

---

### Variant B: Manuaalne Seadistus (Setup)

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

# Kontrolli rakenduste (applications) kättesaadavust
ls ../apps/backend-java-spring
ls ../apps/backend-nodejs  # Lab 2 jaoks
ls ../apps/frontend  # Lab 2 jaoks
```

#### 4. Alusta Harjutus 1'st

```bash
cat exercises/01a-single-container-nodejs.md
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

### Docker Pildid (Images):

- [ ] `user-service:1.0` (Node.js backend, ~200MB)
- [ ] `user-service:1.0-optimized` (mitme-sammuline (multi-stage) build, ~50MB)
- [ ] `todo-service:1.0` (Java Spring Boot backend, ~370MB)
- [ ] `todo-service:1.0-optimized` (mitme-sammuline (multi-stage) build, ~180MB)

### Töötavad Konteinerid (Harjutus 4 lõpus):

- [ ] User Teenus (Service) (port 3000)
- [ ] Todo Teenus (Service) (port 8081)
- [ ] PostgreSQL User DB (port 5432)
- [ ] PostgreSQL Todo DB (port 5433)

### Andmehoidlad (Volumes):

- [ ] `postgres-user-data` (kasutajate andmebaas)
- [ ] `postgres-todo-data` (ülesannete andmebaas)

### Võrk (Network):

- [ ] `todo-network` (kohandatud silla (bridge) võrk (network))

### Testimine:

**User Teenus (Service):**
- [ ] `POST /api/auth/register` - kasutaja registreerimine
- [ ] `POST /api/auth/login` - JWT token genereerimine
- [ ] `GET /api/users` - kasutajate nimekiri (vajab JWT)
- [ ] `GET /health` - tagastab OK

**Todo Teenus (Service):**
- [ ] `POST /api/todos` - loo todo (vajab User Teenuse (Service) JWT)
- [ ] `GET /api/todos` - loe todos
- [ ] `PATCH /api/todos/:id/complete` - märgi tehtud
- [ ] `DELETE /api/todos/:id` - kustuta
- [ ] `GET /health` - tagastab OK

**End-to-End JWT Workflow:**
- [ ] User Teenus (Service) genereerib JWT token
- [ ] Todo Teenus (Service) valideerib sama JWT token'it
- [ ] Mikroteenuste (microservices) suhtlus toimib

---

## 📊 Progressi Jälgimine

- [ ] Harjutus 1A: Üksik Konteiner (Single Container) (User Teenus (Service) - Node.js)
- [ ] Harjutus 1B: Üksik Konteiner (Single Container) (Todo Teenus (Service) - Java)
- [ ] Harjutus 2: Mitme-Konteineri (Multi-Container) (2 teenust (services) + 2 DB)
- [ ] Harjutus 3: Võrgundus (Networking) (Kohandatud võrk (custom network), 4 konteinerit)
- [ ] Harjutus 4: Andmehoidlad (Volumes) (Andmete püsivus (data persistence), 2 andmehoidlat (volumes))
- [ ] Harjutus 5: Optimeerimine (Optimization) (Mitme-sammulised (multi-stage) buildid, 2 teenust (services))

---

## 🆘 Troubleshooting

### Konteiner ei käivitu?
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

### Pildi (image) ehitus (build) ebaõnnestub?
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
- ✅ Konteineriseerinud 2 mikroteenust (microservices) (Node.js ja Java)
- ✅ Loonud 4 Docker pilti (images) (2 lihtsat + 2 optimeeritud)
- ✅ Hallanud mitme-konteineri (multi-container) süsteemi (4 konteinerit)
- ✅ Kasutanud Docker võrke (networks) ja andmehoidlaid (volumes)
- ✅ Testinud End-to-End mikroteenuste (microservices) suhtlust
- ✅ Optimeerinud pildi (image) suurust (kuni 75% väiksemad!)

**Edu laboriga! 🚀**

---

## 📌 Lisainfo

**Abiskriptid:**
- `./setup.sh` - Automaatne seadistus (setup) ja piltide (images) ehitamine
- `./reset.sh` - Labori ressursside puhastamine

**Harjutused:**
- 6 harjutust: 2x Üksik Konteiner (Single Container), Mitme-Konteineri (Multi-Container), Võrgundus (Networking), Andmehoidlad (Volumes), Optimeerimine (Optimization)
- Kokku: ~4.5 tundi

**Staatus:** ✅ 100% valmis
**Viimane uuendus:** 2025-11-19
