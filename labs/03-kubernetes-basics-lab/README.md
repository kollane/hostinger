# Labor 3: Kubernetes Põhitõed

**Kestus:** 6 tundi
**Eeldused:** Labor 1-2 läbitud, Peatükk 15-16 (Kubernetes)
**Eesmärk:** Deploy mikroteenuste süsteem Kubernetes cluster'isse

---

## 📋 Ülevaade

Selles laboris **tõlgid Lab 2 Docker Compose rakenduse Kubernetes manifest'ideks** ja deploy'd täieliku mikroteenuste süsteemi Kubernetes cluster'isse.

Õpid Kubernetes fundamentaalseid kontseptsioone täisfunktsionaalse rakenduse näitel:
- **Pods** - väikseim deployable üksus
- **Deployments** - deklaratiivne rakenduste haldus
- **Services** - network discovery ja load balancing
- **ConfigMaps & Secrets** - konfiguratsiooni haldus
- **Persistent Volumes** - andmete püsiv salvestamine
- **InitContainers** - database migratsioonid

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

✅ Seadistada Kubernetes cluster'i (Minikube/K3s)
✅ Kirjutada Kubernetes YAML manifest'e
✅ Deploy'da rakendusi Deployment'idega
✅ Hallata teenuste suhtlust Service'idega
✅ Kasutada ConfigMaps ja Secrets turvaliselt
✅ Säilitada andmeid PersistentVolume'idega
✅ Rakendada database migration'eid InitContainers'iga
✅ Debuggida Kubernetes ressursse kubectl'iga
✅ Mõista Kubernetes põhiarhitektuuri

---

## 🏗️ Arhitektuur

### Lab 2 Lõpuseisu (Stardipunkt)

**Docker Compose: 5 teenust**

```
┌─────────────────────────────────────────────────────┐
│          Docker Compose (Lab 2)                     │
│                                                     │
│  Frontend (Nginx:8080)                              │
│       │                                             │
│       ├──> User Service (Node.js:3000)              │
│       │         │                                   │
│       │         └──> PostgreSQL-User (5432)         │
│       │                    └─ Volume: postgres-user-data │
│       │                                             │
│       └──> Todo Service (Java:8081)                 │
│                 │                                   │
│                 └──> PostgreSQL-Todo (5433)         │
│                          └─ Volume: postgres-todo-data │
│                                                     │
│  Networks: todo-network                             │
└─────────────────────────────────────────────────────┘
```

### Lab 3 Sihtolek (Kubernetes)

**Kubernetes Cluster: 5 Deployments/StatefulSets**

