# Lab 9: Backup & Disaster Recovery

**Kestus:** 5 tundi (5 × 60 min exercises)
**Eeldus:** Lab 1-8 completed
**Eesmärk:** Implementeeri production-ready backup ja disaster recovery strateegia Velero'ga.

---

## 📋 Ülevaade

See lab õpetab **production-critical** oskust: **backup & disaster recovery (DR)** Kubernetes cluster'ites. Kasutame **Velero** - industry-standard Kubernetes backup tool, mis tagab:

- ✅ **Backup:** Kubernetes resources, PersistentVolumes, secrets
- ✅ **Restore:** Full cluster, namespace, või application-level restore
- ✅ **Migration:** Move applications between clusters
- ✅ **Disaster Recovery:** Recover from catastrophic failures
- ✅ **Compliance:** Regulatory backup requirements

**Miks see oluline?**
> "It's not a matter of IF you'll need backups, but WHEN."

Production incidents:
- Accidental `kubectl delete` (human error)
- Ransomware attacks (encrypt Kubernetes etcd)
- Cloud provider outages (whole region down)
- Cluster corruption (etcd failure)
- Data loss (PersistentVolume deleted)

**Lab 9 integratsioon:**
- **Lab 7:** Backup Vault secrets, Sealed Secrets
- **Lab 8:** Backup ArgoCD Applications
- **Lab 6:** Monitor Velero metrics (Prometheus)
- **Lab 3-4:** Backup StatefulSets (PostgreSQL)

---

## 🎯 Õpieesmärgid

Peale selle lab'i läbimist oskad:

- ✅ Installida ja konfigureerida Velero
- ✅ Seadistada backup storage (S3, MinIO)
- ✅ Luua application-level backups (user-service + database)
- ✅ Luua PersistentVolume backups
- ✅ Seadistada scheduled backups (daily, weekly)
- ✅ Teostada full cluster restore
- ✅ Teostada selective restore (namespace, application)
- ✅ Testida disaster recovery scenario
- ✅ Migreerida applications teise cluster'isse
- ✅ Integreerida backups CI/CD workflow'ga

---

## 🏗️ Velero Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Velero Architecture                            │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐      │
│  │  Kubernetes Cluster                                    │      │
│  │                                                         │      │
│  │  ┌──────────────────┐                                  │      │
│  │  │  Velero Server   │                                  │      │
│  │  │  (Deployment)    │                                  │      │
│  │  └────────┬─────────┘                                  │      │
│  │           │                                             │      │
│  │           │ watches                                     │      │
│  │           ▼                                             │      │
│  │  ┌──────────────────────────────────────────┐          │      │
│  │  │  Kubernetes Resources                    │          │      │
│  │  │  - Deployments, Services, ConfigMaps     │          │      │
│  │  │  - Secrets, PVCs, StatefulSets           │          │      │
│  │  │  - ArgoCD Applications, Vault configs    │          │      │
│  │  └──────────────────────────────────────────┘          │      │
│  │           │                                             │      │
│  │           │ backup                                      │      │
│  │           ▼                                             │      │
│  │  ┌──────────────────┐       ┌──────────────────┐       │      │
│  │  │  Volume Snapshots│       │  Resource JSONs  │       │      │
│  │  │  (PV data)       │       │  (manifests)     │       │      │
│  │  └────────┬─────────┘       └────────┬─────────┘       │      │
│  │           │                           │                 │      │
│  └───────────┼───────────────────────────┼─────────────────┘      │
│              │                           │                        │
│              │ upload                    │ upload                 │
│              ▼                           ▼                        │
│  ┌──────────────────────────────────────────────────────┐        │
│  │  Object Storage (S3, MinIO, GCS, Azure)              │        │
│  │                                                       │        │
│  │  backups/                                             │        │
│  │  ├── production-backup-20250122-1200/                │        │
│  │  │   ├── manifests.json.gz                           │        │
│  │  │   ├── pv-snapshots/                               │        │
│  │  │   └── metadata.json                               │        │
│  │  ├── production-backup-20250123-1200/                │        │
│  │  └── ...                                              │        │
│  └──────────────────────────────────────────────────────┘        │
│                          │                                        │
│                          │ restore                                │
│                          ▼                                        │
│  ┌──────────────────────────────────────────────────────┐        │
│  │  Target Cluster (same or different)                  │        │
│  │  - Recreate Deployments, Services, ConfigMaps        │        │
│  │  - Restore PersistentVolumes                         │        │
│  │  - Restore Secrets (encrypted via Sealed Secrets)    │        │
│  └──────────────────────────────────────────────────────┘        │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

