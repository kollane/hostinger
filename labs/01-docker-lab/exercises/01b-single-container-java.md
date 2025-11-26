# Harjutus 1: Ühe Konteineri Käivitamine

**Kestus:** 45 minutit
**Eesmärk:** Konteineriseeri Java Spring Boot Todo teenus (service) ja õpi Dockerfile'i loomist

---

## ⚠️ OLULINE: Harjutuse Fookus

**See harjutus keskendub Docker põhitõdede õppimisele, MITTE töötavale rakendusele (application)!**

✅ **Õpid:**
- Dockerfile'i loomist
- Docker pildi (image) ehitamist (build)
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

Selles harjutuses konteineriseerid Java Spring Boot Todo teenuse (service) rakenduse (application). Õpid looma Dockerfile'i, ehitama (build) Docker pilti (image) ja käivitama konteinereid (isegi kui see hangub andmebaasi puudumise tõttu).

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Luua Dockerfile'i Java Spring Boot rakendusele (application)
- ✅ Ehitada (build) Docker pilti (image)
- ✅ Käivitada ja peatada konteinereid
- ✅ Kasutada keskkonna muutujaid (environment variables)
- ✅ Vaadata konteineri logisid
- ✅ Debuggida konteineri probleeme

---

## 🖥️ Sinu Testimise Konfiguratsioon

### SSH Ühendus VPS-iga
```bash
ssh labuser@93.127.213.242 -p [SINU-PORT]
```

| Õpilane | SSH Port | Password |
|---------|----------|----------|
| student1 | 2201 | student1 |
| student2 | 2202 | student2 |
| student3 | 2203 | student3 |

---

## 🏗️ Arhitektuur

```
┌─────────────────────────────┐
│   Docker Konteiner          │
│                             │
│  ┌───────────────────────┐  │
│  │  Java Rakendus (Application) │  │
│  │  Todo Teenus (Service)         │  │
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

### Samm 1: Tutvu Rakendusega (Application)

**Rakenduse (application) juurkataloog:** `~/labs/apps/backend-java-spring`

Vaata Todo teenuse (service) koodi:

```bash
cd ~/labs/apps/backend-java-spring

# Vaata faile
ls -la

# Loe README
cat README.md

# Vaata build.gradle
cat build.gradle
```

**Küsimused:**
- Millise pordiga rakendus (application) käivitub? (8081)
- Millised sõltuvused (dependencies) on vajalikud? (vaata build.gradle)
- Kas rakendus (application) vajab andmebaasi? (Jah, PostgreSQL)

### Samm 2: Loo Dockerfile

Loo fail nimega `Dockerfile`:

**⚠️ Oluline:** Dockerfail tuleb luua rakenduse (application) juurkataloogi `~/labs/apps/backend-java-spring`

```bash
vim Dockerfile
```

**📖 Dockerfile põhitõed:** Kui vajad abi Dockerfile instruktsioonide (FROM, WORKDIR, COPY, CMD, EXPOSE) mõistmisega, loe [Peatükk 06: Dockerfile - Rakenduste Konteineriseerimise Detailid](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md).

**Ülesanne:** Kirjuta Dockerfile, mis:
1. Kasutab Java 21 JRE alpine baaspilti (base image)
2. Seadistab töökataloogiks `/app`
3. Kopeerib JAR faili (eeldab, et ehitamine (build) on tehtud)
4. Avaldab pordi 8081
5. Käivitab rakenduse (application)

**Märkus:** See on lihtne Dockerfile, mis eeldab, et JAR fail on juba ehitatud (built). Optimeeritud versioonis (Harjutus 5) lisame mitme-sammulise (multi-stage) ehitamise (build).

**💡 Abi vajadusel:**
- Vaata Docker dokumentatsiooni: https://docs.docker.com/engine/reference/builder/
- Vaata näidislahendust lahenduste kataloogis: `~/labs/01-docker-lab/solutions/backend-java-spring/Dockerfile`

**💡 Näpunäide: Dockerfile struktuur**

```dockerfile
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Kopeeri JAR fail
COPY build/libs/todo-service.jar app.jar

