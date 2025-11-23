# Peatükk 5: Docker Põhimõtted

## Õpieesmärgid

Peale selle peatüki läbimist oskad:
- ✅ Selgitada, mis on Docker ja miks seda kasutatakse
- ✅ Eristada virtuaalmasinate ja konteinerite vahel
- ✅ Mõista Docker arhitektuuri (client, daemon, registry)
- ✅ Eristada Docker image'it (image) konteinerist (container)
- ✅ Installida Docker Ubuntu/Linux süsteemi
- ✅ Käivitada ja hallata lihtsaid Docker konteinereid

## Põhimõisted

- **Docker:** Avatud lähtekoodiga konteineriseerimise platvorm, mis võimaldab pakkida rakendusi koos kõigi sõltuvustega standardiseeritud üksustesse (konteineritesse).
- **Container (konteiner):** Käivitatav instants Docker image'ist. Isoleeritud protsess, millel on oma failisüsteem, võrk ja ressursid, kuid jagab host süsteemi kerneli.
- **Image (pilt):** Read-only (kirjutuskaitstud) template konteinerite loomiseks. Sisaldab rakendust, sõltuvusi, teeke ja konfiguratsioone.
- **Docker Hub:** Avalik registry (hoidla) Docker image'ite jaoks, sarnane GitHub'ile, aga image'ite salvestamiseks ja jagamiseks.
- **Dockerfile:** Tekstifail, mis sisaldab järjestikust juhiste komplekti Docker image'i ehitamiseks.
- **Docker Engine:** Docker'i põhikomponent, mis koosneb daemon'ist, REST API'st ja CLI client'ist.
- **Registry (registri):** Teenus Docker image'ite salvestamiseks ja levitamiseks (Docker Hub, private registries).

## Teooria

### Miks konteinerid? Virtuaalmasinast konteineriteni

#### Traditsiooniline lähenemine: Virtuaalmasinad (VM)

Enne konteinereid kasutati rakenduste isoleerimiseks virtuaalmasinaid. Virtuaalmasinad pakuvad täielikku isolatsiooni, simuleerides tervet arvutisüsteemi:

```
┌─────────────────────────────────────────────────────────────┐
│                   Füüsiline Server                          │
│                                                             │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐ │
│  │     VM 1       │  │     VM 2       │  │    VM 3      │ │
│  │                │  │                │  │              │ │
│  │  Guest OS      │  │  Guest OS      │  │  Guest OS    │ │
│  │  (Ubuntu       │  │  (Ubuntu       │  │  (CentOS     │ │  ← Iga VM töötab
│  │   22.04)       │  │   20.04)       │  │   Stream 9)  │ │    TÄIELIKKU OS
│  │  2-4GB RAM     │  │  2-4GB RAM     │  │  2-4GB RAM   │ │    (palju ressursse)
│  │                │  │                │  │              │ │
│  │  App A         │  │  App B         │  │  App C       │ │
│  │  + Libs        │  │  + Libs        │  │  + Libs      │ │
│  └────────────────┘  └────────────────┘  └──────────────┘ │
│                                                             │
│         Hypervisor (VMware ESXi, VirtualBox, KVM)           │
│                                                             │
│                   Host OS (Ubuntu Server)                   │
│                                                             │
│              Hardware (CPU, RAM, Disk, Network)             │
└─────────────────────────────────────────────────────────────┘
```

**Probleemid virtuaalmasinatega:**
- ❌ **Ressursimahukas:** Iga VM töötab täielikku operatsioonisüsteemi (2-4GB RAM, 10-20GB disk ruumi)
- ❌ **Aeglane käivitus:** VM boot võtab 30-60 sekundit või enam
- ❌ **Suur overhead:** Hypervisor ja mitme OS kernel'i haldamine kulutab palju ressursse
- ❌ **Raiskamine:** Iga VM-il on oma kernel, failisüsteem, süsteemiteenused (kuigi kasutab ainult väikest osa)
- ❌ **Aeglane provisioneerimine:** Uue VM loomine võtab minuteid

#### Modern lähenemine: Docker Konteinerid

Konteinerid jagavad host süsteemi operatsioonisüsteemi kerneli, kuid on omavahel isoleeritud:

```
┌─────────────────────────────────────────────────────────────┐
│                   Füüsiline Server                          │
│                                                             │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐ ┌──────────┐ │
│  │Container 1│  │Container 2│  │Container 3│ │Container4│ │
│  │           │  │           │  │           │ │          │ │
│  │  App A    │  │  App B    │  │  App C    │ │  App D   │ │
│  │  + Libs   │  │  + Libs   │  │  + Libs   │ │  + Libs  │ │  ← Ainult rakendus
│  │  Node.js  │  │  Java     │  │  Python   │ │  Nginx   │ │    + vajalikud libs
│  │  50MB     │  │  250MB    │  │  100MB    │ │  20MB    │ │    (väike footprint)
│  └───────────┘  └───────────┘  └───────────┘ └──────────┘ │
│                                                             │
│                 Docker Engine (Daemon)                      │  ← Haldab konteinereid
│          containerd + runc (runtime)                        │
│                                                             │
│                   Host OS (Ubuntu Server)                   │  ← ÜKS OS kernel
│                      Linux Kernel                           │    kõigile konteineritele
│                                                             │
│              Hardware (CPU, RAM, Disk, Network)             │
└─────────────────────────────────────────────────────────────┘
```

**Konteinerite eelised:**
- ✅ **Kerged:** 20-500MB vs 2-4GB (VM) - ainult rakendus ja sõltuvused, mitte terve OS
- ✅ **Kiire käivitus:** <1 sekund vs 30-60 sekundit (VM) - protsessi start, mitte OS boot
- ✅ **Ressursside efektiivsus:** Saad käivitada 10-100x rohkem konteinereid kui VM'e samal riistvaral
- ✅ **Portaabelsus:** "Works on my machine" → "Works everywhere" - sama image töötab arenduses, testimises ja produktsioonis
- ✅ **Isolatsioon:** Iga konteiner on eraldatud (protsessid, võrk, failisüsteem), kuid jagab kernel'i
- ✅ **Kiire deployment:** Uue konteineri käivitamine võtab sekundeid
- ✅ **Versioonihaldus:** Image'id on versioonistatavad (tags: v1.0, v1.1, latest)
- ✅ **Skaleeritavus:** Lihtne käivitada 10, 100, 1000 konteineri koopiat

#### Võrdlus: VM vs Konteiner

| Aspekt | Virtuaalmasin (VM) | Konteiner |
|--------|-------------------|-----------|
| **OS** | Terve Guest OS per VM | Jagab Host OS kerneli |
| **Suurus** | 2-20GB | 20-500MB |
| **Käivitusaeg** | 30-60 sekundit | <1 sekund |
| **RAM overhead** | 2-4GB per VM | 10-100MB per konteiner |
| **Isolatsioon** | Täielik (hypervisor tasemel) | Protsessi tasemel (namespaces, cgroups) |
| **Jõudlus** | Väike overhead (hypervisor) | Natiivne jõudlus |
| **Density** | 10-50 VM'd per host | 100-1000 konteinerit per host |
| **Portaabelsus** | VM image (suur, OS-spetsiifiline) | Container image (väike, portable) |
| **Kasutus** | Erinevate OS'ide isoleerimine | Mikroteenuste, rakenduste isoleerimine |

**Millal kasutada VM'i?**
- Vajad erinevaid operatsioonisüsteeme (Windows + Linux)
- Vajad täielikku kernel-level isolatsiooni (security)
- Legacy rakendused, mis nõuavad spetsiifilist OS versiooni

**Millal kasutada konteinerit?**
- Mikroteenused arhitektuur
- CI/CD pipeline'id (kiire build, test, deploy)
- Rakenduste skaleerimiseks (horisontaalne skaleerimine)
- Development/production parity (sama keskkonnad)
- Cloud-native rakendused

### Docker Arhitektuur

Docker kasutab **client-server arhitektuuri**. Docker süsteem koosneb kolmest põhikomponendist:

```
┌────────────────────────────────────────────────────────────────────┐
│                         Docker Client                              │
│                                                                    │
│  $ docker build -t myapp:1.0 .                                    │
│  $ docker run -d -p 8080:80 nginx                                 │
│  $ docker ps                                                       │
│  $ docker pull ubuntu:22.04                                       │
│                                                                    │
│                            │                                       │
│                            │ REST API (HTTP/UNIX socket)           │
│                            ▼                                       │
└────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│                       Docker Daemon (dockerd)                      │
│                                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │   Images     │  │  Containers  │  │      Volumes            │ │
│  │              │  │              │  │                         │ │
│  │  nginx:latest│  │  container1  │  │  postgres-data          │ │
│  │  node:18     │  │  container2  │  │  app-logs               │ │
│  │  myapp:1.0   │  │  container3  │  │                         │ │
│  └──────────────┘  └──────────────┘  └─────────────────────────┘ │
│                                                                    │
│  ┌──────────────┐  ┌──────────────────────────────────────────┐  │
│  │   Networks   │  │   containerd (runtime)                   │  │
│  │              │  │   └─> runc (low-level runtime)           │  │
│  │  bridge      │  │                                          │  │
│  │  mynetwork   │  └──────────────────────────────────────────┘  │
│  └──────────────┘                                                 │
└────────────────────────────────────────────────────────────────────┘

                            │
                            │ HTTP(S)
                            ▼

┌────────────────────────────────────────────────────────────────────┐
│                      Docker Registry                               │
│                       (Docker Hub)                                 │
│                                                                    │
│     ┌─────────────────────────────────────────────────┐           │
│     │  Public Images:                                 │           │
│     │  • nginx (official)                             │           │
│     │  • node (official)                              │           │
│     │  • postgres (official)                          │           │
│     │  • ubuntu (official)                            │           │
│     │                                                 │           │
│     │  Private Images:                                │           │
│     │  • yourcompany/myapp:1.0                        │           │
│     │  • yourcompany/backend:latest                   │           │
│     └─────────────────────────────────────────────────┘           │
└────────────────────────────────────────────────────────────────────┘
```

