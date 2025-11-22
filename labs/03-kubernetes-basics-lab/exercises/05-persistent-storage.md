# Harjutus 5: Persistent Storage

**Kestus:** 60 minutit
**Eesmärk:** Õppida andmete püsivat salvestamist Kubernetes'es

---

## 📋 Ülevaade

Selles harjutuses õpid **Persistent Volumes (PV)** ja **Persistent Volume Claims (PVC)** - Kubernetes ressursse, mis võimaldavad **andmete säilitamist pod'ide restart'ide vahel**.

**Probleem:**
- Container file system on **ephemeral** (kaob pod restart'imisel)
- PostgreSQL andmed kaovad pod'i kustutamisel
- Stateful rakendused vajavad persistent storage'it

**Lahendus:**
- **PersistentVolume (PV):** Storage resource cluster'is
- **PersistentVolumeClaim (PVC):** Storage request (developer)
- **StatefulSet:** Deployment-like, aga stateful apps'ile (DB, cache)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista PV vs PVC vs StorageClass
- ✅ Luua PersistentVolume (hostPath)
- ✅ Luua PersistentVolumeClaim
- ✅ Mount'ida PVC pod'ile
- ✅ Testida andmete persistence
- ✅ Deploy'da StatefulSet PostgreSQL'ile
- ✅ Mõista StatefulSet vs Deployment erinevust
- ✅ Kasutada volumeClaimTemplates
- ✅ Backup ja restore volume'id

---

## 🏗️ Arhitektuur

### Deployment vs StatefulSet

```
┌────────────────────────────────────────────────────────┐
│          Deployment (Stateless Apps)                   │
│                                                        │
│  Pod'id on identsed ja vahetatavad:                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │ Pod-abc  │  │ Pod-def  │  │ Pod-xyz  │            │
│  │ Random   │  │ Random   │  │ Random   │            │
│  │ names    │  │ names    │  │ names    │            │
│  └──────────┘  └──────────┘  └──────────┘            │
│                                                        │
│  Kasutamine: Frontend, API servers, stateless         │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│          StatefulSet (Stateful Apps)                   │
│                                                        │
│  Pod'id on unikaalsed ja stabiilsed:                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐│
│  │ postgres-0   │  │ postgres-1   │  │ postgres-2   ││
│  │ Stable name  │  │ Stable name  │  │ Stable name  ││
│  │ Stable PVC   │  │ Stable PVC   │  │ Stable PVC   ││
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘│
│         │                 │                 │         │
│         ▼                 ▼                 ▼         │
│    ┌────────┐        ┌────────┐        ┌────────┐    │
│    │ PVC-0  │        │ PVC-1  │        │ PVC-2  │    │
│    │ 10Gi   │        │ 10Gi   │        │ 10Gi   │    │
│    └────────┘        └────────┘        └────────┘    │
│                                                        │
│  Kasutamine: Databases, caches, stateful services     │
└────────────────────────────────────────────────────────┘
```

### PV, PVC, Pod Relationship

```
┌─────────────────────────────────────────────────────────┐
│                   Developer                             │
│  "Ma vajan 10Gi storage'it PostgreSQL'ile"             │
└────────────────────┬────────────────────────────────────┘
                     │ Creates
                     ▼
┌─────────────────────────────────────────────────────────┐
│  PersistentVolumeClaim: postgres-pvc                    │
│  Request: 10Gi, ReadWriteOnce                           │
└────────────────────┬────────────────────────────────────┘
                     │ Binds to
                     ▼
┌─────────────────────────────────────────────────────────┐
│  PersistentVolume: postgres-pv                          │
│  Capacity: 10Gi, hostPath: /mnt/data/postgres           │
│  (Created by Admin or StorageClass)                     │
└────────────────────┬────────────────────────────────────┘
                     │ Maps to
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Host Machine Disk                          │
│  /mnt/data/postgres/ (actual files)                     │
└─────────────────────────────────────────────────────────┘
                     ▲
                     │ Pod mounts
                     │
┌─────────────────────────────────────────────────────────┐
│  Pod: postgres-0                                        │
│  volumeMounts:                                          │
│    - mountPath: /var/lib/postgresql/data                │
│      name: postgres-storage                             │
│  volumes:                                               │
│    - name: postgres-storage                             │
│      persistentVolumeClaim:                             │
│        claimName: postgres-pvc                          │
└─────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Mõista PV vs PVC vs StorageClass (5 min)

**PersistentVolume (PV):**
- **Admin loob** (või StorageClass provision'ib automaatselt)
- Actual storage resource (hostPath, NFS, AWS EBS, GCP PD)
- Capacity, access modes, reclaim policy

**PersistentVolumeClaim (PVC):**
- **Developer loob**
- Storage request (size, access mode)
- Kubernetes bind'ib PVC → PV

**StorageClass:**
- **Dynamic provisioning** (cloud)
- Automaatselt loob PV kui PVC luuakse
- Näited: `standard` (Minikube), `local-path` (K3s), `gp2` (AWS)

**Static vs Dynamic Provisioning:**

```
Static (Lab 3 - õpime algul):
1. Admin loob PV manually (hostPath)
2. Developer loob PVC
3. Kubernetes bind'ib PVC → PV

Dynamic (Production):
1. Developer loob PVC (määrab StorageClass)
2. StorageClass provision'ib automaatselt PV
3. Kubernetes bind'ib PVC → PV
```

---

### Samm 2: Loo PersistentVolume (Static Provisioning) (10 min)

**hostPath PV** (development - kasutab host machine disk'i).

**⚠️ HOIATUS:** hostPath on **ainult single-node cluster'ites** (Minikube, K3s)! Production'is kasuta NFS, cloud disks.

Loo fail `postgres-user-pv.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-user-pv
  labels:
    type: local
    app: postgres-user
spec:
  storageClassName: manual  # Static provisioning
  capacity:
    storage: 10Gi  # Total size
  accessModes:
    - ReadWriteOnce  # RWO = 1 node, 1 pod
  hostPath:
    path: /mnt/data/postgres-user  # Host machine path
    type: DirectoryOrCreate  # Create if not exists
  persistentVolumeReclaimPolicy: Retain  # Keep data after PVC deletion
```

**Access Modes:**
- **ReadWriteOnce (RWO):** 1 node can mount (most common for databases)
- **ReadOnlyMany (ROX):** Multiple nodes read-only
- **ReadWriteMany (RWX):** Multiple nodes read-write (needs shared storage like NFS)

**Reclaim Policy:**
- **Retain:** Keep PV and data after PVC deletion (manual cleanup)
- **Delete:** Delete PV and data after PVC deletion
- **Recycle:** Deprecated (basic scrub)

**Deploy:**

```bash
kubectl apply -f postgres-user-pv.yaml

# Kontrolli
kubectl get pv

# Output:
# NAME               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   AGE
# postgres-user-pv   10Gi       RWO            Retain           Available           manual         10s

# STATUS: Available (ei ole veel bound PVC'ga)

kubectl describe pv postgres-user-pv

# Output:
# Name:            postgres-user-pv
# Labels:          app=postgres-user
#                  type=local
# Capacity:        10Gi
# Access Modes:    RWO
# Reclaim Policy:  Retain
# Status:          Available
# Claim:
# StorageClass:    manual
# ...
```

**Loo teine PV todo-service'le:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-todo-pv
  labels:
    type: local
    app: postgres-todo
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data/postgres-todo
    type: DirectoryOrCreate
  persistentVolumeReclaimPolicy: Retain
EOF

kubectl get pv
# NAME               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM
# postgres-user-pv   10Gi       RWO            Retain           Available
# postgres-todo-pv   10Gi       RWO            Retain           Available
```

---

### Samm 3: Loo PersistentVolumeClaim (10 min)

**PVC** = Storage request.

Loo fail `postgres-user-pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-user-pvc
  labels:
    app: postgres-user
spec:
  storageClassName: manual  # Match PV storageClassName
  accessModes:
    - ReadWriteOnce  # Match PV accessModes
  resources:
    requests:
      storage: 10Gi  # Request size (≤ PV capacity)
```

**Deploy:**

```bash
kubectl apply -f postgres-user-pvc.yaml

# Kontrolli
kubectl get pvc

# Output:
# NAME                STATUS   VOLUME             CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# postgres-user-pvc   Bound    postgres-user-pv   10Gi       RWO            manual         5s
#                     ^^^^^    ^^^^^^^^^^^^^^^^
#                     Bound!   Auto-matched PV

kubectl describe pvc postgres-user-pvc

# Output:
# Name:          postgres-user-pvc
# Status:        Bound
# Volume:        postgres-user-pv  ← Auto-bound
# Capacity:      10Gi
# Access Modes:  RWO
# ...

# Kontrolli PV uuesti
kubectl get pv

# Output:
# NAME               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS   AGE
# postgres-user-pv   10Gi       RWO            Retain           Bound    default/postgres-user-pvc   manual         5m
#                                                                ^^^^^    ^^^^^^^^^^^^^^^^^^^^^
#                                                                Bound!   PVC nimi
```

**Binding rules:**
- `storageClassName` must match
- `accessModes` must match
- PVC `requests.storage` ≤ PV `capacity.storage`
- Label selectors (optional)

**Loo todo PVC:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-todo-pvc
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
EOF

kubectl get pvc
# NAME                STATUS   VOLUME             CAPACITY   ACCESS MODES
# postgres-user-pvc   Bound    postgres-user-pv   10Gi       RWO
# postgres-todo-pvc   Bound    postgres-todo-pv   10Gi       RWO
```

---

### Samm 4: Deploy PostgreSQL StatefulSet (15 min)

**StatefulSet** on sarnane Deployment'ile, aga stateful apps'ile.

**Erinevused:**
- **Stable pod names:** `postgres-user-0` (mitte random hash)
- **Stable storage:** Iga pod'il oma PVC
- **Ordered deployment:** Pod'id käivituvad järjekorras (0 → 1 → 2)
- **Ordered termination:** Kustutatakse vastupidises järjekorras

Loo fail `postgres-user-statefulset.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-user
  labels:
    app: postgres-user
spec:
  type: ClusterIP
  clusterIP: None  # Headless service (StatefulSet jaoks)
  selector:
    app: postgres-user
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-user
  labels:
    app: postgres-user
spec:
  serviceName: postgres-user  # Headless service nimi
  replicas: 1  # Tavaliselt 1 (või 3+ cluster'is)
  selector:
    matchLabels:
      app: postgres-user
  template:
    metadata:
      labels:
        app: postgres-user
        tier: database
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
          name: postgres

        # Environment variables (ConfigMap/Secret'idest)
        envFrom:
        - configMapRef:
            name: postgres-user-config
        - secretRef:
            name: db-user-secret

        # Volume mount
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres  # Subfolder (et ei kirjutaks otse root'i)

      # Volumes - kasutab PVC'd
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-user-pvc
```

**Loo PostgreSQL ConfigMap:**

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-user-config
data:
  POSTGRES_DB: user_service_db
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres  # DEV only! Production: kasuta Secret
  PGDATA: /var/lib/postgresql/data/postgres
EOF
```

**Deploy StatefulSet:**

```bash
kubectl apply -f postgres-user-statefulset.yaml

# Kontrolli StatefulSet
kubectl get statefulsets

# Output:
# NAME            READY   AGE
# postgres-user   1/1     30s

# Kontrolli pod'e
kubectl get pods -l app=postgres-user

# Output:
# NAME              READY   STATUS    RESTARTS   AGE
# postgres-user-0   1/1     Running   0          40s
#               ^^^ Stable name (not random hash!)

# Kontrolli Service
kubectl get svc postgres-user

# Output:
# NAME            TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
# postgres-user   ClusterIP   None         <none>        5432/TCP   1m
#                             ^^^^
#                             Headless service (clusterIP: None)
```

**Testi PostgreSQL:**

```bash
# Exec pod'i
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db

# PostgreSQL shell:
user_service_db=# \dt
# No relations found. (tables pole veel - loome Harjutus 6'is Liquibase'iga)

user_service_db=# CREATE TABLE test (id INT);
# CREATE TABLE

user_service_db=# \dt
#         List of relations
#  Schema | Name | Type  |  Owner
# --------+------+-------+----------
#  public | test | table | postgres

user_service_db=# \q

# Exit pod
```

---

### Samm 5: Testi Andmete Persistence (10 min)

**Test: Pod restart ei kustuta andmeid.**

```bash
# Loo test tabel
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "CREATE TABLE persistence_test (id SERIAL PRIMARY KEY, data TEXT);"

kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "INSERT INTO persistence_test (data) VALUES ('Test data 1'), ('Test data 2');"

# Kontrolli
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "SELECT * FROM persistence_test;"

# Output:
#  id |    data
# ----+-------------
#   1 | Test data 1
#   2 | Test data 2

# Kustuta pod (simuleeri crash)
kubectl delete pod postgres-user-0

# StatefulSet loob automaatselt uue pod'i SAMA nimega (postgres-user-0)
kubectl get pods -l app=postgres-user --watch

# Output:
# NAME              READY   STATUS        RESTARTS   AGE
# postgres-user-0   1/1     Terminating   0          5m
# postgres-user-0   0/1     Pending       0          0s
# postgres-user-0   0/1     ContainerCreating   0   1s
# postgres-user-0   1/1     Running       0          10s

# Kontrolli andmeid (peaks olema alles!)
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "SELECT * FROM persistence_test;"

# Output:
#  id |    data
# ----+-------------
#   1 | Test data 1
#   2 | Test data 2

# ✅ Andmed on alles! PVC mount'iti uuele pod'ile
```

**Test: Node restart (Minikube)**

```bash
# Minikube: restart node
minikube stop
minikube start

# Kontrolli pod'e
kubectl get pods -l app=postgres-user

# Andmed on ikka alles
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "SELECT * FROM persistence_test;"
```

---

### Samm 6: Deploy PostgreSQL Todo StatefulSet (5 min)

Sarnaselt user-service'le.

```bash
# PV ja PVC on juba loodud Samm 2-3'is

# ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-todo-config
data:
  POSTGRES_DB: todo_service_db
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
  PGDATA: /var/lib/postgresql/data/postgres
EOF

# StatefulSet + Service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: postgres-todo
spec:
  type: ClusterIP
  clusterIP: None
  selector:
    app: postgres-todo
  ports:
  - port: 5432
    name: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-todo
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
        tier: database
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        envFrom:
        - configMapRef:
            name: postgres-todo-config
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-todo-pvc
EOF

# Kontrolli
kubectl get statefulsets
# NAME            READY   AGE
# postgres-user   1/1     15m
# postgres-todo   1/1     10s

kubectl get pods -l tier=database
# NAME              READY   STATUS    RESTARTS   AGE
# postgres-user-0   1/1     Running   0          15m
# postgres-todo-0   1/1     Running   0          15s
```

---

### Samm 7: Testi rakenduste ühendust (5 min)

Nüüd on DB'd valmis - testi backend'e!

```bash
# Port forward user-service
kubectl port-forward svc/user-service 8080:3000

# Teises terminalis - health check
curl http://localhost:8080/health

# Output peaks nüüd olema:
# {"status":"OK","database":"connected",...}  ← ✅ DB ühendus!

# Register user
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'

# Output:
# {"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...","user":{...}}

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Output:
# {"token":"..."}

# Kontrolli DB'd
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "SELECT id, name, email FROM users;"

# Output:
#  id |   name    |       email
# ----+-----------+-------------------
#   1 | Test User | test@example.com
```

---

### Samm 8: Dynamic Provisioning (StorageClass) (5 min)

**Production best practice:** Kasuta StorageClass (dynamic provisioning).

**Minikube:**

```bash
# Minikube-l on "standard" StorageClass (hostPath provisioner)
kubectl get storageclass

# Output:
# NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE
# standard (default)   k8s.io/minikube-hostpath   Delete          Immediate
```

**PVC with StorageClass (no manual PV!):**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-dynamic-pvc
spec:
  storageClassName: standard  # Use StorageClass
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

**Apply:**

```bash
kubectl apply -f postgres-dynamic-pvc.yaml

# Kontrolli - PV luuakse AUTOMAATSELT!
kubectl get pvc postgres-dynamic-pvc

# Output:
# NAME                   STATUS   VOLUME                                     CAPACITY
# postgres-dynamic-pvc   Bound    pvc-abc123-xxxx-xxxx-xxxx-xxxxxxxxxxxx     5Gi

kubectl get pv

# Output näitab automaatselt loodud PV'd:
# NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
# pvc-abc123-xxxx-xxxx-xxxx-xxxxxxxxxxxx     5Gi        RWO            Delete           Bound    default/postgres-dynamic-pvc
```

**K3s:**

```bash
kubectl get storageclass

# Output:
# NAME                   PROVISIONER             RECLAIMPOLICY
# local-path (default)   rancher.io/local-path   Delete
```

**StatefulSet volumeClaimTemplates (automatic PVC creation):**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-dynamic
spec:
  serviceName: postgres-dynamic
  replicas: 3
  selector:
    matchLabels:
      app: postgres-dynamic
  template:
    metadata:
      labels:
        app: postgres-dynamic
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data

  # volumeClaimTemplates - StatefulSet loob automaatselt PVC iga pod'i jaoks!
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      storageClassName: standard  # või local-path (K3s)
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
```

**Deploy'imisel loob:**
- `postgres-storage-postgres-dynamic-0` PVC (10Gi)
- `postgres-storage-postgres-dynamic-1` PVC (10Gi)
- `postgres-storage-postgres-dynamic-2` PVC (10Gi)

**Iga pod'il oma persistent storage!**

---

### Samm 9: Backup & Restore (5 min)

**Backup volume data:**

```bash
# Method 1: PostgreSQL pg_dump
kubectl exec postgres-user-0 -- pg_dump -U postgres user_service_db > backup.sql

# Method 2: Copy entire data directory
kubectl exec postgres-user-0 -- tar czf /tmp/backup.tar.gz -C /var/lib/postgresql/data .
kubectl cp postgres-user-0:/tmp/backup.tar.gz ./postgres-user-backup.tar.gz

# Method 3: Snapshot (cloud provider)
# AWS: aws ec2 create-snapshot --volume-id <ebs-volume-id>
# GCP: gcloud compute disks snapshot <disk-name>
```

**Restore:**

```bash
# Method 1: psql restore
kubectl exec -i postgres-user-0 -- psql -U postgres user_service_db < backup.sql

# Method 2: Extract backup
kubectl cp ./postgres-user-backup.tar.gz postgres-user-0:/tmp/backup.tar.gz
kubectl exec postgres-user-0 -- tar xzf /tmp/backup.tar.gz -C /var/lib/postgresql/data
```

---

### Samm 10: Cleanup (Optional) (5 min)

**NB:** Ära kustuta - vajame järgmises harjutuses!

```bash
# Kui vaja:
# Kustuta StatefulSet (pod'id kustutatakse)
kubectl delete statefulset postgres-user

# Kustuta PVC
kubectl delete pvc postgres-user-pvc

# Kustuta PV (kui reclaim policy = Retain, PV jääb Available)
kubectl delete pv postgres-user-pv

# Host machine data (kui hostPath)
# Minikube:
minikube ssh
sudo rm -rf /mnt/data/postgres-user
exit

# K3s:
sudo rm -rf /mnt/data/postgres-user
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **PersistentVolumes:**
  - [ ] `postgres-user-pv` (10Gi, hostPath)
  - [ ] `postgres-todo-pv` (10Gi, hostPath)

- [ ] **PersistentVolumeClaims:**
  - [ ] `postgres-user-pvc` (Bound to postgres-user-pv)
  - [ ] `postgres-todo-pvc` (Bound to postgres-todo-pv)

- [ ] **StatefulSets:**
  - [ ] `postgres-user` (1 replica)
  - [ ] `postgres-todo` (1 replica)

- [ ] **Pods:**
  - [ ] `postgres-user-0` (Running, PVC mounted)
  - [ ] `postgres-todo-0` (Running, PVC mounted)

- [ ] **Services:**
  - [ ] `postgres-user` (Headless ClusterIP)
  - [ ] `postgres-todo` (Headless ClusterIP)

- [ ] **Data Persistence:**
  - [ ] Andmed jäävad alles pod restart'imisel
  - [ ] Backend apps saavad ühenduda DB'ga

**Kontrolli:**

```bash
kubectl get pv
kubectl get pvc
kubectl get statefulsets
kubectl get pods -l tier=database
kubectl exec -it postgres-user-0 -- psql -U postgres -d user_service_db -c "\dt"
curl http://localhost:8080/health  # (port-forward svc/user-service 8080:3000)
```

---

## 🐛 Troubleshooting

### Probleem 1: PVC on Pending

**Sümptom:**
```bash
kubectl get pvc
# NAME                STATUS    VOLUME   CAPACITY   ACCESS MODES
# postgres-user-pvc   Pending
```

**Põhjused:**
1. PV ei eksisteeri
2. PV ja PVC ei match'i (storageClassName, accessModes, capacity)
3. PV on juba bound teise PVC'ga

**Diagnoos:**

```bash
kubectl describe pvc postgres-user-pvc

# Events:
# Warning  ProvisioningFailed  1m  persistentvolume-controller  no persistent volumes available for this claim
```

**Lahendus:**

```bash
# Kontrolli PV
kubectl get pv

# Loo PV või paranda match
# - storageClassName PEAB match'ima
# - accessModes PEAB match'ima
# - PV capacity ≥ PVC request
```

---

### Probleem 2: Pod ei mount'i volume'i

**Sümptom:**
```bash
kubectl describe pod postgres-user-0

# Events:
# Warning  FailedMount  1m  kubelet  Unable to attach or mount volumes: ...
```

**Põhjused:**
1. PVC ei eksisteeri
2. PVC on Pending
3. hostPath directory permissions

**Lahendus:**

```bash
# Kontrolli PVC
kubectl get pvc postgres-user-pvc

# Kui Bound, kontrolli host path permissions
# Minikube:
minikube ssh
sudo ls -la /mnt/data/
sudo chmod 777 /mnt/data/postgres-user  # Or proper permissions
exit
```

---

### Probleem 3: StatefulSet pod ei käivitu

**Sümptom:**
```bash
kubectl get pods
# postgres-user-0   0/1   Init:0/1   0   10s
```

**Diagnoos:**

```bash
kubectl describe pod postgres-user-0

# Events:
# Warning  FailedScheduling  1m  default-scheduler  0/1 nodes are available: 1 pod has unbound immediate PersistentVolumeClaims.
```

**Lahendus:** PVC peab olema Bound enne pod'i käivitamist.

---

## 🎓 Õpitud Mõisted

### Storage Concepts
- **Ephemeral storage:** Container file system (kaob restart'imisel)
- **PersistentVolume (PV):** Cluster storage resource
- **PersistentVolumeClaim (PVC):** Storage request
- **StorageClass:** Dynamic provisioner
- **Static provisioning:** Admin loob PV manually
- **Dynamic provisioning:** StorageClass loob PV automaatselt

### Access Modes
- **ReadWriteOnce (RWO):** 1 node, 1 pod (most common for DB)
- **ReadOnlyMany (ROX):** Multiple nodes, read-only
- **ReadWriteMany (RWX):** Multiple nodes, read-write (NFS, cloud shared)

### Reclaim Policies
- **Retain:** Keep PV after PVC deletion (manual cleanup)
- **Delete:** Delete PV and data after PVC deletion
- **Recycle:** Deprecated

### StatefulSet
- **Stable pod names:** `postgres-0`, `postgres-1` (not random)
- **Stable storage:** PVC per pod
- **Ordered deployment/termination**
- **Headless Service:** `clusterIP: None` (DNS per pod)

### kubectl Storage Commands
- `kubectl get pv` - List PersistentVolumes
- `kubectl get pvc` - List PersistentVolumeClaims
- `kubectl describe pv <name>` - PV details
- `kubectl describe pvc <name>` - PVC details
- `kubectl get storageclass` - List StorageClasses
- `kubectl get statefulsets` / `kubectl get sts` - List StatefulSets

---

## 💡 Parimad Tavad

### ✅ DO (Tee):
1. **Kasuta StatefulSet databases'ile** - Stable names, PVC per pod
2. **Dynamic provisioning production'is** - StorageClass (AWS EBS, GCP PD)
3. **Reclaim policy: Retain dev'is** - Ära kaota andmeid kogemata
4. **subPath:** Mount volume subfolder'isse (`/var/lib/postgresql/data/postgres`)
5. **Backup regularly** - pg_dump, snapshots
6. **volumeClaimTemplates StatefulSet'is** - Auto-creates PVC per pod
7. **Headless Service StatefulSet'ile** - DNS per pod

### ❌ DON'T (Ära tee):
1. **Ära kasuta hostPath production'is** - Single-node only
2. **Ära kustuta PVC enne backup'i** - Data loss!
3. **Ära kasuta emptyDir stateful apps'ile** - Ephemeral!
4. **Ära unusta accessModes** - RWO ≠ RWX

---

## 🔗 Järgmine Samm

Meil on nüüd:
- ✅ 2x PostgreSQL StatefulSet (user, todo)
- ✅ Persistent storage
- ✅ Backend'id saavad ühenduda DB'ga

**Probleem:** Database schema puudub (tables, indexes).

**Järgmises harjutuses (Harjutus 6):**
- InitContainers - käivituvad ENNE main container'i
- Liquibase migrations - loob DB schema automaatselt
- Täielik stack deploy (5 teenust)
- End-to-end test

---

**Jätka:** [Harjutus 6: InitContainers & Database Migrations](06-initcontainers-migrations.md)

---

## 📚 Viited

**Kubernetes Dokumentatsioon:**
- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

**Storage Providers:**
- [hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath) (dev only!)
- [NFS](https://kubernetes.io/docs/concepts/storage/volumes/#nfs)
- [AWS EBS CSI](https://github.com/kubernetes-sigs/aws-ebs-csi-driver)
- [GCP Persistent Disk](https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes)

---

**Õnnitleme! Oled deploy'nud stateful rakendused persistent storage'iga! 🎉**

*Järgmises harjutuses õpime InitContainers ja Liquibase migrations - viimane samm täieliku stack'i loomiseks!*
