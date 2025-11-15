# Peatükk 15: Docker Registry ja Image Haldamine

**Kestus:** 3 tundi
**Eeldused:** Peatükk 12-14 läbitud
**Eesmärk:** Õppida Docker image'ite salvestamist, jagamist ja haldamist

---

## Sisukord

1. [Mis on Docker Registry?](#1-mis-on-docker-registry)
2. [Docker Hub](#2-docker-hub)
3. [Image Tagging Strateegiad](#3-image-tagging-strateegiad)
4. [Private Registry VPS-il](#4-private-registry-vps-il)
5. [Image Push ja Pull](#5-image-push-ja-pull)
6. [Security Scanning](#6-security-scanning)
7. [CI/CD Integratsioon](#7-cicd-integratsioon)
8. [Image Cleanup](#8-image-cleanup)
9. [Harjutused](#9-harjutused)

---

## 1. Mis on Docker Registry?

### 1.1. Definitsioon

**Docker Registry** on teenus Docker image'ite salvestamiseks ja levitamiseks.

**Analoogia:** Git ja GitHub
- **Git** = Docker
- **GitHub** = Docker Registry (nt Docker Hub)
- **Repository** = Image repositoorium

---

### 1.2. Registry Tüübid

**1. Public Registry:**
- **Docker Hub** - kõige populaarsem
- **GitHub Container Registry**
- **Quay.io**

**2. Private Registry:**
- **Oma VPS-il** (Docker Registry konteiner)
- **Cloud providers** (AWS ECR, Google GCR, Azure ACR)

**3. Self-hosted Enterprise:**
- **Harbor**
- **Artifactory**

---

### 1.3. Miks Registry?

✅ **Jagamine:** Image'id teistele arendajatele
✅ **Versioonihaldus:** Erinevad versioonid (tags)
✅ **CI/CD:** Automated build ja deployment
✅ **Backup:** Image'id ei kao
✅ **Private:** Oma ettevõtte image'id

---

## 2. Docker Hub

### 2.1. Mis on Docker Hub?

**Docker Hub** on Docker'i ametlik public registry.

URL: https://hub.docker.com

**Funktsioonid:**
- Tasuta public repositooriumid (unlimited)
- Tasuta 1 private repositoorium
- Automated builds
- Webhooks
- Teams ja organisatsioonid

---

### 2.2. Docker Hub Konto Loomine

**1. Registreeru:**

Brauseris: https://hub.docker.com/signup

**2. Kinnita email**

**3. Loo repositoorium:**

Docker Hub → Repositories → Create Repository

- **Name:** `backend-nodejs`
- **Visibility:** Public või Private
- **Description:** "Node.js Express Backend"

---

### 2.3. Docker Hub Login

VPS-is `kirjakast`:

```bash
# Login
docker login

# Küsib:
# Username: sinu-username
# Password: sinu-parool

# Väljund:
# Login Succeeded
```

**MÄRKUS:** Parool salvestuub `~/.docker/config.json`

---

### 2.4. Logout

```bash
# Logout (oluline shared serverites)
docker logout

# Kustuta credentials
rm ~/.docker/config.json
```

---

## 3. Image Tagging Strateegiad

### 3.1. Image Tag Süntaks

```
registry/username/image:tag

Näited:
docker.io/johndoe/backend:1.0
docker.io/johndoe/backend:latest
ghcr.io/myorg/backend:v2.1.0
localhost:5000/backend:dev
```

**Komponendid:**
- `registry`: Docker Hub (docker.io), GCR, ECR, jne
- `username`: Kasutaja või organisatsioon
- `image`: Image nimi
- `tag`: Versioon

---

### 3.2. Tagging Best Practices

**✅ HEAD:**

- **Semantic Versioning:** `1.0.0`, `1.2.3`, `2.0.0`
- **Git commit SHA:** `abc123f`
- **Git branch:** `main`, `develop`
- **Environment:** `production`, `staging`, `dev`
- **Date:** `2025-11-15`

**❌ VALE:**

- **latest** production-is (ei tea, mis versioon)
- **Üldised tag-id:** `v1`, `test`

---

### 3.3. Näited

```bash
# Semantic versioning
backend:1.0.0
backend:1.2.3
backend:2.0.0

# Git SHA
backend:abc123f
backend:def456a

# Branch + SHA
backend:main-abc123f
backend:develop-def456a

# Environment
backend:production
backend:staging

# Mitmik tags
backend:1.0.0
backend:1.0
backend:1
backend:latest
```

---

### 3.4. Image Tag'imine

```bash
# Build ja tag korraga
docker build -t username/backend:1.0.0 .

# Tag olemasolev image
docker tag backend:latest username/backend:1.0.0
docker tag backend:latest username/backend:latest

# Mitu tag-i
docker tag backend:latest username/backend:1.0.0
docker tag backend:latest username/backend:1.0
docker tag backend:latest username/backend:latest

# Vaata image'e
docker images | grep backend

# Väljund:
# username/backend   1.0.0    abc123   ...
# username/backend   1.0      abc123   ...
# username/backend   latest   abc123   ...
```

---

## 4. Private Registry VPS-il

### 4.1. Miks Private Registry?

✅ **Kontroll:** Oma infra
✅ **Turvalisus:** Ei jaga Docker Hub-iga
✅ **Kiirus:** VPS-is, väike latency
✅ **Tasuta:** Unlimited private images

---

### 4.2. Registry Konteiner Käivitamine

```bash
# SSH VPS-i
ssh janek@kirjakast

# Käivita registry
docker run -d \
  --name registry \
  --restart unless-stopped \
  -p 5000:5000 \
  -v registry-data:/var/lib/registry \
  registry:2

# Kontrolli
docker ps | grep registry

# Testi
curl http://localhost:5000/v2/_catalog

# Väljund:
# {"repositories":[]}
```

---

### 4.3. Registry SSL/TLS-iga (soovitatud)

**Probleem:** HTTP registry ei ole turvaline

**Lahendus:** HTTPS self-signed sertifikaadiga

```bash
# Loo sertifikaadi kataloog
mkdir -p ~/registry/certs

# Genereeri self-signed sert
cd ~/registry/certs
openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout domain.key -x509 -days 365 \
  -out domain.crt \
  -subj "/CN=kirjakast"

# Käivita registry HTTPS-iga
docker run -d \
  --name registry \
  --restart unless-stopped \
  -p 5000:5000 \
  -v registry-data:/var/lib/registry \
  -v ~/registry/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```

**Kontrolli:**

```bash
curl -k https://localhost:5000/v2/_catalog
```

---

### 4.4. Registry Authentication (valikuline)

```bash
# Loo password file
mkdir -p ~/registry/auth
docker run --rm \
  --entrypoint htpasswd \
  httpd:2 -Bbn janek MyPassword123 > ~/registry/auth/htpasswd

# Käivita registry auth-iga
docker run -d \
  --name registry \
  --restart unless-stopped \
  -p 5000:5000 \
  -v registry-data:/var/lib/registry \
  -v ~/registry/auth:/auth \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  registry:2

# Login
docker login localhost:5000
# Username: janek
# Password: MyPassword123
```

---

## 5. Image Push ja Pull

### 5.1. Push Docker Hub-i

```bash
# 1. Login
docker login

# 2. Tag image
docker tag backend:1.0 username/backend:1.0
docker tag backend:1.0 username/backend:latest

# 3. Push
docker push username/backend:1.0
docker push username/backend:latest

# Väljund:
# The push refers to repository [docker.io/username/backend]
# abc123: Pushed
# def456: Pushed
# 1.0: digest: sha256:... size: 1234
```

---

### 5.2. Push Private Registry-sse

```bash
# 1. Tag image
docker tag backend:1.0 localhost:5000/backend:1.0

# 2. Push
docker push localhost:5000/backend:1.0

# 3. Kontrolli
curl http://localhost:5000/v2/_catalog

# Väljund:
# {"repositories":["backend"]}

# Tags
curl http://localhost:5000/v2/backend/tags/list

# Väljund:
# {"name":"backend","tags":["1.0"]}
```

---

### 5.3. Pull Image'i

```bash
# Pull Docker Hub-ist
docker pull username/backend:1.0

# Pull private registry-st
docker pull localhost:5000/backend:1.0

# Pull konkreetne tag
docker pull postgres:16-alpine

# Pull kõik tag-id (ettevaatust!)
docker pull -a username/backend
```

---

## 6. Security Scanning

### 6.1. Docker Scan (Built-in)

```bash
# Scan image
docker scan backend:1.0

# Väljund:
# Tested 123 dependencies for known issues, found 5 issues
#
# Issues to fix by upgrading:
#   Upgrade node:18-alpine to node:18.19-alpine to fix
#   ✗ Critical severity vulnerability found in openssl
#     ...
```

---

### 6.2. Trivy (soovitatud)

**Trivy** on populaarne security scanner.

**Paigaldamine:**

```bash
# Paigalda Trivy
sudo apt install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
  sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install trivy -y

# Kontrolli
trivy --version
```

**Kasutamine:**

```bash
# Scan image
trivy image backend:1.0

# Väljund:
# backend:1.0 (alpine 3.19.0)
# Total: 5 (CRITICAL: 2, HIGH: 2, MEDIUM: 1, LOW: 0)
#
# | CVE-2024-1234 | CRITICAL | openssl | 1.1.1 | Fixed in 1.1.2 |
# ...

# Scan ainult CRITICAL ja HIGH
trivy image --severity CRITICAL,HIGH backend:1.0

# JSON output (CI/CD jaoks)
trivy image -f json -o results.json backend:1.0
```

---

## 7. CI/CD Integratsioon

### 7.1. GitHub Actions Näide

`.github/workflows/docker-build.yml`:

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

env:
  REGISTRY: docker.io
  IMAGE_NAME: username/backend

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Login to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}
          type=sha,prefix={{branch}}-

    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Scan image
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
```

**Secrets (GitHub Settings → Secrets):**
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` (Docker Hub → Account Settings → Security → New Access Token)

---

### 7.2. Manual Deploy Script

```bash
# deploy.sh
#!/bin/bash

set -e

# Config
REGISTRY="username"
IMAGE="backend"
VERSION=$(git rev-parse --short HEAD)
TAG="$REGISTRY/$IMAGE:$VERSION"

echo "Building $TAG..."
docker build -t $TAG .

echo "Scanning for vulnerabilities..."
trivy image --severity CRITICAL,HIGH --exit-code 1 $TAG

echo "Pushing to registry..."
docker push $TAG

echo "Deploying to VPS..."
ssh janek@kirjakast << EOF
  docker pull $TAG
  docker stop backend || true
  docker rm backend || true
  docker run -d --name backend \
    -p 3000:3000 \
    --restart unless-stopped \
    $TAG
EOF

echo "Deployed $TAG successfully!"
```

Kasutamine:

```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 8. Image Cleanup

### 8.1. Lokaalsed Image'd

```bash
# Vaata kõiki image'e
docker images

# Kustuta kasutamata image'd
docker image prune

# Kustuta kõik kasutamata (+ dangling)
docker image prune -a

# Force (ilma kinnituseta)
docker image prune -a -f

# Kustuta konkreetne image
docker rmi backend:1.0

# Kustuta mitu
docker rmi backend:1.0 backend:2.0 postgres:15
```

---

### 8.2. Registry Cleanup

```bash
# Private registry cleanup (registry container-is)
docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml

# Docker Hub - käsitsi web UI's
# Hub → Repositories → backend → Tags → Delete
```

---

### 8.3. Automated Cleanup Script

```bash
# cleanup-old-images.sh
#!/bin/bash

# Kustuta image'd, mis on vanemad kui 30 päeva
docker images --format "{{.Repository}}:{{.Tag}} {{.CreatedAt}}" | \
  awk '$3 < "'$(date -d '30 days ago' +%Y-%m-%d)'" {print $1}' | \
  xargs -r docker rmi

# Kustuta dangling images
docker image prune -f
```

Crontab (käivita iga nädal):

```bash
# Redigeeri crontab
crontab -e
```

Lisa:

```
0 2 * * 0 /home/janek/cleanup-old-images.sh
```

---

## 9. Harjutused

### Harjutus 15.1: Docker Hub

1. Loo Docker Hub konto
2. Login VPS-is: `docker login`
3. Build image: `docker build -t username/test:1.0 .`
4. Push: `docker push username/test:1.0`
5. Kontrolli Docker Hub web UI-s

---

### Harjutus 15.2: Private Registry

1. Käivita registry VPS-is
2. Tag image: `docker tag backend:1.0 localhost:5000/backend:1.0`
3. Push: `docker push localhost:5000/backend:1.0`
4. Kontrolli: `curl http://localhost:5000/v2/_catalog`

---

### Harjutus 15.3: Tagging Strateegia

1. Build backend image
2. Tag mitmega:
   - `username/backend:1.0.0`
   - `username/backend:1.0`
   - `username/backend:latest`
   - `username/backend:$(git rev-parse --short HEAD)`
3. Push kõik: `docker push username/backend --all-tags`

---

### Harjutus 15.4: Security Scan

1. Paigalda Trivy
2. Scan image: `trivy image backend:1.0`
3. Paranda vulnerabilities (upgrade base image)
4. Scan uuesti ja võrdle

---

### Harjutus 15.5: CI/CD Pipeline

1. Loo GitHub repo
2. Lisa `.github/workflows/docker-build.yml`
3. Seadista secrets
4. Push code
5. Vaata GitHub Actions build-i

---

## Kokkuvõte

Selles peatükis said:

✅ **Mõistsid Docker Registry kontseptsiooni**
✅ **Lõid Docker Hub konto ja push-isid image-e**
✅ **Seadistasid private registry VPS-il**
✅ **Õppisid image tagging best practices-e**
✅ **Kasutasid security scanning-ut (Trivy)**
✅ **Integreerisid CI/CD-ga (GitHub Actions)**
✅ **Automatiseerisid image cleanup-i**

---

## Järgmine Peatükk

**Peatükk 16: Kubernetes Alused**

Järgmises peatükis:
- Kubernetes arhitektuur
- K3s paigaldamine VPS-ile
- kubectl põhikäsud
- Pods, Deployments, Services

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
**VPS:** kirjakast (Ubuntu 24.04 LTS)
