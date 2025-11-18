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

## 🔧 Eeldused

### Eelnevad labid:
- [x] **Labor 1: Docker Põhitõed** - KOHUSTUSLIK
  - Docker containerite mõistmine (metrics collection jaoks)
  - Docker image build oskus

- [ ] **Labor 2: Docker Compose** - SOOVITUSLIK
  - Multi-container kogemus aitab, kuid pole kohustuslik

- [x] **Labor 3: Kubernetes Alused** - KOHUSTUSLIK
  - Vaja on töötavat Kubernetes cluster'it
  - Deployitud rakendusi, mida monitoorida (User Service, Frontend)
  - Deployments ja Services loodud
  - Pod'ide ja node'ide mõistmine

- [ ] **Labor 4: Kubernetes Täiustatud** - SOOVITUSLIK
  - HPA monitoring aitab mõista autoscaling metrics'e
  - Ingress monitoring võimalused

- [ ] **Labor 5: CI/CD** - SOOVITUSLIK
  - Deployment tracking metrics'e mõistmine
  - Pipeline'i monitoorimine

### Tööriistad:
- [x] Kubernetes cluster töötab (Lab 3'st)
- [x] kubectl configured (`kubectl cluster-info`)
- [x] Helm paigaldatud (`helm version` - Prometheus/Grafana paigalduseks)
- [x] Vähemalt 2GB vaba RAM (Prometheus + Grafana + rakendused)
- [x] Internet ühendus (Helm charts allalaadimiseks)

### Valmis komponendid:
- [x] Töötavad rakendused K8s'is (User Service, Frontend - Lab 3'st)
- [x] Deployments ja Services loodud (Lab 3'st)
- [ ] Ingress seadistatud (Lab 4 - optional, aitab Ingress metrics jaoks)

### Teadmised:
- [x] **Labor 3:** Kubernetes põhikontseptsioonid (Pods, Services)
- [x] **Peatükk 24:** Monitoring ja logging põhimõtted
- [x] Metrics ja logs mõisted
- [x] PromQL query language alused (õpitakse laboris)
- [x] YAML süntaks

---

## 📚 Progressiivne Õppetee

```
Labor 1 (Docker)
  ↓ Docker image'd →
Labor 2 (Compose)
  ↓ Multi-container kogemus →
Labor 3 (K8s Basics)
  ↓ K8s manifests + deployed apps →
Labor 4 (K8s Advanced)
  ↓ Ingress + Helm →
Labor 5 (CI/CD)
  ↓ Automated deployments →
Labor 6 (Monitoring) ← Oled siin
```

---

## ⚡ Kiirstart Setup

### Variant A: Automaatne Seadistus (Soovitatud)

Käivita setup script, mis seadistab monitoring keskkonna:

```bash
# Käivita setup script
chmod +x setup.sh
./setup.sh
```

**Script teeb:**
- ✅ Kontrollib Kubernetes cluster'i
- ✅ Kontrollib Lab 3 rakenduste olemasolu
- ✅ Deploy'b Lab 3 komponendid kui puuduvad
- ✅ Kontrollib Helm'i (Lab 4'st)
- ✅ Valmistab ette Prometheus/Grafana paigalduse

---

### Variant B: Manuaalne Seadistus

#### 1. Kontrolli Kubernetes Cluster'i

```bash
# Cluster töötab?
kubectl cluster-info
kubectl get nodes

# Rakendused töötavad?
kubectl get deployments
kubectl get services
```

#### 2. Kontrolli Helm'i

```bash
# Helm versioon
helm version

# Kui puudub, paigalda
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### 3. Kontrolli Vaba RAM-i

Prometheus + Grafana vajab vähemalt 2GB RAM-i:

```bash
free -h
```

#### 4. Alusta Harjutus 1'st

```bash
cat exercises/01-prometheus-setup.md
```

---

### ⚡ Kiirkontroll: Kas Oled Valmis?

```bash
# Kiirkontroll
kubectl cluster-info && \
kubectl get deployments && \
helm version && \
echo "✅ Kõik eeldused on täidetud!"
```

---

**Staatus:** 📝 Framework valmis, sisu lisatakse
**Viimane uuendus:** 2025-11-15
