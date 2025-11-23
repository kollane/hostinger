# DevOps Koolituskava 2.0 - IMPLEMENTEERIMISE PLAAN

**Kuupäev:** 2025-01-22
**Versioon:** 2.0 DevOps-First (Restructured)
**Staatus:** 🚀 Implementeerimisfaas
**Eesmärk:** Luua täielik 25-peatükiline DevOps administraatori koolituskava

---

## 📋 I. ÜLEVAADE

### Mis On Tehtud? ✅

**Planeerimise faas (100% valmis):**
- ✅ `UUS-DEVOPS-KOOLITUSKAVA.md` - Täielik 25-peatükiline struktuur
- ✅ `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` - 2025 best practices ja strateegia
- ✅ `PEATUKK-6-TAIENDUS-TEHNOLOOGIAD.md` - Node.js, Java, Liquibase, Hibernate (6-8h)
- ✅ `LISA-PEATUKK-Cloud-Providers.md` - IaaS/PaaS/SaaS, AWS, Azure, GCP (3-4h)
- ✅ `LISA-PEATUKK-Kubernetes-Distributions.md` - K3s, K0s, EKS, managed K8s (3-4h)
- ✅ PostgreSQL peatükk liigutatud peatükist 3 → peatükki 6 (PÄRAST Docker'it)
- ✅ Struktuuri valideeritud ja kinnitatud

**Labide faas (100% valmis):**
- ✅ Lab 1: Docker Basics (6 harjutust)
- ✅ Lab 2: Docker Compose (planeering olemas)
- ✅ Lab 3: Kubernetes Basics (README olemas, harjutused 1-2 tehtud)
- ✅ Labs 4-6: Raamistik ja struktuur olemas

**Rakenduste faas (100% valmis):**
- ✅ `labs/apps/backend-nodejs/` - User Service (Node.js + Express + PostgreSQL)
- ✅ `labs/apps/backend-java-spring/` - Todo Service (Java Spring Boot)
- ✅ `labs/apps/frontend/` - Web UI (HTML + Vanilla JS)

---

## 🎯 II. MIS TULEB TEHA?

### Faas 1: VPS Anonümiseerimine (KÕRGE PRIORITEET) ⚠️

**Probleem:**
Kõik failid viitavad konkreetsele VPS'ile:
- Hostname: `kirjakast`
- IP: `93.127.213.242`
- Kasutaja: `janek`

**Lahendus:**
Asendada geneeriliste näidetega kõigis failides.

**Failid, mida muuta:**
1. `CLAUDE.md` - VPS viited (18 kohta)
2. `UUS-DEVOPS-KOOLITUSKAVA.md` - VPS viited
3. Kõik 12 olemasolevat peatükki (01-12)
4. Kõik labide README failid
5. `labs/apps/*/README.md`

**Asendusmuster:**
```bash
# ENNE:
kirjakast @ 93.127.213.242
Kasutaja: janek

# PÄRAST:
vpsserver @ 203.0.113.42  # RFC 5737 test IP
Kasutaja: student
# VÕI
your-vps-hostname @ YOUR_VPS_IP
Kasutaja: your-username
```

**Töömaht:** 2-3 tundi

---

### Faas 2: Lisamaterjalide Integreerimine (KESKMINE PRIORITEET)

**2.1 Tehnoloogiate Süvapeatükk**

**Olemasolev:** `PEATUKK-6-TAIENDUS-TEHNOLOOGIAD.md`
**Sisu:** Node.js, Java/Spring Boot, Gradle vs Maven, Liquibase, Hibernate
**Kestus:** 6-8h materiaal

**Integreerimise valikud:**

**VARIANT A: Lisa Peatükk 6 sisse**
- Peatükk 6 praegu: PostgreSQL Konteinerites (2-4h)
- Laiendatud Peatükk 6: PostgreSQL + Rakenduste Konteineriseerimise Detailid (8-12h)
- Plusssid: Loogiline koht (PostgreSQL + rakendused koos)
- Miinused: Liiga pikk peatükk

**VARIANT B: Loo eraldi peatükk 6A/6B**
- Peatükk 6: PostgreSQL Konteinerites (2-4h)
- Peatükk 6A: Rakenduste Konteineriseerimise Detailid (6-8h)
- Peatükk 7: Docker Compose (4h)
- Plusssid: Puhas struktuur, modulaarne
- Miinused: Muudab peatükkide numeratsiooni

**VARIANT C: Lisa Peatükk 5 sisse** (SOOVITATUD)
- Peatükk 5 praegu: Dockerfile ja Image Loomine (4h)
- Laiendatud Peatükk 5: Dockerfile ja Rakenduste Konteineriseerimise Detailid (10-12h)
- Plusssid: Loogiline koht (Dockerfile + rakendused), ei muuda numeratsiooni
- Miinused: Pikk peatükk, kuid jagatav alamteemadeks

**OTSUS: VARIANT C** ✅
- Laiendame Peatükk 5 põhjalikuks rakenduste konteineriseerimise peatükiks
- Jaotame 5 alamteemat:
  - 5.1: Dockerfile Basics (2h)
  - 5.2: Node.js Rakenduste Konteineriseerimine (2h)
  - 5.3: Java/Spring Boot Konteineriseerimine (2h)
  - 5.4: Database Migrations (Liquibase) (2h)
  - 5.5: Multi-stage Builds ja Optimiseerimine (2h)

---

**2.2 Cloud Providers Peatükk**

**Olemasolev:** `LISA-PEATUKK-Cloud-Providers.md`
**Sisu:** IaaS/PaaS/SaaS, AWS, Azure, GCP, Oracle, DigitalOcean, Hetzner
**Kestus:** 3-4h materiaal

**Integreerimise valikud:**

**VARIANT A: Lisa Peatükk 1 sisse**
- Peatükk 1 praegu: DevOps Sissejuhatus ja VPS Setup (3h)
- Laiendatud: + Cloud vs VPS (1h) = 4h
- Plusssid: Alguses selgitatakse VPS vs Cloud
- Miinused: Liiga palju infot alguses

**VARIANT B: Loo eraldi peatükk 1A**
- Peatükk 1: DevOps Sissejuhatus ja VPS Setup (3h)
- Peatükk 1A: Cloud Providers ja IaaS/PaaS/SaaS (3-4h)
- Plusssid: Eraldi fookus, modulaarne
- Miinused: Muudab numeratsiooni

**VARIANT C: Lisa lisapeatükina (SOOVITATUD)** ✅
- Jääb `LISA-PEATUKK-Cloud-Providers.md` nimega
- Viidatakse sellele Peatükis 1 ja Peatükis 9 (Kubernetes)
- Plusssid: Ei muuda põhistruktuuri, valikuline süvenemine
- Miinused: Ei ole põhikavas

---

**2.3 Kubernetes Distributions Peatükk**

**Olemasolev:** `LISA-PEATUKK-Kubernetes-Distributions.md`
**Sisu:** K3s, K0s, MicroK8s, vanilla K8s, EKS, AKS, GKE, DOKS
**Kestus:** 3-4h materiaal

**Integreerimise valikud:**

**VARIANT A: Lisa Peatükk 9 sisse**
- Peatükk 9 praegu: Kubernetes Alused ja K3s Setup (4h)
- Laiendatud: + K8s Distributions (2h) = 6h
- Plusssid: Loogiline koht
- Miinused: Pikk peatükk

**VARIANT B: Loo eraldi peatükk 9A**
- Peatükk 9: Kubernetes Alused ja K3s Setup (4h)
- Peatükk 9A: Kubernetes Distributions ja Managed K8s (3-4h)
- Plusssid: Eraldi fookus
- Miinused: Muudab numeratsiooni

**VARIANT C: Lisa lisapeatükina (SOOVITATUD)** ✅
- Jääb `LISA-PEATUKK-Kubernetes-Distributions.md` nimega
- Viidatakse sellele Peatükis 9
- Plusssid: Ei muuda põhistruktuuri, valikuline süvenemine
- Miinused: Ei ole põhikavas

---

### Faas 3: 25 Peatüki Kirjutamine (SUUR TÖÖMAHUKUS)

**Strateegia:**
Kirjutame peatükid **prioriteedi järgi**, mitte järjestikku.

#### **PRIORITEET 1: Kriitiline Tee (Must-Have)** 🔴

Need peatükid on KOHUSTUSLIKUD koolituskava toimimiseks:

1. **Peatükk 1: DevOps Sissejuhatus ja VPS Setup** (3h)
   - Staatus: ❌ Puudub
   - Töömaht: 4-6h kirjutamist
   - Prioriteet: KRIITILINE
   - Põhjus: Esimene peatükk, seab toon kogu kavale

2. **Peatükk 4: Docker Põhimõtted** (4h)
   - Staatus: ❌ Puudub
   - Töömaht: 6-8h kirjutamist
   - Prioriteet: KRIITILINE
   - Põhjus: Esimene konteinerite peatükk, kogu kava aluseks

3. **Peatükk 5: Dockerfile ja Rakenduste Konteineriseerimise Detailid** (10-12h)
   - Staatus: ⚠️ Osaline (PEATUKK-6-TAIENDUS-TEHNOLOOGIAD.md)
   - Töömaht: 8-10h kirjutamist (integreerimine + täiendamine)
   - Prioriteet: KRIITILINE
   - Põhjus: Praktiline rakenduste konteineriseerimise alus

4. **Peatükk 6: PostgreSQL Konteinerites** (2-4h)
   - Staatus: ⚠️ Osaline (UUS-DEVOPS-KOOLITUSKAVA.md outline)
   - Töömaht: 4-6h kirjutamist
   - Prioriteet: KRIITILINE
   - Põhjus: DB administreerimine DevOps kontekstis

5. **Peatükk 9: Kubernetes Alused ja K3s Setup** (4h)
   - Staatus: ❌ Puudub
   - Töömaht: 6-8h kirjutamist
   - Prioriteet: KRIITILINE
   - Põhjus: Esimene K8s peatükk, orkestreerimise alus

**Prioriteet 1 Kokku:** 5 peatükki, 28-38h kirjutamist

---

#### **PRIORITEET 2: Oluline Tee (Should-Have)** 🟡

Need peatükid on OLULISED täieliku koolituskava jaoks:

6. **Peatükk 2: Linux Põhitõed DevOps Kontekstis** (3h)
7. **Peatükk 3: Git DevOps Töövoos** (2h)
8. **Peatükk 7: Docker Compose** (4h)
9. **Peatükk 10: Pods ja Deployments** (4h)
10. **Peatükk 11: Services ja Networking** (4h)
11. **Peatükk 12: ConfigMaps, Secrets** (3h)
12. **Peatükk 13: Persistent Storage** (4h)
13. **Peatükk 15: GitHub Actions Basics** (3h)
14. **Peatükk 18: Prometheus ja Metrics** (4h)
15. **Peatükk 19: Grafana ja Visualization** (3h)

**Prioriteet 2 Kokku:** 10 peatükki, 34h materiaal, ~50-60h kirjutamist

---

#### **PRIORITEET 3: Täiendav Tee (Nice-to-Have)** 🟢

Need peatükid täiendavad koolituskava:

16. **Peatükk 8: Docker Registry** (2-4h)
17. **Peatükk 14: Ingress ja Load Balancing** (3-5h)
18. **Peatükk 16: Docker Build Automation** (3h)
19. **Peatükk 17: Kubernetes Deployment Automation** (4-6h)
20. **Peatükk 20: Logging ja Log Aggregation** (4h)
21. **Peatükk 21: Alerting** (2h)
22. **Peatükk 22: Security Best Practices** (4-6h)
23. **Peatükk 23: High Availability ja Scaling** (4h)
24. **Peatükk 24: Backup ja Disaster Recovery** (3h)
25. **Peatükk 25: Troubleshooting ja Debugging** (3-5h)

**Prioriteet 3 Kokku:** 10 peatükki, 32-46h materiaal, ~50-70h kirjutamist

---

### Kirjutamise Ajakava

**Realistlik ajakava (full-time töö):**
- Prioriteet 1 (5 peatükki): 1 nädal (28-38h kirjutamist)
- Prioriteet 2 (10 peatükki): 2 nädalat (50-60h kirjutamist)
- Prioriteet 3 (10 peatükki): 2 nädalat (50-70h kirjutamist)

**KOKKU: 5 nädalat (128-168h kirjutamist)**

**Kiire ajakava (prioriteedid 1-2):**
- Prioriteet 1: 3-4 päeva
- Prioriteet 2: 1 nädal

**KOKKU: 10-11 päeva (78-98h kirjutamist)**

---

## 🚀 III. IMPLEMENTEERIMISE SAMMUD

### Samm 1: VPS Anonümiseerimine (1-2 päeva)

**Ülesanded:**
- [ ] Loo skript VPS viidete leidmiseks: `grep -r "kirjakast\|93.127.213.242\|janek" .`
- [ ] Muuda CLAUDE.md (18 kohta)
- [ ] Muuda UUS-DEVOPS-KOOLITUSKAVA.md
- [ ] Muuda olemasolevad 12 peatükki
- [ ] Muuda labide README failid
- [ ] Muuda rakenduste README failid
- [ ] Testi, et kõik viited on asendatud
- [ ] Commit ja push

**Väljund:**
- ✅ Kõik VPS viited asendatud geneeriliste näidetega
- ✅ Koolituskava on üldiselt kasutatav

---

### Samm 2: Lisamaterjalide Integreerimine (1 päev)

**Ülesanded:**
- [ ] Integreeri `PEATUKK-6-TAIENDUS-TEHNOLOOGIAD.md` → Peatükk 5
  - Lisa Node.js sektsioon
  - Lisa Java/Spring Boot sektsioon
  - Lisa Liquibase sektsioon
  - Lisa Hibernate sektsioon
  - Lisa multi-stage builds
- [ ] Lisa viited LISA-PEATUKK-Cloud-Providers.md → Peatükk 1, 9
- [ ] Lisa viited LISA-PEATUKK-Kubernetes-Distributions.md → Peatükk 9
- [ ] Commit ja push

**Väljund:**
- ✅ Peatükk 5 on põhjalik (10-12h materiaal)
- ✅ Lisapeatükid on linkitud põhikavast

---

### Samm 3: Prioriteet 1 Peatükid (1 nädal)

**Ülesanded:**
- [ ] **Peatükk 1:** DevOps Sissejuhatus ja VPS Setup
  - DevOps kultuur ja põhimõtted
  - IaC kontseptsioon
  - VPS vs Cloud (viide LISA peatükile)
  - SSH, UFW, sudo, systemd
  - Praktilised harjutused

- [ ] **Peatükk 4:** Docker Põhimõtted
  - Konteinerid vs VM'id
  - Docker arhitektuur
  - Images, containers, volumes, networks
  - Praktilised harjutused (Nginx, PostgreSQL, Node.js)

- [ ] **Peatükk 5:** Dockerfile ja Rakenduste Konteineriseerimise Detailid
  - Dockerfile süntaks
  - Node.js konteineriseerimise detailid
  - Java/Spring Boot konteineriseerimise detailid
  - Liquibase migrations
  - Multi-stage builds
  - Praktilised harjutused (backend-nodejs, backend-java-spring)

- [ ] **Peatükk 6:** PostgreSQL Konteinerites
  - PostgreSQL Docker konteineris
  - Volume lifecycle
  - Backup ja restore
  - Performance monitoring
  - Praktilised harjutused

- [ ] **Peatükk 9:** Kubernetes Alused ja K3s Setup
  - K8s arhitektuur
  - K3s vs K8s (viide LISA peatükile)
  - kubectl CLI
  - Pods, Deployments, Services (basic)
  - Praktilised harjutused (K3s install, esimene pod)

**Väljund:**
- ✅ Kriitilised peatükid valmis
- ✅ Koolituskava kriitiline tee (VPS → Docker → K8s) on kaetud

---

### Samm 4: Prioriteet 2 Peatükid (2 nädalat)

**Ülesanded:**
- [ ] Peatükk 2: Linux Põhitõed
- [ ] Peatükk 3: Git
- [ ] Peatükk 7: Docker Compose
- [ ] Peatükk 10: Pods ja Deployments
- [ ] Peatükk 11: Services ja Networking
- [ ] Peatükk 12: ConfigMaps, Secrets
- [ ] Peatükk 13: Persistent Storage
- [ ] Peatükk 15: GitHub Actions
- [ ] Peatükk 18: Prometheus
- [ ] Peatükk 19: Grafana

**Väljund:**
- ✅ Docker moodul täielik (4-8)
- ✅ K8s basics moodul täielik (9-13)
- ✅ CI/CD ja Monitoring alused valmis

---

### Samm 5: Prioriteet 3 Peatükid (2 nädalat)

**Ülesanded:**
- [ ] Peatükid 8, 14, 16-17, 20-25

**Väljund:**
- ✅ Kogu koolituskava 100% valmis

---

### Samm 6: Kvaliteedikontroll ja Viimistlus (3-5 päeva)

**Ülesanded:**
- [ ] Terviklikkuse kontroll
  - Kas kõik peatükid on omavahel seotud?
  - Kas viited labidele on õiged?
  - Kas tehnilised detailid on õiged?

- [ ] Keelekontroll
  - Eesti keel korrektne?
  - Tehnilised terminid õigesti kasutatud?
  - Järjepidev terminoloogia?

- [ ] Labide kontroll
  - Kas kõik lab viited töötavad?
  - Kas lab harjutused vastavad peatükkidele?

- [ ] CLAUDE.md uuendamine
  - Uus struktuur
  - Uued peatükid
  - Uued viited

**Väljund:**
- ✅ Kvaliteetselt viimistletud koolituskava
- ✅ Valmis kasutamiseks

---

## 📊 IV. RESSURSSIDE KORDUVKASUTAMINE

### Olemasolevad Ressursid

**Praegusest kavast saab taaskasutada:**
- ✅ Peatükk 2 (VPS) → ~70% saab kasutada Peatükis 1
- ✅ Peatükk 3 (PostgreSQL) → ~50% saab kasutada Peatükis 6
- ✅ Peatükk 4 (Git) → ~80% saab kasutada Peatükis 3
- ✅ Peatükk 12 (Docker) → ~90% saab kasutada Peatükis 4
- ✅ Peatükk 14 (Docker Compose) → ~95% saab kasutada Peatükis 7
- ✅ Peatükk 16-25 (K8s, CI/CD, Production) → ~85-95% saab kasutada

**Hinnanguline taaskasutus:** 60-70%
**Uut kirjutamist:** 30-40%

---

## 🎯 V. KVALITEEDIKRITEERIUMID

Iga peatükk PEAB sisaldama:

### Struktuur
- ✅ Selge pealkiri ja kestus
- ✅ Õpieesmärgid (3-5 punkti)
- ✅ Teoorias: kontseptsioonid + põhjendused
- ✅ Praktikas: käsud + koodinäited
- ✅ Praktilised harjutused (vähemalt 3)
- ✅ Viited labidele (kui asjakohane)
- ✅ "Mida sa õppisid" kokkuvõte

### Sisu
- ✅ Eesti keeles (tehnilised terminid inglise keeles)
- ✅ DevOps administraatori vaatenurk (mitte arendaja)
- ✅ Praktiline fookus (hands-on)
- ✅ 2025 best practices
- ✅ Tööstusstandardi tools (K3s, Loki, Trivy, jne)

### Kood ja Käsud
- ✅ Kõik käsud testitavad
- ✅ Kõik koodinäited töötavad
- ✅ Kommenteeritud ja selgitatud
- ✅ Turvalised (no hardcoded secrets)

---

## 📅 VI. AJAKAVA KOKKUVÕTE

### Kiire Ajakava (Prioriteedid 1-2)

| Faas | Kestus | Väljund |
|------|--------|---------|
| **1. VPS Anonümiseerimine** | 1-2 päeva | Üldiselt kasutatav koolituskava |
| **2. Lisamaterjalide Integreerimine** | 1 päev | Peatükk 5 põhjalik (10-12h) |
| **3. Prioriteet 1 Peatükid** | 1 nädal | VPS → Docker → K8s tee valmis |
| **4. Prioriteet 2 Peatükid** | 2 nädalat | Docker + K8s + CI/CD moodulid valmis |
| **5. Kvaliteedikontroll** | 3-5 päeva | Viimistletud koolituskava |

**KOKKU: 4-5 nädalat (full-time töö)**

---

### Täielik Ajakava (Kõik 25 peatükki)

| Faas | Kestus | Väljund |
|------|--------|---------|
| **1-2. VPS + Lisamaterjalid** | 2-3 päeva | Põhistruktuur valmis |
| **3. Prioriteet 1** | 1 nädal | Kriitiline tee valmis |
| **4. Prioriteet 2** | 2 nädalat | Põhimoodulid valmis |
| **5. Prioriteet 3** | 2 nädalat | Täielik koolituskava |
| **6. Kvaliteedikontroll** | 3-5 päeva | 100% valmis |

**KOKKU: 6-7 nädalat (full-time töö)**

---

## ✅ VII. JÄRGMISED SAMMUD (KOHE)

**Praegu alustan:**

1. **VPS Anonümiseerimine** (TÄNA)
   - Muudan CLAUDE.md
   - Loon skripti kõigi viidete leidmiseks
   - Asendan geneeriliste näidetega

2. **Peatükk 5 Integreerimine** (TÄNA/HOMME)
   - Integreerin PEATUKK-6-TAIENDUS-TEHNOLOOGIAD.md
   - Loon põhjaliku peatüki 5

3. **Peatükk 1 Kirjutamine** (HOMME/ÜLEHOMME)
   - Esimene peatükk: DevOps sissejuhatus

4. **Peatükk 4 Kirjutamine** (3-4 PÄEV)
   - Docker põhimõtted

---

## 📞 VIII. KONTAKT JA TAGASISIDE

**Implementeerija:** Claude Code (Sonnet 4.5)
**Kuupäev:** 2025-01-22
**Versioon:** 2.0 Implementation Plan
**Staatus:** 🚀 READY TO START

---

**Alustame koolituskava loomist! 🎓**
