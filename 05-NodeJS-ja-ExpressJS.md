# Peatükk 5: Node.js ja Express.js Alused

**Kestus:** 4 tundi
**Eeldused:** Peatükid 1-4 läbitud
**Eesmärk:** Õppida Node.js ja Express.js abil backend arendust ja esimese REST API loomist

---

## Sisukord

1. [Node.js Ülevaade](#1-nodejs-ülevaade)
2. [Node.js Paigaldamine](#2-nodejs-paigaldamine)
3. [npm ja Package.json](#3-npm-ja-packagejson)
4. [Esimene Node.js Programm](#4-esimene-nodejs-programm)
5. [Express.js Sissejuhatus](#5-expressjs-sissejuhatus)
6. [Routing ja HTTP Meetodid](#6-routing-ja-http-meetodid)
7. [Middleware Kontseptsioon](#7-middleware-kontseptsioon)
8. [Request ja Response Objektid](#8-request-ja-response-objektid)
9. [Environment Variables](#9-environment-variables)
10. [Esimene REST API](#10-esimene-rest-api)
11. [Harjutused](#11-harjutused)
12. [Kontrolliküsimused](#12-kontrolliküsimused)
13. [Lisamaterjalid](#13-lisamaterjalid)

---

## 1. Node.js Ülevaade

### 1.1. Mis on Node.js?

**Node.js** on JavaScript runtime, mis võimaldab käivitada JavaScripti **serveri poolel** (väljaspool brauserit).

#### Analoogia: JavaScript Vabastamine

**Enne Node.js (2009):**
```
JavaScript = Vanglas (ainult brauser)
   │
   └─ Saab töötada ainult veebilehel
      Ei saa faile lugeda
      Ei saa servereid luua
```

**Pärast Node.js:**
```
JavaScript = Vaba (kõikjal)
   ├─ Brauser (frontend)
   ├─ Server (backend)
   ├─ Desktop rakendused (Electron)
   ├─ Mobile (React Native)
   └─ IoT (Internet of Things)
```

---

### 1.2. Node.js Arhitektuur

```
┌─────────────────────────────────────────────────┐
│              Node.js Runtime                    │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │         JavaScript Application           │  │
│  │         (sinu kood)                      │  │
│  └────────────────┬─────────────────────────┘  │
│                   │                             │
│  ┌────────────────▼─────────────────────────┐  │
│  │         Node.js Standard Library         │  │
│  │  fs, http, crypto, path, events, ...    │  │
│  └────────────────┬─────────────────────────┘  │
│                   │                             │
│  ┌────────────────▼─────────────────────────┐  │
│  │         Node.js Bindings                 │  │
│  │         (C++ bridge)                     │  │
│  └────────────────┬─────────────────────────┘  │
│                   │                             │
├───────────────────┼─────────────────────────────┤
│  ┌────────────────▼─────────┐ ┌──────────────┐ │
│  │      V8 Engine           │ │   libuv      │ │
│  │  (Google Chrome)         │ │  (Async I/O) │ │
│  │  - JavaScript compiler   │ │  - Event loop│ │
│  │  - Garbage collection    │ │  - Thread    │ │
│  └──────────────────────────┘ │    pool      │ │
│                                └──────────────┘ │
└─────────────────────────────────────────────────┘
```

---

### 1.3. Node.js Põhiomadused

#### 1.3.1. V8 Engine

**V8** on Google Chrome'i JavaScript engine (C++-s), mis:
- Kompileerib JavaScripti masinkoodiks
- Optimeerib jõudlust
- Haldab mälu (garbage collection)

**Tulemus:** JavaScript on **kiire** (võrreldav Python, Ruby, PHP-ga)

---

#### 1.3.2. Event-Driven & Non-Blocking I/O

**Analoogia: Restoran**

**Traditional (Blocking I/O) - PHP, Python (sync):**
```
Ettekandjad (threads):
1. Võta tellimus → Mine kööki → Oota → Too toit → Järgmine klient
2. Võta tellimus → Mine kööki → Oota → Too toit → Järgmine klient
3. ...

Kui üks ettekandjа ootab, ei saa midagi muud teha.
Palju ettekandjaid (thread'е) = palju mälu.
```

**Node.js (Non-Blocking I/O):**
```
Üks ettekandjа (single thread):
1. Võta tellimus A → Saada kööki → Võta tellimus B
2. Võta tellimus C → Saada kööki → Võta tellimus D
3. Toit A valmis → Too kliendile → Võta tellimus E
4. Toit B valmis → Too kliendile → ...

Ei oota kunagi! Alati midagi teeb.
Väga efektiivne.
```

---

#### 1.3.3. Event Loop

**Event Loop** on Node.js süda:

```
┌───────────────────────────┐
│   Call Stack (põhi pool)  │
│   (sinu sünkroonne kood)  │
└─────────────┬─────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│          Event Loop (tsükkel)           │
├─────────────────────────────────────────┤
│                                         │
│  1. Timers (setTimeout, setInterval)   │
│  2. Pending I/O callbacks              │
│  3. Idle, prepare                      │
│  4. Poll (võrk, failid)                │
│  5. Check (setImmediate)               │
│  6. Close callbacks                    │
│                                         │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────┐
│   Callback Queue            │
│   (async operatsioonid)     │
└─────────────────────────────┘
```

**Näide:**
```javascript
console.log('1. Start');

setTimeout(() => {
  console.log('2. Timer (async)');
}, 0);

console.log('3. End');

// Väljund:
// 1. Start
// 3. End
// 2. Timer (async)
```

**Miks?** `setTimeout` on async, läheb Event Loop'i, käivitatakse pärast sünkroonset koodi.

---

### 1.4. Node.js vs Teised

| Omadus | Node.js | Python (Django/Flask) | PHP | Java (Spring) |
|--------|---------|----------------------|-----|---------------|
| **Keel** | JavaScript | Python | PHP | Java |
| **I/O Model** | Non-blocking | Blocking (async võimalik) | Blocking | Multi-threaded |
| **Concurrency** | Event-driven | Multi-process/thread | Multi-process | Multi-threaded |
| **Jõudlus (I/O)** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **Mälu** | Väike | Keskmine | Väike | Suur |
| **Õppimiskõver** | Keskmine | Lihtne | Lihtne | Keeruline |
| **Kasutusjuhud** | Reaalajas, API, mikroteenused | Üldine, ML, scripting | Web, CMS | Ettevõte, suur süsteem |
| **Package Manager** | npm | pip | composer | maven/gradle |
| **Populaarsus** | 🥇 | 🥈 | 🥉 | 🥈 |

---

### 1.5. Millal Kasutada Node.js?

#### ✅ Sobib Hästi

- **Reaalajas rakendused** - Chat, notifications, live updates
- **REST API'd** - Mikroteenused, backend for frontend
- **I/O intensiivsed rakendused** - File upload, streaming
- **SPA (Single Page Applications)** - React, Vue, Angular backend
- **Prototüüpimine** - Kiire arendus
- **Full-stack JavaScript** - Frontend ja backend samas keeles

#### ⚠️ Ei Sobi Nii Hästi

- **CPU intensiivsed** - Video encoding, image processing (blocking)
- **Scientific computing** - Paremad on Python, R, Julia
- **Väga suur ettevõte süsteem** - Java/C# pakuvad rohkem struktuuri

---

## 2. Node.js Paigaldamine

### 2.1. Node.js Versioonid

Node.js'il on kaks peamist versiooni liini:

- **LTS (Long Term Support):** Stabiilne, soovitav tootmiseks
  - Praegu: Node 20.x LTS
  - Tugi: 30 kuud

- **Current:** Uusimad funktsioonid, vähem stabiilne
  - Praegu: Node 21.x

**Soovitus:** Kasuta **LTS versiooni** (Node 20.x)

---

### 2.2. Paigaldamine Zorin OS-is

#### Meetod 1: NodeSource Repository (SOOVITAV)

```bash
# Lae alla ja käivita NodeSource setup script
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Paigalda Node.js
sudo apt install -y nodejs

# Kontrolli versiooni
node --version
# Väljund: v20.10.0 (või sarnane)

npm --version
# Väljund: 10.2.3 (või sarnane)
```

---

#### Meetod 2: nvm (Node Version Manager)

**nvm** võimaldab paigaldada ja hallata mitut Node.js versiooni.

```bash
# Lae alla ja paigalda nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

# Lae nvm uuesti (või taaskäivita terminal)
source ~/.bashrc

# Kontrolli nvm
nvm --version
# Väljund: 0.39.5

# Paigalda Node.js LTS
nvm install --lts

# Kasuta LTS versiooni
nvm use --lts

# Kontrolli
node --version
npm --version
```

**nvm Eelised:**
- Võid kasutada mitut Node.js versiooni
- Projektipõhised versioonid (`.nvmrc`)
- Lihtne vahetada versioone

```bash
# Paigalda konkreetne versioon
nvm install 18.18.0

# Vaheta versiooni
nvm use 18.18.0

# Näita kõiki paigaldatud versioone
nvm list

# Seadista vaikimisi versioon
nvm alias default 20
```

---

### 2.3. Paigaldamine VPS-is

```bash
# Logi VPS-i sisse
ssh hostinger-vps

# Paigalda Node.js (NodeSource)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Kontrolli
node --version
npm --version
```

---

### 2.4. Node.js Testimine

```bash
# REPL (Read-Eval-Print Loop) - interaktiivne shell
node

# Node.js REPL avaneb:
# Welcome to Node.js v20.10.0.
# Type ".help" for more information.
# >

# Proovi JavaScripti:
> console.log('Hello, Node.js!')
Hello, Node.js!
undefined

> 2 + 2
4

> const sum = (a, b) => a + b
undefined

> sum(5, 3)
8

> .exit
# (või Ctrl+D)
```

---

## 3. npm ja Package.json

### 3.1. Mis on npm?

**npm (Node Package Manager)** on:
- **Package manager** - Teekide (libraries) paigaldamine
- **Registry** - npmjs.com (1.5M+ pakette)
- **CLI tool** - `npm install`, `npm run`, jne

#### Analoogia: Moodulite Pood

```
npm = App Store (aga teekidele)
   │
   ├─ express: Web framework
   ├─ lodash: Utility library
   ├─ axios: HTTP client
   └─ 1,500,000+ teisi pakette
```

---

### 3.2. package.json Fail

**package.json** on projekti "pass" - sisaldab:
- Projekti metaandmeid (nimi, versioon, autor)
- Sõltuvusi (dependencies)
- Skripte (npm run ...)
- Konfiguratsiooni

---

### 3.3. Uue Projekti Loomine

```bash
# Loo projektikataloog
mkdir ~/projects/my-api
cd ~/projects/my-api

# Initsialiseeri npm projekt
npm init

# Interaktiivne dialoog:
# package name: (my-api)
```
👉 Vajuta ENTER (vaikimisi)

```
# version: (1.0.0)
```
👉 Vajuta ENTER

```
# description: Minu esimene Node.js API
```
👉 Kirjuta kirjeldus

```
# entry point: (index.js)
```
👉 Vajuta ENTER

```
# test command:
```
👉 Jäta tühjaks (hiljem)

```
# git repository:
```
👉 Jäta tühjaks või sisesta GitHub URL

```
# keywords: api, nodejs, express
```
👉 Võtmesõnad (valikuline)

```
# author: Janek Tamm
```
👉 Sinu nimi

```
# license: (ISC)
```
👉 Vajuta ENTER

```
Is this OK? (yes)
```
👉 Vajuta ENTER

**Alternatiiv (kiire):**
```bash
# Loo package.json vaikeväärtustega
npm init -y
```

---

### 3.4. package.json Struktuur

```json
{
  "name": "my-api",
  "version": "1.0.0",
  "description": "Minu esimene Node.js API",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": ["api", "nodejs", "express"],
  "author": "Janek Tamm",
  "license": "ISC"
}
```

**Väljade selgitus:**
- **name:** Projekti nimi (unikaalne npm-is kui publitseerid)
- **version:** Semantiline versioon (major.minor.patch)
- **description:** Lühike kirjeldus
- **main:** Entry point (fail, mis eksporditakse)
- **scripts:** Käsud, mida saad käivitada `npm run <script>`
- **keywords:** Otsingumärksõnad
- **author:** Autor
- **license:** Litsents (ISC, MIT, GPL, jne)

---

### 3.5. Pakettide Paigaldamine

#### Paketi Paigaldamine

```bash
# Paigalda express (web framework)
npm install express

# VÕI lühidalt:
npm i express
```

**Väljund:**
```
added 57 packages, and audited 58 packages in 3s

7 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

**Mis juhtus?**
1. Express ja sõltuvused laeti alla npm registrist
2. Paigaldati `node_modules/` kataloogi
3. Lisati `package.json` faili:

```json
{
  ...
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

4. Loodi `package-lock.json` (täpne versioonide lukk)

---

#### node_modules Kataloog

```bash
# Vaata node_modules
ls node_modules/

# Väljund:
# accepts  cookie      express      ...
# array-flatten  cookie-signature  finalhandler  ...
# body-parser   debug    ...
# (57 kausta - express ja sõltuvused)
```

**OLULINE:** `node_modules/` on **suur** ja **ei tohiks commit'ida** Git'i!

```bash
# Lisa .gitignore'i
echo "node_modules/" >> .gitignore
```

---

#### Versioonimärgid

```json
"dependencies": {
  "express": "^4.18.2"
}
```

**Selgitus:**
- `4.18.2` - Täpne versioon
- `^4.18.2` - **Caret** - Luba minor ja patch uuendused (4.x.x)
- `~4.18.2` - **Tilde** - Luba ainult patch uuendused (4.18.x)
- `*` - **Wildcard** - Uusim versioon (ohtlik!)
- `latest` - Uusim versioon

**Soovitus:** Kasuta `^` (vaikimisi npm install)

---

#### Dev Dependencies

**Development dependencies** on paketid, mida vajad ainult arenduseks (mitte tootmises):

```bash
# Paigalda nodemon (auto-restart arenduses)
npm install --save-dev nodemon

# VÕI lühidalt:
npm i -D nodemon
```

**package.json:**
```json
{
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

---

#### Globaalne Paigaldamine

Mõned tööriistad tuleks paigaldada globaalselt:

```bash
# Paigalda nodemon globaalselt
npm install -g nodemon

# Kontrolli
nodemon --version
```

**Globaalsed paketid on kättesaadavad kõigis projektides.**

---

### 3.6. package-lock.json

**package-lock.json** lukustab **täpsed** versioonid kõigi sõltuvuste kohta.

**Miks?**
- **Reprodutseeritavus:** Kõik paigaldavad täpselt samad versioonid
- **Turvalisus:** Väldi ootamatuid uuendusi
- **Kiirus:** npm saab cache'ist laadida

**Commit'i package-lock.json Git'i!**

---

### 3.7. Sõltuvuste Taaspaigaldamine

Kui kloonid projekti (ilma `node_modules/`):

```bash
# Paigalda kõik sõltuvused package.json põhjal
npm install

# npm loob node_modules/ ja paigaldab kõik
```

**Tootmispaigaldus (ilma devDependencies):**
```bash
npm install --production
# VÕI
npm ci --production
```

**npm ci** (clean install):
- Kustutab `node_modules/`
- Paigaldab täpselt `package-lock.json` järgi
- Kiirem ja deterministlikum kui `npm install`

---

### 3.8. npm Skriptid

**Skriptid** on kohandatud käsud `package.json` failis:

```json
{
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  }
}
```

**Käivitamine:**
```bash
# Käivita start script
npm start

# Käivita dev script
npm run dev

# Käivita test script
npm test
# VÕI
npm run test
```

**Erikäsud** (`start`, `test`) ei vaja `run`:
```bash
npm start   # OK
npm test    # OK
```

**Muud skriptid** vajavad `run`:
```bash
npm run dev
npm run build
```

---

## 4. Esimene Node.js Programm

### 4.1. Hello World (Node.js)

```bash
# Loo fail
nano hello.js
```

**Lisa sisu:**
```javascript
console.log('Hello, Node.js!');
```

**Salvesta** ja **välju**.

**Käivita:**
```bash
node hello.js

# Väljund:
# Hello, Node.js!
```

✅ **Esimene Node.js programm töötab!**

---

### 4.2. HTTP Server (built-in)

Node.js sisaldab `http` moodulit:

```javascript
// server.js
const http = require('http');

// Loo server
const server = http.createServer((req, res) => {
  // Määra response headers
  res.writeHead(200, { 'Content-Type': 'text/plain' });

  // Saada response
  res.end('Hello from Node.js HTTP server!');
});

// Kuula pordil 3000
const PORT = 3000;
server.listen(PORT, () => {
  console.log(`Server kuulab aadressil http://localhost:${PORT}`);
});
```

**Käivita:**
```bash
node server.js

# Väljund:
# Server kuulab aadressil http://localhost:3000
```

**Testi brauseris:**
- Mine: http://localhost:3000
- Näed: "Hello from Node.js HTTP server!"

**Sulge server:** Ctrl+C

---

### 4.3. CommonJS vs ES Modules

Node.js toetab kahte moodulistandardit:

#### CommonJS (traditsiooniline, vaikimisi)

```javascript
// Export
module.exports = {
  sum: (a, b) => a + b,
  multiply: (a, b) => a * b
};

// Import
const math = require('./math');
console.log(math.sum(2, 3)); // 5
```

#### ES Modules (modernne, ES6+)

```javascript
// Export
export const sum = (a, b) => a + b;
export const multiply = (a, b) => a * b;

// Import
import { sum, multiply } from './math.js';
console.log(sum(2, 3)); // 5
```

**ES Modules kasutamine Node.js-is:**

**Meetod 1:** Lisa `package.json`-i:
```json
{
  "type": "module"
}
```

**Meetod 2:** Kasuta `.mjs` faililaiendust:
```bash
node server.mjs
```

**Meie koolituses:** Kasutame **CommonJS** (lihtsam ja laialdasemalt toetatud).

---

## 5. Express.js Sissejuhatus

### 5.1. Mis on Express.js?

**Express.js** on minimalistlik ja paindlik **web framework** Node.js-ile.

#### Analoogia: Framework kui Tööriistakast

**Ilma Express-ta (pure Node.js):**
```javascript
// Routing käsitsi
if (req.url === '/users' && req.method === 'GET') {
  // ...
} else if (req.url === '/users' && req.method === 'POST') {
  // ...
} else if (req.url.startsWith('/users/')) {
  // ...
}
// Palju boilerplate koodi!
```

**Express-iga:**
```javascript
app.get('/users', (req, res) => { /* ... */ });
app.post('/users', (req, res) => { /* ... */ });
app.get('/users/:id', (req, res) => { /* ... */ });
// Lihtne ja selge!
```

---

### 5.2. Express Omadused

✅ **Routing** - URL-ide haldamine (GET, POST, PUT, DELETE)
✅ **Middleware** - Request/response tsükli manipuleerimine
✅ **Template engines** - HTML genereerimine (Pug, EJS)
✅ **Static files** - CSS, JS, pildid
✅ **Error handling** - Tsentraalse veatöötlus
✅ **Lihtsus** - Vähe boilerplate'i
✅ **Laiendatavus** - Tuhandeid middleware pakette

---

### 5.3. Express Paigaldamine

```bash
# Oled my-api kataloogis
cd ~/projects/my-api

# Paigalda Express
npm install express

# Kontrolli package.json
cat package.json
```

---

### 5.4. Esimene Express Server

```bash
# Loo fail
nano index.js
```

**Lisa sisu:**
```javascript
// Impordi Express
const express = require('express');

// Loo Express rakendus
const app = express();

// Määra port
const PORT = 3000;

// Määra route (marsruut)
app.get('/', (req, res) => {
  res.send('Hello from Express!');
});

// Käivita server
app.listen(PORT, () => {
  console.log(`Server töötab aadressil http://localhost:${PORT}`);
});
```

**Salvesta** ja **välju**.

**Käivita:**
```bash
node index.js

# Väljund:
# Server töötab aadressil http://localhost:3000
```

**Testi:**
- Brauser: http://localhost:3000
- Väljund: "Hello from Express!"

✅ **Express server töötab!**

---

### 5.5. Nodemon - Auto-restart

**Nodemon** taaskäivitab serveri automaatselt, kui failid muutuvad.

```bash
# Paigalda nodemon (dev dependency)
npm install --save-dev nodemon

# Lisa script package.json-i
# Redigeeri package.json:
nano package.json
```

**Lisa:**
```json
{
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  }
}
```

**Käivita:**
```bash
npm run dev

# Väljund:
# [nodemon] 3.0.1
# [nodemon] to restart at any time, enter `rs`
# [nodemon] watching path(s): *.*
# [nodemon] watching extensions: js,mjs,json
# [nodemon] starting `node index.js`
# Server töötab aadressil http://localhost:3000
```

**Nüüd muuda index.js:**
```javascript
app.get('/', (req, res) => {
  res.send('Hello from Express! (updated)');
});
```

**Salvesta** - Nodemon taaskäivitab automaatselt:
```
[nodemon] restarting due to changes...
[nodemon] starting `node index.js`
Server töötab aadressil http://localhost:3000
```

---

## 6. Routing ja HTTP Meetodid

### 6.1. HTTP Meetodid (Verbs)

| Meetod | CRUD | Kirjeldus | Näide |
|--------|------|-----------|-------|
| **GET** | Read | Loe andmeid | GET /users (kõik kasutajad) |
| **POST** | Create | Loo uus ressurss | POST /users (uus kasutaja) |
| **PUT** | Update | Uuenda ressurssi (täielik) | PUT /users/1 (uuenda kasutaja 1) |
| **PATCH** | Update | Uuenda ressurssi (osaline) | PATCH /users/1 (uuenda email) |
| **DELETE** | Delete | Kustuta ressurss | DELETE /users/1 (kustuta kasutaja 1) |

---

### 6.2. Routing Express-is

```javascript
const express = require('express');
const app = express();

// GET request
app.get('/users', (req, res) => {
  res.send('GET /users - Loe kõik kasutajad');
});

// POST request
app.post('/users', (req, res) => {
  res.send('POST /users - Loo uus kasutaja');
});

// PUT request
app.put('/users/:id', (req, res) => {
  const userId = req.params.id;
  res.send(`PUT /users/${userId} - Uuenda kasutaja ${userId}`);
});

// DELETE request
app.delete('/users/:id', (req, res) => {
  const userId = req.params.id;
  res.send(`DELETE /users/${userId} - Kustuta kasutaja ${userId}`);
});

app.listen(3000);
```

---

### 6.3. Route Parameters

**Route parameters** on dünaamilised URL-i osad:

```javascript
// :id on parameter
app.get('/users/:id', (req, res) => {
  const userId = req.params.id;
  res.send(`Kasutaja ID: ${userId}`);
});

// Mitu parameetrit
app.get('/users/:userId/posts/:postId', (req, res) => {
  const { userId, postId } = req.params;
  res.send(`Kasutaja ${userId}, postitus ${postId}`);
});
```

**Testi:**
- GET http://localhost:3000/users/42
- Vastus: "Kasutaja ID: 42"

---

### 6.4. Query Parameters

**Query parameters** on URL-i küsimärgi järel:

```javascript
// URL: /search?q=javascript&limit=10
app.get('/search', (req, res) => {
  const query = req.query.q;
  const limit = req.query.limit || 10; // vaikimisi 10

  res.send(`Otsing: "${query}", Limit: ${limit}`);
});
```

**Testi:**
- GET http://localhost:3000/search?q=nodejs&limit=5
- Vastus: `Otsing: "nodejs", Limit: 5`

---

### 6.5. Route Handlers

**Mitu handler'it järjestikku:**

```javascript
// Logger middleware (käivitub enne handler'it)
const logger = (req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next(); // Liigu edasi järgmisele
};

// Route koos logger'iga
app.get('/users', logger, (req, res) => {
  res.send('Kasutajad');
});
```

**Array of handlers:**
```javascript
const checkAuth = (req, res, next) => {
  // Kontrolli autentimist
  if (req.headers.authorization) {
    next();
  } else {
    res.status(401).send('Unauthorized');
  }
};

const getUser = (req, res) => {
  res.send('Autenditud kasutaja andmed');
};

app.get('/profile', [checkAuth, getUser]);
```

---

### 6.6. Router Object

**Express Router** võimaldab organiseerida route'sid:

```javascript
// routes/users.js
const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.send('Kõik kasutajad');
});

router.get('/:id', (req, res) => {
  res.send(`Kasutaja ${req.params.id}`);
});

router.post('/', (req, res) => {
  res.send('Loo kasutaja');
});

module.exports = router;
```

**index.js:**
```javascript
const express = require('express');
const app = express();

// Impordi router
const usersRouter = require('./routes/users');

// Mount router
app.use('/users', usersRouter);

app.listen(3000);
```

**Nüüd:**
- GET /users → "Kõik kasutajad"
- GET /users/42 → "Kasutaja 42"
- POST /users → "Loo kasutaja"

---

## 7. Middleware Kontseptsioon

### 7.1. Mis on Middleware?

**Middleware** on funktsioonid, mis töödeldakse **enne** route handler'it.

#### Analoogia: Lennujaama Turvakontroll

```
Reisija → Piletikontroll → Turvaskanner → Passi kontroll → Värav
   │           │                │               │           │
   └───────────┴────────────────┴───────────────┴───────────┘
              Middleware chain (ahel)
```

Iga samm saab:
- **Kontrollida** (authentication, validation)
- **Muuta** (parse body, add headers)
- **Lõpetada** (error, unauthorized)
- **Edasi saata** (`next()`)

---

### 7.2. Middleware Struktuur

```javascript
const myMiddleware = (req, res, next) => {
  // 1. Tee midagi request'iga
  console.log('Middleware executed');

  // 2. Muuda req või res objekti
  req.customProperty = 'Hello';

  // 3. Lõpeta response (või jätka)
  // res.send('Done'); // Lõpeta

  // 4. Kutsu next() jätkamiseks
  next();
};

app.use(myMiddleware); // Rakenda kõigile route'dele
```

---

### 7.3. Middleware Tüübid

#### 7.3.1. Application-level Middleware

```javascript
// Rakenda kõigile
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Rakenda konkreetsele path'ile
app.use('/api', (req, res, next) => {
  console.log('API request');
  next();
});
```

---

#### 7.3.2. Router-level Middleware

```javascript
const router = express.Router();

router.use((req, res, next) => {
  console.log('Router middleware');
  next();
});

router.get('/users', (req, res) => {
  res.send('Users');
});
```

---

#### 7.3.3. Built-in Middleware

Express sisaldab mõningaid built-in middleware:

```javascript
// Parsi JSON body
app.use(express.json());

// Parsi URL-encoded body (vormid)
app.use(express.urlencoded({ extended: true }));

// Staatic files (public kataloog)
app.use(express.static('public'));
```

**Näide: JSON body parsing**
```javascript
app.use(express.json());

app.post('/users', (req, res) => {
  console.log(req.body); // { name: "John", email: "john@example.com" }
  res.send('Kasutaja loodud');
});
```

---

#### 7.3.4. Third-party Middleware

Populaarsed middleware paketid:

```bash
# CORS (Cross-Origin Resource Sharing)
npm install cors

# Morgan (HTTP request logger)
npm install morgan

# Helmet (Security headers)
npm install helmet

# Compression (gzip)
npm install compression
```

**Kasutamine:**
```javascript
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');

app.use(cors());              // Luba CORS
app.use(morgan('combined'));  // Logi päringud
app.use(helmet());            // Turvalisuse headers
```

---

#### 7.3.5. Error-handling Middleware

**Error middleware** on erijuht - 4 parameetrit:

```javascript
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Midagi läks valesti!');
});
```

**Peab olema VIIMANE middleware!**

---

### 7.4. Middleware Järjekord

**Järjekord on oluline!**

```javascript
const express = require('express');
const app = express();

// 1. Logi iga request
app.use((req, res, next) => {
  console.log('1. Logger');
  next();
});

// 2. Parsi JSON
app.use(express.json());

// 3. Route
app.post('/users', (req, res) => {
  console.log('3. Route handler');
  res.send('OK');
});

// 4. Error handler (viimane!)
app.use((err, req, res, next) => {
  console.log('4. Error handler');
  res.status(500).send('Error!');
});
```

**Käivituse järjekord:** 1 → 2 → 3 (kui error, siis 4)

---

## 8. Request ja Response Objektid

### 8.1. Request Object (req)

**req** sisaldab kõike request'i kohta:

```javascript
app.get('/info', (req, res) => {
  console.log({
    method: req.method,           // GET
    url: req.url,                 // /info?page=1
    path: req.path,               // /info
    query: req.query,             // { page: '1' }
    params: req.params,           // { id: '42' } (kui /:id)
    headers: req.headers,         // { 'user-agent': '...', ... }
    body: req.body,               // { name: 'John' } (POST/PUT/PATCH)
    ip: req.ip,                   // Client IP
    hostname: req.hostname,       // localhost
    protocol: req.protocol        // http
  });

  res.send('Info logged');
});
```

---

### 8.2. Response Object (res)

**res** võimaldab saata vastust:

#### 8.2.1. Teksti Saatmine

```javascript
res.send('Hello');                    // Plain text
res.send('<h1>Hello</h1>');          // HTML
res.send({ message: 'Hello' });      // JSON (automaatselt)
```

---

#### 8.2.2. JSON Saatmine

```javascript
res.json({
  success: true,
  data: { id: 1, name: 'John' }
});

// Automaatselt seab Content-Type: application/json
```

---

#### 8.2.3. Status Code

```javascript
res.status(200).send('OK');
res.status(201).json({ message: 'Created' });
res.status(400).send('Bad Request');
res.status(404).send('Not Found');
res.status(500).send('Server Error');

// Katkesta ilma body'ta
res.sendStatus(404); // Saadab "Not Found"
```

---

#### 8.2.4. Redirect

```javascript
res.redirect('/new-url');
res.redirect(301, '/new-url'); // Permanent redirect
```

---

#### 8.2.5. Headers

```javascript
res.set('Content-Type', 'text/html');
res.set('X-Custom-Header', 'value');

// VÕI
res.header('Content-Type', 'text/html');
```

---

#### 8.2.6. Cookies

```javascript
// Seadista cookie
res.cookie('username', 'john', { maxAge: 900000, httpOnly: true });

// Kustuta cookie
res.clearCookie('username');
```

---

#### 8.2.7. File Download

```javascript
res.download('/path/to/file.pdf');
res.download('/path/to/file.pdf', 'custom-filename.pdf');
```

---

## 9. Environment Variables

### 9.1. Mis on Environment Variables?

**Environment variables** on konfiguratsioon, mis **erineb keskkonniti**:
- Development
- Staging
- Production

**Näited:**
- Andmebaasi URL
- API võtmed
- Port number
- JWT secret

---

### 9.2. .env Fail

**.env** fail hoiab secrets ja konfiguratsiooni:

```bash
# Loo .env fail
nano .env
```

**Lisa:**
```
# Server
PORT=3000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=StrongPassword123!

# JWT
JWT_SECRET=supersecretkey123456

# API Keys
API_KEY=your-api-key-here
```

**Salvesta** ja **välju**.

**OLULINE:** Lisa .env .gitignore'i!
```bash
echo ".env" >> .gitignore
```

---

### 9.3. dotenv Package

**dotenv** laeb .env faili environment variable'iteks:

```bash
# Paigalda dotenv
npm install dotenv
```

**index.js:**
```javascript
// Lae .env fail (ALATI ESIMESENA!)
require('dotenv').config();

const express = require('express');
const app = express();

// Kasuta environment variables
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

app.get('/', (req, res) => {
  res.json({
    environment: NODE_ENV,
    port: PORT,
    dbHost: process.env.DB_HOST
  });
});

app.listen(PORT, () => {
  console.log(`Server töötab port ${PORT}, env: ${NODE_ENV}`);
});
```

---

### 9.4. .env.example

**Loo .env.example** ilma väärtusteta (commit'i Git'i):

```bash
nano .env.example
```

**Lisa:**
```
# Server
PORT=
NODE_ENV=

# Database
DB_HOST=
DB_PORT=
DB_NAME=
DB_USER=
DB_PASSWORD=

# JWT
JWT_SECRET=

# API Keys
API_KEY=
```

**Commit:**
```bash
git add .env.example .gitignore
git commit -m "docs: Lisa .env.example ja ignoreeri .env"
```

---

### 9.5. Erinevad Keskkonnad

```bash
# Development
NODE_ENV=development npm run dev

# Production
NODE_ENV=production npm start
```

**Kood:**
```javascript
if (process.env.NODE_ENV === 'production') {
  // Production-specific logic
  app.use(compression());
} else {
  // Development-specific logic
  app.use(morgan('dev'));
}
```

---

## 10. Esimene REST API

### 10.1. REST Põhimõtted

**REST (Representational State Transfer)** on arhitektuuristiil API-dele.

**Põhimõtted:**
1. **Resource-based** - URL-id esindavad ressursse (`/users`, `/posts`)
2. **HTTP meetodid** - CRUD operatsioonid (GET, POST, PUT, DELETE)
3. **Stateless** - Iga request on sõltumatu
4. **JSON formaat** - Andmete vahetamine
5. **HTTP status koodid** - Standardsed vastuse koodid

---

### 10.2. API Struktuur

```
GET    /api/users       - Loe kõik kasutajad
GET    /api/users/:id   - Loe üks kasutaja
POST   /api/users       - Loo uus kasutaja
PUT    /api/users/:id   - Uuenda kasutaja (täielik)
PATCH  /api/users/:id   - Uuenda kasutaja (osaline)
DELETE /api/users/:id   - Kustuta kasutaja
```

---

### 10.3. In-Memory CRUD API

```javascript
// index.js
require('dotenv').config();
const express = require('express');
const app = express();

// Middleware
app.use(express.json());

// In-memory "andmebaas"
let users = [
  { id: 1, name: 'Alice', email: 'alice@example.com' },
  { id: 2, name: 'Bob', email: 'bob@example.com' }
];

let nextId = 3;

// === ROUTES ===

// GET /api/users - Kõik kasutajad
app.get('/api/users', (req, res) => {
  res.json({
    success: true,
    data: users
  });
});

// GET /api/users/:id - Üks kasutaja
app.get('/api/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const user = users.find(u => u.id === id);

  if (!user) {
    return res.status(404).json({
      success: false,
      error: 'Kasutajat ei leitud'
    });
  }

  res.json({
    success: true,
    data: user
  });
});

// POST /api/users - Loo uus kasutaja
app.post('/api/users', (req, res) => {
  const { name, email } = req.body;

  // Valideeri
  if (!name || !email) {
    return res.status(400).json({
      success: false,
      error: 'Nimi ja email on kohustuslikud'
    });
  }

  // Loo uus kasutaja
  const newUser = {
    id: nextId++,
    name,
    email
  };

  users.push(newUser);

  res.status(201).json({
    success: true,
    data: newUser
  });
});

// PUT /api/users/:id - Uuenda kasutaja
app.put('/api/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const { name, email } = req.body;

  const userIndex = users.findIndex(u => u.id === id);

  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'Kasutajat ei leitud'
    });
  }

  // Uuenda
  users[userIndex] = { id, name, email };

  res.json({
    success: true,
    data: users[userIndex]
  });
});

// DELETE /api/users/:id - Kustuta kasutaja
app.delete('/api/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const userIndex = users.findIndex(u => u.id === id);

  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      error: 'Kasutajat ei leitud'
    });
  }

  // Kustuta
  const deletedUser = users.splice(userIndex, 1)[0];

  res.json({
    success: true,
    data: deletedUser
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route ei leitud'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Serveri viga'
  });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API töötab aadressil http://localhost:${PORT}`);
});
```

---

### 10.4. API Testimine

#### cURL

```bash
# GET kõik kasutajad
curl http://localhost:3000/api/users

