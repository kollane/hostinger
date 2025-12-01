# LXD Kubernetes Laborikeskkonna Paigaldusjuhend (Proxy)

## Ülevaade

See juhend on **Kubernetes laborite (Lab 3-10)** jaoks ettevõtte sisevõrgus, kus ligipääs internetile käib läbi proxy serveri.

**Eeldused:**
- Ubuntu 24.04 LTS
- Vähemalt 24GB RAM (3 õpilast × 5GB + host)
- Proxy: `http://cache1.sss:3128`
- Sisemine staatiline IP

---

## 1. Host Süsteemi Ettevalmistus

### 1.1 Proxy Kontrollimine

```bash
# Kontrolli, et host'i proxy töötab
cat /etc/apt/apt.conf.d/proxy.conf
# Peaks näitama:
# Acquire::http::Proxy "http://cache1.sss:3128";
# Acquire::https::Proxy "http://cache1.sss:3128";

# Testi
sudo apt-get update
```

### 1.2 Süsteemi Uuendamine

```bash
sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y \
  curl \
  wget \
  git \
  vim \
  htop \
  net-tools \
  ca-certificates \
  gnupg \
  lsb-release
```

### 1.3 Swap Seadistamine (kui puudub)

```bash
# Kontrolli
free -h
swapon --show

# Kui puudub, loo 4GB swap
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 2. LXD Paigaldamine

### 2.1 LXD Snap

```bash
sudo snap install lxd
sudo usermod -aG lxd $USER
newgrp lxd

# Kontrolli
lxd --version
```

### 2.2 LXD Initialiseerimine

```bash
lxd init
```

**Vastused:**
```
Clustering: no
Storage pool: yes → default → dir
MAAS: no
Network bridge: yes → lxdbr0
IPv4: auto (või 10.67.86.1/24)
IPv6: none
Available over network: no
Cache images: yes
YAML preseed: no
```

### 2.3 LXD Kontrollimine

```bash
lxc network list
lxc storage list
lxc profile list
```

---

## 3. Turvalisus (Sisevõrk)

**Ettevõtte sisevõrgus jätame vahele:**

| Komponent | Staatus | Põhjus |
|-----------|---------|--------|
| **UFW** | ❌ Ei kasuta | Ettevõtte tulemüür kaitseb, võib segada LXD võrku |
| **fail2ban** | ❌ Ei kasuta | Brute-force sisevõrgust ebatõenäoline |
| **SSH hardening** | ❌ Ei kasuta | Laborikeskkond, lihtsad paroolid OK |

**Miks:**
- Masin on sisevõrgus sisemise IP-ga (mitte internetis)
- Ligipääs internetile käib läbi ettevõtte proxy
- Ettevõtte perimeeter-tulemüür juba filtreerib liiklust
- UFW võib tekitada probleeme LXD NAT/lxdbr0 võrguga
- Lihtsustab troubleshooting'ut

**Kui hiljem vaja (nt avalik server):** Vaata põhijuhendit `INSTALLATION.md` sektsioonid 5.1-5.3.

---

## 4. Kubernetes Profiili Loomine

### 4.1 Loo devops-lab-k8s Profiil

```bash
lxc profile create devops-lab-k8s
lxc profile edit devops-lab-k8s
```

**Lisa see YAML:**

```yaml
config:
  limits.cpu: "2"
  limits.memory: 5120MiB
  limits.memory.enforce: soft
  security.nesting: "true"
  security.privileged: "false"
  security.syscalls.intercept.mknod: "true"
  security.syscalls.intercept.setxattr: "true"
  linux.kernel_modules: ip_tables,ip6_tables,nf_nat,overlay,br_netfilter
  raw.lxc: |
    lxc.apparmor.profile=unconfined
    lxc.cap.drop=
    lxc.cgroup.devices.allow=a
    lxc.mount.auto=proc:rw sys:rw cgroup:rw
  cloud-init.user-data: |
    #cloud-config
    write_files:
      - path: /etc/apt/apt.conf.d/proxy.conf
        content: |
          Acquire::http::Proxy "http://cache1.sss:3128";
          Acquire::https::Proxy "http://cache1.sss:3128";
      - path: /etc/environment
        append: true
        content: |
          http_proxy=http://cache1.sss:3128
          https_proxy=http://cache1.sss:3128
          HTTP_PROXY=http://cache1.sss:3128
          HTTPS_PROXY=http://cache1.sss:3128
          no_proxy=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local
