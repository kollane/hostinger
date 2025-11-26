# Harjutus 1: Cluster Setup & Pods

**Kestus:** 60 minutit
**Eesmärk:** Seadistada Kubernetes cluster ja deploy'da esimesed Pod'id

---

## 📋 Ülevaade

Selles harjutuses **seadistad Kubernetes cluster'i** ja õpid K8s põhikomponenti - **Pod**. Saad esmase kogemuse kubectl'iga ja mõistad, kuidas Kubernetes käivitab containereid.

**Pod** on Kubernetes'e väikseim deployable üksus - üks või mitu konteinerit, mis jagavad samad ressursid (võrk (network), salvestamine (storage)).

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Käivitada Kubernetes cluster'i (Minikube või K3s)
- ✅ Kasutada kubectl põhikäske
- ✅ Mõista Kubernetes arhitektuuri (Control Plane, Worker Nodes)
- ✅ Luua Pod'e imperatiivselt (`kubectl run`)
- ✅ Kirjutada Pod manifest'e YAML'is (deklaratiivne)
- ✅ Deploy'da User Service Pod
- ✅ Vaadata Pod'ide logisid ja state'i
- ✅ Debuggida Pod'ide probleeme
- ✅ Sisestada containerisse exec käskudega
- ✅ Kustutada ressursse

---

## 🏗️ Arhitektuur

### Kubernetes Cluster Struktuur

```
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Cluster                         │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Control Plane (Master Node)              │  │
│  │  ┌─────────────┬─────────────┬─────────────┐     │  │
│  │  │ API Server  │  Scheduler  │  Controller │     │  │
│  │  └─────────────┴─────────────┴─────────────┘     │  │
│  │  │ etcd (cluster state storage)              │    │  │
│  │  └──────────────────────────────────────────┘     │  │
│  └────────────────────┬─────────────────────────────┘  │
│                       │                                │
│  ┌────────────────────▼─────────────────────────────┐  │
│  │         Worker Node(s)                           │  │
│  │                                                  │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │  Kubelet (Node Agent)                      │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │  Container Runtime (Docker/containerd)     │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  │                                                  │  │
│  │  Pods:                                           │  │
│  │  ┌─────────────────┐  ┌─────────────────┐       │  │
│  │  │ Pod: nginx-pod  │  │Pod: user-service│       │  │
│  │  │ ┌─────────────┐ │  │ ┌─────────────┐ │       │  │
│  │  │ │  Container  │ │  │ │  Container  │ │       │  │
│  │  │ │nginx:alpine │ │  │ │user-service │ │       │  │
│  │  │ │   port:80   │ │  │ │  port:3000  │ │       │  │
│  │  │ └─────────────┘ │  │ └─────────────┘ │       │  │
│  │  └─────────────────┘  └─────────────────┘       │  │
│  │                                                  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Komponendid:**
- **Control Plane:** Haldab cluster'it (API Server, Scheduler, Controller Manager, etcd)
- **Worker Node(s):** Käivitavad pod'e (Kubelet, Container Runtime)
- **Pod:** Väikseim üksus - 1+ konteinerit
- **kubectl:** CLI cluster'iga suhtlemiseks

---

## 📝 Sammud

### Samm 1: Paigalda kubectl (5 min)

**kubectl** on Kubernetes CLI - peamine tööriist cluster'iga suhtlemiseks.

```bash
# Lae alla kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Paigalda
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Kontrolli versiooni
kubectl version --client --output=yaml

# Peaks näitama:
# clientVersion:
#   gitVersion: v1.28.x
```

**Bash completion (soovituslik):**
```bash
# Lisa kubectl autocompletion
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc

# Nüüd saad kasutada:
k get pods  # Lühike alias
k get po    # Veel lühem (kubectl toetab lühendeid)
```

---

### Samm 2: Käivita Kubernetes Cluster (15 min)

Vali **üks** variant:

#### **Variant A: Minikube** (soovitatud algajatele)

Minikube käivitab single-node Kubernetes cluster'i lokaalselt.

```bash
# Paigalda Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Käivita cluster
minikube start --cpus=2 --memory=4096 --driver=docker

