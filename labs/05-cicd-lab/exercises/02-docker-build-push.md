# Harjutus 2: Docker Build ja Push

**Kestus:** 60 minutit
**Eesmärk:** Automatiseerida Docker image build ja push Docker Hub'i GitHub Actions'iga

---

## 📋 Ülevaade

Selles harjutuses õpid automatiseerima Docker image build'i ja push'i Docker Hub'i GitHub Actions workflow'dega. See on CI/CD pipeline'i oluline osa - iga koodi muudatus ehitatakse automaatselt uueks Docker image'iks.

**Docker build automation** tagab, et image'id on alati ajakohased, versioonitud ja valmis deploy'miseks. Kasutame `docker/build-push-action` marketplace action'i, mis toetab multi-platform build'e, cache'i ja tagging strateegiaid.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Autentida Docker Hub'i GitHub Actions's
- ✅ Kasutada `docker/build-push-action`
- ✅ Ehitada multi-stage Docker image'id
- ✅ Implementeerida image tagging strateegiat (latest, versioned, sha)
- ✅ Optimeerida build cache'i
- ✅ Push'ida image'id Docker Hub'i automaatselt
- ✅ Kasutada Docker Hub secrets'eid turvaliselt

---

## 🏗️ Arhitektuur

```
┌──────────────────────────────────────────────────┐
│         GitHub Repository                        │
│                                                  │
│  Developer push code                             │
│         │                                        │
│         ▼                                        │
│  ┌────────────────────────────────────────────┐ │
│  │  .github/workflows/docker-build.yml       │ │
│  │                                            │ │
│  │  on: [push]                                │ │
│  │                                            │ │
│  │  jobs:                                     │ │
│  │    build-and-push:                         │ │
│  │      - Login Docker Hub                    │ │
│  │      - Build image (multi-stage)           │ │
│  │      - Tag: latest, v1.0.0, sha-abc123     │ │
│  │      - Push Docker Hub                     │ │
│  └────────────────┬───────────────────────────┘ │
│                   │                              │
└───────────────────┼──────────────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   Docker Hub          │
        │                       │
        │   your-username/      │
        │   user-service:       │
        │     - latest          │
        │     - v1.0.0          │
        │     - sha-abc123      │
        └───────────────────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  Kubernetes Cluster   │
        │  kubectl apply -f     │
        │  deployment.yaml      │
        └───────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Loo Docker Hub Konto (5 min)

**1. Registreeru Docker Hub'is:**

- Mine: https://hub.docker.com/signup
- Loo konto (tasuta)
- Verifitseeri email

**2. Loo Access Token:**

1. Docker Hub → Account Settings → **Security** → **Access Tokens**
2. Kliki **New Access Token**
3. Nimi: `github-actions`
4. Permissions: **Read & Write**
5. **Generate** → kopeeri token (näed ainult üks kord!)

**3. Testi local login:**

```bash
# Login Docker Hub'i
docker login

# Username: your-dockerhub-username
# Password: your-access-token (MITTE password!)

# Peaks näitama:
# Login Succeeded
```

---

### Samm 2: Lisa Docker Hub Secrets (5 min)

**Lisa secrets GitHub repository'sse:**

1. GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Kliki **New repository secret**

**Secret 1:**
- Name: `DOCKER_USERNAME`
- Value: `your-dockerhub-username`
- Kliki **Add secret**

**Secret 2:**
- Name: `DOCKER_PASSWORD`
- Value: `your-docker-hub-access-token` (mitte password!)
- Kliki **Add secret**

**Kontrolli:**

```bash
# Secrets peaksid olema lisatud
# Settings → Secrets → Actions
# - DOCKER_USERNAME
# - DOCKER_PASSWORD
```

---

### Samm 3: Loo Dockerfile (10 min)

**Loo optimeeritud multi-stage Dockerfile:**

Loo fail `Dockerfile` (kui pole juba olemas):

```dockerfile
# Stage 1: Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install ALL dependencies (including devDependencies)
RUN npm ci

# Copy source code
COPY . .

# Optional: Run build step if needed
# RUN npm run build

# ============================================
# Stage 2: Production stage
FROM node:18-alpine AS production

