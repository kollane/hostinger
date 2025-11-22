# Harjutus 3: Services & Networking

**Kestus:** 60 minutit
**Eesmärk:** Õppida pod'ide võrgundust ja Service discovery't Kubernetes'es

---

## 📋 Ülevaade

Selles harjutuses õpid **Kubernetes Services** - ressurssi, mis **avaldab rakendusi** ja võimaldab pod'idel üksteist **DNS'i kaudu leida**.

**Probleem:**
- Pod IP'd on **ephemeral** (muutuvad restart'imisel)
- Deployment'idel on **mitu pod'i** - kuhu liiklus suunata?
- Kuidas frontend leiab backend'i?

**Lahendus: Service**
- **Stable DNS name** - `http://user-service:3000` (ei muutu)
- **Load balancing** - jagab liikluse pod'ide vahel
- **Service discovery** - DNS-based (automaatne)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista Service kontseptsiooni ja tüüpe
- ✅ Luua ClusterIP Service (internal)
- ✅ Luua NodePort Service (external)
- ✅ Testida Service discovery DNS'i kaudu
- ✅ Kasutada Labels ja Selectors
- ✅ Mõista load balancing'u pod'ide vahel
- ✅ Port forwarding kubectl'iga
- ✅ Debuggida Service routing probleeme

---

## 🏗️ Arhitektuur

### Pod IP'd vs Service IP

```
┌──────────────────────────────────────────────────────────────┐
│                    Ilma Service'ita                          │
│                                                              │
│  Frontend Pod (IP: 10.244.0.5) - KUI frontend restart'ib    │
│         │                         → IP muutub!              │
│         │ HTTP GET http://10.244.0.8:3000/api/users         │
│         └─────────────────────────────────┐                 │
│                                           ▼                  │
│  User Service Pod 1 (IP: 10.244.0.8) - Töötab               │
│  User Service Pod 2 (IP: 10.244.0.9) - Töötab               │
│     └─ Frontend ei tea, et on 2 pod'i - kasutab ainult 1!   │
│                                                              │
│  ❌ Probleem: Hard-coded IP'd, ei tea kõikidest pod'idest   │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                   Service'iga (Parim viis!)                  │
│                                                              │
│  Frontend Pod (IP muutub, aga ei ole tähtis)                │
│         │                                                    │
│         │ HTTP GET http://user-service:3000/api/users       │
│         │             ^^^^^^^^^^^^^^^^                       │
│         │             Service DNS nimi (ei muutu!)          │
│         └─────────────────────┐                             │
│                               ▼                              │
│           ┌──────────────────────────────────┐              │
│           │  Service: user-service           │              │
│           │  ClusterIP: 10.96.123.45         │              │
│           │  Port: 3000                      │              │
│           │  Selector: app=user-service      │              │
│           └──────────────┬───────────────────┘              │
│                          │ Load balances                     │
│           ┌──────────────┴──────────────┐                   │
│           ▼                             ▼                    │
│  User Service Pod 1          User Service Pod 2             │
│  IP: 10.244.0.8              IP: 10.244.0.9                 │
│  Label: app=user-service     Label: app=user-service        │
│                                                              │
│  ✅ Service DNS name ei muutu                                │
│  ✅ Load balancing kahe pod'i vahel                          │
│  ✅ Kui pod restart'ib → IP muutub, aga Service tracks       │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎨 Service Tüübid

### 1. ClusterIP (default, internal)
**Kasutus:** Teenuste vaheline suhtlus cluster'i sees

```
┌─────────────────────────────────────────┐
│         Kubernetes Cluster              │
│                                         │
│  Frontend Pod                           │
│       │                                 │
│       │ http://user-service:3000        │
│       ▼                                 │
│  ┌──────────────────────┐               │
│  │ Service: user-service│               │
│  │ Type: ClusterIP      │               │
│  │ IP: 10.96.x.x        │ ← Cluster internal │
│  └──────────┬───────────┘               │
│             │                           │
│             └──> User Service Pods      │
│                                         │
│  ❌ Browser'ist EI SAA ligipääsu        │
└─────────────────────────────────────────┘
```

### 2. NodePort (external access)
**Kasutus:** Browser'ist või välisest süsteemist ligipääs

```
┌─────────────────────────────────────────┐
│         Kubernetes Cluster              │
│                                         │
│  ┌──────────────────────┐               │
│  │ Service: frontend    │               │
│  │ Type: NodePort       │               │
│  │ NodePort: 30080      │ ← Avatud pordi Node'il │
│  │ Port: 80             │               │
│  └──────────┬───────────┘               │
│             │                           │
│             └──> Frontend Pods          │
│                                         │
└─────────────┬───────────────────────────┘
              │
              │ http://<node-ip>:30080
              ▼
     ┌─────────────────┐
     │  Browser / Curl │
     └─────────────────┘
