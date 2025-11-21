# Harjutus 3: Docker Võrgundus (Networking)

**Kestus:** 45 minutit
**Eesmärk:** Loo kohandatud võrk (custom network) ja ühenda konteinerid korrektse võrgundusega (proper networking)

**Eeldus:** [Harjutus 2: Mitme-Konteineri (Multi-Container)](02-multi-container.md) läbitud ✅
💡 **Märkus:** Kui baaspildid (base images) (`user-service:1.0`, `todo-service:1.0`) puuduvad, käivita `./setup.sh` ja vali `Y`

---

## 📋 Ülevaade

Eelmises harjutuses kasutasime `--link` et ühendada konteinereid. See toimis, aga Docker soovitab kasutada **kohandatud võrke (custom networks)** selle asemel!

**Miks kohandatud võrgud (custom networks) on paremad kui --link?**
- ✅ Automaatne DNS lahendus (resolution) (konteineri nimi = hostname)
- ✅ Võrgu isolatsioon (network isolation) (erinevad projektid erinevates võrkudes (networks))
- ✅ Turvalisem (--link on aegunud (deprecated))
- ✅ Skaaleerib paremini (lihtne lisada/eemaldada konteinereid)
- ✅ Tänapäevane parim praktika (best practice)

**Selles harjutuses:**
- Loome kohandatud võrgu (custom network) `todo-network`
- Käivitame KÕIK 4 konteinerit (2 PostgreSQL + User Teenus (Service) + Todo Teenus (Service))
- Aga kasutame korrektset võrgundust (proper networking) (mitte --link!)
- Testime End-to-End JWT workflow'i kohandatud võrgus (custom network)

---

## 🎯 Õpieesmärgid

- ✅ Luua kohandatud (custom) Docker võrk (network)
- ✅ Käivitada 4 konteinerit samas võrgus (network)
- ✅ Kasutada DNS hostname lahendust (resolution) (automaatne!)
- ✅ Testida teenuste (services) vahelist suhtlust (User Teenus (Service) ↔ Todo Teenus (Service))
- ✅ Testida End-to-End JWT workflow'i
- ✅ Inspekteerida võrgu (network) konfiguratsiooni
- ✅ Isoleerida teenused (services) võrkudega (networks)
- ✅ Mõista, miks see on parem kui --link

---

## 📝 Sammud

### Samm 1: Puhasta Keskkond (5 min)

```bash
# Stopp ja eemalda vanad konteinerid Harjutus 2-st
docker stop user-service todo-service postgres-user postgres-todo 2>/dev/null || true
docker rm user-service todo-service postgres-user postgres-todo 2>/dev/null || true

# Kontrolli, et kõik on puhastatud
docker ps -a | grep -E 'user-service|todo-service|postgres'
# Peaks olema tühi
```

### Samm 2: Loo Kohandatud Võrk (Custom Network) (5 min)

```bash
# Loo silla (bridge) võrk (network) todo-network
docker network create todo-network

# Vaata kõiki võrke (networks)
docker network ls
# Peaks näitama:
# - bridge (default)
# - host
# - none
# - todo-network (uus!)

# Inspekteeri todo-network detaile
docker network inspect todo-network
```

**Mida näed?**
- Network tüüp: bridge
- Subnet: näiteks 172.18.0.0/16
- Gateway: näiteks 172.18.0.1
- Konteinerid: [] (tühi, sest pole veel ühtegi konteinerit lisatud)

### Samm 3: Käivita PostgreSQL Konteinerid Samas Võrgus (Network) (10 min)

**Nüüd käivitame MÕLEMAD PostgreSQL konteinerit samas kohandatud võrgus (custom network):**

```bash
# PostgreSQL User Teenusele (Service)
docker run -d \
  --name postgres-user \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  postgres:16-alpine

# PostgreSQL Todo Teenusele (Service)
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  postgres:16-alpine

# Kontrolli mõlemat
docker ps | grep postgres
# Peaks näitama mõlemat: postgres-user JA postgres-todo
```

**Märka:** EI kasuta `-p` portide vastendamist (port mapping), sest PostgreSQL on ainult sisemiselt kättesaadav (võrgu isolatsioon (network isolation)!)

### Samm 4: Seadista Andmebaasid (10 min)

