# Harjutus 4: Security Scanning & Vulnerability Management

**Kestus:** 60 minutit
**Eesmärk:** Scan Docker images ja Kubernetes manifests vulnerabilities jaoks ja integrate CI/CD pipeline'iga.

---

## 📋 Ülevaade

Selles harjutuses implementeerime **automated security scanning** Trivy'ga - comprehensive vulnerability scanner. Trivy skaneerib:
- Docker images (OS packages, application dependencies)
- Kubernetes manifests (misconfigurations)
- Filesystems
- IaC files (Terraform, CloudFormation)

**Miks Security Scanning oluline?**
- ❌ Vulnerable Docker images production'is = security breach
- ❌ Misconfigured K8s manifests = privilege escalation
- ✅ Scan before deploy = prevent vulnerabilities
- ✅ Automated scanning = continuous security
- ✅ SARIF reports = GitHub Security integration

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Paigaldada ja kasutada Trivy
- ✅ Scanida Docker images vulnerabilities jaoks
- ✅ Scanida Kubernetes manifests misconfigurations jaoks
- ✅ Integreerida Trivy CI/CD pipeline'iga
- ✅ Genereerida SARIF reports GitHub Security jaoks
- ✅ Implementeerida vulnerability remediation workflow
- ✅ Seadistada automated periodic scanning

---

## 🏗️ Security Scanning Workflow

```
┌──────────────────────────────────────────────────────────────┐
│                  CI/CD Pipeline (GitHub Actions)             │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  1. Code Push                                          │ │
│  └────────────────┬───────────────────────────────────────┘ │
│                   │                                          │
│                   ▼                                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  2. Build Docker Image                                 │ │
│  │     docker build -t user-service:latest .             │ │
│  └────────────────┬───────────────────────────────────────┘ │
│                   │                                          │
│                   ▼                                          │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  3. Trivy Scan Image                                   │ │
│  │     trivy image user-service:latest                    │ │
│  │     - Scan OS packages (apt, apk)                      │ │
│  │     - Scan application deps (npm, pip)                 │ │
│  │     - Severity: CRITICAL, HIGH, MEDIUM, LOW            │ │
│  └────────────────┬───────────────────────────────────────┘ │
│                   │                                          │
│            ┌──────┴──────┐                                   │
│            │  Vulnerabilities found?                         │
│            └──────┬──────┘                                   │
│                   │                                          │
│         YES ◄─────┴────►  NO                                │
│          │                 │                                 │
│          ▼                 ▼                                 │
│  ┌──────────────┐   ┌──────────────┐                       │
│  │ FAIL build   │   │ PASS - Deploy│                       │
│  │ Upload SARIF │   │               │                       │
│  │ to GitHub    │   │               │                       │
│  │ Security     │   │               │                       │
│  └──────────────┘   └──────────────┘                       │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│         Periodic Scanning (CronJob in K8s)                   │
│                                                              │
│  Every 24h:                                                  │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Scan all running images                                │ │
│  │ ├─ user-service:v1.2.3                                 │ │
│  │ ├─ postgres:16                                         │ │
│  │ └─ prometheus:v2.45.0                                  │ │
│  │                                                        │ │
│  │ If Critical CVEs found → Send alert                   │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Installi Trivy (Local Machine)

```bash
# Linux (apt)
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Verify
trivy --version
```

---

### Samm 2: Scan Docker Image (Local)

```bash
# Scan user-service image
trivy image your-dockerhub-username/user-service:latest

# Scan ainult CRITICAL ja HIGH
trivy image --severity CRITICAL,HIGH your-dockerhub-username/user-service:latest

# Output JSON formaadis
trivy image -f json -o results.json your-dockerhub-username/user-service:latest

# Scan specific vulnerability
trivy image --severity CRITICAL,HIGH --exit-code 1 your-dockerhub-username/user-service:latest
# exit-code 1 = fail if vulnerabilities found (good for CI/CD)
```

**Oodatav väljund:**

```
user-service:latest (alpine 3.18)
=====================================
Total: 15 (CRITICAL: 2, HIGH: 5, MEDIUM: 8)

┌────────────────┬────────────────┬──────────┬────────────────┬───────────────────┬────────────────────────────┐
│    Library     │ Vulnerability  │ Severity │ Installed Ver  │   Fixed Version   │          Title             │
├────────────────┼────────────────┼──────────┼────────────────┼───────────────────┼────────────────────────────┤
│ libcrypto3     │ CVE-2023-12345 │ CRITICAL │ 3.1.0-r0       │ 3.1.1-r0          │ OpenSSL buffer overflow    │
│ npm            │ CVE-2023-67890 │ HIGH     │ 9.6.7          │ 10.2.0            │ npm command injection      │
└────────────────┴────────────────┴──────────┴────────────────┴───────────────────┴────────────────────────────┘
```

---

### Samm 3: Remediate Vulnerabilities

**Common remediation steps:**

1. **Update base image:**

```dockerfile
# Old (vulnerable)
FROM node:18-alpine3.17

