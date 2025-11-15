# 🧪 LABOR: KLIENDIFRONT ja MACHINEFRONT Autentimine

## 📚 Eesmärk

Selles laboris õpid:
1. ✅ Mis on KLIENDIFRONT ja MACHINEFRONT autentimine
2. ✅ Kuidas JWT tokenid töötavad
3. ✅ Kuidas API võtmed töötavad
4. ✅ Millal kasutada kumbagi meetodit

## ⏱️ Ajakulu: ~45 minutit

---

## SAMM 1: Mõistete selgitus (5 min)

### KLIENDIFRONT (Client-Facing)
**Kasutaja autentimine** - kasutatakse, kui **inimene** kasutab rakendust

**Näide:** Sa logid sisse Gmail'i:
1. Sisestademaili ja parooli
2. Server kontrollib parooli
3. Server väljastab sulle **JWT tokeni**
4. Edaspidi kasutad seda tokenit kõikides päringutes
5. Token **aegub pärast 1 tundi** (turvalisuse huvides)

```
Kasutaja → Email + Parool → Server → JWT Token → Päringud
```

### MACHINEFRONT (Machine-to-Machine)
**Masinate autentimine** - kasutatakse, kui **kaks teenust** suhtlevad omavahel

**Näide:** Stripe makse-API räägib sinu serveriga:
1. Sul on eelnevalt **jagatud API võti**
2. Iga päring sisaldab seda võtit
3. Võti **ei aegu** (jääb samaks)
4. Võti annab tavaliselt **admin õigused**

```
Teenus A → API Key → Teenus B → Vastus
```

### Võrdlus

| | KLIENDIFRONT | MACHINEFRONT |
|--|--------------|--------------|
| **Kasutaja** | Inimene | Masin/Teenus |
| **Login** | Email + Parool | API võti |
| **Token** | JWT (ajutine) | API Key (püsiv) |
| **Aegub** | Jah (1h) | Ei |
| **Header** | `Authorization: Bearer <token>` | `X-API-Key: <key>` |

---

## SAMM 2: Paigaldamine (10 min)

### Variant A: Docker Compose (kiirem)

```bash
cd labs/apps

# Käivita kõik teenused
docker-compose up -d

# Kontrolli, et kõik töötab
docker-compose ps

# Vaata logisid
docker-compose logs -f backend
```

**Valmis!**
- Backend: http://localhost:3000
- Frontend: http://localhost:8080
- PostgreSQL: localhost:5432

### Variant B: Manuaalne paigaldus

```bash
cd labs/apps/backend-nodejs

# 1. Paigalda sõltuvused
npm install

# 2. Seadista PostgreSQL
sudo systemctl start postgresql
sudo -u postgres psql -f database-setup.sql

# 3. Seadista .env
cp .env.example .env
nano .env
```

Muuda `.env` failis:
```env
JWT_SECRET=mingi-turvaline-võti-12345
API_KEY=mingi-api-võti-67890
```

```bash
# 4. Käivita server
npm start
```

Ava teine terminal:
```bash
cd labs/apps/frontend

# 5. Käivita frontend
python3 -m http.server 8000
```

**Valmis!**
- Backend: http://localhost:3000
- Frontend: http://localhost:8000

---

## SAMM 3: KLIENDIFRONT testimine veebilehel (10 min)

1. **Ava veebileht:** http://localhost:8000

2. **Registreeru:**
   - Kasutajanimi: `oma_nimi`
   - Email: `test@example.com`
   - Parool: `test123`
   - Vajuta "Registreeru"

3. **Logi sisse:**
   - Email: `test@example.com`
   - Parool: `test123`
   - Vajuta "Logi sisse"

4. **Lisa märkmeid:**
   - Pealkiri: "Ostunimekiri"
   - Sisu: "Piim, leib, juust"
   - Vajuta "Lisa märge"

5. **Testi funktsioone:**
   - Lisa veel märkmeid
   - Muuda märget
   - Kustuta märge
   - Logi välja ja sisse

