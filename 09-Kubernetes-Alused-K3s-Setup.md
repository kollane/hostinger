# Peatükk 9: Kubernetes Alused ja K3s Setup

**Kestus:** 4 tundi
**Tase:** Keskmine
**Eeldused:** Docker põhitõed selged (Peatükk 4-6)

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist oskad:

1. ✅ Selgitada Kubernetes orkestreerimise põhimõtteid
2. ✅ Mõista Kubernetes arhitektuuri (Control Plane, Worker Nodes)
3. ✅ Selgitada Pods, Deployments, Services rolli
4. ✅ Mõista K3s vs vanilla Kubernetes trade-off'e
5. ✅ Selgitada kubectl rolli Kubernetes ecosystem'is
6. ✅ Mõista declarative vs imperative configuration
7. ✅ Selgitada Namespaces ja Labels rolli
8. ✅ Mõista self-healing ja auto-scaling concepts

---

## 🎯 1. Container Orchestration: Miks Kubernetes?

### 1.1 Docker Compose Limitations

**Docker Compose (õpitud Peatükis 7) on suurepärane small-scale deploymentideks:**

- Multi-container aplikatsioonid ühes serveris
- Deklaratiivne config (docker-compose.yml)
- Easy development environment

**Aga Docker Compose limitations:**

1. **Single-host:** Töötab ainult ÜHES serveris
   - Ei saa jaotada containereid mitme serveri vahel
   - Server crash → kogu rakendus down

2. **No auto-scaling:**
   - Load suureneb → pead käsitsi rohkem containereid käivitama
   - Ei ole automaatne scaling

3. **No self-healing:**
   - Container crash → jääb surnuks
   - Pead käsitsi restartima

4. **No rolling updates:**
   - Deploy uus versioon → downtime (stop old, start new)
   - Ei ole zero-downtime deployment

5. **No load balancing:**
   - Kui 3 backend containerit → pead ise nginx reverse proxy seadistama

**When Docker Compose stops being enough:**

```
Development: 5 containers on 1 VPS → Docker Compose ✅
Staging: 20 containers on 1 VPS → Docker Compose struggles ⚠️
Production: 100 containers on 5 servers → NEED ORCHESTRATION ❌
```

---

### 1.2 Kubernetes: Container Orchestration Platform

**Kubernetes lahendab orkestreerimise probleemi:**

> "Kubernetes is a portable, extensible, open-source platform for managing containerized workloads and services."

**Core capabilities:**

1. **Multi-node deployment:**
   - Distribute containerid across multiple servers (nodes)
   - Cluster concept: N servers work as ONE logical unit

2. **Auto-scaling:**
   - Horizontal Pod Autoscaler (HPA): Load suureneb → deploy rohkem Pods
   - Vertical Pod Autoscaler (VPA): Increase Pod resources (CPU, memory)

3. **Self-healing:**
   - Pod crashib → Kubernetes restartib automaatselt
   - Node fails → reschedule Pods teistesse Nodes'desse

4. **Rolling updates:**
   - Deploy uus versioon incrementally (10% → 50% → 100%)
   - Zero downtime
   - Automatic rollback kui uus versioon fails health checks

5. **Load balancing:**
   - Service abstraction: Stable endpoint (ClusterIP, LoadBalancer)
   - Automatic load balancing across Pod replicas

6. **Service discovery:**
   - DNS-based: Service names resolve to Pod IPs
   - Environment variables: Injected into Pods

7. **Secret/Config management:**
   - ConfigMap: Configuration data
   - Secret: Sensitive data (encrypted at rest)

**Use case comparison:**

| Complexity | Tool | Reasoning |
|------------|------|-----------|
| **Simple (1-10 containers, 1 server)** | Docker Compose | Lightweight, easy config |
| **Medium (10-50 containers, 1-2 servers)** | Docker Swarm / Docker Compose | Still manageable |
| **Complex (50+ containers, 3+ servers)** | Kubernetes | Orchestration essential |
| **Enterprise (100s-1000s containers)** | Kubernetes | Industry standard |

---

