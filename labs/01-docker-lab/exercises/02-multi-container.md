# Harjutus 2: Mitme-konteineri seadistus (Multi-Container Setup) - Mikroteenuste Arhitektuur

**Kestus:** 90 minutit
**Eesmärk:** Käivita User teenus (service) + Todo teenus (service) + PostgreSQL ja mõista mikroteenuste suhtlust

**Eeldused:**
- ✅ [Harjutus 1A: Üksik Konteiner (Single Container) (User Teenus (Service))](01a-single-container-nodejs.md) läbitud
- ✅ [Harjutus 1B: Üksik Konteiner (Single Container) (Todo Teenus (Service))](01b-single-container-java.md) läbitud
- 💡 **Alternatiiv:** Kui vahele jätsid, käivita `./setup.sh` ja vali `Y` - see ehitab (builds) vajalikud pildid (images) automaatselt

---

## 📋 Ülevaade

**Mäletad Harjutus 1-st?**
- User teenus (service) hangus (crashed) (PostgreSQL puudub)
- Todo teenus (service) hangus (crashed) (PostgreSQL puudub)
- JWT token ei töötanud (teenused (services) ei suhtle)

**Harjutus 2 lahendab:**
- ✅ Käivitame KAKS PostgreSQL konteinerit (üks User teenusele (service), teine Todo teenusele (service))
- ✅ User teenus (service) genereerib JWT tokeneid
- ✅ Todo teenus (service) valideerib JWT tokeneid
- ✅ Saame TÖÖTAVA mikroteenuste (microservices) süsteemi!

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Käivitada mitut konteinerit koos
- ✅ Mõista mikroteenuste (microservices) arhitektuuri
- ✅ Õppida JWT-põhist autentimist teenuste (services) vahel
- ✅ Kasutada konteinerite võrgundust (container networking)
- ✅ Debugida mitme-konteineri (multi-container) süsteemi

---

## 🏗️ Arhitektuur

```
User (browser/cURL)
    │
    ├──> User teenus (service) (3000) ──> PostgreSQL (5432: user_service_db)
    │         │
    │         └─> Genereerib JWT tokeni
    │
    │    (JWT token)
    │         │
    │         ▼
    └──> Todo teenus (service) (8081) ──> PostgreSQL (5433: todo_service_db)
              │
              └─> Valideerib JWT tokenit
```

**Tähtis:** Mõlemad teenused (services) kasutavad SAMA `JWT_SECRET` väärtust!

---

## 📝 Sammud

### Samm 1: Käivita PostgreSQL Konteinerid (15 min)

```bash
# PostgreSQL User teenusele (service)
docker run -d \
  --name postgres-user \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -p 5432:5432 \
  postgres:16-alpine

# PostgreSQL Todo teenusele (service)
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
# User Teenuse (Service) PostgreSQL
docker logs postgres-user
# Peaks nägema: "database system is ready to accept connections"

# Todo Teenuse (Service) PostgreSQL
docker logs postgres-todo
# Peaks nägema: "database system is ready to accept connections"
```

**Miks kaks PostgreSQL konteinerit?**
- ✅ Igal mikroteenusel (microservice) oma andmebaas (mikroteenuste (microservices) parim praktika (best practice))
- ✅ Sõltumatu andmete haldamine
- ✅ Õpid mitme andmebaasi seadistust (multi-database setup)

**Märkus:** Kasutame erinevaid porte host'is:
- `5432` → User teenuse (service) PostgreSQL
- `5433` → Todo teenuse (service) PostgreSQL

### Samm 2: Seadista User teenuse (service) Andmebaas (10 min)

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
- `id` - automaatselt kasvav primaarvõti (primary key)
- `email` - unikaalne (ei saa kahte sama emailiga kasutajat)
- `password` - `bcrypt` hashitud parool
- `role` - kasutaja roll (user/admin)

