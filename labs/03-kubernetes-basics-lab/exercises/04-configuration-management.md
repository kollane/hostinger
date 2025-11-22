# Harjutus 4: Configuration Management

**Kestus:** 60 minutit
**Eesmärk:** Õppida konfiguratsiooni haldamist ConfigMaps ja Secrets'iga

---

## 📋 Ülevaade

Selles harjutuses õpid **ConfigMaps** ja **Secrets** - Kubernetes ressursid konfiguratsiooni ja sensitiivsete andmete haldamiseks.

**Probleem:**
- Environment variables on hard-coded Deployment YAML'is
- Paroolid on plaintext'is (`DB_PASSWORD: "postgres"`)
- Config muutmisel tuleb Deployment uuesti deploy'da
- Sama config kordub mitmes Deployment'is

**Lahendus:**
- **ConfigMap** - Non-sensitive config (DB_HOST, PORT, NODE_ENV)
- **Secret** - Sensitive data (passwords, API keys, certificates)
- **Eraldi ressursid** - Config on Deployment'ist lahus
- **Reusable** - Sama ConfigMap/Secret mitmes pod'is

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista ConfigMap vs Secret erinevust
- ✅ Luua ConfigMap'e YAML'iga
- ✅ Luua Secret'eid YAML'iga
- ✅ Inject ConfigMap environment variables'ina
- ✅ Inject Secret environment variables'ina
- ✅ Mount ConfigMap failina (volume)
- ✅ Mount Secret failina
- ✅ Uuenda ConfigMap'e ja rollout Deployment
- ✅ Kasutada base64 encoding'ut
- ✅ Rakendada 12-Factor App patterns

---

## 🏗️ Arhitektuur

### Enne: Hard-coded Config

```
┌──────────────────────────────────────────────────────┐
│           Deployment: user-service                   │
│                                                      │
│  spec:                                               │
│    template:                                         │
│      spec:                                           │
│        containers:                                   │
│        - name: user-service                          │
│          env:                                        │
│          - name: DB_HOST                             │
│            value: "postgres-user"  ← Hard-coded      │
│          - name: DB_PASSWORD                         │
│            value: "postgres"  ← ❌ PLAINTEXT PASSWORD│
│          - name: JWT_SECRET                          │
│            value: "secret123"  ← ❌ PLAINTEXT SECRET │
│                                                      │
│  ❌ Config on Deployment YAML'is                     │
│  ❌ Paroolid on plaintext                            │
│  ❌ Config muutmine = Deployment uuesti deploy       │
└──────────────────────────────────────────────────────┘
```

### Pärast: ConfigMap + Secret