description: DevOps Lab K8s Profile - 5GB RAM, 2 CPU, Kubernetes + Proxy
devices:
  root:
    path: /
    pool: default
    type: disk
  kmsg:
    path: /dev/kmsg
    source: /dev/kmsg
    type: unix-char
name: devops-lab-k8s
```

**Salvesta:** `:wq` (vim) või `Ctrl+O, Enter, Ctrl+X` (nano)

### 4.2 Kontrolli Profiili

```bash
lxc profile show devops-lab-k8s
```

### 4.3 Profiili Haldamine

```bash
# Vaata kõiki profiile
lxc profile list

# Muuda profiili
lxc profile edit devops-lab-k8s

# Vaata, millised konteinerid kasutavad profiili
lxc profile show devops-lab-k8s | grep -A 100 "used_by"

# Eemalda profiil konteinerilt (kui vaja)
lxc profile remove <container-name> devops-lab-k8s

# Kustuta profiil (peab olema kasutamata!)
lxc profile delete devops-lab-k8s
```

**⚠️ Profiili ei saa kustutada, kui konteinerid kasutavad seda!**

Esmalt eemalda profiil kõigilt konteineritelt või kustuta konteinerid:

```bash
# Variant 1: Eemalda profiil konteineritelt
for c in $(lxc list -c n --format csv | grep k8s); do
  lxc profile remove $c devops-lab-k8s 2>/dev/null || true
done
lxc profile delete devops-lab-k8s

# Variant 2: Kustuta konteinerid ja siis profiil
lxc delete --force devops-k8s-student1
lxc delete --force devops-k8s-student2
lxc delete --force devops-k8s-student3
lxc profile delete devops-lab-k8s
```

---

## 5. Kubernetes Template Loomine

### 5.1 Base Konteineri Käivitamine

```bash
# Käivita Ubuntu 24.04 K8s profiiliga
lxc launch ubuntu:24.04 k8s-template -p default -p devops-lab-k8s

# Oota IP-d (30 sekundit)
sleep 30
lxc list k8s-template

# Logi sisse
lxc exec k8s-template -- bash
```

**Nüüd oled KONTEINERIS.**

### 5.2 Proxy Kontrollimine (Konteineris)

```bash
# Kontrolli, et cloud-init seadistas proxy
cat /etc/apt/apt.conf.d/proxy.conf
cat /etc/environment

# Testi
apt-get update
# Peaks töötama!
```

**Kui proxy EI tööta**, lisa käsitsi:

```bash
cat > /etc/apt/apt.conf.d/proxy.conf << 'EOF'
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF

cat >> /etc/environment << 'EOF'
http_proxy=http://cache1.sss:3128
https_proxy=http://cache1.sss:3128
HTTP_PROXY=http://cache1.sss:3128
HTTPS_PROXY=http://cache1.sss:3128
no_proxy=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local
EOF

source /etc/environment
apt-get update
```

### 5.3 Süsteemi Uuendamine (Konteineris)

```bash
apt-get update
apt-get upgrade -y

apt-get install -y \
  curl \
  wget \
  git \
  vim \
  nano \
  htop \
  ca-certificates \
  gnupg \
  lsb-release \
  software-properties-common \
  apt-transport-https
```

### 5.4 Docker Paigaldamine (Konteineris)

```bash
# Docker GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Docker repo
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installi Docker
apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Kontrolli
docker --version
```

### 5.5 KRIITILINE: containerd Downgrade (Konteineris)

```bash
# Downgrade containerd (LXD ühilduvus)
apt-get install -y --allow-downgrades containerd.io=1.7.28-1~ubuntu.24.04~noble
apt-mark hold containerd.io

# Kontrolli
containerd --version
# Peab olema: 1.7.28

# Taaskäivita Docker
systemctl restart docker

# Testi
docker run --rm hello-world
```

### 5.6 Docker Proxy Seadistamine (Konteineris)

```bash
# Docker daemon proxy
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/proxy.conf << 'EOF'
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF

# Reload ja restart
systemctl daemon-reload
systemctl restart docker

# Kontrolli
systemctl show --property=Environment docker
```

### 5.7 Kubernetes Tööriistade Paigaldamine (Konteineris)

```bash
# Kubernetes repo GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Kubernetes repo
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  tee /etc/apt/sources.list.d/kubernetes.list

