# Peatükk 22: Security Best Practices 🔒

**Kestus:** 4 tundi
**Eeldused:** Peatükk 21 läbitud
**Eesmärk:** Turvalisuse best practices rakendamine

---

## Sisukord

1. [Ülevaade](#1-ülevaade)
2. [Network Policies](#2-network-policies)
3. [Pod Security Standards](#3-pod-security-standards)
4. [Secrets Management](#4-secrets-management)
5. [Image Security Scanning](#5-image-security-scanning)
6. [OWASP Top 10](#6-owasp-top-10)
7. [Rate Limiting](#7-rate-limiting)
8. [Security Headers](#8-security-headers)
9. [Harjutused](#9-harjutused)

---

## 1. Ülevaade

### 1.1. Security Layers

```
┌─────────────────────────────────────────────┐
│         INFRASTRUCTURE SECURITY              │
│  - Firewall (ufw)                           │
│  - SSH key-based auth                       │
│  - fail2ban                                 │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│         NETWORK SECURITY                     │
│  - Network Policies (K8s)                   │
│  - TLS/SSL (cert-manager)                   │
│  - Private networks                         │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│         CONTAINER SECURITY                   │
│  - Pod Security Standards                   │
│  - Image scanning (Trivy)                   │
│  - Non-root users                           │
│  - Read-only filesystem                     │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│         APPLICATION SECURITY                 │
│  - OWASP Top 10                             │
│  - Input validation                         │
│  - SQL injection prevention                 │
│  - XSS prevention                           │
│  - CSRF tokens                              │
└─────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────┐
│         SECRETS MANAGEMENT                   │
│  - Kubernetes Secrets                       │
│  - Sealed Secrets                           │
│  - External Secrets (Vault)                 │
└─────────────────────────────────────────────┘
```

---

## 2. Network Policies

### 2.1. Mis on Network Policy?

**Network Policy:** Kubernetes firewall Pod-ide vahel

**Vaikimisi:** Kõik Podid saavad omavahel suhelda (no restrictions)

**Network Policy-ga:** Määra täpselt, kes saab kellega suhelda

### 2.2. Default Deny Policy

**Keela kõik ühendused, luba ainult vajalik:**

**Fail:** `default-deny-all.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}  # Kehtib kõigile Podidele
  policyTypes:
  - Ingress
  - Egress
```

**Rakenda:**
```bash
kubectl apply -f default-deny-all.yaml

# NB! Peale seda EI SAA enam ükski Pod ühendust (ka DNS ei tööta!)
# Peame lisama specific allow policies
```

### 2.3. Allow Backend → PostgreSQL

**Luba backend Podidel ühenduda PostgreSQL-iga:**

**Fail:** `allow-backend-to-postgres.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-postgres
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
```

### 2.4. Allow Frontend ← Ingress

**Luba Ingress suhelda frontend-iga:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: kube-system  # Traefik on kube-system-is
    ports:
    - protocol: TCP
      port: 80
```

### 2.5. Allow DNS

**Kõik Podid vajavad DNS-i:**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}  # Kõik Podid
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

### 2.6. Complete Network Policy Set

**Fail:** `network-policies.yaml`

```yaml
---
# 1. Default deny all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# 2. Allow DNS for all
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53

---
# 3. Allow backend → postgres
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-postgres
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432

---
# 4. Allow ingress → backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 3000

---
# 5. Allow ingress → frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 80

---
# 6. Allow backend egress (API calls, external DB)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

**Rakenda:**
```bash
kubectl apply -f network-policies.yaml

# Testi
kubectl exec -it -n production <backend-pod> -- curl http://postgres:5432
# Peaks töötama

kubectl exec -it -n production <backend-pod> -- curl http://google.com
# Peaks FAILIMA (kui ei ole lubatud)
```

---

## 3. Pod Security Standards

### 3.1. Pod Security Admission

**Kubernetes 1.25+:** Pod Security Admission (PSA) asendab PodSecurityPolicy

**3 taset:**
- **Privileged:** Pole piiranguid
- **Baseline:** Minimaalsed piirangud
- **Restricted:** Kõige turvalisem

### 3.2. Enforce Restricted Mode

**Label namespace:**
```bash
kubectl label namespace production \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

**Nüüd ei saa deployida privileeritud Podi:**
```yaml
# See FAILIB
spec:
  containers:
  - name: bad
    securityContext:
      privileged: true  # ❌ Not allowed in restricted mode
```

### 3.3. Secure Pod Manifest

**Fail:** `backend-deployment-secure.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      # Security Context Pod-level
      securityContext:
        runAsNonRoot: true        # Keela root user
        runAsUser: 1000           # User ID
        fsGroup: 1000             # File system group
        seccompProfile:
          type: RuntimeDefault    # Seccomp profile

      containers:
      - name: backend
        image: localhost:5000/backend:1.0

        # Security Context Container-level
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL                 # Drop kõik capabilities
          readOnlyRootFilesystem: true  # Read-only filesystem

        # Volume mounts writable paths
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/.npm

        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"

      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
```

### 3.4. Dockerfile Non-Root User

**Backend Dockerfile:**
```dockerfile
FROM node:18-alpine

# Loo non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser

WORKDIR /app

# Kopeeri files
COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Muuda ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

EXPOSE 3000

CMD ["node", "src/index.js"]
```

**Build:**
```bash
docker build -t localhost:5000/backend:secure .
docker push localhost:5000/backend:secure
```

---

## 4. Secrets Management

### 4.1. Kubernetes Secrets (Base64)

**Probleem:** Base64 ei ole encryption, ainult encoding

**Lae Secret:**
```bash
kubectl get secret backend-secret -n production -o yaml

# data:
#   DB_PASSWORD: cGFzc3dvcmQ=  ← base64, mitte encrypted!

echo "cGFzc3dvcmQ=" | base64 -d
# password  ← igaüks saab dekodeerida
```

### 4.2. Sealed Secrets

**Sealed Secrets:** Encrypted Secrets GitHubis

**Paigalda Sealed Secrets controller:**
```bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Paigalda kubeseal CLI
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar -xvzf kubeseal-0.24.0-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

**Loo Sealed Secret:**
```bash
# Loo tavalisSecret (ära commit see!)
kubectl create secret generic backend-secret \
  --from-literal=DB_PASSWORD=supersecret \
  --dry-run=client -o yaml > secret.yaml

# Encrypt kubeseal-iga
kubeseal --format=yaml < secret.yaml > sealed-secret.yaml

# Nüüd saad commit-ida sealed-secret.yaml (encrypted)
kubectl apply -f sealed-secret.yaml

# Sealed Secrets controller dekrüpteerib automaatselt Secret-iks
kubectl get secret backend-secret -n production
```

**sealed-secret.yaml näeb välja nii:**
```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: backend-secret
  namespace: production
spec:
  encryptedData:
    DB_PASSWORD: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEq...  ← encrypted!
```

### 4.3. External Secrets (HashiCorp Vault)

**External Secrets Operator:** Sünkroniseerib secrets Vault-ist K8s-i

**Quick setup:**
```bash
# Paigalda External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n kube-system

# Paigalda Vault (dev mode)
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --set "server.dev.enabled=true" -n vault --create-namespace
```

**SecretStore:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: production
spec:
  provider:
    vault:
      server: "http://vault.vault.svc.cluster.local:8200"
      path: "secret"
      version: "v2"
      auth:
        tokenSecretRef:
          name: "vault-token"
          key: "token"
```

**ExternalSecret:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: backend-secret
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: backend-secret
  data:
  - secretKey: DB_PASSWORD
    remoteRef:
      key: database
      property: password
```

---

## 5. Image Security Scanning

### 5.1. Trivy

**Paigalda Trivy:**
```bash
# VPS kirjakast
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install trivy
```

**Scanni image:**
```bash
trivy image localhost:5000/backend:1.0

# Output:
# Total: 245 (UNKNOWN: 5, LOW: 89, MEDIUM: 78, HIGH: 65, CRITICAL: 8)
```

**Scanni ainult CRITICAL ja HIGH:**
```bash
trivy image --severity CRITICAL,HIGH localhost:5000/backend:1.0
```

**Fail kui leitakse CRITICAL:**
```bash
trivy image --exit-code 1 --severity CRITICAL localhost:5000/backend:1.0

# Exit code 1 kui leitakse CRITICAL vulnerabilities
```

### 5.2. Trivy GitHub Actions-is

**Workflow:** `.github/workflows/security-scan.yml`

```yaml
name: Security Scan

on:
  push:
    branches: [main]
  pull_request:

jobs:
  trivy:
    name: Trivy Scan
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Build image
      run: |
        cd labs/apps/backend-nodejs
        docker build -t backend:test .

    - name: Run Trivy scan
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: backend:test
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'

    - name: Upload results to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'
```

### 5.3. Admission Controller (OPA Gatekeeper)

**Keela vulnerable images:**

```bash
# Paigalda Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

**ConstraintTemplate (näide):**
```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sblockimages
spec:
  crd:
    spec:
      names:
        kind: K8sBlockImages
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sblockimages
        violation[{"msg": msg}] {
          input.review.object.spec.containers[_].image
          not startswith(input.review.object.spec.containers[_].image, "localhost:5000/")
          msg := "Only images from localhost:5000 registry are allowed"
        }
```

---

## 6. OWASP Top 10

### 6.1. SQL Injection Prevention

**❌ BAD (vulnerable):**
```javascript
app.get('/users/:id', async (req, res) => {
  const query = `SELECT * FROM users WHERE id = ${req.params.id}`;  // ❌ SQL injection!
  const result = await pool.query(query);
  res.json(result.rows);
});
```

**✅ GOOD (safe):**
```javascript
app.get('/users/:id', async (req, res) => {
  const query = 'SELECT * FROM users WHERE id = $1';  // ✅ Parameterized
  const result = await pool.query(query, [req.params.id]);
  res.json(result.rows);
});
```

### 6.2. XSS Prevention

**Backend:** Validate and sanitize input

```javascript
const validator = require('validator');

app.post('/api/users', async (req, res) => {
  const { name, email } = req.body;

  // Validate
  if (!validator.isEmail(email)) {
    return res.status(400).json({ error: 'Invalid email' });
  }

  // Sanitize
  const sanitizedName = validator.escape(name);

  // Save
  await pool.query('INSERT INTO users (name, email) VALUES ($1, $2)', [sanitizedName, email]);
  res.json({ success: true });
});
```

**Frontend:** Escape output

```javascript
// ❌ BAD
document.getElementById('name').innerHTML = userData.name;  // XSS!

// ✅ GOOD
document.getElementById('name').textContent = userData.name;  // Safe
```

### 6.3. CSRF Protection

**Backend (Express):**
```bash
npm install csurf cookie-parser
```

```javascript
const csrf = require('csurf');
const cookieParser = require('cookie-parser');

app.use(cookieParser());
app.use(csrf({ cookie: true }));

// Send CSRF token to frontend
app.get('/api/csrf-token', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// Protected route
app.post('/api/users', (req, res) => {
  // CSRF token validated automatically
  // ...
});
```

**Frontend:**
```javascript
// Fetch CSRF token
const { csrfToken } = await fetch('/api/csrf-token').then(r => r.json());

// Include in requests
fetch('/api/users', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'CSRF-Token': csrfToken
  },
  body: JSON.stringify(data)
});
```

### 6.4. Authentication Best Practices

**Password hashing (bcrypt):**
```javascript
const bcrypt = require('bcrypt');

// Register
const hashedPassword = await bcrypt.hash(password, 10);  // 10 rounds
await pool.query('INSERT INTO users (email, password) VALUES ($1, $2)', [email, hashedPassword]);

// Login
const user = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
const valid = await bcrypt.compare(password, user.rows[0].password);
```

**JWT Best Practices:**
```javascript
const jwt = require('jsonwebtoken');

// Short expiry
const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, {
  expiresIn: '1h'  // ✅ Short expiry
});

// Verify
const decoded = jwt.verify(token, process.env.JWT_SECRET);
```

---

## 7. Rate Limiting

### 7.1. Express Rate Limit

**Paigalda:**
```bash
npm install express-rate-limit
```

**Rakenda:**
```javascript
const rateLimit = require('express-rate-limit');

// General rate limit
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 100,                   // Max 100 requests per window
  message: 'Too many requests, please try again later'
});

// Login rate limit (stricter)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,                     // Max 5 login attempts
  skipSuccessfulRequests: true
});

app.use('/api', generalLimiter);
app.use('/api/auth/login', loginLimiter);
```

### 7.2. Traefik Rate Limiting

**Ingress annotation:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: production
  annotations:
    traefik.ingress.kubernetes.io/rate-limit: |
      average: 100
      burst: 200
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend
            port:
              number: 3000
```

---

## 8. Security Headers

### 8.1. Helmet (Express)

**Paigalda:**
```bash
npm install helmet
```

**Rakenda:**
```javascript
const helmet = require('helmet');

app.use(helmet());

// VÕI custom config
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));
```

**Headers lisatud:**
- `X-DNS-Prefetch-Control`
- `X-Frame-Options: DENY`
- `Strict-Transport-Security`
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection`

### 8.2. Nginx Security Headers (Frontend)

**nginx.conf:**
```nginx
server {
    listen 80;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';" always;

    # HSTS (kui HTTPS)
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

## 9. Harjutused

### Harjutus 1: Network Policies

**Eesmärk:** Rakenda network policies

```bash
vim network-policies.yaml
# (kopeeri sektsioonist 2.6)

kubectl apply -f network-policies.yaml

# Testi
kubectl exec -n production <backend-pod> -- curl -m 5 postgres:5432
# Peaks töötama

kubectl exec -n production <frontend-pod> -- curl -m 5 postgres:5432
# Peaks FAILIMA (frontend ei saa ühendust postgres-iga)
```

**Valideerimise checklist:**
- [ ] Network policies rakendatud
- [ ] Backend → PostgreSQL töötab
- [ ] Frontend → PostgreSQL blokitud
- [ ] DNS töötab kõigile

---

### Harjutus 2: Secure Pod Configuration

**Eesmärk:** Deployida secure Pod

```bash
# Label namespace
kubectl label namespace production pod-security.kubernetes.io/enforce=restricted

# Muuda Dockerfile non-root user-iks
vim labs/apps/backend-nodejs/Dockerfile
# Lisa USER appuser

# Build
docker build -t localhost:5000/backend:secure .
docker push localhost:5000/backend:secure

# Deploy secure manifest
vim backend-deployment-secure.yaml
# (kopeeri sektsioonist 3.3)

kubectl apply -f backend-deployment-secure.yaml
```

**Valideerimise checklist:**
- [ ] Namespace labeled restricted
- [ ] Dockerfile kasutab non-root user-it
- [ ] Pod securityContext correct
- [ ] readOnlyRootFilesystem: true
- [ ] Pod käivitub edukalt

---

### Harjutus 3: Trivy Image Scanning

**Eesmärk:** Scanni images vulnerabilities jaoks

```bash
# Paigalda Trivy
sudo apt install trivy

# Scanni backend
trivy image localhost:5000/backend:1.0

# Scanni ainult CRITICAL
trivy image --severity CRITICAL,HIGH localhost:5000/backend:1.0

# Fail kui CRITICAL
trivy image --exit-code 1 --severity CRITICAL localhost:5000/backend:1.0
```

**Valideerimise checklist:**
- [ ] Trivy paigaldatud
- [ ] Image scanitud
- [ ] Vulnerabilities leitud
- [ ] Exit code 1 kui CRITICAL

---

## Kokkuvõte

Selles peatükis õppisid:

✅ **Network Policies:** Pod-to-Pod firewall
✅ **Pod Security:** Non-root, read-only, capabilities drop
✅ **Secrets Management:** Sealed Secrets, External Secrets
✅ **Image Scanning:** Trivy vulnerability detection
✅ **OWASP Top 10:** SQL injection, XSS, CSRF
✅ **Rate Limiting:** Express ja Traefik
✅ **Security Headers:** Helmet, Nginx headers

---

## Järgmine Samm

**Peatükk 23: Troubleshooting ja Debugging**

**Ressursid:**
- OWASP: https://owasp.org/www-project-top-ten/
- Trivy: https://github.com/aquasecurity/trivy
- Sealed Secrets: https://github.com/bitnami-labs/sealed-secrets

---

**VPS:** kirjakast @ 93.127.213.242
**Kasutaja:** janek
**Security:** Defense in depth

Edu! 🚀
