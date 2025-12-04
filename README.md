# DevOps Koolituskava ja Praktilised Laborid

**Eestikeelne DevOps Administraatori Õppeprogramm**

Põhjalik teoreetiline koolitusmaterj koos hands-on laboritega, mis õpetab täielikku DevOps administraatori oskuste komplekti - konteineriseerimisest kuni production-ready infrastructure'ini.

---

## 📚 Mis on see programm?

See on **kahetasandiline õppeprogramm**, mis ühendab:

1. **📖 Teoreetiline koolituskava** - 31 põhjalikku peatükki, mis selgitavad DevOps kontseptsioone, tööriistu ja parimaid praktikaid
2. **🛠️ Praktilised laborid** - 10 hands-on laborit (45 tundi), kus rakendat teoreetilisi teadmisi reaalse infrastruktuuri ülesehitamisel

**Programmi fookus:** DevOps/infrastruktuuri haldamine, MITTE rakenduste arendamine. Kasutad kolme valmis mikroteenust (Node.js, Java Spring Boot, Frontend) ja õpid neid dockerizing'ut, orkestreerimist, deployment'i, monitorimist ja turvalist haldamist.

---

## 🎯 Kellele mõeldud?

**Sihtgrupp:** IT-taustaga algajad DevOps'is

**Eeldused:**
- ✅ Oskad kasutada terminali/käsurida
- ✅ Tead Linuxit põgusalt (fail navigeerimine, põhikäsud)
- ✅ Oled kuulnud Docker'ist ja Kubernetes'est (aga ei pea olema kogemus)
- ✅ Soovid õppida DevOps administraatori rolli (infrastruktuur, deployment, monitoring)

**Peale programmi läbimist oskad:**
- 🐳 Konteineristada rakendusi Docker'iga (multi-stage builds, optimization)
- ☸️ Deploy'da ja orkesteerida Kubernetes'es (Pods, Deployments, Services, Ingress, HPA)
- 🔄 Seadistada CI/CD pipeline'e (GitHub Actions, automated deployment)
- 📊 Monitoorida ja logida süsteeme (Prometheus, Grafana, Loki, Alerting)
- 🔒 Turvata infrastruktuuri (Vault, RBAC, Network Policies, security scanning)
- 🚀 Kasutada täiustatud DevOps praktikaid (GitOps/ArgoCD, Backup/DR, Terraform IaC)

---

## 📊 Programmi Ülevaade

