# Sealed Secrets - Step-by-Step Guide

**Reference solution for Exercise 5**

---

## 📋 Prerequisites

- ✅ Kubernetes cluster running
- ✅ kubectl installed and configured
- ✅ Sealed Secrets Controller installed
- ✅ kubeseal CLI installed

---

## 🚀 Quick Start

### 1. Install Sealed Secrets Controller

```bash
# Install controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Verify installation
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# Wait for pod to be Ready
kubectl wait --for=condition=ready pod \
  -l name=sealed-secrets-controller \
  -n kube-system \
  --timeout=300s
```

---

### 2. Install kubeseal CLI

**Linux:**
```bash
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar -xvzf kubeseal-0.24.0-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

# Verify
kubeseal --version
```

**macOS:**
```bash
brew install kubeseal
```

**Windows:**
```powershell
choco install kubeseal
```

---

### 3. Fetch Public Certificate

```bash
# Fetch certificate from controller
kubeseal --fetch-cert > pub-sealed-secrets.pem

# Verify certificate
cat pub-sealed-secrets.pem
```

**Output:**
```
-----BEGIN CERTIFICATE-----
MIIErTCCApWgAwIBAgIRAMq...
...
-----END CERTIFICATE-----
```

**⚠️ IMPORTANT:** Backup this certificate! You'll need it if you lose cluster access.

---

## 🔐 Creating Sealed Secrets

### Example 1: Database Password

**Step 1: Create normal Secret (dry-run)**

```bash
kubectl create secret generic db-password \
  --from-literal=password=SuperSecretDBPassword123 \
  --from-literal=username=postgres \
  --namespace=production \
  --dry-run=client -o yaml > db-secret.yaml
```

**db-secret.yaml:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-password
  namespace: production
type: Opaque
data:
  password: U3VwZXJTZWNyZXREQlBhc3N3b3JkMTIz  # Base64
  username: cG9zdGdyZXM=
```

**Step 2: Seal the Secret**

```bash
kubeseal < db-secret.yaml > db-sealed-secret.yaml

# Or with inline cert (offline mode):
kubeseal --cert pub-sealed-secrets.pem < db-secret.yaml > db-sealed-secret.yaml
```

**Step 3: Delete plaintext secret file**

```bash
rm db-secret.yaml  # Contains sensitive data!
```

**Step 4: Commit sealed secret to Git**

```bash
git add db-sealed-secret.yaml
git commit -m "Add database password (sealed)"
git push
```

**Step 5: Apply to cluster**

```bash
kubectl apply -f db-sealed-secret.yaml

# Verify SealedSecret created
kubectl get sealedsecret -n production

# Verify normal Secret created by controller
kubectl get secret db-password -n production
```

---

### Example 2: JWT Secret

```bash
# Create secret
kubectl create secret generic jwt-secret \
  --from-literal=secret=your-jwt-secret-key-here \
  --from-literal=expiresIn=24h \
  --namespace=production \
  --dry-run=client -o yaml > jwt-secret.yaml

# Seal it
kubeseal < jwt-secret.yaml > jwt-sealed-secret.yaml

# Delete plaintext
rm jwt-secret.yaml

# Commit and apply
git add jwt-sealed-secret.yaml
git commit -m "Add JWT secret (sealed)"
kubectl apply -f jwt-sealed-secret.yaml
```

---

### Example 3: From File

```bash
# Create secret from file
kubectl create secret generic tls-cert \
  --from-file=tls.crt=server.crt \
  --from-file=tls.key=server.key \
  --namespace=production \
  --dry-run=client -o yaml > tls-secret.yaml

# Seal it
kubeseal < tls-secret.yaml > tls-sealed-secret.yaml

# Cleanup and commit
rm tls-secret.yaml
git add tls-sealed-secret.yaml
git commit -m "Add TLS certificate (sealed)"
```

---

## 🎯 Scope Types

### Strict Scope (Default)

**Most secure** - Sealed to specific namespace AND name

```bash
kubeseal < secret.yaml > sealed-secret.yaml

# Or explicitly:
kubeseal --scope strict < secret.yaml > sealed-secret.yaml
```

**Characteristics:**
- ✅ Cannot rename secret
- ✅ Cannot move to different namespace
- ✅ Most secure option

---

### Namespace-Wide Scope

**Flexible** - Sealed to namespace only, can rename

```bash
kubeseal --scope namespace-wide < secret.yaml > sealed-secret.yaml
```

**Characteristics:**
- ✅ Can rename within same namespace
- ❌ Cannot move to different namespace
- ⚠️ Less secure than strict

---

### Cluster-Wide Scope

**Most flexible** - Can use anywhere with any name

```bash
kubeseal --scope cluster-wide < secret.yaml > sealed-secret.yaml
```

**Characteristics:**
- ✅ Can use in any namespace
- ✅ Can rename freely
- ❌ Least secure option
- ⚠️ Use only when necessary

---

## 🔄 Secret Rotation

### Rotate Secret Value

```bash
# 1. Create new secret with new value
kubectl create secret generic db-password \
  --from-literal=password=NewSuperSecretPassword456 \
  --from-literal=username=postgres \
  --namespace=production \
  --dry-run=client -o yaml > new-db-secret.yaml

# 2. Seal it
kubeseal < new-db-secret.yaml > db-sealed-secret.yaml

# 3. Delete plaintext
rm new-db-secret.yaml

# 4. Commit
git add db-sealed-secret.yaml
git commit -m "Rotate database password"
git push

# 5. Apply
kubectl apply -f db-sealed-secret.yaml

# 6. Restart pods to pick up new secret
kubectl rollout restart deployment user-service -n production
```

---

## 💾 Backup & Disaster Recovery

### Backup Private Key

```bash
# Export private key
kubectl get secret -n kube-system sealed-secrets-key \
  -o yaml > sealed-secrets-key-backup.yaml

