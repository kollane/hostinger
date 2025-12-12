# Docker Image Quality Verification Roadmap

Terviklik ja süsteemne **kvaliteedikontrolli teekaart (roadmap)** juba valmis ehitatud Docker image'ile. Eesmärk: tagada, et konteiner on **minimaalne**, **turvaline** ja **ei leki** ehitusaegseid saladusi (nagu Nexus või proxy).

***

### 1. KIHI JA EFEKTIIVSUSE ANALÜÜS (Efficiency Check)

**Eesmärk:** Tõestada, et multi-stage build töötas ja konteinerisse ei jäänud "ehitusprahti" ega raisatud ruumi.

* **Tööriist:** `dive`
* **Käsk:** `dive <sinu-image-nimi>`
* **Mida kontrollida:**

1. **Image Efficiency Score:** See peaks olema 99% või kõrgem.
2. **Wasted Space:** See number peab olema ligi 0 MB. Kui see on suur, tähendab see, et sa lisasid faili ühes kihis ja kustutasid teises (see fail on tegelikult ikka image'is alles).
3. **Failisüsteem:** Sirvi parempoolses aknas failipuu läbi. Kas näed seal `src/` kausta? Kas näed Maveni repo (`.m2`)? Kas näed GCC kompileerijat?
        * *Kui JAH:* Multi-stage build on valesti seadistatud.
        * *Kui EI:* Väga hea, ainult binaarid on alles.


### 2. LEKETE TUVASTAMINE (Proxy \& Secrets Audit)

**Eesmärk:** Garanteerida, et Nexuse paroolid ja sisevõrgu proxy aadressid ei ole kättesaadavad.

* **Tööriistad:** `docker history`, `grep`, `env`
* **Samm A: Ajaloo kontroll (History Check)**
    * **Käsk:** `docker history --no-trunc <sinu-image-nimi> | grep -E "ARG|ENV|proxy"`
    * **Mida otsida:** Kas näed rida, kus on kirjas `HTTP_PROXY=http://user:password@...`?
    * *Reegel:* `ARG` muutujad võivad ajaloos näha olla, aga ainult siis, kui nad on "tühjad" või ei sisalda saladusi. Kui näed seal parooli, on image kompromiteeritud.
* **Samm B: Keskkonna kontroll (Runtime Check)**
    * **Käsk:** `docker run --rm --entrypoint printenv <sinu-image-nimi>`
    * **Mida otsida:** Otsi muutujaid `HTTP_PROXY`, `HTTPS_PROXY`.
    * *Reegel:* Toodangukonteineris **ei tohi** olla ehitusaegseid proxy seadeid. Kui need on seal, proovib rakendus asjatult sisevõrgu proxyt kasutada ja võib lekkida päringuid.


### 3. TURVALISUSE SKANEERIMINE (Vulnerability Scanning)

**Eesmärk:** OCI standarditele vastavus – vältida teadaolevate turvaaukudega (CVE) komponentide sattumist live-keskkonda.

* **Tööriist:** `trivy`
* **Käsk:** `trivy image --severity HIGH,CRITICAL <sinu-image-nimi>`
* **Mida kontrollida:**

1. **OS paketid:** Kas baas-image (nt Alpine või Debian Slim) on vana?
2. **Rakenduse sõltuvused:** Trivy skaneerib ka JAR faile ja `node_modules` kausta. Kas sinu Nexuse kaudu tõmmatud teekides on turvaauke?
    * *Tegevus:* Kui leiad `CRITICAL`, siis image ei tohi minna Kubernetesele. Tuleb uuendada baas-image'it või teeke.


### 4. STRUKTUURI JA ÕIGUSTE TEST (Compliance Testing)

**Eesmärk:** Veenduda, et failid on õiges kohas ja konteiner ei jookse administraatori õigustes.

* **Tööriist:** `container-structure-test` (Google)
* **Testi sisu (näide):**
    * **File Existence:** Kas `/app/minu-rakendus.jar` on olemas?
    * **User Check:** Kas konteineri kasutaja on `root` (UID 0)?
* **Manuaalne kiirkontroll:**
    * `docker run --rm --entrypoint id <sinu-image-nimi>`
    * *Oodatav:* `uid=1001(appuser) ...`
    * *Keelatud:* `uid=0(root)` (DevOps parimate praktikate kohaselt ei tohi rakendused joosta root-ina, välja arvatud erijuhud).


### 5. "SMOKE TEST" EHK KÄIVITUVUS

**Eesmärk:** Kas see asi üldse töötab ilma välise abita?

* **Tegevus:** Käivita konteiner isoleeritult (ilma Kubernetese abirattadeta).
* **Käsk:** `docker run --rm -p 8080:8080 --name test-run <sinu-image-nimi>`
* **Kontroll:**

1. Kas logides on veateated stiilis "Class not found" või "Missing shared library"? (Viitab, et multi-stage'is kopeeriti liiga vähe asju).
2. Tee päring: `curl localhost:8080/health`.

***

### KOKKUVÕTE: Sinu "Quality Gate" kriteeriumid

Enne kui lükkad image'i registrisse (Push), peab see läbima need "väravad":

1. 🔴 **Efficiency:** Kasutegur > 98% (`dive`).
2. 🔴 **Privacy:** Proxy paroolid puuduvad `env`-ist ja `history`-st.
3. 🔴 **Security:** 0 kriitilist turvaauku (`trivy`).
4. 🔴 **User:** Ei jookse root kasutajana.
5. 🟢 **Size:** Suurus on mõistlik (nt Java < 250MB, Go < 30MB).

Kui need tingimused on täidetud, oled valmis Kubernetesele liikuma teadmisega, et vundament on tugev.

---

**Viimane uuendus:** 2025-12-12
**Tüüp:** Koodiselgitus
**Kasutatakse:** Lab 1, Harjutus 05 (Samm 8: Image Quality Verification)
