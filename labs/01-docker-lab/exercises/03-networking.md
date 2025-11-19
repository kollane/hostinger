# Harjutus 3: Docker Networking

**Kestus:** 45 minutit
**Eesmärk:** Loo custom network ja ühenda containerid proper networking'uga

**Eeldus:** [Harjutus 2: Multi-Container](02-multi-container.md) läbitud ✅

---

## 📋 Ülevaade

Eelmises harjutuses kasutasime `--link` et ühendada kontenereid. See toimis, aga Docker soovitab kasutada **custom networks** selle asemel!

**Miks custom networks on paremad kui --link?**
- ✅ Automaatne DNS resolution (container nimi = hostname)
- ✅ Network isolation (erinevad projektid erinevates networks)
- ✅ Turvalisem (--link on deprecated)
- ✅ Skaaleerib paremini (lihtne lisada/eemaldada containereid)
- ✅ Tänapäevane best practice

**Selles harjutuses:**
- Loome custom network `todo-network`
- Käivitame KÕIK 4 containerit (2 PostgreSQL + User Service + Todo Service)
- Aga kasutame proper networking'ut (mitte --link!)
- Testame End-to-End JWT workflow'i custom network'is

---

## 🎯 Õpieesmärgid

- ✅ Luua custom Docker network
- ✅ Käivitada 4 containerit samas network'is
- ✅ Kasutada DNS hostname resolution (automaatne!)
- ✅ Testida teenuste vahelist suhtlust (User Service ↔ Todo Service)
- ✅ Testida End-to-End JWT workflow'i
- ✅ Inspekteerida network konfiguratsiooni
- ✅ Isoleerida teenused network'idega
- ✅ Mõista, miks see on parem kui --link

---

## 📝 Sammud

### Samm 1: Puhasta Keskkond (5 min)

```bash
# Stopp ja eemalda vanad containerid Harjutus 2-st
docker stop user-service todo-service postgres-user postgres-todo 2>/dev/null || true
docker rm user-service todo-service postgres-user postgres-todo 2>/dev/null || true

# Kontrolli, et kõik on puhastatud
docker ps -a | grep -E 'user-service|todo-service|postgres'
# Peaks olema tühi
```

### Samm 2: Loo Custom Network (5 min)

```bash
# Loo bridge network todo-network
docker network create todo-network

# Vaata kõiki network'e
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
- Containers: [] (tühi, sest pole veel ühtegi containerit lisatud)

### Samm 3: Käivita PostgreSQL Containerid Samas Network'is (10 min)

**Nüüd käivitame MÕLEMAD PostgreSQL containerit samas custom network'is:**

```bash
# PostgreSQL User Service'ile
docker run -d \
  --name postgres-user \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  postgres:16-alpine

# PostgreSQL Todo Service'ile
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

**Märka:** EI kasuta `-p` port mapping'ut, sest PostgreSQL on ainult sisemiselt kättesaadav (network isolation!)

### Samm 4: Seadista Andmebaasid (10 min)

```bash
# Loo users tabel User Service andmebaasis
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

# Kontrolli User Service tabel
docker exec postgres-user psql -U postgres -d user_service_db -c "\dt"
# Peaks näitama: users tabel

# Loo todos tabel Todo Service andmebaasis
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

# Kontrolli Todo Service tabel
docker exec postgres-todo psql -U postgres -d todo_service_db -c "\dt"
# Peaks näitama: todos tabel
```

### Samm 5: Genereeri Jagatud JWT Secret (5 min)

**OLULINE:** Mõlemad teenused peavad kasutama SAMA JWT_SECRET'i!

```bash
# Genereeri turvaline 256-bitine võti
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET=$JWT_SECRET"

# Salvesta see muutujana (kasutame mõlemas teenuses!)
export JWT_SECRET

# Kontrolli, et muutuja on seatud
echo "Kontroll: $JWT_SECRET"
```

### Samm 6: Käivita User Service (10 min)

```bash
# User Service container samas network'is
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

**✨ MAAGIA #1:** Kasutame container nime `postgres-user` otse hostname'ina!
- ❌ Harjutus 2: Vajasime `--link postgres-user:postgres`
- ✅ Harjutus 3: Lihtsalt kasuta `DB_HOST=postgres-user` (automaatne DNS!)

### Samm 7: Käivita Todo Service (10 min)

```bash
# Todo Service container samas network'is
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

**✨ MAAGIA #2:** Kasutame container nime `postgres-todo` otse hostname'ina!

**Kontrolli, et kõik 4 containerit töötavad:**

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Oodatud väljund:
# NAMES              STATUS          PORTS
# todo-service       Up X minutes    0.0.0.0:8081->8081/tcp
# user-service       Up X minutes    0.0.0.0:3000->3000/tcp
# postgres-todo      Up X minutes    5432/tcp (sisemiselt!)
# postgres-user      Up X minutes    5432/tcp (sisemiselt!)
```

### Samm 8: Testi DNS Resolution (15 min)

**See on kõige huvitavam osa!** Vaatame, kuidas Docker automaatselt resolvib container nimesid.

#### 8a. Testi DNS Todo Service'ist

```bash
# Sisene Todo Service containerisse
docker exec -it todo-service sh

