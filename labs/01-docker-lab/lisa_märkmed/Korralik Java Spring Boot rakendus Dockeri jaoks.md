<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

## Korralik Java Spring Boot rakendus Dockeri jaoks

Põhjalik ülevaade, millised peavad olema nõuded arendajale, et Java Spring Boot rakendust saaks lihtsalt ja turvaliselt konteineriseerida.

***

## 1. Rakenduse struktuur ja ehitus

### Maven/Gradle konfiguratsioon

**Arendaja peab:**

- Kasutama Maven'it või Gradle'it projektihalduseks[^1][^2]
- Looma **executable JAR** faili (fat JAR ehk uber JAR), mis sisaldab kõiki sõltuvusi[^3][^4]
- Määrama Spring Boot versiooni selgesõnaliselt `pom.xml` või `build.gradle` failis[^5]
- Lisama vajalikud Spring Boot starter'id (nt `spring-boot-starter-web`)[^6]

**Näide Maven build käsk:**

```bash
mvn clean package
# või production build'i jaoks:
mvn clean install
```

**Tulemus:** `target/app.jar` fail, mis on valmis containerisse paigutamiseks.[^4][^3]

***

## 2. Dockerfile nõuded ja parimad praktikad

### 2.1 Kerge base image

**Kohustuslik:**

- Kasutada **lightweight JRE base image'i**, mitte täielikku JDK'd[^2][^1][^4]
- Eelistada `eclipse-temurin:17-jre-alpine` või `eclipse-temurin:21-jre-alpine`[^1][^2][^4]
- **Vältida** raskeid image'e nagu `openjdk` või `ubuntu`[^2]

**Miks:** Väiksem image suurus (Alpine ~100MB vs Ubuntu ~500MB+), kiirem build ja deploy, väiksem turvarisk.[^4][^2]

```dockerfile
# ❌ Halb praktika
FROM openjdk:21

# ✅ Hea praktika
FROM eclipse-temurin:21-jre-alpine
```


***

### 2.2 Multi-stage build

**Kohustuslik production keskkonna jaoks:**

- Kasutada **multi-stage build'i**, kus esimene stage ehitab rakenduse, teine stage sisaldab ainult runtime'i[^7][^8][^1]
- Vältida build-tools'ide (Maven, Gradle) jõudmist production image'i[^9][^7]

**Näide:**

```dockerfile
# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine
WORKDIR /opt/app
COPY --from=build /app/target/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Tulemus:** Final image on 70-80% väiksem ja sisaldab ainult runtime komponente.[^8][^7]

***

### 2.3 Layering ja cache optimiseerimine

**Spring Boot layering nõue:**

- Kasutada Spring Boot'i **layer index** funktsionaalsust, et eraldada sõltuvused (dependencies), Spring Boot loader, snapshot sõltuvused ja application code erinevatesse layeritesse[^10][^1]
- See võimaldab Docker'il cache'ida sõltuvusi ja muuta ainult application layer'it, kui kood muutub[^10]

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

**Dockerfile layering näide:**

```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /opt/app
COPY --from=build /app/target/app.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
```

**Tulemus:** Korduvad build'id on 5-10x kiiremad tänu cache'ile.[^1][^10]

***

### 2.4 Turvalisus (Security)

**Kohustuslik:**

1. **Ära kasuta root user'it**[^2][^4][^1]
    - Loo dedicated user ja group
    - Kasuta `USER` directive'i Dockerfile'is
```dockerfile
RUN addgroup -S javauser && adduser -S -s /usr/sbin/nologin -G javauser javauser
RUN chown -R javauser:javauser /opt/app
USER javauser
```

2. **Update base image**[^4]
    - Alpine: `apk update && apk upgrade`
    - Patch teadaolevad haavatavused
3. **Kasuta konkreetseid image tag'e, mitte `latest`**[^8][^2]
    - `eclipse-temurin:21-jre-alpine` ✅
    - `openjdk:latest` ❌
4. **Minimaalsed privilegeeritud õigused**[^6][^4]
    - Ära installi tarbetuid pakette
    - Kasuta distroless või minimal image'i

***

### 2.5 JVM memory optimiseerimine

**Arendaja peab:**

- Konfigureerima JVM memory settings container keskkonna jaoks[^2][^4]
- Kasutama `-XX:MaxRAMPercentage` ja `-XX:InitialRAMPercentage` flagsid[^4]

```dockerfile
ENTRYPOINT ["java", \
    "-XX:InitialRAMPercentage=80", \
    "-XX:MinRAMPercentage=80", \
    "-XX:MaxRAMPercentage=80", \
    "-jar", \
    "app.jar"]
