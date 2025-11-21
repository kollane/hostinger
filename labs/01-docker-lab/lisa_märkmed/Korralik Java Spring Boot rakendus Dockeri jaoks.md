<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## Korralik Java Spring Boot rakendus (application) Dockeri jaoks

Põhjalik ülevaade, millised peavad olema nõuded arendajale, et Java Spring Boot rakendust (application) saaks lihtsalt ja turvaliselt konteineriseerida.

***

## 1. Rakenduse (application) struktuur ja ehitus (build)

### Maven/Gradle konfiguratsioon

**Arendaja peab:**

- Kasutama Maven'it või Gradle'it projektihalduseks[^1][^2]
- Looma **executable JAR** faili (fat JAR ehk uber JAR), mis sisaldab kõiki sõltuvusi (dependencies)[^3][^4]
- Määrama Spring Boot versiooni selgesõnaliselt `pom.xml` või `build.gradle` failis[^5]
- Lisama vajalikud Spring Boot starter'id (nt `spring-boot-starter-web`)[^6]

**Näide Maven ehituse (build) käsk:**

```bash
mvn clean package
# või production ehituse (build) jaoks:
mvn clean install
```

**Tulemus:** `target/app.jar` fail, mis on valmis konteinerisse paigutamiseks.[^4][^3]

***

## 2. Dockerfile nõuded ja parimad praktikad (best practices)

### 2.1 Kerge baaspilt (base image)

**Kohustuslik:**

- Kasutada **kerget (lightweight) JRE baaspilti (base image)**, mitte täielikku JDK'd[^2][^1][^4]
- Eelistada `eclipse-temurin:17-jre-alpine` või `eclipse-temurin:21-jre-alpine`[^1][^2][^4]
- **Vältida** raskeid pilte (images) nagu `openjdk` või `ubuntu`[^2]

**Miks:** Väiksem pildi (image) suurus (Alpine ~100MB vs Ubuntu ~500MB+), kiirem ehitus (build) ja paigaldus (deploy), väiksem turvarisk.[^4][^2]

```dockerfile
# ❌ Halb praktika
FROM openjdk:21

# ✅ Hea praktika
FROM eclipse-temurin:21-jre-alpine
```


***

### 2.2 Mitme-sammuline (multi-stage) ehitus (build)

**Kohustuslik production keskkonna jaoks:**

- Kasutada **mitme-sammulist (multi-stage) ehitust (build)**, kus esimene etapp ehitab rakenduse (application), teine etapp sisaldab ainult runtime'i[^7][^8][^1]
- Vältida ehitustööriistade (build-tools) (Maven, Gradle) jõudmist tootmispilti (production image)[^9][^7]

**Näide:**

```dockerfile
# 1. etapp: Ehitus (Build)
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# 2. etapp: Runtime
FROM eclipse-temurin:21-jre-alpine
WORKDIR /opt/app
COPY --from=build /app/target/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Tulemus:** Lõplik pilt (image) on 70-80% väiksem ja sisaldab ainult runtime komponente.[^8][^7]

***

### 2.3 Kihtide (Layering) ja vahemälu (cache) optimeerimine

**Spring Boot kihtide (layering) nõue:**

- Kasutada Spring Boot'i **kihtide indeksi (layer index)** funktsionaalsust, et eraldada sõltuvused (dependencies), Spring Boot laadija (loader), snapshot sõltuvused (dependencies) ja rakenduse (application) kood erinevatesse kihtidesse (layers)[^10][^1]
- See võimaldab Docker'il vahemällu (cache) salvestada sõltuvusi (dependencies) ja muuta ainult rakenduse (application) kihti (layer), kui kood muutub[^10]

**Kuidas aktiveerida (Maven):**

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

**Dockerfile kihtide (layering) näide:**

```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /opt/app
COPY --from=build /app/target/app.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
```

**Tulemus:** Korduvad ehitused (builds) on 5-10x kiiremad tänu vahemälule (cache).[^1][^10]

***

### 2.4 Turvalisus (Security)

**Kohustuslik:**

1. **Ära kasuta root user'it**[^2][^4][^1]
    - Loo dedicated user ja group
    - Kasuta `USER` direktiivi Dockerfile'is
```dockerfile
RUN addgroup -S javauser && adduser -S -s /usr/sbin/nologin -G javauser javauser
RUN chown -R javauser:javauser /opt/app
USER javauser
```

2. **Uuenda baaspilti (base image)**[^4]
    - Alpine: `apk update && apk upgrade`
    - Patch teadaolevad haavatavused
3. **Kasuta konkreetseid pildi (image) tag'e, mitte `latest`**[^8][^2]
    - `eclipse-temurin:21-jre-alpine` ✅
    - `openjdk:latest` ❌
4. **Minimaalsed privilegeeritud õigused**[^6][^4]
    - Ära installi tarbetuid pakette
    - Kasuta distroless või minimaalset pilti (image)

***

### 2.5 JVM memory optimiseerimine

**Arendaja peab:**

- Konfigureerima JVM mälu seadeid konteineri keskkonna jaoks[^2][^4]
- Kasutama `-XX:MaxRAMPercentage` ja `-XX:InitialRAMPercentage` lippe[^4]

```dockerfile
ENTRYPOINT ["java", \
    "-XX:InitialRAMPercentage=80", \
    "-XX:MinRAMPercentage=80", \
    "-XX:MaxRAMPercentage=80", \
    "-jar", \
    "app.jar"]