# Output:
# 😄  minikube v1.32.0 on Ubuntu 24.04
# ✨  Using the docker driver based on user configuration
# 👍  Starting control plane node minikube in cluster minikube
# 🚜  Pulling base image ...
# 🔥  Creating docker container (CPUs=2, Memory=4096MB) ...
# 🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
# 🔗  Configuring bridge CNI (Container Networking Interface) ...
# 🔎  Verifying Kubernetes components...
# 🌟  Enabled addons: storage-provisioner, default-storageclass
# 🏄  Done! kubectl is now configured to use "minikube" cluster

# Kontrolli cluster'i
kubectl cluster-info

# Output:
# Kubernetes control plane is running at https://192.168.49.2:8443
# CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# Kontrolli node'e
kubectl get nodes

# Output:
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   2m    v1.28.3
```

**Minikube kasulikud käsud:**
```bash
minikube status         # Cluster staatus
minikube stop           # Peata cluster
minikube start          # Käivita uuesti
minikube delete         # Kustuta cluster
minikube dashboard      # Ava web UI
minikube ip             # Cluster IP
minikube ssh            # Sisene node'i
minikube logs           # Vaata logisid
```

---

#### **Variant B: K3s** (lightweight, production-like)

K3s on kerge Kubernetes distributsioon, sobib VPS'idele.

```bash
# Paigalda K3s
curl -sfL https://get.k3s.io | sh -

# Output:
# [INFO]  Finding release for channel stable
# [INFO]  Using v1.28.3+k3s1 as release
# [INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.28.3+k3s1/sha256sum-amd64.txt
# [INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.28.3+k3s1/k3s
# [INFO]  Verifying binary download
# [INFO]  Installing k3s to /usr/local/bin/k3s
# [INFO]  Skipping installation of SELinux RPM
# [INFO]  Creating /usr/local/bin/kubectl symlink to k3s
# [INFO]  Creating /usr/local/bin/crictl symlink to k3s
# [INFO]  Skipping /usr/local/bin/ctr symlink to k3s, command exists in PATH at /usr/bin/ctr
# [INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
# [INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
# [INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
# [INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
# [INFO]  systemd: Enabling k3s unit
# [INFO]  systemd: Starting k3s

# Kontrolli teenuse staatust
sudo systemctl status k3s

# Seadista kubeconfig (et kasutada kubectl ilma sudo'ta)
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config

# Kontrolli cluster'i
kubectl cluster-info

# Kontrolli node'e
kubectl get nodes

# Output:
# NAME       STATUS   ROLES                  AGE   VERSION
# kirjakast  Ready    control-plane,master   1m    v1.28.3+k3s1
```

**K3s kasulikud käsud:**
```bash
sudo systemctl status k3s      # Teenuse staatus
sudo systemctl stop k3s         # Peata
sudo systemctl start k3s        # Käivita
sudo journalctl -u k3s -f       # Vaata logisid
/usr/local/bin/k3s-uninstall.sh # Desinstalli
```

---

### Samm 3: Kontrolli Cluster'i (5 min)

Olenemata valitud variant'ist, kontrolli et cluster töötab:

```bash
# Cluster info
kubectl cluster-info

# Node'id (peaks olema vähemalt 1 Ready staatuses)
kubectl get nodes

# Detailne node info
kubectl get nodes -o wide

# System pod'id (Kubernetes core komponendid)
kubectl get pods -n kube-system

# Output peaks näitama pod'e nagu:
# - coredns-xxx (DNS)
# - etcd-xxx (state storage)
# - kube-apiserver-xxx (API server)
# - kube-controller-manager-xxx
# - kube-scheduler-xxx
# - kube-proxy-xxx (networking)

# Kubernetes API versioonid
kubectl api-resources

# Namespace'id
kubectl get namespaces

