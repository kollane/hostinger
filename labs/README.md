# DevOps Praktilised Laborid

**Hands-On DevOps Training Program** - 10 laborit, 45 tundi praktilisi oskusi

---

## 🚀 Kiirstart

Tere tulemast DevOps praktiliste laborite juurde! See on **praktiline õppeprogramm**, mis õpetab tõelisi DevOps administraatori oskusi hands-on harjutuste kaudu.

**Kuidas alustada:**

1. **Kontrolli eeldused** - Docker, kubectl, Minikube/K3s, Git
2. **Loe see README läbi** - Saa ülevaade kõigist laboritest
3. **Alusta Lab 1'st** - `cd 01-docker-lab && cat README.md`

**Fookus:** DevOps/infrastruktuuri haldamine, mitte rakenduste arendamine
**Rakendused:** Kolm valmis mikroteenust (user-service, todo-service, frontend)
**Sinu roll:** DevOps admin - dockerizing, orchestration, deployment, monitoring, security

---

## 📋 Laborite Ülevaade

**Kokku: 10 laborit, 45 tundi praktilisi harjutusi**

| # | Labor | Kestus | Eeldused | Staatus |
|---|-------|--------|----------|---------|
| **1** | [Docker Põhitõed](01-docker-lab/) | 4h | Peatükk 12 | ✅ Valmis |
| **2** | [Docker Compose](02-docker-compose-lab/) | 3h | Lab 1, Peatükk 13 | ✅ Valmis |
| **3** | [Kubernetes Alused](03-kubernetes-basics-lab/) | 5h | Lab 1-2, Peatükk 15-16 | ✅ Valmis |
| **4** | [Kubernetes Täiustatud](04-kubernetes-advanced-lab/) | 5h | Lab 3, Peatükk 17-19 | ✅ Valmis |
| **5** | [CI/CD Pipeline](05-cicd-lab/) | 4h | Lab 1-4, Peatükk 20-21 | ✅ Valmis |
| **6** | [Monitoring & Logging](06-monitoring-logging-lab/) | 4h | Lab 1-5, Peatükk 24 | ✅ Valmis |
| **7** | [Security & Secrets](07-security-secrets-lab/) | 5h | Lab 1-6, Peatükk 25 | ✅ Valmis |
| **8** | [GitOps with ArgoCD](08-gitops-argocd-lab/) | 5h | Lab 1-7 | ✅ Valmis |
| **9** | [Backup & Disaster Recovery](09-backup-disaster-recovery-lab/) | 5h | Lab 1-8 | ✅ Valmis |
| **10** | [Terraform Infrastructure as Code](10-terraform-iac-lab/) | 5h | Lab 1-9 | ✅ Valmis |

### Laborite Grupid

**📦 Põhikursus (Lab 1-6, 25h):**
- Docker konteinerite haldamine
- Kubernetes orkestratsioon
- CI/CD automatiseerimine
- Monitoring ja logging

**🔒 Täiustatud kursus (Lab 7-10, 20h):**
- Security ja secrets management
- GitOps deployment patterns
- Backup ja disaster recovery
- Infrastructure as Code

---

## 🏗️ Mikroteenuste Arhitektuur

Kõik laborid kasutavad sama kolme mikroteenust:

