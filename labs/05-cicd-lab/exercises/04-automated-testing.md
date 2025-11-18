# Harjutus 4: Automated Testing

**Kestus:** 45 minutit
**Eesmärk:** Integreerida automated testing CI/CD pipeline'i

---

## 📋 Ülevaade

Selles harjutuses õpid lisama automated teste CI/CD pipeline'i. **Testid peavad läbima enne Docker build'i ja deployment'i** - see on quality gate, mis tagab, et vigane kood ei jõua production'i.

**Automated testing** tagab koodi kvaliteedi, vähendab bugi production'is ja annab kindluse, et muudatused ei rikkunud olemasolevat funktsionaalsust. Kasutame unit teste, integration teste ja linting'ut.

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Kirjutada unit teste Node.js rakendusele
- ✅ Integreerida npm test GitHub Actions'iga
- ✅ Lisada linting (ESLint) CI pipeline'i
- ✅ Genereerida test coverage report'e
- ✅ Implementeerida quality gate'sid (fail-fast)
- ✅ Upload'ida test artifacts
- ✅ Blokeerida deployment kui testid failivad

---

## 🏗️ Arhitektuur

```
┌────────────────────────────────────────────────┐
│         GitHub Repository                      │
│                                                │
│  Developer push code                           │
│         │                                      │
│         ▼                                      │
│  ┌──────────────────────────────────────────┐ │
│  │  .github/workflows/ci.yml               │ │
│  │                                          │ │
│  │  ┌────────────────────────────────────┐ │ │
│  │  │  1. Lint (ESLint)                  │ │ │
│  │  │     ✅ Pass → Continue              │ │ │
│  │  │     ❌ Fail → Stop pipeline        │ │ │
│  │  └────────────────────────────────────┘ │ │
│  │           │                              │ │
│  │           ▼                              │ │
│  │  ┌────────────────────────────────────┐ │ │
│  │  │  2. Unit Tests (npm test)          │ │ │
│  │  │     ✅ Pass → Continue              │ │ │
│  │  │     ❌ Fail → Stop pipeline        │ │ │
│  │  └────────────────────────────────────┘ │ │
│  │           │                              │ │
│  │           ▼                              │ │
│  │  ┌────────────────────────────────────┐ │ │
│  │  │  3. Coverage Report                │ │ │
│  │  │     Upload artifact                │ │ │
│  │  └────────────────────────────────────┘ │ │
│  │           │                              │ │
│  │           ▼                              │ │
│  │  ┌────────────────────────────────────┐ │ │
│  │  │  4. Docker Build (if tests pass)   │ │ │
│  │  └────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────┘ │
└────────────────────────────────────────────────┘

Quality Gate: Tests must pass before build/deploy!
```

---

## 📝 Sammud

### Samm 1: Lisa Testing Dependencies (5 min)

**Install Jest (testing framework):**

```bash
# Install Jest + supertest (API testing)
npm install --save-dev jest supertest

# Install ESLint
npm install --save-dev eslint eslint-config-standard

# Kontrolli package.json
cat package.json
```

**Lisa `package.json` scripts:**

```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest --coverage",
    "test:watch": "jest --watch",
    "lint": "eslint .",
    "lint:fix": "eslint . --fix"
  },
  "jest": {
    "testEnvironment": "node",
    "coverageDirectory": "coverage",
    "collectCoverageFrom": [
      "**/*.js",
      "!node_modules/**",
      "!coverage/**",
      "!jest.config.js"
    ]
  }
}
```

---

### Samm 2: Loo ESLint Config (5 min)

**Loo ESLint konfiguratsioon:**

Loo fail `.eslintrc.json`:

```json
{
  "env": {
    "node": true,
    "es2021": true,
    "jest": true
  },
  "extends": "eslint:recommended",
  "parserOptions": {
    "ecmaVersion": 12
  },
  "rules": {
    "indent": ["error", 2],
    "linebreak-style": ["error", "unix"],
    "quotes": ["error", "single"],
    "semi": ["error", "always"],
    "no-unused-vars": ["warn"],
    "no-console": "off"
  }
}
```

**Loo `.eslintignore`:**

```
node_modules/
coverage/
.github/
```

