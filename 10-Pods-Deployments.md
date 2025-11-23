# Peatükk 10: Pods ja Deployments

**Kestus:** 4 tundi
**Eeldused:** Peatükk 9 (Kubernetes alused, K3s setup)
**Eesmärk:** Mõista Kubernetes põhilisi abstraktsioone rakenduste deploy'miseks

---

## Õpieesmärgid

Selle peatüki lõpuks oskad:
- Mõista Pod'i kui Kubernetes'e väikseimat deploy'itavat ühikut
- Kirjutada Pod ja Deployment manifest'e
- Konfigureerida resource limits ja health checks
- Hallata ReplicaSets ja replica skaalerimist
- Teostada rolling updates ja rollbacks

---

## 10.1 Pod - Kubernetes Põhiabstraktsioon

### Mis on Pod?

**Definitsioon:**
> Pod on väikseim deploy'itav ühik Kubernetes'es. Pod sisaldab ühte või rohkem konteinereid, mis jagavad võrku ja storage'i.

**Pod vs Container:**

```
Docker:
Container = iseseisev ühik (network, storage, process)

Kubernetes:
Pod = 1+ containers (shared network, shared storage, isolated processes)
```

**Miks mitte otse Container?**

1. **Co-located containers:**
   - Main app container + logging sidecar
   - Main app + metrics exporter
   - Shared lifecycle (start/stop koos)

2. **Shared resources:**
   - Network namespace: localhost communication (127.0.0.1)
   - Storage volumes: shared PersistentVolumeClaim
   - IPC namespace: shared memory

**Praktiline näide:**

```yaml
# Pod with 2 containers (main app + logging sidecar)
apiVersion: v1
kind: Pod
metadata:
  name: backend-with-logging
spec:
  containers:
  - name: backend
    image: backend-nodejs:1.0
    volumeMounts:
    - name: logs
      mountPath: /var/log/app

  - name: log-forwarder
    image: fluent/fluent-bit:latest
    volumeMounts:
    - name: logs
      mountPath: /var/log/app

  volumes:
  - name: logs
    emptyDir: {}
```

**Arhitektuur:**

```
Pod (IP: 10.244.1.5)
│
├── Container: backend (port 3000)
│   └── Writes logs to /var/log/app/
│
├── Container: log-forwarder
│   └── Reads logs from /var/log/app/
│   └── Forwards to Loki
│
└── Shared Volume: emptyDir (logs)
```

**Communication:**
- Backend → Log-forwarder: `curl localhost:24224` (same Pod!)
- External → Backend: `curl 10.244.1.5:3000` (Pod IP)

---

### Pod Lifecycle

**Pod states:**

1. **Pending:** Pod created, not yet scheduled to Node
2. **Running:** Pod scheduled, containers running
3. **Succeeded:** All containers terminated successfully (exit 0)
4. **Failed:** At least one container failed (exit code ≠ 0)
5. **Unknown:** Cannot determine state (Node lost connection)

**Lifecycle workflow:**

```
1. kubectl apply -f pod.yaml
   → API Server receives request

2. Scheduler assigns Pod to Node
   → Pending → Running

3. Kubelet (on Node) pulls image
   → docker pull backend-nodejs:1.0

4. Kubelet starts container
   → docker run backend-nodejs:1.0

5. Container runs
   → Running state

6. Container exits (crash or completion)
   → Failed or Succeeded

7. Pod restart policy applies
   → Always: restart container
   → OnFailure: restart only if failed
   → Never: don't restart
```

**Pod Ephemeral Nature:**

**Kriitlik kontseptsioon:**
> Pods are EPHEMERAL (ajutised). Pod kustub → kõik data kaob (v.a. PersistentVolumes).

**Mida see tähendab DevOps'ile:**

```
Pod crashib või kustub:
→ New Pod created with NEW IP address
→ All in-memory state LOST
→ Containers restart from IMAGE (not from checkpoint)

Järeldus:
- Stateless applications: OK (no problem)
- Stateful applications: Use PersistentVolumes!
```

📖 **Praktika:** Labor 3, Harjutus 2 - Pod lifecycle ja restart policies

---

