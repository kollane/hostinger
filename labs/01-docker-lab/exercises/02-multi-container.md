# Harjutus 2: Multi-Container Setup

**Kestus:** 60 minutit
**Eesmärk:** Käivita Node.js User Service koos PostgreSQL andmebaasiga

---

## 📋 Ülevaade

Õpi käivitama kahte containerit koos - User Service ja PostgreSQL - ning ühendama neid omavahel.

---

## 🎯 Õpieesmärgid

- ✅ Käivitada PostgreSQL container
- ✅ Ühendada Node.js rakendus PostgreSQL'iga
- ✅ Kasutada container networking'ut
- ✅ Testi CRUD operatsioone
- ✅ Debuggida connectivity probleeme

---

## 📝 Sammud

### Samm 1: Käivita PostgreSQL Container (15 min)

```bash
# Käivita PostgreSQL container
docker run -d \
  --name postgres-users \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -p 5432:5432 \
  postgres:15-alpine

# Kontrolli
docker ps | grep postgres

# Vaata logisid
docker logs postgres-users
```

### Samm 2: Seadista Andmebaas (10 min)

```bash
# Ühenda PostgreSQL'iga
docker exec -it postgres-users psql -U postgres -d user_service_db

# SQL konsoolis:
-- Loo users tabel
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Kontrolli
\dt
\q
```

### Samm 3: Käivita User Service Container (15 min)

```bash
# Stopp varasem container
docker stop user-service
docker rm user-service

# Käivita uuesti, ühendades PostgreSQL'iga
docker run -d \
  --name user-service \
  -p 3000:3000 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-secret-key \
  -e JWT_EXPIRES_IN=1h \
  -e NODE_ENV=production \
  user-service:1.0

# Kontrolli logisid
docker logs -f user-service
```

**Probleem:** `host.docker.internal` ei pruugi Linuxis töötada!

**Lahendus:** Kasuta PostgreSQL container IP'd:

```bash
# Leia PostgreSQL IP
docker inspect postgres-users | grep IPAddress

# Või kasuta --link (deprecated, aga toimib)
docker run -d \
  --name user-service \
  --link postgres-users:postgres \
  -p 3000:3000 \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-secret-key \
  user-service:1.0
```

### Samm 4: Testi API (15 min)

```bash
# Health check
curl http://localhost:3000/health

# Registreeri kasutaja
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"test123"}'

# Logi sisse
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Salvesta token
TOKEN="<token-from-response>"

# Hangi kasutajad
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN"
```

### Samm 5: Troubleshooting (5 min)

**Connection refused:**
```bash
# Kontrolli, kas PostgreSQL töötab
docker ps | grep postgres

# Vaata User Service logisid
docker logs user-service

# Testi connectivity container'ist
docker exec -it user-service sh
ping postgres  # peaks töötama kui kasutad --link
exit
```

---

## ✅ Kontrolli

- [ ] PostgreSQL container töötab
- [ ] User Service container töötab
- [ ] Health check tagastab `"database": "connected"`
- [ ] Saad kasutajaid registreerida
- [ ] Saad sisse logida ja tokeni saada
- [ ] CRUD operatsioonid töötavad

---

## 🎓 Õpitud

- Container linking (deprecated, kasuta networks!)
- Environment variables
- Container connectivity
- Database initialization
- Multi-container troubleshooting

---

**Järgmine:** [Harjutus 3: Networking](03-networking.md) - õpi proper networking'ut!
