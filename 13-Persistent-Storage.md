# Peatükk 13: Persistent Storage

**Kestus:** 4 tundi
**Eeldused:** Peatükk 9-12 (Kubernetes alused, Pods, Deployments, Services, ConfigMaps)
**Eesmärk:** Hallata persistent storage stateful rakenduste jaoks

---

## Õpieesmärgid

Selle peatüki lõpuks oskad:
- Mõista PersistentVolume (PV) ja PersistentVolumeClaim (PVC) abstraktsioone
- Konfigureerida StorageClass dynamic provisioning'uks
- Deploy'ida StatefulSets stateful rakenduste jaoks
- Hallata volume lifecycle (create, mount, retain, delete)
- Mõista volume access modes ja reclaim policies

---

## 13.1 Miks Persistent Storage?

### Pod Ephemeral Storage Probleem

**Probleem:**

```
Deployment: postgres (1 replica)

Pod starts:
→ Container writes data to /var/lib/postgresql/data
→ Data stored in container writable layer

Pod deleted (restart, update, node failure):
→ Container filesystem DELETED
→ ALL DATA LOST!

New Pod:
→ Fresh container → EMPTY database!
```

**Container storage layers:**

```
Read-only image layers (immutable):
  - postgres:16-alpine base
  - PostgreSQL binaries

Writable container layer (ephemeral):
  - /var/lib/postgresql/data
  - Deleted when container deleted!
```

**Järeldus:**
> Pod filesystem is EPHEMERAL. Stateful applications MUST use persistent volumes.

---

### Volume Types Overview

**emptyDir (ephemeral):**
```yaml
volumes:
- name: cache
  emptyDir: {}
```
- Created when Pod starts
- Shared between containers in Pod
- **DELETED when Pod deleted**
- Use case: Temporary scratch space, cache

---

**hostPath (dangerous):**
```yaml
volumes:
- name: data
  hostPath:
    path: /mnt/data  # Path on Node
```
- Mounts Node filesystem into Pod
- **Tied to specific Node**
- **Security risk** (Pod can access Node filesystem)
- Use case: Single-node dev/test only

---

**PersistentVolume (production):**
```yaml
volumes:
- name: data
  persistentVolumeClaim:
    claimName: postgres-pvc
```
- **Survives Pod deletion**
- Decoupled from Pod lifecycle
- Portable across Nodes
- Use case: Databases, file storage, stateful apps

---

## 13.2 PersistentVolume (PV) ja PersistentVolumeClaim (PVC)

### Architecture

**Separation of concerns:**

```
Cluster Administrator:
→ Creates PersistentVolume (PV)
→ Physical storage (NFS, iSCSI, cloud disks)

Developer:
→ Creates PersistentVolumeClaim (PVC)
→ Requests storage (size, access mode)

Kubernetes:
→ Binds PVC to matching PV
→ Mounts PV into Pod
```

**Analogy:**

```
PersistentVolume = Hard drive (physical storage)
PersistentVolumeClaim = Purchase order ("I need 10GB storage")
Binding = Kubernetes finds matching drive and assigns it
```

---

### PersistentVolume (PV) - Storage Resource

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce  # Single Node read-write
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data/postgres  # For dev/test (use NFS/cloud in prod)
```

**Key fields:**

**capacity.storage:**
- Size of storage (10Gi, 100Gi, 1Ti)

**accessModes:**
- `ReadWriteOnce` (RWO): One Node, read-write
- `ReadOnlyMany` (ROX): Many Nodes, read-only
- `ReadWriteMany` (RWX): Many Nodes, read-write

**persistentVolumeReclaimPolicy:**
- `Retain`: Keep PV after PVC deleted (manual cleanup)
- `Delete`: Delete PV after PVC deleted
- `Recycle`: Deprecated (use dynamic provisioning)

**storageClassName:**
- Grouping PVs (fast-ssd, slow-hdd, cloud-disk)
- PVC requests specific class

---

### PersistentVolumeClaim (PVC) - Storage Request

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: manual
```

**Kubernetes binding:**

