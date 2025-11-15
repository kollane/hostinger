# Peatükk 1: Sissejuhatus ja Ülevaade

**Kestus:** 2 tundi
**Eeldused:** Põhilised arvutikasutamise oskused
**Eesmärk:** Mõista full-stack arenduse olemust, tutvuda kasutatava keskkonnaga ja seada eesmärgid

---

## Sisukord

1. [Full-stack Arenduse Põhimõtted](#1-full-stack-arenduse-põhimõtted)
2. [Hostingeri VPS Platvorm](#2-hostingeri-vps-platvorm)
3. [Arenduskeskkond: Zorin OS ja Ubuntu](#3-arenduskeskkond-zorin-os-ja-ubuntu)
4. [Koolituskava Struktuur ja Eesmärgid](#4-koolituskava-struktuur-ja-eesmärgid)
5. [Vajalikud Tööriistad ja Eelteadmised](#5-vajalikud-tööriistad-ja-eelteadmised)
6. [Õpiväljundid](#6-õpiväljundid)
7. [Harjutused](#7-harjutused)
8. [Kontrolliküsimused](#8-kontrolliküsimused)
9. [Lisamaterjalid](#9-lisamaterjalid)

---

## 1. Full-stack Arenduse Põhimõtted

### 1.1. Mis on Full-stack Arendus?

**Full-stack arendus** tähendab võimet töötada nii **frontend-iga** (kasutajaliides) kui ka **backend-iga** (serveri pool) ning mõista, kuidas need koos toimivad.

#### Analoogia: Restoran kui Veebirakendus

Kujutame ette restorani:

- **Frontend (kliendifront):** Restorani saal, kus kliendid istuvad, menüüd loevad ja toitu tellivad. See on see, mida klient **näeb ja millega suhtleb**.

- **Backend (serveri pool):** Köök ja ladu, kus toit valmistatakse, koostisosad hoitakse ja tellimused töödeldakse. Klient seda **ei näe**, aga see on kriitilise tähtsusega.

- **Andmebaas (database):** Ladu, kus kõik koostisosad (andmed) hoitakse organiseeritult ja kättesaadavalt.

- **API (liides):** Ettekandjad, kes viivad tellimused kööki ja toovad toidu klientidele. Nad on **vahendajad** frontendi ja backendi vahel.

**Full-stack arendaja** on nagu restoraniomanik, kes **mõistab kogu protsessi** - saalist kuni köögini.

---

### 1.2. Veebirakenduse Arhitektuur

Tänapäevane veebirakendus koosneb kolmest põhilisest kihist:

```
┌─────────────────────────────────────────┐
│           FRONTEND (Client)             │
│  ┌─────────────────────────────────┐   │
│  │    HTML + CSS + JavaScript       │   │
│  │    (User Interface)              │   │
│  └─────────────────────────────────┘   │
└───────────────┬─────────────────────────┘
                │
                │ HTTP/HTTPS (REST API)
                │
┌───────────────▼─────────────────────────┐
│           BACKEND (Server)              │
│  ┌─────────────────────────────────┐   │
│  │    Node.js + Express.js          │   │
│  │    (Business Logic)              │   │
│  └─────────────┬───────────────────┘   │
└────────────────┼───────────────────────┘
                 │
                 │ SQL Queries
                 │
┌────────────────▼────────────────────────┐
│         DATABASE (Storage)              │
│  ┌─────────────────────────────────┐   │
│  │    PostgreSQL                    │   │
│  │    (Data Persistence)            │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

#### 1.2.1. Frontend (Kliendipoolne)

**Tehnoloogiad:**
- **HTML5** - Struktuuri loomine (nagu maja karkass)
- **CSS3** - Kujundus ja välimus (nagu siseviimistlus)
- **JavaScript** - Interaktiivsus ja dünaamika (nagu elektrisüsteem)

**Vastutus:**
- Kasutajaliidese renderdamine
- Kasutaja sisendi valideerimine
- Backend-iga suhtlemine (API kutsed)
- Kasutajakogemuse (UX) tagamine

---

#### 1.2.2. Backend (Serveri Poolne)

**Tehnoloogiad:**
- **Node.js** - JavaScript runtime server-poolel
- **Express.js** - Veebiraamistik (web framework)
- **REST API** - Liides frontendi ja backendi vahel

**Vastutus:**
- Äriloogika (business logic) töötlemine
- Autentimine ja autoriseerimine
- Andmebaasi päringud
- Andmete valideerimine ja töötlemine
- Turvalisuse tagamine

---

#### 1.2.3. Andmebaas (Database)

**Tehnoloogia:**
- **PostgreSQL** - Relatsiooniline andmebaas (relational database)

**Vastutus:**
- Andmete püsiv salvestamine
- Andmete struktureerimine (schema)
- Päringute optimeerimine
- Andmete terviklikkus (data integrity)

---

### 1.3. Kaasaegsed Arenduspraktikad

Selles koolituses käsitleme ka tänapäevaseid DevOps praktikaid:

#### 1.3.1. Konteinerisatsioon (Containerization)

**Docker** võimaldab meil pakkida rakendust koos kõigi sõltuvustega ühte isoleeritud "konteinerisse".

**Analoogia:** Docker on nagu kohver, kuhu paned kõik reisiks vajalikud asjad. Kohver on standardse suurusega ja mahub igale lennukile (serverisse), sõltumata sellest, milline lennufirma (operatsioonisüsteem) on.

**Eelised:**
- ✅ "Töötab minu masinas" probleem lahendatud
- ✅ Kiire deployment
- ✅ Keskkonna järjepidevus (development = production)
- ✅ Kerge skaleeritavus

---

#### 1.3.2. Orkestratsioon (Orchestration)

**Kubernetes (K8s)** haldab konteinerite käivitamist, skaleerimist ja haldamist.

**Analoogia:** Kui Docker on kohver, siis Kubernetes on lennujaama logistikasüsteem, mis tagab, et kõik kohvrid (konteinerid) jõuavad õigesse kohta õigel ajal, ja kui mingi lend (server) tühistatakse, leitakse automaatselt alternatiiv.

**Eelised:**
- ✅ Automaatne skaaleerimine (autoscaling)
- ✅ Enesetervendamine (self-healing)
- ✅ Load balancing
- ✅ Kõrge kättesaadavus (high availability)

---

#### 1.3.3. CI/CD (Continuous Integration / Continuous Deployment)

**Automatiseeritud protsess**, mis:
1. **Testib** koodi automaatselt iga muudatuse korral
2. **Ehitab** (builds) rakenduse
3. **Paigaldab** (deploys) toodangusse

**Analoogia:** CI/CD on nagu autotöökoja konveier - iga osa läbib automaatse kvaliteedikontrolli ja jõuab lõpuks valmis autona väljale.

---

## 2. Hostingeri VPS Platvorm

### 2.1. Mis on VPS?

**VPS (Virtual Private Server)** on virtuaalserver, mis käitub nagu eraldi füüsiline server, aga on tegelikult osa suuremast füüsilisest serverist.

#### Analoogia: Korterelamu

- **Füüsiline server (dedicated server):** Omaette maja - kogu jõudlus on sinu käsutuses, aga kallis
- **VPS:** Korter korterelamus - sul on oma privaatne ruum, oma ressursid, aga jagad hoone infrastruktuuri teistega
- **Shared hosting:** Ühiselamu tuba - jagad ressursse kõigega, väga piiratud kontroll

---

### 2.2. Sinu Hostingeri VPS Parameetrid

Vaatame üle, mis ressursid sul on kasutada:

| Parameeter | Väärtus | Selgitus |
|------------|---------|----------|
| **vCPU tuumad** | 2 | Kaks virtuaalset protsessorituuma - piisav väikeseks kuni keskmiseks rakenduseks |
| **RAM** | 8 GB | Mälu - kriitilise tähtsusega Kubernetes jaoks (minimaalne soovitus) |
| **Kettaruum** | 100 GB NVMe | Kiire SSD-põhine salvestus - piisav arenduseks ja testiks |
| **Andmeedastus** | 8 TB/kuu | Väga suur - ei peaks kunagi otsa saama õppimise käigus |

---

### 2.3. Ressursside Planeerimine

#### 2.3.1. RAM Jaotus (8 GB)

Kuna meil on ainult 8 GB RAM-i, peame olema ressursside kasutamisel ettevaatlikud:

```
┌────────────────────────────────────────┐
│     8 GB RAM Jaotus                    │
├────────────────────────────────────────┤
│ Ubuntu OS + System:        ~1.5 GB     │
│ Kubernetes (K3s):          ~1.5 GB     │
│ PostgreSQL:                ~1-2 GB     │
│ Backend (Node.js) x3:      ~1.5 GB     │
│ Frontend (Nginx) x2:       ~100 MB     │
│ Monitoring (Prometheus):   ~500 MB     │
│ Varu (Buffer):             ~1 GB       │
└────────────────────────────────────────┘
```

**Soovitus:** Kasutame **K3s** (lightweight Kubernetes) standardse Kubernetes asemel, kuna see kasutab vähem ressursse.

---

#### 2.3.2. Ketta Ruumi Planeerimine (100 GB)

```
┌────────────────────────────────────────┐
│     100 GB NVMe Jaotus                 │
├────────────────────────────────────────┤
│ Ubuntu OS:                 ~10 GB      │
│ Docker images:             ~15 GB      │
│ PostgreSQL andmed:         ~20 GB      │
│ Application logs:          ~5 GB       │
│ Backups:                   ~20 GB      │
│ Vaba ruum:                 ~30 GB      │
└────────────────────────────────────────┘
```

---

### 2.4. Mis on Võimalik ja Mis Mitte

#### ✅ Võimalik Sellel Konfiguratsioonil

- Täisfunktsionaalne full-stack rakendus
- Docker ja Docker Compose
- K3s (lightweight Kubernetes)
- PostgreSQL andmebaas
- CI/CD pipeline
- Monitoring ja logging (kerged lahendused)
- 3-5 backend replica't
- 2-3 frontend replica't
- Development ja staging keskkonnad

#### ❌ Mitte Soovitav või Võimatu

- Suur toodangukoormus (production high-traffic)
- Paljud paralleelsed PostgreSQL replikad
- Raske monitoring (Elasticsearch + Kibana)
- Paljud paralleelsed build'id CI/CD-s
- GPU-nõudvad rakendused
- Suur andmeanalüütika

---

## 3. Arenduskeskkond: Zorin OS ja Ubuntu

### 3.1. Zorin OS (Sinu Töölaud)

**Zorin OS** on Ubuntu-põhine Linuxi distributsioon, mis on disainitud Windows kasutajatele lihtsamaks üleminekuks.

**Versioon:** Zorin OS 17 Core (põhineb Ubuntu 22.04 LTS)

**Miks Zorin OS on hea arenduseks:**
- ✅ Põhineb Ubuntu-l (suur kogukond ja tugi)
- ✅ Stabiilne ja kasutajasõbralik
- ✅ Kõik arendusriistad on kättesaadavad
- ✅ Hea hardware tugi (HP EliteBook)
- ✅ Pre-installed tööriistad

---

### 3.2. Ubuntu 24.04 LTS (VPS)

**Ubuntu 24.04 LTS (Noble Numbat)** on pikaajalise toega (Long Term Support) server-distributsioon.

**Miks Ubuntu 24.04 LTS:**
- ✅ **LTS:** 5 aastat turvauuendusi (kuni 2029)
- ✅ Suur kogukond ja dokumentatsioon
- ✅ Parim tugi Docker ja Kubernetes jaoks
- ✅ Stabiilne ja turvaline
- ✅ APT package manager (lihtne tarkvara paigaldamine)

---

### 3.3. Zorin OS vs. Ubuntu Server

| Aspekt | Zorin OS 17 (Töölaud) | Ubuntu 24.04 LTS (VPS) |
|--------|----------------------|------------------------|
| **Otstarve** | Arendusmasin | Produktsioonserver |
| **Kasutajaliides** | GNOME Desktop | Ainult käsurida (CLI) |
| **Paketihaldur** | APT | APT |
| **Kerneli Versioon** | 5.15 (Ubuntu 22.04) | 6.8 (Ubuntu 24.04) |
| **Python Versioon** | Python 3.10 | Python 3.12 |
| **Ressursid** | 16 GB RAM (su laptop) | 8 GB RAM (VPS) |

**Hea teada:** Kuna mõlemad põhinevad Ubuntu-l, on käsud ja tööriistad üldjuhul samad. Ainus suur erinevus on kasutajaliidese olemasolu.

---

## 4. Koolituskava Struktuur ja Eesmärgid

### 4.1. Õppimise Teekaart

Koolituskava on jaotatud **7 mooduliks** ja **25 peatükiks**:

```
MOODUL 1: Alused (Peat. 1-4)
    ↓
MOODUL 2: Backend (Peat. 5-8)
    ↓
MOODUL 3: Frontend (Peat. 9-11)
    ↓
MOODUL 4: Docker (Peat. 12-14)
    ↓
MOODUL 5: Kubernetes (Peat. 15-19)
    ↓
MOODUL 6: CI/CD (Peat. 20-21)
    ↓
MOODUL 7: Täiustatud (Peat. 22-25)
```

---

### 4.2. Peamised Õpieesmärgid

Selle koolituse lõpuks oskad:

#### Frontend
- ✅ Luua kaasaegseid veebirakendusi HTML5, CSS3 ja JavaScript abil
- ✅ Teha API kutseid ja töödelda vastuseid
- ✅ Luua kasutajasõbralikke liidese (responsive design)
- ✅ Implementeerida autentimist frontendis

#### Backend
- ✅ Luua RESTful API-sid Node.js ja Express.js-ga
- ✅ Ühenduda PostgreSQL andmebaasiga
- ✅ Implementeerida JWT autentimist
- ✅ Kirjutada turvalist koodi (OWASP Top 10)

#### Andmebaas
- ✅ Disainida andmebaasi skeeme
- ✅ Kirjutada SQL päringuid
- ✅ Optimeerida päringuid ja indekseid
- ✅ Teha backup-e ja restore-e

#### DevOps
- ✅ Luua Docker image'id ja konteinereid
- ✅ Kirjutada Docker Compose faile
- ✅ Paigaldada rakendusi Kubernetes-es
- ✅ Seadistada CI/CD pipeline-e

#### Turvalisus
- ✅ Kasutada SSL/TLS sertifikaate
- ✅ Hallata secrets turvaliselt
- ✅ Implementeerida network policies
- ✅ Skannida haavatavusi

---

### 4.3. Praktiline Projekt

Läbi koolituse ehitame **märkmete rakenduse** (Notes Application):

**Funktsionaalsus:**
- Kasutaja registreerimine ja sisselogimine
- Märkmete loomine, lugemine, uuendamine, kustutamine (CRUD)
- Märkmete kategooriad ja sildid (tags)
- Otsing ja filtreerimine
- Markdown tugi
- API dokumentatsioon (Swagger)

**Tehnoloogiad:**
- Frontend: HTML, CSS, Vanilla JavaScript
- Backend: Node.js + Express.js
- Andmebaas: PostgreSQL
- Konteinerisatsioon: Docker
- Orkestratsioon: Kubernetes (K3s)
- CI/CD: GitHub Actions

---

## 5. Vajalikud Tööriistad ja Eelteadmised

### 5.1. Eelteadmised (Prerequisites)

#### Minimaalsed Teadmised

**Vajalik:**
- ✅ Põhilised arvutikasutamise oskused
- ✅ Tekstiredaktori kasutamine
- ✅ Käsurea (terminal) põhikäsud
- ✅ Inglise keele lugemisoskus (dokumentatsioon)

**Soovitav (aga mitte vajalik):**
- 🔶 HTML/CSS põhitõed
- 🔶 Programmeerimise põhikontseptsioonid
- 🔶 Git versioonihalduse põhitõed
- 🔶 SQL põhitõed

**Hea teada:** Kui sulle on mõni teema täiesti uus, ära muretse! Kõike õpetame algusest peale.

---

### 5.2. Tööriistad Zorin OS-is

#### 5.2.1. Juba Paigaldatud

Zorin OS-il on juba paljud tööriistad olemas:

```bash
# Kontrolli paigaldatud versioone
python3 --version    # Python 3.10.x
git --version        # Git versioonihaldus
curl --version       # HTTP klient
```

#### 5.2.2. Paigaldatavad Tööriistad

Koolituse käigus paigaldame:

| Tööriist | Otstarve | Paigaldame |
|----------|----------|------------|
| **VS Code** | Koodiredaktor | Peatükk 2 |
| **Node.js** | JavaScript runtime | Peatükk 5 |
| **Docker** | Konteinerisatsioon | Peatükk 12 |
| **kubectl** | Kubernetes CLI | Peatükk 15 |
| **Postman** | API testimine | Peatükk 7 |

---

### 5.3. Tööriistad VPS-is

VPS-i paigaldame:

| Tööriist | Versioon | Otstarve |
|----------|----------|----------|
| **Docker** | Latest | Konteinerisatsioon |
| **K3s** | Latest | Kubernetes |
| **PostgreSQL** | 16 | Andmebaas |
| **Nginx** | Latest | Web server / Reverse proxy |
| **Git** | Latest | Versioonihaldus |

---

### 5.4. Veebiteenused

Vajame ka mõningaid veebiteenuseid:

| Teenus | Otstarve | Hind |
|--------|----------|------|
| **GitHub** | Koodi hoidla + CI/CD | Tasuta |
| **Docker Hub** | Docker image'id | Tasuta |
| **Hostinger VPS** | Server | Tasuline (juba olemas) |

---

## 6. Õpiväljundid

Pärast seda peatükki peaksid oskama:

- ✅ **Selgitada** full-stack arenduse olemust
- ✅ **Kirjeldada** veebirakenduse kolmekihilist arhitektuuri
- ✅ **Mõista** VPS-i olemust ja oma ressursse
- ✅ **Teada** koolituskava struktuuri ja eesmärke
- ✅ **Loetleda** vajalikke tööriistu ja tehnoloogiaid

---

## 7. Harjutused

### Harjutus 1.1: Keskkonnas Orienteerumine

**Eesmärk:** Tutvuda oma töökeskkonnaga

**Sammud:**

1. Ava terminal Zorin OS-is (`Ctrl + Alt + T`)

2. Kontrolli süsteemi infot:
```bash
# Operatsioonisüsteemi info
cat /etc/os-release

# CPU info
lscpu | grep "Model name"

# Mälu info
free -h

# Ketta ruum
df -h
```

3. Kontrolli paigaldatud tarkvara:
```bash
python3 --version
git --version
curl --version
```

4. Loo projektikataloog:
```bash
mkdir -p ~/projects/hostinger-course
cd ~/projects/hostinger-course
pwd
```

**Oodatav väljund:**
```
/home/janek/projects/hostinger-course
```

---

### Harjutus 1.2: Git Seadistamine

**Eesmärk:** Seadistada Git oma isiklike andmetega

**Sammud:**

1. Seadista oma nimi ja email:
```bash
git config --global user.name "Sinu Nimi"
git config --global user.email "sinu.email@example.com"
```

2. Kontrolli konfiguratsiooni:
```bash
git config --list | grep user
```

3. Seadista vaikimisi redaktor (valikuline):
```bash
# Kui eelistad nano't
git config --global core.editor nano

# Või kui eelistad vim'i
git config --global core.editor vim
```

**Oodatav väljund:**
```
user.name=Sinu Nimi
user.email=sinu.email@example.com
```

---

### Harjutus 1.3: Esimene GitHub Repositoorium

**Eesmärk:** Luua GitHub konto ja esimene repositoorium

**Sammud:**

1. Mine https://github.com ja loo konto (kui ei ole)

2. Loo uus repositoorium:
   - Nimi: `hostinger-course-project`
   - Kirjeldus: "Full-stack arenduse koolitusprojekt"
   - Avalik (public)
   - Lisa README.md

3. Klooni repositoorium oma masinasse:
```bash
cd ~/projects/hostinger-course
git clone https://github.com/sinu-kasutajanimi/hostinger-course-project.git
cd hostinger-course-project
```

4. Tee esimene muudatus:
```bash
echo "# Hostinger Full-Stack Koolitusprojekt" >> README.md
git add README.md
git commit -m "Esimene commit: README uuendatud"
git push origin main
```

**Kontrolli:** Mine GitHubis oma repositooriumisse ja vaata, kas muudatus on olemas.

---

### Harjutus 1.4: Ressursside Planeerimine

**Eesmärk:** Planeerida oma VPS-i ressursse

**Ülesanne:** Täida järgmine tabel:

| Komponent | Eeldatav RAM Vajadus | Eeldatav Ketta Vajadus |
|-----------|----------------------|------------------------|
| Ubuntu OS | 1.5 GB | 10 GB |
| Kubernetes (K3s) | _____ GB | _____ GB |
| PostgreSQL | _____ GB | _____ GB |
| Backend (Node.js) x3 | _____ GB | _____ GB |
| Frontend (Nginx) x2 | _____ MB | _____ MB |
| **KOKKU** | _____ GB | _____ GB |

**Kontrolli:** Kas su kokku arvutatud ressursid mahuvad 8 GB RAM-i ja 100 GB kettaruumi?

---

## 8. Kontrolliküsimused

### Teoreetilised Küsimused

1. **Mis on full-stack arendaja peamine eripära?**
   <details>
   <summary>Vastus</summary>
   Full-stack arendaja oskab töötada nii frontendi (kasutajaliides) kui backendi (serveri pool) ning andmebaasiga. Ta mõistab kogu rakenduse arhitektuuri.
   </details>

2. **Nimeta veebirakenduse kolm põhikihti.**
   <details>
   <summary>Vastus</summary>
   1. Frontend (Client) - Kasutajaliides
   2. Backend (Server) - Äriloogika ja API
   3. Database (Storage) - Andmete salvestamine
   </details>

3. **Mis on Docker ja miks me seda kasutame?**
   <details>
   <summary>Vastus</summary>
   Docker on konteinerisatsioonitehnoloogia, mis võimaldab pakkida rakendust koos kõigi sõltuvustega ühte isoleeritud konteinerisse. Kasutame seda, et tagada rakenduse järjepidev käitumine erinevates keskkondades (development, staging, production).
   </details>

4. **Mis vahe on VPS-il ja shared hosting-ul?**
   <details>
   <summary>Vastus</summary>
   VPS (Virtual Private Server) annab sulle eraldi virtuaalserveri oma ressurssidega ja täieliku kontrolliga. Shared hosting-u puhul jagad serveri ressursse ja keskkonda paljude teiste kasutajatega ning sul on piiratud kontroll.
   </details>

5. **Miks me kasutame K3s-i tavaliselt Kubernetes asemel 8 GB RAM-iga serveris?**
   <details>
   <summary>Vastus</summary>
   K3s on lightweight (kerge) Kubernetes distributsioon, mis kasutab oluliselt vähem ressursse kui täielik Kubernetes. See on optimeeritud väiksemate serverite ja edge computing jaoks, säilitades samal ajal Kubernetes põhifunktsionaalsuse.
   </details>

6. **Mis on REST API?**
   <details>
   <summary>Vastus</summary>
   REST (Representational State Transfer) API on arhitektuuristiil, mis võimaldab erinevatest rakendustel omavahel HTTP protokolli kaudu suhelda. See on nagu "keel", milles frontend ja backend omavahel räägivad.
   </details>

---

### Praktilised Küsimused

7. **Kui palju RAM-i on soovitav reserveerida Kubernetes (K3s) jaoks 8 GB süsteemis?**
   <details>
   <summary>Vastus</summary>
   Umbes 1.5 GB. K3s on optimeeritud väikesteks keskkondadeks ja vajab vähem ressursse kui täielik Kubernetes.
   </details>

8. **Milline käsk näitab Linux-is vaba mälu hulka?**
   <details>
   <summary>Vastus</summary>
   ```bash
   free -h
   ```
   `-h` lipp näitab tulemust inimloetavas formaadis (human-readable).
   </details>

9. **Kuidas kontrollida, kas Git on paigaldatud?**
   <details>
   <summary>Vastus</summary>
   ```bash
   git --version
   ```
   </details>

10. **Mis on .gitignore faili otstarve?**
    <details>
    <summary>Vastus</summary>
    .gitignore fail määrab, milliseid faile ja katalooge Git peaks ignoreerima (mitte jälgima). Näiteks node_modules/, .env failid, build kataloogid jne.
    </details>

---

## 9. Lisamaterjalid

### 📚 Soovitatud Lugemine

#### Full-Stack Arendus
- [MDN Web Docs](https://developer.mozilla.org/) - Parim ressurss veebitehnoloogiate õppimiseks
- [freeCodeCamp](https://www.freecodecamp.org/) - Tasuta interaktiivsed kursused
- [The Odin Project](https://www.theodinproject.com/) - Täielik full-stack õppekava

#### Docker ja Kubernetes
- [Docker Get Started](https://docs.docker.com/get-started/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [K3s Documentation](https://docs.k3s.io/)

#### PostgreSQL
- [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)
- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)

---

### 🎥 Video Ressursid

- **Traversy Media** (YouTube) - Full-stack tutorials
- **Academind** (YouTube) - Node.js ja Docker
- **TechWorld with Nana** (YouTube) - DevOps ja Kubernetes
- **Hussein Nasser** (YouTube) - Backend ja andmebaasid

---

### 🛠️ Kasulikud Tööriistad

#### Arendus
- **Visual Studio Code** - Koodiredaktor
- **Postman** - API testimine
- **DBeaver** - Andmebaasi haldus (GUI)

#### DevOps
- **Docker Desktop** - Docker haldus (GUI)
- **Lens** - Kubernetes IDE
- **k9s** - Kubernetes terminal UI

---

### 🌐 Kogukonnad

- **Stack Overflow** - Küsimused ja vastused
- **Dev.to** - Arendajate blogi platvorm
- **Reddit** - r/webdev, r/nodejs, r/docker, r/kubernetes
- **Discord** - Erinevad arenduskogukonnad

---

## Kokkuvõte

Selles peatükis said ülevaate:

✅ **Full-stack arenduse** olemusest ja arhitektuurist
✅ **Hostingeri VPS** ressurssidest ja võimalustest
✅ **Zorin OS ja Ubuntu** rollist arendusprotsessis
✅ **Koolituskava struktuurist** ja eesmärkidest
✅ **Vajalikest tööriistadest** ja eelteadmistest

---

## Järgmine Peatükk

**Peatükk 2: VPS Esmane Seadistamine**

Järgmises peatükis:
- Loome SSH võtmepaarid
- Ühendume VPS-iga
- Seadistame põhilise turvalisuse (firewall, fail2ban)
- Paigaldame baastööriistad

---

## Tagasiside ja Küsimused

Kui sul on küsimusi või soovitusi selle peatüki kohta:
- Loo issue GitHubis: `hostinger-course-project/issues`
- Või märgi üles oma küsimused eraldi faili

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-14
**Järgmine uuendus:** Peatükk 2 lisamine
