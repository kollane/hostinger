# Mitme Keskkonna Seadistused

See projekt toetab **4 erinevat keskkonda**:

| Keskkond | Fail | Kasutus | Pordid avatud? |
|----------|------|---------|----------------|
| **Local Dev** | `docker-compose.override.yml` | Automaatne (git ignore) | ✅ Kõik localhost'ile |
| **Test** | `docker-compose.test.yml` | Manuaalne käivitamine | ✅ Kõik localhost'ile |
| **Prelive** | `docker-compose.prelive.yml` | Prod-sarnane testimine | ❌ Ainult frontend |
| **Production** | `docker-compose.prod.yml` | Live deploy | ❌ Ainult frontend |

---

## Kiire Kasutamine

### 1️⃣ Local Development (Automaatne)

```bash
# Käivita (laeb automaatselt docker-compose.override.yml)
docker-compose up -d

# Ühenda andmebaasidega:
# - User DB:  localhost:5432, user=postgres, password=postgres
# - Todo DB:  localhost:5433, user=postgres, password=postgres

# Seiska
docker-compose down
```

**Märkus:** `docker-compose.override.yml` on `.gitignore`'is (ainult lokaalse arenduse jaoks)

---

### 2️⃣ Test Keskkond

```bash
# Käivita
docker-compose -f docker-compose.yml -f docker-compose.test.yml up -d

# Kontrolli
docker ps
docker-compose -f docker-compose.yml -f docker-compose.test.yml logs -f

# Testi API'd
curl http://localhost:3000/health  # User Service
curl http://localhost:8081/health  # Todo Service
curl http://localhost:8080         # Frontend

# Ühenda andmebaasidega (DBeaver/pgAdmin)
# - User DB:  localhost:5432
# - Todo DB:  localhost:5433

# Seiska
docker-compose -f docker-compose.yml -f docker-compose.test.yml down
```

---

### 3️⃣ Prelive Keskkond (Prod-sarnane)

```bash
# Käivita
docker-compose -f docker-compose.yml -f docker-compose.prelive.yml up -d

# Kontrolli resource kasutust
docker stats

# Testi frontend'i (ainult see on avatud!)
curl http://localhost:8080

# API testid läbi frontend'i
curl http://localhost:8080/api/users/health

# ❌ Andmebaasid ei ole kättesaadavad host'ilt (isoleeritud)

# Seiska
docker-compose -f docker-compose.yml -f docker-compose.prelive.yml down
```

---

### 4️⃣ Production Keskkond

```bash
# Käivita environment variables'iga
docker-compose -f docker-compose.yml -f docker-compose.prod.yml \
  --env-file .env.prod up -d

# Või ilma env failita (kasutab docker-compose.yml vaikeväärtusi)
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Kontrolli health status
docker ps  # Vaata (healthy) märgistust

# Resource monitoring
docker stats

# Logid (ainult viimased 100 rida)
docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs --tail=100

# Graceful shutdown
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

# ⚠️ OHTLIK: Kustuta ka volumes (andmekadu!)
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down -v
```

---

## Keskkondade Erinevused

| Aspekt | Local Dev | Test | Prelive | Production |
|--------|-----------|------|---------|------------|
| **Andmebaasi pordid** | ✅ 5432, 5433 | ✅ 5432, 5433 | ❌ Isoleeritud | ❌ Isoleeritud |
| **Backend pordid** | ✅ 3000, 8081 | ✅ 3000, 8081 | ❌ Sisevõrk | ❌ Sisevõrk |
| **Frontend port** | ✅ 8080 | ✅ 8080 | ✅ 8080 | ✅ 80 (443 SSL) |
| **Database network** | Internal: false | Internal: false | Internal: true | Internal: true |
| **Resource limits** | ❌ Pole | ✅ Moderate | ✅ Strict | ✅ Very strict |
| **Logging level** | DEBUG | DEBUG | INFO | WARN |
| **Restart policy** | unless-stopped | unless-stopped | unless-stopped | always |
| **Health checks** | 30s interval | 30s interval | 15s interval | 15s interval |

---

## Alias'ed (Valikuline)

Lisa `~/.bashrc` või `~/.zshrc` faili:

```bash
# Docker Compose aliased
alias dc-test='docker-compose -f docker-compose.yml -f docker-compose.test.yml'
alias dc-prelive='docker-compose -f docker-compose.yml -f docker-compose.prelive.yml'
alias dc-prod='docker-compose -f docker-compose.yml -f docker-compose.prod.yml'
```

**Kasutamine:**
```bash
dc-test up -d
dc-prelive logs -f
dc-prod down
```

---

## Troubleshooting

### Probleem: "Service is unhealthy"

```bash
# Vaata logisid
docker-compose -f docker-compose.yml -f docker-compose.test.yml logs <service-name>

# Kontrolli health check'i
docker inspect <container-name> | grep -A 10 Health
```

### Probleem: "Port is already allocated"

```bash
# Kontrolli, mis kasutab porti
sudo lsof -i :5432
sudo lsof -i :8080

# Seiska konkureerivad konteinerid
docker ps
docker stop <container-id>
```

### Probleem: "Cannot connect to database"

```bash
# TEST/DEV keskkonnas: Kontrolli, kas pordid on avatud
docker ps  # Vaata PORTS veergu

# PRELIVE/PROD keskkonnas: Andmebaasid ON isoleeritud (see on OK!)
# Rakendused pääsevad neile ligi sisevõrgu (database-network) kaudu
```

---

## Best Practices

1. **Local Dev:**
   - Kasuta `docker-compose.override.yml` (automaatne)
   - ÄRA commit'i seda git'i (on `.gitignore`'is)

2. **Test:**
   - Ava kõik pordid debugging'uks
   - Kasuta DBeaver/pgAdmin'i andmebaasidega ühendamiseks

3. **Prelive:**
   - Testi production-sarnases keskkonnas
   - Resource limit'id peavad olema seatud
   - Andmebaasid isoleeritud (nagu prod'is)

4. **Production:**
   - Kasuta `.env.prod` faili (ÄRA commit'i saladusi!)
   - SSL/TLS (HTTPS)
   - Monitoring (Prometheus + Grafana)
   - Backup strategy (regulaarsed pg_dump'id)

---

## Viited

- **Base config:** `docker-compose.yml`
- **Test override:** `docker-compose.test.yml`
- **Prelive override:** `docker-compose.prelive.yml`
- **Production override:** `docker-compose.prod.yml`
- **Local dev override:** `docker-compose.override.yml` (git ignore)

---

**Viimane uuendus:** 2025-12-11
