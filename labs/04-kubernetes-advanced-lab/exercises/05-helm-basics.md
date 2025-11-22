# Harjutus 5: Helm Package Manager

**Kestus:** 60 minutit
**Eesmärk:** Template-based deployment ja ettevalmistus CI/CD'ks (Lab 5)

---

## 📋 Ülevaade

Selles harjutuses **õpid Helm 3 package manager'it** - template-based Kubernetes deployment'i tööriista. Lood Helm chart'i User Service'le ja õpid, kuidas Helm lihtsustab keeruliste rakenduste haldamist.

**Enne vs Pärast:**
- **Enne:** `kubectl apply -f deployment.yaml service.yaml configmap.yaml ...` (10+ faili)
- **Pärast:** `helm install user-service ./chart` (1 käsk)

---

## 🎯 Õpieesmärgid

- ✅ Mõista Helm chart'i struktuuri
- ✅ Luua Helm chart User Service'le
- ✅ Kasutada values.yaml templating'ut
- ✅ Paigaldada release'e (install/upgrade/rollback)
- ✅ Valmistuda CI/CD automatiseerimiseks (Lab 5)

---

## 🏗️ Arhitektuur

### Kubectl (Traditional)

```
my-app/
├── deployment.yaml
├── service.yaml
├── configmap.yaml
├── secret.yaml
├── ingress.yaml
├── hpa.yaml
└── pvc.yaml

Deploy:
  kubectl apply -f deployment.yaml
  kubectl apply -f service.yaml
  kubectl apply -f configmap.yaml
  ... (10+ käsku)

Probleem:
  - Palju korduvat koodi
  - Raske hallata mitut environment'i (dev/staging/prod)
  - Versioning puudub
  - Rollback keeruline
```

### Helm (Template-based)

```
user-service/
├── Chart.yaml           # Metadata
├── values.yaml          # Konfiguratsioon
└── templates/
    ├── deployment.yaml  # Template (uses {{ .Values }})
    ├── service.yaml
    ├── configmap.yaml
    ├── secret.yaml
    ├── ingress.yaml
    ├── hpa.yaml
    └── NOTES.txt        # Post-install instructions

Deploy:
  helm install user-service ./user-service

Benefits:
  ✅ Üks käsk, kõik ressursid
  ✅ Templating ({{ .Values.replicas }})
  ✅ Multi-environment (values-dev.yaml, values-prod.yaml)
  ✅ Versioning (Chart.yaml version)
  ✅ Rollback (helm rollback)
```

---

## 📝 Sammud

### Samm 1: Paigalda Helm 3 (5 min)

**Kontrolli kas Helm on juba paigaldatud:**

```bash
helm version
# version.BuildInfo{Version:"v3.x.x", ...}
```

**Kui puudub, paigalda:**

```bash
# Ubuntu/Debian
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# macOS
brew install helm

# Verifitseeri
helm version
helm repo list
```

**Lisa official chart repositories (optional):**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

### Samm 2: Mõista Helm Kontseptsioone (5 min)

**3 peamist kontseptsiooni:**

1. **Chart** (Package)
   - Helm package (zip fail)
   - Sisaldab template'e ja metadata
   - Analoogia: npm package, Docker image

2. **Release** (Deployed instance)
   - Deployed chart instance
   - Üks chart võib olla mitu release'i (nt `user-service-dev`, `user-service-prod`)
   - Analoogia: running container

3. **Repository** (Chart storage)
   - Chart'ide salvestuskoht (nagu Docker Hub)
   - Näited: Bitnami, Helm Stable
   - Analoogia: npm registry

**Helm 3 vs Helm 2:**
- ❌ Helm 2: Tiller (server component) - deprecated
- ✅ Helm 3: No Tiller (client-only) - soovitatud

### Samm 3: Loo Helm Chart Struktuur (10 min)

**Loo chart directory:**

```bash
# Navigeeri Lab 4 solutions/ kataloogi
cd /home/user/hostinger/labs/04-kubernetes-advanced-lab/solutions

# Loo Helm chart scaffold
helm create user-service

# Kontrolli struktuuri
tree user-service
```

**Oodatud struktuur:**

```
user-service/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default config values
├── charts/                 # Dependency charts (empty)
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── serviceaccount.yaml
│   ├── _helpers.tpl        # Template helpers
│   ├── NOTES.txt           # Post-install message
│   └── tests/
│       └── test-connection.yaml
└── .helmignore
```

**Cleanup default files (kasutame oma):**

```bash
cd user-service
rm -rf templates/*
touch templates/.gitkeep
```

### Samm 4: Konfigureeri Chart.yaml (5 min)

Loo `Chart.yaml`:

