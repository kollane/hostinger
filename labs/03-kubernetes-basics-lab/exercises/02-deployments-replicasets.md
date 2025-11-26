# Harjutus 2: Deployments & ReplicaSets

**Kestus:** 60 minutit
**Eesmärk:** Õppida rakenduste deklaratiivset haldamist Deployment'idega

---

## 📋 Ülevaade

Selles harjutuses õpid **Deployment'e** - Kubernetes ressurssi, mis **haldab pod'e automaatselt**. Deployment tagab:
- **Self-healing** - pod crashib → loob automaatselt uue
- **Scaling** - käivita mitu koopiat (replicas)
- **Rolling updates** - uuenda rakendust ilma downtime'ita
- **Rollback** - tagasi eelmise versiooni juurde

**Deployment vs Pod:**
- **Pod** (Harjutus 1): Käsitsi loodud, ei tule crashist tagasi
- **Deployment** (see harjutus): Haldab pod'e, self-healing, scaling, updates

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista Deployment vs Pod erinevust
- ✅ Luua Deployment manifest'e YAML'is
- ✅ Deploy'da User Service ja Todo Service Deployment'idega
- ✅ Scale'ida Deployment'e (replicas)
- ✅ Teha rolling update (uuenda image versioon)
- ✅ Rollback ebaõnnestunud update
- ✅ Mõista ReplicaSet'i rolli
- ✅ Vaadata Deployment history't
- ✅ Debuggida Deployment probleeme

---

## 🏗️ Arhitektuur

### Pod vs Deployment

```
┌────────────────────────────────────────────────────────────────┐
│                    Pod (Harjutus 1)                            │
│                                                                │
│  kubectl apply -f pod.yaml                                     │
│         │                                                      │
│         ▼                                                      │
│    ┌─────────┐                                                │
│    │   Pod   │  ← Kui crashib → KADUNUD (ei tule tagasi)     │
│    └─────────┘                                                │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                Deployment (See harjutus)                       │
│                                                                │
│  kubectl apply -f deployment.yaml                              │
│         │                                                      │
│         ▼                                                      │
│  ┌──────────────┐                                             │
│  │  Deployment  │  ← Juhib ReplicaSet'i                       │
│  │ replicas: 3  │                                             │
│  └──────┬───────┘                                             │
│         │                                                      │
│         ▼                                                      │
│  ┌──────────────┐                                             │
│  │  ReplicaSet  │  ← Tagab 3 pod'i olemasolu                  │
│  │ desired: 3   │                                             │
│  └──────┬───────┘                                             │
│         │                                                      │
│         ├───────────┬───────────┐                             │
│         ▼           ▼           ▼                             │
│     ┌───────┐   ┌───────┐   ┌───────┐                        │
│     │ Pod 1 │   │ Pod 2 │   │ Pod 3 │                        │
│     └───────┘   └───────┘   └───────┘                        │
│         │           │           │                             │
│         │      Pod 2 crashib    │                             │
│         │           ▼           │                             │
│         │      ┌───────┐        │                             │
│         │      │ Pod 2'│ ← Loob automaatselt uue!            │
│         │      │ (new) │        │                             │
│         │      └───────┘        │                             │
└────────────────────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Mõista Deployment Kontseptsiooni (5 min)

**Deployment hierarchy:**

```
Deployment
    ↓ creates and manages
ReplicaSet
    ↓ creates and manages
