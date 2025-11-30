# Harjutus 6: Tootmiskeskkonna mustrid (Production Patterns)

**Eesmärk:** Konfigureeri tootmiskõlbulik Docker Compose seadistused

---

## 📋 Harjutuse ülevaade

Selles harjutuses õpid konfigureerima Docker Compose stack'i tootmiskeskkonna jaoks. Rakendad parimaid praktikaid: ressursilimiidid, skaleerimine, taaskäivituspoliitika, logimine ja turvalisus.

**Arenduskeskkond (Development) vs Toote keskkond (Production):**

- **Arenduskeskkond (Development):** Kiire iteratsioon, veatuvastus (debug), palju logisid
- **Toote keskkond (Production):** Stabiilsus, turvalisus, ressursside haldus, vähem logisid

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Konfigureerida **ressursilimiite (resource limits)** (CPU, mälu)
- ✅ **Skaleerida (scale)** teenuseid (**koopiaid (replicas)**)
- ✅ Seadistada **taaskäivituspoliitikaid (restart policies)**
- ✅ Optimeerida **tervisekontrolle (health checks)**
- ✅ Konfigureerida **logimist (logging)**
- ✅ Rakendada **turvalisuse (security)** parimaid praktikaid
- ✅ Luua **tootmiskõlbulik (production-ready)** `docker-compose.prod.yml`

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Harjutus 5 on läbitud:**

```bash
# 1. Kas stack töötab?
cd compose-project
docker compose ps

# 2. Kas Liquibase teenused väljusid edukalt?
docker compose ps | grep liquibase
# Peaks nägema: Exited (0)
```

**Kui midagi puudub:**

- 🔗 Mine tagasi [Harjutus 5](05-database-migrations.md)

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📝 Sammud

### Samm 1: Loo Production Compose fail

Loo eraldi fail production seadistustele:

```bash
cd compose-project
vim docker-compose.prod.yml
```

Lisa järgmine sisu:

```yaml
# ==========================================================================
# Docker Compose - Production Configuration
# ==========================================================================
# Kasutamine:
#   docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
# ==========================================================================

# MÄRKUS: Docker Compose v2 (2025)
# version: '3.8' on VALIKULINE Compose v2's!
# Võid selle ära jätta - Compose v2 kasutab automaatselt uusimat versiooni.
#version: '3.8'

services:
  # ==========================================================================
  # PostgreSQL - Production Settings
  # ==========================================================================
  postgres-user:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  postgres-todo:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # ==========================================================================
  # User Service - Production Settings
  # ==========================================================================
  user-service:
    deploy:
      replicas: 2  # Scale to 2 instances
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
    environment:
      NODE_ENV: production
      LOG_LEVEL: info  # Vähem logisid kui dev's
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
    # Remove host volume mounts (no hot reload in prod)
    volumes: []

  # ==========================================================================
  # Todo Service - Production Settings
  # ==========================================================================
  todo-service:
    deploy:
      replicas: 2  # Scale to 2 instances
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
    environment:
      SPRING_PROFILES_ACTIVE: prod
      LOGGING_LEVEL_ROOT: WARN  # Vähem logisid
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"

  # ==========================================================================
  # Frontend - Production Settings
  # ==========================================================================
  frontend:
    deploy:
      replicas: 1  # Nginx on väga kerge, 1 piisab
      resources:
        limits:
          cpus: '0.25'
          memory: 128M
        reservations:
          cpus: '0.1'
          memory: 64M
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "3"
```

Salvesta: `Esc`, siis `:wq`, `Enter`

---

### Samm 2: Mõista production seadistusi

#### Ressursilimiidid (Resource Limits):

```yaml
deploy:
  resources:
    limits:        # Maksimaalne kasutus
      cpus: '1.0'  # 1 CPU core
      memory: 512M # 512MB RAM
    reservations:  # Garanteeritud minimaalne
      cpus: '0.5'
      memory: 256M
```

**Tähendus:**

- **limits:** Konteiner ei saa kasutada rohkem kui see
- **reservations:** Docker garanteerib vähemalt nii palju

**Miks oluline:**

- Üks konteiner ei saa kasutada kõiki ressursse (resource starvation)
- Ennustatav jõudlus

#### Koopiad (Replicas):

```yaml
deploy:
  replicas: 2  # Käivita 2 koopiat
```

**Tähendus:**

- Docker Compose käivitab 2 konteinerit sama tõmmisega (docker image)
- Koormuse jaotamine (load balancing)
- Kõrge käideldavus (high availability)

**TÄHTIS:** Production'is kasutatakse tavaliselt Kubernetes'i skaleerimist, mitte Docker Compose replicas'e.

#### Taaskäivituspoliitika (Restart Policy):

