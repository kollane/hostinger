# Peatükk 21: Monitoring ja Logging 📊

**Kestus:** 4 tundi
**Eeldused:** Peatükk 20 läbitud, rakendus K8s-es töötab
**Eesmärk:** Seadistada täielik monitoring ja logging stack

---

## Sisukord

1. [Ülevaade](#1-ülevaade)
2. [Prometheus Paigaldamine](#2-prometheus-paigaldamine)
3. [Grafana Dashboards](#3-grafana-dashboards)
4. [PostgreSQL Monitoring - Mõlemad Variandid](#4-postgresql-monitoring---mõlemad-variandid)
5. [Application Metrics](#5-application-metrics)
6. [Log Aggregation - Loki + Promtail](#6-log-aggregation---loki--promtail)
7. [AlertManager](#7-alertmanager)
8. [Node Exporter](#8-node-exporter)
9. [Harjutused](#9-harjutused)

---

## 1. Ülevaade

### 1.1. Monitoring Stack Arhitektuur

```
┌─────────────────────────────────────────────────────────────┐
│              VPS kirjakast - MONITORING STACK                │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                  GRAFANA (Port 3001)                    │ │
│  │              Visualizations & Dashboards                │ │
│  └───────┬────────────────────────────────┬────────────────┘ │
│          │ queries                        │ queries          │
│          ▼                                ▼                  │
│  ┌─────────────────┐             ┌─────────────────┐        │
│  │   PROMETHEUS    │             │      LOKI       │        │
│  │   (Port 9090)   │             │   (Port 3100)   │        │
│  │   Metrics DB    │             │    Logs DB      │        │
│  └────────┬────────┘             └────────┬────────┘        │
│           │ scrape                        │ push             │
│           ▼                               ▼                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │           EXPORTERS & AGENTS                        │    │
│  │                                                     │    │
│  │  ┌───────────────┐  ┌───────────────┐  ┌────────┐ │    │
│  │  │ Node Exporter │  │ Postgres      │  │Promtail│ │    │
│  │  │ (VPS metrics) │  │ Exporter      │  │(logs)  │ │    │
│  │  └───────────────┘  └───────────────┘  └────────┘ │    │
│  │                                                     │    │
│  │  ┌───────────────┐  ┌───────────────┐            │    │
│  │  │ kube-state    │  │ App metrics   │            │    │
│  │  │ metrics       │  │ (prom-client) │            │    │
│  │  └───────────────┘  └───────────────┘            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              APPLICATION PODS                       │    │
│  │  - Backend (metrics endpoint /metrics)              │    │
│  │  - Frontend                                         │    │
│  │  - PostgreSQL StatefulSet / External DB             │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 1.2. Monitoring vs Logging

**Monitoring (Prometheus):**
- **Metrics:** Numbrilised väärtused (CPU, memory, request count)
- **Time series:** Ajaline andmekogum
- **Alerting:** Kui metric ületab threshold

**Logging (Loki):**
- **Logs:** Tekstilised sündmused
- **Aggregation:** Kõik logid ühes kohas
- **Searching:** Otsi logides mustrite järgi

---

## 2. Prometheus Paigaldamine

### 2.1. Prometheus K3s-is (Helm)

**Paigalda Helm (kui puudub):**
```bash
# VPS kirjakast
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version
```

**Lisa Prometheus Helm repo:**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

**Paigalda Prometheus:**
```bash
# Loo namespace
kubectl create namespace monitoring

# Paigalda Prometheus stack (sisaldab Grafana, AlertManager)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=7d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \
  --set grafana.adminPassword=admin123 \
  --set grafana.service.type=NodePort \
  --set grafana.service.nodePort=30300

# Jälgi paigaldust
kubectl get pods -n monitoring -w
```

**Kontrolli:**
```bash
kubectl get all -n monitoring

# Peaks nägema:
# - prometheus-kube-prometheus-prometheus-0
# - prometheus-grafana-xxx
# - prometheus-kube-state-metrics-xxx
# - prometheus-prometheus-node-exporter-xxx
# - alertmanager-xxx
```

### 2.2. Prometheus Config

**Vaata Prometheus config-i:**
```bash
kubectl get secret prometheus-kube-prometheus-prometheus -n monitoring -o yaml
```

**Prometheus UI:**
```bash
# Port-forward
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Ava browseris: http://localhost:9090
# VÕI VPS IP: http://93.127.213.242:9090 (kui NodePort)
```

**Prometheus Targets:**
- Ava: http://localhost:9090/targets
- Peaks nägema kõiki scrape targets

### 2.3. ServiceMonitor Custom Rakendusele

**ServiceMonitor:** Ütleb Prometheus-ele, kuidas backend metrics-t scrape-ida

**Fail:** `backend-servicemonitor.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: backend-monitor
  namespace: production
  labels:
    app: backend
    release: prometheus  # Prometheus otsib seda label-it
spec:
  selector:
    matchLabels:
      app: backend
  endpoints:
  - port: http          # Service port name
    path: /metrics      # Metrics endpoint
    interval: 30s       # Scrape iga 30s
    scrapeTimeout: 10s
```

**Rakenda:**
```bash
kubectl apply -f backend-servicemonitor.yaml

# Kontrolli Prometheus UI-s
# Status → Targets → backend-monitor
```

---

## 3. Grafana Dashboards

### 3.1. Grafana Ligipääs

**Prometheus Helm install lõi Grafana automaatselt.**

```bash
# Grafana password (kui ei seadista install ajal)
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d
echo

# Port-forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80

# Ava: http://localhost:3001
# Username: admin
# Password: (ülalt saadud)
```

**VÕI NodePort:**
```bash
# Kui seadistasid NodePort 30300
# Ava: http://93.127.213.242:30300
```

### 3.2. Add Prometheus Data Source

1. Grafana → Configuration (⚙️) → Data Sources
2. Add data source → Prometheus
3. URL: `http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`
4. Save & Test

**Peaks nägema:** "Data source is working"

### 3.3. Import Kubernetes Dashboards

**Valmis dashboards:**

1. **Kubernetes Cluster Monitoring:**
   - Dashboard ID: `15757` (Kubernetes / Views / Global)
   - Import → Load → Vali Prometheus data source

2. **Node Exporter Full:**
   - Dashboard ID: `1860`
   - Näitab VPS metrics (CPU, RAM, disk)

3. **Kubernetes Pods:**
   - Dashboard ID: `15758`
   - Pod-level metrics

**Import:**
- Grafana → Dashboards → Import
- Sisesta Dashboard ID
- Load → Vali Prometheus data source → Import

### 3.4. Custom Backend Dashboard

**Loo uus dashboard:**
1. Grafana → Dashboards → New → New Dashboard
2. Add visualization
3. Vali Prometheus data source

**Näidis queries:**

**HTTP Request Count:**
```promql
rate(http_requests_total{job="backend"}[5m])
```

**HTTP Request Duration (p95):**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="backend"}[5m]))
```

**Memory Usage:**
```promql
container_memory_usage_bytes{namespace="production", pod=~"backend.*"}
```

**CPU Usage:**
```promql
rate(container_cpu_usage_seconds_total{namespace="production", pod=~"backend.*"}[5m])
```

**Pod Count:**
```promql
count(kube_pod_info{namespace="production", pod=~"backend.*"})
```

**Salvesta dashboard:** Dashboard → Save dashboard → Anna nimi "Backend Monitoring"

---

## 4. PostgreSQL Monitoring - Mõlemad Variandid

### 4.1. PRIMAARNE: StatefulSet PostgreSQL Exporter

**PostgreSQL Exporter Deployment:**

**Fail:** `postgres-exporter.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-exporter
  namespace: production
  labels:
    app: postgres-exporter
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
      - name: postgres-exporter
        image: quay.io/prometheuscommunity/postgres-exporter:latest
        ports:
        - name: metrics
          containerPort: 9187
        env:
        - name: DATA_SOURCE_NAME
          value: "postgresql://$(DB_USER):$(DB_PASSWORD)@postgres:5432/appdb?sslmode=disable"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-exporter
  namespace: production
  labels:
    app: postgres-exporter
spec:
  selector:
    app: postgres-exporter
  ports:
  - name: metrics
    port: 9187
    targetPort: 9187
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: postgres-exporter
  namespace: production
  labels:
    app: postgres-exporter
    release: prometheus
spec:
  selector:
    matchLabels:
      app: postgres-exporter
  endpoints:
  - port: metrics
    interval: 30s
```

**Rakenda:**
```bash
kubectl apply -f postgres-exporter.yaml

# Kontrolli
kubectl get pods -n production -l app=postgres-exporter
kubectl logs -n production -l app=postgres-exporter

# Testi metrics endpoint
kubectl port-forward -n production svc/postgres-exporter 9187:9187
curl http://localhost:9187/metrics
```

**PostgreSQL Grafana Dashboard:**
- Import Dashboard ID: `9628` (PostgreSQL Database)
- Data source: Prometheus

### 4.2. ALTERNATIIV: Väline PostgreSQL

**Kui PostgreSQL on VPS-is (väljaspool K8s):**

**Paigalda exporter VPS-is:**
```bash
# VPS kirjakast (väljaspool K8s)
docker run -d \
  --name postgres-exporter \
  --restart always \
  -p 9187:9187 \
  -e DATA_SOURCE_NAME="postgresql://appuser:password@localhost:5432/appdb?sslmode=disable" \
  quay.io/prometheuscommunity/postgres-exporter:latest

# Kontrolli
curl http://localhost:9187/metrics
```

**Prometheus scrape config:**

**Fail:** `prometheus-external-postgres.yaml`

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: postgres-exporter-external
  namespace: production
subsets:
- addresses:
  - ip: 93.127.213.242  # VPS IP
  ports:
  - name: metrics
    port: 9187
    protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-exporter-external
  namespace: production
  labels:
    app: postgres-exporter
spec:
  ports:
  - name: metrics
    port: 9187
    targetPort: 9187
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: postgres-exporter-external
  namespace: production
  labels:
    app: postgres-exporter
    release: prometheus
spec:
  selector:
    matchLabels:
      app: postgres-exporter
  endpoints:
  - port: metrics
    interval: 30s
```

**Rakenda:**
```bash
kubectl apply -f prometheus-external-postgres.yaml
```

### 4.3. PostgreSQL Metrics

**Levinumad PostgreSQL metrics:**

```promql
# Active connections
pg_stat_activity_count

# Database size
pg_database_size_bytes{datname="appdb"}

# Transaction rate
rate(pg_stat_database_xact_commit{datname="appdb"}[5m])

# Slow queries
pg_stat_statements_max_exec_time_seconds

# Cache hit ratio
rate(pg_stat_database_blks_hit{datname="appdb"}[5m]) /
(rate(pg_stat_database_blks_hit{datname="appdb"}[5m]) + rate(pg_stat_database_blks_read{datname="appdb"}[5m]))
```

---

## 5. Application Metrics

### 5.1. Node.js Prometheus Client

**Paigalda prom-client:**
```bash
cd /home/janek/projects/hostinger/labs/apps/backend-nodejs

npm install prom-client
```

**Muuda backend koodi:**

**Fail:** `src/metrics.js` (UUS FAIL)

```javascript
const promClient = require('prom-client');

// Loo Registry
const register = new promClient.Registry();

// Default metrics (CPU, memory, event loop jne)
promClient.collectDefaultMetrics({ register });

// Custom metrics

// HTTP request counter
const httpRequestCounter = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// HTTP request duration histogram
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.001, 0.01, 0.1, 0.5, 1, 2, 5],
  registers: [register]
});

// Database query duration
const dbQueryDuration = new promClient.Histogram({
  name: 'db_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['query_type'],
  buckets: [0.001, 0.01, 0.1, 0.5, 1, 2, 5],
  registers: [register]
});

// Active users gauge
const activeUsers = new promClient.Gauge({
  name: 'active_users',
  help: 'Number of active users',
  registers: [register]
});

module.exports = {
  register,
  httpRequestCounter,
  httpRequestDuration,
  dbQueryDuration,
  activeUsers
};
```

**Muuda:** `src/index.js`

```javascript
const express = require('express');
const { register, httpRequestCounter, httpRequestDuration } = require('./metrics');

const app = express();

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;

    httpRequestCounter.inc({
      method: req.method,
      route: req.route ? req.route.path : req.path,
      status_code: res.statusCode
    });

    httpRequestDuration.observe({
      method: req.method,
      route: req.route ? req.route.path : req.path,
      status_code: res.statusCode
    }, duration);
  });

  next();
});

// ... existing routes ...

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// ... existing code ...
```

**Build uus image:**
```bash
docker build -t localhost:5000/backend:1.1 .
docker push localhost:5000/backend:1.1

# Update K8s
kubectl set image deployment/backend backend=localhost:5000/backend:1.1 -n production --record
```

### 5.2. Testi Metrics

```bash
# Port-forward
kubectl port-forward -n production svc/backend 3000:3000

# Testi metrics endpoint
curl http://localhost:3000/metrics

# Peaks nägema:
# http_requests_total{method="GET",route="/health",status_code="200"} 42
# http_request_duration_seconds_bucket{method="GET",route="/health",status_code="200",le="0.01"} 42
# ...
```

---

## 6. Log Aggregation - Loki + Promtail

### 6.1. Loki Paigaldamine

**Loki Helm chart:**
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Paigalda Loki stack (Loki + Promtail)
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set loki.persistence.enabled=true \
  --set loki.persistence.size=10Gi \
  --set promtail.enabled=true

# Kontrolli
kubectl get pods -n monitoring -l app=loki
kubectl get pods -n monitoring -l app=promtail
```

### 6.2. Loki Data Source Grafana-s

1. Grafana → Configuration → Data Sources
2. Add data source → Loki
3. URL: `http://loki.monitoring.svc.cluster.local:3100`
4. Save & Test

### 6.3. Log Queries

**Grafana → Explore → Vali Loki data source**

**Näidis queries:**

**Kõik backend logid:**
```logql
{namespace="production", app="backend"}
```

**Error logid:**
```logql
{namespace="production", app="backend"} |= "error"
```

**HTTP 500 errors:**
```logql
{namespace="production", app="backend"} | json | status_code="500"
```

**Log rate (per minute):**
```logql
rate({namespace="production", app="backend"}[1m])
```

**Top 10 error messages:**
```logql
topk(10, sum by (msg) (rate({namespace="production", app="backend"} |= "error" [5m])))
```

### 6.4. Structured Logging Backend-is

**Paigalda Winston (structured logging):**
```bash
cd /home/janek/projects/hostinger/labs/apps/backend-nodejs
npm install winston
```

**Loo:** `src/logger.js`

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'backend',
    version: process.env.APP_VERSION || '1.0.0'
  },
  transports: [
    new winston.transports.Console()
  ]
});

