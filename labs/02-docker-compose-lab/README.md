# Labor 2: Docker Compose

**Kestus:** 5.25 tundi
**Eeldused:** Labor 1 läbitud (4 optimeeritud konteinerit), Peatükk 13 (Docker Compose)
**Eesmärk:** Õppida multi-container rakenduste orkestreerimist Docker Compose'iga ning turvalise võrgu segmenteerimise põhitõdesid

**📖 Kasutatavad rakendused:**

- [User Service](../apps/backend-nodejs/README.md) - Autentimisteenus, mis haldab kasutajaid ja annab välja JWT "token"-eid
- [Todo Service](../apps/backend-java-spring/README.md) - Todo ülesannete rakendus (to-do list), kus kasutajad saavad hallata oma ülesandeid

---

## 📋 Ülevaade

Selles laboris õpid hallama mitut konteinerit korraga Docker Compose'i abil. **Lähtud Labor 1 lõpuseisust** (4 töötavat optimeeritud konteinerit) ja konverteerid need docker-compose.yml failiks, lisad "frontend" teenuse ning õpid parimaid praktikaid tootmiskõlbulike (production-ready) konfiguratsioonide loomiseks.

**Labor 1 vs Labor 2:**

- **Labor 1:** Käivitasid iga konteineri eraldi käsuga (`docker run`)
- **Labor 2:** Käivitad kogu süsteemi ühe käsuga (`docker compose up`)

Lab 2 lõpuks on sul valmis terve süsteem docker-compose.yml failiga, mida saad Lab 3's Kubernetes'esse deploy'da.

**⚠️ MÄRKUS: Docker Compose v2 (2025 Best Practice)**

See labor kasutab **Docker Compose v2** (`docker compose` käsku, mitte `docker-compose`):

- ✅ Käsk: `docker compose up` (v2) - SOOVITATAV 2025+
- ❌ Käsk: `docker-compose up` (v1, aegunud)
- ℹ️ `version:` väli YAML failis on valikuline (optional) Compose v2's
- ℹ️ Compose v2 on built-in Docker CLI's alates Docker 20.10+

---

## 🏗️ Arhitektuur

### Lab 1 Lõpuseisu (Stardipunkt)

Lab 1 lõpus oli sul töötamas **4 konteinerit** (manuaalsete `docker run` käskudega):

```
┌────────────────────────────────────────────────────────────┐
│           todo-network (custom bridge)                     │
│                                                            │
│   ┌──────────────────┐         ┌──────────────────┐       │
│   │  user-service    │         │  todo-service    │       │
│   │  (Node.js)       │         │  (Java Spring)   │       │
│   │  Port: 3000      │         │  Port: 8081      │       │
│   │  Image:          │         │  Image:          │       │
│   │  user-service:   │         │  todo-service:   │       │
│   │  1.0-optimized   │         │  1.0-optimized   │       │
│   └────────┬─────────┘         └────────┬─────────┘       │
│            │                            │                  │
│            ▼                            ▼                  │
│   ┌──────────────────┐         ┌──────────────────┐       │
│   │  postgres-user   │         │  postgres-todo   │       │
│   │  Port: 5432      │         │  Port: 5433      │       │
│   │  Volume:         │         │  Volume:         │       │
│   │  postgres-user-  │         │  postgres-todo-  │       │
│   │  data            │         │  data            │       │
│   └──────────────────┘         └──────────────────┘       │
└────────────────────────────────────────────────────────────┘
```

**Lab 1-st said:**

- ✅ 2 optimeeritud "backend" tõmmist (mitmeastmelised ehitused)
- ✅ 2 PostgreSQL andmebaasi (eraldi andmeköidetega)
- ✅ Kohandatud võrk (todo-network)
- ✅ Manuaalsed `docker run` käsud iga konteineri jaoks

### Lab 2 Sihtolek (5 Teenust)

Lab 2 lõpus on sul töötamas **5 teenust (services)** Docker Compose'iga:

```
               Browser (http://93.127.213.242:[SINU-PORT])
                         │
                         ▼
        ┌────────────────────────────────┐
        │  Frontend (Nginx)              │
        │  Port: 8080                    │
        │  Static HTML/CSS/JS            │
        └────┬──────────────────────┬────┘
             │                      │
             │ API Calls            │
             ▼                      ▼
    ┌─────────────────┐    ┌─────────────────┐
    │  User Service   │    │  Todo Service   │
    │  (Node.js)      │    │  (Java Spring)  │
    │  Port: 3000     │    │  Port: 8081     │
    └────────┬────────┘    └────────┬────────┘
             │                      │
             ▼                      ▼
    ┌─────────────────┐    ┌─────────────────┐
    │  PostgreSQL     │    │  PostgreSQL     │
    │  Port: 5432     │    │  Port: 5433     │
    │  users DB       │    │  todos DB       │
    └─────────────────┘    └─────────────────┘
```

**Lab 2'st saad:**

- ✅ Kogu süsteemi haldamine ühe docker-compose.yml failiga
- ✅ "frontend" teenus (5. komponent)
- ✅ .env failid salajaste haldamiseks
- ✅ Andmebaasi migratsioonid Liquibase'iga
- ✅ Tootmiskõlbulikud konfiguratsioonid

**Teenused:**

- **"Frontend"**: Nginx staatiliste failidega → Suhtleb mõlema "backendiga"
- **"User Service"**: Node.js + Express → Autentimine, kasutajate haldus
- **"Todo Service"**: Java Spring Boot → Todo CRUD operatsioonid (Lab 1-st)
- **PostgreSQL x2**: Eraldi andmebaasid users ja todos jaoks

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

- ✅ Konverteerida **mitme konteineri** seadistust Docker Compose failiks
- ✅ Kirjutada `docker-compose.yml` faile järgides parimaid praktikaid
- ✅ Implementeerida **võrgu segmenteerimist** ja turvalisi portide konfiguratsioone
- ✅ Vähendada **rünnaku pinda** 96% (5 avalikku porti → 1 avalik port)
- ✅ Mõista **3-kihilist arhitektuuri** (DMZ → Backend → Database)
- ✅ Hallata **keskkonnamuutujaid** `.env` failidega
- ✅ Kasutada `docker-compose.override.yml` **mustrit**
- ✅ Implementeerida **andmebaasi migratsioone** Liquibase'iga
- ✅ Konfigureerida **tootmiskeskkonna mustreid** (skaleerimine, ressursilimiidid, tervisekontrollid)
- ✅ **Teostada veatuvastust** mitme konteineri rakendusi

---

## 📂 Labori Struktuur

```
02-docker-compose-lab/
├── README.md                  # See fail
├── setup.sh                   # Automaatne seadistus
├── exercises/                 # Harjutused (7 harjutust)
│   ├── 01-compose-basics.md           # Lab 1 → docker-compose.yml (4 teenust)
│   ├── 02-add-frontend.md             # Lisa Frontend (5. teenus)
│   ├── 03-network-segmentation.md     # Võrgu segmenteerimine ja portide turvalisus
│   ├── 04-environment-management.md   # .env failid ja override pattern
│   ├── 05-database-migrations.md      # Liquibase init container
│   ├── 06-production-patterns.md      # Scaling, limits, health checks
│   └── 07-advanced-patterns.md        # Advanced patterns
└── solutions/                 # Lahendused
    ├── docker-compose.yml             # 4 teenust (Harjutus 1)
    ├── docker-compose-full.yml        # 5 teenust (Harjutus 2)
    ├── docker-compose.secure.yml      # Turvaline arhitektuur (Harjutus 3)
    ├── docker-compose.override.yml    # Dev debug ports (Harjutus 3)
    ├── docker-compose.prod.yml        # Production variant
    ├── .env.example                   # Environment template
    └── liquibase/                     # Migration failid
```

---

## 🔧 Eeldused

### Eelnevad labid:

- [x] **Labor 1: Docker Põhitõed** - KOHUSTUSLIK
  - **PEAB olema Lab 1'st:**
    - ✅ `user-service:1.0-optimized` **tõmmis** (~50MB, Node.js multi-stage build)
    - ✅ `todo-service:1.0-optimized` **tõmmis** (~180MB, Java multi-stage build)
    - ✅ `postgres-user-data` andmeköide (sisaldab users tabelit)
    - ✅ `postgres-todo-data` andmeköide (sisaldab todos tabelit)
    - ✅ `todo-network` kohandatud võrk (custom bridge network)
    - ✅ 4 töötavat konteinerit (user-service, todo-service, 2x postgres)

### Tööriistad:

- [x] Docker Compose paigaldatud (`docker compose version` - v2.x)
- [x] Docker daemon töötab (`docker ps`)
- [x] Vähemalt 4GB vaba RAM
- [x] vim või muu text editor

### Teadmised:

- [x] **Labor 1:** Docker põhitõed (tõmmised, konteinerid, võrgud, andmeköited)
- [x] **Peatükk 13:** Docker Compose põhimõtted
- [x] YAML failivorming
- [x] Keskkonnamuutujad

---

## 🚀 Quick Start

Lab 2'l on kaks alustamise viisi:

### Variant A: Setup Skript (Soovitatav algajatele ja kiireks testimiseks)

```bash
cd 02-docker-compose-lab
./setup.sh
```

**Seadistusskript teeb:**

- ✅ Kontrollib Lab 1 eeldusi (images, volumes, network)
- ✅ Loob puuduvad ressursid (võrk, volumes)
- ✅ Võimaldab valida andmebaasi automaatset initsialiseermist
  - Variant 1: Käsitsi (pedagoogiline - õpid SQL'i ja docker exec'i)
  - Variant 2: Automaatne (mugavus - init skriptid loodavad skeemi + testimisandmed)
- ✅ Käivitab teenused

**Sobib, kui:**

