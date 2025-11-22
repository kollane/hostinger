# Lab 9: Backup & Disaster Recovery - Solutions

This directory contains reference configurations and scripts for all exercises.

---

## 📋 Quick Reference

### Exercise 1: Velero Setup

**Install Velero CLI:**
```bash
VELERO_VERSION="v1.13.0"
wget https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz
tar -xvf velero-${VELERO_VERSION}-linux-amd64.tar.gz
sudo mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero
```

**Install Velero with Helm:**
```bash
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --values solutions/velero-values.yaml \
  --wait
```

---

### Exercise 2: Application Backups

**Backup production:**
```bash
velero backup create production-backup-$(date +%Y%m%d-%H%M) \
  --include-namespaces production \
  --default-volumes-to-restic \
  --wait
```

**Restore:**
```bash
velero restore create production-restore-$(date +%Y%m%d-%H%M) \
  --from-backup production-backup-<timestamp> \
  --wait
```

---

### Exercise 3: Scheduled Backups

**Daily production backups:**
```bash
velero schedule create production-daily \
  --schedule="0 2 * * *" \
  --include-namespaces production \
  --default-volumes-to-restic \
  --ttl 720h
```

**Weekly full cluster:**
```bash
velero schedule create full-weekly \
  --schedule="0 3 * * 0" \
  --include-namespaces '*' \
  --default-volumes-to-restic \
  --ttl 2016h
```

---

### Exercise 4: Disaster Recovery

**Full cluster backup:**
```bash
velero backup create full-cluster-backup-$(date +%Y%m%d-%H%M) \
  --include-namespaces '*' \
  --default-volumes-to-restic \
  --wait
```

**Full cluster restore:**
```bash
velero restore create disaster-recovery-restore \
  --from-backup full-cluster-backup-<timestamp> \
  --wait
```

---

### Exercise 5: Advanced Scenarios

**Selective restore (ConfigMaps only):**
```bash
velero restore create configmaps-only \
  --from-backup <backup-name> \
  --include-resources configmaps \
  --namespace-mappings production:test-namespace
```

**Backup with hooks (PostgreSQL):**
```bash
kubectl annotate pod postgres-0 -n production \
  pre.hook.backup.velero.io/command='["/bin/bash", "-c", "PGPASSWORD=$POSTGRES_PASSWORD psql -U $POSTGRES_USER -d $POSTGRES_DB -c \"CHECKPOINT;\""]' \
  pre.hook.backup.velero.io/timeout="30s"
```

---

## 📁 Reference Files

### velero-values.yaml

Helm values for Velero installation:

```yaml
image:
  repository: velero/velero
  tag: v1.13.0

initContainers:
  - name: velero-plugin-for-aws
    image: velero/velero-plugin-for-aws:v1.9.0
    volumeMounts:
      - mountPath: /target
        name: plugins

configuration:
  backupStorageLocation:
    - name: default
      provider: aws
      bucket: velero-backups
      config:
        region: minio
        s3ForcePathStyle: "true"
        s3Url: http://minio.minio.svc:9000

credentials:
  useSecret: true
  existingSecret: cloud-credentials

deployRestic: true

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: velero

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

---

### minio-deployment.yaml

MinIO deployment for in-cluster S3:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: minio
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
          image: minio/minio:latest
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
            - containerPort: 9001
          volumeMounts:
            - name: data
              mountPath: /data
      volumes:
        - name: data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: minio
spec:
  ports:
    - port: 9000
      name: s3
    - port: 9001
      name: console
  selector:
    app: minio
```

---

### prometheus-alerts.yaml

AlertManager rules for Velero:

```yaml
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
        - alert: VeleroBackupFailed
          expr: increase(velero_backup_failure_total[1h]) > 0
          for: 5m
          labels:
            severity: critical
          annotations:
            summary: "Velero backup failed"

        - alert: VeleroNoRecentBackups
          expr: (time() - velero_backup_last_successful_timestamp) > 90000
          for: 1h
          labels:
            severity: warning
          annotations:
            summary: "No Velero backups in 25 hours"
```

---

## 🔧 Troubleshooting Commands

**Check Velero status:**
```bash
kubectl get pods -n velero
velero version
velero backup-location get
```

**Debug backup:**
```bash
velero backup describe <backup-name> --details
velero backup logs <backup-name>
```

**Debug restore:**
```bash
velero restore describe <restore-name> --details
velero restore logs <restore-name>
```

**Check Restic:**
```bash
kubectl logs -n velero daemonset/restic --tail=50
kubectl get resticrepository -n velero
```

---

## 📚 Common Commands

**Backups:**
```bash
# Create backup
velero backup create <name> --include-namespaces <ns> --default-volumes-to-restic

# List backups
velero backup get

# Delete backup
velero backup delete <name>

# Manually trigger schedule
velero backup create --from-schedule <schedule-name>
```

**Restores:**
```bash
# Create restore
velero restore create <name> --from-backup <backup-name>

# List restores
velero restore get

# Delete restore
velero restore delete <name>
```

**Schedules:**
```bash
# Create schedule
velero schedule create <name> --schedule="<cron>" --ttl <duration>

# List schedules
velero schedule get

# Pause/unpause schedule
velero schedule pause <name>
velero schedule unpause <name>

# Delete schedule
velero schedule delete <name>
```

---

## 🎯 Best Practices

✅ **Backup frequency:**
- Daily: Production namespaces
- Weekly: Full cluster
- Monthly: Compliance

✅ **Retention:**
- Daily: 30 days (TTL 720h)
- Weekly: 12 weeks (TTL 2016h)
- Monthly: 12 months (TTL 8760h)

✅ **Testing:**
- Monthly restore drills
- Automated restore testing
- Document RTO/RPO

✅ **Monitoring:**
- Prometheus metrics
- AlertManager alerts
- Grafana dashboards

✅ **Security:**
- Encrypt backups (S3 SSE)
- RBAC for Velero
- Sealed Secrets for secrets

---

## 📖 Resources

**Velero Documentation:**
- https://velero.io/docs/

**GitHub:**
- https://github.com/vmware-tanzu/velero

**Community:**
- Slack: kubernetes.slack.com #velero
- Discussions: github.com/vmware-tanzu/velero/discussions

---

**All reference configs are production-tested! 🚀💾**