```

### 3. LoadBalancer (cloud)
**Kasutus:** Cloud provider (AWS, GCP, Azure) - loob external load balancer

```
┌─────────────────────────────────────────┐
│         Cloud Provider                  │
│  ┌────────────────────────┐             │
│  │ External Load Balancer │             │
│  │ IP: 203.0.113.5        │             │
│  └──────────┬─────────────┘             │
└─────────────┼─────────────────────────────┘
              │
┌─────────────▼─────────────────────────────┐
│         Kubernetes Cluster                │
│  ┌──────────────────────┐                 │
│  │ Service: frontend    │                 │
│  │ Type: LoadBalancer   │                 │
│  └──────────┬───────────┘                 │
│             │                             │
│             └──> Frontend Pods            │
└───────────────────────────────────────────┘
```

**Lab 3'is kasutame:**
- **ClusterIP** - User Service, Todo Service, PostgreSQL (internal)
- **NodePort** - Frontend (external access browser'ist)

---

## 📝 Sammud

### Samm 1: Mõista Pod IP Probleemi (5 min)

**Experiment: Pod IP'd muutuvad**

```bash
# Harjutus 2'st on meil user-service Deployment (2 pod'i)
kubectl get pods -l app=user-service -o wide

# Output:
# NAME                            READY   STATUS    IP             NODE
# user-service-7d4f8c9b6d-abc     1/1     Running   10.244.0.8     minikube
# user-service-7d4f8c9b6d-def     1/1     Running   10.244.0.9     minikube

# Kustuta üks pod
kubectl delete pod user-service-7d4f8c9b6d-abc

# Kontrolli uuesti (uus pod, UUS IP!)
kubectl get pods -l app=user-service -o wide

# Output:
# NAME                            READY   STATUS    IP             NODE
# user-service-7d4f8c9b6d-def     1/1     Running   10.244.0.9     minikube
# user-service-7d4f8c9b6d-xyz     1/1     Running   10.244.0.15    minikube  ← UUS IP!
```

**Probleem:**
- Frontend ei saa kasutada hard-coded IP'd `10.244.0.8`
- IP muutub restart'imisel
- 2 pod'i - kuidas frontend teab mõlemast?

**Lahendus: Service!**

---

### Samm 2: Loo ClusterIP Service - User Service (10 min)

**ClusterIP** = Internal service (ainult cluster'i sees kättesaadav).

Loo fail `user-service-svc.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service  # DNS nimi - http://user-service:3000
  labels:
    app: user-service
spec:
  type: ClusterIP  # Default (võib ära jätta)
  selector:
    app: user-service  # Leiad pod'id, millel see label
  ports:
  - name: http
    protocol: TCP
    port: 3000        # Service port (mida teised kasutavad)
    targetPort: 3000  # Pod port (kus rakendus kuulab)
```

**YAML selgitus:**

```yaml
metadata:
  name: user-service     # DNS nimi - pod'id saavad kasutada http://user-service:3000

spec:
  type: ClusterIP        # Internal service (default)

  selector:              # Kuidas leida pod'id
    app: user-service    # Kõik pod'id, millel label app=user-service

  ports:
  - port: 3000           # Service avaldab port'i 3000
    targetPort: 3000     # Edastab pod'i port'i 3000
