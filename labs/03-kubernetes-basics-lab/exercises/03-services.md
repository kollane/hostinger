# Harjutus 3: Kubernetes Services

**Kestus:** 60 minutit
**Eesmärk:** Õppida Service'idega rakenduste avaldamist ja Service Discovery't

---

## 📋 Ülevaade

Selles harjutuses õpid kasutama **Kubernetes Services** - mehhanism pod'ide võrku avaldamiseks. Service annab püsiva IP aadressi ja DNS nime deployment'ile, isegi kui pod'id pöörduvad vaheldumisi (rolling update, scaling, crashid).

**Miks Service vajalik?**
- Pod'ide IP-d muutuvad (pod restart, rolling update)
- Service annab püsiva endpoint'i
- Load balancing mitme pod'i vahel
- Service discovery DNS'iga

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua ClusterIP Service (internal)
- ✅ Luua NodePort Service (external)
- ✅ Mõista LoadBalancer Service't
- ✅ Kasutada Labels ja Selectors
- ✅ Testida Service discovery (DNS)
- ✅ Port forward'ida kubectl'iga
- ✅ Debuggida Service routing'u

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────────────────────────┐
│           Kubernetes Cluster                    │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Service: user-service (ClusterIP)      │   │
│  │  IP: 10.96.0.100 (cluster internal)     │   │
│  │  DNS: user-service.default.svc.cluster  │   │
│  └────────────────┬────────────────────────┘   │
│                   │ Load Balancing             │
│         ┌─────────┼─────────┐                  │
│         ▼         ▼         ▼                  │
│      ┌────┐   ┌────┐    ┌────┐                │
│      │Pod │   │Pod │    │Pod │                │
│      │ 1  │   │ 2  │    │ 3  │                │
│      └────┘   └────┘    └────┘                │
│      (labels: app=user-service)                │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Service: frontend (NodePort)           │   │
│  │  ClusterIP: 10.96.0.101                 │   │
│  │  NodePort: 30080                        │   │
│  └────────────────┬────────────────────────┘   │
│                   ▼                            │
│                ┌────┐                          │
│                │Pod │                          │
│                └────┘                          │
│                                                 │
└─────────────────────────────────────────────────┘
         │
         │ External access
         ▼
    Node IP:30080
```

---

## 📝 Sammud

### Samm 1: ClusterIP Service (15 min)

**ClusterIP** on default Service tüüp - internal IP, kättesaadav ainult cluster'is.

**Eeldus:** user-service Deployment peab olema deploy'tud (Harjutus 2).

```bash
# Kontrolli Deployment'i
kubectl get deployments

# Kui puudub, deploy:
kubectl apply -f ../02-deployments/user-deployment.yaml
```

Loo fail `user-service-clusterip.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  type: ClusterIP  # Default (võib välja jätta)
  selector:
    app: user-service  # Ühendub pod'idega, kellel see label
  ports:
  - name: http
    port: 80        # Service port (cluster sees)
    targetPort: 3000  # Container port pod'is
    protocol: TCP
```

**Manifest selgitus:**
- **selector:** Label, mis ühendab Service pod'idega
- **port:** Service port (teised pod'id kasutavad seda)
- **targetPort:** Container port pod'is (kust Service route'ib)

**Deploy:**

```bash
kubectl apply -f user-service-clusterip.yaml

# Kontrolli
kubectl get services
# või lühidalt:
kubectl get svc

# NAME           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# kubernetes     ClusterIP   10.96.0.1       <none>        443/TCP   1d
# user-service   ClusterIP   10.96.0.100     <none>        80/TCP    5s
```

**Kontrolli Endpoints:**

Service route'ib liiklust pod'idele. Endpoints on pod'ide IP'd.

```bash
kubectl get endpoints user-service

# NAME           ENDPOINTS                           AGE
# user-service   172.17.0.3:3000,172.17.0.4:3000     10s

# Peaks näitama pod'ide IP'sid ja porte
```

**Testi Service't cluster'ist:**

```bash
# Sisene test pod'i
kubectl run test-pod --image=alpine --rm -it -- sh

# Pod sees:
apk add curl

# Testi Service't IP'ga
curl http://10.96.0.100/health

# Testi Service't DNS'iga
curl http://user-service/health
curl http://user-service.default.svc.cluster.local/health

# Peaks vastama:
# {
#   "status": "ERROR",
#   "database": "disconnected"
# }

exit
```

**DNS Service Discovery:**
Kubernetes loob automaatselt DNS kirje:
- `user-service` (sama namespace)
- `user-service.default` (täpsem)
- `user-service.default.svc.cluster.local` (FQDN)

---

### Samm 2: NodePort Service (15 min)

**NodePort** avaldab Service'i väliselt Node IP + port'i kaudu.

Loo fail `frontend-nodeport.yaml`:

Esmalt deploy frontend Deployment (kui pole):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: frontend:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 8080
```

```bash
# Deploy Frontend (kui pole)
kubectl apply -f frontend-deployment.yaml
```

**Loo NodePort Service:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - name: http
    port: 80          # Service port
    targetPort: 8080  # Container port
    nodePort: 30080   # External port (30000-32767 vahel)
    protocol: TCP
