# Harjutus 2: Horizontal Pod Autoscaler (HPA)

**Kestus:** 45 minutit
**Eesmärk:** Automaatne skaleerimine koormus põhiselt

---

## 📋 Ülevaade

Selles harjutuses **seadistad automaatse skaleerimise** User Service'le. Õpid paigaldama Metrics Server'it ja konfigureerima CPU-based autoscaling'ut.

**Enne vs Pärast:**
- **Enne (Lab 3):** Fikseeritud 2 replicas
- **Pärast (Lab 4):** 2-10 replicas (automaatne CPU põhine)

---

## 🎯 Õpieesmärgid

- ✅ Mõista HPA (Horizontal Pod Autoscaler) kontseptsiooni
- ✅ Paigaldada Metrics Server
- ✅ Luua HPA ressurssi CPU metrics'iga
- ✅ Testida autoscaling'ut load testiga
- ✅ Debuggida HPA probleeme

---

## 🏗️ Arhitektuur

### Enne (Fikseeritud Replicas)

```
User Service Deployment
  replicas: 2 (fikseeritud)
  ├─ Pod 1 (CPU: 80%) ⚠️ Overloaded
  └─ Pod 2 (CPU: 85%) ⚠️ Overloaded
```

### Pärast (HPA)

```
Metrics Server
  ↓ (küsib CPU/Memory metrics)
User Service Deployment
  ↓
HPA Controller
  ├─ Min: 2 replicas
  ├─ Max: 10 replicas
  └─ Target CPU: 50%

Koormus madal (CPU < 50%):
  2 pods (minimum)

Koormus kõrge (CPU > 50%):
  ├─ Pod 1 (CPU: 45%)
  ├─ Pod 2 (CPU: 48%)
  ├─ Pod 3 (CPU: 47%)
  ├─ Pod 4 (CPU: 44%)
  └─ ... up to 10 pods
```

---

## 📝 Sammud

### Samm 1: Mõista HPA Kontseptsiooni (5 min)

**HPA = Horizontal Pod Autoscaler**

**Kuidas töötab?**
1. Metrics Server kogub CPU/Memory kasutust Pod'idest
2. HPA kontrollib target metrics'it (nt CPU < 50%)
3. Kui CPU > 50% → Lisa pod'e
4. Kui CPU < 50% → Eemalda pod'e (min replicas piires)

**HPA vs VPA:**
- **HPA (Horizontal):** Lisa/eemalda pod'e (rohkem/vähem koopiad)
- **VPA (Vertical):** Suurenda/vähenda pod'i ressursse (CPU/memory)

**Millal kasutada HPA?**
- Stateless rakendused (API serverid, frontend)
- Muutuv koormus (päeval palju, öösel vähe)
- Kiire scale-out vajadus

**Millal MITTE kasutada?**
- StatefulSet'id (andmebaasid) - kasuta VPA
- Konstantne koormus - fikseeritud replicas piisab

### Samm 2: Paigalda Metrics Server (10 min)

**Metrics Server on kohustuslik HPA jaoks!**

**Kontrolli kas juba paigaldatud:**

```bash
kubectl get deployment metrics-server -n kube-system
```

**Kui puudub, paigalda:**

```bash
# Official manifest
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Kontrolli paigaldust
kubectl get deployment metrics-server -n kube-system

# Oodatud:
# NAME             READY   UP-TO-DATE   AVAILABLE
# metrics-server   1/1     1            1
```

**Minikube/K3s special config (kui TLS errors):**

```bash
# K3s/Minikube vajab --kubelet-insecure-tls
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

**Verifitseeri metrics:**

```bash
# Oota 1-2 minutit, siis:
kubectl top nodes
kubectl top pods