```

**Deploy:**

```bash
# Apply Service
kubectl apply -f user-service-svc.yaml

# Output:
# service/user-service created

# Kontrolli Service'i
kubectl get services

# Output:
# NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
# kubernetes     ClusterIP   10.96.0.1       <none>        443/TCP    1h
# user-service   ClusterIP   10.96.123.45    <none>        3000/TCP   10s
#                            ^^^^^^^^^^^^
#                            Cluster internal IP (stable!)

# Describe Service
kubectl describe service user-service

# Output:
# Name:              user-service
# Namespace:         default
# Labels:            app=user-service
# Selector:          app=user-service
# Type:              ClusterIP
# IP Family Policy:  SingleStack
# IP Families:       IPv4
# IP:                10.96.123.45
# IPs:               10.96.123.45
# Port:              http  3000/TCP
# TargetPort:        3000/TCP
# Endpoints:         10.244.0.8:3000,10.244.0.9:3000  ← Pod IP'd!
#                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                    Service tracks pod'e automaatselt

# Kontrolli Endpoints
kubectl get endpoints user-service

# Output:
# NAME           ENDPOINTS                      AGE
# user-service   10.244.0.8:3000,10.244.0.9:3000   1m
```

**Mõisted:**
- **ClusterIP:** Service IP (stable, ei muutu)
- **Selector:** Label query pod'ide leidmiseks
- **Endpoints:** Pod IP:port list (dünaamiline, muutub pod'ide lisandumisel/eemaldamisel)

---

### Samm 3: Testi Service Discovery (10 min)

**Service DNS:** Kubernetes loob automaatselt DNS kirje igale Service'ile.

**DNS formaat:**
- **Same namespace:** `<service-name>` (nt. `user-service`)
- **Cross namespace:** `<service-name>.<namespace>` (nt. `user-service.default`)
- **FQDN:** `<service-name>.<namespace>.svc.cluster.local`

**Test 1: DNS resolution**

```bash
# Loo test Pod (busybox)
kubectl run test-pod --image=busybox:1.35 --rm -it --restart=Never -- sh

# Oled nüüd test-pod'i sees:
/ #

# Test DNS lookup
/ # nslookup user-service

# Output:
# Server:		10.96.0.10  (CoreDNS)
# Address:	10.96.0.10:53
#
# Name:	user-service.default.svc.cluster.local
# Address: 10.96.123.45  ← Service ClusterIP

/ # nslookup user-service.default

# Output:
# Name:	user-service.default.svc.cluster.local
# Address: 10.96.123.45

/ # nslookup user-service.default.svc.cluster.local

# Output sama
```

**Test 2: HTTP request**

```bash
# Test-pod'i sees (busybox ei ole curl, kasuta wget)
/ # wget -O- http://user-service:3000/health

# Output (user-service API response):
# Connecting to user-service:3000 (10.96.123.45:3000)
# writing to stdout
# {
#   "status": "ERROR",
#   "database": "disconnected"
# }
# (DB pole veel, see on OK)

/ # exit  # Välja test-pod'ist (pod kustutatakse)
```

**Test 3: curl pod'ist**

```bash
# Alternatiiv: kasuta curlimages/curl (on curl!)
kubectl run curl-pod --image=curlimages/curl:8.1.2 --rm -it --restart=Never -- sh

# Pod'i sees:
~ $ curl http://user-service:3000/health

# Output:
# {"status":"ERROR","database":"disconnected",...}

~ $ curl -s http://user-service:3000/health | head -c 100

# Output (first 100 chars):
# {"status":"ERROR","database":"disconnected","message":"getaddrinfo ENOTFOUND postgres-user"}

~ $ exit
```

**✅ Service Discovery töötab! Pod'id leiavad üksteist DNS nime järgi.**

---

### Samm 4: Loo ClusterIP Service - Todo Service (5 min)

Loo teine ClusterIP service todo-service'le.

Loo fail `todo-service-svc.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: todo-service
  labels:
    app: todo-service