Pods
```

**Deployment:**
- Deklareerib soovitud seisund (desired state)
- Haldab versioone (rollout history)
- Teeb rolling updates'e
- Võimaldab rollback'i

**ReplicaSet:**
- Tagab õige arvu pod'e (replicas)
- Asendab crashed pod'e
- Scale'ib üles/alla
- **Tavaliselt ei puutu ReplicaSet'iga otse** (Deployment haldab seda)

**Pod:**
- Käivitab actual container'id
- Managed by ReplicaSet

---

### Samm 2: Loo Esimene Deployment - User Service (10 min)

Loo fail `user-service-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  replicas: 2  # Käivita 2 pod'i
  selector:
    matchLabels:
      app: user-service  # Deployment haldab pod'e, millel on see label
  template:  # Pod template - kuidas pod'id luuakse
    metadata:
      labels:
        app: user-service  # Pod'idele antav label (peab match'ima selector'iga!)
        tier: backend
    spec:
      containers:
      - name: user-service
        image: user-service:1.0-optimized
        imagePullPolicy: Never  # Minikube: kasuta local image'i
        ports:
        - containerPort: 3000
          name: http
          protocol: TCP
        env:
        - name: PORT
          value: "3000"
        - name: NODE_ENV
          value: "development"
        - name: DB_HOST
          value: "postgres-user"  # Loome hiljem (Harjutus 5)
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "user_service_db"
        - name: DB_USER
          value: "postgres"
        - name: DB_PASSWORD
          value: "postgres"  # TEMPORARY - liigume Secrets'i Harjutus 4'is
        - name: JWT_SECRET
          value: "temporary-dev-secret-key"
        - name: JWT_EXPIRES_IN
          value: "1h"
```

**YAML struktuuri selgitus:**

```yaml
apiVersion: apps/v1          # Deployment on apps API group'is (mitte core v1)
kind: Deployment
metadata:
  name: user-service         # Deployment'i nimi
  labels:                    # Deployment'i enda label'id
    app: user-service
spec:
  replicas: 2                # Mitu pod'i käivitada
  selector:                  # Kuidas leida hallatud pod'e
    matchLabels:
      app: user-service      # PEAB MATCH'ima template.metadata.labels'iga!
  template:                  # Pod template (sama nagu Harjutus 1 Pod manifest)
    metadata:
      labels:
        app: user-service    # Pod'idele antakse see label
    spec:
      containers:            # Container definitsioonid (sama nagu Pod'is)
      - name: user-service
        image: user-service:1.0-optimized
        ...
```

**Deploy:**

```bash
# Apply Deployment
kubectl apply -f user-service-deployment.yaml

# Output:
# deployment.apps/user-service created

# Kontrolli Deployment'i
kubectl get deployments

# Output:
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   2/2     2            2           10s

# Kontrolli ReplicaSet'i (automaatselt loodud)
kubectl get replicasets

# Output:
# NAME                      DESIRED   CURRENT   READY   AGE
# user-service-7d4f8c9b6d   2         2         2       15s
#              ^^^^^^^^^^^ Random hash (pod template hash)

# Kontrolli Pod'e (automaatselt loodud)
kubectl get pods

# Output:
# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-7d4f8c9b6d-k8s7m   1/1     Running   0          20s
# user-service-7d4f8c9b6d-x2p9r   1/1     Running   0          20s
#              ^^^^^^^^^^^ ReplicaSet hash
#                          ^^^^^ Random string

# Wide output (näitab IP'd ja Node'e)
kubectl get pods -o wide
```

**Mõisted:**
- `READY 2/2`: 2 pod'i 2'st on ready
- `UP-TO-DATE`: Mitu pod'i vastab uusimale template'ile
- `AVAILABLE`: Mitu pod'i on kättesaadav kasutajatele

---

### Samm 3: Testi Self-Healing (10 min)

**Deployment tagab self-healing** - kui pod crashib või kustutatakse, luuakse automaatselt uus.

```bash
# Vaata pod'e
kubectl get pods

# Output:
# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-7d4f8c9b6d-k8s7m   1/1     Running   0          2m
# user-service-7d4f8c9b6d-x2p9r   1/1     Running   0          2m

# Kustuta üks pod (simuleeri crash)
kubectl delete pod user-service-7d4f8c9b6d-k8s7m

# Output:
# pod "user-service-7d4f8c9b6d-k8s7m" deleted

# KOHE kontrolli pod'e (enne kui termination lõppeb)
kubectl get pods

# Output:
# NAME                            READY   STATUS        RESTARTS   AGE
# user-service-7d4f8c9b6d-k8s7m   1/1     Terminating   0          2m
# user-service-7d4f8c9b6d-x2p9r   1/1     Running       0          2m
# user-service-7d4f8c9b6d-abc123  0/1     ContainerCreating   0   1s  ← UUS POD!

