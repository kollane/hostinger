# Peatükk 18: Prometheus ja Metrics

**Kestus:** 4 tundi
**Eeldused:** Peatükk 9-13 (Kubernetes core)
**Eesmärk:** Mõista metrics collection ja Prometheus arhitektuuri

---

## Õpieesmärgid

- Mõista observability pillars (metrics, logs, traces)
- Prometheus arhitektuur (pull model, PromQL)
- Kubernetes metrics collection (ServiceMonitor, PodMonitor)
- Exporters ja instrumentation
- AlertManager basics

---

## 18.1 Observability Fundamentals

### Three Pillars of Observability

**Metrics:**
- Numbers over time (CPU usage, request count, latency)
- Efficient storage (time-series database)
- Ideal for: Dashboards, alerts, trends

**Logs:**
- Event records (application logs, errors)
- Unstructured or structured
- Ideal for: Debugging, troubleshooting

**Traces:**
- Request flow through microservices
- Distributed tracing
- Ideal for: Performance bottleneck discovery

**DevOps focus:** Metrics = foundation for proactive monitoring

---

## 18.2 Prometheus Architecture

### Pull Model

**Architecture:**

```
Prometheus Server:
  → Pull metrics from targets (every 15s)
  → Store in time-series database (TSDB)
  → Query via PromQL
  → Send alerts to AlertManager

Targets:
  - Kubernetes API (kubelet, kube-state-metrics)
  - Exporters (node-exporter, postgres-exporter)
  - Applications (/metrics endpoint)

AlertManager:
  → Receives alerts from Prometheus
  → Routes to channels (Slack, email, PagerDuty)
  → Deduplicates and groups
```

**Pull vs Push:**
```
Prometheus (pull): Prometheus scrapes targets
Benefits:
- Targets don't need to know Prometheus location
- Automatic service discovery
- Prometheus controls scrape frequency

Push (e.g., InfluxDB): Targets push to collector
```

---

### Metric Types

**Counter:** Only increases (reset on restart)
```
http_requests_total{method="GET",status="200"} 1547
```
Use: Total requests, errors, bytes sent

**Gauge:** Can go up or down
```
memory_usage_bytes 536870912
pod_count{namespace="default"} 15
```
Use: Current values (temperature, queue length)

**Histogram:** Distribution of values
```
http_request_duration_seconds_bucket{le="0.1"} 4823
http_request_duration_seconds_bucket{le="0.5"} 5102
http_request_duration_seconds_sum 2134.5
http_request_duration_seconds_count 5120
```
Use: Latency, request sizes

**Summary:** Similar to histogram (client-side quantiles)

---

## 18.3 Kubernetes Metrics Collection

### Metrics Sources

**1. cAdvisor (kubelet embedded):**
- Container resource usage (CPU, memory, network)
- `/metrics/cadvisor` endpoint

**2. kubelet:**
- Node metrics
- `/metrics` endpoint

**3. kube-state-metrics:**
- Kubernetes object state (Deployments, Pods, Services)
- Exposes as Prometheus metrics

**4. Application metrics:**
- Custom `/metrics` endpoint in app

---

### Installing Prometheus (Prometheus Operator)

```yaml
# Install via Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

**What gets installed:**
- Prometheus server
- Grafana
- AlertManager
- node-exporter (DaemonSet)
- kube-state-metrics
- Prometheus Operator (manages Prometheus resources)

---

### ServiceMonitor - Automatic Service Discovery

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: backend-monitor
  namespace: default
spec:
  selector:
    matchLabels:
      app: backend  # Target Services with this label
  endpoints:
  - port: metrics  # Service port name
    path: /metrics
    interval: 30s
```

**How it works:**

```
1. ServiceMonitor created
2. Prometheus Operator detects ServiceMonitor
3. Operator updates Prometheus scrape config
4. Prometheus scrapes backend Service /metrics every 30s
```

**No manual Prometheus config!** Kubernetes-native service discovery.

📖 **Praktika:** Labor 6, Harjutus 1 - Prometheus setup + ServiceMonitor

---

## 18.4 Application Instrumentation

### Node.js Example

```javascript
// Install: npm install prom-client express
const express = require('express');
const client = require('prom-client');

const app = express();

// Enable default metrics (process CPU, memory, etc.)
client.collectDefaultMetrics();

// Custom counter
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status']
});

// Custom histogram
const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request latency',
  labelNames: ['method', 'route']
});

// Middleware
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer();
  res.on('finish', () => {
    end({ method: req.method, route: req.route?.path || req.path });
    httpRequestsTotal.inc({ method: req.method, route: req.route?.path || req.path, status: res.statusCode });
  });
  next();
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// API routes
app.get('/api/users', (req, res) => {
  res.json({ users: [] });
});

app.listen(3000);
```

**Metrics exposed:**

```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/api/users",status="200"} 1547

# HELP http_request_duration_seconds HTTP request latency
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",route="/api/users",le="0.005"} 1200
http_request_duration_seconds_bucket{method="GET",route="/api/users",le="0.01"} 1450
http_request_duration_seconds_sum{method="GET",route="/api/users"} 5.2
http_request_duration_seconds_count{method="GET",route="/api/users"} 1547
```

---

## 18.5 PromQL - Query Language

### Basic Queries

**Instant vector (current value):**
```promql
# Current memory usage
container_memory_usage_bytes{pod="backend-abc123"}

# HTTP request rate (last 5 min)
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**Range vector (time series):**
```promql
# CPU usage last hour
container_cpu_usage_seconds_total{pod="backend"}[1h]
```

---

### Aggregation

```promql
# Total requests across all Pods
sum(rate(http_requests_total[5m]))