```
┌─────────────────────────────────────────────────────────────────┐
│                     DEVOPS ÕPPEPROGRAMM                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  📖 TEOREETILINE KOOLITUSKAVA (31 peatükki)                     │
│  • ~52,000-65,000 sõna (~104-129 lehekülge)                     │
│  • 70% teooria, 30% praktilised näited                          │
│  • Eesti keeles, inglise terminid sulgudes                      │
│                                                                 │
│           ↓ TOETAB ↓                                            │
│                                                                 │
│  🛠️ PRAKTILISED LABORID (10 laborit, 45 tundi)                  │
│  • Hands-on harjutused                                          │
│  • 3 valmis mikroteenust (Node.js, Java Spring, Frontend)       │
│  • Progressiivne õpe (iga labor ehitab eelmisele)               │
│                                                                 │
│           ↓                                                     │
│                                                                 │
│  🎓 TULEMUS: Production-Ready DevOps Administraator             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Kogu programm:**
- **31 peatükki** teoreetilist materjali
- **10 laborit** (45 tundi hands-on praktikat)
- **7 faasi** progressiivset õppimist
- **Täielik DevOps stack:** Docker → Kubernetes → CI/CD → Monitoring → Security → GitOps → IaC

---

## 📖 Koolituskava Sisukord

**Progressi ülevaade:** 5 / 31 peatükki valmis (16.1%)

```
[█████░░░░░░░░░░░░░░░░░░░░░░░░░] 16.1%
```

### FAAS 1: Põhitõed ja Sissejuhatus (Peatükid 1-4)

| # | Peatükk | Staatus | Teemad |
|---|---------|---------|--------|
| 1 | [DevOps Sissejuhatus ja VPS Setup](01-DevOps-Sissejuhatus-VPS-Setup.md) | ⏳ Planeeritud | DevOps põhimõisted, CI/CD, IaC, VPS setup, SSH, firewall |
| 2 | [Linux Põhitõed DevOps Kontekstis](02-Linux-Pohitoed-DevOps-Kontekstis.md) | ⏳ Planeeritud | Bash käsud, õigused, kasutajad, protsessid, systemctl, package management |
| 3 | [Git DevOps Töövoos](03-Git-DevOps-Toovoos.md) | ⏳ Planeeritud | Git alused, branching strategies, pull requests, versioning |
| 4 | [Võrgutehnoloogia Alused](04-Vorgutehnoloogia-Alused.md) | ⏳ Planeeritud | IP, portid, DNS, load balancing, reverse proxy, firewall |

---

### FAAS 2: Docker ja Konteinerid (Peatükid 5-9) ⭐ PRIORITEET

| # | Peatükk | Staatus | Teemad |
|---|---------|---------|--------|
| 5 | **[Docker Põhimõtted](resource/05-Docker-Pohimotted.md)** | ✅ **Valmis** | VM vs konteinerid, Docker arhitektuur, image vs container, workflow |
| 6 | **[Dockerfile ja Konteineriseerimise Detailid](resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md)** | ✅ **Valmis** | Dockerfile instruktsionid, multi-stage builds, base image valik, optimization |
| 6A | **[Java/Spring Boot ja Node.js Spetsiifika](resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)** | ✅ **Valmis** | WAR Tomcat vs JAR konteiner, JVM tuning, Spring Boot embedded server, Node.js best practices |
| 7 | [Docker Image'ite Haldamine ja Optimeerimine](07-Docker-Imagite-Haldamine-Optimeerimine.md) | ⏳ Planeeritud | Build, tag, push, registry, versioning, security scanning |
| 8 | [Docker Compose](08-Docker-Compose.md) | ⏳ Planeeritud | docker-compose.yml, multi-container apps, environments, migrations |
| 8A | **[Docker Compose Production vs Development](resource/08A-Docker-Compose-Production-Development-Seadistused.md)** | ✅ **Valmis** | Port binding strateegiad, production vs dev lähenemine, override pattern, security best practices |
| 8B | **[Nginx Reverse Proxy Docker Keskkonnas](resource/08B-Nginx-Reverse-Proxy-Docker-Keskkonnas.md)** | ✅ **Valmis** | Reverse proxy kontseptsioon, Nginx Docker Compose's, CORS lahendamine, API gateway, turvalisus |
| 9 | [PostgreSQL Konteinerites](09-PostgreSQL-Konteinerites.md) | ⏳ Planeeritud | Volumes, connection strings, backup/restore, Liquibase |

**FAAS 2 Progress:** 5 / 8 peatükki valmis (62.5%)

---

### FAAS 3: Kubernetes Alused (Peatükid 10-17)

| # | Peatükk | Staatus | Teemad |
|---|---------|---------|--------|
| 10 | [Kubernetes Sissejuhatus](10-Kubernetes-Sissejuhatus.md) | ⏳ Planeeritud | K8s vs Docker Compose, arhitektuur, K3s setup, kubectl |
| 11 | [Pods ja Rakenduste Käivitamine](11-Pods-Rakenduste-Kaivitamine.md) | ⏳ Planeeritud | Pod lifecycle, YAML manifest, kubectl käsud |
| 12 | [Deployments ja ReplicaSets](12-Deployments-ReplicaSets.md) | ⏳ Planeeritud | Deployment vs Pod, self-healing, scaling, rolling updates, rollbacks |
| 13 | [Services ja Networking](13-Services-Networking.md) | ⏳ Planeeritud | ClusterIP, NodePort, LoadBalancer, DNS service discovery |
| 14 | [ConfigMaps ja Secrets](14-ConfigMaps-Secrets.md) | ⏳ Planeeritud | Environment variables, volume mounts, 12-factor app |
| 15 | [Persistent Storage](15-Persistent-Storage.md) | ⏳ Planeeritud | PV, PVC, StorageClass, StatefulSets |
| 16 | [InitContainers ja Database Migrations](16-InitContainers-Database-Migrations.md) | ⏳ Planeeritud | InitContainer pattern, Liquibase migrations |
| 17 | [Ingress ja Load Balancing](17-Ingress-Load-Balancing.md) | ⏳ Planeeritud | Nginx Ingress, routing (path/host-based), TLS |

---

### FAAS 4: Kubernetes Täiustatud + CI/CD (Peatükid 18-21)

| # | Peatükk | Staatus | Teemad |
|---|---------|---------|--------|
| 18 | [Horizontal Pod Autoscaling](18-Horizontal-Pod-Autoscaling.md) | ⏳ Planeeritud | HPA, Metrics Server, CPU/memory autoscaling |
| 19 | [Helm Package Manager](19-Helm-Package-Manager.md) | ⏳ Planeeritud | Chart struktuur, templates, values, helm käsud |
| 20 | [GitHub Actions Basics](20-GitHub-Actions-Basics.md) | ⏳ Planeeritud | Workflows, jobs, steps, triggers, secrets, matrix strategy |
| 21 | [Automated Deployment Pipeline](21-Automated-Deployment-Pipeline.md) | ⏳ Planeeritud | Docker build/push automation, Helm deployment, multi-environment, quality gates |

---

### FAAS 5: Monitoring ja Logging (Peatükid 22-24)

| # | Peatükk | Staatus | Teemad |
|---|---------|---------|--------|
| 22 | [Prometheus Metrics](22-Prometheus-Metrics.md) | ⏳ Planeeritud | Prometheus arhitektuur, PromQL, ServiceMonitor, instrumentation |
| 23 | [Grafana Visualization ja Loki Logging](23-Grafana-Visualization-Loki-Logging.md) | ⏳ Planeeritud | Dashboards, LogQL, Promtail, logs+metrics correlation |
| 24 | [Alerting](24-Alerting.md) | ⏳ Planeeritud | AlertManager, alert rules, notification channels |

---

### FAAS 6: Security (Peatükid 25-27)

| # | Peatükk | Staatus | Teemad |
|---|---------|---------|--------|
| 25 | [Security Best Practices](25-Security-Best-Practices.md) | ⏳ Planeeritud | OWASP K8s Top 10, CIS Benchmark, Pod Security Standards |
| 26 | [Vault ja Sealed Secrets](26-Vault-Sealed-Secrets.md) | ⏳ Planeeritud | HashiCorp Vault, Agent Injector, Sealed Secrets Controller |
| 27 | [RBAC ja Network Policies](27-RBAC-Network-Policies.md) | ⏳ Planeeritud | Kubernetes RBAC, ServiceAccounts, Network Policies, Trivy scanning |

---

### FAAS 7: Täiustatud Teemad (Peatükid 28-30)

| # | Peatükk | Staatus | Teemad |
|---|---------|---------|--------|
| 28 | [GitOps with ArgoCD](28-GitOps-ArgoCD.md) | ⏳ Planeeritud | GitOps principles, ArgoCD, Kustomize, sync policies, Canary deployments |
| 29 | [Backup ja Disaster Recovery](29-Backup-Disaster-Recovery.md) | ⏳ Planeeritud | Velero, backup strategies, restore workflows, 3-2-1 rule |
| 30 | [Terraform Infrastructure as Code](30-Terraform-Infrastructure-as-Code.md) | ⏳ Planeeritud | Terraform basics, Kubernetes provider, modules, state management |

---

## 🛠️ Praktilised Laborid

**10 laborit, 45 tundi hands-on praktikat**

Detailne kirjeldus: [`labs/README.md`](labs/README.md)

### Põhikursus (Lab 1-6, 25h)

| Lab | Kestus | Teema | Eeldus Peatükid | Staatus |
|-----|--------|-------|----------------|---------|
| **[Lab 1: Docker Põhitõed](labs/01-docker-lab/)** | 4h | Dockerfile, image build, multi-stage builds, networking, volumes | 5, 6, 6A, 7 | 📦 Valmis |
| **[Lab 2: Docker Compose](labs/02-docker-compose-lab/)** | 3h | docker-compose.yml, full-stack setup, environments, migrations | 8, 9 | 📦 Valmis |
| **[Lab 3: Kubernetes Basics](labs/03-kubernetes-basics-lab/)** | 5h | Pods, Deployments, Services, ConfigMaps, Secrets, PV/PVC | 10-16 | 📦 Valmis |
| **[Lab 4: Kubernetes Advanced](labs/04-kubernetes-advanced-lab/)** | 5h | Ingress, HPA, rolling updates, Helm charts | 17-19 | 📦 Valmis |
| **[Lab 5: CI/CD Pipeline](labs/05-cicd-lab/)** | 4h | GitHub Actions, automated build/deploy, multi-environment | 20, 21 | 📦 Valmis |
| **[Lab 6: Monitoring & Logging](labs/06-monitoring-logging-lab/)** | 4h | Prometheus, Grafana, Loki, dashboards, alerts | 22-24 | 📦 Valmis |

### Täiustatud Kursus (Lab 7-10, 20h)

| Lab | Kestus | Teema | Eeldus Peatükid | Staatus |
|-----|--------|-------|----------------|---------|
| **[Lab 7: Security & Secrets](labs/07-security-secrets-lab/)** | 5h | Vault, RBAC, Network Policies, Trivy scanning | 25-27 | 📦 Valmis |
| **[Lab 8: GitOps with ArgoCD](labs/08-gitops-argocd-lab/)** | 5h | ArgoCD, Kustomize, ApplicationSet, Canary | 28 | 📦 Valmis |
| **[Lab 9: Backup & Disaster Recovery](labs/09-backup-disaster-recovery-lab/)** | 5h | Velero, backup/restore, DR drills, migration | 29 | 📦 Valmis |
| **[Lab 10: Terraform IaC](labs/10-terraform-iac-lab/)** | 5h | Terraform Kubernetes provider, modules, state | 30 | 📦 Valmis |

---

## 🔗 Peatükkide ja Laborite Seosed

Kuidas teoreetiline materjal toetab praktilisi laboreid:

| Laborid | Peatükid | Teoreetilised Teemad |
|---------|---------|---------------------|
| **Lab 1-2** (Docker) | **5, 6, 6A, 7, 8, 9** | Docker põhimõtted, Dockerfile, Java/Node konteineriseerimise, Image haldamine, Docker Compose, PostgreSQL |
| **Lab 3-4** (Kubernetes) | **10-19** | K8s intro, Pods, Deployments, Services, ConfigMaps, Secrets, Storage, InitContainers, Ingress, HPA, Helm |
| **Lab 5** (CI/CD) | **20, 21** | GitHub Actions, automated deployment pipeline, multi-environment |
| **Lab 6** (Monitoring) | **22-24** | Prometheus metrics, Grafana + Loki logging, Alerting |
| **Lab 7** (Security) | **25-27** | Security best practices, Vault, Sealed Secrets, RBAC, Network Policies |
| **Lab 8** (GitOps) | **28** | GitOps principles, ArgoCD, Kustomize, sync policies, Canary |
| **Lab 9** (Backup/DR) | **29** | Velero, backup strategies, restore workflows, disaster recovery |
| **Lab 10** (Terraform) | **30** | Terraform IaC, Kubernetes provider, modules, state management |

---

## 🏗️ Mikroteenuste Arhitektuur

Kõik laborid kasutavad **sama kolme valmis mikroteenust**:

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
│  • Registreerimine    │  │  • TODO CRUD              │
│  • JWT autentimine    │  │  • Filtreerimine          │
│  • Kasutajahaldus     │  │  • Statistika             │
│  • RBAC (user/admin)  │  │  • JWT validatsioon       │
└──────────┬────────────┘  └──────────┬────────────────┘
           │                          │
           │ PostgreSQL               │ PostgreSQL
           ▼                          ▼
     users DB (5432)            todos DB (5433)
```

