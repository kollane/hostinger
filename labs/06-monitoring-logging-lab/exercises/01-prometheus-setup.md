# Harjutus 1: Prometheus Setup

**Kestus:** 60 minutit
**Eesmärk:** Paigaldada ja seadistada Prometheus Kubernetes cluster'is

---

## 📋 Ülevaade

Selles harjutuses õpid paigaldama **Prometheus** - avatud lähtekoodiga monitoring ja alerting süsteemi. Prometheus kogub metrics'eid Kubernetes cluster'ist, pod'idest ja rakendustest ning salvestab need time-series andmebaasis.

**Prometheus** on Cloud Native Computing Foundation (CNCF) projekt ja de facto standard Kubernetes monitoring'uks. See kasutab pull-based mudelit - scrape'ib endpoints'e regulaarselt ja kogub metrics'eid.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Paigaldada Prometheus Helm Chart'iga
- ✅ Konfigureerida Prometheus scrape targets
- ✅ Vaadata Prometheus UI'd
- ✅ Kirjutada PromQL päringuid
- ✅ Seadistada ServiceMonitor'eid
- ✅ Mõista Prometheus arhitektuuri
- ✅ Debuggida metrics collection'i

---

## 🏗️ Arhitektuur

```
┌────────────────────────────────────────────────────┐
│         Kubernetes Cluster                         │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  Prometheus Server                           │ │
│  │  - Time-series DB                            │ │
│  │  - Scrape targets                            │ │
│  │  - PromQL query engine                       │ │
│  └────────┬─────────────────────────────────────┘ │
│           │ scrapes (HTTP pull)                   │
│           ▼                                        │
│  ┌─────────────────┐  ┌─────────────────┐        │
│  │ kube-state-     │  │ node-exporter   │        │
│  │ metrics         │  │ (host metrics)  │        │
│  │ (K8s objects)   │  └─────────────────┘        │
│  └─────────────────┘                              │
│           │                                        │
│           ▼                                        │
│  ┌─────────────────────────────────────────────┐  │
│  │ Application Pods                            │  │
│  │ - user-service:3000/metrics                 │  │
│  │ - todo-service:8081/metrics                 │  │
│  └─────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────┘

Prometheus scrapes all targets every 15s (configurable)
```

---

## 📝 Sammud

### Samm 1: Loo Monitoring Namespace (5 min)

**Loo eraldi namespace monitoring'uks:**

```bash
# Loo monitoring namespace
kubectl create namespace monitoring

# Lisa label (Prometheus operator kasutab seda)
kubectl label namespace monitoring name=monitoring

# Kontrolli
kubectl get namespaces monitoring --show-labels

# Peaks näitama:
# NAME         STATUS   AGE   LABELS
# monitoring   Active   10s   name=monitoring
```

---

### Samm 2: Lisa Prometheus Helm Repository (5 min)

**Lisa Prometheus Community Helm repo:**

```bash
# Lisa Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Update repo
helm repo update

# Otsi Prometheus charts
helm search repo prometheus-community | grep -E "kube-prometheus-stack"

# Peaks näitama:
# prometheus-community/kube-prometheus-stack    Latest    Full Prometheus stack...

# Vaata chart detaile
helm show chart prometheus-community/kube-prometheus-stack
```

**kube-prometheus-stack** sisaldab:
- Prometheus Operator
- Prometheus server
- Alertmanager
- Grafana (integration)
- kube-state-metrics
- node-exporter
- Default dashboards ja alerts

---

### Samm 3: Loo Prometheus Values File (10 min)

**Loo custom Helm values fail:**

Loo fail `prometheus-values.yaml`:

```yaml
# Prometheus Operator Configuration
prometheus:
  prometheusSpec:
    # Retention period
    retention: 7d
    retentionSize: "10GB"

    # Resources
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 2Gi

    # Storage
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

    # ServiceMonitor selector
    serviceMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelector: {}
    podMonitorSelector: {}

# Grafana (included)
grafana:
  enabled: true
  adminPassword: "admin"  # Change in production!

  # Persistent storage
  persistence:
    enabled: true
    size: 5Gi

  # Resources
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

# Alertmanager
alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 5Gi

# kube-state-metrics (K8s object metrics)
kube-state-metrics:
  enabled: true

# node-exporter (host metrics)
prometheus-node-exporter:
  enabled: true

# Default ServiceMonitors
defaultRules:
  create: true
  rules:
    alertmanager: true
    etcd: false  # Ei kasuta kui cluster pole self-hosted
    kubeApiserver: true
    kubeScheduler: false
    kubeStateMetrics: true
    kubelet: true
    kubernetesApps: true
    kubernetesResources: true
    kubernetesStorage: true
    kubernetesSystem: true
    node: true
    prometheus: true
```

**Values file selgitus:**

- **retention:** Kui kaua metrics'eid säilitada (7 päeva)
- **storageSpec:** Persistent volume metrics'ide jaoks (10GB)
- **serviceMonitorSelector:** Automaatne ServiceMonitor'ite discovery
- **grafana.enabled:** Kaasas Grafana (automaatne integration)
- **defaultRules:** Built-in alerting rules

---

### Samm 4: Paigalda Prometheus Stack (10 min)

**Install Prometheus kube-prometheus-stack Helm chart'iga:**

```bash
# Install Prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml

# Peaks näitama:
# NAME: prometheus
# LAST DEPLOYED: ...
# NAMESPACE: monitoring
# STATUS: deployed
# REVISION: 1

# Kontrolli pod'e
kubectl get pods -n monitoring

# Oodatud pod'id:
# NAME                                                   READY   STATUS
# prometheus-kube-prometheus-operator-xxxxx              1/1     Running
# prometheus-prometheus-kube-prometheus-prometheus-0     2/2     Running
# prometheus-grafana-xxxxx                               3/3     Running
# prometheus-kube-state-metrics-xxxxx                    1/1     Running
# prometheus-prometheus-node-exporter-xxxxx              1/1     Running
# alertmanager-prometheus-kube-prometheus-alertmanager-0 2/2     Running

# Kontrolli services
kubectl get svc -n monitoring

# Oodatud services:
# NAME                                      TYPE        CLUSTER-IP      PORT(S)
# prometheus-kube-prometheus-prometheus     ClusterIP   10.x.x.x        9090/TCP
# prometheus-grafana                        ClusterIP   10.x.x.x        80/TCP
# alertmanager-operated                     ClusterIP   None            9093,9094,9094/TCP
```

**Paigaldus võtab ~2-3 minutit**, kuni kõik pod'id on Running.

---

### Samm 5: Ava Prometheus UI (5 min)

**Port forward Prometheus UI'le:**

```bash
# Port forward Prometheus UI
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Ava brauseris:
# http://localhost:9090
```

**Prometheus UI'is:**

1. **Status → Targets** - Vaata kõiki scrape targets
   - Peaks näitama: kube-state-metrics, node-exporter, Prometheus, Alertmanager, kubelet, jne
   - Status: UP (roheline)

2. **Graph tab** - Testi PromQL päringuid:
   ```promql
   # Kõik metrics
   {__name__=~".+"}

   # Node CPU usage
   node_cpu_seconds_total

   # Pod memory usage
   container_memory_usage_bytes

   # HTTP requests (kui app metrics on)
   http_requests_total
   ```

3. **Status → Configuration** - Vaata Prometheus config'i

---

### Samm 6: Testi PromQL Päringuid (10 min)

**Prometheus Query Language (PromQL) näited:**

**1. Node CPU kasutus (%):**

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**2. Pod memory kasutus (MB):**

```promql
sum(container_memory_usage_bytes{pod=~"user-service.*"}) / 1024 / 1024
```

**3. Pod restart count:**

```promql
kube_pod_container_status_restarts_total
```

**4. Disk space vaba (%):**

```promql
node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100
```

**5. HTTP request rate:**

```promql
rate(http_requests_total[5m])
```

