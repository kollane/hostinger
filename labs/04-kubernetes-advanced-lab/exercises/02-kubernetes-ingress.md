# Harjutus 02: Kubernetes Ingress

**Kestus:** 90 minutit
**Tee:** Path A ja Path B (mõlemad)
**Eelmata:** Path A jaoks - Harjutus 01 (DNS + Nginx) läbitud
**Eesmärk:** Paigaldada Kubernetes Ingress Controller ja luua Ingress ressursid mikroteenuste routing'uks

---

## 📋 Ülevaade

Selles harjutuses õpid kaasaegset cloud-native viisi liikluse suunamiseks Kubernetes klastris. Ingress Controller on Kubernetes'e natiivne reverse proxy lahendus, mis pakub sama funktsionaalsust kui Nginx (harjutus 01), kuid täielikult integreeritud Kubernetes API-ga.

**Arhitektuur, mida loome:**

```
Internet
    ↓
Ingress Controller (Nginx Ingress pod)
    ↓
Ingress Resource (routing reeglid YAML'is)
    ↓
Kubernetes Services
    ↓
    ├─→ frontend-service    → Frontend Pods
    ├─→ user-service        → User Service Pods
    └─→ todo-service        → Todo Service Pods
```

**Võrdlus traditsioonilise Nginx'iga (Path A õppijatele):**

| Aspekt | Nginx (Harjutus 01) | Ingress (See harjutus) |
|--------|-------------------|----------------------|
| **Konfiguratsioon** | nginx.conf fail | YAML manifest |
| **Muudatused** | SSH + vim + reload | kubectl apply |
| **Backend discovery** | Käsitsi: localhost:3000 | Automaatne: Service nimi |
| **Skaleerumine** | 1 instance | Mitu replica't |
| **HA** | Single point of failure | Automaatne failover |

---

## 🎯 Õpieesmärgid

Selle harjutuse lõpuks sa:

- ✅ Mõistad Ingress Controller ja Ingress Resource erinevust
- ✅ Oskad paigaldada Nginx Ingress Controller'i Kubernetes klasterisse
- ✅ Oskad luua Ingress ressursse path-based routing'uks
- ✅ Mõistad kuidas Ingress integreerub Service discovery'ga
- ✅ Oskad seadistada Ingress annotation'eid
- ✅ Tead kuidas debugida Ingress probleeme
- ✅ Mõistad Ingress Class kontseptsiooni
- ✅ Oskad võrrelda erinevaid Ingress Controller'eid

---

## 📚 Teoreetiline Taust

### Mis on Kubernetes Ingress?

**Ingress** on Kubernetes API objekt, mis haldab välist ligipääsu teenustele klastris, tavaliselt HTTP/HTTPS.

```yaml
Ingress (routing reeglid) + Ingress Controller (implementatsioon) = Reverse Proxy
```

### Ingress vs Service

```
NodePort/LoadBalancer Service:
Internet → Service (port 30000-32767) → Pod

Ingress:
Internet → Ingress Controller (port 80/443) → Service → Pod
```

**Eelised:**
- ✅ Üks entry point kõigile teenustele
- ✅ Path ja host based routing
- ✅ SSL termination ühes kohas
- ✅ Inimloetavad URL'id (ei nõua portide numbrite teadmist)

### Ingress Controller tüübid

Kubernetes'el EI OLE vaikimisi Ingress Controller'it. Sa pead valima ja paigaldama ühe:

| Controller | Eelised | Kasutatakse |
|------------|---------|-------------|
| **Nginx Ingress** | Populaarne, lihtne, lai tugi | Enamik projektid |
| **Traefik** | Automaatne service discovery, Let's Encrypt | Modern microservices |
| **HAProxy** | Väga kiire, enterprise-grade | High traffic |
| **Istio Gateway** | Service mesh, traffic management | Complex microservices |
| **AWS ALB** | Native AWS integratsioon | AWS EKS |
| **GCE** | Native GCP integratsioon | Google GKE |

**Selles harjutuses:** Kasutame **Nginx Ingress Controller'it** (kõige levinum valik).

---

## 🔧 Eeltingimused

### 1. Kubernetes klaster töötab

```bash
kubectl cluster-info
kubectl get nodes
```

**Oodatav väljund:**
```
NAME       STATUS   ROLES           AGE   VERSION
kirjakast   Ready    control-plane   1d    v1.28.0
```

