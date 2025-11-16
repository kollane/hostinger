# Harjutus 5: Persistent Volumes

**Kestus:** 60 minutit
**Eesmärk:** Õppida andmete püsivat salvestamist Kubernetes'es

---

## 📋 Ülevaade

Selles harjutuses õpid kasutama **Persistent Volumes (PV)** ja **Persistent Volume Claims (PVC)** - Kubernetes ressursse, mis võimaldavad andmete säilitamist pod'ide ja restart'ide vahel.

**Probleem:** Container file system on ephemeral (kaob pod restart'imisel)
**Lahendus:** Persistent Volumes - püsiv storage, mis elab pod'ist kauem

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Mõista PV vs PVC erinevust
- ✅ Luua PersistentVolume (PV)
- ✅ Luua PersistentVolumeClaim (PVC)
- ✅ Mount'ida PVC pod'ile
- ✅ Testida andmete persistence
- ✅ Kasutada StorageClass'e
- ✅ Deploy'da StatefulSet PostgreSQL'iga
- ✅ Mõista volume lifecycle

---

## 🏗️ Arhitektuur

```
┌──────────────────────────────────────────────────┐
│         Kubernetes Cluster                       │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │  StatefulSet: postgres                     │  │
│  └────────────────┬───────────────────────────┘  │
│                   │                              │
│                   ▼                              │
│           ┌───────────────┐                      │
│           │  Pod: postgres│                      │
│           │               │                      │
│           │  ┌─────────┐  │                      │
│           │  │container│  │                      │
│           │  │/var/lib/│  │                      │
│           │  │postgres │  │                      │
│           │  └────┬────┘  │                      │
│           └───────┼───────┘                      │
│                   │ volumeMount                  │
│                   ▼                              │
│  ┌────────────────────────────────────────────┐  │
│  │  PersistentVolumeClaim: postgres-pvc       │  │
│  │  Request: 10Gi                             │  │
│  └────────────────┬───────────────────────────┘  │
│                   │ Bound                        │
│                   ▼                              │
│  ┌────────────────────────────────────────────┐  │
│  │  PersistentVolume: postgres-pv             │  │
│  │  Capacity: 10Gi                            │  │
│  │  hostPath: /mnt/data                       │  │
│  └────────────────┬───────────────────────────┘  │
│                   │                              │
│                   ▼                              │
│        Host Machine Disk (/mnt/data)             │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## 📝 Sammud

### Samm 1: Mõista PV vs PVC (5 min)

**PersistentVolume (PV):**
- Cluster admin loob (storage resource)
- Täpsustab storage tüüp (hostPath, NFS, cloud disk)
- Capacity, access modes

**PersistentVolumeClaim (PVC):**
- Developer loob (storage request)
- Küsib teatud suurust ja access mode'i
- Kubernetes "bind'ib" PVC → PV

**Analoogia:**
- PV = server (resource)
- PVC = request (tarbimine)

---

### Samm 2: Loo PersistentVolume (10 min)

Loo fail `postgres-pv.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
spec:
  capacity:
    storage: 10Gi  # Suurus

  accessModes:
    - ReadWriteOnce  # RWO = üks node korraga (read+write)

  persistentVolumeReclaimPolicy: Retain  # Säilita andmed PVC kustutamisel

  storageClassName: manual  # Storage class (matching PVC'ga)

  hostPath:
    path: /mnt/data  # Host machine path (Minikube/K3s)
    type: DirectoryOrCreate  # Loo directory, kui ei eksisteeri
```

**Access Modes selgitus:**
- **ReadWriteOnce (RWO):** Üks node, read+write (kõige levinum)
- **ReadOnlyMany (ROX):** Mitu node't, ainult read
- **ReadWriteMany (RWX):** Mitu node't, read+write (NFS, cloud FS)

**Reclaim Policy:**
- **Retain:** Säilita andmed peale PVC kustutamist (manual cleanup)
- **Delete:** Kustuta PV ja andmed (automaatne, ohtlik!)
- **Recycle:** Kustutatakse failid (deprecated)

**Deploy:**

```bash
kubectl apply -f postgres-pv.yaml

# Kontrolli
kubectl get pv

# NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
# postgres-pv   10Gi       RWO            Retain           Available           manual                  5s

# STATUS: Available = vaba (pole bound PVC'ga)
```

---

### Samm 3: Loo PersistentVolumeClaim (10 min)

Loo fail `postgres-pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce  # Peab matchima PV access mode'ga

  resources:
    requests:
      storage: 10Gi  # Peab olema <= PV capacity

  storageClassName: manual  # Peab matchima PV storage class'iga
```

**Deploy:**

```bash
kubectl apply -f postgres-pvc.yaml

# Kontrolli
kubectl get pvc

# NAME           STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# postgres-pvc   Bound    postgres-pv   10Gi       RWO            manual         5s

# STATUS: Bound = ühendatud PV'ga

# Kontrolli PV uuesti
kubectl get pv

# NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   AGE
# postgres-pv   10Gi       RWO            Retain           Bound    default/postgres-pvc   manual         2m

# STATUS: Bound
# CLAIM: default/postgres-pvc (millise PVC'ga bound)
```

**Binding protsess:**
1. PVC loomisel Kubernetes otsib sobivat PV'd
2. Tingimused: storage class, access mode, capacity
3. Kui leitakse match → Binding
4. Kui ei leita → PVC jääb Pending

---

### Samm 4: Mount PVC Pod'ile (15 min)

Loo fail `postgres-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1  # PostgreSQL peaks olema 1 (RWO)
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          value: "postgres"
        - name: POSTGRES_DB
          value: "user_service_db"

        # Mount PVC
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data  # PostgreSQL data directory
          subPath: postgres  # Subpath (vältimaks permission issue)

      # Define volume
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc  # Viide PVC-le
```

**subPath selgitus:**
PostgreSQL vajab tühja kausta. `subPath: postgres` loob `/var/lib/postgresql/data/postgres` subkausta.

**Deploy:**

```bash
kubectl apply -f postgres-deployment.yaml

# Kontrolli
kubectl get pods

# NAME                       READY   STATUS    RESTARTS   AGE
# postgres-xxxxxxxxxx-xxxxx  1/1     Running   0          10s

# Vaata logisid
kubectl logs deployment/postgres

# Peaks näitama:
# PostgreSQL init process complete; ready for start up
```

---

### Samm 5: Testi Andmete Persistence (10 min)

**Lisa andmeid PostgreSQL'i:**

```bash
# Sisene postgres pod'i
kubectl exec -it deployment/postgres -- psql -U postgres -d user_service_db

# Psql shell'is:
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    message VARCHAR(100)
);

