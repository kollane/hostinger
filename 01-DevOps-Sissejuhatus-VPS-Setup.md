# Peatükk 1: DevOps Sissejuhatus ja VPS Setup

**Kestus:** 3 tundi
**Tase:** Algaja
**Eeldused:** Baasteadmised arvutitest ja internetist
**Labid:** Lab 0 - VPS Setup (detailsed juhised)

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist mõistad:

1. ✅ DevOps kultuuri ja selle tähtsust tänapäevases IT-s
2. ✅ Infrastructure as Code (IaC) kontseptsiooni ja eeliseid
3. ✅ VPS, Cloud ja On-Premise lahenduste erinevusi
4. ✅ Turvalise serveri juurdepääsu põhimõtteid
5. ✅ Firewall'i rolli süsteemi turvalisuses
6. ✅ Kasutajahalduse ja õiguste tähtsust
7. ✅ Teenuste haldamise põhimõtteid

---

## 🎯 1. DevOps Filosoofia

### 1.1 Traditsioonilise IT Probleem

Enne DevOps'i domineeris organisatsioonides **siilomudel** (silo model): arendajad ja operaatorid töötasid eraldi, erinevate eesmärkidega.

**Arendajad (Dev):** Eesmärk on luua uusi funktsionaalsusi kiiresti.
**Operaatorid (Ops):** Eesmärk on hoida süsteem stabiilsena.

See tekitas **põhimõttelise konflikti:**
- Uued funktsioonid = muudatused = potentsiaalne ebastabiilsus
- Arendajad tahavad deploy'da tihti
- Operaatorid tahavad muudatusi harva

**Tagajärjed:**
- Pikad release tsüklid (kuud või isegi aastad)
- "Üle seina viskamine" - arendajad annavad koodi üle, Ops peab hakkama saama
- Vastastikused süüdistused vigade korral
- Käsitsi protsessid, mis on vigu täis
- Aeglane reageerimine probleemidele

### 1.2 DevOps Lahendus

DevOps on **kultuuriline liikumine**, mis ühendab arenduse ja operatsioonid üheks meeskonnaks ühise eesmärgiga: **kiire, kvaliteetne ja turvaline tarkvara kohaletoimetamine**.

**CAMS Raamistik:**

**Culture (Kultuur):**
Koostöö, usalduus, jagatud vastutus. "Blameless postmortems" - kui midagi läheb valesti, õpime sellest, ei süüdista inimesi.

**Automation (Automatiseerimine):**
Kõik, mida saab automatiseerida, PEAKS olema automatiseeritud. Build, test, deploy, monitoring, scaling.

**Measurement (Mõõtmine):**
"What gets measured gets improved." Jälgime metrikaid, logisid, kasutaja tagasisidet.

**Sharing (Jagamine):**
Teadmiste ja kogemuste jagamine meeskonnas. Dokumentatsioon, pair programming, knowledge sharing sessions.

### 1.3 DevOps Administraatori Roll Selles Maailmas

DevOps administraator ei ole lihtsalt "süsteemiadministraator uues kuues". See roll nõuab:

**Infrastruktuuri haldamist kui koodi:**
Serverid, võrgud, load balancerid - kõik kirjeldatakse koodiga (YAML, Terraform), mitte ei seadistata käsitsi. See tähendab versionikontrolli, code review'd, automatiseeritud testimist.

**Orkestreerimise mõistmist:**
Kuidas hallata sadu või tuhandeid konteinereid? Kuidas tagada, et kui üks server kukub välja, rakendus jätkab töötamist?

**Monitoring ja observability:**
Mitte lihtsalt "kas server töötab", vaid "kuidas rakendus käitub, kus on kitsaskohad, mida kasutajad teevad".

**Security automation:**
Turvalisus ei ole afterthought, vaid built-in. Secrets management, network policies, image scanning.

**Continuous improvement:**
Pidev õppimine, uute tööriistade katsetamine, protsesside optimeerimine.

---

## 🏗️ 2. Infrastructure as Code (IaC)

### 2.1 Mis On IaC ja Miks See On Revolutsiooniline?

Traditsiooniline lähenemine: sisene serverisse SSH kaudu, käivita käsud käsitsi, muuda konfiguratsioonifaile vim'iga, tee screenshot, et meeles pidada, mida tegid. Korda teises serveris. Ja kolmandas. Ja neljandas...

