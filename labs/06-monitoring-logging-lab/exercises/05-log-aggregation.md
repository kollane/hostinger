# Harjutus 5: Log Aggregation with Loki

**Kestus:** 60 minutit
**Eesmärk:** Implementeeri log aggregation Loki + Promtail'iga ja õpi LogQL query language.

---

## 📋 Ülevaade

Selles harjutuses seadistame **Grafana Loki** - log aggregation system, mida nimetatakse "Prometheus for logs". Loki on kerge, kuluefektiivne alternatiiv ELK/EFK stack'ile.

**Loki vs Elasticsearch:**
- **Loki:** Indexeerib ainult labels (not full-text), madalam resource usage
- **Elasticsearch:** Indexeerib kogu log content, suurem resource usage

**Stack komponendid:**
- **Loki** - Log storage ja query engine
- **Promtail** - Log collector (DaemonSet igal node'il)
- **Grafana** - Log visualization (juba installitud)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Paigaldada Loki + Promtail Helm chart'iga
- ✅ Mõista Loki arhitektuuri (labels vs indexed data)
- ✅ Konfigureerida Promtail log collection
- ✅ Kirjutada LogQL queries
- ✅ Integreerida Loki Grafana'ga
- ✅ Correlate logs ja metrics
- ✅ Debuggida probleeme logide abil
- ✅ Filtreerida logs label'ite ja regex'iga

---

## 🏗️ Loki Arhitektuur

```
┌────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster                            │
│                                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Node 1     │  │   Node 2     │  │   Node 3     │    │
│  │              │  │              │  │              │    │
│  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │    │
│  │  │ Pod    │  │  │  │ Pod    │  │  │  │ Pod    │  │    │
│  │  │ logs → │  │  │  │ logs → │  │  │  │ logs → │  │    │
│  │  └────┬───┘  │  │  └────┬───┘  │  │  └────┬───┘  │    │
│  │       │      │  │       │      │  │       │      │    │
│  │  /var/log/   │  │  /var/log/   │  │  /var/log/   │    │
│  │  pods/*.log  │  │  pods/*.log  │  │  pods/*.log  │    │
│  │       │      │  │       │      │  │       │      │    │
│  │       ▼      │  │       ▼      │  │       ▼      │    │
│  │  ┌─────────┐ │  │  ┌─────────┐ │  │  ┌─────────┐ │    │
│  │  │Promtail │ │  │  │Promtail │ │  │  │Promtail │ │    │
│  │  │DaemonSet│ │  │  │DaemonSet│ │  │  │DaemonSet│ │    │
│  │  └────┬────┘ │  │  └────┬────┘ │  │  └────┬────┘ │    │
│  └───────┼──────┘  └───────┼──────┘  └───────┼──────┘    │
│          │                 │                 │            │
│          └─────────────────┼─────────────────┘            │
│                            │ push logs (HTTP)             │
│                            ▼                              │
│                  ┌─────────────────┐                      │
│                  │      Loki       │                      │
│                  │   (monitoring)  │                      │
│                  │                 │                      │
│                  │  - Index labels │                      │
│                  │  - Store logs   │                      │
│                  │  - Query engine │                      │
│                  └────────┬────────┘                      │
│                           │ LogQL queries                 │
│                           ▼                               │
│                  ┌─────────────────┐                      │
│                  │    Grafana      │                      │
│                  │  - Explore logs │                      │
│                  │  - Dashboards   │                      │
│                  └─────────────────┘                      │
└────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Lisa Grafana Helm Repository

```bash
# Lisa Loki Helm repo
helm repo add grafana https://grafana.github.io/helm-charts

# Update
helm repo update

# Kontrolli
helm search repo grafana/loki-stack
```

**Oodatav väljund:**
```
NAME                 CHART VERSION  APP VERSION
grafana/loki-stack   2.9.11         v2.9.2
```

---

### Samm 2: Loo Loki Values File

Loome custom values faili Loki stack'i jaoks.

**Loo fail `loki-values.yaml`:**

```bash
vim loki-values.yaml
```

**Fail sisu:**

```yaml
# Loki Stack Configuration
# Includes: Loki + Promtail

# Loki configuration
loki:
  enabled: true

  # Persistence (disable for lab)
  persistence:
    enabled: false

  # Resources
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

  # Configuration
  config:
    # Loki listens on port 3100
    server:
      http_listen_port: 3100

    # Limits
    limits_config:
      enforce_metric_name: false
      reject_old_samples: true
      reject_old_samples_max_age: 168h  # 7 days
      ingestion_rate_mb: 10
      ingestion_burst_size_mb: 20

    # Schema config (how logs are stored)
    schema_config:
      configs:
        - from: 2023-01-01
          store: boltdb-shipper
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 24h

    # Storage config
    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/index
        cache_location: /loki/cache
        shared_store: filesystem
      filesystem:
        directory: /loki/chunks

    # Compactor (cleanup old data)
    compactor:
      working_directory: /loki/compactor
      shared_store: filesystem
      retention_enabled: true
      retention_delete_delay: 2h

# Promtail configuration (log collector)
promtail:
  enabled: true

  # Resources
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi

  # Configuration
  config:
    # Promtail server
    server:
      http_listen_port: 9080

    # Where to send logs
    clients:
      - url: http://{{ .Release.Name }}-loki:3100/loki/api/v1/push

    # Scrape configs (what logs to collect)
    scrape_configs:
      # Kubernetes pods logs
      - job_name: kubernetes-pods
        pipeline_stages:
          # Extract metadata
          - cri: {}

        kubernetes_sd_configs:
          - role: pod

        # Relabeling (add labels to logs)
        relabel_configs:
          # Namespace
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace

          # Pod name
          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod

          # Container name
          - source_labels: [__meta_kubernetes_pod_container_name]
            target_label: container

          # App label
          - source_labels: [__meta_kubernetes_pod_label_app]
            target_label: app

          # Environment label (if exists)
          - source_labels: [__meta_kubernetes_namespace]
            target_label: environment
            regex: (.*)
            replacement: $1

          # Only scrape running pods
          - source_labels: [__meta_kubernetes_pod_phase]
            action: keep
            regex: Running

# Grafana integration (we already have Grafana)
grafana:
  enabled: false  # We use existing Grafana from kube-prometheus-stack

# Fluent Bit (alternative to Promtail)
fluent-bit:
  enabled: false
```

**Salvesta:** `Esc`, `:wq`, `Enter`

---

### Samm 3: Installi Loki Stack

```bash
# Installi Loki + Promtail
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki-values.yaml \
  --wait \
  --timeout 5m

# Kontrolli pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=loki
kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail
```

**Oodatav väljund:**
```
NAME                    READY   STATUS    AGE
loki-0                  1/1     Running   2m
loki-promtail-xxxxx     1/1     Running   2m  (DaemonSet - 1 per node)
```

---

### Samm 4: Kontrolli Loki Service

```bash
kubectl get svc -n monitoring -l app.kubernetes.io/name=loki
```

**Oodatav väljund:**
```
NAME         TYPE        CLUSTER-IP      PORT(S)
loki         ClusterIP   10.96.x.x       3100/TCP
loki-headless ClusterIP  None            3100/TCP
```

---

### Samm 5: Test Loki API

```bash
# Port-forward Loki
kubectl port-forward -n monitoring svc/loki 3100:3100

# Test health endpoint
curl http://localhost:3100/ready

# Test metrics endpoint
curl http://localhost:3100/metrics
```

**Oodatav vastus (ready):**
```
ready
```

---

### Samm 6: Lisa Loki Data Source Grafana'sse

**Grafana UI:**

1. Port-forward Grafana (kui ei ole juba running):
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80
   ```

2. Ava brauseris: `http://localhost:3001`

3. **Configuration** (⚙️) → **Data Sources**

4. **Add data source**

5. Vali **Loki**

**Data source settings:**

- **Name:** `Loki`
- **URL:** `http://loki:3100`
- **Access:** Server (default)

Kliki **Save & Test**

**Oodatav vastus:** "Data source connected and labels found"

---

### Samm 7: Explore Logs Grafana'ga

**Grafana UI:**

1. Kliki **Explore** (compass ikoon vasakul)

2. Üleval vasakul data source dropdown: vali **Loki**

3. **Log browser** avaneb

---

#### Query 1: Kõik logs development namespace'ist

```logql
{namespace="development"}
```

**Tulemus:** Kõik log read development namespace'ist

---

#### Query 2: Logs user-service'st

```logql
{namespace="production", app="user-service"}
```

---

#### Query 3: Filter ERROR logs

```logql
{namespace="production", app="user-service"} |= "ERROR"
```

**Selgitus:**
- `|=` - Contains filter (case-sensitive)
- Näitab ainult log read, mis sisaldavad "ERROR"

---

#### Query 4: Filter by regex

```logql
{namespace="production"} |~ "error|ERROR|Error"
```

**Selgitus:**
- `|~` - Regex filter
- Matchi "error", "ERROR", või "Error"

---

#### Query 5: Exclude WARN logs

```logql
{namespace="production"} != "WARN"
```

**Selgitus:**
- `!=` - Does not contain filter

---

#### Query 6: Rate of ERROR logs

```logql
rate({namespace="production"} |= "ERROR" [5m])
```

**Selgitus:**
- `rate([5m])` - Errors per second viimase 5 minuti jooksul
- Aggregate metric (nagu PromQL)

---

#### Query 7: Count errors per pod

```logql
sum by (pod) (count_over_time({namespace="production"} |= "ERROR" [5m]))
```

**Selgitus:**
- `count_over_time([5m])` - Count entries in 5 min window
- `sum by (pod)` - Summeeri per pod

---

### Samm 8: Loo Logs Dashboard Grafana'sse

**Create dashboard:**

1. **Create** (+) → **Dashboard**
2. **Add panel**

---

#### Panel 1: Error Rate by Namespace

**Query:**

```logql
sum by (namespace) (rate({job="kubernetes-pods"} |= "ERROR" [5m]))
```

**Panel settings:**
- **Title:** `Error Rate by Namespace`
- **Visualization:** Time series
- **Unit:** logs/sec
- **Legend:** `{{namespace}}`

---

#### Panel 2: Logs Table (Recent Errors)

**Query:**

```logql
{namespace="production"} |= "ERROR"
```

**Panel settings:**
- **Title:** `Recent Errors (Production)`
- **Visualization:** Logs
- **Display:** List
- **Deduplication:** None

---

#### Panel 3: Top Error Pods

**Query:**

```logql
topk(5,
  sum by (pod) (count_over_time({namespace="production"} |= "ERROR" [1h]))
)
```

**Panel settings:**
- **Title:** `Top 5 Pods by Error Count (Last 1h)`
- **Visualization:** Bar gauge
- **Unit:** logs

---

### Samm 9: Logs + Metrics Correlation

Saame korreleerida logs ja metrics sama dashboard'is.

**Create combined dashboard:**

1. Loo uus panel query'ga:
   ```promql
   rate(http_requests_total{status=~"5.."}[5m])
   ```
   - Data source: **Prometheus**
   - Title: "Server Error Rate (Metrics)"

2. Loo teine panel query'ga:
   ```logql
   rate({namespace="production"} |= "ERROR" [5m])
   ```
   - Data source: **Loki**
   - Title: "Error Log Rate (Logs)"

**Nüüd näed correlation'i:**
- Kui error rate tõuseb metrics'tes → vaata logs panel'it real-time error messages jaoks

---

### Samm 10: Live Tail (Real-time Logs)

**Grafana Explore:**

1. Kliki **Explore**
2. Vali **Loki** data source
3. Query:
   ```logql
   {namespace="production", app="user-service"}
   ```
4. Kliki **Live** (üleval paremal)

**Logs streamivad real-time!**

**Generate logs:**

```bash
# Port-forward user-service
kubectl port-forward -n production deployment/user-service 3000:3000

# Generate requests
for i in {1..100}; do
  curl -s http://localhost:3000/api/users > /dev/null
  sleep 0.5
done
```

Grafana Live Tail näitab iga requesti logi real-time!

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Loki + Promtail installitud monitoring namespace'is
- [ ] Promtail DaemonSet running kõigil node'idel
- [ ] Loki data source configured Grafana's
- [ ] LogQL queries töötavad (namespace, app filters)
- [ ] Logs visible Grafana Explore'is
- [ ] Logs dashboard created (errors, rate, tables)
- [ ] Live tail töötab
- [ ] Logs + metrics correlation dashboard

### Verifitseerimine

```bash
# 1. Kontrolli Loki pod
kubectl get pods -n monitoring -l app.kubernetes.io/name=loki

# 2. Kontrolli Promtail pods (1 per node)
kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail

# 3. Test Loki API
kubectl port-forward -n monitoring svc/loki 3100:3100
curl http://localhost:3100/ready

# 4. Query logs API
curl -G -s 'http://localhost:3100/loki/api/v1/query' \
  --data-urlencode 'query={namespace="production"}' \
  --data-urlencode 'limit=5' | jq '.data.result'

# 5. Kontrolli Promtail logs (kas kogub logs)
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=20
```

---

## 🔍 Troubleshooting

### Probleem: Promtail ei kogu logs

**Lahendus:**

```bash
# Kontrolli Promtail pod logs
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail --tail=50

# Kontrolli Promtail access /var/log/pods
kubectl exec -n monitoring -it <promtail-pod> -- ls -la /var/log/pods

# Kontrolli Promtail config
kubectl get configmap -n monitoring loki-promtail -o yaml
```

---

### Probleem: Loki ei näita logs Grafana's

**Lahendus:**

1. **Test Loki API directly:**
   ```bash
   curl -G -s 'http://localhost:3100/loki/api/v1/label' | jq
   # Peaks näitama labels: namespace, pod, container, jne
   ```

2. **Check Grafana data source:**
   - Configuration → Data Sources → Loki
   - Test connection
   - Check URL: `http://loki:3100`

3. **Check logs exist:**
   ```bash
   # Query specific namespace
   curl -G -s 'http://localhost:3100/loki/api/v1/query' \
     --data-urlencode 'query={namespace="production"}' \
     --data-urlencode 'limit=1'
   ```

---

### Probleem: "too many outstanding requests"

**Põhjus:** Loki resource limits

**Lahendus:**

Increase limits in `loki-values.yaml`:

```yaml
loki:
  config:
    limits_config:
      ingestion_rate_mb: 20        # Increase from 10
      ingestion_burst_size_mb: 40  # Increase from 20
```

```bash
helm upgrade loki grafana/loki-stack \
  --namespace monitoring \
  --values loki-values.yaml
```

---

## 📚 Mida Sa Õppisid?

✅ **Loki arhitektuur**
  - Labels-based indexing (not full-text)
  - Promtail log shipping
  - Push-based model (vs Prometheus pull)

✅ **LogQL query language**
  - Label selectors: `{namespace="production"}`
  - Filters: `|=`, `!=`, `|~`
  - Aggregations: `rate()`, `count_over_time()`
  - Arithmetic: `sum by()`, `topk()`

✅ **Log aggregation patterns**
  - DaemonSet for log collection
  - Centralized log storage
  - Label-based organization

✅ **Observability correlation**
  - Logs + metrics in same dashboard
  - Troubleshooting with combined view
  - Real-time log tailing

---

## 💡 Loki Best Practices

✅ **Label cardinality:** Hoia labels count low (namespace, pod, app - not user_id!)
✅ **Retention:** 7-30 päeva (balanseeri storage vs history)
✅ **Log levels:** Kasuta structured logging (JSON) labels'teks
✅ **Sampling:** Production'is consider sampling high-volume logs
✅ **Storage:** Production'is kasuta persistent storage (S3, GCS)
✅ **High availability:** 2+ Loki replicas distributed across zones
✅ **Query optimization:** Kasuta time range ja label filters (avoid `{job=".*"}`)

---

## 🎓 LogQL Cheat Sheet

### Basic Queries

```logql
# All logs from namespace
{namespace="production"}

# Specific pod
{namespace="production", pod="user-service-abc123"}

# Multiple namespaces
{namespace=~"production|staging"}
```

### Filters

```logql
# Contains
{namespace="production"} |= "error"

# Does not contain
{namespace="production"} != "debug"

# Regex
{namespace="production"} |~ "error|ERROR|Error"

# Negative regex
{namespace="production"} !~ "debug|DEBUG"
```

### Aggregations

```logql
# Rate (logs per second)
rate({namespace="production"} [5m])

# Count
count_over_time({namespace="production"} [5m])

# Sum by label
sum by (pod) (count_over_time({namespace="production"} [5m]))

# Top K
topk(10, sum by (pod) (rate({namespace="production"} [5m])))
```

### JSON Parsing

```logql
# Parse JSON field
{namespace="production"} | json | level="error"

# Extract field
{namespace="production"} | json message="msg"
```

---

## 🏆 Lab 6 Täielik!

**Õnnitleme! Sa läbisid Lab 6 kõik 5 harjutust! 🎉**

**Mida sa nüüd oskad:**

✅ **Prometheus:** Metrics collection, PromQL queries
✅ **Grafana:** Custom dashboards, visualizations
✅ **Loki:** Log aggregation, LogQL queries
✅ **AlertManager:** Alert rules, notifications
✅ **Observability:** Metrics + Logs correlation

**Sinu production-ready monitoring stack:**

```
┌─────────────────────────────────────────────────┐
│         Production Observability Stack          │
├─────────────────────────────────────────────────┤
│                                                 │
│  Metrics: Prometheus + Grafana                 │
│  Logs: Loki + Promtail                         │
│  Alerts: AlertManager + Slack                  │
│                                                 │
│  Coverage:                                      │
│  ✓ Cluster metrics (CPU, memory, pods)        │
│  ✓ Application metrics (requests, latency)    │
│  ✓ Multi-environment (dev, staging, prod)     │
│  ✓ Log aggregation (all pods)                 │
│  ✓ Alerting (critical + warning)              │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

**Järgmised sammud:**

🚀 **Production deployment:**
- Enable persistent storage (Prometheus, Grafana, Loki)
- High availability (multiple replicas)
- Backup strategies
- Resource tuning

📊 **Advanced dashboards:**
- SLA/SLO tracking
- Business metrics
- Cost monitoring

🔔 **Advanced alerting:**
- PagerDuty integration
- Alert fatigue reduction
- Incident management workflows

---

**Kestus:** 60 minutit
**Lab 6 Status:** ✅ Completed!

Tubli töö! 💪📈📊🔥
