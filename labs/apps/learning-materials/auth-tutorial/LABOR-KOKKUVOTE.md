# 🎓 LABOR 1: KLIENDIFRONT ja MACHINEFRONT - Kokkuvõte

## 📋 Labori info

- **Nimi:** KLIENDIFRONT ja MACHINEFRONT Autentimine
- **Ajakulu:** 90-120 minutit (koos lõppülesannetega)
- **Raskusaste:** Algaja/Keskmine
- **Eeldused:** Põhilised Node.js, JavaScript ja HTTP teadmised

---

## 🎯 Õpiväljundid

Selle labori lõpuks õpilane:

### Teadmised
1. ✅ **Mõistab** KLIENDIFRONT (kasutaja) autentimise põhimõtteid
2. ✅ **Mõistab** MACHINEFRONT (masinatevaheline) autentimise põhimõtteid
3. ✅ **Teab** JWT tokeni struktuuri ja tööpõhimõtet
4. ✅ **Teab** API võtmete kasutamise parimaid tavasid
5. ✅ **Eristab**, millal kasutada kumba autentimismeetodit

### Oskused
1. ✅ **Oskab** implementeerida JWT autentimist Node.js/Express rakenduses
2. ✅ **Oskab** implementeerida API võtme autentimist
3. ✅ **Oskab** testida API endpoint'e curl ja Thunder Client abil
4. ✅ **Oskab** dekodeerida ja analüüsida JWT tokeneid
5. ✅ **Oskab** käsitleda autentimise vigu ja erandeid
6. ✅ **Oskab** rakendada rate limiting'ut API kaitseks

### Kompetentsid
1. ✅ **Suudab** valida sobiva autentimismeetodi vastavalt kasutusjuhtumile
2. ✅ **Suudab** ehitada turvalise REST API autentimisega
3. ✅ **Suudab** integreerida frontend ja backend autentimist
4. ✅ **Suudab** tuvastada ja parandada turvaauke autentimises

---

## 📚 Labori struktuur

### 12 sammu kokku:

1. **Mõistete selgitus** (5 min) - Teooria
2. **Paigaldamine** (10 min) - Keskkonna seadistamine
3. **KLIENDIFRONT veebilehel** (10 min) - Praktiline testimine
4. **KLIENDIFRONT käsurealt** (10 min) - cURL testimine
5. **MACHINEFRONT** (10 min) - API võtme kasutamine
6. **Kahe meetodi võrdlus** (5 min) - Analüüs
7. **Turvalisus ja häkkimine** (5 min) - Turvapraktikad
8. **JWT analüüs** (5 min) - Tokeni dekeerimine
9. **Veatöötlus** (10 min) - Error handling
10. **Thunder Client** (10 min) - API kliendi kasutamine
11. **Token aegumine** (5 min) - Session management
12. **Reaalsed kasutusjuhtumid** (5 min) - Praktilised näited

**Boonus: 3 lõppülesannet** (30 min)

---

## 📁 Projekti struktuur

```
labs/apps/
├── README.md                          # Projekti ülevaade ja API dok
├── LABOR.md                           # Põhjalik labori juhend
├── KONTROLLNIMEKIRI.md                # Edusammude jälgimine
├── LABOR-KOKKUVOTE.md                 # See fail
│
├── docker-compose.yml                 # Docker seadistus
├── test-kliendifront.sh              # Automaatne KLIENDIFRONT test
├── test-machinefront.sh              # Automaatne MACHINEFRONT test
├── thunder-client-collection.json     # API testide kollektsioon
├── thunder-client-env.json           # Keskkonna muutujad
│
├── backend-nodejs/
│   ├── package.json                   # Node.js sõltuvused
│   ├── server.js                      # Backend API (300+ rida)
│   ├── database-setup.sql             # PostgreSQL tabelid
│   ├── .env.example                   # Näidis konfiguratsioon
│   ├── .gitignore                     # Git ignore
│   └── Dockerfile                     # Docker konteiner
│
└── frontend/
    ├── index.html                     # Veebilehe HTML
    ├── styles.css                     # CSS kujundus
    └── app.js                         # Frontend loogika (300+ rida)
```