```

**Deploy:**

```bash
kubectl apply -f frontend-nodeport.yaml

# Kontrolli
kubectl get svc frontend

# NAME       TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
# frontend   NodePort   10.96.0.101    <none>        80:30080/TCP   5s
```

**Testi NodePort'i:**

```bash
# Minikube: Hangi URL
minikube service frontend --url

# Peaks tagastama: http://192.168.49.2:30080

# Ava brauseris või curl
curl http://$(minikube ip):30080

# K3s: Kasuta node IP
curl http://localhost:30080
```

**Kuidas NodePort toimib:**
1. Liiklus tuleb Node IP:30080
2. Suunatakse Service ClusterIP:80
3. Service suunab pod'i targetPort'i 8080

---

### Samm 3: LoadBalancer Service (Minikube) (10 min)

**LoadBalancer** loob välise load balancer'i (cloud'is AWS/GCP/Azure). Minikube'is saame simuleerida `minikube tunnel`'iga.

Loo fail `frontend-loadbalancer.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-lb
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - name: http
    port: 80
    targetPort: 8080
    protocol: TCP
```

**Deploy:**

```bash
kubectl apply -f frontend-loadbalancer.yaml

# Kontrolli
kubectl get svc frontend-lb

# NAME          TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# frontend-lb   LoadBalancer   10.96.0.102     <pending>     80:31234/TCP   5s

# EXTERNAL-IP on <pending> - Minikube vajab tunnel'it
```

**Minikube: Loo tunnel (teine terminal):**

```bash
minikube tunnel

# Jätab töötama - hoidke terminal avatud
```

**Kontrolli uuesti:**

```bash
kubectl get svc frontend-lb

# NAME          TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
# frontend-lb   LoadBalancer   10.96.0.102     10.96.0.102     80:31234/TCP   1m

# EXTERNAL-IP on nüüd määratud
```

**Testi:**

```bash
curl http://10.96.0.102
```

**Märkus:** Production'is (AWS, GCP) saad avaliku IP ja real load balancer.

---

### Samm 4: Testi Service Discovery (10 min)

Loon deployment'i, mis kasutab `user-service` Service't.

Loo fail `client-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: client-pod
spec:
  containers:
  - name: alpine
    image: alpine
    command: ["sleep", "3600"]
```

**Deploy ja testi:**

```bash
kubectl apply -f client-pod.yaml

# Sisene pod'i
kubectl exec -it client-pod -- sh

# Pod sees:
apk add curl

# Testi DNS service discovery
curl http://user-service/health

# Peaks töötama! Service discovery via DNS

# Testi teise namespace'i Service't (kui oleks)
# curl http://service-name.namespace-name.svc.cluster.local

exit
```

**DNS resolutsion:**
```bash
# Pod sees:
nslookup user-service

# Peaks näitama:
# Name:   user-service.default.svc.cluster.local
# Address: 10.96.0.100
```

---

### Samm 5: Multi-Port Service (5 min)

Service võib avaldada mitut porti.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: multi-port-service
spec:
  selector:
    app: my-app
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443
  - name: metrics
    port: 9090
    targetPort: 9090
```

**Märkus:** Iga port peab omama unikaalse `name`.

---

### Samm 6: Headless Service (5 min)

**Headless Service** ei anna ClusterIP'd - DNS tagastab otse pod'ide IP'd. Kasulik StatefulSet'iga.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: headless-service
spec:
  clusterIP: None  # Headless
  selector:
    app: user-service
  ports:
  - port: 80
    targetPort: 3000
```

**Testi:**

```bash
kubectl apply -f headless-service.yaml

# DNS lookup
kubectl run test --image=alpine --rm -it -- sh
nslookup headless-service

# Peaks tagastama mitut A-kirjet (pod'ide IP'd)
# Name:   headless-service.default.svc.cluster.local
# Address: 172.17.0.3
# Address: 172.17.0.4
```

---

### Samm 7: Port Forwarding (5 min)

Kui ei taha NodePort'i või Service't luua, kasuta `port-forward`.

```bash
# Forward local port 8080 → Service user-service port 80
kubectl port-forward service/user-service 8080:80

# Või otse pod'ile
kubectl port-forward pod/user-service-xxxxxxxxx-xxxxx 8080:3000

# Teises terminalis:
curl http://localhost:8080/health
```

**Kasutatakse:**
- Kiire local testing
- Debugging
- Ei sobi production'i (ainult üks pod)

---

### Samm 8: Service Debugging (5 min)

```bash
# Kontrolli Service't
kubectl get svc user-service

# Detailne info
kubectl describe svc user-service

# Tähtis info:
# - Selector: app=user-service
# - Endpoints: 172.17.0.3:3000, 172.17.0.4:3000
# - Port mappings

# Kontrolli Endpoints (kas pod'id on ühendatud?)
kubectl get endpoints user-service

# Kui Endpoints on tühi:
# - Kontrolli selector'it (kas matchib pod label'itega?)
kubectl get pods --show-labels
kubectl get svc user-service -o yaml | grep selector