INSERT INTO test_table (message) VALUES ('Persistence test');

SELECT * FROM test_table;

# Peaks näitama:
#  id |     message
# ----+-----------------
#   1 | Persistence test

\q  # Välju psql
```

**Restart pod (kustuta):**

```bash
# Kustuta pod (Deployment loob uue)
kubectl delete pod -l app=postgres

# Oota uut pod'i
kubectl get pods -w

# Ctrl+C väljumiseks
```

**Kontrolli andmeid:**

```bash
# Sisene UUDE pod'i
kubectl exec -it deployment/postgres -- psql -U postgres -d user_service_db

# Psql shell'is:
SELECT * FROM test_table;

# Peaks ENDISELT näitama:
#  id |     message
# ----+-----------------
#   1 | Persistence test

# Andmed säilisid! ✅

\q
```

---

### Samm 6: StorageClass ja Dynamic Provisioning (10 min)

**StorageClass** võimaldab dynamic provisioning'ut - PV luuakse automaatselt PVC loomisel.

```bash
# Vaata olemasolevaid StorageClass'e
kubectl get storageclass
# või lühidalt:
kubectl get sc

# Minikube:
# NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   AGE
# standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           1d
```

**Loo PVC ilma PV'ta (dynamic provisioning):**

Loo fail `dynamic-pvc.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard  # Minikube default StorageClass
```

**Deploy:**

```bash
kubectl apply -f dynamic-pvc.yaml

