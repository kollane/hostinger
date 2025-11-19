# Harjutus 2: Multi-Container Setup - Mikroteenuste Arhitektuur

**Kestus:** 90 minutit
**Eesmärk:** Käivita User Service + Todo Service + PostgreSQL ja mõista mikroteenuste suhtlust

**Eeldused:**
- ✅ [Harjutus 1A: Single Container (User Service)](01-single-container-user_service.md) läbitud
- ✅ [Harjutus 1B: Single Container (Todo Service)](01-single-container-todo_service.md) läbitud

---

## 📋 Ülevaade

**Mäletad Harjutus 1-st?**
- User Service crashis (PostgreSQL puudub)
- Todo Service crashis (PostgreSQL puudub)
- JWT token ei töötanud (teenused ei suhtle)

**Harjutus 2 lahendab:**
- ✅ Käivitame KAKS PostgreSQL containerit (üks User Service'ile, teine Todo Service'ile)
- ✅ User Service genereerib JWT tokeneid
- ✅ Todo Service valideerib JWT tokeneid
- ✅ Saame TÖÖTAVA mikroteenuste süsteemi!

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Käivitada mitut containerit koos
- ✅ Mõista mikroteenuste arhitektuuri
- ✅ Õppida JWT-põhist autentimist teenuste vahel
- ✅ Kasutada container networking'ut
- ✅ Debuggida multi-container süsteemi

---

## 🏗️ Arhitektuur

```
User (browser/cURL)
    │
    ├──> User Service (3000) ──> PostgreSQL (5432: user_service_db)
    │         │
    │         └─> Genereerib JWT tokeni
    │
    │    (JWT token)
    │         │
    │         ▼
    └──> Todo Service (8081) ──> PostgreSQL (5433: todo_service_db)
              │
              └─> Valideerib JWT tokenit
```

**Tähtis:** Mõlemad teenused kasutavad SAMA `JWT_SECRET` väärtust!

---

## 📝 Sammud

### Samm 1: Käivita PostgreSQL Containerid (15 min)

```bash
# PostgreSQL User Service'ile
docker run -d \
  --name postgres-user \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -p 5432:5432 \
  postgres:16-alpine

# PostgreSQL Todo Service'ile
docker run -d \
  --name postgres-todo \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  -p 5433:5432 \
  postgres:16-alpine

# Kontrolli
docker ps | grep postgres
```

**Kontrolli logisid:**

```bash
# User Service PostgreSQL
docker logs postgres-user
# Peaks nägema: "database system is ready to accept connections"

# Todo Service PostgreSQL
docker logs postgres-todo
# Peaks nägema: "database system is ready to accept connections"
```

**Miks kaks PostgreSQL containerit?**
- ✅ Iga mikroteenusele oma andmebaas (mikroteenuste best practice)
- ✅ Sõltumatu andmete haldamine
- ✅ Õpid multi-database setup'i

**Märkus:** Kasutame erinevaid porte host'is:
- `5432` → User Service PostgreSQL
- `5433` → Todo Service PostgreSQL

### Samm 2: Seadista User Service Andmebaas (10 min)

```bash
# Loo users tabel
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

# Kontrolli
docker exec postgres-user psql -U postgres -d user_service_db -c "\dt"
# Peaks näitama: users tabel

# Vaata tabeli struktuuri
docker exec postgres-user psql -U postgres -d user_service_db -c "\d users"
```

**Mida lõime?**
- `users` tabel kasutajate andmetega
- `id` - automaatselt kasvav primaarkey
- `email` - unikaalne (ei saa kahte sama emailiga kasutajat)
- `password` - bcrypt hashitud parool
- `role` - kasutaja roll (user/admin)

### Samm 3: Seadista Todo Service Andmebaas (10 min)

```bash
# Loo todos tabel
# TÄHTIS: Kasuta BIGSERIAL ja BIGINT, mitte SERIAL ja INTEGER!
# Spring Boot JPA Entity kasutab Long tüüpi, mis vajab BIGINT
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

# Kontrolli
docker exec postgres-todo psql -U postgres -d todo_service_db -c "\dt"
# Peaks näitama: todos tabel

# Vaata tabeli struktuuri
docker exec postgres-todo psql -U postgres -d todo_service_db -c "\d todos"
```