```
┌──────────────────────────────────────────────────────────┐
│  ConfigMap: user-config (Non-sensitive)                  │
│  data:                                                   │
│    DB_HOST: "postgres-user"                              │
│    DB_PORT: "5432"                                       │
│    DB_NAME: "user_service_db"                            │
│    PORT: "3000"                                          │
│    NODE_ENV: "production"                                │
└──────────────────────┬───────────────────────────────────┘
                       │
┌──────────────────────┼───────────────────────────────────┐
│  Secret: db-user-secret (Sensitive - base64 encoded)     │
│  data:                                                   │
│    DB_USER: cG9zdGdyZXM=  (postgres)                     │
│    DB_PASSWORD: cG9zdGdyZXM=  (postgres)                 │
└──────────────────────┬───────────────────────────────────┘
                       │
┌──────────────────────┼───────────────────────────────────┐
│  Secret: jwt-secret                                      │
│  data:                                                   │
│    JWT_SECRET: c3VwZXItc2VjcmV0LWtleQ==                  │
│    JWT_EXPIRES_IN: MWg=  (1h)                            │
└──────────────────────┬───────────────────────────────────┘
                       │
                       │ envFrom / env
                       ▼
┌──────────────────────────────────────────────────────────┐
│           Deployment: user-service                       │
│                                                          │
│  spec:                                                   │
│    template:                                             │
│      spec:                                               │
│        containers:                                       │
│        - name: user-service                              │
│          envFrom:                                        │
│          - configMapRef:                                 │
│              name: user-config  ← Load all keys          │
│          - secretRef:                                    │
│              name: db-user-secret  ← Load all keys       │
│          - secretRef:                                    │
│              name: jwt-secret                            │
│                                                          │
│  ✅ Config eraldi ressursina                             │
│  ✅ Secrets base64 encoded                               │
│  ✅ Reusable (sama ConfigMap mitmes Deployment'is)       │
└──────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Mõista ConfigMap vs Secret (5 min)

**ConfigMap:**
- **Non-sensitive** config data
- Plaintext storage (base64 ei kasutata)
- Näited: DB_HOST, PORT, APP_NAME, LOG_LEVEL
- Visible kubectl get configmap -o yaml

**Secret:**
- **Sensitive** data
- Base64 encoded (NOT encryption!)
- Näited: passwords, API keys, SSH keys, TLS certs
- Type: Opaque, kubernetes.io/tls, kubernetes.io/dockerconfigjson

**OLULINE:**
- Base64 on **encoding, mitte encryption**!
- Secrets on cluster'is **plaintext** (etcd'is)
- Production'is: Encrypt secrets at rest (KMS, Vault)
- RBAC: Piira Secret access'i

---

### Samm 2: Loo ConfigMap - User Service (10 min)

**ConfigMap loomine: 3 viisi**

#### **Viis 1: YAML manifest (best practice)**

Loo fail `user-config-cm.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-config
  labels:
    app: user-service
data:
  # Key-value paarid (plaintext)
  DB_HOST: "postgres-user"
  DB_PORT: "5432"
  DB_NAME: "user_service_db"
  PORT: "3000"
  NODE_ENV: "production"
  JWT_EXPIRES_IN: "1h"
  LOG_LEVEL: "info"
```

**Deploy:**

```bash
kubectl apply -f user-config-cm.yaml

# Kontrolli
kubectl get configmaps

# Output:
# NAME          DATA   AGE
# user-config   7      10s

kubectl describe configmap user-config

# Output:
# Name:         user-config
# Namespace:    default
# Labels:       app=user-service
# Annotations:  <none>
#
# Data
# ====
# DB_HOST:
# ----
# postgres-user
# DB_PORT:
# ----
# 5432
# ...

# Vaata YAML'i
kubectl get configmap user-config -o yaml
```

#### **Viis 2: Imperatiivne (literal values)**

```bash
# Loo ConfigMap kubectl'iga (literal key-value)
kubectl create configmap user-config-imperative \
  --from-literal=DB_HOST=postgres-user \
  --from-literal=DB_PORT=5432 \
  --from-literal=PORT=3000

kubectl get configmap user-config-imperative -o yaml
```

#### **Viis 3: From file**

```bash
# Loo .env fail
cat > user-config.env <<EOF
DB_HOST=postgres-user
DB_PORT=5432
DB_NAME=user_service_db
PORT=3000
NODE_ENV=production
EOF

# Loo ConfigMap failist
kubectl create configmap user-config-from-file \
  --from-env-file=user-config.env

kubectl get configmap user-config-from-file -o yaml
```

**Soovitus:** Kasuta YAML manifest'e (versioon control, reproducible).

---

### Samm 3: Loo Secret - Database Credentials (10 min)

**Secret loomine:**

#### **Base64 encoding:**

```bash
# Encode values base64'iga
echo -n "postgres" | base64
# Output: cG9zdGdyZXM=

echo -n "super-secret-password" | base64
# Output: c3VwZXItc2VjcmV0LXBhc3N3b3Jk
```

**Loo fail `db-user-secret.yaml`:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-user-secret
  labels:
    app: user-service
type: Opaque  # Generic secret
data:
  # Base64 encoded values
  DB_USER: cG9zdGdyZXM=  # postgres
  DB_PASSWORD: cG9zdGdyZXM=  # postgres (dev only!)
```

**Deploy:**

