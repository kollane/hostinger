# Docker Best Practices: Java Spring Boot

Täiendavad advanced teemad backend-java-spring rakenduse konteineriseerimiseks.

> **Märkus:** Põhiline Dockerfile ja multi-stage build on juba valmis. Vaata:
> - `Dockerfile.optimized` - Production-ready multi-stage build
> - [Lab 1 Harjutus 1b](/labs/01-docker-lab/exercises/01b-single-container-java.md) - Põhjalik konteineriseerimise juhend

***

## 1. JVM Memory Tuning Containerites

### Probleem

Containerite memory limitid erinevad host süsteemist. Vaikimisi JVM settings võivad põhjustada **OOM (Out of Memory) errori**, kuna JVM ei tea container'i tegelikku memory limiti.

### Lahendus

Kasuta `-XX:MaxRAMPercentage` ja `-XX:InitialRAMPercentage` flagsid, mis võimaldavad JVM-il automaatselt tuvastada container'i memory limiti ja seadistada end vastavalt.

**Dockerfile ENTRYPOINT näide:**

```dockerfile
ENTRYPOINT ["java", \
    "-XX:InitialRAMPercentage=80", \
    "-XX:MinRAMPercentage=80", \
    "-XX:MaxRAMPercentage=80", \
    "-jar", \
    "app.jar"]
```

**Selgitus:**
- `InitialRAMPercentage=80` - JVM kasutab 80% container'i RAM-ist heap'i algvärtusena
- `MaxRAMPercentage=80` - Maksimaalne heap suurus on 80% container'i RAM-ist
- Jääb 20% süsteemile ja metaspace'ile

**Docker run näide memory limitiga:**

```bash
docker run -d \
    --name todo-service \
    --memory="512m" \
    -p 8081:8081 \
    todo-service:1.0
```

**Tulemus:** JVM kasutab `~410MB` heap'i (80% × 512MB), jäädes container'i limiti piiresse.

***

## 2. Spring Boot Layering

### Probleem

Tavaliselt Docker kopeerib terve JAR faili ühte layer'isse. Kui muudad rakenduse koodi ühe rea võrra, peab Docker rebuild'ima terve layer'i, sh kõik sõltuvused (dependencies), mis on ajakulukas.

### Lahendus

Spring Boot 2.3+ toetab **layer index** funktsionaalsust, mis eraldab JAR faili osadeks:
1. **Dependencies** - välised teegid (muutuvad harva)
2. **Spring Boot Loader** - Spring Boot infrastruktuur (muutub harva)
3. **Snapshot Dependencies** - SNAPSHOT versioonid (muutuvad keskmiselt)
4. **Application** - sinu kood (muutub sageli)

**Tulemus:** Docker cache'ib dependencies layer'i ja rebuild'ib ainult application layer'i, kui kood muutub.

### Kuidas aktiveerida

**Maven (pom.xml):**

```xml
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
        <layers>
            <enabled>true</enabled>
        </layers>
    </configuration>
</plugin>
```

**Gradle (build.gradle):**

```gradle
tasks.named('bootJar') {
    layered {
        enabled = true
    }
}
```

### Dockerfile layering näide

```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /opt/app

# Kopeeri JAR
COPY --from=build /app/build/libs/app.jar app.jar

# Ekstrakteeri layers
RUN java -Djarmode=layertools -jar app.jar extract

# Kopeeri layers õiges järjekorras (harva muutuvad enne)
COPY --from=extract dependencies/ ./
COPY --from=extract spring-boot-loader/ ./
COPY --from=extract snapshot-dependencies/ ./
COPY --from=extract application/ ./

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
```

**Kasu:** Korduvad build'id on **5-10x kiiremad** tänu cache'ile.

***

## 3. Graceful Shutdown

### Probleem

Kui Docker peatab container'i (`docker stop`), saadetakse rakendusele SIGTERM signaal. Vaikimisi Spring Boot peatab rakenduse kohe, mis võib põhjustada:
- Pooleliolevate HTTP päringute katkemist
- Andmete kaotust (nt transaktsiooni pooleli jäämine)
- Halba kasutajakogemust

### Lahendus

Konfigureeri **graceful shutdown**, mis võimaldab rakendusele lõpetada pooleliolevad päringud enne sulgemist.

**application.properties:**

```properties
# Graceful shutdown
server.shutdown=graceful

# Timeout graceful shutdown'i jaoks (maksimaalne aeg)
spring.lifecycle.timeout-per-shutdown-phase=30s
```

**application.yml:**

```yaml
server:
  shutdown: graceful

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s
```

**Kuidas see töötab:**
1. Docker saadab SIGTERM signaali
2. Spring Boot lõpetab uute päringute vastuvõtmise
3. Ootab kuni 30 sekundit, et pooleliolevad päringud lõpetaksid
4. Sulgeb rakenduse

**Docker stop käsu timeout:**

```bash
# Annan rakendusele 40 sekundit graceful shutdown'i jaoks
docker stop --time=40 todo-service
```