**Miks BIGSERIAL ja BIGINT?**
- ❌ `SERIAL` = INTEGER (32-bit) → Spring Boot ootab Long
- ✅ `BIGSERIAL` = BIGINT (64-bit) → Sobib Spring Boot Long'iga
- ❌ Kui kasutad SERIAL, saad error'i: "wrong column type encountered"

### Samm 4: Genereeri Jagatud JWT Secret (5 min)

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

**Miks sama JWT_SECRET?**

```
User Service (genereerib JWT)
    │
    ├─> Allkirjastab tokeni JWT_SECRET'iga
    │
    ▼
JWT Token (sisaldab userId, email, role)
    │
    ▼
Todo Service (valideerib JWT)
    │
    └─> Kontrollib allkirja sama JWT_SECRET'iga
```

**Kui JWT_SECRET on erinev:**
- ❌ User Service genereerib tokeni ühega võtmega
- ❌ Todo Service proovib valideerida teise võtmega
- ❌ Tulemus: "Invalid signature" error

### Samm 5: Käivita User Service (10 min)

```bash
# Puhasta varasemad containerid Harjutus 1-st
docker stop user-service 2>/dev/null || true
docker rm user-service 2>/dev/null || true

# Käivita User Service --link'iga
docker run -d \
  --name user-service \
  --link postgres-user:postgres \
  -p 3000:3000 \
  -e DB_HOST=postgres \
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

**Mida `--link postgres-user:postgres` teeb?**
- Loob DNS aliase: `postgres` → `postgres-user` container IP
- User Service saab ühenduda `postgres:5432` kaudu
- **Deprecated** (Harjutus 3 õpetab custom networks!)

**Kontrolli, et container töötab:**

```bash
docker ps | grep user-service
# STATUS peaks olema: Up X seconds
```

**Kui container crashib:**
```bash
# Vaata logisid
docker logs user-service

# Levinud probleemid:
# - DB_HOST vale → kontrolli --link
# - PostgreSQL ei tööta → vaata docker ps | grep postgres
# - JWT_SECRET puudub → kontrolli echo $JWT_SECRET
```

### Samm 6: Käivita Todo Service (10 min)

```bash
# Puhasta varasemad containerid Harjutus 1-st
docker stop todo-service 2>/dev/null || true
docker rm todo-service 2>/dev/null || true

# Käivita Todo Service --link'iga
docker run -d \
  --name todo-service \
  --link postgres-todo:postgres \
  -p 8081:8081 \
  -e DB_HOST=postgres \
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

**Kontrolli, et kõik 4 containerit töötavad:**

```bash
docker ps

# Peaks näitama:
# - postgres-user (5432)
# - postgres-todo (5433)
# - user-service (3000)
# - todo-service (8081)
```

**Kui mõni container puudub:**
```bash
# Vaata kõiki containereid (ka peatatud)
docker ps -a

# Vaata crashinud containeri logisid
docker logs <container-name>
```

### Samm 7: Testi Autentimist (User Service) (10 min)

```bash
# Health check
curl http://localhost:3000/health
# Oodatud: {"status":"OK","database":"connected"}

# Registreeri kasutaja
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "test123"
  }'

# Oodatud vastus:
# {
#   "token": "eyJhbGci...",
#   "user": {
#     "id": 1,
#     "email": "test@example.com",
#     "name": "Test User",
#     "role": "user"
#   }
# }
```

**Kui sain error'i:**

```bash
# Error: Email already exists
# Lahendus: Kasuta teist emaili või reseti andmebaas

# Error: Database connection failed
# Lahendus: Kontrolli, kas postgres-user töötab
docker ps | grep postgres-user
docker logs user-service
```

**Nüüd login ja salvesta JWT token:**

```bash
# Login ja salvesta JWT token muutujasse
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  | jq -r '.token')

echo "JWT Token: $TOKEN"
```