**Kui Kubernetes pole paigaldatud:**

Paigalda minikube (local development) VÕI k3s (lightweight production):

```bash
# Minikube (development)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start

# VÕI k3s (production-like)
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

### 2. kubectl on paigaldatud ja töötab

```bash
kubectl version --client
```

### 3. Lab 3 manifest'id on olemas

Kontrolli, et sul on Labor 3 YAML failid:

```bash
ls /home/janek/projects/hostinger/labs/03-kubernetes-basics-lab/manifests/
```

**Oodatav:** deployment.yaml, service.yaml, configmap.yaml vms

Kui mitte, kasuta seda harjutust kui juhist ja loo ise.

---

## 📝 Samm 1: Paigalda Nginx Ingress Controller

### 1.1 Paigalda Nginx Ingress Controller ametlikust repo'st

Kubernetes community hooldab ametlikku Nginx Ingress Controller'it:

```bash
# Paigalda viimane stable versioon
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
```

**Mida see teeb:**
- Loob `ingress-nginx` namespace'i
- Loob Ingress Controller Deployment'i
- Loob LoadBalancer Service teenuse
- Loob vajalikud RBAC reeglid (ServiceAccount, ClusterRole, ClusterRoleBinding)
- Loob ConfigMap Nginx seadistustele
- Loob IngressClass objekti

### 1.2 Oota kuni Ingress Controller on valmis

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

**Oodatav väljund:**
```
pod/ingress-nginx-controller-xxxx-yyyy condition met
```

### 1.3 Kontrolli Ingress Controller pod'ide staatust

```bash
kubectl get pods -n ingress-nginx
```

**Oodatav väljund:**
```
NAME                                       READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-7c6974c4d8-abcd   1/1     Running   0          2m
```

### 1.4 Kontrolli Ingress Controller Service'it

```bash
kubectl get service -n ingress-nginx ingress-nginx-controller
```

**Oodatav väljund:**
```
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
ingress-nginx-controller   LoadBalancer   10.96.100.10    <pending>     80:30080/TCP,443:30443/TCP
```

**Märkus:**
- **Cloud environment'is** (AWS, GCP): EXTERNAL-IP saab automaatselt (LoadBalancer)
- **Bare-metal/VPS:** EXTERNAL-IP jääb `<pending>` - kasutame NodePort'e

### 1.5 Kontrolli IngressClass

```bash
kubectl get ingressclass
```

**Oodatav väljund:**
```
NAME    CONTROLLER             AGE
nginx   k8s.io/ingress-nginx   2m
```

---

## 📝 Samm 2: Paigalda Rakendused Kubernetes Klasterisse

Enne kui saame luua Ingress ressursse, peame paigaldama meie mikroteenused Kubernetes'esse.

### 2.1 Loo namespace rakenduste jaoks

```bash
kubectl create namespace todo-app
```

### 2.2 Loo PostgreSQL StatefulSet (User Service)

**Fail:** `user-postgres-statefulset.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-postgres-config
  namespace: todo-app
data:
  POSTGRES_DB: user_service_db
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-user
  namespace: todo-app
spec:
  serviceName: postgres-user
  replicas: 1
  selector:
    matchLabels:
      app: postgres-user
  template:
    metadata:
      labels:
        app: postgres-user
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
          name: postgres
        envFrom:
        - configMapRef:
            name: user-postgres-config
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-user
  namespace: todo-app
spec:
  selector:
    app: postgres-user
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None  # Headless service
```

**Rakenda:**
```bash
kubectl apply -f user-postgres-statefulset.yaml
```

### 2.3 Loo PostgreSQL StatefulSet (Todo Service)

**Fail:** `todo-postgres-statefulset.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: todo-postgres-config
  namespace: todo-app
data:
  POSTGRES_DB: todo_service_db
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-todo
  namespace: todo-app
spec:
  serviceName: postgres-todo
  replicas: 1
  selector:
    matchLabels:
      app: postgres-todo
  template:
    metadata:
      labels:
        app: postgres-todo
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
          name: postgres
        envFrom:
        - configMapRef:
            name: todo-postgres-config
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-todo
  namespace: todo-app
spec:
  selector:
    app: postgres-todo
  ports:
  - port: 5432
    targetPort: 5432
  clusterIP: None
