# Harjutus 3: Rolling Updates & Health Checks

**Kestus:** 45 minutit
**Eesmärk:** Zero-downtime deployments liveness & readiness probe'idega

---

## 📋 Ülevaade

Selles harjutuses **implementeerid zero-downtime update strateegia** ja **health check'id**. Õpid rolling updates'i, liveness/readiness probe'e ja rollback mehhanisme.

**Enne vs Pärast:**
- **Enne:** `kubectl apply` → downtime, crashloop'id
- **Pärast:** Rolling update → 0% downtime, controlled rollout

---

## 🎯 Õpieesmärgid

- ✅ Mõista Rolling Update strateegiaid
- ✅ Konfigureerida Liveness ja Readiness Probe'e
- ✅ Teha zero-downtime update
- ✅ Rollback'ida ebaõnnestunud deployment
- ✅ Monitoorida deployment progressi

---

## 🏗️ Arhitektuur

### Recreate Strategy (Downtime ⚠️)

```
Update start:
  ├─ Terminate ALL old pods
  ├─ ⏸️ DOWNTIME (5-30 seconds)
  └─ Create new pods

Service: UNAVAILABLE during update
```

### Rolling Update Strategy (Zero Downtime ✅)

```
Update start:
  ├─ Pod 1 (v1.0) → Running
  ├─ Pod 2 (v1.0) → Running
  ├─ Pod 3 (v1.1) → Creating...
  └─ Pod 4 (v1.1) → Creating...

Readiness probe passes:
  ├─ Pod 3 (v1.1) → Ready ✅
  └─ Pod 1 (v1.0) → Terminating

Final state:
  ├─ Pod 2 (v1.0) → Terminating
  ├─ Pod 3 (v1.1) → Running ✅
  └─ Pod 4 (v1.1) → Running ✅

Service: ALWAYS AVAILABLE (mixed v1.0 + v1.1 during update)
```

---

## 📝 Sammud

### Samm 1: Mõista Health Check Tüüpe (5 min)

**3 tüüpi probe'e:**

1. **Liveness Probe** (Kas konteiner on elus?)
   - Kui **FAIL** → Kubernetes RESTART'ib konteineri
   - Kasutusjuht: Deadlock, infinite loop, crash
   - Näide: Rakendus hangus, aga protsess töötab

2. **Readiness Probe** (Kas konteiner on valmis liiklust vastu võtma?)
   - Kui **FAIL** → Pod eemaldatakse Service endpoint'idest
   - Kasutusjuht: Startup latency, dependency check (DB connection)
   - Näide: Rakendus käivitub, aga DB pole veel ühendatud

3. **Startup Probe** (Kas konteiner on käivitunud?)
   - Kui **FAIL** → Kubernetes RESTART'ib konteineri
   - Ainult käivitamisel
   - Kasutusjuht: Aeglane startup (legacy apps)

**Tüüpiline setup:**

```yaml
livenessProbe:  # "Kas elus?"
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3  # 3 fail'i → restart

readinessProbe:  # "Kas valmis?"
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 2  # 2 fail'i → remove from Service
```

### Samm 2: Lisa Health Check Endpoint'id (10 min)

**Kontrolli kas User Service on /health endpoint:**

```bash
# Kui User Service juba töötab
kubectl exec -it <user-service-pod> -- wget -q -O- http://localhost:3000/health

# Oodatud vastus:
# {"status":"healthy","timestamp":"..."}
```

**Kui puudub, lisa oma rakendusele:**

Näidis Node.js endpoint (peaks olema juba `labs/apps/backend-nodejs/server.js`):

```javascript
// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Readiness endpoint (kontrollib DB ühendust)
app.get('/ready', async (req, res) => {
  try {
    await db.query('SELECT 1'); // Quick DB check
    res.status(200).json({ 
      status: 'ready',
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'not ready',
      error: error.message 
    });
  }
});
```

### Samm 3: Konfigureeri Deployment Health Check'idega (10 min)