# Kui näed CPU/Memory kasutust → Metrics Server töötab! ✅
```

### Samm 3: Valmista Deployment Ette (5 min)

**HPA vajab resource requests määratud!**

Kontrolli kas User Service Deployment'il on `resources.requests.cpu` määratud:

```bash
kubectl get deployment user-service -o yaml | grep -A 5 resources
```

**Kui puudub, lisa:**

Loo fail `user-service-deployment-with-resources.yaml`:

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
        ports:
        - containerPort: 3000
        env:
        - name: DB_HOST
          value: "postgres-user"
        - name: DB_PORT
          value: "5432"
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
        
        # ⚠️ OLULINE: HPA vajab resources.requests!
        resources:
          requests:
            cpu: 100m      # 0.1 CPU core
            memory: 128Mi
          limits:
            cpu: 500m      # 0.5 CPU core max
            memory: 512Mi
```

**Rakenda:**

```bash
kubectl apply -f user-service-deployment-with-resources.yaml

# Kontrolli
kubectl describe deployment user-service | grep -A 4 "Limits:"
```

### Samm 4: Loo HPA Ressurss (10 min)

Loo `hpa-user-service.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: user-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: user-service
  
  minReplicas: 2
  maxReplicas: 10
  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50  # Scale kui CPU > 50%
  
  # Optional: Memory-based scaling
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70  # Scale kui Memory > 70%
  
  # Scaling behavior (optional)
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0  # Koheselt scale up
      policies:
      - type: Percent
        value: 100  # Double pods igal sammul
        periodSeconds: 15
      - type: Pods
        value: 4    # Max 4 pod'i korraga
        periodSeconds: 15
      selectPolicy: Max  # Vali agressiivsem policy
    
    scaleDown:
      stabilizationWindowSeconds: 300  # Oota 5 min enne scale down
      policies:
      - type: Percent
        value: 50   # Remove 50% pods igal sammul
        periodSeconds: 60
```

**Rakenda:**

```bash
kubectl apply -f hpa-user-service.yaml

# Kontrolli
kubectl get hpa
kubectl describe hpa user-service-hpa
```

**Oodatud väljund:**

```
NAME                REFERENCE                TARGETS   MINPODS   MAXPODS   REPLICAS
user-service-hpa   Deployment/user-service   12%/50%   2         10        2
```

### Samm 5: Testi Autoscaling (10 min)

**5a. Genereeri koormus (Load Test)**

Kasuta `kubectl run` testimiseks:

```bash
# Loo load generator pod
kubectl run load-generator --image=busybox:1.36 --restart=Never -- /bin/sh -c \
  "while true; do wget -q -O- http://user-service:3000/health; done"

# Või Apache Bench (rohkem koormust)
kubectl run load-generator --image=httpd:2.4-alpine --restart=Never -- \
  sh -c "apk add --no-cache apache2-utils && ab -n 100000 -c 100 http://user-service:3000/health"
```

**5b. Jälgi skaleerimist**

```bash
# Terminal 1: HPA status
watch kubectl get hpa user-service-hpa

# Terminal 2: Pods
watch kubectl get pods -l app=user-service

# Terminal 3: Metrics
watch kubectl top pods -l app=user-service
```

**Oodatud käitumine:**

```
0:00 - CPU 15%, 2 pods
0:30 - CPU 65%, HPA detekteerib ülekoormuse
1:00 - CPU 70%, HPA skaleerib → 4 pods
1:30 - CPU 55%, HPA skaleerib → 6 pods
2:00 - CPU 45%, stabiliseerunud 6 pods

(Peata load test)

7:00 - CPU 10%, HPA scale down → 4 pods (5 min stabilization)
12:00 - CPU 5%, HPA scale down → 2 pods (min replicas)
```

**5c. Peata load test**

```bash
kubectl delete pod load-generator
```

### Samm 6: Debug HPA Probleeme (5 min)

