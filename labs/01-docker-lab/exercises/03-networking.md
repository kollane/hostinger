# Harjutus 3: Docker võrgundus (Networking)

**Eeldused:**
- ✅ [Harjutus 2: Mitme konteineri seadistus](02-multi-container.md) läbitud
- 💡 **Märkus:** Kui baastõmmised (`user-service:1.0`, `todo-service:1.0`) puuduvad, käivita `lab1-setup` ja vali `Y`

---

## 📋 Harjutuse ülevaade

Eelmises harjutuses kasutasime `--link` et ühendada konteinereid. See toimis, aga Docker soovitab kasutada **kohandatud võrke (docker networks)**!

**Miks kohandatud võrgud (docker networks) on paremad kui --link?**
- ✅ Automaatne DNS lahendus (konteineri nimi = hostinimi)
- ✅ Võrgu isolatsioon (erinevad projektid erinevates võrkudes)
- ✅ Turvalisem (--link on aegunud)
- ✅ Skaleerib paremini (lihtne lisada/eemaldada konteinereid)
- ✅ Tänapäevane parim praktika

**Selles harjutuses:**
- Loome kohandatud võrgu `todo-network`
- Käivitame KÕIK 4 konteinerit (2 PostgreSQL + User Service + Todo Service)
- Kasutame korrektset võrgundust (mitte --link!)
- Testime End-to-End JWT töövoogu kohandatud võrgus

## 📝 Sammud

### Samm 1: Puhasta keskkond

```bash
# Stopp ja eemalda vanad konteinerid eelmistest harjutustest
docker stop user-service todo-service postgres-user postgres-todo todo-service-test user-service-test 2>/dev/null || true
docker rm user-service todo-service postgres-user postgres-todo todo-service-test user-service-test 2>/dev/null || true

# Kontrolli, et kõik on puhastatud
docker ps -a | grep -E 'user-service|todo-service|postgres'
# Peaks olema tühi
```

### Samm 2: Loo kohandatud võrk

```bash
# Loo sildvõrk (bridge network) todo-network
docker network create todo-network

# Vaata kõiki võrke
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

### Samm 3: Käivita PostgreSQL konteinerid samas võrgus

**Nüüd käivitame MÕLEMAD PostgreSQL konteinerit samas kohandatud võrgus:**

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

**Märka:** EI kasuta `-p` pordivastendust (port mapping), sest PostgreSQL on ainult sisemiselt kättesaadav (võrgu isolatsioon!)

### Samm 4: Seadista andmebaasid

```bash
# Loo users tabel User Service'i andmebaasis
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

# Kontrolli User Service'i tabel
docker exec postgres-user psql -U postgres -d user_service_db -c "\dt"
# Peaks näitama: users tabel

# Loo todos tabel Todo Service'i andmebaasis
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

# Kontrolli Todo Service'i tabel
docker exec postgres-todo psql -U postgres -d todo_service_db -c "\dt"
# Peaks näitama: todos tabel
```

### Samm 5: Genereeri jagatud JWT saladus

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

### Samm 6: Käivita User Service

**ℹ️ Portide turvalisus:**

Kasutame lihtsustatud portide vastendust (`-p 3000:3000`).
- ✅ **Antud laboreid tehes turvatud sisevõrk kaitseb**
- ✅ **PostgreSQL EI kasuta `-p`:** Ainult `todo-network` võrgus (võrgu isolatsioon - PARIM PRAKTIKA!)
- 📚 **Tootmises oleks õige:** `-p 127.0.0.1:3000:3000` rakenduste jaoks
- 🎯 **Lab 7 käsitleb:** Võrguturvalisust põhjalikumalt

**Hetkel keskendume Docker võrkudele!**

---

```bash
# User Service'i konteiner samas võrgus
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

**✨ MAAGIA #1:** Kasutame konteineri nime `postgres-user` otse hostinimena (hostname)!
- ❌ Harjutus 2: Vajasime `--link postgres-user:postgres`
- ✅ Harjutus 3: Lihtsalt kasuta `DB_HOST=postgres-user` (automaatne DNS!)

### Samm 7: Käivita Todo Service

```bash
# Todo Service'i konteiner samas võrgus
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

**✨ MAAGIA #2:** Kasutame konteineri nime `postgres-todo` otse hostinimena!

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

### Samm 8: Testi DNS lahendust

**See on kõige huvitavam osa!** Vaatame, kuidas Docker automaatselt lahendab (resolves) konteinerite nimesid.

#### 8a. Testi DNS Todo Service'ist

```bash
# Sisene Todo Service'i konteinerisse
docker exec -it todo-service sh

# Kuna konteineri sisse vaja internetti, seadista konteineris sees proksi
export HTTP_PROXY=http://proxy-chain.intel.com:911
export HTTPS_PROXY=http://proxy-chain.intel.com:912