### Samm 3: Seadista Todo teenuse (service) Andmebaas (10 min)

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
- ❌ `SERIAL` = INTEGER (32-bit) → Spring Boot ootab `Long`
- ✅ `BIGSERIAL` = BIGINT (64-bit) → Sobib Spring Boot `Long`'iga
- ❌ Kui kasutad `SERIAL`, saad vea (error): "wrong column type encountered"

**📖 Java/Spring Boot JPA ja PostgreSQL:** Põhjalikum selgitus Spring Boot JPA Entity tüüpide ja PostgreSQL andmetüüpide vastavuse kohta (Long vs BIGINT, Integer vs INT) leiad [Peatükk 06A: Java Spring Boot ja Node.js Konteineriseerimise Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md).

### Samm 4: Genereeri Jagatud JWT Saladus (Shared Secret) (5 min)

**OLULINE:** Mõlemad teenused (services) peavad kasutama SAMA `JWT_SECRET`'i!

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
User teenus (service) (genereerib JWT)
    │
    ├─> Allkirjastab tokeni JWT_SECRET'iga
    │
    ▼
JWT Token (sisaldab userId, email, role)
    │
    ▼
Todo teenus (service) (valideerib JWT)
    │
    └─> Kontrollib allkirja sama JWT_SECRET'iga
```

**Kui JWT_SECRET on erinev:**
- ❌ User teenus (service) genereerib tokeni ühega võtmega
- ❌ Todo teenus (service) proovib valideerida teise võtmega
- ❌ Tulemus: "Invalid signature" viga (error)

### Samm 5: Käivita User teenus (service) (10 min)

```bash
# Puhasta varasemad konteinerid Harjutus 1-st
docker stop user-service 2>/dev/null || true
docker rm user-service 2>/dev/null || true

# Käivita User teenus (service) --link'iga
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
- Loob DNS aliase: `postgres` → `postgres-user` konteineri IP
- User teenus (service) saab ühenduda `postgres:5432` kaudu
- **Aegunud (deprecated)** (Harjutus 3 õpetab kohandatud võrke (custom networks)!)

**Kontrolli, et konteiner töötab:**

```bash
docker ps | grep user-service
# STATUS peaks olema: Up X seconds
```

**Kui konteiner hangub (crashes):**
```bash
# Vaata logisid
docker logs user-service

# Levinud probleemid:
# - DB_HOST vale → kontrolli --link
# - PostgreSQL ei tööta → vaata docker ps | grep postgres
# - JWT_SECRET puudub → kontrolli echo $JWT_SECRET
```

### Samm 6: Käivita Todo teenus (service) (10 min)

```bash
# Puhasta varasemad konteinerid Harjutus 1-st
docker stop todo-service 2>/dev/null || true
docker rm todo-service 2>/dev/null || true

# Käivita Todo teenus (service) --link'iga
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

**Kontrolli, et kõik 4 konteinerit töötavad:**

```bash
docker ps

# Peaks näitama:
# - postgres-user (5432)
# - postgres-todo (5433)
# - user-service (3000)
# - todo-service (8081)
```

**Kui mõni konteiner puudub:**
```bash
# Vaata kõiki konteinereid (ka peatatud)
docker ps -a

# Vaata hangunud (crashed) konteineri logisid
docker logs <container-name>
```

### Samm 7: Testi Autentimist (User teenus (service)) (10 min)

```bash
# Seisukorra kontroll (health check)
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

**Kui sain vea (error):**

```bash
# Viga (error): Email already exists
# Lahendus: Kasuta teist emaili või reseti andmebaas

# Viga (error): Database connection failed
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
- ✅ User teenus (service) genereerib JWT tokenit
- ✅ Token sisaldab kasutaja andmeid (id, email, role)
- ✅ Token on allkirjastatud JWT_SECRET'iga
- ✅ Token aegub pärast 24h (JWT_EXPIRES_IN)

### Samm 8: Testi Todo teenust (service) JWT Tokeniga (15 min)

```bash
# Seisukorra kontroll (health check)
curl http://localhost:8081/health
# Oodatud: {"status":"UP"}

