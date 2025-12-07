# Harjutus 1: Üksiku konteineri loomine (Todo Service)

**🏗️ Arhitektuurne Lähenemine:**

Nendes harjutuses õpid looma **OCI-standardset** (Open Container Initiative) Docker tõmmist, mis sobib kasutamiseks nii Docker'iga kui ka **Kubernetes orkestratsioonisüsteemidega**.
 
 See harjutus keskendub Docker põhitõdedele. **Täielikult OCI-standardne** ja **production-ready** lahendus tuleb **[Harjutus 5: Tõmmise Optimeerimine](05-optimization.md)**.

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


## 📝 Sammud

### Samm 1: Tutvu rakenduse koodiga

**Rakenduse juurkataloog:** `~/labs/apps/backend-java-spring`

Vaata Todo Service koodi:

```bash
cd ~/labs/apps/backend-java-spring
```
```bash
# Vaata faile
ls -la
```
```bash
# Loe README
cat README.md
```
```bash
# Vaata build.gradle
cat build.gradle
```

**Küsimused:**
- Millise pordiga rakendus käivitub? (8081)
- Millised sõltuvused (dependencies) on vajalikud? (vaata build.gradle)
- Kas rakendus vajab andmebaasi? (Jah, PostgreSQL)

### Samm 2: Dockerfile loomine
---

- **📖 Dockerfile põhitõed:** Kui vajad abi Dockerfile instruktsioonide (FROM, WORKDIR, COPY, RUN, CMD, ARG, multi-stage) mõistmisega, loe [Peatükk 06: Dockerfile - Rakenduste Konteineriseerimise Detailid](../../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md).
- **📖 ARG-põhine Proxy Best Practices:** Kui soovid mõista, miks ettevõtetes (nt Intel võrk) on vaja proxy serverit ja kuidas ARG-põhine proxy konfiguratsioon töötab, loe: [Docker ARG-põhine Proxy Best Practices](../../../resource/code-explanations/Docker-ARG-Proxy-Best-Practices.md).
- **📖 Gradle proxy konfiguratsioonide põhjalikku selgitust:** [Peatükk 06A: Java Spring Boot Spetsiifika](../../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)

---

####  Dockerfile loomine

**⚠️ Oluline:** Dockerfail tuleb luua rakenduse juurkataloogi `~/labs/apps/backend-java-spring`.

```bash
cd ~/labs/apps/backend-java-spring
```

**Kasutame laboris** 2-stage build Gradle containeris ARG proksiga:

```bash
vim Dockerfile
```

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

---


### Samm 3: Loo .dockerignore

Loo `.dockerignore` fail, et vältida tarbetute failide kopeerimist:

**⚠️ Oluline:** .dockerignore tuleb luua rakenduse juurkataloogi `~/labs/apps/backend-java-spring`

```bash
vim .dockerignore
```

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
**📖 Põhjalik selgitus:** [.dockerignore Selgitus](../../../resource/code-explanations/Dockerignore-Explained.md)

---

**💡 Abi vajadusel:**
Vaata näidislahendust: [`solutions/backend-java-spring/.dockerignore`](../solutions/backend-java-spring/.dockerignore)


### Samm 4: Ehita Docker tõmmis

**Asukoht:** `~/labs/apps/backend-java-spring`

**Ehita proksiga (corporate võrk):**
```bash
# Asenda oma proxy aadress!
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -t todo-service:1.0 .

# Vaata ehitamise protsessi
# Märka: iga RUN käsk loob uue kihi (layer)
```

**Ehita ilma proksita (avalik võrk):**
```bash
docker build -t todo-service:1.0 .
# ARG-id jäävad tühjaks, Gradle download töötab avalikus võrgus
```

**Kontrolli: Kas proxy leak'ib runtime'i?**
```bash
docker run --rm todo-service:1.0 env | grep -i proxy
# Oodatud: TÜHI VÄLJUND! ✅
# Proxy EI OLE runtime'is = clean, turvaline, portaabel!
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

**ℹ️ Portide turvalisus:**

Selles harjutuses kasutame lihtsustatud portide vastendust (`-p 8081:8081`).
- ✅ **Host'i tulemüür kaitseb:** VPS-is on UFW tulemüür, mis blokeerib pordi 8081 internetist
- 📚 **Tootmises oleks õige:** `-p 127.0.0.1:8081:8081` (avab pordi ainult localhost'il)
- 🎯 **Lab 2 käsitleb:** Võrguturvalisust ja reverse proxy seadistust

**Hetkel keskendume Docker põhitõdedele!**

---

#### Variant A: Ilma andmebaasita (testimiseks)

```bash
# Käivita konteiner interaktiivselt
docker run -it --name todo-service-test \
  -p 8081:8081 \
  -e DB_HOST=localhost \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-test-secret-key-min-32-chars-long \
  todo-service:1.0
```

**Märkused:**
- `-it` - interactive + tty
- `--name` - anna konteinerile nimi
- `-p 8081:8081` - portide vastendamine hostist konteinerisse
- `-e` - keskkonna muutuja

**Oodatud tulemus:**
```
❌ Error connecting to database
Connection refused...
```

**See on TÄPSELT see, mida tahame näha!** 🎉
- Konteiner käivitus ✅
- Rakendus proovis käivituda ✅
- Veateade näitab probleemi (puuduv DB) ✅
- Õppisid, kuidas Docker vigu näeb ✅

Vajuta `Ctrl+C` et peatada.

#### Variant B: Taustal töötav režiim (Detached Mode)

```bash
# Käivita taustal ehk detached režiimis (-d)
docker run -d --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-test-secret-key-min-32-chars-long \
  -e SPRING_PROFILES_ACTIVE=prod \
  todo-service:1.0
```

### Samm 6: Veatuvastus ja tõrkeotsing

```bash
# Vaata kas töötab
docker ps

# Vaata konteineri staatust
docker ps -a

# Vaata logisid
docker logs todo-service

# Vaata reaalajas
docker logs -f todo-service

# Sisene konteinerisse
docker exec -it todo-service sh

# Konteineri sees:
ls -la
java -version
env | grep DB
exit

# Inspekteeri konteinerit
docker inspect todo-service

# Vaata ressursikasutust
docker stats todo-service
```

**Miks konteiner puudub `docker ps` väljundis?**
- Konteiner käivitus, aga rakendus hangus kohe
- Docker peatas hangunud konteineri automaatselt
- `docker ps` näitab ainult TÖÖTAVAID konteinereid
- `docker ps -a` näitab KÕIKI konteinereid (ka peatatud)

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


**💡 Näidislahendused:**

Lahendused asuvad `solutions/backend-java-spring/` kaustas:
- [`Dockerfile.simple`](../solutions/backend-java-spring/Dockerfile.simple) - Variant B (2-stage Gradle containeris)
- [`Dockerfile.vps-simple`](../solutions/backend-java-spring/Dockerfile.vps-simple) - Variant A (1-stage pre-built JAR)

📂 Kõik lahendused: [`solutions/backend-java-spring/`](../solutions/backend-java-spring/)

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