# GET üks kasutaja
curl http://localhost:3000/api/users/1

# POST uus kasutaja
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Charlie","email":"charlie@example.com"}'

# PUT uuenda kasutaja
curl -X PUT http://localhost:3000/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice Updated","email":"alice.new@example.com"}'

# DELETE kustuta kasutaja
curl -X DELETE http://localhost:3000/api/users/2
```

---

#### Postman / Insomnia

**GUI tööriistad API testimiseks:**

1. **Paigalda Postman:** https://www.postman.com/downloads/
2. Loo uus request
3. Määra:
   - **Method:** GET, POST, PUT, DELETE
   - **URL:** http://localhost:3000/api/users
   - **Body:** JSON (POST/PUT)
4. Saada request

---

## 11. Harjutused

### Harjutus 5.1: Node.js ja npm Seadistamine

**Eesmärk:** Paigaldada Node.js ja testida npm

**Sammud:**
1. Paigalda Node.js (NodeSource või nvm)
2. Kontrolli versioone: `node --version`, `npm --version`
3. Testi REPL: `node` → `console.log('Hello')`
4. Loo uus projekt: `npm init -y`
5. Paigalda pakett: `npm install lodash`
6. Kontrolli `node_modules/` ja `package.json`

---

### Harjutus 5.2: Esimene Express Server

**Eesmärk:** Luua töötav Express server

**Sammud:**
1. Loo kataloog `express-app`
2. `npm init -y`
3. `npm install express`
4. Loo `index.js`:
```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Hello Express!');
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```
5. Käivita: `node index.js`
6. Testi brauseris: http://localhost:3000

---

### Harjutus 5.3: Routing ja Middleware

**Eesmärk:** Harjutada routing'ut ja middleware

**Sammud:**
1. Lisa logger middleware:
```javascript
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});
```
2. Lisa route'id:
   - GET /about
   - GET /contact
   - GET /users/:id
3. Lisa 404 handler
4. Testi kõiki route'sid

---

### Harjutus 5.4: Environment Variables

**Eesmärk:** Kasutada .env faili

**Sammud:**
1. `npm install dotenv`
2. Loo `.env` fail:
```
PORT=4000
APP_NAME=My App
```
3. Muuda `index.js`:
```javascript
require('dotenv').config();
const PORT = process.env.PORT || 3000;
// ...
app.listen(PORT, () => {
  console.log(`${process.env.APP_NAME} on port ${PORT}`);
});
```
4. Lisa `.env` .gitignore'i
5. Loo `.env.example` (ilma väärtusteta)

---

### Harjutus 5.5: Täielik CRUD API

**Eesmärk:** Luua täisfunktsionaalne REST API

**Sammud:**
1. Kopeeri koodi sektsioonis 10.3
2. Käivita server
3. Testi kõiki endpoint'e:
   - GET /api/users
   - GET /api/users/:id
   - POST /api/users
   - PUT /api/users/:id
   - DELETE /api/users/:id
4. Kasuta Postman või cURL
5. Kontrolli, et kõik töötab

---

## 12. Kontrolliküsimused

### Teoreetilised Küsimused

1. **Mis on Node.js ja kuidas see erineb brauseri JavaScript'ist?**
   <details>
   <summary>Vastus</summary>
   Node.js on JavaScript runtime, mis võimaldab käivitada JavaScripti serveri poolel (väljaspool brauserit). Erinevus: Node.js-il on juurdepääs failisüsteemile, võrgule, protsessidele jne, mida brauseris ei ole turvalisuse tõttu.
   </details>

2. **Mis on Event Loop ja miks see on oluline?**
   <details>
   <summary>Vastus</summary>
   Event Loop on Node.js mehhanism, mis võimaldab non-blocking asynchronous I/O operatsioone, kuigi JavaScript on single-threaded. See jälgib callback queue'sid ja käivitab callback'e, kui call stack on tühi.
   </details>

3. **Mis vahe on dependencies ja devDependencies vahel?**
   <details>
   <summary>Vastus</summary>
   - dependencies: Paketid, mida rakendus vajab käivitamiseks (tootmises)
   - devDependencies: Paketid, mida vajad ainult arenduseks (testid, build tools)
   </details>

4. **Mis on middleware Express-is?**
   <details>
   <summary>Vastus</summary>
   Middleware on funktsioonid, mis käivitatakse request-response tsükli ajal enne route handler'it. Nad võivad muuta req/res objekte, lõpetada response'i või kutsuda next() edasi liikumiseks.
   </details>

5. **Mis on REST API ja millised on selle põhiprintsiibid?**
   <details>
   <summary>Vastus</summary>
   REST (Representational State Transfer) on arhitektuuristiil API-dele. Põhiprintsiibid: resource-based URL-id, HTTP meetodid (GET, POST, PUT, DELETE), stateless, JSON formaat, standardsed HTTP status koodid.
   </details>

---

### Praktilised Küsimused

6. **Kuidas paigaldada pakett npm-iga?**
   <details>
   <summary>Vastus</summary>
   ```bash
   npm install pakett-nimi
   # VÕI
   npm i pakett-nimi
   # Dev dependency:
   npm install --save-dev pakett-nimi
   ```
   </details>

7. **Kuidas luua Express server, mis kuulab pordil 3000?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   const express = require('express');
   const app = express();

   app.listen(3000, () => {
     console.log('Server running on port 3000');
   });
   ```
   </details>

