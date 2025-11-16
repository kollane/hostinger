# Harjutus 4: ConfigMaps ja Secrets

**Kestus:** 60 minutit
**Eesmärk:** Õppida konfiguratsiooni ja salajaste andmete haldamist Kubernetes'es

---

## 📋 Ülevaade

Selles harjutuses õpid kasutama **ConfigMaps** ja **Secrets** - Kubernetes ressursse, mis eraldavad konfiguratsiooni rakenduse koodist. See võimaldab sama image't kasutada erinevates environmentides (dev, staging, prod).

**ConfigMap** = non-sensitive konfiguratsioon (API URLs, feature flags)
**Secret** = sensitive andmed (paroolid, API keys, sertifikaadid)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua ConfigMap'e yaml'ist ja kubectl'iga
- ✅ Luua Secret'eid erinevatel viisidel
- ✅ Kasutada ConfigMap'e environment variables'ina
- ✅ Kasutada Secret'eid environment variables'ina
- ✅ Mount'ida ConfigMap'e failidena
- ✅ Uuendada konfiguratsioone ilma pod'e restart'imata
- ✅ Mõista base64 encoding'ut

---

## 🏗️ Arhitektuur

```
┌──────────────────────────────────────────────┐
│        Kubernetes Cluster                    │
│                                              │
│  ┌────────────────┐   ┌──────────────────┐  │
│  │  ConfigMap     │   │    Secret        │  │
│  │  app-config    │   │  db-credentials  │  │
│  └────────┬───────┘   └─────────┬────────┘  │
│           │                     │           │
│           └──────────┬──────────┘           │
│                      │                      │
│                      ▼                      │
│           ┌──────────────────┐              │
│           │   Deployment     │              │
│           │  user-service    │              │
│           └──────────────────┘              │
│                      │                      │
│              ┌───────┴───────┐              │
│              ▼               ▼              │
│           ┌────┐          ┌────┐            │
│           │Pod │          │Pod │            │
│           │env:│          │env:│            │
│           │DB_ │          │DB_ │            │
│           │HOST│          │HOST│            │
│           └────┘          └────┘            │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Loo ConfigMap (15 min)

**Variant A: Literal values (kubectl)**

```bash
# Loo ConfigMap literal väärtustega
kubectl create configmap app-config \
  --from-literal=APP_NAME="User Service" \
  --from-literal=LOG_LEVEL=debug \
  --from-literal=API_VERSION=v1

# Kontrolli
kubectl get configmaps
# või lühidalt:
kubectl get cm

# NAME         DATA   AGE
# app-config   3      5s

# Vaata ConfigMap'i sisu
kubectl describe configmap app-config

# Data:
# ====
# API_VERSION:
# ----
# v1
# APP_NAME:
# ----
# User Service
# LOG_LEVEL:
# ----
# debug

# Vaata YAML formaadis
kubectl get configmap app-config -o yaml
```

**Variant B: YAML manifest**

Loo fail `app-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_NAME: "User Service"
  LOG_LEVEL: "debug"
  API_VERSION: "v1"
  PORT: "3000"
  NODE_ENV: "production"
```

```bash
kubectl apply -f app-config.yaml

# Kontrolli
kubectl get cm app-config -o yaml
```

**Variant C: From file**

Loo fail `config.properties`:

```properties
database.host=postgres
database.port=5432
database.name=user_service_db
app.timeout=30
app.retries=3
```

```bash
# Loo ConfigMap failist
kubectl create configmap db-config --from-file=config.properties

# Vaata
kubectl describe cm db-config

# Data:
# ====
# config.properties:
# ----
# database.host=postgres
# database.port=5432
# ...
```

---

### Samm 2: Loo Secret (15 min)

**Variant A: Literal values**

```bash
# Loo Secret literal väärtustega
kubectl create secret generic db-credentials \
  --from-literal=DB_USER=postgres \
  --from-literal=DB_PASSWORD=supersecret123

# Kontrolli
kubectl get secrets

# NAME             TYPE     DATA   AGE
# db-credentials   Opaque   2      5s

# Vaata Secret'i (salvestatud base64'd)
kubectl get secret db-credentials -o yaml

# data:
#   DB_PASSWORD: c3VwZXJzZWNyZXQxMjM=  # base64 encoded
#   DB_USER: cG9zdGdyZXM=              # base64 encoded
```

**Decode base64:**

```bash
# Linux/Mac
echo "c3VwZXJzZWNyZXQxMjM=" | base64 -d
# Output: supersecret123

# Või kubectl
kubectl get secret db-credentials -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
# Output: supersecret123
```

**Variant B: YAML manifest**

Loo fail `jwt-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
type: Opaque
data:
  # Base64 encoded väärtused
  JWT_SECRET: bXktc3VwZXItc2VjcmV0LWtleS0xMjM0NTY=  # my-super-secret-key-123456