```yaml
apiVersion: v2
name: user-service
description: User Service Helm Chart for Todo App
type: application

# Chart version (semantic versioning)
version: 1.0.0

# Application version (image tag)
appVersion: "1.0"

# Metadata
keywords:
  - nodejs
  - authentication
  - jwt
  - postgresql

maintainers:
  - name: DevOps Team
    email: devops@kirjakast.cloud

# Dependencies (optional)
# dependencies:
#   - name: postgresql
#     version: 12.x.x
#     repository: https://charts.bitnami.com/bitnami
```

### Samm 5: Loo values.yaml (10 min)

Loo `values.yaml` (default väärtused):

```yaml
# ==========================================================================
# Helm Values - User Service
# ==========================================================================
# Default väärtused. Override'i install ajal:
#   helm install user-service . -f values-prod.yaml
#   helm install user-service . --set replicaCount=5
# ==========================================================================

# Replica count
replicaCount: 2

# Image config
image:
  repository: user-service
  tag: "1.0"
  pullPolicy: IfNotPresent

# Service config
service:
  type: ClusterIP
  port: 3000
  targetPort: 3000

# Ingress config
ingress:
  enabled: true
  className: nginx
  host: kirjakast.cloud
  path: /api/users
  pathType: Prefix

# Resources
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

# Autoscaling (HPA)
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 50
  targetMemoryUtilizationPercentage: 70

# Health checks
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5

# Environment variables
env:
  # Database
  DB_HOST: postgres-user
  DB_PORT: "5432"
  DB_NAME: user_service_db
  DB_USER: postgres
  # DB_PASSWORD from secret
  
  # App config
  NODE_ENV: production
  PORT: "3000"

# Secrets (loo eraldi Secret resource)
secrets:
  jwtSecret: "your-jwt-secret-here"
  dbPassword: "postgres"

# NodeSelector (optional)
nodeSelector: {}

# Tolerations (optional)
tolerations: []

# Affinity (optional)
affinity: {}
```

### Samm 6: Loo Template'id (15 min)

**6a. Deployment template**

Loo `templates/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  labels:
    app: {{ .Chart.Name }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    release: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  
  selector:
    matchLabels:
      app: {{ .Chart.Name }}
      release: {{ .Release.Name }}
  
  template:
    metadata:
      labels:
        app: {{ .Chart.Name }}
        release: {{ .Release.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        
        ports:
        - containerPort: {{ .Values.service.targetPort }}
        
        env:
        {{- range $key, $value := .Values.env }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Release.Name }}-secrets
              key: dbPassword
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: {{ .Release.Name }}-secrets
              key: jwtSecret
        
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        
        {{- if .Values.livenessProbe }}
        livenessProbe:
          {{- toYaml .Values.livenessProbe | nindent 10 }}
        {{- end }}
        
        {{- if .Values.readinessProbe }}
        readinessProbe:
          {{- toYaml .Values.readinessProbe | nindent 10 }}
        {{- end }}
      
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

**6b. Service template**

Loo `templates/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
  labels:
    app: {{ .Chart.Name }}
    release: {{ .Release.Name }}
spec:
  type: {{ .Values.service.type }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.targetPort }}
    protocol: TCP
    name: http
  selector:
    app: {{ .Chart.Name }}
    release: {{ .Release.Name }}
```

**6c. Secret template**

Loo `templates/secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-secrets
  labels:
    app: {{ .Chart.Name }}
    release: {{ .Release.Name }}
type: Opaque
data:
  # Base64 encoded (Helm encodes automatically with b64enc)
  jwtSecret: {{ .Values.secrets.jwtSecret | b64enc | quote }}
  dbPassword: {{ .Values.secrets.dbPassword | b64enc | quote }}
```

**6d. HPA template (conditional)**

Loo `templates/hpa.yaml`:

```yaml
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Release.Name }}
  labels:
    app: {{ .Chart.Name }}
    release: {{ .Release.Name }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Release.Name }}
  
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.autoscaling.targetCPUUtilizationPercentage }}
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: {{ .Values.autoscaling.targetMemoryUtilizationPercentage }}
{{- end }}
```

**6e. Ingress template (conditional)**

Loo `templates/ingress.yaml`:

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}
  labels:
    app: {{ .Chart.Name }}
    release: {{ .Release.Name }}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: {{ .Values.ingress.className }}
  rules:
  - host: {{ .Values.ingress.host }}
    http:
      paths:
      - path: {{ .Values.ingress.path }}
        pathType: {{ .Values.ingress.pathType }}
        backend:
          service:
            name: {{ .Release.Name }}
            port:
              number: {{ .Values.service.port }}
{{- end }}
```

**6f. NOTES.txt (post-install message)**

Loo `templates/NOTES.txt`:

```
🎉 User Service installed successfully!

Release Name: {{ .Release.Name }}
Namespace: {{ .Release.Namespace }}

To access your application:

{{- if .Values.ingress.enabled }}
  Ingress URL: http://{{ .Values.ingress.host }}{{ .Values.ingress.path }}
{{- else }}
  Service: kubectl port-forward svc/{{ .Release.Name }} 3000:3000
  Then access: http://localhost:3000
{{- end }}

Health check:
  curl http://{{ .Values.ingress.host }}{{ .Values.ingress.path }}/health

View pods:
  kubectl get pods -l release={{ .Release.Name }}

View logs:
  kubectl logs -l release={{ .Release.Name }} --tail=50 -f

Upgrade:
  helm upgrade {{ .Release.Name }} .

Rollback:
  helm rollback {{ .Release.Name }}

Uninstall:
  helm uninstall {{ .Release.Name }}
```

### Samm 7: Valideeri ja Paigalda Chart (10 min)

**7a. Lint chart (syntax check):**

```bash
helm lint .
# Should return: 0 chart(s) linted, 0 chart(s) failed
```

**7b. Dry-run (preview generated YAML):**

```bash
helm install user-service . --dry-run --debug

# Näitab kõiki genereeritud Kubernetes manifeste
# Kontrolli kas template'id expandisid õigesti
```

**7c. Install release:**

```bash
# Install chart
helm install user-service .

# VÕI custom values:
helm install user-service . -f values-prod.yaml

# VÕI override inline:
helm install user-service . --set replicaCount=5 --set image.tag=1.1
```

**7d. Verifitseeri:**

```bash
# List releases
helm list

# Check resources
kubectl get all -l release=user-service

# View generated manifests
helm get manifest user-service

# View values used
helm get values user-service
```

### Samm 8: Upgrade & Rollback (5 min)

**Upgrade release:**

```bash
# Muuda values.yaml (nt replicaCount: 5)
vim values.yaml

# Upgrade
helm upgrade user-service .

# Verifitseeri
helm list
kubectl get pods -l release=user-service
```

**Rollback:**

```bash
# View history
helm history user-service

# Rollback to previous revision
helm rollback user-service

# VÕI specific revision
helm rollback user-service 1
```

**Uninstall:**

```bash
helm uninstall user-service

# Kontrolli cleanup
kubectl get all -l release=user-service
# Peaks olema tühi
```

---

## ✅ Kontrolli Tulemusi

- [ ] Helm 3 paigaldatud (`helm version`)
- [ ] Chart struktuur loodud (`user-service/`)
- [ ] Chart.yaml ja values.yaml konfigureeritud
- [ ] Template'id loodud (deployment, service, secret, hpa, ingress)
- [ ] `helm lint` pass'ib
- [ ] `helm install` õnnestus
- [ ] Release töötab (`kubectl get pods`)
- [ ] `helm upgrade` toimib
- [ ] `helm rollback` toimib

---

## 🎓 Õpitud Mõisted

**Helm Chart:**
- Package Kubernetes manifestide jaoks
- Template'id + values.yaml
- Versioning (Chart.yaml version)

**Template Functions:**
- `{{ .Values.key }}` - Access values.yaml
- `{{ .Release.Name }}` - Release name
- `{{ .Chart.Name }}` - Chart name
- `{{- if }}` - Conditional logic
- `{{- range }}` - Loop
- `{{ toYaml }}` - YAML formatting
- `{{ b64enc }}` - Base64 encoding

**Release Lifecycle:**
- `helm install` - Create release
- `helm upgrade` - Update release
- `helm rollback` - Revert release
- `helm uninstall` - Delete release

**Multi-Environment:**
- `values.yaml` (default)
- `values-dev.yaml` (dev override)
- `values-prod.yaml` (prod override)
- `helm install -f values-prod.yaml`

---

## 💡 Parimad Praktikad

1. **Semantic versioning** - Chart.yaml version (1.0.0 → 1.0.1 → 1.1.0)
2. **values.yaml comments** - Dokumenteeri kõik parameetrid
3. **Conditional resources** - `{{- if .Values.ingress.enabled }}`
4. **_helpers.tpl** - Reusable template snippets
5. **NOTES.txt** - Post-install instructions
6. **helm lint** - Validate enne install'i
7. **--dry-run** - Preview enne apply'd

---

## 🔗 Järgmine Samm

**Õnnitleme! Oled lõpetanud Lab 4!**

Lab 4's õppisid:
✅ Ingress routing
✅ Horizontal Pod Autoscaler
✅ Rolling updates & health checks
✅ Resource limits & quotas
✅ Helm package manager

**Lab 5 (CI/CD) jätkab sellest:**
- GitHub Actions pipeline'id
- Automated Docker build
- Helm deploy automation
- Multi-environment (dev/staging/prod)

**Jätka:** [Labor 5: CI/CD Pipeline](../../05-cicd-lab/README.md)

---

## 📚 Viited

- [Helm Documentation](https://helm.sh/docs/)
- [Chart Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Built-in Objects](https://helm.sh/docs/chart_template_guide/builtin_objects/)

---

**Õnnitleme! Oled lõpetanud Lab 4 ja valdad nüüd production-ready Kubernetes patterns! 🎉**
