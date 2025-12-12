# Spring Boot Configuration Management - Tehnilised Selgitused

**Autor:** Claude Code
**Kuupäev:** 2025-12-11
**Kontekst:** Lab 2 Harjutus 4 (Environment Management) täiendav materjal
**Sihtrühm:** DevOps õppijad, kes vajavad selgitust, kuhu panna erinevat tüüpi konfiguratsioonid

---

## 📋 Ülevaade

See dokument selgitab, **kuidas Spring Boot konfiguratsioonihierarhia töötab** ja **kuhu panna erinevat tüüpi seadistusi**:
- Infrastruktuuriseaded (DB, JWT)
- Ärilised konfiguratsioonid (max laenu summa, trial period)
- Integratsioonide seaded (SMTP, external API)
- Cron schedule'd
- Feature flags

---

## 🎯 Spring Boot Konfiguratsioonihierarhia

Spring Boot loeb konfiguratsiooni **prioriteedi järjekorras** (kõrgeim prioriteet võidab):

```
1. Environment variables (Docker Compose)    ← KÕRGEIM PRIORITEET
2. application-{profile}.yml                 ← Profile-specific
3. application.yml                           ← VAIKEVÄÄRTUSED
4. Koodis määratud vaikeväärtused           ← MADALAIM PRIORITEET
```

**Näide:**

Kui `application.yml` ütleb `server.port: 8080`, aga environment variable on `SERVER_PORT=8081`, siis Spring Boot kasutab **8081** (environment variable võidab).

---

## 📦 Konfiguratsioonitüübid

### 1️⃣ Infrastruktuur (Tech Config)
**Näited:** Database credentials, JWT secrets, encryption keys

**Asukoht:**
- Environment variables (.env + docker-compose.yml)
- Kubernetes Secrets (Lab 3+)

