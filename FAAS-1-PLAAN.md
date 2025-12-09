# FAAS 1 Tegevusplaan - Põhitõed ja Sissejuhatus

**Versioon:** 1.2
**Kuupäev:** 2025-12-09
**Staatus:** Valmis planeerimiseks

---

## Ülevaade

**FAAS 1** hõlmab 4 põhipeatükki (1-4), mis loovad DevOps koolituskava fundamentaalsed alused. Need on **üldised põhimõtted**, mis kehtivad igal pool, järgivad **parimaid praktikaid** ja **tööstuse standardeid**.

| Peatükk | Teema | Maht | Ajakulu | Prioriteet |
|---------|-------|------|---------|-----------|
| **1** | DevOps Sissejuhatus | 6-8 lk | 1.5h | Keskmine |
| **2** | Linux Põhitõed DevOps Kontekstis | 10-12 lk | 3.5h | Kõrge |
| **3** | Git DevOps Töövoos | 6-8 lk | 2h | Keskmine |
| **4** | Võrgutehnoloogia Alused | 6-8 lk | 2h | Kõrge |

**Kokku:** 28-36 lehekülge, ~14,000-18,000 sõna, ~9h töö

---

## Põhimõtted

### Üldine Lähenemine

**FAAS 1 peatükid on:**
- ✅ Üldised ja põhimõtteid selgitavad
- ✅ Töötavad igal pool (avalik internet, ettevõtte sisevõrk, VPN)
- ✅ Järgivad tööstuse parimaid praktikaid ja standardeid
- ✅ Selgitavad põhikonseptsioone algajale arusaadaval tasemel
- ✅ ILMA proksi-spetsiifiliste detailideta (need on Peatükk 6A's)

### Standardid ja Parimate Praktikate Allikad

**DevOps:**
- CALMS framework (Jez Humble, Gene Kim)
- DORA metrics (DevOps Research and Assessment)
- The DevOps Handbook, The Phoenix Project
- DevSecOps praktikad (Shift-Left Security)
- SRE (Site Reliability Engineering - Google)

**Linux:**
- FHS (Filesystem Hierarchy Standard)
- systemd (moderne süsteemi init)
- SSH public key authentication (RFC 4716)
- UFW (Ubuntu standard firewall)
- LSM (Linux Security Modules - SELinux, AppArmor)

**Git:**
- Conventional Commits (conventionalcommits.org)
- Semantic Versioning (semver.org)
- GitHub Flow / Git Flow
- Branch protection best practices

**Networking:**
- TCP/IP protocol suite (RFC 793, RFC 791)
- DNS (RFC 1034, RFC 1035)
- Private IP ranges (RFC 1918)
- CIDR notation (RFC 4632)
- OSI 7-layer model (ISO/IEC 7498)

### Miks FAAS 1 on oluline?

1. **Fundamentaalsed teadmised** - Alused KÕIGILE hilisematele peatükkidele
2. **Eeldused laboritele** - Linux, Git ja võrgutehnoloogia baasoskused
3. **DevOps mõtteviis** - Filosoofiline raamistik kogu programmi jaoks
4. **Tööstuse standardid** - Järgib väljakujunenud praktikaid

---

## Peatükk 1: DevOps Sissejuhatus

### Eesmärk

Luua arusaam DevOps filosoofiast, kultuurist ja tööriistadest, järgides **tööstuse parimaid praktikaid** (CALMS, DORA, SRE).

### Põhiteemad (uuendatud koos parimate praktikatega)

```markdown
- DevOps definitsioon ja põhimõisted
- DevOps vs traditsiooniline IT (Waterfall vs Agile vs DevOps)
- DevOps kultuur (CALMS framework)
- CI/CD põhimõtted (Continuous Integration, Continuous Delivery/Deployment)
- Infrastructure as Code (IaC) kontseptsioon
- DevSecOps (Security as Code, Shift-Left Security)
- SRE (Site Reliability Engineering) - põgus sissejuhatus
- Observability vs Monitoring (kaasaegne lähenemine)
- DORA metrics (deployment frequency, lead time, MTTR, change failure rate)
- DevOps tööriistad ülevaade (Docker, Kubernetes, Git, CI/CD tools, Monitoring)
- DevOps lifecycle (Plan → Code → Build → Test → Release → Deploy → Operate → Monitor)
```

### Struktuur (uuendatud)

```markdown
# Peatükk 1: DevOps Sissejuhatus

## Õpieesmärgid (5 punkti)
- ✅ Selgitada DevOps filosoofiat ja põhimõtteid (CALMS framework)
- ✅ Eristada DevOps'i traditsioonilistest IT meetoditest (Waterfall, Agile)
- ✅ Mõista CI/CD, IaC ja DevSecOps kontseptsioone
- ✅ Tunda SRE ja Observability põhimõtteid
- ✅ Tunda DevOps tööriistu ja DORA metrics'eid

## Põhimõisted (10-12 terminit)
- DevOps (DevOps)
- Pidev integratsioon (Continuous Integration - CI)
- Pidev kohaletoimetamine (Continuous Delivery - CD)
- Pidev paigaldamine (Continuous Deployment)
- Infrastruktuur kui kood (Infrastructure as Code - IaC)
- Turvalisus kui kood (Security as Code - DevSecOps)
- SRE (Site Reliability Engineering)
- Vaadeldavus (Observability)
- Konteineristamine (containerization)
- Orkestreerimine (orchestration)
- Jälgimine (monitoring)
- Automatiseerimine (automation)

## Teooria (70% - 4-5 lk)

### 1. Mis on DevOps?
- DevOps definitsioon
- Dev (Development) + Ops (Operations) = DevOps
- DevOps kui kultuur, mitte ainult tööriistad
- DevOps eesmärgid (faster deployment, higher quality, better collaboration)

### 2. DevOps vs Traditsioonilised Meetodid
- **Waterfall model** (jäik, aeglane, sequential)
- **Agile** (iterative, fast feedback, dev-focused)
- **DevOps** (Agile + Operations, full lifecycle)
- Võrdlustabel (deployment frequency, lead time, MTTR, change failure rate)

### 3. DevOps Kultuur ja Põhimõtted (CALMS Framework)
- **C**ulture (collaboration, shared responsibility, blameless culture)
- **A**utomation (automate everything - builds, tests, deployments)
- **L**ean (eliminate waste, continuous improvement, kaizen)
- **M**easurement (DORA metrics, monitoring, feedback loops)
- **S**haring (knowledge sharing, documentation, transparency)
- "You build it, you run it" (Amazon filosoofia)

### 4. CI/CD Põhimõtted
- **Continuous Integration (CI):**
  - Kood liitub sageli (daily, hourly)
  - Automated builds ja tests
  - Fast feedback
- **Continuous Delivery (CD):**
  - Kood on alati deployment-ready
  - Manual approval production'i
- **Continuous Deployment:**
  - Automaatne deployment production'i
  - Ei ole manual approval'i
- CI/CD pipeline diagram (ASCII art)

### 5. Infrastructure as Code (IaC)
- Mis on IaC?
- Deklaratiivne vs imperatiivne lähenemine
- IaC eelised (version control, reproducibility, automation)
- IaC tööriistad ülevaade (Terraform, Ansible, CloudFormation, Helm)

### 6. DevSecOps (Security as Code)
- Security kui osa DevOps'ist (mitte eraldi silo)
- Shift-Left Security (turvalisus arenduse alguses)
- Security automation (vulnerability scanning, SAST/DAST)
- Compliance as Code
- (Detailsem käsitlus: Peatükid 25-27)

### 7. SRE (Site Reliability Engineering) - Põgus Sissejuhatus
- SRE definitsioon (Google lähenemine)
- SRE vs DevOps (SRE on üks DevOps'i implementatsioon)
- SRE põhimõtted:
  - Error budgets (lubatud vigade määr)
  - Service Level Objectives (SLO)
  - Toil reduction (rutiinsete ülesannete automatiseerimine)
  - Blameless postmortems
- (Detailsem käsitlus: Peatükid 22-24)

### 8. Observability vs Monitoring
- **Traditional Monitoring:** Metrics, alerts (teame, mida otsida)
- **Observability:** Logs, metrics, traces (mõistame süsteemi seesmist käitumist)
- "Three pillars of Observability":
  - Logs (sündmuste salvestused)
  - Metrics (numbrilised mõõdikud)
  - Traces (distribueeritud süsteemide jälgimine)
- (Detailsem käsitlus: Peatükid 22-24)

### 9. DORA Metrics (DevOps Performance Metrics)
- **Deployment Frequency:** Kui sageli deploy'me?
- **Lead Time for Changes:** Commit'ist production'i kestus
- **Mean Time to Restore (MTTR):** Taastumise kiirus
- **Change Failure Rate:** Mitu % deployment'itest ebaõnnestub?
- Elite/High/Medium/Low performers klassifikatsioon

### 10. DevOps Tööriistad Ökoloogia
- **Konteinerid:** Docker, Kubernetes
- **CI/CD:** GitHub Actions, Jenkins, GitLab CI, CircleCI
- **Monitoring & Observability:** Prometheus, Grafana, Loki, Jaeger
- **IaC:** Terraform, Ansible
- **Source Control:** Git, GitHub, GitLab
- **Secrets Management:** Vault, Sealed Secrets
- **Security:** Trivy, Snyk, SonarQube
- Tööriistad lifecycle'i faaside kaupa (diagram)

### 11. DevOps Lifecycle
- **Plan** (Jira, Trello)
- **Code** (Git, IDE)
- **Build** (Docker, Maven, Gradle, npm)
- **Test** (Jest, JUnit, Selenium)
- **Release** (GitHub Releases, semantic versioning)
- **Deploy** (Kubernetes, Helm, ArgoCD)
- **Operate** (Kubernetes, systemd)
- **Monitor** (Prometheus, Grafana, Loki, Alerting)
- Feedback loop (Monitor → Plan)

## Praktilised Näited (30% - 2 lk)

### Näide 1: Traditional vs DevOps Deployment (DORA Metrics)
**Traditional (Waterfall):**
```
Deployment Frequency: 1x per quarter (90 days)
Lead Time: 4.5 months
MTTR: 1-2 weeks
Change Failure Rate: 30-40%
→ LOW performer
```

**DevOps (Elite):**
```
Deployment Frequency: Multiple per day
Lead Time: < 1 hour
MTTR: < 1 hour
Change Failure Rate: < 5%
→ ELITE performer
```

### Näide 2: CI/CD Pipeline Näide
```yaml
# .github/workflows/ci-cd.yml (GitHub Actions)
name: CI/CD Pipeline

on:
  push:
    branches: [main]

jobs:
  build-test-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t myapp:${{ github.sha }} .

      - name: Run tests
        run: docker run myapp:${{ github.sha }} npm test

      - name: Security scan (DevSecOps)
        run: trivy image myapp:${{ github.sha }}

      - name: Push to registry
        run: docker push myregistry/myapp:${{ github.sha }}

      - name: Deploy to Kubernetes
        run: kubectl set image deployment/myapp myapp=myregistry/myapp:${{ github.sha }}
```
**Selgitus:** Iga push main branch'i käivitab automaatse build → test → security scan → deploy workflow'i.

### Näide 3: Infrastructure as Code (Terraform)
```hcl
# Deklaratiivne lähenemine
resource "kubernetes_deployment" "myapp" {
  metadata {
    name = "myapp"
  }
  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "myapp"
      }
    }
    template {
      metadata {
        labels = {
          app = "myapp"
        }
      }
      spec {
        container {
          name  = "myapp"
          image = "myapp:1.0.0"
        }
      }
    }
  }
}
```
**Selgitus:** Infrastruktuur on koodina (version control, reproducible, auditable).

## Levinud Müüdid ja Väärarusaamad

### Müüt 1: "DevOps = Tööriistad"
**Tõde:** DevOps on esmajoones kultuur ja filosoofia (CALMS). Tööriistad aitavad, aga ilma kultuurita ei toimi.

### Müüt 2: "DevOps = DevOps Engineer"
**Tõde:** DevOps on kogu meeskonna vastutus (devs, ops, QA, security). "DevOps Engineer" on anti-pattern (tekitab silo'd).

### Müüt 3: "DevOps = Kubernetes"
**Tõde:** Kubernetes on üks tööriist paljudest. Väikesed projektid võivad kasutada lihtsalt Docker Compose'i.

### Müüt 4: "DevOps = NoOps"
**Tõde:** DevOps ei tähenda Ops'i kõrvaldamist. Operations on endiselt vajalik, aga koos Dev'iga.

### Müüt 5: "DevOps on ainult startup'idele"
**Tõde:** DevOps praktikad töötavad igas organisatsioonis (väike startup kuni suur enterprise).

### Müüt 6: "SRE ja DevOps on vastandlikud"
**Tõde:** SRE on üks DevOps'i implementatsioon (Google lähenemine). SRE kasutab DevOps põhimõtteid.

## Best Practices
- ✅ Alusta väikestest sammudest (ei pea kohe Kubernetes'ega alustama)
- ✅ Automatiseeri kõike, mida saad (builds, tests, deployments, security scans)
- ✅ Mõõda DORA metrics'eid (deployment frequency, lead time, MTTR, change failure rate)
- ✅ Jaga teadmisi (documentation, pair programming, blameless postmortems)
- ✅ Continuous improvement (retrospectives, kaizen)
- ✅ Shift-Left Security (turvalisus arenduse alguses)
- ✅ Observability > Monitoring (mõista süsteemi seesmist käitumist)
- ❌ Ära loo "DevOps team" (tekitab silo'd)
- ❌ Ära keskendu ainult tööriistadele (kultuur on tähtsam)
- ❌ Ära unusta turvalisust (DevSecOps)

## Kokkuvõte
- DevOps on kultuur, filosoofia ja praktikad (CALMS framework)
- CI/CD ja IaC on DevOps põhiprintsiibid
- DevSecOps = Security as Code (Shift-Left)
- SRE on üks DevOps'i implementatsioon (error budgets, SLO)
- Observability > Monitoring (logs + metrics + traces)
- DORA metrics mõõdavad DevOps performance'i
- DevOps eesmärk: kiire, kvaliteetne, turvaline deployment

## Viited ja Edasine Lugemine
- [The Phoenix Project - DevOps raamat](https://www.amazon.com/Phoenix-Project-DevOps-Helping-Business/dp/0988262592)
- [The DevOps Handbook](https://www.amazon.com/DevOps-Handbook-World-Class-Reliability-Organizations/dp/1942788002)
- [Accelerate: The Science of DevOps](https://www.amazon.com/Accelerate-Software-Performing-Technology-Organizations/dp/1942788339)
- [Site Reliability Engineering (SRE Book - Google)](https://sre.google/sre-book/table-of-contents/)
- [DORA Metrics](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)
- [CALMS Framework](https://www.atlassian.com/devops/frameworks/calms-framework)
- [DevOps Roadmap](https://roadmap.sh/devops)

---

**Viimane uuendus:** 2025-12-09 (planeeritud)
**Seos laboritega:** Üldine teoreetiline raamistik kõigile laboritele
**Eelmine peatükk:** -
**Järgmine peatükk:** 02-Linux-Pohitoed-DevOps-Kontekstis.md
```