# - Kontrolli, kas pod'id on READY
kubectl get pods
```

**Service ei tööta?**

1. **Endpoints tühi:**
   - Selector ei matchi pod'ide label'itega
   - Pod'id pole READY (readiness probe failib)

2. **Connection refused:**
   - targetPort on vale
   - Container ei kuula õigel pordil

3. **Timeout:**
   - Network policy blokeerib
   - Firewall issues

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **ClusterIP Service:**
  - [ ] Loodud ja kättesaadav cluster'is
  - [ ] DNS service discovery toimib

- [ ] **NodePort Service:**
  - [ ] Loodud ja kättesaadav Node IP:port kaudu

- [ ] **LoadBalancer Service (Minikube):**
  - [ ] minikube tunnel käivitatud
  - [ ] External IP määratud

- [ ] **Service Discovery:**
  - [ ] Testi DNS resolution'd
  - [ ] Pod'id saavad omavahel ühendust Service'i kaudu

- [ ] **Debugging:**
  - [ ] `kubectl get endpoints`
  - [ ] `kubectl describe svc`
  - [ ] Port forwarding

---

## 🐛 Troubleshooting

### Probleem 1: Endpoints on tühjad

**Sümptom:**
```bash
kubectl get endpoints user-service
# NAME           ENDPOINTS   AGE
# user-service   <none>      1m
```

**Diagnoos:**

```bash
# Kontrolli Service selector'it
kubectl get svc user-service -o yaml | grep -A 2 selector

# selector:
#   app: user-service

# Kontrolli pod'ide label'eid
kubectl get pods --show-labels | grep user-service

# Kas label matchib?
```

**Lahendus:**
Muuda Service selector'it või pod'i label'eid, et nad matchiks.

---

### Probleem 2: Connection refused

**Sümptom:**
```bash
curl http://user-service/health
# curl: (7) Failed to connect to user-service port 80: Connection refused
```

**Diagnoos:**

```bash
# Kontrolli targetPort'i
kubectl get svc user-service -o yaml | grep targetPort

# targetPort: 3000

# Kontrolli, kas container kuulab pordil 3000
kubectl exec -it user-service-xxxxxxxxx-xxxxx -- netstat -tuln | grep 3000

# Või testi otse pod'i
kubectl port-forward pod/user-service-xxxxxxxxx-xxxxx 8080:3000
curl http://localhost:8080/health
```

**Lahendus:**
Muuda Service `targetPort` õigeks.

---

### Probleem 3: DNS ei tööta

**Sümptom:**
```bash
# Pod sees:
curl http://user-service
# curl: (6) Could not resolve host: user-service
```

**Diagnoos:**

```bash
# Kontrolli DNS
kubectl get svc -n kube-system | grep dns

# kube-dns peaks olema Running

# Pod sees:
cat /etc/resolv.conf

# Peaks näitama:
# nameserver 10.96.0.10
# search default.svc.cluster.local svc.cluster.local cluster.local

nslookup user-service
```

**Lahendus:**
Restart coredns:
```bash
kubectl rollout restart deployment/coredns -n kube-system
```

---

## 🎓 Õpitud Mõisted

### Service tüübid:
- **ClusterIP:** Internal IP, kättesaadav ainult cluster'is (default)
- **NodePort:** Avaldab Service Node IP + port kaudu (30000-32767)
- **LoadBalancer:** Loob välise load balancer'i (cloud)
- **ExternalName:** DNS CNAME alias välisele service'ile
- **Headless:** clusterIP: None - DNS tagastab pod'ide IP'd

### Service Discovery:
- **DNS:** Service name → ClusterIP (nt `user-service` → `10.96.0.100`)
- **Environment Variables:** Kubernetes lisab Service info pod'i env'i
- **FQDN:** `service-name.namespace.svc.cluster.local`

### Muud:
- **Selector:** Label query, mis ühendab Service pod'idega
- **Endpoints:** Pod'ide IP'd, millele Service route'ib
- **Port mapping:** port (Service) → targetPort (Container)

---

## 💡 Parimad Tavad

1. **Kasuta ClusterIP internal comm'i jaoks** - NodePort/LoadBalancer ainult external access
2. **Anna Service'idele mõistlikud nimed** - DNS friendly (lowercase, hyphens)
3. **Määra port names** - Eriti multi-port Service'i korral
4. **Kontrolli Endpoints** - Alati peale Service loomist
5. **Kasuta selector'eid õigesti** - Match pod label'itega
6. **Headless Service StatefulSet'iga** - Kui vajad pod'ide individuaalseid IP'sid
7. **Port forward debugging'uks** - Mitte production'i

---

## 🔗 Järgmine Samm

Nüüd oskad avaldada deployment'e Service'idega! Aga kuidas hallata konfiguratsioone (env variables, secrets)?

Järgmises harjutuses õpid **ConfigMaps ja Secrets**!

**Jätka:** [Harjutus 4: ConfigMaps & Secrets](04-configmaps-secrets.md)

---

## 📚 Viited

- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Service Discovery](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [Service Types](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)

---

**Õnnitleme! Oskad nüüd avaldada rakendusi Kubernetes Services'iga! 🌐**