---

## 🔑 Põhimõisted

### KLIENDIFRONT (Client-Facing Authentication)

**Definitsioon:** Autentimismeetod, kus **inimkasutaja** logib sisse rakendusesse.

**Karakteristikud:**
- 👤 Kasutaja sisestab kredentsiaale (email + parool)
- 🎫 Server väljastab JWT tokeni
- ⏰ Token aegub (tavaliselt 15min - 1h)
- 🔐 Token saadetakse: `Authorization: Bearer <token>`
- 🎯 Kasutaja näeb ainult **oma** andmeid

**Näited:**
- Mobiilirakendus
- Veebileht
- Desktop rakendus
- SPA (Single Page Application)

### MACHINEFRONT (Machine-to-Machine Authentication)

**Definitsioon:** Autentimismeetod, kus **kaks teenust/süsteemi** suhtlevad omavahel.

**Karakteristikud:**
- 🤖 Teenus kasutab eelnevalt jagatud API võtit
- 🔑 Võti saadetakse: `X-API-Key: <key>`
- ♾️ Võti ei aegu (püsiv)
- 👑 Annab tavaliselt admin õigused
- 🌐 Näeb **kõiki** andmeid

**Näited:**
- Mikroteenused
- Serverless funktsioonid (Lambda, Cloud Functions)
- Scheduled jobs (Cron)
- CI/CD pipeline'id
- 3rd party integratsioonid

---

## 🔐 JWT (JSON Web Token)

### Struktuur

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiaWF0IjoxNjk5ODc2NTQzLCJleHAiOjE2OTk4ODAx NDN9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
     HEADER                                    PAYLOAD                                                                            SIGNATURE
