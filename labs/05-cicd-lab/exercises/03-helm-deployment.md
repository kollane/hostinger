# Harjutus 3: Helm Deployment Automation

**Kestus:** 60 minutit
**Eesmärk:** Automatiseeri Kubernetes deployment Helm'iga

---

## 📋 Ülevaade

Selles harjutuses **automatiseerid Kubernetes deployment'i** kasutades Lab 4 Helm chart'e. Lood CD (Continuous Deployment) workflow'i, mis:
- Käivitub peale CI success'i
- Deploy'b automaatselt õigesse environment'i
- Kasutab Helm upgrade --atomic (zero-downtime)
- Verifitseerib deployment'i health check'idega

**CD = Continuous Deployment:**
- Automaatne deploy peale successful CI'i
- Multi-environment support (dev/staging/prod)
- Rollback automaatselt kui deploy fail
- Zero-downtime

---

## 🎯 Õpieesmärgid

- ✅ Seadistada kubeconfig GitHub Secrets'is
- ✅ Luua CD workflow Helm'iga
- ✅ Multi-environment deployment
- ✅ Health check automation
- ✅ Automatic rollback

---

## 🏗️ Arhitektuur

```
CI Success
   │
   ▼
┌────────────────────────────────────────────┐
│  CD Workflow (.github/workflows/cd.yml)    │
│                                            │
│  Job 1: Determine Environment             │
│  ├─ develop → development                 │
│  ├─ staging → staging                     │
│  └─ main    → production                  │
│      │                                     │
│      ▼                                     │
│  Job 2: Deploy                            │
│  ├─ Setup kubectl + Helm                  │
│  ├─ Configure kubeconfig                  │
│  ├─ helm upgrade --install                │
│  │   --values values-{env}.yaml           │
│  │   --set image.tag=$SHA                │
│  │   --atomic                             │
│  ├─ Wait for rollout                      │
│  ├─ Health check                          │
│  └─ Rollback on failure ✓                 │
│                                            │
└────────────────────────────────────────────┘
   │
   ▼
Kubernetes Cluster
├─ Namespace: development
├─ Namespace: staging
└─ Namespace: production
```

---

## 📝 Sammud

### Samm 1: Kopeeri Helm Chart (5 min)

```bash
# Navigate to repository
cd user-service-cicd

# Copy Helm chart from Lab 4
cp -r ../labs/04-kubernetes-advanced-lab/solutions/helm/user-service helm-chart

# Verify
ls helm-chart/
# Should see: Chart.yaml, values.yaml, templates/, values-dev.yaml, etc.
```

### Samm 2: Seadista KUBECONFIG Secret (10 min)

**Generate base64 kubeconfig:**

```bash
# Encode your kubeconfig
cat ~/.kube/config | base64 -w 0

# Copy output
```

**Lisa GitHub Secrets:**

GitHub → Settings → Secrets → Actions → New repository secret:

```
Name: KUBECONFIG
Secret: <paste base64 encoded kubeconfig>
```

**Test kubeconfig:**

```bash
# Decode and test
echo "PASTE_BASE64_HERE" | base64 -d > /tmp/test-kubeconfig
export KUBECONFIG=/tmp/test-kubeconfig
kubectl cluster-info
```

### Samm 3: Loo Namespaces (5 min)

```bash
# Create namespaces for each environment
kubectl create namespace development
kubectl create namespace staging
kubectl create namespace production

# Verify
kubectl get namespaces
```

### Samm 4: Loo CD Workflow (25 min)

**Loo `.github/workflows/cd.yml`:**

