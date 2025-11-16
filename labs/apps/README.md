# Valmis Rakendused DevOps Laborite Jaoks

**Eesmärk:** Need rakendused on valmis konteineriseerimiseks ja deploymiseks DevOps laborites.

**Fookus:** DevOps/infrastruktuurihaldamine, mitte rakenduste arendamine.

---

## 📦 Rakenduste Ülevaade

### 1. User Service (Node.js)

**Kaust:** `backend-nodejs/`

**Kirjeldus:** REST API kasutajate haldamiseks JWT autentimisega

**Tehnoloogiad:**
- Node.js 18+
- Express.js
- PostgreSQL
- JWT + bcrypt
- RBAC (user, admin)

**Port:** 3000

**API Endpoint'id:**
- `POST /api/auth/register` - Kasutaja registreerimine
- `POST /api/auth/login` - JWT sisselogimine
- `GET /api/users` - Kõik kasutajad (pagination, search, filter)
- `GET /api/users/:id` - Konkreetne kasutaja
- `POST /api/users` - Loo kasutaja (admin)
- `PUT /api/users/:id` - Uuenda kasutajat
- `DELETE /api/users/:id` - Kustuta kasutaja (admin)
- `GET /api/users/me` - Oma profiil
- `PUT /api/users/me` - Uuenda profiili
- `PUT /api/users/me/password` - Muuda parooli
- `GET /health` - Tervisekontroll

**Näidis:**
```bash
cd backend-nodejs
npm install
cp .env.example .env
npm start
```

**Kasutatakse laborites:**
- Labor 1: Docker põhitõed
- Labor 2: Docker Compose
- Labor 3-4: Kubernetes
- Labor 5: CI/CD
- Labor 6: Monitoring

**Viited koolituskavale:**
- Peatükk 5: Node.js ja Express.js
- Peatükk 6: PostgreSQL integratsioon
- Peatükk 7: REST API disain
- Peatükk 8: Autentimine ja autoriseerimine

---

### 2. Todo Service (Java Spring Boot)

**Kaust:** `backend-java-spring/`

**Kirjeldus:** REST API todo märkmete haldamiseks JWT autentimisega

**Tehnoloogiad:**
- Java 17
- Spring Boot 3
- PostgreSQL
- Spring Security + JWT
- Gradle

**Port:** 8081

**API Endpoint'id:**
- `POST /api/todos` - Loo uus todo
- `GET /api/todos` - Kõik todo'd (pagination, filter)
- `GET /api/todos/{id}` - Konkreetne todo
- `PUT /api/todos/{id}` - Uuenda todo't
- `DELETE /api/todos/{id}` - Kustuta todo
- `PATCH /api/todos/{id}/complete` - Märgi tehtuks
- `GET /api/todos/stats` - Statistika
- `GET /health` - Tervisekontroll
- `GET /swagger-ui.html` - API dokumentatsioon

**Näidis:**
```bash
cd backend-java-spring
./gradlew bootRun
```

**Kasutatakse laborites:**
- Labor 1: Docker põhitõed (Java container, multi-stage build)
- Labor 2: Docker Compose (multi-service)
- Labor 3-4: Kubernetes (JVM tuning, resource limits)
- Labor 5: CI/CD (Gradle builds)
- Labor 6: Monitoring (JVM metrics)

**Viited koolituskavale:**
- Peatükk 12: Docker põhimõtted (Java konteinerid)

---

### 3. Frontend (Web UI)

**Kaust:** `frontend/`

**Kirjeldus:** Kasutajaliides User ja Todo teenuste jaoks

**Tehnoloogiad:**
- HTML5
- CSS3
- Vanilla JavaScript
- Fetch API

**Port:** 8080

**Funktsioonid:**
- Kasutajate haldamine (User Service)
- Todo märkmete haldamine (Todo Service)
- CRUD operatsioonid
- JWT autentimine
- Error handling
- Loading states

**Näidis:**
```bash
cd frontend
python3 -m http.server 8080
```

**Kasutatakse laborites:**
- Labor 1: Docker põhitõed
- Labor 2: Docker Compose
- Labor 3-4: Kubernetes (Ingress)

**Viited koolituskavale:**
- Peatükk 9: HTML5 ja CSS3
- Peatükk 10: Vanilla JavaScript
- Peatükk 11: Frontend ja Backend integratsioon

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────────────────┐
│     Frontend (Port 8080)                │
│     HTML + CSS + JavaScript             │
└────────────────┬────────────────────────┘
                 │
                 │ REST API (JWT)
                 │
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
┌──────────────┐      ┌──────────────┐
│ User Service │      │ Todo Service │
│  (Node.js)   │      │ (Java Spring) │
│  Port 3000   │      │   Port 8081   │
└──────┬───────┘      └───────┬───────┘
       │                      │
       │ PostgreSQL           │ PostgreSQL
       │                      │
       ▼                      ▼