**Kui `jq` ei ole installitud:**
```bash
# Ubuntu/Debian
sudo apt install -y jq

# Või salvesta manuaalselt
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Kopeeri "token" väärtus ja salvesta:
TOKEN="eyJhbGci..."
```

**Dekodeeri token (vaata, mida sisaldab):**

```bash
# Dekodeeri JWT payload
echo $TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq

# Peaks näitama:
# {
#   "id": 1,
#   "email": "test@example.com",
#   "name": "Test User",
#   "role": "user",
#   "iat": 1234567890,
#   "exp": 1234654290
# }
```

**Mida õppisid?**
- ✅ User Service genereerib JWT tokenit
- ✅ Token sisaldab kasutaja andmeid (id, email, role)
- ✅ Token on allkirjastatud JWT_SECRET'iga
- ✅ Token aegub pärast 24h (JWT_EXPIRES_IN)

### Samm 8: Testi Todo Service JWT Tokeniga (15 min)

```bash
# Health check
curl http://localhost:8081/health
# Oodatud: {"status":"UP"}

# Loo todo (kasutades User Service'i JWT tokenit!)
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Õpi Docker Multi-Container",
    "description": "Läbi töötada Harjutus 2",
    "priority": "high",
    "dueDate": "2025-11-20T18:00:00"
  }'

# Oodatud vastus:
# {
#   "id": 1,
#   "userId": 1,
#   "title": "Õpi Docker Multi-Container",
#   "description": "Läbi töötada Harjutus 2",
#   "completed": false,
#   "priority": "high",
#   "dueDate": "2025-11-20T18:00:00",
#   "createdAt": "...",
#   "updatedAt": "..."
# }
```

**Märka:** `userId: 1` tuli JWT tokenist!

**Loe kõik todos:**

```bash
curl -X GET http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN" | jq

# Peaks näitama loodud todo'd
```

**Märgi todo tehtud:**

```bash
# Märgi todo 1 tehtud
curl -X PATCH http://localhost:8081/api/todos/1/complete \
  -H "Authorization: Bearer $TOKEN"

# Kontrolli
curl -X GET http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN" | jq
# "completed" peaks olema: true
```

**Testi veel mõned todos:**

```bash
# Loo teine todo
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Õpi Docker Networking",
    "description": "Harjutus 3: Custom Networks",
    "priority": "medium",
    "dueDate": "2025-11-21T18:00:00"
  }'

# Kontrolli andmebaasi otse
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;"
```

**Mida õppisid?**
- ✅ Todo Service aktsepteerib User Service'i JWT tokenit
- ✅ Todo Service ekstraktis userId tokenist (userId: 1)
- ✅ CRUD operatsioonid töötavad mikroteenuste vahel
- ✅ Mõlemad teenused usaldavad sama JWT_SECRET'i

### Samm 9: Mõista Mikroteenuste Suhtlust (10 min)

**Mis toimus?**

1. **User Service** võttis vastu registreerimise ja login'i päringu
2. **User Service** genereris JWT tokeni (sisaldab userId, email, role)
3. **Sina** saatsid JWT tokeni Todo Service'ile
4. **Todo Service** valideeris JWT tokenit (sama JWT_SECRET!)
5. **Todo Service** ekstraktis userId tokenist ja salvestas todo andmebaasi

**Tähtis mõiste:**
- User Service on **autentimise keskus (authentication hub)**
- Todo Service on **ressursi teenus (resource service)**
- JWT token on **autentimise tõend (authentication proof)**
- Mõlemad teenused usaldavad sama JWT_SECRET'i

**Diagramm:**

```
1. User registreerib/logib sisse
   │
   ▼
User Service (genereerib JWT token)
   │
   └─> Allkirjastab JWT_SECRET'iga
   │
   ▼
JWT Token
{
  "id": 1,
  "email": "test@example.com",
  "role": "user",
  "iat": 1234567890,
  "exp": 1234654290
}
   │
   ▼
2. User saadab tokeni Todo Service'ile
   │
   ▼
Todo Service
   │
   ├─> Valideerib tokenit (JWT_SECRET)
   ├─> Ekstraktib userId: 1
   └─> Salvestab todo (user_id=1)
```

