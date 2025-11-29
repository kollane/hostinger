# Harjutus 1: HashiCorp Vault Setup & Integration

**Kestus:** 60 minutit
**Eesmärk:** Paigalda HashiCorp Vault ja integreeri Kubernetes'ega secrets management jaoks.

---

## 📋 Ülevaade

Selles harjutuses paigaldame **HashiCorp Vault** - industry-standard secrets management platform. Vault võimaldab turvaliselt hoida ja hallata API keys, passwords, certificates ja muid tundlikke andmeid.

**Miks Vault?**
- ❌ Kubernetes Secrets on base64-encoded (NOT encrypted at rest by default)
- ❌ ConfigMaps on plain text
- ❌ Hardcoded secrets in code = security disaster
- ✅ Vault encrypts secrets at rest
- ✅ Fine-grained access control (policies)
- ✅ Audit logging (kes luges mida)
- ✅ Dynamic secrets (auto-generated, auto-revoked)
- ✅ Secret rotation

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Paigaldada Vault Helm chart'iga
- ✅ Initialize ja unseal Vault
- ✅ Konfigureerida Kubernetes authentication
- ✅ Luua Vault policies
- ✅ Kasutada Vault Agent Injector (sidecar pattern)
- ✅ Inject secrets user-service'sse
- ✅ Migreerida hardcoded secrets Vault'i

---

## 🏗️ Vault Arhitektuur

```
┌──────────────────────────────────────────────────────┐
│         Kubernetes Cluster                           │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │  Vault Server (vault namespace)                │ │
│  │                                                │ │
│  │  ┌──────────────────────────────────────────┐ │ │
│  │  │  Vault Storage (file/raft backend)       │ │ │
│  │  │  - Encrypted at rest                     │ │ │
│  │  │  - High availability (HA mode)           │ │ │
│  │  └──────────────────────────────────────────┘ │ │
│  │                                                │ │
│  │  ┌──────────────────────────────────────────┐ │ │
│  │  │  Vault Auth Methods                      │ │ │
│  │  │  - Kubernetes (ServiceAccount tokens)    │ │ │
│  │  │  - AppRole, JWT, LDAP, etc              │ │ │
│  │  └──────────────────────────────────────────┘ │ │
│  │                                                │ │
│  │  ┌──────────────────────────────────────────┐ │ │
│  │  │  Secrets Engines                         │ │ │
│  │  │  - KV v2 (key-value store)              │ │ │
│  │  │  - Database (dynamic DB credentials)    │ │ │
│  │  │  - PKI (TLS certificates)               │ │ │
│  │  └──────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────┘ │
│               │                                     │
│               │ Vault Agent Injector                │
│               ▼                                     │
│  ┌────────────────────────────────────────────────┐ │
│  │  Application Pod (production namespace)        │ │
│  │                                                │ │
│  │  ┌──────────────┐     ┌───────────────────┐  │ │
│  │  │ vault-agent  │────▶│  user-service     │  │ │
│  │  │ (init +      │     │  (main container) │  │ │
│  │  │  sidecar)    │     │                   │  │ │
│  │  │              │     │ Reads secrets from│  │ │
│  │  │ Authenticates│     │ /vault/secrets/   │  │ │
│  │  │ Fetches      │     │                   │  │ │
│  │  │ secrets      │     │                   │  │ │
│  │  └──────────────┘     └───────────────────┘  │ │
│  └────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Loo Vault Namespace

```bash
# Loo dedicated namespace Vault'i jaoks
kubectl create namespace vault

# Kontrolli
kubectl get namespaces | grep vault
```

**Oodatav väljund:**
```
vault   Active   5s
```

---

### Samm 2: Lisa HashiCorp Helm Repository

```bash
# Lisa Vault Helm repo
helm repo add hashicorp https://helm.releases.hashicorp.com

# Update
helm repo update

