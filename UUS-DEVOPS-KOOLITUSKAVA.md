# UUS DevOps ADMINISTRAATORI KOOLITUSKAVA

**Versioon:** 2.0 DevOps-First
**Kuupäev:** 2025-01-22
**Fookus:** DevOps Administraator (mitte Full-Stack Arendaja)
**Kestus:** ~65-75 tundi (vs praegune 93h)
**Põhimõte:** Praktiline, hands-on, labipõhine õpe

---

## 🎯 Põhierinevused Praegusest Kavast

### Praegune Koolituskava (v1.0)

```
Moodulid 1-3: VPS + Backend (Node.js) + Frontend (HTML/JS)
└─ 44 tundi (47%)
   ├─ Node.js/Express arendus (süvendatult)
   ├─ REST API kirjutamine algusest
   ├─ Frontend HTML/CSS/JavaScript (4 tundi)
   └─ PostgreSQL integratsioon arendaja vaatenurgast

Moodulid 4-7: Docker + Kubernetes + CI/CD + Production
└─ 49 tundi (53%)
   └─ DevOps algab ALLES peatükist 12
```

**Probleem:**
- Liiga palju web-arendust
- DevOps jääb teisejärguliseks
- Ei sobi DevOps administraatori rollile

---

### Uus Koolituskava (v2.0 DevOps-First)

```
Moodul 1: Linux & VPS Alused
└─ 8-10 tundi (13%)
   ├─ Ainult infrastruktuuri alused
   └─ PostgreSQL administraatori vaatenurgast

Moodulid 2-6: Docker → Kubernetes → CI/CD → Production
└─ 57-65 tundi (87%)
   ├─ KOHE Docker ja konteinerid
   ├─ Kasutame VALMIS rakendusi labides
   ├─ Backend/Frontend ainult "mõistmise" tasemel
   └─ Fookus: infrastruktuur, orkestratsioon, automatiseerimine
```

**Lahendus:**
- ✅ DevOps PRIORITEET algusest peale
- ✅ Valmis rakendused labides (ei pea ise kirjutama)
- ✅ Backend/Frontend teooria minimeeritud
- ✅ 87% ajast DevOps teemadel

---

## 📚 Uue Koolituskava Struktuur

---

### **MOODUL 1: LINUX JA VPS ALUSED** (8-10h)

**Eesmärk:** Anda vajalik infrastruktuuri alus DevOps tööks

---

#### **Peatükk 1: DevOps Sissejuhatus ja VPS Setup** (3h)

**Sisu:**
- DevOps põhimõtted ja kultuur
- Infrastructure as Code (IaC) kontseptsioon
- VPS vs Cloud vs On-Premise
- SSH võtmed ja turvalisus
- UFW firewall põhitõed
- sudo ja kasutajate haldamine
- systemd teenuste haldamine

**Praktilised harjutused:**
- VPS kirjakast @ 93.127.213.242 setup
- SSH key-based autentimine
- UFW reeglite loomine
- Kasutaja janek konfigureerimine

**Kestus:** 3 tundi

---

#### **Peatükk 2: Linux Põhitõed DevOps Kontekstis** (3h)

**Sisu:**
- Failisüsteemi struktuur (/etc, /var, /opt, /home)
- Protsesside haldamine (ps, top, htop, systemctl)
- Logide vaatamine (journalctl, /var/log)
- Võrgu haldamine (netstat, ss, ip)
- Package management (apt)
- Environment variables ja PATH
- Cron jobs ja scheduled tasks
- File permissions ja ownership

**Praktilised harjutused:**
- Logide monitooring journalctl'iga
- Cron job backup'i jaoks
- Protsesside haldamine

**Kestus:** 3 tundi

---

#### **Peatükk 3: PostgreSQL Administraator Perspektiivist** (2-4h)

**OLULINE:** Ei õpeta PostgreSQL ARENDUST, vaid ADMINISTREERIMIST

**Sisu:**

**3.1 Miks PostgreSQL DevOps kontekstis?**
- Rakendused vajab andmebaasi (user-service, todo-service)
- DevOps administraator HALDAB andmebaasi, ei arenda
- Konteineriseeritud vs väline DB

