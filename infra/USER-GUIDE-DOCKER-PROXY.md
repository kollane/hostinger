# Kasutajajuhend: Docker Laborid (Proxy Keskkond)

## Tere tulemast Docker laboritesse!

Tere tulemast DevOps koolituse Docker laborite juurde! See juhend aitab sul alustada tööd oma isiklikus laborikeskkonnas, kus saad praktiseerida Docker'i ja konteinerimistehnoloogiaid.

**Mida sa siin õpid:**
- **Lab 1:** Docker põhialused - konteinerite loomine, haldamine ja mitme-sammulised ehitused (multi-stage builds)
- **Lab 2:** Docker Compose - mitme konteineri rakenduste orkestreerimist, PostgreSQL andmebaasi integreerimist

**Kuidas saada abi:**
- Loe esmalt see juhend hoolikalt läbi
- Kui jääd hätta, vaata "Probleemide Lahendamine" sektsiooni (peatükk 5)
- Küsi abi kaasõppijatelt või koolitajalt
- Ära karda eksida - vigadest õpitakse kõige rohkem!

---

## Sinu Keskkond

### Kontoinformatsioon

Iga õpilane saab oma isikliku laborikeskkonna:

- **Kasutajanimi:** `labuser`
- **Parool:** Saad koolitajalt (küsi, kui ei tea)
- **SSH Port:** Vastavalt õpilase numbrile (vaata allolevast tabelist)
- **Host IP:** Serveri IP aadress (saad koolitajalt)

### Port Mapping

Iga õpilane kasutab erinevaid porte. Leia oma õpilasenumber ja kasuta vastavaid porte:

| Õpilane | SSH Port | Frontend | User API | Todo API |
|---------|----------|----------|----------|----------|
| **Student1** | 2201 | 8080 | 3000 | 8081 |
| **Student2** | 2202 | 8180 | 3100 | 8181 |
| **Student3** | 2203 | 8280 | 3200 | 8281 |
| **Student4** | 2204 | 8380 | 3300 | 8381 |
| **Student5** | 2205 | 8480 | 3400 | 8481 |
| **Student6** | 2206 | 8580 | 3500 | 8581 |

**Näide (Student1):**
- SSH ühendus: `ssh labuser@<HOST-IP> -p 2201`
- Frontend brauseris: `http://<HOST-IP>:8080`
- User API: `http://<HOST-IP>:3000`
- Todo API: `http://<HOST-IP>:8081`

### Ressursid

Sinu laborikeskkond sisaldab:

- **RAM:** 2.5GB (piisav Docker laboriteks)
- **CPU:** 1 core
- **Tööriistad:**
  - Docker (Engine + Compose)
  - Java 21 (Spring Boot rakenduste jaoks)
  - Node.js 20 (Node.js rakenduste jaoks)
  - Git (versioonihalduks)

---

## 1. Esimene Sisselogimine

### SSH Kaudu Sisselogimine

Kasuta oma arvutis terminali (Windows: PowerShell, Mac/Linux: Terminal):

```bash
# Üldine formaat
ssh labuser@<HOST-IP> -p <SSH-PORT>

# Näide: Student1
ssh labuser@192.168.1.100 -p 2201

# Näide: Student3
ssh labuser@192.168.1.100 -p 2203

# Sisesta parool kui küsitakse (parool ei kuvata, kui trükid)
```

**Esimesel korral** võid näha hoiatust võtme kohta:
```
The authenticity of host '[192.168.1.100]:2201' can't be established.
...
Are you sure you want to continue connecting (yes/no)?
```

Kirjuta `yes` ja vajuta Enter.

### Kontrolli Keskkonda

Pärast sisselogimist kontrolli, et kõik töötab:

```bash
# 1. Kontrolli kasutajanime
whoami
# Väljund peaks olema: labuser

# 2. Kontrolli masina nime
hostname
# Väljund peaks olema midagi nagu: devops-student1

# 3. Kontrolli Docker'i versiooni
docker --version
# Väljund näiteks: Docker version 24.0.7, build afdd53b

# 4. Kontrolli töötavaid konteinereid
docker ps
# Peaks näitama tühja nimekirja või süsteemi konteinereid

# 5. Vaata labori faile
cd ~/labs
ls -la
# Peaks näitama: 01-docker-lab ja 02-docker-compose-lab katalooge
```

Kui kõik käsud töötasid, oled valmis alustama!

---

## 2. Docker Põhikäsud

### Konteinerite Haldamine