```

**Rakenda:**
```bash
kubectl apply -f todo-postgres-statefulset.yaml
```

### 2.4 Loo User Service Deployment

**Fail:** `user-service-deployment.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
  namespace: todo-app
type: Opaque
stringData:
  JWT_SECRET: shared-secret-key-change-this-in-production-must-be-at-least-256-bits
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: todo-app
spec:
  replicas: 2  # Load balancing: 2 pod'i
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:1.0  # Kasuta oma Docker image'i
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: DB_HOST
          value: postgres-user.todo-app.svc.cluster.local
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: user_service_db
        - name: DB_USER
          value: postgres
        - name: DB_PASSWORD
          value: postgres
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: JWT_SECRET
        - name: JWT_EXPIRES_IN
          value: "1h"
        - name: PORT
          value: "3000"
        - name: NODE_ENV
          value: production
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: todo-app
spec:
  selector:
    app: user-service
  ports:
  - port: 3000
    targetPort: 3000
  type: ClusterIP
```

**Rakenda:**
```bash
kubectl apply -f user-service-deployment.yaml
```

### 2.5 Loo Todo Service Deployment

**Fail:** `todo-service-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-service
  namespace: todo-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo-service
  template:
    metadata:
      labels:
        app: todo-service
    spec:
      containers:
      - name: todo-service
        image: todo-service:1.0  # Kasuta oma Docker image'i
        ports:
        - containerPort: 8081
          name: http
        env:
        - name: DB_HOST
          value: postgres-todo.todo-app.svc.cluster.local
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: todo_service_db
        - name: DB_USER
          value: postgres
        - name: DB_PASSWORD
          value: postgres
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: JWT_SECRET
        - name: SPRING_PROFILES_ACTIVE
          value: prod
        livenessProbe:
          httpGet:
            path: /health
            port: 8081
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8081
          initialDelaySeconds: 30
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: todo-service
  namespace: todo-app
spec:
  selector:
    app: todo-service
  ports:
  - port: 8081
    targetPort: 8081
  type: ClusterIP
```

**Rakenda:**
```bash
kubectl apply -f todo-service-deployment.yaml
```

### 2.6 Loo Frontend Deployment

**Fail:** `frontend-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: todo-app
spec:
  replicas: 2
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
        image: nginx:alpine
        ports:
        - containerPort: 80
          name: http
        volumeMounts:
        - name: frontend-files
          mountPath: /usr/share/nginx/html
      volumes:
      - name: frontend-files
        hostPath:
          path: /home/janek/projects/hostinger/labs/apps/frontend
          type: Directory
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: todo-app
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

**Rakenda:**
```bash
kubectl apply -f frontend-deployment.yaml
```

### 2.7 Kontrolli kõiki ressursse

```bash
kubectl get all -n todo-app
```

**Oodatav väljund:**
```
NAME                               READY   STATUS    RESTARTS   AGE
pod/frontend-xxx                   1/1     Running   0          1m
pod/postgres-todo-0                1/1     Running   0          2m
pod/postgres-user-0                1/1     Running   0          2m
pod/todo-service-xxx               1/1     Running   0          1m
pod/user-service-xxx               1/1     Running   0          1m

NAME                   TYPE        CLUSTER-IP       PORT(S)
service/frontend       ClusterIP   10.96.10.1       80/TCP
service/postgres-todo  ClusterIP   None             5432/TCP
service/postgres-user  ClusterIP   None             5432/TCP
service/todo-service   ClusterIP   10.96.10.2       8081/TCP
service/user-service   ClusterIP   10.96.10.3       3000/TCP

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/frontend       2/2     2            2           1m
deployment.apps/todo-service   2/2     2            2           1m
deployment.apps/user-service   2/2     2            2           1m

NAME                              READY   AGE
statefulset.apps/postgres-todo    1/1     2m
statefulset.apps/postgres-user    1/1     2m
```

---

## 📝 Samm 3: Loo Ingress Ressurss

### 3.1 Mõista Ingress YAML struktuuri

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-app-ingress
  annotations:
    # Annotation'id konfigureerivad Ingress Controller käitumist
spec:
  ingressClassName: nginx
  rules:
  - host: kirjakast.cloud
    http:
      paths:
      - path: /api/todos
        pathType: Prefix
        backend:
          service:
            name: todo-service
            port:
              number: 8081
