# Harjutus 5: Alerting & Monitoring

**Kestus:** 60 minutit
**Eesmärk:** Seadistada alerting rules ja notification channels

---

## 📋 Ülevaade

Selles harjutuses õpid seadistama **Prometheus Alerting** ja **Alertmanager** - süsteeme, mis saadavad notificatione kui metrics või logs näitavad probleeme. Loome alerting rules (high CPU, pod down, error rate) ja konfigureerime notification channel'id (Slack, email).

**Alerting** on production monitoring'u kriitiline osa - see teavitab sind probleemidest **enne** kui kasutajad märkavad või süsteem failibub.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua Prometheus alerting rules
- ✅ Konfigureerida Alertmanager
- ✅ Seadistada notification channels
- ✅ Testida alerting'ut
- ✅ Tuunida alert thresholds
- ✅ Silencida alertseid
- ✅ Vaadata alerting history

---

## 🏗️ Arhitektuur

```
┌───────────────────────────────────────────────────────┐
│  Prometheus                                           │
│                                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ Alerting Rules (PrometheusRule CRD)             │ │
│  │ - High CPU (> 80%)                              │ │
│  │ - Pod Down (up == 0)                            │ │
│  │ - High Error Rate (> 5%)                        │ │
│  └────────────┬────────────────────────────────────┘ │
│               │ evaluates rules every 15s            │
│               ▼                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ Alert State                                     │ │
│  │ - Pending → Firing → Resolved                   │ │
│  └────────────┬────────────────────────────────────┘ │
│               │ sends alerts                          │
│               ▼                                       │
│  ┌─────────────────────────────────────────────────┐ │
│  │ Alertmanager                                    │ │
│  │ - Grouping                                      │ │
│  │ - Routing (by severity, team)                   │ │
│  │ - Deduplication                                 │ │
│  │ - Silencing                                     │ │
│  └────────────┬────────────────────────────────────┘ │
│               │ notifications                         │
└───────────────┼───────────────────────────────────────┘
                │
                ▼
    ┌──────────────────────┐  ┌──────────────────┐
    │  Slack / Discord     │  │  Email / PagerDuty│
    │  #alerts channel     │  │  ops@company.com │
    └──────────────────────┘  └──────────────────┘
```

---

## 📝 Sammud

### Samm 1: Loo Alerting Rules (15 min)

**PrometheusRule CRD** defineerib alert'id.

Loo fail `prometheus-rules.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: user-service-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus
spec:
  groups:
  - name: user-service
    interval: 30s
    rules:

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Infrastructure Alerts
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    - alert: HighCPUUsage
      expr: |
        (100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 80
      for: 5m
      labels:
        severity: warning
        team: platform
      annotations:
        summary: "High CPU usage on {{ $labels.instance }}"
        description: "CPU usage is {{ $value | humanize }}% on {{ $labels.instance }}"

    - alert: HighMemoryUsage
      expr: |
        (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
      for: 5m
      labels:
        severity: warning
        team: platform
      annotations:
        summary: "High memory usage on {{ $labels.instance }}"
        description: "Memory usage is {{ $value | humanize }}% on {{ $labels.instance }}"

    - alert: DiskSpaceLow
      expr: |
        (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
      for: 10m
      labels:
        severity: critical
        team: platform
      annotations:
        summary: "Low disk space on {{ $labels.instance }}"
        description: "Only {{ $value | humanize }}% disk space available on {{ $labels.instance }}"

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Kubernetes Alerts
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    - alert: PodDown
      expr: |
        up{job="kubernetes-pods", namespace="default", pod=~"user-service.*"} == 0
      for: 1m
      labels:
        severity: critical
        team: backend
      annotations:
        summary: "Pod {{ $labels.pod }} is down"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has been down for more than 1 minute"

    - alert: PodCrashLooping
      expr: |
        rate(kube_pod_container_status_restarts_total{namespace="default", pod=~"user-service.*"}[15m]) > 0
      for: 5m
      labels:
        severity: warning
        team: backend
      annotations:
        summary: "Pod {{ $labels.pod }} is crash looping"
        description: "Pod {{ $labels.pod }} has restarted {{ $value }} times in the last 15 minutes"

    - alert: DeploymentReplicasMismatch
      expr: |
        kube_deployment_spec_replicas{namespace="default", deployment="user-service"}
        !=
        kube_deployment_status_replicas_available{namespace="default", deployment="user-service"}
      for: 5m
      labels:
        severity: warning
        team: backend
      annotations:
        summary: "Deployment {{ $labels.deployment }} replicas mismatch"
        description: "Desired replicas != Available replicas for {{ $labels.deployment }}"

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # Application Alerts
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    - alert: HighErrorRate
      expr: |
        (
          sum(rate(http_requests_total{app="user-service", status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total{app="user-service"}[5m]))
        ) * 100 > 5
      for: 2m
      labels:
        severity: critical
        team: backend
      annotations:
        summary: "High error rate for user-service"
        description: "Error rate is {{ $value | humanize }}% for user-service"

    - alert: HighLatency
      expr: |
        histogram_quantile(0.95,
          sum(rate(http_request_duration_seconds_bucket{app="user-service"}[5m])) by (le)
        ) > 1
      for: 5m
      labels:
        severity: warning
        team: backend
      annotations:
        summary: "High latency for user-service"
        description: "P95 latency is {{ $value | humanize }}s for user-service"

    - alert: NoTrafficFor10Minutes
      expr: |
        rate(http_requests_total{app="user-service"}[10m]) == 0
      for: 10m
      labels:
        severity: warning
        team: backend
      annotations:
        summary: "No traffic to user-service"
        description: "User-service has received no requests for 10 minutes"
```

