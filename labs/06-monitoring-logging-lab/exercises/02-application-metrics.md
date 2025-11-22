# Harjutus 2: Application Metrics Collection

**Kestus:** 60 minutit
**Eesmärk:** Konfigureeri user-service metrics collection kõigist keskkondadest (development, staging, production).

---

## 📋 Ülevaade

Selles harjutuses seadistame **application-level metrics** kogumise. Lab 5-s deployisime user-service kolme keskkonda ja lisasime `/metrics` endpoint. Nüüd konfigureerime Prometheus'e neid metrics'eid koguma.

**Kasutame:**
- **ServiceMonitor CRD** (Custom Resource Definition) - Prometheus Operator pattern
- **Multi-environment labels** - Keskkondade eristamine
- **Custom metrics** - HTTP requests, latency, errors, business metrics

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

✅ Luua ServiceMonitor CRD user-service jaoks
✅ Konfigureerida metrics collection multi-environment setup'is
✅ Kontrollida metrics endpoints
✅ Kirjutada PromQL queries application metrics'ele
✅ Monitoorida HTTP request rate, latency, errors
✅ Kasutada labels metrics'e filtreerimiseks

---

## 🏗️ Application Metrics Arhitektuur

```
┌─────────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                             │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         Prometheus (monitoring namespace)               │   │
│  │                                                         │   │
│  │  1. ServiceMonitor discovers user-service endpoints    │   │
│  │  2. Scrapes /metrics every 30s                         │   │
│  │  3. Adds labels: namespace, pod, environment           │   │
│  │  4. Stores in time-series DB                           │   │
│  └────────┬────────────────────────────────────────────────┘   │
│           │ scrapes HTTP GET /metrics                          │
│           │                                                    │
│    ┌──────┼──────────────────┬─────────────────┐              │
│    │      │                  │                 │              │
│    ▼      ▼                  ▼                 ▼              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ development  │  │   staging    │  │  production  │        │
│  │ namespace    │  │  namespace   │  │  namespace   │        │
│  │              │  │              │  │              │        │
│  │ user-service │  │ user-service │  │ user-service │        │
│  │ pod(s)       │  │ pod(s)       │  │ pod(s)       │        │
│  │              │  │              │  │              │        │
│  │ GET /metrics │  │ GET /metrics │  │ GET /metrics │        │
│  │ ───────────► │  │ ───────────► │  │ ───────────► │        │
│  │ http_reqs    │  │ http_reqs    │  │ http_reqs    │        │
│  │ http_latency │  │ http_latency │  │ http_latency │        │
│  │ http_errors  │  │ http_errors  │  │ http_errors  │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Kontrolli User-Service /metrics Endpoint

Lab 5 Exercise 4's lisasime `/metrics` endpoint user-service'sse. Kontrollime, kas see töötab.

#### Development Namespace

```bash
# Port-forward user-service development namespace'is
kubectl port-forward -n development deployment/user-service 3000:3000

# Uues terminalis: testi metrics endpoint
curl http://localhost:3000/metrics
```

**Oodatav väljund (Prometheus format):**
```
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/api/users",status="200"} 42

# HELP http_request_duration_seconds HTTP request latency
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 35
http_request_duration_seconds_bucket{le="0.5"} 40
http_request_duration_seconds_sum 12.5
http_request_duration_seconds_count 42

# HELP nodejs_heap_size_used_bytes Node.js heap used
# TYPE nodejs_heap_size_used_bytes gauge
nodejs_heap_size_used_bytes 45678912
```

**Märkused:**
- Metrics on Prometheus format (OpenMetrics compatible)
- Counter: Monotonically increasing value (total requests)
- Histogram: Latency distribution (buckets)
- Gauge: Current value (memory usage)

**Katkesta port-forward:** `Ctrl+C`

---

#### Staging ja Production

Kontrolli ka staging ja production namespace'ides:

```bash
# Staging
kubectl port-forward -n staging deployment/user-service 3001:3000
curl http://localhost:3001/metrics

