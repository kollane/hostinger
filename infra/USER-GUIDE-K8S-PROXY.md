# Kasutajajuhend: Kubernetes Laborid (Proxy Keskkond)

## Tere tulemast Kubernetes laboritesse!

Tere tulemast DevOps koolituse Kubernetes laborite juurde! See juhend aitab sul alustada tööd oma isiklikus K8s (Kubernetes) laborikeskkonnas, kus saad praktiseerida konteineri orkestreerimist ja keerukamaid DevOps tehnoloogiaid.

**Mida sa siin õpid:**
- **Lab 3:** Kubernetes põhialused - pod'id, deployment'id, service'id
- **Lab 4:** Kubernetes täpsemalt - Ingress, HPA (Horizontal Pod Autoscaler), Helm
- **Lab 5:** CI/CD - GitHub Actions, pipeline'id
- **Lab 6:** Monitoring - Prometheus, Grafana, Loki
- **Lab 7:** Turvalisus - Vault, RBAC, security policies
- **Lab 8:** GitOps - ArgoCD, deklaratiivne deployment
- **Lab 9:** Backup & Disaster Recovery - andmete kaitse
- **Lab 10:** Infrastructure as Code - Terraform

**Kuidas saada abi:**
- Loe esmalt see juhend hoolikalt läbi
- Kui jääd hätta, vaata "Probleemide Lahendamine" sektsiooni (peatükk 6)
- Küsi abi kaasõppijatelt või koolitajalt
- Ära karda eksida - K8s on keerukas, aga praktiline kogemus on parim õpetaja!

---

## Sinu Keskkond

### Kontoinformatsioon

