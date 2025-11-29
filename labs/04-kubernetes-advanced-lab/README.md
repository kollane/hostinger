# Labor 4: Kubernetes Täiustatud Funktsioonid

**Kestus:** 5 tundi
**Eeldused:** Labor 3 läbitud (Kubernetes Basics), Peatükk 17-19
**Eesmärk:** Viia Kubernetes rakendus production-ready tasemele

---

## 📋 Ülevaade

Selles laboris **täiendad Lab 3 põhilahendust production-ready funktsioonidega**:
- Ingress routing (ilma NodePort'ita)
- Automaatne skaleerimine (HPA)
- Zero-downtime updates
- Resource management
- Helm package manager

**Labor 3 vs Labor 4:**
- **Labor 3:** Põhitõed - Pods, Deployments, Services, ConfigMaps
- **Labor 4:** Production - Ingress, Autoscaling, Rolling Updates, Helm

Lab 4 lõpus on sul production-ready Kubernetes süsteem, mille saad Lab 5's automatiseerida CI/CD pipeline'iga.

---

## 🏗️ Arhitektuur

### Lab 3 Lõpuseisu (Stardipunkt)

**5 teenust Kubernetes'es (NodePort access):**

```
┌─────────────────────────────────────────────────────────────┐
│                 Kubernetes Cluster (Lab 3)                  │
│                                                             │
│  Frontend (NodePort :30080) ← Browser: http://VPS:30080    │
│       │                                                     │
│       ├──> User Service (ClusterIP :3000)                   │
│       │         │                                           │
│       │         └──> PostgreSQL-User (StatefulSet)          │
│       │                   └─ PVC: postgres-user-data        │
│       │                                                     │
│       └──> Todo Service (ClusterIP :8081)                   │
│                 │                                           │
│                 └──> PostgreSQL-Todo (StatefulSet)          │
│                           └─ PVC: postgres-todo-data        │
│                                                             │
│  ❌ Probleemid:                                             │
│  - NodePort access (port 30080) - ei sobi production'is    │
│  - Fikseeritud replicas - ei skaleeru automaatselt          │
│  - Käsitsi update'id - downtime oht                         │
│  - Ressursside piirangud puuduvad - resource exhaustion    │
│  - kubectl apply manifest'id - raske hallata                │
└─────────────────────────────────────────────────────────────┘
```

### Lab 4 Sihtolek (Production-Ready)

**Ingress + Autoscaling + Helm:**

```
                  Browser: http://kirjakast.cloud
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (Lab 4)                     │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Ingress Controller (nginx)                        │    │
│  │  - Path-based routing: /, /api/users, /api/todos  │    │
│  │  - Load balancing                                  │    │
│  └──────┬───────────────┬──────────────┬──────────────┘    │
│         │               │              │                   │
│         ▼               ▼              ▼                   │
│    Frontend      User Service    Todo Service             │
│   (replicas: 2)  (replicas: 2-10) (replicas: 2-5)         │
│                  HPA enabled      HPA enabled              │
│                                                             │
│  ✅ Lahendused:                                             │
│  - Ingress routing - port 80/443 (standard HTTP/HTTPS)     │
│  - HPA autoscaling - CPU/memory põhine                      │
│  - Rolling updates - zero-downtime                          │
│  - Resource limits - CPU/memory requests & limits           │
│  - Helm charts - template-based deployment                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

- ✅ Paigaldada Ingress Controller (ingress-nginx)
- ✅ Konfigureerida Ingress ressursse path-based routing'uks
- ✅ Seadistada Horizontal Pod Autoscaler (HPA)
- ✅ Implementeerida rolling updates zero-downtime'iga
- ✅ Defineerida resource requests & limits
- ✅ Kasutada Helm 3 chart'e rakenduste paketeerimiseks
- ✅ Valmistada süsteemi ette CI/CD automatiseerimiseks (Lab 5)

---

## 📂 Labori Struktuur

```
04-kubernetes-advanced-lab/
├── README.md                          # Sinu asud siin
├── exercises/
│   ├── 01-ingress-controller.md      # Ingress routing (60 min)
│   ├── 02-horizontal-pod-autoscaler.md # HPA (45 min)
│   ├── 03-rolling-updates.md         # Zero-downtime updates (45 min)
│   ├── 04-resource-limits.md         # CPU/Memory management (45 min)
│   └── 05-helm-basics.md             # Helm packaging (60 min)
├── solutions/
│   ├── manifests/
│   │   ├── ingress-nginx.yaml        # Ingress Controller install
│   │   ├── app-ingress.yaml          # Application Ingress rules
│   │   ├── hpa-user-service.yaml     # HPA config
│   │   ├── deployment-rolling.yaml   # Rolling update config
│   │   └── resource-quota.yaml       # Namespace quotas
│   └── helm/
│       ├── user-service/             # Helm chart example
│       │   ├── Chart.yaml
│       │   ├── values.yaml
│       │   └── templates/
│       └── todo-app/                 # Full stack Helm chart
└── setup.sh                          # Quick setup script
```

---

## 🔧 Eeldused

### Eelnevad labid:
- [x] **Labor 1: Docker Põhitõed** - KOHUSTUSLIK
- [ ] **Labor 2: Docker Compose** - SOOVITUSLIK
- [x] **Labor 3: Kubernetes Põhitõed** - KOHUSTUSLIK (peab olema läbitud!)

### Labor 3 lõpuseisu kontroll:

```bash
# 1. Kubernetes cluster töötab
kubectl cluster-info

# 2. Labor 3 teenused deployed
kubectl get deployments
# Oodatud: frontend, user-service, todo-service
kubectl get statefulsets
# Oodatud: postgres-user, postgres-todo

# 3. Teenused accessible
kubectl get services
# Frontend: NodePort (30080)
# user-service, todo-service: ClusterIP

# 4. Vähemalt 4GB vaba RAM
free -h
```

**Kui midagi puudub:**
- 🔗 Mine tagasi [Labor 3](../03-kubernetes-basics-lab/README.md)

### Tööriistad:
- [x] kubectl configured (`kubectl version --client`)
- [ ] Helm 3.x paigaldatud (`helm version`)
- [ ] Vähemalt 4GB vaba RAM (Ingress Controller + HPA)
- [x] Internet ühendus (image'id, Helm charts)

### Helm 3 paigaldamine:

```bash
# Ubuntu/Debian
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Kontrolli
helm version
# version.BuildInfo{Version:"v3.x.x", ...}
```

---

## 📚 Progressiivne Õppetee

```
Labor 1 (Docker)
  ↓ Docker images →
Labor 2 (Compose)
  ↓ Multi-container →
Labor 3 (K8s Basics)
  ↓ Pods, Deployments, Services →
Labor 4 (K8s Advanced) ← OLED SIIN
  ↓ Ingress, HPA, Helm →
Labor 5 (CI/CD)
  ↓ Automated deployment →
Labor 6 (Monitoring)
```

---

## 🚀 Harjutuste Ülevaade

### Harjutus 1: Ingress Controller & Routing (60 min)

**Eesmärk:** Asenda NodePort Ingress routing'uga

**Õpid:**
- Ingress-nginx paigaldamine
- Path-based routing (`/`, `/api/users`, `/api/todos`)
- Service access standardsete portide kaudu (80/443)

**Tulemus:**
```
Enne: http://VPS:30080
Pärast: http://kirjakast.cloud
```

### Harjutus 2: Horizontal Pod Autoscaler (45 min)

**Eesmärk:** Automaatne skaleerimine koormus põhiselt

**Õpid:**
- Metrics Server paigaldamine
- CPU-based autoscaling
- Load testing (HPA trigger)

**Tulemus:**
```
CPU < 50%: 2 pods
CPU > 50%: up to 10 pods (automaatselt)
```

### Harjutus 3: Rolling Updates & Health Checks (45 min)

**Eesmärk:** Zero-downtime deployments

**Õpid:**
- Rolling update strateegia
- Liveness & Readiness probes
- Rollback mehhanismid

**Tulemus:**
```
kubectl set image deployment/user-service user-service=user-service:1.1
→ Zero-downtime update
```

### Harjutus 4: Resource Limits & Quotas (45 min)

**Eesmärk:** Resource exhaustion vältimine

**Õpid:**
- CPU/Memory requests & limits
- ResourceQuota namespace'le
- LimitRange defaults

**Tulemus:**
```
Pod saab garanteeritud ressursid (requests)
Pod ei saa üle tarbida (limits)
```

### Harjutus 5: Helm Package Manager (60 min)

**Eesmärk:** Template-based deployment (ettevalmistus Lab 5 CI/CD'ks)

**Õpid:**
- Helm 3 basics
- Chart loomine (user-service)
- Values.yaml templating
- Release management

**Tulemus:**
```
kubectl apply -f ... (40 rida YAML)
→ helm install user-service ./user-service (1 käsk)
```

---

## 🎓 Mida Õpid Selles Laboris?

### Production-Ready Kubernetes:

1. **Ingress vs NodePort:**
   - NodePort: Development OK, production mitte
   - Ingress: Standard HTTP/HTTPS, TLS, path routing

2. **Automaatne Skaleerimine:**
   - HPA (Horizontal Pod Autoscaler)
   - CPU/Memory metrics
   - Custom metrics (optional)

3. **Zero-Downtime Deployments:**
   - Rolling updates
   - Health checks (liveness/readiness)
   - Rollback strategies

4. **Resource Management:**
   - Requests (garanteeritud)
   - Limits (max)
   - Quotas (namespace level)

5. **Helm Package Manager:**
   - Template-based configs
   - Version control
   - Easy rollbacks
   - **Ettevalmistus CI/CD'ks (Lab 5)**

---

## 🔗 Järgmised Sammud

**Peale selle labori läbimist:**
- ✅ Sul on production-ready Kubernetes süsteem
- ✅ Automaatne skaleerimine töötab
- ✅ Zero-downtime updates implementeeritud
- ✅ Helm charts loodud

**Labor 5 (CI/CD) jätkab sellest:**
- GitHub Actions pipeline'id
- Automated build → test → deploy
- Helm deploy automation
- Multi-environment (dev/staging/prod)

---

## 📝 Kiirstart

```bash
# 1. Kontrolli Labor 3 on valmis
kubectl get all

# 2. Alusta Harjutus 1'ga
cd exercises
cat 01-ingress-controller.md

# 3. Järgi harjutusi järjekorras
# Iga harjutus ehitab eelmisele
```

---

## 🐛 Troubleshooting

### Probleem: "Helm not found"

```bash
# Paigalda Helm 3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### Probleem: "Insufficient CPU/memory"

```bash
# Kontrolli vaba ressurssi
kubectl top nodes
free -h

# Suurenda VM ressursse või
# Vähenda replica count'i
```

### Probleem: "Ingress Controller ei tööta"

```bash
# Kontrolli pods
kubectl get pods -n ingress-nginx

# Vaata logisid
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

---

## 📚 Viited

- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Helm Documentation](https://helm.sh/docs/)

---

**Alusta Labor 4'ga ja vii oma Kubernetes süsteem production-ready tasemele! 🚀**
