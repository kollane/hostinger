# Harjutus 1: Single Container

**Kestus:** 45 minutit
**Eesmärk:** Konteinerise Java Spring Boot Todo Service ja õpi Dockerfile'i loomist

---

## ⚠️ OLULINE: Harjutuse Fookus

**See harjutus keskendub Docker põhitõdedele, MITTE töötavale rakendusele!**

✅ **Õpid:**
- Dockerfile'i loomist
- Docker image'i build'imist
- Container'i käivitamist
- Logide vaatamist ja debuggimist
- Docker käskude kasutamist

❌ **Rakendus EI TÖÖTA täielikult:**
- Todo-service vajab PostgreSQL andmebaasi
- Container käivitub, aga crashib kohe (see on **OODATUD**)
- Töötava rakenduse saad **Harjutus 2**-s (Multi-Container)

**Miks see hea on?**
- Õpid debuggima probleeme (`docker logs`, `docker exec`)
- Mõistad, miks rakendused vajavad omavahel suhtlemist
- Näed, kuidas Docker error messaged välja näevad

---

## 📋 Ülevaade

Selles harjutuses konteineriseerid Java Spring Boot Todo Service rakenduse. Õpid looma Dockerfile'i, build'ima Docker image'i ja käivitama containerit (isegi kui see crashib andmebaasi puudumise tõttu).

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua Dockerfile'i Java Spring Boot rakendusele
- ✅ Build'ida Docker image'i
- ✅ Käivitada ja peatada containereid
- ✅ Kasutada environment variables
- ✅ Vaadata container logisid
- ✅ Debuggida container probleeme

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────┐
│   Docker Container          │
│                             │
│  ┌───────────────────────┐  │
│  │  Java Application     │  │
│  │  Todo Service         │  │
│  │  Port: 8081           │  │
│  └───────────────────────┘  │
│                             │
└─────────────────────────────┘
          │
          │ Port mapping
          │
    localhost:8081
```

---

## 📝 Sammud

### Samm 1: Tutvu Rakendusega (5 min)

**Asukoht:** `/hostinger/labs/apps/backend-java-spring`

Vaata Todo Service koodi:

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
- Millise pordiga rakendus käivitub? (8081)
- Millised sõltuvused on vajalikud? (vaata build.gradle)
- Kas rakendus vajab andmebaasi? (Jah, PostgreSQL)

### Samm 2: Loo Dockerfile (15 min)

**Asukoht:** `/hostinger/labs/apps/backend-java-spring`

Loo fail nimega `Dockerfile`:

```bash
vim Dockerfile
```

**Ülesanne:** Kirjuta Dockerfile, mis:
1. Kasutab Java 17 JRE alpine base image'i
2. Seadistab töökataloogiks `/app`
3. Kopeerib JAR faili (eeldab, et build on tehtud)
4. Avaldab pordi 8081
5. Käivitab rakenduse

**Märkus:** See on lihtne Dockerfile, mis eeldab, et JAR fail on juba build'itud. Optimeeritud versioonis (Harjutus 5) lisame multi-stage build'i.

**💡 Abi vajadusel:**
- Vaata Docker dokumentatsiooni: https://docs.docker.com/engine/reference/builder/
- Vaata näidislahendust lahenduste kataloogis: `/hostinger/labs/01-docker-lab/solutions/backend-java-spring/Dockerfile`

<details>
<summary>💡 Näpunäide: Dockerfile struktuur</summary>

```dockerfile
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Kopeeri JAR fail
COPY build/libs/todo-service.jar app.jar

# Avalda port
EXPOSE 8081