### Kirjutamise Järjekord

1. **Teooria sektsioonid** (70%):
   - Mis on DevOps? → vs Traditional → CALMS → CI/CD → IaC → DevSecOps → SRE → Observability → DORA → Tööriistad → Lifecycle
2. **Praktilised näited** (30%):
   - DORA metrics võrdlus → CI/CD pipeline (DevSecOps) → IaC näide
3. **Müüdid ja väärarusaamad**:
   - 6 levinud müüti (lisa SRE müüt)
4. **Viimistlemine**:
   - Best practices, kokkuvõte, viited (lisa SRE Book)

---

## Peatükk 2: Linux Põhitõed DevOps Kontekstis

### Eesmärk

Õpetada Linuxi command-line (CLI) põhitõed, järgides **FHS (Filesystem Hierarchy Standard)**, **systemd** ja **Linux Security Modules (LSM)** standardeid.

### Põhiteemad (uuendatud koos turvalisuse põhimõtetega)

```markdown
- Bash käsud failide haldamiseks
  - Navigeerimine: ls, cd, pwd, tree
  - Failide manipuleerimine: cp, mv, rm, mkdir, touch
  - Failide vaatamine: cat, less, head, tail, grep
  - Otsimine: find, locate
- Failide õigused
  - chmod (numeric ja symbolic notation)
  - chown, chgrp
  - Spetsiaalsed õigused (setuid, setgid, sticky bit)
- Kasutajad ja grupid
  - useradd, usermod, userdel
  - groupadd, groupmod
  - /etc/passwd, /etc/group
  - sudo ja sudoers
- Linux turvalisus (põgus sissejuhatus)
  - SELinux vs AppArmor (LSM - Linux Security Modules)
  - Mandatory Access Control (MAC) vs Discretionary Access Control (DAC)
  - Kasutusjuhud DevOps'is
- SSH ja turvaline juurdepääs
  - SSH public key authentication (RFC 4716)
  - ssh-keygen, ssh-copy-id
  - SSH config (~/.ssh/config)
- Protsessid
  - ps, top, htop
  - kill, killall, pkill
  - Background/foreground (&, fg, bg, jobs)
- Süsteemiteenused (systemd)
  - systemctl (start, stop, restart, enable, disable, status)
  - journalctl (log vaatamine)
- Package management (APT)
  - apt (update, upgrade, install, remove, search)
  - apt-cache policy
- Environment variables
  - export, printenv, echo $VAR
  - .bashrc, .profile
- Firewall (ufw)
  - ufw enable/disable
  - ufw allow/deny
  - ufw status
```

