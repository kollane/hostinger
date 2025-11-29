# Harjutus 2: Mitme konteineri seadistus (Multi-Container Setup)

**Eeldused:**
- ✅ [Harjutus 1A: Üksiku konteineri loomine (User Teenus)](01a-single-container-nodejs.md) läbitud
- ✅ [Harjutus 1B: Üksiku konteineri loomine (Todo Teenus)](01b-single-container-java.md) läbitud

---

## 📋 Harjutuse ülevaade

**Mäletad Harjutus 1-st?**
- User teenus hangus (puudus PostgreSQL)
- Todo teenus hangus (puudus PostgreSQL)
- JWT "token" ei töötanud (teenused ei suhelnud)

**Harjutus 2 lahendab:**
- ✅ Käivitame KAKS PostgreSQL konteinerit (üks User teenusele, teine Todo teenusele)
- ✅ User teenus genereerib JWT "token"-eid
- ✅ Todo teenus valideerib JWT "token"-eid
- ✅ Saame TÖÖTAVA mikroteenuste süsteemi!

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Käivitada mitut **konteinerit (containers)** koos
- ✅ Mõista **mikroteenuste (microservices)** arhitektuuri
- ✅ Õppida JWT-põhist autentimist **teenuste (services)** vahel
- ✅ Kasutada konteinerite **võrgundust (networking)**
- ✅ Teostada **veatuvastust (debug)** mitme konteineri süsteemis

---

## 🖥️ Sinu Testimise Konfiguratsioon

### SSH Ühendus VPS-iga
```bash
ssh labuser@93.127.213.242 -p [SINU-PORT]
```

| Õpilane | SSH Port | Password |
|---------|----------|----------|
| student1 | 2201 | student1 |
| student2 | 2202 | student2 |
| student3 | 2203 | student3 |

---

## 🏗️ Arhitektuur

```
User (browser/cURL)
    │
    ├──> User teenus (3000) ──> PostgreSQL (5432: user_service_db)
    │         │
    │         └─> Genereerib JWT "token"-i
    │
    │    (JWT "token")
    │         │
    │         ▼
    └──> Todo teenus (8081) ──> PostgreSQL (5433: todo_service_db)
              │
              └─> Valideerib JWT "token"-it
```

**Tähtis:** Mõlemad teenused kasutavad SAMA `JWT_SECRET` väärtust!

---

## 📝 Sammud

### Samm 1: Käivita PostgreSQL konteinerid

```bash
# PostgreSQL User teenusele
docker run -d \
  --name postgres-user \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -p 5432:5432 \
  postgres:16-alpine

# PostgreSQL Todo teenusele
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
# User teenuse PostgreSQL
docker logs postgres-user
# Peaks nägema: "database system is ready to accept connections"

# Todo teenuse PostgreSQL
docker logs postgres-todo
# Peaks nägema: "database system is ready to accept connections"
```

**Miks kaks PostgreSQL konteinerit?**
- ✅ Igal mikroteenusel oma andmebaas (mikroteenuste parim praktika)
- ✅ Sõltumatu andmete haldamine
- ✅ Õpid mitme andmebaasi seadistust (multi-database setup)

**Märkus:** Kasutame erinevaid porte hostis:
- `5432` → User teenuse PostgreSQL
- `5433` → Todo teenuse PostgreSQL

### Samm 2: Seadista User teenuse andmebaas

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

### Samm 3: Seadista Todo teenuse andmebaas

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

### Samm 4: Genereeri jagatud JWT saladus (Shared Secret)

**📖 Täielik JWT ja JWT_SECRET selgitus:** [User Service README](../../apps/backend-nodejs/README.md) selgitab:
- Mis on JWT "token" (digitaalne visiitkaart)
- Miks kõik teenused peavad kasutama SAMA JWT_SECRET võtit
- Kuidas JWT töötab mikroteenuste arhitektuuris

---

**OLULINE:** Mõlemad teenused peavad kasutama SAMA `JWT_SECRET`'i!

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
User teenus (genereerib JWT)
    │
    ├─> Allkirjastab "token"-i JWT_SECRET'iga
    │
    ▼