**3.2 PostgreSQL Konteineris (Docker) - PRIMAARNE**
- Docker PostgreSQL image käivitamine
- Port mapping ja volumes
- Environment variables (POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB)
- psql kliendi põhikäsud (\l, \c, \dt, \d)
- Database ja user'i loomine
- Backup ja restore (pg_dump, pg_restore)
- Logide vaatamine (docker logs)

**3.3 PostgreSQL Väline (Traditsiooniline) - ALTERNATIIV**
- APT paigaldus
- systemd teenuse haldamine
- pg_hba.conf (client authentication)
- postgresql.conf (basic tuning)
- Backup cron job

**3.4 DevOps Vaatenurk:**
```bash
# DevOps administraator PEAB teadma:
✅ Kuidas PostgreSQL konteinerit käivitada
✅ Kuidas ühendust testida
✅ Kuidas backup'e teha
✅ Kuidas logisid vaadata
✅ Kuidas performance'i monitoorida (pg_stat_statements)

❌ EI PEA teadma:
❌ SQL päringute kirjutamist (see on arendaja töö)
❌ Database schema disaini
❌ ORM'ide kasutamist
```

**Praktilised harjutused:**
- PostgreSQL Docker konteiner
- Backup ja restore
- Performance monitoring (pg_stat_activity)

**Kestus:** 2-4 tundi

---

#### **Peatükk 4: Git DevOps Töövoos** (2h)

**Sisu:**
- Git põhikäsud (clone, pull, commit, push)
- Branch'id ja merge
- .gitignore ja secrets haldamine
- GitOps kontseptsioon
- Infrastructure as Code repositories

**MITTE süvitsi:**
- ❌ Pull requests ja code review (see on arendaja töö)
- ❌ Git flow strategies

**Praktiline harjutus:**
- Clone koolituskava repo
- Commit ja push muudatused

**Kestus:** 2 tundi

---

### **MOODUL 2: DOCKER JA KONTEINERISATSIOON** (14-16h)

**Eesmärk:** Valdada Docker'i täielikult - pildid, konteinerid, võrgud, andmehoidlad

---

#### **Peatükk 5: Docker Põhimõtted** (4h)

**Sisu:**
- Konteinerite vs VM'ide erinevused
- Docker arhitektuur (daemon, client, images, containers)
- Docker lifecycle (pull → run → stop → rm)
- Images vs Containers
- Port mapping (-p)
- Volume mounting (-v)
- Environment variables (-e)
- Docker networks (bridge, host)
- Logs ja debugging (docker logs, docker exec)

**Praktiline harjutus:**
- Nginx konteiner (hello world)
- PostgreSQL konteiner (persistent data)
- Node.js rakenduse konteiner

**Kestus:** 4 tundi

**Viide labidele:** Labor 1 Harjutus 1-2

---

#### **Peatükk 6: Dockerfile ja Image Loomine** (4h)

**Sisu:**
- Dockerfile süntaks
- FROM, RUN, COPY, CMD, ENTRYPOINT
- Layer caching ja optimiseerimine
- Multi-stage builds
- .dockerignore
- Image tagging strategies
- Best practices (non-root user, minimal base images)

**OLULINE:**
Kasutame VALMIS rakendusi (`labs/apps/backend-nodejs`, `labs/apps/frontend`)
- EI kirjuta Node.js koodi
- KÜLL kirjutame Dockerfile'e nende jaoks

**Praktiline harjutus:**
- Dockerfile backend-nodejs'le
- Dockerfile frontend'ile
- Multi-stage build (development vs production)

**Kestus:** 4 tundi

**Viide labidele:** Labor 1 Harjutus 1-5

---

#### **Peatükk 7: Docker Compose** (4h)

**Sisu:**
- docker-compose.yml süntaks
- Service definitsioonid
- Networks ja service discovery
- Volumes ja data persistence
- Environment variables ja .env failid
- depends_on ja healthchecks
- Multi-container orchestration
- Development vs production configs