```bash
# Vaata kõiki töötavaid konteinereid
docker ps

# Vaata kõiki konteinereid (ka peatatud)
docker ps -a

# Käivita konteiner
docker start <container-name>
# Näide:
docker start my-nginx

# Peata konteiner
docker stop <container-name>
# Näide:
docker stop my-nginx

# Taaskäivita konteiner
docker restart <container-name>

# Kustuta konteiner (peab olema peatatud)
docker rm <container-name>

# Vaata konteineri logisid
docker logs <container-name>

# Vaata logisid reaalajas (live)
docker logs -f <container-name>
# Vajuta Ctrl+C, et väljuda

# Vaata konteineri detailset infot
docker inspect <container-name>
```

### Image'ite Haldamine

```bash
# Vaata lokaalseid image'id
docker images

# Laadi image registrist (Docker Hub)
docker pull alpine:3.16
docker pull nginx:latest
docker pull postgres:16-alpine

# Kustuta image
docker rmi <image-name>
# Näide:
docker rmi nginx:latest

# Ehita oma image Dockerfile'ist
cd ~/labs/01-docker-lab/...
docker build -t myapp:v1 .
# -t = tag (nimi ja versioon)
# . = Dockerfile on praeguses kataloogis

# Vaata image'i ajalugu (kihte)
docker history <image-name>
```

### Docker Compose

Docker Compose võimaldab hallata mitut konteinerit korraga:

```bash
# Käivita kõik teenused
cd ~/labs/02-docker-compose-lab/...
docker compose up -d
# -d = detached mode (töötab taustal)

# Vaata teenuste staatust
docker compose ps

# Vaata kõigi teenuste logisid
docker compose logs

# Vaata ühe teenuse logisid
docker compose logs frontend
docker compose logs -f user-api  # Live logs

# Peata kõik teenused
docker compose stop

# Käivita teenused uuesti
docker compose restart

# Käivita üks teenus uuesti
docker compose restart frontend

# Kustuta kõik teenused (kuid säilita volume'id)
docker compose down

# Kustuta kõik sh volume'id (ETTEVAATUST!)
docker compose down -v
```

---

## 3. Labori Failide Kasutamine

### Kataloogistruktuur

Sinu labori failid asuvad kataloogis `~/labs`:

```
~/labs/
├── README.md                  # Ülevaade kõigist laboritest
├── 01-docker-lab/             # Lab 1: Docker põhialused
│   ├── README.md              # Lab 1 juhend
│   ├── exercises/             # Ülesanded
│   │   ├── 01-basic-container/
│   │   ├── 02-dockerfile/
│   │   └── ...
│   └── solutions/             # Lahendused (vaata kui jääd hätta)
│       ├── 01-basic-container/
│       └── ...
└── 02-docker-compose-lab/     # Lab 2: Docker Compose
    ├── README.md              # Lab 2 juhend
    ├── apps/                  # Valmis rakendused
    │   ├── frontend/
    │   ├── user-api/
    │   └── todo-api/
    ├── exercises/             # Ülesanded
    └── solutions/             # Lahendused
```

### Töövoog

Nii peaks töötama ülesandega:

```bash
# 1. Loe labori üldist juhendit
cd ~/labs/01-docker-lab
cat README.md
# VÕI kasuta less, et lehekülgede kaupa vaadata:
less README.md  # Vajuta 'q', et väljuda

# 2. Mine ülesande kataloogi
cd exercises/01-basic-container

# 3. Loe ülesande juhendit
cat README.md

# 4. Tee ülesannet
# ... siin kirjutad oma lahenduse ...
# Näiteks:
docker pull alpine:3.16
docker run -d --name my-container alpine:3.16 sleep 3600

# 5. Testi oma lahendust
docker ps | grep my-container

# 6. Kui jääd hätta, vaata lahendust
cd ~/labs/01-docker-lab/solutions/01-basic-container
cat solution.md
# VÕI
cat Dockerfile  # Kui seal on Dockerfile näidis
```

---

## 4. Kasulikud Käsud

### Süsteemi Info

```bash
# Vaata RAM kasutust
free -h
# Näitab: total, used, free, available

# Vaata kettaruumi kasutust
df -h
# Näitab: filesystem, size, used, available

# Vaata CPU ja mälu kasutust reaalajas
top
# Vajuta 'q', et väljuda

# Või kasuta htop (värvilisem, selgem)
htop
# Vajuta F10 või 'q', et väljuda

# Vaata võrgu ühendusi
netstat -tuln
# Näitab: avatud porte ja nende olekut

# Vaata, mis kasutab konkreetset porti
sudo lsof -i :8080
```

### Docker Debug

```bash
# Kontrolli Docker daemoni staatust
sudo systemctl status docker

# Taaskäivita Docker daemon (kui midagi on katki)
sudo systemctl restart docker

# Vaata Docker'i süsteemi infot
docker info

# Vaata Docker'i disk kasutust
docker system df

# Puhasta kasutamata image'id, konteinerid, volume'id, network'id
docker system prune
# Küsib kinnitust, kirjuta 'y'

# Puhasta KÕIK (sh image'id mida hetkel ei kasuta)
docker system prune -a
# ETTEVAATUST: see kustutab kõik lokaalsed image'id!

# Vaata konteineri ressursside kasutust
docker stats
# Näitab: CPU, RAM, Network, Disk I/O
# Vajuta Ctrl+C, et väljuda
```

