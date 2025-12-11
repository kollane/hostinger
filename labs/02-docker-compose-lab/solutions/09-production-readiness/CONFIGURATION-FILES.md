# Konfiguratsioonifailide Asukoht

## ℹ️ Täielikud Konfiguratsioonifailid

Kõik täielikud konfiguratsioonifailid (Nginx, Prometheus, Grafana, Docker Compose) on kirjeldatud **harjutuse juhendis**:

👉 **[exercises/09-production-readiness.md](../../exercises/09-production-readiness.md)**

## 📋 Failide Nimekiri

### Docker Compose
- `docker-compose.prod.yml` - **Harjutuse juhend, Samm 2.1** (read 505-785)

### Nginx
- `nginx/nginx.conf` - **Harjutuse juhend, Samm 1.3** (read 232-372)
- `nginx/html/index.html` - **Harjutuse juhend, Samm 1.4** (read 385-495)

### Prometheus
- `prometheus/prometheus.yml` - **Harjutuse juhend, Samm 3.1** (read 825-890)
- `prometheus/alerts.yml` - **Harjutuse juhend, Samm 3.2** (read 900-975)

### Grafana
- `grafana/provisioning/datasources/prometheus.yml` - **Harjutuse juhend, Samm 4.1** (read 990-1005)
- `grafana/provisioning/dashboards/dashboard.yml` - **Harjutuse juhend, Samm 4.2** (read 1015-1030)

## 🚀 Kiire Alustamine

Selle asemel, et kopeerida kõiki faile siia, **järgi harjutuse juhendi samme** (1-7), mis:
- Selgitavad iga faili eesmärki
- Pakuvad step-by-step juhiseid
- Sisaldavad täielikke konfiguratsioonide näiteid
- Annavad troubleshooting'u nõuandeid

## 📝 Märkus

Solutions kaust sisaldab:
- ✅ `README.md` - Quick start ja ülevaade
- ✅ `.env.prod.example` - Environment variables template
- ✅ `nginx/ssl/generate-ssl.sh` - SSL certificate generator
- ✅ `scripts/init-databases.sh` - Database initialization script
- ✅ See fail - Viited täielikele konfiguratsioonidele

**Täielikud konfiguratsioonifailid:**
Kopeeri exercises/09-production-readiness.md failist järgides juhendi samme.

**Põhjus:**
- Vältida duplikatsiooni
- Juhend jääb ainsaks tõe allikaks (single source of truth)
- Kasutajad õpivad faile käsitsi seadistama (pedagoogiline väärtus)