```bash
kubectl apply -f db-user-secret.yaml

# Kontrolli
kubectl get secrets

# Output:
# NAME              TYPE     DATA   AGE
# db-user-secret    Opaque   2      10s

kubectl describe secret db-user-secret

# Output:
# Name:         db-user-secret
# Namespace:    default
# Labels:       app=user-service
# Type:  Opaque
#
# Data
# ====
# DB_PASSWORD:  8 bytes  ← Ei näita väärtust!
# DB_USER:      8 bytes

# Vaata YAML'i (base64 encoded)
kubectl get secret db-user-secret -o yaml

# Output:
# apiVersion: v1
# data:
#   DB_PASSWORD: cG9zdGdyZXM=
#   DB_USER: cG9zdGdyZXM=
# kind: Secret
# ...

# Decode base64
kubectl get secret db-user-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
# Output: postgres
```

#### **Alternatiiv: stringData (plaintext, auto-encodes)**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-user-secret
type: Opaque
stringData:  # Plaintext - Kubernetes encode'ib automaatselt base64'ks
  DB_USER: postgres
  DB_PASSWORD: postgres
```

**Pärast apply'id:**

```bash
kubectl get secret db-user-secret -o yaml
# data:
#   DB_PASSWORD: cG9zdGdyZXM=  ← Auto-encoded base64!
#   DB_USER: cG9zdGdyZXM=
```

**Soovitus dev'is:** Kasuta `stringData` (lihtsam). Production'is: kasuta external secrets (Sealed Secrets, External Secrets Operator, Vault).

---

### Samm 4: Loo Secret - JWT (5 min)

Loo fail `jwt-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
  labels:
    app: user-service
type: Opaque
stringData:
  JWT_SECRET: "super-secret-jwt-signing-key-256-bits-long"
  JWT_EXPIRES_IN: "1h"
```

**Deploy:**

```bash
kubectl apply -f jwt-secret.yaml

kubectl get secret jwt-secret -o yaml
```

---

### Samm 5: Inject ConfigMap & Secret - envFrom (10 min)

**Uuenda user-service Deployment ConfigMap/Secret kasutamiseks.**

Loo fail `user-service-deployment-with-config.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
        tier: backend
    spec:
      containers:
      - name: user-service
        image: user-service:1.0-optimized
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
          name: http

        # Inject ALL keys from ConfigMap
        envFrom:
        - configMapRef:
            name: user-config  # Laeb kõik key-value paarid env vars'ina

        # Inject ALL keys from Secrets
        - secretRef:
            name: db-user-secret
        - secretRef:
            name: jwt-secret

        # Nüüd pod'il on env vars:
        # - DB_HOST (ConfigMap)
        # - DB_PORT (ConfigMap)
        # - DB_NAME (ConfigMap)
        # - PORT (ConfigMap)
        # - NODE_ENV (ConfigMap)
        # - JWT_EXPIRES_IN (ConfigMap + Secret - Secret wins!)
        # - LOG_LEVEL (ConfigMap)
        # - DB_USER (Secret)
        # - DB_PASSWORD (Secret)
        # - JWT_SECRET (Secret)
```

**Deploy:**

```bash
# Apply Deployment
kubectl apply -f user-service-deployment-with-config.yaml

# Kontrolli pod'e
kubectl get pods -l app=user-service

# Vaata pod'i env vars'e
kubectl exec -it <user-service-pod> -- env | grep -E "DB_|JWT_|PORT|NODE_ENV"

# Output:
# DB_HOST=postgres-user
# DB_PORT=5432
# DB_NAME=user_service_db
# DB_USER=postgres
# DB_PASSWORD=postgres
# PORT=3000
# NODE_ENV=production
# JWT_SECRET=super-secret-jwt-signing-key-256-bits-long
# JWT_EXPIRES_IN=1h
```

**Testi rakendust:**

```bash
# Port forward
kubectl port-forward svc/user-service 8080:3000

# Teises terminalis
curl http://localhost:8080/health