#### 1. Docker Client (CLI)

Docker client (`docker` käsk) on kasutajaliides Docker'iga suhtlemiseks:

```bash
# Näited Docker CLI käskudest
docker build -t myapp:1.0 .        # Ehita image
docker run -d nginx                 # Käivita konteiner
docker ps                           # Näita töötavaid konteinereid
docker images                       # Näita lokaalseid image'id
docker pull ubuntu:22.04            # Tõmba image registrist
```

**Kuidas see töötab:**
- Client saadab käsud Docker daemon'ile REST API kaudu
- Suhtlus toimub läbi UNIX socket'i (`/var/run/docker.sock`) või TCP ühenduse
- Client võib olla erineval masinal kui daemon (remote Docker)

#### 2. Docker Daemon (dockerd)

Docker daemon on server, mis:
- Kuulab Docker API päringuid
- Haldab Docker objekte (images, containers, networks, volumes)
- Suhtleb teiste daemon'itega (distributed systems)
- Kasutab containerd'i konteinerite käivitamiseks

**Daemon'i põhifunktsioonid:**
- **Image management:** Image'ite ehitamine, salvestamine, kustutamine
- **Container lifecycle:** Konteinerite loomine, käivitamine, peatamine, kustutamine
- **Network management:** Võrkude loomine ja haldamine konteinerite vahel
- **Volume management:** Andmete püsivuse haldamine
- **Registry communication:** Image'ite push/pull registry'st

#### 3. Docker Registry (Docker Hub)

Registry on teenus, mis salvestab Docker image'id:

**Docker Hub** (hub.docker.com):
- Avalik, tasuta registry
- Miljonid official ja community image'd
- Private repositories (tasulised)
- Automated builds

**Teised registries:**
- **Private registries:** Ettevõtte enda registry (Harbor, JFrog Artifactory)
- **Cloud registries:** AWS ECR, Google GCR, Azure ACR
- **GitLab/GitHub Container Registry**

**Image nimetamine:**
```
[registry]/[username]/[repository]:[tag]

docker.io/library/nginx:latest          # Docker Hub official
docker.io/mycompany/myapp:1.0           # Docker Hub private
ghcr.io/myorg/myapp:latest              # GitHub Container Registry
myregistry.com:5000/team/app:v2.0       # Private registry
```

### Docker Image vs Container

See on üks olulisemaid kontseptsioone Docker'is:

#### Docker Image (Pilt)

**Definitsioon:** Read-only template, mis sisaldab kõike vajalikku rakenduse käivitamiseks.

**Image koosneb:**
- **Base layer:** Operatsioonisüsteem (nt Ubuntu, Alpine Linux)
- **Application layer:** Rakendus ja selle kood
- **Dependencies layer:** Teegid, runtime'id (Node.js, Java, Python)
- **Configuration layer:** Konfiguratsioonifailid, environment variables

**Image on layer'ite komplekt:**

```
┌─────────────────────────────────────────┐
│  myapp:1.0 (Image)                      │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ Layer 4: CMD ["node", "app.js"]   │ │ ← Käivituskäsk
│  │          (metadata, 0 bytes)      │ │
│  ├───────────────────────────────────┤ │
│  │ Layer 3: COPY . /app              │ │ ← Rakenduse kood
│  │          (5MB)                    │ │
│  ├───────────────────────────────────┤ │
│  │ Layer 2: RUN npm install          │ │ ← Node.js sõltuvused
│  │          (50MB node_modules)      │ │
│  ├───────────────────────────────────┤ │
│  │ Layer 1: FROM node:18-alpine      │ │ ← Base OS + Node.js
│  │          (150MB)                  │ │
│  └───────────────────────────────────┘ │
│                                         │
│  Total: 205MB (read-only)               │
└─────────────────────────────────────────┘
```