**Velero Components:**
1. **Server:** Runs in Kubernetes, watches resources, executes backups/restores
2. **CLI:** `velero` command-line tool for managing backups
3. **Plugins:** CSI snapshots, S3, GCS, Azure storage providers
4. **Restic:** File-level backup for PersistentVolumes (alternative to snapshots)

---

## 📊 Backup Strategies

### 1. Full Cluster Backup
Backup everything in cluster (all namespaces, all resources).

**Use case:** Disaster recovery, cluster migration

```bash
velero backup create full-cluster-backup \
  --include-namespaces '*' \
  --snapshot-volumes
```

---

### 2. Namespace-Level Backup
Backup specific namespace(s).

**Use case:** Application-level backup, multi-tenant clusters

```bash
velero backup create production-backup \
  --include-namespaces production \
  --snapshot-volumes
```

---

### 3. Application-Level Backup
Backup specific application (by labels).

**Use case:** Selective backup, granular control

```bash
velero backup create user-service-backup \
  --selector app=user-service \
  --include-namespaces production
```

---

### 4. Scheduled Backups
Automated backups (daily, weekly, retention).

**Use case:** Production best practice, compliance

```bash
velero schedule create daily-production \
  --schedule="0 2 * * *" \
  --include-namespaces production \
  --ttl 720h  # 30 days retention
```

---

### 5. PersistentVolume Backups
Backup data in PersistentVolumes.

**Methods:**
- **Volume Snapshots (CSI):** Cloud-native snapshots (fast, efficient)
- **Restic:** File-level backup (works everywhere, slower)

```bash
# CSI snapshots (if supported by storage class)
velero backup create postgres-backup \
  --include-namespaces production \
  --snapshot-volumes

# Restic file-level backup
velero backup create postgres-backup-restic \
  --include-namespaces production \
  --default-volumes-to-restic
```

---

## 🔗 Integration with Previous Labs

### Lab 7: Security & Secrets Management

**Challenge:** Secrets (Vault, Sealed Secrets) need special handling.

**Solution:**
- **Sealed Secrets:** Backup SealedSecret CRDs (encrypted in Git anyway)
- **Vault:** Backup Vault data separately (Vault snapshots)
- **Kubernetes Secrets:** Backed up but decrypt carefully during restore

```bash
# Backup including Sealed Secrets
velero backup create security-backup \
  --include-namespaces production \
  --include-resources sealedsecrets,secrets
```

---

### Lab 8: GitOps with ArgoCD

**Challenge:** ArgoCD Applications are CRDs, need backup.

**Solution:**
- Backup ArgoCD namespace (Applications, Projects, RBAC)
- Restore ArgoCD → applications auto-sync from Git

```bash
# Backup ArgoCD configuration
velero backup create argocd-backup \
  --include-namespaces argocd \
  --include-resources applications,appprojects
```

**Note:** Since ArgoCD follows GitOps, manifests are in Git. Backup is for ArgoCD config itself, not applications (those are in Git!).

---

### Lab 6: Monitoring & Logging

**Integration:** Monitor Velero with Prometheus.

- Velero exports metrics (backup success/failure, duration)
- Create Grafana dashboard for backup monitoring
- Alert on backup failures

```yaml
# Velero Prometheus metrics
velero_backup_success_total
velero_backup_failure_total
velero_backup_duration_seconds
```

---

### Lab 3-4: StatefulSets (PostgreSQL)

**Challenge:** StatefulSets with PersistentVolumes need consistent backups.

**Solution:**
- Use Velero hooks (pre-backup: pause writes, post-backup: resume)
- CSI snapshots for PV data
- Backup StatefulSet manifests + PVCs

```bash
# Backup PostgreSQL StatefulSet
velero backup create postgres-backup \
  --include-namespaces production \
  --selector app=postgres \
  --snapshot-volumes
```

---

## 📝 Lab Exercises

### Exercise 1: Velero Setup & Installation (60 min)

**Õpieesmärgid:**
- Install Velero CLI
- Install Velero server (Helm)
- Configure MinIO as backup storage (self-hosted S3)
- Verify backup/restore functionality