module.exports = logger;
```

**Kasuta:**
```javascript
const logger = require('./logger');

// Info log
logger.info('User registered', { userId: user.id, email: user.email });

// Error log
logger.error('Database connection failed', { error: err.message, stack: err.stack });

// Request logging
app.use((req, res, next) => {
  logger.info('HTTP request', {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
});
```

**Loki saab nüüd parsida JSON logisid:**
```logql
{namespace="production", app="backend"} | json | userId="123"
```

---

## 7. AlertManager

### 7.1. Prometheus Alert Rules

**Loo alert rules:**

**Fail:** `prometheus-alerts.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backend-alerts
  namespace: production
  labels:
    prometheus: kube-prometheus
    release: prometheus
spec:
  groups:
  - name: backend
    interval: 30s
    rules:
    # High Error Rate
    - alert: HighErrorRate
      expr: |
        rate(http_requests_total{status_code=~"5..", job="backend"}[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
        component: backend
      annotations:
        summary: "High error rate detected"
        description: "Backend error rate is {{ $value }} (threshold 0.05)"

    # Pod Down
    - alert: BackendPodDown
      expr: |
        kube_deployment_status_replicas_available{namespace="production",deployment="backend"} < 1
      for: 1m
      labels:
        severity: critical
        component: backend
      annotations:
        summary: "Backend pod down"
        description: "No backend pods available in production"

    # High Memory Usage
    - alert: HighMemoryUsage
      expr: |
        container_memory_usage_bytes{namespace="production",pod=~"backend.*"} /
        container_spec_memory_limit_bytes{namespace="production",pod=~"backend.*"} > 0.9
      for: 5m
      labels:
        severity: warning
        component: backend
      annotations:
        summary: "High memory usage"
        description: "Pod {{ $labels.pod }} memory usage is {{ $value | humanizePercentage }}"

    # High CPU Usage
    - alert: HighCPUUsage
      expr: |
        rate(container_cpu_usage_seconds_total{namespace="production",pod=~"backend.*"}[5m]) > 0.8
      for: 5m
      labels:
        severity: warning
        component: backend
      annotations:
        summary: "High CPU usage"
        description: "Pod {{ $labels.pod }} CPU usage is {{ $value | humanizePercentage }}"

  - name: postgres
    interval: 30s
    rules:
    # PostgreSQL Down
    - alert: PostgreSQLDown
      expr: |
        pg_up == 0
      for: 1m
      labels:
        severity: critical
        component: database
      annotations:
        summary: "PostgreSQL is down"
        description: "PostgreSQL exporter cannot connect to database"

    # High Connection Count
    - alert: HighConnectionCount
      expr: |
        pg_stat_activity_count > 80
      for: 5m
      labels:
        severity: warning
        component: database
      annotations:
        summary: "High PostgreSQL connection count"
        description: "Connection count is {{ $value }} (threshold 80)"

    # Low Cache Hit Ratio
    - alert: LowCacheHitRatio
      expr: |
        rate(pg_stat_database_blks_hit{datname="appdb"}[5m]) /
        (rate(pg_stat_database_blks_hit{datname="appdb"}[5m]) +
         rate(pg_stat_database_blks_read{datname="appdb"}[5m])) < 0.9
      for: 10m
      labels:
        severity: warning
        component: database
      annotations:
        summary: "Low PostgreSQL cache hit ratio"
        description: "Cache hit ratio is {{ $value | humanizePercentage }} (threshold 90%)"
```

**Rakenda:**
```bash
kubectl apply -f prometheus-alerts.yaml

# Kontrolli Prometheus UI-s
# Alerts tab → backend alerts
```

### 7.2. AlertManager Konfiguratsioon

**AlertManager on juba paigaldatud Prometheus Helm chart-iga.**

**Edit AlertManager config:**
```bash
kubectl edit secret alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring
```

**Näidis config (Slack notifications):**

```yaml
global:
  resolve_timeout: 5m
  slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'slack-notifications'
  routes:
  - match:
      severity: critical
    receiver: 'slack-critical'
    continue: true
  - match:
      severity: warning
    receiver: 'slack-warnings'

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#monitoring'
    title: 'Alert: {{ .GroupLabels.alertname }}'
    text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

- name: 'slack-critical'
  slack_configs:
  - channel: '#critical-alerts'
    title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
    text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

- name: 'slack-warnings'
  slack_configs:
  - channel: '#warnings'
    title: '⚠️ Warning: {{ .GroupLabels.alertname }}'
    text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

**Reload AlertManager:**
```bash
kubectl delete pod -n monitoring -l app.kubernetes.io/name=alertmanager
```

---

## 8. Node Exporter

**Node Exporter on juba paigaldatud Prometheus Helm chart-iga.**

**Kontrolli:**
```bash
kubectl get daemonset -n monitoring prometheus-prometheus-node-exporter

# Peaks olema 1/1 (üks node VPS-is)
```

**Node metrics:**
```promql
# CPU usage
rate(node_cpu_seconds_total{mode="idle"}[5m])

# Memory usage
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes

# Disk usage
node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}

# Network traffic
rate(node_network_receive_bytes_total{device="eth0"}[5m])
```

**Node Exporter Dashboard:**
- Import Dashboard ID: `1860` (Node Exporter Full)

---

## 9. Harjutused

### Harjutus 1: Prometheus + Grafana Setup

**Eesmärk:** Paigaldada ja seadistada Prometheus + Grafana

**Sammud:**

1. **Paigalda Prometheus stack:**
```bash
kubectl create namespace monitoring

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.adminPassword=admin123
```

2. **Kontrolli paigaldust:**
```bash
kubectl get pods -n monitoring

# Kõik peaks olema Running
```

3. **Ava Grafana:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80

# Ava: http://localhost:3001
# Login: admin / admin123
```

4. **Kontrolli Prometheus data source:**
- Configuration → Data Sources
- Peaks olema Prometheus juba konfigureeritud

5. **Import dashboards:**
- Import Dashboard 15757 (Kubernetes Cluster)
- Import Dashboard 1860 (Node Exporter)
- Import Dashboard 15758 (Pods)

**Valideerimise checklist:**
- [ ] Prometheus paigaldatud
- [ ] Grafana kättesaadav
- [ ] Prometheus data source töötab
- [ ] 3+ dashboard-i imporditud
- [ ] Näed VPS metrics-eid

---

### Harjutus 2: Backend Application Metrics

**Eesmärk:** Lisada Prometheus metrics backend-ile

**Sammud:**

1. **Paigalda prom-client:**
```bash
cd /home/janek/projects/hostinger/labs/apps/backend-nodejs
npm install prom-client
```

2. **Loo metrics.js:**
```bash
vim src/metrics.js
# (kopeeri sektsioonist 5.1)
```

3. **Muuda index.js:**
```bash
vim src/index.js
# Lisa metrics middleware ja /metrics endpoint
# (vaata sektsiooni 5.1)
```

4. **Build ja deploy:**
```bash
docker build -t localhost:5000/backend:metrics .
docker push localhost:5000/backend:metrics

kubectl set image deployment/backend backend=localhost:5000/backend:metrics -n production --record
```

5. **Loo ServiceMonitor:**
```bash
vim backend-servicemonitor.yaml
# (kopeeri sektsioonist 2.3)

kubectl apply -f backend-servicemonitor.yaml
```

6. **Kontrolli Prometheus:**
- Ava Prometheus UI
- Status → Targets
- Peaks nägema `backend-monitor`

7. **Loo custom dashboard:**
- Grafana → New Dashboard
- Lisa queries (vaata sektsiooni 3.4)
- Salvesta

**Valideerimise checklist:**
- [ ] prom-client paigaldatud
- [ ] /metrics endpoint töötab
- [ ] ServiceMonitor loodud
- [ ] Prometheus scrape-ib backend-i
- [ ] Custom dashboard loodud
- [ ] Näed HTTP request metrics

---

### Harjutus 3: PostgreSQL Monitoring

**Eesmärk:** Seadistada PostgreSQL monitoring (vali variant)

**PRIMAARNE: StatefulSet PostgreSQL**

```bash
vim postgres-exporter.yaml
# (kopeeri sektsioonist 4.1)

kubectl apply -f postgres-exporter.yaml

# Kontrolli
kubectl get pods -n production -l app=postgres-exporter
kubectl logs -n production -l app=postgres-exporter
```

**ALTERNATIIV: Väline PostgreSQL**

```bash
# VPS-is (väljaspool K8s)
docker run -d \
  --name postgres-exporter \
  --restart always \
  -p 9187:9187 \
  -e DATA_SOURCE_NAME="postgresql://appuser:password@localhost:5432/appdb?sslmode=disable" \
  quay.io/prometheuscommunity/postgres-exporter:latest

# K8s-is
vim prometheus-external-postgres.yaml
# (kopeeri sektsioonist 4.2)

kubectl apply -f prometheus-external-postgres.yaml
```

**Import PostgreSQL Dashboard:**
- Grafana → Import → Dashboard ID `9628`

**Valideerimise checklist:**
- [ ] PostgreSQL exporter running
- [ ] Prometheus scrape-ib exporter-it
- [ ] PostgreSQL dashboard imporditud
- [ ] Näed DB metrics (connections, size, transactions)

---

### Harjutus 4: Alerting

**Eesmärk:** Seadistada alerts

**Sammud:**

1. **Loo alert rules:**
```bash
vim prometheus-alerts.yaml
# (kopeeri sektsioonist 7.1)

kubectl apply -f prometheus-alerts.yaml
```

2. **Kontrolli Prometheus:**
- Prometheus UI → Alerts
- Peaks nägema kõiki defineeritud alerts

3. **Simuleeri alert:**
```bash
# Skaleeri backend 0-ks (simuleerib pod down)
kubectl scale deployment/backend --replicas=0 -n production

# Oota 1-2 minutit

# Kontrolli Prometheus Alerts
# BackendPodDown peaks olema FIRING

# Taasta
kubectl scale deployment/backend --replicas=3 -n production
```

4. **Seadista AlertManager (valikuline):**
```bash
# Kui sul on Slack webhook
kubectl edit secret alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring

# Lisa Slack config (vaata sektsiooni 7.2)
```

**Valideerimise checklist:**
- [ ] Alert rules loodud
- [ ] Alerts nähtavad Prometheus-es
- [ ] Test alert (pod down) käivitus
- [ ] Alert resolved peale fixi

---

## Kokkuvõte

Selles peatükis õppisid:

✅ **Prometheus:**
- Paigaldamine Helm-iga
- Scrape configuration
- ServiceMonitor CRD
- PromQL queries

✅ **Grafana:**
- Dashboards import
- Custom dashboards
- Data sources (Prometheus, Loki)
- Visualizations

✅ **PostgreSQL Monitoring:**
- PRIMAARNE: StatefulSet exporter
- ALTERNATIIV: External exporter
- DB-specific metrics
- Performance dashboards

✅ **Application Metrics:**
- prom-client (Node.js)
- Custom metrics (counters, histograms, gauges)
- HTTP request tracking
- Business metrics

✅ **Logging:**
- Loki + Promtail stack
- Log aggregation
- LogQL queries
- Structured logging (Winston)

✅ **Alerting:**
- PrometheusRule CRD
- Alert expressions
- AlertManager configuration
- Notification channels (Slack)

✅ **Node Metrics:**
- Node Exporter
- System metrics (CPU, memory, disk, network)

---

## Järgmine Samm

**Peatükk 22: Security Best Practices**
- SSL/TLS
- Network Policies
- Secrets management
- Pod Security Standards
- Vulnerability scanning
- OWASP Top 10

**Ressursid:**
- Prometheus: https://prometheus.io/docs/
- Grafana: https://grafana.com/docs/
- Loki: https://grafana.com/docs/loki/
- prom-client: https://github.com/simetr/prom-client

---

**VPS:** kirjakast @ 93.127.213.242
**Kasutaja:** janek
**Editor:** vim
**Monitoring:** Prometheus + Grafana + Loki

Edu! 🚀