**Kubernetes deployment näide:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-service
spec:
  template:
    spec:
      containers:
      - name: todo-service
        image: todo-service:1.0
      terminationGracePeriodSeconds: 40  # Peab olema > timeout-per-shutdown-phase
```

***

## 4. Spring Boot Actuator Health Checks

**Actuator dependency** on juba lisatud `build.gradle` failis:

```gradle
implementation 'org.springframework.boot:spring-boot-starter-actuator'
```

**Dockerfile HEALTHCHECK** (juba olemas `Dockerfile.optimized`'is):

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1
```

**Actuator endpoint'id:**
- `/actuator/health` - Health status
- `/actuator/info` - Rakenduse info
- `/actuator/metrics` - Metrikud

**Konfigureerimine (application.properties):**

```properties
# Avalda health endpoint
management.endpoints.web.exposure.include=health,info,metrics

# Näita detailseid health komponente
management.endpoint.health.show-details=always
```

***

## 5. Turvalisus - Non-Root User

**Dockerfile.optimized** kasutab juba non-root user'it:

```dockerfile
# Loo dedicated user
RUN addgroup -S javauser && adduser -S -s /usr/sbin/nologin -G javauser javauser

# Seadista õigused
RUN chown -R javauser:javauser /opt/app

# Vaheta non-root user'ile
USER javauser
```

**Miks see on oluline:**
- ✅ Vähendab turvariski (konteinerist ei saa root access host süsteemile)
- ✅ Production best practice
- ✅ Kubernetes PodSecurityPolicy nõuab seda

***

## 6. Best Practices Checklist

| Nõue | Prioriteet | Staatus backend-java-spring |
| :-- | :-- | :-- |
| **Executable JAR (fat JAR)** | ✅ Kohustuslik | ✅ Valmis (Gradle bootJar) |
| **Lightweight JRE base image** | ✅ Kohustuslik | ✅ Valmis (eclipse-temurin:21-jre-alpine) |
| **Multi-stage build** | ✅ Production | ✅ Valmis (Dockerfile.optimized) |
| **Non-root user** | ✅ Kohustuslik | ✅ Valmis (javauser) |
| **Health checks (Actuator)** | ✅ Production | ✅ Valmis (HEALTHCHECK + Actuator) |
| **JVM memory settings** | ✅ Kohustuslik | ✅ Valmis (Dockerfile.optimized uuendatud) |
| **Spring Boot layering** | ⚠️ Soovituslik | ❌ Valikuline (build.gradle'is pole aktiveeritud) |
| **Graceful shutdown** | ⚠️ Soovituslik | ⚠️ Vajalik lisada application.properties'isse |
| **.dockerignore** | ⚠️ Soovituslik | ✅ Valmis |
| **Environment variables** | ✅ Kohustuslik | ✅ Valmis (.env + docker-compose.yml) |

***

## 7. Näited ja Viited

### Olemasolevad failid

- **Dockerfile.optimized** - Production-ready multi-stage build koos JVM tuning'uga
- **.dockerignore** - Välistab tarbetud failid
- **build.gradle** - Gradle konfiguratsioon Spring Boot'iga
- **application.properties** - Rakenduse konfiguratsioon
- **docker-compose.yml** - Kogu stack (PostgreSQL + Todo Service)

### Lab harjutused

- **Lab 1 Harjutus 1b** - Java Spring Boot konteineriseerimine
- **Lab 1 Harjutus 5** - Optimisation (multi-stage build, cache, size)
- **Lab 2 Harjutus 2b** - Docker Compose (PostgreSQL + backend)

### Docker käsud

```bash
# Build optimeeritud image
docker build -f Dockerfile.optimized -t todo-service:1.0-opt .

# Run memory limitiga
docker run -d \
    --name todo-service \
    --env-file .env \
    --memory="512m" \
    --cpus="1.0" \
    -p 8081:8081 \
    todo-service:1.0-opt

# Kontrolli health
docker ps  # Peaks näitama "healthy" status
docker logs todo-service

# Graceful stop
docker stop --time=40 todo-service
```

***

## 8. Kokkuvõte

Backend-java-spring rakendus on **production-ready** järgmiste omadustega:

✅ **Kerge image:** Alpine-based JRE (~180MB optimeeritud vs ~500MB tavaline)
✅ **Turvaline:** Non-root user, konkreetne image tag, minimaalsed privilegeeritud õigused
✅ **Optimeeritud:** Multi-stage build, väike image suurus, kiire build cache
✅ **Monitooritav:** Health checks, Actuator endpoints
✅ **Container-aware:** JVM memory tuning, õiged limitid

**Täiendamiseks:**
- ⚠️ **Graceful shutdown:** Lisa `server.shutdown=graceful` application.properties'isse
- ⚠️ **Spring Boot layering:** Aktiveeri build.gradle'is (valikuline, optimeerib build cache)

***

## Viited

- [Spring Boot Docker Official Guide](https://spring.io/guides/gs/spring-boot-docker)
- [Spring Boot Efficient Images](https://docs.spring.io/spring-boot/reference/packaging/container-images/efficient-images.html)
- [JVM Container Settings](https://docs.oracle.com/en/java/javase/17/docs/specs/man/java.html#java-options)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
