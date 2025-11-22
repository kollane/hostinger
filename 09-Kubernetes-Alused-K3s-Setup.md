# Peatükk 9: Kubernetes Alused ja K3s Setup

**Kestus:** 4 tundi
**Tase:** Keskmine
**Eeldused:** Docker põhitõed selged (Peatükk 4-6)

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist oskad:

1. ✅ Selgitada Kubernetes arhitektuuri
2. ✅ Mõista Pods, Deployments, Services kontseptsioone
3. ✅ Installeerida K3s (lightweight Kubernetes)
4. ✅ Kasutada kubectl CLI-d
5. ✅ Deploy'da esimest Pod'i
6. ✅ Luua ja hallata Namespaces
7. ✅ Kasutada Labels ja Selectors
8. ✅ Eristada K3s vs vanilla Kubernetes

---

## 🎯 1. Mis On Kubernetes ja Miks Me Seda Vajame?

### 1.1 Docker Compose vs Kubernetes

**Docker Compose (Peatükk 7):**
```yaml
# docker-compose.yml - Üks server
services:
  frontend:
    image: frontend:1.0
  backend:
    image: backend:1.0
  postgres:
    image: postgres:16-alpine
```

**Probleem suuremates süsteemides:**
- ❌ Ainult ÜKSÜHEVPS'is
- ❌ Ei skaleer automaatselt
- ❌ Ei paranda ennast (self-healing)
- ❌ Ei toeta multi-node cluster'eid
- ❌ Pole built-in load balancing
- ❌ Pole rolling updates

**Lahendus: Kubernetes (orkestratsioon):**
```
Kubernetes = "Container Orchestrator"
```

---

### 1.2 Kubernetes Võimekused

**Mida Kubernetes teeb:**
```bash
✅ Self-healing: Pod crashib → restart automaatselt
✅ Auto-scaling: Load suureneb → deploy rohkem Pod'e
✅ Load balancing: Jagab traffic'u Pod'ide vahel
✅ Rolling updates: Deploy uus versioon ilma downtime'ita
✅ Rollback: Uus versioon buggy → tagasi vanal verzionele
✅ Secret management: Salasta andmebaasi paroolid
✅ Storage orchestration: Halda persistent volumes
✅ Multi-node: Töötab mitme serveri cluster'is
```

**Analoogia:**
```
Docker Compose = Üks auto (lihtne, kiire)
Kubernetes = Logistikaettevõte (keeruline, aga võimas)

Docker Compose:
- Hea 5-10 konteinerile
- Üks server
- Lihtne config

Kubernetes:
- Hea 100-10000 konteinerile
- Multi-node cluster
- Kompleksne config
```

---

### 1.3 Millal Kasutada Kubernetes'e?

**✅ Kasuta Kubernetes'e kui:**
- Rohkem kui 10-20 konteinerit
- Vajad auto-scaling'ut
- Vajad high availability (99.9% uptime)
- Vajad rolling updates
- Multi-node cluster
- Production environment

**❌ ÄRA kasuta Kubernetes'e kui:**
- Väike projekt (5 konteinerit)
- Üks VPS piisab
- Docker Compose töötab hästi
- Ei vaja orkestreerimist

**Meie koolituskavas:**
Õpime Kubernetes'e, sest see on **industry standard** DevOps'is! 🚀

---

## 🏗️ 2. Kubernetes Arhitektuur

### 2.1 Kubernetes Cluster Komponendid

```
+-----------------------------------+
|       KUBERNETES CLUSTER          |
+-----------------------------------+
|                                   |
|  +-----------------------------+  |
|  |     CONTROL PLANE (Master) |  |
|  +-----------------------------+  |
|  | - API Server                |  | ← kubectl ühendub siia
|  | - Scheduler                 |  | ← Otsustab, millisesse Node'i Pod panna
|  | - Controller Manager        |  | ← Jälgib Pod'ide seisundit
|  | - etcd (database)           |  | ← Hoiab cluster state'i
|  +-----------------------------+  |
|                                   |
|  +-----------------------------+  |
|  |      WORKER NODES (3x)      |  |
|  +-----------------------------+  |
|  | Node 1:                     |  |
|  |  - kubelet                  |  | ← Haldab Pod'e Node'is
|  |  - kube-proxy               |  | ← Network routing
|  |  - Container Runtime (Docker)|  |
|  |  - Pods (running apps)      |  |
|  +-----------------------------+  |
|  | Node 2: ...                 |  |
|  | Node 3: ...                 |  |
|  +-----------------------------+  |
+-----------------------------------+
```

