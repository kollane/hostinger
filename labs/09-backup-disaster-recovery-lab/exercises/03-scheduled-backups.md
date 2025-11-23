# Harjutus 3: Scheduled Backups & Retention Policies

**Kestus:** 60 minutit
**Eesmärk:** Automatiseeri backups scheduled CRD'dega ja konfigureeri retention policies.

---

## 📋 Ülevaade

Selles harjutuses loome **automated backup schedules** - production best practice. Manuaalsed backups ei ole piisavad; vajame:

- ✅ **Daily backups** - Production namespaces (30 days retention)
- ✅ **Weekly backups** - Full cluster (12 weeks retention)
- ✅ **Monthly backups** - Long-term compliance (12 months retention)
- ✅ **Retention policies** - Auto-delete old backups (save storage costs)
- ✅ **Monitoring** - Prometheus alerts on backup failures

**Miks schedule'd?**
- Consistent backups (every day at 2 AM)
- No human error (forget to backup)
- Compliance requirements (regulatory)
- Cost optimization (retention policies)

**Velero Schedule CRD:**
- Cron-based scheduling
- Automatic backup creation
- Automatic old backup deletion (TTL)
- Same options as manual backups

**Integration:**
- **Lab 6:** Prometheus monitoring, Grafana dashboards
- **Lab 7:** Backup Sealed Secrets automatically
- **Lab 8:** Backup ArgoCD Applications daily

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

✅ Luua Velero Schedule CRD
✅ Konfigureerida cron expressions (daily, weekly, monthly)
✅ Seadistada retention policies (TTL)
✅ Monitor'ida scheduled backups (Prometheus)
✅ Create Grafana dashboard backup metrics'tele
✅ Seadistada AlertManager alerts backup failures'tele
✅ Manage'ida backup storage costs

---

## 🏗️ Backup Schedule Strategy

```
┌────────────────────────────────────────────────────────────────┐
│              Backup Schedule Strategy (3-2-1 Rule)             │
│                                                                │
│  Daily Backups (30 days retention)                             │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  Schedule: production-daily                          │     │
│  │  Cron: "0 2 * * *" (every day at 2 AM UTC)           │     │
│  │  Scope: production namespace                         │     │
│  │  TTL: 720h (30 days)                                 │     │
│  │  Restic: Yes (PV data)                               │     │
│  │                                                       │     │
│  │  Backups created:                                     │     │
│  │  - production-daily-20250122020000                    │     │
│  │  - production-daily-20250123020000                    │     │
│  │  - ... (30 days worth)                                │     │
│  │  - production-daily-20250221020000 (oldest, auto-deleted)│  │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
│  Weekly Backups (12 weeks retention)                           │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  Schedule: full-weekly                               │     │
│  │  Cron: "0 3 * * 0" (every Sunday at 3 AM UTC)        │     │
│  │  Scope: all namespaces (*)                           │     │
│  │  TTL: 2016h (12 weeks = 84 days)                     │     │
│  │  Restic: Yes                                          │     │
│  │                                                       │     │
│  │  Backups created:                                     │     │
│  │  - full-weekly-20250119030000                         │     │
│  │  - full-weekly-20250126030000                         │     │
│  │  - ... (12 weeks worth)                               │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
│  Monthly Backups (12 months retention)                         │
│  ┌──────────────────────────────────────────────────────┐     │
│  │  Schedule: full-monthly                              │     │
│  │  Cron: "0 4 1 * *" (1st day of month at 4 AM UTC)    │     │
│  │  Scope: all namespaces                               │     │
│  │  TTL: 8760h (12 months = 365 days)                   │     │
│  │  Restic: Yes                                          │     │
│  │                                                       │     │
│  │  Backups created:                                     │     │
│  │  - full-monthly-20250101040000                        │     │
│  │  - full-monthly-20250201040000                        │     │
│  │  - ... (12 months worth)                              │     │
│  └──────────────────────────────────────────────────────┘     │
│                                                                │
│  Total Backups at any time:                                    │
│  - 30 daily (production)                                       │
│  - 12 weekly (full cluster)                                    │
│  - 12 monthly (full cluster)                                   │
│  = ~54 backups total                                           │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

**3-2-1 Backup Rule:**
- **3** copies of data (original + 2 backups)
- **2** different storage types (MinIO + S3)
- **1** off-site copy (S3 in different region)

---

## 📝 Sammud

### Samm 1: Create Daily Production Backup Schedule

Daily backup production namespace (RPO = 24h).

```bash
# Create schedule
velero schedule create production-daily \
  --schedule="0 2 * * *" \
  --include-namespaces production \
  --default-volumes-to-restic \
  --ttl 720h

