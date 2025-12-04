# Harjutus 1: Üksiku konteineri loomine (Todo Service)

**Todo Service'i rakenduse lühitutvustus:**
- ✍️ Loob ja haldab todo ülesandeid (CRUD)
- 👀 Kuvab kasutaja ülesandeid (filtreerimine, sorteerimine)
- 📊 Näitab statistikat (tehtud/pooleli ülesanded)
- 🔐 Valideerib JWT "token"-eid User Service'ilt

**📖 Rakenduse funktsionaalsuse kohta lähemalt siit:** [Todo Service README](../../apps/backend-java-spring/README.md)

---
## 📋 Harjutuse ülevaade
**Harjutuse eesmärk:** Selles harjutuses konteineriseerid Java Spring Boot Todo Service'i rakenduse. Õpid looma Dockerfile'i, ehitama Docker tõmmist ja käivitama konteinereid.

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

## 🖥️ Sinu Testimise Konfiguratsioon

### SSH Ühendus VPS-iga
```bash
ssh labuser@93.127.213.242 -p [SINU-PORT]
```

| Õpilane | SSH Port | Password |
|--------|----------|----------|
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
│  │  Java Rakendus        │  │
│  │  Todo Service         │  │
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

**⚠️ Oluline:** Dockerfail tuleb luua rakenduse juurkataloogi `~/labs/apps/backend-java-spring`

```bash
vim Dockerfile
```

**📖 Dockerfile põhitõed:** Kui vajad abi Dockerfile instruktsioonide (FROM, WORKDIR, COPY, RUN, CMD, ARG, multi-stage) mõistmisega, loe [Peatükk 06: Dockerfile - Rakenduste Konteineriseerimise Detailid](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md).

---

#### Variant A: Lihtne (VPS, õppemeetod)

Lihtne 1-stage Dockerfile VPS'i jaoks (eeldab pre-built JAR'i):

```dockerfile
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Kopeeri JAR fail (eeldab host'is ehitatud JAR'i!)
COPY build/libs/todo-service.jar app.jar

# Avalda port
EXPOSE 8081

# Käivita
CMD ["java", "-jar", "app.jar"]
```

**Ehita:**
```bash
# 1. Ehita JAR host'is
./gradlew clean bootJar

# 2. Ehita Docker tõmmis
docker build -t todo-service:1.0 .
```

⚠️ **Märkus:** See on NÄIDIS VPS testimiseks. Praktikas kasuta Variant B (Gradle build containeris)!

---

#### Variant B: Corporate Keskkond (PRIMAARNE) ⭐

**Enamik õpilasi kasutab seda!** 2-stage build Gradle containeris ARG proksiga:

```dockerfile
# ====================================
# 1. etapp: Builder (JAR'i ehitamine)
# ====================================
FROM gradle:8.11-jdk21-alpine AS builder

# ARG võimaldab anda proxy build-time'is (portaabel!)
ARG HTTP_PROXY
ARG HTTPS_PROXY

WORKDIR /app

# Kopeeri Gradle konfiguratsiooni failid
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Lae alla sõltuvused (cached kui build.gradle ei muutu)
# OLULINE: export GRADLE_OPTS ja gradle käsk peavad olema SAMAS RUN blokis!
RUN if [ -n "$HTTP_PROXY" ]; then \
      PROXY_HOST=$(echo "$HTTP_PROXY" | sed 's|^.*://||; s|:.*$||'); \
      PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
      export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT"; \
      gradle dependencies --no-daemon; \
    else \
      gradle dependencies --no-daemon; \
    fi

# Kopeeri lähtekood
COPY src ./src

# Ehita JAR fail
# OLULINE: Proxy seadistus tuleb korrata iga RUN käsu jaoks!
RUN if [ -n "$HTTP_PROXY" ]; then \
      PROXY_HOST=$(echo "$HTTP_PROXY" | sed 's|^.*://||; s|:.*$||'); \
      PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
      export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT"; \
      gradle bootJar --no-daemon; \
    else \
      gradle bootJar --no-daemon; \
    fi

# ====================================
# 2. etapp: Runtime (clean JRE, ilma proksita)
# ====================================
FROM eclipse-temurin:21-jre-alpine AS runtime

WORKDIR /app

# Kopeeri ainult JAR builder'ist
COPY --from=builder /app/build/libs/todo-service.jar app.jar

# Avalda port
EXPOSE 8081

# Käivita rakendus
CMD ["java", "-jar", "app.jar"]
```

**Ehita proksiga (corporate võrk):**
```bash
# Asenda oma proxy aadress!
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -t todo-service:1.0 .
```

**Ehita ilma proksita (avalik võrk):**
```bash
docker build -t todo-service:1.0 .
# Gradle download töötab avalikus võrgus
```

**Kontrolli: Kas proxy leak'ib?**
```bash
docker run --rm todo-service:1.0 env | grep -i proxy
# Oodatud: TÜHI! ✅ Proxy EI OLE runtime'is
```

**Mida õppisid?**
- ✅ Multi-stage build (Gradle build containeris!)
- ✅ ARG vs ENV (build-time vs runtime)
- ✅ Proxy ei leki (clean runtime!)
- ✅ Ei vaja host'is Java/Gradle installimist

---

**📖 Põhjalik selgitus:**

Kui vajad ARG, ENV, multi-stage build'i ja Gradle proxy konfiguratsioonide põhjalikku selgitust, loe:
- 👉 [Peatükk 06: Dockerfile Detailid](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md)
- 👉 [Peatükk 06A: Java Spring Boot Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)

**💡 Näidislahendused:**
- `solutions/backend-java-spring/Dockerfile.simple` - Variant B (2-stage Gradle containeris)
- `solutions/backend-java-spring/Dockerfile.vps-simple` - Variant A (1-stage pre-built JAR)

---

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

**⚠️ Oluline:** Sõltuvalt valitud variandist, ehitamine erineb:

#### Kui kasutad Variant A (VPS, pre-built JAR):

```bash
# 1. Ehita JAR host'is
./gradlew clean bootJar

# 2. Kontrolli JAR'i
ls -lh build/libs/

# 3. Ehita Docker tõmmis
docker build -t todo-service:1.0 .
```

#### Kui kasutad Variant B (PRIMAARNE - Gradle containeris):

```bash
# Ainult Docker build (Gradle build toimub containeris!)
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -t todo-service:1.0 .

# VÕI ilma proksita (avalik võrk):
docker build -t todo-service:1.0 .
```

**Kontrolli tõmmist:**

```bash
# Vaata kõiki tõmmiseid
docker images

# Vaata todo-service tõmmise infot
docker image inspect todo-service:1.0

# Kontrolli suurust
docker images todo-service:1.0
```

**Küsimused:**
- Kui suur on sinu tõmmis? (peaks olema ~180-230MB)
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
