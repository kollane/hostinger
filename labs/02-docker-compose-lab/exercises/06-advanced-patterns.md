# Harjutus 6: Advanced Patterns (VALIKULINE)

**Kestus:** 30 minutit
**Eesmärk:** Õppida täiendavaid Docker Compose pattern'e ja troubleshooting oskusi

---

## ⭐ VALIKULINE HARJUTUS

See harjutus on **valikuline** ja **sõltumatu** Harjutustest 3-5.

**Eeldused:** Harjutus 1 või 2 läbitud (töötav docker-compose.yml)

**Õpid:**
- Docker Compose profiles (erinevad teenuste komplektid)
- Volume backup & restore (disaster recovery)
- Network troubleshooting (debug tööriistad)

---

## 📋 Ülevaade

Selles harjutuses õpid kolme **täiendavat DevOps pattern'i**, mis on kasulikud real-world projektides:

1. **Profiles** - Käivita erinevaid teenuste komplekte (dev, prod, debug)
2. **Backup/Restore** - Andmete kaitse ja disaster recovery
3. **Network Troubleshooting** - Debug network probleeme

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Kasutada Docker Compose profile'e
- ✅ Backup'ida ja restore'ida volume andmeid
- ✅ Debuggida network probleeme
- ✅ Kasutada debug containereid
- ✅ Analüüsida Docker network'e

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Harjutus 1 või 2 on läbitud:**

```bash
# Kontrolli, kas docker-compose.yml on olemas
cd compose-project
ls -la docker-compose.yml

# Kontrolli, kas stack töötab
docker compose ps
# Peaks nägema vähemalt 4 teenust
```

**Kui midagi puudub:**
- 🔗 Mine tagasi [Harjutus 1](01-compose-basics.md)

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📝 Sammud

### Osa 1: Docker Compose Profiles (10 min)

#### Samm 1: Mõista Profiles Kontseptsiooni (2 min)

**Probleem:**
- Tihti tahad development'is käivitada debug tools'e
- Production'is ei vaja debug tools'e
- Praegu pead käsitsi kommenteerima teenuseid (services)

**Lahendus: Profiles**
```bash
# Käivita ainult põhiteenused
docker compose up -d

# Käivita koos debug tools'ega
docker compose --profile debug up -d
```

#### Samm 2: Lisa Debug Teenus (3 min)

Ava docker-compose.yml:

```bash
vim docker-compose.yml
```

