# Harjutus 2: Application Backups

**Kestus:** 60 minutit
**Eesmärk:** Backup production applications (user-service + PostgreSQL) koos PersistentVolume data'ga.

---

## 📋 Ülevaade

Selles harjutuses backup'ime **production application** koos andmebaasiga. See on real-world scenario, kus vaja:

- ✅ Backup application code (Deployments, Services, ConfigMaps)
- ✅ Backup database schema (PostgreSQL StatefulSet)
- ✅ Backup database DATA (PersistentVolumes)
- ✅ Verify backup consistency
- ✅ Restore to different namespace (testing)

**Challenge:**
- StatefulSets need special handling (ordered startup)
- PersistentVolumes contain critical data
- Database backups need consistency (no partial writes)

**Solution:**
- Velero hooks (pre-backup: flush DB, post-backup: resume)
- Restic file-level PV backups
- Full namespace backup (all resources together)

**Integratsioon:**
- **Lab 5:** user-service application
- **Lab 3-4:** PostgreSQL StatefulSet
- **Lab 7:** Sealed Secrets (need backup too)
- **Lab 8:** ArgoCD Applications (optional backup)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

✅ Backup'ida production application koos DB'ga
✅ Backup'ida PersistentVolumes Restic'uga
✅ Inspect'ida backup contents
✅ Restore'ida application eraldi namespace'sse
✅ Verify'da restored application töötab
✅ Handle'da StatefulSet backups correctly
✅ Test'ida backup consistency

---

## 🏗️ Backup Scope

```
┌────────────────────────────────────────────────────────────────┐
│         Production Namespace - Backup Scope                    │
│                                                                │
│  Namespace: production                                         │
│  ┌──────────────────────────────────────────────────────┐     │
│  │                                                       │     │
│  │  Application Layer                                    │     │
│  │  ┌─────────────────────────────────────────┐         │     │
│  │  │  Deployment: user-service               │         │     │
│  │  │  - 3 replicas                           │         │     │
│  │  │  - Image: user-service:v1.0.0           │         │     │
│  │  │  - ConfigMap: user-service-config       │         │     │
│  │  │  - Secret: jwt-secret (Sealed)          │         │     │
│  │  └─────────────────────────────────────────┘         │     │
│  │           │                                           │     │
│  │           │ connects to                               │     │
│  │           ▼                                           │     │
│  │  Database Layer                                       │     │
│  │  ┌─────────────────────────────────────────┐         │     │
│  │  │  StatefulSet: postgres                  │         │     │
│  │  │  - 1 replica                            │         │     │
│  │  │  - Image: postgres:16                   │         │     │
│  │  │  - Secret: postgres-secret (Sealed)     │         │     │
│  │  │                                         │         │     │
│  │  │  PersistentVolumeClaim: postgres-data   │         │     │
│  │  │  - 10Gi                                 │         │     │
│  │  │  - Contains: /var/lib/postgresql/data  │         │     │
│  │  └─────────────────────────────────────────┘         │     │
│  │                                                       │     │
│  │  Networking                                           │     │
│  │  ┌─────────────────────────────────────────┐         │     │
│  │  │  Service: user-service                  │         │     │
│  │  │  Service: postgres                      │         │     │
│  │  └─────────────────────────────────────────┘         │     │
│  │                                                       │     │
│  └──────────────────────────────────────────────────────┘     │
│                          │                                     │
│                          │ Velero backup                       │
│                          ▼                                     │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  Backup: production-backup-20250122                  │     │
│  │  - Deployments, StatefulSets, Services               │     │
│  │  - ConfigMaps, Secrets (Sealed)                      │     │
│  │  - PVCs + PV data (Restic)                           │     │
│  │  - Total size: ~500MB (app + DB data)                │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Verify Production Application Exists

Ensure user-service ja PostgreSQL on deployed (from Lab 5, 3-4).

```bash
# Check production namespace
kubectl get all -n production

# Should see:
# - deployment.apps/user-service
# - statefulset.apps/postgres
# - service/user-service
# - service/postgres
```

**If not deployed, deploy now:**

```bash
# Quick deploy (minimal for backup testing)
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

