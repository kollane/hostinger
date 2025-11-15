# FULL-STACK VEEBIRAKENDUSTE ARENDAMINE HOSTINGERIS
## PostgreSQL kahes variandis: Konteineriseeritud vs Väline Teenus

---

## KOOLITUSKAVA STRUKTUUR (25 peatükki + lisad)

---

### **MOODUL 1: ALUSED JA KESKKONNA ETTEVALMISTUS**

---

#### **Peatükk 1: Sissejuhatus ja ülevaade**
- Full-stack arenduse põhimõtted
- Hostingeri VPS platvorm
- Zorin OS arenduskeskkonnana
- Koolituskava struktuur ja eesmärgid
- Vajalikud tööriistad ja eelteadmised

**Kestus:** 2 tundi

---

#### **Peatükk 2: VPS esmane seadistamine**
- SSH võtmete genereerimine ja kasutamine
- Zorin OS-is SSH kliendi seadistamine
- VPS-iga ühenduse loomine
- Põhilised turvameetmed (firewall, fail2ban)
- Kasutajate ja õiguste haldamine
- Põhiliste tööriistade paigaldamine

**Praktilised ülesanded:**
- SSH võtmepaariga VPS-i sisselogimine
- sudo kasutaja loomine
- Põhilise tulemüüri (UFW) seadistamine

**Kestus:** 3 tundi

---

#### **Peatükk 3: PostgreSQL paigaldamine - MÕLEMAD VARIANDID** ⭐

**3.1 PRIMAARNE VARIANT: PostgreSQL Dockeris**
- Dockeri kontseptsioon ja eelised
- Docker Engine paigaldamine VPS-ile
- PostgreSQL official image valimine
- Docker volume'ide loomine andmete püsivuseks
- PostgreSQL konteineri käivitamine
- Põhiline konfiguratsioon (postgresql.conf, pg_hba.conf)
- Pordikaardistus ja võrguseaded
- Konteineri haldamine (start, stop, restart, logs)

**3.2 ALTERNATIIVNE VARIANT: PostgreSQL otse VPS-ile**
- APT repositooriumi lisamine (PostgreSQL official repo)
- PostgreSQL 15/16 paigaldamine
- Põhilised konfiguratsioonifailid
- Teenuse (service) haldamine systemd kaudu
- Kasutajate ja andmebaaside loomine
- Võrguühenduste lubamine (pg_hba.conf)

**3.3 Variantide võrdlus ja valikukriteeriumid**

| Kriteerium | Docker PostgreSQL | Väline PostgreSQL |
|------------|-------------------|-------------------|
| **Paigaldamise lihtsus** | Lihtne, standardne image | Nõuab OS-spetsiifilist seadistust |
| **Isolatsioon** | Täielik isolatsioon | Jagab OS-ressursse |
| **Versiooni haldamine** | Lihtne (image tag) | Nõuab apt/yum haldust |
| **Ressursside piiramine** | Docker limits | Süsteemsed piirid |
| **Backup** | Volume backup | PostgreSQL native tools |
| **Kõrge kättesaadavus (HA)** | Kubernetes StatefulSet | Replikatsioon, Patroni |
| **Kasutusjuhtumid** | Mikroteenused, DevOps, K8s | Traditsiooniline, suur tootmine |

**Millal valida Docker PostgreSQL:**
- Kubernetes/konteiner-keskkond
- Arendus- ja testimiskeskkonnad
- Versiooni muudatused peab olema lihtsad
- Mikroteenuste arhitektuur
- DevOps/GitOps töövood

**Millal valida väline PostgreSQL:**
- Suur produktsioonisüsteem kõrge koormaga
- Olemasolev traditsiooniline taristu
- Vajalik maksimaalne jõudlus ilma konteinerisatsioonita
- Spetsiifiline PostgreSQL konfiguratsioon
- DBA meeskond eelistab traditsioonilist haldusmeetodit

**Praktilised ülesanded:**
- Mõlema variandi paigaldamine testikeskkonnas
- Ühenduse testimine psql kliendiga
- Põhiliste andmebaasioperatsioonide testimine
- Jõudluse võrdlus (pgbench)

**Kestus:** 4 tundi

---

#### **Peatükk 4: Git ja versioonihaldus**
- Git põhimõtted ja töövoog
- Git paigaldamine ja seadistamine
- Repositooriumi loomine
- Põhilised käsud (commit, push, pull, branch, merge)
- .gitignore seadistamine
- SSH võtmed GitHubis/GitLabis
- Harud (branches) ja merge konfliktid
- Best practices koodi versioonihalduseks

**Praktilised ülesanded:**
- Projekti repositooriumi loomine
- Esimene commit ja push
- Arendusharu loomine

**Kestus:** 3 tundi

---

### **MOODUL 2: BACKEND ARENDUS (Node.js + Express)**

---

#### **Peatükk 5: Node.js ja Express.js alused**
- Node.js arhitektuur ja V8 engine
- npm ja package.json
- Express.js raamistik
- Middleware kontseptsioon
- Routing ja HTTP meetodid
- Request/Response objekt
- Environment variables (.env)
- Veatöötlus (error handling)

**Praktilised ülesanded:**
- Lihtne REST API loomine
- Middleware'i kirjutamine
- Environment konfiguratsioon