### Struktuur (uuendatud koos LSM sektsiiooniga)

```markdown
# Peatükk 2: Linux Põhitõed DevOps Kontekstis

## Õpieesmärgid (8 punkti)
- ✅ Navigeerida Linuxi failisüsteemis (FHS standard)
- ✅ Hallata faile ja katalooge (cp, mv, rm, mkdir, chmod, chown)
- ✅ Otsida ja analüüsida faile (find, grep, tail)
- ✅ Mõista Linux turvalisuse põhimõtteid (SELinux/AppArmor)
- ✅ Hallata kasutajaid ja SSH autentimist
- ✅ Hallata protsesse (ps, top, kill)
- ✅ Kasutada systemctl'i teenuste haldamiseks
- ✅ Seadistada firewall'i (ufw)

## Põhimõisted (20-22 terminit)
- Terminal (terminal)
- Shell (shell - Bash)
- Käsk (command)
- Argument (argument)
- Toru (pipe - |)
- Standardväljund (stdout)
- Standardveaväljund (stderr)
- Õigused (permissions)
- Kasutaja (user)
- Grupp (group)
- SSH võti (SSH key)
- Protsess (process)
- Teenus (service / daemon)
- Pakett (package)
- Keskkonnamuutuja (environment variable)
- Tulemüür (firewall)
- MAC (Mandatory Access Control)
- DAC (Discretionary Access Control)
- SELinux (Security-Enhanced Linux)
- AppArmor (Application Armor)

## Teooria (70% - 7-8 lk)

### 1. Bash ja Command-Line Alused
- Mis on shell? (Bash, Zsh, Fish)
- CLI vs GUI: miks DevOps kasutab CLI'd?
- Käsu struktuur: command [options] [arguments]
- Pipes ja redirection (|, >, >>, 2>&1)

### 2. Failisüsteem ja Navigeerimine (FHS - Filesystem Hierarchy Standard)
- Linuxi failisüsteemi struktuur:
  - `/` - root
  - `/home` - kasutajate kodukataloogid
  - `/etc` - konfiguratsioonifailid
  - `/var` - muutuvad andmed (logs, cache)
  - `/usr` - kasutaja programmid
  - `/opt` - kolmandate osapoolte tarkvara
  - `/tmp` - ajutised failid
- Navigeerimiskäsud: ls, cd, pwd, tree
- Absoluutne vs relatiivne tee
- Peidetud failid (.bashrc, .env)

### 3. Failide Manipuleerimine
- Loomine: touch, mkdir
- Kopeerimine/liigutamine: cp, mv
- Kustutamine: rm, rmdir
- Vaatamine: cat, less, head, tail
- Otsimine: find, locate, grep
- Arhiveerimine: tar, gzip

### 4. Failide Õigused (DAC - Discretionary Access Control)
- Õiguste süsteem: rwx (read, write, execute)
- Numbriline vs sümboliline notatsioon (chmod 755 vs chmod u+x)
- Omanik ja grupp (chown, chgrp)
- Spetsiaalsed õigused (setuid, setgid, sticky bit)

### 5. Kasutajad ja Grupid
- useradd, usermod, userdel
- groupadd, groupmod
- /etc/passwd ja /etc/group failid
- sudo ja sudoers
- Non-root user vs root (turvaline praktika)

### 6. Linux Turvalisus (LSM - Linux Security Modules) - Põgus Sissejuhatus
- **DAC vs MAC:**
  - DAC (Discretionary): Kasutaja kontrollib oma failide õigusi (chmod, chown)
  - MAC (Mandatory): Süsteem kontrollib juurdepääsu (SELinux, AppArmor)
- **SELinux (Red Hat, CentOS, Fedora):**
  - Security contexts (user:role:type:level)
  - Enforcing vs Permissive vs Disabled
  - Kasutusjuht: Strict access control (finance, government)
- **AppArmor (Ubuntu, Debian, SUSE):**
  - Profile-based (faili tee põhine)
  - Enforce vs Complain
  - Kasutusjuht: Lihtsam kui SELinux (Ubuntu default)
- **DevOps kontekstis:**
  - Konteinerites: SELinux/AppArmor võivad mõjutada bind mounts'i
  - Best practice: Testa rakendusi mõlemas (SELinux ON ja OFF)
  - Troubleshooting: `ausearch -m avc` (SELinux), `dmesg | grep apparmor` (AppArmor)
- **(Detailsem käsitlus: Peatükk 25 - Security Best Practices)**

### 7. SSH ja Turvaline Juurdepääs (RFC 4716)
- Mis on SSH?
- Password authentication vs SSH key authentication
- SSH võtme genereerimine (ssh-keygen ed25519 > RSA)
- SSH võtme kopeerimine serverisse (ssh-copy-id)
- SSH config fail (~/.ssh/config)
- SSH agent (ssh-agent, ssh-add)

### 8. Protsesside Haldamine
- Mis on protsess?
- ps, top, htop
- kill, killall, pkill (signaalid: SIGTERM vs SIGKILL)
- Background/foreground (&, fg, bg, jobs, nohup)

### 9. Süsteemiteenused (systemd)
- Mis on systemd? (moderne init system, asendas SysVinit)
- systemctl käsud (start, stop, restart, enable, disable, status)
- journalctl (log vaatamine, tsentraliseeritud)
- Unit failid (/etc/systemd/system/)

### 10. Pakkide Haldamine (APT - Advanced Package Tool)
- apt update vs apt upgrade
- apt install, remove, purge
- apt search, apt-cache policy
- Repository'd (/etc/apt/sources.list)

### 11. Environment Variables
- Mis on env var?
- export, printenv, echo $VAR
- PATH, HOME, USER, PWD
- .bashrc, .profile, .bash_aliases

### 12. Firewall (UFW - Uncomplicated Firewall)
- Mis on firewall?
- UFW (Ubuntu standard, wraps iptables)
- ufw enable/disable
- ufw allow/deny (port, service, IP)
- ufw status verbose

## Praktilised Näited (30% - 3-4 lk)

### Näide 1: Failisüsteemi Navigeerimine (FHS)
```bash
# Failisüsteemi struktuuri vaatamine
tree -L 1 /
# /
# ├── bin -> usr/bin      # Põhikäsud
# ├── boot                # Kernel ja boot failid
# ├── etc                 # Konfiguratsioonid
# ├── home                # Kasutajate kataloogid
# ├── opt                 # 3rd party apps
# ├── tmp                 # Ajutised failid
# ├── usr                 # Kasutaja programmid
# └── var                 # Logid, cache

