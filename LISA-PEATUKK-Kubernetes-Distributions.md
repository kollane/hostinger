# Lisa Peatükk: Kubernetes Distributions ja Ecosystem

**Kestus:** 3-4 tundi
**Eesmärk:** Mõista erinevaid Kubernetes distributions'e, managed teenuseid ja ecosystem'i tööriistu DevOps administraatori vaatenurgast

---

## 📋 Ülevaade

**Kubernetes (K8s)** on konteinerite orkestreerimise platform, aga on **palju erinevaid viise**, kuidas Kubernetes'e käivitada ja hallata:

1. **Vanilla Kubernetes** - "Pure" K8s upstream
2. **Lightweight Distributions** - K3s, K0s, MicroK8s
3. **Enterprise Distributions** - OpenShift, Rancher, Tanzu
4. **Managed Kubernetes** - EKS, AKS, GKE (cloud providers)
5. **Development K8s** - Minikube, Kind, k3d

DevOps administraator peab teadma:
- ✅ Millal kasutada kumba distribution'i
- ✅ Plussid ja miinused
- ✅ Installation ja management
- ✅ Ecosystem tools (Helm, Lens, k9s, ArgoCD)

---

## ☸️ I. KUBERNETES DISTRIBUTIONS

### 1.1 Vanilla Kubernetes (Upstream)

**Definitsioon:**
"Pure" Kubernetes, nagu CNCF (Cloud Native Computing Foundation) releases.

**Installatsioon:**
```bash
# kubeadm (official tool)
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Manual binary install (hard mode)
wget https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl
```

**Plussid:**
- ✅ **Official** - reference implementation
- ✅ **Latest features** - bleeding edge
- ✅ **No vendor lock-in**
- ✅ **Learning** - best for understanding K8s internals

**Miinused:**
- ❌ **Complex setup** (multi-node cluster, networking, storage)
- ❌ **Manual management** (upgrades, backups)
- ❌ **Resource-heavy** (2GB+ RAM per node)
- ❌ **No built-in addons** (need install dashboard, metrics-server manually)

**Kasutusjuhud:**
- Learning (K8s eksam preparation)
- Research (testing new features)
- On-premise bare metal (kui ei taha vendor dependencies)

**Ressursid:**
- Min: 2 vCPU, 2GB RAM (single node)
- Recommended: 3+ nodes (1 master, 2+ workers), 4GB RAM each

---

### 1.2 K3s (Lightweight Kubernetes)

**Definitsioon:**
Rancher Labs (SUSE) loodud **lightweight Kubernetes** (certified CNCF):
- Üks binary (~70MB vs K8s ~1GB)
- Lightweight (~512MB RAM vs 2GB+)
- Production-ready
- Edge/IoT optimized

**Installatsioon:**
```bash
# Single command install!
curl -sfL https://get.k3s.io | sh -

# Check
sudo k3s kubectl get nodes
```

**Arhitektuur:**
- **Embedded etcd** (SQLite kui 1 node, etcd kui 3+ nodes)
- **Traefik** Ingress Controller (default)
- **ServiceLB** Load Balancer (default)
- **Local-path-provisioner** Storage (default)
- **CoreDNS** DNS

**Plussid:**
- ✅ **Lihtne install** (1 command!)
- ✅ **Väike** (~512MB RAM, vs vanilla 2GB+)
- ✅ **Production-ready** (CNCF certified, ~100% K8s API compliance)
- ✅ **Built-in components** (Traefik, storage, LB out-of-box)
- ✅ **ARM support** (Raspberry Pi!)
- ✅ **Auto-updates** (systemd service)

**Miinused:**
- ❌ **Etcd default SQLite** (single node = no HA default, upgrade to etcd multi-node)
- ❌ **Traefik locked** (kui tahad Nginx Ingress, pead disabling Traefik)
- ❌ **Less customization** (kui vanilla K8s)

**Kasutusjuhud:**
- ✅ **VPS deployment** (see on MEIE valik koolituskavas!)
- ✅ Edge computing (Raspberry Pi, IoT devices)
- ✅ CI/CD runners (lightweight test clusters)
- ✅ Development (local laptop K8s)