# Kontrolli
kubectl get pvc dynamic-pvc

# NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# dynamic-pvc   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   5Gi        RWO            standard       5s

# STATUS: Bound (PV loodi automaatselt!)

# Vaata PV'd
kubectl get pv

# PV nimega pvc-xxxxxxxx... loodi automaatselt
```

**Dynamic provisioning eelised:**
- ✅ Ei vaja manuaalset PV loomist
- ✅ Skaleerib paremini (cloud environmentides)
- ✅ Admin ei pea iga PV't käsitsi looma

---

### Samm 7: StatefulSet PostgreSQL'ile (10 min)

**StatefulSet** on Deployment alternatiiv stateful rakendustele (andmebaasid).

**StatefulSet vs Deployment:**
- **Deployment:** Pod'id on identsed, state'less
- **StatefulSet:** Pod'il on identity (ordinal index), persistent storage automaatselt

Loo fail `postgres-statefulset.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  clusterIP: None  # Headless Service (StatefulSet vajab)
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432

---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres  # Headless Service nimi
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          value: "postgres"
        - name: POSTGRES_PASSWORD
          value: "postgres"
        - name: POSTGRES_DB
          value: "user_service_db"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres

  # volumeClaimTemplates: Loob PVC automaatselt iga pod'ile
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
```

**Deploy:**

```bash
# Kustuta eelmine Deployment (conflict)
kubectl delete deployment postgres

kubectl apply -f postgres-statefulset.yaml

# Kontrolli
kubectl get statefulset

# NAME       READY   AGE
# postgres   1/1     10s

kubectl get pods

# NAME         READY   STATUS    RESTARTS   AGE
# postgres-0   1/1     Running   0          20s

# Märka: Pod nimi on postgres-0 (ordinal index)

# Kontrolli PVC (loodi automaatselt)
kubectl get pvc

# NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# postgres-storage-postgres-0 Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   10Gi       RWO            standard       30s
```

**StatefulSet eelised:**
- ✅ Stable network identity (postgres-0, postgres-1, ...)
- ✅ Persistent storage per pod (volumeClaimTemplates)
- ✅ Ordered deployment ja scaling
- ✅ Sobilik andmebaasidele, Kafka, Elasticsearch

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **PersistentVolume:**
  - [ ] Loodud `postgres-pv`
  - [ ] Capacity, access modes, reclaim policy

- [ ] **PersistentVolumeClaim:**
  - [ ] Loodud `postgres-pvc`
  - [ ] Bound PV'ga

- [ ] **Pod integration:**
  - [ ] PVC mount'itud pod'ile
  - [ ] Andmed säilisid pod restart'i järel

- [ ] **StorageClass:**
  - [ ] Dynamic provisioning töötab
  - [ ] PV loodi automaatselt

- [ ] **StatefulSet:**
  - [ ] PostgreSQL deploy'tud StatefulSet'iga
  - [ ] volumeClaimTemplates töötas

---

## 🐛 Troubleshooting

### Probleem 1: PVC jääb Pending

**Sümptom:**
```bash
kubectl get pvc
# NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# postgres-pvc   Pending                                      manual         1m
```

**Diagnoos:**

```bash
kubectl describe pvc postgres-pvc

# Events:
# - no persistent volumes available for this claim and no storage class is set
```

**Lahendused:**

1. **PV puudub:**
```bash
# Loo PV
kubectl apply -f postgres-pv.yaml
```

2. **StorageClass ei matchi:**
```bash
# Kontrolli PV storage class
kubectl get pv postgres-pv -o yaml | grep storageClassName

# Kontrolli PVC storage class
kubectl get pvc postgres-pvc -o yaml | grep storageClassName

# Peavad matchima!
```

3. **Access mode ei matchi:**
```bash
# PV: ReadWriteMany
# PVC: ReadWriteOnce
# Ei matchi → Muuda ühte
```

---

### Probleem 2: Pod ei käivitu - FailedMount

**Sümptom:**
```bash
kubectl describe pod postgres-xxx

