# DevOps Koolituskava Plaan 2025

**Versioon:** 1.0
**Kuupäev:** 2025-11-23
**Staatus:** Käimas (FAAS 2)

---

## Ülevaade

See dokument on **master plan** 31-peatükilise eestikeelse DevOps koolituskava loomiseks. Koolituskava toetab 10 praktilist laborit (Lab 1-10) ja katab täieliku DevOps administraatori oskuste komplekti.

**Kogu ulatus:**
- **31 peatükki** (Peatükid 1-30 + Peatükk 6A)
- **~52,000-65,000 sõna** (~104-129 lehekülge A4)
- **Fookus:** 70% teooria, 30% näited
- **Sihtgrupp:** IT-taustaga algajad DevOps'is
- **Keel:** Eesti keel, inglise terminid sulgudes

**Eesmärk:**
Luua põhjalik teoreetiline materjal, mis selgitab laborites praktiseeritavaid teemasid. Õppija saab lugeda peatükki enne või labori tegemise ajal, et mõista kontseptsioone ja põhimõtteid.

---

## Failide Struktuur

Iga peatükk on eraldi Markdown fail järgmise nimetusstandardiga:

```
/home/janek/projects/hostinger/
├── 01-DevOps-Sissejuhatus-VPS-Setup.md
├── 02-Linux-Pohitoed-DevOps-Kontekstis.md
├── 03-Git-DevOps-Toovoos.md
├── 04-Vorgutehnoloogia-Alused.md
├── resource/
│   ├── 05-Docker-Pohimotted.md                                    ✅ VALMIS
│   ├── 06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md   ✅ VALMIS
│   ├── 06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md ✅ VALMIS
│   └── 08A-Docker-Compose-Production-Development-Seadistused.md   ✅ VALMIS
├── 07-Docker-Imagite-Haldamine-Optimeerimine.md
├── 08-Docker-Compose.md
├── 09-PostgreSQL-Konteinerites.md
├── 10-Kubernetes-Sissejuhatus.md
├── 11-Pods-Rakenduste-Kaivitamine.md
├── 12-Deployments-ReplicaSets.md
├── 13-Services-Networking.md
├── 14-ConfigMaps-Secrets.md
├── 15-Persistent-Storage.md
├── 16-InitContainers-Database-Migrations.md
├── 17-Ingress-Load-Balancing.md
├── 18-Horizontal-Pod-Autoscaling.md
├── 19-Helm-Package-Manager.md
├── 20-GitHub-Actions-Basics.md
├── 21-Automated-Deployment-Pipeline.md
├── 22-Prometheus-Metrics.md
├── 23-Grafana-Visualization-Loki-Logging.md
├── 24-Alerting.md
├── 25-Security-Best-Practices.md
├── 26-Vault-Sealed-Secrets.md
├── 27-RBAC-Network-Policies.md
├── 28-GitOps-ArgoCD.md
├── 29-Backup-Disaster-Recovery.md
└── 30-Terraform-Infrastructure-as-Code.md
```

---

## Detailne Peatükkide Nimekiri

### FAAS 1: Põhitõed ja Sissejuhatus (Peatükid 1-4)

#### Peatükk 1: DevOps Sissejuhatus ja VPS Setup
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 1.5h teooria + 0.5h näited

**Põhiteemad:**
- DevOps definitsioon ja põhimõisted
- DevOps vs traditsiooniline IT (Waterfall vs Agile vs DevOps)
- DevOps kultuur (collaboration, automation, measurement)
- CI/CD põhimõtted (Continuous Integration, Continuous Delivery/Deployment)
- Infrastructure as Code (IaC) kontseptsioon
- VPS (Virtual Private Server) setup
  - Ubuntu 22.04/24.04 install
  - SSH access (public key authentication)
  - Kasutajate haldus (useradd, usermod, groups)
  - Õigused (chmod, chown)
  - Firewall põhitõed (ufw - uncomplicated firewall)
- DevOps tööriistad ülevaade (Docker, Kubernetes, Git, CI/CD tools)

**Seos laboritega:** Üldine taust kõigile laboritele

---

#### Peatükk 2: Linux Põhitõed DevOps Kontekstis
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Bash käsud failide haldamiseks
  - Navigeerimine: ls, cd, pwd, tree
  - Failide manipuleerimine: cp, mv, rm, mkdir, touch
  - Failide vaatamine: cat, less, head, tail, grep
  - Otsimine: find, locate
- Failide õigused
  - chmod (numeric ja symbolic notation)
  - chown, chgrp
  - Spetsiaalsed õigused (setuid, setgid, sticky bit)
- Kasutajad ja grupid
  - useradd, usermod, userdel
  - groupadd, groupmod
  - /etc/passwd, /etc/group
- Protsessid
  - ps, top, htop
  - kill, killall, pkill
  - Background/foreground (&, fg, bg, jobs)
- Süsteemiteenused
  - systemctl (start, stop, restart, enable, disable, status)
  - journalctl (log vaatamine)
- Package management
  - apt (update, upgrade, install, remove, search)
  - apt-cache policy
- Environment variables
  - export, printenv, echo $VAR
  - .bashrc, .profile

**Seos laboritega:** Kõik laborid (Linux CLI baas)

---

#### Peatükk 3: Git DevOps Töövoos
**Staatus:** ⏳ Planeeritud
**Maht:** 6-8 lk (~3,000-4,000 sõna)
**Kestus:** 1.5h teooria + 0.5h näited

**Põhiteemad:**
- Git alused
  - Versioonikontrolli kontseptsioon
  - Repository (local vs remote)
  - Working directory, staging area, commit history
- Põhikäsud
  - git init, clone
  - git add, commit, push, pull
  - git status, log, diff
- Branching strategies
  - Feature branching
  - Git Flow (main, develop, feature, release, hotfix)
  - GitHub Flow (main, feature branches)
- Collaboration workflow
  - Pull requests (review, approve, merge)
  - Merge conflicts resolution
  - Code review best practices
- Git DevOps kontekstis
  - .gitignore patterns
  - Semantic versioning (tags: v1.0.0, v1.1.0)
  - Commit message conventions
  - Branch protection rules
- Git hooks (pre-commit, post-commit eelvaade)

**Seos laboritega:** Lab 5 (CI/CD), Lab 8 (GitOps)