**Testi linting:**

```bash
# Lint kood
npm run lint

# Fix automaatselt
npm run lint:fix

# Peaks näitama:
# ✨  Done in 2.5s
```

**Commit:**

```bash
git add package.json .eslintrc.json .eslintignore
git commit -m "Add ESLint configuration"
git push origin main
```

---

### Samm 3: Kirjuta Unit Teste (10 min)

**Loo test kataloog:**

```bash
mkdir -p tests
```

**Loo test fail `tests/server.test.js`:**

```javascript
const request = require('supertest');
const app = require('../server'); // Export app from server.js

describe('User Service API', () => {
  describe('GET /health', () => {
    it('should return health status', async () => {
      const res = await request(app)
        .get('/health')
        .expect('Content-Type', /json/)
        .expect(200);

      expect(res.body).toHaveProperty('status');
      expect(res.body).toHaveProperty('timestamp');
    });
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      const newUser = {
        name: 'Test User',
        email: `test${Date.now()}@example.com`,
        password: 'Test123!'
      };

      const res = await request(app)
        .post('/api/auth/register')
        .send(newUser)
        .expect('Content-Type', /json/)
        .expect(201);

      expect(res.body).toHaveProperty('user');
      expect(res.body.user).toHaveProperty('id');
      expect(res.body.user.email).toBe(newUser.email);
    });

    it('should fail with missing fields', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ email: 'test@example.com' })
        .expect(400);

      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login existing user', async () => {
      // First register
      const user = {
        name: 'Login Test',
        email: `login${Date.now()}@example.com`,
        password: 'Test123!'
      };

      await request(app).post('/api/auth/register').send(user);

      // Then login
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: user.email, password: user.password })
        .expect(200);

      expect(res.body).toHaveProperty('token');
    });

    it('should fail with wrong password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'test@example.com', password: 'wrongpass' })
        .expect(401);

      expect(res.body).toHaveProperty('error');
    });
  });
});
```

**Muuda `server.js` - ekspordi app:**

Lisa `server.js` lõppu:

```javascript
// Export app for testing
module.exports = app;
```

**Testi local:**

```bash
# Run tests
npm test

# Peaks näitama:
# PASS  tests/server.test.js
#   User Service API
#     GET /health
#       ✓ should return health status (50ms)
#     POST /api/auth/register
#       ✓ should register a new user (100ms)
#       ✓ should fail with missing fields (20ms)
#     POST /api/auth/login
#       ✓ should login existing user (150ms)
#       ✓ should fail with wrong password (80ms)
#
# Test Suites: 1 passed, 1 total
# Tests:       5 passed, 5 total
# Snapshots:   0 total
# Time:        2.5s
# Coverage:    75% Statements, 70% Branches, 80% Functions, 75% Lines
```

**Commit:**

```bash
git add tests/ server.js
git commit -m "Add unit tests with Jest"
git push origin main
```

---

### Samm 4: Loo CI Workflow (10 min)

**Loo workflow testing'uks:**

Loo fail `.github/workflows/ci.yml`:

```yaml
name: Continuous Integration

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    name: Lint Code
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

  test:
    name: Run Tests
    runs-on: ubuntu-latest
    needs: lint  # Runs only if lint passes

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Upload coverage report
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: coverage-report
          path: coverage/

  build:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: test  # Runs only if tests pass

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/user-service:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**Workflow selgitus:**

- **Job 1 (lint):** ESLint check
  - Fails → STOP pipeline
- **Job 2 (test):** Unit tests + coverage
  - Needs lint to pass
  - Fails → STOP pipeline
- **Job 3 (build):** Docker build
  - Needs test to pass
  - Only runs if tests passed

**Commit ja push:**

```bash
git add .github/workflows/ci.yml
git commit -m "Add CI workflow with lint and test"
git push origin main
```

---

### Samm 5: Vaata CI Workflow Käivitumist (5 min)

**GitHub Actions tab:**

1. Mine repository → **Actions**
2. "Continuous Integration" workflow käivitub
3. Vaata job'e: lint → test → build

**Oodatud väljund:**

```
✅ Job: Lint Code
   ✅ Checkout code
   ✅ Setup Node.js
   ✅ Install dependencies
   ✅ Run ESLint
      ✨  No linting errors found