8. **Kuidas määrata GET route Express-is?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   app.get('/path', (req, res) => {
     res.send('Response');
   });
   ```
   </details>

9. **Kuidas parsida JSON body Express-is?**
   <details>
   <summary>Vastus</summary>
   ```javascript
   app.use(express.json());
   ```
   </details>

10. **Kuidas saada route parameter väärtust?**
    <details>
    <summary>Vastus</summary>
    ```javascript
    app.get('/users/:id', (req, res) => {
      const id = req.params.id;
      res.send(`User ID: ${id}`);
    });
    ```
    </details>

11. **Kuidas laadida environment variables .env failist?**
    <details>
    <summary>Vastus</summary>
    ```javascript
    require('dotenv').config();
    const port = process.env.PORT;
    ```
    </details>

12. **Kuidas saata JSON response Express-is?**
    <details>
    <summary>Vastus</summary>
    ```javascript
    res.json({ success: true, data: { id: 1 } });
    ```
    </details>

---

## 13. Lisamaterjalid

### 📚 Soovitatud Lugemine

#### Node.js
- [Node.js Documentation](https://nodejs.org/docs/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
- [Understanding the Node.js Event Loop](https://nodejs.org/en/docs/guides/event-loop-timers-and-nexttick/)

#### Express.js
- [Express.js Official Documentation](https://expressjs.com/)
- [Express.js Guide](https://expressjs.com/en/guide/routing.html)
- [Express.js API Reference](https://expressjs.com/en/4x/api.html)

#### npm
- [npm Documentation](https://docs.npmjs.com/)
- [package.json Documentation](https://docs.npmjs.com/cli/v9/configuring-npm/package-json)

---

### 🛠️ Kasulikud Tööriistad

#### API Testing
- **Postman** - GUI API client
- **Insomnia** - Alternatiiv Postman'ile
- **Thunder Client** - VS Code extension
- **httpie** - Command-line HTTP client

```bash
# Paigalda httpie
sudo apt install httpie

