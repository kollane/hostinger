# Harjutus 1: Kubernetes Pods

**Kestus:** 60 minutit
**Eesmärk:** Õppida Kubernetes Pod'ide loomist, haldamist ja debuggimist

---

## 📋 Ülevaade

Selles harjutuses tutvud Kubernetes põhikomponendiga - **Pod**. Õpid looma pod'e, jälgima nende seisundit ja lahendama levinud probleeme.

**Pod** on Kubernetes'e väikseim deployable üksus - üks või mitu konteinerit, mis jagavad samad ressursid (network, storage).

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Käivitada Kubernetes clusterit (Minikube/K3s)
- ✅ Luua Pod manifest'e (YAML)
- ✅ Deploy'da pod'e kubectl'iga
- ✅ Vaadata pod'ide staatust ja logisid
- ✅ Debuggida pod'i probleeme
- ✅ Sisestada containerisse exec käskudega
- ✅ Kustutada pod'e

---

## 🏗️ Arhitektuur

```
┌────────────────────────────────┐
│   Kubernetes Cluster           │
│                                │
│  ┌──────────────────────────┐  │
│  │     Namespace: default   │  │
│  │                          │  │
│  │  ┌────────────────────┐  │  │
│  │  │   Pod: user-pod    │  │  │
│  │  │                    │  │  │
│  │  │  Container:        │  │  │
│  │  │  user-service:1.0  │  │  │
│  │  │  Port: 3000        │  │  │
│  │  └────────────────────┘  │  │
│  │                          │  │
│  └──────────────────────────┘  │
│                                │
└────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Käivita Kubernetes Cluster (10 min)

**Variant A: Minikube (Soovitatud algajatele)**

```bash
# Paigalda Minikube (kui pole veel)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Käivita cluster
minikube start --cpus=2 --memory=4096

# Kontrolli cluster'i
kubectl cluster-info
kubectl get nodes

# Peaks näitama:
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   1m    v1.28.x
```

**Variant B: K3s (Kerge, tootmislähedane)**

```bash
# Paigalda K3s
curl -sfL https://get.k3s.io | sh -

# Kontrolli
sudo kubectl get nodes
# või
k3s kubectl get nodes

# Seadista kubectl ilma sudo'ta
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

kubectl get nodes
```

**Kontrolli kubectl'i:**
```bash
kubectl version --client
kubectl config current-context

# Peaks näitama:
# minikube või default (K3s)
```

---

### Samm 2: Loo Esimene Pod imperatiivselt (10 min)

Kõige lihtsam viis pod'i loomiseks:

```bash
# Loo Pod nginx image'iga
kubectl run nginx-pod --image=nginx:alpine

# Kontrolli pod'i
kubectl get pods

# Peaks näitama:
# NAME        READY   STATUS    RESTARTS   AGE
# nginx-pod   1/1     Running   0          10s

# Detailne info
kubectl describe pod nginx-pod

# Vaata logisid
kubectl logs nginx-pod

# Sisene pod'i
kubectl exec -it nginx-pod -- sh

# Pod sees:
ls -la
cat /etc/nginx/nginx.conf
exit

# Kustuta pod
kubectl delete pod nginx-pod
```

**Mõisted:**
- `kubectl run` - loob pod'i imperatiivselt (käsurea kaudu)
- `--image` - määrab Docker image
- `get pods` - näitab pod'ide listi
- `describe pod` - detailne info
- `logs` - container'i stdout/stderr
- `exec -it` - sisene töötavasse containerisse

---

### Samm 3: Loo Pod YAML Manifest'iga (15 min)

**Deklaratiivne lähenemine (best practice):**

Loo fail `user-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: user-pod
  labels:
    app: user-service
    version: "1.0"
spec:
  containers:
  - name: user-service
    image: user-service:1.0
    imagePullPolicy: Never  # Kasuta local image'i (Minikube)
    ports:
    - containerPort: 3000
      name: http
    env:
    - name: PORT
      value: "3000"
    - name: NODE_ENV
      value: "production"
    - name: DB_HOST
      value: "postgres"  # Hiljem loome
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
```

**Manifest struktuuri selgitus:**

- **apiVersion:** Kubernetes API versioon (v1 = core API)
- **kind:** Ressursi tüüp (Pod, Deployment, Service, jne)
- **metadata:**
  - `name`: Pod'i nimi (unikaalne namespace'is)
  - `labels`: Key-value paarid (kasutatakse selector'ites)
- **spec:**
  - `containers`: Array containerite definitsioonidest
    - `name`: Container'i nimi pod'i sees
    - `image`: Docker image
    - `imagePullPolicy`: `Never` = ära pull Docker Hub'ist, kasuta local
    - `ports`: Avaldatavad pordid
    - `env`: Environment variables

**Deploy pod:**

```bash
# Esmalt - lae image Minikube'i (kui kasutad Minikube)
eval $(minikube docker-env)
cd ../../apps/backend-nodejs
docker build -t user-service:1.0 .
cd ../../03-kubernetes-basics-lab/exercises

