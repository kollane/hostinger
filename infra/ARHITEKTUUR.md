# LXD DevOps Laborikeskkonna Arhitektuur

## Ülevaade

See on VPS-põhine mitme-õpilase DevOps laborikeskkond, mis kasutab LXD konteinerite virtualiseerimist. Süsteem võimaldab 2-3 õpilasel samaaegselt töötada isoleeritud keskkondades, kus neil on oma Docker, ressursid ja labori failid.

## Arhitektuuri Diagramm

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          VPS HOST SÜSTEEM                                │
│  OS: Ubuntu 24.04                                                        │
│  RAM: 7.8GB + 4GB Swap                                                   │
│  CPU: 2 cores (AMD SVM virtualization)                                   │
│  External IP: <vps-ip>                                                   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                        UFW FIREWALL                              │   │
│  │  - Allow lxdbr0 traffic (in/out/routed)                          │   │
│  │  - Port forwarding rules: 2201-2203, 8080-8281, 3000-3200       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                      LXD DAEMON                                  │   │
│  │  Bridge: lxdbr0 (10.67.86.0/24)                                  │   │
│  │  NAT: Enabled                                                    │   │
│  │  IPv4 DHCP: 10.67.86.2 - 10.67.86.254                            │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                    │                                     │
│                    ┌───────────────┼───────────────┐                    │
│                    │               │               │                    │
│  ┌─────────────────▼─────┐ ┌──────▼──────┐ ┌─────▼──────────────┐     │
│  │  devops-student1      │ │ devops-     │ │  devops-student3   │     │
│  │  IP: 10.67.86.225     │ │ student2    │ │  IP: 10.67.86.175  │     │
│  │  ┌──────────────────┐ │ │ IP:         │ │  ┌───────────────┐ │     │
│  │  │ labuser          │ │ │ 10.67.86.115│ │  │ labuser       │ │     │
│  │  │ Password:        │ │ │ ┌─────────┐ │ │  │ Password:     │ │     │
│  │  │ student1         │ │ │ │ labuser │ │ │  │ student3      │ │     │
│  │  ├──────────────────┤ │ │ │ Pass:   │ │ │  ├───────────────┤ │     │
│  │  │ Ubuntu 24.04     │ │ │ │ student2│ │ │  │ Ubuntu 24.04  │ │     │
│  │  │ RAM: 2.5GB       │ │ │ ├─────────┤ │ │  │ RAM: 2.5GB    │ │     │
│  │  │ CPU: 1 core      │ │ │ │Ubuntu   │ │ │  │ CPU: 1 core   │ │     │
│  │  │ Disk: 20GB       │ │ │ │24.04    │ │ │  │ Disk: 20GB    │ │     │
│  │  ├──────────────────┤ │ │ │RAM:2.5GB│ │ │  ├───────────────┤ │     │
│  │  │ Docker 29.0.4    │ │ │ │CPU:1core│ │ │  │ Docker 29.0.4 │ │     │
│  │  │ Docker Compose   │ │ │ ├─────────┤ │ │  │ Docker Compose│ │     │
│  │  │ v2.40.3          │ │ │ │Docker   │ │ │  │ v2.40.3       │ │     │
│  │  ├──────────────────┤ │ │ │29.0.4   │ │ │  ├───────────────┤ │     │
│  │  │ SSH Server       │ │ │ │Compose  │ │ │  │ SSH Server    │ │     │
│  │  │ Port: 22 (int)   │ │ │ │v2.40.3  │ │ │  │ Port: 22 (int)│ │     │
│  │  ├──────────────────┤ │ │ ├─────────┤ │ │  ├───────────────┤ │     │
│  │  │ Labs 1-10        │ │ │ │SSH:22   │ │ │  │ Labs 1-10     │ │     │
│  │  │ /home/labuser/   │ │ │ │(int)    │ │ │  │ /home/labuser/│ │     │
│  │  │ labs/            │ │ │ ├─────────┤ │ │  │ labs/         │ │     │
│  │  └──────────────────┘ │ │ │Labs 1-10│ │ │  └───────────────┘ │     │
│  └────────────────────────┘ │ └─────────┘ │ └────────────────────┘     │
│                              └─────────────┘                             │
└─────────────────────────────────────────────────────────────────────────┘
                                     │
                    External Access via Port Forwarding
                                     │
