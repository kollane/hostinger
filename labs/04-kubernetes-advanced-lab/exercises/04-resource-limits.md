# Harjutus 4: Resource Limits & Quotas

**Kestus:** 45 minutit
**Eesmärk:** CPU/Memory management ja resource exhaustion vältimine

---

## 📋 Ülevaade

Selles harjutuses **seadistad resource requests & limits** ja **ResourceQuota**. Õpid, kuidas vältida resource exhaustion'it ja tagada õiglane ressursside kasutus.

**Enne vs Pärast:**
- **Enne:** Pod'id võivad kasutada kogu node CPU/memory → node crash
- **Pärast:** Garanteeritud ressursid (requests) + maksimum piirangud (limits)

---

## 🎯 Õpieesmärgid

- ✅ Mõista Resource Requests vs Limits erinevust
- ✅ Seadistada CPU ja Memory limits
- ✅ Luua ResourceQuota namespace'le
- ✅ Luua LimitRange default'ide jaoks
- ✅ Debuggida resource-related probleeme

---

## 🏗️ Arhitektuur

### Enne (Resource Limits Puuduvad ⚠️)

```
Node (2 CPU, 4GB RAM)
  ├─ Pod A (no limits) → Uses 1.5 CPU, 3GB RAM
  ├─ Pod B (no limits) → Tries to use 1 CPU, 2GB RAM
  └─ ⚠️ Node CRASH - Out of Memory!
```

### Pärast (Requests & Limits ✅)

```
Node (2 CPU, 4GB RAM)
  ├─ Pod A
  │   ├─ Requests: 500m CPU, 512Mi RAM (guaranteed)
  │   └─ Limits: 1000m CPU, 1Gi RAM (max)
  │
  ├─ Pod B
  │   ├─ Requests: 500m CPU, 512Mi RAM
  │   └─ Limits: 1000m CPU, 1Gi RAM
  │
  └─ ✅ Total requests: 1 CPU, 1GB → Safe (50% utilization)
      Max possible: 2 CPU, 2GB → Still within node capacity
```

---

## 📝 Sammud

### Samm 1: Mõista Requests vs Limits (5 min)

**2 kontseptsiooni:**

1. **Requests (Garanteeritud):**
   - Minimaalne ressurss, mida pod VAJAB
   - Kubernetes scheduler kasutab seda pod placement'iks
   - Kui node'il ei ole piisavalt vaba requests → pod ei saa scheduled

2. **Limits (Maksimum):**
   - Maksimaalne ressurss, mida pod TOHIB kasutada
   - CPU limit → Throttling (aeglustamine)
   - Memory limit → OOMKilled (Out of Memory)

**Näide:**

```yaml
resources:
  requests:
    cpu: 100m      # 0.1 CPU core (guaranteed)
    memory: 128Mi  # 128 MiB (guaranteed)
  limits:
    cpu: 500m      # 0.5 CPU core (max)
    memory: 512Mi  # 512 MiB (max, exceeding → OOMKill)
```

**QoS Classes (Quality of Service):**

| Class | Requests | Limits | Behavior |
|-------|----------|--------|----------|
| **Guaranteed** | Set | Equal to requests | Viimane OOMKilled |
| **Burstable** | Set | Higher than requests | Keskmine priority |
| **BestEffort** | Not set | Not set | Esimene OOMKilled |

### Samm 2: Seadista Deployment Resources (10 min)

Uuenda User Service Deployment resources'iga:

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
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
        
        # ========================================
        # Resource Management
        # ========================================
        resources:
          requests:
            # CPU: 100 millicore = 0.1 CPU core
            # Guaranteed minimum
            cpu: 100m
            
            # Memory: 128 MiB guaranteed
            memory: 128Mi
          
          limits:
            # CPU: 500 millicore = 0.5 CPU core max
            # Exceeding → Throttled (slowed down)
            cpu: 500m
            
            # Memory: 512 MiB max
            # Exceeding → OOMKilled (pod restart)
            memory: 512Mi
        
        # Health checks (from Exercise 3)
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Rakenda:**

```bash
kubectl apply -f user-service-deployment-resources.yaml

# Kontrolli QoS class
kubectl describe pod <user-service-pod> | grep "QoS Class"
# Oodatud: QoS Class: Burstable
```

