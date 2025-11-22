# Lab 8: GitOps with ArgoCD

**Kestus:** 5 tundi (5 × 60 min)
**Eeldused:** Lab 1-7 läbitud (eriti Lab 7 Security ja Lab 5 CI/CD)
**Tehnoloogiad:** ArgoCD, Kustomize, Argo Rollouts, ApplicationSet
**Keskkond:** Kubernetes cluster, Helm 3, Git repository

---

## 📋 Ülevaade

Lab 8 keskendub **GitOps** - modern deployment methodology kus Git on single source of truth. ArgoCD on Kubernetes-native continuous delivery tool, mis automaatselt sünkroniseerib Kubernetes cluster'i Git repository'ga.

**GitOps Principles:**
1. **Declarative** - Kogu desired state on deklareeritud Git'is
2. **Versioned** - Git history = deployment history
3. **Immutable** - Git commits on immutable
4. **Pulled Automatically** - ArgoCD pulls changes from Git
5. **Continuously Reconciled** - ArgoCD ensures actual state = desired state

**Integratsioon Lab 7-ga:**
- Lab 7 Sealed Secrets → Lab 8 encrypted secrets in Git
- Lab 7 RBAC → Lab 8 ArgoCD access control
- Lab 7 Network Policies → Lab 8 deploys policies GitOps-style
- Lab 5 CI/CD → Lab 8 replaces manual deployments

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

✅ Paigaldada ja konfigureerida ArgoCD
✅ Luua Git-based deployment workflow
✅ Deploy rakendusi declarative GitOps pattern'iga
✅ Manageda multi-environment deployments (dev/staging/prod)
✅ Kasutada Kustomize overlays
✅ Implementeerida progressive delivery (Canary deployments)
✅ Automatiseerida sync policies
✅ Integreerida ArgoCD RBAC ja SSO
✅ Monitoorida deployments ArgoCD UI's

---

## 🏗️ GitOps Arhitektuur

### Traditional CI/CD vs GitOps

```
┌─────────────────────────────────────────────────────────────┐
│         Traditional CI/CD (Push-based)                      │
│                                                             │
│  Developer ──▶ Git ──▶ CI Pipeline ──▶ kubectl apply       │
│                           │                   │             │
│                           │                   ▼             │
│                           │            Kubernetes Cluster   │
│                           │                                 │
│  Problems:                                                  │
│  ❌ kubectl credentials in CI                               │
│  ❌ No drift detection                                      │
│  ❌ Manual rollback                                         │
│  ❌ No self-healing                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│         GitOps with ArgoCD (Pull-based)                     │
│                                                             │
│  Developer ──▶ Git ──▶ CI builds image                     │
│                  │                                           │
│                  │ ArgoCD watches Git                       │
│                  ▼                                           │
│           ┌──────────────┐                                  │
│           │   ArgoCD     │                                  │
│           │  (in cluster)│                                  │
│           │              │                                  │
│           │ - Monitors   │                                  │
│           │ - Syncs      │                                  │
│           │ - Heals      │                                  │
│           └──────┬───────┘                                  │
│                  │ applies manifests                        │
│                  ▼                                           │
│           Kubernetes Cluster                                │
│                                                             │
│  Benefits:                                                  │
│  ✅ No kubectl credentials in CI                            │
│  ✅ Automatic drift detection                               │
│  ✅ Git revert = rollback                                   │
│  ✅ Self-healing                                            │
│  ✅ Audit trail (Git history)                               │
└─────────────────────────────────────────────────────────────┘
```

### ArgoCD Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    Git Repository                              │
│                                                                │
│  manifests/                                                    │
│  ├── base/                  (Kustomize base)                   │
│  │   ├── deployment.yaml                                       │
│  │   ├── service.yaml                                          │
│  │   └── kustomization.yaml                                    │
│  ├── overlays/                                                 │
│  │   ├── development/      (Dev environment)                   │
│  │   │   └── kustomization.yaml                                │
│  │   ├── staging/          (Staging environment)               │
│  │   │   └── kustomization.yaml                                │
│  │   └── production/       (Production environment)            │
│  │       └── kustomization.yaml                                │
│  └── sealed-secrets/       (Encrypted secrets from Lab 7)      │
│      └── db-sealed-secret.yaml                                 │
└──────────────────────┬─────────────────────────────────────────┘
                       │
                       │ ArgoCD monitors (every 3 min)
                       ▼
