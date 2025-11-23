# Harjutus 3: Multi-Environment Deployments with Kustomize

**Kestus:** 60 minutit
**Eesmärk:** Halda mitmeid environment'e (dev, staging, production) Kustomize ja ArgoCD abil.

---

## 📋 Ülevaade

Selles harjutuses konfigureerime **multi-environment deployment** kasutades **Kustomize** - Kubernetes native configuration management tool. Kustomize võimaldab jagada common manifeste (base) ja customiseerida neid environment-spetsiifiliselt (overlays).

**Probleem ilma Kustomize'ta:**
```bash
# Duplicate manifests iga environment'i jaoks
k8s/user-service-dev.yaml    # 200 lines, 90% identical
k8s/user-service-staging.yaml # 200 lines, 90% identical
k8s/user-service-prod.yaml   # 200 lines, 90% identical

# Nightmare to maintain!
```

**Lahendus Kustomize'ga:**
```bash
# DRY (Don't Repeat Yourself)
k8s/user-service/base/         # Common config (once)
k8s/user-service/overlays/dev/ # Only differences
k8s/user-service/overlays/staging/
k8s/user-service/overlays/production/
```

**Miks Kustomize?**
- ✅ Kubernetes native (built into kubectl)
- ✅ No templating (pure YAML, no {{variables}})
- ✅ Overlay pattern (base + patches)
- ✅ Environment-specific customization
- ✅ ArgoCD native support
- ✅ Git-friendly (clear diffs)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

✅ Luua Kustomize base manifests
✅ Luua environment-specific overlays
✅ Kasutada Kustomize patches (strategic merge, JSON)
✅ Customiseerida replicas, resources, env vars per environment
✅ Deploy'da multiple environments ArgoCD'ga
✅ Mõista Kustomize vs Helm tradeoffs
✅ Integreerida Sealed Secrets (Lab 7) per environment

---

## 🏗️ Kustomize Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                 Kustomize Base + Overlays                      │
│                                                                │
│  k8s/user-service/                                             │
│  │                                                             │
│  ├── base/                        ← Common manifests          │
│  │   ├── deployment.yaml          (shared by all envs)        │
│  │   ├── service.yaml                                         │
│  │   └── kustomization.yaml                                   │
│  │                                                             │
│  └── overlays/                                                │
│      │                                                         │
│      ├── development/             ← Dev-specific              │
│      │   ├── kustomization.yaml   (2 replicas, debug)         │
│      │   └── patch-deployment.yaml                            │
│      │                                                         │
│      ├── staging/                 ← Staging-specific          │
│      │   ├── kustomization.yaml   (3 replicas, staging DB)    │
│      │   └── patch-deployment.yaml                            │
│      │                                                         │
│      └── production/              ← Prod-specific             │
│          ├── kustomization.yaml   (5 replicas, prod DB, HPA)  │
│          ├── patch-deployment.yaml                            │
│          └── hpa.yaml             (autoscaling)               │
│                                                                │
│  ArgoCD Applications:                                          │
│  ├── user-service-dev     → overlays/development              │
│  ├── user-service-staging → overlays/staging                  │
│  └── user-service-prod    → overlays/production               │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**
- **Base:** Common configuration (deployment, service)
- **Overlay:** Environment-specific patches
- **Patch:** Modifications to base (strategic merge or JSON patch)
- **Kustomization:** Defines how to combine base + patches

---

## 📝 Sammud

### Samm 1: Restructure Repository (Base)

Loome base manifests kõigile environment'idele.

**Create base directory:**

```bash
mkdir -p k8s/user-service/base
cd k8s/user-service/base
```

**Create base deployment:**

```bash
cat > deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  replicas: 2  # Default (overridden by overlays)
  
  selector:
    matchLabels:
      app: user-service
  
  template:
    metadata:
      labels:
        app: user-service
    
    spec:
      serviceAccountName: user-service
      
      containers:
        - name: user-service
          image: YOUR_DOCKERHUB_USERNAME/user-service:latest
          
          ports:
            - containerPort: 3000
              name: http
          
          env:
            # These will be overridden by overlays
            - name: DB_HOST
              value: postgres
            - name: DB_PORT
              value: "5432"
            - name: DB_NAME
              value: userdb
            - name: NODE_ENV
              value: "production"
            - name: PORT
              value: "3000"
          
          # Health checks
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
          
          # Resources (minimal - overlays will customize)
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
YAML
```

**Create base service:**

```bash
cat > service.yaml << 'YAML'
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

**Create base kustomization:**

```bash
cat > kustomization.yaml << 'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Resources
resources:
  - deployment.yaml
  - service.yaml

# Common labels (added to all resources)
commonLabels:
  app.kubernetes.io/name: user-service
  app.kubernetes.io/managed-by: argocd

