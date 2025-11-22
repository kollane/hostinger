# Lab 6: Monitoring & Logging

**Kestus:** 5 tundi (5 × 60 min)
**Eeldused:** Lab 1-5 läbitud (eriti Lab 5 - CI/CD)
**Tehnoloogiad:** Prometheus, Grafana, Loki, Promtail, AlertManager
**Keskkond:** Kubernetes cluster, Helm 3

---

## 📋 Ülevaade

Lab 6 keskendub **production-ready monitoring ja logging** süsteemide seadistamisele. Kasutame Cloud Native Computing Foundation (CNCF) tööriistade stack'i:

- **Prometheus** - Metrics collection ja time-series database
- **Grafana** - Visualization ja dashboards
- **Loki** - Log aggregation (Prometheus for logs)
- **Promtail** - Log shipper
- **AlertManager** - Alert routing ja notifications

**Integratsioon Lab 5-ga:**
- Lab 5 deployed rakendused kolmes keskkonnas (development, staging, production)
- Lab 5 lisas `/metrics` endpoint user-service'sse (Prometheus scraping jaoks)
- Lab 6 lisab monitoring ja alerting kõikidele keskkondadele

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

✅ Paigaldada Prometheus + Grafana stack Helm'iga
✅ Koguda metrics'eid Kubernetes cluster'ist ja rakendustest
✅ Luua custom Grafana dashboard'e PromQL päringutega
✅ Seadistada alert rules ja notifications (Slack)
✅ Implementeerida log aggregation Loki + Promtail'iga
✅ Kasutada PromQL ja LogQL päringuid troubleshooting'uks
✅ Monitoorida multi-environment deployment'e (dev/staging/prod)

---

## 🏗️ Arhitektuur

### Monitoring Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                           │
│                                                                 │
│  ┌────────────┐      ┌────────────┐      ┌────────────┐       │
│  │ Development│      │  Staging   │      │ Production │       │
│  │ Namespace  │      │ Namespace  │      │ Namespace  │       │
│  │            │      │            │      │            │       │
│  │ user-      │      │ user-      │      │ user-      │       │
│  │ service    │      │ service    │      │ service    │       │
│  │ :3000      │      │ :3000      │      │ :3000      │       │
│  │ /metrics   │      │ /metrics   │      │ /metrics   │       │
│  └──────┬─────┘      └──────┬─────┘      └──────┬─────┘       │
│         │                   │                   │              │
│         │                   │                   │              │
│         └───────────────────┼───────────────────┘              │
│                             │                                  │
│                             ▼ scrape (HTTP pull)               │
│                    ┌────────────────┐                          │
│                    │  Prometheus    │                          │
│                    │  :9090         │                          │
│                    │                │                          │
│                    │  - Time-series │                          │
│                    │    database    │                          │
│                    │  - PromQL      │                          │
│                    │  - Alert rules │                          │
│                    └────────┬───────┘                          │
│                             │                                  │
│              ┌──────────────┼──────────────┐                   │
│              │              │              │                   │
│              ▼              ▼              ▼                   │
│    ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│    │ kube-state │  │   node-    │  │ AlertManager│            │
│    │  metrics   │  │  exporter  │  │   :9093    │            │
│    └────────────┘  └────────────┘  └──────┬─────┘            │
│                                            │                   │
│                                            ▼                   │
│              ┌─────────────────────────────────┐               │
│              │  Grafana :3001                  │               │
│              │  - Dashboards                   │               │
│              │  - Data source: Prometheus      │               │
│              │  - Data source: Loki            │               │
│              └─────────────────────────────────┘               │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
                   Slack Notifications
