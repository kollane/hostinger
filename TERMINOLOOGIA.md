# Docker & DevOps Terminoloogia Sõnastik

Selle dokumendi eesmärk on ühtlustada terminoloogiat kõigis labori harjutustes ja teoreetilistes materjalides.

## Põhimõte

**Reegel 1: Peatükk "Õpieesmärgid" (Learning Objectives)**
Selles peatükis (tavaliselt faili alguses olev loetelu) peavad **kõik** tehnilised terminid olema esitatud paralleelselt:
*   Eestikeelne termin (Ingliskeelne termin)
*   *Näide:* "Luua **andmeköiteid (docker volumes)**..."

**Reegel 2: Ülejäänud tekst (Body Text)**
Teksti sisus kasutame reeglina **ainult eestikeelset terminit**.
*   *Näide:* "...ühenda andmeköide konteineriga..."

**Reegel 3: Erand ülejäänud tekstis**
Kui tehniline termin esineb antud failis **esimest korda** JA seda **ei ole mainitud** selle konkreetse faili "Õpieesmärgid" loetelus, siis toome esimesel mainimisel välja mõlemad keeled. Edaspidi samas failis kasutame vaid eestikeelset.

**Näide:**
> "Ehita Docker **tõmmis (docker image)**..."

---

## Sõnastik

### Põhimõisted

| Eesti keeles | Inglise keeles | Näide kasutuses |
|--------------|----------------|-----------------|
| **tõmmis** | image | Ehita Docker tõmmis (docker image) |
| **konteiner** | container | Käivita Docker konteiner |
| **ehita** | build | Ehita tõmmis `build` käsuga |
| **käivita** | run | Käivita konteiner |
| **varamu / register** | registry | Lae tõmmis Docker Hub varamusse (registry) |
| **silt** | tag | Märgista tõmmis sildiga (tag) `v1.0` |
| **logid** | logs | Vaata konteineri logisid |
| **mikroteenus** | microservice | Arenda ja paigalda mikroteenust (microservice) |

### Arhitektuur ja Võrk

| Eesti keeles | Inglise keeles | Näide kasutuses |
|--------------|----------------|-----------------|
| **baastõmmis** | base image | Kasuta `node:18` baastõmmist |
| **kiht** | layer | Tõmmis koosneb mitmest kihist (layers) |
| **mitmeastmeline** | multi-stage | Mitmeastmeline (multi-stage) Dockerfile |
| **vahemälu** | cache | Kasuta ehitamisel vahemälu (cache) |
| **köide / andmeköide** | volume | Andmete säilitamiseks kasuta köidet (docker volume) |
| **võrk** | network | Ühenda konteinerid samasse võrku (docker network) |
| **pordivastendus** | port mapping | Määra pordivastendus (port mapping) 80:8080 |
| **taustarežiim** | detached mode | Käivita konteiner taustarežiimis (detached mode) |
| **tervisekontroll** | health check | Seadista rakenduse/konteineri tervisekontroll (health check) |

### Kubernetes ja Orkestreerimine

| Eesti keeles | Inglise keeles | Näide kasutuses |
|--------------|----------------|-----------------|
| **orkestreerimine** | orchestration | Konteinerite orkestreerimine |
| **klaster** | cluster | Kubernetes klaster |
| **nimeruum** | namespace | Loo uus nimeruum (namespace) |
| **paigaldus / kasutuselevõtt** | deployment | Uuenda rakenduse paigaldust (deployment) |
| **teenus** | service | Avalda rakendus teenusena (service) |
| **sissepääs** | ingress | Konfigureeri sissepääs (ingress) |
| **püsiköide** | persistent volume | Salvesta andmed püsiköitesse |
| **manifest** | manifest | Kirjelda ressursid YAML manifestis |
| **koopia** | replica | Määra koopiate (replicas) arv |

### Arendus ja Protsessid

| Eesti keeles | Inglise keeles | Näide kasutuses |
|--------------|----------------|-----------------|
| **sõltuvused** | dependencies | Paigalda npm sõltuvused (dependencies) |
| **keskkonnamuutuja** | environment variable | Loe konfi keskkonnamuutujatest |
| **töövoog** | workflow / pipeline | CI/CD töövoog |
| **konteineriseerimine** | containerization | Pärandrakenduse konteineriseerimine |
| **krahhima / kokku jooksma** | crash | Rakendus krahhis (crashed) vea tõttu |
| **hanguma** | hang | Protsess hangus (on vastuseta), kuid töötab |
| **veatuvastus** | debug | Käivita rakendus veatuvastuse (debug) režiimis |
| **toote keskkond** | production | Rakendus on toote keskkonnas (production) |
| **arenduskeskkond** | development | Töötan arenduskeskkonnas (development) |
| **tagasi keerama** | rollback | Varasema versiooni juurde tagasi keerama (rollback) |
| **ehita uuesti** | rebuild | Ehita tõmmis uuesti (rebuild) |
| **taaskäivitus** | restart | Taaskäivita teenus/konteiner |

