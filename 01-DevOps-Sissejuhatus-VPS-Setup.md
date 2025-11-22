# Peatükk 1: DevOps Sissejuhatus ja VPS Setup

**Kestus:** 3 tundi
**Tase:** Algaja
**Eeldused:** Baasteadmised arvutitest ja internetist

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist oskad:

1. ✅ Selgitada DevOps kultuuri ja põhimõtteid
2. ✅ Mõista Infrastructure as Code (IaC) kontseptsiooni
3. ✅ Eristada VPS, Cloud ja On-Premise lahendusi
4. ✅ Seadistada turvalist SSH ligipääsu võtmetega
5. ✅ Konfigureerida UFW firewalli põhireegleid
6. ✅ Hallata kasutajaid ja sudo õigusi
7. ✅ Käivitada ja jälgida systemd teenuseid

---

## 🎯 1. DevOps: Mis See On ja Miks Me Seda Vajame?

### 1.1 Traditsiooniline IT vs DevOps

**Vana maailm (Waterfall):**
```
Arendajad (Dev) → Kood valmis → "Viska üle seina" → Operaatorid (Ops)
   ↓                                                        ↓
"Minu masinas töötab!"                            "See ei tööta production'is!"
   ↓                                                        ↓
Conflict ⚡                                         Süüdistamine 😠
```

**Probleem:**
- ❌ Aeglane tarkvara väljalaskmine (kuud/aastad)
- ❌ Arendajad ja operaatorid eraldi "siilobuses"
- ❌ "See ei ole minu probleem" mentaliteet
- ❌ Käsitsi deploy'mine → vigu, inimlikke eksimusi
- ❌ Production'i probleemid → pikk debug aeg

---

**Uus maailm (DevOps):**
```
Arendajad + Operaatorid = ÜKS MEESKOND
   ↓
Automatiseerimine (CI/CD)
   ↓
Kiire, sagedane, turvaline tarkvara väljalaskmine
   ↓
Järjepidev parendamine (Continuous Improvement)
```

**Lahendus:**
- ✅ Kiire tarkvara väljalaskmine (päevad/tunnid)
- ✅ Ühine vastutus kvaliteedi eest
- ✅ Automatiseeritud protsessid
- ✅ Infrastruktuur kui kood (reproducible)
- ✅ Kiirem vigade avastamine ja parandamine

---

### 1.2 DevOps Põhimõtted

**1. Kultuur (Culture):**
- Koostöö arendajate ja operaatorite vahel
- Jagatud vastutus
- Ebaõnnestumistest õppimine (blameless postmortems)
- Pidev parendamine

**2. Automatiseerimine (Automation):**
- Build, test, deploy automatiseerimine
- Infrastruktuuri haldamine koodiga (IaC)
- Monitoring ja alerting automaatne

**3. Mõõtmine (Measurement):**
- Metrikad ja logid
- Performance monitoring
- User feedback

**4. Jagamine (Sharing):**
- Teadmiste jagamine
- Dokumentatsioon
- Avatud kommunikatsioon

**Akronüüm:** **CAMS** (Culture, Automation, Measurement, Sharing)

---

### 1.3 DevOps Administraatori Roll

**Mida DevOps administraator TEEB:**

```bash
# DevOps administraator on "infrastruktuuri arhitekt"

✅ Haldab servereid ja konteinereid
✅ Seadistab orkestreerimist (Kubernetes)
✅ Automatiseerib deploy'mise (CI/CD)
✅ Monitoorib süsteeme (Prometheus, Grafana)
✅ Tagab turvalisuse (SSL, firewalls, secrets)
✅ Backup'ib andmeid ja taastab süsteeme
✅ Debuggib production'i probleeme
✅ Kirjutab Infrastructure as Code (Terraform, Kubernetes YAML)
```

**Mida DevOps administraator EI TEE:**

