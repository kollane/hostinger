# Harjutus 4: Logging with Loki

**Kestus:** 60 minutit
**Eesmärk:** Seadistada Loki log aggregation ja visualiseeri logisid Grafana's

---

## 📋 Ülevaade

Selles harjutuses õpid paigaldama **Grafana Loki** - horizontaalselt scalable, highly available log aggregation süsteemi. Loki kogub logisid pod'idest, salvestab need ja võimaldab päringuid LogQL keelega Grafana's.

**Loki** on nagu "Prometheus logide jaoks" - kasutab sarnaseid label'eid ja integreerib sujuvalt Grafana'ga. Erinevalt Elasticsearch'ist, Loki ei indekseeri log sisu (ainult label'id), mis teeb selle kergemaks ja odavamaks.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Paigaldada Loki ja Promtail
- ✅ Konfigureerida log shipping
- ✅ Lisada Loki data source Grafana'sse
- ✅ Kirjutada LogQL päringuid
- ✅ Visualiseerida logisid Grafana's
- ✅ Filter'ida logisid label'ite ja regex'iga
- ✅ Debuggida production issues logide abil

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────────────────────────────┐
│         Kubernetes Cluster                          │
│                                                     │
│  ┌───────────────┐  ┌───────────────┐              │
│  │  Pod 1        │  │  Pod 2        │              │
│  │  (user-svc)   │  │  (todo-svc)   │              │
│  │               │  │               │              │
│  │  stdout/stderr│  │  stdout/stderr│              │
│  └───────┬───────┘  └───────┬───────┘              │
│          │                  │                       │
│          ▼                  ▼                       │
│  ┌──────────────────────────────────────────────┐  │
│  │  Promtail DaemonSet                          │  │
│  │  (log collector on each node)                │  │
│  │  - Reads logs from /var/log/pods/*           │  │
│  │  - Adds labels (namespace, pod, container)   │  │
│  │  - Ships to Loki                             │  │
│  └────────────────┬─────────────────────────────┘  │
│                   │ HTTP push                       │
│                   ▼                                 │
│  ┌──────────────────────────────────────────────┐  │
│  │  Loki                                        │  │
│  │  - Log storage (chunks)                      │  │
│  │  - Label indexing                            │  │
│  │  - LogQL query engine                        │  │
│  └────────────────┬─────────────────────────────┘  │
│                   │ LogQL query                     │
│                   ▼                                 │
│  ┌──────────────────────────────────────────────┐  │
│  │  Grafana                                     │  │
│  │  - Loki data source                          │  │
│  │  - Log visualization                         │  │
│  │  - LogQL query UI                            │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Lisa Loki Helm Repository (5 min)

```bash
# Lisa Grafana Helm repo
helm repo add grafana https://grafana.github.io/helm-charts

# Update
helm repo update

# Otsi Loki stack
helm search repo grafana/loki-stack

# Peaks näitama:
# NAME                 CHART VERSION  APP VERSION  DESCRIPTION
# grafana/loki-stack   2.x.x          v2.9.x       Loki: like Prometheus, but for logs
```

---

### Samm 2: Loo Loki Values File (10 min)

Loo `loki-values.yaml`:

```yaml
loki:
  enabled: true
  isDefault: true

  # Persistence
  persistence:
    enabled: true
    size: 10Gi

  # Resources
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

  # Config
  config:
    # Retention period
    limits_config:
      retention_period: 168h  # 7 days

    # Chunk storage
    chunk_store_config:
      max_look_back_period: 0s

    # Table manager
    table_manager:
      retention_deletes_enabled: true
      retention_period: 168h

# Promtail (log collector)
promtail:
  enabled: true

  # Resources
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi

  # Config
  config:
    # Server
    server:
      http_listen_port: 3101

    # Scrape configs
    scrape_configs:
      # Kubernetes pods
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod

        relabel_configs:
          # Add namespace label
          - source_labels: [__meta_kubernetes_pod_namespace]
            target_label: namespace

          # Add pod label
          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod

          # Add container label
          - source_labels: [__meta_kubernetes_pod_container_name]
            target_label: container

          # Add app label
          - source_labels: [__meta_kubernetes_pod_label_app]
            target_label: app

          # Log path
          - source_labels: [__meta_kubernetes_pod_uid, __meta_kubernetes_pod_container_name]
            target_label: __path__
            separator: /
            replacement: /var/log/pods/*$1/*.log

# Grafana integration (already installed)
grafana:
  enabled: false  # Using existing Grafana from kube-prometheus-stack

# Fluent Bit (alternative log collector)
fluent-bit:
  enabled: false
```

---

### Samm 3: Paigalda Loki Stack (10 min)

```bash
# Install Loki stack
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki-values.yaml

# Peaks näitama:
# NAME: loki
# NAMESPACE: monitoring
# STATUS: deployed

# Kontrolli pod'e
kubectl get pods -n monitoring | grep loki

# Oodatud pod'id:
# loki-0                         1/1     Running   0          2m
# loki-promtail-xxxxx            1/1     Running   0          2m  (DaemonSet)
# loki-promtail-yyyyy            1/1     Running   0          2m

# Kontrolli services
kubectl get svc -n monitoring | grep loki

# NAME               TYPE        CLUSTER-IP    PORT(S)
# loki               ClusterIP   10.x.x.x      3100/TCP
# loki-promtail      ClusterIP   None          3101/TCP
```

**Paigaldus võtab ~2 minutit.**

---

### Samm 4: Lisa Loki Data Source Grafana'sse (5 min)

**Port forward Grafana:**

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

**Lisa data source:**

1. Grafana UI (http://localhost:3000) → ☰ → **Connections** → **Data sources**
2. Kliki **Add data source**
3. Vali **Loki**
4. **Name:** `Loki`
5. **URL:** `http://loki.monitoring:3100`
6. **Access:** Server (default)
7. Scroll down → **Save & test**

Peaks näitama: ✅ "Data source connected and labels found."

---

### Samm 5: Testi LogQL Päringuid (10 min)

**Grafana Explore:**

1. Grafana → ☰ → **Explore**
2. Vali data source: **Loki** (dropdown)

**LogQL query näited:**

**1. Kõik logid namespace'ist:**
```logql
{namespace="default"}
```

**2. Specific pod logid:**
```logql
{namespace="default", pod=~"user-service.*"}
```

**3. Filter ERROR level:**
```logql
{namespace="default"} |= "ERROR"
```

**4. Regex match:**
```logql
{namespace="default"} |~ "HTTP.*500"
```

**5. Exclude health check logs:**
```logql
{namespace="default"} != "/health"
```

**6. JSON parsing:**
```logql
{namespace="default"} | json | level="error"
```

**7. Rate query (logs per second):**
```logql
rate({namespace="default"}[5m])
```

Kliki **Run query** → vaata logisid!

---

### Samm 6: Loo Logs Dashboard (15 min)

**Uus dashboard: "Application Logs"**

**Panel 1: Log Stream**

- Visualization: **Logs**
- Query:
  ```logql
  {namespace="default", app="user-service"}
  ```
- Options:
  - **Show time:** ✅
  - **Wrap lines:** ✅
  - **Deduplication:** None

**Panel 2: Error Log Rate**

- Visualization: **Time series**
- Query:
  ```logql
  sum(rate({namespace="default", app="user-service"} |= "ERROR" [5m]))
  ```
- Title: Error Logs per Second

**Panel 3: Log Level Distribution**

- Visualization: **Pie chart**
- Query A (INFO):
  ```logql
  count_over_time({namespace="default"} |= "INFO" [5m])
  ```
- Query B (WARN):
  ```logql
  count_over_time({namespace="default"} |= "WARN" [5m])
  ```
- Query C (ERROR):
  ```logql
  count_over_time({namespace="default"} |= "ERROR" [5m])
  ```

**Panel 4: Top 10 Error Messages**

- Visualization: **Table**
- Query:
  ```logql
  topk(10, sum by (pod) (count_over_time({namespace="default"} |= "ERROR" [1h])))
  ```

Salvesta dashboard!

---

### Samm 7: Lisa Structured Logging Rakendusse (10 min)

**Install Winston (logging library):**

```bash
cd labs/apps/backend-nodejs
npm install winston
```

**Loo `logger.js`:**

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()  // JSON format (parsable by Loki)
  ),
  defaultMeta: { service: 'user-service' },
  transports: [
    new winston.transports.Console()
  ]
});

module.exports = logger;
```

**Kasuta logger'it:**

```javascript
const logger = require('./logger');

// Replace console.log with logger
logger.info('Server starting...', { port: 3000 });
logger.warn('Database connection slow', { latency: 500 });
logger.error('Database connection failed', { error: err.message });
```

**Kasutuse näide `server.js`'is:**

```javascript
const logger = require('./logger');

app.listen(PORT, () => {
  logger.info('Server started', {
    port: PORT,
    environment: process.env.NODE_ENV
  });
});
```

**Middleware logging:**

```javascript
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = Date.now() - start;

    logger.info('HTTP Request', {
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration_ms: duration,
      ip: req.ip
    });
  });

  next();
});
```

---

### Samm 8: Testi Loki Logide Pärimist (5 min)

**Deploy updated app:**

```bash
git add logger.js server.js package.json
git commit -m "Add structured logging with Winston"
git push origin main

# CI/CD builds + deploys
```

**Kontrolli logisid Grafana's:**

1. Grafana → Explore → Loki
2. Query:
   ```logql
   {namespace="default", app="user-service"} | json
   ```
3. Peaks näitama structured JSON logs
4. Kliki log'i → expand → näed JSON fields

**Filter JSON field'ite järgi:**

```logql
{namespace="default"} | json | method="POST" | status="500"
```

---

## ✅ Kontrolli Tulemusi

- [ ] **Loki stack:**
  - [ ] Loki pod running
  - [ ] Promtail DaemonSet running (1 per node)

- [ ] **Grafana:**
  - [ ] Loki data source connected
  - [ ] Explore works (LogQL queries)

- [ ] **Logs:**
  - [ ] Application logs visible
  - [ ] Structured JSON logs
  - [ ] Filtering works

- [ ] **Dashboard:**
  - [ ] Logs dashboard created
  - [ ] Log panels visualize logs

---

## 🐛 Troubleshooting

### Probleem 1: Loki "No labels found"

**Põhjus:** Promtail ei kogu logisid või Loki ei saa ühendust.

**Diagnoos:**

```bash
# Kontrolli Promtail logisid
kubectl logs -n monitoring -l app.kubernetes.io/name=promtail

# Peaks näitama:
# level=info msg="Successfully sent batch"
```

**Lahendus:** Kontrolli Promtail config (`scrape_configs`).

---

### Probleem 2: No logs in Grafana Explore

**Diagnoos:**

```bash
# Testi Loki API
kubectl port-forward -n monitoring svc/loki 3100:3100

curl 'http://localhost:3100/loki/api/v1/labels'

# Peaks tagastama label'id:
# {"status":"success","data":["namespace","pod","container",...]}
```

**Lahendus:** Kui labels tühi, Promtail ei kogu logisid.

---

## 🎓 Õpitud Mõisted

### Loki:
- **Log aggregation:** Keskne log storage
- **Label indexing:** Ainult labels indexed (ei indekseeri log content)
- **Chunk storage:** Logs stored in chunks (compressed)

### Promtail:
- **DaemonSet:** Runs on every node
- **Scraping:** Reads logs from /var/log/pods/*
- **Relabeling:** Adds labels (namespace, pod, container)

### LogQL:
- **Label selector:** `{namespace="default"}`
- **Line filter:** `|= "ERROR"` (contains), `|~ "regex"`
- **JSON parser:** `| json`
- **Aggregation:** `rate()`, `count_over_time()`, `sum()`

### Structured Logging:
- **JSON format:** Machine-readable (parsable)
- **Fields:** Structured data (method, status, duration)
- **Winston:** Node.js logging library

---

## 💡 Parimad Tavad

1. **Structured logging** - Use JSON format
2. **Log levels** - INFO, WARN, ERROR (filterable)
3. **Context fields** - Add useful metadata (user_id, request_id)
4. **Don't log secrets** - Never log passwords, tokens
5. **Log sampling** - Sample high-volume logs (DEBUG)
6. **Retention** - 7-30 days (balance cost vs history)
7. **Correlation IDs** - Track requests across services
8. **Error stack traces** - Include full error details

---

## 🔗 Järgmine Samm

Järgmises harjutuses seadistame **Alerting** - saadame notificatione kui metrics või logid näitavad probleeme.

**Jätka:** [Harjutus 5: Alerting & Monitoring](05-alerting-monitoring.md)

---

## 📚 Viited

- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/configuration/)
- [Winston Logger](https://github.com/winstonjs/winston)

---

**Õnnitleme! Loki kogub nüüd logisid ja saad neid visualiseerida Grafana's! 📋**