**CPU units:**
- `1000m` = 1 CPU core
- `500m` = 0.5 CPU core
- `100m` = 0.1 CPU core (10% of core)
- `1` = 1 CPU core (sama mis 1000m)

**Memory units:**
- `128Mi` = 128 Mebibytes (1024-based)
- `128M` = 128 Megabytes (1000-based)
- `1Gi` = 1 Gibibyte
- `1G` = 1 Gigabyte

### Samm 3: Loo ResourceQuota Namespace'le (10 min)

**ResourceQuota limiteerib terve namespace ressursse.**

Loo `resource-quota.yaml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: default  # Või oma namespace
spec:
  hard:
    # CPU limits
    requests.cpu: "2"       # Max 2 CPU cores requests kokku
    limits.cpu: "4"         # Max 4 CPU cores limits kokku
    
    # Memory limits
    requests.memory: 4Gi    # Max 4GB requests kokku
    limits.memory: 8Gi      # Max 8GB limits kokku
    
    # Pod count
    pods: "20"              # Max 20 pod'i namespace'is
    
    # PersistentVolumeClaims
    persistentvolumeclaims: "5"
    requests.storage: 50Gi  # Max 50GB storage
    
    # Services
    services: "10"
    services.loadbalancers: "2"
    services.nodeports: "5"
```

**Rakenda:**

```bash
kubectl apply -f resource-quota.yaml

# Kontrolli
kubectl get resourcequota
kubectl describe resourcequota compute-quota
```

**Oodatud väljund:**

```
Name:                   compute-quota
Namespace:              default
Resource                Used    Hard
--------                ----    ----
limits.cpu              1       4
limits.memory           1Gi     8Gi
persistentvolumeclaims  2       5
pods                    5       20
requests.cpu            200m    2
requests.memory         256Mi   4Gi
requests.storage        10Gi    50Gi
services                3       10
```

### Samm 4: Loo LimitRange Default'ide Jaoks (10 min)

**LimitRange määrab default'id ja min/max väärtused.**

Loo `limit-range.yaml`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: default
spec:
  limits:
  # Container default'id
  - type: Container
    default:  # Default LIMITS (kui ei määratud)
      cpu: 500m
      memory: 512Mi
    defaultRequest:  # Default REQUESTS (kui ei määratud)
      cpu: 100m
      memory: 128Mi
    min:  # Minimaalne lubatud
      cpu: 50m
      memory: 64Mi
    max:  # Maksimaalne lubatud
      cpu: 2000m  # 2 CPU cores max per container
      memory: 2Gi
    maxLimitRequestRatio:  # Max ratio limits/requests
      cpu: 10     # Limit võib olla max 10x requests
      memory: 4   # Limit võib olla max 4x requests
  
  # Pod total limits
  - type: Pod
    max:
      cpu: 4000m  # 4 CPU cores max per pod (all containers combined)
      memory: 4Gi
  
  # PersistentVolumeClaim
  - type: PersistentVolumeClaim
    min:
      storage: 1Gi
    max:
      storage: 20Gi
```

**Rakenda:**

```bash
kubectl apply -f limit-range.yaml

# Kontrolli
kubectl get limitrange
kubectl describe limitrange resource-limits
```

**Testimine:**

```bash
# Loo pod ILMA resources määratult
kubectl run test-pod --image=nginx:1.25-alpine

# Kontrolli - peaks olema default'id rakendatud
kubectl get pod test-pod -o yaml | grep -A 10 resources

# Cleanup
kubectl delete pod test-pod
```

### Samm 5: Test Resource Limits (10 min)

**5a. CPU Limit Test (Throttling)**

Loo `cpu-stress.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-stress-test
spec:
  containers:
  - name: stress
    image: polinux/stress:1.0.4
    resources:
      requests:
        cpu: 100m
      limits:
        cpu: 200m  # Limit 0.2 CPU
    command: ["stress"]
    args: ["--cpu", "2", "--timeout", "60s"]  # Try use 2 CPUs
```

```bash
kubectl apply -f cpu-stress.yaml

# Jälgi CPU kasutust
kubectl top pod cpu-stress-test

