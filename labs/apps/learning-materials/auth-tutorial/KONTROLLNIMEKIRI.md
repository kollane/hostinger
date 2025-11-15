# ✅ Labori Kontrollnimekiri

Märgi kõik läbi tehtud ülesanded.

## 📚 Ettevalmistus

- [ ] Olen lugenud README.md faili
- [ ] Olen lugenud LABOR.md faili
- [ ] Mõistan erinevust KLIENDIFRONT ja MACHINEFRONT vahel

---

## 🔧 SAMM 1: Mõistete selgitus (5 min)

- [ ] Mõistan, mis on KLIENDIFRONT
- [ ] Mõistan, mis on MACHINEFRONT
- [ ] Olen vaadanud võrdlustabelit
- [ ] Tean, millal kumba meetodit kasutada

**Küsimused:**
- [ ] Saan vastata: Mis on JWT token?
- [ ] Saan vastata: Mis on API võti?
- [ ] Saan vastata: Mis vahe on JWT ja API Key vahel?

---

## 🚀 SAMM 2: Paigaldamine (10 min)

### Variant A: Docker Compose
- [ ] Käivitasin `docker-compose up -d`
- [ ] Kontrollisin `docker-compose ps`
- [ ] Näen, et kõik teenused töötavad
- [ ] Backend vastab: http://localhost:3000/health
- [ ] Frontend laadib: http://localhost:8080

### Variant B: Manuaalne
- [ ] Paigaldasin `npm install`
- [ ] Lõin `.env` faili
- [ ] Seadistasin PostgreSQL andmebaasi
- [ ] Käivitasin backend serveri
- [ ] Käivitasin frontend serveri
- [ ] Backend vastab: http://localhost:3000/health

---

## 🌐 SAMM 3: KLIENDIFRONT veebilehel (10 min)

- [ ] Avasin veebilehe http://localhost:8000
- [ ] Registreerisin uue kasutaja
- [ ] Logisin sisse
- [ ] Lisasin 3 märget
- [ ] Muutsin märget
- [ ] Kustutasin märke
- [ ] Logisin välja ja sisse uuesti
- [ ] Kontrollisin DevTools → Network → Headers
- [ ] Nägin JWT tokenit päringutes

**Küsimused:**
- [ ] Kus token salvestatakse? (localStorage)
- [ ] Mis juhtub, kui logid välja? (token kustutatakse)
- [ ] Kas märkmed jäävad alles peale välja logimist? (JAH, andmebaasis)

---

## 💻 SAMM 4: KLIENDIFRONT käsurealt (10 min)

- [ ] Tegin skripti käivitatavaks: `chmod +x test-kliendifront.sh`
- [ ] Käivitasin `./test-kliendifront.sh`
- [ ] Nägin, kuidas registreerimine töötab
- [ ] Nägin, kuidas JWT token väljastatakse
- [ ] Nägin, kuidas tokenit kasutatakse
- [ ] Testisin ilma tokenita (ebaõnnestus ✅)

**Harjutused:**
- [ ] Kopeerisin JWT tokeni ja vaatasin jwt.io lehel
- [ ] Mõistan JWT struktuuri (header.payload.signature)
- [ ] Proovisin curl'iga käsitsi päringut teha
- [ ] Muutsin skripti, et see loob 3 märget

---

## 🤖 SAMM 5: MACHINEFRONT käsurealt (10 min)

- [ ] Muutsin `test-machinefront.sh` failis API võtit
- [ ] Tegin skripti käivitatavaks: `chmod +x test-machinefront.sh`
- [ ] Käivitasin `./test-machinefront.sh`
- [ ] Nägin KÕIKI kasutajate märkmeid (admin juurdepääs)
- [ ] Sain statistika (kasutajate ja märkmete arv)
- [ ] Testisin vale API võtmega (ebaõnnestus ✅)
- [ ] Testisin ilma API võtmeta (ebaõnnestus ✅)