```
┌──────────────────────────────────────────────────────────┐
│               Frontend (Port 8080)                       │
│         HTML5 + CSS3 + Vanilla JavaScript                │
│         UI: Login, TODO list, User management            │
└──────────────┬────────────────────┬──────────────────────┘
               │                    │
               │ REST API           │ REST API
               ▼                    ▼
┌───────────────────────┐  ┌───────────────────────────┐
│  User Service         │  │  Todo Service             │
│  (Node.js + Express)  │  │  (Java Spring Boot)       │
│  Port 3000            │  │  Port 8081                │
│                       │  │                           │
│  Funktsioonid:        │  │  Funktsioonid:            │
│  • Registreerimine    │  │  • TODO CRUD              │
│  • JWT autentimine    │  │  • Filtreerimine          │
│  • Kasutajahaldus     │  │  • Statistika             │
│  • RBAC (user/admin)  │  │  • JWT validatsioon       │
└──────────┬────────────┘  └──────────┬────────────────┘
           │                          │
           │ SQL                      │ SQL
           ▼                          ▼
┌───────────────────────┐  ┌───────────────────────────┐
│  PostgreSQL           │  │  PostgreSQL               │
│  users DB (5432)      │  │  todos DB (5433)          │
│                       │  │                           │
│  Tabelid:             │  │  Tabelid:                 │
│  • users              │  │  • todos                  │
│    - id, name, email  │  │    - id, user_id, title   │
│    - password_hash    │  │    - description          │
│    - role, timestamps │  │    - completed, priority  │
└───────────────────────┘  └───────────────────────────┘
```

**Reaalne stsenaarium:**
- Kasutaja registreerib → Login → Vaata TODOsid → Lisa/muuda/kustuta
- JWT token-based authentication
- Role-based access control (user vs admin)
- Mikroteenuste vaheline suhtlus
- Production-like arhitektuur!

---

## 🎯 Õpieesmärgid

### DevOps Administraatori Oskused

Peale kõigi laborite läbimist oskad:

✅ **Konteinerite haldamine:**
- Luua ja optimeerida Docker image'id
- Hallata containereid ja volumes
- Kasutada Docker Compose multi-container rakenduste jaoks

✅ **Kubernetes orkestratsioon:**
- Deploy'da rakendusi Kubernetes cluster'isse
- Hallata Pods, Deployments, Services, Ingress
- Konfigureerida ConfigMaps, Secrets, PersistentVolumes
- Kasutada Helm chart'e

✅ **CI/CD automatiseerimine:**
- Seadistada GitHub Actions workflows
- Automatiseerida build, test, deploy protsess
- Implementeerida rolling updates
- Teostada automated quality gates

✅ **Monitoring ja Logging:**
- Seadistada Prometheus ja Grafana
- Koguda application metrics
- Agregeerida ja analüüsida logisid
- Seadistada alerting rules

✅ **Security:**
- Hallata secrets (Vault, Sealed Secrets)
- Konfigureerida RBAC access control
- Implementeerida Network Policies
- Skaneerida vulnerabilities (Trivy)

✅ **GitOps:**
- Deploy'da rakendusi ArgoCD'ga
- Hallata multi-environment setups (dev, staging, prod)
- Kasutada Kustomize overlays
- Implementeerida progressive delivery (Canary)

✅ **Disaster Recovery:**
- Luua backups Velero'ga
- Teostada disaster recovery drills
- Migreerida applications cross-cluster
- Seadistada automated backup schedules

✅ **Infrastructure as Code:**
- Provision'ida Kubernetes resources Terraform'iga
- Luua reusable Terraform modules
- Manage'ida Terraform state
- Integreerida IaC CI/CD workflow'ga

---

## 📚 Detailsed Labori Kirjeldused

### Lab 1: Docker Põhitõed (4h)

**Eesmärk:** Õppida Docker image'ite ja containerite haldamist

**Teemad:**
- Single container rakendused (Node.js, Java Spring)
- Multi-container setup (rakendus + PostgreSQL)
- Container networking
- Data persistence (volumes)
- Image optimization (multi-stage builds)

**Tulemus:** 3 optimeeritud Docker image'i (user-service, todo-service, frontend)

---

### Lab 2: Docker Compose (3h)

**Eesmärk:** Hallata mitme-konteineri rakendusi Docker Compose'iga

**Teemad:**
- Basic docker-compose.yml struktuur
- Full-stack setup (kõik teenused koos)
- Environment management (dev vs prod)
- Database migrations
- Production patterns

**Tulemus:** Täielik docker-compose.yml, mis käivitab kogu süsteemi

---

### Lab 3: Kubernetes Alused (5h)

