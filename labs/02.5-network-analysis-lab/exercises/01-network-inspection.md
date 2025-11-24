# Harjutus 1: Võrgu Inspekteerimine ja Analüüs (Network Inspection & Analysis)

**Kestus:** 60 minutit
**Eesmärk:** Docker võrkude põhjalik inspekteerimine ja analüüs professionaalsete tööriistadega

---

## 📋 Ülevaade

Selles harjutuses õpid:
- Docker võrkude detailset inspekteerimist
- JSON väljundi analüüsimist `jq` tööriistaga
- Container-to-network mapping'ut
- IP aadresside ja subnet'ide analüüsi
- Multi-network configuration'i mõistmist

---

## ⚠️ Enne Alustamist

### Kontrolli Lab 2 Stack'i

```bash
# 1. Mine Lab 2 compose-project kausta
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project

# 2. Kontrolli, et kõik teenused töötavad
docker compose ps

# Oodatud väljund: Kõik 5 teenust (services) peaksid olema UP ja healthy:
# NAME            IMAGE                         STATUS
# frontend        nginx:alpine                  Up (healthy)
# user-service    user-service:1.0-optimized    Up (healthy)
# todo-service    todo-service:1.0-optimized    Up (healthy)
# postgres-user   postgres:16-alpine            Up (healthy)
# postgres-todo   postgres:16-alpine            Up (healthy)

# 3. Kontrolli võrkude olemasolu
docker network ls | grep -E "frontend-network|backend-network|database-network"

# Oodatud väljund: 3 võrku peaksid eksisteerima
```

**Kui midagi ei tööta:** Tagasi [Lab 2 Harjutus 3](../../02-docker-compose-lab/exercises/03-network-segmentation.md)

---

## 📝 Sammud

### Samm 1: Docker Võrkude Ülevaade (10 min)

#### 1.1. Vaata kõiki võrke süsteemis

```bash
# Näita kõiki võrke
docker network ls

# Oodatud väljund (näide):
# NETWORK ID     NAME                            DRIVER    SCOPE
# abc123def456   bridge                          bridge    local
# def456ghi789   host                            host      local
# ghi789jkl012   none                            null      local
# jkl012mno345   frontend-network                bridge    local
# mno345pqr678   backend-network                 bridge    local
# pqr678stu901   database-network                bridge    local
```

**Selgitus:**
- `bridge` - Default Docker võrk
- `host` - Host networking (otsene ligipääs host võrgule)
- `none` - No networking
- `frontend-network`, `backend-network`, `database-network` - Meie loodud võrgud Lab 2's

#### 1.2. Filtreeri ainult meie võrgud

```bash
# Näita ainult meie võrke
docker network ls --filter name=network

# VÕI konkreetsemalt
docker network ls | grep -E "frontend|backend|database"
```

#### 1.3. Võrkude arv ja driver'id

```bash
# Loe kokku, mitu bridge võrku on
docker network ls --filter driver=bridge | wc -l

# Oodatud: vähemalt 4 (bridge + 3 meie võrku)
```

---

### Samm 2: Põhjalik Võrgu Inspekteerimine (15 min)

#### 2.1. Frontend Network Analüüs

```bash
# Inspekteeri frontend-network võrku
docker network inspect frontend-network

# Väljund on pikk JSON. Vaatame olulisi osasid:
```

**JSON struktuuri mõistmine:**

```json
[
    {
        "Name": "frontend-network",
        "Id": "abc123...",
        "Created": "2025-11-24T...",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.20.0.0/16",
                    "Gateway": "172.20.0.1"
                }
            ]
        },
        "Internal": false,
        "Containers": {
            "container_id_1": {
                "Name": "frontend",
                "EndpointID": "...",
                "MacAddress": "02:42:ac:14:00:02",
                "IPv4Address": "172.20.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

**Olulised v�����ljad:**
- `Name` - Võrgu nimi
- `Driver` - Võrgu driver (tavaliselt "bridge")
- `IPAM` - IP Address Management (subnet, gateway)
- `Internal` - Kas võrk on isoleeritud (välisühendus keelatud)
- `Containers` - Konteinerid, mis on ühendatud sellesse võrku

#### 2.2. Kasuta `jq` JSON Parsingut

```bash
# Installi jq, kui puudub
which jq || sudo apt-get install -y jq

