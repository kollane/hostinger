# Harjutus 5: Advanced Backup & Restore Scenarios

**Kestus:** 60 minutit
**Eesmärk:** Master advanced Velero scenarios: migration, selective restore, hooks, CI/CD integration.

---

## 📋 Ülevaade

Selles harjutuses uurime **advanced Velero use cases**:

1. **Cross-Cluster Migration** - Move applications between clusters
2. **Selective Restore** - Restore specific resources only
3. **Backup Hooks** - Pre/post-backup commands (database consistency)
4. **Integration with ArgoCD** (Lab 8) - Backup ArgoCD Applications
5. **Integration with Sealed Secrets** (Lab 7) - Backup encrypted secrets
6. **CI/CD Integration** - Automate backups in pipelines

**Real-world scenarios:**
- Migrate from on-prem to cloud
- Blue-green cluster upgrades
- Restore single application (not entire cluster)
- Consistent database backups (flush before backup)

---

## 🎯 Õpieesmärgid

- ✅ Migrate application to different cluster
- ✅ Selective restore (specific resources)
- ✅ Create backup hooks (pre/post-backup)
- ✅ Backup ArgoCD Applications
- ✅ Backup Sealed Secrets
- ✅ Automate backups in CI/CD
- ✅ Restore encrypted secrets correctly

---

## 📝 Sammud

### PART 1: Cross-Cluster Migration

### Samm 1: Setup Second Cluster (or Simulate)

**Option A: Real second cluster**
- Cloud provider (GKE, EKS, AKS)
- Minikube/Kind locally

**Option B: Simulate (same cluster, different namespace)**
```bash
# Create "target-cluster" namespace (simulates second cluster)
kubectl create namespace target-cluster
```

---

### Samm 2: Create Backup in Source Cluster

```bash
# Backup production namespace
velero backup create migration-backup \
  --include-namespaces production \
  --default-volumes-to-restic \
  --wait
```

---

### Samm 3: Restore to Target Cluster (or Namespace)

**Option A: Real second cluster**
```bash
# Install Velero on target cluster (same S3 bucket!)
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --values velero-values.yaml \
  --wait

# Restore from shared S3 bucket
velero restore create migration-restore \
  --from-backup migration-backup \
  --wait
```

**Option B: Simulate (namespace mapping)**
```bash
# Restore to target-cluster namespace
velero restore create migration-restore \
  --from-backup migration-backup \
  --namespace-mappings production:target-cluster \
  --wait

# Verify
kubectl get all -n target-cluster
```

**Use case:** Zero-downtime migration (blue-green clusters)

---

### PART 2: Selective Restore

### Samm 4: Restore Only Specific Resources

**Scenario:** Need only ConfigMaps and Secrets (not full cluster).

```bash
# Restore only ConfigMaps
velero restore create configmaps-only-restore \
  --from-backup production-backup-<timestamp> \
  --include-resources configmaps \
  --namespace-mappings production:production-restore-test

# Verify
kubectl get configmap -n production-restore-test
```

**Restore by labels:**

```bash
# Restore only resources with label app=user-service
velero restore create user-service-only-restore \
  --from-backup production-backup-<timestamp> \
  --selector app=user-service \
  --namespace-mappings production:production-restore-test
```

---

### Samm 5: Exclude Resources from Restore

**Scenario:** Restore everything except Secrets (use fresh secrets).

```bash
velero restore create no-secrets-restore \
  --from-backup production-backup-<timestamp> \
  --exclude-resources secrets \
  --namespace-mappings production:production-restore-test
```

---

### PART 3: Backup Hooks (Database Consistency)

### Samm 6: Create Pre-Backup Hook (PostgreSQL)

**Problem:** PostgreSQL may have in-flight transactions during backup (inconsistent backup).

**Solution:** Pre-backup hook: `CHECKPOINT` (flush WAL to disk).

```yaml
# postgres-backup-hooks.yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres-0
  namespace: production
  annotations:
    # Pre-backup hook: Run before Velero backs up this pod
    pre.hook.backup.velero.io/command: '["/bin/bash", "-c", "PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $POSTGRES_DB -c \"CHECKPOINT;\""]'
    pre.hook.backup.velero.io/timeout: "30s"

    # Post-backup hook: Run after Velero backs up (optional)
    post.hook.backup.velero.io/command: '["/bin/bash", "-c", "echo \"Backup completed\""]'
spec:
  # ... (rest of pod spec)
```

