# Harjutus 3: Docker Networking

**Kestus:** 45 minutit
**Eesmärk:** Loo custom network ja ühenda containerid proper networking'uga

---

## 🎯 Õpieesmärgid

- ✅ Luua custom Docker network
- ✅ Käivitada containerid samas network'is
- ✅ Kasutada DNS hostname resolution
- ✅ Inspekteerida network konfiguratsiooni
- ✅ Isoleerida teenused network'idega

---

## 📝 Sammud

### Samm 1: Puhasta Keskkond

```bash
# Stopp ja eemalda vanad containerid
docker stop user-service postgres-users
docker rm user-service postgres-users
```

### Samm 2: Loo Custom Network

```bash
# Loo bridge network
docker network create app-network

# Vaata network'e
docker network ls

# Inspekteeri
docker network inspect app-network
```

### Samm 3: Käivita Containerid Samas Network'is

```bash
# PostgreSQL
docker run -d \
  --name postgres-users \
  --network app-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  postgres:15-alpine

# User Service
docker run -d \
  --name user-service \
  --network app-network \
  -p 3000:3000 \
  -e DB_HOST=postgres-users \
  -e DB_PORT=5432 \
  -e DB_NAME=user_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-secret-key \
  user-service:1.0
```

**Võrra:** Nüüd saad kasutada container nime `postgres-users` hostname'ina!

### Samm 4: Testi DNS Resolution

```bash
# Sisene User Service containerisse
docker exec -it user-service sh

# Testi DNS
ping postgres-users    # Peaks töötama!
nslookup postgres-users
exit
```

### Samm 5: Inspekteeri Network

```bash
# Vaata, mis containerid on network'is
docker network inspect app-network

# Peaks näitama kahte containerit
```

### Samm 6: Testi Rakendust

```bash
curl http://localhost:3000/health
# Peaks näitama: "database": "connected"
```

---

## ✅ Kontrolli

- [ ] `app-network` on loodud
- [ ] Mõlemad containerid töötavad samas network'is
- [ ] DNS resolution töötab (container nimi = hostname)
- [ ] User Service ühendub PostgreSQL'iga
- [ ] API vastab korrektselt

---

## 🎓 Õpitud

- Custom bridge networks
- DNS-based service discovery
- Network isolation
- Container hostname resolution

**Järgmine:** [Harjutus 4: Volumes](04-volumes.md)