# Mõne sekundi pärast
kubectl get pods

# Output:
# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-7d4f8c9b6d-x2p9r   1/1     Running   0          3m
# user-service-7d4f8c9b6d-abc123  1/1     Running   0          30s

# ReplicaSet nägi, et DESIRED=2, aga CURRENT=1, seega lõi automaatselt uue!
```

**Võrdle Pod'iga (Harjutus 1):**

```bash
# Loo Pod otse (ilma Deployment'ita)
kubectl run test-pod --image=nginx:alpine

# Kustuta pod
kubectl delete pod test-pod

# Kontrolli
kubectl get pods

# Output: test-pod on KADUNUD - ei tulnud tagasi!
```

**Self-healing on Deployment'i võtmeomadus!**

---

### Samm 4: Scale Deployment (10 min)

**Scaling** = muuda replicas count'i.

```bash
# Hetkel: 2 pod'i
kubectl get deployments

# Output:
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   2/2     2            2           5m

# Scale üles 4 pod'ile (imperatiivne viis)
kubectl scale deployment user-service --replicas=4

# Output:
# deployment.apps/user-service scaled

# Kontrolli
kubectl get pods

# Output (näitab 4 pod'i):
# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-7d4f8c9b6d-x2p9r   1/1     Running   0          6m
# user-service-7d4f8c9b6d-abc123  1/1     Running   0          3m
# user-service-7d4f8c9b6d-def456  1/1     Running   0          10s  ← UUS
# user-service-7d4f8c9b6d-ghi789  1/1     Running   0          10s  ← UUS

# Scale alla 1 pod'ile
kubectl scale deployment user-service --replicas=1

# Kontrolli
kubectl get pods

# Output (3 pod'i Terminating, 1 jääb):
# NAME                            READY   STATUS        RESTARTS   AGE
# user-service-7d4f8c9b6d-x2p9r   1/1     Running       0          7m
# user-service-7d4f8c9b6d-abc123  1/1     Terminating   0          4m
# user-service-7d4f8c9b6d-def456  1/1     Terminating   0          1m
# user-service-7d4f8c9b6d-ghi789  1/1     Terminating   0          1m
```

**Deklaratiivne scaling (best practice):**

```bash
# Muuda YAML failis
vim user-service-deployment.yaml

# Muuda:
# spec:
#   replicas: 3  # <-- Muuda 2 → 3

# Apply uuesti
kubectl apply -f user-service-deployment.yaml

# Output:
# deployment.apps/user-service configured

# Kontrolli
kubectl get deployments
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   3/3     3            3           10m
```

**Miks deklaratiivne on parem?**
- YAML fail on "source of truth"
- Versioon control (Git)
- Reprodutseerimine (deploy teises cluster'is)

---

### Samm 5: Loo Todo Service Deployment (10 min)

Loo teine Deployment - Todo Service (Java Spring Boot).

**Esmalt: Lae image cluster'isse**

```bash
# Minikube:
eval $(minikube docker-env)
cd ~/labs/apps/backend-java-spring
docker build -t todo-service:1.0-optimized -f Dockerfile.optimized .
cd -

# K3s:
cd ~/labs/apps/backend-java-spring
docker build -t todo-service:1.0-optimized -f Dockerfile.optimized .
docker save todo-service:1.0-optimized -o /tmp/todo-service.tar
sudo k3s ctr images import /tmp/todo-service.tar
cd -
```

**Loo fail `todo-service-deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-service
  labels:
    app: todo-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: todo-service
  template:
    metadata:
      labels:
        app: todo-service
        tier: backend
    spec:
      containers:
      - name: todo-service
        image: todo-service:1.0-optimized
        imagePullPolicy: Never
        ports:
        - containerPort: 8081
          name: http
          protocol: TCP
        env:
        - name: SERVER_PORT
          value: "8081"
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: SPRING_DATASOURCE_URL
          value: "jdbc:postgresql://postgres-todo:5432/todo_service_db"
        - name: SPRING_DATASOURCE_USERNAME
          value: "postgres"
        - name: SPRING_DATASOURCE_PASSWORD
          value: "postgres"  # TEMPORARY - Harjutus 4'is liigume Secrets'i