Iga õpilane saab oma isikliku Kubernetes klastri (ühe-node'iga):

- **Kasutajanimi:** `labuser`
- **Parool:** Saad koolitajalt (küsi, kui ei tea)
- **SSH Port:** Vastavalt õpilase numbrile (vaata allolevast tabelist)
- **Host IP:** Serveri IP aadress (saad koolitajalt)
- **K8s Versioon:** 1.31

### Port Mapping

Iga õpilane kasutab erinevaid porte. Leia oma õpilasenumber ja kasuta vastavaid porte:

| Õpilane | SSH Port | K8s API | Ingress HTTP | Ingress HTTPS |
|---------|----------|---------|--------------|---------------|
| **Student1** | 2211 | 6443 | 30080 | 30443 |
| **Student2** | 2212 | 6444 | 30180 | 30543 |
| **Student3** | 2213 | 6445 | 30280 | 30643 |
| **Student4** | 2214 | 6446 | 30380 | 30743 |
| **Student5** | 2215 | 6447 | 30480 | 30843 |
| **Student6** | 2216 | 6448 | 30580 | 30943 |

**Näide (Student1):**
- SSH ühendus: `ssh labuser@<HOST-IP> -p 2211`
- Kubernetes API: `https://<HOST-IP>:6443` (kubectl kasutab seda automaatselt)
- Rakendused HTTP: `http://<HOST-IP>:30080`
- Rakendused HTTPS: `https://<HOST-IP>:30443`

### Ressursid

Sinu laborikeskkond sisaldab:

- **RAM:** 5GB (piisav Kubernetes laboriteks)
- **CPU:** 2 cores
- **Tööriistad:**
  - Docker (konteineri runtime)
  - Kubernetes 1.31 (kubeadm, kubelet, kubectl)
  - Helm 3 (package manager)
  - Terraform (infrastructure as code)
  - Trivy (security scanner)
  - Kustomize (configuration management)
  - Git (versioonihalduks)

---

## 1. Esimene Sisselogimine

### SSH Kaudu Sisselogimine

Kasuta oma arvutis terminali (Windows: PowerShell, Mac/Linux: Terminal):

```bash
# Üldine formaat
ssh labuser@<HOST-IP> -p <SSH-PORT>

# Näide: Student1
ssh labuser@192.168.1.100 -p 2211

# Näide: Student3
ssh labuser@192.168.1.100 -p 2213

# Sisesta parool kui küsitakse (parool ei kuvata, kui trükid)
```

**Esimesel korral** võid näha hoiatust võtme kohta:
```
The authenticity of host '[192.168.1.100]:2211' can't be established.
...
Are you sure you want to continue connecting (yes/no)?
```

Kirjuta `yes` ja vajuta Enter.

### Kontrolli Keskkonda

Pärast sisselogimist kontrolli, et kõik töötab:

```bash
# 1. Kontrolli kasutajanime
whoami
# Väljund peaks olema: labuser

# 2. Kontrolli masina nime
hostname
# Väljund peaks olema midagi nagu: devops-k8s-student1

# 3. Kontrolli kubectl versiooni
kubectl version --client
# Näitab kubectl versiooni

# 4. Vaata klastri node'e
kubectl get nodes
# Peaks näitama ühte node'i staatusega Ready

# 5. Vaata klastri infot
kubectl cluster-info
# Näitab Kubernetes control plane aadressi

# 6. Vaata süsteemi pod'e
kubectl get pods -n kube-system
# Peaks näitama kõiki süsteemi pod'e (coredns, flannel, jne)

# 7. Vaata labori faile
cd ~/labs
ls -la
# Peaks näitama: 03-k8s-basics-lab kuni 10-terraform-iac-lab
```

Kui kõik käsud töötasid ja node on Ready, oled valmis alustama!

---

## 2. Kubernetes Põhikäsud

### Node'id ja Klaster

```bash
# Vaata kõiki node'e
kubectl get nodes

# Detailne info node'st
kubectl get nodes -o wide
# Näitab: IP, OS, kernel, container runtime

# Veel detailsem info
kubectl describe node <node-name>

# Klastri info
kubectl cluster-info

# Klastri komponentide staatus
kubectl get componentstatuses
# VÕI lühidalt:
kubectl get cs
```

### Pod'id

Pod on Kubernetes'e väikseim ühik - üks või mitu konteinerit koos:

```bash
# Vaata kõiki pod'e kõigis namespace'ides
kubectl get pods -A
# -A = --all-namespaces

# Vaata pod'e default namespace'is
kubectl get pods

# Detailne info pod'ist
kubectl describe pod <pod-name>

# Vaata pod'i logisid
kubectl logs <pod-name>

# Vaata logisid reaalajas (live)
kubectl logs -f <pod-name>
# Vajuta Ctrl+C, et väljuda

# Kui pod'is on mitu konteinerit, määra konteiner
kubectl logs <pod-name> -c <container-name>

# Logi pod'i sisse
kubectl exec -it <pod-name> -- /bin/sh
# VÕI kui on bash:
kubectl exec -it <pod-name> -- /bin/bash

# Käivita käsk pod'is ilma sisse logimata
kubectl exec <pod-name> -- ls /app

# Kustuta pod
kubectl delete pod <pod-name>
```

### Deployment'id

Deployment haldab pod'e ja tagab, et neid töötaks alati õige arv:

```bash
# Vaata kõiki deployment'e
kubectl get deployments
# VÕI lühidalt:
kubectl get deploy

# Detailne info deployment'ist
kubectl describe deployment <deployment-name>

# Skaleeri deployment'i
kubectl scale deployment <deployment-name> --replicas=3
# Loob 3 pod'i

# Restart deployment'i pod'e (zero-downtime)
kubectl rollout restart deployment <deployment-name>

# Vaata deployment'i ajalugu
kubectl rollout history deployment <deployment-name>

# Tagasi varem versiooni (rollback)
kubectl rollout undo deployment <deployment-name>

# Kustuta deployment (sh kõik selle pod'id)
kubectl delete deployment <deployment-name>
```

### Service'id

Service võimaldab juurdepääsu pod'idele stabiilse nime ja IP kaudu:

```bash
# Vaata kõiki service'id
kubectl get services
# VÕI lühidalt:
kubectl get svc

# Detailne info service'ist
kubectl describe service <service-name>

# Vaata endpoints'e (millised pod'id on service'i taga)
kubectl get endpoints <service-name>

# Kustuta service
kubectl delete service <service-name>
```

### Namespace'id

Namespace'id aitavad eraldada ressursse:

```bash
# Vaata kõiki namespace'e
kubectl get namespaces
# VÕI lühidalt:
kubectl get ns

# Loo uus namespace
kubectl create namespace my-app

# Vaata pod'e konkreetses namespace'is
kubectl get pods -n my-app

# Vaata kõike namespace'is
kubectl get all -n my-app

# Kustuta namespace (sh kõik selle sees!)
kubectl delete namespace my-app
```

### YAML Failide Kasutamine

Kubernetes kasutab YAML faile ressursside kirjeldamiseks:

```bash
# Rakenda YAML faili
kubectl apply -f deployment.yaml

# Rakenda kõik YAML failid kataloogis
kubectl apply -f ./manifests/

# Kustuta ressursid YAML failist
kubectl delete -f deployment.yaml

# Vaata YAML'i ilma rakendamata (dry-run)
kubectl apply -f deployment.yaml --dry-run=client -o yaml

# Ekspordi olemasolev ressurss YAML'ina
kubectl get deployment my-app -o yaml > my-app.yaml
```

---

## 3. Helm (Package Manager)

Helm on Kubernetes'e package manager, mis võimaldab installida terved rakendusi ühe käsuga:

```bash
# Lisa Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable

# Uuenda repository nimekirja
helm repo update

# Otsi chart'e
helm search repo nginx
helm search repo postgres

# Vaata chart'i infot
helm show chart bitnami/nginx
helm show values bitnami/nginx  # Default väärtused

# Installi chart
helm install my-nginx bitnami/nginx

# Installi chart kindlasse namespace'i
helm install my-nginx bitnami/nginx -n my-namespace --create-namespace

# Installi chart custom väärtustega
helm install my-nginx bitnami/nginx --set service.type=NodePort

# VÕI kasuta values.yaml faili
helm install my-nginx bitnami/nginx -f my-values.yaml

# Vaata installitud release'e
helm list
# VÕI kõigis namespace'ides:
helm list -A

# Vaata release'i staatust
helm status my-nginx

# Upgrade release'i
helm upgrade my-nginx bitnami/nginx

# Upgrade VÕI install (kui ei eksisteeri)
helm upgrade --install my-nginx bitnami/nginx

# Rollback release'i
helm rollback my-nginx 1  # 1 = revision number

# Kustuta release
helm uninstall my-nginx

# Kustuta release ja puhasta ajalugu
helm uninstall my-nginx --purge
```

---

## 4. Labori Failide Kasutamine

### Kataloogistruktuur

Sinu labori failid asuvad kataloogis `~/labs`:

```
~/labs/
├── README.md                  # Ülevaade kõigist laboritest
├── 03-k8s-basics-lab/         # Lab 3: Kubernetes põhialused
│   ├── README.md
│   ├── exercises/
│   └── solutions/
├── 04-k8s-advanced-lab/       # Lab 4: Ingress, HPA, Helm
│   ├── README.md
│   ├── exercises/
│   └── solutions/
├── 05-cicd-lab/               # Lab 5: CI/CD
├── 06-monitoring-lab/         # Lab 6: Prometheus, Grafana
├── 07-security-lab/           # Lab 7: Security, Vault, RBAC
├── 08-gitops-lab/             # Lab 8: ArgoCD
├── 09-backup-lab/             # Lab 9: Backup & Disaster Recovery
└── 10-terraform-iac-lab/      # Lab 10: Terraform IaC
```

### Töövoog

Nii peaks töötama ülesandega:

```bash
# 1. Loe labori üldist juhendit
cd ~/labs/03-k8s-basics-lab
cat README.md
# VÕI kasuta less:
less README.md  # Vajuta 'q', et väljuda

# 2. Mine ülesande kataloogi
cd exercises/01-pods

# 3. Loe ülesande juhendit
cat README.md

# 4. Tee ülesannet
# Näiteks rakenda YAML fail:
kubectl apply -f pod.yaml

# Kontrolli tulemust:
kubectl get pods

# 5. Testi oma lahendust
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# 6. Kui jääd hätta, vaata lahendust
cd ~/labs/03-k8s-basics-lab/solutions/01-pods
cat solution.md
cat pod.yaml  # Näidis YAML fail
```

---

## 5. Kasulikud Käsud

### Kiirviited (Alias'ed)

Kubernetes käsud võivad olla pikad. Tee need lühemaks:

```bash
# Lisa need ~/.bashrc faili
echo "alias k='kubectl'" >> ~/.bashrc
echo "alias kgp='kubectl get pods'" >> ~/.bashrc
echo "alias kgs='kubectl get services'" >> ~/.bashrc
echo "alias kgd='kubectl get deployments'" >> ~/.bashrc
echo "alias kgn='kubectl get nodes'" >> ~/.bashrc
echo "alias kga='kubectl get all'" >> ~/.bashrc

# Rakenda kohe
source ~/.bashrc

# Nüüd saad kasutada:
k get pods
kgp
kgp -A
kgs
kgd
```

### Ressursside Kasutus

```bash
# Vaata node'ide ressursside kasutust
kubectl top nodes

# Vaata pod'ide ressursside kasutust
kubectl top pods

# Vaata kõigi pod'ide ressursse kõigis namespace'ides
kubectl top pods -A

# Sorteeritud RAM järgi
kubectl top pods -A --sort-by=memory

# Sorteeritud CPU järgi
kubectl top pods -A --sort-by=cpu
```

### Debug Käsud

```bash
# Vaata klastri eventi (uusimad üleval)
kubectl get events --sort-by=.metadata.creationTimestamp

# Vaata eventi konkreetses namespace'is
kubectl get events -n my-namespace

# Vaata pod'i täielikku YAML'i
kubectl get pod <pod-name> -o yaml

# Vaata pod'i JSON'ina
kubectl get pod <pod-name> -o json

# Vaata service'i DNS'i lahendamist
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# Konteineri sees:
nslookup my-service
nslookup my-service.my-namespace.svc.cluster.local
exit

# Testi võrku kahe pod'i vahel
kubectl exec <pod1> -- ping <pod2-ip>

# Vaata, millised port'id on avatud
kubectl exec <pod-name> -- netstat -tuln
```

### Puhastamine

```bash
# Kustuta kõik pod'id default namespace'is
kubectl delete pods --all

# Kustuta kõik ressursid namespace'is
kubectl delete all --all -n my-namespace

# Kustuta kõik failed pod'id
kubectl delete pods --field-selector status.phase=Failed -A

# Sunni kustutamine (kui pod ei kustuta)
kubectl delete pod <pod-name> --force --grace-period=0
```

---

## 6. Probleemide Lahendamine

### Probleem 1: Pod Jääb Pending Olekusse

**Sümptom:**
```
kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
mypod     0/1     Pending   0          5m
```

**Võimalikud põhjused:**
1. Ebapiisav RAM või CPU (node'il ei ole ressursse)
2. Node ei ole valmis (NotReady)
3. Image pull ebaõnnestub
4. PersistentVolumeClaim ei ole bound

**Lahendus:**

```bash
# 1. Vaata pod'i detailset infot
kubectl describe pod mypod
# Vaata "Events" sektsiooni alumises osas

# 2. Kontrolli node'i staatust
kubectl get nodes
# Peaks olema "Ready"

# 3. Kontrolli ressursse
kubectl top nodes
kubectl top pods -A

# 4. Kui ressursid on otsas, skaleeri teisi deployment'e maha
kubectl scale deployment <another-deployment> --replicas=0

# 5. Kui image pull ebaõnnestub, võta ühendust koolitajaga
```

---

### Probleem 2: Image Pull Ebaõnnestub

**Sümptom:**
```
kubectl describe pod mypod
...
Events:
  Warning  Failed     Pulling image "myimage:v1": rpc error...
  Warning  Failed     Failed to pull image "myimage:v1": ...
```

**Põhjus:**
- Image'i ei eksisteeri
- Proxy seadistus puudub või on vale (administraatori probleem)
- Registry autentimine puudub

**Lahendus:**

```bash
# 1. Kontrolli image'i nime
kubectl get pod mypod -o yaml | grep image:

# 2. Proovi pull'ida käsitsi
docker pull myimage:v1

# 3. Kui image on privaatr egistry's, loo secret
kubectl create secret docker-registry my-secret \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<pass>

# Lisa secret pod'i YAML'i:
# imagePullSecrets:
# - name: my-secret

# 4. Kui proxy probleem, võta ühendust koolitajaga
```

---

### Probleem 3: Service Ei Ole Kättesaadav

**Sümptom:**
```
curl http://my-service:8080
curl: (6) Could not resolve host: my-service
```

**Lahendus:**

```bash
# 1. Kontrolli, kas service eksisteerib
kubectl get services
kubectl get svc my-service

# 2. Kontrolli, kas pod'id töötavad
kubectl get pods -l app=my-app
# Service kasutab selector'it leida pod'e

# 3. Kontrolli endpoints'e
kubectl get endpoints my-service
# Kui ENDPOINTS on <none>, siis pod'id ei vasta selector'ile

# 4. Testi DNS'i
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
nslookup my-service
nslookup my-service.default.svc.cluster.local
exit

# 5. Testi service'i cluster IP'lt
kubectl get svc my-service  # Leia CLUSTER-IP
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
wget -O- http://<CLUSTER-IP>:8080
exit

# 6. Kui on NodePort service, testi:
curl http://<NODE-IP>:<NODE-PORT>
```

---

### Probleem 4: kubectl Ei Tööta

**Sümptom:**
```
kubectl get nodes
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

**Põhjus:** kubeconfig puudub või on vale.

**Lahendus:**

```bash
# 1. Kontrolli kubeconfig'i
ls -la ~/.kube/config

# 2. Kontrolli kubeconfig'i sisu
kubectl config view

# 3. Kui puudub, võta ühendust koolitajaga
# Administraator peab selle seadistama

# 4. Kontrolli, kas saad API serveriga ühendust
curl -k https://localhost:6443
# Peaks vastama 403 või 401 (see on OK)
```

---

### Probleem 5: Pod CrashLoopBackOff

**Sümptom:**
```
kubectl get pods
NAME      READY   STATUS             RESTARTS   AGE
mypod     0/1     CrashLoopBackOff   5          5m
```

**Põhjus:** Konteiner käivitus, aga siis kohe "crashed" (lõppes).

**Lahendus:**

```bash
# 1. Vaata logisid
kubectl logs mypod
# Näitab viimase konteineri logisid

# 2. Vaata eelmise crash'i logisid
kubectl logs mypod --previous

# 3. Vaata detailset infot
kubectl describe pod mypod
# Vaata "State" ja "Last State" sektsioone

# 4. Kui konteiner käivitus aga kohe lõppes, võib olla:
# - Rakendus sai vea ja lõpetas
# - Puudub CMD või ENTRYPOINT (konteiner lõpetas kohe)
# - Liveness probe ei läbi

# 5. Kontrolli YAML'i
kubectl get pod mypod -o yaml
# Vaata: command, args, livenessProbe

# 6. Testi konteinerit käsitsi Docker'iga
docker run -it <image-name> /bin/sh
```

---

### Probleem 6: Node on NotReady

**Sümptom:**
```
kubectl get nodes
NAME       STATUS     ROLES           AGE   VERSION
node1      NotReady   control-plane   5m    v1.31.0
```

**Põhjus:**
- Kubelet ei tööta
- Network plugin (Flannel) ei tööta
- Ressursid otsas

**Lahendus:**

```bash
# 1. Kontrolli kubelet'i
sudo systemctl status kubelet

# 2. Vaata kubelet'i logisid
sudo journalctl -u kubelet -f
# Vajuta Ctrl+C, et väljuda

# 3. Kontrolli network plugin'i (Flannel)
kubectl get pods -n kube-system | grep flannel
# Kõik flannel pod'id peavad olema Running

# 4. Kui midagi on katki, võta ühendust koolitajaga
# See on administraatori probleem
```

---

### Probleem 7: Ingress Ei Tööta

**Sümptom:**
```
curl http://<HOST-IP>:30080
curl: (7) Failed to connect
```

**Lahendus:**

```bash
# 1. Kontrolli Ingress controller'it
kubectl get pods -n ingress-nginx
# Peaks olema ingress-nginx-controller pod Running

# 2. Kontrolli Ingress ressurssi
kubectl get ingress
kubectl describe ingress my-ingress

# 3. Kontrolli, kas backend service töötab
kubectl get svc
kubectl get endpoints <backend-service>

# 4. Testi NodePort'i otse
kubectl get svc -n ingress-nginx
# Leia ingress-nginx-controller service NodePort

# 5. Kui ei tööta, võta ühendust koolitajaga
```

---

## 7. Parimad Praktikad

### DO's ✅

- **Kasuta namespace'e**
  - Eralda oma rakendused teistest
  - `kubectl create namespace my-app`
  - `kubectl apply -f app.yaml -n my-app`

- **Lisa label'id**
  - Märgista oma ressursid
  - `app=myapp`, `env=dev`, `version=v1`

- **Kasuta YAML faile**
  - Ära loo ressursse käsitsi käskudega
  - YAML failid on versioonihallatavad
  - `kubectl apply -f deployment.yaml`

- **Testi enne apply'd**
  - `kubectl apply -f app.yaml --dry-run=client -o yaml`
  - Kontrolli, kas YAML on korrektne

- **Puhasta ressursid**
  - Kustuta kasutamata pod'id, deployment'id, service'id
  - `kubectl delete deployment old-app`

- **Kasuta ressursside piire**
  - Määra requests ja limits YAML'is:
    ```yaml
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
    ```

### DON'T's ❌

- ❌ **Ära kustuta kube-system pod'e**
  - Need on süsteemi pod'id
  - Kui kustutad, klaster ei tööta

- ❌ **Ära kasuta default namespace'i**
  - Loo oma namespace
  - Default on segane ja ei eralda ressursse

- ❌ **Ära kasuta kogu RAM-i**
  - Sul on 5GB RAM-i
  - Jäta vähemalt 1GB vabaks süsteemi pod'idele
  - Vaata: `kubectl top nodes`

- ❌ **Ära jäta töötavaid deployment'e**
  - Kui ei kasuta, skaleeri 0-le:
  - `kubectl scale deployment my-app --replicas=0`

- ❌ **Ära proovi parandada süsteemi probleeme**
  - Kubelet ei tööta → Koolitaja
  - Node NotReady → Koolitaja
  - Flannel ei tööta → Koolitaja

- ❌ **Ära sunni kustuta pod'e ilma põhjuseta**
  - `kubectl delete pod <pod> --force` on ohtlik
  - Kasuta ainult kui tõesti vaja

---

## 8. Kasulikud Lingid

### Kubernetes Dokumentatsioon

- **Kubernetes põhialused:** https://kubernetes.io/docs/home/
- **kubectl Cheat Sheet:** https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- **Kubernetes Concepts:** https://kubernetes.io/docs/concepts/
- **kubectl Reference:** https://kubernetes.io/docs/reference/kubectl/

### Helm

- **Helm dokumentatsioon:** https://helm.sh/docs/
- **Helm Hub (chart'id):** https://artifacthub.io/

### Muud Tööriistad

- **Terraform:** https://www.terraform.io/docs
- **Prometheus:** https://prometheus.io/docs/
- **Grafana:** https://grafana.com/docs/
- **ArgoCD:** https://argo-cd.readthedocs.io/

### Õppematerjalid

- **Play with Kubernetes:** https://labs.play-with-k8s.com/ (tasuta online labor)
- **Kubernetes By Example:** https://kubernetesbyexample.com/
- **Kubernetes The Hard Way:** https://github.com/kelseyhightower/kubernetes-the-hard-way

### Eesti Keelsed Materjalid

- Selles koolituses kasutatakse eesti keelseid teoreetilisi materjale
- Küsi koolitajalt, millised peatükid toetavad neid Kubernetes laboreid

---

## 9. Abi Saamine

### Enda Jaoks

**Kui sul on probleeme:**

1. **Proovi esmalt lahendada ise**
   - Loe "Probleemide Lahendamine" sektsiooni (peatükk 6)
   - Vaata pod'i logisid: `kubectl logs <pod-name>`
   - Vaata eventi: `kubectl get events --sort-by=.metadata.creationTimestamp`
   - Vaata detaile: `kubectl describe pod <pod-name>`
   - Otsi veateadet Google'ist

2. **Kasuta kubectl help'i**
   - `kubectl --help`
   - `kubectl get --help`
   - `kubectl apply --help`

3. **Küsi kaasõppijatelt**
   - Võib-olla keegi on sama probleemiga kokku puutunud
   - Jagage teadmisi ja kogemusi

4. **Võta ühendust koolitajaga**
   - Kirjuta selgelt, mis probleem on
   - Lisa:
     - `kubectl get pods` väljund
     - `kubectl describe pod <pod>` väljund
     - `kubectl logs <pod>` väljund
   - Ütle, mis sa juba proovisid

### Tehnilised Probleemid (Koolitaja Abi)

Järgmiste probleemide korral võta **kohe** ühendust koolitajaga:

- **SSH ei tööta** → Koolitaja
- **kubectl ei tööta** → Koolitaja
- **Node on NotReady** → Koolitaja
- **Kubernetes klaster ei tööta** → Koolitaja
- **Image pull ebaõnnestub (proxy)** → Koolitaja
- **Labori failid puuduvad** → Koolitaja
- **Ressursid on otsa** (RAM, disk) → Koolitaja
- **Flannel või CNI ei tööta** → Koolitaja
- **Ingress controller ei tööta** → Koolitaja

### Koolitaja Kontakt

[Siin peaks olema koolitaja kontaktandmed - küsi koolitajalt]

---

## Kokkuvõte

Palju õnne - nüüd oled valmis alustama Kubernetes laboreid!

**Meeldetuletused:**
- Sinu keskkond: `devops-k8s-student<X>` (X = sinu number)
- SSH port: `221X` (näiteks Student1 = 2211)
- Kubernetes käsud: `kubectl get`, `kubectl apply`, `kubectl describe`
- Helm: `helm install`, `helm list`, `helm uninstall`
- Namespace'id: Alati loo oma namespace (`kubectl create ns my-app`)
- Abi: Loe juhendeid, vaata logisid, küsi kaasõppijatelt, võta ühendust koolitajaga

**Edu Kubernetes laboritega!**

Kubernetes on keerukas, aga ülimalt võimas tööriist. Ära karda eksida - vigadest õpitakse kõige rohkem. Praktiline kogemus on parim õpetaja, ja pärast neid laboreid oskad sa hallata tootmiskeskkondi!

---

**Viimane uuendus:** 2025-12-02
**Versioon:** 1.0
**Keskkond:** Kubernetes Lab (Lab 3-10)
**K8s Versioon:** 1.31
**Sihtgrupp:** DevOps koolituse õpilased

---

**Küsimused või ettepanekud?** Võta ühendust koolitajaga!
