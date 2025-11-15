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

### 2. Product Service (Java Spring Boot)

**Kaust:** `backend-java-spring/`

**Kirjeldus:** REST API toodete haldamiseks

**Tehnoloogiad:**
- Java 17
- Spring Boot 3
- PostgreSQL
- Spring Security

**Port:** 8081

**API Endpoint'id:**
- `GET /api/products` - Kõik tooted
- `GET /api/products/{id}` - Konkreetne toode
- `POST /api/products` - Loo toode
- `PUT /api/products/{id}` - Uuenda toodet
- `DELETE /api/products/{id}` - Kustuta toode
- `GET /actuator/health` - Tervisekontroll

**Näidis:**
```bash
cd backend-java-spring
./mvnw spring-boot:run
```

**Kasutatakse laborites:**
- Labor 1: Docker põhitõed (Java container)
- Labor 2: Docker Compose (multi-service)
- Labor 3-4: Kubernetes

**Viited koolituskavale:**
- Peatükk 12: Docker põhimõtted (Java konteinerid)

---

### 3. Frontend (Web UI)

**Kaust:** `frontend/`

**Kirjeldus:** Kasutajaliides User ja Product teenuste jaoks

**Tehnoloogiad:**
- HTML5
- CSS3
- Vanilla JavaScript
- Fetch API

**Port:** 8080

**Funktsioonid:**
- Kasutajate loend
- Toodete loend
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
│ User Service │      │Product Service│
│  (Node.js)   │      │ (Java Spring) │
│  Port 3000   │      │   Port 8081   │
└──────┬───────┘      └───────┬───────┘
       │                      │
       │ PostgreSQL           │ PostgreSQL
       │                      │
       ▼                      ▼
┌──────────────┐      ┌──────────────┐
│ PostgreSQL   │      │ PostgreSQL   │
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

# Product Service (teine terminal)
cd backend-java-spring
./mvnw spring-boot:run

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

# Product Service
curl http://localhost:8081/actuator/health

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
├── backend-java-spring/         # Product Service
│   ├── src/
│   ├── pom.xml
│   ├── Dockerfile
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
- Konteinerise User Service
- Konteinerise Product Service
- Konteinerise Frontend
- Multi-stage builds
- Image optimisatsioon

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
| **Product Service** | 12 |
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