**Eesmärk:** Deploy'da rakendused Kubernetes cluster'isse

**Teemad:**
- Pods ja cluster setup
- Deployments ja ReplicaSets
- Services (ClusterIP, NodePort, LoadBalancer)
- ConfigMaps ja Secrets
- Persistent storage
- Init containers ja migrations

**Tulemus:** Töötav Kubernetes deployment kõigi kolme teenusega

---

### Lab 4: Kubernetes Täiustatud (5h)

**Eesmärk:** Kubernetes'e täiustatud funktsioonide kasutamine

**Teemad:**
- Ingress controller ja routing
- Horizontal Pod Autoscaling
- Rolling updates (zero-downtime)
- Resource limits ja quotas
- Helm chart'ide loomine

**Tulemus:** Production-ready Kubernetes deployment koos Helm chart'idega

---

### Lab 5: CI/CD Pipeline (4h)

**Eesmärk:** Automatiseerida build ja deploy protsess

**Teemad:**
- GitHub Actions workflows
- Docker image build ja push (automated)
- Helm deployment automation
- Quality gates (testing, linting)
- Production pipeline patterns

**Tulemus:** Täielik CI/CD pipeline GitHub Actions'is

---

### Lab 6: Monitoring & Logging (4h)

**Eesmärk:** Seadistada monitoring ja logging production süsteemile

**Teemad:**
- Prometheus setup ja configuration
- Application metrics (custom metrics)
- Grafana dashboards
- Alerting rules
- Log aggregation (Loki)

**Tulemus:** Täielik monitoring stack (Prometheus + Grafana + Loki)

---

### Lab 7: Security & Secrets Management (5h)

**Eesmärk:** Implementeerida production-ready security

**Teemad:**
- HashiCorp Vault secrets management
- Kubernetes RBAC (Roles, RoleBindings)
- Network Policies (zero-trust networking)
- Security scanning (Trivy)
- Sealed Secrets (encrypted secrets in Git)

**Tulemus:** Production-ready security stack koos Vault ja RBAC'ga

---

### Lab 8: GitOps with ArgoCD (5h)

**Eesmärk:** Implementeerida GitOps deployment workflow

**Teemad:**
- ArgoCD setup ja configuration
- Git-based deployment workflow
- Multi-environment management (Kustomize)
- ApplicationSet (dynamic Applications)
- Progressive delivery (Canary deployments, Argo Rollouts)

**Tulemus:** Täielik GitOps workflow kus Git on single source of truth

---

### Lab 9: Backup & Disaster Recovery (5h)

**Eesmärk:** Implementeerida backup ja disaster recovery strateegia

**Teemad:**
- Velero setup (Kubernetes backup tool)
- Application backups (manifests + PersistentVolumes)
- Scheduled backups ja retention policies
- Disaster recovery drills
- Cross-cluster migration

**Tulemus:** Automated backup workflow koos tested disaster recovery plan'iga

---

### Lab 10: Terraform Infrastructure as Code (5h)

**Eesmärk:** Provision'ida infrastructure Terraform'iga (IaC)

**Teemad:**
- Terraform basics (HCL, providers, state)
- Kubernetes resources via Terraform
- Terraform modules (DRY principle)
- State management (local vs remote)
- GitOps for infrastructure (Terraform + ArgoCD)

**Tulemus:** Infrastructure as Code setup kus kogu infrastruktuur on version controlled

---

## 🛠️ Eeldused ja Tööriistad

### Kohustuslikud Tööriistad

✅ **Docker & Docker Compose**
```bash
docker --version
docker compose version
```

✅ **Kubernetes**
- kubectl
- Minikube või K3s (local cluster)
```bash
kubectl version --client
minikube version  # või k3s --version
```

✅ **Versioonikontroll**
```bash
git --version
```

✅ **Text Editor**
- VS Code (soovitatud)
- vim, nano, või muu

### Soovituslikud Tööriistad

