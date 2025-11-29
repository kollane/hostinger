# Lab 7: Security & Secrets Management

**Kestus:** 5 tundi (5 × 60 min)
**Eeldused:** Lab 1-6 läbitud (eriti Lab 5 CI/CD ja Lab 6 Monitoring)
**Tehnoloogiad:** HashiCorp Vault, Kubernetes RBAC, Network Policies, Trivy, Sealed Secrets
**Keskkond:** Kubernetes cluster, Helm 3

---

## 📋 Ülevaade

Lab 7 keskendub **production-ready security** implementeerimisele. Turvalisus ei ole "nice-to-have", vaid absoluutne nõue iga production süsteemi jaoks.

**Security Pillars (CNCF Security Best Practices):**
1. **Secrets Management** - Mitte kunagi hardcode passwords/API keys
2. **Access Control** - RBAC (Role-Based Access Control)
3. **Network Security** - Network Policies (zero-trust networking)
4. **Vulnerability Management** - Security scanning ja patching
5. **GitOps Security** - Encrypted secrets in Git (Sealed Secrets)

**Integratsioon Lab 6-ga:**
- Lab 6 monitoring + Lab 7 security = **Production-Ready Platform**
- Lab 6 Grafana access → Lab 7 RBAC kontrollib, kes saab ligi
- Lab 6 logs → Lab 7 audit logs (kes tegi mida)
- Lab 6 alerts → Lab 7 security alerts (unauthorized access, vulnerabilities)

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

- ✅ Paigaldada ja kasutada HashiCorp Vault secrets management'iks
- ✅ Konfigureerida Kubernetes RBAC (Roles, RoleBindings, ServiceAccounts)
- ✅ Implementeerida Network Policies (pod-to-pod communication control)
- ✅ Skaneerida Docker images ja Kubernetes manifests vulnerabilities jaoks
- ✅ Kasutada Sealed Secrets encrypted secrets Git'is hoidmiseks
- ✅ Mõista Pod Security Standards (Restricted, Baseline, Privileged)
- ✅ Implementeerida security best practices CI/CD pipeline'is

---

## 🏗️ Security Arhitektuur

### Secrets Management Flow

```
┌────────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                            │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │         HashiCorp Vault (vault namespace)                │ │
│  │                                                          │ │
│  │  Secrets stored encrypted:                              │ │
│  │  - Database passwords                                   │ │
│  │  - API keys                                             │ │
│  │  - TLS certificates                                     │ │
│  │  - JWT secrets                                          │ │
│  └────────────┬─────────────────────────────────────────────┘ │
│               │ Vault Agent Injector (sidecar)                │
│               ▼                                               │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │  Application Pod (production namespace)                  │ │
│  │                                                          │ │
│  │  ┌─────────────────┐   ┌──────────────────────┐        │ │
│  │  │ Vault Agent     │   │ user-service         │        │ │
│  │  │ (sidecar)       │──▶│ (main container)     │        │ │
│  │  │                 │   │                      │        │ │
│  │  │ Fetches secrets │   │ Reads from /vault/   │        │ │
│  │  │ from Vault      │   │ secrets/db-password  │        │ │
│  │  └─────────────────┘   └──────────────────────┘        │ │
│  │                                                          │ │
│  │  NO hardcoded secrets in:                               │ │
│  │  ❌ Environment variables                               │ │
│  │  ❌ ConfigMaps                                          │ │
│  │  ❌ Code                                                │ │
│  └──────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

### RBAC Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                  Kubernetes RBAC                               │
│                                                                │
│  User/ServiceAccount                                           │
│        │                                                       │
│        ▼                                                       │
│  ┌──────────────┐                                             │
│  │ RoleBinding  │──────┐                                      │
│  └──────────────┘      │                                      │
│        │               │                                      │
│        │               ▼                                      │
│        │         ┌──────────┐                                 │
│        └────────▶│   Role   │                                 │
│                  └──────────┘                                 │
│                       │                                       │
│                       ▼                                       │
│               ┌───────────────┐                               │
│               │  Permissions  │                               │
│               ├───────────────┤                               │
│               │ - get pods    │                               │
│               │ - list svc    │                               │
│               │ - create dep  │                               │
│               └───────────────┘                               │
│                                                                │
│  Principle of Least Privilege:                                │
│  ✓ Only necessary permissions                                 │
│  ✓ Namespace-scoped (not cluster-wide)                        │
│  ✓ ServiceAccounts for apps (not admin)                       │
└────────────────────────────────────────────────────────────────┘
```

### Network Policies