**Kestus:** 4 tundi

---

#### **Peatükk 6: PostgreSQL integratsioon Node.js-iga**

**6.1 PRIMAARNE: Ühendamine Docker PostgreSQL-iga**
- node-postgres (pg) teek
- Connection pooling
- Docker võrgu seadistamine (bridge, host)
- Container name vs IP aadress
- Connection string Docker keskkonnas
- Docker Compose PostgreSQL + Node.js
- Ühenduse testimine ja veaotsing

```javascript
// Docker PostgreSQL ühendus
const pool = new Pool({
  host: 'postgres', // Docker container nimi
  port: 5432,
  database: 'appdb',
  user: 'appuser',
  password: process.env.DB_PASSWORD
});
```

**6.2 ALTERNATIIV: Ühendamine välise PostgreSQL-iga**
- Connection string väline host
- SSL/TLS ühendused
- Võrgu turvalisus (firewall reeglid)
- Connection timeout ja retry logic

```javascript
// Väline PostgreSQL ühendus
const pool = new Pool({
  host: 'db.example.com', // Väline hostname või IP
  port: 5432,
  database: 'appdb',
  user: 'appuser',
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: true,
    ca: fs.readFileSync('/path/to/ca-certificate.crt').toString()
  }
});
```

**6.3 Andmebaasi päringud**
- Parameetriseeritud päringud (SQL injection kaitse)
- Transactions
- Error handling
- Query logging

**Praktilised ülesanded:**
- Ühenduse loomine mõlemas variandis
- CRUD operatsioonid
- Transaction näide

**Kestus:** 4 tundi

---

#### **Peatükk 7: REST API disain ja realiseerimine**
- RESTful põhimõtted
- API endpoint-id ja nende struktuur
- HTTP meetodid ja status koodid
- Request validation (Joi, express-validator)
- API dokumentatsioon (Swagger/OpenAPI)
- Versioonihaldus API-s
- Rate limiting ja throttling

**Praktilised ülesanded:**
- Täisfunktsionaalne CRUD API loomine
- Swagger dokumentatsiooni genereerimine
- API testimine Postman/Insomnia-ga

**Kestus:** 4 tundi

---

#### **Peatükk 8: Autentimine ja autoriseerimine**
- Autentimise vs autoriseerimise kontseptsioon
- JWT (JSON Web Tokens)
- Paroolide räsimine (bcrypt)
- Session vs token-based auth
- OAuth2 ja OpenID Connect ülevaade
- Rollipõhine ligipääsukontroll (RBAC)
- Refresh tokenid
- Turvalisuse best practices

**Praktilised ülesanded:**
- JWT põhine autentimissüsteem
- Registreerimise ja sisselogimise endpoint-id
- Protected route'id

**Kestus:** 5 tundi

---

### **MOODUL 3: FRONTEND ARENDUS**

---

#### **Peatükk 9: HTML5 ja CSS3 tänapäevases veebirakenduses**
- Semantiline HTML
- CSS Grid ja Flexbox
- Responsive design
- CSS muutujad (custom properties)
- CSS raamistikud (Bootstrap, Tailwind CSS)
- Accessibility (a11y) põhimõtted
- Fonts ja ikoonid

**Praktilised ülesanded:**
- Responsive layout loomine
- Vormi disain ja valideerimine (HTML5)

**Kestus:** 3 tundi

---

#### **Peatükk 10: Vanilla JavaScript süvendatult**
- ES6+ funktsioonid (arrow functions, destructuring, spread/rest)
- Async/Await vs Promises
- Fetch API
- DOM manipulatsioon
- Event handling
- Error handling kliendipoolel
- Local storage ja session storage
- Modules (import/export)

**Praktilised ülesanded:**
- API kutsumine fetch-iga
- Dünaamiline sisu renderdamine
- Vormi submit async-lt

**Kestus:** 4 tundi

---

#### **Peatükk 11: Frontend ja backend integratsioon**
- CORS (Cross-Origin Resource Sharing)
- API kliendi loomine
- Autentimise voog frontendis (token salvestamine)
- Protected pages
- Error handling ja kasutajale tagasiside
- Loading states
- Form validation (klient + server)

**Praktilised ülesanded:**
- Login/registreerimise vorm
- Dashboard autentimisega
- API error handling

**Kestus:** 4 tundi

---

### **MOODUL 4: DOCKER JA KONTEINERISATSIOON**

---

#### **Peatükk 12: Docker põhimõtted** 🐳
- Konteinerite vs VM-ide erinevused
- Docker arhitektuur (daemon, client, registry)
- Images vs Containers
- Dockerfile loomine
- Layer caching ja optimiseerimine
- .dockerignore
- Multi-stage builds
- Best practices Node.js rakendusele

**Praktilised ülesanded:**
- Backend Dockerfile loomine
- Frontend Dockerfile loomine (Nginx)
- Image'i buildimine ja käivitamine

**Kestus:** 4 tundi

---

#### **Peatükk 13: Docker Compose** 🐳