```

**Miks:** Konteinerite mälulimiidid erinevad host süsteemist. Vaikimisi JVM seaded võivad põhjustada OOM (Out of Memory) vea (error).[^2][^4]

***

## 3. Rakenduse (application) konfiguratsioon

### 3.1 Väline (Externalized) konfiguratsioon

**Arendaja peab:**

- Kasutama **keskkonna muutujaid (environment variables)** tundliku info (paroolid, API võtmed, ühendusstringid) jaoks[^6][^4]
- Mitte hoidma mandaate (credentials) koodis ega `application.properties` failis[^6]
- Toetama Spring Boot'i profiilisüsteemi (`application-dev.properties`, `application-prod.properties`)[^3]

**Näide Docker run käsk:**

```bash
docker run --env-file app.env -p 8080:8080 app:latest
```

**app.env fail:**

```
SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/mydb
SPRING_DATASOURCE_USERNAME=user
SPRING_DATASOURCE_PASSWORD=secret
```


***

### 3.2 Seisukorra kontrollid (Health checks) ja Actuator

**Kohustuslik production keskkonna jaoks:**

- Lisada **Spring Boot Actuator** sõltuvus (dependency)[^1][^4]
- Aktiveerida seisukorra (health) lõpp-punkt (endpoint): `/actuator/health`[^1]
- Konfigureerima **HEALTHCHECK** Dockerfile'is[^1][^2]

**Maven sõltuvus (dependency):**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

**Dockerfile HEALTHCHECK:**

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1
```

**Miks:** Võimaldab Docker'il ja orkestraatoritel (Kubernetes, Swarm) automaatselt tuvastada, kas rakendus (application) on töökorras.[^11][^1]

***

### 3.3 Viisakas sulgemine (Graceful shutdown)

**Arendaja peab:**

- Konfigureerima viisaka sulgemise (graceful shutdown), et vältida andmete kaotust konteineri taaskäivitamise (restart) ajal[^2]
- Lisama `application.properties`:

```properties
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s
```


***

## 4. .dockerignore fail

**Kohustuslik:**

- Luua `.dockerignore` fail projekti juurkausta[^8][^2]
- Välistada tarbetud failid (target/, build/, .git/, .idea/, *.log)[^8]

**Näide .dockerignore:**

```
target/
build/
.git/
.idea/
*.log
*.md
.DS_Store
```

**Miks:** Väiksem ehituskontekst (build context) → kiirem Docker ehitus (build).[^8]

***

## 5. Nõuded arendajale - kokkuvõte

| Kategooria | Nõue | Prioriteet |
| :-- | :-- | :-- |
| **Ehitus (Build)** | Käivitatav JAR (fat JAR) | ✅ Kohustuslik |
| **Baaspilt (Base image)** | Kerge JRE (eclipse-temurin:alpine) | ✅ Kohustuslik |
| **Mitme-sammuline (Multi-stage)** | Eraldi ehituse (build) ja runtime etapp | ✅ Production jaoks |
| **Kihtideks jaotamine (Layering)** | Spring Boot kihtideks jaotamine (layering) aktiveeritud | ⚠️ Soovituslik |
| **Turvalisus** | Mitte-juurkasutaja (non-root user), konkreetne tag | ✅ Kohustuslik |
| **JVM** | Mälu seaded (-XX:MaxRAMPercentage) | ✅ Kohustuslik |
| **Konfiguratsioon** | Keskkonna muutujad (Environment variables) | ✅ Kohustuslik |
| **Tervis** | Actuator + HEALTHCHECK | ✅ Production jaoks |
| **Sulgemine (Shutdown)** | Viisakas sulgemine (graceful shutdown) konfig | ⚠️ Soovituslik |
| **.dockerignore** | Ehituskonteksti (build context) optimeerimine | ⚠️ Soovituslik |


***

## 6. Näidis tootmisvalmis (production-ready) Dockerfile