```
┌────────────────────────────────────────────────────────────────┐
│              Network Policies (Zero Trust)                     │
│                                                                │
│  Default: DENY ALL                                            │
│  │                                                             │
│  ├─▶ Allow: Frontend → User-Service (port 3000)              │
│  │                                                             │
│  ├─▶ Allow: User-Service → PostgreSQL (port 5432)            │
│  │                                                             │
│  ├─▶ Allow: Prometheus → User-Service /metrics (port 3000)   │
│  │                                                             │
│  └─▶ DENY: Everything else                                    │
│                                                                │
│  Benefits:                                                     │
│  ✓ Lateral movement prevention (attack containment)          │
│  ✓ Compliance (PCI-DSS, HIPAA require network segmentation)  │
│  ✓ Defense in depth                                           │
└────────────────────────────────────────────────────────────────┘
```

---

## 📂 Labori Struktuur

```
07-security-secrets-lab/
├── README.md                          # See fail
├── exercises/                         # Harjutused
│   ├── 01-vault-setup.md              # 60 min - Vault install & integration
│   ├── 02-kubernetes-rbac.md          # 60 min - RBAC setup
│   ├── 03-network-policies.md         # 60 min - Pod isolation
│   ├── 04-security-scanning.md        # 60 min - Trivy, vulnerability mgmt
│   └── 05-sealed-secrets.md           # 60 min - Encrypted secrets in Git
├── solutions/                         # Reference lahendused
│   ├── vault/
│   │   ├── values.yaml                # Vault Helm values
│   │   ├── vault-policy.hcl           # Vault access policy
│   │   └── vault-integration.yaml     # ServiceAccount, annotations
│   ├── rbac/
│   │   ├── developer-role.yaml        # Developer Role
│   │   ├── readonly-role.yaml         # Read-only Role
│   │   └── serviceaccount.yaml        # App ServiceAccounts
│   ├── network-policies/
│   │   ├── default-deny-all.yaml      # Baseline deny policy
│   │   ├── allow-frontend-backend.yaml
│   │   ├── allow-backend-db.yaml
│   │   └── allow-monitoring.yaml
│   ├── security-scanning/
│   │   ├── trivy-scan.yaml            # Trivy CronJob
│   │   └── ci-security-check.yml      # GitHub Actions workflow
│   └── sealed-secrets/
│       ├── sealed-secret.yaml         # Encrypted secret
│       └── sealing-howto.md           # Step-by-step guide
└── setup.sh                           # Environment setup script
```

---

## 🔧 Eeldused

### Eelnevad labid

✅ **Lab 1-4:** Docker, Kubernetes alused ja advanced
✅ **Lab 5 (KOHUSTUSLIK):** CI/CD pipeline
  - GitHub Actions workflows
  - Multi-environment deployments
✅ **Lab 6 (KOHUSTUSLIK):** Monitoring
  - Prometheus + Grafana running
  - Application metrics collection

### Tööriistad

