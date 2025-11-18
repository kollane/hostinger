# Harjutus 5: Multi-Environment Pipeline

**Kestus:** 60 minutit
**Eesmärk:** Luua multi-environment CI/CD pipeline (dev, staging, production)

---

## 📋 Ülevaade

Selles harjutuses õpid looma eraldi environment'e development, staging ja production jaoks. **Iga environment'il on oma deployment strateegia, secrets ja approval gate'd.**

**Multi-environment pipeline** võimaldab:
- ✅ Testa koodi dev environment'is enne staging'u
- ✅ Verifitseerida staging environment'is enne production'i
- ✅ Manual approval production deployment'ide jaoks
- ✅ Environment-specific configuration (DB URLs, API keys)
- ✅ Rollback strateegia iga environment'i jaoks

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Seadistada GitHub Environments (dev, staging, prod)
- ✅ Implementeerida branch-based deployment
- ✅ Kasutada environment-specific secrets
- ✅ Lisada manual approval gate'sid
- ✅ Luua rollback workflow
- ✅ Implementeerida deployment notifications
- ✅ Hallata multi-environment kubeconfig'e

---

## 🏗️ Arhitektuur

```
┌───────────────────────────────────────────────────────┐
│              GitHub Repository                        │
│                                                       │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │   develop   │  │   staging    │  │     main    │ │
│  │   branch    │  │   branch     │  │   branch    │ │
│  └──────┬──────┘  └───────┬──────┘  └──────┬──────┘ │
│         │                 │                 │        │
│         ▼                 ▼                 ▼        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  │ Auto Deploy  │  │ Auto Deploy  │  │ Manual       │
│  │ dev env      │  │ staging env  │  │ Approval     │
│  └──────┬───────┘  └───────┬──────┘  └──────┬───────┘
│         │                  │                 │        │
└─────────┼──────────────────┼─────────────────┼────────┘
          │                  │                 │
          ▼                  ▼                 ▼
    ┌──────────┐       ┌──────────┐     ┌──────────┐
    │   Dev    │       │ Staging  │     │   Prod   │
    │ Cluster  │       │ Cluster  │     │ Cluster  │
    │          │       │          │     │ ⚠️ Gated │
    │ 1 replica│       │ 2 replicas│    │ 3 replicas│
    └──────────┘       └──────────┘     └──────────┘
```

---

## 📝 Sammud

### Samm 1: Loo Git Branch'id (5 min)

**Loo development ja staging branch'id:**

```bash
# Loo develop branch
git checkout -b develop
git push origin develop

# Loo staging branch
git checkout -b staging
git push origin staging

# Tagasi main'i
git checkout main

# Kontrolli branch'e
git branch -a

# Peaks näitama:
#   develop
#   staging
# * main
#   remotes/origin/develop
#   remotes/origin/staging
#   remotes/origin/main
```

---

### Samm 2: Seadista GitHub Environments (10 min)

**Loo 3 environment'i GitHub'is:**

1. Mine repository → **Settings** → **Environments**
2. Kliki **New environment**

**Environment 1: development**

- Name: `development`
- Deployment branches: `Selected branches` → `develop`
- Environment secrets:
  - `KUBECONFIG` (dev cluster kubeconfig)
  - `REPLICAS` = `1`
- **No protection rules**

**Environment 2: staging**

- Name: `staging`
- Deployment branches: `Selected branches` → `staging`
- Environment secrets:
  - `KUBECONFIG` (staging cluster kubeconfig)
  - `REPLICAS` = `2`
- **No protection rules**

**Environment 3: production**

- Name: `production`
- Deployment branches: `Selected branches` → `main`
- Environment secrets:
  - `KUBECONFIG` (prod cluster kubeconfig)
  - `REPLICAS` = `3`
- **Protection rules:**
  - ✅ **Required reviewers:** (vali enda GitHub username)
  - ⏱️ **Wait timer:** 5 minutes

**Environment secrets ülevaade:**

```
development:
  - KUBECONFIG (dev cluster)
  - REPLICAS = 1

staging:
  - KUBECONFIG (staging cluster)
  - REPLICAS = 2

production:
  - KUBECONFIG (prod cluster)
  - REPLICAS = 3
  - 🔒 Manual approval required
```

---

### Samm 3: Loo Multi-Environment Deploy Workflow (15 min)

**Loo workflow mitme environment'iga:**