# Output (DB pole veel, aga config töötab):
# {"status":"ERROR","database":"disconnected",...}
```

---

### Samm 6: Inject Specific Keys - env (5 min)

**Kui ei taha KÕIKI key'sid, kasuta `env` (mitte `envFrom`):**

```yaml
spec:
  containers:
  - name: user-service
    image: user-service:1.0-optimized
    env:
    # Specific key from ConfigMap
    - name: DATABASE_HOST  # Env var nimi pod'is
      valueFrom:
        configMapKeyRef:
          name: user-config
          key: DB_HOST  # Key ConfigMap'is

    # Specific key from Secret
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-user-secret
          key: DB_PASSWORD

    # Static value
    - name: CUSTOM_VAR
      value: "static-value"
```

**Millal kasutada:**
- `envFrom`: Load kõik key'd (convenience)
- `env` with `valueFrom`: Specific key'd, rename env var

---

### Samm 7: Mount ConfigMap kui Volume (10 min)

**ConfigMap'i saab mount'ida failina** (nt. nginx.conf, app.properties).

**Näide: nginx.conf ConfigMap'ina**

Loo `nginx-config-cm.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {
        worker_connections 1024;
    }

    http {
        server {
            listen 80;
            server_name localhost;

            location / {
                root /usr/share/nginx/html;
                index index.html;
            }

            location /api/ {
                proxy_pass http://user-service:3000/;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
            }
        }
    }
```

**Deploy:**

```bash
kubectl apply -f nginx-config-cm.yaml
```

**Uuenda frontend Deployment:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80

        # Mount ConfigMap volume'ina
        volumeMounts:
        - name: nginx-config-volume
          mountPath: /etc/nginx/nginx.conf  # File path pod'is
          subPath: nginx.conf  # Specific key ConfigMap'ist

      volumes:
      - name: nginx-config-volume
        configMap:
          name: nginx-config  # ConfigMap nimi
```

**Deploy ja testi:**

```bash
kubectl apply -f frontend-deployment-with-config.yaml

# Kontrolli mount'i
kubectl exec -it <frontend-pod> -- cat /etc/nginx/nginx.conf

# Output: ConfigMap'ist mount'itud nginx.conf
```

---

### Samm 8: Uuenda ConfigMap ja Rollout (10 min)

**ConfigMap/Secret muutmine:**

```bash
# Muuda ConfigMap
kubectl edit configmap user-config

# Või apply uuendatud YAML'i
vim user-config-cm.yaml
# Muuda LOG_LEVEL: "debug"

kubectl apply -f user-config-cm.yaml

# Kontrolli
kubectl get configmap user-config -o yaml
```

**OLULINE:** Pod'id ei uuene automaatselt!

**3 viisi pod'ide uuendamiseks:**

#### **1. Rollout Deployment (soovitatud)**

```bash
# Restart Deployment (pod'id recreate'itakse)
kubectl rollout restart deployment user-service

# Kontrolli
kubectl rollout status deployment user-service

# Uued pod'id loetakse uuendatud ConfigMap
```

#### **2. Muuda Deployment (force update)**

```bash
# Lisa annotation (kutsub rollout)
kubectl patch deployment user-service \
  -p '{"spec":{"template":{"metadata":{"annotations":{"configmap-version":"2"}}}}}'

# Või lisa env var, mis viitab ConfigMap resourceVersion'ile (täiustatud)
```

#### **3. Immutable ConfigMaps (Kubernetes 1.21+)**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-config-v1  # Versioned name
immutable: true  # Ei saa muuta
data:
  LOG_LEVEL: "info"
```

**Uuenda Deployment uue ConfigMap nimega:**

```yaml
envFrom:
- configMapRef:
    name: user-config-v2  # Uus versioon
```

**Eelis:** Deployment rollout käivitub automaatselt (nimi muutus).

---

### Samm 9: Loo Todo Service ConfigMap & Secret (5 min)

Sarnaselt user-service'le.

**`todo-config-cm.yaml`:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: todo-config
data:
  SERVER_PORT: "8081"
  SPRING_PROFILES_ACTIVE: "prod"
  SPRING_DATASOURCE_URL: "jdbc:postgresql://postgres-todo:5432/todo_service_db"
```

