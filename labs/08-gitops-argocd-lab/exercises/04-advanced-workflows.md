# Harjutus 4: Advanced GitOps Workflows (ApplicationSet & Argo Rollouts)

**Kestus:** 60 minutit
**Eesmärk:** Implementeeri advanced GitOps patterns: ApplicationSet ja Canary deployments Argo Rollouts'ga.

---

## 📋 Ülevaade

Selles harjutuses õpime kahte advanced ArgoCD feature't:

1. **ApplicationSet** - Automaatselt genereeri ArgoCD Applications template'idest
2. **Argo Rollouts** - Progressive delivery (Canary, Blue-Green deployments)

**Probleem ilma ApplicationSet'ta:**
```yaml
# Duplicate Application manifests:
argocd-apps/user-service-dev.yaml      # 90% identical
argocd-apps/user-service-staging.yaml  # 90% identical
argocd-apps/user-service-prod.yaml     # 90% identical
argocd-apps/todo-service-dev.yaml      # 90% identical
# ... 50+ files
```

**Lahendus ApplicationSet'ga:**
```yaml
# Single ApplicationSet generates all Applications
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: user-service-all-envs
spec:
  generators:
    - list:
        elements:
          - env: dev
          - env: staging
          - env: production
  template:
    # ... generates 3 Applications automatically
```

**Probleem traditional Deployment'ga:**
- Immediate rollout (risky!)
- No gradual traffic shift
- Hard to rollback

**Lahendus Argo Rollouts'ga:**
- Canary: 10% → 25% → 50% → 100%
- Blue-Green: instant switch with instant rollback
- Metrics-based promotion (Prometheus integration)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua ApplicationSet template'e
- ✅ Kasutada list, git, cluster generators
- ✅ Installida Argo Rollouts controller
- ✅ Luua Rollout (vs Deployment)
- ✅ Implementeerida Canary deployment strategy
- ✅ Kasutada Blue-Green deployment
- ✅ Integreerida Prometheus metrics promotion'iks
- ✅ Luua AnalysisTemplate automated testing'uks

---

## 🏗️ ApplicationSet Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                  ApplicationSet Controller                     │
│                                                                │
│  ApplicationSet Manifest (Single)                              │
│  ┌──────────────────────────────────────────┐                 │
│  │ apiVersion: argoproj.io/v1alpha1         │                 │
│  │ kind: ApplicationSet                     │                 │
│  │ spec:                                    │                 │
│  │   generators:                            │                 │
│  │     - list:                              │                 │
│  │         elements:                        │                 │
│  │           - env: dev, replicas: 1        │                 │
│  │           - env: staging, replicas: 2    │                 │
│  │           - env: prod, replicas: 5       │                 │
│  │   template:                              │                 │
│  │     spec:                                │                 │
│  │       source:                            │                 │
│  │         path: k8s/{{env}}                │                 │
│  │       destination:                       │                 │
│  │         namespace: {{env}}               │                 │
│  └──────────────────────────────────────────┘                 │
│                      │                                         │
│                      │ generates                               │
│                      ▼                                         │
│  ┌─────────────────────────────────────────────────┐          │
│  │  3 Application CRDs automatically created:      │          │
│  │  1. user-service-dev → k8s/dev                  │          │
│  │  2. user-service-staging → k8s/staging          │          │
│  │  3. user-service-prod → k8s/prod                │          │
│  └─────────────────────────────────────────────────┘          │
│                                                                │
└───────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Argo Rollouts Architecture

