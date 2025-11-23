# Peatükk 15: GitHub Actions Basics

**Kestus:** 3 tundi
**Eeldused:** Peatükk 3 (Git), Peatükk 4-7 (Docker)
**Eesmärk:** Automatiseerida build, test, ja deploy workflow GitHub Actions'iga

---

## Õpieesmärgid

Selle peatüki lõpuks oskad:
- Mõista CI/CD põhimõtteid ja GitHub Actions arhitektuuri
- Kirjutada workflow YAML faile
- Seadistada triggers (push, pull_request, schedule)
- Kasutada GitHub-hosted runners
- Hallata secrets ja environment variables
- Luua multi-job workflows

---

## 15.1 Miks CI/CD?

### Probleem: Manual Deployment

**Traditional workflow:**

```
Developer:
1. Write code
2. Test locally (maybe...)
3. Build Docker image manually
4. Push image to registry
5. SSH to server
6. docker pull new image
7. docker stop old container
8. docker run new container
9. Hope everything works...

Problems:
- Manual steps → error-prone
- Inconsistent (different developers do it differently)
- No testing before deploy
- Slow (30 minutes per deploy)
- No rollback strategy
- Works on my machine™
```

---

### Solution: CI/CD Pipeline

**Continuous Integration (CI):**
> Automatically build and test code on every commit

**Continuous Deployment (CD):**
> Automatically deploy tested code to production

**GitHub Actions workflow:**

```
1. Developer: git push
   ↓
2. GitHub Actions (automatic):
   - Checkout code
   - Run linter (code quality)
   - Run tests
   - Build Docker image
   - Push to Docker Hub
   - Deploy to Kubernetes
   ↓
3. Production updated (5 minutes, zero human intervention)
```

**DevOps benefits:**
- ✅ Consistency (same process every time)
- ✅ Speed (automated → 10x faster)
- ✅ Quality (tests always run)
- ✅ Confidence (if tests pass, deploy is safe)
- ✅ Audit trail (all deployments logged)

---

## 15.2 GitHub Actions Architecture

### Components

**Workflow:**
- YAML file in `.github/workflows/`
- Defines automation (build, test, deploy)

**Trigger (Event):**
- What starts workflow (push, pull_request, schedule)

**Job:**
- Set of steps running on a runner
- Multiple jobs can run in parallel

**Step:**
- Individual task (checkout code, run command, use action)

**Runner:**
- Machine that executes workflow
- GitHub-hosted (free minutes) or self-hosted

**Action:**
- Reusable task (checkout code, setup Node.js, deploy to K8s)

---

### Architecture Diagram

```
GitHub Repository:
  .github/workflows/ci.yml

Trigger: git push
  ↓
GitHub Actions Service:
  → Allocate runner (Ubuntu VM)
  → Checkout code
  → Execute jobs

Runner (GitHub-hosted):
  - Ubuntu 22.04
  - 2 CPU cores
  - 7 GB RAM
  - 14 GB SSD

Jobs execute:
  → Build Docker image
  → Run tests
  → Push to registry
  → Deploy to Kubernetes

Result:
  → Success ✅ or Failure ❌
  → Notification (email, Slack)
```

---

## 15.3 Workflow YAML Structure

### Minimal Workflow

```yaml
# .github/workflows/hello.yml
name: Hello World

on: [push]  # Trigger

jobs:
  greet:
    runs-on: ubuntu-latest
    steps:
    - name: Say hello
      run: echo "Hello, World!"
```

**What happens:**

```
1. Push to any branch
2. GitHub Actions starts workflow
3. Allocate ubuntu-latest runner
4. Run command: echo "Hello, World!"
5. Log output visible in GitHub UI
```

---

### Workflow Syntax Breakdown

**name:** Workflow display name

```yaml
name: CI Pipeline
```

**on:** Triggers (events)

```yaml
# Single trigger
on: push

# Multiple triggers
on: [push, pull_request]

# Specific branches
on:
  push:
    branches:
      - main
      - develop

# Specific paths
on:
  push:
    paths:
      - 'src/**'
      - 'Dockerfile'

# Scheduled (cron)
on:
  schedule:
    - cron: '0 2 * * *'  # Daily 02:00 UTC
```

**jobs:** Define jobs

```yaml
jobs:
  build:  # Job ID
    runs-on: ubuntu-latest  # Runner
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run build
        run: npm run build
```