**Põhjus:**
- Sensitive (ei tohi Git'i panna)
- Environment-specific (dev vs prod erinevad)

---

### 2️⃣ Äriline Funktionaalsus (Business Config)
**Näited:** Max laenu summa, intressimäärad, teenustasud, trial period, max items per user

**Asukoht:**
- `application.yml` (vaikeväärtused)
- `application-{profile}.yml` (profile-specific overrides)
- Environment variables (kui kliendi-spetsiifiline või deploy-time muudetav)

**Põhjus:**
- Non-sensitive (võib Git'i panna)
- Äriloogika osa (peaks olema koodiga koos)
- Override'itav vajadusel (env vars)

---

### 3️⃣ Integratsioonid (External Services)
**Näited:** SMTP server, external API endpoints, cron schedule'd, timeouts, retry policies

**Asukoht:**
- `application.yml` (vaikeväärtused, dev endpoints)
- Environment variables (production endpoints, API keys, passwords)

**Põhjus:**
- Mixed: endpoints võivad olla public, aga credentials on secret
- Override'itav environment'ide vahel

---

## 📄 application.yml - Struktuuri Näide

```yaml
# apps/backend-java-spring/src/main/resources/application.yml
# ============================================================================
# VAIKEVÄÄRTUSED (Development)
# ============================================================================

server:
  port: ${SERVER_PORT:8080}

# ============================================================================
# Database (infrastructure)
# ============================================================================
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:postgresql://localhost:5432/todo_service_db}
    username: ${SPRING_DATASOURCE_USERNAME:dbuser}
    password: ${SPRING_DATASOURCE_PASSWORD:changeme}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: update  # Development: auto-create/update tables
    show-sql: false     # Don't show SQL in logs by default

  # ============================================================================
  # Email configuration (integration)
  # ============================================================================
  mail:
    host: ${SMTP_HOST:localhost}           # Development: MailHog
    port: ${SMTP_PORT:1025}
    username: ${SMTP_USERNAME:}            # Optional by default
    password: ${SMTP_PASSWORD:}
    properties:
      mail.smtp.auth: ${SMTP_AUTH:false}
      mail.smtp.starttls.enable: ${SMTP_STARTTLS:false}

# ============================================================================
# JWT (infrastructure - sensitive)
# ============================================================================
jwt:
  secret: ${JWT_SECRET:default-jwt-secret-change-in-production}
  expiration: ${JWT_EXPIRATION_MS:86400000}  # 24 hours in milliseconds

# ============================================================================
# Business logic configuration
# ============================================================================
app:
  business:
    max-todos-per-user: ${MAX_TODOS_PER_USER:100}
    allow-public-registration: ${ALLOW_PUBLIC_REGISTRATION:true}
    trial-period-days: ${TRIAL_PERIOD_DAYS:14}
    default-reminder-time: ${DEFAULT_REMINDER_TIME:09:00}

  features:
    email-notifications: ${FEATURE_EMAIL_NOTIFICATIONS:true}
    todo-sharing: ${FEATURE_TODO_SHARING:false}
    analytics: ${FEATURE_ANALYTICS:false}
    export-pdf: ${FEATURE_EXPORT_PDF:false}

  rate-limiting:
    requests-per-minute: ${RATE_LIMIT_RPM:60}
    burst-size: ${RATE_LIMIT_BURST:10}

# ============================================================================
# Cron schedules
# ============================================================================
scheduling:
  cron:
    # Cleanup old completed todos
    cleanup-old-todos: ${CRON_CLEANUP_TODOS:0 0 2 * * *}      # 2 AM daily

    # Send reminder emails
    send-reminders: ${CRON_SEND_REMINDERS:0 0 9 * * MON-FRI}  # 9 AM weekdays

    # Generate daily reports
    generate-reports: ${CRON_REPORTS:0 0 1 * * *}             # 1 AM daily

    # Database backup
    database-backup: ${CRON_DB_BACKUP:0 0 3 * * *}            # 3 AM daily

  enabled: ${SCHEDULING_ENABLED:true}

# ============================================================================
# External API integrations
# ============================================================================
external:
  analytics-api:
    url: ${ANALYTICS_API_URL:http://localhost:8080/api}
    api-key: ${ANALYTICS_API_KEY:dev-api-key}
    timeout-ms: ${ANALYTICS_TIMEOUT:5000}
    retry-attempts: ${ANALYTICS_RETRY:3}
    enabled: ${ANALYTICS_ENABLED:false}

  notification-service:
    url: ${NOTIFICATION_SERVICE_URL:http://localhost:8082}
    api-key: ${NOTIFICATION_API_KEY:dev-notification-key}
    enabled: ${NOTIFICATION_SERVICE_ENABLED:false}

  payment-gateway:
    url: ${PAYMENT_API_URL:http://localhost:8090}
    api-key: ${PAYMENT_API_KEY:dev-payment-key}
    timeout-ms: ${PAYMENT_TIMEOUT:10000}
    webhook-secret: ${PAYMENT_WEBHOOK_SECRET:dev-webhook-secret}

# ============================================================================
# Logging
# ============================================================================
logging:
  level:
    root: ${LOGGING_LEVEL_ROOT:INFO}
    com.example.todoservice: ${LOGGING_LEVEL_APP:DEBUG}
    org.springframework.web: ${LOGGING_LEVEL_SPRING_WEB:INFO}
    org.hibernate.SQL: ${LOGGING_LEVEL_SQL:DEBUG}
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
  file:
    name: ${LOG_FILE:logs/application.log}
    max-size: ${LOG_FILE_MAX_SIZE:10MB}
    max-history: ${LOG_FILE_MAX_HISTORY:30}
```

---

## 🔧 Profile-Specific Overrides

### application-dev.yml (Development)

```yaml
# apps/backend-java-spring/src/main/resources/application-dev.yml

spring:
  jpa:
    show-sql: true  # Show SQL queries in development

  mail:
    host: localhost
    port: 1025  # MailHog for local email testing

app:
  business:
    max-todos-per-user: 1000  # Higher limit for testing
    allow-public-registration: true  # Open registration in dev

  features:
    email-notifications: false  # Disable email sending in dev
    analytics: false            # Disable analytics in dev
    export-pdf: true            # Enable for testing

scheduling:
  cron:
    cleanup-old-todos: "0 */5 * * * *"    # Every 5 minutes (faster testing)
    send-reminders: "0 */10 * * * *"       # Every 10 minutes
    generate-reports: "0 */15 * * * *"     # Every 15 minutes
    database-backup: "0 0 * * * *"         # Every hour
  enabled: false  # Disable scheduled jobs in dev (or true if testing)

external:
  analytics-api:
    enabled: false  # Disable external calls in dev
  notification-service:
    enabled: false
  payment-gateway:
    url: http://localhost:8090  # Local mock server

logging:
  level:
    root: DEBUG
    com.example.todoservice: TRACE
    org.springframework.web: DEBUG
    org.hibernate.SQL: DEBUG
```

---

### application-prod.yml (Production)

```yaml
# apps/backend-java-spring/src/main/resources/application-prod.yml

spring:
  jpa:
    show-sql: false  # Don't log SQL in production
    hibernate:
      ddl-auto: validate  # Don't auto-modify schema in production

  mail:
    host: ${SMTP_HOST}  # Must be set via environment variable
    port: ${SMTP_PORT:587}
    properties:
      mail.smtp.auth: true
      mail.smtp.starttls.enable: true

app:
  business:
    max-todos-per-user: 100  # Stricter limit in production
    allow-public-registration: false  # Closed registration (invite-only)

  features:
    email-notifications: true
    analytics: true
    export-pdf: true

  rate-limiting:
    requests-per-minute: 30  # Stricter rate limiting in production
    burst-size: 5

scheduling:
  cron:
    cleanup-old-todos: "0 0 2 * * *"      # 2 AM daily
    send-reminders: "0 0 9 * * MON-FRI"   # 9 AM weekdays
    generate-reports: "0 0 1 * * *"       # 1 AM daily
    database-backup: "0 0 3 * * SUN"      # 3 AM every Sunday
  enabled: true

external:
  analytics-api:
    timeout-ms: 3000  # Shorter timeout in production
    retry-attempts: 2
    enabled: true
  notification-service:
    enabled: true
  payment-gateway:
    timeout-ms: 5000  # Shorter timeout in production

logging:
  level:
    root: WARN
    com.example.todoservice: INFO
    org.springframework.web: WARN
    org.hibernate.SQL: WARN
  file:
    name: /var/log/todo-service/application.log
```

---

## 🐳 Docker Compose Konfiguratsioon

### docker-compose.yml

```yaml
services:
  todo-service:
    image: todo-service:1.0-optimized
    environment:
      # ======================================================================
      # Infrastructure (sensitive)
      # ======================================================================
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-todo:5432/todo_service_db
      SPRING_DATASOURCE_PASSWORD: ${DB_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}

      # ======================================================================
      # SMTP (sensitive credentials)
      # ======================================================================
      SMTP_HOST: ${SMTP_HOST}
      SMTP_PORT: ${SMTP_PORT}
      SMTP_USERNAME: ${SMTP_USERNAME}
      SMTP_PASSWORD: ${SMTP_PASSWORD}
      SMTP_AUTH: true
      SMTP_STARTTLS: true

      # ======================================================================
      # External API (sensitive keys)
      # ======================================================================
      ANALYTICS_API_URL: ${ANALYTICS_API_URL}
      ANALYTICS_API_KEY: ${ANALYTICS_API_KEY}
      ANALYTICS_ENABLED: ${ANALYTICS_ENABLED}

      NOTIFICATION_SERVICE_URL: ${NOTIFICATION_SERVICE_URL}
      NOTIFICATION_API_KEY: ${NOTIFICATION_API_KEY}
      NOTIFICATION_SERVICE_ENABLED: ${NOTIFICATION_SERVICE_ENABLED}

      PAYMENT_API_URL: ${PAYMENT_API_URL}
      PAYMENT_API_KEY: ${PAYMENT_API_KEY}
      PAYMENT_WEBHOOK_SECRET: ${PAYMENT_WEBHOOK_SECRET}

      # ======================================================================
      # Spring Profile
      # ======================================================================
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILE:prod}

      # ======================================================================
      # Business Configuration (optional overrides)
      # ======================================================================
      MAX_TODOS_PER_USER: ${MAX_TODOS_PER_USER:100}
      ALLOW_PUBLIC_REGISTRATION: ${ALLOW_PUBLIC_REGISTRATION:false}
      FEATURE_TODO_SHARING: ${FEATURE_TODO_SHARING:true}

      # ======================================================================
      # Cron Schedules (optional overrides)
      # ======================================================================
      CRON_CLEANUP_TODOS: ${CRON_CLEANUP_TODOS:0 0 3 * * *}
      SCHEDULING_ENABLED: ${SCHEDULING_ENABLED:true}
```

---

## 🔐 .env Fail (Secrets + Environment-Specific)

```bash
# .env
# ⚠️ IMPORTANT: NEVER COMMIT THIS FILE TO GIT!

# ============================================================================
# Infrastructure Secrets
# ============================================================================
DB_PASSWORD=SuperSecurePassword123!
JWT_SECRET=a8f5f167f44f4964e6c998dee827110c3e51c9e5f3a7f0d8e2b4c9a1f5e8d7b3

# ============================================================================
# SMTP Configuration (SendGrid example)
# ============================================================================
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ============================================================================
# External API Keys
# ============================================================================
# Analytics
ANALYTICS_API_URL=https://analytics.example.com/api
ANALYTICS_API_KEY=prod-analytics-key-xxxxxxxxxxxxxxxx
ANALYTICS_ENABLED=true

# Notifications
NOTIFICATION_SERVICE_URL=https://notifications.example.com
NOTIFICATION_API_KEY=prod-notification-key-xxxxxxxxxxxxxxxx
NOTIFICATION_SERVICE_ENABLED=true

# Payment Gateway (Stripe example)
PAYMENT_API_URL=https://api.stripe.com/v1
PAYMENT_API_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
PAYMENT_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# ============================================================================
# Spring Profile
# ============================================================================
SPRING_PROFILE=prod

# ============================================================================
# Business Configuration (environment-specific overrides)
# ============================================================================
MAX_TODOS_PER_USER=50
ALLOW_PUBLIC_REGISTRATION=false
FEATURE_TODO_SHARING=true
FEATURE_ANALYTICS=true
FEATURE_EXPORT_PDF=true

# ============================================================================
# Cron Schedules (optional overrides)
# ============================================================================
CRON_CLEANUP_TODOS=0 0 3 * * *  # 3 AM (override default 2 AM)
CRON_DB_BACKUP=0 0 4 * * SUN    # 4 AM Sunday (override default 3 AM)
SCHEDULING_ENABLED=true
```

---

## 🎯 Otsustamise Reeglid

### 📄 Pane `application.yml`'i:

**✅ Sobib:**
- Turvalised vaikeväärtused (development friendly)
- Ärilised vaikeväärtused (defaults, mida saab override'ida)
- Feature flags (vaikimisi OFF või ON, override'itav)
- Non-sensitive API endpoints (dev/staging URLs)
- Cron schedule'd (development/default schedule)
- Timeouts, retry policies (conservative defaults)
- Logging patterns
- Business rules (max items, limits, trial periods)

**❌ EI SOBI:**
- Salasõnad, API keys, secrets
- Production-specific credentials
- Customer-specific configurations
- Anything that changes per deployment

**Syntax:**
```yaml
property: ${ENV_VAR:default_value}
```

---

### 📋 Pane `application-{profile}.yml`'i:

**✅ Sobib:**
- Profile-specific ärilised reeglid (dev vs prod limits)
- Environment-specific timeouts, rate limits
- Profile-specific feature flags
- Logging levels (dev=DEBUG, prod=WARN)
- Database schema management (dev=update, prod=validate)
- Cron schedules (dev=frequent, prod=production schedule)

**❌ EI SOBI:**
- Salasõnad (isegi production-prod.yml'is ei peaks olema!)
- Anything that needs to change without code redeploy

---

### 🔐 Pane Environment Variables'itesse (.env + docker-compose.yml):

**✅ Sobib:**
- Kõik salasõnad (DB, SMTP, API keys)
- Environment-specific endpoints (production SMTP server)
- Customer-specific configs (kui multi-tenant)
- Deploy-time muudetavad feature flags
- Secrets (JWT_SECRET, encryption keys, webhook secrets)
- API credentials (usernames, passwords, tokens)
- External service URLs (production URLs)

**❌ EI SOBI:**
- Ärilised reeglid, mis on "hardcoded" (need lähevad application.yml'i)
- Default väärtused (need lähevad application.yml'i)
- Anything that should be version controlled

---

## 📊 Otsustamise Voog (Decision Tree)

```
┌─────────────────────────────────────────────────┐
│ Kas see on salasõna/API key/secret?             │
└───────────────┬─────────────────────────────────┘
                │
        ┌───────┴───────┐
        │ JAH           │ EI
        │               │
        ▼               ▼
┌───────────────┐  ┌──────────────────────────────────────┐
│ Environment   │  │ Kas see muutub environment'ide vahel │
│ Variable      │  │ (dev/staging/prod)?                  │
│ (.env)        │  └──────────────┬───────────────────────┘
└───────────────┘                 │
                          ┌───────┴───────┐
                          │ JAH           │ EI
                          │               │
                          ▼               ▼
                  ┌──────────────┐  ┌─────────────────────┐
                  │ Kas sensitive?│  │ Kas see on äriline  │
                  └───┬──────────┘  │ vaikeväärtus?       │
                      │             └────┬────────────────┘
              ┌───────┴───────┐         │
              │ JAH           │ EI      │
              │               │         │
              ▼               ▼         ▼
       ┌──────────┐  ┌────────────────────┐  ┌──────────────┐
       │ Env Var  │  │ application-       │  │ application  │
       │ (.env)   │  │ {profile}.yml      │  │ .yml         │
       └──────────┘  └────────────────────┘  └──────────────┘
```

---

## 🔍 Spring Boot Property Name Mapping

**Kuidas Spring Boot konverteerib environment variable'id YAML properties'teks:**

| Environment Variable | YAML Property | Näide Väärtus |
|---------------------|--------------|--------------|
| `SERVER_PORT` | `server.port` | `8081` |
| `SPRING_DATASOURCE_URL` | `spring.datasource.url` | `jdbc:postgresql://...` |
| `SPRING_DATASOURCE_USERNAME` | `spring.datasource.username` | `dbuser` |
| `SPRING_DATASOURCE_PASSWORD` | `spring.datasource.password` | `securepass123` |
| `SPRING_JPA_SHOW_SQL` | `spring.jpa.show-sql` | `true` |
| `JWT_SECRET` | `jwt.secret` | `my-jwt-secret` |
| `JWT_EXPIRATION_MS` | `jwt.expiration` | `86400000` |
| `SMTP_HOST` | `spring.mail.host` | `smtp.example.com` |
| `SMTP_PORT` | `spring.mail.port` | `587` |
| `LOGGING_LEVEL_ROOT` | `logging.level.root` | `WARN` |
| `LOGGING_LEVEL_APP` | `logging.level.com.example` | `INFO` |
| `MAX_TODOS_PER_USER` | `app.business.max-todos-per-user` | `100` |
| `CRON_CLEANUP_TODOS` | `scheduling.cron.cleanup-old-todos` | `0 0 2 * * *` |

**Konversiooni reeglid:**
1. Uppercase → lowercase: `SERVER` → `server`
2. Underscore (`_`) → dot (`.`) või dash (`-`): `SPRING_DATASOURCE_URL` → `spring.datasource.url`
3. Camel case: `SPRING_JPA_SHOW_SQL` → `spring.jpa.show-sql`

---

## 🛠️ Praktilised Näited

### Näide 1: SMTP Konfiguratsioon

**application.yml (vaikeväärtused - MailHog dev):**
```yaml
spring:
  mail:
    host: ${SMTP_HOST:localhost}
    port: ${SMTP_PORT:1025}
    username: ${SMTP_USERNAME:}
    password: ${SMTP_PASSWORD:}
    properties:
      mail.smtp.auth: ${SMTP_AUTH:false}
      mail.smtp.starttls.enable: ${SMTP_STARTTLS:false}
```

**application-prod.yml (production defaults):**
```yaml
spring:
  mail:
    host: ${SMTP_HOST:smtp.sendgrid.net}
    port: ${SMTP_PORT:587}
    properties:
      mail.smtp.auth: true
      mail.smtp.starttls.enable: true
```

**.env (production secrets):**
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SMTP_AUTH=true
SMTP_STARTTLS=true
```

**Tulemus production'is:**
- Host: `smtp.sendgrid.net` (env var)
- Port: `587` (env var)
- Username: `apikey` (env var)
- Password: `SG.xxxx` (env var - SECRET!)
- Auth: `true` (env var)
- StartTLS: `true` (env var)

---

### Näide 2: Cron Schedule

**application.yml (dev-friendly):**
```yaml
scheduling:
  cron:
    cleanup-old-todos: ${CRON_CLEANUP_TODOS:0 */5 * * * *}  # Every 5 min (dev)
    send-reminders: ${CRON_SEND_REMINDERS:0 */10 * * * *}   # Every 10 min (dev)
  enabled: ${SCHEDULING_ENABLED:false}  # Disabled by default in dev
```

**application-prod.yml (production schedule):**
```yaml
scheduling:
  cron:
    cleanup-old-todos: ${CRON_CLEANUP_TODOS:0 0 2 * * *}  # 2 AM daily
    send-reminders: ${CRON_SEND_REMINDERS:0 0 9 * * MON-FRI}  # 9 AM weekdays
  enabled: ${SCHEDULING_ENABLED:true}
```

**.env (override if needed):**
```bash
CRON_CLEANUP_TODOS=0 0 3 * * *  # 3 AM instead of 2 AM
CRON_SEND_REMINDERS=0 0 8 * * MON-FRI  # 8 AM instead of 9 AM
SCHEDULING_ENABLED=true
```

---

### Näide 3: Feature Flags

**application.yml (conservative defaults):**
```yaml
app:
  features:
    email-notifications: ${FEATURE_EMAIL_NOTIFICATIONS:false}
    todo-sharing: ${FEATURE_TODO_SHARING:false}
    premium-features: ${FEATURE_PREMIUM:false}
    export-pdf: ${FEATURE_EXPORT_PDF:false}
```

**.env (enable selectively in production):**
```bash
FEATURE_EMAIL_NOTIFICATIONS=true
FEATURE_TODO_SHARING=true
FEATURE_PREMIUM=false  # Not ready yet
FEATURE_EXPORT_PDF=true
```

**Eelis:** Saad feature'd sisse/välja lülitada ilma koodi muutmata või redeploy'mata!

---

### Näide 4: External API (Payment Gateway)

**application.yml (dev mock):**
```yaml
external:
  payment-gateway:
    url: ${PAYMENT_API_URL:http://localhost:8090}
    api-key: ${PAYMENT_API_KEY:dev-api-key}
    timeout-ms: ${PAYMENT_TIMEOUT:10000}
    webhook-secret: ${PAYMENT_WEBHOOK_SECRET:dev-webhook-secret}
    enabled: ${PAYMENT_ENABLED:false}
```

**.env (production Stripe):**
```bash
PAYMENT_API_URL=https://api.stripe.com/v1
PAYMENT_API_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # SECRET!
PAYMENT_TIMEOUT=5000  # Shorter in production
PAYMENT_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxxxxxxxxxxxx  # SECRET!
PAYMENT_ENABLED=true
```

**Tulemus:**
- Dev: localhost mock server, fake credentials
- Prod: Real Stripe API, real credentials (from env vars)

---

## 🚀 Edasiarendus: Kubernetes ConfigMaps & Secrets (Lab 3+)

Kui migreerud Kubernetes'e (Lab 3), siis:

### ConfigMap (non-sensitive configs)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: todo-service-config
  namespace: production
data:
  # Business config
  MAX_TODOS_PER_USER: "100"
  ALLOW_PUBLIC_REGISTRATION: "false"
  TRIAL_PERIOD_DAYS: "14"

  # Feature flags
  FEATURE_TODO_SHARING: "true"
  FEATURE_ANALYTICS: "true"

  # Cron schedules
  CRON_CLEANUP_TODOS: "0 0 2 * * *"
  CRON_SEND_REMINDERS: "0 0 9 * * MON-FRI"

  # External endpoints (non-sensitive)
  ANALYTICS_API_URL: "https://analytics.example.com/api"
  NOTIFICATION_SERVICE_URL: "https://notifications.example.com"

  # SMTP (non-sensitive)
  SMTP_HOST: "smtp.sendgrid.net"
  SMTP_PORT: "587"
```

---

### Secret (sensitive configs)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: todo-service-secrets
  namespace: production
type: Opaque
data:
  # All values are base64 encoded
  DB_PASSWORD: U3VwZXJTZWN1cmVQYXNzd29yZDEyMyE=
  JWT_SECRET: YThmNWYxNjdmNDRmNDk2NGU2Yzk5OGRlZTgyNzExMGMzZTUxYzllNWYzYTdmMGQ4ZTJiNGM5YTFmNWU4ZDdiMw==
  SMTP_PASSWORD: U0cueHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eA==
  ANALYTICS_API_KEY: cHJvZC1hbmFseXRpY3Mta2V5LXh4eHh4eHh4eHh4eHh4eHh4eHg=
  NOTIFICATION_API_KEY: cHJvZC1ub3RpZmljYXRpb24ta2V5LXh4eHh4eHh4eHh4eHh4eA==
  PAYMENT_API_KEY: c2tfbGl2ZV94eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eA==
  PAYMENT_WEBHOOK_SECRET: d2hzZWNfeHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eA==
```

---

### Deployment (kasutab ConfigMap + Secret)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-service
  namespace: production
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: todo-service
        image: todo-service:1.0-optimized
        envFrom:
        - configMapRef:
            name: todo-service-config
        - secretRef:
            name: todo-service-secrets
```

---

## 📚 Kokkuvõte

### Kiire Otsustusjuhis:

| Konfiguratsioon | application.yml | application-{profile}.yml | Environment Variables (.env) | K8s ConfigMap | K8s Secret |
|----------------|----------------|--------------------------|------------------------------|---------------|------------|
| **Database password** | ❌ | ❌ | ✅ | ❌ | ✅ |
| **JWT secret** | ❌ | ❌ | ✅ | ❌ | ✅ |
| **SMTP password** | ❌ | ❌ | ✅ | ❌ | ✅ |
| **API keys** | ❌ | ❌ | ✅ | ❌ | ✅ |
| **SMTP host** | ✅ (dev default) | ✅ (prod default) | ✅ (override) | ✅ | ❌ |
| **External API URL** | ✅ (dev mock) | ✅ (prod URL) | ✅ (override) | ✅ | ❌ |
| **Max todos per user** | ✅ (default: 100) | ✅ (prod: 50) | ✅ (override) | ✅ | ❌ |
| **Feature flags** | ✅ (defaults) | ✅ (profile defaults) | ✅ (toggle) | ✅ | ❌ |
| **Cron schedules** | ✅ (dev: frequent) | ✅ (prod: normal) | ✅ (override) | ✅ | ❌ |
| **Timeouts** | ✅ (conservative) | ✅ (optimized) | ✅ (override) | ✅ | ❌ |
| **Logging levels** | ✅ (INFO) | ✅ (dev: DEBUG, prod: WARN) | ✅ (override) | ✅ | ❌ |

---

### Best Practice Workflow:

1. **Alusta `application.yml`'iga** - määra turvalised vaikeväärtused (dev-friendly)
2. **Lisa profile'd** - `application-dev.yml`, `application-prod.yml` (environment-specific defaults)
3. **Override env vars'iga** - salajased ja customer-specific (.env)
4. **Syntax:** `${ENV_VAR:default_value}` võimaldab flexibility + safety
5. **Tulevikus K8s** - ConfigMaps (non-sensitive) + Secrets (sensitive) (Lab 3)

---

### Võtmepunktid:

✅ **DO:**
- Pane vaikeväärtused `application.yml`'i
- Kasuta `${ENV_VAR:default}` syntax'it
- Pane salajased `.env` faili (ära commit Git'i!)
- Kasuta profile'e (dev, prod)
- Dokumenteeri, mis on overridable

❌ **DON'T:**
- Ära pane salasõnu `application.yml`'i
- Ära hardcode production väärtusi
- Ära commit `.env` faili Git'i
- Ära jäta mandatory muutujaid ilma default'ita (kui dev ei vaja)

---

## 🔗 Seotud Materjalid

- **Lab 2 Harjutus 4:** Environment Management
- **12-Factor App:** https://12factor.net/config
- **Spring Boot Externalized Configuration:** https://docs.spring.io/spring-boot/reference/features/external-config.html
- **Spring Boot Profiles:** https://docs.spring.io/spring-boot/reference/features/profiles.html

---

**Viimane uuendus:** 2025-12-11
**Staatus:** Täiendav tehnilise selgitus Lab 2 harjutustele
**TODO:** Otsusta hiljem, kas see läheb theory peatükki või jääb code-explanations kataloogi
