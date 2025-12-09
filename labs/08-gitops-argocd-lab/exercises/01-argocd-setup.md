# Harjutus 1: ArgoCD Setup & Installation

**Kestus:** 60 minutit
**Eesmärk:** Paigalda ja konfigureeri ArgoCD Kubernetes cluster'is GitOps workflow jaoks.

---

## 📋 Ülevaade

Selles harjutuses installime **ArgoCD** - industry-standard GitOps continuous delivery tool Kubernetes'le. ArgoCD automatiseerib rakenduste deploy'mise Git repositooriumist Kubernetes cluster'isse.

**Miks ArgoCD?**
- ✅ GitOps Native: Git on single source of truth
- ✅ Deklaratiivne: Kubernetes manifests Git'is
- ✅ Automaatne sünkroniseerimine: Cluster peegeldab Git'i state
- ✅ Self-healing: Automaatne drift detection ja correction
- ✅ Rollback: Git history = deployment history
- ✅ Multi-cluster: Halda mitu cluster'it ühest kohast
- ✅ Web UI + CLI: Intuitiivne visualiseerimine
- ✅ RBAC ja SSO: Enterprise-ready access control

**GitOps vs Traditional CI/CD:**

```
❌ Traditional CI/CD:
Developer → Git → CI builds → CI pushes to K8s → K8s cluster
            (kubectl apply from CI - problematic!)

✅ GitOps with ArgoCD:
Developer → Git → ArgoCD watches Git → ArgoCD applies → K8s cluster
            (Pull model - more secure, auditable)
```

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista ArgoCD arhitektuuri ja komponente
- ✅ Installida ArgoCD Helm'iga
- ✅ Konfigureerida ArgoCD UI ja CLI access
- ✅ Ühendada Git repository ArgoCD'ga
- ✅ Mõista ArgoCD permissions model
- ✅ Debuggida ArgoCD installation issues
- ✅ Integreerida ArgoCD Lab 5, 6, 7'ga

---

## 🏗️ ArgoCD Arhitektuur

```
┌─────────────────────────────────────────────────────────────────┐
│                      ArgoCD Architecture                        │
│                                                                 │
│  ┌────────────────┐          ┌────────────────┐                │
│  │  Git Repository│          │  ArgoCD Server │                │
│  │  (manifests)   │◄─────────│  (API + UI)    │                │
│  └────────────────┘  watches └────────┬───────┘                │
│         │                             │                         │
│         │                             │ REST API                │
│         │                             ▼                         │
│         │                    ┌─────────────────┐                │
│         │                    │  Application    │                │
│         │                    │  Controller     │                │
│         │                    └────────┬────────┘                │
│         │                             │                         │
│         │                             │ sync                    │
│         │                             ▼                         │
│         │                    ┌─────────────────┐                │
│         └───────────────────►│  Repo Server    │                │
│                              │  (manifest      │                │
│                              │   generator)    │                │
│                              └────────┬────────┘                │
│                                       │                         │
│                                       │ apply                   │
│                                       ▼                         │
│                              ┌─────────────────┐                │
│                              │  Kubernetes     │                │
│                              │  Cluster        │                │
│                              │  (pods, svcs)   │                │
│                              └─────────────────┘                │
│                                                                 │
│  Components:                                                    │
│  1. API Server - REST API + Web UI                             │
│  2. Repository Server - Clones Git, generates manifests        │
│  3. Application Controller - Monitors apps, syncs state        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**ArgoCD Core Concepts:**
- **Application**: Kubernetes resources defined in Git
- **Project**: Logical grouping of Applications
- **Sync**: Process of making cluster state match Git state
- **Health**: Status of Kubernetes resources (Healthy, Degraded, Progressing)
- **Sync Status**: Git vs Cluster comparison (Synced, OutOfSync)

---

## 📝 Sammud

### Samm 1: Kontrolli Eeldusi

ArgoCD nõuab töötavat Kubernetes cluster'it.

```bash
# Check Kubernetes cluster
kubectl cluster-info

# Check current context
kubectl config current-context

# Check nodes
kubectl get nodes

# Ensure you have Lab 5, 6, 7 namespaces
kubectl get namespaces | grep -E 'development|staging|production|monitoring'
```

**Expected output:**
- Kubernetes cluster reachable
- At least 1 node Ready
- Namespaces: development, staging, production, monitoring exist

---

### Samm 2: Loo ArgoCD Namespace

```bash
# Create argocd namespace
kubectl create namespace argocd

# Verify
kubectl get namespace argocd
```

**Namespace labeling (for Network Policies from Lab 7):**

```bash
# Label namespace for monitoring scraping
kubectl label namespace argocd monitoring=prometheus

