# Peatükk 6: PostgreSQL Integratsioon Node.js-iga

**Kestus:** 4 tundi
**Eeldused:** Peatükid 1-5 läbitud
**Eesmärk:** Ühendada Express API PostgreSQL andmebaasiga ja luua päris andmebaasipõhine REST API

---

## Sisukord

1. [Ülevaade ja Plaan](#1-ülevaade-ja-plaan)
2. [node-postgres (pg) Teek](#2-node-postgres-pg-teek)
3. [PRIMAARNE: Docker PostgreSQL-iga](#3-primaarne-docker-postgresql-iga)
4. [ALTERNATIIV: Väline PostgreSQL](#4-alternatiiv-väline-postgresql)
5. [Connection Pooling](#5-connection-pooling)
6. [Andmebaasi Päringud](#6-andmebaasi-päringud)
7. [SQL Injection Kaitse](#7-sql-injection-kaitse)
8. [Transactions](#8-transactions)
9. [Error Handling](#9-error-handling)
10. [CRUD API PostgreSQL-iga](#10-crud-api-postgresql-iga)
11. [Harjutused](#11-harjutused)
12. [Kontrolliküsimused](#12-kontrolliküsimused)
13. [Lisamaterjalid](#13-lisamaterjalid)

---

## 1. Ülevaade ja Plaan

### 1.1. Mis Muutub?

**Peatükis 5** lõime REST API, mis kasutas **in-memory** andmeid:

```javascript
// ❌ In-memory (kaob restart'i korral)
let users = [
  { id: 1, name: 'Alice', email: 'alice@example.com' }
];
```

**Peatükis 6** asendame selle **PostgreSQL andmebaasiga**:

```javascript
// ✅ PostgreSQL (püsiv)
const result = await pool.query('SELECT * FROM users');
const users = result.rows;
```

---

### 1.2. Arhitektuur

#### Enne (Peatükk 5)
```
┌─────────────────────┐
│   Client (Browser)  │
│   Postman / cURL    │
└──────────┬──────────┘
           │ HTTP Request
           ▼
┌─────────────────────┐
│   Express API       │
│   (Node.js)         │
├─────────────────────┤
│   let users = [...] │  ◀─ In-memory (❌)
└─────────────────────┘
```

#### Pärast (Peatükk 6)
```
┌─────────────────────┐
│   Client (Browser)  │
│   Postman / cURL    │
└──────────┬──────────┘
           │ HTTP Request
           ▼
┌─────────────────────┐
│   Express API       │
│   (Node.js)         │
├─────────────────────┤
│   node-postgres (pg)│
└──────────┬──────────┘
           │ SQL Query
           ▼
┌─────────────────────┐
│   PostgreSQL DB     │  ◀─ Persistent (✅)
│   (Docker/Väline)   │
└─────────────────────┘
```

---

### 1.3. Mida Õpime?

✅ **node-postgres (pg)** teegi kasutamine
✅ **Connection pooling** - efektiivne ühenduste haldus
✅ **Parameetriseeritud päringud** - SQL injection kaitse
✅ **Error handling** - andmebaasi vigade käsitlemine
✅ **Transactions** - ACID compliance
✅ **CRUD API** - täisfunktsionaalne andmebaasipõhine API
✅ **Kahe variandi tugi** - Docker ja väline PostgreSQL

---

## 2. node-postgres (pg) Teek

### 2.1. Mis on node-postgres?

**node-postgres** (pakett `pg`) on kõige populaarsem PostgreSQL klient Node.js-ile.

**Omadused:**
✅ Pure JavaScript (ei vaja native dependencies)
✅ Connection pooling
✅ Promises ja async/await tugi
✅ Prepared statements
✅ Transaction support
✅ SSL/TLS tugi

**Alternatiivid:**
- **Knex.js** - SQL query builder
- **Sequelize** - ORM (Object-Relational Mapping)
- **Prisma** - Modern ORM
- **TypeORM** - TypeScript ORM

**Meie koolituses:** Kasutame **pg** (madalama taseme, parem SQL õppimiseks).

---

### 2.2. Paigaldamine

```bash
# Oled my-api kataloogis (Peatükk 5 projekt)
cd ~/projects/my-api

# Paigalda pg
npm install pg

# Kontrolli
cat package.json
```

**package.json:**
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1"
  }
}
```

---

### 2.3. pg API Ülevaade

**node-postgres** pakub kaks peamist viisi ühendamiseks:

#### Client (ühendus)
```javascript
const { Client } = require('pg');
const client = new Client({ connectionString: '...' });

await client.connect();
await client.query('SELECT * FROM users');
await client.end();
```

**Kasutus:** Lühiajalised skriptid, migratsioонid

---

#### Pool (ühenduste pool)
```javascript
const { Pool } = require('pg');
const pool = new Pool({ connectionString: '...' });

// Ühendused hallatakse automaatselt
await pool.query('SELECT * FROM users');
// Ei vaja .end() (pool jääb elavaks)
```

**Kasutus:** Web serverid, pikaajalised rakendused (⭐ **SOOVITAV**)

---

## 3. PRIMAARNE: Docker PostgreSQL-iga

### 3.1. Eeldused

Eeldame, et sul on **Peatükist 3** töötav Docker PostgreSQL:

```bash
# Kontrolli, kas PostgreSQL konteiner töötab
docker ps | grep postgres

# Väljund peaks olema:
# CONTAINER ID   IMAGE                PORTS                    NAMES
# a1b2c3d4e5f6   postgres:16-alpine   0.0.0.0:5432->5432/tcp   postgres-prod
```

**Kui ei tööta:**
```bash
# Käivita uuesti (Peatükk 3, sektsioon 4.3.2)
docker start postgres-prod

# VÕI loo uus:
docker run --name postgres-prod \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=StrongPassword123! \
  -e POSTGRES_DB=appdb \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  --restart unless-stopped \
  -d postgres:16-alpine
```

---

### 3.2. Connection String

**Connection string** on URI, mis sisaldab kõike ühenduse loomiseks:

```
postgresql://username:password@host:port/database
```

**Näide (Docker PostgreSQL):**
```
postgresql://appuser:StrongPassword123!@localhost:5432/appdb
```

**Komponentide selgitus:**
- `postgresql://` - Protokoll (postgres:// ka OK)
- `appuser` - Kasutajanimi
- `StrongPassword123!` - Parool
- `localhost` - Host (kuna Docker teeb port mapping)
- `5432` - Port
- `appdb` - Andmebaasi nimi

---

### 3.3. Environment Variables

**OLULINE:** Ei tohiks hardcode'ida paroole koodis!

**.env fail:**
```bash
# Redigeeri .env
nano .env
```

**Lisa:**
```env
# Server
PORT=3000
NODE_ENV=development

# PostgreSQL (Docker variant)
DATABASE_URL=postgresql://appuser:StrongPassword123!@localhost:5432/appdb

# VÕI komponendid eraldi:
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=StrongPassword123!
```

**Salvesta** ja **välju**.

---

### 3.4. Ühenduse Loomine (Pool)

**Loo fail db.js:**
```bash
nano db.js
```

**Lisa sisu:**
```javascript
// db.js
const { Pool } = require('pg');

// Loo connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,

  // Pool konfiguratsioon
  max: 20,                  // Maksimaalselt 20 ühendust pool'is
  idleTimeoutMillis: 30000, // Ühendus suletakse kui idle 30s
  connectionTimeoutMillis: 2000, // Timeout ühenduse loomisel
});

// Event listeners (kasulik debug'imiseks)
pool.on('connect', () => {
  console.log('✅ Ühendatud andmebaasiga');
});

pool.on('error', (err) => {
  console.error('❌ Ootamatu andmebaasi viga:', err);
  process.exit(-1);
});

// Export pool
module.exports = pool;
```

**Salvesta** ja **välju**.

---

### 3.5. Ühenduse Testimine

**Muuda index.js:**
```bash
nano index.js
```

**Lisa pärast require'dotenv':**
```javascript
// index.js
require('dotenv').config();
const express = require('express');
const pool = require('./db'); // ⬅️ LISA

const app = express();
app.use(express.json());

// Test route - kontrolli DB ühendust
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({
      success: true,
      time: result.rows[0].now,
      message: 'Andmebaas töötab!'
    });
  } catch (error) {
    console.error('DB viga:', error);
    res.status(500).json({
      success: false,
      error: 'Andmebaasiühendus ebaõnnestus'
    });
  }
});

// ... (teised route'id)

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server töötab port ${PORT}`);
});
```

**Salvesta** ja **välju**.

---

**Käivita server:**
```bash
npm run dev

# Väljund:
# [nodemon] starting `node index.js`
# ✅ Ühendatud andmebaasiga
# Server töötab port 3000
```

**Testi:**
```bash
curl http://localhost:3000/api/test-db

# Väljund:
# {
#   "success": true,
#   "time": "2024-11-14T14:30:00.123Z",
#   "message": "Andmebaas töötab!"
# }
```

✅ **Ühendus töötab!**

---

### 3.6. Docker Network (Optional)

Kui tahad, et Express ja PostgreSQL oleksid **samas Docker network'is** (ilma port mapping'uta):

```bash
# Loo network (kui pole olemas)
docker network create app-network

# Ühenda PostgreSQL sellesse
docker network connect app-network postgres-prod

# Kontrolli
docker network inspect app-network
```

**Connection string muutub:**
```env
# Host on nüüd konteineri nimi (mitte localhost)
DATABASE_URL=postgresql://appuser:StrongPassword123!@postgres-prod:5432/appdb
```

**Kui Express ka Dockeris** (hiljem Peatükis 12):
```dockerfile
# Dockerfile
FROM node:20-alpine
# ...
```

```bash
# Käivita Express samas network'is
docker run --name express-api --network app-network ...
```

---

## 4. ALTERNATIIV: Väline PostgreSQL

### 4.1. Eeldused

Eeldame, et sul on **Peatükist 3** töötav väline PostgreSQL:

```bash
# Kontrolli PostgreSQL staatust
sudo systemctl status postgresql

# Peaks olema: active (running)
```

**Kui ei tööta:**
```bash
sudo systemctl start postgresql
```

---

### 4.2. Connection String

**Väline PostgreSQL** (VPS):

```env
# Kui Node.js töötab samal serveril
DATABASE_URL=postgresql://appuser:StrongPassword123!@localhost:5432/appdb

# Kui Node.js töötab eraldi serveril
DATABASE_URL=postgresql://appuser:StrongPassword123!@192.168.1.100:5432/appdb
```

---

### 4.3. SSL/TLS Ühendused

Tootmises peaks kasutama **SSL/TLS**:

**.env:**
```env
# SSL/TLS-iga
DATABASE_URL=postgresql://appuser:password@db.example.com:5432/appdb?sslmode=require
```

**db.js (SSL konfiguratsioon):**
```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: false } // Production
    : false // Development
});
```

**HOIATUS:** `rejectUnauthorized: false` ainult testimiseks! Tootmises kasuta õigeid sertifikaate.

---

### 4.4. Firewall Reeglid

Kui Node.js ja PostgreSQL on **eri serverites**:

**PostgreSQL serveris:**
```bash
# Luba PostgreSQL port
sudo ufw allow from 192.168.1.50 to any port 5432 comment 'Node.js server'

# VÕI kõigile (AINULT TESTIMISEKS!)
sudo ufw allow 5432/tcp
```

**pg_hba.conf:**
```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

**Lisa:**
```
# Luba Node.js serveri IP
host    all             all             192.168.1.50/32         scram-sha-256
```

**Taaskäivita:**
```bash
sudo systemctl restart postgresql
```

---

## 5. Connection Pooling

### 5.1. Mis on Connection Pool?

**Connection pool** on ühenduste **taaskasutamise** mehhanism.

#### Analoogia: Takso Seisukoht

**Ilma pool'ita (iga päring = uus ühendus):**
```
Client → Telli takso → Oota → Sõida → Maksad → Takso läheb ära
        (aeglane!)      (raiskab aega)
```

**Pool'iga (ühendused on juba valmis):**
```
Client → Võtad valmis takso → Sõidad → Tagastad pool'i
        (kiire!)              (taaskasutus)
```

---

### 5.2. Pool Konfiguratsioon

**db.js:**
```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,

  max: 20,                    // Maksimaalselt 20 ühendust
  min: 2,                     // Minimaalselt 2 ühendust (warm pool)
  idleTimeoutMillis: 30000,   // Idle ühendus suletakse 30s pärast
  connectionTimeoutMillis: 2000, // Timeout 2s (kui pool on täis)

  // Query timeout
  query_timeout: 10000,       // Päring timeout 10s

  // Statement timeout
  statement_timeout: 10000,   // SQL statement timeout 10s
});
```

---

### 5.3. Pool Kasutamine

**Automaatne (soovitatav):**
```javascript
// Pool haldab ühendusi automaatselt
const result = await pool.query('SELECT * FROM users');
// Ühendus tagastatakse pool'i automaatselt
```

**Manuaalne (kui vaja kontrollida):**
```javascript
const client = await pool.connect();
try {
  const result = await client.query('SELECT * FROM users');
  return result.rows;
} catch (error) {
  throw error;
} finally {
  client.release(); // ⚠️ OLULINE: vabasta ühendus!
}
```

---

### 5.4. Pool Monitoring

**Kontrolli pool'i staatust:**
```javascript
app.get('/api/pool-stats', (req, res) => {
  res.json({
    total: pool.totalCount,     // Kokku ühendusi
    idle: pool.idleCount,       // Idle ühendusi
    waiting: pool.waitingCount  // Ootavaid päringuid
  });
});
```

---

## 6. Andmebaasi Päringud

### 6.1. Lihtsad Päringud

```javascript
// SELECT
const result = await pool.query('SELECT * FROM users');
console.log(result.rows); // [{ id: 1, name: 'Alice', ... }, ...]

// INSERT
const result = await pool.query(
  "INSERT INTO users (name, email) VALUES ('Bob', 'bob@example.com') RETURNING *"
);
console.log(result.rows[0]); // { id: 2, name: 'Bob', ... }

// UPDATE
const result = await pool.query(
  "UPDATE users SET name = 'Alice Updated' WHERE id = 1 RETURNING *"
);

// DELETE
const result = await pool.query(
  "DELETE FROM users WHERE id = 2 RETURNING *"
);
```

---

### 6.2. Result Objekt

**pool.query()** tagastab objekti:

```javascript
const result = await pool.query('SELECT * FROM users');

console.log({
  rows: result.rows,          // Array of objects [{ id: 1, ... }]
  rowCount: result.rowCount,  // Number of rows
  fields: result.fields,      // Column metadata
  command: result.command     // SQL command (SELECT, INSERT, ...)
});
```

**Näide:**
```javascript
{
  rows: [
    { id: 1, name: 'Alice', email: 'alice@example.com' },
    { id: 2, name: 'Bob', email: 'bob@example.com' }
  ],
  rowCount: 2,
  command: 'SELECT'
}
```

---

## 7. SQL Injection Kaitse

### 7.1. SQL Injection Oht

**SQL Injection** on äärmiselt ohtlik turvaviga!

#### ❌ VALE (ohtlik!)

```javascript
// ÄRA KUNAGI TEE SEDA!
const userId = req.params.id;
const query = `SELECT * FROM users WHERE id = ${userId}`;
const result = await pool.query(query);
```

**Ründaja saadab:**
```
GET /api/users/1; DROP TABLE users; --
```

**Käivitatav SQL:**
```sql
SELECT * FROM users WHERE id = 1; DROP TABLE users; --
```

💀 **Kõik kasutajad on kustutatud!**

---

### 7.2. Parameetriseeritud Päringud

#### ✅ ÕIGE (turvaline!)

```javascript
const userId = req.params.id;
const result = await pool.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);
```

**Ründaja saadab:**
```
GET /api/users/1; DROP TABLE users; --
```

**Käivitatav SQL:**
```sql
SELECT * FROM users WHERE id = '1; DROP TABLE users; --'
-- See on nüüd lihtsalt string, mitte SQL kood!
```

✅ **Turvaline!** pg library escapeb parameetrid.

---

### 7.3. Parameetrite Süntaks

**Positional parameters ($1, $2, ...):**

```javascript
// Üks parameeter
await pool.query(
  'SELECT * FROM users WHERE id = $1',
  [userId]
);

// Mitu parameetrit
await pool.query(
  'SELECT * FROM users WHERE name = $1 AND email = $2',
  [name, email]
);

// INSERT
await pool.query(
  'INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3) RETURNING *',
  [name, email, passwordHash]
);

// UPDATE
await pool.query(
  'UPDATE users SET name = $1, email = $2 WHERE id = $3 RETURNING *',
  [name, email, userId]
);

// DELETE
await pool.query(
  'DELETE FROM users WHERE id = $1 RETURNING *',
  [userId]
);
```

**REEGEL:** ALATI kasuta parameetriseeritud päringuid kasutaja sisendiga!

---

### 7.4. WHERE IN

**Mitme väärtusega:**

```javascript
// Otsi kasutajaid ID-de järgi
const ids = [1, 2, 3];

await pool.query(
  'SELECT * FROM users WHERE id = ANY($1)',
  [ids]
);

// VÕI
await pool.query(
  'SELECT * FROM users WHERE id IN (SELECT unnest($1::int[]))',
  [ids]
);
```

---

## 8. Transactions

### 8.1. Mis on Transaction?

**Transaction** (tehing) on **mitme operatsiooni** grupp, mis kas:
- **Õnnestub täielikult** (commit)
- **Ebaõnnestub täielikult** (rollback)

#### Analoogia: Pangaülekanne

```
Alusta → Võta 100€ Kontolt A → Lisa 100€ Kontole B → Commit
   ↓              ↓                     ↓              ↓
   │         Kui viga siia            Rollback!    Salvesta
   └──────────────┘
        ACID garantii
```

---

### 8.2. ACID Omadused

- **Atomicity:** Kõik või mitte midagi
- **Consistency:** Andmed on alati korrektsed
- **Isolation:** Transactions ei sega teineteist
- **Durability:** Commit on püsiv (ka restart'i korral)

---

### 8.3. Transaction Kasutamine

**Põhiline süntaks:**

```javascript
const client = await pool.connect();

try {
  await client.query('BEGIN');

  // Tee mitu operatsiooni
  await client.query('INSERT INTO users ...');
  await client.query('UPDATE accounts ...');
  await client.query('DELETE FROM logs ...');

  await client.query('COMMIT');
  console.log('Transaction õnnestus!');
} catch (error) {
  await client.query('ROLLBACK');
  console.error('Transaction ebaõnnestus, rollback tehtud');
  throw error;
} finally {
  client.release(); // Vabasta ühendus pool'i
}
```

---

### 8.4. Transaction Näide

**Kasutaja registreerimine + audit log:**

```javascript
app.post('/api/register', async (req, res) => {
  const { name, email, password } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // 1. Loo kasutaja
    const userResult = await client.query(
      'INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3) RETURNING *',
      [name, email, hashPassword(password)]
    );
    const user = userResult.rows[0];

    // 2. Loo audit log entry
    await client.query(
      'INSERT INTO audit_logs (user_id, action, timestamp) VALUES ($1, $2, NOW())',
      [user.id, 'USER_CREATED']
    );

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      data: user
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Registration transaction failed:', error);
    res.status(500).json({
      success: false,
      error: 'Registreerimine ebaõnnestus'
    });
  } finally {
    client.release();
  }
});
```

**Kui step 2 ebaõnnestub, ROLLBACK tühistab ka step 1!**

---

### 8.5. Transaction Helper Function

**Loo utils/db.js:**

```javascript
// utils/db.js
const pool = require('../db');

/**
 * Käivita transaction
 * @param {Function} callback - Async function mis saa client'i
 */
async function withTransaction(callback) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

module.exports = { withTransaction };
```

**Kasutamine:**

```javascript
const { withTransaction } = require('./utils/db');

app.post('/api/register', async (req, res) => {
  try {
    const user = await withTransaction(async (client) => {
      // Kõik päringud transaction'is
      const userResult = await client.query('INSERT INTO users ...');
      await client.query('INSERT INTO audit_logs ...');
      return userResult.rows[0];
    });

    res.status(201).json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});
```

---

## 9. Error Handling

### 9.1. PostgreSQL Veakoodid

PostgreSQL tagastab veakoodid (error codes):

**Levinud koodid:**
- `23505` - Unique constraint violation (duplikaatne väärtus)
- `23503` - Foreign key constraint violation
- `23502` - Not null constraint violation
- `42P01` - Undefined table
- `42703` - Undefined column
- `57014` - Query canceled (timeout)

**Täielik nimekiri:** https://www.postgresql.org/docs/current/errcodes-appendix.html

---

### 9.2. Error Handling Pattern

```javascript
app.post('/api/users', async (req, res) => {
  const { name, email } = req.body;

  try {
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Database error:', error);

    // Kontrolli veakoodi
    if (error.code === '23505') {
      // Unique constraint violation
      return res.status(409).json({
        success: false,
        error: 'Email on juba kasutuses'
      });
    }

    // Muu viga
    res.status(500).json({
      success: false,
      error: 'Serveri viga'
    });
  }
});
```

---

### 9.3. Error Middleware

**Loo keskne error handler:**

```javascript
// middleware/errorHandler.js
function errorHandler(err, req, res, next) {
  console.error('Error:', err);

  // PostgreSQL vigad
  if (err.code) {
    switch (err.code) {
      case '23505': // Unique constraint
        return res.status(409).json({
          success: false,
          error: 'Duplikaat väärtus'
        });

      case '23503': // Foreign key constraint
        return res.status(400).json({
          success: false,
          error: 'Seotud kirje ei eksisteeri'
        });

      case '23502': // Not null constraint
        return res.status(400).json({
          success: false,
          error: 'Kohustuslik väli puudub'
        });

      default:
        return res.status(500).json({
          success: false,
          error: 'Andmebaasi viga'
        });
    }
  }

  // Üldine viga
  res.status(500).json({
    success: false,
    error: process.env.NODE_ENV === 'production'
      ? 'Serveri viga'
      : err.message
  });
}

module.exports = errorHandler;
```

**index.js:**
```javascript
const errorHandler = require('./middleware/errorHandler');

// ... (route'id)

// Kasuta error middleware't (viimane!)
app.use(errorHandler);
```

---

## 10. CRUD API PostgreSQL-iga

### 10.1. Andmebaasi Ettevalmistus

**Loo tabel kasutajatele:**

```bash
# Docker PostgreSQL
docker exec -it postgres-prod psql -U appuser -d appdb

# Väline PostgreSQL
psql -U appuser -d appdb -h localhost
```

**SQL:**
```sql
-- Loo users tabel
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Lisa indeks email'ile (kiiremaks otsinguks)
CREATE INDEX idx_users_email ON users(email);

-- Lisa kommentaar
COMMENT ON TABLE users IS 'Rakenduse kasutajad';

-- Kontrolli
\d users

-- Väljumine
\q
```

---

### 10.2. Täielik CRUD API

**Loo routes/users.js:**

```javascript
// routes/users.js
const express = require('express');
const router = express.Router();
const pool = require('../db');

// === GET /api/users - Kõik kasutajad ===
router.get('/', async (req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT id, name, email, created_at FROM users ORDER BY id'
    );

    res.json({
      success: true,
      count: result.rowCount,
      data: result.rows
    });
  } catch (error) {
    next(error);
  }
});

// === GET /api/users/:id - Üks kasutaja ===
router.get('/:id', async (req, res, next) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'SELECT id, name, email, created_at FROM users WHERE id = $1',
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        error: 'Kasutajat ei leitud'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
});

// === POST /api/users - Loo kasutaja ===
router.post('/', async (req, res, next) => {
  const { name, email, password } = req.body;

  // Validatsioon
  if (!name || !email || !password) {
    return res.status(400).json({
      success: false,
      error: 'Nimi, email ja parool on kohustuslikud'
    });
  }

  // Lihtne email validatsioon
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return res.status(400).json({
      success: false,
      error: 'Vigane email formaat'
    });
  }

  try {
    // HOIATUS: Päris rakenduses kasuta bcrypt'i!
    // const bcrypt = require('bcrypt');
    // const passwordHash = await bcrypt.hash(password, 10);
    const passwordHash = password; // Ajutiselt (MITTE TOOTMISES!)

    const result = await pool.query(
      'INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3) RETURNING id, name, email, created_at',
      [name, email, passwordHash]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
});

// === PUT /api/users/:id - Uuenda kasutaja ===
router.put('/:id', async (req, res, next) => {
  const { id } = req.params;
  const { name, email } = req.body;

  // Validatsioon
  if (!name || !email) {
    return res.status(400).json({
      success: false,
      error: 'Nimi ja email on kohustuslikud'
    });
  }

  try {
    const result = await pool.query(
      'UPDATE users SET name = $1, email = $2, updated_at = NOW() WHERE id = $3 RETURNING id, name, email, updated_at',
      [name, email, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        error: 'Kasutajat ei leitud'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
});

// === PATCH /api/users/:id - Osaline uuendamine ===
router.patch('/:id', async (req, res, next) => {
  const { id } = req.params;
  const { name, email } = req.body;

  // Vähemalt üks väli peab olema
  if (!name && !email) {
    return res.status(400).json({
      success: false,
      error: 'Vähemalt üks väli (name või email) on kohustuslik'
    });
  }

  try {
    // Dünaamiline UPDATE (ainult antud väljad)
    const updates = [];
    const values = [];
    let paramCount = 1;

    if (name) {
      updates.push(`name = $${paramCount++}`);
      values.push(name);
    }

    if (email) {
      updates.push(`email = $${paramCount++}`);
      values.push(email);
    }

    updates.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE users
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, name, email, updated_at
    `;

    const result = await pool.query(query, values);

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        error: 'Kasutajat ei leitud'
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
});

// === DELETE /api/users/:id - Kustuta kasutaja ===
router.delete('/:id', async (req, res, next) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM users WHERE id = $1 RETURNING id, name, email',
      [id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        error: 'Kasutajat ei leitud'
      });
    }

    res.json({
      success: true,
      message: 'Kasutaja kustutatud',
      data: result.rows[0]
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
```

---

### 10.3. Mount Router

**index.js:**

```javascript
require('dotenv').config();
const express = require('express');
const pool = require('./db');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// Middleware
app.use(express.json());

// Routes
const usersRouter = require('./routes/users');
app.use('/api/users', usersRouter);

// Test route
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({
      success: true,
      time: result.rows[0].now,
      message: 'Andmebaas töötab!'
    });
  } catch (error) {
    console.error('DB viga:', error);
    res.status(500).json({
      success: false,
      error: 'Andmebaasiühendus ebaõnnestus'
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route ei leitud'
  });
});

// Error handler
app.use(errorHandler);

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Server töötab port ${PORT}`);
});
```

---

### 10.4. API Testimine

**cURL näited:**

```bash
# GET kõik kasutajad
curl http://localhost:3000/api/users

# GET üks kasutaja
curl http://localhost:3000/api/users/1

# POST uus kasutaja
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice",
    "email": "alice@example.com",
    "password": "secret123"
  }'

# PUT uuenda kasutaja
curl -X PUT http://localhost:3000/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Updated",
    "email": "alice.new@example.com"
  }'

# PATCH osaline uuendamine
curl -X PATCH http://localhost:3000/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Smith"
  }'

# DELETE kustuta kasutaja
curl -X DELETE http://localhost:3000/api/users/1
```

---

### 10.5. Postman Collection

**Import Postman'i:**

```json
{
  "info": {
    "name": "Users API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Get All Users",
      "request": {
        "method": "GET",
        "url": "http://localhost:3000/api/users"
      }
    },
    {
      "name": "Get User by ID",
      "request": {
        "method": "GET",
        "url": "http://localhost:3000/api/users/1"
      }
    },
    {
      "name": "Create User",
      "request": {
        "method": "POST",
        "url": "http://localhost:3000/api/users",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"name\": \"Bob\",\n  \"email\": \"bob@example.com\",\n  \"password\": \"secret123\"\n}"
        }
      }
    }
  ]
}
```

---

## 11. Harjutused

### Harjutus 6.1: PostgreSQL Ühenduse Seadistamine

**Eesmärk:** Ühendada Node.js PostgreSQL-iga

**Sammud:**
1. Kontrolli, et PostgreSQL töötab (Docker või väline)
2. Paigalda `pg`: `npm install pg`
3. Loo `db.js` fail connection pool'iga
4. Lisa `.env` fail connection string'iga
5. Testi ühendust: `/api/test-db` route
6. Kontrolli, et näed `✅ Ühendatud andmebaasiga`

**Oodatav tulemus:** Õnnestunud DB ühendus

---

### Harjutus 6.2: Users Tabeli Loomine

**Eesmärk:** Luua andmebaasiskeem

**Sammud:**
1. Ühenda PostgreSQL-iga (psql)
2. Loo `users` tabel (vt sektsioon 10.1)
3. Lisa test andmed:
```sql
INSERT INTO users (name, email, password_hash) VALUES
  ('Alice', 'alice@example.com', 'hash1'),
  ('Bob', 'bob@example.com', 'hash2');
```
4. Kontrolli: `SELECT * FROM users;`

---

### Harjutus 6.3: GET Endpoint'id

**Eesmärk:** Luua lugemise endpoint'id

**Sammud:**
1. Loo `routes/users.js`
2. Lisa GET `/api/users` (kõik kasutajad)
3. Lisa GET `/api/users/:id` (üks kasutaja)
4. Mount router `index.js`-is
5. Testi mõlemat endpoint'i cURL või Postman'iga

**Kontrolli:**
```bash
curl http://localhost:3000/api/users
curl http://localhost:3000/api/users/1
```

---

### Harjutus 6.4: POST Endpoint

**Eesmärk:** Luua kasutaja loomise endpoint

**Sammud:**
1. Lisa POST `/api/users` route
2. Valideeri `name`, `email`, `password`
3. Kasuta parameetriseeritud päringut
4. Testi duplikaatse email'iga (peaks tagastama 409)

**Test:**
```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Charlie","email":"charlie@example.com","password":"secret"}'
```

---

### Harjutus 6.5: PUT ja DELETE Endpoint'id

**Eesmärk:** Täielik CRUD

**Sammud:**
1. Lisa PUT `/api/users/:id`
2. Lisa DELETE `/api/users/:id`
3. Testi kõiki operatsioone
4. Kontrolli, et andmed päriselt muutuvad DB-s

---

### Harjutus 6.6: Error Handling

**Eesmärk:** Käsitleda vigu korrektselt

**Sammud:**
1. Loo `middleware/errorHandler.js`
2. Käsitle 23505 (unique constraint)
3. Testi duplikaatse email'iga
4. Kontrolli, et saad 409 vastuse

---

### Harjutus 6.7: Transaction Kasutamine

**Eesmärk:** Harjutada transactions

**Sammud:**
1. Loo `audit_logs` tabel:
```sql
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
2. Muuda POST `/api/users` kasutama transaction'it
3. Lisa audit log entry pärast kasutaja loomist
4. Testi, et mõlemad kirjed luuakse

---

## 12. Kontrolliküsimused

### Teoreetilised Küsimused

1. **Mis on connection pool ja miks on see oluline?**
   <details>
   <summary>Vastus</summary>
   Connection pool on ühenduste taaskasutamise mehhanism. Oluline, kuna ühenduse loomine on aeganõudev - pool hoiab ühendusi valmis ja taaskasutab neid, parandades jõudlust.
   </details>

2. **Mis on SQL injection ja kuidas seda vältida?**
   <details>
   <summary>Vastus</summary>
   SQL injection on turvaauk, kus ründaja sisestab pahatahtlikku SQL koodi. Vältimine: kasuta ALATI parameetriseeritud päringuid ($1, $2, ...), mitte string concatenation'it.
   </details>

3. **Mis on transaction ja millal seda kasutada?**
   <details>
   <summary>Vastus</summary>
   Transaction on mitme operatsiooni grupp, mis kas õnnestub täielikult või ebaõnnestub täielikult (ACID). Kasuta kui pead tegema mitu seotud operatsiooni, mis peavad kõik õnnestuma.
   </details>

4. **Mis vahe on Client ja Pool vahel pg teegis?**
   <details>
   <summary>Vastus</summary>
   Client on üks ühendus, mida peab käsitsi avama ja sulgema. Pool on ühenduste kogum, mis hallatakse automaatselt - sobib web serveritele.
   </details>

5. **Mis on PostgreSQL veakood 23505?**
   <details>
   <summary>Vastus</summary>
   Unique constraint violation - üritad lisada duplikaatse väärtuse unique väljale (nt email).
   </details>

---

### Praktilised Küsimused

6. **Kuidas paigaldada pg teek?**
   <details>
   <summary>Vastus</summary>
   ```bash
   npm install pg
   ```
   </details>

7. **Kuidas luua connection pool?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   const { Pool } = require('pg');
   const pool = new Pool({
     connectionString: process.env.DATABASE_URL
   });
   ```
   </details>

8. **Kuidas teha parameetriseeritud päring?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   const result = await pool.query(
     'SELECT * FROM users WHERE id = $1',
     [userId]
   );
   ```
   </details>

9. **Kuidas teha transaction?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   const client = await pool.connect();
   try {
     await client.query('BEGIN');
     // ... päringud
     await client.query('COMMIT');
   } catch (error) {
     await client.query('ROLLBACK');
   } finally {
     client.release();
   }
   ```
   </details>

10. **Kuidas käsitleda unique constraint violation?**
    <details>
    <summary>Vastus</summary>
    ```javascript
    try {
      await pool.query('INSERT ...');
    } catch (error) {
      if (error.code === '23505') {
        return res.status(409).json({ error: 'Duplikaat' });
      }
    }
    ```
    </details>

---

## 13. Lisamaterjalid

### 📚 Soovitatud Lugemine

#### node-postgres
- [node-postgres Documentation](https://node-postgres.com/)
- [Connection Pooling](https://node-postgres.com/features/pooling)
- [Queries](https://node-postgres.com/features/queries)
- [Transactions](https://node-postgres.com/features/transactions)

#### PostgreSQL
- [PostgreSQL Error Codes](https://www.postgresql.org/docs/current/errcodes-appendix.html)
- [SQL Injection Prevention](https://bobby-tables.com/)
- [ACID Transactions](https://www.postgresql.org/docs/current/tutorial-transactions.html)

#### Best Practices
- [Node.js Best Practices - Database](https://github.com/goldbergyoni/nodebestpractices#5-database-best-practices)
- [OWASP SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)

---

### 🛠️ Kasulikud Tööriistad

#### Database Clients
- **DBeaver** - Universal database client
- **pgAdmin** - PostgreSQL GUI
- **Postico** - macOS PostgreSQL client
- **TablePlus** - Modern database client

#### Libraries
- **pg-format** - SQL query formatting ja escaping
- **pg-promise** - Promise-based PostgreSQL client
- **Knex.js** - SQL query builder
- **Sequelize** - ORM (Object-Relational Mapping)

```bash
# pg-format paigaldamine
npm install pg-format

# Kasutamine
const format = require('pg-format');
const query = format('SELECT * FROM %I WHERE %I = %L', 'users', 'email', email);
```

---

### 📖 pg Cheat Sheet

```javascript
// === Setup ===
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// === Queries ===
// SELECT
const result = await pool.query('SELECT * FROM users');
const users = result.rows;

// INSERT
const result = await pool.query(
  'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
  [name, email]
);

// UPDATE
await pool.query(
  'UPDATE users SET name = $1 WHERE id = $2',
  [name, id]
);

// DELETE
await pool.query('DELETE FROM users WHERE id = $1', [id]);

// === Transaction ===
const client = await pool.connect();
try {
  await client.query('BEGIN');
  await client.query('INSERT ...');
  await client.query('UPDATE ...');
  await client.query('COMMIT');
} catch (error) {
  await client.query('ROLLBACK');
  throw error;
} finally {
  client.release();
}

// === Error Handling ===
try {
  await pool.query('INSERT ...');
} catch (error) {
  if (error.code === '23505') {
    // Unique constraint violation
  }
}
```

---

## Kokkuvõte

Selles peatükis said:

✅ **Õppisid node-postgres (pg) teeki** - Connection pooling
✅ **Ühendasid Express API PostgreSQL-iga** - Docker ja väline variant
✅ **Õppisid parameetriseeritud päringuid** - SQL injection kaitse
✅ **Harjutasid transactions** - ACID garantii
✅ **Käsitlesid vigu korrektselt** - PostgreSQL veakoodid
✅ **Lõid täisfunktsionaalse CRUD API** - Päris andmebaasipõhine
✅ **Mõistsid connection pool'i** - Jõudluse optimeerimine

---

## Järgmine Peatükk

**Peatükk 7: REST API Disain ja Realiseerimine**

Järgmises peatükis:
- RESTful API disainipõhimõtted
- API versioneerimine
- Pagination, filtering, sorting
- API dokumentatsioon (Swagger/OpenAPI)
- Rate limiting
- CORS seadistamine
- API testimine (Jest, Supertest)

**API muutub professionaalseks!** 🚀

---

## Troubleshooting

### Probleem 1: "Connection refused" viga

**Sümptom:** `Error: connect ECONNREFUSED 127.0.0.1:5432`

**Lahendus:**
```bash
# Kontrolli, kas PostgreSQL töötab
# Docker:
docker ps | grep postgres

# Kui ei tööta:
docker start postgres-prod

# Väline:
sudo systemctl status postgresql
sudo systemctl start postgresql

# Kontrolli porti
sudo ss -tlnp | grep 5432
```

---

### Probleem 2: "password authentication failed"

**Sümptom:** `error: password authentication failed for user "appuser"`

**Lahendus:**
```bash
# Kontrolli .env faili
cat .env
# DATABASE_URL=postgresql://appuser:ÕigeParool@localhost:5432/appdb

# Testi psql'iga
psql -U appuser -d appdb -h localhost
# Kui küsib parooli, sisesta see

# Docker:
docker exec -it postgres-prod psql -U appuser -d appdb
```

---

### Probleem 3: "relation 'users' does not exist"

**Sümptom:** `error: relation "users" does not exist`

**Lahendus:**
```bash
# Ühenda PostgreSQL-iga
psql -U appuser -d appdb -h localhost

# Kontrolli tabeleid
\dt

# Kui pole users tabelit, loo see
CREATE TABLE users (...);

# Kontrolli uuesti
\dt
```

---

### Probleem 4: "Pool is full" - too many connections

**Sümptom:** `Error: Timed out waiting for connection from pool`

**Lahendus:**
```javascript
// Suurenda pool'i suurust db.js failis
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 50 // Suurenda (vaikimisi 10)
});

// VÕI kontrolli, kas vabastаd ühendusi:
const client = await pool.connect();
try {
  // ...
} finally {
  client.release(); // ⚠️ OLULINE!
}
```

---

### Probleem 5: SQL Injection test

**Test:**
```bash
# Kui kasutad string concatenation (VALE):
curl "http://localhost:3000/api/users/1; DROP TABLE users; --"

# Peaks andma vea (parameetriseeritud päring):
curl "http://localhost:3000/api/users/1%3B%20DROP%20TABLE%20users%3B%20--"
# Peaks tagastama 404 või Not Found
```

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
**Järgmine uuendus:** Peatükk 7 lisamine
