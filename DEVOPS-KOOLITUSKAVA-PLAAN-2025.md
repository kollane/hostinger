# DevOps Administraatori Koolituskava - PÕHJALIK PLAAN 2025

**Versioon:** 2.0 DevOps-First
**Kuupäev:** 2025-01-22
**Staatus:** 📋 Planeerimisfaas
**Eesmärk:** Luua tänapäevane, praktiline, labipõhine DevOps administraatori koolituskava

---

## 📊 I. STRATEEGILINE ÜLEVAADE

### Mis Me Loome?

**Uus DevOps-keskne koolituskava**, mis:
- ✅ Fookus 100% DevOps administraatoril (mitte full-stack arendajal)
- ✅ Konteinerid ja orkestratsioon algusest peale (peatükk 5, mitte 12)
- ✅ Kasutab 2025 best practices (K3s, Loki, Trivy, Sealed Secrets)
- ✅ Põhineb valmis rakendustel (labs/apps/) - DevOps HALDAB, ei arenda
- ✅ Praktilised laborid 6 tk (Docker → K8s → CI/CD → Monitoring)
- ✅ 67-79 tundi (vs praegune 93h)

### Sihtgrupp

**Sobib:**
- DevOps insenerid
- Site Reliability Engineers (SRE)
- Platform Engineers
- Kubernetes administraatorid
- Süsteemiadministraatorid → konteineritele

**EI sobi:**
- Backend/Frontend arendajad (kasuta v1.0 kava)

### Võrdlus Praeguse Kavaga

| Aspekt | Praegune v1.0 | Uus v2.0 DevOps |
|--------|---------------|-----------------|
| **Kestus** | 93h | 67-79h (-21%) |
| **Backend arendus** | 17h (Node.js, Express, REST) | 0h (kasutame valmis apps) |
| **Frontend arendus** | 11h (HTML, CSS, JS) | 0h (kasutame valmis apps) |
| **DevOps fookus** | 65h (70%) | 67-79h (100%) |
| **Docker algus** | Peatükk 12 (pärast 44h) | Peatükk 5 (pärast 10h) |
| **Kubernetes algus** | Peatükk 15 (pärast 56h) | Peatükk 9 (pärast 24h) |
| **Sihtgrupp** | Full-stack arendaja | DevOps administraator |

---

## 🔧 II. 2025 BEST PRACTICES (KOHUSTUSLIKUD)

### Docker & Konteinerid

**KASUTAME:**
- ✅ **Alpine base images** (`node:18-alpine`, `eclipse-temurin:17-jre-alpine`)
  - Väike: 5MB vs Debian 120MB
  - Secure: vähem dependencies, väiksem attack surface

- ✅ **Multi-stage builds** (KOHUSTUSLIK!)
  ```dockerfile
  FROM gradle:8-jdk17 AS builder
  # Build stage: kogu build tooling

  FROM eclipse-temurin:17-jre-alpine AS runner
  # Runtime: AINULT JRE, väike image
  ```

- ✅ **Non-root users** (ALATI!)
  ```dockerfile
  RUN addgroup --system --gid 1001 appuser
  RUN adduser --system --uid 1001 appuser
  USER appuser
  ```

- ✅ **Layer caching optimization**
  ```dockerfile
  COPY package.json package-lock.json ./
  RUN npm ci --only=production
  COPY src/ ./src/  # Muutub tihti, eraldi layer
  ```

- ✅ **.dockerignore** (node_modules, .git, .env)
- ✅ **Health checks** (HEALTHCHECK directive)
- ✅ **Security scanning** (Trivy)

**VÄLTIME:**
- ❌ `latest` tag production'is
- ❌ Root kasutaja konteineris
- ❌ Debian/Ubuntu kui Alpine sobib
- ❌ Development dependencies production image'is

---

### Kubernetes

**KASUTAME:**
- ✅ **K3s** (lightweight Kubernetes, VPS-friendly)
  - 512MB RAM vs 2GB (K8s)
  - Üks binary, lihtne install
  - Production-ready (CNCF certified)

- ✅ **StatefulSets** andmebaaside jaoks (mitte Deployments!)
  - Ordered deployment (postgres-0 enne postgres-1)
  - Stable network IDs
  - Persistent storage per replica

- ✅ **InitContainers** database migrations'ile
  ```yaml
  initContainers:
  - name: liquibase-migration
    image: liquibase/liquibase:4.25-alpine
    # Käivitub ENNE main container'it
  ```