Loo `user-service-deployment-rolling.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 3
  
  # Rolling Update strateegia
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1       # Max 1 extra pod (total 4 during update)
      maxUnavailable: 0 # Min 3 pods ALWAYS available (zero downtime)
  
  selector:
    matchLabels:
      app: user-service
      version: v1.0  # Versioning
  
  template:
    metadata:
      labels:
        app: user-service
        version: v1.0
    spec:
      containers:
      - name: user-service
        image: user-service:1.0
        ports:
        - containerPort: 3000
        
        env:
        - name: DB_HOST
          value: "postgres-user"
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
        
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        
        # Liveness Probe - Kas konteiner on elus?
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30  # Oota 30s enne esimest check'i
          periodSeconds: 10        # Check iga 10s
          timeoutSeconds: 5        # Timeout 5s
          failureThreshold: 3      # 3 fail'i → RESTART
          successThreshold: 1      # 1 success → healthy
        
        # Readiness Probe - Kas valmis liiklust vastu võtma?
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5   # Alusta kohe
          periodSeconds: 5         # Check iga 5s
          timeoutSeconds: 3
          failureThreshold: 2      # 2 fail'i → NOT READY
          successThreshold: 1
        
        # Startup Probe (optional) - Aeglane käivitamine
        startupProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 0
          periodSeconds: 5
          failureThreshold: 12     # 12 * 5s = 60s max startup time
```

**Rakenda:**

```bash
kubectl apply -f user-service-deployment-rolling.yaml

# Kontrolli
kubectl get deployment user-service
kubectl describe deployment user-service
```

### Samm 4: Testi Rolling Update (15 min)

**4a. Vaata algseisu**

```bash
# Pods ja nende versioonid
kubectl get pods -l app=user-service -L version

# Deployment revision
kubectl rollout history deployment/user-service
```

**4b. Simulate update (muuda image tag)**

Loo uus image (või kasuta sama, testimiseks):

```bash
# Variant 1: Tag sama image uue versiooniga
docker tag user-service:1.0 user-service:1.1

# Variant 2: Muuda environment variable (testimiseks)
kubectl set env deployment/user-service VERSION=1.1
```

**4c. Trigger rolling update**

```bash
# Update image
kubectl set image deployment/user-service user-service=user-service:1.1

# VÕI muuda label
kubectl patch deployment user-service -p '{"spec":{"template":{"metadata":{"labels":{"version":"v1.1"}}}}}'
```

**4d. Jälgi update progressi**

```bash
# Terminal 1: Rollout status
kubectl rollout status deployment/user-service

# Terminal 2: Watch pods (real-time)
watch kubectl get pods -l app=user-service -L version

# Terminal 3: Events
kubectl get events --watch | grep user-service
```

**Oodatud käitumine:**

```
0:00 - 3 pods (v1.0) running
0:05 - Create pod-4 (v1.1)
0:10 - pod-4 (v1.1) readiness check...
0:15 - pod-4 (v1.1) READY → Terminate pod-1 (v1.0)
0:20 - Create pod-5 (v1.1)
0:25 - pod-5 (v1.1) READY → Terminate pod-2 (v1.0)
0:30 - Create pod-6 (v1.1)
0:35 - pod-6 (v1.1) READY → Terminate pod-3 (v1.0)
0:40 - ✅ Update complete! 3 pods (v1.1) running

ZERO DOWNTIME: Alati vähemalt 3 pod'i (maxUnavailable: 0)
```

**4e. Test continuous availability**

Käivita paralleelselt load test:

```bash
# Terminal 4: Continuous requests
while true; do 
  curl -s http://<SERVICE-IP>:3000/health | jq .status
  sleep 0.5
done

# Oodatud: Ükski request EI FAILI (zero downtime)
```

### Samm 5: Rollback Ebaõnnestunud Update (5 min)

**Simulei vigane update:**