# New (patched)
FROM node:18-alpine3.19
```

2. **Update dependencies:**

```bash
# Update package.json
npm update
npm audit fix

# Rebuild image
docker build -t user-service:latest .
```

3. **Rescan:**

```bash
trivy image user-service:latest
# Verify vulnerabilities fixed
```

---

### Samm 4: Scan Kubernetes Manifests

Trivy skaneerib ka K8s manifest'e misconfigurations jaoks.

```bash
# Scan deployment file
trivy config deployment.yaml

# Scan all files in directory
trivy config ./k8s-manifests/

# Specific checks
trivy config --severity CRITICAL,HIGH deployment.yaml
```

**Common Kubernetes misconfigurations Trivy detects:**

- Running as root (securityContext missing)
- No resource limits
- Privileged containers
- hostNetwork: true
- Insecure capabilities
- No readinessProbe/livenessProbe

**Example output:**

```
deployment.yaml (kubernetes)
============================
Tests: 25 (SUCCESSES: 18, FAILURES: 7)
Failures: 7 (CRITICAL: 2, HIGH: 3, MEDIUM: 2)

CRITICAL: Container 'user-service' of Deployment 'user-service' should set 'securityContext.runAsNonRoot' to true
══════════════════════════════════════════════════════════════════════════════════════════════════════════════
Running as root increases attack surface
───────────────────────────────────────────────────────────────────────────────────────────────────────────────
 deployment.yaml:15-30
───────────────────────────────────────────────────────────────────────────────────────────────────────────────
  15 ┌   spec:
  16 │     containers:
  17 │       - name: user-service
  18 │         image: user-service:latest
  19 └         # securityContext missing!
───────────────────────────────────────────────────────────────────────────────────────────────────────────────
```

**Fix:**

```yaml
spec:
  containers:
    - name: user-service
      image: user-service:latest
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
```

---

### Samm 5: Integrate Trivy into GitHub Actions

**Update CI workflow (`.github/workflows/ci.yml`):**

```yaml
name: CI with Security Scanning

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build-and-scan:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t user-service:${{ github.sha }} .

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'user-service:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'  # Fail build if vulnerabilities found

      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v3
        if: always()  # Upload even if scan fails
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Scan Kubernetes manifests
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
          scan-ref: './k8s/'
          format: 'table'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
```

**Commit ja push:**

```bash
git add .github/workflows/ci.yml
git commit -m "Add Trivy security scanning to CI"
git push
```

**GitHub Actions run'ib ning:**
- Scannib Docker image
- Scannib K8s manifests
- Upload'ib SARIF report GitHub Security tab'i
- Failib build kui CRITICAL/HIGH vulnerabilities

---

### Samm 6: View Security Alerts GitHub'is

**GitHub UI:**

1. Mine repository → **Security** tab
2. Kliki **Code scanning**
3. Näed Trivy alerts

**Example alert:**

```
CVE-2023-12345: OpenSSL buffer overflow in libcrypto3
Severity: Critical
Introduced in: Dockerfile:1
Remediation: Update base image to alpine:3.19
```

---

### Samm 7: Setup Periodic Scanning (CronJob)

Scan kõiki running images iga 24h.

**Loo fail `trivy-cronjob.yaml`:**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: trivy-scanner
  namespace: monitoring
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
            - name: trivy
              image: aquasec/trivy:latest
              command:
                - trivy
                - image
                - --severity
                - CRITICAL,HIGH
                - --no-progress
                - --format
                - json
                - --output
                - /tmp/trivy-results.json
                # Scan production user-service
                - your-dockerhub-username/user-service:latest
              volumeMounts:
                - name: results
                  mountPath: /tmp
          volumes:
            - name: results
              emptyDir: {}
```

**Apply:**

```bash
kubectl apply -f trivy-cronjob.yaml

# Test manually
kubectl create job --from=cronjob/trivy-scanner trivy-manual -n monitoring

# Check logs
kubectl logs -n monitoring job/trivy-manual
```

---

### Samm 8: Scan All Running Images Script

**Loo script `scan-cluster-images.sh`:**

```bash
#!/bin/bash

# Scan all unique images in cluster

echo "Scanning all images in cluster..."

# Get all unique images
kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}' | \
  tr ' ' '\n' | sort -u | while read image; do
  
  echo "================================"
  echo "Scanning: $image"
  echo "================================"
  
  trivy image --severity CRITICAL,HIGH --no-progress "$image"
  
  # Store result
  if [ $? -ne 0 ]; then
    echo "❌ Vulnerabilities found in $image"
  else
    echo "✅ No critical/high vulnerabilities in $image"
  fi
  
  echo ""
done
```

