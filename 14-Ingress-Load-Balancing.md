# Peatükk 14: Ingress ja Load Balancing

**Kestus:** 4 tundi
**Eeldused:** Peatükk 9-13 (Kubernetes core)
**Eesmärk:** Mõista Ingress arhitektuuri ja HTTP load balancing'u Kubernetes'es

---

## Õpieesmärgid

- Mõista Ingress vs Service erinevust
- Ingress Controller arhitektuur (Traefik, Nginx)
- Path-based ja host-based routing
- TLS/SSL termination
- cert-manager ja Let's Encrypt automaatne SSL
- Load balancing strateegiad

---

## 14.1 Ingress vs Service

### Probleem: NodePort ja LoadBalancer Piirangud

**Scenario:** 3 mikroteenust (frontend, backend, api)

**❌ Lahendus 1: NodePort (iga teenuse jaoks)**

```yaml
# Frontend Service (port 30001)
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 30001

# Backend Service (port 30002)
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  type: NodePort
  ports:
  - port: 3000
    nodePort: 30002
```

**Probleemid:**
- Kasutaja peab meelde jätma portid: `http://vps:30001`, `http://vps:30002`
- Ei saa kasutada domeene: `frontend.example.com`, `backend.example.com`
- Pole SSL'i (HTTPS)
- Port range: 30000-32767 (limited)

---

**❌ Lahendus 2: LoadBalancer (iga teenuse jaoks)**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: LoadBalancer
  ports:
  - port: 80
```

**Probleemid:**
- Cloud'is: **1 LoadBalancer = 1 IP = $10-20/month**
- 3 teenust = 3 LoadBalancer'it = $30-60/month
- Kallis!

---

**✅ Lahendus 3: Ingress (1 entry point kõigile teenustele)**

```
Internet → Ingress Controller (80, 443)
            ├─ frontend.example.com → frontend Service
            ├─ api.example.com → backend Service
            └─ example.com/blog → blog Service

1 IP address
1 SSL certificate (wildcard *.example.com)
Unlimited services (path/host routing)
```

**Benefit:**
- **Kulude kokkuhoid:** 1 LoadBalancer vs N LoadBalancer'it
- **Centralized SSL:** cert-manager halda kõik sertifikaadid
- **Intelligent routing:** URL-based (domain, path)
- **Features:** Rate limiting, auth, rewrite rules

---

## 14.2 Ingress Arhitektuur

### Komponendid

**1. Ingress Resource (YAML config):**

```yaml
# Kirjeldab routing rules (mis URL → milline Service)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
spec:
  rules:
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