# Installi kubeadm, kubelet, kubectl
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Kontrolli
kubeadm version
kubectl version --client
kubelet --version
```

### 5.8 Kernel Moodulite Seadistamine (Konteineris)

```bash
# Lae vajalikud moodulid
cat > /etc/modules-load.d/k8s.conf << 'EOF'
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Sysctl seadistused
cat > /etc/sysctl.d/k8s.conf << 'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
```

### 5.9 labuser Kasutaja Loomine (Konteineris)

```bash
# Loo kasutaja
useradd -m -s /bin/bash -u 1000 labuser
usermod -aG docker labuser
echo "labuser:temppassword" | chpasswd

# Kontrolli
id labuser
```

### 5.10 SSH Server (Konteineris)

```bash
apt-get install -y openssh-server

cat > /etc/ssh/sshd_config.d/99-lab.conf << 'EOF'
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
EOF

systemctl enable ssh
```

### 5.11 labuser Bash Konfiguratsioon (Konteineris)

```bash
su - labuser

cat >> ~/.bashrc << 'EOF'

# Proxy
export http_proxy=http://cache1.sss:3128
export https_proxy=http://cache1.sss:3128
export HTTP_PROXY=http://cache1.sss:3128
export HTTPS_PROXY=http://cache1.sss:3128
export no_proxy=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local

# Kubernetes
export KUBECONFIG=~/.kube/config
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'

# Docker AppArmor Workaround for LXD
docker() {
  case "$1" in
    run|exec|create)
      /usr/bin/docker "$1" --security-opt apparmor=unconfined "${@:2}"
      ;;
    *)
      /usr/bin/docker "$@"
      ;;
  esac
}
export -f docker

EOF