# Deploy PostgreSQL StatefulSet
cat > postgres-statefulset.yaml << 'YAML'
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: production
spec:
  ports:
    - port: 5432
  clusterIP: None
  selector:
    app: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: production
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
          image: postgres:16
          ports:
            - containerPort: 5432
          env:
            - name: POSTGRES_DB
              value: userdb
            - name: POSTGRES_USER
              value: userservice
            - name: POSTGRES_PASSWORD
              value: password123  # In prod: use Sealed Secret (Lab 7)
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
    - metadata:
        name: postgres-data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
YAML

kubectl apply -f postgres-statefulset.yaml

# Deploy user-service (simple version)
kubectl create deployment user-service \
  --image=YOUR_DOCKERHUB_USERNAME/user-service:latest \
  --replicas=2 \
  -n production

kubectl expose deployment user-service \
  --port=3000 \
  --target-port=3000 \
  -n production
```

---

### Samm 2: Populate PostgreSQL with Test Data

Loome test data PostgreSQL'is, et verificeerida PV backup töötab.

```bash
# Exec into PostgreSQL pod
kubectl exec -it -n production postgres-0 -- psql -U userservice -d userdb

# Create test table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW()
);

# Insert test data
INSERT INTO users (name, email) VALUES
  ('Alice', 'alice@example.com'),
  ('Bob', 'bob@example.com'),
  ('Charlie', 'charlie@example.com'),
  ('Diana', 'diana@example.com'),
  ('Eve', 'eve@example.com');

# Verify
SELECT * FROM users;

# Exit
\q
```

**Expected:** 5 users in database.

---

### Samm 3: Create Production Backup (Full Namespace)

Backup entire production namespace (application + database + data).

```bash
# Create backup with Restic (for PV data)
velero backup create production-backup-$(date +%Y%m%d-%H%M) \
  --include-namespaces production \
  --default-volumes-to-restic \
  --wait

# Example:
# velero backup create production-backup-20250122-1200 \
#   --include-namespaces production \
#   --default-volumes-to-restic \
#   --wait
```

**Expected output:**
```
Backup request "production-backup-20250122-1200" submitted successfully.
Waiting for backup to complete. You may safely press ctrl-c to stop waiting...
Backup completed with status: Completed. You may check for more information using the commands `velero backup describe production-backup-20250122-1200` and `velero backup logs production-backup-20250122-1200`.
```

**Note:** Restic backup võib võtta aega (depends on PV size).

---

### Samm 4: Inspect Backup Contents

```bash
# Describe backup
velero backup describe production-backup-20250122-1200

# Expected output shows:
# - Phase: Completed
# - Namespaces: production
# - Resources:
#   - deployments: 1
#   - statefulsets: 1
#   - services: 2
#   - configmaps: X
#   - secrets: X
#   - persistentvolumeclaims: 1
#   - pods: X (transient, excluded by default)
```

**Detailed view:**

```bash
velero backup describe production-backup-20250122-1200 --details

# Shows individual resources backed up
```

**Check logs:**

```bash
velero backup logs production-backup-20250122-1200 | tail -50

# Should NOT show errors
```

---

### Samm 5: Verify Restic Backup (PV Data)

Restic backup'ib PersistentVolume file-level.

```bash
# Check Restic repositories
kubectl get resticrepository -n velero

# Describe
kubectl describe resticrepository -n velero

# Expected: Repository ready, backups count > 0
```

**Verify backup includes PVC:**

```bash
velero backup describe production-backup-20250122-1200 --details \
  | grep -A5 "Restic Backups"

# Should show:
# Restic Backups:
#   production/postgres-data-postgres-0: Completed
```

---

### Samm 6: Simulate Data Loss (Delete Production)

Test restore by deleting production namespace.

**CAUTION:** This deletes production! Only do in lab environment.

```bash
# Delete production namespace
kubectl delete namespace production

# Verify deleted
kubectl get namespace production
# Error: namespace "production" not found

# Verify data gone
kubectl get all -n production
# No resources found
```

---

### Samm 7: Restore Production from Backup

```bash
# Create restore
velero restore create production-restore-$(date +%Y%m%d-%H%M) \
  --from-backup production-backup-20250122-1200 \
  --wait

