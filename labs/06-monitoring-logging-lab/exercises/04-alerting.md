# Harjutus 4: Alerting & Notifications

**Kestus:** 60 minutit
**Eesmärk:** Seadista alert rules ja notifications probleemidest automaatselt teavitamiseks.

---

## 📋 Ülevaade

Selles harjutuses seadistame **alerting** - automaatse monitooringu, mis teavitab probleemidest (high CPU, pod crashes, high error rate). Kasutame:

- **PrometheusRule CRD** - Alert rules definition
- **AlertManager** - Alert routing ja notifications
- **Slack** - Notification channel (optional: Email, PagerDuty, etc)

**Alert workflow:**
1. Prometheus evaluates alert rules (every 30s)
2. Alert fires kui tingimus on true
3. AlertManager receives alert
4. AlertManager routes alert (grouping, throttling)
5. Notification sent (Slack, Email, etc)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

✅ Luua PrometheusRule CRD alert rules jaoks
✅ Määrata alert severity levels (critical, warning, info)
✅ Konfigureerida AlertManager
✅ Seadistada Slack webhook notifications
✅ Testida alerts (trigger ja resolve)
✅ Mõista alert states (Pending, Firing, Resolved)
✅ Kasutada alert labels ja annotations
✅ Silencing alerts (maintenance windows)

---

## 🏗️ Alerting Arhitektuur

```
┌────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster                            │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │  Prometheus (monitoring namespace)                   │ │
│  │                                                      │ │
│  │  1. Load PrometheusRules                            │ │
│  │  2. Evaluate rules every 30s                        │ │
│  │  3. Check if conditions are true                    │ │
│  │  4. Send alert to AlertManager                      │ │
│  └────────────────────┬─────────────────────────────────┘ │
│                       │ alerts                            │
│                       ▼                                   │
│  ┌──────────────────────────────────────────────────────┐ │
│  │  AlertManager (monitoring namespace)                 │ │
│  │                                                      │ │
│  │  1. Receive alerts from Prometheus                  │ │
│  │  2. Group alerts (same issue)                       │ │
│  │  3. Throttle (avoid spam)                           │ │
│  │  4. Route to receivers (Slack, Email, etc)          │ │
│  └────────────────────┬─────────────────────────────────┘ │
└────────────────────────┼──────────────────────────────────┘
                        │ notifications
                        ▼
                  ┌──────────────┐
                  │   Slack      │
                  │   Channel    │
                  └──────────────┘
```

---

## 📝 Sammud

### Samm 1: Loo Esimesed Alert Rules

Loome PrometheusRule CRD alert rules'iga.

**Loo fail `alert-rules.yaml`:**

```bash
vim alert-rules.yaml
```

**Fail sisu:**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: user-service-alerts
  namespace: monitoring
  labels:
    prometheus: kube-prometheus  # Selector for Prometheus