# Loo todo (kasutades User teenuse (service) JWT tokenit!)
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
    "title": "Õpi Docker Võrgundust (Networking)",
    "description": "Harjutus 3: Custom Networks",
    "priority": "medium",
    "dueDate": "2025-11-21T18:00:00"
  }'

# Kontrolli andmebaasi otse
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT * FROM todos;"
```

**Mida õppisid?**
- ✅ Todo teenus (service) aktsepteerib User teenuse (service) JWT tokenit
- ✅ Todo teenus (service) ekstraktis `userId` tokenist (userId: 1)
- ✅ CRUD operatsioonid töötavad mikroteenuste (microservices) vahel
- ✅ Mõlemad teenused (services) usaldavad sama JWT_SECRET'i

### Samm 9: Mõista Mikroteenuste (Microservices) Suhtlust (10 min)

**Mis toimus?**

1. **User teenus (service)** võttis vastu registreerimise ja login'i päringu
2. **User teenus (service)** genereris JWT tokeni (sisaldab userId, email, role)
3. **Sina** saatsid JWT tokeni Todo teenusele (service)
4. **Todo teenus (service)** valideeris JWT tokenit (sama JWT_SECRET!)
5. **Todo teenus (service)** ekstraktis `userId` tokenist ja salvestas todo andmebaasi

**Tähtis mõiste:**
- User teenus (service) on **autentimise keskus (authentication hub)**
- Todo teenus (service) on **ressursi teenus (resource service)**
- JWT token on **autentimise tõend (authentication proof)**
- Mõlemad teenused (services) usaldavad sama JWT_SECRET'i

**Diagramm:**

```
1. User registreerib/logib sisse
   │
   ▼
User teenus (service) (genereerib JWT token)
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
2. User saadab tokeni Todo teenusele (service)
   │
   ▼
Todo teenus (service)
   │
   ├─> Valideerib tokenit (JWT_SECRET)
   ├─> Ekstraktib userId: 1
   └─> Salvestab todo (user_id=1)
```

**Mikroteenuste (microservices) arhitektuuri eelised:**
- ✅ **Sõltumatus** - Igal teenusel (service) oma andmebaas
- ✅ **Skaleeritavus** - Saab skaleerida teenuseid (services) eraldi
- ✅ **Turvalisus** - Tsentraliseeritud autentimine
- ✅ **Paindlikkus** - Erinevad tehnoloogiad (Node.js + Java)

**Kuidas see töötab tootmises?**

```
API Gateway (Nginx/Kong)
    │
    ├──> User teenus (service) (3 replicas)
    │       └──> PostgreSQL (master-slave)
    │
    └──> Todo teenus (service) (5 replicas)
            └──> PostgreSQL (master-slave)
```

### Samm 10: Tõrkeotsing (Troubleshooting) (10 min)

**1. JWT token ei tööta Todo teenuses (service):**

```bash
# Viga (error): 401 Unauthorized

# Kontrolli, et mõlemad teenused (services) kasutavad SAMA JWT_SECRET
docker exec user-service env | grep JWT_SECRET
docker exec todo-service env | grep JWT_SECRET
# Peavad olema IDENTSED!

# Kui erinevad, taaskäivita (restart) teenused (services) õige JWT_SECRET'iga
docker stop user-service todo-service
docker rm user-service todo-service

# Kontrolli, et JWT_SECRET on endiselt seatud
echo $JWT_SECRET

# Käivita uuesti (Samm 5 ja 6)
```

**2. Token on aegunud:**

```bash
# Viga (error): Token expired

# Genereeri uus token
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  | jq -r '.token')

echo "Uus token: $TOKEN"
```

**3. Andmebaasi ühenduse viga (Database connection error):**

```bash
# Kontrolli, kas PostgreSQL konteinerid töötavad
docker ps | grep postgres

# Peaks näitama mõlemat:
# postgres-user (5432)
# postgres-todo (5433)

