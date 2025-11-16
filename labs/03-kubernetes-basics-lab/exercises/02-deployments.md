# Harjutus 2: Kubernetes Deployments

**Kestus:** 60 minutit
**Eesmärk:** Õppida Deployment'ide abil rakenduste deploy'mist, scaling'ut ja update'imist

---

## 📋 Ülevaade

Selles harjutuses õpid kasutama **Deployment'e** - production'i standardset viisi rakenduste deploy'miseks Kubernetes'es. Deployment haldab pod'e automaatselt: loob uusi, kustutab vanad, skaleerib ja teeb rolling updates ilma downtime'ita.

**Miks Deployment, mitte Pod?**
- ✅ Automaatne self-healing (pod crashib → luuakse uus)
- ✅ Scaling (lisa või eemalda pod'e)
- ✅ Rolling updates (uuenda rakendust ilma downtime'ita)
- ✅ Rollback (tagasi eelmisele versioonile)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua Deployment manifest'e
- ✅ Deploy'da rakendusi Deployment'idega
- ✅ Skaleerida deployment'e (replicas)
- ✅ Uuendada rakendust (rolling update)
- ✅ Rollback'ida ebaõnnestunud update
- ✅ Mõista ReplicaSet rolli
- ✅ Vaadata deployment'i ajalugu

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────────────────┐
│        Kubernetes Cluster               │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  Deployment: user-service         │  │
│  │  replicas: 3                      │  │
│  └──────────────┬────────────────────┘  │
│                 │                       │
│                 ▼                       │
│  ┌───────────────────────────────────┐  │
│  │  ReplicaSet (auto-created)        │  │
│  │  desired: 3, current: 3           │  │
│  └──────────────┬────────────────────┘  │
│                 │                       │
│         ┌───────┼───────┐               │
│         ▼       ▼       ▼               │
│      ┌────┐  ┌────┐  ┌────┐             │
│      │Pod │  │Pod │  │Pod │             │
│      │ 1  │  │ 2  │  │ 3  │             │
│      └────┘  └────┘  └────┘             │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Loo Esimene Deployment (15 min)

Loo fail `user-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  labels:
    app: user-service
spec:
  # Soovitud pod'ide arv
  replicas: 2

  # Selector, mis ühendab Deployment'i pod'idega
  selector:
    matchLabels:
      app: user-service

  # Pod template
  template:
    metadata:
      labels:
        app: user-service
        version: "1.0"
    spec:
      containers:
      - name: user-service
        image: user-service:1.0
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: PORT
          value: "3000"
        - name: NODE_ENV
          value: "production"
        - name: DB_HOST
          value: "postgres"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "user_service_db"
        - name: DB_USER
          value: "postgres"
        - name: DB_PASSWORD
          value: "postgres"
        - name: JWT_SECRET
          value: "temporary-secret-key"

        # Resource limits (best practice)
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
```

**Manifest selgitus:**

- **replicas:** Mitu pod'i soovid (skaleerumine)
- **selector.matchLabels:** Kuidas Deployment leiab oma pod'e
- **template:** Pod'i definitsioon (sama mis Harjutus 1)
- **resources:**
  - `requests`: Minimaalsed ressursid (scheduling otsus)
  - `limits`: Maksimaalsed ressursid (ei tohi ületada)

**Deploy:**

```bash
# Esmalt veendu, et image on olemas (Minikube)
eval $(minikube docker-env)
cd ../../apps/backend-nodejs
docker build -t user-service:1.0 .
cd ../../03-kubernetes-basics-lab/exercises
eval $(minikube docker-env -u)

# Deploy Deployment
kubectl apply -f user-deployment.yaml

# Kontrolli
kubectl get deployments

# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   2/2     2            2           10s

kubectl get pods

# NAME                          READY   STATUS    RESTARTS   AGE
# user-service-xxxxxxxxx-xxxxx  1/1     Running   0          10s
# user-service-xxxxxxxxx-yyyyy  1/1     Running   0          10s

# Vaata ReplicaSet'i (auto-loodud)
kubectl get replicasets

# NAME                     DESIRED   CURRENT   READY   AGE
# user-service-xxxxxxxxx   2         2         2       20s
```

**Mida Deployment tegi?**
1. Lõi ReplicaSet'i
2. ReplicaSet lõi 2 pod'i
3. Jälgib, et alati 2 pod'i töötaks

---

### Samm 2: Testi Self-Healing (5 min)

Deployment taastab automaatselt pod'i, kui see crashib.

```bash
# Listi pod'e
kubectl get pods

# Kustuta üks pod
kubectl delete pod user-service-xxxxxxxxx-xxxxx

# Kohe uuesti listi
kubectl get pods

# Näed, et:
# 1. Üks pod on Terminating
# 2. Uus pod on juba ContainerCreating või Running
# Deployment lõi automaatselt asenduse!

# Pärast mõnda sekundit on jälle 2/2 READY
kubectl get deployments
```

**See on self-healing** - Deployment tagab alati soovitud arvu pod'e.

---

### Samm 3: Scale Deployment (10 min)

**Variant A: kubectl scale käsk**

```bash
# Scale 2 → 5 pod'i
kubectl scale deployment user-service --replicas=5

# Kontrolli
kubectl get deployments
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   5/5     5            5           2m

kubectl get pods
# Peaks olema 5 user-service pod'i
```

**Variant B: Muuda YAML'i**

```bash
# Muuda user-deployment.yaml
# replicas: 2 → replicas: 3

# Apply uuesti
kubectl apply -f user-deployment.yaml

# Kontrolli
kubectl get deployments
# user-service   3/3     3            3           3m
```

**Scale down:**

```bash
# Vähenda tagasi 2-le
kubectl scale deployment user-service --replicas=2

# Vaata, kuidas pod'e kustutatakse
kubectl get pods --watch

# Ctrl+C väljumiseks
```

**Miks scaling toimib?**
Deployment muudab ReplicaSet'i `desired` välja → ReplicaSet loob või kustutab pod'e.

---

### Samm 4: Rolling Update (15 min)

**Rolling update** = uuenda rakendust ilma downtime'ita (pod'e uuendatakse järjest).

**Simuleerime uuendust:**

```bash
# Build uus versioon
cd ../../apps/backend-nodejs

# Muuda midagi (nt lisa server.js-i)
echo "console.log('Version 1.1');" >> server.js

# Build uus image
eval $(minikube docker-env)
docker build -t user-service:1.1 .
eval $(minikube docker-env -u)

cd ../../03-kubernetes-basics-lab/exercises
```

**Uuenda Deployment'i:**

**Variant A: Set image käsk**

```bash
kubectl set image deployment/user-service user-service=user-service:1.1

# Vaata rolling update'i reaalajas
kubectl rollout status deployment/user-service

# Peaks näitama:
# Waiting for deployment "user-service" rollout to finish: 1 out of 2 new replicas have been updated...
# Waiting for deployment "user-service" rollout to finish: 1 old replicas are pending termination...
# deployment "user-service" successfully rolled out

kubectl get pods --watch
# Näed, kuidas vanad pod'id termineeritakse ja uued luuakse
```

**Variant B: Muuda YAML'i**

```yaml
# user-deployment.yaml
spec:
  template:
    spec:
      containers:
      - name: user-service
        image: user-service:1.1  # 1.0 → 1.1
```

```bash
kubectl apply -f user-deployment.yaml
kubectl rollout status deployment/user-service
```

**Kontrolli uuendust:**

```bash
# Vaata deployment'i image versiooni
kubectl describe deployment user-service | grep Image

# Peaks näitama:
# Image: user-service:1.1

# Vaata uue pod'i logisid
kubectl logs deployment/user-service

# Peaks näitama:
# Version 1.1
```

---

### Samm 5: Rollback (10 min)

Kui update läks valesti, rollback'i eelmisele versioonile.

**Vaata ajalugu:**

```bash
kubectl rollout history deployment/user-service

# REVISION  CHANGE-CAUSE
# 1         <none>
# 2         <none>
```

**Lisa change-cause annotation (järgmiseks korraks):**

```bash
kubectl annotate deployment/user-service kubernetes.io/change-cause="Update to version 1.1"
```

**Rollback viimasele versioonile:**

```bash
kubectl rollout undo deployment/user-service

# Vaata rollback'i
kubectl rollout status deployment/user-service

# Kontrolli image versiooni
kubectl describe deployment user-service | grep Image
# Peaks näitama:
# Image: user-service:1.0
```

**Rollback konkreetsele revision'ile:**

```bash
# Vaata history
kubectl rollout history deployment/user-service

# Rollback revision 1-le
kubectl rollout undo deployment/user-service --to-revision=1
```

**Miks rollback toimib?**
Deployment säilitab vanad ReplicaSet'id (aga 0 replicas). Rollback muudab vana ReplicaSet'i aktiivseks.

```bash
# Vaata ReplicaSet'e
kubectl get replicasets

# Näed mitut ReplicaSet'i:
# user-service-xxxxxxxxx   2   2   2   5m  (current)
# user-service-yyyyyyyyy   0   0   0   10m (old)
```

---

### Samm 6: Update Strateegia (5 min)

Deployment'il on 2 update strateegiat:

**1. RollingUpdate (default):**
Uuendab pod'e järjest ilma downtime'ita.

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max +1 pod ajutiselt (näit 2→3→2)
      maxUnavailable: 0  # Min 0 pod'i unavailable (alati toimiv)
```

**2. Recreate:**
Kustutab kõik vanad pod'id enne uute loomist (downtime!).

```yaml
spec:
  strategy:
    type: Recreate
```

**Testi RollingUpdate parameetreid:**

```yaml
# user-deployment.yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Võib ajutiselt olla 4 pod'i (3 +1)
      maxUnavailable: 1  # Võib olla 1 pod unavailable (miinimum 2)
```

```bash
kubectl apply -f user-deployment.yaml

# Uuenda rakendust ja vaata, kuidas pod'id asendatakse
kubectl set image deployment/user-service user-service=user-service:1.1
kubectl get pods --watch
```

---

### Samm 7: Pause ja Resume (5 min)

Võid "pausida" deployment'i, et teha mitu muudatust korraga.

```bash
# Pause deployment (ei tee rolling update'i)
kubectl rollout pause deployment/user-service

# Tee mitu muudatust
kubectl set image deployment/user-service user-service=user-service:1.2
kubectl set resources deployment/user-service -c=user-service --limits=cpu=200m,memory=512Mi

# Pod'id ei uuene veel!

# Resume (alles nüüd toimub rolling update)
kubectl rollout resume deployment/user-service

# Vaata rollout'i
kubectl rollout status deployment/user-service
```

---

### Samm 8: Deployment Detailid (5 min)

```bash
# Vaata Deployment'i detaile
kubectl describe deployment user-service

# Tähtis info:
# - Replicas: 2 desired, 2 updated, 2 available
# - StrategyType: RollingUpdate
# - Pod Template (containers, env, resources)
# - Events (scaling, updates)

# Vaata Deployment YAML'i
kubectl get deployment user-service -o yaml

# Vaata ainult image
kubectl get deployment user-service -o jsonpath='{.spec.template.spec.containers[0].image}'

# Export manifest
kubectl get deployment user-service -o yaml > exported-deployment.yaml
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **Deployment loomine:**
  - [ ] YAML manifest
  - [ ] `kubectl apply -f deployment.yaml`

- [ ] **Deployment haldamine:**
  - [ ] `kubectl get deployments`
  - [ ] `kubectl describe deployment`
  - [ ] `kubectl scale`

- [ ] **Rolling update:**
  - [ ] `kubectl set image`
  - [ ] `kubectl rollout status`
  - [ ] Vaadata update'i reaalajas

- [ ] **Rollback:**
  - [ ] `kubectl rollout undo`
  - [ ] `kubectl rollout history`
  - [ ] Rollback konkreetsele revision'ile

- [ ] **Self-healing:**
  - [ ] Mõista, et pod'i kustutamine loob uue

- [ ] **Scaling:**
  - [ ] Scale up/down kubectl'iga
  - [ ] Muuta replicas YAML'is

---

## 🐛 Troubleshooting

### Probleem 1: Deployment stuck "0/3 replicas"

**Sümptom:**
```bash
kubectl get deployments
# NAME           READY   UP-TO-DATE   AVAILABLE   AGE
# user-service   0/3     3            0           5m
```

**Diagnoos:**

```bash
kubectl describe deployment user-service
# Vaata Events

kubectl get pods
# Vaata pod'ide state'e

# Võimalikud põhjused:
# - ImagePullBackOff (image puudub)
# - CrashLoopBackOff (rakendus crashib)
# - Insufficient resources (ei jätku CPU/RAM)
```

---

### Probleem 2: Rolling update ei lõpe kunagi

**Sümptom:**
```bash
kubectl rollout status deployment/user-service
# Waiting for deployment "user-service" rollout to finish: 1 out of 2 new replicas have been updated...
# (jääb kinni)
```

**Diagnoos:**

```bash
kubectl describe deployment user-service

# Vaata:
# - Kas uued pod'id saavad READY? (readiness probe võib failida)
# - Events sektsioon
```

**Lahendus:**

```bash
# Rollback
kubectl rollout undo deployment/user-service

# Või kustuta Deployment ja loo uuesti
kubectl delete deployment user-service
kubectl apply -f user-deployment.yaml
```

---

### Probleem 3: Liiga palju ReplicaSets

**Sümptom:**
```bash
kubectl get replicasets
# 10+ ReplicaSet'i (iga update loob uue)
```

**Lahendus:**

Seadista revision history limit:

```yaml
spec:
  revisionHistoryLimit: 3  # Säilita ainult 3 viimasest ReplicaSet'i
```

```bash
kubectl apply -f user-deployment.yaml

# Vanad ReplicaSet'id kustutatakse automaatselt
```

---

## 🎓 Õpitud Mõisted

### Deployment:
- **Deployment:** Haldab ReplicaSet'e ja pod'e deklaratiivselt
- **ReplicaSet:** Tagab soovitud arvu pod'e (auto-loodud Deployment'iga)
- **Pod Template:** Pod'i definitsioon Deployment'i sees
- **Replicas:** Soovitud pod'ide arv