**Sinu roll:** DevOps Administraator - dockerize, orkestreebi, deploy, monitoori, turva. **EI arenda rakendusi.**

---

## 🚀 Kuidas Alustada

### 1. Kontrolli Eeldusi

**Kohustuslikud tööriistad:**
```bash
docker --version          # Docker Engine
docker compose version    # Docker Compose
kubectl version --client  # Kubernetes CLI
minikube version         # või k3s --version
git --version            # Versioonikontroll
```

**Soovituslikud:**
- Helm (Kubernetes package manager)
- k9s (Terminal UI for Kubernetes)
- VS Code (text editor)

**Online accounts:**
- GitHub konto (CI/CD jaoks)
- Docker Hub konto (image registry)

### 2. Vali Õpitee

**Variant A: Progressiivne õpe (soovitatav)**
1. Loe Peatükk 5 (Docker Põhimõtted)
2. Tee Lab 1 harjutused
3. Loe Peatükk 6 ja 6A (Dockerfile detailid)
4. Jätka Lab 1 (Dockerfile loomine)
5. Loe Peatükk 7-9 (Compose, PostgreSQL)
6. Tee Lab 2
7. ... jne

**Variant B: Teooria enne praktikat**
1. Loe kõik FAAS 2 peatükid (5-9)
2. Tee Lab 1 ja Lab 2
3. Loe FAAS 3 peatükid (10-17)
4. Tee Lab 3 ja Lab 4
5. ... jne

