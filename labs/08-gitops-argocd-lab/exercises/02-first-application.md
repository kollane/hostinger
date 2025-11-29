# Harjutus 2: First Application Deployment with ArgoCD

**Kestus:** 60 minutit
**Eesmärk:** Deploy user-service GitOps workflow'ga kasutades ArgoCD.

---

## 📋 Ülevaade

Selles harjutuses deployime **user-service** (Lab 5'st) ArgoCD kaudu. See asendab käsitsi `kubectl apply` käsud GitOps workflow'ga, kus Git repository on single source of truth.

**Traditional Deployment (Lab 5):**
```bash
# Manual kubectl apply (problematic!)
kubectl apply -f user-service-deployment.yaml -n production
kubectl apply -f user-service-service.yaml -n production
```

**GitOps Deployment (Lab 8):**
```bash
# 1. Push manifests to Git
git add k8s/
git commit -m "Add user-service manifests"
git push

# 2. ArgoCD automatically detects changes and syncs
# No kubectl needed!
```

**Miks see parem?**
- ✅ Git history = deployment history (audit trail)
- ✅ Rollback = git revert (triviaalne)
- ✅ No kubectl credentials in CI/CD (turvalisem)
- ✅ Self-healing (kui keegi teeb manual kubectl apply, ArgoCD reverting back)
- ✅ Multi-cluster deployment (same manifest, multiple clusters)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua ArgoCD Application manifest
- ✅ Deploy'da rakendus Git repository'st
- ✅ Kasutada manual vs automatic sync strategies
- ✅ Mõista Application health ja sync status
- ✅ Teostada rollback Git'i kaudu
- ✅ Integreerida ArgoCD Lab 5 CI/CD workflow'ga
- ✅ Debuggida deployment issues ArgoCD UI'st

---

## 🏗️ GitOps Workflow Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│              GitOps Workflow (CI + CD Separated)                 │
│                                                                  │
│  Developer                                                       │
│      │                                                           │
│      │ git push                                                  │
│      ▼                                                           │
│  ┌────────────────┐                                             │
│  │  Git Repository│                                             │
│  │  (hostinger)   │                                             │
│  └────┬───────┬───┘                                             │
│       │       │                                                 │
│       │       │                                                 │
│       │       └──────────────────────┐                          │
│       │                              │                          │
│       │ webhook                      │ watches                  │
│       ▼                              ▼                          │
│  ┌─────────────┐              ┌──────────────┐                 │
│  │  GitHub     │              │   ArgoCD     │                 │
│  │  Actions    │              │   (watches   │                 │
│  │  (CI)       │              │    k8s/)     │                 │
│  └──────┬──────┘              └──────┬───────┘                 │
│         │                            │                          │
│         │ docker build               │                          │
│         │ docker push                │ kubectl apply            │
│         ▼                            ▼                          │
│  ┌──────────────┐            ┌────────────────┐                │
│  │  Docker Hub  │            │  Kubernetes    │                │
│  │  (images)    │            │  Cluster       │                │
│  └──────────────┘            └────────────────┘                │
│                                                                  │
│  CI builds image → ArgoCD deploys from Git                      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Key Points:**
- **CI (GitHub Actions):** Builds Docker image, pushes to registry
- **CD (ArgoCD):** Deploys Kubernetes manifests from Git
- **Separation of concerns:** CI doesn't need kubectl credentials
- **Git as source of truth:** Kubernetes state matches Git state

---

## 📝 Sammud

### Samm 1: Prepare Git Repository Structure

ArgoCD vajab korrastatud manifest directory't.

**Recommended structure:**

```bash
# In your hostinger repository
mkdir -p k8s/user-service/base
mkdir -p k8s/user-service/overlays/development
mkdir -p k8s/user-service/overlays/staging
mkdir -p k8s/user-service/overlays/production

# Tree view:
k8s/
└── user-service/
    ├── base/                    # Common manifests
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── kustomization.yaml
    └── overlays/                # Environment-specific
        ├── development/
        │   └── kustomization.yaml
        ├── staging/
        │   └── kustomization.yaml
        └── production/
            └── kustomization.yaml
```

**Note:** Kustomize täpsemalt Exercise 3's. Praegu kasutame lihtsat structure.

---

### Samm 2: Create Base Manifests

**Create deployment manifest:**

```bash
cat > k8s/user-service/base/deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        version: v1
    spec:
      serviceAccountName: user-service  # From Lab 7 RBAC
      
      containers:
        - name: user-service
          image: YOUR_DOCKERHUB_USERNAME/user-service:latest  # Replace!
          
          ports:
            - containerPort: 3000
              name: http
          
          env:
            # Database connection
            - name: DB_HOST
              value: postgres
            - name: DB_PORT
              value: "5432"
            - name: DB_NAME
              value: userdb
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-secret  # From Lab 7 Sealed Secrets
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            
            # JWT
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: jwt-secret  # From Lab 7
                  key: secret
            - name: JWT_EXPIRES_IN
              value: "24h"
            
            # Application
            - name: PORT
              value: "3000"
            - name: NODE_ENV
              value: "production"
          
          # Health checks (Lab 4)
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
          
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
          
          # Resources (Lab 4)
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
YAML
```

**Create service manifest:**

```bash
cat > k8s/user-service/base/service.yaml << 'YAML'
apiVersion: v1
kind: Service
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  type: ClusterIP
  ports:
    - port: 3000
      targetPort: 3000
      protocol: TCP
      name: http
  selector:
    app: user-service
YAML
```

**Create kustomization (optional for now):**

```bash
cat > k8s/user-service/base/kustomization.yaml << 'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

# Common labels
commonLabels:
  app.kubernetes.io/name: user-service
  app.kubernetes.io/managed-by: argocd
YAML
```

---

### Samm 3: Commit Manifests to Git

```bash
# Add files
git add k8s/user-service/

# Commit
git commit -m "Add user-service Kubernetes manifests for ArgoCD"

# Push to remote
git push origin main
```

**Verify Git repository:**
```bash
# Check remote
git ls-remote --heads origin
```

---

### Samm 4: Create ArgoCD Application (Method 1: CLI)

**Create application via CLI:**

```bash
# Create application
argocd app create user-service \
  --project default \
  --repo https://github.com/YOUR_USERNAME/hostinger.git \
  --path k8s/user-service/base \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production \
  --sync-policy manual

# Verify creation
argocd app list

# Get details
argocd app get user-service
```

**Expected output:**
```
Name:               user-service
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          production
URL:                https://localhost:8080/applications/user-service
Repo:               https://github.com/YOUR_USERNAME/hostinger.git
Target:             HEAD
Path:               k8s/user-service/base
SyncWindow:         Sync Allowed
Sync Policy:        Manual
Sync Status:        OutOfSync from HEAD (abc123)
Health Status:      Missing
```

**Key fields:**
- `Sync Status: OutOfSync` - Git != Kubernetes (normal for new app)
- `Health Status: Missing` - Resources don't exist yet
- `Sync Policy: Manual` - Requires explicit sync command

---

### Samm 5: Create ArgoCD Application (Method 2: Declarative YAML)

**Preferred method:** Application as code.

```bash
cat > argocd-apps/user-service.yaml << 'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service
  namespace: argocd
  
  # Finalizer for cascading delete
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  # Project (logical grouping)
  project: default
  
  # Source (Git repository)
  source:
    repoURL: https://github.com/YOUR_USERNAME/hostinger.git
    targetRevision: HEAD  # or specific branch/tag
    path: k8s/user-service/base
  
  # Destination (Kubernetes cluster)
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  # Sync policy
  syncPolicy:
    # Manual sync (safer for production)
    # automated:
    #   prune: true    # Delete resources not in Git
    #   selfHeal: true # Revert manual kubectl changes
    
    # Sync options
    syncOptions:
      - CreateNamespace=false  # Don't create namespace (already exists)
      - PruneLast=true         # Delete resources last during sync
    
    # Retry strategy
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
YAML
```

**Apply Application manifest:**

```bash
# Create Application
kubectl apply -f argocd-apps/user-service.yaml

# Verify
argocd app get user-service
```

**Commit Application manifest to Git (GitOps all the way!):**

```bash
git add argocd-apps/user-service.yaml
git commit -m "Add ArgoCD Application for user-service"
git push
```

---

### Samm 6: Sync Application (Manual)

**Via CLI:**

```bash
# Sync application
argocd app sync user-service

# Watch sync progress
argocd app sync user-service --async
argocd app wait user-service --timeout 300
```

**Expected output:**
```
TIMESTAMP                  GROUP        KIND   NAMESPACE                  NAME    STATUS    HEALTH        HOOK  MESSAGE
2025-01-15T10:30:00+00:00            Service  production          user-service   Synced   Healthy              service/user-service created
2025-01-15T10:30:01+00:00   apps  Deployment  production          user-service   Synced  Progressing            deployment.apps/user-service created
...
2025-01-15T10:30:30+00:00   apps  Deployment  production          user-service   Synced   Healthy              deployment.apps/user-service healthy
```

**Via UI:**
1. Open ArgoCD UI (http://localhost:8080)
2. Click "user-service" application
3. Click "Sync" button
4. Review changes (Deployment, Service)
5. Click "Synchronize"
6. Watch deployment progress (graphical view)

---

### Samm 7: Verify Deployment

**Check application status:**

```bash
# ArgoCD status
argocd app get user-service

# Expected:
# Sync Status:   Synced to HEAD (abc123)
# Health Status: Healthy
```

**Check Kubernetes resources:**

```bash
# Pods
kubectl get pods -n production | grep user-service

# Deployment
kubectl get deployment user-service -n production

# Service
kubectl get service user-service -n production

# Logs
kubectl logs -n production deployment/user-service --tail=50
```

**Test application:**

```bash
# Port-forward
kubectl port-forward svc/user-service -n production 3000:3000 &

# Health check
curl http://localhost:3000/health

# Expected: {"status":"ok"}
```

---

### Samm 8: Make Changes and Sync

Test GitOps workflow: muuda manifesti Git'is, ArgoCD detects.

**Update replica count:**

```bash
# Edit deployment
vim k8s/user-service/base/deployment.yaml

# Change:
spec:
  replicas: 3  # Was 2

# Commit
git add k8s/user-service/base/deployment.yaml
git commit -m "Scale user-service to 3 replicas"
git push
```

**ArgoCD detects OutOfSync:**

```bash
# Check status (should show OutOfSync)
argocd app get user-service

# Output:
# Sync Status: OutOfSync from HEAD (new commit abc456)
```

**Sync again:**

```bash
# Manual sync
argocd app sync user-service

# Verify
kubectl get pods -n production | grep user-service
# Should see 3 pods now
```

---

### Samm 9: Enable Automatic Sync (Optional)

**Update Application to auto-sync:**

```bash
# Edit Application manifest
vim argocd-apps/user-service.yaml

# Add syncPolicy.automated:
spec:
  syncPolicy:
    automated:
      prune: true     # Delete resources not in Git
      selfHeal: true  # Revert manual changes

# Apply
kubectl apply -f argocd-apps/user-service.yaml
```

**Test auto-sync:**

```bash
# Make change in Git
vim k8s/user-service/base/deployment.yaml
# Change replicas: 4

git add k8s/user-service/base/deployment.yaml
git commit -m "Scale to 4 replicas"
git push

# ArgoCD automatically syncs (wait ~3 minutes)
argocd app wait user-service --sync

# Verify
kubectl get pods -n production | grep user-service
# Should see 4 pods automatically
```

---

### Samm 10: Test Self-Healing

Self-healing reverting manual kubectl changes.

**Make manual change:**

```bash
# Manual kubectl scale (WRONG in GitOps!)
kubectl scale deployment user-service -n production --replicas=10

# Check pods
kubectl get pods -n production | grep user-service
# Should see 10 pods initially
```

**ArgoCD detects drift:**

```bash
# Check status
argocd app get user-service

# Output:
# Sync Status: OutOfSync (live state differs from Git)
```

**ArgoCD self-heals (if automated sync enabled):**

```bash
# Wait ~3 minutes, ArgoCD reverts to Git state (replicas: 4)
argocd app wait user-service --health

# Verify
kubectl get pods -n production | grep user-service
# Should be back to 4 pods (from Git)
```

**Lesson:** GitOps enforces Git as single source of truth. Manual kubectl changes are reverted.

---

### Samm 11: Rollback via Git

Rollback on triviaalne Git'is.

**Scenario:** New version has bug, rollback to previous.

```bash
# Update image tag
vim k8s/user-service/base/deployment.yaml

# Change:
image: YOUR_USERNAME/user-service:v2.0.0  # Buggy version

# Commit
git add k8s/user-service/base/deployment.yaml
git commit -m "Deploy user-service v2.0.0"
git push

# ArgoCD syncs (automated or manual)
argocd app sync user-service
```

**Discover bug, rollback:**

```bash
# Git revert (creates new commit undoing changes)
git revert HEAD

# Or git reset (rewrites history - avoid in shared repos)
# git reset --hard HEAD~1
# git push --force

# Push revert
git push

# ArgoCD syncs rollback automatically (if automated)
argocd app wait user-service --sync

# Verify
kubectl describe deployment user-service -n production | grep Image
# Should show previous image tag
```

**Audit trail:**
```bash
# Git history = deployment history
git log --oneline k8s/user-service/base/deployment.yaml
```

---

### Samm 12: View Application in ArgoCD UI

**Graphical visualization:**

1. Open ArgoCD UI: http://localhost:8080
2. Click "user-service" application
3. View application tree:
   - Application (root)
   - ├── Deployment (user-service)
   - │   └── ReplicaSet
   - │       └── Pods (3x)
   - └── Service (user-service)
4. Color coding:
   - Green: Healthy and Synced
   - Yellow: Progressing
   - Red: Degraded or OutOfSync

**Inspect resources:**
- Click Deployment → View YAML, Events, Logs
- Click Pod → View Logs in real-time
- Click Service → View Endpoints

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Git repository structure created (k8s/user-service/)
- [ ] Manifests committed to Git (deployment, service)
- [ ] ArgoCD Application created (CLI or YAML)
- [ ] Application synced successfully
- [ ] All resources Healthy in ArgoCD
- [ ] Application accessible (port-forward test)
- [ ] Changes synced from Git (replica count test)
- [ ] Rollback tested (git revert)
- [ ] UI visualization viewed

### Verifitseerimine

```bash
# 1. Check ArgoCD Application
argocd app get user-service
# Sync Status: Synced
# Health Status: Healthy

# 2. Check Kubernetes resources
kubectl get all -n production | grep user-service

# 3. Test application
curl http://localhost:3000/health

# 4. Check Git history
git log --oneline k8s/user-service/

# 5. View in UI
# http://localhost:8080 → user-service → should be green
```

---

## 🔍 Troubleshooting

### Probleem: Application OutOfSync but Git hasn't changed

**Sümptomid:**
```
Sync Status: OutOfSync
```

**Põhjus:** Manual kubectl changes or ConfigMap/Secret updates.

**Lahendus:**

```bash
# Check diff
argocd app diff user-service

# If manual change, sync to revert:
argocd app sync user-service

# Or update Git to match desired state
```

---

### Probleem: Deployment Progressing but never Healthy

**Sümptomid:**
```
Health Status: Progressing (stuck)
```

**Lahendus:**

```bash
# Check pods
kubectl get pods -n production | grep user-service

# If CrashLoopBackOff:
kubectl logs -n production deployment/user-service

# Common issues:
# - Database connection failed (check secrets)
# - Image pull failed (check image tag)
# - Readiness probe failing (check /health endpoint)

# Fix manifest in Git, commit, sync
```

---

### Probleem: "Application has invalid source"

**Sümptomid:**
```
ComparisonError: repository not found
```

**Lahendus:**

```bash
# Check repository connection
argocd repo list

# If repository not connected, add:
argocd repo add https://github.com/YOUR_USERNAME/hostinger.git \
  --username YOUR_USERNAME \
  --password YOUR_GITHUB_PAT

# Verify path exists in Git
git ls-tree -r HEAD k8s/user-service/base/
```

---

### Probleem: Sync fails with "namespace does not exist"

**Sümptomid:**
```
namespace "production" not found
```

**Lahendus:**

```bash
# Create namespace manually (Lab 5 should have created it)
kubectl create namespace production

# Or enable CreateNamespace in Application:
# syncOptions:
#   - CreateNamespace=true
```

---

## 📚 Mida Sa Õppisid?

✅ **ArgoCD Application CRD**
  - Application manifest structure
  - Source (Git), Destination (K8s cluster)
  - Sync policies (manual vs automated)

✅ **GitOps Workflow**
  - Git as single source of truth
  - Declarative configuration
  - Audit trail via Git history
  - Rollback = git revert

✅ **Sync Strategies**
  - Manual sync (safer, explicit)
  - Automated sync (convenient, faster)
  - Self-healing (enforce Git state)
  - Pruning (delete orphaned resources)

✅ **Integration with Lab 5**
  - CI builds image (GitHub Actions)
  - CD deploys manifest (ArgoCD)
  - Separation of concerns

---

## 🚀 Järgmised Sammud

**Exercise 3: Multi-Environment Deployments** - Kustomize base + overlays:
- Development environment (2 replicas, debug logging)
- Staging environment (3 replicas, staging DB)
- Production environment (5 replicas, production DB, resource limits)
- Single ArgoCD Application per environment

```bash
cat exercises/03-multi-environment.md
```

---

## 💡 GitOps Best Practices

✅ **Manifest Organization:**
- Base manifests (common)
- Environment overlays (specific)
- Keep manifests DRY (Don't Repeat Yourself)

✅ **Sync Policies:**
- Start with manual sync (learn the flow)
- Use automated sync for dev/staging
- Use sync windows for production (deploy only during business hours)

✅ **Secrets Management:**
- Never commit plain secrets to Git
- Use Sealed Secrets (Lab 7) or External Secrets Operator
- Reference secrets via secretKeyRef

✅ **Version Control:**
- Commit messages describe what changed and why
- Tag releases (git tag v1.0.0)
- Use branches for testing changes (deploy from feature branch first)

✅ **Monitoring:**
- Watch ArgoCD metrics in Prometheus (Lab 6)
- Set alerts for OutOfSync applications
- Monitor sync duration and failures

---

**Õnnitleme! Esimene rakendus deployitud GitOps workflow'ga! 🚀✅**

**Kestus:** 60 minutit
**Järgmine:** Exercise 3 - Multi-Environment Deployments

