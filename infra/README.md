# LXD DevOps Laborikeskkonna Dokumentatsioon

## Ülevaade

See kataloog sisaldab kogu dokumentatsiooni VPS-põhise LXD DevOps laborikeskkonna kohta, mis võimaldab 2-3 õpilasel samaaegselt töötada isoleeritud keskkondades.

**Deployment kuupäev:** 2025-11-25
**Platform:** LXD konteinerid Ubuntu 24.04 VPS-il
**Õpilasi:** 3 (devops-student1, devops-student2, devops-student3)
**Labid:** 10 praktilist labi (45 tundi kokku)

---

## Dokumentatsioon

| Fail | Kirjeldus | Sihtgrupp |
|------|-----------|-----------|
| **ARHITEKTUUR.md** | Süsteemi arhitektuur, diagrammid, komponendid | Admin, DevOps |
| **ADMIN-GUIDE.md** | Administraatori juhend (konteinerite haldamine) | Admin |
| **TECHNICAL-SPECS.md** | Tehnilised detailid, konfiguratsioonid | Admin, DevOps |
| **README.md** | See fail (ülevaade) | Kõik |
| **[../labs/README.md](../labs/README.md)** | Õpilase juhend (SSH, labid, käsud) | Õpilased |

---

## Kiirviited

### Administraatorile

**Levinumad toimingud:**
```bash
# Vaata kõiki konteinereid
sg lxd -c "lxc list"

# Logi konteinerisse
sg lxd -c "lxc exec devops-student1 -- bash"

# Kontrolli ressursse
sg lxd -c "lxc list -c ns4M"

# Restart konteiner
sg lxd -c "lxc restart devops-student1"

# Loo snapshot
sg lxd -c "lxc snapshot devops-student1 backup-$(date +%Y%m%d)"
```

**Täpsemad juhised:** Vaata [ADMIN-GUIDE.md](ADMIN-GUIDE.md)

### Õpilasele

**SSH sisselogimine:**
```bash
# Student 1
ssh labuser@<vps-ip> -p 2201
Password: student1

# Student 2
ssh labuser@<vps-ip> -p 2202
Password: student2

# Student 3
ssh labuser@<vps-ip> -p 2203
Password: student3
```

**Esimesed sammud:**
```bash
# Kontrolli ressursse
check-resources

# Loe juhend
cd ~/labs/
cat README.md

# Alusta Lab 1
cd 01-docker-lab/
cat README.md
```

**Täpsemad juhised:** Vaata [labs/README.md](../labs/README.md)

---

## Süsteemi Konfiguratsioon

### Host Süsteem

```
OS: Ubuntu 24.04 LTS
RAM: 7.8GB + 4GB Swap
CPU: 2 cores (AMD SVM)
Disk: 96GB
Network: 1 external IP
```

### Konteinerid

| Nimi | IP | RAM | CPU | Pordid (SSH, Web, APIs) |
|------|-------|-----|-----|------------------------|
| devops-student1 | 10.67.86.225 | 2.5GB | 1 | 2201, 8080, 3000, 8081 |
| devops-student2 | 10.67.86.115 | 2.5GB | 1 | 2202, 8180, 3100, 8181 |
| devops-student3 | 10.67.86.175 | 2.5GB | 1 | 2203, 8280, 3200, 8281 |

### Template

```
Image: devops-lab-base
Base: Ubuntu 24.04
Docker: 29.0.4
Docker Compose: v2.40.3
Size: 494.69MB (compressed)
Labs: 1-10 (all included)
```

---

## Port Mapping

### SSH Juurdepääs

| Õpilane | Host Port | Container Port | Parool |
|---------|-----------|----------------|--------|
| Student 1 | 2201 | 22 | student1 |
| Student 2 | 2202 | 22 | student2 |
| Student 3 | 2203 | 22 | student3 |

### Web Teenused

| Teenus | Student 1 | Student 2 | Student 3 | Container Port |
|--------|-----------|-----------|-----------|----------------|
| Frontend | 8080 | 8180 | 8280 | 8080 |
| User API | 3000 | 3100 | 3200 | 3000 |
| Todo API | 8081 | 8181 | 8281 | 8081 |

**Brauserist ligipääs:**
- Frontend: `http://<vps-ip>:8080` (student1)
- User API: `http://<vps-ip>:3000/api` (student1)
- Todo API: `http://<vps-ip>:8081/api` (student1)

---

## Arhitektuur (Lühikokkuvõte)

