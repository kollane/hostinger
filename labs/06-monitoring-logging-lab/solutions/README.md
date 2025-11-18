# Lab 6: Monitoring & Logging - Solutions

See kaust sisaldab näidislahendusi ja konfiguratsioonifaile Lab 6 harjutustele.

---

## 📂 Monitoring Stack Ülevaade

**Täielik monitoring stack:**

```
┌─────────────────────────────────────────────────────┐
│                  Grafana UI                         │
│  - Dashboards (Metrics + Logs)                     │
│  - Alerting                                         │
│  - Query UI (PromQL + LogQL)                       │
└────────┬────────────────────────┬───────────────────┘
         │                        │
         ▼                        ▼
┌──────────────────┐    ┌──────────────────┐
│  Prometheus      │    │  Loki            │
│  - Metrics       │    │  - Logs          │
│  - Alerting      │    │  - Log storage   │
└────────┬─────────┘    └────────┬─────────┘
         │                       │
         ▼                       ▼
┌──────────────────┐    ┌──────────────────┐
│  ServiceMonitors │    │  Promtail        │
│  - Scrape configs│    │  - Log collector │
└────────┬─────────┘    └────────┬─────────┘
         │                       │
         ▼                       ▼
┌──────────────────────────────────────────┐
│         Application Pods                 │
│  - /metrics endpoint (Prometheus)       │
│  - stdout/stderr logs (Loki)            │
└──────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### 1. Paigalda Prometheus Stack

```bash
# Lisa Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values prometheus-values.yaml
```

### 2. Paigalda Loki Stack

```bash
# Lisa Helm repo
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install loki-stack
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki-values.yaml
```

### 3. Port Forward Services

```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Alertmanager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093

# Loki
kubectl port-forward -n monitoring svc/loki 3100:3100
```

**Access UI's:**
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)
- Alertmanager: http://localhost:9093

---

## 📝 Configuration Files

### Prometheus Values (`prometheus-values.yaml`)

```yaml
prometheus:
  prometheusSpec:
    retention: 7d
    retentionSize: "10GB"

    resources:
      requests:
        cpu: 200m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 2Gi

    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

grafana:
  enabled: true
  adminPassword: "admin"

  persistence:
    enabled: true
    size: 5Gi

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi

kube-state-metrics:
  enabled: true

prometheus-node-exporter:
  enabled: true
```

---

### Loki Values (`loki-values.yaml`)

```yaml
loki:
  enabled: true

  persistence:
    enabled: true
    size: 10Gi

  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

  config:
    limits_config:
      retention_period: 168h  # 7 days

promtail:
  enabled: true

  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
```

---

### ServiceMonitor (`servicemonitor-user-service.yaml`)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: user-service-monitor
  namespace: default
  labels:
    app: user-service
spec:
  selector:
    matchLabels:
      app: user-service
  endpoints:
  - port: http
    path: /metrics
    interval: 15s
    scrapeTimeout: 10s
```

---

### Prometheus Alert Rules (`prometheus-rules.yaml`)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: user-service-alerts
  namespace: monitoring
spec:
  groups:
  - name: user-service
    interval: 30s
    rules:

    - alert: HighCPUUsage
      expr: |
        (100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on {{ $labels.instance }}"

    - alert: PodDown
      expr: |
        up{job="kubernetes-pods", namespace="default", pod=~"user-service.*"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ $labels.pod }} is down"

    - alert: HighErrorRate
      expr: |
        (sum(rate(http_requests_total{app="user-service", status=~"5.."}[5m]))
        /
        sum(rate(http_requests_total{app="user-service"}[5m]))) * 100 > 5
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "High error rate for user-service"
```

---

### Alertmanager Config (`alertmanager-config.yaml`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-prometheus-kube-prometheus-alertmanager
  namespace: monitoring
type: Opaque
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m

    route:
      receiver: 'default'
      group_by: ['alertname', 'cluster']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h

      routes:
      - match:
          severity: critical
        receiver: 'critical-alerts'
        repeat_interval: 1h

      - match:
          severity: warning
        receiver: 'warning-alerts'
        repeat_interval: 4h

    receivers:
    - name: 'default'

    - name: 'critical-alerts'
      slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts-critical'
        title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'

    - name: 'warning-alerts'
      slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts-warning'
        title: '⚠️  WARNING: {{ .GroupLabels.alertname }}'
```

---

## 📊 Useful PromQL Queries

### Infrastructure Metrics

```promql
# Node CPU usage (%)
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Node memory usage (%)
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk space available (%)
node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100

# Network traffic (bytes/sec)
rate(node_network_receive_bytes_total[5m])
```

### Kubernetes Metrics

