# Labor 2: Docker Compose

**Kestus:** 5.25 tundi
**Eeldused:** Labor 1 läbitud (4 optimeeritud konteinerit), Peatükk 13 (Docker Compose)
**Eesmärk:** Õppida multi-container rakenduste orkestreerimist Docker Compose'iga ning turvalise võrgu segmenteerimise (network segmentation) põhitõdesid

---

## 📋 Ülevaade

Selles laboris õpid hallama mitut konteinerit korraga Docker Compose'i abil. **Lähtud Labor 1 lõpuseisust** (4 töötavat optimeeritud konteinerit) ja konverteerid need docker-compose.yml failiks, lisad Frontend teenuse (service) ning õpid parimaid praktikaid production-ready konfiguratsioonide loomiseks.

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

**Lab 1'st said:**
- ✅ 2 optimeeritud backend pilti (images) (multi-stage builds)
- ✅ 2 PostgreSQL andmebaasi (eraldi volumes)
- ✅ Kohandatud võrk (custom network) (todo-network)
- ✅ Manuaalsed `docker run` käsud iga konteineri jaoks

### Lab 2 Sihtolek (5 Teenust)

Lab 2 lõpus on sul töötamas **5 teenust (services)** Docker Compose'iga:

```
               Browser (http://kirjakast:8080)
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
- ✅ Frontend teenus (service) (5. komponent)
- ✅ .env failid salajaste haldamiseks
- ✅ Database migration'id Liquibase'iga
- ✅ Production-ready konfiguratsioonid

**Teenused (services):**
- **Frontend**: Nginx staatiliste failidega (static files) → Suhtleb mõlema backend'iga
- **User Service**: Node.js + Express → Autentimine, kasutajate haldus
- **Todo Service**: Java Spring Boot → Todo CRUD operatsioonid (Lab 1'st)
- **PostgreSQL x2**: Eraldi andmebaasid users ja todos jaoks

---

## 🎯 Õpieesmärgid

Peale selle labori läbimist oskad:

✅ Konverteerida mitme-konteineri (multi-container) seadistust Docker Compose failiks
✅ Kirjutada docker-compose.yml faile järgides parimaid praktikaid
✅ Implementeerida võrgu segmenteerimist (network segmentation) ja turvalisi portide konfiguratsioone
✅ Vähendada rünnaku pinda (attack surface) 96% (5 avalikku porti → 1 avalik port)
✅ Mõista 3-taseme arhitektuuri (DMZ → Backend → Database)
✅ Hallata keskkonna muutujaid (environment variables) .env failidega
✅ Kasutada docker-compose.override.yml pattern'i
✅ Implementeerida database migration'eid Liquibase'iga
✅ Konfigureerida production patterns (scaling, resource limits, health checks)
✅ Debuggida multi-container rakendusi

---

## 📂 Labori Struktuur

```
02-docker-compose-lab/
├── README.md                  # See fail
├── setup.sh                   # Automaatne seadistus
├── reset.sh                   # Labori ressursside puhastamine
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
    - ✅ `user-service:1.0-optimized` pilt (image) (~50MB, Node.js multi-stage build)
    - ✅ `todo-service:1.0-optimized` pilt (image) (~180MB, Java multi-stage build)
    - ✅ `postgres-user-data` andmehoidla (volume) (sisaldab users tabelit)
    - ✅ `postgres-todo-data` andmehoidla (volume) (sisaldab todos tabelit)
    - ✅ `todo-network` kohandatud võrk (custom bridge network)
    - ✅ 4 töötavat konteinerit (user-service, todo-service, 2x postgres)

### Tööriistad:
- [x] Docker Compose paigaldatud (`docker compose version` - v2.x)
- [x] Docker daemon töötab (`docker ps`)
- [x] Vähemalt 4GB vaba RAM
- [x] vim või muu text editor

### Teadmised:
- [x] **Labor 1:** Docker põhitõed (pildid (images), konteinerid, võrgud (networks), andmehoidlad (volumes))
- [x] **Peatükk 13:** Docker Compose põhimõtted
- [x] YAML failivorming
- [x] Keskkonna muutujad (environment variables)

