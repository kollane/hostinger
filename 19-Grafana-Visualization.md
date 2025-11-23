# Peatükk 19: Grafana ja Visualization

**Kestus:** 3 tundi
**Eeldused:** Peatükk 18 (Prometheus)
**Eesmärk:** Luua interaktiivseid dashboards'e Grafana'ga

---

## Õpieesmärgid

- Grafana arhitektuur ja integratsioon Prometheus'ega
- Data sources (Prometheus, Loki, PostgreSQL)
- Dashboard loomine ja panellid
- Variables ja templating
- Alerting Grafana's

---

## 19.1 Grafana Overview

**Grafana = Visualization platform**

```
Prometheus (data) → Grafana (visualization)

Grafana supports:
- Prometheus, Loki, InfluxDB, PostgreSQL, MySQL, Elasticsearch
- Interactive dashboards
- Alerts (alternative to AlertManager)
- User management, teams
```

**Access Grafana:**

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open: http://localhost:3000
# Default: admin / prom-operator (check with kubectl get secret)
```

---

## 19.2 Data Sources

### Adding Prometheus

```
Configuration → Data Sources → Add data source

Type: Prometheus
URL: http://prometheus-operated:9090
Access: Server (default)

Save & Test
```

**Already configured** if installed via kube-prometheus-stack Helm chart.

---

### Query Examples

**PromQL in Grafana:**

```promql
# CPU usage by Pod
sum(rate(container_cpu_usage_seconds_total{pod=~"backend.*"}[5m])) by (pod)

# Memory usage
container_memory_usage_bytes{pod=~"backend.*"}

# HTTP requests (with variables)
rate(http_requests_total{namespace="$namespace",pod=~"$pod"}[5m])
```

---

## 19.3 Dashboard Creation

### Create Dashboard

```
+ → Create Dashboard → Add visualization

Data source: Prometheus
Query: sum(rate(http_requests_total[5m]))
```

**Panel types:**
- Time series (line chart)
- Gauge (current value)
- Stat (single number)
- Table
- Heatmap
- Bar chart

---

### Panel Options

**Time series panel:**

```
Query: rate(http_requests_total[5m])

Panel options:
- Title: HTTP Request Rate
- Description: Requests per second

Legend:
- {{pod}} - {{status}}

Axes:
- Left Y: Requests/sec
- Right Y: (optional second metric)

Thresholds:
- Green: < 100
- Yellow: 100-500
- Red: > 500
```

---

### Multiple Queries

```
Query A: sum(rate(http_requests_total{status="200"}[5m]))
Legend: Success

Query B: sum(rate(http_requests_total{status=~"5.."}[5m]))
Legend: Errors
```

**Result:** Two lines on same graph (success + errors)

---

## 19.4 Variables and Templating

### Dashboard Variables

**Create variable:**

```
Dashboard settings → Variables → Add variable

Name: namespace
Type: Query
Data source: Prometheus
Query: label_values(kube_pod_info, namespace)
Refresh: On dashboard load
```

**Use variable in panel:**

```promql
# In query
rate(http_requests_total{namespace="$namespace"}[5m])

# In panel title
HTTP Requests - $namespace
```

**Multi-select variable:**

```
Name: pod
Type: Query
Query: label_values(kube_pod_info{namespace="$namespace"}, pod)
Multi-value: ✅
Include All: ✅
```

**Use in query:**

```promql
rate(http_requests_total{namespace="$namespace",pod=~"$pod"}[5m])
```

**Benefit:** Single dashboard for all namespaces/pods!

---

### Common Variables

**1. Namespace:**
```
label_values(kube_pod_info, namespace)
```

**2. Pod:**
```
label_values(kube_pod_info{namespace="$namespace"}, pod)
```

**3. Time range:**
```
Name: interval
Type: Interval
Values: 1m,5m,10m,30m,1h
```

**Use:**
```promql
rate(http_requests_total[$interval])
```

---

## 19.5 Sample Dashboards

### Kubernetes Cluster Overview

**Panels:**

**1. Cluster CPU Usage**
```promql
sum(rate(container_cpu_usage_seconds_total[5m])) / sum(machine_cpu_cores) * 100
```

**2. Cluster Memory Usage**
```promql
sum(container_memory_usage_bytes) / sum(machine_memory_bytes) * 100
```

**3. Pods by Namespace**
```promql
sum(kube_pod_info) by (namespace)
```

**4. Pod Status**
```promql
sum(kube_pod_status_phase{phase=~"Pending|Running|Succeeded|Failed|Unknown"}) by (phase)
```

---

### Application Dashboard

**Backend API Dashboard:**

**1. Request Rate**
```promql
sum(rate(http_requests_total{job="backend"}[5m]))
```

**2. Error Rate**
```promql
sum(rate(http_requests_total{job="backend",status=~"5.."}[5m])) / sum(rate(http_requests_total{job="backend"}[5m])) * 100
```

**3. Latency (p95, p99)**
```promql
# P95
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="backend"}[5m])) by (le))

# P99
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job="backend"}[5m])) by (le))
```

**4. Active Connections**
```promql
sum(http_active_connections{job="backend"})
```

---

## 19.6 Community Dashboards

**Import dashboard:**

```
+ → Import
Dashboard ID: 12345 (from grafana.com/dashboards)

