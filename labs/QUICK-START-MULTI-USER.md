# 🚀 Quick Start - Multi-User Setup

5-minutine juhend mitme kasutaja jaoks.

---

## 👤 Iga Kasutaja Teeb (Esimene Kord)

### Docker Labs (Lab 1-2)

```bash
# 1. Logi sisse oma kasutajaga
ssh yourname@93.127.213.242

# 2. Navigate to labs
cd /path/to/labs  # Küsi adminilt õige path

# 3. Setup environment
source multi-user-setup.sh

# 4. Reload shell
source ~/.bashrc

# ✅ VALMIS! Nüüd saad alustada Lab 1 või Lab 2
```

### Kubernetes Labs (Lab 3-10)

```bash
# 1. Logi sisse oma kasutajaga
ssh yourname@93.127.213.242

# 2. Navigate to labs
cd /path/to/labs

# 3. Create your Kubernetes cluster
bash k8s-multi-user-setup.sh create

# Oota ~2 minutit...

# 4. Reload shell
source ~/.bashrc

# 5. Verify
k get nodes

# ✅ VALMIS! Nüüd saad alustada Lab 3-10
```

---

## 💻 Igapäevane Kasutamine

### Docker (Lab 1-2)

```bash
# Navigate to lab
cd labs/01-docker-lab  # või 02-docker-compose-lab

# Start
dc-up

# Check
dc-ps

# Access
curl http://localhost:${BACKEND_PORT}/health
# Check port: cat ~/.env-lab

# Stop
dc-down
```

### Kubernetes (Lab 3-10)

```bash
# Navigate to lab
cd labs/03-kubernetes-basics-lab  # või 04, 05, ..., 10

# Check cluster
k get nodes

# Deploy
k apply -f pod.yaml

# Check
k get pods

# Logs
k logs my-pod

# Cleanup namespace
k delete namespace janek-test
```

---

## 🧹 Cleanup (Labi Lõpus)

### Docker

```bash
# Stop current lab
dc-down

# Remove all your containers/volumes/networks
d-cleanup
```

### Kubernetes

```bash
# Option 1: Delete specific namespace
k delete namespace ${LAB_USER}-production

# Option 2: Full cluster reset
bash labs/k8s-multi-user-setup.sh delete
bash labs/k8s-multi-user-setup.sh create
```

---

## ❓ Kui Midagi Ei Tööta

### Docker

```bash
# Check your config
cat ~/.env-lab

# Re-run setup
source multi-user-setup.sh

# Cleanup and restart
d-cleanup
dc-up
```

### Kubernetes

```bash
# Check cluster
bash labs/k8s-multi-user-setup.sh status

# Recreate cluster
bash labs/k8s-multi-user-setup.sh delete
bash labs/k8s-multi-user-setup.sh create
```

### Port Conflicts

```bash
# Check what's using your port
sudo lsof -i :3001  # Replace with your port

# Check your assigned ports
cat ~/.env-lab
```

---

## 📋 Cheat Sheet

### Docker Aliases

```bash
dc-up          # Start services
dc-down        # Stop services
dc-logs        # View logs
dc-ps          # List containers
dc-restart     # Restart services

d-ps           # List YOUR containers only
d-cleanup      # Remove all YOUR resources
```

### Kubernetes Aliases

```bash
k              # kubectl (your cluster)
kgp            # Get pods
kgs            # Get services
kgn            # Get YOUR namespaces
kl pod-name    # Logs
kx pod-name    # Exec into pod
```

### Environment Variables

```bash
$USER_PREFIX      # Your username (janek)
$LAB_USER         # Your username (K8s)
$LAB_CLUSTER      # Your cluster name (janek-k8s-lab)
$LAB_NAMESPACE    # Your default namespace (janek-default)
$BACKEND_PORT     # Your backend port (3001)
$POSTGRES_PORT    # Your postgres port (5433)
$FRONTEND_PORT    # Your frontend port (8081)
```

---

## 🎯 Täielik Workflow Näide

### Docker Lab 1 (Single Container)

```bash
# 1. Setup (once)
source multi-user-setup.sh
source ~/.bashrc

# 2. Navigate
cd labs/01-docker-lab

# 3. Build
docker build -t ${USER_PREFIX}-backend ../apps/backend-nodejs

# 4. Run
docker run -d \
  --name ${USER_PREFIX}-backend \
  -p ${BACKEND_PORT}:3000 \
  ${USER_PREFIX}-backend

# 5. Test
curl http://localhost:${BACKEND_PORT}/health

# 6. Cleanup
docker stop ${USER_PREFIX}-backend
docker rm ${USER_PREFIX}-backend
```

### Kubernetes Lab 3 (Pod)

```bash
# 1. Setup cluster (once)
bash labs/k8s-multi-user-setup.sh create
source ~/.bashrc

# 2. Navigate
cd labs/03-kubernetes-basics-lab

# 3. Create namespace
k create namespace ${LAB_USER}-test

# 4. Deploy
k apply -f exercises/pod.yaml -n ${LAB_USER}-test

# 5. Check
k get pods -n ${LAB_USER}-test

# 6. Cleanup
k delete namespace ${LAB_USER}-test
```

---

## 🆘 Abi Vajalik?

1. **Loe täielikku juhendit:** `cat labs/MULTI-USER-GUIDE.md`
2. **Kontrolli süsteemi staatust:**
   - Docker: `docker ps`
   - Kubernetes: `bash labs/k8s-multi-user-setup.sh status`
3. **Küsi adminilt abi** kui probleem püsib

---

**Happy Learning! 🎓**
