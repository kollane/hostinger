# Administraatori Juhend - LXD DevOps Laborikeskkond

## Ülevaade

See juhend on mõeldud VPS administraatorile, kes haldab LXD-põhist DevOps laborikeskkonda.

## Kiirviited

- [Konteinerite haldamine](#konteinerite-haldamine)
- [Labs failide sünkroniseerimine](#labs-failide-sünkroniseerimine)
- [SSH turvalisus](#ssh-turvalisus)
- [Ressursside monitooring](#ressursside-monitooring)
- [Backup ja taastamine](#backup-ja-taastamine)
- [Uue õpilase lisamine](#uue-õpilase-lisamine)
- [Template uuendamine](#template-uuendamine)
- [Probleemide lahendamine](#probleemide-lahendamine)

---

## Süsteemi Ülevaade

**VPS Konfiguratsioon:**
- OS: Ubuntu 24.04 LTS
- RAM: 7.8GB + 4GB Swap
- CPU: 2 cores (AMD SVM)
- External IP: `<vps-ip>`

**Konteinerid:**
- devops-student1 (IP: 10.67.86.225)
- devops-student2 (IP: 10.67.86.115)
- devops-student3 (IP: 10.67.86.175)

**Template:**
- Image: devops-lab-base
- Base: Ubuntu 24.04 + Docker 29.0.4 + Labs

---

## Konteinerite Haldamine

### Põhikäsud

```bash
# Vaata kõiki konteinereid
sg lxd -c "lxc list"

# Detailne info konteinerist
sg lxd -c "lxc info devops-student1"

# Logi konteinerisse (root)
sg lxd -c "lxc exec devops-student1 -- bash"

# Logi konteinerisse (labuser)
sg lxd -c "lxc exec devops-student1 -- su - labuser"
```

### Konteineri elutsükkel

```bash
# Käivita konteiner
sg lxd -c "lxc start devops-student1"

# Peata konteiner
sg lxd -c "lxc stop devops-student1"

# Taaskäivita konteiner
sg lxd -c "lxc restart devops-student1"

# Kustuta konteiner
sg lxd -c "lxc delete devops-student1"

# Kustuta töötav konteiner (force)
sg lxd -c "lxc delete --force devops-student1"
```

### Failide kopeerimine

```bash
# Host → Container
sg lxd -c "lxc file push /path/to/file devops-student1/home/labuser/"

# Container → Host
sg lxd -c "lxc file pull devops-student1/home/labuser/file.txt /tmp/"

# Rekursiivne kopeerimine
sg lxd -c "lxc file push -r /path/to/dir/ devops-student1/home/labuser/"
```

### Käskude käivitamine konteineris

```bash
# Üksik käsk
sg lxd -c "lxc exec devops-student1 -- docker ps"

# Mitme käsu jada
sg lxd -c "lxc exec devops-student1 -- bash -c 'cd /home/labuser && ls -la'"

# Käsk kindla kasutajana
sg lxd -c "lxc exec devops-student1 -- su - labuser -c 'docker ps'"
```

---

## Labs Failide Sünkroniseerimine

### Ülevaade

Kui host masinas Git repositooriumis (`/home/janek/projects/hostinger/labs/`) muutuvad laboritööde juhendid või materjalid, saad need muudatused kõikidesse konteineritesse kopeerida automaatsete skriptidega.

**Asukoht:** Kõik skriptid asuvad kataloogis `/home/janek/scripts/`

**Workflow:**
1. Host'il: Muuda faile git repo's (`/home/janek/projects/hostinger/labs/`)
2. Host'il: Commit & push muudatused
3. Host'il: Käivita sync skript
4. Failid kopeeritakse konteineritesse (`/home/labuser/labs/`)

### Sync Skriptid

#### 1. sync-labs.sh - Sync üks konteiner

Kopeerib labs failid ühte konteinerisse.

```bash
/home/janek/scripts/sync-labs.sh devops-student1
```

**Mis toimub:**
1. Loob backup'i konteineri olemasolevast labs kataloogist `/tmp/labs-backup-YYYYMMDD-HHMMSS.tar.gz`
2. Kopeerib kõik failid host'ilt (`/home/janek/projects/hostinger/labs/`) → konteinerisse (`/home/labuser/labs/`)
3. Seab õiged ownership'id (labuser:labuser)

**Kasutamine:**
```bash
# Sync konkreetne konteiner
/home/janek/scripts/sync-labs.sh devops-student1
/home/janek/scripts/sync-labs.sh devops-student2
/home/janek/scripts/sync-labs.sh devops-student3
```

#### 2. sync-all-students.sh - Sync kõik konteinerid

Kopeerib labs failid kõikidesse kolmesse konteinerisse korraga.

```bash
/home/janek/scripts/sync-all-students.sh
```

**Väljund:**
```
===================================
Syncing labs to all students
===================================

>>> devops-student1 <<<
📦 Syncing labs to devops-student1...
Creating backup...
Copying files...
Setting ownership...
✅ devops-student1 updated!
   Backup: /tmp/labs-backup-*.tar.gz

>>> devops-student2 <<<
...

✅ All students updated!
```

#### 3. check-versions.sh - Kontrolli versioone

Kontrollib, millal viimati labs failid igas konteineris uuendati.

```bash
/home/janek/scripts/check-versions.sh
```

**Väljund:**
```
Lab Versions (last modified):
==============================
devops-student1: 2025-11-25
devops-student2: 2025-11-25
devops-student3: 2025-11-25

Host version:
2025-11-25
```

**Tõlgendamine:**
- Kui konteineri kuupäev on **vanem** kui host'i kuupäev → konteiner vajab uuendamist
- Kui kuupäevad on **samad** → kõik on sünkroonis

#### 4. update-template.sh - Uuenda template

Uuendab base template'i (`devops-lab-base`), et uued konteinerid saaksid kohe uusimad labs failid.

```bash
/home/janek/scripts/update-template.sh
```

**Mis toimub:**
1. Loob ajutise konteineri template'ist
2. Kopeerib uusimad labs failid
3. Peatab konteineri
4. Backup'ib vana template'i → `/tmp/devops-lab-base-backup-YYYYMMDD.tar.gz`
5. Publikeerib uue template'i
6. Eemaldab vana template'i
7. Kustutab ajutise konteineri

**Kasutamine:**
```bash
# Uuenda template (tehakse tavaliselt kord kuus või enne uute õpilaste lisamist)
/home/janek/scripts/update-template.sh
```

### Igapäevane Töövoog

**1. Muuda labs faile host'il:**
```bash
cd /home/janek/projects/hostinger/labs

# Muuda faile (nt. Lab 2 juhend)
nano 02-docker-compose-lab/exercises/01-docker-compose-postgres.md

# Commit & push
git add .
git commit -m "Updated Lab 2 exercise 1"
git push
```

**2. Kontrolli, millised konteinerid vajavad uuendamist:**
```bash
/home/janek/scripts/check-versions.sh
```

Kui näed, et mõned konteinerid on vananenud:
```
devops-student1: 2025-11-20  ← vana!
devops-student2: 2025-11-25  ← uus
devops-student3: 2025-11-20  ← vana!
Host version: 2025-11-25
```

**3A. Uuenda kõik konteinerid korraga:**
```bash
/home/janek/scripts/sync-all-students.sh
```

**3B. Või uuenda ainult need, mis vajavad:**
```bash
/home/janek/scripts/sync-labs.sh devops-student1
/home/janek/scripts/sync-labs.sh devops-student3
```

**4. Kontrolli uuesti:**
```bash
/home/janek/scripts/check-versions.sh
```

Nüüd peaks kõik olema sünkroonis:
```
devops-student1: 2025-11-25  ← uuendatud!
devops-student2: 2025-11-25
devops-student3: 2025-11-25  ← uuendatud!
Host version: 2025-11-25
```

### Backup'id

**Kus asuvad backup'id:**
- Konteineri backup'id: `/tmp/labs-backup-*.tar.gz` (konteinerites)
- Template backup'id: `/tmp/devops-lab-base-backup-*.tar.gz` (host'il)

**Backup'i taastamine konteinerisse:**
```bash
# Vaata, millised backup'id on olemas
sg lxd -c "lxc exec devops-student1 -- ls -lh /tmp/labs-backup-*.tar.gz"

# Taasta backup (kui vaja)
sg lxd -c "lxc exec devops-student1 -- bash -c 'rm -rf /home/labuser/labs && tar -xzf /tmp/labs-backup-20251125-143022.tar.gz -C /home/labuser/'"
```

**Template backup'i taastamine:**
```bash
# Vaata olemasolevad backup'id
ls -lh /tmp/devops-lab-base-backup-*.tar.gz

# Import backup'i tagasi (kui vaja)
sg lxd -c "lxc image import /tmp/devops-lab-base-backup-20251125.tar.gz --alias devops-lab-base-restored"
```

### Skriptide Asukoht ja Õigused

**Kataloog:** `/home/janek/scripts/`

**Failid:**
```
/home/janek/scripts/
├── sync-labs.sh              # Sync üks konteiner
├── sync-all-students.sh      # Sync kõik konteinerid
├── check-versions.sh         # Kontrolli versioone
└── update-template.sh        # Uuenda template
```

**Õigused:**
```bash
# Kõik skriptid peavad olema executable
chmod +x /home/janek/scripts/*.sh

# Kontrolli õigusi
ls -l /home/janek/scripts/
```

### Võimalikud Probleemid

**Probleem 1: "Permission denied"**
```
bash: /home/janek/scripts/sync-labs.sh: Permission denied
```

**Lahendus:**
```bash
chmod +x /home/janek/scripts/*.sh
```

**Probleem 2: "Container not found"**
```
Error: not found
```

**Lahendus:**
```bash
# Kontrolli, kas konteiner on olemas ja töötab
sg lxd -c "lxc list"

# Käivita konteiner, kui on peatatud
sg lxd -c "lxc start devops-student1"
```

**Probleem 3: "Operation not permitted" konteineri sees**
```
chown: changing ownership of '/home/labuser/labs': Operation not permitted
```

**Lahendus:**
```bash
# Sync skript juba teeb chown'i konteineri sees root õigustega
# Kui ikka esineb, kontrolli, kas konteiner on unprivileged:
sg lxd -c "lxc config show devops-student1 | grep security.privileged"
# Peaks olema: security.privileged: "false"
```

### Eelised ja Piirangud

**✅ Eelised:**
- Lihtne ja kiire (1-2 minutit kõik 3 konteinerit)
- Automaatne backup enne iga uuendust
- Admin kontrollib, millal ja mida uuendatakse
- Ei vaja git'i konteinerites
- Valikuline: uuenda ainult mõnda konteinerit või kõiki korraga

**⚠️ Piirangud:**
- Õpilased ei saa ise labs faile uuendada (on read-only nende jaoks)
- Õpilased ei näe git ajalugu
- Kõik failid kopeeritakse, ka need mis ei muutunud
- Vajab admin'i tegevust (pole automaatne)

**💡 Soovitus:**
- Tee sync **enne** iga laboritööde sessiooni (nt. esmaspäeval enne tundi)
- Kontrolli versioone `check-versions.sh` abil regulaarselt
- Hoia backup'id alles vähemalt 1 nädal
- Uuenda template'i kord kuus või enne uute õpilaste lisamist

---

## SSH Turvalisus

### Ülevaade

SSH juurdepääs on turvatud mitme kihilise kaitsega, mis kaitseb brute-force rünnakute ja volitamata juurdepääsu eest.

**SSH Pordid:**
- Host: 1984
- devops-student1: 2201
- devops-student2: 2202
- devops-student3: 2203

### Rakendatud Turvameetmed

#### 1. Fail2ban SSH Kaitse

**Konfiguratsioon:** `/etc/fail2ban/jail.d/sshd-custom.conf`

```bash
[sshd]
enabled = true
port = 1984,2201,2202,2203
filter = sshd
logpath = /var/log/auth.log
maxretry = 3       # 3 ebaõnnestunud katset
bantime = 3600     # Blokeeri 1 tunniks
findtime = 600     # 10 minuti jooksul
```

**Kontrolli staatust:**
```bash
# Kontrolli, kas fail2ban töötab
sudo systemctl status fail2ban

# Kontrolli SSH jail'i
sudo fail2ban-client status sshd

# Vaata blokeeritud IP-sid
sudo fail2ban-client status sshd | grep "Banned IP"
```

**Deblokeeri IP (kui vaja):**
```bash
# Deblokeeri konkreetne IP
sudo fail2ban-client set sshd unbanip 123.456.789.0

# Vaata fail2ban logi
sudo tail -f /var/log/fail2ban.log
```

#### 2. SSH Konfiguratsioon (Konteinerid)

**Konfiguratsioon:** `/etc/ssh/sshd_config.d/99-security.conf` (konteinerites)

```
MaxAuthTries 3              # Ainult 3 parooli katset
LoginGraceTime 30           # 30s aega sisselogimiseks
PermitRootLogin no          # Root sisselogimine keelatud
PasswordAuthentication yes  # Parool autentimine lubatud
PubkeyAuthentication yes    # SSH key autentimine lubatud
PermitEmptyPasswords no     # Tühjad paroolid keelatud
ClientAliveInterval 300     # Session timeout 5min
ClientAliveCountMax 2       # Max 2 × 5min = 10min
```

**Kontrolli seadeid:**
```bash
# Vaata aktiivset SSH konfiguratsiooni
sg lxd -c "lxc exec devops-student1 -- sshd -T" | grep -E '(maxauth|login|permit|password|clientalive)'

# Kontrolli SSH teenuse staatust
sg lxd -c "lxc exec devops-student1 -- systemctl status ssh"

# Testi SSH konfiguratsiooni (süntaks)
sg lxd -c "lxc exec devops-student1 -- sshd -t"
```

#### 3. UFW Firewall Rate Limiting

**Seadistus:**
```bash
# Rate limiting: max 6 ühendust 30 sekundi jooksul
Port 1984: LIMIT (host SSH)
Port 2201: LIMIT (student1 SSH)
Port 2202: LIMIT (student2 SSH)
Port 2203: LIMIT (student3 SSH)
```

**Kontrolli:**
```bash
sudo ufw status numbered
```

**Muuda reegleid:**
```bash
# Kustuta reegel numbri järgi
sudo ufw delete [number]

# Lisa uus rate limited reegel
sudo ufw limit 2201/tcp comment 'SSH student1 rate limited'

# Reload
sudo ufw reload
```

#### 4. Tugevad Paroolid

**Asukoht:** `~/student-passwords.txt` (permissions: 600)

**Paroolide vaatamine:**
```bash
cat ~/student-passwords.txt
```

**Parooli vahetus konteineri jaoks:**
```bash
# Genereeri uus tugev parool
NEW_PASS=$(openssl rand -base64 16)

# Sea uus parool
sg lxd -c "lxc exec devops-student1 -- bash -c \"echo 'labuser:$NEW_PASS' | chpasswd\""

# Salvesta parool
echo "devops-student1 new password: $NEW_PASS" >> ~/student-passwords.txt
```

### Turvalisuse Tasemed

SSH ühendus läbib mitu turvakihti:

```
Ühenduse katse
    ↓
1. UFW Rate Limiting (>6 ühendust/30s → blokeeri)
    ↓
2. Fail2ban (>3 ebaõnnestunud katset/10min → blokeeri IP 1h)
    ↓
3. SSH MaxAuthTries (ainult 3 parooli katset)
    ↓
4. SSH LoginGraceTime (30s aega sisselogimiseks)
    ↓
5. Tugev parool (~22 tähemärki)
    ↓
✅ Sisselogitud
    ↓
6. Session Timeout (10 min idle → disconnect)
```

### Monitooring ja Auditid

#### Vaata SSH sisselogimisi

**Õnnestunud sisselogimised:**
```bash
# Host
sudo grep "Accepted password" /var/log/auth.log | tail -20

# Konteiner
sg lxd -c "lxc exec devops-student1 -- grep 'Accepted password' /var/log/auth.log | tail -20"
```

**Ebaõnnestunud sisselogimised:**
```bash
# Host
sudo grep "Failed password" /var/log/auth.log | tail -20

# Konteiner
sg lxd -c "lxc exec devops-student1 -- grep 'Failed password' /var/log/auth.log | tail -20"
```

**Aktiivne sessioonid:**
```bash
# Host
who

# Konteiner
sg lxd -c "lxc exec devops-student1 -- who"
```

#### Fail2ban Statistika

```bash
# Kogu statistika
sudo fail2ban-client status

# SSH jail detailid
sudo fail2ban-client status sshd

# Blokeeritud IP-d
sudo fail2ban-client get sshd banned

# Fail2ban tegevuste logi
sudo tail -f /var/log/fail2ban.log
```

### Tavalised Probleemid

#### Probleem 1: "Permission denied" kuigi parool on õige

**Võimalikud põhjused:**
1. Vale kasutajanimi (peaks olema `labuser`)
2. Vale port
3. IP blokeeritud fail2ban'iga

**Lahendus:**
```bash
# Kontrolli, kas IP on blokeeritud
sudo fail2ban-client status sshd

# Deblokeeri IP
sudo fail2ban-client set sshd unbanip <IP-ADDRESS>

# Kontrolli SSH teenust konteineris
sg lxd -c "lxc exec devops-student1 -- systemctl status ssh"
```

#### Probleem 2: "Connection timed out"

**Võimalikud põhjused:**
1. UFW ei luba porti
2. Konteiner ei tööta
3. SSH teenus ei tööta konteineris

**Lahendus:**
```bash
# Kontrolli UFW
sudo ufw status | grep 2201

# Kontrolli konteinerit
sg lxd -c "lxc list devops-student1"

# Kontrolli SSH teenust
sg lxd -c "lxc exec devops-student1 -- systemctl status ssh"
```

#### Probleem 3: Fail2ban blokeerib õigeid kasutajaid

**Lahendus:**
```bash
# Deblokeeri IP
sudo fail2ban-client set sshd unbanip <IP>

# Suurenda maxretry (kui vaja)
sudo nano /etc/fail2ban/jail.d/sshd-custom.conf
# Muuda: maxretry = 5
sudo systemctl restart fail2ban
```

### Paroolide Haldamine

#### Õpilastele Paroolide Edastamine

**Turvaliselt:**
1. Kopeeri parool failist `~/student-passwords.txt`
2. Saada privaatselt (email, Teams, Slack DM)
3. **ÄRA** saada avalikes kanalites (nt. group chat)

**Soovitused õpilastele:**
```
Esimesel sisselogimisel:
1. Logi sisse: ssh -p 2201 labuser@93.127.213.242
2. Vaheta parool: passwd
3. Sisesta vana parool
4. Sisesta uus tugev parool (2x)
```

#### Parooli Reset (Admin)

Kui õpilane unustab parooli:

```bash
# 1. Genereeri uus parool
NEW_PASS=$(openssl rand -base64 16)

# 2. Sea uus parool konteineris
sg lxd -c "lxc exec devops-student1 -- bash -c \"echo 'labuser:$NEW_PASS' | chpasswd\""

# 3. Saada õpilasele uus parool
echo "Uus parool devops-student1: $NEW_PASS"
```

### SSH Key Autentimine (Valikuline)

Kui soovid veel turvalisemalt (SSH võtmed):

**1. Genereeri SSH võti:**
```bash
ssh-keygen -t ed25519 -C "student1@devops-lab"
```

**2. Lisa public key konteinerisse:**
```bash
# Kopeeri public key
cat ~/.ssh/id_ed25519.pub

# Lisa konteinerisse
sg lxd -c "lxc exec devops-student1 -- bash -c 'mkdir -p /home/labuser/.ssh && echo \"<PUBLIC-KEY>\" >> /home/labuser/.ssh/authorized_keys'"

# Sea õigused
sg lxd -c "lxc exec devops-student1 -- chown -R labuser:labuser /home/labuser/.ssh"
sg lxd -c "lxc exec devops-student1 -- chmod 700 /home/labuser/.ssh"
sg lxd -c "lxc exec devops-student1 -- chmod 600 /home/labuser/.ssh/authorized_keys"
```

**3. Keela parool autentimine (kui SSH key töötab):**
```bash
sg lxd -c "lxc exec devops-student1 -- bash -c 'echo \"PasswordAuthentication no\" > /etc/ssh/sshd_config.d/99-security.conf'"
sg lxd -c "lxc exec devops-student1 -- systemctl restart ssh"
```

### Turvalisuse Ülevaade

| Meede | Seadistus | Kirjeldus |
|-------|-----------|-----------|
| **Fail2ban** | 3 katset / 10min → ban 1h | Blokeerib IP-d automaatselt |
| **UFW Rate Limit** | 6 ühendust / 30s | Esimene kaitse brute-force vastu |
| **MaxAuthTries** | 3 katset | Parooli katsetused enne disconnect'i |
| **LoginGraceTime** | 30s | Aeg sisselogimiseks |
| **Root Login** | Keelatud | Root ei saa sisse logida |
| **Tugevad Paroolid** | 22 tähemärki | Juhusliku genereeritud |
| **Session Timeout** | 10 min idle | Automaatne väljalogimise |

**Soovitused:**
- ✅ Kontrolli fail2ban logi regulaarselt
- ✅ Jälgi ebaõnnestunud sisselogimisi
- ✅ Uuenda paroole iga 3-6 kuud
- ✅ Kasuta SSH võtmeid, kui võimalik
- ✅ Hoia `~/student-passwords.txt` turvaline (chmod 600)

---

## Ressursside Monitooring

### RAM kasutus

```bash
# Host RAM
free -h

# Kõik konteinerid korraga
sg lxd -c "lxc list -c ns4M"

# Ühe konteineri detailne info
sg lxd -c "lxc info devops-student1" | grep -A 3 "Memory usage"
```

**Tavaline kasutus:**
- Idle (konteiner käivitatud, Docker idle): ~260MB
- Docker Compose käivitatud: ~500-800MB
- Kõik 3 teenust käimas: ~1-1.5GB

### CPU kasutus

```bash
# Host CPU
htop
# või
top

# Konteineri CPU
sg lxd -c "lxc info devops-student1" | grep -A 3 "CPU usage"

# Live monitoring (host)
htop
# Filtreeri: F4, sisesta "lxc"
```

### Disk kasutus

```bash
# Host disk
df -h

# Konteineri disk
sg lxd -c "lxc exec devops-student1 -- df -h"

# LXD storage pool
sg lxd -c "lxc storage info default"
```

### Network monitoring

```bash
# Konteineri network stats
sg lxd -c "lxc info devops-student1" | grep -A 5 "Network usage"

# Port forwarding kontrollimine
netstat -tuln | grep -E ':(2201|2202|2203|8080|8180|8280)'

# Konteineri avatud pordid
sg lxd -c "lxc exec devops-student1 -- netstat -tuln"
```

### Ressursside limiidid

```bash
# Vaata praeguseid limiite
sg lxd -c "lxc config show devops-student1"

# Muuda RAM limiiti (2.5GB → 3GB)
sg lxd -c "lxc config set devops-student1 limits.memory 3GB"

# Muuda CPU limiiti (1 → 2 cores)
sg lxd -c "lxc config set devops-student1 limits.cpu 2"

# Taaskäivita, et muudatused rakenduksid
sg lxd -c "lxc restart devops-student1"
```

---

## Backup ja Taastamine

### Snapshot'id

```bash
# Loo snapshot
sg lxd -c "lxc snapshot devops-student1 before-lab2"

# Vaata snapshot'e
sg lxd -c "lxc info devops-student1" | grep Snapshots -A 20

# Taasta snapshot
sg lxd -c "lxc restore devops-student1 before-lab2"

# Kustuta snapshot
sg lxd -c "lxc delete devops-student1/before-lab2"
```

**Soovitatud snapshot strateegia:**
- Enne iga labo algust: `before-lab-N`
- Pärast edu edukat labi: `after-lab-N-success`
- Enne suuri muudatusi: `before-changes-YYYY-MM-DD`

### Image export/import

```bash
# Ekspordi konteiner image'ina
sg lxd -c "lxc publish devops-student1 --alias student1-backup-2025-11-25"

# Vaata salvestatud image'id
sg lxd -c "lxc image list"

# Ekspordi image failina
sg lxd -c "lxc image export student1-backup-2025-11-25 /backup/"

# Impordi image failist
sg lxd -c "lxc image import /backup/image.tar.gz --alias restored-backup"

# Loo konteiner backed up image'ist
sg lxd -c "lxc launch restored-backup devops-student1-restored"
```

### Täielik backup skript

```bash
#!/bin/bash
# backup-all-students.sh

DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/lxd-students"

mkdir -p "$BACKUP_DIR"

for STUDENT in devops-student1 devops-student2 devops-student3; do
    echo "Backing up $STUDENT..."

    # Snapshot
    sg lxd -c "lxc snapshot $STUDENT backup-$DATE"

    # Export as image
    sg lxd -c "lxc publish $STUDENT --alias ${STUDENT}-backup-$DATE"

    # Export to file
    sg lxd -c "lxc image export ${STUDENT}-backup-$DATE $BACKUP_DIR/${STUDENT}-$DATE"

    echo "$STUDENT backup complete"
done

echo "All backups complete in $BACKUP_DIR"
```

Salvesta ja käivita:
```bash
chmod +x backup-all-students.sh
./backup-all-students.sh
```

---

## Uue Õpilase Lisamine

### Student4 lisamine (näide)

**1. Käivita uus konteiner template'ist:**

```bash
sg lxd -c "lxc launch devops-lab-base devops-student4 -p default -p devops-lab"
```

**2. Oota, kuni konteiner saab IP:**

```bash
# Kontrolli olekut
sg lxd -c "lxc list devops-student4"
# Oodake, kuni näete IP aadressi
```

**3. Sea parool:**

```bash
sg lxd -c "lxc exec devops-student4 -- bash -c 'echo \"labuser:student4\" | chpasswd'"
```

**4. Kontrolli ja luba SSH password auth:**

```bash
sg lxd -c "lxc exec devops-student4 -- bash -c 'sed -i \"s/^#*PasswordAuthentication.*/PasswordAuthentication yes/\" /etc/ssh/sshd_config && systemctl restart ssh'"
```

**5. Lisa port forwarding (SSH ja Web):**

```bash
# SSH (järgmine vaba port: 2204)
sg lxd -c "lxc config device add devops-student4 ssh-proxy proxy listen=tcp:0.0.0.0:2204 connect=tcp:127.0.0.1:22"

# Frontend (järgmine vaba port: 8380)
sg lxd -c "lxc config device add devops-student4 web-proxy proxy listen=tcp:0.0.0.0:8380 connect=tcp:127.0.0.1:8080"

# User Service API (järgmine vaba port: 3300)
sg lxd -c "lxc config device add devops-student4 user-api-proxy proxy listen=tcp:0.0.0.0:3300 connect=tcp:127.0.0.1:3000"

# Todo Service API (järgmine vaba port: 8381)
sg lxd -c "lxc config device add devops-student4 todo-api-proxy proxy listen=tcp:0.0.0.0:8381 connect=tcp:127.0.0.1:8081"
```

**6. Testi SSH ühendust:**

```bash
ssh labuser@localhost -p 2204
# Password: student4
```

**7. Uuenda dokumentatsiooni:**

Lisa `labs/README.md` faili "Sinu Keskkond" sektsiooni student4 andmed (SSH port, API pordid).

---

## Template Uuendamine

### Millal uuendada template'i?

- Docker'i versioon uuendatud
- Labs uuendatud (uued ülesanded, parandused)
- Security updates
- Uued tööriistad vajalikud

### Template uuendamise protsess

**1. Loo ajutine konteiner template'ist:**

```bash
sg lxd -c "lxc launch devops-lab-base temp-update -p default -p devops-lab"
```

**2. Tee muudatused:**

```bash
# Logi konteinerisse
sg lxd -c "lxc exec temp-update -- bash"

# ⚠️ KRIITILINE: Rakenda containerd fix (kui uuendad Docker'it)
apt-get update
apt-get upgrade docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
# NB! ÄRA upgrade containerd.io - see on lukustatud versioonil 1.7.28

# Verifitseeri containerd versiooni
containerd --version
# Peaks olema: 1.7.28
apt-mark showhold | grep containerd
# Peaks olema: containerd.io

# Kui containerd on 1.7.29+ või 2.x, downgrade:
apt install -y --allow-downgrades containerd.io=1.7.28-1~ubuntu.24.04~noble
apt-mark hold containerd.io

# Või: uuenda labs
rm -rf /home/labuser/labs
# ... kopeeri uued labs ...

# Logi välja
exit
```

**3. Puhasta ajalugu ja ajutised failid:**

```bash
sg lxd -c "lxc exec temp-update -- bash -c '
    apt-get clean
    rm -rf /tmp/*
    rm -rf /var/tmp/*
    history -c
'"
```

**4. Peata konteiner:**

```bash
sg lxd -c "lxc stop temp-update"
```

**5. Publitseeri uuena template'ina:**

```bash
# Varajane template varundamine
sg lxd -c "lxc image export devops-lab-base /backup/devops-lab-base-old"

# Kustuta vana alias
sg lxd -c "lxc image delete devops-lab-base"

# Publitseeri uus
sg lxd -c "lxc publish temp-update --alias devops-lab-base description='DevOps Lab Template: Ubuntu 24.04 + Docker + Labs (Updated 2025-11-25)'"
```

**6. Kustuta ajutine konteiner:**

```bash
sg lxd -c "lxc delete temp-update"
```

**7. Testi uut template'i:**

```bash
sg lxd -c "lxc launch devops-lab-base test-new-template -p default -p devops-lab"
sg lxd -c "lxc exec test-new-template -- docker --version"
sg lxd -c "lxc exec test-new-template -- ls -la /home/labuser/labs/"
sg lxd -c "lxc delete --force test-new-template"
```

### Õpilaskonteinerite uuendamine uuest template'ist

**Variant 1: Clean recreation (soovitatud):**

```bash
# 1. Backup'i õpilase andmed (kui vajalik)
sg lxd -c "lxc snapshot devops-student1 before-template-update"

# 2. Kustuta vana konteiner
sg lxd -c "lxc delete --force devops-student1"

# 3. Loo uus uuest template'ist
sg lxd -c "lxc launch devops-lab-base devops-student1 -p default -p devops-lab"

# 4. Sea parool ja port forwarding uuesti
# ... (vt "Uue õpilase lisamine" sektsiooni) ...
```

**Variant 2: In-place update (riskantsem):**

```bash
# Käivita update käsud otse konteineris
sg lxd -c "lxc exec devops-student1 -- bash -c 'apt-get update && apt-get upgrade -y'"
```

---

## Kasutajate haldamine

### Parooli muutmine

```bash
# Muuda labuser parooli
sg lxd -c "lxc exec devops-student1 -- bash -c 'echo \"labuser:new-password\" | chpasswd'"
```

### Uue kasutaja lisamine (kui vajalik)

```bash
sg lxd -c "lxc exec devops-student1 -- bash -c '
    useradd -m -s /bin/bash newuser
    echo "newuser:password123" | chpasswd
    usermod -aG docker newuser
'"
```

### Kasutaja kustutamine

```bash
sg lxd -c "lxc exec devops-student1 -- userdel -r olduser"
```

---

## Network haldamine

### Port forwarding vaatamine

```bash
# Vaata konteineri device'e
sg lxd -c "lxc config device show devops-student1"

# Vaata host'i listening porte
netstat -tuln | grep LISTEN
```

### Port forwarding lisamine

```bash
# Näide: Lisa port 5000 → 5000
sg lxd -c "lxc config device add devops-student1 custom-proxy proxy listen=tcp:0.0.0.0:5000 connect=tcp:127.0.0.1:5000"
```

### Port forwarding eemaldamine

```bash
sg lxd -c "lxc config device remove devops-student1 custom-proxy"
```

### Network troubleshooting

```bash
# Kontrolli, kas konteiner saab internetti
sg lxd -c "lxc exec devops-student1 -- ping -c 3 8.8.8.8"

# Kontrolli DNS-i
sg lxd -c "lxc exec devops-student1 -- nslookup google.com"

# Kontrolli bridge'i
ip addr show lxdbr0

# Kontrolli NAT reegleid
sudo iptables -t nat -L -n -v | grep lxdbr0
```

---

## Turvalisus

### UFW reeglid

```bash
# Vaata UFW olekut (vajab sudo)
sudo ufw status verbose

# Lisa uus reegel (kui vajalik)
sudo ufw allow 2204/tcp comment 'SSH student4'
```

**NB!** UFW on seadistatud lubama lxdbr0 liiklust. Ära muuda neid reegleid:
```bash
ufw allow in on lxdbr0
ufw route allow in on lxdbr0
ufw route allow out on lxdbr0
```

### SSH turvalisus

**Soovitused:**
- Keela root login: `PermitRootLogin no`
- Kasuta SSH võtmeid (tulevikus)
- Piira login katseid: fail2ban

### Konteinerite turvalisus

```bash
# Kontrolli, kas konteiner on unprivileged
sg lxd -c "lxc config show devops-student1" | grep privileged

# Peaks olema: security.privileged: "false"
```

---

## Automatiseerimine

### Cron Job: Automaatne backup

Lisa crontab'i:
```bash
crontab -e
```

Lisa rida:
```
0 2 * * 0 /home/janek/backup-all-students.sh >> /var/log/lxd-backup.log 2>&1
```

(Iga pühapäev kell 02:00 backup)

### Skript: Restart kõik konteinerid

```bash
#!/bin/bash
# restart-all-students.sh

for STUDENT in devops-student1 devops-student2 devops-student3; do
    echo "Restarting $STUDENT..."
    sg lxd -c "lxc restart $STUDENT"
    sleep 5
done

echo "All students restarted"
```

### Skript: Check resources all containers

```bash
#!/bin/bash
# check-resources.sh

echo "=== Container Resource Usage ==="
sg lxd -c "lxc list -c ns4M"

echo ""
echo "=== Host Memory ==="
free -h

echo ""
echo "=== Host Disk ==="
df -h /
```

---

## Probleemide Lahendamine

### Konteiner ei käivitu

```bash
# Kontrolli logisid
sg lxd -c "lxc info devops-student1 --show-log"

# Proovi force start
sg lxd -c "lxc start devops-student1 --force"

# Kui ei aita, loo uus template'ist
sg lxd -c "lxc delete --force devops-student1"
sg lxd -c "lxc launch devops-lab-base devops-student1 -p default -p devops-lab"
```

### Konteineril ei ole internetti

```bash
# 1. Kontrolli lxdbr0 olekut
ip addr show lxdbr0

# 2. Kontrolli UFW reegleid
sudo ufw status verbose | grep lxdbr0

# 3. Kontrolli NAT-i
sudo iptables -t nat -L -n -v | grep lxdbr0

# 4. Taaskäivita LXD daemon
sudo systemctl restart lxd
```

### Port forwarding ei tööta

```bash
# 1. Kontrolli device'i olemasolu
sg lxd -c "lxc config device show devops-student1"

# 2. Kontrolli, kas host port on listening
netstat -tuln | grep 2201

# 3. Eemalda ja lisa device uuesti
sg lxd -c "lxc config device remove devops-student1 ssh-proxy"
sg lxd -c "lxc config device add devops-student1 ssh-proxy proxy listen=tcp:0.0.0.0:2201 connect=tcp:127.0.0.1:22"

# 4. Taaskäivita konteiner
sg lxd -c "lxc restart devops-student1"
```

### Docker ei tööta konteineris

```bash
# 1. Kontrolli nesting seadistust
sg lxd -c "lxc config show devops-student1" | grep nesting
# Peaks olema: security.nesting: "true"

# 2. Kontrolli Docker daemoni olekut
sg lxd -c "lxc exec devops-student1 -- systemctl status docker"

# 3. Taaskäivita Docker
sg lxd -c "lxc exec devops-student1 -- systemctl restart docker"

# 4. Kontrolli, kas labuser on docker grupis
sg lxd -c "lxc exec devops-student1 -- groups labuser"
```

### ⚠️ Docker konteinerid ei käivitu - sysctl permission denied

**Sümptom:**
```
Error: unable to start container process:
open sysctl net.ipv4.ip_unprivileged_port_start file:
reopen fd 8: permission denied
```

**Põhjus:**
- `containerd.io` versioon 1.7.29+ või 2.x on bugine LXD keskkonnas
- Ubuntu 24.04 + LXD + Docker kombinatsioon
- Mõjutab KÕIKI Docker konteinereid (PostgreSQL, nginx, jne)

**Lahendus (RAKENDATUD 2025-11-26):**

```bash
# 1. Kontrolli containerd versiooni kõigis konteinerites
for container in devops-student1 devops-student2 devops-student3; do
  echo "=== $container ==="
  sg lxd -c "lxc exec $container -- containerd --version"
done

# 2. Kui versioon on 1.7.29+ või 2.x, downgrade kõigis konteinerites
for container in devops-student1 devops-student2 devops-student3; do
  echo "=== Downgrading containerd in $container ==="
  sg lxd -c "lxc exec $container -- bash -c '
    systemctl stop docker
    apt install -y --allow-downgrades containerd.io=1.7.28-1~ubuntu.24.04~noble
    apt-mark hold containerd.io
    systemctl restart containerd
    systemctl restart docker
  '"
done

# 3. Verifitseeri fix'i
sg lxd -c "lxc exec devops-student1 -- su - labuser -c 'docker run --rm alpine:3.16 echo OK'"
# Peaks väljastama: OK
```

**Testimine PostgreSQL 16-alpine'iga:**
```bash
# Kui varem kasutasid PostgreSQL 14, loo volumes uuesti
sg lxd -c "lxc exec devops-student1 -- su - labuser -c '
  docker volume rm postgres-user-data postgres-todo-data 2>/dev/null || true
  docker volume create postgres-user-data
  docker volume create postgres-todo-data
'"

# Test PostgreSQL 16-alpine
sg lxd -c "lxc exec devops-student1 -- su - labuser -c 'docker run --rm -e POSTGRES_PASSWORD=test postgres:16-alpine postgres --version'"
```

**OLULINE:**
- ✅ Versioon on lukustatud: `apt-mark hold containerd.io`
- ⚠️ ÄRA käivita `apt upgrade` ilma kontrolli
- ⚠️ Template image vajab sama fix'i enne uuendamist
- 📖 Detailne info: `TECHNICAL-SPECS.md` → Known Issues

### RAM otsa

```bash
# 1. Kontrolli, kumb protsess kasutab palju
sg lxd -c "lxc exec devops-student1 -- ps aux --sort=-%mem | head -20"

# 2. Peata mittevajalikud konteinerid
sg lxd -c "lxc stop devops-student2"

# 3. Suurenda swap'i (kui vaja)
sudo swapoff /swapfile
sudo dd if=/dev/zero of=/swapfile bs=1G count=8  # 8GB
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 4. Suurenda konteineri RAM limiiti
sg lxd -c "lxc config set devops-student1 limits.memory 3GB"
sg lxd -c "lxc restart devops-student1"
```

---

## Kasulikud Käsud

### Üherealisesed käsud

```bash
# Näita kõikide konteinerite IP aadresse
sg lxd -c "lxc list -c n4"

# Restart kõik konteinerid
for c in devops-student1 devops-student2 devops-student3; do sg lxd -c "lxc restart $c"; done

# Docker versioon kõigis konteinerites
for c in devops-student1 devops-student2 devops-student3; do echo "=== $c ==="; sg lxd -c "lxc exec $c -- docker --version"; done

# Puhasta kõik Docker ressursid (kõigis konteinerites)
for c in devops-student1 devops-student2 devops-student3; do sg lxd -c "lxc exec $c -- su - labuser -c 'docker system prune -af --volumes'"; done
```

### Debugging

```bash
# Vaata konteinerite logisid
sg lxd -c "lxc info devops-student1 --show-log"

# LXD daemon log
sudo journalctl -u lxd -f

# Container console (kui SSH ei tööta)
sg lxd -c "lxc console devops-student1"
# Exit: Ctrl+a q
```

---

## Kontaktinfo ja Tugi

**LXD dokumentatsioon:**
- https://documentation.ubuntu.com/lxd/en/latest/

**Docker dokumentatsioon:**
- https://docs.docker.com/

**LXD foorum:**
- https://discuss.linuxcontainers.org/

---

## Quick Reference

| Tegevus | Käsk |
|---------|------|
| Vaata konteinereid | `sg lxd -c "lxc list"` |
| Logi konteinerisse | `sg lxd -c "lxc exec <name> -- bash"` |
| Restart | `sg lxd -c "lxc restart <name>"` |
| Snapshot | `sg lxd -c "lxc snapshot <name> <snap-name>"` |
| Vaata RAM-i | `sg lxd -c "lxc list -c ns4M"` |
| Kontrolli Dockerit | `sg lxd -c "lxc exec <name> -- docker ps"` |
| Backup kõik | `./backup-all-students.sh` |

---

**Viimane uuendus:** 2025-11-26
**Versioon:** 1.1
**Hooldaja:** VPS Admin
**Muudatused:**
- 2025-11-26: Lisa containerd.io 1.7.28 downgrade juhend (sysctl bug fix)
- 2025-11-25: Esialgne versioon