# Navigeerimine
cd /var/log
ls -lh  # Logifailid
```

### Näide 2: Failide Haldamine
```bash
# Kataloogi loomine ja navigeerimine
mkdir -p ~/projects/myapp
cd ~/projects/myapp

# Faili loomine ja vaatamine
echo "Hello DevOps" > README.md
cat README.md

# Failide kopeerimine
cp README.md README.backup

# Failide otsimine
find . -name "*.md"
grep "DevOps" *.md
```

### Näide 3: Õigused ja Omanikud
```bash
# Faili õigused
ls -la script.sh
# -rw-r--r-- 1 user group 256 Dec 09 10:00 script.sh

# Käivitusõiguse lisamine
chmod +x script.sh

# Numbriline notatsioon
chmod 755 script.sh  # rwxr-xr-x

# Omaniku muutmine
sudo chown root:root /etc/myconfig
```

### Näide 4: SELinux/AppArmor Kontroll (põgusalt)
```bash
# SELinux staatus (Red Hat/CentOS)
getenforce
# Enforcing / Permissive / Disabled

# AppArmor staatus (Ubuntu)
sudo aa-status
# apparmor module is loaded.

# Docker konteiner SELinux kontekstiga
docker run --security-opt label=type:container_t myapp

# Troubleshooting SELinux (kui bind mount ei tööta)
ausearch -m avc -ts recent
```

### Näide 5: Kasutajad ja SSH
```bash
# Uue kasutaja loomine
sudo useradd -m -s /bin/bash devops-user