```
1. PVC created: requests 10Gi, RWO, class=manual
2. Kubernetes searches for matching PV:
   - Capacity >= 10Gi ✅
   - AccessModes include RWO ✅
   - StorageClass = manual ✅
3. Bind PVC → PV
4. PVC status: Bound
```

**View binding:**

```bash
kubectl get pvc

NAME            STATUS   VOLUME        CAPACITY   ACCESS MODES
postgres-pvc    Bound    postgres-pv   10Gi       RWO
```

**Status:**
- `Pending`: No matching PV found
- `Bound`: PVC bound to PV
- `Lost`: PV deleted, but PVC still exists

---

### Using PVC in Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres
spec:
  containers:
  - name: postgres
    image: postgres:16-alpine
    volumeMounts:
    - name: postgres-storage
      mountPath: /var/lib/postgresql/data

  volumes:
  - name: postgres-storage
    persistentVolumeClaim:
      claimName: postgres-pvc  # Reference PVC
```

**Workflow:**

```
1. Pod starts
2. Kubernetes finds PVC: postgres-pvc
3. PVC is bound to PV: postgres-pv
4. Kubernetes mounts PV into container:
   /mnt/data/postgres (Node) → /var/lib/postgresql/data (container)
5. PostgreSQL writes data → persists on Node disk
6. Pod deleted → data survives!
7. New Pod mounts same PVC → data intact
```

📖 **Praktika:** Labor 3, Harjutus 10 - PersistentVolumes for PostgreSQL

---

## 13.3 StorageClass - Dynamic Provisioning

### Static vs Dynamic Provisioning

**Static (manual):**

```
1. Admin creates PV manually (10Gi disk)
2. Developer creates PVC (requests 10Gi)
3. Kubernetes binds PVC → PV

Problem:
- Admin must pre-create PVs
- Waste (created 10Gi, only 5Gi used)
- Slow (wait for admin)
```

**Dynamic (automatic):**

```
1. Developer creates PVC (requests 10Gi)
2. Kubernetes StorageClass provisioner:
   → Calls cloud API (AWS EBS, GCP PD, Azure Disk)
   → Creates 10Gi disk automatically
   → Creates PV pointing to disk
   → Binds PVC → PV

Benefit:
- No admin involvement
- On-demand provisioning
- Exact size (no waste)
```

---

### StorageClass Definition

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs  # Cloud provisioner
parameters:
  type: gp3  # AWS EBS type (gp3 = SSD)
  iopsPerGB: "10"
  encrypted: "true"
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

**Key fields:**

**provisioner:**
- `kubernetes.io/aws-ebs` - AWS EBS
- `kubernetes.io/gce-pd` - GCP Persistent Disk
- `kubernetes.io/azure-disk` - Azure Disk
- `k8s.io/minikube-hostpath` - Minikube local
- `rancher.io/local-path` - K3s local

**parameters:**
- Provisioner-specific (disk type, IOPS, encryption)

**reclaimPolicy:**
- `Delete`: Delete cloud disk when PVC deleted
- `Retain`: Keep disk (manual cleanup)

**allowVolumeExpansion:**
- `true`: Can expand PVC size (10Gi → 20Gi)
- `false`: Size fixed

**volumeBindingMode:**
- `Immediate`: Create PV immediately when PVC created
- `WaitForFirstConsumer`: Create PV when Pod first uses PVC (better Node placement)

---

### Using StorageClass

**PVC with dynamic provisioning:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: fast-ssd  # Use StorageClass
```

**What happens:**

```
1. PVC created: 20Gi, class=fast-ssd
2. StorageClass provisioner (AWS EBS):
   → aws ec2 create-volume --size 20 --type gp3
   → Volume created: vol-abc123
3. Kubernetes creates PV:
   - awsElasticBlockStore.volumeID: vol-abc123
   - capacity: 20Gi
4. Bind PVC → PV
5. Pod mounts PVC → volume attached to Node → mounted into container
```

**Cloud costs:**
- AWS EBS gp3: ~$0.08/GB/month
- 20Gi PVC = 20GB disk = ~$1.60/month

---

### Default StorageClass