# Avalda port
EXPOSE 8081

# Käivita rakendus (application)
CMD ["java", "-jar", "app.jar"]
```

### Samm 3: Loo .dockerignore

Loo `.dockerignore` fail, et vältida tarbetute failide kopeerimist:

**⚠️ Oluline:** .dockerignore tuleb luua rakenduse (application) juurkataloogi `~/labs/apps/backend-java-spring`

```bash
vim .dockerignore
```

**💡 Abi vajadusel:**
Vaata näidislahendust: `~/labs/01-docker-lab/solutions/backend-java-spring/.dockerignore`

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
- Kiirem ehitamine (build)
- Turvalisem (ei kopeeri .env faile)
- Ei kopeeri lähtekoodi (ainult JAR fail)

### Samm 4: Ehita (build) Docker pilt (image)

**Asukoht:** `~/labs/apps/backend-java-spring`

Esmalt ehita (build) JAR fail, seejärel Docker pilt (image):

**⚠️ Oluline:** Nii JAR-i kui ka Docker pildi (image) ehitamiseks (build) pead olema rakenduse (application) juurkataloogis (kus asuvad `build.gradle` ja `Dockerfile`).

```bash
# Ehita (build) JAR fail
./gradlew clean bootJar

# Kontrolli, et JAR on loodud
ls -lh build/libs/

# Ehita (build) Docker pilt (image) tag'iga
docker build -t todo-service:1.0 .

# Vaata ehitamise (build) protsessi
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

### Samm 5: Käivita Konteiner

**⚠️ OLULINE:** Järgnevad käsud käivitavad konteineri, aga rakendus (application) hangub, sest PostgreSQL puudub. See on **OODATUD** käitumine! Fookus on õppida Docker käske, mitte saada töötav rakendus (application).

#### Variant A: Interaktiivne režiim (näed kohe vigu (errors))

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
- Õppisid, kuidas Docker vigu (errors) näeb ✅

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
- `docker ps -a` näitab KÕIKI konteinereid (ka peatatud)

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

### Samm 6: Debug ja Troubleshoot

```bash
# Vaata konteineri staatust
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

## 💡 Parimad Praktikad (Best Practices)

1. **Kasuta `.dockerignore`** - Väldi tarbetute failide kopeerimist
2. **Kasuta alpine pilte (images)** - Väiksem suurus, kiirem
3. **Kasuta JRE (mitte JDK)** - Runtime ei vaja kompileerimise (compile) tööriistu
4. **Ehita (build) JAR enne Docker pildi (image) ehitamist (build)** - Kiire taasehitamine (rebuild), kui kood muutub
5. **Kasuta EXPOSE** - Dokumenteeri, millist porti rakendus (application) kasutab
6. **JWT_SECRET peab olema turvaline** - Min 32 tähemärki; testiks sobib lihtsalt string, tootmises kasuta `openssl rand -base64 32`

**📖 Java konteineriseerimise parimad tavad:** Põhjalikum käsitlus JAR vs WAR, Spring Boot spetsiifikast, JVM memory tuning'ust ja teised Java spetsiifilised teemad leiad [Peatükk 06A: Java Spring Boot ja Node.js Konteineriseerimise Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md).

---

**Õnnitleme! Oled loonud oma esimese Docker pildi (image)! 🎉**

## 🔗 Järgmine Samm

Järgmises harjutuses lisame PostgreSQL konteineri ja ühendame kaks konteinerit!

**Jätka:** [Harjutus 2: Mitme Konteineri Käivitamine](02-multi-container.md)

---

## 📚 Viited

- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Docker run reference](https://docs.docker.com/engine/reference/run/)
- [Spring Boot Docker parimad praktikad (best practices)](https://spring.io/guides/topicals/spring-boot-docker/)
