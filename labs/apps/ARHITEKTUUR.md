# 🏗️ Rakenduse Arhitektuur - Mida Iga Teenus Teeb?

**Viimane uuendus:** 2025-11-16

---

## 🎯 Ülevaade

See on **mikroteenuste arhitektuur** - üks rakendus jagatud kolmeks iseseisvaks teenuseks.

**Analoogia:** Kui oleks restoran:
- **Frontend** = Menüü ja tellimislaud (klient näeb seda)
- **User Service** = Kassasüsteem (kes sa oled, kas oled sisse loginud)
- **Todo Service** = Köök (teeb su tellimusi)
- **PostgreSQL** = Raamatupidamine (hoiab kõike)

---

## 📊 Arhitektuuriskeem

```
┌─────────────────────────────────────────────────────────────┐
│                      KASUTAJA (Brauser)                     │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Port 8080)                     │
│   Mida teeb: Kuvab kasutajaliidesed (login, todo list)    │
│   Tehnoloogia: HTML + CSS + JavaScript                     │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               │ POST /api/auth/login         │ POST /api/todos
               │ (kasutajanimi, parool)       │ (pealkiri, kirjeldus)
               │                              │
               ▼                              ▼
┌───────────────────────────┐   ┌────────────────────────────┐
│   USER SERVICE (3000)     │   │  TODO SERVICE (8081)       │
│                           │   │                            │
│ Mida teeb:                │   │ Mida teeb:                 │
│ • Kontrollib kasutajaid   │   │ • Haldab TODO märkmeid     │
│ • Login/logout            │   │ • Lisa, muuda, kustuta     │
│ • Annab JWT tokeni        │   │ • Märgi tehtuks            │
│ • Kontrollib õigusi       │   │ • Näita statistikat        │
│                           │   │                            │
│ Tehnoloogia:              │   │ Tehnoloogia:               │
│ Node.js + Express         │   │ Java + Spring Boot         │
└────────────┬──────────────┘   └──────────────┬─────────────┘
             │                                  │
             │ SQL Queries                      │ SQL Queries
             │                                  │
             ▼                                  ▼
┌───────────────────────────┐   ┌────────────────────────────┐
│ POSTGRESQL (5432)         │   │ POSTGRESQL (5433)          │
│                           │   │                            │
│ Andmebaas:                │   │ Andmebaas:                 │
│ user_service_db           │   │ todo_service_db            │
│                           │   │                            │
│ Tabelid:                  │   │ Tabelid:                   │
│ • users                   │   │ • todos                    │
│   - id                    │   │   - id                     │
│   - name                  │   │   - user_id (viide)        │
│   - email                 │   │   - title                  │
│   - password_hash         │   │   - description            │
│   - role (user/admin)     │   │   - completed              │
│                           │   │   - priority               │
└───────────────────────────┘   └────────────────────────────┘
```

---

## 🔍 Iga Teenuse Detailne Selgitus

### 1️⃣ Frontend - Kasutajaliides

**Mida see TEEB?**
- Kuvab sisselogimise vormi
- Kuvab todo nimekirja
- Võimaldab lisada/muuta/kustutada todo'sid
- Näitab veateateid ja eduteate

**Miks see on VAJALIK?**
- Kasutaja ei saa otse API'ga suhelda
- Vajab graafilist liidest (HTML/CSS)
- Brauser ei mõista JSON'i ilma JavaScript'ita

**Kuidas see TÖÖTAB?**
1. Laeb HTML/CSS/JavaScript failid
2. JavaScript teeb päringuid API'dele
3. Kuvab vastused kasutajale

**Näide workflow:**
```
Kasutaja sisestab email + parool
    ↓
Frontend saadab POST /api/auth/login
    ↓
User Service kontrollib ja tagastab JWT tokeni
    ↓
Frontend salvestab tokeni localStorage'i
    ↓
Iga järgmine päring sisaldab: Authorization: Bearer <token>
```

**Labrites:**
- Õpid, kuidas serveerida static faile (Nginx)
- Õpid, kuidas suunata /api/ päringud backend'ile (reverse proxy)
- Õpid CORS probleeme lahendama