**Apply annotation to existing StatefulSet:**

```bash
# Annotate PostgreSQL StatefulSet
kubectl patch statefulset postgres -n production -p '
{
  "spec": {
    "template": {
      "metadata": {
        "annotations": {
          "pre.hook.backup.velero.io/command": "[\"/bin/bash\", \"-c\", \"PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $POSTGRES_DB -c \\\"CHECKPOINT;\\\"\"]",
          "pre.hook.backup.velero.io/timeout": "30s"
        }
      }
    }
  }
}'

# Restart pods to apply annotation
kubectl rollout restart statefulset postgres -n production
```

---

### Samm 7: Test Backup with Hooks

```bash
# Create backup (hooks will execute)
velero backup create postgres-with-hooks \
  --include-namespaces production \
  --selector app=postgres \
  --default-volumes-to-restic \
  --wait

# Check logs for hook execution
velero backup logs postgres-with-hooks | grep -i hook

# Should see:
# "running pre hook"
# "pre hook completed successfully"
```

---

### PART 4: ArgoCD Integration (Lab 8)

### Samm 8: Backup ArgoCD Applications

```bash
# Backup ArgoCD namespace
velero backup create argocd-backup \
  --include-namespaces argocd \
  --include-resources applications,appprojects,secrets,configmaps \
  --wait

# Verify
velero backup describe argocd-backup --details | grep -i application
```

**Note:** ArgoCD follows GitOps - applications auto-sync from Git. Backup is for ArgoCD config, not application manifests (those are in Git!).

---

### Samm 9: Restore ArgoCD Applications

```bash
# Simulate ArgoCD namespace deletion
kubectl delete namespace argocd

# Restore ArgoCD
velero restore create argocd-restore \
  --from-backup argocd-backup \
  --wait

# Verify Applications restored
kubectl get applications -n argocd

# Applications should auto-sync from Git (GitOps!)
argocd app list
```

---

### PART 5: Sealed Secrets Integration (Lab 7)

### Samm 10: Backup Sealed Secrets

**Challenge:** SealedSecret CRDs need Sealed Secrets controller to decrypt.

```bash
# Backup production (includes SealedSecrets)
velero backup create sealed-secrets-backup \
  --include-namespaces production \
  --include-resources sealedsecrets,secrets \
  --wait

# Verify SealedSecrets included
velero backup describe sealed-secrets-backup --details | grep -i sealed
```

---

### Samm 11: Restore Sealed Secrets

**Prerequisite:** Sealed Secrets controller must be running in target cluster!

```bash
# Ensure Sealed Secrets controller running (Lab 7)
kubectl get pods -n kube-system | grep sealed-secrets

# Restore
velero restore create sealed-secrets-restore \
  --from-backup sealed-secrets-backup \
  --namespace-mappings production:production-restore-test \
  --wait

# Verify SealedSecrets decrypted to Secrets
kubectl get sealedsecrets,secrets -n production-restore-test

# SealedSecret → Secret (controller decrypts)
```

**Important:** Sealed Secrets private key must be same in target cluster (or backup/restore the key).

---

### PART 6: CI/CD Integration

### Samm 12: Automate Backups in GitHub Actions (Lab 5)

**Use case:** Create backup before deployment (rollback safety).

```yaml
# .github/workflows/deploy-with-backup.yaml
name: Deploy with Backup

on:
  push:
    branches: [main]

jobs:
  backup-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Install Velero CLI
        run: |
          wget https://github.com/vmware-tanzu/velero/releases/latest/download/velero-linux-amd64.tar.gz
          tar -xvf velero-linux-amd64.tar.gz
          sudo mv velero-*/velero /usr/local/bin/

      - name: Configure kubectl
        run: |
          echo "${{ secrets.KUBECONFIG }}" > kubeconfig
          export KUBECONFIG=kubeconfig

      - name: Create pre-deployment backup
        run: |
          velero backup create pre-deploy-backup-$(date +%s) \
            --include-namespaces production \
            --default-volumes-to-restic \
            --wait

      - name: Deploy application
        run: |
          kubectl apply -f k8s/production/

      - name: Verify deployment
        run: |
          kubectl rollout status deployment/user-service -n production

      - name: Rollback on failure
        if: failure()
        run: |
          BACKUP=$(velero backup get --sort-by startTimestamp | grep pre-deploy | tail -1 | awk '{print $1}')
          velero restore create rollback-restore-$(date +%s) \
            --from-backup $BACKUP \
            --wait
```