```
┌─────────────────────────────────────────┐
│         VPS Host (Ubuntu 24.04)         │
│   RAM: 7.8GB + 4GB Swap, CPU: 2 cores  │
│                                         │
│  ┌────────────────────────────────┐    │
│  │       UFW Firewall             │    │
│  │  - Allow lxdbr0 traffic        │    │
│  │  - Port forwarding rules       │    │
│  └────────────────────────────────┘    │
│                 │                       │
│  ┌──────────────┴─────────────────┐    │
│  │      LXD (lxdbr0: 10.67.86.1)  │    │
│  └──────────────┬─────────────────┘    │
│                 │                       │
│     ┌───────────┼──────────┐           │
│     ↓           ↓          ↓           │
│  student1   student2   student3        │
│  .225       .115       .175            │
│  2.5GB      2.5GB      2.5GB           │
│  1 CPU      1 CPU      1 CPU           │
│  Docker     Docker     Docker          │
└─────────────────────────────────────────┘
         ↓ Port forwarding
┌─────────────────────────────────────────┐
│         Internet (External)             │
│  SSH: 2201/2202/2203                    │
│  Web: 8080/8180/8280, 3000-3200, 8081+  │
└─────────────────────────────────────────┘
```

**Täielik arhitektuur diagrammidega:** Vaata [ARHITEKTUUR.md](ARHITEKTUUR.md)

---

## Põhitehnoloogiad

### LXD (Linux Containers)

- **Versioon:** Latest (Ubuntu 24.04 snap)
- **Bridge:** lxdbr0 (10.67.86.0/24)
- **Storage:** dir driver (directory-backed)
- **Security:** Unprivileged containers, nesting enabled

### Docker (Container Runtime)

- **Docker Engine:** 29.0.4
- **Docker Compose:** v2.40.3 (plugin)
- **Storage Driver:** overlay2
- **Nested:** Enabled in LXD (`security.nesting: true`)

### Labid

- **Lab 1:** Docker Basics (4h)
- **Lab 2:** Docker Compose (5.25h)
- **Lab 3:** Kubernetes Basics (5h)
- **Lab 4:** Kubernetes Advanced (5h)
- **Lab 5:** CI/CD Pipeline (4h)
- **Lab 6:** Monitoring & Logging (4h)
- **Lab 7:** Security & Secrets (5h)
- **Lab 8:** GitOps with ArgoCD (5h)
- **Lab 9:** Backup & Disaster Recovery (5h)
- **Lab 10:** Terraform IaC (5h)

**Kokku:** 45 tundi praktilist DevOps õpet

---

## Peamised Funktsioonid

### ✅ Isolatsioon

- **Ressurssid:** Iga õpilane eraldatud RAM (2.5GB), CPU (1 core)
- **Võrk:** Privaatsed IP-d lxdbr0 bridge'is
- **Protsessid:** PID namespace isolation
- **Failisüsteem:** Mount namespace isolation
- **Turvalisus:** Unprivileged containers, user namespace remapping

### ✅ Nested Docker

- **Security nesting:** Enabled per container
- **Docker-in-LXD:** Töötab täielikult
- **Use case:** Labid 1-2 vajavad Docker konteinereid

### ✅ Port Forwarding

- **Meetod:** LXD proxy devices
- **Auto-managed:** LXD haldab iptables reegleid
- **Isoleeritud:** Iga õpilase pordid eraldi

### ✅ Template-based Deployment

- **Template:** devops-lab-base image
- **Kiire:** 30-60 sekundit per konteiner
- **Identsed:** Kõik õpilased sama keskkonna

### ✅ Backup & Recovery

- **Snapshots:** Per-container snapshots
- **Image export:** Täielik backup failina
- **Kiire taastamine:** Lõhke snapshot'ist minutitega

---

## Hooldus

### Igapäevane

```bash
# Kontrolli ressursse
free -h
df -h
sg lxd -c "lxc list -c ns4M"
```

### Iganädalane

```bash
# Backup kõik konteinerid
for c in devops-student1 devops-student2 devops-student3; do
    sg lxd -c "lxc snapshot $c weekly-$(date +%Y%m%d)"
done

# Puhasta vanad snapshots (>7 päeva)
# ... (vaata ADMIN-GUIDE.md)
```

### Igakuine

```bash
# Täielik backup (image export)
sg lxd -c "lxc publish devops-student1 --alias backup-$(date +%Y%m)"
sg lxd -c "lxc image export backup-$(date +%Y%m) /backup/"

# Template update (kui vajalik)
# ... (vaata ADMIN-GUIDE.md)
```

---

## Probleemide Lahendamine

### Konteiner ei käivitu

1. Vaata logisid: `sg lxd -c "lxc info <name> --show-log"`
2. Proovi restart: `sg lxd -c "lxc restart <name>"`
3. Loo uus template'ist (vaata ADMIN-GUIDE.md)

### Interneti-ühendus puudub