```
┌─────────────────────────────────────────────────────────────────┐
│                Kubernetes Cluster (Lab 3)                       │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Namespace: default                                       │  │
│  │                                                          │  │
│  │   Service: frontend-svc (NodePort :30080)                │  │
│  │        │                                                 │  │
│  │        ▼                                                 │  │
│  │   Deployment: frontend (replicas: 1)                     │  │
│  │        └─ Pod: frontend-xxx                              │  │
│  │             └─ Container: nginx:alpine                   │  │
│  │                  └─ volumeMount: /usr/share/nginx/html   │  │
│  │                                                          │  │
│  │   Service: user-service (ClusterIP :3000)                │  │
│  │        │                                                 │  │
│  │        ▼                                                 │  │
│  │   Deployment: user-service (replicas: 2)                 │  │
│  │        ├─ initContainer: liquibase-user-init             │  │
│  │        └─ Pod: user-service-xxx (x2)                     │  │
│  │             └─ Container: user-service:1.0-optimized     │  │
│  │                  ├─ envFrom: user-config (ConfigMap)     │  │
│  │                  └─ envFrom: db-user-secret (Secret)     │  │
│  │                       │                                  │  │
│  │                       └──> Service: postgres-user        │  │
│  │                                  │                       │  │
│  │                                  ▼                       │  │
│  │                       StatefulSet: postgres-user         │  │
│  │                            └─ PVC: postgres-user-data    │  │
│  │                                                          │  │
│  │   Service: todo-service (ClusterIP :8081)                │  │
│  │        │                                                 │  │
│  │        ▼                                                 │  │
│  │   Deployment: todo-service (replicas: 2)                 │  │
│  │        ├─ initContainer: liquibase-todo-init             │  │
│  │        └─ Pod: todo-service-xxx (x2)                     │  │
│  │             └─ Container: todo-service:1.0-optimized     │  │
│  │                  ├─ envFrom: todo-config (ConfigMap)     │  │
│  │                  └─ envFrom: db-todo-secret (Secret)     │  │
│  │                       │                                  │  │
│  │                       └──> Service: postgres-todo        │  │
│  │                                  │                       │  │
│  │                                  ▼                       │  │
│  │                       StatefulSet: postgres-todo         │  │
│  │                            └─ PVC: postgres-todo-data    │  │
│  │                                                          │  │
│  │  ConfigMaps: user-config, todo-config, frontend-config   │  │
│  │  Secrets: db-user-secret, db-todo-secret, jwt-secret     │  │
│  │  PVCs: postgres-user-data, postgres-todo-data            │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Võtmemuutused Docker Compose → Kubernetes:**

| Docker Compose | Kubernetes | Selgitus |
|----------------|------------|----------|
| `docker-compose.yml` | YAML manifests | Iga ressurss eraldi fail |
| `services:` | `Deployment` + `Service` | Deployment haldab Pods, Service avaldab |
| `depends_on:` | InitContainers | Liquibase käivitub enne rakendust |
| `volumes:` | PersistentVolumeClaim | PVC taotleb storage'i |
| `networks:` | DNS-based discovery | Pod'id leiavad üksteist Service'i nime järgi |
| `environment:` | ConfigMap + Secret | Eraldi ressursid env vars'i jaoks |
| `ports:` | Service (NodePort/ClusterIP) | Service avaldab Deployment'i |

---

## 📂 Labori Struktuur

```
03-kubernetes-basics-lab/
├── README.md                          # See fail
├── exercises/                         # Harjutused (6 tk)
│   ├── 01-cluster-setup-pods.md       # 60 min - Cluster + esimesed Pods
│   ├── 02-deployments-replicasets.md  # 60 min - Deployments + scaling
│   ├── 03-services-networking.md      # 60 min - Services + discovery
│   ├── 04-configuration-management.md # 60 min - ConfigMaps + Secrets
│   ├── 05-persistent-storage.md       # 60 min - PV/PVC + StatefulSets
│   └── 06-initcontainers-migrations.md # 60 min - InitContainers + Liquibase
├── solutions/                         # Täielikud lahendused
│   ├── 01-pods/
│   ├── 02-deployments/
│   ├── 03-services/
│   ├── 04-config/
│   ├── 05-storage/
│   ├── 06-full-stack/                 # Täielik süsteem (kõik 5 teenust)
│   └── README.md
└── setup.sh                           # Cluster setup automation
```

---

## 🔧 Eeldused

### ✅ Eelnevad Labid

**Labor 1: Docker Põhitõed (KOHUSTUSLIK)**
- Docker image'id loodud:
  - `user-service:1.0-optimized` (~50MB Node.js)
  - `todo-service:1.0-optimized` (~180MB Java)
  - `frontend:1.0` (~15MB Nginx)
- Dockerfile'ide mõistmine
- Container networking ja volumes

**Labor 2: Docker Compose (KOHUSTUSLIK)**
- Multi-container rakenduste kogemus
- `docker-compose.yml` struktuur
- Database migration'id Liquibase'iga (Harjutus 4)
- Service discovery kontseptsioon

**Labor 2.5: Network Analysis & Testing (VALIKULINE - EI OLE VAJALIK)**
- 🔷 **Lab 2.5 on valikuline süvendav materjal**
- Lab 2.5 EI OLE eeldus Lab 3 jaoks
- Võid jätkata Lab 3'ga kohe pärast Lab 2'd
- Lab 2.5 õpetab professionaalset võrgu analüüsi (valikuline, advanced)

### ✅ Tööriistad

**1. kubectl (Kubernetes CLI)**
```bash
# Ubuntu/Debian paigaldus
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Kontrolli
kubectl version --client
# Client Version: v1.28+
```

**2. Kubernetes Cluster (vali üks)**

**Variant A: Minikube** (soovitatud algajatele)
```bash
# Paigaldus
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Käivita
minikube start --cpus=2 --memory=4096 --driver=docker

# Kontrolli
kubectl cluster-info
kubectl get nodes
```

**Variant B: K3s** (lightweight, production-like)
```bash
# Paigaldus
curl -sfL https://get.k3s.io | sh -

# Setup kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