```bash
# Deploy vigane image (ei eksisteeri)
kubectl set image deployment/user-service user-service=user-service:broken

# Jälgi
kubectl rollout status deployment/user-service
# Oodatud: "Waiting for deployment spec update to be observed..."

kubectl get pods -l app=user-service
# Näed: ImagePullBackOff või ErrImagePull
```

**Rollback:**

```bash
# Variant 1: Undo viimane rollout
kubectl rollout undo deployment/user-service

# Variant 2: Rollback konkreetsele revision'ile
kubectl rollout history deployment/user-service
kubectl rollout undo deployment/user-service --to-revision=2

# Kontrolli
kubectl rollout status deployment/user-service
kubectl get pods -l app=user-service
```

**Verifitseeri:**

```bash
# Pods peaksid olema tagasi v1.0
kubectl get pods -l app=user-service -L version

# Deployment history
kubectl rollout history deployment/user-service
```

---

## ✅ Kontrolli Tulemusi

- [ ] Deployment'il on liveness ja readiness probe'id
- [ ] Rolling update strateegia seadistatud (`maxSurge: 1, maxUnavailable: 0`)
- [ ] Update teostatud (`kubectl set image`)
- [ ] Update oli zero-downtime (curl test ei failinud)
- [ ] Rollback toimis (`kubectl rollout undo`)
- [ ] Pods on tagasi stable versioonil

---

## 🎓 Õpitud Mõisted

**Rolling Update:**
- Järk-järguline pod'ide asendamine
- `maxSurge` - max extra pods
- `maxUnavailable` - max unavailable pods
- Zero-downtime võimaldamine

**Liveness Probe:**
- Kontrollib kas konteiner on elus
- Fail → Kubernetes restart'ib
- Kasutusjuht: Deadlock, crash

**Readiness Probe:**
- Kontrollib kas valmis liiklust vastu võtma
- Fail → Remove from Service endpoints
- Kasutusjuht: Startup latency, DB connection

**Rollback:**
- `kubectl rollout undo` - tagasi viimane revision
- `--to-revision=N` - konkreetne revision
- Deployment history säilib

**Revision History:**
- `kubectl rollout history` - vaata ajalugu
- `.spec.revisionHistoryLimit` - max salvestatud revisions

---

## 💡 Parimad Praktikad

1. **maxUnavailable: 0** - Zero downtime (kui piisavalt ressursse)
2. **Readiness probe kohustuslik** - Väldi liiklust poolelioleva pod'ile
3. **Liveness probe initialDelay** - Anna aega startup'iks
4. **failureThreshold ≥ 3** - Väldi false positive restart'e
5. **Resource requests** - Garanteeri pod'i jaoks ressursid
6. **Test rollback** - Veendu et rollback toimib

---

## 🐛 Levinud Probleemid

### "Pods crashloop'ivad pärast update'i"

```bash
# Kontrolli liveness probe
kubectl describe pod <pod-name> | grep -A 10 Liveness

# Probleem: initialDelaySeconds liiga lühike
# Lahendus: Suurenda initialDelaySeconds (nt 30s)
```

### "Update on 'stuck' pooleli"

```bash
# Kontrolli readiness probe
kubectl describe pod <new-pod> | grep -A 10 Readiness

# Probleem: Readiness probe never passes
# Lahendus: Kontrolli /ready endpoint'i või eemalda probe (ajutiselt)
```

### "Service downtime update ajal"

```bash
# Kontrolli rollingUpdate config
kubectl get deployment user-service -o yaml | grep -A 5 rollingUpdate

# Probleem: maxUnavailable > 0
# Lahendus: Seadista maxUnavailable: 0
```

---

## 🔗 Järgmine Samm

Järgmises harjutuses õpid **Resource Limits & Quotas** production-ready resource management'i jaoks!

**Jätka:** [Harjutus 4: Resource Limits](04-resource-limits.md)

---

## 📚 Viited

- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [Liveness & Readiness Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)
- [Rollback](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)

---

**Õnnitleme! Oled implementeerinud zero-downtime deployments! 🎉**