# Add metadata
LABEL maintainer="your-email@example.com"
LABEL description="User Service API"
LABEL version="1.0.0"

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy only production dependencies
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy source from builder
COPY --from=builder --chown=nodejs:nodejs /app .

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "server.js"]
```

**Dockerfile selgitus:**

- **Stage 1 (builder):** Build dependencies
- **Stage 2 (production):** Ainult production files
- **Multi-stage:** Väiksem image (ei sisalda build tools)
- **Non-root user:** Security best practice
- **Health check:** Kubernetes readiness/liveness probe'ide jaoks

**Loo `.dockerignore`:**

```
node_modules
npm-debug.log
.env
.git
.gitignore
.github
README.md
.vscode
coverage
.DS_Store
```

**Commit:**

```bash
git add Dockerfile .dockerignore
git commit -m "Add optimized multi-stage Dockerfile"
git push origin main
```

---

### Samm 4: Loo Docker Build Workflow (15 min)

**Loo workflow Docker image build'iks ja push'iks:**

Loo fail `.github/workflows/docker-build.yml`:

```yaml
name: Docker Build and Push

on:
  push:
    branches: [main, develop]
    tags:
      - 'v*'  # Push on tag v1.0.0
  pull_request:
    branches: [main]
  workflow_dispatch:  # Manual trigger

env:
  REGISTRY: docker.io
  IMAGE_NAME: ${{ secrets.DOCKER_USERNAME }}/user-service

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      packages: write

    steps:
      # Step 1: Checkout code
      - name: Checkout code
        uses: actions/checkout@v3

      # Step 2: Set up Docker Buildx
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      # Step 3: Login to Docker Hub
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      # Step 4: Extract metadata (tags, labels)
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}

      # Step 5: Build and push Docker image
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64

      # Step 6: Image digest
      - name: Print image digest
        run: echo "Image pushed with digest ${{ steps.build.outputs.digest }}"
```

**Workflow selgitus:**

- **docker/setup-buildx-action:** Docker Buildx (multi-platform, cache)
- **docker/login-action:** Autentimine Docker Hub'i
- **docker/metadata-action:** Automaatne tag'imine (latest, version, sha)
- **docker/build-push-action:** Build ja push ühe action'iga
- **cache-from/cache-to:** GitHub Actions cache (kiirenda build'e)
- **platforms:** Multi-platform build (amd64, arm64)

**Commit ja push:**

```bash
git add .github/workflows/docker-build.yml
git commit -m "Add Docker build and push workflow"
git push origin main
```

---

### Samm 5: Vaata Workflow Käivitumist (5 min)

**GitHub Actions tab'is:**

1. Mine repository → **Actions**
2. Peaks näitama "Docker Build and Push" workflow käivitumas
3. Kliki run'ile → vaata step'e

**Oodatud väljund:**

```
✅ Checkout code
✅ Set up Docker Buildx
✅ Login to Docker Hub
   Login Succeeded
✅ Extract metadata
   Tags:
     - docker.io/your-username/user-service:main
     - docker.io/your-username/user-service:sha-abc1234
     - docker.io/your-username/user-service:latest
✅ Build and push
   [1/2] FROM docker.io/library/node:18-alpine
   [2/2] WORKDIR /app
   ...
   => exporting to image
   => pushing to docker.io/your-username/user-service:latest
   ✅ Image pushed successfully
```

**Kontrolli Docker Hub'is:**

1. Mine https://hub.docker.com
2. Repositories → `user-service`
3. Tags → peaks näitama:
   - `latest`
   - `main`
   - `sha-abc1234`

---

### Samm 6: Testi Image'i (5 min)

**Pull ja käivita build'itud image:**

```bash
# Pull image Docker Hub'ist
docker pull your-username/user-service:latest

# Käivita container
docker run -d --name user-service \
  -p 3000:3000 \
  -e DB_HOST=localhost \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=test-secret \
  your-username/user-service:latest

# Kontrolli
docker ps

# Testi health check
curl http://localhost:3000/health

# Peaks vastama:
# {"status":"ERROR","database":"disconnected",...}
# (See on OK - PostgreSQL pole veel ühendatud)

# Kustuta
docker rm -f user-service
```

---

### Samm 7: Implementeeri Semantic Versioning (10 min)

**Lisa Git tag workflow'le:**

```bash
# Loo Git tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Workflow käivitub automaatselt
# Vaata Actions tab'is
```

**Workflow tuvastab tag'i ja loob:**

- `your-username/user-service:v1.0.0`
- `your-username/user-service:1.0`
- `your-username/user-service:1`
- `your-username/user-service:latest`

**Semantic Versioning (SemVer):**

- **MAJOR.MINOR.PATCH** (1.0.0)
- **MAJOR:** Breaking changes (1.x.x → 2.0.0)
- **MINOR:** New features (1.0.x → 1.1.0)
- **PATCH:** Bug fixes (1.0.0 → 1.0.1)

**Tag'imise best practice:**

```bash
# Development
git push origin main → user-service:main, user-service:latest