# Output:
# NAME              STATUS   AGE
# default           Active   5m    <- Siin töötame
# kube-node-lease   Active   5m
# kube-public       Active   5m
# kube-system       Active   5m    <- System components
```

✅ **Checkpoint:** Kui `kubectl get nodes` näitab node'i Ready staatuses, oled valmis!

---

### Samm 4: Loo Esimene Pod Imperatiivselt (5 min)

**Imperatiivne lähenemine:** Käsurea käsk loob ressursi kohe.

```bash
# Loo lihtne nginx Pod
kubectl run nginx-pod --image=nginx:alpine

# Output:
# pod/nginx-pod created

# Kontrolli pod'i
kubectl get pods

# Output:
# NAME        READY   STATUS              RESTARTS   AGE
# nginx-pod   0/1     ContainerCreating   0          5s

# Oota ~10-20 sekundit, kontrolli uuesti
kubectl get pods

# Output:
# NAME        READY   STATUS    RESTARTS   AGE
# nginx-pod   1/1     Running   0          30s
```

**Mõisted:**
- `READY 1/1`: 1 container 1'st töötab
- `STATUS Running`: Pod töötab
- `RESTARTS 0`: Pole crashinud/restartinud
- `AGE`: Aeg loomisest

```bash
# Detailne info pod'i kohta
kubectl describe pod nginx-pod

# Näitab:
# - Node kus pod töötab
# - Container image ja state
# - Environment variables
# - Volumes
# - Events (mis juhtus pod'i loomise ajal)

# Vaata logisid
kubectl logs nginx-pod

# Output (nginx access log):
# /docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
# ...

# Sisene pod'i containerisse
kubectl exec -it nginx-pod -- sh

# Oled nüüd container'i sees:
/ # ls -la
/ # ps aux
/ # cat /etc/nginx/nginx.conf
/ # exit

# Kustuta pod
kubectl delete pod nginx-pod

# Output:
# pod "nginx-pod" deleted
```

---

### Samm 5: Loo Pod YAML Manifest'iga (Deklaratiivne) (15 min)

**Deklaratiivne lähenemine** (best practice): Kirjuta YAML fail, mis kirjeldab soovitud seisund.

#### **Näide 1: Lihtne nginx Pod**

Loo fail `nginx-pod.yaml`:

```bash
vim nginx-pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-demo
  labels:
    app: nginx
    environment: dev
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
      name: http
```

**YAML struktuuri selgitus:**

```yaml
apiVersion: v1              # API versioon (v1 = core API)
kind: Pod                   # Ressursi tüüp
metadata:                   # Metadata pod'i kohta
  name: nginx-demo          # Pod'i nimi (unikaalne namespace'is)
  labels:                   # Key-value paarid (kasutatakse selector'ites)
    app: nginx
    environment: dev
spec:                       # Specification - soovitud seisund
  containers:               # Array konteinerite definitsioonidest
  - name: nginx             # Container'i nimi pod'i sees
    image: nginx:alpine     # Docker image
    ports:                  # Avaldatavad pordid
    - containerPort: 80     # Container kuulab port'i 80
      name: http            # Port'i nimi (optional, aga hea dokumentatsiooniks)
```

**Deploy pod:**

```bash
# Apply manifest (loo või uuenda ressurss)
kubectl apply -f nginx-pod.yaml

# Output:
# pod/nginx-demo created

# Kontrolli
kubectl get pods

# Output:
# NAME         READY   STATUS    RESTARTS   AGE
# nginx-demo   1/1     Running   0          10s

# Vaata loodud YAML'i (Kubernetes lisas palju metainfot)
kubectl get pod nginx-demo -o yaml

# Või JSON formaadis
kubectl get pod nginx-demo -o json
```

**Testi pod'i:**

```bash
# Port forward local port 8080 → pod port 80
kubectl port-forward pod/nginx-demo 8080:80

# Teises terminalis:
curl http://localhost:8080

# Peaks tagastama nginx default page HTML
```

**Kustuta pod:**

```bash
# Kustuta manifest'i järgi
kubectl delete -f nginx-pod.yaml

