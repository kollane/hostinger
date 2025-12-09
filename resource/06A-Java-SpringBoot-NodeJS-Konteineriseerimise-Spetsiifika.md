# Peatükk 6A: Java/Spring Boot ja Node.js Rakenduste Konteineriseerimise Spetsiifika

## Õpieesmärgid

Peale selle peatüki läbimist oskad:
- ✅ Mõista traditsioonilist Java deployment'i (WAR failid Tomcat serveris)
- ✅ Selgitada Spring Boot embedded server lähenemist
- ✅ Võrrelda WAR Tomcat vs JAR konteiner deployment strategy'sid
- ✅ Luua optimeeritud multi-stage Dockerfile Java Spring Boot rakendusele (Gradle ja Maven)
- ✅ Tuunida JVM konteinerikeskkonnas (heap size, GC, container-awareness)
- ✅ Konteinerdada Node.js rakendusi (põhitõed ja best practices)
- ✅ Optimeerida image size'i Java ja Node.js rakenduste jaoks

## Põhimõisted

- **WAR (Web Application Archive):** Java web rakenduse pakendusformaat (ZIP arhiiv), mis deploy'itakse application serverisse (Tomcat, Jetty, WebLogic).
- **Tomcat:** Apache Tomcat - Java Servlet/JSP container, mis jookseb eraldi protsessina ja hostib mitmeid WAR rakendusi.
- **Embedded Server:** Spring Boot sisseehitatud veebiserver (Tomcat, Jetty, Undertow), mis on pakitud JAR faili sisse.
- **Executable JAR (Fat JAR):** Käivitatav JAR fail, mis sisaldab rakendust JA kõiki sõltuvusi (libs, embedded server). Käivitamine: `java -jar app.jar`.
- **Spring Boot:** Opinionated framework, mis lihtsustab Spring rakenduste loomist (convention over configuration, embedded server, auto-configuration).
- **Maven vs Gradle:** Build automation tools Java jaoks. Maven kasutab XML (pom.xml), Gradle kasutab Groovy/Kotlin DSL (build.gradle).
- **JVM Tuning:** Java Virtual Machine'i parameetrite optimeerimine (heap size, GC strategy, thread pool size) konteinerikeskkonnas.
- **Container-aware JVM:** Java 10+ feature, mis võimaldab JVM'il "näha" konteineri resource limit'e (CPU, memory) ja kohanduda vastavalt.

## Teooria

### 1. Traditsiooniline Java Web Deployment - WAR Tomcat Serveris

Enne Spring Boot'i (ja mikroteenuseid) deploy'iti Java web rakendusi **application serveritesse** nagu Tomcat, JBoss, WebLogic, WebSphere.

#### WAR Faili Struktuur

WAR (Web Application Archive) on ZIP arhiiv järgmise struktuuriga:

```
myapp.war
├── META-INF/
│   └── MANIFEST.MF
├── WEB-INF/
│   ├── web.xml              ← Deployment descriptor (servlet mapping, filters)
│   ├── classes/              ← Compiled Java classes
│   │   └── com/myapp/
│   │       ├── controllers/
│   │       ├── services/
│   │       └── models/
│   ├── lib/                  ← JAR sõltuvused (Spring, Hibernate, JDBC drivers)
│   │   ├── spring-core-5.3.jar
│   │   ├── hibernate-core-6.1.jar
│   │   └── postgresql-42.5.jar
│   └── views/                ← JSP files (kui kasutad JSP)
│       └── index.jsp
└── static/                   ← Static assets (CSS, JS, images)
    ├── css/
    ├── js/
    └── images/
```

#### Tomcat Server Setup ja Deployment Workflow

**Tomcat install ja setup (traditional):**

```bash
# 1. Download Tomcat
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.15/bin/apache-tomcat-10.1.15.tar.gz
tar -xzf apache-tomcat-10.1.15.tar.gz
mv apache-tomcat-10.1.15 /opt/tomcat

# 2. Configure Tomcat (server.xml, context.xml, tomcat-users.xml)
vi /opt/tomcat/conf/server.xml
# Set port (default 8080)
# <Connector port="8080" protocol="HTTP/1.1" .../>

# 3. Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export CATALINA_HOME=/opt/tomcat

# 4. Start Tomcat
/opt/tomcat/bin/startup.sh
# Tomcat käivitub http://localhost:8080
```

**Deploy WAR file:**

```bash
# Build WAR (Maven)
mvn clean package
# Tulemus: target/myapp.war

# Deploy Tomcat'i (copy to webapps/)
cp target/myapp.war /opt/tomcat/webapps/

# Tomcat auto-deploye'b (extract WAR → /opt/tomcat/webapps/myapp/)
# Rakendus kättesaadav: http://localhost:8080/myapp

# Restart Tomcat
/opt/tomcat/bin/shutdown.sh
/opt/tomcat/bin/startup.sh
# DOWNTIME: 30-60 sekundit!
```

**Multiple applications samal Tomcat serveril:**

```
/opt/tomcat/webapps/
├── app1.war → http://localhost:8080/app1
├── app2.war → http://localhost:8080/app2
├── app3.war → http://localhost:8080/app3
└── ROOT/    → http://localhost:8080/      (default app)
```

**Kõik rakendused jagavad:**
- Sama Tomcat server protsessi
- Sama JVM (heap, thread pool)
- Sama port (8080)

#### Probleemid Traditsionaalse Lähenemisega

1. **Port konfliktid:**
   - Tomcat jookseb port 8080 peal
   - Ei saa käivitada mitut Tomcat'i samal masinal (ilma port reconfiguration'ita)

2. **Resource jagamine (Shared JVM):**
   - Kui app1 consumes liiga palju heap'i → app2 saab OutOfMemoryError
   - Thread pool on jagatud → üks slow app blokeerib teisi

3. **Deployment downtime:**
   - Tomcat restart võtab 30-60 sekundit
   - Kõik rakendused on down restart'i ajal

4. **Dependency conflicts (JAR hell):**
   - app1 vajab spring-core-5.2.jar
   - app2 vajab spring-core-6.0.jar
   - Sama lib ei saa olla kahes erinevas versioonis WEB-INF/lib/ (conflict!)

5. **Vertikaalne skaleerimine:**
   - Rohkem load'i → suurem server (bigger CPU, more RAM)
   - Ei saa skaleerida rakendusi independently

6. **Sõltuvus operatsioonisüsteemi paketihaldusest:**
   - Tomcat install on manual (download, extract, configure)
   - Erinevad keskkonnad (dev, staging, prod) võivad olla erinevad

7. **Monitorimise raskus:**
   - Mitmed rakendused sama JVM'is → raske eristada metrics'eid
   - Kumb rakendus tarbis 80% CPU? Kumb leak'is memory?

### 2. Modern Java Deployment - Spring Boot Embedded Server

Spring Boot tõi paradigma muutuse: **"embedded server"** - veebiserver on **JAR faili sees**, mitte eraldi protsess.

#### Spring Boot Philosophy

