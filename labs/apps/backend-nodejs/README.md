# User Service - Backend Node.js

**Eesmärk:** REST API kasutajate haldamiseks JWT autentimisega ja RBAC-ga

**Tehnoloogiad:**
- Node.js 18+
- Express.js
- PostgreSQL
- JWT (jsonwebtoken)
- bcrypt

**Port:** 3000

---

## 📋 Funktsioonid

### Autentimine
- ✅ Kasutaja registreerimine
- ✅ JWT-põhine sisselogimine
- ✅ Token-based authentication
- ✅ Parooli hasheerimine (bcrypt)

### Kasutajate haldamine (CRUD)
- ✅ Kõigi kasutajate loend (pagination, search, filter)
- ✅ Konkreetse kasutaja vaatamine
- ✅ Kasutaja loomine (ainult admin)
- ✅ Kasutaja uuendamine
- ✅ Kasutaja kustutamine (ainult admin)

### Profiile haldamine
- ✅ Oma profiili vaatamine
- ✅ Oma profiili uuendamine
- ✅ Parooli vahetus

### RBAC (Role-Based Access Control)
- ✅ Rollid: `user`, `admin`
- ✅ Rollipõhine juurdepääsukontroll

---

## 🚀 Kiirstart

### 1. Paigalda sõltuvused

```bash
npm install
```

### 2. Seadista keskkond

```bash
cp .env.example .env
nano .env
```

Muuda `.env` failis:
```env
JWT_SECRET=your-very-secret-key
DB_NAME=user_service_db
DB_USER=postgres
DB_PASSWORD=postgres
```

### 3. Seadista andmebaas

```bash
# Käivita PostgreSQL
sudo systemctl start postgresql

# Loo andmebaas ja tabelid
sudo -u postgres psql -f database-setup.sql
```

### 4. Käivita server

```bash
# Development
npm start

# Production
NODE_ENV=production npm start
```

Server käivitub aadressil: `http://localhost:3000`

---

## 📚 API Dokumentatsioon

### Base URL

```
http://localhost:3000/api
```

### Autentimise endpoint'id

#### 1. Registreeri kasutaja

```http
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Vastus:**
```json
{
  "message": "User created successfully",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "created_at": "2025-11-15T10:00:00.000Z"
  }
}
```

#### 2. Logi sisse

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

**Vastus:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user"
  }
}
```

### Kasutajate endpoint'id

**Märkus:** Kõik kasutajate endpoint'id nõuavad JWT tokenit.

```http
Authorization: Bearer <token>
```

#### 3. Hangi kõik kasutajad

```http
GET /api/users?page=1&limit=10&search=john&role=user&sortBy=name&sortOrder=ASC
Authorization: Bearer <token>
```

**Query parameetrid:**
- `page` - Lehekülje number (default: 1)
- `limit` - Tulemuste arv lehe kohta (default: 10)
- `search` - Otsi nime või emaili järgi
- `role` - Filtreeri rolli järgi (`user`, `admin`)
- `sortBy` - Sorteeri välja järgi (`name`, `email`, `created_at`, `updated_at`)
- `sortOrder` - Sorteerimise järjekord (`ASC`, `DESC`)

**Vastus:**
```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "user",
      "created_at": "2025-11-15T10:00:00.000Z",
      "updated_at": "2025-11-15T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 1,
    "totalPages": 1
  }
}
```

#### 4. Hangi kasutaja ID järgi

```http
GET /api/users/:id
Authorization: Bearer <token>
```

#### 5. Loo uus kasutaja (ainult admin)

```http
POST /api/users
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Jane Smith",
  "email": "jane@example.com",
  "password": "password123",
  "role": "user"
}
```

#### 6. Uuenda kasutajat

```http
PUT /api/users/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Updated",
  "email": "john.updated@example.com"
}
```

**Õigused:**
- Admin saab uuendada kõiki kasutajaid
- Tavakasutaja saab uuendada ainult iseennast
- Ainult admin saab muuta rolle

