# Harjutus 1: Ühe Konteineri Käivitamine

**Kestus:** 45 minutit
**Eesmärk:** Konteinerise Java Spring Boot Todo teenus (service) ja õpi Dockerfile'i loomist

---

## ⚠️ OLULINE: Harjutuse Fookus

**See harjutus keskendub Docker põhitõdede õppimisele, MITTE töötavale rakendusele!**

✅ **Õpid:**
- Dockerfile'i loomist
- Docker pildi (image) ehitamist
- Konteineri käivitamist
- Logide vaatamist ja debuggimist
- Docker käskude kasutamist

❌ **Rakendus (application) EI TÖÖTA täielikult:**
- Todo teenus (service) vajab PostgreSQL andmebaasi
- Konteiner käivitub, aga hangub kohe (see on **OODATUD**)
- Töötava rakenduse (application) saad **Harjutus 2**-s (mitme konteineri käivitamine)

**Miks see hea on?**
- Õpid debuggima probleeme (`docker logs`, `docker exec`)
- Mõistad, miks rakendused (applications) vajavad omavahel suhtlemist
- Näed, kuidas Docker vea (error) sõnumid välja näevad

---

## 📋 Ülevaade

Selles harjutuses konteineriseerid Java Spring Boot Todo teenuse (service) rakenduse (application). Õpid looma Dockerfile'i, ehitama Docker pilti (image) ja käivitama konteinereid (isegi kui see hangub andmebaasi puudumise tõttu).

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua Dockerfile'i Java Spring Boot rakendusele (application)
- ✅ Ehitada Docker pilti (image)
- ✅ Käivitada ja peatada konteinereid
- ✅ Kasutada keskkonna muutujaid (environment variables)
- ✅ Vaadata konteineri logisid
- ✅ Debuggida konteineri probleeme

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────┐
│   Docker Konteiner          │
│                             │
│  ┌───────────────────────┐  │
│  │  Java Rakendus        │  │
│  │  Todo Teenus          │  │
│  │  Port: 8081           │  │
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
          │
          │ Portide vastendamine
          │
    localhost:8081
```

---

## 📝 Sammud

### Samm 1: Tutvu Rakendusega (5 min)

**Rakenduse juurkataloog:** `/hostinger/labs/apps/backend-java-spring`

Vaata Todo teenuse (service) koodi:

```bash
cd ../apps/backend-java-spring

# Vaata faile
ls -la

# Loe README
cat README.md

# Vaata build.gradle
cat build.gradle
```

**Küsimused:**
- Millise pordiga rakendus (application) käivitub? (8081)
- Millised sõltuvused on vajalikud? (vaata build.gradle)
- Kas rakendus (application) vajab andmebaasi? (Jah, PostgreSQL)

### Samm 2: Loo Dockerfile (15 min)

Loo fail nimega `Dockerfile`:

**⚠️ Oluline:** Dockerfail tuleb luua rakenduse juurkataloogi `/hostinger/labs/apps/backend-java-spring`

```bash
vim Dockerfile
```

**Ülesanne:** Kirjuta Dockerfile, mis:
1. Kasutab Java 17 JRE alpine baaspilti (base image)
2. Seadistab töökataloogiks `/app`
3. Kopeerib JAR faili (eeldab, et ehitamine on tehtud)
4. Avaldab pordi 8081
5. Käivitab rakenduse (application)

**Märkus:** See on lihtne Dockerfile, mis eeldab, et JAR fail on juba ehitatud. Optimeeritud versioonis (Harjutus 5) lisame mitme-sammulise (multi-stage) ehitamise.

**💡 Abi vajadusel:**
- Vaata Docker dokumentatsiooni: https://docs.docker.com/engine/reference/builder/
- Vaata näidislahendust lahenduste kataloogis: `/hostinger/labs/01-docker-lab/solutions/backend-java-spring/Dockerfile`

**💡 Näpunäide: Dockerfile struktuur**

```dockerfile
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Kopeeri JAR fail
COPY build/libs/todo-service.jar app.jar

# Avalda port
EXPOSE 8081

