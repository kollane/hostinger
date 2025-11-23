# Peatükk 20: Logging ja Log Aggregation (Loki)

**Kestus:** 4 tundi
**Eeldused:** Peatükk 18-19 (Prometheus, Grafana), Peatükk 9-13 (Kubernetes core)
**Eesmärk:** Mõista log aggregation arhitektuuri ja Loki integration Prometheus/Grafana'ga

---

## Õpieesmärgid

- Structured logging fundamentals
- Loki arhitektuur (label-based vs full-text indexing)
- Promtail log collection (DaemonSet)
- LogQL queries (Loki query language)
- Grafana integration (logs + metrics in one UI)
- Log retention ja storage management
- Loki vs Graylog vs ELK

---

## 20.1 Logging Fundamentals

### Miks Logid on Olulised?

**Three pillars of observability:**

```
Metrics (Prometheus):
  - WHAT is happening? (CPU 80%, 500 req/s)
  - Numeric time-series data
  - Efficient storage (aggregated)

Logs (Loki):
  - WHY is it happening? (Error: DB connection timeout)
  - Text event records
  - Debugging, troubleshooting

Traces (Jaeger):
  - WHERE in the system? (Request took 5s in payment service)
  - Distributed tracing
  - Microservices bottleneck discovery
```

**When to use logs:**
- ✅ Debugging errors (stack traces, error messages)
- ✅ Audit trail (who did what, when?)
- ✅ Security analysis (failed logins, suspicious activity)
- ✅ Compliance (GDPR, PCI-DSS logging requirements)
- ❌ High-cardinality time-series (use Prometheus metrics instead)

---

### Unstructured vs Structured Logs

**❌ Unstructured (plain text):**

```
2025-01-23 10:15:32 User john logged in from 192.168.1.1
2025-01-23 10:15:45 Error connecting to database: timeout
```

**Probleemid:**
- Hard to parse (regex patterns brittle)
- No consistent format
- Difficult to filter and aggregate

---

**✅ Structured (JSON):**

```json
{
  "timestamp": "2025-01-23T10:15:32Z",
  "level": "info",
  "user": "john",
  "action": "login",
  "ip": "192.168.1.1"
}
{
  "timestamp": "2025-01-23T10:15:45Z",
  "level": "error",
  "service": "database",
  "error": "connection timeout"
}
```

**Benefits:**
- ✅ Easy to parse (JSON parsers)
- ✅ Consistent structure
- ✅ Filterable (level=error, service=database)
- ✅ Aggregatable (count by user, by error type)

---

### Logging Best Practices

**1. Use log levels:**

```javascript
// Node.js example (Winston logger)
logger.debug('Detailed debugging info');  // Development only
logger.info('User logged in');            // Normal operation
logger.warn('High memory usage');         // Warning (not critical)
logger.error('DB connection failed');     // Error (needs attention)
logger.fatal('Cannot start server');      // Critical (service down)
```

**Production:** `INFO` level (skip DEBUG to reduce volume)

---

**2. Include context:**

```javascript
// ❌ BAD
logger.error('Request failed');

// ✅ GOOD
logger.error('Request failed', {
  method: 'POST',
  path: '/api/users',
  statusCode: 500,
  userId: '12345',
  duration: '5.2s',
  error: err.message
});
```

---

**3. Don't log secrets:**

```javascript
// ❌ NEVER LOG SECRETS!
logger.info('User logged in', { password: userPassword });

// ✅ GOOD
logger.info('User logged in', { userId: userId });
```

---

## 20.2 Centralized Logging Problem

### Without Log Aggregation (❌ Chaotic)

```
Kubernetes cluster:
  - 10 nodes
  - 100 Pods (microservices)
  - Logs scattered across all Pods

Debugging:
  kubectl logs pod-1  # Check log
  kubectl logs pod-2  # Check another log
  kubectl logs pod-3  # ...
  # 😱 Must check 100 Pods manually!
```

