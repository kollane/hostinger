# Labor 3: Kubernetes Alused

**Kestus:** 5 tundi
**Eeldused:** Labor 1-2 läbitud, Peatükk 15-16 (Kubernetes alused)
**Eesmärk:** Deploy'da rakendused Kubernetes cluster'isse

---

## 📋 Ülevaade

Selles laboris deploy'ad Labor 1'st loodud Docker image'd Kubernetes cluster'isse. Õpid Kubernetes põhikontseptsioone: Pods, Deployments, Services, ConfigMaps, Secrets ja Persistent Volumes.

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

✅ Luua ja hallata Kubernetes Pods
✅ Deploy'da rakendusi Deployment'idega
✅ Seadistada Services (ClusterIP, NodePort, LoadBalancer)
✅ Kasutada ConfigMaps ja Secrets konfiguratsioonide jaoks
✅ Hallata Persistent Volumes andmete säilitamiseks
✅ Debuggida Kubernetes ressursse
✅ Kasutada kubectl põhikäske

---

## 🏗️ Arhitektuur

```
┌────────────────────────────────────────────────────┐
│         Kubernetes Cluster (Minikube/K3s)          │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │              Namespace: default              │ │
│  │                                              │ │
│  │  ┌─────────────┐  ┌─────────────┐          │ │
│  │  │   Service   │  │   Service   │          │ │
│  │  │ user-service│  │  frontend   │          │ │
│  │  │ ClusterIP   │  │  NodePort   │          │ │
│  │  └──────┬──────┘  └──────┬──────┘          │ │
│  │         │                │                  │ │
│  │         ▼                ▼                  │ │
│  │  ┌─────────────┐  ┌─────────────┐          │ │
│  │  │ Deployment  │  │ Deployment  │          │ │
│  │  │ user-service│  │  frontend   │          │ │
│  │  │ replicas: 2 │  │ replicas: 1 │          │ │
│  │  └──────┬──────┘  └──────┬──────┘          │ │
│  │         │                │                  │ │
│  │    ┌────┴────┐           │                  │ │
│  │    ▼         ▼           ▼                  │ │
│  │  ┌────┐   ┌────┐      ┌────┐               │ │
│  │  │Pod │   │Pod │      │Pod │               │ │
│  │  │ 1  │   │ 2  │      │ 1  │               │ │
│  │  └────┘   └────┘      └────┘               │ │
│  │    │         │           │                  │ │
│  │    └────┬────┘           │                  │ │
│  │         │                │                  │ │
│  │         ▼                │                  │ │
│  │  ┌─────────────┐         │                  │ │
│  │  │   Service   │         │                  │ │
│  │  │  postgres   │         │                  │ │
│  │  │ ClusterIP   │         │                  │ │
│  │  └──────┬──────┘         │                  │ │
│  │         │                │                  │ │
│  │         ▼                │                  │ │
│  │  ┌─────────────┐         │                  │ │
│  │  │ StatefulSet │         │                  │ │
│  │  │  postgres   │         │                  │ │
│  │  └──────┬──────┘         │                  │ │
│  │         │                │                  │ │
│  │         ▼                │                  │ │
│  │  ┌─────────────┐         │                  │ │
│  │  │     PVC     │         │                  │ │
│  │  │postgres-data│         │                  │ │
│  │  └──────┬──────┘         │                  │ │
│  │         │                │                  │ │
│  │         ▼                │                  │ │
│  │  ┌─────────────┐         │                  │ │
│  │  │     PV      │         │                  │ │
│  │  │  10Gi disk  │         │                  │ │
│  │  └─────────────┘         │                  │ │
│  │                                              │ │
│  │  ConfigMaps: db-config, app-config          │ │
│  │  Secrets: db-credentials, jwt-secret        │ │
│  │                                              │ │
│  └──────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────┘
```

---

## 📂 Labori Struktuur

```
03-kubernetes-basics-lab/
├── README.md              # See fail
├── exercises/             # Harjutused
│   ├── 01-pods.md
│   ├── 02-deployments.md
│   ├── 03-services.md
│   ├── 04-configmaps-secrets.md
│   └── 05-persistent-volumes.md
├── manifests/             # Näidis YAML failid
│   ├── 01-pods/
│   ├── 02-deployments/
│   ├── 03-services/
│   ├── 04-config/
│   └── 05-storage/
└── solutions/             # Täielikud lahendused
    └── README.md
```

