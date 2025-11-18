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
docker stop todo-service postgres-todo
docker rm todo-service postgres-todo
```

### Samm 2: Loo Custom Network

```bash
# Loo bridge network
docker network create todo-network

# Vaata network'e
docker network ls

# Inspekteeri
docker network inspect todo-network
```

### Samm 3: Käivita Containerid Samas Network'is

```bash
# PostgreSQL
docker run -d \
  --name postgres-todo \
  --network todo-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=todo_service_db \
  postgres:16-alpine

# Todo Service
docker run -d \
  --name todo-service \
  --network todo-network \
  -p 8081:8081 \
  -e DB_HOST=postgres-todo \
  -e DB_PORT=5432 \
  -e DB_NAME=todo_service_db \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -e JWT_SECRET=my-secret-key \
  todo-service:1.0
```

**Võrra:** Nüüd saad kasutada container nime `postgres-todo` hostname'ina!

### Samm 4: Testi DNS Resolution

```bash
# Sisene Todo Service containerisse
docker exec -it todo-service sh

# Testi DNS (kui ping on installitud alpine image'is)
# ping postgres-todo    # Peaks töötama!
# nslookup postgres-todo
exit
```

### Samm 5: Inspekteeri Network

```bash
# Vaata, mis containerid on network'is
docker network inspect todo-network

# Peaks näitama kahte containerit
```

### Samm 6: Testi Rakendust

```bash
curl http://localhost:8081/health
# Peaks näitama: "status": "UP"
```

---

## ✅ Kontrolli

- [x] `todo-network` on loodud
- [x] Mõlemad containerid töötavad samas network'is
- [x] DNS resolution töötab (container nimi = hostname)
- [x] Todo Service ühendub PostgreSQL'iga
- [x] API vastab korrektselt

---

## 🎓 Õpitud

- Custom bridge networks
- DNS-based service discovery
- Network isolation
- Container hostname resolution

**Järgmine:** [Harjutus 4: Volumes](04-volumes.md)