```

**Deploy:**

```bash
# Apply
kubectl apply -f todo-service-deployment.yaml

# Kontrolli
kubectl get deployments

# Output:
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   3/3     3            3           15m
# todo-service   2/2     2            2           10s

kubectl get pods

# Output (5 pod'i kokku):
# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-7d4f8c9b6d-...     1/1     Running   0          15m
# user-service-7d4f8c9b6d-...     1/1     Running   0          15m
# user-service-7d4f8c9b6d-...     1/1     Running   0          15m
# todo-service-5c6b7d8e9f-...     1/1     Running   0          15s
# todo-service-5c6b7d8e9f-...     1/1     Running   0          15s
```

---

### Samm 6: Rolling Update (Uuenda Image) (10 min)

**Rolling update** = uuenda rakendust ilma downtime'ita.

**Stsenaarium:** Uuendame user-service image versiooni 1.0 → 1.1

**Simulatsioon:** Tag'ime sama image uue versiooniga

```bash
# Minikube:
eval $(minikube docker-env)
docker tag user-service:1.0-optimized user-service:1.1-optimized
eval $(minikube docker-env -u)

# K3s:
docker tag user-service:1.0-optimized user-service:1.1-optimized
docker save user-service:1.1-optimized -o /tmp/user-service-1.1.tar
sudo k3s ctr images import /tmp/user-service-1.1.tar
```

**Uuenda Deployment (imperatiivne):**

```bash
# Set new image
kubectl set image deployment/user-service \
  user-service=user-service:1.1-optimized

# Output:
# deployment.apps/user-service image updated

# Jälgi rolling update progressi
kubectl rollout status deployment/user-service

# Output:
# Waiting for deployment "user-service" rollout to finish: 1 out of 3 new replicas have been updated...
# Waiting for deployment "user-service" rollout to finish: 1 old replicas are pending termination...
# Waiting for deployment "user-service" rollout to finish: 2 old replicas are pending termination...
# deployment "user-service" successfully rolled out

# Vaata pod'e rolling update ajal
kubectl get pods --watch

# Näed:
# user-service-7d4f8c9b6d-xxx (OLD)  1/1  Running
# user-service-7d4f8c9b6d-yyy (OLD)  1/1  Running
# user-service-7d4f8c9b6d-zzz (OLD)  1/1  Running
# user-service-8e5g9d0c7a-aaa (NEW)  0/1  ContainerCreating  <- Loob uue
# user-service-8e5g9d0c7a-aaa (NEW)  1/1  Running
# user-service-7d4f8c9b6d-xxx (OLD)  1/1  Terminating         <- Kustutab vana
# user-service-8e5g9d0c7a-bbb (NEW)  0/1  ContainerCreating
# ...
# (Press Ctrl+C to exit watch)
```

**Rolling Update Strateegia:**

Deployment'is saab määrata update strateegia:

```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate  # Vaikimisi
    rollingUpdate:
      maxUnavailable: 1  # Max 1 pod võib olla down update ajal
      maxSurge: 1        # Max 1 extra pod võib olla update ajal
```

**Tähendus:**
- `maxUnavailable: 1` → Alati vähemalt 2 pod'i (3 - 1) jäävad töötama
- `maxSurge: 1` → Max 4 pod'i (3 + 1) võib ajutiselt eksisteerida
- Update käib **järk-järgult**: loo uus → oota kuni ready → kustuta vana

**Zero-downtime deployment!**

---

### Samm 7: Rollout History ja Rollback (10 min)

Deployment säilitab rollout history.

```bash
# Vaata rollout history't
kubectl rollout history deployment/user-service

# Output:
# deployment.apps/user-service
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         <none>

# Revision 1 = initial deployment (1.0-optimized)
# Revision 2 = updated image (1.1-optimized)

# Vaata konkreetse revision detaile
kubectl rollout history deployment/user-service --revision=2