# Näita ainult võrgu nime ja driver'it
docker network inspect frontend-network | jq '.[0].Name, .[0].Driver'

# Oodatud väljund:
# "frontend-network"
# "bridge"

# Näita IPAM konfiguratsiooni
docker network inspect frontend-network | jq '.[0].IPAM'

# Oodatud väljund:
# {
#   "Driver": "default",
#   "Options": null,
#   "Config": [
#     {
#       "Subnet": "172.20.0.0/16",
#       "Gateway": "172.20.0.1"
#     }
#   ]
# }

# Näita ainult subnet'i
docker network inspect frontend-network | jq '.[0].IPAM.Config[0].Subnet'

# Oodatud: "172.20.0.0/16" (või sarnane)

# Näita gateway
docker network inspect frontend-network | jq '.[0].IPAM.Config[0].Gateway'

# Oodatud: "172.20.0.1" (või sarnane)
```

#### 2.3. Analüüsi Konteinereid Võrgus

```bash
# Millised konteinerid on frontend-network'is?
docker network inspect frontend-network | jq '.[0].Containers'

# Näita ainult konteinerite nimesid
docker network inspect frontend-network | jq '.[0].Containers | to_entries[] | .value.Name'

# Oodatud väljund:
# "frontend"

# Näita konteinerite IP aadresse
docker network inspect frontend-network | jq '.[0].Containers | to_entries[] | "\(.value.Name): \(.value.IPv4Address)"'

# Oodatud väljund (näide):
# "frontend: 172.20.0.2/16"
```

---

### Samm 3: Backend Network Analüüs (10 min)

#### 3.1. Backend Network Ülevaade

```bash
# Inspekteeri backend-network
docker network inspect backend-network | jq '.[0] | {Name, Driver, Internal, Subnet: .IPAM.Config[0].Subnet}'

# Oodatud väljund (näide):
# {
#   "Name": "backend-network",
#   "Driver": "bridge",
#   "Internal": false,
#   "Subnet": "172.21.0.0/16"
# }
```

#### 3.2. Millised Konteinerid on Backend Network'is?

```bash
# Näita kõiki konteinereid backend-network'is
docker network inspect backend-network | jq '.[0].Containers | to_entries[] | "\(.value.Name): \(.value.IPv4Address)"'

# Oodatud väljund (3 konteinerit):
# "frontend: 172.21.0.2/16"
# "user-service: 172.21.0.3/16"
# "todo-service: 172.21.0.4/16"

# ✅ KONTROLLI: Frontend, user-service ja todo-service peaksid olema siin!
```

**Miks frontend on backend-network'is?**
- Frontend teeb reverse proxy backend teenustele
- Peab saama ühendust user-service:3000 ja todo-service:8081'ga
- See on taotluslik multi-network konfiguratsioon!

---

### Samm 4: Database Network Analüüs (10 min)

#### 4.1. Database Network Inspekteerimine

```bash
# Inspekteeri database-network
docker network inspect database-network | jq '.[0] | {Name, Driver, Internal, Subnet: .IPAM.Config[0].Subnet}'

# Oodatud väljund (näide):
# {
#   "Name": "database-network",
#   "Driver": "bridge",
#   "Internal": true,    # ← OLULINE! See peab olema TRUE
#   "Subnet": "172.22.0.0/16"
# }
```

**KRIITILINE: Kontrolli `Internal` flag'i!**

```bash
# Kontrolli, kas database-network on internal: true
docker network inspect database-network | jq '.[0].Internal'

# Oodatud väljund: true

# Kui on false:
# ❌ PROBLEEM: Database võrk ei ole isoleeritud!
# Lahendus: Tagasi Lab 2 Harjutus 3, paranda docker-compose.yml
```

#### 4.2. Millised Konteinerid on Database Network'is?

```bash
# Näita kõiki konteinereid database-network'is
docker network inspect database-network | jq '.[0].Containers | to_entries[] | "\(.value.Name): \(.value.IPv4Address)"'