**13.1 PRIMAARNE: PostgreSQL + Backend + Frontend**
- docker-compose.yml struktuur
- Service'ide defineerimine
- Volumes ja andmete püsivus
- Networks ja service discovery
- Environment variables
- Dependency management (depends_on)
- Health checks

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    networks:
      - app-network

  backend:
    build: ./backend
    depends_on:
      - postgres
    environment:
      DB_HOST: postgres  # Container name
      DB_PORT: 5432
    networks:
      - app-network

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
```

**13.2 ALTERNATIIV: Väline PostgreSQL + Backend + Frontend**
```yaml
version: '3.8'
services:
  backend:
    build: ./backend
    environment:
      DB_HOST: db.example.com  # Väline host
      DB_PORT: 5432
      DB_SSL: "true"
    networks:
      - app-network

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - app-network

networks:
  app-network:
    driver: bridge
```

**Praktilised ülesanded:**
- Kogu stack'i käivitamine Docker Compose-iga mõlemas variandis
- Volumes'i haldamine
- Logs'ide vaatamine (docker-compose logs)

**Kestus:** 4 tundi

---

#### **Peatükk 14: Docker Registry ja image'i haldamine**
- Docker Hub
- Eraregistry loomine
- Image tagging strateegiad
- Image'i push/pull
- Multi-platform images (ARM, x86)
- Security scanning (Trivy, Clair)
- Image cleanup ja ruumihaldamine

**Praktilised ülesandes:**
- Image push Docker Hub-i
- Private registry seadistamine VPS-il
- Automated builds GitHub Actions-iga

**Kestus:** 3 tundi

---

### **MOODUL 5: KUBERNETES JA ORKESTRATSIOON**

---

#### **Peatükk 15: Kubernetes alused** ☸️
- Kubernetes arhitektuur (master, worker nodes)
- Pods, ReplicaSets, Deployments
- Services (ClusterIP, NodePort, LoadBalancer)
- K3s vs Kubernetes
- K3s paigaldamine VPS-ile
- kubectl konfigureerimine
- Namespaces
- Labels ja selectors

**Praktilised ülesanded:**
- K3s installimine VPS-ile
- kubectl põhikäsud
- Esimese pod'i käivitamine

**Kestus:** 4 tundi

---

#### **Peatükk 16: PostgreSQL Kubernetes-es - MÕLEMAD VARIANDID** ☸️⭐

**16.1 PRIMAARNE: StatefulSet PostgreSQL-ile**
- StatefulSet vs Deployment
- PersistentVolume ja PersistentVolumeClaim
- HeadlessService PostgreSQL-ile
- ConfigMaps ja Secrets
- Init containers
- PostgreSQL StatefulSet manifest

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: appdb
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

**16.2 ALTERNATIIV: ExternalName Service välise DB-ga**
- ExternalName Service kontseptsioon
- Endpoints objektid
- Välise DB integratsioon K8s-iga
- SSL/TLS sertifikaadid Secrets-ina
- Connection pooling considerations

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  type: ExternalName
  externalName: db.example.com
  ports:
  - port: 5432
---
# VÕI Endpoints jaoks:
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  ports:
  - port: 5432
---
apiVersion: v1
kind: Endpoints
metadata:
  name: postgres
subsets:
  - addresses:
    - ip: 192.168.1.100  # Väline DB IP
    ports:
    - port: 5432
```

**16.3 Variantide võrdlus Kubernetes kontekstis**

| Aspekt | StatefulSet PostgreSQL | Väline PostgreSQL |
|--------|------------------------|-------------------|
| **Haldamine** | Kubernetes native | Väline haldus |
| **Scalability** | Keeruline (replikad) | Sõltub välisest teenusest |
| **Backup** | Kubernetes CronJobs | Väline backup lahendus |
| **Monitoring** | K8s metrics | Väline monitoring |
| **Failover** | Kubernetes restart | Väline HA setup |
| **Network latency** | Väga madal (sama cluster) | Võib olla kõrgem |

**Praktilised ülesanded:**
- StatefulSet PostgreSQL deployment
- Väline DB ühendamine ExternalName Service-iga
- Connection testing mõlemas variandis
- PV/PVC haldamine (StatefulSet variant)

**Kestus:** 5 tundi

---

#### **Peatükk 17: Backend deployment Kubernetes-es** ☸️

**17.1 PRIMAARNE: StatefulSet PostgreSQL-iga**
- Deployment manifest backend-ile
- ConfigMap keskkonnamuutujatele
- Secrets andmebaasi mandaatidele
- Service backend-ile (ClusterIP)
- Health checks (liveness, readiness probes)
- Resource limits ja requests
- HorizontalPodAutoscaler

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: your-registry/backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: DB_HOST
          value: postgres  # StatefulSet Service name
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: appdb
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

**17.2 ALTERNATIIV: Väline PostgreSQL-iga**
```yaml
# Peamine erinevus on env konfiguratsioonis
        env:
        - name: DB_HOST
          value: db.example.com  # Väline hostname
        - name: DB_SSL
          value: "true"
        - name: DB_SSL_CA
          valueFrom:
            secretKeyRef:
              name: db-ssl-secret
              key: ca.crt
```

**Praktilised ülesanded:**
- Backend deployment mõlema variant
- Autoscaling seadistamine
- Rolling updates

**Kestus:** 4 tundi

---

