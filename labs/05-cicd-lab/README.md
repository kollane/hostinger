# Labor 5: CI/CD Pipeline GitHub Actions'iga

**Kestus:** 5 tundi (5 × 60 min harjutust)
**Eeldused:** Labor 1-4 läbitud
**Eesmärk:** Automatiseeri täielik DevOps workflow GitHub Actions'iga

---

## 📋 Ülevaade

Selles laboris **lood täieliku CI/CD pipeline'i**, mis automatiseerib kogu tsükli: code push → test → build → security scan → deploy Kubernetes'e.

**Miks CI/CD?**
- ⚡ Kiirem deployment (minutid vs tunnid)
- 🐛 Vähem vigu (automated testing)
- 🔒 Turvalisem (security scanning)
- 📊 Jälgitav (deployment history)
- 🔄 Korratav (sama protsess iga kord)

**Enne vs Pärast:**
- **Enne:** Manuaalne build → manual test → manual deploy (1-2h, error-prone)
- **Pärast:** Git push → automaatne pipeline → deployed (5-10 min, reliable)

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

- ✅ Luua GitHub Actions workflow'sid
- ✅ Automatiseerida testimist (unit tests, linting)
- ✅ Ehitada ja pushida Docker image'eid automaatselt
- ✅ Skaneerida turvaauke (Docker Scout, Trivy)
- ✅ Deploy'da Helm'iga automaatselt
- ✅ Seadistada multi-environment pipeline (dev/staging/prod)
- ✅ Implementeerida rollback mehhanismi
- ✅ Kasutada GitHub Secrets'e turvaliselt

---

## 🏗️ Arhitektuur

### CI/CD Pipeline Flow

```
Developer
   │
   ├─ git push → GitHub
   │              │
   │              ▼
   │     ┌─────────────────────────┐
   │     │  GitHub Actions         │
   │     │                         │
   │     │  ┌──────────────────┐  │
   │     │  │ 1. CI Workflow   │  │
   │     │  │                  │  │
   │     │  │  ├─ Lint         │  │
   │     │  │  ├─ Test (Node   │  │
   │     │  │  │   20 + 22)    │  │
   │     │  │  ├─ Build Docker │  │
   │     │  │  └─ Security Scan│  │
   │     │  │     (Scout+Trivy)│  │
   │     │  └────────┬──────────┘  │
   │     │           │              │
   │     │           ▼              │
   │     │  ┌──────────────────┐  │
   │     │  │ 2. CD Workflow   │  │
   │     │  │                  │  │
   │     │  │  ├─ Determine    │  │
   │     │  │  │   Environment │  │
   │     │  │  ├─ Setup Helm   │  │
   │     │  │  ├─ Deploy with  │  │
   │     │  │  │   Helm        │  │
   │     │  │  ├─ Health Check │  │
   │     │  │  └─ Rollback on  │  │
   │     │  │     Failure      │  │
   │     │  └────────┬──────────┘  │
   │     └───────────┼─────────────┘
   │                 │
   │                 ▼
   │        ┌─────────────────┐
   │        │  Docker Hub     │
   │        │                 │
   │        │  user-service:  │
   │        │  - main-abc123  │
   │        │  - develop-xyz  │
   │        └────────┬────────┘
   │                 │
   │                 ▼
   │        ┌─────────────────────┐
   │        │  Kubernetes Cluster │
   │        │                     │
   │        │  Namespaces:        │
   │        │  ├─ development     │
   │        │  ├─ staging         │
   │        │  └─ production      │
   │        │                     │
   │        │  Helm Releases:     │
   │        │  └─ user-service    │
   │        └─────────────────────┘
   │
   └─ Notifications (GitHub UI, email)
```

### Multi-Environment Strategy

```
Branch        Environment    Auto-Deploy?   Approval?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
develop   →   development    ✅ Yes         ❌ No
staging   →   staging        ✅ Yes         ❌ No  
main      →   production     ❌ No          ✅ Manual
```

---

## 📂 Labori Struktuur

```
05-cicd-lab/
├── README.md                          # See fail
├── exercises/                         # Harjutused (5 × 60 min)
│   ├── 01-github-actions-basics.md   # GitHub Actions alused
│   ├── 02-ci-pipeline.md             # Lint, Test, Build, Security
│   ├── 03-helm-deployment.md         # Automated Helm deploy
│   ├── 04-quality-gates.md           # Testing & validation
│   └── 05-production-pipeline.md     # Multi-env, approval, rollback
├── .github/
│   └── workflows/                     # GitHub Actions workflows
│       ├── ci.yml                     # Continuous Integration
│       ├── cd.yml                     # Continuous Deployment
│       └── security.yml               # Scheduled security scans
├── solutions/                         # Näidislahendused
│   ├── workflows/                     # Reference workflows
│   └── configs/                       # Config näidised
└── setup.sh                           # Environment setup script
```