**❓ Küsimused:**
- Mis juhtub, kui logid välja? (märkmed kaovad ekraanilt)
- Mis juhtub, kui logid uuesti sisse? (märkmed tulevad tagasi)
- Kust tuleb JWT token? (vaata browser DevTools → Network → Headers)

---

## SAMM 4: KLIENDIFRONT testimine käsurealt (10 min)

```bash
cd labs/apps

# 1. Tee testimise skript käivitatavaks
chmod +x test-kliendifront.sh

# 2. Käivita test
./test-kliendifront.sh
```

**Mida skript teeb?**
1. ✅ Registreerib uue kasutaja
2. ✅ Logib sisse ja saab JWT tokeni
3. ✅ Loob märkme (kasutades tokenit)
4. ✅ Hangib kõik märkmed (kasutades tokenit)
5. ✅ Proovib ilma tokenita (ebaõnnestub)

**Analüüsi väljundit:**

```json
{
  "message": "Sisselogimine edukas",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiaWF0IjoxNjk5...",
  "user": {
    "id": 1,
    "username": "testuser",
    "email": "test@example.com"
  }
}
```

**❓ Ülesanded:**
1. Kopeeri JWT token siit: https://jwt.io ja vaata, mis sees on
2. Muuda skripti nii, et see loob 3 märget
3. Proovi käsitsi curl'iga päringut teha

---

## SAMM 5: MACHINEFRONT testimine (10 min)

```bash
cd labs/apps

# 1. Muuda skriptis API võtit
nano test-machinefront.sh

# Muuda rida:
API_KEY="your-api-key-here"  # ← Pane siia .env failis olev API_KEY

# 2. Tee skript käivitatavaks
chmod +x test-machinefront.sh

# 3. Käivita test
./test-machinefront.sh
```

**Mida skript teeb?**
1. ✅ Hangib KÕIK märkmed (admin juurdepääs)
2. ✅ Hangib statistika (kasutajate arv, märkmete arv)
3. ✅ Proovib vale võtmega (ebaõnnestub)
4. ✅ Proovib ilma võtmeta (ebaõnnestub)

**Analüüsi väljundit:**

```json
{
  "notes": [
    {
      "id": 1,
      "title": "Esimene märge",
      "content": "Test",
      "username": "testuser",
      "email": "test@example.com"
    }
  ]
}
```

**❓ Pane tähele:**
- MACHINEFRONT näeb **kõikide kasutajate** märkmeid
- KLIENDIFRONT näeb ainult **oma** märkmeid

---

## SAMM 6: Võrdle kahte meetodit (5 min)

### Testimisülesanne

1. **Käivita mõlemad testid:**
```bash
./test-kliendifront.sh > kliendifront.txt
./test-machinefront.sh > machinefront.txt

# Võrdle
diff kliendifront.txt machinefront.txt
```

2. **Kontrolli päiseid:**
```bash
# KLIENDIFRONT
curl -v http://localhost:3000/api/notes \
  -H "Authorization: Bearer <su-token>"

# MACHINEFRONT
curl -v http://localhost:3000/api/admin/stats \
  -H "X-API-Key: <su-võti>"
```

**❓ Küsimused:**
- Kumba kasutad mobiilirakenduses? (KLIENDIFRONT)
- Kumba kasutad kahe serveri vahel? (MACHINEFRONT)
- Kumb on turvalisem? (Mõlemad võrdselt, kui õigesti tehtud)

---

## SAMM 7: Turvalisus ja häkkimine (5 min)

### Testimisülesanded

1. **Proovi JWT tokenit muuta:**
```bash
# Võta token test-kliendifront.sh väljundist
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Muuda viimast tähte
FAKE_TOKEN="${TOKEN:0:-5}XXXXX"

# Proovi kasutada
curl http://localhost:3000/api/notes \
  -H "Authorization: Bearer $FAKE_TOKEN"

# Tulemus: "Kehtetu või aegunud token" ✅
```

2. **Proovi API võtit ära arvata:**
```bash
curl http://localhost:3000/api/admin/stats \
  -H "X-API-Key: 123456"

# Tulemus: "Kehtetu API võti" ✅
```