# Kontrolli User teenuse (service) logisid
docker logs user-service
# Otsib: "Database connected" või "Error connecting to database"

# Kontrolli Todo teenuse (service) logisid
docker logs todo-service
# Otsid: "HikariPool started" või "Connection refused"
```

**4. `--link` ei tööta:**

```bash
# Kui kasutad uuemat Docker versiooni, kasuta konteineri IP-d
POSTGRES_USER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgres-user)
POSTGRES_TODO_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgres-todo)

echo "User DB IP: $POSTGRES_USER_IP"
echo "Todo DB IP: $POSTGRES_TODO_IP"

# Taaskäivita (restart) teenused (services) IP'dega
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

# Sama Todo teenusele (service)
```

**5. Skeemi valideerimise viga (Schema validation error) (wrong column type):**

```bash
# Viga (error): wrong column type encountered in column [id] in table [todos];
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

# Taaskäivita (restart) todo-service
docker restart todo-service
docker logs -f todo-service
```

**6. Port on juba kasutusel:**

```bash
# Viga (error): bind: address already in use

# Kontrolli, mis kasutab porti
sudo lsof -i :3000
sudo lsof -i :8081

# Peata konflikti põhjustav protsess või kasuta teist porti
docker run -p 3001:3000 ...  # Kasuta host porti 3001
```

---

## ✅ Kontrolli Tulemusi

- [x] Kaks PostgreSQL konteinerit töötavad (portid 5432 ja 5433)
- [x] User teenuse (service) konteiner töötab (port 3000)
- [x] Todo teenuse (service) konteiner töötab (port 8081)
- [x] Mõlemad teenused (services) kasutavad SAMA JWT_SECRET'i
- [x] User teenuse (service) `/health` tagastab `{"status":"OK","database":"connected"}`
- [x] Todo teenuse (service) `/health` tagastab `{"status":"UP"}`
- [x] Registreerimine töötab
- [x] Login tagastab JWT tokeni
- [x] Todo teenus (service) aktsepteerib User teenuse (service) tokenit
- [x] CRUD operatsioonid töötavad (loo, loe, uuenda todos)
- [x] Mõistad mikroteenuste (microservices) arhitektuuri
- [x] Mõistad JWT-põhist autentimist

---

## 🎓 Õpitud Kontseptsioonid

### Mikroteenuste (Microservices) Arhitektuur:

- **Autentimise keskus (Authentication Hub)** - Keskne autentimise teenus (service) (User Teenus (Service))
- **Ressursi teenused (Resource Services)** - Ressursside haldamise teenused (services) (Todo Teenus (Service))
- **JWT-põhine autentimine (JWT-based Auth)** - Token-põhine autentimine teenuste (services) vahel
- **Jagatud saladus (Shared Secret)** - Jagatud salajane võti (JWT_SECRET)
- **Teenuste-vaheline usaldus (Service-to-Service Trust)** - Teenuste (services) vaheline usaldus
- **Andmebaas teenuse kohta (Database per Service)** - Iga teenus (service) oma andmebaasiga (mikroteenuste (microservices) parim praktika (best practice))

### Docker Mitme-Konteineri (Multi-Container):

- **Konteinerite linkimine (Container Linking)** (`--link` - aegunud (deprecated), aga lihtne õppimiseks!)
- **Portide vastendamine (Port Mapping)** - Mitu teenust (service) erinevatel portidel
- **Keskkonna muutujad (Environment Variables)** - Konfiguratsioon konteinerites
- **Mitme andmebaasi seadistus (Multi-Database Setup)** - Iga teenus (service) oma PostgreSQL'iga
- **Seisukorra kontrollid (Health Checks)** - Kontrolli, et teenused (services) töötavad
- **Konteinerite sõltuvus (Container Dependency)** - Teenused (services) sõltuvad andmebaasidest

### JWT Autentimine:

- **Tokeni genereerimine (Token Generation)** - User teenus (service) genereerib JWT tokenit
- **Tokeni valideerimine (Token Validation)** - Todo teenus (service) valideerib JWT tokenit
- **Tokeni sisu (Token Payload)** - Sisaldab userId, email, role, exp
- **Tokeni allkiri (Token Signature)** - Allkirjastatud JWT_SECRET'iga
- **Tokeni aegumine (Token Expiration)** - Tokenid aeguvad (vaikimisi 24h)
- **Bearer autentimine (Bearer Authentication)** - `Authorization: Bearer <token>`

### Levinud Probleemid ja Lahendused:

- **JWT_SECRET peab olema SAMA** mõlemas teenuses (services) → Kontrolli keskkonna muutujaid (environment variables)
- **BIGSERIAL vs SERIAL** - Spring Boot vajab BIGINT → Kasuta BIGSERIAL
- **Tokeni aegumine (Token expiration)** - Tokenid aeguvad → Genereeri uus token login'iga
- **Konteineri DNS** - `--link` loob DNS aliase → Kasuta `--link` või konteineri IP-d
- **Skeemi valideerimise vead (Schema validation errors)** - Andmebaasi veergude tüübid peavad vastama JPA Entity tüüpidele

### Järgmine Samm:

Harjutus 3 õpetab **korralikku võrgundust (proper networking)** Docker Võrkude (Networks) kasutades (mitte aegunud (deprecated) `--link`)!

---

## 📊 Võrdlus: Harjutus 1 vs Harjutus 2

| Aspekt | Harjutus 1 | Harjutus 2 |
|--------|-----------|-----------|
| **Konteinerid** | 1 (hangub (crashes)) | 4 (töötavad) |
| **PostgreSQL** | ❌ Puudub | ✅ 2 DB konteinerit |
| **Võrgundus (Networking)** | ❌ Puudub | ✅ --link |
| **JWT autentimine (Auth)** | ❌ Ei tööta | ✅ Täielik voog (flow) |
| **Staatus (Status)** | ❌ Hangub (crashes) | ✅ Töötab |
| **Õpitav** | Dockeri põhitõed (basics) | Mikroteenused (Microservices) |
| **User teenus (service)** | ❌ Hangub (crashes) | ✅ Genereerib JWT |
| **Todo teenus (service)** | ❌ Hangub (crashes) | ✅ Valideerib JWT |
| **API testid** | ❌ Ei tööta | ✅ Töötavad |

---

## 🧪 Testimine

### Test 1: Kas kõik konteinerid töötavad?

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Oodatud väljund:
# NAMES              STATUS          PORTS
# todo-service       Up X minutes    0.0.0.0:8081->8081/tcp
# user-service       Up X minutes    0.0.0.0:3000->3000/tcp
# postgres-todo      Up X minutes    0.0.0.0:5433->5432/tcp
# postgres-user      Up X minutes    0.0.0.0:5432->5432/tcp
```