Example IDs:
- 315: Kubernetes cluster monitoring
- 1860: Node Exporter Full
- 6417: Kubernetes Deployment Statefulset Daemonset metrics
- 7249: PostgreSQL Database
```

**Search:** https://grafana.com/grafana/dashboards/

**Customize imported dashboard:**
- Add/remove panels
- Change queries
- Add variables

---

## 19.7 Alerting in Grafana

### Alert Rules

**Create alert on panel:**

```
Edit panel → Alert tab → Create alert

Condition:
- WHEN avg() OF query(A, 5m, now) IS ABOVE 80

Evaluate every: 1m
For: 5m (pending period)

Annotations:
- summary: High CPU usage
- description: CPU usage is {{ $values.A }}%
```

**Alert states:**
- **OK:** Condition false
- **Pending:** Condition true, waiting for `for` duration
- **Alerting:** Firing (sent to contact points)

---

### Contact Points

**Configuration → Alerting → Contact points**

**Slack:**
```
Name: slack-devops
Type: Slack
Webhook URL: https://hooks.slack.com/services/...
Channel: #devops-alerts
```

**Email:**
```
Name: email-oncall
Type: Email
Addresses: oncall@company.com,team@company.com
```

**PagerDuty:**
```
Name: pagerduty-critical
Type: PagerDuty
Integration Key: YOUR_INTEGRATION_KEY
```

---

### Notification Policies

**Route alerts to contact points:**

```
Default contact point: email-oncall

Specific routing:
- Label: severity = critical
  Contact point: pagerduty-critical

- Label: severity = warning
  Contact point: slack-devops
```

📖 **Praktika:** Labor 6, Harjutus 4 - Grafana dashboards + alerts

---

## 19.8 Advanced Features

### Annotations

**Mark events on graphs:**

```
Dashboard settings → Annotations → Add annotation

Data source: Prometheus
Query: ALERTS{alertname="DeploymentEvent"}

Result: Vertical lines on graph showing deployments
```

**Use case:** Correlate deployments with metric changes

---

### Dashboard Links

**Link dashboards:**

```
Dashboard settings → Links → Add link

Type: Dashboard
Title: Node Details
Dashboard: Node Exporter Full
Include current time range: ✅
Include current variables: ✅
```

**Use case:** Navigate from cluster overview → node details

---

### Playlist

**Auto-rotate dashboards:**

```
Dashboards → Playlists → New playlist

Add dashboards:
- Cluster Overview (interval: 30s)
- Application Metrics (interval: 30s)
- PostgreSQL Stats (interval: 30s)

Start playlist
```

**Use case:** NOC display (TV screen showing metrics)

---

## 19.9 Best Practices

### 1. Dashboard Organization

```
Folders:
- Infrastructure (cluster, nodes)
- Applications (backend, frontend)
- Databases (postgres, redis)
- Business Metrics (sales, signups)
```

---

### 2. Panel Titles and Descriptions

```yaml
# ✅ GOOD
Title: "Backend API - Request Rate (req/s)"
Description: "HTTP requests per second, aggregated across all pods"

# ❌ BAD
Title: "Requests"
Description: ""
```

---

### 3. Consistent Colors

```
Success (2xx): Green
Client errors (4xx): Yellow
Server errors (5xx): Red
```

---

### 4. Use Templates

```
# Single dashboard for all environments
Variables:
- $environment (dev, staging, prod)
- $namespace

Queries:
kube_pod_info{namespace="$namespace"}
```

---

### 5. Add Legends

```
Query: rate(http_requests_total[5m])
Legend: {{pod}} - {{status}}

Result:
- backend-abc123 - 200
- backend-abc123 - 500
- backend-def456 - 200
```

---

## 19.10 Grafana vs Kibana vs Graylog

| Kriteerium | Grafana | Kibana (ELK) | Graylog |
|------------|---------|--------------|---------|
| **Focus** | Metrics | Logs + Search | Logs |
| **Data source** | Prometheus, Loki, etc. | Elasticsearch | MongoDB + Elasticsearch |
| **Primary use** | Dashboards | Log analysis | Log management |
| **Learning curve** | Easy | Medium | Medium |
| **Best for** | Time-series metrics | Full-text log search | Centralized logging |

**Common setup:**
- **Grafana:** Metrics dashboards (Prometheus)
- **Graylog:** Log aggregation and search
- **Both:** Alerts (metrics + log patterns)

---

## Kokkuvõte

**Grafana:**
- Visualization platform (Prometheus, Loki, databases)
- Interactive dashboards (time series, gauges, tables)
- Variables and templating (dynamic dashboards)
- Alerting (alternative to AlertManager)
- Community dashboards (import from grafana.com)

**Dashboard creation:**
- Add data source (Prometheus)
- Add panels (queries, visualization type)
- Configure variables ($namespace, $pod)
- Set up alerts (contact points, notification policies)

**Best practices:**
- Organize in folders
- Use descriptive titles
- Consistent colors (green/yellow/red)
- Template dashboards (variables)
- Import community dashboards (customize)

---

**DevOps Vaatenurk:**

```bash
# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Get admin password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d

# Backup dashboards (JSON)
curl -H "Authorization: Bearer YOUR_API_KEY" http://localhost:3000/api/dashboards/db/my-dashboard > dashboard-backup.json
```

---

**Järgmised Sammud:**
**Peatükk 20A:** Graylog (comprehensive log management)

📖 **Praktika:** Labor 6 - Grafana dashboards, alerts, templates