┌────────────────────────────────────────────────────────────────┐
│              ArgoCD Server (argocd namespace)                  │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Application Controller                                  │ │
│  │  - Monitors Git repository                               │ │
│  │  - Compares desired state (Git) vs actual state (K8s)    │ │
│  │  - Detects drift                                         │ │
│  │  - Triggers sync                                         │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Repo Server                                             │ │
│  │  - Fetches manifests from Git                            │ │
│  │  │  - Renders Helm charts                                 │ │
│  │  - Renders Kustomize overlays                            │ │
│  │  - Returns rendered manifests                            │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  ArgoCD UI / API Server                                  │ │
│  │  - Web UI (port 443/80)                                  │ │
│  │  - REST API                                              │ │
│  │  - RBAC enforcement                                      │ │
│  │  - SSO integration                                       │ │
│  └──────────────────────────────────────────────────────────┘ │
└──────────────────────┬─────────────────────────────────────────┘
                       │ kubectl apply
                       ▼
┌────────────────────────────────────────────────────────────────┐
│          Kubernetes Cluster (Namespaces)                       │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ Development  │  │   Staging    │  │  Production  │        │
│  │ Namespace    │  │  Namespace   │  │  Namespace   │        │
│  │              │  │              │  │              │        │
│  │ user-service │  │ user-service │  │ user-service │        │
│  │ (1 replica)  │  │ (2 replicas) │  │ (3 replicas) │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└────────────────────────────────────────────────────────────────┘
```

---

## 📂 Labori Struktuur

```
08-gitops-argocd-lab/
├── README.md                          # See fail
├── exercises/                         # Harjutused
│   ├── 01-argocd-setup.md             # 60 min - ArgoCD install & config
│   ├── 02-first-app-deployment.md     # 60 min - Deploy user-service GitOps
│   ├── 03-multi-environment.md        # 60 min - Kustomize overlays (dev/staging/prod)
│   ├── 04-advanced-workflows.md       # 60 min - ApplicationSet, Sync Waves, Rollouts
│   └── 05-security-best-practices.md  # 60 min - ArgoCD RBAC, SSO, Image Updater
├── solutions/                         # Reference lahendused
│   ├── argocd/
│   │   ├── install-values.yaml        # ArgoCD Helm values
│   │   └── application.yaml           # Example Application CRD
│   ├── kustomize/
│   │   ├── base/                      # Base manifests
│   │   └── overlays/                  # Environment overlays
│   │       ├── development/
│   │       ├── staging/
│   │       └── production/
│   ├── applicationset/
│   │   └── example-appset.yaml        # ApplicationSet example
│   └── rollouts/
│       └── canary-rollout.yaml        # Canary deployment example
└── setup.sh                           # Environment setup script
```

---

## 🔧 Eeldused

### Eelnevad labid

✅ **Lab 1-4:** Docker, Kubernetes, Helm
✅ **Lab 5 (KOHUSTUSLIK):** CI/CD pipeline
  - GitHub repository
  - Docker images built
✅ **Lab 6:** Monitoring (Prometheus + Grafana)
✅ **Lab 7 (KOHUSTUSLIK):** Security
  - Sealed Secrets (encrypted secrets in Git)
  - RBAC
  - Network Policies

### Tööriistad

✅ Kubernetes cluster töötab (`kubectl cluster-info`)
✅ Helm 3 paigaldatud (`helm version`)
✅ Git repository access (GitHub, GitLab, Bitbucket)
✅ Sealed Secrets Controller (Lab 7)

### Teadmised

✅ Kubernetes manifests (Deployment, Service, ConfigMap)
✅ Helm basics (Lab 4)
✅ Git workflow (commit, push, pull)
🆕 GitOps principles (õpime laboris)
🆕 Kustomize (õpime laboris)
🆕 Declarative deployment patterns

---

## 🎓 Harjutused

### Exercise 1: ArgoCD Setup & Installation (60 min)

**Eesmärk:** Paigalda ArgoCD ja tutvusta põhilisi kontseptsioone.

**Teemad:**
- ArgoCD arhitektuur (Application Controller, Repo Server, API Server)
- Installation methods (Helm vs manifest)
- ArgoCD UI access
- ArgoCD CLI installation
- Initial configuration
- Creating first repository connection

**Tulemus:**
- ArgoCD running argocd namespace'is
- ArgoCD UI accessible
- CLI configured
- Git repository connected

---

### Exercise 2: First Application Deployment (60 min)

**Eesmärk:** Deploy user-service GitOps-style ArgoCD'ga.

**Teemad:**
- Git repository structure
- Application CRD (Custom Resource Definition)
- Sync policies (manual vs automated)
- Health status
- Sync strategies (kubectl apply vs replace)
- Self-healing
- Manual sync vs auto-sync

**Workflow:**
1. Create Git repo structure
2. Add user-service manifests to Git
3. Create ArgoCD Application
4. Sync application
5. Verify deployment
6. Test self-healing (delete pod, ArgoCD recreates)

**Tulemus:**
- User-service deployed via ArgoCD
- Git = single source of truth
- Changes in Git auto-sync to cluster
- Self-healing demonstrated

---

### Exercise 3: Multi-Environment Deployments (60 min)

**Eesmärk:** Manage dev/staging/production environments Kustomize'iga.

**Teemad:**
- Kustomize basics (base + overlays)
- Environment-specific configurations
  - Development: 1 replica, no ingress
  - Staging: 2 replicas, ingress enabled
  - Production: 3 replicas, HPA enabled
- Sealed Secrets per environment
- Application per environment
- App of Apps pattern
- Promoting changes (dev → staging → prod)

**Directory structure:**
```
manifests/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── development/
    │   ├── kustomization.yaml
    │   └── replica-patch.yaml
    ├── staging/
    │   └── kustomization.yaml
    └── production/
        ├── kustomization.yaml
        └── hpa.yaml
