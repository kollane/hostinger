# Peatükk 6: Dockerfile ja Image Loomine - TÄIENDUS
## Põhjalik Tehnoloogiate Käsitlus

**Kestus:** 6-8 tundi (suurendatud 4h → 6-8h)
**Eesmärk:** Mõista erinevate tehnoloogiate konteineridamist DevOps administraatori vaatenurgast

---

## 📋 Ülevaade

See peatükk käsitleb PÕHJALIKULT järgmisi tehnoloogiaid:
1. **Node.js rakenduste konteineridamine**
2. **Java/Spring Boot rakenduste konteineridamine** (sh Tomcat)
3. **Database Migrations (Liquibase)**
4. **ORM ja Database Ühendused (Hibernate)**

**OLULINE DevOps Vaatenurk:**
- ✅ EI õpeta programmeerimist
- ✅ KÜLL õpetame konteineridamist, optimiseerimist, deployment'i
- ✅ Fookus: Kuidas DevOps administraator neid tehnoloogiaid HALDAB

---

## 📦 SEKTSIOON 1: Node.js Rakenduste Konteineridamine

### 1.1 Node.js Rakenduse Struktuur (DevOps Vaates)

**Mis on Node.js rakendus?**
```
backend-nodejs/
├── package.json          # Dependencies ja scripts (npm põhifail)
├── package-lock.json     # Dependency versioonide lock
├── src/                  # Source code (arendaja kirjutab)
│   ├── index.js          # Main application entry point
│   ├── routes/           # API endpoints
│   ├── models/           # Database models
│   └── middleware/       # Express middleware
├── .env.example          # Environment variables template
└── node_modules/         # Installed dependencies (SUUR!)
```

**DevOps Administraator PEAB Teadma:**
- ✅ `package.json` sisaldab dependency'sid ja scripte
- ✅ `npm install` installib kõik dependency'd → `node_modules/`
- ✅ `node_modules/` on SUUR (100-500MB) → EI tohi Docker image'sse
- ✅ `npm start` käivitab rakenduse
- ✅ Environment variables (DB_HOST, JWT_SECRET, etc.)

**DevOps Administraator EI PEAD Teadma:**
- ❌ JavaScript süntaksi
- ❌ Express routing implementatsiooni
- ❌ Kuidas middleware'e kirjutada

---

### 1.2 Node.js Dockerfile - Lihtne Variant

```dockerfile
# Lihtne Dockerfile (EI SOOVITATUD production'is!)
FROM node:18

# Working directory
WORKDIR /app

# Kopeeri kõik failid
COPY . .

# Installi dependency'd
RUN npm install

# Avalda port
EXPOSE 3000

# Käivita rakendus
CMD ["npm", "start"]
```

**Probleemid:**
- ❌ Image suurus: ~900MB (node:18 = 900MB!)
- ❌ Development dependency'd kaasas
- ❌ `node_modules/` rebuildid iga muudatuse peale
- ❌ Root kasutajana töötamine (security risk)
- ❌ Ei kasuta layer caching'u

---

### 1.3 Node.js Dockerfile - Optimeeritud Variant

```dockerfile
# Stage 1: Dependencies
FROM node:18-alpine AS deps

WORKDIR /app

# Kopeeri AINULT dependency failid
COPY package.json package-lock.json ./

# Installi PRODUCTION dependency'd
RUN npm ci --only=production

# Stage 2: Builder (kui vaja build step)
FROM node:18-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Kui vaja transpile (TypeScript) või build
# RUN npm run build

# Stage 3: Runtime
FROM node:18-alpine AS runner

WORKDIR /app

# Security: Non-root kasutaja
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

# Kopeeri AINULT production dependency'd
COPY --from=deps /app/node_modules ./node_modules

# Kopeeri AINULT source code
COPY --chown=nodejs:nodejs src ./src
COPY --chown=nodejs:nodejs package.json ./

# Kasutaja muutmine
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start
CMD ["node", "src/index.js"]
```

**Parandused:**
- ✅ Image suurus: ~900MB → ~150MB (alpine base)
- ✅ Layer caching: package.json eraldi COPY
- ✅ Non-root kasutaja (nodejs:nodejs)
- ✅ AINULT production dependencies
- ✅ Health check built-in

---

### 1.4 Node.js .dockerignore

```
# .dockerignore - ÄRA kopeeri Docker image'sse
node_modules/
npm-debug.log
.env
.env.local
.git/
.gitignore
README.md
*.md
.vscode/
.idea/
coverage/
.nyc_output/
dist/
build/
```

**Miks oluline?**
- 🚀 Kiirem build (väiksem context)
- 💾 Väiksem image size
- 🔒 Ei kopeeri secrets'e (.env)

---

### 1.5 Node.js Multi-Stage Build Võrdlus

| Aspekt | Lihtne Dockerfile | Multi-Stage Optimeeritud |
|--------|-------------------|--------------------------|
| **Image size** | ~900MB | ~150MB |
| **Base image** | node:18 (Debian) | node:18-alpine |
| **Dependencies** | All (dev + prod) | Production only |
| **Layer caching** | ❌ Puudub | ✅ package.json eraldi |
| **Security** | ❌ Root user | ✅ Non-root (nodejs) |
| **Health check** | ❌ Puudub | ✅ Built-in |
| **Build aeg** | ~2 min | ~1 min (cached) |

---

### 1.6 Node.js Environment Variables

**DevOps Administraator Konfiguurib:**