```

### Logging Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                           │
│                                                                 │
│  ┌────────────┐      ┌────────────┐      ┌────────────┐       │
│  │ Pod        │      │ Pod        │      │ Pod        │       │
│  │            │      │            │      │            │       │
│  │ stdout/    │      │ stdout/    │      │ stdout/    │       │
│  │ stderr     │      │ stderr     │      │ stderr     │       │
│  └──────┬─────┘      └──────┬─────┘      └──────┬─────┘       │
│         │                   │                   │              │
│         │ (log files)       │                   │              │
│         ▼                   ▼                   ▼              │
│  ┌──────────────────────────────────────────────────┐          │
│  │            Promtail (DaemonSet)                  │          │
│  │            - Tails log files                     │          │
│  │            - Adds labels (pod, namespace, etc)   │          │
│  └──────────────────────┬───────────────────────────┘          │
│                         │ push logs (HTTP)                     │
│                         ▼                                      │
│                  ┌────────────┐                                │
│                  │   Loki     │                                │
│                  │   :3100    │                                │
│                  │            │                                │
│                  │ - Index    │                                │
│                  │   labels   │                                │
│                  │ - Store    │                                │
│                  │   logs     │                                │
│                  └──────┬─────┘                                │
│                         │                                      │
│                         │ LogQL queries                        │
│                         ▼                                      │
│                  ┌────────────┐                                │
│                  │  Grafana   │                                │
│                  └────────────┘                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📂 Labori Struktuur

```
06-monitoring-logging-lab/
├── README.md                          # See fail
├── exercises/                         # Harjutused
│   ├── 01-prometheus-setup.md         # 60 min - Prometheus install & config
│   ├── 02-application-metrics.md      # 60 min - User-service metrics collection
│   ├── 03-grafana-dashboards.md       # 60 min - Custom dashboards
│   ├── 04-alerting.md                 # 60 min - Alert rules & notifications
│   └── 05-log-aggregation.md          # 60 min - Loki + Promtail
├── solutions/                         # Reference lahendused
│   ├── prometheus/
│   │   ├── values.yaml                # Prometheus Helm values
│   │   └── servicemonitor.yaml        # ServiceMonitor for user-service
│   ├── grafana/
│   │   ├── values.yaml                # Grafana Helm values
│   │   └── dashboards/
│   │       ├── cluster-overview.json  # K8s cluster dashboard
│   │       └── user-service.json      # User-service dashboard
│   ├── alertmanager/
│   │   ├── values.yaml                # AlertManager config
│   │   └── alert-rules.yaml           # Prometheus alert rules
│   └── loki/
│       ├── values.yaml                # Loki Helm values
│       └── promtail-values.yaml       # Promtail config
└── setup.sh                           # Environment setup script
```

---

## 🔧 Eeldused

### Eelnevad labid

✅ **Lab 1-4:** Docker, Kubernetes alused ja advanced
✅ **Lab 5 (KOHUSTUSLIK):** CI/CD pipeline valmis
  - User-service deployed kolmes keskkonnas (development, staging, production)
  - `/metrics` endpoint lisatud user-service'sse
  - Helm charts kasutusel

### Tööriistad

✅ Kubernetes cluster töötab (`kubectl cluster-info`)
✅ Helm 3 paigaldatud (`helm version`)
✅ Lab 5 rakendused deployed (development, staging, production namespace)
✅ Vähemalt 4GB vaba RAM (Prometheus + Grafana + Loki)

### Teadmised

✅ Kubernetes põhimõisted (Pods, Deployments, Services)
✅ Helm chart'ide kasutamine
✅ HTTP metrics endpoints
🆕 PromQL query language (õpime laboris)
🆕 LogQL query language (õpime laboris)

---

## 🎓 Harjutused

### Exercise 1: Prometheus Setup (60 min)

**Eesmärk:** Paigalda Prometheus Helm chart'iga ja tutvusta põhilisi kontseptsioone.

**Teemad:**
- Prometheus arhitektuur
- Helm chart install (prometheus-community/kube-prometheus-stack)
- Prometheus UI tutvustus
- Basic PromQL queries
- Scrape targets verification

**Tulemus:**
- Prometheus töötab monitoring namespace'is
- Prometheus kogub metrics kube-state-metrics ja node-exporter'ist
- PromQL query oskus

### Exercise 2: Application Metrics (60 min)

**Eesmärk:** Konfigureeri user-service metrics collection kõigist keskkondadest.

**Teemad:**
- ServiceMonitor CRD (Custom Resource Definition)
- User-service /metrics endpoint
- Multi-environment monitoring (dev, staging, prod)
- Custom metrics labels
- PromQL queries application metrics'ele

**Tulemus:**
- User-service metrics visible Prometheus'es
- ServiceMonitor kõigile keskkondadele
- Dashboard'id kõigi keskkondade jaoks

### Exercise 3: Grafana Dashboards (60 min)

**Eesmärk:** Loo custom Grafana dashboard'e.

**Teemad:**
- Grafana install (included in kube-prometheus-stack)
- Data source configuration (Prometheus)
- Dashboard creation
  - Cluster overview (CPU, memory, pods)
  - User-service dashboard (requests, latency, errors)
  - Multi-environment comparison
- Panel types (Graph, Gauge, Table)
- Variables ja templating

**Tulemus:**
- Grafana accessible port-forward või Ingress kaudu
- Custom dashboard cluster metrics'ele
- Custom dashboard user-service'le
- Multi-environment view

### Exercise 4: Alerting (60 min)

**Eesmärk:** Seadista alert rules ja notifications.

**Teemad:**
- PrometheusRule CRD
- Alert rule syntax
- AlertManager configuration
- Slack webhook integration
- Alert states (Pending, Firing, Resolved)
- Severity levels (critical, warning, info)

**Alert näited:**
- High CPU usage (>80% 5 min)
- Pod crash looping
- High error rate (>5% requests)
- Service down

**Tulemus:**
- Alert rules konfigureeritud
- Slack notifications töötavad
- Test alerts triggered ja resolved

### Exercise 5: Log Aggregation with Loki (60 min)

**Eesmärk:** Implementeeri log aggregation Loki + Promtail'iga.

**Teemad:**
- Loki arhitektuur (labels vs indexed data)
- Loki + Promtail install Helm'iga
- Promtail DaemonSet (log collection)
- LogQL query language
- Grafana Loki data source
- Log correlation with metrics

**LogQL queries:**
- Filter by namespace: `{namespace="production"}`
- Filter by pod: `{pod=~"user-service-.*"}`
- Filter by log level: `{namespace="production"} |= "ERROR"`
- Rate of errors: `rate({namespace="production"} |= "ERROR" [5m])`

**Tulemus:**
- Loki kogub logs kõigist pod'idest
- LogQL queries töötavad
- Grafana displays logs
- Logs + metrics correlation

---

## 🚀 Kiirstart

### Automaatne Setup (Soovitatud)

```bash
# Käivita setup script
chmod +x setup.sh
./setup.sh
```

**Script kontrollib:**
- ✅ Kubernetes cluster connectivity
- ✅ Helm installation
- ✅ Lab 5 deployed applications (development, staging, production)
- ✅ Available resources (RAM, disk)
- ✅ Monitoring namespace creation

### Manuaalne Setup

```bash
# 1. Kontrolli eelduseid
kubectl cluster-info
helm version