exit
```

### 5.12 Puhastamine ja Välju (Konteineris)

```bash
apt-get clean
apt-get autoremove -y
rm -rf /tmp/* /var/tmp/*
history -c
exit
```

**Nüüd oled tagasi HOST'is.**

---

## 6. Template Publitseerimine

```bash
# Peata konteiner
lxc stop k8s-template

# Publitseeri image'ina
lxc publish k8s-template --alias k8s-lab-base \
  description="K8s Lab Template: Ubuntu 24.04 + Docker + K8s 1.31 + Proxy"

# Kontrolli
lxc image list

# Kustuta template konteiner
lxc delete k8s-template

# Backup (valikuline)
mkdir -p ~/lxd-backups
lxc image export k8s-lab-base ~/lxd-backups/k8s-lab-base-$(date +%Y%m%d)
```

---

## 7. Õpilaskonteinerite Loomine

### 7.1 Student 1

```bash
# Loo konteiner
lxc launch k8s-lab-base devops-k8s-student1 -p default -p devops-lab-k8s

# Oota IP
sleep 15
lxc list devops-k8s-student1

# Sea parool
lxc exec devops-k8s-student1 -- bash -c 'echo "labuser:student1" | chpasswd'

# Port forwarding
lxc config device add devops-k8s-student1 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2211 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-k8s-student1 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6443 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student1 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30080 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student1 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30443 connect=tcp:127.0.0.1:30443 nat=true
```

### 7.2 Student 2

```bash
lxc launch k8s-lab-base devops-k8s-student2 -p default -p devops-lab-k8s
lxc exec devops-k8s-student2 -- bash -c 'echo "labuser:student2" | chpasswd'

lxc config device add devops-k8s-student2 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2212 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-k8s-student2 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6444 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student2 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30180 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student2 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30543 connect=tcp:127.0.0.1:30443 nat=true
```

### 7.3 Student 3

```bash
lxc launch k8s-lab-base devops-k8s-student3 -p default -p devops-lab-k8s
lxc exec devops-k8s-student3 -- bash -c 'echo "labuser:student3" | chpasswd'

lxc config device add devops-k8s-student3 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2213 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-k8s-student3 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6445 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student3 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30280 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student3 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30643 connect=tcp:127.0.0.1:30443 nat=true
```

### 7.4 Port Mapping Tabel

| Service | Internal | Student 1 | Student 2 | Student 3 |
|---------|----------|-----------|-----------|-----------|
| SSH | 22 | 2211 | 2212 | 2213 |
| K8s API | 6443 | 6443 | 6444 | 6445 |
| Ingress HTTP | 30080 | 30080 | 30180 | 30280 |
| Ingress HTTPS | 30443 | 30443 | 30543 | 30643 |

---

## 8. Kubernetes Klastri Initsialiseerimine (Iga Õpilane)

**See samm tehakse IGA konteineri sees eraldi!**

### 8.1 Logi Konteinerisse

```bash
# Host'ist
lxc exec devops-k8s-student1 -- su - labuser
```

### 8.2 Kubernetes Klastri Loomine

```bash
# Initsialiseeeri klaster (single-node)
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --ignore-preflight-errors=NumCPU,Mem

# Seadista kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Kontrolli
kubectl get nodes
# STATUS peaks olema NotReady (võrk puudub)
```

### 8.3 Pod Network (Flannel)

```bash
# Installi Flannel CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Oota, kuni valmis (1-2 min)
kubectl get nodes -w
# Oota kuni STATUS = Ready, siis Ctrl+C
```

### 8.4 Luba Pods Master Node'il

```bash
# Single-node klaster - luba scheduling master'il
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Kontrolli
kubectl get nodes
# NAME    STATUS   ROLES           AGE   VERSION
# ...     Ready    control-plane   ...   v1.31.x
```

### 8.5 Testi Klastrit

```bash
# Loo test pod
kubectl run nginx-test --image=nginx --port=80

# Oota, kuni töötab
kubectl get pods -w
# Oota STATUS = Running, siis Ctrl+C

# Kontrolli
kubectl get pods
kubectl describe pod nginx-test

# Puhasta
kubectl delete pod nginx-test
```

---

## 9. Testimine

### 9.1 Host'ist

```bash
# Konteinerite staatus
lxc list

# Ressursid
lxc list -c ns4M

# Port forwarding
netstat -tuln | grep -E ':(2211|2212|2213|6443)'
```

### 9.2 SSH Test (teisest masinast)

```bash
ssh labuser@<HOST-IP> -p 2211
# Parool: student1
```

### 9.3 Kubernetes Test (konteineris)

```bash
# Logi sisse
lxc exec devops-k8s-student1 -- su - labuser

# Kontrolli klastrit
kubectl cluster-info
kubectl get nodes
kubectl get pods -A

# Testi deployment
kubectl create deployment hello --image=nginx
kubectl get pods
kubectl delete deployment hello
```

---

## 10. Troubleshooting

### 10.1 Proxy Ei Tööta Konteineris

```bash
# Kontrolli
lxc exec devops-k8s-student1 -- cat /etc/apt/apt.conf.d/proxy.conf
lxc exec devops-k8s-student1 -- cat /etc/environment

# Lisa käsitsi kui puudub
lxc exec devops-k8s-student1 -- bash -c 'cat > /etc/apt/apt.conf.d/proxy.conf << EOF
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF'
```

### 10.2 Docker Pull Ei Tööta (Proxy)

```bash
lxc exec devops-k8s-student1 -- bash

# Kontrolli Docker proxy
systemctl show --property=Environment docker

# Kui puudub, lisa
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/proxy.conf << 'EOF'
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8"
EOF

systemctl daemon-reload
systemctl restart docker
```

### 10.3 kubeadm init Ebaõnnestub

```bash
# Vaata logisid
journalctl -xeu kubelet

# Reset ja proovi uuesti
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all
```

### 10.4 Pods Jäävad Pending/ImagePullBackOff

```bash
# Kontrolli põhjust
kubectl describe pod <pod-name>

# Kui "failed to pull image" - proxy probleem
# Kontrolli containerd proxy
cat /etc/systemd/system/containerd.service.d/proxy.conf

# Kui puudub
mkdir -p /etc/systemd/system/containerd.service.d
cat > /etc/systemd/system/containerd.service.d/proxy.conf << 'EOF'
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8"
EOF

systemctl daemon-reload
systemctl restart containerd
```

---

## 11. Paroolide Kokkuvõte

```bash
cat > ~/k8s-student-passwords.txt << 'EOF'
# Kubernetes Lab Passwords
# Host: <HOST-IP>

devops-k8s-student1:
  SSH: ssh labuser@<HOST-IP> -p 2211
  Password: student1
  K8s API: https://<HOST-IP>:6443

devops-k8s-student2:
  SSH: ssh labuser@<HOST-IP> -p 2212
  Password: student2
  K8s API: https://<HOST-IP>:6444

devops-k8s-student3:
  SSH: ssh labuser@<HOST-IP> -p 2213
  Password: student3
  K8s API: https://<HOST-IP>:6445
EOF

chmod 600 ~/k8s-student-passwords.txt
```

---

**Autor:** DevOps Lab Admin
**Versioon:** 1.0
**Viimane uuendus:** 2025-12-01
**Proxy:** cache1.sss:3128
