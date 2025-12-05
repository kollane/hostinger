# Harjutus 1: Üksiku konteineri loomine (Todo Service)
---
## 📋 Harjutuse ülevaade

**Harjutuse eesmärk:** Selles harjutuses konteineriseerid Java Spring Boot Todo Service'i rakenduse. Õpid looma Dockerfile'i, ehitama Docker tõmmist ja käivitama konteinereid.

**Todo Service'i rakenduse lühitutvustus:**
- ✍️ Loob ja haldab todo ülesandeid (CRUD)
- 👀 Kuvab kasutaja ülesandeid (filtreerimine, sorteerimine)
- 📊 Näitab statistikat (tehtud/pooleli ülesanded)
- 🔐 Valideerib JWT "token"-eid User Service'ilt

**📖 Rakenduse funktsionaalsuse kohta lähemalt siit:** [Todo Service README](../../apps/backend-java-spring/README.md)

**Harjutuse Fookus:** See harjutus keskendub Docker põhitõdede õppimisele, MITTE töötavale rakendusele (application)!

✅ **Õpid:**
- Dockerfile'i loomist
- Docker **tõmmise (docker image)** ehitamist
- **Konteineri** käivitamist
- **Logide (logs)** vaatamist ja **veatuvastust (debug)**
- Docker käskude kasutamist

❌ **Rakendus EI TÖÖTA täielikult:**
- Todo Service vajab PostgreSQL andmebaasi
- Konteiner käivitub, aga hangub kohe (see on **OODATUD**)
- Töötava rakenduse saad **Harjutus 2**-s (mitme konteineri käivitamine)

---

## 📝 Sammud

### Samm 1: Tutvu rakenduse koodiga

**Rakenduse juurkataloog:** `~/labs/apps/backend-java-spring`

Vaata Todo Service koodi:

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
- Millise pordiga rakendus käivitub? (8081)
- Millised sõltuvused (dependencies) on vajalikud? (vaata build.gradle)
- Kas rakendus vajab andmebaasi? (Jah, PostgreSQL)

### Samm 2: Loo Dockerfile

Loo fail nimega `Dockerfile`:

**⚠️ Oluline:** Dockerfail tuleb luua rakenduse juurkataloogi `~/labs/apps/backend-java-spring`

```bash
vim Dockerfile
```

**📖 Dockerfile põhitõed:** Kui vajad abi Dockerfile instruktsioonide (FROM, WORKDIR, COPY, CMD, EXPOSE) mõistmisega, loe [Peatükk 06: Dockerfile - Rakenduste Konteineriseerimise Detailid](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md).

**Ülesanne:** Kirjuta Dockerfile, mis:
1. Kasutab Java 21 JRE alpine baastõmmist (base image)
2. Seadistab töökataloogiks `/app`
3. Kopeerib JAR faili (eeldab, et ehitamine on tehtud)
4. Avaldab pordi 8081
5. Käivitab rakenduse

**Märkus:** See on lihtne Dockerfile, mis eeldab, et JAR fail on juba ehitatud. Optimeeritud versioonis (Harjutus 5) lisame mitmeastmelise (multi-stage) ehitamise.

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

# Käivita rakendus
CMD ["java", "-jar", "app.jar"]
```

### Samm 3: Loo .dockerignore

Loo `.dockerignore` fail, et vältida tarbetute failide kopeerimist:

**⚠️ Oluline:** .dockerignore tuleb luua rakenduse juurkataloogi `~/labs/apps/backend-java-spring`

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
gradlew
gradlew.bat
```

**Miks see oluline on?**
- Väiksem tõmmise suurus
- Kiirem ehitamine
- Turvalisem (ei kopeeri .env faile)
- Ei kopeeri lähtekoodi (ainult JAR fail)

### Samm 4: Ehita Docker tõmmis

**Asukoht:** `~/labs/apps/backend-java-spring`

Esmalt ehita JAR fail, seejärel Docker tõmmis:

**⚠️ Oluline:** Nii JAR-i kui ka Docker tõmmise ehitamiseks pead olema rakenduse juurkataloogis (kus asuvad `build.gradle` ja `Dockerfile`).

```bash
# Ehita JAR fail
./gradlew clean bootJar

# Kontrolli, et JAR on loodud
ls -lh build/libs/

# Ehita Docker tõmmis sildiga (tag)
docker build -t todo-service:1.0 .

# Vaata ehitamise protsessi
# Märka: iga käsk loob uue kihi (layer)
```

Kontrolli tõmmist:

```bash
# Vaata kõiki tõmmiseid
docker images

# Vaata todo-service tõmmise infot
docker image inspect todo-service:1.0

# Kontrolli suurust
docker images todo-service:1.0
```

**Küsimused:**
- Kui suur on sinu tõmmis?
- Mitu kihti (layers) on tõmmisel?
- Millal tõmmis loodi?

### Samm 5: Käivita Konteiner

