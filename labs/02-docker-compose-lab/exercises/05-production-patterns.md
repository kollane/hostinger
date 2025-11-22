# Harjutus 5: Production Patterns

**Kestus:** 45 minutit
**Eesmärk:** Konfigureeri production-ready Docker Compose seadistused

---

## 📋 Ülevaade

Selles harjutuses õpid konfigureerima Docker Compose stack'i production keskkonna jaoks. Rakendad parimaid praktikaid: resource limits, scaling, restart policies, logging ja security.

**Development vs Production:**
- **Development:** Kiire iteratsioon, debug, palju logisid
- **Production:** Stabiilsus, turvalisus, resource management, vähem logisid

---

## 🎯 Õpieesmärgid

Peale selle harjutuse läbimist oskad:

- ✅ Konfigureerida resource limits (CPU, memory)
- ✅ Scaleerida teenuseid (replicas)
- ✅ Seadistada restart policies
- ✅ Optimeerida health checks
- ✅ Konfigureerida logging
- ✅ Rakendada security best practices
- ✅ Luua production-ready docker-compose.prod.yml

---

## ⚠️ Enne Alustamist: Kontrolli Eeldusi

**Veendu, et Harjutus 4 on läbitud:**

```bash
# 1. Kas stack töötab?
cd compose-project
docker compose ps

# 2. Kas Liquibase teenused exitisid edukalt?
docker compose ps | grep liquibase
# Peaks nägema: Exited (0)
```

**Kui midagi puudub:**
- 🔗 Mine tagasi [Harjutus 4](04-database-migrations.md)

**✅ Kui kõik ülalpool on OK, võid jätkata!**

---

## 📝 Sammud

### Samm 1: Loo Production Compose Fail (15 min)

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

version: '3.8'

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

### Samm 2: Mõista Production Seadistusi (10 min)

#### Resource Limits:

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
- Predictable performance

#### Replicas:

```yaml
deploy:
  replicas: 2  # Käivita 2 koopiat
```

**Tähendus:**
- Docker Compose käivitab 2 konteinerit sama image'iga
- Load balancing (liiklus jaotatakse)
- High availability (kui üks crashib, teine töötab)

**TÄHTIS:** Production'is kasutatakse tavaliselt Kubernetes'i scaling'u, mitte Docker Compose replicas'e.

#### Restart Policy:

```yaml
deploy:
  restart_policy:
    condition: on-failure  # Restart ainult kui crashib
    delay: 5s             # Oota 5s enne restart'i
    max_attempts: 3       # Maksimaalselt 3 restart'i
    window: 120s          # 120s akna jooksul
```

#### Logging:

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

### Samm 3: Käivita Production Mode's (10 min)

```bash
# Peata development stack
docker compose down

# Käivita production mode's
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

**TÄHTIS:** Replicas töötavad ainult Swarm mode's või Kubernetes'es. Docker Compose ei toeta täielikult load balancing'ut ilma Swarm'ita.

**Swarm mode testimine (optional):**

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

### Samm 4: Kontrolli Resource Kasutust (5 min)

```bash
# Vaata resource kasutust
docker stats

# Väljund näitab:
# CONTAINER       CPU %   MEM USAGE / LIMIT   MEM %
# user-service    0.5%    128MB / 256MB       50%
# todo-service    1.2%    256MB / 512MB       50%
# postgres-user   0.3%    200MB / 512MB       39%
```

**Analüüs:**
- Kõik konteinerid on limits'te piires
- Memory kasutus on mõistlik
- CPU kasutus on väike (idle)

---

### Samm 5: Testi Health Checks (5 min)

Health checks on juba docker-compose.yml's defineeritud:

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
# Vaata health status'e
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

### Samm 6: Optimiseeri Logging (5 min)

**Vaata praeguseid loge:**

```bash
# Vaata kui palju ruumi logid kasutavad
docker inspect user-service | grep LogPath

