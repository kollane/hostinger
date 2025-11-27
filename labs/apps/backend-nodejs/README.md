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

## 📘 Mis on User Service rakendus?

User Service on **autentimisteenus**, mis haldab kasutajaid ja annab välja JWT tokeneid.

### Mis rakendus teeb?

1. 🔐 **Registreerimine ja sisselogimine** - kasutajad loovad konto ja logivad sisse
2. 🎫 **JWT tokeni genereerimine** - pärast sisselogimist saab kasutaja tokeni
3. 👥 **Kasutajate haldamine** - loe, muuda, kustuta kasutajaid (CRUD)
4. 🛡️ **Rollipõhine ligipääs** - admin ja user rollid (RBAC)

### Kuidas see töötab koos Todo Service'iga?

See õpperakendus koosneb **kahest eraldi teenusest**:

```
┌─────────────────────┐      ┌──────────────────────┐
│   User Service      │      │   Todo Service       │
│   (Node.js)         │      │   (Java Spring Boot) │
├─────────────────────┤      ├──────────────────────┤
│ ✅ Autentimine      │      │ ✅ Todo ülesanded    │
│ ✅ JWT genereerimine│──────│ ✅ JWT valideerimine │
│ ✅ Kasutajate CRUD  │      │ ✅ Todo CRUD         │
│ ✅ RBAC (rollid)    │      │ ✅ Statistika        │
└─────────────────────┘      └──────────────────────┘
         │                            │
         ↓                            ↓
  PostgreSQL (5432)           PostgreSQL (5433)
  (kasutajad, rollid)         (todo ülesanded)
```

**Töövoog:**

1. Kasutaja logib sisse **User Service'is** → saab JWT tokeni
2. Kasutaja lisab todo **Todo Service'is** → saadab JWT tokeni kaasa
3. Todo Service **valideerib tokenit** (jagavad sama JWT_SECRET)
4. Todo Service näeb tokenist `userId` → salvestab todo õige kasutaja alla

### Miks kaks eraldi teenust?

- ✅ **Eraldi vastutusalad**: User Service = autentimine, Todo Service = ülesanded
- ✅ **Eraldi andmebaasid**: Kasutajad ja todo'd ei sega üksteist
- ✅ **Erinevad tehnoloogiad**: Node.js (User) + Java (Todo) - õpid mõlemat
- ✅ **Iseseisev skaleerimine**: Saab teenuseid eraldi skaleerida vastavalt vajadusele

---

## 🎫 Mis asi on JWT token?

JWT token on **digitaalne tõend**, mis tõestab kasutaja isikut ilma parooliga.

**Kuidas see töötab:**

1. 🔐 **Login** (email + parool) → User Service genereerib JWT tokeni
2. 🎫 **Järgmised päringud** → Kasutaja saadab tokeni kaasa, EI KÜSI PAROOLI
3. ⏰ Token kehtib teatud aja (nt 24h), siis tuleb uuesti sisse logida

**JWT token sisaldab:**
- `userId` - kasutaja ID
- `email` - kasutaja e-mail
- `role` - kasutaja roll (admin, user)
- `exp` - tokeni kehtivusaeg

### Praktiline näide

User Teenus (Service) on **autentimise keskus (authentication hub)** mikroteenuste (microservices) arhitektuuris:

1. **Kasutaja registreerib** → POST /api/auth/register
2. **Kasutaja logib sisse** → POST /api/auth/login
3. **Saab JWT tokeni** → `{"token": "eyJhbGci..."}`
4. **Kasutab tokenit teistes teenustes (services)** → Todo Teenus (Service), Product Teenus (Service) jne

### JWT token sisu

**JWT token sisaldab krüpteeritud infot:**
- `userId` - Kasutaja ID (nt 123)
- `email` - Kasutaja email (nt test@example.com)
- `role` - Kasutaja roll (user/admin)
- `exp` - Token'i aegumisaeg (nt "kehtib kuni 2025-01-27 10:00")

### Tehniliselt

- User Service on **autentimise keskus (authentication hub)**
- JWT token sisaldab kasutaja infot (ID, email, roll)
- Teised teenused saavad JWT-st lugeda, kes kasutaja on
- Ei ole vaja iga teenuse jaoks eraldi kasutajate andmebaasi