✅ Job: Run Tests
   ✅ Checkout code
   ✅ Setup Node.js
   ✅ Install dependencies
   ✅ Run tests
      PASS  tests/server.test.js
      Test Suites: 1 passed, 1 total
      Tests:       5 passed, 5 total
      Coverage:    75%
   ✅ Upload coverage report
      Artifact uploaded: coverage-report

✅ Job: Build Docker Image
   ✅ Checkout code
   ✅ Set up Docker Buildx
   ✅ Login to Docker Hub
   ✅ Build and push
      Image pushed: user-service:abc123
```

---

### Samm 6: Testi Fail-Fast (5 min)

**Testi, mis juhtub kui test fallib:**

**Loo vigane test:**

Muuda `tests/server.test.js`:

```javascript
describe('Failing Test', () => {
  it('should fail intentionally', () => {
    expect(1 + 1).toBe(3); // ❌ Fails
  });
});
```

**Commit ja push:**

```bash
git add tests/server.test.js
git commit -m "Add failing test (intentional)"
git push origin main
```

**Vaata Actions tab'is:**

```
✅ Job: Lint Code (passes)
❌ Job: Run Tests (FAILS)
   ✅ Checkout code
   ✅ Setup Node.js
   ✅ Install dependencies
   ❌ Run tests
      FAIL  tests/server.test.js
      ● Failing Test › should fail intentionally
        expect(received).toBe(expected)
        Expected: 3
        Received: 2

⏸️  Job: Build Docker Image (SKIPPED - tests failed)
```

**Build ei käivitu!** Pipeline stopib peale test failure'd.

**Paranda test:**

```javascript
// Kustuta vigane test või paranda:
expect(1 + 1).toBe(2); // ✅
```

```bash
git add tests/server.test.js
git commit -m "Fix failing test"
git push origin main
```

---

### Samm 7: Lisa Coverage Badge (3 min)

**Lisa test coverage badge README.md'sse:**

Muuda `README.md`:

```markdown
# User Service

