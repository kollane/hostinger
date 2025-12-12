# Legacy → Docker → Kubernetes: Roadmap

**Eesmärk:** Detailne roadmap ettevõtetele, kes migratsioonivad **Tomcat/Java/Spring Boot** legacy süsteemidest Docker Compose'i ja hiljem (vajadusel) Kubernetes'ele.

**Sihtrühm:**
- Legacy stack: Tomcat 8/9 + Java 8/11/17 + Spring Boot
- Build tool: Gradle (peamiselt), Maven
- Deploy: Manuaalsed WAR deploy'd, Jenkins copy-war
- Rakendusi: 5-20
- Keskkonnad: 3-4 (dev, test, prelive, prod)

**Ajakava:**
- **Etapp 1:** Konteinerise (Lab 1) - 3-6 kuud
- **Etapp 2:** Orkestreerimise (Lab 2) - 3-6 kuud
- **Etapp 2B:** Production (Compose) - 12-18 kuud (stabiilne!)
- **Etapp 3:** Kubernetes - Valikuline (ainult kui scale vajab)

---

## 1. Alguspunkt: Legacy Maailm

### 1.1. Tüüpiline Legacy Stack (2015-2020)

**Tehnoloogiline stack:**
- **App Server:** Tomcat 8/9 (test, prelive, prod serverites)
- **Runtime:** Java 8/11 rakendused
- **Framework:** Spring Boot 2.x (osad rakendused) või Spring MVC
- **Build:** Gradle build (peamiselt), mõned Maven
- **Database:** PostgreSQL/Oracle andmebaasid (eraldi serverites või AWS RDS)
- **Deploy:** Manuaalsed deploy'd (Jenkins → FTP/SCP → Tomcat restart)

**Infrastruktuur:**
```
Server A (test-app-01):
├─ /opt/tomcat8/webapps/crm.war
├─ /opt/tomcat8/webapps/analytics.war
└─ /opt/tomcat8/webapps/admin.war

Server B (prod-app-01):
├─ /opt/tomcat9/webapps/crm.war (v1.5.2)
├─ /opt/tomcat9/webapps/analytics.war (v2.1.0)
└─ /opt/tomcat9/webapps/admin.war (v1.0.3)

PostgreSQL Server (db-01):
├─ crm_db (port 5432)
├─ analytics_db (port 5432)
└─ admin_db (port 5432)
```

---

### 1.2. Probleemid Legacy Stack'iga