```bash
# Mark StorageClass as default
kubectl patch storageclass fast-ssd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# PVC without storageClassName → uses default
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # No storageClassName → uses default!
```

---

## 13.4 Access Modes - Volume Sharing

### ReadWriteOnce (RWO)

**Single Node, read-write:**

```
Node A:
  - Pod 1 (read-write) ✅
  - Pod 2 (read-write) ✅ (same Node!)

Node B:
  - Pod 3 (read-write) ❌ BLOCKED (different Node!)
```

**Use case:**
- Databases (PostgreSQL, MySQL) - single writer
- Block storage (AWS EBS, GCP PD, Azure Disk)

**Limitation:**
- Pods on different Nodes cannot share volume
- Deployment with replicas=3 across 3 Nodes → FAILS

---

### ReadOnlyMany (ROX)

**Multiple Nodes, read-only:**

```
Node A, B, C:
  - Pods can read ✅
  - Pods CANNOT write ❌
```

**Use case:**
- Static assets (images, CSS, JS)
- Configuration files
- Shared read-only data

---

### ReadWriteMany (RWX)

**Multiple Nodes, read-write:**

```
Node A:
  - Pod 1 (read-write) ✅

Node B:
  - Pod 2 (read-write) ✅

Node C:
  - Pod 3 (read-write) ✅

All Pods read/write same volume simultaneously
```

**Use case:**
- Shared file storage (user uploads, logs)
- Multi-replica apps sharing data

**Storage backends:**
- NFS ✅
- CephFS ✅
- AWS EFS ✅
- GCP Filestore ✅
- Azure Files ✅
- AWS EBS ❌ (RWO only)
- GCP PD ❌ (RWO only)

**Trade-off:**
- RWX: More complex, expensive (NFS/EFS), slower
- RWO: Simple, cheap (block storage), faster

**DevOps recommendation:**
- Use RWO when possible (stateful apps)
- Use RWX only if multiple Pods MUST write

---

## 13.5 StatefulSets - Stateful Applications

### Deployment vs StatefulSet

**Deployment (stateless):**

```
Replicas: 3

Pods created:
- backend-abc123 (random name)
- backend-def456
- backend-ghi789

Pod deleted:
→ New Pod: backend-jkl012 (DIFFERENT name)
→ Random Pod from replica set

PVC:
→ All Pods share SAME PVC (if RWX)
→ OR each Pod gets random PVC
```

**StatefulSet (stateful):**

```
Replicas: 3

Pods created:
- postgres-0 (ordinal index)
- postgres-1
- postgres-2

Pod postgres-1 deleted:
→ New Pod: postgres-1 (SAME name!)
→ SAME ordinal index

PVC:
→ Each Pod gets OWN dedicated PVC
→ postgres-0 → postgres-pvc-0
→ postgres-1 → postgres-pvc-1
```

**Key differences:**

| Aspect | Deployment | StatefulSet |
|--------|------------|-------------|
| Pod names | Random (abc123) | Stable (postgres-0) |
| Pod identity | Interchangeable | Unique, stable |
| PVC binding | Shared or random | Dedicated per Pod |
| Startup order | Parallel | Sequential (0 → 1 → 2) |
| Network identity | Random IP | Stable hostname |

---

### StatefulSet Manifest

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless  # Required!
  replicas: 3
  selector:
    matchLabels:
      app: postgres

  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data

  volumeClaimTemplates:  # PVC template
  - metadata:
      name: postgres-storage
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 10Gi
      storageClassName: fast-ssd
```

**volumeClaimTemplates:**

```
StatefulSet creates PVCs automatically:

postgres-0 → postgres-storage-postgres-0 (10Gi)
postgres-1 → postgres-storage-postgres-1 (10Gi)
postgres-2 → postgres-storage-postgres-2 (10Gi)

Each Pod gets DEDICATED PVC (NOT shared!)
```

---

### StatefulSet Lifecycle

**Create:**

```bash
kubectl apply -f statefulset.yaml

1. Create postgres-0:
   - Create PVC: postgres-storage-postgres-0
   - Wait for PV binding
   - Start Pod postgres-0
   - Wait for readiness probe

