# Harjutus 4: Disaster Recovery Drill

**Kestus:** 60 minutit
**Eesmärk:** Simulate catastrophic failure ja täielik cluster restore.

---

## 📋 Ülevaade

Selles harjutuses testim **disaster recovery** stsenaariumi: simulate total production failure ja full cluster restore. See on **critical production skill**.

**Scenario:** Production cluster failure
- Entire production namespace deleted (human error: `kubectl delete ns production`)
- Or: etcd corruption, ransomware, cloud provider outage
- **Goal:** Restore from backup, minimize downtime

**Metrics:**
- **RTO (Recovery Time Objective):** How long to restore?
- **RPO (Recovery Point Objective):** How much data loss?

**This exercise:**
- RTO target: < 30 minutes
- RPO: 24 hours (daily backups)

---

## 🎯 Õpieesmärgid

- ✅ Create full cluster backup
- ✅ Simulate catastrophic failure
- ✅ Perform full cluster restore
- ✅ Measure RTO (recovery time)
- ✅ Verify all applications running
- ✅ Document recovery procedures
- ✅ Test restore in separate cluster (bonus)

---

## 📝 Sammud

### Samm 1: Create Full Cluster Backup (Pre-Disaster)

```bash
# Full cluster backup (all namespaces)
velero backup create full-cluster-backup-$(date +%Y%m%d-%H%M) \
  --include-namespaces '*' \
  --default-volumes-to-restic \
  --wait

# Wait for completion (may take 10-30 min depending on cluster size)
```

**Verify backup:**

```bash
velero backup describe full-cluster-backup-<timestamp>

# Should show:
# Phase: Completed
# Total items: 100+ (all resources in cluster)
# Restic Backups: Completed (all PVs)
```

---

### Samm 2: Document Pre-Disaster State

Document current state (for verification after restore).

```bash
# Count resources
kubectl get all --all-namespaces | wc -l

# List all namespaces
kubectl get namespaces

# Save state to file
kubectl get all --all-namespaces > pre-disaster-state.txt
```

**Key metrics:**
- Number of namespaces
- Number of pods
- Number of PVCs
- Total PV data size

---

### Samm 3: Simulate Disaster (Delete Production)

**CAUTION:** Only in lab environment!

**Start RTO timer:**

```bash
START_TIME=$(date +%s)
echo "Disaster occurred at: $(date)"
```

**Simulate disaster:**

```bash
# Delete production namespace (simulate accidental deletion)
kubectl delete namespace production

# Verify deleted
kubectl get namespace production
# Error: namespace "production" not found
```

**Or simulate full cluster failure (more extreme):**

```bash
# Delete ALL application namespaces (keep kube-system, velero)
kubectl delete namespace development staging production monitoring argocd

# Cluster is now "empty" (applications gone)
```

---

### Samm 4: Begin Recovery (Restore from Backup)

**Check available backups:**

```bash
# List recent backups
velero backup get

# Find latest full cluster backup
velero backup get | grep full-cluster
```

**Start restore:**

```bash
# Restore from latest backup
velero restore create disaster-recovery-restore \
  --from-backup full-cluster-backup-<timestamp> \
  --wait

# This will take 5-20 minutes depending on cluster size
```

---

### Samm 5: Monitor Restore Progress

```bash
# Watch restore progress
velero restore describe disaster-recovery-restore

# Check Phase: InProgress → Completed

# Stream logs
velero restore logs disaster-recovery-restore --follow
```

**Monitor namespace recreation:**

```bash
# Watch namespaces being restored
watch kubectl get namespaces

# Should see:
# production, staging, development, monitoring, argocd (recreated)
```

---

### Samm 6: Verify All Namespaces Restored

```bash
# Check namespaces
kubectl get namespaces

# Compare with pre-disaster state
diff <(cat pre-disaster-state.txt | grep "^namespace" | sort) \
     <(kubectl get namespaces --no-headers | awk '{print $1}' | sort)

# Should match
```

---

### Samm 7: Verify Production Applications Running

**Check pods:**

```bash
# Wait for all pods to be Running
kubectl get pods --all-namespaces

# Or check production specifically
kubectl get pods -n production

# Wait for Ready
kubectl wait --for=condition=Ready pods --all -n production --timeout=10m
```

**Check StatefulSets (PostgreSQL):**

```bash
# PostgreSQL should be running
kubectl get statefulset -n production postgres

# Check data restored
kubectl exec -n production postgres-0 -- psql -U userservice -d userdb -c "SELECT COUNT(*) FROM users;"

# Should show 5 (or your test data count)
```

---

### Samm 8: Verify ArgoCD Restored (Lab 8)

```bash
# Check ArgoCD namespace
kubectl get pods -n argocd

# All ArgoCD components should be Running:
# - argocd-server
# - argocd-repo-server
# - argocd-application-controller

# Check ArgoCD Applications restored
kubectl get applications -n argocd

# Applications should auto-sync from Git (GitOps!)
```

---

