# Peatükk 17: Kubernetes Deployment Automation

**Kestus:** 5 tundi
**Eeldused:** Peatükk 15-16 (GitHub Actions, Docker Build), Peatükk 9-13 (Kubernetes core)
**Eesmärk:** Automatiseerida Kubernetes deployment workflow CI/CD'is

---

## Õpieesmärgid

- kubectl apply GitHub Actions'is
- Kubeconfig management ja turvalisus
- Self-hosted runners Kubernetes'es
- Blue-green ja canary deployments
- Rollback automation
- Multi-environment (dev, staging, prod)
- GitOps kontseptsioon (ArgoCD preview)

---

## 17.1 Manual vs Automated Deployment

### Manual Workflow (❌ Aeglane, viga-altis)

```bash
# Developer workstation - iga deploy jaoks
git pull origin main
docker build -t myorg/backend:1.0 .
docker push myorg/backend:1.0

# SSH to K8s master
ssh production
kubectl set image deployment/backend backend=myorg/backend:1.0
kubectl rollout status deployment/backend

# Wait... Check logs...
kubectl logs -f deployment/backend
```

**Probleemid:**
- ❌ Manual steps (unustame version number'i muuta)
- ❌ Pole testitud (deploy untested code?)
- ❌ Downtime risk (manual mistakes)
- ❌ Pole auditit (kes deploy'is, millal?)
- ❌ Rollback raske (must manually revert)

---

### Automated Workflow (✅ Kiire, usaldusväärt)

```
Git push → GitHub Actions:
  1. Run tests
  2. Build Docker image
  3. Scan image (Trivy)
  4. Push to registry
  5. Update Kubernetes manifest (new image tag)
  6. kubectl apply -f deployment.yaml
  7. Wait for rollout (readiness probes)
  8. Run smoke tests
  9. Notify Slack (deploy success/failure)

Time: 5-7 minutes (fully automated)
Auditeeritud: Git history + GitHub Actions logs
Rollback: git revert → auto-deploy previous version
```

---

## 17.2 kubectl in GitHub Actions

### Setup Kubeconfig

**Problem:** GitHub Actions runner ei tea cluster'ist

**Solution:** Store kubeconfig as Secret

**1. Get kubeconfig from K3s:**

```bash
# K3s master node
sudo cat /etc/rancher/k3s/k3s.yaml

# Output:
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS...
    server: https://127.0.0.1:6443  # ⚠️ Change to public IP!
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
users:
- name: default
  user:
    client-certificate-data: LS0tLS...
    client-key-data: LS0tLS...
```

**2. Modify server URL:**

```yaml
# Change:
server: https://127.0.0.1:6443

# To (public IP or domain):
server: https://YOUR_VPS_IP:6443
# Or:
server: https://k8s.example.com:6443
```

**3. Encode kubeconfig (Base64):**

```bash
cat k3s.yaml | base64 -w 0 > kubeconfig-base64.txt
```

**4. Add to GitHub Secrets:**

```
GitHub repository → Settings → Secrets → Actions → New secret

Name: KUBECONFIG_BASE64
Value: <paste base64 content>
```

---

### GitHub Actions Workflow - Basic Deploy

```yaml
# .github/workflows/k8s-deploy.yml
name: Deploy to Kubernetes

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      # Setup kubectl
      - name: Install kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'v1.28.0'

      # Setup kubeconfig
      - name: Set up kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG_BASE64 }}" | base64 -d > $HOME/.kube/config
          chmod 600 $HOME/.kube/config

      # Verify connection
      - name: Test kubectl
        run: kubectl get nodes

      # Deploy
      - name: Deploy to Kubernetes
        run: |
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml

      # Wait for rollout
      - name: Wait for rollout
        run: kubectl rollout status deployment/backend --timeout=5m
```

**Trigger:**

```bash
git add k8s/deployment.yaml
git commit -m "Update deployment"
git push origin main

# GitHub Actions deploys automatically!
```

---

## 17.3 Dynamic Image Tag Updates

### Problem: Hardcoded Image Tag

**k8s/deployment.yaml:**

```yaml
spec:
  containers:
  - name: backend
    image: myorg/backend:1.0  # ❌ Hardcoded! Must manually edit
```

**Problem:** Every deploy requires editing YAML file (error-prone)

---

### Solution 1: sed (Simple)

```yaml
# GitHub Actions workflow
- name: Update image tag
  run: |
    SHA=$(git rev-parse --short HEAD)
    sed -i "s|image: myorg/backend:.*|image: myorg/backend:${SHA}|g" k8s/deployment.yaml
    kubectl apply -f k8s/deployment.yaml
```

**How it works:**

```bash
# Before:
image: myorg/backend:latest

# After sed:
image: myorg/backend:abc123  # Git SHA
```

---

### Solution 2: kubectl set image (Recommended)

```yaml
# GitHub Actions workflow
- name: Deploy with new image
  run: |
    SHA=$(git rev-parse --short HEAD)

    # Apply manifests (if structure changed)
    kubectl apply -f k8s/deployment.yaml

    # Update image tag (no YAML edit!)
    kubectl set image deployment/backend \
      backend=myorg/backend:${SHA} \
      --record

    # Wait for rollout
    kubectl rollout status deployment/backend
```

**Benefit:** Manifest stays unchanged, only image tag updated

---

### Solution 3: Kustomize (Advanced)

**kustomization.yaml:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

images:
  - name: myorg/backend
    newTag: abc123  # Updated by CI/CD
```

**GitHub Actions:**

```yaml
- name: Update image tag with Kustomize
  run: |
    SHA=$(git rev-parse --short HEAD)
    cd k8s

    # Update tag in kustomization.yaml
    kustomize edit set image myorg/backend:${SHA}

    # Apply
    kubectl apply -k .
```

---

## 17.4 Multi-Environment Deployments

### Environment Structure

```
Kubernetes namespaces:
  - dev (development)
  - staging (pre-production)
  - prod (production)

Deployment strategy:
  Git push → dev (auto-deploy)
  Tag release → staging (auto-deploy)
  Manual approve → prod (manual gate)
```

---

### GitHub Actions - Multi-Environment

```yaml
name: Multi-Environment Deploy

on:
  push:
    branches: [main, develop]
  release:
    types: [published]

jobs:
  # Auto-deploy to dev (develop branch)
  deploy-dev:
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
      - name: Set kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG_BASE64 }}" | base64 -d > $HOME/.kube/config
      - name: Deploy to dev
        run: |
          SHA=$(git rev-parse --short HEAD)
          kubectl set image deployment/backend \
            backend=myorg/backend:${SHA} \
            -n dev \
            --record
          kubectl rollout status deployment/backend -n dev

  # Auto-deploy to staging (main branch)
  deploy-staging:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
      - name: Set kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG_BASE64 }}" | base64 -d > $HOME/.kube/config
      - name: Deploy to staging
        run: |
          SHA=$(git rev-parse --short HEAD)
          kubectl set image deployment/backend \
            backend=myorg/backend:${SHA} \
            -n staging \
            --record
          kubectl rollout status deployment/backend -n staging

  # Manual deploy to production (release published)
  deploy-production:
    if: github.event_name == 'release'
    runs-on: ubuntu-latest
    environment: production  # Requires approval
    steps:
      - uses: actions/checkout@v4
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
      - name: Set kubeconfig
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG_BASE64 }}" | base64 -d > $HOME/.kube/config
      - name: Deploy to production
        run: |
          VERSION=${{ github.event.release.tag_name }}
          kubectl set image deployment/backend \
            backend=myorg/backend:${VERSION} \
            -n prod \
            --record
          kubectl rollout status deployment/backend -n prod