**Image omadused:**
- ✅ **Read-only:** Image'i ei saa muuta pärast loomist
- ✅ **Layer'ite süsteem:** Iga muudatus loob uue layer'i
- ✅ **Shared layers:** Mitmed image'd võivad jagada baas-layer'eid (säästab ruumi)
- ✅ **Versioonistatav:** Image'il on tag'id (v1.0, v1.1, latest)
- ✅ **Portaabel:** Sama image töötab igas Docker keskkonnas

#### Docker Container (Konteiner)

**Definitsioon:** Käivitatav instants image'ist koos kirjutatava layer'iga (writeable layer).

```
┌─────────────────────────────────────────┐
│  myapp-container (Container)            │
│  PID: 12345 (running)                   │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ Writeable Layer (Container Layer) │ │ ← Muudatused konteineri käitumise ajal
│  │ • /var/log/app.log (logid)        │ │   (kaduvad pärast kustutamist)
│  │ • /tmp/cache                      │ │
│  │ • Modified files                  │ │
│  │ (100MB, READ-WRITE)               │ │
│  ├───────────────────────────────────┤ │
│  │                                   │ │
│  │  Image Layers (myapp:1.0)         │ │ ← Image on read-only
│  │  • Layer 4 (CMD)                  │ │
│  │  • Layer 3 (kood)                 │ │
│  │  • Layer 2 (npm install)          │ │
│  │  • Layer 1 (node:18-alpine)       │ │
│  │  (205MB, READ-ONLY)               │ │
│  └───────────────────────────────────┘ │
│                                         │
│  Network: bridge (IP: 172.17.0.2)       │
│  Ports: 3000:3000                       │
│  Volumes: /data -> /var/lib/app/data    │
└─────────────────────────────────────────┘
```