# Kontrolli
helm search repo hashicorp/vault
```

**Oodatav väljund:**
```
NAME              CHART VERSION  APP VERSION
hashicorp/vault   0.27.0         1.15.2
```

---

### Samm 3: Loo Vault Values File

Vault saab töötada development mode (in-memory, unsealed automaatselt) või production mode (persistent storage, manual unseal).

**Lab jaoks kasutame dev mode (simple), kuid tootmises ALATI production mode!**

Loo fail `vault-values.yaml`:

```bash
vim vault-values.yaml
```

**Fail sisu:**

```yaml
# Vault Helm Chart Values
# Development mode (for lab)

server:
  # Dev mode (NOT for production!)
  dev:
    enabled: true  # Auto-unseal, in-memory storage

  # Resources
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

  # Standalone mode (not HA)
  standalone:
    enabled: true

  # Service
  service:
    enabled: true
    type: ClusterIP
    port: 8200

  # Data storage (disabled in dev mode)
  dataStorage:
    enabled: false

# Vault Agent Injector (sidecar injection)
injector:
  enabled: true

  # Resources
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 250m
      memory: 256Mi

# Vault UI
ui:
  enabled: true
  serviceType: ClusterIP

# Server-side request forgery protection
global:
  enabled: true
  tlsDisable: true  # Disable TLS for lab (enable in production!)
```

**Salvesta:** `Esc`, `:wq`, `Enter`

---

### Samm 4: Installi Vault

```bash
# Installi Vault
helm install vault hashicorp/vault \
  --namespace vault \
  --values vault-values.yaml \
  --wait \
  --timeout 5m

# Kontrolli pod
kubectl get pods -n vault
```

**Oodatav väljund:**
```
NAME                                    READY   STATUS    AGE
vault-0                                 1/1     Running   2m
vault-agent-injector-xxxxx              1/1     Running   2m
```

**Märkused:**
- Dev mode = pod auto-unseals (production'is manual unseal)
- vault-0 = Vault server
- vault-agent-injector = Webhook for sidecar injection

---

### Samm 5: Ligipääs Vault UI'le

```bash
# Port-forward Vault UI
kubectl port-forward -n vault svc/vault 8200:8200
```

**Ava brauseris:** `http://localhost:8200`

**Dev mode login:**
- **Method:** Token
- **Token:** `root` (dev mode default token)

**Vault UI:**
- **Secrets Engines** - Kus secrets hoitakse
- **Access** - Authentication methods ja policies
- **Policies** - Access control rules

**Jäta port-forward käima ja ava uus terminal.**

---

### Samm 6: Konfigureeri Kubernetes Authentication

Vault peab autentima Kubernetes pods'e (ServiceAccount tokens).

**Vault pod'ist:**

```bash
# Exec into Vault pod
kubectl exec -n vault vault-0 -- /bin/sh
```

**Vault pod'is (execute these commands):**

```bash
# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

# Exit pod
exit
```

**Selgitus:**
- `vault auth enable kubernetes` - Enable K8s auth method
- `kubernetes_host` - K8s API server address (Vault connects to this)

---

### Samm 7: Loo Secrets Vault'is

Loome database password secrets.

**Vault CLI (local machine):**

```bash
# Export Vault address
export VAULT_ADDR='http://localhost:8200'

# Login (dev mode token = root)
export VAULT_TOKEN='root'

# Enable KV secrets engine (v2)
vault secrets enable -path=secret kv-v2

# Write database password
vault kv put secret/db \
  password=SuperSecretDBPassword123 \
  username=postgres \
  host=postgres.production.svc.cluster.local \
  port=5432 \
  database=userdb

# Verify
vault kv get secret/db
```

**Oodatav väljund:**
```
======= Secret Path =======
secret/data/db

======= Data =======
Key         Value
---         -----
database    userdb
host        postgres.production.svc.cluster.local
password    SuperSecretDBPassword123
port        5432
username    postgres
```

---

