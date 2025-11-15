# Harjutus 4: Docker Volumes

**Kestus:** 45 minutit
**Eesmärk:** Säilita andmed volumes'iga ja õpi data persistence

---

## 🎯 Õpieesmärgid

- ✅ Luua named volumes
- ✅ Mount volume containerisse
- ✅ Testida data persistence
- ✅ Backup ja restore
- ✅ Inspekteerida volumes

---

## 📝 Sammud

### Samm 1: Loo Named Volume

```bash
# Loo volume PostgreSQL jaoks
docker volume create postgres-users-data

# Vaata volumes
docker volume ls

# Inspekteeri
docker volume inspect postgres-users-data
```

### Samm 2: Käivita PostgreSQL Volume'iga

```bash
# Stopp ja eemalda vana
docker stop postgres-users
docker rm postgres-users

# Käivita uuesti volume'iga
docker run -d \
  --name postgres-users \
  --network app-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -v postgres-users-data:/var/lib/postgresql/data \
  postgres:15-alpine
```

### Samm 3: Seadista Andmebaas ja Lisa Andmeid

```bash
# Loo tabel
docker exec -it postgres-users psql -U postgres -d user_service_db -c "
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);"

# Lisa testandmed
docker exec -it postgres-users psql -U postgres -d user_service_db -c "
INSERT INTO users (name, email, password) VALUES
('John Doe', 'john@example.com', 'hashed_password'),
('Jane Smith', 'jane@example.com', 'hashed_password');"

# Kontrolli
docker exec -it postgres-users psql -U postgres -d user_service_db -c "SELECT * FROM users;"
```

### Samm 4: Testi Data Persistence

```bash
# Stopp container
docker stop postgres-users

# Eemalda container (MITTE volume!)
docker rm postgres-users

# Käivita uuesti SAMA volume'iga
docker run -d \
  --name postgres-users \
  --network app-network \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=user_service_db \
  -v postgres-users-data:/var/lib/postgresql/data \
  postgres:15-alpine

# Oota 5 sekundit
sleep 5

# Kontrolli - andmed peaksid olema alles!
docker exec -it postgres-users psql -U postgres -d user_service_db -c "SELECT * FROM users;"
```

**Tulemus:** Andmed on alles! 🎉

### Samm 5: Backup (Bonus)

```bash
# Backup volume
docker run --rm \
  -v postgres-users-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/postgres-backup.tar.gz -C /data .

# Kontrolli
ls -lh postgres-backup.tar.gz
```

### Samm 6: Vaata Volume Kasutust

```bash
# Volume info
docker volume inspect postgres-users-data

# Volume suurus
docker system df -v
```

---

## ✅ Kontrolli

- [ ] Volume `postgres-users-data` on loodud
- [ ] PostgreSQL kasutab volume'i
- [ ] Andmed jäävad alles container restart järel
- [ ] Backup on loodud

---

## 🎓 Õpitud

- Named volumes
- Volume mounting
- Data persistence
- Backup strategies
- Volume management

**Järgmine:** [Harjutus 5: Optimization](05-optimization.md)