**Praktiline harjutus:**
- Frontend + Backend + PostgreSQL Compose file
- Multi-service deployment
- Log aggregation

**Kestus:** 4 tundi

**Viide labidele:** Labor 2

---

#### **Peatükk 8: Docker Registry ja Image Haldamine** (2-4h)

**Sisu:**
- Docker Hub
- Image push/pull
- Private registry (local)
- Image tagging strategies (latest, semantic versioning)
- Image security scanning (Trivy)
- Registry authentication
- Multi-platform images (amd64, arm64)

**Praktiline harjutus:**
- Push image Docker Hub'i
- Private registry setup
- Security scanning

**Kestus:** 2-4 tundi

---

### **MOODUL 3: KUBERNETES ORKESTRATSIOON** (22-26h)

**Eesmärk:** Deploy ja halda production-ready rakendusi Kubernetes'es

---

#### **Peatükk 9: Kubernetes Alused ja K3s Setup** (4h)

**Sisu:**
- Kubernetes arhitektuur (master, worker, etcd, API server)
- Pods, Deployments, Services kontseptsioonid
- kubectl CLI
- K3s vs Kubernetes vs Minikube
- K3s installeerimine VPS'is (kirjakast)
- kubeconfig seadistamine
- Namespaces
- Labels ja Selectors

**Praktiline harjutus:**
- K3s installeerimine kirjakast VPS'is
- kubectl põhikäsud
- Esimene Pod (Nginx)

**Kestus:** 4 tundi

**Viide labidele:** Labor 3 Harjutus 1

---

#### **Peatükk 10: Pods ja Deployments** (4h)

**Sisu:**
- Pod manifest YAML struktuur
- Container specification
- Resource requests ja limits
- Liveness ja readiness probes
- Deployments ja ReplicaSets
- Replica management
- Rolling updates
- Rollback strategies
- Self-healing

**Praktiline harjutus:**
- Deploy backend-nodejs Deployment
- Scale replicas
- Rolling update
- Rollback

**Kestus:** 4 tundi

**Viide labidele:** Labor 3 Harjutus 2

---

#### **Peatükk 11: Services ja Networking** (4h)

**Sisu:**
- Service tüübid (ClusterIP, NodePort, LoadBalancer, ExternalName)
- Service discovery (DNS)
- Endpoints
- Load balancing
- Port vs TargetPort vs NodePort
- Headless Services
- Network Policies (basic)

**Praktiline harjutus:**
- ClusterIP Service backend'ile
- NodePort Service frontend'ile
- Service discovery test
- Microservices communication

**Kestus:** 4 tundi

**Viide labidele:** Labor 3 Harjutus 3

---

#### **Peatükk 12: ConfigMaps, Secrets ja Configuration** (3h)

**Sisu:**
- ConfigMap loomine (literal, file, env file)
- Secret loomine (Opaque, TLS, Docker registry)
- Base64 encoding
- Environment variable injection
- Volume mount konfiguratsiooni jaoks
- 12-Factor App configuration
- Secrets management best practices

**Praktiline harjutus:**
- ConfigMap rakenduse seadete jaoks
- Secret DB mandaatide jaoks
- JWT secret

**Kestus:** 3 tundi

**Viide labidele:** Labor 3 Harjutus 4

---

#### **Peatükk 13: Persistent Storage** (4h)

**Sisu:**
- PersistentVolume (PV)
- PersistentVolumeClaim (PVC)
- StorageClass
- Access Modes (RWO, RWX, ROX)
- Reclaim Policies (Retain, Delete, Recycle)
- StatefulSets vs Deployments
- PostgreSQL StatefulSet
- Volume snapshots

**Praktiline harjutus:**
- PV/PVC PostgreSQL jaoks
- StatefulSet PostgreSQL
- Data persistence test

**Kestus:** 4 tundi

**Viide labidele:** Labor 3 Harjutus 5

---

#### **Peatükk 14: Ingress ja Load Balancing** (3-5h)

**Sisu:**
- Ingress Controllers (Traefik, Nginx)
- Ingress rules ja path-based routing
- Host-based routing (domains)
- TLS/SSL termination
- cert-manager ja Let's Encrypt
- Annotations
- Rate limiting

