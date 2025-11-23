# Peatükk 16: Docker Build Automation

**Kestus:** 3 tundi
**Eeldused:** Peatükk 15 (GitHub Actions Basics), Peatükk 5 (Dockerfile), Peatükk 8 (Docker Registry)
**Eesmärk:** Automatiseerida Docker image build, test, scan, ja push workflow CI/CD'is

---

## Õpieesmärgid

- Docker build GitHub Actions'is
- Multi-platform builds (buildx)
- Image tagging strategies (SHA, semantic versioning)
- Layer caching optimization
- Security scanning (Trivy)
- Build secrets management
- Push to registries (Docker Hub, private registry)

---

## 16.1 Manual vs Automated Builds

### Manual Workflow (❌ Aeglane, kordav)

```bash
# Developer workstation - iga deploy jaoks
cd backend-nodejs
docker build -t myorg/backend:1.0 .
docker tag myorg/backend:1.0 myorg/backend:latest
docker push myorg/backend:1.0
docker push myorg/backend:latest

# Deploy to production
ssh production
docker pull myorg/backend:1.0
docker stop backend
docker rm backend
docker run -d --name backend myorg/backend:1.0
```

**Probleemid:**
- ❌ Manual steps (unustame push'ida või tag'ida)
- ❌ Pole CI (tests ei jookse automaatselt)
- ❌ Pole security scan'i
- ❌ Aeganõudev (10-15 min per deploy)
- ❌ Inconsistent (different build environment each time)

---

### Automated Workflow (✅ Kiire, usaldusväärnväärne)

```
Git push → GitHub Actions → Workflow triggers:
  1. Checkout code
  2. Run linter (eslint)
  3. Run tests (npm test)
  4. Build Docker image
  5. Scan image (Trivy)
  6. Tag image (version, SHA, latest)
  7. Push to Docker Hub
  8. Deploy to staging (auto)
  9. Deploy to production (manual approval)

Time: 5-7 minutes (automated)
Consistency: Same build environment every time
Quality: Tests + security scan before push
```

**Benefits:**
- ✅ **Automated:** Git push → deploy (no manual steps)
- ✅ **Tested:** CI tests catch bugs before deploy
- ✅ **Secure:** Vulnerability scan before production
- ✅ **Fast:** Parallel jobs, cached layers
- ✅ **Traceable:** Every image tagged with Git SHA (rollback võimalus)

---

## 16.2 Basic Docker Build Workflow

### GitHub Actions Workflow - Simple Build

```yaml
# .github/workflows/docker-build.yml
name: Docker Build and Push

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      # 1. Checkout code
      - name: Checkout repository
        uses: actions/checkout@v4

      # 2. Login to Docker Hub
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      # 3. Build Docker image
      - name: Build image
        run: |
          docker build -t myorg/backend:latest .

      # 4. Push to Docker Hub
      - name: Push image
        run: |
          docker push myorg/backend:latest
```

**Setup secrets:**

```bash
# GitHub repository → Settings → Secrets → Actions
# Add:
DOCKER_USERNAME = myorg
DOCKER_PASSWORD = your-docker-hub-token  # NOT password! Use token
```

**Trigger:**

```bash
git add .
git commit -m "Add CI/CD workflow"
git push origin main

# GitHub Actions runs automatically!
```

---

## 16.3 Image Tagging Strategies

### ❌ BAD: Only `latest` Tag

```yaml
- name: Build and push
  run: |
    docker build -t myorg/backend:latest .
    docker push myorg/backend:latest
```

**Problems:**
- Pole versioning'ut (can't rollback to previous version)
- Breaking changes owerwrite'vad `latest` (production breaks!)
- Ei tea, milline versioon jookseb production'is

---

### ✅ GOOD: Multi-Tag Strategy

**1. Git SHA (commit hash):**

```yaml
- name: Build and tag with SHA
  run: |
    # Get short SHA
    SHA=$(git rev-parse --short HEAD)

    # Build and tag
    docker build -t myorg/backend:${SHA} .
    docker tag myorg/backend:${SHA} myorg/backend:latest

    # Push both tags
    docker push myorg/backend:${SHA}
    docker push myorg/backend:latest
```

**Benefit:** Every image traceable to Git commit