JWT "token" (sisaldab userId, email, role)
    │
    ▼
Todo teenus (valideerib JWT)
    │
    └─> Kontrollib allkirja sama JWT_SECRET'iga
```

**Kui JWT_SECRET on erinev:**
- ❌ User teenus genereerib "token"-i ühega võtmega
- ❌ Todo teenus proovib valideerida teise võtmega
- ❌ Tulemus: "Invalid signature" viga (error)

### Samm 5: Käivita User teenus

```bash
# Puhasta varasemad konteinerid Harjutus 1-st
docker stop user-service 2>/dev/null || true
docker rm user-service 2>/dev/null || true

# Käivita User teenus --link'iga
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
- User teenus saab ühenduda `postgres:5432` kaudu
- **Aegunud (deprecated)** (Harjutus 3 õpetab kohandatud võrke!)

**Kontrolli, et konteiner töötab:**

```bash
docker ps | grep user-service
# STATUS peaks olema: Up X seconds
```

**Kui konteiner krahhib:**
```bash
# Vaata logisid
docker logs user-service

# Levinud probleemid:
# - DB_HOST vale → kontrolli --link
# - PostgreSQL ei tööta → vaata docker ps | grep postgres
# - JWT_SECRET puudub → kontrolli echo $JWT_SECRET
```

### Samm 6: Käivita Todo teenus

```bash
# Puhasta varasemad konteinerid Harjutus 1-st
docker stop todo-service 2>/dev/null || true
docker rm todo-service 2>/dev/null || true

# Käivita Todo teenus --link'iga
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

# Vaata hangunud konteineri logisid
docker logs <container-name>
```

### Samm 7: Testi autentimist (User teenus)

```bash
# Tervisekontroll (health check)
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

**Nüüd login ja salvesta JWT "token":**

```bash
# Login ja salvesta JWT "token" muutujasse
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
- ✅ User teenus (service) genereerib JWT "token"-it
- ✅ "Token" sisaldab kasutaja andmeid (id, email, role)
- ✅ "Token" on allkirjastatud JWT_SECRET'iga
- ✅ "Token" aegub pärast 24h (JWT_EXPIRES_IN)

### Samm 8: Testi Todo teenust JWT "token"-iga

```bash
# Tervisekontroll (health check)
curl http://localhost:8081/health
# Oodatud: {"status":"UP"}

# Loo todo (kasutades User teenuse JWT "token"-it!)
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

**Märka:** `userId: 1` tuli JWT "token"-ist!

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

### Samm 9: Mõista mikroteenuste suhtlust

**Mis toimus?**

1. **User teenus** võttis vastu registreerimise ja login'i päringu
2. **User teenus** genereris JWT "token"-i (sisaldab userId, email, role)
3. **Sina** saatsid JWT "token"-i Todo teenusele
4. **Todo teenus** valideeris JWT "token"-it (sama JWT_SECRET!)
5. **Todo teenus** ekstraktis `userId` "token"-ist ja salvestas todo andmebaasi

**Tähtis mõiste:**
- User teenus on **autentimise keskus (authentication hub)**
- Todo teenus on **ressursi teenus (resource service)**
- JWT "token" on **autentimise tõend (authentication proof)**
- Mõlemad teenused usaldavad sama JWT_SECRET'i

**Diagramm:**

```
1. User registreerib/logib sisse
   │
   ▼
User teenus (genereerib JWT "token")
   │
   └─> Allkirjastab JWT_SECRET'iga
   │
   ▼
JWT "token"
{
  "id": 1,
  "email": "test@example.com",
  "role": "user",
  "iat": 1234567890,
  "exp": 1234654290
}
   │
   ▼
2. User saadab "token"-i Todo teenusele
   │
   ▼
Todo teenus
   │
   ├─> Valideerib "token"-it (JWT_SECRET)
   ├─> Ekstraktib userId: 1
   └─> Salvestab todo (user_id=1)