**Variant C: Praktiline (kogenud kasutajatele)**
1. Alusta kohe Lab 1'st
2. Kui vajad teooria tuge, loe vastavat peatükki
3. Kasuta peatükke referentsina

### 3. Õppimise Workflow

```
┌─────────────────┐
│ 1. LOE PEATÜKK  │  ← Teooria (70%), Näited (30%)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. TEE LABOR    │  ← Hands-on harjutused
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. KONTROLLI    │  ← Kas kõik töötab? Kas saad aru?
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. JÄRGMINE ──► │
└─────────────────┘
```

### 4. Abi Saamine

**Probleemid labori tegemise ajal:**
1. Kontrolli vastava peatüki "Levinud Probleemid ja Lahendused" sektsiooni
2. Kasuta labori `reset.sh` skripti puhtalt lehelt alustamiseks
3. Vaata laborite README.md faili troubleshooting sektsiooni

**Küsimused teoreetilise materjali kohta:**
- Kontrolli peatüki "Viited ja Edasine Lugemine" sektsiooni
- Vaata ametlikku dokumentatsiooni (Docker docs, Kubernetes docs jne)

---

## 📂 Repositooriumi Struktuur

```
/home/janek/projects/hostinger/
├── README.md                                    ← See fail
├── DEVOPS-KOOLITUSKAVA-PLAAN-2025.md           ← Master plan (detail)
├── TERMINOLOOGIA.md                             ← Eesti-inglise terminid
│
├── resource/
│   ├── 05-Docker-Pohimotted.md                      ✅ VALMIS
│   ├── 06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md  ✅ VALMIS
│   ├── 06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md  ✅ VALMIS
│   └── code-explanations/                          ← Koodiselgitused
│       └── Node.js-Dockerfile-Proxy-Explained.md   ✅ VALMIS
│
├── 01-DevOps-Sissejuhatus-VPS-Setup.md         ⏳
├── 02-Linux-Pohitoed-DevOps-Kontekstis.md      ⏳
├── 03-Git-DevOps-Toovoos.md                     ⏳
├── 04-Vorgutehnoloogia-Alused.md                ⏳
├── 07-Docker-Imagite-Haldamine-Optimeerimine.md  ⏳
├── 08-Docker-Compose.md                          ⏳
├── 09-PostgreSQL-Konteinerites.md                ⏳
├── 10-Kubernetes-Sissejuhatus.md                 ⏳
├── ...
├── 30-Terraform-Infrastructure-as-Code.md        ⏳
│
└── labs/
    ├── README.md                                 ← Laborite detailne ülevaade
    ├── CLAUDE.md                                 ← Juhised Claude Code'ile
    ├── apps/                                     ← Valmis mikroteenused
    │   ├── backend-nodejs/                       (User Service)
    │   ├── backend-java-spring/                  (Todo Service)
    │   ├── frontend/                             (Web UI)
    │   └── docker-compose.yml
    │
    ├── 01-docker-lab/                            📦 Docker Põhitõed
    ├── 02-docker-compose-lab/                    📦 Docker Compose
    ├── 03-kubernetes-basics-lab/                 📦 Kubernetes Basics
    ├── 04-kubernetes-advanced-lab/               📦 Kubernetes Advanced
    ├── 05-cicd-lab/                              📦 CI/CD Pipeline
    ├── 06-monitoring-logging-lab/                📦 Monitoring & Logging
    ├── 07-security-secrets-lab/                  📦 Security & Secrets
    ├── 08-gitops-argocd-lab/                     📦 GitOps ArgoCD
    ├── 09-backup-disaster-recovery-lab/          📦 Backup & DR
    └── 10-terraform-iac-lab/                     📦 Terraform IaC
```