# Production
kubectl port-forward -n production deployment/user-service 3002:3000
curl http://localhost:3002/metrics
```

---

### Samm 2: Loo ServiceMonitor Development Jaoks

ServiceMonitor on Prometheus Operator CRD, mis automaatselt konfigureer scrape targets.

Loo fail `servicemonitor-development.yaml`:

```bash
vim servicemonitor-development.yaml
```

**Fail sisu:**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: user-service-development
  namespace: monitoring
  labels:
    app: user-service
    environment: development
spec:
  # Selector: millised Services see ServiceMonitor watches
  selector:
    matchLabels:
      app: user-service

  # Namespaces, kust Services leida
  namespaceSelector:
    matchNames:
      - development

  # Endpoints configuration
  endpoints:
    - port: http              # Service port name
      path: /metrics          # Metrics endpoint path
      interval: 30s           # Scrape interval
      scrapeTimeout: 10s      # Timeout per scrape

      # Relabeling (add custom labels)
      relabelings:
        - sourceLabels: [__meta_kubernetes_namespace]
          targetLabel: namespace

        - sourceLabels: [__meta_kubernetes_pod_name]
          targetLabel: pod

        - targetLabel: environment
          replacement: development
```

**Salvesta:** `Esc`, `:wq`, `Enter`

**Apply:**

```bash
kubectl apply -f servicemonitor-development.yaml
```

**Kontrolli:**

```bash
kubectl get servicemonitors -n monitoring
```

**Oodatav väljund:**
```
NAME                       AGE
user-service-development   5s
```

---

### Samm 3: Kontrolli Prometheus Targets

ServiceMonitor automaatselt lisab target Prometheus'e.

**Prometheus UI:**

1. Port-forward (kui ei ole juba running):
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
   ```

2. Ava brauseris: `http://localhost:9090`

3. Kliki `Status` → `Targets`

4. Otsi `user-service-development`

**Peaks nägema:**
- **Job:** `serviceMonitor/monitoring/user-service-development/0`
- **State:** UP (1/1)
- **Labels:** namespace=development, environment=development, pod=user-service-...
- **Endpoint:** `http://<pod-ip>:3000/metrics`

---

### Samm 4: Test PromQL Queries User-Service Metrics'ele

**Prometheus UI → Graph:**

#### Query 1: HTTP requests total

```promql
http_requests_total{environment="development"}
```

**Tulemus:** Total requests per method/route/status

---

#### Query 2: Request rate (requests per second)

```promql
rate(http_requests_total{environment="development"}[5m])
```

**Selgitus:**
- `rate([5m])` - Keskmine requests per second viimase 5 minuti jooksul
- Kasulik trend'ide vaatamiseks

---

#### Query 3: Request rate per route

```promql
sum by (route) (rate(http_requests_total{environment="development"}[5m]))
```

**Tulemus:** Requests/sec per API endpoint

---

#### Query 4: HTTP error rate

```promql
rate(http_requests_total{environment="development", status=~"5.."}[5m])
```

**Selgitus:**
- `status=~"5.."` - Regex match 500-599 status codes
- Monitoring server errors

---

#### Query 5: Average request latency (95th percentile)

```promql
histogram_quantile(0.95,
  rate(http_request_duration_seconds_bucket{environment="development"}[5m])
)
```

**Selgitus:**
- `histogram_quantile(0.95, ...)` - 95% requests on kiiremad kui see väärtus
- P95 latency on standard SLA metric

---

#### Query 6: Memory usage

```promql
nodejs_heap_size_used_bytes{environment="development"}
```

**Tulemus:** Heap memory kasutus baitides

---

### Samm 5: Loo ServiceMonitor Staging Jaoks

```bash
vim servicemonitor-staging.yaml
```

**Fail sisu:**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: user-service-staging
  namespace: monitoring
  labels:
    app: user-service
    environment: staging
