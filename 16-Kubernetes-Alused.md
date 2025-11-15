# Peatükk 16: Kubernetes Alused ☸️

**Kestus:** 4 tundi
**Eeldused:** Peatükk 12-15 läbitud, kubectl paigaldatud (Peatükk 13)
**Eesmärk:** Õppida Kubernetes põhimõtteid ja paigaldada K3s VPS-ile

---

## Sisukord

1. [Mis on Kubernetes?](#1-mis-on-kubernetes)
2. [Kubernetes Arhitektuur](#2-kubernetes-arhitektuur)
3. [K3s vs Kubernetes](#3-k3s-vs-kubernetes)
4. [K3s Paigaldamine VPS-ile](#4-k3s-paigaldamine-vps-ile)
5. [kubectl Konfigureerimine](#5-kubectl-konfigureerimine)
6. [Pods](#6-pods)
7. [Deployments](#7-deployments)
8. [Services](#8-services)
9. [Namespaces](#9-namespaces)
10. [Labels ja Selectors](#10-labels-ja-selectors)
11. [Harjutused](#11-harjutused)

---

## 1. Mis on Kubernetes?

### 1.1. Definitsioon

**Kubernetes** (K8s) on avatud lähtekoodiga container orkestratsioonisüsteem.

**Probleem:**
- Docker Compose sobib 1 serverisse
- Kuidas hallata 100+ konteinerit 10+ serveris?
- Kuidas skaleerida automaatselt?
- Kuidas taastuda serverite rikete korral?

**Lahendus:** Kubernetes

---

### 1.2. Kubernetes vs Docker Compose

| Feature | Docker Compose | Kubernetes |
|---------|---------------|------------|
| **Scale** | Üks server | Mitu serverit (cluster) |
| **HA** | Ei | Jah (auto-restart, replication) |
| **Auto-scaling** | Ei | Jah (HPA) |
| **Self-healing** | Restart policy | Auto-restart, reschedule |
| **Load balancing** | Lihtne | Native (Service) |
| **Rolling updates** | Manuaalne | Automaatne |
| **Config** | docker-compose.yml | YAML manifests |
| **Complexity** | Lihtne | Keeruline |
| **Use case** | Dev/test, väike prod | Suur prod, microservices |

---

### 1.3. Kubernetes Põhimõisted

**Cluster:** Serverite grupp (nodes), mis käivitavad containereid

**Node:** Üks server (VM või bare metal)

**Pod:** Väikseim üksus, sisaldab 1+ konteinerit

**Deployment:** Haldab pod-e (replicas, updates)

**Service:** Load balancer pod-ide vahel

**Namespace:** Virtuaalne cluster ressursside isoleerimiseks

---

## 2. Kubernetes Arhitektuur

### 2.1. Cluster Struktuur

```
┌────────────────────────────────────────────┐
│          KUBERNETES CLUSTER                │
├────────────────────────────────────────────┤
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │       CONTROL PLANE (Master)         │ │
│  ├──────────────────────────────────────┤ │
│  │  - API Server (kube-apiserver)       │ │
│  │  - Scheduler (kube-scheduler)        │ │
│  │  - Controller Manager                │ │
│  │  - etcd (database)                   │ │
│  └──────────────────────────────────────┘ │
│                    │                       │
│         ┌──────────┼──────────┐            │
│         │          │          │            │
│  ┌──────▼────┐ ┌──▼──────┐ ┌─▼────────┐  │
│  │  WORKER   │ │ WORKER  │ │  WORKER  │  │
│  │  NODE 1   │ │ NODE 2  │ │  NODE 3  │  │
│  ├───────────┤ ├─────────┤ ├──────────┤  │
│  │ - kubelet │ │- kubelet│ │- kubelet │  │
│  │ - kube-   │ │- kube-  │ │- kube-   │  │
│  │   proxy   │ │  proxy  │ │  proxy   │  │
│  │ - Pods    │ │- Pods   │ │- Pods    │  │
│  └───────────┘ └─────────┘ └──────────┘  │
│                                            │
└────────────────────────────────────────────┘
```

**Control Plane (Master):**
- **API Server:** Kõigi API päringute vastuvõtja
- **Scheduler:** Otsustab, millisesse node'i pod läheb
- **Controller Manager:** Jälgib ja haldab klastrit
- **etcd:** Kõigi klastri andmete salvestus

**Worker Nodes:**
- **kubelet:** Agent, mis käivitab pod-e
- **kube-proxy:** Võrgu routing
- **Container runtime:** Docker või containerd

---

## 3. K3s vs Kubernetes

### 3.1. Mis on K3s?

**K3s** on **lightweight Kubernetes distributsioon** Rancher'ilt.

**Peamised erinevused:**

| Aspekt | Kubernetes (K8s) | K3s |
|--------|------------------|-----|
| **Binary size** | ~1GB | ~100MB |
| **Memory** | ~4GB+ | ~512MB |
| **Dependencies** | Palju | Minimaalsed |
| **Setup** | Keeruline | Lihtne (1 käsk) |
| **Features** | Kõik | Kõik (+ mõned ekstra) |
| **Use case** | Suur enterprise | VPS, edge, IoT |

**K3s eelised VPS-il:**
- ✅ Väike ressursivajadus (sobib 2GB RAM VPS-ile)
- ✅ Lihtne paigaldamine (1 käsk)
- ✅ Sisseehitatud load balancer (Traefik)
- ✅ Sisseehitatud storage (local-path)
- ✅ SQLite vaikimisi (ei vaja etcd)

---

## 4. K3s Paigaldamine VPS-ile

### 4.1. Eeldused

```bash
# SSH VPS-i
ssh janek@kirjakast

# Kontrolli ressursse
free -h    # Vähemalt 1GB vaba RAM
df -h      # Vähemalt 10GB vaba disk

# Kontrolli kubectl
kubectl version --client

# Kui puudub, paigalda (Peatükk 13)
```

---

### 4.2. K3s Installimine

```bash
# Paigalda K3s (single-node cluster)
curl -sfL https://get.k3s.io | sh -

# Installi käigus:
# - Paigaldab K3s binary
# - Loob systemd service
# - Käivitab K3s serveri
# - Loob kubeconfig faili /etc/rancher/k3s/k3s.yaml

# Kontrolli installimist
sudo systemctl status k3s

# Väljund:
# ● k3s.service - Lightweight Kubernetes
#      Loaded: loaded
#      Active: active (running)
```

---

### 4.3. K3s Konfigureerimine

**K3s kubeconfig:**

```bash
# K3s kubeconfig on /etc/rancher/k3s/k3s.yaml
# Aga see on ainult root-ile kättesaadav

# Kopeeri oma kasutajale
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown janek:janek ~/.kube/config

# Muuda õigusi
chmod 600 ~/.kube/config
```

---

### 4.4. K3s Testimine

```bash
# Vaata nodes
kubectl get nodes

# Väljund:
# NAME        STATUS   ROLES                  AGE   VERSION
# kirjakast   Ready    control-plane,master   2m    v1.28.x+k3s1

# Vaata pods (system)
kubectl get pods -A

# Väljund:
# NAMESPACE     NAME                                     READY   STATUS
# kube-system   local-path-provisioner-...               1/1     Running
# kube-system   coredns-...                              1/1     Running
# kube-system   metrics-server-...                       1/1     Running
# kube-system   traefik-...                              1/1     Running

# Cluster info
kubectl cluster-info

# Väljund:
# Kubernetes control plane is running at https://127.0.0.1:6443
# CoreDNS is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
# Metrics-server is running at https://127.0.0.1:6443/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy
```

✅ **K3s on paigaldatud ja töötab!**

---

## 5. kubectl Konfigureerimine

### 5.1. kubectl Autocomplete

```bash
# Bash autocomplete
echo 'source <(kubectl completion bash)' >> ~/.bashrc

# Alias
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc

# Laadi uuesti
source ~/.bashrc

# Nüüd saad kasutada:
k get pods
k get nodes
```

---

### 5.2. kubectl Config Kontekstid

```bash
# Vaata praegust konteksti
kubectl config current-context

# Väljund:
# default

# Vaata kõiki kontekste
kubectl config get-contexts

# Vaheta konteksti (kui mitu klastrit)
kubectl config use-context default
```

---

## 6. Pods

### 6.1. Mis on Pod?

**Pod** on väikseim üksus Kubernetes'es. Sisaldab 1+ konteinerit.

```
┌─────────────────┐
│      POD        │
├─────────────────┤
│  Container 1    │
│  Container 2    │  (tavaliselt 1)
└─────────────────┘
```

**Omadused:**
- Ühine IP aadress
- Ühine network namespace
- Ühine storage (volumes)
- Lühiaegne (ephemeral)

---

### 6.2. Pod Loomine (Imperatiivne)

```bash
# Käivita Nginx pod
kubectl run nginx --image=nginx:alpine

# Väljund:
# pod/nginx created

# Vaata pods
kubectl get pods

# Väljund:
# NAME    READY   STATUS    RESTARTS   AGE
# nginx   1/1     Running   0          10s

# Detailne info
kubectl describe pod nginx

# Logs
kubectl logs nginx

# Shell pod-is
kubectl exec -it nginx -- sh

# (shell-is:)
# / # hostname
# nginx
# / # exit
```

---

### 6.3. Pod Loomine (Deklaratiivne - YAML)

**Loo manifest:**

```bash
vim nginx-pod.yaml
```

Vajuta `i` ja lisa:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
```

Salvesta: `Esc`, `:wq`

**Apply:**

```bash
kubectl apply -f nginx-pod.yaml

# Väljund:
# pod/nginx created

# Kustuta
kubectl delete -f nginx-pod.yaml
```

---

### 6.4. Multi-Container Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80

  - name: logger
    image: busybox
    command: ['sh', '-c', 'while true; do echo "Logging..."; sleep 10; done']
```

**Kasutusjuhtumid:**
- Sidecar pattern (log aggregator)
- Ambassador pattern (proxy)
- Adapter pattern (data format converter)

---

## 7. Deployments

### 7.1. Mis on Deployment?

**Deployment** haldab pod-e:
- Desired state (soovitud arv replikaid)
- Rolling updates
- Rollback
- Self-healing

**Pod vs Deployment:**
- **Pod:** Käsitsi, lühiaegne
- **Deployment:** Automatiseeritud, püsiv

---

### 7.2. Deployment Loomine

```bash
# Imperatiivne
kubectl create deployment nginx --image=nginx:alpine --replicas=3

# Väljund:
# deployment.apps/nginx created

# Vaata deployments
kubectl get deployments

# Väljund:
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# nginx   3/3     3            3           20s

# Vaata pods
kubectl get pods

# Väljund:
# NAME                     READY   STATUS    RESTARTS   AGE
# nginx-7c79c4bf97-abcd    1/1     Running   0          30s
# nginx-7c79c4bf97-efgh    1/1     Running   0          30s
# nginx-7c79c4bf97-ijkl    1/1     Running   0          30s
```

---

### 7.3. Deployment YAML

```bash
vim nginx-deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
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
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

Salvesta ja apply:

```bash
kubectl apply -f nginx-deployment.yaml
```

---

### 7.4. Deployment Scaling

```bash
# Scale up
kubectl scale deployment nginx --replicas=5

# Väljund:
# deployment.apps/nginx scaled

# Kontrolli
kubectl get pods | grep nginx

# Scale down
kubectl scale deployment nginx --replicas=2
```

---

### 7.5. Rolling Update

```bash
# Uuenda image
kubectl set image deployment/nginx nginx=nginx:1.25

# Vaata rollout progress
kubectl rollout status deployment/nginx

# Väljund:
# Waiting for deployment "nginx" rollout to finish: 1 out of 3 new replicas have been updated...
# deployment "nginx" successfully rolled out

# Vaata rollout history
kubectl rollout history deployment/nginx

# Rollback eelmisele versioonile
kubectl rollout undo deployment/nginx
```

---

## 8. Services

### 8.1. Mis on Service?

**Service** on abstraktsioon, mis pakub stabiilset võrgu endpoint-i pod-idele.

**Probleem:**
- Pod-ide IP aadressid muutuvad (restart, scaling)
- Kuidas ühenduda replicatega?

**Lahendus:** Service (stabiilne DNS nimi + load balancing)

---

### 8.2. Service Tüübid

**1. ClusterIP (default):**
- Ainult klastri-sisene juurdepääs
- Stabiilne IP ja DNS

**2. NodePort:**
- Väline juurdepääs läbi node port-i
- Port range: 30000-32767

**3. LoadBalancer:**
- Väline load balancer (cloud providers)
- K3s: kasutab host IP-d

**4. ExternalName:**
- DNS CNAME alias välisele teenusele

---

### 8.3. ClusterIP Service

```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

Apply:

```bash
kubectl apply -f nginx-service.yaml

# Vaata service
kubectl get service nginx-service

# Väljund:
# NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# nginx-service   ClusterIP   10.43.123.456   <none>        80/TCP    10s

# Test (teisest pod-ist)
kubectl run test --image=busybox --rm -it --restart=Never -- wget -O- nginx-service

# Väljund: Nginx HTML
```

---

### 8.4. NodePort Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080  # valikuline
```

Apply:

```bash
kubectl apply -f nginx-nodeport.yaml

# Vaata
kubectl get service nginx-nodeport

# Väljund:
# NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# nginx-nodeport   NodePort   10.43.123.456   <none>        80:30080/TCP   10s

# Test väljastpoolt
curl http://kirjakast:30080
# Või IP-ga:
curl http://93.127.213.242:30080
```

---

## 9. Namespaces

### 9.1. Mis on Namespace?

**Namespace** on virtuaalne cluster ressursside isoleerimiseks.

**Kasutusjuhtumid:**
- **Keskkonnad:** dev, staging, production
- **Meeskonnad:** team-a, team-b
- **Projektid:** project-x, project-y

---

### 9.2. Default Namespaces

```bash
# Vaata namespaces
kubectl get namespaces

# Väljund:
# NAME              STATUS   AGE
# default           Active   1h    # Kasutaja ressursid
# kube-system       Active   1h    # Süsteemi komponendid
# kube-public       Active   1h    # Avalikud ressursid
# kube-node-lease   Active   1h    # Node heartbeats
```

---

### 9.3. Namespace Loomine

```bash
# Imperatiivne
kubectl create namespace production

# Või YAML
vim production-namespace.yaml
```

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
```

Apply:

```bash
kubectl apply -f production-namespace.yaml
```

---

### 9.4. Ressursid Namespace-is

```bash
# Loo deployment namespace-is
kubectl create deployment nginx --image=nginx:alpine -n production

# Vaata pods namespace-is
kubectl get pods -n production

# Vaata kõiki pods (kõigis namespaces)
kubectl get pods -A

# Seadista default namespace
kubectl config set-context --current --namespace=production

# Nüüd kasutab vaikimisi production
kubectl get pods  # sama kui kubectl get pods -n production
```

---

## 10. Labels ja Selectors

### 10.1. Labels

**Labels** on key-value paarid, mis on kinnitatud ressurssidele.

```yaml
metadata:
  labels:
    app: nginx
    environment: production
    version: "1.0"
```

---

### 10.2. Selectors

**Selectors** leiavad ressursse labels'i järgi.

```bash
# Vaata pods labeliga app=nginx
kubectl get pods -l app=nginx

# Mitu label-it
kubectl get pods -l app=nginx,environment=production

# Label-id välja näidates
kubectl get pods --show-labels
```

---

### 10.3. Deployment Selector

```yaml
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx  # Peab matchima selector-iga!
```

---

## 11. Harjutused

### Harjutus 16.1: K3s Paigaldamine

1. SSH VPS-i: `ssh janek@kirjakast`
2. Paigalda K3s: `curl -sfL https://get.k3s.io | sh -`
3. Seadista kubeconfig: `sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config`
4. Kontrolli: `kubectl get nodes`

---

### Harjutus 16.2: Esimene Pod

1. Käivita nginx pod: `kubectl run nginx --image=nginx:alpine`
2. Vaata: `kubectl get pods`
3. Describe: `kubectl describe pod nginx`
4. Shell: `kubectl exec -it nginx -- sh`
5. Kustuta: `kubectl delete pod nginx`

---

### Harjutus 16.3: Deployment

1. Loo deployment YAML (3 replicas)
2. Apply: `kubectl apply -f deployment.yaml`
3. Vaata pods: `kubectl get pods`
4. Scale 5-ks: `kubectl scale deployment nginx --replicas=5`
5. Update image: `kubectl set image deployment/nginx nginx=nginx:1.25`

---

### Harjutus 16.4: Service

1. Loo NodePort service
2. Apply: `kubectl apply -f service.yaml`
3. Vaata: `kubectl get service`
4. Test: `curl http://localhost:30080`

---

### Harjutus 16.5: Namespace ja Labels

1. Loo namespace: `kubectl create ns production`
2. Loo deployment production namespace-is koos labels
3. Loo service, mis kasutab label selector-eid
4. Test: `kubectl get all -n production`

---

## Kokkuvõte

Selles peatükis said:

✅ **Mõistsid Kubernetes arhitektuuri**
✅ **Paigaldasid K3s VPS-ile**
✅ **Seadistasid kubectl-i**
✅ **Lõid pod-e ja deployment-e**
✅ **Lõid service-id load balancing jaoks**
✅ **Kasutasid namespace-e ja labels-eid**

---

## Järgmine Peatükk

**Peatükk 17: PostgreSQL Kubernetes-es - MÕLEMAD VARIANDID**

Järgmises peatükis:
- StatefulSet PostgreSQL-ile (PRIMAARNE)
- ExternalName Service välise DB-ga (ALTERNATIIV)
- PersistentVolumes ja PersistentVolumeClaims
- Secrets ja ConfigMaps

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
**VPS:** kirjakast (Ubuntu 24.04 LTS)