```

### Header
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

### Payload
```json
{
  "id": 1,
  "email": "test@example.com",
  "username": "testuser",
  "iat": 1699876543,  // issued at
  "exp": 1699880143   // expiration
}
```

### Signature
```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  secret
)
```

### ⚠️ Olulised punktid:

1. JWT EI OLE krüpteeritud - see on Base64 encoded
2. Keegi saab tokenit LUGEDA, aga mitte MUUTA (allkiri kaitseb)
3. Token sisaldab infot - ära pane sinna sensitiivset infot (paroole!)
4. Token peaks aeguma - turvalisuse huvides

---

## 🛡️ Turvalisus

### Mida labor õpetab:

1. **Password hashing** - bcrypt (10 rounds)
2. **JWT signing** - HMAC SHA256
3. **SQL injection kaitse** - parameterized queries
4. **XSS kaitse** - HTML escaping
5. **Rate limiting** - API kuritarvitamise vältimiseks
6. **CORS** - Cross-origin requests
7. **Token expiration** - Session management

### Mida tootmises veel vaja:

- [ ] HTTPS (SSL/TLS)
- [ ] Refresh tokens
- [ ] Token revocation
- [ ] 2FA (Two-Factor Authentication)
- [ ] Password requirements (min length, complexity)
- [ ] Account lockout (brute force protection)
- [ ] Logging ja monitoring
- [ ] Secrets management (Vault, KMS)
- [ ] OWASP Top 10 järgimine

---

## 🧪 Testimise meetodid

Labors õpitakse 3 testimise meetodit:

### 1. cURL (käsurida)
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

**Plussid:**
- ✅ Kiire
- ✅ Skriptitav
- ✅ Pole vaja GUI'd

**Miinused:**
- ❌ Kompleksne süntaks
- ❌ Raske tokeneid hallata

### 2. Thunder Client (VS Code plugin)
```json
{
  "name": "Login",
  "method": "POST",
  "url": "{{baseUrl}}/auth/login",
  "body": {
    "email": "{{email}}",
    "password": "{{password}}"
  }
}
```

**Plussid:**
- ✅ Graafiline
- ✅ Muutujad ja keskkonnad
- ✅ Kollektsioonid
- ✅ Automaatne token salvestus

**Miinused:**
- ❌ Vajab VS Code'i
- ❌ Vähem paindlik kui cURL

### 3. Veebileht (frontend)
```javascript
const response = await fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password })
});
```

**Plussid:**
- ✅ Kasutajasõbralik
- ✅ Näitab real-world stsenaariumi
- ✅ Visuaalne feedback

**Miinused:**
- ❌ Aeglasem testimiseks
- ❌ Raskem automatiseerida

---

## 📊 HTTP vastuskoodid

Labor õpetab tundma olulisi HTTP koode:

| Kood | Nimi | Tähendus | Näide |
|------|------|----------|-------|
| 200 | OK | Edukas päring | GET /api/notes |
| 201 | Created | Ressurss loodud | POST /api/notes |
| 400 | Bad Request | Vigased andmed | Puuduvad väljad |
| 401 | Unauthorized | Puudub autentimine | Token puudub |
| 403 | Forbidden | Keelatud juurdepääs | Kehtetu token |
| 404 | Not Found | Ei leitud | Märget pole |
| 500 | Server Error | Serveri viga | DB viga |

---

## 🎯 Lõppülesanded

### Ülesanne 1: Admin Endpoint (lihtne)
Lisa endpoint, mis kustutab kõik kasutaja märkmed.

**Õpiväljund:** MACHINEFRONT endpoint'ide loomine

### Ülesanne 2: Refresh Token (keskmine)
Implementeeri refresh token mehhanism.

**Õpiväljund:** Session management, JWT parimad tavad

### Ülesanne 3: Rate Limiting (keskmine)
Lisa rate limiting admin endpoint'idele.

**Õpiväljund:** API kaitse, DoS preventsioon

---

## 📈 Järgmised sammud

Kui labor on läbitud, soovitame:

1. **OAuth 2.0** - Kolmanda osapoole autentimine (Google, Facebook)
2. **Passport.js** - Node.js autentimise raamistik
3. **Refresh Tokens** - Pikaajalised sessioonid
4. **SSO (Single Sign-On)** - Ühtne sisselogimine
5. **HTTPS** - SSL/TLS seadistamine
6. **API Gateway** - Kong, AWS API Gateway
7. **Identity Providers** - Auth0, Okta, Keycloak

---

## ✅ Kontrolli, kas labor on valmis

### Backend
- [ ] `package.json` - sõltuvused määratud
- [ ] `server.js` - kõik endpoint'id implementeeritud
- [ ] `.env.example` - näidis konfiguratsioon
- [ ] `database-setup.sql` - tabelid loodud
- [ ] `Dockerfile` - konteiner defineeritud

### Frontend
- [ ] `index.html` - UI struktureeritud
- [ ] `styles.css` - kujundus tehtud
- [ ] `app.js` - loogika implementeeritud

### Dokumentatsioon
- [ ] `README.md` - API dokumentatsioon
- [ ] `LABOR.md` - sammhaaval juhend
- [ ] `KONTROLLNIMEKIRI.md` - edusammude jälgimine

### Testimine
- [ ] `test-kliendifront.sh` - automaattestid
- [ ] `test-machinefront.sh` - admin testid
- [ ] `thunder-client-collection.json` - API kollektsioon

### Deployment
- [ ] `docker-compose.yml` - kõik teenused
- [ ] PostgreSQL andmebaas töötab
- [ ] Backend API töötab
- [ ] Frontend laadib

---

## 🎊 Kokkuvõte

**See labor annab:**
- ✅ Praktilise kogemuse kahe peamise autentimismeetodiga
- ✅ Arusaama JWT tokenite tööpõhimõttest
- ✅ Oskuse ehitada turvalisi REST API'sid
- ✅ Teadmised API testimisest
- ✅ Aluse edasiseks õppimiseks (OAuth, SSO, etc)

**Laboris loodud rakendust saab:**
- 🚀 Kasutada baasina reaalsetes projektides
- 📚 Viitena tulevikus
- 🎓 Portfoolios näitamiseks
- 🔧 Edasiarendamiseks (lisa funktsionaalsust!)

---

**Edu laboriga! 🎉**

Kui teil on küsimusi või leiate vigu, palun looge issue GitHub'is või võtke ühendust õppejõuga.

---

*Labor koostatud: 2025-11-15*
*Versio: 1.0*
*Autor: Hostinger VPS õppematerjalid*