```bash
# Docker run
docker run -e DB_HOST=postgres \
           -e DB_PORT=5432 \
           -e DB_NAME=appdb \
           -e JWT_SECRET=mysecret \
           -e NODE_ENV=production \
           user-service:1.0

# Docker Compose
services:
  user-service:
    image: user-service:1.0
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: appdb
      JWT_SECRET: ${JWT_SECRET}
      NODE_ENV: production

# Kubernetes
env:
  - name: DB_HOST
    value: "postgres-user"
  - name: JWT_SECRET
    valueFrom:
      secretKeyRef:
        name: jwt-secret
        key: secret
```

**Rakendus kasutab neid:**
```javascript
// src/config/database.js (arendaja kirjutas)
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});
```

**DevOps roll:** Tagada, et kõik environment variables on õigesti seadistatud!

---

### 1.7 Node.js Troubleshooting

**Levinud probleemid:**

#### Probleem 1: "Cannot find module"
```bash
docker logs user-service
# Error: Cannot find module 'express'
```

**Põhjus:** Dependencies pole installitud
**Lahendus:**
```dockerfile
RUN npm ci --only=production  # Kontrolli, et see on Dockerfile's
```

#### Probleem 2: "ECONNREFUSED postgres:5432"
```bash
docker logs user-service
# Error: connect ECONNREFUSED 172.17.0.2:5432
```

**Põhjus:** PostgreSQL pole veel valmis või vale hostname
**Lahendus:**
```yaml
# Docker Compose - lisa healthcheck ja depends_on
services:
  postgres:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]

  user-service:
    depends_on:
      postgres:
        condition: service_healthy
```

#### Probleem 3: "Port 3000 already in use"
```bash
docker logs user-service
# Error: listen EADDRINUSE: address already in use :::3000
```

**Põhjus:** Teine konteiner kasutab sama porti
**Lahendus:**
```bash
# Muuda host port
docker run -p 3001:3000 user-service:1.0
```

---

### 1.8 Node.js Viited Laboritele

**Labor 1: Docker Põhitõed**
- 📁 `labs/01-docker-lab/exercises/01a-single-container-nodejs.md`
  - User Service konteineridamine
  - Lihtne Dockerfile vs optimeeritud
  - Image size võrdlus

**Labor 1: Optimization**
- 📁 `labs/01-docker-lab/exercises/05-optimization.md`
  - Multi-stage build Node.js'le
  - 200MB → 50MB optimiseerimine
  - Health checks

**Lahendused:**
- 📁 `labs/01-docker-lab/solutions/backend-nodejs/Dockerfile`
- 📁 `labs/01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized`

---

## ☕ SEKTSIOON 2: Java/Spring Boot Rakenduste Konteineridamine

### 2.1 Traditional vs Modern Java Deployment

#### Traditional Approach: WAR + Tomcat Server

**Kuidas see töötas (enne konteinereid):**

```
1. Arendaja kirjutab Java kood
2. Build tool (Maven/Gradle) → WAR file
3. WAR file deploy'takse Tomcat serverisse
4. Tomcat server käivitab WAR'i
```

**Failide struktuur:**
```
my-app/
├── src/main/java/           # Java source code
├── src/main/resources/      # application.properties
├── pom.xml                  # Maven config
└── target/
    └── my-app.war           # Build output (deployable)

Tomcat Server:
/opt/tomcat/
├── bin/                     # Tomcat scripts (catalina.sh)
├── conf/                    # server.xml, tomcat-users.xml
├── webapps/                 # WAR'id pannakse siia
│   ├── ROOT/                # Default app
│   └── my-app.war           # Sinu app
└── logs/                    # Tomcat logs
```

**Deployment:**
```bash
# Traditional deployment
cp target/my-app.war /opt/tomcat/webapps/
/opt/tomcat/bin/catalina.sh run
```

**Probleemid:**
- ❌ Sõltub Tomcat serveri versioonist
- ❌ Shared server (mitu app'i samas Tomcat'is)
- ❌ Raske skaleerida
- ❌ Konfiguratsioon server.xml'is

---

#### Modern Approach: Spring Boot + Embedded Tomcat

**Kuidas see töötab (Spring Boot):**

```
1. Arendaja kirjutab Java kood
2. Spring Boot build → Executable JAR (sisaldab Tomcat'i!)
3. Käivita JAR: java -jar my-app.jar
4. Embedded Tomcat käivitub automaatselt
```

**Failide struktuur:**
```
my-spring-boot-app/
├── src/main/java/
│   └── com/example/
│       ├── Application.java         # Main class (@SpringBootApplication)
│       ├── controllers/             # REST controllers
│       ├── services/                # Business logic
│       └── repositories/            # Database access
├── src/main/resources/
│   └── application.properties       # Spring Boot config
├── build.gradle                     # Gradle config
└── build/libs/
    └── my-app-1.0.0.jar             # Executable JAR (sisaldab Tomcat!)
```

**Build ja Run:**
```bash
# Build (Gradle)
./gradlew clean bootJar

# Run
java -jar build/libs/my-app-1.0.0.jar

# Spring Boot käivitab embedded Tomcat'i automaatselt!
# Started Application in 3.5 seconds (JVM running for 4.0)
```

**Eelised:**
- ✅ Self-contained (Tomcat kaasas)
- ✅ Üks JAR = üks rakendus
- ✅ Lihtne skaleerida (iga instance oma JAR)
- ✅ Konfiguratsioon application.properties'is