### Test 2: Kas seisukorra kontrollid (health checks) töötavad?

```bash
# User teenus (service)
curl -s http://localhost:3000/health | jq
# Oodatud: {"status":"OK","database":"connected"}

# Todo teenus (service)
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

echo "Tokeni pikkus (length): ${#TOKEN}"
# Oodatud: Token length: 150+ (JWT on pikk string)
```

### Test 4: Kas JWT token töötab Todo teenuses (service)?

```bash
# Loo todo
curl -s -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Test todo","priority":"high"}' | jq

# Loe todosid
curl -s -X GET http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN" | jq

# Oodatud: Peaksid nägema loodud todo'd
```

### Test 5: Kas andmebaasid sisaldavad andmeid?

```bash
# User teenuse (service) andmebaas
docker exec postgres-user psql -U postgres -d user_service_db -c "SELECT id, email, role FROM users;"

# Todo teenuse (service) andmebaas
docker exec postgres-todo psql -U postgres -d todo_service_db -c "SELECT id, user_id, title, completed FROM todos;"
```

**Kui kõik 5 testi läbisid, siis oled edukalt läbinud Harjutuse 2!** 🎉

---

## 💡 Parimad Praktikad (Best Practices)

### Mikroteenuste (Microservices) Arhitektuur:

1. **Andmebaas teenuse kohta (Database per Service)** - Iga teenus (service) oma andmebaasiga
2. **Tsentraliseeritud autentimine (Centralized Authentication)** - Üks teenus (service) genereerib JWT tokeneid
3. **Jagatud saladuse haldus (Shared Secret Management)** - Kõik teenused (services) usaldavad sama JWT_SECRET'i
4. **Tokeni aegumine (Token Expiration)** - Tokenid aeguvad (turvalisuse jaoks)
5. **Seisukorra kontrollid (Health Checks)** - Iga teenus (service) pakub /health lõpp-punkti (endpoint)