spec:
  groups:
    # Group 1: User Service Alerts
    - name: user-service
      interval: 30s  # Kui tihti evaluate rules
      rules:
        # Alert 1: High Error Rate
        - alert: HighErrorRate
          expr: |
            (
              sum by (environment) (rate(http_requests_total{status=~"5.."}[5m]))
              /
              sum by (environment) (rate(http_requests_total[5m]))
            ) > 0.05
          for: 5m  # Alert fires kui tingimus on true 5 minutit
          labels:
            severity: critical
            component: user-service
          annotations:
            summary: "High error rate in {{ $labels.environment }}"
            description: "Error rate is {{ $value | humanizePercentage }} in {{ $labels.environment }} (threshold: 5%)"

        # Alert 2: High Request Latency
        - alert: HighRequestLatency
          expr: |
            histogram_quantile(0.95,
              sum by (environment, le) (rate(http_request_duration_seconds_bucket[5m]))
            ) > 1
          for: 10m
          labels:
            severity: warning
            component: user-service
          annotations:
            summary: "High request latency in {{ $labels.environment }}"
            description: "P95 latency is {{ $value }}s in {{ $labels.environment }} (threshold: 1s)"

        # Alert 3: Service Down
        - alert: ServiceDown
          expr: |
            up{job=~".*user-service.*"} == 0
          for: 1m
          labels:
            severity: critical
            component: user-service
          annotations:
            summary: "User service is down in {{ $labels.namespace }}"
            description: "User service has been down for 1 minute in {{ $labels.namespace }}"

    # Group 2: Kubernetes Cluster Alerts
    - name: kubernetes-cluster
      interval: 30s
      rules:
        # Alert 4: High CPU Usage
        - alert: HighCPUUsage
          expr: |
            sum by (node) (rate(node_cpu_seconds_total{mode!="idle"}[5m])) > 0.8
          for: 10m
          labels:
            severity: warning
            component: cluster
          annotations:
            summary: "High CPU usage on {{ $labels.node }}"
            description: "CPU usage is {{ $value | humanizePercentage }} on {{ $labels.node }} (threshold: 80%)"

        # Alert 5: High Memory Usage
        - alert: HighMemoryUsage
          expr: |
            (
              node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
            ) / node_memory_MemTotal_bytes > 0.9
          for: 10m
          labels:
            severity: critical
            component: cluster
          annotations:
            summary: "High memory usage on {{ $labels.node }}"
            description: "Memory usage is {{ $value | humanizePercentage }} on {{ $labels.node }} (threshold: 90%)"

        # Alert 6: Pod Crash Looping
        - alert: PodCrashLooping
          expr: |
            rate(kube_pod_container_status_restarts_total[15m]) > 0
          for: 5m
          labels:
            severity: warning
            component: kubernetes
          annotations:
            summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
            description: "Pod has restarted {{ $value }} times in the last 15 minutes"

        # Alert 7: Deployment Replicas Mismatch
        - alert: DeploymentReplicasMismatch
          expr: |
            kube_deployment_spec_replicas != kube_deployment_status_replicas_available
          for: 15m
          labels:
            severity: warning
            component: kubernetes
          annotations:
            summary: "Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has mismatched replicas"
            description: "Desired: {{ $value }}, Available: check deployment status"
```

**Apply:**

```bash
kubectl apply -f alert-rules.yaml
```

**Kontrolli:**

```bash
kubectl get prometheusrules -n monitoring
```

**Oodatav väljund:**
```
NAME                  AGE
user-service-alerts   10s
```

---

### Samm 2: Kontrolli Alerts Prometheus UI's

**Prometheus UI:**

1. Port-forward (kui ei ole juba running):
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
   ```

2. Ava brauseris: `http://localhost:9090`

3. Kliki **Alerts**

**Peaks nägema:**
- HighErrorRate (State: Inactive või Firing)
- HighRequestLatency (State: Inactive)
- ServiceDown (State: Inactive)
- HighCPUUsage (State: Inactive või Pending/Firing)
- HighMemoryUsage (State: Inactive)
- PodCrashLooping (State: Inactive)
- DeploymentReplicasMismatch (State: Inactive)

**Alert states:**
- **Inactive** (green) - Tingimus ei ole true
- **Pending** (yellow) - Tingimus on true, aga ei ole veel `for` duration'i täis
- **Firing** (red) - Tingimus on true ja `for` duration möödas, alert on saadetud AlertManager'ile

---

### Samm 3: Seadista Slack Webhook (Optional)

Slack notifications'ide jaoks vajame Slack webhook URL'i.

**Slack setup:**

1. Mine: https://api.slack.com/messaging/webhooks
2. Kliki **Create your Slack app**
3. Vali **From scratch**
4. **App Name:** `Prometheus Alerts`
5. **Workspace:** Vali oma workspace
6. **Incoming Webhooks** → Activate
7. **Add New Webhook to Workspace**
8. Vali channel (nt. `#alerts` või `#monitoring`)
9. **Copy Webhook URL:** `https://hooks.slack.com/services/T.../B.../...`

**Test webhook:**

```bash
curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "🚨 Test alert from Prometheus Lab 6"
  }'
```

Slack channel'is peaks ilmuma test message.

---

### Samm 4: Konfigureeri AlertManager Slack Integration

Loome AlertManager configuration Secret'i.

**Loo fail `alertmanager-config.yaml`:**

```bash
vim alertmanager-config.yaml
```

