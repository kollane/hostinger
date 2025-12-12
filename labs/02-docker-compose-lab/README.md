# Labor 2: Docker Compose

**Kestus:** ~8-10 tundi (6 põhilist + 3 advanced harjutust)
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

## 🎯 Strateegiline Ülevaade: Legacy → Docker → Kubernetes

### Miks See Labor On Oluline?

Paljud ettevõtted jooksutavad rakendusi **legacy infrastruktuuris** (Tomcat, WebLogic, manuaalsed deploy'd). **Docker Compose on esimene samm moderniseerimise teel** - lihtsam kui Kubernetes, aga annab juba suurt väärtust.

| Etapp | Tehnoloogia | Deploy Aeg | Downtime | Skaleeritavus |
|-------|-------------|------------|----------|---------------|
| **Legacy** | Tomcat/WebLogic | 30-60 min | 5-10 min | ❌ Raske |
| **Docker Compose** | Docker | 5 min | 0 min | ✅ Manual (2-3 replicas) |
| **Kubernetes** | K8s | 2 min | 0 min | ✅✅ Auto-scaling |

**Võtmepunkt:** **80% projektidest ei vaja Kubernetes't!** Docker Compose on täisväärtuslik production lahendus.

### Moderniseerimise Tee (Ülevaade)

**Progressiivne lähenemine:** Legacy (Tomcat, WebLogic) → Docker → Docker Compose → Kubernetes

```
Etapp 1: Konteinerise (Lab 1)       → 3-6 kuud
Etapp 2: Orkestreerimise (Lab 2)     → 3-6 kuud
Etapp 2B: Production (Docker Compose) → 12-18 kuud
Etapp 3: Kubernetes (Lab 3-10)       → Valikuline (kui kasvad)
```

**Millal jääda Docker Compose'i juurde:**
- Teenuseid: 1-20
- Servereid: 1-3
- Legacy rakendusi: 5-15

**Millal Kubernetes:**
- Teenuseid: 30+
- Servereid: 10+
- Vajad auto-scaling'ut

📖 **Detailne roadmap:** [LEGACY-TO-KUBERNETES-ROADMAP.md](LEGACY-TO-KUBERNETES-ROADMAP.md)
- Tomcat/WebLogic konteinerimise praktilised näited
- 15 rakenduse migratsioonistrateegia
- Täielik ajakava (1.5-3 aastat)
- Otsustamise kriteeriumid

---

### Lab 2 Õpieesmärgid

Selles laboris õpid **kõik vajalikud oskused Docker Compose production setup'iks**:

| Harjutus | Oskus | K8s Vaste |
|----------|-------|-----------|
| 1-3 | Basics, networking | Pods, Services |
| 4 | Multi-environment | ConfigMaps, Secrets |
| 6 | Production patterns | Resource Limits |
| 9 | High Availability | Deployments, Ingress |

**Võtmepunkt:** Docker Compose oskused on Kubernetes'e alus!

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
├── setup.sh                   # Automaatne seadistus (kasuta aliast: lab2-setup)
├── exercises/                 # Harjutused (9 harjutust)
│   ├── 01-compose-basics.md           # Lab 1 → docker-compose.yml (4 teenust)
│   ├── 02-add-frontend.md             # Lisa Frontend (5. teenus)
│   ├── 03-network-segmentation.md     # Võrgu segmenteerimine ja portide turvalisus
│   ├── 04-environment-management.md   # .env failid ja override pattern
│   ├── 05-database-migrations.md      # Liquibase init container
│   ├── 06-production-patterns.md      # Scaling, limits, health checks
│   ├── 07-advanced-patterns.md        # Advanced patterns (VALIKULINE)
│   ├── 08-legacy-integration.md       # Legacy integration (vana maailm + Docker)
│   └── 09-production-readiness.md     # Production-ready stack (SSL, HA, Monitoring)
└── solutions/                 # Lahendused
    ├── docker-compose.yml             # 4 teenust (Harjutus 1)
    ├── docker-compose-full.yml        # 5 teenust (Harjutus 2)
    ├── docker-compose.secure.yml      # Turvaline arhitektuur (Harjutus 3)
    ├── docker-compose.override.yml    # Dev debug ports (Harjutus 3)
    ├── docker-compose.prod.yml        # Production variant
    ├── .env.example                   # Environment template
    ├── liquibase/                     # Migration failid
    ├── 08-legacy-integration/         # Legacy integration (3 tier'i)
    │   ├── tier1-legacy-db/
    │   ├── tier2-docker-apps/
    │   └── tier3-legacy-nginx/
    └── 09-production-readiness/       # Production stack
        ├── docker-compose.prod.yml
        ├── nginx/ (SSL konfiguratsioon)
        ├── prometheus/
        └── grafana/
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

### 🔧 Märkus Proxy Keskkonna Kohta

Docker Compose keskendub orkestreerimisele, mitte image ehitamisele. Lab 2 eeldab, et Docker image'd on juba olemas. Siin on 4 stsenaariumit, kuidas hallata image'id proxy keskkonnas.

---

#### Stsenaarium A: Lab 1 Images On Juba Olemas (Tavaliselt)

**See on KÕIGE TAVALISEM stsenaarium! 🎯**

Kui läbisid Lab 1 ja ehitasid Docker image'd:
- ✅ Image'd on juba valmis: `user-service:1.0-optimized`, `todo-service:1.0-optimized`
- ✅ Lab 2 kasutab neid valmis pilte (`image:` direktiiv compose failides)
- ℹ️ Proxy ei ole enam vajalik - see oli **build-time mure**, mitte **orchestration-time** mure

**Mida teha:**
```bash
# Kontrolli, kas image'd on olemas
docker images | grep -E "user-service|todo-service"

# Kui näed:
# user-service    1.0-optimized   ...
# todo-service    1.0-optimized   ...
# Siis LAB 2 ON VALMIS ALUSTAMISEKS! ✅
```

**Jätka harjutustega:**
```bash
cd compose-project
docker compose up -d
```

---

#### Stsenaarium B: setup.sh Ehitab Images Automaatselt (Mugav)

**Kui Lab 1 image'd puuduvad, setup skript teeb kõik automaatselt! 🚀**

Lab 2 setup skript (`./setup.sh` või `lab2-setup`):
1. ✅ Kontrollib, kas Lab 1 image'd on olemas
2. ✅ Kui puuduvad, pakub **automaatset ehitamist**
3. ✅ Kasutab Lab 1 `Dockerfile.optimized.proxy` faile
4. ✅ Seadistab **vaikimisi proxy väärtused**:
   - `HTTP_PROXY=http://proxy-chain.intel.com:911`
   - `HTTPS_PROXY=http://proxy-chain.intel.com:912`

**Mida teha:**
```bash
cd labs/02-docker-compose-lab
./setup.sh

# Skript küsib:
# "Kas soovid ehitada (build) baaspildid (base images) KOHE?"
# Vali: [Y] Jah, ehita mõlemad pildid nüüd
```

**Tulemus:**
- ✅ `user-service:1.0-optimized` ehitatud
- ✅ `todo-service:1.0-optimized` ehitatud
- ✅ PostgreSQL andmebaasid seadistatud
- ✅ Valmis alustamiseks!

---

#### Stsenaarium C: Käsitsi Building Proxy Keskkonnas (Harva Vajalik)

**Kui setup.sh ei tööta või soovid käsitsi kontrollida build protsessi. 🔧**

##### 1. Node.js User Service

```bash
cd ../apps/backend-nodejs

# Asenda oma proxy aadress!
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized.proxy \
  -t user-service:1.0-optimized .

# Kontrolli
docker images | grep user-service
```

##### 2. Java Spring Boot Todo Service

```bash
cd ../backend-java-spring

# Asenda oma proxy aadress!
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -f ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized.proxy \
  -t todo-service:1.0-optimized .

# Kontrolli
docker images | grep todo-service
```

##### 3. Jätka Lab 2'ga

```bash
cd ../../02-docker-compose-lab/compose-project
docker compose up -d
```

**📖 Põhjalikud juhendid:**
- [Lab 1 Node.js Proxy README](../01-docker-lab/solutions/backend-nodejs/README-PROXY.md) - ARG, ENV, npm proxy konfiguratsioon
- [Lab 1 Java Proxy README](../01-docker-lab/solutions/backend-java-spring/README-PROXY.md) - Gradle GRADLE_OPTS parsing, multi-stage build

---

#### Stsenaarium D: Compose build: Direktiiv (VALIKULINE - Harva Kasutatud)

**Miks Lab 2 compose failid EI KASUTA `build:` direktiivi vaikimisi? 🤔**

1. **Lab 2 eesmärk:** Õpetab orkestreerimist, MITTE image ehitamist
   - Compose failid jäävad **lihtsamaks** ja **loetavamaks**
   - Fookus on teenuste orkestreerimise õppimisel

2. **Kiire startup:**
   - Image'd on juba ehitatud (Lab 1 või setup.sh)
   - `docker compose up` ei kuluta aega rebuild'imisele
   - Ideaalne harjutuste jaoks

3. **Selge vastutuste jaotus:**
   - **Lab 1:** Docker image'ite ehitamine (building)
   - **Lab 2:** Docker Compose orkestratsioon (orchestration)

**Kui siiski vajad `build:` direktiivi** (näiteks arenduses):

```yaml
# docker-compose.yml (VALIKULINE - harva vajalik)
services:
  user-service:
    build:
      context: ../apps/backend-nodejs
      dockerfile: ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized.proxy
      args:
        HTTP_PROXY: ${HTTP_PROXY:-http://proxy-chain.intel.com:911}
        HTTPS_PROXY: ${HTTPS_PROXY:-http://proxy-chain.intel.com:912}
    image: user-service:1.0-optimized
    # ... ülejäänud konfiguratsioon

  todo-service:
    build:
      context: ../apps/backend-java-spring
      dockerfile: ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized.proxy
      args:
        HTTP_PROXY: ${HTTP_PROXY:-http://proxy-chain.intel.com:911}
        HTTPS_PROXY: ${HTTPS_PROXY:-http://proxy-chain.intel.com:912}
    image: todo-service:1.0-optimized
    # ... ülejäänud konfiguratsioon
```

**Kasutamine:**
```bash
# Build ja käivita (rebuild'ib image'd iga kord)
docker compose up -d --build

# Ainult build
docker compose build

# Kasuta keskkonnamuutujaid
HTTP_PROXY=http://custom-proxy:8080 docker compose build
```

**⚠️ Märkus:** See lähenemisviis on harva vajalik Lab 2's. **Soovituslik:** Kasuta **Stsenaarium B** (setup.sh) või **Stsenaarium C** (käsitsi).

---

## 🚀 Quick Start

Lab 2'l on kaks alustamise viisi:

### Variant A: Setup Skript (Soovitatav algajatele ja kiireks testimiseks)

```bash
# Variant 1: Käivita igalt poolt (alias)
lab2-setup

# Variant 2: Käivita labori kataloogist
cd 02-docker-compose-lab
./setup.sh  # Või lihtsalt: lab2-setup
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
- **lab2-setup on mugavuse huvides** - kasuta, kui vajad kiiret starti või testimisandmeid
- **Soovitame esimest korda teha käsitsi**, et õppida Docker põhitõdesid



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

### Harjutus 7: Edasijõudnute mustrid (VALIKULINE)
**Fail:** [exercises/07-advanced-patterns.md](exercises/07-advanced-patterns.md)

Täiustatud Docker Compose mustrid:

- Docker Compose profiilid (dev, debug, prod)
- Andmeköite varundamine ja taastamine
- Võrgu tõrkeotsing (debug containers)
- Compose Watch režiim (auto-rebuild arenduses)

### Harjutus 8: Legacy Integration - Docker + Olemasolev Infrastruktuur (60-75 min)
**Fail:** [exercises/08-legacy-integration.md](exercises/08-legacy-integration.md)

Integreeri Dockerised rakendusi legacy infrastruktuuriga:

- Ühenda Docker konteinerid **välistele andmebaasidele** (simuleerib AWS RDS, Azure DB)
- Konfigureeri rakendused töötama **olemasoleva reverse proxy** taga
- Kasuta `host.docker.internal` host teenustega suhtlemiseks
- Simuleeri **3-tier enterprise arhitektuuri** (DB tier, App tier, LB tier)
- Mõista **hübriid-infrastruktuuri** mustreid (vana maailm + Docker maailm)

### Harjutus 9: Production Readiness - SSL, Failover, Health Checks, Monitoring (90-120 min)
**Fail:** [exercises/09-production-readiness.md](exercises/09-production-readiness.md)

Ettevalmistamine production deploy'iks:

- Konfigureeri **SSL/TLS terminatsiooni** Nginx'is (self-signed + Let's Encrypt)
- Implementeeri **high availability** (2 replicas per service, load balancing)
- Advanced **health checks** (startup, liveness, readiness probes)
- Seadista **Prometheus + Grafana** monitoring
- **Resource limits** ja **graceful shutdown**
- **Production best practices** (secrets management, backups, alerting)




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
**Viimane uuendus:** 2025-12-11