![CI](https://github.com/your-username/user-service/workflows/Continuous%20Integration/badge.svg)
![Coverage](https://img.shields.io/badge/coverage-75%25-green)

REST API for user management with JWT authentication.

## Features
- User registration
- JWT authentication
- CRUD operations
- Automated tests
- CI/CD pipeline

## Testing
```bash
npm test
npm run lint
```
```

**Commit:**

```bash
git add README.md
git commit -m "Add CI and coverage badges"
git push origin main
```

---

### Samm 8: Lisa Integration Tests (Optional, 5 min)

**Integration test PostgreSQL'iga:**

Loo `tests/integration.test.js`:

```javascript
const request = require('supertest');
const app = require('../server');

describe('Integration Tests', () => {
  describe('Full User Flow', () => {
    let token;
    let userId;

    it('should register, login, and fetch user', async () => {
      // 1. Register
      const user = {
        name: 'Integration Test',
        email: `integration${Date.now()}@example.com`,
        password: 'Test123!'
      };

      const registerRes = await request(app)
        .post('/api/auth/register')
        .send(user)
        .expect(201);

      userId = registerRes.body.user.id;

      // 2. Login
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({ email: user.email, password: user.password })
        .expect(200);

      token = loginRes.body.token;
      expect(token).toBeDefined();

      // 3. Fetch user with token
      const fetchRes = await request(app)
        .get(`/api/users/${userId}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(fetchRes.body.email).toBe(user.email);
    });
  });
});
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **Testing setup:**
  - [ ] Jest installed
  - [ ] ESLint configured
  - [ ] Test scripts `package.json`'is

- [ ] **Tests:**
  - [ ] Unit tests `tests/server.test.js`
  - [ ] 5+ test case'i
  - [ ] Coverage >70%

- [ ] **CI Workflow:**
  - [ ] `.github/workflows/ci.yml`
  - [ ] Lint job
  - [ ] Test job
  - [ ] Build job (conditional)

- [ ] **Quality Gate:**
  - [ ] Lint errors → stop pipeline
  - [ ] Test failures → stop pipeline
  - [ ] Build only if tests pass

- [ ] **Artifacts:**
  - [ ] Coverage report uploaded
  - [ ] Badges README.md'is

---

## 🐛 Troubleshooting

### Probleem 1: Tests failivad - Cannot find module '../server'

**Sümptom:**
```
❌ Run tests
   Error: Cannot find module '../server'
```

**Põhjus:**

`server.js` ei ekspordi `app` objekti.

**Lahendus:**

Lisa `server.js` lõppu:

```javascript
module.exports = app;
```

---

### Probleem 2: Coverage <70%

**Sümptom:**
```
✅ Run tests
   Coverage: 55% Statements (below threshold)
```

**Lahendus:**

Kirjuta rohkem teste:

```javascript
// Lisa testid kõigile endpoint'idele
describe('GET /api/users', () => { ... });
describe('PUT /api/users/:id', () => { ... });
describe('DELETE /api/users/:id', () => { ... });
```

---

### Probleem 3: ESLint errors blokeerivad pipeline'i

**Sümptom:**
```
❌ Run ESLint
   error: Unexpected console statement (no-console)
```

**Lahendus:**

**Variant A: Paranda kood:**

```bash
npm run lint:fix
```

**Variant B: Muuda ESLint rule:**

`.eslintrc.json`:

```json
{
  "rules": {
    "no-console": "warn"  // warning, mitte error
  }
}
```

---

## 🎓 Õpitud Mõisted

### Testing:
- **Unit Test:** Testa individuaalseid funktsioone isoleeritult
- **Integration Test:** Testa mitme komponendi koostööd
- **Test Coverage:** % koodist, mida testid katavad
- **Test Suite:** Grupp seotud teste
- **Test Case:** Üks individuaalne test

### Jest:
- **describe():** Grupeeri testid (test suite)
- **it() / test():** Individuaalne test case
- **expect():** Assertion (ootus)
- **beforeEach():** Setup before each test
- **afterEach():** Cleanup after each test

### CI Concepts:
- **Fail-Fast:** Stop pipeline esimese error'i peale
- **Quality Gate:** Tingimuslik kontrolli punkt (testid peavad läbima)
- **Artifact:** Workflow'i genereeritud fail (coverage report)
- **Job Dependencies:** `needs:` (job käivitub alles peale teist)

### ESLint:
- **Linting:** Koodi staatilise analüüs (syntax, style)
- **Rules:** Linting reeglid (indent, quotes, semi)
- **Auto-fix:** Automaatne parandus (`--fix`)

---

## 💡 Parimad Tavad

1. **Kirjuta testid enne deployment'i** - Quality gate!
2. **100% coverage pole eesmärk** - Keskend olulistele testidele (70-80% piisab)
3. **Testi API endpoint'e** - Unit + integration tests
4. **Kasuta supertest** - API testing library
5. **Fail-fast** - Stop pipeline esimese error'i peale
6. **Upload artifacts** - Coverage reports, test results
7. **Badge'id README'sse** - CI status, coverage
8. **Lint enne teste** - Kiirem feedback (linting on kiirem kui testid)
9. **Cache dependencies** - `cache: 'npm'` (kiirenda workflow'sid)
10. **Test isolation** - Iga test peab olema independent

---

## 🔗 Järgmine Samm

Nüüd sul on automated testing ja quality gate'id! Järgmises harjutuses loome **multi-environment pipeline** - dev, staging ja production deployment'id erinevate approval gate'idega.

**Jätka:** [Harjutus 5: Multi-Environment Pipeline](05-multi-environment.md)

---

## 📚 Viited

### Testing:
- [Jest Documentation](https://jestjs.io/)
- [Supertest](https://github.com/visionmedia/supertest)
- [Testing Node.js Apps](https://nodejs.org/en/docs/guides/testing/)

### ESLint:
- [ESLint Documentation](https://eslint.org/)
- [ESLint Rules](https://eslint.org/docs/rules/)

### GitHub Actions:
- [Upload Artifact](https://github.com/actions/upload-artifact)
- [Node.js CI](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-nodejs)

---

**Õnnitleme! Sul on nüüd automated testing CI/CD pipeline'is! ✅**