---

### 2.2 Java Build Tools: Maven vs Gradle

**DevOps administraator PEAB tundma mõlemat!**

#### Maven (pom.xml)

```xml
<!-- pom.xml -->
<project>
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>todo-service</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
        </dependency>
    </dependencies>
</project>
```

**Maven käsud:**
```bash
mvn clean package          # Build JAR
mvn spring-boot:run        # Run app
mvn test                   # Run tests
```

#### Gradle (build.gradle)

```groovy
// build.gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.2.0'
}

group = 'com.example'
version = '1.0.0'

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.postgresql:postgresql'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.liquibase:liquibase-core'
}
```

**Gradle käsud:**
```bash
./gradlew clean bootJar    # Build JAR
./gradlew bootRun          # Run app
./gradlew test             # Run tests
```

**Võrdlus:**

| Aspekt | Maven | Gradle |
|--------|-------|--------|
| **Config fail** | pom.xml (XML) | build.gradle (Groovy/Kotlin) |
| **Loetavus** | Verbose | Concise |
| **Build kiirus** | Aeglasem | Kiirem (incremental builds) |
| **Wrapper** | `mvnw` | `./gradlew` |
| **Kasutumus** | Legacy projects | Modern projects |

**Meie labides:** Kasutame **Gradle** (todo-service)

---

### 2.3 Java/Spring Boot Dockerfile - Traditional WAR Variant

```dockerfile
# Dockerfile.war - Traditional Tomcat deployment
FROM tomcat:9-jdk17

# Kustuta default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Kopeeri WAR file Tomcat webapps'i
COPY target/my-app.war /usr/local/tomcat/webapps/ROOT.war

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
```

**Image size:** ~450MB

**Kasutusjuhtumid:**
- Legacy applications
- Vanad projektid, mis ei saa Spring Boot'i migreeruda
- Organisatsioonid, kus Tomcat server on standard

---

### 2.4 Java/Spring Boot Dockerfile - Multi-Stage Build (SOOVITATUD)

```dockerfile
# Stage 1: Build
FROM gradle:8.5-jdk17 AS builder

WORKDIR /app

# Kopeeri AINULT build failid (layer caching!)
COPY build.gradle settings.gradle ./
COPY gradle/ gradle/

# Download dependencies (cached layer)
RUN gradle dependencies --no-daemon

# Kopeeri source code
COPY src/ src/

# Build JAR
RUN gradle bootJar --no-daemon

# Stage 2: Runtime
FROM eclipse-temurin:17-jre-alpine AS runner

WORKDIR /app

# Security: Non-root kasutaja
RUN addgroup --system --gid 1001 spring
RUN adduser --system --uid 1001 spring

# Kopeeri AINULT JAR file builder stage'ist
COPY --from=builder --chown=spring:spring /app/build/libs/*.jar app.jar

# Kasutaja muutmine
USER spring

# Expose Spring Boot port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# JVM tuning (optional)
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

**Image size võrdlus:**

| Variant | Base Image | Size | Layers |
|---------|------------|------|--------|
| **Single-stage (JDK)** | `openjdk:17` | ~470MB | 8 |
| **Multi-stage (JRE)** | `eclipse-temurin:17-jre` | ~280MB | 5 |
| **Multi-stage (Alpine JRE)** | `eclipse-temurin:17-jre-alpine` | **~180MB** | 5 |

**Optimiseerimine:**
- ✅ Build stage: JDK (kogu Gradle + compiler)
- ✅ Runtime stage: JRE (ainult Java runtime)
- ✅ Alpine base (~5MB vs Debian ~120MB)
- ✅ Layer caching: dependencies eraldi
- ✅ Non-root user (spring)
- ✅ Health check (Spring Boot Actuator)

---

### 2.5 Java .dockerignore

```
# .dockerignore
.gradle/
build/
target/
*.log
.env
.git/
.gitignore
README.md
*.md
.idea/
.vscode/
*.iml
bin/
out/
```

---

### 2.6 Spring Boot application.properties (DevOps Vaates)

**Fail:** `src/main/resources/application.properties`

```properties
# Application
spring.application.name=todo-service
server.port=8081

# Database (environment variables!)
spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:todo_service_db}
spring.datasource.username=${DB_USER:postgres}
spring.datasource.password=${DB_PASSWORD:postgres}

# JPA/Hibernate
spring.jpa.hibernate.ddl-auto=none
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect

# Liquibase (migrations)
spring.liquibase.enabled=true
spring.liquibase.change-log=classpath:db/changelog/db.changelog-master.xml

# JWT
jwt.secret=${JWT_SECRET:default-secret-change-in-production}

# Actuator (health checks)
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always
```

**DevOps administraator seadistab environment variables:**

```bash
# Docker
docker run -e DB_HOST=postgres-todo \
           -e DB_PORT=5432 \
           -e DB_NAME=todo_service_db \
           -e DB_USER=appuser \
           -e DB_PASSWORD=secret \
           -e JWT_SECRET=production-secret \
           todo-service:1.0

# Kubernetes ConfigMap + Secret
apiVersion: v1
kind: ConfigMap
metadata:
  name: todo-config
data:
  DB_HOST: "postgres-todo"
  DB_PORT: "5432"
  DB_NAME: "todo_service_db"
---
apiVersion: v1
kind: Secret
metadata:
  name: todo-secret
