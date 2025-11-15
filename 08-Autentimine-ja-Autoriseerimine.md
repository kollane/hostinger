# Peatükk 8: Autentimine ja Autoriseerimine

**Kestus:** 4 tundi
**Eeldused:** Peatükid 1-7 läbitud
**Eesmärk:** Lisa API-le JWT autentimine, paroolide hasheerimine ja role-based access control

---

## Sisukord

1. [Autentimise Põhimõtted](#1-autentimise-põhimõtted)
2. [JWT (JSON Web Tokens)](#2-jwt-json-web-tokens)
3. [Paroolide Hasheerimine (bcrypt)](#3-paroolide-hasheerimine-bcrypt)
4. [Register Endpoint](#4-register-endpoint)
5. [Login Endpoint](#5-login-endpoint)
6. [Auth Middleware](#6-auth-middleware)
7. [Protected Routes](#7-protected-routes)
8. [Refresh Tokens](#8-refresh-tokens)
9. [Role-Based Access Control](#9-role-based-access-control)
10. [Password Reset](#10-password-reset)
11. [Harjutused](#11-harjutused)
12. [Kontrolliküsimused](#12-kontrolliküsimused)
13. [Lisamaterjalid](#13-lisamaterjalid)

---

## 1. Autentimise Põhimõtted

### 1.1. Autentimine vs Autoriseerimine

**Autentimine (Authentication)** - KES sa oled?
- Tõestab kasutaja identiteedi
- Login username/password'iga
- Näide: "Ma olen Alice"

**Autoriseerimine (Authorization)** - MIDA sa tohid teha?
- Kontrollib õigusi
- Role-based, permission-based
- Näide: "Alice võib kasutajaid kustutada"

---

### 1.2. Session-Based vs Token-Based

#### Session-Based (traditsiooniline)
```
1. Kasutaja logib sisse
2. Server loob sessiooni ja salvestab mälus/DB's
3. Server saadab session ID cookie'na
4. Iga request saadab cookie kaasa
5. Server kontrollib sessiooni
```

**Eelised:**
- ✅ Lihtne sessioon tühistada (server-side)
- ✅ Väike cookie size

**Puudused:**
- ⚠️ Ei skaleeru hästi (peab sessioone salvestama)
- ⚠️ Keeruline mikroteenuste arhitektuuris

---

#### Token-Based (JWT)
```
1. Kasutaja logib sisse
2. Server genereerib JWT tokeni
3. Klient salvestab tokeni (localStorage/cookie)
4. Iga request saadab tokeni header'is
5. Server valideerib tokeni (no DB lookup!)
```

**Eelised:**
- ✅ Stateless (ei vaja server-side storage)
- ✅ Skaleerib hästi
- ✅ Sobib mikroteenustele, mobile apps

**Puudused:**
- ⚠️ Keeruline tokeni tühistada enne expiry
- ⚠️ Suurem payload

**Meie koolituses:** Kasutame **JWT** (modernne, skaleeruv)

---

## 2. JWT (JSON Web Tokens)

### 2.1. Mis on JWT?

**JWT** on kompaktne, URL-safe token kasutaja identiteedi edastamiseks.

**Struktuur:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsImlhdCI6MTYzMjQ4MzIwMH0.4X8QVnVh3r_tYFJwO3bFoUZm8aKvPv2t3VZ_kGF8x9I

Header.Payload.Signature
```

---

### 2.2. JWT Komponendid

#### Header
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```
Base64 encoded: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`

#### Payload (Claims)
```json
{
  "userId": 1,
  "email": "alice@example.com",
  "role": "admin",
  "iat": 1632483200,
  "exp": 1632486800
}
```
Base64 encoded: `eyJ1c2VySWQiOjEsImlhdCI6MTYzMjQ4MzIwMH0`

#### Signature
```
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)
```

**Oluline:** JWT on **signeeritud**, mitte **krüpteeritud**. Ära pane sensitive data payload'i!

---

### 2.3. JWT Claims

**Registered claims:**
- `iss` (issuer) - Token'i väljaandja
- `sub` (subject) - Kasutaja ID
- `aud` (audience) - Sihtrühm
- `exp` (expiration) - Aegumise aeg (timestamp)
- `iat` (issued at) - Väljaandmise aeg
- `nbf` (not before) - Kehtib alates

**Custom claims:**
- `userId` - Kasutaja ID
- `email` - Email
- `role` - Roll
- `permissions` - Õigused

---

### 2.4. JWT Paigaldamine

```bash
npm install jsonwebtoken
```

**Kasutamine:**
```javascript
const jwt = require('jsonwebtoken');

// Genereeri token
const token = jwt.sign(
  { userId: 1, email: 'alice@example.com' },
  process.env.JWT_SECRET,
  { expiresIn: '1h' }
);

// Verifitseeri token
try {
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  console.log(decoded.userId); // 1
} catch (error) {
  console.error('Invalid token');
}
```

**.env:**
```
JWT_SECRET=your-super-secret-key-change-this-in-production-min-32-chars
JWT_EXPIRES_IN=1h
```

---

## 3. Paroolide Hasheerimine (bcrypt)

### 3.1. Miks Hasheerida?

**MITTE KUNAGI** salvesta paroole plain text'ina!

```javascript
// ❌ VALE (turvaauk!)
await pool.query('INSERT INTO users (email, password) VALUES ($1, $2)', [email, password]);

// ✅ ÕIGE
const passwordHash = await bcrypt.hash(password, 10);
await pool.query('INSERT INTO users (email, password_hash) VALUES ($1, $2)', [email, passwordHash]);
```

---

### 3.2. bcrypt Paigaldamine

```bash
npm install bcrypt
```

**Kasutamine:**
```javascript
const bcrypt = require('bcrypt');

// Hash password
const password = 'MyPassword123';
const saltRounds = 10;
const passwordHash = await bcrypt.hash(password, saltRounds);
// $2b$10$N9qo8uLOickgx2ZMRZoMye.L0T5gvZ9o.kJ3qC9xGZ8r9F8qK8L9G

// Võrdle password'i
const isMatch = await bcrypt.compare('MyPassword123', passwordHash);
console.log(isMatch); // true

const isMatch2 = await bcrypt.compare('WrongPassword', passwordHash);
console.log(isMatch2); // false
```

**Salt rounds:**
- 10 = kiire, sobilik arenduseks
- 12 = tasakaalustatud (soovitav production)
- 14+ = aeglane, väga turvaline

---

## 4. Register Endpoint

### 4.1. Kasutajate Tabel

```sql
-- Lisa role column
ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'user';

-- Võimalikud rollid
CREATE TYPE user_role AS ENUM ('user', 'admin', 'moderator');
ALTER TABLE users ALTER COLUMN role TYPE user_role USING role::user_role;
```

---

### 4.2. Register Route

**routes/auth.js:**
```javascript
const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const { body, validationResult } = require('express-validator');

/**
 * @route   POST /api/auth/register
 * @desc    Register kasutaja
 * @access  Public
 */
router.post('/register',
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
      .matches(/\d/).withMessage('Parool peab sisaldama vähemalt ühte numbrit')
      .matches(/[A-Z]/).withMessage('Parool peab sisaldama vähemalt ühte suurt tähte')
      .matches(/[a-z]/).withMessage('Parool peab sisaldama vähemalt ühte väikest tähte')
  ],

  async (req, res, next) => {
    try {
      // Validation
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

      const { name, email, password } = req.body;

      // Kontrolli, kas email on juba kasutusel
      const existingUser = await pool.query(
        'SELECT id FROM users WHERE email = $1',
        [email]
      );

      if (existingUser.rowCount > 0) {
        return res.status(409).json({
          success: false,
          error: 'Email on juba registreeritud'
        });
      }

      // Hash password
      const saltRounds = 12;
      const passwordHash = await bcrypt.hash(password, saltRounds);

      // Loo kasutaja
      const result = await pool.query(
        `INSERT INTO users (name, email, password_hash, role)
         VALUES ($1, $2, $3, $4)
         RETURNING id, name, email, role, created_at`,
        [name, email, passwordHash, 'user']
      );

      const user = result.rows[0];

      // Genereeri JWT token
      const token = jwt.sign(
        {
          userId: user.id,
          email: user.email,
          role: user.role
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '1h' }
      );

      res.status(201).json({
        success: true,
        message: 'Kasutaja edukalt registreeritud',
        data: {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
          },
          token
        }
      });

    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;
```

---

### 4.3. Mount Auth Router

**index.js:**
```javascript
const authRouter = require('./routes/auth');
app.use('/api/auth', authRouter);
```

---

### 4.4. Test Register

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Smith",
    "email": "alice@example.com",
    "password": "SecurePass123"
  }'

# Response:
{
  "success": true,
  "message": "Kasutaja edukalt registreeritud",
  "data": {
    "user": {
      "id": 1,
      "name": "Alice Smith",
      "email": "alice@example.com",
      "role": "user"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

## 5. Login Endpoint

**routes/auth.js:**
```javascript
/**
 * @route   POST /api/auth/login
 * @desc    Login kasutaja
 * @access  Public
 */
router.post('/login',
  [
    body('email')
      .trim()
      .notEmpty().withMessage('Email on kohustuslik')
      .isEmail().withMessage('Vigane email formaat')
      .normalizeEmail(),

    body('password')
      .notEmpty().withMessage('Parool on kohustuslik')
  ],

  async (req, res, next) => {
    try {
      // Validation
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

      const { email, password } = req.body;

      // Leia kasutaja
      const result = await pool.query(
        'SELECT id, name, email, password_hash, role FROM users WHERE email = $1',
        [email]
      );

      if (result.rowCount === 0) {
        return res.status(401).json({
          success: false,
          error: 'Vale email või parool'
        });
      }

      const user = result.rows[0];

      // Võrdle parooli
      const isPasswordValid = await bcrypt.compare(password, user.password_hash);

      if (!isPasswordValid) {
        return res.status(401).json({
          success: false,
          error: 'Vale email või parool'
        });
      }

      // Genereeri JWT token
      const token = jwt.sign(
        {
          userId: user.id,
          email: user.email,
          role: user.role
        },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '1h' }
      );

      res.json({
        success: true,
        message: 'Login edukas',
        data: {
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
          },
          token
        }
      });

    } catch (error) {
      next(error);
    }
  }
);
```

---

### 5.1. Test Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@example.com",
    "password": "SecurePass123"
  }'

# Response:
{
  "success": true,
  "message": "Login edukas",
  "data": {
    "user": {
      "id": 1,
      "name": "Alice Smith",
      "email": "alice@example.com",
      "role": "user"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

## 6. Auth Middleware

### 6.1. Loo Auth Middleware

**middleware/auth.js:**
```javascript
const jwt = require('jsonwebtoken');

/**
 * Autentimise middleware - kontrollib JWT tokenit
 */
function authenticate(req, res, next) {
  try {
    // Võta token header'ist
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        success: false,
        error: 'Token puudub. Autentimine nõutud.'
      });
    }

    // Bearer TOKEN formaat
    const token = authHeader.split(' ')[1]; // "Bearer eyJhbG..."

    if (!token) {
      return res.status(401).json({
        success: false,
        error: 'Vale token formaat. Kasuta: Bearer TOKEN'
      });
    }

    // Verifitseeri token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Lisa decoded info req objektile
    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role
    };

    next(); // Jätka järgmise middleware/route'iga

  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Token on aegunud'
      });
    }

    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        error: 'Vigane token'
      });
    }

    res.status(500).json({
      success: false,
      error: 'Autentimise viga'
    });
  }
}

module.exports = authenticate;
```

---

## 7. Protected Routes

### 7.1. Kasuta Auth Middleware

**routes/users.js:**
```javascript
const authenticate = require('../middleware/auth');

// GET /api/users - Ainult autenditud kasutajad
router.get('/', authenticate, async (req, res, next) => {
  try {
    // req.user on kättesaadav (lisatud middleware'i poolt)
    console.log('Logged in user:', req.user.email);

    const result = await pool.query('SELECT id, name, email FROM users');

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/users/me - Enda info
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT id, name, email, role, created_at FROM users WHERE id = $1',
      [req.user.userId]
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
```

---

### 7.2. Test Protected Route

```bash
# Ilma tokenita (FAIL)
curl http://localhost:3000/api/users/me

# Response:
# {
#   "success": false,
#   "error": "Token puudub. Autentimine nõutud."
# }

# Tokeniga (SUCCESS)
curl http://localhost:3000/api/users/me \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Response:
# {
#   "success": true,
#   "data": {
#     "id": 1,
#     "name": "Alice Smith",
#     "email": "alice@example.com",
#     "role": "user"
#   }
# }
```

---

## 8. Refresh Tokens

### 8.1. Miks Refresh Tokens?

**Probleem:** Access token kehtib 1h. Pärast seda peab kasutaja uuesti sisse logima.

**Lahendus:** Refresh token
- Access token: lühike (15min - 1h)
- Refresh token: pikk (7-30 päeva)
- Kasuta refresh token'it, et saada uus access token

---

### 8.2. Refresh Tokens Tabel

```sql
CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
```

---

### 8.3. Genereeri Refresh Token

**routes/auth.js:**
```javascript
const crypto = require('crypto');

// Login endpoint'is
router.post('/login', ..., async (req, res, next) => {
  // ... (validate password)

  // Access token (lühike)
  const accessToken = jwt.sign(
    { userId: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '15m' }
  );

  // Refresh token (pikk, random)
  const refreshToken = crypto.randomBytes(64).toString('hex');

  // Salvesta refresh token DB'sse
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7); // 7 päeva

  await pool.query(
    'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
    [user.id, refreshToken, expiresAt]
  );

  res.json({
    success: true,
    data: {
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
      accessToken,
      refreshToken
    }
  });
});
```

---

### 8.4. Refresh Endpoint

```javascript
/**
 * @route   POST /api/auth/refresh
 * @desc    Uuenda access token refresh token'i abil
 * @access  Public
 */
router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        error: 'Refresh token puudub'
      });
    }

    // Kontrolli refresh token DB'st
    const result = await pool.query(
      `SELECT rt.*, u.email, u.role
       FROM refresh_tokens rt
       JOIN users u ON rt.user_id = u.id
       WHERE rt.token = $1 AND rt.expires_at > NOW()`,
      [refreshToken]
    );

    if (result.rowCount === 0) {
      return res.status(401).json({
        success: false,
        error: 'Vale või aegunud refresh token'
      });
    }

    const tokenData = result.rows[0];

    // Genereeri uus access token
    const accessToken = jwt.sign(
      {
        userId: tokenData.user_id,
        email: tokenData.email,
        role: tokenData.role
      },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    res.json({
      success: true,
      data: {
        accessToken
      }
    });

  } catch (error) {
    next(error);
  }
});
```

---

## 9. Role-Based Access Control

### 9.1. Authorize Middleware

**middleware/authorize.js:**
```javascript
/**
 * Autoriseerimise middleware - kontrollib rolle
 * @param {string[]} allowedRoles - Lubatud rollid
 */