# Output:
# deployment.apps/user-service with revision #2
# Pod Template:
#   Labels:	app=user-service
#           pod-template-hash=8e5g9d0c7a
#   Containers:
#    user-service:
#     Image:	user-service:1.1-optimized
#     ...
```

**Simulatsioon: Update ebaõnnestus (vale image):**

```bash
# Deploy "broken" image (ei eksisteeri)
kubectl set image deployment/user-service \
  user-service=user-service:broken-version

# Kontrolli rollout
kubectl rollout status deployment/user-service

# Output (jääb timeout'i):
# Waiting for deployment "user-service" rollout to finish: 1 out of 3 new replicas have been updated...
# (Ctrl+C to cancel)

# Vaata pod'e
kubectl get pods

# Output:
# NAME                            READY   STATUS             RESTARTS   AGE
# user-service-8e5g9d0c7a-aaa     1/1     Running            0          5m  (OLD - töötab)
# user-service-8e5g9d0c7a-bbb     1/1     Running            0          5m  (OLD - töötab)
# user-service-9f6h0e1d8b-ccc     0/1     ImagePullBackOff   0          30s (NEW - broken!)

# Deployment ei kustuta vanu pod'e, sest uued ei käivitu (maxUnavailable respekteerib!)
```

**Rollback:**

```bash
# Undo viimane rollout
kubectl rollout undo deployment/user-service

# Output:
# deployment.apps/user-service rolled back

# Kontrolli
kubectl rollout status deployment/user-service
# deployment "user-service" successfully rolled out

kubectl get pods
# NAME                            READY   STATUS    RESTARTS   AGE
# user-service-8e5g9d0c7a-aaa     1/1     Running   0          7m
# user-service-8e5g9d0c7a-bbb     1/1     Running   0          7m
# user-service-8e5g9d0c7a-ddd     1/1     Running   0          10s

# Tagasi versiooni 1.1-optimized!

# Rollback konkreetsele revision'ile
kubectl rollout undo deployment/user-service --to-revision=1

# History
kubectl rollout history deployment/user-service
# REVISION  CHANGE-CAUSE
# 2         <none>
# 3         <none>
# 4         <none>  <- Current (rollback to revision 1)
```

**Parimad tavad:**
- Testi uued image'd staging environment'is enne production'i
- Kasuta image tag'e (mitte `latest`)
- Jälgi rollout'i `kubectl rollout status`
- Hoia history (default: 10 revision'it)

---

### Samm 8: Pause ja Resume Rollout (5 min)

Saad rollout'i pausida (nt. testimiseks).

```bash
# Pause rollout
kubectl rollout pause deployment/user-service

# Tee mitu muudatust (need ei rakendu kohe)
kubectl set image deployment/user-service user-service=user-service:1.2-optimized
kubectl set env deployment/user-service NODE_ENV=production

# Resume rollout (kõik muudatused rakenduvad korraga)
kubectl rollout resume deployment/user-service

# Kontrolli
kubectl rollout status deployment/user-service
```

---

### Samm 9: Vaata ReplicaSet'e (5 min)

**ReplicaSet** on Deployment'i poolt loodud ja hallatud.

```bash
# Vaata ReplicaSet'e
kubectl get replicasets

# Output:
# NAME                      DESIRED   CURRENT   READY   AGE
# user-service-7d4f8c9b6d   0         0         0       30m  (OLD - revision 1)
# user-service-8e5g9d0c7a   3         3         3       20m  (CURRENT - revision 4)
# user-service-9f6h0e1d8b   0         0         0       10m  (OLD - broken revision)

# Describe ReplicaSet
kubectl describe replicaset user-service-8e5g9d0c7a

# Output näitab:
# - Controlled By: Deployment/user-service
# - Replicas: 3 current / 3 desired
# - Pod Template (sama nagu Deployment'is)
# - Events