# Common annotations
commonAnnotations:
  managed-by: kustomize
YAML
```

---

### Samm 2: Create Development Overlay

Development environment: minimal resources, debug logging.

**Create overlay directory:**

```bash
mkdir -p k8s/user-service/overlays/development
cd k8s/user-service/overlays/development
```

**Create development kustomization:**

```bash
cat > kustomization.yaml << 'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Namespace
namespace: development

# Base
bases:
  - ../../base

# Name prefix (optional)
namePrefix: dev-

# Labels specific to development
commonLabels:
  environment: development

# Replica count override
replicas:
  - name: user-service
    count: 1  # Single replica for dev

# Patches
patches:
  # Strategic merge patch for deployment
  - path: patch-deployment.yaml
    target:
      kind: Deployment
      name: user-service

# ConfigMap generator (dev-specific config)
configMapGenerator:
  - name: user-service-config
    literals:
      - LOG_LEVEL=debug
      - ENABLE_DEBUG=true
YAML
```

**Create development patch:**

```bash
cat > patch-deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  template:
    spec:
      containers:
        - name: user-service
          # Development-specific env vars
          env:
            - name: NODE_ENV
              value: "development"
            - name: LOG_LEVEL
              value: "debug"
            - name: DB_HOST
              value: postgres.development.svc.cluster.local
          
          # Lower resource limits for dev
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 200m
              memory: 256Mi
YAML
```

**Test kustomize build:**

```bash
# Preview generated manifests
kubectl kustomize k8s/user-service/overlays/development

# Should show merged base + dev overlay
```

---

### Samm 3: Create Staging Overlay

Staging: more replicas, staging DB, closer to production.

**Create overlay directory:**

```bash
mkdir -p k8s/user-service/overlays/staging
cd k8s/user-service/overlays/staging
```

**Create staging kustomization:**

```bash
cat > kustomization.yaml << 'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: staging

bases:
  - ../../base

namePrefix: staging-

commonLabels:
  environment: staging

# Staging replicas
replicas:
  - name: user-service
    count: 2

patches:
  - path: patch-deployment.yaml
    target:
      kind: Deployment
      name: user-service

configMapGenerator:
  - name: user-service-config
    literals:
      - LOG_LEVEL=info
      - ENABLE_DEBUG=false
YAML
```

**Create staging patch:**

```bash
cat > patch-deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  template:
    spec:
      containers:
        - name: user-service
          env:
            - name: NODE_ENV
              value: "staging"
            - name: LOG_LEVEL
              value: "info"
            - name: DB_HOST
              value: postgres.staging.svc.cluster.local
          
          # Staging resources (moderate)
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
YAML
```

---

### Samm 4: Create Production Overlay

Production: high replicas, strict resources, HPA, production DB.

**Create overlay directory:**

```bash
mkdir -p k8s/user-service/overlays/production
cd k8s/user-service/overlays/production
```

**Create production kustomization:**

```bash
cat > kustomization.yaml << 'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

bases:
  - ../../base

namePrefix: prod-

commonLabels:
  environment: production

# Production replicas (HPA will override)
replicas:
  - name: user-service
    count: 3

patches:
  - path: patch-deployment.yaml
    target:
      kind: Deployment
      name: user-service

# Additional resources (HPA)
resources:
  - hpa.yaml

configMapGenerator:
  - name: user-service-config
    literals:
      - LOG_LEVEL=warn
      - ENABLE_DEBUG=false
      - RATE_LIMIT=1000
YAML
```

**Create production patch:**

```bash
cat > patch-deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  template:
    spec:
      containers:
        - name: user-service
          env:
            - name: NODE_ENV
              value: "production"
            - name: LOG_LEVEL
              value: "warn"
            - name: DB_HOST
              value: postgres.production.svc.cluster.local
            
            # Production secrets (Sealed Secrets from Lab 7)
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: jwt-secret
                  key: secret
          
          # Production resources (strict)
          resources:
            requests:
              cpu: 200m
              memory: 256Mi
            limits:
              cpu: 1000m
              memory: 1Gi
YAML
```

**Create HPA (Lab 4 integration):**

```bash
cat > hpa.yaml << 'YAML'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  
  minReplicas: 3
  maxReplicas: 10
  
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
YAML
```

---

### Samm 5: Commit Kustomize Structure to Git

```bash
# Add all overlays
git add k8s/user-service/

# Commit
git commit -m "Add Kustomize base and overlays for multi-environment deployment"

# Push
git push origin main
```

**Verify structure:**

```bash
tree k8s/user-service/