### Koodiselgitused (Code Explanations)

Lisaks põhjalikele peatükkidele (05-30) sisaldab koolituskava ka **lühikesi koodiselgitusi** - konkreetsete koodilõikude rea-haaval analüüse.

**Asukoht:** `resource/code-explanations/`

**Eristus peatükkidest:**
- Peatükid: Põhjalikud teoreetilised käsitlused (10-20 lk)
- Koodiselgitused: Lühikesed, koodikesksed analüüsid (3-5 lk)

**Olemasolevad:**
- `Node.js-Dockerfile-Proxy-Explained.md` - 2-stage Dockerfile ARG proxy pattern (Lab 1, Exercise 01a)

---

## 📈 Progressi Tracking

### Praegune Seis (2025-11-23)

**Koolituskava:**
- ✅ Valmis: 3 peatükki (Peatükid 5, 6, 6A)
- 🏗️ Pooleli: FAAS 2 (Docker)
- ⏳ Planeeritud: 28 peatükki

**Progress:**
```
Peatükid:     3 / 31    (9.7%)   [███░░░░░░░░░░░░░░░░░░░░░░░░░░░]
Sõnad:        ~27,000 / ~52,000-65,000 (52% FAAS 2'st)
Lehekülgi:    ~54 / ~104-129
FAAS 2:       3 / 5     (60%)    [███████████░░░░░░░]
```

