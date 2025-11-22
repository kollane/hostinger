# Peatükk 4: Docker Põhimõtted

**Kestus:** 4 tundi
**Tase:** Algaja
**Eeldused:** Peatükk 1-3 läbitud, VPS juurdepääs

---

## 📋 Õpieesmärgid

Pärast selle peatüki läbimist oskad:

1. ✅ Selgitada konteinerite ja VM'ide arhitektuurilisi erinevusi
2. ✅ Mõista Docker arhitektuuri ja komponentide vastutusalasid
3. ✅ Selgitada image'ide ja containerite vahelist suhet
4. ✅ Mõista konteinerite lifecycle'i ja olekumasinaid
5. ✅ Selgitada port mapping'u vajadust ja network isolation'it
6. ✅ Mõista volume'ite rolli andmete püsivuse tagamisel
7. ✅ Selgitada environment variables'ite kasutamist konfiguratsioonis
8. ✅ Mõista Docker networking mudeleid ja DNS resolution'it
9. ✅ Rakendada observability põhimõtteid containerite debuggimiseks

---

## 🎯 1. Mis On Docker ja Miks Me Seda Vajame?

### 1.1 Klassikaline Probleem: "Mul Töötab!"

**Probleem, mida iga DevOps on kogenud:**

Arendaja: "Kood on valmis! Mul töötab!"
DevOps: "Panen production'i..."
Production: 💥 CRASH 💥
DevOps: "See ei tööta!"
Arendaja: "Aga mul töötab!"

**Miks see juhtub?**

See klassikaline probleem ei tulene mitte kehvast koodist ega arendaja valelikust väitest. Probleem on **keskkonnapõhine erinevus** (environmental drift):

- Arendaja masinas: Node.js 18.0.0, Ubuntu 22.04, PostgreSQL 14, PORT=3000
- Production serveris: Node.js 16.0.0, Ubuntu 20.04, PostgreSQL 12, PORT=8080

**Põhjuslik analüüs:**

1. **Dependency Hell:** Erinevad library versioonid käituvad erinevalt
2. **Runtime Differences:** Node.js 16 vs 18 - API muudatused, deprecated features
3. **Configuration Drift:** Hardcoded PORT=3000 vs production PORT=8080
4. **OS-Level Differences:** Failisüsteemi õigused, environment variables, system libraries

See on **infrastruktuuri reprodutseeritavuse probleem**. Kood on determineeritud (sama input → sama output), aga **keskkond ei ole**.

---

### 1.2 Docker Lahendus: Determinism for Infrastructure

**Docker filosoofia:**

> "Kui see töötab konteineris, siis töötab kõikjal!"

**Kuidas Docker seda saavutab?**

Docker **isoleerib rakenduse ja selle sõltuvused** ühte konteinerisse, mis on **immutable** (muutumatu) ja **portable** (teisaldatav).

**Põhimõte:**

- **Image** kirjeldab TÄPSELT, mis on rakenduse keskkond (Node.js 18, Alpine Linux, npm packages)
- See image on **identne** kõikjal: arendaja masinas, CI/CD serveris, staging'us, production'is
- **Sama image → sama keskkond → sama tulemus**

**Miks see elimineerib "mul töötab" probleemi?**

- **Reproducibility:** Image on read-only template. Ei saa muutuda.
- **Consistency:** Sama image hash garanteerib identsust
- **Isolation:** Konteineri sõltuvused ei sega host'i ega teisi konteinereid
- **Portability:** Sama image töötab x86_64 ja ARM64 arhitektuuridel (multi-arch images)

**Arhitektuuriline eelis:**

Arendaja ei loo mitte "koodi", vaid "koodi + keskkonna". DevOps ei deploy'i mitte "koodi", vaid "garanteeritud töötavat artefakti".

📖 **Praktika:** Labor 1, Harjutus 1 - Esimene Docker container

---

## 🖥️ 2. Konteinerid vs Virtuaalmasinad

### 2.1 Virtuaalmasin (VM) Arhitektuur

**VM mudel:**

```
+-----------------------------------+
|    App A    |    App B            |
|-------------|---------------------|
|  Libraries  |   Libraries         |
|-------------|---------------------|
|   Guest OS  |    Guest OS         |   ← Iga VM = Täielik OS!
|   (Ubuntu)  |    (CentOS)         |
+===================================+
|         Hypervisor (VMware, VirtualBox)
+===================================+
|         Host OS (Windows, Linux)
+===================================+
|         Hardware (CPU, RAM)
+-----------------------------------+
```

**Arhitektuuriline analüüs:**