### JWT Secret - jagatud saladus

**Oluline:** Kõik teenused (User Service, Todo Service jne) peavad kasutama **SAMA JWT_SECRET** võtit!

**Miks?**
- User Service allkirjastab JWT tokeni `JWT_SECRET` võtmega
- Todo Service kontrollib tokeni **SAMA** `JWT_SECRET` võtmega
- Kui võtmed erinevad, token ei kehti! ❌

**Näide:**

```bash
# ÕIGE: Mõlemad teenused kasutavad SAMA võtit
JWT_SECRET="minu-super-turvaline-secret-12345"

# User Service kasutab: JWT_SECRET="minu-super-turvaline-secret-12345"
# Todo Service kasutab: JWT_SECRET="minu-super-turvaline-secret-12345"
# ✅ Token töötab!

# VALE: Erinevad võtmed
# User Service kasutab: JWT_SECRET="secret-A"
# Todo Service kasutab: JWT_SECRET="secret-B"
# ❌ Token EI tööta!
```

**Genereeri turvaline secret:**

```bash
# Linuxis/macOS
openssl rand -base64 32

# Tulemus: juhuslik 32-tähemärgiline string
# Näide: "xK7mP9vL2nQ8wR5tY6uI0oP3jH4kF1gS2dA9bN7cM5v="
```

**Kuidas seda laborites kasutatakse:**
- **Lab 1:** User Service konteiner hangub (PostgreSQL puudub, JWT-d ei saa testida)
- **Lab 2:** Lisame PostgreSQL + jagatud JWT_SECRET → töötav süsteem!
- **Lab 3+:** Kasutame Kubernetes Secrets JWT_SECRET salvestamiseks

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

## 📘 Mis on User Service ja miks see on vajalik?

### 💡 Lihtsustatult

User Service on nagu **turvatöötaja kontori sissepääsu juures**, kes:
1. 🔐 Kontrollib, kes sa oled (login)
2. 🎫 Annab sulle **digitaalse visiitkaardi** (JWT token)
3. ✅ Teised teenused usaldavad seda visiitkaart

### Igapäevaelu analoogia: Kontorihoone

Kujuta ette **suurt kontorihoone** (mikroteenuste süsteem):

```
🏢 Kontorihoone
│
├── 🚪 Sissepääs (User Service)
│   └── Turvatöötaja kontrollib ID'd ja annab külastuskaardi
│
├── 🏬 Esimene korrus: Köök (Todo Service)
│   └── Kui on külastuskaart, saad süüa
│
├── 🏬 Teine korrus: Raamatukogu (Product Service)
│   └── Kui on külastuskaart, saad raamatuid
│
└── 🏬 Kolmas korrus: Konverentsiruum (Analytics Service)
    └── Kui on külastuskaart, saad siseneda
```

**User Service roll:**
- Ainult **üks sissepääs** kogu hoonesse (centralized authentication)
- Kontrollib kasutajanime ja parooli **ÜHEAINSA** korra
- Annab **külastuskaardi** (JWT token), mis kehtib kõigil korrustel
- Teised teenused usaldavad seda kaarti ilma, et peaksid ise parooli küsima

### Miks see on parem kui iga teenus eraldi?

❌ **Ilma User Service'ta:**
- Todo teenus küsib parooli → kontrollib andmebaasist
- Product teenus küsib parooli → kontrollib andmebaasist
- Analytics teenus küsib parooli → kontrollib andmebaasist
- **Probleem:** Kasutaja peab sisestama parooli KOLM KORDA

✅ **User Service'ga:**
- **Login ÜHEAINSA korra** → Saad JWT tokeni
- Todo teenus usaldab tokenit (ei küsi parooli)
- Product teenus usaldab tokenit (ei küsi parooli)
- Analytics teenus usaldab tokenit (ei küsi parooli)
- **Tulemus:** Kasutaja sisestab parooli ainult üks kord! 🎉

---

## 🎫 Mis asi on JWT token?

### 💡 Lihtsustatult