┌──────────────┐      ┌──────────────┐
│ PostgreSQL   │      │ PostgreSQL   │
│  users DB    │      │  todos DB    │
│  Port 5432   │      │  Port 5433   │
└──────────────┘      └──────────────┘
```

---

## 🚀 Kiirstart

### Variant 1: Docker Compose (Soovitatav)

```bash
# Käivita kõik teenused
docker-compose up -d

# Kontrolli
docker-compose ps
docker-compose logs -f

# Stopp
docker-compose down
```

### Variant 2: Manuaalne

```bash
# PostgreSQL
sudo systemctl start postgresql

# User Service
cd backend-nodejs
npm install
cp .env.example .env
npm start

# Todo Service (teine terminal)
cd backend-java-spring
./gradlew bootRun

# Frontend (kolmas terminal)
cd frontend
python3 -m http.server 8080
```

---

## 🧪 Testimine

### Health Check'id

```bash
# User Service
curl http://localhost:3000/health

# Todo Service
curl http://localhost:8081/health

# Frontend
curl http://localhost:8080
```

### API Testimine

```bash
# 1. Registreeri kasutaja
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"test123"}'

# 2. Logi sisse
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# 3. Kasuta tokenit
TOKEN="<token-from-login>"
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN"
```

---

## 📂 Kataloogistruktuur

```
apps/
├── README.md                    # See fail
├── docker-compose.yml           # Kõik teenused koos
│
├── backend-nodejs/              # User Service
│   ├── server.js
│   ├── package.json
│   ├── Dockerfile
│   ├── .env.example
│   ├── database-setup.sql
│   └── README.md
│
├── backend-java-spring/         # Todo Service
│   ├── src/
│   ├── build.gradle
│   ├── Dockerfile
│   ├── Dockerfile.optimized
│   ├── database-setup.sql
│   └── README.md
│
├── frontend/                    # Web UI
│   ├── index.html
│   ├── css/
│   ├── js/
│   ├── Dockerfile
│   └── README.md
│
└── learning-materials/          # Õppematerjalid
    └── auth-tutorial/           # JWT/Auth õpetus
```

---

## 🎓 Kasutatakse Laborites

### Labor 1: Docker Põhitõed
- Konteinerise User Service (Node.js)
- Konteinerise Todo Service (Java Spring Boot, multi-stage build)
- Konteinerise Frontend
- Multi-stage builds (eriti Java jaoks)
- Image optimisatsioon
- JVM tuunimine konteinerites

### Labor 2: Docker Compose
- Käivita kõik teenused
- Networks ja volumes
- Environment variables
- Development vs Production

### Labor 3-4: Kubernetes
- Deploy pods
- Services ja Ingress
- ConfigMaps ja Secrets
- Persistent Volumes
- Autoscaling

### Labor 5: CI/CD
- GitHub Actions
- Automated builds
- Automated deployments
- Testing
- Rollbacks

### Labor 6: Monitoring
- Prometheus metrics
- Grafana dashboards
- Log aggregation
- Alerting
- Troubleshooting

---

## 📚 Viited Koolituskavale

| Rakendus | Seotud Peatükid |
|----------|----------------|
| **User Service** | 5, 6, 7, 8, 12 |
| **Todo Service** | 12 (Java konteinerid, multi-stage builds) |
| **Frontend** | 9, 10, 11 |

---

## 💡 Märkused

### Rakendused on VALMIS

- ✅ Kõik endpoint'id implementeeritud
- ✅ Autentimine ja autoriseerimine toimib
- ✅ Andmebaas seadistatud
- ✅ Dockerfile'id olemas
- ✅ Valmis konteineriseerimiseks

### DevOps Fookus

Need rakendused on mõeldud **DevOps** harjutusteks, mitte rakenduste arendamiseks. Fookus on:

- 🐳 **Konteineriseerimineal** (Docker)
- ☸️ **Orkestratsiooni** (Kubernetes)
- 🔄 **CI/CD** (GitHub Actions)
- 📊 **Monitoring** (Prometheus, Grafana)
- 📝 **Logging** (EFK stack)

---

## 🔗 Järgmised Sammud

1. **Tutvu rakendustega:**
   ```bash
   cd backend-nodejs && cat README.md
   ```

2. **Käivita lokaalselt:**
   ```bash
   docker-compose up
   ```

3. **Alusta Labor 1:**
   ```bash
   cd ../01-docker-lab
   cat README.md
   ```

---

**Valmis DevOps laborite jaoks! 🚀**

*Rakendused on loodud koolituskava peatükkide 5-11 põhjal ja valmis kasutamiseks laborites 1-6.*
