# Peatükk 12: ConfigMaps ja Secrets

**Kestus:** 3 tundi
**Eeldused:** Peatükk 9-11 (Kubernetes alused, Pods, Services)
**Eesmärk:** Hallata rakenduste konfiguratsioone ja secrets'e turvaliselt

---

## Õpieesmärgid

Selle peatüki lõpuks oskad:
- Mõista 12-Factor App configuration principles
- Luua ja kasutada ConfigMaps konfiguratsiooni jaoks
- Hallata Secrets turvaliselt
- Inject'ida config'i Pods'idesse (env vars, volumes)
- Mõista Secrets management best practices

---

## 12.1 Miks ConfigMaps ja Secrets?

### Probleem: Hardcoded Configuration

**Anti-pattern:**

```javascript
// src/config.js (hardcoded!)
const config = {
  dbHost: 'postgres-prod.company.com',
  dbPort: 5432,
  dbName: 'user_service_db',
  jwtSecret: 'super-secret-key-hardcoded',  // ❌ SECRET IN CODE!
  logLevel: 'info'
};
```

**Probleemid:**
1. **No environment flexibility:**
   - Dev, staging, prod use SAME config
   - Must rebuild image for different environments

2. **Secrets in code:**
   - Git history contains secrets
   - Everyone with code access sees secrets
   - Security breach

3. **No runtime updates:**
   - Config change → rebuild → redeploy
   - No dynamic configuration

---

### 12-Factor App: Config in Environment

**Principle III:**
> "Store config in the environment. Config varies between deploys, code does not."

**Kubernetes solution:**
- **ConfigMap:** Non-sensitive configuration (DB host, log level)
- **Secret:** Sensitive data (passwords, API keys, certificates)

**Architecture:**

```
ConfigMap: backend-config
  DB_HOST: postgres-service
  DB_PORT: "5432"
  LOG_LEVEL: info

Secret: backend-secrets
  DB_PASSWORD: c3VwZXItc2VjcmV0  # base64 encoded
  JWT_SECRET: bXktand0LXNlY3JldA==

Deployment:
  → Inject ConfigMap + Secret as env vars
  → Pod reads: process.env.DB_HOST, process.env.DB_PASSWORD
```

**DevOps benefit:**
- Same Docker image → multiple environments (config external)
- Update config → no rebuild
- Secrets not in Git

---

## 12.2 ConfigMaps - Non-Sensitive Configuration

### Creating ConfigMaps

**Method 1: Literal values**

```bash
kubectl create configmap backend-config \
  --from-literal=DB_HOST=postgres-service \
  --from-literal=DB_PORT=5432 \
  --from-literal=LOG_LEVEL=info
```

**Method 2: From file**

```bash
# config.properties
DB_HOST=postgres-service
DB_PORT=5432
LOG_LEVEL=info

kubectl create configmap backend-config \
  --from-file=config.properties
```

**Method 3: YAML manifest (Infrastructure as Code)**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: default
data:
  DB_HOST: postgres-service
  DB_PORT: "5432"     # Must be string!
  LOG_LEVEL: info
  # Multi-line values
  nginx.conf: |
    server {
      listen 80;
      server_name example.com;
      location / {
        proxy_pass http://backend;
      }
    }
```

**Key points:**
- All values must be STRINGS (quote numbers!)
- Can store multi-line files (use `|` or `>`)
- NOT base64 encoded (plain text)

---

### Using ConfigMaps - Environment Variables

**Inject all keys as env vars:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  template:
    spec:
      containers:
      - name: backend
        image: backend-nodejs:1.0
        envFrom:
        - configMapRef:
            name: backend-config  # All keys → env vars
```

**Result:**

```bash
# Inside Pod:
echo $DB_HOST       # postgres-service
echo $DB_PORT       # 5432
echo $LOG_LEVEL     # info
```

---

**Inject specific keys:**

```yaml
env:
- name: DATABASE_HOST  # Custom env var name
  valueFrom:
    configMapKeyRef:
      name: backend-config
      key: DB_HOST  # ConfigMap key

- name: DATABASE_PORT
  valueFrom:
    configMapKeyRef:
      name: backend-config
      key: DB_PORT
```

---

### Using ConfigMaps - Volume Mounts

**Mount ConfigMap as files:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d  # Mount location
          readOnly: true

      volumes:
      - name: config
        configMap:
          name: nginx-config  # ConfigMap name