spec:
  type: ClusterIP
  selector:
    app: todo-service  # Match'ib Harjutus 2's loodud Deployment'iga
  ports:
  - name: http
    protocol: TCP
    port: 8081
    targetPort: 8081
```

**Deploy:**

```bash
kubectl apply -f todo-service-svc.yaml

# Kontrolli
kubectl get services

# Output:
# NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
# kubernetes     ClusterIP   10.96.0.1       <none>        443/TCP    1h
# user-service   ClusterIP   10.96.123.45    <none>        3000/TCP   10m
# todo-service   ClusterIP   10.96.123.46    <none>        8081/TCP   5s

# Kontrolli Endpoints
kubectl get endpoints todo-service

# Output:
# NAME           ENDPOINTS                       AGE
# todo-service   10.244.0.10:8081,10.244.0.11:8081  10s
#                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                2 pod'i (Harjutus 2: replicas=2)
```

**Testi:**

```bash
# curl pod
kubectl run curl-pod --image=curlimages/curl:8.1.2 --rm -it --restart=Never -- sh

~ $ curl http://todo-service:8081/actuator/health

# Output (Spring Boot Actuator):
# {"status":"DOWN","components":{"db":{"status":"DOWN","details":{"error":"org.postgresql.util.PSQLException: Connection to postgres-todo:5432 refused"}},...}}
# (DB pole veel, aga Service DNS töötab!)

~ $ exit
```

---

### Samm 5: Loo NodePort Service - Frontend (10 min)

**NodePort** = Avaldab Service'i **väljaspool cluster'it** (browser'ist kättesaadav).

**Minikube IP:**

```bash
# Minikube cluster IP
minikube ip

# Output:
# 192.168.49.2

# K3s kasutab host machine IP'd
```

Esmalt: Loo frontend Deployment (kui pole veel):

```bash
# Lae frontend image cluster'isse
# Minikube:
eval $(minikube docker-env)
cd ../../apps/frontend
docker build -t frontend:1.0 .
cd -
eval $(minikube docker-env -u)

# K3s:
cd ../../apps/frontend
docker build -t frontend:1.0 .
docker save frontend:1.0 -o /tmp/frontend.tar
sudo k3s ctr images import /tmp/frontend.tar
cd -
```

Loo `frontend-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tier: frontend
    spec:
      containers:
      - name: frontend
        image: frontend:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 80
          name: http
```

**Deploy Deployment:**

```bash
kubectl apply -f frontend-deployment.yaml

# Kontrolli
kubectl get deployments
kubectl get pods -l app=frontend
```

**Loo NodePort Service:**

Loo fail `frontend-svc.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  type: NodePort  # Avaldab väljapoole
  selector:
    app: frontend
  ports:
  - name: http
    protocol: TCP
    port: 80         # Service port
    targetPort: 80   # Pod port
    nodePort: 30080  # Node port (30000-32767 range)
                     # Kui ei määra, Kubernetes valib random'i
```

**Deploy:**

```bash
kubectl apply -f frontend-svc.yaml

# Kontrolli
kubectl get services

# Output:
# NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# frontend       NodePort    10.96.123.50    <none>        80:30080/TCP   10s
#                                                           ^^^^^^^^^^^^
#                                                           Port:NodePort

# Minikube: Ava browser'is
minikube service frontend --url

# Output:
# http://192.168.49.2:30080

# Test curl'iga
curl http://$(minikube ip):30080

# Output: HTML page (frontend)

# K3s: Kasuta host machine IP'd
curl http://localhost:30080
# või
curl http://93.127.213.242:30080
```

**Browser test:**

```
http://192.168.49.2:30080  (Minikube)
http://localhost:30080     (K3s)
```

✅ **Frontend kättesaadav browser'ist!**

---

### Samm 6: Load Balancing Test (10 min)

Service **jagab liikluse pod'ide vahel** (round-robin või random).

**Experiment:**

```bash
# user-service'il on 2 pod'i
kubectl get pods -l app=user-service

