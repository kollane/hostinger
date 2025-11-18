# Harjutus 1: Single Container

**Kestus:** 45 minutit
**Eesmärk:** Konteinerise Java Spring Boot Todo Service ja õpi Dockerfile'i loomist

---

## 📋 Ülevaade

Selles harjutuses konteineriseerid Java Spring Boot Todo Service rakenduse. Õpid looma Dockerfile'i, build'ima Docker image'i ja käivitama containerit.

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

Vaata Todo Service koodi:

```bash
cd ../../apps/backend-java-spring

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

**Vihje:** Vaata Docker dokumentatsiooni või solutions/ kausta!

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

Loo `.dockerignore` fail, et vältida tarbetute failide kopeerimist:

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

Esmalt build'i JAR fail, seejärel Docker image:

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

#### Variant A: Ilma andmebaasita (testimiseks)

```bash
# Käivita container interaktiivselt
docker run -it --name todo-service-test \
  -p 8081:8081 \
  -e DB_HOST=localhost \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=test-secret \
  todo-service:1.0
```

**Märkused:**
- `-it` - interactive + tty
- `--name` - anna containerile nimi
- `-p 8081:8081` - map port 8081 host'ist container'isse
- `-e` - environment variable

**Probleam:** Rakendus ei käivitu, sest PostgreSQL puudub!

#### Variant B: Background režiimis

```bash
# Käivita taustal (detached mode)
docker run -d --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=test-secret-key \
  -e SPRING_PROFILES_ACTIVE=prod \
  todo-service:1.0

# Vaata kas töötab
docker ps

# Vaata logisid
docker logs todo-service

# Vaata reaalajas
docker logs -f todo-service
```

**Probleam:** Kui PostgreSQL ei tööta, siis rakendus crashib!

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

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [x] **Dockerfile** backend-java-spring/ kaustas
- [x] **.dockerignore** fail
- [x] **JAR fail** build/libs/todo-service.jar
- [x] **Docker image** `todo-service:1.0` (vaata `docker images`)
- [x] **Container** käivitatud (vaata `docker ps`)
- [x] Mõistad Dockerfile'i struktuuri
- [x] Oskad build'ida image'i
- [x] Oskad käivitada containerit
- [x] Oskad vaadata logisid

---

## 🧪 Testimine

### Test 1: Kas image on loodud?

```bash
docker images | grep todo-service
# Peaks näitama: todo-service 1.0 ...
```

### Test 2: Kas container töötab?

```bash
docker ps | grep todo-service
# Peaks näitama töötavat containerit
```

### Test 3: Kas rakendus vastab?

**Märkus:** See ei tööta ilma PostgreSQL'ita!

```bash
curl http://localhost:8081/health
# Oodatud vastus:
# {
#   "status": "DOWN"
# }
```

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

---

## 💡 Parimad Tavad

1. **Kasuta `.dockerignore`** - Väldi tarbetute failide kopeerimist
2. **Kasuta alpine images** - Väiksem suurus, kiirem
3. **Kasuta JRE (mitte JDK)** - Runtime ei vaja compile tools
4. **Build JAR enne Docker build'i** - Kiire rebuild, kui kood muutub
5. **Kasuta EXPOSE** - Dokumenteeri, millist porti rakendus kasutab

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
