# 📊 Serveri Praegune Olek

**Viimane uuendus:** 2025-11-16 13:00
**Olek:** ✅ Valmis laboritöödeks

---

## ✅ Paigaldatud

- Docker 29.0.1
- Docker Compose v2.40.3
- Java 17 (OpenJDK)
- Gradle 8.5 (wrapper)
- Nginx 1.24.0
- vim 9.1
- yazi 25.5.31

## ⏳ Pole Veel Paigaldatud

Paigaldatakse labrite käigus:
- Node.js 18 (Lab 3)
- kubectl (Lab 3)
- k3s / minikube (Lab 3)
- PostgreSQL client (Lab 3)

---

## 🐳 Docker

**Image'id:**
- apps-user-service:latest (222 MB)
- apps-todo-service:latest (475 MB)
- postgres:16-alpine
- nginx:alpine

**Volume'id:**
- apps_user-data (olemas, tühi)
- apps_todo-data (olemas, tühi)

**Konteinerid:** Kõik peatatud ✅

---

## 🌐 Nginx

**Olek:** Peatatud ✅

**Konfiguratsioon olemas:**
- /etc/nginx/sites-available/kirjakast.cloud
- Reverse proxy User Service + Todo Service + Frontend

**Käivitamiseks:**
```bash
sudo systemctl start nginx
```

---

## 📂 Rakendused

**Asukoht:** `/home/janek/projects/hostinger/labs/apps/`

### User Service (Node.js)
- ✅ Kood valmis
- ✅ Docker image ehitatud
- ✅ Andmebaasi setup skript olemas
- ⏸️ Pole käivitatud

### Todo Service (Java Spring Boot)
- ✅ Kood valmis
- ✅ Docker image ehitatud
- ✅ Andmebaasi setup skript olemas
- ⏸️ Pole käivitatud

### Frontend
- ✅ HTML/CSS/JS valmis
- ✅ API endpoint'id parandatud (/api/todos)
- ⏸️ Pole käivitatud

---

## 🎯 Testimine

**Test skript:** `/home/janek/projects/hostinger/labs/apps/test-app.sh`

**Käivitamine:**
```bash
cd /home/janek/projects/hostinger/labs/apps
docker compose up -d
sleep 30
./test-app.sh
docker compose down
```

**Oodatav tulemus:** Kõik 8 testi läbitud ✅

---

## 📚 Labrid

### Lab 1: Docker Basics
- ✅ Täielikult valmis
- 5 harjutust + lahendused
- Kestus: 5 tundi

### Lab 2-3, 5-6
- ⏳ Framework valmis
- Sisu lisatakse hiljem

### Lab 4: Kubernetes Advanced
- ✅ README valmis (Path A/B)
- ✅ Harjutus 01: DNS + Nginx ✅
- ✅ Harjutus 02: Kubernetes Ingress ✅
- ✅ Lahendused + võrdlusdokument ✅
- ⏳ Harjutused 03-05 (TO DO)

---

## 🔐 Ligipääs

**SSH:**
```bash
ssh janek@kirjakast
ssh janek@93.127.213.242
```

**Domeen:**
- kirjakast.cloud → 93.127.213.242 (DNS seadistatud)

**Testimine:**
```bash
# curl VPS-is
curl http://localhost:3000/health
curl http://kirjakast.cloud/api/users

# Brauser
http://kirjakast.cloud (kui Nginx + Docker Compose töötavad)
```

---

## 📋 Järgmised Sammud

### Laborite Tegemine

1. **Alusta Lab 1'st:**
   ```bash
   cd /home/janek/projects/hostinger/labs/01-docker-lab
   cat README.md
   ```

2. **VÕI alusta Lab 4'st:**
   ```bash
   cd /home/janek/projects/hostinger/labs/04-kubernetes-advanced-lab
   cat README.md
   ```

3. **VÕI testi valmis rakendust:**
   ```bash
   cd /home/janek/projects/hostinger/labs/apps
   docker compose up -d
   ./test-app.sh
   ```

### Labrite Täiendamine

**TO DO:**
- Lab 2: Docker Compose harjutused
- Lab 3: Kubernetes Basics harjutused
- Lab 4: Harjutused 03-05 (SSL, Helm, Autoscaling)
- Lab 5: CI/CD harjutused
- Lab 6: Monitoring harjutused

---

## 🛠️ Hooldus

**Puhastamine:**
```bash
# Peata kõik konteinerid
docker stop $(docker ps -aq)

# Kustuta kasutamata ressursid
docker system prune -a

# Kustuta volume'id (ETTEVAATUST!)
docker volume prune
```

**Backup:**
```bash
# Backup kood
tar -czf ~/backup-labs-$(date +%Y%m%d).tar.gz /home/janek/projects/hostinger/labs/

# Backup Docker image'id
docker save apps-user-service:latest | gzip > ~/user-service.tar.gz
docker save apps-todo-service:latest | gzip > ~/todo-service.tar.gz
```

---

**Vaata ka:**
- `/home/janek/projects/hostinger/ALUSTA-SIIT.md` - Kuidas alustada
- `/home/janek/projects/hostinger/PROGRESS-STATUS.md` - Mis on valmis
- `/home/janek/projects/hostinger/labs/apps/TESTIMINE.md` - Testimisjuhend

---

**Server:** kirjakast.cloud (93.127.213.242)
**OS:** Ubuntu 24.04.3 LTS
**Kasutaja:** janek
**Ressursid:** 7.8 GB RAM, 2 CPU, 96 GB disk
