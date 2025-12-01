# LXD DevOps Laborikeskkonna Paigaldusjuhend

## Ülevaade

See juhend kirjeldab, kuidas paigaldada LXD-põhine DevOps laborikeskkond täiesti uuele Ubuntu 24.04 serverile või sülearvutile.

**Versioon:** 1.0
**Viimane uuendus:** 2025-01-28
**Eeldatav aeg:** 2-4 tundi (manuaalne paigaldus)

---

## Sisukord

1. [Süsteeminõuded](#1-süsteeminõuded)
2. [VPS vs Laptop Deployment](#2-vps-vs-laptop-deployment)
3. [Süsteemi Ettevalmistus](#3-süsteemi-ettevalmistus)
4. [LXD Paigaldamine](#4-lxd-paigaldamine)
5. [Turvalisuse Seadistamine](#5-turvalisuse-seadistamine)
6. [DevOps Lab Profiili Loomine](#6-devops-lab-profiili-loomine)
7. [Template Image Loomine](#7-template-image-loomine)
8. [Õpilaskonteinerite Loomine](#8-õpilaskonteinerite-loomine)
9. [Labs Failide Sünkroniseerimine](#9-labs-failide-sünkroniseerimine)
10. [Laptop/Portable Deployment](#10-laptopportable-deployment)
11. [Testimine](#11-testimine)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Süsteeminõuded

### Miinimum Nõuded

#### Docker Laboritele (Lab 1-2)

| Komponent | Miinimum | Soovitatav | Ideaalne |
|-----------|----------|------------|----------|
| **OS** | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS Server |
| **RAM** | 6GB | 8GB | 12GB+ |
| **CPU** | 2 cores | 4 cores | 4+ cores |
| **Disk** | 40GB | 80GB | 100GB+ SSD |
| **Võrk** | 1 IP | Staatiline IP | Staatiline avalik IP |
| **Virtualization** | AMD-V või VT-x | AMD-V või VT-x | AMD-V/VT-x enabled |

#### Kubernetes Laboritele (Lab 3-10)

| Komponent | Miinimum | Soovitatav | Ideaalne |
|-----------|----------|------------|----------|
| **OS** | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS Server |
| **RAM** | 16GB | 24GB | 32GB+ |
| **CPU** | 4 cores | 6 cores | 8+ cores |
| **Disk** | 80GB | 120GB | 200GB+ SSD |
| **Võrk** | 1 IP | Staatiline IP | Staatiline avalik IP |
| **Virtualization** | AMD-V või VT-x | AMD-V või VT-x | AMD-V/VT-x enabled |

**Märkus:** Kubernetes komponentide (kubelet, kube-proxy, etcd) ja monitoring tööriistade (Prometheus, Grafana) tõttu on mälu- ja CPU nõuded märgatavalt kõrgemad.

### Ressursside Kalkulaator

#### Docker Laboritele (Lab 1-2)

**Iga õpilane vajab:**
- RAM: 2-2.5GB
- CPU: 1 core (shared)
- Disk: ~10-15GB (Docker images kaasa arvatud)

**Näited:**

```
3 õpilast (Docker):
  RAM: 3 × 2.5GB = 7.5GB + 1GB host = 8.5GB total
  CPU: 2 cores minimum (3-4 soovitatav)
  Disk: 3 × 15GB + 20GB host = 65GB

5 õpilast (Docker):
  RAM: 5 × 2.5GB = 12.5GB + 1GB host = 13.5GB total
  CPU: 4 cores minimum
  Disk: 5 × 15GB + 20GB host = 95GB
```

#### Kubernetes Laboritele (Lab 3-10)

**Iga õpilane vajab:**
- RAM: 4-6GB (Kubernetes komponentid + pods)
- CPU: 2 cores (shared)
- Disk: ~20-30GB (Docker + Kubernetes images)

**Näited:**

```
3 õpilast (Kubernetes):
  RAM: 3 × 5GB = 15GB + 2GB host = 17GB total
  CPU: 4 cores minimum (6 soovitatav)
  Disk: 3 × 25GB + 30GB host = 105GB

4 õpilast (Kubernetes, 24GB server):
  RAM: 4 × 5GB = 20GB + 2GB host = 22GB total
  CPU: 6 cores minimum (8 soovitatav)
  Disk: 4 × 25GB + 30GB host = 130GB

5 õpilast (Kubernetes, 32GB server):
  RAM: 5 × 5GB = 25GB + 2GB host = 27GB total
  CPU: 8 cores minimum
  Disk: 5 × 25GB + 30GB host = 155GB
```

**Kubernetes Mälu Jaotus Konteineris:**
```
- Kubernetes süsteemikomponendid (kubelet, kube-proxy): ~500MB
- Docker daemon: ~200MB
- Control plane (kui single-node): ~1-1.5GB
- Workload pods (rakendused, monitoring): ~2-3GB
- OS + cache: ~500MB
KOKKU: ~4.5-6GB
```

### Kontrollimise Käsud

```bash
# CPU cores ja virtualization
lscpu | grep -E 'CPU\(s\)|Virtualization|Model name'

# RAM
free -h

# Disk
df -h

# OS versioon
lsb_release -a
```

**Kriitilised kontrollid:**

```bash
# 1. Virtualization peab olema enabled
egrep -c '(vmx|svm)' /proc/cpuinfo
# Tulemus peaks olema > 0

# 2. Kernel versioon (peaks olema 6.x+)
uname -r

# 3. Swap kontroll
swapon --show
# Kui tühi, tuleb swap luua
```

---

## 2. VPS vs Laptop Deployment

### Võrdlus

| Aspekt | VPS (Produktsioon) | Laptop (Arendus/Koolitus) |
|--------|-------------------|---------------------------|
| **IP aadress** | Staatiline, avalik | Dünaamiline, kohalik |
| **Ligipääs** | Internet (24/7) | Localhost/LAN |
| **Ressursid** | Fikseeritud | Piiratud (battery) |
| **Võrk** | Üks võrk | Muutub (WiFi, kodu, töö) |
| **Kasutuskoht** | Produktsioon | Arendus, demo, koolitus |
| **Kulud** | $10-50/kuu | $0 (olemasolev HW) |
| **Usaldusväärsus** | 99.9% uptime | Kui arvuti sees |

### Millal Kasutada VPS'i?

✅ **VPS on ÕIGE valik kui:**
- Õpilased asuvad erinevates asukohtades
- Vajad 24/7 ligipääsu
- On vaja stabiilset, avalikku IP'd
- Õpilasi on 3+
- Koolitus kestab nädalaid/kuid

### Millal Kasutada Laptop'i?

✅ **Laptop on ÕIGE valik kui:**
- Demo/esitlus klassiruumis
- Isiklik arendus/õppimine
- Lühiajaline koolitus (1-2 päeva)
- Kõik ühes võrgus (sama WiFi)
- Ei vaja avalikku ligipääsu

**Märkus:** Laptop deployment spetsiifilised juhised on [Peatükk 10](#10-laptopportable-deployment).

---

## 3. Süsteemi Ettevalmistus

### 3.1 Ühendus Serveriga

**VPS:**
```bash
# SSH serverisse (kasuta VPS provider'i antud IP'd)
ssh root@<VPS-IP>
```

**Laptop:**
```bash
# Logi kohalikku terminalisse
# Või ava Terminal rakendus Ubuntu Desktop'is
```

### 3.2 Süsteemi Uuendamine

```bash
# 1. Uuenda pakettide nimekirja
sudo apt-get update

# 2. Upgrade kõik paketid
sudo apt-get upgrade -y

# 3. Installi põhilised tööriistad
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

# 4. Taaskäivita (kui kernel uuendus)
# MÄRKUS: VPS'is võib taaskäivitus katkestada SSH
sudo reboot
# Oota 1-2 minutit ja ühenda uuesti
```

### 3.3 Hostname Seadistamine (Valikuline)

```bash
# VPS
sudo hostnamectl set-hostname devops-lab-server

# Laptop
sudo hostnamectl set-hostname devops-lab-laptop

# Kontrolli
hostnamectl
```

### 3.4 Swap Seadistamine

**Kontrolli olemasolevat swap'i:**
```bash
free -h
swapon --show
```

**Kui swap puudub või on väike (<4GB), loo uus:**

```bash
# 1. Loo swap fail (4GB)
sudo fallocate -l 4G /swapfile

# Kui fallocate ei tööta, kasuta dd:
# sudo dd if=/dev/zero of=/swapfile bs=1G count=4

# 2. Sea õigused (TURVALISUS)
sudo chmod 600 /swapfile

# 3. Vorminda swap'ina
sudo mkswap /swapfile

# 4. Aktiveeri
sudo swapon /swapfile

# 5. Kontrolli
free -h
swapon --show
# Peaks näitama 4GB swap'i

# 6. Tee püsivaks (lisab /etc/fstab)
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 7. Optimeeri swappiness (vähenda swap'i kasutust)
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 3.5 Võrgu Konfiguratsioon (VPS)

**Staatiline IP (kui DHCP):**

```bash
# 1. Leia interface nimi
ip addr show

# 2. Vaata praegust konfiguratsiooni
cat /etc/netplan/*.yaml

# 3. Seadista staatiline IP (näide)
# HOIATUS: Vale konfiguratsioon katkestab SSH!
sudo vim /etc/netplan/01-netcfg.yaml

# Näidis konfiguratsioon (kohanda vastavalt vajadusele):
network:
  version: 2
  ethernets:
    eth0:  # Sinu interface nimi
      addresses:
        - 93.127.213.242/24  # Sinu IP/mask
      routes:
        - to: default
          via: 93.127.213.1  # Gateway
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4

# 4. Testi konfiguratsiooni (EI RAKENDA VEEL!)
sudo netplan try
# Kui töötab, vajuta Enter 120s jooksul
# Kui ei tööta, ootab 120s ja rollback automaatselt

# 5. Rakenda
sudo netplan apply

# 6. Kontrolli
ip addr show
ping -c 3 8.8.8.8
```

**⚠️ VPS HOIATUS:** Kui võrgu konfiguratsioon läheb valesti, kaotad SSH ligipääsu! Kasuta VPS provider'i console'i (VNC/KVM).

---

## 4. LXD Paigaldamine

### 4.1 LXD Snap Paigaldamine

```bash
# 1. Installi LXD snap (Ubuntu 24.04 soovitatud meetod)
sudo snap install lxd

# 2. Lisa oma kasutaja lxd gruppi
# Asenda 'janek' oma kasutajanimega
sudo usermod -aG lxd $USER

# 3. Logi välja ja sisse (gruppilisandus aktiveerub)
# SSH: logi välja ja sisse uuesti
exit
ssh root@<VPS-IP>

# Või aktiveeri sessioon käsitsi:
newgrp lxd

# 4. Kontrolli
lxd --version
groups
# Peaks sisaldama: lxd
```

### 4.2 LXD Initialiseerimine

```bash
# Käivita LXD init interaktiivne wizard
lxd init
```

**Vasta järgmiselt:**

```
Would you like to use LXD clustering? (yes/no) [default=no]:
→ no

Do you want to configure a new storage pool? (yes/no) [default=yes]:
→ yes

Name of the new storage pool [default=default]:
→ default

Name of the storage backend to use (dir, lvm, zfs, btrfs, ceph) [default=zfs]:
→ dir
(Märkus: dir on lihtsaim, zfs on parem kui oskad)

Would you like to connect to a MAAS server? (yes/no) [default=no]:
→ no

Would you like to create a new local network bridge? (yes/no) [default=yes]:
→ yes

What should the new bridge be called? [default=lxdbr0]:
→ lxdbr0

What IPv4 address should be used? (CIDR subnet notation, "auto" or "none") [default=auto]:
→ auto
(Või spetsiifiline: 10.67.86.1/24)

What IPv6 address should be used? (CIDR subnet notation, "auto" or "none") [default=auto]:
→ none

Would you like the LXD server to be available over the network? (yes/no) [default=no]:
→ no

Would you like stale cached images to be updated automatically? (yes/no) [default=yes]:
→ yes

Would you like a YAML "lxd init" preseed to be printed? (yes/no) [default=no]:
→ no
```

### 4.3 LXD Konfiguratsiooni Kontrollimine

```bash
# Vaata LXD infot
lxc info

# Vaata võrku
lxc network list
lxc network show lxdbr0

# Vaata storage pool'i
lxc storage list
lxc storage info default

# Vaata profile'e
lxc profile list
lxc profile show default
```

**Oodatav lxdbr0 konfiguratsioon:**
```yaml
config:
  ipv4.address: 10.67.86.1/24
  ipv4.nat: "true"
  ipv6.address: none
```

### 4.4 Test Konteineri Käivitamine

```bash
# 1. Käivita test konteiner
lxc launch ubuntu:24.04 test-container

# 2. Vaata konteinerit
lxc list

# Peaks näitama:
# +----------------+---------+-----------------------+-------+
# | NAME           | STATE   | IPV4                  | IPV6  |
# +----------------+---------+-----------------------+-------+
# | test-container | RUNNING | 10.67.86.XXX (eth0)   |       |
# +----------------+---------+-----------------------+-------+

# 3. Testi internet ühendust
lxc exec test-container -- ping -c 3 8.8.8.8

# 4. Testi DNS
lxc exec test-container -- ping -c 3 google.com

# 5. Kui töötab, kustuta test konteiner
lxc delete --force test-container
```

**Kui test ebaõnnestub, vaata [Troubleshooting](#12-troubleshooting).**

---

## 5. Turvalisuse Seadistamine

### 5.1 UFW Firewall (VPS Kohustuslik)

```bash
# 1. Installi UFW
sudo apt-get install -y ufw

# 2. ENNE lubamist, luba SSH (muidu lukustad ennast välja!)
sudo ufw allow 22/tcp comment 'SSH'
# Või kui kasutad mittestandardset SSH porti:
# sudo ufw allow 1984/tcp comment 'SSH custom port'

# 3. Luba LXD bridge liiklust (KRIITILINE!)
sudo ufw allow in on lxdbr0
sudo ufw route allow in on lxdbr0
sudo ufw route allow out on lxdbr0

# 4. Muuda default routed policy
sudo ufw default allow routed

# 5. Luba õpilaste SSH pordid
sudo ufw limit 2201:2203/tcp comment 'SSH students (rate limited)'

# 6. Luba õpilaste web teenused
sudo ufw allow 8080:8281/tcp comment 'Web services students'
sudo ufw allow 3000:3200/tcp comment 'API services students'

# 7. Aktiveeri UFW
sudo ufw enable

# Vastus: Command may disrupt existing ssh connections. Proceed with operation (y|n)?
→ y

# 8. Kontrolli
sudo ufw status verbose
```

**Oodatav väljund:**
```
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere                   # SSH
2201:2203/tcp              LIMIT       Anywhere                   # SSH students
8080:8281/tcp              ALLOW       Anywhere                   # Web services
3000:3200/tcp              ALLOW       Anywhere                   # API services
Anywhere on lxdbr0         ALLOW       Anywhere
...
```

**Laptop Märkus:** UFW on valikuline, kuid soovitatav turvalisuse jaoks.

**⚠️ UFW + LXD HOIATUS:**

Kui pärast UFW lubamist LXD konteinerid **ei saa internetti** (ping annab 100% packet loss), proovi:

```bash
# 1. Keela UFW ajutiselt testimiseks
sudo ufw disable

# 2. Testi uuesti
lxc launch ubuntu:24.04 ufw-test
sleep 10
lxc exec ufw-test -- ping -c 3 8.8.8.8
lxc delete --force ufw-test

# 3. Kui nüüd töötab, on UFW blokeerimas LXD liiklust
# Lisa reeglid uuesti ja reload:
sudo ufw allow in on lxdbr0
sudo ufw route allow in on lxdbr0
sudo ufw route allow out on lxdbr0
sudo ufw default allow routed
sudo ufw enable
sudo ufw reload

# 4. Kui ikka ei tööta, vaata Troubleshooting sektsiooni 12.2
```

### 5.2 Fail2ban SSH Kaitse (VPS Soovitatav)

```bash
# 1. Installi fail2ban
sudo apt-get install -y fail2ban

# 2. Loo custom konfiguratsioon
sudo tee /etc/fail2ban/jail.d/sshd-custom.conf > /dev/null << 'EOF'
[sshd]
enabled = true
port = 22,1984,2201,2202,2203
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

# 3. Taaskäivita fail2ban
sudo systemctl restart fail2ban

# 4. Kontrolli
sudo systemctl status fail2ban
sudo fail2ban-client status sshd
```

### 5.3 SSH Tugevdamine (VPS)

**Ainult VPS jaoks - laptop'is võid vahele jätta.**

```bash
# 1. Varukoopia SSH konfigust
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# 2. Muuda SSH seadeid
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf > /dev/null << 'EOF'
# SSH Hardening for DevOps Lab
PermitRootLogin no
MaxAuthTries 3
LoginGraceTime 30
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# 3. Testi SSH konfiguratsiooni
sudo sshd -t
# Kui ei anna errori, siis OK

# 4. Taaskäivita SSH
sudo systemctl restart sshd

# 5. ÄRA LOGI VÄLJA! Ava uus terminal ja testi SSH
# Kui ei tööta, on vana sessioon veel elus
```

**⚠️ HOIATUS:** Ära logi välja enne SSH testimist uues aknas!

---

## 6. DevOps Lab Profiilide Loomine

### 6.1 Docker Profiili Loomine (Lab 1-2)

```bash
# Loo devops-lab profile (Docker laboritele)
lxc profile create devops-lab

# Seadista profile
lxc profile edit devops-lab
```

**Lisa järgmine YAML konfiguratsioon:**

```yaml
config:
  limits.cpu: "1"
  limits.memory: 2560MiB
  limits.memory.enforce: soft
  security.nesting: "true"
  security.privileged: "false"
  security.syscalls.intercept.mknod: "true"
  security.syscalls.intercept.setxattr: "true"
description: DevOps Lab Profile - 2.5GB RAM, 1 CPU, Docker support
devices:
  root:
    path: /
    pool: default
    type: disk
name: devops-lab
```

**Salvesta ja välju:** Vim'is: `:wq` või Nano's: `Ctrl+O`, `Enter`, `Ctrl+X`

### 6.2 Kubernetes Profiili Loomine (Lab 3-10)

```bash
# Loo devops-lab-k8s profile (Kubernetes laboritele)
lxc profile create devops-lab-k8s

# Seadista profile
lxc profile edit devops-lab-k8s
```

**Lisa järgmine YAML konfiguratsioon:**

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

**Salvesta ja välju:** Vim'is: `:wq` või Nano's: `Ctrl+O`, `Enter`, `Ctrl+X`

**⚠️ Kubernetes Profiili Märkused:**
- Suurem RAM (5GB) ja 2 CPU tuuma Kubernetes komponentidele
- `linux.kernel_modules`: Kubernetes vajalikud kernel moodulid
- `raw.lxc` seadistused: Kubernetes nõuab rohkem õigusi (siiski turvalisem kui privileged)
- `/dev/kmsg`: Kubernetes vajab ligipääsu kernel logidele

### 6.3 Profiilide Kontrollimine

```bash
# Vaata mõlemat profiili
lxc profile show devops-lab
lxc profile show devops-lab-k8s

# Listata kõik profiilid
lxc profile list
```

### 6.4 Security Settings Selgitus

#### Docker Profil (devops-lab)

| Setting | Väärtus | Selgitus |
|---------|---------|----------|
| `security.nesting` | `true` | Lubab Docker-in-Docker (konteiner konteineris) |
| `security.privileged` | `false` | Unprivileged konteiner (turvalisem) |
| `security.syscalls.intercept.mknod` | `true` | Lubab device loomist (Docker vajab) |
| `security.syscalls.intercept.setxattr` | `true` | Lubab extended attributes (Docker overlay2) |
| `limits.memory.enforce` | `soft` | Lubab mälu ületamist kui host'il vaba |

#### Kubernetes Profil (devops-lab-k8s)

| Setting | Väärtus | Selgitus |
|---------|---------|----------|
| `limits.cpu` | `2` | 2 CPU tuuma (Kubernetes komponentidele) |
| `limits.memory` | `5120MiB` | 5GB RAM (kubelet, kube-proxy, pods) |
| `linux.kernel_modules` | `ip_tables,...` | Kubernetes võrgu moodulid |
| `raw.lxc: lxc.apparmor.profile` | `unconfined` | Vähem piiratud AppArmor (K8s vajab) |
| `raw.lxc: lxc.cap.drop` | tühi | Säilitab capabilities (K8s vajab) |
| `raw.lxc: lxc.mount.auto` | `proc:rw...` | Kubernetes vajab kirjutamisõigust /proc'ile |
| `kmsg device` | `/dev/kmsg` | Kubernetes logide jaoks |

**Turvalisuse kompromiss:** Kubernetes profil on vähem piiratud kui Docker profil, kuna Kubernetes vajab rohkem süsteemitaseme juurdepääsu. Siiski on see turvalisem kui täielikult `privileged` konteiner.

---

## 7. Template Image Loomine

See on pikim ja kõige kriitilisem samm. Template sisaldab kõike, mis õpilastel vaja (Docker, labs, tööriistad).

### 7.1 Base Konteineri Käivitamine

```bash
# 1. Käivita Ubuntu 24.04 konteiner
lxc launch ubuntu:24.04 devops-template -p default -p devops-lab

# 2. Oota, kuni konteiner saab IP (15-30 sekundit)
lxc list devops-template

# 3. Logi konteinerisse (root'ina)
lxc exec devops-template -- bash
```

**Nüüd oled konteineri sees. Järgnevad käsud käivita KONTEINERIS.**

### 7.2 Süsteemi Uuendamine (Konteineris)

```bash
# Uuenda paketid
apt-get update
apt-get upgrade -y

# Installi põhilised tööriistad
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
  software-properties-common
```

### 7.3 Docker Engine Paigaldamine (Konteineris)

```bash
# 1. Lisa Docker GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# 2. Lisa Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3. Uuenda paketilisti
apt-get update

# 4. Installi Docker
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# 5. Kontrolli versioone
docker --version
docker compose version
containerd --version
```

### 7.4 ⚠️ KRIITILINE: containerd.io Downgrade (Konteineris)

**OLULINE:** Ilma selleta EI TÖÖTA Docker konteinerid LXD'is!

```bash
# 1. Kontrolli praegust versiooni
containerd --version

# 2. Kui versioon on 1.7.29+ või 2.x, downgrade:
apt-get install -y --allow-downgrades containerd.io=1.7.28-1~ubuntu.24.04~noble

# 3. Lukusta versioon (et ei uuendaks)
apt-mark hold containerd.io

# 4. Verifitseeri
containerd --version
# Peaks olema: containerd containerd.io 1.7.28 ...

apt-mark showhold | grep containerd
# Peaks näitama: containerd.io

# 5. Taaskäivita Docker
systemctl restart docker

# 6. Testi
docker run --rm hello-world
# Peaks väljastama: Hello from Docker!

# 7. Testi Alpine (sysctl bug test)
docker run --rm alpine:3.16 echo "OK"
# Peaks väljastama: OK

# 8. Testi PostgreSQL 16-alpine
docker run --rm -e POSTGRES_PASSWORD=test postgres:16-alpine postgres --version
# Peaks väljastama PostgreSQL versiooni ilma errorita
```

**Kui testimised ebaõnnestuvad, vaata [Troubleshooting](#12-troubleshooting) "Docker sysctl error".**

### 7.5 Diagnostika Tööriistade Paigaldamine (Konteineris)

```bash
# Võrgu diagnostika tööriistad
apt-get install -y \
  jq \
  nmap \
  tcpdump \
  netcat-openbsd \
  dnsutils \
  net-tools \
  iproute2

# Arenduse tööriistad
apt-get install -y \
  build-essential \
  python3 \
  python3-pip

# Kontrolli
which jq nmap tcpdump nc dig netstat lsof ip
```

### 7.6 Java 21 Paigaldamine (Konteineris)

```bash
# Installi OpenJDK 21
apt-get install -y openjdk-21-jdk

# Kontrolli
java -version
javac -version

# Peaks näitama: openjdk version "21.0.x"
```

### 7.7 Node.js 20 Paigaldamine (Konteineris)

```bash
# 1. Lisa NodeSource repository (Node.js 20 LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

# 2. Installi Node.js
apt-get install -y nodejs

# 3. Kontrolli
node --version
npm --version

# Peaks näitama:
# Node: v20.x.x
# NPM: 10.x.x
```

### 7.8 labuser Kasutaja Loomine (Konteineris)

```bash
# 1. Loo labuser kasutaja
useradd -m -s /bin/bash -u 1000 labuser

# 2. Lisa docker gruppi
usermod -aG docker labuser

# 3. Sea ajutine parool (muudetakse hiljem konteinerites)
echo "labuser:temppassword" | chpasswd

# 4. Kontrolli
id labuser
# Peaks näitama: uid=1000(labuser) gid=1000(labuser) groups=1000(labuser),999(docker)
```

### 7.9 SSH Server Paigaldamine (Konteineris)

```bash
# 1. Installi OpenSSH server
apt-get install -y openssh-server

# 2. Luba password authentication
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/99-security.conf << 'EOF'
# DevOps Lab SSH Configuration
MaxAuthTries 3
LoginGraceTime 30
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
PermitEmptyPasswords no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# 3. Luba SSH teenus (LXD konteineris ei käivitu automaatselt)
systemctl enable ssh

# 4. Kontrolli konfiguratsiooni
sshd -t
# Kui ei anna errori, siis OK
```

### 7.10 Sudo Õiguste Seadistamine (Konteineris)

```bash
# Loo sudoers fail labuser'i jaoks
cat > /etc/sudoers.d/labuser-devops << 'EOF'
# DevOps Training Lab - Limited Sudo Access
Defaults:labuser !requiretty
labuser ALL=(ALL) NOPASSWD: /usr/bin/lsof
labuser ALL=(ALL) NOPASSWD: /usr/bin/nmap
labuser ALL=(ALL) NOPASSWD: /usr/sbin/tcpdump
labuser ALL=(ALL) NOPASSWD: /bin/systemctl restart docker
labuser ALL=(ALL) NOPASSWD: /bin/systemctl status docker
labuser ALL=(ALL) NOPASSWD: /bin/ls /var/lib/docker/volumes/
labuser ALL=(ALL) NOPASSWD: /bin/ls /var/lib/docker/volumes/*
labuser ALL=(ALL) NOPASSWD: /usr/bin/du /var/lib/docker/containers/*
EOF

# Sea õigused
chmod 0440 /etc/sudoers.d/labuser-devops
chown root:root /etc/sudoers.d/labuser-devops

# VALIDEERI (KRITILINE!)
visudo -c -f /etc/sudoers.d/labuser-devops
# Peaks väljastama: parsed OK

# Testi (labuser'ina)
su - labuser -c 'sudo lsof -i :22'
# Peaks töötama ilma paroolita ja näitama SSH porte
```

### 7.11 Bash Konfiguratsioon labuser'ile (Konteineris)

```bash
# Vaheta kasutajat
su - labuser

# Nüüd oled labuser'ina
# Loo .bashrc konfiguratsioon
cat >> /home/labuser/.bashrc << 'EOF'

# Java Environment
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Docker Aliases
alias docker-stop-all="docker stop \$(docker ps -aq) 2>/dev/null || echo 'No containers running'"
alias check-resources="echo '=== RAM ===' && free -h && echo && echo '=== DISK ===' && df -h / && echo && echo '=== DOCKER ===' && docker ps -a && docker images"

# Lab Aliases
alias labs-reset="~/labs/labs-reset.sh"
alias lab1-setup="cd ~/labs/01-docker-lab && ./setup.sh"

# Docker AppArmor Workaround for LXD
# LXD konteinerites on AppArmor piiratud, see wrapper lisab vajaliku flag'i
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

# Logi labuser'ist välja (tagasi root'i)
exit
```

### 7.12 Labs Kausta Ettevalmistus (Konteineris)

```bash
# Loo labs kataloog (failid sünkroniseeritakse hiljem)
mkdir -p /home/labuser/labs
chown -R labuser:labuser /home/labuser/labs

# Loo README placeholder
cat > /home/labuser/README.md << 'EOF'
# DevOps Laborikeskkond

Tere tulemast DevOps laborikeskkonda!

## Kiirstart

1. Kontrolli ressursse:
   ```
   check-resources
   ```

2. Loe labori juhendeid:
   ```
   cd ~/labs/
   ls -la
   ```

3. Alusta Lab 1'ga:
   ```
   cd ~/labs/01-docker-lab/
   cat README.md
   ```

## Kasulikud käsud

- `docker ps` - Vaata töötavaid konteinereid
- `docker images` - Vaata olemasolevaid image'id
- `labs-reset` - Puhasta kõik Docker ressursid
- `lab1-setup` - Lab 1 seadistus

## Abi

Kui midagi ei tööta, küsi abi juhendajalt või vaata:
- Lab README failid
- CLAUDE.md (AI abi)

Edu laborite lahendamisel!
EOF

chown labuser:labuser /home/labuser/README.md
```

### 7.13 Puhastamine ja Optimeerimine (Konteineris)

```bash
# 1. Puhasta APT cache
apt-get clean
apt-get autoremove -y

# 2. Kustuta ajutised failid
rm -rf /tmp/*
rm -rf /var/tmp/*

# 3. Kustuta bash history
history -c

# 4. Kustuta log failid (valikuline)
# find /var/log -type f -delete

# 5. Logi välja konteinerist (tagasi host'i)
exit
```

**Nüüd oled tagasi HOST süsteemis.**

### 7.14 Template'i Publitseerimine (Host)

```bash
# 1. Peata konteiner (OLULINE!)
lxc stop devops-template

# 2. Publitseeri image'ina
lxc publish devops-template --alias devops-lab-base \
  description="DevOps Lab Template: Ubuntu 24.04 + Docker 29.0.4 + containerd 1.7.28 + Labs"

# 3. Vaata loodud image't
lxc image list

# Peaks näitama:
# +-----------------+--------------+--------+...
# | devops-lab-base | ...          | 494MB  |...
# +-----------------+--------------+--------+...

# 4. Kustuta template konteiner (enam ei vaja)
lxc delete devops-template
```

### 7.15 Template'i Backup (Soovitatud)

```bash
# Ekspordi template failina (backup)
mkdir -p ~/lxd-backups
lxc image export devops-lab-base ~/lxd-backups/devops-lab-base-$(date +%Y%m%d)

# Kontrolli
ls -lh ~/lxd-backups/
# Peaks näitama .tar.gz faili (~300-500MB)
```

---

## 8. Õpilaskonteinerite Loomine

**Vali üks järgmistest:**
- **Variant A:** Docker laboritele (Lab 1-2) - kasuta `devops-lab` profiili
- **Variant B:** Kubernetes laboritele (Lab 3-10) - kasuta `devops-lab-k8s` profiili
- **Variant C:** Kombineeritud - loo mõlemad tüübid

### 8.1 Docker Konteinerite Loomine (Lab 1-2)

**Kui kavatsed ainult Docker laboreid teha, kasuta seda varianti.**

#### 8.1.1 Student 1 Loomine (Docker)

```bash
# 1. Loo konteiner
lxc launch devops-lab-base devops-student1 -p default -p devops-lab

# 2. Oota, kuni saab IP (10-20 sekundit)
lxc list devops-student1

# 3. Sea parool
lxc exec devops-student1 -- bash -c 'echo "labuser:student1" | chpasswd'

# 4. Lisa SSH port forwarding (Host:2201 → Container:22)
lxc config device add devops-student1 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2201 \
  connect=tcp:127.0.0.1:22 \
  nat=true

# 5. Lisa Web port forwarding (Host:8080 → Container:8080)
lxc config device add devops-student1 web-proxy proxy \
  listen=tcp:0.0.0.0:8080 \
  connect=tcp:127.0.0.1:8080 \
  nat=true

# 6. Lisa User API port forwarding (Host:3000 → Container:3000)
lxc config device add devops-student1 user-api-proxy proxy \
  listen=tcp:0.0.0.0:3000 \
  connect=tcp:127.0.0.1:3000 \
  nat=true

# 7. Lisa Todo API port forwarding (Host:8081 → Container:8081)
lxc config device add devops-student1 todo-api-proxy proxy \
  listen=tcp:0.0.0.0:8081 \
  connect=tcp:127.0.0.1:8081 \
  nat=true

# 8. Kontrolli
lxc config device show devops-student1
```

### 8.2 Student 2 Loomine

```bash
# 1. Loo konteiner
lxc launch devops-lab-base devops-student2 -p default -p devops-lab

# 2. Sea parool
lxc exec devops-student2 -- bash -c 'echo "labuser:student2" | chpasswd'

# 3. Port forwarding (pordid erinevad!)
lxc config device add devops-student2 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2202 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-student2 web-proxy proxy \
  listen=tcp:0.0.0.0:8180 connect=tcp:127.0.0.1:8080 nat=true

lxc config device add devops-student2 user-api-proxy proxy \
  listen=tcp:0.0.0.0:3100 connect=tcp:127.0.0.1:3000 nat=true

lxc config device add devops-student2 todo-api-proxy proxy \
  listen=tcp:0.0.0.0:8181 connect=tcp:127.0.0.1:8081 nat=true
```

### 8.3 Student 3 Loomine

```bash
# 1. Loo konteiner
lxc launch devops-lab-base devops-student3 -p default -p devops-lab

# 2. Sea parool
lxc exec devops-student3 -- bash -c 'echo "labuser:student3" | chpasswd'

# 3. Port forwarding
lxc config device add devops-student3 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2203 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-student3 web-proxy proxy \
  listen=tcp:0.0.0.0:8280 connect=tcp:127.0.0.1:8080 nat=true

lxc config device add devops-student3 user-api-proxy proxy \
  listen=tcp:0.0.0.0:3200 connect=tcp:127.0.0.1:3000 nat=true

lxc config device add devops-student3 todo-api-proxy proxy \
  listen=tcp:0.0.0.0:8281 connect=tcp:127.0.0.1:8081 nat=true
```

### 8.2 Kubernetes Konteinerite Loomine (Lab 3-10)

**Kui kavatsed Kubernetes laboreid teha, kasuta seda varianti.**

**⚠️ Eeldus:** Serveris peab olema vähemalt 24GB RAM!

#### 8.2.1 Student 1 Loomine (Kubernetes)

```bash
# 1. Loo konteiner Kubernetes profiiliga
lxc launch devops-lab-base devops-k8s-student1 -p default -p devops-lab-k8s

# 2. Oota, kuni saab IP (10-20 sekundit)
lxc list devops-k8s-student1

# 3. Sea parool
lxc exec devops-k8s-student1 -- bash -c 'echo "labuser:student1" | chpasswd'

# 4. Lisa SSH port forwarding (Host:2211 → Container:22)
lxc config device add devops-k8s-student1 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2211 \
  connect=tcp:127.0.0.1:22 \
  nat=true

# 5. Lisa Kubernetes API port (Host:6443 → Container:6443)
lxc config device add devops-k8s-student1 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6443 \
  connect=tcp:127.0.0.1:6443 \
  nat=true

# 6. Lisa Ingress HTTP port (Host:30080 → Container:30080)
lxc config device add devops-k8s-student1 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30080 \
  connect=tcp:127.0.0.1:30080 \
  nat=true

# 7. Lisa Ingress HTTPS port (Host:30443 → Container:30443)
lxc config device add devops-k8s-student1 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30443 \
  connect=tcp:127.0.0.1:30443 \
  nat=true

# 8. Kontrolli
lxc config device show devops-k8s-student1
```

#### 8.2.2 Student 2 Loomine (Kubernetes)

```bash
# 1. Loo konteiner
lxc launch devops-lab-base devops-k8s-student2 -p default -p devops-lab-k8s

# 2. Sea parool
lxc exec devops-k8s-student2 -- bash -c 'echo "labuser:student2" | chpasswd'

# 3. Port forwarding (pordid erinevad!)
lxc config device add devops-k8s-student2 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2212 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-k8s-student2 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6444 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student2 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30180 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student2 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30543 connect=tcp:127.0.0.1:30443 nat=true
```

#### 8.2.3 Student 3 Loomine (Kubernetes)

```bash
# 1. Loo konteiner
lxc launch devops-lab-base devops-k8s-student3 -p default -p devops-lab-k8s

# 2. Sea parool
lxc exec devops-k8s-student3 -- bash -c 'echo "labuser:student3" | chpasswd'

# 3. Port forwarding
lxc config device add devops-k8s-student3 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2213 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-k8s-student3 k8s-api-proxy proxy \
  listen=tcp:0.0.0.0:6445 connect=tcp:127.0.0.1:6443 nat=true

lxc config device add devops-k8s-student3 ingress-http-proxy proxy \
  listen=tcp:0.0.0.0:30280 connect=tcp:127.0.0.1:30080 nat=true

lxc config device add devops-k8s-student3 ingress-https-proxy proxy \
  listen=tcp:0.0.0.0:30643 connect=tcp:127.0.0.1:30443 nat=true
```

#### 8.2.4 Kubernetes Port Mapping Tabel

| Service | Internal Port | Student 1 | Student 2 | Student 3 |
|---------|--------------|-----------|-----------|-----------|
| SSH | 22 | 2211 | 2212 | 2213 |
| K8s API | 6443 | 6443 | 6444 | 6445 |
| Ingress HTTP | 30080 | 30080 | 30180 | 30280 |
| Ingress HTTPS | 30443 | 30443 | 30543 | 30643 |

**Märkus:** Kubernetes kasutab NodePort vahemikku 30000-32767, seega kasutatakse erinevaid porte iga õpilase jaoks.

### 8.3 Kombineeritud Variant (Docker + Kubernetes)

**Kui soovid mõlemat tüüpi konteinereid:**

```bash
# Docker konteinerid (Lab 1-2)
lxc launch devops-lab-base devops-docker-student1 -p default -p devops-lab
lxc launch devops-lab-base devops-docker-student2 -p default -p devops-lab

# Kubernetes konteinerid (Lab 3-10)
lxc launch devops-lab-base devops-k8s-student1 -p default -p devops-lab-k8s
lxc launch devops-lab-base devops-k8s-student2 -p default -p devops-lab-k8s

# HOIATUS: Vaja vähemalt 24GB RAM!
# 2 × 2.5GB (Docker) + 2 × 5GB (K8s) = 15GB + 2GB host = 17GB minimum
```

### 8.4 Kõigi Konteinerite Ülevaade

```bash
# Vaata kõiki konteinereid
lxc list

# Kontrolli ressursside kasutust
lxc list -c ns4M

# Kontrolli iga konteineri portide forwarding'ut
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== $c ==="
  lxc config device show $c
done
```

### 8.5 Paroolide Salvestamine

```bash
# Loo fail paroolide hoidmiseks (TURVALINE!)
cat > ~/student-passwords.txt << 'EOF'
# DevOps Lab Student Passwords
# Created: $(date +%Y-%m-%d)

devops-student1:
  SSH: ssh labuser@<SERVER-IP> -p 2201
  Password: student1

devops-student2:
  SSH: ssh labuser@<SERVER-IP> -p 2202
  Password: student2

devops-student3:
  SSH: ssh labuser@<SERVER-IP> -p 2203
  Password: student3

# MÄRKUS: Soovitav vahetada tugevate paroolide vastu!
EOF

# Lukusta fail (ainult sina saad lugeda)
chmod 600 ~/student-passwords.txt

# Vaata
cat ~/student-passwords.txt
```

---

## 9. Labs Failide Sünkroniseerimine

### 9.1 Git Repositooriumi Kloneerimine (Host)

```bash
# 1. Navigeeri oma home kausta
cd ~

# 2. Loo projects kataloog
mkdir -p projects
cd projects

# 3. Klooni repositoorium
# Asenda URL oma repo URL'iga
git clone https://github.com/yourusername/devops-labs.git hostinger

# VÕI kui juba kloonitud:
# cd hostinger
# git pull

# 4. Kontrolli
ls -la hostinger/labs/
# Peaks näitama: 01-docker-lab, 02-docker-compose-lab, ..., apps/, README.md
```

### 9.2 Sünkroniseerimise Skriptide Loomine

```bash
# Loo skriptide kataloog
mkdir -p ~/scripts
cd ~/scripts
```

#### 9.2.1 sync-labs.sh - Üks Konteiner

```bash
cat > ~/scripts/sync-labs.sh << 'EOFSCRIPT'
#!/bin/bash
# Sync labs to one container

set -e

CONTAINER="$1"
# Kasuta keskkonna muutujat või vaikimisi $HOME/projects/hostinger/labs
SOURCE_DIR="${LABS_SOURCE:-$HOME/projects/hostinger/labs}"

if [ -z "$CONTAINER" ]; then
  echo "Usage: $0 <container-name>"
  echo "Example: $0 devops-student1"
  exit 1
fi

# Check if container exists
if ! lxc list -c n --format csv | grep -q "^${CONTAINER}$"; then
  echo "Error: Container '$CONTAINER' not found"
  exit 1
fi

echo "📦 Syncing labs to $CONTAINER..."

# Backup existing labs in container
BACKUP_NAME="labs-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
echo "Creating backup: /tmp/$BACKUP_NAME"
lxc exec $CONTAINER -- bash -c "tar czf /tmp/$BACKUP_NAME -C /home/labuser labs 2>/dev/null || true"

# Push labs directory
echo "Copying files..."
lxc file push -r "$SOURCE_DIR/" "$CONTAINER/home/labuser/"

# Fix ownership
echo "Setting ownership..."
lxc exec $CONTAINER -- chown -R labuser:labuser /home/labuser/labs

# Fix executable permissions for .sh files
lxc exec $CONTAINER -- find /home/labuser/labs -type f -name '*.sh' -exec chmod 755 {} \;

echo "✅ $CONTAINER updated!"
echo "   Backup: /tmp/$BACKUP_NAME"
EOFSCRIPT

chmod +x ~/scripts/sync-labs.sh
```

#### 9.2.2 sync-all-students.sh - Kõik Konteinerid

```bash
cat > ~/scripts/sync-all-students.sh << 'EOFSCRIPT'
#!/bin/bash
# Sync labs to all student containers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==================================="
echo "Syncing labs to all students"
echo "==================================="
echo

# Leia kõik devops konteinerid (nii Docker kui K8s)
CONTAINERS=$(lxc list --format csv -c n | grep -E "^devops-(student|k8s-student)" || true)

if [ -z "$CONTAINERS" ]; then
  echo "No devops containers found"
  exit 0
fi

for CONTAINER in $CONTAINERS; do
  echo ">>> $CONTAINER <<<"
  "$SCRIPT_DIR/sync-labs.sh" "$CONTAINER" || true
  echo
done

echo "✅ All students updated!"
EOFSCRIPT

chmod +x ~/scripts/sync-all-students.sh
```

#### 9.2.3 check-versions.sh - Versiooni Kontroll

```bash
cat > ~/scripts/check-versions.sh << 'EOFSCRIPT'
#!/bin/bash
# Check when labs were last updated in each container

LABS_SOURCE="${LABS_SOURCE:-$HOME/projects/hostinger/labs}"

echo "Lab Versions (last modified):"
echo "=============================="

# Leia kõik töötavad devops konteinerid
CONTAINERS=$(lxc list --format csv -c n,s | grep -E "^devops-(student|k8s-student)" | grep "RUNNING" | cut -d',' -f1 || true)

if [ -z "$CONTAINERS" ]; then
  echo "No running devops containers found"
else
  for CONTAINER in $CONTAINERS; do
    LAST_MODIFIED=$(lxc exec $CONTAINER -- stat -c %Y /home/labuser/labs 2>/dev/null | xargs -I{} date -d @{} +%Y-%m-%d 2>/dev/null || echo "N/A")
    echo "$CONTAINER: $LAST_MODIFIED"
  done
fi

echo
echo "Host version:"
if [ -d "$LABS_SOURCE" ]; then
  stat -c %Y "$LABS_SOURCE" | xargs -I{} date -d @{} +%Y-%m-%d
else
  echo "Labs source not found: $LABS_SOURCE"
fi
EOFSCRIPT

chmod +x ~/scripts/check-versions.sh
```

### 9.3 Labs Sünkroniseerimine

```bash
# Sünkroniseeri kõikidesse konteineritesse
~/scripts/sync-all-students.sh

# Kontrolli versioone
~/scripts/check-versions.sh
```

---

## 10. Laptop/Portable Deployment

**Kui kasutad VPS'i, võid selle peatüki vahele jätta.**

### 10.1 Erinevused VPS'st

- ✅ **Localhost ainult** - Lihtsaim ja turvaliseм
- ✅ **Ressursside säästmine** - Vähem RAM/CPU
- ✅ **Portable** - Töötab igas võrgus
- ❌ **Pole 24/7** - Ainult kui arvuti sees
- ❌ **Pole avalikult kättesaadav** - Ainult localhost

### 10.2 Võrgu Lahendused

#### Variant 1: Localhost Ainult (Soovitatav)

```bash
# Port forwarding localhost'ile
lxc config device add devops-student1 ssh-proxy proxy \
  listen=tcp:127.0.0.1:2201 \
  connect=tcp:127.0.0.1:22

# SSH kasutamine
ssh labuser@localhost -p 2201

# Web brauser
http://localhost:8080
```

#### Variant 2: Kohaliku Võrgu IP (LAN Demo)

```bash
# Leia kohalik IP
ip addr show | grep "inet " | grep -v 127.0.0.1
# Näiteks: 192.168.1.100

# Port forwarding kõigile liidestele
lxc config device add devops-student1 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2201 \
  connect=tcp:127.0.0.1:22

# SSH teisest arvutist (samas WiFis)
ssh labuser@192.168.1.100 -p 2201

# UFW (kui kasutusel)
sudo ufw allow from 192.168.1.0/24 to any port 2201:2203
```

#### Variant 3: Tailscale VPN (Parim kaug ligipääsu jaoks)

```bash
# 1. Installi Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# 2. Login
sudo tailscale up

# 3. Leia Tailscale IP
tailscale ip -4
# Näiteks: 100.64.0.1

# 4. Port forwarding Tailscale IP-le
lxc config device add devops-student1 ssh-proxy proxy \
  listen=tcp:100.64.0.1:2201 \
  connect=tcp:127.0.0.1:22

# 5. SSH igalt Tailscale võrgu seadmelt
ssh labuser@100.64.0.1 -p 2201
```

### 10.3 Ressursside Optimeerimine

```bash
# Vähenda RAM'i (laptop'is)
lxc config set devops-student1 limits.memory 2GB

# Lisa CPU tuuming
lxc config set devops-student1 limits.cpu 2

# Peata kasutamata konteinerid
lxc stop devops-student2
lxc stop devops-student3
```

### 10.4 Energia Säästmine

```bash
# Suspend konteinerid (säilitab state)
lxc pause devops-student1

# Resume
lxc start devops-student1

# Pärast hibernate/sleep taaskäivita LXD
sudo systemctl restart lxd
```

---

## 11. Testimine

**⚠️ TÄHTIS: See sektsioon on testimise jaoks TEISES ARVUTIS!**

**Ära testi paigaldusprotsessi käigus samas masinas - testimine toimub pärast paigaldust eraldi testmasinas!**

Detailne testimisjuhend on eraldi failis: **[TESTING-GUIDE.md](TESTING-GUIDE.md)**

### Kiirkontroll Paigalduse Käigus

Ainult need käsud võid käivitada paigalduse lõpus (host'is):

```bash
# 1. Konteinerite staatus
lxc list

# 2. Ressursid
lxc list -c ns4M

# 3. Võrgu kontroll (konteinerite IP-d)
lxc list -c n4

# 4. Port forwarding kontroll
netstat -tuln | grep -E ':(2201|2202|2203|8080)'
```

**Täielik testimine:** Vaata [TESTING-GUIDE.md](TESTING-GUIDE.md)

---

## 12. Troubleshooting

### 12.1 LXD Ei Saa Internetti

**Sümptom:**
```bash
lxc exec test-container -- ping 8.8.8.8
# connect: Network is unreachable
```

**Lahendus:**

```bash
# 1. Kontrolli lxdbr0 olekut
ip addr show lxdbr0
# Peaks olema: state UP

# 2. Kontrolli NAT
sudo iptables -t nat -L -n -v | grep lxdbr0
# Peaks olema MASQUERADE reegel

# 3. Kontrolli IP forwarding
cat /proc/sys/net/ipv4/ip_forward
# Peaks olema: 1

# Kui 0, luba:
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# 4. Taaskäivita LXD
sudo systemctl restart lxd

# 5. Testi uuesti
lxc exec test-container -- ping -c 3 8.8.8.8
```

### 12.2 UFW Blokeerib LXD Liiklust

**Sümptom:**
```bash
# UFW on enabled, aga konteinerid ei saa internetti
```

**Lahendus:**

```bash
# Lisa LXD reeglid UUESTI
sudo ufw allow in on lxdbr0
sudo ufw route allow in on lxdbr0
sudo ufw route allow out on lxdbr0
sudo ufw default allow routed

# Reload
sudo ufw reload

# Testi
lxc exec test-container -- ping -c 3 8.8.8.8
```

### 12.3 Docker sysctl Permission Denied

**Sümptom:**
```bash
docker run --rm alpine echo test
# Error: unable to start container process:
# open sysctl net.ipv4.ip_unprivileged_port_start file: permission denied
```

**Põhjus:** containerd.io versioon on 1.7.29+ või 2.x

**Lahendus:**

```bash
# Logi konteinerisse
lxc exec devops-student1 -- bash

# Kontrolli versiooni
containerd --version

# Downgrade
systemctl stop docker
apt install -y --allow-downgrades containerd.io=1.7.28-1~ubuntu.24.04~noble
apt-mark hold containerd.io

# Taaskäivita
systemctl restart containerd
systemctl restart docker

# Testi
docker run --rm alpine echo "OK"
# Peaks väljastama: OK
```

### 12.4 SSH Port Forwarding Ei Tööta

**Sümptom:**
```bash
ssh labuser@<SERVER-IP> -p 2201
# Connection refused
```

**Lahendus:**

```bash
# 1. Kontrolli, kas port on listening host'is
netstat -tuln | grep 2201
# Peaks näitama: 0.0.0.0:2201 LISTEN

# 2. Kui ei ole, kontrolli proxy device't
lxc config device show devops-student1 | grep ssh-proxy

# 3. Kui puudub, lisa uuesti
lxc config device remove devops-student1 ssh-proxy  # Kui eksisteerib
lxc config device add devops-student1 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2201 connect=tcp:127.0.0.1:22 nat=true

# 4. Kontrolli UFW (kui kasutusel)
sudo ufw status | grep 2201
# Kui puudub:
sudo ufw allow 2201/tcp

# 5. Kontrolli SSH teenust konteineris
lxc exec devops-student1 -- systemctl status ssh
# Kui ei tööta:
lxc exec devops-student1 -- systemctl start ssh
lxc exec devops-student1 -- systemctl enable ssh
```

### 12.5 Konteiner Ei Käivitu

**Sümptom:**
```bash
lxc launch devops-lab-base test
# Error: Failed to run: ...
```

**Lahendus:**

```bash
# 1. Vaata logisid
lxc info test --show-log

# 2. Kontrolli profile'e
lxc profile show devops-lab

# 3. Proovi ilma devops-lab profile'ita
lxc launch devops-lab-base test-minimal -p default

# 4. Kui töötab, on viga devops-lab profile'is
lxc profile edit devops-lab
# Kontrolli YAML süntaksit
```

### 12.6 RAM Otsa

**Sümptom:**
```bash
free -h
# Mem: 7.8Gi used, 100Mi available
```

**Lahendus:**

```bash
# 1. Peata mittevajalikke konteinereid
lxc stop devops-student2
lxc stop devops-student3

# 2. Puhasta Docker igas konteineris
for c in devops-student1 devops-student2 devops-student3; do
  lxc exec $c -- su - labuser -c 'docker system prune -af --volumes'
done

# 3. Vähenda konteineri RAM limiiti
lxc config set devops-student1 limits.memory 2GB
lxc restart devops-student1

# 4. Suurenda swap'i (kui vaja)
sudo swapoff /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1G count=8  # 8GB
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 12.7 Disk Täis

**Sümptom:**
```bash
df -h
# /dev/sda1  96G  92G  0  100% /
```

**Lahendus:**

```bash
# 1. Leia suuremad kataloogid
du -h --max-depth=1 /var/snap/lxd | sort -h

# 2. Puhasta Docker image'd konteinerites
for c in devops-student1 devops-student2 devops-student3; do
  echo "=== Cleaning $c ==="
  lxc exec $c -- su - labuser -c 'docker system prune -af --volumes'
done

# 3. Kustuta vanad LXD image'd
lxc image list
lxc image delete <fingerprint>

# 4. Kustuta vanad snapshots
lxc info devops-student1 | grep Snapshots
lxc delete devops-student1/<snapshot-name>

# 5. APT cache
sudo apt-get clean
sudo apt-get autoremove -y
```

### 12.8 Docker AppArmor Permission Denied

**Sümptom:**
```bash
docker run --rm alpine echo test
# docker: Error response from daemon: failed to create task for container:
# failed to start shim: ...
# open /sys/kernel/security/apparmor/profiles: permission denied
```

**Põhjus:** LXD konteinerites on AppArmor piiratud ja Docker ei saa lugeda AppArmor profiile.

**Lahendus 1 - Kasuta wrapper funktsiooni (soovitatud):**

Template'i .bashrc failis peaks olema Docker wrapper funktsioon, mis automaatselt lisab `--security-opt apparmor=unconfined`. Kui see puudub:

```bash
# Logi konteinerisse
lxc exec devops-student1 -- su - labuser

# Lisa .bashrc-sse
cat >> ~/.bashrc << 'EOF'

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

# Lae uuesti
source ~/.bashrc

# Testi
docker run --rm alpine echo "OK"
# Peaks väljastama: OK
```

**Lahendus 2 - Käsitsi flag iga kord:**

```bash
docker run --security-opt apparmor=unconfined --rm alpine echo "OK"
```

**Märkus:** Kui kasutad `docker-compose`, peab services definitsioonis olema:
```yaml
services:
  myservice:
    security_opt:
      - apparmor:unconfined
```

---

## Järgmised Sammud

Pärast edukast paigaldust:

1. **Salvesta paroolid:** `~/student-passwords.txt`
2. **Tee backup:** Ekspordi template ja konteinerid
3. **Seadista cron backup:** Automaatsed snapshots
4. **Jaga juhendid:** Saada õpilastele SSH info ja README
5. **Monitoori ressursse:** `lxc list -c ns4M`

---

## Viited

- **LXD Dokumentatsioon:** https://documentation.ubuntu.com/lxd/
- **Docker Dokumentatsioon:** https://docs.docker.com/
- **Ubuntu 24.04 Dokumentatsioon:** https://ubuntu.com/server/docs
- **Tailscale:** https://tailscale.com/kb/

---

**Autor:** DevOps Lab Admin
**Versioon:** 1.1
**Viimane uuendus:** 2025-12-01
**Litsentss:** MIT
**Tagasiside:** https://github.com/yourusername/devops-labs/issues