```bash
# 1. Kontrolli HPA staatust
kubectl get hpa user-service-hpa
# TARGETS peaks olema "12%/50%" (mitte "<unknown>/50%")

# 2. Kui "<unknown>", kontrolli Metrics Server
kubectl top pods
# Kui ei tööta → Metrics Server probleem

# 3. Kontrolli HPA events
kubectl describe hpa user-service-hpa
# Otsi "Events:" sektsiooni:
# - ScaledUp: Successfully scaled
# - FailedGetResourceMetric: Metrics Server error

# 4. Kontrolli resource requests
kubectl get deployment user-service -o yaml | grep -A 5 requests
# Peab olema: requests.cpu ja requests.memory

# 5. HPA logid (kui advanced debugging)
kubectl logs -n kube-system -l k8s-app=metrics-server
```

**Levinud probleemid:**

| Probleem | Põhjus | Lahendus |
|----------|--------|----------|
| `<unknown>/50%` | Metrics Server puudub | Paigalda Metrics Server |
| `FailedGetResourceMetric` | Deployment'il puudub `requests.cpu` | Lisa `resources.requests` |
| HPA ei skaleeri | CPU liiga madal | Genereeri rohkem koormust |
| Liiga kiire scale down | `stabilizationWindowSeconds` puudub | Lisa `behavior.scaleDown` |

---

## ✅ Kontrolli Tulemusi

- [ ] Metrics Server töötab (`kubectl top pods`)
- [ ] HPA loodud (`kubectl get hpa`)
- [ ] HPA näitab metrics (`12%/50%`, mitte `<unknown>`)
- [ ] Load test käivitus (`kubectl run load-generator`)
- [ ] HPA skaleeris üles (2 → 4+ pods)
- [ ] HPA skaleeris alla pärast koormuse kadumist (4 → 2 pods)

---

## 🎓 Õpitud Mõisted

**Horizontal Pod Autoscaler (HPA):**
- Automaatne pod'ide arvu muutmine
- CPU/Memory metrics põhine
- Min/max replicas piirid

**Metrics Server:**
- Kogub resource metrics'id (CPU/Memory)
- HPA sõltub sellest
- `kubectl top` kasutab seda

**Resource Requests:**
- `requests.cpu` - garanteeritud CPU
- HPA arvutab kasutuse % requests'ist
- KOHUSTUSLIK HPA jaoks

**autoscaling/v2:**
- Uuem API (Kubernetes 1.23+)
- Toetab mitut metric'it korraga
- Behavior policy (scale up/down speed)

---

## 💡 Parimad Praktikad

1. **Alati määra resource requests** - HPA ei tööta ilma
2. **Stabilization window** - Väldi liiga kiiret scale down'i
3. **Min replicas ≥ 2** - High availability
4. **Max replicas** - Väldi resource exhaustion
5. **Memory + CPU** - Kasuta mõlemat metric'it
6. **Load testing** - Testi autoscaling enne production'i

---

## 🐛 Levinud Probleemid

### "HPA TARGETS: <unknown>/50%"

```bash
# Põhjus: Metrics Server puudub või ei tööta
kubectl get deployment metrics-server -n kube-system

# Lahendus: Paigalda Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### "FailedGetResourceMetric"

```bash
# Põhjus: Deployment'il puudub resources.requests
kubectl get deployment user-service -o yaml | grep requests

# Lahendus: Lisa resources.requests.cpu
# Vaata Samm 3
```

### "HPA ei skaleeri"

```bash
# Kontrolli CPU kasutust
kubectl top pods -l app=user-service

# Kui CPU < 50% → Genereeri rohkem koormust
# Kui CPU > 50% → Kontrolli HPA events
kubectl describe hpa user-service-hpa
```

---

## 🔗 Järgmine Samm

Järgmises harjutuses õpid **Rolling Updates** ja **Zero-Downtime Deployments**!

**Jätka:** [Harjutus 3: Rolling Updates](03-rolling-updates.md)

---

## 📚 Viited

- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [HPA Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
- [autoscaling/v2 API](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/)

---

**Õnnitleme! Oled seadistanud automaatse skaleerimise! 🎉**