# Vaata log faili suurust
sudo du -h /var/lib/docker/containers/*/user-service*-json.log
```

**Production logging best practices:**

1. **Piira log faili suurust** - Vältimaks kettaruumi täitumist
2. **Roteerideeriminelogged** - Vanad logid kustutatakse
3. **Keskne logging** - Saada logid centralized system'i (Elasticsearch, Loki)
4. **Log level** - Production'is INFO või WARN, mitte DEBUG

---

### Samm 7: Security Hardening (5 min)

Lisa security seadistused docker-compose.prod.yml'i:

```bash
vim docker-compose.prod.yml
```

Lisa igale teenusele (service):

```yaml
  user-service:
    # ... existing config
    security_opt:
      - no-new-privileges:true  # Väldi privilege escalation
    read_only: false  # Kui võimalik, kasuta true
    tmpfs:
      - /tmp  # Temporary failide jaoks
```

**Security best practices:**
- ✅ Run as non-root user (juba tehtud optimized image's)
- ✅ Read-only filesystem (kus võimalik)
- ✅ Drop capabilities
- ✅ No privilege escalation
- ✅ Scan images for vulnerabilities

---

## ✅ Kontrolli Tulemusi

Peale selle harjutuse läbimist peaksid omama:

- [ ] **docker-compose.prod.yml** production seadistustega
- [ ] **Resource limits** defineeritud (CPU, memory)
- [ ] **Restart policies** konfigureeritud
- [ ] **Logging** optimeeritud (rotation, size limits)
- [ ] **Security** hardened
- [ ] **Stack töötab** production mode's
- [ ] **Health checks** toimivad

---

## 🧪 Testimine

### Kontroll-käsud:

```bash
# 1. Kas production stack töötab?
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps

# 2. Kas resource limits on rakendatud?
docker inspect user-service | grep -A 10 "Resources"

# 3. Kas logging on konfigureeritud?
docker inspect user-service | grep -A 5 "LogConfig"

# 4. Kas health checks töötavad?
docker compose ps | grep healthy
```

---

## 🎓 Õpitud Mõisted

### Production vs Development:

| Aspekt | Development | Production |
|--------|-------------|------------|
| Restart Policy | `always` või `unless-stopped` | `on-failure` (limited) |
| Resource Limits | Ei ole | Defined (CPU, memory) |
| Logging | Verbose (DEBUG) | Minimal (INFO, WARN) |
| Log Rotation | Ei ole | Enabled (max-size, max-file) |
| Replicas | 1 | 2+ (high availability) |
| Volume Mounts | Source code (hot reload) | Ei ole |
| Security | Relaxed | Hardened |

### Docker Compose Deploy:

```yaml
deploy:
  replicas: 2          # Mitu instance'i
  resources:           # Resource limits
    limits:
      cpus: '1.0'
      memory: 512M
  restart_policy:      # Restart behavior
    condition: on-failure
```

**TÄHTIS:** `deploy` võti töötab täielikult ainult Docker Swarm või Kubernetes'es!

---

## 💡 Parimad Tavad

### 1. Resource Management:

```yaml
# Määra alati limits JA reservations
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M
    reservations:
      cpus: '0.5'
      memory: 256M
```

### 2. Logging:

```yaml
# Roteeri logisid, piira suurust
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### 3. Health Checks:

```yaml
# Määra mõistlikud väärtused
healthcheck:
  interval: 30s     # Mitte liiga tihti
  timeout: 3s       # Piisavalt aega
  retries: 3        # Mitte liiga palju
  start_period: 40s # Anna aega käivitumiseks
```

### 4. Restart Policy:

```yaml
# Production: on-failure (limited)
deploy:
  restart_policy:
    condition: on-failure
    max_attempts: 3  # Väldi infinite restart loop
```

### 5. Security:

```yaml
# Hardened security
security_opt:
  - no-new-privileges:true
read_only: true  # Kui võimalik
```

---

## 🐛 Levinud Probleemid

### Probleem 1: "Replicas ei tööta docker compose up'iga"

```bash
# docker-compose.prod.yml sisaldab:
deploy:
  replicas: 2

# Aga käivitades:
docker compose -f docker-compose-full.yml -f docker-compose.prod.yml up -d

# Näed ainult 1 konteinerit, mitte 2
docker compose ps
# NAME            STATUS
# user-service    Up
```

**Põhjus:**
- `deploy.replicas` töötab AINULT Docker Swarm või Kubernetes'es
- `docker compose up` käsk IGNOREERIB `replicas` seadistust
- See on Docker Compose piirang

**Lahendus 1: Kasuta docker compose --scale (Development/Testing)**

```bash
# Käivita 2 user-service instance'i
docker compose up -d --scale user-service=2

# Kontrolli
docker compose ps
# NAME                 STATUS
# user-service-1       Up
# user-service-2       Up
```

**Probleem --scale'iga:**
- ❌ Ei saa kasutada `container_name` (konflikt)
- ❌ Port mapping konfliktib (nt. mõlemad tahavad 3000:3000)

**Lahendus 2: Kasuta Docker Swarm (Production)**

```bash
# Initseeri Swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose-full.yml -c docker-compose.prod.yml myapp

# Kontrolli
docker stack services myapp
# NAME                  REPLICAS
# myapp_user-service    2/2
# myapp_todo-service    2/2
```

**Lahendus 3: Kasuta Kubernetes (Soovitatud Production)**

```yaml
# Kubernetes Deployment (Lab 3)
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: user-service
```

**MÄRKUS:** Lab 3 õpetab Kubernetes'e, kus `replicas` töötab ideaalselt!

---

### Probleem 2: "OOM Killed" (Out of Memory)

```bash
# Konteiner crashib memory limiti tõttu
docker logs user-service | grep "OOM"

# Lahendus: Suurenda memory limit'i
deploy:
  resources:
    limits:
      memory: 1G  # Suurenda 512M -> 1G
```

### Probleem 2: "CPU Throttling"

```bash
# Konteiner on väga aeglane
docker stats

# Näed: CPU % on alati 100% (throttled)

# Lahendus: Suurenda CPU limit'i
deploy:
  resources:
    limits:
      cpus: '2.0'  # Suurenda 1.0 -> 2.0
```

### Probleem 3: "Disk Full" (Logid)

```bash
# Kettaruum on täis
df -h

# Vaata log faile
sudo du -sh /var/lib/docker/containers/*/

# Lahendus: Puhasta vanad logid
docker system prune -a --volumes

# Ja konfigureeri rotation
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
- ✅ Haldad salajaseid .env failidega
- ✅ Automatiseeris database migration'id Liquibase'iga
- ✅ Konfigureeris production-ready seadistused

**Järgmine Labor:**
- 🎯 **Labor 3:** Kubernetes Põhitõed
  - Konverteeri docker-compose.yml → Kubernetes manifests
  - Deploy stack Kubernetes cluster'isse
  - Kasuta Liquibase InitContainer'eid
  - Skaleerri teenuseid Kubernetes'es

---

## 📚 Viited

- [Docker Compose deploy](https://docs.docker.com/compose/compose-file/deploy/)
- [Resource constraints](https://docs.docker.com/config/containers/resource_constraints/)
- [Logging drivers](https://docs.docker.com/config/containers/logging/configure/)
- [Security best practices](https://docs.docker.com/engine/security/)

---

**Õnnitleme! Labor 2 on lõpetatud! 🎉**

**Valmis Kubernetes'e migreerumiseks Lab 3's!**