**Komponendid selgitatult:**

**Control Plane (Master):**
- **API Server:** REST API, kubectl ühendub siia
- **Scheduler:** Otsustab, millisesse Node'i uus Pod paigutada
- **Controller Manager:** Jälgib ja haldab Deployments, ReplicaSets, etc.
- **etcd:** Distributed key-value store (cluster state database)

**Worker Nodes:**
- **kubelet:** Agent, mis käivitab ja haldab Pod'e
- **kube-proxy:** Network proxy, load balancing
- **Container Runtime:** Docker, containerd, CRI-O

---

### 2.2 Kubernetes Objektid (Resources)

**Põhilised objektid:**

```
Pod                 Smallest deployable unit (1 or more containers)
  ↓
ReplicaSet          Ensures N replicas of Pods are running
  ↓
Deployment          Manages ReplicaSets, rolling updates
  ↓
Service             Load balancer for Pods, stable endpoint
  ↓
Ingress             HTTP(S) routing from outside
```

**Veel objekte:**
- **ConfigMap:** Configuration data
- **Secret:** Sensitive data (passwords, tokens)
- **PersistentVolume (PV):** Storage
- **PersistentVolumeClaim (PVC):** Storage request
- **StatefulSet:** Stateful apps (databases)
- **Namespace:** Logical cluster partitioning

---

## 🐧 3. K3s - Lightweight Kubernetes

### 3.1 Vanilla Kubernetes vs K3s

**Vanilla Kubernetes:**
```bash
# Installeerimine: KEERULINE!
- kubeadm init
- CNI plugin (Calico, Flannel)
- Control plane setup
- Worker node join
- Certificate management
# Minimum 2GB RAM per node

⏱️ Setup aeg: 1-2 tundi
```

**K3s:**
```bash
# Installeerimine: LIHTNE!
curl -sfL https://get.k3s.io | sh -

# Done! Kubernetes on valmis! ✅
⏱️ Setup aeg: 2 minutit
```

**Võrdlus:**

| Aspekt | Vanilla Kubernetes | K3s |
|--------|-------------------|-----|
| **Memory** | 2-4 GB | 512 MB ✅ |
| **Binary size** | 100-200 MB | 50 MB ✅ |
| **Setup** | kubeadm, complicated | 1 command ✅ |
| **Components** | Kõik eraldi | Kõik ühes binary's ✅ |
| **Storage** | Ei kaasa | Built-in (local-path) ✅ |
| **Load Balancer** | Cloud provider | Traefik (built-in) ✅ |
| **Use case** | Production (large) | VPS, Edge, IoT, dev ✅ |

**Miks K3s meie koolituskavas?**
- ✅ Lightweight (512MB RAM vs 2GB)
- ✅ Lihtne install (1 käsk)
- ✅ CNCF certified (100% K8s compatible!)
- ✅ Production-ready (Rancher Labs)
- ✅ Töötab VPS'is suurepäraselt!

📖 **Lisalugemine:** `LISA-PEATUKK-Kubernetes-Distributions.md` (K3s, K0s, MicroK8s, EKS, AKS, GKE)

---

### 3.2 K3s Installeerimine VPS'is

**1. Eeldused:**
```bash
# VPS:
- Ubuntu 24.04 LTS
- 2GB RAM (min 512MB)
- Sudo access
- UFW firewall lubatud portid
```

**2. UFW reeglid:**
```bash
# K3s ports
sudo ufw allow 6443/tcp comment 'K3s API Server'
sudo ufw allow 10250/tcp comment 'K3s kubelet'

# Kui kasutad Traefik Ingress:
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
```

**3. Install K3s:**
```bash
# Vanilla install (default)
curl -sfL https://get.k3s.io | sh -

# VÕI custom install:
curl -sfL https://get.k3s.io | sh -s - \
  --write-kubeconfig-mode 644 \
  --disable traefik  # Disable Traefik (optional)

# Wait for installation...
# [INFO]  systemd: Starting k3s
# [INFO]  systemd: Starting k3s-agent
```

**4. Verify install:**
```bash
# Check K3s service
sudo systemctl status k3s

# Check nodes
sudo k3s kubectl get nodes

# Output:
# NAME          STATUS   ROLES                  AGE   VERSION
# your-vps      Ready    control-plane,master   1m    v1.28.5+k3s1
```