# Kontrolli
kubectl get nodes
```

**3. Ressursid**
- ✅ Vähemalt 4GB vaba RAM
- ✅ 20GB vaba kettaruumi
- ✅ Internet ühendus (image'ite load'imiseks)

### ✅ Teadmised

**Peatükid:**
- Peatükk 15: Kubernetes arhitektuur ja komponendid
- Peatükk 16: Kubernetes põhikontseptsioonid

**YAML süntaks:**
- Tühikud vs tabs (kasuta AINULT tühikuid!)
- Key-value paarid
- Arrays ja nested objects

---

## 📚 Progressiivne Õppetee

```
Lab 1: Docker Põhitõed (3h)
   ↓ Images, Containers, Networks, Volumes

Lab 2: Docker Compose (4.5h)
   ↓ Multi-container apps, Liquibase migrations

Lab 3: Kubernetes Põhitõed (6h) ← OLED SIIN
   ↓ Deploy Docker Compose → Kubernetes
   ↓ Pods, Deployments, Services, PV, InitContainers

Lab 4: Kubernetes Täiustatud (5h)
   ↓ Ingress, HPA, RBAC, Helm

Lab 5: CI/CD (4h)
   ↓ GitHub Actions → Kubernetes deploy

Lab 6: Monitoring & Logging (4h)
   ↓ Prometheus, Grafana, Loki
```

---

## 📝 Harjutused

### Harjutus 1: Cluster Setup & Pods (60 min)
**Fail:** [exercises/01-cluster-setup-pods.md](exercises/01-cluster-setup-pods.md)

**Seadista Kubernetes ja deploy esimesed Pod'id:**
- Käivita Kubernetes cluster (Minikube/K3s)
- Mõista Kubernetes arhitektuuri
- Loo esimene Pod imperatiivselt (`kubectl run`)
- Kirjuta Pod manifest YAML'is
- Deploy User Service Pod
- Debug Pod'i (logs, exec, describe)
- Mõista Pod lifecycle

**Õpid:**
- Kubernetes cluster setup
- kubectl põhikäsud
- Pod kontseptsioon ja manifest struktuur
- Container deployment K8s'is
- Basic troubleshooting

**Tulemus:**
```bash
kubectl get pods
# NAME              READY   STATUS    RESTARTS   AGE
# user-service-pod  1/1     Running   0          2m
```

---

### Harjutus 2: Deployments & ReplicaSets (60 min)
**Fail:** [exercises/02-deployments-replicasets.md](exercises/02-deployments-replicasets.md)

**Halda rakendusi Deployment'idega:**
- Mõista Deployment vs Pod
- Loo User Service Deployment (2 replicas)
- Loo Todo Service Deployment (2 replicas)
- Scale Deployment'e
- Rolling update (uuenda image versioon)
- Rollback ebaõnnestunud update
- Vaata ReplicaSet'i rolli

**Õpid:**
- Deployment manifest struktuur
- Replica management
- Self-healing (pod crashib → automaatselt uus)
- Rolling update strategy
- Version control Kubernetes'es

**Tulemus:**
```bash
kubectl get deployments
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   2/2     2            2           5m
# todo-service   2/2     2            2           3m

kubectl get pods
# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-7d4f8c9b6d-k8s7m   1/1     Running   0          5m
# user-service-7d4f8c9b6d-x2p9r   1/1     Running   0          5m
# todo-service-5c6b7d8e9f-a3q4w   1/1     Running   0          3m
# todo-service-5c6b7d8e9f-m7n8s   1/1     Running   0          3m
```

---

### Harjutus 3: Services & Networking (60 min)
**Fail:** [exercises/03-services-networking.md](exercises/03-services-networking.md)

**Avalda rakendused Service'idega:**
- Mõista Service tüüpe (ClusterIP, NodePort, LoadBalancer)
- Loo ClusterIP Service user-service'le
- Loo ClusterIP Service todo-service'le
- Loo NodePort Service frontend'ile
- Testi Service discovery (DNS)
- Kasuta Labels ja Selectors
- Port forwarding kubectl'iga

**Õpid:**
- Service discovery Kubernetes'es
- DNS-based service resolution
- Load balancing pod'ide vahel
- ClusterIP vs NodePort vs LoadBalancer
- Label selectors

**Tulemus:**
```bash
kubectl get services
# NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
# user-service   ClusterIP   10.96.123.45    <none>        3000/TCP         5m
# todo-service   ClusterIP   10.96.123.46    <none>        8081/TCP         5m
# frontend       NodePort    10.96.123.47    <none>        80:30080/TCP     3m