Muuda `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Environment

on:
  push:
    branches:
      - develop    # Auto-deploy to dev
      - staging    # Auto-deploy to staging
      - main       # Manual approval to prod
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - development
          - staging
          - production

env:
  IMAGE_NAME: ${{ secrets.DOCKER_USERNAME }}/user-service

jobs:
  determine-environment:
    runs-on: ubuntu-latest
    outputs:
      environment: ${{ steps.set-env.outputs.environment }}
    steps:
      - name: Determine environment
        id: set-env
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            echo "environment=${{ inputs.environment }}" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "environment=production" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
            echo "environment=staging" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
            echo "environment=development" >> $GITHUB_OUTPUT
          fi

  deploy:
    runs-on: ubuntu-latest
    needs: determine-environment
    environment:
      name: ${{ needs.determine-environment.outputs.environment }}
      url: https://${{ needs.determine-environment.outputs.environment }}.example.com

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.28.0'

      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > $HOME/.kube/config
          chmod 600 $HOME/.kube/config

      - name: Deploy to ${{ needs.determine-environment.outputs.environment }}
        run: |
          ENV=${{ needs.determine-environment.outputs.environment }}
          REPLICAS=${{ secrets.REPLICAS || 2 }}

          echo "🚀 Deploying to $ENV environment"
          echo "📦 Replicas: $REPLICAS"
          echo "🖼️  Image: ${{ env.IMAGE_NAME }}:${{ github.sha }}"

          # Update deployment
          kubectl set image deployment/user-service \
            user-service=${{ env.IMAGE_NAME }}:sha-${{ github.sha }} \
            --namespace=$ENV \
            --record

          # Scale to environment-specific replicas
          kubectl scale deployment/user-service \
            --replicas=$REPLICAS \
            --namespace=$ENV

      - name: Wait for rollout
        run: |
          ENV=${{ needs.determine-environment.outputs.environment }}
          kubectl rollout status deployment/user-service \
            --namespace=$ENV \
            --timeout=5m

          echo "✅ Rollout completed in $ENV"

      - name: Verify deployment
        run: |
          ENV=${{ needs.determine-environment.outputs.environment }}

          echo "📊 Deployment status:"
          kubectl get deployment user-service --namespace=$ENV
          kubectl get pods -l app=user-service --namespace=$ENV

      - name: Health check
        run: |
          ENV=${{ needs.determine-environment.outputs.environment }}

          kubectl port-forward deployment/user-service 3000:3000 --namespace=$ENV &
          PID=$!
          sleep 5

          HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")
          kill $PID

          if [ "$HTTP_CODE" == "200" ]; then
            echo "✅ Health check passed in $ENV"
          else
            echo "❌ Health check failed in $ENV"
            exit 1
          fi

      - name: Deployment summary
        run: |
          ENV=${{ needs.determine-environment.outputs.environment }}

          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "🎉 Deployment to $ENV successful!"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "📦 Image: ${{ env.IMAGE_NAME }}:sha-${{ github.sha }}"
          echo "🔢 Replicas: $(kubectl get deployment user-service --namespace=$ENV -o jsonpath='{.spec.replicas}')"
          echo "✅ Available: $(kubectl get deployment user-service --namespace=$ENV -o jsonpath='{.status.availableReplicas}')"
          echo "🌐 Environment: $ENV"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Commit:**

```bash
git add .github/workflows/deploy.yml
git commit -m "Add multi-environment deployment workflow"
git push origin main
git push origin develop
git push origin staging
```

---

### Samm 4: Testi Development Deployment (5 min)

**Push develop branch'i:**

```bash
git checkout develop
echo "// Dev change $(date)" >> server.js
git add server.js
git commit -m "Test dev deployment"
git push origin develop
```

**Vaata Actions:**

1. "Deploy to Environment" workflow käivitub
2. Environment: `development`
3. **Auto-deploy** (no approval)
4. Replicas: 1

**Oodatud väljund:**

```
✅ Determine environment
   environment=development

✅ Deploy to development
   🚀 Deploying to development environment
   📦 Replicas: 1
   🖼️  Image: user-service:sha-abc123

✅ Wait for rollout
   deployment "user-service" successfully rolled out
   ✅ Rollout completed in development

✅ Deployment summary
   🎉 Deployment to development successful!
   📦 Image: user-service:sha-abc123
   🔢 Replicas: 1
   🌐 Environment: development