```

**Mikroteenuste arhitektuuri eelised:**
- ✅ **Sõltumatus** - Igal teenusel oma andmebaas
- ✅ **Skaleeritavus** - Saab skaleerida teenuseid eraldi
- ✅ **Turvalisus** - Tsentraliseeritud autentimine
- ✅ **Paindlikkus** - Erinevad tehnoloogiad (Node.js + Java)

**Kuidas see töötab toote keskkonnas?**

```
API Gateway (Nginx/Kong)
    │
    ├──> User teenus (3 replicas)
    │       └──> PostgreSQL (master-slave)
    │
    └──> Todo teenus (5 replicas)
            └──> PostgreSQL (master-slave)
```

### Samm 10: Tõrkeotsing (Troubleshooting)

**1. JWT "token" ei tööta Todo teenuses:**

```bash
# Viga (error): 401 Unauthorized

# Kontrolli, et mõlemad teenused kasutavad SAMA JWT_SECRET
docker exec user-service env | grep JWT_SECRET
docker exec todo-service env | grep JWT_SECRET
# Peavad olema IDENTSED!

# Kui erinevad, taaskäivita teenused õige JWT_SECRET'iga
docker stop user-service todo-service
docker rm user-service todo-service

# Kontrolli, et JWT_SECRET on endiselt seatud
echo $JWT_SECRET

# Käivita uuesti (Samm 5 ja 6)
```

**2. "Token" on aegunud:**

```bash
# Viga (error): Token expired

# Genereeri uus "token"
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

# Kontrolli User teenuse logisid
docker logs user-service
# Otsib: "Database connected" või "Error connecting to database"

# Kontrolli Todo teenuse logisid
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

# Taaskäivita teenused IP'dega
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

# Sama Todo teenusele
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

# Taaskäivita todo-service
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

## 🎓 Õpitud kontseptsioonid

### Mikroteenuste arhitektuur:

- **Autentimise keskus (Authentication Hub)** - Keskne autentimise teenus (User teenus)
- **Ressursi teenused (Resource Services)** - Ressursside haldamise teenused (Todo teenus)
- **JWT-põhine autentimine (JWT-based Auth)** - Token-põhine autentimine teenuste vahel
- **Jagatud saladus (Shared Secret)** - Jagatud salajane võti (JWT_SECRET)
- **Teenuste-vaheline usaldus (Service-to-Service Trust)** - Teenuste vaheline usaldus
- **Andmebaas teenuse kohta (Database per Service)** - Iga teenus oma andmebaasiga (mikroteenuste parim praktika)

### Docker mitme konteineriga:

- **Konteinerite linkimine (Container Linking)** (`--link` - aegunud, aga lihtne õppimiseks!)
- **Portide vastendamine (Port Mapping)** - Mitu teenust erinevatel portidel
- **Keskkonnamuutujad** - Konfiguratsioon konteinerites
- **Mitme andmebaasi seadistus (Multi-Database Setup)** - Iga teenus oma PostgreSQL'iga
- **Tervisekontrollid (Health Checks)** - Kontrolli, et teenused töötavad
- **Konteinerite sõltuvus** - Teenused sõltuvad andmebaasidest

### JWT Autentimine:

- **"Token"-i genereerimine** - User teenus genereerib JWT "token"-it
- **"Token"-i valideerimine** - Todo teenus valideerib JWT "token"-it
- **"Token"-i sisu** - Sisaldab userId, email, role, exp
- **"Token"-i allkiri** - Allkirjastatud JWT_SECRET'iga
- **"Token"-i aegumine** - "Token"-id aeguvad (vaikimisi 24h)
- **Bearer autentimine** - `Authorization: Bearer <token>`

### Levinud probleemid ja lahendused:

- **JWT_SECRET peab olema SAMA** mõlemas teenuses → Kontrolli keskkonnamuutujaid
- **BIGSERIAL vs SERIAL** - Spring Boot vajab BIGINT → Kasuta BIGSERIAL
- **"Token"-i aegumine** - "Token"-id aeguvad → Genereeri uus "token" login'iga
- **Konteineri DNS** - `--link` loob DNS aliase → Kasuta `--link` või konteineri IP-d
- **Skeemi valideerimise vead** - Andmebaasi veergude tüübid peavad vastama JPA Entity tüüpidele