JWT token on nagu **digitaalne visiitkaart**, mis tõestab, kes sa oled ilma parooliga.

### Analoogia igapäevaelust: Kontori külastuskaart

- 🏢 Kui lähed kontorisse, annavad esimesel korral **külastuskaardi** (pärast parooli kontrolli)
- 🚪 Järgmistel kordadel näitad ainult kaarti, ei pea parooli mitte kunagi enam sisestama
- ✅ Kaart sisaldab infot: nimi, roll, kehtivusaeg

### JWT token töötab täpselt samamoodi

1. 🔐 **Login kord** (email + parool) → Saad JWT tokeni
2. 🎫 **Järgmised päringud** → Näitad ainult tokenit, EI KÜSI PAROOLI
3. ⏰ Token kehtib teatud aja (nt 24h), siis tuleb uuesti sisse logida

### Kuidas see seostub User Service'ga?

Meenuta kontorihoone analogiat:
- 🏢 User Service = turvatöötaja sissepääsu juures
- 🎫 JWT token = digitaalne külastuskaart
- 🚪 Login = kontrollib ID'd ja annab kaardi
- ✅ Teised teenused = usaldavad kaarti, ei küsi parooli enam

See on täpselt see, mida User Service teeb mikroteenuste arhitektuuris!

### Praktiline näide: User Service töövoog

User Teenus (Service) on **autentimise keskus (authentication hub)** mikroteenuste (microservices) arhitektuuris:

1. **Kasutaja registreerib** → POST /api/auth/register
2. **Kasutaja logib sisse** → POST /api/auth/login
3. **Saab JWT tokeni** → `{"token": "eyJhbGci..."}`
4. **Kasutab tokenit teistes teenustes (services)** → Todo Teenus (Service), Product Teenus (Service) jne

### JWT token sisu

**JWT token sisaldab krüpteeritud infot:**
- `userId` - Kasutaja ID (nt 123)
- `email` - Kasutaja email (nt test@example.com)
- `role` - Kasutaja roll (user/admin)
- `exp` - Token'i aegumisaeg (nt "kehtib kuni 2025-01-27 10:00")

### Tehniliselt

- User Service on **autentimise keskus (authentication hub)**
- JWT token sisaldab kasutaja infot (ID, email, roll)
- Teised teenused saavad JWT-st lugeda, kes kasutaja on
- Ei ole vaja iga teenuse jaoks eraldi kasutajate andmebaasi

### JWT Secret - jagatud saladus

**Oluline:** Kõik teenused (User Service, Todo Service jne) peavad kasutama **SAMA JWT_SECRET** võtit!

**Miks?**
- User Service allkirjastab JWT tokeni `JWT_SECRET` võtmega
- Todo Service kontrollib tokeni **SAMA** `JWT_SECRET` võtmega
- Kui võtmed erinevad, token ei kehti! ❌

**Näide:**

```bash
# ÕIGE: Mõlemad teenused kasutavad SAMA võtit
JWT_SECRET="minu-super-turvaline-secret-12345"

# User Service kasutab: JWT_SECRET="minu-super-turvaline-secret-12345"
# Todo Service kasutab: JWT_SECRET="minu-super-turvaline-secret-12345"
# ✅ Token töötab!

# VALE: Erinevad võtmed
# User Service kasutab: JWT_SECRET="secret-A"
# Todo Service kasutab: JWT_SECRET="secret-B"
# ❌ Token EI tööta!
```

**Genereeri turvaline secret:**

```bash
# Linuxis/macOS
openssl rand -base64 32

# Tulemus: juhuslik 32-tähemärgiline string
# Näide: "xK7mP9vL2nQ8wR5tY6uI0oP3jH4kF1gS2dA9bN7cM5v="
```

**Kuidas seda laborites kasutatakse:**
- **Lab 1:** User Service konteiner hangub (PostgreSQL puudub, JWT-d ei saa testida)
- **Lab 2:** Lisame PostgreSQL + jagatud JWT_SECRET → töötav süsteem!
- **Lab 3+:** Kasutame Kubernetes Secrets JWT_SECRET salvestamiseks

---

**Valmis DevOps harjutusteks! 🚀**