# Container sees - testi DNS resolution
# Installi network tools
apk add --no-cache bind-tools curl

# Test 1: Kas näeme PostgreSQL'i?
nslookup postgres-todo
# Peaks näitama: Name: postgres-todo, Address: 172.18.0.X

# Test 2: Kas näeme teist teenust (User Service)?
nslookup user-service
# Peaks näitama: Name: user-service, Address: 172.18.0.Y

# Test 3: Testi ühendust User Service'iga
curl http://user-service:3000/health
# Oodatud: {"status":"OK","database":"connected"}

# Vaata DNS konfiguratsiooni
cat /etc/resolv.conf
# nameserver peaks olema Docker'i DNS server (127.0.0.11)

exit
```

#### 8b. Testi DNS User Service'ist

```bash
# Sisene User Service containerisse
docker exec -it user-service sh

# Installi network tools
apk add --no-cache bind-tools curl

# Test 1: Kas näeme oma PostgreSQL'i?
nslookup postgres-user
# Peaks näitama: Name: postgres-user, Address: 172.18.0.X

# Test 2: Kas näeme Todo Service'i?
nslookup todo-service
# Peaks näitama: Name: todo-service, Address: 172.18.0.Z

# Test 3: Testi ühendust Todo Service'iga
curl http://todo-service:8081/health
# Oodatud: {"status":"UP"}

exit
```

**✨ MAAGIA #3:** Teenused näevad teineteist automaatselt!
- ✅ User Service ↔ Todo Service suhtlus töötab
- ✅ Iga teenus näeb oma PostgreSQL'i
- ✅ DNS resolution on automaatne (container nimi = hostname!)

**Mida õppisid?**
- Docker loob automaatse DNS serveri igale custom networkile (127.0.0.11)
- Container nimi = automaatne DNS hostname
- Ei vaja --link ega IP aadresse!
- Teenused saavad omavahel suhelda HTTP kaudu

### Samm 9: Inspekteeri Network (5 min)

```bash
# Vaata todo-network detaile
docker network inspect todo-network

# Peaks näitama KÕIK 4 containerit:
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

# Näita ainult container nimesid ja IP'd
docker network inspect todo-network | grep -E '"Name"|"IPv4Address"'
```

**Vaata:**
- KÕIK 4 containerit on samas network'is ✅
- Igal containeril on oma IP aadress ✅
- Need IP'd on samast subnet'ist (172.18.0.0/16) ✅
- Network isolation toimib (välismaailm ei näe PostgreSQL porte!) ✅

### Samm 10: Testi Health Check'e (5 min)

```bash
# User Service health check
curl http://localhost:3000/health
# Oodatud: {"status":"OK","database":"connected"}

# Todo Service health check
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
- Network on korrektne ✅
- Mõlemad PostgreSQL'id on kättesaadavad ✅
- DNS resolution toimib ✅
- Mõlemad teenused on terved ✅

### Samm 11: Testi End-to-End JWT Workflow'i (15 min)

**See on KÕIGE OLULISEM TEST!** Testib täielikku mikroteenuste suhtlust custom network'is.