#### **Peatükk 18: Frontend deployment ja Ingress** ☸️
- Frontend Deployment (Nginx image)
- Service frontend-ile
- Ingress controller (Traefik K3s default)
- Ingress rules ja path-based routing
- TLS/SSL sertifikaadid (cert-manager)
- Domain nimedega töötamine

**Praktilised ülesanded:**
- Frontend deployment
- Ingress rule loomine
- HTTPS seadistamine Let's Encrypt-iga

**Kestus:** 4 tundi

---

#### **Peatükk 19: ConfigMaps, Secrets ja volume management** ☸️
- ConfigMaps failidest ja väärtustest
- Secrets turvaliselt haldamine
- Volume types (emptyDir, hostPath, PV/PVC)
- Storage classes
- Dynamic provisioning
- Backup strateegiad Kubernetes volumes-ile

**Praktilised ülesanded:**
- ConfigMap loomine konfiguratsioonifailidest
- Secrets encrypted at rest
- PV/PVC haldamine

**Kestus:** 3 tundi

---

### **MOODUL 6: CI/CD JA AUTOMATISEERIMINE**

---

#### **Peatükk 20: GitHub Actions CI/CD**
- GitHub Actions workflow süntaks
- Triggers (push, pull_request, schedule)
- Jobs ja steps
- Secrets GitHub-is
- Automated testing
- Docker image build ja push
- Kubernetes deployment automation
- Multi-environment (dev, staging, prod)

**Praktilised ülesanded:**
- CI workflow testide jaoks
- CD workflow Docker image build + K8s deployment
- Environment-specific configs

**Kestus:** 5 tundi

---

#### **Peatükk 21: Monitoring ja logging** 📊

**21.1 PostgreSQL monitoring - mõlemad variandid**

**Docker/StatefulSet PostgreSQL:**
- Prometheus PostgreSQL exporter
- Container metrics
- Log aggregation (Loki)

**Väline PostgreSQL:**
- Remote monitoring setup
- pg_stat_statements
- External monitoring service integration

**21.2 Üldine monitoring**
- Prometheus paigaldamine K3s-i
- Grafana dashboards
- AlertManager
- Log aggregation (Loki + Promtail)
- Application metrics (Node.js prom-client)

**Praktilised ülesanded:**
- Prometheus + Grafana setup
- PostgreSQL dashboard loomine mõlema variandi jaoks
- Alert rules

**Kestus:** 4 tundi

---

### **MOODUL 7: TÄIUSTATUD TEEMAD**

---

#### **Peatükk 22: Andmebaasi haldus ja optimeerimine** 🗄️

**22.1 PRIMAARNE: Docker/StatefulSet PostgreSQL**
- Backup strateegiad konteinerites
  - pg_dump Docker volume'ist
  - Kubernetes CronJob backup-ile
  - Volume snapshots
- Restore protseduurid
- Migration Kubernetes-es (StatefulSet upgrade)
- Performance tuning (postgresql.conf in ConfigMap)

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # Iga päev kell 2:00
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:16-alpine
            command:
            - /bin/sh
            - -c
            - pg_dump -h postgres -U appuser appdb > /backup/backup-$(date +%Y%m%d).sql
            env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