**Praktiline harjutus:**
- Traefik Ingress (K3s default)
- HTTPS setup Let's Encrypt'iga
- Multi-service routing

**Kestus:** 3-5 tundi

**Viide labidele:** Labor 4 Harjutus 1

---

### **MOODUL 4: CI/CD JA AUTOMATISEERIMINE** (10-12h)

**Eesmärk:** Automatiseerida build, test, deploy workflow

---

#### **Peatükk 15: GitHub Actions Basics** (3h)

**Sisu:**
- GitHub Actions arhitektuur
- Workflow süntaks (YAML)
- Triggers (push, pull_request, schedule, workflow_dispatch)
- Jobs ja steps
- Runners (GitHub-hosted vs self-hosted)
- Actions marketplace
- Secrets ja environment variables
- Matrix strategy

**Praktiline harjutus:**
- Esimene workflow (Hello World)
- Lint ja test workflow
- Multi-job workflow

**Kestus:** 3 tundi

---

#### **Peatükk 16: Docker Build Automation** (3h)

**Sisu:**
- Docker build GitHub Actions'is
- Multi-platform builds (buildx)
- Image tagging strategies (SHA, semantic versioning)
- Docker Hub push
- Registry authentication
- Image caching optimization
- Security scanning (Trivy) CI's

**Praktiline harjutus:**
- Automated Docker build workflow
- Push Docker Hub'i
- Security scan CI's

**Kestus:** 3 tundi

**Viide labidele:** Labor 5 Harjutus 1-2

---

#### **Peatükk 17: Kubernetes Deployment Automation** (4-6h)

**Sisu:**
- kubectl apply GitHub Actions'is
- Kubeconfig management
- Self-hosted runners Kubernetes'es
- Blue-green deployments
- Canary deployments (basic)
- Rollback automation
- Multi-environment (dev, staging, prod)
- GitOps kontseptsioon (ArgoCD preview)

**Praktiline harjutus:**
- CI/CD pipeline (build → test → deploy)
- Automated Kubernetes deployment
- Multi-environment workflow

**Kestus:** 4-6 tundi

**Viide labidele:** Labor 5 Harjutus 3-5

---

### **MOODUL 5: MONITORING, LOGGING, SECURITY** (15-18h)

**Eesmärk:** Production-ready observability ja turvalisus

---

#### **Peatükk 18: Prometheus ja Metrics** (4h)

**Sisu:**
- Prometheus arhitektuur
- Metrics collection (pull model)
- PromQL põhitõed
- Exporters (node-exporter, postgres-exporter)
- ServiceMonitors (Prometheus Operator)
- Recording rules
- Federation

**Praktiline harjutus:**
- Prometheus install Kubernetes'es
- Metrics collection
- PromQL queries

**Kestus:** 4 tundi

**Viide labidele:** Labor 6 Harjutus 1

---

#### **Peatükk 19: Grafana ja Visualization** (3h)

**Sisu:**
- Grafana setup
- Data sources (Prometheus)
- Dashboards loomine
- Panels ja visualizations
- Variables ja templating
- Alerts Grafana's
- Community dashboards

**Praktiline harjutus:**
- Grafana install
- Kubernetes dashboard
- Custom dashboard mikroteenuste jaoks

**Kestus:** 3 tundi

**Viide labidele:** Labor 6 Harjutus 2

---

#### **Peatükk 20: Logging ja Log Aggregation** (4h)

**Sisu:**
- Structured logging
- Loki arhitektuur
- Promtail log collection
- LogQL queries
- Log retention policies
- Log aggregation patterns
- Correlation traces ja logs

**Praktiline harjutus:**
- Loki + Promtail install
- Log aggregation mikroteenuste jaoks
- LogQL queries Grafana's

**Kestus:** 4 tundi

**Viide labidele:** Labor 6 Harjutus 3

---

#### **Peatükk 21: Alerting** (2h)

