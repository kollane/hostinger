# Peatükk 2: Linux Põhitõed DevOps Kontekstis

**Kestus:** 3 tundi
**Eeldused:** Peatükk 1 (VPS setup, SSH juurdepääs)
**Eesmärk:** Mõista Linux süsteemi DevOps administraatori vaatenurgast

---

## Õpieesmärgid

Selle peatüki lõpuks oskad:
- Mõista Linux failisüsteemi struktuuri ja selle rolli DevOps töövoos
- Hallata süsteemiteenuseid (systemd) ja protsesse
- Vaadata ja analüüsida logisid tõrkeotsingu jaoks
- Konfigureerida automatiseeritud ülesandeid (cron)
- Mõista keskkonna muutujaid (environment variables) ja nende kasutamist

---

## 2.1 Linux Failisüsteem DevOps Vaatenurgast

### Miks Linux DevOps'is?

**Domineeriv server OS:**
- 96.3% web servereid kasutavad Unix/Linux (W3Techs 2025)
- Kõik peamised cloud providerid: AWS, Azure, GCP → Linux baasil
- Konteinerid (Docker, Kubernetes) → Linux kernel tehnoloogia

**DevOps perspektive:**
> "Ma ei pea teadma, kuidas Linux kerneli kompileerida. Ma pean teadma, KUHU rakendus oma konfiguratsioonifaile salvestab ja KUIDAS logisid vaadata."

---

### FHS (Filesystem Hierarchy Standard)

Linux failisüsteem on hierarhiline, alustades juurkataloogist `/`.

**Kriitilised kataloogid DevOps töös:**

#### `/etc` - Konfiguratsioonifailid

**Eesmärk:** Süsteemi ja rakenduste konfiguratsioon
**Näited:**
- `/etc/systemd/system/` - Teenuste definitsioonid
- `/etc/nginx/nginx.conf` - Nginx konfiguratsioon
- `/etc/ssh/sshd_config` - SSH serveri seaded
- `/etc/cron.d/` - Automatiseeritud ülesanded

**DevOps tähtsus:**
- Configuration as Code → need failid on versiooni kontrollitud (Git)
- Muudatused siin mõjutavad kogu süsteemi käitumist
- Backup'id peavad sisaldama `/etc` kataloogi

**Praktiline näide:**
```
Muudad /etc/systemd/system/myapp.service
→ systemctl daemon-reload (laadi konfiguratsioon uuesti)
→ systemctl restart myapp (rakenda muudatused)
```

---

#### `/var` - Muutuvad andmed

**Eesmärk:** Failid, mis MUUTUVAD rakenduse töö ajal

**Kriitilised alamkataloogid:**

**`/var/log/` - Logifailid**
- Kõik süsteemi ja rakenduste logid
- DevOps administraatori PEAMINE tööriist tõrkeotsinguks
- Näited: `/var/log/syslog`, `/var/log/nginx/access.log`, `/var/log/postgresql/`

**`/var/lib/` - Rakenduste andmed**
- PostgreSQL andmebaas: `/var/lib/postgresql/`
- Docker volumes: `/var/lib/docker/volumes/`
- Stateful andmed, mis PEAVAD säilima restart'ide vahel

**`/var/cache/` - Cache andmed**
- APT package cache: `/var/cache/apt/`
- Kustutamisel ei kao kriitiline data (regenereeritav)

**Miks `/var` on oluline?**

1. **Ruumi jälgimine:**
   - Logid võivad täita ketta → rakendus crashib
   - DevOps administraator seadistab log rotation (logrotate)

2. **Backup strateegia:**
   - `/var/lib/postgresql/` → igapäevane backup
   - `/var/log/` → ei ole vaja backup'ida (rotatsioon)
   - `/var/cache/` → ei ole vaja backup'ida

3. **Volume mounting:**
   - Dockeris: `-v /var/lib/postgresql/data:/var/lib/postgresql/data`
   - Kubernetes: PersistentVolume → `/var/lib/postgresql/data`

---

#### `/opt` - Kolmanda osapoole tarkvara

**Eesmärk:** Manually installed software (väljaspool APT)

**Näited:**
- `/opt/myapp/` - Custom rakendus
- `/opt/prometheus/` - Prometheus manuaalne install
- `/opt/k3s/` - K3s binaar