type: Opaque
stringData:
  DB_USER: "appuser"
  DB_PASSWORD: "secret"
  JWT_SECRET: "production-secret"
```

---

### 2.7 Java Build Process - Samm-Sammult

**DevOps administraator PEAB tundma build protsessi!**

#### Gradle Build

```bash
# 1. Clone repo
git clone https://github.com/example/todo-service.git
cd todo-service

# 2. Kontrolli Gradle wrapper olemasolu
ls -la gradlew
# -rwxr-xr-x  1 user  staff  5764 Jan 22 10:00 gradlew

# 3. Build JAR (esimene kord võtab kaua - download dependencies)
./gradlew clean bootJar

# Output:
# BUILD SUCCESSFUL in 1m 23s
# 5 actionable tasks: 5 executed

# 4. Leia JAR file
ls -lh build/libs/
# -rw-r--r-- 1 user staff  45M Jan 22 10:02 todo-service-1.0.0.jar

# 5. Testi JAR'i lokaalset (optional)
java -jar build/libs/todo-service-1.0.0.jar

# 6. Build Docker image
docker build -t todo-service:1.0 -f Dockerfile.optimized .

# 7. Verify image
docker images | grep todo-service
# todo-service  1.0  abc123  2 minutes ago  180MB
```

#### Maven Build (kui kasutad Maven'i)

```bash
# Build JAR
mvn clean package

# Output JAR
ls -lh target/
# -rw-r--r-- 1 user staff  45M Jan 22 10:02 todo-service-1.0.0.jar
```

---

### 2.8 Java Troubleshooting

#### Probleem 1: "OutOfMemoryError: Java heap space"

```bash
docker logs todo-service
# java.lang.OutOfMemoryError: Java heap space
```

**Põhjus:** JVM vajab rohkem mälu
**Lahendus:**

```dockerfile
# Dockerfile - lisa JVM tuning
ENV JAVA_OPTS="-Xmx1024m -Xms512m"
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

```yaml
# Kubernetes - lisa resource limits
resources:
  requests:
    memory: "512Mi"
  limits:
    memory: "1Gi"
```

#### Probleem 2: "Cannot load driver class: org.postgresql.Driver"

```bash
docker logs todo-service
# Cannot load driver class: org.postgresql.Driver
```

**Põhjus:** PostgreSQL dependency puudub
**Lahendus:**

```groovy
// build.gradle - kontrolli dependency
dependencies {
    runtimeOnly 'org.postgresql:postgresql'  // PEAB olema!
}
```

#### Probleem 3: Liquibase migration ebaõnnestub

```bash
docker logs todo-service
# Liquibase: liquibase.exception.LockException: Could not acquire change log lock
```

**Põhjus:** Eelmine container crashis ja lock jäi peale
**Lahendus:**

```bash
# Sisene PostgreSQL'i
kubectl exec -it postgres-todo-0 -- psql -U appuser -d todo_service_db

# Kustuta lock
DELETE FROM databasechangeloglock;
```

---

### 2.9 Java Viited Laboritele

**Labor 1: Single Container - Java Spring Boot**
- 📁 `labs/01-docker-lab/exercises/01b-single-container-java.md`
  - Todo Service konteineridamine
  - Gradle build process
  - JAR file creation

**Labor 1: Optimization**
- 📁 `labs/01-docker-lab/exercises/05-optimization.md`
  - Multi-stage build Java'le
  - 370MB → 180MB optimiseerimine
  - JDK vs JRE comparison

**Lahendused:**
- 📁 `labs/01-docker-lab/solutions/backend-java-spring/Dockerfile`
- 📁 `labs/01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized`

---

## 🗄️ SEKTSIOON 3: Database Migrations (Liquibase)

### 3.1 Miks Database Migrations DevOps Kontekstis?

**Traditsiooniline lähenemine (käsitsi):**

```sql
-- DBA käivitab käsitsi SQL skriptid
psql -U postgres -d appdb -f 001-create-users-table.sql
psql -U postgres -d appdb -f 002-add-email-column.sql
psql -U postgres -d appdb -f 003-create-index.sql
```

**Probleemid:**
- ❌ Käsitsi tegevus (error-prone)
- ❌ Raske jälgida, mis versioon on deploy'tud
- ❌ Rollback keeruline
- ❌ Multi-environment sync (dev, staging, prod)

**Automated Migrations (Liquibase/Flyway):**

```
Application käivitub → Liquibase kontrollib DB versiooni → Rakendab uued migration'id → Application valmis
```

**Eelised:**
- ✅ Automaatne (osa rakenduse käivitumisest)
- ✅ Versioonitud (changelog failid)
- ✅ Rollback võimalus
- ✅ Idempotent (sama migration kaks korda = ok)

---

### 3.2 Liquibase vs Flyway

| Aspekt | Liquibase | Flyway |
|--------|-----------|--------|
| **Formaadid** | XML, YAML, JSON, SQL | SQL, Java |
| **Database support** | 30+ | 20+ |
| **Rollback** | ✅ Built-in | ❌ Manual (paid version) |
| **Changelog** | XML changelog | SQL files (V1__name.sql) |
| **Komplekssus** | Keerulisem | Lihtsam |
| **Kasutus** | Enterprise | Startups |

**Meie labides:** Kasutame **Liquibase** (todo-service, user-service)

---

### 3.3 Liquibase Changelog Struktuur

**Meie rakenduses:**