```

**Workflow:**

```
develop branch push → auto-deploy to dev namespace
main branch push → auto-deploy to staging namespace
GitHub Release published → manual approval → deploy to prod namespace
```

---

## 17.5 Blue-Green Deployments

### Concept

**Blue-Green = Zero-downtime deployment with instant rollback**

```
Initial state:
  Service → Blue deployment (v1.0, 3 Pods)
  Green deployment (v1.1, 3 Pods) exists but not serving traffic

Cutover:
  Service → Green deployment (v1.1, 3 Pods)
  Blue deployment (v1.0) still running (instant rollback!)

Cleanup (after validation):
  Delete Blue deployment (v1.0)
```

**Benefit:**
- ✅ Zero downtime (instant switch)
- ✅ Instant rollback (switch back to Blue)
- ✅ Test Green in production (before cutover)
- ❌ Double resources required (2x Pods)

---

### Implementation

**1. Blue deployment (current version):**

```yaml
# deployment-blue.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-blue
  labels:
    app: backend
    version: blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
      version: blue
  template:
    metadata:
      labels:
        app: backend
        version: blue
    spec:
      containers:
      - name: backend
        image: myorg/backend:1.0
```

**2. Service (points to Blue initially):**

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
    version: blue  # Traffic → Blue
  ports:
  - port: 3000
```