---

### 2️⃣ User Service - Autentimine ja Kasutajahaldus

**Mida see TEEB?**
- **Registreerimine:** Loo uus kasutaja (hash parool bcrypt'iga)
- **Login:** Kontrolli email+parool, anna JWT token
- **Autoriseerimine:** Kontrolli, kas kasutajal on õigus (user vs admin)
- **Kasutajahaldus:** CRUD operatsioonid kasutajatele

**Miks see on ERALDI teenus?**
- ✅ **Turvalisus:** Autentimine on kriitiline, peab olema isoleeritud
- ✅ **Korduvkasutatavus:** Teised teenused (Todo, Payment, jne) kasutavad sama User Service't
- ✅ **Skaleerumine:** Kui palju login'e → lisa rohkem User Service pod'e
- ✅ **Tehnoloogia:** Node.js on kiire I/O jaoks (palju paralleelseid login'e)

**Kuidas see TÖÖTAB?**

**Registreerimine:**
```javascript
POST /api/auth/register
{
  "name": "Janek",
  "email": "janek@example.com",
  "password": "parool123"
}

↓ Backend:
1. Kontrolli, kas email juba eksisteerib
2. Hash parool bcrypt'iga (turvalisus)
3. Salvesta andmebaasi
4. Tagasta: { message: "User registered successfully" }
```

**Login:**
```javascript
POST /api/auth/login
{
  "email": "janek@example.com",
  "password": "parool123"
}

↓ Backend:
1. Leia kasutaja email'i järgi
2. Võrdle parooli bcrypt.compare()
3. Loo JWT token (sisaldab: id, email, role)
4. Tagasta: { token: "eyJhbG...", user: {...} }
```

**JWT Token Näide:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NSwiZW1haWwiOiJqYW5la0BleGFtcGxlLmNvbSIsInJvbGUiOiJ1c2VyIn0.SIGNATURE
        ↑                              ↑                                                    ↑
     Header                         Payload                                             Signature
                                  (kasutaja info)
```

**Miks JWT?**
- ✅ Stateless - backend ei pea sessioone mäletama
- ✅ Self-contained - kõik info on tokenis
- ✅ Secure - signatuur takistab võltsimist
- ✅ Expires - token aegub 1h pärast

**Labrites:**
- Õpid, kuidas JWT töötab mikroteenustes
- Õpid environment variables (JWT_SECRET)
- Õpid Secrets management Kubernetes'es

---

### 3️⃣ Todo Service - Äriloogika

**Mida see TEEB?**
- **CRUD:** Create, Read, Update, Delete TODO märkmeid
- **Filtreerimine:** Näita ainult lõpetatud / pooleliolevaid
- **Statistika:** Kui palju TODO'sid, completion rate
- **Autentimise kontrollimine:** Kontrolli JWT tokenit (ei tee ise login'e!)

**Miks see on ERALDI teenus?**
- ✅ **Vastutuse jaotus:** User Service = autentimine, Todo Service = äriloogika
- ✅ **Sõltumatus:** Võid lisada Payment Service, Blog Service, jne ilma User Service'i puudutamata
- ✅ **Tehnoloogia valik:** Java Spring Boot on hea äriloogika jaoks (type safety, enterprise patterns)
- ✅ **Skaleerumine:** Kui palju TODO'sid → lisa rohkem Todo Service pod'e

**Kuidas see TÖÖTAB?**

**JWT Validatsioon:**
```
1. Frontend saadab: Authorization: Bearer <token>
2. Todo Service ekstraktib tokeni
3. Valideerib signatuuri (sama JWT_SECRET nagu User Service'il!)
4. Ekstraktib user_id tokenist
5. Kasutab user_id, et filtreerida todo'sid
```

**Miks jagab JWT_SECRET'iga?**
- User Service LOOB tokeni
- Todo Service VALIDEERIB tokeni
- Mõlemad peavad kasutama SAMA SECRET'i

**Loo TODO:**
```javascript
POST /api/todos
Authorization: Bearer eyJhbG...
{
  "title": "Õpi Docker",
  "description": "Tee Lab 1 harjutused",
  "priority": "high"
}

↓ Backend:
1. Valideeri JWT token → saa user_id = 5
2. Loo todo:
   - user_id: 5 (tokenist)
   - title: "Õpi Docker"
   - completed: false
3. Salvesta andmebaasi
4. Tagasta: { id: 10, user_id: 5, title: "Õpi Docker", ... }
```

**Loe TODO'sid (ainult MINU todo'd):**
```javascript
GET /api/todos
Authorization: Bearer eyJhbG...

↓ Backend:
1. Valideeri JWT → user_id = 5
2. SELECT * FROM todos WHERE user_id = 5
3. Tagasta: [{ id: 10, title: "Õpi Docker" }, ...]
```

**TÄHTIS:** Todo Service EI näe teiste kasutajate todo'sid!

**Labrites:**
- Õpid mikroteenuste vahelist autentimist (shared JWT secret)
- Õpid JVM tuning Docker'is
- Õpid Gradle build'e CI/CD'is
- Õpid Java metrics Prometheus'es

---

### 4️⃣ PostgreSQL - Andmebaas

**Mida see TEEB?**
- Hoiab kõiki andmeid püsivalt
- Kontrollib andmete terviklust (constraints)
- Tagab ACID omadused (Atomicity, Consistency, Isolation, Durability)

**Miks KAKS andmebaasi?**
```
postgres-user (port 5432)  → user_service_db
postgres-todo (port 5433)  → todo_service_db
```

**Põhjused:**
- ✅ **Isolatsioon:** Iga teenus omab oma andmeid
- ✅ **Skaleerumine:** Võid skaleerida igaüht eraldi
- ✅ **Backup:** Võid backupida igaüht eraldi
- ✅ **Turvalisus:** Kui Todo DB kompromiteeritakse, User DB on turvaline
- ✅ **Arendus:** Tiimid võivad töötada iseseisvalt

**Labrites:**
- Õpid StatefulSet Kubernetes'es (andmebaas vajab püsivat storage't)
- Õpid PersistentVolumes
- Õpid database migrations
- Õpid backupe

---

## 🔄 Täielik Workflow Näide

### Stsenaarium: Kasutaja lisab uue TODO

**Samm 1: Kasutaja logib sisse**
```
Brauser → POST /api/auth/login (email, parool)
    ↓
User Service:
  1. Kontrollib parooli
  2. Loob JWT token: { id: 5, email: "janek@...", role: "user" }
  3. Tagastab tokeni
    ↓
Brauser salvestab tokeni localStorage'i
```

**Samm 2: Kasutaja avab TODO lehe**
```
Brauser → GET /api/todos
Authorization: Bearer <token>
    ↓
Todo Service:
  1. Valideerib tokenit (kontrollib signatuuri)
  2. Ekstraktib user_id = 5
  3. SELECT * FROM todos WHERE user_id = 5
  4. Tagastab: []  (kasutajal pole veel todo'sid)
    ↓
Brauser kuvab: "Sul pole veel ühtegi märget"
```

**Samm 3: Kasutaja lisab TODO**
```
Brauser → POST /api/todos
Authorization: Bearer <token>
{
  "title": "Õpi Kubernetes",
  "priority": "high"
}
    ↓
Todo Service:
  1. Valideerib tokenit → user_id = 5
  2. INSERT INTO todos (user_id, title, priority, completed)
     VALUES (5, 'Õpi Kubernetes', 'high', false)
  3. Tagastab: { id: 42, user_id: 5, title: "Õpi Kubernetes", ... }
    ↓
Brauser kuvab: "Märge lisatud!" ja näitab uut TODO'd
```

**Samm 4: Kasutaja märgib TODO tehtuks**
```
Brauser → PATCH /api/todos/42/complete
Authorization: Bearer <token>
    ↓
Todo Service:
  1. Valideerib tokenit → user_id = 5
  2. Kontrollib: SELECT * FROM todos WHERE id = 42 AND user_id = 5
     (tagab, et see on kasutaja oma TODO)
  3. UPDATE todos SET completed = true WHERE id = 42
  4. Tagastab: { id: 42, completed: true, ... }
    ↓
Brauser kuvab: "TODO märgitud tehtuks!" ja kuvab rohelise tärni
```

---

## 🎓 Miks Mikroteenused?

### Monolith vs Mikroteenused

**Monolith (üks suur rakendus):**
```
┌────────────────────────────┐
│   Kõik ühes rakenduses     │
│   - Users                  │
│   - Todos                  │
│   - Payments               │
│   - Blog                   │
│   - ...                    │
└────────────────────────────┘
```

**Probleemid:**
- ❌ Raske skaleerida (kui Users vajab rohkem ressursse, pead skaleerima KÕIKE)
- ❌ Deploy = restart KÕIK (kui uuendad Todos, läheb ka Users alla)
- ❌ Üks bug võib kukutada KÕIK
- ❌ Raske arendada (kõik tiimid töötavad samas koodis)

**Mikroteenused:**
```
┌──────────┐  ┌──────────┐  ┌──────────┐
│  Users   │  │  Todos   │  │ Payments │
└──────────┘  └──────────┘  └──────────┘
```

**Eelised:**
- ✅ Skaleeri ainult seda, mida vaja (rohkem login'e → rohkem User Service pod'e)
- ✅ Deploy iseseisvalt (uuenda Todos ilma Users'i puudutamata)
- ✅ Tõrketaluvus (kui Todos crashib, Users töötab edasi)
- ✅ Tehnoloogia valik (Users = Node.js, Todos = Java)
- ✅ Tiimid töötavad iseseisvalt

**Puudused:**
- ❌ Keerukam (rohkem moving parts)
- ❌ Network latency (teenused peavad suhtlema üle võrgu)
- ❌ Raske debugida (vead võivad olla mitmes teenuses)
- ❌ DevOps skills VAJALIKUD (Docker, Kubernetes, monitoring)

**Selles kursuses õpidki, kuidas mikroteenuseid hallata!**

---

## 🛠️ Labrite Kontekstis

### Lab 1: Docker Basics
**Fookus:** Üks teenus (User Service)
- Õpid kontaineriseerimist lihtsalt
- Ei pea muretsema teenuste vahelist suhtlust

### Lab 2: Docker Compose
**Fookus:** Kõik teenused koos
- Õpid orkestratsiooni
- Õpid teenuste vahelist suhtlust (networking)
- Õpid environment variables

### Lab 3-4: Kubernetes
**Fookus:** Tootmislik skaleerimine
- Õpid High Availability
- Õpid Autoscaling
- Õpid Load Balancing

### Lab 5: CI/CD
**Fookus:** Automatiseerimine
- Õpid automaatseid build'e
- Õpid teste
- Õpid deploye

### Lab 6: Monitoring
**Fookus:** Observability
- Õpid metrics (Prometheus)
- Õpid logs (Loki)
- Õpid alerting

---

## 📊 Kokkuvõte

| Teenus | Vastutus | Tehnoloogia | Port | Miks vajalik? |
|--------|----------|-------------|------|---------------|
| **Frontend** | UI/UX | HTML/JS | 8080 | Kasutaja suhtlus |
| **User Service** | Autentimine | Node.js | 3000 | Login, JWT |
| **Todo Service** | Äriloogika | Java | 8081 | TODO CRUD |
| **PostgreSQL** | Andmed | SQL | 5432/5433 | Püsiv storage |

**Kõik koos = Täisfunktsionaalne TODO rakendus mikroteenustes!**

---

**Viited:**
- `/home/janek/projects/hostinger/labs/apps/README.md` - Tehniline dokumentatsioon
- `/home/janek/projects/hostinger/labs/README.md` - Labrite ülevaade
- `/home/janek/projects/hostinger/labs/apps/TESTIMINE.md` - Kuidas testida

---

**Viimane uuendus:** 2025-11-16
