# Harjutus 5: Sealed Secrets & GitOps

**Kestus:** 60 minutit
**Eesmärk:** Implementeeri encrypted secrets Git'is GitOps-compatible secrets management.

---

## 📋 Ülevaade

Selles harjutuses implementeerime **Sealed Secrets** - Bitnami lahendus secrets'te turvaliseks hoidmiseks Git repository's. Sealed Secrets võimaldab commit'ida encrypted secrets Git'i, mida ainult Kubernetes cluster saab dekryptida.

**Probleem:**
- ❌ Kubernetes Secrets (base64) ei või commit'ida Git'i - ANYONE can decode
- ❌ Vault on hea, kuid ei ole GitOps-compatible (secrets ei ole Git'is)
- ❌ Manual `kubectl create secret` → no version control, no audit trail

**Sealed Secrets lahendus:**
- ✅ Encrypt secrets public key'ga (local machine)
- ✅ Commit encrypted SealedSecret to Git (safe!)
- ✅ Controller cluster'is decryptib private key'ga
- ✅ GitOps workflow: Git = single source of truth

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Paigaldada Sealed Secrets Controller
- ✅ Installida kubeseal CLI tool
- ✅ Encryptida Kubernetes Secrets
- ✅ Commit encrypted secrets Git'i
- ✅ Manageda secret rotation
- ✅ Backupida private key (disaster recovery)
- ✅ Integreerida GitOps workflow'ga

---

## 🏗️ Sealed Secrets Arhitektuur

```
┌─────────────────────────────────────────────────────────────┐
│                  Local Machine (Developer)                  │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │  1. Create normal Secret                           │    │
│  │     kubectl create secret generic db-password \    │    │
│  │       --from-literal=password=SuperSecret \       │    │
│  │       --dry-run=client -o yaml > secret.yaml      │    │
│  └────────────────────┬───────────────────────────────┘    │
│                       │                                     │
│                       ▼                                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │  2. Seal Secret (encrypt with public key)         │    │
│  │     kubeseal < secret.yaml > sealed-secret.yaml    │    │
│  │                                                    │    │
│  │     Public key fetched from cluster               │    │
│  └────────────────────┬───────────────────────────────┘    │
│                       │                                     │
│                       ▼                                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │  3. Commit to Git (SAFE - encrypted!)             │    │
│  │     git add sealed-secret.yaml                     │    │
│  │     git commit -m "Add DB password (sealed)"       │    │
│  │     git push                                       │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼ git pull / ArgoCD sync
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster                             │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Sealed Secrets Controller                         │    │
│  │  (has private key)                                 │    │
│  │                                                    │    │
│  │  Watches SealedSecret resources                   │    │
│  └────────────────────┬───────────────────────────────┘    │
│                       │                                     │
│                       ▼                                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │  SealedSecret Applied                              │    │
│  │  apiVersion: bitnami.com/v1alpha1                  │    │
│  │  kind: SealedSecret                                │    │
│  │  spec:                                             │    │
│  │    encryptedData:                                  │    │
│  │      password: AgB7j3k... (encrypted)             │    │
│  └────────────────────┬───────────────────────────────┘    │
│                       │                                     │
│                       ▼ Controller decrypts                 │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Normal Kubernetes Secret Created                  │    │
│  │  apiVersion: v1                                    │    │
│  │  kind: Secret                                      │    │
│  │  data:                                             │    │
│  │    password: U3VwZXJTZWNyZXQ= (base64)            │    │
│  └────────────────────┬───────────────────────────────┘    │
│                       │                                     │
│                       ▼                                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Application Pod                                   │    │
│  │  Uses normal Secret (decrypted)                    │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Installi Sealed Secrets Controller

```bash
# Install Sealed Secrets Controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Verify installation
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# Wait for pod to be Running
kubectl wait --for=condition=ready pod -l name=sealed-secrets-controller -n kube-system --timeout=300s
```

**Oodatav väljund:**

```
NAME                                        READY   STATUS    AGE
sealed-secrets-controller-xxxxx-xxxxx       1/1     Running   30s
```

---

### Samm 2: Installi kubeseal CLI (Local Machine)

```bash
# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar -xvzf kubeseal-0.24.0-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

# Verify
kubeseal --version
```

**Oodatav väljund:**

```
kubeseal version: 0.24.0
```

---

### Samm 3: Fetch Public Key

kubeseal vajab public key'ta cluster'ist.

```bash
# Fetch public key from controller
kubeseal --fetch-cert > pub-sealed-secrets.pem

# Verify
cat pub-sealed-secrets.pem
```

**Oodatav väljund:**

```
-----BEGIN CERTIFICATE-----
MIIErTCCApWgAwIBAgIRAMq...
...
-----END CERTIFICATE-----
```

**IMPORTANT:** Backup this public key! Kui cluster on destroyed, vajad seda secrets'te re-sealimiseks.

---

### Samm 4: Create ja Seal Database Password

**1. Create normal Secret (DON'T apply yet!):**

```bash
kubectl create secret generic db-password \
  --from-literal=password=SuperSecretDBPassword123 \
  --from-literal=username=postgres \
  --namespace=production \
  --dry-run=client -o yaml > db-secret.yaml
```

**2. Seal it:**

```bash
kubeseal < db-secret.yaml > db-sealed-secret.yaml

# Verify sealed secret
cat db-sealed-secret.yaml
```

**Oodatav väljund:**

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: db-password
  namespace: production
spec:
  encryptedData:
    password: AgBY3j9kL1... (long encrypted string)
    username: AgCd8fj3k... (long encrypted string)
  template:
    metadata:
      name: db-password
      namespace: production
    type: Opaque
```

**3. Verify original secret cannot be extracted:**

```bash
# This is SAFE to commit to Git!
cat db-sealed-secret.yaml

# You CANNOT reverse engineer the original password
```

---

### Samm 5: Apply SealedSecret

```bash
# Apply sealed secret
kubectl apply -f db-sealed-secret.yaml

# Controller automatically creates normal Secret
kubectl get secret db-password -n production
```

**Verify decryption:**

```bash
# Get decrypted password (inside cluster only!)
kubectl get secret db-password -n production -o jsonpath='{.data.password}' | base64 -d

# Should output: SuperSecretDBPassword123
```

---

### Samm 6: Commit to Git

```bash
# Add sealed secret to Git
git add db-sealed-secret.yaml

# Commit (SAFE - encrypted!)
git commit -m "Add database password (sealed secret)"

# Push
git push
```

**⚠️ DO NOT commit `db-secret.yaml` (original unencrypted secret)!**

**Add to `.gitignore`:**

```bash
echo "*-secret.yaml" >> .gitignore
echo "!*-sealed-secret.yaml" >> .gitignore

git add .gitignore
git commit -m "Ignore unencrypted secrets"
```

---

### Samm 7: Use Sealed Secret in Deployment

Update user-service Deployment to use sealed secret.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: production
spec:
  template:
    spec:
      containers:
        - name: user-service
          image: user-service:latest
          env:
            # Use sealed secret (controller created normal Secret)
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-password  # Name of SealedSecret
                  key: password

            - name: DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: db-password
                  key: username
```

```bash
kubectl apply -f user-service-deployment.yaml

# Verify env vars
kubectl exec -n production deployment/user-service -- env | grep DB_
```

---

### Samm 8: Secret Rotation

Update secret value ja re-seal.

**1. Create new secret with updated password:**

```bash
kubectl create secret generic db-password \
  --from-literal=password=NewSuperSecretPassword456 \
  --from-literal=username=postgres \
  --namespace=production \
  --dry-run=client -o yaml > db-secret-new.yaml
```

**2. Re-seal:**

```bash
kubeseal < db-secret-new.yaml > db-sealed-secret.yaml
```

**3. Apply updated SealedSecret:**

```bash
kubectl apply -f db-sealed-secret.yaml

# Controller updates normal Secret
# Pods using Secret will get new value (after restart)
```

**4. Commit updated sealed secret:**

```bash
git add db-sealed-secret.yaml
git commit -m "Rotate database password"
git push
```

---

### Samm 9: Backup Private Key (CRITICAL!)

**Private key on cluster'is. Kui cluster on destroyed, secrets on LOST!**

```bash
# Backup private key
kubectl get secret -n kube-system \
  -l sealedsecrets.bitnami.com/sealed-secrets-key=active \
  -o yaml > sealed-secrets-master-key.yaml

# Store SECURELY (NOT in Git!)
# Options:
# 1. Encrypted USB stick (offline backup)
# 2. Password manager (1Password, LastPass)
# 3. HashiCorp Vault
# 4. Cloud KMS (AWS Secrets Manager, GCP Secret Manager)
```

**Restore private key (disaster recovery):**

```bash
# Restore key to new cluster
kubectl apply -f sealed-secrets-master-key.yaml -n kube-system

# Restart controller
kubectl delete pod -n kube-system -l name=sealed-secrets-controller

# Controller can now decrypt existing SealedSecrets
```

---

### Samm 10: GitOps Integration (ArgoCD - Optional Preview)

Sealed Secrets on GitOps-compatible.

**ArgoCD Application:**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service
  namespace: argocd
spec:
  source:
    repoURL: https://github.com/your-org/your-repo
    path: k8s/production
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**GitOps workflow:**

1. Developer updates sealed secret (local)
2. Commit + push to Git
3. ArgoCD syncs sealed secret to cluster
4. Sealed Secrets Controller decrypts → creates normal Secret
5. Application uses Secret

**Full observability:** All secret changes visible Git history!

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Sealed Secrets Controller installed
- [ ] kubeseal CLI installed
- [ ] Public key fetched
- [ ] Secret created ja sealed
- [ ] SealedSecret applied to cluster
- [ ] Normal Secret automatically created by controller
- [ ] SealedSecret committed to Git (encrypted)
- [ ] Application uses sealed secret
- [ ] Private key backed up
- [ ] Secret rotation tested

### Verifitseerimine

```bash
# 1. Controller running
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# 2. SealedSecret exists
kubectl get sealedsecret -n production

# 3. Normal Secret created
kubectl get secret db-password -n production

# 4. Can extract value (inside cluster)
kubectl get secret db-password -n production -o jsonpath='{.data.password}' | base64 -d

# 5. Git has encrypted version
git log --oneline | grep "sealed"
```

---

## 🔍 Troubleshooting

### Probleem: kubeseal "cannot fetch certificate"

**Lahendus:**

```bash
# Check controller pod
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# Port-forward controller
kubectl port-forward -n kube-system svc/sealed-secrets-controller 8080:8080

# Fetch cert manually
curl -s http://localhost:8080/v1/cert.pem > pub-sealed-secrets.pem

# Use offline cert
kubeseal --cert pub-sealed-secrets.pem < secret.yaml > sealed-secret.yaml
```

---

### Probleem: SealedSecret not decrypting

**Lahendus:**

```bash
# Check controller logs
kubectl logs -n kube-system -l name=sealed-secrets-controller

# Common issue: namespace mismatch
# SealedSecret namespace must match Secret namespace

# Verify SealedSecret
kubectl describe sealedsecret db-password -n production

# Check if Secret was created
kubectl get secret db-password -n production
```

---

### Probleem: Lost private key

**Lahendus:**

If no backup: **Secrets are UNRECOVERABLE**. You must:
1. Re-create all secrets (new values)
2. Re-seal with new controller key
3. Update applications

**Prevention:** ALWAYS backup private key!

---

## 📚 Mida Sa Õppisid?

✅ **Sealed Secrets**
  - Asymmetric encryption (public/private key)
  - SealedSecret CRD
  - Controller pattern

✅ **GitOps-compatible secrets**
  - Safe to commit encrypted secrets
  - Git = single source of truth
  - Audit trail (Git history)

✅ **Secret lifecycle**
  - Creation and sealing
  - Rotation
  - Backup and disaster recovery

✅ **Security improvements**
  - No manual kubectl create secret
  - Version control for secrets
  - Encryption at rest (Git)

---

## 🚀 Lab 7 Complete!

**Õnnitleme! Läbisid kõik 5 harjutust! 🎉**

**Lab 7 Skills:**
✅ HashiCorp Vault secrets management
✅ Kubernetes RBAC access control
✅ Network Policies (zero-trust)
✅ Security scanning (Trivy)
✅ Sealed Secrets (GitOps)

**Production-ready security stack:**

```
┌───────────────────────────────────────────────┐
│      Production Security Checklist           │
├───────────────────────────────────────────────┤
│ ✅ Secrets in Vault (not hardcoded)         │
│ ✅ RBAC (least privilege)                   │
│ ✅ Network Policies (zero-trust)            │
│ ✅ Images scanned (Trivy in CI/CD)          │
│ ✅ Sealed Secrets in Git                    │
│ ✅ No cluster-admin in production           │
│ ✅ Security alerts enabled                  │
└───────────────────────────────────────────────┘
```

---

## 💡 Sealed Secrets vs Vault

**When to use Sealed Secrets:**
- ✅ GitOps workflow (ArgoCD, Flux)
- ✅ Simple secrets (API keys, passwords)
- ✅ No dynamic secrets needed
- ✅ Small team, simple infrastructure

**When to use Vault:**
- ✅ Dynamic secrets (database credentials rotation)
- ✅ Complex secret policies
- ✅ Integration with cloud providers (AWS, GCP)
- ✅ Large organization, multiple teams
- ✅ Compliance requirements (audit logs, encryption)

**Best practice:** Use BOTH!
- Vault: Runtime secrets (injected into pods)
- Sealed Secrets: Static configuration secrets (in Git)

---

**Õnnitleme! Lab 7 on valmis! 🔐🛡️✅**

**Kestus:** 5 tundi (5 × 60 min)
**Next Lab:** Lab 8 - GitOps with ArgoCD (future)