**Ressursid:**
- Min: 1 vCPU, 512MB RAM (single node)
- Recommended: 2 vCPU, 2GB RAM (production single node)
- HA: 3+ nodes (1GB RAM each)

**Pricing:**
- FREE (open source, Apache 2.0)

**Comparison: K3s vs Vanilla:**
| Aspekt | Vanilla K8s | K3s |
|--------|-------------|-----|
| **Binary size** | ~1GB | 70MB |
| **Memory** | 2GB+ | 512MB+ |
| **Install** | kubeadm (complex) | 1 command |
| **Ingress** | Manual install | Traefik (default) |
| **Storage** | Manual | local-path (default) |
| **ARM support** | Limited | ✅ Full |

---

### 1.3 K0s (Zero Friction Kubernetes)

**Definitsioon:**
Mirantis loodud **zero dependencies** Kubernetes:
- Üks binary (no external dependencies!)
- Zero friction (easy install)
- Vanilla K8s-compatible (100% upstream)

**Installatsioon:**
```bash
# Download binary
curl -sSLf https://get.k0s.sh | sudo sh

# Install as service
sudo k0s install controller --single

# Start
sudo k0s start
```

**Plussid:**
- ✅ **Zero dependencies** (single static binary)
- ✅ **Vanilla-compatible** (100% upstream K8s)
- ✅ **Modular** (choose own Ingress, CNI, storage)
- ✅ **Auto-pilot mode** (auto-updates, self-healing)
- ✅ **Multi-architecture** (x86, ARM)

**Miinused:**
- ❌ **Less opinionated** (need choose Ingress, storage manually)
- ❌ **Newer** (kui K3s, less battle-tested)
- ❌ **Smaller community** (kui K3s)

**K0s vs K3s:**
| Aspekt | K3s | K0s |
|--------|-----|-----|
| **Philosophy** | Opinionated (Traefik default) | Modular (choose own) |
| **Default Ingress** | Traefik | None (choose own) |
| **Default Storage** | local-path | None (choose own) |
| **Maturity** | 2019 (older) | 2020 (newer) |
| **Community** | Larger | Smaller |

**Kasutusjuhud:**
- Kui tahad vanilla K8s experience kuid lihtsa install'iga
- Kui eelistad modulaarsust (choose own components)
- Bare metal deployments

---

### 1.4 MicroK8s (Canonical)

**Definitsioon:**
Canonical (Ubuntu) loodud **minimal Kubernetes** (snap package):
- Low-ops
- Minimal production K8s
- Ubuntu-optimized

**Installatsioon:**
```bash
# Ubuntu/Debian (snap)
sudo snap install microk8s --classic

# Add user to group
sudo usermod -a -G microk8s $USER
newgrp microk8s

# Check status
microk8s status

# Enable addons
microk8s enable dns dashboard ingress storage
```