**Mikroteenuste arhitektuuri eelised:**
- ✅ **Sõltumatus** - Iga teenus oma andmebaasiga
- ✅ **Skaleeritavus** - Saab skaleerida teenuseid eraldi
- ✅ **Turvalisus** - Tsentraliseeritud autentimine
- ✅ **Paindlikkus** - Erinevad tehnoloogiad (Node.js + Java)

**Kuidas see töötab tootmises?**

```
API Gateway (Nginx/Kong)
    │
    ├──> User Service (3 replicas)
    │       └──> PostgreSQL (master-slave)
    │
    └──> Todo Service (5 replicas)
            └──> PostgreSQL (master-slave)
```

### Samm 10: Troubleshooting (10 min)

**1. JWT token ei tööta Todo Service'is:**

```bash
# Error: 401 Unauthorized

# Kontrolli, et mõlemad teenused kasutavad SAMA JWT_SECRET
docker exec user-service env | grep JWT_SECRET
docker exec todo-service env | grep JWT_SECRET
# Peavad olema IDENTSED!

# Kui erinevad, restart teenused õige JWT_SECRET'iga
docker stop user-service todo-service
docker rm user-service todo-service

# Kontrolli, et JWT_SECRET on endiselt seatud
echo $JWT_SECRET

# Käivita uuesti (Samm 5 ja 6)
```

**2. Token on aegunud:**

```bash
# Error: Token expired

# Genereeri uus token
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  | jq -r '.token')

echo "Uus token: $TOKEN"
```

**3. Database connection error:**

```bash
# Kontrolli, kas PostgreSQL containerid töötavad
docker ps | grep postgres

# Peaks näitama mõlemat:
# postgres-user (5432)
# postgres-todo (5433)

# Kontrolli User Service logisid
docker logs user-service
# Otsib: "Database connected" või "Error connecting to database"

# Kontrolli Todo Service logisid
docker logs todo-service
# Otsid: "HikariPool started" või "Connection refused"
```

**4. `--link` ei tööta:**

```bash
# Kui kasutad uuemat Docker versiooni, kasuta container IP
POSTGRES_USER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgres-user)
POSTGRES_TODO_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgres-todo)

echo "User DB IP: $POSTGRES_USER_IP"
echo "Todo DB IP: $POSTGRES_TODO_IP"

# Restart teenused IP'dega
docker stop user-service
docker rm user-service

docker run -d --name user-service \
  -e DB_HOST=$POSTGRES_USER_IP \
  -p 3000:3000 \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=$JWT_SECRET \
  -e JWT_EXPIRES_IN=24h \
  -e NODE_ENV=production \
  -e PORT=3000 \
  user-service:1.0

# Sama Todo Service'ile
```

**5. Schema validation error (wrong column type):**

```bash
# Error: wrong column type encountered in column [id] in table [todos];
# found [serial (Types#INTEGER)], but expecting [bigint (Types#BIGINT)]

# Lahendus: Kasuta BIGSERIAL ja BIGINT, mitte SERIAL ja INTEGER
docker exec postgres-todo psql -U postgres -d todo_service_db -c "
DROP TABLE IF EXISTS todos;
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

# Restart todo-service
docker restart todo-service
docker logs -f todo-service
```

**6. Port on juba kasutusel:**

```bash
# Error: bind: address already in use

# Kontrolli, mis kasutab porti
sudo lsof -i :3000
sudo lsof -i :8081

# Peata konflikti põhjustav protsess või kasuta teist porti
docker run -p 3001:3000 ...  # Kasuta host porti 3001
```

---

## ✅ Kontrolli Tulemusi