```
src/main/resources/db/changelog/
├── db.changelog-master.xml       # Master file (viitab teistele)
├── changes/
│   ├── 001-create-users-table.xml
│   ├── 002-add-email-index.xml
│   └── 003-add-todos-table.xml
└── rollback/
    └── 001-rollback-users.xml
```

**Master changelog:** `db.changelog-master.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.9.xsd">

    <!-- Include all changesets -->
    <include file="db/changelog/changes/001-create-users-table.xml"/>
    <include file="db/changelog/changes/002-add-email-index.xml"/>
    <include file="db/changelog/changes/003-add-todos-table.xml"/>

</databaseChangeLog>
```

**Changeset näide:** `001-create-users-table.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.9.xsd">

    <changeSet id="001-create-users-table" author="devops">
        <createTable tableName="users">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true" nullable="false"/>
            </column>
            <column name="username" type="VARCHAR(50)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="email" type="VARCHAR(100)">
                <constraints nullable="false" unique="true"/>
            </column>
            <column name="password_hash" type="VARCHAR(255)">
                <constraints nullable="false"/>
            </column>
            <column name="created_at" type="TIMESTAMP" defaultValueComputed="CURRENT_TIMESTAMP"/>
        </createTable>

        <rollback>
            <dropTable tableName="users"/>
        </rollback>
    </changeSet>

</databaseChangeLog>
```

---

### 3.4 Liquibase Database Tabelid

**Liquibase loob 2 tabelit:**

#### 1. `databasechangelog` - Migration History

```sql
SELECT * FROM databasechangelog;

-- id                        | author  | filename                      | exectype | dateexecuted
-- 001-create-users-table    | devops  | changes/001-create-users...   | EXECUTED | 2025-01-22 10:00:00
-- 002-add-email-index       | devops  | changes/002-add-email-ind...  | EXECUTED | 2025-01-22 10:00:01
-- 003-add-todos-table       | devops  | changes/003-add-todos-tab...  | EXECUTED | 2025-01-22 10:00:02
```

**DevOps kasutamine:**
- Vaata, mis migration'id on rakendatud
- Kontrolli deployment versiooni
- Troubleshoot migration issues

#### 2. `databasechangeloglock` - Locking Mechanism

```sql
SELECT * FROM databasechangeloglock;

-- id | locked | lockgranted         | lockedby
-- 1  | false  | NULL                | NULL
```

**DevOps kasutamine:**
- Kui stuck, kustuta lock:
  ```sql
  UPDATE databasechangeloglock SET locked = false;
  ```

---

### 3.5 Liquibase Docker Konteineris (Docker Compose)

**Variant A: Application käivitab Liquibase'i (Spring Boot)**

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: todo_service_db
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: secret
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser"]
      interval: 5s

  todo-service:
    build: ./backend-java-spring
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DB_HOST: postgres
      DB_USER: appuser
      DB_PASSWORD: secret
      # Spring Boot automaatselt käivitab Liquibase'i!
      SPRING_LIQUIBASE_ENABLED: "true"
```

**Kuidas see töötab:**

```
1. docker compose up
2. PostgreSQL käivitub
3. todo-service ootab PostgreSQL healthcheck'i
4. todo-service käivitub
5. Spring Boot detect'ib Liquibase dependency
6. Liquibase kontrollib databasechangelog tabelit
7. Liquibase rakendab uued changeset'id
8. Application valmis
```

---

**Variant B: Eraldi Liquibase Init Container (Käsitsi)**

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: todo_service_db
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser"]

  liquibase-init:
    image: liquibase/liquibase:4.25-alpine
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./db/changelog:/liquibase/changelog
    command:
      - --url=jdbc:postgresql://postgres:5432/todo_service_db
      - --username=appuser
      - --password=secret
      - --changeLogFile=changelog/db.changelog-master.xml
      - update

  todo-service:
    build: ./backend-java-spring
    depends_on:
      liquibase-init:
        condition: service_completed_successfully
    environment:
      SPRING_LIQUIBASE_ENABLED: "false"  # Liquibase juba käivitatud!
```

**Erinevus:**
- Variant A: Application käivitab migration'id (lihtne)
- Variant B: Eraldi container migration'idele (advanced, rohkem kontrolli)

---

### 3.6 Liquibase Kubernetes'es (InitContainer)

**InitContainer Pattern:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-service
spec:
  template:
    spec:
      # Init Container käivitub ENNE main container'it
      initContainers:
      - name: liquibase-migration
        image: liquibase/liquibase:4.25-alpine
        command:
        - sh
        - -c
        - |
          liquibase \
            --url=jdbc:postgresql://postgres-todo:5432/todo_service_db \
            --username=${DB_USER} \
            --password=${DB_PASSWORD} \
            --changeLogFile=/liquibase/changelog/db.changelog-master.xml \
            update
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-todo-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-todo-secret
              key: password
        volumeMounts:
        - name: liquibase-changelog
          mountPath: /liquibase/changelog

      # Main Container käivitub AINULT pärast init container'i edukat lõppu
      containers:
      - name: todo-service
        image: todo-service:1.0-optimized
        env:
        - name: SPRING_LIQUIBASE_ENABLED
          value: "false"  # Init container juba tegi!

      volumes:
      - name: liquibase-changelog
        configMap:
          name: liquibase-changelog