### Samm 8: Loo Vault Policy

Policy määrab, kes saab lugeda/kirjutada secrets'e.

**Loo fail `user-service-policy.hcl`:**

```bash
cat > user-service-policy.hcl << 'EOF'
# Policy for user-service
# Allow read access to database secrets

path "secret/data/db" {
  capabilities = ["read"]
}
EOF
```

**Write policy to Vault:**

```bash
vault policy write user-service user-service-policy.hcl

# Verify
vault policy read user-service
```

---

### Samm 9: Loo Vault Role Kubernetes ServiceAccount Jaoks

Vault role seob Kubernetes ServiceAccount'i Vault policy'ga.

```bash
vault write auth/kubernetes/role/user-service \
    bound_service_account_names=user-service \
    bound_service_account_namespaces=production \
    policies=user-service \
    ttl=24h
```

**Selgitus:**
- `bound_service_account_names` - K8s ServiceAccount name
- `bound_service_account_namespaces` - K8s namespace
- `policies` - Vault policy to apply
- `ttl` - Token lifetime (24h)

---

### Samm 10: Loo Kubernetes ServiceAccount

```bash
# Loo ServiceAccount user-service jaoks
kubectl create serviceaccount user-service -n production

# Kontrolli
kubectl get serviceaccount -n production user-service
```

---

### Samm 11: Deploy User-Service with Vault Injection

Muudame user-service Deployment'i, et inject secrets Vault'ist.

**Loo fail `user-service-vault.yaml`:**

```bash
cat > user-service-vault.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
      annotations:
        # Vault Agent Injector annotations
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "user-service"
        
        # Inject database password
        vault.hashicorp.com/agent-inject-secret-db-password: "secret/data/db"
        vault.hashicorp.com/agent-inject-template-db-password: |
          {{- with secret "secret/data/db" -}}
          export DB_PASSWORD="{{ .Data.data.password }}"
          export DB_USERNAME="{{ .Data.data.username }}"
          export DB_HOST="{{ .Data.data.host }}"
          export DB_PORT="{{ .Data.data.port }}"
          export DB_DATABASE="{{ .Data.data.database }}"
          {{- end -}}
    spec:
      serviceAccountName: user-service
      containers:
        - name: user-service
          image: your-dockerhub-username/user-service:latest
          ports:
            - containerPort: 3000
          command: ["/bin/sh", "-c"]
          args:
            - source /vault/secrets/db-password && node server.js
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
EOF
```

**Selgitus:**
- `vault.hashicorp.com/agent-inject: "true"` - Enable injection
- `vault.hashicorp.com/role: "user-service"` - Vault role
- `vault.hashicorp.com/agent-inject-secret-*` - Secret path
- `vault.hashicorp.com/agent-inject-template-*` - Template (how to render secret)
- `source /vault/secrets/db-password` - Source rendered secret before starting app

**Apply:**

```bash
kubectl apply -f user-service-vault.yaml
```

---

### Samm 12: Kontrolli Vault Injection

```bash
# Kontrolli pod (peaks olema 2 containers)
kubectl get pods -n production -l app=user-service

# Describe pod
kubectl describe pod -n production -l app=user-service
```

**Oodatav väljund:**
```
Containers:
  vault-agent:        # Sidecar (Vault Agent)
    Image: hashicorp/vault:1.15.2
  user-service:       # Main container
    Image: user-service:latest
```

**Check secrets file:**

```bash
# Exec into main container
kubectl exec -n production -it <pod-name> -c user-service -- /bin/sh

# Inside container:
cat /vault/secrets/db-password

# Should see:
# export DB_PASSWORD="SuperSecretDBPassword123"
# export DB_USERNAME="postgres"
# ...
```

---

## ✅ Kontrolli Oma Edusamme

### Checklist