# Pre-release
git tag v1.0.0-beta.1 → user-service:v1.0.0-beta.1

# Production release
git tag v1.0.0 → user-service:v1.0.0, user-service:1.0, user-service:1
```

---

### Samm 8: Optimeeri Build Cache (5 min)

**GitHub Actions cache kiirendab build'e:**

```yaml
# Workflow'is on juba:
cache-from: type=gha
cache-to: type=gha,mode=max
```

**Kontrolli cache kasutamist:**

1. Esimene build: ~5-10 minutit
2. Teine build (cache'iga): ~1-2 minutit

**Actions tab'is vaata:**

```
✅ Build and push
   => [internal] load build definition from Dockerfile
   => [internal] load metadata for docker.io/library/node:18-alpine
   => importing cache manifest from gha:...
   => [1/6] FROM docker.io/library/node:18-alpine (cached)
   => [2/6] WORKDIR /app (cached)
   => [3/6] COPY package*.json ./ (cached)
   => [4/6] RUN npm ci
   ...
```

**(cached)** = layer cache'ist, ei rebuild'i.

---

### Samm 9: Multi-Platform Build (Optional, 5 min)

**Ehita image'd Linux amd64 JA arm64 jaoks:**

Muuda `docker-build.yml`:

```yaml
- name: Build and push
  uses: docker/build-push-action@v4
  with:
    context: .
    push: true
    tags: ${{ steps.meta.outputs.tags }}
    platforms: linux/amd64,linux/arm64  # Lisa arm64
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

**Commit ja push:**

```bash
git add .github/workflows/docker-build.yml
git commit -m "Enable multi-platform build (amd64 + arm64)"
git push origin main
```

**Kontrolli Docker Hub'is:**

- Image toetab nüüd nii x86_64 kui ARM64 (Apple M1, Raspberry Pi)

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Docker Hub:**
  - [ ] Docker Hub konto
  - [ ] Access token
  - [ ] `user-service` repository

- [ ] **GitHub Secrets:**
  - [ ] `DOCKER_USERNAME`
  - [ ] `DOCKER_PASSWORD`

- [ ] **Repository files:**
  - [ ] `Dockerfile` (multi-stage)
  - [ ] `.dockerignore`
  - [ ] `.github/workflows/docker-build.yml`

- [ ] **Workflow:**
  - [ ] Build ja push toimib
  - [ ] Image'id Docker Hub'is
  - [ ] Tag strateegia toimib (latest, versioned, sha)

- [ ] **Docker Hub tags:**
  - [ ] `latest`
  - [ ] `main` (või `develop`)
  - [ ] `sha-xxxxxxx`
  - [ ] `v1.0.0` (kui tag loodud)

---

## 🐛 Troubleshooting

### Probleem 1: Login ebaõnnestub - unauthorized

**Sümptom:**
```
❌ Login to Docker Hub
   Error: Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password
```

**Diagnoos:**

1. **Kontrolli secrets:**

```bash
# Settings → Secrets → Actions
# DOCKER_USERNAME = your-dockerhub-username (MITTE email!)
# DOCKER_PASSWORD = access token (MITTE password!)
```

2. **Kontrolli Docker Hub access token:**

- Docker Hub → Account Settings → Security → Access Tokens
- Token peab olema **Read & Write** permission'iga

**Lahendus:**

```bash
# Loo uus access token Docker Hub'is
# Settings → Security → New Access Token
# Permissions: Read & Write
# Kopeeri token

# Uuenda GitHub secret
# Settings → Secrets → DOCKER_PASSWORD → Update
```

---

### Probleem 2: Build ebaõnnestub - No space left on device

**Sümptom:**
```
❌ Build and push
   Error: failed to solve: write /var/lib/docker/...: no space left on device
```

**Põhjus:**

- GitHub Actions runner'il on piiratud disk space (~14GB)
- Suurte image'ide build võib ruumi täis võtta

**Lahendus:**

**Variant A: Optimeeri Dockerfile**

```dockerfile
# Kasuta alpine base image (väiksem)
FROM node:18-alpine

# Puhasta cache
RUN npm ci --only=production && npm cache clean --force

# Multi-stage build (ainult production files)
```

**Variant B: Puhasta vanad image'id workflow's**

