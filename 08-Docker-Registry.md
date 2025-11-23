# Peatükk 8: Docker Registry ja Image Haldamine

**Kestus:** 3 tundi
**Eeldused:** Peatükk 4-7 (Docker põhimõtted, Dockerfile, Compose)
**Eesmärk:** Mõista Docker Registry arhitektuuri ja image haldamise strateegiaid

---

## Õpieesmärgid

- Mõista Docker Registry rolli image lifecycle's
- Erinevad registry tüübid (Docker Hub, self-hosted, Harbor)
- Image tagging strategies ja versioonimine
- Registry authentication ja turvalisus
- Private registry setup ja haldamine
- CI/CD integratsioon

---

## 8.1 Docker Registry Fundamentals

### Mis on Docker Registry?

**Docker Registry = Image storage and distribution system**

```
Developer workstation:
  1. docker build -t myapp:1.0 .  (Build image)
  2. docker push myapp:1.0         (Push to registry)

Production server:
  3. docker pull myapp:1.0         (Pull from registry)
  4. docker run myapp:1.0          (Run container)
```

**Miks me vajame registry't?**
- **Jagatavus:** Sama image mitmel serveril (dev, staging, prod)
- **Versioonimine:** Image history ja rollback võimalus
- **CI/CD:** Automaatne build → test → push → deploy workflow
- **Turvalisus:** Private images (mitte avalikud Docker Hub'is)

---

### Registry vs Repository vs Image

**Struktuur:**

```
Registry (server):
  docker.io (Docker Hub)
  gcr.io (Google Container Registry)
  your-registry.com (self-hosted)

Repository (namespace):
  library/nginx
  myorg/backend
  username/myapp

Image (versioned artifact):
  myapp:1.0
  myapp:1.1
  myapp:latest
```

**Analoogia Git'iga:**
```
Git:
  GitHub (server) → myorg/myrepo (repository) → commit SHA (version)

Docker:
  Docker Hub (registry) → myorg/myapp (repository) → myapp:1.0 (image)
```

---

## 8.2 Docker Hub - Public Registry

### Docker Hub Arhitektuur

**Docker Hub = Docker'i ametlik public registry**

```
URL: https://hub.docker.com

Official images:
  nginx           (no username prefix)
  postgres
  node

User images:
  myusername/backend
  myusername/frontend

Organizations:
  myorg/backend
  myorg/database
```

**Free tier (2024):**
- ✅ Unlimited public repositories
- ✅ 1 private repository
- ✅ Pull rate limit: 200/6h (authenticated), 100/6h (anonymous)
- ❌ No team collaboration (paid feature)

**Paid tiers:**
- Pro: $5/month (unlimited private repos, no rate limits)
- Team: $7/user/month (team collaboration)

---

### Docker Hub Workflow

**1. Create account ja repository:**

```bash
# Login
docker login
# Username: myusername
# Password: ********
```

**2. Tag image:**

```bash
# Build
docker build -t backend:1.0 .

# Tag for Docker Hub (username/repository:tag)
docker tag backend:1.0 myusername/backend:1.0
docker tag backend:1.0 myusername/backend:latest
```

**3. Push to Docker Hub:**

```bash
docker push myusername/backend:1.0
docker push myusername/backend:latest
```

**4. Pull from Docker Hub:**

```bash
# Any server can now pull (if public)
docker pull myusername/backend:1.0

# Use in Docker Compose
services:
  backend:
    image: myusername/backend:1.0  # Pulled from Docker Hub
```

---

### Tagging Strategies

**❌ BAD: Ainult `latest` tag**

```bash
docker build -t myapp:latest .
docker push myapp:latest
```

**Probleem:**
- Pole versioning'ut
- Rollback võimatu
- Ei tea, milline versioon production'is

---

**✅ GOOD: Semantic versioning + SHA**

```bash
# Git commit SHA
GIT_SHA=$(git rev-parse --short HEAD)

# Semantic version
VERSION="1.2.3"

# Tag multiple versions
docker tag myapp:latest myorg/myapp:${VERSION}
docker tag myapp:latest myorg/myapp:${GIT_SHA}
docker tag myapp:latest myorg/myapp:latest

# Push all tags
docker push myorg/myapp:${VERSION}
docker push myorg/myapp:${GIT_SHA}
docker push myorg/myapp:latest
```

**Production deployment:**

```yaml
# Deployment uses specific version (not latest!)
spec:
  containers:
  - name: backend
    image: myorg/backend:1.2.3  # NEVER use :latest in prod!
```

**Rollback:**

```bash
# Rollback to previous version
kubectl set image deployment/backend backend=myorg/backend:1.2.2
```

---

## 8.3 Private Docker Registry - Self-Hosted

### Miks Self-Hosted Registry?

**Use cases:**
- ✅ **Turvalisus:** Organisatsiooni internal images ei lähe public internet'i
- ✅ **Kontroll:** Oma serveris, oma reeglid
- ✅ **Kiirus:** LAN-is pull/push on kiirem kui Docker Hub
- ✅ **Maksuvaba:** Ei maksa Docker Hub Pro eest
- ❌ **Maintenance:** Peab ise haldama (storage, backup, SSL)

---

### Docker Registry Setup (Official Image)

**Architecture:**

```
Docker Registry container:
  - Image: registry:2
  - Port: 5000
  - Storage: Volume (persist images)
  - Auth: Basic HTTP auth (optional)
  - TLS: Nginx reverse proxy (recommended)
```

**Basic setup (no auth, HTTP only - DEV ONLY!):**

```yaml
# docker-compose.yml
version: '3.8'

services:
  registry:
    image: registry:2
    ports:
      - "5000:5000"
    volumes:
      - registry-data:/var/lib/registry
    environment:
      REGISTRY_STORAGE_DELETE_ENABLED: 'true'

volumes:
  registry-data:
```

**Start registry:**

```bash
docker compose up -d

# Push to local registry
docker tag myapp:1.0 localhost:5000/myapp:1.0
docker push localhost:5000/myapp:1.0

# Pull from local registry
docker pull localhost:5000/myapp:1.0
```

---

### Production Registry Setup (HTTPS + Auth)

**Architecture:**

```
Internet → Nginx (HTTPS, port 443)
           ├─ SSL termination (Let's Encrypt)
           ├─ Basic Auth
           └─ Proxy to Registry (port 5000)
```

**docker-compose.yml (production):**

```yaml
version: '3.8'

services:
  registry:
    image: registry:2
    restart: always
    environment:
      REGISTRY_STORAGE_DELETE_ENABLED: 'true'
      REGISTRY_HTTP_SECRET: 'your-random-secret-here'
    volumes:
      - registry-data:/var/lib/registry

  nginx:
    image: nginx:alpine
    restart: always
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./htpasswd:/etc/nginx/htpasswd:ro  # Basic auth
      - /etc/letsencrypt:/etc/letsencrypt:ro  # SSL certs
    depends_on:
      - registry

volumes:
  registry-data:
```

**Create htpasswd (authentication):**

```bash
# Install htpasswd utility
sudo apt install apache2-utils

# Create user:password
htpasswd -Bc htpasswd admin
# Password: ********
```

**nginx.conf (reverse proxy):**

```nginx
events {}

http {
  upstream registry {
    server registry:5000;
  }

  server {
    listen 443 ssl;
    server_name registry.example.com;

    ssl_certificate /etc/letsencrypt/live/registry.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/registry.example.com/privkey.pem;

    client_max_body_size 0;  # Allow large image uploads

    location / {
      auth_basic "Registry Authentication";
      auth_basic_user_file /etc/nginx/htpasswd;

      proxy_pass http://registry;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }
  }

  # HTTP redirect to HTTPS
  server {
    listen 80;
    server_name registry.example.com;
    return 301 https://$server_name$request_uri;
  }
}
```

**Login and use:**

```bash
# Login to private registry
docker login registry.example.com
# Username: admin
# Password: ********

# Push
docker tag myapp:1.0 registry.example.com/myapp:1.0
docker push registry.example.com/myapp:1.0

# Pull
docker pull registry.example.com/myapp:1.0
```

---

## 8.4 Harbor - Enterprise Registry

### Harbor vs Docker Registry

| Feature | Docker Registry | Harbor |
|---------|-----------------|---------|
| **Tugi** | Official Docker | CNCF project |
| **UI** | ❌ Ei ole | ✅ Web UI |
| **Auth** | Basic HTTP | LDAP, OIDC, DB |
| **RBAC** | ❌ | ✅ Projects, roles |
| **Vulnerability scan** | ❌ | ✅ Trivy, Clair |
| **Image signing** | ❌ | ✅ Notary, Cosign |
| **Replication** | ❌ | ✅ Multi-registry |
| **Garbage collection** | Manual | Scheduled |
| **Complexity** | Lihtne | Keeruline |
| **Best for** | Dev/staging | Production/enterprise |

**Harbor arhitektuur:**

```
Harbor components:
  - Core (API, Web UI)
  - Registry (Docker Registry v2)
  - PostgreSQL (metadata)
  - Redis (cache, job queue)
  - Trivy/Clair (vulnerability scanner)
  - Notary (image signing)
  - ChartMuseum (Helm charts)
```

---

### Harbor Features

**1. Projects ja RBAC:**

```
Project: myorg/backend
  Users:
    - admin (full access)
    - developer (push/pull)
    - viewer (pull only)

Permissions:
  - Push images
  - Pull images
  - Delete images
  - Scan images
```

**2. Vulnerability Scanning:**

```
Image: myorg/backend:1.0
  Scan results:
    - CVE-2023-12345 (Critical)
    - CVE-2023-67890 (High)
    - 15 Medium, 30 Low

Action: Block deployment if Critical vulnerabilities
```

**3. Image Retention Policies:**

```yaml
# Keep only:
- Last 10 tags
- Tags newer than 30 days
- Tags matching regex: v\d+\.\d+\.\d+ (semantic versions)

# Delete:
- Untagged images
- Old development tags (dev-*, test-*)
```

**4. Replication:**

```
Primary Harbor (AWS):
  myorg/backend:1.0

Replicate to:
  Secondary Harbor (Azure): myorg/backend:1.0
  DR Harbor (on-prem): myorg/backend:1.0
```

📖 **Praktika:** Labor 2, Harjutus 5 - Harbor setup (optional advanced)

---

## 8.5 Registry Security

### Best Practices

**1. HTTPS Always (Production):**

```bash
# ✅ GOOD
docker push registry.example.com/myapp:1.0  # HTTPS

# ❌ BAD
docker push localhost:5000/myapp:1.0  # HTTP (dev only!)
```

---

**2. Authentication:**

```yaml
# Kubernetes: Pull private images
apiVersion: v1
kind: Secret
metadata:
  name: registry-credentials
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: BASE64_ENCODED_DOCKER_CONFIG

---
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      imagePullSecrets:
      - name: registry-credentials  # Use credentials for pull
      containers:
      - name: backend
        image: registry.example.com/myapp:1.0
```

**Create secret:**

```bash
kubectl create secret docker-registry registry-credentials \
  --docker-server=registry.example.com \
  --docker-username=admin \
  --docker-password=yourpassword \
  --docker-email=admin@example.com
```

---

**3. Image Scanning:**

```bash
# Scan before push (CI/CD)
docker build -t myapp:1.0 .
trivy image myapp:1.0

# Fail CI if Critical vulnerabilities
trivy image --severity CRITICAL --exit-code 1 myapp:1.0
```

---

**4. Image Signing (Cosign):**

```bash
# Sign image after push
cosign sign --key cosign.key myorg/backend:1.0

# Verify before deploy
cosign verify --key cosign.pub myorg/backend:1.0
```

---

**5. Least Privilege:**

```
Registry users:
  - CI/CD bot: push/pull (automated)
  - Developers: pull only (manual testing)
  - Production K8s: pull only (deployment)
  - Admin: full access (registry management)
```

---

## 8.6 Registry Storage Management

### Storage Drivers

**Docker Registry supports:**

```
filesystem:  /var/lib/registry (default, local disk)
s3:          AWS S3
gcs:         Google Cloud Storage
azure:       Azure Blob Storage
swift:       OpenStack Swift
```

**S3 backend example:**

```yaml
# config.yml
storage:
  s3:
    accesskey: AWS_ACCESS_KEY
    secretkey: AWS_SECRET_KEY
    region: us-east-1
    bucket: my-docker-registry
    encrypt: true
    secure: true
```

**Benefit:** Unlimited storage, HA, geo-replication

---

### Garbage Collection

**Problem:** Deleted images jäävad registry'sse (layers ei kustutata)

```
Initial state:
  myapp:1.0 (100MB)
  myapp:1.1 (105MB - shares 95MB with 1.0)

Delete myapp:1.0:
  myapp:1.1 (105MB)
  Orphaned layers: 5MB (from 1.0, unused)

Garbage collection:
  myapp:1.1 (100MB)  # Reclaimed 5MB
```

**Run garbage collection:**

```bash
# Stop registry
docker compose stop registry

# Run GC
docker run --rm -v registry-data:/var/lib/registry \
  registry:2 garbage-collect /etc/docker/registry/config.yml

# Start registry
docker compose start registry
```

**Harbor:** Automatic scheduled GC (Web UI → Administration → Garbage Collection)

---

## 8.7 Alternative Registries

### Võrdlus

| Registry | Type | Best for | Cost |
|----------|------|----------|------|
| **Docker Hub** | SaaS | Public OSS, small teams | Free tier (limited) |
| **Docker Registry** | Self-hosted | Internal dev/staging | Free (maintenance cost) |
| **Harbor** | Self-hosted | Enterprise production | Free (CNCF) |
| **AWS ECR** | Cloud | AWS-native | Pay-per-GB storage + transfer |
| **GCR/Artifact Registry** | Cloud | GCP-native | Pay-per-GB |
| **Azure ACR** | Cloud | Azure-native | Pay-per-GB |
| **GitHub Container Registry** | SaaS | GitHub projects | Free (public), included (private) |
| **GitLab Container Registry** | SaaS/Self-hosted | GitLab projects | Included |
| **JFrog Artifactory** | SaaS/Self-hosted | Multi-format (Docker, Maven, npm) | Enterprise pricing |

---

### Cloud Provider Registries

**AWS ECR:**

```bash
# Login (uses AWS CLI)
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS \
  --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Push
docker tag myapp:1.0 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:1.0
```

**Google Artifact Registry:**

```bash
# Login (uses gcloud)
gcloud auth configure-docker us-central1-docker.pkg.dev

# Push
docker tag myapp:1.0 us-central1-docker.pkg.dev/my-project/my-repo/myapp:1.0
docker push us-central1-docker.pkg.dev/my-project/my-repo/myapp:1.0
```

**Benefit:** Native cloud integration (IAM, billing, network)

---

## 8.8 CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/build.yml
name: Build and Push

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Login to Docker Hub
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      # Build and tag
      - name: Build image
        run: |
          VERSION=$(git describe --tags --always)
          docker build -t myorg/backend:${VERSION} .
          docker tag myorg/backend:${VERSION} myorg/backend:latest

      # Push to registry
      - name: Push to Docker Hub
        run: |
          VERSION=$(git describe --tags --always)
          docker push myorg/backend:${VERSION}
          docker push myorg/backend:latest
```

**Multi-registry push:**

```yaml
# Push to Docker Hub + private registry
- name: Push to registries
  run: |
    VERSION=$(git describe --tags --always)

    # Docker Hub
    docker push myorg/backend:${VERSION}

    # Private registry
    docker tag myorg/backend:${VERSION} registry.example.com/backend:${VERSION}
    docker push registry.example.com/backend:${VERSION}
```

📖 **Praktika:** Labor 5, Harjutus 2 - CI/CD Docker build + push

---

## 8.9 Registry Monitoring

### Health Check

```bash
# Docker Registry API v2
curl https://registry.example.com/v2/

# Expected response:
{}  # HTTP 200 OK

# List repositories
curl -u admin:password https://registry.example.com/v2/_catalog

# List tags
curl -u admin:password https://registry.example.com/v2/myapp/tags/list
```

---

### Prometheus Metrics

**Harbor:** Built-in Prometheus exporter

```yaml
# Harbor metrics endpoint
http://harbor.example.com/api/v2.0/metrics

# Prometheus scrape config
scrape_configs:
  - job_name: 'harbor'
    static_configs:
      - targets: ['harbor.example.com:80']
    metrics_path: /api/v2.0/metrics
```

**Metrics:**
- `harbor_project_total` - Total projects
- `harbor_repo_total` - Total repositories
- `harbor_artifact_total` - Total artifacts (images)
- `registry_http_requests_total` - HTTP requests
- `registry_storage_action_seconds` - Storage latency

---

## Kokkuvõte

**Docker Registry:**
- **Public:** Docker Hub (free tier, rate limits)
- **Self-hosted:** Docker Registry (simple, no UI)
- **Enterprise:** Harbor (UI, RBAC, vulnerability scanning, replication)
- **Cloud:** ECR, GCR, ACR (native cloud integration)

**Tagging strategies:**
- ✅ Semantic versioning (1.2.3)
- ✅ Git SHA (abc123)
- ✅ Multiple tags (version + SHA + latest)
- ❌ NEVER use `:latest` in production deployments

**Security:**
- ✅ HTTPS always (Let's Encrypt)
- ✅ Authentication (htpasswd, LDAP, OIDC)
- ✅ Image scanning (Trivy, Clair)
- ✅ Image signing (Cosign, Notary)
- ✅ RBAC (Harbor projects)

**Storage:**
- Filesystem (default), S3, GCS, Azure Blob
- Garbage collection (reclaim space)
- Retention policies (auto-delete old tags)

**CI/CD:**
- Automated build → tag → scan → push
- Multi-registry replication
- Kubernetes integration (imagePullSecrets)

---

**DevOps Vaatenurk:**

```bash
# Local development: Docker Hub
docker push myusername/myapp:dev

# Staging/Production: Private registry (Harbor)
docker push registry.example.com/myapp:1.0

# Cloud deployment: Cloud provider registry
docker push us-central1-docker.pkg.dev/my-project/myapp:1.0

# Check registry health
curl https://registry.example.com/v2/

# List images
curl -u admin:pass https://registry.example.com/v2/_catalog
```

---

**Järgmised Sammud:**
**Peatükk 9:** Kubernetes Alused ja K3s Setup
**Peatükk 14:** Ingress ja Load Balancing (Advanced K8s)

📖 **Praktika:** Labor 2, Harjutus 5 - Private Docker Registry setup
