# LXD DevOps Lab - Laptopi Kasutajajuhend

## Ülevaade

See juhend on mõeldud kasutajatele, kes käitavad DevOps laborikeskkonda **oma isiklikul arvutil** (laptop/desktop). Erinevalt VPS-põhisest seadistusest töötab kogu keskkond lokaalselt ja pordid on suunatud `localhost`-ile.

**Eeldused:**
- LXD on paigaldatud ja seadistatud (vaata INSTALLATION.md)
- Template image `devops-lab-base` on loodud
- Konteiner(id) on käivitatud

---

## Kiirstart

### 1. SSH Sisselogimine

```bash
# Docker labide jaoks (Lab 1-2)
ssh labuser@localhost -p 2201
# Parool: student1

# Kubernetes labide jaoks (Lab 3-10)
ssh labuser@localhost -p 2201
# Parool: student1
```

### 2. Esimesed Sammud Konteineris

```bash
# Kontrolli ressursse
check-resources

# Vaata laboreid
ls ~/labs/

# Alusta Lab 1
cd ~/labs/01-docker-lab/
cat README.md
```

### 3. Brauseris Ligipääs

| Teenus | URL | Kirjeldus |
|--------|-----|-----------|
| Frontend | http://localhost:8080 | React/Vue rakendus |
| User API | http://localhost:3000 | Node.js kasutajate API |
| Todo API | http://localhost:8081 | Java Spring Boot API |

**Kubernetes labide puhul:**

| Teenus | URL | Kirjeldus |
|--------|-----|-----------|
| K8s API | https://localhost:6443 | Kubernetes API server |
| Ingress HTTP | http://localhost:30080 | Kubernetes Ingress |
| Ingress HTTPS | https://localhost:30443 | Kubernetes Ingress (TLS) |

---

## Konteinerite Haldamine

### Praeguse Oleku Vaatamine

```bash
# Vaata kõiki konteinereid
lxc list

# Vaata ressursikasutust
lxc list -c ns4M

# Vaata konteineri detaile
lxc info devops-k8s-student1
```

### Konteineri Käivitamine ja Peatamine

```bash
# Käivita konteiner
lxc start devops-k8s-student1

# Peata konteiner
lxc stop devops-k8s-student1

# Restart
lxc restart devops-k8s-student1
```

### Otse Konteinerisse Sisenemine

```bash
# Root kasutajana
lxc exec devops-k8s-student1 -- bash

# labuser kasutajana
lxc exec devops-k8s-student1 -- su - labuser
```

---

## Port Forwarding

### Docker Labid (devops-student1)

| Host Port | Container Port | Teenus |
|-----------|----------------|--------|
| 2201 | 22 | SSH |
| 8080 | 8080 | Frontend |
| 3000 | 3000 | User API |
| 8081 | 8081 | Todo API |

### Kubernetes Labid (devops-k8s-student1)

| Host Port | Container Port | Teenus |
|-----------|----------------|--------|
| 2201 | 22 | SSH |
| 6443 | 6443 | K8s API Server |
| 30080 | 30080 | Ingress HTTP |
| 30443 | 30443 | Ingress HTTPS |

### Port Forwarding'u Lisamine/Muutmine

```bash
# Lisa uus port
lxc config device add devops-k8s-student1 custom-proxy proxy \
  listen=tcp:127.0.0.1:9090 connect=tcp:127.0.0.1:9090 nat=true

# Eemalda port
lxc config device remove devops-k8s-student1 custom-proxy

# Vaata kõiki device'eid
lxc config device show devops-k8s-student1
```

---

## Labs Sünkroniseerimine

Kui teed muudatusi lab failidesse host masinal, saad need sünkroniseerida konteinerisse:

### Üksiku Konteineri Sünkroniseerimine

```bash
# Kasuta sync-labs.sh skripti
~/scripts/sync-labs.sh devops-k8s-student1

# Või käsitsi
lxc file push -r ~/projects/hostinger/labs/ devops-k8s-student1/home/labuser/
lxc exec devops-k8s-student1 -- chown -R labuser:labuser /home/labuser/labs
```

### Kõigi Konteinerite Sünkroniseerimine

```bash
~/scripts/sync-all-students.sh
```

### Versioonide Kontrollimine

```bash
~/scripts/check-versions.sh
```

---

## Template Haldamine

### Template'i Uuendamine

Kui oled teinud muudatusi ja tahad uut template'i:

```bash
~/scripts/update-template.sh
```

See skript:
1. Loob ajutise konteineri praegusest template'ist
2. Sünkroniseerib uusimad labid
3. Loob uue template image'i
4. Kustutab ajutise konteineri

### Uue Konteineri Loomine Template'ist

```bash
# Docker labide jaoks
lxc launch devops-lab-base devops-student1 -p default -p devops-lab

# Kubernetes labide jaoks
lxc launch devops-lab-base devops-k8s-student1 -p default -p devops-lab-k8s

# Seadista parool
lxc exec devops-student1 -- bash -c "echo 'labuser:student1' | chpasswd"
```

---

## Snapshot'id ja Taastamine

### Snapshot'i Loomine

```bash
# Enne riskantset operatsiooni
lxc snapshot devops-k8s-student1 before-experiment

# Nimega koos kuupäevaga
lxc snapshot devops-k8s-student1 backup-$(date +%Y%m%d-%H%M)
```

### Snapshot'ide Vaatamine

```bash
lxc info devops-k8s-student1 | grep -A 20 "Snapshots:"
```

### Snapshot'ist Taastamine

```bash
# Taasta eelmisest snapshot'ist
lxc restore devops-k8s-student1 before-experiment
```