**IaC põhimõte:** Infrastruktuur kirjeldatakse koodina, mida saab:
- Versiooni hallata (Git)
- Review'da (pull requests)
- Testida (automated tests)
- Korrata (reproducible)
- Rollback'ida (kui midagi läheb valesti)

**Näide kontseptuaalselt:**
Traditsiooniline viis: "Logi sisse, installi Nginx, seadista port 80, kopeeri SSL sertifikaat..."
IaC viis: "Kirjelda YAML failis: 'Tahan Nginx teenust, port 80, SSL enabled'. Käivita üks käsk. Done."

**IaC eelised:**

**Reproducibility:** Sama kood toodab sama tulemuse alati. Ei ole "aga minu masinas töötab" probleemi.

**Version control:** Git hoiab kõike. Saad vaadata, kes, millal, mida muutis. Saad tagasi kerida.

**Documentation as code:** Kood ON dokumentatsioon. Kui keegi tahab teada, kuidas infrastruktuur töötab, vaata koodi.

**Testability:** Saad testida infrastruktuuri muudatusi enne production'i. Test environment = kopeeri sama kood.

**Collaboration:** Code review'd, approval process, mitme inimese panus.

### 2.2 IaC Tööriistad Maastikul

**Konfiguratsioonihaldus (Configuration Management):**
Ansible, Chef, Puppet - serveri seadistamine (installi tarkvara, seadista failid).

**Provisioneerimine (Provisioning):**
Terraform, Pulumi - infrastruktuuri loomine (serverid, võrgud, cloud ressursid).

**Orkestratsioon (Orchestration):**
Kubernetes, Docker Compose - konteinerite haldamine ja orkestratsioon.

**CI/CD:**
GitHub Actions, GitLab CI, Jenkins - automatiseerimine.

Selles koolituses keskendume **konteinerite orkestratsioonile** (Docker, Kubernetes), mis on 2025. aasta DevOps'i tuum.

---

## 🖥️ 3. VPS, Cloud ja On-Premise - Õige Valiku Tegemine

### 3.1 Mis On VPS?

Virtual Private Server - virtuaalserver, mis jagab füüsilist riista teiste VPS'idega, kuid on isoleeritud. Saad root access'i, installid mida tahad, konfigureed kuidas tahad.

**VPS tugevused:**
- Fikseeritud hind (ennustatav eelarve)
- Lihtne (SSH sisse, apt install, done)
- Hea õppimiseks ja väikestele projektidele
- Root access = täielik kontroll

**VPS piirangud:**
- Skaleerumine piiratud (kui vajad rohkem võimsust, uuenda VPS plaani või lisa uus server)
- Single point of failure (kui VPS kukub välja, kõik on maas)
- Käsitsi haldamine (sina vastutad kõige eest)

### 3.2 Cloud (IaaS) - AWS, Azure, GCP

Cloud on "VPS steroididel". API-põhine, infinite scalability, pay-as-you-go.

**Miks cloud?**

**Elasticity:** Vaja rohkem servereid? API call, 30 sekundit, done. Ei vaja enam? Delete, maksa ainult selle aja eest, kui kasutasid.

**Managed services:** RDS (database as a service), EKS (Kubernetes as a service), S3 (storage). Ei pea ise PostgreSQL'i tuunima, backupe tegema - provider teeb.

**Global reach:** Tahan serveid USAs, Euroopas, Aasias? Mõne klikiga.

**Disadvantages:**
- Hind (võib olla kallis, kui ei optimeeri)
- Komplekssus (tuhandeid teenuseid, keeruline pricing)
- Vendor lock-in (raske migreerida teisele providerile)

**Millal kasutada:** Enterprise projektid, mis vajavad scalability't, high availability'd, global presence.

### 3.3 On-Premise

Oma füüsilised serverid oma serverruumis.

**Miks keegi seda veel teeb?**

**Compliance:** Pangad, tervishoiusüsteemid, valitsusasutused - ranged andmekaitse nõuded.

**Scale:** Kui oled Google'i suurune, on odavam oma data center kui cloud.

**Control:** 100% kontroll kõige üle.

**Disadvantages:** Suur algsinvesteering, vajad serverruumi, jahutust, IT personali riista haldamiseks, aeglane skaleerumine.

### 3.4 Meie Valik: VPS Õppimiseks, Põhimõtted Kehtivad Kõikjal