# Kasuta
http GET http://localhost:3000/api/users
http POST http://localhost:3000/api/users name=John email=john@example.com
```

#### Development
- **nodemon** - Auto-restart
- **pm2** - Production process manager
- **nvm** - Node version manager

---

### 🎥 Video Ressursid

- **Traversy Media** - Node.js Crash Course
- **The Net Ninja** - Node.js Tutorial for Beginners
- **Academind** - Node.js - The Complete Guide
- **freeCodeCamp** - Learn Node.js - Full Tutorial

---

### 📖 Express.js Cheat Sheet

```javascript
// === Setup ===
const express = require('express');
const app = express();

// === Middleware ===
app.use(express.json());                    // Parse JSON
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded
app.use(express.static('public'));          // Static files

// === Routing ===
app.get('/path', (req, res) => {});         // GET
app.post('/path', (req, res) => {});        // POST
app.put('/path/:id', (req, res) => {});     // PUT
app.delete('/path/:id', (req, res) => {}); // DELETE

// === Request ===
req.params.id        // Route params
req.query.search     // Query params
req.body             // POST/PUT body
req.headers          // Headers
req.method           // HTTP method
req.path             // URL path

// === Response ===
res.send('text')               // Send text
res.json({ key: 'value' })     // Send JSON
res.status(404).send('Not Found') // Status + send
res.redirect('/new-url')       // Redirect