**Probleemid:**
- ❌ Logs lost when Pod deleted (ephemeral)
- ❌ Can't search across all services
- ❌ No correlation (can't trace request across services)
- ❌ No retention (old logs deleted)

---

### With Log Aggregation (✅ Centralized)

```
All Pods → Promtail (DaemonSet on each node)
            → Loki (central log storage)
            → Grafana (query and visualize)

Debugging:
  Grafana UI → Search all logs in one place
  Filter: service=backend, level=error, time=last 1h
  Result: All backend errors aggregated!
```

**Benefits:**
- ✅ **Centralized:** All logs in one place
- ✅ **Persistent:** Logs survive Pod deletions
- ✅ **Searchable:** Query across all services
- ✅ **Correlatable:** Trace request ID across microservices
- ✅ **Retention:** Store logs for days/months

---

## 20.3 Loki Architecture

### Loki vs Elasticsearch (Design Philosophy)

**Elasticsearch (full-text indexing):**

```
Log entry:
  "User john logged in from 192.168.1.1"

Elasticsearch indexes EVERY WORD:
  - "User" → indexed
  - "john" → indexed
  - "logged" → indexed
  - "in" → indexed
  - "from" → indexed
  - "192.168.1.1" → indexed

Storage: MASSIVE (full inverted index)
Query: Fast (full-text search)
Cost: High (storage, CPU, memory)
```

---

**Loki (label-based indexing):**

```
Log entry:
  {
    "timestamp": "...",
    "level": "info",
    "user": "john"
  }

Loki indexes ONLY LABELS:
  - job=backend (indexed)
  - level=info (indexed)
  - user=john (NOT indexed - high cardinality!)

Log content: Compressed, NOT indexed

Storage: Small (only labels indexed)
Query: Fast for labels, slower for content search
Cost: Low (10x cheaper than Elasticsearch)
```

**Loki = Like Prometheus, but for logs**

```
Prometheus:
  - Metrics with labels (cpu{pod="backend-1"})
  - Labels indexed, values stored

Loki:
  - Logs with labels ({job="backend",level="error"})
  - Labels indexed, log content stored (compressed)
```

---

### Loki Components

```
Loki stack:
  1. Promtail (log collector, runs on each node)
     - Reads logs from /var/log/containers/*.log
     - Adds labels (namespace, pod, container)
     - Sends to Loki

  2. Loki (log storage and query engine)
     - Stores logs (compressed)
     - Indexes labels
     - Queries via LogQL

  3. Grafana (visualization)
     - Query Loki (LogQL)
     - Combine logs + metrics (Prometheus + Loki)
```

---

## 20.4 Install Loki Stack

### Helm Install

```bash
# Add Grafana Helm repo
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki stack (Loki + Promtail + Grafana)
helm install loki grafana/loki-stack \
  --namespace logging \
  --create-namespace \
  --set grafana.enabled=true \
  --set prometheus.enabled=true \
  --set promtail.enabled=true

# Check installation
kubectl get pods -n logging

# Output:
# loki-0 (StatefulSet)
# loki-promtail-* (DaemonSet, one per node)
# loki-grafana-* (Deployment)
```

---

### Access Grafana

```bash
# Port-forward Grafana
kubectl port-forward -n logging svc/loki-grafana 3000:80

# Get admin password
kubectl get secret -n logging loki-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d

# Open: http://localhost:3000
# Login: admin / <password>
```

---

### Add Loki Data Source

**Grafana UI:**

```
Configuration → Data Sources → Add data source
Type: Loki
URL: http://loki:3100  (Loki service in same namespace)
Save & Test ✅
```

**Verify:**

```
Explore → Select Loki data source
Query: {namespace="default"}
Result: Logs from default namespace appear!
```

📖 **Praktika:** Labor 6, Harjutus 3 - Loki stack setup

---

## 20.5 Promtail Configuration

### Promtail DaemonSet

**Promtail = Log collector (runs on every node)**

```yaml
# Simplified Promtail config
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: promtail
  namespace: logging
spec:
  selector:
    matchLabels:
      app: promtail
  template:
    metadata:
      labels:
        app: promtail
    spec:
      containers:
      - name: promtail
        image: grafana/promtail:latest
        args:
        - -config.file=/etc/promtail/promtail.yaml
        volumeMounts:
        - name: config
          mountPath: /etc/promtail
        - name: varlog
          mountPath: /var/log  # Host logs
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers  # Container logs
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: promtail-config
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

---

### Promtail Configuration (promtail.yaml)

```yaml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml  # Track read position (avoid re-reading)

clients:
  - url: http://loki:3100/loki/api/v1/push  # Loki endpoint

scrape_configs:
  # Kubernetes Pod logs
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod

    relabel_configs:
      # Add namespace label
      - source_labels: [__meta_kubernetes_namespace]
        target_label: namespace

      # Add pod label
      - source_labels: [__meta_kubernetes_pod_name]
        target_label: pod

      # Add container label
      - source_labels: [__meta_kubernetes_pod_container_name]
        target_label: container

      # Log file path
      - source_labels: [__meta_kubernetes_pod_uid, __meta_kubernetes_pod_container_name]
        target_label: __path__
        replacement: /var/log/pods/*$1/*.log
```

**Result:**

```
Promtail reads logs from:
  /var/log/pods/default_backend-abc123_12345/backend/0.log

Adds labels:
  {namespace="default", pod="backend-abc123", container="backend"}

Sends to Loki:
  POST http://loki:3100/loki/api/v1/push
```

---

## 20.6 LogQL - Loki Query Language

### Basic Queries

**1. Stream selector (filter by labels):**

```logql
# All logs from backend container
{container="backend"}

# Logs from production namespace
{namespace="production"}

# Multiple labels (AND)
{namespace="production", container="backend"}

# Regex match
{pod=~"backend-.*"}  # All backend Pods
{level!="debug"}     # Exclude debug logs
```

---

**2. Line filter (search log content):**

```logql
# Logs containing "error"
{container="backend"} |= "error"

# Logs NOT containing "debug"
{container="backend"} != "debug"

# Regex line filter
{container="backend"} |~ "error|ERROR|Error"

# Case-insensitive
{container="backend"} |~ "(?i)error"
```

---

**3. JSON parser:**

```logql
# Parse JSON logs
{container="backend"} | json

# Extract field
{container="backend"} | json | level="error"

# Multiple filters
{container="backend"} | json | level="error" | userId="12345"
```

**Example log:**

```json
{"timestamp":"2025-01-23T10:15:45Z","level":"error","userId":"12345","message":"DB timeout"}
```

**Query:**

```logql
{container="backend"} | json | level="error" | userId="12345"
```

**Result:** Filters logs where `level="error"` AND `userId="12345"`

---

**4. Aggregations (count, rate):**

```logql
# Count logs per second
rate({container="backend"}[5m])

# Count error logs
count_over_time({container="backend"} |= "error" [5m])

# Error rate (errors per second)
sum(rate({container="backend"} | json | level="error" [5m]))

# Top 10 users by error count
topk(10, sum by (userId) (count_over_time({container="backend"} | json | level="error" [1h])))
```

---

## 20.7 Grafana Logs Integration

### Explore View (Ad-hoc queries)

**Grafana → Explore → Loki data source**

**Query examples:**

```logql
# Show all backend logs (last 1 hour)
{container="backend"}

# Show only errors
{container="backend"} | json | level="error"

# Search for specific error message
{container="backend"} |= "database timeout"
```

**Features:**
- Time range picker (last 5m, 1h, 24h)
- Live streaming (tail -f mode)
- Log context (show surrounding logs)
- Copy log line
- Deduplication

---

### Dashboard - Logs Panel

**Create dashboard with logs:**

```
Add panel → Visualization: Logs
Data source: Loki
Query: {namespace="production"} | json | level="error"
```

**Panel options:**
- **Time:** Last 6 hours
- **Dedupe:** Exact (hide duplicate lines)
- **Order:** Newest first
- **Wrap lines:** On (long lines wrap)

---

### Logs + Metrics in One Dashboard

**Combine Prometheus metrics + Loki logs:**

**Panel 1: HTTP Request Rate (Prometheus):**

```promql
rate(http_requests_total{job="backend"}[5m])
```

**Panel 2: Error Logs (Loki):**

```logql
{job="backend"} | json | level="error"
```

**Benefit:** See metrics spike → check logs immediately (same dashboard!)

---

### Log Context

**Click log line → Show context:**

```
Grafana shows:
  - 10 lines BEFORE log
  - Selected log line (highlighted)
  - 10 lines AFTER log

Use case: Debug error by seeing surrounding logs
```

---

## 20.8 Log Retention and Storage

### Retention Policies

**Loki retention config:**

```yaml
# loki-config.yaml
limits_config:
  retention_period: 720h  # 30 days

compactor:
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150

table_manager:
  retention_deletes_enabled: true
  retention_period: 720h
```

**Retention strategies:**

```
Option 1: Time-based (30 days)
  - Delete logs older than 30 days

Option 2: Size-based (100GB)
  - Delete oldest logs when total > 100GB

Option 3: Tier-based
  - Hot: Last 7 days (fast SSD)
  - Warm: 8-30 days (slower HDD)
  - Cold: >30 days (S3 archive)
```

---

### Storage Backends

**Local storage (default):**

```yaml
schema_config:
  configs:
  - from: 2024-01-01
    store: boltdb-shipper
    object_store: filesystem
    schema: v11

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/cache
  filesystem:
    directory: /loki/chunks  # Local disk
```

**Probleemid:**
- Limited disk space
- No HA (single node failure = data loss)

---

**S3 storage (production):**

```yaml
storage_config:
  aws:
    s3: s3://us-east-1/my-loki-bucket
    s3forcepathstyle: true
  boltdb_shipper:
    active_index_directory: /loki/index
    cache_location: /loki/cache
    shared_store: s3
```

**Benefits:**
- ✅ Unlimited storage
- ✅ HA (S3 durable)
- ✅ Cost-effective (S3 cheaper than EBS)

---

## 20.9 Advanced Features

### Multi-tenancy

**Loki supports tenants (X-Scope-OrgID header):**

```yaml
# Tenant: team-a
curl -H "X-Scope-OrgID: team-a" http://loki:3100/loki/api/v1/push

# Tenant: team-b
curl -H "X-Scope-OrgID: team-b" http://loki:3100/loki/api/v1/push

# Each tenant's logs isolated
```

**Use case:** Multi-team Kubernetes cluster (namespace isolation)

---

### Alerting (Loki Ruler)

**Loki can fire alerts based on logs:**

```yaml
# loki-ruler-config.yaml
groups:
  - name: backend-alerts
    rules:
    - alert: HighErrorRate
      expr: |
        sum(rate({job="backend"} | json | level="error" [5m])) > 10
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate in backend"
```

**Integration with AlertManager:**

```yaml
ruler:
  alertmanager_url: http://alertmanager:9093
```

---

## 20.10 Loki vs Graylog vs ELK

### Comparison

| Kriteerium | Loki | Graylog | Elasticsearch (ELK) |
|------------|------|---------|---------------------|
| **Indexing** | Labels only | Full-text | Full-text |
| **Storage** | Very low | Medium | Very high |
| **Query speed (labels)** | Fast | Fast | Fast |
| **Query speed (content)** | Slow | Very fast | Very fast |
| **Cost** | Low | Medium | High |
| **Complexity** | Low | Medium | High |
| **Integration** | Grafana native | Web UI | Kibana |
| **Use case** | Kubernetes logs | General logging | Large-scale analytics |
| **Best for** | DevOps (Prometheus stack) | Security, compliance | Full-text search, ML |

---

### When to Use Each?

**Loki (✅ Recommended for Kubernetes):**
- ✅ Already using Prometheus + Grafana
- ✅ Label-based filtering enough (not full-text search)
- ✅ Budget-conscious (low storage)
- ✅ Simple setup (Helm chart)

**Graylog:**
- ✅ Need full-text search
- ✅ Security use cases (SIEM features)
- ✅ Alerting and dashboards built-in
- ✅ Standalone logging platform

**Elasticsearch (ELK):**
- ✅ Large-scale (TB/day logs)
- ✅ Complex queries (joins, aggregations)
- ✅ Machine learning (anomaly detection)
- ❌ Expensive (storage, infra)

---

## Kokkuvõte

**Logging fundamentals:**
- **Structured logs:** JSON format (easy to parse and filter)
- **Log levels:** DEBUG, INFO, WARN, ERROR, FATAL
- **Context:** Include request ID, user ID, service name
- **Centralized:** All logs in one place (survive Pod deletions)

**Loki architecture:**
- **Label-based indexing:** Like Prometheus for logs
- **Low storage:** 10x cheaper than Elasticsearch
- **Grafana integration:** Logs + metrics in one UI
- **Components:** Promtail (collector) + Loki (storage) + Grafana (UI)

**LogQL:**
- **Stream selector:** `{namespace="prod", container="backend"}`
- **Line filter:** `|= "error"`, `|~ "(?i)error"`
- **JSON parser:** `| json | level="error"`
- **Aggregations:** `rate()`, `count_over_time()`, `topk()`

**Storage:**
- **Local:** Default (limited, no HA)
- **S3:** Production (unlimited, HA, cost-effective)
- **Retention:** Time-based (30 days), size-based (100GB)

**Comparison:**
- **Loki:** DevOps, Kubernetes, Prometheus stack, low cost
- **Graylog:** Security, full-text search, SIEM
- **ELK:** Large-scale, complex analytics, ML

---

**DevOps Vaatenurk:**

```bash
# Access Grafana
kubectl port-forward -n logging svc/loki-grafana 3000:80

# Check Promtail (one per node)
kubectl get pods -n logging -l app=promtail

# Check Loki
kubectl get pods -n logging -l app=loki

# Query logs via API
curl -G http://loki:3100/loki/api/v1/query_range \
  --data-urlencode 'query={namespace="default"}' \
  --data-urlencode 'limit=10'

# Promtail logs (troubleshooting)
kubectl logs -n logging -l app=promtail
```

---

**Järgmised Sammud:**
**Peatükk 20A:** Graylog Log Management (alternative logging platform)
**Peatükk 21:** Alerting
**Peatükk 22:** Security Best Practices

📖 **Praktika:** Labor 6, Harjutus 3 - Loki + Promtail + Grafana setup, LogQL queries