**Plussid:**
- ✅ **Ubuntu integration** (snap package, auto-updates)
- ✅ **Addon system** (enable dns, dashboard, prometheus 1 command'iga)
- ✅ **Multi-node** (easy clustering)
- ✅ **Strict confinement** (security via snap isolation)

**Miinused:**
- ❌ **Snap dependency** (ainult snap-supported distros)
- ❌ **Ubuntu-centric** (other distros supported, aga not first-class)
- ❌ **Snap overhead** (snapd daemon)

**MicroK8s vs K3s:**
| Aspekt | K3s | MicroK8s |
|--------|-----|----------|
| **Package** | Binary | Snap |
| **Distro** | Any | Ubuntu-optimized |
| **Addons** | Built-in | Enable manually |
| **Community** | CNCF/Rancher | Canonical |

**Kasutusjuhud:**
- Ubuntu servers (Canonical support)
- Workstations (developer laptops Ubuntu)
- IoT (Ubuntu Core devices)

---

### 1.5 RKE2 (Rancher Kubernetes Engine 2)

**Definitsioon:**
Rancher (SUSE) **security-focused** Kubernetes:
- FIPS 140-2 compliant
- CIS Kubernetes Benchmark compliant
- Government/enterprise focus

**Plussid:**
- ✅ **Security hardened** (FIPS, CIS, STIGs)
- ✅ **Air-gapped** support
- ✅ **Rancher integration** (managed by Rancher UI)

**Miinused:**
- ❌ **Enterprise-focused** (overkill startups'ile)
- ❌ **Resource-heavy** (kui K3s)

**Kasutusjuhud:**
- Government (FIPS compliance)
- Enterprise security requirements
- Air-gapped environments

---

## ☁️ II. MANAGED KUBERNETES (Cloud)

### 2.1 AWS EKS (Elastic Kubernetes Service)

**Definitsioon:**
AWS managed Kubernetes control plane.

**Setup:**
```bash
# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create cluster
eksctl create cluster \
  --name my-cluster \
  --region us-west-2 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3

# ~15 min creation time
```

**Plussid:**
- ✅ **No control plane management** (AWS haldab master node'd)
- ✅ **Integrated** (IAM, VPC, ELB, EBS, S3)
- ✅ **Auto-upgrades** (control plane)
- ✅ **Fargate** (serverless pods, no nodes!)

**Miinused:**
- ❌ **Expensive** ($0.10/h control plane = $73/month + node costs)
- ❌ **AWS lock-in**
- ❌ **Slower updates** (kui upstream K8s, 3-6 months lag)

**Pricing:**
```
EKS Control Plane: $73/month
Worker Nodes (3x t3.medium): $90/month
TOTAL: ~$163/month minimum
```

**Viide:** Lisa Peatükk Cloud Providers (AWS sektsioon)

---

### 2.2 Azure AKS (Azure Kubernetes Service)

**Definitsioon:**
Microsoft Azure managed Kubernetes.

**Plussid:**
- ✅ **FREE control plane!** (vs EKS $73/month)
- ✅ **Azure integration** (Active Directory, Azure Monitor)
- ✅ **Windows nodes** (best Windows container support)

**Miinused:**
- ❌ **Azure lock-in**
- ❌ **Less mature** (kui EKS)

**Pricing:**
```
AKS Control Plane: FREE
Worker Nodes (3x Standard_B2s): $90/month
TOTAL: ~$90/month
```

**Viide:** Lisa Peatükk Cloud Providers (Azure sektsioon)

---

### 2.3 GCP GKE (Google Kubernetes Engine)

**Definitsioon:**
Google Cloud managed Kubernetes (Google INVENTED Kubernetes!).

**Plussid:**
- ✅ **Best K8s experience** (Google created K8s!)
- ✅ **Fastest updates** (latest K8s features first)
- ✅ **Auto-pilot mode** (fully managed nodes + control plane)
- ✅ **GCP integration** (Cloud SQL, Cloud Storage)

**Miinused:**
- ❌ **GCP lock-in**
- ❌ **Expensive** ($73/month control plane standard mode)

**Pricing:**
```
GKE Standard:
- Control Plane: $73/month
- Worker Nodes (3x n1-standard-2): $145/month
- TOTAL: ~$218/month

GKE Autopilot (fully managed):
- No control plane fee
- Pay per pod resource usage
- ~$150-300/month (varies)
```

**Viide:** Lisa Peatükk Cloud Providers (GCP sektsioon)

---

### 2.4 DigitalOcean Kubernetes (DOKS)

**Definitsioon:**
DigitalOcean managed Kubernetes (developer-friendly).

**Plussid:**
- ✅ **FREE control plane!**
- ✅ **Simple UI** (beginner-friendly)
- ✅ **Predictable pricing** (flat rates)

**Pricing:**
```
DOKS Control Plane: FREE
Worker Nodes (3x Droplet $12/month): $36/month
TOTAL: ~$36/month

vs EKS: $163/month (4.5x cheaper!)
```

**Viide:** Lisa Peatükk Cloud Providers (DigitalOcean sektsioon)

---

## 🛠️ III. KUBERNETES ECOSYSTEM TOOLS

### 3.1 Package Management

#### Helm (The Kubernetes Package Manager)

**Definitsioon:**
Kubernetes **package manager** - install complex apps (PostgreSQL, Prometheus, GitLab) koos konfigu templating'uga.

**Install:**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Kasutamine:**
```bash
# Add repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install PostgreSQL
helm install my-postgres bitnami/postgresql

# List releases
helm list

# Upgrade
helm upgrade my-postgres bitnami/postgresql --set auth.password=newsecret

# Rollback
helm rollback my-postgres 1
```

**Plussid:**
- ✅ **Reusability** (don't reinvent YAML)
- ✅ **Templating** (values.yaml parameterization)
- ✅ **Version control** (release history)
- ✅ **Rollback** (easy revert)

**Miinused:**
- ❌ **Complexity** (learning curve)
- ❌ **Templating bugs** (YAML templating errors)

**Kasutusjuhud:**
- Install complex apps (Prometheus, Grafana, PostgreSQL)
- Multi-environment (dev/staging/prod same chart, different values)
- Release management (rollback failed deploys)

---

#### Kustomize (Template-free Configuration)

**Definitsioon:**
**Patch-based** Kubernetes configuration (built into kubectl).

**Kasutamine:**
```bash
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

images:
  - name: my-app
    newTag: v2.0.0

# Apply
kubectl apply -k .
```

**Plussid:**
- ✅ **No templating** (pure YAML patching)
- ✅ **Built-in** (kubectl native)
- ✅ **Simpler** (kui Helm, less magic)

**Miinused:**
- ❌ **Less powerful** (kui Helm templating)
- ❌ **No package management** (ei ole chart repository)

**Helm vs Kustomize:**
| Aspekt | Helm | Kustomize |
|--------|------|-----------|
| **Approach** | Templating (Go templates) | Patching (overlay) |
| **Package mgmt** | ✅ Charts, repos | ❌ No |
| **Rollback** | ✅ Built-in | ❌ Manual (via Git) |
| **Complexity** | Higher | Lower |
| **Use case** | Complex apps, multi-env | Simple apps, GitOps |

---

### 3.2 GitOps Tools

#### ArgoCD (Declarative GitOps)

**Definitsioon:**
**GitOps** continuous delivery tool - Git repository on **single source of truth**.

**Workflow:**
```
1. Commit manifest to Git (deployment.yaml)
2. ArgoCD detects change
3. ArgoCD auto-syncs to Kubernetes
4. Application deployed!
```

**Install:**
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

**Plussid:**
- ✅ **Git as source of truth** (audit trail, rollback via Git)
- ✅ **Auto-sync** (Git commit → auto deploy)
- ✅ **Multi-cluster** (manage multiple K8s clusters)
- ✅ **Web UI** (visualize apps)
- ✅ **RBAC** (who can deploy what)

**Miinused:**
- ❌ **Learning curve** (GitOps mindset shift)
- ❌ **Git required** (no manual kubectl apply)

**Kasutusjuhud:**
- GitOps workflows (everything in Git)
- Multi-cluster management
- Enterprise (audit, compliance)

---

#### Flux (GitOps Toolkit)

**Definitsioon:**
CNCF **GitOps** toolkit (alternative to ArgoCD).

**Plussid:**
- ✅ **CNCF project** (vendor-neutral)
- ✅ **Pull-based** (cluster pulls from Git, not push)
- ✅ **Helm support** (native)

**Flux vs ArgoCD:**
| Aspekt | ArgoCD | Flux |
|--------|--------|------|
| **UI** | ✅ Web UI | ❌ CLI only (Weave GitOps paid UI) |
| **Maturity** | More mature | CNCF Incubating |
| **Helm** | Supported | Native (better) |
| **Learning curve** | Easier (UI) | Harder (CLI) |

---

### 3.3 CLI ja UI Tools

#### kubectl (Official CLI)

**Definitsioon:**
Official Kubernetes CLI.

**Kasulikud pluginad:**
```bash
# krew (kubectl plugin manager)
curl -fsSLO https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz
tar zxvf krew-linux_amd64.tar.gz
./krew-linux_amd64 install krew

# Plugins
kubectl krew install ctx   # Switch contexts
kubectl krew install ns    # Switch namespaces
kubectl krew install tree  # Tree view resources
```

---

#### k9s (Terminal UI)

**Definitsioon:**
**Terminal UI** Kubernetes management (ncurses).

**Install:**
```bash
# Homebrew (Mac/Linux)
brew install k9s

# Binary
curl -sS https://webinstall.dev/k9s | bash
```

**Features:**
- ✅ **Live updates** (pods, logs, events real-time)
- ✅ **Keyboard shortcuts** (Vim-like)
- ✅ **Log streaming** (view logs in UI)
- ✅ **Port forwarding** (one key)
- ✅ **Exec into pods** (shell access)

**Plussid:**
- ✅ **Faster** (kui kubectl get, kubectl logs switching)
- ✅ **Intuitive** (visual, no memorizing commands)
- ✅ **Lightweight** (terminal, no browser)

---

#### Lens (Kubernetes IDE)

**Definitsioon:**
**Desktop GUI** Kubernetes management (Electron app).

**Plussid:**
- ✅ **Visual** (charts, graphs, metrics)
- ✅ **Multi-cluster** (manage multiple clusters in one UI)
- ✅ **Integrated terminal** (kubectl built-in)
- ✅ **Prometheus metrics** (integrated)
- ✅ **Extensions** (plugin system)

**Miinused:**
- ❌ **Resource-heavy** (Electron app, RAM hungry)
- ❌ **Desktop only** (no SSH remote management)

**k9s vs Lens:**
| Aspekt | k9s | Lens |
|--------|-----|------|
| **Type** | Terminal (TUI) | Desktop (GUI) |
| **Resource** | Lightweight (~20MB RAM) | Heavy (~500MB RAM) |
| **Remote** | ✅ SSH friendly | ❌ Desktop only |
| **Metrics** | Basic | ✅ Prometheus charts |
| **Use case** | SSH servers, minimal | Workstation, visual |

---

### 3.4 Service Mesh (Advanced)

#### Istio

**Definitsioon:**
**Service mesh** - add observability, security, traffic management to microservices.

**Features:**
- Traffic management (canary, blue-green)
- Security (mTLS, auth)
- Observability (distributed tracing)

**Plussid:**
- ✅ **Feature-rich** (most comprehensive)
- ✅ **Google backed** (maturity)

**Miinused:**
- ❌ **Complex** (steep learning curve)
- ❌ **Resource-heavy** (sidecars add overhead)

---

#### Linkerd

**Definitsioon:**
**Lightweight service mesh** (simpler kui Istio).

**Plussid:**
- ✅ **Lightweight** (Rust-based, fast)
- ✅ **Simple** (easier kui Istio)
- ✅ **CNCF** (graduated project)

**Miinused:**
- ❌ **Fewer features** (kui Istio)

**Istio vs Linkerd:**
| Aspekt | Istio | Linkerd |
|--------|-------|---------|
| **Complexity** | High | Low |
| **Resources** | Heavy | Lightweight |
| **Features** | Comprehensive | Essential |
| **Maturity** | More mature | CNCF Graduated |
| **Use case** | Enterprise, full-featured | Startups, simple |

---

## 📊 IV. VÕRDLUS JA SOOVITUSED

### 4.1 Distribution Võrdlus

| Distribution | Pros | Cons | Best For |
|--------------|------|------|----------|
| **K3s** | ✅ Lightweight, easy, production-ready | ❌ Traefik locked-in | ✅ VPS, Edge, IoT |
| **K0s** | ✅ Modular, vanilla-compatible | ❌ Newer, smaller community | Bare metal, modular |
| **MicroK8s** | ✅ Ubuntu integration, addons | ❌ Snap dependency | Ubuntu servers |
| **Vanilla** | ✅ Official, latest features | ❌ Complex setup, resource-heavy | Learning, on-premise |
| **EKS** | ✅ AWS integration, no control plane mgmt | ❌ Expensive ($163/mo min) | AWS enterprise |
| **GKE** | ✅ Best K8s (Google created it!) | ❌ Expensive | GCP, K8s-heavy |
| **DOKS** | ✅ FREE control plane, simple | ❌ Fewer features | Startups, budget |

---

### 4.2 Soovitused DevOps Administraatorile

**Õppimiseks (Learning):**
1. **Alusta:** K3s VPS'is (meie koolituskava!)
2. **Edasi:** Vanilla Kubernetes (kubeadm, eksam prep)
3. **Cloud:** GKE free tier ($300 credit) või DOKS (free control plane)

**Production Use Cases:**

**Stsenaarium 1: Startup, VPS, Budget**
- ✅ **K3s** VPS'is ($25/month DigitalOcean)
- Why: Cheap, production-ready, simple

**Stsenaarium 2: Startup, Cloud, Scaling**
- ✅ **DOKS** (DigitalOcean K8s) or **GKE Autopilot**
- Why: Free control plane (DOKS) or fully managed (GKE)

**Stsenaarium 3: Enterprise, AWS, Compliance**
- ✅ **EKS** (AWS managed K8s)
- Why: AWS integration, enterprise support

**Stsenaarium 4: Enterprise, Multi-cloud**
- ✅ **Rancher** (manages EKS, AKS, GKE, on-premise)
- Why: Unified management across clouds

**Stsenaarium 5: Government, Air-gapped**
- ✅ **RKE2** (security hardened)
- Why: FIPS, CIS compliance

**Stsenaarium 6: Edge/IoT**
- ✅ **K3s** (Raspberry Pi, ARM devices)
- Why: Lightweight, ARM support

---

### 4.3 Ecosystem Tools Soovitused

**Must-Have:**
- ✅ **kubectl** - official CLI (no choice!)
- ✅ **Helm** - package management (install Prometheus, PostgreSQL)
- ✅ **k9s** or **Lens** - UI (k9s kui SSH, Lens kui workstation)

**Recommended:**
- ✅ **ArgoCD** or **Flux** - GitOps (CI/CD automation)
- ✅ **kubectx/kubens** - context switching (multi-cluster)

**Advanced:**
- ✅ **Istio** or **Linkerd** - service mesh (kui microservices heavy)
- ✅ **Rancher** - multi-cluster management

---

## 🎓 V. LEARNING PATH

### Samm 1: K3s VPS'is (Meie Koolituskava)
- Install K3s VPS'is
- Deploy apps (Lab 3-4)
- Learn kubectl, Helm, k9s

### Samm 2: Vanilla Kubernetes (Eksam Prep)
- kubeadm install
- Multi-node cluster
- CKA exam prep

### Samm 3: Managed Kubernetes (Cloud)
- GKE free tier ($300 credit)
- Deploy same apps kui Lab 3-4
- Compare VPS vs Cloud

### Samm 4: GitOps (Advanced)
- ArgoCD install K3s'is
- Git-based deployments
- Auto-sync

### Samm 5: Certifications
- ✅ **CKA** (Certified Kubernetes Administrator)
- ✅ **CKAD** (Certified Kubernetes Application Developer)
- ✅ **CKS** (Certified Kubernetes Security Specialist)

---

## 📚 VI. VIITED

**Official Docs:**
- Kubernetes: https://kubernetes.io/docs/
- K3s: https://docs.k3s.io/
- K0s: https://docs.k0sproject.io/
- MicroK8s: https://microk8s.io/docs
- Helm: https://helm.sh/docs/
- ArgoCD: https://argo-cd.readthedocs.io/

**Managed K8s:**
- EKS: https://docs.aws.amazon.com/eks/
- AKS: https://learn.microsoft.com/azure/aks/
- GKE: https://cloud.google.com/kubernetes-engine/docs

**Tools:**
- k9s: https://k9scli.io/
- Lens: https://k8slens.dev/
- Istio: https://istio.io/docs/
- Linkerd: https://linkerd.io/docs/

---

## ✅ KOKKUVÕTE

**DevOps Administraator peab teadma:**

**Distributions:**
- ✅ **K3s** - lightweight, production VPS (MEIE VALIK!)
- ✅ **EKS/AKS/GKE** - managed cloud K8s
- ✅ **Vanilla K8s** - learning, eksam prep

**Tools:**
- ✅ **kubectl** - CLI (must-have)
- ✅ **Helm** - package management
- ✅ **k9s/Lens** - UI
- ✅ **ArgoCD** - GitOps (advanced)

**Soovitus:**
- 🎓 **Learn:** K3s VPS → Vanilla K8s → Managed GKE/DOKS
- 🛠️ **Tools:** kubectl + Helm + k9s (minimum)
- 📜 **Certify:** CKA → CKAD → CKS

---

**Edu Kubernetes learning'ul! ☸️**

*Kubernetes on DevOps administraatori kõige olulisem skill 2025!*