### Docker Mitme-Konteineri (Multi-Container):

1. **Kasuta --link'i säästlikult (Use --link Sparingly)** - `--link` on aegunud (deprecated), kasuta Harjutus 3-s kohandatud võrke (custom networks)
2. **Keskkonna muutujad (Environment Variables)** - Konfiguratsioon läbi keskkonna muutujate (env vars), mitte kõvakodeeritud (hardcoded)
3. **Portide vastendamine (Port Mapping)** - Kasuta erinevaid host porte konflikti vältimiseks
4. **Konteinerite nimed (Container Names)** - Anna konteineritele selged nimed (user-service, postgres-user)
5. **Logimine (Logging)** - Kasuta `docker logs` debugimiseks

### JWT Autentimine:

1. **Turvalised saladused (Secure Secrets)** - Genereeri JWT_SECRET `openssl rand -base64 32`
2. **Tokeni aegumine (Token Expiration)** - Määra mõistlik aegumisaeg (expiration time) (24h arenduskeskkonnas (dev), 1h tootmiskeskkonnas (prod))
3. **Valideeri tokeneid (Validate Tokens)** - Kontrolli alati tokeni signatuuri
4. **Kaasa kasutaja info (Include User Info)** - Token peaks sisaldama userId, email, role
5. **Bearer autentimine (Bearer Authentication)** - Kasuta standardset `Authorization: Bearer <token>` päist (header)

---

## 🔗 Järgmine Samm

Järgmises harjutuses õpid **korralikku võrgundust (proper networking)** Docker Võrkude (Networks) kasutades!

**Miks kohandatud võrgud (custom networks) on paremad kui --link?**
- ✅ Pole aegunud (deprecated)
- ✅ Parem DNS-i lahendus (resolution)
- ✅ Võrgu isolatsioon (Network isolation)
- ✅ Konteinerite avastamine (Container discovery)
- ✅ Mitu võrku (Multiple networks)

**Jätka:** [Harjutus 3: Docker võrgundus (Networking)](03-networking.md) - õpi kohandatud võrke (custom networks)!

---

## 📚 Viited

- [Docker Networking](https://docs.docker.com/network/)
- [Microservices Architecture](https://microservices.io/)
- [JWT Authentication](https://jwt.io/introduction)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
- [Spring Boot with Docker](https://spring.io/guides/topicals/spring-boot-docker/)
- [Node.js with Docker](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)

---

**Õnnitleme! Oled ehitanud oma esimese mikroteenuste (microservices) süsteemi! 🎉**

**Mida saavutasid:**
- ✅ 4 konteinerit töötavad koos
- ✅ 2 mikroteenust (microservices) suhtlevad JWT kaudu
- ✅ 2 andmebaasi haldavad eraldi andmeid
- ✅ Täielik autentimise ja autoriseerimise voog (flow)
- ✅ Mõistad mikroteenuste (microservices) arhitektuuri põhimõtteid

**Järgmises harjutuses:**
- Õpid kohandatud (custom) Docker võrke (networks)
- Loobud aegunud (deprecated) --link'ist
- Ehitad parema võrgunduse (networking) lahenduse