function authorize(...allowedRoles) {
  return (req, res, next) => {
    // Eeldab, et authenticate middleware on juba käivitatud
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Autentimine nõutud'
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: `Ligipääs keelatud. Nõutud roll: ${allowedRoles.join(' või ')}`
      });
    }

    next();
  };
}

module.exports = authorize;
```

---

### 9.2. Kasutamine

**routes/users.js:**
```javascript
const authenticate = require('../middleware/auth');
const authorize = require('../middleware/authorize');

// Ainult admin saab kasutajaid kustutada
router.delete('/:id',
  authenticate,
  authorize('admin'),
  async (req, res, next) => {
    try {
      const { id } = req.params;

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
  }
);

// Admin või moderator saavad kasutajaid vaadata
router.get('/',
  authenticate,
  authorize('admin', 'moderator'),
  async (req, res, next) => {
    // ...
  }
);
```

---

### 9.3. Test Autoriseerimine

```bash
# User proovib kustutada (FAIL)
curl -X DELETE http://localhost:3000/api/users/2 \
  -H "Authorization: Bearer USER_TOKEN"

# Response:
# {
#   "success": false,
#   "error": "Ligipääs keelatud. Nõutud roll: admin"
# }

# Admin kustutab (SUCCESS)
curl -X DELETE http://localhost:3000/api/users/2 \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

---

## 10. Password Reset

### 10.1. Password Reset Flow

```
1. Kasutaja vajutab "Forgot Password"
2. Sisestab email
3. Server genereerib reset token
4. Saadab email'i reset link'iga
5. Kasutaja klikib link'i
6. Sisestab uue parooli
7. Server verifitseerib token'i ja uuendab parooli
```

---

### 10.2. Password Reset Tabel

```sql
CREATE TABLE password_reset_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### 10.3. Request Password Reset

```javascript
/**
 * @route   POST /api/auth/forgot-password
 * @desc    Taotle parooli reset'i
 * @access  Public
 */
router.post('/forgot-password', async (req, res, next) => {
  try {
    const { email } = req.body;

    // Leia kasutaja
    const result = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    // Ära avalikusta, kas email on olemas (security)
    if (result.rowCount === 0) {
      return res.json({
        success: true,
        message: 'Kui email on registreeritud, saadetakse reset link'
      });
    }

    const userId = result.rows[0].id;

    // Genereeri reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 1); // 1 tund

    // Salvesta token
    await pool.query(
      'INSERT INTO password_reset_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
      [userId, resetToken, expiresAt]
    );

    // Saada email (TODO: email service)
    const resetUrl = `http://localhost:3000/reset-password?token=${resetToken}`;
    console.log('Reset URL:', resetUrl);

    // TODO: Saada email (nodemailer)

    res.json({
      success: true,
      message: 'Kui email on registreeritud, saadetakse reset link'
    });

  } catch (error) {
    next(error);
  }
});
```

---

### 10.4. Reset Password

```javascript
/**
 * @route   POST /api/auth/reset-password
 * @desc    Reset password token'i abil
 * @access  Public
 */
router.post('/reset-password', async (req, res, next) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({
        success: false,
        error: 'Token ja uus parool on kohustuslikud'
      });
    }

    // Leia token
    const result = await pool.query(
      `SELECT user_id FROM password_reset_tokens
       WHERE token = $1 AND expires_at > NOW() AND used = FALSE`,
      [token]
    );

    if (result.rowCount === 0) {
      return res.status(400).json({
        success: false,
        error: 'Vale või aegunud token'
      });
    }

    const userId = result.rows[0].user_id;

    // Hash uus parool
    const passwordHash = await bcrypt.hash(newPassword, 12);

    // Uuenda parool
    await pool.query(
      'UPDATE users SET password_hash = $1 WHERE id = $2',
      [passwordHash, userId]
    );

    // Märgi token kasutatud
    await pool.query(
      'UPDATE password_reset_tokens SET used = TRUE WHERE token = $1',
      [token]
    );

    res.json({
      success: true,
      message: 'Parool edukalt uuendatud'
    });

  } catch (error) {
    next(error);
  }
});
```

---

## 11. Harjutused

### Harjutus 8.1: Register ja Login

1. Lisa users tabelisse role column
2. Loo routes/auth.js
3. Lisa register endpoint
4. Lisa login endpoint
5. Testi mõlemat Postman'iga

---

### Harjutus 8.2: Auth Middleware

1. Loo middleware/auth.js
2. Rakenda authenticate middleware
3. Kaitse GET /api/users/me route
4. Testi tokenita ja tokeniga

---

### Harjutus 8.3: Role-Based Access

1. Loo middleware/authorize.js
2. Kaitse DELETE /api/users/:id (ainult admin)
3. Testi user ja admin tokenitega

---

### Harjutus 8.4: Refresh Tokens

1. Loo refresh_tokens tabel
2. Lisa refresh token login'is
3. Loo POST /api/auth/refresh endpoint
4. Testi refresh flow'i

---

## 12. Kontrolliküsimused

1. **Mis vahe on autentimisel ja autoriseerimise?**
2. **Mis on JWT ja millest see koosneb?**
3. **Miks on bcrypt parem kui MD5/SHA256 paroolide jaoks?**
4. **Mis on refresh token ja miks seda kasutada?**
5. **Kuidas implementeerida role-based access control?**

---

## 13. Lisamaterjalid

- [JWT.io](https://jwt.io/) - JWT debugger
- [bcrypt explained](https://auth0.com/blog/hashing-in-action-understanding-bcrypt/)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