# Tagasi normaalsesse env'i
eval $(minikube docker-env -u)

# Nüüd deploy pod
kubectl apply -f user-pod.yaml

# Kontrolli
kubectl get pods
# NAME       READY   STATUS    RESTARTS   AGE
# user-pod   1/1     Running   0          5s
```

**Kontrolli pod'i detaile:**

```bash
# Vaata pod infot
kubectl describe pod user-pod

# Tähtis info:
# - Status: Running
# - IP: 172.17.0.x (cluster internal IP)
# - Events: Image pulled, Container created, Started

# Vaata YAML'i, mida Kubernetes lõi
kubectl get pod user-pod -o yaml

# Vaata logisid
kubectl logs user-pod

# Peaks näitama:
# Server running on port 3000
# (aga DB connection ebaõnnestub, sest PostgreSQL puudub)
```

---

### Samm 4: Debuggi Pod'i (10 min)

Pod ei käivitu või crashib? Siin on debug workflow:

**1. Kontrolli pod'i statusit:**

```bash
kubectl get pods

# Võimalikud STATE'id:
# - Pending: Planeeritakse node'le
# - ContainerCreating: Image pullimine
# - Running: Töötab
# - CrashLoopBackOff: Crashib kogu aeg
# - Error: Viga
# - Completed: Lõpetatud (job)
```

**2. Describe pod'i:**

```bash
kubectl describe pod user-pod

# Vaata:
# - Events sektsioon (lõpus)
# - Container state
# - Restart count
```

**3. Vaata logisid:**

```bash
# Current container logs
kubectl logs user-pod

# Previous container logs (kui crashis)
kubectl logs user-pod --previous

# Follow logs real-time
kubectl logs -f user-pod
```

**4. Sisene pod'i:**

```bash
# Sisene containerisse
kubectl exec -it user-pod -- sh

# Pod sees:
env | grep DB
ls -la /app
cat package.json
ps aux
exit
```

**5. Port forward testimiseks:**

```bash
# Mapped local port 8080 → pod port 3000
kubectl port-forward pod/user-pod 8080:3000

# Teises terminalis:
curl http://localhost:8080/health

# Oodatud vastus:
# {
#   "status": "ERROR",
#   "database": "disconnected",
#   "message": "Database connection failed"
# }
# (See on OK - PostgreSQL pole veel deploy'tud!)
```

---

### Samm 5: Tööta Labels ja Annotations'iga (5 min)

**Labels** = key-value paarid selector'ite jaoks
**Annotations** = metadata info (ei kasutata selector'ites)

```bash
# Vaata pod'i label'eid
kubectl get pod user-pod --show-labels

# Peaks näitama:
# NAME       READY   STATUS    RESTARTS   AGE   LABELS
# user-pod   1/1     Running   0          10m   app=user-service,version=1.0

# Filter pod'e label'i järgi
kubectl get pods -l app=user-service
kubectl get pods -l version=1.0

# Lisa uus label
kubectl label pod user-pod environment=dev

# Uuenda label'it
kubectl label pod user-pod version=1.1 --overwrite

# Kustuta label
kubectl label pod user-pod version-

# Lisa annotation
kubectl annotate pod user-pod description="User service API pod"

# Vaata annotation'e
kubectl describe pod user-pod | grep Annotations
```

---

### Samm 6: Multi-Container Pod (10 min)

Pod võib sisaldada mitut konteinerit (sidecar pattern).

Loo fail `multi-container-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
spec:
  containers:
  # Peamine container
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx

  # Sidecar container - logide lugemine
  - name: log-reader
    image: busybox
    command: ["sh", "-c", "tail -f /logs/access.log"]
    volumeMounts:
    - name: shared-logs
      mountPath: /logs

  # Shared volume
  volumes:
  - name: shared-logs
    emptyDir: {}
```

**Deploy ja testi:**

```bash
kubectl apply -f multi-container-pod.yaml

# Kontrolli - peaks olema 2/2 containers READY
kubectl get pods

# NAME                  READY   STATUS    RESTARTS   AGE
# multi-container-pod   2/2     Running   0          10s

# Vaata nginx container'i logisid
kubectl logs multi-container-pod -c nginx

# Vaata log-reader container'i logisid
kubectl logs multi-container-pod -c log-reader

# Sisene konkreetsesse containerisse
kubectl exec -it multi-container-pod -c nginx -- sh

# Kustuta
kubectl delete pod multi-container-pod
```

---

### Samm 7: Kustuta Pod'e (5 min)

```bash
# Kustuta üks pod
kubectl delete pod user-pod

# Kustuta manifest'i järgi
kubectl delete -f user-pod.yaml

# Kustuta kõik pod'id label'i järgi
kubectl delete pods -l app=user-service

# Force delete (kui stuck)
kubectl delete pod user-pod --force --grace-period=0

# Kustuta kõik pod'id namespace'is (ETTEVAATUST!)
kubectl delete pods --all
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **Kubernetes cluster:**
  - [ ] Minikube või K3s käivitatud
  - [ ] kubectl toimib