# Konteineri sees - testi DNS lahendust
# Installi võrgu tööriistad
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

**✨ MAAGIA #3:** Teenused näevad teineteist automaatselt!
- ✅ User Service ↔ Todo Service suhtlus töötab
- ✅ Iga teenus näeb oma PostgreSQL'i
- ✅ DNS lahendus on automaatne (konteineri nimi = hostinimi!)

**Mida õppisid?**
- Docker loob automaatse DNS serveri igale kohandatud võrgule (127.0.0.11)
- Konteineri nimi = automaatne DNS hostinimi
- Ei vaja --link ega IP aadresse!
- Teenused saavad omavahel suhelda HTTP kaudu

### Samm 9: Inspekteeri võrku

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
- KÕIK 4 konteinerit on samas võrgus ✅
- Igal konteineril on oma IP aadress ✅
- Need IP'd on samast alamvõrgust (subnet) (172.18.0.0/16) ✅
- Võrgu isolatsioon toimib (välismaailm ei näe PostgreSQL porte!) ✅

### Samm 10: Testi rakenduse tervisekontrolli (Health Check)

```bash
# User Service'i tervisekontroll
curl http://localhost:3000/health
# Oodatud: {"status":"OK","database":"connected"}

# Todo Service'i tervisekontroll
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
- Võrk on korrektne ✅
- Mõlemad PostgreSQL'id on kättesaadavad ✅
- DNS lahendus toimib ✅
- Mõlemad teenused on terved ✅

### Samm 11: Testi End-to-End JWT töövoogu

**See on KÕIGE OLULISEM TEST!** Testib täielikku mikroteenuste suhtlust kohandatud võrgus.

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

# 2. Login ja salvesta JWT "token"
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"network@example.com","password":"test123"}' \
  | jq -r '.token')

echo "JWT Token: $TOKEN"

# 3. Kasuta "token"-it Todo Service'is (MIKROTEENUSTE SUHTLUS!)
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Õpi Kohandatud Võrke (Custom Networks)",
    "description": "Docker võrgundus on nüüd selge!",
    "priority": "high",
    "dueDate": "2025-11-20T18:00:00"
  }' | jq

# Oodatud vastus:
# {
#   "id": 1,
#   "userId": 1,  <-- ekstraktitud JWT "token"-ist!
#   "title": "Õpi Kohandatud Võrke (Custom Networks)",
#   "description": "Docker võrgundus on nüüd selge!",
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
1. ✅ User Service genereeris JWT "token"-i
2. ✅ Todo Service valideeris "token"-it (SAMA JWT_SECRET!)
3. ✅ Todo Service ekstraktis userId "token"-ist (userId: 1)
4. ✅ CRUD operatsioonid töötasid mikroteenuste vahel
5. ✅ Kohandatud võrk võimaldas automaatset DNS lahendust
6. ✅ Mõlemad teenused suhtlesid oma andmebaasidega

**See on täielik mikroteenuste arhitektuur kohandatud võrgus!** 🚀

---

---

## 💡 Parimad Praktikad (Best Practices)

**Kohandatud võrgud:**
1. **Kasuta alati kohandatud võrke** - Mitte vaikimisi silda (default bridge)
2. **Anna võrgule mõistlik nimi** - `todo-network`, mitte `network1`
3. **Üks võrk projekti/stack'i kohta** - Isolatsioon!
4. **Kasuta konteinerite nimesid hostinimedena** - Automaatne DNS
5. **Ära avalda PostgreSQL porte välismaailma** - Turvalisus!

**Konteinerite nimetamine:**
1. **Kasuta kirjeldavaid nimesid** - `postgres-user`, mitte `db1`
2. **Järjepidev nimetamine** - `<service>-<purpose>` (postgres-user, postgres-todo)
3. **Konteineri nimi = DNS hostinimi** - Pane tähele!

**Turvalisus:**
1. **Võrgu isolatsioon** - Ainult vajalikud konteinerid samas võrgus
2. **Pordivastendus** - Ainult väliselt vajalikud pordid (3000, 8081)
3. **Sisemised teenused** - PostgreSQL ilma `-p` (ainult sisemiselt kättesaadav)

---

## 📚 Viited

- [Docker Networking Overview](https://docs.docker.com/network/)
- [User-defined bridge networks](https://docs.docker.com/network/bridge/)
- [Container networking](https://docs.docker.com/config/containers/container-networking/)
- [Docker DNS resolution](https://docs.docker.com/network/bridge/#configure-the-default-bridge-network)

---

**Õnnitleme! Oled loonud tootmiskõlbuliku (production-ready) võrgu seadistuse! 🎉**

**Järgmine:** [Harjutus 4: Docker andmeköited](04-volumes.md) - Õpi, kuidas säilitada andmed!
