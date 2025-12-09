# .dockerignore Selgitus Algajale

## Mis on `.dockerignore`?

`.dockerignore` fail on nagu **filter**, mis ütleb Docker'ile: **"Ära kopeeri neid faile tõmmisesse (image)!"**

---

## Kuidas see töötab?

Kui sa ehitad Docker tõmmise käsuga:
```bash
docker build -t user-service:1.0 .
```

**Mis juhtub:**
1. Docker vaatab su rakenduse kausta (`.` = praegune kataloog)
2. Docker loeb `.dockerignore` faili
3. Dockerfile käsk `COPY . .` kopeerib **kõik failid VÄLJA ARVATUD** need, mis on `.dockerignore` failis

---

## Node.js `.dockerignore` Rea-haaval

```
node_modules
npm-debug.log
.env
.git
.gitignore
README.md
*.md
```

### 1. `node_modules`

**Mis see on?**
- Kaust, kus Node.js hoiab kõiki sõltuvusi (dependencies)
- `npm install` loob selle kausta ja laeb sinna tuhandeid faile

**Miks välistada?**
- ❌ **Host'i `node_modules` võib olla vale:** Sinu arvutis (host) võivad olla macOS/Windows sõltuvused, aga Docker konteineris jookseb Linux
- ❌ **Gigantne suurus:** `node_modules` võib olla 100-500MB
- ❌ **Aeglane kopeerimine:** Docker peab kopeerima tuhandeid väikeseid faile → väga aeglane
- ✅ **Dockerfile ehitab ise:** Dockerfile käsk `RUN npm install` loob **õiged** Linux-põhised sõltuvused konteineris

**Näide:**
```dockerfile
COPY package*.json ./   # Kopeeri ainult sõltuvuste nimekiri
RUN npm install          # Docker installib ise node_modules konteineris
COPY . .                 # Kopeeri rakenduse kood (aga mitte node_modules!)
```

---

### 2. `npm-debug.log`

**Mis see on?**
- Logifail, mille npm loob, kui `npm install` ebaõnnestub

**Miks välistada?**
- ❌ **Debug info host'ist pole vajalik:** See fail sisaldab vigu sinu arvutist, mitte Docker konteinerist
- ❌ **Võib olla tundlik info:** Debug logid võivad sisaldada failiteid, keskkonna infot
- ✅ **Tõmmis peab olema puhas:** Tootmises (production) ei peaks olema debug faile

---

### 3. `.env`

**Mis see on?**
- Fail, kus hoiad **salajasi väärtusi** (secrets):
  ```
  DB_PASSWORD=superSecret123
  JWT_SECRET=mySecretKey
  API_KEY=sk-proj-abc123xyz
  ```

**Miks välistada?**
- 🔥 **TURVARISK #1:** Kui `.env` läheb Docker tõmmisesse, siis:
  - Tõmmis salvestatakse Docker Hub'i → kogu maailm näeb su paroole
  - Tõmmis salvestatakse vahemälus (cache) → ei saa eemaldada
  - Kolleegid saavad tõmmise → näevad su production paroole
- ✅ **Õige viis:** Edasta saladused käivitamise ajal (runtime):
  ```bash
  docker run -e DB_PASSWORD=secret123 user-service:1.0
  ```

**Näide HALVAST tavast:**
```dockerfile
# ❌ VÄGA PAHA! Ära kunagi tee nii!
COPY .env .
ENV DB_PASSWORD=secret123   # Läheb tõmmisesse, kõik näevad!
```

**Näide ÕIGEST tavast:**
```bash
# ✅ ÕIGE! Saladused runtime'il
docker run \
  -e DB_PASSWORD=secret123 \
  -e JWT_SECRET=myKey \
  user-service:1.0
```

---

### 4. `.git`

**Mis see on?**
- Kaust, kus Git hoiab kogu versiooniajalogu

**Miks välistada?**
- ❌ **Suur suurus:** `.git` kaust võib olla 50-200MB (kogu projekt ajalugu)
- ❌ **Pole vaja runtime'il:** Tootmises pole vaja Git ajalugu
- ❌ **Võib sisaldada tundlikku infot:** Vanad commitid võivad sisaldada kustutatud paroole, API võtmeid
- ✅ **Tõmmis peab olema väike ja puhas**

---

### 5. `.gitignore`

**Mis see on?**
- Fail, mis ütleb Git'ile, milliseid faile mitte trackida

**Miks välistada?**
- ❌ **Pole vaja runtime'il:** `.gitignore` on ainult arendajatele
- ❌ **Tarbetu fail tõmmises:** Rakendus ei kasuta seda kunagi
- ✅ **Väiksem tõmmis**

---

### 6. `README.md` ja `*.md`

**Mis need on?**
- Dokumentatsioonifailid (Markdown)
- `README.md` - projekti kirjeldus
- `*.md` - kõik Markdown failid (CONTRIBUTING.md, CHANGELOG.md, jne)

**Miks välistada?**
- ❌ **Pole vaja runtime'il:** Dokumentatsioon on arendajatele, mitte tootmisele
- ❌ **Tarbetu sisu tõmmises:** Rakendus ei loe README faile
- ✅ **Väiksem tõmmis:** Iga megabait loeb!

