# Harjutus 9: Production Readiness - Lahendused

See kataloog sisaldab lahendusi Harjutus 9 jaoks: Production-Ready Docker Compose Stack (SSL/TLS, HA, Monitoring).

---

## 📂 Failide Struktuur

```
09-production-readiness/
├── README.md                          # See fail
├── docker-compose.prod.yml            # Production konfiguratsioon (PEAMINE)
├── .env.prod.example                  # Environment variables template
├── nginx/
│   ├── nginx.conf                     # SSL-enabled Nginx konfiguratsioon
│   ├── ssl/
│   │   ├── generate-ssl.sh            # SSL certificate generator (executable)
│   │   ├── cert.pem                   # SSL certificate (genereeritakse)
│   │   └── key.pem                    # Private key (genereeritakse)
│   └── html/
│       └── index.html                 # Landing page
├── prometheus/
│   ├── prometheus.yml                 # Prometheus konfiguratsioon
│   └── alerts.yml                     # Alerting rules
├── grafana/
│   └── provisioning/
│       ├── datasources/
│       │   └── prometheus.yml         # Auto-configure Prometheus datasource
│       └── dashboards/
│           └── dashboard.yml          # Dashboard provisioning
└── scripts/
    └── init-databases.sh              # Database initialization script
```

---

## 🚀 Quick Start

### Samm 1: Genereeri SSL Sertifikaat

```bash
cd nginx/ssl
./generate-ssl.sh

# Generates:
# - cert.pem (self-signed certificate)
# - key.pem (private key)
```

### Samm 2: Kopeeri Environment Template

```bash
cp .env.prod.example .env.prod
vim .env.prod  # Uuenda salasõnad!
```

### Samm 3: Initsialiseeri Andmebaasid

```bash
cd ../..
./scripts/init-databases.sh
```

### Samm 4: Käivita Production Stack

```bash
docker compose -f docker-compose.prod.yml --env-file .env.prod up -d

# Vaata logisid
docker compose -f docker-compose.prod.yml logs -f
```

---

## 🏗️ Arhitektuur

```
                 Internet (HTTPS/443)
                        │
                        ▼
┌──────────────────────────────────────────────┐
│ Nginx (SSL Termination)                      │
│ - Port 443 (HTTPS), 80 (HTTP redirect)      │
│ - Load balancing (round-robin)              │
└───────────────────┬──────────────────────────┘
                    │ HTTP (internal)
                    ▼
┌──────────────────────────────────────────────┐
│ Application Layer (HA - 2 replicas each)    │
│ - user-service-1, user-service-2            │
│ - todo-service-1, todo-service-2            │
└───────────────────┬──────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────────┐
│ Database Layer                               │
│ - postgres-user, postgres-todo              │
└──────────────────────────────────────────────┘

     Monitoring Stack
┌──────────────────────────────────────────────┐
│ Prometheus (9090) + Grafana (3001)          │
└──────────────────────────────────────────────┘
```

---

## 🧪 Testimine

### SSL/TLS Test

```bash
# HTTP → HTTPS redirect
curl -I http://localhost/
# HTTP/1.1 301 Moved Permanently

# HTTPS endpoint (self-signed cert)
curl -k https://localhost/health
# Nginx LB: Healthy (HTTPS)
```

### Load Balancing Test

```bash
# 10 päringut, vaata load balancing'ut
for i in {1..10}; do
  curl -k -s https://localhost/api/auth/health
  sleep 0.5
done

# Peaks näitama user-service-1 ja user-service-2 vaheldumisi
```

### Failover Test

```bash
# Peata user-service-1
docker stop user-service-1

# Testi, kas traffic'u võetakse vastu
for i in {1..5}; do
  curl -k https://localhost/api/auth/health
  sleep 1
done

# user-service-2 peaks vastama (no downtime!)

# Käivita user-service-1 tagasi
docker start user-service-1
```

### End-to-End API Test (HTTPS)

```bash
# Registreeri kasutaja
curl -k -X POST https://localhost/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@example.com","password":"test123"}'

# Login
TOKEN=$(curl -k -s -X POST https://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Loo todo
curl -k -X POST https://localhost/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"Production Test","description":"SSL + HA + Monitoring"}'

# Vaata todos
curl -k https://localhost/api/todos -H "Authorization: Bearer $TOKEN"
```

### Monitoring Test

```bash
# Prometheus (ava brauseris)
# http://localhost:9090
# Targets → peaks nägema 5/5 UP

# Grafana (ava brauseris)
# http://localhost:3001
# Login: admin / admin123 (või .env.prod password)
```

---

## 📊 Teenused ja Portid