**5. Setup kubectl alias:**
```bash
# Lisa ~/.bashrc faili:
echo 'alias kubectl="sudo k3s kubectl"' >> ~/.bashrc
source ~/.bashrc

# Test:
kubectl get nodes
# Töötab! ✅
```

---

### 3.3 kubeconfig Setup (Non-Root Access)

**Probleem:** K3s vajab sudo't

**Lahendus - Kopeeri kubeconfig:**
```bash
# 1. Loo ~/.kube directory
mkdir -p ~/.kube

# 2. Kopeeri K3s kubeconfig
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

# 3. Muuda ownership
sudo chown $USER:$USER ~/.kube/config

# 4. Test kubectl (ILMA sudo'ta)
kubectl get nodes
# Töötab! ✅
```

---

## 🛠️ 4. kubectl - Kubernetes CLI

### 4.1 kubectl Põhikäsud

**Get resources:**
```bash
# List pods
kubectl get pods

# List pods (all namespaces)
kubectl get pods -A

# List nodes
kubectl get nodes

# List deployments
kubectl get deployments

# List services
kubectl get services

# List KÕIK resources
kubectl get all
```

**Describe (detailed info):**
```bash
# Describe pod
kubectl describe pod <pod-name>

# Describe node
kubectl describe node <node-name>

# Describe service
kubectl describe service <service-name>
```

**Create/Delete:**
```bash
# Apply YAML file
kubectl apply -f deployment.yaml

# Delete resource
kubectl delete pod <pod-name>
kubectl delete -f deployment.yaml

# Delete by type and name
kubectl delete deployment nginx
```

**Logs:**
```bash
# View pod logs
kubectl logs <pod-name>

# Follow logs (tail -f)
kubectl logs -f <pod-name>

# Logs from specific container (multi-container pod)
kubectl logs <pod-name> -c <container-name>

# Previous container logs (kui pod restartis)
kubectl logs <pod-name> --previous
```

