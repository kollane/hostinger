# 🚀 Kuidas Alustada Laboritöödega

**Serveri olek:** ✅ Valmis laboritöödeks
**Viimane uuendus:** 2025-11-16

---

## 📋 Mis on Server Valmis?

### ✅ Paigaldatud Tarkvara

- **Docker:** 29.0.1 ✅
- **Docker Compose:** v2.40.3 ✅
- **Java:** OpenJDK 17.0.16 ✅
- **Gradle:** 8.5 (wrapper) ✅
- **Node.js:** (paigaldamata - lisatakse Lab 3 käigus)
- **kubectl:** (paigaldamata - lisatakse Lab 3 käigus)
- **Nginx:** 1.24.0 (praegu peatatud) ✅
- **vim:** 9.1 ✅
- **yazi:** 25.5.31 ✅

### ✅ Valmis Rakendused

Kõik rakendused on ehitatud ja valmis:

```
/home/janek/projects/hostinger/labs/apps/
├── backend-nodejs/          # User Service (Node.js + Express)
├── backend-java-spring/     # Todo Service (Java + Spring Boot)
├── frontend/                # Frontend (HTML + JS)
└── docker-compose.yml       # Full stack orchestration
```

**Docker image'id ehitatud:**
- `apps-user-service:latest` (222 MB)
- `apps-todo-service:latest` (475 MB)

### ✅ Dokumentatsioon

- **Laborijuhendid:** `/home/janek/projects/hostinger/labs/`
- **Teoreetilised peatükid:** `/home/janek/projects/hostinger/*.md`
- **Testimisjuhend:** `/home/janek/projects/hostinger/labs/apps/TESTIMINE.md`
- **Lab 4 harjutused:** `/home/janek/projects/hostinger/labs/04-kubernetes-advanced-lab/`

---

## 🎯 Järgmised Sammud - Vali Oma Tee

### Variant 1: Alusta Lab 1'st (Soovitatud)

**Eesmärk:** Õpi Docker põhitõed puhtalt lehelt

```bash
# 1. Mine Lab 1 kataloogi
cd /home/janek/projects/hostinger/labs/01-docker-lab

# 2. Loe ülevaadet
cat README.md

# 3. Alusta Harjutus 1'ga
cd exercises
cat 01-single-container.md
```

**Mis saad teha:**
- Ehitad oma esimese Dockerfile'i
- Käivitad Node.js rakenduse Docker'is
- Õpid käske: `docker build`, `docker run`, `docker ps`
- Lahendused on `01-docker-lab/solutions/` kataloogis

**Kestus:** 4-5 tundi

---

### Variant 2: Alusta Lab 4'st (DNS + Nginx + Kubernetes)

**Eesmärk:** Õpi tootmisse paigaldamist

**Vali õppetee:**

#### Path A - Algaja (6h)
Õpid nii traditsioonilist kui kaasaegset lähenemist:

```bash
cd /home/janek/projects/hostinger/labs/04-kubernetes-advanced-lab
cat README.md

# Alusta DNS + Nginx harjutusest
cd exercises
cat 01-dns-nginx-proxy.md
```

**Järjekord:**
1. DNS + Nginx Reverse Proxy (90 min)
2. Kubernetes Ingress (90 min)
3. SSL/TLS (60 min)
4. Helm Charts (60 min)
5. Autoscaling (60 min)

#### Path B - Kogenud (4h)
Jäta Nginx vahele, alusta kohe Kubernetes'iga:

```bash
cd /home/janek/projects/hostinger/labs/04-kubernetes-advanced-lab/exercises
cat 02-kubernetes-ingress.md
```

---

### Variant 3: Testi Valmis Rakendust

**Eesmärk:** Vaata, kuidas kõik koos töötab

```bash
# 1. Käivita kõik teenused
cd /home/janek/projects/hostinger/labs/apps
docker compose up -d

# 2. Oota 30 sekundit (teenused stardivad)
sleep 30

# 3. Kontrolli staatust
docker compose ps

# 4. Käivita automaatne test
./test-app.sh
```

**Oodatav väljund:**
```
🧪 Todo App Testimine
====================
✅ User Service: UP
✅ Todo Service: UP
✅ Kasutaja olemas
✅ Token saadud
✅ TODO loodud
✅ Leitud X TODO'd
✅ TODO märgitud tehtuks
✅ Statistika: Kokku X, Tehtud X
✅ TODO kustutatud
====================
✅ Kõik testid läbitud!
====================
```

**Kui testid läbitud:**
- Rakendus töötab ✅
- Backend API'd töötavad ✅
- Autentimine töötab ✅

**Peata teenused:**
```bash
docker compose down
```

---

## 📚 Labori Struktuur