### 1.3 Kubernetes Adoption and Industry Standard

**Why Kubernetes won the orchestration war:**

1. **CNCF (Cloud Native Computing Foundation):**
   - Vendor-neutral (not owned by single company)
   - Google donated original Borg/Omega ideas → Kubernetes

2. **Cloud provider support:**
   - AWS EKS (Elastic Kubernetes Service)
   - Azure AKS (Azure Kubernetes Service)
   - GCP GKE (Google Kubernetes Engine)

3. **Ecosystem:**
   - Helm (package manager)
   - Prometheus (monitoring)
   - Istio (service mesh)
   - ArgoCD (GitOps)

4. **Job market:**
   - Kubernetes skill = high demand DevOps talent
   - Most job listings require Kubernetes experience

**Miks me õpime Kubernetes'e?**

- Industry standard (90%+ Fortune 500 companies use it)
- Essential DevOps skill
- Foundation for cloud-native architectures
- Transferable knowledge (EKS, AKS, GKE, OpenShift)

---

## 🏗️ 2. Kubernetes Arhitektuur: Control Plane + Worker Nodes

### 2.1 Cluster Architecture

**Kubernetes cluster koosneb kahest osast:**

```
Control Plane (Master)    Worker Nodes (where Pods run)
        ↓                           ↓
   [API Server]              [Node 1: kubelet, Pods]
   [Scheduler]               [Node 2: kubelet, Pods]
   [Controller Manager]      [Node 3: kubelet, Pods]
   [etcd]
```

**Why this separation?**

- **Control Plane:** "Brain" - makes decisions (scheduling, scaling, updates)
- **Worker Nodes:** "Muscle" - runs actual workloads (Pods)

**Benefit:** Control Plane can manage hundreds of Worker Nodes

---

### 2.2 Control Plane Components

**1. API Server:**

- **Role:** REST API for Kubernetes (kubectl talks to API Server)
- **Responsibility:** Authentication, authorization, admission control
- **Architecture:** Stateless (can scale horizontally for HA)

**Why important:** Single source of truth - all operations go through API Server

**2. Scheduler:**

- **Role:** Decides WHICH Node a Pod should run on
- **Logic:**
  - Node has enough resources (CPU, memory)?
  - Pod has affinity/anti-affinity rules?
  - Node has required taints/tolerations?
- **Output:** Binding (Pod → Node)

**Why important:** Efficient resource utilization (pack Pods optimally)

**3. Controller Manager:**

- **Role:** Runs control loops (reconciliation loops)
- **Examples:**
  - **ReplicaSet Controller:** Ensure N replicas of Pod are running
  - **Deployment Controller:** Manage rolling updates
  - **Node Controller:** Detect failed Nodes

**How it works:**

```
Desired state (Deployment: replicas=3)
    ↓
Current state (2 Pods running)
    ↓
Reconciliation loop: Create 1 more Pod → Desired = Current
```

**Why important:** Self-healing, auto-scaling (desired state → actual state)

**4. etcd:**

- **Role:** Distributed key-value store (cluster state database)
- **Stores:** All cluster data (Pods, Services, ConfigMaps, Secrets)
- **Architecture:** Raft consensus (distributed, fault-tolerant)

**Why important:** Source of truth for cluster state (if etcd dies, cluster dies)

---

### 2.3 Worker Node Components

**1. kubelet:**

- **Role:** Agent that runs on each Worker Node
- **Responsibility:**
  - Receives Pod specs from API Server
  - Ensures Pods are running and healthy
  - Reports Node and Pod status back to API Server

**How it works:**

```
API Server: "Node 1, run Pod X"
    ↓
kubelet (Node 1): "OK, starting Pod X via container runtime"
    ↓
Container Runtime: docker run / containerd
    ↓
kubelet: "Pod X is running, reporting back to API Server"
```

**2. kube-proxy:**

- **Role:** Network proxy (implements Service abstraction)
- **Responsibility:**
  - Maintains network rules (iptables / IPVS)
  - Load balances traffic to Pod replicas

**Example:**