**Sisu:**
- Prometheus AlertManager
- Alert rules (PrometheusRules)
- Alert routing
- Notification channels (Slack, email, PagerDuty)
- Alert fatigue prevention
- Runbooks

**Praktiline harjutus:**
- AlertManager setup
- Alert rules (CPU, memory, pod down)
- Slack notifications

**Kestus:** 2 tundi

**Viide labidele:** Labor 6 Harjutus 4

---

#### **Peatükk 22: Security Best Practices** (4-6h)

**Sisu:**
- Pod Security Standards (restricted, baseline, privileged)
- Network Policies
- RBAC (Role-Based Access Control)
- Secrets management (Sealed Secrets, External Secrets, Vault)
- Image scanning (Trivy)
- Non-root containers
- Read-only filesystems
- Capabilities dropping
- TLS/SSL everywhere
- Security contexts

**Praktiline harjutus:**
- Network Policies
- Pod Security Standards
- RBAC rules
- Sealed Secrets

**Kestus:** 4-6 tundi

**Viide labidele:** Labor 4 Harjutus 3-4

---

### **MOODUL 6: PRODUCTION OPERATIONS** (10-12h)

**Eesmärk:** Production-ready deployment ja operatsioonid

---

#### **Peatükk 23: High Availability ja Scaling** (4h)

**Sisu:**
- HorizontalPodAutoscaler (HPA)
- Vertical Pod Autoscaler (VPA preview)
- Cluster Autoscaler
- PodDisruptionBudget
- Anti-affinity ja affinity
- Resource limits tuning
- Database connection pooling (PgBouncer)
- Caching (Redis intro)

**Praktiline harjutus:**
- HPA CPU-based
- PodDisruptionBudget
- Load testing (k6)

**Kestus:** 4 tundi

---

#### **Peatükk 24: Backup ja Disaster Recovery** (3h)

**Sisu:**
- PostgreSQL backup strategies
  - Konteineris: CronJob + pg_dump
  - Väline: cron + pg_basebackup
- Volume snapshots
- Velero (Kubernetes backup)
- Restore procedures
- RTO ja RPO kontseptsioonid
- Disaster recovery testing

**Praktiline harjutus:**
- Automated PostgreSQL backup (mõlemad variandid)
- CronJob backup Kubernetes'es
- Restore test

**Kestus:** 3 tundi

---

#### **Peatükk 25: Troubleshooting ja Debugging** (3-5h)

**Sisu:**
- kubectl debugging (logs, describe, exec, port-forward)
- Ephemeral containers
- Debug containers
- Common issues:
  - ImagePullBackOff
  - CrashLoopBackOff
  - Pending Pods
  - Service not reachable
  - PVC Pending
- Network debugging (DNS, connectivity)
- Resource constraints (OOM, CPU throttling)
- PostgreSQL slow queries
- Application debugging

**Praktiline harjutus:**
- Broken deployment parandamine
- Network issue troubleshooting
- Performance bottleneck leidmine

**Kestus:** 3-5 tundi

**Viide labidele:** Labor 6 Harjutus 5

---

## 🎓 Õpitulemused

Peale koolituskava läbimist oskad:

### DevOps Administraatori Pädevused

**Linux ja Infrastruktuur:**
- ✅ VPS haldamine (SSH, firewall, kasutajad)
- ✅ systemd teenuste haldamine
- ✅ Logide monitooring
- ✅ PostgreSQL administreerimine (mitte arendus!)

**Konteinerisatsioon:**
- ✅ Docker image'ite loomine ja optimeerimine
- ✅ Konteinerite haldamine ja debugging
- ✅ Docker Compose multi-container rakendused
- ✅ Private registry haldamine

**Kubernetes Orkestratsioon:**
- ✅ K3s/Kubernetes cluster haldamine
- ✅ Pods, Deployments, StatefulSets deploy
- ✅ Services ja Ingress konfigureerimine
- ✅ ConfigMaps, Secrets haldamine
- ✅ PersistentVolumes ja storage
- ✅ Network Policies ja RBAC

**CI/CD:**
- ✅ GitHub Actions workflows
- ✅ Automated Docker builds
- ✅ Kubernetes deployment automation
- ✅ Multi-environment deployments

