# Harjutus 5: Autoscaling ja Rolling Updates

**Kestus:** 60 minutit
**Eesmärk:** Õppida automaatset skaleerimist ja zero-downtime deployment'e

---

## 📋 Ülevaade

Selles harjutuses õpid kasutama **Horizontal Pod Autoscaler (HPA)** automaatseks skaleerimiseks ning implementeerima **Rolling Updates** ilma downtime'ita.

**HPA** = automaatselt lisab või eemaldab pod'e CPU/memory kasutuse põhjal
**Rolling Update** = järjest pod'ide asendamine (zero downtime)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Paigaldada Metrics Server'it
- ✅ Luua Horizontal Pod Autoscaler (HPA)
- ✅ Testida autoscaling'u koormusega
- ✅ Seadistada readiness ja liveness probes
- ✅ Implementeerida Rolling Update strateegiat
- ✅ Teha zero-downtime deployment'e
- ✅ Monitoorida HPA ja deployment'i

---

## 🏗️ Arhitektuur

```
┌───────────────────────────────────────────────────┐
│           Kubernetes Cluster                      │
│                                                   │
│  ┌─────────────────────────────────────────────┐  │
│  │  Metrics Server                             │  │
│  │  (CPU/Memory metrics)                       │  │
│  └──────────────┬──────────────────────────────┘  │
│                 │                                 │
│                 ▼                                 │
│  ┌─────────────────────────────────────────────┐  │
│  │  HorizontalPodAutoscaler                    │  │
│  │  Target: 50% CPU                            │  │
│  │  Min: 2, Max: 10                            │  │
│  └──────────────┬──────────────────────────────┘  │
│                 │ scales                          │
│                 ▼                                 │
│  ┌─────────────────────────────────────────────┐  │
│  │  Deployment: user-service                   │  │
│  │  replicas: 2-10 (dynamic)                   │  │
│  └──────────────┬──────────────────────────────┘  │
│                 │                                 │
│        ┌────────┴────────┐                        │
│        ▼                 ▼                        │
│     ┌────┐ ... ┌────┐ ┌────┐                     │
│     │Pod │      │Pod │ │Pod │                     │
│     │ 1  │      │ N  │ │ N+1│                     │
│     └────┘      └────┘ └────┘                     │
│      ↑                   ↑                        │
│      │                   │                        │
│  CPU: 30%            CPU: 60%                     │
│  (avg: 45% < 50%)    → scale up                   │
│                                                   │
└───────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Paigalda Metrics Server (10 min)

**Metrics Server** kogub CPU/memory metrics pod'idest (HPA vajab seda).

**Minikube:**

```bash
# Minikube'il on Metrics Server addon
minikube addons enable metrics-server

# Kontrolli
minikube addons list | grep metrics-server
# metrics-server: enabled
```

**K3s:**

K3s tuleb built-in metrics-server'iga, aga kui puudub:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Kontrolli
kubectl get deployment metrics-server -n kube-system
```

**Kontrolli metrics'eid:**

```bash
# Oota ~60 sekundit (metrics kogutakse)

# Vaata node metrics
kubectl top nodes

# NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# minikube   250m         6%     1500Mi          37%

# Vaata pod metrics
kubectl top pods

# NAME                          CPU(cores)   MEMORY(bytes)
# user-service-xxx-xxxxx        10m          50Mi
```

**Kui `kubectl top` ei tööta:**
```bash
# Restart metrics-server
kubectl rollout restart deployment/metrics-server -n kube-system

# Oota 60 sekundit ja proovi uuesti
```

---

### Samm 2: Seadista Resource Requests (10 min)

**HPA vajab CPU/memory requests** - ilma nendeta ei saa autoscale'ida.

Loo fail `user-deployment-with-resources.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 2
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
        image: user-service:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 3000

        # Resource requests ja limits (MANDATORY HPA jaoks!)
        resources:
          requests:
            cpu: 100m      # 0.1 CPU core
            memory: 128Mi
          limits:
            cpu: 500m      # 0.5 CPU core max
            memory: 256Mi

        env:
        - name: PORT
          value: "3000"
        - name: NODE_ENV
          value: "production"
```

**Deploy:**

```bash
kubectl apply -f user-deployment-with-resources.yaml

# Kontrolli
kubectl get deployment user-service

# Vaata resource usage
kubectl top pods -l app=user-service
```

---

### Samm 3: Loo Horizontal Pod Autoscaler (10 min)