# Käivita rakendus (application)
CMD ["java", "-jar", "app.jar"]
```

### Samm 3: Loo .dockerignore (5 min)

Loo `.dockerignore` fail, et vältida tarbetute failide kopeerimist:

**⚠️ Oluline:** .dockerignore tuleb luua rakenduse juurkataloogi `/hostinger/labs/apps/backend-java-spring`

```bash
vim .dockerignore
```

**💡 Abi vajadusel:**
Vaata näidislahendust: `/hostinger/labs/01-docker-lab/solutions/backend-java-spring/.dockerignore`

**Sisu:**
```
.gradle
build/
!build/libs/todo-service.jar
.env
.git
.gitignore
README.md
*.md
src/
gradlew
gradlew.bat
```

**Miks see oluline on?**
- Väiksem pildi (image) suurus
- Kiirem ehitamine
- Turvalisem (ei kopeeri .env faile)
- Ei kopeeri lähtekoodi (ainult JAR fail)

### Samm 4: Ehita Docker pilt (image) (10 min)

**Asukoht:** `/hostinger/labs/apps/backend-java-spring`

Esmalt ehita JAR fail, seejärel Docker pilt (image):

**⚠️ Oluline:** Nii JAR-i kui ka Docker pildi (image) ehitamiseks pead olema rakenduse (application) juurkataloogis (kus asuvad `build.gradle` ja `Dockerfile`).

```bash
# Build JAR fail
./gradlew clean bootJar

# Kontrolli, et JAR on loodud
ls -lh build/libs/

# Ehita Docker pilt (image) tagiga
docker build -t todo-service:1.0 .

# Vaata ehitamise protsessi
# Märka: iga käsk loob uue kihi (layer)
```

**Kontrolli pilti (image):**

```bash
# Vaata kõiki pilte (images)
docker images

# Vaata todo-service pildi (image) infot
docker image inspect todo-service:1.0

# Kontrolli suurust
docker images todo-service:1.0
```

**Küsimused:**
- Kui suur on sinu pilt (image)? (peaks olema ~200-250MB)
- Mitu kihti (layers) on pildil (image)?
- Millal pilt (image) loodi?

### Samm 5: Käivita Konteiner (10 min)

**⚠️ OLULINE:** Järgnevad käsud käivitavad konteineri, aga rakendus (application) hangub, sest PostgreSQL puudub. See on **OODATUD** käitumine! Fookus on õppida Docker käske, mitte saada töötav rakendus (application).

#### Variant A: Interaktiivne režiim (näed kohe vigasid (errors))

**See variant on PARIM õppimiseks** - näed kohe, mida juhtub:

```bash
# Käivita konteiner interaktiivselt
# MÄRKUS: DB_HOST on vale, seega hangub (see on ÕIGE käitumine!)
docker run -it --name todo-service-test \
  -p 8081:8081 \
  -e DB_HOST=nonexistent-db \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-test-secret-key-min-32-chars-long \
  todo-service:1.0
```

**Märkused:**
- `-it` - interactive + tty (näed logisid real-time)
- `--name` - anna konteinerile nimi
- `-p 8081:8081` - portide vastendamine (port mapping) host'ist konteinerisse
- `-e` - keskkonna muutuja (environment variable)
- `JWT_SECRET` - lihtsalt test väärtus (min 32 tähemärki); tootmises kasuta `openssl rand -base64 32`

**Oodatud tulemus:**
```
...
Error connecting to database
...
Application failed to start
```

**See on TÄPSELT see, mida tahame näha!** 🎉
- Konteiner käivitus ✅
- Rakendus (application) proovis käivituda ✅
- Vea (error) sõnum näitab probleemi (puuduv DB) ✅
- Õppisid, kuidas Docker vigasid (errors) näeb ✅

Vajuta `Ctrl+C` et peatada.

#### Variant B: Taustal töötav režiim (detached mode) (õpi `docker ps` ja `docker logs`)

**See variant õpetab, kuidas debuggida hangunud konteinereid:**

```bash
# Puhasta eelmine test konteiner
docker rm -f todo-service-test

# Käivita taustal töötavas režiimis (detached mode)
# MÄRKUS: DB_HOST on vale, seega hangub (see on ÕIGE käitumine!)
docker run -d --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=nonexistent-db \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-test-secret-key-min-32-chars-long \
  -e SPRING_PROFILES_ACTIVE=prod \
  todo-service:1.0
```

**Vaata, mis juhtus:**

```bash
# Kas töötab? (HINT: Ei tööta!)
docker ps

# Vaata ka peatatud konteinereid
docker ps -a
# STATUS peaks olema: Exited (1)
```

**Miks konteiner puudub `docker ps` väljundis?**
- Konteiner käivitus, aga rakendus (application) hangus kohe
- Docker peatas hangunud konteineri automaatselt
- `docker ps` näitab ainult TÖÖTAVAID konteinereid
- `docker ps -a` näitab KÕIKi konteinereid (ka peatatud)

**Õpi logisid vaatama:**

```bash
# Vaata logisid (isegi kui konteiner on peatatud!)
docker logs todo-service