2. Create postgres-1:
   - (same steps)

3. Create postgres-2:
   - (same steps)

Sequential startup: 0 → 1 → 2
```

**Scale up:**

```bash
kubectl scale statefulset postgres --replicas=5

4. Create postgres-3 (after postgres-2 ready)
5. Create postgres-4 (after postgres-3 ready)
```

**Scale down:**

```bash
kubectl scale statefulset postgres --replicas=2

Delete postgres-4 (highest index first)
Delete postgres-3
Keep postgres-0, postgres-1

PVCs NOT deleted! (persist for later scale-up)
```

**Delete StatefulSet:**

```bash
kubectl delete statefulset postgres

Pods deleted: postgres-2 → postgres-1 → postgres-0 (reverse order)
PVCs SURVIVE! (manual deletion required)
```

---

### Headless Service for StatefulSet

**Required for stable network identity:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
spec:
  clusterIP: None  # Headless!
  selector:
    app: postgres
  ports:
  - port: 5432
```

**DNS records:**

```
postgres-0.postgres-headless.default.svc.cluster.local → 10.244.1.10
postgres-1.postgres-headless.default.svc.cluster.local → 10.244.1.11
postgres-2.postgres-headless.default.svc.cluster.local → 10.244.1.12
```

**Use case:**

```
PostgreSQL cluster:
- postgres-0: PRIMARY (read-write)
- postgres-1: REPLICA (read-only)
- postgres-2: REPLICA (read-only)

Application:
- Write queries → postgres-0.postgres-headless:5432
- Read queries → postgres-1.postgres-headless:5432 OR postgres-2.postgres-headless:5432
```

📖 **Praktika:** Labor 3, Harjutus 11 - StatefulSet PostgreSQL cluster

---

## 13.6 Volume Lifecycle Management

### Reclaim Policies

**Retain (manual cleanup):**

```yaml
persistentVolumeReclaimPolicy: Retain
```

```
1. PVC deleted
2. PV status: Released (not Bound, not Available)
3. PV data persists on disk
4. Admin manually:
   - Backup data if needed
   - Clean up PV: kubectl delete pv postgres-pv
   - Delete cloud disk (if cloud storage)
```

**Use case:** Production (safety - no accidental data loss)

---

**Delete (automatic cleanup):**

```yaml
persistentVolumeReclaimPolicy: Delete
```

```
1. PVC deleted
2. Kubernetes deletes PV
3. StorageClass provisioner deletes cloud disk

WARNING: DATA PERMANENTLY DELETED!
```

**Use case:** Dev/test (automatic cleanup)

---

### Volume Expansion

**Expand PVC size:**

```yaml
# Original PVC
spec:
  resources:
    requests:
      storage: 10Gi

# Update to 20Gi
spec:
  resources:
    requests:
      storage: 20Gi
```

```bash
kubectl apply -f pvc.yaml

# For cloud disks (AWS EBS, GCP PD):
1. Kubernetes calls cloud API: resize disk 10Gi → 20Gi
2. Cloud resizes disk
3. Pod restart (may be required for filesystem resize)

# Check expansion status
kubectl describe pvc postgres-pvc
# Conditions:
#   FileSystemResizePending: True
#   Resizing: True
```

**Limitations:**
- Cannot SHRINK (20Gi → 10Gi not allowed)
- StorageClass must have `allowVolumeExpansion: true`
- Some storage backends require Pod restart

---

### Backup and Restore

**Volume snapshot (cloud storage):**

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: postgres-snapshot
spec:
  volumeSnapshotClassName: csi-snapclass
  source:
    persistentVolumeClaimName: postgres-pvc
```

**What happens:**

```
1. VolumeSnapshot created
2. Cloud snapshot created (AWS EBS snapshot, GCP PD snapshot)
3. Snapshot stored in cloud (incremental, fast)
```

**Restore from snapshot:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc-restored
spec:
  dataSource:
    name: postgres-snapshot  # Restore from snapshot
    kind: VolumeSnapshot
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Use case:**
- Disaster recovery
- Clone production to staging
- Testing restore procedures

📖 **Praktika:** Labor 4, Harjutus 5 - Volume snapshots and restore

---

## 13.7 Best Practices

### 1. Use Dynamic Provisioning

```yaml
# ✅ GOOD (dynamic)
storageClassName: fast-ssd