✅ Kubernetes cluster töötab (`kubectl cluster-info`)
✅ Helm 3 paigaldatud (`helm version`)
✅ Lab 5 ja Lab 6 komponendid deployed
✅ `kubeseal` CLI tool (installime Exercise 5's)

### Teadmised

✅ Kubernetes põhimõisted
✅ Helm chart'ide kasutamine
✅ YAML süntaks
🆕 Secrets management põhimõtted (õpime laboris)
🆕 RBAC concepts (õpime laboris)
🆕 Network security (õpime laboris)

---

## 🎓 Harjutused

### Exercise 1: HashiCorp Vault Setup (60 min)

**Eesmärk:** Paigalda Vault ja integreeri Kubernetes'ega secrets management jaoks.

**Teemad:**
- Vault arhitektuur (seal/unseal, storage backend)
- Vault installation Helm'iga (dev mode vs production)
- Vault initialization ja unseal
- Kubernetes authentication method
- Vault policies (read/write permissions)
- Vault Agent Injector (sidecar pattern)
- Secret injection user-service'sse

**Näide:**
```yaml
# Pod annotation for Vault injection
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/agent-inject-secret-db-password: "secret/data/db"
  vault.hashicorp.com/role: "user-service"
```

**Tulemus:**
- Vault running vault namespace'is
- User-service gets DB password from Vault (not hardcoded)
- Secrets roteeritavad Vault'ist (zero-downtime)

---

### Exercise 2: Kubernetes RBAC (60 min)

**Eesmärk:** Implementeeri Role-Based Access Control kõigile kasutajatele ja rakendustele.

**Teemad:**
- RBAC components (Role, RoleBinding, ClusterRole, ClusterRoleBinding)
- ServiceAccounts for applications
- User roles (developer, read-only, admin)
- Namespace-scoped permissions
- Testing RBAC (kubectl auth can-i)
- Best practices (least privilege)

**Roles:**
1. **Developer Role** - Deploy apps, view logs, exec into pods
2. **Read-Only Role** - View resources (for monitoring users)
3. **CI/CD Role** - Deploy apps via ServiceAccount (for GitHub Actions)
4. **App ServiceAccount** - Minimal permissions (e.g., read ConfigMaps)

**Tulemus:**
- Every app has dedicated ServiceAccount
- Users have appropriate roles
- No one uses cluster-admin in production

---

### Exercise 3: Network Policies (60 min)

**Eesmärk:** Implementeeri pod-to-pod communication control (zero-trust networking).

**Teemad:**
- Network Policy types (Ingress, Egress)
- Default deny-all policy
- Allow-specific policies
- Label-based selection
- Testing network connectivity
- CNI requirements (Calico, Cilium support NetworkPolicy)

**Policies:**
1. **Default Deny All** - Block all traffic by default
2. **Allow Frontend → User-Service** - Only on port 3000
3. **Allow User-Service → PostgreSQL** - Only on port 5432
4. **Allow Prometheus → All** - Scraping /metrics
5. **Allow DNS** - CoreDNS access for all pods

**Tulemus:**
- Zero-trust networking (explicit allow, implicit deny)
- Attack surface minimized
- Lateral movement prevented

---

### Exercise 4: Security Scanning (60 min)

**Eesmärk:** Scan Docker images ja Kubernetes manifests vulnerabilities jaoks.

**Teemad:**
- **Trivy** - Vulnerability scanner (images, filesystems, manifests)
- **Scanning Docker images** - CI/CD integration
- **Scanning Kubernetes YAML** - Misconfigurations
- **SARIF reports** - GitHub Security integration
- **Vulnerability severity** - Critical, High, Medium, Low
- **Remediation** - Patching, updating base images
- **CronJob scanning** - Automated periodic scans

**CI/CD Integration:**
```yaml
# GitHub Actions
- name: Run Trivy scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'user-service:latest'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail build if vulnerabilities found
```

**Tulemus:**
- All Docker images scanned before deployment
- Kubernetes manifests scanned for misconfigurations
- Security reports in GitHub Security tab
- Automated vulnerability detection

---

### Exercise 5: Sealed Secrets & GitOps (60 min)

**Eesmärk:** Store encrypted secrets in Git (GitOps-friendly secrets management).

**Teemad:**
- **Sealed Secrets** - Bitnami Sealed Secrets Controller
- **Public/private key encryption** - Asymmetric encryption
- **kubeseal CLI** - Encrypt secrets
- **SealedSecret CRD** - Encrypted secret resource
- **GitOps workflow** - Secrets in Git (encrypted)
- **Secret rotation** - Re-sealing secrets
- **Backup** - Private key backup (disaster recovery)

**Workflow:**
```bash
# 1. Create normal secret
kubectl create secret generic db-password \
  --from-literal=password=supersecret \
  --dry-run=client -o yaml > secret.yaml

# 2. Seal it
kubeseal < secret.yaml > sealed-secret.yaml

# 3. Commit to Git (safe - encrypted!)
git add sealed-secret.yaml
git commit -m "Add database password (encrypted)"

# 4. Apply to cluster
kubectl apply -f sealed-secret.yaml

# 5. Sealed Secret Controller decrypts → creates normal Secret
```

**Tulemus:**
- Secrets stored in Git (encrypted)
- GitOps-compatible secrets management
- No manual kubectl create secret needed
- Audit trail (Git history)

---

## 🚀 Kiirstart

### Automaatne Setup (Soovitatud)

```bash
# Käivita setup script
chmod +x setup.sh
lab1-setup
```

**Script kontrollib:**
- ✅ Kubernetes cluster connectivity
- ✅ Helm installation
- ✅ Lab 5 ja Lab 6 prerequisites
- ✅ Security tools availability
- ✅ Vault namespace creation

### Manuaalne Setup

```bash
# 1. Kontrolli eelduseid
kubectl cluster-info
helm version

# 2. Kontrolli Lab 5/6 komponente
kubectl get deployments -n production
kubectl get pods -n monitoring

# 3. Loo vault namespace
kubectl create namespace vault

# 4. Alusta Exercise 1'st
cat exercises/01-vault-setup.md
```

---

## 🔒 Security Best Practices

### Secrets Management

❌ **NEVER:**
- Hardcode passwords in code
- Store secrets in ConfigMaps
- Commit secrets to Git (plain text)
- Use default passwords
- Share secrets via Slack/Email

✅ **ALWAYS:**
- Use Vault or Sealed Secrets
- Rotate secrets regularly
- Use strong, random passwords
- Encrypt secrets at rest
- Audit secret access

### RBAC

✅ **Principle of Least Privilege:**
- Give minimum necessary permissions
- Use namespace-scoped Roles (not ClusterRoles)
- Separate ServiceAccounts per app
- Regular RBAC audits

### Network Security

✅ **Zero Trust:**
- Default deny all traffic
- Explicit allow policies only
- Minimize exposed ports
- Segment environments (prod, staging, dev)

### Vulnerability Management

✅ **Continuous Scanning:**
- Scan all Docker images before deployment
- Scan Kubernetes manifests
- Automated scanning in CI/CD
- Patch critical vulnerabilities within 24h
- Update base images regularly

---

## 🔗 Integratsioon Eelmiste Labidega

**Lab 5 → Lab 7:**
- Lab 5 CI/CD pipeline + Lab 7 security scanning
- Lab 5 GitHub Actions + Lab 7 Trivy integration
- Lab 5 secrets (GitHub Secrets) → Lab 7 Vault migration

**Lab 6 → Lab 7:**
- Lab 6 Prometheus RBAC (who can access metrics)
- Lab 6 Grafana RBAC (dashboard access control)
- Lab 6 AlertManager Vault secrets (Slack webhook URL)
- Lab 6 Loki Network Policy (allow Promtail → Loki)

**Lab 4 → Lab 7:**
- Lab 4 Helm charts + Lab 7 security scanning
- Lab 4 Ingress TLS certificates (Vault management)

---

## 📊 Security Metrics

Peale Lab 7 läbimist peaks sul olema:

✅ **Secrets Management:**
- 0 hardcoded secrets in code/config
- 100% secrets in Vault või Sealed Secrets
- Secret rotation policy (30-90 days)

✅ **Access Control:**
- RBAC for all users/apps
- 0 cluster-admin usage in production
- Dedicated ServiceAccounts per app

✅ **Network Security:**
- Default deny-all Network Policies
- Explicit allow rules documented
- Network segmentation per environment

✅ **Vulnerability Management:**
- 0 Critical vulnerabilities in production images
- 100% images scanned before deployment
- < 24h remediation time for Critical CVEs

---

## 📚 Õppematerjalid

### Official Documentation

- [HashiCorp Vault](https://www.vaultproject.io/docs)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Trivy](https://aquasecurity.github.io/trivy/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)

### Security Standards

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [OWASP Kubernetes Top 10](https://owasp.org/www-project-kubernetes-top-ten/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

---

## ⚠️ Troubleshooting

### Vault sealed error

```bash
# Vault needs to be unsealed after restart
kubectl exec -n vault vault-0 -- vault operator unseal <key-1>
kubectl exec -n vault vault-0 -- vault operator unseal <key-2>
kubectl exec -n vault vault-0 -- vault operator unseal <key-3>
```

### RBAC permission denied

```bash
# Check if user/ServiceAccount has permission
kubectl auth can-i get pods --as=system:serviceaccount:default:my-sa

# Describe RoleBinding
kubectl describe rolebinding my-binding -n production
```

### Network Policy blocking traffic

```bash
# Test connectivity from pod
kubectl run test-pod --image=busybox --rm -it -- wget -O- http://user-service:3000

# Check Network Policies
kubectl get networkpolicies -n production
kubectl describe networkpolicy allow-frontend-backend
```

---

## 🎯 Labori Eesmärgid

Peale Lab 7 läbimist on sul:

✅ **Production-ready security stack**
  - Vault secrets management
  - RBAC access control
  - Network Policies isolation
  - Vulnerability scanning automated

✅ **Security skills**
  - Secrets lifecycle management
  - Role-based access design
  - Zero-trust networking
  - Security scanning ja remediation

✅ **Compliance readiness**
  - SOC 2, ISO 27001, PCI-DSS compatible
  - Audit logs (RBAC, Vault)
  - Encrypted secrets
  - Network segmentation

✅ **DevSecOps mindset**
  - Security integrated in CI/CD
  - Shift-left security (early detection)
  - Automated security testing
  - Security as code (RBAC, Network Policies in Git)

---

**Alusta:** `lab1-setup` ja seejärel `cat exercises/01-vault-setup.md`

**Kestus:** 5 tundi (5 × 60 min)

**Security is not optional. It's essential. 🔒🛡️**