```

**Tulemus:**
- 3 ArgoCD Applications (dev, staging, prod)
- Environment-specific configs
- Promotion workflow (Git branch/tag based)

---

### Exercise 4: Advanced GitOps Workflows (60 min)

**Eesmärk:** Implementeeri advanced ArgoCD patterns.

**Teemad:**
- **ApplicationSet** - Generate multiple Applications dynamically
- **Sync Waves** - Control deployment order (DB before app)
- **Hooks** - PreSync, Sync, PostSync, SyncFail
- **Progressive Delivery** - Canary deployments with Argo Rollouts
- **Automated Rollback** - Automatic rollback on failure
- **Diff strategies** - Ignore certain fields

**ApplicationSet example:**
```yaml
# Generate Application per Git folder
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: all-envs
spec:
  generators:
    - git:
        repoURL: https://github.com/user/repo
        directories:
          - path: overlays/*
```

**Argo Rollouts (Canary):**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: user-service
spec:
  strategy:
    canary:
      steps:
        - setWeight: 20    # 20% traffic to new version
        - pause: {duration: 2m}
        - setWeight: 50    # 50% traffic
        - pause: {duration: 2m}
        - setWeight: 100   # 100% traffic (full rollout)
```

**Tulemus:**
- ApplicationSet generates apps automatically
- Sync waves control deployment order
- Canary deployment working
- Hooks execute pre/post sync tasks

---

### Exercise 5: GitOps Security & Best Practices (60 min)

**Eesmärk:** Implementeeri security ja production best practices.

**Teemad:**
- **ArgoCD RBAC** - Role-based access control
  - Readonly users (view only)
  - Developer users (sync allowed)
  - Admin users (full access)
- **SSO Integration** - OIDC/SAML (Google, GitHub, Okta)
- **Webhook Automation** - GitHub webhook → instant sync
- **ArgoCD Image Updater** - Automatic image version updates
- **Notifications** - Slack/Email on sync events
- **Resource limits** - Prevent resource exhaustion
- **Audit logging** - Track all ArgoCD operations

**ArgoCD RBAC example:**
```yaml
# ConfigMap: argocd-rbac-cm
policy.csv: |
  # Readonly role
  p, role:readonly, applications, get, *, allow
  p, role:readonly, applications, sync, *, deny

  # Developer role
  p, role:developer, applications, get, */*, allow
  p, role:developer, applications, sync, */*, allow
  p, role:developer, applications, delete, *, deny

  # Bind user to role
  g, john@company.com, role:developer
```

**Image Updater:**
```yaml
# Annotation on Application
argocd-image-updater.argoproj.io/image-list: user-service=dockerhub/user-service
argocd-image-updater.argoproj.io/user-service.update-strategy: latest
```

**Tulemus:**
- ArgoCD RBAC configured
- SSO working (Google OAuth)
- GitHub webhook triggers instant sync
- Image updater automates image updates
- Slack notifications on deployment events

---

## 🚀 Kiirstart

### Automaatne Setup (Soovitatud)

```bash
# Käivita setup script
chmod +x setup.sh
./setup.sh
```

**Script kontrollib:**
- ✅ Kubernetes cluster connectivity
- ✅ Helm installation
- ✅ Git repository availability
- ✅ Lab 7 Sealed Secrets Controller
- ✅ ArgoCD namespace creation
- ✅ Optional: Install ArgoCD

### Manuaalne Setup

```bash
# 1. Kontrolli eelduseid
kubectl cluster-info
helm version
git --version

# 2. Kontrolli Sealed Secrets (Lab 7)
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# 3. Loo ArgoCD namespace
kubectl create namespace argocd

# 4. Alusta Exercise 1'st
cat exercises/01-argocd-setup.md
```

---

## 🔗 Integratsioon Eelmiste Labidega

**Lab 5 → Lab 8:**
- Lab 5 CI builds Docker image → pushes to registry
- Lab 8 ArgoCD deploys image to Kubernetes
- Separation of concerns: CI builds, CD (ArgoCD) deploys

**Lab 7 → Lab 8:**
- Lab 7 Sealed Secrets → Lab 8 stores encrypted secrets in Git
- Lab 7 RBAC → Lab 8 ArgoCD RBAC (who can deploy)
- Lab 7 Network Policies → Lab 8 deploys policies GitOps-style

**Lab 4 → Lab 8:**
- Lab 4 Helm charts → Lab 8 ArgoCD deploys Helm charts
- Helm values per environment

**Lab 6 → Lab 8:**
- Lab 6 Prometheus monitors ArgoCD metrics
- Lab 6 Grafana dashboard for ArgoCD

---

## 📊 GitOps Benefits

**Traditional Deployment:**
- ❌ Manual `kubectl apply`
- ❌ No version control for cluster state
- ❌ Drift (cluster state != desired state)
- ❌ Manual rollback (find old manifest, apply)
- ❌ No audit trail
- ❌ Credentials in CI/CD

**GitOps with ArgoCD:**
- ✅ Declarative (Git = desired state)
- ✅ Versioned (Git history)
- ✅ Automatic drift detection
- ✅ Easy rollback (git revert)
- ✅ Audit trail (Git commits)
- ✅ No cluster credentials in CI
- ✅ Self-healing
- ✅ Multi-cluster support

---

## 💡 GitOps Best Practices

**Repository Structure:**
✅ Separate repos: app code vs manifests
✅ Environment branches OR folders
✅ Never commit secrets (use Sealed Secrets)

**Sync Policies:**
✅ Manual sync for production (safer)
✅ Auto-sync for dev/staging (faster)
✅ Prune enabled (remove deleted resources)
✅ Self-heal enabled (recreate deleted resources)

**Change Management:**
✅ Pull requests for manifest changes
✅ Code review for infrastructure
✅ Automated testing (kubeval, conftest)
✅ Gradual rollout (dev → staging → prod)

**Security:**
✅ ArgoCD RBAC (who can sync what)
✅ SSO integration
✅ Webhook signatures (GitHub)
✅ Private repos (SSH keys, tokens)

---

## 🔍 Troubleshooting

### Application stuck in "Progressing" state

```bash
# Check sync status
argocd app get <app-name>

# Check pod events
kubectl describe pod -n <namespace> <pod-name>

# Check logs
kubectl logs -n <namespace> <pod-name>

# Manual sync
argocd app sync <app-name>
```

### OutOfSync status

**Reasons:**
- Manual changes in cluster (kubectl apply)
- Drift

**Solution:**
```bash
# View diff
argocd app diff <app-name>

# Sync to Git state (override manual changes)
argocd app sync <app-name> --prune
```

### Image not updating

**Check Image Updater:**
```bash
kubectl logs -n argocd deployment/argocd-image-updater

# Force update
argocd app set <app-name> --parameter image.tag=v1.2.3
```

---

## 📚 Õppematerjalid

**Official Documentation:**
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Argo Rollouts](https://argoproj.github.io/argo-rollouts/)
- [Kustomize](https://kustomize.io/)
- [ApplicationSet](https://argocd-applicationset.readthedocs.io/)

**GitOps Principles:**
- [GitOps Manifesto](https://opengitops.dev/)
- [CNCF GitOps Working Group](https://github.com/cncf/tag-app-delivery)

---

## 🎯 Labori Eesmärgid

Peale Lab 8 läbimist on sul:

✅ **Production-ready GitOps workflow**
  - ArgoCD manages all deployments
  - Git = single source of truth
  - Declarative infrastructure

✅ **Multi-environment management**
  - Dev, Staging, Production
  - Kustomize overlays
  - Environment promotion

✅ **Advanced deployment patterns**
  - Canary deployments
  - Blue-Green deployments
  - Automated rollback

✅ **Security & Compliance**
  - ArgoCD RBAC
  - SSO integration
  - Audit trail (Git history)
  - Encrypted secrets (Sealed Secrets)

✅ **Automation**
  - Auto-sync from Git
  - Webhook-triggered deploys
  - Image version automation

---

**Alusta:** `./setup.sh` ja seejärel `cat exercises/01-argocd-setup.md`

**Kestus:** 5 tundi (5 × 60 min)

**GitOps = The Future of Kubernetes Deployments! 🚀📦🔄**