**Apply rules:**

```bash
kubectl apply -f prometheus-rules.yaml

# Kontrolli
kubectl get prometheusrule -n monitoring

# NAME                   AGE
# user-service-alerts    10s
```

---

### Samm 2: Kontrolli Alerts Prometheus UI's (5 min)

**Port forward Prometheus:**

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

**Prometheus UI → Alerts:**

http://localhost:9090/alerts

**Peaks näitama:**
- HighCPUUsage (Inactive või Pending või Firing)
- HighMemoryUsage
- PodDown
- HighErrorRate
- ...

**Alert state'id:**
- **Inactive:** Condition false
- **Pending:** Condition true, aga `for` duration pole veel möödas
- **Firing:** Condition true ja `for` duration möödas → Alertmanager'ile saadetud

---

### Samm 3: Seadista Alertmanager (10 min)

**Alertmanager config on juba olemas (kube-prometheus-stack).**

Kontrolli config:

```bash
kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager \
  -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

# Peaks näitama default config:
# global: ...
# route: ...
# receivers: ...
```

**Loo custom Alertmanager config:**

Loo fail `alertmanager-config.yaml`:

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

    # Routing tree
    route:
      receiver: 'default'
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h

      routes:
      # Critical alerts → Slack + Email
      - match:
          severity: critical
        receiver: 'critical-alerts'
        group_wait: 10s
        group_interval: 5m
        repeat_interval: 1h

      # Warning alerts → Slack only
      - match:
          severity: warning
        receiver: 'warning-alerts'
        group_wait: 30s
        group_interval: 10m
        repeat_interval: 4h

    # Receivers (notification destinations)
    receivers:
    - name: 'default'
      # Null receiver (no notifications)

    - name: 'critical-alerts'
      slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts-critical'
        title: '🚨 CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

    - name: 'warning-alerts'
      slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts-warning'
        title: '⚠️  WARNING: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

**Apply config:**

```bash
kubectl apply -f alertmanager-config.yaml

# Restart Alertmanager pod
kubectl delete pod -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0
```

---

### Samm 4: Seadista Slack Notifications (10 min)

**Loo Slack Incoming Webhook:**

1. Mine https://api.slack.com/apps
2. **Create New App** → **From scratch**
3. **App Name:** Prometheus Alerts
4. **Workspace:** Vali oma workspace
5. **Incoming Webhooks** → **Activate Incoming Webhooks** → ON
6. **Add New Webhook to Workspace**
7. Vali channel: `#alerts` (või loo uus)
8. Kopeeri **Webhook URL:** `https://hooks.slack.com/services/T.../B.../...`

**Lisa webhook Alertmanager config'i:**

Muuda `alertmanager-config.yaml`:

```yaml
slack_configs:
- api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
  channel: '#alerts'
  ...
```

Apply uuesti:

```bash
kubectl apply -f alertmanager-config.yaml
kubectl delete pod -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0
```

---

### Samm 5: Testi Alerting (10 min)

**Genereeri test alert:**

**Variant A: Simuleeri high CPU:**

```bash
# SSH serverisse
ssh janek@kirjakast

# Stress CPU
stress-ng --cpu 4 --timeout 300s

# Või kui stress-ng pole installed:
while true; do :; done &  # Korda 4x (4 background processes)
```

**Variant B: Stop pod (PodDown alert):**

```bash
kubectl scale deployment user-service --replicas=0

# Wait 1 minute → PodDown alert fires

# Restore
kubectl scale deployment user-service --replicas=3
```

**Variant C: Generate errors (HighErrorRate alert):**

```bash
# Muuda app'i, et tagastada 500 errors
# Või tee vigaseid request'e:

for i in {1..100}; do
  curl http://user-service/non-existent-route
done
```

**Kontrolli Prometheus UI:**

http://localhost:9090/alerts

Alert peaks liikuma: Inactive → Pending → **Firing**

---

### Samm 6: Vaata Alertmanager UI (5 min)

**Port forward Alertmanager:**

