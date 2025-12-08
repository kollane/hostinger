# Labor 1: Docker Põhitõed

## 📋 Ülevaade

Selles laboris õpid konteineriseerima mikroteenuseid, haldama Docker võrke ja andmeköiteid (volumes) ning optimeerima Docker tõmmiseid (images) tootekeskkonna jaoks.

**📖 Kasutatavad rakendused:**
- [User Service](../apps/backend-nodejs/README.md) - Node.js autentimisteenus (JWT, kasutajahaldus)
- [Todo Service](../apps/backend-java-spring/README.md) - Java Spring Boot ülesannete rakendus

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

- ✅ Luua **Dockerfile'e** erinevatele rakendustele (Node.js, Java)
- ✅ Ehitada (build) Docker **tõmmiseid (images)**
- ✅ Käivitada ja hallata **konteinereid (containers)**
- ✅ Seadistada Docker **võrke (networks)** ja **andmeköiteid (volumes)**
- ✅ Optimeerida tõmmise suurust **mitmeastmeliste ehitustega (multi-stage builds)**

---

## 🏗️ Arhitektuur

**Lab 1 katab MÕLEMAD mikroteenust:**

```
┌────────────────────────┐        ┌────────────────────────┐
│   User Service         │        │   Todo Service         │
│   (Node.js 18)         │        │   (Java 17 + Spring)   │
│   Port: 3000           │        │   Port: 8081           │
│                        │        │                        │
│   - POST /auth/register│        │   - GET /api/todos     │
│   - POST /auth/login   │        │   - POST /api/todos    │
│   - GET /api/users     │        │   - PATCH /api/todos/:id│
│   - GET /health        │        │   - DELETE /api/todos/:id│
└──────────┬─────────────┘        └──────────┬─────────────┘
           │                                 │
           ▼                                 ▼
    ┌─────────────┐                  ┌─────────────┐
    │  PostgreSQL │                  │  PostgreSQL │
    │  Port: 5432 │                  │  Port: 5433 │
    │  - users DB │                  │  - todos DB │
    └─────────────┘                  └─────────────┘
```

**Mikroteenuste arhitektuur:**
- User Service: JWT autentimine, kasutajate haldus
- Todo Service: Ülesannete haldus, kasutab User Service JWT tokeneid
- Eraldatud andmebaasid: igal teenusel oma PostgreSQL instants

---

## 📂 Labori Struktuur

```
01-docker-lab/
├── README.md              # See fail
├── setup.sh               # Automaatne seadistus ja image'ite ehitamine
├── exercises/             # 6 harjutust (01a-single-container kuni 05-optimization)
└── solutions/             # Näidislahendused
    ├── backend-nodejs/        # User Service Dockerfile'id + README-PROXY.md
    └── backend-java-spring/   # Todo Service Dockerfile'id + README-PROXY.md
```

**Täpsem info:** Iga harjutuse fail sisaldab step-by-step juhiseid, troubleshooting'ut ja õppematerjale.

---

## 📝 Harjutused

1. **[Harjutus 1A](exercises/01a-single-container-nodejs.md)** (45 min) - Konteineriseeri Node.js User Service: loo Dockerfile, ehita image, käivita ja testi REST API.

2. **[Harjutus 1B](exercises/01b-single-container-java.md)** (45 min) - Konteineriseeri Java Spring Boot Todo Service: ehita JAR, loo Dockerfile, käivita ja testi API.

3. **[Harjutus 2](exercises/02-multi-container.md)** (90 min) - Käivita 4 konteinerit koos (2 teenust + 2 PostgreSQL) ja testi mikroteenuste vahelist JWT autentimist.

4. **[Harjutus 3](exercises/03-networking.md)** (45 min) - Loo kohandatud Docker võrk, käivita kõik 4 konteinerit ühes võrgus ja testi DNS lahendust.

5. **[Harjutus 4](exercises/04-volumes.md)** (45 min) - Lisa PostgreSQL andmeköited, testi andmete püsivust ja tee backup/restore.

6. **[Harjutus 5](exercises/05-optimization.md)** (45 min) - Optimeeri image'id mitmeastmeliste ehitustega (Node.js 200MB→50MB, Java 370MB→180MB) ja lisa health checks.

**Kokku:** ~5 tundi hands-on praktikat

---

## ⚡ Kiirstart

### Automaatne Seadistus (Soovitatud)