# Käivita rakendus
CMD ["java", "-jar", "app.jar"]
```
</details>

### Samm 3: Loo .dockerignore (5 min)

**Asukoht:** `/hostinger/labs/apps/backend-java-spring`

Loo `.dockerignore` fail, et vältida tarbetute failide kopeerimist:

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
- Väiksem image suurus
- Kiirem build
- Turvalisem (ei kopeeri .env faile)
- Ei kopeeri source code'i (ainult JAR fail)

### Samm 4: Build Docker Image (10 min)

**Asukoht:** `/hostinger/labs/apps/backend-java-spring`

Esmalt build'i JAR fail, seejärel Docker image:

**⚠️ Oluline:** Nii JAR-i kui ka Docker image'i ehitamiseks pead olema rakenduse juurkataloogis (kus asuvad `build.gradle` ja `Dockerfile`).

```bash
# Build JAR fail
./gradlew clean bootJar

# Kontrolli, et JAR on loodud
ls -lh build/libs/

# Build Docker image tagiga
docker build -t todo-service:1.0 .

# Vaata build protsessi
# Märka: iga käsk loob uue layer
```

**Kontrolli image'i:**

```bash
# Vaata kõiki image'id
docker images

# Vaata todo-service image infot
docker image inspect todo-service:1.0

# Kontrolli suurust
docker images todo-service:1.0
```

**Küsimused:**
- Kui suur on sinu image? (peaks olema ~200-250MB)
- Mitu layer'it on image'il?
- Millal image loodi?

### Samm 5: Käivita Container (10 min)

**⚠️ OLULINE:** Järgnevad käsud käivitavad containeri, aga rakendus crashib, sest PostgreSQL puudub. See on **OODATUD** käitumine! Fookus on õppida Docker käske, mitte saada töötav rakendus.

#### Variant A: Interaktiivne režiim (näed kohe error'eid)

**See variant on PARIM õppimiseks** - näed kohe, mida juhtub:

```bash
# Käivita container interaktiivselt
# MÄRKUS: DB_HOST on vale, seega crashib (see on ÕIGE käitumine!)
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
- `--name` - anna containerile nimi
- `-p 8081:8081` - map port 8081 host'ist container'isse
- `-e` - environment variable
- `JWT_SECRET` - lihtsalt test väärtus (min 32 tähemärki); tootmises kasuta `openssl rand -base64 32`

**Oodatud tulemus:**
```
...
Error connecting to database
...
Application failed to start
```

**See on TÄPSELT see, mida tahame näha!** 🎉
- Container käivitus ✅
- Rakendus proovis käivituda ✅
- Error message näitab probleemi (puuduv DB) ✅
- Õppisid, kuidas Docker error'eid näeb ✅

Vajuta `Ctrl+C` et peatada.

#### Variant B: Background režiim (õpi `docker ps` ja `docker logs`)

**See variant õpetab, kuidas debuggida crashinud containereid:**

```bash
# Puhasta eelmine test container
docker rm -f todo-service-test

# Käivita taustal (detached mode)
# MÄRKUS: DB_HOST on vale, seega crashib (see on ÕIGE käitumine!)
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

# Vaata ka peatatud containereid
docker ps -a
# STATUS peaks olema: Exited (1)
```

**Miks container puudub `docker ps` väljundis?**
- Container käivitus, aga rakendus crashis kohe
- Docker peatas crashinud container'i automaatselt
- `docker ps` näitab ainult TÖÖTAVAID containereid
- `docker ps -a` näitab KÕIKi containereid (ka peatatud)

**Õpi logisid vaatama:**

```bash
# Vaata logisid (isegi kui container on peatatud!)
docker logs todo-service

# Oodatud väljund:
# Error: Unable to connect to database...
# Connection refused...
```

**See on PERFEKTNE õppetund! 🎓**
- Õppisid `-d` (detached mode) ✅
- Õppisid vahet `docker ps` vs `docker ps -a` ✅
- Õppisid, et logid on ka peatatud containerites ✅
- Mõistad, miks multi-container lahendus on vaja ✅