# Verify
kubectl get namespace argocd --show-labels
```

---

### Samm 3: Install ArgoCD (Helm Method - Recommended)

Kasutame Helm'i, sest see annab paremad configuration võimalused.

**Add Helm repo:**

```bash
# Add ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm

# Update repos
helm repo update

# Search for chart
helm search repo argo-cd
```

**Create values file:**

```bash
cat > argocd-values.yaml << 'YAML'
# ArgoCD Helm Values for Lab 8

global:
  domain: argocd.local

# Server configuration
server:
  replicas: 1  # Single replica for lab
  
  # Resource limits
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  
  # Ingress (disabled for lab - will use port-forward)
  ingress:
    enabled: false
  
  # Metrics for Prometheus (Lab 6 integration)
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring
  
  # Configuration
  config:
    # Repositories (will add manually later)
    repositories: |
      - url: https://github.com/argoproj/argocd-example-apps.git
        type: git
        name: argocd-examples

# Application Controller
controller:
  replicas: 1
  
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 1Gi
  
  # Metrics
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring

# Repo Server
repoServer:
  replicas: 1
  
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 512Mi
  
  # Metrics
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring

# Redis (for caching)
redis:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi

# Dex (SSO - disabled for lab)
dex:
  enabled: false

# Notifications (optional)
notifications:
  enabled: false

# ApplicationSet Controller (for advanced workflows)
applicationSet:
  enabled: true
  replicas: 1
  
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
YAML
```

**Install ArgoCD:**

```bash
# Install with Helm
helm install argocd argo/argo-cd \
  --namespace argocd \
  --values argocd-values.yaml \
  --version 7.0.0 \
  --wait \
  --timeout 10m

# Verify installation
kubectl get pods -n argocd

# Should see:
# - argocd-server-xxx
# - argocd-application-controller-xxx
# - argocd-repo-server-xxx
# - argocd-redis-xxx
# - argocd-applicationset-controller-xxx
```

**Wait for all pods to be Ready:**

```bash
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=5m
```

---

### Samm 4: Alternative - Install via Manifest (Optional)

Kui ei soovi Helm'i kasutada:

```bash
# Install official manifest
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=5m
```

**Note:** Helm method on soovitatav, sest values file'i saab versiooni kontrollida Git'is.

---

### Samm 5: Access ArgoCD UI

**Get initial admin password:**

```bash
# ArgoCD creates random admin password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
# Save this password!

# Example output: k9sT7xQ3pL2mN5vB
```

**Port-forward to access UI:**

```bash
# Forward port 8080 → ArgoCD server port 80
kubectl port-forward svc/argocd-server -n argocd 8080:80 &

# Access: http://localhost:8080
```

**Login to UI:**
- URL: http://localhost:8080
- Username: `admin`
- Password: (from previous step)

**Expected UI:**
- ArgoCD Dashboard with "Applications" view
- No applications yet (empty state)
- Settings accessible (top right gear icon)

---

### Samm 6: Change Admin Password

Security best practice: muuda default password.

```bash
# Login via CLI first (need to install CLI - next step)
# Or use UI: Settings → Accounts → admin → Update Password
```

**Via UI:**
1. Click gear icon (Settings)
2. Click "Accounts"
3. Click "admin"
4. Click "Update Password"
5. New password: `argocd-admin-2025` (või turvalisem)

---

### Samm 7: Install ArgoCD CLI

ArgoCD CLI on vajalik automation'iks ja debugging'uks.

**Linux (Ubuntu):**

```bash
# Download latest version
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

# Make executable
chmod +x argocd

# Move to PATH
sudo mv argocd /usr/local/bin/argocd

# Verify
argocd version --client
```

**Expected output:**
```
argocd: v2.10.0+...
```

---

### Samm 8: Login via CLI

```bash
# Login (port-forward must be active!)
argocd login localhost:8080 \
  --username admin \
  --password 'argocd-admin-2025' \
  --insecure

# Expected: 'admin:login' logged in successfully
```

**Verify CLI login:**

```bash
# List applications (should be empty)
argocd app list

# Get cluster info
argocd cluster list

# Should see in-cluster context
```

---

### Samm 9: Configure Git Repository

Ühenda ArgoCD oma Git repository'ga (või demo repo Lab 5'st).

**Option 1: Add via CLI (Public Repo):**

```bash
# Add public repository
argocd repo add https://github.com/argoproj/argocd-example-apps.git \
  --name argocd-examples