```yaml
name: Continuous Deployment

on:
  workflow_run:
    workflows: ["Continuous Integration"]
    types: [completed]
    branches: [main, develop, staging]
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
  HELM_CHART_PATH: helm-chart

jobs:
  # ========================================
  # Determine Environment
  # ========================================
  determine-environment:
    name: 🎯 Determine Environment
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' || github.event_name == 'workflow_dispatch' }}

    outputs:
      environment: ${{ steps.set-env.outputs.environment }}
      image_tag: ${{ steps.set-env.outputs.image_tag }}

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🎯 Set environment and image tag
        id: set-env
        run: |
          if [[ "${{ github.event_name }}" == "workflow_dispatch" ]]; then
            ENV="${{ inputs.environment }}"
            TAG="${{ github.ref_name }}-${{ github.sha }}"
          elif [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            ENV="production"
            TAG="main-${{ github.sha }}"
          elif [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
            ENV="staging"
            TAG="staging-${{ github.sha }}"
          elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
            ENV="development"
            TAG="develop-${{ github.sha }}"
          else
            echo "❌ Unknown branch"
            exit 1
          fi

          echo "environment=$ENV" >> $GITHUB_OUTPUT
          echo "image_tag=$TAG" >> $GITHUB_OUTPUT

          echo "🎯 Environment: $ENV"
          echo "🏷️  Image Tag: $TAG"

  # ========================================
  # Deploy to Kubernetes
  # ========================================
  deploy:
    name: 🚀 Deploy to ${{ needs.determine-environment.outputs.environment }}
    runs-on: ubuntu-latest
    needs: determine-environment
    timeout-minutes: 10

    environment:
      name: ${{ needs.determine-environment.outputs.environment }}

    steps:
      - name: 📥 Checkout code
        uses: actions/checkout@v4

      - name: 🔧 Setup kubectl
        uses: azure/setup-kubectl@v4
        with:
          version: 'v1.31.0'

      - name: ⎈ Setup Helm
        uses: azure/setup-helm@v4
        with:
          version: 'v3.16.0'

      - name: 🔐 Configure kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG }}" | base64 -d > $HOME/.kube/config
          chmod 600 $HOME/.kube/config

      - name: ✅ Verify cluster connection
        run: |
          kubectl cluster-info
          kubectl get nodes

      - name: 🚀 Deploy with Helm
        run: |
          ENV="${{ needs.determine-environment.outputs.environment }}"
          TAG="${{ needs.determine-environment.outputs.image_tag }}"

          # Determine environment-specific values
          if [[ "$ENV" == "production" ]]; then
            VALUES_FILE="values-prod.yaml"
            REPLICAS=3
          elif [[ "$ENV" == "staging" ]]; then
            VALUES_FILE="values-staging.yaml"
            REPLICAS=2
          else
            VALUES_FILE="values-dev.yaml"
            REPLICAS=1
          fi

          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "🚀 Deploying with Helm"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "🌐 Environment: $ENV"
          echo "📦 Image: ${{ env.IMAGE_NAME }}:$TAG"
          echo "📋 Values: $VALUES_FILE"
          echo "🔢 Replicas: $REPLICAS"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

          # Create namespace if not exists
          kubectl create namespace $ENV --dry-run=client -o yaml | kubectl apply -f -

          # Helm upgrade with atomic rollback
          helm upgrade --install user-service \
            ${{ env.HELM_CHART_PATH }} \
            --namespace=$ENV \
            --values ${{ env.HELM_CHART_PATH }}/$VALUES_FILE \
            --set image.tag=$TAG \
            --set image.repository=${{ env.IMAGE_NAME }} \
            --set replicaCount=$REPLICAS \
            --wait \
            --timeout=5m \
            --atomic

          echo "✅ Deployment successful!"

      - name: 📊 Verify deployment
        run: |
          ENV="${{ needs.determine-environment.outputs.environment }}"

          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "📊 Deployment Status"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

          # Deployment info
          kubectl get deployment user-service -n $ENV

          # Pods
          kubectl get pods -l app=user-service -n $ENV

          # Current image
          kubectl get deployment user-service -n $ENV \
            -o jsonpath='{.spec.template.spec.containers[0].image}'
          echo ""

      - name: 🏥 Health check
        run: |
          ENV="${{ needs.determine-environment.outputs.environment }}"

          echo "🏥 Performing health check..."

          # Get a pod name
          POD=$(kubectl get pod -n $ENV -l app=user-service -o jsonpath='{.items[0].metadata.name}')

          # Health check with retry
          for i in {1..5}; do
            HTTP_CODE=$(kubectl exec -n $ENV $POD -- wget -qO- http://localhost:3000/health 2>/dev/null | grep -o "healthy" || echo "fail")
            
            if [ "$HTTP_CODE" == "healthy" ]; then
              echo "✅ Health check passed!"
              exit 0
            fi

            echo "⚠️  Retry $i/5..."
            sleep 5
          done

          echo "❌ Health check failed"
          exit 1

      - name: 📝 Deployment summary
        if: always()
        run: |
          ENV="${{ needs.determine-environment.outputs.environment }}"
          TAG="${{ needs.determine-environment.outputs.image_tag }}"

          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "           🎉 Deployment Complete!          "
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "🌐 Environment: $ENV"
          echo "📦 Image: ${{ env.IMAGE_NAME }}:$TAG"
          echo "📊 Helm Release: user-service"
          echo "🕐 Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

### Samm 5: Test CD Workflow (15 min)

**5a. Test development deploy:**

```bash
# Create develop branch
git checkout -b develop