# ReplicaSet nimi = Deployment nimi + pod template hash
# user-service-8e5g9d0c7a
#              ^^^^^^^^^^
#              Pod template hash (muutub image update'iga)
```

**Miks on vanad ReplicaSet'id (DESIRED=0)?**
- Deployment säilitab vanu ReplicaSet'e rollback jaoks
- Vaikimisi hoiab 10 revision'it
- Ei võta ressursse (pod'id on kusutatud)

```bash
# Cleanup vanad ReplicaSet'id (optional)
kubectl delete replicaset user-service-7d4f8c9b6d
kubectl delete replicaset user-service-9f6h0e1d8b
```

**Tavaliselt EI puutu ReplicaSet'iga otse** - Deployment haldab seda!

---

### Samm 10: Deployment Annotations ja Change-Cause (5 min)

Lisa rollout history'sse kirjeldused.

```bash
# Lisa annotation rollout'ile
kubectl annotate deployment/user-service \
  kubernetes.io/change-cause="Update to version 1.1 with bug fixes"

# Tee update
kubectl set image deployment/user-service \
  user-service=user-service:1.1-optimized

# Vaata history't
kubectl rollout history deployment/user-service

# Output:
# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         <none>
# 5         Update to version 1.1 with bug fixes  <- Annotation nähtav!
```

**Deklaratiivne viis (YAML'is):**

```yaml
metadata:
  name: user-service
  annotations:
    kubernetes.io/change-cause: "Initial deployment v1.0"
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Deployments:**
  - [ ] `user-service` Deployment (replicas: 2-3)
  - [ ] `todo-service` Deployment (replicas: 2)

- [ ] **ReplicaSets:**
  - [ ] Automaatselt loodud igale Deployment'ile
  - [ ] Haldavad pod'e

- [ ] **Pods:**
  - [ ] 4-5 pod'i kokku (user-service + todo-service)
  - [ ] Kõik Running staatuses

- [ ] **Oskused:**
  - [ ] Deploy Deployment manifest'i
  - [ ] Scale Deployment'i
  - [ ] Testi self-healing (delete pod → tuleb tagasi)
  - [ ] Rolling update (image update)
  - [ ] Rollback ebaõnnestunud update'ist
  - [ ] Vaata rollout history't

**Kontrolli:**

```bash
kubectl get deployments
kubectl get replicasets
kubectl get pods
kubectl rollout history deployment/user-service
```

---

## 🐛 Troubleshooting

### Probleem 1: Deployment ei loo pod'e

**Sümptom:**
```bash
kubectl get deployments
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   0/2     0            0           2m

kubectl get pods
# No resources found in default namespace.
```

**Diagnoos:**

```bash
# Describe Deployment
kubectl describe deployment user-service

# Vaata Events:
# Warning  FailedCreate  1m  replicaset-controller  Error creating: ...

# Levinud põhjused:
# - Selector ei match'i pod template labels'iga
# - Image ei eksisteeri
# - Insufficient resources
```

**Lahendus:**

```bash
# Kontrolli selector vs labels match
# spec.selector.matchLabels PEAB olema identne spec.template.metadata.labels'iga

# Õige:
# selector:
#   matchLabels:
#     app: user-service
# template:
#   metadata:
#     labels:
#       app: user-service  ← MATCH!
```

---

### Probleem 2: Rolling Update jääb kinni

**Sümptom:**
```bash
kubectl rollout status deployment/user-service
# Waiting for deployment "user-service" rollout to finish: 1 out of 3 new replicas have been updated...
# (ei lõpeta)
```

**Diagnoos:**

```bash
# Vaata pod'e
kubectl get pods

# Output:
# user-service-xxx (OLD)  1/1  Running
# user-service-yyy (NEW)  0/1  ImagePullBackOff

# Uus pod ei käivitu!

# Describe pod'i
kubectl describe pod user-service-yyy

# Events:
# Failed to pull image "user-service:broken": rpc error: ...
```

**Lahendus:**

```bash
# Rollback
kubectl rollout undo deployment/user-service
```

---

### Probleem 3: Liiga palju ReplicaSet'e

**Sümptom:**
```bash
kubectl get replicasets
# 20+ replicaset'i kõik DESIRED=0
```

**Lahendus:**

```bash
# Seadista revision history limit (vaikimisi 10)
# deployment.yaml:
spec:
  revisionHistoryLimit: 5  # Hoia ainult 5 viimasest revision'i

# Apply
kubectl apply -f deployment.yaml

# Või cleanup käsitsi
kubectl get replicasets | grep "0         0         0" | awk '{print $1}' | xargs kubectl delete replicaset
```

