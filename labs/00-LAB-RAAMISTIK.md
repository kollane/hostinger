# DevOps Praktiliste Laborite Raamistik

**Eesmärk:** Õppida DevOps administraatori töövoogu hands-on praktika kaudu
**Fookus:** DevOps/infrastruktuuri haldamine, mitte rakenduste arendamine
**Kuupäev:** 2025-11-15

---

## 📋 Ülevaade

See laboritöö kataloog sisaldab praktilisi harjutusi, mis põhinevad koolituskavas õpitud teemadel. Laborid on järjestatud nii, et iga järgmine labor kasutab eelmises laboris loodud komponente ja teadmisi.

---

## 🎯 Õpieesmärgid

Peale laborite läbimist oskad:

✅ **Dockeriga töötamine:**
- Luua ja hallata Docker image'id
- Käivitada ja hallata containereid
- Kasutada volumes ja networks
- Optimeerida image'id production'i jaoks

✅ **Kubernetes'ega töötamine:**
- Deploy'da rakendusi Kubernetes cluster'isse
- Hallata pods, deployments, services
- Konfigureerida ingress ja load balancing
- Kasutada ConfigMaps ja Secrets

✅ **CI/CD Pipeline:**
- Seadistada GitHub Actions
- Automatiseerida build ja deploy protsess
- Teostada automated testing
- Implement rolling updates

✅ **Monitoring ja Logging:**
- Seadistada Prometheus ja Grafana
- Koguda ja analüüsida logisid
- Seadistada alerting
- Troubleshoot production issues

---

## 🏗️ Laborite Arhitektuur

### Ülevaade Rakendustest

Laborites kasutame **koolituskavas välja töötatud** rakendusi (Peatükid 5-11), et luua reaalsele stsenaarium:

```
┌─────────────────────────────────────────────────────────────┐
│              User Management Frontend (Port 8080)           │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │ register.html│  │  login.html  │  │ dashboard.html  │   │
│  │              │  │              │  │ + profile.html  │   │
│  └──────────────┘  └──────────────┘  └─────────────────┘   │
│         HTML5 + CSS3 + Vanilla JavaScript                   │
│         JWT Token Management (LocalStorage)                 │
│         Fetch API + Async/Await                            │
└────────────────────────┬───────────────────────────────────┘
                         │
                         │ REST API (JWT Bearer Token)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│          Backend Node.js - User Service (Port 3000)         │
│  ┌────────────────────────────────────────────────────┐     │
│  │ /api/auth/register  - User registration            │     │
│  │ /api/auth/login     - JWT authentication           │     │
│  │ /api/users          - CRUD (pagination, search)    │     │
│  │ /api/users/me       - Profile management           │     │
│  │ /api/users/me/password - Password change           │     │
│  └────────────────────────────────────────────────────┘     │
│         Express.js + JWT + bcrypt + RBAC                    │
└────────────────────────┬───────────────────────────────────┘
                         │
                         │ SQL (pg + connection pool)
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│            PostgreSQL Database (Port 5432)                  │
│  ┌────────────────────────────────────────────────────┐     │
│  │ users table (id, name, email, password, role...)   │     │
│  │ - JWT authentication data                          │     │
│  │ - RBAC roles (user, admin)                         │     │
│  │ - Timestamps, indexes                              │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

**Reaalne Stsenaarium:**
- Kasutaja registreerib → Login → Dashboard → Profile Management
- JWT token-based authentication
- Role-based access control (tavakasutaja vs admin)
- Pagination, search, filtering
- Password change, profile update
- Täpselt nagu production süsteemis!

---

## 📂 Laborite Struktuur

```
labs/
│
├── 00-LAB-RAAMISTIK.md              # See fail - laborite ülevaade
│
├── apps/                             # Valmis rakendused (eelnevalt kirjutatud)
│   ├── backend-nodejs/               # Node.js + Express + PostgreSQL
│   │   ├── src/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   └── README.md
│   │
│   ├── backend-java-spring/          # Java Spring Boot + PostgreSQL
│   │   ├── src/
│   │   ├── Dockerfile
│   │   ├── pom.xml
│   │   └── README.md
│   │
│   └── frontend/                     # HTML + Vanilla JavaScript
│       ├── index.html
│       ├── css/
│       ├── js/
│       ├── Dockerfile
│       └── README.md
│
├── 01-docker-lab/                    # Labor 1: Docker Põhitõed
│   ├── README.md
│   ├── exercises/
│   │   ├── 01-single-container.md
│   │   ├── 02-multi-container.md
│   │   ├── 03-networking.md
│   │   ├── 04-volumes.md
│   │   └── 05-optimization.md
│   └── solutions/
│
├── 02-docker-compose-lab/            # Labor 2: Docker Compose
│   ├── README.md
│   ├── exercises/
│   │   ├── 01-basic-compose.md
│   │   ├── 02-full-stack.md
│   │   ├── 03-dev-prod-envs.md
│   │   └── 04-scaling.md
│   └── solutions/
│       └── docker-compose.yml
│
├── 03-kubernetes-basics-lab/        # Labor 3: Kubernetes Alused
│   ├── README.md
│   ├── exercises/
│   │   ├── 01-pods.md
│   │   ├── 02-deployments.md
│   │   ├── 03-services.md
│   │   ├── 04-configmaps-secrets.md
│   │   └── 05-persistent-volumes.md
│   └── manifests/
│
├── 04-kubernetes-advanced-lab/      # Labor 4: Kubernetes Täiustatud
│   ├── README.md
│   ├── exercises/
│   │   ├── 01-ingress.md
│   │   ├── 02-helm.md
│   │   ├── 03-autoscaling.md
│   │   ├── 04-rolling-updates.md
│   │   └── 05-monitoring.md
│   └── manifests/
│
├── 05-cicd-lab/                      # Labor 5: CI/CD Pipeline
│   ├── README.md
│   ├── exercises/
│   │   ├── 01-github-actions-basics.md
│   │   ├── 02-docker-build-push.md
│   │   ├── 03-kubernetes-deploy.md
│   │   ├── 04-automated-testing.md
│   │   └── 05-rollback-strategy.md
│   └── .github/
│       └── workflows/
│
└── 06-monitoring-logging-lab/       # Labor 6: Monitoring ja Logging
    ├── README.md
    ├── exercises/
    │   ├── 01-prometheus-setup.md
    │   ├── 02-grafana-dashboards.md
    │   ├── 03-log-aggregation.md
    │   ├── 04-alerting.md
    │   └── 05-troubleshooting.md
    └── configs/
