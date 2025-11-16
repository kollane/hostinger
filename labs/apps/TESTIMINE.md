# Todo App Testimisjuhend

**Eesmärk:** Testida, et User Service + Todo Service + Frontend töötavad korrektselt

---

## 🚀 Kiirstart - 2 Minutit

### 1. Kontrolli teenuste staatust

```bash
cd /home/janek/projects/hostinger/labs/apps
docker compose ps
```

**Oodatav:** 5 teenust (STATUS: Up, healthy)

### 2. Tervisekontroll

```bash
curl http://localhost:3000/health  # User Service
curl http://localhost:8081/health  # Todo Service
```

**Oodatav:** `{"status":"UP"}` mõlemalt

### 3. Kiire API test

```bash
# Registreeri
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"test123"}'

# Logi sisse
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

**Oodatav:** JSON vastus koos JWT tokeniga

---

## 📋 Täielik Testimine (Samm-sammult)

### Samm 1: Registreeri kasutaja

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Kasutaja",
    "email": "test@example.com",
    "password": "test123"
  }'
```

**Oodatav vastus:**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 5,
    "name": "Test Kasutaja",
    "email": "test@example.com",
    "role": "user"
  }
}
```

**Kui viga "Email already exists":**
- See on OK - kasutaja on juba loodud
- Liigu edasi Samm 2 juurde

---

### Samm 2: Logi sisse ja salvesta JWT token

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123"
  }' | tee /tmp/login-response.json
```

**Oodatav vastus:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NSwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwibmFtZSI6IlRlc3QgS2FzdXRhamEiLCJyb2xlIjoidXNlciIsImlhdCI6MTczMTc1MjQwMCwiZXhwIjoxNzMxNzU2MDAwfQ.SIGNATURE",
  "user": {
    "id": 5,
    "name": "Test Kasutaja",
    "email": "test@example.com",
    "role": "user"
  }
}
```

**Ekstrakti token muutujasse:**
```bash
TOKEN=$(cat /tmp/login-response.json | grep -o '"token":"[^"]*' | cut -d'"' -f4)
echo "Token: $TOKEN"
```

**Kontrolli et token on salvestatud:**
```bash
echo $TOKEN | cut -c1-50
# Peaks algama: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

### Samm 3: Loo TODO

```bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Esimene TODO",
    "description": "Testimine käib!",
    "priority": "high"
  }'
```

**Oodatav vastus:**
```json
{
  "id": 6,
  "userId": 5,
  "title": "Esimene TODO",
  "description": "Testimine käib!",
  "completed": false,
  "priority": "high",
  "dueDate": null,
  "createdAt": "2025-11-16T12:30:00",
  "updatedAt": "2025-11-16T12:30:00"
}
```

**Märkus:** `id` võib olla erinev (6, 7, 8 vms) - see on OK

---

### Samm 4: Loe kõik TODOd

```bash
curl http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN"
```

**Oodatav vastus:**
```json
{
  "content": [
    {
      "id": 6,
      "userId": 5,
      "title": "Esimene TODO",
      "description": "Testimine käib!",
      "completed": false,
      "priority": "high",
      "dueDate": null,
      "createdAt": "2025-11-16T12:30:00",
      "updatedAt": "2025-11-16T12:30:00"
    }
  ],
  "totalElements": 1,
  "totalPages": 1,
  "currentPage": 0,
  "pageSize": 10
}
```

---

### Samm 5: Märgi TODO tehtuks

```bash
# Asenda "6" oma TODO ID'ga
curl -X PATCH http://localhost:8081/api/todos/6/complete \
  -H "Authorization: Bearer $TOKEN"
```

**Oodatav vastus:**
```json
{
  "id": 6,
  "userId": 5,
  "title": "Esimene TODO",
  "description": "Testimine käib!",
  "completed": true,    ← Muutus false → true
  "priority": "high",
  "dueDate": null,
  "createdAt": "2025-11-16T12:30:00",
  "updatedAt": "2025-11-16T12:35:00"  ← Uuendatud
}
```

---

### Samm 6: Vaata statistikat

```bash
curl http://localhost:8081/api/todos/stats \
  -H "Authorization: Bearer $TOKEN"
```