# Push
git push -u origin develop

# Vaata workflow
# GitHub → Actions → "Continuous Deployment"
```

**5b. Test manual deploy:**

GitHub → Actions → "Continuous Deployment" → Run workflow → Select environment

**5c. Verify deployment:**

```bash
# Check pods
kubectl get pods -n development

# Check helm release
helm list -n development

# Health check
kubectl port-forward -n development svc/user-service 3000:3000

# Another terminal
curl http://localhost:3000/health
```

✅ **Kontrolli:** Pod on running, health check OK

---

## ✅ Kontrolli Tulemusi

- [ ] KUBECONFIG secret seadistatud
- [ ] Namespaces loodud (dev/staging/prod)
- [ ] CD workflow loodud
- [ ] Develop branch auto-deploy toimib
- [ ] Manual deploy toimib
- [ ] Health check passes
- [ ] Helm release visible (`helm list`)

---

## 🎓 Õpitud Mõisted

**Helm Upgrade:**
- `--install` - Install if not exists
- `--atomic` - Rollback on failure
- `--wait` - Wait for ready state

**Environment Strategy:**
- Branch-based deployment
- develop → development
- staging → staging
- main → production

**Health Checks:**
- Post-deployment validation
- Retry logic (5 attempts)
- Fails deployment if unhealthy

---

## 💡 Best Practices

1. **Atomic upgrades** - Auto rollback on failure
2. **Wait flag** - Ensure pods ready
3. **Health checks** - Verify after deploy
4. **Environment isolation** - Separate namespaces
5. **Image tagging** - branch-sha format
6. **Timeout** - Prevent hung deployments

---

## 🐛 Troubleshooting

### Helm upgrade fails?

```bash
# Check helm history
helm history user-service -n development

# Check pod logs
kubectl logs -n development -l app=user-service

# Rollback manually
helm rollback user-service -n development
```

### kubeconfig error?

```bash
# Verify secret is base64 encoded
echo "$KUBECONFIG_SECRET" | base64 -d | head

# Test connection
kubectl cluster-info
```

### Health check fails?

```bash
# Check pod status
kubectl get pods -n development

# Check logs
kubectl logs -n development <pod-name>

# Manual health check
kubectl exec -n development <pod-name> -- wget -qO- http://localhost:3000/health
```

---

## 🔗 Järgmine Samm

Järgmises harjutuses lisad **quality gates ja testing**!

**Jätka:** [Harjutus 4: Quality Gates](04-quality-gates.md)

---

## 📚 Viited

- [Helm Upgrade](https://helm.sh/docs/helm/helm_upgrade/)
- [Azure Setup Helm Action](https://github.com/Azure/setup-helm)
- [Kubectl Action](https://github.com/Azure/setup-kubectl)

---

**Õnnitleme! CD pipeline on valmis! 🎉**