---

### Samm 13: Automate Restore Testing

**CI/CD pipeline:** Test restores automatically.

```yaml
# .github/workflows/test-backups.yaml
name: Test Backups Monthly

on:
  schedule:
    - cron: '0 0 1 * *'  # 1st of month

jobs:
  restore-test:
    runs-on: ubuntu-latest
    steps:
      - name: Get latest backup
        run: |
          BACKUP=$(velero backup get --sort-by startTimestamp | tail -1 | awk '{print $1}')
          echo "Testing backup: $BACKUP"

      - name: Restore to test namespace
        run: |
          velero restore create test-restore-$(date +%s) \
            --from-backup $BACKUP \
            --namespace-mappings production:backup-test \
            --wait

      - name: Verify restore
        run: |
          kubectl get all -n backup-test
          kubectl exec -n backup-test postgres-0 -- psql -U userservice -d userdb -c "SELECT COUNT(*) FROM users;"

      - name: Cleanup
        run: |
          kubectl delete namespace backup-test
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Cross-cluster migration tested
- [ ] Selective restore (specific resources) tested
- [ ] Backup hooks configured (PostgreSQL)
- [ ] ArgoCD Applications backed up and restored
- [ ] Sealed Secrets backed up and restored
- [ ] CI/CD backup automation created
- [ ] Automated restore testing pipeline created

### Verifitseerimine

```bash
# 1. Check migration backup
velero backup get | grep migration

# 2. Verify selective restore
kubectl get configmap -n production-restore-test

# 3. Check hooks executed
velero backup logs postgres-with-hooks | grep hook

# 4. Verify ArgoCD restored
kubectl get applications -n argocd

# 5. Verify Sealed Secrets decrypted
kubectl get sealedsecrets,secrets -n production-restore-test
```

---

## 📚 Mida Sa Õppisid?

✅ **Cross-Cluster Migration**
  - Same backup, different cluster
  - Namespace mappings
  - Zero-downtime migration

✅ **Selective Restore**
  - Resource filtering (include/exclude)
  - Label selectors
  - Granular control

✅ **Backup Hooks**
  - Pre-backup commands (database consistency)
  - Post-backup commands
  - Pod annotation syntax

✅ **ArgoCD Integration**
  - Backup ArgoCD namespace
  - GitOps + Backup synergy
  - Application auto-sync after restore

✅ **Sealed Secrets Integration**
  - SealedSecret CRDs backup
  - Controller decrypts after restore
  - Private key management

✅ **CI/CD Integration**
  - Automated pre-deployment backups
  - Automated restore testing
  - Rollback automation

---

## 🚀 Lab 9 Complete!

**Õnnitleme! Sa läbisid Lab 9: Backup & Disaster Recovery! 🎉💾**

**Mida sa saavutasid:**
- ✅ Velero installation (MinIO storage)
- ✅ Application backups (user-service + PostgreSQL)
- ✅ Scheduled backups (daily, weekly, monthly)
- ✅ Disaster recovery (full cluster restore, RTO < 30 min)
- ✅ Advanced scenarios (migration, selective restore, hooks)
- ✅ Production-ready backup strategy

**Järgmised sammud:**
- **Lab 10:** Infrastructure as Code with Terraform (final lab!)

---

## 💡 Velero Best Practices Summary

✅ **Backup Strategy:**
- Daily backups: Production (30 days)
- Weekly backups: Full cluster (12 weeks)
- Monthly backups: Compliance (12 months)

✅ **Retention:**
- Automate with TTL
- Monitor storage costs
- 3-2-1 rule (3 copies, 2 storage types, 1 off-site)

✅ **Monitoring:**
- Prometheus metrics
- Grafana dashboards
- AlertManager alerts on failures

✅ **Testing:**
- Monthly restore drills
- Automated restore testing
- Document RTO/RPO

✅ **Security:**
- Encrypt backups (S3 SSE)
- RBAC for Velero access
- Sealed Secrets for sensitive data

---

**Kestus:** 60 minutit
**Lab 9 Total:** 5 hours (5 exercises × 60 min)
**Status:** ✅ Complete

EOF
