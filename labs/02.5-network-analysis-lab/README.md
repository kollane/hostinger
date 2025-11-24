# Lab 2.5: Võrgu Analüüs ja Testimine (Network Analysis & Testing)

⚠️ **SEE LAB ON VALIKULINE (Optional)** ⚠️

**Kestus:** 3 tundi
**Tase:** 🔷 Advanced/Valikuline
**Eeldus:** Lab 2 lõpetatud

---

## 📋 Ülevaade

See lab õpetab Docker võrkude professionaalset analüüsi ja testimist. Õpid kasutama tööstuse standardseid diagnostic tööriistu, süstemaatilist testimise metoodikat ja automatiseeritud skripte.

**Oluline:** See lab **KASUTAB** Lab 2 loodud docker-compose stack'i. Sa ei loo uut keskkonda, vaid analsüüsid ja testid olemasolevat.

---

## 🤔 Kas See Lab On Minu Jaoks?

### ✅ Tee see lab, kui:

- Soovid **süvendada Docker võrkude teadmisi** professionaalsele tasemele
- Plaanid töötada **DevOps/SRE rollis**, kus network debugging on oluline
- Huvi pakub **professionaalne võrgu analüüs** ja diagnostika
- Soovid õppida **automatiseeritud testimist** ja skriptimist
- Oled huvitatud **security auditing'ust** ja compliance'ist
- Soovid mõista **network performance** analüüsi
- Vajad **troubleshooting oskusi** tootmiskeskkondades

### ⏭️ Jäta vahele, kui:

- Soovid **kiiresti Kubernetes'e jõuda** (Lab 3 on järgmine)
- Docker võrkude **põhitõed on sulle piisavad**
- **Aeg on piiratud** ja soovid järgmiste labidega jätkata
- Pole huvitatud **deep-dive** analüüsist
- Professionaalsed diagnostic tööriistad **ei ole prioriteet**

---

## ❓ Kas See On Lab 3 Eeldus?

### ❌ **EI!** Lab 3 (Kubernetes Basics) saab alustada otse pärast Lab 2'd.

Lab 2.5 süvendab Docker võrgu oskusi, aga **ei ole vajalik** Kubernetes'i õppimiseks. Võid julgelt jätkata Lab 3'ga ja tulla Lab 2.5 juurde hiljem tagasi, kui vajad sügavamaid võrgu analüüsi oskusi.

---

## 📅 Millal See Lab Teha?

### **Variant A:** Kohe pärast Lab 2 (soovitatud süvendajatele)
Kui soovid Docker võrke täielikult mõista enne Kubernetes'e liikumist.

### **Variant B:** Pärast Lab 3-4 (kui K8s võrgud tekitavad küsimusi)
Paljud Docker võrgu kontseptsioonid kehtivad ka Kubernetes'is. Kui Lab 3-4's tekivad küsimused võrkude kohta, tule tagasi Lab 2.5 juurde.

### **Variant C:** Hiljem, kui vaja (alati võimalik tagasi tulla)
Professionaalsed diagnostic oskused on alati kasulikud. Võid teha selle labi ka peale kogu programmi läbimist, kui vajad süvendust.

---

## 🎯 Õpieesmärgid

Peale selle labi läbimist oskad:

- ✅ **Inspekteerida Docker võrke professionaalselt** (`docker network inspect`, `jq` JSON parsing)
- ✅ **Testida võrguühendusi süstemaatiliselt** (connectivity matrix, isolation verification)
- ✅ **Analüüsida võrguliiklust** (`tcpdump`, `ss`, `netstat`)
- ✅ **Testida DNS resolution'it** ja service discovery'd (`nslookup`, `dig`)
- ✅ **Luua automatiseeritud testimise skripte** (bash scripts, pass/fail reporting)
- ✅ **Auditeerida võrgu turvalisust** (`nmap`, port scanning, vulnerability assessment)
- ✅ **Mõõta võrgu jõudlust** (latency, throughput, bottleneck detection)
- ✅ **Tuvastada võrguprobleeme süstemaatiliselt** (OSI model-based troubleshooting)
- ✅ **Integreerida network teste CI/CD pipeline'i**

---

## ⚠️ Eeldused

### ✅ **KRIITILINE: Lab 2 Peab Olema Lõpetatud!**

See lab **KASUTAB** Lab 2 Harjutus 3 loodud docker-compose stack'i:

**Mis peab olemas olema:**
- ✅ 3 võrku: `frontend-network`, `backend-network`, `database-network`
- ✅ 5 teenust töötavad: `frontend`, `user-service`, `todo-service`, `postgres-user`, `postgres-todo`
- ✅ Võrgu segmenteerimine on rakendatud (Harjutus 3)
- ✅ Ainult frontend port 8080 on avalik
- ✅ Backend/database pordid on localhost-only või suletud