# 2. Kontrolli Lab 5 rakendusi
kubectl get deployments -n development
kubectl get deployments -n staging
kubectl get deployments -n production

# 3. Kontrolli user-service /metrics endpoint
kubectl port-forward -n production deployment/user-service 3000:3000
curl http://localhost:3000/metrics

# 4. Loo monitoring namespace
kubectl create namespace monitoring

# 5. Alusta Exercise 1'st
cat exercises/01-prometheus-setup.md
```

---

## 📊 Monitoorimise Metrikad

### Cluster-Level Metrics

- **Node metrics:** CPU, memory, disk, network
- **Pod metrics:** CPU, memory, restarts, status
- **Deployment metrics:** Replicas, available, unavailable
- **Resource quotas:** Namespace limits

### Application-Level Metrics

User-service (Node.js + Express):
- `http_requests_total` - Total HTTP requests
- `http_request_duration_seconds` - Request latency
- `http_requests_errors_total` - Error count
- `nodejs_heap_size_used_bytes` - Memory usage
- `nodejs_eventloop_lag_seconds` - Event loop lag

### Custom Business Metrics

- User registrations per hour
- Active users
- JWT tokens issued
- Database query latency

---

## 🔍 Kasulikud PromQL Queries

### Cluster Health

```promql
# CPU usage by node
sum by (node) (rate(node_cpu_seconds_total{mode!="idle"}[5m]))

