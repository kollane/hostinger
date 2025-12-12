# Harjutus 9: Production Readiness - SSL, Failover, Health Checks, Monitoring

**Eesmärk:** Õppida konfigureerimist tootmiskõlbulikuks (production-ready) Docker Compose stack'iks koos SSL/TLS'i, failover'i, health check'ide ja monitoring'uga

**Kestus:** 90-120 minutit

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Konfigureerida **SSL/TLS terminatsiooni** Nginx reverse proxy'is
- ✅ Implementeerida **high availability** (kõrge kättesaadavus) mitme instantsiga
- ✅ Kasutada **advanced health check'e** (liveness, readiness, startup probes)
- ✅ Seadistada **Prometheus monitoring'ut** Docker Compose teenustele
- ✅ Implementeerida **graceful shutdown** ja **rolling updates**
- ✅ Optimeerida **ressursse** (CPU, memory limits, connection pooling)
- ✅ Konfigureerida **log aggregation'it** ja **alerting'ut**
- ✅ Mõista **production best practice'e** Docker Compose keskkonnas

---

## 🏢 Stsenaarium: Ettevalmistus Production Deploy'iks

### Olukord:

Oled välja arendanud mikroteenuste stack'i (Harjutused 1-8), aga nüüd tuleb see **production'i viia**:

**❌ Praegused probleemid:**
- Puudub SSL/TLS (HTTP, mitte HTTPS)
- Ainult 1 instantsi igast teenusest (single point of failure)
- Lihtsamad health check'id (ei erista startup vs runtime)
- Puudub monitoring (ei tea, mis süsteemis toimub)
- Manuaalne deployment (ei ole automated)
- Ressursi limiidid puuduvad (võib kõik RAM'i ära kasutada)

### Siht-arhitektuur (Production-Ready):

```
                    Internet (HTTPS)
                         │
                         ▼
┌────────────────────────────────────────────────────────┐
│ Nginx (SSL Termination)                                │
│ - Port: 443 (HTTPS), 80 (redirect → 443)              │
│ - SSL Certificate (Let's Encrypt / Self-signed)       │
│ - Load balancing (round-robin)                        │
│ - Health check endpoints                              │
└──────────────┬─────────────────────────────────────────┘
               │ HTTP (internal network)
               ▼
┌────────────────────────────────────────────────────────┐
│ User Service (HA - 2 replicas)                         │
│ - Instance 1: user-service-1 (3000)                    │
│ - Instance 2: user-service-2 (3001)                    │
│ - Health: Startup + Liveness + Readiness              │
│ - Metrics: /metrics (Prometheus format)               │
│ - Resources: CPU limit, memory limit                  │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌────────────────────────────────────────────────────────┐
│ Todo Service (HA - 2 replicas)                         │
│ - Instance 1: todo-service-1 (8081)                    │
│ - Instance 2: todo-service-2 (8082)                    │
│ - Health: Startup + Liveness + Readiness              │
│ - Metrics: /metrics (Prometheus format)               │
│ - Resources: CPU limit, memory limit                  │
└──────────────┬─────────────────────────────────────────┘
               │
               ▼
┌────────────────────────────────────────────────────────┐
│ PostgreSQL (2 instances)                               │
│ - postgres-user (primary)                              │
│ - postgres-todo (primary)                              │
│ - Persistent volumes (data safety)                     │
│ - Connection pooling                                   │
└────────────────────────────────────────────────────────┘

                    Monitoring Layer
┌────────────────────────────────────────────────────────┐
│ Prometheus (9090)                                      │
│ - Scrapes /metrics from all services                   │
│ - Stores time-series data                             │
│ - Alerting rules                                       │
└────────────────────────────────────────────────────────┘
               │
               ▼
┌────────────────────────────────────────────────────────┐
│ Grafana (3001)                                         │
│ - Dashboards (system metrics, app metrics)            │
│ - Alerts visualization                                │
└────────────────────────────────────────────────────────┘
```

---

## 📂 Failide Struktuur

```
09-production-readiness/
├── docker-compose.prod.yml          # Production konfiguratsioon
├── .env.prod                        # Production environment vars
├── nginx/
│   ├── nginx.conf                   # SSL-enabled konfiguratsioon
│   ├── ssl/
│   │   ├── generate-ssl.sh          # Self-signed cert generator
│   │   ├── cert.pem                 # SSL certificate
│   │   └── key.pem                  # Private key
│   └── html/
│       └── index.html               # Default landing page
├── prometheus/
│   ├── prometheus.yml               # Prometheus konfiguratsioon
│   └── alerts.yml                   # Alerting rules
├── grafana/
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml       # Auto-configure Prometheus
│   │   └── dashboards/
│   │       ├── dashboard.yml
│   │       └── docker-compose-dashboard.json
└── scripts/
    ├── healthcheck-user.sh          # Custom health check script
    └── healthcheck-todo.sh
```

---

## 🏗️ Pattern Selgitus: BASE + OVERRIDE (OLULINE!)

**Eeldus:** Oled läbinud **Harjutused 4-6** (Multi-Environment Pattern)

Selles harjutuses jätkame **BASE + OVERRIDE** pattern'i kasutamist:

```
docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
                 ↑ BASE (compose-project/)  ↑ PROD (solutions/09-*)  ↑ SECRETS
```

**Oluline erinevus:**

- **BASE config:** `compose-project/docker-compose.yml` (Harjutused 1-6)
  - Põhiteenused: postgres, user-service, todo-service, frontend
  - Network definitions
  - Basic health checks

- **PRODUCTION override:** `solutions/09-production-readiness/docker-compose.prod.yml`
  - **SSL/TLS** (Nginx port 443)
  - **High Availability** (2 replicas per service)
  - **Monitoring** (Prometheus, Grafana - UUED teenused)
  - **Resource limits** (CPU, memory)
  - **Advanced health checks**

**Fail structure:**
```
compose-project/
└── docker-compose.yml              # BASE (Harjutused 1-6)

solutions/09-production-readiness/
├── docker-compose.prod.yml         # PRODUCTION overrides + NEW services
├── .env.prod.example               # Production secrets template
├── nginx/                          # SSL config files
├── prometheus/                     # Monitoring config
└── grafana/                        # Dashboard config
```

**Käivitamine:**
```bash
cd solutions/09-production-readiness/
docker-compose -f ../../compose-project/docker-compose.yml \
               -f docker-compose.prod.yml \
               --env-file .env.prod up -d
```

**Viited:**
- 📖 [compose-project/ENVIRONMENTS.md](../compose-project/ENVIRONMENTS.md)
- 📖 [compose-project/PASSWORDS.md](../compose-project/PASSWORDS.md)

---

## 📝 Sammud

### Samm 1: SSL/TLS Seadistamine (30 min)

#### 1.1 Loo harjutuse kataloog

```bash
cd ~/labs/02-docker-compose-lab/exercises
mkdir -p 09-production-readiness/{nginx/ssl,nginx/html,prometheus,grafana/provisioning/{datasources,dashboards},scripts}
cd 09-production-readiness
```

#### 1.2 Genereeri self-signed SSL sertifikaat

**Testimiseks kasutame self-signed sertifikaati. Production'is kasuta Let's Encrypt!**

```bash
cd nginx/ssl
vim generate-ssl.sh
```

**Fail: `nginx/ssl/generate-ssl.sh`**

```bash
#!/bin/bash
# Genereeri self-signed SSL certificate (TESTING ONLY!)
# Production: Use Let's Encrypt (certbot)

echo "Generating self-signed SSL certificate..."

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout key.pem \
  -out cert.pem \
  -subj "/C=EE/ST=Harjumaa/L=Tallinn/O=DevOps Training/OU=IT/CN=localhost"

echo "✅ SSL certificate generated:"
echo "  - cert.pem (certificate)"
echo "  - key.pem (private key)"
echo ""
echo "⚠️  WARNING: This is a self-signed certificate!"
echo "   For production, use Let's Encrypt: https://letsencrypt.org/"
```

```bash
# Tee skript käivitatavaks ja käivita
chmod +x generate-ssl.sh
./generate-ssl.sh

# Kontrolli
ls -lh cert.pem key.pem
```

#### 1.3 Loo SSL-enabled Nginx konfiguratsioon

```bash
cd ../
vim nginx.conf
```

**Fail: `nginx/nginx.conf`**

```nginx
# Production-Ready Nginx Configuration
# Features: SSL/TLS, Load Balancing, Health Checks, Security Headers

events {
    worker_connections 2048;
}

http {
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

    # Upstream: User Service (HA - 2 replicas)
    upstream user_service_backend {
        least_conn;  # Load balancing algorithm

        server user-service-1:3000 max_fails=3 fail_timeout=30s;
        server user-service-2:3000 max_fails=3 fail_timeout=30s;

        # Health check (passive)
        # Active health checks require nginx-plus or third-party module
    }

    # Upstream: Todo Service (HA - 2 replicas)
    upstream todo_service_backend {
        least_conn;

        server todo-service-1:8081 max_fails=3 fail_timeout=30s;
        server todo-service-2:8081 max_fails=3 fail_timeout=30s;
    }

    # HTTP server - Redirect to HTTPS
    server {
        listen 80;
        server_name localhost;

        # Health check endpoint (no redirect)
        location /health {
            access_log off;
            return 200 "Nginx LB: Healthy (HTTP)\n";
            add_header Content-Type text/plain;
        }

        # Redirect all other traffic to HTTPS
        location / {
            return 301 https://$host$request_uri;
        }
    }

    # HTTPS server - Main application
    server {
        listen 443 ssl http2;
        server_name localhost;

        # SSL Configuration
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;

        # SSL protocols and ciphers (modern configuration)
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        # SSL session cache
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # HSTS (HTTP Strict Transport Security)
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # Root location (landing page)
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "Nginx LB: Healthy (HTTPS)\n";
            add_header Content-Type text/plain;
        }

        # Nginx status (internal only)
        location /nginx-status {
            stub_status on;
            access_log off;
            allow 172.16.0.0/12;  # Docker networks
            deny all;
        }

        # User Service API (with rate limiting)
        location /api/auth/ {
            limit_req zone=api_limit burst=20 nodelay;

            proxy_pass http://user_service_backend;
            proxy_http_version 1.1;

            # Headers
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;

            # Timeouts
            proxy_connect_timeout 5s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;

            # CORS
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;

            if ($request_method = 'OPTIONS') {
                return 204;
            }
        }

        location /api/users {
            limit_req zone=api_limit burst=20 nodelay;

            proxy_pass http://user_service_backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Todo Service API
        location /api/todos {
            limit_req zone=api_limit burst=20 nodelay;

            proxy_pass http://todo_service_backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # CORS
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type' always;

            if ($request_method = 'OPTIONS') {
                return 204;
            }
        }

        # Metrics endpoint (Prometheus)
        location /metrics {
            # Restrict to internal networks only
            allow 172.16.0.0/12;  # Docker networks
            deny all;

            # Aggregate metrics from all services
            # In real production, use nginx-prometheus-exporter
            return 200 "# Placeholder for nginx metrics\n";
            add_header Content-Type text/plain;
        }
    }
}
```

**Salvesta** (`:wq`)

#### 1.4 Loo landing page

```bash
cd html
vim index.html
```

**Fail: `nginx/html/index.html`**

```html
<!DOCTYPE html>
<html lang="et">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Production-Ready Stack</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        h1 { font-size: 2.5rem; margin-bottom: 10px; }
        .status { color: #4ade80; font-weight: bold; }
        .services {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .service {
            background: rgba(255, 255, 255, 0.15);
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        .service h3 { margin-bottom: 10px; font-size: 1.2rem; }
        .service p { color: rgba(255, 255, 255, 0.8); font-size: 0.9rem; }
        .badge {
            display: inline-block;
            background: #4ade80;
            color: #1a202c;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: bold;
            margin-top: 10px;
        }
        .links { margin-top: 30px; }
        .links a {
            display: inline-block;
            color: white;
            text-decoration: none;
            background: rgba(255, 255, 255, 0.2);
            padding: 10px 20px;
            border-radius: 5px;
            margin-right: 10px;
            transition: background 0.3s;
        }
        .links a:hover { background: rgba(255, 255, 255, 0.3); }
        .footer { margin-top: 30px; text-align: center; opacity: 0.7; font-size: 0.9rem; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Production-Ready Stack</h1>
        <p class="status">✅ System Operational</p>

        <div class="services">
            <div class="service">
                <h3>🔐 SSL/TLS</h3>
                <p>HTTPS enabled</p>
                <span class="badge">Active</span>
            </div>
            <div class="service">
                <h3>⚖️ Load Balancing</h3>
                <p>2 replicas per service</p>
                <span class="badge">HA</span>
            </div>
            <div class="service">
                <h3>❤️ Health Checks</h3>
                <p>Liveness + Readiness</p>
                <span class="badge">Active</span>
            </div>
            <div class="service">
                <h3>📊 Monitoring</h3>
                <p>Prometheus + Grafana</p>
                <span class="badge">Active</span>
            </div>
        </div>

        <div class="links">
            <a href="/api/auth/health">User Service Health</a>
            <a href="/api/todos/health">Todo Service Health</a>
            <a href="http://localhost:9090" target="_blank">Prometheus</a>
            <a href="http://localhost:3001" target="_blank">Grafana</a>
        </div>

        <div class="footer">
            <p>🤖 DevOps Training Lab 2 - Harjutus 9: Production Readiness</p>
            <p>Secure • Scalable • Monitored</p>
        </div>
    </div>
</body>
</html>
```

**Salvesta** (`:wq`)

---

### Samm 2: High Availability - Multiple Replicas (20 min)

#### 2.1 Loo production Compose fail

```bash
cd ~/labs/02-docker-compose-lab/exercises/09-production-readiness
vim docker-compose.prod.yml
```

**Fail: `docker-compose.prod.yml`**

```yaml
# Production-Ready Docker Compose Configuration
# Features:
# - SSL/TLS termination
# - Multiple replicas (HA)
# - Advanced health checks
# - Resource limits
# - Monitoring (Prometheus + Grafana)

services:
  # ==========================================================================
  # Nginx - SSL Termination & Load Balancer
  # ==========================================================================
  nginx:
    image: nginx:1.25-alpine
    container_name: nginx-prod-lb
    restart: unless-stopped
    ports:
      - "80:80"    # HTTP (redirects to HTTPS)
      - "443:443"  # HTTPS
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/html:/usr/share/nginx/html:ro
    networks:
      - frontend-network
      - backend-network
    depends_on:
      - user-service-1
      - user-service-2
      - todo-service-1
      - todo-service-2
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/health"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 10s

  # ==========================================================================
  # User Service - Replica 1
  # ==========================================================================
  user-service-1:
    image: user-service:1.0-optimized
    container_name: user-service-1
    restart: unless-stopped
    environment:
      DATABASE_URL: postgresql://dbuser:${DB_PASSWORD:-dbpass123}@postgres-user:5432/user_service_db
      JWT_SECRET: ${JWT_SECRET}
      NODE_ENV: production
      PORT: 3000
      INSTANCE_ID: user-service-1
    networks:
      - backend-network
      - database-network
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s
    depends_on:
      postgres-user:
        condition: service_healthy

  # ==========================================================================
  # User Service - Replica 2
  # ==========================================================================
  user-service-2:
    image: user-service:1.0-optimized
    container_name: user-service-2
    restart: unless-stopped
    environment:
      DATABASE_URL: postgresql://dbuser:${DB_PASSWORD:-dbpass123}@postgres-user:5432/user_service_db
      JWT_SECRET: ${JWT_SECRET}
      NODE_ENV: production
      PORT: 3000
      INSTANCE_ID: user-service-2
    networks:
      - backend-network
      - database-network
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s
    depends_on:
      postgres-user:
        condition: service_healthy

  # ==========================================================================
  # Todo Service - Replica 1
  # ==========================================================================
  todo-service-1:
    image: todo-service:1.0-optimized
    container_name: todo-service-1
    restart: unless-stopped
    environment:
      DATABASE_URL: postgresql://dbuser:${DB_PASSWORD:-dbpass123}@postgres-todo:5432/todo_service_db
      JWT_SECRET: ${JWT_SECRET}
      SPRING_PROFILES_ACTIVE: prod
      SERVER_PORT: 8081
      INSTANCE_ID: todo-service-1
    networks:
      - backend-network
      - database-network
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8081/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 60s
    depends_on:
      postgres-todo:
        condition: service_healthy

  # ==========================================================================
  # Todo Service - Replica 2
  # ==========================================================================
  todo-service-2:
    image: todo-service:1.0-optimized
    container_name: todo-service-2
    restart: unless-stopped
    environment:
      DATABASE_URL: postgresql://dbuser:${DB_PASSWORD:-dbpass123}@postgres-todo:5432/todo_service_db
      JWT_SECRET: ${JWT_SECRET}
      SPRING_PROFILES_ACTIVE: prod
      SERVER_PORT: 8081
      INSTANCE_ID: todo-service-2
    networks:
      - backend-network
      - database-network
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8081/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 60s
    depends_on:
      postgres-todo:
        condition: service_healthy

  # ==========================================================================
  # PostgreSQL - Users Database
  # ==========================================================================
  postgres-user:
    image: postgres:16-alpine
    container_name: postgres-user-prod
    restart: unless-stopped
    environment:
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD: ${DB_PASSWORD:-dbpass123}
      POSTGRES_DB: user_service_db
      # Performance tuning
      POSTGRES_SHARED_BUFFERS: 256MB
      POSTGRES_EFFECTIVE_CACHE_SIZE: 1GB
      POSTGRES_MAINTENANCE_WORK_MEM: 64MB
      POSTGRES_CHECKPOINT_COMPLETION_TARGET: 0.9
      POSTGRES_WAL_BUFFERS: 16MB
      POSTGRES_DEFAULT_STATISTICS_TARGET: 100
      POSTGRES_RANDOM_PAGE_COST: 1.1
      POSTGRES_EFFECTIVE_IO_CONCURRENCY: 200
      POSTGRES_WORK_MEM: 4MB
      POSTGRES_MIN_WAL_SIZE: 1GB
      POSTGRES_MAX_WAL_SIZE: 4GB
      POSTGRES_MAX_CONNECTIONS: 100
    volumes:
      - postgres-user-data:/var/lib/postgresql/data
    networks:
      - database-network
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dbuser -d user_service_db"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # ==========================================================================
  # PostgreSQL - Todos Database
  # ==========================================================================
  postgres-todo:
    image: postgres:16-alpine
    container_name: postgres-todo-prod
    restart: unless-stopped
    environment:
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD: ${DB_PASSWORD:-dbpass123}
      POSTGRES_DB: todo_service_db
      POSTGRES_SHARED_BUFFERS: 256MB
      POSTGRES_EFFECTIVE_CACHE_SIZE: 1GB
      POSTGRES_MAX_CONNECTIONS: 100
    volumes:
      - postgres-todo-data:/var/lib/postgresql/data
    networks:
      - database-network
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dbuser -d todo_service_db"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  # ==========================================================================
  # Prometheus - Metrics Collection
  # ==========================================================================
  prometheus:
    image: prom/prometheus:v2.48.0
    container_name: prometheus-prod
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/alerts.yml:/etc/prometheus/alerts.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    networks:
      - monitoring-network
      - backend-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9090/-/healthy"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ==========================================================================
  # Grafana - Metrics Visualization
  # ==========================================================================
  grafana:
    image: grafana/grafana:10.2.2
    container_name: grafana-prod
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD:-admin123}
      GF_INSTALL_PLUGINS: ""
    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - grafana-data:/var/lib/grafana
    networks:
      - monitoring-network
    depends_on:
      - prometheus
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres-user-data:
    name: postgres-user-data-prod
  postgres-todo-data:
    name: postgres-todo-data-prod
  prometheus-data:
    name: prometheus-data-prod
  grafana-data:
    name: grafana-data-prod

networks:
  frontend-network:
    name: prod-frontend-network
    driver: bridge
  backend-network:
    name: prod-backend-network
    driver: bridge
  database-network:
    name: prod-database-network
    driver: bridge
    internal: true  # Database network is isolated
  monitoring-network:
    name: prod-monitoring-network
    driver: bridge
```

**Salvesta** (`:wq`)

---

### Samm 3: Prometheus Monitoring (20 min)

#### 3.1 Loo Prometheus konfiguratsioon

```bash
cd prometheus
vim prometheus.yml
```

**Fail: `prometheus/prometheus.yml`**

```yaml
# Prometheus Configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    environment: 'production'
    cluster: 'docker-compose-lab2'

# Alerting configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets: []
          # - alertmanager:9093

# Load alerting rules
rule_files:
  - '/etc/prometheus/alerts.yml'

# Scrape configurations
scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Docker containers (via cAdvisor - optional)
  # - job_name: 'cadvisor'
  #   static_configs:
  #     - targets: ['cadvisor:8080']

  # User Service instances
  - job_name: 'user-service'
    metrics_path: '/metrics'
    static_configs:
      - targets:
          - 'user-service-1:3000'
          - 'user-service-2:3000'
        labels:
          service: 'user-service'

  # Todo Service instances
  - job_name: 'todo-service'
    metrics_path: '/metrics'
    static_configs:
      - targets:
          - 'todo-service-1:8081'
          - 'todo-service-2:8081'
        labels:
          service: 'todo-service'

  # PostgreSQL exporter (optional - requires postgres_exporter)
  # - job_name: 'postgres'
  #   static_configs:
  #     - targets:
  #         - 'postgres-exporter-user:9187'
  #         - 'postgres-exporter-todo:9187'

  # Nginx exporter (optional - requires nginx-prometheus-exporter)
  # - job_name: 'nginx'
  #   static_configs:
  #     - targets: ['nginx-exporter:9113']
```

**Salvesta** (`:wq`)

#### 3.2 Loo alerting reeglid

```bash
vim alerts.yml
```

**Fail: `prometheus/alerts.yml`**

```yaml
# Prometheus Alerting Rules
groups:
  - name: service_health
    interval: 30s
    rules:
      # Alert when service is down
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "{{ $labels.instance }} has been down for more than 1 minute."

      # Alert when service has high error rate
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate on {{ $labels.job }}"
          description: "{{ $labels.instance }} has error rate above 5% for 5 minutes."

  - name: resource_usage
    interval: 30s
    rules:
      # Alert when memory usage is high
      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.name }}"
          description: "Container {{ $labels.name }} memory usage is above 90%."

      # Alert when CPU usage is high
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.name }}"
          description: "Container {{ $labels.name }} CPU usage is above 80% for 10 minutes."

  - name: database
    interval: 30s
    rules:
      # Alert when database connections are high
      - alert: HighDatabaseConnections
        expr: pg_stat_database_numbackends > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High database connections"
          description: "Database has more than 80 connections for 5 minutes."
```

**Salvesta** (`:wq`)

---

### Samm 4: Grafana Dashboards (15 min)

#### 4.1 Loo Grafana datasource provisioning

```bash
cd ../grafana/provisioning/datasources
vim prometheus.yml
```

**Fail: `grafana/provisioning/datasources/prometheus.yml`**

```yaml
# Grafana Datasource Provisioning - Prometheus
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
    jsonData:
      timeInterval: "15s"
```

**Salvesta** (`:wq`)

#### 4.2 Loo dashboard provisioning

```bash
cd ../dashboards
vim dashboard.yml
```

**Fail: `grafana/provisioning/dashboards/dashboard.yml`**

```yaml
# Grafana Dashboard Provisioning
apiVersion: 1

providers:
  - name: 'Docker Compose Dashboards'
    orgId: 1
    folder: 'Production'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
      foldersFromFilesStructure: true
```

**Salvesta** (`:wq`)

---

### Samm 5: Environment Variables (5 min)

**Märkus:** See jätkab **Harjutus 4** multi-environment pattern'i.

```bash
cd ~/labs/02-docker-compose-lab/solutions/09-production-readiness
cp .env.prod.example .env.prod
nano .env.prod
```

**Fail: `.env.prod`**

```bash
# Production Environment Variables
# IMPORTANT: In real production, use secrets management (Vault, AWS Secrets Manager)
# See also: compose-project/PASSWORDS.md

# Database
DB_PASSWORD=SuperSecureProductionPassword123!

# JWT Secret (must be strong and random)
JWT_SECRET=a8f5f167f44f4964e6c998dee827110c3e51c9e5f3a7f0d8e2b4c9a1f5e8d7b3

# Grafana
GRAFANA_PASSWORD=GrafanaAdminPassword456!

# Application
NODE_ENV=production
SPRING_PROFILES_ACTIVE=prod

# Monitoring
PROMETHEUS_RETENTION_DAYS=30
```

**Salvesta** (`:wq`)

**⚠️ HOIATUS: Ära pane .env.prod faili Git'i!**

```bash
echo ".env.prod" >> ~/labs/02-docker-compose-lab/.gitignore
```

---

### Samm 6: Käivita Production Stack (10 min)

#### 6.1 Initsialiseeri andmebaasid

**Enne stack'i käivitamist, loo DB skeemid (kui ei ole juba loodud):**

```bash
# OPTION A: Kasuta Lab 2 olemasolevaid volumes (kui on)
# docker volume ls | grep postgres

# OPTION B: Loo uued volumes ja initsialiseeri
docker volume create postgres-user-data-prod
docker volume create postgres-todo-data-prod

# Käivita ajutised PostgreSQL konteinerid
docker run -d --name temp-postgres-user \
  -e POSTGRES_USER=dbuser \
  -e POSTGRES_PASSWORD=SuperSecureProductionPassword123! \
  -e POSTGRES_DB=user_service_db \
  -v postgres-user-data-prod:/var/lib/postgresql/data \
  postgres:16-alpine

docker run -d --name temp-postgres-todo \
  -e POSTGRES_USER=dbuser \
  -e POSTGRES_PASSWORD=SuperSecureProductionPassword123! \
  -e POSTGRES_DB=todo_service_db \
  -v postgres-todo-data-prod:/var/lib/postgresql/data \
  postgres:16-alpine

# Oota 10 sekundit
sleep 10

# Loo tabelid
docker exec -it temp-postgres-user psql -U dbuser -d user_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

docker exec -it temp-postgres-todo psql -U dbuser -d todo_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Eemalda ajutised konteinerid
docker stop temp-postgres-user temp-postgres-todo
docker rm temp-postgres-user temp-postgres-todo
```

#### 6.2 Käivita production stack

```bash
cd ~/labs/02-docker-compose-lab/solutions/09-production-readiness

# Käivita kõik teenused (BASE + PROD override)
docker compose -f ../../compose-project/docker-compose.yml \
               -f docker-compose.prod.yml \
               --env-file .env.prod up -d
#               ↑ BASE config                    ↑ PROD override   ↑ SECRETS

# Vaata logisid
docker compose -f ../../compose-project/docker-compose.yml \
               -f docker-compose.prod.yml logs -f

# Oota kuni kõik teenused on käivitunud (30-60 sekundit)
```

#### 6.3 Kontrolli teenuste olekut

```bash
# Vaata kõiki teenuseid
docker compose -f ../../compose-project/docker-compose.yml \
               -f docker-compose.prod.yml ps

# Peaks nägema 9 konteinerit:
# - nginx-prod-lb (80, 443)
# - user-service-1, user-service-2
# - todo-service-1, todo-service-2
# - postgres-user-prod, postgres-todo-prod
# - prometheus-prod (9090)
# - grafana-prod (3001)

# Health check'id
docker compose -f ../../compose-project/docker-compose.yml \
               -f docker-compose.prod.yml ps --filter "health=healthy"
```

**Alias (valikuline):**
```bash
# Lisa ~/.bashrc faili lihtsustamiseks
alias dc-prod-ex9='docker compose -f ../../compose-project/docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod'

# Kasutamine:
dc-prod-ex9 ps
dc-prod-ex9 logs -f
dc-prod-ex9 down
```

---

### Samm 7: Testimine (20 min)

#### 7.1 SSL/TLS testimine

```bash
# HTTP → HTTPS redirect
curl -I http://localhost/
# Peaks nägema: HTTP/1.1 301 Moved Permanently

# HTTPS endpoint (self-signed cert)
curl -k https://localhost/health
# Legacy Nginx LB: Healthy (HTTPS)

# Testi brauseris
# HTTPS: https://localhost (võtab self-signed cert hoiatuse vastu)
```

#### 7.2 Load balancing testimine

```bash
# Tee 10 päringut, vaata kumb instantsi vastab
for i in {1..10}; do
  curl -k -s https://localhost/api/auth/health | grep -o 'user-service-[12]' || echo "N/A"
  sleep 0.5
done

# Peaks nägema:
# user-service-1
# user-service-2
# user-service-1
# user-service-2
# ... (round-robin või least-conn)
```

#### 7.3 Failover testimine

```bash
# Peata user-service-1
docker stop user-service-1

# Testi, kas user-service-2 võtab üle
for i in {1..5}; do
  curl -k https://localhost/api/auth/health
  sleep 1
done

# Peaks töötama ilma katkestuseta!

# Käivita user-service-1 tagasi
docker start user-service-1

# Oota 30 sekundit (health check)
sleep 30

# Load balancing peaks taastuma
for i in {1..10}; do
  curl -k -s https://localhost/api/auth/health | grep -o 'user-service-[12]' || echo "N/A"
  sleep 0.5
done
```

#### 7.4 End-to-End API test (HTTPS)

```bash
# Registreeri kasutaja (HTTPS)
curl -k -X POST https://localhost/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Production User",
    "email": "prod@example.com",
    "password": "SecurePass123!"
  }'

# Login (HTTPS)
TOKEN=$(curl -k -s -X POST https://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"prod@example.com","password":"SecurePass123!"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo "JWT Token: $TOKEN"

# Loo todo (HTTPS)
curl -k -X POST https://localhost/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Production Deployment Complete",
    "description": "SSL + HA + Monitoring working!"
  }'

# Vaata todos (HTTPS)
curl -k https://localhost/api/todos \
  -H "Authorization: Bearer $TOKEN"
```

#### 7.5 Prometheus testimine

```bash
# Ava brauser
# http://localhost:9090

# Targets (Status → Targets):
# - prometheus (1/1)
# - user-service (2/2)
# - todo-service (2/2)

# Küsimused (Graph):
# - up
# - rate(http_requests_total[5m])
# - container_memory_usage_bytes
```

#### 7.6 Grafana testimine

```bash
# Ava brauser
# http://localhost:3001

# Login:
# Username: admin
# Password: admin123 (või .env.prod GRAFANA_PASSWORD)

# Lisa dashboard:
# 1. Dashboard → Import
# 2. Import ID: 1860 (Node Exporter Full)
# 3. Või loo custom dashboard:
#    - Panel → Add new panel
#    - Query: up
#    - Visualization: Stat
```

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **SSL/TLS:** HTTPS töötab (https://localhost)
- [ ] **HTTP → HTTPS:** Automaatne redirect
- [ ] **Load Balancing:** 2 instantsi per service, round-robin
- [ ] **Failover:** Kui 1 instantsi crashib, teine võtab üle
- [ ] **Health Checks:** Kõik teenused "healthy" olekus
- [ ] **Resource Limits:** CPU ja memory limitid seadistatud
- [ ] **Monitoring:** Prometheus (9090) kogub metrics'eid
- [ ] **Dashboards:** Grafana (3001) kuvab metrics'eid
- [ ] **Security:** Database network isolated, rate limiting enabled

---

## 🧪 Advanced Testimine

### Test 1: Stress Testing (Load Testing)

```bash
# Installi Apache Bench (kui ei ole)
# Ubuntu/Debian: sudo apt-get install apache2-utils
# macOS: brew install httpd (ab included)

# Load test (1000 requests, 10 concurrent)
ab -n 1000 -c 10 -k https://localhost/health

# Vaata Prometheus metrics'e:
# rate(http_requests_total[1m])
```

### Test 2: Database Connection Pooling

```bash
# Vaata PostgreSQL ühendusi
docker exec -it postgres-user-prod psql -U dbuser -d user_service_db -c "SELECT count(*) FROM pg_stat_activity;"

# Tee palju parallelseid päringuid
for i in {1..20}; do
  (curl -k -s https://localhost/api/auth/health > /dev/null) &
done
wait

# Vaata ühendusi uuesti
docker exec -it postgres-user-prod psql -U dbuser -d user_service_db -c "SELECT count(*), state FROM pg_stat_activity GROUP BY state;"
```

### Test 3: Graceful Shutdown

```bash
# Vaata teenuse logisid reaalajas
docker logs -f user-service-1 &

# Peata teenus gracefully
docker stop user-service-1

# Peaks nägema:
# - "Received SIGTERM signal"
# - "Closing database connections..."
# - "Server shutting down gracefully"
```

---

## 🐛 Levinud Probleemid

### Probleem 1: "SSL handshake failed"

**Sümptom:**
```bash
curl https://localhost/health
# curl: (60) SSL certificate problem: self signed certificate
```

**Lahendus:**

```bash
# Kasuta -k (insecure) flag'i self-signed cert'idega
curl -k https://localhost/health

# Või brauseris: Akcepteeri risk ja jätka
```

**Production:**
```bash
# Kasuta Let's Encrypt (tasuta SSL)
# https://letsencrypt.org/

# Certbot (automaatne)
sudo certbot --nginx -d yourdomain.com
```

### Probleem 2: "Service unhealthy"

**Sümptom:**
```bash
docker compose -f docker-compose.prod.yml ps
# user-service-1  unhealthy
```

**Lahendus:**

```bash
# Vaata health check logisid
docker inspect user-service-1 | grep -A 10 "Health"

# Vaata teenuse logisid
docker logs user-service-1 | tail -50

# Kontrolli health check endpoint'i manuaalselt
docker exec user-service-1 wget -O- http://localhost:3000/health
```

### Probleem 3: "Prometheus not scraping"

**Sümptom:** Prometheus targets "down"

**Lahendus:**

```bash
# Kontrolli, kas teenused on samas võrgus
docker network inspect prod-backend-network | grep user-service

# Testi ühenduvust Prometheus konteinerist
docker exec -it prometheus-prod wget -O- http://user-service-1:3000/metrics

# Kontrolli prometheus.yml konfiguratsiooni
docker exec -it prometheus-prod cat /etc/prometheus/prometheus.yml
```

---

## 🎓 Õpitud Mõisted

### 1. SSL/TLS Termination

**Mis see on?**
- HTTPS ühendus lõpetatakse load balancer'is
- Sisevõrgus (backend) kasutatakse HTTP'i
- Lihtsustab sertifikattide haldust (ainult ühes kohas)

**Konfiguratsioon:**
```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    location / {
        proxy_pass http://backend;  # HTTP sisevõrgus
    }
}
```

### 2. High Availability (HA)

**Põhimõte:**
- Mitu identset instantsi igast teenusest
- Load balancer jaotab traffic'u instantside vahel
- Kui üks instantsi crashib, teised jätkavad

**Docker Compose:**
```yaml
user-service-1:
  image: user-service:1.0

user-service-2:
  image: user-service:1.0
```

### 3. Health Check Tüübid

**Startup Probe:**
- Kontrollib, kas teenus on käivitunud
- Pikemad timeout'id (60s)

**Liveness Probe:**
- Kontrollib, kas teenus töötab
- Kui ebaõnnestub → restart

**Readiness Probe:**
- Kontrollib, kas teenus on valmis päringuid vastu võtma
- Kui ebaõnnestub → ei saada traffic'ut

```yaml
healthcheck:
  test: ["CMD", "wget", "--spider", "http://localhost:3000/health"]
  interval: 30s       # Kui tihti kontrollitakse
  timeout: 5s         # Max aeg vastuseks
  retries: 3          # Mitu korda retry'takse
  start_period: 60s   # Startup grace period
```

### 4. Resource Limits

**Limits vs Reservations:**
- **Limits:** Max ressursid, mida konteiner saab kasutada
- **Reservations:** Min ressursid, mis garanteeritakse

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'      # Max 1 CPU core
      memory: 1G       # Max 1GB RAM
    reservations:
      cpus: '0.5'      # Min 0.5 CPU cores
      memory: 512M     # Min 512MB RAM
```

---

## 💡 Production Best Practices

### 1. Secrets Management

**❌ ÄRA** pane salasõnu .env faili (Git'i)

**✅ KASUTA** secrets management'i:
- Docker Secrets (Swarm)
- Vault (HashiCorp)
- AWS Secrets Manager
- Azure Key Vault

**Näide (Docker Secrets):**
```yaml
secrets:
  db_password:
    external: true

services:
  app:
    secrets:
      - db_password
```

### 2. SSL/TLS Best Practices

**✅ DO:**
- Kasuta Let's Encrypt production'is
- Keela vanad protokollid (TLS 1.0, 1.1)
- Kasuta tugevaid cipher'eid
- Enable HSTS

**❌ DON'T:**
- Ära kasuta self-signed cert'e production'is
- Ära keela SSL verify'mist

### 3. Monitoring & Alerting

**Mida monitoorida:**
- Service uptime (up metric)
- HTTP error rates (5xx, 4xx)
- Response times (latency)
- Resource usage (CPU, memory)
- Database connections
- Disk usage

**Alerting:**
- Seadista alerts critical metrics'idele
- Kasuta PagerDuty, Opsgenie, vms
- Testi alerts'e regulaarselt

### 4. Backup Strategy

**3-2-1 reegel:**
- **3** koopiat
- **2** erinevat meedia't (disk, cloud)
- **1** offsite backup

```bash
# Automaatne backup (cron)
0 2 * * * /path/to/backup-script.sh
```

---

## 🔗 Järgmine Samm

**Õnnitleme! Oled läbinud Lab 2 kõik harjutused!**

**Mida saavutasid:**
- ✅ Docker Compose orkestratsioon (Harjutused 1-6)
- ✅ Advanced patterns (Harjutus 7)
- ✅ Legacy integration (Harjutus 8)
- ✅ Production readiness (Harjutus 9)

**Järgmine Labor:**
- 🎯 **Labor 3:** Kubernetes Põhitõed
  - Migratsioon Docker Compose → Kubernetes
  - Pods, Deployments, Services
  - ConfigMaps, Secrets, PersistentVolumes

---

## 📚 Viited

### SSL/TLS:
- [Let's Encrypt](https://letsencrypt.org/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [SSL Labs Test](https://www.ssllabs.com/ssltest/)

### Monitoring:
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Docker Compose metrics](https://docs.docker.com/config/daemon/prometheus/)

### High Availability:
- [Nginx Load Balancing](https://nginx.org/en/docs/http/load_balancing.html)
- [Docker health checks](https://docs.docker.com/engine/reference/builder/#healthcheck)
- [Production best practices](https://docs.docker.com/compose/production/)

---

**Puhastamine:**

```bash
# Peata kõik teenused
cd ~/labs/02-docker-compose-lab/exercises/09-production-readiness
docker compose -f docker-compose.prod.yml down

# Eemalda volumes (kui tahad puhast algust)
docker compose -f docker-compose.prod.yml down -v

# Või käsitsi
docker volume rm postgres-user-data-prod postgres-todo-data-prod prometheus-data-prod grafana-data-prod
```

---

**Viimane uuendus:** 2025-12-11
**Seotud harjutused:** Lab 2 Harjutus 6 (Production Patterns), Lab 2 Harjutus 8 (Legacy Integration)
**Eeldusteadmised:** Docker Compose, SSL/TLS basics, Prometheus, Grafana
