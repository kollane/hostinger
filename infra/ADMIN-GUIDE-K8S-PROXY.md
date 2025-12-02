# Kubernetes Laborite Administraatori Juhend (Proxy Keskkond)

## Ülevaade

See juhend on mõeldud administraatorile, kes haldab LXD-põhist DevOps Kubernetes laborikeskkonda **ettevõtte sisevõrgus proxy serveri kaudu**.

**Keskkond:**
- Server: mtadocker1test
- Proxy: cache1.sss:3128
- Template: k8s-lab-base
- Labs: Lab 3-10 (Kubernetes, Helm, CI/CD, Monitoring, Security, GitOps, Terraform)
- Õpilased: Kuni 6 kohta

**Erinevused Docker template'ist:**
- ✅ Kubernetes 1.31 (kubeadm, kubectl, kubelet)
- ✅ Helm, Terraform, Trivy, Kustomize
- ✅ Kernel moodulid HOST'is (overlay, br_netfilter)
- ✅ no_proxy sisaldab `.svc,.cluster.local` (KRIITILINE!)
- ✅ 5GB RAM, 2 CPU cores (vs Docker: 2.5GB, 1 core)

## Kiirviited

- [Süsteemi ülevaade](#süsteemi-ülevaade)
- [Proxy konfiguratsiooni haldamine](#1-proxy-konfiguratsiooni-haldamine)
- [Kernel moodulite haldamine (HOST)](#2-kernel-moodulite-haldamine-host)
- [Konteinerite haldamine](#3-konteinerite-haldamine)
- [Labs failide sünkroniseerimine](#4-labs-failide-sünkroniseerimine)
- [SSH ja turvalisus](#5-ssh-ja-turvalisus-sisevõrk)
- [Kubernetes spetsiifilised käsud](#6-kubernetes-spetsiifilised-käsud)
- [Ressursside monitooring](#7-ressursside-monitooring)
- [Backup ja taastamine](#8-backup-ja-taastamine)
- [Template uuendamine](#9-template-uuendamine-k8s)
- [Uue õpilase lisamine](#10-uue-õpilase-lisamine-k8s-kuni-6-kohta)
- [Probleemide lahendamine](#11-probleemide-lahendamine-k8s-proxy)
- [Kasulikud käsud](#12-kasulikud-käsud-k8s)
- [Quick reference](#13-quick-reference-k8s)

---

## Süsteemi Ülevaade

**Server:**
- Nimi: mtadocker1test
- OS: Ubuntu 24.04 LTS
- Proxy: cache1.sss:3128
- Keskkond: Ettevõtte sisevõrk

**Template:**
- Nimi: k8s-lab-base
- Base: Ubuntu 24.04 + Docker + Kubernetes 1.31
- RAM: 5GB per student
- CPU: 2 cores per student
- Tööriistad: Docker, Kubernetes (kubeadm, kubectl, kubelet), Helm, Terraform, Trivy, Kustomize

**Konteinerid (kuni 6 kohta):**
- devops-k8s-student1 (SSH: 2211, K8s API: 6443)
- devops-k8s-student2 (SSH: 2212, K8s API: 6444)
- devops-k8s-student3 (SSH: 2213, K8s API: 6445)
- devops-k8s-student4 (SSH: 2214, K8s API: 6446) - vajadusel
- devops-k8s-student5 (SSH: 2215, K8s API: 6447) - vajadusel
- devops-k8s-student6 (SSH: 2216, K8s API: 6448) - vajadusel

**Ressursid:**
- 6 × 5GB = 30GB RAM + host overhead

**Labs:**
- Asukoht: ~/projects/labs
- Laborid: Lab 3-10
- Teemad: Kubernetes, Helm, Ingress, HPA, CI/CD, Monitoring, Security, GitOps, Backup, Terraform

---

## 1. Proxy Konfiguratsiooni Haldamine

### 1.1 Host Proxy Seadistamine

Sama nagu Docker juhendis. Vaata ADMIN-GUIDE-DOCKER-PROXY.md sektsioon 1.1.

**Lühidalt:**

```bash
# APT proxy
sudo tee /etc/apt/apt.conf.d/proxy.conf << 'EOF'
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF

# Environment
sudo tee -a /etc/environment << 'EOF'
http_proxy="http://cache1.sss:3128"
https_proxy="http://cache1.sss:3128"
no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF

# Snap proxy
sudo snap set system proxy.http="http://cache1.sss:3128"
sudo snap set system proxy.https="http://cache1.sss:3128"
```

### 1.2 Konteineri Proxy Seadistamine

**⚠️ KRIITILINE ERINEVUS:** K8s template PEAB sisaldama `.svc,.cluster.local` no_proxy seadistuses!

**Põhjus:** Kubernetes pod'id suhtlevad teenustega nagu `postgres-service.default.svc`. Ilma `.svc` no_proxy's läheb päring proxy kaudu → ERROR!

**APT Proxy:**

```bash
lxc exec devops-k8s-student1 -- bash -c 'cat > /etc/apt/apt.conf.d/proxy.conf << "EOF"
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF'
```

**Environment Variables (sisaldab .svc,.cluster.local):**

```bash
# /etc/environment
lxc exec devops-k8s-student1 -- bash -c 'cat >> /etc/environment << "EOF"
http_proxy="http://cache1.sss:3128"
https_proxy="http://cache1.sss:3128"
no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"
HTTP_PROXY="http://cache1.sss:3128"
HTTPS_PROXY="http://cache1.sss:3128"
NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"
EOF'

# /etc/profile.d/proxy.sh
lxc exec devops-k8s-student1 -- bash -c 'cat > /etc/profile.d/proxy.sh << "EOF"
export http_proxy="http://cache1.sss:3128"
export https_proxy="http://cache1.sss:3128"
export no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"
export HTTP_PROXY="http://cache1.sss:3128"
export HTTPS_PROXY="http://cache1.sss:3128"
export NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"
EOF'
```

**Docker Daemon Proxy:**

```bash
lxc exec devops-k8s-student1 -- bash -c '
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/proxy.conf << "EOF"
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"
EOF

systemctl daemon-reload
systemctl restart docker
'
```

**containerd Proxy (sisaldab .svc,.cluster.local):**

```bash
lxc exec devops-k8s-student1 -- bash -c '
mkdir -p /etc/systemd/system/containerd.service.d
cat > /etc/systemd/system/containerd.service.d/proxy.conf << "EOF"
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"
EOF

systemctl daemon-reload
systemctl restart containerd
systemctl restart docker
'
```

### 1.3 Proxy Testimine

Sama nagu Docker juhendis + Kubernetes spetsiifiline:

```bash
# Host
env | grep -i proxy
curl -I https://google.com
apt-get update

# Konteiner
lxc exec devops-k8s-student1 -- bash -l -c 'env | grep -i proxy'
lxc exec devops-k8s-student1 -- curl -I https://google.com
lxc exec devops-k8s-student1 -- apt-get update
lxc exec devops-k8s-student1 -- docker pull alpine:3.16

# Testi K8s pod-to-service ühendust (pärast K8s init)
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get svc'
```

---

## 2. Kernel Moodulite Haldamine (HOST)

### 2.1 Ülevaade

**⚠️ KRIITILINE:** Kernel mooduleid EI SAA laadida konteinerist! LXD konteinerid jagavad HOST'i kerneli.

**Vajalikud moodulid K8s jaoks:**
- `overlay` - OverlayFS support (Docker & Kubernetes)
- `br_netfilter` - Bridge netfilter support (Kubernetes networking)

### 2.2 Kernel Moodulite Laadimise (HOST'is)

```bash
# HOST masinas (mitte konteineris!)
sudo modprobe overlay
sudo modprobe br_netfilter

# Tee moodulid püsivaks (reboot'i järel)
sudo tee /etc/modules-load.d/k8s.conf << 'EOF'
overlay
br_netfilter
EOF

# Kontrolli
lsmod | grep overlay
lsmod | grep br_netfilter
# Peaksid nägema mõlemat moodulit
```

### 2.3 Sysctl Seadistused (HOST'is)

```bash
# HOST masinas
sudo tee /etc/sysctl.d/k8s.conf << 'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Rakenda
sudo sysctl --system

# Kontrolli
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
# Peaks olema: = 1
```

### 2.4 Verifitseerimine Konteineris

```bash
# Logi konteinerisse
lxc exec devops-k8s-student1 -- bash

# Kontrolli, et moodulid on nähtavad (jagatud HOST'iga)
lsmod | grep overlay
lsmod | grep br_netfilter
# Peaksid nägema sama väljundit nagu HOST'is

exit
```

**⚠️ OLULINE:**
- Kui moodulid puuduvad HOST'is, Flannel CNI ei käivitu → K8s cluster ei tööta
- Kui sysctl seadistused puuduvad, pod networking ei tööta korralikult

---

## 3. Konteinerite Haldamine

Sama nagu Docker juhendis, aga konteineri nimed on erinevad:

```bash
# Vaata kõiki K8s konteinereid
lxc list | grep k8s

# Detailne info
lxc info devops-k8s-student1

# Logi konteinerisse
lxc exec devops-k8s-student1 -- bash -l

# Logi konteinerisse (labuser)
lxc exec devops-k8s-student1 -- su - labuser

# Restart
lxc restart devops-k8s-student1
```

**Profile:** devops-lab-k8s (5GB RAM, 2 CPU cores)

---

## 4. Labs Failide Sünkroniseerimine

Sama nagu Docker juhendis, aga konteineri nimed on `devops-k8s-student*`.

### 4.1 Sync Skriptid (K8s versioon)

#### sync-k8s-labs.sh

```bash
cat > ~/scripts/sync-k8s-labs.sh << 'EOFSCRIPT'
#!/bin/bash
# Sync labs to all K8s student containers

set -e

SOURCE_DIR="${LABS_SOURCE:-$HOME/projects/labs}"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Labs source not found: $SOURCE_DIR"
  exit 1
fi

echo "====================================="
echo "Syncing labs to K8s students"
echo "====================================="

# Find all K8s student containers
CONTAINERS=$(lxc list --format csv -c n | grep -E "^devops-k8s-student" || true)

if [ -z "$CONTAINERS" ]; then
  echo "No K8s student containers found"
  exit 0
fi

for CONTAINER in $CONTAINERS; do
  echo ">>> $CONTAINER <<<"

  # Backup existing labs
  lxc exec $CONTAINER -- bash -c "tar czf /tmp/labs-backup-\$(date +%Y%m%d-%H%M%S).tar.gz -C /home/labuser labs 2>/dev/null || true"

  # Push labs directory
  echo "Copying files..."
  lxc file push -r "$SOURCE_DIR/" "$CONTAINER/home/labuser/"

  # Fix ownership
  lxc exec $CONTAINER -- chown -R labuser:labuser /home/labuser/labs

  # Fix executable permissions
  lxc exec $CONTAINER -- find /home/labuser/labs -type f -name '*.sh' -exec chmod 755 {} \;

  echo "✅ $CONTAINER updated!"
  echo
done

echo "✅ All K8s students updated!"
EOFSCRIPT

chmod +x ~/scripts/sync-k8s-labs.sh
```

**Kasutamine:**

```bash
# Sync kõik K8s students
~/scripts/sync-k8s-labs.sh

# VÕI konkreetselt üks
~/scripts/sync-labs.sh devops-k8s-student1
```

---

## 5. SSH ja Turvalisus (Sisevõrk)

Sama nagu Docker juhendis. SSH pordid: 2211-2216 (K8s students).

**Port Mapping:**

| Student | SSH Port |
|---------|----------|
| student1 | 2211 |
| student2 | 2212 |
| student3 | 2213 |
| student4 | 2214 |
| student5 | 2215 |
| student6 | 2216 |

```bash
# Näide: Student1
lxc config device add devops-k8s-student1 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2211 connect=tcp:127.0.0.1:22 nat=true
```

---

## 6. Kubernetes Spetsiifilised Käsud

### 6.1 Kubernetes Cluster Initialization (Iga Õpilane)

**⚠️ OLULINE:** See samm tehakse IGA konteineri sees eraldi! Iga õpilane saab oma isikliku single-node K8s clusteri.

```bash
# 1. Logi konteinerisse
lxc exec devops-k8s-student1 -- su - labuser

# 2. Initsialiseeři klaster (single-node)
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --ignore-preflight-errors=NumCPU,Mem

# 3. Seadista kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 4. Kontrolli
kubectl get nodes
# STATUS peaks olema NotReady (võrk puudub)

# 5. Installi Flannel CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# 6. Oota, kuni valmis (1-2 min)
kubectl get nodes -w
# Oota kuni STATUS = Ready, siis Ctrl+C

# 7. Luba Pods Master Node'il (single-node klaster)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# 8. Testi klastrit
kubectl run nginx-test --image=nginx --port=80
kubectl get pods -w
# Oota STATUS = Running

kubectl delete pod nginx-test

# 9. Logi välja
exit
```

**Võimalikud probleemid:**
- Kui Flannel pod'id ei käivitu → Kontrolli kernel mooduleid HOST'is (vt sektsioon 2)
- Kui image pull ebaõnnestub → Kontrolli containerd proxy't (vt sektsioon 1.2)

### 6.2 Kubernetes Port Forwarding

```bash
# K8s API (iga õpilane oma port)
lxc config device add devops-k8s-student1 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6443 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student2 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6444 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student3 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6445 connect=tcp:127.0.0.1:6443 nat=true

# Ingress HTTP/HTTPS (student1 näide)
lxc config device add devops-k8s-student1 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30080 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student1 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30443 connect=tcp:127.0.0.1:30443 nat=true
```

### 6.3 Port Mapping Tabel (kuni 6 õpilast)

| Service | Internal | Student 1 | Student 2 | Student 3 | Student 4 | Student 5 | Student 6 |
|---------|----------|-----------|-----------|-----------|-----------|-----------|-----------|
| SSH | 22 | 2211 | 2212 | 2213 | 2214 | 2215 | 2216 |
| K8s API | 6443 | 6443 | 6444 | 6445 | 6446 | 6447 | 6448 |
| Ingress HTTP | 30080 | 30080 | 30180 | 30280 | 30380 | 30480 | 30580 |
| Ingress HTTPS | 30443 | 30443 | 30543 | 30643 | 30743 | 30843 | 30943 |

### 6.4 Kubernetes Monitooring

```bash
# Klastri staatus
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl cluster-info'

# Node'id
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get nodes'

# Kõik pod'id
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get pods -A'

# K8s resource kasutus (kui metrics-server on paigaldatud)
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl top nodes'
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl top pods -A'
```

---

## 7. Ressursside Monitooring

Sama nagu Docker juhendis, aga limiidid on erinevad:

**Limiidid per student:**
- RAM: 5GB
- CPU: 2 cores

**Tavaline kasutus:**
- Idle K8s cluster: ~1.5-2GB (Flannel, CoreDNS, kube-proxy, kube-apiserver, etcd)
- K8s cluster + rakendused: ~2-3GB

```bash
# Vaata RAM kasutust
lxc list -c ns4M

# Detailne info
lxc info devops-k8s-student1 | grep -A 3 "Memory usage"
```

---

## 8. Backup ja Taastamine

Sama nagu Docker juhendis + K8s spetsiifiline:

### 8.1 Kubernetes Cluster Backup

**etcd Backup:**

```bash
# Backup etcd (kui vaja)
lxc exec devops-k8s-student1 -- su - labuser -c '
ETCDCTL_API=3 etcdctl snapshot save /tmp/etcd-backup-$(date +%Y%m%d).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
'
```

**kubeconfig Backup:**

```bash
# Backup kubeconfig
lxc file pull devops-k8s-student1/home/labuser/.kube/config /backup/student1-kubeconfig-$(date +%Y%m%d).yaml
```

**LXD Snapshot (soovitatud):**

```bash
# Loo snapshot (hõlmab tervet konteinerit, sh K8s cluster state)
lxc snapshot devops-k8s-student1 before-lab5

# Taasta
lxc restore devops-k8s-student1 before-lab5
```

---

## 9. Template Uuendamine (K8s)

### 9.1 Template Uuendamise Protsess

```bash
# 1. Loo ajutine konteiner
lxc launch k8s-lab-base temp-k8s-update -p default -p devops-lab-k8s

# 2. Logi sisse
lxc exec temp-k8s-update -- bash

# 3-6. [Sama nagu Docker template: proxy seadistus, apt update/upgrade, containerd downgrade]
# Vaata ADMIN-GUIDE-DOCKER-PROXY.md sektsioon 7.2, sammud 3-6

# 7. Uuenda K8s tööriistu (kui vaja)
apt-get update
apt-get upgrade -y kubelet kubeadm kubectl
# VÕI konkreetne versioon
apt-mark unhold kubelet kubeadm kubectl
apt-get install -y kubelet=1.31.x-00 kubeadm=1.31.x-00 kubectl=1.31.x-00
apt-mark hold kubelet kubeadm kubectl

# 8. Verifitseeri K8s versioonid
kubeadm version
kubectl version --client
kubelet --version

# 9. Kontrolli Helm, Terraform, Trivy, Kustomize
helm version
terraform version
trivy version
kustomize version

# 10. Kontrolli no_proxy seadistust (PEAB sisaldama .svc,.cluster.local)
cat /etc/environment | grep no_proxy
cat /etc/profile.d/proxy.sh | grep no_proxy
cat ~/.bashrc | grep no_proxy
# Peab olema: no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"

# Kui puudub, lisa:
sed -i 's/no_proxy="\(.*\)"/no_proxy="\1,.svc,.cluster.local"/' /etc/environment
sed -i 's/no_proxy="\(.*\)"/no_proxy="\1,.svc,.cluster.local"/' /etc/profile.d/proxy.sh

# 11-16. [Sama nagu Docker template: sudo config, puhastamine, publish]
# Vaata ADMIN-GUIDE-DOCKER-PROXY.md sektsioon 7.2, sammud 8-10

# Puhasta
apt-get clean
rm -rf /tmp/* /var/tmp/*
history -c
exit

# Peata konteiner
lxc stop temp-k8s-update

# Backup vana template
lxc image export k8s-lab-base /tmp/k8s-lab-base-backup-$(date +%Y%m%d)

# Kustuta vana alias
lxc image delete k8s-lab-base

# Publitseeri K8s template'ina
lxc publish temp-k8s-update --alias k8s-lab-base \
  description="K8s Lab Template: Ubuntu 24.04 + Docker + K8s 1.31 + Helm + Terraform + Proxy (Updated $(date +%Y-%m-%d))"

# Kustuta ajutine konteiner
lxc delete temp-k8s-update

# Testi uut template'i
lxc launch k8s-lab-base test-new-k8s-template -p default -p devops-lab-k8s
lxc exec test-new-k8s-template -- docker --version
lxc exec test-new-k8s-template -- kubeadm version
lxc delete --force test-new-k8s-template
```

---

## 10. Uue Õpilase Lisamine (K8s, kuni 6 kohta)

**Märkus:** Süsteem toetab kuni 6 õpilast. Alltoodud näited student4, student5, student6 jaoks.

### 10.1 Student4 Lisamine

```bash
# 1. Käivita konteiner
lxc launch k8s-lab-base devops-k8s-student4 -p default -p devops-lab-k8s

# 2. Oota IP
sleep 30
lxc list devops-k8s-student4

# 3. Sea parool
lxc exec devops-k8s-student4 -- bash -c 'echo "labuser:student4" | chpasswd'

# 4. Port forwarding (vt port mapping tabel sektsioon 6.3)
lxc config device add devops-k8s-student4 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2214 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-k8s-student4 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6446 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student4 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30380 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student4 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30743 connect=tcp:127.0.0.1:30443 nat=true

# 5. Sync labs
~/scripts/sync-k8s-labs.sh
# VÕI konkreetselt student4
~/scripts/sync-labs.sh devops-k8s-student4

# 6. Initialize Kubernetes Cluster
# [Vt sektsioon 6.1]

# 7. Testi SSH
ssh labuser@<HOST-IP> -p 2214
# Password: student4

# 8. Testi K8s
ssh labuser@<HOST-IP> -p 2214
kubectl get nodes
```

### 10.2 Student5 ja Student6 Lisamine

Analoogselt student4-le, kasuta järgmisi porte (vt tabel sektsioon 6.3):
- **Student5:** SSH 2215, K8s API 6447, Ingress HTTP 30480, Ingress HTTPS 30843
- **Student6:** SSH 2216, K8s API 6448, Ingress HTTP 30580, Ingress HTTPS 30943

---

## 11. Probleemide Lahendamine (K8s + Proxy)

### 11.1 Proxy Probleemid

Sama nagu Docker juhendis: 9.1-9.5 (Proxy ei tööta konteineris, Docker pull, containerd pull, proxy login shellis, containerd versioon)

### 11.2 kubeadm init Ebaõnnestub

**Sümptom:**
```
kubeadm init
...
[ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
```

**Lahendus:**
```bash
# Ignoreeri preflight errors (lab environment)
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --ignore-preflight-errors=NumCPU,Mem
```

### 11.3 Pods Jäävad Pending/ImagePullBackOff (Proxy)

**Sümptom:**
```
kubectl get pods -A
NAMESPACE     NAME                         READY   STATUS             RESTARTS   AGE
default       nginx-test-xxx               0/1     ImagePullBackOff   0          2m
```

**Lahendus:**
```bash
# 1. Kontrolli pod'i detaile
kubectl describe pod nginx-test-xxx

# 2. Kui "failed to pull image" - containerd proxy puudub
lxc exec devops-k8s-student1 -- bash -c '
mkdir -p /etc/systemd/system/containerd.service.d
cat > /etc/systemd/system/containerd.service.d/proxy.conf << "EOF"
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"
EOF

systemctl daemon-reload
systemctl restart containerd
'

# 3. Kustuta pod ja loo uuesti
kubectl delete pod nginx-test-xxx
kubectl run nginx-test --image=nginx --port=80
```

### 11.4 Kubernetes Services Unreachable (no_proxy Vale)

**Sümptom:**
```
kubectl exec -it myapp-pod -- curl http://postgres-service.default.svc:5432
curl: (6) Could not resolve host: postgres-service.default.svc
```

**Põhjus:** `.svc` puudub no_proxy seadistuses → päring läheb proxy kaudu.

**Lahendus:**
```bash
# 1. Kontrolli no_proxy
lxc exec devops-k8s-student1 -- su - labuser -c 'echo $no_proxy'

# 2. Kui .svc,.cluster.local puudub, lisa
lxc exec devops-k8s-student1 -- bash -c '
# /etc/environment
sed -i "s/no_proxy=\"\(.*\)\"/no_proxy=\"\1,.svc,.cluster.local\"/" /etc/environment

# /etc/profile.d/proxy.sh
sed -i "s/no_proxy=\"\(.*\)\"/no_proxy=\"\1,.svc,.cluster.local\"/" /etc/profile.d/proxy.sh

# labuser ~/.bashrc
sed -i "s/no_proxy=\"\(.*\)\"/no_proxy=\"\1,.svc,.cluster.local\"/" /home/labuser/.bashrc
'

# 3. Restart pod'id (kui vaja)
kubectl delete pod myapp-pod
kubectl apply -f myapp-deployment.yaml
```

### 11.5 Flannel Pod'id Ei Käivitu

**Sümptom:**
```
kubectl get pods -n kube-flannel
NAME                    READY   STATUS             RESTARTS   AGE
kube-flannel-ds-xxx     0/1     CrashLoopBackOff   5          3m
```

**Lahendus:**
```bash
# 1. Vaata logi
kubectl logs -n kube-flannel kube-flannel-ds-xxx

# 2. Kontrolli kernel mooduleid (HOST'is!)
# Logi välja konteinerist
exit

# HOST'is
lsmod | grep overlay
lsmod | grep br_netfilter

# Kui puudub, laadi moodulid (vt sektsioon 2.2)
sudo modprobe overlay
sudo modprobe br_netfilter

# 3. Logi tagasi konteinerisse ja kontrolli
lxc exec devops-k8s-student1 -- lsmod | grep overlay

# 4. Restart Flannel
lxc exec devops-k8s-student1 -- su - labuser -c '
kubectl delete pods -n kube-flannel --all
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
'
```

### 11.6 kubectl Ei Tööta (kubeconfig Puudu)

**Sümptom:**
```
kubectl get nodes
The connection to the server localhost:8080 was refused
```

**Lahendus:**
```bash
# Seadista kubeconfig
lxc exec devops-k8s-student1 -- su - labuser -c '
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
'

# Testi
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get nodes'
```

---

## 12. Kasulikud Käsud (K8s)

### Proxy Debug

Sama nagu Docker juhendis.

### Kubernetes Haldamine

```bash
# Klastri info
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl cluster-info'

# Node'id
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get nodes'

# Kõik pod'id
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get pods -A'

# Namespace'id
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get ns'

# Deployment'id
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get deployments -A'

# Service'id
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get svc -A'

# Ingress'id
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get ingress -A'

# Resource kasutus
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl top nodes'
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl top pods -A'
```

### Kernel Moodulid (HOST)

```bash
# Kontrolli mooduleid
lsmod | grep overlay
lsmod | grep br_netfilter

# Laadi moodulid (kui puudub)
sudo modprobe overlay
sudo modprobe br_netfilter

# Verifitseeri konteineris
lxc exec devops-k8s-student1 -- lsmod | grep overlay
```

### Labs Sync (K8s)

```bash
# Sync kõik K8s students
~/scripts/sync-k8s-labs.sh

# Kontrolli versioone
~/scripts/check-versions.sh

# Sync üks
~/scripts/sync-labs.sh devops-k8s-student1
```

---

## 13. Quick Reference (K8s)

| Tegevus | Käsk |
|---------|------|
| Vaata K8s konteinereid | `lxc list \| grep k8s` |
| Logi K8s konteinerisse | `lxc exec devops-k8s-student1 -- bash -l` |
| Restart K8s konteiner | `lxc restart devops-k8s-student1` |
| Snapshot K8s | `lxc snapshot devops-k8s-student1 <name>` |
| Kontrolli K8s node'e | `lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get nodes'` |
| Kontrolli K8s pod'e | `lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get pods -A'` |
| Sync labs (K8s) | `~/scripts/sync-k8s-labs.sh` |
| Kontrolli proxy | `lxc exec devops-k8s-student1 -- env \| grep -i proxy` |
| Testi Docker pull | `lxc exec devops-k8s-student1 -- docker pull alpine:3.16` |
| Kernel moodulid HOST | `sudo modprobe overlay br_netfilter` |

---

**Viimane uuendus:** 2025-12-02
**Versioon:** 1.0
**Proxy:** cache1.sss:3128
**Hooldaja:** VPS Admin
**Keskkond:** Ettevõtte sisevõrk (proxy)
**Template:** k8s-lab-base (Kubernetes 1.31, Lab 3-10)
**K8s Versioon:** 1.31