Loo fail `hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service  # Deployment nimi

  minReplicas: 2   # Minimaalne pod'ide arv
  maxReplicas: 10  # Maksimaalne pod'ide arv

  metrics:
  # CPU target
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50  # 50% CPU kasutusest

  # Memory target (optional)
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70  # 70% memory kasutusest

  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0  # Kohe scale up
      policies:
      - type: Percent
        value: 100  # Topelta pod'e korraga (max)
        periodSeconds: 15
      - type: Pods
        value: 4    # Lisa max 4 pod'i korraga
        periodSeconds: 15
      selectPolicy: Max

    scaleDown:
      stabilizationWindowSeconds: 300  # Oota 5min enne scale down
      policies:
      - type: Percent
        value: 50   # Eemalda max 50% pod'idest
        periodSeconds: 60
```

**Deploy:**

```bash
kubectl apply -f hpa.yaml

# Kontrolli
kubectl get hpa

# NAME               REFERENCE                TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
# user-service-hpa   Deployment/user-service  5%/50%, 10%/70% 2         10        2          10s

# TARGETS:
# - 5%/50% = current CPU / target CPU
# - 10%/70% = current memory / target memory

# Detailne info
kubectl describe hpa user-service-hpa
```

---

### Samm 4: Testi Autoscaling'u (15 min)

**Loo koormust:**

```bash
# Install load generator
kubectl run load-generator --image=busybox --rm -it --restart=Never -- sh

# Pod sees:
while true; do wget -q -O- http://user-service/health; done

# Jäta töötama (teises terminalis jätka)
```

**Jälgi autoscaling'u:**

```bash
# Watch HPA
kubectl get hpa user-service-hpa --watch

# Peaks nägema CPU kasvu:
# NAME               REFERENCE                TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
# user-service-hpa   Deployment/user-service  5%/50%     2         10        2          1m
# user-service-hpa   Deployment/user-service  30%/50%    2         10        2          2m
# user-service-hpa   Deployment/user-service  60%/50%    2         10        2          3m  (scale up!)
# user-service-hpa   Deployment/user-service  55%/50%    2         10        4          4m
# user-service-hpa   Deployment/user-service  40%/50%    2         10        4          5m

# Vaata pod'ide arvu
kubectl get pods -l app=user-service --watch

# Peaks nägema uusi pod'e:
# NAME                           READY   STATUS              RESTARTS   AGE
# user-service-xxx-xxxxx         1/1     Running             0          5m
# user-service-xxx-yyyyy         1/1     Running             0          5m
# user-service-xxx-zzzzz         0/1     ContainerCreating   0          5s  (uus!)
# user-service-xxx-aaaaa         0/1     Pending             0          5s  (uus!)
```

**Peata koormus:**

```bash
# Esimeses terminalis (load-generator):
# Ctrl+C (peata while loop)

# Jälgi scale down (võtab ~5 minutit)
kubectl get hpa user-service-hpa --watch

# Peaks nägema CPU langust:
# NAME               REFERENCE                TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
# user-service-hpa   Deployment/user-service  40%/50%   2         10        4          6m
# user-service-hpa   Deployment/user-service  20%/50%   2         10        4          7m
# user-service-hpa   Deployment/user-service  10%/50%   2         10        4          8m
# ...
# user-service-hpa   Deployment/user-service  5%/50%    2         10        2          11m (scaled down!)
```

---

### Samm 5: Readiness ja Liveness Probes (10 min)

**Probes** kontrollivad pod'i tervist.