```bash
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093
```

**Alertmanager UI:**

http://localhost:9093

**Peaks näitama:**
- **Alerts:** Aktiivsed alert'id (Firing)
- **Silences:** Vaikestatud alert'id
- **Status:** Alertmanager config

**Silence alert:**

1. Kliki alert'ile
2. **Silence** button
3. **Duration:** 1h
4. **Comment:** "Planned maintenance"
5. **Create**

Alert on nüüd silenced 1 tunniks - notificatione ei saadeta.

---

### Samm 7: Loo Grafana Alert (5 min)

**Grafana native alerting:**

1. Grafana → Dashboard → "User Service Dashboard"
2. Edit "High Memory Usage" panel
3. Kliki **Alert** tab → **Create alert rule from this panel**
4. **Rule name:** User Service Memory Alert
5. **Evaluate every:** 1m
6. **For:** 5m
7. **Condition:** `WHEN last() OF query(A) IS ABOVE 500`
8. **Folder:** General
9. **Group:** User Service
10. Save

**Contact point:**

1. Grafana → ☰ → **Alerting** → **Contact points**
2. **New contact point**
3. **Name:** Slack
4. **Integration:** Slack
5. **Webhook URL:** (paste Slack webhook)
6. **Test** → Save

---

## ✅ Kontrolli Tulemusi

- [ ] **Alerting rules:**
  - [ ] PrometheusRule created
  - [ ] Alerts visible Prometheus UI

- [ ] **Alertmanager:**
  - [ ] Config applied
  - [ ] Slack webhook configured
  - [ ] Routing rules defined

- [ ] **Notifications:**
  - [ ] Slack channel receives alerts
  - [ ] Alert formatting correct

- [ ] **Testing:**
  - [ ] Test alert fired
  - [ ] Notification received
  - [ ] Alert resolved

---

## 🐛 Troubleshooting

### Probleem 1: Alerts ei fire

**Diagnoos:**

```bash
# Kontrolli PrometheusRule
kubectl get prometheusrule -n monitoring user-service-alerts -o yaml

# Kontrolli Prometheus logs
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 -c prometheus
```

**Lahendus:** Testi query Prometheus UI's (Graph tab).

---

### Probleem 2: Slack notificatione ei tule

**Diagnoos:**

```bash
# Kontrolli Alertmanager logs
kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0

# Peaks näitama:
# level=info msg="Notify successful" receiver=slack
```

**Lahendus:** Kontrolli Slack webhook URL (viga URL'is).

---

## 🎓 Õpitud Mõisted

### Alerting:
- **Alert rule:** PromQL query + threshold + duration
- **Pending:** Condition true, aga `for` duration pole veel möödas
- **Firing:** Alert active (saadetud Alertmanager'ile)
- **Resolved:** Condition false (alert enam ei fire)

### Alertmanager:
- **Routing:** Alert'ide suunamine receiver'itele (by severity, team)
- **Grouping:** Grupeeri sarnased alert'id (avoid alert storm)
- **Deduplication:** Ära saada sama alert'i mitu korda
- **Silencing:** Vaikesta alert'id (planned maintenance)

### Severity:
- **critical:** Production down, immediate action
- **warning:** Degraded performance, investigate soon
- **info:** Informational, no action needed

---

## 💡 Parimad Tavad

1. **Alert on symptoms, not causes** - Alert "high error rate", not "pod restarted"
2. **Tune thresholds** - Avoid false positives (too sensitive) ja false negatives (not sensitive enough)
3. **Use `for` duration** - Avoid alerting on transient spikes (use 5m `for`)
4. **Severity levels** - Critical (immediate), Warning (investigate), Info
5. **Actionable alerts** - Include runbook link või troubleshooting steps
6. **Alert fatigue** - Too many alerts → ignored (tune or disable)
7. **On-call rotation** - Define who responds to alerts
8. **Escalation** - Critical → PagerDuty (page on-call), Warning → Slack
9. **SLO-based alerting** - Alert on SLO violations (error budget)
10. **Test alerts regularly** - Fire test alerts to verify notification channels

---

## 🔗 Kokkuvõte

**Õnnitleme! Oled läbinud Lab 6: Monitoring & Logging!**

**Omandatud oskused:**
- ✅ Prometheus monitoring
- ✅ Grafana dashboards
- ✅ Application metrics
- ✅ Loki log aggregation
- ✅ Alerting & notifications

**Täielik monitoring stack:**
- Prometheus → Metrics collection
- Grafana → Visualization
- Loki → Log aggregation
- Alertmanager → Alerting

**Järgmine samm:** Apply these skills production'is!

---

## 📚 Viited

- [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/overview/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Alerting](https://grafana.com/docs/grafana/latest/alerting/)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)

---

**Õnnitleme! Monitoring & Logging on nüüd seadistatud! 🎉📊📋🔔**