**DevOps praktikas:**
- Eraldamine süsteemi tarkvara (APT) ja custom rakenduste vahel
- Lihtne backup → kogu `/opt/myapp/` kataloog

---

#### `/home` - Kasutajate kodukataloogid

**DevOps kontekst:**
- `/home/student/` - SSH kasutaja kodukataloog
- `~/.ssh/` - SSH võtmed (authorized_keys, id_ed25519)
- `~/hostinger/` - Git repository koolituskavaga

**IaC praktikas:**
- Rakendused EI TOHIKS salvestada andmeid `/home` alla
- Rakendused kasutavad `/var/lib/` või `/opt/`

---

#### `/tmp` - Ajutised failid

**Iseloom:**
- Kustub taaskäivitamisel (või regulaarselt tmpfiles.d'ga)
- Kõik kasutajad saavad kirjutada

**DevOps hoiatus:**
- EI TOHI salvestada püsivaid andmeid
- Sobib ainult ajutiste failide jaoks (nt session data, temp cache)

---

### Failisüsteemi Struktuuri Rakendamine DevOps Töös

**Stsenaarium: PostgreSQL installeerimine**

```
1. Binaar installeerimine:
   APT paigaldab → /usr/bin/postgres

2. Konfiguratsioon:
   → /etc/postgresql/16/main/postgresql.conf
   → /etc/postgresql/16/main/pg_hba.conf

3. Andmed:
   → /var/lib/postgresql/16/main/ (data directory)

4. Logid:
   → /var/log/postgresql/postgresql-16-main.log

5. PID fail (process ID):
   → /var/run/postgresql/16-main.pid
```

**DevOps tegevused:**
- Muudan konfiguratsiooni → `/etc/postgresql/.../postgresql.conf`
- Vaatan logisid → `/var/log/postgresql/`
- Teen backup'i → `/var/lib/postgresql/` (ainult andmed)
- Taaskäivitan teenust → `systemctl restart postgresql@16-main`

📖 **Praktika:** Labor 0, Harjutus 3 - Failisüsteemi struktuuri tutvustamine

---

## 2.2 Protsesside Haldamine

### Protsess vs Teenus

**Protsess (Process):**
- Käimasolev programm (running program)
- Igal protsessil on PID (Process ID)
- Näited: nginx worker, postgres backend, node.js app

**Teenus (Service):**
- Protsess, mida haldab systemd
- Käivitub automaatselt boot'il
- Näited: nginx.service, postgresql.service

**DevOps perspektive:**
> "Ma ei käivita nginx'i käsitsi käsurealt (`nginx`). Ma haldan seda teenusena (`systemctl start nginx`)."

---

### systemd - Teenuste Haldamise Süsteem

**Mis on systemd?**
- Modern init system (asendas vana SysVinit)
- Haldab kõiki süsteemi teenuseid
- Paralleelib boot'i → kiirem käivitamine
- Integrated logging (journald)

**Põhikäsud:**

```bash
# Teenuse staatus
systemctl status nginx

# Käivita teenus
systemctl start nginx

# Peata teenus
systemctl stop nginx

# Taaskäivita teenus
systemctl restart nginx

# Luba automaatne käivitamine boot'il
systemctl enable nginx

# Keela automaatne käivitamine
systemctl disable nginx

# Vaata kõiki aktiivseid teenuseid
systemctl list-units --type=service --state=running
```

**Miks see oluline?**

1. **Automaatne taaskäivitamine:**
   - Teenus crashib → systemd taaskäivitab (Restart=on-failure)
   - Production ready: rakendus ei jää maha pärast serveri restart'i

2. **Ressursside haldamine:**
   - Võid piirata CPU, RAM, I/O (cgroups)
   - Näide: `MemoryMax=2G` - PostgreSQL ei saa kasutada rohkem kui 2GB RAM

3. **Dependencies:**
   - `After=network.target` - käivita pärast võrgu üles tulekut
   - `Requires=postgresql.service` - backend vajab andmebaasi

---

### Custom Teenuse Loomine

**Stsenaarium:** Node.js backend DevOps administraatori vaates

**`/etc/systemd/system/backend-nodejs.service`:**
```ini
[Unit]
Description=User Service (Node.js Backend)
After=network.target postgresql.service

[Service]
Type=simple
User=student
WorkingDirectory=/opt/backend-nodejs
Environment="NODE_ENV=production"
Environment="DB_HOST=localhost"
ExecStart=/usr/bin/node /opt/backend-nodejs/src/index.js
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Kontseptuaalne selgitus:**

- **After=postgresql.service:** Backend EI käivitu enne, kui DB on valmis
- **Restart=on-failure:** Crashib → 10 sek pärast uuesti käivitamine
- **WorkingDirectory:** Protsess näeb seda kui `/` (relative paths)
- **Environment:** Env vars (aga production'is kasutame pigem EnvironmentFile=/opt/backend-nodejs/.env)

**DevOps töövoog:**
```bash
# 1. Kopeeri rakendus
sudo cp -r backend-nodejs /opt/

# 2. Loo teenuse fail
sudo vim /etc/systemd/system/backend-nodejs.service

# 3. Laadi systemd konfiguratsioon uuesti
sudo systemctl daemon-reload

# 4. Luba ja käivita teenus
sudo systemctl enable --now backend-nodejs

# 5. Kontrolli staatust
sudo systemctl status backend-nodejs
```

📖 **Praktika:** Labor 1, Harjutus 6 - Custom systemd teenuse loomine

---

### Protsesside Monitoorimine

**`ps` - Protsesside nimekiri**

Vaata käimasolevaid protsesse:
```bash
ps aux | grep postgres
```

**Väljundi tähendus:**
- USER: kes protsessi omanik
- PID: Process ID
- %CPU, %MEM: ressursside kasutus
- COMMAND: käsk, mis protsessi käivitas

**`top` / `htop` - Reaalajas monitooring**

**top:** Standard, kõigil serveritel olemas
**htop:** Kaunistatud, värvid, hõlpsam kasutada (peab installima)

**Mida DevOps administraator otsib:**
- CPU 100% → rakendus on bottleneck'is
- MEM 95% → vajad rohkem RAM'i või on memory leak
- Load Average > CPU core count → süsteem on ülekoormatud

---

## 2.3 Logide Vaatamine ja Analüüs

### Miks logid on DevOps'i kõige tähtsam tööriist?

**Tõrkeotsingud:**
> "Rakendus ei tööta" → Esimene küsimus: "Mida logid näitavad?"

**Logid räägivad:**
- Application errors (500 Internal Server Error)
- Database connection failures (can't connect to PostgreSQL)
- Authentication failures (invalid JWT token)
- Performance issues (slow query: 5 seconds)

---

### journalctl - systemd Logide Vaatamine

**Mis on journald?**
- systemd integrated logging
- Kõik teenuste logid ühes kohas
- Binary format (binary log storage, not plain text)

**Põhikäsud:**

```bash
# Vaata kõiki logisid (uusimad lõpus)
journalctl

# Vaata konkreetse teenuse logisid
journalctl -u nginx

# Reaalajas jälgimine (tail -f analoog)
journalctl -u nginx -f

# Viimased 50 rida
journalctl -u backend-nodejs -n 50

# Logid alates teatavast ajast
journalctl --since "2025-01-23 10:00:00"

# Logid vahemikus
journalctl --since "1 hour ago" --until "now"

# Ainult error level ja kõrgemad
journalctl -u backend-nodejs -p err
```

**DevOps töövoog - Tõrkeotsingud:**

```
1. Teenus ei käivitu:
   systemctl status backend-nodejs
   → journalctl -u backend-nodejs -n 100

2. Rakendus crashib jooksutamise ajal:
   journalctl -u backend-nodejs -f
   → Vaata real-time error message

3. Ajaloolised logid:
   journalctl --since "yesterday" -u backend-nodejs
```

---

### `/var/log/` - Traditsioonilised Logifailid

**Miks `/var/log/`, kui on journald?**
- Mõned rakendused kirjutavad otse failidesse
- Plain text logid on lihtsam parsida (grep, awk)
- Log rotation (logrotate) töötab failidega

**Kriitilised logifailid:**

**Süsteemilogid:**
- `/var/log/syslog` - Üldised süsteemisündmused
- `/var/log/auth.log` - SSH login'id, sudo kasutamine
- `/var/log/kern.log` - Kernel messages (hardware issues)

**Rakenduste logid:**
- `/var/log/nginx/access.log` - HTTP requests
- `/var/log/nginx/error.log` - Nginx errors
- `/var/log/postgresql/postgresql-16-main.log` - DB queries, errors

**Näited:**

```bash
# SSH login'ide jälgimine
tail -f /var/log/auth.log

# Nginx viimased 100 rida
tail -n 100 /var/log/nginx/access.log

# Otsi error'eid Nginx logidest
grep "ERROR" /var/log/nginx/error.log

# 500 Internal Server Error'id
grep " 500 " /var/log/nginx/access.log
```

---

### Log Rotation - Logide Haldamine

**Probleem:**
- Nginx access.log kasvab päevas 1GB
- 30 päevaga → 30GB
- Ketas täitub → rakendus crashib

**Lahendus: logrotate**

Automatically:
- Rotate logisid (access.log → access.log.1 → access.log.2.gz)
- Kompresseeri vanad logid (gzip)
- Kustuta vanad logid (>30 päeva)

**Konfiguratsioon: `/etc/logrotate.d/nginx`**
```
/var/log/nginx/*.log {
    daily           # Igapäevane rotatsioon
    rotate 14       # Hoia 14 päeva logisid
    compress        # Kompressi vanad logid
    delaycompress   # Ei kompressi viimast (1-päevast)
    notifempty      # Ei roteeri, kui fail tühi
    create 0640 www-data adm
    sharedscripts
    postrotate
        systemctl reload nginx  # Nginx peab avama uue log faili
    endscript
}
```

**DevOps perspektive:**
> "Ma ei pea käsitsi logisid kustutama. Logrotate teeb seda automaatselt. Mu ülesanne on KONTROLLIDA, et rotatsiooni konfiguratsioon on õige."

📖 **Praktika:** Labor 0, Harjutus 4 - Logide vaatamine ja analyys

---

## 2.4 Võrgu Haldamine

### Miks võrk on DevOps'i kriitiline?

**Mikroteenused:**
- Frontend → Backend → PostgreSQL → Redis
- Iga ühendus kasutab võrku (network socket)
- DevOps peab teadma, kuidas ühendusi debuggida

---

### Võrgu Diagnostika Tööriistad

**`ip` - Network interface haldamine**

Vaata network interface'e:
```bash
ip addr show
ip a  # Lühend
```

**Väljund:**
```
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
    inet 10.0.0.5/24  # IP address + subnet mask
    inet6 fe80::...   # IPv6 address
```

**Mida DevOps otsib:**
- Kas interface on UP? (võrk töötab)
- Mis on IP address? (10.0.0.5)
- Mis on subnet? (/24 = 255.255.255.0)

---

**`ss` - Socket statistics (asendab vana `netstat`)**

Vaata avatud porte:
```bash
# Kõik kuulavad (listening) pordid
ss -tulpn

# -t: TCP
# -u: UDP
# -l: listening
# -p: process name
# -n: numeric (ei resolve'i hostname'e)
```

**Näide väljund:**
```
tcp   LISTEN  0  128  0.0.0.0:22      0.0.0.0:*   users:(("sshd",pid=1234))
tcp   LISTEN  0  128  0.0.0.0:80      0.0.0.0:*   users:(("nginx",pid=5678))
tcp   LISTEN  0  128  127.0.0.1:5432  0.0.0.0:*   users:(("postgres",pid=9012))
```

**DevOps analüüs:**
- Port 22 (SSH): kuulab kõigil interface'idel (0.0.0.0)
- Port 80 (Nginx): kuulab kõigil interface'idel
- Port 5432 (PostgreSQL): kuulab AINULT localhost'il (127.0.0.1) → turvaline!

**Praktiline kasutus:**
```
Backend ei saa ühendust PostgreSQL'iga.

1. Kontrolli, kas PostgreSQL kuulab:
   ss -tulpn | grep 5432

2. Kui ei kuula:
   → systemctl status postgresql (kas teenus töötab?)
   → journalctl -u postgresql (mis on error?)

3. Kui kuulab ainult 127.0.0.1, aga backend on teises serveris:
   → Muuda /etc/postgresql/.../postgresql.conf
   → listen_addresses = '*'
   → systemctl restart postgresql
```

---

**`ping` - Ühenduvuse test**

```bash
ping google.com
```

**Mida see testib:**
- DNS resolution (kas google.com → IP address töötab?)
- Network connectivity (kas pakettid jõuavad google.com serverisse?)

**DevOps kasutus:**
- Backend ei saa ühendust external API'ga
- ping api.example.com → Kontrolli, kas võrk töötab

---

**`curl` - HTTP requests**

```bash
# Testi API endpoint'i
curl http://localhost:3000/health

# Näita HTTP header'eid
curl -I http://localhost:3000/health

# POST request
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

**DevOps kasutus:**
- Testi, kas backend vastab (health check)
- Debug API errors (mis HTTP status code tagastatakse?)

📖 **Praktika:** Labor 0, Harjutus 5 - Võrgu diagnostika

---

## 2.5 Package Management (APT)

### Miks APT DevOps töös?

**Traditional installs:**
- PostgreSQL, Nginx, Docker → APT
- Dependency management (installitakse automaatselt kõik dependencies)
- Security updates (apt upgrade)

**DevOps perspektive:**
> "Ma ei compili PostgreSQL'i source code'ist. Ma installin APT'iga, mis annab mulle production-ready binary + automatic updates."

---

### APT Põhikäsud

```bash
# Update package list (ALATI enne install'i!)
sudo apt update

# Upgrade kõiki pakette
sudo apt upgrade

# Install package
sudo apt install postgresql-16

# Remove package
sudo apt remove postgresql-16

# Remove package + config files
sudo apt purge postgresql-16

# Otsi paketti
apt search postgres

# Vaata paketi infot
apt show postgresql-16

# List installed packages
apt list --installed
```

**DevOps töövoog:**

```bash
# 1. Update package index
sudo apt update

# 2. Install PostgreSQL
sudo apt install postgresql-16

# 3. Teenus käivitub automaatselt
systemctl status postgresql

# 4. Security updates (iga nädal)
sudo apt update && sudo apt upgrade -y
```

---

### APT Repositories

**Mis on repository?**
- Server, kust APT package'id alla laeb
- `/etc/apt/sources.list`
- Kolmanda osapoole repo'd: Docker, Kubernetes, PostgreSQL

**Näide: PostgreSQL official repo lisamine**

```bash
# Add PostgreSQL APT repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Add GPG key
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update package list
sudo apt update

# Now you can install latest PostgreSQL
sudo apt install postgresql-16
```

**DevOps praktikas:**
- Ubuntu 24.04 default repo → PostgreSQL 14
- PostgreSQL official repo → PostgreSQL 16 (latest)
- Production: kasutame latest stable version

📖 **Praktika:** Labor 0, Harjutus 6 - APT package management

---

## 2.6 Environment Variables ja PATH

### Mis on Environment Variables?

**Definitsion:**
- Muutujad, mis on kättesaadavad KÕIGILE protsessidele
- Kasutatud konfiguratsiooni jaoks (nt DB_HOST, API_KEY)
- 12-Factor App principle: Config in environment

**DevOps kontekst:**
> "Ma ei hardcodi DB parooli koodi. Ma panen selle environment variable'sse."

---

### Põhilised Env Vars

```bash
# Vaata kõiki env vars
env

# Vaata konkreetset
echo $PATH
echo $HOME
echo $USER
```

**Kriitilised env vars:**

**PATH:**
```
PATH=/usr/local/bin:/usr/bin:/bin
```

**Mida see tähendab?**
- Kui kirjutan `node`, siis Linux otsib:
  1. `/usr/local/bin/node`
  2. `/usr/bin/node`
  3. `/bin/node`
- Esimene leitud → käivitatakse

**Miks oluline?**
- Node.js install → `/usr/bin/node`
- Custom binary → `/usr/local/bin/myapp`
- Kui PATH ei sisalda `/usr/local/bin` → `myapp: command not found`

---

### Env Vars Rakenduste Jaoks

**Node.js backend näide:**

```bash
# Shell'is
export DB_HOST=localhost
export DB_PORT=5432
export JWT_SECRET=my-secret-key

# Käivita rakendus
node src/index.js
```

**Rakenduse koodis:**
```javascript
const dbHost = process.env.DB_HOST || 'localhost';
```

**DevOps praktikas:**

**Development:** `.env` fail
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=user_service_db
JWT_SECRET=dev-secret
```

**Production:** systemd EnvironmentFile
```ini
[Service]
EnvironmentFile=/opt/backend-nodejs/.env
ExecStart=/usr/bin/node /opt/backend-nodejs/src/index.js
```

**Kubernetes:** ConfigMap + Secret
```yaml
env:
  - name: DB_HOST
    valueFrom:
      configMapKeyRef:
        name: backend-config
        key: db_host
```

**Miks environment variables?**

1. **Security:** Secrets ei ole koodis (no Git commits)
2. **Portability:** Sama kood töötab dev, staging, prod (erinev config)
3. **12-Factor App:** Industry standard best practice

📖 **Praktika:** Labor 1, Harjutus 3 - Environment variables Docker'is

---

## 2.7 Cron Jobs - Automatiseeritud Ülesanded

### Miks cron DevOps'is?

**Regulaarsed ülesanded:**
- PostgreSQL backup iga päev kell 02:00
- Log cleanup iga nädal
- Certificate renewal (Let's Encrypt) iga 3 kuud
- Metrics collection iga 5 minutit

**DevOps perspektive:**
> "Ma ei tee backup'e käsitsi. Cron teeb seda automaatselt iga öö."

---

### Cron Süntaks

```
* * * * * /path/to/command

│ │ │ │ │
│ │ │ │ └─ Day of week (0-7, 0 ja 7 on pühapäev)
│ │ │ └─── Month (1-12)
│ │ └───── Day of month (1-31)
│ └─────── Hour (0-23)
└───────── Minute (0-59)
```

**Näited:**

```bash
# Iga päev kell 02:00
0 2 * * * /opt/scripts/backup.sh

# Iga tunni alguses
0 * * * * /opt/scripts/cleanup.sh

# Iga 5 minuti tagant
*/5 * * * * /opt/scripts/check-health.sh

# Esmaspäeviti kell 09:00
0 9 * * 1 /opt/scripts/weekly-report.sh

# Kuu esimesel päeval kell 03:00
0 3 1 * * /opt/scripts/monthly-cleanup.sh
```

---

### Crontab Haldamine

```bash
# Vaata oma crontab'i
crontab -l

# Muuda crontab'i
crontab -e

# Root kasutaja crontab
sudo crontab -e
```

**Praktiline näide - PostgreSQL backup:**

```bash
# 1. Loo backup script
sudo vim /opt/scripts/postgres-backup.sh
```

```bash
#!/bin/bash
BACKUP_DIR=/var/backups/postgresql
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
docker exec postgres pg_dump -U appuser user_service_db > $BACKUP_DIR/backup_$DATE.sql

# Keep only last 7 days
find $BACKUP_DIR -type f -mtime +7 -delete
```

```bash
# 2. Tee script käivitatavaks
sudo chmod +x /opt/scripts/postgres-backup.sh

# 3. Lisa crontab'i (root)
sudo crontab -e

# 4. Lisa rida:
0 2 * * * /opt/scripts/postgres-backup.sh >> /var/log/postgres-backup.log 2>&1
```

**Selgitus:**
- `>> /var/log/postgres-backup.log` - Väljund logifaili
- `2>&1` - Redirect errors ka samasse faili

---

### Systemd Timers - Modern Alternative

**Miks systemd timer?**
- Parem logging (journalctl)
- Dependency management (After=network.target)
- Retry logic (Restart=on-failure)

**Näide - sama PostgreSQL backup:**

**`/etc/systemd/system/postgres-backup.service`:**
```ini
[Unit]
Description=PostgreSQL Backup
After=postgresql.service

[Service]
Type=oneshot
ExecStart=/opt/scripts/postgres-backup.sh
User=root
```

**`/etc/systemd/system/postgres-backup.timer`:**
```ini
[Unit]
Description=PostgreSQL Backup Timer

[Timer]
OnCalendar=daily
OnCalendar=02:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
# Enable and start timer
sudo systemctl enable --now postgres-backup.timer

# Check timer status
systemctl list-timers

# View logs
journalctl -u postgres-backup.service
```

📖 **Praktika:** Labor 3, Harjutus 6 - Automated PostgreSQL backups

---

## 2.8 File Permissions ja Ownership

### Miks permissions DevOps'is?

**Security:**
- Rakendus EI TOHI saada kirjutada `/etc/passwd`
- Nginx worker töötab kui `www-data` user (mitte root)
- PostgreSQL data files kuuluvad `postgres` userile

**Praktiline probleem:**
```
Permission denied: /var/lib/postgresql/data

→ Wrong ownership → rakendus crashib
```

---

### Permission Model

**Formaat: `rwxrwxrwx`**

```
-rw-r--r--  1 student student  1234 Jan 23 10:00 file.txt
│││││││││
││││││││└─ Other (kõik teised): read
│││││││└── Other: -
││││││└─── Other: -
│││││└──── Group: read
││││└───── Group: -
│││└────── Group: -
││└─────── Owner: read
│└──────── Owner: write
└───────── Owner: -
```

**Permission bits:**
- `r` (read): 4
- `w` (write): 2
- `x` (execute): 1

**Numeric form:**
```
chmod 644 file.txt
│││
││└─ Other: read (4)
│└── Group: read (4)
└─── Owner: read+write (6 = 4+2)
```

---

### Ownership

```bash
# Change owner
sudo chown student:student file.txt
#           user   group

# Change owner recursively
sudo chown -R www-data:www-data /var/www/html

# Change only group
sudo chgrp postgres /var/lib/postgresql/data
```

**DevOps praktikas:**

**Nginx static files:**
```bash
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```
- Owner: www-data (Nginx worker)
- Permissions: 755 = rwxr-xr-x (owner kirjutada, teised lugeda)

**PostgreSQL data directory:**
```bash
sudo chown -R postgres:postgres /var/lib/postgresql/16/main
sudo chmod 700 /var/lib/postgresql/16/main
```
- Owner: postgres
- Permissions: 700 = rwx------ (AINULT owner access)
- Miks? Security - keegi teine ei tohi näha DB andmeid

---

## Kokkuvõte

### Mida sa õppisid?

**Linux failisüsteem:**
- `/etc` - Konfiguratsioonifailid (systemd, nginx, ssh)
- `/var/log` - Logid (journalctl, nginx, postgresql)
- `/var/lib` - Andmed (postgresql data, docker volumes)
- `/opt` - Custom rakendused

**Protsesside haldamine:**
- systemd - Teenuste haldamine (start, stop, enable, disable)
- Custom teenuste loomine (`.service` failid)
- Ressursside monitooring (top, htop, ps)

**Logide vaatamine:**
- journalctl - systemd logid (reaal-ajas ja ajaloolised)
- /var/log/ - Traditsioonilised logifailid (nginx, postgresql)
- logrotate - Logide automaatne rotatsioon

**Võrgu haldamine:**
- ip - Network interfaces
- ss - Avatud pordid (listening services)
- ping, curl - Ühenduvuse testimine

**Package management:**
- apt - Tarkvara installeerimine ja uuendamine
- APT repositories - Kolmanda osapoole tarkvarad

**Automatiseerimine:**
- cron - Ajastatud ülesanded (backups, cleanup)
- systemd timers - Modern alternative cron'ile

**Security:**
- File permissions (chmod, chown)
- Least privilege principle (rakendused ei tööta kui root)

---

### DevOps Administraatori Vaatenurk

**Iga päev kasutad:**
```bash
systemctl status <service>   # Kas teenus töötab?
journalctl -u <service> -f   # Mis on error?
ss -tulpn | grep <port>      # Kas port kuulab?
curl http://localhost:3000/health  # Kas API vastab?
```

**Iga nädal/kuu:**
```bash
sudo apt update && sudo apt upgrade  # Security updates
crontab -l  # Kontrolli backup'e
```

**Tõrkeotsing:**
```
1. systemctl status → Kas teenus töötab?
2. journalctl -u → Mis on error message?
3. ss -tulpn → Kas port kuulab?
4. curl → Kas API vastab?
5. /var/log/ → Application logid
```

---

### Järgmised Sammud

**Peatükk 3:** Git DevOps Töövoos
**Peatükk 4:** Docker Põhimõtted (konteinerite maailm!)

---

**Kestus kokku:** ~3 tundi teooriat + praktilised harjutused labides