```

---

## 🔧 Valmis Rakendused

### 1. Backend Node.js (User Service)

**Tehnoloogiad:** Node.js 18, Express, PostgreSQL
**Port:** 3000
**Andmebaas:** users (PostgreSQL port 5432)

**API Endpoints:**
- `GET /api/users` - Kõik kasutajad
- `GET /api/users/:id` - Konkreetne kasutaja
- `POST /api/users` - Loo kasutaja
- `PUT /api/users/:id` - Uuenda kasutajat
- `DELETE /api/users/:id` - Kustuta kasutaja
- `GET /health` - Health check

**Viited koolituskavale:**
- Peatükk 5: Node.js ja Express.js
- Peatükk 6: PostgreSQL integratsioon
- Peatükk 12: Docker põhimõtted

---

### 2. Backend Java Spring Boot (Todo Service)

**Tehnoloogiad:** Java 17, Spring Boot 3, PostgreSQL, Gradle
**Port:** 8081
**Andmebaas:** todos (PostgreSQL port 5433)

**API Endpoints:**
- `POST /api/todos` - Loo uus todo
- `GET /api/todos` - Kõik todo'd (pagination, filter)
- `GET /api/todos/{id}` - Konkreetne todo
- `PUT /api/todos/{id}` - Uuenda todo't
- `DELETE /api/todos/{id}` - Kustuta todo
- `PATCH /api/todos/{id}/complete` - Märgi tehtuks
- `GET /api/todos/stats` - Statistika
- `GET /health` - Health check
- `GET /swagger-ui.html` - API dokumentatsioon

**Viited koolituskavale:**
- Peatükk 12: Docker põhimõtted (Java container, multi-stage builds)

---

### 3. Frontend (Web UI)

**Tehnoloogiad:** HTML5, CSS3, Vanilla JavaScript
**Port:** 8080

**Funktsioonid:**
- Kasutajate haldamine (User Service API)
- Todo märkmete haldamine (Todo Service API)
- CRUD operatsioonid mõlema teenuse jaoks
- JWT autentimine
- Error handling
- Loading states

**Viited koolituskavale:**
- Peatükk 9: HTML5 ja CSS3
- Peatükk 10: Vanilla JavaScript
- Peatükk 11: Frontend ja Backend integratsioon

---

## 📚 Laborite Kirjeldused

### Labor 1: Docker Põhitõed (4h)

**Eesmärk:** Õppida Docker image'ite ja containerite haldamist

**Eeldused:**
- Peatükk 12: Docker põhimõtted läbitud
- Docker paigaldatud

**Teemad:**
1. **Single Container:** Üksiku rakenduse (Node.js backend) konteinerisatsioon
2. **Multi-Container:** Rakendus + PostgreSQL eraldi containerites
3. **Networking:** Container'ite omavaheline suhtlus
4. **Volumes:** Andmete säilitamine
5. **Optimization:** Image'i suuruse optimeerimine, multi-stage build

**Tulemus:** 3 töötavat Docker image'i (backend-nodejs, backend-java, frontend)

---

### Labor 2: Docker Compose (3h)

**Eesmärk:** Hallata mitme-konteineri rakendusi Docker Compose'iga

**Eeldused:**
- Labor 1 läbitud
- Peatükk 13: Docker Compose (tulevane)

**Teemad:**
1. **Basic Compose:** Lihtne docker-compose.yml
2. **Full-Stack:** Kõik teenused ühes compose file'is
3. **Dev/Prod Environments:** Erinevad keskkonna konfiguratsioonid
4. **Scaling:** Teenuste skaleerimine

**Tulemus:** Täielik docker-compose.yml fail, mis käivitab kogu süsteemi

---

### Labor 3: Kubernetes Alused (5h)

**Eesmärk:** Deploy'da rakendused Kubernetes cluster'isse

**Eeldused:**
- Labor 1 ja 2 läbitud (Docker image'd olemas)
- Peatükk 15-16: Kubernetes alused (tulevane)
- Minikube või K3s paigaldatud

**Teemad:**
1. **Pods:** Üksikute pod'ide loomine
2. **Deployments:** Deployment'ide haldamine
3. **Services:** Service'ide konfigureerimine (ClusterIP, NodePort, LoadBalancer)
4. **ConfigMaps & Secrets:** Konfiguratsioonide ja saladustega töötamine
5. **Persistent Volumes:** Andmete säilitamine Kubernetes'es

**Tulemus:** Töötav Kubernetes deployment kõigi kolme teenusega

---

### Labor 4: Kubernetes Täiustatud (5h)

**Eesmärk:** Kubernetes'e täiustatud funktsioonide kasutamine

**Eeldused:**
- Labor 3 läbitud
- Peatükk 17-19: Kubernetes täiustatud (tulevane)

**Teemad:**
1. **Ingress:** Ingress controller ja routing
2. **Helm:** Helm chart'ide loomine
3. **Autoscaling:** Horizontal Pod Autoscaling
4. **Rolling Updates:** Zero-downtime deployments
5. **Monitoring:** Metrics ja health checks

**Tulemus:** Production-ready Kubernetes deployment koos Helm chart'idega

---

### Labor 5: CI/CD Pipeline (4h)

**Eesmärk:** Automatiseerida build ja deploy protsess

**Eeldused:**
- Labor 1-4 läbitud
- Peatükk 20-21: CI/CD (tulevane)
- GitHub konto

**Teemad:**
1. **GitHub Actions Basics:** Workflow'de loomine
2. **Docker Build & Push:** Automatiseeritud image build
3. **Kubernetes Deploy:** Auto-deploy Kubernetes'e
4. **Automated Testing:** Unit ja integration testid
5. **Rollback Strategy:** Automaatne rollback ebaõnnestumisel

**Tulemus:** Täielik CI/CD pipeline GitHub Actions'is

---

### Labor 6: Monitoring ja Logging (4h)

**Eesmärk:** Seadistada monitoring ja logging production süsteemile

**Eeldused:**
- Labor 1-5 läbitud
- Peatükk 24: Monitoring (tulevane)

**Teemad:**
1. **Prometheus Setup:** Metrics'i kogumine
2. **Grafana Dashboards:** Visualiseerimine
3. **Log Aggregation:** Keskne logging (EFK stack)
4. **Alerting:** Alert'ide seadistamine
5. **Troubleshooting:** Debugging production issues

**Tulemus:** Täielik monitoring ja logging lahendus

---

## 🎓 Laborite Progressioon

```
Labor 1 (Docker)
    ↓
