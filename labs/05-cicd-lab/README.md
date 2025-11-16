# Labor 5: CI/CD Pipeline

**Kestus:** 4 tundi
**Eeldused:** Labor 1-4 läbitud, Peatükk 20-21 (CI/CD)
**Eesmärk:** Automatiseerida build ja deploy protsess GitHub Actions'iga

---

## 📋 Ülevaade

Selles laboris lood täieliku CI/CD pipeline'i GitHub Actions'iga, mis automatiseerib kogu DevOps workflow'i: koodi push → automaatne test → Docker image build → deploy Kubernetes'e.

**CI/CD** = Continuous Integration + Continuous Deployment
- **CI:** Automaatne testimine ja build iga commit'iga
- **CD:** Automaatne deploy production'i peale edukat build'i

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

✅ Luua GitHub Actions workflow'sid
✅ Automatiseerida Docker image build'i ja push'i
✅ Auto-deploy'da Kubernetes klasterisse
✅ Käivitada automated tests
✅ Implementeerida rollback strateegiat
✅ Seadistada multi-environment pipeline (dev, staging, prod)
✅ Kasutada GitHub Secrets
✅ Monitoorida pipeline'i

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────────────────────────────┐
│               GitHub Repository                     │
│                                                     │
│  Developer push code                                │
│          │                                          │
│          ▼                                          │
│  ┌─────────────────────────────────────────┐       │
│  │   GitHub Actions Workflow               │       │
│  │                                         │       │
│  │   1. Checkout code                      │       │
│  │   2. Run tests (npm test)               │       │
│  │   3. Build Docker image                 │       │
│  │   4. Push to Docker Hub                 │       │
│  │   5. Deploy to Kubernetes               │       │
│  │   6. Health check                       │       │
│  └─────────────────┬───────────────────────┘       │
│                    │                                │
└────────────────────┼────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │   Docker Hub           │
        │   user-service:latest  │
        │   user-service:v1.2.3  │
        └────────────┬───────────┘
                     │
                     ▼
        ┌────────────────────────────┐
        │  Kubernetes Cluster        │
        │                            │
        │  kubectl apply -f          │
        │  deployment.yaml           │
        │                            │
        │  Rolling update            │
        │  New pods: v1.2.3          │
        └────────────────────────────┘
```

---

## 📂 Labori Struktuur

```
05-cicd-lab/
├── README.md              # See fail
├── exercises/             # Harjutused
│   ├── 01-github-actions-basics.md
│   ├── 02-docker-build-push.md
│   ├── 03-kubernetes-deploy.md
│   ├── 04-automated-testing.md
│   └── 05-multi-environment.md
├── .github/               # GitHub Actions workflows
│   └── workflows/
│       ├── ci.yml         # Continuous Integration
│       ├── cd.yml         # Continuous Deployment
│       └── rollback.yml   # Rollback workflow
└── solutions/             # Näidislahendused
    └── README.md
```

---

## 🔧 Eeldused

### Tööriistad:
- [x] GitHub konto
- [x] Docker Hub konto (või GitHub Container Registry)
- [x] Kubernetes cluster (Lab 3-4'st)
- [x] kubectl configured
- [x] Git paigaldatud

### Valmis komponendid:
- [x] User Service rakendus (Lab 1)
- [x] Dockerfile (Lab 1)
- [x] Kubernetes manifests (Lab 3)
- [x] Helm Chart (Lab 4 - optional)

---

## 📝 Harjutused

### Harjutus 1: GitHub Actions Basics (45 min)
**Fail:** [exercises/01-github-actions-basics.md](exercises/01-github-actions-basics.md)

**Loo esimene GitHub Actions workflow:**
- GitHub Actions struktuur
- Workflow YAML süntaks
- Triggers (push, pull_request)
- Jobs ja steps
- Actions marketplace
- Testi lihtsat workflow'd

**Õpid:**
- GitHub Actions põhimõtteid
- YAML workflow syntax
- Runners ja jobs
- Environment variables
- Secrets kasutamist

---

### Harjutus 2: Docker Build ja Push (60 min)
**Fail:** [exercises/02-docker-build-push.md](exercises/02-docker-build-push.md)

**Automatiseeri Docker image build:**
- Docker Hub autentimine
- Build Docker image workflow's
- Multi-platform builds
- Image tagging strateegia
- Push Docker Hub'i
- Cache layer'ite kasutamine

**Õpid:**
- Docker build automation
- Docker Hub secrets
- Image tagging best practices
- Build cache optimization
- Multi-stage build CI's

---

### Harjutus 3: Kubernetes Deploy (60 min)
**Fail:** [exercises/03-kubernetes-deploy.md](exercises/03-kubernetes-deploy.md)

**Auto-deploy Kubernetes'e:**
- kubeconfig seadistamine
- kubectl GitHub Actions's
- Deployment update strateegia
- Rolling update CI/CD's
- Health check peale deploy'i
- Rollout status kontroll

**Õpid:**
- Kubernetes deployment automation
- kubeconfig secrets
- kubectl commands CI's
- Deployment verification
- Zero-downtime CI/CD

---

### Harjutus 4: Automated Testing (45 min)
**Fail:** [exercises/04-automated-testing.md](exercises/04-automated-testing.md)

**Lisa automaatsed testid:**
- Unit tests (npm test)
- Integration tests
- Linting (ESLint)
- Code coverage
- Test reporting
- Failing tests → blokeerib deploy

**Õpid:**
- Test automation CI's
- Test reporting
- Coverage metrics
- Quality gates
- Fail-fast strateegiat

---

### Harjutus 5: Multi-Environment Pipeline (60 min)
**Fail:** [exercises/05-multi-environment.md](exercises/05-multi-environment.md)

**Loo dev/staging/prod pipeline:**
- Environment-specific workflows
- Branch-based deployment (dev → staging → prod)
- Manual approval gates
- Environment secrets
- Rollback strateegia
- Blue-Green deployment

**Õpid:**
- Multi-environment CI/CD
- Deployment strategies
- Approval workflows
- Environment management
- Rollback procedures

---

## 🚀 Kiirstart

### 1. Kontrolli Eeldusi

```bash
# Git
git --version