### Snapshot'i Kustutamine

```bash
lxc delete devops-k8s-student1/before-experiment
```

---

## Probleemide Lahendamine

### Docker ei tööta konteineris

**Sümptom:** `docker: Error response from daemon: AppArmor enabled...`

**Lahendus:** Kasuta docker wrapper funktsiooni (peaks olema juba .bashrc-s):

```bash
# Kontrolli, kas wrapper on olemas
type docker

# Kui ei ole, lisa .bashrc-sse:
cat >> ~/.bashrc << 'EOF'
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
source ~/.bashrc
```

### Konteiner ei saa internetti

**Sümptom:** `ping: google.com: Temporary failure in name resolution`

**Lahendus:**

```bash
# Host masinal - kontrolli UFW
sudo ufw status verbose | grep lxdbr0

# Kui reegleid pole:
sudo ufw allow in on lxdbr0
sudo ufw allow out on lxdbr0
sudo ufw route allow in on lxdbr0
sudo ufw route allow out on lxdbr0
sudo ufw reload

# Restart konteiner
lxc restart devops-k8s-student1
```

### Port ei ole kättesaadav

**Sümptom:** `curl: (7) Failed to connect to localhost port 8080`

**Lahendus:**

```bash
# 1. Kontrolli, kas teenus töötab konteineris
lxc exec devops-k8s-student1 -- ss -tlnp | grep 8080

# 2. Kontrolli port forwarding
lxc config device show devops-k8s-student1

# 3. Kontrolli, kas konteiner töötab
lxc list | grep devops

# 4. Restart konteiner
lxc restart devops-k8s-student1
```

### SSH ühendus aeglane

**Sümptom:** SSH ühenduse loomine võtab 10+ sekundit

**Lahendus:**

```bash
# Lisa SSH config'i
cat >> ~/.ssh/config << 'EOF'
Host devops-lab
    HostName localhost
    Port 2201
    User labuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

# Kasuta alias'ega
ssh devops-lab
```

### RAM/Disk täis

```bash
# Host masinal - vaata ressursse
free -h
df -h

# Konteineris - puhasta Docker
lxc exec devops-k8s-student1 -- docker system prune -af
lxc exec devops-k8s-student1 -- docker volume prune -f

# Vaata konteineri ressursikasutust
lxc list -c ns4M
```

---

## Kasulikud Alias'ed

Lisa oma `~/.bashrc` faili:

```bash
# LXD/DevOps Lab aliases
alias lab='ssh labuser@localhost -p 2201'
alias lab-root='lxc exec devops-k8s-student1 -- bash'
alias lab-status='lxc list -c ns4M'
alias lab-sync='~/scripts/sync-labs.sh devops-k8s-student1'
alias lab-restart='lxc restart devops-k8s-student1'
```

Aktiveeri:
```bash
source ~/.bashrc

# Kasuta
lab          # SSH konteinerisse
lab-root     # Root shell konteineris
lab-status   # Ressursid
lab-sync     # Sünkroniseeri labid
```

---

## Konteineri Täielik Reset

Kui tahad alustada puhtalt lehelt:

```bash
# 1. Kustuta olemasolev konteiner
lxc stop devops-k8s-student1 --force
lxc delete devops-k8s-student1

# 2. Loo uus template'ist
lxc launch devops-lab-base devops-k8s-student1 -p default -p devops-lab-k8s

# 3. Seadista parool
lxc exec devops-k8s-student1 -- bash -c "echo 'labuser:student1' | chpasswd"

# 4. Lisa port forwarding (kui profiilis pole)
lxc config device add devops-k8s-student1 ssh-proxy proxy \
  listen=tcp:127.0.0.1:2201 connect=tcp:127.0.0.1:22 nat=true

# 5. Sünkroniseeri uusimad labid
~/scripts/sync-labs.sh devops-k8s-student1
```

---

## Mitu Konteinerit Korraga

Kui tahad mitut keskkonda (nt Docker ja K8s eraldi):

```bash
# Docker labide konteiner (port 2201)
lxc launch devops-lab-base devops-student1 -p default -p devops-lab

# Kubernetes labide konteiner (port 2202)
lxc launch devops-lab-base devops-k8s-student1 -p default -p devops-lab-k8s
# Muuda SSH port (vaikimisi 2201, muuda 2202-ks)
lxc config device set devops-k8s-student1 ssh-proxy listen=tcp:127.0.0.1:2202

# SSH
ssh labuser@localhost -p 2201  # Docker labs
ssh labuser@localhost -p 2202  # K8s labs
```

---

## Ressursipiirangud

### Praegused Limiidid (profiilis)

```bash
# Vaata profiili seadistust
lxc profile show devops-lab-k8s
```

Tüüpilised väärtused:
- **RAM:** 4-6GB (limits.memory)
- **CPU:** 2-4 cores (limits.cpu)
- **Disk:** Jagatud host'iga

### Limiitide Muutmine

```bash
# Suurenda RAM-i
lxc config set devops-k8s-student1 limits.memory 8GB

# Suurenda CPU-sid
lxc config set devops-k8s-student1 limits.cpu 4

# Kontrolli
lxc config show devops-k8s-student1 | grep limits
```

---

## Viited

- **INSTALLATION.md** - Täielik paigaldusjuhend
- **ADMIN-GUIDE.md** - Administraatori juhend (VPS-põhine)
- **../labs/README.md** - Labide ülevaade ja juhised
- **TECHNICAL-SPECS.md** - Tehnilised detailid

---

**Viimane uuendus:** 2025-12-01
**Versioon:** 1.0