### 🔍 Kontrolli enne alustamist:

```bash
# 1. Mine Lab 2 projekti kausta
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project

# 2. Kontrolli, et stack töötab
docker compose ps
# Oodatud: Kõik 5 teenust UP ja healthy

# 3. Kontrolli võrkude olemasolu
docker network ls | grep -E "frontend-network|backend-network|database-network"
# Oodatud: 3 võrku

# 4. Kontrolli frontend'i
curl http://localhost:8080
# Oodatud: HTML kood

# 5. Kontrolli võrgu segmentatsiooni
docker compose exec frontend nc -zv postgres-user 5432 2>&1
# Oodatud: "Name or service not known" (isolatsioon töötab!)
```

### ❌ Kui midagi puudub:

**Stack ei tööta?**
```bash
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project
docker compose up -d
```

**Võrgud puuduvad?**
Tagasi Lab 2 Harjutus 3:
```bash
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab
cat exercises/03-network-segmentation.md
```

**Lab 2 pole üldse tehtud?**
🔗 [Lab 2: Docker Compose](../02-docker-compose-lab/README.md)

---

## 📚 Harjutused

### [Harjutus 1: Võrgu Inspekteerimine ja Analüüs](exercises/01-network-inspection.md) (60 min)

**Eesmärk:** Docker võrkude põhjalik inspekteerimine professionaalsete tööriistadega

**Teemad:**
- `docker network inspect` deep-dive
- JSON parsing `jq`'ga (subnet, gateway, IPAM)
- Container-to-network mapping
- IP address discovery
- Multi-network configuration analysis
- Network driver ja capabilities

**Õpid kasutama:**
- `docker network ls`, `docker network inspect`
- `jq` JSON filtering
- `docker inspect` container network settings
- Network topology visualiseerimine

---

### [Harjutus 2: Võrguühenduste Testimine](exercises/02-connectivity-testing.md) (45 min)

**Eesmärk:** Süstemaatiline connectivity testing ja isolation verification

**4 põhikomponenti:**

1. **DNS Resolution Testing**
   - `nslookup`, `dig`, `host` service discovery
   - Docker embedded DNS (127.0.0.11) verification
   - Cross-network DNS isolation testing

2. **Port Connectivity Testing**
   - `nc -zv` connectivity matrix
   - `ping` latency testing
   - Expected vs actual connectivity

3. **HTTP Endpoint Testing**
   - `curl -v` detailed requests
   - Response time measurement
   - Health check validation

4. **Database Connection Testing**
   - PostgreSQL connection verification
   - Connection pool testing
   - Query execution testing

**Testing Matrix:**
```
Frontend → user-service:3000      ✅ SHOULD WORK
Frontend → todo-service:8081      ✅ SHOULD WORK
Frontend → postgres-user:5432     ❌ SHOULD FAIL (isolated!)
Frontend → postgres-todo:5432     ❌ SHOULD FAIL (isolated!)
user-service → postgres-user:5432 ✅ SHOULD WORK
user-service → postgres-todo:5432 ❌ SHOULD FAIL (wrong DB!)
```

---

### [Harjutus 3: Liikluse Analüüs ja Monitooring](exercises/03-traffic-analysis.md) (45 min)

**Eesmärk:** Võrguliikluse analüüs ja performance monitoring

**Teemad:**
- Packet capture `tcpdump`'iga
- Traffic filtering (port, protocol, host)
- Connection monitoring (`ss`, `netstat`)
- Performance analysis (latency, throughput)
- DNS traffic analysis
- HTTP request tracking

**Õpid kasutama:**
- `tcpdump` - packet capture ja analüüs
- `ss -tunap` - active connections
- `netstat -tlnp` - listening ports
- `curl -w` - HTTP timing analysis
- Performance bottleneck detection

---

### [Harjutus 4: Automatiseeritud Testimine ja Security Audit](exercises/04-automated-testing.md) (30 min)

**Eesmärk:** Automated testing scripts ja security auditing

**3 põhiosa:**

1. **Automated Testing Scripts**
   - `test-network-segmentation.sh` - 10 automated tests
   - Pass/fail reporting
   - CI/CD integration ready

2. **Security Audit**
   - `nmap` port scanning
   - `lsof` exposed ports verification
   - Docker Scout vulnerability scanning
   - Container capabilities audit

3. **Load Testing**
   - Parallel request handling
   - Performance under load
   - Bottleneck detection
   - Capacity planning

**Õpid:**
- Bash scripting automated testide jaoks
- Security auditing tööriistad
- Performance testing metodoloogia

---

## 🔧 Kasutatav Keskkond

See lab **EI LOO** uut Docker Compose stack'i. Sa kasutad Lab 2 olemasolevat keskkonda:

**Asukoht:** `/home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project/`

**Failid:**
- `docker-compose.yml` - 5 teenust, 3 võrku
- `nginx.conf` - reverse proxy konfiguratsioon
- `docker-compose.override.yml` - localhost binding

**Võrgud:**
- `frontend-network` - DMZ, avalik ligipääs
- `backend-network` - Application layer, internal
- `database-network` - Data layer, internal: true

**Teenused:**
- `frontend` (nginx:alpine) - Port 8080
- `user-service` (user-service:1.0-optimized) - Port 3000 (localhost-only)
- `todo-service` (todo-service:1.0-optimized) - Port 8081 (localhost-only)
- `postgres-user` (postgres:16-alpine) - Port 5432 (localhost-only)
- `postgres-todo` (postgres:16-alpine) - Port 5433 (localhost-only)

---

## 🛠️ Vajalikud Tööriistad

Enamik tööriistu on juba olemas Linux süsteemides. Kontrolli:

```bash
# Võrgu analüüs
which docker jq nc ping dig nslookup

# Liikluse analüüs
which tcpdump ss netstat lsof

# Security audit
which nmap curl

# Scripting
which bash
```

**Kui midagi puudub:**
```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y jq netcat-openbsd dnsutils tcpdump nmap net-tools

# Red Hat/CentOS
sudo yum install -y jq nmap-ncat bind-utils tcpdump nmap net-tools
```

---

## 🚀 Alustamine

### 1. Kontrolli eeldusi (5 min)

```bash
# Käivita eelduste kontroll (eespool kirjeldatud)
cd /home/janek/projects/hostinger/labs/02-docker-compose-lab/compose-project
docker compose ps
docker network ls | grep -E "frontend|backend|database"
```

### 2. Alusta Harjutus 1'ga

```bash
cd /home/janek/projects/hostinger/labs/02.5-network-analysis-lab
cat exercises/01-network-inspection.md
```

### 3. Järgi harjutusi järjest

Harjutused on loodud progressiivelt:
- Harjutus 1: Inspection (mõista struktuuri)
- Harjutus 2: Testing (testa funktsionaalsust)
- Harjutus 3: Analysis (analüüsi liiklust)
- Harjutus 4: Automation (automatiseeri testid)

---

## 📊 Õnnestumise Kriteeriumid

Peale selle labi läbimist peaksid omama:

- [ ] **Võrgu inspekteerimise oskused** - oskad kasutada `docker network inspect`, `jq`
- [ ] **Connectivity testing võimalused** - mõistad connectivity matrix'it
- [ ] **Traffic analysis tööriistad** - oskad kasutada `tcpdump`, `ss`
- [ ] **DNS testing** - mõistad service discovery'd
- [ ] **Automated testing scripts** - oled loonud bash teste
- [ ] **Security audit oskused** - oskad kasutada `nmap`, `lsof`
- [ ] **Performance analysis** - oskad mõõta latentsust ja throughput'i
- [ ] **Troubleshooting methodology** - oskad süstemaatiliselt diagnoosida

---

## 🔗 Järgmised Sammud

### **Pärast Lab 2.5 läbimist:**

**Variant A: Jätka Kubernetes'ega**
Oled nüüd võrgu analüüsi expert! Neid oskusi saad rakendada ka Kubernetes'is.
→ [Lab 3: Kubernetes Basics](../03-kubernetes-basics-lab/README.md)

**Variant B: Korda ja harjuta**
Proovi erinevaid stsenaariumeid:
- Loo teisi võrgu segmentatsioone
- Simuleeri võrguprobleeme
- Testi erinevaid load scenarios

---

## 💡 Parimad Tavad

1. **Kasuta süstemaatilist lähenemist** - järgi OSI model layers
2. **Dokumenteeri tulemused** - salvesta test output
3. **Automatiseeri korduvad testid** - bash scripts
4. **Mõista, miks midagi töötab** - ei piisa "see töötab" vastusest
5. **Kasuta production-ready tööriistu** - õpi tööstuse standardeid
6. **Testi edge case'e** - mitte ainult happy path
7. **Võrdle oodatud vs tegelik** - connectivity matrix

---

## 📚 Viited ja Ressursid

- [Docker Networks dokumentatsioon](https://docs.docker.com/network/)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [tcpdump Tutorial](https://danielmiessler.com/study/tcpdump/)
- [Network Troubleshooting Guide](https://www.redhat.com/sysadmin/network-troubleshooting)
- [Linux Performance Analysis Tools](https://brendangregg.com/linuxperf.html)

---

**Valmis? Alusta Harjutus 1'ga! 🚀**

→ [exercises/01-network-inspection.md](exercises/01-network-inspection.md)

---

**Viimane uuendus:** 2025-11-24