```yaml
deploy:
  restart_policy:
    condition: on-failure  # Restart ainult kui krahhib
    delay: 5s             # Oota 5s enne restart'i
    max_attempts: 3       # Maksimaalselt 3 restart'i
    window: 120s          # 120s akna jooksul
```

#### Logimine (Logging):

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"  # Maksimaalne faili suurus
    max-file: "3"    # Hoia 3 roteeritud faili
```

**Tähendab:**

- Logid salvestatakse JSON vormingus
- Iga logifail max 10MB
- Kui 10MB täis, roteeritakse (uus fail)
- Hoitakse max 3 faili (30MB kokku)

---

### Samm 3: Käivita production mode'is

```bash
# Peata development stack
docker compose down

# Käivita production mode'is
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Kontrolli staatust
docker compose ps

# Peaks nägema 2x user-service ja 2x todo-service
# NAME                         STATUS
# user-service-1               Up
# user-service-2               Up
# todo-service-1               Up
# todo-service-2               Up
```

**TÄHTIS:** `replicas` töötavad ainult Swarm mode's või Kubernetes'es. Docker Compose ei toeta täielikult koormuse jaotamist ilma Swarm'ita.

**Swarm mode testimine (valikuline):**

```bash
# Enable Swarm mode
docker swarm init

# Deploy stack Swarm'is
docker stack deploy -c docker-compose.yml -c docker-compose.prod.yml todo-stack

# Vaata teenuseid
docker service ls

# Vaata replicas'e
docker service ps todo-stack_user-service
```

---

### Samm 4: Kontrolli ressursikasutust

```bash
# Vaata ressursikasutust
docker stats

# Väljund näitab:
# CONTAINER       CPU %   MEM USAGE / LIMIT   MEM %
# user-service    0.5%    128MB / 256MB       50%
# todo-service    1.2%    256MB / 512MB       50%
# postgres-user   0.3%    200MB / 512MB       39%
```

**Analüüs:**

- Kõik konteinerid on limitide piires
- Mälukasutus on mõistlik
- CPU kasutus on väike (idle)

---

### Samm 5: Testi tervisekontrolle

Rakenduse tervisekontrollid (Health Checks) on juba docker-compose.yml's defineeritud:

```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
  interval: 30s    # Kontrolli iga 30s
  timeout: 3s      # Max 3s ootamine
  retries: 3       # 3 ebaõnnestumist
  start_period: 40s # Oota 40s enne esimest kontroll
```

**Testi:**

```bash
# Vaata tervise staatust
docker compose ps

# Kõik peaksid olema "healthy"

# Simulatsioon: peata user-service
docker compose stop user-service

# Vaata logisid
docker compose logs

# Restart automaatselt (restart policy)
# Peale ~5s peaks user-service taaskäivituma
```

---

### Samm 6: Optimeeri logimine

**Vaata praeguseid loge:**

```bash
# Vaata kui palju ruumi logid kasutavad
docker inspect user-service | grep LogPath