```bash
# Deployment
kubectl set image deployment/backend backend=myorg/backend:abc123

# Rollback (exact commit)
kubectl set image deployment/backend backend=myorg/backend:xyz789
```

---

**2. Semantic versioning (tag-based):**

```yaml
- name: Build with version tag
  run: |
    # Get version from Git tag (e.g., v1.2.3)
    VERSION=${GITHUB_REF#refs/tags/}

    docker build -t myorg/backend:${VERSION} .
    docker tag myorg/backend:${VERSION} myorg/backend:latest

    docker push myorg/backend:${VERSION}
    docker push myorg/backend:latest
```

**Trigger:**

```bash
# Create Git tag
git tag v1.2.3
git push origin v1.2.3

# GitHub Actions builds myorg/backend:v1.2.3
```

---

**3. Combined strategy (BEST):**

```yaml
- name: Build with multiple tags
  run: |
    SHA=$(git rev-parse --short HEAD)
    VERSION=${GITHUB_REF#refs/tags/}  # Only if tag exists

    # Always tag with SHA
    docker build -t myorg/backend:${SHA} .

    # Tag with version if Git tag exists
    if [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      docker tag myorg/backend:${SHA} myorg/backend:${VERSION}
      docker push myorg/backend:${VERSION}
    fi

    # Always tag latest
    docker tag myorg/backend:${SHA} myorg/backend:latest

    # Push SHA and latest
    docker push myorg/backend:${SHA}
    docker push myorg/backend:latest
```

**Result:**

```bash
# Push to main (no tag):
myorg/backend:abc123  (SHA)
myorg/backend:latest

# Push tag v1.2.3:
myorg/backend:abc123  (SHA)
myorg/backend:v1.2.3  (version)
myorg/backend:latest
```

---

## 16.4 Multi-Platform Builds (buildx)

### Problem: Architecture Mismatch

**Scenario:**

```
Developer workstation:
  - Build on MacBook (ARM64)
  - docker build → image for ARM64

Production server:
  - VPS (x86_64/AMD64)
  - docker run → ERROR: exec format error (wrong architecture!)
```

**Solution:** Build for multiple platforms

---

### Docker Buildx

**Buildx = Docker CLI plugin for multi-platform builds**

```bash
# Check buildx
docker buildx version

# Create builder (supports multi-platform)
docker buildx create --name multiplatform --use
docker buildx inspect --bootstrap
```

**Build for multiple platforms:**

```bash
# Build for AMD64 (x86_64) and ARM64
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myorg/backend:1.0 \
  --push \
  .

# Result: Single image manifest (contains both architectures)
# Docker automatically pulls correct version based on host architecture
```

---

### GitHub Actions - Multi-Platform Build

```yaml
name: Multi-Platform Build

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      # Setup QEMU (emulator for ARM builds on x86)
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      # Setup Buildx
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # Login
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      # Build and push (multi-platform)
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            myorg/backend:latest
            myorg/backend:${{ github.sha }}
```

**Supported platforms:**
- `linux/amd64` (most VPS, AWS, Azure)
- `linux/arm64` (AWS Graviton, Apple Silicon, Raspberry Pi)
- `linux/arm/v7` (older ARM devices)

---

## 16.5 Layer Caching Optimization

### Why Caching Matters

**Without caching:**

```
Build 1: 5 minutes (full build)
Build 2: 5 minutes (full build again - no cache!)
Build 3: 5 minutes
```

**With caching:**

```
Build 1: 5 minutes (full build)
Build 2: 1 minute (cached layers reused!)
Build 3: 30 seconds (only changed layer rebuilt)
```

**Savings:** 80-90% faster builds in CI

---

### GitHub Actions Cache

**docker/build-push-action with cache:**

```yaml
- name: Build and push with cache
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: myorg/backend:latest
    cache-from: type=registry,ref=myorg/backend:buildcache
    cache-to: type=registry,ref=myorg/backend:buildcache,mode=max
```

**How it works:**

```
First build:
  1. Build all layers
  2. Push image layers to registry
  3. Push cache metadata to myorg/backend:buildcache

Second build (no code changes):
  1. Pull cache from myorg/backend:buildcache
  2. Reuse cached layers (FAST!)
  3. Only rebuild changed layers

Second build (package.json changed):
  1. Pull cache
  2. Reuse base layers (FROM node:18)
  3. Rebuild npm install layer (package.json changed)
  4. Rebuild COPY layer
  5. Push new cache
```

