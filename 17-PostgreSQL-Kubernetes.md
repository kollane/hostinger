# Peatükk 17: PostgreSQL Kubernetes-es - MÕLEMAD VARIANDID ☸️⭐

**Kestus:** 5 tundi
**Eeldused:** Peatükk 16 läbitud, K3s paigaldatud
**Eesmärk:** Deployida PostgreSQL Kubernetes-es kahes variandis

---

## Sisukord

1. [Ülevaade](#1-ülevaade)
2. [Secrets ja Sensitive Data](#2-secrets-ja-sensitive-data)
3. [ConfigMaps](#3-configmaps)
4. [PersistentVolumes ja PersistentVolumeClaims](#4-persistentvolumes-ja-persistentvolumeclaims)
5. [PRIMAARNE: StatefulSet PostgreSQL](#5-primaarne-statefulset-postgresql)
6. [ALTERNATIIV: ExternalName Service](#6-alternatiiv-externalname-service)
7. [Variantide Võrdlus](#7-variantide-võrdlus)
8. [Backup Strateegiad](#8-backup-strateegiad)
9. [Harjutused](#9-harjutused)

---

## 1. Ülevaade

### 1.1. Kaks Lähenemist

**PRIMAARNE: StatefulSet PostgreSQL**
- PostgreSQL töötab Kubernetes-es
- PersistentVolume andmete jaoks
- Ideaalne: mikroteenused, cloud-native

**ALTERNATIIV: Väline PostgreSQL**
- PostgreSQL töötab väljaspool klastrit
- ExternalName Service ühendamiseks
- Ideaalne: suur produktsioon, legacy

---

### 1.2. Arhitektuurid

**Primaarne (StatefulSet):**
```
┌─────────────────────────────┐
│   KUBERNETES CLUSTER        │
│                             │
│  Backend Pods               │
│      ↓                      │
│  PostgreSQL Service         │
│      ↓                      │
│  PostgreSQL StatefulSet     │
│      ↓                      │
│  PersistentVolumeClaim      │
│      ↓                      │
│  PersistentVolume           │
└─────────────────────────────┘
```

**Alternatiiv (Väline):**
```
┌─────────────────────────────┐
│   KUBERNETES CLUSTER        │
│                             │
│  Backend Pods               │
│      ↓                      │
│  ExternalName Service       │
└──────────┬──────────────────┘
           │ (SSL/TLS)
           ▼
┌─────────────────────────────┐
│   EXTERNAL POSTGRESQL       │
│   (VPS või Managed Service) │
└─────────────────────────────┘
```

---

## 2. Secrets ja Sensitive Data

### 2.1. Mis on Secret?

**Secret** salvestab tundlikke andmeid (paroolid, võtmed, sertid) krüpteeritult.

---

### 2.2. Secret Loomine

```bash
# Imperatiivne
kubectl create secret generic postgres-secret \
  --from-literal=username=appuser \
  --from-literal=password=MyStrongPassword123!

# Kontrolli
kubectl get secrets

# Vaata (base64 encoded)
kubectl get secret postgres-secret -o yaml
```

**YAML variant:**

```bash
# Encode väärtused
echo -n 'appuser' | base64
# YXBwdXNlcg==

echo -n 'MyStrongPassword123!' | base64
# TXlTdHJvbmdQYXNzd29yZDEyMyE=
```

```yaml
# postgres-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
data:
  username: YXBwdXNlcg==
  password: TXlTdHJvbmdQYXNzd29yZDEyMyE=
```

Apply:

```bash
kubectl apply -f postgres-secret.yaml
```

---

### 2.3. Secret Kasutamine

```yaml
env:
- name: POSTGRES_USER
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: username

- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: password
```

---

## 3. ConfigMaps

### 3.1. Mis on ConfigMap?

**ConfigMap** salvestab konfiguratsioonifaile ja keskkonnamuutujaid (ei-tundlikud).

---

### 3.2. ConfigMap Loomine

```bash
# Imperatiivne
kubectl create configmap postgres-config \
  --from-literal=database=appdb \
  --from-literal=port="5432"
```

**YAML:**

```yaml
# postgres-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
data:
  database: appdb
  port: "5432"
  max_connections: "200"
```

**Failist:**

```bash
# Loo postgresql.conf
vim postgresql.conf
```

```ini
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
```

```bash
# Loo ConfigMap failist
kubectl create configmap postgres-conf \
  --from-file=postgresql.conf=postgresql.conf
```

---

### 3.3. ConfigMap Kasutamine

**Env variables:**

```yaml
env:
- name: POSTGRES_DB
  valueFrom:
    configMapKeyRef:
      name: postgres-config
      key: database
```

**Volume mount:**

```yaml
volumeMounts:
- name: postgres-conf
  mountPath: /etc/postgresql/postgresql.conf
  subPath: postgresql.conf

volumes:
- name: postgres-conf
  configMap:
    name: postgres-conf
```

---

## 4. PersistentVolumes ja PersistentVolumeClaims

### 4.1. Storage Kontseptsioonid

**PersistentVolume (PV):** Füüsiline storage (disk)

**PersistentVolumeClaim (PVC):** "Taotlus" storage-le

**StorageClass:** Dünaamilise PV loomise template

```
┌──────────────┐
│   Pod        │
│      ↓       │
│   PVC        │  (claim: "Ma tahan 10GB")
└──────┬───────┘
       ↓
┌──────────────┐
│   PV         │  (actual storage)
└──────────────┘
```

---

### 4.2. K3s local-path StorageClass

K3s sisaldab `local-path` StorageClass-i (default):

```bash
# Vaata StorageClasses
kubectl get storageclass

# Väljund:
# NAME                   PROVISIONER             RECLAIMPOLICY
# local-path (default)   rancher.io/local-path   Delete
```

---

### 4.3. PersistentVolumeClaim Loomine

```yaml
# postgres-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
  - ReadWriteOnce  # Üks node saab kirjutada
  storageClassName: local-path
  resources:
    requests:
      storage: 10Gi
```

Apply:

```bash
kubectl apply -f postgres-pvc.yaml

# Kontrolli
kubectl get pvc

# Väljund:
# NAME           STATUS   VOLUME                                     CAPACITY
# postgres-pvc   Bound    pvc-abc123-xyz...                          10Gi

# PV loodi automaatselt
kubectl get pv
```

---

## 5. PRIMAARNE: StatefulSet PostgreSQL

### 5.1. Mis on StatefulSet?

**StatefulSet** on Deployment-laadne, aga stateful rakenduste jaoks:

**Erinevused Deployment-ist:**
- Stabiilsed network ID-d (pod-0, pod-1, ...)
- Stabiilsed storage (PVC per pod)
- Järjestatud deployment ja scaling
- Järjestatud deletion

**Kasutusjuhtumid:** Andmebaasid, message queues, koordinatsiooniteenused

---

### 5.2. PostgreSQL StatefulSet (Täielik)

```bash
vim postgres-statefulset.yaml
```

```yaml
# postgres-statefulset.yaml
---
# Secret
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  username: appuser
  password: MyStrongPassword123!

---
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
data:
  database: appdb
  port: "5432"

---
# Headless Service
apiVersion: v1
kind: Service
metadata:
  name: postgres
  labels:
    app: postgres
spec:
  clusterIP: None  # Headless
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres

---
# StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
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
          name: postgres
        env:
        - name: POSTGRES_DB
          valueFrom:
            configMapKeyRef:
              name: postgres-config
              key: database
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - sh
            - -c
            - pg_isready -U $POSTGRES_USER
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - sh
            - -c
            - pg_isready -U $POSTGRES_USER
          initialDelaySeconds: 5
          periodSeconds: 5

  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: local-path
      resources:
        requests:
          storage: 10Gi
```

---

### 5.3. Deploy StatefulSet

```bash
# Apply
kubectl apply -f postgres-statefulset.yaml

# Vaata pods
kubectl get pods -w  # (-w = watch mode)

# Väljund:
# NAME         READY   STATUS    RESTARTS   AGE
# postgres-0   0/1     Pending   0          0s
# postgres-0   0/1     ContainerCreating   0          2s
# postgres-0   1/1     Running             0          30s

# Vaata StatefulSet
kubectl get statefulset

# Vaata Service
kubectl get service postgres

# Vaata PVC
kubectl get pvc

# Väljund:
# NAME                        STATUS   VOLUME                   CAPACITY
# postgres-storage-postgres-0   Bound    pvc-abc123...            10Gi
```

---

### 5.4. Testimine

```bash
# Ühenda PostgreSQL-iga
kubectl exec -it postgres-0 -- psql -U appuser -d appdb

# psql-is:
appdb=# \l
appdb=# CREATE TABLE test (id SERIAL PRIMARY KEY, name TEXT);
appdb=# INSERT INTO test (name) VALUES ('Hello from Kubernetes!');
appdb=# SELECT * FROM test;
appdb=# \q

# Testi välj aspooltsystemctl restart k3s

# Pod restarditakse, aga andmed säilivad!
kubectl delete pod postgres-0

# Oota kuni pod taastub
kubectl get pods -w

# Ühenda uuesti
kubectl exec -it postgres-0 -- psql -U appuser -d appdb -c "SELECT * FROM test;"

# Väljund:
#  id |          name
# ----+------------------------
#   1 | Hello from Kubernetes!
```

✅ **Andmed säilivad!**

---

## 6. ALTERNATIIV: ExternalName Service

### 6.1. Stsenaarium

PostgreSQL töötab **väliselt** (nt dedikeeritud VPS, AWS RDS, jne).

---

### 6.2. Variant 1: ExternalName Service

**Eeldus:** Väline PostgreSQL on DNS-iga kättesaadav (nt `db.example.com`)

```yaml
# external-postgres.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  type: ExternalName
  externalName: db.example.com  # Väline hostname
  ports:
  - port: 5432
```

Apply:

```bash
kubectl apply -f external-postgres.yaml
```

**Kuidas see töötab:**

```
Pod → Service "postgres" → DNS → db.example.com:5432
```

**Backend kood:**

```javascript
// Sama nagu StatefulSet variant!
const pool = new Pool({
  host: 'postgres',  // Service name
  port: 5432,
  // ...
});
```

---

### 6.3. Variant 2: Endpoints (IP-based)

Kui väline DB on IP aadressiga (nt `192.168.1.100`):

```yaml
# external-postgres-ip.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  ports:
  - port: 5432
    targetPort: 5432

---
apiVersion: v1
kind: Endpoints
metadata:
  name: postgres  # Peab matchima Service name-iga
subsets:
- addresses:
  - ip: 192.168.1.100  # Väline PostgreSQL IP
  ports:
  - port: 5432
```

---

### 6.4. SSL/TLS Ühendus Välise DB-ga

**Secret SSL sertifikaadile:**

```bash
# Kopeeri CA sertifikaat
kubectl create secret generic db-ssl-secret \
  --from-file=ca.crt=/path/to/ca-certificate.crt
```

**Backend env:**

```yaml
env:
- name: DB_HOST
  value: postgres  # ExternalName Service
- name: DB_SSL
  value: "true"
- name: DB_SSL_CA
  valueFrom:
    secretKeyRef:
      name: db-ssl-secret
      key: ca.crt

volumeMounts:
- name: db-ssl
  mountPath: /app/ssl
  readOnly: true

volumes:
- name: db-ssl
  secret:
    secretName: db-ssl-secret
```

**Backend kood:**

```javascript
const fs = require('fs');
const pool = new Pool({
  host: process.env.DB_HOST,
  ssl: process.env.DB_SSL === 'true' ? {
    rejectUnauthorized: true,
    ca: fs.readFileSync('/app/ssl/ca.crt').toString()
  } : false
});
```

---

## 7. Variantide Võrdlus

| Aspekt | StatefulSet | Väline PostgreSQL |
|--------|-------------|-------------------|
| **Haldamine** | Kubernetes native | Väline (manual/managed) |
| **Scalability** | Keeruline (StatefulSet scaling) | Sõltub välisest |
| **HA** | K8s restart, manual replication | Väline HA (Patroni, RDS) |
| **Backup** | CronJob, volume snapshots | Väline backup |
| **Monitoring** | K8s metrics, Prometheus | Väline monitoring |
| **Network Latency** | Väga madal (sama cluster) | Võib olla kõrgem |
| **Ressursid** | Klastri ressursid | Dedicated server |
| **Cost** | Klastri osa | Eraldi server/managed service |
| **Kasutusjuht** | Mikroteenused, dev/test | Suur produktsioon, legacy |

---

## 8. Backup Strateegiad

### 8.1. StatefulSet Backup (CronJob)

```yaml
# postgres-backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # Iga päev kell 2:00 AM
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
            - |
              BACKUP_FILE="/backup/backup-$(date +\%Y\%m\%d-\%H\%M\%S).sql"
              pg_dump -h postgres -U $POSTGRES_USER -d $POSTGRES_DB > $BACKUP_FILE
              echo "Backup saved: $BACKUP_FILE"
            env:
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: username
            - name: POSTGRES_DB
              valueFrom:
                configMapKeyRef:
                  name: postgres-config
                  key: database
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: postgres-backup-pvc

---
# Backup PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-backup-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 20Gi
```

---

### 8.2. Restore

```bash
# Kopeeri backup pod-ist
kubectl cp postgres-0:/backup/backup-20251115.sql ./backup.sql

# Või restore otse
kubectl exec -it postgres-0 -- psql -U appuser -d postgres < backup.sql
```

---

## 9. Harjutused

### Harjutus 17.1: StatefulSet PostgreSQL

1. Loo Secret, ConfigMap, Service, StatefulSet (kasuta näidet 5.2)
2. Apply: `kubectl apply -f postgres-statefulset.yaml`
3. Kontrolli pods: `kubectl get pods`
4. Ühenda: `kubectl exec -it postgres-0 -- psql -U appuser -d appdb`
5. Loo test tabel ja andmed

---

### Harjutus 17.2: Data Persistence Test

1. Loo andmed PostgreSQL-is
2. Kustuta pod: `kubectl delete pod postgres-0`
3. Oota, kuni pod taastub
4. Kontrolli, kas andmed on alles

---

### Harjutus 17.3: ExternalName Service

1. Paigalda PostgreSQL otse VPS-ile (Peatükk 3)
2. Loo ExternalName Service (kasuta kirjakast hostname)
3. Test: Ühenda pod-ist PostgreSQL-iga

---

### Harjutus 17.4: Backup CronJob

1. Loo backup PVC ja CronJob
2. Apply: `kubectl apply -f postgres-backup-cronjob.yaml`
3. Trigger manually: `kubectl create job --from=cronjob/postgres-backup manual-backup`
4. Kontrolli backup-i: `kubectl logs job/manual-backup`

---

## Kokkuvõte

Selles peatükis said:

✅ **Õppisid StatefulSet kontseptsiooni**
✅ **Deployisid PostgreSQL Kubernetes-es (StatefulSet)**
✅ **Kasutasid Secrets ja ConfigMaps**
✅ **Töötasid PersistentVolumes-iga**
✅ **Seadistasid ExternalName Service välisele DB-le**
✅ **Lõid backup strateegia CronJob-iga**

---

## Järgmine Peatükk

**Peatükk 18: Backend Deployment Kubernetes-es**

Järgmises peatükis:
- Backend Deployment
- ConfigMaps ja Secrets backend jaoks
- Service backend-ile
- Health checks (liveness, readiness)
- HorizontalPodAutoscaler

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
**VPS:** kirjakast (Ubuntu 24.04 LTS)