```

**ConfigMap:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  default.conf: |
    server {
      listen 80;
      location / {
        proxy_pass http://backend-service;
      }
    }
```

**Result:**

```
Pod filesystem:
/etc/nginx/conf.d/default.conf (file)
  → Contents: server { listen 80; ... }

Nginx reads:
→ /etc/nginx/conf.d/default.conf
→ Applies configuration
```

**Use case:**
- Application config files (nginx.conf, postgresql.conf)
- Scripts, certificates (non-sensitive)

---

### ConfigMap Updates

**Scenario:** Change log level info → debug

```bash
# Update ConfigMap
kubectl edit configmap backend-config

# Change:
LOG_LEVEL: info → LOG_LEVEL: debug
```

**Behavior:**

**Environment variables:** NOT updated (Pod restart required)

```
Pod started with LOG_LEVEL=info
ConfigMap updated: LOG_LEVEL=debug
Pod still sees: LOG_LEVEL=info

Restart Pod:
→ New env vars injected → LOG_LEVEL=debug
```

**Volume mounts:** Automatically updated (kubelet sync, ~60s delay)

```
Pod filesystem: /etc/config/LOG_LEVEL = "info"
ConfigMap updated: LOG_LEVEL=debug
Wait ~60s:
Pod filesystem: /etc/config/LOG_LEVEL = "debug"

App can re-read file → sees new value (if supports hot reload)
```

**DevOps trade-off:**
- Env vars: Fast access, no runtime updates
- Volume mounts: Runtime updates, app must support reload

📖 **Praktika:** Labor 3, Harjutus 8 - ConfigMaps for application configuration

---

## 12.3 Secrets - Sensitive Data

### Creating Secrets

**Method 1: Literal (base64 auto-encoded)**

```bash
kubectl create secret generic backend-secrets \
  --from-literal=DB_PASSWORD=super-secret-password \
  --from-literal=JWT_SECRET=my-jwt-secret-key
```

**Method 2: From file**

```bash
# .env (plain text)
DB_PASSWORD=super-secret-password
JWT_SECRET=my-jwt-secret-key

kubectl create secret generic backend-secrets \
  --from-file=.env
```

**Method 3: YAML manifest**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: default
type: Opaque
data:
  DB_PASSWORD: c3VwZXItc2VjcmV0LXBhc3N3b3Jk  # base64 encoded
  JWT_SECRET: bXktand0LXNlY3JldC1rZXk=
```

**Base64 encoding:**

```bash
# Encode
echo -n "super-secret-password" | base64
# Output: c3VwZXItc2VjcmV0LXBhc3N3b3Jk

# Decode
echo "c3VwZXItc2VjcmV0LXBhc3N3b3Jk" | base64 -d
# Output: super-secret-password
```

**IMPORTANT:**
> Base64 is NOT encryption! Anyone with kubectl access can decode Secrets.

---

### Secret Types

```yaml
type: Opaque  # Generic secret (default)

# Other types:
type: kubernetes.io/service-account-token
type: kubernetes.io/dockerconfigjson  # Docker registry auth
type: kubernetes.io/tls  # TLS certificates
type: kubernetes.io/ssh-auth  # SSH keys
```

**TLS Secret example:**

```bash
kubectl create secret tls tls-cert \
  --cert=server.crt \
  --key=server.key
```

**Docker registry auth:**

```bash
kubectl create secret docker-registry docker-hub \
  --docker-server=docker.io \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=user@company.com
```

---

### Using Secrets - Environment Variables

**Inject all keys:**

```yaml
envFrom:
- secretRef:
    name: backend-secrets  # All keys → env vars
```

**Inject specific keys:**

```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: backend-secrets
      key: DB_PASSWORD

- name: JWT_SECRET
  valueFrom:
    secretKeyRef:
      name: backend-secrets
      key: JWT_SECRET
```

**Result:**

```javascript
// Node.js application
const dbPassword = process.env.DB_PASSWORD;  // "super-secret-password"
const jwtSecret = process.env.JWT_SECRET;    // "my-jwt-secret-key"
```

---

### Using Secrets - Volume Mounts

```yaml
volumeMounts:
- name: secrets
  mountPath: /etc/secrets
  readOnly: true

volumes:
- name: secrets
  secret:
    secretName: backend-secrets
```

**Result:**

```
Pod filesystem:
/etc/secrets/DB_PASSWORD (file) → "super-secret-password"
/etc/secrets/JWT_SECRET (file) → "my-jwt-secret-key"