Koolituses kasutame VPS'i, sest:
- Lihtne alustada
- Odav
- Annab täielik

u kontrolli (õppimine)
- **KUID:** Kõik, mida õpid, kehtib ka cloud'is ja on-premise'is

Docker on Docker, Kubernetes on Kubernetes - ei ole vahet, kas töötad VPS'is, AWS'is või oma serverruumis.

---

## 🔐 4. Turvalisus: SSH, Firewalls, Kasutajahaldus

### 4.1 Miks Turvalisus On DevOps'i Osa?

**DevSecOps** - security ei ole afterthought, vaid built-in.

Traditsiooniline: "Teeme rakenduse valmis, siis küsime security teamilt, kas OK."
DevSecOps: "Security on osa arendusest algusest peale."

### 4.2 SSH - Turvalist Ligipääsu Mõistmine

**Probleem:** Kui sinu server on internetis, siis tuhandeid botte proovivad SSH parooli ära arvata. Brute force attack.

**Lahendus: SSH võtmete autentimine**

**Kontseptsioonid:**

**Public-key cryptography:** Sul on kaks võtit - private (saladus) ja public (võid jagada). Kui midagi on encrypted public key'ga, saab dekryptida ainult private key'ga.

**SSH võtmete autentimine:**
1. Genererid võtmepaari (private + public)
2. Public key paned serverisse
3. Kui ühendad, server küsib: "Tõesta, et sul on private key"
4. Sinu SSH client tõestab (matemaatika)
5. Ühendus lubatud