```

**Base64 encode käsitsi:**

```bash
echo -n "my-super-secret-key-123456" | base64
# Output: bXktc3VwZXItc2VjcmV0LWtleS0xMjM0NTY=
```

```bash
kubectl apply -f jwt-secret.yaml
```

**Variant C: stringData (ei vaja encode'imist)**

Loo fail `jwt-secret-plain.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: jwt-secret
type: Opaque
stringData:  # Kubernetes encode'ib automaatselt
  JWT_SECRET: "my-super-secret-key-123456"
  JWT_EXPIRES_IN: "24h"
```

```bash
kubectl apply -f jwt-secret-plain.yaml

# Kubernetes teisendab stringData → data (base64)
kubectl get secret jwt-secret -o yaml
# data:
#   JWT_SECRET: bXktc3VwZXItc2VjcmV0LWtleS0xMjM0NTY=
```

---

### Samm 3: Kasuta ConfigMap Environment Variables'ina (10 min)

Muuda Deployment'i, et kasutada ConfigMap'i.

Loo fail `deployment-with-configmap.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 3000

        # Environment variables ConfigMap'ist
        env:
        # Üksikud key'd
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_NAME

        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: LOG_LEVEL

        # Või kasuta envFrom (kõik key'd korraga)
        envFrom:
        - configMapRef:
            name: app-config
```

**Deploy ja testi:**

```bash
kubectl apply -f deployment-with-configmap.yaml

# Kontrolli pod'i environment variables
kubectl exec -it deployment/user-service -- env | grep APP

# Peaks näitama:
# APP_NAME=User Service
# LOG_LEVEL=debug
# API_VERSION=v1
```

---

### Samm 4: Kasuta Secret Environment Variables'ina (10 min)

Muuda Deployment'i, et kasutada Secret'e.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 3000

        env:
        # ConfigMap
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_NAME

        # Secret (üksikud key'd)
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: DB_USER

        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: DB_PASSWORD

        # Või kasuta envFrom (kõik Secret key'd korraga)
        envFrom:
        - secretRef:
            name: jwt-secret
```

**Deploy ja testi:**

```bash
kubectl apply -f deployment-with-secret.yaml

# Kontrolli (ETTEVAATUST - secret on nähtav!)
kubectl exec -it deployment/user-service -- env | grep DB

# DB_USER=postgres
# DB_PASSWORD=supersecret123

# Märkus: env näitab decoded väärtust!
```

---

### Samm 5: Mount ConfigMap Failina (10 min)

ConfigMap võib ka mount'ida volume'ina (failid pod'is).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: user-service:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 3000

        # Mount ConfigMap failina
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
          readOnly: true

      # Define volume
      volumes:
      - name: config-volume
        configMap:
          name: db-config  # Loodud Samm 1, Variant C
```

**Testi:**

```bash
kubectl apply -f deployment-with-volume.yaml

# Sisene pod'i
kubectl exec -it deployment/user-service -- sh

# Pod sees:
ls -la /etc/config

# Peaks näitama:
# config.properties -> ..data/config.properties

cat /etc/config/config.properties

# Peaks näitama:
# database.host=postgres
# database.port=5432
# ...

exit
```

---

### Samm 6: Uuenda ConfigMap (5 min)

Kui ConfigMap on mount'itud volume'ina, uuendused ilmuvad automaatselt (60-90 sec delay).

```bash
# Uuenda ConfigMap
kubectl edit configmap db-config

# Muuda näiteks:
# database.host=postgres → database.host=postgres-new

# Või:
kubectl patch configmap db-config -p '{"data":{"database.host":"postgres-new"}}'

# Oota ~90 sekundit

# Kontrolli pod'is
kubectl exec -it deployment/user-service -- cat /etc/config/config.properties

# Peaks näitama uut väärtust:
# database.host=postgres-new

# Märkus: Rakendus peab ise faili uuesti lugema!
```

**Environment variables ei uuene automaatselt** - vaja pod restart:

```bash
# Kui kasutad env, restart pod
kubectl rollout restart deployment/user-service
```

---

### Samm 7: Immutable ConfigMaps ja Secrets (5 min)

Alates K8s 1.19 saad luua immutable ressursse (ei saa muuta).

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: immutable-config
data:
  API_URL: "https://api.example.com"
immutable: true  # Ei saa muuta!
```

**Eelis:**
- Performance (kubelet ei pea jälgima muudatusi)
- Turvalisus (väldib juhuslikke muudatusi)

**Puudus:**
- Kui vaja muuta, tuleb luua uus ConfigMap ja uuendada Deployment

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **ConfigMap:**
  - [ ] Luua literal, YAML ja file'ist
  - [ ] Kasutada environment variables'ina
  - [ ] Mount'ida volume'ina

- [ ] **Secret:**
  - [ ] Luua literal, YAML (base64), stringData
  - [ ] Kasutada environment variables'ina
  - [ ] Mõista base64 encoding'ut

- [ ] **Deployment integration:**
  - [ ] `env.valueFrom.configMapKeyRef`
  - [ ] `env.valueFrom.secretKeyRef`
  - [ ] `envFrom.configMapRef`
  - [ ] `volumes.configMap`

- [ ] **Uuendamine:**
  - [ ] ConfigMap/Secret uuendamine
  - [ ] Rollout restart Deployment

---

## 🐛 Troubleshooting

### Probleem 1: Pod ei käivitu - MountVolume.SetUp failed

**Sümptom:**
```bash
kubectl describe pod user-service-xxx

# Events:
# MountVolume.SetUp failed for volume "config-volume" : configmap "app-config" not found
```

**Lahendus:**

```bash
# Kontrolli, kas ConfigMap eksisteerib
kubectl get cm app-config

# Kui puudub, loo:
kubectl apply -f app-config.yaml
```

---

### Probleem 2: Environment variable on tühi

**Sümptom:**
```bash
kubectl exec -it deployment/user-service -- env | grep APP_NAME
# (tühi)
```

**Diagnoos:**

```bash
# Kontrolli, kas ConfigMap key eksisteerib
kubectl get cm app-config -o yaml

# Kontrolli Deployment env määratlust
kubectl get deployment user-service -o yaml | grep -A 5 "env:"

# Kas key name matchib?
```

---

### Probleem 3: Secret base64 decode error

**Sümptom:**
```bash
echo "invalid-base64" | base64 -d
# base64: invalid input
```

**Lahendus:**

Kasuta `stringData` YAML'is (Kubernetes encode'ib automaatselt):