```bash
# Loo users tabel User Teenuse (Service) andmebaasis
docker exec -i postgres-user psql -U postgres -d user_service_db <<EOF
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Kontrolli User Teenuse (Service) tabel
docker exec postgres-user psql -U postgres -d user_service_db -c "\dt"
# Peaks näitama: users tabel

# Loo todos tabel Todo Teenuse (Service) andmebaasis
docker exec -i postgres-todo psql -U postgres -d todo_service_db <<EOF
CREATE TABLE todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    priority VARCHAR(20) DEFAULT 'medium',
    due_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Kontrolli Todo Teenuse (Service) tabel
docker exec postgres-todo psql -U postgres -d todo_service_db -c "\dt"
# Peaks näitama: todos tabel
```

### Samm 5: Genereeri Jagatud JWT Secret (5 min)

**OLULINE:** Mõlemad teenused (services) peavad kasutama SAMA JWT_SECRET'i!

```bash
# Genereeri turvaline 256-bitine võti
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET=$JWT_SECRET"

# Salvesta see muutujana (kasutame mõlemas teenuses!)
export JWT_SECRET

# Kontrolli, et muutuja on seatud
echo "Kontroll: $JWT_SECRET"
```

### Samm 6: Käivita User Teenus (Service) (10 min)

```bash
# User Teenuse (Service) konteiner samas võrgus (network)
docker run -d \
  --name user-service \
  --network todo-network \
  -p 3000:3000 \
  -e DB_HOST=postgres-user \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=$JWT_SECRET \
  -e JWT_EXPIRES_IN=24h \
  -e NODE_ENV=production \
  -e PORT=3000 \
  user-service:1.0

# Vaata logisid
docker logs -f user-service
# Vajuta Ctrl+C kui näed: "Server running on port 3000"
```

**✨ MAAGIA #1:** Kasutame konteineri nime `postgres-user` otse hostname'ina!
- ❌ Harjutus 2: Vajasime `--link postgres-user:postgres`
- ✅ Harjutus 3: Lihtsalt kasuta `DB_HOST=postgres-user` (automaatne DNS!)

### Samm 7: Käivita Todo Teenus (Service) (10 min)

```bash
# Todo Teenuse (Service) konteiner samas võrgus (network)
docker run -d \
  --name todo-service \
  --network todo-network \
  -p 8081:8081 \
  -e DB_HOST=postgres-todo \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=$JWT_SECRET \
  -e SPRING_PROFILES_ACTIVE=prod \
  todo-service:1.0

# Vaata logisid
docker logs -f todo-service
# Vajuta Ctrl+C kui näed: "Started TodoApplication in X.XX seconds"
```

**✨ MAAGIA #2:** Kasutame konteineri nime `postgres-todo` otse hostname'ina!

**Kontrolli, et kõik 4 konteinerit töötavad:**

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Oodatud väljund:
# NAMES              STATUS          PORTS
# todo-service       Up X minutes    0.0.0.0:8081->8081/tcp
# user-service       Up X minutes    0.0.0.0:3000->3000/tcp
# postgres-todo      Up X minutes    5432/tcp (sisemiselt!)
# postgres-user      Up X minutes    5432/tcp (sisemiselt!)
```

### Samm 8: Testi DNS Lahendust (Resolution) (15 min)

**See on kõige huvitavam osa!** Vaatame, kuidas Docker automaatselt lahendab (resolves) konteinerite nimesid.

#### 8a. Testi DNS Todo Teenusest (Service)

```bash
# Sisene Todo Teenuse (Service) konteinerisse
docker exec -it todo-service sh

# Konteineri sees - testi DNS lahendust (resolution)
# Installi võrgu (network) tööriistad
apk add --no-cache bind-tools curl

# Test 1: Kas näeme PostgreSQL'i?
nslookup postgres-todo
# Peaks näitama: Name: postgres-todo, Address: 172.18.0.X

# Test 2: Kas näeme teist teenust (service) (User Teenus (Service))?
nslookup user-service
# Peaks näitama: Name: user-service, Address: 172.18.0.Y

# Test 3: Testi ühendust User Teenusega (Service)
curl http://user-service:3000/health
# Oodatud: {"status":"OK","database":"connected"}

# Vaata DNS konfiguratsiooni
cat /etc/resolv.conf
# nameserver peaks olema Docker'i DNS server (127.0.0.11)

