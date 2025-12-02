# Host Süsteemi Seadistamine (Proxy Keskkond)

## Ülevaade

See juhend kirjeldab **host masina ettevalmistamist** DevOps laborikeskkonna jaoks **proxy seadistusega** ettevõtte sisevõrgus.

**⚠️ KOHUSTUSLIK EELDUS:** See juhend tuleb läbida ENNE Docker või Kubernetes laborite seadistamist!

**Mida see juhend hõlmab:**
- ✅ Proxy seadistamine (APT, keskkond, Snap)
- ✅ LXD paigaldamine ja initialiseerimine
- ✅ Kernel moodulite laadmine (Kubernetes jaoks)
- ✅ Turvalisuse selgitus (sisevõrk)

**Pärast seda juhendit jätka:**
- 👉 **Docker laborid (Lab 1-2):** [ADMIN-GUIDE-DOCKER-PROXY.md](ADMIN-GUIDE-DOCKER-PROXY.md)
- 👉 **Kubernetes laborid (Lab 3-10):** [ADMIN-GUIDE-K8S-PROXY.md](ADMIN-GUIDE-K8S-PROXY.md)

---

## Sisukord

1. [Süsteeminõuded](#1-süsteeminõuded)
2. [Quick Reference](#2-quick-reference)
3. [Host Süsteemi Ettevalmistus](#3-host-süsteemi-ettevalmistus)
   - 3.1 [Proxy Seadistamine](#31-proxy-seadistamine)
   - 3.2 [Süsteemi Uuendamine](#32-süsteemi-uuendamine)
   - 3.3 [Swap Seadistamine](#33-swap-seadistamine)
4. [LXD Paigaldamine](#4-lxd-paigaldamine)
   - 4.1 [LXD Snap](#41-lxd-snap)
   - 4.2 [LXD Initialiseerimine](#42-lxd-initialiseerimine)
   - 4.3 [LXD Kontrollimine](#43-lxd-kontrollimine)
5. [Kernel Moodulite Laadmine](#5-kernel-moodulite-laadmine)
   - 5.1 [overlay ja br_netfilter Moodulid](#51-overlay-ja-br_netfilter-moodulid)
   - 5.2 [Sysctl Seadistused](#52-sysctl-seadistused)
   - 5.3 [Verifitseerimine](#53-verifitseerimine)
6. [Turvalisus](#6-turvalisus)
7. [Kontrollimine](#7-kontrollimine)
8. [Järgmised Sammud](#8-järgmised-sammud)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Süsteeminõuded

### Minimaalsed Nõuded

| Komponent | Nõue |
|-----------|------|
| **OS** | Ubuntu 24.04 LTS |
| **RAM** | Min 8GB (Docker), 16GB (Kubernetes) |
| **CPU** | 4+ cores |
| **Disk** | 50GB+ vaba ruumi |
| **Võrk** | Staatiline IP sisevõrgus |
| **Proxy** | http://cache1.sss:3128 |

### Laborite Ressursinõuded

| Labor Tüüp | Õpilasi | RAM per õpilane | Kokku RAM |
|------------|---------|-----------------|-----------|
| Docker (Lab 1-2) | 3 | 2.5GB | ~10GB (+ host) |
| Kubernetes (Lab 3-10) | 3 | 5GB | ~18GB (+ host) |

**Märkus:** Võid alustada Docker laboritega (vähem ressursse) ja hiljem lisada Kubernetes laborid.

---

## 2. Quick Reference

### Proxy URL
```bash
http://cache1.sss:3128
```

### Peamised Konfiguratsioonifailid
```
/etc/apt/apt.conf.d/proxy.conf          # APT proxy
/etc/environment                         # Keskkonna muutujad
/etc/modules-load.d/k8s.conf            # Kernel moodulid (K8s)
/etc/sysctl.d/k8s.conf                  # Sysctl (K8s)
```

### Peamised Käsud
```bash
# Proxy kontrollimine
env | grep -i proxy
apt-get update
curl -I https://google.com

# LXD kontrollimine
lxc list
lxc network list
lxc storage list

# Kernel moodulite kontrollimine (K8s)
lsmod | grep overlay
lsmod | grep br_netfilter
```

---

## 3. Host Süsteemi Ettevalmistus

### 3.1 Proxy Seadistamine

**⚠️ OLULINE:** Proxy keskkonna jaoks pead seadistama 3 kohta!

#### 3.1.1 APT Proxy (paketihaldur)

```bash
sudo tee /etc/apt/apt.conf.d/proxy.conf << 'EOF'
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF
```

#### 3.1.2 Keskkonna Muutujad (kõigile kasutajatele)

```bash
sudo tee -a /etc/environment << 'EOF'
http_proxy="http://cache1.sss:3128"
https_proxy="http://cache1.sss:3128"
HTTP_PROXY="http://cache1.sss:3128"
HTTPS_PROXY="http://cache1.sss:3128"
no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF

# Lae keskkond uuesti
source /etc/environment
```

#### 3.1.3 Snap Proxy (LXD image'ite allalaadimiseks)

```bash
sudo snap set system proxy.http="http://cache1.sss:3128"
sudo snap set system proxy.https="http://cache1.sss:3128"
```

#### 3.1.4 Proxy Kontrollimine

```bash
# APT
cat /etc/apt/apt.conf.d/proxy.conf

# Keskkond
echo $http_proxy

# Snap
snap get system proxy

# Testi ühendust
sudo apt-get update
curl -I https://google.com
```

**Oodatav tulemus:** `apt-get update` töötab ja `curl` tagastab HTTP 200/301.

| Komponent | Fail/Käsk | Mida mõjutab |
|-----------|-----------|--------------|
| APT | `/etc/apt/apt.conf.d/proxy.conf` | `apt-get`, `apt` |
| Keskkond | `/etc/environment` | `curl`, `wget`, `git`, jne |
| Snap | `snap set system proxy.*` | `snap install`, LXD image download |

### 3.2 Süsteemi Uuendamine

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

### 3.3 Swap Seadistamine (kui puudub)

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

## 4. LXD Paigaldamine

### 4.1 LXD Snap

```bash
sudo snap install lxd
sudo usermod -aG lxd $USER
newgrp lxd

# Kontrolli
lxd --version
```

### 4.2 LXD Initialiseerimine

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

### 4.3 LXD Kontrollimine

```bash
lxc network list
lxc storage list
lxc profile list
```

**Oodatav väljund:**

```bash
# lxc network list
+--------+----------+---------+
|  NAME  |   TYPE   | MANAGED |
+--------+----------+---------+
| lxdbr0 | bridge   | YES     |
+--------+----------+---------+

# lxc storage list
+---------+-------------+
|  NAME   | DRIVER      |
+---------+-------------+
| default | dir         |
+---------+-------------+

# lxc profile list
+---------+
|  NAME   |
+---------+
| default |
+---------+
```

---

## 5. Kernel Moodulite Laadmine

**⚠️ OLULINE:** See sektsioon on vajalik **ainult Kubernetes laborite jaoks** (Lab 3-10).

**Kui plaanid ainult Docker laboreid (Lab 1-2), võid selle sektsiooni vahele jätta.**

### Miks on vaja?

Kubernetes vajab spetsiifilisi kernel mooduleid võrgu (Flannel CNI) ja konteinerite töötamiseks:
- **overlay:** Docker/containerd storage driver
- **br_netfilter:** Kubernetes võrgu iptables filtreerimine

**KRIITILINE:** LXD konteinerid jagavad HOST'i kerneli, seega moodulid tuleb laadida HOST masinas, mitte konteineris!

### 5.1 overlay ja br_netfilter Moodulid

```bash
# Laadi moodulid kohe
sudo modprobe overlay
sudo modprobe br_netfilter

# Tee moodulid püsivaks (reboot'i järel)
sudo tee /etc/modules-load.d/k8s.conf << 'EOF'
overlay
br_netfilter
EOF

# Kontrolli, et moodulid on laaditud
lsmod | grep overlay
lsmod | grep br_netfilter
```

**Oodatav väljund:**
```
overlay               151552  0
br_netfilter           32768  0
```

### 5.2 Sysctl Seadistused

```bash
# Loo sysctl konfiguratsioon
sudo tee /etc/sysctl.d/k8s.conf << 'EOF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Rakenda seadistused
sudo sysctl --system

# Kontrolli
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
```

**Oodatav tulemus:**
```
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
```

### 5.3 Verifitseerimine

```bash
# Kontrolli, et kõik 3 seadistust on aktiivsed
echo "=== Kernel Moodulid ==="
lsmod | grep -E 'overlay|br_netfilter'

echo ""
echo "=== Sysctl Seadistused ==="
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
```

**Peaks näitama:**
- overlay moodul laaditud
- br_netfilter moodul laaditud
- Kõik 3 sysctl väärtust = 1

---

## 6. Turvalisus

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

**Kui hiljem vaja (nt avalik server):** Vaata põhijuhendit või küsi süsteemiadministraatorilt.

---

## 7. Kontrollimine

### 7.1 Proxy Kontrollimine

```bash
# Keskkonna muutujad
env | grep -i proxy

# APT
cat /etc/apt/apt.conf.d/proxy.conf

# Snap
snap get system proxy

# Testi ühendust
curl -I https://google.com
sudo apt-get update
```

### 7.2 LXD Kontrollimine

```bash
# LXD versioon
lxd --version

# LXD komponendid
lxc network list
lxc storage list
lxc profile list

# Testi konteineri käivitamine (kiire test)
lxc launch ubuntu:24.04 test-container
lxc list test-container
lxc delete --force test-container
```

### 7.3 Kernel Moodulite Kontrollimine (kui K8s)

```bash
# Ainult kui plaanid Kubernetes laboreid!
lsmod | grep overlay
lsmod | grep br_netfilter
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
```

---

## 8. Järgmised Sammud

**✅ Host süsteem on nüüd valmis!**

### Vali labor tüüp:

#### Variant A: Docker Laborid (Lab 1-2)
👉 **Jätka:** [ADMIN-GUIDE-DOCKER-PROXY.md](ADMIN-GUIDE-DOCKER-PROXY.md)

**Mida hõlmab:**
- LXD profiili loomine (devops-lab: 2.5GB RAM, 1 CPU)
- Docker template loomine (devops-lab-base)
- Õpilaskonteinerite loomine (student1-3)
- Labs failide sünkroniseerimine
- Port forwarding (SSH, Web, API)

**Ressursid:** ~10GB RAM kokku (3 õpilast)

---

#### Variant B: Kubernetes Laborid (Lab 3-10)
👉 **Jätka:** [ADMIN-GUIDE-K8S-PROXY.md](ADMIN-GUIDE-K8S-PROXY.md)

**⚠️ EELDUS:** Kernel moodulid peavad olema laaditud (sektsioon 5)!

**Mida hõlmab:**
- LXD profiili loomine (devops-lab-k8s: 5GB RAM, 2 CPU)
- Kubernetes template loomine (k8s-lab-base)
- Õpilaskonteinerite loomine (student1-3)
- Kubernetes klastri initialiseerimine
- Labs failide sünkroniseerimine
- Port forwarding (SSH, K8s API, Ingress)

**Ressursid:** ~18GB RAM kokku (3 õpilast)

---

#### Variant C: Mõlemad
Võid luua mõlemad laborikeskkonnad:

1. **Loo Docker laborid:** [ADMIN-GUIDE-DOCKER-PROXY.md](ADMIN-GUIDE-DOCKER-PROXY.md)
2. **Loo K8s laborid:** [ADMIN-GUIDE-K8S-PROXY.md](ADMIN-GUIDE-K8S-PROXY.md)

**Järjekord ei ole oluline** - Docker ja K8s juhendid on üksteisest sõltumatud!

**Ressursid:** ~28GB RAM kokku (mõlemad)

---

## 9. Troubleshooting

### 9.1 Proxy Ei Tööta

**Sümptom:** `apt-get update` annab vea või `curl` ei tööta

**Kontrolli:**
```bash
# 1. Keskkonna muutujad
env | grep -i proxy
# Peaks näitama: http_proxy=http://cache1.sss:3128

# 2. APT konfiguratsioon
cat /etc/apt/apt.conf.d/proxy.conf
# Peaks sisaldama: Acquire::http::Proxy "http://cache1.sss:3128";

# 3. Snap konfiguratsioon
snap get system proxy
# Peaks näitama: http ja https seadistatud
```

**Lahendus:** Korda sektsiooni 3.1 samm-sammult

### 9.2 LXD Init Ebaõnnestub

**Sümptom:** `lxd init` annab vea

**Kontrolli:**
```bash
# 1. Kontrolli, kas LXD on paigaldatud
snap list lxd

# 2. Kontrolli kasutajaõigusi
groups | grep lxd

# 3. Proovi restart
sudo snap restart lxd
```

**Lahendus:**
```bash
# Kui lxd grupp puudub
sudo usermod -aG lxd $USER
newgrp lxd

# Proovi uuesti
lxd init
```

### 9.3 Kernel Moodulid Ei Laadunud

**Sümptom:** `lsmod | grep overlay` ei näita midagi

**Kontrolli:**
```bash
# Proovi manuaalselt laadida
sudo modprobe overlay
sudo modprobe br_netfilter

# Kontrolli
lsmod | grep -E 'overlay|br_netfilter'
```

**Lahendus:**
```bash
# Kui annab vea, kontrolli kernel'i
uname -r
# Peaks olema: 5.x või 6.x

# Kontrolli /etc/modules-load.d/k8s.conf
cat /etc/modules-load.d/k8s.conf

# Peaks sisaldama:
# overlay
# br_netfilter
```

### 9.4 Test Konteineri Loomine Ebaõnnestub

**Sümptom:** `lxc launch ubuntu:24.04 test` annab vea

**Võimalikud põhjused:**
1. Proxy ei tööta (snap ei saa image'it alla)
2. LXD storage või network probleemid

**Kontrolli:**
```bash
# 1. Snap proxy
snap get system proxy

# 2. LXD storage
lxc storage list
lxc storage show default

# 3. LXD network
lxc network list
lxc network show lxdbr0

# 4. Vaata täpsemaid logisid
journalctl -u snap.lxd.daemon -n 50
```

**Lahendus:**
```bash
# Proovi reinit
lxd init

# Või proovi image'it käsitsi
lxc image list images: | grep ubuntu/24.04
```

---

## Kokkuvõte

**✅ Mida tegime:**
- ✅ Seadistasime proxy (APT, keskkond, Snap)
- ✅ Paigaldasime ja initsialiseerisime LXD
- ✅ Laadisime kernel moodulid (Kubernetes jaoks)
- ✅ Kontrollisime süsteemi valmisolekut

**🎯 Järgmised sammud:**
- 👉 Docker laborid: [ADMIN-GUIDE-DOCKER-PROXY.md](ADMIN-GUIDE-DOCKER-PROXY.md)
- 👉 K8s laborid: [ADMIN-GUIDE-K8S-PROXY.md](ADMIN-GUIDE-K8S-PROXY.md)

**📚 Seotud dokumendid:**
- [ADMIN-GUIDE-DOCKER-PROXY.md](ADMIN-GUIDE-DOCKER-PROXY.md) - Docker laborite administreerimine
- [ADMIN-GUIDE-K8S-PROXY.md](ADMIN-GUIDE-K8S-PROXY.md) - Kubernetes laborite administreerimine

---

**Autor:** DevOps Lab Admin
**Versioon:** 1.0
**Viimane uuendus:** 2025-12-02
**Proxy:** cache1.sss:3128
**Keskkond:** Ettevõtte sisevõrk
