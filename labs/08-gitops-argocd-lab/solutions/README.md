# Lab 8: GitOps with ArgoCD - Solutions

This directory contains reference manifests and configurations for all exercises.

---

## 📋 Directory Structure

```
solutions/
├── README.md                           # This file
├── argocd-values.yaml                  # Helm values for ArgoCD installation
├── user-service-application.yaml       # Basic Application manifest
├── applicationset-multi-env.yaml       # ApplicationSet example
├── rollout-canary.yaml                 # Argo Rollouts Canary example
├── analysis-template.yaml              # Prometheus-based analysis
├── argocd-rbac-cm.yaml                 # RBAC policies
├── argocd-cm-sso.yaml                  # GitHub SSO configuration
└── kustomize-example/                  # Kustomize structure example
    ├── base/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── kustomization.yaml
    └── overlays/
        ├── development/
        ├── staging/
        └── production/
```

---

## 🚀 Quick Start

### Exercise 1: ArgoCD Setup

```bash
# Install ArgoCD with Helm
helm install argocd argo/argo-cd \
  --namespace argocd \
  --values solutions/argocd-values.yaml \
  --wait

# Get admin password
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d

# Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Open: http://localhost:8080
```

### Exercise 2: First Application

```bash
# Create Application
kubectl apply -f solutions/user-service-application.yaml

# Sync
argocd app sync user-service
```

### Exercise 3: Multi-Environment with Kustomize

```bash
# Copy Kustomize structure to your repo
cp -r solutions/kustomize-example/* k8s/user-service/

# Commit to Git
git add k8s/user-service/
git commit -m "Add Kustomize base and overlays"
git push

# Create Applications (one per environment)
argocd app create user-service-dev \
  --repo https://github.com/YOUR_USERNAME/hostinger.git \
  --path k8s/user-service/overlays/development \
  --dest-namespace development \
  --dest-server https://kubernetes.default.svc

# Repeat for staging and production
```

### Exercise 4: ApplicationSet & Argo Rollouts

```bash
# Install ApplicationSet
kubectl apply -f solutions/applicationset-multi-env.yaml

# Install Argo Rollouts
helm install argo-rollouts argo/argo-rollouts --namespace argocd

# Create Rollout
kubectl apply -f solutions/rollout-canary.yaml

# Create AnalysisTemplate
kubectl apply -f solutions/analysis-template.yaml
```

### Exercise 5: Security (RBAC & SSO)

```bash
# Configure RBAC
kubectl apply -f solutions/argocd-rbac-cm.yaml

# Configure GitHub SSO
kubectl apply -f solutions/argocd-cm-sso.yaml

# Restart ArgoCD
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout restart deployment argocd-dex-server -n argocd
```

---

## 📝 Reference Files

### argocd-values.yaml

Complete Helm values for ArgoCD installation with:
- Prometheus metrics enabled (Lab 6 integration)
- ApplicationSet enabled
- Resource limits configured
- ServiceMonitors for monitoring

**Usage:**
```bash
helm install argocd argo/argo-cd \
  --namespace argocd \
  --values solutions/argocd-values.yaml
```

---

### user-service-application.yaml

Basic ArgoCD Application manifest for user-service.

**Features:**
- Manual sync policy
- Production namespace
- Retry strategy
- Finalizers for cascading delete

**Usage:**
```bash
kubectl apply -f solutions/user-service-application.yaml
argocd app sync user-service
```

---

### applicationset-multi-env.yaml

ApplicationSet with list generator for multi-environment deployment.

**Generates:**
- user-service-development
- user-service-staging
- user-service-production

**Usage:**
```bash
kubectl apply -f solutions/applicationset-multi-env.yaml
argocd app list  # Should show 3 applications
```

---

### rollout-canary.yaml

Argo Rollouts manifest with Canary strategy.

**Strategy:**
- 10% → 25% → 50% → 75% → 100%
- Manual promotion (pause between steps)
- MaxSurge: 25%, MaxUnavailable: 0

**Usage:**
```bash
kubectl apply -f solutions/rollout-canary.yaml

# Update image to trigger rollout
kubectl argo rollouts set image user-service \
  user-service=YOUR_USERNAME/user-service:v2.0.0 \
  -n production

# Watch rollout
kubectl argo rollouts get rollout user-service -n production --watch

# Promote
kubectl argo rollouts promote user-service -n production
```