**Miks kasutasime `DB_HOST=nonexistent-db`?**
- See tagab, et container **crashib**, sest andmebaasi pole
- See on OODATUD käitumine Harjutus 1's!
- Töötava lahenduse saad [Harjutus 2: Multi-Container](02-multi-container.md)-s

### Samm 6: Debug ja Troubleshoot (5 min)

```bash
# Vaata container statusit
docker ps -a

# Vaata logisid
docker logs todo-service

# Sisene containerisse
docker exec -it todo-service sh

# Container sees:
ls -la
java -version
env | grep DB
exit

# Inspekteeri containerit
docker inspect todo-service

# Vaata resource kasutust
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

2. **Rakendus crashib:**
   ```bash
   # Vaata logisid
   docker logs todo-service

   # Tõenäoliselt puudub PostgreSQL
   ```

3. **Ei saa ühendust:**
   ```bash
   # Kontrolli, kas container töötab
   docker ps

   # Vaata network't
   docker inspect todo-service | grep IPAddress
   ```

4. **JWT_SECRET liiga lühike (kui kasutad oma väärtust):**
   ```bash
   # Error: The specified key byte array is 88 bits which is not secure enough

   # Lahendus: Kasuta vähemalt 32 tähemärki (256 bits)
   # Test jaoks: my-test-secret-key-min-32-chars-long
   # Tootmises: openssl rand -base64 32
   ```

5. **Container crashib kohe (andmebaas puudub):**
   ```bash
   # Error: Unable to connect to database

   # See on OODATUD käitumine Harjutus 1's!
   # Lahendus: Käivita PostgreSQL container (Harjutus 2)
   ```

---

## 🎯 Oodatud Tulemus

**Mida PEAKS saavutama:**

✅ **Docker image on loodud:**
```bash
docker images | grep todo-service
# todo-service   1.0    abc123   ~200-250MB
```

✅ **Container käivitub (isegi kui crashib):**
```bash
docker ps -a | grep todo-service
# STATUS: Exited (1) - See on OK!
```

✅ **Logid näitavad error messaget:**
```bash
docker logs todo-service
# Error: Unable to connect to database...
```

✅ **Oskad Docker käske kasutada:**
- `docker build` - image loomine
- `docker run` - container käivitamine
- `docker ps` vs `docker ps -a` - töötavad vs kõik containerid
- `docker logs` - logide vaatamine
- `docker exec` - containerisse sisenemine

**Mida EI PEAKS saavutama:**

❌ Töötav rakendus (see tuleb Harjutus 2-s)
❌ Edukad API testid (andmebaas puudub)
❌ `docker ps` näitab töötavat containerit (crashib kohe)

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [x] **Dockerfile** backend-java-spring/ kaustas
- [x] **.dockerignore** fail
- [x] **JAR fail** build/libs/todo-service.jar
- [x] **Docker image** `todo-service:1.0` (vaata `docker images`)
- [x] **Container käivitatud** (vaata `docker ps -a` - STATUS: Exited)
- [x] Mõistad Dockerfile'i struktuuri
- [x] Oskad build'ida image'i
- [x] Oskad käivitada containerit
- [x] Oskad vaadata logisid
- [x] **Mõistad, miks crashib** (PostgreSQL puudub)

---

## 🧪 Testimine

### Test 1: Kas image on loodud? ✅

```bash
docker images | grep todo-service
# Oodatud: todo-service   1.0   ...   200-250MB
```

**Kui näed seda, siis image on edukalt loodud!** 🎉

### Test 2: Kas container käivitus? ✅

```bash
docker ps -a | grep todo-service
# Oodatud: Exited (1) - See on ÕIGE!
```

**Miks "Exited (1)" on hea?**
- Container käivitus (Docker image toimib) ✅
- Rakendus käivitus (Java töötab) ✅
- Rakendus crashis (PostgreSQL puudub) ✅
- See on TÄPSELT see, mida ootame! ✅

### Test 3: Kas logid näitavad error messaget? ✅

```bash
docker logs todo-service | head -20
# Peaks sisaldama:
# - Spring Boot logo
# - Error: Unable to connect to database
# - Connection refused / Unknown host
```

**See on PERFEKTNE!** Sa õppisid:
- Kuidas vaadata logisid crashinud containeris
- Kuidas debuggida error messaget
- Miks multi-container lahendus on vajalik

### Test 4: Kas container ei ole `docker ps` väljundis? ✅

```bash
docker ps | grep todo-service
# Oodatud: TÜHI (midagi ei näita)
```

**See on ÕIGE!**
- `docker ps` näitab ainult TÖÖTAVAID containereid
- Crashinud container on peatatud
- Kasuta `docker ps -a` et näha kõiki containereid

---

## 🎓 Edukas Harjutus!

**Kui kõik 4 testi läbisid, siis oled edukalt läbinud Harjutuse 1!**

Sa õppisid:
- ✅ Docker image'i build'imist
- ✅ Container'i käivitamist
- ✅ Vahet `docker ps` vs `docker ps -a`
- ✅ Logide vaatamist crashinud containeris
- ✅ Error message'ite debuggimist
- ✅ Miks multi-container setup on vajalik

**Järgmine samm:** [Harjutus 2: Multi-Container](02-multi-container.md) - Lisame PostgreSQL ja saame töötava rakenduse!

---

## 🎓 Õpitud Mõisted

### Dockerfile instruktsioonid:

- `FROM` - Base image
- `WORKDIR` - Töökataloog
- `COPY` - Kopeeri failid
- `RUN` - Käivita käsk build ajal
- `EXPOSE` - Avalda port
- `CMD` - Käivita käsk container start'imisel

### Docker käsud:

- `docker build` - Build image
- `docker run` - Käivita container
- `docker ps` - Näita töötavaid containereid
- `docker logs` - Vaata container logisid
- `docker exec` - Käivita käsk töötavas containeris
- `docker inspect` - Vaata container/image infot

### Docker run parameetrid:

- `-d` - Detached mode (taustal)
- `-it` - Interactive + TTY (interaktiivne)
- `-p 8081:8081` - Port mapping (host:container)
- `-e KEY=value` - Environment variable
- `--name <nimi>` - Anna containerile nimi
- `--link <container>:<alias>` - Ühenda teise containeriga (deprecated, kasuta networks!)

### Õpitud probleemid ja lahendused:

- **JWT_SECRET peab olema min 32 tähemärki** - Test: `my-test-secret-key-min-32-chars-long`, Tootmine: `openssl rand -base64 32`
- **Container crashib (PostgreSQL puudub)** - See on Harjutus 1's OODATUD! Lahendus tuleb Harjutus 2's

---

## 💡 Parimad Tavad

1. **Kasuta `.dockerignore`** - Väldi tarbetute failide kopeerimist
2. **Kasuta alpine images** - Väiksem suurus, kiirem
3. **Kasuta JRE (mitte JDK)** - Runtime ei vaja compile tools
4. **Build JAR enne Docker build'i** - Kiire rebuild, kui kood muutub
5. **Kasuta EXPOSE** - Dokumenteeri, millist porti rakendus kasutab
6. **JWT_SECRET peab olema turvaline** - Min 32 tähemärki; testiks sobib lihtsalt string, tootmises kasuta `openssl rand -base64 32`

---

## 🔗 Järgmine Samm

Järgmises harjutuses lisame PostgreSQL containeri ja ühendame kaks containerit!

**Jätka:** [Harjutus 2: Multi-Container](02-multi-container.md)

---

## 📚 Viited

- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Docker run reference](https://docs.docker.com/engine/reference/run/)
- [Spring Boot Docker best practices](https://spring.io/guides/topicals/spring-boot-docker/)

---

**Õnnitleme! Oled loonud oma esimese Docker image'i! 🎉**