```bash
❌ Ei kirjuta rakenduste koodi (Node.js, Java)
❌ Ei disaini andmebaasi skeeme
❌ Ei implementeeri business logic'ut
❌ Ei loo frontend UI komponente

# Analoogia:
# Arendaja = Autotootja (loob auto)
# DevOps = Mehhaanik + Logistik (hooldab, transpordib, monitoorib)
```

---

## 🏗️ 2. Infrastructure as Code (IaC)

### 2.1 Mis On IaC?

**Definitsioon:**
Infrastructure as Code (IaC) on praktika, kus infrastruktuur (serverid, võrgud, load balancers) hallatakse ja proviseeritakse läbi koodi, mitte käsitsi konfiguratsiooni kaudu.

**Traditsiooniline viis (ClickOps):**
```bash
# Administraator:
1. Logi sisse serverisse SSH'ga
2. Käivita käsud käsitsi:
   sudo apt install nginx
   sudo systemctl start nginx
3. Muuda konfiguratsioonifaile käsitsi vim'iga
4. Tee screenshot'e, et meeles pidada, mida tegid
5. Korda samu samme teisel serveril 😓

# Probleem:
- ❌ Aeganõudev ja igav
- ❌ Inimlikud vead
- ❌ Ei ole reproducible (ei saa korrata)
- ❌ Ei ole versioned (git puudub)
```

**IaC viis:**
```yaml
# Kood (näiteks Kubernetes manifest):
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
```

```bash
# Rakendamine:
kubectl apply -f nginx-deployment.yaml

# Plussid:
✅ Kiire ja reproducible
✅ Versioned Git'is
✅ Code review võimalik
✅ Automated testing võimalik
✅ Üks käsk → kogu infrastruktuur valmis
```

---

### 2.2 IaC Tööriistad

**Kategooriad:**

| Kategooria | Tööriist | Kasutus |
|-----------|----------|---------|
| **Konfiguratsioon** | Ansible, Chef, Puppet | Serverite seadistamine |
| **Provisioneerimine** | Terraform, Pulumi | Cloud ressursside loomine |
| **Orkestratsioon** | Kubernetes, Docker Compose | Konteinerite haldamine |
| **CI/CD** | GitHub Actions, GitLab CI | Automatiseerimine |

**Selles koolituskavas kasutame:**
- ✅ **Docker** - konteinerisatsioon
- ✅ **Docker Compose** - multi-container orkestratsioon
- ✅ **Kubernetes (K3s)** - production orkestratsioon
- ✅ **GitHub Actions** - CI/CD automatiseerimine

---

## 🖥️ 3. VPS vs Cloud vs On-Premise

### 3.1 Võrdlus

| Aspekt | VPS | Cloud (IaaS) | On-Premise |
|--------|-----|--------------|------------|
| **Definitsioon** | Virtual Private Server | Pay-as-you-go infrastruktuur | Oma serverid firmas |
| **Hind** | 5-50€/kuu (fikseeritud) | Kasutusepõhine (muutuv) | Suur algsinvesteering |
| **Skaleeruvus** | Piiratud (upgrade VPS) | Peaaegu lõpmatu | Aeglane (osta riist) |
| **Kontrolli tase** | Root access | API kaudu | Täielik kontroll |
| **Maintenance** | Provider hooldab riista | Provider hooldab riista | Sina hooldad kõike |
| **Setup aeg** | Minutid | Sekundid (API) | Nädalad/kuud |
| **Näited** | Hetzner, DigitalOcean, Linode | AWS, Azure, GCP | Oma serveriruum |

---

### 3.2 Millal Kasutada?

**VPS (meie valik koolituskavas):**
```
✅ Kasuta kui:
- Väike/keskmine projekt (1-10 serverit)
- Eelarve on piiratud (5-50€/kuu)
- Lihtne setup (SSH + apt)
- Stabiilne koormus (ei vaja autoscaling'ut)

❌ Ära kasuta kui:
- Vajad kiiresti 100+ serverit
- Vajad managed teenuseid (RDS, EKS)
- Vajad globaalset CDN'i
```