- ✅ **PersistentVolumeClaims** (local-path StorageClass K3s'is)
- ✅ **ConfigMaps** konfiguratsioonile (non-sensitive)
- ✅ **Secrets** mandaatidele (base64)
- ✅ **Pod Security Standards** (restricted profile)
  ```yaml
  apiVersion: v1
  kind: Namespace
  metadata:
    labels:
      pod-security.kubernetes.io/enforce: restricted
  ```

- ✅ **Network Policies** (micro-segmentation)
  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  # Allow AINULT frontend → backend traffic
  ```

- ✅ **HorizontalPodAutoscaler** (CPU-based scaling)
- ✅ **Resource requests & limits** (ALATI!)
  ```yaml
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  ```

**VÄLTIME:**
- ❌ Minikube production'is (ainult dev/testing)
- ❌ Docker Swarm (deprecated, low adoption)
- ❌ Deployments andmebaasidele (kasuta StatefulSets)
- ❌ PodSecurityPolicy (deprecated K8s 1.25+, kasuta PSS)
- ❌ Hostpath volumes production'is (kasuta proper PV)

---

### CI/CD

**KASUTAME:**
- ✅ **GitHub Actions** (mitte Jenkins, Travis, CircleCI)
  - Native GitHub integration
  - Free for public repos
  - 2000 min/month free private repos
  - Matrix strategy (parallel builds)

- ✅ **Self-hosted runners** Kubernetes'es
  ```yaml
  apiVersion: actions.summerwind.dev/v1alpha1
  kind: RunnerDeployment
  # Actions runner pod'idena K8s'is
  ```

- ✅ **Reusable workflows**
  ```yaml
  jobs:
    build:
      uses: ./.github/workflows/docker-build.yml
  ```

- ✅ **Matrix strategy** (multi-platform)
  ```yaml
  strategy:
    matrix:
      platform: [linux/amd64, linux/arm64]
  ```

- ✅ **Security scanning** pipeline'is
  - Trivy (image scanning)
  - Dependabot (dependency updates)
  - CodeQL (code scanning)

- ✅ **Multi-environment deployments** (dev, staging, prod)
- ✅ **GitOps kontseptsioon** (ArgoCD preview)

**VÄLTIME:**
- ❌ Jenkins (complex, resource-heavy, outdated UI)
- ❌ Travis CI (pricing changes, declining)
- ❌ CircleCI (kui GitHub Actions native)
- ❌ Hardcoded secrets workflows'is (use GitHub Secrets)

---

### Monitoring & Logging

**KASUTAME:**
- ✅ **Prometheus** (metrics collection)
  - CNCF graduated project
  - Pull model (scrapes /metrics endpoints)
  - PromQL query language

- ✅ **Grafana** (visualization)
  - Best-in-class dashboards
  - Multiple data sources
  - Alerting

- ✅ **Loki + Promtail** (log aggregation)
  - "Prometheus for logs"
  - Grafana Labs
  - Label-based indexing (cheap storage!)
  - Query logs koos metrics'iga

- ✅ **AlertManager** (alerting)
  - Prometheus native
  - Alert routing, grouping, silencing
  - Multiple notification channels

- ✅ **ServiceMonitors** (Prometheus Operator)
  ```yaml
  apiVersion: monitoring.coreos.com/v1
  kind: ServiceMonitor
  # Auto-discovery of /metrics endpoints
  ```

- ✅ **Structured logging** (JSON)
  ```json
  {"level":"info","timestamp":"2025-01-22T10:00:00Z","message":"User created","user_id":123}
  ```

**VÄLTIME:**
- ❌ ELK Stack (Elasticsearch + Logstash + Kibana)
  - Heavy (8GB+ RAM for Elasticsearch)
  - Expensive
  - Complex to manage
  - Use case: kui vaja full-text search

- ❌ Grafana Alerts only (use AlertManager)
- ❌ Plain text logs (use structured JSON)
- ❌ Fluentd/Fluent Bit (kui Promtail lihtne piisab)

---

### Database

**KASUTAME:**
- ✅ **Liquibase** (database migrations)
  - XML/YAML/SQL changesets
  - Rollback support (built-in)
  - Preconditions
  - Version tracking (databasechangelog table)

- ✅ **HikariCP** (connection pooling)
  - Fastest connection pool (benchmarked)
  - Spring Boot default
  - Low latency

- ✅ **PgBouncer** (kui high-traffic)
  - Connection multiplexing
  - 200 app connections → 25 DB connections
  - Lightweight (Golang)

- ✅ **StatefulSets** Kubernetes'es
  - PostgreSQL kui StatefulSet (mitte Deployment!)
  - PersistentVolumeClaim per replica

- ✅ **Automated backups** (CronJob)
  ```yaml
  apiVersion: batch/v1
  kind: CronJob
  spec:
    schedule: "0 2 * * *"  # 02:00 daily
  ```

**VÄLTIME:**
- ❌ Flyway kui Liquibase olemas (no free rollback)
- ❌ Manual SQL migrations (use Liquibase automation)
- ❌ `spring.jpa.hibernate.ddl-auto=create` (NEVER production!)
- ❌ No connection pooling (use HikariCP)

---

### Security

**KASUTAME:**
- ✅ **Trivy** (image scanning)
  - Fast, accurate
  - CNCF Sandbox project
  - CLI + CI/CD integration

- ✅ **Sealed Secrets** (GitOps-friendly)
  ```yaml
  apiVersion: bitnami.com/v1alpha1
  kind: SealedSecret
  # Encrypted in Git, decrypted in cluster
  ```

- ✅ **External Secrets Operator** (Vault, AWS Secrets Manager)
  ```yaml
  apiVersion: external-secrets.io/v1beta1
  kind: ExternalSecret
  # Sync secrets from external vaults
  ```

- ✅ **Network Policies** (Calico, Cilium)
- ✅ **Pod Security Standards** (restricted)
- ✅ **RBAC** (Role-Based Access Control)
- ✅ **TLS everywhere** (cert-manager + Let's Encrypt)
- ✅ **Non-root containers** (ALATI!)
- ✅ **Read-only filesystems** (kui võimalik)
- ✅ **Drop capabilities**
  ```yaml
  securityContext:
    capabilities:
      drop:
      - ALL
  ```

**VÄLTIME:**
- ❌ Clair (outdated scanner)
- ❌ Plaintext secrets Git'is
- ❌ No RBAC (kasuta least privilege)
- ❌ Root containers
- ❌ PodSecurityPolicy (deprecated, use PSS)

---

### Package Management

**KASUTAME:**
- ✅ **Helm 3** (Kubernetes package manager)
  - Chart'id (reusable K8s templates)
  - Templating (values.yaml)
  - Release management

- ✅ **Kustomize** (kui lihtne overlay piisab)
  - Built into kubectl
  - Patch-based
  - No templating

**VÄLTIME:**
- ❌ Helm 2 (deprecated, Tiller removed)
- ❌ Manual YAML copy-paste

---

## 📚 III. KOOLITUSKAVA STRUKTUUR (25 Peatükki)

### Moodul 1: LINUX JA VPS ALUSED (8-10h)

#### Peatükk 1: DevOps Sissejuhatus ja VPS Setup (3h)
- DevOps kultuur ja töövoog (Plan → Code → Build → Test → Release → Deploy → Operate → Monitor)
- Hostinger VPS (kirjakast @ 93.127.213.242)
- SSH keys (ed25519, mitte RSA)
- UFW firewall (ufw allow 22,80,443,6443/tcp)
- sudo ja kasutajate haldamine
- systemd teenuste haldamine

**Praktiline:**
- VPS access setup
- Firewall rules
- Non-root kasutaja loomine

**Viited:** -

---

#### Peatükk 2: Linux Põhitõed DevOps Kontekstis (3h)
- Failisüsteem (/etc, /var, /opt, /home)
- Protsessid (ps, top, systemctl)
- Logid (journalctl, /var/log)
- Võrk (ss, ip, netstat)
- Environment variables
- Cron jobs
- Permissions (chmod, chown)

**Praktiline:**
- journalctl log monitoring
- Cron job backup'i jaoks
- Process management

**Viited:** -

---

#### Peatükk 3: PostgreSQL Administraator Perspektiivist (2-4h)
- **MITTE ARENDUS** - ainult ADMINISTREERIMINE
- Docker PostgreSQL (PRIMAARNE)
- Native install (ALTERNATIIV)
- psql põhikäsud (\l, \c, \dt, \d)
- Backup (pg_dump, pg_restore)
- Performance monitoring (pg_stat_activity)
- Connection limits (max_connections)

**Praktiline:**
- PostgreSQL Docker container
- Backup ja restore
- Connection monitoring

**Viited:** -

---

#### Peatükk 4: Git DevOps Töövoos (2h)
- Git põhikäsud (clone, pull, commit, push)
- Branches ja merge
- .gitignore
- GitOps kontseptsioon
- Infrastructure as Code repos

**Praktiline:**
- Clone koolituskava repo
- Commit ja push

**Viited:** -

---

### Moodul 2: DOCKER JA KONTEINERISATSIOON (16-20h)

#### Peatükk 5: Docker Põhimõtted (4h)
- Konteinerid vs VMs
- Docker arhitektuur (daemon, client, images, containers)
- Docker lifecycle (pull → run → stop → rm)
- Port mapping (-p)
- Volumes (-v)
- Environment variables (-e)
- Networks (bridge, host)
- Logs ja debugging

**Praktiline:**
- Nginx konteiner
- PostgreSQL konteiner
- Node.js rakendus

**Viited:** Labor 1 Harjutus 1-2

---

#### Peatükk 6: Dockerfile ja Image Loomine (6-8h) ✅ VALMIS
**Detailne sisu:** `PEATUKK-6-TAIENDUS-TEHNOLOOGIAD.md`

**Sektsioonid:**
1. **Node.js Konteineridamine** (1.5h)
   - package.json, npm install
   - Multi-stage builds (900MB → 150MB)
   - .dockerignore
   - Health checks
   - Troubleshooting

2. **Java/Spring Boot Konteineridamine** (2h)
   - Traditional (WAR + Tomcat) vs Modern (JAR + Embedded Tomcat)
   - Gradle vs Maven
   - Multi-stage builds (470MB → 180MB)
   - JDK vs JRE
   - application.properties
   - JVM tuning

3. **Liquibase Database Migrations** (1.5h)
   - Changelog struktuur (XML/YAML)
   - databasechangelog tables
   - Docker Compose migrations
   - Kubernetes InitContainers
   - Troubleshooting (locks, checksums)

4. **Hibernate/HikariCP** (1-2h)
   - Connection pooling
   - Pool size tuning
   - PostgreSQL max_connections
   - PgBouncer
   - Monitoring (Actuator metrics)

**Praktiline:**
- Dockerfile Node.js'le (lihtne + optimized)
- Dockerfile Java'le (multi-stage)
- Liquibase setup
- HikariCP configuration

**Viited:** Labor 1 Harjutus 1A, 1B, 5

---

#### Peatükk 7: Docker Compose (4h)
- docker-compose.yml struktuur
- Services, networks, volumes
- depends_on + healthcheck
- Environment variables (.env)
- Multi-container orchestration
- Dev vs prod configs

**Praktiline:**
- Frontend + Backend + PostgreSQL
- Multi-service deployment
- Healthcheck dependencies

**Viited:** Labor 2

---

#### Peatükk 8: Docker Registry ja Image Haldamine (2-4h)
- Docker Hub
- Private registry (local)
- Image tagging (semantic versioning)
- Push/pull
- Security scanning (Trivy)
- Multi-platform images

**Praktiline:**
- Push Docker Hub'i
- Private registry setup
- Trivy scanning

**Viited:** Labor 1 (registry), Labor 5 (CI/CD push)

---

### Moodul 3: KUBERNETES ORKESTRATSIOON (22-26h)

#### Peatükk 9: Kubernetes Alused ja K3s Setup (4h)
- K8s arhitektuur (control plane, nodes)
- Pods, Deployments, Services
- kubectl CLI
- **K3s installeerimine VPS'is (kirjakast)**
- kubeconfig
- Namespaces
- Labels ja Selectors

**Praktiline:**
- K3s install kirjakast VPS'is
- kubectl põhikäsud
- Esimene Pod (Nginx)

**Viited:** Labor 3 Harjutus 1

---

#### Peatükk 10: Pods ja Deployments (4h)
- Pod manifest YAML
- Container spec
- Resource requests/limits
- Liveness/readiness probes
- Deployments ja ReplicaSets
- Rolling updates
- Rollbacks
- Self-healing

**Praktiline:**
- Deploy backend Deployment
- Scale replicas
- Rolling update
- Rollback

**Viited:** Labor 3 Harjutus 2

---

#### Peatükk 11: Services ja Networking (4h)
- Service types (ClusterIP, NodePort, LoadBalancer)
- DNS-based discovery
- Endpoints
- Load balancing
- Headless Services
- Network Policies (basic)

**Praktiline:**
- ClusterIP Service
- NodePort Service
- Service discovery test

**Viited:** Labor 3 Harjutus 3

---

#### Peatükk 12: ConfigMaps, Secrets ja Configuration (3h)
- ConfigMap (literal, file, env)
- Secret (Opaque, TLS, Docker registry)
- Environment variable injection
- Volume mount
- 12-Factor App config
- **Sealed Secrets** (GitOps)

**Praktiline:**
- ConfigMap rakenduse seadetele
- Secret DB credentials'ile
- Sealed Secret

**Viited:** Labor 3 Harjutus 4

---

#### Peatükk 13: Persistent Storage (4h)
- PersistentVolume (PV)
- PersistentVolumeClaim (PVC)
- StorageClass (local-path K3s'is)
- Access Modes (RWO, RWX, ROX)
- Reclaim Policies
- **StatefulSets** (PostgreSQL!)
- Volume snapshots

**Praktiline:**
- PV/PVC setup
- StatefulSet PostgreSQL
- Data persistence test

**Viited:** Labor 3 Harjutus 5

---

#### Peatükk 14: Ingress ja Load Balancing (3-5h)
- Ingress Controllers (Traefik K3s default)
- Ingress rules (path-based, host-based)
- TLS/SSL termination
- **cert-manager + Let's Encrypt**
- Annotations
- Rate limiting

**Praktiline:**
- Traefik Ingress
- HTTPS setup (Let's Encrypt)
- Multi-service routing

**Viited:** Labor 4 Harjutus 1

---

### Moodul 4: CI/CD JA AUTOMATISEERIMINE (10-12h)

#### Peatükk 15: GitHub Actions Basics (3h)
- Workflow süntaks (YAML)
- Triggers (push, PR, schedule, manual)
- Jobs ja steps
- Runners (GitHub-hosted vs self-hosted)
- Actions marketplace
- Secrets
- Matrix strategy

**Praktiline:**
- Hello World workflow
- Lint ja test workflow
- Multi-job workflow

**Viited:** Labor 5 Harjutus 1

---

#### Peatükk 16: Docker Build Automation (3h)
- Docker build GitHub Actions'is
- Multi-platform builds (buildx)
- Image tagging (SHA, semver)
- Docker Hub push
- Caching optimization
- **Trivy scanning CI's**

**Praktiline:**
- Automated Docker build
- Push Docker Hub'i
- Security scan

**Viited:** Labor 5 Harjutus 2

---

#### Peatükk 17: Kubernetes Deployment Automation (4-6h)
- kubectl apply GitHub Actions'is
- Kubeconfig management
- **Self-hosted runners K8s'es**
- Blue-green deployments
- Canary deployments (basic)
- Rollback automation
- Multi-environment (dev/staging/prod)
- **GitOps** (ArgoCD preview)

**Praktiline:**
- CI/CD pipeline (build → test → deploy)
- Automated K8s deployment
- Multi-environment

**Viited:** Labor 5 Harjutus 3-5

---

### Moodul 5: MONITORING, LOGGING, SECURITY (15-18h)

#### Peatükk 18: Prometheus ja Metrics (4h)
- Prometheus arhitektuur (pull model)
- Metrics types (counter, gauge, histogram, summary)
- PromQL põhitõed
- Exporters (node-exporter, postgres-exporter)
- **ServiceMonitors** (Prometheus Operator)
- Recording rules

**Praktiline:**
- Prometheus install K8s'es
- Metrics collection
- PromQL queries

**Viited:** Labor 6 Harjutus 1

---

#### Peatükk 19: Grafana ja Visualization (3h)
- Grafana setup
- Data sources (Prometheus)
- Dashboards
- Panels ja visualizations
- Variables ja templating
- Alerts
- Community dashboards

**Praktiline:**
- Grafana install
- Kubernetes dashboard
- Custom dashboard

**Viited:** Labor 6 Harjutus 2

---

#### Peatükk 20: Logging ja Log Aggregation (4h)
- Structured logging (JSON)
- **Loki arhitektuur** (label-based indexing)
- **Promtail** log collection
- LogQL queries
- Log retention
- Correlation (logs + metrics)

**Praktiline:**
- Loki + Promtail install
- Log aggregation
- LogQL Grafana's

**Viited:** Labor 6 Harjutus 3

---

#### Peatükk 21: Alerting (2h)
- **Prometheus AlertManager**
- Alert rules (PrometheusRules)
- Routing
- Notification channels (Slack, email)
- Alert fatigue prevention
- Runbooks

**Praktiline:**
- AlertManager setup
- Alert rules (CPU, memory, pod down)
- Slack notifications

**Viited:** Labor 6 Harjutus 4

---

#### Peatükk 22: Security Best Practices (4-6h)
- **Pod Security Standards** (restricted)
- **Network Policies**
- RBAC (Role-Based Access Control)
- **Sealed Secrets**
- **External Secrets Operator** (Vault)
- **Trivy** image scanning
- Non-root containers
- Read-only filesystems
- Drop capabilities
- TLS/SSL (cert-manager)

**Praktiline:**
- Network Policies
- Pod Security Standards
- RBAC rules
- Sealed Secrets
- Trivy scanning

**Viited:** Labor 4 Harjutus 3-4

---

### Moodul 6: PRODUCTION OPERATIONS (10-12h)

#### Peatükk 23: High Availability ja Scaling (4h)
- **HorizontalPodAutoscaler** (HPA)
- Vertical Pod Autoscaler (VPA)
- Cluster Autoscaler
- **PodDisruptionBudget**
- Anti-affinity
- Resource limits tuning
- **PgBouncer** (connection pooling)
- Caching (Redis intro)

**Praktiline:**
- HPA CPU-based
- PodDisruptionBudget
- Load testing (k6)

**Viited:** Labor 4 Harjutus 5

---

#### Peatükk 24: Backup ja Disaster Recovery (3h)
- PostgreSQL backup strategies:
  - **Konteineris: CronJob + pg_dump**
  - Väline: cron + pg_basebackup
- Volume snapshots
- Velero (Kubernetes backup)
- Restore procedures
- RTO ja RPO
- DR testing

**Praktiline:**
- Automated PostgreSQL backup (mõlemad variandid)
- CronJob K8s'es
- Restore test

**Viited:** Labor 3 (StatefulSet backup)

---

#### Peatükk 25: Troubleshooting ja Debugging (3-5h)
- kubectl debugging (logs, describe, exec, port-forward)
- Ephemeral containers
- Common issues:
  - ImagePullBackOff
  - CrashLoopBackOff
  - Pending Pods
  - Service unreachable
  - PVC Pending
- Network debugging (DNS, connectivity)
- Resource constraints (OOM, CPU throttling)
- PostgreSQL slow queries
- Application debugging

**Praktiline:**
- Broken deployment fix
- Network issue troubleshooting
- Performance bottleneck

**Viited:** Labor 6 Harjutus 5

---

## 🔨 IV. IMPLEMENTEERIMISE SAMMUD

### Samm 1: Planeerimine ja Audit ✅ VALMIS

**Tehtud:**
- ✅ Koostatud UUS-DEVOPS-KOOLITUSKAVA.md (põhiline ettepanek)
- ✅ Koostatud PEATUKK-6-TAIENDUS-TEKNOLOOGIAD.md (Node.js, Java, Liquibase, Hibernate)
- ✅ Koostatud DEVOPS-KOOLITUSKAVA-PLAAN-2025.md (see dokument)
- ✅ Best practices 2025 auditeeritud

---

### Samm 2: Peakoolituskava Integreerimine

**Tegevused:**
1. **Uuenda UUS-DEVOPS-KOOLITUSKAVA.md**
   - Integreeri Peatükk 6 täiendus (6-8h materjal)
   - Lisa laboriviited KÕIKIDESSE peatükkidesse
   - Täpsusta kestusi (67-79h)

2. **Lisa Best Practices märgid**
   - Iga tehnoloogia juures: ✅ KASUTAME vs ❌ VÄLTIME
   - Põhjendused (miks K3s, mitte Minikube prod'is)

3. **Täienda võrdlustabeleid**
   - v1.0 vs v2.0 võrdlus
   - Tehnoloogiate võrdlused (Maven vs Gradle, Liquibase vs Flyway)

**Tulemus:** Uuendatud UUS-DEVOPS-KOOLITUSKAVA.md (master document)

**Ajakulu:** 2-3 tundi

---

### Samm 3: Prioriteet 1 Peatükid (Kriitilised)

**Kirjutame ESIMESENA:**

#### 3.1 Peatükk 1: DevOps Sissejuhatus ja VPS Setup (3h)
**Fail:** `01-DevOps-Sissejuhatus-VPS-Setup.md`

**Struktuur:**
```markdown
# Peatükk 1: DevOps Sissejuhatus ja VPS Setup

## 1.1 DevOps Kultuur ja Töövoog
- DevOps definitsioon
- CALMS framework (Culture, Automation, Lean, Measurement, Sharing)
- DevOps lifecycle: Plan → Code → Build → Test → Release → Deploy → Operate → Monitor
- SRE vs DevOps

## 1.2 VPS Setup (kirjakast @ 93.127.213.242)
- SSH key generation (ed25519)
- SSH config (~/.ssh/config)
- Initial server setup
- UFW firewall (ports: 22, 80, 443, 6443)

## 1.3 User Management
- Non-root kasutaja
- sudo konfigureerimine
- SSH key-based auth

## 1.4 systemd Teenused
- systemctl käsud
- Service management
- Logs (journalctl)

## Praktilised Harjutused
- [ ] SSH key setup
- [ ] VPS ühendus
- [ ] Firewall rules
- [ ] Non-root kasutaja

## Kontrolli Tulemusi
- [ ] SSH key-based login töötab
- [ ] UFW firewall enabled
- [ ] Non-root kasutaja sudo õigustega

## Troubleshooting
- SSH connection refused
- Permission denied (publickey)
- Firewall blocking

## Viited
- Koolituskava: 00-DEVOPS-RAAMISTIK.md
- Best practices: DEVOPS-KOOLITUSKAVA-PLAAN-2025.md sektsioon II
```

**Ajakulu:** 4-6 tundi kirjutamiseks

---

#### 3.2 Peatükk 9: Kubernetes Alused ja K3s Setup (4h)
**Fail:** `09-Kubernetes-Alused-K3s-Setup.md`

**Põhjus:** Kubernetes on koolituskava TUUM - see peab olema täiuslik!

**Struktuur:**
```markdown
# Peatükk 9: Kubernetes Alused ja K3s Setup

## 9.1 Kubernetes Arhitektuur
- Control plane komponendid (API server, etcd, scheduler, controller-manager)
- Worker node komponendid (kubelet, kube-proxy, container runtime)
- Pods, Deployments, Services kontseptsioonid

## 9.2 K3s vs Kubernetes vs Minikube
- Võrdlustabel (resource usage, features, use cases)
- Miks K3s VPS'is? (512MB RAM vs 2GB)

## 9.3 K3s Installeerimine VPS'is (kirjakast)
- Prerequisites check
- K3s install script
- kubeconfig setup
- Cluster verification

## 9.4 kubectl CLI
- kubectl config
- Põhikäsud (get, describe, logs, exec, apply, delete)
- kubectl explain
- kubectl cheat sheet

## 9.5 Namespaces
- Default vs kube-system vs custom
- Resource isolation
- Namespace best practices

## 9.6 Labels ja Selectors
- Label syntax
- Selectors (equality-based, set-based)
- Common labels (app, version, component)

## Praktilised Harjutused
- [ ] K3s install kirjakast VPS'is
- [ ] kubectl config
- [ ] Namespace loomine
- [ ] Esimene Pod (Nginx)
- [ ] Labels ja selectors

## Kontrolli Tulemusi
- [ ] K3s cluster töötab
- [ ] kubectl get nodes → Ready
- [ ] Nginx pod Running
- [ ] kubectl logs töötab

## Troubleshooting
- K3s install fails
- kubectl connection refused
- Pod ImagePullBackOff
- Pod Pending

## Viited
- Lab 3 Harjutus 1: Cluster Setup & Pods
- Best practices: K3s (DEVOPS-KOOLITUSKAVA-PLAAN-2025.md)
```

**Ajakulu:** 6-8 tundi kirjutamiseks

---

#### 3.3 Peatükk 2: Linux Põhitõed DevOps Kontekstis (3h)
**Fail:** `02-Linux-Pohitoed-DevOps.md`

**Ajakulu:** 4-6 tundi

---

### Samm 4: Prioriteet 2 Peatükid (Olulised)

**Kirjutame TEISENA:**
- Peatükk 5: Docker Põhimõtted (4h)
- Peatükk 7: Docker Compose (4h)
- Peatükk 8: Docker Registry (2-4h)
- Peatükk 10-14: Kubernetes (Pods, Services, ConfigMaps, Storage, Ingress)
- Peatükk 15-17: CI/CD (GitHub Actions)
- Peatükk 18-21: Monitoring (Prometheus, Grafana, Loki, AlertManager)

**Ajakulu:** 15-20 peatükki × 4-6h = 60-120 tundi kirjutamiseks

---

### Samm 5: Prioriteet 3 Peatükid (Toetavad)

**Kirjutame VIIMASENA:**
- Peatükk 3: PostgreSQL Administraator (2-4h)
- Peatükk 4: Git DevOps Töövoos (2h)
- Peatükk 22: Security Best Practices (4-6h)
- Peatükk 23-25: Production Operations (HA, Backup, Troubleshooting)

**Ajakulu:** 6 peatükki × 3-5h = 18-30 tundi

---

### Samm 6: Labide Kohandamine (DevOps Perspektiiv)

**Iga labi README.md uuendamine:**

**Lisame "DevOps Administraatori Perspektiiv" sektsiooni:**

```markdown
## 🎯 DevOps Administraatori Perspektiiv

### Mida PEAD Teadma:
- ✅ Kuidas Dockerfile'e kirjutada (multi-stage builds)
- ✅ Kuidas image'id buildida ja optimeerida (Alpine, layer caching)
- ✅ Kuidas environment variables seadistada (ConfigMaps, Secrets)
- ✅ Kuidas health checks'e lisada (liveness, readiness)
- ✅ Kuidas troubleshoot'ida (logs, exec, describe)
- ✅ Kuidas security scanning'u teha (Trivy)

### Mida EI PEA Teadma:
- ❌ Node.js koodi kirjutamine (arendaja töö)
- ❌ Java Spring Boot arendus (arendaja töö)
- ❌ SQL päringute kirjutamine (arendaja töö)
- ❌ Frontend JavaScript (arendaja töö)

### Kasutame Valmis Rakendusi:
**Arendaja kirjutas:**
- `labs/apps/backend-nodejs/` (User Service)
- `labs/apps/backend-java-spring/` (Todo Service)
- `labs/apps/frontend/` (Web UI)

**DevOps administraator:**
- KONTEINERISEERIB need rakendused
- DEPLOY'dab Kubernetes'e
- MONITOORIB production'is
- TROUBLESHOOT'ib issues

**Analoogia:**
DevOps administraator : Rakendus = Automehhaanik : Auto

Automehhaanik EI PEAD teadma, kuidas autot DISAINIDA või TOOTA.
Automehhaanik PEAB teadma, kuidas autot HOOLDADA, PARANDADA, MONITOORIDA.
```

**Labid uuendamiseks:**
- Lab 1: Docker Põhitõed
- Lab 2: Docker Compose
- Lab 3: Kubernetes Basics
- Lab 4: Kubernetes Advanced
- Lab 5: CI/CD
- Lab 6: Monitoring & Logging

**Ajakulu:** 6 laborit × 2h = 12 tundi

---

### Samm 7: Kvaliteedikontroll ja Testimine

**Checklist iga peatüki jaoks:**

```markdown
## Kvaliteedikontrolli Checklist

### Sisu Kvaliteet
- [ ] **Praktiline fookus** (80% hands-on, 20% teooria)
- [ ] **2025 best practices** (ei vananenud tehnoloogiaid)
- [ ] **DevOps vaatenurk** (mitte arendaja vaatenurk)
- [ ] **Töötavad näited** (testitud VPS'is kirjakast)

### Struktuur
- [ ] **Laboriviited** olemas (Labor X Harjutus Y)
- [ ] **Troubleshooting sektsioon** (levinud probleemid + lahendused)
- [ ] **Kontrolli tulemusi** checklist
- [ ] **Praktiline harjutus** samm-sammult

### Tehnilised Detailid
- [ ] **Koodnäited** (syntax highlighting, copy-pasteable)
- [ ] **Käsud** (täpsed, töötavad)
- [ ] **YAML manifests** (valid syntax, testitud)
- [ ] **VPS-spetsiifiline** (kirjakast hostname, IP)

### Keel ja Stiil
- [ ] **Eesti keel** põhitekstis
- [ ] **English technical terms** (Docker, Kubernetes, Pod)
- [ ] **Consistent terminology** (konteiner, mitte container)
- [ ] **Clear explanations** (arusaadav algajale)

### Viited
- [ ] **Koolituskava viited** (00-DEVOPS-RAAMISTIK.md)
- [ ] **Best practices viited** (DEVOPS-KOOLITUSKAVA-PLAAN-2025.md)
- [ ] **Laboriviited** (Labor X)
- [ ] **External docs** (Kubernetes.io, Docker.com)
```

**Ajakulu:** 25 peatükki × 1h = 25 tundi

---

## 📅 V. AJAKAVA (Realistlik Hinnang)

### Variant A: Täielik Implementeerimine (Soovitatud)

**Samm 1:** Planeerimine ✅ **VALMIS** (2-3 päeva)

**Samm 2:** Peakava integreerimine (2-3h)

**Samm 3:** Prioriteet 1 peatükid (3 tk)
- Peatükk 1, 2, 9
- Ajakulu: 14-20h kirjutamist
- Kalender: 2-3 päeva

**Samm 4:** Prioriteet 2 peatükid (15 tk)
- Docker, Kubernetes, CI/CD, Monitoring
- Ajakulu: 60-120h kirjutamist
- Kalender: 8-15 päeva

**Samm 5:** Prioriteet 3 peatükid (6 tk)
- PostgreSQL, Git, Security, Production
- Ajakulu: 18-30h kirjutamist
- Kalender: 2-4 päeva

**Samm 6:** Labide kohandamine (6 tk)
- DevOps perspektiivi lisamine
- Ajakulu: 12h
- Kalender: 1-2 päeva

**Samm 7:** Kvaliteedikontroll (25 tk)
- Ajakulu: 25h
- Kalender: 3-4 päeva

**KOKKU:** 16-29 tööpäeva (3-6 nädalat)

---

### Variant B: Faasidena Implementeerimine

**Faas 1: MVP (Minimum Viable Product)**
- Samm 1-3: Plaan + Prioriteet 1 peatükid
- Tulemus: 3 peatükki valmis (1, 2, 9)
- Ajakulu: 5-8 päeva

**Faas 2: Tuum**
- Samm 4: Docker + Kubernetes peatükid
- Tulemus: 10 peatükki valmis (5-14)
- Ajakulu: 10-15 päeva

**Faas 3: CI/CD ja Monitoring**
- Samm 4 jätk: Peatükid 15-21
- Tulemus: 7 peatükki valmis
- Ajakulu: 7-10 päeva

**Faas 4: Lõplik Viimistlus**
- Samm 5-7: Prioriteet 3 + Labid + QA
- Tulemus: Kõik 25 peatükki valmis
- Ajakulu: 6-10 päeva

**KOKKU:** 28-43 päeva (4-9 nädalat) - faasides

---

## ✅ VI. KVALITEEDIKONTROLL

### Automaatne Kontrollimine

**Tehnilised kontrollid:**
```bash
# YAML syntax validation
yamllint peatukid/*.yaml

# Markdown lint
markdownlint peatukid/*.md

# Link checking
markdown-link-check peatukid/*.md

# Spell check (Estonian + English technical terms)
aspell check peatukid/*.md
```

---

### Manuaalne Review

**Iga peatüki review checklist:**

1. **Tehniline täpsus**
   - [ ] Käsud töötavad (testitud VPS'is)
   - [ ] YAML manifests valid
   - [ ] Versiooni numbrid õiged (K8s 1.28+, Docker 24+)

2. **Best practices compliance**
   - [ ] 2025 best practices järgitud
   - [ ] Security best practices (non-root, scanning)
   - [ ] Performance optimization (multi-stage builds)

3. **Pedagoogiline kvaliteet**
   - [ ] Eesmärgid selged
   - [ ] Praktiline harjutus samm-sammult
   - [ ] Troubleshooting kaasatud

4. **Laboriviited**
   - [ ] Iga peatükk viitab asjakohasele labile
   - [ ] Laboris vastav sisu olemas

---

### Testimine VPS'is

**Test environment:**
- VPS: kirjakast @ 93.127.213.242
- OS: Ubuntu 24.04.3 LTS
- User: janek

**Testimise workflow:**
```bash
# 1. Alusta puhtalt labalt
./labs/reset.sh

# 2. Järgi peatüki juhiseid täpselt
cat 05-Docker-Pohimotted.md

# 3. Dokumenteeri kõik käsud
script -a testing-log.txt

# 4. Kontrolli tulemusi
# Kas kõik käsud töötasid?
# Kas tulemus on oodatud?

# 5. Troubleshooting test
# Tekita tahtlikult viga
# Kas troubleshooting sektsioon aitab?
```

---

## 📝 VII. DELIVERABLES (Lõpptulemused)

### Dokumendid

**Koolituskava dokumentatsioon:**
1. ✅ `00-DEVOPS-RAAMISTIK.md` - Master curriculum framework
2. ✅ `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` - See dokument (plaan)
3. ✅ `UUS-DEVOPS-KOOLITUSKAVA.md` - Koondülevaade (integrated)
4. ✅ `PEATUKK-6-TAIENDUS-TEKNOLOOGIAD.md` - Node.js, Java, Liquibase, Hibernate

**25 peatükki (Estonian):**
```
01-DevOps-Sissejuhatus-VPS-Setup.md
02-Linux-Pohitoed-DevOps.md
03-PostgreSQL-Administraator.md
04-Git-DevOps-Toovoos.md
05-Docker-Pohimotted.md
06-Dockerfile-Image-Loomine.md (6-8h, includes PEATUKK-6-TAIENDUS)
07-Docker-Compose.md
08-Docker-Registry.md
09-Kubernetes-Alused-K3s-Setup.md
10-Pods-Deployments.md
11-Services-Networking.md
12-ConfigMaps-Secrets.md
13-Persistent-Storage.md
14-Ingress-LoadBalancing.md
15-GitHub-Actions-Basics.md
16-Docker-Build-Automation.md
17-Kubernetes-Deployment-Automation.md
18-Prometheus-Metrics.md
19-Grafana-Visualization.md
20-Logging-Log-Aggregation.md
21-Alerting.md
22-Security-Best-Practices.md
23-High-Availability-Scaling.md
24-Backup-Disaster-Recovery.md
25-Troubleshooting-Debugging.md
```

**Labid (6 tk, uuendatud):**
```
labs/01-docker-lab/README.md (+ DevOps perspektiiv)
labs/02-docker-compose-lab/README.md
labs/03-kubernetes-basics-lab/README.md
labs/04-kubernetes-advanced-lab/README.md
labs/05-cicd-lab/README.md
labs/06-monitoring-logging-lab/README.md
```

---

### Abimaterjalid

**Best practices guides:**
- Docker best practices checklist
- Kubernetes best practices checklist
- Security best practices checklist

**Cheat sheets:**
- kubectl cheat sheet (Estonian)
- Docker CLI cheat sheet
- Git DevOps workflow

**Troubleshooting guides:**
- Docker troubleshooting
- Kubernetes troubleshooting
- PostgreSQL troubleshooting

---

## 🎯 VIII. JÄRGMISED SAMMUD (Immediate Actions)

### Samm 1: Kinnitamine ✋ **OOTAB SINU KINNITUST**

**Küsimused:**
1. ✅ **Kas see plaan sobib?**
   - 25 peatükki, 67-79h, DevOps-first
   - 2025 best practices (K3s, Loki, Trivy, Sealed Secrets)
   - Prioriteedid: 1 (kriitiline) → 2 (oluline) → 3 (toetav)

2. ✅ **Kas best practices list on täielik?**
   - Docker: Alpine, multi-stage, non-root
   - K8s: K3s, StatefulSets, InitContainers, PSS, Network Policies
   - CI/CD: GitHub Actions, self-hosted runners
   - Monitoring: Prometheus+Grafana, Loki+Promtail (mitte ELK)
   - Security: Trivy, Sealed Secrets, External Secrets
   - Database: Liquibase, HikariCP, PgBouncer

3. ✅ **Kas soovid muuta prioriteete?**
   - Praegu: Peatükk 1, 2, 9 esimesena
   - Saad muuta järjekorda

4. ✅ **Milline implementeerimise variant?**
   - Variant A: Kõik korraga (16-29 päeva)
   - Variant B: Faasides (MVP → Tuum → CI/CD → Viimistlus)

---

### Samm 2: Implementeerimise Algus (Pärast Kinnitust)

**KOHE pärast sinu kinnitust:**

1. **Uuenda UUS-DEVOPS-KOOLITUSKAVA.md**
   - Integreeri Peatükk 6 täiendus
   - Lisa laboriviited kõikidesse peatükkidesse
   - Täpsusta kestusi

2. **Alusta Peatükk 1 kirjutamisega**
   - `01-DevOps-Sissejuhatus-VPS-Setup.md`
   - DevOps kultuur + VPS kirjakast setup
   - 3h materjal

3. **Commit ja push**
   - Git commit strategy: üks peatükk = üks commit
   - Descriptive commit messages

---

## 📞 IX. KONTAKT JA KÜSIMUSED

**Kui sul on küsimusi:**
- Best practices kohta (miks Loki, mitte ELK?)
- Prioriteetide kohta (miks peatükk 9 enne 5?)
- Struktuuri kohta (kas 6-8h peatükk on liiga pikk?)
- Ajakava kohta (kas 3-6 nädalat on realistlik?)

**Anna teada:**
- Mis vajab täpsustamist
- Mis peaks olema erinev
- Millised on sinu prioriteedid

---

## ✨ KOKKUVÕTE

**See plaan annab sulle:**
- ✅ **Täieliku ülevaate** kogu projektist (strateegia → struktuur → implementeerimine → kvaliteedikontroll)
- ✅ **2025 best practices** detailse loendiga (KASUTAME vs VÄLTIME)
- ✅ **25 peatüki struktuuri** (moodulid 1-6, laboriviited)
- ✅ **Implementeerimise roadmap** (7 sammu, prioriteedid, ajakava)
- ✅ **Kvaliteedikontrolli** (checklist, testimine VPS'is)
- ✅ **Deliverables** (25 peatükki + 6 labi + abimaterjalid)

**Valmis alustama, kui annad rohelist tuld!** 🚀

---

**Autor:** Claude Code (Sonnet 4.5)
**Kuupäev:** 2025-01-22
**Versioon:** 1.0 Final Plan
**Staatus:** 📋 Ootab kinnitust

**Edu koolituskava loomisega!** 🎓