# Verify schedule created
velero schedule get

# Expected:
# NAME               STATUS    CREATED                          SCHEDULE    BACKUP TTL   LAST BACKUP   SELECTOR   PAUSED
# production-daily   Enabled   2025-01-22 12:00:00 +0000 UTC    0 2 * * *   720h0m0s     n/a           <none>     false
```

**Cron expression breakdown:**
```
0 2 * * *
│ │ │ │ │
│ │ │ │ └─── Day of week (0-6, Sunday=0)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)

0 2 * * * = Every day at 2:00 AM UTC
```

---

### Samm 2: Create Weekly Full Cluster Backup

Weekly full cluster backup (Sundays at 3 AM).

```bash
# Create schedule
velero schedule create full-weekly \
  --schedule="0 3 * * 0" \
  --include-namespaces '*' \
  --default-volumes-to-restic \
  --ttl 2016h

# Verify
velero schedule get full-weekly

# Describe (detailed view)
velero schedule describe full-weekly
```

**TTL calculation:**
- 12 weeks × 7 days × 24 hours = 2016 hours

---

### Samm 3: Create Monthly Full Cluster Backup

Monthly backup (1st day of month at 4 AM).

```bash
# Create schedule
velero schedule create full-monthly \
  --schedule="0 4 1 * *" \
  --include-namespaces '*' \
  --default-volumes-to-restic \
  --ttl 8760h

# Verify
velero schedule get
```

**TTL calculation:**
- 12 months × 30 days × 24 hours = 8640 hours (use 8760h for safety)

---

### Samm 4: Test Schedule (Manual Trigger)

Schedules run automatically, but test immediately.

```bash
# Manually trigger production-daily schedule
velero backup create --from-schedule production-daily

# Check backup created
velero backup get

# Should see:
# production-daily-20250122120000
```

**Wait for completion:**

```bash
# Watch backup progress
velero backup describe production-daily-20250122120000

# Wait for Phase: Completed
```

---

### Samm 5: Create Environment-Specific Schedules

Different schedules for dev, staging, production.

**Development (daily, 7 days retention):**

```bash
velero schedule create development-daily \
  --schedule="0 1 * * *" \
  --include-namespaces development \
  --default-volumes-to-restic \
  --ttl 168h  # 7 days
```

**Staging (daily, 14 days retention):**

```bash
velero schedule create staging-daily \
  --schedule="0 2 * * *" \
  --include-namespaces staging \
  --default-volumes-to-restic \
  --ttl 336h  # 14 days
```

**Production (already created):**
- production-daily (30 days)

---

### Samm 6: View All Schedules

```bash
# List all schedules
velero schedule get

# Expected:
# NAME                STATUS    SCHEDULE    TTL
# production-daily    Enabled   0 2 * * *   720h
# staging-daily       Enabled   0 2 * * *   336h
# development-daily   Enabled   0 1 * * *   168h
# full-weekly         Enabled   0 3 * * 0   2016h
# full-monthly        Enabled   0 4 1 * *   8760h
```

**Describe schedule:**

```bash
# Detailed info
velero schedule describe production-daily

# Shows:
# - Schedule: 0 2 * * *
# - TTL: 720h
# - Last Backup: production-daily-20250122020000
# - Number of Backups: 5 (example)
```

---

### Samm 7: Monitor Backup Expiration (TTL)

Old backups automatically deleted when TTL expires.

```bash
# List backups with expiration
velero backup get

# Example output:
# NAME                           STATUS      CREATED                          EXPIRES    STORAGE LOCATION
# production-daily-20250122      Completed   2025-01-22 02:00:00 +0000 UTC    29d        default
# production-daily-20250121      Completed   2025-01-21 02:00:00 +0000 UTC    28d        default
# production-daily-20241223      Completed   2024-12-23 02:00:00 +0000 UTC    1d         default  ← Will be deleted in 1 day
```

**Check expiration manually:**

```bash
velero backup describe production-daily-20241223 | grep Expiration

# Expiration: 2025-01-24 02:00:00 +0000 UTC
```

---

### Samm 8: Pause/Resume Schedules

Temporarily disable schedules (e.g., during maintenance).

```bash
# Pause schedule
velero schedule pause production-daily

# Verify
velero schedule get
# STATUS: Paused

# Resume
velero schedule unpause production-daily