### Järgmine samm:

Harjutus 3 õpetab **korralikku võrgundust** Docker võrkude (networks) kasutades (mitte aegunud `--link`)!

---

## 📊 Võrdlus: Harjutus 1 vs Harjutus 2

| Aspekt | Harjutus 1 | Harjutus 2 |
|--------|-----------|-----------|
| **Konteinerid** | 1 (hangub) | 4 (töötavad) |
| **PostgreSQL** | ❌ Puudub | ✅ 2 DB konteinerit |
| **Võrgundus** | ❌ Puudub | ✅ --link |
| **JWT autentimine** | ❌ Ei tööta | ✅ Täielik voog |
| **Staatus** | ❌ Hangub | ✅ Töötab |
| **Õpitav** | Dockeri põhitõed | Mikroteenused |
| **User teenus** | ❌ Hangub | ✅ Genereerib JWT |
| **Todo teenus** | ❌ Hangub | ✅ Valideerib JWT |
| **API testid** | ❌ Ei tööta | ✅ Töötavad |

---

## 💡 Parimad Praktikad (Best Practices)

### Mikroteenuste arhitektuur:

1. **Andmebaas teenuse kohta** - Iga teenus oma andmebaasiga
2. **Tsentraliseeritud autentimine** - Üks teenus genereerib JWT "token"-eid
3. **Jagatud saladuse haldus** - Kõik teenused usaldavad sama JWT_SECRET'i
4. **"Token"-i aegumine** - "Token"-id aeguvad (turvalisuse jaoks)
5. **Tervisekontrollid** - Iga teenus pakub /health lõpp-punkti

### Docker mitme konteineriga:

1. **Kasuta --link'i säästlikult** - `--link` on aegunud, kasuta Harjutus 3-s kohandatud võrke
2. **Keskkonnamuutujad** - Konfiguratsioon läbi keskkonnamuutujate, mitte kõvakodeeritud
3. **Pordivastendus** - Kasuta erinevaid host porte konflikti vältimiseks
4. **Konteinerite nimed** - Anna konteineritele selged nimed (user-service, postgres-user)
5. **Logimine** - Kasuta `docker logs` veatuvastuseks

### JWT Autentimine:

1. **Turvalised saladused** - Genereeri JWT_SECRET `openssl rand -base64 32`
2. **"Token"-i aegumine** - Määra mõistlik aegumisaeg (24h arenduskeskkonnas, 1h toote keskkonnas)
3. **Valideeri "token"-eid** - Kontrolli alati "token"-i signatuuri
4. **Kaasa kasutaja info** - "Token" peaks sisaldama userId, email, role
5. **Bearer autentimine** - Kasuta standardset `Authorization: Bearer <token>` päist

---

## 🔗 Järgmine Samm

Järgmises harjutuses õpid **korralikku võrgundust** Docker võrkude kasutades!

**Miks kohandatud võrgud (custom networks) on paremad kui --link?**
- ✅ Pole aegunud (deprecated)
- ✅ Parem DNS-i lahendus
- ✅ Võrgu isolatsioon
- ✅ Konteinerite avastamine
- ✅ Mitu võrku

**Jätka:** [Harjutus 3: Docker võrgundus (Networking)](03-networking.md) - õpi kohandatud võrke!

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
- ✅ 4 konteinerit töötavad koos
- ✅ 2 mikroteenust suhtlevad JWT kaudu
- ✅ 2 andmebaasi haldavad eraldi andmeid
- ✅ Täielik autentimise ja autoriseerimise voog
- ✅ Mõistad mikroteenuste arhitektuuri põhimõtteid

**Järgmises harjutuses:**
- Õpid kohandatud Docker võrke
- Loobud aegunud --link'ist
- Ehitad parema võrgunduse lahenduse