**runs-on:** Runner type

```yaml
runs-on: ubuntu-latest  # Ubuntu 22.04
runs-on: ubuntu-20.04   # Specific version
runs-on: windows-latest
runs-on: macos-latest
```

**steps:** Tasks in job

```yaml
steps:
  - name: Step description
    uses: actions/checkout@v4  # Use pre-built action

  - name: Run command
    run: echo "Hello"  # Shell command

  - name: Multi-line command
    run: |
      npm install
      npm test
```

📖 **Praktika:** Labor 5, Harjutus 1 - First GitHub Actions workflow

---

## 15.4 Common Triggers

### Push Trigger

```yaml
on:
  push:
    branches:
      - main
      - 'release/**'  # release/v1.0, release/v2.0
    tags:
      - 'v*'  # v1.0.0, v2.1.3
```

**Use case:** Deploy to production on push to main

---

### Pull Request Trigger

```yaml
on:
  pull_request:
    branches:
      - main
    types:
      - opened
      - synchronize  # New commits pushed to PR
```

**Use case:** Run tests before merge

---

### Manual Trigger (workflow_dispatch)

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - staging
          - production
```

**Use case:** Manual production deploys (button in GitHub UI)

---

### Scheduled Trigger

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily 02:00 UTC
    - cron: '0 */6 * * *'  # Every 6 hours
```

**Use case:** Nightly builds, automated backups, security scans

---

## 15.5 Steps and Actions

### Checkout Code

**Always first step:**

```yaml
steps:
  - name: Checkout repository
    uses: actions/checkout@v4
```

**What it does:**
- Clones Git repository to runner
- Checks out commit that triggered workflow

---

### Run Shell Commands

```yaml
steps:
  - name: Install dependencies
    run: npm install

  - name: Run tests
    run: npm test

  - name: Multi-line script
    run: |
      echo "Building application..."
      npm run build
      echo "Build complete!"
```

---

### Use Pre-built Actions

**Setup Node.js:**

```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '18'
```

**Setup Docker Buildx:**

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
```

**Login to Docker Hub:**

```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

**GitHub Actions Marketplace:**
- https://github.com/marketplace?type=actions
- 20,000+ pre-built actions

---

## 15.6 Environment Variables and Secrets

### Environment Variables

**Workflow-level:**

```yaml
env:
  NODE_ENV: production
  APP_VERSION: 1.2.3

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Version $APP_VERSION"
```

**Job-level:**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    env:
      BUILD_ENV: production
    steps:
      - run: npm run build
```

**Step-level:**

```yaml
steps:
  - name: Deploy
    env:
      DEPLOY_ENV: production
    run: ./deploy.sh
```

---

### Secrets Management

**Create secret in GitHub:**

```
Repository → Settings → Secrets and variables → Actions
→ New repository secret

Name: DOCKER_PASSWORD
Value: super-secret-docker-hub-password
```

**Use secret in workflow:**

```yaml
steps:
  - name: Login to Docker Hub
    uses: docker/login-action@v3
    with:
      username: ${{ secrets.DOCKER_USERNAME }}
      password: ${{ secrets.DOCKER_PASSWORD }}
```

**Secrets security:**
- Never logged in output (masked as ***)
- Not accessible in forked repositories (security)
- Encrypted at rest

**Default secrets:**

```yaml
steps:
  - name: Checkout with token
    uses: actions/checkout@v4
    with:
      token: ${{ secrets.GITHUB_TOKEN }}  # Auto-provided
```

---

### Context Variables

**GitHub context:**

```yaml
steps:
  - run: echo "Repository: ${{ github.repository }}"
  - run: echo "Branch: ${{ github.ref_name }}"
  - run: echo "SHA: ${{ github.sha }}"
  - run: echo "Actor: ${{ github.actor }}"
```

**Runner context:**

```yaml
steps:
  - run: echo "OS: ${{ runner.os }}"
  - run: echo "Arch: ${{ runner.arch }}"
```

📖 **Praktika:** Labor 5, Harjutus 2 - Secrets management

---

## 15.7 Multi-Job Workflows

### Parallel Jobs

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run lint

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit
```

**Execution:**

```
test          lint          security-scan
  ↓             ↓                ↓
Parallel execution (fastest!)
```

---

### Sequential Jobs (dependencies)

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run build

  test:
    needs: build  # Wait for build
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  deploy:
    needs: [build, test]  # Wait for both
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

