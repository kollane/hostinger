# Lab 5: CI/CD Pipeline - Solutions

See kaust sisaldab näidislahendusi Lab 5 harjutustele.

---

## 📂 Workflow'de Ülevaade

### 1. Continuous Integration (`ci.yml`)

**Asukoht:** `.github/workflows/ci.yml`

**Eesmärk:** Lint + Test + Build Docker image

**Käivitub:**
- `push` → `main`, `develop`, `staging` branch'idele
- `pull_request` → `main` branch'i
- `workflow_dispatch` → manuaalselt

**Job'id:**
1. **lint** - ESLint code quality check
2. **test** - Unit/integration tests (Node.js 18, 20)
3. **build** - Docker image build ja push
4. **summary** - CI pipeline kokkuvõte

**Features:**
- ✅ Fail-fast: lint fails → stop pipeline
- ✅ Matrix testing: test Node.js 18 ja 20
- ✅ Coverage report: upload artifact
- ✅ Docker cache: GitHub Actions cache
- ✅ Multi-platform: linux/amd64

**Secrets:**
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

---

### 2. Continuous Deployment (`cd.yml`)

**Asukoht:** `.github/workflows/cd.yml`

**Eesmärk:** Deploy Kubernetes'e (multi-environment)

**Käivitub:**
- `workflow_run` → peale edukat CI workflow'i
- `workflow_dispatch` → manuaalselt (vali environment + image tag)

**Environment'id:**
- `develop` → `development` (auto-deploy, 1 replica)
- `staging` → `staging` (auto-deploy, 2 replicas)
- `main` → `production` (manual approval, 3 replicas)

**Job'id:**
1. **determine-environment** - Määra target environment ja image tag
2. **deploy** - Deploy Kubernetes'e

**Features:**
- ✅ Branch-based deployment
- ✅ Environment-specific replicas
- ✅ Rolling update (zero-downtime)
- ✅ Health check (curl /health)
- ✅ Automatic rollback kui deploy failibub

**Secrets (per environment):**
- `KUBECONFIG` - Base64 encoded kubeconfig
- `REPLICAS` - Replica count (1, 2, 3)

---

### 3. Rollback (`rollback.yml`)

**Asukoht:** `.github/workflows/rollback.yml`

**Eesmärk:** Manual rollback deployment'i

**Käivitub:**
- `workflow_dispatch` → ainult manuaalselt

**Input'id:**
- `environment` - development, staging, production
- `revision` - (optional) specific revision number

**Job'id:**
1. **rollback** - Rollback deployment

**Features:**
- ✅ Rollback eelmisele revision'ile (default)
- ✅ Rollback konkreetsele revision'ile
- ✅ Show rollout history
- ✅ Health check peale rollback'i
- ✅ Detailed summary

---

## 🚀 Workflow'de Kasutamine

### CI Workflow

**Automaatne käivitamine:**

```bash
# Push koodi → CI käivitub automaatselt
git add .
git commit -m "Update feature"
git push origin main
```

**Manuaalne käivitamine:**

1. GitHub → Actions → "Continuous Integration"
2. "Run workflow" → vali branch → "Run workflow"

---

### CD Workflow

**Automaatne deployment:**

```bash
# Develop → development environment
git push origin develop

# Staging → staging environment
git push origin staging

# Main → production environment (vajab approval!)
git push origin main
```

**Manual deployment:**

1. GitHub → Actions → "Continuous Deployment"
2. "Run workflow"
3. Vali:
   - Environment: development/staging/production
   - Image tag: (optional) specific tag
4. "Run workflow"

**Production approval:**

1. Push `main` branch'i
2. Workflow ootab approval
3. GitHub → Actions → "Continuous Deployment" run
4. "Review deployments" → ✅ Approve → "Approve and deploy"

---

### Rollback Workflow

**Rollback eelmisele versioonile:**

1. GitHub → Actions → "Rollback Deployment"
2. "Run workflow"
3. Vali:
   - Environment: production
   - Revision: (leave empty)
4. "Run workflow"

**Rollback konkreetsele revision'ile:**

1. GitHub → Actions → "Rollback Deployment"
2. "Run workflow"
3. Vali:
   - Environment: production
   - Revision: 3
4. "Run workflow"

---

## 🔐 Secrets Setup

### Repository Secrets

**Docker Hub:**
- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub access token

### Environment Secrets

**development:**
- `KUBECONFIG` - Dev cluster kubeconfig (base64)
- `REPLICAS` - `1`

**staging:**
- `KUBECONFIG` - Staging cluster kubeconfig (base64)
- `REPLICAS` - `2`

**production:**
- `KUBECONFIG` - Prod cluster kubeconfig (base64)
- `REPLICAS` - `3`

**Kubeconfig encode:**