┌────────────────────────────────────┴─────────────────────────────────────┐
│                          INTERNET (External Access)                       │
│                                                                           │
│  SSH Access:                                                              │
│    ssh labuser@<vps-ip> -p 2201  →  devops-student1                     │
│    ssh labuser@<vps-ip> -p 2202  →  devops-student2                     │
│    ssh labuser@<vps-ip> -p 2203  →  devops-student3                     │
│                                                                           │
│  Web Access (when services running):                                     │
│    http://<vps-ip>:8080  →  student1 frontend                           │
│    http://<vps-ip>:8180  →  student2 frontend                           │
│    http://<vps-ip>:8280  →  student3 frontend                           │
│                                                                           │
│    http://<vps-ip>:3000  →  student1 user-service API                   │
│    http://<vps-ip>:3100  →  student2 user-service API                   │
│    http://<vps-ip>:3200  →  student3 user-service API                   │
│                                                                           │
│    http://<vps-ip>:8081  →  student1 todo-service API                   │
│    http://<vps-ip>:8181  →  student2 todo-service API                   │
│    http://<vps-ip>:8281  →  student3 todo-service API                   │
└───────────────────────────────────────────────────────────────────────────┘
```

## Komponentide Selgitus

### 1. VPS Host Süsteem

**Operatsioonisüsteem:** Ubuntu 24.04 LTS

**Ressursid:**
- RAM: 7.8GB (füüsiline) + 4GB Swap
- CPU: 2 cores, AMD virtualization (SVM) enabled
- Disk: 96GB
- Network: 1 external IP address

**Põhikomponendid:**
- LXD daemon (konteinerite haldamine)
- UFW firewall (võrguturve ja port forwarding)
- lxdbr0 bridge (konteinerite võrk)

### 2. LXD Konteinerite Platvorm

**LXD Bridge (lxdbr0):**
- Võrguaadress: 10.67.86.0/24
- DHCP vahemik: 10.67.86.2 - 10.67.86.254
- NAT enabled (konteinerid saavad internetti)
- IPv4 forwarding enabled

**LXD Profile (devops-lab):**
```yaml
name: devops-lab
config:
  limits.cpu: "1"
  limits.memory: 2560MiB
  security.nesting: "true"      # Docker-in-Docker tugi
  security.privileged: "false"  # Unprivileged konteiner
devices:
  root:
    path: /
    pool: default
    type: disk
    size: 20GB