```

**ConfigMap changelog failidele:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: liquibase-changelog
data:
  db.changelog-master.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <databaseChangeLog>
      <include file="001-create-todos.xml"/>
    </databaseChangeLog>

  001-create-todos.xml: |
    <?xml version="1.0" encoding="UTF-8"?>
    <databaseChangeLog>
      <changeSet id="001" author="devops">
        <createTable tableName="todos">
          <column name="id" type="BIGINT" autoIncrement="true">
            <constraints primaryKey="true"/>
          </column>
          <column name="title" type="VARCHAR(255)"/>
        </createTable>
      </changeSet>
    </databaseChangeLog>
```

**Kuidas see töötab:**

```
1. kubectl apply -f deployment.yaml
2. Kubernetes loob Pod'i
3. Init Container (liquibase-migration) käivitub
4. Liquibase rakendab migration'id
5. Init Container lõpeb (exit 0)
6. Main Container (todo-service) käivitub
7. Pod valmis (Running)
```

**Eelised:**
- ✅ Migration'id ENNE rakendust
- ✅ Rakendus ei crashe DB schema puudumisel
- ✅ Eraldi concern (separation of concerns)

---

### 3.7 Liquibase Troubleshooting

#### Probleem 1: "Waiting for changelog lock"

```bash
docker logs todo-service
# Waiting for changelog lock...
```

**Põhjus:** Eelmine migration jäi lukku (crash)
**Lahendus:**

```sql
-- Sisene DB'sse
psql -U appuser -d todo_service_db

-- Vabasta lock
UPDATE databasechangeloglock SET locked = false, lockgranted = NULL, lockedby = NULL;
```

#### Probleem 2: "Validation Failed: change set ... has been modified"

```bash
docker logs todo-service
# Validation Failed: change set 001-create-users has been modified
```

**Põhjus:** Changelog file muudetud pärast deployment'i (checksum mismatch)
**Lahendused:**

**Lahendus 1:** Rollback ja uuesti
```sql
DELETE FROM databasechangelog WHERE id = '001-create-users';
```

**Lahendus 2:** Clear checksums (testing only!)
```bash
liquibase clear-checksums
```

**PRODUCTION:** EI TOHI muuta juba deploy'tud changeset'e! Lisa UUSI changeset'e.

---

### 3.8 Liquibase Best Practices (DevOps)

**DO:**
- ✅ Kasuta descript ID'sid (`001-create-users-table`, mitte `changeset1`)
- ✅ Üks changeset = üks logical change
- ✅ Lisa rollback iga changeset'i juurde
- ✅ Testi migration'e dev keskkonnas ENNE prod'i
- ✅ Versiooni changelog failid Git'is
- ✅ Kasuta InitContainer Kubernetes'es

**DON'T:**
- ❌ ÄRA muuda juba deploy'tud changeset'e
- ❌ ÄRA kustuta vanu changelog faile
- ❌ ÄRA käivita migration'e käsitsi prod'is (automation!)
- ❌ ÄRA deploy'da rakendust ilma migration'e testimata

---

### 3.9 Liquibase Viited Laboritele

**Labor 2: Docker Compose**
- 📁 `labs/02-docker-compose-lab/exercises/04-database-migrations.md`
  - Liquibase setup Docker Compose'is
  - Automated migrations
  - Healthcheck dependencies

**Labor 3: Kubernetes Basics**
- 📁 `labs/03-kubernetes-basics-lab/exercises/06-initcontainers-migrations.md`
  - InitContainer pattern
  - Liquibase ConfigMap
  - Migration troubleshooting

---

## 🔗 SEKTSIOON 4: Hibernate ja Database Ühendused (Administraatori Perspektiivist)

### 4.1 Mis on Hibernate? (DevOps Vaates)

**Arendaja vaates:**
```java
// Arendaja kirjutab Java koodi (ORM - Object-Relational Mapping)
@Entity
public class User {
    @Id
    @GeneratedValue
    private Long id;
    private String username;
}

// Arendaja salvestab objekti
User user = new User();
user.setUsername("john");
userRepository.save(user);  // Hibernate genereerib SQL automaatselt!
```

**DevOps vaates:**

```
Hibernate = Database Connection Manager + SQL Generator

DevOps PEAB teadma:
1. Connection Pooling (HikariCP)
2. Environment Variables (DB credentials)
3. Connection Limits
4. Performance Tuning
5. Troubleshooting Connection Issues
```

**DevOps EI PEAD teadma:**
- ❌ Kuidas @Entity annotatsioone kasutada
- ❌ Kuidas ORM mapping'e kirjutada
- ❌ Hibernate Query Language (HQL)

---

### 4.2 Connection Pooling (HikariCP)

**Mis on Connection Pool?**

```
Ilma poolita:
Request 1 → Uus DB connection → Query → Sulge connection
Request 2 → Uus DB connection → Query → Sulge connection
Request 3 → Uus DB connection → Query → Sulge connection
(Aeglane! Iga request uus TCP connection)

Connection pool'iga:
Application käivitub → Loo 10 connection'it → POOL

Request 1 → Võta connection pool'ist → Query → Tagasta pool'i
Request 2 → Võta connection pool'ist → Query → Tagasta pool'i
Request 3 → Võta connection pool'ist → Query → Tagasta pool'i
(Kiire! Connection'id reused)
```

**Spring Boot default:** HikariCP (kõige kiirem connection pool)

---

### 4.3 HikariCP Konfigureerimine (application.properties)