Lood 3 Docker image'i
    ↓
Labor 2 (Docker Compose)
    ↓
Kasutad Labor 1 image'id compose'is
    ↓
Labor 3 (Kubernetes Basics)
    ↓
Deploy'ad Labor 1 image'd Kubernetes'e
    ↓
Labor 4 (Kubernetes Advanced)
    ↓
Täiustad Labor 3 deployment'i
    ↓
Labor 5 (CI/CD)
    ↓
Automatiseerid Labor 1-4 protsessid
    ↓
Labor 6 (Monitoring)
    ↓
Monitoorid kõike, mis Labor 1-5 lõid
```

---

## 🛠️ Vajalikud Tööriistad

### Kohustuslikud:
- ✅ Docker ja Docker Compose
- ✅ kubectl
- ✅ Minikube või K3s (Kubernetes cluster)
- ✅ Git
- ✅ Text editor (VS Code soovitatud)

### Soovituslikud:
- 📦 Helm
- 📦 k9s (Kubernetes CLI UI)
- 📦 kubectx/kubens
- 📦 Docker Desktop (Windows/Mac)
- 📦 Lens (Kubernetes IDE)

### Online Tools:
- GitHub konto (CI/CD jaoks)
- Docker Hub konto (image registry)

---

## 📖 Viited Koolituskavale

Laborid põhinevad järgmistel peatükkidel:

| Labor | Seotud Peatükid |
|-------|----------------|
| **Labor 1** | Peatükk 12: Docker põhimõtted |
| **Labor 2** | Peatükk 13: Docker Compose |
| **Labor 3** | Peatükk 15-16: Kubernetes alused |
| **Labor 4** | Peatükk 17-19: Kubernetes täiustatud |
| **Labor 5** | Peatükk 20-21: CI/CD |
| **Labor 6** | Peatükk 24: Monitoring |

---

## 💡 Kuidas Laboreid Läbida

### 1. **Ettevalmistus:**
   - Loe läbi vastavad peatükid koolituskavast
   - Paigalda vajalikud tööriistad
   - Klooni laborite repositoorium

### 2. **Labori Läbimine:**
   - Loe labor README.md
   - Järgi step-by-step juhiseid
   - Proovi ise enne solutions'ite vaatamist
   - Testi kõiki komponente

### 3. **Kontrolli:**
   - Kas kõik teenused töötavad?
   - Kas API'd on kättesaadavad?
   - Kas andmed säilivad restart'i järel?
   - Kas logging töötab?

### 4. **Dokumenteeri:**
   - Tee märkmeid
   - Salvesta töötavad käsud
   - Kirjelda probleeme ja lahendusi

---

## 🎯 Õpitulemused

Peale kõigi laborite läbimist oskad:

✅ **DevOps Administraator Pädevused:**
- Konteinerite haldamine (Docker)
- Orkestratsioon (Kubernetes)
- CI/CD pipeline'ide seadistamine
- Monitoring ja troubleshooting
- Infrastructure as Code (Helm, YAML)
- GitOps workflow

✅ **Praktilised Oskused:**
- Deploy production-ready rakendusi
- Skaleerida teenuseid vastavalt koormusele
- Monitoorida süsteemi tervist
- Rollback'ida ebaõnnestunud deploymente
- Debuggida production issues

✅ **Töövoog:**
- Code → Build → Test → Deploy → Monitor
- GitOps workflow
- Incident response
- Capacity planning

---

## 📞 Küsimused ja Abi

Kui tekivad probleemid:

1. **Kontrolli Prerequisites:** Kas kõik tööriistad on paigaldatud?
2. **Vaata Solutions:** Iga labor sisaldab solutions/ kausta
3. **Debug:** Kasuta `docker logs`, `kubectl logs`, `kubectl describe`
4. **Dokumentatsioon:** Viited ametlikule dokumentatsioonile

---

## 🚀 Alustamine

1. **Loo laborite kaust:**
   ```bash
   cd ~/Documents/Meie\ pere/õppematerjal/hostinger/labs
   ```

2. **Alusta Labor 1'st:**
   ```bash
   cd 01-docker-lab
   cat README.md
   ```

3. **Järgi juhiseid ja naudi õppimist!**

---

**Edu laborite läbimisel! 🎓**

*Laborid on disainitud praktilise DevOps administraatori töövoo õppimiseks.*
*Iga labor ehitab eelmisele ja koos moodustavad tervikliku DevOps skillset'i.*

---

**Autor:** Koolituskava v1.0
**Viimane uuendus:** 2025-11-15