# Verify
argocd repo list
```

**Option 2: Add via UI:**
1. Settings → Repositories
2. Click "Connect Repo"
3. Method: HTTPS
4. Repository URL: `https://github.com/argoproj/argocd-example-apps.git`
5. Click "Connect"

**Option 3: Private Repository (GitHub - will use in Exercise 2):**

```bash
# Generate GitHub Personal Access Token (PAT)
# GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
# Permissions: repo (full control)

# Add private repo with PAT
argocd repo add https://github.com/YOUR_USERNAME/hostinger.git \
  --username YOUR_GITHUB_USERNAME \
  --password YOUR_GITHUB_PAT \
  --name hostinger-lab

# Verify connection
argocd repo list | grep hostinger
```

---

### Samm 10: Configure RBAC (Basic)

ArgoCD RBAC võimaldab fine-grained access control (täpsem harjutus Exercise 5).

**Get current RBAC config:**

```bash
# Get argocd-rbac-cm ConfigMap
kubectl get configmap argocd-rbac-cm -n argocd -o yaml
```

**Basic RBAC example (readonly user):**

```bash
cat > argocd-rbac-cm.yaml << 'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  # Policy definition
  policy.csv: |
    # Readonly role
    p, role:readonly, applications, get, */*, allow
    p, role:readonly, applications, list, */*, allow
    
    # Bind user to role (local user example)
    g, readonly-user, role:readonly
  
  # Default policy for unknown users
  policy.default: role:readonly
YAML

# Apply
kubectl apply -f argocd-rbac-cm.yaml
```

**Note:** RBAC täpsemalt käsitleme Exercise 5's koos SSO integratsiooniga.

---

### Samm 11: Enable Prometheus Metrics (Lab 6 Integration)

ArgoCD exportib metrics Prometheus'le.

**Verify ServiceMonitors created:**

```bash
# Check if ServiceMonitors exist (Helm values enabled them)
kubectl get servicemonitor -n argocd

# Should see:
# - argocd-application-controller
# - argocd-repo-server
# - argocd-server
```

**Add ArgoCD metrics to Prometheus (if not auto-discovered):**

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &

# Open: http://localhost:9090/targets
# Search for "argocd" - should see 3 targets UP
```

**If targets not visible, ensure Prometheus scrapes argocd namespace:**

```yaml
# Check Prometheus ServiceMonitor selector
kubectl get prometheus -n monitoring prometheus-kube-prometheus-prometheus -o yaml | grep serviceMonitorSelector -A5
```

---

### Samm 12: Create First Application (Test)

Loome test application ArgoCD examples repo'st.

**Via CLI:**

```bash
# Create guestbook app from examples
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync (deploy) application
argocd app sync guestbook

# Check status
argocd app get guestbook
```

**Via UI:**
1. Click "+ New App"
2. Application Name: `guestbook`
3. Project: `default`
4. Sync Policy: `Manual`
5. Repository URL: `https://github.com/argoproj/argocd-example-apps.git`
6. Path: `guestbook`
7. Cluster: `https://kubernetes.default.svc`
8. Namespace: `default`
9. Click "Create"
10. Click "Sync" → "Synchronize"

**Verify deployment:**

```bash
# Check pods
kubectl get pods -n default | grep guestbook

# Should see:
# guestbook-ui-xxx   1/1   Running
```

**Access guestbook:**

```bash
# Port-forward
kubectl port-forward svc/guestbook-ui -n default 8081:80 &

# Open: http://localhost:8081
```

**Delete test app (cleanup):**

```bash
# Delete app (and all resources)
argocd app delete guestbook --cascade

# Or via UI: Click app → Delete
```

---

### Samm 13: Configure Notifications (Optional)

ArgoCD võib saata notifications Slack'i, email'i, jne.

**Example: Slack notifications:**

```yaml
# argocd-notifications-cm ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  
  template.app-deployed: |
    message: |
      Application {{.app.metadata.name}} deployed to {{.app.spec.destination.namespace}}
  
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

**Note:** Notifications täpsemalt Exercise 5's.

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] ArgoCD namespace created
- [ ] ArgoCD installed (Helm or manifest)
- [ ] All ArgoCD pods Running (5+ pods)
- [ ] ArgoCD UI accessible (port-forward)
- [ ] Admin password changed
- [ ] ArgoCD CLI installed and logged in
- [ ] Git repository connected
- [ ] Prometheus metrics enabled (ServiceMonitors)
- [ ] Test application deployed and synced

### Verifitseerimine

```bash
# 1. All pods Running
kubectl get pods -n argocd

# 2. Check services
kubectl get svc -n argocd

# 3. CLI login test
argocd app list