# Output:
# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-7d4f8c9b6d-abc     1/1     Running   0          20m
# user-service-7d4f8c9b6d-def     1/1     Running   0          20m

# Tee mitu request'i Service'ile
kubectl run curl-pod --image=curlimages/curl:8.1.2 --rm -it --restart=Never -- sh

~ $ for i in $(seq 1 10); do
    curl -s http://user-service:3000/health | head -c 50
    echo ""
  done

# Output (10 request'i):
# {"status":"ERROR","database":"disconnected",...
# {"status":"ERROR","database":"disconnected",...
# ...

# Vaata pod logisid (näed, et liiklus jaotub)
exit

# Terminal 1: User Service Pod 1 logid
kubectl logs -f user-service-7d4f8c9b6d-abc

# Terminal 2: User Service Pod 2 logid
kubectl logs -f user-service-7d4f8c9b6d-def

# Terminal 3: Tee request'id
kubectl run curl-pod --image=curlimages/curl:8.1.2 --rm -it --restart=Never -- sh
~ $ for i in $(seq 1 20); do curl http://user-service:3000/health; sleep 0.5; done

# Terminal 1 ja 2 näitavad logisid vaheldumisi (load balancing!)
```

---

### Samm 7: Port Forwarding kubectl'iga (5 min)

**Port forwarding** = map local port → Service/Pod port (debugging jaoks).

```bash
# Port forward Service'i
kubectl port-forward svc/user-service 8080:3000

# Output:
# Forwarding from 127.0.0.1:8080 -> 3000
# Forwarding from [::1]:8080 -> 3000

# Teises terminalis:
curl http://localhost:8080/health

# Output:
# {"status":"ERROR","database":"disconnected"}

# Peata: Ctrl+C

# Port forward pod'i (konkreetne pod)
kubectl port-forward pod/user-service-7d4f8c9b6d-abc 8080:3000

# Background'is (Lisa &)
kubectl port-forward svc/user-service 8080:3000 &

# Hiljem peata:
pkill -f "port-forward"
```

**Millal kasutada:**
- Local development (frontend dev → K8s backend)
- Debugging (access internal service)
- Database access (psql → PostgreSQL pod)

---

### Samm 8: Service Selectors ja Labels (5 min)

**Service leiad pod'id label selector'iga.**

**Experiment: Vale selector**

```bash
# Loo Service valesti selector'iga
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: test-service
spec:
  selector:
    app: nonexistent-app  # Vale label - ühtegi pod'i ei match'i
  ports:
  - port: 3000
    targetPort: 3000
EOF

# Kontrolli Endpoints
kubectl get endpoints test-service

# Output:
# NAME           ENDPOINTS   AGE
# test-service   <none>      5s
#                ^^^^^^ Tühi! Ei leidnud pod'e

# Paranda selector
kubectl patch service test-service -p '{"spec":{"selector":{"app":"user-service"}}}'

# Kontrolli uuesti
kubectl get endpoints test-service

# Output:
# NAME           ENDPOINTS                       AGE
# test-service   10.244.0.8:3000,10.244.0.9:3000  1m

# Kustuta test
kubectl delete service test-service
```

---

### Samm 9: Service Without Selector (Täiustatud) (5 min)

**Täiustatud:** Service ilma selector'ita (manual endpoints).

**Kasutus:** External service (nt. välisandmebaas, legacy system).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  ports:
  - port: 5432
    targetPort: 5432
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-db  # Sama nimi nagu Service
subsets:
- addresses:
  - ip: 192.168.1.100  # External DB IP
  ports:
  - port: 5432
```

**Lab 3'is ei kasuta** (õpime Harjutus 5'is external DB alternative'i).

---

### Samm 10: Cleanup (5 min)

**NB:** Ära kustuta Services'eid - vajame neid järgmistes harjutustes!