```

**22.2 ALTERNATIIV: Väline PostgreSQL**
- Traditsiooniline backup (pg_dump, pg_basebackup)
- WAL archiving
- Point-in-time recovery (PITR)
- Replication setup (streaming replication)
- High Availability (Patroni, PgBouncer)

**22.3 Ühised teemad**
- Index optimeerimine
- Query performance analysis (EXPLAIN ANALYZE)
- Connection pooling (PgBouncer)
- Vacuum ja maintenance
- Partitioning strateegiad

**Praktilised ülesanded:**
- Automated backup mõlemas variandis
- Restore testimine
- Performance profiling
- Index loomine ja mõõtmine

**Kestus:** 5 tundi

---

#### **Peatükk 23: Turvalisus ja best practices** 🔒
- SSL/TLS rakenduses (Let's Encrypt)
- Secrets management (Vault, Sealed Secrets)
- Network policies Kubernetes-es
- Pod security policies/standards
- Image vulnerability scanning
- OWASP Top 10
- Rate limiting ja DDoS kaitse
- Security headers
- Dependency auditing (npm audit)

**Praktilised ülesanded:**
- Network policy loomine
- Vault integratsioon
- Security scanning CI-s

**Kestus:** 4 tundi

---

#### **Peatükk 24: Skaleeritavus ja jõudlus**
- Horizontal vs vertical scaling
- Load balancing (Ingress, Service)
- Caching strateegiad (Redis)
- CDN kasutamine staatilistele failidele
- Database connection pooling
- Async processing (job queues)
- Performance testing (k6, Artillery)

**Praktilised ülesanded:**
- Redis cache lisamine
- HorizontalPodAutoscaler seadistamine
- Load testing

**Kestus:** 4 tundi

---

#### **Peatükk 25: Troubleshooting ja debugging**
- Kubernetes debugging (kubectl logs, describe, exec)
- Docker debugging
- PostgreSQL slow query log
- Application debugging (Node.js debugger)
- Network debugging (tcpdump, netstat)
- Resource constraints diagnoosing
- Common pitfalls ja lahendused

**Praktilised ülesanded:**
- Broken deployment parandamine
- Performance bottleneck leidmine
- Network connectivity issues

**Kestus:** 3 tundi

---

### **LISAD JA RESSURSID**

---

#### **Lisa A: Arhitektuuri diagrammid**

**A.1 PRIMAARNE arhitektuur: Full Docker/Kubernetes Stack**
```
┌─────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Ingress Controller                   │  │
│  │         (Traefik + Let's Encrypt)                │  │
│  └────────────────┬─────────────────────────────────┘  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │       Frontend Service           │                  │
│  │      (ClusterIP: 80)             │                  │
│  └────────────────┬─────────────────┘                  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │     Frontend Deployment          │                  │
│  │    (Nginx + Static files)        │                  │
│  │         Replicas: 2              │                  │
│  └──────────────────────────────────┘                  │
│                                                         │
│  ┌──────────────────────────────────┐                  │
│  │       Backend Service            │                  │
│  │      (ClusterIP: 3000)           │                  │
│  └────────────────┬─────────────────┘                  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │     Backend Deployment           │                  │
│  │    (Node.js + Express)           │                  │
│  │         Replicas: 3              │                  │
│  │         HPA enabled              │                  │
│  └────────────────┬─────────────────┘                  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │    PostgreSQL Service            │                  │
│  │   (Headless ClusterIP)           │                  │
│  └────────────────┬─────────────────┘                  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │   PostgreSQL StatefulSet         │                  │
│  │     (postgres:16-alpine)         │                  │
│  │         Replicas: 1              │                  │
│  └────────────────┬─────────────────┘                  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │   PersistentVolumeClaim          │                  │
│  │      (postgres-storage)          │                  │
│  │          10Gi                    │                  │
│  └──────────────────────────────────┘                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**A.2 ALTERNATIIVNE arhitektuur: Hybrid (K8s + Väline DB)**
```
┌─────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Ingress Controller                   │  │
│  │         (Traefik + Let's Encrypt)                │  │
│  └────────────────┬─────────────────────────────────┘  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │       Frontend Service           │                  │
│  │      (ClusterIP: 80)             │                  │
│  └────────────────┬─────────────────┘                  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │     Frontend Deployment          │                  │
│  │    (Nginx + Static files)        │                  │
│  │         Replicas: 2              │                  │
│  └──────────────────────────────────┘                  │
│                                                         │
│  ┌──────────────────────────────────┐                  │
│  │       Backend Service            │                  │
│  │      (ClusterIP: 3000)           │                  │
│  └────────────────┬─────────────────┘                  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │     Backend Deployment           │                  │
│  │    (Node.js + Express)           │                  │
│  │         Replicas: 3              │                  │
│  │         HPA enabled              │                  │
│  └────────────────┬─────────────────┘                  │
│                   │                                     │
│  ┌────────────────▼─────────────────┐                  │
│  │  PostgreSQL ExternalName         │                  │
│  │       Service                    │                  │
│  │  externalName: db.example.com    │                  │
│  └────────────────┬─────────────────┘                  │
│                   │                                     │
└───────────────────┼─────────────────────────────────────┘
                    │
                    │ SSL/TLS ühendus
                    │
    ┌───────────────▼────────────────┐
    │   VÄLINE POSTGRESQL SERVER      │
    │   (Dedicated VPS või Managed)   │
    │                                 │
    │   - PostgreSQL 16               │
    │   - Streaming Replication       │
    │   - PgBouncer connection pool   │
    │   - Automated backups           │
    └─────────────────────────────────┘
```

**A.3 Võrgunduse erinevused**

**Docker Compose (Arendus):**
- Bridge network - konteinerid suhtlevad omavahel
- Host network - otsene juurdepääs host-i võrgule
- Service discovery läbi container name

**Kubernetes (Produktsioon):**
- Pod network - igal pod-il oma IP
- Service abstraction - stabiilne DNS nimi
- Ingress - välisele liiklusele juurdepääs

---

#### **Lisa B: Käsureakäsud ja cheatsheet**

**B.1 Docker käsud**
```bash
# Image haldamine
docker build -t myapp:latest .
docker images
docker rmi image-id

# Container haldamine
docker run -d -p 3000:3000 --name myapp myapp:latest
docker ps
docker ps -a
docker logs myapp
docker exec -it myapp /bin/sh
docker stop myapp
docker rm myapp

# Volume haldamine
docker volume ls
docker volume create myvolume
docker volume inspect myvolume
docker volume rm myvolume

# Network
docker network ls
docker network create mynetwork
docker network inspect mynetwork

# Docker Compose
docker-compose up -d
docker-compose down
docker-compose logs -f
docker-compose ps
docker-compose exec service-name /bin/sh
```

**B.2 Kubernetes käsud**
```bash
# Cluster info
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Pods
kubectl get pods
kubectl get pods -n namespace
kubectl describe pod pod-name
kubectl logs pod-name
kubectl logs -f pod-name
kubectl exec -it pod-name -- /bin/sh
kubectl delete pod pod-name

# Deployments
kubectl get deployments
kubectl describe deployment deployment-name
kubectl scale deployment deployment-name --replicas=5
kubectl rollout status deployment/deployment-name
kubectl rollout undo deployment/deployment-name

# Services
kubectl get services
kubectl describe service service-name
kubectl expose deployment deployment-name --port=80 --target-port=8080

# ConfigMaps ja Secrets
kubectl create configmap myconfig --from-file=config.yaml
kubectl get configmaps
kubectl describe configmap myconfig

kubectl create secret generic mysecret --from-literal=password=mypassword
kubectl get secrets
kubectl describe secret mysecret

# Apply manifests
kubectl apply -f deployment.yaml
kubectl apply -f . (kõik yaml failid kataloogis)
kubectl delete -f deployment.yaml

# PV/PVC
kubectl get pv
kubectl get pvc
kubectl describe pvc pvc-name

# StatefulSets
kubectl get statefulsets
kubectl describe statefulset statefulset-name
kubectl scale statefulset statefulset-name --replicas=3
```

**B.3 PostgreSQL käsud**

```bash
# Docker PostgreSQL-i ühendus
docker exec -it postgres-container psql -U username -d database

# Väline PostgreSQL ühendus
psql -h db.example.com -U username -d database

# Põhilised SQL käsud
\l                      # Andmebaaside loend
\c database_name        # Ühenda andmebaasiga
\dt                     # Tabelite loend
\d table_name           # Tabeli struktuur
\du                     # Kasutajate loend
\q                      # Välju

# Backup
pg_dump -h localhost -U username database > backup.sql
pg_dump -h localhost -U username -Fc database > backup.dump  # Custom format

# Restore
psql -h localhost -U username database < backup.sql
pg_restore -h localhost -U username -d database backup.dump

# Performance
EXPLAIN ANALYZE SELECT * FROM table WHERE condition;
```

---

#### **Lisa C: Konfiguratsiooni näidisfailid**

**C.1 Docker Compose - Primaarne variant (PostgreSQL included)**
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: app-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_INITDB_ARGS: "-E UTF8 --locale=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: app-backend
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      NODE_ENV: production
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
    ports:
      - "3000:3000"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: app-frontend
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - "80:80"
      - "443:443"
    networks:
      - app-network
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro

volumes:
  postgres_data:
    driver: local

networks:
  app-network:
    driver: bridge
```

**C.2 Docker Compose - Alternatiivne variant (Väline PostgreSQL)**
```yaml
version: '3.8'

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: app-backend
    restart: unless-stopped
    environment:
      NODE_ENV: production
      DB_HOST: ${EXTERNAL_DB_HOST}  # db.example.com
      DB_PORT: ${EXTERNAL_DB_PORT:-5432}
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_SSL: "true"
      JWT_SECRET: ${JWT_SECRET}
    ports:
      - "3000:3000"
    networks:
      - app-network
    volumes:
      - ./ssl/ca-certificate.crt:/app/ssl/ca.crt:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: app-frontend
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - "80:80"
      - "443:443"
    networks:
      - app-network
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro

networks:
  app-network:
    driver: bridge
```

**C.3 Kubernetes - StatefulSet PostgreSQL (Primaarne)**
```yaml
# postgres-statefulset.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: production
type: Opaque
stringData:
  username: appuser
  password: CHANGE_ME_STRONG_PASSWORD
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: production
data:
  postgresql.conf: |
    max_connections = 200
    shared_buffers = 256MB
    effective_cache_size = 1GB
    maintenance_work_mem = 64MB
    checkpoint_completion_target = 0.9
    wal_buffers = 16MB
    default_statistics_target = 100
    random_page_cost = 1.1
    effective_io_concurrency = 200
    work_mem = 1310kB
    min_wal_size = 1GB
    max_wal_size = 4GB
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: production
spec:
  clusterIP: None  # Headless service
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: production
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_DB
          value: appdb
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        - name: postgres-config
          mountPath: /etc/postgresql/postgresql.conf
          subPath: postgresql.conf
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U $POSTGRES_USER
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U $POSTGRES_USER
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: postgres-config
        configMap:
          name: postgres-config
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: local-path  # K3s default
      resources:
        requests:
          storage: 20Gi
```

**C.4 Kubernetes - Väline PostgreSQL (Alternatiivne)**
```yaml
# external-postgres.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: production
type: Opaque
stringData:
  username: appuser
  password: EXTERNAL_DB_PASSWORD
  ca.crt: |
    -----BEGIN CERTIFICATE-----
    ... CA Certificate ...
    -----END CERTIFICATE-----
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: production
spec:
  type: ExternalName
  externalName: db.example.com  # Väline hostname
  ports:
  - port: 5432
    targetPort: 5432
---
# VÕI kui kasutad IP aadressi:
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: production
spec:
  ports:
  - port: 5432
    targetPort: 5432
---
apiVersion: v1
kind: Endpoints
metadata:
  name: postgres
  namespace: production
subsets:
- addresses:
  - ip: 192.168.1.100  # Väline PostgreSQL IP
  ports:
  - port: 5432
```

---

#### **Lisa D: Troubleshooting guide**

**D.1 PostgreSQL ühenduse probleemid**

**Sümptom:** Backend ei saa PostgreSQL-iga ühendust

**Docker variant:**
```bash
# 1. Kontrolli, kas PostgreSQL container töötab
docker ps | grep postgres

# 2. Vaata PostgreSQL loge
docker logs postgres-container

# 3. Testi ühendust container seest
docker exec -it backend-container ping postgres

# 4. Testi PostgreSQL-i ühendust
docker exec -it backend-container psql -h postgres -U appuser -d appdb

# 5. Kontrolli network-i
docker network inspect app-network
```

**Kubernetes variant:**
```bash
# 1. Kontrolli pod olekut
kubectl get pods -n production | grep postgres

# 2. Vaata loge
kubectl logs -n production postgres-0

# 3. Describe pod (event'id)
kubectl describe pod -n production postgres-0

# 4. Testi DNS lahendust
kubectl run -it --rm debug --image=busybox --restart=Never -n production -- nslookup postgres

# 5. Testi ühendust backend pod-ist
kubectl exec -it -n production backend-pod-name -- ping postgres
kubectl exec -it -n production backend-pod-name -- nc -zv postgres 5432
```

**Väline PostgreSQL:**
```bash
# 1. Testi ühendust backend pod-ist
kubectl exec -it -n production backend-pod-name -- ping db.example.com
kubectl exec -it -n production backend-pod-name -- nc -zv db.example.com 5432

# 2. Kontrolli SSL sertifikaati
kubectl exec -it -n production backend-pod-name -- openssl s_client -connect db.example.com:5432 -starttls postgres

# 3. Kontrolli ExternalName service-i
kubectl get svc -n production postgres
kubectl describe svc -n production postgres

# 4. Kontrolli firewall reegleid välises serveris
# (VPS-is, kus väline PostgreSQL on)
sudo ufw status | grep 5432
```

**D.2 Jõudlusprobleemid**

**PostgreSQL on aeglane:**
```bash
# 1. Kontrolli ühenduste arvu
docker exec -it postgres-container psql -U appuser -d appdb -c "SELECT count(*) FROM pg_stat_activity;"

# 2. Vaata aeglasi päringuid
docker exec -it postgres-container psql -U appuser -d appdb -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE (now() - pg_stat_activity.query_start) > interval '5 seconds';"

# 3. Kontrolli cache hit ratio
docker exec -it postgres-container psql -U appuser -d appdb -c "SELECT sum(heap_blks_read) as heap_read, sum(heap_blks_hit) as heap_hit, sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio FROM pg_statio_user_tables;"

# 4. Vaata index kasutamist
docker exec -it postgres-container psql -U appuser -d appdb -c "SELECT schemaname, tablename, indexname, idx_scan FROM pg_stat_user_indexes ORDER BY idx_scan;"
```

**D.3 Kubernetes pod ei käivitu**

```bash
# 1. Vaata pod olekut ja event'e
kubectl describe pod -n production pod-name

# Levinud põhjused ja lahendused:

# ImagePullBackOff - vale image nimi või puudub ligipääs registry-le
kubectl get events -n production --sort-by='.lastTimestamp'

# CrashLoopBackOff - rakendus crashib
kubectl logs -n production pod-name --previous

# Pending - ei ole piisavalt ressursse
kubectl describe nodes
kubectl top nodes

# 2. Kontrolli resource requests/limits
kubectl get pod -n production pod-name -o yaml | grep -A 5 resources

# 3. Testi pod manuaalselt
kubectl run -it --rm debug --image=your-image --restart=Never -n production -- /bin/sh
```

---

#### **Lisa E: Best practices kokkuvõte**

**E.1 Docker best practices**
- ✅ Kasuta ametlikke base image'e (node:20-alpine, postgres:16-alpine)
- ✅ Multi-stage build image size vähendamiseks
- ✅ .dockerignore faili kasutamine
- ✅ Non-root kasutaja containeris
- ✅ Health checks defineerimine
- ✅ Secrets env variables'ina, mitte hardcoded
- ✅ Volume'id andmete püsivuseks
- ❌ Latest tag produktsioonis
- ❌ Tundlikud andmed image'sse

**E.2 Kubernetes best practices**
- ✅ Resource requests ja limits kõigil pod-idel
- ✅ Liveness ja readiness probes
- ✅ PodDisruptionBudget kõrge kättesaadavuseks
- ✅ Network Policies võrgu isolatsiooniks
- ✅ Secrets mandaatidele, ConfigMaps konfiguratsioonile
- ✅ Labels ja annotations organiseerimiseks
- ✅ Namespaces erinevate keskkondade jaoks
- ✅ RBAC õiguste piiramiseks
- ❌ Kõik pod-id default namespace-is
- ❌ Privileged containerid ilma põhjuseta

**E.3 PostgreSQL best practices**

**Mõlemad variandid:**
- ✅ Tugevad paroolid
- ✅ Regular backups (automated)
- ✅ Connection pooling (PgBouncer)
- ✅ Monitoring ja alerting
- ✅ Regular VACUUM ANALYZE
- ✅ Index optimeerimine
- ❌ root/postgres kasutaja rakenduses

**Docker/StatefulSet variant:**
- ✅ PersistentVolume andmete jaoks
- ✅ Init containers andmebaasi initsiatsiooniks
- ✅ ConfigMap postgresql.conf jaoks
- ✅ StatefulSet (mitte Deployment)
- ✅ Headless Service
- ✅ CronJob automated backup-ile

**Väline PostgreSQL variant:**
- ✅ SSL/TLS ühendused
- ✅ Streaming replication HA jaoks
- ✅ Patroni automatic failover-iks
- ✅ Eraldatud server kriitiliste rakenduste jaoks
- ✅ Professional DBA haldus
- ✅ Regulaarne PITR testimine

**E.4 Turvalisus best practices**
- ✅ Kõik ühendused üle SSL/TLS
- ✅ Secrets encrypted at rest
- ✅ Image vulnerability scanning
- ✅ Network policies mikroteenuste vahel
- ✅ Pod security standards
- ✅ Regular dependency updates
- ✅ Audit logging
- ❌ Hardcoded secrets
- ❌ Root containerid
- ❌ Avatud portid ilma firewall-ita

---

#### **Lisa F: Kasulikud ressursid**

**Dokumentatsioon:**
- Docker: https://docs.docker.com/
- Kubernetes: https://kubernetes.io/docs/
- K3s: https://docs.k3s.io/
- PostgreSQL: https://www.postgresql.org/docs/
- Node.js: https://nodejs.org/docs/
- Express: https://expressjs.com/

**Tööriistad:**
- kubectl: https://kubernetes.io/docs/tasks/tools/
- Docker Compose: https://docs.docker.com/compose/
- Helm: https://helm.sh/docs/
- Lens (Kubernetes IDE): https://k8slens.dev/
- k9s (Terminal UI): https://k9scli.io/

**Õppematerjalid:**
- Kubernetes By Example: https://kubernetesbyexample.com/
- Docker Curriculum: https://docker-curriculum.com/
- PostgreSQL Tutorial: https://www.postgresqltutorial.com/

**Kogukond:**
- Stack Overflow
- Kubernetes Slack
- Docker Community Forums
- PostgreSQL mailing lists

---

#### **Lisa G: Sõnastik (Glossary)**

**Eesti - Inglise - Selgitus**

- **Konteiner** - Container - Isoleeritud protsess, mis sisaldab rakendust ja sõltuvusi
- **Kujutis** - Image - Mall (template), millest luuakse konteiner
- **Pod** - Pod - Väikseim Kubernetes üksus, sisaldab üht või enamat konteinerit
- **Teenus** - Service - Kubernetes abstraktsioon, mis pakub stabiilset võrgu endpoint-i
- **Maht** - Volume - Püsiv andmesalvestus konteinerite jaoks
- **Deployment** - Deployment - Kubernetes ressurss, mis haldab replicated rakendusi
- **StatefulSet** - StatefulSet - Kubernetes ressurss stateful rakenduste jaoks (nt andmebaas)
- **Ingress** - Ingress - Välisele liiklusele juurdepääsu haldamine
- **Secret** - Secret - Tundlike andmete (paroolid, võtmed) hoidmiseks
- **ConfigMap** - ConfigMap - Konfiguratsioonifailide hoidmiseks
- **Namespace** - Namespace - Virtuaalne cluster ressursside isoleerimiseks
- **Replikatsioon** - Replication - Andmete kopeerimine mitme serveri vahel
- **Kuuendatavus** - Scalability - Võime rakendust laiendada suurema koormuse jaoks
- **Koormuse tasakaalustamine** - Load Balancing - Liikluse jaotamine mitme serveri vahel
- **Kõrge kättesaadavus** - High Availability (HA) - Süsteemi töövõime ka rikke korral

---

## KOOLITUSKAVA KOKKUVÕTE

**Kogukestus:** ~95 tundi (umbes 12 tööpäeva)

**Moodulite jaotus:**
1. Alused ja ettevalmistus: 12 tundi
2. Backend arendus: 17 tundi
3. Frontend arendus: 11 tundi
4. Docker: 11 tundi
5. Kubernetes: 20 tundi
6. CI/CD ja automatiseerimine: 9 tundi
7. Täiustatud teemad: 16 tundi

**PostgreSQL variantide käsitlus:**
- **Peatükk 3:** Mõlemad paigaldusviisid paralleelselt + võrdlus
- **Peatükk 6:** Node.js integratsioon mõlemas variandis
- **Peatükk 13:** Docker Compose mõlemas variandis
- **Peatükk 16:** Kubernetes deployment mõlemas variandis
- **Peatükk 21:** Monitoring mõlemas variandis
- **Peatükk 22:** Backup ja optimeerimine mõlemas variandis

**Primaarne fookus:** Docker/Kubernetes PostgreSQL
**Alternatiiv:** Väline PostgreSQL (selgelt märgitud)

**Praktiline lähenemisviis:**
- Iga peatükk sisaldab praktilisi ülesandeid
- Kasutatakse päris VPS-i (Hostinger)
- Kasutatakse päris andmebaasi (PostgreSQL mõlemas variandis)
- Õpilane saab valmis rakenduse, mille saab deployda

---

## JÄRGMISED SAMMUD

1. **Vali peatükk**, millega soovid alustada (soovitatav: Peatükk 1 või 3)
2. **Iga peatükk** täidetakse eraldi failina koos:
   - Detailse teoreetilise sisuga
   - Praktiliste näidetega
   - Koodi näidistega
   - Harjutustega
   - Kontrolliküsimustega
3. **Projektikataloog**: `/home/janek/Documents/Meie pere/õppematerjal/hostinger/`

---

**Autor:** Claude Code AI Agent
**Kuupäev:** 2025-11-14
**Versioon:** 1.0