spec:
  selector:
    matchLabels:
      app: user-service

  namespaceSelector:
    matchNames:
      - staging

  endpoints:
    - port: http
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s

      relabelings:
        - sourceLabels: [__meta_kubernetes_namespace]
          targetLabel: namespace

        - sourceLabels: [__meta_kubernetes_pod_name]
          targetLabel: pod

        - targetLabel: environment
          replacement: staging
```

**Apply:**

```bash
kubectl apply -f servicemonitor-staging.yaml
```

---

### Samm 6: Loo ServiceMonitor Production Jaoks

```bash
vim servicemonitor-production.yaml
```

**Fail sisu:**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: user-service-production
  namespace: monitoring
  labels:
    app: user-service
    environment: production
spec:
  selector:
    matchLabels:
      app: user-service

  namespaceSelector:
    matchNames:
      - production

  endpoints:
    - port: http
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s

      relabelings:
        - sourceLabels: [__meta_kubernetes_namespace]
          targetLabel: namespace

        - sourceLabels: [__meta_kubernetes_pod_name]
          targetLabel: pod

        - targetLabel: environment
          replacement: production
```

**Apply:**

```bash
kubectl apply -f servicemonitor-production.yaml
```

**Kontrolli kõiki ServiceMonitors:**

```bash
kubectl get servicemonitors -n monitoring
```

**Oodatav väljund:**
```
NAME                       AGE
user-service-development   5m
user-service-staging       2m
user-service-production    10s
```

---

### Samm 7: Kontrolli Kõiki Targets Prometheus UI's

**Prometheus UI → Status → Targets:**

Peaks nägema 3 user-service target group'i:
- `serviceMonitor/monitoring/user-service-development/0` (UP)
- `serviceMonitor/monitoring/user-service-staging/0` (UP)
- `serviceMonitor/monitoring/user-service-production/0` (UP)

---

### Samm 8: Multi-Environment Queries

Nüüd saame võrrelda metrics'eid keskkondade vahel.

#### Query 1: Request rate kõigis keskkondades

```promql
sum by (environment) (rate(http_requests_total[5m]))
```

**Tulemus:** Requests/sec per environment

---

#### Query 2: Latency võrdlus

```promql
histogram_quantile(0.95,
  sum by (environment, le) (rate(http_request_duration_seconds_bucket[5m]))
)
```

**Tulemus:** P95 latency per environment

---

#### Query 3: Error rate võrdlus

```promql
sum by (environment) (rate(http_requests_total{status=~"5.."}[5m]))
```

**Tulemus:** Server errors per environment

---

#### Query 4: Memory usage võrdlus

```promql
sum by (environment) (nodejs_heap_size_used_bytes)
```

**Tulemus:** Memory usage per environment

---

### Samm 9: Generate Traffic (Optional Test)

Kui tahad näha metrics'eid liikumas, genereeri traffic:

```bash
# Port-forward user-service
kubectl port-forward -n development deployment/user-service 3000:3000

# Uues terminalis: generate requests
for i in {1..100}; do
  curl -s http://localhost:3000/api/users > /dev/null
  sleep 0.1
done
```

**Prometheus UI'sis peaks nägema:**
- `http_requests_total` counter kasvab
- Request rate graph näitab spike'i
- Latency histogram uueneb

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] User-service /metrics endpoint töötab kõigis keskkondades
- [ ] ServiceMonitor loodud development, staging, production jaoks
- [ ] Prometheus Targets UI näitab 3 user-service targets (kõik UP)
- [ ] PromQL query `http_requests_total` returns data
- [ ] Request rate query töötab
- [ ] Latency query töötab (histogram_quantile)
- [ ] Multi-environment võrdlus queries töötavad
- [ ] Environment label on õigesti seatud (development/staging/production)

### Verifitseerimine

```bash
# 1. Kontrolli ServiceMonitors
kubectl get servicemonitors -n monitoring | grep user-service

# 2. Test Prometheus API
curl -s 'http://localhost:9090/api/v1/query?query=http_requests_total' | jq '.data.result[] | {environment: .metric.environment, value: .value[1]}'

# 3. Kontrolli targets API kaudu
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.app=="user-service") | {environment: .labels.environment, health: .health}'
```

