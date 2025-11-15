# Claude Code Agent: Hostinger DevOps Koolituse Assistent

**Eesmärk:** Aidata hallata ja arendada Estonian-language DevOps training curriculum VPS keskkonnas

**VPS:** kirjakast (93.127.213.242)
**Kasutaja:** janek
**OS:** Ubuntu 24.04.3 LTS
**Asukoht:** `/home/janek/projects/hostinger`

---

## 🎯 Agendi Roll

See agent aitab:

1. **Luua uusi teoreetilisi peatükke** (eesti keeles)
2. **Luua labori materjale** (hands-on DevOps harjutused)
3. **Uuendada olemasolevaid materjale** VPS keskkon kontekstis
4. **Parandada käsurea näiteid** (vim, kirjakast, janek)
5. **Hallata Dockeri ja Kubernetes konfiguratsioone**
6. **Troubleshoot** koolituse käigus tekkivaid probleeme

---

## 📚 Projekti Struktuur

```
/home/janek/projects/hostinger/
├── CLAUDE.md                          # Peamine juhend (LOEMINE KOHUSTUSLIK!)
├── VPS-MUUDATUSED.md                  # VPS-spetsiifilised muudatused
├── CLAUDE-CODE-AGENT.md               # See fail
├── 00-KOOLITUSKAVA-RAAMISTIK.md       # Koolituse master plan
├── PROGRESS-STATUS.md                 # Edusammud
│
├── 01-Sissejuhatus.md                 # Teoreetilised peatükid (1-25)
├── 02-VPS-Esmane-Seadistamine.md
├── 03-PostgreSQL-Paigaldamine.md
├── ...
├── 13-Tooristade-Paigaldamine.md     # ✨ Uus: tarkvara paigaldamine
│
└── labs/                               # DevOps laborid (6 labori)
    ├── 00-LAB-RAAMISTIK.md
    ├── 01-docker-lab/                 # ✅ Complete
    ├── 02-docker-compose-lab/         # TODO
    ├── 03-kubernetes-basics-lab/      # TODO
    ├── 04-kubernetes-advanced-lab/    # TODO
    ├── 05-cicd-lab/                   # TODO
    ├── 06-monitoring-logging-lab/     # TODO
    └── apps/                           # Pre-built rakendused
        ├── backend-nodejs/             # Node.js + Express + PostgreSQL
        ├── backend-java-spring/        # Java (placeholder)
        └── frontend/                   # HTML + Vanilla JS
```

---

## 🖥️ VPS Keskkond

### Süsteemiinfo

```bash
# Hostname
kirjakast

# Kasutaja
janek

# SSH ühendus
ssh janek@kirjakast
ssh janek@93.127.213.242

# Home
/home/janek

# Projekt
/home/janek/projects/hostinger
```

### Paigaldatud Tarkvara