- **Liveness Probe:** Kas pod töötab? (kui mitte → restart)
- **Readiness Probe:** Kas pod on valmis liiklust vastu võtma? (kui mitte → eemalda Service endpoint'ist)

Muuda Deployment'i:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 2
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
        image: user-service:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 3000

        # Readiness probe - kas pod valmis liiklust vastu võtma?
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5  # Oota 5s enne esimest check'i
          periodSeconds: 5        # Check iga 5s
          timeoutSeconds: 2
          successThreshold: 1     # 1 success → READY
          failureThreshold: 3     # 3 failures → NOT READY

        # Liveness probe - kas pod töötab?
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 15
          periodSeconds: 10
          timeoutSeconds: 2
          failureThreshold: 3     # 3 failures → RESTART pod

        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
```

**Deploy ja testi:**

```bash
kubectl apply -f user-deployment-with-probes.yaml

# Kontrolli pod'i
kubectl describe pod user-service-xxx-xxxxx

# Peaks näitama:
# Liveness:   http-get http://:3000/health delay=15s timeout=2s period=10s #success=1 #failure=3
# Readiness:  http-get http://:3000/health delay=5s timeout=2s period=5s #success=1 #failure=3

# Vaata events
kubectl get events --sort-by='.lastTimestamp' | grep user-service

# Peaks näitama readiness probe success
```

**Kui /health endpoint failib:**
Pod on NOT READY → Service ei route liiklust sellele pod'ile.

---

### Samm 6: Rolling Update Strateegia (10 min)

**Rolling Update** asendab järjest pod'e ilma downtime'ita.

Muuda Deployment rolling update parameetreid:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 4
  selector:
    matchLabels:
      app: user-service

  # Rolling Update strateegia
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max +1 pod ajutiselt (võib olla 5 pod'i: 4+1)
      maxUnavailable: 0  # Min 0 unavailable (alati vähemalt 4 töötab)

  template:
    metadata:
      labels:
        app: user-service
        version: "1.0"
    spec:
      containers:
      - name: user-service
        image: user-service:1.0
        imagePullPolicy: Never

        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5

        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

**Testi rolling update:**

```bash
# Deploy
kubectl apply -f user-deployment-rolling.yaml

# Kontrolli pod'e
kubectl get pods -l app=user-service --watch

# Uuenda image (simuleerime update't)
kubectl set image deployment/user-service user-service=user-service:1.1

# Jälgi rolling update:
# NAME                          READY   STATUS              RESTARTS   AGE
# user-service-xxx-xxxxx        1/1     Running             0          5m
# user-service-xxx-yyyyy        1/1     Running             0          5m
# user-service-xxx-zzzzz        1/1     Running             0          5m
# user-service-xxx-aaaaa        1/1     Running             0          5m
# user-service-new-xxxxx        0/1     ContainerCreating   0          2s   (uus pod!)
# user-service-new-xxxxx        1/1     Running             0          5s   (uus READY)
# user-service-xxx-xxxxx        1/1     Terminating         0          5m   (vana termineeritakse)
# user-service-new-yyyyy        0/1     ContainerCreating   0          2s   (järgmine uus)
# ...

# Kontroll rollout status
kubectl rollout status deployment/user-service

# Waiting for deployment "user-service" rollout to finish: 2 out of 4 new replicas have been updated...
# Waiting for deployment "user-service" rollout to finish: 3 out of 4 new replicas have been updated...
# Waiting for deployment "user-service" rollout to finish: 3 of 4 updated replicas are available...
# deployment "user-service" successfully rolled out
```

**Zero downtime:**
- maxUnavailable: 0 → alati vähemalt 4 pod'i töötab
- Readiness probe → uus pod peab olema READY enne vana pod'i termineerimist

---

### Samm 7: Monitoori HPA ja Deployment (5 min)

```bash
# HPA status
kubectl get hpa user-service-hpa

# Deployment status
kubectl get deployment user-service

# Pod metrics
kubectl top pods -l app=user-service

# HPA events
kubectl describe hpa user-service-hpa

# Events:
#   Type    Reason             Age   Message
#   ----    ------             ----  -------
#   Normal  SuccessfulRescale  5m    New size: 4; reason: cpu resource utilization (percentage of request) above target
#   Normal  SuccessfulRescale  2m    New size: 2; reason: All metrics below target

# Deployment events
kubectl describe deployment user-service
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **Metrics Server:**
  - [ ] Paigaldatud ja töötab
  - [ ] `kubectl top` töötab

- [ ] **HPA:**
  - [ ] Loodud ja seotud Deployment'iga
  - [ ] CPU target seadistatud (50%)
  - [ ] Autoscaling töötab (scale up/down)

- [ ] **Resource Requests:**
  - [ ] Deployment'il on CPU/memory requests
  - [ ] Limits seadistatud

- [ ] **Probes:**
  - [ ] Readiness probe seadistatud
  - [ ] Liveness probe seadistatud

- [ ] **Rolling Update:**
  - [ ] maxSurge ja maxUnavailable seadistatud
  - [ ] Zero-downtime deployment toimib

---

## 🐛 Troubleshooting

### Probleem 1: HPA näitab "unknown" target

**Sümptom:**
```bash
kubectl get hpa
# NAME               REFERENCE                TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
# user-service-hpa   Deployment/user-service  <unknown>/50%   2         10        2          1m
```

**Diagnoos:**

```bash
# Kontrolli Metrics Server
kubectl get deployment metrics-server -n kube-system

# Kontrolli pod metrics
kubectl top pods

# Kui "error: Metrics API not available":
# Metrics Server ei tööta
```

**Lahendus:**

```bash
# Minikube
minikube addons enable metrics-server

# K3s/Manual
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Oota 60s
kubectl top pods
```

---

### Probleem 2: HPA ei scale'i

**Sümptom:**
```bash
# CPU on 80%, aga HPA ei lisa pod'e
kubectl get hpa
# TARGETS: 80%/50%, REPLICAS: 2
```

**Diagnoos:**

```bash
# Kontrolli HPA events
kubectl describe hpa user-service-hpa

# Events:
# FailedGetResourceMetric: unable to get metrics for resource cpu
```

**Lahendus:**

1. **Resource requests puuduvad:**
```yaml
resources:
  requests:
    cpu: 100m  # MANDATORY!
```

2. **Deployment pole valmis:**
```bash
kubectl get deployment user-service
# READY: 0/2 (pod'id ei ole READY)

# Kontrolli pod'i
kubectl describe pod user-service-xxx
```

---

### Probleem 3: Rolling update jääb kinni

**Sümptom:**
```bash
kubectl rollout status deployment/user-service
# Waiting for deployment "user-service" rollout to finish: 1 out of 4 new replicas have been updated...
# (jääb kinni)
```

**Diagnoos:**

```bash
# Kontrolli pod'i
kubectl get pods -l app=user-service

# Uus pod on Pending/CrashLoopBackOff?
kubectl describe pod user-service-new-xxxxx

# Readiness probe failib?
kubectl logs user-service-new-xxxxx
```

**Lahendus:**

```bash
# Rollback
kubectl rollout undo deployment/user-service

# Paranda issue (nt readiness probe path)
# Proovi uuesti
```

---

## 🎓 Õpitud Mõisted

### Autoscaling:
- **Horizontal Pod Autoscaler (HPA):** Automaatne pod'ide arvu muutmine
- **Metrics Server:** CPU/memory metrics koguja
- **Target Utilization:** CPU/memory threshold (nt 50%)
- **Scale Up:** Lisa pod'e (CPU > target)
- **Scale Down:** Eemalda pod'e (CPU < target)

### Resource Management:
- **Requests:** Minimaalsed ressursid (scheduling otsus)
- **Limits:** Maksimaalsed ressursid (ei tohi ületada)
- **CPU:** Millicores (100m = 0.1 core)
- **Memory:** Mi, Gi

### Health Checks:
- **Liveness Probe:** Kas pod töötab? (kui mitte → restart)
- **Readiness Probe:** Kas pod valmis? (kui mitte → eemalda Service endpoint'ist)
- **Startup Probe:** Kas pod käivitus? (slow start apps)

### Rolling Update:
- **maxSurge:** Max +N pod'i ajutiselt
- **maxUnavailable:** Max N pod'i unavailable
- **Zero Downtime:** maxUnavailable=0 + readiness probe

---

## 💡 Parimad Tavad

1. **Alati määra resource requests** - HPA vajab neid
2. **Limits väiksemad kui requests** - Väldi resource starvation
3. **Readiness probe kohustuslik** - Zero downtime rolling update
4. **Liveness probe ettevaatlikult** - Vale config võib põhjustada crash loop
5. **maxUnavailable: 0 production'is** - Zero downtime
6. **HPA min/max mõistlikult** - Ära sea max=1000 kui vajad max 10
7. **Stabilization window** - Väldi flapping (scale up/down/up/down)
8. **CPU target mitte liiga madal** - 50-70% on mõistlik
9. **Monitoori HPA events** - kubectl describe hpa
10. **Testi autoscaling staging'us** - Enne prod'i

---

## 🔗 Järgmine Samm

Õnnitleme! Oled läbinud kõik Lab 4 harjutused:
✅ DNS + Nginx Reverse Proxy (Path A)
✅ Kubernetes Ingress
✅ SSL/TLS Sertifikaadid
✅ Helm Charts
✅ Autoscaling + Rolling Updates

**Järgmine Labor:** Lab 5: CI/CD Pipeline (GitHub Actions)

Lab 5'as õpid:
- GitHub Actions workflow'de loomist
- Automaatset Docker image build + push
- Kubernetes auto-deploy
- Automated testing
- Rollback strateegiaid

---

## 📚 Viited

- [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Deployments Rolling Update](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-update-deployment)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

---

**Õnnitleme! Oskad nüüd autoscale'ida ja teha zero-downtime deployments! 🚀**