**Oodatav väljund:**
```json
{"environment": "development", "health": "up"}
{"environment": "staging", "health": "up"}
{"environment": "production", "health": "up"}
```

---

## 🔍 Troubleshooting

### Probleem: ServiceMonitor ei loo targets

**Põhjus:** Selector ei matchi Service labels'eid

**Lahendus:**

```bash
# Kontrolli Service labels
kubectl get service -n development user-service -o yaml | grep -A5 labels

# ServiceMonitor selector peab matchima Service labels'eid
# Kui Service label on "app.kubernetes.io/name: user-service"
# Siis ServiceMonitor selector peab olema:
# selector:
#   matchLabels:
#     app.kubernetes.io/name: user-service

# Või lisa Service'le label:
kubectl label service user-service app=user-service -n development
```

---

### Probleem: Metrics endpoint returns 404

**Põhjus:** /metrics endpoint pole implementeeritud

**Lahendus:**

User-service peab exporting'ima metrics. Lab 5 Exercise 4's me lisasime selle. Kui puudub:

**Node.js (Express) example:**

```javascript
// Install prom-client
// npm install prom-client

const promClient = require('prom-client');

// Enable default metrics (memory, CPU, etc)
promClient.collectDefaultMetrics();

// Create custom metrics
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request latency in seconds',
  labelNames: ['method', 'route']
});

// Middleware to track requests
app.use((req, res, next) => {
  const start = Date.now();

  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;

    httpRequestsTotal.inc({
      method: req.method,
      route: req.route?.path || req.path,
      status: res.statusCode
    });

    httpRequestDuration.observe({
      method: req.method,
      route: req.route?.path || req.path
    }, duration);
  });

  next();
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(await promClient.register.metrics());
});
```

Rebuild Docker image ja redeploy.

---

### Probleem: Targets on DOWN

**Põhjus:** Port mismatch või network issues

**Lahendus:**

```bash
# Kontrolli Service port name
kubectl get service -n development user-service -o yaml

# Service peab omama port name "http"
# ports:
#   - name: http
#     port: 3000
#     targetPort: 3000

# ServiceMonitor kasutab port name'i:
# endpoints:
#   - port: http  # <-- peab matchima Service port name'iga

# Või kasuta port number'it:
# endpoints:
#   - port: 3000
```

---

## 📚 Mida Sa Õppisid?

✅ **ServiceMonitor CRD**
  - Automatic service discovery
  - Label-based selection
  - Relabeling configuration

✅ **Multi-environment monitoring**
  - Per-environment ServiceMonitors
  - Environment labels
  - Cross-environment comparisons

✅ **Application metrics types**
  - Counter (http_requests_total)
  - Histogram (http_request_duration_seconds)
  - Gauge (nodejs_heap_size_used_bytes)

✅ **PromQL advanced queries**
  - rate() for request rate
  - histogram_quantile() for percentiles
  - sum by() for aggregations
  - Regex filtering (status=~"5..")

---

## 🚀 Järgmised Sammud

**Exercise 3: Grafana Dashboards** - Visualiseeri metrics Grafana'ga:
- Loo custom dashboards
- Multi-environment panels
- Alert thresholds visualization
- Variables ja templating

```bash
cat exercises/03-grafana-dashboards.md
```

---

## 💡 Best Practices

✅ **Metric naming:** Kasuta descriptive names (http_requests_total, not requests)
✅ **Labels:** Hoia label cardinality madal (avoid high-cardinality labels like user_id)
✅ **Scrape interval:** 30s on standard (balanss storage vs latency)
✅ **Histogram buckets:** Defineeri buckets aplikatsiooni latency range'i põhjal
✅ **Environment separation:** Kasuta labels või erinevaid Prometheus instances
✅ **Metrics retention:** Production metrics 30-90 päeva, development 7 päeva

---

**Õnnitleme! Rakenduste metrics collection töötab! 🎉📊**

**Kestus:** 60 minutit
**Järgmine:** Exercise 3 - Grafana Dashboards