```
Service "backend" → 3 Pod replicas (10.1.0.2, 10.1.0.3, 10.1.0.4)
    ↓
kube-proxy: iptables rules → round-robin to 3 Pods
```

**3. Container Runtime:**

- **Role:** Actually runs containers
- **Options:**
  - Docker (deprecated in K8s 1.24+)
  - containerd (CNCF graduated, default in K3s)
  - CRI-O (Red Hat)

**CRI (Container Runtime Interface):** Standard interface → Kubernetes agnostic to runtime

---

## 🐧 3. K3s: Lightweight Kubernetes for VPS

### 3.1 Vanilla Kubernetes vs K3s

**Vanilla Kubernetes challenges:**

1. **Complex setup:**
   - kubeadm init (initialize Control Plane)
   - Certificate management (PKI infrastructure)
   - CNI plugin installation (Calico, Flannel for networking)
   - Worker Node join (tokens, certificates)
   - Estimated setup time: 1-2 hours (with troubleshooting)

2. **Resource requirements:**
   - Control Plane: 2GB RAM minimum
   - Worker Node: 2GB RAM minimum
   - Minimum cluster: 6GB RAM (3 nodes × 2GB)

3. **Components:**
   - Separate binaries for each component (kube-apiserver, kube-scheduler, etc.)
   - Total binary size: ~200MB
   - Complex dependency management

**K3s solution:**

> "K3s is a highly available, certified Kubernetes distribution designed for production workloads in unattended, resource-constrained, remote locations or inside IoT appliances."

**Key differences:**

1. **Simple installation:**
   - One command: `curl -sfL https://get.k3s.io | sh -`
   - Estimated setup time: 2 minutes

2. **Lightweight:**
   - 512MB RAM sufficient for small workloads
   - Binary size: ~50MB (vs 200MB vanilla)

3. **Single binary:**
   - All components in one binary (k3s)
   - Easier management, smaller attack surface

4. **Batteries included:**
   - Built-in storage provider (local-path-provisioner)
   - Built-in load balancer (ServiceLB)
   - Built-in Ingress controller (Traefik)

**What's removed in K3s?**

- Legacy, alpha features
- Cloud provider integrations (unnecessary for VPS)
- In-tree storage plugins (replaced by CSI)

**What's the same?**

- **100% certified Kubernetes** (CNCF conformance tests pass)
- Same API (kubectl works identically)
- Same manifests (YAML files compatible)

**Trade-offs:**

| Aspect | Vanilla K8s | K3s |
|--------|------------|-----|
| **Certification** | ✅ Official | ✅ CNCF certified |
| **Production use** | ✅ Large scale | ✅ Small-medium scale |
| **Resource usage** | ❌ High (2GB+) | ✅ Low (512MB) |
| **Setup complexity** | ❌ Complex | ✅ Simple |
| **Cloud integrations** | ✅ Native | ⚠️ Manual setup |
| **Use case** | Enterprise, cloud | VPS, Edge, IoT |

---

### 3.2 K3s Architecture Simplifications

**How K3s achieves lightweight:**

1. **SQLite instead of etcd (optional):**
   - Default: SQLite (embedded database)
   - Optional: External etcd for HA
   - Benefit: No separate etcd cluster needed

2. **Containerd instead of Docker:**
   - Docker deprecated in K8s → K3s uses containerd directly
   - Benefit: Less overhead (no Docker daemon)

3. **Single binary packaging:**
   - All Control Plane components in one process
   - Benefit: Lower memory footprint (shared libraries)

4. **Simplified networking:**
   - Default CNI: Flannel (lightweight)
   - Optional: Replace with Calico, Cilium

**Why K3s for our training:**

- ✅ Works on modest VPS (2GB RAM total)
- ✅ Fast setup (focus on learning, not infrastructure)
- ✅ Production-ready (Rancher Labs, SUSE acquired)
- ✅ Skills transferable to vanilla K8s, EKS, AKS, GKE

📖 **Lisalugemine:** `LISA-PEATUKK-Kubernetes-Distributions.md` (K3s, K0s, MicroK8s, EKS, AKS, GKE comparisons)

