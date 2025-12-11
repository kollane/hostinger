# Harjutus 8: Legacy Integration - Lahendused

See kataloog sisaldab lahendusi Harjutus 8 jaoks: Docker + Olemasolev (Legacy) Infrastruktuur.

---

## 📂 Failide Struktuur

```
08-legacy-integration/
├── README.md                        # See fail
├── tier1-legacy-db/                 # Legacy andmebaas (simulatsioon)
│   └── docker-compose.yml
├── tier2-docker-apps/               # Dockerised mikroteenused
│   ├── docker-compose.yml
│   └── .env.example
└── tier3-legacy-nginx/              # Legacy load balancer (simulatsioon)
    ├── docker-compose.yml
    └── nginx.conf
```

---

## 🚀 Quick Start

### Variant A: Käivita kõik 3 tier'i korraga

```bash
cd tier1-legacy-db && docker compose up -d && cd ..
cd tier2-docker-apps && docker compose up -d && cd ..
cd tier3-legacy-nginx && docker compose up -d && cd ..

# Testi
curl http://localhost:8080/health
```

### Variant B: Sammhaaval (soovitatav õppimiseks)

Järgi [exercises/08-legacy-integration.md](../../exercises/08-legacy-integration.md) juhiseid.

---

## 🏗️ Arhitektuur

```
┌────────────────────────────────────────────────────────────┐
│ Tier 3: legacy-nginx-lb (port 8080)                       │
│ - Nginx reverse proxy                                     │
│ - Avalik endpoint                                         │
└───────────────────────┬────────────────────────────────────┘
                        │ HTTP (host.docker.internal:3000, :8081)
                        ▼
┌────────────────────────────────────────────────────────────┐
│ Tier 2: docker-user-service (3000), docker-todo-service   │
│ - Dockerised mikroteenused                                │
│ - Ühenduvad legacy DB'ga                                  │
└───────────────────────┬────────────────────────────────────┘
                        │ TCP (host.docker.internal:5432, :5433)
                        ▼
┌────────────────────────────────────────────────────────────┐
│ Tier 1: legacy-postgres-user (5432), legacy-postgres-todo │
│ - Legacy andmebaas (simulatsioon)                         │
│ - Eksponeeritud hostile                                   │
└────────────────────────────────────────────────────────────┘
```

---

## 🧪 Testimine

### End-to-End Test

```bash
# 1. Health check'id
curl http://localhost:8080/health     # Nginx LB
curl http://localhost:3000/health     # User Service (otse)
curl http://localhost:8081/health     # Todo Service (otse)

# 2. Registreeri kasutaja (läbi Nginx)
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "test123"
  }'

# 3. Login (saad JWT token)
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "Token: $TOKEN"

# 4. Loo todo (läbi Nginx)
curl -X POST http://localhost:8080/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test Legacy Integration",
    "description": "Full stack test"
  }'

# 5. Vaata todo'sid
curl http://localhost:8080/api/todos \
  -H "Authorization: Bearer $TOKEN"

# 6. Kontrolli andmebaasis
docker exec -it legacy-postgres-user psql -U dbuser -d user_service_db -c "SELECT * FROM users;"
docker exec -it legacy-postgres-todo psql -U dbuser -d todo_service_db -c "SELECT * FROM todos;"
```

---

## 🔧 Konfiguratsioon

### Environment Variables (Tier 2)

Kopeeri `.env.example` → `.env`:

```bash
cd tier2-docker-apps
cp .env.example .env
vim .env
```

Uuenda `JWT_SECRET` väärtust!

---

## 🐛 Troubleshooting

### Probleem: "Could not connect to database"

**Lahendus (Linux):**

Kui `host.docker.internal` ei tööta:

```bash
# Kontrolli extra_hosts
docker compose config | grep extra_hosts

# Või kasuta host IP'd
ip addr show docker0 | grep "inet "
# Uuenda DATABASE_URL → 172.17.0.1:5432
```

### Probleem: "502 Bad Gateway" Nginx'ist

**Lahendus:**

```bash
# Kontrolli Tier 2 töötab
cd tier2-docker-apps && docker compose ps

# Testi otse (mööda Nginx'i)
curl http://localhost:3000/health
curl http://localhost:8081/health
```

---

## 🧹 Puhastamine

```bash
# Peata kõik tier'id
cd tier1-legacy-db && docker compose down -v
cd ../tier2-docker-apps && docker compose down
cd ../tier3-legacy-nginx && docker compose down

# Eemalda volumes
docker volume rm legacy-postgres-user-data legacy-postgres-todo-data
```

---

## 📚 Viited

- [Harjutus 8 juhised](../../exercises/08-legacy-integration.md)
- [Docker host.docker.internal](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)
- [Nginx upstream](http://nginx.org/en/docs/http/ngx_http_upstream_module.html)

---

**Viimane uuendus:** 2025-12-11