**Exec (sisene Pod'i):**
```bash
# Bash shell
kubectl exec -it <pod-name> -- bash

# VÕI sh (Alpine images)
kubectl exec -it <pod-name> -- sh

# Üks käsk
kubectl exec <pod-name> -- ls -la /app
```

---

### 4.2 kubectl Context ja Config

```bash
# View current context
kubectl config current-context

# View kubeconfig
kubectl config view

# Switch context (multi-cluster)
kubectl config use-context production
```

---

## 🎯 5. Esimene Pod - Hello Kubernetes!

### 5.1 Imperative Way (CLI)

```bash
# Run Nginx pod
kubectl run nginx --image=nginx:1.25-alpine

# Verify
kubectl get pods

# Output:
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          10s

# Describe pod
kubectl describe pod nginx

# View logs
kubectl logs nginx

# Delete pod
kubectl delete pod nginx
```

---

### 5.2 Declarative Way (YAML) - SOOVITATUD!

**Loo Pod YAML:**
```bash
cat > nginx-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
EOF
```

**Apply:**
```bash
# Create pod
kubectl apply -f nginx-pod.yaml

# Verify
kubectl get pods

# Port-forward (local access)
kubectl port-forward nginx-pod 8080:80

# Test (another terminal)
curl http://localhost:8080
# Welcome to nginx!

# Delete
kubectl delete -f nginx-pod.yaml
```

---

## 📦 6. Deployment - Production Way

### 6.1 Miks Deployment, Mitte Pod?

**Pod probleem:**
```bash
# 1. Loo pod
kubectl run nginx --image=nginx:1.25-alpine

# 2. Pod crashib
kubectl delete pod nginx --force

# 3. Pod on KADUNUD! ❌
kubectl get pods
# No resources found.
```

**Deployment lahendus (Self-Healing):**
```bash
# 1. Loo Deployment (3 replicas)
kubectl create deployment nginx --image=nginx:1.25-alpine --replicas=3

# 2. Pod crashib
kubectl delete pod nginx-xxx-yyy --force

# 3. Kubernetes LOOB AUTOMAATSELT uue Pod'i! ✅
kubectl get pods
# nginx-xxx-aaa  1/1  Running
# nginx-xxx-bbb  1/1  Running
# nginx-xxx-ccc  1/1  Running  ← UUS!
```

---

### 6.2 Deployment YAML

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3                    # 3 Pods
  selector:
    matchLabels:
      app: nginx
  template:                      # Pod template
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
```

**Apply:**
```bash
# Deploy
kubectl apply -f nginx-deployment.yaml

# Verify
kubectl get deployments
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   3/3     3            3           30s

kubectl get pods
# nginx-deployment-abc123-xxx  1/1  Running
# nginx-deployment-abc123-yyy  1/1  Running
# nginx-deployment-abc123-zzz  1/1  Running

# Scale up
kubectl scale deployment nginx-deployment --replicas=5

# Scale down
kubectl scale deployment nginx-deployment --replicas=2
```

---

## 🌐 7. Service - Load Balancing

### 7.1 Miks Service?

**Probleem:**
```bash
# Pods on ephemeral - IP addresses muutuvad!
kubectl get pods -o wide
# NAME           IP           NODE
# nginx-abc123   10.42.0.5    node1  ← IP võib muutuda pärast restart'i!
# nginx-def456   10.42.0.6    node1
```

**Service lahendus - Stable endpoint:**
```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx              # Match Pods with label app=nginx
  ports:
  - port: 80                # Service port
    targetPort: 80          # Container port
  type: ClusterIP           # Internal access only
```

**Apply:**
```bash
kubectl apply -f nginx-service.yaml

# Verify
kubectl get services
# NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
# nginx-service   ClusterIP   10.43.100.50    <none>        80/TCP

# Service DNS name (internal):
# nginx-service.default.svc.cluster.local
```

---

### 7.2 Service Types

| Type | Description | Use Case |
|------|-------------|----------|
| **ClusterIP** | Internal access only (default) | Backend services |
| **NodePort** | External access via Node IP:Port | Testing, simple deployments |
| **LoadBalancer** | Cloud load balancer | Production (cloud providers) |
| **ExternalName** | DNS CNAME redirect | External databases |

**NodePort example:**
```yaml
type: NodePort
ports:
- port: 80
  targetPort: 80
  nodePort: 30080   # Access: http://NODE_IP:30080
```

---

## 🏷️ 8. Labels ja Selectors

### 8.1 Labels - Metadata

**Labels** = key-value pairs for organizing resources

```yaml
metadata:
  labels:
    app: nginx
    environment: production
    team: devops
    version: v1.0
```

**List by labels:**
```bash
# Filter by label
kubectl get pods -l app=nginx
kubectl get pods -l environment=production
kubectl get pods -l environment=production,team=devops

# Show labels
kubectl get pods --show-labels
```

---

### 8.2 Selectors - Matching

**Selector** = choose resources by labels

```yaml
# Deployment selector
selector:
  matchLabels:
    app: nginx

# Service selector
selector:
  app: nginx
```

---

## 🔖 9. Namespaces - Logical Isolation

### 9.1 Mis On Namespace?

**Namespace** = logical cluster inside a cluster

```bash
# Default namespaces
kubectl get namespaces

# Output:
# NAME              STATUS   AGE
# default           Active   1h   ← Default (sinu app'id siia)
# kube-system       Active   1h   ← K8s system components
# kube-public       Active   1h   ← Public (readable by all)
# kube-node-lease   Active   1h   ← Node heartbeats
```

---

### 9.2 Namespaces Kasutamine

**Loo namespace:**
```bash
# Imperative
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production

# Declarative
cat > namespace.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: dev
EOF

kubectl apply -f namespace.yaml
```

**Deploy namespace'i:**
```bash
# Deploy to specific namespace
kubectl apply -f nginx-deployment.yaml -n dev

# List pods in namespace
kubectl get pods -n dev

# List all pods (all namespaces)
kubectl get pods -A
```

**Set default namespace:**
```bash
# Set context namespace
kubectl config set-context --current --namespace=dev

# Verify
kubectl config view | grep namespace
```

---

## 📝 10. Praktilised Harjutused

### Harjutus 1: K3s Install ja Verify (30 min)

**Eesmärk:** Installi K3s VPS'is

**Sammud:**
```bash
# 1. Install K3s
curl -sfL https://get.k3s.io | sh -

# 2. Verify service
sudo systemctl status k3s

# 3. Setup kubectl alias
echo 'alias kubectl="sudo k3s kubectl"' >> ~/.bashrc
source ~/.bashrc

# 4. Check nodes
kubectl get nodes

# 5. Check pods (kube-system)
kubectl get pods -n kube-system

# 6. Check version
kubectl version
```

**Kontrolli:**
- [ ] K3s service on running
- [ ] Node on Ready
- [ ] kubectl töötab
- [ ] kube-system pods on Running

---

### Harjutus 2: Esimene Deployment (45 min)

**Eesmärk:** Deploy Nginx Deployment + Service

**Sammud:**
```bash
# 1. Loo Deployment
cat > nginx-deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
EOF

# 2. Apply
kubectl apply -f nginx-deployment.yaml

# 3. Verify
kubectl get deployments
kubectl get pods

# 4. Loo Service
cat > nginx-service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF

kubectl apply -f nginx-service.yaml

# 5. Test
curl http://localhost:30080
# Welcome to nginx!

# 6. Scale
kubectl scale deployment nginx --replicas=5
kubectl get pods

# 7. Cleanup
kubectl delete -f nginx-deployment.yaml
kubectl delete -f nginx-service.yaml
```

**Kontrolli:**
- [ ] 3 Pods käivituvad
- [ ] Service on loodud
- [ ] NodePort access töötab
- [ ] Scaling töötab

---

### Harjutus 3: Namespaces ja Labels (30 min)

**Eesmärk:** Organiseer ressursse namespaces'iga

**Sammud:**
```bash
# 1. Loo namespaces
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace prod

# 2. Deploy dev environment
kubectl apply -f nginx-deployment.yaml -n dev
kubectl apply -f nginx-service.yaml -n dev

# 3. Deploy staging environment
kubectl apply -f nginx-deployment.yaml -n staging
kubectl apply -f nginx-service.yaml -n staging

# 4. List all pods
kubectl get pods -A | grep nginx

# 5. Set default namespace
kubectl config set-context --current --namespace=dev

# 6. Now kubectl uses 'dev' by default
kubectl get pods  # Shows dev pods

# 7. Filter by labels
kubectl get pods -l app=nginx

# 8. Cleanup
kubectl delete namespace dev
kubectl delete namespace staging
```

**Kontrolli:**
- [ ] 3 namespaces on loodud
- [ ] Pods on erinevates namespaces'ides
- [ ] Default namespace on seatud
- [ ] Label filtering töötab

---

## 🎓 11. Mida Sa Õppisid?

✅ **Kubernetes Kontseptsioonid:**
- Orkestreerimise vajadus
- Control Plane + Worker Nodes arhitektuur
- Pod → ReplicaSet → Deployment → Service hierarhia

✅ **K3s:**
- K3s vs vanilla Kubernetes eelised
- K3s installeerimine (1 käsk!)
- Lightweight (512MB vs 2GB)

✅ **kubectl:**
- get, describe, logs, exec käsud
- apply, delete YAML failide jaoks
- Imperative vs Declarative approach

✅ **Kubernetes Objektid:**
- Pod (smallest unit)
- Deployment (self-healing, scaling)
- Service (load balancing, stable endpoint)
- Namespace (logical isolation)
- Labels ja Selectors

✅ **Praktilised Oskused:**
- K3s VPS'is
- YAML manifest'ide kirjutamine
- Deployments ja Services loomine
- Namespaces haldamine

---

## 🚀 12. Järgmised Sammud

**Peatükk 10: Pods ja Deployments** 🎯
- Pod lifecycle
- Liveness ja Readiness probes
- Resource requests ja limits
- Rolling updates ja Rollback
- **SÜGAV SUKELDUMISES DEPLOYMENTS'ESSE!**

**Peatükk 11: Services ja Networking** 🌐
- Service discovery (DNS)
- Load balancing
- Endpoints
- Network Policies

**Labid:**
- **Lab 3:** Kubernetes Basics - Hands-on K8s deployment

---

## ✅ Kontrolli Ennast

- [ ] Mõistad Kubernetes arhitektuuri
- [ ] Oskad selgitada Pod, Deployment, Service
- [ ] Oled installinud K3s VPS'is
- [ ] Oskad kasutada kubectl CLI-d
- [ ] Oskad deploy'da YAML manifest'e
- [ ] Mõistad Namespaces ja Labels
- [ ] Oled läbinud kõik 3 praktilist harjutust

**Kui kõik on ✅, oled valmis Peatükiks 10!** 🚀

---

**Peatükk 9 lõpp**
**Järgmine:** Peatükk 10 - Pods ja Deployments

**Õnnitleme!** Oled nüüd Kubernetes maailmas! ☸️🎉