---

#### Peatükk 4: Võrgutehnoloogia Alused DevOps'is
**Staatus:** ⏳ Planeeritud
**Maht:** 6-8 lk (~3,000-4,000 sõna)
**Kestus:** 1.5h teooria + 0.5h näited

**Põhiteemad:**
- Võrgu põhimõisted
  - IP aadressid (IPv4, public vs private, CIDR notation)
  - Portid ja protokollid (TCP, UDP)
  - DNS (domain name system, A/AAAA/CNAME records)
- Levinud portid DevOps'is
  - HTTP: 80, HTTPS: 443
  - SSH: 22
  - PostgreSQL: 5432, MySQL: 3306
  - Custom app ports: 3000, 8080, 8081
- Load balancing kontseptsioon
  - Round-robin, least connections
  - Health checks
- Reverse proxy
  - Nginx reverse proxy eelvaade
  - Ingress (Kubernetes context)
- Networking tools
  - ping, traceroute, nslookup/dig
  - netstat, ss, lsof
  - curl, wget
- Firewall
  - ufw (uncomplicated firewall)
  - Allow/deny rules

**Seos laboritega:** Kõik laborid (networking on kõikjal)

---

### FAAS 2: Docker ja Konteinerid (Peatükid 5-9) ⭐ KÕRGE PRIORITEET

