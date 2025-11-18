# DevOps Praktilised Laborid

**Hands-On DevOps Training Labs**

---

## 🎯 Ülevaade

See kaust sisaldab praktilisi laboreid DevOps administraatorite koolitamiseks. Laborid põhinevad koolituskavas õpitud teemadel ja keskenduvad **praktilistele DevOps oskustele**, mitte rakenduste arendamisele.

---

## 📚 Laborite Loend

| # | Labor | Kestus | Eeldused | Staatus |
|---|-------|--------|----------|---------|
| **0** | [Laborite Raamistik](00-LAB-RAAMISTIK.md) | - | - | ✅ Valmis |
| **1** | [Docker Põhitõed](01-docker-lab/) | 4h | Peatükk 12 | ✅ Valmis |
| **2** | [Docker Compose](02-docker-compose-lab/) | 3h | Labor 1, Peatükk 13 | ✅ Valmis |
| **3** | [Kubernetes Alused](03-kubernetes-basics-lab/) | 5h | Labor 1-2, Peatükk 15-16 | ✅ Valmis |
| **4** | [Kubernetes Täiustatud](04-kubernetes-advanced-lab/) | 5h | Labor 3, Peatükk 17-19 | ✅ Valmis |
| **5** | [CI/CD Pipeline](05-cicd-lab/) | 4h | Labor 1-4, Peatükk 20-21 | ✅ Valmis |
| **6** | [Monitoring & Logging](06-monitoring-logging-lab/) | 4h | Labor 1-5, Peatükk 24 | ✅ Valmis |

**Kokku:** 25 tundi hands-on praktikat

---

## 🏗️ Laborite Arhitektuur

Kõik laborid kasutavad samu kolme mikroteenust:

```
┌──────────────────────────────────────────────────┐
│               Frontend (Port 8080)               │
│            HTML + Vanilla JavaScript             │
└──────────────┬──────────────────┬────────────────┘
               │                  │
               ▼                  ▼
┌──────────────────────┐   ┌──────────────────────┐
│  Node.js Backend     │   │ Java Spring Backend  │
│   User Service       │   │   Todo Service       │
│    (Port 3000)       │   │    (Port 8081)       │
└──────────┬───────────┘   └──────────┬───────────┘
           │                          │
           ▼                          ▼
┌──────────────────────┐   ┌──────────────────────┐
│  PostgreSQL          │   │  PostgreSQL          │
│   users DB           │   │   todos DB           │
│   (Port 5432)        │   │   (Port 5433)        │
└──────────────────────┘   └──────────────────────┘
```

---

## 🚀 Kiirstart

### 1. Vaata Laborite Raamistikku

```bash
cd labs
cat 00-LAB-RAAMISTIK.md
```

### 2. Kontrolli Eeldused

**Kohustuslikud tööriistad:**
- Docker & Docker Compose
- kubectl
- Minikube või K3s
- Git
- Text editor

**Kontrolli installatsioone:**
```bash
docker --version
docker compose version
kubectl version --client
minikube version  # või k3s --version
git --version
```

### 3. Alusta Labor 1'st

```bash
cd 01-docker-lab
cat README.md
```

---

## 📂 Kataloogistruktuur

```
labs/
├── README.md                      # See fail
├── 00-LAB-RAAMISTIK.md           # Laborite ülevaade ja plaan
│
├── apps/                          # Valmis rakendused
│   ├── backend-nodejs/            # Node.js + Express + PostgreSQL
│   ├── backend-java-spring/      # Java Spring Boot + PostgreSQL
│   └── frontend/                  # HTML + JS + CSS
│
├── 01-docker-lab/                 # Docker hands-on
├── 02-docker-compose-lab/         # Docker Compose hands-on
├── 03-kubernetes-basics-lab/      # Kubernetes alused
├── 04-kubernetes-advanced-lab/    # Kubernetes täiustatud
├── 05-cicd-lab/                   # CI/CD Pipeline
└── 06-monitoring-logging-lab/     # Monitoring & Logging
```

---

## 🎓 Õpieesmärgid

Peale laborite läbimist oskad:

### DevOps Administraatori Oskused:
✅ Konteinerite haldamine (Docker)
✅ Orkestratsioon (Kubernetes)
✅ CI/CD pipeline'ide seadistamine
✅ Monitoring ja logging
✅ Infrastructure as Code
✅ GitOps workflow

### Praktilised Pädevused:
✅ Deploy production-ready rakendusi
✅ Skaleerida teenuseid
✅ Monitoorida süsteemi tervist
✅ Rollback'ida deploymente
✅ Debuggida production issues

---

## 📖 Seosed Koolituskavaga

Laborid toetuvad järgmistele peatükkidele:

- **Peatükk 12:** Docker põhimõtted → Labor 1
- **Peatükk 13:** Docker Compose → Labor 2
- **Peatükk 15-16:** Kubernetes alused → Labor 3
- **Peatükk 17-19:** Kubernetes täiustatud → Labor 4
- **Peatükk 20-21:** CI/CD → Labor 5
- **Peatükk 24:** Monitoring → Labor 6

---

## 💡 Soovitatud Töövoog

1. **Õpi Teooria:** Loe läbi vastav peatükk koolituskavast
2. **Prakiseeri:** Tee läbi vastav labor hands-on
3. **Eksperimenteeri:** Muuda konfiguratsioone, testi erinevaid stsenaariume
4. **Dokumenteeri:** Tee märkmeid ja salvesta töötavad käsud

---

## 🔑 Olulised Märkmed

### Laborite Disain:
- **Hands-on fookus:** Kõik laborid on praktilised
- **DevOps pädevused:** Ei keskendu koodiarendusele
- **Järjestikused laborid:** Iga labor ehitab eelmisele
- **Valmis rakendused:** Apps on eelnevalt kirjutatud, fookus on DevOps'il

### Valmis Rakendused:
Kõik kolm mikroteenust on **eelnevalt valmis kirjutatud**:
- Backend Node.js (User Service)
- Backend Java Spring (Todo Service)
- Frontend (Web UI)

**Sina (DevOps admin) tegeleb:**
- Dockerizing
- Orchestration
- Deployment
- Monitoring
- CI/CD

---

## 🆘 Abi ja Tugi

Kui tekivad probleemid:

1. **Kontrolli README.md** - Iga labor sisaldab detailset dokumentatsiooni
2. **Vaata Solutions** - `solutions/` kaustas on töötavad näidised
3. **Debug Logs:**
   - Docker: `docker logs <container>`
   - Kubernetes: `kubectl logs <pod>`
4. **Viited Koolituskavale** - Tagasi teooriale vajadusel

---

## 📊 Progress Tracking

Märgi ära läbitud laborid:

- [ ] Labor 0: Raamistik läbi loetud
- [ ] Labor 1: Docker Põhitõed
- [ ] Labor 2: Docker Compose
- [ ] Labor 3: Kubernetes Alused
- [ ] Labor 4: Kubernetes Täiustatud
- [ ] Labor 5: CI/CD Pipeline
- [ ] Labor 6: Monitoring & Logging

---

## 🎯 Järgmised Sammud

1. Loe läbi [00-LAB-RAAMISTIK.md](00-LAB-RAAMISTIK.md)
2. Kontrolli eeldusi (Docker, kubectl, jne)
3. Alusta Labor 1'st

---

**Edu ja head õppimist! 🚀**

*Laborid on disainitud praktilise DevOps administraatori töövoo õppimiseks.*

---

**Viimane uuendus:** 2025-11-15