# Average memory per namespace
avg by (namespace) (container_memory_usage_bytes)

# Max CPU per Pod
max by (pod) (rate(container_cpu_usage_seconds_total[5m]))
```

---

### Filters

```promql
# Specific namespace
container_memory_usage_bytes{namespace="production"}

# Regex match
http_requests_total{route=~"/api/.*"}

# Not equal
http_requests_total{status!="200"}
```

---

### Practical Queries

**1. Pod CPU usage (%)**
```promql
sum(rate(container_cpu_usage_seconds_total{pod="backend-abc"}[5m])) by (pod) * 100
```

**2. Request error rate**
```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100
```

**3. 99th percentile latency**
```promql
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

**4. Pods not ready**
```promql
kube_pod_status_phase{phase!="Running"} > 0
```

📖 **Praktika:** Labor 6, Harjutus 2 - PromQL queries

---

## 18.6 Exporters

### Node Exporter (Server Metrics)

**Installed as DaemonSet** (one per Node)

**Metrics:**
- CPU, memory, disk, network
- Filesystem usage
- System load

**Query:**
```promql
# Disk usage %
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100

# CPU usage %
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

---

### PostgreSQL Exporter

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-exporter
  template:
    metadata:
      labels:
        app: postgres-exporter
    spec:
      containers:
      - name: exporter
        image: prometheuscommunity/postgres-exporter:latest
        env:
        - name: DATA_SOURCE_NAME
          value: "postgresql://user:password@postgres:5432/dbname?sslmode=disable"
        ports:
        - containerPort: 9187
          name: metrics

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-exporter
  labels:
    app: postgres-exporter
spec:
  ports:
  - port: 9187
    name: metrics
  selector:
    app: postgres-exporter

---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: postgres-monitor
spec:
  selector:
    matchLabels:
      app: postgres-exporter
  endpoints:
  - port: metrics
```

**Metrics:**
- Connections, active queries
- Table sizes, index usage
- Replication lag
- pg_stat_activity, pg_stat_statements

---

## 18.7 Recording Rules - Pre-compute Queries

**Problem:** Complex PromQL queries are slow

**Solution:** Recording rules (pre-compute and store)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backend-rules
spec:
  groups:
  - name: backend_metrics
    interval: 30s
    rules:
    # Recording rule (pre-compute)
    - record: job:http_requests:rate5m
      expr: sum(rate(http_requests_total[5m])) by (job)

    # Recording rule (error rate)
    - record: job:http_errors:rate5m
      expr: sum(rate(http_requests_total{status=~"5.."}[5m])) by (job)
```

**Use pre-computed metric:**
```promql
# Fast (no aggregation needed)
job:http_requests:rate5m{job="backend"}
```

---

## 18.8 AlertManager Basics

### Alerting Rules

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backend-alerts
spec:
  groups:
  - name: backend_alerts
    rules:
    # Alert: High error rate
    - alert: HighErrorRate
      expr: |
        sum(rate(http_requests_total{status=~"5.."}[5m])) by (job)
        /
        sum(rate(http_requests_total[5m])) by (job)
        > 0.05
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate on {{ $labels.job }}"
        description: "Error rate is {{ $value | humanizePercentage }} (threshold: 5%)"

    # Alert: Pod down
    - alert: PodDown
      expr: kube_pod_status_phase{phase!="Running"} > 0
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.pod }} is down"
```

**Alert states:**
- **Inactive:** Condition false
- **Pending:** Condition true, waiting for `for` duration
- **Firing:** Condition true for >= `for` duration → sent to AlertManager

---

### AlertManager Configuration

```yaml
# ConfigMap for AlertManager
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
data:
  alertmanager.yml: |
    global:
      resolve_timeout: 5m

    route:
      receiver: 'default'
      group_by: ['alertname', 'namespace']
      group_wait: 10s
      group_interval: 5m
      repeat_interval: 12h

      routes:
      - match:
          severity: critical
        receiver: 'pagerduty'

      - match:
          severity: warning
        receiver: 'slack'

    receivers:
    - name: 'default'
      webhook_configs:
      - url: 'http://webhook.example.com'

    - name: 'slack'
      slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#devops-alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

    - name: 'pagerduty'
      pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_KEY'
```

**Routing:**
```
Alert: severity=critical
→ Route to pagerduty receiver
→ PagerDuty notification

Alert: severity=warning
→ Route to slack receiver
→ Slack #devops-alerts message
```

📖 **Praktika:** Labor 6, Harjutus 3 - Alerting rules + AlertManager

---

## Kokkuvõte

**Prometheus:**
- Pull-based metrics collection
- Time-series database (TSDB)
- PromQL query language
- Kubernetes-native (ServiceMonitor, Prometheus Operator)

**Metrics:**
- Counter, Gauge, Histogram, Summary
- Application instrumentation (/metrics endpoint)
- Exporters (node, postgres, custom)

**PromQL:**
- Instant/range vectors
- Aggregation (sum, avg, max)
- Rate, histogram_quantile

**Alerting:**
- PrometheusRule (alerting + recording rules)
- AlertManager (routing, grouping, deduplication)
- Receivers (Slack, PagerDuty, email)

---

**DevOps Vaatenurk:**

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090
# Open http://localhost:9090/targets

# Query metrics
curl 'http://localhost:9090/api/v1/query?query=up'

# Check AlertManager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
# Open http://localhost:9093
```

---

**Järgmised Sammud:**
**Peatükk 19:** Grafana (visualization)
**Peatükk 20A:** Graylog (log management)

📖 **Praktika:** Labor 6 - Prometheus + Grafana + AlertManager