# Kasutaja lisamine sudo gruppi
sudo usermod -aG sudo devops-user

# SSH võtme genereerimine (ed25519 on turvalisem kui RSA)
ssh-keygen -t ed25519 -C "devops@example.com"

# SSH võtme kopeerimine serverisse
ssh-copy-id user@server-ip

# SSH ühenduse testimine
ssh user@server-ip
```

### Näide 6: Protsessid ja Teenused (systemd)
```bash
# Protsesside vaatamine
ps aux | grep nginx

# Protsessi peatamine
kill -15 12345  # SIGTERM (graceful)
kill -9 12345   # SIGKILL (force)

# Systemd teenuste haldamine
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker

# Logide vaatamine (journalctl)
sudo journalctl -u docker -n 50
sudo journalctl -u docker --since "1 hour ago"
```

### Näide 7: Pakkide Paigaldamine (APT)
```bash
# Pakkide loendi uuendamine
sudo apt update

# Paketi paigaldamine
sudo apt install -y curl wget vim

# Paketi versioon
apt-cache policy docker-ce

# Süsteemi uuendamine
sudo apt upgrade -y
```

### Näide 8: Environment Variables
```bash
# Env var'i seadistamine
export MY_VAR="Hello World"
echo $MY_VAR

# PATH'i laiendamine
export PATH="$PATH:/opt/myapp/bin"

# .bashrc fail
echo 'export MY_VAR="Persistent"' >> ~/.bashrc
source ~/.bashrc
```

### Näide 9: Firewall (UFW)
```bash
# UFW lubamine
sudo ufw enable

# SSH lubamine (OLULINE enne ufw enable!)
sudo ufw allow 22/tcp

# HTTP/HTTPS lubamine
sudo ufw allow 80,443/tcp

# Specific IP lubamine
sudo ufw allow from 192.168.1.100 to any port 22

# Staatuse kontroll
sudo ufw status verbose

# Reegli kustutamine
sudo ufw delete allow 80/tcp
```

## Levinud Probleemid ja Lahendused

### Probleem 1: "Permission denied"
**Sümptom:** `bash: ./script.sh: Permission denied`
**Põhjus:** Failil pole käivitusõigust
**Lahendus:**
```bash
chmod +x script.sh
./script.sh
```

### Probleem 2: "No such file or directory"
**Sümptom:** `cp: cannot stat 'file.txt': No such file or directory`
**Põhjus:** Fail pole olemas või vale tee
**Lahendus:**
```bash
ls -la  # Kontrolli faili olemasolu
pwd     # Kontrolli praegust kataloogi
```

### Probleem 3: SSH võtme autentimine ebaõnnestub
**Sümptom:** `Permission denied (publickey)`
**Põhjus:** Vale õigused .ssh kataloogil või vigane võti
**Lahendus:**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### Probleem 4: SELinux blokeerib bind mount (Docker)
**Sümptom:** `Permission denied` Docker bind mount'imisel
**Põhjus:** SELinux enforcing mode
**Lahendus:**
```bash
# Variant A: Lisa :z või :Z bind mount'ile
docker run -v /host/path:/container/path:z myapp