# Service discovery test (seest pod'ist):
curl http://user-service:3000/health
curl http://todo-service:8081/actuator/health
```

---

### Harjutus 4: Configuration Management (60 min)
**Fail:** [exercises/04-configuration-management.md](exercises/04-configuration-management.md)

**Halda konfiguratsioone ConfigMaps ja Secrets'iga:**
- Loo ConfigMap user-service seadete jaoks
- Loo ConfigMap todo-service seadete jaoks
- Loo Secret DB paroolide jaoks
- Loo Secret JWT signing key jaoks
- Inject ConfigMap environment variables'ina
- Inject Secret environment variables'ina
- Mount ConfigMap failina (nginx.conf)
- Uuenda ConfigMap ja rollout Deployment

**Õpid:**
- ConfigMap vs Secret erinevus
- Environment variable injection
- Volume mount konfiguratsioonile
- Base64 encoding Secrets'is
- 12-Factor App configuration pattern

**Tulemus:**
```bash
kubectl get configmaps
# NAME            DATA   AGE
# user-config     8      5m
# todo-config     6      5m

kubectl get secrets
# NAME                TYPE     DATA   AGE
# db-user-secret      Opaque   3      5m
# db-todo-secret      Opaque   3      5m
# jwt-secret          Opaque   2      5m

# Pod kasutab configmap + secret
kubectl describe pod user-service-xxx | grep -A5 "Environment"
```

---

### Harjutus 5: Persistent Storage (60 min)
**Fail:** [exercises/05-persistent-storage.md](exercises/05-persistent-storage.md)

**Säilita andmeid PersistentVolume'idega:**
- Mõista PV vs PVC vs StorageClass
- Loo PersistentVolume (hostPath)
- Loo PersistentVolumeClaim
- Mount PVC PostgreSQL Deployment'ile
- Testi andmete persistence (pod restart)
- Konverdi Deployment → StatefulSet
- StatefulSet volumeClaimTemplates

**Õpid:**
- PersistentVolume ja PersistentVolumeClaim
- Storage provisioning (static vs dynamic)
- StorageClass rolli
- StatefulSet vs Deployment
- Volume lifecycle ja reclaim policies

**Tulemus:**
```bash
kubectl get pv
# NAME                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
# postgres-user-pv     10Gi       RWO            Retain           Bound    default/postgres-user-pvc
# postgres-todo-pv     10Gi       RWO            Retain           Bound    default/postgres-todo-pvc

kubectl get pvc
# NAME                STATUS   VOLUME             CAPACITY   ACCESS MODES
# postgres-user-pvc   Bound    postgres-user-pv   10Gi       RWO
# postgres-todo-pvc   Bound    postgres-todo-pv   10Gi       RWO

kubectl get statefulsets
# NAME             READY   AGE
# postgres-user    1/1     5m
# postgres-todo    1/1     5m
```

---

### Harjutus 6: InitContainers & Database Migrations (60 min)
**Fail:** [exercises/06-initcontainers-migrations.md](exercises/06-initcontainers-migrations.md)

**Rakenda database migration'eid InitContainers'iga:**
- Mõista InitContainers kontseptsiooni
- Tõlgi Lab 2 Liquibase pattern K8s'i
- Loo Liquibase ConfigMap (changelog files)
- Lisa initContainer user-service Deployment'ile
- Lisa initContainer todo-service Deployment'ile
- Deploy täielik stack (5 teenust)
- Testi end-to-end workflow
- Verificeeri migration'ite rakendumist

**Õpid:**
- InitContainers vs Main containers
- Docker Compose `depends_on` → K8s InitContainers
- Database migration best practices
- Production-ready deployment pattern
- Troubleshooting init container failures

**Tulemus:**
```bash
kubectl get all
# NAME                                READY   STATUS    RESTARTS   AGE
# pod/postgres-user-0                 1/1     Running   0          10m
# pod/postgres-todo-0                 1/1     Running   0          10m
# pod/user-service-7d4f8c9b6d-k8s7m   1/1     Running   0          8m
# pod/user-service-7d4f8c9b6d-x2p9r   1/1     Running   0          8m
# pod/todo-service-5c6b7d8e9f-a3q4w   1/1     Running   0          6m
# pod/todo-service-5c6b7d8e9f-m7n8s   1/1     Running   0          6m
# pod/frontend-6b5c8d9e0f-p4r5t       1/1     Running   0          4m