# Oodatud väljund (4 konteinerit):
# "user-service: 172.22.0.2/16"
# "todo-service: 172.22.0.3/16"
# "postgres-user: 172.22.0.4/16"
# "postgres-todo: 172.22.0.5/16"

# ✅ KONTROLLI: Backend teenused JA andmebaasid peaksid olema siin!
```

**Miks backend teenused on database-network'is?**
- user-service vajab ligipääsu postgres-user'ile
- todo-service vajab ligipääsu postgres-todo'le
- Database network on isolated (internal: true), seega turvalisem

---

### Samm 5: Container Network Settings Analüüs (10 min)

#### 5.1. Frontend Multi-Network Configuration

```bash
# Inspekteeri frontend konteinerit
docker inspect frontend | jq '.[0].NetworkSettings.Networks'

# Oodatud väljund (2 võrku):
# {
#   "frontend-network": {
#     "IPAMConfig": null,
#     "Links": null,
#     "Aliases": ["frontend", "abc123def456"],
#     "NetworkID": "jkl012mno345",
#     "EndpointID": "...",
#     "Gateway": "172.20.0.1",
#     "IPAddress": "172.20.0.2",
#     "IPPrefixLen": 16,
#     "IPv6Gateway": "",
#     "GlobalIPv6Address": "",
#     "GlobalIPv6PrefixLen": 0,
#     "MacAddress": "02:42:ac:14:00:02"
#   },
#   "backend-network": {
#     "IPAddress": "172.21.0.2",
#     ...
#   }
# }
```

**Näita ainult IP aadresse:**

```bash
# Frontend IP aadressid igas võrgus
docker inspect frontend | jq '.[0].NetworkSettings.Networks | to_entries[] | "\(.key): \(.value.IPAddress)"'

# Oodatud väljund:
# "frontend-network: 172.20.0.2"
# "backend-network: 172.21.0.2"

# ✅ KONTROLLI: Frontend on kahes võrgus!
```

#### 5.2. User-Service Multi-Network Configuration

```bash
# User-service IP aadressid
docker inspect user-service | jq '.[0].NetworkSettings.Networks | to_entries[] | "\(.key): \(.value.IPAddress)"'

# Oodatud väljund:
# "backend-network: 172.21.0.3"
# "database-network: 172.22.0.2"

# ✅ KONTROLLI: user-service on backend JA database võrkudes!
```

#### 5.3. Postgres-User Single Network Configuration

```bash
# Postgres-user IP aadress
docker inspect postgres-user | jq '.[0].NetworkSettings.Networks | to_entries[] | "\(.key): \(.value.IPAddress)"'

# Oodatud väljund:
# "database-network: 172.22.0.4"

# ✅ KONTROLLI: postgres-user on AINULT database võrgus!
```

---

### Samm 6: Võrgu Topologia Visualiseerimine (5 min)

#### 6.1. Loo Network Mapping Script

```bash
# Loo skript, mis näitab kõiki võrke ja konteinereid
cat > /tmp/network-map.sh << 'EOF'
#!/bin/bash
echo "==================================="
echo "Docker Network Topology Mapping"
echo "==================================="
echo ""

for network in frontend-network backend-network database-network; do
    echo "📡 Network: $network"
    echo "   Driver: $(docker network inspect $network | jq -r '.[0].Driver')"
    echo "   Internal: $(docker network inspect $network | jq -r '.[0].Internal')"
    echo "   Subnet: $(docker network inspect $network | jq -r '.[0].IPAM.Config[0].Subnet')"
    echo "   Gateway: $(docker network inspect $network | jq -r '.[0].IPAM.Config[0].Gateway')"
    echo ""
    echo "   Containers:"
    docker network inspect $network | jq -r '.[0].Containers | to_entries[] | "     - \(.value.Name) (\(.value.IPv4Address))"'
    echo ""
    echo "-----------------------------------"
    echo ""