- [ ] **Pod loomine:**
  - [ ] Imperatiivselt (`kubectl run`)
  - [ ] Deklaratiivselt (YAML manifest)

- [ ] **Pod haldamine:**
  - [ ] `kubectl get pods` - listi vaatamine
  - [ ] `kubectl describe pod` - detailne info
  - [ ] `kubectl logs` - logide vaatamine
  - [ ] `kubectl exec` - containerisse sisenemine

- [ ] **Debug:**
  - [ ] Pod'i state'ide tundmine
  - [ ] Events'ide lugemine
  - [ ] Port forwarding

- [ ] **Labels:**
  - [ ] Label'ite lisamine ja kustutamine
  - [ ] Label selector'ite kasutamine

---

## 🐛 Troubleshooting

### Probleem 1: ImagePullBackOff

**Sümptom:**
```bash
kubectl get pods
# NAME       READY   STATUS             RESTARTS   AGE
# user-pod   0/1     ImagePullBackOff   0          1m
```

**Põhjused:**
1. Image ei eksisteeri Docker Hub'is
2. Image on local, aga `imagePullPolicy` on vale

**Lahendus:**

```bash
# Minikube: kasuta local image'e
eval $(minikube docker-env)
docker images | grep user-service  # Kontrolli, kas image olemas
docker build -t user-service:1.0 .

# Pod YAML'is pane:
imagePullPolicy: Never  # või IfNotPresent

# K3s: import image
docker save user-service:1.0 > user-service.tar
sudo k3s ctr images import user-service.tar
```

---

### Probleem 2: CrashLoopBackOff

**Sümptom:**
```bash
kubectl get pods
# NAME       READY   STATUS             RESTARTS   AGE
# user-pod   0/1     CrashLoopBackOff   5          5m
```

**Diagnoos:**

```bash
# Vaata logisid
kubectl logs user-pod
kubectl logs user-pod --previous

# Vaata events
kubectl describe pod user-pod

# Levinud põhjused:
# - Rakendus crashib (viga koodis)
# - Puudub dependency (DB, config)
# - Vale environment variable
# - Port juba kasutusel
```

**Lahendus:**
Paranda pod YAML'i (environment variables, dependencies) ja apply uuesti.

---

### Probleem 3: Pod ei käivitu (Pending)

**Sümptom:**
```bash
kubectl get pods
# NAME       READY   STATUS    RESTARTS   AGE
# user-pod   0/1     Pending   0          5m
```

**Diagnoos:**

```bash
kubectl describe pod user-pod

# Vaata Events:
# - Insufficient CPU/memory
# - No nodes available
```

**Lahendus:**

```bash
# Kontrolli node'ide ressursse
kubectl top nodes

# Vähenda pod'i resource requests
```

---

## 🎓 Õpitud Mõisted

### Pod kontseptsioonid:
- **Pod**: Väikseim deployable üksus Kubernetes'es
- **Container**: Docker container pod'i sees
- **Multi-container Pod**: Mitu konteinerit samas pod'is (sidecar pattern)
- **Shared volumes**: Kõik pod'i containerid jagavad samu volume'id
- **Shared network**: Kõik pod'i containerid jagavad sama IP'd

### kubectl käsud:
- `kubectl run` - Loo pod imperatiivselt
- `kubectl apply -f` - Deploy manifest
- `kubectl get pods` - Listi pod'e
- `kubectl describe pod` - Detailne info
- `kubectl logs` - Container logid
- `kubectl exec` - Käivita käsk pod'i container'is
- `kubectl port-forward` - Map local port pod'i porti
- `kubectl delete pod` - Kustuta pod

### Pod lifecycle:
1. **Pending**: Planeeritakse node'le
2. **ContainerCreating**: Image pullimine + container loomine
3. **Running**: Kõik containerid töötavad
4. **Succeeded**: Container'id lõpetasid edukalt (job)
5. **Failed**: Container crashis
6. **Unknown**: Tundmatu state

---

## 💡 Parimad Tavad

1. **Kasuta alati YAML manifeste** - Deklaratiivne on parem kui imperatiivne
2. **Lisa labels** - Hõlbustab selector'ite kasutamist hiljem
3. **Määra imagePullPolicy** - `Never` local dev'is, `Always` prod'is
4. **Lisa resource limits** - Vältimaks kogu cluster'i ressursside ammendamist
5. **Ära deploy pod'e otse** - Kasuta Deployment'e (harjutus 2)
6. **Kasuta readiness/liveness probes** - Health check'id (õpime hiljem)

---

## 🔗 Järgmine Samm

Pod'id on väga head mõistmaks Kubernetes põhimõtteid, aga **production'is ei deploy'ta pod'e otse**. Kasutatakse **Deployment'e**, mis haldavad pod'e automaatselt (scaling, rolling updates, self-healing).

Järgmises harjutuses õpid Deployment'e!

**Jätka:** [Harjutus 2: Deployments](02-deployments.md)

---

## 📚 Viited

- [Kubernetes Pods](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

---

**Õnnitleme! Oled loonud oma esimesed Kubernetes Pod'id! 🎉**