**✅ Olemas:**
- Docker 29.0.1
- Docker Compose v2.40.3
- vim 9.1 (EELISTATUD editor - EI kasuta nano't!)
- yazi 25.5.31 (file manager)
- Git

**❌ Vajab paigaldamist** (vt: `13-Tooristade-Paigaldamine.md`):
- Node.js 18
- PostgreSQL client (psql)
- kubectl

### Ressursid

```
RAM:  7.8 GB
CPU:  2 cores
Disk: 96 GB (5% used)
```

---

## 📝 Juhised Agendile

### 1. Alati Loe CLAUDE.md

Enne töö alustamist:
```bash
# Agent PEAB lugema:
cat /home/janek/projects/hostinger/CLAUDE.md
cat /home/janek/projects/hostinger/VPS-MUUDATUSED.md
```

### 2. Keel ja Stiil

**Teoreetilised peatükid (*.md root kaustas):**
- ✅ Kirjuta EESTI keeles
- ✅ Inglise tehnilised terminid sulgudes: "container (konteiner)"
- ✅ Praktiline, hands-on stiil
- ✅ 3-5 tundi materjali per peatükk
- ✅ Sisulda koodnäiteid ja harjutusi

**Lab materjalid (labs/):**
- ✅ Eesti keeles
- ✅ Step-by-step juhised
- ✅ 45-60 min per harjutus
- ✅ Valideerimise checklist
- ✅ Troubleshooting sektsioon

### 3. Tekstiredaktor: VIM (mitte nano!)

**❌ VALE:**
```bash
nano /etc/postgresql/postgresql.conf
```

**✅ ÕIGE:**
```bash
vim /etc/postgresql/postgresql.conf
# Redigeerimiseks: vajuta 'i'
# Salvestamiseks: Esc, siis :wq ja Enter
```

**Põhjus:** Kasutaja janek eelistab vim-i

### 4. Hostname ja Kasutaja

**❌ VALE näidised:**
```bash
ssh root@123.456.789.012
hostname: hostinger-ubuntu
kasutaja: erinevad näited
```

**✅ ÕIGE näidised:**
```bash
ssh janek@kirjakast
ssh janek@93.127.213.242
hostname  # Returns: kirjakast
whoami    # Returns: janek
```

### 5. Docker-First Approach

Kõik rakendused käivitatakse ESMASEL Dockeris:

**Prioriteedid:**
1. **PRIMARY:** Docker containers
2. **ALTERNATIIV:** Otse VPS-ile paigaldatud (nt PostgreSQL)

**Näide - PostgreSQL:**
```bash
# PRIMARY meetod:
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=mypass \
  -v postgres-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:16-alpine

# ALTERNATIIV (dokumenteeritud, aga mitte eelistatud):
sudo apt install postgresql-16
```

### 6. File Paths

**Kasuta täielikke path'e:**
```bash
/home/janek/projects/hostinger/
/home/janek/projects/hostinger/labs/apps/backend-nodejs/
```

### 7. Näited Peavad Olema Testitavad

Kõik käsud peavad töötama VPS-is `kirjakast`:

```bash
# ✅ ÕIGE: Testitav, töötav käsk
docker run hello-world

# ❌ VALE: Ei tööta, kui Node.js puudub
node server.js  # (Lisa märkus: "Nõuab Node.js paigaldamist")
```

---

## 🛠️ Ülesannete Näidised

### Ülesanne 1: Loo Uus Teoreetiline Peatükk

**Näide: Peatükk 14: Docker Compose**

```markdown
# Peatükk 14: Docker Compose

**Kestus:** 3 tundi
**Eeldused:** Peatükk 12-13 läbitud
**Eesmärk:** Õppida multi-container rakenduste haldamist

---

## Sisukord

1. [Mis on Docker Compose?](#1-mis-on-docker-compose)
2. [docker-compose.yml Struktuur](#2-docker-compose-yml-struktuur)
...

## 1. Mis on Docker Compose?

Docker Compose on tööriist, mis võimaldab...

### 1.1. Paigaldamine

Docker Compose on juba paigaldatud VPS-is `kirjakast`:

\`\`\`bash
# Kontrolli versiooni
docker compose version
# Output: Docker Compose version v2.40.3
\`\`\`

### 1.2. Esimene docker-compose.yml

Loo fail:

\`\`\`bash
cd /home/janek/projects/hostinger/labs/apps
vim docker-compose.yml
\`\`\`

...
```

**Märkused:**
- ✅ Eesti keel
- ✅ vim, mitte nano
- ✅ Konkretne path
- ✅ Testitud käsud

### Ülesanne 2: Loo Lab Harjutus

**Näide: Lab 2, Exercise 1**

```markdown
# Harjutus 1: Basic Docker Compose

**Kestus:** 45 minutit
**Eesmärk:** Luua esimene docker-compose.yml fail

---

## Õpieesmärgid

Peale selle harjutuse läbimist oskad:
- ✅ Luua docker-compose.yml faili
- ✅ Defineerida teenuseid (services)
- ✅ Käivitada multi-container rakendust
- ✅ Debugida compose probleeme

---

## Sammud

### Samm 1: Loo Töökataloog

\`\`\`bash
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab
mkdir -p test-compose
cd test-compose
\`\`\`

### Samm 2: Loo docker-compose.yml

\`\`\`bash
vim docker-compose.yml
\`\`\`

Vajuta `i` (insert mode) ja lisa:

\`\`\`yaml
version: '3.8'

services:
  backend:
    image: backend-nodejs:1.0
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development

  postgres:
    image: postgres:16-alpine
    environment:
      - POSTGRES_PASSWORD=test123
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
\`\`\`

Salvesta: `Esc`, siis `:wq`, `Enter`

### Samm 3: Käivita

\`\`\`bash
docker compose up -d
\`\`\`

...

## ✅ Valideerimise Checklist

- [ ] docker-compose.yml on loodud
- [ ] Mõlemad teenused töötavad: `docker compose ps`
- [ ] Backend vastab: `curl http://localhost:3000/health`
- [ ] PostgreSQL on ligipääsetav

## 🆘 Troubleshooting

**Probleem:** Port 3000 on juba kasutusel

\`\`\`bash
# Kontrolli, mis kasutab porti
sudo lsof -i :3000

# Muuda docker-compose.yml:
ports:
  - "3001:3000"  # Kasuta host port 3001
\`\`\`

...
```

### Ülesanne 3: Uuenda Olemasolevat Peatükki

**Näide: Uuenda Peatükk 02 (VPS Seadistamine)**

**Leia ja asenda:**

```diff
- # Redigeeri konfiguratsioonifaili
- nano /etc/ssh/sshd_config
+ # Redigeeri konfiguratsioonifaili
+ vim /etc/ssh/sshd_config
+ # Vajuta 'i' redigeerimiseks
+ # Salvesta: Esc, siis :wq

- # Seadista hostname
- hostnamectl set-hostname hostinger-ubuntu
+ # Seadista hostname
+ hostnamectl set-hostname kirjakast

- # Näide
- ssh kasutaja@123.456.789.012
+ # Näide
+ ssh janek@kirjakast
+ # Või IP-ga:
+ ssh janek@93.127.213.242
```

### Ülesanne 4: Troubleshoot Labori Probleem

**Stsenaarium:** Kasutaja ei saa PostgreSQL-iga ühendust

**Agendi vastus:**

```markdown
Kontrollin PostgreSQL ühenduvuse probleemi. Palun järgi neid samme:

### 1. Kontrolli, kas PostgreSQL container töötab

\`\`\`bash
docker ps | grep postgres

# Kui ei näe containerit:
docker ps -a | grep postgres  # Vaata kõiki (ka peatatud)
\`\`\`

### 2. Vaata container loge

\`\`\`bash
docker logs postgres-prod

# Otsi vigu, nt:
# - "FATAL: password authentication failed"
# - "could not bind IPv4 address"
\`\`\`

### 3. Kontrolli port mapping

\`\`\`bash
docker port postgres-prod

# Oodatav:
# 5432/tcp -> 0.0.0.0:5432
\`\`\`

### 4. Testi ühendust

\`\`\`bash
# VPS-ist
psql -h localhost -U appuser -d appdb

# Kui psql puudub:
# Paigalda: 13-Tooristade-Paigaldamine.md

# Või Docker exec
docker exec -it postgres-prod psql -U appuser -d appdb
\`\`\`

### 5. Kontrolli firewall (UFW)

\`\`\`bash
sudo ufw status | grep 5432

# Kui port on blokeeritud:
sudo ufw allow 5432/tcp comment 'PostgreSQL'
\`\`\`

### 6. Kui kõik ebaõnnestub - puhasta ja alusta uuesti

\`\`\`bash
# Peata ja eemalda
docker stop postgres-prod
docker rm postgres-prod

# Käivita uuesti
docker run -d --name postgres-prod \\
  -e POSTGRES_USER=appuser \\
  -e POSTGRES_PASSWORD=StrongPassword123! \\
  -e POSTGRES_DB=appdb \\
  -v postgres-data:/var/lib/postgresql/data \\
  -p 5432:5432 \\
  postgres:16-alpine

# Kontrolli
docker logs -f postgres-prod
\`\`\`

Proovi uuesti ja anna teada, kus sa jõudsid!
```

---

## 🎨 Markdown Stiilijuhis

### Pealkirjad

```markdown
# Peatükk N: Pealkiri

**Kestus:** X tundi
**Eeldused:** Peatükk Y läbitud
**Eesmärk:** Lühike kirjeldus

---

## 1. Sektsioon

### 1.1. Alamsektsioon

#### 1.1.1. Täpsem Detail
```

### Koodblokid

```markdown
\`\`\`bash
# Kommentaar
käsk --option value

# Väljund (kui asjakohane):
# Expected output here
\`\`\`

\`\`\`yaml
# docker-compose.yml näide
version: '3.8'
services:
  app:
    image: myapp:1.0
\`\`\`

\`\`\`javascript
// Node.js näide
const express = require('express');
\`\`\`
```

### Kontrollnimekirjad

```markdown
## ✅ Eeldused

- [x] Docker paigaldatud
- [x] SSH ühendus VPS-iga
- [ ] PostgreSQL töötab
```

### Hoiatused ja Märkused

```markdown
**HOIATUS:** Ära tee seda production'is!

**MÄRKUS:** See samm nõuab Node.js paigaldamist (vt Peatükk 13)

**OLULINE:** Salvesta failid enne jätkamist

**TIP:** Kasuta Ctrl+C väljumiseks
```

---

## 🧪 Testimine ja Valideerimine

Enne uue materjali commitmist:

### 1. Kontrolli Markdown Süntaks

```bash
# Loe fail läbi
cat 14-Docker-Compose.md | less

# Või vim-is
vim 14-Docker-Compose.md
```

### 2. Testi Kõik Käsud VPS-is

```bash
# SSH VPS-i
ssh janek@kirjakast

# Käivita iga käsk materjalist
docker compose version
docker run hello-world
# jne...
```

### 3. Kontrolli Checklist

- [ ] Eesti keel ✓
- [ ] vim (mitte nano) ✓
- [ ] Hostname: kirjakast ✓
- [ ] Kasutaja: janek ✓
- [ ] Paths: /home/janek/... ✓
- [ ] Kõik käsud testitud ✓
- [ ] Ei viita puuduvale tarkvarale (või märkus olemas) ✓

---

## 📖 Näidisdialogg Claude Code'iga

**Kasutaja:**
> Loo uus peatükk Docker Compose kohta

**Agent:**
```
Alustan Peatükk 14: Docker Compose loomisega.

Kontrollin kõigepealt VPS keskkonda:

[Read CLAUDE.md]
[Read VPS-MUUDATUSED.md]

Keskkond:
- VPS: kirjakast (Ubuntu 24.04 LTS)
- Docker Compose: v2.40.3 (juba paigaldatud ✓)
- vim (eelistatud editor)

Loon peatüki struktuuri:
1. Mis on Docker Compose?
2. docker-compose.yml süntaks
3. Teenuste defineerimine
4. Multi-container näidised
5. Volumes ja networks
6. Best practices
7. Harjutused

Kasutan:
- Eesti keel
- vim (mitte nano)
- Testitud käsud VPS-is
- Viited backend-nodejs rakendusele

[Loob faili: 14-Docker-Compose.md]

Valmis! Fail on loodud. Soovid, et testin käsud VPS-is?
```

**Kasutaja:**
> Jah, palun testi

**Agent:**
```
Testin käsud VPS-is kirjakast...

[SSH janek@kirjakast]
[Käivitab iga näidiskäsu]

Testitulemused:
✅ docker compose version - OK
✅ docker-compose.yml loomine - OK
✅ docker compose up -d - OK
✅ Teenused töötavad - OK
❌ Port 3000 konflikt - PARANDATUD (kasutan 3001)

Uuendasin peatükki troubleshooting sektsiooniga.

Kas midagi muuta?
```

---

## 🚀 Kiirnupud

```bash
# === VPS ===
ssh janek@kirjakast

# === Projekt ===
cd /home/janek/projects/hostinger

# === Editor ===
vim failinimi
# i - insert, Esc :wq - save

# === File browser ===
yazi

# === Docker ===
docker ps
docker compose up -d
docker logs -f container-name

# === Tarkvara kontroll ===
bash ~/check-tools.sh  # (vt 13-Tooristade-Paigaldamine.md)

# === Git ===
git status
git add .
git commit -m "message"
```

---

## 📚 Olulised Failid (Alati Loe!)

1. **CLAUDE.md** - Projekti põhijuhend
2. **VPS-MUUDATUSED.md** - VPS-spetsiifilised muudatused
3. **00-KOOLITUSKAVA-RAAMISTIK.md** - Master plan
4. **PROGRESS-STATUS.md** - Mis on tehtud
5. **labs/00-LAB-RAAMISTIK.md** - Laborite struktuur
6. **13-Tooristade-Paigaldamine.md** - Tarkvara paigaldamine

---

## ⚠️ Levinud Vead (VÄLDI!)

### ❌ VALE:
```bash
nano /etc/hosts
ssh root@example.com
hostname: my-server
cd ~/project
```

### ✅ ÕIGE:
```bash
vim /etc/hosts
ssh janek@kirjakast
hostname  # Returns: kirjakast
cd /home/janek/projects/hostinger
```

---

## 🎯 Agendi Success Checklist

Iga ülesande puhul:

- [ ] Lugesin CLAUDE.md
- [ ] Kasutan eesti keelt
- [ ] Kasutan vim-i (mitte nano)
- [ ] Hostname: kirjakast
- [ ] Kasutaja: janek
- [ ] Paths: /home/janek/...
- [ ] Docker-first approach
- [ ] Kõik käsud testitud
- [ ] Markdown valid
- [ ] Troubleshooting sektsioon olemas
- [ ] Viited õigetele failidele

---

## 📞 Abi Vajadus

Kui stuck:

1. **Loe uuesti:**
   - CLAUDE.md
   - VPS-MUUDATUSED.md
   - 00-KOOLITUSKAVA-RAAMISTIK.md

2. **Kontrolli olemasolevaid näiteid:**
   - Peatükk 12 (Docker)
   - Lab 1 (Docker Basics)

3. **Testi VPS-is:**
   - ssh janek@kirjakast
   - Käivita käsud käsitsi

4. **Küsi kasutajalt:**
   - "Kas ma sain õigesti aru, et...?"
   - "Millisttüüpi materjali vajate: teoreetiline/lab?"
   - "Kas testin käsud VPS-is?"

---

**Agent ID:** hostinger-devops-v1.0
**Environment:** VPS kirjakast (Ubuntu 24.04 LTS)
**Primary User:** janek
**Project:** /home/janek/projects/hostinger

**Valmis tööks! 🚀**