```
┌───────────────────────────────────────────────────────────────┐
│                    Canary Deployment                           │
│                                                                │
│  Traffic Split (Progressive):                                 │
│                                                                │
│  ┌────────────────────────────────────────────────┐           │
│  │  Initial State:                                │           │
│  │  ┌─────────────────┐                           │           │
│  │  │  Stable (v1.0)  │  100% traffic             │           │
│  │  │  5 pods         │                           │           │
│  │  └─────────────────┘                           │           │
│  └────────────────────────────────────────────────┘           │
│                                                                │
│  ┌────────────────────────────────────────────────┐           │
│  │  Step 1 (10%):                                 │           │
│  │  ┌─────────────────┐  ┌──────────────┐        │           │
│  │  │  Stable (v1.0)  │  │ Canary (v2.0)│        │           │
│  │  │  5 pods (90%)   │  │ 1 pod (10%)  │        │           │
│  │  └─────────────────┘  └──────────────┘        │           │
│  │  ← Pause → Manual promotion or auto (metrics) │           │
│  └────────────────────────────────────────────────┘           │
│                                                                │
│  ┌────────────────────────────────────────────────┐           │
│  │  Step 2 (50%):                                 │           │
│  │  ┌─────────────────┐  ┌──────────────┐        │           │
│  │  │  Stable (v1.0)  │  │ Canary (v2.0)│        │           │
│  │  │  3 pods (50%)   │  │ 3 pods (50%) │        │           │
│  │  └─────────────────┘  └──────────────┘        │           │
│  └────────────────────────────────────────────────┘           │
│                                                                │
│  ┌────────────────────────────────────────────────┐           │
│  │  Step 3 (100%):                                │           │
│  │  ┌──────────────┐                              │           │
│  │  │ Canary (v2.0)│  100% traffic                │           │
│  │  │ 5 pods       │  (Stable scaled down)        │           │
│  │  └──────────────┘                              │           │
│  └────────────────────────────────────────────────┘           │
│                                                                │
└───────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### PART 1: ApplicationSet

### Samm 1: Install ApplicationSet Controller

ApplicationSet controller oli enabled Exercise 1 Helm values'tes.

**Verify installation:**

```bash
# Check ApplicationSet controller pod
kubectl get pods -n argocd | grep applicationset

# Should see:
# argocd-applicationset-controller-xxx   1/1   Running

# Check CRD
kubectl api-resources | grep applicationset
```

**If not installed, enable in Helm values:**

```yaml
# argocd-values.yaml
applicationSet:
  enabled: true
```

---

### Samm 2: Create ApplicationSet (List Generator)

List generator: explicitly list environments.

**Create ApplicationSet manifest:**

```bash
cat > argocd-apps/applicationset-user-service.yaml << 'YAML'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: user-service-all-envs
  namespace: argocd
spec:
  # Generators define how Applications are created
  generators:
    - list:
        elements:
          # Development
          - env: development
            namespace: development
            replicas: "1"
            syncPolicy: automated
          
          # Staging
          - env: staging
            namespace: staging
            replicas: "2"
            syncPolicy: automated
          
          # Production
          - env: production
            namespace: production
            replicas: "3"
            syncPolicy: manual  # Manual for production
  
  # Template defines Application structure
  template:
    metadata:
      # Application name uses template variable
      name: 'user-service-{{env}}'
    
    spec:
      project: default
      
      source:
        repoURL: https://github.com/YOUR_USERNAME/hostinger.git
        targetRevision: HEAD
        path: 'k8s/user-service/overlays/{{env}}'  # Template variable
      
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'  # Template variable
      
      syncPolicy:
        # Use syncPolicy from generator (automated or manual)
        {{- if eq .syncPolicy "automated"}}
        automated:
          prune: true
          selfHeal: true
        {{- end}}
        
        syncOptions:
          - CreateNamespace=false
YAML
```

**Apply ApplicationSet:**

```bash
# Apply
kubectl apply -f argocd-apps/applicationset-user-service.yaml

# Verify ApplicationSet created
kubectl get applicationset -n argocd

# Verify Applications generated
argocd app list

# Should see:
# user-service-development
# user-service-staging
# user-service-production
```

**Magic!** Single ApplicationSet created 3 Applications automatically.

---

### Samm 3: ApplicationSet Git Generator

Git generator: automatically detect directories in Git.

**Example: Auto-detect all microservices:**

```bash
cat > argocd-apps/applicationset-all-services.yaml << 'YAML'
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: all-microservices
  namespace: argocd
