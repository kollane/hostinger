# Mitme Keskkonna Seadistused (Multi-Environment)

## 📚 Harjutuse Lihtsustus

**Selles harjutuses:**
- ✅ 3 keskkonda: Local Dev (VALIKULINE), Test, Production
- ✅ Sama DB parool (`postgres`) TEST ja PROD jaoks
- ✅ ERINEV JWT Secret TEST vs PROD

**🏢 Reaalses Production Keskkonnas:**
- Eraldi serverid (test.company.com, prod.company.com)
- Eraldi volume'id → ERINEVAD paroolid!

---

## Keskkondade Ülevaade

| Keskkond | Fail | Kasutus | Pordid avatud? |
|----------|------|---------|----------------|
| **Local Dev** | `docker-compose.override.yml` | Automaatne (VALIKULINE) | ✅ Kõik localhost'ile |
| **Test** | `docker-compose.test.yml` | Debug, testimine | ✅ Kõik localhost'ile |
| **Production** | `docker-compose.prod.yml` | Live deploy | ❌ Ainult frontend (80) |

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

### 3️⃣ Production Keskkond

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

| Aspekt | Local Dev | Test | Production |
|--------|-----------|------|------------|
| **Andmebaasi pordid** | ✅ 5432, 5433 | ✅ 5432, 5433 | ❌ Isoleeritud |
| **Backend pordid** | ✅ 3000, 8081 | ✅ 3000, 8081 | ❌ Sisevõrk |
| **Frontend port** | ✅ 8080 | ✅ 8080 | ✅ 80 (443 SSL) |
| **DB Paroolid** | `postgres` | `postgres` | `postgres` (harjutus¹) |
| **JWT Secret** | Harjutus 3 | Base64, 256-bit | ERINEV hash |
| **Database network** | Internal: false | Internal: false | Internal: true |
| **Resource limits** | ❌ Pole | ❌ Pole | ✅ Strict |
| **Logging level** | DEBUG | DEBUG | WARN |
| **Restart policy** | unless-stopped | unless-stopped | always |

**¹ Harjutuse lihtsustus:** Sama DB parool (postgres), sest kasutame samu volume'id.
**Reaalses elus:** Eraldi serverid → eraldi volume'id → ERINEVAD paroolid!

---

## Alias'ed (Valikuline)

Lisa `~/.bashrc` või `~/.zshrc` faili:

```bash
# Docker Compose aliased
alias dc-test='docker-compose -f docker-compose.yml -f docker-compose.test.yml --env-file .env.test'
alias dc-prod='docker-compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod'
```

**Kasutamine:**
```bash
dc-test up -d
dc-test logs -f
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

3. **Production:**
   - Kasuta `.env.prod` faili (ÄRA commit'i saladusi!)
   - SSL/TLS (HTTPS)
   - Monitoring (Prometheus + Grafana)
   - Backup strategy (regulaarsed pg_dump'id)

---

## Viited

- **Base config:** `docker-compose.yml`
- **Test override:** `docker-compose.test.yml`
- **Production override:** `docker-compose.prod.yml`
- **Local dev override:** `docker-compose.override.yml` (git ignore, VALIKULINE)

---

**Viimane uuendus:** 2025-12-11
