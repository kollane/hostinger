# Õpilase Juhend - DevOps Laborikeskkond

## Tere tulemast! 👋

Oled saanud juurdepääsu isoleeritud DevOps laborikeskkonnale, kus saad läbida 10 praktilist DevOps labi. Iga õpilane töötab omas konteineris, millel on oma ressursid ja keskkond.

---

## Sinu Keskkonna Ülevaade

**Sinu konteiner:**
- Operatsioonisüsteem: Ubuntu 24.04 LTS
- RAM: 2.5GB
- CPU: 1 core (shared)
- Disk: 20GB
- Network: Privaatne IP lxdbr0 võrgus

**Installeeritud tarkvara:**
- Docker Engine 29.0.4
- Docker Compose v2.40.3
- Git, curl, wget, vim, nano
- Kõik vajalikud tööriistad laboriteks

**Labori failid:**
```
/home/labuser/labs/
├── 01-docker-lab/              (4h)
├── 02-docker-compose-lab/      (5.25h)
├── 03-kubernetes-basics-lab/   (5h)
├── 04-kubernetes-advanced-lab/ (5h)
├── 05-cicd-lab/                (4h)
├── 06-monitoring-logging-lab/  (4h)
├── 07-security-secrets-lab/    (5h)
├── 08-gitops-argocd-lab/       (5h)
├── 09-backup-disaster-recovery-lab/ (5h)
├── 10-terraform-iac-lab/       (5h)
└── apps/                       (3 microservice rakendust)
```

---

## Sisselogimine

### SSH ühendus

**Sinu andmed on saadud e-mailiga või õppejõult.**

**Näide (asenda oma andmetega):**

```bash
# Student 1
ssh labuser@<vps-ip-aadress> -p 2201
Password: student1

# Student 2
ssh labuser@<vps-ip-aadress> -p 2202
Password: student2

# Student 3
ssh labuser@<vps-ip-aadress> -p 2203
Password: student3
```

**Windows kasutajad:**
- Kasuta PuTTY või Windows Terminal
- Host: `<vps-ip-aadress>`
- Port: `2201` (või 2202, 2203)
- Username: `labuser`
- Password: `<sinu-parool>`

**Mac/Linux kasutajad:**
- Ava Terminal
- Kopeeri SSH käsk ülalt
- Sisesta parool

### Esimene sisselogimine

Pärast sisselogimist näed:

```
Welcome to Ubuntu 24.04.1 LTS (GNU/Linux 6.8.0-87-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

Last login: Mon Nov 25 18:30:00 2025 from 10.67.86.1

labuser@devops-studentX:~$
```

---

## Kasulikud Käsud

### Ressursside kontrollimine

**Kontrolli oma ressursse:**
```bash
check-resources
```

See näitab:
- RAM kasutust (kui palju kasutad 2.5GB-st)
- Disk kasutust (kui palju kasutad 20GB-st)
- Docker konteinereid ja pilte

**Näide väljund:**
```
=== RAM ===
               total        used        free
Mem:           2.5Gi       450Mi       2.0Gi

=== DISK ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G  3.5G   15G  19% /

=== DOCKER ===
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS
(tühi, kui pole konteinereid)
```

### Docker puhastamine

Kui disk täis:
```bash
docker-cleanup
```

See kustutab:
- Kõik peatatud konteinerid
- Kasutamata Docker image'id
- Kasutamata volume'd
- Docker build cache

**⚠️ Hoiatus:** See kustutab ka sinu laborite Docker ressursid. Kasuta ainult siis, kui oled kindel!

### Manuaalne puhastamine

```bash
# Vaata, mis võtab ruumi
docker system df

# Kustuta konkreetne konteiner
docker rm <container-id>

# Kustuta konkreetne image
docker rmi <image-name>

# Kustuta volume
docker volume rm <volume-name>
```

---

## Laboritega Alustamine

### Lab 1: Docker Põhitõed (4h)

**1. Mine lab'i kataloogi:**
```bash
cd ~/labs/01-docker-lab/
```

**2. Loe README:**
```bash
cat README.md
# või
less README.md  # (Väljumine: q)
```

**3. Alusta esimesest ülesandest:**
```bash
cd exercises/
ls
cat 01a-single-container-nodejs.md
```

**4. Järgi ülesande juhiseid:**

Näiteks:
```bash
# Ehita Docker pilt
cd ~/labs/apps/backend-nodejs/
docker build -t user-service:1.0 .

# Vaata, kas pilt tekkis
docker images

# Käivita konteiner
docker run -d --name user-service -p 3000:3000 user-service:1.0

# Kontrolli, kas töötab
docker ps
curl http://localhost:3000/health
```

**5. Kontrolli lahendust:**
```bash
cd ~/labs/01-docker-lab/solutions/
cat 01a-single-container-nodejs.md
```

### Lab 2: Docker Compose (5.25h)

```bash
cd ~/labs/02-docker-compose-lab/
cat README.md
cd exercises/
```