```yaml
- name: Clean up Docker
  run: |
    docker system prune -af --volumes
    df -h  # Näita disk space
```

---

### Probleem 3: Tag ei eksisteeri Docker Hub'is

**Sümptom:**

```bash
docker pull your-username/user-service:v1.0.0
# Error: manifest for your-username/user-service:v1.0.0 not found
```

**Diagnoos:**

```bash
# Kontrolli, kas Git tag eksisteerib
git tag

# Kontrolli, kas tag push'iti
git ls-remote --tags origin

# Kontrolli workflow trigger'it
# .github/workflows/docker-build.yml
on:
  push:
    tags:
      - 'v*'  # Peaks olema
```

**Lahendus:**

```bash
# Push tag'i
git tag v1.0.0
git push origin v1.0.0

# Workflow käivitub automaatselt
# Kontrolli Actions tab'is
```

---

### Probleem 4: Multi-platform build aeglane

**Sümptom:**

Build võtab 20+ minutit (multi-platform arm64).

**Lahendus:**

**Variant A: Ehita ainult amd64 (kiire):**

```yaml
platforms: linux/amd64
```

**Variant B: Kasuta cache'i:**

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

**Variant C: Parallel build:**

```yaml
- name: Build amd64 and arm64 separately
  uses: docker/build-push-action@v4
  with:
    platforms: linux/amd64,linux/arm64
    cache-from: type=gha
    cache-to: type=gha,mode=max
    outputs: type=image,push=true
```

---

## 🎓 Õpitud Mõisted

### Docker Actions:
- **docker/setup-buildx-action:** Docker Buildx setup (multi-platform, cache)
- **docker/login-action:** Registry autentimine (Docker Hub, GHCR, ECR)
- **docker/metadata-action:** Automaatne tag'imine ja label'imine
- **docker/build-push-action:** Build ja push ühe action'iga

### Tagging Strategies:
- **latest:** Viimane main branch build
- **sha-abc123:** Git commit SHA (täpne versioon)
- **v1.0.0:** Semantic version (release tag)
- **main, develop:** Branch name

### Build Optimization:
- **Multi-stage build:** Väiksem production image
- **Build cache:** GitHub Actions cache (layer cache)
- **.dockerignore:** Excludes tarbetud failid
- **Layer caching:** Docker layer cache (korduvkasutus)

### Security:
- **Access tokens:** Docker Hub token (mitte password!)
- **GitHub Secrets:** Turvaliselt secrets'ide salvestamine
- **Non-root user:** Security best practice
- **Image scanning:** (järgmises harjutuses)

---

## 💡 Parimad Tavad

1. **Kasuta multi-stage build'e** - Väiksemad production image'id
2. **Tag'i sematic versioning'iga** - v1.0.0, v1.1.0, v2.0.0
3. **Kasuta build cache'i** - GitHub Actions cache (kiirenda build'e)
4. **Lisa health check** - Docker HEALTHCHECK directive
5. **Optimeeri .dockerignore** - Excludes node_modules, .git, jne
6. **Kasuta Alpine base image'e** - Väiksemad (~50MB vs ~900MB)
7. **Non-root user** - Security best practice
8. **Versiooni base image** - `node:18-alpine` (mitte `node:latest`)
9. **Puhasta cache** - `npm cache clean --force`
10. **Scan image'id** - Trivy, Snyk (security scanning)

---

## 🔗 Järgmine Samm

Nüüd sul on automaatne Docker build ja push! Järgmises harjutuses automatiseerime **Kubernetes deploy'i** - push'ime build'itud image'd automaatselt Kubernetes clusterisse.

**Jätka:** [Harjutus 3: Kubernetes Deploy](03-kubernetes-deploy.md)

---

## 📚 Viited

### GitHub Actions:
- [docker/build-push-action](https://github.com/docker/build-push-action)
- [docker/login-action](https://github.com/docker/login-action)
- [docker/metadata-action](https://github.com/docker/metadata-action)
- [docker/setup-buildx-action](https://github.com/docker/setup-buildx-action)

### Docker:
- [Docker Hub](https://hub.docker.com)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Best practices](https://docs.docker.com/develop/dev-best-practices/)
- [HEALTHCHECK](https://docs.docker.com/engine/reference/builder/#healthcheck)

### Tagging:
- [Semantic Versioning](https://semver.org/)
- [Docker tagging best practices](https://docs.docker.com/engine/reference/commandline/tag/)

---

**Õnnitleme! Oskad nüüd automatiseerida Docker image build'e! 🐳**