- Soovid kiiresti alustada ilma Lab 1 ressursside loomiseta
- Soovid testimisandmetega andmebaasi (4 kasutajat, 8 todo'd)
- Soovid keskenduda Docker Compose'i õppimisele, mitte DB seadistusele

### Variant B: Käsitsi (Pedagoogiline - Õpid kõik sammud)

Järgi harjutuste juhiseid järjest:

1. **Harjutus 1**: Compose Basics - Lab 1 → docker-compose.yml konversioon
2. **Harjutus 2**: Add Frontend - 5. teenuse lisamine
3. **Harjutus 3**: Network Segmentation - Turvaline arhitektuur

```bash
cd 02-docker-compose-lab/exercises
cat 01-compose-basics.md
```

**Sobib, kui:**

- Läbisid Lab 1 ja soovid progressive learning'ut
- Soovid õppida Docker Compose'i samm-sammult
- Soovid mõista MIKS iga konfiguratsioon on vajalik

**⚠️ PEDAGOOGILINE MÄRKUS:**

- **Harjutused õpetavad käsitsi** (docker exec, SQL, võrgud, volumes) - see on õppimise osa!
- **setup.sh on mugavuse huvides** - kasuta, kui vajad kiiret starti või testimisandmeid
- **Soovitame esimest korda teha käsitsi**, et õppida Docker põhitõdesid

---

## 📚 Progressiivne Õppetee

```
Labor 1 (Docker)
  ↓ 4 optimeeritud konteinerit →
Labor 2 (Compose) ← Oled siin
  ↓ docker-compose.yml + 5 teenust →
Labor 3 (K8s Basics)
  ↓ K8s manifests →
Labor 4 (K8s Advanced)
  ↓ Ingress + Helm →
Labor 5 (CI/CD)
  ↓ Automated deployments →
Labor 6 (Monitoring)
```

---


## 📝 Harjutused

### Harjutus 1: Docker Compose Alused (60 min)
**Fail:** [exercises/01-compose-basics.md](exercises/01-compose-basics.md)

Konverteeri Lab 1 lõpuseisu docker-compose.yml failiks:

- Loo services blokk 4 teenusele (2x postgres, 2x backend)
- Defineeri andmeköited ja võrgud
- Kasuta olemasolevaid tõmmiseid (user-service:1.0-optimized, todo-service:1.0-optimized)
- Testi End-to-End workflow

### Harjutus 2: Lisa "frontend" teenus (45 min)
**Fail:** [exercises/02-add-frontend.md](exercises/02-add-frontend.md)

Lisa "frontend" (5. teenus):

- Loo "frontend" teenus Nginx'iga
- Mount staatilised failid (HTML/CSS/JS)
- Konfigureeri pordivastendus (8080:80)
- Testi brauseris

### Harjutus 3: Võrgu segmenteerimine ja portide turvalisus (60 min)
**Fail:** [exercises/03-network-segmentation.md](exercises/03-network-segmentation.md)

Implementeeri turvaline võrgu arhitektuur:

- Loo 3-kihiline võrgu arhitektuur (DMZ → "Backend" → Andmebaas)
- Eemalda avalikud pordid "backend" ja andmebaasi teenustelt
- Kasuta localhost-only binding (127.0.0.1) development debug'imiseks
- Vähenda rünnaku pinda 96%
- Mõista võrgu segmenteerimise põhimõtteid

### Harjutus 4: Keskkonnahaldus (45 min)
**Fail:** [exercises/04-environment-management.md](exercises/04-environment-management.md)

Halda keskkonnamuutujaid:

- Loo .env fail salajastele (JWT_SECRET, DB_PASSWORD)
- Kasuta docker-compose.override.yml pattern'i
- Loo eraldi dev ja prod konfiguratsioonid

### Harjutus 5: Andmebaasi migratsioonid Liquibase'iga (60 min)
**Fail:** [exercises/05-database-migrations.md](exercises/05-database-migrations.md)

Automatiseeri andmebaasi skeem:

- Loo Liquibase changelog failid
- Implementeeri init container pattern
- Käivita migratsioonid enne "backendi"
- Rollback testimine

### Harjutus 6: Toote mustrid (45 min)
**Fail:** [exercises/06-production-patterns.md](exercises/06-production-patterns.md)

Production-ready konfiguratsioon:

- Scaling (replicas)
- Resource limits (CPU, memory)
- Restart policies
- Tervisekontrollid ja dependency management
- Logimise konfiguratsioon

### Harjutus 7: Edasijõudnute mustrid (vajadusel)
**Fail:** [exercises/07-advanced-patterns.md](exercises/07-advanced-patterns.md)

Täiustatud mustrid:








---

## 📚 Viited

### Koolituskava:

- **Peatükk 13:** Docker Compose

### Docker Dokumentatsioon:

- [Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Environment variables](https://docs.docker.com/compose/environment-variables/)
- [Networking in Compose](https://docs.docker.com/compose/networking/)
- [Best practices](https://docs.docker.com/compose/production/)

### Labori Materjalid:

- [TERMINOLOOGIA.md](../TERMINOLOOGIA.md) - Eesti-inglise sõnastik
- [Labor 1 README](../01-docker-lab/README.md) - Eelduslabor

---

## 🎯 Järgmine Labor

Peale selle labori edukat läbimist, jätka:

- **Labor 3:** Kubernetes Põhitõed

---

## 🎓 Kokkuvõte

Peale selle labori läbimist oled:

- ✅ Konverteerinud Lab 1 manuaalsed käsud docker-compose.yml failiks
- ✅ Lisanud Frontend teenuse ja loonud täieliku 5-tier süsteemi
- ✅ Õppinud hallama keskkonnamuutujaid turvaliselt
- ✅ Implementeerinud andmebaasi migratsioonid Liquibase'iga
- ✅ Konfigureerinud production-ready Compose seadistused
- ✅ Teostanud veatuvastust mitme konteineri rakendustel
- ✅ Valmis Kubernetes'e migreerumiseks (Lab 3)

**Edu laboriga! 🚀**

---

**Staatus:** 🏗️ Ülesehitamisel
**Viimane uuendus:** 2025-11-21