**Container omadused:**
- ✅ **Writeable layer:** Konteineril on oma muudetav failisüsteem layer
- ✅ **Protsess:** Konteiner on käivitatud protsess (võib peatada, taaskäivitada, kustutada)
- ✅ **Isoleeritud:** Oma võrk, failisüsteem, protsessid (Linux namespaces)
- ✅ **Ephemeral:** Kui kustutad konteineri, kaob writeable layer (kui ei kasuta volumes'id)
- ✅ **Mitmed konteinerid samast image'ist:** Üks image → mitu konteinerit

**Analoogia:**
- **Image** = **Klass** (OOP): Template, mille järgi luuakse objekte
- **Container** = **Objekt** (instance): Käivitatav instants klassist

**Näide:**
```bash
# Image: nginx:latest (read-only template)
docker pull nginx:latest

# Loomine: Luuakse mitu konteinerit samast image'ist
docker run -d --name web1 -p 8081:80 nginx:latest
docker run -d --name web2 -p 8082:80 nginx:latest
docker run -d --name web3 -p 8083:80 nginx:latest

# Tulemus: 3 eraldi töötavat Nginx konteinerit, kõik sama image'i põhjal
# Iga konteineril on oma writeable layer, aga jagavad sama image layers'id
```

### Docker Workflow: Image'ist konteinerini

Tüüpiline Docker workflow:

```
┌─────────────┐
│ 1. Dockerfile│  ← Kirjuta juhised (FROM, RUN, COPY, CMD)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 2. Build    │  ← $ docker build -t myapp:1.0 .
│   (Image)   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 3. Push     │  ← $ docker push myapp:1.0 (opsionaalne)
│   (Registry)│
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 4. Pull     │  ← $ docker pull myapp:1.0 (teisel masinal)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ 5. Run      │  ← $ docker run -d -p 3000:3000 myapp:1.0
│ (Container) │
└─────────────┘
```

**Samm-sammult:**

1. **Dockerfile loomine:** Kirjuta tekstifail `Dockerfile` juhisega
2. **Image ehitamine:** `docker build` loob image'i Dockerfile'i põhjal
3. **Image salvestamine:** `docker push` saadab image'i registry'sse (opsionaalne)
4. **Image tõmbamine:** `docker pull` tõmbab image'i registry'st (kui vaja)
5. **Konteineri käivitamine:** `docker run` loob ja käivitab konteineri image'ist

### Docker'i põhiline värk (layered filesystem)

Docker kasutab **layer'ite süsteemi** (layered filesystem), mis teeb image'd väga efektiivseks:

**Copy-on-Write (CoW) strateegia:**
- Image layer'd on **read-only**
- Kui konteiner muudab faili, kopeeritakse see **writeable layer'isse**
- Kui konteiner kustutatakse, kaob writeable layer, aga image jääb alles

**Eelised:**
- **Ruumi säästmine:** Mitmed image'd jagavad sama baas-layer'eid
- **Kiire image build:** Cache layer'd, mis pole muutunud
- **Kiire konteineri start:** Pole vaja kopeerida tervet failisüsteemi

**Näide:**
```
# Kolm erinevat image'i, mis kõik kasutavad sama base layer'i

Image: myapp-backend:1.0           Image: myapp-frontend:1.0        Image: nginx:latest
├─ Layer 3: Backend code (5MB)     ├─ Layer 3: Frontend code (3MB)  ├─ Layer 2: Nginx config
├─ Layer 2: Node modules (50MB)    ├─ Layer 2: npm packages (40MB)  │
├─ Layer 1: node:18 (150MB) ───────┴──────────────────────────────┬─┴─ Layer 1: ubuntu:22.04 (80MB)

Disk ruumi kasutus:
- Ilma layer jagamiseta: 150 + 150 + 80 = 380MB
- Layer jagamisega: 150 + 5 + 50 + 3 + 40 + (Nginx layers) = ~250MB
```

## Praktilised Näited

### Näide 1: Docker'i installeerimine Ubuntu süsteemis

Docker'i installeerimine Ubuntu/Debian süsteemis (ametlik meetod):

```bash
# 1. Eelnevate versioonide eemaldamine (kui olemas)
sudo apt-get remove docker docker-engine docker.io containerd runc

# 2. APT repository seadistamine
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. Docker'i GPG võtme lisamine
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. Docker'i repository lisamine APT allikatesse
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Docker Engine installeerimine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# 6. Kontrolli installatsiooni
sudo docker --version
# Väljund: Docker version 24.0.x, build...

sudo docker run hello-world
# Käivitab test konteineri ja näitab kinnitussõnumit
```

**Docker'i käivitamine ilma sudo'ta (opsionaalne):**

```bash
# Lisa oma kasutaja docker gruppi
sudo usermod -aG docker $USER

# Logi välja ja uuesti sisse (või käivita):
newgrp docker

# Nüüd saad kasutada docker käske ilma sudo'ta
docker ps
docker images
```

**Kontroll:**
```bash
# Docker teenuse staatus
sudo systemctl status docker

# Docker info
docker info

# Docker versioon (detailne)
docker version
```

### Näide 2: Esimene Docker konteiner - "Hello World"

```bash
# Käivita hello-world test konteiner
docker run hello-world
```

**Mis juhtub?**

1. **Lokaalne otsing:** Docker otsib image'i `hello-world` lokaalsest cache'ist
2. **Registry download:** Kui pole leitud, tõmbab Docker Hub'ist (`docker.io/library/hello-world:latest`)
3. **Konteineri loomine:** Loob konteineri image'ist
4. **Käivitamine:** Käivitab konteineri, mis prindib tervitussõnumi
5. **Exit:** Konteiner lõpetab töö (status: Exited)

**Väljund:**
```
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
719385e32844: Pull complete
Digest: sha256:88ec0acaa3ec199d3b7eaf73588f4518c25f9d34f58ce9a0df68429c5af48e8d
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from Docker Hub.
 3. The Docker daemon created a new container from that image.
 4. The Docker daemon streamed that output to the Docker client.
```

**Kontroll:**
```bash
# Vaata lokaalseid image'id (hello-world on nüüd olemas)
docker images
# REPOSITORY     TAG       IMAGE ID       CREATED        SIZE
# hello-world    latest    9c7a54a9a43c   4 months ago   13.3kB

# Vaata kõiki konteinereid (kaasa arvatud stopped)
docker ps -a
# CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS                      PORTS     NAMES
# abc123def456   hello-world   "/hello"   10 seconds ago   Exited (0) 8 seconds ago              quirky_euler
```

### Näide 3: Interaktiivne konteiner - Ubuntu bash

```bash
# Käivita Ubuntu konteiner interaktiivses režiimis
docker run -it ubuntu:22.04 bash
```

**Flag'id selgitus:**
- `-i` (--interactive): Hoia STDIN avatud (saad sisestada käske)
- `-t` (--tty): Loo pseudo-TTY (terminal)
- `bash`: Käivita bash shell konteineris

**Tulemus:**
```
Unable to find image 'ubuntu:22.04' locally
22.04: Pulling from library/ubuntu
aece8493d397: Pull complete
Digest: sha256:...
Status: Downloaded newer image for ubuntu:22.04

root@4f8d9b3c2a1e:/# ← Nüüd oled SEES konteineris!
```

**Katseta konteineri sees:**
```bash
# Kontroll: mis OS?
cat /etc/os-release
# Väljund: Ubuntu 22.04 LTS

# Mis protsessid töötavad?
ps aux
# Väljund: ainult bash (PID 1) ja ps (see on isoleeritud!)

# Installi midagi (näiteks curl)
apt-get update && apt-get install -y curl

# Testi
curl https://google.com
# Väljund: HTML...

# Välju konteinerist
exit
```

**Mis juhtus?**
- Kui käsid `exit`, **konteiner peatus** (Exited status)
- Kõik muudatused (nt curl installatsioon) on **writeable layer'is**
- Need muudatused **kaovad**, kui kustutad konteineri

**Kontroll:**
```bash
# Vaata peatunud konteinerit
docker ps -a
# CONTAINER ID   IMAGE          COMMAND   CREATED         STATUS                     PORTS     NAMES
# 4f8d9b3c2a1e   ubuntu:22.04   "bash"    2 minutes ago   Exited (0) 1 minute ago              xenodochial_darwin

# Taaskäivita sama konteiner
docker start -ai 4f8d9b3c2a1e
# Nüüd oled tagasi SAMAS konteineris (curl on endiselt olemas!)

# Kustuta konteiner
docker rm 4f8d9b3c2a1e
# Nüüd on kõik muudatused kadunud
```

### Näide 4: Nginx veebiserveri konteiner (background režiim)

```bash
# Käivita Nginx konteiner background režiimis (detached)
docker run -d -p 8080:80 --name my-nginx nginx:latest
```

**Flag'id selgitus:**
- `-d` (--detach): Käivita background'is (ei blokeeri terminali)
- `-p 8080:80`: Port mapping (host port 8080 → container port 80)
- `--name my-nginx`: Anna konteinerile nimi (muidu random nimi)
- `nginx:latest`: Image nimi ja tag

**Tulemus:**
```
Unable to find image 'nginx:latest' locally
latest: Pulling from library/nginx
a803e7c4b030: Pull complete
8b625c47d697: Pull complete
4d3239651a63: Pull complete
0f816efa513d: Pull complete
01d159b8db2f: Pull complete
5fb9a81470f3: Pull complete
9b1e1e7164db: Pull complete
Digest: sha256:...
Status: Downloaded newer image for nginx:latest

a7f3b8e9c2d1e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9
                                                  ↑
                                    Container ID (full)
```

**Kontroll:**
```bash
# Vaata töötavaid konteinereid
docker ps
# CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                  NAMES
# a7f3b8e9c2d1   nginx:latest   "/docker-entrypoint.…"   10 seconds ago   Up 9 seconds    0.0.0.0:8080->80/tcp   my-nginx

# Testi veebiserveri
curl http://localhost:8080
# Väljund: Nginx welcome page HTML

# Või ava brauseris: http://localhost:8080

# Vaata konteineri logisid
docker logs my-nginx
# 172.17.0.1 - - [23/Nov/2025:14:32:10 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/7.81.0" "-"

# Vaata konteineri ressursse (CPU, RAM)
docker stats my-nginx
# CONTAINER ID   NAME       CPU %     MEM USAGE / LIMIT   MEM %     NET I/O       BLOCK I/O   PIDS
# a7f3b8e9c2d1   my-nginx   0.00%     3.5MiB / 7.77GiB    0.04%     1.5kB / 796B  0B / 0B     5

# Peata konteiner
docker stop my-nginx

# Käivita uuesti
docker start my-nginx

# Kustuta konteiner (peab olema peatatud või kasuta -f)
docker rm -f my-nginx
```

### Näide 5: Docker põhikäsud (cheat sheet)

```bash
# ========== IMAGE MANAGEMENT ==========

# Tõmba image Docker Hub'ist
docker pull nginx:latest
docker pull node:18-alpine

# Vaata lokaalseid image'id
docker images
docker image ls

# Kustuta image
docker rmi nginx:latest
docker image rm node:18-alpine

# Image info (detailne)
docker image inspect nginx:latest

# Kustuta kasutamata image'd
docker image prune -a


# ========== CONTAINER MANAGEMENT ==========

# Käivita konteiner
docker run nginx                      # foreground
docker run -d nginx                   # background (detached)
docker run -it ubuntu bash            # interactive

# Port mapping ja nimi
docker run -d -p 8080:80 --name web nginx

# Environment variables
docker run -d -e "DB_HOST=postgres" -e "DB_PORT=5432" myapp

# Volume mount
docker run -d -v /host/path:/container/path nginx

# Vaata konteinereid
docker ps                             # ainult running
docker ps -a                          # kõik (ka stopped)

# Peata/käivita
docker stop my-nginx
docker start my-nginx
docker restart my-nginx

# Kustuta konteiner
docker rm my-nginx                    # stopped konteiner
docker rm -f my-nginx                 # force (ka running)

# Käivita käsk töötavas konteineris
docker exec -it my-nginx bash         # ava shell konteineris
docker exec my-nginx ls /etc/nginx    # käivita käsk ja näita väljundit

# Logid
docker logs my-nginx                  # kõik logid
docker logs -f my-nginx               # follow (real-time)
docker logs --tail 100 my-nginx       # viimased 100 rida

# Konteiner info
docker inspect my-nginx               # JSON formaat (detailne)
docker stats my-nginx                 # ressursid (CPU, RAM)

# Kopeeri failid konteineri ja hosti vahel
docker cp my-nginx:/etc/nginx/nginx.conf ./nginx.conf
docker cp ./index.html my-nginx:/usr/share/nginx/html/


# ========== CLEANUP ==========

# Kustuta kõik peatunud konteinerid
docker container prune

# Kustuta kõik kasutamata image'd
docker image prune -a

# Kustuta kõik kasutamata volumes
docker volume prune

# Kustuta kõik kasutamata network'd
docker network prune

# Kustuta KÕIK kasutamata ressursid (images, containers, volumes, networks)
docker system prune -a --volumes


# ========== NETWORK ==========

# Vaata network'e
docker network ls

# Loo network
docker network create my-network

# Käivita konteiner network'is
docker run -d --name web --network my-network nginx


# ========== VOLUME ==========

# Vaata volume'id
docker volume ls

# Loo volume
docker volume create my-data

# Käivita konteiner volume'iga
docker run -d -v my-data:/var/lib/data postgres
```

## Levinud Probleemid ja Lahendused

### Probleem 1: "Permission denied" Docker käskude käivitamisel

**Sümptom:**
```bash
docker ps
# Got permission denied while trying to connect to the Docker daemon socket
```

**Põhjus:** Docker daemon vajab root õigusi. Kasutaja pole `docker` grupis.

**Lahendus:**
```bash
# Lisa kasutaja docker gruppi
sudo usermod -aG docker $USER

# Logi välja ja uuesti sisse (või käivita):
newgrp docker

# Nüüd peaks töötama
docker ps
```

### Probleem 2: Port on juba kasutuses

**Sümptom:**
```bash
docker run -d -p 8080:80 nginx
# Error: Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Põhjus:** Host süsteemis töötab juba midagi port 8080 peal.

**Lahendus:**
```bash
# Vaata, mis kasutab porti 8080
sudo lsof -i :8080
# või
sudo netstat -tulpn | grep 8080

# Variandid:
# 1. Peata teine teenus
# 2. Kasuta teist porti
docker run -d -p 8081:80 nginx  # kasuta hoopis 8081

# 3. Kustuta vana konteiner (kui see oli Docker konteiner)
docker ps -a | grep 8080
docker rm -f <container_id>
```

### Probleem 3: Konteiner kohe peatub (Exited status)

**Sümptom:**
```bash
docker run -d ubuntu
# Konteiner käivitub, aga kohe peatub

docker ps -a
# STATUS: Exited (0) 1 second ago
```

**Põhjus:** Docker konteiner töötab nii kaua, kui **main protsess töötab**. Ubuntu image'il pole default protsessi, mis jookseks pidevalt.

**Lahendus:**
```bash
# Käivita long-running protsessiga
docker run -d ubuntu sleep infinity  # jookseb lõpmatuseni

# Või käivita interaktiivses režiimis
docker run -it ubuntu bash

# Või kasuta teenuse image'i (nginx, postgres), mis töötab pidevalt
docker run -d nginx
```

### Probleem 4: "No space left on device"

**Sümptom:**
```bash
docker build -t myapp .
# Error: no space left on device
```

**Põhjus:** Docker võtab palju disk ruumi (images, containers, volumes).

**Lahendus:**
```bash
# Kontrolli Docker disk kasutust
docker system df
# TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
# Images          25        5         15.5GB    12GB (77%)
# Containers      50        2         1.2GB     1.1GB (91%)
# Local Volumes   10        3         5GB       2GB (40%)

# Puhasta kasutamata ressursid
docker system prune -a --volumes
# WARNING! This will remove:
#   - all stopped containers
#   - all networks not used by at least one container
#   - all images without at least one container associated to them
#   - all build cache
#   - all volumes not used by at least one container

# Kinnita: Are you sure? y
```

### Probleem 5: Image'i ei leita Docker Hub'ist

**Sümptom:**
```bash
docker pull mycompany/myapp:latest
# Error response from daemon: pull access denied for mycompany/myapp
```

**Põhjus:** Image on private või ei eksisteeri.

**Lahendus:**
```bash
# 1. Logi Docker Hub'i (kui private image)
docker login
# Username: <username>
# Password: <password>
# Login Succeeded

# Nüüd proovi uuesti
docker pull mycompany/myapp:latest

# 2. Kontrolli image nime õigekirja
# Õige formaat: [registry]/[username]/[repository]:[tag]
docker pull docker.io/mycompany/myapp:latest
```

## Best Practices

### DO's (Tee nii):

- ✅ **Kasuta official image'id baasiks:** `FROM node:18-alpine` on turvalisem kui `FROM ubuntu + RUN apt-get install node`
- ✅ **Tag'i image'd versiooniga:** `myapp:1.0.5` on parem kui `myapp:latest` (predictable deployments)
- ✅ **Kasuta .dockerignore faili:** Väldi node_modules/, .git/, build/ kaasamine image'isse
- ✅ **Puhasta regulaarselt:** `docker system prune -a` kord nädalas (säästab disk ruumi)
- ✅ **Nimeta konteinereid:** `--name my-app` on parem kui random nimed (selgem haldamine)
- ✅ **Kasuta volume'id andmete püsivuseks:** `-v postgres-data:/var/lib/postgresql/data` (data persistence)
- ✅ **Defineeri resource limits:** `--memory="512m" --cpus="1.0"` (väldi resource starvation)
- ✅ **Logi oma image'd registry'sse:** Backup ja multi-host deployment
- ✅ **Kasuta health checks:** `HEALTHCHECK CMD curl http://localhost/ || exit 1` (monitoring)
- ✅ **Dokumenteeri:** README.md koos Docker käskudega (onboarding)

### DON'Ts (Väldi):

- ❌ **Ära käivita konteinereid root user'ina:** Turvalisuse risk (kasuta `USER node`, `USER 1000`)
- ❌ **Ära hoia secrets image'ites:** Passwords, API keys (kasuta environment variables või secrets management)
- ❌ **Ära kasuta `latest` tag'i production'is:** `latest` muutub, versioonid on predictable
- ❌ **Ära kopeeri kogu projekti image'isse:** .dockerignore (node_modules, .git, logs) säästab ruumi
- ❌ **Ära unusta puhastamist:** Vanad image'd ja konteinerid võtavad disk ruumi
- ❌ **Ära installi debug tools production image'isse:** vim, curl, wget suurendavad image size'i ja attack surface
- ❌ **Ära käivita mitut protsessi ühes konteineris:** 1 konteiner = 1 protsess (mikroteenuste põhimõte)
- ❌ **Ära muuda image'it pärast build'i:** Kui vaja muudatusi, rebuild image (immutability)

## Kokkuvõte

Docker revolutsioneerib rakenduste deployment'i läbi **konteineriseerimise**:

**Võtmepunktid:**
1. **Konteinerid vs VM'd:** Konteinerid on kergemad (50-500MB), kiiremad (<1s start), efektiivsemad kui virtuaalmasinad
2. **Docker arhitektuur:** Client → Daemon → Registry (3-tier arhitektuur)
3. **Image vs Container:** Image on read-only template, Container on käivitatav instants image'ist
4. **Layer'ite süsteem:** Image koosneb layer'itest, mis on sharable ja cacheable (efektiivsus)
5. **Workflow:** Dockerfile → Build → (Push) → Pull → Run (CI/CD pipeline)
6. **Isolatsioon:** Konteinerid jagavad host kerneli, kuid on omavahel isoleeritud (namespaces, cgroups)

**Viide laboratooriumidele:**
- **Lab 1:** Dockerize kolme mikroteenust (Node.js, Java Spring Boot, frontend)
- **Lab 2:** Docker Compose multi-container setup (kõik teenused koos)

**Järgmised sammud:**
- **Peatükk 6:** Dockerfile süntaks ja rakenduste konteineriseerimise detailid
- **Peatükk 6A:** Java/Spring Boot ja Node.js konteineriseerimise spetsiifika
- **Peatükk 7:** Docker image'ite haldamine, optimeerimine, registry workflow

## Viited ja Edasine Lugemine

### Ametlik dokumentatsioon:
- **Docker dokumentatsioon:** https://docs.docker.com/
- **Docker Hub:** https://hub.docker.com/
- **Docker CLI reference:** https://docs.docker.com/engine/reference/commandline/cli/
- **Docker architecture:** https://docs.docker.com/get-started/overview/

### Best practices:
- **Docker best practices:** https://docs.docker.com/develop/dev-best-practices/
- **Dockerfile best practices:** https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- **Docker security:** https://docs.docker.com/engine/security/

### Õpimaterjalid:
- **Play with Docker:** https://labs.play-with-docker.com/ (interaktiivne playground)
- **Docker Curriculum:** https://docker-curriculum.com/
- **Awesome Docker:** https://github.com/veggiemonk/awesome-docker (ressursside kollektsioon)

### Täiendavad tööriistad:
- **Dive:** Image layer'ite analüüs (https://github.com/wagoodman/dive)
- **Trivy:** Container security scanning (https://github.com/aquasecurity/trivy)
- **Portainer:** Docker GUI haldamise tööriist (https://www.portainer.io/)

---

**Viimane uuendus:** 2025-11-23
**Seos laboritega:** Lab 1 (Docker Põhitõed), Lab 2 (Docker Compose)
**Järgmine peatükk:** 06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md