# Memory usage by namespace
sum by (namespace) (container_memory_usage_bytes)

# Pod restart count
sum by (namespace, pod) (kube_pod_container_status_restarts_total)
```

### Application Metrics

```promql
# Request rate (requests per second)
rate(http_requests_total{namespace="production"}[5m])

# Average latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate
rate(http_requests_errors_total[5m]) / rate(http_requests_total[5m])
```

### Multi-Environment Comparison

```promql
# Compare request rate across environments
sum by (namespace) (rate(http_requests_total[5m]))

# Compare error rates
sum by (namespace) (rate(http_requests_errors_total[5m]))
```

---

## 🔗 Integratsioon Eelmiste Labidega

**Lab 5 → Lab 6:**
- Lab 5 deployed user-service kolmes keskkonnas
- Lab 5 lisas `/metrics` endpoint (Exercise 4: Quality Gates)
- Lab 6 kogub need metrics Prometheus'ega
- Lab 6 visualizeerib Grafana dashboard'is
- Lab 6 alertib probleemide korral

**Lab 4 → Lab 6:**
- Lab 4 Helm charts kasutatakse Lab 6'ks
- HPA metrics monitooring
- Ingress metrics (kui konfigureeritav)

**Lab 3 → Lab 6:**
- Kubernetes cluster metrics
- Pod ja deployment monitoring

---

## 📚 Õppematerjalid

### Official Documentation

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [LogQL Language](https://grafana.com/docs/loki/latest/logql/)

### Prometheus Operator

- [kube-prometheus-stack Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)

---

## ⚠️ Troubleshooting

### Prometheus ei kogu metrics'eid

```bash
# Kontrolli Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Ava brauseris: http://localhost:9090/targets

# Kontrolli ServiceMonitor'eid
kubectl get servicemonitors -n monitoring
kubectl describe servicemonitor user-service -n monitoring
```

### Grafana ei näita andmeid

```bash
# Kontrolli Prometheus data source
kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80
# Ava brauseris: http://localhost:3001
# Configuration → Data Sources → Prometheus → Test

# Kontrolli Prometheus'es, kas metrics on olemas
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Tee PromQL query: http_requests_total
```

### Loki ei kogu logs'e

```bash
# Kontrolli Promtail pods
kubectl get pods -n monitoring -l app=promtail

# Kontrolli Promtail logs
kubectl logs -n monitoring -l app=promtail --tail=50

# Test Loki
kubectl port-forward -n monitoring svc/loki 3100:3100
curl http://localhost:3100/ready
```

---

## 🎯 Labori Eesmärgid

Peale Lab 6 läbimist on sul:

✅ **Production-ready monitoring stack**
  - Prometheus kogub metrics cluster'ist ja rakendustest
  - Grafana visualizeerib kõik andmed
  - AlertManager saadab teavitusi

✅ **Log aggregation**
  - Loki kogub kõik logs
  - LogQL päringud troubleshooting'uks
  - Logs + metrics correlation

✅ **Multi-environment visibility**
  - Development, staging, production monitooring
  - Keskkondade võrdlus
  - Environment-specific alerts

✅ **Proactive alerting**
  - Alert rules critical events'ile
  - Slack notifications
  - Alert management

✅ **Observability skills**
  - PromQL mastery
  - LogQL queries
  - Dashboard creation
  - Troubleshooting oskused

---

**Alusta:** `./setup.sh` ja seejärel `cat exercises/01-prometheus-setup.md`

**Kestus:** 5 tundi (5 × 60 min)

**Õnn kaasa! 🚀📊📈**