# Verify
velero schedule get
# STATUS: Enabled
```

---

### Samm 9: Monitor Backups with Prometheus (Lab 6)

Create Grafana dashboard for Velero metrics.

**Prometheus queries:**

```promql
# Total backups created
velero_backup_total

# Successful backups (last 24h)
increase(velero_backup_success_total[24h])

# Failed backups (last 24h)
increase(velero_backup_failure_total[24h])

# Backup duration (average over 7 days)
avg_over_time(velero_backup_duration_seconds[7d])

# Backup size (if available via custom metrics)
# Note: Velero doesn't export backup size by default
```

**Grafana Dashboard Panels:**

1. **Backup Success Rate**
   ```promql
   (
     sum(increase(velero_backup_success_total[24h]))
     /
     sum(increase(velero_backup_total[24h]))
   ) * 100
   ```

2. **Backups Per Day**
   ```promql
   increase(velero_backup_total[24h])
   ```

3. **Failed Backups (Alert if > 0)**
   ```promql
   increase(velero_backup_failure_total[24h])
   ```

4. **Average Backup Duration**
   ```promql
   avg(velero_backup_duration_seconds)
   ```

---

### Samm 10: Create Prometheus Alerts

Alert on backup failures (Lab 6 AlertManager).

```yaml
# velero-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: velero-backup-alerts
  namespace: monitoring
spec:
  groups:
    - name: velero
      interval: 30s
      rules:
        # Alert: Backup failed
        - alert: VeleroBackupFailed
          expr: increase(velero_backup_failure_total[1h]) > 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Velero backup failed"
            description: "{{ $value }} Velero backup(s) failed in the last hour"

        # Alert: No backups in 25 hours (daily expected at 2 AM)
        - alert: VeleroNoRecentBackups
          expr: (time() - velero_backup_last_successful_timestamp) > 90000
          for: 1h
          labels:
            severity: warning
          annotations:
            summary: "No Velero backups in 25 hours"
            description: "No successful backups detected. Last backup: {{ $value }} seconds ago"

        # Alert: Backup duration too long (> 2 hours)
        - alert: VeleroBackupSlow
          expr: velero_backup_duration_seconds > 7200
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Velero backup taking too long"
            description: "Backup duration: {{ $value }} seconds (> 2 hours)"
```

**Apply alerts:**

```bash
kubectl apply -f velero-alerts.yaml

# Verify PrometheusRule created
kubectl get prometheusrule -n monitoring velero-backup-alerts
```

**Test alert (simulate failure):**

```bash
# Create backup that will fail (invalid namespace)
velero backup create test-fail-backup --include-namespaces nonexistent

# Wait 5 minutes
# Check Prometheus alerts: http://localhost:9090/alerts
# Should see VeleroBackupFailed alert firing
```

---

### Samm 11: Create Grafana Dashboard

Visualize Velero metrics.

**Import Dashboard:**

1. Open Grafana: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`
2. Open: http://localhost:3000 (admin / prom-operator)
3. Dashboards → Import
4. Use Grafana ID: **11055** (Velero Stats)
5. Or create custom dashboard:

**Custom Dashboard Panels:**

```json
{
  "title": "Velero Backup Status",
  "panels": [
    {
      "title": "Backup Success Rate (24h)",
      "targets": [
        {
          "expr": "(sum(increase(velero_backup_success_total[24h])) / sum(increase(velero_backup_total[24h]))) * 100"
        }
      ],
      "type": "gauge"
    },
    {
      "title": "Backups Per Day",
      "targets": [
        {
          "expr": "increase(velero_backup_total[24h])"
        }
      ],
      "type": "graph"
    },
    {
      "title": "Failed Backups (24h)",
      "targets": [
        {
          "expr": "increase(velero_backup_failure_total[24h])"
        }
      ],
      "type": "stat"
    },
    {
      "title": "Avg Backup Duration",
      "targets": [
        {
          "expr": "avg(velero_backup_duration_seconds)"
        }
      ],
      "type": "stat"
    }
  ]
}
```

---

### Samm 12: Backup Storage Cost Optimization

Monitor and optimize storage usage.

**Check backup sizes:**

```bash
# MinIO: Check bucket size
kubectl exec -n minio deployment/minio -- mc du local/velero-backups

# Example output:
# 5.2GB  velero-backups
```

**Optimize retention:**

- Keep daily backups: 7-30 days (not 90+)
- Incremental backups (if supported by storage backend)
- Compress backups (Velero uses gzip)

**Delete old backups manually (if needed):**