📦 **Helm** - Kubernetes package manager
📦 **k9s** - Terminal UI for Kubernetes
📦 **kubectx/kubens** - Kubernetes context switching
📦 **Lens** - Kubernetes IDE
📦 **Docker Desktop** - Windows/Mac kasutajatele

### Online Accounts

- **GitHub konto** - CI/CD jaoks
- **Docker Hub konto** - Image registry

### Installatsiooni Kontroll

Käivita kõik järgmised käsud, et kontrollida installatsioone:

```bash
docker --version
docker compose version
kubectl version --client
minikube version  # või k3s --version
git --version
helm version  # optional
```

Kui kõik töötavad, oled valmis alustama!

---

## 💡 Kuidas Laboreid Läbida

### 1. Ettevalmistus

- **Loe läbi vastav peatükk koolituskavast** (kui viidatud)
- **Paigalda vajalikud tööriistad** (vt eeldused)
- **Klooni/ava laborite repositoorium**

### 2. Labori Läbimine

- **Loe lab README.md** - Iga labori oma dokumentatsioon
- **Järgi step-by-step juhiseid** - Harjutused on nummerdatud
- **Proovi ise enne solutions'ite vaatamist** - Õppimine tuleb tegemisest
- **Testi kõiki komponente** - Veendu, et kõik töötab

### 3. Kontrolli

**Küsi endalt:**
- ✅ Kas kõik teenused töötavad?
- ✅ Kas API'd on kättesaadavad?
- ✅ Kas andmed säilivad restart'i järel?
- ✅ Kas logging/monitoring töötab?
- ✅ Kas saan aru, mida tegin ja miks?

### 4. Puhastamine ja Reset

Iga labor sisaldab `reset.sh` skripti:

```bash
# Lab ressursside puhastamine
cd 01-docker-lab
./reset.sh

# Alusta laborit uuesti puhtalt lehelt
```

**Mida reset teeb:**
- Kustutab Docker containerid ja image'd
- Eemaldab Docker network'id ja volume'd
- Kustutab Kubernetes ressursid
- Puhastab Helm releases

**Millal kasutada:**
- Soovid harjutust uuesti teha
- Süsteem on segane, alusta puhtalt
- Midagi läks katki
- Liigud järgmise labori juurde

---

## 🔄 Laborite Progressioon

Laborid on järjestatud nii, et iga järgmine labor kasutab eelmiste tulemusi:

```
Lab 1: Docker
    ↓
Lood 3 Docker image'i
    ↓
Lab 2: Docker Compose
    ↓
Kasutad Lab 1 image'id compose'is
    ↓
Lab 3: Kubernetes Basics
    ↓
Deploy'ad Lab 1 image'd Kubernetes'e
    ↓
Lab 4: Kubernetes Advanced
    ↓
Täiustad Lab 3 deployment'i (Helm, Ingress, HPA)
    ↓
Lab 5: CI/CD
    ↓
Automatiseerid Lab 1-4 protsessid
    ↓
Lab 6: Monitoring
    ↓
Monitoorid Lab 1-5 komponente
    ↓
Lab 7: Security
    ↓
Turvad Lab 1-6 süsteemi (Vault, RBAC, Network Policies)
    ↓
Lab 8: GitOps
    ↓
Deploy'ad Lab 1-7 ArgoCD'ga (Git = source of truth)
    ↓
Lab 9: Backup
    ↓
Backup'id Lab 1-8 komponendid (Velero)
    ↓
Lab 10: Terraform
    ↓
Provision'id Lab 1-9 infrastructure as code
    ↓
✅ VALMIS: Production-ready DevOps platform!
```

---

## 📂 Kataloogistruktuur