# Variant B: Kontrolli SELinux konteksti
ls -Z /host/path
sudo chcon -Rt svirt_sandbox_file_t /host/path
```

### Probleem 5: UFW blokeerib SSH ühenduse
**Sümptom:** Ei saa serveriga ühendust peale ufw enable
**Põhjus:** SSH port polnud lubatud enne firewall'i sisselülitamist
**Lahendus:** Konsooli juurdepääs (KVM/console) ja `sudo ufw allow 22`

### Probleem 6: Protsess ei peatu
**Sümptom:** `kill 12345` ei peata protsessi
**Põhjus:** SIGTERM ei toimi (protsess ignoreerib)
**Lahendus:**
```bash
kill -9 12345  # SIGKILL (force kill)
```

### Probleem 7: "E: Could not get lock /var/lib/apt/lists/lock"
**Sümptom:** apt install ebaõnnestub lukustuse tõttu
**Põhjus:** Teine apt protsess töötab taustal
**Lahendus:**
```bash
ps aux | grep apt
sudo killall apt apt-get
sudo apt update
```

### Probleem 8: Environment variable pole püsiv
**Sümptom:** Peale logout'i on MY_VAR kadunud
**Põhjus:** export on session-specific
**Lahendus:**
```bash
echo 'export MY_VAR="value"' >> ~/.bashrc
source ~/.bashrc
```

### Probleem 9: Sudo õigused puuduvad
**Sümptom:** `user is not in the sudoers file`
**Põhjus:** Kasutaja pole sudo grupis
**Lahendus:** Root kasutajana `usermod -aG sudo username`

## Best Practices
- ✅ Kasuta tab completion'it (vajuta Tab klahvi)
- ✅ Kasuta SSH võtmeid (ed25519), MITTE paroole
- ✅ Kasuta non-root kasutajat (sudo), mitte root'i otse
- ✅ Seadista firewall (ufw) kohe peale serveri loomist
- ✅ Testi rakendusi SELinux/AppArmor ON ja OFF režiimis
- ✅ Kontrolli faili enne kustutamist (`ls -la` enne `rm -rf`)
- ✅ Kasuta `systemctl` teenuste haldamiseks, mitte `service`
- ✅ Logi hoiad (journalctl -u service-name)
- ✅ Kasuta absolute paths skriptides
- ✅ Keela root SSH login (PermitRootLogin no)
- ❌ Ära kasuta `rm -rf /` (kustutab süsteemi!)
- ❌ Ära chmod 777 kõike (turvarisk)
- ❌ Ära unusta sudo'ga `apt update` enne `apt install`
- ❌ Ära hoia privaatvõtmeid serverites (ainult avalikud võtmed)
- ❌ Ära keela SELinux/AppArmor, kui ei ole vaja (security risk)

## Kokkuvõte
- Bash on DevOps töövahend nr 1 - CLI on kiirem kui GUI
- FHS (Filesystem Hierarchy Standard) defineerib failisüsteemi struktuuri
- Failide õigused (DAC) ja omanikud on turvalisuse alus
- SELinux/AppArmor (MAC) pakuvad täiendavat turvalisust (eriti konteinerites)
- SSH võtmed (ed25519) on turvalisem kui paroolid
- systemd ja journalctl on teenuste haldamise standardid
- Firewall (ufw) on turvalisuse esimene kiht
- Environment variables on konfiguratsioonide haldamise vahend

## Viited ja Edasine Lugemine
- [Filesystem Hierarchy Standard (FHS)](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)
- [Linux Command Line Basics (Ubuntu)](https://ubuntu.com/tutorials/command-line-for-beginners)
- [Bash Scripting Tutorial](https://linuxconfig.org/bash-scripting-tutorial)
- [systemd Documentation](https://www.freedesktop.org/wiki/Software/systemd/)
- [SELinux User Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux)
- [AppArmor Documentation](https://gitlab.com/apparmor/apparmor/-/wikis/Documentation)
- [SSH Academy](https://www.ssh.com/academy/ssh)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)

---

**Viimane uuendus:** 2025-12-09 (planeeritud)
**Seos laboritega:** KÕIK laborid (Linux CLI baas, SSH, firewall, SELinux/AppArmor konteinerites)
**Eelmine peatükk:** 01-DevOps-Sissejuhatus.md
**Järgmine peatükk:** 03-Git-DevOps-Toovoos.md
```

### Kirjutamise Järjekord

1. **Teooria sektsioonid** (70%)
2. **Praktilised näited** (30% - 9 näidet, lisa SELinux/AppArmor)
3. **Troubleshooting** (9 probleemi, lisa SELinux troubleshooting)
4. **Viimistlemine**

---

## Peatükk 3: Git DevOps Töövoos

### Eesmärk

Õpetada Git'i põhitõed DevOps kontekstis, järgides **Conventional Commits** ja **Semantic Versioning** standardeid.

### Põhiteemad

(Muutmata - juba järgib parimaid praktikaid)

---

## Peatükk 4: Võrgutehnoloogia Alused DevOps'is

### Eesmärk

Õpetada võrgutehnoloogia põhitõed, järgides **TCP/IP**, **DNS (RFC 1034/1035)**, **CIDR (RFC 4632)** ja **OSI 7-layer model** standardeid.

### Põhiteemad (uuendatud koos OSI modeliga)

```markdown
- OSI 7-layer model (põgus sissejuhatus)
  - Layer 7 (Application): HTTP, DNS, SSH
  - Layer 4 (Transport): TCP, UDP
  - Layer 3 (Network): IP, routing
  - (DevOps kontekstis olulised layer'id)
- Võrgu põhimõisted
  - IP aadressid (IPv4, public vs private, CIDR notation - RFC 4632)
  - Portid ja protokollid (TCP, UDP)
  - DNS (domain name system, A/AAAA/CNAME records - RFC 1034/1035)
- Levinud portid DevOps'is
  - HTTP: 80, HTTPS: 443
  - SSH: 22
  - PostgreSQL: 5432, MySQL: 3306
  - Custom app ports: 3000, 8080, 8081
- Load balancing kontseptsioon
  - Round-robin, least connections
  - Health checks
- Reverse proxy
  - Nginx reverse proxy eelvaade
  - Ingress (Kubernetes context)
- Networking tools
  - ping, traceroute, nslookup/dig
  - netstat, ss, lsof
  - curl, wget
- Docker ja Kubernetes networking (põhimõtted)
```

### Struktuur (uuendatud koos OSI sektsiiooniga)

