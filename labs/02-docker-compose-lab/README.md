# Labor 2: Docker Compose

**Kestus:** 3 tundi
**Eeldused:** Labor 1 läbitud, Peatükk 13 (Docker Compose)
**Eesmärk:** Hallata mitme-konteineri rakendusi Docker Compose'iga

---

## 📋 Ülevaade

Selles laboris õpid kasutama Docker Compose'i, et hallata kõiki teenuseid ühe YAML failiga. Kasutad Labor 1'st loodud Docker image'id.

---

## 🎯 Õpieesmärgid

✅ Luua docker-compose.yml faile
✅ Hallata mitut teenust korraga
✅ Konfigureerida networks ja volumes Compose'is
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
  - Vaja on Labor 1'st loodud Docker image'e:
    - `user-service:1.0` (Node.js backend)
    - `todo-service:1.0` (Java backend - optional)
    - `frontend:1.0`
  - Docker käskude põhitundmine (docker run, docker build)
  - Networks ja volumes kogemus

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

#### 2. Kontrolli Lab 1 Image'd

```bash
# Kontrolli olemasolevaid image'e
docker images | grep -E "user-service|todo-service|frontend"
```

**Kui image'd puuduvad, build'i Lab 1'st:**

```bash
# User Service
cd ../apps/backend-nodejs
docker build -t user-service:1.0 .

# Frontend
cd ../frontend
docker build -t frontend:1.0 .

# Tagasi Lab 2'sse
cd ../../02-docker-compose-lab
```

#### 3. Alusta Harjutustega

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