| Probleem | Kirjeldus | Mõju |
|----------|-----------|------|
| **Deploy aeg** | 30-60 min (build → copy → restart Tomcat) | Aeglane iteratsioon |
| **Downtime** | 5-15 min (Tomcat restart) | Kasutajad ei saa kasutada |
| **Konfiguratsioon** | server.xml, context.xml (iga server erinev) | Configuration drift |
| **Skaleerimise** | Raske (vajab uut serverit + manuaalset setup'i) | Raske kasvu hallata |
| **Keskkondade erinevused** | Dev ≠ Test ≠ Prod (erinevad conf'id) | Bugs prod'is! |
| **Dependencies** | WAR fail sisaldab kõike → suur (50-150 MB) | Pikk build, raske jagada |
| **Version control** | Manuaalsed WAR copy'd, versioonid segamini | Raske rollback |

**Konkreetne näide:**

```
CRM App Deploy (legacy):
1. Jenkins build (5 min)
2. Gradle war build (10 min)
3. SCP crm.war → test server (2 min)
4. Stop Tomcat (30 sek)
5. Delete old WAR + extracted dir (30 sek)
6. Copy new WAR to webapps/ (1 min)
7. Start Tomcat (2 min)
8. Wait for app startup (3-5 min)

Kokku: 25-30 min + 10 min downtime
```

---

### 1.3. Näidisrakendus (CRM System)

**Legacy Setup:**

```
Tomcat 9 Server (prod-app-01):
├─ /opt/tomcat/webapps/crm.war (120 MB)
├─ /opt/tomcat/conf/server.xml (port 8080, DB config)
├─ /opt/tomcat/conf/context.xml (JNDI datasource)
└─ Deploy: scp crm.war → restart Tomcat (10 min downtime)
```

**Konfiguratsioon (Tomcat server.xml):**

```xml
<!-- server.xml - JNDI DataSource -->
<Resource name="jdbc/CrmDB"
          auth="Container"
          type="javax.sql.DataSource"
          driverClassName="org.postgresql.Driver"
          url="jdbc:postgresql://prod-db-01:5432/crm_db"
          username="crmuser"
          password="ProdPassword123!"
          maxTotal="20"
          maxIdle="10"
          maxWaitMillis="10000" />
```

**Build (Gradle):**

```gradle
// build.gradle
plugins {
    id 'war'
    id 'org.springframework.boot' version '2.7.18'
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.postgresql:postgresql:42.5.4'
    providedRuntime 'org.springframework.boot:spring-boot-starter-tomcat'
}

war {
    archiveFileName = 'crm.war'
}
```

**Probleemid selle setup'iga:**
- ❌ Konfiguratsioon Tomcat server.xml'is (pole version control'is)
- ❌ Paroolid plaintext'is XML'is
- ❌ Dev/Test/Prod serverite konfid erinevad (manual setup)
- ❌ Deploy vajab Tomcat restart'i (downtime!)
- ❌ Raske skaleerida (iga uus server vajab manual setup)

---

## 2. Etapp 1: Konteinerise (Lab 1) - 3-6 kuud

### 2.1. Pilootprojekt (2 rakendust, 3 kuud)

#### 2.1.1. Vali Lihtsaimad Rakendused

**Kriteeriumid:**
- ✅ Spring Boot (soovitav) - embedded Tomcat
- ✅ Minimaalsed dependencies (vähe XML config'i)
- ✅ PostgreSQL (mitte Oracle - lihtne konteineriseerida)
- ✅ Mitte-kriitilised (võib tundide downtime'i lubada pilootfaasis)
- ✅ Aktiivne development (saad kiiresti testida)

**Näide (Valitud rakendused):**
- **App 1:** Internal Admin Panel (Spring Boot 2.7, Gradle, PostgreSQL)
  - Kasutajad: 10-20 (sisemised admins)
  - Traffic: Madal
  - Kriitilisus: Madal (võib olla paar tundi maas)

- **App 2:** Analytics Dashboard (Spring Boot 2.5, Gradle, PostgreSQL)
  - Kasutajad: 30-50 (read-only dashboard)
  - Traffic: Keskmine
  - Kriitilisus: Madal-keskmine

---

#### 2.1.2. Tomcat + Gradle Rakenduse Konteinermine

##### Variant A: Spring Boot Embedded Tomcat (Lihtsaim - SOOVITATAV)

**Dockerfile:**

```dockerfile
# Dockerfile (admin-panel - Spring Boot Gradle)
FROM gradle:7.6-jdk11 AS build
WORKDIR /app

# Kopeeri Gradle konfiguratsioon (cache layer)
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Download dependencies (cache layer - muutub harva)
RUN gradle dependencies --no-daemon

# Kopeeri source code (muutub tihti)
COPY src ./src

# Build JAR (skip tests for faster build)
RUN gradle bootJar --no-daemon

# Runtime stage (väike image)
FROM eclipse-temurin:11-jre-alpine
WORKDIR /app

# Kopeeri JAR from build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Environment variables (asenda application.properties)
ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV SPRING_PROFILES_ACTIVE=${SPRING_PROFILE:-prod}
ENV SERVER_PORT=${SERVER_PORT:-8080}

# Database config (asenda server.xml JNDI)
ENV SPRING_DATASOURCE_URL=${DB_URL:-jdbc:postgresql://localhost:5432/admin_db}
ENV SPRING_DATASOURCE_USERNAME=${DB_USER:-postgres}
ENV SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD:-changeme}

EXPOSE 8080

# Health check (Spring Boot Actuator)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --spider --quiet http://localhost:8080/actuator/health || exit 1

# Run Spring Boot app
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

**Build ja test:**

```bash
# 1. Build Docker image
docker build -t admin-panel:1.0 .

# Expected output:
# [build 1/7] FROM gradle:7.6-jdk11
# [build 2/7] COPY build.gradle settings.gradle
# [build 3/7] RUN gradle dependencies (CACHED!)
# [build 4/7] COPY src
# [build 5/7] RUN gradle bootJar
# [runtime 1/3] FROM eclipse-temurin:11-jre-alpine
# [runtime 2/3] COPY --from=build /app/build/libs/*.jar
# Successfully built: admin-panel:1.0

# 2. Run lokaalselt (connects to existing dev DB)
docker run -d --name admin-panel \
  -p 8080:8080 \
  -e SPRING_PROFILE=dev \
  -e DB_URL=jdbc:postgresql://192.168.1.50:5432/admin_dev \
  -e DB_USER=devuser \
  -e DB_PASSWORD=devpass123 \
  admin-panel:1.0

# 3. Test
curl http://localhost:8080/actuator/health
# Expected: {"status":"UP"}

curl http://localhost:8080/api/users
# Expected: JSON array of users

# 4. Logs
docker logs -f admin-panel
# Expected: Spring Boot startup logs, no errors

# 5. Stop
docker stop admin-panel
docker rm admin-panel
```

**Võrdlus Legacy vs Docker:**

| Aspekt | Legacy Tomcat | Docker (Spring Boot Embedded) |
|--------|---------------|-------------------------------|
| **Deploy aeg** | 30 min | 5 min (build + run) |
| **Downtime** | 10 min (Tomcat restart) | 0 min (blue-green) |
| **Konfiguratsioon** | server.xml (manual) | ENV vars (automated) |
| **Portability** | Specific server | Runs anywhere (dev laptop = prod) |
| **Rollback** | Manual (copy old WAR) | `docker run admin-panel:1.0.old` |
| **Scaling** | Manual new server | `docker run` × 3 |

---

##### Variant B: Tomcat WAR Deployment (Legacy App'idele)

**Kui rakendus ei kasuta Spring Boot embedded Tomcat'i (traditional WAR):**

```dockerfile
# Dockerfile (crm-app - Tomcat 9 + Gradle WAR)
FROM gradle:7.6-jdk11 AS build
WORKDIR /app

COPY build.gradle settings.gradle ./
COPY gradle ./gradle
RUN gradle dependencies --no-daemon

COPY src ./src
RUN gradle war --no-daemon

# Runtime stage
FROM tomcat:9-jdk11-alpine
WORKDIR /usr/local/tomcat

# Remove default webapps (security)
RUN rm -rf webapps/*

# Copy WAR from build stage
COPY --from=build /app/build/libs/*.war webapps/ROOT.war

# Environment variables
ENV JAVA_OPTS="-Xmx1024m -Xms512m -Dspring.profiles.active=${SPRING_PROFILE:-prod}"
ENV CATALINA_OPTS="-Ddb.host=${DB_HOST:-localhost} -Ddb.port=${DB_PORT:-5432}"

# Database config (asendab server.xml JNDI)
ENV DB_HOST=${DB_HOST:-localhost}
ENV DB_PORT=${DB_PORT:-5432}
ENV DB_NAME=${DB_NAME:-crm_db}
ENV DB_USER=${DB_USER:-postgres}
ENV DB_PASSWORD=${DB_PASSWORD:-changeme}

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --spider --quiet http://localhost:8080/ || exit 1

CMD ["catalina.sh", "run"]
```

**Kasutamine:**

```bash
docker build -t crm-app:1.0 .
docker run -d -p 8080:8080 \
  -e DB_HOST=192.168.1.50 \
  -e DB_NAME=crm_prod \
  -e DB_USER=crmuser \
  -e DB_PASSWORD=ProdPass123 \
  crm-app:1.0
```

---

##### Variant C: Gradle Build Optimization (Multi-Stage + Cache)

**Optimeeritud Dockerfile:**

```dockerfile
# Dockerfile (optimized - Gradle cache layers)
FROM gradle:7.6-jdk11 AS build
WORKDIR /app

# Cache Gradle wrapper ja dependencies (muutub harva)
COPY gradle ./gradle
COPY gradlew build.gradle settings.gradle ./
RUN ./gradlew dependencies --no-daemon || true

# Source code (muutub tihti)
COPY src ./src

# Build JAR
RUN ./gradlew bootJar --no-daemon

# Runtime (väike image)
FROM eclipse-temurin:11-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar

# Non-root user (security)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

**Tulemus:**
- ✅ Image size: ~150 MB (vs 600 MB kui kaasad Gradle ja JDK)
- ✅ Build time: 2-5 min (Gradle cache - 2. build on kiirem!)
- ✅ Security: Non-root user
- ✅ Layer caching: Dependencies muutuvad harva → build kiiremini

---

#### 2.1.3. Konfiguratsioon Migration

##### Enne (Tomcat server.xml JNDI):

```xml
<!-- server.xml -->
<Resource name="jdbc/MyDB"
          auth="Container"
          type="javax.sql.DataSource"
          driverClassName="org.postgresql.Driver"
          url="jdbc:postgresql://prod-db-01:5432/crm_db"
          username="crmuser"
          password="ProdPassword123!"
          maxTotal="20"
          maxIdle="10"
          maxWaitMillis="10000" />
```

**Probleemid:**
- ❌ Parool plaintext'is (version control!)
- ❌ Iga server vajab oma server.xml'i (manual setup)
- ❌ Dev/Test/Prod erinevused (configuration drift)

---

##### Pärast (Docker ENV vars + application.yml):

**application.yml (JAR'is, defaults):**

```yaml
# application.yml (embedded in JAR)
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:postgresql://localhost:5432/crm_db}
    username: ${SPRING_DATASOURCE_USERNAME:postgres}
    password: ${SPRING_DATASOURCE_PASSWORD:changeme}
    hikari:
      maximum-pool-size: ${DB_POOL_SIZE:20}
      minimum-idle: ${DB_POOL_MIN:10}
      connection-timeout: ${DB_TIMEOUT:10000}

  jpa:
    hibernate:
      ddl-auto: ${HIBERNATE_DDL_AUTO:validate}
    show-sql: ${SHOW_SQL:false}

server:
  port: ${SERVER_PORT:8080}
```

**`.env.prod` (Docker Compose):**

```bash
# .env.prod (NOT committed to Git!)
SPRING_DATASOURCE_URL=jdbc:postgresql://prod-db-01:5432/crm_db
SPRING_DATASOURCE_USERNAME=crmuser
SPRING_DATASOURCE_PASSWORD=ProdPassword123!
DB_POOL_SIZE=20
DB_POOL_MIN=10
DB_TIMEOUT=10000
HIBERNATE_DDL_AUTO=validate
SHOW_SQL=false
SERVER_PORT=8080
```

**Tulemused:**
- ✅ Paroolid `.env` failides (ei commitita Git'i)
- ✅ Sama image dev/test/prod (ainult `.env` erineb)
- ✅ Version control: `docker-compose.yml` (infra as code)
- ✅ Automatable: ENV vars tulevad Vault'ist/Secrets Manager'ist

---

### 2.2. Tulemus (Etapp 1 - 3 kuud)

**Saavutused:**
- ✅ 2 rakendust konteinerisse (admin-panel, analytics)
- ✅ Dockerfile'id valmis (multi-stage, Gradle cache)
- ✅ Deploy aeg: 60 min → 5 min (Docker build + run)
- ✅ Downtime: 10 min → 0 min (blue-green deployment)
- ✅ Dev = Prod (sama image, erinevad ENV vars)
- ✅ Õppinud: Gradle multi-stage builds, ENV vars vs XML config

**Metriikat:**

| Metric | Legacy | Docker (Piloot) |
|--------|--------|-----------------|
| Deploy aeg | 30-60 min | 5 min |
| Downtime | 10 min | 0 min |
| Rollback aeg | 30 min (manual) | 30 sek (`docker run old`) |
| Konfiguratsioon | Manual (XML) | Automated (ENV vars) |
| Dev = Prod? | ❌ Ei | ✅ Jah (sama image) |

---

## 3. Etapp 2: Orkestreerimise (Lab 2) - 3-6 kuud

### 3.1. Konverteeri Kõik 15 Rakendust

**Grupeeri rakendused projektideks (5 projektid, 15 rakendust):**

```
Project 1: CRM (3 rakendust)
├─ crm-frontend (Tomcat WAR)
├─ crm-backend (Spring Boot JAR)
└─ crm-reports (Spring Boot JAR)

Project 2: ERP (5 rakendust)
├─ erp-inventory (Tomcat WAR)
├─ erp-orders (Spring Boot JAR)
├─ erp-billing (Spring Boot JAR)
├─ erp-shipping (Spring Boot JAR)
└─ erp-analytics (Spring Boot JAR)

Project 3: Analytics (2 rakendust)
├─ analytics-etl (Spring Boot Batch JAR)
└─ analytics-dashboard (Spring Boot Web JAR)

Project 4: Portal (3 rakendust)
├─ portal-web (Tomcat WAR)
├─ portal-api (Spring Boot JAR)
└─ portal-admin (Spring Boot JAR)

Project 5: Internal Tools (2 rakendust)
├─ monitoring-dashboard (Spring Boot JAR)
└─ admin-tools (Spring Boot JAR)
```

**Prioriteet:**
1. **Kuu 1-2:** Project 1 (CRM) - kõige kasutatum
2. **Kuu 2-3:** Project 2 (ERP) - keerukam (5 apps)
3. **Kuu 3-4:** Project 3-5 (Analytics, Portal, Tools)

---

### 3.2. Docker Compose Pattern (iga projekt)

#### CRM Project docker-compose.yml (BASE):

```yaml
# docker-compose.yml (base config - kõigile ühine)
services:
  # ==========================================================================
  # CRM Frontend (Tomcat WAR)
  # ==========================================================================
  crm-frontend:
    image: crm-frontend:${VERSION:-1.0}
    container_name: crm-frontend
    restart: unless-stopped
    environment:
      BACKEND_URL: http://crm-backend:8080
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILE:-prod}
      JAVA_OPTS: "-Xmx512m -Xms256m"
    networks:
      - crm-network
    depends_on:
      crm-backend:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8080/"]
      interval: 30s
      timeout: 5s
      retries: 3

  # ==========================================================================
  # CRM Backend (Spring Boot JAR)
  # ==========================================================================
  crm-backend:
    image: crm-backend:${VERSION:-1.0}
    container_name: crm-backend
    restart: unless-stopped
    environment:
      # Database (shared legacy DB)
      SPRING_DATASOURCE_URL: ${CRM_DB_URL}
      SPRING_DATASOURCE_USERNAME: ${CRM_DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${CRM_DB_PASSWORD}

      # JWT Secret (shared across services)
      JWT_SECRET: ${JWT_SECRET}

      # Spring Profile
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILE:-prod}
    networks:
      - crm-network
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s

  # ==========================================================================
  # CRM Reports (Spring Boot JAR)
  # ==========================================================================
  crm-reports:
    image: crm-reports:${VERSION:-1.0}
    container_name: crm-reports
    restart: unless-stopped
    environment:
      BACKEND_URL: http://crm-backend:8080
      SPRING_DATASOURCE_URL: ${CRM_DB_URL}
      SPRING_DATASOURCE_USERNAME: ${CRM_DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${CRM_DB_PASSWORD}
    networks:
      - crm-network
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  crm-network:
    driver: bridge
```

---

#### docker-compose.test.yml (TEST overrides):

```yaml
# docker-compose.test.yml (TEST environment overrides)
services:
  crm-frontend:
    ports:
      - "127.0.0.1:8080:8080"  # Debug access (localhost only)
    environment:
      LOG_LEVEL: DEBUG
      SPRING_PROFILES_ACTIVE: test

  crm-backend:
    ports:
      - "127.0.0.1:8081:8080"  # API debug access
      - "127.0.0.1:5005:5005"  # Java remote debug port (IntelliJ IDEA)
    environment:
      JAVA_OPTS: "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
      LOG_LEVEL: DEBUG
      SPRING_PROFILES_ACTIVE: test

  crm-reports:
    ports:
      - "127.0.0.1:8082:8080"
    environment:
      LOG_LEVEL: DEBUG
```

---

#### docker-compose.prod.yml (PRODUCTION overrides):

```yaml
# docker-compose.prod.yml (PRODUCTION environment overrides)
services:
  crm-frontend:
    deploy:
      replicas: 2  # High Availability
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    restart: always  # Auto-restart on failure

  crm-backend:
    deploy:
      replicas: 3  # 3 backend instances (load balance)
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '1.0'
          memory: 512M
    restart: always
    environment:
      JAVA_OPTS: "-Xmx768m -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
      LOG_LEVEL: WARN
      SPRING_PROFILES_ACTIVE: prod

  crm-reports:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
    restart: always
    environment:
      LOG_LEVEL: WARN
```

---

#### .env.test (test secrets):

```bash
# .env.test (TEST environment secrets)
# Loo: cp .env.test.example .env.test

# Database Connection (shared legacy DB server)
CRM_DB_URL=jdbc:postgresql://test-db.internal:5432/crm_test
CRM_DB_USER=testuser
CRM_DB_PASSWORD=test123

# JWT Secret (lihtne test jaoks)
JWT_SECRET=test-jwt-secret-not-for-prod

# Spring Profile
SPRING_PROFILE=test

# Version
VERSION=latest  # TEST: alati latest build
```

---

#### .env.prod (production secrets):

```bash
# .env.prod (PRODUCTION environment secrets)
# Loo: cp .env.prod.example .env.prod

# Database Connection (shared legacy DB server)
CRM_DB_URL=jdbc:postgresql://prod-db.internal:5432/crm_prod
CRM_DB_USER=crmuser
CRM_DB_PASSWORD=<STRONG-PASSWORD-48-BYTES>  # GENEREERI: openssl rand -base64 48

# JWT Secret (ühine kõikidele teenustele)
JWT_SECRET=<STRONG-JWT-SECRET-32-BYTES>  # GENEREERI: openssl rand -base64 32

# Spring Profile
SPRING_PROFILE=prod

# Version (production: specific version, NOT latest!)
VERSION=1.5.2
```

**Genereeri paroolid:**

```bash
# PostgreSQL parool
openssl rand -base64 48

# JWT Secret
openssl rand -base64 32
```

---

### 3.3. Deploy Strategy

#### Test Server:

```bash
# Server A (test.company.com)
cd /opt/crm

# Käivita TEST config'iga
docker-compose -f docker-compose.yml \
               -f docker-compose.test.yml \
               --env-file .env.test up -d

# Kontrolli
docker-compose ps
# crm-frontend    Up      127.0.0.1:8080->8080/tcp
# crm-backend     Up      127.0.0.1:8081->8080/tcp, 127.0.0.1:5005->5005/tcp
# crm-reports     Up      127.0.0.1:8082->8080/tcp

# Logs
docker-compose logs -f
```

---

#### Production Server (3 apps × 2-3 replicas = 8 containers):

```bash
# Server C (prod.company.com)
cd /opt/crm

# Käivita PRODUCTION config'iga
docker-compose -f docker-compose.yml \
               -f docker-compose.prod.yml \
               --env-file .env.prod up -d

# Kontrolli
docker-compose ps
# crm-frontend    Up (2 replicas)
# crm-backend     Up (3 replicas)
# crm-reports     Up (1 replica)

# Total: 6 containers

# Stats (resource usage)
docker stats

# Rolling update (ZERO DOWNTIME)
docker-compose -f docker-compose.yml \
               -f docker-compose.prod.yml \
               --env-file .env.prod \
               up -d --no-deps --build crm-backend

# Rollback (kui midagi on valesti)
VERSION=1.5.1 docker-compose -f docker-compose.yml \
                              -f docker-compose.prod.yml \
                              --env-file .env.prod \
                              up -d crm-backend
```

---

### 3.4. Tulemus (Etapp 2 - 6 kuud)

**Saavutused:**
- ✅ Kõik 15 rakendust Docker Compose'is (5 projektis)
- ✅ Multi-environment pattern (test, prelive, prod)
- ✅ Deploy: 5 min per project (oli 60 min!)
- ✅ Zero downtime (rolling restart)
- ✅ Identical config across environments (.env failid)

**Metriikat:**

| Metric | Legacy | Docker Compose |
|--------|--------|----------------|
| Rakendusi kokku | 15 | 15 |
| Projektid | 15 (eraldi) | 5 (grupeeritud) |
| Deploy aeg (1 app) | 30-60 min | 5 min |
| Deploy aeg (kõik 15) | 7.5h | 25 min |
| Downtime | 10 min per app | 0 min |
| Konfiguratsioon | Manual XML (iga server) | `.env` failid (3 faili) |
| Rollback | 30 min (manual) | 30 sek (VERSION=old) |

---

## 4. Etapp 2B: Production (Compose) - 12-18 kuud

**Eesmärk:** Jääge Docker Compose'i juurde ja tehke stabiilseks. **See on OK!**

### 4.1. Production Topology

```
Server A (test.company.com):
├─ Project 1: CRM (docker-compose -f ... -f docker-compose.test.yml)
├─ Project 2: ERP (docker-compose -f ... -f docker-compose.test.yml)
├─ Project 3: Analytics (docker-compose -f ... -f docker-compose.test.yml)
├─ Project 4: Portal (docker-compose -f ... -f docker-compose.test.yml)
└─ Project 5: Tools (docker-compose -f ... -f docker-compose.test.yml)

Server B (prelive.company.com):
└─ Same 5 projects (docker-compose.prelive.yml + .env.prelive)

Server C (prod.company.com):
└─ Same 5 projects (docker-compose.prod.yml + .env.prod + 2-3 replicas)
```

**Konfid:**

```bash
# Git Repo (infra as code)
/opt/
├── crm/
│   ├── docker-compose.yml          # BASE
│   ├── docker-compose.test.yml     # TEST override
│   ├── docker-compose.prod.yml     # PROD override
│   ├── .env.test                   # TEST secrets (not in git!)
│   └── .env.prod                   # PROD secrets (not in git!)
├── erp/
│   ├── docker-compose.yml
│   ├── docker-compose.test.yml
│   ├── docker-compose.prod.yml
│   ├── .env.test
│   └── .env.prod
└── ... (analytics, portal, tools)
```

---

### 4.2. Monitoring & Logging

#### Prometheus + Grafana (lisatud igale projektile):

**docker-compose.prod.yml (monitoring):**

```yaml
# docker-compose.prod.yml (monitoring komponendid)
services:
  # ... existing services ...

  # ==========================================================================
  # Prometheus (Metrics Collection)
  # ==========================================================================
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: prometheus
    restart: always
    ports:
      - "127.0.0.1:9090:9090"  # Ainult localhost (ei avalik)
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    networks:
      - crm-network
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=${PROMETHEUS_RETENTION:-90d}'

  # ==========================================================================
  # Grafana (Metrics Visualization)
  # ==========================================================================
  grafana:
    image: grafana/grafana:10.2.0
    container_name: grafana
    restart: always
    ports:
      - "127.0.0.1:3000:3000"  # Dashboard (localhost ainult)
    environment:
      GF_SECURITY_ADMIN_USER: ${GRAFANA_USER:-admin}
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
      GF_INSTALL_PLUGINS: grafana-piechart-panel
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - crm-network

volumes:
  prometheus-data:
  grafana-data:
```

**prometheus.yml (scrape config):**

```yaml
# prometheus.yml
global:
  scrape_interval: 30s

scrape_configs:
  # CRM Backend (Spring Boot Actuator metrics)
  - job_name: 'crm-backend'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['crm-backend:8080']

  # CRM Frontend
  - job_name: 'crm-frontend'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['crm-frontend:8080']
```

---

### 4.3. CI/CD Pipeline (Jenkins)

**Jenkinsfile (CRM project):**

```groovy
pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'your-registry.com'
        APP_NAME = 'crm-backend'
        VERSION = "${BUILD_NUMBER}"
    }

    stages {
        stage('Build') {
            steps {
                echo 'Building Gradle project...'
                sh './gradlew clean bootJar'
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh """
                    docker build -t ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} .
                    docker tag ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION} ${DOCKER_REGISTRY}/${APP_NAME}:latest
                """
            }
        }

        stage('Push to Registry') {
            steps {
                echo 'Pushing to Docker registry...'
                sh """
                    docker push ${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}
                    docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
                """
            }
        }

        stage('Deploy to Test') {
            steps {
                echo 'Deploying to test server...'
                sshagent(['test-server']) {
                    sh '''
                        ssh user@test.company.com "
                            cd /opt/crm &&
                            docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test pull crm-backend &&
                            docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test up -d --no-deps crm-backend
                        "
                    '''
                }
            }
        }

        stage('Health Check (Test)') {
            steps {
                echo 'Checking health...'
                sh '''
                    sleep 30
                    curl -f http://test.company.com:8081/actuator/health || exit 1
                '''
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                echo 'Deploying to production server...'
                sshagent(['prod-server']) {
                    sh '''
                        ssh user@prod.company.com "
                            cd /opt/crm &&
                            VERSION=${VERSION} docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d --no-deps crm-backend
                        "
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
```

---

### 4.4. Tulemus (Etapp 2B - 12-18 kuud)

**Saavutused:**
- ✅ Production stable (15 apps, 5 projects, 12-18 kuud)
- ✅ Deploy: Automated (Jenkins → Docker Compose)
- ✅ Monitoring: Prometheus + Grafana
- ✅ Logging: Centralized (Loki optional)
- ✅ High Availability: 2-3 replicas per app
- ✅ Zero downtime deployments

**Metriikat:**

| Metric | Legacy | Etapp 2B (Compose) |
|--------|--------|--------------------|
| Uptime | 99.0% (10 min/app downtime) | 99.9% (0 min downtime) |
| Deploy frequency | Kord kuus (risk!) | Kord nädalas (safe!) |
| Rollback aeg | 30 min (manual) | 30 sek (VERSION=old) |
| Mean Time To Recovery | 30 min | 2 min |
| Serverid | 15 (1 per app) | 3 (test, prelive, prod) |

**💡 Võtmepunkt:** Paljud ettevõtted jäävad **Etapp 2B** juurde ja see on OK! Ei vaja Kubernetes'i kui:
- ✅ 15 rakendust on stabiilne (mitte 100+)
- ✅ 3 serverit on piisav (test, prelive, prod)
- ✅ Manual scaling töötab (2-3 replicas per app)
- ✅ 99.9% uptime on OK (mitte 99.99%)

---

## 5. Etapp 3: Kubernetes (Valikuline)

**⚠️ HOIATUS: Minge Kubernetes'ele AINULT kui:**

### 5.1. Signaalid Migratsiooniks

**✅ Jah, minge Kubernetes'ele kui:**

| Signaal | Kirjeldus | Näide |
|---------|-----------|-------|
| **Scale** | 15 → 30+ rakendust | Kasvate 2x aastas |
| **Serverid** | 3 → 10+ serverit | Multi-region (EU, US, APAC) |
| **Traffic** | Manual scaling ei jõua | Black Friday = 10x traffic spike |
| **Uptime** | 99.9% → 99.99% (4 min/year) | Fintech, Healthcare |
| **Auto-scaling** | Vajad HPA (Horizontal Pod Autoscaler) | Traffic-based scaling |
| **Multi-region** | Disaster Recovery (DR) | Geo-redundancy |

---

**❌ EI, jääge Docker Compose'i juurde kui:**

| Signaal | Kirjeldus | Põhjus |
|---------|-----------|--------|
| **Rakendusi** | 15 apps on stabiilne | Compose on piisav |
| **Serverid** | 3 serverit on piisav | Ei vaja K8s complexity |
| **Traffic** | Manual scaling (2-3 replicas) töötab | Lihtne skaleerida |
| **Uptime** | 99.5-99.9% on OK | Paar tundi aastas downtime OK |
| **Team** | DevOps team < 3 inimest | K8s on liiga keeruline |
| **Eelarve** | Ei ole K8s infrastruktuuri budjetti | AWS EKS = $$$, self-hosted = complexity |

**💡 Võtmepunkt:** Kubernetes ei ole "upgrade" - see on erinevate probleemide lahendus (scale, multi-region, auto-scaling). Kui teil neid probleeme pole, ärge minge K8s'i!

---

### 5.2. Migration Path (kui otsustate)

#### Docker Compose → Kubernetes Manifest

**Enne (docker-compose.yml):**

```yaml
services:
  crm-backend:
    image: crm-backend:1.0
    deploy:
      replicas: 3
    environment:
      SPRING_DATASOURCE_URL: ${DB_URL}
      SPRING_DATASOURCE_USERNAME: ${DB_USER}
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
    ports:
      - "8080:8080"
    networks:
      - crm-network
```

↓ **converts to** ↓

**Pärast (Kubernetes Deployment):**

```yaml
# deployment.yaml (Kubernetes)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crm-backend
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: crm-backend
  template:
    metadata:
      labels:
        app: crm-backend
    spec:
      containers:
      - name: crm-backend
        image: crm-backend:1.0
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          valueFrom:
            secretKeyRef:
              name: crm-secrets
              key: db-url
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: crm-secrets
              key: db-username
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: crm-secrets
              key: db-password
        resources:
          limits:
            cpu: "2.0"
            memory: "1Gi"
          requests:
            cpu: "1.0"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5

---
# service.yaml (Kubernetes Service)
apiVersion: v1
kind: Service
metadata:
  name: crm-backend
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: crm-backend
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP

---
# secret.yaml (Kubernetes Secret)
apiVersion: v1
kind: Secret
metadata:
  name: crm-secrets
  namespace: production
type: Opaque
stringData:
  db-url: "jdbc:postgresql://prod-db.internal:5432/crm_prod"
  db-username: "crmuser"
  db-password: "<base64-encoded-password>"
```

**Deployment:**

```bash
# Apply manifests
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f secret.yaml

# Check status
kubectl get pods -n production
# crm-backend-abc123   1/1   Running   0   2m
# crm-backend-def456   1/1   Running   0   2m
# crm-backend-ghi789   1/1   Running   0   2m

# Logs
kubectl logs -f crm-backend-abc123 -n production

# Scale (auto vai manual)
kubectl scale deployment crm-backend --replicas=5 -n production
```

---

### 5.3. Tulemus (Etapp 3 - Kubernetes)

**Saavutused:**
- ✅ Auto-scaling (HPA: CPU/memory based)
- ✅ Multi-cluster (DR, multi-region: EU, US, APAC)
- ✅ Advanced networking (Service Mesh: Istio, Linkerd)
- ✅ Zero-downtime deployments (rolling updates, blue-green, canary)
- ✅ Self-healing (auto-restart failed pods)
- ✅ Advanced monitoring (Prometheus Operator, Grafana)

**Metriikat:**

| Metric | Docker Compose | Kubernetes |
|--------|----------------|------------|
| Uptime | 99.9% | 99.99% (4 min/year) |
| Auto-scaling | ❌ Ei | ✅ HPA (traffic-based) |
| Multi-region | ❌ Ei | ✅ Jah (DR, geo) |
| Complexity | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Team size | 1-2 DevOps | 3-5 DevOps + K8s expert |
| Cost | $$ | $$$$ (AWS EKS) |

---

## 6. Kokkuvõte

| Etapp | Aeg | Rakendused | Deploy Aeg | Downtime | Uptime | Keerukus | Soovitus |
|-------|-----|------------|------------|----------|--------|----------|----------|
| **Legacy (Tomcat)** | - | 15 | 60 min | 10 min | 99.0% | ⭐⭐ | Migrate! |
| **Etapp 1 (Piloot)** | 3 kuud | 2/15 | 5 min | 0 min | 99.5% | ⭐⭐⭐ | Alusta siit |
| **Etapp 2 (Compose)** | 6 kuud | 15/15 | 5 min | 0 min | 99.9% | ⭐⭐⭐⭐ | Kõik jõuavad siia |
| **Etapp 2B (Prod Compose)** | 12-18 kuud | 15 | 3 min | 0 min | 99.9% | ⭐⭐⭐⭐ | **Jääge siia!** ✅ |
| **Etapp 3 (Kubernetes)** | Valikuline | 30+ | 2 min | 0 min | 99.99% | ⭐⭐⭐⭐⭐ | Ainult kui scale vajab |

---

## 💡 Võtmepunktid

### 1. Paljud ettevõtted jäävad Etapp 2B juurde - **SEE ON OK!**

**Etapp 2B (Production Compose) on stabiilne ja piisav, kui:**
- ✅ 15-20 rakendust (mitte 100+)
- ✅ 3-5 serverit (test, prelive, prod)
- ✅ Manual scaling töötab (2-3 replicas per app)
- ✅ 99.9% uptime on OK (paar tundi aastas downtime)
- ✅ Single region (ei vaja multi-region DR)

**Võrdlus:**

| Aspekt | Docker Compose (Etapp 2B) | Kubernetes (Etapp 3) |
|--------|---------------------------|----------------------|
| **Rakendusi** | 15-20 (piisav) | 30-100+ (scale!) |
| **Uptime** | 99.9% (8h/year) | 99.99% (1h/year) |
| **Complexity** | ⭐⭐⭐⭐ (hallatav) | ⭐⭐⭐⭐⭐ (keeruline!) |
| **Team** | 1-2 DevOps | 3-5 DevOps + K8s expert |
| **Cost** | $$ (3 serverit) | $$$$ (AWS EKS cluster) |
| **Deploy** | 3 min | 2 min |

**💰 Cost näide (AWS):**
- Docker Compose: 3 × EC2 t3.large ($0.08/h × 3 × 730h) = **$175/month**
- Kubernetes (EKS): Control plane $73 + 3 nodes ($175) + ELB ($25) = **$273/month** (+ complexity!)

---

### 2. Kubernetes ei ole "upgrade" - see on erinevate probleemide lahendus

**Kubernetes lahendab:**
- ✅ Auto-scaling (HPA - traffic-based)
- ✅ Multi-region DR (geo-redundancy)
- ✅ Advanced networking (Service Mesh)
- ✅ 99.99% uptime (self-healing)

**Kubernetes EI lahenda:**
- ❌ Liiga aeglast deploymenti (Compose on juba kiire - 3 min!)
- ❌ Liiga keerulisi konfiguratsioon (Compose on lihtne!)
- ❌ Väikese scale probleeme (15 apps = Compose OK!)

**Eespool mainitud eeldused kehtivad uue võtmepunkt:**

**ÄRA mine Kubernetes'ele ainult sellepärast, et "kõik teised kasutavad seda"!**

---

### 3. Migration Timeline (Realistlik)

**Optimaalne tempo:**

```
Aasta 1 (Kuu 0-12):
├─ Q1 (Kuu 1-3): Piloot (2 apps Docker'isse)
├─ Q2 (Kuu 4-6): Täielik migration (15 apps Compose'i)
├─ Q3-Q4 (Kuu 7-12): Stabiliseerimine (monitoring, CI/CD, training)

Aasta 2 (Kuu 13-24):
└─ Production Compose (Etapp 2B) - optimiseerimine, tuning, protsesside täiustamine

Aasta 3+:
└─ VALIKULINE: Kubernetes (ainult kui scale sunnib)
```

**Ära kiirusta:**
- ❌ "Migreerime kõik 15 apps 1 kuuga!" → **Ei tööta! Bugs, downtime, stress!**
- ✅ "2 apps pilootprojektina, siis järk-järgult 15 apps" → **Töötab! Safe, õppimine!**

---

### 4. Training ja Dokumentatsioon

**Vajalikud oskused:**

| Etapp | Vajalikud oskused | Koolitus |
|-------|-------------------|----------|
| **Etapp 1 (Piloot)** | Docker basics, Dockerfile, Gradle | 2 päeva Docker workshop |
| **Etapp 2 (Compose)** | Docker Compose, multi-env patterns, .env | 3 päeva Compose training |
| **Etapp 2B (Prod)** | Monitoring (Prometheus), CI/CD (Jenkins), troubleshooting | 5 päeva advanced training |
| **Etapp 3 (K8s)** | Kubernetes basics, Deployments, Services, Secrets, HPA, Ingress | 10 päeva K8s bootcamp |

**Dokumentatsioon:**
- ✅ README.md: Deployment juhised (test vs prod)
- ✅ TROUBLESHOOTING.md: Common issues ja lahendused
- ✅ RUNBOOKS.md: Production ops juhised

---

## 📚 Viited ja Ressursid

### Hands-on Labs:
- **Lab 1:** Docker Basics (4h) - Konteinerise rakendused
- **Lab 2:** Docker Compose (5h) - Orkestreerimise ja multi-environment
- **Lab 3:** Kubernetes Basics (5h) - Pods, Deployments, Services
- **Lab 8:** GitOps with ArgoCD (5h) - Automated K8s deployments

### Dokumendid:
- [Peatükk 05: Docker Põhimõtted](../../resource/05-Docker-Pohimotted.md)
- [Peatükk 06: Dockerfile Detailid](../../resource/06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md)
- [Peatükk 06A: Java/Spring Boot Konteineriseerimise Spetsiifika](../../resource/06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md)
- [Peatükk 08A: Production vs Development Seadistused](../../resource/08A-Docker-Compose-Production-Development-Seadistused.md)

### External Resources:
- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Spring Boot Docker](https://spring.io/guides/topicals/spring-boot-docker/)
- [Docker Compose Override](https://docs.docker.com/compose/extends/)
- [Gradle Docker Plugin](https://github.com/palantir/gradle-docker)

---

**Viimane uuendus:** 2025-12-12
**Autor:** DevOps Koolituskava
**Sihtrühm:** Legacy Tomcat/Gradle → Docker → (Kubernetes?)
**Märksõnad:** Tomcat, Gradle, Spring Boot, Docker, Compose, Kubernetes, Migration, Roadmap