**3. Deploy Green (new version):**

```yaml
# deployment-green.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-green
  labels:
    app: backend
    version: green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
      version: green
  template:
    metadata:
      labels:
        app: backend
        version: green
    spec:
      containers:
      - name: backend
        image: myorg/backend:1.1  # New version
```

**4. Test Green (without public traffic):**

```bash
# Port-forward to Green Pod (testing)
kubectl port-forward deployment/backend-green 3000:3000

# Test: curl http://localhost:3000/health
```

**5. Switch traffic to Green:**

```bash
# Update Service selector
kubectl patch service backend -p '{"spec":{"selector":{"version":"green"}}}'

# Traffic now flows to Green deployment (v1.1)!
```

**6. Rollback (if issues):**

```bash
# Instant rollback to Blue
kubectl patch service backend -p '{"spec":{"selector":{"version":"blue"}}}'
```

**7. Cleanup (after validation):**

```bash
# Delete Blue deployment
kubectl delete deployment backend-blue
```

---

### GitHub Actions - Blue-Green

```yaml
- name: Blue-Green Deployment
  run: |
    SHA=$(git rev-parse --short HEAD)
    CURRENT=$(kubectl get service backend -o jsonpath='{.spec.selector.version}')

    # Determine next color
    if [ "$CURRENT" == "blue" ]; then
      NEXT="green"
    else
      NEXT="blue"
    fi

    # Deploy new version to NEXT deployment
    kubectl set image deployment/backend-${NEXT} \
      backend=myorg/backend:${SHA} \
      --record

    # Wait for rollout
    kubectl rollout status deployment/backend-${NEXT}

    # Switch traffic to NEXT
    kubectl patch service backend -p "{\"spec\":{\"selector\":{\"version\":\"${NEXT}\"}}}"

    echo "Deployed ${SHA} to ${NEXT} (traffic switched)"
```

📖 **Praktika:** Labor 5, Harjutus 4 - Blue-green deployment

---

## 17.6 Canary Deployments

### Concept

**Canary = Gradual rollout (test with small % of users first)**

```
Initial:
  v1.0: 100% traffic (10 Pods)

Canary:
  v1.0: 90% traffic (9 Pods)
  v1.1: 10% traffic (1 Pod) ← Canary

Validate (metrics, errors):
  If OK → increase canary
  If errors → rollback

Full rollout:
  v1.1: 100% traffic (10 Pods)
  v1.0: deleted
```

**Benefit:**
- ✅ Low risk (only 10% users affected)
- ✅ Early error detection (before full rollout)
- ✅ Gradual increase (10% → 50% → 100%)
- ❌ Complex (need traffic splitting)

---

### Implementation (Service-based)

**1. Stable deployment (v1.0):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-stable
spec:
  replicas: 9  # 90% of total
  selector:
    matchLabels:
      app: backend
      track: stable
  template:
    metadata:
      labels:
        app: backend
        track: stable
    spec:
      containers:
      - name: backend
        image: myorg/backend:1.0
```

**2. Canary deployment (v1.1):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-canary
spec:
  replicas: 1  # 10% of total
  selector:
    matchLabels:
      app: backend
      track: canary
  template:
    metadata:
      labels:
        app: backend
        track: canary
    spec:
      containers:
      - name: backend
        image: myorg/backend:1.1  # New version
```

**3. Service (both stable and canary):**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend  # Matches BOTH stable and canary
  ports:
  - port: 3000
```

**Traffic distribution:**

```
Service load balances across all Pods:
  9 Pods (stable v1.0) + 1 Pod (canary v1.1) = 10 total