App reads:
const dbPassword = fs.readFileSync('/etc/secrets/DB_PASSWORD', 'utf8');
```

**Use case:**
- TLS certificates (nginx, backend)
- SSH keys, kubeconfig files
- Large secrets (files, not env vars)

---

## 12.4 Security Best Practices

### 1. Secrets NOT in Git

❌ **Never commit Secrets YAML:**

```yaml
# secret.yaml (DON'T commit this!)
apiVersion: v1
kind: Secret
data:
  DB_PASSWORD: c3VwZXItc2VjcmV0  # Base64 = NOT encrypted!
```

✅ **Better: Seal secrets or external secret managers**

---

### 2. RBAC - Restrict Secret Access

```yaml
# Only backend ServiceAccount can read backend-secrets
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["backend-secrets"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-secret-reader
subjects:
- kind: ServiceAccount
  name: backend-sa
roleRef:
  kind: Role
  name: secret-reader
```

**Effect:** Only Pods with `backend-sa` ServiceAccount can access `backend-secrets`

---

### 3. Encryption at Rest

**Kubernetes Secret storage:**

```
Secrets stored in etcd (Kubernetes database)

Default: PLAIN TEXT in etcd!
→ If attacker gets etcd access → all Secrets compromised
```

**Enable encryption at rest:**

```yaml
# /etc/kubernetes/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: <base64-encoded-32-byte-key>
  - identity: {}  # Fallback (no encryption)
```

**API server flag:**

```
--encryption-provider-config=/etc/kubernetes/encryption-config.yaml
```

**DevOps recommendation:** Always enable encryption at rest in production

---

### 4. External Secret Managers

**Problem: Kubernetes Secrets limitations:**
- Base64 encoding (not encryption)
- Stored in etcd (single point of failure)
- No audit trail (who accessed which secret?)
- No secret rotation

**Better solutions:**

**HashiCorp Vault:**
```
1. Secrets stored in Vault (encrypted, access logs)
2. Kubernetes Pods request secrets from Vault
3. Vault injects secrets as files or env vars
4. Secrets auto-rotate
```

**AWS Secrets Manager / Azure Key Vault / GCP Secret Manager:**
```
External Secrets Operator:
→ Fetch secrets from cloud provider
→ Create Kubernetes Secrets automatically
→ Sync changes
```

**Sealed Secrets (Bitnami):**
```
1. Encrypt Secret with public key → SealedSecret
2. Commit SealedSecret to Git (safe!)
3. Controller decrypts in cluster → creates Secret
```

**Example: Sealed Secrets**

```bash
# Install Sealed Secrets controller
kubectl apply -f sealed-secrets-controller.yaml

# Encrypt secret
kubeseal < secret.yaml > sealed-secret.yaml

# sealed-secret.yaml can be committed to Git!
```

```yaml
# sealed-secret.yaml (encrypted, safe to commit)
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: backend-secrets
spec:
  encryptedData:
    DB_PASSWORD: AgA7... (long encrypted string)
    JWT_SECRET: AgB8...
```

**Controller decrypts:**
```
SealedSecret → Sealed Secrets Controller → Secret (decrypted)
→ Pods can use Secret
```

📖 **Praktika:** Labor 4, Harjutus 4 - Sealed Secrets

---

## 12.5 Configuration Patterns

### Pattern 1: Environment-Specific ConfigMaps

**Dev, staging, prod have different configs:**

```yaml
# configmap-dev.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: dev
data:
  DB_HOST: postgres-dev
  LOG_LEVEL: debug

---
# configmap-prod.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: production
data:
  DB_HOST: postgres-prod
  LOG_LEVEL: info
```

**Deployment (same YAML for all envs):**

```yaml
env:
- name: DB_HOST
  valueFrom:
    configMapKeyRef:
      name: backend-config  # Namespace-specific!
      key: DB_HOST
```

**Effect:**
- Dev namespace → reads dev ConfigMap
- Prod namespace → reads prod ConfigMap
- Same Deployment YAML → different runtime config

---

### Pattern 2: Combine ConfigMap + Secret

**Separate non-sensitive and sensitive config:**

```yaml
# Non-sensitive (ConfigMap)
env:
- name: DB_HOST
  valueFrom:
    configMapKeyRef:
      name: backend-config
      key: DB_HOST

- name: DB_PORT
  valueFrom:
    configMapKeyRef:
      name: backend-config
      key: DB_PORT

# Sensitive (Secret)
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: backend-secrets
      key: DB_PASSWORD
```

**Benefit:** Clear separation (config vs secrets)

---

### Pattern 3: ConfigMap as Config File

**Application expects config file:**

```yaml
# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  config.json: |
    {
      "database": {
        "host": "postgres-service",
        "port": 5432
      },
      "logging": {
        "level": "info"
      }
    }

# Deployment
volumeMounts:
- name: config
  mountPath: /etc/app/config.json
  subPath: config.json  # Mount single file (not whole directory)

volumes:
- name: config
  configMap:
    name: app-config
```

**Result:**

```
Pod filesystem:
/etc/app/config.json → { "database": { "host": ... } }

App reads:
const config = JSON.parse(fs.readFileSync('/etc/app/config.json'));
```

---

## 12.6 Best Practices

### 1. Immutable ConfigMaps (Kubernetes 1.19+)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  DB_HOST: postgres-service
immutable: true  # Cannot be modified!
```

**Benefit:**
- Accidental changes prevented
- Performance (kubelet doesn't watch for changes)

**To update:**
```
1. Create NEW ConfigMap: backend-config-v2
2. Update Deployment to use backend-config-v2
3. Delete old ConfigMap: backend-config
```

---

### 2. Naming Convention

```yaml
# Version in name
metadata:
  name: backend-config-v1.2.3

# Environment in namespace
namespace: production
```

---

### 3. Validate Required Env Vars

**Application should fail fast:**

```javascript
// startup.js
const requiredEnvVars = ['DB_HOST', 'DB_PASSWORD', 'JWT_SECRET'];

for (const envVar of requiredEnvVars) {
  if (!process.env[envVar]) {
    console.error(`FATAL: Missing required env var: ${envVar}`);
    process.exit(1);  // Fail fast!
  }
}
```

**Effect:**
- Pod crashes immediately if config missing
- Kubernetes restarts Pod → CrashLoopBackOff
- DevOps sees error in logs → fixes config

---

### 4. Default Values

```javascript
const logLevel = process.env.LOG_LEVEL || 'info';  // Default: info
const dbPort = process.env.DB_PORT || 5432;
```

**Balance:**
- Critical config (DB_PASSWORD): NO defaults → fail fast
- Optional config (LOG_LEVEL): defaults OK

---

### 5. Documentation

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  annotations:
    description: "Backend API configuration"
    owner: "devops-team@company.com"
    last-updated: "2025-01-23"
data:
  DB_HOST: postgres-service  # PostgreSQL Service name
  LOG_LEVEL: info  # Options: debug, info, warn, error
```

---

## Kokkuvõte

### Mida sa õppisid?

**12-Factor App:**
- Config in environment, NOT in code
- Same image → multiple environments

**ConfigMaps:**
- Non-sensitive configuration
- Inject as env vars or volume mounts
- Plain text (NOT encrypted)

**Secrets:**
- Sensitive data (passwords, API keys, certificates)
- Base64 encoded (NOT encryption!)
- Inject as env vars or volume mounts
- Enable encryption at rest (production)

**Security:**
- Never commit Secrets to Git
- Use RBAC to restrict access
- External secret managers (Vault, Sealed Secrets)

**Patterns:**
- Environment-specific ConfigMaps (dev, staging, prod)
- Combine ConfigMap + Secret
- Mount as files (config.json, nginx.conf)

---

### DevOps Administraatori Vaatenurk

**Iga päev:**
```bash
kubectl get configmaps           # List ConfigMaps
kubectl get secrets              # List Secrets (base64 encoded)
kubectl describe configmap backend-config  # View data

# Decode Secret
kubectl get secret backend-secrets -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

**Updates:**
```bash
# Edit ConfigMap
kubectl edit configmap backend-config

# Rollout restart (apply new config)
kubectl rollout restart deployment backend
```

**Security:**
```bash
# Check who can access Secrets
kubectl auth can-i get secrets --as=system:serviceaccount:default:backend-sa
```

---

### Järgmised Sammud

**Peatükk 13:** Persistent Storage (PersistentVolumes, StatefulSets)
**Peatükk 14:** Ingress ja Load Balancing (external access)

---

**Kestus kokku:** ~3 tundi teooriat + praktilised harjutused labides

📖 **Praktika:**
- Labor 3, Harjutus 8 - ConfigMaps
- Labor 3, Harjutus 9 - Secrets management
- Labor 4, Harjutus 4 - Sealed Secrets
