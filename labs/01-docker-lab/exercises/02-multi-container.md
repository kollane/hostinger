# Harjutus 2: Multi-Container Setup

**Kestus:** 60 minutit
**Eesmärk:** Käivita Java Spring Boot Todo Service koos PostgreSQL andmebaasiga

---

## 📋 Ülevaade

Õpi käivitama kahte containerit koos - Todo Service ja PostgreSQL - ning ühendama neid omavahel.

---

## 🎯 Õpieesmärgid

- ✅ Käivitada PostgreSQL container
- ✅ Ühendada Java Spring Boot rakendus PostgreSQL'iga
- ✅ Kasutada container networking'ut
- ✅ Testi CRUD operatsioone
- ✅ Debuggida connectivity probleeme

---

## 📝 Sammud

### Samm 1: Käivita PostgreSQL Container (15 min)

```bash
# Käivita PostgreSQL container
docker run -d \
  --name postgres-todo \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  -p 5433:5432 \
  postgres:16-alpine

# Kontrolli
docker ps | grep postgres

# Vaata logisid
docker logs postgres-todo
```

**Märkus:** Kasutame porti 5433, et vältida konflikti teiste PostgreSQL instantsidega.

### Samm 2: Seadista Andmebaas (10 min)

```bash
# Ühenda PostgreSQL'iga
docker exec -it postgres-todo psql -U postgres -d todo_service_db

# SQL konsoolis:
-- Loo todos tabel
CREATE TABLE todos (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    priority VARCHAR(20) DEFAULT 'medium',
    due_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Kontrolli
\dt
\q
```

### Samm 3: Käivita Todo Service Container (15 min)

```bash
# Stopp varasem container
docker stop todo-service
docker rm todo-service

# Käivita uuesti, ühendades PostgreSQL'iga
docker run -d \
  --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-secret-key \
  -e SPRING_PROFILES_ACTIVE=prod \
  todo-service:1.0

# Kontrolli logisid
docker logs -f todo-service
```

**Probleem:** `host.docker.internal` ei pruugi Linuxis töötada!

**Lahendus:** Kasuta PostgreSQL container IP'd:

```bash
# Leia PostgreSQL IP
docker inspect postgres-todo | grep IPAddress

# Või kasuta --link (deprecated, aga toimib)
docker run -d \
  --name todo-service \
  --link postgres-todo:postgres \
  -p 8081:8081 \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-secret-key \
  todo-service:1.0
```

### Samm 4: Testi API (15 min)

**Märkus:** Todo Service vajab JWT tokenit User Service'ilt. Testimiseks võid kasutada mock tokenit või esmalt registreerida kasutaja User Service'is (kui see on käivitatud).

```bash
# Health check
curl http://localhost:8081/health

# Kui sul on JWT token User Service'ilt:
TOKEN="<jwt-token-from-user-service>"

# Loo todo
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Õpi Docker",
    "description": "Läbi töötada kõik Lab 1 harjutused",
    "priority": "high",
    "dueDate": "2025-11-20T18:00:00"
  }'

# Loe kõik todos
curl -X GET http://localhost:8081/api/todos \
  -H "Authorization: Bearer $TOKEN"

# Märgi todo tehtud (id=1)
curl -X PATCH http://localhost:8081/api/todos/1/complete \
  -H "Authorization: Bearer $TOKEN"
```

### Samm 5: Troubleshooting (5 min)

**Connection refused:**
```bash
# Kontrolli, kas PostgreSQL töötab
docker ps | grep postgres

# Vaata Todo Service logisid
docker logs todo-service

# Testi connectivity container'ist
docker exec -it todo-service sh
# Container sees (kui ping on installitud):
# ping postgres  # peaks töötama kui kasutad --link
exit
```

---

## ✅ Kontrolli

- [x] PostgreSQL container töötab (port 5433)
- [x] Todo Service container töötab (port 8081)
- [x] Health check tagastab `"status": "UP"`
- [x] Andmebaas on ühendatud
- [x] Tabelid on loodud
- [x] CRUD operatsioonid töötavad (JWT tokeniga)

---

## 🎓 Õpitud

- Container linking (deprecated, kasuta networks!)
- Environment variables
- Container connectivity
- Database initialization
- Multi-container troubleshooting

---

**Järgmine:** [Harjutus 3: Networking](03-networking.md) - õpi proper networking'ut!