**Fail sisu:**

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

    route:
      # Default receiver
      receiver: 'slack-notifications'

      # Grouping
      group_by: ['alertname', 'environment', 'severity']
      group_wait: 10s        # Oota 10s enne esimest notification'i
      group_interval: 10s    # Oota 10s enne järgmist notification'i samast group'ist
      repeat_interval: 12h   # Repeat notification kui alert on ikka firing

      # Routes (specific alert routing)
      routes:
        # Critical alerts -> immediate
        - match:
            severity: critical
          receiver: 'slack-critical'
          continue: true  # Saada ka default receiver'ile

        # Warning alerts -> throttled
        - match:
            severity: warning
          receiver: 'slack-warnings'

    receivers:
      # Default receiver
      - name: 'slack-notifications'
        slack_configs:
          - api_url: 'YOUR_SLACK_WEBHOOK_URL_HERE'
            channel: '#alerts'
            title: 'Prometheus Alert'
            text: |
              {{ range .Alerts }}
              *Alert:* {{ .Annotations.summary }}
              *Description:* {{ .Annotations.description }}
              *Severity:* {{ .Labels.severity }}
              *Environment:* {{ .Labels.environment }}
              {{ end }}

      # Critical alerts (separate channel or same)
      - name: 'slack-critical'
        slack_configs:
          - api_url: 'YOUR_SLACK_WEBHOOK_URL_HERE'
            channel: '#alerts-critical'
            title: '🚨 CRITICAL ALERT'
            text: |
              {{ range .Alerts }}
              *Alert:* {{ .Annotations.summary }}
              *Description:* {{ .Annotations.description }}
              *Environment:* {{ .Labels.environment }}
              {{ end }}

      # Warning alerts
      - name: 'slack-warnings'
        slack_configs:
          - api_url: 'YOUR_SLACK_WEBHOOK_URL_HERE'
            channel: '#alerts'
            title: '⚠️ Warning Alert'
            text: |
              {{ range .Alerts }}
              *Alert:* {{ .Annotations.summary }}
              *Description:* {{ .Annotations.description }}
              *Environment:* {{ .Labels.environment }}
              {{ end }}
```

**Asenda `YOUR_SLACK_WEBHOOK_URL_HERE` oma webhook URL'iga!**

**Apply:**

```bash
kubectl apply -f alertmanager-config.yaml
```

**Restart AlertManager (config reload):**

```bash
kubectl delete pod -n monitoring -l app.kubernetes.io/name=alertmanager
```

AlertManager pod restartib automaatselt ja laadib uue config'i.

---

### Samm 5: Kontrolli AlertManager UI

**Port-forward AlertManager:**

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```

**Ava brauseris:** `http://localhost:9093`

**AlertManager UI:**
- **Alerts** - Active alerts
- **Silences** - Silence alerts (maintenance windows)
- **Status** - Configuration ja cluster info

---

### Samm 6: Trigger Test Alert

Testime HighErrorRate alert'i.

**Variant 1: Modify alert threshold (temporary test)**

Muuda `alert-rules.yaml` HighErrorRate threshold:

```yaml
# Muuda
) > 0.05  # 5%

# →
) > 0.0001  # 0.01% (liiga madal, trigger alert)
```

Apply ja oota 5 minutit:

```bash
kubectl apply -f alert-rules.yaml
```

**Prometheus UI → Alerts:**
- HighErrorRate peaks minema Pending → Firing

**AlertManager UI:**
- Alert peaks ilmuma alerts list'is

**Slack:**
- Notification peaks tulema channel'is

---

**Variant 2: Generate real errors (realistic test)**

Deploy broken version:

```bash
# Port-forward user-service
kubectl port-forward -n development deployment/user-service 3000:3000

# Generate 500 errors (simulate broken endpoint)
for i in {1..100}; do
  curl -s http://localhost:3000/api/broken-endpoint > /dev/null
  sleep 0.1
done
```

Error rate peaks tõusma ja alert firing 5 minuti pärast.

---

### Samm 7: Resolve Alert

**Kui kasutasid Variant 1:**

```yaml
# Taasta originaal threshold
) > 0.05  # 5%
```

```bash
kubectl apply -f alert-rules.yaml
```

**Prometheus UI:**
- Alert peaks minema Resolved state'i

**Slack:**
- Resolved notification peaks tulema (kui configured)

---

### Samm 8: Silence Alert (Maintenance Window)

Maintenance ajal ei taha alerts.

**AlertManager UI:**

1. Ava `http://localhost:9093`
2. Kliki **Silences**
3. Kliki **New Silence**

**Silence settings:**

- **Matchers:**
  - `environment` = `development`
- **Duration:** 1h
- **Creator:** Your Name
- **Comment:** "Maintenance window - testing deployment"

Kliki **Create**

**Nüüd kõik development environment alerts on silenced 1 tund.**

**CLI kaudu (amtool):**