### Lab 1: Docker Põhitõed ✅ (Valmis)
```
01-docker-lab/
├── README.md
├── exercises/
│   ├── 01-single-container.md      # 60 min
│   ├── 02-multi-container.md       # 60 min
│   ├── 03-networking.md            # 60 min
│   ├── 04-volumes.md               # 60 min
│   └── 05-optimization.md          # 60 min
└── solutions/
    └── backend-nodejs/
        ├── Dockerfile
        ├── Dockerfile.optimized
        └── .dockerignore
```

**Õpieesmärgid:**
- Docker image'te ehitamine
- Konteinerite käivitamine
- Võrgustik ja volume'id
- Multi-stage builds

---

### Lab 2: Docker Compose ⏳ (Framework valmis)
```
02-docker-compose-lab/
├── README.md
├── exercises/           # TO DO - sisu lisatakse
└── solutions/           # TO DO
```

**Õpieesmärgid:**
- docker-compose.yml kirjutamine
- Multi-container orchestration
- Environment variables
- Dependencies ja health checks

---

### Lab 3: Kubernetes Basics ⏳ (Framework valmis)
```
03-kubernetes-basics-lab/
├── README.md
├── exercises/           # TO DO
└── manifests/           # TO DO
```

**Eeldused:**
- kubectl paigaldamine
- Minikube VÕI k3s paigaldamine

**Õpieesmärgid:**
- Pods, Deployments, Services
- ConfigMaps, Secrets
- PersistentVolumes

---

### Lab 4: Kubernetes Advanced + Production ✅ (Valmis)
```
04-kubernetes-advanced-lab/
├── README.md                     # Path A/B juhend ✅
├── exercises/
│   ├── 01-dns-nginx-proxy.md    # 90 min ✅
│   ├── 02-kubernetes-ingress.md # 90 min ✅
│   ├── 03-ssl-tls.md            # 60 min (TO DO)
│   ├── 04-helm-charts.md        # 60 min (TO DO)
│   └── 05-autoscaling.md        # 60 min (TO DO)
├── solutions/
│   ├── nginx/
│   │   └── kirjakast.cloud.conf ✅
│   ├── kubernetes/
│   │   └── app-ingress.yaml     ✅
│   └── helm/                    # TO DO
└── comparison.md                # Nginx vs Ingress ✅
```

**Õpieesmärgid:**
- DNS + Reverse Proxy (traditsiooniline)
- Kubernetes Ingress (kaasaegne)
- SSL/TLS sertifikaadid
- Helm package manager
- Horizontal Pod Autoscaling

---

### Lab 5: CI/CD ⏳ (Framework valmis)
```
05-cicd-lab/
├── README.md
└── exercises/           # TO DO
```

**Õpieesmärgid:**
- GitHub Actions workflows
- Automated testing
- Docker build & push
- Kubernetes deployment

---

### Lab 6: Monitoring & Logging ⏳ (Framework valmis)
```
06-monitoring-logging-lab/
├── README.md
└── exercises/           # TO DO
```

**Õpieesmärgid:**
- Prometheus metrics
- Grafana dashboards
- Log aggregation
- Alerting

---

## 🛠️ Kasulikud Käsud

### Docker

```bash
# Vaata kõiki konteinereid
docker ps -a

# Vaata image'eid
docker images

# Vaata volume'eid
docker volume ls

# Vaata network'e
docker network ls

# Puhasta süsteem
docker system prune -a  # ETTEVAATUST: Kustutab kõik kasutamata ressursid!
```

### Docker Compose

```bash
# Käivita stack
docker compose up -d

# Vaata logisid
docker compose logs -f

# Vaata staatust
docker compose ps

# Peata stack
docker compose down

# Peata JA kustuta volume'id
docker compose down -v
```

### Nginx

```bash
# Käivita Nginx
sudo systemctl start nginx

# Peata Nginx
sudo systemctl stop nginx

# Vaata staatust
sudo systemctl status nginx

# Testi konfiguratsiooni
sudo nginx -t

# Taaslae konfiguratsioon
sudo systemctl reload nginx
```

### Failide Vaatamine

```bash
# vim (preferred)
vim failinimi

# yazi (file manager)
yazi

# cat (lihtne vaatamine)
cat failinimi

# less (suuremad failid)
less failinimi
```

---

## 📖 Soovitatud Õpitee

### Täielik DevOps Kursus (40-50 tundi)

**Nädal 1-2: Docker (Lab 1-2)**
1. Loe Peatükk 9: Docker Sissejuhatus
2. Tee Lab 1: Docker Basics (5h)
3. Loe Peatükk 13: Docker Compose
4. Tee Lab 2: Docker Compose (5h)

**Nädal 3-4: Kubernetes (Lab 3-4)**
1. Loe Peatükk 16-19: Kubernetes
2. Paigalda kubectl ja k3s
3. Tee Lab 3: Kubernetes Basics (5h)
4. Tee Lab 4: Kubernetes Advanced (6h VÕI 4h)