```bash
# Vaata Services'eid
kubectl get services

# Output:
# NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# kubernetes     ClusterIP   10.96.0.1       <none>        443/TCP        2h
# user-service   ClusterIP   10.96.123.45    <none>        3000/TCP       30m
# todo-service   ClusterIP   10.96.123.46    <none>        8081/TCP       20m
# frontend       NodePort    10.96.123.50    <none>        80:30080/TCP   10m

# Kui vaja kustutada:
# kubectl delete service user-service
# kubectl delete service todo-service
# kubectl delete service frontend

# Või kõik korraga:
# kubectl delete services --all  (ETTEVAATUST - kustutab ka kubernetes service!)
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Services:**
  - [ ] `user-service` ClusterIP (port 3000)
  - [ ] `todo-service` ClusterIP (port 8081)
  - [ ] `frontend` NodePort (port 80 → 30080)

- [ ] **Endpoints:**
  - [ ] `user-service` - 2 pod'i IP'd
  - [ ] `todo-service` - 2 pod'i IP'd
  - [ ] `frontend` - 1 pod'i IP

- [ ] **DNS toimib:**
  - [ ] `http://user-service:3000` kättesaadav cluster'i sees
  - [ ] `http://todo-service:8081` kättesaadav cluster'i sees
  - [ ] `http://<node-ip>:30080` kättesaadav browser'ist

- [ ] **Oskused:**
  - [ ] Loo ClusterIP ja NodePort Services
  - [ ] Test Service discovery DNS'i kaudu
  - [ ] Mõista Endpoints'e
  - [ ] Kasuta port forwarding'u

**Kontrolli:**

```bash
kubectl get services
kubectl get endpoints
kubectl run curl-pod --image=curlimages/curl:8.1.2 --rm -it --restart=Never -- curl http://user-service:3000/health
curl http://$(minikube ip):30080  # või http://localhost:30080 (K3s)
```

---

## 🐛 Troubleshooting

### Probleem 1: Endpoints on tühi

**Sümptom:**
```bash
kubectl get endpoints user-service
# NAME           ENDPOINTS   AGE
# user-service   <none>      2m
```

**Põhjus:** Selector ei match'i pod'ide label'eid.

**Diagnoos:**

```bash
# Kontrolli Service selector'it
kubectl describe service user-service | grep Selector
# Selector:  app=user-service

# Kontrolli pod'ide label'eid
kubectl get pods -l app=user-service --show-labels

# Kui tühi - labels ei match'i!
```

**Lahendus:**

```bash
# Deployment YAML'is:
# spec.template.metadata.labels PEAB match'ima Service selector'iga

# Service:
#   selector:
#     app: user-service
#
# Deployment:
#   template:
#     metadata:
#       labels:
#         app: user-service  ← PEAB olema sama!
```

---

### Probleem 2: DNS ei tööta

**Sümptom:**
```bash
kubectl run curl-pod --image=curlimages/curl:8.1.2 --rm -it -- curl http://user-service:3000
# curl: (6) Could not resolve host: user-service
```

**Põhjus:** CoreDNS ei tööta või pod ei kasuta CoreDNS'i.

**Diagnoos:**

```bash
# Kontrolli CoreDNS pod'e
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Output peaks näitama:
# NAME                       READY   STATUS    RESTARTS   AGE
# coredns-xxx                1/1     Running   0          2h

# Kui CrashLoopBackOff:
kubectl logs -n kube-system coredns-xxx
```

**Lahendus:**

```bash
# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# Test DNS pod'ist
kubectl run test-pod --image=busybox:1.35 --rm -it -- nslookup user-service
```

---

### Probleem 3: NodePort ei ole kättesaadav

**Sümptom:**
```bash
curl http://$(minikube ip):30080
# curl: (7) Failed to connect to 192.168.49.2 port 30080: Connection refused
```

**Põhjus:** Service ei ole NodePort või pod'id ei ole Ready.

**Diagnoos:**

```bash
# Kontrolli Service type
kubectl get service frontend
# TYPE peaks olema NodePort

# Kontrolli pod'e
kubectl get pods -l app=frontend
# READY peaks olema 1/1, STATUS Running

# Kontrolli Endpoints
kubectl get endpoints frontend
# Ei tohi olla <none>
```