exit
```

#### 8b. Testi DNS User Teenusest (Service)

```bash
# Sisene User Teenuse (Service) konteinerisse
docker exec -it user-service sh

# Installi võrgu (network) tööriistad
apk add --no-cache bind-tools curl

# Test 1: Kas näeme oma PostgreSQL'i?
nslookup postgres-user
# Peaks näitama: Name: postgres-user, Address: 172.18.0.X

# Test 2: Kas näeme Todo Teenust (Service)?
nslookup todo-service
# Peaks näitama: Name: todo-service, Address: 172.18.0.Z

# Test 3: Testi ühendust Todo Teenusega (Service)
curl http://todo-service:8081/health
# Oodatud: {"status":"UP"}

exit
```

**✨ MAAGIA #3:** Teenused (services) näevad teineteist automaatselt!
- ✅ User Teenus (Service) ↔ Todo Teenus (Service) suhtlus töötab
- ✅ Iga teenus (service) näeb oma PostgreSQL'i
- ✅ DNS lahendus (resolution) on automaatne (konteineri nimi = hostname!)

**Mida õppisid?**
- Docker loob automaatse DNS serveri igale kohandatud võrgule (custom network) (127.0.0.11)
- Konteineri nimi = automaatne DNS hostname
- Ei vaja --link ega IP aadresse!
- Teenused (services) saavad omavahel suhelda HTTP kaudu

### Samm 9: Inspekteeri Võrku (Network) (5 min)

```bash
# Vaata todo-network detaile
docker network inspect todo-network

# Peaks näitama KÕIK 4 konteinerit:
# - "Containers": {
#     "abc123...": {
#       "Name": "postgres-user",
#       "IPv4Address": "172.18.0.2/16"
#     },
#     "def456...": {
#       "Name": "postgres-todo",
#       "IPv4Address": "172.18.0.3/16"
#     },
#     "ghi789...": {
#       "Name": "user-service",
#       "IPv4Address": "172.18.0.4/16"
#     },
#     "jkl012...": {
#       "Name": "todo-service",
#       "IPv4Address": "172.18.0.5/16"
#     }
#   }

# Näita ainult konteinerite nimesid ja IP'd
docker network inspect todo-network | grep -E '"Name"|"IPv4Address"'
```

**Vaata:**
- KÕIK 4 konteinerit on samas võrgus (network) ✅
- Igal konteineril on oma IP aadress ✅
- Need IP'd on samast alamvõrgust (subnet) (172.18.0.0/16) ✅
- Võrgu isolatsioon (network isolation) toimib (välismaailm ei näe PostgreSQL porte!) ✅

### Samm 10: Testi Seisukorra Kontroll (Health Check) (5 min)

```bash
# User Teenuse (Service) seisukorra kontroll (health check)
curl http://localhost:3000/health
# Oodatud: {"status":"OK","database":"connected"}

# Todo Teenuse (Service) seisukorra kontroll (health check)
curl http://localhost:8081/health
# Oodatud:
# {
#   "status": "UP",
#   "components": {
#     "db": { "status": "UP" },
#     "diskSpace": { "status": "UP" }
#   }
# }
```

**Kui mõlemad on "OK"/"UP" - SUUREPÄRANE!** 🎉
- Võrk (network) on korrektne ✅
- Mõlemad PostgreSQL'id on kättesaadavad ✅
- DNS lahendus (resolution) toimib ✅
- Mõlemad teenused (services) on terved ✅

### Samm 11: Testi End-to-End JWT Workflow'i (15 min)

**See on KÕIGE OLULISEM TEST!** Testib täielikku mikroteenuste (microservices) suhtlust kohandatud võrgus (custom network).

```bash
# 1. Registreeri kasutaja User Teenuses (Service)
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Network Test User",
    "email": "network@example.com",
    "password": "test123"
  }'

# Oodatud vastus:
# {
#   "token": "eyJhbGci...",
#   "user": {
#     "id": 1,
#     "email": "network@example.com",
#     "name": "Network Test User",
#     "role": "user"
#   }
# }

# 2. Login ja salvesta JWT token
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"network@example.com","password":"test123"}' \
  | jq -r '.token')

echo "JWT Token: $TOKEN"

