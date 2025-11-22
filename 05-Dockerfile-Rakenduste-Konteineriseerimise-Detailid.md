# Peatükk 5: Dockerfile ja Rakenduste Konteineriseerimise Detailid

**Kestus:** 10-12 tundi (põhjalik)
**Tase:** Keskmine
**Eeldused:** Peatükk 4 läbitud, Docker põhimõtted selged

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist oskad:

1. ✅ Kirjutada Dockerfile'e (FROM, RUN, COPY, CMD, ENTRYPOINT)
2. ✅ Optimeerida Docker image'eid (layer caching, multi-stage builds)
3. ✅ Konteineriseerida Node.js rakendusi (best practices)
4. ✅ Konteineriseerida Java/Spring Boot rakendusi (JAR vs WAR)
5. ✅ Mõista database migrations (Liquibase) DevOps vaates
6. ✅ Kasutada .dockerignore faile tõhusalt
7. ✅ Rakendada security best practices (non-root user)
8. ✅ Optimeerida image suurust (900MB → 150MB)
9. ✅ Debuggida build probleeme

---

## 🎯 OLULINE: DevOps Administraatori Vaatenurk

**Mida sa ÕPID selles peatükis:**
- ✅ Kuidas rakendusi konteineriseerida ja deploy'da
- ✅ Kuidas image'eid optimeerida
- ✅ Kuidas environment variables seadistada
- ✅ Kuidas database migrations'eid hallata

**Mida sa EI ÕPI:**
- ❌ Kuidas Node.js või Java koodi kirjutada
- ❌ Kuidas SQL päringuid luua
- ❌ Kuidas REST API'sid implementeerida

**Analoogia:**
```
DevOps Administraator : Rakendus = Automehhaanik : Auto

Automehhaanik:
✅ Hooldab autot
✅ Paigaldab osi
✅ Debuggib probleeme
❌ Ei disaini autot
❌ Ei tooda mootoreid

DevOps Administraator:
✅ Konteineriseerib rakendusi
✅ Deploy'b production'i
✅ Debuggib infrastructure probleeme
❌ Ei kirjuta rakenduse koodi
❌ Ei disaini database skeeme
```

---

## 📦 1. Dockerfile Põhitõed

### 1.1 Mis On Dockerfile?

**Dockerfile** = retsept Docker image loomiseks (Infrastructure as Code)

```dockerfile
# Näide: Lihtne Node.js Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY src/ ./src/
CMD ["node", "src/index.js"]
```

**Kuidas see töötab:**
```bash
# 1. Kirjuta Dockerfile
vim Dockerfile

# 2. Build image
docker build -t myapp:1.0 .

# 3. Run container
docker run -d -p 3000:3000 myapp:1.0
```

---

### 1.2 Dockerfile Instruktsioonid

#### FROM - Base Image

**Alati esimene rida Dockerfile's!**

```dockerfile
# Täielik OS image (Debian-based)
FROM ubuntu:22.04

# Programming language runtime
FROM node:18        # ~900MB (Debian + Node.js)
FROM node:18-alpine # ~150MB (Alpine + Node.js) ✅ SOOVITATUD

# Java runtime
FROM eclipse-temurin:17-jre-alpine  # JRE (runtime only)
FROM eclipse-temurin:17-jdk         # JDK (development kit)

# Webserver
FROM nginx:1.25-alpine

# Database
FROM postgres:16-alpine
```

**Alpine vs Debian:**

| Aspekt | Alpine | Debian |
|--------|--------|--------|
| **Size** | ~5MB | ~120MB |
| **Package manager** | apk | apt |
| **Shell** | sh (not bash!) | bash |
| **Kasutus** | Production | Development/compatibility |

**Best practice:** Kasuta `-alpine` varianti production'is! ✅

---

#### WORKDIR - Working Directory

```dockerfile
# Määrab working directory containeris
WORKDIR /app

# Kõik järgnevad käsud (COPY, RUN) käivitatakse /app kataloogis
# Analoog: cd /app
```

**Miks WORKDIR?**
- ✅ Puhtam struktuur
- ✅ Ei pea kirjutama `cd /app` iga käsu ette
- ✅ Best practice

---

#### COPY vs ADD