```markdown
# Peatükk 4: Võrgutehnoloogia Alused DevOps'is

## Õpieesmärgid (7 punkti)
- ✅ Mõista OSI 7-layer model'i (lihtsustatud DevOps kontekstis)
- ✅ Mõista IP aadresse ja CIDR notatsiooni (RFC 4632)
- ✅ Eristada public vs private IP aadresse (RFC 1918)
- ✅ Mõista porte ja protokolle (TCP, UDP)
- ✅ Kasutada DNS'i (A, AAAA, CNAME records - RFC 1034/1035)
- ✅ Mõista load balancing'ut ja reverse proxy't
- ✅ Kasutada networking tööriistu (ping, curl, netstat, dig)

## Põhimõisted (15-18 terminit)
- OSI mudel (OSI model)
- IP aadress (IP address)
- Alamvõrk (subnet)
- Port (port)
- Protokoll (protocol - TCP, UDP)
- DNS (Domain Name System)
- Koormusjaotur (load balancer)
- Pöördproxy (reverse proxy)
- HTTP/HTTPS
- NAT (Network Address Translation)

## Teooria (70% - 4-5 lk)

### 1. OSI 7-Layer Model (Lihtsustatud DevOps Kontekstis)
**OSI (Open Systems Interconnection) model** on võrgutehnoloogia teoreetiline raamistik (ISO/IEC 7498).

**DevOps'is olulised layer'id (algajale arusaadav):**
- **Layer 7 (Application):** HTTP, HTTPS, DNS, SSH, FTP
  - *Näide:* Curl teeb HTTP request'i (Layer 7)
- **Layer 4 (Transport):** TCP (reliable), UDP (fast)
  - *Näide:* PostgreSQL kasutab TCP port 5432
- **Layer 3 (Network):** IP aadressid, routing
  - *Näide:* Docker container'il on IP aadress

**Lihtsustatud mnemonic** (meeldejätmiseks):
```
Layer 7: Application - HTTP, DNS     (mida kasutajad näevad)
Layer 4: Transport   - TCP, UDP       (kuidas andmed liiguvad)
Layer 3: Network     - IP             (kuhu andmed lähevad)
```

**Praktiline näide:**
```bash
curl https://api.example.com:443/users
# Layer 7: HTTPS protocol
# Layer 4: TCP port 443
# Layer 3: IP aadress (DNS resolve'ib example.com → IP)
```

**(Märkus: Täielik OSI model on 7 layer'it, aga DevOps'is piisab Layer 3, 4, 7 mõistmisest)**

### 2. IP Aadressid ja Alamvõrgud (RFC 791, RFC 1918, RFC 4632)
- IPv4 vs IPv6
- Public vs private IP:
  - Private (RFC 1918): 192.168.x.x, 10.x.x.x, 172.16-31.x.x
  - Public: Kõik ülejäänud (Internet'is routitud)
- CIDR notatsioon (RFC 4632):
  - 192.168.1.0/24 = 256 IP'd
  - 10.0.0.0/16 = 65,536 IP'd
- NAT (Network Address Translation)

### 3. Portid ja Protokollid (Layer 4)
- Mis on port? (0-65535)
- **TCP vs UDP:**
  - TCP: Reliable, connection-oriented (3-way handshake)
  - UDP: Fast, connectionless (no guarantee)
- Well-known ports (0-1023):
  - HTTP: 80, HTTPS: 443
  - SSH: 22
  - PostgreSQL: 5432, MySQL: 3306
- Registered ports (1024-49151):
  - Custom app ports: 3000, 8080, 8081

### 4. DNS (Domain Name System - RFC 1034, RFC 1035)
- DNS hierarhia (root, TLD, domain, subdomain)
- DNS record tüübid:
  - A (IPv4)
  - AAAA (IPv6)
  - CNAME (alias)
  - MX (mail)
  - TXT (verification)
- DNS resolution protsess (recursive vs iterative)

### 5. Load Balancing
- Mis on load balancer?
- Load balancing algoritmid:
  - Round-robin
  - Least connections
  - IP hash
- Health checks
- Sticky sessions

### 6. Reverse Proxy
- Forward proxy vs reverse proxy
- Nginx kui reverse proxy
- Reverse proxy DevOps'is (API gateway, SSL termination, caching)
- Ingress Kubernetes'es (viide Peatükk 17 ja Lab 4)

### 7. Networking Tools
- Connectivity testing:
  - ping (ICMP - Layer 3)
  - traceroute/tracepath
- DNS lookup:
  - nslookup, dig, host
- HTTP testing:
  - curl, wget (Layer 7)
- Port checking:
  - telnet, nc (netcat) (Layer 4)
- Socket/connection listing:
  - netstat, ss, lsof

### 8. Docker ja Kubernetes Networking (Eelvaade)
- Docker bridge network
- Docker custom networks
- Service discovery (hostname = container name)
- Kubernetes networking model (Pod-to-Pod, Pod-to-Service)

## Praktilised Näited (30% - 2-3 lk)

### Näide 1: OSI Layer'id Praktikas
```bash
# Layer 7 (Application): HTTP request
curl -I https://example.com
# HTTP/1.1 200 OK

# Layer 4 (Transport): TCP port check
nc -zv example.com 443
# Connection to example.com 443 port [tcp/https] succeeded!

# Layer 3 (Network): IP routing
traceroute example.com
# 1  192.168.1.1 (router)
# 2  10.0.0.1 (ISP gateway)
# ...
```

### Näide 2: IP ja CIDR
```bash
# Oma IP aadressi kontroll
ip addr show
hostname -I

# CIDR näide
# 192.168.1.0/24 = 192.168.1.0 - 192.168.1.255 (256 IP'd)
# 10.0.0.0/16 = 10.0.0.0 - 10.0.255.255 (65,536 IP'd)
```

### Näide 3: DNS Lookup (RFC 1034/1035)
```bash
# A record (IPv4)
dig example.com A
nslookup example.com

# AAAA record (IPv6)
dig example.com AAAA

# CNAME (alias)
dig www.example.com CNAME

# MX record (mail)
dig example.com MX
```

### Näide 4: Port ja Connectivity Testing
```bash
# Ping (ICMP - Layer 3)
ping -c 4 google.com

# Traceroute
traceroute google.com

# Port testing (nc - netcat - Layer 4)
nc -zv example.com 80
nc -zv example.com 443

# HTTP request (curl - Layer 7)
curl -I https://example.com

# Download file (wget)
wget https://example.com/file.txt
```

### Näide 5: Socket Listing
```bash
# Listening ports (ss - modern)
sudo ss -tulpn

# Specific port (lsof)
sudo lsof -i :80
sudo lsof -i :5432  # PostgreSQL
```

### Näide 6: Docker Networking (eelvaade Lab 1-2)
```bash
# Docker võrgud
docker network ls

# Custom network loomine
docker network create myapp-network

# Konteinerite ühendamine võrku
docker run -d --name db --network myapp-network postgres
docker run -d --name app --network myapp-network myapp:latest