#### 7. Kustuta kasutaja (ainult admin)

```http
DELETE /api/users/:id
Authorization: Bearer <token>
```

### Profiili endpoint'id

#### 8. Hangi oma profiil

```http
GET /api/users/me
Authorization: Bearer <token>
```

#### 9. Uuenda oma profiili

```http
PUT /api/users/me
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Updated",
  "email": "john.new@example.com"
}
```

#### 10. Muuda parooli

```http
PUT /api/users/me/password
Authorization: Bearer <token>
Content-Type: application/json

{
  "currentPassword": "password123",
  "newPassword": "newpassword456"
}
```

### Tervisekontroll

#### 11. Health Check

```http
GET /health
```

**Vastus:**
```json
{
  "status": "OK",
  "timestamp": "2025-11-15T10:00:00.000Z",
  "service": "user-service",
  "database": "connected"
}
```

---

## 🧪 Testimine

### cURL näited

```bash
# 1. Registreeri kasutaja
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"test123"}'

# 2. Logi sisse ja salvesta token
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  | jq -r '.token')

# 3. Hangi kõik kasutajad
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer $TOKEN"

# 4. Hangi oma profiil
curl http://localhost:3000/api/users/me \
  -H "Authorization: Bearer $TOKEN"

# 5. Uuenda profiili
curl -X PUT http://localhost:3000/api/users/me \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Name"}'

# 6. Muuda parooli
curl -X PUT http://localhost:3000/api/users/me/password \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"currentPassword":"test123","newPassword":"newpass456"}'
```

---

## 🔐 Turvalisus

### Implementeeritud

- ✅ **Password Hashing** - bcrypt (10 rounds)
- ✅ **JWT Authentication** - Token-based auth
- ✅ **RBAC** - Role-based access control
- ✅ **SQL Injection Protection** - Parameterized queries
- ✅ **Input Validation** - Required fields validation
- ✅ **CORS** - Cross-Origin Resource Sharing

### Puuduvad (lisada tootmises)

- ⚠️ **HTTPS** - SSL/TLS encryption
- ⚠️ **Rate Limiting** - API rate limiting
- ⚠️ **Refresh Tokens** - Token refresh mechanism
- ⚠️ **Password Requirements** - Min length, complexity
- ⚠️ **Account Lockout** - Brute force protection
- ⚠️ **Audit Logging** - Security event logging
- ⚠️ **Input Sanitization** - XSS protection

---

## 🐳 Docker

### Dockerfile on olemas!

Valmis konteineriseerimiseks Labor 1's.

```bash
# Build image
docker build -t user-service .

# Run container
docker run -p 3000:3000 --env-file .env user-service
```

---

## 📁 Projekti struktuur

```
backend-nodejs/
├── server.js            # Peamine rakenduse fail
├── package.json         # Node.js sõltuvused
├── .env.example         # Näidis keskkonna muutujad
├── .gitignore           # Git ignore
├── Dockerfile           # Docker konteiner
├── database-setup.sql   # PostgreSQL skeem
└── README.md            # See fail
```

---

## 🔗 Seotud peatükid koolituskavas

- **Peatükk 5:** Node.js ja Express.js
- **Peatükk 6:** PostgreSQL integratsioon
- **Peatükk 7:** REST API disain
- **Peatükk 8:** Autentimine ja autoriseerimine
- **Peatükk 12:** Docker põhimõtted

---

## 📦 Kasutatavad laborites

See rakendus on valmis kasutamiseks järgmistes laborites:

- **Labor 1:** Docker põhitõed - Konteineriseerimine
- **Labor 2:** Docker Compose - Multi-container setup
- **Labor 3:** Kubernetes alused - K8s deployment
- **Labor 4:** Kubernetes täiustatud - Scaling, ingress
- **Labor 5:** CI/CD pipeline - Automated deployment
- **Labor 6:** Monitoring ja logging - Prometheus, Grafana

---

**Valmis DevOps harjutusteks! 🚀**