#### Peatükk 5: Docker Põhimõtted
**Staatus:** ✅ **VALMIS** (2025-11-23)
**Maht:** 16 lk (~8,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Miks konteinerid? (VM vs konteinerid võrdlus)
- Docker arhitektuur (client, daemon, registry)
- Docker image vs container
- Docker workflow (Dockerfile → build → push → pull → run)
- Docker'i installeerimine Ubuntu'sse
- Põhikäsud (run, ps, images, pull, rm, rmi)
- Esimesed näited (hello-world, Nginx, Ubuntu bash)

**Seos laboritega:** Lab 1 (Docker Põhitõed)

---

#### Peatükk 6: Dockerfile ja Rakenduste Konteineriseerimise Detailid
**Staatus:** ✅ **VALMIS** (2025-11-23)
**Maht:** 18 lk (~9,000 sõna)
**Kestus:** 2.5h teooria + 1.5h näited

**Põhiteemad:**
- Dockerfile struktuur ja põhimõtted
- Dockerfile instruktsionid (FROM, WORKDIR, COPY, ADD, RUN, ENV, ARG, EXPOSE, USER, CMD, ENTRYPOINT, HEALTHCHECK)
- Multi-stage builds (build stage → runtime stage)
- Base image valik (Alpine vs Debian vs Distroless)
- Layer caching optimization
- .dockerignore fail
- Security best practices (non-root users, minimal images)

**Seos laboritega:** Lab 1 (Dockerfile loomine)

---

#### Peatükk 6A: Java/Spring Boot ja Node.js Rakenduste Konteineriseerimise Spetsiifika
**Staatus:** ✅ **VALMIS** (2025-01-25, uuendatud corporate proxy ja Nexus käsitlusega)
**Maht:** 26 lk (~14,000 sõna)
**Kestus:** 4h teooria + 2h näited

**Põhiteemad:**
- **Traditsiooniline Java deployment (WAR Tomcat'is):**
  - WAR faili struktuur
  - Tomcat server setup ja deployment workflow
  - Probleemid (port conflicts, shared JVM, downtime, JAR hell)
- **Spring Boot embedded server:**
  - Executable JAR (Fat JAR)
  - Embedded Tomcat/Jetty/Undertow
  - Spring Boot Actuator (health checks, metrics)
  - application.properties configuration
- **Põhjalik võrdlus: Tomcat WAR vs Spring Boot Container:**
  - Deployment workflow võrdlus
  - Resource usage võrdlus
  - Tabel (downtime, isolatsioon, skaleeritavus, monitoring)
- **Java konteineriseerimise spetsiifika:**
  - Build tools (Maven vs Gradle)
  - Multi-stage builds (JDK → JRE)
  - JVM tuning konteinerites
    - Container-aware JVM (Java 10+)
    - Heap size tuning (-Xmx, -Xms, -XX:MaxRAMPercentage)
    - Garbage Collector tuning (G1GC, ZGC)
  - Image optimization (JDK vs JRE, Alpine, Distroless)
- **Node.js konteineriseerimise põhitõed:**
  - npm ci --only=production
  - Multi-stage builds (TypeScript compile → runtime)
  - NODE_ENV=production
  - Non-root user (node user)
- **Corporate võrgu piirangud: Proxy seadistamine Docker build'is:**
  - 8 meetodit võrdlustabeliga (portability, security, CI/CD)
  - ARG multi-stage build (soovitatud production)
  - Gradle vs npm proxy erinevused
  - daemon.json vs Dockerfile trade-offs
  - BuildKit secrets (modern alternative)
  - CI/CD integratsioon (GitHub Actions vihje)
  - Troubleshooting (3 levinud probleemi + lahendused)
  - Flowchart: "Millist meetodit kasutada?"
  - **Lisastsenaarium: Sonatype Nexus Repository Manager (UUS!):**
    - Nexus vs HTTP proxy erinevus (tabel 6 aspektiga)
    - Gradle + Nexus (build.gradle repositories + ARG credentials)
    - Maven + Nexus (settings.xml mirror + ARG credentials)
    - npm + Nexus (.npmrc registry + base64 token)
    - Nexus + HTTP proxy kombinatsioon (NO_PROXY exception)
    - Credentials management (ARG build-time, BuildKit secrets, CI/CD)
    - Troubleshooting (401 unauthorized, SSL errors, proxy conflicts)
    - Best practices (6 punkti)

**Seos laboritega:** Lab 1 (User Service Node.js, Todo Service Java Spring Boot, corporate proxy ja Nexus käsitlus)

---

#### Peatükk 7: Docker Image'ite Haldamine ja Optimeerimine
**Staatus:** ⏳ Planeeritud
**Maht:** 6-8 lk (~3,000-4,000 sõna)
**Kestus:** 1.5h teooria + 0.5h näited

**Põhiteemad:**
- Docker build, tag, push workflow
- Image naming conventions ([registry]/[username]/[repository]:[tag])
- Docker Hub vs private registries (Harbor, ECR, GCR, ACR)
- Image layer'id ja layer cache
- Image size optimization
  - Multi-stage builds
  - Alpine base images
  - .dockerignore
  - Cleanup (apt clean, npm cache clean)
- Image security scanning (Trivy eelvaade)
- Image versioning strategies (semantic versioning, git SHA tags)
- Docker registry authentication (docker login)
- docker history (layer'ite analüüs)
- Dive tool (image layer explorer)

**Seos laboritega:** Lab 1 (Image build ja push)

---

#### Peatükk 8: Docker Compose
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Docker Compose kontseptsioon (multi-container orchestration)
- docker-compose.yml struktuur
  - version (deprecated v3+)
  - services (container definitions)
  - networks (custom networks)
  - volumes (data persistence)
- Services definition
  - image vs build
  - ports (host:container mapping)
  - environment variables (.env file)
  - depends_on (startup order)
  - healthcheck
  - restart policies (no, always, on-failure, unless-stopped)
- Networking
  - Default bridge network
  - Custom networks (service discovery via DNS)
- Volumes
  - Named volumes vs bind mounts
  - Volume drivers
- Environment management
  - docker-compose.override.yml pattern
  - Environment-specific configs (dev vs prod)
  - .env file usage
- Docker Compose commands
  - docker compose up/down
  - docker compose ps/logs
  - docker compose exec/run
  - docker compose build/pull
- Database migrations (Liquibase eelvaade)

**Seos laboritega:** Lab 2 (Docker Compose full-stack setup)

---

#### Peatükk 8A: Docker Compose Production vs Development Seadistused
**Staatus:** ✅ **VALMIS** (2025-01-25)
**Maht:** 15 lk (~7,500 sõna)
**Kestus:** 3h teooria + 1h praktiline harjutus

**Põhiteemad:**
- **Kolm port binding strateegiat:**
  - Avalik binding (0.0.0.0) - ohtlik, millal kasutada
  - Localhost-only binding (127.0.0.1) - turvaline debug
  - Pole porte - maksimaalne turvalisus
- **Production lähenemine:**
  - Ei avalda backend/database porte üldse
  - Teenused suhtlevad ainult Docker võrgus
  - Defense in depth, compliance (PCI-DSS, GDPR)
  - Debug'imine: logs, exec
- **Development lähenemine:**
  - docker-compose.override.yml pattern
  - Localhost-only port binding (127.0.0.1)
  - SSH debug võimalus
  - Turvaline + mugav
- **Turvalisuse parimad tavad:**
  - Defense in depth (Firewall → Port Binding → Network Segmentation → Auth)
  - Principle of least privilege
  - Network segmentation (frontend/backend/database võrgud)
  - Regulaarne auditeerimine
- **Otsustuspuu:** Kuidas valida õiget lähenemist
- **Praktiline harjutus:** Turvalise stack'i loomine

**Seos laboritega:** Lab 2 Exercise 3 (Network Segmentation, Steps 4-5)

---

#### Peatükk 8B: Nginx Reverse Proxy Docker Keskkonnas
**Staatus:** ✅ **VALMIS** (2025-01-25)
**Maht:** 18 lk (~9,000 sõna)
**Kestus:** 3.5h teooria + 1.5h praktiline harjutus

**Põhiteemad:**
- **Reverse proxy kontseptsioon:**
  - Forward proxy vs reverse proxy
  - Nginx kui reverse proxy
  - Kasutusjuhud mikroteenuste arhitektuuris
- **Nginx konfiguratsioon Docker Compose's:**
  - location block'id (frontend failid vs API routing)
  - proxy_pass direktiiv ja trailing slash
  - proxy_set_header direktiivid (Host, X-Real-IP, X-Forwarded-*)
  - Volume mount'id nginx.conf jaoks
- **CORS probleemide lahendamine:**
  - Mis on CORS ja miks see tekib
  - Kuidas reverse proxy lahendab CORS'i
  - Relatiivne URL vs absoluutne URL frontend'is
- **Arhitektuur ja turvalisus:**
  - Üks avalik port (8080), backend'id peidetud
  - Docker Compose teenuste definitsioonid
  - Network segmentation (frontend-network, backend-network)
  - Defense in depth
- **Best practices:**
  - Backend'id pole avalikud (pole porte)
  - Read-only mount'id
  - Rate limiting ja IP filtering
  - Performance optimisatsioonid (caching, gzip, connection pooling)
- **Troubleshooting:**
  - 502 Bad Gateway
  - 404 Not Found API päringutele
  - CORS vead hoolimata proxy'st
  - Timeout'id ja performance probleemid

**Seos laboritega:** Lab 2 Exercise 2 (Frontend + Nginx reverse proxy)

---

#### Peatükk 9: PostgreSQL Konteinerites
**Staatus:** ⏳ Planeeritud
**Maht:** 5-7 lk (~2,500-3,500 sõna)
**Kestus:** 1.5h teooria + 1h näited

**Põhiteemad:**
- PostgreSQL official Docker image
- Volume mounting andmete püsivuseks
  - Named volume: postgres-data:/var/lib/postgresql/data
  - Data persistence across container restarts
- Environment variables
  - POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
  - PGDATA (custom data directory)
- Connection strings konteinerite vahel
  - postgresql://user:password@postgres:5432/dbname
  - Service discovery Docker Compose'is (hostname = service name)
- PostgreSQL configuration konteineris
  - Custom postgresql.conf (volume mount või ENV)
  - max_connections, shared_buffers, work_mem
- Backup ja restore
  - pg_dump konteineris
  - docker exec postgres pg_dump -U user dbname > backup.sql
  - Restore: docker exec -i postgres psql -U user dbname < backup.sql
- Liquibase database migrations
  - Liquibase kontseptsioon (changelog, changesets)
  - Liquibase Docker image
  - InitContainer Kubernetes'es (eelvaade)

**Seos laboritega:** Lab 1 (PostgreSQL konteinerites), Lab 2 (Compose + migrations)

---

### FAAS 3: Kubernetes Alused (Peatükid 10-17)

#### Peatükk 10: Kubernetes Sissejuhatus
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Kubernetes vs Docker Compose (millal kasutada?)
- Kubernetes arhitektuur
  - Control Plane: API Server, etcd, Scheduler, Controller Manager
  - Worker Nodes: kubelet, kube-proxy, container runtime
- Kubernetes objektid (Pods, Services, Deployments, ReplicaSets, ConfigMaps, Secrets jne)
- Kubernetes distributions
  - K3s (lightweight, VPS-friendly)
  - Minikube (local development)
  - K8s (full Kubernetes)
  - EKS, GKE, AKS (managed cloud)
- kubectl install ja konfigureerimine
  - kubeconfig (~/.kube/config)
  - Contexts ja clusters
- K3s setup VPS'is
  - K3s install (single-node cluster)
  - kubectl get nodes
- kubectl põhikäsud
  - get, describe, logs, exec
  - apply, delete
  - kubectl cheat sheet

**Seos laboritega:** Lab 3 (Kubernetes Basics)

---

#### Peatükk 11: Pods ja Rakenduste Käivitamine
**Staatus:** ⏳ Planeeritud
**Maht:** 6-7 lk (~3,000-3,500 sõna)
**Kestus:** 1.5h teooria + 0.5h näited

**Põhiteemad:**
- Pod kontseptsioon (väikseim deployable üksus)
- Pod lifecycle (Pending, Running, Succeeded, Failed, Unknown)
- Single-container vs multi-container Pods
- kubectl run, get, describe, logs, exec
- Pod YAML manifest struktuur
  - apiVersion, kind, metadata, spec
  - containers[], image, ports, env
- Pod restart policies (Always, OnFailure, Never)
- Resource requests ja limits (eelvaade)
- Sidecar pattern (eelvaade)

**Seos laboritega:** Lab 3 (Pods loomine)

---

#### Peatükk 12: Deployments ja ReplicaSets
**Staatus:** ⏳ Planeeritud
**Maht:** 7-9 lk (~3,500-4,500 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Deployment vs Pod (miks mitte käivitada Pode otse?)
- ReplicaSet rolli (desired vs current replicas)
- Deployment YAML struktuur
  - replicas, selector, template
- Deklaratiivne vs imperatiivne deployment
- Self-healing (Pod crashib → ReplicaSet loob uue)
- Scaling (manual ja eelvaade HPA jaoks)
  - kubectl scale deployment myapp --replicas=5
- Rolling updates
  - Update strategy (RollingUpdate vs Recreate)
  - maxSurge, maxUnavailable
- Rollbacks
  - kubectl rollout history/undo
  - Revision tracking

**Seos laboritega:** Lab 3 (Deployments loomine)

---

#### Peatükk 13: Services ja Networking
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Service kontseptsioon (stable endpoint Pod'ide jaoks)
- Service tüübid
  - ClusterIP (default, internal only)
  - NodePort (external access via node IP:port)
  - LoadBalancer (cloud provider LB)
  - ExternalName (DNS CNAME)
- DNS-based service discovery
  - service-name.namespace.svc.cluster.local
  - Sama namespace: lihtsalt service-name
- Label selectors (labels: app=myapp)
- Port mapping (port, targetPort, nodePort)
- Endpoints (Pod IP'de list)
- Load balancing Pod'ide vahel
- kubectl port-forward (local testing)

**Seos laboritega:** Lab 3 (Services loomine)

---

#### Peatükk 14: ConfigMaps ja Secrets
**Staatus:** ⏳ Planeeritud
**Maht:** 6-8 lk (~3,000-4,000 sõna)
**Kestus:** 1.5h teooria + 0.5h näited

**Põhiteemad:**
- ConfigMap kasutamine
  - Environment variables (envFrom, env)
  - Volume mount (config files)
  - kubectl create configmap
- Secrets
  - base64 encoding (mitte encryption!)
  - Secret types (Opaque, TLS, Docker registry)
  - Environment variables vs volume mounts
- 12-Factor App configuration pattern
- Best practices
  - Secrets management (Vault eelvaade Lab 7 jaoks)
  - Immutable ConfigMaps/Secrets
- Secret rotation

**Seos laboritega:** Lab 3 (ConfigMaps ja Secrets)

---

#### Peatükk 15: Persistent Storage
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Volumes vs Persistent Volumes
- Volume types (emptyDir, hostPath, configMap, secret, PVC)
- PersistentVolume (PV) ja PersistentVolumeClaim (PVC)
- StorageClass
  - Dynamic provisioning
  - local-path (K3s default)
  - Cloud storage classes (EBS, GCE PD, Azure Disk)
- Volume lifecycle (Retain, Delete, Recycle)
- Access modes (ReadWriteOnce, ReadOnlyMany, ReadWriteMany)
- StatefulSets vs Deployments (andmebaasidele)
- Volume expansion

**Seos laboritega:** Lab 3 (PostgreSQL PVC)

---

#### Peatükk 16: InitContainers ja Database Migrations
**Staatus:** ⏳ Planeeritud
**Maht:** 5-6 lk (~2,500-3,000 sõna)
**Kestus:** 1h teooria + 0.5h näited

**Põhiteemad:**
- InitContainer kontseptsioon
- InitContainer vs main container
- Kasutamise näited
  - Database migration (Liquibase)
  - Pre-requisite checks (DB readiness)
  - Setup scripts (config generation)
- Liquibase migrations InitContainer'iga
  - Liquibase changelog
  - InitContainer YAML
- depends_on ekvivalent Kubernetes'es

**Seos laboritega:** Lab 3 (Database migrations)

---

#### Peatükk 17: Ingress ja Load Balancing
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Ingress kontseptsioon (HTTP/HTTPS routing)
- Ingress Controller (nginx-ingress, Traefik, HAProxy)
- Ingress YAML struktuur
  - rules[], paths[], backend (service + port)
- Path-based routing (/api/users → user-service, /api/todos → todo-service)
- Host-based routing (app1.example.com, app2.example.com)
- TLS termination (HTTPS)
  - cert-manager (Let's Encrypt eelvaade)
- Annotations (rewrite, CORS, rate limiting)
- Ingress vs LoadBalancer Service

**Seos laboritega:** Lab 4 (Ingress setup)

---

### FAAS 4: Kubernetes Täiustatud + CI/CD (Peatükid 18-21)

#### Peatükk 18: Horizontal Pod Autoscaling
**Staatus:** ⏳ Planeeritud
**Maht:** 6-7 lk (~3,000-3,500 sõna)
**Kestus:** 1.5h teooria + 0.5h näited

**Põhiteemad:**
- HPA kontseptsioon (automaatne scaling)
- Metrics Server install
- CPU/memory-based autoscaling
- HPA YAML struktuur
  - minReplicas, maxReplicas
  - targetCPUUtilizationPercentage
- Custom metrics (edasijõudnud)
- Testing HPA (load testing)

**Seos laboritega:** Lab 4 (HPA setup)

---

#### Peatükk 19: Helm Package Manager
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Helm vs kubectl apply (miks Helm?)
- Helm kontseptsioonid (Chart, Release, Repository)
- Chart struktuur (Chart.yaml, values.yaml, templates/)
- Template engine (Go templates)
  - {{ .Values.image.repository }}
  - {{ .Release.Name }}
  - if/else, range, with
- Helm käsud
  - helm install, upgrade, rollback, uninstall
  - helm list, status
- Values override strategies
  - --set, -f values.yaml
  - Environment-specific values (values-dev.yaml, values-prod.yaml)
- Helm repository management
  - helm repo add/update
  - Artifact Hub

**Seos laboritega:** Lab 4 (Helm charts loomine)

---

#### Peatükk 20: GitHub Actions Basics
**Staatus:** ⏳ Planeeritud
**Maht:** 7-9 lk (~3,500-4,500 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- CI/CD kontseptsioonid (Continuous Integration, Continuous Delivery/Deployment)
- GitHub Actions arhitektuur (Workflows, Jobs, Steps, Runners)
- Workflow süntaks (YAML)
  - on (triggers: push, pull_request, workflow_dispatch, schedule)
  - jobs[], steps[]
  - runs-on (ubuntu-latest, self-hosted)
- GitHub Secrets management
  - GITHUB_TOKEN (automatic)
  - Custom secrets (DOCKER_USERNAME, DOCKER_PASSWORD)
- Matrix strategy (multi-platform builds)
- Artifacts (build artifacts sharing)
- Caching (node_modules, Gradle/Maven dependencies)

**Seos laboritega:** Lab 5 (GitHub Actions workflows)

---

#### Peatükk 21: Automated Deployment Pipeline
**Staatus:** ⏳ Planeeritud
**Maht:** 7-9 lk (~3,500-4,500 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Docker build ja push automation
  - docker/login-action
  - docker/build-push-action
- Helm deployment automation
  - helm upgrade --install
  - kubectl apply -f
- Multi-environment strategy (dev, staging, prod)
  - Environment-specific workflows
  - Deployment approvals (GitHub Environments)
- Quality gates
  - Testing (unit tests, integration tests)
  - Linting (ESLint, Checkstyle)
  - Security scanning (Trivy, Snyk)
- Rollback mechanisms
- Deployment notifications (Slack, email)

**Seos laboritega:** Lab 5 (CI/CD pipeline)

---

### FAAS 5: Monitoring ja Logging (Peatükid 22-24)

#### Peatükk 22: Prometheus Metrics
**Staatus:** ⏳ Planeeritud
**Maht:** 9-11 lk (~4,500-5,500 sõna)
**Kestus:** 2.5h teooria + 1.5h näited

**Põhiteemad:**
- Prometheus arhitektuur (Server, Exporters, Alertmanager, Pushgateway)
- Prometheus data model (metrics, labels, time series)
- Metric types (Counter, Gauge, Histogram, Summary)
- PromQL query language
  - Instant queries, range queries
  - Functions (rate, increase, sum, avg)
  - Aggregation (by, without)
- ServiceMonitor CRD (Prometheus Operator)
- Application instrumentation
  - Node.js (prom-client)
  - Java Spring Boot (Micrometer + Actuator)
- kube-state-metrics, node-exporter
- Prometheus configuration (scrape_configs, targets)

**Seos laboritega:** Lab 6 (Prometheus setup)

---

#### Peatükk 23: Grafana Visualization ja Loki Logging
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Grafana arhitektuur
- Datasources (Prometheus, Loki, InfluxDB jne)
- Dashboard creation
  - Panels (Graph, Stat, Table, Logs)
  - Variables (templating)
  - Annotations
- PromQL queries dashboardides
- Dashboard JSON export/import
- Loki arhitektuur (labels vs indexed data)
- LogQL query language
  - Label selectors {app="myapp"}
  - Line filters |= "error"
  - Aggregation (count_over_time, rate)
- Promtail DaemonSet (log collection)
- Logs + metrics correlation

**Seos laboritega:** Lab 6 (Grafana + Loki setup)

---

#### Peatükk 24: Alerting
**Staatus:** ⏳ Planeeritud
**Maht:** 6-7 lk (~3,000-3,500 sõna)
**Kestus:** 1.5h teooria + 0.5h näited

**Põhiteemad:**
- Prometheus AlertManager
- Alert rules (PrometheusRule CRD)
  - alert, expr, for, labels, annotations
- Alert severity levels (critical, warning, info)
- Notification channels (Slack, email, PagerDuty)
- Alert grouping, inhibition, silencing
- Runbook links (annotations)

**Seos laboritega:** Lab 6 (Alerting setup)

---

### FAAS 6: Security (Peatükid 25-27)

#### Peatükk 25: Security Best Practices
**Staatus:** ⏳ Planeeritud
**Maht:** 6-8 lk (~3,000-4,000 sõna)
**Kestus:** 1.5h teooria + 0.5h näited

**Põhiteemad:**
- OWASP Kubernetes Top 10
- CIS Kubernetes Benchmark
- Pod Security Standards (restricted, baseline, privileged)
- Image security
  - Non-root users
  - Minimal base images (Alpine, Distroless)
  - No secrets in images
- Supply chain security
  - Image scanning (Trivy eelvaade)
  - Signed images (Cosign eelvaade)

**Seos laboritega:** Lab 7 (Security best practices)

---

#### Peatükk 26: Vault ja Sealed Secrets
**Staatus:** ⏳ Planeeritud
**Maht:** 9-11 lk (~4,500-5,500 sõna)
**Kestus:** 2.5h teooria + 1h näited

**Põhiteemad:**
- HashiCorp Vault arhitektuur
  - Vault Server, storage backend
  - Seal/unseal
- Vault integration Kubernetes'ega
  - Vault Agent Injector (sidecar pattern)
  - Annotations (vault.hashicorp.com/agent-inject-secret)
- Vault policies (read, write, list)
- Secret engines (KV v2, Database, PKI)
- Sealed Secrets Controller
  - kubeseal CLI
  - SealedSecret CRD
  - Public/private key encryption
- GitOps-friendly secrets management (Sealed Secrets in Git)

**Seos laboritega:** Lab 7 (Vault ja Sealed Secrets)

---

#### Peatükk 27: RBAC ja Network Policies
**Staatus:** ⏳ Planeeritud
**Maht:** 9-11 lk (~4,500-5,500 sõna)
**Kestus:** 2.5h teooria + 1h näited

**Põhiteemad:**
- Kubernetes RBAC (Role-Based Access Control)
  - Role, RoleBinding (namespace-scoped)
  - ClusterRole, ClusterRoleBinding (cluster-scoped)
  - ServiceAccounts
- RBAC verbs (get, list, create, update, delete, watch)
- Principle of Least Privilege
- Network Policies
  - Ingress rules (incoming traffic)
  - Egress rules (outgoing traffic)
  - Pod selectors, namespace selectors
- Zero-trust networking
- Trivy security scanning
  - Image scanning
  - Manifest scanning (YAML misconfigurations)

**Seos laboritega:** Lab 7 (RBAC ja Network Policies)

---

### FAAS 7: Täiustatud Teemad (Peatükid 28-30)

#### Peatükk 28: GitOps with ArgoCD
**Staatus:** ⏳ Planeeritud
**Maht:** 10-12 lk (~5,000-6,000 sõna)
**Kestus:** 3h teooria + 1.5h näited

**Põhiteemad:**
- GitOps põhimõtted (declarative, versioned, immutable, pulled, reconciled)
- ArgoCD arhitektuur
  - Application Controller
  - Repo Server
  - API Server, UI
- Application CRD
  - source (repo, path, targetRevision)
  - destination (cluster, namespace)
  - syncPolicy
- Kustomize overlays (base + overlays pattern)
  - base/ (common resources)
  - overlays/dev/, overlays/prod/
- Sync policies
  - Manual sync
  - Auto-sync (automated)
  - Self-heal (auto-correct drift)
  - Prune (auto-delete removed resources)
- ApplicationSet (dynamic application generation)
- Argo Rollouts (Canary deployments, Blue-Green)

**Seos laboritega:** Lab 8 (ArgoCD setup ja GitOps workflow)

---

#### Peatükk 29: Backup ja Disaster Recovery
**Staatus:** ⏳ Planeeritud
**Maht:** 8-10 lk (~4,000-5,000 sõna)
**Kestus:** 2h teooria + 1h näited

**Põhiteemad:**
- Velero arhitektuur
- Backup strategies
  - Full cluster backup
  - Namespace backup
  - Application backup (label selectors)
- PersistentVolume backups
  - CSI snapshots (cloud provider)
  - Restic (filesystem backup)
- Scheduled backups
  - Schedule CRD (cron expression)
- Retention policies (TTL, deleteBackupAfter)
- Restore workflows
  - Full cluster restore
  - Selective restore (namespace, resources)
- Cross-cluster migration
- 3-2-1 backup rule (3 copies, 2 media, 1 offsite)

**Seos laboritega:** Lab 9 (Velero backup/restore)

---

#### Peatükk 30: Terraform Infrastructure as Code
**Staatus:** ⏳ Planeeritud
**Maht:** 10-12 lk (~5,000-6,000 sõna)
**Kestus:** 3h teooria + 1.5h näited

**Põhiteemad:**
- Terraform vs kubectl vs Helm
- Terraform arhitektuur
  - Provider, Resource, Data Source
  - State file
- HCL (HashiCorp Configuration Language) syntax
  - resource, data, variable, output
  - Expressions, functions
- Kubernetes provider
  - kubernetes_deployment, kubernetes_service
- Terraform workflow
  - terraform init, plan, apply, destroy
- State management
  - Local state
  - Remote state (S3, Terraform Cloud)
  - State locking
- Terraform modules (DRY principle)
  - Module structure (variables.tf, main.tf, outputs.tf)
  - Module reusability
- GitOps for infrastructure (Atlantis eelvaade)

**Seos laboritega:** Lab 10 (Terraform IaC)

---

## Laborite ja Peatükkide Seoste Tabel

| Labor | Eeldus Peatükid | Põhiteemad Peatükkides |
|-------|----------------|----------------------|
| **Lab 1: Docker Põhitõed** | 5, 6, 6A, 7 | Docker põhimõtted, Dockerfile, Java/Node spetsiifika, Image haldamine |
| **Lab 2: Docker Compose** | 8, 9 | Docker Compose, PostgreSQL konteinerites, Liquibase migrations |
| **Lab 3: Kubernetes Basics** | 10, 11, 12, 13, 14, 15, 16 | K8s intro, Pods, Deployments, Services, ConfigMaps, Secrets, PV/PVC, InitContainers |
| **Lab 4: Kubernetes Advanced** | 17, 18, 19 | Ingress, HPA, Helm charts |
| **Lab 5: CI/CD Pipeline** | 20, 21 | GitHub Actions, automated deployment, multi-environment |
| **Lab 6: Monitoring & Logging** | 22, 23, 24 | Prometheus, Grafana, Loki, Alerting |
| **Lab 7: Security & Secrets** | 25, 26, 27 | Security best practices, Vault, Sealed Secrets, RBAC, Network Policies, Trivy |
| **Lab 8: GitOps ArgoCD** | 28 | GitOps principles, ArgoCD, Kustomize, sync policies, Canary deployments |
| **Lab 9: Backup & DR** | 29 | Velero, backup strategies, restore workflows, cross-cluster migration |
| **Lab 10: Terraform IaC** | 30 | Terraform basics, Kubernetes provider, state management, modules |

---

## Koodiselgitused (Code Explanations)

**Asukoht:** `resource/code-explanations/`

**Eesmärk:** Lühikesed, koodikesksed selgitused, mis ei ole täielikud peatükid, vaid spetsiifiliste koodilõikude analüüs.

**Eristus peatükkidest:**
- **Peatükid (05-30):** Põhjalikud teoreetilised käsitlused, standardne struktuur (Õpieesmärgid, Põhimõisted, Teooria 70%, Näited 30%, Best Practices)
- **Koodiselgitused:** Lühikesed (3-5 lk), konkreetse koodi rea-haaval analüüs, AI-genereeritud stiil OK, ei järgi peatüki struktuuri

**Olemasolevad koodiselgitused:**

| Fail | Teema | Kasutatakse | Staatus |
|------|-------|-------------|---------|
| `Node.js-Dockerfile-Proxy-Explained.md` | 2-stage Node.js Dockerfile ARG proxy pattern | Lab 1, Exercise 01a | ✅ Valmis |

**Tulevikus võimalikud:**
- `Java-Gradle-Dependency-Cache-Explained.md` - Gradle dependencies cache in Docker
- `PostgreSQL-Init-Script-Explained.md` - Database initialization patterns
- `Kubernetes-HPA-Manifest-Explained.md` - HPA configuration breakdown
- `Nginx-Config-Explained.md` - nginx.conf line-by-line analysis

**Kasutamine:**
- Labori harjutusest viidatakse: `[Koodiselgitus: Title](../../../resource/code-explanations/File-Explained.md)`
- Koodiselgitus võib olla AI-genereeritud (Perplexity, ChatGPT), kui kvaliteet on hea
- Lühike ja praktiline, fookus koodil, mitte üldistel kontseptsioonidel

---

## Peatüki Template/Struktuur

Iga peatükk järgib standardset struktuuri:

```markdown
# Peatükk X: [Pealkiri]

## Õpieesmärgid
Peale selle peatüki läbimist oskad:
- ✅ Eesmärk 1
- ✅ Eesmärk 2
- ✅ Eesmärk 3

## Põhimõisted
- **Termin 1 (English term):** Selgitus eesti keeles
- **Termin 2 (English term):** Selgitus eesti keeles

## Teooria

### Alateema 1
[Selgitus, diagrammid, põhimõtted - 70% sisust]

### Alateema 2
[Selgitus, põhjendused, best practices]

## Praktilised Näited (30% sisust)

### Näide 1: [Praktiline stsenaarium]
```bash
# Käsud koos kommentaaridega
```
**Selgitus:** Mida see teeb ja miks

## Levinud Probleemid ja Lahendused

### Probleem 1
**Sümptom:** Mida kasutaja näeb
**Põhjus:** Miks see juhtub
**Lahendus:** Kuidas parandada

## Best Practices
- ✅ Soovitus 1 (DO)
- ✅ Soovitus 2 (DO)
- ❌ Väldi seda 1 (DON'T)
- ❌ Väldi seda 2 (DON'T)

## Kokkuvõte
- Võtmepunktid (3-5 bullet points)
- Viide laboratooriumile

## Viited ja Edasine Lugemine
- [Ametlik dokumentatsioon](https://...)
- [Best practices guide](https://...)

---

**Viimane uuendus:** YYYY-MM-DD
**Seos laboritega:** Lab X (teema)
**Eelmine peatükk:** XX-Eelmine-Pealkiri.md
**Järgmine peatükk:** XX-Jargmine-Pealkiri.md
```

---

## Faaside kaupa Töökorraldus

### FAAS 1: Põhitõed (Peatükid 1-4)
**Kestus:** 1-2 nädalat
**Prioriteet:** Madal (sissejuhatav materjal)
**Järjekord:** 1 → 2 → 3 → 4

Sissejuhatavad teemad: DevOps, Linux, Git, Networking

---

### FAAS 2: Docker (Peatükid 5-9) ⭐ KÕRGE PRIORITEET
**Kestus:** 2-3 nädalat
**Prioriteet:** ✅ **KÕRGE** (toetab Lab 1-2)
**Staatus:** 🏗️ **POOLELI** (5/8 peatükki valmis, 62.5%)
**Järjekord:** 5 → 6 → 6A → 7 → 8 → 8A → 8B → 9

**Valmis:**
- ✅ Peatükk 5: Docker Põhimõtted (16 lk, ~8000 sõna)
- ✅ Peatükk 6: Dockerfile Detailid (18 lk, ~9000 sõna)
- ✅ Peatükk 6A: Java/Spring Boot ja Node.js Spetsiifika (20 lk, ~10000 sõna)
- ✅ Peatükk 8A: Production vs Development Seadistused (15 lk, ~7500 sõna)
- ✅ Peatükk 8B: Nginx Reverse Proxy Docker Keskkonnas (18 lk, ~9000 sõna)

**Järgmine:**
- ⏳ Peatükk 7: Docker Image'ite Haldamine
- ⏳ Peatükk 8: Docker Compose
- ⏳ Peatükk 9: PostgreSQL Konteinerites

---

### FAAS 3: Kubernetes Alused (Peatükid 10-17)
**Kestus:** 4-5 nädalat
**Prioriteet:** ✅ **KÕRGE** (toetab Lab 3-4)
**Järjekord:** 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17

Orkestratsioon, Pods, Deployments, Services, Storage, Ingress

---

### FAAS 4: Kubernetes Täiustatud + CI/CD (Peatükid 18-21)
**Kestus:** 2-3 nädalat
**Prioriteet:** Keskmine (toetab Lab 4-5)
**Järjekord:** 18 → 19 → 20 → 21

HPA, Helm, GitHub Actions, Automated Deployment

---

### FAAS 5: Monitoring (Peatükid 22-24)
**Kestus:** 2 nädalat
**Prioriteet:** Keskmine (toetab Lab 6)
**Järjekord:** 22 → 23 → 24

Prometheus, Grafana, Loki, Alerting

---

### FAAS 6: Security (Peatükid 25-27)
**Kestus:** 2-3 nädalat
**Prioriteet:** Keskmine (toetab Lab 7)
**Järjekord:** 25 → 26 → 27

Security best practices, Vault, Sealed Secrets, RBAC, Network Policies

---

### FAAS 7: Täiustatud Teemad (Peatükid 28-30)
**Kestus:** 2-3 nädalat
**Prioriteet:** Madal (toetab Lab 8-10)
**Järjekord:** 28 → 29 → 30

GitOps, ArgoCD, Backup/DR, Terraform IaC

---

## Kvaliteedikontrolli Checklist

Iga peatüki peale kontrolli:

- [ ] **Õpieesmärgid on selged** (3-5 punkti, konkreetsed)
- [ ] **Põhimõisted on defineeritud** (eesti + inglise terminid)
- [ ] **Teooria on põhjalik** (70% sisust, selged selgitused, diagrammid)
- [ ] **Näited töötavad** (testitud käsud, toimivad konfiguratsioonid)
- [ ] **Levinud probleemid käsitletud** (Sümptom, Põhjus, Lahendus)
- [ ] **Best practices on kaasatud** (DO's ja DON'Ts)
- [ ] **Terminoloogia on järjepidev** (vaata TERMINOLOOGIA.md)
- [ ] **Viited laboratooriumile on korrektsed** (Lab X teema)
- [ ] **Viited ja edasine lugemine** (ametlikud dokud, best practices)
- [ ] **Metadata on täidetud** (Viimane uuendus, Seos laboritega, Eelmine/Järgmine peatükk)
- [ ] **Õigekiri kontrollitud** (eesti keele õigekiri, järjepidev sõnastus)

---

## Edenemise Tracking

### Praegune Staatus (2025-11-23)

**Kokku valmis:** 3 / 31 peatükki (9.7%)
**Sõnu kirjutatud:** ~27,000 / ~52,000-65,000 (52% FAAS 2'st)
**Lehekülgi:** ~54 / ~104-129

**Järgmised sammud:**

1. **Lõpeta FAAS 2** (Docker peatükid 7, 8, 9)
   - Peatükk 7: Docker Image'ite Haldamine (6-8 lk)
   - Peatükk 8: Docker Compose (8-10 lk)
   - Peatükk 9: PostgreSQL Konteinerites (5-7 lk)

2. **Testi FAAS 2 koos Lab 1-2'ga**
   - Loe läbi Lab 1 README ja exercises
   - Kontrolli, kas Peatükid 5-9 katavad kõik laboris kasutatavad teemad
   - Lisa puuduvad teemad või täpsusta

3. **Alusta FAAS 3** (Kubernetes Alused)
   - Peatükk 10: Kubernetes Sissejuhatus

4. **Jätka järjest läbi kõigi faaside**

---

## Hinnanguline Ajakulu

**Kokku:** ~14-15 nädalat (täiskohaga töö, 2 peatükki nädalas)

| Faas | Peatükid | Kestus |
|------|---------|--------|
| FAAS 1 | 1-4 | 1-2 nädalat |
| FAAS 2 | 5-9 | 2-3 nädalat ✅ (pooleli) |
| FAAS 3 | 10-17 | 4-5 nädalat |
| FAAS 4 | 18-21 | 2-3 nädalat |
| FAAS 5 | 22-24 | 2 nädalat |
| FAAS 6 | 25-27 | 2-3 nädalat |
| FAAS 7 | 28-30 | 2-3 nädalat |

**Alternatiivne lähenemine (osaline töö):**
- 1 peatükk nädalas = ~30 nädalat (~7 kuud)
- Prioritiseeri FAAS 2 ja 3 esimesena (Lab 1-4 support)

---

## Märkused

### Uute Materjalide Loomine

**Kodukataloog:** Kõik koolituskava materjalid luuakse `resource/` kataloogi.

**Automaatne paigutamine:**
- Uued peatükid → `/home/janek/projects/hostinger/resource/XX-Pealkiri.md`
- Lisafailid (diagrammid, näited) → `resource/` alamkataloogidesse vastavalt vajadusele

**OLULINE:** Claude Code loob uued koolitusmaterjalid automaatselt `resource/` kataloogi, mitte juurkataloogi.

### Terminoloogia

**KOHUSTUSLIK:** Järgi **TERMINOLOOGIA.md** faili uute materjalide loomisel!

Terminoloogia juhised:
- Eesti terminid: "ehita" (build), "pilt" (image), "konteiner" (container)
- Käsud inglise keeles: `docker build`, `kubectl apply`
- Failinimed muutmata: `Dockerfile`, `package.json`
- Pattern: "Loo Kubernetes deployment (deployment) kasutades kubectl apply käsku"

**Viide:** `/home/janek/projects/hostinger/TERMINOLOOGIA.md` - Docker & DevOps terminoloogia sõnastik

**Uute terminite käsitlemine:**
- Kui uue materjali loomisel ilmnevad **uued tehnilised terminid**, mis puuduvad TERMINOLOOGIA.md failis
- Küsi kasutajalt üle:
  - Kas termin tuleks lisada TERMINOLOOGIA.md faili?
  - Mis kujul (eestikeelne vaste + ingliskeelne termin)?
  - Näide kasutusest
- Hoia terminoloogia sõnastik ajakohane ja järjepidev

### Diagrammid

Kasuta **ASCII art** või **Mermaid** diagramme:
- ASCII art: Lihtsad arhitektuuridiagrammid (nagu Peatükis 5, 6A)
- Mermaid: Kompleksemad workflow'id (kui vaja)

### Näited

- **Töötavad käsud:** Kõik käsud peavad olema testitud
- **Kommentaarid:** Selgita, mida iga käsk teeb
- **Tulemus:** Näita, mis on käsu väljund

### Välised Viited

Kasuta **ametlikke dokumentatsioone** ja **best practices guide'e**:
- Docker: docs.docker.com
- Kubernetes: kubernetes.io/docs
- Spring Boot: spring.io/guides
- Prometheus: prometheus.io/docs
- Väldi aegunud blogisid või foorumeid

---

## Kokkuvõte

See plaan on **living document** - uuenda seda regulaarselt:

1. **Märgi valmis peatükid** (✅)
2. **Uuenda staatust** (Pooleli, Valmis)
3. **Lisa märkusi** (kui midagi muutub)
4. **Testi laborite vastavust** (peale iga faasi)

**Järgmine review:** Peale FAAS 2 valmimist (Peatükid 5-9 kõik valmis)

---

**Viimane uuendus:** 2025-11-23
**Autor:** Claude Code + Janek
**Staatus:** FAAS 2 pooleli (3/5 peatükki valmis)

**Edu koolituskava loomisega! 🎓🚀**