```

**Miks:** Containerite memory limitid erinevad host süsteemist. Vaikimisi JVM settings võivad põhjustada OOM (Out of Memory) errori.[^2][^4]

***

## 3. Rakenduse konfiguratsioon

### 3.1 Externalized configuration

**Arendaja peab:**

- Kasutama **environment variables** tundliku info (paroolid, API võtmed, connection stringid) jaoks[^6][^4]
- Mitte hardcode'ima credential'eid koodi ega `application.properties` faili[^6]
- Toetama Spring Boot'i profile süsteemi (`application-dev.properties`, `application-prod.properties`)[^3]

**Näide Docker run command:**

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

### 3.2 Health checks ja Actuator

**Kohustuslik production keskkonna jaoks:**

- Lisada **Spring Boot Actuator** dependency[^1][^4]
- Aktiveerida health endpoint: `/actuator/health`[^1]
- Konfigureerima **HEALTHCHECK** Dockerfile'is[^1][^2]

**Maven dependency:**

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

**Miks:** Võimaldab Docker'il ja orchestraatoritel (Kubernetes, Swarm) automaatselt tuvastada, kas rakendus on töökorras.[^11][^1]

***

### 3.3 Graceful shutdown

**Arendaja peab:**

- Konfigureerima graceful shutdown'i, et vältida andmete kaotust container'i restart'i ajal[^2]
- Lisama `application.properties`:

```properties
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=30s
```


***

## 4. .dockerignore fail

**Kohustuslik:**

- Luua `.dockerignore` fail projekti root'i[^8][^2]
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

**Miks:** Väiksem build context → kiirem Docker build.[^8]

***

## 5. Nõuded arendajale - kokkuvõte

| Kategooria | Nõue | Prioriteet |
| :-- | :-- | :-- |
| **Build** | Executable JAR (fat JAR) | ✅ Kohustuslik |
| **Base image** | Lightweight JRE (eclipse-temurin:alpine) | ✅ Kohustuslik |
| **Multi-stage** | Eraldi build ja runtime stage | ✅ Production jaoks |
| **Layering** | Spring Boot layering aktiveeritud | ⚠️ Soovituslik |
| **Security** | Non-root user, konkreetne tag | ✅ Kohustuslik |
| **JVM** | Memory settings (-XX:MaxRAMPercentage) | ✅ Kohustuslik |
| **Config** | Environment variables | ✅ Kohustuslik |
| **Health** | Actuator + HEALTHCHECK | ✅ Production jaoks |
| **Shutdown** | Graceful shutdown konfig | ⚠️ Soovituslik |
| **.dockerignore** | Build context optimiseerimine | ⚠️ Soovituslik |


***

## 6. Näidis production-ready Dockerfile

```dockerfile
# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine

# Update packages
RUN apk update --no-cache && apk upgrade --no-cache

# Create non-root user
RUN addgroup -S javauser && adduser -S -s /usr/sbin/nologin -G javauser javauser

# Set up app directory
WORKDIR /opt/app
COPY --from=build /app/target/app.jar app.jar
RUN chown -R javauser:javauser /opt/app

# Switch to non-root user
USER javauser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# JVM settings and entrypoint
ENTRYPOINT ["java", \
    "-XX:InitialRAMPercentage=80", \
    "-XX:MaxRAMPercentage=80", \
    "-jar", \
    "app.jar"]
```


***

## 7. Build ja run käsud

```bash
# Build image
docker build -t myapp:1.0 .

# Run container
docker run -d \
    --name myapp \
    --env-file app.env \
    -p 8080:8080 \
    --memory="512m" \
    myapp:1.0

# Check health
docker ps
docker logs myapp

# Stop gracefully
docker stop myapp
```


***

## Kokkuvõte

Korralik konteineriseeritav Spring Boot rakendus nõuab:

1. **Executable JAR** Maven/Gradle build'ist
2. **Lightweight base image** (alpine JRE)
3. **Multi-stage build** production jaoks
4. **Non-root user** turvalisuse tagamiseks
5. **Environment variables** konfiguratsiooniks
6. **Health checks** monitooringuks
7. **JVM memory tuning** container keskkonna jaoks
8. **Layering** kiirema build'i jaoks

Need praktikad tagavad, et rakendus on **kerge, turvaline, jälgitav ja kiiresti deployable**.[^4][^1][^2]
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