---

## 🔧 Eeldused

### Eelnevad labid:
- [x] **Labor 1: Docker Põhitõed** - KOHUSTUSLIK
  - Vaja on Labor 1'st loodud Docker image'e:
    - `user-service:1.0` (Node.js backend)
    - `frontend:1.0`
  - Dockerfile'ide ja konteinerite mõistmine

- [ ] **Labor 2: Docker Compose** - SOOVITUSLIK
  - Multi-container rakenduste kogemus
  - Ei ole otseselt vajalik, kuid aitab mõista teenuste orkestreerimist

### Tööriistad:
- [x] kubectl paigaldatud (`kubectl version --client` - v1.28+)
- [x] Kubernetes cluster:
  - **Minikube** (soovitatud algajatele) VÕI
  - **K3s** (lightweight, VPS-is)
  - **Kind** (Kubernetes in Docker)
- [x] Docker töötab (Minikube jaoks)
- [x] Vähemalt 4GB vaba RAM (cluster + rakendused)
- [x] Internet ühendus (image'ite tõmbamiseks)

### Teadmised:
- [x] **Labor 1:** Docker põhitõed (images, containers, networks, volumes)
- [x] **Labor 2:** Docker Compose (soovituslik, multi-container kogemus)
- [x] **Peatükk 15:** Kubernetes arhitektuur ja komponendid
- [x] **Peatükk 16:** Kubernetes põhikontseptsioonid (Pods, Deployments, Services)
- [x] YAML süntaks

---

## 📚 Progressiivne Õppetee

```
Labor 1 (Docker)
  ↓ Docker image'd →
Labor 2 (Compose)
  ↓ Multi-container kogemus →
Labor 3 (K8s Basics) ← Oled siin
  ↓ K8s manifests + deployed apps →
Labor 4 (K8s Advanced)
  ↓ Ingress + Helm →
Labor 5 (CI/CD)
  ↓ Automated deployments →
Labor 6 (Monitoring)
```

---

## 📝 Harjutused

### Harjutus 1: Kubernetes Pods (60 min)
**Fail:** [exercises/01-pods.md](exercises/01-pods.md)

**Loo ja halda pod'e:**
- Käivita Minikube/K3s cluster
- Loo esimene Pod YAML'iga
- Deploy User Service Pod
- Testi Pod'i töötamist
- Debug Pod probleeme
- Kasuta kubectl põhikäske

**Õpid:**
- Pod'i kontseptsiooni ja elutsüklit
- YAML manifesti struktuuri
- kubectl create, get, describe, logs, exec
- Pod'i troubleshooting'u tehnikaid

---

### Harjutus 2: Deployments (60 min)
**Fail:** [exercises/02-deployments.md](exercises/02-deployments.md)

**Deploy rakendusi Deployment'idega:**
- Loo Deployment User Service jaoks
- Seadista replicas (mitu koopiat)
- Uuenda rakendust (rolling update)
- Scale'i deployment'i
- Rollback ebaõnnestunud update

**Õpid:**
- Deployment vs Pod erinevust
- ReplicaSet rolli
- Rolling update strateegiat
- Scaling põhimõtteid
- Deployment lifecycle haldust

---

### Harjutus 3: Services (60 min)
**Fail:** [exercises/03-services.md](exercises/03-services.md)

**Avalda rakendused Service'idega:**
- Loo ClusterIP Service (internal)
- Loo NodePort Service (external)
- Testi Service discovery
- Kasuta Labels ja Selectors
- Debuggi Service routing'u

**Õpid:**
- Service tüüpe (ClusterIP, NodePort, LoadBalancer)
- Service discovery Kubernetes'es
- Labels ja Selectors süsteemi
- Port forwarding kubectl'iga
- DNS pod'ide vahel

---

### Harjutus 4: ConfigMaps & Secrets (60 min)
**Fail:** [exercises/04-configmaps-secrets.md](exercises/04-configmaps-secrets.md)

**Halda konfiguratsioone turvaliselt:**
- Loo ConfigMap environment variables jaoks
- Loo Secret andmebaasi paroolide jaoks
- Mount ConfigMap failina
- Kasuta Secrets environment variables'ina
- Uuenda konfiguratsioone

**Õpid:**
- ConfigMap vs Secret erinevust
- Environment variables Pod'ides
- Volume mount'imist konfiguratsioonidele
- Base64 encoding'ut
- Turvaliste andmete haldust

---

### Harjutus 5: Persistent Volumes (60 min)
**Fail:** [exercises/05-persistent-volumes.md](exercises/05-persistent-volumes.md)

**Säilita andmeid Persistent Volumes'iga:**
- Loo PersistentVolume (PV)
- Loo PersistentVolumeClaim (PVC)
- Mount PVC PostgreSQL Pod'ile
- Testi andmete persistence
- Deploy StatefulSet PostgreSQL'ile

**Õpid:**
- PV vs PVC kontseptsiooni
- Storage Classes
- Volume mount'imist Pod'ides
- StatefulSet vs Deployment
- Andmete säilitamist pod restart'i järel

---

## ⚡ Kiirstart Setup

### Variant A: Automaatne Seadistus (Soovitatud)

Käivita setup script, mis seadistab Kubernetes cluster'i ja laeb image'd:

```bash
# Käivita setup script
chmod +x setup.sh
./setup.sh
```

**Script teeb:**
- ✅ Kontrollib kubectl paigaldust
- ✅ Käivitab Kubernetes cluster'i (Minikube või K3s)
- ✅ Kontrollib Lab 1 image'ite olemasolu
- ✅ Build'ib puuduvad image'd
- ✅ Laeb image'd Kubernetes cluster'isse
- ✅ Testib cluster'i töökorras olekut

---

### Variant B: Manuaalne Seadistus

#### 1. Paigalda kubectl (kui puudub)

```bash
# Ubuntu/Debian
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Kontrolli
kubectl version --client
```

#### 2. Vali ja Käivita Kubernetes Cluster

**Variant 2A: Minikube (Soovitatud Algajatele)**

```bash
# Paigalda Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Käivita cluster
minikube start --cpus=2 --memory=4096

# Kontrolli
kubectl cluster-info
kubectl get nodes
```

**Variant 2B: K3s (Lightweight, VPS-is)**

```bash
# Paigalda K3s
curl -sfL https://get.k3s.io | sh -

# Setup kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config

# Kontrolli
kubectl cluster-info
kubectl get nodes
```

#### 3. Lae Lab 1 Image'd Cluster'isse

**Kui kasutad Minikube:**

```bash
# Minikube docker environment
eval $(minikube docker-env)

# Build image'd Minikube sees
cd ../../apps/backend-nodejs
docker build -t user-service:1.0 .

cd ../frontend
docker build -t frontend:1.0 .

# Tagasi normaalsesse environmenti
eval $(minikube docker-env -u)

# Tagasi Lab 3'sse
cd ../../03-kubernetes-basics-lab
```

**Kui kasutad K3s:**

```bash
# Build image'd lokaalselt (kui puuduvad)
cd ../apps/backend-nodejs
docker build -t user-service:1.0 .
docker save user-service:1.0 > /tmp/user-service-1.0.tar

cd ../frontend
docker build -t frontend:1.0 .
docker save frontend:1.0 > /tmp/frontend-1.0.tar

# Import K3s'i
sudo k3s ctr images import /tmp/user-service-1.0.tar
sudo k3s ctr images import /tmp/frontend-1.0.tar

# Tagasi Lab 3'sse
cd ../../03-kubernetes-basics-lab
```

#### 4. Alusta Harjutus 1'st

```bash
cat exercises/01-pods.md
```

---

### ⚡ Kiirkontroll: Kas Oled Valmis?

```bash
# Kiirkontroll
kubectl version --client && \
kubectl cluster-info && \
kubectl get nodes && \
echo "✅ Kõik eeldused on täidetud!"
```

---

## ✅ Kontrolli Tulemusi

Peale labori läbimist pead omama:

- [ ] **Töötav Kubernetes cluster:**
  - [ ] Minikube või K3s käivitatud
  - [ ] kubectl ühendatud clusteriga

- [ ] **Deployments:**
  - [ ] `user-service` Deployment (replicas: 2)
  - [ ] `frontend` Deployment (replicas: 1)
  - [ ] `postgres` StatefulSet (replicas: 1)

- [ ] **Services:**
  - [ ] `user-service` (ClusterIP)
  - [ ] `frontend` (NodePort)
  - [ ] `postgres` (ClusterIP)

- [ ] **ConfigMaps:**
  - [ ] `app-config` (rakenduse seaded)
  - [ ] `db-config` (andmebaasi seaded)

- [ ] **Secrets:**
  - [ ] `db-credentials` (PostgreSQL paroolid)
  - [ ] `jwt-secret` (JWT signing key)

- [ ] **Persistent Volumes:**
  - [ ] `postgres-pv` (PersistentVolume)
  - [ ] `postgres-pvc` (PersistentVolumeClaim)

---

## 📊 Progressi Jälgimine

- [ ] Harjutus 1: Pods
- [ ] Harjutus 2: Deployments
- [ ] Harjutus 3: Services
- [ ] Harjutus 4: ConfigMaps & Secrets
- [ ] Harjutus 5: Persistent Volumes

---

## 🆘 Troubleshooting

### Cluster ei käivitu?

**Minikube:**
```bash
minikube delete
minikube start --cpus=2 --memory=4096 --driver=docker

# Kontrolli logisid
minikube logs
```

**K3s:**
```bash
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

---

### Pod ei käivitu?

```bash
# Vaata Pod statusit
kubectl get pods

# Detailne info
kubectl describe pod <pod-name>

# Vaata logisid
kubectl logs <pod-name>

# Vaata eelmise container'i logisid (kui crashis)
kubectl logs <pod-name> --previous

# Sisene töötavasse Pod'i
kubectl exec -it <pod-name> -- sh
```

---

### Image pull error?

```bash
# Minikube: kasuta local Docker image'e
eval $(minikube docker-env)
docker images  # Kontrolli, kas image olemas

# K3s: import image
sudo k3s ctr images import user-service-1.0.tar
```

---

### Service ei ole kättesaadav?

```bash
# Kontrolli Service'i
kubectl get svc
kubectl describe svc <service-name>

# Kontrolli Endpoints
kubectl get endpoints <service-name>

# Port forward testimiseks
kubectl port-forward svc/<service-name> 8080:80
curl http://localhost:8080
```

---

## 💡 Kasulikud Käsud

### Põhikäsud:

```bash
# Ressursid
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get pvc

# Kõik korraga
kubectl get all

# Detailne info
kubectl describe pod <name>
kubectl describe deployment <name>

# Logid
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow

# Exec
kubectl exec -it <pod-name> -- sh

# Port forward
kubectl port-forward pod/<pod-name> 8080:3000

# Apply manifest
kubectl apply -f deployment.yaml

# Delete
kubectl delete pod <pod-name>
kubectl delete -f deployment.yaml
```

### Debug käsud:

```bash
# Events
kubectl get events --sort-by=.metadata.creationTimestamp

# Resource usage
kubectl top nodes
kubectl top pods

# Cluster info
kubectl cluster-info
kubectl get nodes -o wide

# Namespace'id
kubectl get namespaces
kubectl get pods -n kube-system
```

---

## 📚 Viited

### Koolituskava:
- **Peatükk 15:** Kubernetes arhitektuur
- **Peatükk 16:** Kubernetes põhikomponendid

### Kubernetes Dokumentatsioon:
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

## 🎯 Järgmine Labor

Peale selle labori edukat läbimist, jätka:
- **Labor 4:** Kubernetes Täiustatud (Ingress, Helm, Autoscaling)

---

**Edu laboriga! 🚀**

*Kubernetes on võimas - pärast seda laborit mõistad selle põhikomponente!*

---

**Staatus:** 📝 Harjutuste loomine käib
**Viimane uuendus:** 2025-11-16