**Execution:**

```
build
  ↓
test
  ↓
deploy
```

---

### Matrix Strategy (test multiple versions)

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16, 18, 20]
        os: [ubuntu-latest, windows-latest]

    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
      - run: npm test
```

**Execution:**

```
6 jobs in parallel:
- Node 16 + Ubuntu
- Node 16 + Windows
- Node 18 + Ubuntu
- Node 18 + Windows
- Node 20 + Ubuntu
- Node 20 + Windows
```

**Use case:** Test compatibility across versions

---

## 15.8 Docker Build Automation

### Basic Docker Build and Push

```yaml
name: Docker Build

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: |
            myusername/backend:latest
            myusername/backend:${{ github.sha }}
```

**What happens:**

```
1. Checkout code
2. Setup Docker Buildx (builder)
3. Login to Docker Hub
4. Build image
5. Tag: latest + commit SHA
6. Push to Docker Hub

Result:
- myusername/backend:latest
- myusername/backend:abc1234567
```

---

### Multi-Platform Builds

```yaml
- name: Build multi-platform
  uses: docker/build-push-action@v5
  with:
    context: .
    platforms: linux/amd64,linux/arm64
    push: true
    tags: myusername/backend:latest
```

**Builds for:**
- AMD64 (Intel/AMD servers)
- ARM64 (Apple Silicon, AWS Graviton)

---

### Cache Optimization

```yaml
- name: Build with cache
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: myusername/backend:latest
    cache-from: type=registry,ref=myusername/backend:cache
    cache-to: type=registry,ref=myusername/backend:cache,mode=max
```

**Benefit:** 10x faster builds (reuse layers)

📖 **Praktika:** Labor 5, Harjutus 3 - Automated Docker builds

---

## 15.9 Practical CI/CD Pipeline

### Complete Example - Backend API

```yaml
name: Backend CI/CD

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

env:
  DOCKER_IMAGE: myorg/backend-api
  NODE_VERSION: '18'

