# Peatükk 2: VPS Esmane Seadistamine

**Kestus:** 3 tundi
**Eeldused:** Peatükk 1 läbitud
**Eesmärk:** Seadistada turvaline ühendus VPS-iga ja valmistada server ette arenduseks

---

## Sisukord

1. [SSH Põhimõtted ja Turvalisus](#1-ssh-põhimõtted-ja-turvalisus)
2. [SSH Võtmete Genereerimine Zorin OS-is](#2-ssh-võtmete-genereerimine-zorin-os-is)
3. [VPS-iga Ühenduse Loomine](#3-vps-iga-ühenduse-loomine)
4. [Esimesed Sammud VPS-is](#4-esimesed-sammud-vps-is)
5. [Turvalisuse Seadistamine](#5-turvalisuse-seadistamine)
6. [Kasutajate ja Õiguste Haldamine](#6-kasutajate-ja-õiguste-haldamine)
7. [Põhiliste Tööriistade Paigaldamine](#7-põhiliste-tööriistade-paigaldamine)
8. [Harjutused](#8-harjutused)
9. [Kontrolliküsimused](#9-kontrolliküsimused)
10. [Lisamaterjalid](#10-lisamaterjalid)

---

## 1. SSH Põhimõtted ja Turvalisus

### 1.1. Mis on SSH?

**SSH (Secure Shell)** on krüpteeritud võrguprotokoll, mis võimaldab turvaliselt ühenduda kaugserveriga ja seda hallata.

#### Analoogia: Turvaline Telefonikõne

Kujutame ette kaht suhtlusviisi:

**Ilma SSH-ta (Telnet, HTTP):**
- Nagu avalik telefonikõne, mida kõik saavad pealt kuulata
- Sinu paroolid lähevad läbi võrgu avatekstina
- Ükskõik kes võib neid varastada

**SSH-ga:**
- Nagu krüpteeritud turvaline telefonikõne
- Kogu liiklus on krüpteeritud
- Isegi kui keegi püüab pealt kuulata, näeb ainult juhuslikku müra

---

### 1.2. SSH Autentimise Meetodid

#### 1.2.1. Parooliga Autentimine

```
┌──────────────┐                    ┌──────────────┐
│   Sinu       │  "Kasutaja: root"  │     VPS      │
│  Arvuti      │─────────────────────▶              │
│              │  "Parool: ****"    │              │
│              │─────────────────────▶              │
│              │    ◀─────────────────│              │
│              │  "OK, sisse lubatud"│              │
└──────────────┘                    └──────────────┘
```

**Probleemid:**
- ❌ Paroolid võib ära arvata (brute-force)
- ❌ Paroolid võib varastada
- ❌ Inimesed kasutavad nõrku paroole
- ❌ Botid ründavad pidevalt SSH porte

---

#### 1.2.2. SSH Võtmepaariga Autentimine (SOOVITAV)

```
┌──────────────┐                    ┌──────────────┐
│   Sinu       │  "Kasutaja: root"  │     VPS      │
│  Arvuti      │─────────────────────▶              │
│              │  [Allkirjastan      │              │
│  Privaatvõti │   privaatvõtmega]  │  Avalik võti │
│              │─────────────────────▶              │
│              │  [VPS kontrollib    │              │
│              │   allkirja avaliku  │              │
│              │   võtmega]          │              │
│              │    ◀─────────────────│              │
│              │  "OK, sisse lubatud"│              │
└──────────────┘                    └──────────────┘
```

**Eelised:**
- ✅ Praktiliselt võimatu ära arvata
- ✅ Ei pea paroole meelde jätma
- ✅ Privaatvõti ei lahku kunagi sinu arvutist
- ✅ Saab parooli täiesti keelata

---

### 1.3. SSH Võtmepaar: Avalik vs Privaatne

**Analoogia:** Lukk ja Võti

**Avalik võti (public key):**
- Nagu tavalukk
- Saad selle kellelegi anda
- Ei ole ohtlik, kui keegi seda näeb
- Paigaldatakse serverisse
- Fail: `id_rsa.pub` või `id_ed25519.pub`

**Privaatne võti (private key):**
- Nagu lukuvõti
- **EI TOHI MITTE KUNAGI** kellegagi jagada
- Hoida turvaliselt oma arvutis
- Kaitstud parooliga (passphrase)
- Fail: `id_rsa` või `id_ed25519`

```
┌─────────────────────────────────────┐
│      Krüptograafia Põhimõte         │
├─────────────────────────────────────┤
│                                     │
│  Avalik võti krüpteerib ──┐         │
│                            │        │
│                            ▼        │
│                      [Krüpteeritud  │
│                       Sõnum]        │
│                            │        │
│                            │        │
│  Privaatne võti            │        │
│  dekrüpteerib  ◀───────────┘        │
│                                     │
└─────────────────────────────────────┘
```

---

### 1.4. SSH Turvalisuse Best Practices

| Meede | Kirjeldus | Prioriteet |
|-------|-----------|------------|
| **SSH võtmed** | Kasuta võtmepaare paroolide asemel | 🔴 Kriitiline |
| **Keela root login** | Loo eraldi kasutaja sudo õigustega | 🔴 Kriitiline |
| **Muuda SSH porti** | Kasuta mitte-standardset porti (nt 2222) | 🟡 Soovitav |
| **Firewall (UFW)** | Luba ainult vajalikud pordid | 🔴 Kriitiline |
| **Fail2ban** | Blokeeri automaatselt ründeid | 🔴 Kriitiline |
| **2FA (Two-Factor)** | Kaheastmeline autentimine | 🟡 Soovitav |

---

## 2. SSH Võtmete Genereerimine Zorin OS-is

### 2.1. Kontrolli Olemasolevaid Võtmeid

Enne uue võtmepaari loomist kontrolli, kas sul juba on mõni olemas:

```bash
# Kontrolli SSH kataloogi
ls -la ~/.ssh

# Kui kataloogi ei ole, on see OK (loome selle)
# Kui on, vaata milliseid võtmeid sul on:
# - id_rsa / id_rsa.pub (RSA võtmed)
# - id_ed25519 / id_ed25519.pub (Ed25519 võtmed - modernne)
```

**Võimalikud olukorrad:**

1. **~/.ssh kataloogi ei ole:** Jätkame võtmete loomisega
2. **Kataloog on, aga tühi:** Jätkame võtmete loomisega
3. **Võtmed juba olemas:** Võid kasutada olemasolevaid või luua uued

---

### 2.2. SSH Võtmepaari Genereerimine

#### Meetod 1: Ed25519 (SOOVITAV - modernne ja turvaline)

```bash
# Genereeri Ed25519 võtmepaar
ssh-keygen -t ed25519 -C "janek@zorin-laptop"

# Selgitus:
# -t ed25519     : Kasuta Ed25519 algoritmi (kiire, turvaline, lühike)
# -C "kommentaar": Lisa kommentaar (aitab võtmeid identifitseerida)
```

**Interaktiivne dialoog:**

```
Generating public/private ed25519 key pair.
Enter file in which to save the key (/home/janek/.ssh/id_ed25519):
```
👉 **Vajuta ENTER** (kasuta vaikimisi asukohta)

```
Enter passphrase (empty for no passphrase):
```
👉 **Sisesta tugev parool** (nt 20+ tähemärki, sõnad, numbrid, sümbolid)
   - Parool kaitseb privaatvõtit, kui keegi selle varastab
   - Säilita see parool turvalises kohas (nt KeePassXC)

```
Enter same passphrase again:
```
👉 **Korda parooli**

**Väljund:**
```
Your identification has been saved in /home/janek/.ssh/id_ed25519
Your public key has been saved in /home/janek/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx janek@zorin-laptop
The key's randomart image is:
+--[ED25519 256]--+
|        .o.      |
|       .  o      |
|      .  . .     |
|     . .. o      |
|    . o.S.       |
|     +o*=.       |
|    ..O=B+       |
|     *+X==.      |
|    .E*==o.      |
+----[SHA256]-----+
```

---

#### Meetod 2: RSA 4096-bit (Alternatiiv - laialdaselt toetatud)

Kui mingil põhjusel Ed25519 ei tööta (väga vanad serverid):

```bash
# Genereeri RSA 4096-bit võtmepaar
ssh-keygen -t rsa -b 4096 -C "janek@zorin-laptop"

# Selgitus:
# -t rsa      : Kasuta RSA algoritmi
# -b 4096     : 4096-bitine võti (turvaline)
# -C "comment": Kommentaar
```

---

### 2.3. Võtmete Õigused ja Turvalisus

SSH on **väga range** failide õiguste suhtes. Vale õigustega faile ei kasutata:

```bash
# Seadista õiged õigused
chmod 700 ~/.ssh                    # Ainult sina saad kataloogi kasutada
chmod 600 ~/.ssh/id_ed25519         # Ainult sina saad privaatvõtit lugeda
chmod 644 ~/.ssh/id_ed25519.pub     # Avalik võti võib olla loetav

# Kontrolli õigusi
ls -la ~/.ssh
```

**Oodatav väljund:**
```
drwx------  2 janek janek 4096 nov 14 10:00 .
drwxr-xr-x 25 janek janek 4096 nov 14 09:55 ..
-rw-------  1 janek janek  411 nov 14 10:00 id_ed25519
-rw-r--r--  1 janek janek  103 nov 14 10:00 id_ed25519.pub
```

---

### 2.4. Avaliku Võtme Vaatamine

```bash
# Kuva avalik võti
cat ~/.ssh/id_ed25519.pub
```

**Näide väljund:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMx1yP8hFkxQGP+B5xKvVmMN8rZ9WqF3bLkPx5x8vZR1 janek@zorin-laptop
```

**Struktuuri selgitus:**
```
ssh-ed25519                          <- Algoritm
AAAAC3Nza...x8vZR1                  <- Avalik võti (base64)
janek@zorin-laptop                  <- Kommentaar (identifikatsiooni jaoks)
```

---

## 3. VPS-iga Ühenduse Loomine

### 3.1. Hostingeri VPS Juurdepääsu Info

Kui lõid Hostingeri VPS-i, said emaili või kontrollpaneelist järgmise info:

```
IP aadress:    123.456.789.012
Kasutaja:      root
Parool:        VeryStr0ng!P@ssw0rd
SSH Port:      22 (vaikimisi)
```

**OLULINE:** Esimese sisselogimise ajal kasutame parooli, seejärel seadistame SSH võtmed.

---

### 3.2. Esimene Ühendus Parooliga

#### 3.2.1. Põhikäsk

```bash
# Asenda IP aadress oma VPS-i IP-ga
ssh root@123.456.789.012
```

**Kui see on esimene kord:**

```
The authenticity of host '123.456.789.012 (123.456.789.012)' can't be established.
ED25519 key fingerprint is SHA256:abcd1234efgh5678ijkl9012mnop3456qrst7890.
This key fingerprint is SHA256:abcd1234efgh5678ijkl9012mnop3456qrst7890.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

👉 **Kirjuta `yes`** ja vajuta ENTER

```
Warning: Permanently added '123.456.789.012' (ED25519) to the list of known hosts.
root@123.456.789.012's password:
```

👉 **Sisesta Hostingerilt saadud parool**

**Edukas sisselogimine:**
```
Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.8.0-45-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

Last login: Thu Nov 14 08:30:15 2024 from 192.168.1.100
root@vps-123456:~#
```

✅ **Oled nüüd VPS-is!**

---

### 3.3. SSH Avaliku Võtme Kopeerimine VPS-ile

Nüüd kopeerime oma avaliku võtme serverisse, et tulevikus saaksime sisse logida ilma paroolita.

#### Meetod 1: ssh-copy-id (KÕIGE LIHTSAM)

**Zorin OS-is (oma laptopil):**

```bash
# Kopeeri avalik võti serverisse
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@123.456.789.012

# Selgitus:
# -i          : Määra avaliku võtme fail
# root@IP     : Kasutaja ja serveri IP
```

**Dialoog:**
```
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/janek/.ssh/id_ed25519.pub"
root@123.456.789.012's password:
```
👉 **Sisesta VPS parool**

**Väljund:**
```
Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@123.456.789.012'"
and check to make sure that only the key(s) you wanted were added.
```

---

#### Meetod 2: Manuaalne (kui ssh-copy-id ei tööta)

**Samm 1:** Kopeeri avalik võti lõikelauale:

```bash
cat ~/.ssh/id_ed25519.pub
# Kopeeri väljund (Ctrl+Shift+C)
```

**Samm 2:** Logi VPS-i sisse:

```bash
ssh root@123.456.789.012
```

**Samm 3:** VPS-is loo SSH kataloog ja lisa võti:

```bash
# Loo kataloog, kui seda ei ole
mkdir -p ~/.ssh

# Loo fail authorized_keys ja kleebi sinna avalik võti
nano ~/.ssh/authorized_keys
# Kleebi võti (Ctrl+Shift+V)
# Salvesta (Ctrl+O, Enter) ja välju (Ctrl+X)

# Seadista õiged õigused
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

---

### 3.4. Võtmepaariga Sisselogimine

Nüüd proovi uuesti sisse logida:

```bash
# Logi välja VPS-ist (kui oled sees)
exit

# Logi uuesti sisse
ssh root@123.456.789.012
```

**Kui passphrase on seatud:**
```
Enter passphrase for key '/home/janek/.ssh/id_ed25519':
```
👉 **Sisesta oma privaatvõtme parool** (see, mille sa võtme loomisel seadsid)

**Edu!** Sa pääsed sisse ilma VPS parooli sisestamata.

---

### 3.5. SSH Konfiguratsiooni Fail (mugavus)

Et mitte pidevalt IP aadressi tippida, loo SSH konfiguratsioonifail:

**Zorin OS-is:**

```bash
# Loo või redigeeri SSH config faili
nano ~/.ssh/config
```

**Lisa järgmine sisu:**

```
# Hostinger VPS
Host hostinger-vps
    HostName 123.456.789.012
    User root
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Selgitus:
# Host           : Alias (lühinimi)
# HostName       : VPS IP aadress
# User           : Kasutajanimi
# Port           : SSH port
# IdentityFile   : Privaatvõtme asukoht
# ServerAlive*   : Hoia ühendus elus (ei aegu timeout)
```

**Salvesta** (Ctrl+O, Enter) ja **välju** (Ctrl+X)

**Seadista õigused:**

```bash
chmod 600 ~/.ssh/config
```

**Nüüd saad lihtsalt:**

```bash
ssh hostinger-vps
```

Palju lihtsam! 🎉

---

## 4. Esimesed Sammud VPS-is

### 4.1. Orienteerumine Süsteemis

```bash
# Kus sa oled?
pwd
# Väljund: /root

# Mis on see operatsioonisüsteem?
cat /etc/os-release
# Väljund:
# PRETTY_NAME="Ubuntu 24.04 LTS"
# NAME="Ubuntu"
# VERSION_ID="24.04"
# VERSION="24.04 (Noble Numbat)"
# ...

# Kui palju mälu on?
free -h
# Väljund:
#                total        used        free      shared  buff/cache   available
# Mem:           7.7Gi       1.2Gi       5.8Gi        12Mi       0.7Gi       6.3Gi
# Swap:             0B          0B          0B

# Kui palju kettaruumi?
df -h
# Väljund:
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/vda1        97G  5.2G   87G   6% /
# ...

# CPU info
lscpu | grep "Model name"
# Väljund:
# Model name:  Intel(R) Xeon(R) CPU ...
```

---

### 4.2. Süsteemi Uuendamine (ESMANE)

**Alati esimene asi uuel serveril:**

```bash
# Uuenda pakettide nimekirja
apt update

# Uuenda kõik paketid
apt upgrade -y

# Eemalda mittevajalikud paketid
apt autoremove -y

# Selgitus:
# apt update     : Uuenda pakettide nimekirja (ei paigalda midagi)
# apt upgrade -y : Paigalda uuendused (-y = automaatselt "jah")
# apt autoremove : Eemalda vanad, mittevajalikud paketid
```

**Väljund (näide):**
```
Hit:1 http://archive.ubuntu.com/ubuntu noble InRelease
Get:2 http://archive.ubuntu.com/ubuntu noble-updates InRelease [126 kB]
Get:3 http://security.ubuntu.com/ubuntu noble-security InRelease [126 kB]
...
Reading package lists... Done
Building dependency tree... Done
...
The following packages will be upgraded:
  libssl3 openssl curl ...
15 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
...
```

**Kui kernel uuendati, taaskäivita:**

```bash
# Kontrolli, kas taaskäivitus on vajalik
ls /var/run/reboot-required
# Kui see fail eksisteerib, taaskäivita:

reboot
```

Ühendus katkeb. Oota 1-2 minutit ja logi uuesti sisse:

```bash
ssh hostinger-vps
```

---

### 4.3. Ajavööndi Seadistamine

Vaikimisi on server UTC ajavööndis. Seadistame Eesti aja:

```bash
# Kontrolli praegust aega
timedatectl

# Väljund:
#                Local time: Thu 2024-11-14 08:45:32 UTC
#            Universal time: Thu 2024-11-14 08:45:32 UTC
#                  RTC time: Thu 2024-11-14 08:45:32
#                 Time zone: UTC (UTC, +0000)

# Seadista Eesti ajavöönd
timedatectl set-timezone Europe/Tallinn

# Kontrolli uuesti
timedatectl

# Väljund:
#                Local time: Thu 2024-11-14 10:45:45 EET
#            Universal time: Thu 2024-11-14 08:45:45 UTC
#                  RTC time: Thu 2024-11-14 08:45:45
#                 Time zone: Europe/Tallinn (EET, +0200)
```

---

### 4.4. Hostname Seadistamine

Muudame serveri nime millekski äratuntavaks:

```bash
# Kontrolli praegust hostname'i
hostname
# Väljund: vps-123456 (või midagi sarnast)

# Seadista uus hostname
hostnamectl set-hostname hostinger-ubuntu

# Redigeeri hosts faili
nano /etc/hosts
```

**Lisa või muuda:**
```
127.0.0.1       localhost
127.0.1.1       hostinger-ubuntu

# IPv6
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
```

**Salvesta** (Ctrl+O, Enter) ja **välju** (Ctrl+X)

**Kontrolli:**
```bash
hostname
# Väljund: hostinger-ubuntu
```

---

## 5. Turvalisuse Seadistamine

### 5.1. UFW Firewall Seadistamine

**UFW (Uncomplicated Firewall)** on lihtne firewall Ubuntu jaoks.

#### 5.1.1. UFW Paigaldamine ja Lubamine

```bash
# UFW on tavaliselt juba paigaldatud, kontrolli:
ufw status
# Väljund: Status: inactive

# Seadista vaikimisi reeglid
ufw default deny incoming    # Blokeeri kõik sissetulevad ühendused
ufw default allow outgoing   # Luba kõik väljaminevad ühendused

# Luba SSH (ENNE UFW lubamist!)
ufw allow 22/tcp comment 'SSH'

# Luba HTTP ja HTTPS (veebiserver jaoks)
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Luba K3s (Kubernetes) pordid
ufw allow 6443/tcp comment 'K3s API'
ufw allow 10250/tcp comment 'K3s Kubelet'

# Luba PostgreSQL (kui väline DB variant)
# ufw allow 5432/tcp comment 'PostgreSQL'

# Luba UFW
ufw enable

# Hoiatus:
# Command may disrupt existing ssh connections. Proceed with operation (y|n)?
```
👉 **Kirjuta `y`** ja vajuta ENTER

**Kontrolli:**
```bash
ufw status verbose
```

**Väljund:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere                   # SSH
80/tcp                     ALLOW IN    Anywhere                   # HTTP
443/tcp                    ALLOW IN    Anywhere                   # HTTPS
6443/tcp                   ALLOW IN    Anywhere                   # K3s API
10250/tcp                  ALLOW IN    Anywhere                   # K3s Kubelet
22/tcp (v6)                ALLOW IN    Anywhere (v6)              # SSH
80/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTP
443/tcp (v6)                ALLOW IN    Anywhere (v6)              # HTTPS
6443/tcp (v6)              ALLOW IN    Anywhere (v6)              # K3s API
10250/tcp (v6)             ALLOW IN    Anywhere (v6)              # K3s Kubelet
```

---

### 5.2. Fail2ban Seadistamine

**Fail2ban** jälgib logifaile ja blokeerib automaatselt IP-aadressid, mis proovivad ründeid (nt brute-force).

#### 5.2.1. Fail2ban Paigaldamine

```bash
# Paigalda fail2ban
apt install fail2ban -y

# Kontrolli olekut
systemctl status fail2ban
```

**Väljund:**
```
● fail2ban.service - Fail2Ban Service
     Loaded: loaded (/lib/systemd/system/fail2ban.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2024-11-14 10:50:12 EET; 5s ago
       Docs: man:fail2ban(1)
   Main PID: 12345 (fail2ban-server)
      Tasks: 5 (limit: 9448)
     Memory: 12.5M
        CPU: 123ms
     CGroup: /system.slice/fail2ban.service
             └─12345 /usr/bin/python3 /usr/bin/fail2ban-server -xf start
```

---

#### 5.2.2. Fail2ban SSH Kaitse Konfigureerimine

```bash
# Loo kohalik konfiguratsioonifail
nano /etc/fail2ban/jail.local
```

**Lisa järgmine sisu:**

```ini
[DEFAULT]
# Banni kestus: 1 tund (3600 sekundit)
bantime = 3600

# Vaatluse aeg: 10 minutit (600 sekundit)
findtime = 600

# Maksimaalne katsete arv
maxretry = 5

# Ignoreeri oma IP (asenda oma koduse IP-ga)
# ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

**Salvesta** (Ctrl+O, Enter) ja **välju** (Ctrl+X)

**Taaskäivita fail2ban:**

```bash
systemctl restart fail2ban

# Kontrolli olekut
fail2ban-client status sshd
```

**Väljund:**
```
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/auth.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

---

### 5.3. SSH Serveri Turvalisuse Suurendamine

#### 5.3.1. SSH Konfiguratsiooni Redigeerimine

```bash
# Tee varukoopiakonfiguratsioonifailist
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Redigeeri konfiguratsioonifaili
nano /etc/ssh/sshd_config
```

**Muuda või lisa järgmised read:**

```bash
# Port (muuda mitte-standardseks, nt 2222)
# HOIATUS: Ära muuda veel, kuni ei ole veendunud, et võtmed töötavad!
# Port 2222

# Keela root login parooliga (kui sa lõid eraldi kasutaja)
PermitRootLogin prohibit-password

# Keela parooliga sisselogimine (ainult SSH võtmed)
# HOIATUS: Luba see ainult siis, kui oled veendunud, et võtmed töötavad!
# PasswordAuthentication no

# Luba public key authentication
PubkeyAuthentication yes

# Keela tühi parool
PermitEmptyPasswords no

# Keela X11 forwarding (kui ei vaja)
X11Forwarding no

# Määra login grace time (aeg autentimiseks)
LoginGraceTime 60

# Maksimaalne autentimise katseid
MaxAuthTries 3

# Maksimaalne sessioonide arv
MaxSessions 10
```

**Salvesta** (Ctrl+O, Enter) ja **välju** (Ctrl+X)

---

#### 5.3.2. SSH Teenuse Taaskäivitus

```bash
# Kontrolli konfiguratsiooni süntaksit
sshd -t

# Kui ei ole vigu, taaskäivita SSH
systemctl restart sshd

# Kontrolli olekut
systemctl status sshd
```

**OLULINE:** Ära sulge praegust SSH sessiooni! Ava uus terminal ja testi, kas saad sisse logida:

```bash
# Uues terminalis
ssh hostinger-vps
```

Kui kõik töötab, oled turvaline. ✅

---

## 6. Kasutajate ja Õiguste Haldamine

### 6.1. Miks Mitte Kasutada Root'i Igapäevaselt?

**Analoogia:** Root kui Administraatori Võtmed

- **Root kasutaja** on nagu kõigi ukste peamised võtmed
- Kui midagi läheb valesti (viga käsus, pahavara), võid **kogu süsteemi hävitada**
- **Hea tava:** Kasuta tavakasutajat + sudo (ajutised administraatori õigused)

---

### 6.2. Uue Sudo Kasutaja Loomine

```bash
# Loo uus kasutaja (asenda "janek" oma nimega)
adduser janek

# Dialoog:
# Adding user `janek' ...
# Adding new group `janek' (1001) ...
# Adding new user `janek' (1001) with group `janek' ...
# Creating home directory `/home/janek' ...
# Copying files from `/etc/skel' ...
# New password:
```
👉 **Sisesta tugev parool**

```
# Retype new password:
```
👉 **Korda parooli**

```
# Full Name []:
```
👉 **Sisesta oma nimi** või vajuta lihtsalt ENTER

```
# Room Number []:
# Work Phone []:
# Home Phone []:
# Other []:
# Is the information correct? [Y/n]
```
👉 **Vajuta ENTER** (Y)

---

### 6.3. Lisa Kasutaja Sudo Gruppi

```bash
# Lisa kasutaja sudo gruppi
usermod -aG sudo janek

# Kontrolli gruppe
groups janek
# Väljund: janek : janek sudo
```

---

### 6.4. Kopeeri SSH Võtmed Uuele Kasutajale

```bash
# Kopeeri SSH kataloog root-lt uuele kasutajale
cp -r /root/.ssh /home/janek/

# Muuda omanikuks janek
chown -R janek:janek /home/janek/.ssh

# Kontrolli õigusi
ls -la /home/janek/.ssh
```

---

### 6.5. Testi Uut Kasutajat

**Uues terminalis (Zorin OS-is):**

```bash
# Muuda SSH config faili
nano ~/.ssh/config
```

**Muuda User reale:**
```
Host hostinger-vps
    HostName 123.456.789.012
    User janek              # Muutsime root -> janek
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

**Logi sisse:**
```bash
ssh hostinger-vps
```

**Testi sudo õigusi:**
```bash
sudo apt update
# [sudo] password for janek:
```
👉 **Sisesta janek'i parool**

Kui kõik töötab, oled edukas! ✅

---

### 6.6. Keela Root Sisselogimine (valikuline, aga soovitav)

**Kui oled veendunud, et uus kasutaja töötab:**

```bash
# Redigeeri SSH konfiguratsioonifaili
sudo nano /etc/ssh/sshd_config
```

**Muuda:**
```
PermitRootLogin no
```

**Taaskäivita SSH:**
```bash
sudo systemctl restart sshd
```

Nüüd ei saa root'i kasutajana enam sisse logida. Ainult läbi janek + sudo. 🔒

---

## 7. Põhiliste Tööriistade Paigaldamine

### 7.1. Hädavajalikud Tööriistad

```bash
# Uuenda paketinimekirja
sudo apt update

# Paigalda põhitööriistad
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    net-tools \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Selgitus:
# curl/wget           : HTTP kliendid failide allalaadimiseks
# git                 : Versioonihaldus
# vim/nano            : Tekstiredaktorid
# htop                : Interaktiivne protsessimonitor
# net-tools           : Võrgutööriistad (netstat jne)
# build-essential     : Kompilaatori tööriistad (gcc, make jne)
# software-prop*      : PPA-de haldamiseks
# apt-transport-https : HTTPS toe lisamine apt-le
# ca-certificates     : SSL sertifikaadid
# gnupg               : GPG võtmete haldus
# lsb-release         : Linux Standard Base info
```

---

### 7.2. Kasulikud Võrgudiagnostika Tööriistad

```bash
sudo apt install -y \
    dnsutils \
    traceroute \
    tcpdump \
    nmap \
    iotop

# Selgitus:
# dnsutils     : DNS tööriistad (dig, nslookup)
# traceroute   : Marsruudi jälgimine
# tcpdump      : Võrguliikluse jälgimine
# nmap         : Võrgu skanneerimine
# iotop        : Ketta I/O monitooring
```

---

### 7.3. Tööriistade Testimine

```bash
# curl test
curl -I https://google.com
# Peaks tagastama HTTP headeri'd

# git test
git --version
# Väljund: git version 2.43.0

# htop
htop
# Vajuta 'q' väljumiseks

# Võrgu test
ping -c 3 google.com
# Peaks pinge'd edukalt minema

# DNS test
dig google.com
# Peaks DNS vastuse tagastama
```

---

## 8. Harjutused

### Harjutus 2.1: SSH Võtmete Loomine ja Seadistamine

**Eesmärk:** Luua SSH võtmepaar ja seadistada VPS juurdepääs

**Sammud:**

1. Genereeri Ed25519 SSH võtmepaar
2. Kontrolli loodud faile
3. Kontrolli failide õigusi
4. Kuva avalik võti

**Oodatav tulemus:**
```bash
ls -la ~/.ssh/
# Peaksid nägema:
# id_ed25519
# id_ed25519.pub
```

---

### Harjutus 2.2: VPS-iga Ühenduse Loomine

**Eesmärk:** Ühenduda VPS-iga SSH võtmete abil

**Sammud:**

1. Kopeeri avalik võti VPS-i (`ssh-copy-id`)
2. Logi sisse ilma paroolita
3. Loo SSH config fail
4. Testi aliast (`ssh hostinger-vps`)

**Kontrolli:**
- Pääsed sisse ainult passphrase'iga (privaatvõtme parool)
- Ei küsi VPS parooli

---

### Harjutus 2.3: Turvalisuse Seadistamine

**Eesmärk:** Seadistada firewall ja fail2ban

**Sammud:**

1. Seadista UFW:
   - Blokeeri kõik sissetulevad
   - Luba SSH (22), HTTP (80), HTTPS (443)
   - Luba UFW

2. Paigalda ja seadista fail2ban

3. Kontrolli:
```bash
sudo ufw status
sudo fail2ban-client status sshd
```

---

### Harjutus 2.4: Sudo Kasutaja Loomine

**Eesmärk:** Luua tavakasutaja sudo õigustega

**Sammud:**

1. Loo uus kasutaja `janek`
2. Lisa sudo gruppi
3. Kopeeri SSH võtmed
4. Testi sisselogimist
5. Testi sudo õigusi

**Kontrolli:**
```bash
groups janek
sudo apt update
```

---

### Harjutus 2.5: Tööriistade Paigaldamine ja Testimine

**Eesmärk:** Paigaldada ja testida põhilisi tööriistu

**Sammud:**

1. Paigalda curl, wget, git, htop
2. Testi igat tööriista
3. Paigalda võrgudiagnostika tööriistad
4. Testi ping, dig

**Oodatav tulemus:** Kõik tööriistad töötavad

---

## 9. Kontrolliküsimused

### Teoreetilised Küsimused

1. **Mis vahe on SSH parooliga ja SSH võtmepaariga autentimisel?**
   <details>
   <summary>Vastus</summary>
   Parooliga autentimine saadab parooli üle võrgu (krüpteeritult), aga paroolid võib ära arvata brute-force ründega. SSH võtmepaar kasutab krüptograafilist võtmepaari - privaatvõti (sina) ja avalik võti (server). Võtmepaar on praktiliselt võimatu ära arvata ja parem turvalisus.
   </details>

2. **Miks on oluline hoida privaatvõtit turvaliselt?**
   <details>
   <summary>Vastus</summary>
   Privaatvõti on nagu sinu identiteet. Kui keegi saab su privaatvõtme kätte, võib ta sinu nime all serverisse siseneda. Privaatvõti peaks ALATI olema kaitstud passphrase-iga ja mitte kunagi jagatud.
   </details>

3. **Mis on UFW ja miks me seda kasutame?**
   <details>
   <summary>Vastus</summary>
   UFW (Uncomplicated Firewall) on firewall Ubuntu jaoks, mis blokeerib soovimatut võrguliiklust. Vaikimisi blokeerime kõik sissetulevad ühendused ja lubame ainult vajalikud pordid (SSH, HTTP, HTTPS). See kaitseb serveri rünnete eest.
   </details>

4. **Mis on fail2ban ja kuidas see töötab?**
   <details>
   <summary>Vastus</summary>
   Fail2ban jälgib logifaile (nt /var/log/auth.log) ja kui keegi proovib liiga palju kordi vale parooliga sisse logida, blokeerib fail2ban automaatselt selle IP aadressi. See kaitseb brute-force rünnete eest.
   </details>

5. **Miks on parem kasutada tavakasutajat + sudo, mitte root'i?**
   <details>
   <summary>Vastus</summary>
   Root'il on piiramatu võim süsteemi üle. Üks vale käsk võib kogu süsteemi hävitada. Tavakasutaja + sudo nõuab parooli iga administraatori käsu jaoks, mis annab hetke mõelda "kas ma tõesti tahan seda teha?" ja vähendab õnnetuste riski.
   </details>

---

### Praktilised Küsimused

6. **Milline käsk genereerib Ed25519 SSH võtmepaari?**
   <details>
   <summary>Vastus</summary>
   ```bash
   ssh-keygen -t ed25519 -C "kommentaar"
   ```
   </details>

7. **Kuidas kopeerida SSH avalik võti serverisse?**
   <details>
   <summary>Vastus</summary>
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub kasutaja@server-ip
   ```
   </details>

8. **Millised õigused peavad olema ~/.ssh kataloogil ja privaatvõtmel?**
   <details>
   <summary>Vastus</summary>
   ```bash
   chmod 700 ~/.ssh           # Kataloog
   chmod 600 ~/.ssh/id_ed25519  # Privaatvõti
   ```
   </details>

9. **Kuidas lubada pordi 8080 UFW-s?**
   <details>
   <summary>Vastus</summary>
   ```bash
   sudo ufw allow 8080/tcp comment 'My Application'
   ```
   </details>

10. **Kuidas kontrollida fail2ban staatust SSH jaoks?**
    <details>
    <summary>Vastus</summary>
    ```bash
    sudo fail2ban-client status sshd
    ```
    </details>

11. **Kuidas lisada kasutaja sudo gruppi?**
    <details>
    <summary>Vastus</summary>
    ```bash
    sudo usermod -aG sudo kasutajanimi
    ```
    </details>

12. **Kuidas testida SSH konfiguratsiooni süntaksit enne teenuse taaskäivitust?**
    <details>
    <summary>Vastus</summary>
    ```bash
    sudo sshd -t
    ```
    </details>

---

## 10. Lisamaterjalid

### 📚 Soovitatud Lugemine

#### SSH ja Turvalisus
- [SSH Academy](https://www.ssh.com/academy/ssh) - Põhjalik SSH õpetus
- [DigitalOcean: SSH Essentials](https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys)
- [Ubuntu Server Security](https://ubuntu.com/server/docs/security-introduction)

#### Firewall
- [UFW Essentials](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands)
- [Ubuntu UFW Documentation](https://help.ubuntu.com/community/UFW)

#### Fail2ban
- [Fail2ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [How Fail2ban Works](https://www.digitalocean.com/community/tutorials/how-fail2ban-works-to-protect-services-on-a-linux-server)

---

### 🛠️ Kasulikud Tööriistad

#### SSH Haldus
- **ssh-audit** - SSH serveri konfiguratsioon auditeerimine
  ```bash
  sudo apt install ssh-audit
  ssh-audit localhost
  ```

#### Monitoring
- **htop** - Interaktiivne protsessimonitor
- **iotop** - Ketta I/O monitooring
- **nethogs** - Võrguliikluse monitooring protsessi kohta

---

### 🎥 Video Ressursid

- **LearnLinuxTV** (YouTube) - Linux server administration
- **NetworkChuck** (YouTube) - SSH ja network security
- **Christian Lempa** (YouTube) - Server management

---

### 🔐 Turvalisuse Checklisti

```
☐ SSH võtmed loodud ja paigaldatud
☐ SSH parool keelatud (PasswordAuthentication no)
☐ Root login keelatud või piiratud (PermitRootLogin no/prohibit-password)
☐ UFW firewall seadistatud ja lubatud
☐ Fail2ban paigaldatud ja seadistatud
☐ Sudo kasutaja loodud
☐ Süsteem uuendatud (apt update && apt upgrade)
☐ Ajavöönd seadistatud
☐ Hostname seadistatud
☐ Põhitööriistad paigaldatud
```

---

## Kokkuvõte

Selles peatükis said:

✅ **Õppisid SSH põhimõtteid** ja turvalisust
✅ **Lõid SSH võtmepaari** (Ed25519)
✅ **Seadistasid VPS-iga turvalise ühenduse**
✅ **Seadistasid turvalisuse**:
   - UFW firewall
   - Fail2ban
   - SSH turvalisus
✅ **Lõid sudo kasutaja** turvalisuse parandamiseks
✅ **Paigaldasid põhilised tööriistad**

---

## Järgmine Peatükk

**Peatükk 3: PostgreSQL Paigaldamine - MÕLEMAD VARIANDID**

Järgmises peatükis:
- Docker kontseptsioon ja paigaldamine
- PostgreSQL Dockeris (primaarne)
- PostgreSQL VPS-ile (alternatiivne)
- Variantide võrdlus
- Andmebaasi algne seadistamine
- Esimesed SQL päringud

---

## Troubleshooting (Levinud Probleemid)

### Probleem 1: "Permission denied (publickey)"

**Põhjus:** Avalik võti ei ole serveris või privaatvõti ei ole õigete õigustega.

**Lahendus:**
```bash
# Kontrolli, kas avalik võti on serveris
ssh kasutaja@server "cat ~/.ssh/authorized_keys"

# Kontrolli privaatvõtme õigusi
ls -la ~/.ssh/id_ed25519
# Peab olema: -rw------- (600)

# Paranda õigused
chmod 600 ~/.ssh/id_ed25519
```

---

### Probleem 2: SSH ühendus aegub (timeout)

**Põhjus:** Firewall blokeerib SSH porti või vale IP aadress.

**Lahendus:**
```bash
# Kontrolli UFW-d serveris
sudo ufw status | grep 22

# Kui blokeeritud, luba
sudo ufw allow 22/tcp

# Kontrolli SSH teenuse staatust
sudo systemctl status sshd
```

---

### Probleem 3: "sudo: command not found"

**Põhjus:** Kasutaja ei ole sudo grupis.

**Lahendus:**
```bash
# Logi root'i alla
su - root

# Lisa kasutaja sudo gruppi
usermod -aG sudo kasutajanimi

# Logi kasutaja uuesti sisse
exit
su - kasutajanimi

# Kontrolli
groups
# Peab sisaldama "sudo"
```

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-14
**Järgmine uuendus:** Peatükk 3 lisamine