**Laborid:**
- ✅ Kõik 10 laborit valmis ja testimiseks ready

### Järgmised Sammud

1. **Lõpeta FAAS 2** (Docker peatükid)
   - [ ] Peatükk 7: Docker Image'ite Haldamine
   - [ ] Peatükk 8: Docker Compose
   - [ ] Peatükk 9: PostgreSQL Konteinerites

2. **Alusta FAAS 3** (Kubernetes Alused, Peatükid 10-17)

3. **Jätka FAAS 4-7** (CI/CD, Monitoring, Security, Täiustatud)

**Hinnanguline valmimisaeg:** 14-15 nädalat (2 peatükki/nädal)

---

## 🎓 Õpitulemused

Peale kogu programmi läbimist:

**📦 Konteinerite haldamine:**
- Lood optimeeritud Docker image'id (multi-stage builds, Alpine, distroless)
- Dockerized'id Node.js ja Java Spring Boot rakendusi
- Halda konteinereid ja volume'id

**☸️ Kubernetes orkestratsioon:**
- Deploy'ad rakendusi Kubernetes cluster'isse
- Halda Pods, Deployments, Services, Ingress
- Konfigureeri ConfigMaps, Secrets, PersistentVolumes
- Kasuta Helm chart'e

**🔄 CI/CD automatiseerimine:**
- Seadista GitHub Actions workflows
- Automatiseeri build, test, deploy protsess
- Implementeeri rolling updates ja quality gates