**Erand:**
- Kui su rakendus **kuvab** dokumentatsiooni kasutajale (nt `/docs` endpoint), siis ÄRA välista `*.md`

---

## Java `.dockerignore` Rea-haaval

```
.gradle
build/
!build/libs/todo-service.jar
.env
.git
.gitignore
README.md
*.md
gradlew
gradlew.bat
```

### 1. `.gradle`

**Mis see on?**
- Gradle cache kaust (allalaetud sõltuvused, build cache)

**Miks välistada?**
- ❌ **Suur suurus:** Võib olla 100-500MB
- ❌ **Host'i cache pole vajalik:** Dockerfile käivitab Gradle konteineris, mis loob oma cache
- ✅ **Väiksem tõmmis**

---

### 2. `build/`

**Mis see on?**
- Gradle ehitatud failid (JAR, class failid, jne)

**Miks välistada?**
- ❌ **Host'i build võib olla vale:** Sinu arvutis võib olla vana versioon või vale Java versioon
- ✅ **Dockerfile ehitab ise:** Multi-stage Dockerfile käsk `RUN gradle bootJar` loob JAR'i konteineris

---

### 3. `!build/libs/todo-service.jar`

**Mis see on?**
- **Erand (negation pattern):** Luba kopeerida `todo-service.jar` fail, isegi kui `build/` on välistatud

**Millal kasutada?**
- Ainult kui kasutad **1-stage Dockerfile'i** (pre-built JAR)
- Multi-stage Dockerfile'is EI OLE vaja (builder stage ehitab JAR'i)

**Näide 1-stage Dockerfile (VPS):**
```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY build/libs/todo-service.jar app.jar  # Kopeerib host'i JAR'i
CMD ["java", "-jar", "app.jar"]
```

**Näide 2-stage Dockerfile (Corporate):**
```dockerfile
FROM gradle:8-jdk21 AS builder
RUN gradle bootJar  # Ehitab JAR'i konteineris

FROM eclipse-temurin:21-jre-alpine
COPY --from=builder /app/build/libs/*.jar app.jar  # Kopeerib builder stage'ist
CMD ["java", "-jar", "app.jar"]
```

---

### 4. `gradlew` ja `gradlew.bat`

**Mis need on?**
- Gradle wrapper skriptid (Unix ja Windows)

**Miks välistada?**
- ❌ **Pole vaja konteineris:** Kasutame `gradle:8-jdk21` base tõmmist, kus Gradle on juba installitud
- ✅ **Väiksem tõmmis**

**Erand:**
- Kui kasutad `./gradlew` käsku Dockerfile'is (mitte `gradle`), siis ÄRA välista

---

## Võrdlus: Ilma vs Koos `.dockerignore`

### ❌ Ilma `.dockerignore` (Node.js):
```bash
docker build -t user-service:1.0 .
# Kopeerib:
# - 500MB node_modules (vale OS!)
# - 50MB .git ajalugu
# - .env failid (PAROOLE!)
# - README.md (pole vaja)
# KOKKU: ~600MB tõmmis
```

### ✅ Koos `.dockerignore` (Node.js):
```bash
docker build -t user-service:1.0 .
# Kopeerib:
# - Ainult rakenduse kood (~5MB)
# - Dockerfile installib node_modules ise
# KOKKU: ~150MB tõmmis
```

---

### ❌ Ilma `.dockerignore` (Java):
```bash
docker build -t todo-service:1.0 .
# Kopeerib:
# - 300MB .gradle cache
# - 100MB build/ kaust
# - .env failid (PAROOLE!)
# - gradlew skriptid (pole vaja)
# KOKKU: ~500MB tõmmis
```

### ✅ Koos `.dockerignore` (Java):
```bash
docker build -t todo-service:1.0 .
# Kopeerib:
# - Ainult src/ kood (~2MB)
# - Gradle config failid (~50KB)
# - Dockerfile ehitab JAR'i ise
# KOKKU: ~230MB tõmmis
```

---

## Kokkuvõte

| Fail/kaust | Miks välistada? | Mõju |
|------------|-----------------|------|
| `node_modules` / `.gradle` | Vale OS, suur, Dockerfile ehitab ise | 🚀 Kiirem build, väiksem tõmmis |
| `.env` | 🔥 TURVARISK (paroole!) | 🔒 Turvalisem |
| `.git` | Suur, pole vaja runtime'il | 💾 Väiksem tõmmis |
| `README.md`, `*.md` | Dokumentatsioon, pole vaja runtime'il | 💾 Väiksem tõmmis |
| `npm-debug.log` | Debug info host'ist | 🧹 Puhas tõmmis |
| `build/` | Host'i build võib olla vale | 🚀 Dockerfile ehitab ise |
| `gradlew` | Base image sisaldab Gradle'i | 💾 Väiksem tõmmis |

---

## Millal kasutada `.dockerignore`?

**ALATI!** Iga Dockerfile vajab `.dockerignore` faili.

---

**Viimane uuendus:** 2025-12-05
**Tüüp:** Koodiselgitus
**Kasutatakse:** Lab 1 Harjutus 01a (Node.js), Lab 1 Harjutus 01b (Java)