// === Error Handling ===
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Error!');
});

// === Start Server ===
app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

---

## Kokkuvõte

Selles peatükis said:

✅ **Õppisid Node.js arhitektuuri** - V8 engine, Event Loop, Non-blocking I/O
✅ **Paigaldasid Node.js** - Zorin OS ja VPS
✅ **Õppisid npm-i** - Pakettide paigaldamine, package.json
✅ **Lõid Express serveri** - Esimene web server
✅ **Õppisid routing'ut** - GET, POST, PUT, DELETE
✅ **Mõistsid middleware** - Logging, parsing, error handling
✅ **Töötasid Request/Response objektidega**
✅ **Kasutasid environment variables** - .env failid
✅ **Lõid esimese REST API** - Täielik CRUD

---

## Järgmine Peatükk

**Peatükk 6: PostgreSQL Integratsioon Node.js-iga**

Järgmises peatükis:
- node-postgres (pg) teek
- Connection pooling
- Ühendamine Docker ja välise PostgreSQL-iga
- SQL päringud Node.js-ist
- Parameetriseeritud päringud
- Error handling
- Transactions
- CRUD API PostgreSQL-iga

**API muutub päriseks!** 🚀 Asendame in-memory andmed PostgreSQL-iga.

---

## Troubleshooting

### Probleem 1: "Cannot find module 'express'"

**Lahendus:**
```bash
# Paigalda dependencies
npm install

# VÕI kui package.json puudub
npm install express
```

---

### Probleem 2: Port 3000 on juba kasutusel

**Lahendus:**
```bash
# Leia protsess pordil 3000
sudo lsof -i :3000

# VÕI
sudo netstat -tlnp | grep 3000

# Tapa protsess
kill -9 <PID>

# VÕI kasuta teist porti
PORT=4000 node index.js
```

---

### Probleem 3: nodemon ei tööta

**Lahendus:**
```bash
# Paigalda nodemon
npm install --save-dev nodemon

# Lisa package.json:
"scripts": {
  "dev": "nodemon index.js"
}

# Käivita
npm run dev
```

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-14
**Järgmine uuendus:** Peatükk 6 lisamine