```
labs/
├── README.md                      # See fail - laborite ülevaade
│
├── apps/                          # Valmis rakendused (eelnevalt kirjutatud)
│   ├── backend-nodejs/            # User Service (Node.js + Express)
│   ├── backend-java-spring/      # Todo Service (Java Spring Boot)
│   └── frontend/                  # Web UI (HTML + JS + CSS)
│
├── 01-docker-lab/                 # Lab 1: Docker Põhitõed
│   ├── README.md
│   ├── exercises/                 # 6 harjutust
│   ├── solutions/                 # Lahendused
│   └── reset.sh
│
├── 02-docker-compose-lab/         # Lab 2: Docker Compose
│   ├── README.md
│   ├── exercises/                 # 6 harjutust
│   ├── solutions/
│   └── reset.sh
│
├── 03-kubernetes-basics-lab/      # Lab 3: Kubernetes Alused
│   ├── README.md
│   ├── exercises/                 # 6 harjutust
│   └── reset.sh
│
├── 04-kubernetes-advanced-lab/    # Lab 4: Kubernetes Täiustatud
│   ├── README.md
│   ├── exercises/                 # 5 harjutust
│   └── solutions/
│
├── 05-cicd-lab/                   # Lab 5: CI/CD Pipeline
│   ├── README.md
│   ├── exercises/                 # 5 harjutust
│   └── solutions/workflows/
│
├── 06-monitoring-logging-lab/     # Lab 6: Monitoring & Logging
│   ├── README.md
│   ├── exercises/                 # 5 harjutust
│   └── solutions/
│
├── 07-security-secrets-lab/       # Lab 7: Security & Secrets
│   ├── README.md
│   ├── exercises/                 # 5 harjutust
│   └── solutions/
│
├── 08-gitops-argocd-lab/          # Lab 8: GitOps with ArgoCD
│   ├── README.md
│   ├── exercises/                 # 5 harjutust
│   └── solutions/
│
├── 09-backup-disaster-recovery-lab/  # Lab 9: Backup & DR
│   ├── README.md
│   ├── exercises/                 # 5 harjutust
│   └── solutions/
│
└── 10-terraform-iac-lab/          # Lab 10: Terraform IaC
    ├── README.md
    ├── exercises/                 # 5 harjutust
    └── solutions/
```

---

## 📊 Progress Tracking

Märgi ära läbitud laborid:

- [ ] **Lab 0:** README läbi loetud
- [ ] **Lab 1:** Docker Põhitõed
- [ ] **Lab 2:** Docker Compose
- [ ] **Lab 3:** Kubernetes Alused
- [ ] **Lab 4:** Kubernetes Täiustatud
- [ ] **Lab 5:** CI/CD Pipeline
- [ ] **Lab 6:** Monitoring & Logging
- [ ] **Lab 7:** Security & Secrets
- [ ] **Lab 8:** GitOps with ArgoCD
- [ ] **Lab 9:** Backup & Disaster Recovery
- [ ] **Lab 10:** Terraform Infrastructure as Code

**Kui kõik on tehtud = Production-ready DevOps Administrator! 🎓**

---

## 🆘 Abi ja Troubleshooting

### Kui tekivad probleemid:

**1. Kontrolli README**
- Iga labor sisaldab detailset dokumentatsiooni
- Exercises'id on step-by-step juhendid

**2. Vaata Solutions**
- `solutions/` kaustas on töötavad näidised
- Võrdle oma koodi solution'iga

**3. Debug Logs**
```bash
# Docker
docker logs <container-name>
docker inspect <container-name>

# Kubernetes
kubectl logs <pod-name>
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'

# Docker Compose
docker compose logs <service-name>
```

**4. Kasuta Reset Skripti**
```bash
# Kui midagi läks katki, alusta puhtalt
./reset.sh
```

**5. Kontrolli Eeldusi**
- Kas kõik tööriistad on paigaldatud?
- Kas eelmised laborid on läbitud?
- Kas cluster töötab? (`kubectl cluster-info`)

---

## 🎓 Seosed Koolituskavaga

Laborid toetuvad järgmistele peatükkidele:

| Peatükk | Labor | Teema |
|---------|-------|-------|
| **12** | Lab 1 | Docker põhimõtted |
| **13** | Lab 2 | Docker Compose |
| **15-16** | Lab 3 | Kubernetes alused |
| **17-19** | Lab 4 | Kubernetes täiustatud |
| **20-21** | Lab 5 | CI/CD |
| **24** | Lab 6 | Monitoring |
| **25** | Lab 7 | Security |
| - | Lab 8 | GitOps (advanced topic) |
| - | Lab 9 | Backup & DR (advanced topic) |
| - | Lab 10 | Infrastructure as Code (advanced topic) |

---

## 🔑 Võtme Takeaway'd

### Labori Disain

✅ **Hands-on fookus** - Kõik laborid on praktilised, mitte teoreetilised
✅ **DevOps administraatori pädevused** - Ei keskendu koodiarendusele
✅ **Järjestikused laborid** - Iga labor ehitab eelmisele
✅ **Valmis rakendused** - Apps on eelnevalt kirjutatud, fookus on DevOps'il
✅ **Production-ready** - Kõik laborid õpetavad tõelisi production patterns

### Mida Sina (DevOps Admin) Teed

- ✅ **Dockerizing** - Konteinerite loomine ja optimeerimine
- ✅ **Orchestration** - Kubernetes deployment ja management
- ✅ **Automation** - CI/CD pipeline setup
- ✅ **Monitoring** - Metrics, logs, alerts
- ✅ **Security** - RBAC, secrets, network policies
- ✅ **GitOps** - Declarative deployments
- ✅ **Disaster Recovery** - Backups, restores
- ✅ **Infrastructure as Code** - Terraform

### Mida Sa MITTE Ei Tee

❌ Ei kirjuta Node.js koodi
❌ Ei kirjuta Java koodi
❌ Ei kirjuta frontend koodi
❌ Ei disaini andmebaasi skeeme

**Kõik rakendused on valmis - sina haldad nende lifecycle'i DevOps perspektiivist!**

---

## 🚀 Järgmised Sammud

### Alusta Nüüd!

1. **Kontrolli eeldusi:**
```bash
docker --version && kubectl version --client && git --version
```

2. **Mine Lab 1 juurde:**
```bash
cd 01-docker-lab
cat README.md
```

3. **Järgi juhiseid ja naudi õppimist!**

---

## 📈 Õpitulemused

Peale kõigi 10 labori läbimist:

### Tehnilised Oskused
✅ Oskad deploy'da production-ready rakendusi
✅ Oskad skaleerida teenuseid vastavalt koormusele
✅ Oskad monitoorida süsteemi tervist
✅ Oskad rollback'ida ebaõnnestunud deploymente
✅ Oskad debuggida production issues
✅ Oskad hallata secrets ja access control
✅ Oskad implementeerida GitOps workflows
✅ Oskad teostada disaster recovery
✅ Oskad provision'ida infrastructure as code

### DevOps Töövoog
✅ **Code → Build → Test → Deploy → Monitor**
✅ **GitOps workflow** (Git = single source of truth)
✅ **Incident response** (monitoring, alerting, debugging)
✅ **Capacity planning** (scaling, resource management)
✅ **Security mindset** (shift-left, defense in depth)

### Real-World Skills
✅ **Kubernetes administration** - Production cluster management
✅ **CI/CD pipeline engineering** - Automated deployment workflows
✅ **Monitoring & observability** - Metrics, logs, traces
✅ **Security engineering** - Vault, RBAC, network policies, scanning
✅ **GitOps practices** - ArgoCD, declarative deployments
✅ **Disaster recovery** - Backup strategies, tested recovery plans
✅ **Infrastructure as Code** - Terraform, version controlled infrastructure

---

**Edu laborite läbimisel! 🎓🚀**

*Laborid on disainitud praktilise DevOps administraatori töövoo õppimiseks.*
*Iga labor ehitab eelmisele ja koos moodustavad tervikliku DevOps skillset'i.*

---

**Viimane uuendus:** 2025-11-23
**Kokku materjali:** 10 laborit, 45 tundi hands-on praktikat
**Staatus:** Kõik laborid valmis ja testimiseks ready!
