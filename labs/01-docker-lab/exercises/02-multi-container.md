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
-- TÄHTIS: Kasuta BIGSERIAL ja BIGINT, mitte SERIAL ja INTEGER!
-- Spring Boot JPA Entity kasutab Long tüüpi, mis vajab BIGINT
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

-- Kontrolli
\dt
\q
```

### Samm 3: Käivita Todo Service Container (15 min)

```bash
# Stopp varasem container
docker stop todo-service
docker rm todo-service

# Genereeri turvaline JWT_SECRET (kui pole veel teinud)
openssl rand -base64 32

# Käivita uuesti, ühendades PostgreSQL'iga
# HOIATUS: host.docker.internal ei tööta Linuxis!
docker run -d \
  --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=zXsK64+uquelt/hQqVzK9P3xoBISiiNQsQbg2OR3ncU= \
  -e SPRING_PROFILES_ACTIVE=prod \
  todo-service:1.0

# Kontrolli logisid
docker logs -f todo-service
```

**Probleem:** `host.docker.internal` ei tööta Linuxis!

**Lahendus Linuxis (Ubuntu):** Kasuta `--link` või PostgreSQL container IP'd:

```bash
# Variant 1: Kasuta --link (deprecated, aga lihtne ja toimib)
docker run -d \
  --name todo-service \
  --link postgres-todo:postgres \
  -p 8081:8081 \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=zXsK64+uquelt/hQqVzK9P3xoBISiiNQsQbg2OR3ncU= \
  todo-service:1.0

# Variant 2: Leia PostgreSQL IP ja kasuta seda
POSTGRES_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgres-todo)
echo "PostgreSQL IP: $POSTGRES_IP"

docker run -d \
  --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=$POSTGRES_IP \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=zXsK64+uquelt/hQqVzK9P3xoBISiiNQsQbg2OR3ncU= \
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

**1. Connection refused:**
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

**2. JWT_SECRET liiga lühike:**
```bash
# Error: The specified key byte array is 88 bits which is not secure enough

# Lahendus: Genereeri 256+ bitine võti
openssl rand -base64 32
# Kasuta väljundit -e JWT_SECRET=...
```

**3. Schema validation error (wrong column type):**
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
```

**4. host.docker.internal ei tööta (Linux):**
```bash
# Error: java.net.UnknownHostException: host.docker.internal

# Lahendus: Kasuta --link või container IP
docker stop todo-service && docker rm todo-service
docker run -d --name todo-service \
  --link postgres-todo:postgres \
  -e DB_HOST=postgres \
  ... (muud parameetrid)
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

### Kontseptsioonid:
- Container linking (deprecated, kasuta networks!)
- Environment variables ja nende edastamine containeritele
- Container-to-container connectivity
- Database initialization ja tabeli loomine
- Multi-container troubleshooting

### Levinud probleemid ja lahendused:
- **JWT_SECRET** peab olema vähemalt 256 bits (32 tähemärki)
- **BIGSERIAL vs SERIAL** - Spring Boot JPA kasutab Long → vajab BIGINT
- **host.docker.internal** ei tööta Linuxis → kasuta `--link` või container IP
- **Schema validation errors** - andmebaasi veergude tüübid peavad vastama JPA Entity tüüpidele

### Järgmine samm:
Harjutus 3 õpetab **proper networking'ut** Docker networks kasutades (mitte deprecated `--link`)!

---

**Järgmine:** [Harjutus 3: Networking](03-networking.md) - õpi proper networking'ut!