```properties
# Database Connection
spring.datasource.url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}

# HikariCP Connection Pool
spring.datasource.hikari.maximum-pool-size=10        # Max concurrent connections
spring.datasource.hikari.minimum-idle=5              # Min idle connections
spring.datasource.hikari.connection-timeout=30000    # 30s wait for connection
spring.datasource.hikari.idle-timeout=600000         # 10min idle before close
spring.datasource.hikari.max-lifetime=1800000        # 30min max connection life

# JPA/Hibernate
spring.jpa.hibernate.ddl-auto=none                   # DON'T auto-create schema (use Liquibase!)
spring.jpa.show-sql=false                            # Log SQL queries (debug only)
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
```

**DevOps tuning:**

```properties
# Development (local)
spring.datasource.hikari.maximum-pool-size=5         # Väike pool

# Production (Kubernetes)
spring.datasource.hikari.maximum-pool-size=20        # Suurem pool
```

---

### 4.4 Connection Pool Troubleshooting

#### Probleem 1: "HikariPool - Connection is not available"

```bash
docker logs todo-service
# HikariPool-1 - Connection is not available, request timed out after 30000ms
```

**Põhjus:** Pool täis, kõik connection'id kasutusel
**Analüüs:**

```bash
# Kontrolli PostgreSQL connection'e
psql -U appuser -d todo_service_db -c "SELECT count(*) FROM pg_stat_activity WHERE datname = 'todo_service_db';"
# count: 10  (kui pool size = 10, pool on täis!)

# Vaata, mis päringud töötavad
psql -U appuser -d todo_service_db -c "SELECT pid, state, query FROM pg_stat_activity WHERE datname = 'todo_service_db';"
```

**Lahendused:**

**1. Suurenda pool size:**
```properties
spring.datasource.hikari.maximum-pool-size=20  # 10 → 20
```

**2. Suurenda Kubernetes replicas:**
```yaml
spec:
  replicas: 3  # Rohkem pod'e, jaotab load'i
```

**3. PostgreSQL max_connections:**
```sql
-- Kontrolli max connections
SHOW max_connections;
-- 100

-- Kui pool size 20 ja 5 replica't = 100 connections
-- Suurenda PostgreSQL max_connections (postgresql.conf)
max_connections = 200
```

---

#### Probleem 2: "Too many connections" (PostgreSQL)

```bash
docker logs postgres-todo
# FATAL: sorry, too many clients already
```

**Põhjus:** Liiga palju connection'e PostgreSQL'ile
**Analüüs:**

```sql
-- Max connections
SHOW max_connections;  -- 100

-- Current connections
SELECT count(*) FROM pg_stat_activity;  -- 105 (üle limiidi!)

-- Connections by application
SELECT application_name, count(*)
FROM pg_stat_activity
GROUP BY application_name;

-- application_name     | count
-- todo-service (pod-1) | 20
-- todo-service (pod-2) | 20
-- todo-service (pod-3) | 20
-- todo-service (pod-4) | 20
-- todo-service (pod-5) | 20
-- user-service         | 10
-- TOTAL                | 110
```

**Lahendus:**

**1. Vähenda pool size:**
```properties
# Kui 5 replica't ja pool size 20 = 100 connections
# Vähenda pool size: 5 * 15 = 75 connections
spring.datasource.hikari.maximum-pool-size=15
```

**2. Kasuta PgBouncer (connection pooler):**

```yaml
# pgbouncer-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgbouncer
spec:
  template:
    spec:
      containers:
      - name: pgbouncer
        image: edoburu/pgbouncer:latest
        env:
        - name: DATABASE_URL
          value: "postgresql://appuser:secret@postgres-todo:5432/todo_service_db"
        - name: MAX_CLIENT_CONN
          value: "200"       # Application connections
        - name: DEFAULT_POOL_SIZE
          value: "25"        # PostgreSQL connections
```

**Arhitektuur:**

```
Todo Service (5 replicas, pool size 20) → 100 connections
    ↓
PgBouncer (max_client_conn=200, pool_size=25)
    ↓
PostgreSQL (max_connections=100) ← AINULT 25 connections!
```

---

### 4.5 Hibernate Environment Variables (DevOps Seadistab)

```yaml
# Kubernetes Deployment
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
        env:
        # Database Connection
        - name: DB_HOST
          value: "postgres-todo"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "todo_service_db"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password

        # HikariCP Tuning (optional - override defaults)
        - name: SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE
          value: "15"
        - name: SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT
          value: "20000"

        # Hibernate Settings (optional)
        - name: SPRING_JPA_SHOW_SQL
          value: "false"  # true = debug (log SQL)
        - name: SPRING_JPA_HIBERNATE_DDL_AUTO
          value: "none"   # NEVER 'create' or 'update' in production!
```

---

### 4.6 Health Checks (Hibernate Connection)

**Spring Boot Actuator Health Check:**

```bash
# Health endpoint
curl http://localhost:8081/actuator/health

# Response
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP"
    },
    "ping": {
      "status": "UP"
    }
  }
}
```

**Kubernetes Liveness/Readiness Probe:**

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
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8081
          initialDelaySeconds: 40
          periodSeconds: 10

        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8081
          initialDelaySeconds: 20
          periodSeconds: 5