📖 **Praktika:** Labor 3, Harjutus 1 - K3s installation and verification

---

## 🛠️ 4. kubectl: Kubernetes Command-Line Interface

### 4.1 kubectl Role in Kubernetes Ecosystem

**kubectl on Kubernetes CLI** (command-line interface)

**Architecture:**

```
kubectl (CLI) → REST API calls → API Server → etcd / Scheduler / Controllers
```

**Why kubectl?**

1. **Declarative interface:**
   - Apply desired state (kubectl apply -f deployment.yaml)
   - Kubernetes reconciles current → desired

2. **Imperative commands:**
   - Quick operations (kubectl create, kubectl delete)
   - Development/debugging

3. **Observability:**
   - Get resources (kubectl get pods)
   - Describe resources (kubectl describe pod)
   - Logs (kubectl logs)

**kubectl vs kubeconfig:**

- **kubectl:** Binary executable (CLI tool)
- **kubeconfig:** Configuration file (~/.kube/config)
  - Cluster endpoint (API Server URL)
  - Authentication credentials (certificates, tokens)
  - Context (which cluster + which user + which namespace)

---

### 4.2 Declarative vs Imperative Configuration

**Imperative (command-based):**

```
kubectl create deployment nginx --image=nginx:1.25-alpine
kubectl scale deployment nginx --replicas=3
kubectl expose deployment nginx --port=80
```

**Problem:**
- No source of truth (commands not saved)
- Hard to reproduce (must remember commands)
- No version control

**Declarative (YAML-based):**

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
```

```bash
kubectl apply -f deployment.yaml
```

**Benefits:**
- ✅ Infrastructure as Code (Git version control)
- ✅ Reproducible (same YAML → same result)
- ✅ Reviewable (Git pull requests)
- ✅ Auditable (Git history)

**Best practice:** Use declarative for production, imperative for quick dev/debug

---

### 4.3 kubectl Context and Kubeconfig

**Context concept:**

```
Context = Cluster + User + Namespace

Example contexts:
- dev-context: dev-cluster + dev-user + dev-namespace
- prod-context: prod-cluster + prod-user + prod-namespace
```

**Why contexts?**

- Manage multiple clusters from one machine (dev, staging, prod)
- Switch between clusters easily (kubectl config use-context prod)

**Kubeconfig structure:**

```yaml
clusters:        # List of Kubernetes clusters
- name: k3s
  cluster:
    server: https://127.0.0.1:6443
    certificate-authority-data: <base64>

users:           # List of users (credentials)
- name: k3s-admin
  user:
    client-certificate-data: <base64>
    client-key-data: <base64>

contexts:        # Context = cluster + user + namespace
- name: k3s-default
  context:
    cluster: k3s
    user: k3s-admin
    namespace: default

current-context: k3s-default  # Active context
```

**Security note:** Kubeconfig contains credentials - treat like SSH private key!

📖 **Praktika:** Labor 3, Harjutus 2 - kubectl commands and kubeconfig setup

---

## 📦 5. Kubernetes Objects: Core Abstractions

### 5.1 Pod: Smallest Deployable Unit

**What is a Pod?**

- **Definition:** Group of one or more containers
- **Shared resources:**
  - Network namespace (same IP address, localhost works)
  - Storage volumes (mounted to all containers in Pod)
  - IPC namespace (inter-process communication)

**Why Pods, not just containers?**

**Sidecar pattern:**

```
Pod:
  - Main container: Application (nginx)
  - Sidecar container: Log forwarder (fluent-bit)

Both share:
  - Same IP
  - Can communicate via localhost
  - Can share volume (logs written by nginx, read by fluent-bit)
```

**Pod lifecycle:**

```
Pending → Running → Succeeded/Failed
    ↓
   CrashLoopBackOff (if restartPolicy: Always)