Lisa **debug teenus** (peale frontend'i, enne volumes:):

```yaml
  # ==========================================================================
  # Debug Tools - Network Troubleshooting (VALIKULINE)
  # ==========================================================================
  debug-tools:
    image: nicolaka/netshoot
    container_name: debug-tools
    profiles: ["debug"]  # Käivitub ainult --profile debug'iga
    networks:
      - todo-network
    command: ["sleep", "infinity"]  # Jääb töötama
    restart: "no"
```

Salvesta.

#### Samm 3: Testi Profile'e (5 min)

```bash
# Käivita ilma profile'ita (debug-tools EI käivitu)
docker compose up -d
docker compose ps
# Ei näe debug-tools

# Käivita debug profile'iga
docker compose --profile debug up -d
docker compose ps
# Näed debug-tools

# Sisene debug containerisse
docker compose exec debug-tools bash

# Debug container sees:
# 1. Ping teisi teenuseid
ping -c 3 postgres-user
ping -c 3 user-service

# 2. Curl API'sid
curl http://user-service:3000/health
curl http://todo-service:8081/health

# 3. DNS resolution
nslookup postgres-user
nslookup user-service

# 4. Network connectivity
nc -zv postgres-user 5432
nc -zv user-service 3000

# Välju
exit
```

---

### Osa 2: Volume Backup & Restore (10 min)

#### Samm 4: Backup PostgreSQL Volume (5 min)

**Stsenaarium:** Soovid backup'ida postgres-user-data volume'i.

```bash
# 1. Peata user-service (et andmebaas oleks konsistentne)
docker compose stop user-service

# 2. Backup volume kasutades Alpine containerit
docker run --rm \
  -v postgres-user-data:/data \
  -v $(pwd):/backup \
  alpine \
  tar czf /backup/postgres-user-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .

# 3. Kontrolli backup faili
ls -lh postgres-user-backup-*.tar.gz

# Peaks nägema faili (nt 10-20MB)

# 4. Käivita user-service uuesti
docker compose start user-service
```

**Mida juhtus:**
- `-v postgres-user-data:/data` - Mount'is volume /data'sse
- `-v $(pwd):/backup` - Mount'is praegune kaust /backup'i
- `tar czf` - Lõi compressed archive
- `-C /data .` - Archive'is kõik /data alt

#### Samm 5: Restore Backup (Testimiseks) (5 min)

**HOIATUS:** See kustutab praegused andmed! Test ainult arenduses!

```bash
# 1. Peata user-service
docker compose stop user-service

# 2. Kustuta volume andmed (TESTING ONLY!)
docker run --rm \
  -v postgres-user-data:/data \
  alpine \
  sh -c "rm -rf /data/*"

# 3. Restore backup'ist
docker run --rm \
  -v postgres-user-data:/data \
  -v $(pwd):/backup \
  alpine \
  tar xzf /backup/postgres-user-backup-*.tar.gz -C /data

# 4. Käivita user-service
docker compose start user-service

# 5. Testi, kas andmed on tagasi
docker compose logs user-service | grep "Database connected"

# 6. Testi API'd
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Kui see töötab, restore oli edukas!
```

---

### Osa 3: Network Troubleshooting (10 min)

#### Samm 6: Inspect Network (5 min)

```bash
# 1. Vaata network detaile
docker network inspect todo-network

# Analüüsi väljundit:
# - Containers: Kõik ühendatud konteinerid
# - IPv4Address: Iga konteineri IP
# - Gateway: Network gateway IP

# 2. Vaata konkreetse konteineri network info
docker inspect user-service | grep -A 20 "Networks"

# Näed:
# - IP address
# - Gateway
# - Network name
```

#### Samm 7: Test Network Connectivity (5 min)

Kasuta debug-tools containerit:

```bash
# Käivita debug container (kui ei ole juba)
docker compose --profile debug up -d debug-tools

# Sisene debug containerisse
docker compose exec debug-tools bash

# Testimine:

# 1. Vaata DNS resolution'i
dig postgres-user
dig user-service

# 2. Trace route
traceroute postgres-user

# 3. Port scanning
nmap -p 5432 postgres-user
nmap -p 3000 user-service
nmap -p 8081 todo-service

# 4. HTTP requests
curl -v http://user-service:3000/health
curl -v http://todo-service:8081/health

# 5. PostgreSQL connectivity
nc -zv postgres-user 5432
nc -zv postgres-todo 5432

# 6. Bandwidth test (iperf - kui vaja)
# iperf3 -c user-service -p 3000

# Välju
exit
```

**Analüüs:**
- Kui `ping` töötab, network on ühendatud
- Kui `curl` töötab, service on valmis
- Kui `nc -zv` töötab, port on avatud

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **debug-tools** teenus profile'iga
- [ ] **Backup fail** postgres-user-data volume'ist
- [ ] **Restore** testitud edukalt
- [ ] **Network troubleshooting** oskused:
  - [ ] `docker network inspect`
  - [ ] DNS resolution (`dig`, `nslookup`)
  - [ ] Port connectivity (`nc`, `nmap`)
  - [ ] HTTP requests (`curl`)

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas debug-tools teenus on defineeritud?
docker compose config | grep -A 5 "debug-tools"

# 2. Kas backup fail on olemas?
ls -lh postgres-user-backup-*.tar.gz

# 3. Kas network on ühendatud?
docker network inspect todo-network | grep "user-service"

# 4. Kas debug-tools saab ühenduda teistega?
docker compose exec debug-tools ping -c 1 postgres-user
```

---

## 🎓 Õpitud Mõisted

### Docker Compose Profiles:

```yaml
services:
  myservice:
    profiles: ["dev", "debug"]  # Käivitub ainult need profile'idega
```

**Kasutamine:**
```bash
docker compose --profile dev up -d
docker compose --profile debug up -d
docker compose --profile dev --profile debug up -d  # Mitu profile'i
```

### Volume Backup Pattern:

```bash
# Backup
docker run --rm \
  -v <volume-name>:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz -C /data .

# Restore
docker run --rm \
  -v <volume-name>:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/backup.tar.gz -C /data
```

### Network Troubleshooting Tools:

- **ping** - ICMP connectivity
- **curl** - HTTP requests
- **nc (netcat)** - TCP/UDP connectivity
- **dig/nslookup** - DNS resolution
- **nmap** - Port scanning
- **traceroute** - Route tracing

---

## 💡 Parimad Tavad

### 1. Profiles:

```yaml
# Hea praktika: Defineeri erinevad profile'd
services:
  app:
    profiles: ["prod"]

  debug-tools:
    profiles: ["dev", "debug"]

  test-db:
    profiles: ["test"]
```

### 2. Backup Schedule:

```bash
# Cron job automaatseks backup'iks
0 2 * * * /path/to/backup-script.sh  # Iga päev kell 2:00
```

**Backup script näide:**
```bash
#!/bin/bash
# backup-script.sh

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/backups"

# Backup postgres-user-data
docker run --rm \
  -v postgres-user-data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/postgres-user-$DATE.tar.gz -C /data .

# Kustuta vanad backup'id (>7 päeva)
find $BACKUP_DIR -name "postgres-user-*.tar.gz" -mtime +7 -delete
```

### 3. Network Debugging:

```bash
# Alati alusta lihtsamatest:
1. docker compose ps     # Kas konteinerid töötavad?
2. docker compose logs   # Kas on vigu?
3. docker network ls     # Kas network on olemas?
4. docker network inspect # Kas konteinerid on ühendatud?
5. Debug container       # Teste ping, curl, nc
```

---

## 🐛 Levinud Probleemid

### Probleem 1: "debug-tools ei käivitu"

```bash
# Unustasid --profile flagi?
docker compose --profile debug up -d

# Kontrolli, kas profile on defineeritud
docker compose config | grep -A 5 "debug-tools"
```

### Probleem 2: "Backup fail on 0 bytes"

```bash
# Volume võib olla tühi
docker volume inspect postgres-user-data

# Või vale path
docker run --rm \
  -v postgres-user-data:/data \
  alpine ls -la /data  # Kontrolli sisu
```

### Probleem 3: "Cannot connect in debug-tools"

```bash
# Kontrolli, kas teenus on samas network'is
docker network inspect todo-network | grep debug-tools

# Kui ei ole, lisa network docker-compose.yml'i:
networks:
  - todo-network
```

---

## 🔗 Järgmine Samm

Õnnitleme! Oled läbinud kõik Labor 2 harjutused!

**Mis saavutasid:**
- ✅ Docker Compose põhitõed (5 harjutust)
- ✅ Advanced patterns (6. harjutus - VALIKULINE)
- ✅ Production-ready seadistused
- ✅ Troubleshooting oskused

**Järgmine Labor:**
- 🎯 **Labor 3:** Kubernetes Põhitõed

---

## 📚 Viited

- [Docker Compose profiles](https://docs.docker.com/compose/profiles/)
- [Docker volume backup](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)
- [Netshoot tools](https://github.com/nicolaka/netshoot)
- [Network troubleshooting](https://docs.docker.com/network/)

---

**Õnnitleme! Oled õppinud advanced Docker Compose pattern'e! 🎉**