# Või nime järgi
kubectl delete pod nginx-demo
```

---

#### **Näide 2: User Service Pod (Lab 1 image)**

Nüüd deploy'me Lab 1'st loodud `user-service` image.

**Esmalt: Lae image Kubernetes cluster'isse**

**Kui kasutad Minikube:**
```bash
# Kasuta Minikube Docker environmenti
eval $(minikube docker-env)

# Build või lae image Minikube'i
cd ~/labs/apps/backend-nodejs
docker build -t user-service:1.0-optimized -f Dockerfile.optimized .

# Kontrolli
docker images | grep user-service

# Tagasi normaalsesse env'i
eval $(minikube docker-env -u)

# Tagasi Lab 3 exercises kausta
cd -
```

**Kui kasutad K3s:**
```bash
# Build image lokaalselt (kui pole juba)
cd ~/labs/apps/backend-nodejs
docker build -t user-service:1.0-optimized -f Dockerfile.optimized .

# Salvesta tar failina
docker save user-service:1.0-optimized -o /tmp/user-service.tar

# Impordi K3s'i
sudo k3s ctr images import /tmp/user-service.tar

# Kontrolli
sudo k3s ctr images ls | grep user-service

# Tagasi Lab 3 exercises kausta
cd -
```

**Loo Pod manifest:**

Loo fail `user-service-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: user-service
  labels:
    app: user-service
    tier: backend
    version: "1.0"
spec:
  containers:
  - name: user-service
    image: user-service:1.0-optimized
    imagePullPolicy: Never  # Ära pull Docker Hub'ist, kasuta local image'i
    ports:
    - containerPort: 3000
      name: http
      protocol: TCP
    env:
    - name: PORT
      value: "3000"
    - name: NODE_ENV
      value: "development"
    - name: DB_HOST
      value: "localhost"  # Hetkel puudub DB, seepärast localhost
    - name: DB_PORT
      value: "5432"
    - name: DB_NAME
      value: "user_service_db"
    - name: DB_USER
      value: "postgres"
    - name: DB_PASSWORD
      value: "postgres"
    - name: JWT_SECRET
      value: "temporary-dev-secret-key"
    - name: JWT_EXPIRES_IN
      value: "1h"
```

**Deploy:**

```bash
# Apply
kubectl apply -f user-service-pod.yaml

# Kontrolli
kubectl get pods

# Peaks näitama:
# NAME           READY   STATUS    RESTARTS   AGE
# user-service   1/1     Running   0          15s

# Vaata logisid
kubectl logs user-service

# Peaks näitama user-service käivitumist:
# Server running on port 3000
# Database connection: ERROR (see on OK - DB pole veel)

# Describe (detailne info)
kubectl describe pod user-service

# Näitab:
# - Node: minikube või kirjakast
# - Status: Running
# - IP: 10.244.x.x (cluster internal)
# - Containers: user-service
# - Events: Pulled, Created, Started
```

---

### Samm 6: Testi Pod'i (10 min)

**Port Forward ja API testimine:**

```bash
# Port forward local 8080 → pod 3000
kubectl port-forward pod/user-service 8080:3000

# Käivita background'is (Lisa & lõppu)
kubectl port-forward pod/user-service 8080:3000 &

# Testi health endpoint
curl http://localhost:8080/health

# Output (DB ühendus puudub, aga see on OK):
# {
#   "status": "ERROR",
#   "database": "disconnected",
#   "message": "getaddrinfo ENOTFOUND localhost"
# }

# Siin on põhjus: DB_HOST=localhost, aga Kubernetes'es ei ole DB'd

# Peata port forward
pkill -f "port-forward"
```

**Exec pod'i ja uurimine:**

```bash
# Sisene pod'i
kubectl exec -it user-service -- sh