**`db-todo-secret.yaml`:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-todo-secret
type: Opaque
stringData:
  SPRING_DATASOURCE_USERNAME: postgres
  SPRING_DATASOURCE_PASSWORD: postgres
```

**Deploy:**

```bash
kubectl apply -f todo-config-cm.yaml
kubectl apply -f db-todo-secret.yaml
```

**Uuenda todo-service Deployment:**

```yaml
spec:
  template:
    spec:
      containers:
      - name: todo-service
        envFrom:
        - configMapRef:
            name: todo-config
        - secretRef:
            name: db-todo-secret
```

```bash
kubectl apply -f todo-service-deployment-with-config.yaml
```

---

### Samm 10: Best Practices & Security (5 min)

### ✅ ConfigMap Best Practices

1. **Versioon control:** Git'is hoida ConfigMap YAML'e
2. **Immutable:** Production'is kasuta `immutable: true`
3. **Namespaced:** Separate namespace'id per environment (dev/staging/prod)
4. **Naming:** Descriptive names (`app-config`, `nginx-config`)

### ✅ Secret Best Practices

1. **Ära commit Secret'eid Git'i!**
   ```bash
   # .gitignore
   *-secret.yaml
   *.secret.yaml
   ```

2. **Kasuta External Secrets (Production):**
   - **Sealed Secrets** (Bitnami)
   - **External Secrets Operator** (pull from Vault, AWS Secrets Manager)
   - **SOPS** (Mozilla - encrypt YAML files)

3. **RBAC:** Piira Secret access'i
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   rules:
   - apiGroups: [""]
     resources: ["secrets"]
     verbs: ["get"]  # Read-only
   ```

4. **Encrypt at Rest:** Enable etcd encryption (cluster-level)
   ```bash
   # K8s control plane config
   --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
   ```

5. **Audit:** Log Secret access
   ```bash
   kubectl logs -n kube-system kube-apiserver-xxx | grep secrets
   ```

### 🔒 Security Checklist

- [ ] Secrets base64 encoded (NOT plaintext)
- [ ] Secrets EI OLE Git'is
- [ ] Production: External Secrets Operator
- [ ] RBAC: Piira Secret access
- [ ] Etcd encryption enabled
- [ ] Regular secret rotation

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **ConfigMaps:**
  - [ ] `user-config` (7 keys)
  - [ ] `todo-config` (3 keys)
  - [ ] `nginx-config` (optional - nginx.conf)

- [ ] **Secrets:**
  - [ ] `db-user-secret` (DB_USER, DB_PASSWORD)
  - [ ] `db-todo-secret` (SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD)
  - [ ] `jwt-secret` (JWT_SECRET, JWT_EXPIRES_IN)

- [ ] **Deployments uuendatud:**
  - [ ] `user-service` kasutab `envFrom` ConfigMap + Secret
  - [ ] `todo-service` kasutab `envFrom` ConfigMap + Secret

- [ ] **Oskused:**
  - [ ] Loo ConfigMap ja Secret YAML'iga
  - [ ] Inject env vars `envFrom`
  - [ ] Mount ConfigMap volume'ina
  - [ ] Base64 encode/decode
  - [ ] Rollout Deployment ConfigMap muutmisel

**Kontrolli:**

```bash
kubectl get configmaps
kubectl get secrets
kubectl describe deployment user-service | grep -A10 "Environment"
kubectl exec -it <user-service-pod> -- env | grep DB_
```

---

## 🐛 Troubleshooting

### Probleem 1: ConfigMap/Secret ei eksisteeri

**Sümptom:**
```bash
kubectl get pods
# user-service-xxx   0/1   CreateContainerConfigError   0   10s
```

**Diagnoos:**

```bash
kubectl describe pod user-service-xxx

# Events:
# Warning  Failed  10s  kubelet  Error: configmap "user-config" not found
```

**Lahendus:**

```bash
# Loo ConfigMap
kubectl apply -f user-config-cm.yaml

# Pod restart'ib automaatselt
```

---

### Probleem 2: Base64 decode error