**Küsimused:**
- [ ] Mis erinevus on KLIENDIFRONT ja MACHINEFRONT tulemuste vahel?
- [ ] Miks MACHINEFRONT näeb kõiki märkmeid?
- [ ] Kus API võti salvestatakse? (.env fail)

---

## 🔍 SAMM 6: Võrdle kahte meetodit (5 min)

- [ ] Käivitasin mõlemad testid ja salvestasin väljundi
- [ ] Võrdlesin tulemusi `diff` käsuga
- [ ] Kontrollisin HTTP päiseid `curl -v` abil
- [ ] Mõistan erinevust KLIENDIFRONT ja MACHINEFRONT vahel

**Küsimused:**
- [ ] Kumba kasutan mobiilirakenduses? (KLIENDIFRONT)
- [ ] Kumba kasutan mikroteenuste vahel? (MACHINEFRONT)
- [ ] Kumb on turvalisem? (Mõlemad võrdselt, kui õigesti)

---

## 🛡️ SAMM 7: Turvalisus ja häkkimine (5 min)

- [ ] Proovisin JWT tokenit muuta (ebaõnnestus ✅)
- [ ] Proovisin API võtit ära arvata (ebaõnnestus ✅)
- [ ] Proovisin SQL injection'it (ebaõnnestus ✅)

**Küsimused:**
- [ ] Miks JWT muutmine ei tööta? (krüptograafiline allkiri)
- [ ] Miks SQL injection ei tööta? (parameterized queries)
- [ ] Mis juhtub, kui JWT varastatakse? (varas saab kasutada kuni token aegub)

---

## 🔐 SAMM 8: JWT Tokeni analüüs (5 min)

- [ ] Hangin tokeni test skriptist
- [ ] Külastsin jwt.io lehte
- [ ] Dekodeerisin tokeni
- [ ] Nägin payload sisu (id, email, username, iat, exp)
- [ ] Mõistan, et JWT EI ole krüpteeritud (Base64 kodeering)

**Node.js harjutus:**
- [ ] Avasin Node.js konsooli
- [ ] Lõin oma JWT tokeni
- [ ] Dekodeerisin tokeni
- [ ] Kontrollisin allkirja

**Küsimused:**
- [ ] Mis on `iat`? (issued at - millal token loodi)
- [ ] Mis on `exp`? (expiration - millal token aegub)
- [ ] Kas parool on tokenis? (EI!)
- [ ] Kas keegi saab tokenit lugeda? (JAH - Base64)

---

## ⚠️ SAMM 9: Veatöötlus (10 min)

- [ ] Testisin vale emailiga
- [ ] Testisin vale parooliga
- [ ] Testisin puuduvate väljadega
- [ ] Testisin kehtetu API võtmega
- [ ] Kontrollisin HTTP vastuskoode (200, 401, 403, 404, 500)

**HTTP koodide tundmine:**
- [ ] Tean, mis on 200 (OK)
- [ ] Tean, mis on 401 (Unauthorized)
- [ ] Tean, mis on 403 (Forbidden)
- [ ] Tean, mis on 404 (Not Found)
- [ ] Tean, mis on 500 (Server Error)

---

## 🔧 SAMM 10: Thunder Client (10 min)

- [ ] Paigaldasin Thunder Client VS Code'is
- [ ] Importisin `thunder-client-collection.json`
- [ ] Importisin `thunder-client-env.json`
- [ ] Muutsin `apiKey` väärtust keskkonnas
- [ ] Testisin registreerimist
- [ ] Testisin sisselogimist
- [ ] Token salvestus automaatselt
- [ ] Testisin märkmete hankimist
- [ ] Testisin märkme loomist

**Boonus:**
- [ ] Lõin oma kollektsiooni
- [ ] Lisasin muutujad (variables)
- [ ] Testisin kõiki endpoint'e

---

## ⏰ SAMM 11: Token aegumine (5 min)

- [ ] Muutsin `.env` failis `JWT_EXPIRES_IN=10s`
- [ ] Taaskäivitasin serveri
- [ ] Logisin sisse ja salvestasin tokeni
- [ ] Testisin kohe (töötab ✅)
- [ ] Ootasin 15 sekundit
- [ ] Testisin uuesti (ebaõnnestub ✅)