# Oled nüüd container'i sees:
/app $ ls -la
# total 56
# drwxr-xr-x    1 node     node          4096 Jan 21 10:30 .
# ...
# -rw-r--r--    1 node     node           123 Jan 21 10:30 package.json
# drwxr-xr-x    5 node     node          4096 Jan 21 10:30 src

/app $ cat package.json
/app $ env | grep DB
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=user_service_db
# ...

/app $ ps aux
# PID   USER     TIME  COMMAND
#     1 node      0:00 node src/index.js
#    23 node      0:00 sh

/app $ exit
```

---

### Samm 7: Debuggi Pod'e (5 min)

**Levinud Pod STATE'id:**

```bash
kubectl get pods

# Võimalikud STATE'id:
# - Pending: Planeeritakse node'le (ootab ressursse)
# - ContainerCreating: Image pullimine ja container loomine
# - Running: Töötab
# - CrashLoopBackOff: Crashib kogu aeg (restart loop)
# - Error: Viga juhtus
# - Completed: Lõpetatud edukalt (Jobs)
# - Terminating: Kustutatakse
# - ImagePullBackOff: Ei saa image'i alla laadida
```

**Debug workflow:**

```bash
# 1. Kontrolli staatust
kubectl get pods

# 2. Describe pod'i (events on kõige olulisem)
kubectl describe pod user-service

# Vaata "Events" sektsiooni lõpus:
# Events:
#   Type    Reason     Age   From               Message
#   ----    ------     ----  ----               -------
#   Normal  Scheduled  2m    default-scheduler  Successfully assigned default/user-service to minikube
#   Normal  Pulled     2m    kubelet            Container image "user-service:1.0-optimized" already present on machine
#   Normal  Created    2m    kubelet            Created container user-service
#   Normal  Started    2m    kubelet            Started container user-service

# 3. Vaata logisid
kubectl logs user-service

# Kui pod crashis, vaata eelmise container'i logisid
kubectl logs user-service --previous

# Follow logs real-time
kubectl logs -f user-service

# 4. Sisene pod'i (kui Running)
kubectl exec -it user-service -- sh
```

---

### Samm 8: Labels ja Selectors (5 min)

**Labels** on key-value paarid metadata'na. Neid kasutatakse ressursside grupeerimiseks ja selector'ites.

```bash
# Vaata pod'i label'eid
kubectl get pod user-service --show-labels

# Output:
# NAME           READY   STATUS    RESTARTS   AGE   LABELS
# user-service   1/1     Running   0          10m   app=user-service,tier=backend,version=1.0

# Filter pod'e label'i järgi
kubectl get pods -l app=user-service
kubectl get pods -l tier=backend
kubectl get pods -l version=1.0

# Multiple labels (AND)
kubectl get pods -l app=user-service,tier=backend

# Label selector operators
kubectl get pods -l 'version in (1.0,1.1)'  # IN operator
kubectl get pods -l 'tier!=frontend'        # NOT EQUAL

# Lisa uus label olemasolevale pod'ile
kubectl label pod user-service environment=dev

# Uuenda label'it
kubectl label pod user-service version=1.1 --overwrite

# Kustuta label (lisa -)
kubectl label pod user-service version-

# Vaata uuesti
kubectl get pod user-service --show-labels
```

**Miks labels on olulised?**
- Services kasutavad label selector'eid pod'ide leidmiseks (Harjutus 3)
- Deployments kasutavad label'eid pod'ide haldamiseks (Harjutus 2)
- Võimaldavad gruppeerida ja filtreerida ressursse

---

### Samm 9: Kustu Ressursid (5 min)

```bash
# Kustuta üks pod
kubectl delete pod user-service

# Kustuta manifest'i järgi
kubectl delete -f user-service-pod.yaml

# Kustuta kõik pod'id label'i järgi
kubectl delete pods -l app=user-service

# Force delete (kui stuck)
kubectl delete pod user-service --force --grace-period=0

# Kustuta kõik pod'id namespace'is (ETTEVAATUST!)
kubectl delete pods --all
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **Kubernetes cluster:**
  - [ ] Minikube või K3s käivitatud
  - [ ] kubectl toimib ja ühendatud cluster'iga
  - [ ] Node Ready staatuses