```promql
# Pod count
count(kube_pod_info)

# Pod memory usage (MB)
sum(container_memory_usage_bytes{pod=~"user-service.*"}) / 1024 / 1024

# Pod CPU usage (%)
sum(rate(container_cpu_usage_seconds_total{pod=~"user-service.*"}[5m])) * 100

# Pod restart count
kube_pod_container_status_restarts_total
```

### Application Metrics

```promql
# Request rate (req/sec)
rate(http_requests_total{app="user-service"}[5m])

# Error rate (%)
(sum(rate(http_requests_total{app="user-service",status=~"5.."}[5m]))
/
sum(rate(http_requests_total{app="user-service"}[5m]))) * 100

# P95 latency (seconds)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{app="user-service"}[5m]))

# Active users
active_users
```

---

## 📋 Useful LogQL Queries

### Basic Queries

```logql
# All logs from namespace
{namespace="default"}

# Logs from specific pod
{namespace="default", pod=~"user-service.*"}

# Filter by content
{namespace="default"} |= "ERROR"

# Regex filter
{namespace="default"} |~ "HTTP.*500"

# Exclude health checks
{namespace="default"} != "/health"
```

### Advanced Queries

```logql
# JSON parsing
{namespace="default"} | json | level="error"

# Log rate (logs/sec)
rate({namespace="default"}[5m])

# Error count
count_over_time({namespace="default"} |= "ERROR" [1h])

# Top error messages
topk(10, sum by (pod) (count_over_time({namespace="default"} |= "ERROR" [1h])))
```

---

## 🎨 Grafana Dashboard JSON

### Example Dashboard: User Service

**Import dashboard JSON:**

1. Grafana → Dashboards → Import
2. Paste JSON (näidis allpool)
3. Select Prometheus data source
4. Import

**Basic dashboard structure:**

```json
{
  "dashboard": {
    "title": "User Service Monitoring",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{app=\"user-service\"}[5m])"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "(sum(rate(http_requests_total{app=\"user-service\",status=~\"5..\"}[5m])) / sum(rate(http_requests_total{app=\"user-service\"}[5m]))) * 100"
          }
        ]
      }
    ]
  }
}
```

**Popular community dashboards:**
- **15760** - Kubernetes / Views / Global
- **13332** - Kubernetes Cluster Monitoring
- **7249** - Kubernetes Cluster

---

## 🔧 Troubleshooting

### Prometheus ei kogu metrics'eid

**Check:**

```bash
# ServiceMonitor exists
kubectl get servicemonitor -n default

# Service exists with correct labels
kubectl get svc user-service --show-labels

# Prometheus targets
# http://localhost:9090/targets
```

---

### Loki ei näita logisid

**Check:**

```bash
# Promtail running
kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail

# Promtail logs
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail

# Loki labels
curl 'http://localhost:3100/loki/api/v1/labels'
```

---

### Alerts ei fire

**Check:**

```bash
# PrometheusRule exists
kubectl get prometheusrule -n monitoring

# Prometheus alerts page
# http://localhost:9090/alerts

# Alertmanager
# http://localhost:9093
```

---

## 📚 Additional Resources

### Documentation
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [LogQL Tutorial](https://grafana.com/docs/loki/latest/logql/)

### Helm Charts
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [loki-stack](https://github.com/grafana/helm-charts/tree/main/charts/loki-stack)

### Community Dashboards
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Kubernetes Dashboards](https://grafana.com/grafana/dashboards/?search=kubernetes)

---

## ✅ Lab 6 Completion Checklist

Peale labori läbimist peaksid omama:

- [ ] **Prometheus:**
  - [ ] Prometheus server running
  - [ ] ServiceMonitors configured
  - [ ] Metrics visible

- [ ] **Grafana:**
  - [ ] Grafana accessible
  - [ ] Prometheus data source
  - [ ] Loki data source
  - [ ] Custom dashboards created

- [ ] **Loki:**
  - [ ] Loki server running
  - [ ] Promtail collecting logs
  - [ ] Logs visible in Grafana

- [ ] **Application:**
  - [ ] `/metrics` endpoint
  - [ ] prom-client integrated
  - [ ] Structured logging (JSON)

- [ ] **Alerting:**
  - [ ] Alert rules defined
  - [ ] Alertmanager configured
  - [ ] Slack notifications working

---

## 🎉 Congratulations!

Oled edukalt seadistanud täieliku monitoring ja logging stack'i!

**Skill'id, mida omandasti:**
- ✅ Prometheus metrics collection
- ✅ Grafana visualization
- ✅ Application instrumentation
- ✅ Log aggregation (Loki)
- ✅ Alerting ja notifications

**Next steps:**
- Apply to production
- Tune alert thresholds
- Create custom dashboards
- Monitor SLOs (Service Level Objectives)

---

**Happy Monitoring! 📊📋🔔**