## 10.2 Pod Manifest - YAML Struktuur

### Minimal Pod Manifest

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: backend
  labels:
    app: backend
    tier: api
spec:
  containers:
  - name: backend
    image: backend-nodejs:1.0
    ports:
    - containerPort: 3000
```

**Põhikomponendid:**

**1. apiVersion:**
- `v1` - Core API (Pod, Service, ConfigMap)
- `apps/v1` - Apps API (Deployment, StatefulSet)
- `batch/v1` - Batch jobs (Job, CronJob)

**2. kind:**
- Pod, Deployment, Service, ConfigMap, Secret, ...
- Kubernetes object type

**3. metadata:**
- name: Unique identifier (pod name)
- labels: Key-value pairs (selectors, grouping)
- annotations: Non-identifying metadata (comments, configs)

**4. spec:**
- Desired state (containers, volumes, restart policy, ...)

---

### Container Specification

```yaml
spec:
  containers:
  - name: backend
    image: backend-nodejs:1.0
    imagePullPolicy: IfNotPresent  # Always, Never, IfNotPresent

    command: ["/bin/sh"]  # Override ENTRYPOINT
    args: ["-c", "node src/index.js"]  # Override CMD

    env:
    - name: NODE_ENV
      value: production
    - name: DB_HOST
      value: postgres-service

    ports:
    - containerPort: 3000
      protocol: TCP

    volumeMounts:
    - name: config
      mountPath: /etc/config

    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
```

**Key concepts:**

**imagePullPolicy:**
- `Always`: Pull image every time (latest tag)
- `IfNotPresent`: Pull only if not cached locally
- `Never`: Never pull, use cached only

**DevOps choice:**
```yaml
# Development (test latest changes)
imagePullPolicy: Always

# Production (immutable tags)
image: backend:v1.2.3
imagePullPolicy: IfNotPresent
```

---

### Resource Requests ja Limits

**Requests vs Limits:**

```yaml
resources:
  requests:      # MINIMUM guaranteed
    memory: "128Mi"
    cpu: "100m"

  limits:        # MAXIMUM allowed
    memory: "256Mi"
    cpu: "200m"
```

**Mida need tähendavad?**

**Requests (Scheduler decision):**
```
Pod vajab vähemalt:
- 128 MiB RAM
- 100 millicores CPU (0.1 core)

Scheduler:
→ Find Node with available resources
→ If no Node has 128Mi free → Pod stays Pending
→ If Node has capacity → Schedule Pod to that Node
```

**Limits (Runtime enforcement):**
```
Pod proovib kasutada:
- More than 256 MiB RAM → OOMKilled (Out of Memory)
- More than 200m CPU → Throttled (slowed down, not killed)
```

**CPU units:**
- `1` = 1 CPU core (1000 millicores)
- `500m` = 0.5 CPU core
- `100m` = 0.1 CPU core

**Memory units:**
- `128Mi` = 128 Mebibytes (1 Mi = 1024 KiB)
- `1Gi` = 1 Gibibyte (1 Gi = 1024 MiB)
- `512M` = 512 Megabytes (1 M = 1000 KB)

**DevOps best practice:**

```yaml
# Backend (CPU-intensive)
resources:
  requests:
    cpu: "500m"     # Need 0.5 core
    memory: "256Mi"
  limits:
    cpu: "1000m"    # Can burst to 1 core
    memory: "512Mi"

# Database (memory-intensive)
resources:
  requests:
    cpu: "200m"
    memory: "1Gi"   # Need 1 GB for cache
  limits:
    cpu: "500m"
    memory: "2Gi"   # Can use up to 2 GB