**Cloud (AWS, Azure, GCP):**
```
✅ Kasuta kui:
- Suur projekt (enterprise)
- Vajad autoscaling'ut
- Vajad managed teenuseid
- Vajad globaalset infrastruktuuri

❌ Ära kasuta kui:
- Väga piiratud eelarve
- Lihtne projekt
- Ei taha cloud vendor lock-in'i
```

**On-Premise:**
```
✅ Kasuta kui:
- Ranged compliance nõuded
- Tundlikud andmed (pangad, valitsus)
- Väga suur skaala (Google, Facebook)

❌ Ära kasuta kui:
- Väike ettevõte
- Puudub serveriruum
- Puudub IT personal riista haldamiseks
```

**💡 Meie strateegia:**
Õpime **VPS'il**, kuid kõik oskused on ülekantavad **Cloud'i** ja **On-Premise**.

📖 **Lisalugemine:** `LISA-PEATUKK-Cloud-Providers.md` (detailne IaaS/PaaS/SaaS selgitus)

---

## 🔐 4. SSH ja Turvalisus

### 4.1 Mis On SSH?

**SSH (Secure Shell)** on krüpteeritud protokoll, mida kasutatakse turvaliseks serverisse sisselogimiseks üle interneti.

```bash
# Baasskeem:
Sinu arvuti → SSH (krüpteeritud) → VPS server
   ↓                                     ↓
Private key                         Public key
```

---

### 4.2 SSH Võtmete Genereerimine

**Parooli-põhine autentimine (EI SOOVITATA):**
```bash
# PROBLEEM:
ssh root@YOUR_VPS_IP
Password: *******

❌ Paroole saab brute-force'ida
❌ Paroolid lekivad
❌ Ebamugav (peab meeles pidama)
```

**Võtme-põhine autentimine (SOOVITATUD):**
```bash
# Lokaalne arvuti - Genereeri SSH võtmepaar
ssh-keygen -t ed25519 -C "your-email@example.com"

# Väljund:
# Generating public/private ed25519 key pair.
# Enter file in which to save the key (/home/you/.ssh/id_ed25519): [Enter]
# Enter passphrase (empty for no passphrase): [Sisesta turvaline parool]
# Enter same passphrase again: [Korda]

# Loodud failid:
# ~/.ssh/id_ed25519        ← PRIVATE key (ÄRA JAGA!)
# ~/.ssh/id_ed25519.pub    ← PUBLIC key (safe to share)
```

**Miks ed25519?**
- ✅ Kiirem kui RSA
- ✅ Turvalisem (256-bit security)
- ✅ Väiksem võtme suurus
- ✅ Industry standard 2025

---

### 4.3 Public Key'i Ülespanek Serverisse

**Variant 1: ssh-copy-id (lihtsaim):**
```bash
# Lokaalne arvuti
ssh-copy-id your-username@YOUR_VPS_IP

# Sisesta VPS parool viimast korda
# Public key kopeeritakse automaatselt → ~/.ssh/authorized_keys
```

**Variant 2: Käsitsi (kui ssh-copy-id puudub):**
```bash
# 1. Lokaalne arvuti - Kopeeri public key
cat ~/.ssh/id_ed25519.pub

# 2. VPS - Lisa public key authorized_keys faili
mkdir -p ~/.ssh
chmod 700 ~/.ssh
vim ~/.ssh/authorized_keys  # Paste public key siia
chmod 600 ~/.ssh/authorized_keys
```

**Test:**
```bash
# Lokaalne arvuti - Logi sisse ILMA paroolita
ssh your-username@YOUR_VPS_IP

# Kui küsib passphrase'd (mitte parooli), siis töötab! ✅
```

---

### 4.4 SSH Serveri Turvalisuse Parandamine

**Keela root login ja parooli-autentimine:**
```bash
# VPS
sudo vim /etc/ssh/sshd_config

# Muuda järgmised read:
PermitRootLogin no                    # Keela root SSH
PasswordAuthentication no             # Keela paroolid
PubkeyAuthentication yes              # Luba ainult SSH võtmed
Port 22                               # Võid muuta (nt 2222), kuid 22 on standard

# Salvesta ja taaskäivita SSH
sudo systemctl restart sshd

# Test (teises terminalis, et mitte lukustada ennast välja!):
ssh your-username@YOUR_VPS_IP
```