3. **SQL Injection katse:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com OR 1=1--", "password": "test"}'

# Tulemus: Ei tööta, sest kasutame parameterized queries ✅
```

**❓ Miks need ei tööta?**
- JWT on krüptograafiliselt allkirjastatud
- API võti on serveris turvaliselt salvestatud
- SQL päringud on parameteriseeritud

---

## SAMM 8: JWT Tokeni dekodeerimine ja analüüs (5 min)

### Harjutus 1: Dekodeeri JWT token

```bash
# 1. Hangi token test skriptist
./test-kliendifront.sh | grep -A 1 "token"

# Kopeeri token väärtus
```

**Külasta:** https://jwt.io

**Kleebi token** Debugger sektsiooni ja vaata, mis sees on:

```json
{
  "id": 1,
  "email": "test@example.com",
  "username": "testuser",
  "iat": 1699876543,
  "exp": 1699880143
}
```

**❓ Küsimused:**
- Mis on `iat` (issued at)?
- Mis on `exp` (expiration)?
- Kas sa näed parooli? (EI - JWT ei sisalda parooli!)
- Kas keegi saab tokenit lugeda? (JAH - Base64, mitte krüpteering!)

### Harjutus 2: Loo oma JWT

Kasuta Node.js konsooli:

```bash
node
```

```javascript
const jwt = require('jsonwebtoken');

// Loo oma token
const token = jwt.sign(
  { userId: 123, role: 'admin' },
  'my-secret-key',
  { expiresIn: '1h' }
);

console.log('Token:', token);

// Dekodeeri
const decoded = jwt.decode(token);
console.log('Decoded:', decoded);

// Kontrolli allkirja
try {
  const verified = jwt.verify(token, 'my-secret-key');
  console.log('✅ Token on kehtiv:', verified);
} catch (error) {
  console.log('❌ Token on kehtetu');
}
```

---

## SAMM 9: Veatöötlus ja vigade käsitlemine (10 min)

### Harjutus 1: Testi erinevaid vigu

```bash
# 1. Vale email
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "wrong@example.com", "password": "test123"}'

# Oodatav: {"error": "Vale email või parool"}

# 2. Vale parool
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "wrong"}'

# Oodatav: {"error": "Vale email või parool"}

# 3. Puuduvad väljad
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test2@example.com"}'

# Oodatav: Serveri viga või valideerimise viga

# 4. Aegunud token (oota 1h või muuda JWT_EXPIRES_IN=1s)
# Logi sisse, oota, proovi kasutada

# 5. Kehtetu API võti
curl http://localhost:3000/api/admin/stats \
  -H "X-API-Key: wrong-key"

# Oodatav: {"error": "Kehtetu API võti"}
```

### Harjutus 2: HTTP vastuskoodid

Õpi tundma erinevaid HTTP koode:

| Kood | Tähendus | Näide |
|------|----------|-------|
| 200 | OK | Edukas päring |
| 201 | Created | Uus kasutaja loodud |
| 400 | Bad Request | Puuduvad väljad |
| 401 | Unauthorized | Puudub token |
| 403 | Forbidden | Kehtetu token |
| 404 | Not Found | Märget ei leitud |
| 500 | Server Error | Andmebaasi viga |

```bash
# Kontrolli vastuskoode
curl -i http://localhost:3000/api/notes
# HTTP/1.1 401 Unauthorized

curl -i http://localhost:3000/api/notes \
  -H "Authorization: Bearer fake-token"
# HTTP/1.1 403 Forbidden
```

---

## SAMM 10: Postman/Thunder Client kasutamine (10 min)

### VS Code Thunder Client

1. **Paigalda Thunder Client:**
   - Ava VS Code
   - Extensions → otsi "Thunder Client"
   - Paigalda

2. **Loo uus päring:**
   - Thunder Client → New Request
   - POST `http://localhost:3000/api/auth/login`
   - Body → JSON:
   ```json
   {
     "email": "test@example.com",
     "password": "test123"
   }
   ```
   - Send