**⚠️ OLULINE:** Järgnevad käsud käivitavad konteineri, aga rakendus hangub, sest PostgreSQL puudub. See on **OODATUD** käitumine! Hetkel on fookus õppida Docker käske, mitte saada töötav rakendus.

**ℹ️ Portide turvalisus:**

Selles harjutuses kasutame lihtsustatud portide vastendust (`-p 8081:8081`).
- ✅ **Host'i tulemüür kaitseb:** VPS-is on UFW tulemüür, mis blokeerib pordi 8081 internetist
- 📚 **Tootmises oleks õige:** `-p 127.0.0.1:8081:8081` (avab pordi ainult localhost'il)
- 🎯 **Lab 2 käsitleb:** Võrguturvalisust ja reverse proxy seadistust

**Hetkel keskendume Docker põhitõdedele!**

---

#### Variant A: Interaktiivne režiim (näed kohe vigu)

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
- `-p 8081:8081` - portide vastendamine hostist konteinerisse
- `-e` - keskkonna muutuja
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
- Rakendus proovis käivituda ✅
- Veateade näitab probleemi (puuduv DB) ✅
- Õppisid, kuidas Docker vigu näeb ✅

Vajuta `Ctrl+C` et peatada.

#### Variant B: Taustal töötav režiim (detached mode) (õpi `docker ps` ja `docker logs`)

**See variant õpetab, kuidas veatuvastust teostada hangunud konteineritele:**

```bash
# Puhasta eelmine test konteiner
docker rm -f todo-service-test

# Käivita taustal ehk detached režiimis (-d)
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
- Konteiner käivitus, aga rakendus hangus kohe
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
- Õppisid `-d` (taustal töötav režiim) ✅
- Õppisid vahet `docker ps` vs `docker ps -a` ✅
- Õppisid, et logid on ka peatatud konteinerites ✅
- Mõistad, miks mitme konteineri lahendus on vaja ✅

**Miks kasutasime `DB_HOST=nonexistent-db`?**
- See tagab, et konteiner **hangub**, sest andmebaasi pole
- See on OODATUD käitumine Harjutus 1's!
- Töötava lahenduse saad [Harjutus 2: Mitme Konteineri Käivitamine](02-multi-container.md)-s

### Samm 6: Veatuvastus ja tõrkeotsing

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

2. **Rakendus hangub:**
   ```bash
   # Vaata logisid
   docker logs todo-service

   # Tõenäoliselt puudub PostgreSQL
   ```

3. **Ei saa ühendust:**
   ```bash
   # Kontrolli, kas konteiner töötab
   docker ps

   # Vaata võrku (docker network)
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
   # Veateade: Unable to connect to database

   # See on OODATUD käitumine Harjutus 1's!
   # Lahendus: Käivita PostgreSQL konteiner (Harjutus 2)
   ```

---

## 🎯 Oodatud Tulemus

**Mida PEAKS saavutama:**

✅ **Docker tõmmis on loodud:**
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
- `docker build` - tõmmise loomine
- `docker run` - konteineri käivitamine
- `docker ps` vs `docker ps -a` - töötavad vs kõik konteinerid
- `docker logs` - logide vaatamine
- `docker exec` - konteinerisse sisenemine

**Mida EI PEAKS saavutama:**

❌ Töötav rakendus (see tuleb Harjutus 2-s)
❌ Edukad API testid (andmebaas puudub)
❌ `docker ps` näitab töötavat konteinerit (hangub kohe)

---

## 💡 Parimad Praktikad (Best Practices)

1. **Kasuta `.dockerignore`** - Väldi tarbetute failide kopeerimist
2. **Kasuta alpine tõmmiseid** - Väiksem suurus, kiirem
3. **Kasuta JRE (mitte JDK)** - Runtime ei vaja kompileerimise tööriistu
4. **Ehita JAR enne Docker tõmmise ehitamist** - Kiire taasehitamine, kui kood muutub
5. **Kasuta EXPOSE** - Dokumenteeri, millist porti rakendus kasutab
6. **JWT_SECRET peab olema turvaline** - Min 32 tähemärki; testiks sobib lihtsalt string, tootmises kasuta `openssl rand -base64 32`

**📖 Java konteineriseerimise parimad tavad:** Põhjalikum käsitlus JAR vs WAR, Spring Boot spetsiifikast, JVM memory tuning'ust ja teised Java spetsiifilised teemad leiad [Peatükk 06A: Java Spring Boot ja Node.js Konteineriseerimise Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md).

---

**Õnnitleme! Oled loonud oma esimese Docker tõmmise! 🎉**

## 🔗 Järgmine Samm

Järgmises harjutuses lisame PostgreSQL konteineri ja ühendame kaks konteinerit!

**Jätka:** [Harjutus 2: Mitme Konteineri Käivitamine](02-multi-container.md)

---

## 📚 Viited

- [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
- [Docker run reference](https://docs.docker.com/engine/reference/run/)
- [Spring Boot Docker parimad praktikad (best practices)](https://spring.io/guides/topicals/spring-boot-docker/)
