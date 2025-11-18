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

```
┌──────────────────┐
│  Frontend        │
│  (nginx:alpine)  │
│  Port: 8080      │
└──────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────┐
│Node.js │ │ Java   │
│Backend │ │Backend │
│:3000   │ │:8081   │
└───┬────┘ └───┬────┘
    │          │
    ▼          ▼
┌────────┐ ┌────────┐
│Postgres│ │Postgres│
│:5432   │ │:5433   │
└────────┘ └────────┘
```

---

## 📂 Labori Struktuur

```
01-docker-lab/
├── README.md              # See fail
├── exercises/             # Harjutused
│   ├── 01-single-container.md
│   ├── 02-multi-container.md
│   ├── 03-networking.md
│   ├── 04-volumes.md
│   └── 05-optimization.md
└── solutions/             # Lahendused
    ├── backend-nodejs/
    │   └── Dockerfile
    ├── backend-java/
    │   └── Dockerfile
    └── frontend/
        └── Dockerfile
```

---

## 🔧 Eeldused

### Tööriistad:
- [x] Docker paigaldatud (`docker --version`)
- [x] Docker daemon töötab (`docker ps`)
- [x] Vähemalt 4GB vaba kettaruumi
- [x] Internet ühendus (image'ite allalaadimiseks)

### Teadmised:
- [x] Peatükk 12: Docker põhimõtted
- [x] Bash/terminal põhikäsud
- [x] Text editor kasutamine

---

## 📝 Harjutused

### Harjutus 1: Single Container (45 min)
**Fail:** [exercises/01-single-container.md](exercises/01-single-container.md)

Konteinerise Node.js backend:
- Loo Dockerfile
- Build image
- Käivita container
- Testi API
- Debug logs

### Harjutus 2: Multi-Container (60 min)
**Fail:** [exercises/02-multi-container.md](exercises/02-multi-container.md)

Käivita Node.js + PostgreSQL:
- Käivita PostgreSQL container
- Ühenda Node.js backend andmebaasiga
- Testi CRUD operatsioonid
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

## 🚀 Kiirstart

### 1. Kontrolli Eeldusi

```bash
# Docker versioon
docker --version

# Kas Docker töötab?
docker ps

# Testi Hello World
docker run hello-world
```

### 2. Valmista Ette Rakendused

```bash
# Mine apps kausta
cd ../apps

# Vaata rakendusi
ls -la
```

### 3. Alusta Harjutus 1'st

```bash
cd ../01-docker-lab
cat exercises/01-single-container.md
```

---

## ✅ Kontrolli Tulemusi

Peale labori läbimist pead omama:

- [ ] 3 töötavat Docker image'i:
  - [ ] `user-service:1.0` (Node.js backend)
  - [ ] `todo-service:1.0` (Java backend)
  - [ ] `frontend:1.0`

- [ ] Töötavad containerid:
  - [ ] Node.js backend - User Service (port 3000)
  - [ ] Java backend - Todo Service (port 8081)
  - [ ] Frontend (port 8080)
  - [ ] 2x PostgreSQL (ports 5432, 5433)

- [ ] Volumes:
  - [ ] `postgres-users-data`
  - [ ] `postgres-todos-data`

- [ ] Network:
  - [ ] `app-network`

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