# Events:
# MountVolume.SetUp failed for volume "postgres-pv" : hostPath type check failed
```

**Diagnoos:**

```bash
# hostPath ei eksisteeri node'l
# Minikube: sisene node'sse
minikube ssh
ls -la /mnt/data
exit

# Kui puudub:
minikube ssh
sudo mkdir -p /mnt/data
sudo chmod 777 /mnt/data
exit
```

---

### Probleem 3: PostgreSQL permission denied

**Sümptom:**
```bash
kubectl logs postgres-xxx

# initdb: error: could not change permissions of directory "/var/lib/postgresql/data": Operation not permitted
```

**Lahendus:**

Kasuta `subPath` volume mount'is:

```yaml
volumeMounts:
- name: postgres-storage
  mountPath: /var/lib/postgresql/data
  subPath: postgres  # Fiksib permission issue
```

---

## 🎓 Õpitud Mõisted

### Persistent Volumes:
- **PersistentVolume (PV):** Cluster admin loob, storage resource
- **PersistentVolumeClaim (PVC):** Developer loob, storage request
- **Binding:** PVC ↔ PV ühendamine
- **Access Modes:** RWO, ROX, RWX
- **Reclaim Policy:** Retain, Delete, Recycle

### Storage:
- **StorageClass:** Dynamic provisioning konfiguratsioon
- **Dynamic Provisioning:** PV loodi automaatselt PVC loomisel
- **Static Provisioning:** Admin loob PV käsitsi

### StatefulSet:
- **StatefulSet:** Stateful rakenduste controller
- **Ordinal Index:** Pod'ide numberdamine (postgres-0, postgres-1)
- **volumeClaimTemplates:** Loo PVC automaatselt iga pod'ile
- **Headless Service:** Service ilma ClusterIP'ta

---

## 💡 Parimad Tavad

1. **Kasuta StatefulSet andmebaasidele** - Mitte Deployment
2. **Dynamic provisioning production'is** - Ära loo PV'sid käsitsi
3. **Reclaim Policy: Retain production'is** - Väldimaks juhuslikku andmete kadu
4. **subPath PostgreSQL'ile** - Väldimaks permission issue't
5. **Backup volumes** - Volume ei ole backup lahendus!
6. **Resource requests** - Määra storage suurus mõistlikult (ära küsi 1TB, kui vajad 10GB)
7. **Access modes õigesti** - RWO enamikule, RWX ainult kui vaja
8. **StorageClass per environment** - dev-storage, prod-storage

---

## 🔒 Andmete Turvalisus

**Persistent Volumes ei ole backup!**

- PV võib kaduda (node fail, cluster delete)
- Kasuta eraldi backup lahendust:
  - Velero (Kubernetes backup)
  - Cloud snapshots (AWS EBS, GCP Persistent Disk)
  - pg_dump PostgreSQL'ile
  - Custom CronJob backup scripts

**Näidis: PostgreSQL backup CronJob**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # Iga päev kell 2AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:16-alpine
            command:
            - sh
            - -c
            - pg_dump -U postgres user_service_db > /backups/backup-$(date +\%Y\%m\%d).sql
            env:
            - name: PGPASSWORD
              value: "postgres"
            volumeMounts:
            - name: backups
              mountPath: /backups
          volumes:
          - name: backups
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

---

## 🔗 Järgmine Samm

Õnnitleme! Oled läbinud kõik Lab 3 harjutused:
✅ Pods
✅ Deployments
✅ Services
✅ ConfigMaps & Secrets
✅ Persistent Volumes

**Järgmine Labor:** [Lab 4: Kubernetes Täiustatud](../../04-kubernetes-advanced-lab/README.md)

Lab 4'as õpid:
- Ingress (path-based routing)
- Helm (package manager)
- Autoscaling (HPA)
- Rolling Updates (zero downtime)
- Monitoring

---

## 📚 Viited

- [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)

---

**Õnnitleme! Oskad nüüd hallata persistent storage't Kubernetes'es! 💾**