```

**Template Image (devops-lab-base):**
- Base: Ubuntu 24.04 LTS
- Docker 29.0.4 + Docker Compose v2.40.3
- OpenSSH Server
- labuser kasutaja (docker grupis)
- Kõik laborifailid (/home/labuser/labs/)
- README.md ja bash aliases
- Size: 494.69MB (compressed image)

### 3. Õpilaskonteinerid

Igal õpilasel on identne keskkond:

**Konteiner konfiguratsioon:**
- OS: Ubuntu 24.04 LTS
- RAM: 2.5GB (soft limit)
- CPU: 1 core (shared)
- Disk: 20GB
- Network: eth0 (dhcp via lxdbr0)
- Nested Docker: Enabled

**Installitud tarkvara:**
- Docker Engine 29.0.4
- Docker Compose v2.40.3
- OpenSSH Server
- curl, wget, jq, git, vim, nano
- netstat, ps, htop

**Kasutaja:**
- Username: `labuser`
- Password: `student1` / `student2` / `student3`
- Home: `/home/labuser/`
- Groups: `docker`, `sudo` (limited)

**Laborifailid:**
```
/home/labuser/labs/
├── 01-docker-lab/
├── 02-docker-compose-lab/
├── 03-kubernetes-basics-lab/
├── ... (Labs 4-10)
├── apps/
│   ├── backend-nodejs/
│   ├── backend-java-spring/
│   └── frontend/
├── README.md
└── CLAUDE.md
```

### 4. Võrguarhitektuur

#### Port Forwarding (LXD Proxy Devices)

LXD kasutab proxy device'e, et suunata host pordi liiklust konteineritesse:

**Student 1 (devops-student1):**
```
Host:2201  → Container:22   (SSH)
Host:8080  → Container:8080 (Frontend)
Host:3000  → Container:3000 (User Service API)
Host:8081  → Container:8081 (Todo Service API)
```

**Student 2 (devops-student2):**
```
Host:2202  → Container:22   (SSH)
Host:8180  → Container:8080 (Frontend)
Host:3100  → Container:3000 (User Service API)
Host:8181  → Container:8081 (Todo Service API)
```

**Student 3 (devops-student3):**
```
Host:2203  → Container:22   (SSH)
Host:8280  → Container:8080 (Frontend)
Host:3200  → Container:3000 (User Service API)
Host:8281  → Container:8081 (Todo Service API)
```

#### UFW Firewall Reeglid

Host süsteemis on UFW konfigureeritud lubama LXD bridge liiklust:

```bash
# Allow traffic on LXD bridge
ufw allow in on lxdbr0
ufw route allow in on lxdbr0
ufw route allow out on lxdbr0
ufw default allow routed
```

See võimaldab:
- Konteineritel väljuda internetti (NAT)
- Konteinerite omavahelist kommunikatsiooni
- Host → Container port forwarding'u

### 5. Ressursside Jaotus

**Host Ressursid:**
- Total RAM: 7.8GB
- Swap: 4GB
- Current usage: ~1.9GB (host services + 3 containers)
- Available: ~5.9GB

**Konteinerite ressursid (iga õpilane):**
- RAM limit: 2.5GB
- Current usage: 260-400MB (idle state)
- CPU: 1 core (fair share scheduling)
- Disk: 20GB (thin provisioned)

**Kogu ressursside kasutus:**
```
3 containers × 2.5GB RAM = 7.5GB (theoretical max)
Actual idle usage: ~750MB (all 3 containers)
With Docker workload: ~1.5-2GB (estimated per container)
Total with workload: 4.5-6GB (+ 4GB swap available)
```

### 6. Isolatsioon ja Turvalisus

**Konteinerite isolatsioon:**
- Unprivileged LXD containers (user namespaces)
- Separate network namespaces
- Process isolation (PID namespaces)
- Filesystem isolation (mount namespaces)
- Resource limits (cgroups v2)

**Võrguisolatsioon:**
- Konteinerid ei näe üksteist otseselt
- Igal konteineril oma IP lxdbr0 võrgus
- NAT kaitse välja (host IP varjab konteinerite IP-d)
- Pordid eksponeeritud ainult vajalikud

**Turvalisuse kaalutlused:**
- Nested Docker (nesting=true) võimaldab Docker-in-Docker
- Paroolid on lihtsad (labori jaoks)
- SSH password authentication enabled (õppeotstarbel)
- Root juurdepääs konteineris piiratud

### 7. Docker-in-LXD Arhitektuur

**Kuidas Docker töötab konteineris:**

```
┌─────────────────────────────────────────┐
│    LXD Container (devops-student1)      │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Docker Daemon                    │ │
│  │  - Docker bridge (docker0)        │ │
│  │  - Container runtime (containerd) │ │
│  │  - Storage driver (overlay2)      │ │
│  └───────────────────────────────────┘ │
│           │                             │
│  ┌────────┴─────────────────────────┐  │
│  │  Docker Containers               │  │
│  │  ┌──────────┐  ┌──────────┐     │  │
│  │  │PostgreSQL│  │Node.js   │     │  │
│  │  │(User DB) │  │(User Svc)│     │  │
│  │  └──────────┘  └──────────┘     │  │
│  │  ┌──────────┐  ┌──────────┐     │  │
│  │  │PostgreSQL│  │Java      │     │  │
│  │  │(Todo DB) │  │(Todo Svc)│     │  │
│  │  └──────────┘  └──────────┘     │  │
│  │  ┌──────────┐                    │  │
│  │  │Frontend  │                    │  │
│  │  └──────────┘                    │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