**Testi Prometheus UI's:**

1. Mine Graph tab → sisesta query → Execute
2. Vaata Graph või Table view
3. Proovi erinevaid PromQL funktsioone:
   - `rate()` - per-second rate
   - `sum()` - summation
   - `avg()` - average
   - `by (label)` - group by label

---

### Samm 7: Loo ServiceMonitor (10 min)

**ServiceMonitor** = Prometheus Operator CRD, mis automaatselt konfigureerib scrape target'id.

**Näide: ServiceMonitor user-service'ile:**

Loo fail `servicemonitor-user-service.yaml`:

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

**ServiceMonitor selgitus:**

- **selector:** Leia Service label'i järgi (`app=user-service`)
- **endpoints.port:** Service port nimi (mitte number!)
- **path:** Metrics endpoint (`/metrics`)
- **interval:** Scrape interval (15s)

**Apply ServiceMonitor:**

```bash
# Apply ServiceMonitor
kubectl apply -f servicemonitor-user-service.yaml

# Kontrolli
kubectl get servicemonitor -n default

# NAME                   AGE
# user-service-monitor   10s

# Vaata Prometheus UI's:
# Status → Targets → servicemonitor/default/user-service-monitor
```

**NB:** Rakendus peab eksponeerima `/metrics` endpoint'i (järgmises harjutuses lisame).

---

### Samm 8: Kontrolli Metrics Collection (5 min)

**Kontrolli, et Prometheus kogub metrics'eid:**

```bash
# Prometheus UI
# http://localhost:9090

# Graph tab:
# Sisesta query:
up

# Peaks näitama kõiki targets'e:
# up{job="prometheus"} 1
# up{job="kube-state-metrics"} 1
# up{job="node-exporter"} 1
# up{job="kubelet"} 1
```

**up=1** → target on UP ja scraping toimib
**up=0** → target on DOWN või unreachable

**Kontrolli specific target:**

```promql
up{job="kube-state-metrics"}
```

**Kontrolli scrape duration:**

```promql
scrape_duration_seconds
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Prometheus stack:**
  - [ ] Prometheus server (pod running)
  - [ ] Grafana (pod running)
  - [ ] Alertmanager (pod running)
  - [ ] kube-state-metrics (pod running)
  - [ ] node-exporter (pod running)

- [ ] **Prometheus UI:**
  - [ ] Accessible (port-forward 9090)
  - [ ] Status → Targets (all UP)
  - [ ] Graph tab (PromQL queries work)

- [ ] **Persistent storage:**
  - [ ] PVC created (10GB prometheus)
  - [ ] PVC created (5GB grafana)

- [ ] **ServiceMonitor:**
  - [ ] Created (user-service-monitor)
  - [ ] Visible Prometheus targets

---

## 🐛 Troubleshooting

### Probleem 1: Prometheus pod ei käivitu - Pending

**Sümptom:**
```bash
kubectl get pods -n monitoring
# NAME                                   READY   STATUS    RESTARTS   AGE
# prometheus-prometheus-0                0/2     Pending   0          5m
```

**Põhjus:** PVC ei saa bind'i (storage class puudub).

**Diagnoos:**

```bash
kubectl get pvc -n monitoring

# NAME                                 STATUS    VOLUME   STORAGECLASS
# prometheus-prometheus-db-0           Pending            manual
```

**Lahendus:**

**Variant A: Kasuta local-path (Minikube/K3s):**

```bash
# Minikube
minikube addons enable storage-provisioner

# K3s (local-path juba olemas)
kubectl get storageclass

# Peaks näitama:
# NAME                 PROVISIONER
# local-path (default) rancher.io/local-path
```

**Variant B: Disable persistence (testing):**

```yaml
# prometheus-values.yaml
prometheus:
  prometheusSpec:
    storageSpec: null  # Disable persistence