**Miks see on parem kui parool?**
- Private key ei lähe kunagi üle võrgu (ei saa sniff'ida)
- Brute force on praktiliselt võimatu (2048-bit või 256-bit võti)
- Võid keelata parooli autentimise täielikult

**SSH serveri turvalisuse parandamine:**

**PermitRootLogin no** - Root login SSH kaudu on julgeolekurisk. Kui keegi saab root access'i, on kogu server kompromiteeritud.

**PasswordAuthentication no** - Keela paroolid, luba ainult võtmed.

**Port change (valikuline)** - Vaikimisi port 22, kuid saad muuta (nt 2222). Vähendab bot'ide  traffic'ut, kuid ei ole "real security" (security through obscurity).

📖 **Praktika:** Labor 0, Harjutus 1-2 - SSH võtmete genereerimine ja seadistamine

### 4.3 Firewall - Võrguliikluse Kontroll

**Mis on firewall?** Värav, mis otsustab, milline võrguliiklus on lubatud ja milline mitte.

**UFW (Uncomplicated Firewall) põhimõte:**

**Default policy:** Keela kogu sissetulev liiklus, luba väljuv.

Miks? Kui sa ei luba eksplitsiitselt, siis ei ole ligipääsu. Defense in depth.

**Reeglid:** "Luba SSH (port 22)" - ainult see on avatud. Kõik muu blokeeritud.

**Miks see on kriitiline?**
Kui sul on PostgreSQL port 5432 avatud internetile ja nõrk parool, keegi leiab selle üles ja logib sisse. Firewall on esimene kaitsekiht.

**Firewall ei ole ainuke kaitse:** Defense in depth - firewall + tugev autentimine + encryption + monitoring.

📖 **Praktika:** Labor 0, Harjutus 3 - UFW seadistamine

### 4.4 Kasutajahaldus ja Õigused

**Miks me ei kasuta root'i igapäevaseks tööks?**

**Root = superuser = täielik kontroll.** Üks viga (`rm -rf /`) ja kogu süsteem on kadunud.

**Least Privilege Principle:** Anna kasutajale ainult need õigused, mida ta vajab. Mitte rohkem.

**sudo mehhanism:**
Tavaline kasutaja teeb igapäevast tööd. Kui vajab admin õigusi, kasutab `sudo` (Super User DO). Iga sudo käsk logitakse - auditability.

**Miks see on parem?**
- Saad kontrollida, kes mida teeb
- Logid näitavad, kes millal sudo kasutav (accountability)
- Väiksem risk juhuslikuks erroriks
- Multi-user environment: erinevad kasutajad, erinevad õigused

📖 **Praktika:** Labor 0, Harjutus 4 - Kasutajate loomine ja sudo konfig

### 4.5 Systemd - Teenuste Haldamine

**Mis on systemd?** Linux init süsteem - haldab, milliseid teenuseid käivitatakse, kuidas, millal.

**Miks see on oluline DevOps'is?**

**Service management:** Docker, Nginx, PostgreSQL - kõik on systemd teenused. Pead teadma, kuidas neid käivitada, peatada, enableda.

**Boot sequence:** Mis käivitub automaatselt, kui server restartib? systemd otsustab.

**Dependency management:** Service A vajab Service B'd. systemd teab seda ja käivitab õiges järjekorras.

**Logging:** journalctl - systemd logid. Kõik teenused logivalad sinna.

**Kontseptsioonid:**

**Service unit:** Fail, mis kirjeldab teenust. Kus binary asub, kuidas käivitada, mis on dependencies.

**Enable vs Start:**
`start` = käivita kohe
`enable` = käivita boot'imisel automaatselt

**Restart policy:** Kui teenus crashib, kas restart'ida automaatselt? Systemd saab seda.

📖 **Praktika:** Labor 0, Harjutus 5-6 - Systemd teenuste haldamine

---

## 🎓 5. Mida Sa Õppisid?

### Kontseptuaalsed Teadmised

**DevOps kultuur:** Miks DevOps on tekkinud, mis probleemi see lahendab. CAMS raamistik. DevOps administraatori roll.

**Infrastructure as Code:** Miks infrastruktuur kui kood on revolutsiooniline. Reproducibility, version control, testability, collaboration.

**VPS vs Cloud vs On-Premise:** Iga lähenemise tugevused, nõrkused, kasutusviisid. Miks me õpime VPS'il, aga põhimõtted kehtivad kõikjal.

**Turvaline juurdepääs:** SSH võtmete autentimine, miks see on parem kui paroolid. Public-key cryptography põhimõte.

**Firewall:** Default deny, explicit allow. Defense in depth.

**Kasutajahaldus:** Least privilege principle. Root vs tavaline kasutaja + sudo.

**Systemd:** Teenuste haldamine, boot sequence, logging.

### Praktilised Oskused

Praktilised oskused omandatakse **Labor 0** läbimise käigus:
- VPS setup ja initial configuration
- SSH võtmete genereerimine ja konfigureerimine
- UFW firewall'i seadistamine
- Kasutajate haldamine ja sudo konfig
- Systemd teenuste käivitamine ja monitoorimine

📁 **Labori asukoht:** `labs/00-vps-setup-lab/`

---

## 🚀 6. Järgmised Sammud

**Peatükk 2: Linux Põhitõed DevOps Kontekstis**
Failisüsteem, protsessid, võrk, logid - kõik DevOps administraatori perspektiivist.

**Peatükk 3: Git DevOps Töövoos**
Version control, GitOps, Infrastructure as Code repositories.

**Peatükk 4: Docker Põhimõtted** 🐳
Konteinerite maailm algab - see on meie DevOps teekonna tuum!

---

## 📖 Lisamaterjalid

**Soovitatud lugemine:**
- "The Phoenix Project" - DevOps põhimõtted romaani vormis
- "The DevOps Handbook" - praktiline juhend
- [DevOps Roadmap 2025](https://roadmap.sh/devops) - skill tree

**Lisapeatükid:**
- `LISA-PEATUKK-Cloud-Providers.md` - IaaS/PaaS/SaaS, AWS vs Azure vs GCP
- `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` - 2025 best practices

---

## ✅ Kontrolli Ennast

Enne järgmisele peatükile liikumist, veendu et mõistad:

- [ ] DevOps kultuuri ja CAMS põhimõtteid
- [ ] Miks Infrastructure as Code on oluline
- [ ] VPS, Cloud ja On-Premise erinevusi
- [ ] SSH võtmete autentimise kontseptsiooni
- [ ] Firewall'i rolli turvalisuses
- [ ] Kasutajahalduse ja sudo tähtsust
- [ ] Systemd teenuste haldamise põhimõtteid
- [ ] Oled läbinud Labor 0 (VPS Setup)

**Kui kõik on ✅, oled valmis Peatükiks 2!** 🚀

---

**Peatükk 1 lõpp**
**Järgmine:** Peatükk 2 - Linux Põhitõed DevOps Kontekstis

**Õnnitleme!** Oled astunud esimese sammu DevOps administraatori teekonnale! 🎉