**Võtmeseaded:**
- `security.nesting: true` - võimaldab Docker daemoni konteineris
- `security.privileged: false` - jääb unprivileged (turvalisem)
- AppArmor profile lubab nested containers

### 8. Skaleeritavus

**Praegune seadistus:**
- 3 õpilast samaaegselt
- Piisavalt ressursse Labs 1-2 jaoks

**Skaleerimise võimalused:**

**Vertikaalne (rohkem ressursse):**
- VPS upgrade (rohkem RAM/CPU)
- Konteinerite ressursside suurendamine

**Horisontaalne (rohkem õpilasi):**
- Lisa konteinereid (student4, student5...)
- Lisa portide mappinguid
- Vajalik: rohkem RAM-i (minimum 2GB per õpilane)

**DNS-based routing (tulevikus):**
```
student1.kirjakast.cloud  →  Nginx reverse proxy  →  devops-student1
student2.kirjakast.cloud  →  Nginx reverse proxy  →  devops-student2
student3.kirjakast.cloud  →  Nginx reverse proxy  →  devops-student3
```

Vajab:
- Nginx installimist host'is
- DNS A recordite loomist
- SSL sertifikaate (Let's Encrypt)

## Deployment Workflow

**Template-based deployment:**

```
1. [Template Image] devops-lab-base
        │
        ├─→ lxc launch → devops-student1
        ├─→ lxc launch → devops-student2
        └─→ lxc launch → devops-student3

2. Configure each:
   - Set password
   - Add SSH config
   - Add proxy devices (port forwarding)
   - Start services
```

**Eelised:**
- Kiire deployment (30-60 sekundit per konteiner)
- Identsed keskkonnad
- Lihtne update'ida (update template, redeploy)
- Snapshot'id võimalikud (backup)

## Maintenance ja Monitoring

**Container management:**
```bash
lxc list                    # Vaata kõiki konteinereid
lxc info <name>             # Container detailid
lxc exec <name> -- bash     # Logi konteinerisse
lxc restart <name>          # Taaskäivita
```

**Resource monitoring:**
```bash
lxc list -c ns4M            # Memory usage
lxc info <name> | grep CPU  # CPU usage
free -h                     # Host memory
htop                        # Overall system
```

**Backup strategy:**
```bash
lxc snapshot <name> <snap-name>   # Create snapshot
lxc restore <name> <snap-name>    # Restore
lxc publish <name> --alias backup # Export as image
```

## Kokkuvõte

See arhitektuur pakub:
- ✅ Turvalist isolatsiooni (unprivileged containers)
- ✅ Ressursside õiglast jagamist (cgroups limits)
- ✅ Kiiret deployment'i (template-based)
- ✅ Lihtsat haldamist (LXD CLI)
- ✅ Nested Docker tuge (Labs 1-2 jaoks)
- ✅ Skaleeritavust (rohkem õpilasi võimalik)
- ✅ Port-based routing (DNS tulevikus)

---

**Viimane uuendus:** 2025-11-25
**Versioon:** 1.0
**LXD versioon:** Latest (Ubuntu 24.04)
**Template fingerprint:** b36d81cae5b6eab9f3948ffe6706887c017d892cfad15b05a9de0ae7dccd0ad1