```bash
# Ekspordi kubeconfig
kubectl config view --flatten --minify > kubeconfig.yaml

# Base64 encode
cat kubeconfig.yaml | base64 -w 0

# Kopeeri väljund → GitHub Secrets
```

---

## 🏗️ Environment Setup

### GitHub Environments

**Loo 3 environment'i:**

1. **development**
   - Deployment branches: `develop`
   - No protection rules

2. **staging**
   - Deployment branches: `staging`
   - No protection rules

3. **production**
   - Deployment branches: `main`
   - Protection rules:
     - ✅ Required reviewers (1)
     - ⏱️ Wait timer: 5 minutes

---

## 📊 Workflow Visualiseering

```
┌─────────────────────────────────────────────────────┐
│                  Code Push                          │
└────────────────┬────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────┐
│            CI Workflow (ci.yml)                     │
│                                                     │
│  1. Lint (ESLint)                                   │
│  2. Test (Jest) → Coverage                          │
│  3. Build Docker → Push Docker Hub                  │
└────────────────┬────────────────────────────────────┘
                 │ (on success)
                 ▼
┌─────────────────────────────────────────────────────┐
│            CD Workflow (cd.yml)                     │
│                                                     │
│  Determine environment based on branch:             │
│    develop → development (auto)                     │
│    staging → staging (auto)                         │
│    main → production (manual approval)              │
│                                                     │
│  Deploy to Kubernetes:                              │
│    - kubectl set image                              │
│    - kubectl rollout status                         │
│    - Health check                                   │
└─────────────────────────────────────────────────────┘

If deployment fails or needs rollback:

┌─────────────────────────────────────────────────────┐
│        Rollback Workflow (rollback.yml)             │
│                                                     │
│  Manual trigger:                                    │
│    - Select environment                             │
│    - Select revision (optional)                     │
│                                                     │
│  Rollback:                                          │
│    - kubectl rollout undo                           │
│    - Health check                                   │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ Kohandamine

### Muuda Replica Count

**Environment secrets:**

```bash
# development
REPLICAS=1

# staging
REPLICAS=2

# production
REPLICAS=5  # Increased from 3
```

### Lisa Notification

**Slack notification example (`cd.yml`):**

```yaml
- name: Notify Slack
  if: success()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    payload: |
      {
        "text": "✅ Deployment to ${{ needs.determine-environment.outputs.environment }} successful!"
      }
```

### Multi-Platform Docker Build

**Muuda `ci.yml`:**

```yaml
- name: Build and push
  uses: docker/build-push-action@v4
  with:
    platforms: linux/amd64,linux/arm64  # Add arm64
```

---

## ✅ Kontrolli Tulemusi

Peale workflow'de seadistamist:

- [ ] **CI Workflow:**
  - [ ] Lint passes
  - [ ] Tests pass (Node.js 18, 20)
  - [ ] Docker image builds
  - [ ] Image pushes Docker Hub'i

- [ ] **CD Workflow:**
  - [ ] develop → dev (auto)
  - [ ] staging → staging (auto)
  - [ ] main → prod (manual approval)

- [ ] **Rollback Workflow:**
  - [ ] Manual trigger works
  - [ ] Rollback eelmisele revision'ile
  - [ ] Rollback konkreetsele revision'ile

- [ ] **Secrets:**
  - [ ] Docker Hub secrets
  - [ ] KUBECONFIG per environment
  - [ ] REPLICAS per environment

---

## 🐛 Troubleshooting

### CI fails - lint errors

**Lahendus:**

```bash
# Fix locally
npm run lint:fix
git add .
git commit -m "Fix lint errors"
git push
```

---

### CD fails - kubeconfig invalid

**Diagnoos:**

```bash
# Decode secret
echo "BASE64_STRING" | base64 -d > kubeconfig-test.yaml

# Test
kubectl --kubeconfig=kubeconfig-test.yaml get nodes
```

**Lahendus:**

```bash
# Generate new kubeconfig
kubectl config view --flatten --minify > kubeconfig-new.yaml

# Base64 encode
cat kubeconfig-new.yaml | base64 -w 0

# Update GitHub secret
```

---

### Rollback fails - no history

**Põhjus:** Deployment pole veel update'tud (no history).

**Lahendus:**

Ensure `--record` flag deployment'is:

```yaml
kubectl set image ... --record
```

---

## 📚 Viited

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Jest Testing Framework](https://jestjs.io/)
- [ESLint](https://eslint.org/)

---

## 🎉 Summary

Oled loonud täieliku CI/CD pipeline:

✅ **CI:** Lint → Test → Build → Push
✅ **CD:** Deploy → Multi-environment → Manual approval
✅ **Rollback:** Manual rollback strategy

**Next steps:**
- Lab 6: Monitoring & Logging (Prometheus + Grafana)

---

**Õnnitleme! Sul on nüüd production-ready CI/CD pipeline! 🚀**