**Oodatav vastus:**
```json
{
  "totalTodos": 1,
  "completedTodos": 1,
  "pendingTodos": 0,
  "completionRate": 100.0,
  "todosByPriority": {
    "high": 1,
    "medium": 0,
    "low": 0
  }
}
```

---

### Samm 7: Filtreeri TODOsid

**Ainult lõpetatud:**
```bash
curl "http://localhost:8081/api/todos?completed=true" \
  -H "Authorization: Bearer $TOKEN"
```

**Ainult pooleliolevad:**
```bash
curl "http://localhost:8081/api/todos?completed=false" \
  -H "Authorization: Bearer $TOKEN"
```

**Kõrge prioriteediga:**
```bash
curl "http://localhost:8081/api/todos?priority=high" \
  -H "Authorization: Bearer $TOKEN"
```

**Lehekülgedega (pagination):**
```bash
curl "http://localhost:8081/api/todos?page=0&size=5" \
  -H "Authorization: Bearer $TOKEN"
```

---

### Samm 8: Uuenda TODO

```bash
curl -X PUT http://localhost:8081/api/todos/6 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Uuendatud pealkiri",
    "description": "Uus kirjeldus",
    "priority": "medium",
    "completed": false
  }'
```

---

### Samm 9: Kustuta TODO

```bash
curl -X DELETE http://localhost:8081/api/todos/6 \
  -H "Authorization: Bearer $TOKEN"
```

**Oodatav:** HTTP 204 No Content (tühi vastus)

---

## 🤖 Automaatne Testimine

Salvesta see fail nimega `test-app.sh`:

```bash
#!/bin/bash

# ==========================================================================
# Todo App Automaatne Testimine
# ==========================================================================

BASE_URL="http://localhost:3000"
TODO_URL="http://localhost:8081"

echo "🧪 Todo App Testimine"
echo "===================="

# Värvid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Health Check
echo -e "\n${YELLOW}1. Health Check...${NC}"
USER_HEALTH=$(curl -s $BASE_URL/health)
TODO_HEALTH=$(curl -s $TODO_URL/health)

if [[ $USER_HEALTH == *"UP"* ]]; then
  echo -e "${GREEN}✅ User Service: UP${NC}"
else
  echo -e "${RED}❌ User Service: DOWN${NC}"
  exit 1
fi

if [[ $TODO_HEALTH == *"UP"* ]]; then
  echo -e "${GREEN}✅ Todo Service: UP${NC}"
else
  echo -e "${RED}❌ Todo Service: DOWN${NC}"
  exit 1
fi

# 2. Register (võib ebaõnnestuda kui kasutaja on juba olemas - see on OK)
echo -e "\n${YELLOW}2. Registreerimine...${NC}"
REGISTER_RESP=$(curl -s -X POST $BASE_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Auto Test","email":"test@example.com","password":"test123"}')

if [[ $REGISTER_RESP == *"successfully"* ]] || [[ $REGISTER_RESP == *"already exists"* ]]; then
  echo -e "${GREEN}✅ Kasutaja olemas${NC}"
else
  echo -e "${RED}❌ Registreerimine ebaõnnestus${NC}"
  echo "$REGISTER_RESP"
fi

# 3. Login
echo -e "\n${YELLOW}3. Login...${NC}"
LOGIN_RESP=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}')

TOKEN=$(echo $LOGIN_RESP | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo -e "${RED}❌ Login ebaõnnestus!${NC}"
  echo "$LOGIN_RESP"
  exit 1
else
  echo -e "${GREEN}✅ Token saadud: ${TOKEN:0:50}...${NC}"
fi

# 4. Create TODO
echo -e "\n${YELLOW}4. TODO loomine...${NC}"
CREATE_RESP=$(curl -s -X POST $TODO_URL/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Auto test TODO","description":"Created by test script","priority":"high"}')

TODO_ID=$(echo $CREATE_RESP | grep -o '"id":[0-9]*' | cut -d':' -f2)

if [ ! -z "$TODO_ID" ]; then
  echo -e "${GREEN}✅ TODO loodud (ID: $TODO_ID)${NC}"
else
  echo -e "${RED}❌ TODO loomine ebaõnnestus${NC}"
  echo "$CREATE_RESP"
  exit 1
fi

# 5. Get TODOs
echo -e "\n${YELLOW}5. TODOde lugemine...${NC}"
GET_RESP=$(curl -s $TODO_URL/api/todos \
  -H "Authorization: Bearer $TOKEN")

TOTAL=$(echo $GET_RESP | grep -o '"totalElements":[0-9]*' | cut -d':' -f2)

if [ ! -z "$TOTAL" ]; then
  echo -e "${GREEN}✅ Leitud $TOTAL TODO'd${NC}"
else
  echo -e "${RED}❌ TODOde lugemine ebaõnnestus${NC}"
  exit 1
fi

# 6. Complete TODO
echo -e "\n${YELLOW}6. TODO märkimine tehtuks...${NC}"
COMPLETE_RESP=$(curl -s -X PATCH $TODO_URL/api/todos/$TODO_ID/complete \
  -H "Authorization: Bearer $TOKEN")

COMPLETED=$(echo $COMPLETE_RESP | grep -o '"completed":true')

if [ ! -z "$COMPLETED" ]; then
  echo -e "${GREEN}✅ TODO märgitud tehtuks${NC}"
else
  echo -e "${RED}❌ TODO märkimine ebaõnnestus${NC}"
  exit 1
fi

# 7. Stats
echo -e "\n${YELLOW}7. Statistika...${NC}"
STATS_RESP=$(curl -s $TODO_URL/api/todos/stats \
  -H "Authorization: Bearer $TOKEN")

TOTAL_TODOS=$(echo $STATS_RESP | grep -o '"totalTodos":[0-9]*' | cut -d':' -f2)
COMPLETED_TODOS=$(echo $STATS_RESP | grep -o '"completedTodos":[0-9]*' | cut -d':' -f2)

if [ ! -z "$TOTAL_TODOS" ]; then
  echo -e "${GREEN}✅ Statistika:${NC}"
  echo "   Kokku: $TOTAL_TODOS"
  echo "   Tehtud: $COMPLETED_TODOS"
else
  echo -e "${RED}❌ Statistika lugemine ebaõnnestus${NC}"
  exit 1
fi

# 8. Delete TODO
echo -e "\n${YELLOW}8. TODO kustutamine...${NC}"
DELETE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE $TODO_URL/api/todos/$TODO_ID \
  -H "Authorization: Bearer $TOKEN")

if [ "$DELETE_CODE" == "204" ]; then
  echo -e "${GREEN}✅ TODO kustutatud${NC}"
else
  echo -e "${RED}❌ TODO kustutamine ebaõnnestus (HTTP $DELETE_CODE)${NC}"
fi

# Kokkuvõte
echo -e "\n${GREEN}===================="
echo "✅ Kõik testid läbitud!"
echo "====================${NC}"
```

**Kasutamine:**

```bash
# Salvesta fail
vim test-app.sh
# (kopeeri ülaltoodud sisu)

# Anna käivitusõigused
chmod +x test-app.sh

# Käivita
./test-app.sh
```

---

## 🌐 Brauserist Testimine

### Otse localhost'ist

1. **Frontend:** http://localhost:8080
2. **Todo leht:** http://localhost:8080/todo
3. **Swagger API docs:** http://localhost:8081/swagger-ui.html

### Domeeni kaudu (kui Nginx seadistatud)

1. **Frontend:** http://kirjakast.cloud
2. **Todo leht:** http://kirjakast.cloud/todo
3. **API:** http://kirjakast.cloud/api/todos

---

## 🐛 Troubleshooting

### ❌ Probleem: "Connection refused"

**Põhjus:** Teenused ei tööta

**Lahendus:**
```bash
cd /home/janek/projects/hostinger/labs/apps
docker compose ps
docker compose restart user-service todo-service
```

---

### ❌ Probleem: "Unauthorized" (HTTP 401)

**Põhjus:** JWT token on aegunud (TTL: 1 tund)

**Lahendus:**
```bash
# Logi uuesti sisse ja saa uus token
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

---

### ❌ Probleem: "Invalid email or password"

**Põhjus:** Kasutaja pole loodud või vale parool

**Lahendus:**
```bash
# Kontrolli kas kasutaja on olemas
docker exec -it postgres-user psql -U postgres -d user_service_db \
  -c "SELECT id, email, name FROM users;"