- [x] Kaks PostgreSQL containerit töötavad (portid 5432 ja 5433)
- [x] User Service container töötab (port 3000)
- [x] Todo Service container töötab (port 8081)
- [x] Mõlemad teenused kasutavad SAMA JWT_SECRET'i
- [x] User Service `/health` tagastab `{"status":"OK","database":"connected"}`
- [x] Todo Service `/health` tagastab `{"status":"UP"}`
- [x] Registreerimine töötab
- [x] Login tagastab JWT tokeni
- [x] Todo Service aktsepteerib User Service'i tokenit
- [x] CRUD operatsioonid töötavad (loo, loe, uuenda todos)
- [x] Mõistad mikroteenuste arhitektuuri
- [x] Mõistad JWT-põhist autentimist

---

## 🎓 Õpitud Kontseptsioonid

### Mikroteenuste Arhitektuur:

- **Authentication Hub** - Keskne autentimise teenus (User Service)
- **Resource Services** - Ressursside haldamise teenused (Todo Service)
- **JWT-based Auth** - Token-põhine autentimine teenuste vahel
- **Shared Secret** - Jagatud salajane võti (JWT_SECRET)
- **Service-to-Service Trust** - Teenuste vaheline usaldus
- **Database per Service** - Iga teenus oma andmebaasiga (mikroteenuste best practice)

### Docker Multi-Container:

- **Container Linking** (`--link` - deprecated, aga lihtne õppimiseks!)
- **Port Mapping** - Mitu teenust erinevatel portidel
- **Environment Variables** - Konfiguratsioon containerites
- **Multi-Database Setup** - Iga teenus oma PostgreSQL'iga
- **Health Checks** - Kontrolli, et teenused töötavad
- **Container Dependency** - Teenused sõltuvad andmebaasidest

### JWT Autentimine:

- **Token Generation** - User Service genereerib JWT tokenit
- **Token Validation** - Todo Service valideerib JWT tokenit
- **Token Payload** - Sisaldab userId, email, role, exp
- **Token Signature** - Allkirjastatud JWT_SECRET'iga
- **Token Expiration** - Tokenid aeguvad (default 24h)
- **Bearer Authentication** - `Authorization: Bearer <token>`

### Levinud Probleemid ja Lahendused:

- **JWT_SECRET peab olema SAMA** mõlemas teenuses → Kontrolli env variables
- **BIGSERIAL vs SERIAL** - Spring Boot vajab BIGINT → Kasuta BIGSERIAL
- **Token expiration** - Tokenid aeguvad → Genereeri uus token login'iga
- **Container DNS** - `--link` loob DNS aliase → Kasuta `--link` või container IP
- **Schema validation errors** - Andmebaasi veergude tüübid peavad vastama JPA Entity tüüpidele

### Järgmine Samm:

Harjutus 3 õpetab **proper networking'ut** Docker Networks kasutades (mitte deprecated `--link`)!

---

## 📊 Võrdlus: Harjutus 1 vs Harjutus 2

| Aspekt | Harjutus 1 | Harjutus 2 |
|--------|-----------|-----------|
| **Containerid** | 1 (crashib) | 4 (töötavad) |
| **PostgreSQL** | ❌ Puudub | ✅ 2 DB containerit |
| **Networking** | ❌ Puudub | ✅ --link |
| **JWT Auth** | ❌ Ei tööta | ✅ Täielik flow |
| **Status** | ❌ Crashib | ✅ Töötab |
| **Õpitav** | Docker basics | Mikroteenused |
| **User Service** | ❌ Crashib | ✅ Genereerib JWT |
| **Todo Service** | ❌ Crashib | ✅ Valideerib JWT |
| **API testid** | ❌ Ei tööta | ✅ Töötavad |

---

## 🧪 Testimine

### Test 1: Kas kõik containerid töötavad?

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Oodatud väljund:
# NAMES              STATUS          PORTS
# todo-service       Up X minutes    0.0.0.0:8081->8081/tcp
# user-service       Up X minutes    0.0.0.0:3000->3000/tcp
# postgres-todo      Up X minutes    0.0.0.0:5433->5432/tcp
# postgres-user      Up X minutes    0.0.0.0:5432->5432/tcp
```

### Test 2: Kas health check'id töötavad?

```bash
# User Service
curl -s http://localhost:3000/health | jq
# Oodatud: {"status":"OK","database":"connected"}