Käivita seadistusskript, mis kontrollib kõik eeldused:

```bash
lab1-setup
```

**Script kontrollib:**
- ✅ Docker'i paigaldust ja versiooni
- ✅ Docker daemon'i staatust
- ✅ Vaba kettaruumi (>4GB)
- ✅ Rakenduste kättesaadavust

**Script pakub:**
- 💡 Automaatset baastõmmiste (base images) ehitamist (`user-service:1.0`, `todo-service:1.0`)
- 💡 Võimalust vahele jätta eelnevad harjutusest ja jätkata Harjutus 5'st
---

## 🔧 Eeldused

**Tööriistad:**
- Docker paigaldatud ja töötab (`docker ps`)
- 4GB+ vaba kettaruumi
- Internet ühendus (image'ite allalaadimiseks)

**Teadmised:**
- [Peatükk 5: Docker Põhimõtted](../../resource/05-Docker-Pohimotted.md)
- [Peatükk 6: Dockerfile Detailid](../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md)
- Bash/terminal põhikäsud
---

## 🌐 Proxy Tugi (Korporatiivne Võrk)

Kui oled korporatiivse proxy taga (nt Intel võrk):

**Automaatne tugi:**
- `setup.sh` tuvastab automaatselt `HTTP_PROXY`/`HTTPS_PROXY` keskkonnamuutujad
- Ehitab image'id proxy-toetaliste Dockerfile'idega (`Dockerfile.optimized.proxy`)

**Dockerfile variandid:**
- `Dockerfile.optimized.proxy` - ARG-põhine proxy tugi (Node.js ja Java)
- Proxy ei leki runtime'i (turvalisus)
- Portable (toimib proxy ja ilma proxy keskkonnas)

**Detailsed juhised:**
- `solutions/backend-nodejs/README-PROXY.md` - Node.js proxy selgitus (12KB)
- `solutions/backend-java-spring/README-PROXY.md` - Java/Gradle proxy selgitus (15KB)
- [Peatükk 06A: Java ja Node.js Spetsiifika](../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)

**Näide (manuaalne build):**
```bash
export HTTP_PROXY=http://proxy-chain.intel.com:911
export HTTPS_PROXY=http://proxy-chain.intel.com:912

docker build -f Dockerfile.optimized.proxy \
  --build-arg HTTP_PROXY=$HTTP_PROXY \
  --build-arg HTTPS_PROXY=$HTTPS_PROXY \
  -t user-service:1.0-optimized .
```

---

## 🔄 Labori Ressursside Haldamine

### labs-reset - Täielik Lähtestamine

Kui soovid kõiki Docker ressursse puhastada ja alustada uuesti:

```bash
labs-reset
```

**⚠️ HOIATUS:** Kustutab KÕIK Docker ressursid süsteemis (mitte ainult Lab 1)!

**Script kustutab:**
- 🗑️ KÕIK Docker konteinerid (töötavad ja peatatud)
- 🗑️ KÕIK kohandatud Docker võrgud (välja arvatud bridge, host, none)
- 🗑️ KÕIK Docker andmeköited (volumes)

**Interaktiivne valik: Image'ite Kustutamine**

Script küsib, kas kustutada ka Docker image'id:

```
[N] Ei, säilita Lab 1 baastõmmised (user-service:1.0, todo-service:1.0)
    → Kiire restart Harjutuste 2-6 jaoks
[Y] Jah, kustuta KÕIK image'id
    → Täielik "puhas leht" algusest (alusta Harjutus 1'st)
```

---
**Detailsed lahendused:** Iga harjutuse failis on "Levinud Probleemid ja Lahendused" sektsioon.
---

## 📚 Viited

**Koolituskava:**
- [Peatükk 5: Docker Põhimõtted](../../resource/05-Docker-Pohimotted.md)
- [Peatükk 6: Dockerfile Detailid](../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md)
- [Peatükk 6A: Java/Node.js Spetsiifika](../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)

**Docker Dokumentatsioon:**
- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Best practices](https://docs.docker.com/develop/dev-best-practices/)

---

## 🎯 Järgmine Labor

Peale selle labori edukat läbimist jätka:
- **[Labor 2: Docker Compose](../02-docker-compose-lab/)** - Multi-container orkestratsioon

---

**Kestus:** ~5 tundi
**Staatus:** ✅ Valmis
**Viimane uuendus:** 2025-12-08