```

**Pod is ephemeral:**

- Pod crash/delete → new Pod created (DIFFERENT IP!)
- Don't rely on Pod IP (use Service for stable endpoint)

---

### 5.2 ReplicaSet: Ensuring Desired Replicas

**What is a ReplicaSet?**

- **Role:** Ensures N replicas of Pod are running
- **Reconciliation loop:**
  ```
  Desired replicas: 3
  Current replicas: 2
  Action: Create 1 more Pod
  ```

**Why ReplicaSet?**

1. **High availability:** Pod crash → ReplicaSet creates new Pod
2. **Load distribution:** 3 replicas → distribute traffic
3. **Rolling updates:** Deployment manages ReplicaSets (old + new)

**ReplicaSet vs Deployment:**

- **ReplicaSet:** Low-level (manages Pods)
- **Deployment:** High-level (manages ReplicaSets, rolling updates)

**Best practice:** Don't create ReplicaSets directly - use Deployments

---

### 5.3 Deployment: Declarative Updates

**What is a Deployment?**

- **Role:** Manages ReplicaSets, provides declarative updates
- **Features:**
  - Rolling updates (gradual rollout)
  - Rollback (revert to previous version)
  - Pause/Resume (during deployment)

**How rolling updates work:**

```
Deployment:
  replicas: 3
  image: myapp:v1

Update to myapp:v2:
  1. Create new ReplicaSet (myapp:v2)
  2. Scale up new ReplicaSet: 0 → 1 → 2 → 3
  3. Scale down old ReplicaSet: 3 → 2 → 1 → 0
  4. Old ReplicaSet kept (for rollback)
```

**Deployment strategies:**

- **RollingUpdate (default):** Gradual (maxSurge=25%, maxUnavailable=25%)
- **Recreate:** All old Pods deleted, then new Pods created (downtime!)

---

### 5.4 Service: Stable Network Endpoint

**Why Service?**

**Problem:** Pods have dynamic IPs (Pod restarts → new IP)

**Solution:** Service provides stable endpoint

**Service types:**

1. **ClusterIP (default):**
   - Internal-only (accessible within cluster)
   - Use case: Backend API accessible only from Frontend

2. **NodePort:**
   - Exposes Service on each Node's IP at static port (30000-32767)
   - Use case: Development, testing (not recommended for production)

3. **LoadBalancer:**
   - Cloud provider provisions external load balancer (AWS ELB, Azure LB)
   - Use case: Production external access

4. **ExternalName:**
   - DNS CNAME redirect (for external databases)
   - Use case: External PostgreSQL (AWS RDS)

**Service discovery:**

```
Service "backend" (ClusterIP: 10.96.0.10)
    ↓ DNS
Backend Service resolvable at: backend.default.svc.cluster.local
    ↓
Pods can use: DB_HOST=backend (automatic DNS resolution)
```

📖 **Praktika:** Labor 3, Harjutus 3 - Pod, Deployment, Service deployment

---

## 🏷️ 6. Namespaces and Labels: Organization

### 6.1 Namespaces: Logical Cluster Partitioning

**What are Namespaces?**

- **Definition:** Virtual clusters within physical cluster
- **Purpose:** Isolate resources (dev, staging, prod in same cluster)

**Default namespaces:**

```
default        - Default namespace for user resources
kube-system    - Kubernetes system components (API Server, Scheduler)
kube-public    - Publicly readable (kubeconfig, cluster info)
kube-node-lease - Node heartbeats (kubelet liveness)
```

**Why Namespaces?**

1. **Multi-tenancy:**
   - Team A: namespace-a
   - Team B: namespace-b
   - Resource isolation (quotas, RBAC)

2. **Environment separation:**
   - dev namespace (development workloads)
   - staging namespace (pre-production testing)
   - prod namespace (production workloads)

3. **Resource quotas:**
   - Limit CPU/memory per namespace
   - Prevent resource hogging

**Namespace caveats:**

- Namespaces NOT security boundary (need RBAC + NetworkPolicy)
- Some resources are cluster-wide (Nodes, PersistentVolumes, StorageClasses)

---

### 6.2 Labels and Selectors: Resource Grouping

**What are Labels?**

- **Definition:** Key-value pairs attached to objects (Pods, Services, etc.)
- **Purpose:** Organize and select resources

**Example:**

```yaml
metadata:
  labels:
    app: frontend
    tier: web
    environment: production
    version: v1.2.3