**Monitoring ja Logging:**
- ✅ Prometheus metrics collection
- ✅ Grafana dashboards
- ✅ Loki log aggregation
- ✅ AlertManager alerting

**Production Operations:**
- ✅ High availability seadistamine
- ✅ Autoscaling (HPA)
- ✅ Backup ja disaster recovery
- ✅ Security best practices
- ✅ Troubleshooting ja debugging

---

## 🔧 Rakenduste Mõistmine (Minimaalne Teooria)

### Backend Rakendused (Node.js, Java Spring Boot)

**Mida DevOps administraator PEAB teadma:**

✅ **Arhitektuuri mõistmine:**
- REST API kontseptsioon (HTTP meetodid: GET, POST, PUT, DELETE)
- Microservices kommunikatsioon (user-service ↔ todo-service)
- JWT autentimine (token-based auth)
- PostgreSQL ühendus (connection string, credentials)

✅ **Environment Variables:**
```bash
# User Service vajab:
DB_HOST=postgres-user
DB_PORT=5432
DB_NAME=user_service_db
DB_USER=appuser
DB_PASSWORD=secret
JWT_SECRET=shared-secret
PORT=3000
NODE_ENV=production

# DevOps administraator konfigeerib need ConfigMaps ja Secrets'iga
```

✅ **Health Checks:**
```bash
# Kuidas kontrollida, kas rakendus töötab?
curl http://localhost:3000/health
curl http://localhost:8081/actuator/health
```

✅ **Logs:**
```bash
# Kuidas logisid vaadata?
kubectl logs pod/user-service-xxx
docker logs user-service

# Mida otsida logidest?
- DB connection errors
- Authentication failures
- 500 Internal Server Error
```

❌ **Mida DevOps administraator EI PEA teadma:**
- ❌ Kuidas Node.js Express koodi kirjutada
- ❌ Kuidas SQL päringuid kirjutada
- ❌ Kuidas JWT tokeneid genereerida (see on koodis)
- ❌ Kuidas REST API endpoint'e implementeerida

**Analoogia:**
```
DevOps administraator : Rakendus
       =
Automehhaanik : Auto

Automehhaanik EI PEA teadma, kuidas autot DISAINIDA või TOOTA.
Automehhaanik PEAB teadma, kuidas autot HOOLDADA, PARANDADA, MONITOORIDA.

DevOps administraator EI PEAD teadma, kuidas rakendust KIRJUTADA.
DevOps administraator PEAB teadma, kuidas rakendust DEPLOY'DA, MONITOORIDA, DEBUGGIDA.
```

---

### Frontend (HTML/CSS/JavaScript)

**Mida DevOps administraator PEAB teadma:**

