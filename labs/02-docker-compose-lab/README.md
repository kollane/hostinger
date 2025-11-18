# Labor 2: Docker Compose

**Kestus:** 3 tundi
**Eeldused:** Labor 1 läbitud, Peatükk 13 (Docker Compose)
**Eesmärk:** Ühenda kõik kolm mikroteenust Docker Compose'iga

---

## 📋 Ülevaade

Selles laboris ühendad kõik kolm mikroteenust (**Todo Service, User Service, Frontend**) üheks täisfunktsionaalseks rakenduseks Docker Compose'i abil.

Lab 2 lõpuks on sul valmis terve süsteem, mida saad Lab 3's Kubernetes'esse deploy'da.

---

## 🏗️ Arhitektuur

**Täielik mikroteenuste süsteem:**

```
┌──────────────────────────────────────────────────┐
│           Docker Compose Network                 │
│                                                  │
│   ┌─────────────┐                                │
│   │  Frontend   │  Port: 8080                    │
│   │  (Nginx)    │  UI for users                  │
│   └──────┬──────┘                                │
│          │                                        │
│     ┌────┴────┐                                  │
│     │         │                                   │
│     ▼         ▼                                   │
│  ┌─────┐   ┌─────┐                               │
│  │User │   │Todo │                               │
│  │Svc  │   │Svc  │                               │
│  │:3000│   │:8081│                               │
│  └──┬──┘   └──┬──┘                               │
│     │         │                                   │
│     ▼         ▼                                   │
│  ┌─────┐   ┌─────┐                               │
│  │PG   │   │PG   │                               │
│  │:5432│   │:5433│                               │
│  └─────┘   └─────┘                               │
│   users      todos                                │
└──────────────────────────────────────────────────┘
```

**Teenused:**
- **Frontend**: Nginx serving HTML/CSS/JS → Suhtleb mõlema backend'iga
- **User Service**: Node.js + Express → Autentimine, kasutajate haldus
- **Todo Service**: Java Spring Boot → Todo CRUD operatsioonid (Lab 1'st)
- **PostgreSQL x2**: Eraldi andmebaasid users ja todos jaoks

---

## 🎯 Õpieesmärgid

✅ Luua docker-compose.yml kõigi kolme teenuse jaoks
✅ Hallata mitut teenust korraga
✅ Konfigureerida networks ja volumes Compose'is
✅ Ühenda Frontend mõlema backend'iga
✅ Luua erinevaid keskkonna konfiguratsioone (dev, prod)
✅ Skaleerida teenuseid

---

## 📂 Labori Struktuur

```
02-docker-compose-lab/
├── README.md
├── exercises/
│   ├── 01-basic-compose.md
│   ├── 02-full-stack.md
│   ├── 03-dev-prod-envs.md
│   └── 04-scaling.md
└── solutions/
    ├── docker-compose.yml
    ├── docker-compose.dev.yml
    └── docker-compose.prod.yml
```

---

## 🔧 Eeldused

### Eelnevad labid:
- [x] **Labor 1: Docker Põhitõed** - KOHUSTUSLIK
  - **PEAB olema Lab 1'st:**
    - `todo-service:1.0` (Java Spring Boot backend image - LAB 1 PÕHIFOOKUS)
    - Docker käskude põhitundmine (docker run, docker build)
    - Networks ja volumes kogemus
  - **Setup script build'ib automaatselt:**
    - `user-service:1.0` (Node.js backend image - lisatakse Lab 2's)
    - `frontend:1.0` (Nginx frontend image - lisatakse Lab 2's)

### Tööriistad:
- [x] Docker Compose paigaldatud (`docker compose version` - v2.x)
- [x] Docker daemon töötab (`docker ps`)
- [x] Vähemalt 4GB vaba RAM
- [x] Internet ühendus

### Teadmised:
- [x] **Labor 1:** Docker põhitõed (image build, containers, networks, volumes)
- [x] **Peatükk 13:** Docker Compose põhimõtted ja YAML süntaks
- [x] YAML failivorming

---

## 📚 Progressiivne Õppetee

```
Labor 1 (Docker)
  ↓ Docker image'd →
Labor 2 (Compose) ← Oled siin
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

## ⚡ Kiirstart Setup

### Variant A: Automaatne Seadistus (Soovitatud)

Käivita setup script, mis kontrollib ja loob kõik vajalikud eeldused:

```bash
# Käivita setup script
chmod +x setup.sh
./setup.sh
```

**Script teeb:**
- ✅ Kontrollib Docker Compose paigaldust
- ✅ Kontrollib Lab 1 image'ite olemasolu
- ✅ Build'ib puuduvad image'd automaatselt
- ✅ Valmistab ette töökeskkonna

---

### Variant B: Manuaalne Seadistus

#### 1. Kontrolli Docker Compose

```bash
# Docker Compose versioon (v2.x)
docker compose version

# Kui puudub
sudo apt install docker-compose-plugin
```

#### 2. Kontrolli Lab 1 Image

```bash
# Kontrolli Lab 1 kohustuslikku image'i
docker images | grep "todo-service"
```

**Kui todo-service:1.0 puudub:**

```bash
# Todo Service (LAB 1 KOHUSTUSLIK!)
cd ../apps/backend-java-spring
docker build -t todo-service:1.0 .
cd ../../02-docker-compose-lab
```

#### 3. Build'i Täiendavad Image'd Lab 2 Jaoks

Setup script build'ib need automaatselt, aga saad ka käsitsi:

```bash
# User Service (lisame Lab 2's)
cd ../apps/backend-nodejs
docker build -t user-service:1.0 .

# Frontend (lisame Lab 2's)
cd ../apps/frontend
docker build -t frontend:1.0 .

# Tagasi Lab 2'sse
cd ../../02-docker-compose-lab
```

#### 4. Alusta Harjutustega

```bash
cat exercises/01-basic-compose.md
```

---

### ⚡ Kiirkontroll: Kas Oled Valmis?

```bash
# Kiirkontroll
docker compose version && \
docker images | grep -E "user-service|frontend" && \
echo "✅ Kõik eeldused on täidetud!"
```

---

**Staatus:** 📝 Framework valmis, sisu lisatakse
**Viimane uuendus:** 2025-11-15