3. **Salvesta token:**
   - Kopeeri `token` väärtus vastusest
   - Loo uus päring: GET `http://localhost:3000/api/notes`
   - Headers → Lisa `Authorization: Bearer <token>`
   - Send

### Loo Thunder Client kollektsioon

```json
{
  "clientName": "Thunder Client",
  "collectionName": "Notes API",
  "requests": [
    {
      "name": "Login",
      "method": "POST",
      "url": "http://localhost:3000/api/auth/login",
      "body": {
        "email": "{{email}}",
        "password": "{{password}}"
      }
    },
    {
      "name": "Get Notes",
      "method": "GET",
      "url": "http://localhost:3000/api/notes",
      "headers": {
        "Authorization": "Bearer {{token}}"
      }
    }
  ]
}
```

---

## SAMM 11: Token aegumise testimine (5 min)

### Harjutus: Muuda tokeni aegumisaeg

1. **Muuda .env:**
```bash
nano backend-nodejs/.env

# Muuda
JWT_EXPIRES_IN=10s  # 10 sekundit
```

2. **Taaskäivita server:**
```bash
npm start
```

3. **Testi:**
```bash
# Logi sisse ja salvesta token
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  | jq -r '.token')

# Kohe kasutades - peaks töötama
curl http://localhost:3000/api/notes \
  -H "Authorization: Bearer $TOKEN"

# Oota 15 sekundit
sleep 15

# Proovi uuesti - peaks ebaõnnestuma
curl http://localhost:3000/api/notes \
  -H "Authorization: Bearer $TOKEN"

# Oodatav: {"error": "Kehtetu või aegunud token"}
```

**❓ Miks see oluline on?**
- Turvalisus: kui token varastatakse, on aega kasutada ainult 10s
- Tootmises: tavaliselt 15min - 1h
- Pikemaks sessiooniks: kasuta refresh token'eid

---

## SAMM 12: Reaalsed kasutusjuhtumid (5 min)

### Näide 1: Mobiilirakendus

**Stsenaarium:** Sul on mobiilirakendus, mis näitab kasutaja märkmeid.

```
KLIENDIFRONT kasutamine:

1. Kasutaja avatab rakenduse
2. Rakendus kontrollib: kas token localStorage'is?
3. Kui EI → näita login ekraani
4. Kui JAH → kontrolli, kas token on aegunud
5. Kui aegunud → näita login ekraani
6. Kui kehtiv → lae märkmed

Login protsess:
1. Kasutaja sisestab email + parool
2. Rakendus saadab POST /api/auth/login
3. Server tagastab JWT tokeni
4. Rakendus salvestab tokeni
5. Kõik järgnevad päringud sisaldavad tokenit
```

### Näide 2: Mikroteenused

**Stsenaarium:** Sul on Notes API ja Notification API.

```
MACHINEFRONT kasutamine:

Notes API                 Notification API
    |                            |
    |  Kasutaja loob märkme      |
    |--------------------------->|
    |  X-API-Key: secret123      |
    |  POST /api/notifications   |
    |  { userId: 1, message: ... }|
    |                            |
    |<---------------------------|
    |  { sent: true }            |

Notes API kasutab API võtit, et rääkida Notification API-ga
```

### Näide 3: Serverless funktsioonid

**Stsenaarium:** AWS Lambda funktsioon, mis töötleb märkmeid.

```javascript
// Lambda funktsioon
exports.handler = async (event) => {
  const API_KEY = process.env.API_KEY;

  // Hangi kõik märkmed
  const response = await fetch('https://api.example.com/api/admin/notes', {
    headers: {
      'X-API-Key': API_KEY
    }
  });

  const notes = await response.json();

  // Töötle märkmeid
  // ...
};
```

---

## 🎯 Lõppülesanne: Loo oma API

### Ülesanne 1: Admin endpoint

**Lisa uus MACHINEFRONT endpoint, mis kustutab KÕIK kasutaja märkmed.**

