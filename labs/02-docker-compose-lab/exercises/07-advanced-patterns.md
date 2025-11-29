# Harjutus 7: Edasijõudnute mustrid (Advanced Patterns) (VALIKULINE)

**Eesmärk:** Õppida täiendavaid Docker Compose mustreid ja tõrkeotsingu oskusi

---

## ⭐ VALIKULINE HARJUTUS

See harjutus on **valikuline** ja **sõltumatu** Harjutustest 3-5.

**Eeldused:** Harjutus 1 või 2 läbitud (töötav docker-compose.yml)

**Õpid:**
- Docker Compose profiilid (erinevad teenuste komplektid)
- Andmeköite varundamine ja taastamine (tõrkest taastumine)
- Võrgu tõrkeotsing
- Compose Watch režiim (auto-rebuild arenduses - VALIKULINE)

---

## 📋 Harjutuse ülevaade

Selles harjutuses õpid nelja **täiendavat DevOps mustrit**, mis on kasulikud reaalsetes projektides:

1. **Profiilid (Profiles)** - Käivita erinevaid teenuste komplekte (dev, prod, debug)
2. **Varundamine/Taastamine (Backup/Restore)** - Andmete kaitse ja tõrkest taastumine
3. **Võrgu tõrkeotsing (Network Troubleshooting)** - Debugi võrguprobleeme
4. **Compose Watch** - Automaatne uuesti ehitamine arenduses (2025 parim praktika, valikuline)

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Kasutada Docker Compose **profiile (profiles)**
- ✅ Varundada ja taastada **andmeköite (volume)** andmeid
- ✅ Teostada **veatuvastust (debug)** võrguprobleemide korral
- ✅ Kasutada **silumiskonteinereid (debug containers)**
- ✅ Analüüsida Docker võrke

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

### Osa 1: Docker Compose profiilid (Profiles)

#### Samm 1: Mõista profiilide kontseptsiooni

**Probleem:**
- Tihti tahad development'is käivitada silumistööriistu
- Production'is ei vaja silumistööriistu
- Praegu pead käsitsi kommenteerima teenuseid

**Lahendus: Profiilid**
```bash
# Käivita ainult põhiteenused
docker compose up -d

# Käivita koos silumistööriistadega
docker compose --profile debug up -d
```

#### Samm 2: Lisa silumisteenus

Ava docker-compose.yml:

```bash
vim docker-compose.yml
```