# GitHub CLI (optional)
gh --version

# Docker Hub login
docker login

# kubectl
kubectl version --client

# Kubernetes cluster
kubectl cluster-info
```

### 2. Loo GitHub Repository

```bash
# Loo uus repo GitHub'is või kasuta olemasolevat
# https://github.com/new

# Clone repo
git clone https://github.com/your-username/user-service.git
cd user-service

# Kopeeri rakendus
cp -r ../../apps/backend-nodejs/* .

# Commit ja push
git add .
git commit -m "Initial commit"
git push origin main
```

### 3. Alusta Harjutus 1'st

```bash
cd exercises
cat 01-github-actions-basics.md
```

---

## ✅ Kontrolli Tulemusi

Peale labori läbimist pead omama:

- [ ] **GitHub Actions workflows:**
  - [ ] CI workflow (build + test)
  - [ ] CD workflow (deploy)
  - [ ] Rollback workflow

- [ ] **Automaatne pipeline:**
  - [ ] Code push → automaatne test
  - [ ] Tests pass → Docker image build
  - [ ] Image push → Docker Hub
  - [ ] Auto-deploy → Kubernetes

- [ ] **Environments:**
  - [ ] dev (automatic deploy)
  - [ ] staging (automatic deploy)
  - [ ] prod (manual approval)

- [ ] **Monitoring:**
  - [ ] Pipeline status badges
  - [ ] Deployment history
  - [ ] Rollback capability

---

## 📊 Progressi Jälgimine

- [ ] Harjutus 1: GitHub Actions Basics
- [ ] Harjutus 2: Docker Build & Push
- [ ] Harjutus 3: Kubernetes Deploy
- [ ] Harjutus 4: Automated Testing
- [ ] Harjutus 5: Multi-Environment Pipeline

---

## 🆘 Troubleshooting

### Workflow ei käivitu?

```bash
# Kontrolli GitHub Actions tab'i
# https://github.com/your-username/your-repo/actions

# Kontrolli workflow syntax
# Kasuta GitHub Actions extension VS Code's

# Vaata workflow logisid
# Kliki workflow run → vaata job logisid
```

---

### Docker push ebaõnnestub?

```bash
# Kontrolli Docker Hub credentials GitHub Secrets's
# Settings → Secrets → DOCKER_USERNAME, DOCKER_PASSWORD

# Testi local
docker login
docker push your-username/user-service:latest
```

---

### Kubernetes deploy ebaõnnestub?

```bash
# Kontrolli kubeconfig secret
# Settings → Secrets → KUBECONFIG

# Testi local
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/user-service
```

---

## 💡 Kasulikud GitHub Actions

```yaml
# Workflow triggers
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:  # Manual trigger

# Jobs
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - uses: docker/build-push-action@v4

# Secrets
${{ secrets.DOCKER_USERNAME }}
${{ secrets.KUBECONFIG }}

# Conditional steps
if: github.ref == 'refs/heads/main'
```

---

## 📚 Viited

### Koolituskava:
- **Peatükk 20:** CI/CD põhimõtted
- **Peatükk 21:** GitHub Actions

### GitHub Actions Dokumentatsioon:
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [kubectl Action](https://github.com/marketplace/actions/kubectl-tool-installer)

---

## 🎯 Järgmine Labor

Peale selle labori edukat läbimist, jätka:
- **Labor 6:** Monitoring & Logging (Prometheus, Grafana, Loki)

---

**Edu laboriga! 🚀**

*CI/CD on DevOps'i süda - automatiseeri kõik!*

---

**Staatus:** 📝 Harjutuste loomine käib
**Viimane uuendus:** 2025-11-16
