# Harjutus 3: Docker Networking

**Kestus:** 45 minutit
**Eesmärk:** Loo custom network ja ühenda containerid proper networking'uga

**Eeldus:** [Harjutus 2: Multi-Container](02-multi-container.md) läbitud ✅

---

## 📋 Ülevaade

**Mäletad Harjutus 2-st?** Kasutasime `--link` et ühendada containereid. See toimis, aga Docker soovitab kasutada **custom networks** selle asemel!

**Miks custom networks on paremad kui --link?**
- ✅ Automaatne DNS resolution (container nimi = hostname)
- ✅ Network isolation (erinevad projektid erinevates networks)
- ✅ Turvalisem (--link on deprecated)
- ✅ Skaaleerib paremini (lihtne lisada/eemaldada containereid)
- ✅ Tänapäevane best practice

**Selles harjutuses:**
- Loome custom network `todo-network`
- Käivitame SAMAD containerid (PostgreSQL + Todo Service)
- Aga kasutame proper networking'ut (mitte --link!)

---

## 🎯 Õpieesmärgid

- ✅ Luua custom Docker network
- ✅ Käivitada containerid samas network'is
- ✅ Kasutada DNS hostname resolution
- ✅ Inspekteerida network konfiguratsiooni
- ✅ Isoleerida teenused network'idega
- ✅ Mõista, miks see on parem kui --link

---

## 📝 Sammud

### Samm 1: Puhasta Keskkond (5 min)

```bash
# Stopp ja eemalda vanad containerid Harjutus 2-st
docker stop todo-service postgres-todo 2>/dev/null || true
docker rm todo-service postgres-todo 2>/dev/null || true

# Kontrolli, et kõik on puhastatud
docker ps -a | grep -E 'todo-service|postgres-todo'
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

### Samm 3: Käivita Containerid Samas Network'is (15 min)

#### 3a. Käivita PostgreSQL

```bash
# PostgreSQL containeris custom network'is
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  postgres:16-alpine

# Kontrolli
docker ps | grep postgres-todo
# STATUS peaks olema "Up"
```

**Märka:** EI kasuta `-p 5433:5432`, sest PostgreSQL on ainult sisemiselt kättesaadav (network isolation!)

#### 3b. Seadista andmebaas

```bash
# Loo todos tabel
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "
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
);"

# Kontrolli
docker exec -it postgres-todo psql -U postgres -d todo_service_db -c "\dt"
```

#### 3c. Käivita Todo Service

```bash
# Genereeri turvaline JWT_SECRET (kui pole veel teinud)
openssl rand -base64 32
# Kopeeri väljund ja kasuta all

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
  -e JWT_SECRET=<sinu-genereeritud-secret-siia> \
  todo-service:1.0

# Vaata logisid
docker logs -f todo-service
# Peaks nägema: "Started TodoApplication"
```

**✨ MAAGIA:** Nüüd saad kasutada container nime `postgres-todo` otse hostname'ina!
- ❌ Harjutus 2: Vajasime `--link postgres-todo:postgres`
- ✅ Harjutus 3: Lihtsalt kasuta `DB_HOST=postgres-todo` (automaatne DNS!)

### Samm 4: Testi DNS Resolution (10 min)

**See on kõige huvitavam osa!** Vaatame, kuidas Docker automaatselt resolvib container nimesid.

```bash
# Sisene Todo Service containerisse
docker exec -it todo-service sh

# Container sees - testi DNS resolution
# (alpine image ei sisalda ping/nslookup vaikimisi, aga võid installida)

# Variant 1: Installi ping
apk add --no-cache iputils
ping -c 3 postgres-todo
# Peaks töötama! Näitab PostgreSQL container IP'd

# Variant 2: Kasuta nslookup
apk add --no-cache bind-tools
nslookup postgres-todo
# Peaks näitama: Name: postgres-todo, Address: 172.18.0.2 (või muu IP)

# Variant 3: Lihtsalt vaata /etc/hosts
cat /etc/hosts
# Peaks sisaldama todo-service IP'd

# Vaata DNS konfiguratsiooni
cat /etc/resolv.conf
# nameserver peaks olema Docker'i DNS server (127.0.0.11)

exit
```

**Mida õppisid?**
- Docker loob automaatse DNS serveri igale custom networkile
- Container nimi = automaatne DNS hostname
- Ei vaja --link ega IP aadresse!

### Samm 5: Inspekteeri Network (5 min)

```bash
# Vaata todo-network detaile
docker network inspect todo-network

# Peaks näitama:
# - "Containers": {
#     "abc123...": {
#       "Name": "postgres-todo",
#       "IPv4Address": "172.18.0.2/16"
#     },
#     "def456...": {
#       "Name": "todo-service",
#       "IPv4Address": "172.18.0.3/16"
#     }
#   }

# Näita ainult container nimesid ja IP'd
docker network inspect todo-network | grep -E '"Name"|"IPv4Address"'
```

**Vaata:**
- Mõlemad containerid on samas network'is ✅
- Igal containeril on oma IP aadress ✅
- Need IP'd on samast subnet'ist (172.18.0.0/16) ✅

### Samm 6: Testi Rakendust (5 min)

```bash
# Health check
curl http://localhost:8081/health
# Oodatud vastus:
# {
#   "status": "UP",
#   "components": {
#     "db": { "status": "UP" },
#     "diskSpace": { "status": "UP" }
#   }
# }
```

**Kui status on "UP" - ÕNNITLEME!** 🎉
- Network on korrektne ✅
- PostgreSQL on kättesaadav ✅
- DNS resolution toimib ✅
- Todo Service on terve ✅

---

## ✅ Kontrolli

- [x] `todo-network` on loodud (`docker network ls`)
- [x] Mõlemad containerid töötavad samas network'is (`docker network inspect todo-network`)
- [x] DNS resolution töötab (`ping postgres-todo` container sees)
- [x] Todo Service ühendub PostgreSQL'iga (vaata logisid)
- [x] API vastab korrektselt (`/health` status: UP)
- [x] **Ei kasuta --link** (kasutab custom network!) ✅

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

## 💡 Võrdlus: --link vs Custom Network

| Aspekt | --link (Harjutus 2) | Custom Network (Harjutus 3) |
|--------|---------------------|----------------------------|
| **Status** | ❌ Deprecated | ✅ Recommended |
| **DNS** | Vajab aliast | ✅ Automaatne |
| **Isolation** | ❌ Ei | ✅ Jah |
| **Skaleeritavus** | ❌ Keeruline | ✅ Lihtne |
| **Best practice** | ❌ Ei | ✅ Jah |

**Järeldus:** Kasuta alati custom networks, mitte --link!

---

**Järgmine:** [Harjutus 4: Volumes](04-volumes.md) - Õpi, kuidas säilitada andmed!