**2. Ingress Controller (Pod, jookseb cluster'is):**

```
Ingress Controller:
  - Loeb Ingress resource'e (watch API)
  - Genereerib reverse proxy config (Nginx, Traefik)
  - Proxy HTTP traffic → Services
  - Load balancing
  - SSL termination
```

**Popular controllers:**
- **Traefik** (K3s default, modern, auto-SSL)
- **Nginx Ingress Controller** (most popular, mature)
- **HAProxy Ingress**
- **Istio Gateway** (service mesh)
- **AWS ALB Ingress** (AWS-native)

---

### Workflow

```
1. Create Ingress resource (YAML)
   ↓
2. Ingress Controller detects new Ingress
   ↓
3. Controller generates reverse proxy config
   (Nginx: nginx.conf, Traefik: dynamic config)
   ↓
4. Controller reloads config
   ↓
5. Traffic flows:
   User → Ingress Controller → Service → Pod
```

**Example:**

```
User: curl https://api.example.com/users
  ↓
Ingress Controller (Traefik Pod):
  - SSL termination (HTTPS → HTTP)
  - Match rule: host=api.example.com, path=/
  - Forward to: backend Service (ClusterIP)
  ↓
backend Service:
  - Load balance to backend Pod
  ↓
backend Pod:
  - Return response
```

---

## 14.3 Traefik Ingress (K3s Default)

### Traefik Arhitektuur

**K3s comes with Traefik pre-installed!**

```bash
# Check Traefik deployment
kubectl get pods -n kube-system | grep traefik

# Traefik Service (LoadBalancer)
kubectl get svc -n kube-system traefik

# Output:
NAME      TYPE           EXTERNAL-IP   PORT(S)
traefik   LoadBalancer   10.43.0.1     80:30080/TCP,443:30443/TCP
```

**Traefik features:**
- **Auto-discovery:** Watches Ingress resources automatically
- **Dashboard:** Web UI (http://vps:9000/dashboard/)
- **Let's Encrypt:** Built-in ACME client (auto SSL)
- **Middlewares:** Auth, rate limiting, redirect, headers

---

### Basic Ingress - Single Domain

```yaml
# backend-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
  annotations:
    # Traefik-specific annotations
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  rules:
  - host: api.example.com  # Domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backend  # Service name
            port:
              number: 3000
```

**Apply:**

```bash
kubectl apply -f backend-ingress.yaml

# Check Ingress
kubectl get ingress
# NAME              HOSTS             ADDRESS      PORTS
# backend-ingress   api.example.com   10.43.0.1    80
```

**Test:**

```bash
# Add DNS or /etc/hosts
echo "YOUR_VPS_IP api.example.com" | sudo tee -a /etc/hosts

# Test
curl http://api.example.com/health
# {"status":"healthy"}
```

📖 **Praktika:** Labor 4, Harjutus 1 - Traefik Ingress setup

---

### Multi-Path Routing (Same Domain)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
  - host: example.com
    http:
      paths:
      # Frontend (/)
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80

      # Backend API (/api)
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 3000

      # Admin (/admin)
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin
            port:
              number: 8080
```

**Routing:**

```
http://example.com/           → frontend Service
http://example.com/api/users  → backend Service
http://example.com/admin/     → admin Service
```

**pathType options:**
- `Prefix`: Matches path prefix (e.g., `/api` matches `/api/users`)
- `Exact`: Matches exact path only (e.g., `/api` does NOT match `/api/users`)

---

### Multi-Host Routing (Subdomains)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  rules:
  # Frontend subdomain
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

  # API subdomain
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

  # Admin subdomain
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin
            port:
              number: 8080
```

**Routing:**

```
http://www.example.com/   → frontend Service
http://api.example.com/   → backend Service
http://admin.example.com/ → admin Service
```

---

## 14.4 TLS/SSL Termination

### Manual SSL Certificate

**1. Generate self-signed cert (DEV ONLY):**

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=api.example.com/O=MyOrg"
```

**2. Create Kubernetes Secret:**

```bash
kubectl create secret tls api-tls \
  --cert=tls.crt \
  --key=tls.key
```

**3. Reference Secret in Ingress:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls  # References Secret
  rules:
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

**Test:**

```bash
curl -k https://api.example.com/health
# (-k flag ignores self-signed cert warning)
```

---

## 14.5 Automatic SSL with cert-manager

### cert-manager Arhitektuur

**cert-manager = Kubernetes add-on for automatic SSL**

```
cert-manager components:
  1. Issuer/ClusterIssuer (defines CA: Let's Encrypt, self-signed)
  2. Certificate (defines domain, secret name)
  3. cert-manager controller (watches, requests, renews certs)

Workflow:
  1. Create Ingress with TLS
  2. cert-manager detects TLS config
  3. Requests certificate from Let's Encrypt (ACME challenge)
  4. Let's Encrypt validates domain (HTTP-01 or DNS-01)
  5. cert-manager stores cert in Secret
  6. Ingress uses Secret for HTTPS
  7. Auto-renewal before expiry (90 days → renew at 60 days)
```

---

### Install cert-manager

```bash
# Install cert-manager CRDs and controller
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Check installation
kubectl get pods -n cert-manager

# Output:
# cert-manager-*
# cert-manager-cainjector-*
# cert-manager-webhook-*
```

---

### Create ClusterIssuer (Let's Encrypt)

```yaml
# letsencrypt-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com  # Your email for notifications
    privateKeySecretRef:
      name: letsencrypt-prod-key  # Secret to store ACME account key
    solvers:
    - http01:
        ingress:
          class: traefik  # Use Traefik for HTTP-01 challenge
```

**Apply:**

```bash
kubectl apply -f letsencrypt-issuer.yaml

# Check issuer
kubectl get clusterissuer
# NAME               READY
# letsencrypt-prod   True
```

---

### Ingress with Auto-SSL

```yaml
# backend-ingress-ssl.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod  # Use Let's Encrypt
    traefik.ingress.kubernetes.io/router.entrypoints: websecure  # HTTPS
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls  # cert-manager creates this Secret
  rules:
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

**Apply:**

```bash
kubectl apply -f backend-ingress-ssl.yaml

# Check certificate
kubectl get certificate
# NAME      READY   SECRET    AGE
# api-tls   True    api-tls   2m

# Check secret
kubectl get secret api-tls
# Contains: tls.crt, tls.key (auto-generated by cert-manager!)
```

**Test:**

```bash
curl https://api.example.com/health
# HTTPS works! (valid Let's Encrypt certificate)
```

**HTTP → HTTPS Redirect:**

```yaml
# Redirect HTTP to HTTPS automatically
metadata:
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-redirect-https@kubernetescrd

---
# Middleware for redirect
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: redirect-https
spec:
  redirectScheme:
    scheme: https
    permanent: true
```

📖 **Praktika:** Labor 4, Harjutus 2 - cert-manager + Let's Encrypt

---

## 14.6 Nginx Ingress Controller

### Traefik vs Nginx Ingress

| Feature | Traefik | Nginx Ingress |
|---------|---------|---------------|
| **Default in** | K3s | Manual install |
| **Config** | Dynamic (auto-reload) | Reload required |
| **Dashboard** | ✅ Built-in | ❌ No UI |
| **Let's Encrypt** | ✅ Built-in | Requires cert-manager |
| **Middlewares** | ✅ Native | Via annotations |
| **Learning curve** | Easy | Medium |
| **Community** | Smaller | Larger (most popular) |
| **Performance** | Good | Excellent (Nginx optimized) |
| **Best for** | K3s, small clusters | Large production clusters |

**When to use Nginx:**
- Larger production clusters (1000+ services)
- Need Nginx ecosystem (Lua scripts, modules)
- Already familiar with Nginx config

**When to use Traefik:**
- K3s (comes pre-installed)
- Prefer modern, dynamic config
- Like built-in dashboard

---

### Install Nginx Ingress

```bash
# Install via Helm
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# Check installation
kubectl get pods -n ingress-nginx
# ingress-nginx-controller-*
```

---

### Nginx Ingress Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
  annotations:
    kubernetes.io/ingress.class: nginx  # Use Nginx controller
    nginx.ingress.kubernetes.io/rewrite-target: /  # URL rewrite
    nginx.ingress.kubernetes.io/ssl-redirect: "true"  # Force HTTPS
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls
  rules:
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

**Common Nginx annotations:**

```yaml
annotations:
  # Rate limiting
  nginx.ingress.kubernetes.io/rate-limit: "100"  # 100 req/min

  # CORS
  nginx.ingress.kubernetes.io/enable-cors: "true"

  # Basic Auth
  nginx.ingress.kubernetes.io/auth-type: basic
  nginx.ingress.kubernetes.io/auth-secret: basic-auth

  # Client body size (upload limit)
  nginx.ingress.kubernetes.io/proxy-body-size: "50m"

  # Timeout
  nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
```

---

## 14.7 Load Balancing Strategies

### Service Load Balancing (kube-proxy)

**Default: Round-robin**

```
Ingress Controller → backend Service (ClusterIP)
                      ├─ Pod 1 (request 1)
                      ├─ Pod 2 (request 2)
                      └─ Pod 3 (request 3)
                         Pod 1 (request 4)  ← Round-robin
```

**Session affinity (sticky sessions):**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  sessionAffinity: ClientIP  # Same client IP → same Pod
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600  # 1 hour
  ports:
  - port: 3000
  selector:
    app: backend
```

**Use case:** Stateful applications (sessions stored in memory)

---

### Ingress Controller Load Balancing

**Nginx Ingress: Load balancing algorithms**

```yaml
annotations:
  # Least connections
  nginx.ingress.kubernetes.io/upstream-hash-by: "$request_uri"

  # IP hash (same IP → same backend)
  nginx.ingress.kubernetes.io/upstream-hash-by: "$remote_addr"
```

**Traefik: Weighted round-robin**

```yaml
# TraefikService (advanced load balancing)
apiVersion: traefik.containo.us/v1alpha1
kind: TraefikService
metadata:
  name: backend-weighted
spec:
  weighted:
    services:
    - name: backend-v1
      weight: 80  # 80% traffic
      port: 3000
    - name: backend-v2
      weight: 20  # 20% traffic (canary)
      port: 3000
```

**Use case:** Canary deployments (gradual rollout)

---

## 14.8 Advanced Features

### Rate Limiting

**Nginx Ingress:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"  # 10 requests/second
    nginx.ingress.kubernetes.io/limit-connections: "50"  # Max 50 concurrent
```

**Traefik Middleware:**

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: rate-limit
spec:
  rateLimit:
    average: 100  # 100 req/sec
    burst: 200    # Allow burst up to 200

---
# Apply to Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-rate-limit@kubernetescrd
```

---

### Basic Authentication

**Create htpasswd secret:**

```bash
# Generate htpasswd file
htpasswd -c auth admin
# Password: ********

# Create Secret
kubectl create secret generic basic-auth --from-file=auth
```

**Nginx Ingress:**

```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-type: basic
  nginx.ingress.kubernetes.io/auth-secret: basic-auth
  nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

**Traefik Middleware:**

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
spec:
  basicAuth:
    secret: basic-auth  # Reference Secret
```

---

### Custom Error Pages

**Nginx:**

```yaml
annotations:
  nginx.ingress.kubernetes.io/custom-http-errors: "404,503"
  nginx.ingress.kubernetes.io/default-backend: error-pages
```

---

## Kokkuvõte

**Ingress:**
- **Purpose:** HTTP/HTTPS routing and load balancing (L7)
- **Benefit:** 1 entry point for multiple Services (cost-effective)
- **Components:** Ingress resource (YAML) + Ingress Controller (Pod)

**Ingress Controllers:**
- **Traefik:** K3s default, modern, auto-SSL, dashboard
- **Nginx:** Most popular, mature, high performance
- **Others:** HAProxy, Istio, AWS ALB, GCP Ingress

**Routing:**
- **Path-based:** `/api`, `/admin`, `/` (same domain)
- **Host-based:** `api.example.com`, `www.example.com` (subdomains)
- **TLS/SSL:** Manual certs or auto (cert-manager + Let's Encrypt)

**cert-manager:**
- **Automated SSL:** Let's Encrypt integration (ACME)
- **Auto-renewal:** Renews certs before expiry (90 days → renew at 60)
- **Challenge types:** HTTP-01 (Ingress), DNS-01 (wildcard)

**Load balancing:**
- **kube-proxy:** Round-robin (default), session affinity (ClientIP)
- **Ingress Controller:** Weighted, least connections, IP hash

**Advanced features:**
- Rate limiting
- Basic auth
- CORS
- Redirects (HTTP → HTTPS)
- Custom error pages

---

**DevOps Vaatenurk:**

```bash
# Check Traefik
kubectl get svc -n kube-system traefik

# Create Ingress
kubectl apply -f ingress.yaml

# Check Ingress
kubectl get ingress
kubectl describe ingress myapp-ingress

# Check cert-manager certificate
kubectl get certificate
kubectl describe certificate api-tls

# Test HTTPS
curl -v https://api.example.com/health

# Traefik dashboard
kubectl port-forward -n kube-system svc/traefik 9000:9000
# Open: http://localhost:9000/dashboard/
```

---

**Järgmised Sammud:**
**Peatükk 15:** GitHub Actions Basics (CI/CD)
**Peatükk 16:** Docker Build Automation

📖 **Praktika:** Labor 4 - Ingress, SSL, cert-manager, multi-service routing