```

**Kui DB connection puudub:**
```json
{
  "status": "DOWN",
  "components": {
    "db": {
      "status": "DOWN",
      "details": {
        "error": "org.postgresql.util.PSQLException: Connection refused"
      }
    }
  }
}
```

→ Kubernetes restart'ib pod'i (liveness probe fail)

---

### 4.7 Hibernate Monitoring (DevOps)

**Metricsid (Prometheus + Grafana):**

```properties
# application.properties - enable metrics
management.endpoints.web.exposure.include=health,info,metrics,prometheus
management.metrics.export.prometheus.enabled=true
```

**Olulised metricsid:**

```bash
# HikariCP metrics
curl http://localhost:8081/actuator/metrics/hikaricp.connections.active
# Aktiivsed ühendused

curl http://localhost:8081/actuator/metrics/hikaricp.connections.pending
# Ootel ühendused (kui suur → suurenda pool size)

curl http://localhost:8081/actuator/metrics/hikaricp.connections.timeout
# Connection timeout'id (kui suur → probleem!)
```

**Grafana Dashboard:**
- HikariCP Active Connections (gauge)
- HikariCP Pending Connections (counter)
- HikariCP Timeout Rate (rate)

---

### 4.8 Hibernate Best Practices (DevOps)

**DO:**
- ✅ Kasuta HikariCP (Spring Boot default)
- ✅ Seadista connection pool size application vajaduse järgi
- ✅ Kasuta health checks (Actuator)
- ✅ Monitoori connection pool metrics
- ✅ Kasuta PgBouncer kui palju replicas'e
- ✅ Testi connection limits ENNE production'i

**DON'T:**
- ❌ ÄRA kasuta `spring.jpa.hibernate.ddl-auto=create` production'is
- ❌ ÄRA sea `show-sql=true` production'is (performance!)
- ❌ ÄRA unusta PostgreSQL `max_connections` limiti
- ❌ ÄRA käivita ilma health checks'ita

---

### 4.9 Hibernate Viited Laboritele

**Labor 2: Docker Compose**
- 📁 `labs/02-docker-compose-lab/exercises/02-full-stack.md`
  - Spring Boot + PostgreSQL connection
  - Environment variables seadistamine
  - Connection testing

**Labor 3: Kubernetes Basics**
- 📁 `labs/03-kubernetes-basics-lab/exercises/04-configuration-management.md`
  - ConfigMap database settings'ile
  - Secret DB credentials'ile
  - Environment variable injection

**Labor 6: Monitoring**
- 📁 `labs/06-monitoring-logging-lab/exercises/01-prometheus-setup.md`
  - HikariCP metrics collection
  - Connection pool monitoring
  - Grafana dashboards

---

## 📚 Kokkuvõte - Peatükk 6 Täiendus

### Õpitulemused

Peale selle peatüki läbimist oskad:

**Node.js:**
- ✅ Dockerfile Node.js rakendusele (lihtne + optimeeritud)
- ✅ Multi-stage builds (900MB → 150MB)
- ✅ npm install ja node_modules optimeerimine
- ✅ Environment variables seadistamine
- ✅ Health checks
- ✅ Troubleshooting (ECONNREFUSED, module not found)

**Java/Spring Boot:**
- ✅ Traditional (WAR + Tomcat) vs Modern (JAR + Embedded Tomcat)
- ✅ Gradle vs Maven build process
- ✅ Multi-stage builds Java'le (470MB → 180MB)
- ✅ JDK vs JRE optimization
- ✅ application.properties konfigureerimine
- ✅ JVM tuning (heap size)
- ✅ Troubleshooting (OutOfMemoryError, driver missing)

**Liquibase:**
- ✅ Database migrations automaatne haldamine
- ✅ Changelog struktuur (XML/YAML)
- ✅ Docker Compose migrations (depends_on + healthcheck)
- ✅ Kubernetes InitContainer pattern
- ✅ databasechangelog ja databasechangeloglock tabelid
- ✅ Troubleshooting (lock issues, checksum errors)

**Hibernate/HikariCP:**
- ✅ Connection pooling kontseptsioon
- ✅ HikariCP konfigureerimine
- ✅ Pool size tuning
- ✅ PostgreSQL max_connections limit
- ✅ PgBouncer kui palju replicas'e
- ✅ Health checks ja monitoring
- ✅ Troubleshooting (connection timeout, too many connections)

---

### Laboriviited (Kõik Täiendatud)

| Tehnoloogia | Labor 1 | Labor 2 | Labor 3 | Labor 6 |
|-------------|---------|---------|---------|---------|
| **Node.js** | ✅ Harjutus 1A, 5 | ✅ Harjutus 2 | ✅ Harjutus 2, 4 | - |
| **Java/Spring Boot** | ✅ Harjutus 1B, 5 | ✅ Harjutus 2 | ✅ Harjutus 2, 4 | - |
| **Liquibase** | - | ✅ Harjutus 4 | ✅ Harjutus 6 | - |
| **Hibernate** | - | ✅ Harjutus 2 | ✅ Harjutus 4 | ✅ Harjutus 1 |

---

### Kestuse Uuendus

**Vana Peatükk 6:** 4 tundi
**Uus Peatükk 6 (täiendatud):** **6-8 tundi**

**Jaotus:**
- Node.js konteineridamine: 1.5h
- Java/Spring Boot konteineridamine: 2h
- Liquibase migrations: 1.5h
- Hibernate/HikariCP: 1-2h
- Troubleshooting ja praktilised harjutused: 1-2h

---

**Edu õppimisega! 🚀**

*See täiendus annab põhjaliku arusaamise neljast võtmetehnoloogiast DevOps administraatori vaatenurgast.*