# Vaata logifaili suurust
sudo du -h /var/lib/docker/containers/*/user-service*-json.log
```

**Tootmiskeskkonna logimise parimad tavad:**

1. **Piira logifaili suurust** - Vältimaks kettaruumi täitumist
2. **Logide roteerimine** - Vanad logid kustutatakse
3. **Keskne logimine** - Saada logid tsentraliseeritud süsteemi (Elasticsearch, Loki)
4. **Logi tase** - Production'is INFO või WARN, mitte DEBUG

---

### Samm 7: Turvalisuse tugevdamine (Hardening)

Lisa turvaseadistused docker-compose.prod.yml'i:

```bash
vim docker-compose.prod.yml
```

Lisa igale teenusele:

```yaml
  user-service:
    # ... existing config
    security_opt:
      - no-new-privileges:true  # Väldi privileegide eskaleerumist
    read_only: false  # Kui võimalik, kasuta true
    tmpfs:
      - /tmp  # Ajutiste failide jaoks
```

**Turvalisuse parimad praktikad:**

- ✅ Käita mitte-juurkasutajana (juba tehtud optimeeritud tõmmises)
- ✅ Kirjutuskaitstud failisüsteem (kus võimalik)
- ✅ Loobu ebavajalikest võimekustest (Drop capabilities)
- ✅ Väldi privileegide eskaleerumist
- ✅ Skanni tõmmiseid turvaaukude suhtes

---

## ✅ Kontrolli tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **docker-compose.prod.yml** production seadistustega
- [ ] **Ressursilimiidid** defineeritud (CPU, mälu)
- [ ] **Taaskäivituspoliitikad** konfigureeritud
- [ ] **Logimine** optimeeritud (rotatsioon, suuruse limiidid)
- [ ] **Turvalisus** tugevdatud
- [ ] **Stack töötab** production mode'is
- [ ] **Tervisekontrollid** toimivad

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas production stack töötab?
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps

# 2. Kas ressursilimiidid on rakendatud?
docker inspect user-service | grep -A 10 "Resources"

# 3. Kas logimine on konfigureeritud?
docker inspect user-service | grep -A 5 "LogConfig"

# 4. Kas tervisekontrollid töötavad?
docker compose ps | grep healthy
```

---

## 🎓 Õpitud mõisted

### Toote keskkond (Production) vs Arenduskeskkond (Development):

| Aspekt | Arenduskeskkond (Development) | Toote keskkond (Production) |
|--------|-------------|------------|
| Taaskäivituspoliitika | `always` või `unless-stopped` | `on-failure` (piiratud) |
| Ressursilimiidid | Ei ole | Määratud (CPU, mälu) |
| Logimine | Jutukas (DEBUG/veatuvastus) | Minimaalne (INFO, WARN) |
| Logide rotatsioon | Ei ole | Lubatud (max-size, max-file) |
| Koopiad | 1 | 2+ (kõrge käideldavus) |
| Andmeköite haakimine | Lähtekood (hot reload) | Ei ole |
| Turvalisus | Lõdva | Tugevdatud |

### Docker Compose Deploy:

```yaml
deploy:
  replicas: 2          # Mitu instantsi
  resources:           # Ressursilimiidid
    limits:
      cpus: '1.0'
      memory: 512M
  restart_policy:      # Taaskäivitus
    condition: on-failure
```

**TÄHTIS:** `deploy` võti töötab täielikult ainult Docker Swarm või Kubernetes'es!

---

## 💡 Parimad tavad

### 1. Ressursihaldus:

```yaml
# Määra alati limiidid JA reserveeringud
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 256M
```

### 2. Logimine:

```yaml
# Roteeri logisid, piira suurust
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### 3. Tervisekontrollid:

```yaml
# Määra mõistlikud väärtused
healthcheck:
```

### 4. Taaskäivituspoliitika:

```yaml
# Production: on-failure (limited)
deploy:
  restart_policy:
    condition: on-failure
    max_attempts: 3  # Väldi lõpmatut restart tsüklit
```

### 5. Turvalisus:

```yaml
# Tugevdatud turvalisus
security_opt:
  - no-new-privileges:true
read_only: true  # Kui võimalik
```

---

## 🐛 Levinud probleemid

### Probleem 1: "OOM Killed" (Out of Memory)

```bash
# Konteiner krahhib mälulimiidi tõttu
docker logs user-service | grep "OOM"

# Lahendus: Suurenda mälulimiiti
deploy:
  resources:
    limits:
      memory: 1G  # Suurenda 512M -> 1G
```

### Probleem 2: "CPU Throttling"

```bash
# Konteiner on väga aeglane
docker stats

# Näed: CPU % on alati 100% (piiratud)

# Lahendus: Suurenda CPU limiiti
deploy:
  resources:
    limits:
      cpus: '2.0'  # Suurenda 1.0 -> 2.0
```

### Probleem 3: "Disk Full" (Logid)

```bash
# Kettaruum on täis
df -h

# Vaata logifaile
sudo du -sh /var/lib/docker/containers/*/

# Lahendus: Puhasta vanad logid
docker system prune -a --volumes

# Ja konfigureeri rotatsioon
logging:
  options:
    max-size: "5m"  # Vähenda 10m -> 5m
```

---

## 🔗 Järgmine Samm

Õnnitleme! Oled läbinud kõik 5 harjutust!

**Mis saavutasid:**

- ✅ Konverteris Lab 1 → docker-compose.yml
- ✅ Lisasid Frontend teenuse (5 teenust)
- ✅ Haldad saladusi .env failidega
- ✅ Automatiseerisid andmebaasi migratsioonid Liquibase'iga
- ✅ Konfigureerisid tootmiskõlbulikud (production-ready) seadistused

**Järgmine Labor:**

- 🎯 **Labor 3:** Kubernetes Põhitõed
  - Konverteeri docker-compose.yml → Kubernetes manifestideks
  - Paigalda (deploy) stack Kubernetes klastrisse
  - Kasuta Liquibase Init-konteinereid
  - Skaleeri teenuseid Kubernetes'es

---

## 📚 Viited

- [Docker Compose deploy](https://docs.docker.com/compose/compose-file/deploy/)
- [Resource constraints](https://docs.docker.com/config/containers/resource_constraints/)
- [Logging drivers](https://docs.docker.com/config/containers/logging/configure/)
- [Security best practices](https://docs.docker.com/engine/security/)

---

**Õnnitleme! Labor 2 on lõpetatud! 🎉**

**Valmis Kubernetes'e migreerumiseks Lab 3's!**
