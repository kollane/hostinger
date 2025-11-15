# Peatükk 7: REST API Disain ja Realiseerimine

**Kestus:** 4 tundi
**Eeldused:** Peatükid 1-6 läbitud
**Eesmärk:** Muuta API professionaalseks - pagination, filtering, dokumentatsioon, turvalisus ja testimine

---

## Sisukord

1. [RESTful API Disainipõhimõtted](#1-restful-api-disainipõhimõtted)
2. [HTTP Status Koodid](#2-http-status-koodid)
3. [API Versioneerimine](#3-api-versioneerimine)
4. [Pagination](#4-pagination)
5. [Filtering ja Sorting](#5-filtering-ja-sorting)
6. [Search Funktsioon](#6-search-funktsioon)
7. [Input Validation](#7-input-validation)
8. [CORS Seadistamine](#8-cors-seadistamine)
9. [Rate Limiting](#9-rate-limiting)
10. [Security Headers (Helmet)](#10-security-headers-helmet)
11. [API Dokumentatsioon (Swagger)](#11-api-dokumentatsioon-swagger)
12. [API Testimine](#12-api-testimine)
13. [Harjutused](#13-harjutused)
14. [Kontrolliküsimused](#14-kontrolliküsimused)
15. [Lisamaterjalid](#15-lisamaterjalid)

---

## 1. RESTful API Disainipõhimõtted

### 1.1. REST Põhimõisted

**REST (Representational State Transfer)** on arhitektuuristiil, mitte protokoll.

**6 põhiprintsiipa:**
1. **Client-Server** - Eraldi klient ja server
2. **Stateless** - Iga request on sõltumatu
3. **Cacheable** - Response'id võivad olla cache-itavad
4. **Uniform Interface** - Standardne liides
5. **Layered System** - Kihid (load balancer, cache, jne)
6. **Code on Demand** (optional) - Server saab saata koodi kliendile

---

### 1.2. Resource-Oriented Design

**Resource** on keskne kontseptsioon REST-is.

#### Ressursid vs Tegevused

❌ **VALE (RPC-stiil):**
```
POST /api/createUser
POST /api/deleteUser
GET /api/getUserById?id=1
POST /api/updateUserEmail
```

✅ **ÕIGE (REST-stiil):**
```
POST   /api/users          # Loo kasutaja
DELETE /api/users/1        # Kustuta kasutaja
GET    /api/users/1        # Loe kasutaja
PATCH  /api/users/1        # Uuenda kasutaja
```

---

### 1.3. URL Struktuur

**Best practices:**

✅ **Kasuta nimisõnu (plural):**
```
/users           ← Õige
/user            ← Vale
/getUsers        ← Vale (verb in URL)
```

✅ **Hierarhia suhetele:**
```
/users/1/posts           # Kasutaja 1 postitused
/users/1/posts/5         # Kasutaja 1 postitus 5
/posts/5/comments        # Postituse 5 kommentaarid
```

✅ **Lowercase ja kriipsud:**
```
/user-profiles           ← Õige
/userProfiles            ← Vale (camelCase)
/user_profiles           ← OK, aga kriipsud on paremad
```

✅ **Väldi file extensions:**
```
/users/1                 ← Õige
/users/1.json            ← Vale
```

---

### 1.4. HTTP Meetodid Õigesti

| Meetod | CRUD | Idempotent? | Safe? | Kasutus |
|--------|------|-------------|-------|---------|
| GET | Read | ✅ Jah | ✅ Jah | Loe ressursse (ei muuda) |
| POST | Create | ❌ Ei | ❌ Ei | Loo uus ressurss |
| PUT | Update | ✅ Jah | ❌ Ei | Täielik asendamine |
| PATCH | Update | ❌ Ei | ❌ Ei | Osaline uuendamine |
| DELETE | Delete | ✅ Jah | ❌ Ei | Kustuta ressurss |

**Idempotent** = Sama request mitu korda annab sama tulemuse

---

### 1.5. Request/Response Patterns

#### GET - Loe ressursid
```javascript
// GET /api/users
{
  "success": true,
  "count": 25,
  "data": [
    { "id": 1, "name": "Alice", "email": "alice@example.com" },
    { "id": 2, "name": "Bob", "email": "bob@example.com" }
  ]
}
```

#### POST - Loo ressurss
```javascript
// POST /api/users
// Request body:
{
  "name": "Charlie",
  "email": "charlie@example.com"
}

// Response: 201 Created
{
  "success": true,
  "data": {
    "id": 3,
    "name": "Charlie",
    "email": "charlie@example.com",
    "created_at": "2024-11-15T10:30:00Z"
  }
}
```

#### PUT vs PATCH
```javascript
// PUT /api/users/1 - Täielik asendamine
{
  "name": "Alice Updated",
  "email": "alice.new@example.com"
  // Kõik väljad peavad olema!
}

// PATCH /api/users/1 - Osaline uuendamine
{
  "email": "alice.new@example.com"
  // Ainult muudetavad väljad
}
```

#### DELETE - Kustuta
```javascript
// DELETE /api/users/1
// Response: 200 OK või 204 No Content
{
  "success": true,
  "message": "Kasutaja kustutatud"
}
```

---

## 2. HTTP Status Koodid

### 2.1. Status Koodide Kategooriad

- **1xx** - Informational (harva kasutatav)
- **2xx** - Success
- **3xx** - Redirection
- **4xx** - Client Error
- **5xx** - Server Error

---

### 2.2. Levinud Status Koodid

#### 2xx Success

| Kood | Nimi | Kasutus |
|------|------|---------|
| 200 | OK | Üldine edu (GET, PUT, PATCH) |
| 201 | Created | Ressurss loodud (POST) |
| 204 | No Content | Edu, aga ei tagasta body't (DELETE) |

#### 4xx Client Errors

| Kood | Nimi | Kasutus |
|------|------|---------|
| 400 | Bad Request | Vigane request (validation error) |
| 401 | Unauthorized | Autentimine nõutud |
| 403 | Forbidden | Autenditud, aga pole õigusi |
| 404 | Not Found | Ressurssi ei leitud |
| 409 | Conflict | Konflikt (duplicate email) |
| 422 | Unprocessable Entity | Validation error (alternatiiv 400-le) |
| 429 | Too Many Requests | Rate limit exceeded |

#### 5xx Server Errors

| Kood | Nimi | Kasutus |
|------|------|---------|
| 500 | Internal Server Error | Üldine serveri viga |
| 503 | Service Unavailable | Teenus ajutiselt kättesaamatu |

---

### 2.3. Status Koodide Kasutamine

**routes/users.js:**
```javascript
// 200 OK - edukad GET, PUT, PATCH
app.get('/api/users', async (req, res) => {
  const users = await pool.query('SELECT * FROM users');
  res.status(200).json({ success: true, data: users.rows });
});

// 201 Created - edukas POST
app.post('/api/users', async (req, res) => {
  const result = await pool.query('INSERT INTO users ...');
  res.status(201).json({ success: true, data: result.rows[0] });
});

// 204 No Content - edukas DELETE (ilma body'ta)
app.delete('/api/users/:id', async (req, res) => {
  await pool.query('DELETE FROM users WHERE id = $1', [req.params.id]);
  res.sendStatus(204); // Ei tagasta JSON-i
});

// 400 Bad Request - validation error
app.post('/api/users', async (req, res) => {
  if (!req.body.email) {
    return res.status(400).json({
      success: false,
      error: 'Email on kohustuslik'
    });
  }
});

// 404 Not Found - ressurssi ei leitud
app.get('/api/users/:id', async (req, res) => {
  const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
  if (result.rowCount === 0) {
    return res.status(404).json({
      success: false,
      error: 'Kasutajat ei leitud'
    });
  }
});

// 409 Conflict - duplicate
app.post('/api/users', async (req, res) => {
  try {
    // INSERT ...
  } catch (error) {
    if (error.code === '23505') { // Unique constraint
      return res.status(409).json({
        success: false,
        error: 'Email on juba kasutuses'
      });
    }
  }
});

// 500 Internal Server Error - serveri viga
app.get('/api/users', async (req, res) => {
  try {
    // ...
  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      error: 'Serveri viga'
    });
  }
});
```

---

## 3. API Versioneerimine

### 3.1. Miks Versioneerida?

**Probleem:** API muutub aja jooksul
- Uued väljad
- Eemaldatud väljad
- Struktuuri muudatused
- Breaking changes

**Lahendus:** Versiooni API, et vanad kliendid töötaksid edasi.

---

### 3.2. Versioneerimise Meetodid

#### Meetod 1: URL Path (SOOVITAV)

```javascript
// v1
app.use('/api/v1/users', usersRouterV1);

// v2 (uued funktsioonid)
app.use('/api/v2/users', usersRouterV2);
```

**Eelised:**
- ✅ Selge ja lihtne
- ✅ Kerge cache'ida
- ✅ Kerge testida

**Puudused:**
- ⚠️ URL muutub

---

#### Meetod 2: Query Parameter

```
GET /api/users?version=1
GET /api/users?version=2
```

**Eelised:**
- ✅ URL jääb samaks

**Puudused:**
- ⚠️ Keerulisem cache'ida
- ⚠️ Vähem selge

---

#### Meetod 3: Header

```
GET /api/users
Accept: application/vnd.myapi.v1+json

GET /api/users
Accept: application/vnd.myapi.v2+json
```

**Eelised:**
- ✅ RESTful
- ✅ URL jääb samaks

**Puudused:**
- ⚠️ Keeruline kasutada brauseris
- ⚠️ Vähem intuitiivne

---

### 3.3. Versioneerimise Praktiline Näide

**Struktur:**
```
routes/
├── v1/
│   ├── users.js
│   └── posts.js
└── v2/
    ├── users.js
    └── posts.js
```

**index.js:**
```javascript
const express = require('express');
const app = express();

// V1 routes
const usersV1 = require('./routes/v1/users');
app.use('/api/v1/users', usersV1);

// V2 routes (uued funktsioonid)
const usersV2 = require('./routes/v2/users');
app.use('/api/v2/users', usersV2);

// Redirect vaikimisi uusimale versioonile
app.use('/api/users', usersV2);

app.listen(3000);
```

**routes/v1/users.js:**
```javascript
// Vana API (stabiilne)
router.get('/', async (req, res) => {
  const result = await pool.query('SELECT id, name, email FROM users');
  res.json({ data: result.rows }); // Vana formaat
});
```

**routes/v2/users.js:**
```javascript
// Uus API (täiustatud)
router.get('/', async (req, res) => {
  const result = await pool.query('SELECT id, name, email, created_at FROM users');
  res.json({
    success: true,
    count: result.rowCount,
    data: result.rows
  }); // Uus formaat
});
```

---

## 4. Pagination

### 4.1. Miks Pagination?

**Probleem:** Suur andmehulk
```sql
SELECT * FROM users; -- 1,000,000 kasutajat!
```

**Tagajärjed:**
- Aeglane päring
- Suur mälukasutus
- Aeglane võrk
- Halb kasutajakogemus

**Lahendus:** Pagination - tagasta lehekülgede kaupa.

---

### 4.2. Pagination Tüübid

#### Offset-based Pagination

**URL:**
```
GET /api/users?page=1&limit=10     # Lehekülg 1, 10 tulemust
GET /api/users?page=2&limit=10     # Lehekülg 2
```

**SQL:**
```sql
-- Lehekülg 1 (0-9)
SELECT * FROM users LIMIT 10 OFFSET 0;

-- Lehekülg 2 (10-19)
SELECT * FROM users LIMIT 10 OFFSET 10;

-- Lehekülg 3 (20-29)
SELECT * FROM users LIMIT 10 OFFSET 20;
```

**Eelised:**
- ✅ Lihtne
- ✅ Saad hüpata lehekülgede vahel

**Puudused:**
- ⚠️ Aeglane suurte offset'idega
- ⚠️ Andmete lisamisel leheküljed "nihe'b"

---

#### Cursor-based Pagination

**URL:**
```
GET /api/users?limit=10                      # Esimene lehekülg
GET /api/users?cursor=abc123&limit=10        # Järgmine lehekülg
```

**Eelised:**
- ✅ Kiire (kasutab indeksit)
- ✅ Stabiilne (ei "nihe")

**Puudused:**
- ⚠️ Ei saa hüpata lehekülgede vahel
- ⚠️ Keerulisem

---

### 4.3. Offset Pagination Rakendamine

**routes/users.js:**
```javascript
router.get('/', async (req, res, next) => {
  try {
    // Võta query params (vaikeväärtustega)
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;

    // Valideeri
    if (page < 1) {
      return res.status(400).json({
        success: false,
        error: 'Page peab olema >= 1'
      });
    }

    if (limit < 1 || limit > 100) {
      return res.status(400).json({
        success: false,
        error: 'Limit peab olema 1-100 vahel'
      });
    }

    // Arvuta offset
    const offset = (page - 1) * limit;

    // Päring koos pagination'iga
    const result = await pool.query(
      'SELECT id, name, email, created_at FROM users ORDER BY id LIMIT $1 OFFSET $2',
      [limit, offset]
    );

    // Leia kokku kasutajaid (pagination meta jaoks)
    const countResult = await pool.query('SELECT COUNT(*) FROM users');
    const totalCount = parseInt(countResult.rows[0].count);

    // Arvuta pagination meta
    const totalPages = Math.ceil(totalCount / limit);
    const hasNextPage = page < totalPages;
    const hasPrevPage = page > 1;

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages,
        hasNextPage,
        hasPrevPage,
        nextPage: hasNextPage ? page + 1 : null,
        prevPage: hasPrevPage ? page - 1 : null
      }
    });
  } catch (error) {
    next(error);
  }
});
```

**Testimine:**
```bash
# Lehekülg 1
curl "http://localhost:3000/api/users?page=1&limit=5"

# Response:
{
  "success": true,
  "data": [
    { "id": 1, "name": "Alice", ... },
    { "id": 2, "name": "Bob", ... },
    { "id": 3, "name": "Charlie", ... },
    { "id": 4, "name": "David", ... },
    { "id": 5, "name": "Eve", ... }
  ],
  "pagination": {
    "page": 1,
    "limit": 5,
    "totalCount": 25,
    "totalPages": 5,
    "hasNextPage": true,
    "hasPrevPage": false,
    "nextPage": 2,
    "prevPage": null
  }
}

# Lehekülg 2
curl "http://localhost:3000/api/users?page=2&limit=5"
```

---

### 4.4. Jõudluse Optimeerimine

**Probleem:** `COUNT(*)` on aeglane suurtel tabelitel.

**Lahendus 1:** Cache'i count
```javascript
// Redis cache
const cachedCount = await redis.get('users:count');
if (cachedCount) {
  totalCount = parseInt(cachedCount);
} else {
  const result = await pool.query('SELECT COUNT(*) FROM users');
  totalCount = parseInt(result.rows[0].count);
  await redis.setex('users:count', 300, totalCount); // Cache 5 min
}
```

**Lahendus 2:** Ligikaudne count (PostgreSQL)
```javascript
// Kiire, aga ligikaudne
const result = await pool.query(`
  SELECT reltuples::bigint AS estimate
  FROM pg_class
  WHERE relname = 'users'
`);
const totalCount = parseInt(result.rows[0].estimate);
```

**Lahendus 3:** Ära näita täpset count'i
```javascript
// Näita ainult "More results available"
const hasNextPage = result.rows.length === limit;
```

---

## 5. Filtering ja Sorting

### 5.1. Filtering (Filtreerimine)

**URL:**
```
GET /api/users?role=admin
GET /api/users?role=admin&status=active
GET /api/users?created_after=2024-01-01
```

**Rakendamine:**
```javascript
router.get('/', async (req, res, next) => {
  try {
    const { role, status, created_after } = req.query;

    // Build WHERE clause dünaamiliselt
    const whereClauses = [];
    const values = [];
    let paramCount = 1;

    if (role) {
      whereClauses.push(`role = $${paramCount++}`);
      values.push(role);
    }

    if (status) {
      whereClauses.push(`status = $${paramCount++}`);
      values.push(status);
    }

    if (created_after) {
      whereClauses.push(`created_at >= $${paramCount++}`);
      values.push(created_after);
    }

    // Build SQL query
    let query = 'SELECT * FROM users';
    if (whereClauses.length > 0) {
      query += ' WHERE ' + whereClauses.join(' AND ');
    }
    query += ' ORDER BY id';

    const result = await pool.query(query, values);

    res.json({
      success: true,
      count: result.rowCount,
      filters: { role, status, created_after },
      data: result.rows
    });
  } catch (error) {
    next(error);
  }
});
```

**Testi:**
```bash
curl "http://localhost:3000/api/users?role=admin"
curl "http://localhost:3000/api/users?role=admin&status=active"
```

---

### 5.2. Sorting (Sorteerimine)

**URL:**
```
GET /api/users?sort=name           # ASC (vaikimisi)
GET /api/users?sort=-name          # DESC (miinus = DESC)
GET /api/users?sort=name,-created  # Mitu välja
```

**Rakendamine:**
```javascript
router.get('/', async (req, res, next) => {
  try {
    const { sort } = req.query;

    // Allowed sort fields (whitelist!)
    const allowedSortFields = ['id', 'name', 'email', 'created_at'];

    // Parse sort parameter
    let orderBy = 'id ASC'; // Vaikimisi

    if (sort) {
      const sortFields = sort.split(',').map(field => {
        const direction = field.startsWith('-') ? 'DESC' : 'ASC';
        const fieldName = field.replace(/^-/, '');

        // Valideeri field name (SQL injection kaitse!)
        if (!allowedSortFields.includes(fieldName)) {
          throw new Error(`Invalid sort field: ${fieldName}`);
        }

        return `${fieldName} ${direction}`;
      });

      orderBy = sortFields.join(', ');
    }

    // SQL query
    const query = `SELECT * FROM users ORDER BY ${orderBy}`;
    const result = await pool.query(query);

    res.json({
      success: true,
      sort: req.query.sort || 'default',
      data: result.rows
    });
  } catch (error) {
    if (error.message.includes('Invalid sort field')) {
      return res.status(400).json({
        success: false,
        error: error.message
      });
    }
    next(error);
  }
});
```

**Testi:**
```bash
curl "http://localhost:3000/api/users?sort=name"           # ASC
curl "http://localhost:3000/api/users?sort=-created_at"    # DESC
curl "http://localhost:3000/api/users?sort=role,-name"     # Multi
```

---

### 5.3. Filtering + Sorting + Pagination

**Kombineeritud näide:**

```javascript
router.get('/', async (req, res, next) => {
  try {
    // Pagination
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    // Filtering
    const { role, status } = req.query;
    const whereClauses = [];
    const values = [];
    let paramCount = 1;

    if (role) {
      whereClauses.push(`role = $${paramCount++}`);
      values.push(role);
    }

    if (status) {
      whereClauses.push(`status = $${paramCount++}`);
      values.push(status);
    }

    // Sorting
    const allowedSortFields = ['id', 'name', 'email', 'created_at'];
    let orderBy = 'id ASC';

    if (req.query.sort) {
      const sortField = req.query.sort.replace(/^-/, '');
      if (!allowedSortFields.includes(sortField)) {
        return res.status(400).json({
          success: false,
          error: `Invalid sort field: ${sortField}`
        });
      }
      const direction = req.query.sort.startsWith('-') ? 'DESC' : 'ASC';
      orderBy = `${sortField} ${direction}`;
    }

    // Build query
    let query = 'SELECT * FROM users';
    if (whereClauses.length > 0) {
      query += ' WHERE ' + whereClauses.join(' AND ');
    }
    query += ` ORDER BY ${orderBy}`;
    query += ` LIMIT $${paramCount++} OFFSET $${paramCount++}`;

    values.push(limit, offset);

    // Execute
    const result = await pool.query(query, values);

    // Count (sama WHERE clause)
    let countQuery = 'SELECT COUNT(*) FROM users';
    if (whereClauses.length > 0) {
      countQuery += ' WHERE ' + whereClauses.join(' AND ');
    }
    const countResult = await pool.query(countQuery, values.slice(0, -2));
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages: Math.ceil(totalCount / limit)
      },
      filters: { role, status },
      sort: req.query.sort || 'default'
    });
  } catch (error) {
    next(error);
  }
});
```

**Testi:**
```bash
curl "http://localhost:3000/api/users?role=admin&sort=-created_at&page=1&limit=5"
```

---

## 6. Search Funktsioon

### 6.1. Lihtne Search (LIKE)

**URL:**
```
GET /api/users?search=alice
```

**Rakendamine:**
```javascript
router.get('/', async (req, res, next) => {
  try {
    const { search } = req.query;

    let query = 'SELECT * FROM users';
    const values = [];

    if (search) {
      query += ' WHERE name ILIKE $1 OR email ILIKE $1';
      values.push(`%${search}%`);
    }

    const result = await pool.query(query, values);

    res.json({
      success: true,
      search: search || null,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    next(error);
  }
});
```

**Testi:**
```bash
curl "http://localhost:3000/api/users?search=alice"
```

---

### 6.2. Full-Text Search (PostgreSQL)

**Loo full-text search index:**
```sql
-- Lisa tsvector column
ALTER TABLE users ADD COLUMN search_vector tsvector;

-- Uuenda search_vector
UPDATE users SET search_vector =
  to_tsvector('english', name || ' ' || email);

-- Loo index
CREATE INDEX idx_users_search ON users USING GIN(search_vector);

-- Trigger auto-update'ks
CREATE OR REPLACE FUNCTION users_search_trigger() RETURNS trigger AS $$
BEGIN
  NEW.search_vector := to_tsvector('english', NEW.name || ' ' || NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_search_update
BEFORE INSERT OR UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION users_search_trigger();
```

**API:**
```javascript
router.get('/search', async (req, res, next) => {
  try {
    const { q } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        error: 'Search query (q) is required'
      });
    }

    const result = await pool.query(`
      SELECT id, name, email,
             ts_rank(search_vector, query) AS rank
      FROM users,
           to_tsquery('english', $1) query
      WHERE search_vector @@ query
      ORDER BY rank DESC
      LIMIT 20
    `, [q.split(' ').join(' & ')]);

    res.json({
      success: true,
      query: q,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    next(error);
  }
});
```

**Testi:**
```bash
curl "http://localhost:3000/api/users/search?q=alice"
```

---

## 7. Input Validation

### 7.1. Miks Valideerida?

**Ohud ilma valideerimiseta:**
- SQL injection
- XSS (Cross-Site Scripting)
- Buffer overflow
- Business logic errors

---

### 7.2. Validator Teek

**Paigalda express-validator:**
```bash
npm install express-validator
```

**Kasutamine:**
```javascript
const { body, query, param, validationResult } = require('express-validator');

// POST /api/users - Loo kasutaja
router.post('/',
  // Validation rules
  [
    body('name')
      .trim()
      .notEmpty().withMessage('Nimi on kohustuslik')
      .isLength({ min: 2, max: 100 }).withMessage('Nimi peab olema 2-100 tähemärki'),

    body('email')
      .trim()
      .notEmpty().withMessage('Email on kohustuslik')
      .isEmail().withMessage('Vigane email formaat')
      .normalizeEmail(),

    body('password')
      .notEmpty().withMessage('Parool on kohustuslik')
      .isLength({ min: 8 }).withMessage('Parool peab olema vähemalt 8 tähemärki')
      .matches(/\d/).withMessage('Parool peab sisaldama numbrit')
      .matches(/[A-Z]/).withMessage('Parool peab sisaldama suurt tähte')
  ],

  // Handler
  async (req, res, next) => {
    // Kontrolli vigu
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    try {
      const { name, email, password } = req.body;
      // ... insert to DB
    } catch (error) {
      next(error);
    }
  }
);
```

**Testi:**
```bash
# Vale email
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"notanemail","password":"short"}'

# Response:
{
  "success": false,
  "errors": [
    {
      "msg": "Vigane email formaat",
      "param": "email",
      "location": "body"
    },
    {
      "msg": "Parool peab olema vähemalt 8 tähemärki",
      "param": "password",
      "location": "body"
    }
  ]
}
```

---

### 7.3. Validation Middleware

**Loo taaskasuttatav middleware:**

**middleware/validate.js:**
```javascript
const { validationResult } = require('express-validator');

function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array().map(err => ({
        field: err.param,
        message: err.msg
      }))
    });
  }
  next();
}

module.exports = validate;
```

**Kasutamine:**
```javascript
const validate = require('../middleware/validate');
const { body } = require('express-validator');

router.post('/',
  [
    body('name').trim().notEmpty().isLength({ min: 2, max: 100 }),
    body('email').trim().isEmail().normalizeEmail()
  ],
  validate, // ⬅️ Middleware
  async (req, res, next) => {
    // Kui jõuame siia, on andmed valideeritud
    const { name, email } = req.body;
    // ...
  }
);
```

---

## 8. CORS Seadistamine

### 8.1. Mis on CORS?

**CORS (Cross-Origin Resource Sharing)** kontrollib, millised domeenid saavad API-ga suhelda.

**Probleem:**
```
Frontend:  http://myapp.com
API:       http://api.myapp.com

Browser blokeerib päringu! (Same-Origin Policy)
```

**Lahendus:** CORS headers

---

### 8.2. CORS Paigaldamine

```bash
npm install cors
```

**Lihtne kasutamine (luba kõik):**
```javascript
const cors = require('cors');

app.use(cors()); // ⚠️ AINULT DEVELOPMENT!
```

---

### 8.3. CORS Konfiguratsioon (Production)

```javascript
const cors = require('cors');

const corsOptions = {
  origin: function (origin, callback) {
    const allowedOrigins = [
      'http://localhost:3000',
      'https://myapp.com',
      'https://www.myapp.com'
    ];

    // Luba no-origin (Postman, mobile apps)
    if (!origin) return callback(null, true);

    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true, // Luba cookies
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
```

---

### 8.4. Keskkonnapõhine CORS

```javascript
const corsOptions = {
  origin: process.env.NODE_ENV === 'production'
    ? ['https://myapp.com', 'https://www.myapp.com']
    : true, // Development: luba kõik
  credentials: true
};

app.use(cors(corsOptions));
```

---

## 9. Rate Limiting

### 9.1. Miks Rate Limiting?

**Kaitse:**
- DDoS rünnakud
- Brute-force rünnakud
- API abuse
- Ressursside raiskamine

---

### 9.2. Rate Limiting Paigaldamine

```bash
npm install express-rate-limit
```

**Kasutamine:**
```javascript
const rateLimit = require('express-rate-limit');

// Üldine rate limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutit
  max: 100, // Max 100 requestit per window
  message: {
    success: false,
    error: 'Liiga palju päringuid, proovi hiljem uuesti'
  },
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false,
});

// Rakenda kõigile route'dele
app.use('/api/', limiter);
```

---

### 9.3. Eri Limitid Eri Endpoint'idele

```javascript
// Login limiter (range)
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 5, // Max 5 login katset
  skipSuccessfulRequests: true, // Ära loe edukat login
  message: {
    success: false,
    error: 'Liiga palju login katseid. Proovi 15 minuti pärast uuesti.'
  }
});

// Registration limiter
const registerLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 tund
  max: 3, // Max 3 registreerimist
  message: {
    success: false,
    error: 'Liiga palju registreerimise katseid'
  }
});

// Rakenda
app.post('/api/auth/login', loginLimiter, loginController);
app.post('/api/auth/register', registerLimiter, registerController);
```

---

### 9.4. Redis Store (Production)

**Probleemikoht:** In-memory store ei tööta mitme serveri korral.

**Lahendus:** Redis

```bash
npm install rate-limit-redis redis
```

```javascript
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const redis = require('redis');

const redisClient = redis.createClient({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT
});

const limiter = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rate-limit:'
  }),
  windowMs: 15 * 60 * 1000,
  max: 100
});

app.use('/api/', limiter);
```

---

## 10. Security Headers (Helmet)

### 10.1. Mis on Helmet?

**Helmet** seadistab turvalisuse HTTP header'id automaatselt.

---

### 10.2. Paigaldamine

```bash
npm install helmet
```

**Kasutamine:**
```javascript
const helmet = require('helmet');

app.use(helmet()); // Rakenda kõik turvalisuse header'id
```

---

### 10.3. Helmet Seadistamine

```javascript
app.use(helmet({
  // Content Security Policy
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"]
    }
  },

  // Hide X-Powered-By
  hidePoweredBy: true,

  // HSTS (HTTP Strict Transport Security)
  hsts: {
    maxAge: 31536000, // 1 aasta
    includeSubDomains: true,
    preload: true
  }
}));
```

---

### 10.4. Helmet Header'id

Helmet seadistab automaatselt:

- **X-DNS-Prefetch-Control** - Kontrolli DNS prefetching
- **X-Frame-Options** - Kaitse clickjacking vastu
- **X-Content-Type-Options** - MIME-type sniffing kaitse
- **X-XSS-Protection** - XSS filter
- **Strict-Transport-Security** - Sunni HTTPS
- **Content-Security-Policy** - XSS ja injection kaitse

---

## 11. API Dokumentatsioon (Swagger)

### 11.1. Miks Dokumenteerida?

**Probleemid ilma dokumentatsioonita:**
- Kliendid ei tea, kuidas API-d kasutada
- Arendajad unustan API struktuuri
- Testimine on keeruline
- Integration on aeglane

**Lahendus:** Swagger/OpenAPI - interaktiivne API dokumentatsioon

---

### 11.2. Swagger Paigaldamine

```bash
npm install swagger-ui-express swagger-jsdoc
```

---

### 11.3. Swagger Seadistamine

**swagger.js:**
```javascript
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Users API',
      version: '1.0.0',
      description: 'PostgreSQL-põhine REST API kasutajate haldamiseks',
      contact: {
        name: 'API Support',
        email: 'support@example.com'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development server'
      },
      {
        url: 'https://api.example.com',
        description: 'Production server'
      }
    ]
  },
  apis: ['./routes/*.js'] // Failid, kus on Swagger kommentaarid
};

const specs = swaggerJsdoc(options);

module.exports = { specs, swaggerUi };
```

**index.js:**
```javascript
const { specs, swaggerUi } = require('./swagger');

// Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

console.log('📚 API docs: http://localhost:3000/api-docs');
```

---

### 11.4. Swagger Kommentaarid

**routes/users.js:**
```javascript
/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - name
 *         - email
 *       properties:
 *         id:
 *           type: integer
 *           description: Kasutaja ID
 *         name:
 *           type: string
 *           description: Kasutaja nimi
 *         email:
 *           type: string
 *           format: email
 *           description: Kasutaja email
 *         created_at:
 *           type: string
 *           format: date-time
 *           description: Loomise aeg
 *       example:
 *         id: 1
 *         name: Alice
 *         email: alice@example.com
 *         created_at: 2024-11-15T10:30:00Z
 */

/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Loe kõik kasutajad
 *     tags: [Users]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Lehekülg
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Tulemuste arv lehel
 *       - in: query
 *         name: sort
 *         schema:
 *           type: string
 *         description: Sorteerimine (nt. name, -created_at)
 *     responses:
 *       200:
 *         description: Edukas päring
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                     limit:
 *                       type: integer
 *                     totalCount:
 *                       type: integer
 */
router.get('/', async (req, res) => {
  // ...
});

/**
 * @swagger
 * /api/users:
 *   post:
 *     summary: Loo uus kasutaja
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *             properties:
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 format: password
 *     responses:
 *       201:
 *         description: Kasutaja loodud
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       400:
 *         description: Validation error
 *       409:
 *         description: Email on juba kasutuses
 */
router.post('/', async (req, res) => {
  // ...
});
```

**Testi:** Ava brauser: http://localhost:3000/api-docs

---

## 12. API Testimine

### 12.1. Miks Testida?

**Eelised:**
- ✅ Catch bugs varakult
- ✅ Refactoring confidence
- ✅ Dokumentatsioon (testid näitavad, kuidas API töötab)
- ✅ Regression testing

---

### 12.2. Jest ja Supertest

**Paigalda:**
```bash
npm install --save-dev jest supertest
```

**package.json:**
```json
{
  "scripts": {
    "test": "jest --verbose",
    "test:watch": "jest --watch"
  },
  "jest": {
    "testEnvironment": "node",
    "coveragePathIgnorePatterns": ["/node_modules/"]
  }
}
```

---

### 12.3. Esimene Test

**tests/users.test.js:**
```javascript
const request = require('supertest');
const app = require('../index'); // Export app from index.js

describe('Users API', () => {
  describe('GET /api/users', () => {
    it('peaks tagastama kõik kasutajad', async () => {
      const res = await request(app).get('/api/users');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('peaks toetama pagination', async () => {
      const res = await request(app)
        .get('/api/users')
        .query({ page: 1, limit: 5 });

      expect(res.status).toBe(200);
      expect(res.body.pagination).toBeDefined();
      expect(res.body.pagination.page).toBe(1);
      expect(res.body.pagination.limit).toBe(5);
    });
  });

  describe('GET /api/users/:id', () => {
    it('peaks tagastama kasutaja ID järgi', async () => {
      const res = await request(app).get('/api/users/1');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(1);
    });

    it('peaks tagastama 404, kui kasutajat ei leitud', async () => {
      const res = await request(app).get('/api/users/99999');

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });
  });

  describe('POST /api/users', () => {
    it('peaks looma uue kasutaja', async () => {
      const newUser = {
        name: 'Test User',
        email: `test${Date.now()}@example.com`, // Unique email
        password: 'Password123'
      };

      const res = await request(app)
        .post('/api/users')
        .send(newUser);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe(newUser.name);
      expect(res.body.data.email).toBe(newUser.email);
    });

    it('peaks tagastama 400, kui email puudub', async () => {
      const res = await request(app)
        .post('/api/users')
        .send({ name: 'Test', password: 'Password123' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('peaks tagastama 409, kui email on duplikaat', async () => {
      const user = {
        name: 'Test',
        email: 'duplicate@example.com',
        password: 'Password123'
      };

      // Loo esimene
      await request(app).post('/api/users').send(user);

      // Proovi uuesti (duplikaat)
      const res = await request(app).post('/api/users').send(user);

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
    });
  });
});
```

---

### 12.4. Käivita Testid

```bash
npm test

# Output:
# PASS  tests/users.test.js
#   Users API
#     GET /api/users
#       ✓ peaks tagastama kõik kasutajad (45ms)
#       ✓ peaks toetama pagination (23ms)
#     GET /api/users/:id
#       ✓ peaks tagastama kasutaja ID järgi (18ms)
#       ✓ peaks tagastama 404, kui kasutajat ei leitud (12ms)
#     POST /api/users
#       ✓ peaks looma uue kasutaja (67ms)
#       ✓ peaks tagastama 400, kui email puudub (15ms)
#       ✓ peaks tagastama 409, kui email on duplikaat (45ms)
#
# Test Suites: 1 passed, 1 total
# Tests:       7 passed, 7 total
```

---

### 12.5. Test Database

**Probleem:** Testid muudavad production andmebaasi!

**Lahendus:** Test database

**.env.test:**
```
DATABASE_URL=postgresql://appuser:password@localhost:5432/appdb_test
```

**package.json:**
```json
{
  "scripts": {
    "test": "NODE_ENV=test jest --verbose"
  }
}
```

**db.js:**
```javascript
const pool = new Pool({
  connectionString: process.env.NODE_ENV === 'test'
    ? process.env.TEST_DATABASE_URL
    : process.env.DATABASE_URL
});
```

**Test setup/teardown:**
```javascript
// tests/setup.js
beforeAll(async () => {
  // Loo test andmebaas
  await pool.query('CREATE TABLE IF NOT EXISTS users (...)');
});

afterAll(async () => {
  // Puhasta
  await pool.query('TRUNCATE TABLE users CASCADE');
  await pool.end();
});
```

---

## 13. Harjutused

### Harjutus 7.1: Pagination

**Eesmärk:** Lisa pagination users endpoint'ile

**Sammud:**
1. Muuda GET /api/users endpoint'i
2. Lisa query params: page, limit
3. Tagasta pagination meta
4. Testi Postman'iga

---

### Harjutus 7.2: Filtering ja Sorting

**Eesmärk:** Lisa filtering ja sorting

**Sammud:**
1. Lisa filter query params (role, status)
2. Lisa sort query param
3. Kombineeri filtering, sorting, pagination
4. Testi: `?role=admin&sort=-created_at&page=1`

---

### Harjutus 7.3: Input Validation

**Eesmärk:** Valideeri kasutaja sisend

**Sammud:**
1. Paigalda express-validator
2. Lisa validation POST /api/users endpoint'ile
3. Valideeri: name (min 2), email (valid), password (min 8)
4. Testi vigaste andmetega

---

### Harjutus 7.4: CORS ja Security

**Eesmärk:** Seadista CORS ja Helmet

**Sammud:**
1. Paigalda cors ja helmet
2. Seadista CORS allowed origins
3. Rakenda helmet
4. Testi CORS brauserist

---

### Harjutus 7.5: Rate Limiting

**Eesmärk:** Kaitse API rate limiting'uga

**Sammud:**
1. Paigalda express-rate-limit
2. Seadista limiter: 100 requests / 15 min
3. Testi: tee 101 päringut kiiresti
4. Kontrolli, et saad 429 vastuse

---

### Harjutus 7.6: Swagger Dokumentatsioon

**Eesmärk:** Loo API dokumentatsioon

**Sammud:**
1. Paigalda swagger-ui-express ja swagger-jsdoc
2. Seadista Swagger
3. Lisa Swagger kommentaarid 2 endpoint'ile
4. Ava http://localhost:3000/api-docs

---

### Harjutus 7.7: API Testimine

**Eesmärk:** Kirjuta testid

**Sammud:**
1. Paigalda jest ja supertest
2. Loo tests/users.test.js
3. Kirjuta 5 testi (GET, POST, validation)
4. Käivita: npm test

---

## 14. Kontrolliküsimused

### Teoreetilised Küsimused

1. **Mis on REST ja millised on selle põhiprintsiibid?**
   <details>
   <summary>Vastus</summary>
   REST (Representational State Transfer) on arhitektuuristiil. Põhiprintsiibid: Client-Server, Stateless, Cacheable, Uniform Interface, Layered System, Code on Demand (optional).
   </details>

2. **Mis vahe on PUT ja PATCH meetodil?**
   <details>
   <summary>Vastus</summary>
   PUT: täielik ressursi asendamine (kõik väljad). PATCH: osaline uuendamine (ainult antud väljad). PUT on idempotent, PATCH ei ole alati.
   </details>

3. **Miks on pagination oluline?**
   <details>
   <summary>Vastus</summary>
   Pagination hoiab ära suure andmehulga korraga saatmise, mis aeglustab päringut, kasutab palju mälu ja võrguressurssi, ning halvendab kasutajakogemust.
   </details>

4. **Mis on CORS ja miks on see vajalik?**
   <details>
   <summary>Vastus</summary>
   CORS (Cross-Origin Resource Sharing) võimaldab serveril määrata, millised domeenid saavad API-ga suhelda. Vajalik, sest brauserid blokeerivad vaikimisi cross-origin päringud (Same-Origin Policy).
   </details>

5. **Mis on rate limiting ja miks seda kasutada?**
   <details>
   <summary>Vastus</summary>
   Rate limiting piirab päringute arvu ajaühiku kohta. Kaitse DDoS, brute-force, API abuse ja ressursside raiskamise vastu.
   </details>

---

### Praktilised Küsimused

6. **Kuidas lisada pagination query params?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   const page = parseInt(req.query.page) || 1;
   const limit = parseInt(req.query.limit) || 10;
   const offset = (page - 1) * limit;

   await pool.query('SELECT * FROM users LIMIT $1 OFFSET $2', [limit, offset]);
   ```
   </details>

7. **Kuidas valideerida email express-validator'iga?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   const { body } = require('express-validator');

   body('email')
     .trim()
     .notEmpty().withMessage('Email on kohustuslik')
     .isEmail().withMessage('Vigane email formaat')
     .normalizeEmail()
   ```
   </details>

8. **Kuidas seadistada CORS konkreetsete domeenide jaoks?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   const cors = require('cors');

   app.use(cors({
     origin: ['https://myapp.com', 'https://www.myapp.com'],
     credentials: true
   }));
   ```
   </details>

9. **Kuidas lisada rate limiting?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   const rateLimit = require('express-rate-limit');

   const limiter = rateLimit({
     windowMs: 15 * 60 * 1000,
     max: 100
   });

   app.use('/api/', limiter);
   ```
   </details>

10. **Kuidas kirjutada Supertest test?**
    <details>
    <summary>Vastus</summary>
    ```javascript
    const request = require('supertest');
    const app = require('../index');

    it('peaks tagastama kasutajad', async () => {
      const res = await request(app).get('/api/users');
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
    ```
    </details>

---

## 15. Lisamaterjalid

### 📚 Soovitatud Lugemine

#### REST API Design
- [REST API Tutorial](https://restfulapi.net/)
- [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines)
- [Google API Design Guide](https://cloud.google.com/apis/design)
- [Best Practices for REST API Design](https://stackoverflow.blog/2020/03/02/best-practices-for-rest-api-design/)

#### Security
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [Express.js Security Best Practices](https://expressjs.com/en/advanced/best-practice-security.html)
- [Node.js Security Checklist](https://blog.risingstack.com/node-js-security-checklist/)

#### Testing
- [Jest Documentation](https://jestjs.io/)
- [Supertest Documentation](https://github.com/visionmedia/supertest)

---

### 🛠️ Kasulikud Teegid

#### Validation
```bash
npm install joi              # Schema validation
npm install yup              # Schema validation
npm install validator        # String validators
```

#### Security
```bash
npm install express-mongo-sanitize  # Mongo injection kaitse
npm install xss-clean               # XSS kaitse
npm install hpp                     # HTTP Parameter Pollution kaitse
```

#### Documentation
```bash
npm install @apidevtools/swagger-parser  # Swagger validation
npm install redoc-express                # ReDoc (alternatiiv Swagger UI-le)
```

---

### 📖 HTTP Status Koodide Cheat Sheet

```
2xx Success
  200 OK              - GET, PUT, PATCH edu
  201 Created         - POST edu
  204 No Content      - DELETE edu (ilma body'ta)

4xx Client Errors
  400 Bad Request     - Validation error
  401 Unauthorized    - Autentimine nõutud
  403 Forbidden       - Pole õigusi
  404 Not Found       - Ressurss puudub
  409 Conflict        - Duplikaat, konflikt
  422 Unprocessable   - Validation error (alternatiiv)
  429 Too Many        - Rate limit

5xx Server Errors
  500 Internal        - Serveri viga
  503 Unavailable     - Teenus ajutiselt maas
```

---

## Kokkuvõte

Selles peatükis said:

✅ **Õppisid RESTful API disaini** - Resource-oriented, HTTP meetodid, status koodid
✅ **Lisasid API versioneerimise** - URL path, query, header meetodid
✅ **Rakendasi pagination** - Offset-based, performance optimizations
✅ **Lisasid filtering ja sorting** - Query params, SQL building
✅ **Lisasid search funktsiooni** - LIKE ja full-text search
✅ **Valideerisid input'i** - express-validator
✅ **Seadistasid CORS** - Cross-origin requests
✅ **Rakendası rate limiting** - DDoS kaitse
✅ **Lisasid security headers** - Helmet.js
✅ **Lõid API dokumentatsiooni** - Swagger/OpenAPI
✅ **Kirjutasid API teste** - Jest ja Supertest

---

## Järgmine Peatükk

**Peatükk 8: Autentimine ja Autoriseerimine**

Järgmises peatükis:
- JWT (JSON Web Tokens)
- Paroolide hasheerimine (bcrypt)
- Login ja Register endpoint'id
- Authentication middleware
- Authorization (role-based access control)
- Refresh tokens
- Password reset
- Email verification

**API muutub turvaliseks!** 🔐

---

## Troubleshooting

### Probleem 1: CORS error brauseris

**Sümptom:**
```
Access to fetch at 'http://localhost:3000/api/users' from origin 'http://localhost:8080'
has been blocked by CORS policy
```

**Lahendus:**
```javascript
const cors = require('cors');
app.use(cors({
  origin: 'http://localhost:8080',
  credentials: true
}));
```

---

### Probleem 2: Rate limiter ei tööta mitme serveri korral

**Sümptom:** Rate limit reset'ib, kui server restartib

**Lahendus:** Kasuta Redis store't
```javascript
const RedisStore = require('rate-limit-redis');
const limiter = rateLimit({
  store: new RedisStore({ client: redisClient })
});
```

---

### Probleem 3: Swagger ei näita route'sid

**Sümptom:** /api-docs on tühi

**Lahendus:** Kontrolli apis path'i
```javascript
const options = {
  apis: ['./routes/*.js'] // Kontrolli, et tee on õige
};
```

---

### Probleem 4: Testid failivad

**Sümptom:** Tests give "Connection refused"

**Lahendus:** Kasuta test DB'd
```javascript
// .env.test
TEST_DATABASE_URL=postgresql://...

// db.js
const connectionString = process.env.NODE_ENV === 'test'
  ? process.env.TEST_DATABASE_URL
  : process.env.DATABASE_URL;
```

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
**Järgmine uuendus:** Peatükk 8 lisamine
