# 👥 Multi-User Lab Guide

**Eesmärk:** Lubada mitmel kasutajal samaaegselt samas VPS'is laboreid sooritada ilma konfliktideta.

---

## 📋 Sisukord

1. [Probleemid ja Lahendused](#probleemid-ja-lahendused)
2. [Docker Labs (Lab 1-2)](#docker-labs-lab-1-2)
3. [Kubernetes Labs (Lab 3-10)](#kubernetes-labs-lab-3-10)
4. [Kasutajate Haldamine](#kasutajate-haldamine)
5. [Troubleshooting](#troubleshooting)
6. [Best Practices](#best-practices)

---

## ⚠️ Probleemid ja Lahendused

### Probleemid (Ilma Isolatsioonita)

| Probleem | Näide | Tagajärg |
|----------|-------|----------|
| **Port conflicts** | `docker run -p 3000:3000` | ❌ Port 3000 already in use |
| **Container name conflicts** | `docker run --name postgres` | ❌ Container name already exists |
| **Network conflicts** | `docker network create app-network` | ❌ Network already exists |
| **Volume conflicts** | `docker volume create postgres-data` | ❌ Volume already exists |
| **K8s namespace conflicts** | `kubectl create namespace production` | ❌ Namespace already exists |
| **PVC conflicts** | `kubectl apply -f pvc.yaml` | ❌ PVC already exists |

### Lahendused

| Lab | Lahendus | Isolatsioon |
|-----|----------|-------------|
| **Lab 1-2** (Docker) | User-specific prefixes + Compose project names | Partial (same Docker daemon) |
| **Lab 3-10** (Kubernetes) | Kind cluster per kasutaja | Full (separate K8s clusters) |

---

## 🐳 Docker Labs (Lab 1-2)

### Setup (Ühekordne)

Iga kasutaja käivitab oma keskkonna setup'i:

```bash
# 1. Navigate to labs directory
cd /path/to/labs

# 2. Run multi-user setup
source ./multi-user-setup.sh

# Output:
# === Multi-User Lab Setup ===
# 👤 Current user: janek (UID: 1001)
# 📊 Port offset: 1
# ✅ User-Specific Configuration:
#    PREFIX:        janek
#    PostgreSQL:    localhost:5433
#    Backend API:   localhost:3001
#    Frontend:      localhost:8081
# ✅ Created: /home/janek/.env-lab
# ✅ Created: /home/janek/.lab-aliases.sh
# ✅ Added aliases to .bashrc

# 3. Reload shell
source ~/.bashrc
```

### Kasutamine

#### Docker Compose (Soovitatav)

```bash
# Navigate to lab
cd labs/01-docker-lab  # või 02-docker-compose-lab

# Start services (automaatselt user-specific)
dc-up

# Check status
dc-ps

# View logs
dc-logs backend

# Stop services
dc-down
```

**Mis toimub taustal:**
```bash
# dc-up = docker compose -p janek --env-file ~/.env-lab up -d
# Loob:
#   - janek-backend-1      (port 3001)
#   - janek-postgres-1     (port 5433)
#   - janek-frontend-1     (port 8081)
#   - janek_default        (network)
#   - janek_postgres-data  (volume)
```

#### Manual Docker Commands

```bash
# Container name with prefix
docker run --name ${USER_PREFIX}-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p ${POSTGRES_PORT}:5432 \
  postgres:16

# Check your containers only
d-ps

# Logs
d-logs backend  # = docker logs janek-backend

# Cleanup all your containers
d-cleanup
```

### User-Specific Ports

Iga kasutaja saab automaatselt unikaalsed pordid:

| Kasutaja | UID | Offset | PostgreSQL | Backend | Frontend |
|----------|-----|--------|------------|---------|----------|
| janek | 1001 | 1 | 5433 | 3001 | 8081 |
| maria | 1002 | 2 | 5434 | 3002 | 8082 |
| kalle | 1003 | 3 | 5435 | 3003 | 8083 |

**Formula:** `PORT = BASE_PORT + (USER_ID % 1000)`

---

## ☸️ Kubernetes Labs (Lab 3-10)

### Setup (Ühekordne)

Iga kasutaja loob oma Kind cluster'i:

```bash
# 1. Create user-specific Kind cluster
bash labs/k8s-multi-user-setup.sh create

# Output:
# ╔════════════════════════════════════════════════════════════╗
# ║  Kubernetes Multi-User Lab Setup                          ║
# ╚════════════════════════════════════════════════════════════╝
#
# Checking prerequisites...
# ✅ Docker installed
# ✅ Kind installed (v0.20.0)
# ✅ kubectl installed
#
# Creating Kind cluster: janek-k8s-lab
# Configuration:
#    Cluster name:    janek-k8s-lab
#    API server port: 6444
#    HTTP port:       30081
#    HTTPS port:      30444
#
# Creating cluster "janek-k8s-lab" ...
# ✅ Cluster created successfully!
#
# === Cluster Information ===
# Cluster:
# Kubernetes control plane is running at https://127.0.0.1:6444
#
# Nodes:
# NAME                          STATUS   ROLES           AGE   VERSION
# janek-k8s-lab-control-plane   Ready    control-plane   30s   v1.27.3
# janek-k8s-lab-worker          Ready    <none>          20s   v1.27.3

# 2. Reload shell
source ~/.bashrc

# 3. Verify
k get nodes
```

### Kasutamine

```bash
# Navigate to any Kubernetes lab
cd labs/03-kubernetes-basics-lab  # või 04, 05, ..., 10

# All kubectl commands automatically use YOUR cluster
kubectl get nodes
# = kubectl --context kind-janek-k8s-lab get nodes

# Using alias (shorter)
k get nodes

# Create namespace (user-specific)
k create namespace ${LAB_USER}-production
# Creates: janek-production

# Deploy application
k apply -f deployment.yaml

# Check pods
kgp  # = kubectl get pods

# Logs
kl my-pod-name

# Exec into pod
kx my-pod-name -- sh
```

### Cluster Management

```bash
# Check cluster status
bash labs/k8s-multi-user-setup.sh status

# Delete cluster (cleanup)
bash labs/k8s-multi-user-setup.sh delete
```

### User-Specific Resources

Iga kasutaja cluster'is:

| Resource | Janek | Maria | Kalle |
|----------|-------|-------|-------|
| Cluster name | janek-k8s-lab | maria-k8s-lab | kalle-k8s-lab |
| API server | :6444 | :6445 | :6446 |
| Default namespace | janek-default | maria-default | kalle-default |
| NodePort HTTP | :30081 | :30082 | :30083 |
| NodePort HTTPS | :30444 | :30445 | :30446 |

**Täielik isolatsioon** - iga kasutaja Kubernetes on täiesti eraldatud!

---

## 👤 Kasutajate Haldamine

### Uue Kasutaja Lisamine (Admin)

```bash
# 1. Create system user
sudo useradd -m -s /bin/bash newuser
sudo passwd newuser

# 2. Add to docker group
sudo usermod -aG docker newuser

# 3. Copy lab files (optional - või kasuta shared location)
sudo cp -r /home/shared/labs /home/newuser/
sudo chown -R newuser:newuser /home/newuser/labs

# 4. User logs in and runs setup
su - newuser
cd labs
source ./multi-user-setup.sh  # Docker labs
bash ./k8s-multi-user-setup.sh create  # K8s labs
```

### Kasutaja Eemaldamine (Admin)

```bash
# 1. Login as user and cleanup
su - olduser

# Cleanup Docker resources
docker stop $(docker ps -q --filter "name=$(whoami)-")
docker rm $(docker ps -aq --filter "name=$(whoami)-")
docker volume prune -f
docker network prune -f

# Cleanup K8s cluster
bash labs/k8s-multi-user-setup.sh delete

# Logout
exit

# 2. As admin, remove user
sudo userdel -r olduser
```

---

## 🔧 Troubleshooting

### Docker Labs

#### Probleem: "Port already in use"

```bash
# Check your ports
cat ~/.env-lab

# Check what's using the port
sudo lsof -i :3001

# If it's your old container, cleanup
dc-down
d-cleanup
```

#### Probleem: "Container name already exists"

```bash
# List your containers
d-ps

# Remove specific container
docker rm -f ${USER_PREFIX}-backend

# Or remove all your containers
d-rm-all
```

#### Probleem: "No such file or directory: .env-lab"

```bash
# Re-run setup
source ./multi-user-setup.sh
```

### Kubernetes Labs

#### Probleem: "Cluster does not exist"

```bash
# Check status
bash labs/k8s-multi-user-setup.sh status

# Recreate
bash labs/k8s-multi-user-setup.sh create
```

#### Probleem: "connection refused" (API server)

```bash
# Check if Docker container is running
docker ps | grep ${LAB_USER}-k8s-lab

# Restart cluster
bash labs/k8s-multi-user-setup.sh delete
bash labs/k8s-multi-user-setup.sh create
```

#### Probleem: "context not found"

```bash
# List contexts
kubectl config get-contexts

# Set correct context
kubectl config use-context kind-${LAB_USER}-k8s-lab

# Or use alias
k get nodes  # Always uses correct context
```

---

## ✅ Best Practices

### 1. Kasuta Aliaseid

**Docker:**
```bash
dc-up      # Instead of: docker compose -p $(whoami) --env-file ~/.env-lab up -d
dc-down    # Instead of: docker compose -p $(whoami) --env-file ~/.env-lab down
d-ps       # Instead of: docker ps --filter "name=$(whoami)-"
```

**Kubernetes:**
```bash
k get pods     # Instead of: kubectl --context kind-janek-k8s-lab get pods
kgp            # Even shorter
kl pod-name    # Instead of: kubectl logs pod-name --context ...
```

### 2. Namespacing Convention

Kasuta alati kasutajanime prefiksit:

```bash
# ❌ BAD (conflicts võimalikud)
kubectl create namespace production

# ✅ GOOD (user-specific)
kubectl create namespace ${LAB_USER}-production
# või
kubectl create namespace janek-production
```

### 3. Cleanup Regulaarselt

**Docker (iga päev või labi lõpus):**
```bash
dc-down        # Stop current lab
d-cleanup      # Remove all your containers/networks/volumes
```

**Kubernetes (labi lõpus):**
```bash
# Delete specific namespace
k delete namespace janek-production

# Or full cluster reset
bash labs/k8s-multi-user-setup.sh delete
bash labs/k8s-multi-user-setup.sh create
```

### 4. Kontrolli Ressursse

**Docker:**
```bash
# Your containers
d-ps

# Your volumes
docker volume ls --filter "name=$(whoami)"

# Your networks
docker network ls --filter "name=$(whoami)"
```

**Kubernetes:**
```bash
# Your namespaces
kgn  # = kubectl get namespaces -l user=${LAB_USER}

# Your pods across all namespaces
k get pods -A -l user=${LAB_USER}
```

### 5. Port'ide Dokumenteerimine

Hoia meeles oma port'e:

```bash
# Check your ports
cat ~/.env-lab

# Example output:
# POSTGRES_PORT=5433
# BACKEND_PORT=3001
# FRONTEND_PORT=8081
```

Testi curl'iga:
```bash
curl http://localhost:${BACKEND_PORT}/health
curl http://localhost:${FRONTEND_PORT}
```

---

## 📊 Ressursside Kasutus

### VPS Piirangud (kirjakast)

- **RAM:** 7.8 GB
- **CPU:** 2 cores
- **Disk:** 96 GB

### Hinnanguline Kasutus Per Kasutaja

| Lab Type | RAM | Disk | Notes |
|----------|-----|------|-------|
| Docker (Lab 1-2) | ~500MB | ~2GB | PostgreSQL + 2 containers |
| Kubernetes (Lab 3-10) | ~1.5GB | ~5GB | Kind cluster (2 nodes) |

**Max concurrent users (estimate):**
- **Docker only:** 10-12 users
- **Kubernetes:** 4-5 users
- **Mixed:** 6-8 users

### Monitoring

```bash
# Check system resources
free -h           # RAM
df -h             # Disk
docker stats      # Container resources
```

---

## 🎯 Quick Reference

### Setup Commands

```bash
# Docker labs setup (once)
source labs/multi-user-setup.sh

# K8s labs setup (once)
bash labs/k8s-multi-user-setup.sh create
```

### Daily Usage

```bash
# Docker
cd labs/01-docker-lab
dc-up              # Start
dc-logs -f         # Watch logs
dc-down            # Stop

# Kubernetes
cd labs/03-kubernetes-basics-lab
k get nodes        # Verify cluster
k apply -f pod.yaml
k get pods
```

### Cleanup

```bash
# Docker
d-cleanup

# Kubernetes
bash labs/k8s-multi-user-setup.sh delete
```

---

## 📚 Täiendavad Ressursid

- **Kind documentation:** https://kind.sigs.k8s.io/
- **Docker Compose documentation:** https://docs.docker.com/compose/
- **kubectl cheat sheet:** https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

**Küsimused või probleemid?** Küsi administraatorilt abi!