VM emuleerib **täielikku arvutit**:
- Omaette kernel (Linux kernel VM'i sees)
- Täielik OS (init system, systemd, cron, kõik system utilities)
- Virtuaalne riistvara (BIOS, disk controller, network card)

**Miks see on ressursimahukas?**

1. **Guest OS overhead:** Ubuntu VM sisaldab 1000+ protsessi, millest rakendus kasutab 1-2
2. **Kernel duplication:** 10 VM'i = 10 identset kerneli (mälu duplikatsioon)
3. **Full boot process:** BIOS → bootloader → kernel init → systemd → services (1-5 minutit)
4. **Hardware emulation:** Iga I/O operatsioon läbib hypervisori (network, disk)

**Millal VM on õige valik?**

- **Strong isolation:** Multi-tenant environments (cloud hosting - erinevate klientide VM'id)
- **Different OS'id:** Windows + Linux + FreeBSD samal hostil
- **Legacy applications:** Rakendused, mis nõuavad täielikku OS kontrolli
- **Security boundaries:** Täielik kernel-level isolation (ei jaga kerneli)

---

### 2.2 Konteiner (Docker) Arhitektuur

**Container mudel:**

```
+-----------------------------------+
|  App A  |  App B  |  App C        |
|---------|---------|---------------|
|  Libs   |  Libs   |  Libs         |
+===================================+
|       Docker Engine               |   ← Jagatud kernel!
+===================================+
|       Host OS (Linux)
+===================================+
|       Hardware (CPU, RAM)
+-----------------------------------+
```

**Arhitektuuriline erinevus:**

Konteiner EI OLE virtuaalne masin. See on **protsessi isolatsioon** (process-level isolation).

**Kuidas see töötab?**

Linux kernel'i kaks fundamentaalset feature't:

1. **Namespaces:** Isoleerivad, mida protsess NÄEB
   - PID namespace: Konteiner näeb ainult oma protsesse (PID 1 on containeris nginx, mitte host init)
   - Network namespace: Oma network stack (IP, ports, routes)
   - Mount namespace: Oma failisüsteem
   - User namespace: UID 0 (root) containeris ≠ UID 0 hostis

2. **Cgroups (Control Groups):** Piiravad, mida protsess KASUTAB
   - CPU limit: Max 50% of 1 CPU core
   - Memory limit: Max 512MB RAM
   - Disk I/O limit: Max 100 MB/s write
   - Network bandwidth limit

**Miks konteinerid on kerged?**

- **Ei ole Guest OS:** Konteiner kasutab HOST kerneli (jagatud kernel)
- **Protsess, mitte VM:** Konteiner = eraldi protsess host'i vaates
- **Kerge boot:** "Käivitamine" = fork() protsess (millisekkundid)
- **Väike image:** Ainult rakendus + dependencies (Alpine base = 5 MB)

**Performance eelis:**

- **Native performance:** Kõik system call'id lähevad otse host kernelisse (ei ole hypervisor overhead)
- **Shared libraries:** Kui 10 containerit kasutavad sama base image (alpine:3.19), siis jagavad read-only layer'eid
- **Fast I/O:** Ei ole virtuaalne disk - overlay filesystem on host'i disk'il

---

### 2.3 Võrdlus ja Arhitektuurilised Kompromissid

| Aspekt | Virtuaalmasin | Konteiner |
|--------|---------------|-----------|
| **Boot aeg** | 1-5 minutit (full OS boot) | < 1 sekund (fork process) |
| **Image suurus** | GB'id (full OS) | MB'id (rakendus + libs) |
| **RAM kasutus** | GB'id (kernel + OS + app) | MB'id (ainult app) |
| **Isolatsioon** | Täielik (kernel-level) | Protsessi tasemel (shared kernel) |
| **OS support** | Erinevad OS'id | Ainult Linux (shared kernel) |
| **Tihedus** | 10-20 VM'i serveris | 100-1000 containerit serveris |
| **Security** | Strong isolation | Weaker (kernel vulnerabilities mõjutavad kõiki) |

**Arhitektuuriline analoogia:**

- **VM** = Maja (kõigega komplekt: köök, vannituba, magamistuba, elektrisüsteem, küte)
- **Konteiner** = Korter (jagatud taristu: lift, küte, elekter, vesi)

**Miks mitte mõlemad?**

Praktikas kasutatakse sageli **mõlemaid koos**:
- VM'id strong isolation'i jaoks (erinevad kliendid cloud'is)
- Konteinerid kerge deployment'i jaoks (mikroteenused VM'i sees)

**Näide:** Kubernetes cluster AWS'is:
- EC2 VM'id (host nodes) - VM-level isolation AWS'i infrastruktuuris
- Pods (containerid) - process-level isolation VM'i sees

📖 **Praktika:** Labor 1, Harjutus 2 - VM vs Container performance comparison

---

## 🐳 3. Docker Arhitektuur ja Komponendid

### 3.1 Docker Arhitektuuri Ülevaade

**Docker on client-server arhitektuur:**

```
+------------------+
|  Docker Client   |  ← Käsurea tööriist (docker run, docker build)
+------------------+
        |
        | (REST API üle UNIX socket või TCP)
        ↓
+------------------+
|  Docker Daemon   |  ← Taustprotsess (dockerd)
|  (dockerd)       |
+------------------+
        |
        ├─→ Images (read-only templates)
        ├─→ Containers (running instances)
        ├─→ Volumes (persistent data)
        └─→ Networks (container communication)
```

**Miks client-server arhitektuur?**

1. **Separation of Concerns:**
   - Client: UI/UX, käsurea parsing, kasutaja interaktsioon
   - Daemon: Container lifecycle, image management, security enforcement

2. **Remote Management:**
   - Saad hallata remote Docker daemon'it: `docker -H tcp://remote-server:2375`
   - CI/CD server'id saavad hallata build server'eid

3. **Security Boundary:**
   - Daemon töötab root'ina (vajab privileged access kerneli namespace API'dele)
   - Client ei vaja root õigusi (suhtleb daemoni'ga socket'i kaudu)

4. **Scalability:**
   - Saad lisada mitu daemon'it (Docker Swarm, Kubernetes)
   - Load balancing, high availability

---

### 3.2 Docker Komponendid ja Nende Vastutusalad

**1. Docker Client (`docker` käsk)**

**Vastutus:**
- Kasutaja interface (CLI)
- Päringute genereerimine (user intent → REST API call)
- Response'ide formateerimine (JSON → human-readable)

**Arhitektuurilised detailid:**
- Stateless: Ei hoia state'i, kõik state on daemon'is
- Thin client: Kogu äriloogika on daemon'is
- Pluggable: Saab asendada teiste klientidega (Docker Desktop GUI, Portainer)

**2. Docker Daemon (`dockerd`)**

**Vastutus:**
- **Image management:** Pull, build, push, layer caching, storage driver
- **Container lifecycle:** Create, start, stop, kill, remove
- **Network management:** Bridge creation, DNS resolution, port mapping
- **Volume management:** Volume lifecycle, mount points, storage drivers
- **Security enforcement:** AppArmor/SELinux profiles, capabilities, seccomp

**Miks daemon töötab taustprotsessina?**
- Containerid peavad elama ka pärast `docker run` käsu lõppu
- Daemon peab kuulama API päringuid (async events)
- Resource cleanup (crashed containerite eemaldamine)

**3. Docker Registry (Docker Hub)**

**Vastutus:**
- Image'ide salvestamine (distributed storage)
- Image distribution (CDN, multi-region)
- Authentication ja authorization (private repos)
- Image scanning (vulnerability detection)

**Public vs Private Registry:**
- **Public:** hub.docker.com - community images (nginx, postgres, node)
- **Private:** AWS ECR, Google GCR, Azure ACR, self-hosted Harbor
- **Security:** Private registry'tes saad rakendada access control, audit logs

---

### 3.3 Docker Workflow ja Lifecycle

**Põhiline workflow:**

1. **DEVELOP:** Kirjuta Dockerfile (image blueprint)
2. **BUILD:** `docker build` - loo image Dockerfile'ist
3. **PUSH:** `docker push` - lae image registry'sse
4. **PULL:** `docker pull` - lae image registry'st (teine server/developer)
5. **RUN:** `docker run` - käivita container image'ist
6. **STOP:** `docker stop` - peata container (graceful shutdown)
7. **RM:** `docker rm` - kustuta container (cleanup)

**Miks see workflow on DevOps-friendly?**

- **Reproducibility:** Image on versioned artifact (sha256 hash)
- **Immutability:** Image ei muutu pärast build'i (no config drift)
- **Auditability:** Registry hoiab kõiki versioone (rollback capability)
- **Collaboration:** Arendaja build'ib, DevOps deploy'ib SAMA artefakti

**Image versioning strategy:**

- **latest tag:** Viimane versioon (ÄRGE KASUTAGE PRODUCTION'IS!)
- **Semantic versioning:** myapp:1.2.3, myapp:1.2, myapp:1 (precision vs stability)
- **Git commit hash:** myapp:abc1234 (täpne reproducibility)
- **Build number:** myapp:build-456 (CI/CD integration)

📖 **Praktika:** Labor 1, Harjutus 3 - Docker client-daemon suhtlus

---

## 📦 4. Images vs Containers: Klass vs Objekt

### 4.1 Docker Image: Read-Only Template

**Image on blueprint** (ehitusplaan), millest luuakse containerid.

**OOP analoogia:**
```
Image = Class (class definition)
Container = Object (instance of class)

nginx:1.25-alpine = Image (template)
    ↓ (docker run)
webserver1, webserver2, webserver3 = Containers (instances)
```

**Miks image on read-only?**

1. **Immutability garantii:**
   - Image hash (sha256) on cryptographic guarantee, et image ei ole muutunud
   - Kui image on muudetav, ei saa usaldada hash'i

2. **Layer reusability:**
   - 10 containerit saavad jagada SAMA image layer'eid (storage efficiency)
   - Kui layer oleks writable, ei saaks jagada

3. **Security:**
   - Ei saa inject malware image'sse pärast build'i
   - Signed images (Docker Content Trust) garanteerivad integrity

---

### 4.2 Image Layers: Arhitektuuri Eelis

**Image koosneb layer'itest:**

```
nginx:1.25-alpine image:
+-------------------------+
| Layer 4: CMD (start nginx) - 0 bytes (metadata)
+-------------------------+
| Layer 3: COPY nginx.conf - 5 KB
+-------------------------+
| Layer 2: RUN apk add nginx - 15 MB
+-------------------------+
| Layer 1: FROM alpine:3.19 - 5 MB (base)
+-------------------------+
Total: 20 MB
```

**Miks layer architecture?**

1. **Caching:**
   - Docker cache'ib layer'eid
   - Kui layer ei muutu, ei rebuild'i (vastly faster builds)
   - Muudad ainult koodi (Layer 3) → rebuild ainult Layer 3-4

2. **Storage efficiency:**
   - 10 image'i, mis kasutavad sama base layer'it (alpine:3.19) → jagavad 5 MB layer'it
   - Storage saving: 50 MB → 5 MB

3. **Network efficiency:**
   - `docker pull` laeb ainult puuduvad layer'id
   - Kui sul on juba alpine:3.19, ei lae seda uuesti

4. **Incremental updates:**
   - Update Node.js 18.0 → 18.1: Ainult üks layer muutub
   - Download: 100 MB (kogu image) → 10 MB (muutunud layer)

**Layer implementation: Copy-on-Write (CoW)**

Docker kasutab **overlay filesystem'i** (OverlayFS Linux'is):
- **Lower layers:** Read-only (image layers)
- **Upper layer:** Writable (container layer)
- **Merged view:** Container näeb merged filesystem'i

Kui konteiner kirjutab faili, mis on read-only layer'is:
1. Fail copy'takse upper layer'isse (Copy-on-Write)
2. Muudatus tehakse copy's
3. Container näeb modified faili, image layer jääb muutumatuks

---

### 4.3 Docker Container: Running Instance

**Container on running instance of an image.**

**Mis juhtub `docker run` käsu ajal?**

1. **Image check:** Kas image on lokaalselt? Kui ei, siis pull
2. **Layer mount:** Mount image layer'id read-only
3. **Writable layer:** Loo writable layer (container layer)
4. **Namespaces:** Loo isolated namespaces (PID, network, mount, user)
5. **Cgroups:** Rakenda resource limits (memory, CPU)
6. **Process start:** Fork protsess, exec container CMD
7. **Network:** Ühenda bridge network'i, assign IP

**Konteineri state machine:**

```
Created → Running → Paused → Stopped → Removed
  ↑                              ↓
  └──────── Restart ─────────────┘
```

**Iga containeril on oma:**
- **Container ID:** Unique identifier (abc123def456)
- **Nimi:** User-friendly name (--name webserver)
- **Writable layer:** Failisüsteemi muudatused
- **Network interface:** IP address, ports
- **Process tree:** PID namespace (PID 1 = container CMD)

**Container lifecycle management:**

- **Start:** Fork process, apply cgroups/namespaces
- **Stop:** Send SIGTERM (graceful shutdown), wait 10s, SIGKILL
- **Pause:** Freeze cgroup (protsessid suspended, CPU=0%)
- **Remove:** Delete container layer, cleanup namespaces

📖 **Praktika:** Labor 1, Harjutus 4 - Image layer inspection

---

## 🔌 5. Port Mapping ja Network Isolation

### 5.1 Miks Port Mapping On Vajalik?

**Network isolation probleem:**

Konteinerid on **network isolated** by default:
- Iga containeril on oma network namespace
- Container IP on AINULT bridge network'is (nt 172.17.0.2)
- Host võrk EI NÄE container IP'sid otse

**Probleem:**
```
Host: http://localhost:80 → Host Nginx (kui töötab)
Container: Nginx kuulab port 80 → Aga CONTAINER network'is (172.17.0.2:80)

Host'ist ei saa ligi: curl http://localhost:80 ← EI TÖÖTA
```

**Lahendus: Port Mapping (Port Forwarding)**

Docker daemon loob **NAT (Network Address Translation)** reegli:
```
Host port 8080 → Container 172.17.0.2:80

Tulemus:
curl http://localhost:8080 → Docker daemon forward → Container port 80
```

---

### 5.2 Port Mapping Arhitektuur

**Kuidas see tehniliselt töötab?**

Docker daemon kasutab **iptables** (Linux firewall) NAT reegleid:

1. **DNAT (Destination NAT):** Incoming traffic host port'ist → container IP:port
2. **SNAT (Source NAT):** Outgoing traffic container'ist → host IP

**Näide:**

```
Host: 192.168.1.100
Container: 172.17.0.2 (bridge network)

docker run -p 8080:80 nginx

iptables rule:
-A DOCKER -p tcp --dport 8080 -j DNAT --to-destination 172.17.0.2:80

Tulemus:
External request: 93.127.213.242:8080 → NAT → 172.17.0.2:80
```

**Port binding modes:**

- `-p 8080:80` - Bind host port 8080 kõigile IP'dele (0.0.0.0:8080)
- `-p 127.0.0.1:8080:80` - Bind ainult localhost'ile (ainult local access)
- `-p 80:80` - Same port host'is ja containeris (must be available!)
- `-P` - Publish ALL exposed ports to random host ports (EXPOSE Dockerfile'is)

**Miks port conflicts?**

Host'is saab port 80 kuulata AINULT üks protsess:
- Kui host Nginx juba kuulab port 80 → `docker run -p 80:80` FAILS
- Lahendus: Kasuta erinevat host port'i (-p 8080:80)

---

### 5.3 Network Isolation ja Security

**Port mapping on security boundary:**

- **Exposed ports:** Ainult `-p` flagiga published portid on accessible
- **Closed ports:** Container võib kuulata port 3000, aga kui pole `-p`, siis ei ole ligipääs

**Best practice:**

- **Development:** Publish kõik portid (`-p 3000:3000`)
- **Production:** Publish ainult vajalikud portid (API port, mitte debugging port)
- **Internal services:** Ära publish porte üldse (database containerid kommunitseerivad internal network'i kaudu)

**Näide: Mikroteenuste arhitektuur**

```
Frontend: -p 80:80 (public-facing)
Backend API: -p 3000:3000 (public API)
PostgreSQL: EI OLE -p (ainult internal network)

Tulemus:
- Frontend ja Backend on ligipääsetavad väljapoolt
- PostgreSQL on ligipääsetav AINULT backend container'ile (sama network)
```

📖 **Praktika:** Labor 1, Harjutus 5 - Port mapping ja firewall

---

## 💾 6. Volumes: Persistent Data Management

### 6.1 Container Filesystem On Ephemeral

**Probleem: Containers are stateless by design.**

Container writable layer on **ephemeral** (ajutine):
- Kui container kustutatakse (`docker rm`) → writable layer kustutatakse
- Kõik andmed, mida container kirjutas, kaovad (database, logs, uploads)

**Miks konteinerid on ephemeral?**

1. **Immutability:** Containerid peavad olema asendatavad (cattle, not pets)
2. **Scalability:** Kui containerid hoiavad state'i, ei saa scale horizontaalselt
3. **Kubernetes philosophy:** Pods on ephemeral, storage on eraldi (PersistentVolume)

**Kuid praktikas meil on stateful rakendused:**

- **PostgreSQL:** Database fail (GB'id andmeid)
- **Logs:** Application logs, access logs
- **Uploads:** User-uploaded files (avatars, documents)

**Lahendus: Docker Volumes**

---

### 6.2 Docker Volumes: Persistent Storage Abstraction

**Volume on storage, mis elab containerist KAUEM.**

**Arhitektuur:**

```
Host Filesystem          Container Filesystem
/var/lib/docker/volumes/
  pgdata/
    _data/              →   /var/lib/postgresql/data
      (persistent)              (mount point)

Container kustutatakse → Volume jääb alles
```

**Volume lifecycle:**

1. **Create:** `docker volume create pgdata` - Docker loob directory host'is
2. **Mount:** `docker run -v pgdata:/var/lib/postgresql/data` - Mount containerisse
3. **Use:** Container kirjutab data → salvestub host volume'isse
4. **Persist:** `docker rm` kustutab container, aga EI kustuta volume'i
5. **Reuse:** Uus container saab mount'ida SAMA volume'i → data säilis

**Miks volumes, mitte bind mounts?**

| Aspekt | Volume | Bind Mount |
|--------|--------|------------|
| **Management** | Docker managed | User managed (host path) |
| **Portability** | Portable (Docker abstraction) | Host-specific path |
| **Performance** | Optimized (native filesystem) | Slower (macOS/Windows: OSXFS, 9p) |
| **Backups** | Docker tools (volume plugins) | Manual scripts |
| **Use case** | Production data | Development (code hot-reload) |

**Arhitektuuriline eelis:**

Volume on **abstraction layer** storage'i ees:
- Local disk: `/var/lib/docker/volumes/`
- Network storage: NFS, AWS EFS, Ceph (volume plugins)
- Cloud block storage: AWS EBS, Azure Disk (CSI drivers Kubernetes'es)

---

### 6.3 Volume Lifecycle ja Data Persistence

**Kriitilised stsenaariumid:**

**Stsenaarium 1: Container upgrade**
```
docker run -v pgdata:/var/lib/postgresql/data postgres:14
(andmed salvestuvad volume'isse)

docker rm postgres
docker run -v pgdata:/var/lib/postgresql/data postgres:16
(Upgrade! Sama data, uus PostgreSQL versioon)
```

**Stsenaarium 2: Disaster recovery**
```
docker volume create pgdata-backup
docker run --rm -v pgdata:/source -v pgdata-backup:/backup alpine tar czf /backup/data.tar.gz -C /source .
(Backup volume → compressed archive)

Server crash, rebuild
docker volume create pgdata-restored
docker run --rm -v pgdata-restored:/restore alpine tar xzf /backup/data.tar.gz -C /restore
(Restore volume)
```

**Volume cleanup:**

- Volumes EI kusutata automaatselt (by design - safety)
- `docker volume prune` - kustuta kasutamata volume'id (dangling volumes)
- **OHTLIK:** Võid kaotada data! Backup enne cleanup'i.

**Kubernetes paralleelsus:**

- Docker Volume ≈ Kubernetes PersistentVolume (PV)
- Volume mount ≈ PersistentVolumeClaim (PVC)
- StatefulSet kasutab PVC template'eid (database pods)

📖 **Praktika:** Labor 1, Harjutus 6 - PostgreSQL volume persistence

---

## 🌐 7. Environment Variables: Configuration Management

### 7.1 12-Factor App: Configuration

**12-Factor App põhimõte III: Store config in the environment.**

**Miks environment variables?**

**Probleem: Hardcoded config**

```javascript
// ❌ VALE
const dbHost = "localhost";
const dbPassword = "secret123";
const apiKey = "abc-def-ghi";
```

**Miks see on problemaatiline?**

1. **Security:** Credentials on koodis → Git history → leak
2. **Environment coupling:** localhost ≠ production database host
3. **No flexibility:** Muutmiseks rebuild, redeploy
4. **Secret rotation:** Password change → code change → deployment

**Lahendus: Externalize configuration**

```javascript
// ✅ ÕIGE
const dbHost = process.env.DB_HOST;
const dbPassword = process.env.DB_PASSWORD;
const apiKey = process.env.API_KEY;
```

**Arhitektuurilised eelised:**

- **Separation of concerns:** Code (what to do) vs Config (where/how)
- **Environment parity:** Same code, different config (dev vs staging vs prod)
- **Security:** Secrets ei ole repo's (injected at runtime)
- **Flexibility:** Config change ilma code change'ita

---

### 7.2 Environment Variables Docker'is

**Docker environment variable hierarchy:**

1. **Dockerfile ENV:** Default values (overridable)
2. **docker run -e:** Runtime override (explicit values)
3. **docker run --env-file:** File-based config (bulk import)
4. **Docker Compose environment:** Compose file env section
5. **Kubernetes ConfigMap/Secret:** Orchestration-level config

**Best practices:**

**Development:**
- `.env` file lokaalse arenduse jaoks
- **ÄRGE COMMIT'ige `.env` faili!** (add to `.gitignore`)

**Production:**
- **Secrets management:** Vault, AWS Secrets Manager, Kubernetes Secrets
- **Least privilege:** Container näeb ainult vajalikke secrets (not all)
- **Rotation:** Secret rotation ilma container rebuild'ita

**Configuration validation:**

Container startup peaks valideerima required env variables:
```javascript
if (!process.env.DB_HOST) {
  console.error("ERROR: DB_HOST not set");
  process.exit(1); // Fail fast
}
```

**Miks fail fast?**

Parem crashida kohe startup'is kui töötada pooliku config'iga (partial degradation).

---

### 7.3 Environment Variables vs Configuration Files

**Kumb kasutada?**

| Aspekt | Environment Variables | Config Files |
|--------|----------------------|--------------|
| **12-Factor** | ✅ Compliant | ❌ Non-compliant |
| **Secrets** | ✅ Good (no disk write) | ❌ Risk (file permissions) |
| **Simple config** | ✅ Easy (key=value) | ❌ Overhead (YAML parsing) |
| **Complex config** | ❌ Clunky (nested JSON as string) | ✅ Natural (YAML/JSON structure) |
| **Kubernetes** | ✅ Native (ConfigMap, Secret) | ⚠️ Possible (ConfigMap mount) |

**Hybrid approach (best practice):**

- **Secrets:** Environment variables (DB_PASSWORD, API_KEY)
- **Complex config:** Config files mounted as volumes (nginx.conf, logging.yaml)
- **Feature flags:** Environment variables (FEATURE_X_ENABLED=true)

📖 **Praktika:** Labor 1, Harjutus 7 - Environment-based configuration

---

## 🌍 8. Docker Networks: Container Communication

### 8.1 Docker Networking Model

**Network isolation by default:**

Iga containeril on oma **network namespace**:
- Oma network stack (interfaces, routing table, iptables)
- Oma IP address (containeris: eth0 → 172.17.0.2)
- Oma ports (konteinerid saavad kuulata sama porti, nt 80, ilma konfliktita)

**Docker network drivers:**

1. **Bridge (default):** Virtual switch, containers connected via software bridge
2. **Host:** Container shares host's network stack (no isolation, better performance)
3. **None:** No networking (isolated container)
4. **Overlay:** Multi-host networking (Docker Swarm, cross-server communication)
5. **Macvlan:** Container gets MAC address (appears as physical device on network)

---

### 8.2 Bridge Network: Default Networking

**Kuidas bridge network töötab?**

Docker loob **virtual switch** (docker0 bridge):

```
Host network:
eth0: 192.168.1.100 (external network)

Docker bridge:
docker0: 172.17.0.1 (bridge gateway)
  ├─ veth1 → Container A (172.17.0.2)
  ├─ veth2 → Container B (172.17.0.3)
  └─ veth3 → Container C (172.17.0.4)
```

**Virtual Ethernet (veth) pairs:**

- Docker loob veth pair: üks end bridge'is, teine container'i network namespace'is
- Packet flow: Container eth0 → veth1 (host) → docker0 bridge → veth2 → Container B eth0

**Default bridge limitations:**

- **Ei ole DNS resolution:** Containerid ei saa teineteist resolve'da name'i järgi
- **Manual IP management:** Pead teadma container IP'sid
- **Legacy:** Docker soovitab custom bridge network'e

---

### 8.3 Custom Bridge Networks: DNS Resolution

**Custom network eelis: Automatic DNS resolution**

Docker daemon embedded DNS server (127.0.0.11):
- Containerid saavad teineteist resolve'da **container name** järgi
- DNS query: `postgres` → Docker DNS → 172.18.0.2

**Arhitektuuriline eelis:**

```
Backend container:
const dbHost = "postgres"; // Container name!

Docker DNS resolution:
postgres → 172.18.0.2 (automatic)

No hardcoded IP!
```

**Network isolation turvalisuse jaoks:**

- **Frontend network:** Frontend + Backend
- **Backend network:** Backend + Database
- **Database EI OLE frontend network'is** (principle of least privilege)

```
Frontend container:
- Attached: frontend-net
- Can communicate: Backend
- Cannot communicate: Database (different network)

Backend container:
- Attached: frontend-net, backend-net
- Can communicate: Frontend, Database

Database container:
- Attached: backend-net
- Can communicate: Backend
- Cannot communicate: Frontend
```

**Defense in depth:**

Isegi kui frontend on compromised, ei pääse otse database'i ligi.

---

### 8.4 Network Troubleshooting Concepts

**Observability networkingu jaoks:**

1. **DNS resolution:**
   - Kas container saab resolve'da teise container nime?
   - Tool: `nslookup`, `dig` (DNS queries)

2. **Connectivity:**
   - Kas packets jõuavad destination'i?
   - Tool: `ping`, `curl`, `telnet`

3. **Routing:**
   - Kuidas packet'id route'takse?
   - Tool: `ip route`, `traceroute`

4. **Firewall:**
   - Kas iptables reeglid blokivad traffic'u?
   - Tool: `iptables -L`, Docker daemon logs

**Debugging workflow:**

1. **Check network attachment:** Kas containerid on samas network'is?
2. **DNS test:** Kas DNS resolution töötab? (nslookup)
3. **Ping test:** Kas ICMP packets jõuavad läbi? (ping)
4. **Port test:** Kas destination port kuulab? (telnet, curl)
5. **Logs:** Application logs, Docker daemon logs

📖 **Praktika:** Labor 1, Harjutus 8 - Multi-container networking

---

## 🐛 9. Debugging ja Observability

### 9.1 Observability Põhimõtted

**Observability = Võime mõista süsteemi seisundit väliste väljundite kaudu.**

**Kolm observability pillarit:**

1. **Logs:** Structured events (what happened, when, why)
2. **Metrics:** Numeric measurements (CPU, memory, request count)
3. **Traces:** Request flow across services (distributed tracing)

**Docker observability:**

- **Logs:** STDOUT/STDERR → `docker logs`
- **Metrics:** cgroups stats → `docker stats`
- **Traces:** Application-level (OpenTelemetry, Jaeger)

---

### 9.2 Container Logs: Structured Logging

**Docker logs eeldused:**

- Rakendus logib **STDOUT/STDERR** (not file)
- Docker daemon capture'b output → logging driver
- `docker logs` loeb logging driver'ist

**Miks STDOUT, mitte failid?**

1. **12-Factor App:** Logs as event streams (ei kirjuta failidesse)
2. **Portability:** Sama loogika igal platformil (Docker, Kubernetes, AWS Fargate)
3. **Centralization:** Logging driver saadab logid central aggregation'i (Loki, Elasticsearch)
4. **No disk management:** Ei pea muretsema log rotation, disk space

**Logging drivers:**

- **json-file (default):** Logs JSON files on host'is
- **syslog:** Send to syslog daemon
- **journald:** Systemd journal integration
- **fluentd:** Centralized logging (Fluentd aggregator)
- **awslogs:** AWS CloudWatch Logs

**Structured logging (best practice):**

```json
{"level":"info","time":"2025-01-10T12:00:00Z","msg":"User registered","user_id":123}
```

Structured logs on parsitavad (machine-readable) → better querying, alerting.

---

### 9.3 Container Inspection: Metadata

**`docker inspect` annab container metadata:**

- **Network config:** IP address, attached networks, ports
- **Mounts:** Volumes, bind mounts
- **Environment:** Env variables (aga MITTE secrets - turvarisk!)
- **State:** Running, exit code, start time
- **Image:** Image ID, digest

**Miks see on oluline?**

Debugging stsenaariumid:
- **Networking issue:** Milline IP? Millisesse network'i attached?
- **Volume issue:** Kas mount on correct? Source vs destination?
- **Exit code:** Miks container exited? (exit code 137 = SIGKILL, memory limit)

---

### 9.4 Resource Monitoring: Metrics

**`docker stats` näitab real-time metrics:**

- **CPU %:** Protsendi CPU utilization (limited by cgroup)
- **Memory usage:** Current memory vs limit
- **Network I/O:** Bytes in/out
- **Block I/O:** Disk read/write

**Miks metrics on kriitilised?**

1. **Performance troubleshooting:** Kas CPU bottleneck? Memory leak?
2. **Capacity planning:** Kui palju resources container vajab?
3. **Alerting:** Metric-based alerts (memory > 90% → alert)

**Production observability stack:**

- **Prometheus:** Metrics collection, time-series database
- **Grafana:** Metrics visualization, dashboards
- **Alertmanager:** Alerts based on metrics (PagerDuty, Slack)

📖 **Praktika:** Labor 1, Harjutus 9-10 - Logging ja monitoring

---

## 🎓 10. Mida Sa Õppisid?

### Põhilised Kontseptsioonid

✅ **Arhitektuurilised Põhimõtted:**
- Konteinerite vs VM'ide arhitektuurilised erinevused (kernel sharing vs hypervisor)
- Docker client-server arhitektuur ja komponentide vastutusalad
- Image layering ja Copy-on-Write filesystem
- Network isolation ja port mapping arhitektuur

✅ **Infrastructure Concepts:**
- Ephemeral containers vs persistent volumes
- 12-Factor App configuration management
- Docker networking model (bridge, custom networks, DNS resolution)
- Observability kolm pillarit (logs, metrics, traces)

✅ **DevOps Praktikad:**
- Reproducibility läbi immutable images
- Environment parity (dev/staging/prod sama image)
- Defense in depth (network isolation, least privilege)
- Fail fast philosophy (validation at startup)

✅ **Security Principles:**
- Namespace isolation (PID, network, mount, user)
- Cgroup resource limits (memory, CPU, I/O)
- Port exposure minimization (publish only necessary ports)
- Secrets management (environment variables vs hardcoded)

---

## 🚀 11. Järgmised Sammud

**Peatükk 5: Dockerfile ja Rakenduste Konteineriseerimise Detailid** 📦

Nüüd kui mõistad Docker arhitektuuri ja põhimõtteid, on aeg õppida **kuidas luua oma image'eid**:

- Dockerfile süntaks ja best practices
- Layer caching optimization
- Multi-stage builds (image size optimization)
- Node.js rakenduste konteineriseerimise detailid
- Java/Spring Boot konteineriseerimise strateegiad
- Security best practices (non-root users, minimal base images)

📖 **Praktika:** Labor 1 pakub hands-on harjutusi kõikide selle peatüki kontseptsioonide kohta.

---

## ✅ Kontrolli Ennast

Enne järgmisele peatükile liikumist, veendu et:

- [ ] Mõistad, MIKS konteinerid on kergemad kui VM'id (shared kernel, no Guest OS)
- [ ] Oskad selgitada Docker client-server arhitektuuri (daemon, registry)
- [ ] Mõistad image layer'ite rolli (caching, reusability, CoW)
- [ ] Oskad selgitada, miks port mapping on vajalik (network isolation)
- [ ] Mõistad volume'ite rolli (ephemeral containers vs persistent data)
- [ ] Oskad põhjendada environment variables kasutamist (12-Factor App)
- [ ] Mõistad Docker networking DNS resolution'it (custom networks)
- [ ] Oskad rakendada observability põhimõtteid (logs, metrics)

**Kui kõik on ✅, oled valmis Peatükiks 5!** 🚀

---

**Peatükk 4 lõpp**
**Järgmine:** Peatükk 5 - Dockerfile ja Rakenduste Konteineriseerimise Detailid
