# Peatükk 20: GitHub Actions CI/CD 🚀

**Kestus:** 5 tundi
**Eeldused:** Peatükk 19 läbitud, rakendus K8s-es deployitud
**Eesmärk:** Automatiseerida testing, build ja deployment GitHub Actions-iga

---

## Sisukord

1. [Ülevaade](#1-ülevaade)
2. [GitHub Actions Põhimõtted](#2-github-actions-põhimõtted)
3. [CI Workflow - Testing](#3-ci-workflow---testing)
4. [CD Workflow - Build ja Push](#4-cd-workflow---build-ja-push)
5. [Kubernetes Deployment Automation](#5-kubernetes-deployment-automation)
6. [Multi-Environment Setup](#6-multi-environment-setup)
7. [Secrets ja Environment Variables](#7-secrets-ja-environment-variables)
8. [Advanced Workflows](#8-advanced-workflows)
9. [Best Practices](#9-best-practices)
10. [Harjutused](#10-harjutused)

---

## 1. Ülevaade

### 1.1. CI/CD Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    DEVELOPER WORKFLOW                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ git push
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    GITHUB REPOSITORY                         │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              .github/workflows/                        │ │
│  │              - ci.yml                                  │ │
│  │              - cd.yml                                  │ │
│  │              - deploy.yml                              │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────┬───────────────────────────────────────┘
                       │ Trigger on push/PR
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                 GITHUB ACTIONS RUNNER                        │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   CI JOBS    │  │   CD JOBS    │  │ DEPLOY JOBS  │      │
│  │              │  │              │  │              │      │
│  │ - Lint       │  │ - Build img  │  │ - kubectl    │      │
│  │ - Test       │  │ - Push img   │  │ - Update K8s │      │
│  │ - Security   │  │ - Scan img   │  │ - Verify     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└──────────────────────┬───────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              DOCKER REGISTRY + KUBERNETES                    │
│                                                              │
│  Registry (localhost:5000)    VPS kirjakast (K3s)           │
│  - backend:v1.2.3             - Deployment updated          │
│  - frontend:v1.2.3            - Rolling update              │
│                                - Zero downtime              │
└─────────────────────────────────────────────────────────────┘
```

### 1.2. Workflow Tüübid

**CI (Continuous Integration):**
- **Triggers:** Iga push, pull request
- **Jobs:** Lint, test, security scan
- **Eesmärk:** Valideerida koodi kvaliteet

**CD (Continuous Delivery):**
- **Triggers:** Push main branch-i
- **Jobs:** Build Docker image, push registry-sse
- **Eesmärk:** Valmistada deployment artifact

**Deploy (Continuous Deployment):**
- **Triggers:** Peale CD edukat lõpetamist
- **Jobs:** Update Kubernetes Deployment
- **Eesmärk:** Automaatne deployment produktsiooni

---

## 2. GitHub Actions Põhimõtted

### 2.1. Workflow Struktuur

**Fail:** `.github/workflows/example.yml`

```yaml
name: Example Workflow         # Workflow nimi

on:                            # Triggers (millal käivitub)
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:                           # Globaalsed environment variables
  NODE_VERSION: '18'

jobs:                          # Jobs (paralleelsed)
  build:                       # Job ID
    name: Build Application    # Job nimi (kuvatakse UI-s)
    runs-on: ubuntu-latest     # Runner OS

    steps:                     # Steps (järjestikused)
    - name: Checkout code      # Step nimi
      uses: actions/checkout@v4 # Kasuta eelnevat action-it

    - name: Run tests
      run: npm test            # Käsk mis käivitatakse

    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: build-output
        path: dist/
```

### 2.2. Triggers (on)

**Push:**
```yaml
on:
  push:
    branches:
      - main
      - develop
    paths:
      - 'src/**'
      - 'package.json'
```

**Pull Request:**
```yaml
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
```

**Schedule (Cron):**
```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Iga päev kell 2:00 UTC
```

**Manual (Workflow Dispatch):**
```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'staging'
        type: choice
        options:
          - dev
          - staging
          - production
```

### 2.3. Jobs ja Steps

**Paralleelsed jobs:**
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test

  # lint ja test käivituvad paralleelselt
```

**Järjestikused jobs (dependencies):**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build

  deploy:
    needs: build              # Oota build lõpetamist
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

---

## 3. CI Workflow - Testing

### 3.1. Backend CI Workflow

**Fail:** `.github/workflows/backend-ci.yml`

```yaml
name: Backend CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'labs/apps/backend-nodejs/**'
      - '.github/workflows/backend-ci.yml'
  pull_request:
    branches: [main]
    paths:
      - 'labs/apps/backend-nodejs/**'

env:
  NODE_VERSION: '18'

jobs:
  lint:
    name: Lint Backend Code
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: labs/apps/backend-nodejs

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'
        cache-dependency-path: labs/apps/backend-nodejs/package-lock.json

    - name: Install dependencies
      run: npm ci

    - name: Run ESLint
      run: npm run lint
      continue-on-error: false  # Fail kui lint errors

  test:
    name: Run Backend Tests
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: labs/apps/backend-nodejs

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}
        cache: 'npm'
        cache-dependency-path: labs/apps/backend-nodejs/package-lock.json

    - name: Install dependencies
      run: npm ci

    - name: Run tests
      env:
        DB_HOST: localhost
        DB_PORT: 5432
        DB_NAME: testdb
        DB_USER: testuser
        DB_PASSWORD: testpass
        JWT_SECRET: test-secret-key-for-ci
        NODE_ENV: test
      run: npm test

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      if: always()
      with:
        files: ./labs/apps/backend-nodejs/coverage/lcov.info
        flags: backend

  security:
    name: Security Audit
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: labs/apps/backend-nodejs

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ env.NODE_VERSION }}

    - name: Run npm audit
      run: npm audit --audit-level=moderate
      continue-on-error: true  # Warning, not failure

    - name: Check for known vulnerabilities
      run: npm audit --audit-level=high
```

### 3.2. Frontend CI Workflow

**Fail:** `.github/workflows/frontend-ci.yml`

```yaml
name: Frontend CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'labs/apps/frontend/**'
      - '.github/workflows/frontend-ci.yml'
  pull_request:
    branches: [main]
    paths:
      - 'labs/apps/frontend/**'

jobs:
  lint:
    name: Lint Frontend Code
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Run HTML validation
      uses: Cyb3r-Jak3/html5validator-action@v7.2.0
      with:
        root: labs/apps/frontend/

    - name: Run CSS Lint
      run: |
        cd labs/apps/frontend
        npx stylelint "css/**/*.css"
      continue-on-error: true

  build:
    name: Build Frontend Image
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Build Docker image
      run: |
        cd labs/apps/frontend
        docker build -t frontend:test .

    - name: Test image
      run: |
        docker run -d --name frontend-test -p 8080:80 frontend:test
        sleep 5
        curl -f http://localhost:8080/health || exit 1
        docker stop frontend-test
        docker rm frontend-test
```

---

## 4. CD Workflow - Build ja Push

### 4.1. Backend CD Workflow

**Fail:** `.github/workflows/backend-cd.yml`

```yaml
name: Backend CD

on:
  push:
    branches: [main]
    paths:
      - 'labs/apps/backend-nodejs/**'
  workflow_dispatch:  # Manual trigger

env:
  REGISTRY: localhost:5000
  IMAGE_NAME: backend
  NODE_VERSION: '18'

jobs:
  build-and-push:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest

    outputs:
      image-tag: ${{ steps.meta.outputs.version }}

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3

    - name: Generate image metadata
      id: meta
      run: |
        # Semantic versioning: v1.2.3 või short SHA
        if [[ "${{ github.ref }}" == refs/tags/* ]]; then
          VERSION=${GITHUB_REF#refs/tags/}
        else
          VERSION=$(git rev-parse --short HEAD)
        fi
        echo "version=$VERSION" >> $GITHUB_OUTPUT
        echo "date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> $GITHUB_OUTPUT

    - name: Build Docker image
      run: |
        cd labs/apps/backend-nodejs
        docker build \
          -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }} \
          -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest \
          --label "org.opencontainers.image.created=${{ steps.meta.outputs.date }}" \
          --label "org.opencontainers.image.revision=${{ github.sha }}" \
          --label "org.opencontainers.image.version=${{ steps.meta.outputs.version }}" \
          .

    - name: Scan image with Trivy
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'

    - name: Upload Trivy results to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'

    # VPS-iga ühendamine nõuab SSH tunnel või VPN
    # Siin näide Self-Hosted Runner-iga
    - name: Push to Registry
      run: |
        # Kui kasutad self-hosted runner VPS-is:
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest

    - name: Create release artifact
      run: |
        echo "${{ steps.meta.outputs.version }}" > version.txt
        echo "Image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.meta.outputs.version }}" >> artifact.txt

    - name: Upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: backend-build-${{ steps.meta.outputs.version }}
        path: |
          version.txt
          artifact.txt
```

### 4.2. Self-Hosted Runner VPS-is

**Eesmärk:** Käivitada GitHub Actions workflow VPS-is (kirjakast)

**Paigalda self-hosted runner:**

```bash
# VPS kirjakast-is
cd /home/janek
mkdir actions-runner && cd actions-runner

# Lae alla runner (kontrolli uusimat versiooni GitHub-ist)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

tar xzf actions-runner-linux-x64-2.311.0.tar.gz

# Konfigureeri (GitHub Settings → Actions → Runners → New self-hosted runner)
./config.sh --url https://github.com/YOUR-USERNAME/YOUR-REPO --token YOUR-TOKEN

# Käivita runner service-na
sudo ./svc.sh install
sudo ./svc.sh start

# Kontrolli
sudo ./svc.sh status
```

**Kasuta workflow-s:**
```yaml
jobs:
  deploy:
    runs-on: self-hosted  # Kasuta VPS runner-it
    steps:
      - name: Deploy to K3s
        run: kubectl apply -f deployment.yaml
```

---

## 5. Kubernetes Deployment Automation

### 5.1. Deploy Workflow

**Fail:** `.github/workflows/deploy.yml`

```yaml
name: Deploy to Kubernetes

on:
  workflow_run:
    workflows: ["Backend CD"]
    types: [completed]
    branches: [main]
  workflow_dispatch:
    inputs:
      image-tag:
        description: 'Image tag to deploy'
        required: true
        default: 'latest'
      environment:
        description: 'Environment'
        required: true
        default: 'production'
        type: choice
        options:
          - dev
          - staging
          - production

env:
  REGISTRY: localhost:5000
  IMAGE_NAME: backend

jobs:
  deploy:
    name: Deploy to K3s
    runs-on: self-hosted  # VPS kirjakast

    environment:
      name: ${{ github.event.inputs.environment || 'production' }}

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Get image tag
      id: get-tag
      run: |
        if [ -n "${{ github.event.inputs.image-tag }}" ]; then
          TAG="${{ github.event.inputs.image-tag }}"
        else
          TAG=$(git rev-parse --short HEAD)
        fi
        echo "tag=$TAG" >> $GITHUB_OUTPUT

    - name: Update Deployment image
      run: |
        kubectl set image deployment/backend \
          backend=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ steps.get-tag.outputs.tag }} \
          -n production \
          --record

    - name: Wait for rollout
      run: |
        kubectl rollout status deployment/backend -n production --timeout=5m

    - name: Verify deployment
      run: |
        # Kontrolli, et vähemalt 1 Pod on ready
        READY=$(kubectl get deployment backend -n production -o jsonpath='{.status.readyReplicas}')
        if [ "$READY" -lt 1 ]; then
          echo "Deployment failed: no ready replicas"
          exit 1
        fi
        echo "Deployment successful: $READY replicas ready"

    - name: Test health endpoint
      run: |
        # Port-forward ja test
        kubectl port-forward service/backend 3001:3000 -n production &
        PF_PID=$!
        sleep 5

        HEALTH=$(curl -s http://localhost:3001/health | jq -r '.status')
        kill $PF_PID

        if [ "$HEALTH" != "ok" ]; then
          echo "Health check failed"
          exit 1
        fi
        echo "Health check passed"

    - name: Rollback on failure
      if: failure()
      run: |
        echo "Deployment failed, rolling back..."
        kubectl rollout undo deployment/backend -n production
        kubectl rollout status deployment/backend -n production --timeout=3m
```

### 5.2. Deployment Strategy - Blue/Green

**Blue/Green deployment:** Zero downtime deployment

```yaml
jobs:
  blue-green-deploy:
    name: Blue/Green Deployment
    runs-on: self-hosted

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Get current color
      id: current-color
      run: |
        # Kontrolli, milline värv on praegu aktiivne
        CURRENT=$(kubectl get service backend -n production -o jsonpath='{.spec.selector.color}')
        if [ "$CURRENT" == "blue" ]; then
          NEW_COLOR="green"
        else
          NEW_COLOR="blue"
        fi
        echo "current=$CURRENT" >> $GITHUB_OUTPUT
        echo "new=$NEW_COLOR" >> $GITHUB_OUTPUT

    - name: Deploy new version (new color)
      run: |
        # Deploy uus versioon uue värviga
        cat <<EOF | kubectl apply -f -
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: backend-${{ steps.current-color.outputs.new }}
          namespace: production
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: backend
              color: ${{ steps.current-color.outputs.new }}
          template:
            metadata:
              labels:
                app: backend
                color: ${{ steps.current-color.outputs.new }}
            spec:
              containers:
              - name: backend
                image: localhost:5000/backend:${{ github.sha }}
        EOF

    - name: Wait for new deployment
      run: |
        kubectl rollout status deployment/backend-${{ steps.current-color.outputs.new }} -n production

    - name: Switch service to new color
      run: |
        kubectl patch service backend -n production -p \
          '{"spec":{"selector":{"color":"${{ steps.current-color.outputs.new }}"}}}'

    - name: Verify switch
      run: |
        sleep 10
        # Test endpoint
        curl -f http://backend.production.svc.cluster.local:3000/health

    - name: Delete old deployment
      run: |
        kubectl delete deployment backend-${{ steps.current-color.outputs.current }} -n production
```

---

## 6. Multi-Environment Setup

### 6.1. Environment Structure

```
environments/
├── dev/
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   └── kustomization.yaml
├── staging/
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   └── kustomization.yaml
└── production/
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    └── kustomization.yaml
```

### 6.2. Kustomize Base + Overlays

**Base:** `k8s/base/backend-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
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
        image: localhost:5000/backend:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

**Overlay Production:** `k8s/overlays/production/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

bases:
  - ../../base

resources:
  - namespace.yaml

patchesStrategicMerge:
  - replica-patch.yaml
  - resource-patch.yaml

images:
  - name: localhost:5000/backend
    newTag: v1.2.3  # Uuendatakse CI/CD-s
```

**Replica Patch:** `k8s/overlays/production/replica-patch.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 5  # Production: 5 replicas (base on 2)
```

**Deploy Kustomize-iga:**
```yaml
steps:
- name: Deploy with Kustomize
  run: |
    cd k8s/overlays/production
    kustomize edit set image localhost:5000/backend:${{ github.sha }}
    kubectl apply -k .
```

### 6.3. Environment-Specific Workflow

```yaml
name: Multi-Environment Deploy

on:
  push:
    branches:
      - main        # → production
      - develop     # → staging
      - 'feature/*' # → dev

jobs:
  determine-environment:
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.set-env.outputs.environment }}
    steps:
      - id: set-env
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "environment=production" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
            echo "environment=staging" >> $GITHUB_OUTPUT
          else
            echo "environment=dev" >> $GITHUB_OUTPUT
          fi

  deploy:
    needs: determine-environment
    runs-on: self-hosted
    environment: ${{ needs.determine-environment.outputs.environment }}

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Deploy to ${{ needs.determine-environment.outputs.environment }}
      run: |
        ENV=${{ needs.determine-environment.outputs.environment }}
        kubectl apply -k k8s/overlays/$ENV
```

---

## 7. Secrets ja Environment Variables

### 7.1. GitHub Secrets

**Lisada Secrets GitHub-is:**
1. Repo → Settings → Secrets and variables → Actions
2. New repository secret

**Secrets:**
```
KUBE_CONFIG          # kubectl config (base64)
REGISTRY_URL         # localhost:5000
DB_PASSWORD          # PostgreSQL parool
JWT_SECRET           # JWT secret
```

**Kasuta workflow-s:**
```yaml
steps:
- name: Configure kubectl
  env:
    KUBE_CONFIG_DATA: ${{ secrets.KUBE_CONFIG }}
  run: |
    mkdir -p ~/.kube
    echo "$KUBE_CONFIG_DATA" | base64 -d > ~/.kube/config
    chmod 600 ~/.kube/config

- name: Update Secret
  env:
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
    JWT_SECRET: ${{ secrets.JWT_SECRET }}
  run: |
    kubectl create secret generic backend-secret \
      --from-literal=DB_PASSWORD="$DB_PASSWORD" \
      --from-literal=JWT_SECRET="$JWT_SECRET" \
      --dry-run=client -o yaml | kubectl apply -f -
```

### 7.2. Environment Secrets

**GitHub Environments:**
- Repository → Settings → Environments
- Create environment: `production`, `staging`, `dev`
- Add environment-specific secrets

**Workflow:**
```yaml
jobs:
  deploy-production:
    runs-on: self-hosted
    environment: production  # Kasuta production environment secrets

    steps:
    - name: Deploy
      env:
        DB_HOST: ${{ secrets.DB_HOST }}  # production-specific
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
      run: ./deploy.sh
```

### 7.3. Kubeconfig Secret

**Genereeri KUBE_CONFIG secret:**

```bash
# VPS kirjakast-is
cat ~/.kube/config | base64 -w 0

# Kopeeri output ja lisa GitHub Secrets-isse kui KUBE_CONFIG
```

**Kasuta workflow-s (GitHub-hosted runner):**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest  # GitHub-hosted

    steps:
    - name: Setup kubectl
      uses: azure/setup-kubectl@v3

    - name: Configure kubectl
      env:
        KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
      run: |
        mkdir -p ~/.kube
        echo "$KUBE_CONFIG" | base64 -d > ~/.kube/config

    - name: Deploy
      run: kubectl apply -f deployment.yaml
```

---

## 8. Advanced Workflows

### 8.1. Matrix Strategy

**Testi mitmele Node.js versioonile:**

```yaml
jobs:
  test:
    name: Test on Node ${{ matrix.node }}
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node: [16, 18, 20]
      fail-fast: false  # Jätka teiste versioonidega ka kui üks failib

    steps:
    - uses: actions/checkout@v4

    - name: Setup Node.js ${{ matrix.node }}
      uses: actions/setup-node@v4
      with:
        node-version: ${{ matrix.node }}

    - run: npm ci
    - run: npm test
```

### 8.2. Reusable Workflows

**Reusable Workflow:** `.github/workflows/deploy-template.yml`

```yaml
name: Deploy Template

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      image-tag:
        required: true
        type: string
    secrets:
      kube-config:
        required: true

jobs:
  deploy:
    runs-on: self-hosted
    environment: ${{ inputs.environment }}

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup kubectl
      env:
        KUBE_CONFIG: ${{ secrets.kube-config }}
      run: |
        mkdir -p ~/.kube
        echo "$KUBE_CONFIG" | base64 -d > ~/.kube/config

    - name: Deploy
      run: |
        kubectl set image deployment/backend \
          backend=localhost:5000/backend:${{ inputs.image-tag }} \
          -n ${{ inputs.environment }}
```

**Kasuta teises workflow-s:** `.github/workflows/prod-deploy.yml`

```yaml
name: Production Deploy

on:
  push:
    branches: [main]

jobs:
  call-deploy:
    uses: ./.github/workflows/deploy-template.yml
    with:
      environment: production
      image-tag: ${{ github.sha }}
    secrets:
      kube-config: ${{ secrets.KUBE_CONFIG }}
```

### 8.3. Slack Notifications

```yaml
jobs:
  notify:
    runs-on: ubuntu-latest
    if: always()  # Käivitu isegi kui eelnevad jobid failivad

    steps:
    - name: Send Slack notification
      uses: slackapi/slack-github-action@v1
      with:
        payload: |
          {
            "text": "Deployment ${{ job.status }}",
            "blocks": [
              {
                "type": "section",
                "text": {
                  "type": "mrkdwn",
                  "text": "*Deployment to Production*\nStatus: ${{ job.status }}\nCommit: ${{ github.sha }}\nAuthor: ${{ github.actor }}"
                }
              }
            ]
          }
      env:
        SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 9. Best Practices

### 9.1. Caching Dependencies

**Cache npm dependencies:**
```yaml
steps:
- uses: actions/setup-node@v4
  with:
    node-version: 18
    cache: 'npm'
    cache-dependency-path: package-lock.json

- run: npm ci  # Kasuta ci, mitte install
```

**Cache Docker layers:**
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build image with cache
  uses: docker/build-push-action@v5
  with:
    context: .
    push: false
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### 9.2. Conditional Execution

```yaml
steps:
- name: Deploy to production
  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  run: ./deploy.sh

- name: Run on PR only
  if: github.event_name == 'pull_request'
  run: npm run lint

- name: Run on success
  if: success()
  run: echo "Previous steps succeeded"

- name: Run on failure
  if: failure()
  run: echo "Previous steps failed"

- name: Always run (cleanup)
  if: always()
  run: docker system prune -f
```

### 9.3. Security Best Practices

**1. Ära logi secrets:**
```yaml
- name: Bad example
  run: echo "Password is ${{ secrets.DB_PASSWORD }}"  # ❌ NEVER DO THIS

- name: Good example
  env:
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
  run: |
    # $DB_PASSWORD on peidetud logides
    ./script.sh
```

**2. Kasuta dependency review:**
```yaml
- name: Dependency Review
  uses: actions/dependency-review-action@v3
  if: github.event_name == 'pull_request'
```

**3. Pin action versioonid:**
```yaml
# ❌ Bad: kasutab latest
- uses: actions/checkout@v4

# ✅ Good: pinned commit SHA
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
```

---

## 10. Harjutused

### Harjutus 1: Backend CI/CD Pipeline

**Eesmärk:** Seadistada täielik CI/CD pipeline backend-ile

**Sammud:**

1. **Loo GitHub repo:**
```bash
cd /home/janek/projects/hostinger
git init
git add .
git commit -m "Initial commit"

# Loo repo GitHub-is ja push
git remote add origin https://github.com/YOUR-USERNAME/hostinger-training.git
git push -u origin main
```

2. **Loo CI workflow:**
```bash
mkdir -p .github/workflows
vim .github/workflows/backend-ci.yml
# (kopeeri sektsioonist 3.1)

git add .github/workflows/backend-ci.yml
git commit -m "Add backend CI workflow"
git push
```

3. **Kontrolli GitHub Actions:**
- Ava repo GitHub-is
- Actions tab
- Peaks nägema "Backend CI" workflow running

4. **Vaata tulemusi:**
- Kontrolli, kas kõik jobid (lint, test, security) õnnestuvad
- Vaata loge
- Paranda errors kui on

5. **Loo CD workflow:**
```bash
vim .github/workflows/backend-cd.yml
# (kopeeri sektsioonist 4.1)

git add .github/workflows/backend-cd.yml
git commit -m "Add backend CD workflow"
git push
```

**Valideerimise checklist:**
- [ ] CI workflow loodud
- [ ] Lint job töötab
- [ ] Test job töötab (PostgreSQL service)
- [ ] Security audit töötab
- [ ] CD workflow loodud
- [ ] Docker image built
- [ ] Trivy scan käivitub

---

### Harjutus 2: Self-Hosted Runner VPS-is

**Eesmärk:** Seadistada GitHub Actions runner VPS-is

**Sammud:**

1. **Paigalda runner VPS-is:**
```bash
ssh janek@kirjakast

cd /home/janek
mkdir actions-runner && cd actions-runner

# Lae alla (kontrolli uusim versioon GitHub-ist)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

tar xzf actions-runner-linux-x64-2.311.0.tar.gz
```

2. **Konfigureeri runner:**
- GitHub repo → Settings → Actions → Runners → New self-hosted runner
- Kopeeri token

```bash
./config.sh --url https://github.com/YOUR-USERNAME/YOUR-REPO --token YOUR-TOKEN

# Enter runner name: kirjakast-runner
# Enter runner group: Default
# Enter labels: self-hosted,vps,kirjakast
```

3. **Käivita service:**
```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

4. **Testi runner:**
```yaml
# .github/workflows/test-runner.yml
name: Test Self-Hosted Runner

on: workflow_dispatch

jobs:
  test:
    runs-on: self-hosted

    steps:
    - name: Show hostname
      run: hostname

    - name: Check Docker
      run: docker --version

    - name: Check kubectl
      run: kubectl version --client
```

**Valideerimise checklist:**
- [ ] Runner paigaldatud
- [ ] Runner nähtav GitHub-is (Settings → Runners)
- [ ] Runner status: Idle (roheline)
- [ ] Test workflow käivitub runner-is
- [ ] Saab kätte VPS ressursse (Docker, kubectl)

---

### Harjutus 3: Automated Kubernetes Deployment

**Eesmärk:** Automatiseerida deployment K8s-es

**Sammud:**

1. **Genereeri KUBE_CONFIG secret:**
```bash
# VPS-is
cat ~/.kube/config | base64 -w 0

# Kopeeri output
```

2. **Lisa secret GitHub-i:**
- Repo → Settings → Secrets and variables → Actions
- New repository secret
- Name: `KUBE_CONFIG`
- Value: (paste base64 output)

3. **Loo deploy workflow:**
```bash
vim .github/workflows/deploy.yml
# (kopeeri sektsioonist 5.1)

git add .github/workflows/deploy.yml
git commit -m "Add deployment automation"
git push
```

4. **Testi manual deployment:**
- GitHub → Actions → Deploy to Kubernetes
- Run workflow
- Vali environment: production
- Vali image-tag: latest

5. **Jälgi deployment-i:**
```bash
# VPS-is
watch kubectl get pods -n production
```

6. **Kontrolli rollout:**
```bash
kubectl rollout status deployment/backend -n production
kubectl rollout history deployment/backend -n production
```

**Valideerimise checklist:**
- [ ] KUBE_CONFIG secret lisatud
- [ ] Deploy workflow loodud
- [ ] Manual trigger töötab
- [ ] Deployment uuendatakse K8s-es
- [ ] Rollout õnnestub
- [ ] Health check töötab
- [ ] Rollback töötab failure korral

---

## Kokkuvõte

Selles peatükis õppisid:

✅ **GitHub Actions Põhimõtted:**
- Workflow struktuur (on, jobs, steps)
- Triggers (push, PR, schedule, manual)
- Paralleelsed ja järjestikused jobs

✅ **CI Workflows:**
- Lint, test, security audit
- PostgreSQL service containers
- Code coverage upload

✅ **CD Workflows:**
- Docker image build ja push
- Image tagging strategies
- Security scanning (Trivy)

✅ **Kubernetes Deployment:**
- Automated kubectl deployment
- Rollout verification
- Rollback on failure
- Blue/Green deployment

✅ **Multi-Environment:**
- Environment-specific configs
- Kustomize overlays
- Branch-based deployment

✅ **Secrets Management:**
- GitHub Secrets
- Environment Secrets
- Kubeconfig in CI/CD

✅ **Advanced Features:**
- Self-hosted runners
- Matrix strategy
- Reusable workflows
- Notifications (Slack)

✅ **Best Practices:**
- Dependency caching
- Conditional execution
- Security practices
- Version pinning

---

## Järgmine Samm

**Peatükk 21: Monitoring ja Logging**
- Prometheus + Grafana
- PostgreSQL monitoring (mõlemad variandid)
- Application metrics
- Log aggregation (Loki)
- Alerting (AlertManager)

**Ressursid:**
- GitHub Actions Docs: https://docs.github.com/en/actions
- Workflow Syntax: https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- Self-Hosted Runners: https://docs.github.com/en/actions/hosting-your-own-runners
- Kustomize: https://kustomize.io/

---

**VPS:** kirjakast @ 93.127.213.242
**Kasutaja:** janek
**Editor:** vim
**CI/CD:** GitHub Actions

Edu! 🚀