```yaml
stringData:
  PASSWORD: "my-password"  # Ei vaja base64
```

---

## 🎓 Õpitud Mõisted

### ConfigMap:
- **ConfigMap:** Key-value store non-sensitive konfiguratsioonile
- **data:** Key-value paarid
- **Kasutamine:** env, envFrom, volumes
- **Uuendamine:** kubectl edit, kubectl patch

### Secret:
- **Secret:** Key-value store sensitive andmetele
- **type: Opaque:** Generic secret (default)
- **data:** Base64 encoded väärtused
- **stringData:** Plain text (Kubernetes encode'ib)
- **Decoding:** `kubectl get secret -o jsonpath | base64 -d`

### Environment Variables:
- **env.valueFrom.configMapKeyRef:** Üks key ConfigMap'ist
- **env.valueFrom.secretKeyRef:** Üks key Secret'ist
- **envFrom.configMapRef:** Kõik key'd ConfigMap'ist
- **envFrom.secretRef:** Kõik key'd Secret'ist

### Volumes:
- **volumeMounts:** Kuhu mount'ida pod'is
- **volumes.configMap:** ConfigMap volume source
- **readOnly:** Keela kirjutamine (best practice)

---

## 💡 Parimad Tavad

1. **Ära harda-code konfiguratsiooni image'isse** - Kasuta ConfigMap/Secret
2. **Kasuta Secret'e sensitive andmetele** - Mitte ConfigMap
3. **Kasuta stringData Secret'iga** - Lihtsam kui base64
4. **Immutable production ConfigMaps** - Väldib juhuslikke muudatusi
5. **Ära commit Secret'eid Git'i** - Kasuta .gitignore või sealed-secrets
6. **Namespace secrets** - Ära jaga Secret'e namespace'ide vahel
7. **RBAC Secret'idele** - Piira ligipääsu
8. **Environment specific ConfigMaps** - dev-config, prod-config
9. **Mount failina, kui rakendus loeb faili** - env ainult lihtsate väärtuste jaoks
10. **Rollout restart peale env muutust** - Env variables ei uuene automaatselt

---

## 🔒 Turvalisus

**Secret'id ei ole krüpteeritud etcd'is (default)!**

Täiendavad turvameetmed:
- **Enable encryption at rest:** etcd encryption
- **Use external secret managers:** Vault, AWS Secrets Manager, Azure Key Vault
- **Sealed Secrets:** Bitnami sealed-secrets (encrypt'itud Git'is)
- **RBAC:** Piira, kes saab lugeda Secret'eid

```bash
# Kontrolli, kes saab lugeda secret'eid
kubectl auth can-i get secrets --as=system:serviceaccount:default:default
# no

# Ainult admin'id peaksid saama
```

---

## 🔗 Järgmine Samm

Nüüd oskad hallata konfiguratsioone ConfigMaps ja Secrets'iga! Aga kuidas säilitada andmeid, kui pod restart'ib?

Järgmises harjutuses õpid **Persistent Volumes** - andmete püsiv salvestamine!

**Jätka:** [Harjutus 5: Persistent Volumes](05-persistent-volumes.md)

---

## 📚 Viited

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Distribute Credentials Securely](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)

---

**Õnnitleme! Oskad nüüd hallata konfiguratsioone nagu DevOps meister! 🔐**