# Output:
# k8s/user-service/
# ├── base
# │   ├── deployment.yaml
# │   ├── kustomization.yaml
# │   └── service.yaml
# └── overlays
#     ├── development
#     │   ├── kustomization.yaml
#     │   └── patch-deployment.yaml
#     ├── production
#     │   ├── hpa.yaml
#     │   ├── kustomization.yaml
#     │   └── patch-deployment.yaml
#     └── staging
#         ├── kustomization.yaml
#         └── patch-deployment.yaml
```

---

### Samm 6: Create ArgoCD Applications (Per Environment)

**Create ArgoCD Application for Development:**

```bash
cat > argocd-apps/user-service-dev.yaml << 'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service-dev
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/hostinger.git
    targetRevision: HEAD
    path: k8s/user-service/overlays/development  # Dev overlay
  
  destination:
    server: https://kubernetes.default.svc
    namespace: development
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true  # Auto-sync for dev
    
    syncOptions:
      - CreateNamespace=false
YAML
```

**Create ArgoCD Application for Staging:**

```bash
cat > argocd-apps/user-service-staging.yaml << 'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service-staging
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/hostinger.git
    targetRevision: HEAD
    path: k8s/user-service/overlays/staging  # Staging overlay
  
  destination:
    server: https://kubernetes.default.svc
    namespace: staging
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
```

**Create ArgoCD Application for Production:**

```bash
cat > argocd-apps/user-service-prod.yaml << 'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service-prod
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/hostinger.git
    targetRevision: HEAD
    path: k8s/user-service/overlays/production  # Production overlay
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    # Manual sync for production (safer!)
    # automated:
    #   prune: true
    #   selfHeal: true
    
    syncOptions:
      - CreateNamespace=false
YAML
```

**Apply all Applications:**

```bash
# Apply all at once
kubectl apply -f argocd-apps/

# Verify
argocd app list

# Should see:
# user-service-dev
# user-service-staging
# user-service-prod
```

---

### Samm 7: Sync All Environments

**Sync via CLI:**

```bash
# Sync development (automated, should auto-sync)
argocd app sync user-service-dev

# Sync staging
argocd app sync user-service-staging

# Sync production (manual)
argocd app sync user-service-prod
```

**Verify deployments:**

```bash
# Development
kubectl get pods -n development | grep user-service
# Should see 1 pod (dev overlay: replicas=1)

# Staging
kubectl get pods -n staging | grep user-service
# Should see 2 pods

# Production
kubectl get pods -n production | grep user-service
# Should see 3 pods (HPA may scale to more)
```

---

### Samm 8: Test Environment-Specific Configuration

**Verify environment variables:**

```bash
# Development - should have NODE_ENV=development
kubectl exec -n development deployment/dev-user-service -- env | grep NODE_ENV

# Staging
kubectl exec -n staging deployment/staging-user-service -- env | grep NODE_ENV

# Production
kubectl exec -n production deployment/prod-user-service -- env | grep NODE_ENV
```

**Verify resource limits:**

```bash
# Production should have higher limits
kubectl describe pod -n production -l app=user-service | grep -A5 "Limits"

# Development should have lower limits
kubectl describe pod -n development -l app=user-service | grep -A5 "Limits"
```

---

### Samm 9: Promote Changes Across Environments

Workflow: Dev → Staging → Production.

**Scenario:** Change image tag to v2.0.0.

**Step 1: Update base image:**

```bash
# Edit base deployment
vim k8s/user-service/base/deployment.yaml

# Change:
image: YOUR_USERNAME/user-service:v2.0.0

# Commit
git add k8s/user-service/base/deployment.yaml
git commit -m "Update user-service to v2.0.0"
git push
```

**Step 2: ArgoCD auto-syncs dev and staging:**

```bash
# Wait for auto-sync (or manual sync)
argocd app wait user-service-dev --sync
argocd app wait user-service-staging --sync

# Verify version
kubectl get pods -n development -o jsonpath='{.items[0].spec.containers[0].image}'
# Should show: YOUR_USERNAME/user-service:v2.0.0
```

**Step 3: Test in dev and staging, then sync production:**

```bash
# After testing, manually sync production
argocd app sync user-service-prod

# Monitor rollout
kubectl rollout status deployment/prod-user-service -n production
```

---

### Samm 10: Advanced Kustomize Features

**JSON Patch (more precise than strategic merge):**

```yaml
# In kustomization.yaml
patchesJson6902:
  - target:
      group: apps
      version: v1
      kind: Deployment
      name: user-service
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 5
      - op: add
        path: /spec/template/spec/containers/0/env/-
        value:
          name: CUSTOM_VAR
          value: "custom-value"
```

**Image tag management (GitOps-friendly):**

```yaml
# In kustomization.yaml
images:
  - name: YOUR_USERNAME/user-service
    newTag: v2.0.0  # Override image tag