```

**Why Labels?**

**Selectors match labels:**

```
Service selector: app=backend
    ↓
Selects all Pods with label app=backend
    ↓
Load balances traffic to matched Pods
```

**Deployment selector:**

```yaml
spec:
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend    # Pod template MUST match selector
```

**Label best practices:**

- **app:** Application name (frontend, backend, database)
- **tier:** Architecture tier (web, api, db)
- **environment:** Environment (dev, staging, prod)
- **version:** Application version (v1.2.3)

**Use cases:**

- Service selects Pods
- Deployment manages Pods
- kubectl get pods -l app=backend (filter by label)
- NetworkPolicy selects Pods for firewall rules

📖 **Praktika:** Labor 3, Harjutus 4 - Namespaces and Labels

---

## 🎓 7. Mida Sa Õppisid?

### Põhilised Kontseptsioonid

✅ **Container Orchestration:**
- Docker Compose limitations (single-host, no auto-scaling, no self-healing)
- Kubernetes capabilities (multi-node, auto-scaling, rolling updates, load balancing)
- Orchestration use cases (when Kubernetes is needed)

✅ **Kubernetes Architecture:**
- Control Plane components (API Server, Scheduler, Controller Manager, etcd)
- Worker Node components (kubelet, kube-proxy, container runtime)
- Separation of concerns (brain vs muscle)

✅ **K3s vs Vanilla Kubernetes:**
- Resource requirements (512MB vs 2GB)
- Setup complexity (1 command vs hours)
- Trade-offs (lightweight vs full-featured)

✅ **kubectl and Configuration:**
- Declarative vs imperative (YAML vs commands)
- Kubeconfig structure (clusters, users, contexts)
- kubectl as API client

✅ **Core Objects:**
- Pod (smallest unit, ephemeral, shared network/storage)
- ReplicaSet (desired replicas, reconciliation loop)
- Deployment (rolling updates, rollback)
- Service (stable endpoint, load balancing, types: ClusterIP, NodePort, LoadBalancer)

✅ **Organization:**
- Namespaces (logical partitioning, multi-tenancy)
- Labels and Selectors (resource grouping, filtering)

---

## 🚀 8. Järgmised Sammud

**Peatükk 10: Kubernetes Advanced Concepts** ☸️

Järgmine evolutsioon Kubernetes'es:

- ConfigMaps and Secrets (configuration management)
- PersistentVolumes and PersistentVolumeClaims (stateful applications)
- StatefulSets (databases in Kubernetes)
- Ingress (HTTP routing)
- HorizontalPodAutoscaler (auto-scaling)
- Resource requests and limits (resource management)

**Peatükk 11: CI/CD with Kubernetes** 🚀

Automation ja deployment pipeline:

- GitOps (ArgoCD, Flux)
- Helm (Kubernetes package manager)
- Rolling updates ja canary deployments
- GitHub Actions → Kubernetes integration

📖 **Praktika:** Labor 3 pakub hands-on harjutusi K3s installimiseks, kubectl kasutamiseks, ning Pods, Deployments, Services deploy'miseks.

---

## ✅ Kontrolli Ennast

Enne järgmisele peatükile liikumist, veendu et:

- [ ] Mõistad, miks Kubernetes on vajalik (Docker Compose limitations)
- [ ] Oskad selgitada Kubernetes arhitektuuri (Control Plane vs Worker Nodes)
- [ ] Mõistad K3s eeliseid VPS deployment'ideks
- [ ] Oskad selgitada kubectl rolli (API client, declarative config)
- [ ] Mõistad Pod, ReplicaSet, Deployment, Service rolli
- [ ] Oskad selgitada Namespaces ja Labels kasutust
- [ ] Mõistad self-healing ja auto-scaling concepts

**Kui kõik on ✅, oled valmis Peatükiks 10!** 🚀

---

**Peatükk 9 lõpp**
**Järgmine:** Peatükk 10 - Kubernetes Advanced Concepts