jobs:
  # Job 1: Lint and Test
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run tests
        run: npm test

      - name: Generate coverage report
        run: npm run test:coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/coverage-final.json

  # Job 2: Build Docker Image
  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push'  # Only on push, not PR

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

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
          images: ${{ env.DOCKER_IMAGE }}
          tags: |
            type=ref,event=branch
            type=sha,prefix={{branch}}-

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile.prod
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.DOCKER_IMAGE }}:cache
          cache-to: type=registry,ref=${{ env.DOCKER_IMAGE }}:cache,mode=max

  # Job 3: Security Scan
  security:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.DOCKER_IMAGE }}:main-${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

**Pipeline flow:**

```
git push to main
  ↓
1. Test job (parallel):
   - Lint
   - Unit tests
   - Coverage report

2. Build job (after test passes):
   - Build Docker image
   - Tag: main-abc1234
   - Push to Docker Hub

3. Security job (after build):
   - Scan image for vulnerabilities
   - Upload results to GitHub
```

---

## 15.10 Best Practices

### 1. Fail Fast

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm run lint  # Fast check first
      - run: npm test      # Slower tests second
```

**Benefit:** If lint fails (30s), don't waste time on tests (5min)

---

### 2. Cache Dependencies

```yaml
- name: Setup Node.js with cache
  uses: actions/setup-node@v4
  with:
    node-version: '18'
    cache: 'npm'  # Cache node_modules

- name: Install dependencies
  run: npm ci  # Faster than npm install
```

**Speed improvement:** 5min → 30s

---

### 3. Use Specific Action Versions

```yaml
# ❌ BAD (unstable)
uses: actions/checkout@main

# ✅ GOOD (stable)
uses: actions/checkout@v4
```

---

### 4. Separate Workflows

```
.github/workflows/
  ├── ci.yml          # Test, lint (on PR)
  ├── build.yml       # Build, push (on push to main)
  ├── deploy.yml      # Deploy (on release tag)
  └── security.yml    # Security scan (nightly)
```

**Benefit:** Faster feedback, clearer separation

---

### 5. Use Environments for Secrets

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Environment-specific secrets

    steps:
      - name: Deploy
        env:
          KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
        run: kubectl apply -f deployment.yaml
```

---

### 6. Timeout Jobs

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 10  # Kill after 10 minutes

    steps:
      - run: npm test
```

**Prevent:** Hanging jobs consuming runner minutes

---

## 15.11 GitHub-Hosted vs Self-Hosted Runners

### GitHub-Hosted Runners

**Specs:**
- Ubuntu, Windows, macOS
- 2 CPU cores, 7 GB RAM, 14 GB SSD
- Fresh VM every job (clean state)

**Free tier:**
- 2,000 minutes/month (public repos: unlimited)
- After limit: $0.008/minute

**Pros:**
- ✅ Zero maintenance
- ✅ Fast startup
- ✅ Clean environment

**Cons:**
- ❌ Limited resources (2 cores)
- ❌ No GPU, no custom hardware
- ❌ Cost after free tier

---

### Self-Hosted Runners

**Setup:**

```bash
# On your VPS/server
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz
./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO --token YOUR_TOKEN
./run.sh
```

**Use in workflow:**

```yaml
jobs:
  build:
    runs-on: self-hosted  # Use self-hosted runner
    steps:
      - uses: actions/checkout@v4
      - run: npm run build
```

**Pros:**
- ✅ Unlimited minutes (free)
- ✅ Custom hardware (GPU, more CPU/RAM)
- ✅ Access to internal network

**Cons:**
- ❌ Maintenance (OS updates, security)
- ❌ Not isolated (persistent state between jobs)
- ❌ Security risk (malicious code access to server)

**Production recommendation:** GitHub-hosted for security, self-hosted for cost/performance

---

## 15.12 Alternatiivid: GitLab CI ja Bamboo

### Miks võrrelda?

**DevOps reaalsus:**
> "GitHub Actions on hea, aga organisatsioon võib kasutada GitLab'i või Bamboo'd. DevOps administraator PEAB mõistma erinevusi."

**Kolm peamist CI/CD platvormi:**
1. **GitHub Actions** - GitHub'i native, populaarne open-source projektidele
2. **GitLab CI/CD** - GitLab'i native, enterprise favorite
3. **Bamboo** - Atlassian (Jira integreer), enterprise legacy

---

### GitLab CI/CD

#### Arhitektuur

**GitLab CI = GitLab integree**ritud CI/CD**

```
GitLab Repository:
  .gitlab-ci.yml (root kataloogis)

GitLab Runner:
  - Self-hosted (peamine variant)
  - GitLab SaaS shared runners (piiratud)

Pipeline:
  → Stages (build, test, deploy)
  → Jobs (paralleelsed või sequential)
```

**Võtmeerinevus GitHub Actions'iga:**
- GitHub: Jobs grupeeritakse workflow's
- GitLab: Jobs grupeeritakse **stages'tes**

---

#### GitLab CI YAML Näide

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_IMAGE: myorg/backend

# Build job
build-job:
  stage: build
  image: docker:latest
  services:
    - docker:dind  # Docker-in-Docker
  script:
    - docker build -t $DOCKER_IMAGE:$CI_COMMIT_SHA .
    - docker push $DOCKER_IMAGE:$CI_COMMIT_SHA
  only:
    - main

# Test job
test-job:
  stage: test
  image: node:18
  script:
    - npm ci
    - npm test
  coverage: '/Coverage: \d+\.\d+/'

# Deploy job
deploy-job:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl apply -f k8s/deployment.yaml
  environment:
    name: production
    url: https://api.example.com
  when: manual  # Manual trigger
  only:
    - main
```

**Syntax võrdlus:**

| Aspect | GitHub Actions | GitLab CI |
|--------|----------------|-----------|
| Config file | `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| Trigger | `on: push` | `only: [main]` |
| Runner | `runs-on: ubuntu-latest` | `image: node:18` |
| Steps | `steps: - run:` | `script: -` |
| Secrets | `${{ secrets.NAME }}` | `$CI_JOB_TOKEN` (auto) |

---

#### GitLab Runners

**Self-hosted (peamine):**

```bash
# Install GitLab Runner on VPS
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner

# Register runner
sudo gitlab-runner register \
  --url https://gitlab.com/ \
  --registration-token YOUR_TOKEN \
  --executor docker \
  --docker-image alpine:latest
```

**Shared runners (GitLab SaaS):**
- Free tier: 400 minutes/month
- Paid: $10/month for 1,000 minutes

**Executor types:**
- **docker:** Konteinerites (soovitatud)
- **shell:** Otse host'is
- **kubernetes:** K8s Pod'ides

---

#### GitLab CI Eelised

**✅ Plussid:**

1. **Built-in Docker Registry:**
   ```yaml
   # Push image GitLab Registry'sse (auto-auth)
   script:
     - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
     - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
   ```

2. **Auto DevOps:**
   - Zero-config CI/CD (auto-detects language)
   - Auto build, test, security scan, deploy to K8s

3. **Merge Request Pipelines:**
   - CI runs ONLY on merge request (säästab runner minutes)

4. **DAG (Directed Acyclic Graph):**
   ```yaml
   # Complex dependencies
   deploy:
     needs:
       - build:frontend
       - build:backend
       - test:integration
   ```

5. **Child/Parent Pipelines:**
   - Trigger pipeline from another pipeline
   - Monorepo support (frontend/, backend/ separate pipelines)

**❌ Miinused:**

- Self-hosted runners required (SaaS free tier väike)
- Steeper learning curve (rohkem features = keerulisem)
- GitLab instance maintenance (if self-hosted GitLab)

---

### Bamboo (Atlassian)

#### Arhitektuur

**Bamboo = Standalone CI/CD server**

```
Bamboo Server:
  - Java application
  - Web UI (config via UI, not YAML!)
  - Integration: Jira, Bitbucket, Confluence

Bamboo Agent:
  - Self-hosted (Java agent)
  - Executes builds

Plan:
  → Stages
  → Jobs
  → Tasks
```

**Võtmeerinevus:**
- GitHub Actions/GitLab: **Configuration as Code** (YAML Git'is)
- Bamboo: **UI-based configuration** (clicks, not code!)

---

#### Bamboo Configuration

**No YAML!** Config via Web UI:

```
1. Create Plan (e.g., "Backend Build")
2. Add Stage (e.g., "Build")
3. Add Job (e.g., "Compile")
4. Add Tasks:
   - Source Code Checkout (Git)
   - Script: npm install
   - Script: npm run build
   - Docker: docker build -t backend:${bamboo.buildNumber}
5. Add Deployment Project
   - Environment: Production
   - Tasks: kubectl apply -f deployment.yaml
```

**Bamboo Specs (modern approach):**

```java
// bamboo-specs/bamboo.yaml (Java-based!)
---
version: 2
plan:
  project-key: PROJ
  key: BUILD
  name: Backend Build Plan

stages:
  - Build:
      jobs:
        - Compile:
            tasks:
              - checkout
              - script: npm install
              - script: npm test
```

**Hybrid:** Java/YAML specs stored in Git, but less popular

---

#### Bamboo Eelised

**✅ Plussid:**

1. **Jira Integration:**
   - Automatic issue linking (commit → Jira ticket)
   - Build status in Jira issues
   - Deployment tracking per release

2. **Bitbucket Integration:**
   - Branch detection (auto-create plans)
   - Pull request builds

3. **Mature Deployment Projects:**
   - Multi-environment (dev, staging, prod)
   - Manual approvals (click button to deploy)
   - Rollback support

4. **Build artifacts:**
   - Store build outputs (JARs, Docker images)
   - Artifact sharing between plans

5. **Enterprise features:**
   - Advanced permissions (Jira users/groups)
   - Audit logging
   - Compliance reports

**❌ Miinused:**

- **Expensive:** $1,200/year for 25 agents (vs GitHub Actions free tier)
- **UI-based config:** Ei ole Infrastructure as Code (hard to version)
- **Heavy:** Java server (2GB RAM minimum)
- **Vendor lock-in:** Atlassian ecosystem (Jira, Bitbucket, Confluence)
- **Legacy:** Vähem modern kui GitHub Actions/GitLab CI

---

### Võrdlus: GitHub Actions vs GitLab CI vs Bamboo

| Kriteerium | GitHub Actions | GitLab CI | Bamboo |
|------------|----------------|-----------|---------|
| **Hind** | Free (2,000 min/month) | Free (400 min/month) | $1,200/year |
| **Config** | YAML (`.github/workflows/`) | YAML (`.gitlab-ci.yml`) | UI + specs (Java/YAML) |
| **Runners** | GitHub-hosted + self-hosted | Self-hosted (peamine) | Self-hosted only |
| **IaC** | ✅ YAML Git'is | ✅ YAML Git'is | ❌ UI-based (specs optional) |
| **Docker support** | ✅ Native | ✅ Docker-in-Docker | ✅ Docker tasks |
| **K8s integration** | Marketplace actions | Built-in (Auto DevOps) | Marketplace plugins |
| **Secrets** | GitHub Secrets | GitLab Variables | Bamboo Variables |
| **Parallelism** | Jobs | Jobs in stages | Jobs in stages |
| **Matrix builds** | ✅ | ✅ | ❌ (manual duplication) |
| **Marketplace** | 20,000+ actions | Auto DevOps templates | ~1,000 plugins |
| **Learning curve** | Easy | Medium | Hard (UI + concepts) |
| **Best for** | GitHub repos, OSS | GitLab repos, Enterprise | Atlassian stack (Jira) |

---

### Valiku Juhised

**Vali GitHub Actions kui:**
- ✅ Kasutad GitHub'i
- ✅ Open-source projekt
- ✅ Vajad Marketplace actions'e
- ✅ Budget-conscious (free tier suur)

**Vali GitLab CI kui:**
- ✅ Kasutad GitLab'i
- ✅ Vajad built-in Docker Registry't
- ✅ Enterprise (self-hosted GitLab)
- ✅ Keeruline pipeline logic (DAG, parent/child)

**Vali Bamboo kui:**
- ✅ Kasutad juba Jira + Bitbucket
- ✅ Enterprise (audit, compliance)
- ✅ Deployment projects (multi-env management)
- ❌ **EI SOOVITA uutele projektidele** (legacy, kallis)

---

### Migratsioon GitHub Actions → GitLab CI

**GitHub Actions:**
```yaml
name: CI
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test
```

**GitLab CI ekvivalent:**
```yaml
stages:
  - test

test-job:
  stage: test
  image: node:18
  script:
    - npm test
```

**Migration tools:**
- GitLab CI/CD migration guide
- Manual conversion (syntax different)

---

### Praktiline Soovitus

**DevOps administraator peaks:**

1. **Põhjalikult teadma ühte:**
   - GitHub Actions (kui GitHub org)
   - GitLab CI (kui GitLab org)

2. **Põhimõisteid teadma kõigist:**
   - Pipeline, stage, job, step/task
   - Runners/agents
   - Secrets management
   - Docker integration

3. **Vältima Bamboo'd uutele projektidele:**
   - Kallis, legacy
   - Modern alternatiivid (GitHub Actions, GitLab CI, Jenkins) paremad

**Trend 2025:**
- GitHub Actions: kasvab (populaarsus, OSS)
- GitLab CI: stabiilne (enterprise)
- Bamboo: väheneb (legacy, Atlassian ei investeeri)

---

## Kokkuvõte

### Mida sa õppisid?

**CI/CD fundamentals:**
- Continuous Integration (automatic build + test)
- Continuous Deployment (automatic deploy)
- GitHub Actions = CI/CD platform

**Workflow syntax:**
- YAML in `.github/workflows/`
- Triggers: push, pull_request, schedule, workflow_dispatch
- Jobs: parallel or sequential
- Steps: actions or shell commands

**Common patterns:**
- Checkout code: `actions/checkout@v4`
- Setup environments: `setup-node`, `setup-python`
- Docker build: `docker/build-push-action`
- Secrets: `${{ secrets.SECRET_NAME }}`

**Best practices:**
- Cache dependencies (faster builds)
- Fail fast (lint before tests)
- Specific action versions (@v4, not @main)
- Timeout jobs (prevent hangs)

---

### DevOps Administraatori Vaatenurk

**Iga päev:**
```
git push → Automatic workflow starts
→ View logs in GitHub Actions tab
→ Fix failures
```

**Workflow debugging:**
```yaml
- name: Debug info
  run: |
    echo "Event: ${{ github.event_name }}"
    echo "Branch: ${{ github.ref_name }}"
    env  # Print all env vars
```

**Monitor:**
- Workflow success rate
- Build times (optimize slow steps)
- Runner usage (cost)

---

### Järgmised Sammud

**Peatükk 16:** Docker Build Automation (advanced CI/CD)
**Peatükk 17:** Kubernetes Deployment Automation (GitOps)

---

**Kestus kokku:** ~3 tundi teooriat + praktilised harjutused labides

📖 **Praktika:** Labor 5, Harjutused 1-3 - GitHub Actions CI/CD pipelines