```

---

### Samm 5: Testi Staging Deployment (5 min)

**Merge develop → staging:**

```bash
git checkout staging
git merge develop
git push origin staging
```

**Vaata Actions:**

1. "Deploy to Environment" workflow käivitub
2. Environment: `staging`
3. **Auto-deploy** (no approval)
4. Replicas: 2

---

### Samm 6: Testi Production Deployment (Manual Approval) (10 min)

**Merge staging → main:**

```bash
git checkout main
git merge staging
git push origin main
```

**Vaata Actions:**

1. "Deploy to Environment" workflow käivitub
2. Environment: `production`
3. **⏸️ Waiting for approval**

**Actions tab'is:**

```
⏸️  Deploy / production
   Waiting for approval

   Review pending deployments
   [Review deployments]
```

**Approve deployment:**

1. Kliki **Review deployments**
2. Vali ✅ `production`
3. Lisa kommentaar: "Approved for production"
4. Kliki **Approve and deploy**

**Deployment jätkub:**

```
✅ Manual approval received

✅ Deploy to production
   🚀 Deploying to production environment
   📦 Replicas: 3
   🖼️  Image: user-service:sha-abc123

✅ Deployment summary
   🎉 Deployment to production successful!
   🔢 Replicas: 3
   🌐 Environment: production
```

---

### Samm 7: Loo Rollback Workflow (10 min)

**Loo rollback workflow:**

Loo fail `.github/workflows/rollback.yml`:

```yaml
name: Rollback Deployment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to rollback'
        required: true
        type: choice
        options:
          - development
          - staging
          - production
      revision:
        description: 'Revision number (leave empty for previous)'
        required: false
        type: string

jobs:
  rollback:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.28.0'

      - name: Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > $HOME/.kube/config
          chmod 600 $HOME/.kube/config

      - name: Show rollout history
        run: |
          ENV=${{ inputs.environment }}

          echo "📜 Rollout history for $ENV:"
          kubectl rollout history deployment/user-service --namespace=$ENV

      - name: Rollback deployment
        run: |
          ENV=${{ inputs.environment }}
          REVISION=${{ inputs.revision }}

          if [ -z "$REVISION" ]; then
            echo "⏮️  Rolling back to previous revision in $ENV"
            kubectl rollout undo deployment/user-service --namespace=$ENV
          else
            echo "⏮️  Rolling back to revision $REVISION in $ENV"
            kubectl rollout undo deployment/user-service --namespace=$ENV --to-revision=$REVISION
          fi

      - name: Wait for rollback
        run: |
          ENV=${{ inputs.environment }}
          kubectl rollout status deployment/user-service --namespace=$ENV --timeout=5m

          echo "✅ Rollback completed in $ENV"

      - name: Verify rollback
        run: |
          ENV=${{ inputs.environment }}

          echo "📊 Current deployment:"
          kubectl get deployment user-service --namespace=$ENV
          kubectl get pods -l app=user-service --namespace=$ENV

          # Show current image
          IMAGE=$(kubectl get deployment user-service --namespace=$ENV -o jsonpath='{.spec.template.spec.containers[0].image}')
          echo "🖼️  Current image: $IMAGE"

      - name: Health check
        run: |
          ENV=${{ inputs.environment }}

          kubectl port-forward deployment/user-service 3000:3000 --namespace=$ENV &
          PID=$!
          sleep 5

          HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health || echo "000")
          kill $PID

          if [ "$HTTP_CODE" == "200" ]; then
            echo "✅ Health check passed after rollback"
          else
            echo "❌ Health check failed after rollback"
            exit 1
          fi

      - name: Rollback summary
        run: |
          ENV=${{ inputs.environment }}

          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "⏮️  Rollback in $ENV successful!"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          kubectl get deployment user-service --namespace=$ENV
```

**Commit:**

```bash
git add .github/workflows/rollback.yml
git commit -m "Add rollback workflow"
git push origin main
```

---

### Samm 8: Testi Rollback (5 min)

**Trigger rollback workflow:**

1. Actions tab → **Rollback Deployment**
2. Kliki **Run workflow**
3. Vali:
   - Environment: `staging`
   - Revision: (leave empty for previous)
4. Kliki **Run workflow**

**Oodatud väljund:**

```
✅ Show rollout history
   📜 Rollout history for staging:
   REVISION  CHANGE-CAUSE
   1         ...
   2         ...
   3         ...

✅ Rollback deployment
   ⏮️  Rolling back to previous revision in staging
   deployment.apps/user-service rolled back