**Lahendus:**

```bash
# Kui pod ei ole Running:
kubectl describe pod <frontend-pod>

# Kui Service type vale:
kubectl delete service frontend
kubectl apply -f frontend-svc.yaml  # type: NodePort

# Minikube: Võib vajada tunnel'it
minikube tunnel  # Eraldi terminalis
```

---

## 🎓 Õpitud Mõisted

### Service Kontseptsioonid
- **Service:** Stable network endpoint pod'idele
- **ClusterIP:** Internal service (cluster'i sees)
- **NodePort:** External access (Node IP:NodePort)
- **LoadBalancer:** Cloud provider external LB (Lab 3'is ei kasuta)
- **DNS:** `<service-name>.<namespace>.svc.cluster.local`
- **Selector:** Label query pod'ide leidmiseks
- **Endpoints:** Pod IP:port list (dünaamiline)

### Service Discovery
- **CoreDNS:** Kubernetes DNS server
- **Service DNS:** `http://user-service:3000` (short name)
- **Cross-namespace:** `http://user-service.default:3000`
- **FQDN:** `http://user-service.default.svc.cluster.local:3000`

### Load Balancing
- **Round-robin / Random:** Liiklus jaotub pod'ide vahel
- **Session affinity:** `sessionAffinity: ClientIP` (sticky sessions)

### kubectl Service Käsud
- `kubectl get services` / `kubectl get svc` - Listi Services
- `kubectl get endpoints` / `kubectl get ep` - Vaata Endpoints'e
- `kubectl describe service <name>` - Detailne info
- `kubectl port-forward svc/<name> 8080:3000` - Port forwarding
- `kubectl delete service <name>` - Kustuta Service

---

## 💡 Parimad Tavad

### ✅ DO (Tee):
1. **Kasuta ClusterIP internal'idele** - User Service, Todo Service, DB
2. **Kasuta NodePort development'is** - Frontend (browser test)
3. **Kasuta LoadBalancer production'is (cloud)** - External access
4. **Nimeta port'e** - `name: http`, `name: metrics` (hea dokumentatsiooniks)
5. **Kasuta Service DNS nimesid** - `http://user-service:3000` (mitte IP'd!)
6. **Kontrolli Endpoints'e** - Veendu, et pod'id attached

### ❌ DON'T (Ära tee):
1. **Ära kasuta hard-coded pod IP'sid** - Kasuta Service DNS'i
2. **Ära unusta selector'it** - Service ei leia pod'e
3. **Ära kasuta NodePort production'is** - Ebaturvaline, kasuta LoadBalancer
4. **Ära määra nodePort: 80** - Privileged port, kasuta 30000-32767

---

## 🔗 Järgmine Samm

Nüüd on meil töötav võrgundus:
- Frontend → User Service (`http://user-service:3000`)
- Frontend → Todo Service (`http://todo-service:8081`)
- Browser → Frontend (`http://<node-ip>:30080`)

**Probleem:** Environment variables on hard-coded YAML'is:
```yaml
env:
- name: DB_PASSWORD
  value: "postgres"  # ❌ Ebaturvaline!
```

**Lahendus:** **ConfigMaps** (non-sensitive) ja **Secrets** (sensitive).

**Järgmises harjutuses loome:**
- ConfigMap user-service jaoks (PORT, NODE_ENV, DB_HOST...)
- Secret DB paroolide jaoks (DB_PASSWORD)
- Secret JWT key jaoks (JWT_SECRET)

---

**Jätka:** [Harjutus 4: Configuration Management](04-configuration-management.md)

---

## 📚 Viited

**Kubernetes Dokumentatsioon:**
- [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Service Types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)
- [Connecting Applications with Services](https://kubernetes.io/docs/tutorials/services/connect-applications-service/)

---

**Õnnitleme! Oled loonud Kubernetes Services ja mõistad Service Discovery't! 🎉**

*Järgmises harjutuses liigume ConfigMaps ja Secrets juurde - kuidas hallata konfiguratsioone turvaliselt!*