**⚠️ HOIATUS:**
Enne SSH serveri taaskäivitamist, **testi uues terminalis**, et sa ei lukusta ennast välja!

---

## 🔥 5. UFW Firewall

### 5.1 Mis On Firewall?

**Firewall** on võrgututvamüür, mis kontrollib sissetulevat ja väljuvat liiklust.

```bash
# Skeem:
Internet → Firewall → VPS
             ↓
        Allow/Deny reeglid
```

**UFW (Uncomplicated Firewall)** on Ubuntu's sisseehitatud firewall tööriist.

---

### 5.2 UFW Põhikäsud

**Installi UFW (kui puudub):**
```bash
sudo apt update
sudo apt install ufw -y
```

**Kontrolli staatust:**
```bash
sudo ufw status
# Status: inactive
```

**⚠️ ENNE LUBAMIST: LUBA SSH!**
```bash
# KRIITILISELT OLULINE - vastasel juhul lukustad ennast välja!
sudo ufw allow 22/tcp comment 'SSH'

# VÕI kui muutsid SSH porti:
sudo ufw allow 2222/tcp comment 'SSH custom port'
```

**Luba firewall:**
```bash
sudo ufw enable

# Warning: This may disrupt existing ssh connections. Proceed with operation (y|n)? y
# Firewall is active and enabled on system startup
```

**Kontrolli:**
```bash
sudo ufw status verbose

# Output:
# Status: active
# Logging: on (low)
# Default: deny (incoming), allow (outgoing), disabled (routed)
#
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW IN    Anywhere                  # SSH
```

---

### 5.3 Liikluse Lubamine

**Luba HTTP ja HTTPS (veebiserver):**
```bash
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
```