# Example:
# velero restore create production-restore-20250122-1205 \
#   --from-backup production-backup-20250122-1200 \
#   --wait
```

**Expected output:**
```
Restore request "production-restore-20250122-1205" submitted successfully.
Waiting for restore to complete...
Restore completed with status: Completed.
```

---

### Samm 8: Verify Restored Resources

**Check namespace:**

```bash
# Namespace should exist again
kubectl get namespace production

# Check all resources
kubectl get all,pvc -n production

# Should see:
# - deployment.apps/user-service
# - statefulset.apps/postgres
# - service/user-service
# - service/postgres
# - persistentvolumeclaim/postgres-data-postgres-0
```

**Check StatefulSet:**

```bash
# PostgreSQL pod should be running
kubectl get pods -n production

# Wait for postgres-0 to be Ready
kubectl wait --for=condition=Ready pod/postgres-0 -n production --timeout=5m
```

---

### Samm 9: Verify Database Data Restored

Critical test: check if PostgreSQL data (PV) restored.

```bash
# Exec into PostgreSQL
kubectl exec -it -n production postgres-0 -- psql -U userservice -d userdb

# Query users table
SELECT * FROM users;

# Expected: 5 users (Alice, Bob, Charlie, Diana, Eve)

# Exit
\q
```

**Success!** PersistentVolume data restored via Restic.

---

### Samm 10: Verify Application Works

Test user-service connects to PostgreSQL.

```bash
# Port-forward user-service
kubectl port-forward -n production svc/user-service 3000:3000 &

# Test health endpoint
curl http://localhost:3000/health

# Expected: {"status":"ok"}

# Test database connection (if endpoint exists)
curl http://localhost:3000/api/users

# Should return users from database
```

---

### Samm 11: Restore to Different Namespace (Blue-Green)

Test restore to different namespace (simulate blue-green deployment).

```bash
# Restore to "production-restore-test" namespace
velero restore create production-bluegreen-restore \
  --from-backup production-backup-20250122-1200 \
  --namespace-mappings production:production-restore-test \
  --wait
```

**Verify:**

```bash
# Check new namespace
kubectl get all,pvc -n production-restore-test

# Should have identical resources to production
```

**Test database:**

```bash
# Exec into PostgreSQL in new namespace
kubectl exec -it -n production-restore-test postgres-0 -- psql -U userservice -d userdb

SELECT * FROM users;

# Should show same 5 users

\q
```

**Cleanup:**

```bash
# Delete test namespace
kubectl delete namespace production-restore-test
```

---

### Samm 12: Advanced - Selective Resource Restore

Restore only specific resources (e.g., only StatefulSet).

```bash
# Restore only StatefulSets
velero restore create postgres-only-restore \
  --from-backup production-backup-20250122-1200 \
  --include-resources statefulsets,persistentvolumeclaims \
  --namespace-mappings production:postgres-restore-test

# Verify
kubectl get statefulset,pvc -n postgres-restore-test

# Cleanup
kubectl delete namespace postgres-restore-test
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Production application exists (user-service + PostgreSQL)
- [ ] Test data inserted into PostgreSQL
- [ ] Production backup created (with Restic)
- [ ] Backup completed successfully
- [ ] Restic backed up PersistentVolume
- [ ] Production namespace deleted (simulated disaster)
- [ ] Restore from backup successful
- [ ] All resources restored (Deployment, StatefulSet, Services, PVCs)
- [ ] PostgreSQL data restored (5 users)
- [ ] Application works after restore
- [ ] Blue-green restore to different namespace tested

### Verifitseerimine

```bash
# 1. List backups
velero backup get

# 2. Check production namespace
kubectl get all,pvc -n production

# 3. Verify PostgreSQL data
kubectl exec -n production postgres-0 -- psql -U userservice -d userdb -c "SELECT COUNT(*) FROM users;"
# Should return: 5

# 4. Test application
curl http://localhost:3000/health

# 5. Check restore logs
velero restore describe production-restore-20250122-1205
```