- [ ] **Pod loomine:**
  - [ ] Imperatiivselt: `kubectl run`
  - [ ] Deklaratiivselt: YAML manifest + `kubectl apply`

- [ ] **Pod haldamine:**
  - [ ] `kubectl get pods` - listi vaatamine
  - [ ] `kubectl describe pod` - detailne info
  - [ ] `kubectl logs` - logide vaatamine
  - [ ] `kubectl exec` - containerisse sisenemine
  - [ ] `kubectl port-forward` - local port mapping

- [ ] **Debug:**
  - [ ] Pod state'ide tundmine
  - [ ] Events'ide lugemine describe'ist
  - [ ] Logide analüüs

- [ ] **Labels:**
  - [ ] Label'ite lisamine ja kustutamine
  - [ ] Label selector'ite kasutamine

---

## 🐛 Troubleshooting

### Probleem 1: ImagePullBackOff

**Sümptom:**
```bash
kubectl get pods
# NAME           READY   STATUS             RESTARTS   AGE
# user-service   0/1     ImagePullBackOff   0          2m
```

**Põhjus:** Kubernetes ei leia image'i (ei ole Docker Hub'is ega lokaalselt).

**Lahendus:**

```bash
# Kontrolli events
kubectl describe pod user-service | grep -A10 Events

# Events näitab:
# Failed to pull image "user-service:1.0-optimized": rpc error: code = Unknown desc = Error response from daemon: pull access denied

# Lahendus: Lae image cluster'isse

# Minikube:
eval $(minikube docker-env)
docker images | grep user-service
# Kui puudub:
cd ~/labs/apps/backend-nodejs
docker build -t user-service:1.0-optimized -f Dockerfile.optimized .

# K3s:
docker build -t user-service:1.0-optimized -f Dockerfile.optimized .
docker save user-service:1.0-optimized -o /tmp/user-service.tar
sudo k3s ctr images import /tmp/user-service.tar

# YAML'is kontrolli:
imagePullPolicy: Never  # või IfNotPresent
```

---

### Probleem 2: CrashLoopBackOff

**Sümptom:**
```bash
kubectl get pods
# NAME           READY   STATUS             RESTARTS   AGE
# user-service   0/1     CrashLoopBackOff   5          5m
```

**Põhjus:** Container käivitub, aga crashib kohe.

**Diagnoos:**

```bash
# Vaata logisid
kubectl logs user-service
kubectl logs user-service --previous  # Eelmise crash'i logid

# Describe pod'i
kubectl describe pod user-service

# Levinud põhjused:
# - Rakendus crashib (syntax error, unhandled exception)
# - Puudub dependency (DB, environment variable)
# - Vale command või entrypoint
# - Port juba kasutusel
```

**Lahendus:** Paranda pod YAML'i (environment variables, image) ja apply uuesti.

---

### Probleem 3: Pending (ei lähe Running'isse)

**Sümptom:**
```bash
kubectl get pods
# NAME           READY   STATUS    RESTARTS   AGE
# user-service   0/1     Pending   0          5m
```

**Põhjus:** Ei saa pod'i node'le planeerida.

**Diagnoos:**

```bash
kubectl describe pod user-service

# Events:
# Warning  FailedScheduling  5m  default-scheduler  0/1 nodes are available: 1 Insufficient cpu.

# Levinud põhjused:
# - Insufficient resources (CPU/memory)
# - Node selector ei match'i
# - Taints ja tolerations
```

**Lahendus:**

```bash
# Kontrolli node ressursse
kubectl describe node minikube

# Vähenda pod'i resource requests (õpime Harjutus 5'is)
```

---

## 🎓 Õpitud Mõisted

### Kubernetes Arhitektuur
- **Control Plane:** Haldab cluster'it (API Server, Scheduler, Controller Manager, etcd)
- **Worker Node:** Käivitab pod'e (Kubelet, Container Runtime)
- **Namespace:** Loogiline eraldus (nt. dev, staging, prod)