```javascript
// backend-nodejs/server.js

app.delete('/api/admin/users/:userId/notes', authenticateMachine, async (req, res) => {
  // TODO: Implementeeri
  // 1. Hangi userId parameetrist
  // 2. Kustuta kõik selle kasutaja märkmed
  // 3. Tagasta kustutatud märkmete arv
});
```

**Testimine:**
```bash
curl -X DELETE http://localhost:3000/api/admin/users/1/notes \
  -H "X-API-Key: your-api-key"

# Vastus:
# {"message": "Kustutatud 5 märget"}
```

### Ülesanne 2: Refresh Token

**Lisa refresh token funktsioon.**

1. Muuda login endpoint nii, et tagastab ka refresh tokeni
2. Loo uus endpoint `/api/auth/refresh`, mis võtab refresh tokeni ja annab uue access tokeni
3. Testi curl'iga

<details>
<summary>Vihje</summary>

```javascript
// Login
const accessToken = jwt.sign(payload, secret, { expiresIn: '15m' });
const refreshToken = jwt.sign(payload, refreshSecret, { expiresIn: '7d' });

// Refresh endpoint
app.post('/api/auth/refresh', (req, res) => {
  const { refreshToken } = req.body;

  try {
    const decoded = jwt.verify(refreshToken, refreshSecret);
    const newAccessToken = jwt.sign(
      { id: decoded.id, email: decoded.email },
      secret,
      { expiresIn: '15m' }
    );

    res.json({ token: newAccessToken });
  } catch (error) {
    res.status(403).json({ error: 'Kehtetu refresh token' });
  }
});
```
</details>

### Ülesanne 3: Rate Limiting

**Lisa rate limiting MACHINEFRONT endpoint'idele.**

Paigalda `express-rate-limit`:
```bash
npm install express-rate-limit
```

Implementeeri:
```javascript
const rateLimit = require('express-rate-limit');

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutit
  max: 100, // max 100 päringut
  message: 'Liiga palju päringuid, proovi hiljem uuesti'
});

app.use('/api/admin', apiLimiter);
```

**Testi:**
```bash
# Tee 101 päringut kiiresti
for i in {1..101}; do
  curl http://localhost:3000/api/admin/stats \
    -H "X-API-Key: your-api-key"
done

# 101. päring peaks ebaõnnestuma
```

---

## ✅ Kontrolli oma teadmised

1. **Mis on erinevus KLIENDIFRONT ja MACHINEFRONT vahel?**
   <details>
   <summary>Vastus</summary>

   KLIENDIFRONT = kasutaja autentimine (email+parool → JWT token)
   MACHINEFRONT = masinate autentimine (API võti)
   </details>

2. **Mis on JWT token?**
   <details>
   <summary>Vastus</summary>

   JSON Web Token - krüptograafiliselt allkirjastatud andmepakk, mis sisaldab kasutaja infot ja aegub pärast teatud aega.
   </details>

3. **Millal kasutad API võtit?**
   <details>
   <summary>Vastus</summary>

   Kui kaks teenust/serverit suhtlevad omavahel ilma kasutaja sekkumiseta (machine-to-machine).
   </details>

4. **Kas JWT token tuleb serveris salvestada?**
   <details>
   <summary>Vastus</summary>

   EI! JWT on stateless - server kontrollib ainult allkirja. Token salvestatakse kliendi poolel (localStorage, cookie).
   </details>

5. **Mis juhtub, kui JWT token varastatakse?**
   <details>
   <summary>Vastus</summary>

   Varas saab seda kasutada kuni token aegub. Lahendus: lühike aegumine (1h) + refresh tokenid + HTTPS.
   </details>

---

## 📚 Lisalugemine

- JWT standardid: https://jwt.io
- OAuth 2.0: https://oauth.net/2/
- API autentimine: https://restfulapi.net/security-essentials/

## 🎉 Õnnitleme!

Oled läbinud KLIENDIFRONT ja MACHINEFRONT labori!

**Järgmised sammud:**
1. Õpi OAuth 2.0 (Google/Facebook login)
2. Õpi Refresh Tokenite kasutamist
3. Õpi API rate limiting'ut
4. Õpi HTTPS seadistamist

Edu!