**Convention over Configuration:**
- Auto-configuration (ei vaja XML config'e)
- Embedded server (ei vaja Tomcat install'i)
- "Just run" approach: `java -jar app.jar`

**Standalone Executable:**
```bash
# Traditional (Tomcat):
# 1. Install Tomcat
# 2. Configure server.xml
# 3. Build WAR
# 4. Deploy WAR
# 5. Restart Tomcat

# Spring Boot:
java -jar myapp.jar
# DONE! App töötab.
```

#### Embedded Server Choices

Spring Boot toetab 3 embedded serverit:

| Server | Default | Kui kasutada |
|--------|---------|-------------|
| **Tomcat** | ✅ Jah | General purpose (soovitatav) |
| **Jetty** | ❌ | Lightweight, WebSocket focus |
| **Undertow** | ❌ | High performance, non-blocking I/O |

**pom.xml (Maven) - Embedded Tomcat:**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <!-- Sisaldab spring-boot-starter-tomcat (embedded Tomcat) -->
</dependency>
```

**build.gradle (Gradle) - Embedded Tomcat:**
```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    // Sisaldab embedded Tomcat'i
}
```

**Change to Jetty:**
```groovy
dependencies {
    implementation('org.springframework.boot:spring-boot-starter-web') {
        exclude group: 'org.springframework.boot', module: 'spring-boot-starter-tomcat'
    }
    implementation 'org.springframework.boot:spring-boot-starter-jetty'
}
```

#### Executable JAR (Fat JAR) Struktuur

Spring Boot loob **Fat JAR** (Uber JAR) - kõik dependencies pakitud ühte JAR'i:

```bash
# Build JAR
./gradlew bootJar
# Tulemus: build/libs/myapp-1.0.0.jar (50MB)

# JAR sisu (unzip)
myapp-1.0.0.jar
├── BOOT-INF/
│   ├── classes/                    ← Sinu rakenduse kood
│   │   └── com/myapp/
│   │       ├── Application.class
│   │       └── controllers/
│   ├── lib/                        ← KÕIK dependency JAR'id
│   │   ├── spring-boot-3.2.0.jar
│   │   ├── spring-web-6.1.0.jar
│   │   ├── tomcat-embed-core-10.1.15.jar  ← Embedded Tomcat!
│   │   ├── hibernate-core-6.4.0.jar
│   │   └── postgresql-42.6.0.jar
│   └── classpath.idx               ← Classpath index
├── META-INF/
│   ├── MANIFEST.MF                 ← Main-Class: JarLauncher
│   └── maven/                      ← POM metadata
└── org/springframework/boot/loader/  ← Spring Boot Launcher
    └── JarLauncher.class
```

**Käivitamine:**
```bash
java -jar myapp-1.0.0.jar

# Spring Boot Launcher:
# 1. Load'ib BOOT-INF/classes/
# 2. Load'ib BOOT-INF/lib/*.jar
# 3. Käivitab com.myapp.Application.main()
# 4. Embedded Tomcat starts @ port 8080
```

#### Spring Boot Configuration (application.properties)

Spring Boot kasutatakse **application.properties** või **application.yml** konfiguratsiooniks (mitte server.xml).

**src/main/resources/application.properties:**
```properties
# Server config
server.port=8081
server.servlet.context-path=/api

# Database
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=user
spring.datasource.password=password

# JPA/Hibernate
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# Logging
logging.level.com.myapp=DEBUG
logging.level.org.springframework=INFO

# Actuator (health checks, metrics)
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always
```

**Environment-specific configs:**
```
src/main/resources/
├── application.properties          ← Default
├── application-dev.properties      ← Development
├── application-staging.properties  ← Staging
└── application-prod.properties     ← Production
```

```bash
# Käivita development profile'iga
java -jar myapp.jar --spring.profiles.active=dev

# Käivita production profile'iga
java -jar myapp.jar --spring.profiles.active=prod

# Override properties runtime'il
java -jar myapp.jar --server.port=9000 --spring.datasource.url=jdbc:postgresql://prod-db:5432/mydb
```

#### Spring Boot Actuator (Production-Ready Features)

Spring Boot Actuator pakub built-in **health checks** ja **metrics** endpoint'e:

```groovy
// build.gradle
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
}
```

**Endpoints:**
```bash
# Health check
curl http://localhost:8080/actuator/health
# {"status":"UP","groups":["liveness","readiness"]}

# Metrics
curl http://localhost:8080/actuator/metrics
# {"names":["jvm.memory.used","jvm.threads.live","http.server.requests",...]}