### Pod Kontseptsioonid
- **Pod:** Väikseim deployable üksus (1+ konteinerit)
- **Container:** Docker container pod'i sees
- **Shared network:** Kõik pod'i containerid jagavad sama IP'd ja localhost'i
- **Shared volumes:** Kõik containerid näevad samu volume'id

### kubectl Käsud
- `kubectl run` - Loo pod imperatiivselt
- `kubectl apply -f` - Deploy manifest (deklaratiivne)
- `kubectl get pods` - Listi pod'e
- `kubectl get pods -o wide` - Rohkem infot (IP, Node)
- `kubectl describe pod` - Detailne info (events!)
- `kubectl logs` - Container logid
- `kubectl logs -f` - Follow logs
- `kubectl exec -it <pod> -- sh` - Sisene containerisse
- `kubectl port-forward pod/<name> 8080:3000` - Map local port
- `kubectl delete pod` - Kustuta pod

### Pod Lifecycle
1. **Pending:** Planeeritakse node'le
2. **ContainerCreating:** Image pullimine ja container loomine
3. **Running:** Container(id) töötavad
4. **Succeeded:** Container lõpetas edukalt (Jobs)
5. **Failed:** Container crashis
6. **CrashLoopBackOff:** Crashib restart loop'is
7. **Unknown:** State teadmata

---

## 💡 Parimad Tavad

### ✅ DO (Tee):
1. **Kasuta YAML manifest'e** - Deklaratiivne on parem kui imperatiivne
2. **Lisa labels** - Hõlbustab ressursside haldamist
3. **Määra imagePullPolicy:**
   - `Never` - local development (Minikube)
   - `IfNotPresent` - kontrolli local, siis pull
   - `Always` - pull alati (production)
4. **Dokumenteeri port'e nimega** - `name: http`, `name: metrics`
5. **Kasuta `kubectl describe`** - Events sektsioon on debug'imiseks kuldaväärt
6. **Vaata `kubectl get pods -o wide`** - Näitab IP'd ja Node'i

### ❌ DON'T (Ära tee):
1. **Ära deploy pod'e otse production'is** - Kasuta Deployment'e (Harjutus 2)
2. **Ära pane saladusi (passwords) otse YAML'i** - Kasuta Secrets (Harjutus 4)
3. **Ära jäta resource limits'eid määramata** - Võib ammendada cluster'i (Harjutus 5)
4. **Ära unusta health checks** - Liveness/Readiness probes (Lab 4)

---

## 🔗 Järgmine Samm

Pod'id on suurepärased mõistmaks Kubernetes põhimõtteid, aga **production'is ei deploy'ta pod'e otse**!

**Miks?**
- Kui pod crashib → ei tule automaatselt tagasi
- Kui node crashib → pod kaob
- Ei saa scale'ida (mitu koopiat)
- Ei saa teha rolling update'e

**Lahendus:** Kasuta **Deployment'e**, mis haldavad pod'e automaatselt:
- Self-healing (pod crashib → loob uue)
- Scaling (määra replicas count)
- Rolling updates (uuenda ilma downtime'ita)
- Rollback (tagasi eelmise versiooni juurde)

**Järgmises harjutuses õpid Deployment'e!**

---

**Jätka:** [Harjutus 2: Deployments & ReplicaSets](02-deployments-replicasets.md)

---

## 📚 Viited

**Kubernetes Dokumentatsioon:**
- [Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

**Minikube:**
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Minikube Start](https://minikube.sigs.k8s.io/docs/start/)

**K3s:**
- [K3s Documentation](https://docs.k3s.io/)
- [K3s Quick Start](https://docs.k3s.io/quick-start)

---

**Õnnitleme! Oled deploy'nud oma esimesed Kubernetes Pod'id! 🎉**

*Kubernetes on võimas - järgmises harjutuses õpid, kuidas Deployment'id haldavad pod'e automaatselt!*
