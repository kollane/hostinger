# Docker Laborite Administraatori Juhend (Proxy Keskkond)

## Ülevaade

See juhend on mõeldud administraatorile, kes haldab LXD-põhist DevOps Docker laborikeskkonda **ettevõtte sisevõrgus proxy serveri kaudu**.

**Keskkond:**
- Server: mtadocker1test
- Proxy: cache1.sss:3128
- Template: devops-lab-base
- Labs: Lab 1-2 (Docker, Docker Compose, multi-stage builds)
- Õpilased: Kuni 6 kohta

**Erinevused standardkeskkonnast:**
- ✅ Proxy konfiguratsioon (APT, Docker daemon, containerd)
- ✅ Labs asukoht: ~/projects/labs (mitte ~/projects/hostinger/labs)
- ✅ Minimaalne SSH turvalisus (sisevõrk, ei vaja UFW/fail2ban)
- ✅ Täielikud sync skriptid

## Kiirviited

- [Süsteemi ülevaade](#süsteemi-ülevaade)
- [Proxy konfiguratsiooni haldamine](#1-proxy-konfiguratsiooni-haldamine)
- [Konteinerite haldamine](#2-konteinerite-haldamine)
- [Labs failide sünkroniseerimine](#3-labs-failide-sünkroniseerimine)
- [SSH ja turvalisus](#4-ssh-ja-turvalisus-sisevõrk)
- [Ressursside monitooring](#5-ressursside-monitooring)
- [Backup ja taastamine](#6-backup-ja-taastamine)
- [Template uuendamine](#7-template-uuendamine)
- [Uue õpilase lisamine](#8-uue-õpilase-lisamine-kuni-6-kohta)
- [Probleemide lahendamine](#9-probleemide-lahendamine-proxy-keskkond)
- [Kasulikud käsud](#10-kasulikud-käsud)
- [Quick reference](#11-quick-reference)

---

## Süsteemi Ülevaade

**Server:**
- Nimi: mtadocker1test
- OS: Ubuntu 24.04 LTS
- Proxy: cache1.sss:3128
- Keskkond: Ettevõtte sisevõrk

**Template:**
- Nimi: devops-lab-base
- Base: Ubuntu 24.04 + Docker 29.0.4
- RAM: 2.5GB per student
- CPU: 1 core per student
- Tööriistad: Docker, Java 21, Node.js 20

**Konteinerid (kuni 6 kohta):**
- devops-student1 (SSH: 2201)
- devops-student2 (SSH: 2202)
- devops-student3 (SSH: 2203)
- devops-student4 (SSH: 2204) - vajadusel
- devops-student5 (SSH: 2205) - vajadusel
- devops-student6 (SSH: 2206) - vajadusel

**Ressursid:**
- 6 × 2.5GB = 15GB RAM + host overhead

**Labs:**
- Asukoht: ~/projects/labs
- Laborid: Lab 1-2
- Teemad: Docker basics, Dockerfile, multi-stage builds, Docker Compose, PostgreSQL

---

## 1. Proxy Konfiguratsiooni Haldamine

### 1.1 Host Proxy Seadistamine

**APT Proxy:**

```bash
# Kontrolli praegust seadistust
cat /etc/apt/apt.conf.d/proxy.conf

# Lisa või uuenda
sudo tee /etc/apt/apt.conf.d/proxy.conf << 'EOF'
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF

# Testi
sudo apt-get update
```

**Environment Variables:**

```bash
# /etc/environment
sudo tee -a /etc/environment << 'EOF'
http_proxy="http://cache1.sss:3128"
https_proxy="http://cache1.sss:3128"
no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
HTTP_PROXY="http://cache1.sss:3128"
HTTPS_PROXY="http://cache1.sss:3128"
NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF

# Rakenda
source /etc/environment
```

**Snap Proxy (LXD image download'ide jaoks):**

```bash
sudo snap set system proxy.http="http://cache1.sss:3128"
sudo snap set system proxy.https="http://cache1.sss:3128"
```

**Proxy Kontrollimine:**

```bash
# Kontrolli environment
env | grep -i proxy

# Testi HTTP ühendust
curl -I https://google.com

# Testi APT
sudo apt-get update
```

### 1.2 Konteineri Proxy Seadistamine

**APT Proxy konteineris:**

```bash
lxc exec devops-student1 -- bash -c 'cat > /etc/apt/apt.conf.d/proxy.conf << "EOF"
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF'

# Testi
lxc exec devops-student1 -- apt-get update
```

**Environment Variables konteineris:**

```bash
# /etc/environment
lxc exec devops-student1 -- bash -c 'cat >> /etc/environment << "EOF"
http_proxy="http://cache1.sss:3128"
https_proxy="http://cache1.sss:3128"
no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
HTTP_PROXY="http://cache1.sss:3128"
HTTPS_PROXY="http://cache1.sss:3128"
NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF'

# /etc/profile.d/proxy.sh (login shell'i jaoks)
lxc exec devops-student1 -- bash -c 'cat > /etc/profile.d/proxy.sh << "EOF"
export http_proxy="http://cache1.sss:3128"
export https_proxy="http://cache1.sss:3128"
export no_proxy="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
export HTTP_PROXY="http://cache1.sss:3128"
export HTTPS_PROXY="http://cache1.sss:3128"
export NO_PROXY="localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF'
```

**Docker Daemon Proxy:**

```bash
lxc exec devops-student1 -- bash -c '
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/proxy.conf << "EOF"
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF

systemctl daemon-reload
systemctl restart docker
'
```

**containerd Proxy (KRIITILINE!):**

```bash
lxc exec devops-student1 -- bash -c '
mkdir -p /etc/systemd/system/containerd.service.d
cat > /etc/systemd/system/containerd.service.d/proxy.conf << "EOF"
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF

systemctl daemon-reload
systemctl restart containerd
systemctl restart docker
'
```

**⚠️ OLULINE:**
- Docker template ei vaja `.svc,.cluster.local` no_proxy seadistuses (see on vajalik ainult Kubernetes klastrites)
- containerd proxy on KRIITILINE Docker image pull'ide jaoks

### 1.3 Proxy Testimine

**Host tasemel:**

```bash
# Environment
env | grep -i proxy

# HTTP ühendus
curl -I https://google.com

# APT
apt-get update
```

**Konteineri tasemel:**

```bash
# Environment (kasuta login shell'i!)
lxc exec devops-student1 -- bash -l -c 'env | grep -i proxy'

# HTTP ühendus
lxc exec devops-student1 -- curl -I https://google.com

# APT
lxc exec devops-student1 -- apt-get update

# Docker pull (peamine test!)
lxc exec devops-student1 -- docker pull alpine:3.16
```

**⚠️ NB:** Kui `lxc exec devops-student1 -- bash` ei lae proxy muutujaid, kasuta `bash -l` (login shell) või `su -`.

### 1.4 Proxy Credentials (kui vajalik)

Kui proxy server vajab autentimist:

```bash
# Kodeeri username:password Base64-s
echo -n "username:password" | base64

# Lisa proxy URL'ile
http_proxy="http://username:password@cache1.sss:3128"

# VÕI kasutades Base64 encoded string'i (turvalisem)
http_proxy="http://$(echo -n 'username:password' | base64)@cache1.sss:3128"
```

Salvesta credentials turvaliselt:

```bash
# Loo fail (ainult root näeb)
sudo tee /root/proxy-credentials.txt << 'EOF'
username:password
EOF

sudo chmod 600 /root/proxy-credentials.txt
```

---

## 2. Konteinerite Haldamine

### Põhikäsud

```bash
# Vaata kõiki konteinereid
lxc list

# Detailne info konteinerist
lxc info devops-student1

# Logi konteinerisse (root)
lxc exec devops-student1 -- bash

# Logi konteinerisse (labuser)
lxc exec devops-student1 -- su - labuser

# Logi konteinerisse (labuser, login shell - proxy muutujad laaditakse)
lxc exec devops-student1 -- bash -l -c 'su - labuser'
```

### Konteineri Elutsükkel

```bash
# Käivita konteiner
lxc start devops-student1

# Peata konteiner
lxc stop devops-student1

# Taaskäivita konteiner
lxc restart devops-student1

# Kustuta konteiner
lxc delete devops-student1

# Kustuta töötav konteiner (force)
lxc delete --force devops-student1
```

### Failide Kopeerimine

```bash
# Host → Container
lxc file push /path/to/file devops-student1/home/labuser/

# Container → Host
lxc file pull devops-student1/home/labuser/file.txt /tmp/

# Rekursiivne kopeerimine
lxc file push -r /path/to/dir/ devops-student1/home/labuser/
```

### Käskude Käivitamine Konteineris

```bash
# Üksik käsk
lxc exec devops-student1 -- docker ps

# Mitme käsu jada
lxc exec devops-student1 -- bash -c 'cd /home/labuser && ls -la'

# Käsk kindla kasutajana
lxc exec devops-student1 -- su - labuser -c 'docker ps'
```

### Proxy Seadistuse Kontrollimine

```bash
# Kontrolli APT proxy't
lxc exec devops-student1 -- cat /etc/apt/apt.conf.d/proxy.conf

# Kontrolli environment proxy't
lxc exec devops-student1 -- bash -l -c 'env | grep -i proxy'

# Kontrolli Docker daemon proxy't
lxc exec devops-student1 -- systemctl show --property=Environment docker

# Kontrolli containerd proxy't
lxc exec devops-student1 -- systemctl show --property=Environment containerd

# Kontrolli containerd versiooni (peaks olema 1.7.28)
lxc exec devops-student1 -- containerd --version
```

---

## 3. Labs Failide Sünkroniseerimine

### 3.1 Ülevaade

Labs failid asuvad host masinas `~/projects/labs/` kataloogis ja need tuleb sünkroniseerida konteineritesse.

**Workflow:**
1. Host'il: Muuda faile git repo's (`~/projects/labs/`)
2. Host'il: Commit & push muudatused (valikuline)
3. Host'il: Käivita sync skript
4. Failid kopeeritakse konteineritesse (`/home/labuser/labs/`)

**Skriptide asukoht:** `~/scripts/`

### 3.2 Git Repositooriumi Seadistamine

```bash
# Loo projects kataloog
cd ~
mkdir -p projects
cd projects

# Klooni labs repositoorium
git clone https://github.com/yourusername/devops-labs.git labs

# VÕI kui juba kloonitud
cd labs && git pull
```

**Proxy seadistus git'i jaoks (kui vaja):**

```bash
git config --global http.proxy http://cache1.sss:3128
git config --global https.proxy http://cache1.sss:3128
```

### 3.3 Sync Skriptide Loomine

#### sync-labs.sh (üks konteiner)

```bash
mkdir -p ~/scripts
cat > ~/scripts/sync-labs.sh << 'EOFSCRIPT'
#!/bin/bash
# Sync labs to single Docker container

set -e

CONTAINER="${1:-}"
SOURCE_DIR="${LABS_SOURCE:-$HOME/projects/labs}"

if [ -z "$CONTAINER" ]; then
  echo "Usage: $0 <container-name>"
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Labs source not found: $SOURCE_DIR"
  exit 1
fi

echo "====================================="
echo "Syncing labs to $CONTAINER"
echo "====================================="

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
EOFSCRIPT

chmod +x ~/scripts/sync-labs.sh
```

#### sync-all-students.sh (kõik konteinerid)

```bash
cat > ~/scripts/sync-all-students.sh << 'EOFSCRIPT'
#!/bin/bash
# Sync labs to all Docker student containers

set -e

SOURCE_DIR="${LABS_SOURCE:-$HOME/projects/labs}"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Labs source not found: $SOURCE_DIR"
  exit 1
fi

echo "====================================="
echo "Syncing labs to all Docker students"
echo "====================================="

# Find all Docker student containers
CONTAINERS=$(lxc list --format csv -c n | grep -E "^devops-student" || true)

if [ -z "$CONTAINERS" ]; then
  echo "No student containers found"
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

echo "✅ All Docker students updated!"
EOFSCRIPT

chmod +x ~/scripts/sync-all-students.sh
```

#### check-versions.sh (kontrolli versioone)

```bash
cat > ~/scripts/check-versions.sh << 'EOFSCRIPT'
#!/bin/bash
# Check last modified date of labs in all containers

echo "Lab Versions (last modified):"
echo "=============================="

for CONTAINER in $(lxc list --format csv -c n | grep -E "^devops-student"); do
  VERSION=$(lxc exec $CONTAINER -- stat -c %y /home/labuser/labs 2>/dev/null | cut -d' ' -f1 || echo "N/A")
  echo "$CONTAINER: $VERSION"
done

echo ""
echo "Host version:"
stat -c %y ~/projects/labs | cut -d' ' -f1
EOFSCRIPT

chmod +x ~/scripts/check-versions.sh
```

**Kontrolli skriptide õigusi:**

```bash
ls -l ~/scripts/
# Kõik .sh failid peavad olema executable (rwxr-xr-x)
```

### 3.4 Labs Sünkroniseerimine (igapäevane töövoog)

**1. Uuenda labs host'il:**

```bash
cd ~/projects/labs
git pull
```

**2. Kontrolli, millised konteinerid vajavad uuendamist:**

```bash
~/scripts/check-versions.sh
```

**3. Sync kõik või mõned:**

```bash
# Kõik korraga
~/scripts/sync-all-students.sh

# VÕI üksikud konteinerid
~/scripts/sync-labs.sh devops-student1
~/scripts/sync-labs.sh devops-student3
```

**4. Kontrolli uuesti:**

```bash
~/scripts/check-versions.sh
```

### 3.5 Backup'ide Taastamine

**Vaata backup'e:**

```bash
# Vaata, millised backup'id on olemas
lxc exec devops-student1 -- ls -lh /tmp/labs-backup-*.tar.gz

# Kuvab näiteks:
# -rw-r--r-- 1 root root 12M Nov 25 14:30 /tmp/labs-backup-20251125-143022.tar.gz
```

**Taasta backup:**

```bash
# Taasta konkreetne backup
lxc exec devops-student1 -- bash -c 'rm -rf /home/labuser/labs && tar -xzf /tmp/labs-backup-20251202-143022.tar.gz -C /home/labuser/'

# Taasta ownership
lxc exec devops-student1 -- chown -R labuser:labuser /home/labuser/labs
```

---

## 4. SSH ja Turvalisus (Sisevõrk)

### 4.1 Ülevaade

**⚠️ OLULINE:** See on ettevõtte sisevõrgu keskkond, turvalisus on lihtsustatud.

**Eeldu<Pred:**
- Ettevõtte tulemüür kaitseb serveri väliste rünnakute eest
- Sisevõrgust brute-force rünnakud on ebatõenäolised
- Laborikeskkond õppeotstarbel, mitte tootmiskeskkond

### 4.2 Mida EI kasutata (sisevõrgus)

- ❌ **UFW Firewall:** Ettevõtte tulemüür kaitseb, UFW võib segada LXD võrku
- ❌ **fail2ban:** Brute-force sisevõrgust ebatõenäoline
- ❌ **SSH hardening:** Laborikeskkond, lihtsad paroolid on OK

**Viide:** Täpsem selgitus K8S-INSTALLATION.md sektsioon 3.

### 4.3 SSH Seadistus (minimaalne)

**Kontrolli SSH teenust:**

```bash
lxc exec devops-student1 -- systemctl status ssh
```

**SSH Port Forwarding (host → container):**

```bash
# Student1
lxc config device add devops-student1 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2201 connect=tcp:127.0.0.1:22 nat=true

# Student2
lxc config device add devops-student2 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2202 connect=tcp:127.0.0.1:22 nat=true

# Student3
lxc config device add devops-student3 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2203 connect=tcp:127.0.0.1:22 nat=true
```

### 4.4 Paroolide Haldamine

```bash
# Loo paroolide fail (kuni 6 õpilast)
cat > ~/student-passwords.txt << 'EOF'
# Docker Lab Passwords (kuni 6 kohta)
devops-student1: student1
devops-student2: student2
devops-student3: student3
devops-student4: student4
devops-student5: student5
devops-student6: student6
EOF

chmod 600 ~/student-passwords.txt
```

**Parooli vahetus:**

```bash
# Genereeri uus parool (valikuline)
NEW_PASS=$(openssl rand -base64 16)

# Sea parool
lxc exec devops-student1 -- bash -c "echo 'labuser:$NEW_PASS' | chpasswd"

# Salvesta
echo "devops-student1 new password: $NEW_PASS" >> ~/student-passwords.txt
```

### 4.5 Port Mapping (SSH + Web)

| Student | SSH Port | Frontend | User API | Todo API |
|---------|----------|----------|----------|----------|
| student1 | 2201 | 8080 | 3000 | 8081 |
| student2 | 2202 | 8180 | 3100 | 8181 |
| student3 | 2203 | 8280 | 3200 | 8281 |
| student4 | 2204 | 8380 | 3300 | 8381 |
| student5 | 2205 | 8480 | 3400 | 8481 |
| student6 | 2206 | 8580 | 3500 | 8581 |

### 4.6 SSH Sisselogimine

```bash
# Üldine formaat
ssh labuser@<HOST-IP> -p <SSH-PORT>

# Näide: Student1
ssh labuser@192.168.1.100 -p 2201
# Parool: student1

# Näide: Student3
ssh labuser@192.168.1.100 -p 2203
# Parool: student3
```

### 4.7 Kui Vaja Avalikku Keskkonda

Kui server oleks avalikus võrgus (internet), tuleks rakendada täielik turvalisus:

- **UFW Firewall** rate limiting
- **fail2ban** SSH kaitse
- **SSH hardening** (MaxAuthTries, LoginGraceTime, tugevad paroolid)

Vaata põhijuhendit INSTALLATION.md sektsioonid 5.1-5.3.

---

## 5. Ressursside Monitooring

### RAM Kasutus

```bash
# Host RAM
free -h

# Kõik konteinerid korraga
lxc list -c ns4M

# Ühe konteineri detailne info
lxc info devops-student1 | grep -A 3 "Memory usage"
```

**Tavaline kasutus:**
- Idle (konteiner käivitatud, Docker idle): ~260MB
- Docker Compose käivitatud: ~500-800MB
- Kõik 3 teenust käimas: ~1-1.5GB

**Limiidid:**
- Per student: 2.5GB RAM
- 6 × 2.5GB = 15GB RAM + host overhead

### CPU Kasutus

```bash
# Host CPU
htop
# või
top

# Konteineri CPU
lxc info devops-student1 | grep -A 3 "CPU usage"

# Live monitoring
htop
# Filtreeri: F4, sisesta "lxc"
```

**Limiidid:**
- Per student: 1 CPU core

### Disk Kasutus

```bash
# Host disk
df -h

# Konteineri disk
lxc exec devops-student1 -- df -h

# LXD storage pool
lxc storage info default
```

### Network Monitoring

```bash
# Konteineri network stats
lxc info devops-student1 | grep -A 5 "Network usage"

# Port forwarding kontrollimine
netstat -tuln | grep -E ':(2201|2202|2203|2204|2205|2206|8080|8180|8280)'

# Konteineri avatud pordid
lxc exec devops-student1 -- netstat -tuln
```

### Ressursside Limiidid

```bash
# Vaata praeguseid limiite
lxc config show devops-student1

# Muuda RAM limiiti (2.5GB → 3GB)
lxc config set devops-student1 limits.memory 3GB

# Muuda CPU limiiti (1 → 2 cores)
lxc config set devops-student1 limits.cpu 2

# Taaskäivita, et muudatused rakenduksid
lxc restart devops-student1
```

---

## 6. Backup ja Taastamine

### Snapshot'id

```bash
# Loo snapshot
lxc snapshot devops-student1 before-lab2

# Vaata snapshot'e
lxc info devops-student1 | grep Snapshots -A 20

# Taasta snapshot
lxc restore devops-student1 before-lab2

# Kustuta snapshot
lxc delete devops-student1/before-lab2
```

**Soovitatud snapshot strateegia:**
- Enne iga labo algust: `before-lab-N`
- Pärast edukat labi: `after-lab-N-success`
- Enne suuri muudatusi: `before-changes-YYYY-MM-DD`

### Image Export/Import

```bash
# Ekspordi konteiner image'ina
lxc publish devops-student1 --alias student1-backup-2025-12-02

# Vaata salvestatud image'id
lxc image list

# Ekspordi image failina
lxc image export student1-backup-2025-12-02 /backup/

# Impordi image failist
lxc image import /backup/image.tar.gz --alias restored-backup

# Loo konteiner backed up image'ist
lxc launch restored-backup devops-student1-restored
```

### Täielik Backup Skript

```bash
#!/bin/bash
# backup-all-students.sh

DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/lxd-students"

mkdir -p "$BACKUP_DIR"

for STUDENT in devops-student{1..6}; do
    # Kontrolli, kas konteiner eksisteerib
    if lxc list --format csv -c n | grep -q "^${STUDENT}$"; then
        echo "Backing up $STUDENT..."

        # Snapshot
        lxc snapshot $STUDENT backup-$DATE

        # Export as image
        lxc publish $STUDENT --alias ${STUDENT}-backup-$DATE

        # Export to file
        lxc image export ${STUDENT}-backup-$DATE $BACKUP_DIR/${STUDENT}-$DATE

        echo "$STUDENT backup complete"
    fi
done

echo "All backups complete in $BACKUP_DIR"
```

**Salvesta ja käivita:**

```bash
cat > ~/scripts/backup-all-students.sh << 'EOFSCRIPT'
[... ülaltoodud skript ...]
EOFSCRIPT

chmod +x ~/scripts/backup-all-students.sh
~/scripts/backup-all-students.sh
```

---

## 7. Template Uuendamine

### 7.1 Millal Uuendada?

- Docker versioon uuendatud
- Labs uuendatud
- Security updates
- Diagnostika tööriistad lisatud/uuendatud (jq, nmap, tcpdump, netcat-openbsd, dnsutils, net-tools)
- Sudo konfiguratsioon muutub

### 7.2 Template Uuendamise Protsess

```bash
# 1. Loo ajutine konteiner
lxc launch devops-lab-base temp-update -p default -p devops-lab

# 2. Logi sisse
lxc exec temp-update -- bash

# 3. Uuenda proxy seadistused (kui vaja)
cat > /etc/apt/apt.conf.d/proxy.conf << 'EOF'
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF

# 4. Uuenda süsteem
apt-get update
apt-get upgrade -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
# NB! ÄRA upgrade containerd.io - lukustatud 1.7.28

# 5. Verifitseeri containerd
containerd --version
# Peaks olema: 1.7.28
apt-mark showhold | grep containerd
# Peaks olema: containerd.io

# 6. Kui containerd on 1.7.29+ või 2.x, downgrade
apt install -y --allow-downgrades containerd.io=1.7.28-1~ubuntu.24.04~noble
apt-mark hold containerd.io

# 7. Diagnostika tööriistad (kui pole juba)
apt-get install -y jq nmap tcpdump netcat-openbsd dnsutils net-tools iproute2

# 8. Sudo konfiguratsioon (kui muutub)
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

chmod 0440 /etc/sudoers.d/labuser-devops
chown root:root /etc/sudoers.d/labuser-devops
visudo -c -f /etc/sudoers.d/labuser-devops

# 9. Testi sudo
su - labuser -c 'sudo lsof -i :22'

# 10. Puhasta
apt-get clean
rm -rf /tmp/* /var/tmp/*
history -c
exit

# 11. Peata konteiner
lxc stop temp-update

# 12. Backup vana template
lxc image export devops-lab-base /tmp/devops-lab-base-backup-$(date +%Y%m%d)

# 13. Kustuta vana alias
lxc image delete devops-lab-base

# 14. Publitseeri uus
lxc publish temp-update --alias devops-lab-base \
  description="DevOps Lab Template: Ubuntu 24.04 + Docker + Java 21 + Node.js 20 + Proxy (Updated $(date +%Y-%m-%d))"

# 15. Kustuta ajutine konteiner
lxc delete temp-update

# 16. Testi uut template'i
lxc launch devops-lab-base test-new-template -p default -p devops-lab
lxc exec test-new-template -- docker --version
lxc exec test-new-template -- ls -la /home/labuser/labs/
lxc delete --force test-new-template
```

---

## 8. Uue Õpilase Lisamine (kuni 6 kohta)

**Märkus:** Süsteem toetab kuni 6 õpilast. Alltoodud näited student4, student5, student6 jaoks.

### 8.1 Student4 Lisamine

```bash
# 1. Käivita konteiner
lxc launch devops-lab-base devops-student4 -p default -p devops-lab

# 2. Oota IP
sleep 15
lxc list devops-student4

# 3. Sea parool
lxc exec devops-student4 -- bash -c 'echo "labuser:student4" | chpasswd'

# 4. Port forwarding (vt port mapping tabel sektsioon 4.5)
lxc config device add devops-student4 ssh-proxy proxy \
  listen=tcp:0.0.0.0:2204 connect=tcp:127.0.0.1:22 nat=true

lxc config device add devops-student4 web-proxy proxy \
  listen=tcp:0.0.0.0:8380 connect=tcp:127.0.0.1:8080 nat=true

lxc config device add devops-student4 user-api-proxy proxy \
  listen=tcp:0.0.0.0:3300 connect=tcp:127.0.0.1:3000 nat=true

lxc config device add devops-student4 todo-api-proxy proxy \
  listen=tcp:0.0.0.0:8381 connect=tcp:127.0.0.1:8081 nat=true

# 5. Sync labs
~/scripts/sync-labs.sh devops-student4

# 6. Testi SSH
ssh labuser@<HOST-IP> -p 2204
# Password: student4
```

### 8.2 Student5 ja Student6 Lisamine

Analoogselt student4-le, kasuta järgmisi porte (vt tabel sektsioon 4.5):
- **Student5:** SSH 2205, Frontend 8480, User API 3400, Todo API 8481
- **Student6:** SSH 2206, Frontend 8580, User API 3500, Todo API 8581

---

## 9. Probleemide Lahendamine (Proxy Keskkond)

### 9.1 Proxy Ei Tööta Konteineris

**Sümptom:**
```
apt-get update
E: Could not connect to archive.ubuntu.com:80
```

**Lahendus:**
```bash
# 1. Kontrolli proxy seadistust
lxc exec devops-student1 -- cat /etc/apt/apt.conf.d/proxy.conf
lxc exec devops-student1 -- cat /etc/environment

# 2. Lisa proxy käsitsi kui puudub
lxc exec devops-student1 -- bash -c 'cat > /etc/apt/apt.conf.d/proxy.conf << EOF
Acquire::http::Proxy "http://cache1.sss:3128";
Acquire::https::Proxy "http://cache1.sss:3128";
EOF'

# 3. Testi
lxc exec devops-student1 -- apt-get update
```

### 9.2 Docker Pull Ei Tööta (Proxy)

**Sümptom:**
```
docker pull alpine:3.16
Error response from daemon: Get https://registry-1.docker.io/v2/: dial tcp: lookup registry-1.docker.io: no such host
```

**Lahendus:**
```bash
# 1. Kontrolli Docker daemon proxy't
lxc exec devops-student1 -- systemctl show --property=Environment docker

# 2. Lisa proxy kui puudub
lxc exec devops-student1 -- bash -c '
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/proxy.conf << "EOF"
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF

systemctl daemon-reload
systemctl restart docker
'

# 3. Testi
lxc exec devops-student1 -- docker pull alpine:3.16
```

### 9.3 containerd Pull Ei Tööta (Proxy)

**Sümptom:**
Kubernetes pods (kui kasutad K8s template'i) jäävad ImagePullBackOff olekusse.

**Lahendus:**
```bash
# 1. Lisa containerd proxy
lxc exec devops-student1 -- bash -c '
mkdir -p /etc/systemd/system/containerd.service.d
cat > /etc/systemd/system/containerd.service.d/proxy.conf << "EOF"
[Service]
Environment="HTTP_PROXY=http://cache1.sss:3128"
Environment="HTTPS_PROXY=http://cache1.sss:3128"
Environment="NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,192.168.0.0/16"
EOF

systemctl daemon-reload
systemctl restart containerd
'

# 2. Restart Docker
lxc exec devops-student1 -- systemctl restart docker
```

### 9.4 Proxy Login Shellis Ei Laadi

**Sümptom:**
```bash
lxc exec devops-student1 -- bash
env | grep -i proxy
# Tühi väljund
```

**Lahendus:**
```bash
# Kasuta login shell'i
lxc exec devops-student1 -- bash -l
env | grep -i proxy
# Nüüd peaks proxy muutujad olema

# VÕI
lxc exec devops-student1 -- su -
env | grep -i proxy
```

**Selgitus:** `/etc/environment` ja `/etc/profile.d/proxy.sh` laaditakse ainult login shell'is.

### 9.5 containerd Versioon on Vale

**Sümptom:**
```bash
containerd --version
# containerd.io 1.7.29 või 2.x
```

**Probleem:** containerd 1.7.29+ on bugine LXD keskkonnas (sysctl permission denied).

**Lahendus:**
```bash
# Downgrade containerd 1.7.28-le
lxc exec devops-student1 -- bash -c '
systemctl stop docker
apt install -y --allow-downgrades containerd.io=1.7.28-1~ubuntu.24.04~noble
apt-mark hold containerd.io
systemctl restart containerd
systemctl restart docker
'

# Testi
lxc exec devops-student1 -- docker run --rm alpine:3.16 echo "OK"
```

### 9.6 Konteinerid Ei Käivitu (Üldine)

```bash
# Kontrolli logisid
lxc info devops-student1 --show-log

# Proovi force start
lxc start devops-student1 --force

# Kui ei aita, loo uus template'ist
lxc delete --force devops-student1
lxc launch devops-lab-base devops-student1 -p default -p devops-lab
```

### 9.7 RAM Otsa

```bash
# 1. Kontrolli, kumb protsess kasutab palju
lxc exec devops-student1 -- ps aux --sort=-%mem | head -20

# 2. Peata mittevajalikud konteinerid
lxc stop devops-student2

# 3. Suurenda konteineri RAM limiiti
lxc config set devops-student1 limits.memory 3GB
lxc restart devops-student1
```

---

## 10. Kasulikud Käsud

### Proxy Debug

```bash
# Host proxy
env | grep -i proxy
curl -v -x http://cache1.sss:3128 https://google.com

# Container proxy
lxc exec devops-student1 -- env | grep -i proxy
lxc exec devops-student1 -- curl -v https://google.com

# Docker daemon proxy
lxc exec devops-student1 -- systemctl show --property=Environment docker

# APT proxy
lxc exec devops-student1 -- apt-config dump | grep -i proxy
```

### Konteinerite Haldamine

```bash
# Vaata kõiki
lxc list

# Restart kõik (kuni 6 õpilast)
for c in devops-student{1..6}; do lxc restart $c 2>/dev/null || true; done

# Docker versioon kõigis
for c in devops-student{1..6}; do echo "=== $c ==="; lxc exec $c -- docker --version 2>/dev/null || true; done

# containerd versioon kõigis
for c in devops-student{1..6}; do echo "=== $c ==="; lxc exec $c -- containerd --version 2>/dev/null || true; done
```

### Labs Sync

```bash
# Sync kõik
~/scripts/sync-all-students.sh

# Kontrolli versioone
~/scripts/check-versions.sh

# Sync üks
~/scripts/sync-labs.sh devops-student1
```

---

## 11. Quick Reference

| Tegevus | Käsk |
|---------|------|
| Vaata konteinereid | `lxc list` |
| Logi konteinerisse | `lxc exec <name> -- bash -l` |
| Restart | `lxc restart <name>` |
| Snapshot | `lxc snapshot <name> <snap-name>` |
| Vaata RAM-i | `lxc list -c ns4M` |
| Kontrolli Dockerit | `lxc exec <name> -- docker ps` |
| Sync labs | `~/scripts/sync-all-students.sh` |
| Kontrolli proxy | `lxc exec <name> -- env \| grep -i proxy` |
| Testi Docker pull | `lxc exec <name> -- docker pull alpine:3.16` |

---

**Viimane uuendus:** 2025-12-02
**Versioon:** 1.0
**Proxy:** cache1.sss:3128
**Hooldaja:** VPS Admin
**Keskkond:** Ettevõtte sisevõrk (proxy)
**Template:** devops-lab-base (Docker, Lab 1-2)