---

### Dockerfile Optimization for Caching

**❌ BAD (cache-unfriendly):**

```dockerfile
FROM node:18-alpine
WORKDIR /app

# COPY everything first (cache invalidated on ANY file change!)
COPY . .

# Install dependencies (runs every time even if package.json unchanged)
RUN npm ci

CMD ["node", "src/index.js"]
```

**Problem:** Any source code change (e.g., README.md) invalidates npm cache!

---

**✅ GOOD (cache-friendly):**

```dockerfile
FROM node:18-alpine
WORKDIR /app

# COPY only package files first
COPY package*.json ./

# Install dependencies (cached if package.json unchanged)
RUN npm ci

# COPY source code AFTER dependencies
COPY . .

CMD ["node", "src/index.js"]
```

**Result:**

```
Code change (src/index.js):
  - Reuse node:18 base layer ✅
  - Reuse npm ci layer ✅ (package.json unchanged)
  - Rebuild COPY . layer (only this layer changes)

Time: 30 seconds (vs 3 minutes without cache)
```

---

## 16.6 Security Scanning with Trivy

### Why Scan Images?

**Problem:**

```
Your code: Secure ✅
Base image (node:18): Contains CVE-2023-12345 (Critical vulnerability) ❌

Result: Production server vulnerable to exploit!
```

**Solution:** Scan images before push to production

---

### Trivy Integration

**Trivy = Open-source vulnerability scanner (CNCF project)**

```yaml
name: Build, Scan, and Push

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      # Build image
      - name: Build image
        run: docker build -t myorg/backend:${{ github.sha }} .

      # Scan for vulnerabilities
      - name: Run Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myorg/backend:${{ github.sha }}
          format: 'table'
          exit-code: '1'  # Fail build if CRITICAL vulnerabilities
          severity: 'CRITICAL,HIGH'

      # Push only if scan passes
      - name: Login to Docker Hub
        if: success()  # Only if scan passed!
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Push image
        if: success()
        run: docker push myorg/backend:${{ github.sha }}
```

**Scan output (example):**

```
myorg/backend:abc123 (alpine 3.18)
Total: 15 (CRITICAL: 2, HIGH: 5, MEDIUM: 8)

┌───────────────┬────────────────┬──────────┬────────────────────┐
│   Library     │ Vulnerability  │ Severity │ Installed Version  │
├───────────────┼────────────────┼──────────┼────────────────────┤
│ openssl       │ CVE-2023-12345 │ CRITICAL │ 1.1.1q             │
│ curl          │ CVE-2023-67890 │ HIGH     │ 7.79.1             │
└───────────────┴────────────────┴──────────┴────────────────────┘

# Build fails (exit-code: 1) if CRITICAL found!
```

**Fix:**

```dockerfile
# Update base image to patched version
FROM node:18-alpine3.19  # Updated Alpine version (fixes CVE)
```

📖 **Praktika:** Labor 5, Harjutus 2 - Trivy security scanning

---

## 16.7 Build Secrets Management

### Problem: Secrets in Dockerfile

**❌ NEVER DO THIS:**

```dockerfile
FROM node:18-alpine

# ❌ HARDCODED SECRET (visible in image layers!)
ENV DB_PASSWORD=supersecret123

# ❌ SECRET in build arg (visible in docker history!)
ARG NPM_TOKEN=npm_abc123xyz
RUN echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc
```

**Consequence:**

```bash
# Anyone with image access can extract secrets!
docker history myorg/backend:1.0
# Shows: ARG NPM_TOKEN=npm_abc123xyz ⚠️
```

---

### ✅ Solution 1: Build Secrets (BuildKit)

**Dockerfile:**

```dockerfile
# syntax=docker/dockerfile:1
FROM node:18-alpine

WORKDIR /app

# Use secret at build time (NOT stored in layers!)
RUN --mount=type=secret,id=npm_token \
    echo "//registry.npmjs.org/:_authToken=$(cat /run/secrets/npm_token)" > ~/.npmrc && \
    npm ci && \
    rm ~/.npmrc  # Remove after use
```