Result: ~90% traffic → stable, ~10% traffic → canary
```

**4. Monitor canary (Prometheus metrics):**

```promql
# Error rate canary vs stable
rate(http_requests_total{track="canary",status=~"5.."}[5m])
/
rate(http_requests_total{track="canary"}[5m])

# If canary error rate > stable error rate → rollback!
```

**5. Gradual increase:**

```bash
# Increase canary to 50%
kubectl scale deployment/backend-stable --replicas=5
kubectl scale deployment/backend-canary --replicas=5

# Full rollout (100% canary)
kubectl scale deployment/backend-stable --replicas=0
kubectl scale deployment/backend-canary --replicas=10
```

**6. Rollback (if errors):**

```bash
# Delete canary
kubectl delete deployment backend-canary

# Scale stable back to 100%
kubectl scale deployment/backend-stable --replicas=10
```

---

### Advanced: Istio/Linkerd Traffic Splitting

**Problem:** Service-based canary is imprecise (90/10 depends on Pod count)

**Solution:** Service mesh (Istio, Linkerd) - exact % traffic control

**Istio VirtualService (exact 90/10 split):**

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend
spec:
  hosts:
  - backend
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: backend
        subset: stable
      weight: 90  # Exactly 90%
    - destination:
        host: backend
        subset: canary
      weight: 10  # Exactly 10%
```

---

## 17.7 Rollback Automation

### Automatic Rollback on Failure

**GitHub Actions - Rollback if unhealthy:**

```yaml
- name: Deploy and verify
  run: |
    SHA=$(git rev-parse --short HEAD)

    # Deploy
    kubectl set image deployment/backend backend=myorg/backend:${SHA} --record
    kubectl rollout status deployment/backend --timeout=5m

    # Wait for stabilization
    sleep 30

    # Check health
    HEALTH=$(kubectl get deployment backend -o jsonpath='{.status.availableReplicas}')
    DESIRED=$(kubectl get deployment backend -o jsonpath='{.spec.replicas}')

    if [ "$HEALTH" -lt "$DESIRED" ]; then
      echo "Deployment unhealthy! Rolling back..."
      kubectl rollout undo deployment/backend
      exit 1
    fi

    echo "Deployment successful!"
```

---

### Manual Rollback

**Rollback to previous version:**

```bash
# View rollout history
kubectl rollout history deployment/backend

# Output:
REVISION  CHANGE-CAUSE
1         kubectl set image deployment/backend backend=myorg/backend:abc123
2         kubectl set image deployment/backend backend=myorg/backend:def456
3         kubectl set image deployment/backend backend=myorg/backend:ghi789

# Rollback to previous revision
kubectl rollout undo deployment/backend

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=1
```

---

## 17.8 Self-Hosted Runners in Kubernetes

### Why Self-Hosted Runners?

**GitHub-hosted runners (default):**
- ✅ Easy (no setup)
- ❌ No access to private cluster (firewall, VPN)
- ❌ Limited resources (2 CPU, 7GB RAM)
- ❌ Slower (cold start, no cache)

**Self-hosted runners (in K8s):**
- ✅ Direct cluster access (no firewall issues)
- ✅ More resources (custom sizing)
- ✅ Faster (warm cache, local network)
- ❌ Maintenance (you manage runners)

---

### Deploy Runner in Kubernetes

**1. Create GitHub Runner Token:**

```
GitHub repository → Settings → Actions → Runners → New self-hosted runner
Copy registration token
```

**2. Deploy runner:**

```yaml
# runner-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: github-runner
spec:
  replicas: 2  # 2 concurrent runners
  selector:
    matchLabels:
      app: github-runner
  template:
    metadata:
      labels:
        app: github-runner
    spec:
      containers:
      - name: runner
        image: myoung34/github-runner:latest
        env:
        - name: REPO_URL
          value: https://github.com/myorg/myrepo
        - name: RUNNER_TOKEN
          valueFrom:
            secretKeyRef:
              name: runner-secret
              key: token
        - name: RUNNER_NAME
          value: k8s-runner
        - name: RUNNER_WORKDIR
          value: /tmp/runner
        volumeMounts:
        - name: docker-socket
          mountPath: /var/run/docker.sock  # Docker-in-Docker
      volumes:
      - name: docker-socket
        hostPath:
          path: /var/run/docker.sock
```

**3. Create secret:**