**Luba PostgreSQL (ainult localhost'ist):**
```bash
# RANGE limit:
sudo ufw allow from 10.0.0.0/8 to any port 5432 comment 'PostgreSQL local'

# VÕI ainult localhost:
sudo ufw allow from 127.0.0.1 to any port 5432
```

**Luba NodePort (Kubernetes):**
```bash
# Kubernetes NodePort range
sudo ufw allow 30000:32767/tcp comment 'K8s NodePort'
```

---

### 5.4 Reeglite Kustutamine

**Vaata reeglite numbreid:**
```bash
sudo ufw status numbered

# Output:
# [ 1] 22/tcp         ALLOW IN    Anywhere
# [ 2] 80/tcp         ALLOW IN    Anywhere
# [ 3] 443/tcp        ALLOW IN    Anywhere
```

**Kustuta reegel numbri järgi:**
```bash
sudo ufw delete 2  # Kustutab HTTP reegli
```

**Kustuta reegel käsu järgi:**
```bash
sudo ufw delete allow 80/tcp
```

---

### 5.5 UFW Default Policies

**Kontrolli default police:**
```bash
sudo ufw status verbose

# Default: deny (incoming), allow (outgoing)
```

**Muuda default police (harv):**
```bash
# Keela KÕIK sissetulev liiklus (peale lubatud reeglite)
sudo ufw default deny incoming

# Luba KÕIK väljuv liiklus
sudo ufw default allow outgoing
```

**See on TURVALINE default:** deny incoming, allow outgoing ✅

---

## 👤 6. Kasutajate ja Sudo Haldamine

### 6.1 Root vs Tavalise Kasutaja

**Root kasutaja:**
```bash
# Root = "superuser" = täielik kontroll
# OHTLIK - üks viga võib hävitada kogu süsteemi

❌ ÄRA kasuta root'i igapäevaseks tööks
✅ Kasuta tavalist kasutajat + sudo
```

**Tavaline kasutaja + sudo:**
```bash
# Tavaline kasutaja ei saa teha süsteemse muudatusi
# sudo = "Super User DO" = ajutine root õigus

✅ Turvalisem (peab sudo parooli sisestama)
✅ Auditeeritud (sudo logib kõik käsud)
✅ Best practice
```

---

### 6.2 Uue Kasutaja Loomine

**Loo uus kasutaja:**
```bash
# Root või sudo kasutajana
sudo adduser student

# Küsitakse:
# Enter new UNIX password: ********
# Retype new UNIX password: ********
# Full Name []: Student User
# Room Number []: [Enter]
# ... [Enter kõigile]
```

**Lisa sudo gruppi:**
```bash
sudo usermod -aG sudo student

# -a = append (lisa)
# -G = groups
# sudo = grupi nimi
```

**Kontrolli:**
```bash
# Vaata kasutaja gruppe
groups student
# student : student sudo

# Test sudo õigusi
su - student
sudo whoami
# root ← Töötab! ✅
```

---

### 6.3 Sudo Konfiguratsioon

**Sudo config file:**
```bash
sudo visudo  # KASUTA ALATI visudo, mitte vim /etc/sudoers!

# Fail: /etc/sudoers
```

**Luba kasutajal sudo ILMA paroolita (OPTIONAL, test env):**
```bash
sudo visudo

# Lisa faili lõppu:
student ALL=(ALL) NOPASSWD:ALL

# Salvesta ja välju
```

**⚠️ HOIATUS:**
`NOPASSWD` on mugav arenduseks, kuid **EBATURVALINE production'is**!

---

### 6.4 SSH Võtmete Kopeerimine Uuele Kasutajale

**Probleem:**
Lõid uue kasutaja `student`, kuid SSH võtmed on `root` all.

**Lahendus - Kopeeri authorized_keys:**
```bash
# Root kasutajana
mkdir -p /home/student/.ssh
cp /root/.ssh/authorized_keys /home/student/.ssh/
chown -R student:student /home/student/.ssh
chmod 700 /home/student/.ssh
chmod 600 /home/student/.ssh/authorized_keys
```

**Test:**
```bash
# Lokaalne arvuti
ssh student@YOUR_VPS_IP
# Töötab ilma paroolita! ✅
```

---

## ⚙️ 7. Systemd Teenuste Haldamine

### 7.1 Mis On Systemd?

**Systemd** on Ubuntu (ja enamiku Linux distributsioonide) init süsteem, mis haldab teenuseid (services).

```bash
# Näited teenustest:
- sshd (SSH server)
- docker (Docker daemon)
- nginx (veebiserver)
- postgresql (andmebaas)
```

---

### 7.2 Systemctl Põhikäsud

**Vaata teenuse staatust:**
```bash
sudo systemctl status ssh

# Output:
# ● ssh.service - OpenBSD Secure Shell server
#    Loaded: loaded (/lib/systemd/system/ssh.service; enabled)
#    Active: active (running) since Mon 2025-01-22 10:00:00 UTC; 2h ago
#      Docs: man:sshd(8)
#  Main PID: 1234 (sshd)
#     Tasks: 1 (limit: 4915)
#    Memory: 5.2M
#    CGroup: /system.slice/ssh.service
#            └─1234 /usr/sbin/sshd -D
```

**Käivita teenus:**
```bash
sudo systemctl start nginx
```

**Peata teenus:**
```bash
sudo systemctl stop nginx
```

**Taaskäivita teenus:**
```bash
sudo systemctl restart nginx
```

**Luba teenus käivituma boot'imisel:**
```bash
sudo systemctl enable nginx

# Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service
```

**Keela teenus boot'imisel:**
```bash
sudo systemctl disable nginx
```

---

### 7.3 Systemd Unit Fail (Enda Teenus)

**Näide - Loo lihtne teenus:**
```bash
# Loome bash skripti, mis logib iga 10 sekundi järel
sudo vim /usr/local/bin/hello-service.sh
```

```bash
#!/bin/bash
while true; do
    echo "$(date): Hello from custom service!" >> /var/log/hello-service.log
    sleep 10
done
```

```bash
# Tee käivitatavaks
sudo chmod +x /usr/local/bin/hello-service.sh
```

**Loo systemd unit fail:**
```bash
sudo vim /etc/systemd/system/hello.service
```

```ini
[Unit]
Description=Hello Custom Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/hello-service.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Käivita teenus:**
```bash
# Laadi systemd config uuesti
sudo systemctl daemon-reload

# Käivita teenus
sudo systemctl start hello

# Kontrolli staatust
sudo systemctl status hello

# Luba boot'imisel
sudo systemctl enable hello
```

**Vaata logisid:**
```bash
# Reaalajas
sudo journalctl -u hello -f

# Viimased 50 rida
sudo journalctl -u hello -n 50

# VÕI vaata faili
sudo tail -f /var/log/hello-service.log
```

---

## 📝 8. Praktilised Harjutused

### Harjutus 1: VPS Algne Seadistamine (30 min)

**Eesmärk:** Seadista VPS turvaliselt

**Sammud:**
1. Logi VPS'i sisse root'ina (esimene kord)
2. Uuenda süsteemi:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
3. Loo uus kasutaja `devops`:
   ```bash
   sudo adduser devops
   sudo usermod -aG sudo devops
   ```
4. Genereeri SSH võtmepaar lokaalselt (kui puudub)
5. Kopeeri public key uuele kasutajale
6. Logi sisse uue kasutajana ja testi sudo
7. Keela root login SSH config'us

**Kontrolli:**
- [ ] Uus kasutaja on loodud
- [ ] Kasutajal on sudo õigused
- [ ] SSH võtme autentimine töötab
- [ ] Root login on keelatud

---

### Harjutus 2: UFW Firewall Seadistamine (20 min)

**Eesmärk:** Seadista firewall veebiserveri jaoks

**Sammud:**
1. Installi UFW
2. Luba SSH (port 22)
3. Luba HTTP (port 80) ja HTTPS (port 443)
4. Luba firewall
5. Kontrolli reegleid
6. Testi, et SSH ühendus jääb toimima

**Kontrolli:**
- [ ] UFW on aktiivne
- [ ] SSH on lubatud
- [ ] HTTP ja HTTPS on lubatud
- [ ] Default policy on `deny incoming`

---

### Harjutus 3: Nginx Teenuse Haldamine (30 min)

**Eesmärk:** Installi ja halda Nginx veebiserveri teenust

**Sammud:**
1. Installi Nginx:
   ```bash
   sudo apt install nginx -y
   ```
2. Kontrolli teenuse staatust
3. Testi veebilehte: `curl http://localhost`
4. Peata teenus
5. Käivita uuesti
6. Luba boot'imisel
7. Vaata Nginx logisid:
   ```bash
   sudo journalctl -u nginx -f
   ```

**Kontrolli:**
- [ ] Nginx on paigaldatud
- [ ] Teenus käivitub boot'imisel
- [ ] Nginx vastab localhost'il
- [ ] Oskad vaadata logisid

---

### Harjutus 4: Kohandatud Systemd Teenus (40 min)

**Eesmärk:** Loo oma systemd teenus

**Sammud:**
1. Loo bash skript `/usr/local/bin/disk-monitor.sh`:
   ```bash
   #!/bin/bash
   while true; do
       df -h / | tail -1 >> /var/log/disk-usage.log
       date >> /var/log/disk-usage.log
       sleep 60
   done
   ```
2. Tee käivitatavaks
3. Loo systemd unit fail `/etc/systemd/system/disk-monitor.service`
4. Käivita teenus
5. Kontrolli, et logifail täitub
6. Testi teenuse restart'imist

**Kontrolli:**
- [ ] Skript on loodud ja käivitatav
- [ ] Systemd teenus on loodud
- [ ] Teenus logib `/var/log/disk-usage.log` faili
- [ ] Teenus käivitub pärast restart'i

---

### Harjutus 5: Troubleshooting (Valikuline, 30 min)

**Eesmärk:** Õpi debuggima systemd teenuseid

**Probleemne teenus:**
```bash
# Loo VIGANE teenus
sudo vim /etc/systemd/system/broken.service
```

```ini
[Unit]
Description=Broken Service

[Service]
ExecStart=/usr/bin/nonexistent-command

[Install]
WantedBy=multi-user.target
```

**Sinu ülesanne:**
1. Proovi teenust käivitada
2. Vaata, mis viga tuleb
3. Kasuta `journalctl -u broken` logide vaatamiseks
4. Paranda teenus (muuda ExecStart'i)
5. Käivita edukalt

**Õpitud oskused:**
- systemctl status lugemine
- journalctl kasutamine
- systemd teenuste debuggimine

---

## 🎓 9. Mida Sa Õppisid?

### Omandatud Teadmised

✅ **DevOps Kontseptsioonid:**
- DevOps kultuur: Dev + Ops koostöö
- CAMS põhimõtted (Culture, Automation, Measurement, Sharing)
- Infrastructure as Code (IaC) tähtsus
- DevOps administraatori roll vs arendaja roll

✅ **VPS ja Infrastruktuur:**
- VPS vs Cloud vs On-Premise eristamine
- Millal kasutada VPS'i vs Cloud'i
- VPS seadistamise alused

✅ **SSH Turvalisus:**
- SSH võtmete genereerimine (ed25519)
- Public/Private key paari kasutamine
- SSH serveri turvalise konfigureerimise
- Parooli-autentimise keelamine

✅ **Firewall (UFW):**
- UFW reeglite loomine
- Portide lubamine/keelamine
- Default policy seadistamine
- Firewall'i debuggimine

✅ **Kasutajate Haldamine:**
- Uute kasutajate loomine
- Sudo õiguste andmine
- Kasutajate gruppide haldamine
- Root kasutaja vs tavaline kasutaja

✅ **Systemd:**
- Teenuste käivitamine/peatamine
- Teenuste logide vaatamine (journalctl)
- Kohandatud systemd unit failide loomine
- Teenuste debuggimine

---

## 📚 10. Järgmised Sammud

**Peatükk 2: Linux Põhitõed DevOps Kontekstis**
- Failisüsteemi struktuur
- Protsesside haldamine
- Võrgu debugging
- Cron jobs

**Peatükk 3: Git DevOps Töövoos**
- Git põhikäsud
- Infrastructure as Code repositories
- GitOps kontseptsioon

**Peatükk 4: Docker Põhimõtted** 🐳
- Konteinerid vs VM'id
- Docker lifecycle
- Images ja containers
- **SIIT ALGAB MEIE DEVOPS TEEKOND!**

---

## 📖 Lisaressursid

**Dokumentatsioon:**
- [DevOps Roadmap 2025](https://roadmap.sh/devops)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [SSH Best Practices](https://www.ssh.com/academy/ssh/keygen)
- [Systemd Documentation](https://systemd.io/)

**Lisapeatükid:**
- `LISA-PEATUKK-Cloud-Providers.md` - IaaS/PaaS/SaaS, AWS, Azure, GCP
- `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` - 2025 best practices

---

## ✅ Kontrolli Ennast

Enne järgmisele peatükile liikumist, veendu et:

- [ ] Mõistad DevOps kultuuri ja CAMS põhimõtteid
- [ ] Oskad selgitada IaC kontseptsiooni ja eeliseid
- [ ] Oled seadistanud turvalist SSH ligipääsu võtmetega
- [ ] Oskad konfigureerida UFW firewall'i
- [ ] Oskad hallata kasutajaid ja sudo õigusi
- [ ] Oskad hallata systemd teenuseid
- [ ] Oled läbinud kõik praktilised harjutused

**Kui kõik on ✅, oled valmis Peatükiks 2!** 🚀

---

**Peatükk 1 lõpp**
**Järgmine:** Peatükk 2 - Linux Põhitõed DevOps Kontekstis

**Õnnitleme!** Oled astunud esimese sammu DevOps administraatori teekonnale! 🎉