```bash
# Install amtool
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar -xvf alertmanager-0.27.0.linux-amd64.tar.gz
sudo mv alertmanager-0.27.0.linux-amd64/amtool /usr/local/bin/

# Create silence
amtool --alertmanager.url=http://localhost:9093 silence add \
  environment=development \
  --duration=1h \
  --comment="Maintenance window"
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] PrometheusRule CRD loodud alert rules'iga
- [ ] Alerts visible Prometheus UI's (`http://localhost:9090/alerts`)
- [ ] AlertManager UI accessible (`http://localhost:9093`)
- [ ] Slack webhook configured (või Email/PagerDuty)
- [ ] AlertManager config updated ja reloaded
- [ ] Test alert triggered (manually või realistic)
- [ ] Slack notification received
- [ ] Alert resolved
- [ ] Silence created ja tested

### Verifitseerimine

```bash
# 1. Kontrolli PrometheusRules
kubectl get prometheusrules -n monitoring

# 2. Kontrolli AlertManager config
kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

# 3. Test Prometheus alerts API
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[] | {alert: .labels.alertname, state: .state}'

# 4. Test AlertManager API
curl -s http://localhost:9093/api/v2/alerts | jq '.[] | {alert: .labels.alertname, status: .status.state}'
```

---

## 🔍 Troubleshooting

### Probleem: Alerts ei laadi Prometheus'e

**Lahendus:**

```bash
# Kontrolli PrometheusRule labels
kubectl get prometheusrules -n monitoring user-service-alerts -o yaml

# Prometheus peab matchima PrometheusRule selector'iga
# Vajalik label: prometheus: kube-prometheus

# Kontrolli Prometheus config
kubectl get prometheus -n monitoring prometheus-kube-prometheus-prometheus -o yaml | grep -A5 ruleSelector
```

---

### Probleem: AlertManager ei saada Slack notifications

**Lahendus:**

1. **Test webhook manually:**
   ```bash
   curl -X POST YOUR_WEBHOOK_URL -d '{"text":"test"}'
   ```

2. **Kontrolli AlertManager logs:**
   ```bash
   kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0 -c alertmanager
   ```

3. **Verify config:**
   ```bash
   # Check config syntax
   kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d | yq eval
   ```

---

### Probleem: Alert ei fire (stays Inactive)

**Põhjused:**
1. PromQL query ei tagasta true
2. `for` duration ei ole möödas (alert on Pending)
3. Metrics puuduvad

**Lahendus:**

```bash
# Test PromQL query Prometheus UI's
# Näide: http://localhost:9090/graph
# Query: (sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))) > 0.05

# Kui tagastab tulemusi, alert peaks firing
# Kui ei tagasta, tingimus ei ole true
```

---

## 📚 Mida Sa Õppisid?

✅ **PrometheusRule CRD**
  - Alert rule syntax
  - Expr (PromQL expressions)
  - For duration
  - Labels ja annotations

✅ **Alert severity levels**
  - Critical (immediate action)
  - Warning (investigate)
  - Info (awareness)

✅ **AlertManager**
  - Alert routing
  - Grouping ja throttling
  - Receivers (Slack, Email, etc)
  - Silences

✅ **Alert best practices**
  - Clear annotations (summary, description)
  - Appropriate thresholds
  - Actionable alerts (avoid noise)

---

## 🚀 Järgmised Sammud

**Exercise 5: Log Aggregation with Loki** - Kogume logs ja correlateme metrics'iga:
- Loki installation
- Promtail DaemonSet
- LogQL queries
- Logs + metrics correlation Grafana's

```bash
cat exercises/05-log-aggregation.md
```

---

## 💡 Alert Best Practices

✅ **Actionable alerts:** Iga alert peab olema actionable (mida teha?)
✅ **Clear annotations:** Summary ja description peaksid olema arusaadavad
✅ **Appropriate thresholds:** Ei liiga madal (noise) ega liiga kõrge (missed issues)
✅ **Severity levels:** Kasuta critical, warning, info õigesti
✅ **Grouping:** Groupi related alerts (avoid alert storm)
✅ **Routing:** Critical alerts eraldi channel'i
✅ **Silence management:** Maintenance windows silence'd
✅ **Runbooks:** Link to runbook annotations'is (kuidas probleemi lahendada)

**Alert annotation example with runbook:**

```yaml
annotations:
  summary: "High error rate in {{ $labels.environment }}"
  description: "Error rate is {{ $value }}%"
  runbook_url: "https://wiki.company.com/runbooks/high-error-rate"
```

---

**Õnnitleme! Alerting on configured! 🚨🔔**

**Kestus:** 60 minutit
**Järgmine:** Exercise 5 - Log Aggregation