---

## 5. Probleemide Lahendamine

### Probleem 1: SSH Ühendus Ebaõnnestub

**Sümptom:**
```
ssh: connect to host 192.168.1.100 port 2201: Connection refused
```

**Võimalikud põhjused:**
1. Vale SSH port
2. Vale IP aadress
3. Vale parool
4. Server ei tööta (harva)

**Lahendus:**

```bash
# 1. Kontrolli, et kasutad õiget porti
# Student1 → 2201
# Student2 → 2202
# Student3 → 2203
# jne...

# Näide õige käsk:
ssh labuser@192.168.1.100 -p 2201

# 2. Kontrolli IP aadressi (küsi koolitajalt, kui ei tea)

# 3. Kontrolli parooli (küsi koolitajalt, kui ei tea)
```

**Kui ikkagi ei tööta:** Võta ühendust koolitajaga.

---

### Probleem 2: Docker Konteiner Ei Käivitu

**Sümptom:**
```
docker start mycontainer
Error response from daemon: ...
```

**Lahendus:**

```bash
# 1. Vaata konteineri logisid
docker logs mycontainer
# Logi peaks näitama viga

# 2. Vaata konteineri detailset infot
docker inspect mycontainer
# Vaata "State" sektsiooni

# 3. Kui ei aita, loo uus konteiner
docker stop mycontainer  # Kui töötab
docker rm mycontainer    # Kustuta vana

# Loo uus:
docker run -d --name mycontainer <image-name>
```

---

### Probleem 3: Port Juba Kasutusel

**Sümptom:**
```
docker: Error response from daemon: driver failed programming external connectivity:
Bind for 0.0.0.0:8080 failed: port is already allocated.
```

**Põhjus:** Keegi teine (konteiner või programm) kasutab juba seda porti.

**Lahendus:**

```bash
# 1. Vaata, mis kasutab porti 8080
sudo lsof -i :8080
# Näitab protsessi nime ja PID'i

# 2. Kui see on Docker konteiner, peata see
docker ps  # Leia konteineri nimi
docker stop <container-name>

# 3. VÕI kasuta teist porti
# Muuda -p parameetrit:
docker run -p 8081:8080 myapp
# Nüüd on rakendus kättesaadav pordil 8081
```

---

### Probleem 4: Docker Image Pull Ebaõnnestub

**Sümptom:**
```
docker pull alpine:3.16
Error response from daemon: Get https://registry-1.docker.io/v2/: dial tcp: lookup registry-1.docker.io: no such host
```

**Põhjus:** Proxy seadistus puudub või on vale. See on administraatori probleem.

**Lahendus:**

Võta ühendust koolitajaga. Ära püüa seda ise parandada - proxy seadistus on administraatori ülesanne.

---

### Probleem 5: Labori Failid on Kadunud

**Sümptom:**
```
cd ~/labs
-bash: cd: labs: No such file or directory
```

**Põhjus:** Failid pole sünkroniseeritud või on kustutatud.

**Lahendus:**

Võta ühendust koolitajaga. Administraator sünkroniseerib failid uuesti sinu keskkonda.

---

### Probleem 6: "Permission Denied" Viga

**Sümptom:**
```
docker: Got permission denied while trying to connect to the Docker daemon socket
```

**Põhjus:** Sinu kasutaja ei ole `docker` grupis (harva).

**Lahendus:**

```bash
# Kontrolli, kas oled docker grupis
groups
# Peaks näitama: labuser docker ...

# Kui "docker" puudub, logi välja ja uuesti sisse
exit
ssh labuser@<HOST-IP> -p <SSH-PORT>

# Kui ikkagi ei tööta, võta ühendust koolitajaga
```

---

### Probleem 7: Konteiner Töötab, Aga Port Ei Ole Kättesaadav

**Sümptom:**
```
docker ps
# Konteiner töötab

curl http://localhost:8080
# curl: (7) Failed to connect to localhost port 8080: Connection refused
```

**Lahendus:**

```bash
# 1. Kontrolli, kas port on õigesti mapped
docker ps
# Vaata PORTS veergu, peaks olema: 0.0.0.0:8080->8080/tcp

# 2. Kontrolli konteineri logisid
docker logs <container-name>
# Kas rakendus tõesti käivitus?

# 3. Logi konteineri sisse ja kontrolli
docker exec -it <container-name> /bin/sh
# Konteineri sees:
wget -O- http://localhost:8080
exit

# 4. Kui ei aita, taaskäivita konteiner
docker restart <container-name>
```

---

## 6. Parimad Praktikad

### DO's ✅