---

### analysis-template.yaml

AnalysisTemplate for Prometheus-based automated promotion.

**Metrics:**
- HTTP success rate (must be >= 95%)
- Runs every 30s for 5 minutes

**Usage:**
```bash
kubectl apply -f solutions/analysis-template.yaml

# Use in Rollout strategy:
# strategy:
#   canary:
#     steps:
#       - setWeight: 10
#       - analysis:
#           templates:
#             - templateName: success-rate
```

---

### argocd-rbac-cm.yaml

RBAC policies ConfigMap.

**Roles:**
- `role:developer` - Read all, sync dev/staging only
- `role:ops` - Manage all apps, no create/delete
- `role:admin` - Full access
- `role:readonly` - Read only (default for unknown users)

**Usage:**
```bash
kubectl apply -f solutions/argocd-rbac-cm.yaml
kubectl rollout restart deployment argocd-server -n argocd
```

---

### argocd-cm-sso.yaml

GitHub SSO configuration via Dex.

**Setup:**
1. Create GitHub OAuth App
2. Update `clientID` and org name in manifest
3. Add `clientSecret` to argocd-secret
4. Apply ConfigMap

**Usage:**
```bash
# Add client secret
kubectl patch secret argocd-secret -n argocd --type json -p='[
  {
    "op": "add",
    "path": "/data/dex.github.clientSecret",
    "value": "BASE64_ENCODED_SECRET"
  }
]'

# Apply SSO config
kubectl apply -f solutions/argocd-cm-sso.yaml

# Restart
kubectl rollout restart deployment argocd-dex-server -n argocd
kubectl rollout restart deployment argocd-server -n argocd
```

---

### kustomize-example/

Reference Kustomize structure with base and 3 overlays.

**Structure:**
```
kustomize-example/
├── base/                    # Common manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── development/         # 1 replica, debug logging
    ├── staging/             # 2 replicas, staging DB
    └── production/          # 5 replicas, HPA, prod DB
```

**Usage:**
```bash
# Copy to your repository
cp -r solutions/kustomize-example/* k8s/user-service/

# Test locally
kubectl kustomize k8s/user-service/overlays/production

# Commit and let ArgoCD deploy
git add k8s/user-service/
git commit -m "Add Kustomize structure"
git push
```

---

## 🔧 Customization

### Update Docker Image

In all manifests, replace:
```yaml
image: YOUR_USERNAME/user-service:latest
```

With your actual Docker Hub username.

### Update Git Repository

In all manifests, replace:
```yaml
repoURL: https://github.com/YOUR_USERNAME/hostinger.git
```

With your actual GitHub repository URL.

### Update GitHub Organization (SSO)

In `argocd-cm-sso.yaml`, replace:
```yaml
orgs:
  - name: YOUR_GITHUB_ORG
```

With your GitHub organization name.

---

## 📚 Additional Resources

**ArgoCD Documentation:**
- https://argo-cd.readthedocs.io/

**Argo Rollouts Documentation:**
- https://argo-rollouts.readthedocs.io/

**Kustomize Documentation:**
- https://kustomize.io/

**ArgoCD Image Updater:**
- https://argocd-image-updater.readthedocs.io/

---

## ✅ Verification Commands

```bash
# Check ArgoCD installation
kubectl get pods -n argocd

# List applications
argocd app list

# Get application details
argocd app get user-service

# Check Rollouts
kubectl get rollout -n production

# Check ApplicationSets
kubectl get applicationset -n argocd

# Check RBAC
kubectl get configmap argocd-rbac-cm -n argocd -o yaml

# Test user permissions
argocd account get-user-info
```

---

## 🐛 Troubleshooting

### Application OutOfSync

```bash
# Check diff
argocd app diff user-service

# Force sync
argocd app sync user-service --force
```

### Rollout Stuck

```bash
# Check Rollout status
kubectl argo rollouts get rollout user-service -n production

# Abort rollout
kubectl argo rollouts abort user-service -n production

# Promote rollout
kubectl argo rollouts promote user-service -n production
```

### SSO Not Working

```bash
# Check Dex logs
kubectl logs -n argocd deployment/argocd-dex-server

# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Verify callback URL in GitHub OAuth App matches:
# http://localhost:8080/api/dex/callback
```

---

**Kõik reference manifests on production-tested ja Lab 8 exercises järgi! 🚀**