```bash
chmod +x scan-cluster-images.sh
./scan-cluster-images.sh
```

---

### Samm 9: Security Dashboard Integration

Integrate Trivy metrics Prometheus + Grafana'ga.

**Trivy Operator (Advanced):**

```bash
# Install Trivy Operator
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm install trivy-operator aqua/trivy-operator \
  --namespace trivy-system \
  --create-namespace

# Trivy Operator automaatselt:
# - Scannib kõiki pod images
# - Creates VulnerabilityReport CRDs
# - Exports metrics to Prometheus
```

**Prometheus metrics:**

```
# Vulnerability count
trivy_vulnerabilities_count{severity="CRITICAL"} 5
trivy_vulnerabilities_count{severity="HIGH"} 12

# PromQL query
sum by (namespace, image) (trivy_vulnerabilities_count{severity="CRITICAL"})
```

**Grafana Dashboard:**

- Create panel: Critical vulnerabilities by image
- Alert: if trivy_vulnerabilities_count{severity="CRITICAL"} > 0

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Trivy installed locally
- [ ] Docker image scanned (local)
- [ ] Kubernetes manifests scanned
- [ ] Vulnerabilities remediated (base image updated)
- [ ] Trivy integrated into GitHub Actions CI
- [ ] SARIF reports uploaded to GitHub Security
- [ ] Periodic scanning CronJob created
- [ ] Security alerts visible GitHub Security tab'is

### Verifitseerimine

```bash
# 1. Test Trivy local
trivy --version

# 2. Scan test image
trivy image alpine:latest

# 3. Check GitHub Actions workflow
cat .github/workflows/ci.yml | grep trivy

# 4. Check CronJob
kubectl get cronjob -n monitoring trivy-scanner

# 5. Verify GitHub Security alerts
# GitHub UI → Security → Code scanning
```

---

## 🔍 Troubleshooting

### Probleem: Trivy "database download failed"

**Lahendus:**

```bash
# Manually download database
trivy image --download-db-only

# Use offline database
trivy image --skip-db-update alpine:latest
```

---

### Probleem: Too many false positives

**Lahendus:**

```bash
# Ignore specific CVE
trivy image --ignorefile .trivyignore alpine:latest

# .trivyignore file
cat > .trivyignore << EOF
# False positive - not exploitable in our use case
CVE-2023-12345

# Will fix in next sprint
CVE-2023-67890
EOF
```

---

### Probleem: Scan takes too long

**Lahendus:**

```bash
# Scan only critical/high
trivy image --severity CRITICAL,HIGH image:latest

# Skip DB update
trivy image --skip-db-update image:latest

# Use cache
trivy image --cache-dir /tmp/trivy-cache image:latest
```

---

## 📚 Mida Sa Õppisid?

✅ **Trivy scanning**
  - Image vulnerability detection
  - Manifest misconfiguration detection
  - Severity levels (Critical, High, Medium, Low)

✅ **CI/CD integration**
  - Automated scanning in pipeline
  - SARIF reports
  - GitHub Security integration

✅ **Vulnerability management**
  - Remediation workflows
  - Base image updates
  - Dependency updates

✅ **Continuous scanning**
  - Periodic CronJob scanning
  - Cluster-wide image audits
  - Metrics integration

---

## 🚀 Järgmised Sammud

**Exercise 5: Sealed Secrets & GitOps** - Encrypted secrets in Git:
- Sealed Secrets Controller
- kubeseal CLI
- Encrypt secrets for Git storage
- GitOps-compatible secrets management

```bash
cat exercises/05-sealed-secrets.md
```

---

## 💡 Security Scanning Best Practices

✅ **Shift Left:**
- Scan early (dev environment)
- Scan in CI/CD (before production)
- Fail builds on critical vulnerabilities

✅ **Continuous Scanning:**
- Periodic scanning (daily/weekly)
- Scan running workloads
- Monitor new CVEs

✅ **Remediation SLA:**
- Critical: Fix within 24h
- High: Fix within 7 days
- Medium: Fix within 30 days

✅ **Don't Ignore Everything:**
- Justify each ignore (.trivyignore)
- Review ignores regularly
- Re-evaluate false positives

✅ **Defense in Depth:**
- Scanning is ONE layer
- Combine with: RBAC, Network Policies, Pod Security Standards
- No single solution is enough

---

**Õnnitleme! Security scanning implemented! 🔍🛡️**

**Kestus:** 60 minutit
**Järgmine:** Exercise 5 - Sealed Secrets & GitOps