```

---

### Probleem 2: ServiceMonitor ei ilmu Prometheus targets'is

**Sümptom:**

ServiceMonitor created, aga pole näha Prometheus UI → Status → Targets.

**Diagnoos:**

```bash
# Kontrolli ServiceMonitor
kubectl get servicemonitor -n default user-service-monitor -o yaml

# Kontrolli, kas Service eksisteerib
kubectl get svc user-service -n default

# Kontrolli, kas label match
kubectl get svc user-service -n default --show-labels
```

**Lahendus:**

1. **Service peab eksisteerima:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: user-service
  labels:
    app: user-service  # Must match ServiceMonitor selector
spec:
  ports:
  - name: http  # Must match ServiceMonitor endpoints.port
    port: 80
    targetPort: 3000
  selector:
    app: user-service
```

2. **ServiceMonitor peab olema õiges namespace's:**

- ServiceMonitor namespace = Service namespace (tavaliselt)
- Või kasuta `namespaceSelector` (advanced)

---

### Probleem 3: Metrics endpoint 404

**Sümptom:**

```bash
# Prometheus UI → Targets
# user-service-monitor: DOWN
# Error: HTTP 404 Not Found
```

**Põhjus:** Rakendus ei eksponeerib `/metrics` endpoint'i.

**Lahendus:**

Järgmises harjutuses (03-application-metrics.md) lisame `/metrics` endpoint Node.js rakendusse.

---

## 🎓 Õpitud Mõisted

### Prometheus:
- **Time-series database:** Metrics salvestamine ajatelg (timestamp + value)
- **Scraping:** Pull-based metrics collection (HTTP GET /metrics)
- **Target:** Endpoint, mida Prometheus scrape'ib
- **Job:** Grupp targets'e (nt `node-exporter`, `kubelet`)
- **Instance:** Individuaalne target (nt specific pod IP)

### Prometheus Operator:
- **Operator:** Kubernetes controller, mis haldab Prometheus instance'id
- **ServiceMonitor:** CRD (Custom Resource Definition) scrape config'iks
- **PodMonitor:** Sama mis ServiceMonitor, aga pod'ide jaoks
- **PrometheusRule:** CRD alerting rules'ide jaoks

### PromQL:
- **Instant vector:** Metrics snapshot (current value)
- **Range vector:** Metrics time range (last 5m)
- **Aggregation:** sum(), avg(), max(), min()
- **rate():** Per-second rate over time range
- **by (label):** Group by label

### Metrics Types:
- **Counter:** Monotonically increasing (http_requests_total)
- **Gauge:** Up/down value (memory_usage_bytes)
- **Histogram:** Distribution (request_duration_seconds)
- **Summary:** Quantiles (request_duration_summary)

---

## 💡 Parimad Tavad

1. **Kasuta Helm charts** - kube-prometheus-stack on battle-tested
2. **Persistent storage** - Ära kaota metrics'eid pod restart'il
3. **Retention policy** - Balance storage vs history (7-30 päeva)
4. **ServiceMonitor** - Ära harda-code scrape configs
5. **Resource limits** - Prometheus võib sööda palju mälu
6. **High availability** - Production'is kasuta 2+ Prometheus replicas
7. **Remote write** - Long-term storage (Thanos, Cortex)
8. **Federation** - Multi-cluster monitoring
9. **Security** - Enable authentication (OAuth, basic auth)
10. **Alerting** - Seadista critical alerts (järgmises harjutuses)

---

## 🔗 Järgmine Samm

Nüüd sul on Prometheus töötamas! Järgmises harjutuses seadistame **Grafana dashboards** - visualiseerime metrics'eid ilusate graafikutega.

**Jätka:** [Harjutus 2: Grafana Dashboards](02-grafana-dashboards.md)

---

## 📚 Viited

### Prometheus:
- [Prometheus Documentation](https://prometheus.io/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)

### Helm Charts:
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Community Charts](https://prometheus-community.github.io/helm-charts/)

### Kubernetes:
- [ServiceMonitor CRD](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#servicemonitor)

---

**Õnnitleme! Prometheus on nüüd töötav ja kogub metrics'eid! 📊**