```bash
# 1. Registreeri kasutaja User Service'is
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

# 3. Kasuta tokenit Todo Service'is (MIKROTEENUSTE SUHTLUS!)
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Õpi Custom Networks",
    "description": "Docker networking on nüüd selge!",
    "priority": "high",
    "dueDate": "2025-11-20T18:00:00"
  }' | jq

# Oodatud vastus:
# {
#   "id": 1,
#   "userId": 1,  <-- ekstraktitud JWT tokenist!
#   "title": "Õpi Custom Networks",
#   "description": "Docker networking on nüüd selge!",
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
1. ✅ User Service genereeris JWT tokeni
2. ✅ Todo Service valideeris tokenit (SAMA JWT_SECRET!)
3. ✅ Todo Service ekstraktis userId tokenist (userId: 1)
4. ✅ CRUD operatsioonid töötasid mikroteenuste vahel
5. ✅ Custom network võimaldas automaatset DNS resolution'i
6. ✅ Mõlemad teenused suhtlesid oma andmebaasidega

**See on täielik mikroteenuste arhitektuur custom network'is!** 🚀

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [x] `todo-network` on loodud (`docker network ls`)
- [x] KÕIK 4 containerit töötavad samas network'is (`docker ps`)
- [x] Network inspect näitab kõiki containereid (`docker network inspect todo-network`)
- [x] DNS resolution töötab mõlemas suunas (User Service ↔ Todo Service)
- [x] Mõlemad teenused ühenduvad oma PostgreSQL'idega
- [x] Health check'id töötavad mõlemas teenuses (`/health`)
- [x] End-to-End JWT workflow töötab (User Service → Todo Service)
- [x] **Ei kasuta --link** (kasutab custom network!) ✅
- [x] Mõistad, miks custom networks > --link

---

## 🎓 Õpitud Mõisted

### Custom Bridge Networks:
- `docker network create <nimi>` - Loo network
- `docker network ls` - Näita kõiki network'e
- `docker network inspect <nimi>` - Vaata detaile
- `--network <nimi>` - Ühenda container network'iga

### DNS Resolution:
- Container nimi = automaatne hostname
- Docker sisseehitatud DNS server (127.0.0.11)
- Ei vaja --link ega IP aadresse

### Network Isolation:
- Erinevad networks = isoleeritud
- Ainult sama network'i containerid saavad omavahel rääkida
- Security benefit!

---

## 📊 Võrdlus: --link (Harjutus 2) vs Custom Network (Harjutus 3)

| Aspekt | --link (Harjutus 2) | Custom Network (Harjutus 3) |
|--------|---------------------|----------------------------|
| **Status** | ❌ Deprecated (aegunud) | ✅ Recommended (soovitatav) |
| **DNS** | `--link postgres-todo:postgres` (alias) | `DB_HOST=postgres-todo` (automaatne!) |
| **Isolation** | ❌ Kõik samas default bridge'is | ✅ Eraldi network (todo-network) |
| **Skaleeritavus** | ❌ --link on 1:1 seos | ✅ Lisa/eemalda containereid lihtsalt |
| **Teenuste suhtlus** | ❌ Ainult --link'itud containerid | ✅ Kõik sama network'i containerid |
| **Security** | ❌ Madalam (jagatud default network) | ✅ Kõrgem (isoleeritud network) |
| **Complexity** | Vajab --link iga ühenduse jaoks | Lihtsalt lisa --network todo-network |
| **Best practice** | ❌ EI (Docker soovitab mitte kasutada) | ✅ JAH (tänapäevane standard) |

**Järeldus:** Kasuta ALATI custom networks, mitte --link!
---

## 🎉 Õnnitleme! Mida Sa Õppisid?

### ✅ Tehnilised Oskused

**Custom Docker Networks:**
- ✅ Lõid custom bridge network'i (`docker network create`)
- ✅ Käivitasid 4 containerit samas network'is
- ✅ Kasutasid automaatset DNS resolution'i (container nimi = hostname)
- ✅ Inspekteerisid network konfiguratsiooni
- ✅ Testisid teenuste vahelist suhtlust

**Mikroteenuste Arhitektuur:**
- ✅ Käivitasid täieliku mikroteenuste süsteemi (2 DB + 2 teenust)
- ✅ Testisid End-to-End JWT workflow'i
- ✅ Mõistsid, kuidas teenused omavahel suhtlevad
- ✅ Kasutasid network isolation'i turvalisuse jaoks

**Docker Networking Kontseptsioonid:**
- ✅ Custom networks vs default bridge
- ✅ DNS resolution containerite vahel
- ✅ Network isolation (PostgreSQL ei ole väliselt kättesaadav)
- ✅ Port mapping (ainult teenused on väliselt kättesaadavad: 3000, 8081)
- ✅ Container-to-container communication

### 🔄 Võrreldes Harjutus 2-ga

**Mida muutsime:**
- ❌ `--link postgres-todo:postgres` (deprecated)
- ✅ `--network todo-network` (soovitatav)

**Mida võitsime:**
- ✅ Automaatne DNS resolution (ei vaja aliaseid)
- ✅ Parem isolation (eraldi network)
- ✅ Lihtsam skaleerida (lisa uusi containereid lihtsalt)
- ✅ Tänapäevane best practice

### 🚀 Järgmised Sammud

**Harjutus 4: Volumes** õpetab:
- Kuidas säilitada andmed pärast container'i kustutamist
- Miks volumes on kriitilised tootmises
- Kuidas teha backup/restore

**Jätka:** [Harjutus 4: Volumes](04-volumes.md)

---

## 💡 Parimad Tavad

**Custom Networks:**
1. **Kasuta alati custom networks** - Mitte default bridge
2. **Anna network'ile mõistlik nimi** - `todo-network`, mitte `network1`
3. **Üks network per projekt/stack** - Isolation!
4. **Kasuta container nimesid hostname'idena** - Automaatne DNS
5. **Ära map PostgreSQL porte välismaailma** - Security!

**Container Naming:**
1. **Kasuta kirjeldavaid nimesid** - `postgres-user`, mitte `db1`
2. **Järjepidev nimetamine** - `<service>-<purpose>` (postgres-user, postgres-todo)
3. **Container nimi = DNS hostname** - Pane tähele!

**Security:**
1. **Network isolation** - Ainult vajalikud containerid samas network'is
2. **Port mapping** - Ainult väliselt vajalikud portid (3000, 8081)
3. **Internal services** - PostgreSQL ilma `-p` (ainult sisemiselt kättesaadav)

---

## 📚 Viited

- [Docker Networking Overview](https://docs.docker.com/network/)
- [User-defined bridge networks](https://docs.docker.com/network/bridge/)
- [Container networking](https://docs.docker.com/config/containers/container-networking/)
- [Docker DNS resolution](https://docs.docker.com/network/bridge/#configure-the-default-bridge-network)

---

**Õnnitleme! Oled loonud production-ready network setup'i! 🎉**

**Järgmine:** [Harjutus 4: Volumes](04-volumes.md) - Õpi, kuidas säilitada andmed!