# Kui pole, registreeri uuesti
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"test123"}'
```

---

### ❌ Probleem: "Table 'todos' doesn't exist"

**Põhjus:** Andmebaas pole seadistatud

**Lahendus:**
```bash
# Käivita database setup
cd /home/janek/projects/hostinger/labs/apps/backend-java-spring
docker exec -i postgres-todo psql -U postgres -d todo_service_db < database-setup.sql
```

---

### ❌ Probleem: User Service on "unhealthy"

**Vaata logisid:**
```bash
docker compose logs user-service --tail=50
```

**Tüüpilised vead:**
- `ECONNREFUSED` → PostgreSQL ei tööta
- `password authentication failed` → Vale DB parool

**Lahendus:**
```bash
# Restart teenused õiges järjekorras
docker compose stop user-service
docker compose start postgres-user
sleep 5
docker compose start user-service
```

---

### ❌ Probleem: Todo Service on "unhealthy"

**Vaata logisid:**
```bash
docker compose logs todo-service --tail=50
```

**Tüüpilised vead:**
- `Table 'todos' doesn't exist` → Käivita database-setup.sql
- `Connection refused` → PostgreSQL pole valmis

**Lahendus:**
```bash
# Restart teenused
docker compose restart postgres-todo
sleep 10
docker compose restart todo-service
```

---

## 📊 Andmebaasi Otsene Kontrollimine

### User Service andmebaas

```bash
# Ühenda andmebaasiga
docker exec -it postgres-user psql -U postgres -d user_service_db

# Vaata kasutajaid
SELECT id, name, email, role, created_at FROM users;

# Välju
\q
```

### Todo Service andmebaas

```bash
# Ühenda andmebaasiga
docker exec -it postgres-todo psql -U postgres -d todo_service_db

# Vaata TODO'sid
SELECT id, user_id, title, completed, priority, created_at FROM todos;

# Vaata statistikat
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE completed = true) as completed,
  COUNT(*) FILTER (WHERE completed = false) as pending
FROM todos;

# Välju
\q
```

---

## 📝 Täielik Valideerimise Checklist

Kopeeri see ja märgi ära kui testid:

### Teenuste Staatus
- [ ] `docker compose ps` → 5 teenust "Up (healthy)"
- [ ] User Service health check → HTTP 200
- [ ] Todo Service health check → HTTP 200
- [ ] Frontend kättesaadav → HTTP 200

### User Service (Autentimine)
- [ ] Registreerimine töötab
- [ ] Login töötab
- [ ] JWT token saadakse
- [ ] Token on kehtiv (mitte "null")

### Todo Service (CRUD)
- [ ] TODO loomine töötab (POST /api/todos)
- [ ] TODOde lugemine töötab (GET /api/todos)
- [ ] TODO uuendamine töötab (PUT /api/todos/:id)
- [ ] TODO märkimine tehtuks töötab (PATCH /api/todos/:id/complete)
- [ ] TODO kustutamine töötab (DELETE /api/todos/:id)
- [ ] Statistika töötab (GET /api/todos/stats)

### Filtreerimine
- [ ] Filter completed=true töötab
- [ ] Filter priority=high töötab
- [ ] Pagination töötab (page, size)

### Turvalisus
- [ ] Ilma tokenita API ei tööta (HTTP 401)
- [ ] Vale tokeniga API ei tööta (HTTP 401)
- [ ] Kasutaja näeb ainult oma TODO'sid

---

## 🎯 Kui Kõik Töötab

**Õnnitlused!** 🎉

Sinu Todo App on täielikult toimiv:
- ✅ User Service (Node.js + Express + PostgreSQL)
- ✅ Todo Service (Java + Spring Boot + PostgreSQL)
- ✅ JWT autentimine
- ✅ RESTful API
- ✅ Docker Compose orchestration

**Järgmised sammud:**
1. Testi domeeni kaudu (http://kirjakast.cloud)
2. Testi Kubernetes Ingress'iga (Lab 4)
3. Lisa SSL/TLS (HTTPS)
4. Seadista CI/CD (Lab 5)
5. Lisa monitoring (Lab 6)

---

**Viimane uuendus:** 2025-11-16
**Autor:** DevOps Training Labs