# 3. Kasuta tokenit Todo Teenuses (Service) (MIKROTEENUSTE (MICROSERVICES) SUHTLUS!)
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Õpi Kohandatud Võrke (Custom Networks)",
    "description": "Docker võrgundus (networking) on nüüd selge!",
    "priority": "high",
    "dueDate": "2025-11-20T18:00:00"
  }' | jq

# Oodatud vastus:
# {
#   "id": 1,
#   "userId": 1,  <-- ekstraktitud JWT tokenist!
#   "title": "Õpi Kohandatud Võrke (Custom Networks)",
#   "description": "Docker võrgundus (networking) on nüüd selge!",
#   "completed": false,
#   "priority": "high",
#   "dueDate": "2025-11-20T18:00:00",
#   "createdAt": "...",
#   "updatedAt": "..."
# }

# 4. Loe todos
curl -X GET http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN" | jq

# 5. Märgi todo tehtud
curl -X PATCH http://localhost:8081/api/todos/1/complete \
  -H "Authorization: Bearer $TOKEN"

# 6. Kontrolli andmebaasis
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT id, user_id, title, completed FROM todos;"
```

**🎉 KUI KÕIK TOIMIS - ÕNNITLEME!**

**Mida sa just saavutasid:**
1. ✅ User Teenus (Service) genereeris JWT tokeni
2. ✅ Todo Teenus (Service) valideeris tokenit (SAMA JWT_SECRET!)
3. ✅ Todo Teenus (Service) ekstraktis userId tokenist (userId: 1)
4. ✅ CRUD operatsioonid töötasid mikroteenuste (microservices) vahel
5. ✅ Kohandatud võrk (custom network) võimaldas automaatset DNS lahendust (resolution)
6. ✅ Mõlemad teenused (services) suhtlesid oma andmebaasidega

**See on täielik mikroteenuste (microservices) arhitektuur kohandatud võrgus (custom network)!** 🚀

---

## 🎓 Õpitud Mõisted

### Kohandatud Silla (Bridge) Võrgud (Networks):
- `docker network create <nimi>` - Loo võrk (network)
- `docker network ls` - Näita kõiki võrke (networks)
- `docker network inspect <nimi>` - Vaata detaile
- `--network <nimi>` - Ühenda konteiner võrguga (network)

### DNS Lahendus (Resolution):
- Konteineri nimi = automaatne hostname
- Docker sisseehitatud DNS server (127.0.0.11)
- Ei vaja --link ega IP aadresse

### Võrgu Isolatsioon (Network Isolation):
- Erinevad võrgud (networks) = isoleeritud
- Ainult sama võrgu (network) konteinerid saavad omavahel rääkida
- Turvalisuse eelis!

---

## 📊 Võrdlus: --link (Harjutus 2) vs Kohandatud Võrk (Custom Network) (Harjutus 3)

| Aspekt | --link (Harjutus 2) | Kohandatud Võrk (Custom Network) (Harjutus 3) |
|--------|---------------------|----------------------------|
| **Staatus** | ❌ Aegunud (deprecated) | ✅ Soovitatav (recommended) |
| **DNS** | `--link postgres-todo:postgres` (alias) | `DB_HOST=postgres-todo` (automaatne!) |
| **Isolatsioon** | ❌ Kõik samas vaikimisi sillas (default bridge) | ✅ Eraldi võrk (network) (todo-network) |
| **Skaleeritavus** | ❌ --link on 1:1 seos | ✅ Lisa/eemalda konteinereid lihtsalt |
| **Teenuste (services) suhtlus** | ❌ Ainult --link'itud konteinerid | ✅ Kõik sama võrgu (network) konteinerid |
| **Turvalisus** | ❌ Madalam (jagatud vaikimisi võrk (default network)) | ✅ Kõrgem (isoleeritud võrk (network)) |
| **Keerukus** | Vajab --link iga ühenduse jaoks | Lihtsalt lisa --network todo-network |
| **Parim praktika (best practice)** | ❌ EI (Docker soovitab mitte kasutada) | ✅ JAH (tänapäevane standard) |

**Järeldus:** Kasuta ALATI kohandatud võrke (custom networks), mitte --link!
---

## 🎉 Õnnitleme! Mida Sa Õppisid?

### ✅ Tehnilised Oskused

**Kohandatud (Custom) Docker Võrgud (Networks):**
- ✅ Lõid kohandatud silla (bridge) võrgu (network) (`docker network create`)
- ✅ Käivitasid 4 konteinerit samas võrgus (network)
- ✅ Kasutasid automaatset DNS lahendust (resolution) (konteineri nimi = hostname)
- ✅ Inspekteerisid võrgu (network) konfiguratsiooni
- ✅ Testisid teenuste (services) vahelist suhtlust

**Mikroteenuste (Microservices) Arhitektuur:**
- ✅ Käivitasid täieliku mikroteenuste (microservices) süsteemi (2 DB + 2 teenust (services))
- ✅ Testisid End-to-End JWT workflow'i
- ✅ Mõistsid, kuidas teenused (services) omavahel suhtlevad
- ✅ Kasutasid võrgu isolatsiooni (network isolation) turvalisuse jaoks

**Docker Võrgunduse (Networking) Kontseptsioonid:**
- ✅ Kohandatud võrgud (custom networks) vs vaikimisi sild (default bridge)
- ✅ DNS lahendus (resolution) konteinerite vahel
- ✅ Võrgu isolatsioon (network isolation) (PostgreSQL ei ole väliselt kättesaadav)
- ✅ Portide vastendamine (port mapping) (ainult teenused (services) on väliselt kättesaadavad: 3000, 8081)
- ✅ Konteinerite-vaheline (container-to-container) kommunikatsioon

### 🔄 Võrreldes Harjutus 2-ga

**Mida muutsime:**
- ❌ `--link postgres-todo:postgres` (aegunud (deprecated))
- ✅ `--network todo-network` (soovitatav)

**Mida võitsime:**
- ✅ Automaatne DNS lahendus (resolution) (ei vaja aliaseid)
- ✅ Parem isolatsioon (eraldi võrk (network))
- ✅ Lihtsam skaleerida (lisa uusi konteinereid lihtsalt)
- ✅ Tänapäevane parim praktika (best practice)

### 🚀 Järgmised Sammud

**Harjutus 4: Andmehoidlad (Volumes)** õpetab:
- Kuidas säilitada andmed pärast konteineri kustutamist
- Miks andmehoidlad (volumes) on kriitilised tootmises
- Kuidas teha varukoopiat/taastada (backup/restore)

**Jätka:** [Harjutus 4: Andmehoidlad (Volumes)](04-volumes.md)

---

## 💡 Parimad Praktikad (Best Practices)

**Kohandatud Võrgud (Custom Networks):**
1. **Kasuta alati kohandatud võrke (custom networks)** - Mitte vaikimisi silda (default bridge)
2. **Anna võrgule (network) mõistlik nimi** - `todo-network`, mitte `network1`
3. **Üks võrk (network) projekti/stack'i kohta** - Isolatsioon!
4. **Kasuta konteinerite nimesid hostname'idena** - Automaatne DNS
5. **Ära vasta PostgreSQL porte välismaailma** - Turvalisus!

**Konteinerite Nimetamine:**
1. **Kasuta kirjeldavaid nimesid** - `postgres-user`, mitte `db1`
2. **Järjepidev nimetamine** - `<service>-<purpose>` (postgres-user, postgres-todo)
3. **Konteineri nimi = DNS hostname** - Pane tähele!

**Turvalisus:**
1. **Võrgu isolatsioon (network isolation)** - Ainult vajalikud konteinerid samas võrgus (network)
2. **Portide vastendamine (port mapping)** - Ainult väliselt vajalikud portid (3000, 8081)
3. **Sisemised teenused (internal services)** - PostgreSQL ilma `-p` (ainult sisemiselt kättesaadav)

---

## 📚 Viited

- [Docker Networking Overview](https://docs.docker.com/network/)
- [User-defined bridge networks](https://docs.docker.com/network/bridge/)
- [Container networking](https://docs.docker.com/config/containers/container-networking/)
- [Docker DNS resolution](https://docs.docker.com/network/bridge/#configure-the-default-bridge-network)

---

**Õnnitleme! Oled loonud production-ready võrgu seadistuse (network setup)! 🎉**

**Järgmine:** [Harjutus 4: Andmehoidlad (Volumes)](04-volumes.md) - Õpi, kuidas säilitada andmed!