```

**Komponendid:**
- `ingressClassName`: Millist Ingress Controller'it kasutada
- `rules.host`: Domeen (valikuline, kui puudub siis match kõik hostid)
- `rules.http.paths`: URL path'id ja nende backend Service'd
- `pathType`: `Prefix` (algab sellega) VÕI `Exact` (täpne match)

### 3.2 Loo täielik Ingress konfiguratsioon

**Fail:** `app-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-app-ingress
  namespace: todo-app
  annotations:
    # Nginx-specific annotation'id
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"

    # CORS support
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, PATCH, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Authorization, Content-Type"

    # Timeout'id
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
spec:
  ingressClassName: nginx
  rules:
  - host: kirjakast.cloud
    http:
      paths:
      # Todo Service API
      - path: /api/todos
        pathType: Prefix
        backend:
          service:
            name: todo-service
            port:
              number: 8081

      # User Service API - Users
      - path: /api/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 3000

      # User Service API - Auth
      - path: /api/auth
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 3000

      # Frontend - Todo page
      - path: /todo
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80

      # Frontend - Root
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80

  # Default backend (404 page)
  defaultBackend:
    service:
      name: frontend
      port:
        number: 80
```

### 3.3 Rakenda Ingress

```bash
kubectl apply -f app-ingress.yaml
```

### 3.4 Kontrolli Ingress staatust

```bash
kubectl get ingress -n todo-app
```

**Oodatav väljund:**
```
NAME               CLASS   HOSTS             ADDRESS         PORTS   AGE
todo-app-ingress   nginx   kirjakast.cloud   192.168.1.100   80      1m
```

### 3.5 Vaata detailset info

```bash
kubectl describe ingress todo-app-ingress -n todo-app
```

**Oodatav väljund:**
```
Name:             todo-app-ingress
Namespace:        todo-app
Address:          192.168.1.100
Default backend:  frontend:80
Rules:
  Host             Path  Backends
  ----             ----  --------
  kirjakast.cloud
                   /api/todos    todo-service:8081
                   /api/users    user-service:3000
                   /api/auth     user-service:3000
                   /todo         frontend:80
                   /             frontend:80
Annotations:       nginx.ingress.kubernetes.io/rewrite-target: /
                   nginx.ingress.kubernetes.io/ssl-redirect: false
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  Sync    30s   nginx-ingress-controller  Scheduled for sync
```

---

## 📝 Samm 4: Testimine

### 4.1 Leia Ingress Controller IP/Port

**Kui LoadBalancer:**
```bash
kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Kui NodePort (VPS/bare-metal):**
```bash
kubectl get service -n ingress-nginx ingress-nginx-controller
# Märgi üles NodePort (nt 30080 HTTP jaoks)
```

### 4.2 Seadista DNS osutama Ingress Controller'ile

**Cloud (LoadBalancer):**
```
DNS A-kirje: kirjakast.cloud → <LoadBalancer IP>
```

**VPS (NodePort):**
```
DNS A-kirje: kirjakast.cloud → <VPS IP>
Port forwarding: VPS port 80 → Node NodePort 30080
```

**VPS Port Forward (kui NodePort):**
```bash
# Firewall reegel (iptables)
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080
```

**VÕI** kasuta Nginx host'is (kombineeritud lähenemine):
```nginx
server {
    listen 80;
    server_name kirjakast.cloud;

    location / {
        proxy_pass http://localhost:30080;
    }
}
```

### 4.3 Testi Ingress'i

**Testi API endpoint'e:**
```bash
# User API
curl http://kirjakast.cloud/api/users

# Todo API
curl http://kirjakast.cloud/api/todos

# Frontend
curl -I http://kirjakast.cloud/
curl -I http://kirjakast.cloud/todo
```

### 4.4 Testi täielik workflow

Korda sama workflow't mis harjutuses 01:

```bash
# 1. Registreerimine
curl -X POST http://kirjakast.cloud/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"K8s User","email":"k8s@example.com","password":"test123"}'

# 2. Login
curl -X POST http://kirjakast.cloud/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"k8s@example.com","password":"test123"}' \
  | tee /tmp/k8s-login.json

# 3. Ekstrakti token
TOKEN=$(cat /tmp/k8s-login.json | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# 4. Loo todo
curl -X POST http://kirjakast.cloud/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Õpi Kubernetes Ingress","priority":"high"}'

# 5. Loe todos
curl http://kirjakast.cloud/api/todos -H "Authorization: Bearer $TOKEN"
```

---

