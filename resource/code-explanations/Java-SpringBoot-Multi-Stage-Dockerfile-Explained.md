# Java Spring Boot Dockerfile – detailne seletus

See Dockerfile ehitab ja käivitab **Java Spring Boot rakendust Gradle'iga**, optimeerides suurt image'i kaheastmelise build'iga ja lisades proxy toe.

---

## BuildKit ja syntax versioon

```dockerfile
# syntax=docker/dockerfile:1.4
```

BuildKit syntax versiooni määrang - vähendab UndefinedVar hoiatusi ütleb, et kasutatakse BuildKit mootorit. Siin on oluline, sest Gradle'ile tuleb proxy-parsimise logika sees `RUN` käskudes tinglikult (`if` käsk), mida BuildKit hästi toetab.

---

## Global ARG deklaratsioonid

```dockerfile
ARG HTTP_PROXY=""
ARG HTTPS_PROXY=""
ARG NO_PROXY=""
```

Need on **global build argumentid** enne esimest `FROM`. Gradle (erinevalt npm'ist) ei loe automaatselt keskkonna muutujaid proxy jaoks – tuleb käsitsi `GRADLE_OPTS` seadistada Java süsteemi atribuutidega.

**Märkus pedagoogiline:** Kuigi BuildKit tunneb neid ARG'e automaatselt (built-in), me deklareerime need siiski eksplitsiitselt, et:
1. Dokumenteerida oodatud ARG'e (self-documenting Dockerfile)
2. Seada vaikeväärtused `""` (tühi string, mitte `undefined`)
3. Algajad näevad kohe, kust `${HTTP_PROXY}` tuleb

---

## Stage 1: Builder – Gradle build

```dockerfile
FROM gradle:8.11-jdk21-alpine AS builder
```

`gradle:8.11-jdk21-alpine` on ametlik Gradle pilt, mis sisaldab:

- **Gradle 8.11** – build tööriist
- **JDK 21** – Java Development Kit (kompileerimine)
- **Alpine Linux** – väga kerge OS baas (~5 MB)

Alpine on palju väiksem kui standardne Debian/Ubuntu, sest see on mõeldud konteinerite jaoks.

---

### Proxy ENV määramine

```dockerfile
ENV HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY}
```

Määrab keskkonna muutujaid selles stage'is. **Aga! Gradle ei kasuta neid automaatselt.** Gradle nõuab Java formaati `-Dhttp.proxyHost=` jne, mida teeb `GRADLE_OPTS` keskkonna muutuja.

---

### Gradle failide kopeerimine ja dependency download

```dockerfile
WORKDIR /app

COPY build.gradle settings.gradle ./
COPY gradle ./gradle
```

Kopeerib **ainult Gradle build konfiguratsiooni faile** – `build.gradle` (pealmine), `settings.gradle` (gradle projekte) ja `gradle/` kataloog (wrapper'id jne). **Koodi ei kopeerida veel!**

Selline järjestus lubab Dockeril cacheida dependency downloadi, kui ainult kood muutub.

```dockerfile
RUN if [ -n "$HTTP_PROXY" ]; then \
        PROXY_HOST=$(echo "$HTTP_PROXY" | sed -e 's|http://||' -e 's|https://||' -e 's|:[0-9]*$||'); \
        PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
        export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT"; \
        gradle dependencies --no-daemon; \
    else \
        gradle dependencies --no-daemon; \
    fi
```

**Mis siin juhtub:**

1. `if [ -n "$HTTP_PROXY" ]` – kontrollitakse, kas HTTP_PROXY on seadistatud (ei ole tühi).
2. `sed` ja `grep` – **parseritakse proxy aadress**:
    - PROXY_HOST eraldab hostnime: `http://proxy.com:8080` → `proxy.com`
    - PROXY_PORT eraldab pordi numbri: `http://proxy.com:8080` → `8080`
3. `export GRADLE_OPTS="-Dhttp.proxyHost=..."` – määrab **Java süsteemi atribuudid** (`-D` on Java jaoks). Gradle loeb neid ja kasutab proxy'd.
4. `gradle dependencies --no-daemon` – laadib alla kõik projekti sõltuvused (JAR failid, etc.). `--no-daemon` käivitab Gradle'd otse, mitte taustale jäävat deemoni.

**Miks see keeruline on?** Gradle ei loe `HTTP_PROXY` keskkonna muutujat otse – tuleb käsitsi Java formaati panna.

**Erinevus npm'ist:**
- **npm (Node.js):** kasutab `HTTP_PROXY` keskkonna muutujat automaatselt ✅
- **Gradle (Java):** EI kasuta `HTTP_PROXY` otse, vajab `GRADLE_OPTS` parsing'ut ❌

---

### Koodikopeerimine ja JAR build

```dockerfile
COPY src ./src
RUN if [ -n "$HTTP_PROXY" ]; then \
        PROXY_HOST=$(echo "$HTTP_PROXY" | sed -e 's|http://||' -e 's|https://||' -e 's|:[0-9]*$||'); \
        PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
        export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT"; \
        gradle bootJar --no-daemon; \
    else \
        gradle bootJar --no-daemon; \
    fi
```

Kopeerib `src/` kataloogi (Java lähtekood), seejärel käivitab **sama proxy-parsingud** ja kompileerib `gradle bootJar`. `bootJar` (Spring Boot Gradle plugin) teeb täitustava **JAR faili** – fail, millel on kõik sõltuvused sisse pakitud ja võib käivitada `java -jar ...` käsuga.

Väljund jääb kataloogisse `/app/build/libs/todo-service.jar` (konkreetne fail oleneb `application.properties` või `build.gradle` seadistusest).

---

## Stage 2: Runtime – JAR käitamine

```dockerfile
FROM eclipse-temurin:21-jre-alpine
```

Uus, puhas pilt **ainult Java Runtime Environment'iga** (JRE, mitte täis JDK). JRE on väiksem, sest ei ole kompilatoorit (`javac` jne), vaid ainult JVM käitamise jaoks.

`eclipse-temurin` on ametlik Java pilt, mis on suurem muidugi kui `alpine` üksinda, aga väiksem kui täis gradle pilt.

**Multi-stage build'i eelis:**
- **Builder stage:** Gradle (800MB) + JDK (400MB) + sõltuvused
- **Runtime stage:** Ainult JRE (200MB) + JAR fail
- **Tulemus:** 69% väiksem image (800MB → 250MB)

---

### Non-root kasutaja loomine (Alpine Linuxi käsud)

```dockerfile
RUN addgroup -g 1001 -S spring && \
    adduser -S spring -u 1001 -G spring
```

`addgroup` ja `adduser` on **Alpine Linuxi käsud** (erinevad Debian'i `groupadd`/`useradd`'ist):

- `addgroup -g 1001 -S spring` – loob grupi `spring` GID 1001, `-S` teeb süsteemi grupi.
- `adduser -S spring -u 1001 -G spring` – loob kasutaja `spring` UID 1001, kuulub gruppi `spring`, `-S` on süsteemi kasutaja (ei ole login shell'i).

**Erinevus Debian'ist:**
- **Debian (node:22-slim):** `groupadd -g 1001 nodejs && useradd -r -u 1001 -g nodejs nodejs`
- **Alpine (eclipse-temurin:21-jre-alpine):** `addgroup -g 1001 -S spring && adduser -S spring -u 1001 -G spring`

Turvalisus: konteiner jookseb vähe õiguste kasutajaga, mitte root'iga.

---

### JAR kopeerimine

```dockerfile
COPY --from=builder --chown=spring:spring /app/build/libs/todo-service.jar app.jar
```

Kopeerib **ainult kompileeritud JAR faili** builder stage'ist. Kõik teised failid (lähtekood, Gradle cache, sõltuvuste alla laaditud failid) jäetakse sinna – finaalse image'i suurust vähendatakse drastiliselt.

`--chown=spring:spring` määrab omanikuks `spring` kasutaja ja grupi.

---

### Non-root aktiveerimine

```dockerfile
USER spring:spring
```

Käsk määrab, et **kõik järgnevad käsud ja konteiner jooksevad kasutajana `spring`**.

---

### Pordi avamine

```dockerfile
EXPOSE 8081
```

Dokumenteerib, et app kuulab pordi 8081 (Spring Boot default on 8080, siin on näiteks muudetud).

---

## HEALTHCHECK – keskkonda teadlik tervise kontroll

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/health || exit 1
```

- `--interval=30s` – iga 30 sekundi tagant käivitab kontrolli.
- `--timeout=3s` – kui vastus kestab üle 3 sekundi, loetakse ebaõnnestunuks.
- `--start-period=40s` – esimesed 40 sekundit saab app käivituda (Spring Boot käivitus on aeglasem kui Node.js!), esimesed testid ei märgi "unhealthy" konteinerit.
- `CMD wget --no-verbose --tries=1 --spider http://localhost:8081/health || exit 1`:
    - `wget` – HTTP päring (levinud Alpine'is)
    - `--no-verbose --tries=1 --spider` – vaikne, üks katse, ainult HEAD päringu (ei lae body'd)
    - `http://localhost:8081/health` – Spring Boot actuator `/health` endpoint (tavaliselt defineeritud `spring-boot-starter-actuator` pluginil)
    - `|| exit 1` – kui wget ebaõnnestub, väljub koodiga 1 (unhealthy)

Spring Boot annab vaikimisi `/health` endpoint'i, mis tagastab JSON'i `{"status":"UP"}`, kui app on terve.

**Erinevus Node.js'ist:**
- **Node.js:** Custom `healthcheck.js` skript (HTTP request http module'iga)
- **Java Spring Boot:** Sisseehitatud `/health` endpoint (Spring Boot Actuator) + `wget` käsk

---

## JVM käivitumine ja RAM-i häälestus

```dockerfile
CMD ["java", \
    "-XX:InitialRAMPercentage=80", \
    "-XX:MaxRAMPercentage=80", \
    "-jar", \
    "app.jar"]
```

Käsk käivitab Java rakendust.

### JVM flags

- `-XX:InitialRAMPercentage=80` – määrab **algne heap suurus 80% konteineri RAM'ist**.
- `-XX:MaxRAMPercentage=80` – määrab **maksimaalne heap suurus 80% konteineri RAM'ist**.

**Miks see oluline?** Vaikimisi JVM võttis kogu arvutis saadaoleva RAM'i, mitte konteineri limiti. Näiteks kui host-arvutil on 32 GB, aga konteiner piiratakse 512 MB'ga (`docker run -m 512m`), teeks JVM siiski heap'i 16 GB, mis põhjustab OOM (out of memory) tappimise.

`InitialRAMPercentage=80` ja `MaxRAMPercentage=80` ütlevad JVM'ile, et **kasuta konteineris allokeeritud RAM'i**, mitte host'i RAM'i. Need flagid on container-aware.

- `-jar app.jar` – käivitab Spring Boot JAR faili otse.

**Erinevus Node.js'ist:**
- **Node.js:** Automaatselt container-aware, ei vaja tuning'ut
- **Java:** Vajab `-XX:InitialRAMPercentage` ja `-XX:MaxRAMPercentage` flag'e

---

## Kokkuvõte: ehituse erinevused Node.js'i ja Java vahel

| Omadus | Node.js (npm) | Java (Gradle) |
| :-- | :-- | :-- |
| **Proxy tugi** | npm loeb automaatselt `HTTP_PROXY` env'i | Gradle nõuab käsitsi `GRADLE_OPTS` Java atribuute |
| **Dependencies download** | `npm ci` – üks käsk | `gradle dependencies` – eraldi samm |
| **Build artifact** | `node_modules/` kataloog | Üks täitustav `app.jar` fail |
| **Runtime base** | `node:22-slim` | `eclipse-temurin:21-jre-alpine` |
| **Health check** | Custom `healthcheck.js` skript | Spring Actuator `/health` endpoint + `wget` |
| **Memory tuning** | Node.js automaatselt teadlik containerist | JVM nõuab `-XX:InitialRAMPercentage` jne |
| **Non-root user** | `groupadd`/`useradd` (Debian) | `addgroup`/`adduser` (Alpine) |
| **Multi-stage eelis** | Sõltuvuste kiht cached | JDK → JRE eraldamine (69% väiksem) |

---

## Praktiline kasutamine

Sellise Dockerfile'iga saad ehitada käsuga:

```bash
docker build \
  --build-arg HTTP_PROXY=http://proxy.company.com:8080 \
  -t my-spring-app:latest .
```

Või ilma proxy'ta:

```bash
docker build -t my-spring-app:latest .
```

Käivitada saad:

```bash
docker run -p 8081:8081 -m 512m my-spring-app:latest
```

`-m 512m` piirab konteineri 512 MB'ga, ja JVM'ile seadistatud `MaxRAMPercentage=80` kasutab õigesti 80% sellest (~410 MB).

---

## Kokkuvõte: miks see Dockerfile tugev?

- **Mitmeastmeline build** – finaalse image'i suurus väiksem (ei ole Gradle, kompilaator, lähtekood, build cachid) - 69% väiksem (800MB → 250MB).
- **Proxy parsimine** – funktsioonil töötab korporatiivsetes keskkondades (Gradle GRADLE_OPTS parsing).
- **Dependency caching** – `build.gradle` muutumisel taaskäivitub ainult build, mitte dependency download.
- **Non-root turvalisus** – konteiner jookseb piiratult (spring:1001).
- **Container-aware JVM** – RAM'i häälestus teab, mis on konteineri limit, mitte host'i limit.
- **Health check** – orkestreerimise süsteemid teavad, kas app terve (Spring Boot Actuator).
- **Alpine baas** – kerge, ohutu image'i jaoks.

---

**Tüüp:** Koodiselgitus (KOODISELGITUS)
**Kasutatakse:** Lab 1, Harjutus 05 (Java Spring Boot optimeeritud Dockerfile)
**Viimane uuendus:** 2025-01-25
**Allikas:** AI-genereeritud selgitus (Perplexity AI), kohandatud TERMINOLOOGIA.md reeglite järgi