---

## 🎓 Õpitud Mõisted

### Deployment Kontseptsioonid
- **Deployment:** Haldab ReplicaSet'e ja pod'e deklaratiivselt
- **ReplicaSet:** Tagab õige arvu pod'e (desired state)
- **Replicas:** Mitu pod'i koopiat käivitada
- **Self-healing:** Crashed pod'id asendatakse automaatselt
- **Scaling:** Muuda replicas count'i
- **Rolling update:** Järk-järgult uuenda pod'e (zero-downtime)
- **Rollback:** Tagasi eelmise versiooni juurde

### kubectl Deployment Käsud
- `kubectl apply -f deployment.yaml` - Deploy või uuenda
- `kubectl get deployments` - Listi Deployment'e
- `kubectl describe deployment <name>` - Detailne info
- `kubectl scale deployment <name> --replicas=5` - Scale
- `kubectl set image deployment/<name> container=image:tag` - Update image
- `kubectl rollout status deployment/<name>` - Jälgi rollout'i
- `kubectl rollout history deployment/<name>` - Vaata history't
- `kubectl rollout undo deployment/<name>` - Rollback
- `kubectl rollout pause deployment/<name>` - Pause rollout
- `kubectl rollout resume deployment/<name>` - Resume rollout
- `kubectl delete deployment <name>` - Kustuta Deployment (+ pod'id)

### Rolling Update Strateegia
- **type: RollingUpdate** - Järk-järgult (vaikimisi)
- **maxUnavailable** - Max mitu pod'i võib olla down
- **maxSurge** - Max mitu extra pod'i ajutiselt
- **type: Recreate** - Kõik vanad maha → siis uued üles (downtime!)

---

## 💡 Parimad Tavad

### ✅ DO (Tee):
1. **Kasuta Deployment'e, mitte Pod'e** - Self-healing, scaling, updates
2. **Määra replicas: 2+** - High availability (HA)
3. **Kasuta deklaratiivset lähenemist** - YAML failid, mitte imperatiivne
4. **Test updates staging'is** - Enne production'i
5. **Kasuta image tag'e, mitte `latest`** - Reprodutseeritavus
6. **Jälgi rollout'i** - `kubectl rollout status`
7. **Lisa change-cause annotations** - Dokumenteeri muudatusi
8. **Seadista revisionHistoryLimit** - Ära hoia liigselt vanu ReplicaSet'e

### ❌ DON'T (Ära tee):
1. **Ära muuda ReplicaSet'e otse** - Deployment overwrite'ib
2. **Ära kasuta replicas: 1 production'is** - Single point of failure
3. **Ära unusta rolling update strateegiat** - Default võib olla liiga aggressiivne
4. **Ära deploy `latest` tag'iga** - Ei tea, mis versioon töötab

---

## 🔗 Järgmine Samm

Nüüd on meil töötavad Deployment'id:
- `user-service` (2 pod'i)
- `todo-service` (2 pod'i)

**Probleem:** Kuidas pod'id omavahel suhtlevad? Kuidas frontend jõuab backend'ini?

**Pod IP'd muutuvad:**
```bash
kubectl get pods -o wide
# NAME                 IP            NODE
# user-service-xxx     10.244.0.5    minikube
# user-service-yyy     10.244.0.6    minikube

# Kui pod restart'ib → uus IP!
```

**Lahendus:** **Services** - stable DNS name ja load balancing.

**Järgmises harjutuses loome Services'id, et:**
- Frontend leiab user-service → `http://user-service:3000`
- Todo Service leiab user-service → `http://user-service:3000`
- Browser'ist pääseb frontend'i → NodePort

---

**Jätka:** [Harjutus 3: Services & Networking](03-services-networking.md)

---

## 📚 Viited

**Kubernetes Dokumentatsioon:**
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [ReplicaSet](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
- [Rolling Update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [kubectl Rollout Commands](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout)

---

**Õnnitleme! Oled deploy'nud ja hallatud Kubernetes Deployment'e! 🎉**

*Järgmises harjutuses loome Services'id, et pod'id leiaksid üksteist DNS'i kaudu!*