```bash
# List backups older than 60 days
velero backup get | grep "$(date -d '60 days ago' +%Y-%m)"

# Delete specific backup
velero backup delete production-daily-20241101

# Or delete by schedule (all backups from schedule)
velero backup delete --selector velero.io/schedule-name=production-daily
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Daily production backup schedule created (30 days TTL)
- [ ] Weekly full cluster schedule created (12 weeks TTL)
- [ ] Monthly full cluster schedule created (12 months TTL)
- [ ] Environment-specific schedules (dev, staging) created
- [ ] Schedule manually triggered and backup succeeded
- [ ] TTL expiration verified
- [ ] Prometheus monitoring configured (ServiceMonitor)
- [ ] AlertManager alerts created (backup failures)
- [ ] Grafana dashboard created (Velero metrics)
- [ ] Backup storage usage monitored

### Verifitseerimine

```bash
# 1. List all schedules
velero schedule get

# 2. Check recent backups
velero backup get

# 3. Verify TTL
velero backup describe <backup-name> | grep Expiration

# 4. Check Prometheus targets
kubectl get servicemonitor -n velero

# 5. Check alerts
kubectl get prometheusrule -n monitoring velero-backup-alerts

# 6. Test alert (create failing backup)
velero backup create test-fail --include-namespaces nonexistent
```

---

## 🔍 Troubleshooting

### Probleem: Schedule created but no backups

**Sümptomid:**
```bash
velero schedule get
# LAST BACKUP: n/a
```

**Lahendus:**

```bash
# Check schedule details
velero schedule describe production-daily

# Common issues:
# 1. Cron expression wrong (test with https://crontab.guru/)
# 2. Velero pod not running
kubectl get pods -n velero

# 3. Manually trigger to test
velero backup create --from-schedule production-daily
```

---

### Probleem: Old backups not deleted (TTL not working)

**Lahendus:**

```bash
# Check backup expiration
velero backup describe <old-backup> | grep Expiration

# If Expiration is set but backup still exists after TTL:
# - Velero garbage collection runs every 1 hour (default)
# - Wait or restart Velero pod

kubectl delete pod -n velero -l component=velero
```

---

### Probleem: Prometheus not scraping Velero

**Lahendus:**

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n velero

# Check Prometheus ServiceMonitor selector
kubectl get prometheus -n monitoring -o yaml | grep serviceMonitorSelector

# Ensure Velero namespace labeled
kubectl label namespace velero monitoring=prometheus

# Restart Prometheus
kubectl delete pod -n monitoring -l app.kubernetes.io/name=prometheus
```

---

## 📚 Mida Sa Õppisid?

✅ **Automated Backups**
  - Velero Schedule CRD
  - Cron expressions (daily, weekly, monthly)
  - Automatic backup creation

✅ **Retention Policies**
  - TTL (time-to-live)
  - Automatic old backup deletion
  - Storage cost optimization

✅ **Monitoring & Alerting**
  - Prometheus metrics integration
  - Grafana dashboards
  - AlertManager alerts on failures

✅ **Production Best Practices**
  - 3-2-1 backup rule
  - Environment-specific retention
  - Compliance-ready (12 month retention)

---

## 🚀 Järgmised Sammud

**Exercise 4: Disaster Recovery Drill** - Simulate catastrophic failure:
- Full cluster backup
- Simulate disaster (delete production)
- Full cluster restore
- Measure RTO (Recovery Time Objective)
- Document recovery procedures

```bash
cat exercises/04-disaster-recovery-drill.md
```

---

## 💡 Scheduled Backup Best Practices

✅ **Frequency:**
- **Critical apps:** Daily backups (RPO = 24h)
- **Full cluster:** Weekly backups
- **Compliance:** Monthly backups (long-term retention)

✅ **Timing:**
- Schedule during low-traffic hours (2-4 AM)
- Stagger schedules (avoid overlapping backups)
- Consider time zones (UTC vs local)

✅ **Retention:**
- **Development:** 7 days (short, frequent changes)
- **Staging:** 14 days (pre-production testing)
- **Production:** 30 days (regulatory requirements)

✅ **Monitoring:**
- Alert on failures (critical priority)
- Track backup duration (performance degradation)
- Monitor storage usage (cost control)

✅ **Testing:**
- Monthly restore drills (verify backups work)
- Automated restore testing (CI/CD)
- Document restore procedures

---

**Õnnitleme! Automated backups configured! 🚀⏰**

**Kestus:** 60 minutit
**Järgmine:** Exercise 4 - Disaster Recovery Drill