# ❌ BAD (static - manual PV creation)
storageClassName: manual
```

---

### 2. Set Resource Requests

```yaml
resources:
  requests:
    storage: 20Gi  # Exact size needed
```

**Avoid:**
- Over-provisioning (request 100Gi, use 10Gi → waste)
- Under-provisioning (request 10Gi, need 20Gi → out of space)

---

### 3. Enable Volume Expansion

```yaml
# StorageClass
allowVolumeExpansion: true
```

**Benefit:** Can grow volume without recreating PVC

---

### 4. Use Retain Policy (Production)

```yaml
persistentVolumeReclaimPolicy: Retain
```

**Safety:** Accidental PVC deletion doesn't delete data

---

### 5. Regular Backups

```bash
# Automated backups (CronJob)
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # Daily 02:00
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:16-alpine
            command:
            - /bin/sh
            - -c
            - pg_dump -h postgres-0.postgres-headless -U postgres > /backup/dump-$(date +%Y%m%d).sql
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
```

---

### 6. Monitor Disk Usage

```bash
# Check PVC usage
kubectl exec postgres-0 -- df -h /var/lib/postgresql/data

# Prometheus metric: kubelet_volume_stats_used_bytes
```

**Alert when:**
- Disk usage > 80%
- Expand volume or clean up old data

---

## Kokkuvõte

### Mida sa õppisid?

**Persistent storage need:**
- Pod filesystem is EPHEMERAL
- Stateful apps need persistent volumes

**PersistentVolume (PV) + PersistentVolumeClaim (PVC):**
- PV: Physical storage resource
- PVC: Storage request
- Kubernetes binds PVC → matching PV

**StorageClass:**
- Dynamic provisioning (automatic PV creation)
- Cloud integration (AWS EBS, GCP PD, Azure Disk)
- On-demand, exact size

**Access modes:**
- RWO: Single Node (databases)
- ROX: Multi-Node read-only
- RWX: Multi-Node read-write (NFS, EFS)

**StatefulSets:**
- Stable Pod names (postgres-0, postgres-1)
- Dedicated PVCs per Pod
- Sequential startup/shutdown
- Headless Service for stable DNS

**Lifecycle:**
- Retain policy: Manual cleanup (production)
- Delete policy: Automatic cleanup (dev/test)
- Volume expansion: Grow PVC size
- Snapshots: Backup and restore

---

### DevOps Administraatori Vaatenurk

**Iga päev:**
```bash
kubectl get pv                  # List PersistentVolumes
kubectl get pvc                 # List PersistentVolumeClaims
kubectl get storageclass        # List StorageClasses

kubectl describe pvc postgres-pvc  # Check binding status
```

**Troubleshooting:**
```bash
# PVC stuck in Pending:
kubectl describe pvc postgres-pvc
# Check: No matching PV or insufficient capacity

# Check disk usage:
kubectl exec postgres-0 -- df -h /var/lib/postgresql/data

# Expand volume:
kubectl edit pvc postgres-pvc  # Increase storage size
```

**Cleanup:**
```bash
# Delete PVC (data retained with Retain policy)
kubectl delete pvc postgres-pvc

# Manual PV cleanup
kubectl delete pv postgres-pv

# Cloud disk cleanup (if needed)
aws ec2 delete-volume --volume-id vol-abc123
```

---

### Järgmised Sammud

**Peatükk 14:** Ingress ja Load Balancing (external access, HTTPS)
**Peatükk 15:** GitHub Actions Basics (CI/CD automation)

---

**Kestus kokku:** ~4 tundi teooriat + praktilised harjutused labides

📖 **Praktika:**
- Labor 3, Harjutus 10 - PersistentVolumes for PostgreSQL
- Labor 3, Harjutus 11 - StatefulSet PostgreSQL cluster
- Labor 4, Harjutus 5 - Volume snapshots and backup
