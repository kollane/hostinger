# Peatükk 19: Frontend Deployment ja Ingress ☸️

**Kestus:** 4 tundi
**Eeldused:** Peatükk 18 läbitud, Backend K8s-es deployitud
**Eesmärk:** Deployida frontend Kubernetes-es ja seadistada Ingress väliseks ligipääsuks

---

## Sisukord

1. [Ülevaade](#1-ülevaade)
2. [Frontend Rakenduse Ettevalmistamine](#2-frontend-rakenduse-ettevalmistamine)
3. [Frontend Deployment](#3-frontend-deployment)
4. [Frontend Service](#4-frontend-service)
5. [Ingress Controller (Traefik)](#5-ingress-controller-traefik)
6. [Ingress Rules ja Routing](#6-ingress-rules-ja-routing)
7. [TLS/SSL Sertifikaadid](#7-tlsssl-sertifikaadid)
8. [Domain Nimedega Töötamine](#8-domain-nimedega-töötamine)
9. [Path-Based Routing](#9-path-based-routing)
10. [Harjutused](#10-harjutused)

---

## 1. Ülevaade

### 1.1. Frontend Arhitektuur Kubernetes-es

```
Internet
   │
   ├──> http://93.127.213.242
   │    https://example.com
   │
   ▼
┌──────────────────────────────────────┐
│   VPS kirjakast (93.127.213.242)    │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  K3s Ingress Controller        │  │
│  │  (Traefik)                     │  │
│  │  Ports: 80, 443                │  │
│  └──────────┬─────────────────────┘  │
│             │                        │
│  ┌──────────▼─────────────────────┐  │
│  │  Ingress Rules                 │  │
│  │  - / → frontend                │  │
│  │  - /api → backend              │  │
│  └──────────┬─────────────────────┘  │
│             │                        │
│  ┌──────────▼─────────────────────┐  │
│  │  Frontend Service              │  │
│  │  (ClusterIP: 80)               │  │
│  └──────────┬─────────────────────┘  │
│             │                        │
│  ┌──────────▼─────────────────────┐  │
│  │  Frontend Deployment           │  │
│  │  (Nginx + Static Files)        │  │
│  │  Replicas: 2                   │  │
│  │  - Pod 1 (frontend)            │  │
│  │  - Pod 2 (frontend)            │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  Backend Service               │  │
│  │  (ClusterIP: 3000)             │  │
│  └────────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
```

### 1.2. Frontend Spetsifikatsioon

**Lokaal:**
```bash
Path:       /home/janek/projects/hostinger/labs/apps/frontend
Tech:       Vanilla JavaScript (HTML/CSS/JS)
Server:     Nginx (static files)
Port:       80
```

**Frontend funktsioonid:**
- Login/Register vorm
- Kasutajate nimekiri
- Backend API kutsed (/api/auth/*, /api/users)
- JWT token haldus

---

## 2. Frontend Rakenduse Ettevalmistamine

### 2.1. Frontend Struktuuri Ülevaade

```bash
cd /home/janek/projects/hostinger/labs/apps/frontend

tree
# .
# ├── index.html
# ├── login.html
# ├── register.html
# ├── users.html
# ├── css/
# │   └── style.css
# ├── js/
# │   ├── api.js
# │   ├── auth.js
# │   └── users.js
# ├── Dockerfile
# ├── Dockerfile.optimized
# └── nginx.conf
```

### 2.2. Nginx Konfiguratsioon

Frontend kasutab Nginx-i staatiliste failide serveerimiseks.

**Fail:** `/home/janek/projects/hostinger/labs/apps/frontend/nginx.conf`

```nginx
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Static files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 2.3. API Konfiguratsioon Frontend-is

**Oluline:** Frontend peab teadma backend API URL-i.

**Fail:** `js/api.js`

```javascript
// API base URL
// Kubernetes-es: kasutame suhtelist path-i (/api)
// Ingress suunab /api → backend Service
const API_URL = '/api';

// Näide:
// GET /api/users → Ingress → backend:3000/api/users
```

### 2.4. Dockerfile Frontend-ile

**Fail:** `Dockerfile` (optimized variant on parem)

```dockerfile
# Multi-stage build
FROM nginx:alpine

# Kopeeri Nginx konfiguratsioon
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Kopeeri static files
COPY index.html login.html register.html users.html /usr/share/nginx/html/
COPY css/ /usr/share/nginx/html/css/
COPY js/ /usr/share/nginx/html/js/

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Expose port
EXPOSE 80

# Nginx runs in foreground by default in alpine
CMD ["nginx", "-g", "daemon off;"]
```

---

## 3. Frontend Deployment

### 3.1. Build ja Push Frontend Image

```bash
cd /home/janek/projects/hostinger/labs/apps/frontend

# Build image
docker build -t localhost:5000/frontend:1.0 .

# Test lokaalselt
docker run -d --name frontend-test -p 8080:80 localhost:5000/frontend:1.0

# Kontrolli
curl http://localhost:8080/health
# OK

# Peata test
docker stop frontend-test
docker rm frontend-test

# Push registry-sse
docker push localhost:5000/frontend:1.0
```

### 3.2. Frontend Deployment Manifest

**Fail:** `frontend-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: production
  labels:
    app: frontend
    version: v1
spec:
  replicas: 2                      # 2 koopiat
  selector:
    matchLabels:
      app: frontend
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0            # Zero downtime
  template:
    metadata:
      labels:
        app: frontend
        version: v1
    spec:
      containers:
      - name: frontend
        image: localhost:5000/frontend:1.0
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 80
          protocol: TCP

        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /health
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2

        # Resources
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"

      restartPolicy: Always
```

**Rakenda:**
```bash
kubectl apply -f frontend-deployment.yaml

# Kontrolli
kubectl get deployment frontend -n production
kubectl get pods -n production -l app=frontend

# Vaata loge
kubectl logs -n production -l app=frontend --tail=20
```

---

## 4. Frontend Service

### 4.1. ClusterIP Service

**Fail:** `frontend-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: production
  labels:
    app: frontend
spec:
  type: ClusterIP              # Sisemine service
  selector:
    app: frontend
  ports:
  - name: http
    port: 80                   # Service port
    targetPort: 80             # Container port
    protocol: TCP
  sessionAffinity: None
```

**Rakenda:**
```bash
kubectl apply -f frontend-service.yaml

# Kontrolli
kubectl get service frontend -n production
kubectl describe service frontend -n production

# Vaata endpoints
kubectl get endpoints frontend -n production
```

### 4.2. Testi Service-i

```bash
# Port-forward
kubectl port-forward service/frontend 8080:80 -n production

# Avada browseris
# http://localhost:8080

# VÕI curl
curl http://localhost:8080/health
# OK

curl -I http://localhost:8080/
# HTTP/1.1 200 OK
# Content-Type: text/html
```

---

## 5. Ingress Controller (Traefik)

### 5.1. K3s Default Ingress Controller

K3s tuleb vaikimisi **Traefik** Ingress Controller-iga.

**Kontrolli:**
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik

# NAME                      READY   STATUS    RESTARTS   AGE
# traefik-xxx-xxx           1/1     Running   0          10d

kubectl get service -n kube-system traefik

# NAME      TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)
# traefik   LoadBalancer   10.43.0.1      93.127.213.242    80:30080/TCP,443:30443/TCP
```

**Traefik kuulab:**
- Port **80** (HTTP)
- Port **443** (HTTPS)

### 5.2. Traefik Dashboard (valikuline)

**Luba Traefik dashboard:**
```bash
# Kontrolli, kas dashboard on lubatud
kubectl get ingressroute -n kube-system

# Kui pole, luba:
kubectl port-forward -n kube-system deployment/traefik 9000:9000

# Ava browseris: http://localhost:9000/dashboard/
```

---

## 6. Ingress Rules ja Routing

### 6.1. Lihtne Ingress - Frontend Ainult

**Fail:** `frontend-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  namespace: production
  annotations:
    # Traefik spetsiifilised annotations
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: 93.127.213.242.nip.io     # Wildcard DNS IP-le
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

**nip.io selgitus:**
- `93.127.213.242.nip.io` → resolvib automaatselt `93.127.213.242`
- Kasulik testimiseks ilma domeeni registreerimata

**Rakenda:**
```bash
kubectl apply -f frontend-ingress.yaml

# Kontrolli
kubectl get ingress -n production
kubectl describe ingress frontend-ingress -n production
```

**Testi:**
```bash
# Lokaalselt VPS-is
curl http://93.127.213.242.nip.io/

# Või IP-ga
curl http://93.127.213.242/

# Peaks tagastama index.html sisu
```

### 6.2. Täielik Ingress - Frontend + Backend

**Fail:** `full-ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: production
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
    # Strip /api prefix enne backend-ile edastamist
    traefik.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: 93.127.213.242.nip.io
    http:
      paths:
      # Backend API
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 3000

      # Frontend (peab olema viimane - catch-all)
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

**Kuidas töötab:**
```
http://93.127.213.242.nip.io/          → frontend:80/
http://93.127.213.242.nip.io/login     → frontend:80/login
http://93.127.213.242.nip.io/api/users → backend:3000/api/users
```

**Rakenda:**
```bash
# Kustuta vana Ingress
kubectl delete ingress frontend-ingress -n production

# Rakenda uus
kubectl apply -f full-ingress.yaml

# Kontrolli
kubectl get ingress -n production
kubectl describe ingress app-ingress -n production
```

**Testi:**
```bash
# Frontend
curl http://93.127.213.242.nip.io/
# <html>...</html>

# Backend API
curl http://93.127.213.242.nip.io/api/health
# {"status":"ok","timestamp":"..."}
```

---

## 7. TLS/SSL Sertifikaadid

### 7.1. Cert-Manager Paigaldamine

**Cert-Manager** haldab automaatselt Let's Encrypt sertifikaate.

**Paigalda cert-manager:**
```bash
# Lisa Helm repo (kui ei ole)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

# Kontrolli paigaldust
kubectl get pods -n cert-manager

# NAME                                      READY   STATUS    RESTARTS   AGE
# cert-manager-xxx                          1/1     Running   0          1m
# cert-manager-cainjector-xxx               1/1     Running   0          1m
# cert-manager-webhook-xxx                  1/1     Running   0          1m
```

### 7.2. Let's Encrypt ClusterIssuer

**Fail:** `letsencrypt-issuer.yaml`

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Let's Encrypt production server
    server: https://acme-v02.api.letsencrypt.org/directory

    # Email Let's Encrypt teavitusteks
    email: janek@example.com       # ← MUUDA oma emailiks

    # Secret TLS võtme jaoks
    privateKeySecretRef:
      name: letsencrypt-prod-key

    # HTTP-01 challenge
    solvers:
    - http01:
        ingress:
          class: traefik
```

**Staging issuer (testimiseks):**

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # Let's Encrypt staging server (test)
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: janek@example.com
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
    - http01:
        ingress:
          class: traefik
```

**Rakenda:**
```bash
kubectl apply -f letsencrypt-issuer.yaml

# Kontrolli
kubectl get clusterissuer
# NAME                  READY   AGE
# letsencrypt-prod      True    10s
```

### 7.3. Ingress TLS-iga

**EELDUS:** Sul on domeen (nt `example.com`) mis osutab `93.127.213.242`

**Fail:** `full-ingress-tls.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: production
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    # Cert-manager automaatne sertifikaat
    cert-manager.io/cluster-issuer: letsencrypt-prod
    # Redirect HTTP → HTTPS
    traefik.ingress.kubernetes.io/redirect-entry-point: https
spec:
  tls:
  - hosts:
    - example.com                  # ← MUUDA oma domeeniks
    secretName: example-com-tls    # Cert-manager loob selle automaatselt

  rules:
  - host: example.com              # ← MUUDA oma domeeniks
    http:
      paths:
      # Backend API
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 3000

      # Frontend
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

**Rakenda:**
```bash
kubectl apply -f full-ingress-tls.yaml

# Jälgi sertifikaadi loomist
kubectl get certificate -n production

# NAME               READY   SECRET             AGE
# example-com-tls    True    example-com-tls    2m

# Vaata detaile
kubectl describe certificate example-com-tls -n production

# Kontrolli Secret-i
kubectl get secret example-com-tls -n production
```

**Testi HTTPS:**
```bash
curl https://example.com/
curl https://example.com/api/health
```

### 7.4. Troubleshooting TLS

**Sertifikaat ei loo:**
```bash
# Vaata cert-manager loge
kubectl logs -n cert-manager deployment/cert-manager

# Vaata Certificate events
kubectl describe certificate example-com-tls -n production

# Vaata CertificateRequest
kubectl get certificaterequest -n production
kubectl describe certificaterequest <name> -n production

# Vaata Order (ACME)
kubectl get order -n production
kubectl describe order <name> -n production

# Vaata Challenge
kubectl get challenge -n production
kubectl describe challenge <name> -n production
```

**Levinud probleemid:**
- **DNS ei osuta VPS-ile:** Kontrolli `dig example.com` või `nslookup example.com`
- **Port 80 ei ole ligipääsetav:** Kontrolli firewall (ufw, iptables)
- **HTTP-01 challenge ebaõnnestub:** Vaata, kas `.well-known/acme-challenge/` on ligipääsetav

---

## 8. Domain Nimedega Töötamine

### 8.1. DNS Seadistamine

**Eesmärk:** Domeen `example.com` osutab VPS-ile `93.127.213.242`

**DNS Records:**

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | 93.127.213.242 | 3600 |
| A | www | 93.127.213.242 | 3600 |

**VÕI CNAME (kui on alias):**

| Type | Name | Value | TTL |
|------|------|-------|-----|
| CNAME | www | example.com | 3600 |

**Kontrolli DNS-i:**
```bash
# Dig
dig example.com +short
# 93.127.213.242

dig www.example.com +short
# 93.127.213.242

# Nslookup
nslookup example.com
# Address: 93.127.213.242
```

### 8.2. Subdomeenid

**Näide:** `api.example.com` → backend, `www.example.com` → frontend

**DNS:**

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | api | 93.127.213.242 | 3600 |
| A | www | 93.127.213.242 | 3600 |

**Ingress:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - www.example.com
    - api.example.com
    secretName: app-tls

  rules:
  # Frontend
  - host: www.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80

  # Backend
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 3000
```

---

## 9. Path-Based Routing

### 9.1. Mitu Rakendust Samas Domeenis

**Näide:**
- `example.com/` → App 1 (frontend)
- `example.com/admin` → App 2 (admin panel)
- `example.com/api` → Backend API

**Ingress:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-app-ingress
  namespace: production
spec:
  rules:
  - host: example.com
    http:
      paths:
      # Admin panel (kõige spetsiifilisem esimesena)
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin-panel
            port:
              number: 80

      # API
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 3000

      # Frontend (catch-all viimane)
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

**Oluline:**
- **Järjekord loeb!** Spetsiifilisemad path-id peavad olema enne üldisemaid
- `pathType: Prefix` - match kõik, mis algab selle path-iga
- `pathType: Exact` - match ainult täpne path

### 9.2. PathType Võrdlus

| pathType | Path | URL | Match? |
|----------|------|-----|--------|
| Prefix | /api | /api | ✅ Yes |
| Prefix | /api | /api/users | ✅ Yes |
| Prefix | /api | /api/ | ✅ Yes |
| Exact | /api | /api | ✅ Yes |
| Exact | /api | /api/users | ❌ No |
| Exact | /api | /api/ | ❌ No |

---

## 10. Harjutused

### Harjutus 1: Frontend Deployment

**Eesmärk:** Deployida frontend Kubernetes-es

**Sammud:**

1. **Build frontend image:**
```bash
cd /home/janek/projects/hostinger/labs/apps/frontend

docker build -t localhost:5000/frontend:1.0 .
docker push localhost:5000/frontend:1.0
```

2. **Loo Deployment:**
```bash
vim frontend-deployment.yaml
# (kopeeri sektsioonist 3.2)

kubectl apply -f frontend-deployment.yaml
```

3. **Kontrolli deployment-i:**
```bash
kubectl get deployment frontend -n production
kubectl get pods -n production -l app=frontend

# Peaks olema 2 Podi running
```

4. **Loo Service:**
```bash
vim frontend-service.yaml
# (kopeeri sektsioonist 4.1)

kubectl apply -f frontend-service.yaml

kubectl get service frontend -n production
```

5. **Testi Service-i:**
```bash
kubectl port-forward service/frontend 8080:80 -n production

# Teises terminalis
curl http://localhost:8080/health
# OK

curl http://localhost:8080/
# <html>...</html>
```

**Valideerimise checklist:**
- [ ] Frontend image built ja pushed
- [ ] Deployment loodud (2 replicas)
- [ ] Kõik Podid running ja ready
- [ ] Service loodud
- [ ] Health check töötab
- [ ] HTML leht kättesaadav

---

### Harjutus 2: Ingress Seadistamine

**Eesmärk:** Seadistada Ingress frontend ja backend jaoks

**Sammud:**

1. **Kontrolli Traefik:**
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
kubectl get service -n kube-system traefik
```

2. **Loo täielik Ingress:**
```bash
vim full-ingress.yaml
# (kopeeri sektsioonist 6.2)

kubectl apply -f full-ingress.yaml
```

3. **Kontrolli Ingress-i:**
```bash
kubectl get ingress -n production
kubectl describe ingress app-ingress -n production
```

4. **Testi routing-ut:**
```bash
# Frontend
curl http://93.127.213.242/
curl http://93.127.213.242/login.html

# Backend
curl http://93.127.213.242/api/health
curl http://93.127.213.242/api/users
```

5. **Testi browseris:**
- Ava: `http://93.127.213.242/`
- Peaks nägema frontend-i
- Registreeri kasutaja
- Logi sisse
- Vaata kasutajate nimekirja

**Valideerimise checklist:**
- [ ] Ingress loodud
- [ ] Ingress näitab ADDRESS (VPS IP)
- [ ] Frontend kättesaadav (/)
- [ ] Backend API kättesaadav (/api/health)
- [ ] Frontend saab backendiga suhelda
- [ ] Register/Login töötab

---

### Harjutus 3: HTTPS Let's Encrypt-iga (valikuline)

**EELDUS:** Sul on domeen mis osutab VPS-ile

**Sammud:**

1. **Seadista DNS:**
```bash
# Kontrolli, et domeen osutab VPS-ile
dig example.com +short
# 93.127.213.242
```

2. **Paigalda cert-manager:**
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

kubectl get pods -n cert-manager
```

3. **Loo ClusterIssuer:**
```bash
vim letsencrypt-issuer.yaml
# (kopeeri sektsioonist 7.2)
# MUUDA email oma emailiks

kubectl apply -f letsencrypt-issuer.yaml

kubectl get clusterissuer
```

4. **Uuenda Ingress TLS-iga:**
```bash
vim full-ingress-tls.yaml
# (kopeeri sektsioonist 7.3)
# MUUDA example.com oma domeeniks

kubectl apply -f full-ingress-tls.yaml
```

5. **Jälgi sertifikaadi loomist:**
```bash
# Jälgi certificate
watch kubectl get certificate -n production

# Vaata events
kubectl describe certificate <name> -n production

# Vaata loge
kubectl logs -n cert-manager deployment/cert-manager -f
```

6. **Testi HTTPS:**
```bash
curl https://example.com/
curl https://example.com/api/health

# Kontrolli sertifikaati
openssl s_client -connect example.com:443 -servername example.com
```

**Valideerimise checklist:**
- [ ] DNS osutab VPS-ile
- [ ] cert-manager paigaldatud
- [ ] ClusterIssuer loodud ja READY
- [ ] Certificate loodud ja READY
- [ ] Secret sertifikaadiga loodud
- [ ] HTTPS töötab
- [ ] Sertifikaat on valid (Let's Encrypt)
- [ ] HTTP → HTTPS redirect töötab

---

### Harjutus 4: Path-Based Routing (valikuline)

**Eesmärk:** Seadistada erinevad path-id erinevatele teenustele

**Sammud:**

1. **Loo teine frontend versioon (admin):**
```bash
cd /home/janek/projects/hostinger/labs/apps/frontend

# Kopeeri ja muuda
mkdir -p admin
echo "<h1>Admin Panel</h1>" > admin/index.html

# Loo lihtne Dockerfile
cat > admin/Dockerfile <<EOF
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cd admin
docker build -t localhost:5000/admin:1.0 .
docker push localhost:5000/admin:1.0
```

2. **Loo admin Deployment:**
```bash
vim admin-deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: admin
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: admin
  template:
    metadata:
      labels:
        app: admin
    spec:
      containers:
      - name: admin
        image: localhost:5000/admin:1.0
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: admin
  namespace: production
spec:
  selector:
    app: admin
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl apply -f admin-deployment.yaml
```

3. **Uuenda Ingress path-based routing-uga:**
```bash
vim multi-path-ingress.yaml
# (kopeeri sektsioonist 9.1)

kubectl apply -f multi-path-ingress.yaml
```

4. **Testi:**
```bash
curl http://93.127.213.242/
# Frontend index.html

curl http://93.127.213.242/admin
# <h1>Admin Panel</h1>

curl http://93.127.213.242/api/health
# {"status":"ok"}
```

**Valideerimise checklist:**
- [ ] Admin deployment loodud
- [ ] Ingress uuendatud path-based routing-uga
- [ ] / → frontend
- [ ] /admin → admin panel
- [ ] /api → backend

---

## Kokkuvõte

Selles peatükis õppisid:

✅ **Frontend Deployment:**
- Nginx container staatiliste failide jaoks
- Deployment manifest 2 replicaga
- Health checks Nginx-ile
- Resource limits

✅ **Frontend Service:**
- ClusterIP service sisemiseks ligipääsuks
- Service Discovery
- Endpoints kontrollimine

✅ **Ingress Controller:**
- Traefik K3s-is (default)
- Traefik dashboard
- EntryPoints (web, websecure)

✅ **Ingress Rules:**
- Host-based routing
- Path-based routing
- Frontend + Backend routing
- nip.io wildcard DNS

✅ **TLS/SSL:**
- cert-manager paigaldamine
- Let's Encrypt ClusterIssuer
- Automaatne sertifikaadi haldus
- HTTP → HTTPS redirect

✅ **Domain Management:**
- DNS seadistamine (A records)
- Subdomeenid
- Wildcard sertifikaadid

✅ **Path-Based Routing:**
- Mitu rakendust samas domeenis
- pathType: Prefix vs Exact
- Routing priority (järjekord)

---

## Järgmine Samm

**Peatükk 20: GitHub Actions CI/CD**
- GitHub Actions workflow süntaks
- Automated testing
- Docker image build ja push
- Kubernetes deployment automation
- Multi-environment (dev, staging, prod)

**Ressursid:**
- Kubernetes Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- Traefik: https://doc.traefik.io/traefik/
- cert-manager: https://cert-manager.io/docs/
- Let's Encrypt: https://letsencrypt.org/docs/

---

**VPS:** kirjakast @ 93.127.213.242
**Kasutaja:** janek
**Editor:** vim
**Ingress Controller:** Traefik (K3s default)

Edu! 🚀