# Info
curl http://localhost:8080/actuator/info
# {"app":{"name":"myapp","version":"1.0.0"}}
```

**Kubernetes integration:**
- `/actuator/health/liveness` → Kubernetes liveness probe
- `/actuator/health/readiness` → Kubernetes readiness probe

### 3. Põhjalik Võrdlus: Tomcat WAR vs Spring Boot Container

#### Deployment Workflow Võrdlus

**Traditsiooniline (Tomcat WAR):**

```
┌─────────────────────────────────────────────────────────────┐
│ DEVELOPMENT                                                 │
├─────────────────────────────────────────────────────────────┤
│ 1. Kirjuta kood                                             │
│ 2. mvn clean package → myapp.war                            │
│ 3. Test lokaalselt (deploy Tomcat'i webapps/)               │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ PRODUCTION SERVER                                           │
├─────────────────────────────────────────────────────────────┤
│ 1. Install Tomcat (manual download, extract, configure)     │
│ 2. Configure server.xml (ports, thread pool, JDBC pools)    │
│ 3. Set up JAVA_HOME, CATALINA_HOME                          │
│ 4. Copy myapp.war → /opt/tomcat/webapps/                    │
│ 5. Restart Tomcat (/opt/tomcat/bin/shutdown.sh + startup.sh)│
│    └─> DOWNTIME: 30-60 sekundit                             │
│ 6. Monitor logs: /opt/tomcat/logs/catalina.out              │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ RUNNING STATE                                               │
├─────────────────────────────────────────────────────────────┤
│ • Multiple apps same Tomcat: app1, app2, app3               │
│ • Shared JVM (heap, thread pool)                            │
│ • Port 8080 (fixed, shared)                                 │
│ • Manual scaling (bigger server = vertical scaling)         │
└─────────────────────────────────────────────────────────────┘
```

**Modern (Spring Boot Konteiner):**

```
┌─────────────────────────────────────────────────────────────┐
│ DEVELOPMENT                                                 │
├─────────────────────────────────────────────────────────────┤
│ 1. Kirjuta kood                                             │
│ 2. ./gradlew bootJar → myapp.jar                            │
│ 3. Test lokaalselt: java -jar myapp.jar                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ DOCKERIZE                                                   │
├─────────────────────────────────────────────────────────────┤
│ 1. Kirjuta Dockerfile (multi-stage build)                   │
│ 2. docker build -t myapp:1.0 .                              │
│ 3. docker push myapp:1.0 (registry'sse)                     │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ PRODUCTION (Kubernetes/Docker)                              │
├─────────────────────────────────────────────────────────────┤
│ 1. docker run -d -p 8080:8080 myapp:1.0                     │
│    või                                                      │
│    kubectl apply -f deployment.yaml                          │
│                                                             │
│ ZERO-DOWNTIME DEPLOYMENT:                                   │
│ • Rolling update (Kubernetes)                               │
│ • Blue-Green deployment                                     │
│ • Canary deployment                                         │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│ RUNNING STATE                                               │
├─────────────────────────────────────────────────────────────┤
│ • Each app = own container (isolated)                       │
│ • Own JVM (dedicated heap, threads)                         │
│ • Own port (port mapping: 8080:8080, 8081:8080, etc.)       │
│ • Horizontal scaling (10, 100, 1000 containers)             │
└─────────────────────────────────────────────────────────────┘
```

#### Võrdlustabel: Tomcat WAR vs Spring Boot JAR Konteineris

| Aspekt | Tomcat WAR | Spring Boot JAR (Konteiner) |
|--------|-----------|----------------------------|
| **Pakendus** | WAR (30-50MB) | Executable JAR (50MB) + Docker image (250MB) |
| **Server install** | Manual Tomcat install & config | Embedded Tomcat (JAR'is) |
| **Deployment** | Copy WAR → webapps/ | `docker run` või `kubectl apply` |
| **Downtime** | 30-60s (Tomcat restart) | 0s (rolling update, blue-green) |
| **Isolatsioon** | ❌ Shared JVM (kõik apps koos) | ✅ Oma JVM per konteiner |
| **Port konfliktid** | ✅ Jah (kõik apps port 8080) | ❌ Ei (port mapping) |
| **Memory leak** | ☠️ Leak app1'is → kõik apps crashivad | ✅ Leak app1'is → ainult app1 crashib |
| **Skaleeritavus** | Vertical (bigger server) | Horizontal (more containers) |
| **Resource limits** | ❌ Raske (shared JVM) | ✅ Lihtne (Kubernetes resource limits) |
| **Monitoring** | ⚠️ Raske (metrics mixed) | ✅ Lihtne (per-container metrics) |
| **Configuration** | server.xml, context.xml | application.properties, env vars |
| **Multi-environment** | Manual config changes | Docker image + env vars (immutable) |
| **Rollback** | ⚠️ Manual (restore old WAR) | ✅ Lihtne (`kubectl rollout undo`) |
| **Dependency isolation** | ❌ JAR hell (shared WEB-INF/lib) | ✅ Isolated (Fat JAR per konteiner) |
| **Cloud-native** | ❌ Pole (manual server mgmt) | ✅ Jah (containers, orchestration) |
| **CI/CD integration** | ⚠️ Raske (Tomcat deploy scripts) | ✅ Lihtne (docker build/push, automated) |

#### Resource Usage Võrdlus

**Traditsiooniline Tomcat (3 rakendust):**

```
┌────────────────────────────────────────────────────┐
│  VPS Server (8GB RAM, 4 CPUs)                      │
│                                                    │
│  ┌──────────────────────────────────────────────┐ │
│  │  Tomcat JVM (6GB heap)                       │ │
│  │                                              │ │
│  │  ┌────────────┬────────────┬────────────┐   │ │
│  │  │  app1.war  │  app2.war  │  app3.war  │   │ │
│  │  │  2GB used  │  1GB used  │  3GB used  │   │ │
│  │  └────────────┴────────────┴────────────┘   │ │
│  │                                              │ │
│  │  Shared thread pool: 200 threads             │ │
│  │  Port: 8080 (all apps)                       │ │
│  └──────────────────────────────────────────────┘ │
│                                                    │
│  Probleem: app3 leak'ib memory → kõik crashivad   │
└────────────────────────────────────────────────────┘
```

**Spring Boot Konteinerid (Kubernetes):**

```
┌────────────────────────────────────────────────────┐
│  Kubernetes Cluster (8GB RAM, 4 CPUs)              │
│                                                    │
│  ┌───────────────┬───────────────┬──────────────┐ │
│  │ app1 pod      │ app2 pod      │ app3 pod     │ │
│  │               │               │              │ │
│  │ JVM (2GB heap)│ JVM (1GB heap)│ JVM (3GB heap)││
│  │ 50 threads    │ 50 threads    │ 100 threads  │ │
│  │ Port: 8080    │ Port: 8080    │ Port: 8080   │ │
│  │ (ClusterIP)   │ (ClusterIP)   │ (ClusterIP)  │ │
│  │               │               │              │ │
│  │ Limits:       │ Limits:       │ Limits:      │ │
│  │ • CPU: 1 core │ • CPU: 0.5    │ • CPU: 2     │ │
│  │ • RAM: 2GB    │ • RAM: 1GB    │ • RAM: 3GB   │ │
│  └───────────────┴───────────────┴──────────────┘ │
│                                                    │
│  Eelised:                                          │
│  • app3 memory leak → ainult app3 crashib ja      │
│    restart'itakse (app1, app2 töötavad edasi)     │
│  • Independent scaling (app2: 1 replica,           │
│    app1: 10 replicas)                             │
│  • Per-app monitoring (CPU, RAM, requests)        │
└────────────────────────────────────────────────────┘
```

### 4. Java Rakenduste Konteineriseerimise Spetsiifika

#### Build Tools: Maven vs Gradle

**Maven (pom.xml):**
```xml
<project>
    <groupId>com.mycompany</groupId>
    <artifactId>myapp</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>3.2.0</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

```dockerfile
# Maven multi-stage build
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline  # Download dependencies (cacheable layer)
COPY src ./src
RUN mvn package -DskipTests    # Build JAR

FROM eclipse-temurin:17-jre-alpine
COPY --from=builder /app/target/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

**Gradle (build.gradle):**
```groovy
plugins {
    id 'org.springframework.boot' version '3.2.0'
    id 'java'
}

group = 'com.mycompany'
version = '1.0.0'

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
}
```

```dockerfile
# Gradle multi-stage build
FROM gradle:8-jdk17-alpine AS builder
WORKDIR /app
COPY build.gradle settings.gradle ./
RUN gradle dependencies --no-daemon  # Download dependencies (cacheable)
COPY src ./src
RUN gradle bootJar --no-daemon       # Build JAR

FROM eclipse-temurin:17-jre-alpine
COPY --from=builder /app/build/libs/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

**Maven vs Gradle võrdlus:**

| Aspekt | Maven | Gradle |
|--------|-------|--------|
| **Config formaat** | XML (pom.xml) | Groovy DSL (build.gradle) |
| **Build speed** | Slower | Faster (incremental builds, caching) |
| **Learning curve** | Easier (simple, verbose) | Harder (powerful, flexible) |
| **Dependency management** | ✅ Hea | ✅ Parem (dynamic versions, constraints) |
| **Spring Boot default** | ✅ Jah (traditionaalselt) | ✅ Jah (kasvav populaarsus) |
| **Multi-module projects** | ✅ OK | ✅ Parem (flexible, performant) |

#### JDK vs JRE Image'id Multi-Stage Build'is

**JDK (Java Development Kit):**
- Sisaldab kompileerimise tools (javac, jar, javap)
- Sisaldab JRE't
- Suur size (~600-800MB)
- Kasutamine: **BUILD stage**

**JRE (Java Runtime Environment):**
- Sisaldab AINULT runtime'i (java executable)
- Väike size (~150-250MB)
- Kasutamine: **RUNTIME stage**

**Multi-stage build (JDK → JRE):**

```dockerfile
# ========== BUILD STAGE (JDK) ==========
FROM eclipse-temurin:17-jdk-alpine AS builder
# Image size: ~600MB (sisaldab javac, gradle, maven)

WORKDIR /app
COPY build.gradle settings.gradle ./
COPY src ./src

# Build executable JAR
RUN ./gradlew bootJar --no-daemon
# Tulemus: /app/build/libs/myapp.jar

# ========== RUNTIME STAGE (JRE) ==========
FROM eclipse-temurin:17-jre-alpine
# Image size: ~250MB (ainult java runtime, pole javac)

WORKDIR /app

# Kopeeri JAR builder stage'ist
COPY --from=builder /app/build/libs/*.jar app.jar

# Non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# JVM tuning (näited allpool)
ENV JAVA_OPTS="-Xmx512m -Xms256m"

EXPOSE 8080

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# Final image size: ~250MB (vs ~600MB ilma multi-stage'ita)
```

**Image size võrdlus:**

| Approach | Base Image | Final Size |
|----------|-----------|------------|
| Single-stage (JDK) | eclipse-temurin:17-jdk | ~650MB |
| Multi-stage (JRE) | eclipse-temurin:17-jre | ~270MB |
| Multi-stage (JRE Alpine) | eclipse-temurin:17-jre-alpine | ~250MB |
| Distroless | gcr.io/distroless/java17 | ~220MB |

#### JVM Tuning Konteinerikeskkonnas

**Probleem:** Vana JVM (Java 8 enne update 191) ei "näinud" konteineri memory limit'e ja võttis 25% host RAM'ist (mis võis olla 64GB), mitte konteineri limit'ist (nt 512MB).

**Lahendus:** Java 10+ on **container-aware** (see on default).

##### Container-Aware JVM (Java 10+)

```bash
# Java 10+ automaatselt detekteerib konteineri limits

# Kubernetes pod limit: 1GB RAM
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: myapp
    image: myapp:1.0
    resources:
      limits:
        memory: "1Gi"
      requests:
        memory: "512Mi"

# JVM näeb 1GB (mitte host'i 64GB!)
# Default max heap: ~25% konteineri memory = 250MB
```

**Vaata JVM settings konteineris:**
```bash
docker run --rm -m 1g eclipse-temurin:17-jre-alpine java -XX:+PrintFlagsFinal -version | grep -i maxheap
# MaxHeapSize = 268435456 (256MB, umbes 25% 1GB'st)
```

##### Heap Size Tuning

**Heap parameetrid:**
- `-Xms`: Initial heap size
- `-Xmx`: Maximum heap size
- `-XX:MaxRAM`: Max RAM JVM sees (automaatne container'is)

**Best practice:**
```dockerfile
# Option 1: Set explicit heap size
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Option 2: Percentage of container memory
ENV JAVA_OPTS="-XX:InitialRAMPercentage=50.0 -XX:MaxRAMPercentage=75.0"

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

**Kubernetes deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:1.0
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        env:
        - name: JAVA_OPTS
          value: "-Xmx768m -Xms512m -XX:+UseG1GC"
```

**Reegel:** Heap size peaks olema **60-80% konteineri memory limit'ist** (jäta ruumi non-heap memory jaoks: metaspace, threads, direct buffers).

**Näide:**
- Container limit: 1GB
- Heap: 700-800MB (-Xmx800m)
- Non-heap: 200-300MB (metaspace, threads, code cache)

##### Garbage Collector (GC) Tuning

**Java GC variandid:**

| GC | Kui kasutada |
|----|------------|
| **G1GC** | Default (Java 9+), hea general purpose, low latency |
| **Serial GC** | Väikesed app'd (<100MB heap), single-core containers |
| **Parallel GC** | Throughput-focused, multi-core, batch processing |
| **ZGC / Shenandoah** | Ultra-low latency (<10ms pauses), large heaps (>8GB) |

**Recommendatsioon container'ites:**

```dockerfile
# Default (G1GC) - hea enamikule
CMD ["java", "-jar", "app.jar"]

# Explicit G1GC + tuning
CMD ["java", "-XX:+UseG1GC", "-XX:MaxGCPauseMillis=200", "-jar", "app.jar"]

# Väike konteiner (<256MB heap) - Serial GC
CMD ["java", "-XX:+UseSerialGC", "-Xmx256m", "-jar", "app.jar"]

# Large heap, low latency - ZGC (Java 15+)
CMD ["java", "-XX:+UseZGC", "-Xmx4g", "-jar", "app.jar"]
```

##### Full JVM Tuning Näide

```dockerfile
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar

# Non-root user
RUN addgroup -S spring && adduser -S spring -G spring && \
    chown spring:spring app.jar
USER spring:spring

EXPOSE 8080

# JVM tuning environment variables
ENV JAVA_OPTS="\
    -Xmx768m \
    -Xms512m \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    -XX:ParallelGCThreads=2 \
    -XX:ConcGCThreads=1 \
    -XX:InitiatingHeapOccupancyPercent=45 \
    -Djava.security.egd=file:/dev/./urandom \
    -Dserver.port=8080"

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

**Selgitus:**
- `-Xmx768m -Xms512m`: Heap 512MB start, max 768MB
- `-XX:+UseG1GC`: G1 garbage collector (low latency)
- `-XX:MaxGCPauseMillis=200`: Target max GC pause 200ms
- `-XX:ParallelGCThreads=2`: 2 GC threads (match container CPUs)
- `-Djava.security.egd=file:/dev/./urandom`: Kiire random number generation (avoid /dev/random blocking)

### 5. Node.js Rakenduste Konteineriseerimise Põhitõed

Node.js konteineriseerimise on lihtsam kui Java (vähem tuning'ut), kuid siiski on best practices.

#### npm vs yarn vs pnpm

| Package Manager | Speed | Disk Usage | Lockfile | Best For |
|----------------|-------|-----------|----------|----------|
| **npm** | OK | OK | package-lock.json | Default, simple projects |
| **yarn** | Faster | OK | yarn.lock | Monorepos, workspaces |
| **pnpm** | Fastest | Best (symlinks) | pnpm-lock.yaml | Large projects, disk savings |

**npm best practices:**
```dockerfile
# Kasuta npm ci (clean install), MITTE npm install
RUN npm ci --only=production

# npm ci eelised:
# • Faster (skip version resolution)
# • Uses package-lock.json (predictable)
# • Deletes node_modules enne install'i (clean state)
```

#### Node.js Multi-Stage Build (Optimized)

```dockerfile
# ========== BUILD STAGE ==========
FROM node:18-alpine AS builder

WORKDIR /app

# Install ALL dependencies (incl. devDependencies)
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build  # TypeScript compile, webpack bundle, etc.
# Tulemus: dist/ või build/ kataloog

# ========== PRODUCTION STAGE ==========
FROM node:18-alpine

WORKDIR /app

# Install ONLY production dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy built artifacts from builder
COPY --from=builder /app/dist ./dist

# Non-root user (node user exists in official image)
USER node

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "dist/server.js"]
```

**Image size võrdlus (Express.js app):**

| Approach | Base Image | Dependencies | Final Size |
|----------|-----------|--------------|-----------|
| Single-stage (all deps) | node:18 | Dev + Prod | 1.2GB |
| Single-stage (prod deps) | node:18-alpine | Prod only | 350MB |
| Multi-stage | node:18-alpine | Prod only + built artifacts | 180MB |

#### .dockerignore for Node.js

```
# Dependencies (re-install image'is)
node_modules/
npm-debug.log
yarn-error.log

# Build artifacts
build/
dist/
*.tsbuildinfo

# Tests
tests/
__tests__/
*.test.js
*.spec.js
coverage/

# Documentation
README.md
docs/

# Git
.git/
.gitignore

# Environment files (SECRETS!)
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp

# OS files
.DS_Store
Thumbs.db
```

## Praktilised Näited

### Näide 1: Spring Boot Gradle Multi-Stage Dockerfile (Optimized)

```dockerfile
# ========== BUILD STAGE ==========
FROM gradle:8.5-jdk17-alpine AS builder

WORKDIR /app

# Copy Gradle wrapper and dependencies config (caching layer)
COPY build.gradle settings.gradle gradlew ./
COPY gradle ./gradle

# Download dependencies (this layer is cached if build.gradle unchanged)
RUN gradle dependencies --no-daemon

# Copy source code
COPY src ./src

# Build executable JAR
RUN gradle bootJar --no-daemon

# ========== RUNTIME STAGE ==========
FROM eclipse-temurin:17-jre-alpine

# Add non-root user
RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

# Copy JAR from builder stage
COPY --from=builder /app/build/libs/*.jar app.jar

# Fix permissions
RUN chown spring:spring app.jar

USER spring:spring

EXPOSE 8080

# JVM tuning for containers
ENV JAVA_OPTS="\
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:InitialRAMPercentage=50.0 \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    -Djava.security.egd=file:/dev/./urandom"

# Health check (Spring Boot Actuator)
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health/liveness || exit 1

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

**Build ja run:**
```bash
# Build image
docker build -t todo-service:1.0 .

# Run with resource limits
docker run -d \
  --name todo-service \
  -p 8081:8080 \
  -m 1g \
  --cpus=1.0 \
  -e SPRING_PROFILES_ACTIVE=production \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/todos \
  -e SPRING_DATASOURCE_USERNAME=postgres \
  -e SPRING_DATASOURCE_PASSWORD=secret \
  todo-service:1.0

# Check health
curl http://localhost:8081/actuator/health
# {"status":"UP"}

# Check JVM settings inside container
docker exec todo-service java -XX:+PrintFlagsFinal -version | grep -i maxheap
```

### Näide 2: Spring Boot Maven Dockerfile

```dockerfile
# ========== BUILD STAGE ==========
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copy POM and download dependencies (cacheable layer)
COPY pom.xml ./
RUN mvn dependency:go-offline -B

# Copy source and build
COPY src ./src
RUN mvn package -DskipTests -B

# ========== RUNTIME STAGE ==========
FROM eclipse-temurin:17-jre-alpine

RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

RUN chown spring:spring app.jar

USER spring:spring

EXPOSE 8080

ENV JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseG1GC"

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

### Näide 3: Node.js Express Multi-Stage Dockerfile (TypeScript)

```dockerfile
# ========== BUILD STAGE ==========
FROM node:18-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build TypeScript
COPY tsconfig.json ./
COPY src ./src
RUN npm run build
# Tulemus: dist/ kataloog (compiled JavaScript)

# ========== PRODUCTION STAGE ==========
FROM node:18-alpine

WORKDIR /app

# Install production dependencies only
COPY package.json package-lock.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy built JavaScript from builder
COPY --from=builder /app/dist ./dist

# Non-root user
USER node

EXPOSE 3000

# Environment
ENV NODE_ENV=production \
    PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "dist/server.js"]
```

### Näide 4: Image Size Võrdlus (Praktiline Test)

**Java Spring Boot:**

```bash
# Build erinevate approach'idega

# 1. Single-stage JDK (kõik on image'is)
docker build -f Dockerfile.jdk-single -t myapp:jdk-single .
docker images myapp:jdk-single
# SIZE: 650MB

# 2. Multi-stage JRE
docker build -f Dockerfile.jre-multi -t myapp:jre-multi .
docker images myapp:jre-multi
# SIZE: 270MB

# 3. Multi-stage JRE Alpine
docker build -f Dockerfile.jre-alpine -t myapp:jre-alpine .
docker images myapp:jre-alpine
# SIZE: 250MB

# 4. Distroless
docker build -f Dockerfile.distroless -t myapp:distroless .
docker images myapp:distroless
# SIZE: 220MB

# Võit: 650MB → 220MB (66% vähenemine!)
```

**Node.js Express:**

```bash
# 1. Single-stage (kõik dependencies)
docker build -f Dockerfile.node-single -t myapp:node-single .
docker images myapp:node-single
# SIZE: 1.2GB

# 2. Single-stage Alpine (prod deps)
docker build -f Dockerfile.node-alpine -t myapp:node-alpine .
docker images myapp:node-alpine
# SIZE: 350MB

# 3. Multi-stage Alpine
docker build -f Dockerfile.node-multi -t myapp:node-multi .
docker images myapp:node-multi
# SIZE: 180MB

# Võit: 1.2GB → 180MB (85% vähenemine!)
```

## Levinud Probleemid ja Lahendused

### Probleem 1: OutOfMemoryError konteineris (Java)

**Sümptom:**
```
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
```

**Põhjus:** JVM heap on suurem kui konteineri memory limit.

**Lahendus:**
```yaml
# Kubernetes deployment
resources:
  limits:
    memory: "1Gi"
env:
- name: JAVA_OPTS
  value: "-Xmx768m"  # 75% konteineri memory'st

# REEGEL: Heap <= 75-80% container memory
```

### Probleem 2: Slow Gradle/Maven build konteineris

**Põhjus:** Iga build download'ib dependencies uuesti.

**Lahendus:** Kopeeri dependency config ENNE source code'i (layer caching):
```dockerfile
# GOOD: Dependencies cached
COPY build.gradle settings.gradle ./
RUN gradle dependencies --no-daemon  # Cached if build.gradle unchanged
COPY src ./src
RUN gradle bootJar

# BAD: Re-downloads dependencies every time
COPY . .
RUN gradle bootJar
```

### Probleem 3: Native modules fail (Node.js Alpine)

**Sümptom:**
```
Error: /app/node_modules/bcrypt/lib/binding/bcrypt_lib.node: Error loading shared library
```

**Põhjus:** Native modules compiled for glibc, aga Alpine kasutab musl libc.

**Lahendus 1:** Rebuild native modules Alpine'is:
```dockerfile
FROM node:18-alpine
RUN apk add --no-cache python3 make g++
RUN npm rebuild bcrypt --build-from-source
```

**Lahendus 2:** Kasuta Debian slim (native modules work out-of-box):
```dockerfile
FROM node:18-slim
# npm install töötab ilma rebuild'ita
```

## Best Practices

### Java/Spring Boot:

- ✅ **Multi-stage builds:** Build stage (Gradle + JDK) → Runtime stage (JRE)
- ✅ **JRE runtime image:** eclipse-temurin:17-jre-alpine (mitte JDK)
- ✅ **Container-aware JVM:** Java 10+ (automaatne)
- ✅ **Heap tuning:** `-XX:MaxRAMPercentage=75.0` (75% konteineri memory'st)
- ✅ **G1GC:** `-XX:+UseG1GC` (low latency, general purpose)
- ✅ **Non-root user:** spring user (või loo custom user)
- ✅ **Health checks:** Spring Boot Actuator `/actuator/health`
- ✅ **Dependency caching:** COPY build.gradle ENNE src/
- ✅ **Small base image:** Alpine või Distroless

### Node.js:

- ✅ **Multi-stage builds:** Build stage (compile TypeScript, webpack) → Runtime stage (production deps only)
- ✅ **npm ci:** Mitte npm install (faster, predictable)
- ✅ **--only=production:** Ära install dev dependencies production image'isse
- ✅ **npm cache clean:** Puhasta cache peale install'i
- ✅ **node user:** Non-root (exists in official image)
- ✅ **NODE_ENV=production:** Production optimizations
- ✅ **Alpine base:** node:18-alpine (smaller)
- ✅ **.dockerignore:** node_modules, .env, tests

## Corporate Võrgu Piirangud: Proxy Seadistamine Docker Build'is

### Probleem: Tulemüür Blokeerib Internetiühenduse

Corporate võrkudes (ettevõtte sisevõrgud) on tavaline, et:
- ✅ Docker build protsess vajab sõltuvusi internetist (npm packages, Maven/Gradle dependencies, base images)
- ❌ Firewall/proxy server blokeerib otsese ühenduse välismaailma
- ✅ Proxy server (nt `cache1.sss:3128`) võimaldab kontrollitud juurdepääsu

**Küsimus:** Kuidas saada Gradle või npm käsud build time'is läbi proxy serveri?

**Vastus:** On **8 erinevat meetodit**, millest igaühel on oma trade-off'id.

### Lahendused: 8 Meetodit Proxy Seadistamiseks

#### Tabel: Meetodite Võrdlus

| Meetod | Portability | Security | CI/CD | Beginner | Production | Soovitus |
|--------|:-----------:|:--------:|:-----:|:--------:|:----------:|----------|
| **ARG Multi-Stage** | ✅ Parim | ✅ Clean runtime | ✅ Lihtne | ⚠️ Keskmine | ✅ Jah | **KASUTA** |
| **ARG Single-Stage** | ✅ Hea | ⚠️ Runtime leak | ✅ Lihtne | ✅ Lihtne | ⚠️ Tinglik | Õpetamiseks |
| **Hardcoded ENV** | ❌ Ei | ❌ Leak + fixed | ❌ Ei | ❌ Segane | ❌ Ei | **VÄLDI** |
| **daemon.json** | ⚠️ Piiratud | ✅ Clean image | ⚠️ Keeruline | ❌ Admin | ⚠️ Infrastruktuur | Fallback |
| **config.json** | ⚠️ Per-user | ✅ Clean image | ⚠️ Keeruline | ❌ Manuaalne | ⚠️ Piiratud | Harv |
| **BuildKit Secrets** | ✅ Suurepärane | ✅✅ Parim | ✅ Advanced | ❌ Keeruline | ✅ Modern | Tulevik |
| **--network host** | ❌ Ei | ❌ Ohtlik | ❌ Ei | ❌ Risk | ❌ Ei | **MITTE KUNAGI** |
| **ENV Instruction** | ❌ Ei | ❌ Leak | ❌ Ei | ❌ Segane | ❌ Ei | **VÄLDI** |

#### Meetod 1: ARG Multi-Stage Build (SOOVITATUD) ⭐

**Põhimõte:** `ARG` võimaldab anda proxy build-time'is (Dockerfile build käsu ajal), aga see **EI LEKI runtime'i** (runtime container on puhas).

**Dockerfile näide (Gradle + Java):**

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

**Build proksiga (corporate võrk):**
```bash
# Asenda oma proxy aadress!
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  -t todo-service:1.0 .
```

**Build ilma proksita (avalik võrk):**
```bash
docker build -t todo-service:1.0 .
# Gradle download töötab avalikus võrgus
```

**Kontrolli: Kas proxy leak'ib runtime'i?**
```bash
docker run --rm todo-service:1.0 env | grep -i proxy
# Oodatud: TÜHI väljund! ✅ Proxy EI OLE runtime'is
```

**Eelised:**
- ✅ **Portaabel:** Töötab kõikjal (developer, CI/CD, production, avalik võrk)
- ✅ **Turvaline:** Proxy ei leki runtime'i (multi-stage isolatsioon)
- ✅ **CI/CD friendly:** `--build-arg` lihtne lisada GitHub Actions, GitLab CI
- ✅ **Töötab ilma proksita:** Sama Dockerfile avalikus võrgus

**Gradle vs npm erinevus:**

| Tool | Proxy Handling |
|------|---------------|
| **npm (Node.js)** | Kasutab otse `HTTP_PROXY` environment variable → lihtne |
| **Gradle (Java)** | Vajab `GRADLE_OPTS` parserimist → parsing script vajalik |

**npm näide (lihtsam):**
```dockerfile
FROM node:18-alpine AS builder
ARG HTTP_PROXY
ARG HTTPS_PROXY

# npm kasutab HTTP_PROXY automaatselt
RUN npm ci
```

**Gradle näide (vajab parserimist):**
```dockerfile
FROM gradle:8-jdk17-alpine AS builder
ARG HTTP_PROXY

# Parse proxy URL → GRADLE_OPTS
RUN if [ -n "$HTTP_PROXY" ]; then \
      PROXY_HOST=$(echo "$HTTP_PROXY" | sed 's|^.*://||; s|:.*$||'); \
      PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
      export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT"; \
      gradle dependencies --no-daemon; \
    fi
```

**Miks Gradle vajab parserimist?**
- npm: `HTTP_PROXY=http://cache1.sss:3128` → töötab
- Gradle: Vajab `-Dhttp.proxyHost=cache1.sss -Dhttp.proxyPort=3128` formaati

#### Meetod 2: ARG Single-Stage Build (Õpetamiseks)

Sama ARG lähenemine, aga ilma multi-stage'ita.

**Probleem:** Proxy `ARG` võib konverteerida `ENV`'iks → leak'ib runtime'i.

**Kasutamine:** Sobib õppimiseks Lab 1 (beginnerid), aga mitte production'i.

#### Meetod 3: Hardcoded ENV (ANTI-PATTERN)

**Dockerfile:**
```dockerfile
FROM gradle:8-jdk17-alpine
ENV HTTP_PROXY=http://cache1.sss:3128  # Hardcoded!
ENV HTTPS_PROXY=http://cache1.sss:3128

# ... build steps
```

**Probleemid:**
- ❌ Töötab AINULT corporate võrgus (developer või avalikus võrgus ei tööta)
- ❌ Proxy leak'ib runtime'i (security risk)
- ❌ Mitte portable (CI/CD erinev, production erinev)

**Millal näed seda:**
- Legacy codebases (technical debt)
- "Quick and dirty" lahendused, mis unustati refactor'ida

**Refactoring:** Asenda Meetod 1'ga (ARG multi-stage).

#### Meetod 4: Docker Daemon Configuration (`/etc/docker/daemon.json`)

**Kui kasutada:** Dockerfiles'e ei saa muuta (3rd-party images, read-only repos).

**Setup:**
```bash
# /etc/docker/daemon.json
sudo vi /etc/docker/daemon.json
```

```json
{
  "proxies": {
    "http-proxy": "http://cache1.sss:3128",
    "https-proxy": "http://cache1.sss:3128",
    "no-proxy": "localhost,127.0.0.1,10.0.0.0/8"
  }
}
```

**Restart Docker daemon:**
```bash
sudo systemctl restart docker
# HOIATUS: Kõik töötavad konteinerid peatuvad!
```

**Eelised:**
- ✅ Ühekordselt setup (kõik build'id kasutavad)
- ✅ Pole Dockerfile muudatusi vaja

**Puudused:**
- ❌ Vajab sudo/admin access (developer'id ei saa muuta)
- ❌ Mõjutab KÕIKI projekte masinas (global setting)
- ❌ Pole portable (iga masin vajab manuaalset setup'i)
- ❌ CI/CD keeruline (Docker daemon config build container'is)

**Soovitus:** Fallback, kui Dockerfile muutmine pole võimalik.

#### Meetod 5: Docker CLI Config (`~/.docker/config.json`)

Sarnane `daemon.json`'ile, aga per-user level.

**Põhjus mitte kasutada:** Modern Docker prefereerib `daemon.json`. Haruldane use case.

#### Meetod 6: BuildKit Secrets (Modern/Future)

**Docker BuildKit:** Next-gen build engine (experimental → stable Docker 23.0+).

**Põhimõte:** Secrets mount'itakse build time'is, aga **EI SALVESTU layer'itesse**.

**Lühike preview:**
```bash
docker build \
  --secret id=http_proxy,env=HTTP_PROXY \
  --secret id=https_proxy,env=HTTPS_PROXY \
  -t myapp .
```

```dockerfile
RUN --mount=type=secret,id=http_proxy \
    export HTTP_PROXY=$(cat /run/secrets/http_proxy) && \
    npm install
```

**Eelised:**
- ✅ Secrets **KUNAGI** ei leak'i image layer'itesse
- ✅ Modern, secure approach

**Puudused:**
- ❌ Vajab Docker BuildKit enabled (`DOCKER_BUILDKIT=1`)
- ❌ Nõuab Docker 23.0+ (relatively new)
- ❌ Keeruline beginneritele

**Soovitus:** Future-proof alternative, aga Lab 1 õppijatele liiga keeruline.

**Loe edasi:** [Docker BuildKit Secrets Documentation](https://docs.docker.com/build/building/secrets/)

#### Meetod 7: Network Mode Settings (ANTI-PATTERN)

```bash
docker build --network=host -t myapp .
```

**Miks see on halb:**
- ❌ **Security risk:** Container'il on täielik juurdepääs host network'ile
- ❌ Pole portable (network config võib olla erinev)
- ❌ Mitte production-ready

**Soovitus:** **MITTE KUNAGI** kasutada production'is.

#### Meetod 8: ENV Instruction (Non-ARG)

```dockerfile
ENV HTTP_PROXY=http://cache1.sss:3128
```

**Probleem:** Sama kui hardcoded (Meetod 3) → leak'ib runtime'i, pole flexible.

**Soovitus:** Asenda ARG'iga (Meetod 1).

### Flowchart: Millal Kasutada Millist Meetodit?

```
Kas saad Dockerfile'i muuta?
├─ JAH → Kas oled algaja?
│   ├─ JAH → ARG Single-Stage (Lab 1 õppemeetod)
│   │         └─> Lihtne mõista, aga proxy leak'ib runtime'i
│   │
│   └─ EI → ARG Multi-Stage ⭐ (PRODUCTION)
│             └─> Turvaline, portable, best practice
│
└─ EI → Kas sul on admin access?
    ├─ JAH → daemon.json
    │         └─> Ühekordselt setup, global effect
    │
    └─ EI → config.json (või palun admin'ilt abi)
              └─> Per-user, harv use case
```

### CI/CD Integratsioon

**GitHub Actions, GitLab CI, Jenkins:** Proxy secrets integreeritavad läbi repository secrets.

**Lühike vihje:**
```yaml
# GitHub Actions näide (vihje)
- name: Build Docker image
  run: |
    docker build \
      --build-arg HTTP_PROXY=${{ secrets.PROXY_URL }} \
      --build-arg HTTPS_PROXY=${{ secrets.PROXY_URL }} \
      -t myapp:${{ github.sha }} .
```

**Täpsem käsitlus:** Lab 5 (CI/CD Pipeline) käsitleb täielikku CI/CD workflow'i.

### Troubleshooting: Proxy Probleemide Lahendamine

#### Probleem 1: Build hangub "Downloading dependencies..."

**Sümptom:**
```
Step 5/10 : RUN gradle dependencies --no-daemon
 ---> Running in abc123...
Downloading https://repo.maven.apache.org/...
[hangs indefinitely]
```

**Põhjus:** Proxy pole seadistatud või on vale.

**Lahendus:**
```bash
# 1. Kontrolli proxy environment variable
echo $HTTP_PROXY
# Oodatud: http://cache1.sss:3128

# 2. Test proxy connectivity
curl -x http://cache1.sss:3128 https://repo.maven.apache.org
# Peaks tagastama HTML

# 3. Kontrolli Dockerfile ARG
docker build --build-arg HTTP_PROXY=http://cache1.sss:3128 -t myapp .

# 4. Debug RUN käsu output
RUN echo "GRADLE_OPTS: $GRADLE_OPTS" && gradle dependencies
```

#### Probleem 2: "Connection refused" viga

**Sümptom:**
```
Failed to connect to cache1.sss port 3128: Connection refused
```

**Põhjus:** Proxy host/port parsing on vale VÕI proxy server ei ole kättesaadav.

**Lahendus:**
```bash
# 1. Kontrolli proxy URL format
HTTP_PROXY=http://cache1.sss:3128  # Correct
HTTP_PROXY=cache1.sss:3128          # Incorrect (missing protocol)

# 2. Test proxy host reachability
ping cache1.sss
telnet cache1.sss 3128

# 3. Kontrolli GRADLE_OPTS parsing
docker build --progress=plain -t myapp .
# Näed RUN käskude output'i
```

#### Probleem 3: Proxy leak'ib runtime'i

**Sümptom:**
```bash
docker run --rm myapp env | grep -i proxy
HTTP_PROXY=http://cache1.sss:3128  # ❌ BAD! Runtime proxy leak
```

**Põhjus:** Kasutasid ENV asemel ARG VÕI single-stage build'i.

**Lahendus:**
```dockerfile
# GOOD: ARG multi-stage (ei leki runtime'i)
FROM gradle:8-jdk17 AS builder
ARG HTTP_PROXY  # Build-time only
...

FROM eclipse-temurin:17-jre
# NO HTTP_PROXY here → clean runtime
```

**Test:**
```bash
docker run --rm myapp env | grep -i proxy
# Oodatud: TÜHI väljund ✅
```

### Best Practices

1. ✅ **Kasuta ARG multi-stage** production'is
   - Turvaline (runtime clean)
   - Portable (works kõikjal)
   - CI/CD friendly

2. ✅ **Ära hardcode proxy** Dockerfile'is
   - Kasuta `--build-arg` build time'is
   - Võimalda sama Dockerfile kasutamist avalikus võrgus

3. ✅ **Test runtime clean** (proxy ei leki)
   - `docker run --rm myapp env | grep -i proxy`
   - Oodatud: tühi väljund

4. ✅ **Document CI/CD setup**
   - Repository secrets configuration
   - Build script näited

5. ❌ **Ära kasuta `--network=host`**
   - Security risk
   - Mitte production-ready

---

### Lisastsenaarium: Private Repository Manager (Sonatype Nexus)

**Mis on Nexus Repository Manager?**

Nexus on **corporate artifact repository**, mis:
- Cache'ib avalikud pakid (Maven Central, npmjs.org) → kiire, reliable
- Hostib company internal packages → private sõltuvused
- Pakub security scanning (Nexus IQ), access control (RBAC)
- Asub corporate võrgus (nt `https://nexus.company.com`)

**Erinevus HTTP Proxy vs Nexus:**

| Aspekt | HTTP Proxy (cache1.sss:3128) | Nexus Repository Manager |
|--------|------------------------------|--------------------------|
| **Eesmärk** | Network-level proxy (CONNECT) | Package repository manager |
| **Konfiguratsioon** | `HTTP_PROXY` env var | Build tool settings (settings.xml, .npmrc, build.gradle) |
| **Cache** | Generic HTTP cache | Package-aware artifacts cache |
| **Private packages** | ❌ Ei toeta | ✅ Toetab (hosted repos) |
| **Security scanning** | ❌ Pole | ✅ Nexus IQ integration |
| **Access control** | ⚠️ Basic auth (optional) | ✅ RBAC (required) |

**Oluline:** Nexus **ei ole HTTP proxy** - see on **application-level package repository**.

---

#### Gradle + Nexus

**build.gradle (repositories config):**

```groovy
repositories {
    maven {
        url = uri("https://nexus.company.com/repository/maven-public/")
        credentials {
            username = System.getenv("NEXUS_USERNAME") ?: project.findProperty("nexusUsername")
            password = System.getenv("NEXUS_PASSWORD") ?: project.findProperty("nexusPassword")
        }
    }
}
```

**Dockerfile (multi-stage):**

```dockerfile
FROM gradle:8.11-jdk21-alpine AS builder

ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD

WORKDIR /app

COPY build.gradle settings.gradle ./
RUN gradle dependencies --no-daemon

COPY src ./src
RUN gradle bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine
COPY --from=builder /app/build/libs/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

**Build:**
```bash
docker build \
  --build-arg NEXUS_USERNAME=build-user \
  --build-arg NEXUS_PASSWORD=secret123 \
  -t todo-service:1.0 .
```

**Security check:**
```bash
docker run --rm todo-service:1.0 env | grep NEXUS
# Oodatud: TÜHI ✅ (credentials ei leki runtime'i)
```

---

#### Maven + Nexus

**settings.xml (project root või ~/.m2/settings.xml):**

```xml
<settings>
  <servers>
    <server>
      <id>nexus</id>
      <username>${env.NEXUS_USERNAME}</username>
      <password>${env.NEXUS_PASSWORD}</password>
    </server>
  </servers>

  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>https://nexus.company.com/repository/maven-public/</url>
    </mirror>
  </mirrors>
</settings>
```

**Dockerfile:**

```dockerfile
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD

WORKDIR /app

COPY settings.xml /root/.m2/settings.xml
COPY pom.xml ./
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn package -DskipTests -B

FROM eclipse-temurin:17-jre-alpine
COPY --from=builder /app/target/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

---

#### npm + Nexus

**.npmrc (project root):**

```ini
registry=https://nexus.company.com/repository/npm-public/
always-auth=true
_auth=${NPM_AUTH_TOKEN}
```

**Dockerfile:**

```dockerfile
FROM node:18-alpine AS builder

ARG NPM_AUTH_TOKEN

WORKDIR /app

COPY package.json package-lock.json .npmrc ./
RUN echo "_auth=${NPM_AUTH_TOKEN}" >> .npmrc
RUN npm ci

COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production && npm cache clean --force
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/server.js"]
```

**Build:**
```bash
# Generate token: echo -n "username:password" | base64
docker build \
  --build-arg NPM_AUTH_TOKEN=dXNlcm5hbWU6cGFzc3dvcmQ= \
  -t user-service:1.0 .
```

---

#### Nexus + HTTP Proxy (kombineeritud)

Kui Nexus on HTTP proxy taga (maksimum security setup):

**Dockerfile:**

```dockerfile
FROM gradle:8.11-jdk21-alpine AS builder

ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY=nexus.company.com,*.company.com
ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD

WORKDIR /app

# Seadista proxy (kui Nexus proxy taga)
RUN if [ -n "$HTTP_PROXY" ]; then \
      PROXY_HOST=$(echo "$HTTP_PROXY" | sed 's|^.*://||; s|:.*$||'); \
      PROXY_PORT=$(echo "$HTTP_PROXY" | grep -oE '[0-9]+$'); \
      export GRADLE_OPTS="-Dhttp.proxyHost=$PROXY_HOST -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=$PROXY_HOST -Dhttps.proxyPort=$PROXY_PORT -Dhttp.nonProxyHosts=${NO_PROXY}"; \
    fi

COPY build.gradle settings.gradle ./
RUN gradle dependencies --no-daemon

COPY src ./src
RUN gradle bootJar --no-daemon

FROM eclipse-temurin:21-jre-alpine
COPY --from=builder /app/build/libs/*.jar app.jar
CMD ["java", "-jar", "app.jar"]
```

**Build:**
```bash
docker build \
  --build-arg HTTP_PROXY=http://cache1.sss:3128 \
  --build-arg HTTPS_PROXY=http://cache1.sss:3128 \
  --build-arg NEXUS_USERNAME=build-user \
  --build-arg NEXUS_PASSWORD=secret123 \
  -t todo-service:1.0 .
```

**Märkus:** `NO_PROXY` exception on kritiline - Nexus domain peab olema proxy exclusion'is.

---

#### Credentials Management

**❌ MITTE KUNAGI:**

```dockerfile
ENV NEXUS_USERNAME=admin  # ❌ Leak runtime'i!
ENV NEXUS_PASSWORD=admin123
```

```groovy
// build.gradle
credentials {
    username = "admin"  // ❌ Git history'sse!
    password = "admin123"
}
```

**✅ ÕIGE VIIS:**

```dockerfile
# ARG (build-time only)
ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD
# Runtime stage: NO CREDENTIALS ✅
```

**CI/CD integratsioon:**

```yaml
# GitHub Actions
- name: Build Docker image
  run: |
    docker build \
      --build-arg NEXUS_USERNAME=${{ secrets.NEXUS_USERNAME }} \
      --build-arg NEXUS_PASSWORD=${{ secrets.NEXUS_PASSWORD }} \
      -t myapp:${{ github.sha }} .
```

---

#### Troubleshooting: Nexus Probleemid

**Probleem 1: "Unauthorized" (401)**

```
Received status code 401 from server: Unauthorized
```

**Lahendus:**
```bash
# Test credentials
curl -u username:password https://nexus.company.com/repository/maven-public/

# Debug build
docker build --progress=plain \
  --build-arg NEXUS_USERNAME=test \
  --build-arg NEXUS_PASSWORD=test \
  -t myapp .
```

**Probleem 2: SSL Certificate Error**

```
PKIX path building failed: unable to find valid certification path
```

**Lahendus (DEV ONLY):**
```dockerfile
COPY nexus-cert.pem /usr/local/share/ca-certificates/nexus.crt
RUN update-ca-certificates
```

**Production:** Kasuta proper CA-signed certificate.

**Probleem 3: Proxy blokeerib Nexus'i**

```
Connection refused: https://nexus.company.com
```

**Lahendus:**
```dockerfile
ARG NO_PROXY=nexus.company.com,*.company.com

RUN export http_proxy=$HTTP_PROXY && \
    export https_proxy=$HTTP_PROXY && \
    export no_proxy=$NO_PROXY && \
    gradle dependencies --no-daemon
```

---

#### Best Practices

1. ✅ **ARG credentials** (mitte ENV) - build-time only, ei leki runtime'i
2. ✅ **Mirror all repositories** läbi Nexus - Maven `<mirrorOf>*</mirrorOf>`, npm `registry=`
3. ✅ **CI/CD secrets** - GitHub Secrets, GitLab CI Variables
4. ✅ **Multi-stage build** - credentials builder stage'is, runtime clean
5. ✅ **NO_PROXY exception** - Nexus domain proxy exclusion'is
6. ✅ **Test credential leak** - `docker run --rm myapp env | grep -i nexus` → tühi

---

### Viited

- **Docker daemon proxy config:** https://docs.docker.com/config/daemon/systemd/#httphttps-proxy
- **BuildKit secrets:** https://docs.docker.com/build/building/secrets/
- **Praktiline näide:** `labs/01-docker-lab/solutions/backend-java-spring/README-PROXY.md`
- **Node.js näide:** `labs/01-docker-lab/solutions/backend-nodejs/README-PROXY.md`

---

## Kokkuvõte

**Java/Spring Boot konteineriseerimise peamised punktid:**

1. **Tomcat WAR → Spring Boot JAR paradigma muutus:**
   - WAR: Shared JVM, manual server mgmt, downtime, vertical scaling
   - JAR Konteiner: Isolated JVM, embedded server, zero-downtime, horizontal scaling

2. **Multi-stage builds on KRIITILISED:**
   - Build stage: Gradle/Maven + JDK (600-800MB)
   - Runtime stage: JRE (250MB)
   - **60-70% size vähenemine**

3. **JVM tuning konteinerites:**
   - Java 10+ on container-aware (automaatne)
   - Heap: 60-80% konteineri memory'st (`-XX:MaxRAMPercentage=75.0`)
   - G1GC low latency jaoks (`-XX:+UseG1GC`)

4. **Spring Boot eelised:**
   - Embedded server (pole Tomcat install'i vaja)
   - Executable JAR (`java -jar app.jar`)
   - Actuator (health checks, metrics out-of-the-box)
   - Cloud-native (12-factor app)

**Node.js konteineriseerimise peamised punktid:**

1. **Multi-stage builds:**
   - Build stage: Compile TypeScript, webpack bundle
   - Runtime stage: Prod dependencies + built artifacts
   - **80-85% size vähenemine** (1.2GB → 180MB)

2. **npm ci --only=production:**
   - Faster, predictable, clean installs
   - Ära install dev dependencies production'is

3. **Alpine + non-root user:**
   - node:18-alpine (väike base image)
   - USER node (security)

**Viide laboratooriumidele:**
- **Lab 1:** Dockerize User Service (Node.js Express) ja Todo Service (Java Spring Boot) - praktiline rakendamine

**Järgmised sammud:**
- **Peatükk 7:** Docker image'ite haldamine, optimeerimine, registry workflow
- **Peatükk 8:** Docker Compose (mitme konteineri orkestratsioon)

## Viited ja Edasine Lugemine

### Java/Spring Boot:

- **Spring Boot Docker documentation:** https://spring.io/guides/gs/spring-boot-docker/
- **Spring Boot Actuator:** https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html
- **Eclipse Temurin images:** https://hub.docker.com/_/eclipse-temurin
- **JVM Container tuning:** https://developers.redhat.com/blog/2017/03/14/java-inside-docker

### JVM Tuning:

- **Java SE Container support:** https://docs.oracle.com/javase/8/docs/technotes/guides/vm/gctuning/
- **G1 Garbage Collector:** https://www.oracle.com/technical-resources/articles/java/g1gc.html
- **JVM ergonomics:** https://docs.oracle.com/en/java/javase/17/gctuning/ergonomics.html

### Node.js:

- **Node.js Docker best practices:** https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md
- **Official Node.js images:** https://hub.docker.com/_/node
- **npm ci documentation:** https://docs.npmjs.com/cli/v10/commands/npm-ci

### Tools:

- **Dive:** Analyze image layers - https://github.com/wagoodman/dive
- **JVM Memory Calculator:** https://github.com/cloudfoundry/java-buildpack-memory-calculator

---

**Viimane uuendus:** 2025-01-25
**Seos laboritega:** Lab 1 (Dockerize User Service + Todo Service, corporate proxy käsitlus)
**Eelmine peatükk:** 06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md
**Järgmine peatükk:** 07-Docker-Imagite-Haldamine-Optimeerimine.md