**Sümptom:**
```bash
echo "cG9zdGdyZXM" | base64 -d
# invalid input
```

**Põhjus:** Base64 string on incomplete või vale.

**Lahendus:**

```bash
# Encode uuesti
echo -n "postgres" | base64
# cG9zdGdyZXM=

# Decode
echo "cG9zdGdyZXM=" | base64 -d
# postgres
```

**OLULINE:** Kasuta `-n` flag'i (no newline)!

---

### Probleem 3: ConfigMap muutus ei rakendu

**Sümptom:** Muutsin ConfigMap, aga pod kasutab vana väärtust.

**Põhjus:** Pod'id ei uuene automaatselt.

**Lahendus:**

```bash
# Restart Deployment
kubectl rollout restart deployment user-service

# Või kasuta immutable ConfigMaps + versioned names
```

---

## 🎓 Õpitud Mõisted

### ConfigMap
- **ConfigMap:** Non-sensitive configuration data
- **Plaintext:** Ei kasuta base64
- **envFrom:** Load kõik key'd
- **env + valueFrom:** Specific key
- **volumeMount:** Mount failina

### Secret
- **Secret:** Sensitive data (passwords, keys)
- **Base64 encoded:** NOT encryption!
- **Type:** Opaque, kubernetes.io/tls, kubernetes.io/dockerconfigjson
- **stringData:** Plaintext input (auto-encodes)
- **data:** Base64 encoded input

### 12-Factor App
- **III. Config:** Store config in environment
- **Separation:** Code vs Config vs Secrets
- **Environment Parity:** Same code, different config per env

### kubectl Commands
- `kubectl create configmap <name> --from-literal=key=value`
- `kubectl create configmap <name> --from-env-file=file.env`
- `kubectl create secret generic <name> --from-literal=key=value`
- `kubectl get configmaps` / `kubectl get cm`
- `kubectl get secrets`
- `kubectl describe configmap <name>`
- `kubectl describe secret <name>`
- `kubectl edit configmap <name>`
- `kubectl rollout restart deployment/<name>` - Reload config

---

## 💡 Parimad Tavad

### ✅ DO (Tee):
1. **Kasuta ConfigMap non-sensitive config'ile** - DB_HOST, PORT
2. **Kasuta Secret sensitive data'le** - passwords, API keys
3. **stringData dev'is** - Lihtsam plaintext
4. **Immutable production'is** - `immutable: true`
5. **External Secrets production'is** - Vault, Sealed Secrets
6. **RBAC** - Piira Secret access'i
7. **Version ConfigMaps** - `user-config-v1`, `user-config-v2`

### ❌ DON'T (Ära tee):
1. **Ära commit Secret'eid Git'i** - Kasuta .gitignore
2. **Ära loe Secret'eid otse** - Kasuta RBAC
3. **Ära kasuta ConfigMap paroolidele** - Kasuta Secret
4. **Ära unusta rollout restart** - ConfigMap muutmisel

---

## 🔗 Järgmine Samm

Config on nüüd eraldi ressursides - suurepärane!

**Probleem:** Andmebaas puudub veel:
```
{"status":"ERROR","database":"disconnected"}
```

**Järgmises harjutuses:**
- Loo PostgreSQL StatefulSet
- Loo PersistentVolume (andmete püsivus)
- Loo PersistentVolumeClaim
- Testi andmete persistence pod restart'imisel

---

**Jätka:** [Harjutus 5: Persistent Storage](05-persistent-storage.md)

---

## 📚 Viited

**Kubernetes Dokumentatsioon:**
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Configure Pods with ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
- [Distribute Credentials Securely Using Secrets](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)
- [Encrypting Secret Data at Rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

**Best Practices:**
- [Configuration Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [12-Factor App: Config](https://12factor.net/config)

**External Secrets:**
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [External Secrets Operator](https://external-secrets.io/)
- [SOPS](https://github.com/mozilla/sops)

---

**Õnnitleme! Oled õppinud ConfigMaps ja Secrets! 🎉**

*Järgmises harjutuses deploy'me PostgreSQL ja õpime Persistent Storage!*