```bash
kubectl create secret generic runner-secret \
  --from-literal=token=YOUR_GITHUB_RUNNER_TOKEN
```

**4. Use self-hosted runner in workflow:**

```yaml
jobs:
  deploy:
    runs-on: self-hosted  # Use self-hosted runner!
    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        run: kubectl apply -f k8s/
```

---

## 17.9 GitOps Preview - ArgoCD

### GitOps Concept

**Traditional CI/CD (push-based):**

```
GitHub Actions → kubectl apply → Kubernetes cluster
(CI/CD system pushes changes)
```

**GitOps (pull-based):**

```
Git repository (manifests) ← ArgoCD watches
                              ↓
ArgoCD detects change → applies to cluster
(ArgoCD pulls changes automatically)
```

**Benefits:**
- ✅ **Git = Single source of truth** (cluster state in Git)
- ✅ **Automatic drift detection** (manual kubectl changes reverted!)
- ✅ **Audit trail** (Git history = cluster history)
- ✅ **Rollback** (git revert = cluster rollback)

---

### ArgoCD Quick Preview

**1. Install ArgoCD:**

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**2. Access UI:**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**3. Create Application:**

```yaml
# argocd-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/myrepo
    targetRevision: main
    path: k8s  # Folder with manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true  # Delete resources not in Git
      selfHeal: true  # Auto-sync if drift detected
```

**Apply:**

```bash
kubectl apply -f argocd-app.yaml
```

**Result:**
- ArgoCD watches `k8s/` folder in Git
- Any Git push → ArgoCD auto-syncs cluster
- Manual `kubectl` changes → ArgoCD reverts (self-heal!)

📖 **Praktika:** Labor 5, Harjutus 5 - GitOps with ArgoCD (optional)

---

## Kokkuvõte

**Kubernetes Deployment Automation:**
- **kubectl in CI/CD:** Kubeconfig as Secret, kubectl apply/set image
- **Dynamic image tags:** sed, kubectl set image, Kustomize
- **Multi-environment:** Namespaces (dev, staging, prod), approval gates
- **Blue-Green:** Zero downtime, instant rollback, 2x resources
- **Canary:** Gradual rollout (10% → 50% → 100%), low risk
- **Rollback:** Automatic (health check fail), manual (kubectl rollout undo)
- **Self-hosted runners:** K8s Deployment, direct cluster access
- **GitOps:** ArgoCD (pull-based), Git = source of truth

**GitHub Actions tools:**
- `azure/setup-kubectl@v3` - kubectl installation
- Kubeconfig from Secret (base64 encoded)
- Environment protection rules (manual approval for prod)

**Deployment strategies comparison:**

| Strategy | Downtime | Risk | Complexity | Resources |
|----------|----------|------|------------|-----------|
| **Rolling update** | None | Medium | Low | 1x |
| **Blue-Green** | None | Low | Medium | 2x |
| **Canary** | None | Very low | High | 1.1x-1.5x |
| **Recreate** | Yes | High | Very low | 1x |

**Best practices:**
- ✅ Never hardcode image tags (use Git SHA)
- ✅ Use readiness probes (rollout health check)
- ✅ Set resource limits (prevent resource exhaustion)
- ✅ Use namespaces (dev, staging, prod separation)
- ✅ Require approval for production (GitHub Environments)
- ✅ Monitor deployments (Prometheus alerts)
- ❌ Never kubectl apply from local workstation (use CI/CD)
- ❌ Never use :latest in production

---

**DevOps Vaatenurk:**

```bash
# Check rollout status
kubectl rollout status deployment/backend

# Pause rollout (if issues)
kubectl rollout pause deployment/backend

# Resume rollout
kubectl rollout resume deployment/backend

# Rollback
kubectl rollout undo deployment/backend

# History
kubectl rollout history deployment/backend

# Restart deployment (force Pod recreation)
kubectl rollout restart deployment/backend

# Manual image update
kubectl set image deployment/backend backend=myorg/backend:abc123 --record
```

---

**Järgmised Sammud:**
**Peatükk 18:** Prometheus ja Metrics (monitoring)
**Peatükk 20:** Logging ja Log Aggregation (Loki)

📖 **Praktika:** Labor 5 - Kubernetes Deployment Automation, Blue-Green, Canary, GitOps