## 📝 Samm 5: Ingress Debugging

### 5.1 Vaata Ingress Controller logisid

```bash
# Leia Ingress Controller pod
kubectl get pods -n ingress-nginx

# Vaata loge
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=50 --follow
```

### 5.2 Kontrolli Nginx konfiguratsiooni Ingress Controller'is

```bash
# Sisene Ingress Controller pod'i
kubectl exec -it -n ingress-nginx deployment/ingress-nginx-controller -- bash

# Vaata genereeritud Nginx config'i
cat /etc/nginx/nginx.conf | grep -A 20 "server_name kirjakast.cloud"

# Testi Nginx config'i
nginx -t
```

### 5.3 Testi backend Service'it otse

```bash
# Port-forward'i User Service
kubectl port-forward -n todo-app service/user-service 3000:3000

# Tee päring otse (teises terminal'is)
curl http://localhost:3000/health
curl http://localhost:3000/api/users
```

### 5.4 Kontrolli Service Endpoints

```bash
kubectl get endpoints -n todo-app
```

**Oodatav:** Iga Service'il peab olema IP aadress (pod IP).

```
NAME           ENDPOINTS
frontend       10.244.0.5:80,10.244.0.6:80
user-service   10.244.0.7:3000,10.244.0.8:3000
todo-service   10.244.0.9:8081,10.244.0.10:8081
```

Kui `ENDPOINTS` on tühi → pod'id ei vasta Service selector'ile.

---

## 🐛 Troubleshooting

### Probleem 1: Ingress ADDRESS on tühi

**Sümptomid:**
```bash
kubectl get ingress -n todo-app
# ADDRESS veerg on tühi
```

**Lahendus:**
```bash
# 1. Kontrolli kas Ingress Controller töötab
kubectl get pods -n ingress-nginx

# 2. Kontrolli IngressClass
kubectl get ingressclass

# 3. Kontrolli kas Ingress kasutab õiget IngressClass'i
kubectl get ingress -n todo-app -o yaml | grep ingressClassName
```

### Probleem 2: 503 Service Temporarily Unavailable

**Sümptomid:**
```bash
curl http://kirjakast.cloud/api/todos
<html><body><h1>503 Service Temporarily Unavailable</h1></body></html>
```

**Lahendus:**
```bash
# 1. Kontrolli kas backend pod'id töötavad
kubectl get pods -n todo-app

# 2. Kontrolli Service endpoints
kubectl get endpoints -n todo-app

# 3. Kontrolli pod'ide readiness
kubectl describe pod -n todo-app <pod-name>

# 4. Vaata Ingress Controller loge
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Probleem 3: 404 Not Found (vale path)

**Sümptomid:**
Mõned path'id töötavad, mõned annavad 404.

**Lahendus:**
```bash
# Kontrolli Ingress path'e
kubectl describe ingress -n todo-app todo-app-ingress

# Kontrolli path ordering (täpsemad peaksid olema enne üldisemaid)
# Vale järjekord:
# - path: /          # Match KÕIK päringud (liiga üldine)
# - path: /api/todos # Ei jõua kunagi siia!

# Õige järjekord (nagu meie config'is):
# - path: /api/todos  # Täpsem
# - path: /api/users  # Täpsem
# - path: /           # Üldine (viimane)
```

### Probleem 4: CORS vead

**Sümptomid:**
Browser console näitab CORS policy vigu.

**Lahendus:**
Kontrolli annotation'eid:
```bash
kubectl get ingress -n todo-app todo-app-ingress -o yaml | grep cors
```

Lisa puuduvad annotation'id:
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
```

---

## ✅ Valideerimise Checklist

Märgi ära kui oled täitnud:

- [ ] Nginx Ingress Controller paigaldatud (`kubectl get pods -n ingress-nginx`)
- [ ] IngressClass `nginx` eksisteerib (`kubectl get ingressclass`)
- [ ] Rakenduste pod'id töötavad (`kubectl get pods -n todo-app`)
- [ ] Service'id loodud ja endpoints'id olemas (`kubectl get svc,endpoints -n todo-app`)
- [ ] Ingress ressurss loodud (`kubectl get ingress -n todo-app`)
- [ ] Ingress ADDRESS on määratud (mitte tühi)
- [ ] DNS osutab Ingress Controller IP'le
- [ ] Frontend kättesaadav: `http://kirjakast.cloud/` → HTTP 200
- [ ] Todo page kättesaadav: `http://kirjakast.cloud/todo` → HTTP 200
- [ ] Todo API kättesaadav: `http://kirjakast.cloud/api/todos` → JSON
- [ ] User API kättesaadav: `http://kirjakast.cloud/api/users` → JSON
- [ ] Täielik workflow töötab (registreerimine → login → todo loomine)
- [ ] Load balancing töötab (2 replica't igal teenuselt)

---

## 🎓 Mida Sa Õppisid?

Selle harjutuse käigus õppisid:

### Kubernetes Ingress Kontseptsioonid
- ✅ Ingress Controller vs Ingress Resource erinevus
- ✅ IngressClass ja kuidas valida controller'it
- ✅ Path-based routing Kubernetes'es
- ✅ Annotation'id Nginx Ingress'ile
- ✅ Default backend konfiguratsioon

### Kubernetes Networking
- ✅ ClusterIP Service'id sisemiseks suhtluseks
- ✅ Service discovery DNS'i kaudu (`service-name.namespace.svc.cluster.local`)
- ✅ Endpoints ja kuidas Service pod'idega seotud on
- ✅ External access konfigureerimine

### Tootmise Praktikad
- ✅ Liveness ja readiness probe'id
- ✅ Replica'te kasutamine load balancing'uks
- ✅ Secret'id tundliku info jaoks (JWT secret)
- ✅ ConfigMap'id konfiguratsiooniks
- ✅ StatefulSet'id andmebaasidele

---

## 🆚 Võrdlus: Nginx (Harjutus 01) vs Ingress (See harjutus)

| Aspekt | Nginx VPS (Har. 01) | Kubernetes Ingress (Har. 02) |
|--------|-------------------|------------------------------|
| **Paigaldus** | `apt install nginx` | `kubectl apply -f deploy.yaml` |
| **Konfiguratsioon** | `/etc/nginx/sites-available/kirjakast.cloud` | `app-ingress.yaml` manifest |
| **Muudatused** | `vim` + `nginx -t` + `systemctl reload` | `kubectl apply -f` |
| **Backend discovery** | Käsitsi: `server localhost:3000;` | Automaatne: `service.name: user-service` |
| **Load balancing** | Käsitsi konfiguratsioon (upstream block) | Automaatne (Service endpoints) |
| **Skaleerumine** | 1 Nginx instance | Mitu Ingress Controller pod'i (Deployment) |
| **Failover** | Kui Nginx crashib → kõik maha | K8s restartib pod'i automaatselt |
| **Health checks** | Manuaalne upstream health check | Readiness/liveness probe'id |
| **Sertifikaadid** | Let's Encrypt + certbot | cert-manager (automaatne) |
| **Rollback** | Backup config + restore | `kubectl rollout undo` |
| **Monitoring** | `/var/log/nginx/*.log` | `kubectl logs` + Prometheus metrics |

**Millal kasutada kumbagi:**
- **Nginx VPS:** Lihtsad projektid, üks server, väike tiim
- **Kubernetes Ingress:** Suur liiklus, mikroteenused, cloud-native, DevOps tiim

---

## 🎯 Järgmised Sammud

### Edasi Path A:
➡️ **Harjutus 03: SSL/TLS Sertifikaadid** - lisa HTTPS tugi mõlemale lahendusele

### Edasi Path B:
➡️ **Harjutus 03: SSL/TLS cert-manager'iga** - automaatsed Let's Encrypt sertifikaadid

### Valikuline:
- Proovi teisi Ingress Controller'eid (Traefik, HAProxy)
- Lisa rate limiting Ingress annotation'idega
- Seadista Ingress monitoring Prometheus'ega
- Implementeeri A/B testing path'i põhjal

---

**Õnnitleme!** 🎉

Sa oled nüüd seadistanud Kubernetes Ingress Controller'i ja loonud Ingress ressursid oma mikroteenuste jaoks. See on kaasaegne, skaaleeritav ja cloud-native lähenemine reverse proxy'le.

**Path A õppijatele:** Nüüd sa mõistad mõlemat lähenemist - traditsioonilist (Nginx VPS) ja kaasaegset (K8s Ingress). See annab sulle võimaluse valida õige tööriist iga projekti jaoks!

**Harjutuse lõpp**

---

**Viimane uuendus:** 2025-11-16
**Autor:** DevOps Training Labs