spec:
  generators:
    - git:
        repoURL: https://github.com/YOUR_USERNAME/hostinger.git
        revision: HEAD
        directories:
          - path: k8s/*/overlays/production  # Match all services
  
  template:
    metadata:
      name: '{{path.basename}}'  # e.g., "user-service"
    
    spec:
      project: default
      
      source:
        repoURL: https://github.com/YOUR_USERNAME/hostinger.git
        targetRevision: HEAD
        path: '{{path}}'
      
      destination:
        server: https://kubernetes.default.svc
        namespace: production
      
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
YAML
```

**Use case:** Add new microservice → create `k8s/new-service/overlays/production/` → ApplicationSet auto-detects and creates Application.

---

### PART 2: Argo Rollouts

### Samm 4: Install Argo Rollouts Controller

**Install via Helm:**

```bash
# Add Argo Helm repo (already added in Exercise 1)
helm repo update

# Install Argo Rollouts
helm install argo-rollouts argo/argo-rollouts \
  --namespace argocd \
  --set dashboard.enabled=true \
  --wait

# Verify installation
kubectl get pods -n argocd | grep rollouts

# Should see:
# argo-rollouts-xxx   1/1   Running
```

**Install kubectl plugin (optional but useful):**

```bash
# Download Argo Rollouts kubectl plugin
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64

# Install
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# Verify
kubectl argo rollouts version
```

---

### Samm 5: Create Rollout (Canary Strategy)

Rollout on Deployment replacement with progressive delivery.

**Create Rollout manifest:**

```bash
mkdir -p k8s/user-service-rollout

cat > k8s/user-service-rollout/rollout.yaml << 'YAML'
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: user-service
  namespace: production
spec:
  replicas: 5
  
  # Revision history
  revisionHistoryLimit: 5
  
  # Selector (same as Deployment)
  selector:
    matchLabels:
      app: user-service
  
  # Pod template (same as Deployment)
  template:
    metadata:
      labels:
        app: user-service
    spec:
      serviceAccountName: user-service
      
      containers:
        - name: user-service
          image: YOUR_USERNAME/user-service:v1.0.0
          
          ports:
            - containerPort: 3000
              name: http
          
          env:
            - name: NODE_ENV
              value: "production"
            - name: DB_HOST
              value: postgres.production.svc.cluster.local
          
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
          
          resources:
            requests:
              cpu: 200m
              memory: 256Mi
            limits:
              cpu: 1000m
              memory: 1Gi
  
  # Canary Strategy
  strategy:
    canary:
      # Steps define traffic split progression
      steps:
        # Step 1: 10% traffic to canary
        - setWeight: 10
        - pause: {duration: 2m}  # Wait 2 minutes (or manual promotion)
        
        # Step 2: 25% traffic
        - setWeight: 25
        - pause: {duration: 2m}
        
        # Step 3: 50% traffic
        - setWeight: 50
        - pause: {duration: 5m}  # Longer pause before full rollout
        
        # Step 4: 75% traffic
        - setWeight: 75
        - pause: {duration: 2m}
        
        # Step 5: 100% traffic (full rollout)
        - setWeight: 100
      
      # Max surge/unavailable
      maxSurge: "25%"
      maxUnavailable: 0  # Always maintain capacity
YAML
```

**Create corresponding Service (no changes needed):**

```bash
cat > k8s/user-service-rollout/service.yaml << 'YAML'
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: production
spec:
  type: ClusterIP
  ports:
    - port: 3000
      targetPort: 3000
      protocol: TCP
      name: http
  selector:
    app: user-service  # Selects both stable and canary pods
YAML
```

**Apply Rollout:**

```bash
# Apply
kubectl apply -f k8s/user-service-rollout/

# Verify Rollout created
kubectl get rollout -n production

# Watch rollout progress
kubectl argo rollouts get rollout user-service -n production --watch
```

---

### Samm 6: Perform Canary Deployment

**Update image to trigger rollout:**

```bash
# Edit Rollout
kubectl argo rollouts set image user-service \
  user-service=YOUR_USERNAME/user-service:v2.0.0 \
  -n production

# Watch rollout
kubectl argo rollouts get rollout user-service -n production --watch
```

**Expected output:**
```
Name:            user-service
Namespace:       production
Status:          ॥ Paused
Strategy:        Canary
  Step:          1/5
  SetWeight:     10
  ActualWeight:  10
Images:          YOUR_USERNAME/user-service:v1.0.0 (stable)
                 YOUR_USERNAME/user-service:v2.0.0 (canary)
Replicas:
  Desired:       5
  Current:       6 (5 stable, 1 canary)
  Updated:       1
  Ready:         6
  Available:     6

NAME                                        KIND        STATUS     AGE
⟳ user-service                              Rollout     ॥ Paused   5m
├──# revision:2
│  └──⧉ user-service-v2-abc123              ReplicaSet  ✔ Healthy  30s
│     └──□ user-service-v2-abc123-xxxxx     Pod         ✔ Running  30s
└──# revision:1
   └──⧉ user-service-v1-def456              ReplicaSet  ✔ Healthy  5m
      ├──□ user-service-v1-def456-aaaaa     Pod         ✔ Running  5m
      ├──□ user-service-v1-def456-bbbbb     Pod         ✔ Running  5m
      ├──□ user-service-v1-def456-ccccc     Pod         ✔ Running  5m
      ├──□ user-service-v1-def456-ddddd     Pod         ✔ Running  5m
      └──□ user-service-v1-def456-eeeee     Pod         ✔ Running  5m
```

**Promote to next step (manual):**

```bash
# Promote to next step (25%)
kubectl argo rollouts promote user-service -n production

# Watch again
kubectl argo rollouts get rollout user-service -n production --watch

# Promote again (50%, 75%, 100%)
kubectl argo rollouts promote user-service -n production
```

**Abort rollout (if issues detected):**

```bash
# Abort and rollback to stable version
kubectl argo rollouts abort user-service -n production

# All traffic back to v1.0.0 immediately
```

---

### Samm 7: Blue-Green Deployment Strategy

Alternative to Canary: instant switch with instant rollback.

**Create Blue-Green Rollout:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: user-service-bluegreen
  namespace: production
spec:
  replicas: 5
  
  selector:
    matchLabels:
      app: user-service-bluegreen
  
  template:
    # ... same as before
  
  # Blue-Green Strategy
  strategy:
    blueGreen:
      # Active service (receives traffic)
      activeService: user-service-active
      
      # Preview service (for testing before promotion)
      previewService: user-service-preview
      
      # Auto promotion (or manual)
      autoPromotionEnabled: false  # Manual promotion
      
      # Preview replicas
      previewReplicaCount: 1  # Spin up 1 preview pod for testing
      
      # Scale down delay (old version)
      scaleDownDelaySeconds: 30
```

**Create Active and Preview Services:**

```yaml
---
# Active service (production traffic)
apiVersion: v1
kind: Service
metadata:
  name: user-service-active
  namespace: production
spec:
  type: ClusterIP
  ports:
    - port: 3000
      targetPort: 3000
  selector:
    app: user-service-bluegreen  # Rollout manages this label

---
# Preview service (testing new version)
apiVersion: v1
kind: Service
metadata:
  name: user-service-preview
  namespace: production
spec:
  type: ClusterIP
  ports:
    - port: 3000
      targetPort: 3000
  selector:
    app: user-service-bluegreen  # Rollout manages this label
```

**Workflow:**
1. Deploy new version → preview pods created
2. Test via preview service
3. Promote → instant switch (active service now points to new version)
4. Rollback (if needed) → instant switch back

---

### Samm 8: Automated Promotion with Analysis

Use Prometheus metrics to automatically promote or abort.

**Create AnalysisTemplate:**

```bash
cat > k8s/user-service-rollout/analysis-template.yaml << 'YAML'
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
  namespace: production
spec:
  # Metrics to analyze
  metrics:
    - name: success-rate
      # Prometheus query
      provider:
        prometheus:
          address: http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090
          query: |
            sum(rate(
              http_requests_total{status=~"2..",job="user-service"}[5m]
            ))
            /
            sum(rate(
              http_requests_total{job="user-service"}[5m]
            ))
      
      # Success criteria
      successCondition: result >= 0.95  # 95% success rate required
      
      # Failure criteria
      failureCondition: result < 0.90  # Abort if below 90%
      
      # How often to run query
      interval: 30s
      
      # How many times to run
      count: 10
YAML
```

**Use AnalysisTemplate in Rollout:**

```yaml
# In rollout.yaml
spec:
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: {duration: 1m}
        
        # Analysis step (automated promotion)
        - analysis:
            templates:
              - templateName: success-rate
            args:
              - name: service-name
                value: user-service
        
        - setWeight: 50
        # ... rest of steps
```

**Behavior:**
- Rollout pauses at analysis step
- Prometheus query runs every 30s (10 times)
- If success rate >= 95%: promote automatically
- If success rate < 90%: abort and rollback automatically

---

### Samm 9: Rollouts Dashboard (Optional)

**Access Rollouts UI:**

```bash
# Port-forward Rollouts dashboard
kubectl argo rollouts dashboard -n argocd

# Open: http://localhost:3100

# Or via port-forward:
kubectl port-forward -n argocd svc/argo-rollouts-dashboard 3100:3100
```

**Dashboard features:**
- Visual rollout progress
- Canary weight visualization
- Manual promote/abort buttons
- Analysis results

---

### Samm 10: Integration with ArgoCD

ArgoCD automatically detects Rollout CRDs.

**Create ArgoCD Application for Rollout:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service-rollout
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/hostinger.git
    targetRevision: HEAD
    path: k8s/user-service-rollout
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**ArgoCD UI shows:**
- Rollout status (instead of Deployment)
- Canary/Blue-Green visualization
- Promote/Abort actions (if enabled in ArgoCD settings)

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] ApplicationSet controller installed
- [ ] ApplicationSet created (list generator)
- [ ] Applications auto-generated (3+)
- [ ] Argo Rollouts controller installed
- [ ] kubectl-argo-rollouts plugin installed
- [ ] Rollout created (Canary strategy)
- [ ] Canary deployment tested (10% → 100%)
- [ ] Blue-Green strategy understood
- [ ] AnalysisTemplate created (Prometheus integration)
- [ ] Rollouts dashboard accessed

### Verifitseerimine

```bash
# 1. Check ApplicationSet
kubectl get applicationset -n argocd

# 2. Check generated Applications
argocd app list

# 3. Check Rollout
kubectl get rollout -n production

# 4. Check Rollout status
kubectl argo rollouts get rollout user-service -n production

# 5. Check Analysis
kubectl get analysisrun -n production

# 6. Rollouts dashboard
kubectl argo rollouts dashboard
```

---

## 🔍 Troubleshooting

### Probleem: ApplicationSet not generating Applications

**Sümptomid:**
```
kubectl get applicationset -n argocd
# Shows ApplicationSet but no Applications created
```

**Lahendus:**

```bash
# Check ApplicationSet controller logs
kubectl logs -n argocd deployment/argocd-applicationset-controller

# Common issues:
# - Template syntax error
# - Generator configuration incorrect

# Describe ApplicationSet
kubectl describe applicationset -n argocd user-service-all-envs
```

---

### Probleem: Rollout stuck in Paused state

**Sümptomid:**
```
Status: ॥ Paused
```

**Lahendus:**

```bash
# Check if manual promotion required
kubectl argo rollouts get rollout user-service -n production

# Promote manually
kubectl argo rollouts promote user-service -n production

# Or abort if issues
kubectl argo rollouts abort user-service -n production
```

---

### Probleem: Analysis fails

**Sümptomid:**
```
AnalysisRun failed: metric "success-rate" assessed Failed
```

**Lahendus:**

```bash
# Check AnalysisRun details
kubectl get analysisrun -n production

# Describe AnalysisRun
kubectl describe analysisrun <name> -n production

# Check Prometheus query manually
# Open Prometheus UI, run query to verify metrics exist

# Fix: Ensure application exports metrics
# Ensure Prometheus scrapes application
```

---

## 📚 Mida Sa Õppisid?

✅ **ApplicationSet**
  - List generator (explicit environments)
  - Git generator (auto-detect directories)
  - Template-based Application creation
  - DRY principle for ArgoCD Applications

✅ **Argo Rollouts**
  - Rollout CRD (replacement for Deployment)
  - Canary strategy (gradual traffic shift)
  - Blue-Green strategy (instant switch)
  - Manual and automated promotion

✅ **Progressive Delivery**
  - Risk mitigation (gradual rollout)
  - Instant rollback capability
  - Metrics-based promotion (Prometheus)
  - Analysis templates for automation

✅ **Integration**
  - ArgoCD + Rollouts (GitOps progressive delivery)
  - Prometheus + AnalysisTemplate (metrics-driven)
  - Lab 6 monitoring integration

---

## 🚀 Järgmised Sammud

**Exercise 5: GitOps Security & Best Practices** - ArgoCD RBAC, SSO, Image Updater:
- ArgoCD RBAC configuration
- SSO integration (GitHub, Google)
- ArgoCD Image Updater (automated image tag updates)
- Secrets management (Sealed Secrets integration)
- Multi-cluster management

```bash
cat exercises/05-security-best-practices.md
```

---

## 💡 Advanced GitOps Best Practices

✅ **ApplicationSet Strategy:**
- Use list generator for explicit control
- Use git generator for dynamic service discovery
- Use cluster generator for multi-cluster deployments

✅ **Rollout Strategy Selection:**
- **Canary:** Gradual rollout, risk mitigation (production default)
- **Blue-Green:** Instant switch, instant rollback (critical services)
- **Recreate:** Simple, downtime acceptable (dev/staging)

✅ **Analysis Integration:**
- Always use analysis for automated promotion
- Monitor success rate, error rate, latency
- Set conservative thresholds (95% success rate)
- Fail fast (abort quickly if metrics degrade)

✅ **Promotion Gates:**
- Manual promotion for production (safer)
- Automated promotion for dev/staging (faster iteration)
- Use sync windows (deploy only during business hours)

---

**Õnnitleme! Advanced GitOps workflows implemented! 🚀🎯**

**Kestus:** 60 minutit
**Järgmine:** Exercise 5 - GitOps Security & Best Practices

