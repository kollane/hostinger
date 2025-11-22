# Lab 7 Solutions - Reference Files

See kaust sisaldab reference lahendusi Lab 7 harjutuste jaoks.

## 📂 Struktuuri Ülevaade

```
solutions/
├── README.md                      # See fail
├── vault/
│   ├── values.yaml                # Vault Helm values
│   ├── vault-policy.hcl           # Example Vault policy
│   └── vault-integration.yaml     # ServiceAccount + annotations
├── rbac/
│   ├── developer-role.yaml        # Developer Role
│   ├── readonly-role.yaml         # Read-only Role
│   ├── cicd-role.yaml             # CI/CD ServiceAccount + Role
│   └── app-serviceaccount.yaml    # Application ServiceAccount
├── network-policies/
│   ├── default-deny-all.yaml      # Baseline deny
│   ├── allow-dns.yaml             # CoreDNS access
│   ├── allow-frontend-backend.yaml
│   ├── allow-backend-db.yaml
│   ├── allow-monitoring.yaml      # Prometheus scraping
│   └── allow-external-egress.yaml
├── security-scanning/
│   ├── trivy-cronjob.yaml         # Periodic scanning
│   ├── scan-cluster-images.sh     # Script to scan all images
│   └── ci-security-check.yml      # GitHub Actions workflow
└── sealed-secrets/
    ├── example-sealed-secret.yaml # Sealed secret example
    └── sealing-howto.md           # Step-by-step guide
```

---

## 🔧 Kasutamine

### Vault Setup (Exercise 1)

```bash
# Install Vault
helm install vault hashicorp/vault \
  --namespace vault \
  --values vault/values.yaml \
  --wait

# Apply Vault integration
kubectl apply -f vault/vault-integration.yaml
```

### RBAC Setup (Exercise 2)

```bash
# Apply all RBAC configurations
kubectl apply -f rbac/developer-role.yaml
kubectl apply -f rbac/readonly-role.yaml
kubectl apply -f rbac/cicd-role.yaml
kubectl apply -f rbac/app-serviceaccount.yaml
```

### Network Policies (Exercise 3)

```bash
# Apply in order:
kubectl apply -f network-policies/default-deny-all.yaml
kubectl apply -f network-policies/allow-dns.yaml
kubectl apply -f network-policies/allow-frontend-backend.yaml
kubectl apply -f network-policies/allow-backend-db.yaml
kubectl apply -f network-policies/allow-monitoring.yaml
kubectl apply -f network-policies/allow-external-egress.yaml
```

### Security Scanning (Exercise 4)

```bash
# Local image scan
trivy image your-dockerhub-username/user-service:latest

# Periodic scanning in cluster
kubectl apply -f security-scanning/trivy-cronjob.yaml

# Scan all cluster images
chmod +x security-scanning/scan-cluster-images.sh
./security-scanning/scan-cluster-images.sh
```

### Sealed Secrets (Exercise 5)

```bash
# Install Sealed Secrets Controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# See sealing-howto.md for detailed steps
cat sealed-secrets/sealing-howto.md
```

---

## ⚠️ Märkused

**Sensitive Values:**
- Reference failid sisaldavad placeholder values
- Production'is kasuta tugevaid passwords
- Vault tokens, Sealed Secrets private keys - hoia turvaliselt

**Environment-Specific:**
- Mõned failid on namespace-specific (production)
- Adjust namespaces enda environment'i jaoks
- Test dev/staging enne production'i

**Integration:**
- Lab 5 → Lab 7: CI/CD + security scanning
- Lab 6 → Lab 7: Monitoring RBAC, network policies
- Lab 7 → Lab 8 (future): GitOps with encrypted secrets

---

## 💡 Best Practices

**Vault:**
- ✅ Use production mode (not dev mode!)
- ✅ Enable auto-unseal (cloud KMS)
- ✅ Backup unseal keys securely
- ✅ Enable audit logging

**RBAC:**
- ✅ Principle of least privilege
- ✅ Namespace-scoped Roles (not ClusterRoles)
- ✅ Dedicated ServiceAccounts per app
- ✅ Regular RBAC audits

**Network Policies:**
- ✅ Start with default deny-all
- ✅ Document each allow rule
- ✅ Test in dev/staging first
- ✅ Monitor policy violations

**Security Scanning:**
- ✅ Scan in CI/CD (before deploy)
- ✅ Periodic scanning (daily)
- ✅ Remediation SLA (Critical: 24h)
- ✅ Don't ignore everything

**Sealed Secrets:**
- ✅ BACKUP private key!
- ✅ Rotate secrets regularly
- ✅ Use with GitOps (ArgoCD)
- ✅ Version control (Git history)

---

## 🔍 Troubleshooting

Kui reference failid ei tööta:

1. **Check versions:**
   ```bash
   kubectl version
   helm version
   trivy --version
   kubeseal --version
   ```

2. **Check CRDs:**
   ```bash
   kubectl get crd | grep -E "vault|networkpolicies|sealedsecrets"
   ```

3. **Check namespaces:**
   ```bash
   kubectl get namespaces
   ```

4. **Vaata logs:**
   ```bash
   kubectl logs -n <namespace> <pod-name>
   ```

---

## 📚 Lisainfo

**Official Documentation:**
- [HashiCorp Vault](https://www.vaultproject.io/docs)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Trivy](https://aquasecurity.github.io/trivy/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)

**Security Standards:**
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [OWASP Kubernetes Top 10](https://owasp.org/www-project-kubernetes-top-ten/)
- [NSA Kubernetes Hardening Guide](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)

---

**Edu laboriga! 🔒🛡️**