# Oodatud väljund:
# Error: Unable to connect to database...
# Connection refused...
```

**See on PERFEKTNE õppetund! 🎓**
- Õppisid `-d` (taustal töötav režiim (detached mode)) ✅
- Õppisid vahet `docker ps` vs `docker ps -a` ✅
- Õppisid, et logid on ka peatatud konteinerites ✅
- Mõistad, miks mitme konteineri lahendus on vaja ✅

**Miks kasutasime `DB_HOST=nonexistent-db`?**
- See tagab, et konteiner **hangub**, sest andmebaasi pole
- See on OODATUD käitumine Harjutus 1's!
- Töötava lahenduse saad [Harjutus 2: Mitme Konteineri Käivitamine](02-multi-container.md)-s

### Samm 6: Debug ja Troubleshoot (5 min)

```bash
# Vaata konteineri statusit
docker ps -a

# Vaata logisid
docker logs todo-service

# Sisene konteinerisse
docker exec -it todo-service sh

# Konteineri sees:
ls -la
java -version
env | grep DB
exit

# Inspekteeri konteinerit
docker inspect todo-service

# Vaata ressursside kasutust
docker stats todo-service
```

**Levinud probleemid:**

1. **Port on juba kasutusel:**
   ```bash
   # Vaata, mis kasutab porti 8081
   sudo lsof -i :8081

   # Kasuta teist porti
   docker run -p 8082:8081 ...
   ```

2. **Rakendus (application) hangub:**
   ```bash
   # Vaata logisid
   docker logs todo-service

   # Tõenäoliselt puudub PostgreSQL
   ```

3. **Ei saa ühendust:**
   ```bash
   # Kontrolli, kas konteiner töötab
   docker ps

   # Vaata võrku (network)
   docker inspect todo-service | grep IPAddress
   ```

4. **JWT_SECRET liiga lühike (kui kasutad oma väärtust):**
   ```bash
   # Viga (error): The specified key byte array is 88 bits which is not secure enough

   # Lahendus: Kasuta vähemalt 32 tähemärki (256 bits)
   # Test jaoks: my-test-secret-key-min-32-chars-long
   # Tootmises: openssl rand -base64 32
   ```

5. **Konteiner hangub kohe (andmebaas puudub):**
   ```bash
   # Viga (error): Unable to connect to database

   # See on OODATUD käitumine Harjutus 1's!
   # Lahendus: Käivita PostgreSQL konteiner (Harjutus 2)
   ```

---

## 🎯 Oodatud Tulemus

**Mida PEAKS saavutama:**

✅ **Docker pilt (image) on loodud:**
```bash
docker images | grep todo-service
# todo-service   1.0    abc123   ~200-250MB
```

✅ **Konteiner käivitub (isegi kui hangub):**
```bash
docker ps -a | grep todo-service
# STATUS: Exited (1) - See on OK!
```

✅ **Logid näitavad vea (error) sõnumit:**
```bash
docker logs todo-service
# Error: Unable to connect to database...
```

✅ **Oskad Docker käske kasutada:**
- `docker build` - pildi (image) loomine
- `docker run` - konteineri käivitamine
- `docker ps` vs `docker ps -a` - töötavad vs kõik konteinerid
- `docker logs` - logide vaatamine
- `docker exec` - konteinerisse sisenemine

**Mida EI PEAKS saavutama:**

❌ Töötav rakendus (application) (see tuleb Harjutus 2-s)
❌ Edukad API testid (andmebaas puudub)
❌ `docker ps` näitab töötavat konteinerit (hangub kohe)

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [x] **Dockerfile** backend-java-spring/ kaustas
- [x] **.dockerignore** fail
- [x] **JAR fail** build/libs/todo-service.jar
- [x] **Docker pilt (image)** `todo-service:1.0` (vaata `docker images`)
- [x] **Konteiner käivitatud** (vaata `docker ps -a` - STATUS: Exited)
- [x] Mõistad Dockerfile'i struktuuri
- [x] Oskad ehitada pilti (image)
- [x] Oskad käivitada konteinerit
- [x] Oskad vaadata logisid
- [x] **Mõistad, miks hangub** (PostgreSQL puudub)

---

## 🧪 Testimine

### Test 1: Kas pilt (image) on loodud? ✅

```bash
docker images | grep todo-service
# Oodatud: todo-service   1.0   ...   200-250MB
```

**Kui näed seda, siis pilt (image) on edukalt loodud!** 🎉

### Test 2: Kas konteiner käivitus? ✅

```bash
docker ps -a | grep todo-service
# Oodatud: Exited (1) - See on ÕIGE!
```

**Miks "Exited (1)" on hea?**
- Konteiner käivitus (Docker pilt (image) toimib) ✅
- Rakendus (application) käivitus (Java töötab) ✅
- Rakendus (application) hangus (PostgreSQL puudub) ✅
- See on TÄPSELT see, mida ootame! ✅

### Test 3: Kas logid näitavad vea (error) sõnumit? ✅

```bash
docker logs todo-service | head -20
# Peaks sisaldama:
# - Spring Boot logo
# - Error: Unable to connect to database
# - Connection refused / Unknown host
```

**See on PERFEKTNE!** Sa õppisid:
- Kuidas vaadata logisid hangunud konteineris
- Kuidas debuggida vea (error) sõnumit
- Miks mitme konteineri lahendus on vajalik

### Test 4: Kas konteiner ei ole `docker ps` väljundis? ✅

```bash
docker ps | grep todo-service
# Oodatud: TÜHI (midagi ei näita)
```

**See on ÕIGE!**
- `docker ps` näitab ainult TÖÖTAVAID konteinereid
- Hangunud konteiner on peatatud
- Kasuta `docker ps -a` et näha kõiki konteinereid

---

## 🎓 Edukas Harjutus!

**Kui kõik 4 testi läbisid, siis oled edukalt läbinud Harjutuse 1!**

Sa õppisid:
- ✅ Docker pildi (image) ehitamist
- ✅ Konteineri käivitamist
- ✅ Vahet `docker ps` vs `docker ps -a`
- ✅ Logide vaatamist hangunud konteineris
- ✅ Vea (error) sõnumite debuggimist
- ✅ Miks mitme konteineri lahendus on vajalik

**Järgmine samm:** [Harjutus 2: Mitme Konteineri Käivitamine](02-multi-container.md) - Lisame PostgreSQL ja saame töötava rakenduse (application)!

---

## 🎓 Õpitud Mõisted

### Dockerfile instruktsioonid:

- `FROM` - Baaspilt (base image)
- `WORKDIR` - Töökataloog
- `COPY` - Kopeeri failid
- `RUN` - Käivita käsk ehitamise ajal
- `EXPOSE` - Avalda port
- `CMD` - Käivita käsk konteineri käivitamisel

### Docker käsud:

- `docker build` - Ehita pilt (image)
- `docker run` - Käivita konteiner
- `docker ps` - Näita töötavaid konteinereid
- `docker logs` - Vaata konteineri logisid
- `docker exec` - Käivita käsk töötavas konteineris
- `docker inspect` - Vaata konteineri/pildi (image) infot

### Docker run parameetrid:

- `-d` - Taustal töötav režiim (detached mode)
- `-it` - Interactive + TTY (interaktiivne)
- `-p 8081:8081` - Portide vastendamine (port mapping) (host:konteiner)
- `-e KEY=value` - Keskkonna muutuja (environment variable)
- `--name <nimi>` - Anna konteinerile nimi
- `--link <konteiner>:<alias>` - Ühenda teise konteineriga (deprecated, kasuta võrke (networks)!)

### Õpitud probleemid ja lahendused:

- **JWT_SECRET peab olema min 32 tähemärki** - Test: `my-test-secret-key-min-32-chars-long`, Tootmine: `openssl rand -base64 32`
- **Konteiner hangub (PostgreSQL puudub)** - See on Harjutus 1's OODATUD! Lahendus tuleb Harjutus 2's

---

## 💡 Parimad Tavad

1. **Kasuta `.dockerignore`** - Väldi tarbetute failide kopeerimist
2. **Kasuta alpine pilte (images)** - Väiksem suurus, kiirem
3. **Kasuta JRE (mitte JDK)** - Runtime ei vaja compile tools
4. **Ehita JAR enne Docker pildi (image) ehitamist** - Kiire taasehitamine, kui kood muutub
5. **Kasuta EXPOSE** - Dokumenteeri, millist porti rakendus (application) kasutab
6. **JWT_SECRET peab olema turvaline** - Min 32 tähemärki; testiks sobib lihtsalt string, tootmises kasuta `openssl rand -base64 32`

---

## 🔗 Järgmine Samm

Järgmises harjutuses lisame PostgreSQL konteineri ja ühendame kaks konteinerit!

**Jätka:** [Harjutus 2: Mitme Konteineri Käivitamine](02-multi-container.md)

---

## 📚 Viited

- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Docker run reference](https://docs.docker.com/engine/reference/run/)
- [Spring Boot Docker best practices](https://spring.io/guides/topicals/spring-boot-docker/)

---

**Õnnitleme! Oled loonud oma esimese Docker pildi (image)! 🎉**
