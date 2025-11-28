# Docker & DevOps Terminoloogia Sõnastik

Selle dokumendi eesmärk on ühtlustada terminoloogiat kõigis labori harjutustes ja teoreetilistes materjalides.

## Põhimõte

1.  Kasutame **eestikeelseid sõnu**.
2.  Tehnilised terminid lisame **sulgudes inglise keeles** ainult **esmakordsel mainimisel** peatükis või suuremas lõigus. Edaspidi kasutame vaid eestikeelset terminit.
3.  Kui viitame konkreetsele koodi elemendile (nt YAML võti), kasutame koodivormingut ega tõlgi seda (nt `volumes` sektsioon).

**Näide:**
> "Ehita Docker **tõmmis (image)** kasutades **mitmeastmelist (multi-stage)** ehitust. Seejärel lae tõmmis üles."

---

## Sõnastik

### Põhimõisted

| Eesti keeles | Inglise keeles | Näide kasutuses |
|--------------|----------------|-----------------|
| **tõmmis** | image | Ehita Docker tõmmis (image) |
| **konteiner** | container | Käivita Docker konteiner |
| **ehita / koosta** | build | Koosta tõmmis `build` käsuga |
| **käivita** | run | Käivita konteiner |
| **varamu / register** | registry | Lae tõmmis Docker Hub varamusse (registry) |
| **silt** | tag | Märgista tõmmis sildiga (tag) `v1.0` |
| **logid** | logs | Vaata konteineri logisid |

### Arhitektuur ja Võrk

| Eesti keeles | Inglise keeles | Näide kasutuses |
|--------------|----------------|-----------------|
| **baastõmmis** | base image | Kasuta `node:18` baastõmmist |
| **kiht** | layer | Tõmmis koosneb mitmest kihist (layers) |
| **mitmeastmeline** | multi-stage | Mitmeastmeline (multi-stage) Dockerfile |
| **vahemälu** | cache | Kasuta ehitamisel vahemälu (cache) |
| **köide / andmeköide** | volume | Andmete säilitamiseks kasuta köidet (volume) |
| **võrk** | network | Ühenda konteinerid samasse võrku |
| **pordivastendus** | port mapping | Määra pordivastendus (port mapping) 80:8080 |
| **taustarežiim** | detached mode | Käivita konteiner taustarežiimis (detached mode) |
| **tervisekontroll** | health check | Seadista rakenduse tervisekontroll (health check) |

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

---

## Mida EI tõlgita

### Käsud
Käsud ja nende parameetrid jäävad inglise keelde:
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

---

## Kasutusnäited

### ✅ Õige (loomulik ja täpne)
> "Koosta Docker **tõmmis (image)**, kasutades `node:alpine` **baastõmmist**. Iga `RUN` käsk lisab uue **kihi (layer)**, mida Docker salvestab **vahemälus**."

### ❌ Vale (kohmakas või ebatäpne)
> "Ehita Docker **pilt** kasutades `node:alpine` **base image**-it. Iga `RUN` käsk teeb uue **layeri**, mis läheb **cache**-i."

---

## Versioon

- **Loodud:** 2025-01-20
- **Viimati uuendatud:** 2025-11-28 (Terminite täpsustamine ja laiendamine)
- **Kehtib:** Kõik laborid ja õppematerjalid