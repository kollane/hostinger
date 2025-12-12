# Spring Boot External Properties Files - Tehnilised Selgitused

**Autor:** Claude Code
**Kuupäev:** 2025-12-11
**Kontekst:** Lab 2 Harjutus 4 (Environment Management) täiendav materjal
**Sihtrühm:** DevOps õppijad, kes vajavad selgitust external properties failide kasutamisest

---

## 📋 Ülevaade

See dokument selgitab, **kuidas kasutada external properties faile Spring Boot rakenduses** ja **kuidas need override'ivad JAR siseseid väärtusi**:
- `.properties` vs `.yml` failid
- External config files (JAR'ist väljaspool)
- Spring Boot config location strategies
- Docker Compose integration
- Hybrid approach (YAML + properties + env vars)

---

## 🔄 Spring Boot Properties Failide Hierarhia

### Täielik Prioriteetide Järjekord (kõrgeim võidab):

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Command line arguments                                    │
│    java -jar app.jar --server.port=8081                     │
│    KÕRGEIM PRIORITEET                                        │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Java System properties                                   │
│    java -Dserver.port=8081 -jar app.jar                     │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. OS environment variables                                 │
│    export SERVER_PORT=8081                                  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. External config files (väljaspool JAR'i)                 │
│    ./config/application.properties                          │
│    ./application.properties                                 │
│    /etc/app/application.properties                          │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Internal config files (JAR sees)                         │
│    src/main/resources/application.properties                │
│    src/main/resources/application.yml                       │
│    MADALAIM PRIORITEET                                       │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Properties vs YAML

### application.properties

**Formaat:** Key-value pairs (flat structure)

```properties
# Server configuration
server.port=8080
server.servlet.context-path=/api

# Database configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/mydb
spring.datasource.username=dbuser
spring.datasource.password=changeme
spring.datasource.driver-class-name=org.postgresql.Driver

# JPA configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false

# JWT configuration
jwt.secret=my-secret-key
jwt.expiration=86400000

# Business configuration
app.business.max-todos-per-user=100
app.business.allow-public-registration=true
app.business.trial-period-days=14

# Feature flags
app.features.email-notifications=true
app.features.todo-sharing=false
app.features.analytics=false

# Logging
logging.level.root=INFO
logging.level.com.example.todoservice=DEBUG
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n
```

**Plussid:**
- ✅ Lihtne formaat
- ✅ Vähem ridu (compact)
- ✅ Lihtne override'ida (kopeeri-kleebi)
- ✅ Vanemad DevOps inimesed tunnevad

**Miinused:**
- ❌ Raskem lugeda (kõik flat)
- ❌ Korduvad prefiksid (spring.datasource.x)
- ❌ Puudub struktuur
- ❌ Raskem kommenteerida

---

### application.yml

**Formaat:** Hierarchical structure (YAML)

```yaml
# Server configuration
server:
  port: 8080
  servlet:
    context-path: /api

# Database configuration
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb
    username: dbuser
    password: changeme
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false

# JWT configuration
jwt:
  secret: my-secret-key
  expiration: 86400000

# Business configuration
app:
  business:
    max-todos-per-user: 100
    allow-public-registration: true
    trial-period-days: 14

  features:
    email-notifications: true
    todo-sharing: false
    analytics: false

# Logging
logging:
  level:
    root: INFO
    com.example.todoservice: DEBUG
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
```

**Plussid:**
- ✅ Struktureeritud, loetav
- ✅ Hierarhia nähtav
- ✅ Lihtne kommenteerida
- ✅ Vähem korduvaid prefikseid

**Miinused:**
- ❌ Indentation-sensitive (YAML quirks)
- ❌ Rohkem ridu
- ❌ Mõnikord keerulisem override'ida

---

### Mõlemad Koos?

**Jah, Spring Boot loeb MÕLEMAD!**

Kui mõlemad on olemas:
1. Spring Boot loeb `application.yml`
2. Spring Boot loeb `application.properties`
3. Kui **sama property** on mõlemas → **`.properties` võidab**!

**Näide:**

**application.yml:**
```yaml
server:
  port: 8080
app:
  business:
    max-todos-per-user: 100
```

**application.properties:**
```properties
server.port=8081
```

**Tulemus:**
- `server.port` = **8081** (properties võitis)
- `app.business.max-todos-per-user` = **100** (ainult yml's)

---

## 📂 External Properties Files

### 1. Auto-Discovery (JAR Kõrval)

**Spring Boot otsib automaatselt:**

```
/opt/app/
├── todo-service.jar
├── application.properties      ← Auto-discovery #1
├── application.yml              ← Auto-discovery #2
└── config/
    ├── application.properties   ← Auto-discovery #3 (kõrgeim!)
    └── application.yml          ← Auto-discovery #4
```

**Prioriteedid (kõrgeim võidab):**
1. `./config/application.properties`
2. `./config/application.yml`
3. `./application.properties`
4. `./application.yml`
5. JAR sisesed failid (madalaim)

**Kasutamine:**
```bash
cd /opt/app
java -jar todo-service.jar
# Spring Boot leiab automaatselt external failid!
```

---

### 2. Custom Config Location

**Määra täpselt, kust lugeda:**

#### Variant A: Üks Konkreetne Fail

```bash
java -jar todo-service.jar \
  --spring.config.location=file:/etc/myapp/custom.properties
```

**⚠️ HOIATUS:** See **ASENDAB** kõik vaikeväärtused! Ainult see fail laetakse.

---

#### Variant B: Kataloog

```bash
java -jar todo-service.jar \
  --spring.config.location=file:/etc/myapp/
```

Spring Boot otsib sellest kataloogist:
- `application.properties`
- `application.yml`
- `application-{profile}.properties`
- `application-{profile}.yml`

---

#### Variant C: Mitu Asukohta

```bash
java -jar todo-service.jar \
  --spring.config.location=classpath:/,file:/etc/myapp/
```

**Selgitus:**
- `classpath:/` → JAR sisesed failid
- `file:/etc/myapp/` → External failid
- **Viimane võidab:** `/etc/myapp/` override'ib `classpath:/`

---

### 3. Additional Location (PARIM VARIANT!)

**Lisa external faile, SÄILITA JAR sisesed:**

```bash
java -jar todo-service.jar \
  --spring.config.additional-location=file:/etc/myapp/
```

**Mida see teeb:**
1. ✅ Loeb JAR sisesed failid (vaikeväärtused)
2. ✅ **LISAKS** loeb `/etc/myapp/` failid
3. ✅ External failid override'ivad JAR siseseid

**See on parim variant, sest:**
- JAR sisesed vaikeväärtused jäävad alles
- External failid override'ivad ainult neid, mis on seal määratud
- Ei pea kõike ümber defineerima

---

## 🐳 Docker Compose Integration

### Näide 1: Mount Single External File

**Struktuur:**
```
compose-project/
├── docker-compose.yml
└── config/
    └── application-prod.properties
```

**config/application-prod.properties:**
```properties
# Production overrides
server.port=8081
spring.datasource.url=jdbc:postgresql://postgres-prod:5432/prod_db
spring.datasource.password=ProductionPassword123!
spring.jpa.show-sql=false
logging.level.root=WARN
app.business.max-todos-per-user=50
```

**docker-compose.yml:**
```yaml
services:
  todo-service:
    image: todo-service:1.0-optimized
    volumes:
      # Mount external config file
      - ./config/application-prod.properties:/config/application.properties:ro
    command:
      - "java"
      - "-jar"
      - "/app/todo-service.jar"
      - "--spring.config.additional-location=file:/config/"
    # Või kasuta environment variable
    # environment:
    #   SPRING_CONFIG_ADDITIONAL_LOCATION: file:/config/
```

**Tulemus:**
- JAR sisesed `application.yml` laetakse (vaikeväärtused)
- External `application.properties` override'ib neid
- Ainult määratud properties override'itakse

---

### Näide 2: Multiple Config Files

**Struktuur:**
```
compose-project/
├── docker-compose.yml
└── config/
    ├── database.properties
    ├── security.properties
    └── business.properties
```

**config/database.properties:**
```properties
spring.datasource.url=jdbc:postgresql://postgres-prod:5432/prod_db
spring.datasource.username=dbuser
spring.datasource.password=SecurePassword123!
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
```

**config/security.properties:**
```properties
jwt.secret=production-jwt-secret-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
jwt.expiration=86400000
spring.security.oauth2.client.registration.google.client-id=xxx
spring.security.oauth2.client.registration.google.client-secret=xxx
```

**config/business.properties:**
```properties
app.business.max-todos-per-user=50
app.business.allow-public-registration=false
app.business.trial-period-days=7
app.features.todo-sharing=true
app.features.analytics=true
```

**docker-compose.yml:**
```yaml
services:
  todo-service:
    image: todo-service:1.0-optimized
    volumes:
      - ./config:/config:ro
    environment:
      SPRING_CONFIG_ADDITIONAL_LOCATION: file:/config/
```

**Tulemus:**
- Spring Boot loeb kõik `.properties` failid `/config/` kataloogist
- Kõik override'ivad JAR siseseid väärtusi
- Struktureeritud konfiguratsioon (database, security, business)

---

### Näide 3: Environment-Specific Configs

**Struktuur:**
```
compose-project/
├── docker-compose.yml
├── docker-compose.override.yml     # Development (auto-loaded)
├── docker-compose.prod.yml         # Production
└── config/
    ├── dev/
    │   └── application-dev.properties
    └── prod/
        ├── application-prod.properties
        └── secrets.properties
```

**docker-compose.yml (base):**
```yaml
services:
  todo-service:
    image: todo-service:1.0-optimized
    environment:
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILE:-prod}
```

**docker-compose.override.yml (development - auto-loaded):**
```yaml
services:
  todo-service:
    volumes:
      - ./config/dev:/config:ro
    environment:
      SPRING_CONFIG_ADDITIONAL_LOCATION: file:/config/
      SPRING_PROFILES_ACTIVE: dev
    ports:
      - "8081:8081"  # Expose for debugging
```

**docker-compose.prod.yml (production):**
```yaml
services:
  todo-service:
    volumes:
      - ./config/prod:/config:ro
    environment:
      SPRING_CONFIG_ADDITIONAL_LOCATION: file:/config/
      SPRING_PROFILES_ACTIVE: prod
    # No exposed ports (security)
```

**Käivitamine:**
```bash
# Development (auto-loads docker-compose.override.yml)
docker compose up

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up
```

---

### Näide 4: Secrets Separation

**Struktuur:**
```
compose-project/
├── docker-compose.yml
├── config/
│   └── application-prod.properties  # Non-sensitive (Git OK)
└── secrets/
    └── secrets.properties           # Sensitive (NEVER commit!)
```

**config/application-prod.properties (Git OK):**
```properties
# Non-sensitive production configs
server.port=8081
spring.jpa.show-sql=false
logging.level.root=WARN
app.business.max-todos-per-user=50
app.features.todo-sharing=true

# External endpoints (non-sensitive)
external.analytics-api.url=https://analytics.example.com/api
external.notification-service.url=https://notifications.example.com
```

**secrets/secrets.properties (NEVER commit!):**
```properties
# Database credentials
spring.datasource.url=jdbc:postgresql://prod-db.example.com:5432/prod_db
spring.datasource.password=SuperSecurePassword123!

# JWT secret
jwt.secret=a8f5f167f44f4964e6c998dee827110c3e51c9e5f3a7f0d8e2b4c9a1f5e8d7b3

# External API keys
external.analytics-api.api-key=prod-analytics-key-xxxxxxxxxxxxxxxx
external.notification-service.api-key=prod-notification-key-xxxxxxxxxxxx

# SMTP credentials
spring.mail.username=apikey
spring.mail.password=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**.gitignore:**
```gitignore
secrets/
*.secrets.properties
```

**docker-compose.yml:**
```yaml
services:
  todo-service:
    image: todo-service:1.0-optimized
    volumes:
      - ./config/application-prod.properties:/config/application.properties:ro
      - ./secrets/secrets.properties:/config/secrets.properties:ro
    environment:
      SPRING_CONFIG_ADDITIONAL_LOCATION: file:/config/
```

**Tulemus:**
- Non-sensitive configs Git'is (team collaboration)
- Secrets eraldi (local, production secrets management)
- Spring Boot loeb mõlemad

---

## 🔧 Hybrid Approach (PARIM PRAKTIKA!)

### Kombinatsioon: YAML + Properties + Env Vars

**1. JAR Sisesed: application.yml (Vaikeväärtused + Dokumentatsioon)**

```yaml
# src/main/resources/application.yml
# Well-documented defaults for all environments

server:
  port: ${SERVER_PORT:8080}  # Can be overridden

spring:
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/todo_db}
    username: ${DB_USERNAME:dbuser}
    password: ${DB_PASSWORD:changeme}
    hikari:
      maximum-pool-size: ${DB_POOL_SIZE:10}
      minimum-idle: ${DB_POOL_MIN:2}

jwt:
  secret: ${JWT_SECRET:default-secret-change-in-production}
  expiration: ${JWT_EXPIRATION_MS:86400000}

app:
  business:
    # Business rules with documentation
    max-todos-per-user: ${MAX_TODOS:100}
    allow-public-registration: ${ALLOW_REGISTRATION:true}
    trial-period-days: ${TRIAL_DAYS:14}

  features:
    email-notifications: ${FEATURE_EMAIL:true}
    todo-sharing: ${FEATURE_SHARING:false}
    analytics: ${FEATURE_ANALYTICS:false}
```

---

**2. External Properties: application-prod.properties (Environment-Specific)**

```properties
# config/application-prod.properties
# Production-specific configs (non-sensitive, can be in Git)

server.port=8081

# JPA settings
spring.jpa.show-sql=false
spring.jpa.hibernate.ddl-auto=validate

# Logging
logging.level.root=WARN
logging.level.com.example.todoservice=INFO

# Business rules (stricter in prod)
app.business.max-todos-per-user=50
app.business.allow-public-registration=false

# Features
app.features.todo-sharing=true
app.features.analytics=true

# External services
external.analytics-api.url=https://analytics.example.com/api
external.analytics-api.timeout-ms=3000
external.analytics-api.retry-attempts=2
```

---

**3. Environment Variables: .env (Secrets)**

```bash
# .env (NEVER commit to Git!)

# Database
DB_PASSWORD=SuperSecurePassword123!

# JWT
JWT_SECRET=a8f5f167f44f4964e6c998dee827110c3e51c9e5f3a7f0d8e2b4c9a1f5e8d7b3

# External API keys
ANALYTICS_API_KEY=prod-analytics-key-xxxxxxxxxxxxxxxx
NOTIFICATION_API_KEY=prod-notification-key-xxxxxxxxxxxx

# SMTP
SMTP_PASSWORD=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

**4. Docker Compose: Kombinatsioon**

```yaml
services:
  todo-service:
    image: todo-service:1.0-optimized
    volumes:
      # External properties (non-sensitive)
      - ./config/application-prod.properties:/config/application.properties:ro
    environment:
      # Config location
      SPRING_CONFIG_ADDITIONAL_LOCATION: file:/config/
      SPRING_PROFILES_ACTIVE: prod

      # Secrets from .env
      DB_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      ANALYTICS_API_KEY: ${ANALYTICS_API_KEY}
      NOTIFICATION_API_KEY: ${NOTIFICATION_API_KEY}
      SMTP_PASSWORD: ${SMTP_PASSWORD}

      # Optional runtime overrides
      MAX_TODOS: ${MAX_TODOS:-50}
```

**Tulemus:**
1. JAR sisesed YAML → Vaikeväärtused + dokumentatsioon
2. External properties → Environment-specific non-sensitive
3. Env vars → Secrets + runtime overrides
4. **Best of all worlds!** ✅

---

## 🎯 Millal Kasutada Mida?

### Properties vs YAML vs Env Vars

| Aspekt | application.yml | application.properties | Environment Variables |
|--------|----------------|----------------------|---------------------|
| **Loetavus** | ✅ Suurepärane (hierarchy) | ⚠️ OK (flat) | ⚠️ OK (key=value) |
| **Dokumentatsioon** | ✅ Lihtne kommenteerida | ✅ Kommentaarid OK | ❌ Kommentaare pole |
| **Versioonimine (Git)** | ✅ Soovitatav | ✅ OK | ❌ Secrets ei tohi |
| **Override Priority** | Madal | Keskmine | **Kõrgeim** |
| **Struktureeritud** | ✅ Hierarchy | ❌ Flat | ❌ Flat |
| **Secrets** | ❌ EI SOBI | ❌ EI SOBI | ✅ **Sobib** |
| **12-Factor App** | ⚠️ OK | ⚠️ OK | ✅ **Recommended** |
| **Docker/K8s** | ⚠️ Võimalik | ⚠️ Võimalik | ✅ **Native** |
| **External override** | ✅ Võimalik | ✅ **Lihtne** | ✅ **Kõige lihtsam** |

---

### Otsustamise Voog:

```
┌─────────────────────────────────────────┐
│ Mis tüüpi konfiguratsioon see on?       │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌──────────────┐  ┌─────────────────────────┐
│ Salajane?    │  │ Struktureeritud?        │
│ (password,   │  │ Palju nested properties?│
│  API key)    │  │                         │
└───┬──────────┘  └───────┬─────────────────┘
    │                     │
    │ JAH                 │ JAH
    ▼                     ▼
┌──────────────┐    ┌─────────────────┐
│ Environment  │    │ application.yml │
│ Variable     │    │ (JAR sees)      │
└──────────────┘    └─────────────────┘
    │                     │
    │ EI                  │ EI
    ▼                     ▼
┌──────────────────┐  ┌───────────────────────┐
│ Env-specific?    │  │ External override?    │
│ (dev vs prod)    │  │ (deploy-time change)  │
└────┬─────────────┘  └──────┬────────────────┘
     │ JAH                    │ JAH
     ▼                        ▼
┌─────────────────────┐  ┌────────────────────────┐
│ application-        │  │ application.properties │
│ {profile}.yml       │  │ (external)             │
│ või .properties     │  │                        │
└─────────────────────┘  └────────────────────────┘
```

---

## 📚 Praktilised Näited

### Näide 1: Lihtne Web App (ainult YAML)

**Sobib kui:**
- Väike projekt
- Vähe konfiguratsiooniridu
- Kõik non-sensitive

**Struktuur:**
```
src/main/resources/
├── application.yml              # Defaults
├── application-dev.yml          # Dev overrides
└── application-prod.yml         # Prod overrides
```

**Docker Compose:**
```yaml
services:
  webapp:
    image: webapp:1.0
    environment:
      SPRING_PROFILES_ACTIVE: prod
      DB_PASSWORD: ${DB_PASSWORD}  # Ainult secrets env vars
      JWT_SECRET: ${JWT_SECRET}
```

---

### Näide 2: Enterprise App (YAML + Properties)

**Sobib kui:**
- Suur projekt
- Palju konfiguratsiooniridu
- Eraldi secrets management

**Struktuur:**
```
src/main/resources/
├── application.yml              # Defaults (Git)
├── application-dev.yml          # Dev (Git)
└── application-prod.yml         # Prod defaults (Git)

/opt/app/config/                 # External
├── application-prod.properties  # Prod overrides (Git OK)
└── secrets.properties           # Secrets (NEVER Git!)
```

**Docker Compose:**
```yaml
services:
  app:
    image: app:1.0
    volumes:
      - ./config:/config:ro
    environment:
      SPRING_CONFIG_ADDITIONAL_LOCATION: file:/config/
      SPRING_PROFILES_ACTIVE: prod
```

---

### Näide 3: Multi-Tenant SaaS (Properties per Customer)

**Sobib kui:**
- Multi-tenant
- Iga customer erinev konfiguratsioon

**Struktuur:**
```
/opt/app/
├── app.jar
└── customers/
    ├── customer-a.properties
    ├── customer-b.properties
    └── customer-c.properties
```

**Käivitamine:**
```bash
# Customer A
java -jar app.jar \
  --spring.config.additional-location=file:./customers/customer-a.properties \
  --tenant=customer-a

# Customer B
java -jar app.jar \
  --spring.config.additional-location=file:./customers/customer-b.properties \
  --tenant=customer-b
```

---

## ✅ Best Practices Checklist

### Configuration Management:

- [ ] **JAR sisesed YAML failid** sisaldavad vaikeväärtusi ja dokumentatsiooni
- [ ] **Profile-specific failid** (`-dev`, `-prod`) sisaldavad environment defaults
- [ ] **External properties** sisaldavad non-sensitive environment overrides
- [ ] **Environment variables** sisaldavad ainult secrets ja runtime configs
- [ ] **Secrets ei ole Git'is** (.gitignore lisatud)
- [ ] **Kommentaarid olemas** (mis on override'itav, mis mitte)
- [ ] **${VAR:default}** syntax kasutatud (flexibility + safety)
- [ ] **External config location dokumenteeritud** (README)

### Docker Compose:

- [ ] **Mount config files read-only** (`:ro`)
- [ ] **Use additional-location** (säilitab JAR sisesed defaults)
- [ ] **Secrets eraldi failides** (mitte properties'tes)
- [ ] **.env fail .gitignore's** (secrets protection)
- [ ] **.env.example loodud** (template teammates'idele)

---

## 🔗 Seotud Materjalid

- **Spring Boot Configuration Management:** `./Spring-Boot-Configuration-Management.md`
- **Lab 2 Harjutus 4:** Environment Management
- **Spring Boot Docs:** https://docs.spring.io/spring-boot/reference/features/external-config.html
- **12-Factor App Config:** https://12factor.net/config

---

## 📋 Kiire Võrdlus

| Feature | YAML Only | Properties Only | Hybrid (YAML+Props+Env) |
|---------|-----------|----------------|------------------------|
| **Loetavus** | ✅ Excellent | ⚠️ OK | ✅ Excellent |
| **Flexibility** | ⚠️ Limited | ✅ Good | ✅ **Best** |
| **Secrets Safety** | ❌ Poor | ❌ Poor | ✅ **Best** |
| **Override Easy** | ⚠️ OK | ✅ Good | ✅ **Best** |
| **Documentation** | ✅ Excellent | ✅ Good | ✅ **Best** |
| **12-Factor** | ⚠️ Partial | ⚠️ Partial | ✅ **Full** |
| **Maintenance** | ✅ Easy | ✅ Easy | ⚠️ More complex |
| **Team Collab** | ✅ Good | ✅ Good | ✅ **Best** |

**Soovitus:** Kasuta **Hybrid** lähenemist suurtes projektides! 🎯

---

**Viimane uuendus:** 2025-12-11
**Staatus:** Täiendav tehniline selgitus Lab 2 harjutustele
**Seos:** Täiendab `Spring-Boot-Configuration-Management.md`