**Steps:**
1. Install Velero CLI
2. Deploy MinIO (in-cluster S3-compatible storage)
3. Install Velero with MinIO backend
4. Create first test backup
5. Perform test restore

**Output:** Working Velero installation with MinIO storage.

---

### Exercise 2: Application Backups (60 min)

**Õpieesmärgid:**
- Backup user-service application (from Lab 5)
- Backup PostgreSQL StatefulSet with data
- Verify backup contents
- Restore to different namespace (test)

**Steps:**
1. Backup production namespace (user-service + PostgreSQL)
2. Inspect backup contents
3. Simulate application deletion
4. Restore from backup
5. Verify application works after restore

**Output:** Functional application backup and restore.

---

### Exercise 3: Scheduled Backups & Retention (60 min)

**Õpieesmärgid:**
- Create scheduled backups (daily, weekly)
- Configure retention policies (30 days)
- Monitor backup status
- Integration with Prometheus (Lab 6)

**Steps:**
1. Create daily production backup schedule
2. Create weekly full cluster backup
3. Configure TTL (time-to-live) for old backups
4. Set up Prometheus monitoring
5. Create Grafana dashboard

**Output:** Automated backup workflow with monitoring.

---

### Exercise 4: Disaster Recovery Drill (60 min)

**Õpieesmärgid:**
- Simulate catastrophic failure
- Perform full cluster restore
- Verify all applications working
- Document recovery time objective (RTO)

**Steps:**
1. Create full cluster backup
2. Simulate disaster (delete production namespace)
3. Restore from backup
4. Verify ArgoCD, user-service, PostgreSQL
5. Measure recovery time

**Output:** Tested disaster recovery plan with documented RTO.

---

### Exercise 5: Advanced Scenarios (60 min)

**Õpieesmärgid:**
- Cross-cluster migration
- Selective restore (specific resources)
- Backup hooks (pre/post-backup commands)
- Integration with CI/CD

**Steps:**
1. Migrate application to different cluster
2. Selective restore (restore only ConfigMaps)
3. Create backup hooks for PostgreSQL (pause writes)
4. Automate backups in CI/CD pipeline
5. Restore encrypted secrets (Sealed Secrets)

**Output:** Advanced backup/restore scenarios mastered.

---

## 🛠️ Prerequisites

### Required (from previous labs):

- ✅ **Kubernetes cluster** (Lab 3)
- ✅ **kubectl** configured
- ✅ **Helm** installed
- ✅ **user-service** deployed (Lab 5)
- ✅ **PostgreSQL StatefulSet** (Lab 3-4)
- ✅ **ArgoCD** installed (Lab 8)
- ✅ **Prometheus** monitoring (Lab 6)

### Storage Requirements:

- **MinIO:** In-cluster object storage (~10GB)
- **Alternative:** AWS S3, GCS, Azure Blob Storage

### Tools to Install:

- **Velero CLI** (Linux/Mac/Windows)
- **MinIO Client** (optional, for debugging)

---

## 🔒 Security Best Practices

### 1. Encrypt Backups

Velero supports encryption at rest (cloud provider encryption).

```yaml
# Velero BackupStorageLocation with encryption
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: default
spec:
  provider: aws
  objectStorage:
    bucket: velero-backups
  config:
    serverSideEncryption: AES256  # S3 encryption
```

---

### 2. Access Control

Velero needs permissions to read all resources.

```yaml
# RBAC for Velero (least privilege)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: velero
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

**Security consideration:** Velero has broad permissions. Secure Velero namespace!

---

### 3. Secrets Handling

**Sealed Secrets (Lab 7):** Backups include encrypted SealedSecret CRDs (safe).

**Kubernetes Secrets:** Backed up in plaintext in object storage.
- ✅ **Solution:** Encrypt object storage (S3 SSE, GCS encryption)
- ✅ **Alternative:** Exclude secrets, rely on Vault (Lab 7)

```bash
# Exclude secrets from backup
velero backup create no-secrets-backup \
  --exclude-resources secrets
```

---

### 4. Backup Verification

Always test restores!

```bash
# Restore to test namespace (verify before production)
velero restore create test-restore \
  --from-backup production-backup \
  --namespace-mappings production:test-restore
```

---

## 📈 Monitoring & Alerting

### Velero Metrics (Prometheus Integration)

Velero exposes Prometheus metrics:

```yaml
# ServiceMonitor for Velero (Lab 6)
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: velero
  namespace: velero
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: velero
  endpoints:
    - port: monitoring
      path: /metrics
