# Peatükk 23: Troubleshooting ja Debugging 🔍

**Kestus:** 3 tundi
**Eeldused:** Peatükk 22 läbitud
**Eesmärk:** Õppida debugging tehnikaid ja levinud probleemide lahendusi

---

## Sisukord

1. [Ülevaade](#1-ülevaade)
2. [Kubernetes Debugging](#2-kubernetes-debugging)
3. [Docker Debugging](#3-docker-debugging)
4. [PostgreSQL Debugging](#4-postgresql-debugging)
5. [Application Debugging](#5-application-debugging)
6. [Network Debugging](#6-network-debugging)
7. [Resource Issues](#7-resource-issues)
8. [Common Pitfalls](#8-common-pitfalls)

---

## 1. Ülevaade

### 1.1. Debugging Workflow

```
┌─────────────────────────────────────┐
│   1. IDENTIFY THE PROBLEM           │
│   - Error message?                  │
│   - Which component?                │
│   - When did it start?              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   2. GATHER INFORMATION              │
│   - Logs (kubectl logs)             │
│   - Events (kubectl describe)       │
│   - Metrics (Grafana)               │
│   - Status (kubectl get)            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   3. FORM HYPOTHESIS                │
│   - What could cause this?          │
│   - Recent changes?                 │
│   - Similar issues before?          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   4. TEST HYPOTHESIS                │
│   - kubectl exec (interactive)      │
│   - Temporary fixes                 │
│   - Isolated testing                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   5. IMPLEMENT FIX                  │
│   - Code change                     │
│   - Config change                   │
│   - Infrastructure change           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   6. VERIFY FIX                     │
│   - Monitor logs                    │
│   - Check metrics                   │
│   - Test functionality              │
└─────────────────────────────────────┘
```

---

## 2. Kubernetes Debugging

### 2.1. Kubectl Basic Commands

**Pod status:**
```bash
# List pods
kubectl get pods -n production

# Detailed status
kubectl get pods -n production -o wide

# Watch pods
kubectl get pods -n production -w

# All resources
kubectl get all -n production
```

**Pod details:**
```bash
# Describe pod (events!)
kubectl describe pod <pod-name> -n production

# Events:
#   Warning  Failed     Pod failed to start
#   Normal   Pulled     Container image pulled
#   Warning  BackOff    Back-off restarting failed container
```

### 2.2. Logs

**View logs:**
```bash
# Current logs
kubectl logs <pod-name> -n production

# Previous container logs (kui crashis)
kubectl logs <pod-name> -n production --previous

# Follow logs (live)
kubectl logs -f <pod-name> -n production

# Last 50 lines
kubectl logs <pod-name> -n production --tail=50

# Since timestamp
kubectl logs <pod-name> -n production --since=1h

# Multiple pods (label selector)
kubectl logs -l app=backend -n production --tail=20
```

**Multi-container Pod:**
```bash
# Specify container
kubectl logs <pod-name> -c <container-name> -n production

# All containers
kubectl logs <pod-name> -n production --all-containers=true
```

### 2.3. Exec Into Pod

**Interactive shell:**
```bash
# Bash
kubectl exec -it <pod-name> -n production -- /bin/bash

# Sh (alpine)
kubectl exec -it <pod-name> -n production -- /bin/sh

# Node backend-is
kubectl exec -it <pod-name> -n production -- node --version
```

**Single command:**
```bash
# Check environment
kubectl exec <pod-name> -n production -- env

# Test DNS
kubectl exec <pod-name> -n production -- nslookup postgres

# Check files
kubectl exec <pod-name> -n production -- ls -la /app

# Test connectivity
kubectl exec <pod-name> -n production -- curl http://postgres:5432
```

### 2.4. Debug Container

**Ephemeral container (K8s 1.23+):**
```bash
kubectl debug <pod-name> -n production -it --image=busybox
```

**Debug node:**
```bash
# SSH into node's namespace
kubectl debug node/<node-name> -it --image=ubuntu
```

### 2.5. Port Forward

**Access service locally:**
```bash
# Forward pod port
kubectl port-forward <pod-name> 3000:3000 -n production

# Forward service
kubectl port-forward service/backend 3000:3000 -n production

# Specify local port
kubectl port-forward service/backend 8080:3000 -n production

# Access: http://localhost:8080
```

### 2.6. Copy Files

**Copy from Pod:**
```bash
kubectl cp production/<pod-name>:/app/logs/error.log ./error.log
```

**Copy to Pod:**
```bash
kubectl cp ./fix.js production/<pod-name>:/app/fix.js
```

### 2.7. Common Pod Issues

**ImagePullBackOff:**
```bash
kubectl describe pod <pod-name> -n production

# Events:
#   Failed to pull image "localhost:5000/backend:1.0": connection refused

# Fix:
# 1. Check image exists: docker images | grep backend
# 2. Check registry running: docker ps | grep registry
# 3. Check image name typo
```

**CrashLoopBackOff:**
```bash
kubectl logs <pod-name> -n production --previous

# Common causes:
# - Application crash on startup
# - Missing environment variables
# - Database connection failed
# - Health check failing too early
```

**Pending:**
```bash
kubectl describe pod <pod-name> -n production

# Events:
#   FailedScheduling: Insufficient cpu

# Fix:
# 1. Reduce resource requests
# 2. Add more nodes
# 3. Remove resource limits temporarily
```

---

## 3. Docker Debugging

### 3.1. Container Inspection

**Running containers:**
```bash
docker ps

# All containers (including stopped)
docker ps -a

# Filter
docker ps --filter "name=backend"
```

**Inspect container:**
```bash
docker inspect <container-id>

# Specific field
docker inspect <container-id> | jq '.[0].State'
docker inspect <container-id> | jq '.[0].NetworkSettings.IPAddress'
```

### 3.2. Logs

```bash
# View logs
docker logs <container-id>

# Follow
docker logs -f <container-id>

# Tail
docker logs --tail 50 <container-id>

# Timestamps
docker logs -t <container-id>
```

### 3.3. Exec

```bash
# Bash
docker exec -it <container-id> /bin/bash

# Command
docker exec <container-id> env
docker exec <container-id> ps aux
```

### 3.4. Stats

```bash
# Resource usage
docker stats

# Single container
docker stats <container-id>
```

### 3.5. Common Docker Issues

**Container exits immediately:**
```bash
docker logs <container-id>

# Reasons:
# - CMD/ENTRYPOINT error
# - Application crash
# - Missing dependencies
```

**Port mapping not working:**
```bash
docker ps  # Check ports column
docker port <container-id>

# Test
curl http://localhost:3000
```

**Volume permission denied:**
```bash
docker exec <container-id> ls -la /data

# Fix: chown in Dockerfile or initContainer
```

---

## 4. PostgreSQL Debugging

### 4.1. Connection Issues

**Test connection from backend Pod:**
```bash
kubectl exec -it <backend-pod> -n production -- sh

# Inside Pod
apk add postgresql-client

psql -h postgres -U appuser -d appdb
# If fails:
#   could not connect → check service name, port
#   password authentication failed → check credentials
#   database "appdb" does not exist → check DB_NAME
```

**Check PostgreSQL logs:**
```bash
# Kubernetes StatefulSet
kubectl logs postgres-0 -n production

# Docker container
docker logs <postgres-container>

# Väline PostgreSQL
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

**Common connection errors:**
```
FATAL:  password authentication failed for user "appuser"
→ Check Secret: kubectl get secret postgres-secret -o yaml

FATAL:  database "appdb" does not exist
→ Check initialization: kubectl exec postgres-0 -- psql -U postgres -c "\l"

could not connect to server: Connection refused
→ Check service: kubectl get service postgres -n production
```

### 4.2. Slow Queries

**Enable slow query log (PostgreSQL):**
```sql
-- Connect to PostgreSQL
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- 1000ms = 1s
SELECT pg_reload_conf();
```

**View slow queries:**
```bash
kubectl logs postgres-0 -n production | grep "duration:"

# duration: 2534.123 ms  statement: SELECT * FROM users WHERE ...
```

**Analyze query:**
```sql
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

# Seq Scan on users  (cost=0.00..25.50 rows=1) (actual time=12.345..15.678 rows=1)
# → Missing index!

CREATE INDEX idx_users_email ON users(email);
```

### 4.3. pg_stat_statements

**Enable:**
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

**Top slow queries:**
```sql
SELECT
  query,
  calls,
  mean_exec_time,
  max_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### 4.4. Connection Pool Exhaustion

**Check active connections:**
```sql
SELECT count(*) FROM pg_stat_activity;

-- Max connections
SHOW max_connections;  -- default 100

-- Kill idle connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle'
  AND state_change < NOW() - INTERVAL '10 minutes';
```

---

## 5. Application Debugging

### 5.1. Node.js Debugging

**Enable debug logging:**
```javascript
// src/index.js
const DEBUG = process.env.DEBUG === 'true';

if (DEBUG) {
  console.log('Debug mode enabled');
}

app.use((req, res, next) => {
  if (DEBUG) {
    console.log(`${req.method} ${req.path}`, req.body);
  }
  next();
});
```

**Deploy with DEBUG:**
```yaml
env:
- name: DEBUG
  value: "true"
```

### 5.2. Node.js Debugger (Chrome DevTools)

**Backend-is:**
```javascript
// package.json
{
  "scripts": {
    "debug": "node --inspect=0.0.0.0:9229 src/index.js"
  }
}
```

**Kubernetes:**
```yaml
spec:
  containers:
  - name: backend
    command: ["node", "--inspect=0.0.0.0:9229", "src/index.js"]
    ports:
    - containerPort: 9229  # Debug port
```

**Port-forward:**
```bash
kubectl port-forward <pod-name> 9229:9229 -n production
```

**Chrome DevTools:**
1. Ava Chrome: `chrome://inspect`
2. Configure: `localhost:9229`
3. Inspect → breakpoints, console, etc.

### 5.3. Error Tracking

**Uncaught exceptions:**
```javascript
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  // Log to monitoring service (Sentry)
  process.exit(1);  // Restart pod
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
```

**Express error handler:**
```javascript
app.use((err, req, res, next) => {
  console.error('Error:', err);

  res.status(err.status || 500).json({
    error: {
      message: err.message,
      stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
    }
  });
});
```

---

## 6. Network Debugging

### 6.1. DNS Resolution

**Test DNS:**
```bash
# Inside Pod
kubectl exec -it <pod-name> -n production -- sh

nslookup postgres
# Name:    postgres.production.svc.cluster.local
# Address: 10.43.123.45

nslookup google.com
```

**DNS not working:**
```bash
# Check kube-dns/coredns
kubectl get pods -n kube-system -l k8s-app=kube-dns

# View logs
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### 6.2. Service Connectivity

**Test service:**
```bash
# From debug pod
kubectl run -it --rm debug --image=busybox --restart=Never -n production -- sh

# Inside debug pod
wget -O- http://backend:3000/health
# OK

wget -O- http://postgres:5432
# wget: can't connect (this is expected, postgres doesn't speak HTTP)

# Test TCP
nc -zv postgres 5432
# postgres (10.43.123.45:5432) open  ← SUCCESS
```

**Check service endpoints:**
```bash
kubectl get endpoints backend -n production

# NAME      ENDPOINTS
# backend   10.42.0.12:3000,10.42.0.13:3000,10.42.0.14:3000

# If no endpoints → selector mismatch
kubectl get service backend -n production -o yaml | grep selector
kubectl get pods -n production --show-labels
```

### 6.3. Network Policies

**Test if blocked:**
```bash
# From frontend pod
kubectl exec -it <frontend-pod> -n production -- sh

wget -O- --timeout=5 http://postgres:5432
# wget: download timed out  ← Network Policy blocking
```

**Check network policies:**
```bash
kubectl get networkpolicy -n production

kubectl describe networkpolicy <policy-name> -n production
```

### 6.4. Ingress Issues

**Check Ingress:**
```bash
kubectl get ingress -n production

kubectl describe ingress app-ingress -n production
```

**Traefik logs:**
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=traefik -f
```

**Test from outside:**
```bash
curl -v http://93.127.213.242/
curl -v http://93.127.213.242/api/health
```

---

## 7. Resource Issues

### 7.1. CPU Throttling

**Symptoms:**
- Slow response times
- Timeouts

**Check:**
```bash
kubectl top pods -n production

# NAME                       CPU(cores)   MEMORY(bytes)
# backend-xxx                498m         256Mi
#                            ↑ near 500m limit → throttled
```

**Fix:**
```yaml
resources:
  limits:
    cpu: "1000m"  # Increase limit
```

### 7.2. OOM (Out of Memory)

**Symptoms:**
```bash
kubectl get pods -n production

# NAME                       READY   STATUS      RESTARTS
# backend-xxx                0/1     OOMKilled   3
```

**Check:**
```bash
kubectl describe pod backend-xxx -n production

# Last State: Terminated
#   Reason: OOMKilled
#   Exit Code: 137
```

**Fix:**
```yaml
resources:
  limits:
    memory: "1Gi"  # Increase limit
```

**Find memory leak:**
```bash
# Heap snapshot
kubectl exec <pod-name> -n production -- node -e "require('v8').writeHeapSnapshot('./heap.heapsnapshot')"

kubectl cp production/<pod-name>:/app/heap.heapsnapshot ./heap.heapsnapshot

# Analyze in Chrome DevTools → Memory → Load
```

### 7.3. Disk Space

**Check disk:**
```bash
kubectl exec <pod-name> -n production -- df -h

# /dev/sda1       96G   89G   2.1G  98% /
#                                  ↑ FULL!
```

**Find large files:**
```bash
kubectl exec <pod-name> -n production -- du -sh /* | sort -h

# Clean logs
kubectl exec <pod-name> -n production -- find /var/log -name "*.log" -mtime +7 -delete
```

---

## 8. Common Pitfalls

### 8.1. Environment Variables

**Problem:** App can't connect to DB

**Debug:**
```bash
kubectl exec <pod-name> -n production -- env | grep DB

# DB_HOST=
# DB_PORT=
# ↑ Empty values!
```

**Fix:**
```yaml
env:
- name: DB_HOST
  valueFrom:
    configMapKeyRef:
      name: backend-config  # ← Check name
      key: DB_HOST          # ← Check key exists
```

### 8.2. Image Tag

**Problem:** Changes not deployed

**Debug:**
```bash
kubectl describe pod <pod-name> -n production | grep Image:

# Image: localhost:5000/backend:latest
#        ↑ using cached "latest"
```

**Fix:** Use specific tags
```bash
docker build -t localhost:5000/backend:v1.2.3 .
docker push localhost:5000/backend:v1.2.3

kubectl set image deployment/backend backend=localhost:5000/backend:v1.2.3 -n production
```

### 8.3. ConfigMap/Secret Not Updated

**Problem:** Config changes not applied

**Reason:** Pods don't auto-reload ConfigMap/Secret

**Fix:**
```bash
# Rollout restart
kubectl rollout restart deployment/backend -n production

# OR add annotation to trigger update
kubectl patch deployment backend -n production -p \
  "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"restarted-at\":\"$(date +%s)\"}}}}}"
```

### 8.4. Liveness Probe Killing Pod

**Problem:** Pod keeps restarting

**Debug:**
```bash
kubectl describe pod <pod-name> -n production

# Events:
#   Liveness probe failed: HTTP probe failed with statuscode: 503
#   Killing container with id backend
```

**Fix:**
```yaml
livenessProbe:
  initialDelaySeconds: 60  # ← Give more time to start
  periodSeconds: 30        # ← Less frequent checks
  failureThreshold: 5      # ← More tolerance
```

### 8.5. Service Selector Mismatch

**Problem:** Service has no endpoints

**Debug:**
```bash
kubectl get endpoints backend -n production
# NAME      ENDPOINTS
# backend   <none>  ← NO ENDPOINTS!

kubectl get service backend -n production -o yaml | grep -A2 selector
# selector:
#   app: backend

kubectl get pods -n production --show-labels
# NAME                       LABELS
# backend-xxx                app=api  ← MISMATCH! (app=api vs app=backend)
```

**Fix:** Match labels
```yaml
# Deployment
spec:
  template:
    metadata:
      labels:
        app: backend  # ← Must match Service selector

# Service
spec:
  selector:
    app: backend
```

---

## Kokkuvõte

Selles peatükis õppisid:

✅ **Kubernetes Debugging:**
- kubectl logs, describe, exec
- Port-forward
- Debug containers
- Common Pod issues

✅ **Docker Debugging:**
- Inspect, logs, stats
- Container troubleshooting

✅ **PostgreSQL Debugging:**
- Connection issues
- Slow query log
- pg_stat_statements
- Connection pooling

✅ **Application Debugging:**
- Node.js debugging
- Chrome DevTools
- Error tracking

✅ **Network Debugging:**
- DNS resolution
- Service connectivity
- Network policies
- Ingress troubleshooting

✅ **Resource Issues:**
- CPU throttling
- OOM errors
- Disk space

✅ **Common Pitfalls:**
- Environment variables
- Image tags
- ConfigMap updates
- Liveness probes
- Service selectors

---

## Järgmine Samm

**Peatükk 24: Production Readiness**

**Ressursid:**
- Kubernetes Troubleshooting: https://kubernetes.io/docs/tasks/debug/
- kubectl Cheat Sheet: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

---

**VPS:** kirjakast @ 93.127.213.242
**Kasutaja:** janek
**Debug:** kubectl, logs, exec

Edu! 🚀