### Deployment lifecycle:
- **Rolling Update:** Järjest pod'ide asendamine (zero downtime)
- **Recreate:** Kõik pod'id kustutakse ja luuakse uuesti (downtime)
- **Rollback:** Tagasi eelmisele versioonile
- **Pause/Resume:** Ajutiselt peatada update

### kubectl käsud:
- `kubectl apply -f deployment.yaml` - Deploy või update
- `kubectl get deployments` - Listi deployment'e
- `kubectl scale` - Muuda replicas
- `kubectl set image` - Uuenda image
- `kubectl rollout status` - Vaata rollout'i progressi
- `kubectl rollout undo` - Rollback
- `kubectl rollout history` - Vaata ajalugu
- `kubectl rollout pause/resume` - Pause/Resume update

---

## 💡 Parimad Tavad

1. **Alati kasuta Deployment'e, mitte pod'e otse** - Production'is
2. **Määra resource requests ja limits** - Vältimaks resource starvation
3. **Kasuta RollingUpdate strateegiat** - Zero downtime
4. **Lisa readiness/liveness probes** - Health check'id (õpime hiljem)
5. **Säilita mõistlik revision history** - `revisionHistoryLimit: 3-5`
6. **Annota muudatusi** - `kubectl annotate ... kubernetes.io/change-cause="..."`
7. **Testi update't staging'us enne prod'i** - Rollback on hea, aga mitte pidev lahendus

---

## 🔗 Järgmine Samm

Nüüd oskad deploy'da ja skaleerida rakendusi Deployment'idega! Aga kuidas teised pod'id või välised kasutajad saavad sinu rakendusele ligi?

Järgmises harjutuses õpid **Services** - kuidas avaldada deployment'e network'is!

**Jätka:** [Harjutus 3: Services](03-services.md)

---

## 📚 Viited

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [kubectl Rollout Commands](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout)

---

**Õnnitleme! Oskad nüüd hallata Deployment'e nagu DevOps pro! 🚀**