# Service discovery (hostname = container name)
# app konteiner saab ühenduda db konteineriga hostname'iga "db"
```

## Levinud Probleemid ja Lahendused

### Probleem 1: "Connection refused" (Layer 4)
**Sümptom:** `curl: (7) Failed to connect to localhost port 8080`
**Põhjus:** Port pole listening või firewall blokeerib
**Lahendus:**
```bash
sudo ss -tulpn | grep 8080  # Kontrolli kas port on listening
sudo ufw status             # Kontrolli firewall'i
```

### Probleem 2: DNS ei resolve'i (Layer 7)
**Sümptom:** `ping: example.com: Name or service not known`
**Põhjus:** DNS server pole kättesaadav või vale konfiguratsioon
**Lahendus:**
```bash
cat /etc/resolv.conf
dig @8.8.8.8 example.com  # Google DNS
```

### Probleem 3: "No route to host" (Layer 3)
**Sümptom:** `ping: connect: No route to host`
**Põhjus:** Firewall blokeerib ICMP või host pole kättesaadav
**Lahendus:**
```bash
ip route              # Kontrolli routing table
sudo ufw status       # Kontrolli firewall'i
```

### Probleem 4: Port juba kasutusel (Layer 4)
**Sümptom:** `Error: bind: address already in use`
**Põhjus:** Teine protsess kasutab sama porti
**Lahendus:**
```bash
sudo lsof -i :8080
kill -9 <PID>
```

### Probleem 5: Docker konteinerid ei saa ühendust
**Sümptom:** `curl: (7) Failed to connect to db:5432`
**Põhjus:** Konteinerid pole samas võrgus
**Lahendus:**
```bash
docker network inspect myapp-network
docker network connect myapp-network container-name
```

## Best Practices
- ✅ Mõista OSI layer'eid (3, 4, 7) troubleshooting'uks
- ✅ Kasuta private IP'sid sisevõrgus (RFC 1918)
- ✅ Kasuta standard porte (HTTP 80, HTTPS 443)
- ✅ Kasuta DNS'i (mitte IP aadresse)
- ✅ Kasuta HTTPS'i (mitte HTTP)
- ✅ Load balancer + health checks = high availability
- ✅ Reverse proxy = API gateway, SSL termination
- ❌ Ära avalda kõiki porte (ainult vajalikud)
- ❌ Ära kasuta public IP'sid konteinerites (kasuta private)

## Kokkuvõte
- OSI model (Layer 3, 4, 7) aitab troubleshooting'us
- IP, portid ja DNS on võrgutehnoloogia alused (RFC standardid)
- TCP vs UDP: TCP on reliable (Layer 4), UDP on fast
- DNS resolve'ib domainid IP aadressideks (RFC 1034/1035)
- Load balancer ja reverse proxy on DevOps infrastruktuuri komponendid
- Networking tools (ping, curl, dig, netstat) on diagnostika vahendid
- Docker ja Kubernetes networking on konteinerite suhtluse alus

## Viited ja Edasine Lugemine
- [OSI Model Explained](https://www.cloudflare.com/learning/ddos/glossary/open-systems-interconnection-model-osi/)
- [TCP/IP Illustrated](https://www.amazon.com/TCP-Illustrated-Vol-Addison-Wesley-Professional/dp/0201633469)
- [RFC 791 - Internet Protocol](https://datatracker.ietf.org/doc/html/rfc791)
- [RFC 1918 - Private IP Addresses](https://datatracker.ietf.org/doc/html/rfc1918)
- [RFC 4632 - CIDR Notation](https://datatracker.ietf.org/doc/html/rfc4632)
- [RFC 1034/1035 - DNS](https://datatracker.ietf.org/doc/html/rfc1034)
- [DNS Explained](https://www.cloudflare.com/learning/dns/what-is-dns/)
- [Load Balancing Explained](https://www.nginx.com/resources/glossary/load-balancing/)
- [Docker Networking](https://docs.docker.com/network/)
- [Kubernetes Networking](https://kubernetes.io/docs/concepts/services-networking/)

---

**Viimane uuendus:** 2025-12-09 (planeeritud)
**Seos laboritega:** KÕIK laborid (networking), eriti Lab 1-2 (Docker), Lab 3-4 (Kubernetes, Ingress)
**Eelmine peatükk:** 03-Git-DevOps-Toovoos.md
**Järgmine peatükk:** 05-Docker-Pohimotted.md (resource/ kataloogis)
```

### Kirjutamise Järjekord

1. **Teooria sektsioonid** (70% - lisa OSI model algusesse)
2. **Praktilised näited** (30% - lisa OSI layer'ite näide)
3. **Troubleshooting** (5 probleemi - märgi OSI layer)
4. **Viimistlemine**

---

## Kokkuvõte: FAAS 1 Täiendused

**Lisatud parimate praktikate ja standardite järgi:**

### Peatükk 1 (DevOps):
- ✅ **DevSecOps** (Security as Code, Shift-Left)
- ✅ **SRE** (Site Reliability Engineering - Google)
- ✅ **Observability** (Logs + Metrics + Traces)
- ✅ **DORA metrics** (deployment frequency, lead time, MTTR, change failure rate)
- ✅ **CALMS framework** (viidatud juba, aga nüüd detailsem)

### Peatükk 2 (Linux):
- ✅ **FHS** (Filesystem Hierarchy Standard)
- ✅ **LSM** (Linux Security Modules - SELinux, AppArmor)
- ✅ **MAC vs DAC** (Mandatory vs Discretionary Access Control)
- ✅ **SELinux/AppArmor** konteinerites (põgusalt, algajale arusaadav)

### Peatükk 3 (Git):
- ✅ Järgib juba **Conventional Commits** ja **Semantic Versioning** (muutmata)

### Peatükk 4 (Networking):
- ✅ **OSI 7-layer model** (lihtsustatud DevOps kontekstis, Layer 3, 4, 7)
- ✅ **RFC viited** (RFC 791, RFC 1918, RFC 4632, RFC 1034/1035)
- ✅ **Layer'ite märkimine** troubleshooting'us

---

**Kokku:** 28-36 lehekülge, ~14,000-18,000 sõna, ~9h

**Failide Asukohad:** Juurkataloog (/home/janek/projects/hostinger/)

**Järgmine samm:** Kirjuta Peatükk 2 (Linux Põhitõed)

---

**Viimane uuendus:** 2025-12-09
**Versioon:** 1.2 (Lisatud: SRE, Observability, DevSecOps, SELinux/AppArmor, OSI model)
**Autor:** Claude Code + Janek
**Staatus:** Planeerimine valmis ✅

**Edu FAAS 1 kirjutamisega! 🚀📚**