---

## Mida EI tõlgita

### Käsud
Tehnilisi käske, sealhulgas käske ja nende parameetreid, ei tõlgita. Need jäävad inglise keelde:
- `docker build`, `docker run`
- `kubectl apply`, `kubectl get`
- lipud: `--name`, `-d`, `-p`, `-v`

### Failinimed
Failinimed on tõstutundlikud ja muutmatud:
- `Dockerfile`, `.dockerignore`
- `package.json`, `build.gradle`
- `docker-compose.yml`

### Koodi võtmesõnad
Konfiguratsioonifailide ja koodi süntaks jääb muutmata:
- Dockerfile: `FROM`, `COPY`, `RUN`, `CMD`
- Kubernetes YAML: `metadata`, `spec`, `kind`, `volumes`

### Spetsiifilised terminid
Teatud ingliskeelsed terminid jäävad tõlkimata, kuid neid kasutatakse jutumärkides:
- "hardcoded"
- "token"
- "User Service"
- "Todo Service"
- "frontend"
- "backend"

---

## Kasutusnäited

### ✅ Õige (loomulik ja täpne)
> "Ehita Docker **tõmmis (docker image)**, kasutades `node:alpine` **baastõmmist**. Iga `RUN` käsk lisab uue **kihi (layer)**, mida Docker salvestab **vahemälus**."

### ❌ Vale (kohmakas või ebatäpne)
> "Ehita Docker **pilt** kasutades `node:alpine` **base image**-it. Iga `RUN` käsk teeb uue **layeri**, mis läheb **cache**-i."

---

## Koodiselgitused (Code Explanations)

### KOODISELGITUS Pattern

**Kasutamine:**
Kui kasutan märksõna **KOODISELGITUS** ja viitan failile, siis:
1. Fail paigutatakse `resource/code-explanations/` kataloogi
2. Faili nimi valitakse automaatselt sobiva konventsiooni järgi (`Descriptive-Name-Explained.md`)
3. Sisu on lühike, koodikeskne selgitus (MITTE täielik peatükk)
4. Fail dokumenteeritakse koolituskavas (`DEVOPS-KOOLITUSKAVA-PLAAN-2025.md`)
5. `README.md` sisukord uuendatakse

**Eristus peatükkidest:**
- **Peatükid (05, 06, 06A, ...):** Põhjalikud teoreetilised käsitlused, järgivad standardset struktuuri (Õpieesmärgid, Põhimõisted, Teooria, Best Practices)
- **Koodiselgitused:** Lühikesed, konkreetse koodi seletused, AI-genereeritud stiil OK, ei järgi peatüki struktuuri

**Nimetamise konventsioon:**
- Format: `Technology-Topic-Explained.md`
- Examples:
  - `Node.js-Dockerfile-Proxy-Explained.md`
  - `Java-Gradle-Dependency-Cache-Explained.md`
  - `PostgreSQL-Init-Script-Explained.md`
  - `Kubernetes-HPA-Manifest-Explained.md`
- Ilma numbrita (ei ole osa põhipeatükkidest 1-30)

**Minimaalne struktuur:**
- Pealkiri (või selle puudumine - võib alustada kohe selgitusega)
- Selgitus (code-focused, võib olla AI-genereeritud)
- Jalus: Viimane uuendus, Tüüp: Koodiselgitus, Kasutatakse: [viited laboritele]

**Viitamine labori harjutusest:**
```markdown
**📖 Põhjalik koodi selgitus:**

Kui vajad koodi täpset rea-haaval selgitust, loe:
- 👉 **[Koodiselgitus: Descriptive Title](../../../resource/code-explanations/File-Name-Explained.md)**
```

**Näide:**
- Lab 1, Exercise 01a viitab: `resource/code-explanations/Node.js-Dockerfile-Proxy-Explained.md`
- Selgitus on lühike (4 lehte), AI-genereeritud, koodikeskne
- Sisaldab rea-haaval Dockerfile analüüsi ja portatiivsuse selgitust

---

## Versioon

- **Loodud:** 2025-01-20
- **Viimati uuendatud:** 2025-01-25 (Koodiselgituste (KOODISELGITUS) pattern lisatud)
- **Kehtib:** Kõik laborid ja õppematerjalid