Lisa **silumisteenus** (peale frontend'i, enne volumes:):

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

#### Samm 3: Testi profiile

```bash
# Käivita ilma profiilita (debug-tools EI käivitu)
docker compose up -d
docker compose ps
# Ei näe debug-tools

# Käivita debug profiiliga
docker compose --profile debug up -d
docker compose ps
# Näed debug-tools

# Sisene silumiskonteinerisse
docker compose exec debug-tools bash

# Silumiskonteineri sees:
# 1. Ping teisi teenuseid
ping -c 3 postgres-user
ping -c 3 user-service

# 2. Curl API'sid
curl http://user-service:3000/health
curl http://todo-service:8081/health

# 3. DNS lahendus
nslookup postgres-user
nslookup user-service

# 4. Võrguühenduvus
nc -zv postgres-user 5432
nc -zv user-service 3000

# Välju
exit
```

---

### Osa 2: Andmeköite varundamine ja taastamine (Volume Backup & Restore)

#### Samm 4: Varunda PostgreSQL andmeköide

**Stsenaarium:** Soovid varundada postgres-user-data andmeköidet.

```bash
# 1. Peata user-service (et andmebaas oleks konsistentne)
docker compose stop user-service

# 2. Varunda andmeköide kasutades Alpine konteinerit
docker run --rm \
  -v postgres-user-data:/data \
  -v $(pwd):/backup \
  alpine \
  tar czf /backup/postgres-user-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .

# 3. Kontrolli varukoopia faili
ls -lh postgres-user-backup-*.tar.gz

# Peaks nägema faili (nt 10-20MB)

# 4. Käivita user-service uuesti
docker compose start user-service
```

**Mida juhtus:**
- `-v postgres-user-data:/data` - Haakis andmeköite /data'sse
- `-v $(pwd):/backup` - Haakis praeguse kausta /backup'i
- `tar czf` - Lõi kokkusurutud arhiivi
- `-C /data .` - Arhiveeris kõik /data alt

#### Samm 5: Taasta varukoopia (Testimiseks)

**HOIATUS:** See kustutab praegused andmed! Test ainult arenduses!

```bash
# 1. Peata user-service
docker compose stop user-service

# 2. Kustuta andmeköite andmed (TESTING ONLY!)
docker run --rm \
  -v postgres-user-data:/data \
  alpine \
  sh -c "rm -rf /data/*"

# 3. Taasta varukoopiast
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

# Kui see töötab, taastamine oli edukas!
```

---

### Osa 3: Võrgu tõrkeotsing (Network Troubleshooting)

#### Samm 6: Inspekteeri võrku

```bash
# 1. Vaata võrgu detaile
docker network inspect todo-network

# Analüüsi väljundit:
# - Containers: Kõik ühendatud konteinerid
# - IPv4Address: Iga konteineri IP
# - Gateway: Võrgu gateway IP

# 2. Vaata konkreetse konteineri võrguinfot
docker inspect user-service | grep -A 20 "Networks"

# Näed:
# - IP aadress
# - Gateway
# - Võrgu nimi
```

#### Samm 7: Testi võrguühenduvust

Kasuta debug-tools konteinerit:

```bash
# Käivita silumiskonteiner (kui ei ole juba)
docker compose --profile debug up -d debug-tools

# Sisene silumiskonteinerisse
docker compose exec debug-tools bash

# Testimine:

# 1. Vaata DNS lahendust
dig postgres-user
dig user-service

# 2. Trace route
traceroute postgres-user

# 3. Port scanning
nmap -p 5432 postgres-user
nmap -p 3000 user-service
nmap -p 8081 todo-service

# 4. HTTP päringud
curl -v http://user-service:3000/health
curl -v http://todo-service:8081/health

# 5. PostgreSQL ühenduvus
nc -zv postgres-user 5432
nc -zv postgres-todo 5432

# 6. Bandwidth test (iperf - kui vaja)
# iperf3 -c user-service -p 3000

# Välju
exit
```

**Analüüs:**
- Kui `ping` töötab, võrk on ühendatud
- Kui `curl` töötab, teenus on valmis
- Kui `nc -zv` töötab, port on avatud

---

### Osa 4: Compose Watch - Automaatne ehitus arenduses (VALIKULINE)

**2025 Parim praktika: Kasuta Compose Watch'i kiireks arenduseks!**

Docker Compose Watch (lisatud Compose v2.22+) võimaldab automaatset uuesti ehitamist (rebuild) või failide sünkroonimist, kui lähtekood muutub. See on **super kasulik arenduses!**

#### Samm 8: Mõista Watch režiimi

**Probleem arenduses:**
- Muudad lähtekoodi
- Pead manuaalselt tõmmise uuesti ehitama: `docker compose build`
- Pead teenuse taaskäivitama: `docker compose up -d`
- **Aeglane tagasisideahel!**

**Lahendus: Compose Watch**
```bash
docker compose watch
```

**Automaatselt:**
- Jälgib (watch) lähtekoodi muudatusi
- Ehitab tõmmise uuesti automaatselt
- Taaskäivitab teenuse automaatselt
- **Kiire tagasisideahel!**

#### Samm 9: Konfigureeri Watch režiim

Ava docker-compose.yml ja lisa watch konfiguratsioon User Service'le:

```bash
vim docker-compose.yml
```

Lisa `develop` sektsioon user-service'le (peale `healthcheck:` sektsiooni):

```yaml
  user-service:
    image: user-service:1.0-optimized
    container_name: user-service
    restart: unless-stopped
    # ... existing config ...
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s

    # === WATCH MODE (Development) ===
    develop:
      watch:
        # Variant 1: Rebuild kui lähtekood muutub
        - action: rebuild
          path: ../../apps/backend-nodejs
          ignore:
            - node_modules/
            - .git/

        # Variant 2: Sync specific files (kiirem kui rebuild)
        # - action: sync
        #   path: ../../apps/backend-nodejs/src
        #   target: /app/src

        # Variant 3: Sync + restart (kiirem kui rebuild)
        # - action: sync+restart
        #   path: ../../apps/backend-nodejs/src
        #   target: /app/src
```

**Watch toimingud:**

1. **rebuild** - Täielik uuesti ehitamine (aeglane, aga kindel)
   - Rebuildib tõmmise kui mis tahes fail muutub
   - Taaskäivitab konteineri automaatselt
   - Sobib production-laadseks testimiseks

2. **sync** - Sünkrooni failid ilma ehituseta (kiire!)
   - Kopeerib muudetud failid konteinerisse
   - EI ehita tõmmist uuesti
   - Sobib interpreteeritud keeltele (Node.js, Python)

3. **sync+restart** - Sünkroonimine + restart (keskmine kiirus)
   - Sünkroonib failid + taaskäivitab konteineri
   - Sobib kui rakendus peab restart'ima (konfi muutused)

#### Samm 10: Testi Watch režiimi

```bash
# Käivita watch režiim
docker compose watch

# Oodatud väljund:
# ⦿ watch enabled
# ...watching 1 service

# Nüüd tee muudatus lähtekoodis (TEISES TERMINALIS):
cd ~/labs/apps/backend-nodejs
echo "// Test comment" >> server.js

# Vaata watch terminali:
# Näed automaatset rebuild'i ja restart'i!
# [user-service] rebuilding...
# [user-service] restarting...

# Lõpeta watch režiim: Ctrl+C
```

**Tulemus:**
- ✅ Lähtekoodi muudatus → automaatne rebuild
- ✅ Ei pea manuaalselt käivitama `docker compose build`
- ✅ Kiire arenduse tagasisideahel

#### Bonus: Watch režiim Toote keskkond (Production) vs Arenduskeskkond (Development)

**Arenduskeskkond (Development) (watch režiim):**
```yaml
develop:
  watch:
    - action: sync+restart  # Kiire tagasiside
      path: ./src
      target: /app/src
```

**Toote keskkond (Production) (EI OLE watch'i):**
```yaml
# Ära kasuta watch'i toote keskkonnas (production)!
# develop: sektsiooni ei tohiks toote keskkonna konfis olla
```

**Parim praktika:**
- ✅ Kasuta watch'i ainult arenduses
- ✅ Kasuta `docker-compose.override.yml` watch konfi jaoks
- ❌ ÄRA kasuta watch'i toote keskkonnas (production) (turvalisus + ressursikasutus)

**docker-compose.override.yml näide (dev watch):**
```yaml
# docker-compose.override.yml (local development ainult)
# MÄRKUS: version: '3.8' on valikuline Compose v2's
#version: '3.8'

services:
  user-service:
    develop:
      watch:
        - action: sync+restart
          path: ../../apps/backend-nodejs/src
          target: /app/src
```

**Mida õppisid:**
- ✅ Compose Watch režiim (auto-rebuild)
- ✅ Watch toimingud: rebuild, sync, sync+restart
- ✅ Kiire arenduse tagasisideahel
- ✅ Development vs Production konfi eraldamine

---

## ✅ Kontrolli tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **debug-tools** teenus profiiliga
- [ ] **Varukoopia fail** postgres-user-data andmeköitest
- [ ] **Taastamine** testitud edukalt
- [ ] **Võrgu tõrkeotsingu** oskused:
  - [ ] `docker network inspect`
  - [ ] DNS lahendus (`dig`, `nslookup`)
  - [ ] Pordi ühenduvus (`nc`, `nmap`)
  - [ ] HTTP päringud (`curl`)
- [ ] **Compose Watch** režiim testitud (valikuline)

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas debug-tools teenus on defineeritud?
docker compose config | grep -A 5 "debug-tools"

# 2. Kas varukoopia fail on olemas?
ls -lh postgres-user-backup-*.tar.gz

# 3. Kas võrk on ühendatud?
docker network inspect todo-network | grep "user-service"

# 4. Kas debug-tools saab ühenduda teistega?
docker compose exec debug-tools ping -c 1 postgres-user
```

---

## 🎓 Õpitud mõisted

### Docker Compose profiilid (Profiles):

```yaml
services:
  myservice:
    profiles: ["dev", "debug"]  # Käivitub ainult nende profiilidega
```

**Kasutamine:**
```bash
docker compose --profile dev up -d
docker compose --profile debug up -d
docker compose --profile dev --profile debug up -d  # Mitu profiili
```

### Andmeköite varundamise muster:

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

### Võrgu tõrkeotsingu tööriistad:

- **ping** - ICMP ühenduvus
- **curl** - HTTP päringud
- **nc (netcat)** - TCP/UDP ühenduvus
- **dig/nslookup** - DNS lahendus
- **nmap** - Portide skannimine
- **traceroute** - Marsruudi jälitamine

---

## 💡 Parimad tavad

### 1. Profiilid:

```yaml
# Hea praktika: Defineeri erinevad profiilid
services:
  app:
    profiles: ["prod"]

  debug-tools:
    profiles: ["dev", "debug"]

  test-db:
    profiles: ["test"]
```

### 2. Varundamise graafik:

```bash
# Cron job automaatseks varundamiseks
0 2 * * * /path/to/backup-script.sh  # Iga päev kell 2:00
```

**Varundusskripti näide:**
```bash
#!/bin/bash
# backup-script.sh

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/backups"

# Varunda postgres-user-data
docker run --rm \
  -v postgres-user-data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/postgres-user-$DATE.tar.gz -C /data .

# Kustuta vanad varukoopiad (>7 päeva)
find $BACKUP_DIR -name "postgres-user-*.tar.gz" -mtime +7 -delete
```

### 3. Võrgu silumine:

```bash
# Alati alusta lihtsamatest:
1. docker compose ps     # Kas konteinerid töötavad?
2. docker compose logs   # Kas on vigu?
3. docker network ls     # Kas võrk on olemas?
4. docker network inspect # Kas konteinerid on ühendatud?
5. Debug container       # Teste ping, curl, nc
```

---

## 🐛 Levinud probleemid

### Probleem 1: "debug-tools ei käivitu"

```bash
# Unustasid --profile lipu?
docker compose --profile debug up -d

# Kontrolli, kas profiil on defineeritud
docker compose config | grep -A 5 "debug-tools"
```

### Probleem 2: "Backup fail on 0 bytes"

```bash
# Andmeköide võib olla tühi
docker volume inspect postgres-user-data

# Või vale rada
docker run --rm \
  -v postgres-user-data:/data \
  alpine ls -la /data  # Kontrolli sisu
```

### Probleem 3: "Cannot connect in debug-tools"

```bash
# Kontrolli, kas teenus on samas võrgus
docker network inspect todo-network | grep debug-tools

# Kui ei ole, lisa võrk docker-compose.yml'i:
networks:
  - todo-network
```

---

## 🔗 Järgmine Samm

Õnnitleme! Oled läbinud kõik Labor 2 harjutused!

**Mis saavutasid:**
- ✅ Docker Compose põhitõed (5 harjutust)
- ✅ Edasijõudnute mustrid (6. harjutus - VALIKULINE)
- ✅ Tootmisvalmis seadistused
- ✅ Tõrkeotsingu oskused

**Järgmine Labor:**
- 🎯 **Labor 3:** Kubernetes Põhitõed

---

## 📚 Viited

- [Docker Compose profiles](https://docs.docker.com/compose/profiles/)
- [Docker volume backup](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes)
- [Netshoot tools](https://github.com/nicolaka/netshoot)
- [Network troubleshooting](https://docs.docker.com/network/)

---

**Õnnitleme! Oled õppinud edasijõudnute Docker Compose mustreid! 🎉**