```

**Miks requests ≠ limits?**

- **Requests:** Cluster capacity planning (reserve minimum)
- **Limits:** Safety net (prevent resource starvation)
- **Burstable workloads:** Can use more than requests when available

---

### Health Checks - Liveness ja Readiness Probes

**Miks health checks?**

**Probleem:**
```
Container töötab (process running)
→ Kubernetes arvab: Pod is healthy
→ Aga rakendus on deadlocked (ei vasta requests'idele)
→ Traffic saadetakse Pod'ile → errors!
```

**Lahendus: Probes**

---

#### Liveness Probe - "Is the app alive?"

**Eesmärk:** Detect crashed/deadlocked apps → restart container

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30  # Wait 30s after start
  periodSeconds: 10        # Check every 10s
  timeoutSeconds: 5        # Timeout after 5s
  failureThreshold: 3      # Fail 3 times → restart
```

**Workflow:**

```
1. Container starts
2. Wait 30s (initialDelaySeconds)
3. Every 10s: HTTP GET /health

   Response 200 OK → Healthy
   Response 500 or timeout → Unhealthy

4. 3 consecutive failures → Container RESTART
```

**Liveness check types:**

```yaml
# HTTP GET
livenessProbe:
  httpGet:
    path: /health
    port: 3000

# TCP Socket
livenessProbe:
  tcpSocket:
    port: 5432

# Command execution
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
```

---

#### Readiness Probe - "Is the app ready to serve traffic?"

**Eesmärk:** Prevent traffic to Pods that are starting up or temporarily unavailable

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3
```

**Workflow:**

```
1. Pod starts
2. Wait 10s
3. Every 5s: HTTP GET /ready

   Response 200 OK → READY (add to Service endpoints)
   Response 500 → NOT READY (remove from Service endpoints)

4. Traffic sent ONLY to READY Pods
```

**Liveness vs Readiness:**

```
Liveness:
- Detects: App is broken (deadlock, crash)
- Action: RESTART container
- Example: App deadlocked → restart

Readiness:
- Detects: App is temporarily unavailable (startup, maintenance)
- Action: REMOVE from load balancer (no restart)
- Example: DB migration running → don't send traffic
```

**Best practice:**

```yaml
# Backend application
livenessProbe:
  httpGet:
    path: /healthz       # Simple alive check
    port: 3000
  initialDelaySeconds: 60  # App needs 60s to start
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready         # Check dependencies (DB, Redis)
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 2
```

**Health endpoint implementation:**

```javascript
// /healthz - Liveness (simple)
app.get('/healthz', (req, res) => {
  res.status(200).send('OK');
});

// /ready - Readiness (check dependencies)
app.get('/ready', async (req, res) => {
  try {
    await pool.query('SELECT 1');  // DB connection check
    res.status(200).send('Ready');
  } catch (err) {
    res.status(500).send('Not ready');
  }
});
```

📖 **Praktika:** Labor 3, Harjutus 3 - Liveness ja readiness probes

---

## 10.3 Deployment - Production-Ready Abstractions

### Miks mitte otse Pods?

**Probleem Pod'idega:**

```yaml
# Create Pod directly
kubectl apply -f pod.yaml

Probleemid:
1. Pod kustub → ei tule tagasi (manual recreation)
2. Scaling: create 5 Pods → 5 YAML faili?
3. Updates: muuda image → delete + recreate Pod
4. No rollback võimalust
5. No rolling update (zero-downtime)
```

**Lahendus: Deployment**

---

### Deployment Arhitektuur

**Hierarchy:**

```
Deployment
  └── ReplicaSet (revision 1)
       └── Pod 1 (backend-abc123)
       └── Pod 2 (backend-def456)
       └── Pod 3 (backend-ghi789)
```

**Components:**

**Deployment:**
- Desired state: 3 replicas, image backend:v1.0
- Manages ReplicaSets
- Handles updates and rollbacks

**ReplicaSet:**
- Ensures N Pods are running
- Creates/deletes Pods to match desired count
- Managed by Deployment (don't create manually)

**Pod:**
- Runs container
- Ephemeral (managed by ReplicaSet)

---

### Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: backend
spec:
  replicas: 3                    # Desired number of Pods

  selector:
    matchLabels:
      app: backend               # Which Pods belong to this Deployment

  template:                      # Pod template
    metadata:
      labels:
        app: backend             # Must match selector!
    spec:
      containers:
      - name: backend
        image: backend-nodejs:1.0
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
```

**Key concepts:**

**selector.matchLabels:**
- Deployment finds Pods by label selector
- MUST match template.metadata.labels
- Mismatch → Error: "selector does not match template labels"

**template:**
- Pod template (same as Pod manifest spec)
- Used to create new Pods
- Muudad template → new ReplicaSet → rolling update

---

## 10.4 ReplicaSet ja Replica Management

### ReplicaSet Reconciliation Loop

**How it works:**

```
1. Desired state: 3 replicas
2. Current state: 2 Pods running

Reconciliation:
→ 3 (desired) - 2 (current) = 1
→ Create 1 new Pod
→ Current state = 3 Pods
→ Desired = Current → OK
```

**Self-healing:**

```
Scenario: Node crashib

1. 3 Pods running (Node A, Node B, Node C)
2. Node B crashib → 1 Pod lost
3. Current state: 2 Pods
4. ReplicaSet controller:
   → Desired: 3, Current: 2
   → Create 1 new Pod on available Node (A or C)
5. Current state: 3 Pods → reconciled
```

**DevOps perspektive:**
> "Ma ei pea käsitsi Pods taastama. ReplicaSet teeb seda automaatselt. Self-healing."

---

### Scaling

**Manual scaling:**

```bash
# Scale to 5 replicas
kubectl scale deployment backend --replicas=5

# Workflow:
# 1. Update Deployment spec.replicas: 3 → 5
# 2. ReplicaSet controller: 5 - 3 = 2 → create 2 Pods
# 3. New Pods: backend-xxx, backend-yyy
```

**Declarative scaling (Git):**

```yaml
# deployment.yaml
spec:
  replicas: 5  # Changed from 3
```

```bash
git commit -m "Scale backend to 5 replicas"
git push

# CI/CD or GitOps:
kubectl apply -f deployment.yaml
→ ReplicaSet creates 2 new Pods
```

**Autoscaling preview (HPA - later chapter):**

```yaml
# HorizontalPodAutoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**HPA behavior:**
```
CPU > 70% → scale up (max 10 Pods)
CPU < 70% → scale down (min 3 Pods)
```

📖 **Praktika:** Labor 3, Harjutus 4 - Deployment scaling

---

## 10.5 Rolling Updates - Zero-Downtime Deployments

### Update Strategy

**Deployment update:**

```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate     # Default (vs Recreate)
    rollingUpdate:
      maxUnavailable: 1     # Max 1 Pod can be down during update
      maxSurge: 1           # Max 1 extra Pod during update
```

**Strategies:**

**1. RollingUpdate (default):**
- Gradually replace old Pods with new Pods
- Zero downtime (old Pods serve traffic until new Pods ready)

**2. Recreate:**
- Delete all old Pods → create new Pods
- Downtime (no Pods available during update)
- Kasutamine: Stateful apps that can't run multiple versions

---

### Rolling Update Workflow

**Stsenaarium:** Update image `backend:v1.0` → `backend:v1.1`

```yaml
# Update Deployment
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: backend
        image: backend-nodejs:v1.1  # Changed from v1.0
```

```bash
kubectl apply -f deployment.yaml
```

**What happens:**

```
Initial state:
ReplicaSet-1 (v1.0):
  - Pod A (v1.0) READY
  - Pod B (v1.0) READY
  - Pod C (v1.0) READY

Update:
1. Deployment creates new ReplicaSet-2 (v1.1)

2. Create 1 new Pod (maxSurge=1):
   ReplicaSet-2:
     - Pod D (v1.1) STARTING

   Traffic: A, B, C (v1.0) - still serving

3. Wait for Pod D readiness probe:
   Pod D (v1.1) READY

   Traffic: A, B, C, D (mixed versions)

4. Delete 1 old Pod (maxUnavailable=1):
   Delete Pod A (v1.0)

   Traffic: B, C, D

5. Create Pod E (v1.1):
   Pod E STARTING → READY

   Traffic: B, C, D, E

6. Delete Pod B (v1.0):
   Traffic: C, D, E

7. Create Pod F (v1.1):
   Pod F READY

   Traffic: C, D, E, F

8. Delete Pod C (v1.0):
   Traffic: D, E, F

Final state:
ReplicaSet-1 (v1.0): 0 Pods
ReplicaSet-2 (v1.1):
  - Pod D (v1.1) READY
  - Pod E (v1.1) READY
  - Pod F (v1.1) READY
```

**Key observations:**

1. **No downtime:** Always min 2 Pods available (3 - maxUnavailable:1)
2. **Max capacity:** Max 4 Pods during update (3 + maxSurge:1)
3. **Gradual rollout:** One Pod at a time
4. **Readiness gates:** New Pods must be READY before old Pods deleted

---

### maxSurge ja maxUnavailable Trade-offs

**Conservative (slow, safe):**
```yaml
rollingUpdate:
  maxUnavailable: 0    # No downtime risk
  maxSurge: 1          # Only 1 extra Pod at a time

# Update speed: Slow (one by one)
# Resource usage: Low (only +1 Pod)
# Availability: 100% (always 3 Pods ready)
```

**Aggressive (fast, more resources):**
```yaml
rollingUpdate:
  maxUnavailable: 1
  maxSurge: 2          # 2 extra Pods at a time

# Update speed: Fast (2 Pods at a time)
# Resource usage: High (up to 5 Pods: 3+2)
# Availability: 66% minimum (2/3 Pods)
```

**Production best practice:**
```yaml
rollingUpdate:
  maxUnavailable: 1    # Allow temporary capacity reduction
  maxSurge: 1          # Balanced speed and resource usage
```

📖 **Praktika:** Labor 3, Harjutus 5 - Rolling updates

---

## 10.6 Rollbacks - Undo Failed Deployments

### Deployment Revisions

**Deployment history:**

```bash
# View rollout history
kubectl rollout history deployment backend

# Output:
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl apply --filename=deployment.yaml
3         kubectl set image deployment/backend backend=backend:v1.2
```

**Revisions = ReplicaSets:**

```bash
kubectl get replicasets

# Output:
NAME                DESIRED   CURRENT   READY
backend-7d4c9df8f   3         3         3      # Revision 3 (current)
backend-6b8c5d7f9   0         0         0      # Revision 2
backend-5a7b4c6e8   0         0         0      # Revision 1
```

**Old ReplicaSets kept for rollback!**

---

### Rollback Workflow

**Scenario:** Deployment v1.2 has a critical bug

```bash
# 1. Check current status
kubectl rollout status deployment backend

# Output:
# deployment "backend" successfully rolled out

# 2. Verify issue (Pods crashing)
kubectl get pods
# backend-xxx   0/1   CrashLoopBackOff

# 3. Check logs
kubectl logs backend-xxx
# Error: Cannot connect to database (wrong connection string)

# 4. ROLLBACK to previous revision
kubectl rollout undo deployment backend

# 5. Verify rollback
kubectl rollout status deployment backend
# deployment "backend" successfully rolled out

kubectl get pods
# backend-yyy   1/1   Running  # Old ReplicaSet Pods restored
```

**What happened:**

```
Before rollback:
ReplicaSet-3 (v1.2 - broken): 3 Pods (DESIRED)
ReplicaSet-2 (v1.1 - working): 0 Pods

Rollback command:
1. Scale down ReplicaSet-3: 3 → 0
2. Scale up ReplicaSet-2: 0 → 3
3. Rolling update process (same as normal update)

After rollback:
ReplicaSet-3 (v1.2): 0 Pods
ReplicaSet-2 (v1.1): 3 Pods (DESIRED) ← Previous working version
```

---

### Specific Revision Rollback

```bash
# Rollback to specific revision
kubectl rollout undo deployment backend --to-revision=1

# Workflow:
# 1. Find ReplicaSet for revision 1
# 2. Scale up that ReplicaSet
# 3. Scale down current ReplicaSet
```

---

### Rollback Limitations

**revisionHistoryLimit:**

```yaml
spec:
  revisionHistoryLimit: 10  # Keep last 10 ReplicaSets (default)
```

**Kui revisionHistoryLimit: 2:**
```
Revisions: 1, 2, 3, 4, 5

Kept: 4, 5 (last 2)
Deleted: 1, 2, 3 (old ReplicaSets removed)

→ Can rollback to revision 4, but NOT to revision 1-3
```

**DevOps trade-off:**
- High limit (50): More rollback options, more ReplicaSets cluttering cluster
- Low limit (5): Less clutter, fewer rollback options

**Production recommendation:** 10 (default)

---

## 10.7 Deployment Best Practices

### 1. Always Use Deployments (Not Pods)

❌ **Halb:**
```yaml
kind: Pod
metadata:
  name: backend
```

✅ **Hea:**
```yaml
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
```

**Miks?**
- Self-healing
- Scaling
- Rolling updates
- Rollbacks

---

### 2. Resource Requests ja Limits

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

**Ilma resources'ita:**
- Scheduler doesn't know capacity → bad placement
- Pod võib kasutada kogu Node RAM → OOMKill'ida teisi Pods

---

### 3. Health Checks Alati

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 3000

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
```

**Ilma probes'ita:**
- Dead Pods receive traffic → errors
- Crashed apps don't restart → downtime

---

### 4. Image Tags (Not `latest`)

❌ **Halb:**
```yaml
image: backend:latest
```

✅ **Hea:**
```yaml
image: backend:v1.2.3  # Semantic versioning
# OR
image: backend:abc1234  # Git commit SHA
```

**Miks `latest` on halb?**
- Ei tea, mis versioon täpselt töötab
- Rollback on raske (mis oli "previous latest"?)
- Deployment ei triggeri update (image name ei muutu)

---

### 5. Update Strategy Configuration

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

**Test enne production'i:**
- Staging environment
- Canary deployments (advance topic)

---

### 6. Labels ja Annotations

```yaml
metadata:
  labels:
    app: backend
    tier: api
    version: v1.2.3
    env: production
  annotations:
    description: "User Service Backend API"
    maintainer: "devops-team@company.com"
```

**Labels:** Selectors, grouping, filtering
**Annotations:** Metadata, documentation, tool configs

---

## Kokkuvõte

### Mida sa õppisid?

**Pod:**
- Kubernetes'e väikseim deploy'itav ühik
- Ephemeral (ajutine) - kustub ja taastub
- Shared network + storage mitme konteineri vahel
- Lifecycle: Pending → Running → Succeeded/Failed

**Resource management:**
- Requests: Minimum guaranteed resources (scheduler)
- Limits: Maximum allowed resources (runtime)
- CPU units (millicores), Memory units (Mi, Gi)

**Health checks:**
- Liveness probe: Detect crashed apps → restart
- Readiness probe: Detect unavailable apps → remove from traffic

**Deployment:**
- Production abstraction (not raw Pods)
- Manages ReplicaSets → manages Pods
- Self-healing, scaling, updates, rollbacks

**ReplicaSet:**
- Ensures N replicas running
- Reconciliation loop (desired vs current state)
- Auto-healing when Pods die

**Rolling updates:**
- Zero-downtime deployments
- Gradual Pod replacement
- maxSurge + maxUnavailable configuration

**Rollbacks:**
- Undo failed deployments
- Revision history (old ReplicaSets)
- kubectl rollout undo

---

### DevOps Administraatori Vaatenurk

**Iga päev:**
```bash
kubectl get deployments        # Check deployment status
kubectl get pods              # Check Pod health
kubectl logs <pod>            # Troubleshoot errors
kubectl describe pod <pod>    # Detailed Pod info
```

**Deployments:**
```bash
kubectl apply -f deployment.yaml     # Deploy
kubectl scale deployment backend --replicas=5  # Scale
kubectl rollout status deployment backend     # Check update
kubectl rollout undo deployment backend       # Rollback
```

**Troubleshooting:**
```bash
kubectl get pods                    # Pod status
kubectl describe pod <name>         # Events, errors
kubectl logs <name>                 # App logs
kubectl logs <name> --previous      # Logs from crashed container
kubectl exec -it <name> -- sh       # Debug inside Pod
```

---

### Järgmised Sammud

**Peatükk 11:** Services ja Networking (stable endpoints, load balancing)
**Peatükk 12:** ConfigMaps ja Secrets (configuration management)

---

**Kestus kokku:** ~4 tundi teooriat + praktilised harjutused labides

📖 **Praktika:** Labor 3, Harjutused 2-5 - Pods, Deployments, scaling, rolling updates
