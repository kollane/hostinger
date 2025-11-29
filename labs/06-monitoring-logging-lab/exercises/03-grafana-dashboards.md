# Harjutus 3: Grafana Dashboards

**Kestus:** 60 minutit
**Eesmärk:** Loo custom Grafana dashboard'e user-service ja Kubernetes cluster metrics'e visualiseerimiseks.

---

## 📋 Ülevaade

Selles harjutuses õpime kasutama **Grafana** - võimsat open-source visualization platform'i. Grafana on juba installitud Exercise 1's (osa kube-prometheus-stack'ist).

**Loome:**
- Cluster Overview dashboard (CPU, memory, pods)
- User-Service dashboard (requests, latency, errors)
- Multi-environment comparison dashboard
- Variables (environment selector)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Ligi pääseda Grafana UI'le
- ✅ Konfigureerida Prometheus data source
- ✅ Luua custom dashboard'e
- ✅ Kasutada erinevaid panel types (Graph, Stat, Gauge, Table)
- ✅ Kirjutada PromQL queries Grafana's
- ✅ Luua dashboard variables (templating)
- ✅ Importida pre-built dashboards
- ✅ Exportida ja jagada dashboards (JSON)

---

## 🏗️ Grafana Arhitektuur

```
┌────────────────────────────────────────────────────────┐
│             User Browser                               │
│      http://localhost:3001                             │
└──────────────────┬─────────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────────┐
│        Grafana (monitoring namespace)                  │
│                                                        │
│  ┌──────────────────────────────────────────────┐     │
│  │  Dashboard Renderer                          │     │
│  │  - Executes PromQL queries                   │     │
│  │  - Renders panels (graphs, tables, etc)     │     │
│  │  - Supports variables ($environment)         │     │
│  └──────────────────┬───────────────────────────┘     │
│                     │ PromQL queries                   │
│                     ▼                                  │
│  ┌──────────────────────────────────────────────┐     │
│  │  Data Sources                                │     │
│  │  - Prometheus (primary)                      │     │
│  │  - Loki (logs - Exercise 5)                  │     │
│  └──────────────────┬───────────────────────────┘     │
└────────────────────┼────────────────────────────────────┘
                     │
                     ▼
          ┌──────────────────┐
          │   Prometheus     │
          │   Time-series DB │
          └──────────────────┘
```

---

## 📝 Sammud

### Samm 1: Ligipääs Grafana UI'le

Grafana on installitud kube-prometheus-stack'iga (Exercise 1).

```bash
# Port-forward Grafana service
kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80
```

**Ava brauseris:** `http://localhost:3001`

**Login credentials:**
- **Username:** `admin`
- **Password:** `admin123` (seadistasime Exercise 1 values.yaml'is)

**Esimesel sisselogimisel:**
- Grafana küsib, kas tahad password'i muuta
- Kliki "Skip" (lab jaoks)

---

### Samm 2: Kontrolli Prometheus Data Source

Grafana peab olema ühendatud Prometheus'ega.

**Grafana UI:**

1. Kliki **Configuration** (⚙️) → **Data Sources**
2. Peaks nägema "Prometheus" data source'i (automaatselt configured)
3. Kliki **Prometheus**
4. Kontrolli settings:
   - **URL:** `http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090`
   - **Access:** Server (default)
5. Kliki **Save & Test**

**Oodatav vastus:** "Data source is working"

**Kui data source puudub:**

```yaml
# Add manually:
# Name: Prometheus
# URL: http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090
# Access: Server
```

---

### Samm 3: Loo Esimene Dashboard - Cluster Overview

**Grafana UI:**

1. Kliki **Create** (+) → **Dashboard**
2. Kliki **Add a new panel**

---

#### Panel 1: CPU Usage per Node

**Panel settings:**

1. **Query:**
   ```promql
   sum by (node) (rate(node_cpu_seconds_total{mode!="idle"}[5m]))
   ```

2. **Legend:**
   - Format: `{{node}}`

3. **Panel options** (paremas menüüs):
   - **Title:** `CPU Usage per Node`
   - **Description:** `CPU utilization (0.0 = 0%, 1.0 = 100%)`

4. **Visualization:**
   - Type: **Time series** (default)
   - **Draw style:** Lines
   - **Fill opacity:** 10

5. **Axis:**
   - **Unit:** Misc → Percent (0-1.0)
   - **Min:** 0
   - **Max:** 1

6. Kliki **Apply**

---

#### Panel 2: Memory Usage per Namespace

1. Kliki **Add panel** (üleval paremal)

2. **Query:**
   ```promql
   sum by (namespace) (container_memory_usage_bytes) / 1024 / 1024 / 1024
   ```

3. **Panel options:**
   - **Title:** `Memory Usage per Namespace`
   - **Unit:** Data → GiB

4. **Visualization:**
   - Type: **Bar gauge**
   - **Orientation:** Horizontal

5. **Legend:** `{{namespace}}`

6. Kliki **Apply**

---

#### Panel 3: Pod Count per Namespace

1. **Add panel**

2. **Query:**
   ```promql
   count by (namespace) (kube_pod_info)
   ```

3. **Panel options:**
   - **Title:** `Pod Count per Namespace`

4. **Visualization:**
   - Type: **Stat**
   - **Graph mode:** None
   - **Text mode:** Value and name

5. **Legend:** `{{namespace}}`

6. Kliki **Apply**

---

#### Panel 4: Cluster CPU Total

1. **Add panel**

2. **Query:**
   ```promql
   sum(rate(node_cpu_seconds_total{mode!="idle"}[5m]))
   ```

3. **Panel options:**
   - **Title:** `Cluster CPU Usage`
   - **Unit:** Percent (0-1.0)

4. **Visualization:**
   - Type: **Gauge**
   - **Show threshold markers:** On
   - **Thresholds:**
     - Green: 0 - 0.5 (0-50%)
     - Yellow: 0.5 - 0.8 (50-80%)
     - Red: 0.8+ (80%+)

5. Kliki **Apply**

---

### Samm 4: Salvesta Dashboard

1. Kliki **Save dashboard** (üleval paremal, disk ikoon)
2. **Dashboard name:** `Cluster Overview`
3. **Folder:** General
4. Kliki **Save**

---

### Samm 5: Loo User-Service Dashboard

**Create new dashboard:**

1. Kliki **Create** (+) → **Dashboard**
2. **Add panels:**

---

#### Panel 1: Request Rate per Environment

```promql
sum by (environment) (rate(http_requests_total[5m]))
```

- **Title:** `Request Rate (req/s)`
- **Visualization:** Time series
- **Unit:** Misc → req/s (requests per second)
- **Legend:** `{{environment}}`

---

#### Panel 2: Request Latency (P95)

```promql
histogram_quantile(0.95,
  sum by (environment, le) (rate(http_request_duration_seconds_bucket[5m]))
)
```

- **Title:** `Request Latency P95`
- **Visualization:** Time series
- **Unit:** Time → seconds (s)
- **Legend:** `{{environment}} P95`

---

#### Panel 3: Error Rate

```promql
sum by (environment) (rate(http_requests_total{status=~"5.."}[5m]))
```

- **Title:** `Server Error Rate (5xx)`
- **Visualization:** Time series
- **Unit:** Misc → req/s
- **Legend:** `{{environment}} errors`
- **Thresholds:**
  - Green: 0 - 1
  - Yellow: 1 - 5
  - Red: 5+

---

#### Panel 4: Memory Usage

```promql
sum by (environment) (nodejs_heap_size_used_bytes) / 1024 / 1024
```

- **Title:** `Heap Memory Usage`
- **Visualization:** Time series
- **Unit:** Data → MiB
- **Legend:** `{{environment}}`

---

#### Panel 5: Request Count (Total)

```promql
sum by (environment) (http_requests_total)
```

- **Title:** `Total Requests`
- **Visualization:** Stat
- **Graph mode:** Area
- **Color mode:** Value
- **Legend:** `{{environment}}`

---

### Samm 6: Lisa Dashboard Variables

Variables võimaldavad dashboard'e filtreerimist (nt. environment selector).

**Dashboard Settings:**

1. Kliki **Dashboard settings** (⚙️ üleval paremal)
2. Kliki **Variables**
3. Kliki **Add variable**

**Variable settings:**

- **Name:** `environment`
- **Type:** Query
- **Label:** Environment
- **Data source:** Prometheus
- **Query:**
  ```promql
  label_values(http_requests_total, environment)
  ```
- **Regex:** (tühi)
- **Multi-value:** On (luba valida mitu keskkonda)
- **Include All option:** On

Kliki **Add** ja seejärel **Save dashboard**

---

### Samm 7: Kasuta Variables Panel Queries'tes

Nüüd muuda panel queries'd kasutama `$environment` variable'it.

**Muuda Panel 1 (Request Rate):**

1. Edit panel (kliki panel title → Edit)
2. Muuda query:
   ```promql
   sum by (environment) (rate(http_requests_total{environment=~"$environment"}[5m]))
   ```
3. Apply

Tee sama kõigile teistele panel'itele.

**Dashboard top bar'is peaks nüüd olema dropdown:** Environment: [All] [development] [staging] [production]

Vali "development" ja dashboard näitab ainult development metrics'eid!

---

### Samm 8: Importi Pre-Built Dashboard

Grafana community pakub tuhandeid valmis dashboards'e.

**Import Kubernetes Cluster Monitoring dashboard:**

1. Kliki **Create** (+) → **Import**
2. **Dashboard ID:** `15757` (Kubernetes Cluster Monitoring)
3. Kliki **Load**
4. **Prometheus data source:** Prometheus
5. Kliki **Import**

**Popular dashboards:**
- **15757** - Kubernetes Cluster Monitoring
- **15758** - Kubernetes / Views / Global
- **15759** - Kubernetes / Views / Namespaces
- **15760** - Kubernetes / Views / Pods

---

### Samm 9: Organiseeri Dashboards Folders'isse

1. Kliki **Dashboards** (neli ruutu ikoon vasakul)
2. Kliki **New folder**
3. **Folder name:** `Lab 6 - Monitoring`
4. Kliki **Create**

**Move dashboards to folder:**

1. Dashboards listis, hover over dashboard
2. Kliki **Move**
3. Vali folder `Lab 6 - Monitoring`

---

### Samm 10: Ekspordi Dashboard JSON'ina

Dashboard'e saab jagada JSON format'is.

1. Ava dashboard
2. Kliki **Dashboard settings** (⚙️)
3. Kliki **JSON Model** (vasakul menüüs)
4. Kliki **Copy to Clipboard**
5. Salvesta file'ina: `user-service-dashboard.json`

**Import dashboard JSON'ist:**

1. **Create** (+) → **Import**
2. **Upload JSON file** või paste JSON
3. Kliki **Load** → **Import**

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Grafana UI accessible `http://localhost:3001`
- [ ] Prometheus data source configured ja töötab
- [ ] Cluster Overview dashboard loodud (4 panels)
- [ ] User-Service dashboard loodud (5 panels)
- [ ] Dashboard variables töötavad ($environment)
- [ ] Pre-built dashboard importitud (15757)
- [ ] Dashboards organiseeritud folder'isse
- [ ] Dashboard exportitud JSON'ina

### Verifitseerimine

```bash
# 1. Kontrolli Grafana pod
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# 2. Test Grafana API
curl -s http://admin:admin123@localhost:3001/api/dashboards/home | jq '.meta.slug'

# 3. List dashboards
curl -s http://admin:admin123@localhost:3001/api/search | jq '.[] | {title: .title, uid: .uid}'
```

---

## 🎨 Dashboard Best Practices

### Panel Organization

```
┌─────────────────────────────────────────────────────┐
│  Dashboard: User Service Overview                   │
├─────────────────────────────────────────────────────┤
│  Variables: [$environment] [$namespace]             │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Row 1: Key Metrics (Stat panels)                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │ Total   │ │ Req/s   │ │ Errors  │ │ Latency │  │
│  │ Requests│ │         │ │         │ │ P95     │  │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘  │
│                                                     │
│  Row 2: Time Series (Trends)                       │
│  ┌───────────────────────────────────────────────┐ │
│  │  Request Rate Over Time                       │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  Row 3: Detailed Metrics                          │
│  ┌──────────────────────┐ ┌──────────────────────┐ │
│  │  Latency Distribution│ │  Error Rate          │ │
│  └──────────────────────┘ └──────────────────────┘ │
│                                                     │
│  Row 4: Resources                                  │
│  ┌──────────────────────┐ ┌──────────────────────┐ │
│  │  Memory Usage        │ │  CPU Usage           │ │
│  └──────────────────────┘ └──────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### Color Schemes

✅ **Thresholds:**
- **Green:** Healthy (0-50% resource usage, <5% errors)
- **Yellow:** Warning (50-80% resources, 5-10% errors)
- **Red:** Critical (>80% resources, >10% errors)

✅ **Consistent colors per environment:**
- Development: Blue
- Staging: Orange
- Production: Red

---

## 🔍 Troubleshooting

### Probleem: "Data source is not working"

**Lahendus:**

```bash
# Kontrolli Prometheus service
kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus

# Test Prometheus API Grafana pod'ist
kubectl exec -n monitoring deployment/prometheus-grafana -- \
  curl -s http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090/api/v1/query?query=up

# Reconfigure data source URL:
# http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090
```

---

### Probleem: Panel näitab "No data"

**Põhjused:**
1. PromQL query on vale
2. Metrics pole veel olemas
3. Time range on vale

**Lahendus:**

1. **Test query Prometheus UI's:**
   ```bash
   # Port-forward Prometheus
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
   # Test query: http://localhost:9090
   ```

2. **Kontrolli time range:**
   - Dashboard top right: Time range picker
   - Vali "Last 1 hour" või "Last 6 hours"

3. **Kontrolli query syntax:**
   - Grafana panel → Edit → Query inspector
   - Vaata error messages

---

### Probleem: Variables ei tööta

**Lahendus:**

```bash
# Kontrolli, kas metrics omavad label 'environment'
curl -s 'http://localhost:9090/api/v1/query?query=http_requests_total' | \
  jq '.data.result[0].metric'

# Kui label puudub, lisa ServiceMonitor relabeling (Exercise 2)
```

---

## 📚 Mida Sa Õppisid?

✅ **Grafana UI navigation**
  - Data sources management
  - Dashboard creation
  - Panel configuration

✅ **Visualization types**
  - Time series (graphs)
  - Stat (single values)
  - Gauge (progress indicators)
  - Bar gauge (comparisons)
  - Table (detailed data)

✅ **PromQL in Grafana**
  - Query editor
  - Query variables ($environment)
  - Legend formatting ({{label}})

✅ **Dashboard management**
  - Variables (filters)
  - Folders (organization)
  - Export/import (sharing)
  - Templating

---

## 🚀 Järgmised Sammud

**Exercise 4: Alerting** - Seadista alert rules ja notifications:
- PrometheusRule CRD
- Alert thresholds
- AlertManager configuration
- Slack integration

```bash
cat exercises/04-alerting.md
```

---

## 💡 Dashboard Design Tips

✅ **Above the fold:** Kõige olulisemad metrics üleval (key metrics)
✅ **Drill-down:** Üldisest (overview) detailideni (specific metrics)
✅ **Consistent layout:** Sama tüüpi panels samal real
✅ **Color coding:** Kasuta värve semantiliselt (red = bad, green = good)
✅ **Annotations:** Lisa märkused deployment'idele, incident'idele
✅ **Variables:** Lisa filters (environment, namespace, service)
✅ **Refresh rate:** Auto-refresh production dashboards (30s-1m)

---

**Õnnitleme! Grafana dashboards on valmis! 📊📈**

**Kestus:** 60 minutit
**Järgmine:** Exercise 4 - Alerting