**Küsimused:**
- [ ] Miks token aegub? (turvalisus)
- [ ] Kui kaua peaks token tootmises kehtima? (15min - 1h)
- [ ] Kuidas pikendada sessiooni? (refresh token)

---

## 🌍 SAMM 12: Reaalsed kasutusjuhtumid (5 min)

- [ ] Lugesin mobiilirakenduse näite
- [ ] Lugesin mikroteenuste näite
- [ ] Lugesin serverless funktsioonide näite
- [ ] Mõistan, millal kumba meetodit kasutada

**Küsimused:**
- [ ] Millal kasutad KLIENDIFRONT? (kasutaja + rakendus)
- [ ] Millal kasutad MACHINEFRONT? (teenus + teenus)
- [ ] Kas võib kasutada mõlemat korraga? (JAH!)

---

## 🎯 Lõppülesanded

### Ülesanne 1: Admin endpoint
- [ ] Lõin uue endpoint'i `/api/admin/users/:userId/notes`
- [ ] Endpoint kasutab `authenticateMachine`
- [ ] Endpoint kustutab kõik kasutaja märkmed
- [ ] Endpoint tagastab kustutatud märkmete arvu
- [ ] Testisin curl'iga
- [ ] Endpoint töötab ✅

### Ülesanne 2: Refresh Token
- [ ] Muutsin login endpoint'i
- [ ] Login tagastab ka refresh tokeni
- [ ] Lõin `/api/auth/refresh` endpoint'i
- [ ] Refresh endpoint väljastab uue access tokeni
- [ ] Testisin curl'iga
- [ ] Refresh token töötab ✅

### Ülesanne 3: Rate Limiting
- [ ] Paigaldasin `express-rate-limit`
- [ ] Lisasin rate limiting'u admin endpoint'idele
- [ ] Seadistasin 100 päringut 15 minuti kohta
- [ ] Testisin 101 päringuga
- [ ] 101. päring ebaõnnestus ✅

---

## ✅ Teadmiste kontroll

### Põhiküsimused
- [ ] Saan selgitada KLIENDIFRONT vs MACHINEFRONT
- [ ] Saan selgitada JWT tokeni
- [ ] Saan selgitada API võtit
- [ ] Saan selgitada, millal kumba kasutada
- [ ] Saan selgitada, miks JWT ei ole krüpteeritud
- [ ] Saan selgitada, miks token aegub

### Praktilised oskused
- [ ] Oskan luua JWT tokeni
- [ ] Oskan dekodeerida JWT tokeni
- [ ] Oskan testida API'sid curl'iga
- [ ] Oskan testida API'sid Thunder Client'iga
- [ ] Oskan lugeda HTTP vastuskoode
- [ ] Oskan käsitleda vigu

### Turvalisus
- [ ] Mõistan JWT allkirja tähtsust
- [ ] Mõistan tokeni aegumise tähtsust
- [ ] Mõistan API võtme turvalisust
- [ ] Mõistan SQL injection'i ohtu
- [ ] Mõistan rate limiting'u tähtsust

---

## 🎉 Labori lõpetamine

**Kui oled märkinud kõik ülal olevad kastid, oled edukalt läbinud labori!**

### Järgmised sammud:
- [ ] Õpi OAuth 2.0
- [ ] Õpi Refresh Tokenite kasutamist
- [ ] Õpi HTTPS seadistamist
- [ ] Õpi API Gateway'de kasutamist
- [ ] Õpi CORS-i seadistamist

### Boonus ülesanded:
- [ ] Lisa email verification registreerimisel
- [ ] Lisa parooli taastamine
- [ ] Lisa 2FA (Two-Factor Authentication)
- [ ] Lisa WebSocket ühendus reaalajas uuendusteks
- [ ] Lisa GraphQL API

---

**Õnnitleme! 🎊**

Oled nüüd valmis töötama autentimise ja autoriseerimisega reaalsetes projektides!
