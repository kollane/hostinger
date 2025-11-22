# Lab 6 Solutions - Reference Files

See kaust sisaldab reference lahendusi Lab 6 harjutuste jaoks.

## 📂 Struktuuri Ülevaade

```
solutions/
├── prometheus/
│   ├── values.yaml              # Prometheus Helm values (Exercise 1)
│   └── servicemonitor.yaml      # ServiceMonitor for user-service (Exercise 2)
├── grafana/
│   ├── datasource-loki.yaml     # Loki data source config
│   └── README.md                # Dashboard JSON note
├── alertmanager/
│   ├── alert-rules.yaml         # PrometheusRule CRD (Exercise 4)
│   └── alertmanager-config.yaml # AlertManager Secret (Exercise 4)
└── loki/
    ├── values.yaml              # Loki stack Helm values (Exercise 5)
    └── promql-examples.md       # LogQL query examples
```

## 🔧 Kasutamine

### Prometheus Install (Exercise 1)

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus/values.yaml \
  --wait
```

### ServiceMonitor Apply (Exercise 2)

```bash
kubectl apply -f prometheus/servicemonitor.yaml
```

### Alert Rules Apply (Exercise 4)

```bash
kubectl apply -f alertmanager/alert-rules.yaml
kubectl apply -f alertmanager/alertmanager-config.yaml
```

### Loki Install (Exercise 5)

```bash
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values loki/values.yaml \
  --wait
```

---

## 📊 Grafana Dashboards

Dashboards on loodud Grafana UI's (Exercise 3) ja eksporditavad JSON'ina.

**Export dashboard:**
1. Ava dashboard Grafana UI's
2. Dashboard settings (⚙️) → JSON Model
3. Copy to clipboard
4. Salvesta `.json` failina

**Import dashboard:**
1. Create (+) → Import
2. Upload JSON file või paste JSON
3. Load → Import

---

## ⚠️ Märkused

**Passwords ja secrets:**
- Reference failid sisaldavad placeholder values
- Production'is kasuta tugevaid passwords
- Hoia Slack webhooks ja API tokens turvaliselt

**Resource limits:**
- Values failides on seatud lab-friendly resource limits
- Production'is suurenda resource requests/limits
- Monitor actual usage ja adjust accordingly

**Persistent storage:**
- Lab setup kasutab `persistence: false`
- Production'is enable persistent volumes
- Backup strategies critical data jaoks

---

## 💡 Troubleshooting

Kui reference failid ei tööta:

1. **Kontrolli Helm chart versions:**
   ```bash
   helm search repo prometheus-community/kube-prometheus-stack
   helm search repo grafana/loki-stack
   ```

2. **Kontrolli CRD'sid:**
   ```bash
   kubectl get crd | grep monitoring.coreos.com
   ```

3. **Vaata pod logs:**
   ```bash
   kubectl logs -n monitoring <pod-name>
   ```

---

**Edu laboriga! 🚀**