**📊 Monitoring ja Logging:**
- Seadista Prometheus ja Grafana
- Kogu application metrics
- Agregeerib ja analüüsi logisid (Loki)
- Seadista alerting rules

**🔒 Security:**
- Halda secrets (Vault, Sealed Secrets)
- Konfigureeri RBAC access control
- Implementeeri Network Policies
- Skaneeri vulnerabilities (Trivy)

**🚀 GitOps:**
- Deploy'a rakendusi ArgoCD'ga
- Halda multi-environment setups (dev, staging, prod)
- Kasuta Kustomize overlays
- Implementeeri Canary deployments

**💾 Disaster Recovery:**
- Loo backups Velero'ga
- Teosta disaster recovery drills
- Migreerib applications cross-cluster

**🏗️ Infrastructure as Code:**
- Provision'i Kubernetes resources Terraform'iga
- Loo reusable Terraform modules
- Manage'i Terraform state

**Tulemus:** Production-ready DevOps administraatori skillset! 🎉

---

## 📚 Viited ja Ressursid

### Selle Programmi Failid

- **[DEVOPS-KOOLITUSKAVA-PLAAN-2025.md](DEVOPS-KOOLITUSKAVA-PLAAN-2025.md)** - Detailne master plan (faaside jaotus, timeline, kvaliteedikontroll)
- **[labs/README.md](labs/README.md)** - Laborite põhjalik kirjeldus (ülevaade, arhitektuur, tööriistad)
- **[TERMINOLOOGIA.md](TERMINOLOOGIA.md)** - Eesti-inglise terminoloogia sõnastik

### Välised Ressursid

**Ametlikud dokumentatsioonid:**
- Docker: https://docs.docker.com/
- Kubernetes: https://kubernetes.io/docs/
- Helm: https://helm.sh/docs/
- Prometheus: https://prometheus.io/docs/
- ArgoCD: https://argo-cd.readthedocs.io/

**Best Practices:**
- 12-Factor App: https://12factor.net/
- CNCF Landscape: https://landscape.cncf.io/
- DevOps Roadmap: https://roadmap.sh/devops

---

## 🤝 Panus ja Tagasiside

See on avatud õppematerja project.

**Tagasiside:**
- Kui leidsid vigu või ebatäpsusi - loo issue
- Kui on soovitusi paranduste kohta - loo pull request
- Kui tahad täiendada materjali - võta ühendust

---

## 📄 Litsents ja Kasutamine

**Õppematerjalid:** Vabalt kasutatavad õppeotstarbeliselt
**Rakendused (labs/apps/):** Õppe näidised, kasutades MIT litsentsiga teeke

---

**Viimane uuendus:** 2025-11-23
**Programmi staatus:** 🏗️ Aktiivne arendus (FAAS 2 pooleli)
**Kontakt:** [Täida kontaktinfo kui asjakohane]

---

**Edu DevOps õppimisel! 🚀**

*"The best way to learn DevOps is by doing. Teooria annab aluse, laborid annavad kogemuse."*