done
EOF

chmod +x /tmp/network-map.sh
/tmp/network-map.sh
```

**Oodatud Väljund (näide):**

```
===================================
Docker Network Topology Mapping
===================================

📡 Network: frontend-network
   Driver: bridge
   Internal: false
   Subnet: 172.20.0.0/16
   Gateway: 172.20.0.1

   Containers:
     - frontend (172.20.0.2/16)

-----------------------------------

📡 Network: backend-network
   Driver: bridge
   Internal: false
   Subnet: 172.21.0.0/16
   Gateway: 172.21.0.1

   Containers:
     - frontend (172.21.0.2/16)
     - user-service (172.21.0.3/16)
     - todo-service (172.21.0.4/16)

-----------------------------------

📡 Network: database-network
   Driver: bridge
   Internal: true
   Subnet: 172.22.0.0/16
   Gateway: 172.22.0.1

   Containers:
     - user-service (172.22.0.2/16)
     - todo-service (172.22.0.3/16)
     - postgres-user (172.22.0.4/16)
     - postgres-todo (172.22.0.5/16)

-----------------------------------
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid oskama:

- [ ] **Inspekteerida Docker võrke** - `docker network inspect`
- [ ] **Kasutada jq JSON parsing'ut** - `jq '.[0].IPAM'`, `jq '.[0].Containers'`
- [ ] **Analüüsida IPAM konfiguratsiooni** - Subnet, Gateway
- [ ] **Tuvastada konteinereid võrkudes** - Millised konteinerid millistes võrkudes
- [ ] **Mõista multi-network konfiguratsiooni** - Miks frontend/user-service on mitmes võrgus
- [ ] **Kontrollida internal flag'i** - `Internal: true` database-network'is
- [ ] **Visualiseerida võrgu topologiat** - Loo mapping script

---

## 🎓 Õpitud Mõisted

### Docker Network Concepts:

- **Network Driver** - "bridge", "host", "overlay", "macvlan", etc.
- **IPAM (IP Address Management)** - Subnet, Gateway konfiguratsioon
- **Subnet** - IP address range võrgule (nt. 172.20.0.0/16)
- **Gateway** - Default gateway võrgus (nt. 172.20.0.1)
- **Internal Network** - Võrk ilma välisühenduseta (`internal: true`)
- **Multi-Network Container** - Konteiner, mis on ühendatud mitmesse võrku

### JSON Parsing jq'ga:

- `.[0]` - Esimene element array'st
- `.Name` - Atribuudi lugemine
- `.IPAM.Config[0].Subnet` - Nested atribuudi lugemine
- `to_entries[]` - Objekti konverteerimine array'ks
- `"\(.value.Name)"` - String interpolation

---

## 🐛 Levinud Probleemid

### Probleem 1: "jq: command not found"

```bash
# Lahendus: Installi jq
sudo apt-get update && sudo apt-get install -y jq
```

### Probleem 2: "database-network Internal: false"

```bash
# PROBLEEM: Database võrk ei ole isoleeritud!

# Lahendus: Paranda docker-compose.yml
# Lisa database-network definitsioonile:
networks:
  database-network:
    driver: bridge
    internal: true    # ← Lisa see!

# Taaskäivita stack
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project
docker compose down
docker network rm database-network
docker compose up -d
```

### Probleem 3: "Frontend ei ole backend-network'is"

```bash
# PROBLEEM: Frontend ei saa ühendust backend teenustega

# Lahendus: Lisa frontend teenusele backend-network
# docker-compose.yml's:
services:
  frontend:
    networks:
      - frontend-network
      - backend-network    # ← Lisa see!

# Taaskäivita
docker compose down && docker compose up -d
```

---

## 🔗 Järgmine Samm

Suurepärane! Nüüd mõistad Docker võrkude struktuuri põhjalikult.

**Järgmine harjutus:** [02-connectivity-testing.md](02-connectivity-testing.md) - Testid, kas võrgud töötavad õigesti!

---

**Viimane uuendus:** 2025-11-24