| Teenus | Port (Host) | Port (Container) | Protokoll | Kirjeldus |
|--------|-------------|------------------|-----------|-----------|
| **nginx** | 80 | 80 | HTTP | Redirect → HTTPS |
| **nginx** | 443 | 443 | HTTPS | SSL termination |
| **user-service-1** | - | 3000 | HTTP | Internal only |
| **user-service-2** | - | 3000 | HTTP | Internal only |
| **todo-service-1** | - | 8081 | HTTP | Internal only |
| **todo-service-2** | - | 8081 | HTTP | Internal only |
| **postgres-user** | - | 5432 | PostgreSQL | Internal only |
| **postgres-todo** | - | 5432 | PostgreSQL | Internal only |
| **prometheus** | 9090 | 9090 | HTTP | Metrics collection |
| **grafana** | 3001 | 3000 | HTTP | Dashboards |

---

## 🔐 Turvalisus

### SSL/TLS

**Testing (self-signed):**
- Kasutame self-signed certificate'i
- Brauserid hoiatavad (ootuspärane)
- Kasuta `-k` flag'i cURL'iga

**Production (Let's Encrypt):**
```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Generate SSL certificate (automatic)
sudo certbot --nginx -d yourdomain.com

# Auto-renewal (cron)
sudo certbot renew --dry-run
```

### Secrets Management

**⚠️ OLULINE:**
- ÄRA pane `.env.prod` faili Git'i!
- Production'is kasuta Vault, AWS Secrets Manager, vms
- Rotate salasõnu regulaarselt

### Network Segmentation

- **frontend-network:** Nginx ↔ Apps
- **backend-network:** Apps ↔ Apps
- **database-network:** Apps ↔ DB (internal=true)
- **monitoring-network:** Prometheus, Grafana

---

## 🐛 Troubleshooting

### Probleem: "SSL handshake failed"

```bash
# Self-signed cert hoiatus - kasuta -k flag'i
curl -k https://localhost/health
```

### Probleem: "Service unhealthy"

```bash
# Vaata health check logisid
docker inspect user-service-1 | grep -A 10 "Health"

# Vaata teenuse logisid
docker logs user-service-1 --tail 50
```

### Probleem: "Prometheus targets down"

```bash
# Kontrolli võrku
docker network inspect prod-backend-network | grep user-service

# Testi ühenduvust
docker exec -it prometheus-prod wget -O- http://user-service-1:3000/metrics
```

---

## 📈 Resource Usage

**Minimaalsed nõuded:**
- CPU: 4 cores
- RAM: 8GB
- Disk: 20GB

**Teenuste resource limits:**
- Nginx: 256MB RAM, 0.25 CPU
- User Service (x2): 512MB RAM each, 0.5 CPU each
- Todo Service (x2): 1GB RAM each, 1.0 CPU each
- PostgreSQL (x2): 1GB RAM each, 1.0 CPU each
- Prometheus: 1GB RAM, 0.5 CPU
- Grafana: 512MB RAM, 0.25 CPU

**Kokku:** ~6.5GB RAM, ~5.5 CPU cores

---

## 🧹 Puhastamine

```bash
# Peata kõik teenused
docker compose -f docker-compose.prod.yml down

# Eemalda volumes (kui tahad puhast algust)
docker compose -f docker-compose.prod.yml down -v

# Või käsitsi
docker volume rm \
  postgres-user-data-prod \
  postgres-todo-data-prod \
  prometheus-data-prod \
  grafana-data-prod
```

---

## 📚 Täpsemad Juhised

Täielikud sammhaaval juhised leiad:
👉 **[exercises/09-production-readiness.md](../../exercises/09-production-readiness.md)**

See sisaldab:
- SSL/TLS seadistamine (Let's Encrypt)
- Advanced health checks
- Prometheus alerting rules
- Grafana dashboards
- Rolling updates
- Graceful shutdown
- Load testing
- ja palju muud!

---

## ✅ Production Checklist

Enne production deploy'i, kontrolli:

- [ ] **SSL/TLS:** Valid certificate (Let's Encrypt), mitte self-signed
- [ ] **Secrets:** Kasuta secrets management'i (Vault, AWS Secrets Manager)
- [ ] **Backups:** Automaatsed backup'id (daily, tested)
- [ ] **Monitoring:** Prometheus + Grafana + Alerting
- [ ] **Logging:** Centralized logging (ELK, Loki)
- [ ] **High Availability:** Multiple replicas, tested failover
- [ ] **Resource Limits:** CPU ja memory limits seadistatud
- [ ] **Health Checks:** Liveness, readiness, startup probes
- [ ] **Security:** Network policies, least privilege, no secrets in code
- [ ] **Documentation:** Runbooks, incident response playbooks
- [ ] **Disaster Recovery:** Tested backup restore procedure
- [ ] **Performance Testing:** Load testing, stress testing done

---

**Viimane uuendus:** 2025-12-11
**Seotud harjutused:** Lab 2 Harjutus 6, 8
