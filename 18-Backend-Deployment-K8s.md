# Peatükk 18: Backend Deployment Kubernetes-es ☸️

**Kestus:** 4 tundi
**Eeldused:** Peatükk 16 ja 17 läbitud, PostgreSQL K8s-es deployitud
**Eesmärk:** Deployida Node.js backend Kubernetes-es mõlema PostgreSQL variandiga

---

## Sisukord

1. [Ülevaade](#1-ülevaade)
2. [ConfigMap Keskkonnamuutujatele](#2-configmap-keskkonnamuutujatele)
3. [Secrets Mandaatidele](#3-secrets-mandaatidele)
4. [Backend Deployment Manifest](#4-backend-deployment-manifest)
5. [Service Backend-ile](#5-service-backend-ile)
6. [Health Checks ja Probes](#6-health-checks-ja-probes)
7. [Resource Limits ja Requests](#7-resource-limits-ja-requests)
8. [HorizontalPodAutoscaler](#8-horizontalpodautoscaler)
9. [Rolling Updates ja Rollbacks](#9-rolling-updates-ja-rollbacks)
10. [Harjutused](#10-harjutused)

---

## 1. Ülevaade

### 1.1. Deployment Arhitektuur

**PRIMAARNE: StatefulSet PostgreSQL**
```
┌──────────────────────────────────┐
│   KUBERNETES CLUSTER (kirjakast) │
│                                  │
│  ┌────────────────────────┐      │
│  │  Ingress Controller    │      │
│  │  (Traefik)             │      │
│  └──────────┬─────────────┘      │
│             │                    │
│  ┌──────────▼─────────────┐      │
│  │  Backend Service       │      │
│  │  (ClusterIP: 3000)     │      │
│  └──────────┬─────────────┘      │
│             │                    │
│  ┌──────────▼─────────────┐      │
│  │  Backend Deployment    │      │
│  │  (Replicas: 3)         │      │
│  │  - Pod 1 (backend)     │      │
│  │  - Pod 2 (backend)     │──┐   │
│  │  - Pod 3 (backend)     │  │   │
│  └────────────────────────┘  │   │
│             │                │   │
│  ┌──────────▼─────────────┐  │   │
│  │  PostgreSQL Service    │  │   │
│  │  (ClusterIP: 5432)     │  │   │
│  └──────────┬─────────────┘  │   │
│             │                │   │
│  ┌──────────▼─────────────┐  │   │
│  │  PostgreSQL StatefulSet│  │   │
│  │  - postgres-0          │  │   │
│  │    ↓                   │  │   │
│  │  PersistentVolume      │  │   │
│  └────────────────────────┘  │   │
│                              │   │
│  ConfigMaps & Secrets ───────┘   │
│                                  │
└──────────────────────────────────┘
```

**ALTERNATIIV: Väline PostgreSQL**
```
┌──────────────────────────────────┐
│   KUBERNETES CLUSTER (kirjakast) │
│                                  │
│  ┌────────────────────────┐      │
│  │  Backend Deployment    │      │
│  │  (Replicas: 3)         │      │
│  └──────────┬─────────────┘      │
│             │                    │
│  ┌──────────▼─────────────┐      │
│  │  ExternalName Service  │      │
│  │  postgres              │      │
│  └──────────┬─────────────┘      │
└─────────────┼────────────────────┘
              │
              │ SSL/TLS
              ▼
   ┌────────────────────┐
   │ Väline PostgreSQL  │
   │ db.example.com     │
   └────────────────────┘
```

### 1.2. Backend Spetsifikatsioon

VPS kirjakast-is asuva backend teenuse kirjeldus:

```bash
# Backend rakendus
Path:         /home/janek/projects/hostinger/labs/apps/backend-nodejs
Technology:   Node.js 18 + Express 4.18
Port:         3000
Database:     PostgreSQL (pg 8.11)
Auth:         JWT (jsonwebtoken 9.0)

# Võtmefunktsioonid
- User registration ja login
- JWT autentimine
- Password hashing (bcrypt)
- Health check endpoint (/health)
- Readiness check endpoint (/ready)
```

---

## 2. ConfigMap Keskkonnamuutujatele

### 2.1. Mis on ConfigMap?

**ConfigMap** on Kubernetes ressurss mittesalajase konfiguratsioonandmete hoidmiseks.

**Kasutatakse:**
- Keskkonnamuutujad (non-sensitive)
- Konfiguratsioonifailid
- Käsurea argumendid

**EI kasutata:**
- Paroolid, API võtmed → kasuta Secrets

### 2.2. Backend ConfigMap - PRIMAARNE Variant

**Fail:** `backend-configmap-primary.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: production
  labels:
    app: backend
    environment: production
data:
  # Node.js konfiguratsioon
  NODE_ENV: "production"
  PORT: "3000"

  # PostgreSQL ühendus (StatefulSet)
  DB_HOST: "postgres"              # StatefulSet Service nimi
  DB_PORT: "5432"
  DB_NAME: "appdb"

  # JWT konfiguratsioon (non-sensitive)
  JWT_EXPIRES_IN: "24h"

  # Logging
  LOG_LEVEL: "info"

  # CORS
  CORS_ORIGIN: "https://example.com"
```

**Rakenda:**
```bash
# Loo namespace
kubectl create namespace production

# Rakenda ConfigMap
kubectl apply -f backend-configmap-primary.yaml

# Kontrolli
kubectl get configmap -n production
kubectl describe configmap backend-config -n production
```

### 2.3. Backend ConfigMap - ALTERNATIIV Variant

**Fail:** `backend-configmap-external.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: production
  labels:
    app: backend
    environment: production
data:
  # Node.js konfiguratsioon
  NODE_ENV: "production"
  PORT: "3000"

  # PostgreSQL ühendus (VÄLINE)
  DB_HOST: "db.example.com"        # Väline hostname
  DB_PORT: "5432"
  DB_NAME: "appdb"
  DB_SSL: "true"                   # SSL nõutud välisele

  # JWT konfiguratsioon
  JWT_EXPIRES_IN: "24h"

  # Logging
  LOG_LEVEL: "info"

  # CORS
  CORS_ORIGIN: "https://example.com"
```

**Oluline erinevus:**
- `DB_HOST` viitab välisele hostnamele
- `DB_SSL: "true"` - SSL/TLS kohustuslik

---

## 3. Secrets Mandaatidele

### 3.1. Secrets vs ConfigMaps

| Aspekt | ConfigMap | Secret |
|--------|-----------|--------|
| **Andmed** | Avalikud/mittesalajased | Salajased |
| **Näited** | PORT, LOG_LEVEL | Paroolid, API võtmed |
| **Encoding** | Plain text | Base64 |
| **Turvalisus** | Pole krüpteeritud | Encrypted at rest (kui seadistatud) |

### 3.2. Backend Secrets - PRIMAARNE Variant

**Loo Secret käsurealt:**
```bash
# Base64 encode väärtused
echo -n "appuser" | base64
# YXBwdXNlcg==

echo -n "supersecretpassword" | base64
# c3VwZXJzZWNyZXRwYXNzd29yZA==

echo -n "my-super-secret-jwt-key-change-this-in-production" | base64
# bXktc3VwZXItc2VjcmV0LWp3dC1rZXktY2hhbmdlLXRoaXMtaW4tcHJvZHVjdGlvbg==
```

**Fail:** `backend-secret-primary.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
  namespace: production
  labels:
    app: backend
type: Opaque
data:
  # PostgreSQL mandaadid (base64)
  DB_USER: YXBwdXNlcg==                                           # appuser
  DB_PASSWORD: c3VwZXJzZWNyZXRwYXNzd29yZA==                       # supersecretpassword

  # JWT secret (base64)
  JWT_SECRET: bXktc3VwZXItc2VjcmV0LWp3dC1rZXktY2hhbmdlLXRoaXMtaW4tcHJvZHVjdGlvbg==
```

**VÕI kasuta `stringData` (automaatne base64):**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
  namespace: production
  labels:
    app: backend
type: Opaque
stringData:
  DB_USER: "appuser"
  DB_PASSWORD: "supersecretpassword"
  JWT_SECRET: "my-super-secret-jwt-key-change-this-in-production"
```

**Rakenda:**
```bash
kubectl apply -f backend-secret-primary.yaml

# Kontrolli (ei näita väärtusi)
kubectl get secret -n production
kubectl describe secret backend-secret -n production

# Vaata väärtusi (ainult testimiseks!)
kubectl get secret backend-secret -n production -o yaml
kubectl get secret backend-secret -n production -o jsonpath='{.data.DB_USER}' | base64 -d
```

### 3.3. Backend Secrets - ALTERNATIIV Variant

**Fail:** `backend-secret-external.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
  namespace: production
  labels:
    app: backend
type: Opaque
stringData:
  # PostgreSQL mandaadid (väline DB)
  DB_USER: "prod_user"
  DB_PASSWORD: "complex-production-password-123"

  # JWT secret
  JWT_SECRET: "my-super-secret-jwt-key-change-this-in-production"

  # SSL sertifikaat (kui vaja)
  DB_SSL_CA: |
    -----BEGIN CERTIFICATE-----
    MIIDdzCCAl+gAwIBAgIEAgAAuTANBgkqhkiG9w0BAQUFADBaMQswCQYDVQQGEwJJ
    ... (CA sertifikaat) ...
    -----END CERTIFICATE-----
```

---

## 4. Backend Deployment Manifest

### 4.1. PRIMAARNE: StatefulSet PostgreSQL-iga

**Fail:** `backend-deployment-primary.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: production
  labels:
    app: backend
    version: v1
spec:
  replicas: 3                    # 3 koopiat kõrge kättesaadavuse jaoks
  selector:
    matchLabels:
      app: backend
  strategy:
    type: RollingUpdate          # Rolling update strateegia
    rollingUpdate:
      maxSurge: 1                # Max 1 täiendav Pod update ajal
      maxUnavailable: 0          # 0 unavailable Podi (zero downtime)
  template:
    metadata:
      labels:
        app: backend
        version: v1
    spec:
      containers:
      - name: backend
        image: localhost:5000/backend:1.0    # Kohalik registry (Peatükk 15)
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 3000
          protocol: TCP

        # Keskkonnamuutujad ConfigMap-ist
        envFrom:
        - configMapRef:
            name: backend-config

        # Salajased keskkonnamuutujad Secret-ist
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: backend-secret
              key: DB_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: backend-secret
              key: DB_PASSWORD
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: backend-secret
              key: JWT_SECRET

        # Health checks (vaata sektsiooni 6)
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2

        # Resource limits (vaata sektsiooni 7)
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"

      # Restart policy
      restartPolicy: Always
```

**Rakenda:**
```bash
# Kontrolli, et ConfigMap ja Secret on olemas
kubectl get configmap backend-config -n production
kubectl get secret backend-secret -n production

# Rakenda Deployment
kubectl apply -f backend-deployment-primary.yaml

# Jälgi deployment progressi
kubectl rollout status deployment/backend -n production

# Kontrolli Podi staatust
kubectl get pods -n production -l app=backend
kubectl describe pod <pod-name> -n production

# Vaata loge
kubectl logs -n production -l app=backend --tail=50 -f
```

### 4.2. ALTERNATIIV: Väline PostgreSQL

**Fail:** `backend-deployment-external.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: production
  labels:
    app: backend
    version: v1
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: backend
        version: v1
    spec:
      containers:
      - name: backend
        image: localhost:5000/backend:1.0
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 3000
          protocol: TCP

        # ConfigMap (väline variant)
        envFrom:
        - configMapRef:
            name: backend-config

        # Secrets (väline variant)
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: backend-secret
              key: DB_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: backend-secret
              key: DB_PASSWORD
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: backend-secret
              key: JWT_SECRET

        # SSL CA sertifikaat (kui vaja)
        - name: DB_SSL_CA
          valueFrom:
            secretKeyRef:
              name: backend-secret
              key: DB_SSL_CA
              optional: true

        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2

        # Resources
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"

      restartPolicy: Always
```

**Peamine erinevus:**
- `DB_SSL_CA` keskkonna muutuja SSL sertifikaadi jaoks
- `DB_HOST` ConfigMap-is viitab välisele hostnamele

---

## 5. Service Backend-ile

### 5.1. ClusterIP Service

**Fail:** `backend-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: production
  labels:
    app: backend
spec:
  type: ClusterIP          # Sisemine service (ei ole väljaspoolt kättesaadav)
  selector:
    app: backend           # Suunab kõik backend Podid
  ports:
  - name: http
    port: 3000             # Service port
    targetPort: 3000       # Container port
    protocol: TCP
  sessionAffinity: None    # Ei hoia sessiooni sama Podi küljes
```

**Rakenda:**
```bash
kubectl apply -f backend-service.yaml

# Kontrolli
kubectl get service backend -n production
kubectl describe service backend -n production

# Vaata endpoints (peaks näitama kõiki backend Podide IP-sid)
kubectl get endpoints backend -n production
```

**Testi Service-i:**
```bash
# Käivita test Pod samasse namespace-i
kubectl run -it --rm debug --image=alpine --restart=Never -n production -- sh

# Test Podi sees
apk add --no-cache curl
curl http://backend:3000/health
# {"status":"ok","timestamp":"...","uptime":...}

exit
```

### 5.2. Service Discovery

Kubernetes DNS lahendab automaatselt:
```
backend                          → backend.production.svc.cluster.local
backend.production               → backend.production.svc.cluster.local
backend.production.svc           → backend.production.svc.cluster.local
backend.production.svc.cluster.local
```

**Näide backend-ist PostgreSQL-i ühendamine:**
```javascript
// PRIMAARNE: StatefulSet
const dbHost = process.env.DB_HOST; // "postgres"
// Kubernetes DNS: postgres.production.svc.cluster.local

// ALTERNATIIV: Väline
const dbHost = process.env.DB_HOST; // "db.example.com"
// Kubernetes ExternalName Service
```

---

## 6. Health Checks ja Probes

### 6.1. Liveness Probe

**Eesmärk:** Kontrollida, kas container töötab korrektselt

**Kui Liveness Probe ebaõnnestub:**
- Kubernetes taaskäivitab container-i

**Backend health endpoint:**
```javascript
// labs/apps/backend-nodejs/src/index.js

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});
```

**Manifest:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30    # Oota 30s enne esimest kontrolli
  periodSeconds: 10          # Kontrolli iga 10s
  timeoutSeconds: 5          # Timeout 5s
  failureThreshold: 3        # 3 ebaõnnestumist → restart
```

### 6.2. Readiness Probe

**Eesmärk:** Kontrollida, kas container on valmis liiklust vastu võtma

**Kui Readiness Probe ebaõnnestub:**
- Pod eemaldatakse Service endpoints-ist
- Kubernetes EI taaskäivita containerit

**Backend readiness endpoint:**
```javascript
// labs/apps/backend-nodejs/src/index.js

app.get('/ready', async (req, res) => {
  try {
    // Kontrolli DB ühendust
    await pool.query('SELECT 1');

    res.status(200).json({
      status: 'ready',
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({
      status: 'not ready',
      database: 'disconnected',
      error: error.message
    });
  }
});
```

**Manifest:**
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5     # Alusta kiiremini kui liveness
  periodSeconds: 5           # Kontrolli sagedamini
  timeoutSeconds: 3
  failureThreshold: 2        # Kiiremini not ready
```

### 6.3. Startup Probe (valikuline)

**Eesmärk:** Anda aeglaselt käivituvatele rakendustele rohkem aega

```yaml
startupProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 0
  periodSeconds: 5
  failureThreshold: 30       # Max 30 * 5s = 150s käivitumiseks
```

### 6.4. Probes Testimine

**Vaata Podi events-e:**
```bash
kubectl describe pod <pod-name> -n production

# Events:
#   Liveness probe failed: HTTP probe failed with statuscode: 503
#   Readiness probe failed: HTTP probe failed with statuscode: 503
```

**Vaata container restarte:**
```bash
kubectl get pods -n production -l app=backend

# NAME                       READY   STATUS    RESTARTS   AGE
# backend-6d7f8c9b5d-7k2qm   1/1     Running   3          10m
#                                              ↑ restarts count
```

**Simuleerida probe failure:**
```bash
# Exec Pod-i sisse ja tapa protsess
kubectl exec -it <pod-name> -n production -- kill 1

# Kubernetes taaskäivitab container-i automaatselt
```

---

## 7. Resource Limits ja Requests

### 7.1. Requests vs Limits

**Requests:**
- **Garanteeritud** ressursid
- Kubernetes scheduler kasutab seda Podi paigutamiseks Node-le
- Pod ei käivitu, kui Node-l ei ole piisavalt vaba ressurssi

**Limits:**
- **Maksimaalne** ressursikasutus
- Pod ei saa kunagi kasutada rohkem kui limit
- CPU: throttling
- Memory: OOMKilled (Out Of Memory)

### 7.2. Backend Resource Spetsifikatsioon

```yaml
resources:
  requests:
    memory: "256Mi"       # Garanteeritud 256MB RAM
    cpu: "100m"           # Garanteeritud 0.1 CPU core (10%)
  limits:
    memory: "512Mi"       # Max 512MB RAM
    cpu: "500m"           # Max 0.5 CPU core (50%)
```

**CPU ühikud:**
- `1000m` = 1 CPU core = 1 vCPU
- `100m` = 0.1 CPU core = 10% ühest core-ist
- `500m` = 0.5 CPU core = 50% ühest core-ist

**Memory ühikud:**
- `Mi` = Mebibyte (1024^2 bytes)
- `M` = Megabyte (1000^2 bytes)
- `Gi` = Gibibyte (1024^3 bytes)

### 7.3. Ressursside Valimine

**Kuidas valida õigeid väärtusi?**

1. **Alusta konservatiivselt:**
```yaml
requests:
  memory: "128Mi"
  cpu: "50m"
limits:
  memory: "256Mi"
  cpu: "200m"
```

2. **Jälgi tegelikku kasutust:**
```bash
# Vaata ressursikasutust
kubectl top pods -n production -l app=backend

# NAME                       CPU(cores)   MEMORY(bytes)
# backend-6d7f8c9b5d-7k2qm   25m          180Mi
# backend-6d7f8c9b5d-9h4ks   30m          195Mi
# backend-6d7f8c9b5d-xz8lp   28m          175Mi
```

3. **Kohanda vastavalt:**
```yaml
# Näide kohandatud väärtustega
requests:
  memory: "200Mi"    # Veidi rohkem kui keskmine kasutus
  cpu: "50m"         # Madal baseline
limits:
  memory: "400Mi"    # 2x requests (burst jaoks)
  cpu: "300m"        # 6x requests (spike jaoks)
```

### 7.4. QoS Classes (Quality of Service)

Kubernetes määrab automaatselt QoS klassi:

**1. Guaranteed (kõrgeim prioriteet):**
```yaml
# Requests = Limits
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "100m"
```

**2. Burstable (keskmine prioriteet):**
```yaml
# Requests < Limits
resources:
  requests:
    memory: "128Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

**3. BestEffort (madalaim prioriteet):**
```yaml
# Ei ole ühtegi request/limit
resources: {}
```

**Kontrolli QoS klassi:**
```bash
kubectl describe pod <pod-name> -n production | grep "QoS Class"
# QoS Class: Burstable
```

### 7.5. Out of Memory (OOM) Käsitlemine

**Kui Pod ületab memory limit:**
```bash
kubectl get pods -n production

# NAME                       READY   STATUS      RESTARTS   AGE
# backend-6d7f8c9b5d-7k2qm   0/1     OOMKilled   5          10m
```

**Events:**
```bash
kubectl describe pod <pod-name> -n production

# Events:
#   Pod backend-6d7f8c9b5d-7k2qm killed due to memory limit exceeded
```

**Lahendus:**
1. Suurenda memory limit
2. Optimiseeri rakenduse mälukasutust
3. Lisa memory leak detection

---

## 8. HorizontalPodAutoscaler

### 8.1. Mis on HPA?

**HorizontalPodAutoscaler (HPA):**
- Automaatselt skaleerib Podide arvu
- Baseerub CPU, memory või custom metrics-il
- Min ja max replicas piirid

**Arhitektuur:**
```
┌─────────────────────────────────┐
│  HPA                            │
│  - Min: 2 replicas              │
│  - Max: 10 replicas             │
│  - Target CPU: 70%              │
└────────────┬────────────────────┘
             │ watches metrics
             ▼
┌─────────────────────────────────┐
│  Metrics Server                 │
│  (kubectl top pods)             │
└────────────┬────────────────────┘
             │ collects metrics
             ▼
┌─────────────────────────────────┐
│  Backend Deployment             │
│  - Current replicas: 3          │
│  - CPU usage: 85%               │
└─────────────────────────────────┘
             │
             ▼ HPA scales up
┌─────────────────────────────────┐
│  Backend Deployment             │
│  - Current replicas: 5          │
│  - CPU usage: 60%               │
└─────────────────────────────────┘
```

### 8.2. Metrics Server Paigaldamine

K3s-is on metrics server vaikimisi kaasas, kuid kontrolli:

```bash
kubectl get deployment metrics-server -n kube-system

# Kui puudub, paigalda:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Testi
kubectl top nodes
kubectl top pods -n production
```

### 8.3. HPA Manifest - CPU-based

**Fail:** `backend-hpa.yaml`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2                 # Minimaalne 2 koopiat
  maxReplicas: 10                # Maksimaalne 10 koopiat
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70   # Target 70% CPU kasutus
  behavior:                      # Skaleerimise käitumine
    scaleUp:
      stabilizationWindowSeconds: 30   # Oota 30s enne scale up
      policies:
      - type: Percent
        value: 50                # Max 50% suurendus korraga
        periodSeconds: 60
      - type: Pods
        value: 2                 # Max 2 Podi korraga
        periodSeconds: 60
      selectPolicy: Min          # Vali konservatiivsem
    scaleDown:
      stabilizationWindowSeconds: 300  # Oota 5min enne scale down
      policies:
      - type: Percent
        value: 25                # Max 25% vähendus korraga
        periodSeconds: 60
```

**Rakenda:**
```bash
kubectl apply -f backend-hpa.yaml

# Kontrolli HPA staatust
kubectl get hpa -n production
kubectl describe hpa backend-hpa -n production

# Jälgi HPA automaatselt
watch kubectl get hpa -n production
```

**Väljund:**
```
NAME          REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
backend-hpa   Deployment/backend   45%/70%   2         10        3          5m
                                    ↑ current/target
```

### 8.4. HPA Manifest - CPU ja Memory

**Fail:** `backend-hpa-multi.yaml`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  # CPU metric
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70

  # Memory metric
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80   # 80% memory kasutus

  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
      - type: Pods
        value: 2
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Pods
        value: 1
        periodSeconds: 60
```

**Kui mitu metrikat on defineeritud:**
- HPA skaleerib baseerudes **kõige kõrgemal** väärtusel
- Näide: CPU 45%, Memory 85% → skaleerib memory põhjal

### 8.5. HPA Testimine

**1. Tekita load:**

```bash
# Käivita load generator Pod
kubectl run -it --rm load-generator --image=busybox --restart=Never -n production -- sh

# Podi sees: genereeri load
while true; do wget -q -O- http://backend:3000/health; done
```

**2. Jälgi autoscaling-ut:**

```bash
# Terminal 1: Jälgi HPA
watch kubectl get hpa -n production

# Terminal 2: Jälgi Podi arvu
watch kubectl get pods -n production -l app=backend

# Terminal 3: Jälgi CPU kasutust
watch kubectl top pods -n production -l app=backend
```

**3. Näe skaleerimist:**
```
# HPA
NAME          REFERENCE            TARGETS    MINPODS   MAXPODS   REPLICAS
backend-hpa   Deployment/backend   125%/70%   2         10        3
                                    ↓ CPU kasutus kasvab
backend-hpa   Deployment/backend   125%/70%   2         10        5
                                                                   ↑ skaleeriti 3→5

# Pods
NAME                       READY   STATUS    CPU    MEMORY
backend-6d7f8c9b5d-7k2qm   1/1     Running   150m   250Mi
backend-6d7f8c9b5d-9h4ks   1/1     Running   140m   240Mi
backend-6d7f8c9b5d-xz8lp   1/1     Running   145m   245Mi
backend-6d7f8c9b5d-abc12   1/1     Running   80m    180Mi   ← uus Pod
backend-6d7f8c9b5d-def34   1/1     Running   75m    175Mi   ← uus Pod
```

**4. Peata load ja vaata scale down:**
```bash
# Ctrl+C load generator-is

# HPA skaleerib alla peale 5min (stabilizationWindowSeconds)
```

---

## 9. Rolling Updates ja Rollbacks

### 9.1. Rolling Update Strateegia

**Deployment manifest-is:**
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # Max 1 täiendav Pod update ajal
      maxUnavailable: 0    # 0 unavailable Podi (zero downtime)
```

**Kuidas töötab:**
```
Enne update: 3 Podi (v1)
┌────┐ ┌────┐ ┌────┐
│ v1 │ │ v1 │ │ v1 │
└────┘ └────┘ └────┘

Step 1: Loo 1 uus Pod (v2) - maxSurge: 1
┌────┐ ┌────┐ ┌────┐ ┌────┐
│ v1 │ │ v1 │ │ v1 │ │ v2 │ ← uus
└────┘ └────┘ └────┘ └────┘

Step 2: Kui v2 ready, eemalda 1 vana (v1)
┌────┐ ┌────┐ ┌────┐
│ v1 │ │ v1 │ │ v2 │
└────┘ └────┘ └────┘

Step 3: Korda kuni kõik v1 asendatud
┌────┐ ┌────┐ ┌────┐
│ v2 │ │ v2 │ │ v2 │
└────┘ └────┘ └────┘
```

### 9.2. Update Image Version

**Meetod 1: kubectl set image**
```bash
# Ehita uus image
cd /home/janek/projects/hostinger/labs/apps/backend-nodejs
docker build -t localhost:5000/backend:1.1 .
docker push localhost:5000/backend:1.1

# Update Deployment
kubectl set image deployment/backend backend=localhost:5000/backend:1.1 -n production

# Jälgi rollout-i
kubectl rollout status deployment/backend -n production
```

**Meetod 2: kubectl apply (soovitatav)**
```bash
# Muuda manifest-is image versiooni
vim backend-deployment-primary.yaml
# image: localhost:5000/backend:1.1

# Rakenda
kubectl apply -f backend-deployment-primary.yaml

# Jälgi
kubectl rollout status deployment/backend -n production
```

**Väljund:**
```
Waiting for deployment "backend" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "backend" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "backend" rollout to finish: 2 old replicas are pending termination...
deployment "backend" successfully rolled out
```

### 9.3. Rollout History

**Vaata rollout history:**
```bash
kubectl rollout history deployment/backend -n production

# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         <none>
# 3         kubectl apply --filename=backend-deployment-primary.yaml
```

**Lisa change-cause annotation:**
```bash
kubectl annotate deployment/backend \
  kubernetes.io/change-cause="Update to version 1.1" \
  -n production

# VÕI manifest-is:
metadata:
  annotations:
    kubernetes.io/change-cause: "Update to version 1.1"
```

**Vaata konkreetse revision-i detaile:**
```bash
kubectl rollout history deployment/backend --revision=3 -n production
```

### 9.4. Rollback

**Scenario: Uus versioon (1.1) on buggy, tahan tagasi minna versioonile 1.0**

**Rollback viimase revision-i juurde:**
```bash
kubectl rollout undo deployment/backend -n production

# Jälgi rollback-i
kubectl rollout status deployment/backend -n production
```

**Rollback konkreetsele revision-ile:**
```bash
# Vaata history
kubectl rollout history deployment/backend -n production

# REVISION  CHANGE-CAUSE
# 1         Initial deployment v1.0
# 2         Update to v1.1 (buggy)
# 3         Update to v1.2

# Rollback revision 1 juurde
kubectl rollout undo deployment/backend --to-revision=1 -n production
```

### 9.5. Pause ja Resume Rollout

**Pause rollout (testimiseks):**
```bash
# Alusta update
kubectl set image deployment/backend backend=localhost:5000/backend:1.2 -n production

# Pause kohe
kubectl rollout pause deployment/backend -n production

# Praegu on mõned Podid v1.1, mõned v1.2
kubectl get pods -n production -l app=backend -o wide

# Testi v1.2 Podi
kubectl port-forward <v1.2-pod-name> 3000:3000 -n production

# Kui OK, jätka
kubectl rollout resume deployment/backend -n production

# Kui probleem, rollback
kubectl rollout undo deployment/backend -n production
```

---

## 10. Harjutused

### Harjutus 1: Backend Deployment - PRIMAARNE Variant

**Eesmärk:** Deployida backend Kubernetes-es StatefulSet PostgreSQL-iga

**Sammud:**

1. **Kontrolli PostgreSQL-i (Peatükk 17):**
```bash
kubectl get statefulset postgres -n production
kubectl get service postgres -n production
```

2. **Loo ConfigMap:**
```bash
vim backend-configmap-primary.yaml
# (kopeeri sektsioonist 2.2)

kubectl apply -f backend-configmap-primary.yaml
kubectl get configmap backend-config -n production
```

3. **Loo Secret:**
```bash
vim backend-secret-primary.yaml
# (kopeeri sektsioonist 3.2)

kubectl apply -f backend-secret-primary.yaml
kubectl get secret backend-secret -n production
```

4. **Ehita ja push backend image:**
```bash
cd /home/janek/projects/hostinger/labs/apps/backend-nodejs

# Veendu, et .env on õige
cp .env.example .env
vim .env
# DB_HOST=postgres
# DB_PORT=5432
# DB_NAME=appdb
# ...

# Ehita image
docker build -t localhost:5000/backend:1.0 .

# Push kohalikku registry-sse (Peatükk 15)
docker push localhost:5000/backend:1.0
```

5. **Loo Deployment:**
```bash
vim backend-deployment-primary.yaml
# (kopeeri sektsioonist 4.1)

kubectl apply -f backend-deployment-primary.yaml
```

6. **Jälgi deployment-i:**
```bash
kubectl rollout status deployment/backend -n production
kubectl get pods -n production -l app=backend
```

7. **Loo Service:**
```bash
vim backend-service.yaml
# (kopeeri sektsioonist 5.1)

kubectl apply -f backend-service.yaml
kubectl get service backend -n production
```

8. **Testi backend:**
```bash
# Port-forward
kubectl port-forward service/backend 3000:3000 -n production

# Teises terminalis
curl http://localhost:3000/health
# {"status":"ok","timestamp":"...","uptime":...}

# Testi registreerimine
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"test123"}'

# Testi login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
# {"token":"eyJhbGc...","user":{...}}
```

**Valideerimise checklist:**
- [ ] ConfigMap loodud
- [ ] Secret loodud
- [ ] Backend image built ja pushed
- [ ] Deployment loodud (3 replicas)
- [ ] Kõik Podid running ja ready
- [ ] Service loodud ja endpoints korras
- [ ] Health check töötab
- [ ] Register ja login töötavad
- [ ] PostgreSQL ühendus OK

---

### Harjutus 2: HPA Seadistamine ja Testimine

**Eesmärk:** Lisada autoscaling backend deployment-ile

**Sammud:**

1. **Veendu, et metrics server töötab:**
```bash
kubectl top nodes
kubectl top pods -n production
```

2. **Loo HPA:**
```bash
vim backend-hpa.yaml
# (kopeeri sektsioonist 8.3)

kubectl apply -f backend-hpa.yaml
```

3. **Kontrolli HPA:**
```bash
kubectl get hpa -n production
kubectl describe hpa backend-hpa -n production
```

4. **Vähenda min replicas testimiseks:**
```bash
# Ajutiselt muuda HPA
kubectl patch hpa backend-hpa -n production -p '{"spec":{"minReplicas":2,"maxReplicas":6}}'

# Või edit
kubectl edit hpa backend-hpa -n production
```

5. **Tekita load:**
```bash
# Käivita load generator
kubectl run -it --rm load-generator --image=busybox --restart=Never -n production -- sh

# Podi sees
while true; do wget -q -O- http://backend:3000/health; done
```

6. **Jälgi autoscaling-ut (uus terminal):**
```bash
# Terminal 1: HPA
watch kubectl get hpa -n production

# Terminal 2: Podid
watch kubectl get pods -n production -l app=backend

# Terminal 3: CPU
watch kubectl top pods -n production -l app=backend
```

7. **Vaata scale up:**
```
# Peaks nägema replicas kasvamas 2 → 3 → 4 → ...
```

8. **Peata load:**
```bash
# Ctrl+C load generator-is
```

9. **Vaata scale down:**
```bash
# Peale 5min (stabilizationWindowSeconds) peaks replicas vähenema
```

**Valideerimise checklist:**
- [ ] HPA loodud
- [ ] HPA näitab current/target metrics
- [ ] Load generator töötab
- [ ] CPU kasutus kasvab
- [ ] Replicas skaleerub üles
- [ ] Peale load-i peatamist skaleerub alla
- [ ] Min/max replicas piirid töötavad

---

### Harjutus 3: Rolling Update ja Rollback

**Eesmärk:** Uuenda backend versiooni ja tee rollback

**Sammud:**

1. **Muuda backend koodi:**
```bash
cd /home/janek/projects/hostinger/labs/apps/backend-nodejs

# Muuda health endpoint-i
vim src/index.js
```

```javascript
// Muuda:
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    version: '1.1',        // ← Lisa version
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});
```

2. **Ehita uus image:**
```bash
docker build -t localhost:5000/backend:1.1 .
docker push localhost:5000/backend:1.1
```

3. **Update Deployment:**
```bash
# Meetod 1: kubectl set image
kubectl set image deployment/backend backend=localhost:5000/backend:1.1 -n production \
  --record

# VÕI Meetod 2: muuda manifest ja apply
vim backend-deployment-primary.yaml
# image: localhost:5000/backend:1.1
kubectl apply -f backend-deployment-primary.yaml
```

4. **Jälgi rollout-i:**
```bash
kubectl rollout status deployment/backend -n production

# Teises terminalis vaata Podi
watch kubectl get pods -n production -l app=backend
```

5. **Kontrolli uut versiooni:**
```bash
kubectl port-forward service/backend 3000:3000 -n production

curl http://localhost:3000/health
# {"status":"ok","version":"1.1","timestamp":"..."}
```

6. **Vaata rollout history:**
```bash
kubectl rollout history deployment/backend -n production
```

7. **Tee rollback:**
```bash
kubectl rollout undo deployment/backend -n production

# Jälgi
kubectl rollout status deployment/backend -n production
```

8. **Kontrolli, et versioon on tagasi 1.0:**
```bash
curl http://localhost:3000/health
# {"status":"ok","timestamp":"..."}  ← ei ole version field-i
```

**Valideerimise checklist:**
- [ ] Uus image (1.1) built ja pushed
- [ ] Rollout algas
- [ ] Rolling update lõpetatud (zero downtime)
- [ ] Uus versioon töötab
- [ ] Rollout history näitab revisions
- [ ] Rollback õnnestus
- [ ] Vana versioon taastatud

---

### Harjutus 4: Backend Deployment - ALTERNATIIV Variant (valikuline)

**Eesmärk:** Deployida backend välise PostgreSQL-iga

**Eeldus:** Sul on juurdepääs välisele PostgreSQL-ile (näiteks VPS-is traditsiooniliselt paigaldatud)

**Sammud:**

1. **Veendu, et väline PostgreSQL töötab:**
```bash
# VPS kirjakast-is
sudo systemctl status postgresql

# Testi ühendust
psql -h localhost -U appuser -d appdb -c "SELECT version();"
```

2. **Loo ExternalName Service (Peatükk 17):**
```bash
kubectl get service postgres -n production
# Peaks olema ExternalName service
```

3. **Loo ConfigMap (väline variant):**
```bash
vim backend-configmap-external.yaml
# (kopeeri sektsioonist 2.3)

kubectl apply -f backend-configmap-external.yaml
```

4. **Loo Secret (väline variant):**
```bash
vim backend-secret-external.yaml
# (kopeeri sektsioonist 3.3)

# Muuda DB_HOST, DB_USER, DB_PASSWORD vastavalt välisele DB-le

kubectl apply -f backend-secret-external.yaml
```

5. **Loo Deployment:**
```bash
vim backend-deployment-external.yaml
# (kopeeri sektsioonist 4.2)

kubectl apply -f backend-deployment-external.yaml
```

6. **Testi:**
```bash
kubectl port-forward service/backend 3000:3000 -n production

curl http://localhost:3000/health
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"External Test","email":"external@example.com","password":"test123"}'
```

**Valideerimise checklist:**
- [ ] Väline PostgreSQL kättesaadav
- [ ] ExternalName Service loodud
- [ ] ConfigMap (external variant) loodud
- [ ] Secret (external variant) loodud
- [ ] Backend deployment töötab
- [ ] Ühendus välisele DB-le OK
- [ ] API endpointid töötavad

---

## Kokkuvõte

Selles peatükis õppisid:

✅ **ConfigMaps ja Secrets:**
- ConfigMaps mittesalajaste konf-ide jaoks
- Secrets salajaste andmete jaoks (base64)
- `envFrom` ja `env` kasutamine Deployment-is

✅ **Backend Deployment:**
- Deployment manifest koos mõlema PostgreSQL variandiga
- Image pull kohalikust registry-st
- Environment variables ConfigMap-ist ja Secret-ist

✅ **Service:**
- ClusterIP service sisemiseks suhtluseks
- Service Discovery DNS-iga
- Endpoints kontrollimine

✅ **Health Checks:**
- Liveness Probe - container töötab?
- Readiness Probe - container valmis?
- Startup Probe - aeglane käivitamine

✅ **Resource Management:**
- Requests - garanteeritud ressursid
- Limits - maksimaalne kasutus
- QoS classes (Guaranteed, Burstable, BestEffort)
- OOM käsitlemine

✅ **Autoscaling:**
- HorizontalPodAutoscaler (HPA)
- CPU ja memory metrics
- Scale up/down policies
- Stabilization windows

✅ **Updates ja Rollbacks:**
- Rolling update strateegia (zero downtime)
- maxSurge ja maxUnavailable
- Rollout history
- Rollback eelmisele versioonile

---

## Järgmine Samm

**Peatükk 19: Frontend Deployment ja Ingress**
- Frontend deployment (Nginx)
- Ingress controller (Traefik)
- Ingress rules
- TLS/SSL sertifikaadid (Let's Encrypt)
- Domain nimedega töötamine

**Ressursid:**
- Kubernetes Deployments: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- ConfigMaps: https://kubernetes.io/docs/concepts/configuration/configmap/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- HPA: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- Probes: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

---

**VPS:** kirjakast @ 93.127.213.242
**Kasutaja:** janek
**Editor:** vim
**Namespace:** production

Edu! 🚀