# NAME                   TYPE        CLUSTER-IP      PORT(S)          AGE
# service/postgres-user  ClusterIP   10.96.123.44    5432/TCP         10m
# service/postgres-todo  ClusterIP   10.96.123.45    5432/TCP         10m
# service/user-service   ClusterIP   10.96.123.46    3000/TCP         8m
# service/todo-service   ClusterIP   10.96.123.47    8081/TCP         6m
# service/frontend       NodePort    10.96.123.48    80:30080/TCP     4m

# Test end-to-end
curl http://$(minikube ip):30080
# Frontend loads successfully

# Verificeeri migrations
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "\dt"
# Should show tables: users, databasechangelog, databasechangeloglock
```

---

## ✅ Kontrolli Tulemusi

Peale labori läbimist pead omama:

### Kubernetes Cluster
- [ ] Minikube või K3s käivitatud ja töötav
- [ ] kubectl ühendatud cluster'iga
- [ ] Node(s) Ready staatuses

### Deployments/StatefulSets
- [ ] `user-service` Deployment (replicas: 2)
- [ ] `todo-service` Deployment (replicas: 2)
- [ ] `frontend` Deployment (replicas: 1)
- [ ] `postgres-user` StatefulSet (replicas: 1)
- [ ] `postgres-todo` StatefulSet (replicas: 1)

### Services
- [ ] `user-service` ClusterIP (port 3000)
- [ ] `todo-service` ClusterIP (port 8081)
- [ ] `postgres-user` ClusterIP (port 5432)
- [ ] `postgres-todo` ClusterIP (port 5432)
- [ ] `frontend` NodePort (port 80 → 30080)

### Configuration
- [ ] ConfigMaps: `user-config`, `todo-config`, `liquibase-user-changelog`, `liquibase-todo-changelog`
- [ ] Secrets: `db-user-secret`, `db-todo-secret`, `jwt-secret`

### Storage
- [ ] PVC: `postgres-user-pvc` (Bound)
- [ ] PVC: `postgres-todo-pvc` (Bound)
- [ ] Andmed persistivad pod restart'i järel

### InitContainers
- [ ] Liquibase migrations käivituvad enne rakendust
- [ ] Database schema loodud automaatselt
- [ ] Rakendused käivituvad ainult pärast edukat migration'it

### End-to-End Test
- [ ] Frontend kättesaadav: `http://<node-ip>:30080`
- [ ] User registration töötab
- [ ] User login töötab (JWT)
- [ ] Todo CRUD töötab
- [ ] Andmed persistivad

---

## 🆘 Troubleshooting

### Cluster ei käivitu?

**Minikube:**
```bash
# Kustuta ja alusta uuesti
minikube delete
minikube start --cpus=2 --memory=4096 --driver=docker

# Vaata logisid
minikube logs
```

**K3s:**
```bash
# Kontrolli teenuse staatust
sudo systemctl status k3s

# Vaata logisid
sudo journalctl -u k3s -f
```

---

### Pod ei käivitu (ImagePullBackOff)?

```bash
# Kontrolli pod events
kubectl describe pod <pod-name>

# Minikube: kasuta local image'e
eval $(minikube docker-env)
docker images | grep user-service
# Kui puudub:
cd ~/labs/apps/backend-nodejs
docker build -t user-service:1.0-optimized -f Dockerfile.optimized .

# K3s: import image
docker save user-service:1.0-optimized > user-service.tar
sudo k3s ctr images import user-service.tar

# YAML'is:
spec:
  containers:
  - name: user-service
    image: user-service:1.0-optimized
    imagePullPolicy: Never  # või IfNotPresent
```

---

### Pod crashib (CrashLoopBackOff)?

```bash
# Vaata logisid
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Eelmise crash'i logid

# Vaata events
kubectl describe pod <pod-name>

# Sisene pod'i (kui töötab)
kubectl exec -it <pod-name> -- sh

# Levinud põhjused:
# - Puudub DB ühendus (kontrolli Service nimesid)
# - Vale environment variable (kontrolli ConfigMap/Secret)
# - Port juba kasutusel
# - Puudub dependency (DB pole valmis)
```

---

### Service ei ole kättesaadav?