Lab 2 õpetab:
- Docker Compose põhitõed
- Multi-container rakendused
- Production vs Development seadistused
- Nginx reverse proxy

### Järgmised labid (Labs 3-10)

Labid peab tegema **järjekorras** (1 → 2 → 3 ... → 10), sest igaüks tugineb eelmistele!

---

## Rakenduste Testimine

Labide käigus käivitad kolm microservice'i:

### 1. User Service (Node.js + PostgreSQL)

```bash
# Käivita
cd ~/labs/apps/backend-nodejs/
docker-compose up -d

# Kontrolli
curl http://localhost:3000/health
```

**Väline juurdepääs (brauserist):**
- Student 1: `http://<vps-ip>:3000`
- Student 2: `http://<vps-ip>:3100`
- Student 3: `http://<vps-ip>:3200`

### 2. Todo Service (Java Spring Boot + PostgreSQL)

```bash
# Käivita
cd ~/labs/apps/backend-java-spring/
docker-compose up -d

# Kontrolli
curl http://localhost:8081/health
```

**Väline juurdepääs:**
- Student 1: `http://<vps-ip>:8081`
- Student 2: `http://<vps-ip>:8181`
- Student 3: `http://<vps-ip>:8281`

### 3. Frontend (Web UI)

```bash
# Käivita
cd ~/labs/apps/frontend/
docker-compose up -d

# Kontrolli
curl http://localhost:8080
```

**Väline juurdepääs (ava brauseris):**
- Student 1: `http://<vps-ip>:8080`
- Student 2: `http://<vps-ip>:8180`
- Student 3: `http://<vps-ip>:8280`

### API testimine (curl)

**Registreeri kasutaja:**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"test123"}'
```

**Logi sisse (saad JWT token):**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

**Kasuta token'it:**
```bash
TOKEN="<jwt-token-siia>"
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN"
```

---

## Probleemide Lahendamine

### Docker käsud ei tööta

**Probleem:** `permission denied while trying to connect to the Docker daemon socket`

**Lahendus:**
```bash
# Kontrolli, kas oled docker grupis
groups

# Kui ei ole, siis logi välja ja uuesti sisse
exit
ssh labuser@<vps-ip> -p <sinu-port>
```

### Konteinerid ei käivitu

**Probleem:** Docker konteinerid crashivad või ei käivitu

**Lahendus 1:** Kontrolli logisid
```bash
docker logs <container-name>
```

**Lahendus 2:** Kontrolli, kas port on juba kasutuses
```bash
netstat -tuln | grep <port-number>

# Näiteks port 3000
netstat -tuln | grep 3000
```

**Lahendus 3:** Peata konfliktivad konteinerid
```bash
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
```

### RAM otsa

**Probleem:** "Out of memory" vead

**Lahendus 1:** Kontrolli kasutust
```bash
check-resources
```

**Lahendus 2:** Peata mittevajalikud konteinerid
```bash
# Vaata, mis töötab
docker ps

# Peata konteiner
docker stop <container-name>

# Või kõik
docker stop $(docker ps -aq)
```

**Lahendus 3:** Puhasta
```bash
docker-cleanup
```

### Disk otsa

**Probleem:** "No space left on device"

**Lahendus 1:** Kontrolli kasutust
```bash
df -h
docker system df
```

**Lahendus 2:** Puhasta Docker
```bash
docker-cleanup
```

**Lahendus 3:** Kustuta vanad labid
```bash
# Näiteks Lab 1 failid (kui Lab 2 valmis)
cd ~/labs/01-docker-lab/
./reset.sh
```

### Port forwarding ei tööta

**Probleem:** Ei saa brauserist ligi rakendusele

**Kontrolli 1:** Kas teenus töötab konteineris?
```bash
curl http://localhost:8080
```

**Kontrolli 2:** Kas õige port?
- Student 1: 8080, 3000, 8081
- Student 2: 8180, 3100, 8181
- Student 3: 8280, 3200, 8281

**Kontrolli 3:** Kas kasutad õiget IP?
```bash
# Konteineris kasuta:
curl http://localhost:8080