```dockerfile
# 1. etapp: Ehitus (Build)
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# 2. etapp: Runtime
FROM eclipse-temurin:21-jre-alpine

# Uuenda pakette
RUN apk update --no-cache && apk upgrade --no-cache

# Loo mitte-juurkasutaja (non-root user)
RUN addgroup -S javauser && adduser -S -s /usr/sbin/nologin -G javauser javauser

# Seadista rakenduse (app) kataloog
WORKDIR /opt/app
COPY --from=build /app/target/app.jar app.jar
RUN chown -R javauser:javauser /opt/app

# Lülitu mitte-juurkasutajale (non-root user)
USER javauser

# Paljasta port
EXPOSE 8080

# Seisukorra kontroll (Health check)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# JVM seaded ja sisenemispunkt (entrypoint)
ENTRYPOINT ["java", \
    "-XX:InitialRAMPercentage=80", \
    "-XX:MaxRAMPercentage=80", \
    "-jar", \
    "app.jar"]
```


***

## 7. Ehituse (build) ja käivitamise (run) käsud

```bash
# Ehita (build) pilt (image)
docker build -t myapp:1.0 .

# Käivita konteiner
docker run -d \
    --name myapp \
    --env-file app.env \
    -p 8080:8080 \
    --memory="512m" \
    myapp:1.0

# Kontrolli tervist
docker ps
docker logs myapp

# Peata viisakalt
docker stop myapp
```


***

## Kokkuvõte

Korralik konteineriseeritav Spring Boot rakendus (application) nõuab:

1. **Käivitatav JAR** Maven/Gradle ehitusest (build)
2. **Kerge baaspilt (base image)** (alpine JRE)
3. **Mitme-sammuline (multi-stage) ehitus (build)** tootmise jaoks
4. **Mitte-juurkasutaja (non-root user)** turvalisuse tagamiseks
5. **Keskkonna muutujad (environment variables)** konfiguratsiooniks
6. **Seisukorra kontrollid (health checks)** monitooringuks
7. **JVM mälu häälestamine** konteineri keskkonna jaoks
8. **Kihtideks jaotamine (Layering)** kiirema ehituse (build) jaoks

Need praktikad tagavad, et rakendus (application) on **kerge, turvaline, jälgitav ja kiiresti paigaldatav (deployable)**.[^4][^1][^2]
<span style="display:none">[^12][^13][^14][^15][^16][^17][^18][^19][^20]</span>

<div align="center">⁂</div>

[^1]: https://mydeveloperplanet.com/2022/12/14/spring-boot-docker-best-practices/

[^2]: https://www.javaguides.net/2025/02/docker-best-practices-for-java.html

[^3]: https://masteringbackend.com/posts/spring-boot-docker-dockerizing-java-spring-boot-apps

[^4]: https://gpiskas.com/posts/creating-slim-production-ready-docker-images-java-apps/

[^5]: https://www.geeksforgeeks.org/java/containerizing-java-applications-creating-a-spring-boot-app-using-dockerfile/

[^6]: https://javapro.io/2025/07/03/how-to-containerize-a-java-application-securely/

[^7]: https://bell-sw.com/videos/dockerize-spring-boot-wisely-6-tips-to-improve-the-container-images-of-your-spring-boot-apps/

[^8]: https://www.docker.com/blog/9-tips-for-containerizing-your-spring-boot-code/

[^9]: https://blog.frankel.ch/hitchhiker-guide-containerizing-java-apps/

[^10]: https://docs.spring.io/spring-boot/reference/packaging/container-images/efficient-images.html

[^11]: https://lumigo.io/container-monitoring/docker-health-check-a-practical-guide/

[^12]: https://nirmata.com/2016/08/23/create-and-deploy-spring-based-java-application-in-containers-using-docker/

[^13]: https://dev.to/wittedtech-by-harshit/devops-dockerizing-your-spring-boot-app-7kc

[^14]: https://learn.microsoft.com/en-us/azure/container-apps/java-containers-intro

[^15]: https://gist.github.com/nik-sta/9b29ed544caa284031878d7fd51af603

[^16]: https://drlee.io/build-a-spring-boot-microservice-with-docker-in-the-cloud-3857406171f1

[^17]: https://spring.io/guides/gs/spring-boot-docker

[^18]: https://blog.devops.dev/spring-boot-deployment-best-practices-from-monolith-to-microservices-️-️-d87a7a4954ef

[^19]: https://faun.pub/application-containerization-a-beginners-guide-f251331268dd

[^20]: https://stackoverflow.com/questions/71697307/best-practices-while-building-docker-images-for-spring-boot-app-via-gradle

