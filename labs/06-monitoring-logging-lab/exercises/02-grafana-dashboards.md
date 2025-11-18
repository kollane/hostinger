# Harjutus 2: Grafana Dashboards

**Kestus:** 60 minutit
**Eesmärk:** Luua Grafana dashboards metrics'ide visualiseerimiseks

---

## 📋 Ülevaade

Selles harjutuses õpid kasutama **Grafana** - metrics visualiseerimise ja monitoring platvormi. Loome dashboards'e Kubernetes cluster'i ja rakenduste jälgimiseks, kasutades Prometheus'st pärit metrics'eid.

**Grafana** võimaldab luua interaktiivseid dashboards'e, kus saab visualiseerida time-series andmeid graafikute, gauge'ide, tabelite ja alerting'uga. See on de facto standard Prometheus metrics'ide visualiseerimiseks.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Avada ja kasutada Grafana UI'd
- ✅ Lisada Prometheus data source'i
- ✅ Luua custom dashboards'e
- ✅ Lisada ja konfigureerida panel'eid
- ✅ Kasutada PromQL päringuid Grafana'sImportida valmis dashboards'e
- ✅ Kasutada template variables
- ✅ Seadistada dashboard alerting'ut

---

## 🏗️ Arhitektuur

```
┌────────────────────────────────────────────────────┐
│         Kubernetes Cluster                         │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  Grafana                                     │ │
│  │  - UI (port 3000)                            │ │
│  │  - Dashboards                                │ │
│  │  - Alerting                                  │ │
│  └────────┬─────────────────────────────────────┘ │
│           │ queries (PromQL)                      │
│           ▼                                        │
│  ┌──────────────────────────────────────────────┐ │
│  │  Prometheus                                  │ │
│  │  - Data source                               │ │
│  │  - Time-series DB                            │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
└────────────────────────────────────────────────────┘

User → Grafana UI → Query Prometheus → Display metrics
```

---

## 📝 Sammud

### Samm 1: Ava Grafana UI (5 min)

**Port forward Grafana service:**

```bash
# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Ava brauseris:
# http://localhost:3000
```

**Login Grafana'sse:**