---

## 🔍 Troubleshooting

### Probleem: Restic backup stuck "InProgress"

**Sümptomid:**
```bash
velero backup describe <backup>
# Restic Backups: InProgress
```

**Lahendus:**

```bash
# Check Restic logs
kubectl logs -n velero daemonset/restic | grep -i error

# Check pod has Restic annotation (if not using --default-volumes-to-restic)
kubectl get pod <postgres-pod> -n production -o yaml | grep backup.velero

# If slow: large PV data (wait longer)
# Monitor progress in Restic logs
kubectl logs -n velero daemonset/restic --tail=50 -f
```

---

### Probleem: PostgreSQL pod CrashLoopBackOff after restore

**Sümptomid:**
```bash
kubectl get pods -n production
# postgres-0   0/1   CrashLoopBackOff
```

**Lahendus:**

```bash
# Check pod logs
kubectl logs -n production postgres-0

# Common issues:
# 1. PVC not bound
kubectl get pvc -n production
# If Pending: wait for volume provisioning

# 2. Data corruption
# Delete pod, let StatefulSet recreate
kubectl delete pod -n production postgres-0

# 3. Permission issues (PV ownership)
# Exec and check /var/lib/postgresql/data ownership
```

---

### Probleem: Database empty after restore

**Sümptomid:**
- PostgreSQL pod running
- No users in database

**Lahendus:**

```bash
# Check if PV data restored
kubectl exec -n production postgres-0 -- ls -la /var/lib/postgresql/data

# Should show PostgreSQL data files (base/, pg_wal/, etc.)

# If empty:
# 1. Ensure backup used --default-volumes-to-restic
# 2. Check Restic backup succeeded
velero backup describe <backup> --details | grep "Restic Backups"

# 3. Restore may have failed partially
velero restore logs <restore> | grep -i error
```

---

### Probleem: Restore "PartiallyFailed"

**Lahendus:**

```bash
# Check restore details
velero restore describe <restore> --details

# Common causes:
# 1. Namespace already exists with conflicting resources
#    Fix: Delete namespace first, or use namespace-mappings

# 2. StorageClass not available
#    Fix: Ensure StorageClass exists in target cluster

# 3. Secrets (Sealed Secrets) CRD not installed
#    Fix: Install Sealed Secrets controller (Lab 7)
```

---

## 📚 Mida Sa Õppisid?

✅ **Application-Level Backups**
  - Full namespace backup (all resources)
  - StatefulSet backups (ordered pods)
  - PersistentVolume backups (Restic file-level)

✅ **Restore Strategies**
  - Full restore (disaster recovery)
  - Namespace mapping (blue-green)
  - Selective restore (specific resources)

✅ **Data Consistency**
  - Database data backed up (PV)
  - Verify data after restore
  - Test application functionality

✅ **Production Scenarios**
  - Simulate data loss
  - Measure recovery time
  - Verify zero data loss

---

## 🚀 Järgmised Sammud

**Exercise 3: Scheduled Backups & Retention** - Automate backups:
- Create daily production backup schedule
- Create weekly full cluster backup
- Configure retention policies (TTL)
- Monitor backup status (Prometheus, Lab 6)
- Alert on backup failures

```bash
cat exercises/03-scheduled-backups.md
```

---

## 💡 Application Backup Best Practices

✅ **Consistency:**
- Use backup hooks (pre-backup: pause writes, post-backup: resume)
- For databases: use native backup tools (pg_dump) + Velero

✅ **Testing:**
- Always test restores (monthly drills)
- Restore to separate namespace first
- Verify application works after restore

✅ **Monitoring:**
- Alert on backup failures (Prometheus)
- Track backup duration
- Monitor backup size growth

✅ **Retention:**
- Daily backups: 30 days
- Weekly backups: 12 weeks
- Before major changes: on-demand backup

✅ **Documentation:**
- Document restore procedures
- Maintain runbooks
- Train team on recovery process

---

**Õnnitleme! Production application backup & restore töötab! 🚀💾**

**Kestus:** 60 minutit
**Järgmine:** Exercise 3 - Scheduled Backups & Retention Policies