**COPY (SOOVITATUD):**
```dockerfile
# Kopeeri fail host'ist containerisse
COPY package.json /app/

# Kopeeri kataloog
COPY src/ /app/src/

# Kopeeri kõik (kasuta .dockerignore!)
COPY . /app/
```

**ADD (HOIATUS):**
```dockerfile
# ADD = COPY + auto-extract tar files + download URLs
ADD archive.tar.gz /app/  # Auto-extracts!
ADD https://example.com/file.txt /app/  # Downloads!

# ❌ Väldi ADD! Kasuta COPY (predictable)
```

**Best practice:** Kasuta ALATI `COPY`, mitte `ADD`! ✅

---

#### RUN - Execute Commands

```dockerfile
# Käivita käsk IMAGE BUILD ajal
RUN apt update && apt install -y curl

# Node.js: Install dependencies
RUN npm install

# Java: Build JAR
RUN ./gradlew bootJar

# Mitu käsku ühes RUN'is (best practice!)
RUN apt update && \
    apt install -y curl wget && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
```

**Miks kombineerida käsud?**
- ✅ Vähem layers
- ✅ Väiksem image size
- ✅ Kiirem build

---

#### CMD vs ENTRYPOINT

**CMD - Default käsk (võib override'ida):**
```dockerfile
CMD ["node", "src/index.js"]

# Kasutamine:
docker run myapp               # Käivitab: node src/index.js
docker run myapp npm test      # Override: npm test
```

**ENTRYPOINT - Fikseeritud käsk (ei saa override'ida):**
```dockerfile
ENTRYPOINT ["node"]
CMD ["src/index.js"]

# Kasutamine:
docker run myapp               # Käivitab: node src/index.js
docker run myapp src/test.js   # Käivitab: node src/test.js
```

**Kombineerimine:**
```dockerfile
# Best practice: ENTRYPOINT + CMD
ENTRYPOINT ["node"]
CMD ["src/index.js"]  # Default argument, saab muuta
```

---

#### ENV - Environment Variables

```dockerfile
# Määra environment variable
ENV NODE_ENV=production
ENV PORT=3000

# Kasuta variable
CMD node -e "console.log('Port:', process.env.PORT)"
```

---

#### EXPOSE - Dokumenteeri Port

```dockerfile
# Dokumenteeri, millist porti konteiner kasutab
EXPOSE 3000

# ⚠️ EXPOSE ei avalda porti automaatselt!
# Pead kasutama -p flag'i: docker run -p 3000:3000 myapp
```

---

#### USER - Security

```dockerfile
# Vaikimisi: container töötab ROOT'ina (OHTLIK!)

# Best practice: Loo non-root kasutaja
RUN addgroup --system --gid 1001 appuser
RUN adduser --system --uid 1001 appuser

# Kasuta non-root kasutajat
USER appuser

# Nüüd kõik käsud käivitatakse "appuser" kasutajana
```

---

#### HEALTHCHECK - Container Health

```dockerfile
# Kontrolli, kas rakendus on terve
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD curl -f http://localhost:3000/health || exit 1

# Docker kontrollib iga 30s, kas /health endpoint vastab
```

---

### 1.3 Dockerfile Näide - Kõik Koos

```dockerfile
# Base image
FROM node:18-alpine

# Working directory
WORKDIR /app

# Metadata
LABEL maintainer="devops@example.com"
LABEL version="1.0"

# Non-root kasutaja (security)
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

# Copy dependencies
COPY --chown=nodejs:nodejs package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application code
COPY --chown=nodejs:nodejs src/ ./src/

# Environment
ENV NODE_ENV=production
ENV PORT=3000

# Kasutaja muutmine
USER nodejs

# Port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s CMD node -e "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

# Start command
CMD ["node", "src/index.js"]
```

---

## 🔧 2. Layer Caching ja Optimiseerimine

### 2.1 Kuidas Docker Layers Töötavad

**Docker image koosneb layer'itest:**

```dockerfile
FROM node:18-alpine        # Layer 1: Base image
WORKDIR /app               # Layer 2: Create /app
COPY package.json .        # Layer 3: Copy package.json
RUN npm install            # Layer 4: Install dependencies (SUUR!)
COPY src/ ./src/           # Layer 5: Copy source code
CMD ["node", "src/index.js"] # Layer 6: Metadata
```

**Layer caching:**
```
1st build: Kõik layer'id builditakse (5 min)
2nd build: Kui package.json EI MUUTU → Layer 3-4 cached! (10 sec)
```

---

### 2.2 Layer Caching Optimiseerimine

**❌ VALE (ei kasuta caching'ut):**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .                    # Kopeeri KÕIK (sh package.json)
RUN npm install             # Rebuild iga muudatuse peale!
CMD ["node", "src/index.js"]

# Probleem:
# src/index.js muudatus → COPY . . muutub → npm install rebuild → AEGLANE!
```

**✅ ÕIGE (kasutab caching'ut):**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./       # Kopeeri AINULT dependency failid
RUN npm install             # Cached, kui package.json ei muutu!
COPY src/ ./src/            # Kopeeri source (muutub tihti)
CMD ["node", "src/index.js"]

# Benefit:
# src/index.js muudatus → npm install CACHED → KIIRE!
```

**Võrdlus:**

| Stsenaarium | Vale Dockerfile | Õige Dockerfile |
|-------------|----------------|----------------|
| **1st build** | 5 min | 5 min |
| **src muudatus** | 5 min | 10 sec ✅ |
| **package.json muudatus** | 5 min | 5 min |

---

### 2.3 .dockerignore - Välistamine

**Mis on .dockerignore?**
Fail, mis ütleb Docker'ile, milliseid faile EI tohiks image'sse kopeerida.

**.dockerignore näide:**
```
# Dependencies (installed in RUN npm install)
node_modules/

# Development files
*.log
.env
.env.local

# Git
.git/
.gitignore

# IDEs
.vscode/
.idea/
*.swp

# Documentation
README.md
*.md

# Tests
tests/
coverage/
__tests__/

# Build artifacts
dist/
build/
```

**Miks oluline?**
- 🚀 Kiirem build (väiksem context)
- 💾 Väiksem image (ei kopeeri jura)
- 🔒 Security (ei kopeeri .env secrets)

---

## 🟢 3. Node.js Rakenduste Konteineriseerimise Detailid

### 3.1 Node.js Rakenduse Struktuur (DevOps Vaates)

**Meie näide: `labs/apps/backend-nodejs/` (User Service)**

```
backend-nodejs/
├── package.json           # Dependencies (npm põhifail)
├── package-lock.json      # Lock file (versioonid)
├── src/
│   ├── index.js           # Main entry point
│   ├── routes/            # API endpoints
│   ├── models/            # Database models
│   └── middleware/        # Express middleware
├── .env.example           # Environment template
└── node_modules/          # Installed deps (SUUR - 100-500MB!)
```

**DevOps Administraator PEAB teadma:**
- ✅ `package.json` = dependency list
- ✅ `npm install` = installib node_modules/
- ✅ `npm start` = käivitab rakenduse
- ✅ Environment variables (DB_HOST, JWT_SECRET)

**DevOps Administraator EI PEA teadma:**
- ❌ JavaScript süntaksi
- ❌ Express routing'u implementatsiooni

---

### 3.2 Node.js Dockerfile - Lihtne Variant (EI SOOVITATUD)

```dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3000
CMD ["npm", "start"]
```

**Probleemid:**
- ❌ Image size: ~900MB
- ❌ Development dependencies kaasas
- ❌ Root kasutaja (security risk)
- ❌ Ei kasuta layer caching'ut

---

### 3.3 Node.js Dockerfile - Optimeeritud Multi-Stage

```dockerfile
# ============================================
# Stage 1: Dependencies
# ============================================
FROM node:18-alpine AS deps

WORKDIR /app

# Copy AINULT dependency files (layer caching!)
COPY package.json package-lock.json ./

# Install PRODUCTION dependencies
RUN npm ci --only=production

# ============================================
# Stage 2: Runtime
# ============================================
FROM node:18-alpine AS runner

WORKDIR /app

# Security: Non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

# Copy AINULT production dependencies stage'ist
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application source
COPY --chown=nodejs:nodejs src ./src
COPY --chown=nodejs:nodejs package.json ./

# Environment
ENV NODE_ENV=production
ENV PORT=3000

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
- ✅ Image size: ~900MB → ~150MB
- ✅ Layer caching: package.json eraldi
- ✅ Non-root user (nodejs:nodejs)
- ✅ AINULT production dependencies
- ✅ Health check built-in

---

### 3.4 Node.js Build ja Run

```bash
# 1. Clone repo
git clone https://github.com/example/user-service.git
cd user-service

# 2. Loo .dockerignore
cat > .dockerignore <<EOF
node_modules/
npm-debug.log
.env
.git/
README.md
EOF

# 3. Build optimized image
docker build -t user-service:1.0 -f Dockerfile.optimized .

# 4. Verify size
docker images user-service
# user-service  1.0  abc123  2 min ago  152MB ✅

# 5. Run with environment variables
docker run -d \
  --name user-service \
  -p 3000:3000 \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=appuser \
  -e DB_PASSWORD=secret \
  -e JWT_SECRET=my-jwt-secret \
  -e NODE_ENV=production \
  user-service:1.0

# 6. Test
curl http://localhost:3000/health
# {"status":"healthy"}
```

---

### 3.5 Node.js Troubleshooting

#### Probleem 1: "Cannot find module 'express'"
```bash
docker logs user-service
# Error: Cannot find module 'express'
```

**Põhjus:** Dependencies pole installitud
**Lahendus:** Kontrolli Dockerfile - `RUN npm ci --only=production`

#### Probleem 2: "ECONNREFUSED postgres:5432"
```bash
docker logs user-service
# Error: connect ECONNREFUSED
```

**Põhjus:** PostgreSQL pole valmis või vale hostname
**Lahendus:** Kasuta healthcheck + depends_on Docker Compose'is

---

## ☕ 4. Java/Spring Boot Rakenduste Konteineriseerimise Detailid

### 4.1 Traditional vs Modern Java Deployment

#### **Traditional: WAR + Tomcat Server**

```
Arendaja → Maven/Gradle → WAR file → Tomcat server → Deploy
                           ↓
                    my-app.war (deployment unit)
```

**Probleemid:**
- ❌ Sõltub Tomcat versioonist
- ❌ Shared server (mitu app'i samas Tomcat'is)
- ❌ Raske skaleerida

#### **Modern: Spring Boot + Embedded Tomcat**

```
Arendaja → Gradle/Maven → Executable JAR (sisaldab Tomcat'i!) → java -jar my-app.jar
                           ↓
                    my-app-1.0.0.jar (self-contained)
```

**Eelised:**
- ✅ Self-contained (Tomcat kaasas)
- ✅ Üks JAR = üks rakendus
- ✅ Lihtne skaleerida

---

### 4.2 Java Build Tools: Maven vs Gradle

| Aspekt | Maven | Gradle |
|--------|-------|--------|
| **Config** | `pom.xml` (XML) | `build.gradle` (Groovy) |
| **Wrapper** | `mvnw` | `./gradlew` |
| **Build kiirus** | Aeglasem | Kiirem ✅ |
| **Kasutus** | Legacy | Modern ✅ |

**Gradle build käsud:**
```bash
./gradlew clean bootJar    # Build executable JAR
./gradlew bootRun          # Run locally
./gradlew test             # Run tests
```

---

### 4.3 Java/Spring Boot Multi-Stage Dockerfile (SOOVITATUD)

```dockerfile
# ============================================
# Stage 1: Build
# ============================================
FROM gradle:8.5-jdk17 AS builder

WORKDIR /app

# Copy build files (layer caching!)
COPY build.gradle settings.gradle ./
COPY gradle/ gradle/

# Download dependencies (cached!)
RUN gradle dependencies --no-daemon

# Copy source code
COPY src/ src/

# Build JAR
RUN gradle bootJar --no-daemon

# ============================================
# Stage 2: Runtime
# ============================================
FROM eclipse-temurin:17-jre-alpine AS runner

WORKDIR /app

# Security: Non-root user
RUN addgroup --system --gid 1001 spring && \
    adduser --system --uid 1001 spring

# Copy AINULT JAR from builder stage
COPY --from=builder --chown=spring:spring /app/build/libs/*.jar app.jar

# Kasutaja muutmine
USER spring

# Expose Spring Boot port
EXPOSE 8081

# Health check (Spring Boot Actuator)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# JVM tuning
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

**Image size võrdlus:**

| Variant | Base | Size |
|---------|------|------|
| Single-stage (JDK) | openjdk:17 | ~470MB |
| Multi-stage (JRE Alpine) | temurin:17-jre-alpine | **~180MB** ✅ |

**Optimiseerimised:**
- ✅ Build stage: JDK (gradle + compiler)
- ✅ Runtime stage: JRE (ainult Java runtime)
- ✅ Alpine base (~5MB vs Debian ~120MB)
- ✅ Non-root user (spring)

---

### 4.4 Java application.properties (DevOps Vaates)

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

# Liquibase (database migrations)
spring.liquibase.enabled=true
spring.liquibase.change-log=classpath:db/changelog/db.changelog-master.xml

# Actuator (health checks)
management.endpoints.web.exposure.include=health,info,metrics
```

**DevOps seadistab environment variables:**

```bash
docker run -d \
  --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=postgres-todo \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=appuser \
  -e DB_PASSWORD=secret \
  -e JWT_SECRET=production-secret \
  todo-service:1.0
```

---

### 4.5 Java Build ja Run

```bash
# 1. Clone repo
cd labs/apps/backend-java-spring

# 2. Build JAR locally (test)
./gradlew clean bootJar

# 3. Verify JAR
ls -lh build/libs/
# -rw-r--r-- 1 user staff  45M  todo-service-1.0.0.jar

# 4. Build Docker image
docker build -t todo-service:1.0 -f Dockerfile.optimized .

# 5. Verify image size
docker images todo-service
# todo-service  1.0  abc123  5 min ago  182MB ✅

# 6. Run
docker run -d \
  --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=postgres \
  todo-service:1.0

# 7. Test health endpoint
curl http://localhost:8081/actuator/health
# {"status":"UP"}
```

---

### 4.6 Java Troubleshooting

#### Probleem: OutOfMemoryError

```bash
docker logs todo-service
# java.lang.OutOfMemoryError: Java heap space
```

**Lahendus: Lisa JVM tuning**
```dockerfile
ENV JAVA_OPTS="-Xmx1024m -Xms512m"
```

```yaml
# Kubernetes: Resource limits
resources:
  requests:
    memory: "512Mi"
  limits:
    memory: "1Gi"
```

---

## 🗄️ 5. Database Migrations (Liquibase) - DevOps Vaates

### 5.1 Miks Database Migrations?

**Traditsiooniline (käsitsi):**
```sql
psql -U postgres -d appdb -f 001-create-users.sql
psql -U postgres -d appdb -f 002-add-email-column.sql
```

**Probleemid:**
- ❌ Käsitsi (error-prone)
- ❌ Raske jälgida versioone
- ❌ Rollback keeruline

**Automated Migrations (Liquibase):**
```
Application käivitub → Liquibase kontrollib DB → Rakendab uued changesets → Valmis!
```

**Eelised:**
- ✅ Automaatne
- ✅ Versioonitud
- ✅ Rollback võimalus
- ✅ Idempotent

---

### 5.2 Liquibase Changelog Näide

**Master changelog:** `db/changelog/db.changelog-master.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.9.xsd">

    <include file="db/changelog/changes/001-create-users-table.xml"/>
    <include file="db/changelog/changes/002-add-email-index.xml"/>
</databaseChangeLog>
```

**Changeset:** `001-create-users-table.xml`

```xml
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
    </createTable>

    <rollback>
        <dropTable tableName="users"/>
    </rollback>
</changeSet>
```

---

### 5.3 Liquibase DevOps Roll

**Mida DevOps administraator TEEB:**

```bash
# 1. Kontrolli migration history
kubectl exec -it postgres-todo-0 -- psql -U appuser -d todo_service_db
SELECT * FROM databasechangelog;

# Output:
# id                     | author  | filename                    | exectype
# 001-create-users-table | devops  | changes/001-create-users... | EXECUTED
# 002-add-email-index    | devops  | changes/002-add-email-in... | EXECUTED

# 2. Troubleshoot locked migrations
SELECT * FROM databasechangeloglock;

# Kui locked=true → Unlock:
DELETE FROM databasechangeloglock;

# 3. Rollback (kui vaja)
liquibase rollback --count=1
```

**Mida DevOps administraator EI TEE:**
- ❌ Ei kirjuta SQL päringuid (arendaja teeb)
- ❌ Ei disaini database skeemi

---

## 🎓 6. Multi-Stage Build Best Practices

### 6.1 Miks Multi-Stage?

**Single-stage probleem:**
```dockerfile
FROM node:18  # 900MB (sisaldab build tools!)
# Build ja runtime koos → Suur image
```

**Multi-stage lahendus:**
```dockerfile
FROM node:18 AS builder    # Build stage (900MB)
# RUN npm install, build, etc.

FROM node:18-alpine AS runner  # Runtime stage (150MB)
# COPY --from=builder ... (ainult built files!)
```

**Tulemus:** 900MB → 150MB ✅

---

### 6.2 Multi-Stage Pattern

```dockerfile
# ============================================
# Stage 1: Builder/Dependencies
# ============================================
FROM <language>:<version> AS builder
# - Install build tools
# - Install dependencies
# - Build application
# - Run tests (optional)

# ============================================
# Stage 2: Runtime
# ============================================
FROM <language>:<version>-alpine AS runner
# - Copy AINULT built files
# - Non-root user
# - Health check
# - Start command
```

---

## 📝 7. Praktilised Harjutused

### Harjutus 1: Node.js Rakenduse Konteineriseerimise (60 min)

**Eesmärk:** Konteineriseeri User Service optimeeritult

**Sammud:**
```bash
# 1. Navigate to app
cd labs/apps/backend-nodejs

# 2. Loo .dockerignore
cat > .dockerignore <<EOF
node_modules/
npm-debug.log
.env
.git/
README.md
coverage/
EOF

# 3. Kirjuta multi-stage Dockerfile.optimized
# (Kasuta peatükis 3.3 näidet)

# 4. Build
docker build -t user-service:optimized -f Dockerfile.optimized .

# 5. Verify size
docker images user-service

# 6. Run with env vars
docker run -d \
  --name user-service \
  -p 3000:3000 \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e JWT_SECRET=test-secret \
  user-service:optimized

# 7. Test health
curl http://localhost:3000/health
```

**Kontrolli:**
- [ ] Image size < 200MB
- [ ] Container käivitub
- [ ] Health endpoint vastab
- [ ] Non-root kasutaja (nodejs)

---

### Harjutus 2: Java/Spring Boot Konteineriseerimise (90 min)

**Eesmärk:** Konteineriseeri Todo Service multi-stage build'iga

**Sammud:**
```bash
# 1. Navigate
cd labs/apps/backend-java-spring

# 2. Test local build
./gradlew clean bootJar
ls -lh build/libs/

# 3. Kirjuta Dockerfile.optimized
# (Kasuta peatükis 4.3 näidet)

# 4. Build Docker image
docker build -t todo-service:optimized -f Dockerfile.optimized .

# 5. Verify size (peaks olema ~180MB)
docker images todo-service

# 6. Run
docker run -d \
  --name todo-service \
  -p 8081:8081 \
  -e DB_HOST=postgres \
  -e DB_NAME=todo_service_db \
  todo-service:optimized

# 7. Test actuator
curl http://localhost:8081/actuator/health
```

**Kontrolli:**
- [ ] Image size < 200MB
- [ ] Multi-stage build kasutusel
- [ ] JRE alpine base image
- [ ] Health check töötab

---

### Harjutus 3: Image Size Optimiseerimine (45 min)

**Eesmärk:** Võrdle lihtsat ja optimeeritud Dockerfile'i

**Sammud:**
```bash
# 1. Build lihtne variant (Node.js)
cat > Dockerfile.simple <<'EOF'
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
EOF

docker build -t user-service:simple -f Dockerfile.simple .

# 2. Build optimized variant
docker build -t user-service:optimized -f Dockerfile.optimized .

# 3. Võrdle sizes
docker images | grep user-service

# Expected:
# user-service  simple      900MB
# user-service  optimized   152MB

# 4. Võrdle layers
docker history user-service:simple
docker history user-service:optimized
```

**Analüüs:**
- [ ] Mitu korda väiksem optimized image?
- [ ] Mitmed layer'id on cached?
- [ ] Milline on build time erinevus?

---

### Harjutus 4: Liquibase Migrations Kubernetes'es (60 min)

**Eesmärk:** Õpi hallama database migrations'eid

**Sammud:**
```bash
# 1. Deploy PostgreSQL
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        env:
        - name: POSTGRES_DB
          value: todo_service_db
        - name: POSTGRES_USER
          value: appuser
        - name: POSTGRES_PASSWORD
          value: secret
        ports:
        - containerPort: 5432
EOF

# 2. Deploy todo-service (with Liquibase)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: todo-service
  template:
    metadata:
      labels:
        app: todo-service
    spec:
      containers:
      - name: todo-service
        image: todo-service:optimized
        env:
        - name: DB_HOST
          value: postgres
        - name: DB_NAME
          value: todo_service_db
        - name: DB_USER
          value: appuser
        - name: DB_PASSWORD
          value: secret
EOF

# 3. Kontrolli migration history
kubectl exec -it postgres-0 -- psql -U appuser -d todo_service_db \
  -c "SELECT * FROM databasechangelog;"

# 4. Vaata todo-service logisid
kubectl logs -f deployment/todo-service | grep Liquibase
```

**Kontrolli:**
- [ ] Liquibase changesets on rakendatud
- [ ] Tabelid on loodud
- [ ] Migrations töötavad automaatselt

---

## 🎓 8. Mida Sa Õppisid?

### Omandatud Teadmised

✅ **Dockerfile Süntaks:**
- FROM, WORKDIR, COPY, RUN, CMD, ENTRYPOINT
- ENV, EXPOSE, USER, HEALTHCHECK
- Layer struktuur ja caching

✅ **Optimiseerimine:**
- Multi-stage builds
- Layer caching (dependencies eraldi)
- .dockerignore kasutamine
- Alpine base images
- Image size 900MB → 150MB

✅ **Node.js Konteineriseerimise:**
- package.json layer caching
- npm ci --only=production
- Non-root nodejs kasutaja
- Health checks

✅ **Java/Spring Boot Konteineriseerimise:**
- Gradle/Maven build process
- JAR vs WAR deployment
- JDK (build) vs JRE (runtime)
- Spring Boot Actuator health checks

✅ **Database Migrations:**
- Liquibase changesets
- Migration history (databasechangelog)
- Rollback mechanisms
- DevOps troubleshooting

✅ **Security Best Practices:**
- Non-root users (nodejs, spring)
- Secrets via environment variables
- .dockerignore (ei kopeeri .env)
- Minimal base images

---

## 🚀 9. Järgmised Sammud

**Peatükk 6: PostgreSQL Konteinerites** 🐘
- PostgreSQL Docker konteineris
- Volume lifecycle ja data persistence
- Backup ja restore
- Performance monitoring
- **NÜÜD ON SUL DOCKERFILE OSKUSED VALMIS!**

**Peatükk 7: Docker Compose** 🐳
- Multi-container orchestration
- Frontend + Backend + PostgreSQL koos
- Networks ja service discovery

**Labid:**
- **Lab 1:** Docker Basics - Containerization exercises
- **Lab 2:** Docker Compose - Multi-service deployment

---

## 📖 10. Lisaressursid

**Dokumentatsioon:**
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Node.js Docker Best Practices](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)
- [Spring Boot Docker](https://spring.io/guides/topicals/spring-boot-docker/)
- [Liquibase Docs](https://docs.liquibase.com/)

**Meie materjalid:**
- `PEATUKK-6-TAIENDUS-TEHNOLOOGIAD.md` - Põhjalik 1700-realine supplement
- `labs/01-docker-lab/` - Hands-on exercises
- `labs/apps/backend-nodejs/` - User Service source
- `labs/apps/backend-java-spring/` - Todo Service source

---

## ✅ Kontrolli Ennast

Enne järgmisele peatükile liikumist, veendu et:

- [ ] Mõistad Dockerfile syntax'i (FROM, RUN, COPY, CMD)
- [ ] Oskad kirjutada multi-stage Dockerfile'e
- [ ] Oskad optimeerida image size'i (layer caching, alpine)
- [ ] Oskad konteineriseerida Node.js rakendusi
- [ ] Oskad konteineriseerida Java/Spring Boot rakendusi
- [ ] Mõistad Liquibase migrations'eid DevOps vaates
- [ ] Oskad kasutada .dockerignore faile
- [ ] Oskad rakendada security best practices (non-root)
- [ ] Oled läbinud kõik 4 praktilist harjutust

**Kui kõik on ✅, oled valmis Peatükiks 6!** 🚀

---

**Peatükk 5 lõpp**
**Järgmine:** Peatükk 6 - PostgreSQL Konteinerites

**Õnnitleme!** Oled nüüd ekspert rakenduste konteineriseerimises! 🐳☕🟢
