# Harjutus 1: Velero Setup & Installation

**Kestus:** 60 minutit
**Eesmärk:** Paigalda ja konfigureeri Velero Kubernetes backup tool koos MinIO storage'ga.

---

## 📋 Ülevaade

Selles harjutuses installime **Velero** - VMware Tanzu (endine Heptio Ark) open-source backup tool Kubernetes'le. Velero võimaldab:

- ✅ Backup Kubernetes resources (Deployments, Services, ConfigMaps, etc.)
- ✅ Backup PersistentVolumes (volume snapshots või Restic file-level)
- ✅ Scheduled backups (automated, retention policies)
- ✅ Disaster recovery (full cluster restore)
- ✅ Migration (move apps between clusters)

**Miks Velero?**
- Industry standard (CNCF project)
- Cloud-agnostic (works with any S3-compatible storage)
- Kubernetes-native (CRDs for Backup, Restore, Schedule)
- Plugin architecture (CSI snapshots, cloud providers)
- Open-source ja aktiivselt maintained

**Storage Backend:** MinIO (self-hosted S3-compatible object storage)
- Runs in-cluster (no external dependencies)
- S3 API compatible
- Perfect for learning and testing

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

✅ Installida Velero CLI
✅ Deploy'da MinIO in-cluster (S3-compatible storage)
✅ Installida Velero server Helm'iga
✅ Konfigureerida BackupStorageLocation
✅ Luua esimest test backup
✅ Teostada test restore
✅ Verificeerida Velero metrics (Lab 6 integration)
✅ Debuggida Velero issues

---

## 🏗️ Setup Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                  Velero + MinIO Setup                          │
│                                                                │
│  Kubernetes Cluster                                            │
│  ┌──────────────────────────────────────────────────────┐     │
│  │                                                       │     │
│  │  Namespace: velero                                    │     │
│  │  ┌─────────────────────┐    ┌──────────────────┐     │     │
│  │  │  Velero Server      │    │  Restic DaemonSet│     │     │
│  │  │  (Deployment)       │    │  (node-level     │     │     │
│  │  │                     │    │   PV backup)     │     │     │
│  │  │  - Backup CRD       │    └──────────────────┘     │     │
│  │  │  - Restore CRD      │                             │     │
│  │  │  - Schedule CRD     │                             │     │
│  │  └──────────┬──────────┘                             │     │
│  │             │                                         │     │
│  │             │ S3 API (upload backups)                 │     │
│  │             ▼                                         │     │
│  │  ┌──────────────────────────────────────────┐        │     │
│  │  │  MinIO (in-cluster S3)                   │        │     │
│  │  │  - Deployment                            │        │     │
│  │  │  - PVC (10GB)                            │        │     │
│  │  │  - Service (S3 API on port 9000)         │        │     │
│  │  │                                          │        │     │
│  │  │  Bucket: velero-backups                  │        │     │
│  │  │  ├── production-backup-20250122/         │        │     │
│  │  │  ├── staging-backup-20250122/            │        │     │
│  │  │  └── ...                                 │        │     │
│  │  └──────────────────────────────────────────┘        │     │
│  │                                                       │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
│  Velero CLI (local)                                            │
│  └── velero backup create ...                                 │
│  └── velero restore create ...                                │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Kontrolli Eeldusi

Velero nõuab töötavat Kubernetes cluster'it.

```bash
# Check cluster
kubectl cluster-info

# Check namespaces from previous labs
kubectl get namespaces

# Should see: development, staging, production, monitoring, argocd
```

**Expected:**
- Kubernetes cluster reachable
- Lab 5, 6, 7, 8 namespaces exist

---

### Samm 2: Install Velero CLI

**Linux (Ubuntu):**

```bash
# Download latest Velero CLI
VELERO_VERSION="v1.13.0"
wget https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz

# Extract
tar -xvf velero-${VELERO_VERSION}-linux-amd64.tar.gz

# Move to PATH
sudo mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero

# Verify
velero version --client-only
```

**Expected output:**
```
Client:
  Version: v1.13.0
  Git commit: 12345abc
```

**macOS:**

```bash
brew install velero
```

**Windows (WSL or Git Bash):**

```bash
# Download from GitHub releases
# Extract and add to PATH
```

---

### Samm 3: Create Velero Namespace

```bash
# Create namespace
kubectl create namespace velero

# Label for monitoring (Lab 6 integration)
kubectl label namespace velero monitoring=prometheus

# Verify
kubectl get namespace velero --show-labels
```

---

### Samm 4: Deploy MinIO (In-Cluster S3)

MinIO pakub S3-compatible object storage in-cluster.

**Create MinIO deployment:**

```bash
cat > minio-deployment.yaml << 'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: minio

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minio-pvc
  namespace: minio
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: minio
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
        - name: minio
          image: minio/minio:RELEASE.2024-01-01T16-36-33Z
          
          args:
            - server
            - /data
            - --console-address
            - :9001
          
          env:
            - name: MINIO_ROOT_USER
              value: "minio"
            - name: MINIO_ROOT_PASSWORD
              value: "minio123"
          
          ports:
            - containerPort: 9000
              name: s3
            - containerPort: 9001
              name: console
          
          volumeMounts:
            - name: data
              mountPath: /data
          
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
      
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: minio-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: minio
spec:
  type: ClusterIP
  ports:
    - port: 9000
      targetPort: 9000
      protocol: TCP
      name: s3
    - port: 9001
      targetPort: 9001
      protocol: TCP
      name: console
  selector:
    app: minio
YAML

# Apply
kubectl apply -f minio-deployment.yaml

# Wait for MinIO pod
kubectl wait --for=condition=Ready pod -l app=minio -n minio --timeout=5m
```

**Verify MinIO:**

```bash
# Check pod
kubectl get pods -n minio

# Port-forward to access MinIO console (optional)
kubectl port-forward -n minio svc/minio 9001:9001 &

# Open: http://localhost:9001
# Username: minio
# Password: minio123
```

---

### Samm 5: Create MinIO Bucket for Velero

```bash
# Exec into MinIO pod
kubectl exec -n minio deployment/minio -- sh -c '
  mc alias set local http://localhost:9000 minio minio123
  mc mb local/velero-backups
  mc ls local
'

# Expected: velero-backups bucket created
```

---

### Samm 6: Create Credentials Secret for Velero

Velero vajab MinIO credentials S3 API access'iks.

```bash
# Create credentials file
cat > credentials-velero << 'EOF'
[default]
aws_access_key_id = minio
aws_secret_access_key = minio123