---

## 🚀 Quick Start

Lab 2'l on kaks alustamise viisi:

### Variant A: Setup Skript (Soovitatav algajatele ja kiireks testimiseks)

```bash
cd 02-docker-compose-lab
./setup.sh
```

**Setup skript teeb:**
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
- Defineeri andmehoidlad (volumes) ja võrgud (networks)
- Kasuta olemasolevaid pilte (images) (user-service:1.0-optimized, todo-service:1.0-optimized)
- Testi End-to-End workflow

### Harjutus 2: Lisa Frontend Teenus (45 min)
**Fail:** [exercises/02-add-frontend.md](exercises/02-add-frontend.md)

Lisa Frontend (5. teenus):
- Loo frontend teenus (service) Nginx'iga
- Mount staatilised failid (static files) (HTML/CSS/JS)
- Konfigureeri portide vastendamine (port mapping) (8080:80)
- Testi brauseris

### Harjutus 3: Võrgu Segmenteerimine ja Portide Turvalisus (60 min)
**Fail:** [exercises/03-network-segmentation.md](exercises/03-network-segmentation.md)

Implementeeri turvaline võrgu arhitektuur:
- Loo 3-taseme võrgu arhitektuur (DMZ → Backend → Database)
- Eemalda avalikud pordid backend ja database teenustelt
- Kasuta localhost-only binding (127.0.0.1) development debug'imiseks
- Vähenda rünnaku pinda (attack surface) 96%
- Mõista võrgu segmenteerimise (network segmentation) põhimõtteid

### Harjutus 4: Environment Management (45 min)
**Fail:** [exercises/04-environment-management.md](exercises/04-environment-management.md)

Halda keskkonna muutujaid (environment variables):
- Loo .env fail salajastele (JWT_SECRET, DB_PASSWORD)
- Kasuta docker-compose.override.yml pattern'i
- Loo eraldi dev ja prod konfiguratsioonid

### Harjutus 5: Database Migrations Liquibase'iga (60 min)
**Fail:** [exercises/05-database-migrations.md](exercises/05-database-migrations.md)

Automatiseeri database schema:
- Loo Liquibase changelog failid
- Implementeeri init container pattern
- Käivita migration'id enne backend'i
- Rollback testimine

### Harjutus 6: Production Patterns (45 min)
**Fail:** [exercises/06-production-patterns.md](exercises/06-production-patterns.md)

Production-ready konfiguratsioon:
- Scaling (replicas)
- Resource limits (CPU, memory)
- Restart policies
- Seisukorra kontrollid (health checks) ja dependency management
- Logging konfiguratsioon

### Harjutus 7: Advanced Patterns (vajadusel)
**Fail:** [exercises/07-advanced-patterns.md](exercises/07-advanced-patterns.md)

Täiustatud mustrid (advanced patterns):
- Vaata faili detailide jaoks

---

## ⚡ Kiirstart Seadistus

### Automaatne Seadistus

Käivita setup script, mis kontrollib Lab 1 eeldusi:

```bash
# Käivita seadistus script
chmod +x setup.sh
./setup.sh
```

**Script kontrollib:**
- ✅ Docker Compose paigaldust
- ✅ Lab 1 piltide (images) olemasolu (user-service:1.0-optimized, todo-service:1.0-optimized)
- ✅ Lab 1 andmehoidlate (volumes) olemasolu (postgres-user-data, postgres-todo-data)
- ✅ Lab 1 võrgu (network) olemasolu (todo-network)

**Kui midagi puudub:**
- 💡 Script suunab sind tagasi Lab 1 juurde
- 💡 Või pakub võimalust luua puuduvad ressursid

---

### ⚡ Kiirkontroll: Kas Oled Valmis?

Enne labori alustamist veendu, et kõik Lab 1 ressursid on olemas:

```bash
# Kiirkontroll (kõik peaksid tagastama 0 või rohkem ridu)
echo "=== Docker Compose ==="
docker compose version

echo -e "\n=== Lab 1 Pildid (Images) ==="
docker images | grep -E "user-service.*optimized|todo-service.*optimized"

echo -e "\n=== Lab 1 Andmehoidlad (Volumes) ==="
docker volume ls | grep -E "postgres-user-data|postgres-todo-data"

echo -e "\n=== Lab 1 Võrk (Network) ==="
docker network ls | grep todo-network

echo -e "\n✅ Kui kõik on olemas, oled valmis!"
```
---

## ✅ Kontrolli Tulemusi

Peale labori läbimist pead omama:

### Docker Compose Failid:

- [ ] `docker-compose.yml` (4 teenust: 2x postgres, 2x backend)
- [ ] `docker-compose-full.yml` (5 teenust: + frontend)
- [ ] `docker-compose.prod.yml` (production variant)
- [ ] `.env` fail (salajased)
- [ ] `docker-compose.override.yml` (dev overrides)

### Töötavad Teenused (Harjutus 5 lõpus):

- [ ] Frontend (port 8080) - Nginx
- [ ] User Service (port 3000) - Node.js
- [ ] Todo Service (port 8081) - Java Spring
- [ ] PostgreSQL User DB (port 5432)
- [ ] PostgreSQL Todo DB (port 5433)

### Testimine:

**Frontend:**
- [ ] `http://kirjakast:8080` - avab login lehte
- [ ] Login toimib (suhtleb User Service'iga)
- [ ] Todo list kuvatakse (suhtleb Todo Service'iga)

**Backend API'd:**
- [ ] `curl http://localhost:3000/health` - User Service OK
- [ ] `curl http://localhost:8081/health` - Todo Service OK
- [ ] End-to-End JWT workflow toimib

**Docker Compose:**
- [ ] `docker compose ps` - kõik teenused UP ja HEALTHY
- [ ] `docker compose logs` - logid kättesaadavad
- [ ] Andmed püsivad peale `docker compose down && docker compose up`

---

## 📊 Progressi Jälgimine

- [ ] Harjutus 1: Docker Compose Alused (4 teenust)
- [ ] Harjutus 2: Lisa Frontend (5 teenust)
- [ ] Harjutus 3: Võrgu Segmenteerimine ja Portide Turvalisus
- [ ] Harjutus 4: Environment Management (.env failid)
- [ ] Harjutus 5: Database Migrations (Liquibase)
- [ ] Harjutus 6: Production Patterns (scaling, limits)
- [ ] Harjutus 7: Advanced Patterns (vajadusel)

---

## 🆘 Troubleshooting

### Probleem 1: "Lab 1 pildid (images) puuduvad"

```bash
# Kontrolli pilte (images)
docker images | grep optimized

# Kui puuduvad, mine Lab 1 juurde
cd ../01-docker-lab
cat exercises/05-optimization.md
```

### Probleem 2: "Andmehoidlad (volumes) puuduvad või on tühjad"

```bash
# Kontrolli andmehoidlaid (volumes)
docker volume ls | grep postgres

# Kui puuduvad, loo need Lab 1's
cd ../01-docker-lab
cat exercises/04-volumes.md
```

### Probleem 3: "docker compose up ebaõnnestub"

```bash
# Kontrolli YAML syntax'it
docker compose config

# Vaata detailseid vigu (errors)
docker compose up --verbose
```

### Probleem 4: "Port juba kasutusel"

```bash
# Vaata, mis kasutab porti
sudo lsof -i :3000
sudo lsof -i :8081
sudo lsof -i :8080

# Peata konfliktis olevad konteinerid
docker ps -a | grep -E "3000|8081|8080"
docker stop <container-id>
```

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
- ✅ Lisanud Frontend teenuse (service) ja loonud täieliku 5-tier süsteemi
- ✅ Õppinud hallama keskkonna muutujaid (environment variables) turvaliselt
- ✅ Implementeerinud database migration'id Liquibase'iga
- ✅ Konfigureerinud production-ready Compose seadistused
- ✅ Debugginud multi-container rakendusi
- ✅ Valmis Kubernetes'e migreerumiseks (Lab 3)

**Edu laboriga! 🚀**

---

**Staatus:** 🏗️ Ülesehitamisel
**Viimane uuendus:** 2025-11-21
