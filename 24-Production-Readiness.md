# Peatükk 24: Production Readiness ✅

**Kestus:** 3 tundi
**Eeldused:** Peatükid 1-23 läbitud
**Eesmärk:** Production readiness checklist ja best practices

---

## Sisukord

1. [Production Readiness Checklist](#1-production-readiness-checklist)
2. [High Availability](#2-high-availability)
3. [Backup ja Disaster Recovery](#3-backup-ja-disaster-recovery)
4. [Performance Optimization](#4-performance-optimization)
5. [Monitoring ja Alerting](#5-monitoring-ja-alerting)
6. [Documentation](#6-documentation)
7. [Deployment Checklist](#7-deployment-checklist)

---

## 1. Production Readiness Checklist

### 1.1. Infrastructure

```
✅ INFRASTRUCTURE
│
├── ✅ VPS/Cloud
│   ├── [ ] Adequate resources (CPU, RAM, disk)
│   ├── [ ] Backup/snapshot policy
│   ├── [ ] Monitoring agent installed
│   └── [ ] SSH key-based auth (no password)
│
├── ✅ Network
│   ├── [ ] Firewall configured (ufw)
│   ├── [ ] fail2ban enabled
│   ├── [ ] DDoS protection
│   └── [ ] DNS configured
│
├── ✅ Kubernetes
│   ├── [ ] K3s/K8s version supported
│   ├── [ ] Node monitoring (node-exporter)
│   ├── [ ] Cluster backup (etcd)
│   └── [ ] kubectl access restricted
│
└── ✅ TLS/SSL
    ├── [ ] cert-manager installed
    ├── [ ] Let's Encrypt certificates
    ├── [ ] Auto-renewal working
    └── [ ] HTTPS redirect enabled
```

### 1.2. Application

```
✅ APPLICATION
│
├── ✅ Backend
│   ├── [ ] Environment variables from Secrets
│   ├── [ ] Health check endpoints (/health, /ready)
│   ├── [ ] Structured logging (JSON)
│   ├── [ ] Error handling (uncaughtException)
│   ├── [ ] Metrics endpoint (/metrics)
│   ├── [ ] CORS configured
│   ├── [ ] Rate limiting
│   ├── [ ] Input validation
│   └── [ ] SQL injection prevention
│
├── ✅ Frontend
│   ├── [ ] Security headers (CSP, HSTS, X-Frame-Options)
│   ├── [ ] XSS prevention
│   ├── [ ] Gzip compression
│   ├── [ ] Cache headers
│   └── [ ] Minified/bundled assets
│
└── ✅ Database
    ├── [ ] Backups automated
    ├── [ ] Backup restoration tested
    ├── [ ] Connection pooling
    ├── [ ] Indexes optimized
    ├── [ ] Slow query log enabled
    └── [ ] Password rotation policy
```

### 1.3. Security

```
✅ SECURITY
│
├── ✅ Container Security
│   ├── [ ] Images scanned (Trivy)
│   ├── [ ] Non-root user
│   ├── [ ] Read-only filesystem
│   ├── [ ] Capabilities dropped
│   └── [ ] securityContext configured
│
├── ✅ Network Security
│   ├── [ ] Network Policies applied
│   ├── [ ] TLS everywhere
│   ├── [ ] No plaintext secrets
│   └── [ ] Pod Security Standards (restricted)
│
├── ✅ Secrets Management
│   ├── [ ] Kubernetes Secrets (base64)
│   ├── [ ] Sealed Secrets (encrypted)
│   ├── [ ] External Secrets (Vault) [optional]
│   └── [ ] Regular rotation
│
└── ✅ Access Control
    ├── [ ] RBAC configured
    ├── [ ] Service accounts with minimal permissions
    ├── [ ] No default service account usage
    └── [ ] Audit logging enabled
```

### 1.4. Observability

```
✅ OBSERVABILITY
│
├── ✅ Monitoring
│   ├── [ ] Prometheus collecting metrics
│   ├── [ ] Grafana dashboards created
│   ├── [ ] Node metrics (node-exporter)
│   ├── [ ] Pod metrics (kube-state-metrics)
│   ├── [ ] Application metrics (prom-client)
│   └── [ ] PostgreSQL metrics (postgres-exporter)
│
├── ✅ Logging
│   ├── [ ] Loki aggregating logs
│   ├── [ ] Promtail forwarding logs
│   ├── [ ] Structured logging (JSON)
│   ├── [ ] Log retention policy
│   └── [ ] Log search working
│
└── ✅ Alerting
    ├── [ ] PrometheusRules defined
    ├── [ ] AlertManager configured
    ├── [ ] Notification channel (Slack/email)
    ├── [ ] Critical alerts tested
    └── [ ] On-call rotation defined
```

### 1.5. CI/CD

```
✅ CI/CD
│
├── ✅ Continuous Integration
│   ├── [ ] Automated tests on PR
│   ├── [ ] Linting on PR
│   ├── [ ] Security scanning on PR
│   └── [ ] Code coverage tracked
│
├── ✅ Continuous Deployment
│   ├── [ ] Automated build on merge
│   ├── [ ] Image tagging strategy
│   ├── [ ] Automated deployment
│   ├── [ ] Rollback procedure tested
│   └── [ ] Blue/green or canary deployment
│
└── ✅ Environments
    ├── [ ] Dev environment
    ├── [ ] Staging environment (production-like)
    ├── [ ] Production environment
    └── [ ] Environment parity maintained
```

---

## 2. High Availability

### 2.1. Pod Replicas

**Minimum 2 replicas for stateless apps:**
```yaml
spec:
  replicas: 3  # ✅ HA (tolerates 1 node/pod failure)
```

### 2.2. PodDisruptionBudget

**Ensure minimum pods during updates:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: backend-pdb
  namespace: production
spec:
  minAvailable: 2  # Minimaalne 2 podi peab alati töötama
  selector:
    matchLabels:
      app: backend
```

### 2.3. Anti-Affinity

**Distribute pods across nodes:**
```yaml
spec:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - backend
          topologyKey: kubernetes.io/hostname
```

### 2.4. Health Checks

**Liveness and Readiness probes:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 2
```

---

## 3. Backup ja Disaster Recovery

### 3.1. PostgreSQL Backups

**PRIMAARNE: StatefulSet PostgreSQL CronJob**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: production
spec:
  schedule: "0 2 * * *"  # Daily 2 AM
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
              pg_dump -h postgres -U appuser appdb > $BACKUP_FILE
              gzip $BACKUP_FILE

              # Keep only last 7 days
              find /backup -name "*.sql.gz" -mtime +7 -delete
            env:
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
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-backup-pvc
  namespace: production
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
```

**ALTERNATIIV: Väline PostgreSQL**

```bash
# VPS-is crontab
crontab -e

# Add:
0 2 * * * pg_dump -h localhost -U appuser appdb | gzip > /backups/backup-$(date +\%Y\%m\%d).sql.gz

# Retention (keep 7 days)
0 3 * * * find /backups -name "*.sql.gz" -mtime +7 -delete
```

### 3.2. Backup Restoration Test

**Test restore monthly:**
```bash
# Extract backup
gunzip backup-20250115.sql.gz

# Restore to test database
psql -h localhost -U appuser testdb < backup-20250115.sql

# Verify
psql -h localhost -U appuser testdb -c "SELECT COUNT(*) FROM users;"
```

### 3.3. Kubernetes State Backup

**Backup manifests:**
```bash
# Export all resources
kubectl get all -n production -o yaml > production-backup.yaml

# Backup specific resources
kubectl get configmap,secret,pvc,service,deployment,statefulset -n production -o yaml > production-resources.yaml

# Store in git or S3
```

**etcd backup (K3s):**
```bash
# K3s stores etcd snapshots automatically
ls -la /var/lib/rancher/k3s/server/db/snapshots/

# Manual snapshot
k3s etcd-snapshot save --name manual-backup-$(date +%Y%m%d)
```

---

## 4. Performance Optimization

### 4.1. Resource Limits

**Set appropriate limits:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

**Monitor and adjust:**
```bash
kubectl top pods -n production

# If consistently near limit → increase
# If far below request → decrease
```

### 4.2. HPA (HorizontalPodAutoscaler)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### 4.3. Database Optimization

**Indexes:**
```sql
-- Find missing indexes
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;

-- Create index on frequently queried columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

**Connection pooling (PgBouncer):**
```yaml
# pgbouncer.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgbouncer
  namespace: production
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: pgbouncer
        image: pgbouncer/pgbouncer:latest
        ports:
        - containerPort: 5432
        env:
        - name: DATABASES_HOST
          value: postgres
        - name: DATABASES_PORT
          value: "5432"
        - name: DATABASES_DBNAME
          value: appdb
        - name: PGBOUNCER_POOL_MODE
          value: transaction
        - name: PGBOUNCER_MAX_CLIENT_CONN
          value: "1000"
        - name: PGBOUNCER_DEFAULT_POOL_SIZE
          value: "25"
```

**Backend connects to pgbouncer instead of postgres:**
```yaml
env:
- name: DB_HOST
  value: pgbouncer  # Instead of postgres
```

### 4.4. Caching (Redis)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: production
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-data
          mountPath: /data
      volumes:
      - name: redis-data
        persistentVolumeClaim:
          claimName: redis-pvc
```

**Backend Redis client:**
```javascript
const redis = require('redis');
const client = redis.createClient({
  url: 'redis://redis:6379'
});

// Cache user data
app.get('/api/users/:id', async (req, res) => {
  const cached = await client.get(`user:${req.params.id}`);
  if (cached) {
    return res.json(JSON.parse(cached));
  }

  const user = await pool.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
  await client.setEx(`user:${req.params.id}`, 3600, JSON.stringify(user.rows[0]));
  res.json(user.rows[0]);
});
```

---

## 5. Monitoring ja Alerting

### 5.1. Key Metrics to Monitor

**Application:**
- HTTP request rate
- HTTP error rate (5xx)
- Response time (p50, p95, p99)
- Active connections

**Infrastructure:**
- CPU usage
- Memory usage
- Disk usage
- Network I/O

**Database:**
- Connection count
- Query duration
- Cache hit ratio
- Database size

### 5.2. Critical Alerts

```yaml
# prometheus-critical-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: critical-alerts
  namespace: production
spec:
  groups:
  - name: critical
    interval: 30s
    rules:
    # Application Down
    - alert: ApplicationDown
      expr: up{job="backend"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Application is down"

    # High Error Rate
    - alert: HighErrorRate
      expr: rate(http_requests_total{status_code=~"5..",job="backend"}[5m]) > 0.1
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate (>10%)"

    # Database Down
    - alert: DatabaseDown
      expr: pg_up == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "PostgreSQL is down"

    # Disk Almost Full
    - alert: DiskAlmostFull
      expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.1
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Disk usage >90%"
```

---

## 6. Documentation

### 6.1. Runbook

**Create runbook for common issues:**

**File:** `docs/runbook.md`

```markdown
# Production Runbook

## Application Down

**Symptoms:** Health check failing, 502/503 errors

**Steps:**
1. Check pods: `kubectl get pods -n production`
2. View logs: `kubectl logs -l app=backend -n production --tail=50`
3. Describe pod: `kubectl describe pod <name> -n production`
4. If CrashLoopBackOff:
   - Check recent deployments
   - Rollback: `kubectl rollout undo deployment/backend -n production`

## Database Connection Failed

**Symptoms:** Backend logs show "connection refused"

**Steps:**
1. Check PostgreSQL pod: `kubectl get pod postgres-0 -n production`
2. Check service: `kubectl get service postgres -n production`
3. Test connection from backend pod:
   ```bash
   kubectl exec -it <backend-pod> -n production -- sh
   nc -zv postgres 5432
   ```
4. Check credentials: `kubectl get secret postgres-secret -o yaml`

## High Memory Usage

**Symptoms:** OOMKilled, slow response

**Steps:**
1. Check memory: `kubectl top pods -n production`
2. Identify leak:
   - Heap snapshot
   - Analyze in Chrome DevTools
3. Temporary fix: Increase memory limit
4. Permanent fix: Fix code, deploy
```

### 6.2. Architecture Diagram

**Document current architecture:**

```markdown
# Architecture

## Production Stack

```
Internet → Traefik Ingress → Frontend/Backend → PostgreSQL
                                              ↓
                                            Redis (cache)
```

## Services

- **Frontend:** Nginx serving static files
- **Backend:** Node.js 18 + Express API
- **Database:** PostgreSQL 16 StatefulSet
- **Cache:** Redis 7
- **Monitoring:** Prometheus + Grafana
- **Logging:** Loki + Promtail
```

### 6.3. Deployment Procedure

**Document deployment steps:**

```markdown
# Deployment Procedure

## Prerequisites
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Staging tested

## Steps

1. **Build image:**
   ```bash
   docker build -t localhost:5000/backend:v1.2.3 .
   docker push localhost:5000/backend:v1.2.3
   ```

2. **Update manifest:**
   ```bash
   kubectl set image deployment/backend backend=localhost:5000/backend:v1.2.3 -n production --record
   ```

3. **Monitor rollout:**
   ```bash
   kubectl rollout status deployment/backend -n production
   ```

4. **Verify:**
   ```bash
   curl https://example.com/api/health
   ```

5. **If issues, rollback:**
   ```bash
   kubectl rollout undo deployment/backend -n production
   ```
```

---

## 7. Deployment Checklist

### 7.1. Pre-Deployment

```
✅ PRE-DEPLOYMENT
│
├── [ ] All tests passing
├── [ ] Code review approved
├── [ ] Security scan passed (Trivy)
├── [ ] Staging deployment successful
├── [ ] Database migrations prepared (if any)
├── [ ] Rollback plan documented
├── [ ] Team notified (deployment window)
└── [ ] On-call engineer available
```

### 7.2. Deployment

```
✅ DEPLOYMENT
│
├── [ ] Create backup (database, configs)
├── [ ] Run database migrations (if needed)
├── [ ] Deploy new version
├── [ ] Monitor rollout
├── [ ] Verify health checks
├── [ ] Smoke test critical paths
└── [ ] Monitor metrics/logs for 15 minutes
```

### 7.3. Post-Deployment

```
✅ POST-DEPLOYMENT
│
├── [ ] All health checks passing
├── [ ] Error rate normal
├── [ ] Response time normal
├── [ ] No unexpected alerts
├── [ ] Update changelog/release notes
└── [ ] Mark deployment complete
```

### 7.4. Rollback (if needed)

```
✅ ROLLBACK
│
├── [ ] Identify issue
├── [ ] Execute rollback:
│   └── kubectl rollout undo deployment/backend -n production
├── [ ] Verify rollback successful
├── [ ] Post-mortem meeting scheduled
└── [ ] Document lessons learned
```

---

## Kokkuvõte

Selles peatükis õppisid:

✅ **Production Readiness Checklist:**
- Infrastructure
- Application
- Security
- Observability
- CI/CD

✅ **High Availability:**
- Multiple replicas
- PodDisruptionBudget
- Anti-affinity
- Health checks

✅ **Backup & DR:**
- PostgreSQL backups (mõlemad variandid)
- Restoration testing
- Kubernetes state backup

✅ **Performance:**
- Resource limits
- HPA autoscaling
- Database optimization
- Caching (Redis)

✅ **Monitoring:**
- Key metrics
- Critical alerts
- Runbook

✅ **Documentation:**
- Architecture diagram
- Deployment procedure
- Troubleshooting guide

---

## Järgmine Samm

**Peatükk 25: Kokkuvõte ja Järgmised Sammud**

**Production Deployment Ready! 🎉**

---

**VPS:** kirjakast @ 93.127.213.242
**Kasutaja:** janek
**Status:** Production Ready

Edu! 🚀