- **Salvesta oma töö regulaarselt**
  - Lisa oma lahendused Git repo'sse (kui sul on)
  - Kopeeri olulised failid

- **Kasuta README faile**
  - Iga labori juhend on README.md failis
  - Loe juhend enne alustamist läbi

- **Testi enne commit'i**
  - Veendu, et kõik töötab enne kui märgid lahenduse valmis

- **Küsi abi**
  - Kui jääd hätta, küsi koolitajalt või kaasõppijatelt
  - Ära jää probleemiga kinni tundideks

- **Puhasta ressursid**
  - Peata või kustuta konteinerid, kui neid ei kasuta
  - Hoia oma keskkond korras

- **Tee märkmeid**
  - Kirjuta üles, mida õppisid
  - Dokumenteeri oma lahendused

### DON'T's ❌

- ❌ **Ära muuda süsteemi seadistusi**
  - Keskkonda haldab administraator
  - Ära muuda proxy seadistusi, võrku, firewall'i

- ❌ **Ära kustuta labori faile**
  - Kui kustutad, võta ühendust administraatoriga
  - Ära muuda ~/labs/ kausta struktuuri

- ❌ **Ära kasuta kogu RAM-i**
  - Sul on 2.5GB RAM-i
  - Jäta vähemalt 500MB vabaks (vaata: `free -h`)

- ❌ **Ära jäta konteinereid taustal töötama**
  - Peata konteinerid, kui neid ei kasuta
  - Näide: `docker stop $(docker ps -q)` peatab kõik

- ❌ **Ära proovi parandada süsteemi probleeme**
  - Docker daemon ei tööta → Koolitaja
  - Proxy ei tööta → Koolitaja
  - SSH ei tööta → Koolitaja

---

## 7. Kasulikud Lingid

### Docker Dokumentatsioon

- **Docker põhialused:** https://docs.docker.com/get-started/
- **Dockerfile reference:** https://docs.docker.com/engine/reference/builder/
- **Docker CLI reference:** https://docs.docker.com/engine/reference/commandline/cli/
- **Docker Compose:** https://docs.docker.com/compose/

### Muud Ressursid

- **Alpine Linux:** https://alpinelinux.org/ (kerge Linux distributsioon konteineritele)
- **PostgreSQL dokumentatsioon:** https://www.postgresql.org/docs/
- **Docker Hub:** https://hub.docker.com/ (avalikud image'id)

### Eesti Keelsed Materjalid

- Selles koolituses kasutatakse eesti keelseid teoreetilisi materjale
- Küsi koolitajalt, millised peatükid toetavad neid laboreid

---

## 8. Abi Saamine

### Enda Jaoks

**Kui sul on probleeme:**

1. **Proovi esmalt lahendada ise**
   - Loe "Probleemide Lahendamine" sektsiooni (peatükk 5)
   - Vaata konteineri logisid: `docker logs <container-name>`
   - Otsi veateadet Google'ist

2. **Küsi kaasõppijatelt**
   - Võib-olla keegi on sama probleemiga kokku puutunud
   - Jagage teadmisi ja kogemusi

3. **Võta ühendust koolitajaga**
   - Kirjuta selgelt, mis probleem on
   - Lisa veateateid ja käskude väljundeid
   - Ütle, mis sa juba proovisid

### Tehnilised Probleemid (Koolitaja Abi)

Järgmiste probleemide korral võta **kohe** ühendust koolitajaga:

- **SSH ei tööta** → Koolitaja
- **Docker ei tööta** → Koolitaja
- **Labori failid puuduvad** → Koolitaja
- **Ressursid on otsa** (RAM, disk) → Koolitaja
- **Proxy seadistus ei tööta** → Koolitaja
- **Keskkonnas midagi on katki** → Koolitaja

### Koolitaja Kontakt

[Siin peaks olema koolitaja kontaktandmed - küsi koolitajalt]

---

## Kokkuvõte

Palju õnne - nüüd oled valmis alustama Docker laboreid!

**Meeldetuletused:**
- Sinu keskkond: `devops-student<X>` (X = sinu number)
- SSH port: `220X` (näiteks Student1 = 2201)
- Docker käsud: `docker ps`, `docker run`, `docker build`
- Docker Compose: `docker compose up -d`, `docker compose down`
- Abi: Loe juhendeid, küsi kaasõppijatelt, võta ühendust koolitajaga

**Edu laboritega!**

Ära karda eksida - vigadest õpitakse kõige rohkem. Docker on võimas tööriist ja praktiline kogemus on parim õpetaja.

---

**Viimane uuendus:** 2025-12-02
**Versioon:** 1.0
**Keskkond:** Docker Lab (Lab 1-2)
**Sihtgrupp:** DevOps koolituse õpilased

---

**Küsimused või ettepanekud?** Võta ühendust koolitajaga!