**GitHub Actions:**

```yaml
- name: Build with secrets
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: myorg/backend:latest
    secrets: |
      npm_token=${{ secrets.NPM_TOKEN }}
```

**Result:** Secret used during build, NOT stored in image layers!

---

### ✅ Solution 2: Runtime Secrets (Kubernetes)

```dockerfile
# Don't include secrets in image at all!
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci  # No secrets needed (public packages)
COPY . .
CMD ["node", "src/index.js"]
```

**Secrets injected at runtime:**

```yaml
# Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: backend
        image: myorg/backend:1.0
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: backend-secrets
              key: db-password  # Injected at runtime!
```

---

## 16.8 Complete CI/CD Pipeline

### Production-Ready Workflow

```yaml
# .github/workflows/docker-cicd.yml
name: CI/CD - Build, Test, Scan, Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: docker.io
  IMAGE_NAME: myorg/backend

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test

  build-and-scan:
    needs: test  # Only if tests pass
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,suffix=,format=short
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=registry,ref=${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.IMAGE_NAME }}:buildcache,mode=max

      - name: Run Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  deploy-staging:
    needs: build-and-scan  # Only if build and scan pass
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to staging
        run: |
          # Deploy logic (kubectl, SSH, etc.)
          echo "Deploying ${{ github.sha }} to staging"

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production  # Requires manual approval
    steps:
      - name: Deploy to production
        run: |
          echo "Deploying ${{ github.sha }} to production"
```

**Workflow:**

```
Git push → main branch
  ↓
1. Test job:
   - Lint code
   - Run unit tests
   ✅ Pass → continue
  ↓
2. Build and scan job:
   - Build multi-platform image
   - Tag with SHA, branch, version
   - Push to Docker Hub
   - Scan with Trivy
   ✅ No critical vulnerabilities → continue
  ↓
3. Deploy staging:
   - Auto-deploy to staging environment
   ✅ Staging healthy → continue
  ↓
4. Deploy production:
   - Wait for manual approval (GitHub Environments)
   - Deploy to production
```

📖 **Praktika:** Labor 5, Harjutus 3 - Complete CI/CD pipeline

---

## Kokkuvõte

**Docker Build Automation:**
- **Automated workflow:** Git push → build → test → scan → push → deploy
- **Tagging strategies:** SHA (traceability) + semantic versioning + latest
- **Multi-platform:** buildx (AMD64 + ARM64 support)
- **Layer caching:** 80-90% faster builds (registry cache)
- **Security scanning:** Trivy (CRITICAL/HIGH vulnerabilities)
- **Secrets management:** Build secrets (--mount=type=secret), runtime secrets (K8s)

**GitHub Actions tools:**
- `docker/setup-buildx-action` - Multi-platform support
- `docker/login-action` - Registry authentication
- `docker/build-push-action` - Build and push with caching
- `docker/metadata-action` - Smart tagging (SHA, version, branch)
- `aquasecurity/trivy-action` - Vulnerability scanning

**Best practices:**
- ✅ Always tag with Git SHA (traceability)
- ✅ Scan before push (Trivy exit-code: 1)
- ✅ Cache layers (registry cache)
- ✅ Multi-platform builds (AMD64 + ARM64)
- ✅ Never hardcode secrets (use build secrets or runtime secrets)
- ✅ Lint and test before build
- ❌ Never push without scanning
- ❌ Never use :latest in production deployments

---

**DevOps Vaatenurk:**

```bash
# Local testing (before committing)
docker build -t myapp:test .
trivy image myapp:test

# CI/CD handles automatically:
# - Build
# - Tag (SHA, version, latest)
# - Scan (Trivy)
# - Push (Docker Hub)
# - Deploy (staging → production)

# Check GitHub Actions logs
gh run list
gh run view <run-id>

# Manual build with buildx (multi-platform)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myorg/backend:1.0 \
  --push \
  .
```

---

**Järgmised Sammud:**
**Peatükk 17:** Kubernetes Deployment Automation
**Peatükk 18:** Prometheus ja Metrics (monitoring)

📖 **Praktika:** Labor 5 - Docker Build Automation, Security Scanning, Multi-Platform Builds