```bash
# Kontrolli Service'i
kubectl get svc
kubectl describe svc <service-name>

# Kontrolli Endpoints (kas pod'id attached?)
kubectl get endpoints <service-name>

# Kui endpoints tühi:
# - Kontrolli Label selectors (Service vs Deployment)
# - Kontrolli, kas pod'id Running staatuses

# Port forwarding testimiseks
kubectl port-forward svc/<service-name> 8080:3000
curl http://localhost:8080/health
```

---

### InitContainer ebaõnnestub?

```bash
# Vaata init container logisid
kubectl logs <pod-name> -c <init-container-name>

# Näide:
kubectl logs user-service-xxx -c liquibase-user-init

# Describe pod näitab init container state
kubectl describe pod <pod-name>

# Levinud põhjused:
# - DB pole veel valmis (lisa DB healthcheck)
# - Vale DB connection string
# - Liquibase changelog'is syntax error
```

---

### PVC on Pending staatuses?

```bash
# Kontrolli PVC
kubectl describe pvc <pvc-name>

# Levinud põhjused:
# 1. PV puudub (loo PV või kasuta StorageClass)
# 2. PV ja PVC ei match'i (capacity, accessModes)
# 3. StorageClass puudub

# Minikube: kasuta "standard" StorageClass (auto-provisioning)
# K3s: kasuta "local-path" StorageClass
```

---

## 💡 Kasulikud Käsud

### Põhikäsud

```bash
# Kõik ressursid
kubectl get all

# Specific resources
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get configmaps
kubectl get secrets
kubectl get pvc
kubectl get statefulsets

# Wide output (rohkem infot)
kubectl get pods -o wide

# YAML output
kubectl get deployment user-service -o yaml

# Watch mode (auto-refresh)
kubectl get pods -w

# Detailne info
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
kubectl describe service <service-name>
```

### Debug käsud

```bash
# Logid
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>  # Multi-container pod
kubectl logs <pod-name> --previous  # Eelmise crash'i logid
kubectl logs -f <pod-name>  # Follow mode

# Exec pod'i
kubectl exec -it <pod-name> -- sh
kubectl exec -it <pod-name> -c <container-name> -- sh  # Multi-container

# Port forward
kubectl port-forward pod/<pod-name> 8080:3000
kubectl port-forward svc/<service-name> 8080:3000

# Events
kubectl get events --sort-by=.metadata.creationTimestamp

# Resource usage
kubectl top nodes
kubectl top pods
```

### Manifest management

```bash
# Apply manifest
kubectl apply -f deployment.yaml
kubectl apply -f ./manifests/  # Directory

# Delete
kubectl delete -f deployment.yaml
kubectl delete pod <pod-name>
kubectl delete deployment <deployment-name>
kubectl delete all -l app=user-service  # By label

# Edit live (ei soovita production'is!)
kubectl edit deployment user-service
```

### Cluster info

```bash
# Cluster info
kubectl cluster-info
kubectl version

# Nodes
kubectl get nodes
kubectl describe node <node-name>

# Namespaces
kubectl get namespaces
kubectl get pods -n kube-system  # System pods
```

---

## 📚 Viited

### Koolituskava
- **Peatükk 15:** Kubernetes Arhitektuur ja Komponendid
- **Peatükk 16:** Kubernetes Põhikontseptsioonid

### Kubernetes Dokumentatsioon
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Best Practices
- [Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Security Best Practices](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

---

## 🎯 Järgmine Labor

Peale selle labori edukat läbimist, jätka:

**Labor 4: Kubernetes Täiustatud**
- Ingress (domain-based routing, HTTPS)
- Health Probes (liveness, readiness, startup)
- HorizontalPodAutoscaler (CPU-based autoscaling)
- RBAC (Role-Based Access Control)
- Helm (package manager)

---

## 📊 Progressi Jälgimine

- [ ] Harjutus 1: Cluster Setup & Pods (60 min)
- [ ] Harjutus 2: Deployments & ReplicaSets (60 min)
- [ ] Harjutus 3: Services & Networking (60 min)
- [ ] Harjutus 4: Configuration Management (60 min)
- [ ] Harjutus 5: Persistent Storage (60 min)
- [ ] Harjutus 6: InitContainers & Migrations (60 min)

**Kokku: 6 tundi**

---

**Edu laboriga! 🚀**

*Kubernetes on võimas - pärast seda laborit mõistad selle tuumsüsteemi põhjalikult!*

---

**Staatus:** 🚧 Uute harjutuste loomine käib
**Viimane uuendus:** 2025-01-21
**Versioon:** 2.0 (Täielikult uuendatud - 2025 best practices)