1. Kontrolli lxdbr0: `ip addr show lxdbr0`
2. Kontrolli UFW: `sudo ufw status verbose | grep lxdbr0`
3. Taaskäivita LXD: `sudo systemctl restart lxd`

### RAM täis

1. Kontrolli kasutust: `sg lxd -c "lxc list -c ns4M"`
2. Peata konteiner: `sg lxd -c "lxc stop <name>"`
3. Puhasta Docker: `sg lxd -c "lxc exec <name> -- docker system prune -af"`

**Rohkem troubleshooting'u:** Vaata ADMIN-GUIDE.md "Probleemide lahendamine" peatükki

---

## Turvalisus

### Praegune Seadistus

- ✅ Unprivileged LXD containers
- ✅ User namespace remapping (UID mapping)
- ✅ AppArmor profiles (lxc-container-default-cgns)
- ✅ Seccomp filtering
- ✅ Network isolation (private IPs)
- ✅ UFW firewall (lxdbr0 traffic allowed)

### Soovitused Tugevdamiseks

- ⚠️ SSH: Muuda paroolid tugevamaks
- ⚠️ SSH: Keela password auth, kasuta SSH keys
- ⚠️ SSH: Installi fail2ban
- ⚠️ Monitoring: Seadista alertid (RAM, disk > 80%)
- ⚠️ Updates: Automaatsed security updates

**Rohkem turvalisusest:** Vaata TECHNICAL-SPECS.md "Security Configuration" peatükki

---

## Ressurssid ja Viited

### Dokumentatsioon

- **LXD:** https://documentation.ubuntu.com/lxd/
- **Docker:** https://docs.docker.com/
- **Ubuntu:** https://ubuntu.com/server/docs

### Sisemised Dokumendid

- Laborid: `/home/janek/projects/hostinger/labs/`
- Apps: `/home/janek/projects/hostinger/labs/apps/`
- Arhitektuur: `/home/janek/projects/hostinger/labs/apps/ARHITEKTUUR.md`

### Foorum ja Tugi

- **LXD Forum:** https://discuss.linuxcontainers.org/
- **Docker Forum:** https://forums.docker.com/
- **Stack Overflow:** https://stackoverflow.com/questions/tagged/lxd

---

## Kontaktinfo

**Süsteemi Administraator:**
- E-mail: [lisage siia]
- Telefon: [lisage siia]

**Õppejõud:**
- E-mail: [lisage siia]
- Telefon: [lisage siia]

**Hädaabinumber (VPS provider):**
- Support: [lisage VPS provider support]

---

## Versiooniajalugu

| Kuupäev | Versioon | Muudatused |
|---------|----------|------------|
| 2025-11-25 | 1.0 | Esialgne deployment (3 õpilast, 10 labi) |

---

## Litsents ja Kasutusõigused

**Labori materjalid:**
- Autor: [lisage autor]
- Litsents: [määrake litsents]

**Tarkvara:**
- LXD: Apache 2.0 License
- Docker: Apache 2.0 License
- Ubuntu: GPLv3 ja muud

---

## Järgmised Sammud (Tulevikuplaanid)

### Lühiajaline (1-3 kuud)

- [ ] DNS-based routing (student1/2/3.kirjakast.cloud)
- [ ] SSL sertifikaadid (Let's Encrypt)
- [ ] Nginx reverse proxy host'is
- [ ] Automaatsed backups (cron)
- [ ] Monitoring ja alerting (Prometheus?)

### Pikaajaline (3-12 kuud)

- [ ] Kubernetes labid (Labs 3-4) tugi
- [ ] Täiendavad õpilased (4-6 õpilast)
- [ ] VPS upgrade (rohkem RAM/CPU)
- [ ] Centralized logging (ELK stack?)
- [ ] CI/CD integration (Labs 5-8)

---

## Kokkuvõte

See laborikeskkond pakub:

- **3 isoleeritud keskkonda** õpilastele
- **10 praktilist labi** (45h DevOps õpet)
- **Docker + Docker Compose** täielik tugi
- **Kiire deployment** template'ist
- **Lihtne haldamine** LXD CLI kaudu
- **Turvaline** (unprivileged containers, isolation)
- **Skaleeritav** (lisa rohkem õpilasi vajadusel)

**Alusta siit:**
- Admin: [ADMIN-GUIDE.md](ADMIN-GUIDE.md)
- Õpilane: [labs/README.md](../labs/README.md)
- Tehniline: [TECHNICAL-SPECS.md](TECHNICAL-SPECS.md)
- Arhitektuur: [ARHITEKTUUR.md](ARHITEKTUUR.md)

---

**Viimane uuendus:** 2025-11-25
**Dokumentatsiooni versioon:** 1.0
**Koostaja:** Claude Code (AI assistant)
**Ülevaataja:** VPS Admin
