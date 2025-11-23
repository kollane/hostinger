# Harjutus 1: Prometheus Setup

**Kestus:** 60 minutit
**Eesmärk:** Paigalda Prometheus Kubernetes cluster'i ja õpi basic metrics collection.

---

## 📋 Ülevaade

Selles harjutuses paigaldad **Prometheus** - avatud lähtekoodiga monitoring ja alerting süsteemi. Prometheus on Cloud Native Computing Foundation (CNCF) graduated project ja de facto standard Kubernetes monitoring'uks.

**Prometheus peamised komponendid:**
- **Prometheus Server** - Time-series database ja scraping engine
- **kube-state-metrics** - Kubernetes object metrics
- **node-exporter** - Hardware ja OS metrics
- **AlertManager** - Alert routing (kasutatakse Exercise 4's)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

✅ Paigaldada Prometheus kube-prometheus-stack Helm chart'iga
✅ Mõista Prometheus arhitektuuri
✅ Navigeerida Prometheus UI's
✅ Kirjutada basic PromQL queries
✅ Kontrollida scrape targets'e
✅ Verificeerida metrics collection'i

---

## 🏗️ Prometheus Arhitektuur

```
┌─────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                         │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Prometheus Server (monitoring namespace)          │    │
│  │  - Time-series database                            │    │
│  │  - HTTP server (UI + API)                          │    │
│  │  - Scraper (pulls metrics every 30s)               │    │
│  │  - Alert evaluation engine                         │    │
│  └────────┬───────────────────────────────────────────┘    │
│           │ scrapes (HTTP GET /metrics)                    │
│           │                                                │
│           ▼                                                │
│  ┌─────────────────┐  ┌─────────────────┐                 │
│  │ kube-state-     │  │ node-exporter   │                 │
│  │ metrics         │  │ (DaemonSet)     │                 │
│  │                 │  │                 │                 │
│  │ Exposes K8s     │  │ Exposes node    │                 │
│  │ object metrics: │  │ metrics:        │                 │
│  │ - Deployments   │  │ - CPU usage     │                 │
│  │ - Pods          │  │ - Memory usage  │                 │
│  │ - Services      │  │ - Disk I/O      │                 │
│  │ - ConfigMaps    │  │ - Network       │                 │
│  └─────────────────┘  └─────────────────┘                 │
│                                                             │
│  User accesses:                                            │
│  http://localhost:9090 (via port-forward)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Loo Monitoring Namespace

Kõik monitoring komponendid (Prometheus, Grafana, Loki) pannakse `monitoring` namespace'i.

```bash
# Loo namespace
kubectl create namespace monitoring

# Kontrolli
kubectl get namespaces | grep monitoring
```

**Oodatav väljund:**
```
monitoring   Active   5s
```

---

### Samm 2: Lisa Prometheus Helm Repository

Kasutame `prometheus-community/kube-prometheus-stack` chart'i, mis sisaldab:
- Prometheus Server
- Grafana
- kube-state-metrics
- node-exporter
- AlertManager
- Prometheus Operator (CRD'd nagu ServiceMonitor, PrometheusRule)

```bash
# Lisa Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Uuenda repositories
helm repo update

# Kontrolli chart'i olemasolu
helm search repo prometheus-community/kube-prometheus-stack
```

**Oodatav väljund:**
```
NAME                                              CHART VERSION  APP VERSION
prometheus-community/kube-prometheus-stack        55.5.0         v0.70.0
```

---

### Samm 3: Loo Custom Values Fail

Loome custom values faili, et konfigureerida Prometheus meie vajadusteks:
- Persistence disabled (development jaoks)
- Smaller resource requests
- Port-forward friendly configuration

Loo fail `prometheus-values.yaml`:

```bash
vim prometheus-values.yaml
```

**Fail sisu:**

```yaml
# Prometheus Values for Lab 6
# kube-prometheus-stack Helm chart

# Prometheus configuration
prometheus:
  prometheusSpec:
    # Retention
    retention: 7d
    retentionSize: "10GB"

    # Resources (adjust based on cluster size)
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 2Gi

    # Storage (disable persistence for lab)
    storageSpec: {}

    # ServiceMonitor selector (collect all ServiceMonitors)
    serviceMonitorSelectorNilUsesHelmValues: false

    # PodMonitor selector
    podMonitorSelectorNilUsesHelmValues: false

# Grafana configuration
grafana:
  enabled: true

  # Admin credentials
  adminPassword: admin123  # Change in production!

  # Persistence disabled for lab
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

# AlertManager configuration
alertmanager:
  enabled: true

  # Persistence disabled
  alertmanagerSpec:
    storage: {}

    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 200m
        memory: 256Mi

# kube-state-metrics
kubeStateMetrics:
  enabled: true

# node-exporter (DaemonSet)
nodeExporter:
  enabled: true

# Prometheus Operator
prometheusOperator:
  enabled: true

  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

**Salvesta ja välju:** `Esc`, `:wq`, `Enter`

---

### Samm 4: Installi Prometheus Stack

```bash
# Installi Helm chart
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --wait \
  --timeout 10m

# Kontrolli installatsiooni
kubectl get pods -n monitoring
```

**Oodatav väljund (kõik pods RUNNING):**
```
NAME                                                   READY   STATUS    AGE
prometheus-kube-prometheus-operator-...                1/1     Running   2m
prometheus-kube-state-metrics-...                      1/1     Running   2m
prometheus-prometheus-node-exporter-...                1/1     Running   2m
prometheus-grafana-...                                 2/2     Running   2m
alertmanager-prometheus-kube-prometheus-alertmanager-0 2/2     Running   2m
prometheus-prometheus-kube-prometheus-prometheus-0     2/2     Running   2m
```

**Märkused:**
- Install võib võtta 3-5 minutit
- Node-exporter on DaemonSet (1 pod per node)
- Prometheus ja AlertManager on StatefulSet (persistent identity)

---

### Samm 5: Kontrolli Prometheus Services

```bash
# Näita kõiki services monitoring namespace'is
kubectl get services -n monitoring
```

**Oodatav väljund:**
```
NAME                                      TYPE        CLUSTER-IP      PORT(S)
prometheus-kube-prometheus-prometheus     ClusterIP   10.96.x.x       9090/TCP
prometheus-kube-prometheus-alertmanager   ClusterIP   10.96.x.x       9093/TCP
prometheus-grafana                        ClusterIP   10.96.x.x       80/TCP
prometheus-kube-state-metrics             ClusterIP   10.96.x.x       8080/TCP
prometheus-prometheus-node-exporter       ClusterIP   10.96.x.x       9100/TCP
```

---

### Samm 6: Ligipääs Prometheus UI'le

Prometheus UI on kättesaadav port-forward kaudu:

```bash
# Port-forward Prometheus service
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

**Ava brauseris:** `http://localhost:9090`

**Prometheus UI komponendid:**
- **Graph** - PromQL queries ja visualization
- **Alerts** - Active alerts
- **Status → Targets** - Scrape targets ja nende status
- **Status → Configuration** - Prometheus config
- **Status → Service Discovery** - Discovered targets

**Jäta port-forward käima ja ava uus terminal harjutuse jätkamiseks.**

---

### Samm 7: Kontrolli Scrape Targets

Targets on endpoints, kust Prometheus kogub metrics'eid.

**Prometheus UI:**
1. Ava `http://localhost:9090`
2. Kliki `Status` → `Targets`

**Peaks nägema:**
- **kube-state-metrics** - State UP (1/1)
- **node-exporter** - State UP (1/1 või rohkem kui multi-node cluster)
- **prometheus** - State UP (self-monitoring)
- **alertmanager** - State UP (1/1)

**CLI kaudu:**

```bash
# Prometheus API kaudu
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

**Oodatav väljund:**
```json
{"job": "prometheus-kube-prometheus-prometheus", "health": "up"}
{"job": "prometheus-kube-state-metrics", "health": "up"}
{"job": "prometheus-prometheus-node-exporter", "health": "up"}
```

---

### Samm 8: Esimesed PromQL Queries

PromQL (Prometheus Query Language) on võimas query keel metrics'te pärimiseks.

**Prometheus UI → Graph:**

#### Query 1: Kontrolli, kas metrics tulevad

```promql
up
```

**Tulemus:** Kõik targets peaksid olema `1` (up)

---

#### Query 2: Kubernetes node CPU usage

```promql
sum by (node) (rate(node_cpu_seconds_total{mode!="idle"}[5m]))
```

**Selgitus:**
- `node_cpu_seconds_total` - Node CPU kasutus sekundites
- `{mode!="idle"}` - Kõik režiimid välja arvatud idle
- `rate([5m])` - Kasv viimase 5 minuti jooksul
- `sum by (node)` - Summeeri node kaupa

**Tulemus:** CPU kasutus (0.0 - 1.0 = 0% - 100%) per node

---

#### Query 3: Memory kasutus namespace kaupa

```promql
sum by (namespace) (container_memory_usage_bytes)
```

**Selgitus:**
- `container_memory_usage_bytes` - Container memory kasutus
- `sum by (namespace)` - Summeeri namespace kaupa

**Tulemus:** Memory kasutus baitides per namespace

---

#### Query 4: Pod restart count

```promql
sum by (namespace, pod) (kube_pod_container_status_restarts_total)
```

**Tulemus:** Restart count per pod

---

#### Query 5: Available pods per deployment

```promql
kube_deployment_status_replicas_available
```

**Tulemus:** Mitu pod'i on saadaval per deployment

---

### Samm 9: Metrics Exploration

Prometheus kogub tuhandeid metrics'eid. Õpi neid leidma:

**Prometheus UI → Graph:**

1. Kliki "Metrics Explorer" (hamburgeri ikoon query välja kõrval)
2. Filtreeri metrics'e: `node_`, `kube_`, `container_`
3. Vali metric ja vaata autocomplete suggestions'id

**Kasulikud metric prefixid:**
- `node_*` - Node/host metrics (CPU, memory, disk, network)
- `kube_*` - Kubernetes object metrics (deployments, pods, services)
- `container_*` - Container metrics (CPU, memory)

---

### Samm 10: Time-Series Visualization

Proovi graafikute loomist:

**Prometheus UI → Graph:**

1. Query: `rate(node_cpu_seconds_total{mode="system"}[5m])`
2. Kliki **Graph** tab (mitte Console)
3. Vaata CPU kasutuse graafikut aja jooksul

**Visualiseerimise nupud:**
- **Add Panel** - Lisa uus graafik
- **Stacked** - Stack multiple series
- **Time range** - Muuda time window (1h, 6h, 1d, etc)
- **Resolution** - Query resolution (step size)

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Monitoring namespace loodud
- [ ] Prometheus Helm chart installitud
- [ ] Kõik pods on RUNNING state'is
- [ ] Prometheus UI accessible `http://localhost:9090`
- [ ] Targets on UP state'is (kube-state-metrics, node-exporter)
- [ ] PromQL query `up` returns 1 for all targets
- [ ] CPU usage query töötab
- [ ] Memory usage query töötab
- [ ] Metrics explorer töötab

### Verifitseerimine CLI'ga

```bash
# 1. Kontrolli pods
kubectl get pods -n monitoring

# 2. Kontrolli Prometheus ready state
kubectl get statefulset -n monitoring prometheus-prometheus-kube-prometheus-prometheus

# 3. Test PromQL API
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | {metric: .metric.job, value: .value[1]}'

# 4. Kontrolli targets health
curl -s http://localhost:9090/api/v1/targets | jq '[.data.activeTargets[] | {job: .labels.job, health: .health}]'
```

---

## 🔍 Troubleshooting

### Probleem: Pods ei käivitu (Pending state)

**Põhjus:** Insufficient resources (CPU/memory)

**Lahendus:**
```bash
# Kontrolli pod events
kubectl describe pod -n monitoring <pod-name>

# Vähenda resource requests
vim prometheus-values.yaml  # Vähenda requests: cpu ja memory
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml
```

---

### Probleem: Targets on DOWN state'is

**Põhjus:** Service discovery või network issues

**Lahendus:**
```bash
# Kontrolli target pod'e
kubectl get pods -n monitoring -l app.kubernetes.io/name=kube-state-metrics
kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter

# Kontrolli service
kubectl get svc -n monitoring prometheus-kube-state-metrics

# Kontrolli endpoint
kubectl get endpoints -n monitoring prometheus-kube-state-metrics

# Test metrics endpoint
kubectl port-forward -n monitoring svc/prometheus-kube-state-metrics 8080:8080
curl http://localhost:8080/metrics
```

---

### Probleem: Port-forward ei tööta

**Lahendus:**
```bash
# Kontrolli, kas port 9090 on vaba
lsof -i :9090

# Kasuta teist porti
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9091:9090
# Ava: http://localhost:9091
```

---

## 📚 Mida Sa Õppisid?

✅ **Prometheus arhitektuur**
  - Time-series database
  - Pull-based metrics collection
  - Scrape targets

✅ **Helm chart installation**
  - kube-prometheus-stack
  - Custom values configuration
  - Multi-component deployment

✅ **PromQL basics**
  - Metric queries
  - Rate calculations
  - Aggregations (sum, avg)
  - Label filtering

✅ **Metrics types**
  - Node metrics (hardware)
  - Kubernetes object metrics (deployments, pods)
  - Container metrics (resource usage)

---

## 🚀 Järgmised Sammud

**Exercise 2: Application Metrics** - Kogume metrics user-service'st:
- ServiceMonitor CRD
- User-service `/metrics` endpoint
- Multi-environment monitoring (dev, staging, prod)
- Custom application metrics

```bash
cat exercises/02-application-metrics.md
```

---

## 💡 Best Practices

✅ **Retention:** Hoia metrics 7-30 päeva (balanseeri storage vs history)
✅ **Resource limits:** Sea CPU ja memory limits (prevent resource starvation)
✅ **High availability:** Production'is kasuta 2+ Prometheus replicas
✅ **Persistent storage:** Production'is kasuta PersistentVolumes
✅ **Query optimization:** Kasuta recording rules slow queries jaoks
✅ **Label cardinality:** Ära loo liiga palju unique label combinations (performance impact)

---

**Õnnitleme! Prometheus on nüüd running ja kogub metrics'eid! 🎉**

**Kestus:** 60 minutit
**Järgmine:** Exercise 2 - Application Metrics
