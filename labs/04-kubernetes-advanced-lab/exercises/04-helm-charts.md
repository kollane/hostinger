# Harjutus 4: Helm Charts

**Kestus:** 60 minutit
**Eesmärk:** Õppida Helm Charts'ide loomist ja rakenduste paketeerimist

---

## 📋 Ülevaade

Selles harjutuses õpid kasutama **Helm** - Kubernetes'e package manager'it. Helm võimaldab paketeerida, versioneerida ja jagada Kubernetes rakendusi Chart'idena.

**Helm Chart** = template'id + väärtused = deploy'tav pakett

**Miks Helm?**
- ✅ Template engine (üks Chart, mitu environment'i)
- ✅ Versiooneerimine (rollback, upgrade)
- ✅ Dependency management
- ✅ Reusable packages

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Paigaldada Helm'i
- ✅ Luua Helm Chart struktuuri
- ✅ Kirjutada Helm template'id (Go templates)
- ✅ Kasutada values.yaml faili
- ✅ Install'ida Chart'e
- ✅ Upgrade'ida releases
- ✅ Rollback'ida releases
- ✅ Kasutada Chart repositooriume

---

## 🏗️ Arhitektuur

```
┌────────────────────────────────────────┐
│  Helm Chart: user-service             │
│                                        │
│  ├── Chart.yaml    (metadata)         │
│  ├── values.yaml   (default values)   │
│  ├── templates/    (K8s manifests)    │
│  │   ├── deployment.yaml              │
│  │   ├── service.yaml                 │
│  │   ├── configmap.yaml               │
│  │   └── _helpers.tpl                 │
│  └── charts/       (dependencies)     │
│                                        │
│         helm install                   │
│              ↓                         │
│  ┌────────────────────────────────┐   │
│  │  Release: user-service-prod    │   │
│  │  Revision: 1                   │   │
│  │  ┌──────────┐ ┌──────────┐    │   │
│  │  │Deployment│ │ Service  │    │   │
│  │  └──────────┘ └──────────┘    │   │
│  └────────────────────────────────┘   │
└────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Paigalda Helm (5 min)

```bash
# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Või apt (Ubuntu)
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install helm

# Kontrolli versiooni
helm version

# Peaks näitama:
# version.BuildInfo{Version:"v3.xx.x", ...}
```

---

### Samm 2: Loo Helm Chart Struktuur (10 min)

```bash
# Loo uus Chart
helm create user-service

# Vaata struktuuri
tree user-service

# user-service/
# ├── Chart.yaml        # Chart metadata
# ├── values.yaml       # Default väärtused
# ├── charts/           # Chart dependencies
# ├── templates/        # Kubernetes manifest template'id
# │   ├── deployment.yaml
# │   ├── service.yaml
# │   ├── ingress.yaml
# │   ├── _helpers.tpl  # Template helper functions
# │   ├── NOTES.txt     # Post-install notes
# │   └── tests/
# │       └── test-connection.yaml
# └── .helmignore       # Ignore patterns

cd user-service
```

**Failide selgitus:**

**Chart.yaml:**
```yaml
apiVersion: v2
name: user-service
description: A Helm chart for User Service
type: application
version: 0.1.0  # Chart version
appVersion: "1.0"  # App version
```

**values.yaml (default väärtused):**
```yaml
replicaCount: 2

image:
  repository: user-service
  pullPolicy: Never
  tag: "1.0"

service:
  type: ClusterIP
  port: 80
```

---

### Samm 3: Muuda Template'id (15 min)

**Muuda `templates/deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "user-service.fullname" . }}
  labels:
    {{- include "user-service.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "user-service.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "user-service.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 3000
          protocol: TCP
        env:
        {{- range .Values.env }}
        - name: {{ .name }}
          value: {{ .value | quote }}
        {{- end }}
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
```

**Template syntax selgitus:**
- `{{ .Values.replicaCount }}` - väärtus values.yaml'ist
- `{{ .Chart.Name }}` - Chart.yaml nimi
- `{{- include "..." . }}` - helper function
- `{{- range ... }}` - loop
- `| nindent 4` - indentation

**Muuda `values.yaml`:**

```yaml
replicaCount: 2

image:
  repository: user-service
  pullPolicy: Never
  tag: "1.0"

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

env:
  - name: PORT
    value: "3000"
  - name: NODE_ENV
    value: "production"
  - name: DB_HOST
    value: "postgres"
  - name: DB_PORT
    value: "5432"
  - name: DB_NAME
    value: "user_service_db"

resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "500m"

ingress:
  enabled: false
```

---

### Samm 4: Testi Template Rendering'u (5 min)

```bash
# Dry-run: vaata, mis YAML tekib
helm template user-service .

# Või ainult Deployment
helm template user-service . -s templates/deployment.yaml

# Lint: kontrolli syntax vigu
helm lint .

# Peaks näitama:
# ==> Linting .
# [INFO] Chart.yaml: icon is recommended
#
# 1 chart(s) linted, 0 chart(s) failed

# Debug: näita ka väärtusi
helm install user-service . --dry-run --debug
```

---

### Samm 5: Install Chart (10 min)

```bash
# Install Chart
helm install user-service-release .

# Peaks näitama:
# NAME: user-service-release
# LAST DEPLOYED: ...
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# NOTES: ...

# Kontrolli release'e
helm list

# NAME                  NAMESPACE  REVISION  UPDATED                                  STATUS    CHART               APP VERSION
# user-service-release  default    1         2025-11-16 18:00:00.000000000 +0000 UTC  deployed  user-service-0.1.0  1.0

# Kontrolli Kubernetes ressursse
kubectl get all -l app.kubernetes.io/instance=user-service-release

# Peaks näitama:
# NAME                                                READY   STATUS    RESTARTS   AGE
# pod/user-service-release-xxxxxxxxxx-xxxxx           1/1     Running   0          1m
# pod/user-service-release-xxxxxxxxxx-yyyyy           1/1     Running   0          1m
#
# NAME                               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# service/user-service-release       ClusterIP   10.96.0.xxx     <none>        80/TCP    1m
#
# NAME                                           READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/user-service-release           2/2     2            2           1m
```

---

### Samm 6: Upgrade Chart (10 min)

**Muuda väärtusi:**

Loo fail `prod-values.yaml`:

```yaml
replicaCount: 3  # 2 → 3

image:
  repository: user-service
  pullPolicy: Never
  tag: "1.1"  # 1.0 → 1.1

env:
  - name: PORT
    value: "3000"
  - name: NODE_ENV
    value: "production"  # prod environment
  - name: LOG_LEVEL
    value: "info"
```

**Upgrade release:**

```bash
# Upgrade release uute väärtustega
helm upgrade user-service-release . -f prod-values.yaml

# Peaks näitama:
# Release "user-service-release" has been upgraded. Happy Helming!
# NAME: user-service-release
# LAST DEPLOYED: ...
# NAMESPACE: default
# STATUS: deployed
# REVISION: 2

# Kontrolli
helm list

# REVISION: 2 (uuendatud!)

kubectl get deployment user-service-release -o wide

# READY: 3/3 (skaleerus 2 → 3)

# Vaata history
helm history user-service-release

# REVISION  UPDATED                   STATUS      CHART               APP VERSION  DESCRIPTION
# 1         ...                       superseded  user-service-0.1.0  1.0          Install complete
# 2         ...                       deployed    user-service-0.1.0  1.1          Upgrade complete
```

---

### Samm 7: Rollback (5 min)

**Kui upgrade läks valesti:**

```bash
# Rollback revision 1-le
helm rollback user-service-release 1

# Peaks näitama:
# Rollback was a success! Happy Helming!

# Kontrolli
helm history user-service-release

# REVISION  UPDATED   STATUS      CHART               APP VERSION  DESCRIPTION
# 1         ...       superseded  user-service-0.1.0  1.0          Install complete
# 2         ...       superseded  user-service-0.1.0  1.1          Upgrade complete
# 3         ...       deployed    user-service-0.1.0  1.0          Rollback to 1

# Märka: revision 3 (rollback loob uue revision'i)

kubectl get deployment user-service-release

# READY: 2/2 (tagasi 3 → 2)
```

---

### Samm 8: Uninstall Chart (3 min)

```bash
# Uninstall release
helm uninstall user-service-release

# Peaks näitama:
# release "user-service-release" uninstalled

# Kontrolli
helm list
# (tühi)

kubectl get all -l app.kubernetes.io/instance=user-service-release
# No resources found
```

---

### Samm 9: Chart Dependencies (7 min)

**Kasuta teiste Chart'e dependency'na:**

Muuda `Chart.yaml`:

```yaml
apiVersion: v2
name: user-service
description: A Helm chart for User Service
type: application
version: 0.1.0
appVersion: "1.0"

dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
```

**Update dependencies:**

```bash
# Download dependencies
helm dependency update

# Peaks näitama:
# Hang tight while we grab the latest from your chart repositories...
# ...Successfully got an update from the "bitnami" chart repository
# Update Complete. ⎈Happy Helming!⎈
# Saving 1 charts
# Downloading postgresql from repo https://charts.bitnami.com/bitnami
# Deleting outdated charts

# Kontrolli
ls charts/
# postgresql-12.x.x.tgz

# Install koos dependency'ga
helm install user-service-release . --set postgresql.enabled=true
```

---

### Samm 10: Helm Repository (5 min)

**Kasuta avalikke Chart repositooriume:**

```bash
# Lisa Bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repo
helm repo update

# Otsi Chart'e
helm search repo postgresql

# NAME                    CHART VERSION  APP VERSION  DESCRIPTION
# bitnami/postgresql      12.x.x         16.x.x       PostgreSQL is an advanced object...

# Install Chart repo'st
helm install my-postgres bitnami/postgresql

# Kontrolli
helm list
kubectl get pods
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **Helm install:**
  - [ ] Helm paigaldatud
  - [ ] `helm version` töötab

- [ ] **Chart loomine:**
  - [ ] `helm create` Chart struktuur
  - [ ] Chart.yaml, values.yaml, templates/

- [ ] **Template'id:**
  - [ ] Go template syntax
  - [ ] `{{ .Values.* }}`
  - [ ] Helper functions

- [ ] **Release lifecycle:**
  - [ ] `helm install`
  - [ ] `helm upgrade`
  - [ ] `helm rollback`
  - [ ] `helm uninstall`

- [ ] **Testing:**
  - [ ] `helm template` (dry-run)
  - [ ] `helm lint`

- [ ] **Repositories:**
  - [ ] `helm repo add`
  - [ ] `helm search repo`

---

## 🐛 Troubleshooting

### Probleem 1: helm install ebaõnnestub - invalid

**Sümptom:**
```bash
helm install user-service-release .
# Error: YAML parse error on user-service/templates/deployment.yaml: error converting YAML to JSON
```

**Lahendus:**

```bash
# Lint Chart
helm lint .

# Testi template rendering
helm template . --debug

# Kontrolli YAML syntax
```

---

### Probleem 2: Values ei rakendu

**Sümptom:**
```bash
helm install user-service-release . --set replicaCount=5
# Aga deployment on ainult 2 replicas
```

**Diagnoos:**

```bash
# Vaata, mis väärtused rakendusid
helm get values user-service-release

# Testi dry-run'iga
helm install user-service-release . --set replicaCount=5 --dry-run --debug
```

---

### Probleem 3: Dependency download ebaõnnestub

**Sümptom:**
```bash
helm dependency update
# Error: could not find Chart.yaml
```

**Lahendus:**

```bash
# Veendu, et oled Chart directory's
cd user-service

# Kontrolli Chart.yaml olemasolu
ls -la Chart.yaml
```

---

## 🎓 Õpitud Mõisted

### Helm:
- **Chart:** Kubernetes rakenduse pakett (templates + values)
- **Release:** Chart'i installitud instance (nt `user-service-prod`)
- **Revision:** Release versioon (upgrade loob uue revision'i)
- **Repository:** Chart'ide kollektsioon (nt Bitnami)

### Chart Structure:
- **Chart.yaml:** Metadata (nimi, versioon, dependencies)
- **values.yaml:** Default konfiguratsioon
- **templates/:** Kubernetes manifest template'id
- **charts/:** Sub-chart'id (dependencies)
- **_helpers.tpl:** Template helper functions

### Template Syntax:
- **{{ .Values.* }}:** väärtused values.yaml'ist
- **{{ .Chart.* }}:** metadata Chart.yaml'ist
- **{{ .Release.* }}:** release info (nimi, namespace)
- **{{- include "..." . }}:** helper function kutsutud
- **| nindent 4:** pipe filter (indentation)

### Helm Commands:
- `helm create` - Loo uus Chart
- `helm install` - Install Chart
- `helm upgrade` - Upgrade release
- `helm rollback` - Rollback revision
- `helm uninstall` - Uninstall release
- `helm list` - Listi releases
- `helm template` - Render template (dry-run)
- `helm lint` - Validate Chart

---

## 💡 Parimad Tavad

1. **Versiooni Chart'e semantically** - 0.1.0, 0.2.0, 1.0.0
2. **Kasuta values.yaml environment-specific väärtustele** - dev-values.yaml, prod-values.yaml
3. **Ära harda-code väärtusi template'ites** - Kasuta {{ .Values.* }}
4. **Dokumenteeri values.yaml** - Lisa kommentaarid
5. **Lisa NOTES.txt** - Post-install juhised kasutajale
6. **Lint enne install'i** - `helm lint .`
7. **Testi dry-run'iga** - `helm install --dry-run --debug`
8. **Kasuta dependencies** - Ära kopeeri Chart'e, kasuta dependency'sid
9. **Versiooni lockfile** - `Chart.lock` Git'i
10. **Package ja jaga** - `helm package .` ja upload repositooriumisse

---

## 🔗 Järgmine Samm

Nüüd oskad paketeerida rakendusi Helm Chart'idega! Aga kuidas skaleerida automaatselt koormusele vastates?

Järgmises harjutuses õpid **Autoscaling ja Rolling Updates**!

**Jätka:** [Harjutus 5: Autoscaling + Rolling Updates](05-autoscaling-rolling.md)

---

## 📚 Viited

- [Helm Documentation](https://helm.sh/docs/)
- [Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Bitnami Charts](https://github.com/bitnami/charts)
- [Artifact Hub](https://artifacthub.io/) - Helm Chart search

---

**Õnnitleme! Oskad nüüd paketeerida rakendusi Helm'iga! 📦**