```

**Secret references (Sealed Secrets from Lab 7):**

```yaml
# In kustomization.yaml
secretGenerator:
  - name: db-credentials
    files:
      - username=secrets/db-username.txt
      - password=secrets/db-password.txt
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Kustomize base created (deployment, service, kustomization)
- [ ] Development overlay created (1 replica, debug)
- [ ] Staging overlay created (2 replicas, staging DB)
- [ ] Production overlay created (3+ replicas, HPA, prod DB)
- [ ] All overlays committed to Git
- [ ] 3 ArgoCD Applications created (dev, staging, prod)
- [ ] All environments synced successfully
- [ ] Environment-specific config verified (env vars, resources)
- [ ] Promotion workflow tested (dev → staging → prod)

### Verifitseerimine

```bash
# 1. Test Kustomize builds
kubectl kustomize k8s/user-service/overlays/development
kubectl kustomize k8s/user-service/overlays/staging
kubectl kustomize k8s/user-service/overlays/production

# 2. Check ArgoCD Applications
argocd app list

# 3. Verify pods in each namespace
kubectl get pods -n development | grep user-service
kubectl get pods -n staging | grep user-service
kubectl get pods -n production | grep user-service

# 4. Check replica counts
kubectl get deployment -n development dev-user-service
kubectl get deployment -n staging staging-user-service
kubectl get deployment -n production prod-user-service

# 5. Verify HPA (production only)
kubectl get hpa -n production
```

---

## 🔍 Troubleshooting

### Probleem: Kustomize build fails

**Sümptomid:**
```
Error: unable to find one of 'kustomization.yaml'
```

**Lahendus:**

```bash
# Ensure kustomization.yaml exists in overlay directory
ls k8s/user-service/overlays/development/kustomization.yaml

# Check YAML syntax
kubectl kustomize k8s/user-service/overlays/development

# Common issue: wrong base path
# In kustomization.yaml:
bases:
  - ../../base  # Relative path from overlay directory
```

---

### Probleem: ArgoCD shows "ComparisonError"

**Sümptomid:**
```
ComparisonError: kustomize build failed
```

**Lahendus:**

```bash
# Check ArgoCD repo-server logs
kubectl logs -n argocd deployment/argocd-repo-server

# Test kustomize build locally
kubectl kustomize k8s/user-service/overlays/production

# Fix YAML syntax errors, commit, push
```

---

### Probleem: Patches not applied

**Sümptomid:**
- Environment-specific values not reflected in pods

**Lahendus:**

```bash
# Verify patch syntax (strategic merge vs JSON)
kubectl kustomize k8s/user-service/overlays/production | grep -A10 "env:"

# Ensure patch targets correct resource
# In kustomization.yaml:
patches:
  - path: patch-deployment.yaml
    target:
      kind: Deployment
      name: user-service  # Must match base name
```

---

## 📚 Mida Sa Õppisid?

✅ **Kustomize Fundamentals**
  - Base manifests (DRY)
  - Overlays (environment-specific)
  - Patches (strategic merge, JSON)
  - Generators (ConfigMap, Secret)

✅ **Multi-Environment Strategy**
  - Development (1 replica, debug, auto-sync)
  - Staging (2 replicas, testing, auto-sync)
  - Production (3+ replicas, HPA, manual sync)

✅ **GitOps Promotion**
  - Change in base → all environments
  - Test in dev → staging → production
  - Git history = deployment audit trail

✅ **ArgoCD Integration**
  - One Application per environment
  - Same repo, different paths (overlays)
  - Automated vs manual sync per environment

---

## 🚀 Järgmised Sammud

**Exercise 4: Advanced GitOps Workflows** - ApplicationSet ja Argo Rollouts:
- ApplicationSet (generate Applications from templates)
- Argo Rollouts (Canary deployments, Blue-Green)
- Progressive delivery
- Automated promotion gates

```bash
cat exercises/04-advanced-workflows.md
```

---

## 💡 Kustomize Best Practices

✅ **Base Design:**
- Keep base minimal (only common config)
- Use sensible defaults
- Avoid environment-specific values in base

✅ **Overlay Design:**
- Each overlay completely independent
- Environment-specific patches only
- Clear naming (dev, staging, production)

✅ **Patch Strategy:**
- Use strategic merge for simple changes (env vars, replicas)
- Use JSON patch for complex modifications
- Keep patches small and focused

✅ **Version Control:**
- Commit base and overlays together
- Tag releases (git tag v1.0.0)
- Use branches for testing overlay changes

✅ **Testing:**
- Always test `kubectl kustomize` before committing
- Preview generated manifests
- Verify in dev before staging/production

---

**Õnnitleme! Multi-environment deployment Kustomize'ga! 🚀🌍**

**Kestus:** 60 minutit
**Järgmine:** Exercise 4 - Advanced GitOps Workflows