✅ **Static files hosting:**
- Nginx konteiner serveerib HTML/CSS/JS faile
- `/usr/share/nginx/html` kaust
- nginx.conf konfiguratsioon (proxy_pass backend'ile)

✅ **Build process:**
```bash
# Frontend "build" on lihtne:
# Kopeeri HTML/CSS/JS failid Nginx image'sse
COPY index.html /usr/share/nginx/html/
COPY css/ /usr/share/nginx/html/css/
COPY js/ /usr/share/nginx/html/js/
```

❌ **Mida DevOps administraator EI PEA teadma:**
- ❌ JavaScript DOM manipulation
- ❌ CSS Flexbox/Grid detailid
- ❌ Fetch API kasutamine
- ❌ Frontend framework'id (React, Vue, Angular)

---

## 📊 Võrdlus Praeguse Kavaga

| Aspekt | Praegune Kava (v1.0) | Uus DevOps Kava (v2.0) |
|--------|---------------------|------------------------|
| **Kogukestus** | 93 tundi | 65-75 tundi |
| **Backend Arendus** | 17h (Node.js, Express, REST API, JWT) | 0h (kasutame valmis rakendusi) |
| **Frontend Arendus** | 11h (HTML, CSS, JavaScript) | 0h (kasutame valmis frontend'i) |
| **DevOps/Infrastruktuur** | 65h (70%) | 65-75h (100%) |
| **Docker algus** | Peatükk 12 (pärast 44h) | Peatükk 5 (pärast 10h) |
| **Kubernetes algus** | Peatükk 15 (pärast 56h) | Peatükk 9 (pärast 24h) |
| **Praktiline fookus** | Full-stack arendaja | DevOps administraator |
| **Labide kasutamine** | Lab 1-6 | Lab 1-6 (SAMA, kuid erinev lähenemine) |

---

## 🎯 Sihtgrupp ja Eeldused

### Kellele sobib UUS kava?

✅ **Sobib:**
- DevOps insenerid
- Site Reliability Engineers (SRE)
- Süsteemiadministraatorid, kes liiguvad cloud/containers'e
- Platform Engineers
- Kubernetes administraatorid
- CI/CD insenerid

❌ **EI sobi:**
- Backend arendajad (kasuta v1.0 kava)
- Frontend arendajad (kasuta v1.0 kava)
- Full-stack arendajad (kasuta v1.0 kava)

### Eeldused

**Vajalik:**
- ✅ Linux command line'i põhitõed
- ✅ Text editor oskus (vim või VS Code)
- ✅ VPS juurdepääs või local VM

**Soovitav:**
- 📦 REST API kontseptsiooni tundmine (on kavas olemas)
- 📦 YAML süntaksi tundmine (õpime)
- 📦 Git põhitõed (peatükk 4)

**EI OLE vajalik:**
- ❌ Programmeerimiskogemus (Node.js, Java, Python)
- ❌ Web arendus (HTML, CSS, JavaScript)
- ❌ SQL päringud

---

## 🚀 Implementeerimine

### Variant A: Täiesti Uus Koolituskava

**Loome täiesti uued peatükid:**
```
/home/user/hostinger/devops-koolitus/
├── 00-DEVOPS-KOOLITUSKAVA-RAAMISTIK.md
├── 01-DevOps-Sissejuhatus-VPS-Setup.md
├── 02-Linux-Pohitoed-DevOps.md
├── 03-PostgreSQL-Administraator.md
├── 04-Git-DevOps-Toovoos.md
├── 05-Docker-Pohimotted.md
├── 06-Dockerfile-Image-Loomine.md
├── 07-Docker-Compose.md
├── 08-Docker-Registry.md
├── 09-Kubernetes-Alused-K3s.md
├── 10-Pods-Deployments.md
├── 11-Services-Networking.md
├── 12-ConfigMaps-Secrets.md
├── 13-Persistent-Storage.md
├── 14-Ingress-LoadBalancing.md
├── 15-GitHub-Actions-Basics.md
├── 16-Docker-Build-Automation.md
├── 17-Kubernetes-Deployment-Automation.md
├── 18-Prometheus-Metrics.md
├── 19-Grafana-Visualization.md
├── 20-Logging-Log-Aggregation.md
├── 21-Alerting.md
├── 22-Security-Best-Practices.md
├── 23-High-Availability-Scaling.md
├── 24-Backup-Disaster-Recovery.md
├── 25-Troubleshooting-Debugging.md
└── labs/  # SAMA laborite struktuur nagu praegu
    ├── 01-docker-lab/
    ├── 02-docker-compose-lab/
    ├── 03-kubernetes-basics-lab/
    ├── 04-kubernetes-advanced-lab/
    ├── 05-cicd-lab/
    └── 06-monitoring-logging-lab/
```

**Plussid:**
- ✅ Puhas DevOps fookus
- ✅ Ei segaidu praeguse kavaga
- ✅ Võib säilitada mõlemad kavad (v1.0 ja v2.0)

**Miinused:**
- ❌ Tuleb kirjutada 25 uut peatükki
- ❌ Suurem töökoormus

---

### Variant B: Praeguse Kava Restruktuureerimine

**Kasutame ümber praeguseid peatükke:**
- Peatükk 2 (VPS) → Peatükk 1
- Peatükk 3 (PostgreSQL) → Peatükk 3 (lühendatud)
- Peatükk 4 (Git) → Peatükk 4 (lühendatud)
- Peatükk 12-25 (Docker, K8s, CI/CD) → Peatükid 5-25 (SAMA sisu!)

**Jätame VÄLJA:**
- ❌ Peatükk 5-8 (Backend arendus)
- ❌ Peatükk 9-11 (Frontend arendus)

**Lisame MINIMAALSELT:**
- Peatükk 2: Linux DevOps kontekstis (3h)
- "Rakenduste Mõistmine" lisad vajalikesse peatükkidesse

**Plussid:**
- ✅ Vähem uut kirjutamist
- ✅ Kasutame olemasolevat sisu

**Miinused:**
- ❌ Peatükkide numbrid muutuvad
- ❌ Segadus praeguse kavaga

---

### Variant C: Kahe Kava Säilitamine

**Praegune kava (v1.0):** Full-Stack DevOps
```
/home/user/hostinger/
├── 01-Sissejuhatus.md
├── 02-VPS-Esmane-Seadistamine.md
├── ...
└── 25-Kokkuvote-Jargmised-Sammud.md
```

**Uus kava (v2.0):** DevOps Administraator
```
/home/user/hostinger/devops-admin/
├── 01-DevOps-VPS-Setup.md
├── 02-Linux-Alused.md
├── ...
└── 25-Troubleshooting.md
```

**Ühised laborid:**
```
/home/user/hostinger/labs/
├── 01-docker-lab/
├── 02-docker-compose-lab/
├── ...
```

**Plussid:**
- ✅ Mõlemad kavad säilivad
- ✅ Kasutaja saab valida
- ✅ Full-stack arendajad saavad v1.0
- ✅ DevOps administraatorid saavad v2.0

**Miinused:**
- ❌ Kahekordne maintenance

---

## 🎓 Soovitused

### Soovitus 1: Variant A (Täiesti Uus Kava)

**Miks:**
- Puhas DevOps fookus
- Ei segaidu praeguse kavaga
- Võimaldab säilitada mõlemad kavad tulevikus
- Parim kasutajakogemus DevOps administraatoritele

**Implementeerimine:**
1. Loome uue kataloogi `/devops-admin/`
2. Kirjutame 25 uut peatükki (DevOps-keskne)
3. Kasutame SAMA labide struktuuri
4. Lisa dokumentatsioon: "Kahe kava võrdlus"

---

### Soovitus 2: Kasutatavad Ressursid

**Uuesti kasutatavad praegusest kavast:**
- ✅ Peatükk 2: VPS seadistamine (95% sama)
- ✅ Peatükk 3: PostgreSQL (lühendatud versioon)
- ✅ Peatükk 4: Git (lühendatud versioon)
- ✅ Peatükk 12: Docker põhimõtted (100% sama)
- ✅ Peatükk 14: Docker Compose (100% sama)
- ✅ Peatükk 15: Docker Registry (100% sama)
- ✅ Peatükk 16-25: Kubernetes, CI/CD, Production (100% sama!)

**Täiesti uued peatükid:**
- 📝 Peatükk 1: DevOps sissejuhatus
- 📝 Peatükk 2: Linux DevOps kontekstis
- 📝 "Rakenduste Mõistmine" lisad

**Hinnanguline töö:**
- ♻️ Uuesti kasutamine: 70%
- 📝 Uus kirjutamine: 30%
- ⏱️ Ajakulu: ~15-20 tundi (vs 93h teooria uuesti kirjutamine)

---

## 📞 Järgmised Sammud

1. **Otsus:** Vali implementeerimise variant (A, B või C)
2. **Struktuur:** Kinnita peatükkide struktuur
3. **Kirjutamine:** Alusta uute peatükkide loomisega
4. **Labide kohandamine:** Lisa labidele DevOps-keskne lähenemine
5. **Testimine:** Test koolituskava real students'iga

---

**Autor:** Claude Code (Sonnet 4.5)
**Kuupäev:** 2025-01-22
**Versioon:** 2.0 Draft
**Staatus:** 🚧 Ettepaneku faas

---

**Edu uue koolituskava loomisega! 🚀**