**Nädal 5: CI/CD (Lab 5)**
1. Loe Peatükk 23: CI/CD
2. Tee Lab 5: GitHub Actions (5h)

**Nädal 6: Monitoring (Lab 6)**
1. Loe Peatükk 24: Monitoring
2. Tee Lab 6: Prometheus + Grafana (5h)

**Kogu aeg: 35-45 tundi**

---

### Kiire DevOps Intro (10-15 tundi)

**Path B läbi kõik labrid:**

1. **Lab 1:** Docker Basics (5h)
   - Harjutused 1, 2, 5 (jäta 3-4 vahele)

2. **Lab 2:** Docker Compose (2h)
   - Ainult põhiharjutus

3. **Lab 4:** Kubernetes Ingress (4h)
   - Path B (alusta harjutus 02'st)
   - Jäta SSL ja Helm vahele

**Kogu aeg: 11 tundi**

---

## 🐛 Kui Midagi Läheb Valesti

### Probleem: Docker ei tööta

```bash
# Kontrolli Docker daemon'i
docker ps

# Kui ei tööta, restart
sudo systemctl restart docker
```

### Probleem: Port on juba kasutuses

```bash
# Leia, mis kasutab porti
sudo netstat -tlnp | grep :3000

# VÕI
sudo lsof -i :3000

# Peata teenus
sudo kill <PID>
```

### Probleem: Pole piisavalt ruumi

```bash
# Kontrolli ruumi
df -h

# Kustuta kasutamata Docker ressursid
docker system prune -a

# Kustuta vana build cache
docker builder prune -a
```

### Probleem: Unustasid parooli

```bash
# PostgreSQL reset
docker exec -it <container> psql -U postgres
# ALTER USER postgres WITH PASSWORD 'uus-parool';
```

---

## 📁 Tähtsamad Asukohad

```
/home/janek/projects/hostinger/
├── ALUSTA-SIIT.md              # See fail
├── PROGRESS-STATUS.md          # Mis on tehtud
├── XX-Topic.md                 # Teoreetilised peatükid (1-12)
└── labs/
    ├── README.md               # Labrite ülevaade
    ├── 00-LAB-RAAMISTIK.md     # Labrite struktuur
    ├── apps/                   # Valmis rakendused
    │   ├── TESTIMINE.md        # Kuidas testida
    │   └── test-app.sh         # Automaatne test
    ├── 01-docker-lab/          # Lab 1 ✅
    ├── 02-docker-compose-lab/  # Lab 2 ⏳
    ├── 03-kubernetes-basics-lab/ # Lab 3 ⏳
    ├── 04-kubernetes-advanced-lab/ # Lab 4 ✅
    ├── 05-cicd-lab/            # Lab 5 ⏳
    └── 06-monitoring-logging-lab/ # Lab 6 ⏳
```

---

## 🎓 Õppematerjalid

### Teoreetilised Peatükid (✅ Valmis)

1. ✅ VPS Sissejuhatus
2. ✅ Ubuntu Põhikäsud
3. ✅ PostgreSQL Paigaldus (External)
4. ✅ PostgreSQL Paigaldus (Containerized)
5. ✅ Git Põhitõed
6. ✅ Node.js + Express Setup
7. ✅ REST API Design
8. ✅ JWT Autentimine
9. ✅ Docker Sissejuhatus
10. ✅ Frontend Basics
11. ✅ Testing Strategies
12. ✅ Security Best Practices

### Laboriharjutused

- ✅ **Lab 1:** Täielikult valmis (5 harjutust + lahendused)
- ✅ **Lab 4:** 2/5 harjutust valmis + võrdlusdokument
- ⏳ **Lab 2-3, 5-6:** Framework valmis, sisu lisatakse

---

## 🚀 Kiire Alustamine

**Kui tahad KOHE alustada:**

```bash
# 1. Mine Lab 1 kataloogi
cd /home/janek/projects/hostinger/labs/01-docker-lab

# 2. Loe README
cat README.md | less

# 3. Alusta esimese harjutusega
cd exercises
vim 01-single-container.md

# 4. Kui jääd kinni, vaata lahendust
cd ../solutions/backend-nodejs
ls -la
cat Dockerfile
```

**Edu!** 🎉

---

**Küsimused?**
- Vaata `/home/janek/projects/hostinger/labs/README.md`
- Kontrolli `/home/janek/projects/hostinger/PROGRESS-STATUS.md`
- Loe `/home/janek/projects/hostinger/labs/apps/TESTIMINE.md`

---

**Viimane uuendus:** 2025-11-16
**Server:** kirjakast (93.127.213.242)
**Kasutaja:** janek