- **Username:** `admin`
- **Password:** `admin` (või `prometheus-values.yaml`'is määratud)

**Esimene login:**

1. Grafana küsib password'i muutmist
2. Vali uus password või "Skip"
3. Welcome to Grafana!

---

### Samm 2: Kontrolli Prometheus Data Source (5 min)

**Prometheus data source on automaatselt konfigureeritud (kube-prometheus-stack):**

1. Grafana UI → **☰ (Menu)** → **Connections** → **Data sources**
2. Peaks näitama: **Prometheus**
3. Kliki "Prometheus"
4. Kontrolli seadeid:
   - **URL:** `http://prometheus-kube-prometheus-prometheus.monitoring:9090`
   - **Access:** Server (default)
   - **Status:** ✅ Data source is working

**Testi data source:**

1. Scroll down → **Save & test**
2. Peaks näitama: ✅ "Data source is working"

---

### Samm 3: Exploreeri Built-in Dashboards (10 min)

**kube-prometheus-stack kaasas valmis dashboards:**

1. Grafana UI → **☰ (Menu)** → **Dashboards**
2. Näed foldereid:
   - **General**
   - **Kubernetes / Compute Resources**
   - **Kubernetes / Networking**
   - **Kubernetes / Storage**

**Vaata dashboard'e:**

**1. Kubernetes / Compute Resources / Cluster:**

- Overall cluster CPU usage
- Overall cluster memory usage
- Pod count
- CPU requests vs limits

**2. Kubernetes / Compute Resources / Namespace (Workloads):**

- CPU usage per namespace
- Memory usage per namespace
- Network I/O per namespace

**3. Node Exporter / Nodes:**

- CPU usage per node
- Memory usage per node
- Disk I/O
- Network traffic

**Exploreeri dashboard'e:**

- Vaata erinevaid panele
- Muuda time range (ülemine parem nurk)
- Testi zoom'i (drag graafikul)
- Vaata panel query'sid (Edit panel → Query)

---

### Samm 4: Loo Uus Dashboard (15 min)

**Loo custom dashboard Kubernetes pod'ide jaoks:**

**1. Loo uus dashboard:**

1. Grafana UI → **☰ → Dashboards**
2. Kliki **New → New Dashboard**
3. Kliki **Add visualization**
4. Vali data source: **Prometheus**

**2. Lisa esimene panel - Pod Count:**

**Query:**
```promql
count(kube_pod_info)
```

**Panel settings:**
- **Title:** Pod Count
- **Visualization:** Stat
- **Unit:** none
- **Color scheme:** Green

Kliki **Apply**

**3. Lisa teine panel - Pod Memory Usage:**

Kliki **Add → Visualization**

**Query:**
```promql
sum(container_memory_usage_bytes{pod=~"user-service.*"}) / 1024 / 1024
```

**Panel settings:**
- **Title:** User Service Memory (MB)
- **Visualization:** Time series
- **Unit:** megabytes (MB)
- **Legend:** {{pod}}

Kliki **Apply**

**4. Lisa kolmas panel - Pod CPU Usage:**

Kliki **Add → Visualization**

**Query:**
```promql
sum(rate(container_cpu_usage_seconds_total{pod=~"user-service.*"}[5m])) * 100
```

**Panel settings:**
- **Title:** User Service CPU (%)
- **Visualization:** Time series
- **Unit:** percent (0-100)
- **Y-axis max:** 100

Kliki **Apply**

**5. Salvesta dashboard:**

1. Kliki **💾 Save dashboard** (ülemine parem nurk)
2. **Name:** My Kubernetes Dashboard
3. **Folder:** General
4. Kliki **Save**

---

### Samm 5: Importi Valmis Dashboard (10 min)

**Grafana.com sisaldab tuhandeid valmis dashboards'e:**

**Importi Kubernetes Cluster Monitoring dashboard:**

1. Grafana UI → **☰ → Dashboards**
2. Kliki **New → Import**
3. **Import via grafana.com:** `15760`
   - (Kubernetes / Views / Global)
4. Kliki **Load**
5. **Prometheus:** Vali "Prometheus" data source
6. Kliki **Import**

**Dashboard on valmis!**

Näed:
- Cluster overview (CPU, Memory, Network)
- Namespace breakdown
- Pod status
- Node status

**Populaarsed Kubernetes dashboards (ID):**

- **15760** - Kubernetes / Views / Global
- **13332** - Kubernetes Cluster Monitoring
- **12114** - Kubernetes / System / CoreDNS
- **7249** - Kubernetes Cluster
- **11663** - Kubernetes Metrics

**Importi mitu dashboard'i:**

```
Import ID:
- 15760 (Global view)
- 13332 (Cluster monitoring)
- 7249 (Kubernetes Cluster)
```

---

### Samm 6: Lisa Template Variables (10 min)

**Template variables** võimaldavad dünaamilisi dashboards'e (filter by namespace, pod, jne).

**Lisa namespace variable:**

1. Ava oma dashboard "My Kubernetes Dashboard"
2. Kliki **⚙️ Dashboard settings** (ülemine parem)
3. Vali **Variables** tab → Kliki **Add variable**

**Variable config:**

- **Name:** `namespace`
- **Type:** Query
- **Data source:** Prometheus
- **Query:**
  ```promql
  label_values(kube_pod_info, namespace)
  ```
- **Refresh:** On time range change
- **Multi-value:** ✅ (lubab mitut valida)
- **Include All option:** ✅

Kliki **Apply**

**Lisa pod variable:**

Kliki **Add variable** uuesti:

- **Name:** `pod`
- **Type:** Query
- **Data source:** Prometheus
- **Query:**
  ```promql
  label_values(kube_pod_info{namespace=~"$namespace"}, pod)
  ```
- **Regex:** `user-service.*` (filter ainult user-service pods)
- **Refresh:** On time range change
- **Multi-value:** ✅

Kliki **Apply**

**Kasuta variables panel'ites:**

1. Tagasi dashboard'ile
2. Edit "User Service Memory" panel
3. Muuda query:
   ```promql
   sum(container_memory_usage_bytes{namespace=~"$namespace", pod=~"$pod"}) by (pod) / 1024 / 1024
   ```
4. Kliki **Apply**

Nüüd saad ülemises menüüs valida namespace ja pod!

---

### Samm 7: Loo Application Dashboard (10 min)

**Loo täielik dashboard rakenduse jaoks:**

**Uus dashboard nimega "User Service Dashboard":**

**Panel 1: Request Rate**
```promql
rate(http_requests_total{service="user-service"}[5m])
```
- Visualization: Time series
- Legend: {{method}} {{path}}

**Panel 2: Request Duration (p95)**
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service="user-service"}[5m]))
```
- Visualization: Time series
- Unit: seconds (s)

**Panel 3: Error Rate**
```promql
rate(http_requests_total{service="user-service", status=~"5.."}[5m])
```
- Visualization: Time series
- Color: Red

**Panel 4: Active Connections**
```promql
sum(nodejs_active_handles_total{service="user-service"})
```
- Visualization: Stat
- Unit: none

**Panel 5: Memory Heap Used**
```promql
nodejs_heap_size_used_bytes{service="user-service"} / 1024 / 1024
```
- Visualization: Gauge
- Unit: megabytes (MB)
- Thresholds: 0-50 (green), 50-80 (yellow), 80-100 (red)

**Panel 6: Event Loop Lag**
```promql
nodejs_eventloop_lag_seconds{service="user-service"}
```
- Visualization: Time series
- Unit: seconds (s)

Salvesta dashboard!

---

### Samm 8: Seadista Dashboard Alerting (5 min)

**Loo alert high memory usage jaoks:**

1. Edit "User Service Memory" panel
2. Kliki **Alert** tab
3. Kliki **Create alert rule from this panel**

**Alert rule:**

- **Rule name:** High Memory Usage - User Service
- **Evaluate every:** 1m
- **For:** 5m
- **Condition:**
  - Query: (juba olemas)
  - Threshold: `> 500` (MB)

**Labels:**
- `severity`: `warning`
- `service`: `user-service`

**Annotations:**
- `summary`: User Service memory usage is above 500MB

Kliki **Save rule and exit**

**Alert notification (Harjutus 5'sseadistame täielikult).**

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Grafana UI:**
  - [ ] Accessible (port-forward 3000)
  - [ ] Logged in (admin)

- [ ] **Data source:**
  - [ ] Prometheus configured
  - [ ] Status: Working

- [ ] **Dashboards:**
  - [ ] My Kubernetes Dashboard (custom)
  - [ ] User Service Dashboard (application)
  - [ ] 3+ imported dashboards (15760, 13332, 7249)

- [ ] **Variables:**
  - [ ] namespace variable
  - [ ] pod variable
  - [ ] Working in panels

- [ ] **Panels:**
  - [ ] Pod Count (Stat)
  - [ ] Memory Usage (Time series)
  - [ ] CPU Usage (Time series)
  - [ ] Request Rate (app metrics)

- [ ] **Alerting:**
  - [ ] Alert rule created (High Memory)

---

## 🐛 Troubleshooting

### Probleem 1: Prometheus data source ei tööta

**Sümptom:**

"Data source is not working. Check your configuration."

**Diagnoos:**

```bash
# Kontrolli Prometheus service
kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus

# Kontrolli URL Grafana data source's:
# http://prometheus-kube-prometheus-prometheus.monitoring:9090
```

**Lahendus:**

1. Grafana → Data sources → Prometheus
2. **URL:** `http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090`
3. **Save & test**

---

### Probleem 2: Panel'is "No data"

**Sümptom:**

Panel näitab "No data" või tühja graafikut.

**Diagnoos:**

1. **Edit panel** → Query tab
2. Viska **Query inspector** (Query → Inspector)
3. Vaata Prometheus response

**Võimalikud põhjused:**

1. **Query vale:**
   - Testi query Prometheus UI's
   - Kontrolli label'eid

2. **Time range vale:**
   - Muuda time range (last 15min → last 6h)

3. **Metrics puuduvad:**
   - Application ei eksponeerib metrics'eid
   - ServiceMonitor puudub

**Lahendus:**

```promql
# Testi lihtsam query:
up{job="prometheus"}

# Kui see töötab, siis Prometheus data source OK
```

---

### Probleem 3: Imported dashboard tühi

**Sümptom:**

Importisin dashboard, aga kõik panelid on tühjad.

**Põhjus:** Vale Prometheus data source.

**Lahendus:**

1. Dashboard settings (⚙️)
2. **Variables** tab
3. Kontrolli `datasource` variable
4. Vali **Prometheus**
5. Salvesta

---

## 🎓 Õpitud Mõisted

### Grafana:
- **Dashboard:** Kollektsioon panel'eid (visualizations)
- **Panel:** Individuaalne visualisatsioon (graph, stat, table)
- **Data source:** Andmete allikas (Prometheus, Loki, InfluxDB)
- **Query:** PromQL või muu query language
- **Time range:** Ajaperiood metrics'ide jaoks

### Visualizations:
- **Time series:** Line graph (metrics over time)
- **Stat:** Single value (current value)
- **Gauge:** Meter (0-100%)
- **Bar chart:** Bars (comparison)
- **Table:** Tabular data
- **Heatmap:** Color-coded matrix

### Variables:
- **Query variable:** Dynamic values from data source
- **Custom variable:** Static values (comma-separated)
- **Interval variable:** Time intervals ($__interval)
- **$variable syntax:** Use in queries (`namespace=~"$namespace"`)

### Alerting:
- **Alert rule:** Condition + evaluation interval
- **Threshold:** Value limit (> 500 MB)
- **For duration:** Kui kaua condition peab olema true (5m)
- **Notification:** Kuhu alert saadetakse (Slack, email)

---

## 💡 Parimad Tavad

1. **Organize dashboards folders** - Grupeeri teemalised dashboards (K8s, Apps, Logs)
2. **Use template variables** - Dünaamilised dashboards (filter by namespace, pod)
3. **Set meaningful titles** - Selged panel nimed ("User Service Memory Usage")
4. **Add descriptions** - Panel description (kuidas interpreteerida)
5. **Color thresholds** - Green/yellow/red (0-50/50-80/80-100)
6. **Legend formatting** - `{{pod}}` või `{{namespace}}/{{pod}}`
7. **Unit selection** - Vali õige unit (MB, %, seconds)
8. **Time range presets** - Last 15m, 1h, 6h, 24h
9. **Refresh interval** - Auto-refresh (5s, 10s, 30s)
10. **Export/import JSON** - Backup dashboards (Settings → JSON Model)

---

## 🔗 Järgmine Samm

Nüüd oskad luua Grafana dashboards'e! Järgmises harjutuses lisame **rakenduse metrics'id** - User Service'le `/metrics` endpoint prom-client library'ga.

**Jätka:** [Harjutus 3: Application Metrics](03-application-metrics.md)

---

## 📚 Viited

### Grafana:
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)
- [Panel Types](https://grafana.com/docs/grafana/latest/panels-visualizations/)

### Dashboards:
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Kubernetes Dashboards](https://grafana.com/grafana/dashboards/?search=kubernetes)

### PromQL:
- [PromQL for Grafana](https://grafana.com/docs/grafana/latest/datasources/prometheus/query-editor/)

---

**Õnnitleme! Oskad nüüd luua Grafana dashboards'e! 📊📈**