✅ Wait for rollback
   deployment "user-service" successfully rolled out
   ✅ Rollback completed in staging

✅ Rollback summary
   ⏮️  Rollback in staging successful!
   NAME           READY   UP-TO-DATE   AVAILABLE   AGE
   user-service   2/2     2            2           10m
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Git branch'id:**
  - [ ] `develop` (auto-deploy dev)
  - [ ] `staging` (auto-deploy staging)
  - [ ] `main` (manual approval prod)

- [ ] **GitHub Environments:**
  - [ ] `development` (no protection)
  - [ ] `staging` (no protection)
  - [ ] `production` (required reviewers)

- [ ] **Environment secrets:**
  - [ ] `KUBECONFIG` (per environment)
  - [ ] `REPLICAS` (1, 2, 3)

- [ ] **Workflows:**
  - [ ] `.github/workflows/deploy.yml` (multi-env)
  - [ ] `.github/workflows/rollback.yml`

- [ ] **Deployment strateegia:**
  - [ ] develop → dev (auto)
  - [ ] staging → staging (auto)
  - [ ] main → prod (manual approval)

---

## 🐛 Troubleshooting

### Probleem 1: Production approval timeout

**Sümptom:**
```
⏸️  Waiting for approval
   ⏱️  Review timed out
```

**Lahendus:**

Settings → Environments → production → Edit:
- **Wait timer:** Increase to 60 minutes

---

### Probleem 2: Wrong environment deployed

**Sümptom:**

Push to `develop` → deployed to `staging`

**Diagnoos:**

Branch protection rules või workflow trigger vale.

**Lahendus:**

`.github/workflows/deploy.yml`:

```yaml
on:
  push:
    branches:
      - develop   # Only dev
      - staging   # Only staging
      - main      # Only prod
```

---

### Probleem 3: Rollback ebaõnnestub

**Sümptom:**
```
❌ Rollback deployment
   error: no rollout history found
```

**Põhjus:**

Deployment pole veel update'tud (no history).

**Lahendus:**

Ensure `--record` flag deployment'is:

```bash
kubectl set image ... --record
```

---

## 🎓 Õpitud Mõisted

### Multi-Environment:
- **Development:** Arendajate testimiseks (unstable)
- **Staging:** Pre-production testimine (stable, prod-like)
- **Production:** Live environment (stable, high availability)

### Deployment Strategies:
- **Branch-based:** Branch = environment (`develop` → dev)
- **Auto-deploy:** Automaatne deployment peale push'i
- **Manual approval:** Nõuab inimese kinnitust
- **Rollback:** Tagasi eelmisele versioonile

### GitHub Environments:
- **Environment secrets:** Environment-specific secrets
- **Protection rules:** Required reviewers, wait timer
- **Deployment branches:** Millised branch'id võivad deploy'da

---

## 💡 Parimad Tavad

1. **3 environment'i minimum** - dev, staging, prod
2. **Manual approval production'is** - Vältimaks automaatseid vigu
3. **Environment-specific secrets** - Erinev DB per environment
4. **Branch protection** - `main` branch protected
5. **Staging = production copy** - Testida prod-like environment'is
6. **Rollback strateegia** - Kiire tagasipööramine
7. **Deployment notifications** - Slack/Discord alerts
8. **Blue-Green deployment** - Zero-downtime (advanced)
9. **Canary deployment** - Partial rollout (advanced)
10. **Monitor after deploy** - Health checks, logs, metrics

---

## 🔗 Järgmine Samm

**Õnnitleme!** Oled loonud täieliku CI/CD pipeline:

✅ Code push → Lint → Test → Build → Deploy (multi-env) → Rollback

Järgmine samm: **Labor 6 - Monitoring & Logging**

Seal õpid:
- Prometheus metrics
- Grafana dashboards
- Log aggregation (Loki)
- Alerting

**Jätka:** [Labor 6: Monitoring & Logging](../../06-monitoring-logging-lab/README.md)

---

## 📚 Viited

### GitHub:
- [Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [Required reviewers](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#required-reviewers)
- [Environment secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-an-environment)

### Deployment Strategies:
- [Blue-Green Deployment](https://kubernetes.io/blog/2018/04/30/zero-downtime-deployment-kubernetes-jenkins/)
- [Canary Deployment](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments)

---

**Õnnitleme! Sul on nüüd production-ready multi-environment CI/CD pipeline! 🎉🚀**