---

## 🔧 Eeldused

### Eelnevad labid:

✅ **Labor 1: Docker** - KOHUSTUSLIK
- Dockerfile loomise oskus
- Docker image build

✅ **Labor 3: Kubernetes Basics** - KOHUSTUSLIK  
- Kubernetes deployment mõistmine
- kubectl kasutamine

✅ **Labor 4: Kubernetes Advanced** - KOHUSTUSLIK
- Helm charts (kasutame automaatseks deploy'ks)
- Ingress, HPA (monitoorime pipeline'is)

❌ **Labor 2: Docker Compose** - Pole vajalik

### Tööriistad:

- ✅ **GitHub konto** (tasuta tier piisab)
- ✅ **Docker Hub konto** (või GitHub Container Registry)
- ✅ Kubernetes cluster (Lab 3'st)
- ✅ kubectl configured
- ✅ Git paigaldatud

### GitHub Secrets (seadistame Harjutus 1's):

```
DOCKER_USERNAME      # Docker Hub username
DOCKER_PASSWORD      # Docker Hub password/token
KUBECONFIG          # Base64 encoded kubeconfig
```

---

## 📚 Progressiivne Õppetee

```
Labor 1 (Docker)
  ↓ Dockerfile + Images
Labor 3 (K8s Basics)  
  ↓ Deployments + Services
Labor 4 (K8s Advanced)
  ↓ Helm Charts + Production Patterns
Labor 5 (CI/CD) ← Oled siin
  ↓ Automated Deployments + Monitoring Metrics
Labor 6 (Monitoring)
  ↓ Prometheus + Grafana
```

**Lab 5 ja Lab 6 seos:**
- Lab 5 deploy'b rakendused automaatselt
- Lab 6 monitoorib neid rakendusi
- Lab 5 lisab `/metrics` endpoint'i (Prometheus jaoks)
- Lab 5 workflow'de metrics kuvatakse Lab 6 Grafana's

---

## 📝 Harjutused

### Harjutus 1: GitHub Actions Põhitõed (60 min)

**Fail:** [exercises/01-github-actions-basics.md](exercises/01-github-actions-basics.md)

**Õpid:**
- GitHub Actions workflow süntaksi
- Triggers (push, pull_request, workflow_dispatch)
- Jobs ja steps
- GitHub Secrets seadistamist
- Esimene "Hello World" workflow

**Tulem:**
- Töötav GitHub repository
- Esimene workflow käivitub
- Secrets seadistatud

---

### Harjutus 2: Continuous Integration Pipeline (60 min)

**Fail:** [exercises/02-ci-pipeline.md](exercises/02-ci-pipeline.md)

**Õpid:**
- Automated linting (ESLint)
- Automated testing (Jest, Mocha)
- Multi-version testing (Node 20 + 22)
- Docker image build & push
- Security scanning (Docker Scout + Trivy)

**Tulem:**
- `ci.yml` workflow
- Automated tests iga commit'iga
- Docker images pushed automaatselt
- Security vulnerabilities detected

---

### Harjutus 3: Helm Deployment Automation (60 min)

**Fail:** [exercises/03-helm-deployment.md](exercises/03-helm-deployment.md)

**Õpid:**
- Helm upgrade automation
- kubeconfig GitHub Secrets'is
- Environment-specific values (dev/staging/prod)
- Deployment verification
- Health checks

**Tulem:**
- `cd.yml` workflow
- Automaatne deploy peale CI success'i
- Multi-environment support
- Zero-downtime deployments

---

### Harjutus 4: Quality Gates & Testing (60 min)

**Fail:** [exercises/04-quality-gates.md](exercises/04-quality-gates.md)

**Õpid:**
- Test coverage requirements
- Quality gates (tests must pass)
- Integration testing
- Smoke tests peale deploy'i
- Failed deployment rollback

**Tulem:**
- Coverage reporting
- Deploy blokeeritakse kui tests fail
- Automated rollback
- Post-deployment validation

---

### Harjutus 5: Production Pipeline (60 min)

**Fail:** [exercises/05-production-pipeline.md](exercises/05-production-pipeline.md)

**Õpid:**
- Manual approval gates (production)
- Blue-green deployment
- Canary deployments
- Rollback workflow
- Deployment notifications

**Tulem:**
- Production requires approval
- Safe rollback mechanism
- Deployment history tracking
- Slack/Email notifications (optional)

---

## ⚡ Kiirstart

### 1. Fork/Clone Repository

```bash
# Clone your repository
git clone https://github.com/your-username/user-service.git
cd user-service

# Kopeeri User Service kood
cp -r ../labs/apps/backend-nodejs/* .
cp ../labs/04-kubernetes-advanced-lab/solutions/helm/user-service helm-chart
```

### 2. Seadista GitHub Secrets

GitHub UI → Settings → Secrets and variables → Actions → New repository secret:

```bash
# Docker Hub
DOCKER_USERNAME: your-dockerhub-username
DOCKER_PASSWORD: your-dockerhub-token

# Kubernetes
KUBECONFIG: <base64 encoded kubeconfig>
```

**Generate KUBECONFIG secret:**

```bash
# Encode kubeconfig
cat ~/.kube/config | base64 -w 0

# Copy output ja lisa GitHub Secrets'i
```

### 3. Create Workflows

Kopeeri workflows:

```bash
mkdir -p .github/workflows
cp ../labs/05-cicd-lab/solutions/workflows/* .github/workflows/
```

### 4. Test Workflow

```bash
# Commit and push
git add .
git commit -m "Add CI/CD workflows"
git push

# Vaata GitHub Actions tab'i
# https://github.com/your-username/your-repo/actions
```

---

## ✅ Kontrolli Tulemusi

Peale labori läbimist:

- [ ] **CI Workflow toimib:**
  - [ ] Lint käivitub automaatselt
  - [ ] Tests pass (Node 20 + 22)
  - [ ] Docker image builds
  - [ ] Security scan completes

- [ ] **CD Workflow toimib:**
  - [ ] Auto-deploy development
  - [ ] Auto-deploy staging
  - [ ] Manual approval production
  - [ ] Health checks pass

- [ ] **Rollback toimib:**
  - [ ] Manual rollback workflow
  - [ ] Automatic rollback on failure

- [ ] **Multi-Environment:**
  - [ ] 3 namespaces (dev/staging/prod)
  - [ ] Environment-specific configs
  - [ ] Proper image tagging

---

## 🐛 Troubleshooting

### Workflow ei käivitu?

```bash
# 1. Kontrolli workflow syntax
# GitHub Actions UI näitab syntax errors

# 2. Kontrolli triggers
on:
  push:
    branches: [main, develop]

# 3. Vaata workflow logs
# Actions tab → workflow run → job logs
```

### Docker push fails?

```bash
# Kontrolli secrets
Settings → Secrets → DOCKER_USERNAME, DOCKER_PASSWORD

# Test local
docker login
docker push your-username/user-service:test
```

### Helm deploy fails?

```bash
# Kontrolli KUBECONFIG secret
# Peab olema base64 encoded

# Test local
helm upgrade --install user-service ./helm-chart
```

---

## 💡 Best Practices

1. **Ära commit'i secrets** - Use GitHub Secrets
2. **Test local** - Testi workflow'e local'i (act tool)
3. **Fail fast** - Stopp pipeline kui tests fail
4. **Automated rollback** - Rollback automaatselt kui deploy fail
5. **Matrix testing** - Test mitmel Node versioonil
6. **Security scanning** - Igal build'il
7. **Environment parity** - Dev/staging parity production'iga

---

## 📊 Progressi Jälgimine

- [ ] Harjutus 1: GitHub Actions Basics
- [ ] Harjutus 2: CI Pipeline
- [ ] Harjutus 3: Helm Deployment
- [ ] Harjutus 4: Quality Gates
- [ ] Harjutus 5: Production Pipeline

---

## 🔗 Järgmine Labor

**Labor 6: Monitoring & Logging**
- Prometheus metrics collection
- Grafana dashboards
- CI/CD deployment tracking
- Pipeline performance monitoring

---

## 📚 Viited

### GitHub Actions:
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)

### Docker:
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Docker Scout](https://docs.docker.com/scout/)

### Helm:
- [Helm Documentation](https://helm.sh/docs/)
- [Azure Setup Helm Action](https://github.com/Azure/setup-helm)

---

**Edu laboriga! 🚀**

*Automatiseeri kõik - DevOps mantra!*

---

**Staatus:** 🚧 Labor 5 uuendamine käib (2025 best practices)
**Viimane uuendus:** 2025-11-22
**Branch:** `claude/lab5-cicd-2025-updates-018RYjxCqf8E3dwpfDYHmSHJ`