# 4. Repositories connected
argocd repo list

# 5. Prometheus metrics
kubectl get servicemonitor -n argocd

# 6. Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Open http://localhost:8080
```

---

## 🔍 Troubleshooting

### Probleem: Pods ei lähe Running state

**Sümptomid:**
```
argocd-server-xxx   0/1   CrashLoopBackOff
```

**Lahendus:**

```bash
# Check pod logs
kubectl logs -n argocd <pod-name>

# Check events
kubectl describe pod -n argocd <pod-name>

# Common issue: Insufficient resources
kubectl top nodes
kubectl top pods -n argocd

# Fix: Increase node resources or decrease ArgoCD resource requests
```

---

### Probleem: Cannot access UI (port-forward fails)

**Sümptomid:**
```
error: unable to forward port because pod is not running
```

**Lahendus:**

```bash
# Check if argocd-server pod is Running
kubectl get pods -n argocd | grep argocd-server

# If not Running, check logs
kubectl logs -n argocd deployment/argocd-server

# Restart port-forward
pkill -f "port-forward.*argocd"
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

---

### Probleem: "Unable to connect to repository"

**Sümptomid:**
```
rpc error: code = Unknown desc = authentication required
```

**Lahendus:**

```bash
# For private repos, ensure credentials are correct
argocd repo add https://github.com/YOUR_USERNAME/repo.git \
  --username YOUR_USERNAME \
  --password YOUR_PAT

# Verify connection
argocd repo list

# Check repo-server logs if issues persist
kubectl logs -n argocd deployment/argocd-repo-server
```

---

### Probleem: CLI login fails

**Sümptomid:**
```
FATA[0000] rpc error: code = Unavailable desc = connection refused
```

**Lahendus:**

```bash
# Ensure port-forward is active
kubectl port-forward svc/argocd-server -n argocd 8080:80 &

# Login with correct credentials
argocd login localhost:8080 --username admin --password 'YOUR_PASSWORD' --insecure

# If password forgotten, reset:
kubectl patch secret argocd-secret -n argocd -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'
kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-server
```

---

### Probleem: Prometheus metrics not visible

**Sümptomid:**
- No ArgoCD targets in Prometheus UI

**Lahendus:**

```bash
# Check ServiceMonitors exist
kubectl get servicemonitor -n argocd

# Check Prometheus ServiceMonitor selector
kubectl get prometheus -n monitoring -o yaml | grep serviceMonitorSelector -A5

# Ensure monitoring namespace can scrape argocd namespace (Network Policy from Lab 7)
kubectl get networkpolicy -n argocd

# If needed, create allow-monitoring policy (similar to Lab 7 Exercise 3)
```

---

## 📚 Mida Sa Õppisid?

✅ **ArgoCD Architecture**
  - API Server (UI + REST API)
  - Application Controller (sync engine)
  - Repo Server (manifest generation)
  - Redis (caching)

✅ **Installation Methods**
  - Helm (recommended for production)
  - Manifest (simpler for testing)
  - Configuration via values files

✅ **Access Methods**
  - Web UI (visual management)
  - CLI (automation)
  - REST API (integrations)

✅ **GitOps Concepts**
  - Git as single source of truth
  - Declarative configuration
  - Pull model (vs push in CI/CD)

✅ **Integration Points**
  - Prometheus metrics (Lab 6)
  - RBAC principles (Lab 7)
  - CI/CD workflow (Lab 5)

---

## 🚀 Järgmised Sammud

**Exercise 2: First Application Deployment** - Deploy user-service GitOps workflow'ga:
- Create Application manifest
- Deploy from Git
- Sync strategies (manual vs automatic)
- Health checks and rollback

```bash
cat exercises/02-first-application.md
```

---

## 💡 ArgoCD Best Practices

✅ **Version Control Everything:**
- ArgoCD configuration (Helm values)
- Application manifests
- RBAC policies
- Git as single source of truth

✅ **Use Projects:**
- Logical grouping per team/environment
- Resource whitelisting
- RBAC per project

✅ **Monitoring:**
- Enable Prometheus metrics
- Set up alerts for OutOfSync applications
- Monitor sync duration

✅ **Security:**
- Change default admin password
- Use RBAC (principle of least privilege)
- Private repos with credentials
- SSO integration (Exercise 5)

✅ **Sync Strategies:**
- Start with manual sync (safer)
- Move to automated sync when confident
- Use sync windows for production

---

**Õnnitleme! ArgoCD on paigaldatud ja töötab! 🚀🔄**

**Kestus:** 60 minutit
**Järgmine:** Exercise 2 - First Application Deployment