### Samm 9: Verify Monitoring Restored (Lab 6)

```bash
# Check Prometheus
kubectl get pods -n monitoring | grep prometheus

# Check Grafana
kubectl get pods -n monitoring | grep grafana

# Port-forward and verify dashboards
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
# Open: http://localhost:3000
```

---

### Samm 10: Calculate RTO (Recovery Time Objective)

```bash
# End RTO timer
END_TIME=$(date +%s)

# Calculate RTO
RTO=$((END_TIME - START_TIME))

echo "RTO: ${RTO} seconds ($((RTO / 60)) minutes)"

# Example output: RTO: 1200 seconds (20 minutes)
```

**Document RTO:**
- **Target:** < 30 minutes
- **Achieved:** <YOUR_RTO> minutes
- **Pass/Fail:** (based on target)

---

### Samm 11: Verify Data Integrity (No Data Loss)

**RPO (Recovery Point Objective):**
- Daily backups = RPO of 24 hours
- If disaster happens 23 hours after backup, max 23 hours data loss

**Check PostgreSQL data:**

```bash
# Count users (should match pre-disaster count)
kubectl exec -n production postgres-0 -- psql -U userservice -d userdb -c "SELECT COUNT(*) FROM users;"

# Compare with pre-disaster backup
# If using daily backup: max 24h data loss acceptable
```

**Verify ConfigMaps and Secrets:**

```bash
# Check ConfigMaps restored
kubectl get configmap -n production

# Check Sealed Secrets restored
kubectl get sealedsecrets -n production
```

---

### Samm 12: Document Recovery Procedures

Create runbook for future disasters.

```markdown
# Disaster Recovery Runbook

## Prerequisites
- Velero installed and configured
- Daily backups running
- Access to backup storage (MinIO/S3)
- kubectl access to cluster

## Recovery Steps

1. **Identify disaster type**
   - Namespace deleted
   - Cluster corruption
   - Ransomware

2. **Find latest backup**
   ```
   velero backup get | grep full-cluster
   ```

3. **Start restore**
   ```
   velero restore create dr-restore-$(date +%s) \
     --from-backup <latest-backup> \
     --wait
   ```

4. **Monitor restore**
   ```
   velero restore describe dr-restore-<timestamp>
   ```

5. **Verify applications**
   ```
   kubectl get pods --all-namespaces
   kubectl get pvc --all-namespaces
   ```

6. **Verify data integrity**
   - Check databases (query count)
   - Check application functionality
   - Verify user-facing services

7. **Calculate RTO**
   - Document time from disaster to full recovery

8. **Post-mortem**
   - What caused disaster?
   - How to prevent?
   - Update runbook

## Contacts
- On-call: <phone>
- Backup admin: <email>
- Cloud provider support: <number>
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Full cluster backup created
- [ ] Pre-disaster state documented
- [ ] Disaster simulated (namespace deleted)
- [ ] RTO timer started
- [ ] Restore initiated
- [ ] All namespaces restored
- [ ] All pods Running
- [ ] PostgreSQL data verified
- [ ] ArgoCD restored (Lab 8)
- [ ] Monitoring restored (Lab 6)
- [ ] RTO calculated (< 30 min target)
- [ ] Recovery procedures documented

### Verifitseerimine

```bash
# 1. Check restore completed
velero restore describe disaster-recovery-restore

# 2. Count resources (match pre-disaster)
kubectl get all --all-namespaces | wc -l

# 3. Verify production app
curl http://<user-service-ip>:3000/health

# 4. Check PostgreSQL data
kubectl exec -n production postgres-0 -- psql -U userservice -d userdb -c "SELECT COUNT(*) FROM users;"

# 5. RTO within target
echo "RTO: ${RTO} seconds"
```

---

## 🔍 Troubleshooting

### Probleem: Restore stuck "InProgress"

**Lahendus:**
```bash
# Check Velero logs
kubectl logs -n velero deployment/velero --tail=100

# Check Restic (if PV restore slow)
kubectl logs -n velero daemonset/restic --tail=50

# Patience: Large PVs take time (10-30 min)
```

### Probleem: Pods CrashLoopBackOff after restore

**Lahendus:**
```bash
# Common: PVCs not bound yet (wait)
kubectl get pvc --all-namespaces

# If Pending: wait for volume provisioning
# If Bound: delete pod, let controller recreate
kubectl delete pod <pod-name> -n <namespace>
```

---

## 📚 Mida Sa Õppisid?

✅ Full cluster backup & restore
✅ RTO measurement
✅ Disaster recovery procedures
✅ Data integrity verification
✅ Runbook creation

---

## 🚀 Järgmised Sammud

**Exercise 5: Advanced Scenarios** - Migration, selective restore:
- Cross-cluster migration
- Selective resource restore
- Backup hooks (pre/post-backup)
- CI/CD integration

```bash
cat exercises/05-advanced-scenarios.md
```

---

**Kestus:** 60 minutit
**Järgmine:** Exercise 5 - Advanced Scenarios
