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
- [Kubernetes laborite seadistamine](#3-kubernetes-laborite-seadistamine-lab-3-10) ⭐ **Alusta siit!**
- [Labs failide sünkroniseerimine](#4-labs-failide-sünkroniseerimine)
- [Konteinerite haldamine](#5-konteinerite-haldamine)
- [Proxy konfiguratsiooni haldamine](#6-proxy-konfiguratsiooni-haldamine)
- [Kernel moodulite haldamine (HOST)](#7-kernel-moodulite-haldamine-host)
- [SSH ja turvalisus](#8-ssh-ja-turvalisus-sisevõrk)
- [Kubernetes spetsiifilised käsud](#9-kubernetes-spetsiifilised-käsud)
- [Ressursside monitooring](#10-ressursside-monitooring)
- [Backup ja taastamine](#11-backup-ja-taastamine)
- [Template uuendamine](#12-template-uuendamine-k8s)
- [Probleemide lahendamine](#13-probleemide-lahendamine-k8s-proxy)
- [Kasulikud käsud](#14-kasulikud-käsud-k8s)
- [Quick reference](#15-quick-reference-k8s)

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


## 3. Kubernetes Laborite Seadistamine (Lab 3-10)

**⚠️ EELDUS:** [HOST-SETUP-PROXY.md](HOST-SETUP-PROXY.md) on täidetud (host valmis, proxy töötab, LXD paigaldatud, **KERNEL MOODULID LAADITUD**!)

**Mida see sektsioon hõlmab:**
- ✅ devops-lab-k8s profiili loomine (5GB RAM, 2 CPU, kernel modules)
- ✅ K8s template'i loomine (k8s-lab-base)
- ✅ Esimeste 3 õpilaskonteineri loomine MANUAALSELT (student1-3 + K8s init)
- 🔧 Automatiseeritud setup skript (VALIKULINE - pärast manuaalset kinnitust! ⏱️ ~30 min!)
- ➕ Täiendavate õpilaste lisamine (student4-6)

**Workflow:**
1. Loo LXD profiil (3.0) → 2. Loo K8s template (3.1) → 3. Loo student1-3 MANUAALSELT + K8s init (3.2-3.3) → 4. Valikuline: automatiseeri (3.4) → 5. Lisa student4-6 (3.5)

---

### 3.0 LXD Profiili Loomine (devops-lab-k8s)

**⚠️ KOHUSTUSLIK ESMALT:** Enne template'i loomist pead looma LXD profiili!

**⚠️ KRIITILINE EELDUS:** HOST-SETUP-PROXY.md sektsioon 5 peab olema täidetud (kernel moodulid laaditud HOST'is)!

#### 3.0.1 Loo devops-lab-k8s Profiil

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
description: DevOps Lab K8s Profile - 5GB RAM, 2 CPU, Kubernetes support
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

#### 3.0.2 Kontrolli Profiili

```bash
lxc profile show devops-lab-k8s
lxc profile list
```

#### 3.0.3 Profiili Selgitus

| Setting | Väärtus | Selgitus |
|---------|---------|----------|
| limits.cpu | "2" | 2 CPU cores (K8s vajab rohkem kui Docker) |
| limits.memory | 5120MiB | 5GB RAM (K8s vajab rohkem ressursse) |
| security.nesting | "true" | Docker-in-Docker support (KRIITILINE!) |
| linux.kernel_modules | ip_tables,... | K8s vajalikud kernel moodulid |
| raw.lxc | lxc.apparmor.profile=unconfined | K8s vajab rohkem õigusi |
| kmsg device | /dev/kmsg | K8s logide jaoks |

**Miks devops-lab-k8s, mitte devops-lab?**
- Kubernetes vajab rohkem ressursse: 5GB vs 2.5GB RAM, 2 vs 1 CPU
- K8s vajab spetsiifilisi kernel mooduleid (ip_tables, overlay, br_netfilter)
- K8s vajab kmsg device'i logide jaoks
- K8s vajab lihtsustatud AppArmor profiili (unconfined)

---

### 3.1 Kubernetes Template Loomine (k8s-lab-base)

**⚠️ MANUAALNE PROTSESS:** See on samm-sammult juhend K8s template'i loomiseks. Peale seda saad luua õpilaskonteinereid template'ist (sektsioonid 3.2-3.3).

**⚠️ HOIATUS:** See protsess võtab aega ~30-45 minutit (K8s tööriistade paigaldamine, konfigureerimine).

#### 3.1.1 Base Konteineri Käivitamine

```bash
# Käivita Ubuntu 24.04 devops-lab-k8s profiiliga
lxc launch ubuntu:24.04 k8s-template -p default -p devops-lab-k8s

# Oota IP-d (30 sekundit)
sleep 30
lxc list k8s-template

# Logi sisse
lxc exec k8s-template -- bash
```

**Nüüd oled KONTEINERIS.**

#### 3.1.2 Proxy Seadistamine (Konteineris)

**⚠️ OLULINE:** Seadista proxy ENNE apt-get käske!

```bash
# 1. APT proxy
cat > /etc/apt/apt.conf.d/proxy.conf << 'EOF'
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF

# 2. Keskkonna muutujad (kirjuta kogu fail üle)
cat > /etc/environment << 'EOF'
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
http_proxy="http://cache1.sss:3128"
https_proxy="http://cache1.sss:3128"
HTTP_PROXY="http://cache1.sss:3128"
HTTPS_PROXY="http://cache1.sss:3128"
no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"
EOF

# 3. Lae muutujad KOHE aktiivseks
source /etc/environment

# 4. Kontrolli
echo "http_proxy=$http_proxy"
echo "https_proxy=$https_proxy"
echo "no_proxy=$no_proxy"

# 5. Tee seaded püsivaks (login shell jaoks)
cat > /etc/profile.d/proxy.sh << 'EOF'
export http_proxy="http://cache1.sss:3128"
export https_proxy="http://cache1.sss:3128"
export HTTP_PROXY="http://cache1.sss:3128"
export HTTPS_PROXY="http://cache1.sss:3128"
export no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"
EOF
chmod +x /etc/profile.d/proxy.sh

# 6. Testi
apt-get update
# Kui töötab, jätka järgmise sammuga
```

**📝 Märkus - K8s template no_proxy:**

**⚠️ KRIITILINE:** Kubernetes template PEAB sisaldama `.svc,.cluster.local` no_proxy seadistuses!

```bash
# ✅ K8s template (Lab 3-10) - KRIITILINE:
no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"

# ❌ Docker template (Lab 1-2) - EI sisalda:
no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
```

**Miks vajalik?**
- `.svc` - Kubernetes service DNS suffix (pod-to-service suhtlus)
- `.cluster.local` - Täielik K8s cluster DNS suffix
- Ilma nendeta läheksid pod-to-service ühendused proxy kaudu → ERROR!

#### 3.1.3-3.1.6 Süsteemi Uuendamine ja Tööriistad

[Täpselt sama nagu ADMIN-GUIDE-DOCKER-PROXY.md sektsioonid 3.1.3-3.1.6]

```bash
# 3.1.3: apt-get update && upgrade
# 3.1.4: Java 21
# 3.1.5: Node.js 20
# 3.1.6: Diagnostika tööriistad (jq, nmap, tcpdump, netcat-openbsd, dnsutils, net-tools)

# [Täielikud käsud: vt K8S-INSTALLATION.md sektsioonid 5.3, 5.3a, 5.3b, 5.3c]
```

#### 3.1.7-3.1.9 Docker Paigaldamine

[Täpselt sama nagu ADMIN-GUIDE-DOCKER-PROXY.md sektsioonid 3.1.7-3.1.9]

```bash
# 3.1.7: Docker paigaldamine
# 3.1.8: containerd downgrade 1.7.28 (KRIITILINE!)
# 3.1.9: Docker proxy seadistamine

# [Täielikud käsud: vt K8S-INSTALLATION.md sektsioonid 5.4, 5.5, 5.6]
```

#### 3.1.10 Kubernetes Tööriistade Paigaldamine (Konteineris)

**Kubernetes 1.31:**

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

**Helm 3:**

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Kontrolli
helm version

# Lisa populaarsed repo'd
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

**Kustomize:**

```bash
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
mv kustomize /usr/local/bin/

# Kontrolli
kustomize version
```

**Trivy (Security scanning):**

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Kontrolli
trivy version
```

**Terraform:**

```bash
# Lisa HashiCorp repo
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# Installi Terraform
apt-get update
apt-get install -y terraform

# Kontrolli
terraform version
```

#### 3.1.11 labuser Kasutaja Loomine (Konteineris)

[Sama nagu Docker template - vt ADMIN-GUIDE-DOCKER-PROXY.md sektsioon 3.1.10]

```bash
useradd -m -s /bin/bash -u 1001 labuser
usermod -aG docker labuser
echo "labuser:temppassword" | chpasswd

id labuser
# uid=1001(labuser) gid=1001(labuser)
```

#### 3.1.12 SSH Server (Konteineris)

[Sama nagu Docker template - vt ADMIN-GUIDE-DOCKER-PROXY.md sektsioon 3.1.11]

```bash
apt-get install -y openssh-server

cat > /etc/ssh/sshd_config.d/99-lab.conf << 'EOF'
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
EOF

systemctl enable ssh
```

#### 3.1.13 labuser Bash Konfiguratsioon (Konteineris)

**K8s template (SISALDAB Kubernetes, Helm, Terraform aliased!):**

```bash
su - labuser

cat >> ~/.bashrc << 'EOF'

# Proxy (K8s spetsiifiline - sisaldab .svc,.cluster.local)
export http_proxy=http://cache1.sss:3128
export https_proxy=http://cache1.sss:3128
export HTTP_PROXY=http://cache1.sss:3128
export HTTPS_PROXY=http://cache1.sss:3128
export no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16,.svc,.cluster.local"

# Default Editor
export EDITOR=vim
export VISUAL=vim

# Java Environment (todo-service jaoks)
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Kubernetes
export KUBECONFIG=~/.kube/config
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kgaa='kubectl get all -A'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kdel='kubectl delete'
alias kaf='kubectl apply -f'

# Helm
alias h='helm'
alias hls='helm list -A'
alias hi='helm install'
alias hu='helm upgrade'
alias hd='helm delete'

# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'

# Docker Aliases
alias docker-stop-all="docker stop \$(docker ps -aq) 2>/dev/null || echo 'No containers running'"
alias docker-clean="docker system prune -af --volumes"

# Lab Aliases
alias labs-reset="~/labs/labs-reset.sh"

# Resource Check (K8s version)
alias check-resources="echo '=== RAM ===' && free -h && echo && echo '=== DISK ===' && df -h / && echo && echo '=== K8s Nodes ===' && kubectl get nodes 2>/dev/null || echo 'K8s not initialized' && echo && echo '=== K8s Pods ===' && kubectl get pods -A 2>/dev/null || true"

# Docker AppArmor Workaround for LXD
docker() {
  case "\$1" in
    run|exec|create)
      /usr/bin/docker "\$1" --security-opt apparmor=unconfined "\${@:2}"
      ;;
    *)
      /usr/bin/docker "\$@"
      ;;
  esac
}
export -f docker

EOF

exit
```

#### 3.1.14 Labs Kausta Ettevalmistus (Konteineris)

```bash
# Loo labs kataloog (sünkroniseeritakse hiljem)
mkdir -p /home/labuser/labs
chown -R labuser:labuser /home/labuser/labs
```

#### 3.1.15 Puhastamine (Konteineris)

```bash
apt-get clean
apt-get autoremove -y
rm -rf /tmp/* /var/tmp/*
history -c
exit
```

**Nüüd oled tagasi HOST'is.**

#### 3.1.16 Template Publitseerimine (HOST)

```bash
# Peata konteiner
lxc stop k8s-template

# Publitseeri image'ina
lxc publish k8s-template --alias k8s-lab-base \
  description="K8s Lab Template: Ubuntu 24.04 + Docker + K8s 1.31 + Helm + Terraform + Trivy + Kustomize + Proxy ($(date +%Y-%m-%d))"

# Kontrolli
lxc image list

# Kustuta template konteiner
lxc delete k8s-template

# Backup (valikuline, soovitatud)
mkdir -p ~/lxd-backups
lxc image export k8s-lab-base ~/lxd-backups/k8s-lab-base-$(date +%Y%m%d)
```

**✅ K8s template on valmis!** Järgmises sammus loome esimesed õpilaskonteinerid ja initsialiseerime Kubernetes klastri.

---

### 3.2 Student1 Loomine (Täielik MANUAALNE K8s Protsess)

**⚠️ OLULINE:** Järgi seda sektsiooni täpselt, samm-sammult. See on BAAS student2-3 jaoks!

**Eeldus:** k8s-lab-base template on loodud (sektsioon 3.1).

**⏱️ Ajakulu:** ~15-20 minutit (sh K8s init ~5-10 min).

#### 3.2.1 Konteineri Käivitamine

```bash
# Loo konteiner template'ist
lxc launch k8s-lab-base devops-k8s-student1 -p default -p devops-lab-k8s

# Oota IP (20-30 sek)
sleep 30
lxc list devops-k8s-student1
```

#### 3.2.2 Parooli Seadistamine

```bash
lxc exec devops-k8s-student1 -- bash -c 'echo "labuser:student1" | chpasswd'
```

#### 3.2.3 Port Forwarding (SSH + K8s + Ingress)

```bash
# SSH
lxc config device add devops-k8s-student1 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2211 connect=tcp:127.0.0.1:22 nat=true

# K8s API Server
lxc config device add devops-k8s-student1 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6443 connect=tcp:127.0.0.1:6443 nat=true

# Ingress HTTP
lxc config device add devops-k8s-student1 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30080 connect=tcp:127.0.0.1:30080 nat=true

# Ingress HTTPS
lxc config device add devops-k8s-student1 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30443 connect=tcp:127.0.0.1:30443 nat=true
```

#### 3.2.4 Kubernetes Klastri Initialiseerimine (Konteineris)

**⚠️ KRIITILINE:** Iga õpilaskonteiner peab oma K8s clusteri initima!

```bash
# Logi konteinerisse (labuser)
lxc exec devops-k8s-student1 -- su - labuser

# Initsialiseeiri klaster (single-node)
sudo kubeadm init \
  --pod-network-cidr=10.244.0.0/16 \
  --ignore-preflight-errors=NumCPU,Mem

# Seadista kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Kontrolli
kubectl get nodes
# STATUS peaks olema NotReady (võrk puudub veel)
```

#### 3.2.5 Pod Network (Flannel CNI)

```bash
# Installi Flannel CNI
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Oota, kuni valmis (1-2 min)
kubectl get nodes -w
# Oota kuni STATUS = Ready, siis Ctrl+C
```

#### 3.2.6 Luba Pods Master Node'il

```bash
# Single-node klaster - luba scheduling master'il
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Kontrolli
kubectl get nodes
# NAME    STATUS   ROLES           AGE   VERSION
# ...     Ready    control-plane   ...   v1.31.x
```

#### 3.2.7 Testi Klastrit

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

# Logi välja
exit
```

#### 3.2.8 Labs Failide Sünkroniseerimine (HOST'ist)

```bash
# Sync labs (kasuta sektsioonis 4 loodud skripti)
~/scripts/sync-k8s-labs.sh devops-k8s-student1
```

#### 3.2.9 Kontrollimine

```bash
# SSH test (HOST'ist)
ssh labuser@<HOST-IP> -p 2211
# Parool: student1

# K8s test konteineris
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl cluster-info'
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get nodes'
lxc exec devops-k8s-student1 -- su - labuser -c 'kubectl get pods -A'

# Labs kataloog
lxc exec devops-k8s-student1 -- ls -la /home/labuser/labs/

# Proxy kontroll
lxc exec devops-k8s-student1 -- su - labuser -c 'env | grep -i no_proxy'
# Peab sisaldama: .svc,.cluster.local

# Port forwarding test
netstat -tuln | grep -E ':(2211|6443|30080|30443)'
```

**✅ Student1 on valmis ja K8s cluster toimib!**

---

### 3.3 Student2 ja Student3 Loomine (Lühike + K8s Init)

**Märkus:** Analoogselt student1-le, aga erinevad pordid. **IGA ÕPILANE PEAB OMA K8s CLUSTERI INITMA!**

#### 3.3.1 Student2

```bash
# Loo konteiner
lxc launch k8s-lab-base devops-k8s-student2 -p default -p devops-lab-k8s

# Parool
lxc exec devops-k8s-student2 -- bash -c 'echo "labuser:student2" | chpasswd'

# Port forwarding (pordid: SSH 2212, K8s API 6444, Ingress HTTP 30180, HTTPS 30543)
lxc config device add devops-k8s-student2 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2212 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-k8s-student2 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6444 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student2 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30180 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student2 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30543 connect=tcp:127.0.0.1:30443 nat=true

# K8s cluster init (KONTEINERIS!)
lxc exec devops-k8s-student2 -- su - labuser -c "
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU,Mem

mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo 'Waiting for node to be Ready...'
kubectl wait --for=condition=Ready node --all --timeout=120s || true

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
"

# Sync labs
~/scripts/sync-k8s-labs.sh devops-k8s-student2

# Test
ssh labuser@<HOST-IP> -p 2212
# Parool: student2
```

#### 3.3.2 Student3

```bash
# Loo konteiner
lxc launch k8s-lab-base devops-k8s-student3 -p default -p devops-lab-k8s

# Parool
lxc exec devops-k8s-student3 -- bash -c 'echo "labuser:student3" | chpasswd'

# Port forwarding (pordid: SSH 2213, K8s API 6445, Ingress HTTP 30280, HTTPS 30643)
lxc config device add devops-k8s-student3 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2213 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-k8s-student3 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6445 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student3 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30280 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student3 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30643 connect=tcp:127.0.0.1:30443 nat=true

# K8s cluster init (KONTEINERIS!)
lxc exec devops-k8s-student3 -- su - labuser -c "
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU,Mem

mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

echo 'Waiting for node to be Ready...'
kubectl wait --for=condition=Ready node --all --timeout=120s || true

kubectl taint nodes --all node-role.kubernetes.io/control-plane-
"

# Sync labs
~/scripts/sync-k8s-labs.sh devops-k8s-student3

# Test
ssh labuser@<HOST-IP> -p 2213
# Parool: student3
```

**✅ Student1-3 on valmis ja K8s clusterid toimivad!**

---

### 3.4 Automatiseeritud Setup Skript (VALIKULINE - pärast manuaalset testimist!)

**⚠️ OLULINE:** See on VALIKULINE! Admin peab esmalt manuaalselt läbi tegema 3.2 ja 3.3 ning kinnitama, et K8s cluster toimib. Alles siis võib lisada automatiseeritud skripti.

**⏱️ HOIATUS:** K8s init võtab aega (~5-10 min per student). Skript võib kesta ~30-40 minutit!

**Miks manuaalne esmalt?**
- Saad õppida, kuidas K8s cluster tekib
- Saad tuvastada probleeme enne automatiseerimist
- K8s init protsess on kriitiline - peab näema, mis juhtub

**Kui manuaalne protsess töötab:**

```bash
cat > ~/scripts/setup-k8s-students.sh << 'EOFSCRIPT'
#!/bin/bash
# Setup K8s students 1-3 automatically

set -e

echo "====================================="
echo "Setting up K8s students 1-3"
echo "⏱️  Estimated time: 30-40 minutes"
echo "====================================="

# Port mappings
declare -A SSH_PORTS=([1]=2211 [2]=2212 [3]=2213)
declare -A API_PORTS=([1]=6443 [2]=6444 [3]=6445)
declare -A HTTP_PORTS=([1]=30080 [2]=30180 [3]=30280)
declare -A HTTPS_PORTS=([1]=30443 [2]=30543 [3]=30643)

for i in 1 2 3; do
  NAME="devops-k8s-student$i"
  PASSWORD="student$i"

  echo ""
  echo "========================================="
  echo ">>> Creating $NAME <<<"
  echo "========================================="

  # Launch container
  lxc launch k8s-lab-base $NAME -p default -p devops-lab-k8s

  # Wait for container
  echo "Waiting for container to start..."
  sleep 30

  # Set password
  lxc exec $NAME -- bash -c "echo 'labuser:$PASSWORD' | chpasswd"

  # Port forwarding
  lxc config device add $NAME ssh-proxy proxy \
    listen=tcp:0.0.0.0:${SSH_PORTS[$i]} connect=tcp:127.0.0.1:22 nat=true

  lxc config device add $NAME k8s-api-proxy proxy \
    listen=tcp:0.0.0.0:${API_PORTS[$i]} connect=tcp:127.0.0.1:6443 nat=true

  lxc config device add $NAME ingress-http-proxy proxy \
    listen=tcp:0.0.0.0:${HTTP_PORTS[$i]} connect=tcp:127.0.0.1:30080 nat=true

  lxc config device add $NAME ingress-https-proxy proxy \
    listen=tcp:0.0.0.0:${HTTPS_PORTS[$i]} connect=tcp:127.0.0.1:30443 nat=true

  echo "✅ $NAME created!"
  echo ""
  echo "Now initializing K8s cluster (this takes ~5-10 minutes)..."

  # K8s cluster init
  lxc exec $NAME -- su - labuser -c "
    echo '[1/6] Initializing K8s cluster...'
    sudo kubeadm init \
      --pod-network-cidr=10.244.0.0/16 \
      --ignore-preflight-errors=NumCPU,Mem

    echo '[2/6] Configuring kubectl...'
    mkdir -p \$HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
    sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

    echo '[3/6] Installing Flannel CNI...'
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    echo '[4/6] Waiting for node to be Ready (may take 1-2 min)...'
    kubectl wait --for=condition=Ready node --all --timeout=180s || echo 'Warning: Node not ready yet'

    echo '[5/6] Removing taint...'
    kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

    echo '[6/6] Verifying cluster...'
    kubectl get nodes
    kubectl get pods -A

    echo '✅ K8s cluster ready!'
  "

  echo "✅ $NAME K8s cluster initialized!"
done

echo ""
echo "Syncing labs to all K8s students..."
~/scripts/sync-k8s-labs.sh

echo ""
echo "========================================="
echo "✅ All K8s students ready!"
echo "========================================="
lxc list | grep devops-k8s-student
EOFSCRIPT

chmod +x ~/scripts/setup-k8s-students.sh
```

**Kasutamine:**
```bash
# HOIATUS: Võtab aega ~30-40 minutit!
~/scripts/setup-k8s-students.sh
```

**Kontrollimine pärast automatiseeritud setup'i:**
```bash
# Vaata kõiki
lxc list | grep devops-k8s-student

# Testi SSH
ssh labuser@<HOST-IP> -p 2211
ssh labuser@<HOST-IP> -p 2212
ssh labuser@<HOST-IP> -p 2213

# Testi K8s
for c in devops-k8s-student{1..3}; do
  echo "=== $c ==="
  lxc exec $c -- su - labuser -c 'kubectl get nodes'
  lxc exec $c -- su - labuser -c 'kubectl get pods -A'
done
```

---

### 3.5 Uue Õpilase Lisamine (Student4-6)

**Märkus:** Süsteem toetab kuni 6 õpilast. Alltoodud näited student4, student5, student6 jaoks.

#### 3.5.1 Student4 Lisamine

```bash
# 1. Käivita konteiner
lxc launch k8s-lab-base devops-k8s-student4 -p default -p devops-lab-k8s

# 2. Oota IP
sleep 30
lxc list devops-k8s-student4

# 3. Sea parool
lxc exec devops-k8s-student4 -- bash -c 'echo "labuser:student4" | chpasswd'

# 4. Port forwarding (pordid: SSH 2214, K8s API 6446, Ingress HTTP 30380, HTTPS 30743)
lxc config device add devops-k8s-student4 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2214 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-k8s-student4 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6446 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student4 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30380 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student4 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30743 connect=tcp:127.0.0.1:30443 nat=true

# 5. K8s init (sama nagu student1-3)
lxc exec devops-k8s-student4 -- su - labuser -c "
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU,Mem
mkdir -p \$HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl wait --for=condition=Ready node --all --timeout=120s || true
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
"

# 6. Sync labs
~/scripts/sync-k8s-labs.sh devops-k8s-student4

# 7. Testi SSH
ssh labuser@<HOST-IP> -p 2214
# Password: student4

# 8. Testi K8s
lxc exec devops-k8s-student4 -- su - labuser -c 'kubectl get nodes'
```

#### 3.5.2 Student5 ja Student6 Lisamine

Analoogselt student4-le, kasuta järgmisi porte:
- **Student5:** SSH 2215, K8s API 6447, Ingress HTTP 30480, Ingress HTTPS 30843
- **Student6:** SSH 2216, K8s API 6448, Ingress HTTP 30580, Ingress HTTPS 30943

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


## 5. Konteinerite Haldamine

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


## 6. Proxy Konfiguratsiooni Haldamine

### 6.1 Host Proxy Seadistamine

Sama nagu Docker juhendis. Vaata ADMIN-GUIDE-DOCKER-PROXY.md sektsioon 6.1.

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

### 6.2 Konteineri Proxy Seadistamine

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

### 6.3 Proxy Testimine

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


## 7. Kernel Moodulite Haldamine (HOST)

### 7.1 Ülevaade

**⚠️ KRIITILINE:** Kernel mooduleid EI SAA laadida konteinerist! LXD konteinerid jagavad HOST'i kerneli.

**Vajalikud moodulid K8s jaoks:**
- `overlay` - OverlayFS support (Docker & Kubernetes)
- `br_netfilter` - Bridge netfilter support (Kubernetes networking)

### 7.2 Kernel Moodulite Laadimise (HOST'is)

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

### 7.3 Sysctl Seadistused (HOST'is)

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

### 7.4 Verifitseerimine Konteineris

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


## 8. SSH ja Turvalisus (Sisevõrk)

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


## 9. Kubernetes Spetsiifilised Käsud

### 9.1 Kubernetes Cluster Initialization (Iga Õpilane)

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
- Kui Flannel pod'id ei käivitu → Kontrolli kernel mooduleid HOST'is (vt sektsioon 7)
- Kui image pull ebaõnnestub → Kontrolli containerd proxy't (vt sektsioon 6.2)

### 9.2 Kubernetes Port Forwarding

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

### 9.3 Port Mapping Tabel (kuni 6 õpilast)

| Service | Internal | Student 1 | Student 2 | Student 3 | Student 4 | Student 5 | Student 6 |
|---------|----------|-----------|-----------|-----------|-----------|-----------|-----------|
| SSH | 22 | 2211 | 2212 | 2213 | 2214 | 2215 | 2216 |
| K8s API | 6443 | 6443 | 6444 | 6445 | 6446 | 6447 | 6448 |
| Ingress HTTP | 30080 | 30080 | 30180 | 30280 | 30380 | 30480 | 30580 |
| Ingress HTTPS | 30443 | 30443 | 30543 | 30643 | 30743 | 30843 | 30943 |

### 9.4 Kubernetes Monitooring

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


## 10. Ressursside Monitooring

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


## 11. Backup ja Taastamine

Sama nagu Docker juhendis + K8s spetsiifiline:

### 11.1 Kubernetes Cluster Backup

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


## 12. Template Uuendamine (K8s)

### 12.1 Template Uuendamise Protsess

```bash
# 1. Loo ajutine konteiner
lxc launch k8s-lab-base temp-k8s-update -p default -p devops-lab-k8s

# 2. Logi sisse
lxc exec temp-k8s-update -- bash

# 3-6. [Sama nagu Docker template: proxy seadistus, apt update/upgrade, containerd downgrade]
# Vaata ADMIN-GUIDE-DOCKER-PROXY.md sektsioon 10.2, sammud 3-6

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
# Vaata ADMIN-GUIDE-DOCKER-PROXY.md sektsioon 10.2, sammud 8-10

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


## 13. Probleemide Lahendamine (K8s + Proxy)

### 13.1 Proxy Probleemid

Sama nagu Docker juhendis: 9.1-9.5 (Proxy ei tööta konteineris, Docker pull, containerd pull, proxy login shellis, containerd versioon)

### 13.2 kubeadm init Ebaõnnestub

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

### 13.3 Pods Jäävad Pending/ImagePullBackOff (Proxy)

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

### 13.4 Kubernetes Services Unreachable (no_proxy Vale)

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

### 13.5 Flannel Pod'id Ei Käivitu

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

# Kui puudub, laadi moodulid (vt sektsioon 7.2)
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

### 13.6 kubectl Ei Tööta (kubeconfig Puudu)

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


## 14. Kasulikud Käsud (K8s)

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


## 15. Quick Reference (K8s)

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