# Oodatud: CPU ~200m (throttled to limit)
# Kui limit poleks → CPU would be ~2000m
```

**5b. Memory Limit Test (OOMKill)**

Loo `memory-stress.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-stress-test
spec:
  containers:
  - name: stress
    image: polinux/stress:1.0.4
    resources:
      requests:
        memory: 128Mi
      limits:
        memory: 256Mi  # Max 256MB
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "512M", "--timeout", "30s"]
```

```bash
kubectl apply -f memory-stress.yaml

# Vaata pod'i
kubectl get pod memory-stress-test

# Oodatud: OOMKilled (memory exceeded limit)
kubectl describe pod memory-stress-test | grep -A 5 "Last State"

# Output:
# Last State: Terminated
#   Reason: OOMKilled
#   Exit Code: 137
```

**Cleanup:**

```bash
kubectl delete pod cpu-stress-test memory-stress-test
```

---

## ✅ Kontrolli Tulemusi

- [ ] Deployment'il on resource requests ja limits
- [ ] QoS Class on Burstable või Guaranteed
- [ ] ResourceQuota loodud ja rakendatud
- [ ] LimitRange loodud ja default'id töötavad
- [ ] CPU throttling test õnnestus (200m limit)
- [ ] Memory OOMKill test õnnestus (256Mi limit)

---

## 🎓 Õpitud Mõisted

**Resource Requests:**
- Garanteeritud minimaalne ressurss
- Scheduler kasutab placement'iks
- QoS class määramine

**Resource Limits:**
- Maksimaalne lubatud ressurss
- CPU → Throttling
- Memory → OOMKill

**ResourceQuota:**
- Namespace-level piirangud
- Total requests/limits summa
- Pod/Service count limits

**LimitRange:**
- Default values kui ei määratud
- Min/max validation
- Ratio limits/requests

**QoS Classes:**
- **Guaranteed** - Requests = Limits
- **Burstable** - Requests < Limits
- **BestEffort** - No requests/limits

---

## 💡 Parimad Praktikad

1. **Alati määra requests** - Scheduler vajab seda
2. **Limits production'is** - Väldi resource exhaustion
3. **Requests ≈ avg usage** - Optimaalne resource utilization
4. **Limits = max burst** - Luba lühiajaline spike
5. **Memory requests = limits** - Väldi OOMKill'i (kui võimalik)
6. **ResourceQuota namespace'le** - Multi-tenant environment
7. **LimitRange default'id** - Sunnitud resources määramine

**Recommended ratios:**

```yaml
# Web API (burstable)
requests:
  cpu: 100m
  memory: 128Mi
limits:
  cpu: 500m     # 5x requests
  memory: 512Mi # 4x requests

# Database (guaranteed)
requests:
  cpu: 1000m
  memory: 2Gi
limits:
  cpu: 1000m    # Same as requests
  memory: 2Gi   # Same as requests
```

---

## 🐛 Levinud Probleemid

### "Pod stuck in Pending (Insufficient CPU)"

```bash
# Kontrolli node capacity
kubectl describe node <node-name> | grep -A 5 "Allocated resources"

# Probleem: Liiga suured requests, node ei mahu
# Lahendus: Vähenda requests VÕI kasuta suurem node
```

### "Pod OOMKilled (137 exit code)"

```bash
kubectl describe pod <pod-name> | grep "Last State"
# Exit Code: 137 = OOMKilled

# Probleem: Memory limit liiga madal
# Lahendus: Suurenda memory limits
```

### "CPU throttling (slow app)"

```bash
# Kontrolli CPU kasutust vs limit
kubectl top pod <pod-name>

# Kui kasutus = limit → throttled
# Lahendus: Suurenda CPU limits
```

### "Error: failed quota"

```bash
kubectl describe resourcequota

# Probleem: Namespace quota exceeded
# Lahendus: Suurenda quota VÕI cleanup unused resources
```

---

## 🔗 Järgmine Samm

Järgmises harjutuses õpid **Helm Package Manager** templating'ut ja release management'i!

**Jätka:** [Harjutus 5: Helm Basics](05-helm-basics.md)

---

## 📚 Viited

- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
- [LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/)
- [QoS Classes](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)

---

**Õnnitleme! Oled seadistanud production-ready resource management! 🎉**