# Encrypt backup (GPG)
gpg --encrypt --recipient admin@company.com sealed-secrets-key-backup.yaml

# Store securely
# - AWS S3 (encrypted)
# - 1Password / Vault
# - Offline backup
```

**⚠️ CRITICAL:** Without this key, you CANNOT decrypt sealed secrets!

---

### Restore to New Cluster

```bash
# 1. Apply backed-up key to new cluster
kubectl apply -f sealed-secrets-key-backup.yaml

# 2. Install Sealed Secrets Controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# 3. Restart controller to pick up key
kubectl rollout restart deployment sealed-secrets-controller -n kube-system

# 4. Apply all sealed secrets
kubectl apply -f sealed-secrets/
```

---

## 🔍 Verification & Debugging

### Verify SealedSecret

```bash
# Check SealedSecret created
kubectl get sealedsecret -n production

# Describe SealedSecret
kubectl describe sealedsecret db-password -n production
```

---

### Verify Normal Secret Created

```bash
# Check Secret created by controller
kubectl get secret -n production

# Describe Secret
kubectl describe secret db-password -n production

# View Secret (base64 encoded)
kubectl get secret db-password -n production -o yaml

# Decode Secret (to verify correct value)
kubectl get secret db-password -n production \
  -o jsonpath='{.data.password}' | base64 -d
```

---

### Check Controller Logs

```bash
# View controller logs
kubectl logs -n kube-system \
  -l name=sealed-secrets-controller \
  --tail=50 \
  --follow
```

---

### Common Errors

**Error: "no key could decrypt secret"**

**Cause:** SealedSecret was created for different cluster

**Solution:**
- Re-seal secret for current cluster
- Restore private key from backup

---

**Error: SealedSecret created but no Secret appears**

**Cause:** Controller error

**Solution:**
```bash
# Check controller logs
kubectl logs -n kube-system -l name=sealed-secrets-controller

# Check events
kubectl describe sealedsecret db-password -n production

# Restart controller
kubectl rollout restart deployment sealed-secrets-controller -n kube-system
```

---

**Error: kubeseal cannot fetch cert**

**Cause:** Controller not running or network issue

**Solution:**
```bash
# Check controller running
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# Use offline mode with saved cert
kubeseal --cert pub-sealed-secrets.pem < secret.yaml > sealed-secret.yaml
```

---

## 🔐 GitOps Workflow

### ArgoCD Integration

**1. Store sealed secrets in Git:**

```
my-app/
├── deployment.yaml
├── service.yaml
└── sealed-secrets/
    ├── db-password.yaml
    └── jwt-secret.yaml
```

**2. ArgoCD syncs sealed secrets:**

ArgoCD applies sealed secrets → Controller decrypts → Normal secrets created

**3. Application uses normal secrets:**

```yaml
# deployment.yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-password
        key: password
```

---

## 📚 Best Practices

### Security

- ✅ **Always delete plaintext secret files** after sealing
- ✅ **Use strict scope by default** (most secure)
- ✅ **Backup private key** (encrypted, multiple locations)
- ✅ **Rotate secrets regularly** (30-90 days)
- ✅ **Audit sealed secrets** in Git history
- ❌ **Never commit plaintext secrets** to Git
- ❌ **Never share encrypted secrets** between clusters

---

### Operations

- ✅ **Document all secrets** (what they're for)
- ✅ **Label sealed secrets** appropriately
- ✅ **Monitor controller** (Prometheus metrics)
- ✅ **Test restore procedure** periodically
- ✅ **Use namespaces** to isolate secrets
- ✅ **Integrate with CI/CD** (automated sealing)

---

### GitOps

- ✅ **Version control** all sealed secrets
- ✅ **Review changes** in pull requests
- ✅ **Automate deployment** (ArgoCD, Flux)
- ✅ **Audit trail** (Git history)
- ✅ **Environment-specific** sealed secrets (dev, staging, prod)

---

## 🛠️ Advanced Usage

### Re-seal All Secrets

```bash
# Re-seal all secrets for new cluster
for SECRET in secrets/*.yaml; do
  kubeseal < "$SECRET" > "sealed-secrets/$(basename $SECRET)"
done
```

---

### Seal from Literal (One-liner)

```bash
echo -n "my-secret-value" | \
  kubectl create secret generic my-secret \
    --from-file=password=/dev/stdin \
    --dry-run=client -o yaml | \
  kubeseal > my-sealed-secret.yaml
```

---

### Seal Multiple Namespaces

```bash
# Seal for production
kubeseal --namespace production < secret.yaml > prod-sealed.yaml

# Seal for staging
kubeseal --namespace staging < secret.yaml > staging-sealed.yaml
```

---

## 📊 Monitoring

### Prometheus Metrics

```bash
# Port-forward controller
kubectl port-forward -n kube-system \
  svc/sealed-secrets-controller \
  8080:8080

# View metrics
curl http://localhost:8080/metrics | grep sealed_secrets
```

**Key metrics:**
- `sealed_secrets_controller_unseal_requests_total` - Total unseal requests
- `sealed_secrets_controller_unseal_errors_total` - Failed unseals

---

## 🎯 Summary

**Workflow:**
1. Create secret (dry-run)
2. Seal with kubeseal
3. Delete plaintext
4. Commit sealed secret to Git
5. Apply to cluster
6. Controller decrypts

**Remember:**
- 🔑 Backup private key!
- 🔒 Use strict scope by default
- 📝 Version control sealed secrets
- 🔄 Rotate secrets regularly
- 🚫 Never commit plaintext secrets

---

**GitOps-compatible, secure, auditable secret management! 🔐✅**