# Todo Service
curl -s http://localhost:8081/health | jq
# Oodatud: {"status":"UP"}
```

### Test 3: Kas autentimine töötab?

```bash
# Registreerimine
curl -s -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test2","email":"test2@example.com","password":"test123"}' | jq

# Login
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test2@example.com","password":"test123"}' \
  | jq -r '.token')

echo "Token length: ${#TOKEN}"
# Oodatud: Token length: 150+ (JWT on pikk string)
```

### Test 4: Kas JWT token töötab Todo Service'is?

```bash
# Loo todo
curl -s -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Test todo","priority":"high"}' | jq

# Loe todos
curl -s -X GET http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN" | jq

# Oodatud: Peaksid nägema loodud todo'd
```

### Test 5: Kas andmebaasid sisaldavad andmeid?

```bash
# User Service andmebaas
docker exec postgres-user psql -U postgres -d user_service_db -c "SELECT id, email, role FROM users;"

# Todo Service andmebaas
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT id, user_id, title, completed FROM todos;"
```

**Kui kõik 5 testi läbisid, siis oled edukalt läbinud Harjutuse 2!** 🎉

---

## 💡 Parimad Tavad

### Mikroteenuste Arhitektuur:

1. **Database per Service** - Iga teenus oma andmebaasiga
2. **Centralized Authentication** - Üks teenus genereerib JWT tokeneid
3. **Shared Secret Management** - Kõik teenused usaldavad sama JWT_SECRET'i
4. **Token Expiration** - Tokenid aeguvad (turvalise jaoks)
5. **Health Checks** - Iga teenus pakub /health endpoint'i

### Docker Multi-Container:

1. **Use --link Sparingly** - `--link` on deprecated, kasuta Harjutus 3-s custom networks
2. **Environment Variables** - Konfiguratsioon läbi env vars, mitte hardcoded
3. **Port Mapping** - Kasuta erinevaid host porte konflikti vältimiseks
4. **Container Names** - Anna containeritele selged nimed (user-service, postgres-user)
5. **Logging** - Kasuta `docker logs` debuggimiseks

### JWT Autentimine:

1. **Secure Secrets** - Genereeri JWT_SECRET `openssl rand -base64 32`
2. **Token Expiration** - Määra mõistlik expiration aeg (24h dev, 1h prod)
3. **Validate Tokens** - Kontrolli alati tokeni signatuuri
4. **Include User Info** - Token peaks sisaldama userId, email, role
5. **Bearer Authentication** - Kasuta standardset `Authorization: Bearer <token>` header'it

---

## 🔗 Järgmine Samm

Järgmises harjutuses õpid **proper networking'ut** Docker Networks kasutades!

**Miks custom networks on paremad kui --link?**
- ✅ Pole deprecated
- ✅ Parem DNS resolution
- ✅ Network isolation
- ✅ Container discovery
- ✅ Multiple networks

**Jätka:** [Harjutus 3: Docker Networking](03-networking.md) - õpi custom networks!

---

## 📚 Viited

- [Docker Networking](https://docs.docker.com/network/)
- [Microservices Architecture](https://microservices.io/)
- [JWT Authentication](https://jwt.io/introduction)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
- [Spring Boot with Docker](https://spring.io/guides/topicals/spring-boot-docker/)
- [Node.js with Docker](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)

---

**Õnnitleme! Oled ehitanud oma esimese mikroteenuste süsteemi! 🎉**

**Mida saavutasid:**
- ✅ 4 containerit töötavad koos
- ✅ 2 mikroteenust suhtlevad JWT kaudu
- ✅ 2 andmebaasi haldavad eraldi andmeid
- ✅ Täielik autentimise ja autoriseerimise flow
- ✅ Mõistad mikroteenuste arhitektuuri põhimõtteid

**Järgmises harjutuses:**
- Õpid custom Docker networks
- Loobud deprecated --link'ist
- Ehitad parema networking lahenduse