- [ ] Vault installitud vault namespace'is
- [ ] Vault UI accessible `http://localhost:8200`
- [ ] Kubernetes auth method enabled
- [ ] Secrets created in Vault (secret/db)
- [ ] Vault policy created (user-service-policy)
- [ ] Vault role created (user-service)
- [ ] ServiceAccount created (user-service)
- [ ] User-service deployed with Vault annotations
- [ ] Pod has 2 containers (vault-agent + user-service)
- [ ] Secrets visible in /vault/secrets/db-password

### Verifitseerimine

```bash
# 1. Kontrolli Vault pod
kubectl get pods -n vault

# 2. Test Vault API
curl -s http://localhost:8200/v1/sys/health | jq

# 3. Kontrolli secret
vault kv get secret/db

# 4. Kontrolli policy
vault policy read user-service

# 5. Kontrolli pod injection
kubectl get pod -n production -l app=user-service -o jsonpath='{.items[0].spec.containers[*].name}'
# Should output: vault-agent user-service
```

---

## 🔍 Troubleshooting

### Probleem: Vault pod CrashLoopBackOff

**Lahendus:**

```bash
# Kontrolli logs
kubectl logs -n vault vault-0

# Dev mode issue: restart pod
kubectl delete pod -n vault vault-0
```

---

### Probleem: Vault Agent injection failed

**Põhjus:** ServiceAccount või Vault role mismatch

**Lahendus:**

```bash
# Kontrolli ServiceAccount
kubectl get sa -n production user-service

# Kontrolli Vault role
vault read auth/kubernetes/role/user-service

# Verify bound_service_account_names matchib ServiceAccount nimega
```

---

### Probleem: Secret not found in /vault/secrets/

**Lahendus:**

```bash
# Kontrolli pod annotations
kubectl get pod -n production -l app=user-service -o yaml | grep vault.hashicorp.com

# Kontrolli vault-agent logs
kubectl logs -n production <pod-name> -c vault-agent

# Common issue: secret path typo
# Correct: secret/data/db (with /data/)
# Wrong: secret/db
```

---

## 📚 Mida Sa Õppisid?

✅ **Vault arhitektuur**
  - Sealed/unsealed state
  - Storage backends
  - Dev vs production mode

✅ **Vault secrets management**
  - KV v2 secrets engine
  - Path-based secrets
  - Secret versioning

✅ **Kubernetes integration**
  - Kubernetes auth method
  - ServiceAccount token authentication
  - Vault roles ja policies

✅ **Vault Agent Injector**
  - Sidecar pattern
  - Init container + sidecar container
  - Template rendering

✅ **Security improvements**
  - No hardcoded secrets
  - Centralized secrets management
  - Audit logging

---

## 🚀 Järgmised Sammud

**Exercise 2: Kubernetes RBAC** - Access control for users ja applications:
- Roles ja RoleBindings
- ServiceAccounts
- Least privilege principle
- Testing RBAC permissions

```bash
cat exercises/02-kubernetes-rbac.md
```

---

## 💡 Production Recommendations

**DO NOT USE DEV MODE IN PRODUCTION!**

Production setup:
```yaml
server:
  dev:
    enabled: false  # DISABLE dev mode
  
  ha:
    enabled: true   # High availability
    replicas: 3     # 3+ Vault servers
  
  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: "fast-ssd"
  
  # Auto-unseal with cloud KMS
  seal:
    awskms:  # AWS KMS
      enabled: true
```

**Best practices:**
- ✅ Use auto-unseal (AWS KMS, GCP KMS, Azure Key Vault)
- ✅ Enable audit logging
- ✅ Backup unseal keys securely (split between team members)
- ✅ Enable TLS (mTLS for Vault-to-Vault communication)
- ✅ Regular secret rotation
- ✅ Monitor Vault metrics (Prometheus integration)

---

**Õnnitleme! Vault on configured ja integated! 🔐✅**

**Kestus:** 60 minutit
**Järgmine:** Exercise 2 - Kubernetes RBAC