```

**Key Metrics:**
- `velero_backup_success_total` - Successful backups
- `velero_backup_failure_total` - Failed backups
- `velero_backup_duration_seconds` - Backup duration
- `velero_restore_success_total` - Successful restores

---

### Alerting Rules

```yaml
# Prometheus AlertRule for backup failures
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: velero-alerts
spec:
  groups:
    - name: velero
      interval: 30s
      rules:
        - alert: VeleroBackupFailed
          expr: velero_backup_failure_total > 0
          for: 5m
          annotations:
            summary: "Velero backup failed"
            description: "Backup {{ $labels.backup }} failed"
```

---

## 💡 Best Practices

### ✅ 1. Test Restores Regularly

> "Untested backups are Schrödinger's backups - they both exist and don't exist until you try to restore."

**Practice:**
- Monthly restore drills
- Restore to test environment
- Document restore procedures

---

### ✅ 2. Multiple Backup Locations

**3-2-1 Rule:**
- **3** copies of data
- **2** different storage types
- **1** off-site copy

```bash
# Example: MinIO (in-cluster) + S3 (cloud)
velero backup-location create minio --provider aws ...
velero backup-location create s3 --provider aws ...
```

---

### ✅ 3. Retention Policies

Balance cost and compliance.

```bash
# Daily: 30 days
# Weekly: 12 weeks
# Monthly: 12 months

velero schedule create daily --schedule="0 2 * * *" --ttl 720h
velero schedule create weekly --schedule="0 2 * * 0" --ttl 2016h
velero schedule create monthly --schedule="0 2 1 * *" --ttl 8760h
```

---

### ✅ 4. Backup Validation

Automate restore testing.

```bash
# CI/CD pipeline: restore backup to ephemeral test cluster
velero restore create auto-test-restore \
  --from-backup latest \
  --wait
```

---

### ✅ 5. Document Recovery Procedures

Create runbooks:
1. Restore priority (critical apps first)
2. Step-by-step restore commands
3. Rollback procedures
4. Contact information (on-call)

---

## 🔍 Troubleshooting

### Backup Stuck in "InProgress"

**Symptoms:** Backup never completes.

**Causes:**
- Large PersistentVolumes (slow snapshots)
- Network issues (upload to S3 fails)
- Resource limits (Velero pod OOMKilled)

**Solutions:**
```bash
# Check Velero logs
kubectl logs -n velero deployment/velero

# Increase Velero resources
kubectl edit deployment velero -n velero
# resources.limits.memory: 1Gi → 2Gi

# Check backup status
velero backup describe <backup-name>
```

---

### Restore Fails with "PartiallyFailed"

**Symptoms:** Some resources not restored.

**Causes:**
- Resource conflicts (resource already exists)
- CRD not installed (e.g., SealedSecret CRD missing)
- Namespace doesn't exist

**Solutions:**
```bash
# Check restore details
velero restore describe <restore-name> --details

# Restore errors
velero restore logs <restore-name>

# Skip existing resources
velero restore create --from-backup <backup> --existing-resource-policy update
```

---

## 📚 Resources

**Velero Documentation:**
- https://velero.io/docs/
- https://github.com/vmware-tanzu/velero

**Community:**
- Velero Slack: kubernetes.slack.com #velero
- GitHub Discussions: https://github.com/vmware-tanzu/velero/discussions

---

## 🎯 Learning Outcomes

Peale selle lab'i:

✅ **Oskad seadistada** production-ready backup strateegia
✅ **Oskad teostada** disaster recovery
✅ **Mõistad** backup best practices (3-2-1, retention, testing)
✅ **Oskad integreerida** backups CI/CD workflow'ga
✅ **Oskad migreerida** applications cross-cluster
✅ **Oskad monitorida** backup health (Prometheus, Grafana)

---

## 🚀 Next Steps

**After Lab 9:**
- **Lab 10:** Infrastructure as Code with Terraform
  - Provision Kubernetes resources with Terraform
  - Backup Terraform state
  - GitOps for infrastructure

---

**Lab 9 Status:** Ready to start! 🚀💾

**Estimated Time:** 5 hours
**Difficulty:** Advanced (builds on Lab 1-8)

**Begin with:** `cat exercises/01-velero-setup.md`