# Väljaspool (brauseris):
http://<vps-ip>:8080  # student1
```

### Unustasid parooli?

Võta ühendust administraatoriga!

---

## Best Practices

### ✅ DO (Tee nii)

1. **Kontrolli ressursse regulaarselt:**
   ```bash
   check-resources
   ```

2. **Puhasta pärast iga labi:**
   ```bash
   cd ~/labs/0X-lab-name/
   ./reset.sh
   ```

3. **Peata konteinerid, kui ei kasuta:**
   ```bash
   docker stop $(docker ps -aq)
   ```

4. **Kasuta lahendusi, kui kinni jääd:**
   ```bash
   cd ~/labs/0X-lab-name/solutions/
   ```

5. **Tee märkmeid:**
   ```bash
   nano ~/my-notes.md
   ```

### ❌ DON'T (Ära tee nii)

1. **Ära käivita kõiki teenuseid korraga:**
   - Hoiab RAM-i täis
   - Võib süsteem kokku kukkuda

2. **Ära kustuta labori faile:**
   ```bash
   # ÄRA TEE:
   rm -rf ~/labs/
   ```

3. **Ära muuda süsteemi seadistusi:**
   - Ära muuda network seadeid
   - Ära installi uusi pakette sudo-ga (ei ole õigusi)
   - Ära muuda Docker seadeid

4. **Ära unusta puhastada:**
   - Docker täidab diski kiiresti
   - Kasuta `docker-cleanup`

5. **Ära jaga oma parooli:**
   - Iga õpilane on oma keskkonnas vastutav

---

## SSH Näpunäited

### SSH võtme kasutamine (turvalisem)

**1. Genereeri SSH võti (oma arvutis):**
```bash
ssh-keygen -t ed25519 -C "devops-lab"
```

**2. Kopeeri võti serverisse:**
```bash
ssh-copy-id -p 2201 labuser@<vps-ip>
```

**3. Logi sisse ilma paroolita:**
```bash
ssh labuser@<vps-ip> -p 2201
```

### SSH config (mugavam)

**Loo fail:** `~/.ssh/config` (oma arvutis)

```
Host devops-lab
    HostName <vps-ip>
    Port 2201
    User labuser
    IdentityFile ~/.ssh/id_ed25519
```

**Nüüd saad logida lihtsalt:**
```bash
ssh devops-lab
```

---

## Abimaterjalid

### Labori dokumentatsioon

```bash
# Põhiline README
cat ~/labs/README.md

# Lab-spetsiifiline README
cat ~/labs/01-docker-lab/README.md

# Claude'i juhised
cat ~/labs/CLAUDE.md

# Rakenduste arhitektuur
cat ~/labs/apps/ARHITEKTUUR.md
```

### Docker dokumentatsioon

```bash
# Docker käsud
docker --help
docker run --help

# Docker Compose
docker compose --help
```

### Online ressursid

- **Docker Docs:** https://docs.docker.com/
- **Docker Compose:** https://docs.docker.com/compose/
- **Ubuntu manuals:** `man docker` (sisesta konteineris)

---

## Kiirviited Käskudele

### Navigeerimine

```bash
cd ~/labs/                  # Labori kataloog
cd ~/labs/01-docker-lab/    # Lab 1
cd ~/labs/apps/             # Rakendused
ls -la                      # Vaata faile
pwd                         # Kus ma olen?
```

### Docker põhikäsud

```bash
docker ps                   # Töötavad konteinerid
docker ps -a                # Kõik konteinerid
docker images               # Kõik image'id
docker logs <name>          # Konteineri logid
docker exec -it <name> bash # Logi konteinerisse
docker stop <name>          # Peata konteiner
docker rm <name>            # Kustuta konteiner
docker rmi <image>          # Kustuta image
docker-cleanup              # Puhasta kõik (ALIAS)
```

### Docker Compose käsud

```bash
docker compose up -d        # Käivita taustal
docker compose ps           # Vaata olekut
docker compose logs -f      # Vaata logisid (live)
docker compose down         # Peata ja kustuta
docker compose restart      # Taaskäivita
```

### Ressursid

```bash
check-resources             # RAM, Disk, Docker (ALIAS)
df -h                       # Disk kasutus
free -h                     # RAM kasutus
htop                        # Live monitoring (exit: q)
```

### Failihaldus

```bash
cat file.txt                # Vaata faili
less file.txt               # Lehitse faili (exit: q)
nano file.txt               # Redigeeri faili (save: Ctrl+O, exit: Ctrl+X)
vim file.txt                # Vim redaktor (exit: :q)
cp source dest              # Kopeeri
mv source dest              # Liiguta/nimeta ümber
rm file                     # Kustuta fail
mkdir dirname               # Loo kataloog
```

---

## Sinu Juurdepääsuinfo

**Täida see informatsioon välja ja hoia turvalises kohas!**

```
VPS IP aadress:  ______________________
SSH Port:        ______________________
Username:        labuser
Password:        ______________________

Frontend URL:    http://___________:____
User API URL:    http://___________:____
Todo API URL:    http://___________:____
```

---

## Abi Saamine

**Kui probleem:**
1. Kontrolli selle juhendi "Probleemide lahendamine" sektsiooni
2. Vaata labori solutions/ kataloogi
3. Küsi õppejõult/administraatorilt

**Kui viga/bug:**
- Kirjelda probleemi täpselt
- Lisa käsk, mida käivitasid
- Lisa veateade
- Võta ekraanipilt (kui võimalik)

**Kontakt:**
- Õppejõud: [lisage kontakt siia]
- Administraator: [lisage kontakt siia]

---

## Head Õppimist! 🚀

Austa oma ressursse, puhasta regulaarselt, ja naudi DevOps õppimist!

**NB!** Sinu keskkond on jagatud ressurssidega. Ole vastutustundlik, et kõik õpilased saaksid rahulikult töötada.

---

**Viimane uuendus:** 2025-11-25
**Versioon:** 1.0
**Labori versioon:** Labs 1-10 (45h total)
