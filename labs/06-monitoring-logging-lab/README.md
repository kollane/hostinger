# Labor 6: Monitoring ja Logging

**Kestus:** 4 tundi
**Eeldused:** Labor 1-5 läbitud, Peatükk 24 (Monitoring)
**Eesmärk:** Seadistada monitoring ja logging production süsteemile

---

## 📋 Ülevaade

Selles laboris seadistad Prometheus ja Grafana monitoring'u ning EFK (Elasticsearch-Fluentd-Kibana) logging stack'i.

---

## 🎯 Õpieesmärgid

✅ Paigaldada Prometheus ja Grafana
✅ Luua Grafana dashboards
✅ Seadistada log aggregation
✅ Konfigureerida alerting
✅ Troubleshoot production issues

---

## 📂 Labori Struktuur

```
06-monitoring-logging-lab/
├── README.md
├── exercises/
│   ├── 01-prometheus-setup.md
│   ├── 02-grafana-dashboards.md
│   ├── 03-log-aggregation.md
│   ├── 04-alerting.md
│   └── 05-troubleshooting.md
├── configs/
│   ├── prometheus.yml
│   ├── grafana-dashboard.json
│   └── fluentd.conf
└── solutions/
```

---

**Staatus:** 📝 Framework valmis, sisu lisatakse
**Viimane uuendus:** 2025-11-15
