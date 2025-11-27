# Sudo Ligipääs - DevOps Laborikeskkond

## Ülevaade

DevOps laborikeskkonnas on seadistatud **piiratud sudo ligipääs**, mis võimaldab õpilastel (`labuser`) teha troubleshooting'ut ilma täielikke root õiguseid andmata.

**Põhimõte:** Passwordless sudo ainult diagnostika käskudele, mis on read-only või kontrolitud häirimine.

---

## Lubatud Sudo Käsud

### 1. Võrgu Port Diagnostika

**lsof - List Open Files**

```bash
# Kontrolli konkreetset porti
sudo lsof -i :3000

# Näita kõiki listening porte
sudo lsof -i -P -n | grep LISTEN

# Filtre

eri Docker proxy bindingud
sudo lsof -i -P -n | grep LISTEN | grep docker-proxy
```

**Kasutuskoht:**
- Lab 1: Port konfliktide tuvastamine (harjutused 1a, 1b, 2, 4)
- Lab 2: Multi-container port checking (harjutused 1, 2, 3)
- Lab 2.5: Network segmentation audit (harjutus 3)

**Miks sudo?** `lsof` vajab root õiguseid võrgu sockettide inspekteerimiseks süsteemitasandil.

---

### 2. Port Scanning

**nmap - Network Mapper**

```bash
# TCP connect scan
sudo nmap -sT localhost -p 8080,3000,8081,5432,5433

# Service version detection
sudo nmap -sV localhost -p 8080,3000,8081

# Specific port scan
sudo nmap -sT localhost -p 22
```

**Kasutuskoht:**
- Lab 2.5: Security auditing (harjutus 4)
- Lab 2.5: Automated testing scripts

**Miks sudo?** `nmap` vajab õiguseid raw packet loomiseks ja portide skaneerimiseks.

---

### 3. Packet Capture

**tcpdump - Packet Analyzer**

```bash
# Capture on host interface
sudo tcpdump -i docker0 -n

# Limited packet capture
sudo tcpdump -i eth0 -c 10

# With filter
sudo tcpdump -i eth0 port 3000 -c 5
```

**Kasutuskoht:**
- Lab 2.5: Traffic analysis (harjutus 3)

**Miks sudo?** `tcpdump` vajab õiguseid network interface'ide ligipääsuks.

**Märkus:** Konteinerite SEES ei vaja sudo't:
```bash
# See töötab ILMA sudo'ta
docker compose exec frontend tcpdump -i eth0
```

---

### 4. Docker Daemon Haldamine

**systemctl - Service Management**

```bash
# Restart Docker daemon
sudo systemctl restart docker

# Check Docker status
sudo systemctl status docker
```

**Kasutuskoht:**
- Lab 2.5: DNS troubleshooting (harjutus 2, probleem 3)
- Harva vajalik, aga õppeotstarbeline

**Miks sudo?** `systemctl` vajab root õiguseid süsteemi teenuste haldamiseks.

---

### 5. Docker Internals Inspection (Read-Only)

**ls - List Docker Volumes**

```bash
# Volume storage locations (educational)
sudo ls -la /var/lib/docker/volumes/
sudo ls -la /var/lib/docker/volumes/postgres-user-data/_data/
```

**Kasutuskoht:**
- Lab 1: Understanding Docker volumes (harjutus 4, samm 8)

**Miks sudo?** `/var/lib/docker/` on root'ile kuuluv kataloog.

---

**du - Disk Usage**

```bash
# Log file size inspection
sudo du -h /var/lib/docker/containers/*/user-service*-json.log

# All container disk usage
sudo du -sh /var/lib/docker/containers/*/
```

**Kasutuskoht:**
- Lab 2: Production patterns, log optimization (harjutus 6)

**Miks sudo?** Docker konteinerite kataloogid on kaitstud.

---

## Sudoers Konfiguratsioon

### Fail: `/etc/sudoers.d/labuser-devops`

```bash
# DevOps Training Lab - Limited Sudo Access for labuser
# Created: 2025-11-27

# Disable requiretty for labuser (allows sudo in scripts)
Defaults:labuser !requiretty

# Allow passwordless sudo for specific commands only
labuser ALL=(ALL) NOPASSWD: /usr/bin/lsof
labuser ALL=(ALL) NOPASSWD: /usr/bin/nmap
labuser ALL=(ALL) NOPASSWD: /usr/sbin/tcpdump
labuser ALL=(ALL) NOPASSWD: /bin/systemctl restart docker
labuser ALL=(ALL) NOPASSWD: /bin/systemctl status docker
labuser ALL=(ALL) NOPASSWD: /bin/ls /var/lib/docker/volumes/
labuser ALL=(ALL) NOPASSWD: /bin/ls /var/lib/docker/volumes/*
labuser ALL=(ALL) NOPASSWD: /usr/bin/du /var/lib/docker/containers/*

# All other sudo commands require password (implicit deny)
```

**Õigused:** `0440` (read-only by root)
**Omanik:** `root:root`

---

## Turvalisuse Põhimõtted

### Defense in Depth

1. **LXD Unprivileged Containers**
   - User namespace remapping (container UID 0 → host UID 1000000)
   - Process isolation (PID, network, mount namespaces)

2. **Limited Sudoers**
   - Ainult spetsiifilised käsud
   - Täiesti määratud path'id (ei luba wildcards)

3. **Network Isolation**
   - lxdbr0 private bridge (10.67.86.0/24)
   - NAT kaitse välja

4. **Logging & Auditing**
   - Kõik sudo kasutused logitakse `/var/log/auth.log`
   - Admin saab jälgida kasutust

5. **Snapshot Capability**
   - LXD snapshot'id võimaldavad kiiret rollback'i

---

## Riskide Analüüs

| Käsk | Risk Tase | Mitigation | Educational Value |
|------|-----------|------------|-------------------|
| `lsof` | **MADAL** | Read-only info disclosure ainult | **KÕRGE** - Port troubleshooting |
| `nmap` | **MADAL-KESKMINE** | Localhost scan, container isolation | **KÕRGE** - Security audit skills |
| `tcpdump` | **KESKMINE** | Piiratud docker0 bridge'ile | **KESKMINE** - Traffic analysis |
| `systemctl restart docker` | **KESKMINE-KÕRGE** | Controlled disruption, educational | **KESKMINE** - Service management |
| `ls /var/lib/docker/volumes/` | **MADAL** | Read-only directory listing | **KESKMINE** - Storage understanding |
| `du /var/lib/docker/containers/` | **MADAL** | Read-only size calculation | **KESKMINE** - Log file growth |

### Võtmepõhimõte

**Kõik lubatud käsud on kas:**
- ✅ **Read-only** - Ei muuda süsteemi (lsof, ls, du)
- ✅ **Kontrollitud häirimine** - Docker restart (õppeotstarbeline)
- ❌ **Ei võimalda:**
  - Failide muutmist
  - Koodi käivitamist
  - Pakettide paigaldamist (ilma paroolita)
  - Kasutajate loomist
  - Süsteemi konfiguratsiooni muutmist

---

## Eelpaigaldatud Tööriistad

Kõik diagnostika tööriistad on template image'is eelnevalt paigaldatud:

```bash
# Võrgu diagnostika
jq                  # JSON query tool
nmap                # Port scanner
tcpdump             # Packet analyzer
netcat-openbsd      # TCP/UDP testing (nc)
dnsutils            # DNS tools (dig, nslookup)
net-tools           # Network tools (netstat, ifconfig)
iproute2            # Modern network tools (ip, ss)
```

**Kontroll:**
```bash
which jq nmap tcpdump nc dig netstat lsof
```

---

## Testimine

### Test Suite (Admin)

```bash
# Test 1: lsof works without password
sg lxd -c "lxc exec devops-student1 -- su - labuser -c 'sudo lsof -i :22'" && echo "✅ lsof works"

# Test 2: nmap works without password
sg lxd -c "lxc exec devops-student1 -- su - labuser -c 'sudo nmap -sT localhost -p 22'" && echo "✅ nmap works"

# Test 3: tcpdump works without password (5 packet limit)
sg lxd -c "lxc exec devops-student1 -- su - labuser -c 'timeout 5 sudo tcpdump -i eth0 -c 5'" && echo "✅ tcpdump works"

# Test 4: systemctl status works without password
sg lxd -c "lxc exec devops-student1 -- su - labuser -c 'sudo systemctl status docker'" && echo "✅ systemctl works"

# Test 5: apt-get REQUIRES password (security check)
sg lxd -c "lxc exec devops-student1 -- su - labuser -c 'timeout 2 sudo apt-get update 2>&1 | grep -q password'" && echo "✅ apt-get requires password (good!)"
```

### Test Suite (Õpilane)

```bash
# Õpilane saab testida sudo käske
sudo lsof -i :22                    # ✅ Peaks töötama
sudo nmap -sT localhost -p 22       # ✅ Peaks töötama
timeout 5 sudo tcpdump -i eth0 -c 5 # ✅ Peaks töötama
sudo apt-get update                 # ❌ Peaks küsima parooli
```

---

## Logging ja Monitooring

### Sudo Kasutuse Jälgimine

**Admin saab jälgida kõiki sudo kasutusi:**

```bash
# Kõik sudo kasutused konteineris
sg lxd -c "lxc exec devops-student1 -- grep sudo /var/log/auth.log | tail -20"

# Ainult labuser'i sudo kasutused
sg lxd -c "lxc exec devops-student1 -- grep 'labuser.*sudo' /var/log/auth.log | tail -20"

# Real-time monitoring
sg lxd -c "lxc exec devops-student1 -- tail -f /var/log/auth.log | grep sudo"
```

**Log Entry näide:**
```
Nov 27 10:15:23 devops-student1 sudo:  labuser : TTY=pts/0 ; PWD=/home/labuser ; USER=root ; COMMAND=/usr/bin/lsof -i :3000
```

---

## Compliance

### Principle of Least Privilege ✅

- Ainult vajalikud käsud
- Täpselt määratud path'id
- Ei wildcards executable'ite jaoks

### Separation of Duties ✅

- labuser ei saa muuta sudoers faili
- labuser ei saa paigaldada pakette ilma paroolita
- labuser ei saa luua kasutajaid

### Logging & Auditing ✅

- Kõik sudo kasutused logitakse
- Admin saab auditeerida tegevust
- Logs säilivad konteineri elutsükli vältel

### Educational Realism ✅

- Peegeldab production DevOps keskkonda
- Õpetab least privilege põhimõtteid
- Hands-on turvalisuse parimal  praktikal

---

## Troubleshooting

### Probleem 1: "sudo: no tty present and no askpass program specified"

**Sümptom:**
```bash
sudo lsof -i :3000
# sudo: no tty present and no askpass program specified
```

**Põhjus:** `Defaults:labuser !requiretty` puudub sudoers failis

**Lahendus:**
```bash
# Admin tegevus
sg lxd -c "lxc exec devops-student1 -- bash -c '
echo \"Defaults:labuser !requiretty\" >> /etc/sudoers.d/labuser-devops
visudo -c -f /etc/sudoers.d/labuser-devops
'"
```

---

### Probleem 2: "sudo: /etc/sudoers.d/labuser-devops is world writable"

**Sümptom:**
```bash
sudo lsof -i :3000
# sudo: /etc/sudoers.d/labuser-devops is world writable
```

**Põhjus:** Vale failide õigused (peaks olema 0440)

**Lahendus:**
```bash
# Admin tegevus
sg lxd -c "lxc exec devops-student1 -- chmod 0440 /etc/sudoers.d/labuser-devops"
sg lxd -c "lxc exec devops-student1 -- chown root:root /etc/sudoers.d/labuser-devops"
```

---

### Probleem 3: Sudo küsib parooli käskude jaoks, mis peaks olema passwordless

**Sümptom:**
```bash
sudo lsof -i :3000
# [sudo] password for labuser:
```

**Põhjus:** Sudoers fail puudub või vale path

**Lahendus:**
```bash
# Admin tegevus - kontrolli sudoers faili
sg lxd -c "lxc exec devops-student1 -- cat /etc/sudoers.d/labuser-devops"

# Kui puudub, loo uuesti (vt ADMIN-GUIDE.md)
```

---

### Probleem 4: "command not found" sudo käsu jaoks

**Sümptom:**
```bash
sudo nmap -sT localhost -p 22
# sudo: nmap: command not found
```

**Põhjus:** nmap ei ole paigaldatud

**Lahendus:**
```bash
# Admin tegevus - paigalda puuduv tööriist
sg lxd -c "lxc exec devops-student1 -- apt-get update"
sg lxd -c "lxc exec devops-student1 -- apt-get install -y nmap"
```

---

## Best Practices

### Admin'ile

✅ **DO:**
- Valideeri ALATI sudoers faili `visudo -c` käsuga enne rakendamist
- Testi sudo käske labuser'ina enne template publitseerimist
- Jälgi sudo kasutuse loge regulaarselt
- Hoia sudoers fail 0440 õigustega
- Kasuta täpselt määratud path'e (mitte wildcards)

❌ **DON'T:**
- Ära anna labuser'ile täielikku sudo ligipääsu (`labuser ALL=(ALL) NOPASSWD: ALL`)
- Ära kasuta wildcards sudoers failis (`NOPASSWD: /usr/bin/*`)
- Ära unusta visudo validatsiooni
- Ära muuda sudoers faili õiguseid (peab olema 0440)

### Õpilasele

✅ **DO:**
- Kasuta sudo ainult troubleshooting'uks
- Loe diagnostika käskude väljundeid hoolikalt
- Küsi abi, kui sudo käsk ei tööta

❌ **DON'T:**
- Ära proovi sudo't kasutada pakettide paigaldamiseks (küsib parooli)
- Ära proovi muuta süsteemi faile (ei õnnestu)
- Ära jaga oma parooli (kui sudo küsib)

---

## Educational Value

### Mida Õpilased Õpivad

1. **Sudo Põhimõtted**
   - Least privilege principle
   - Passwordless vs password sudo
   - Sudoers file structure

2. **Võrgu Diagnostika**
   - Port troubleshooting (lsof)
   - Security scanning (nmap)
   - Traffic analysis (tcpdump)

3. **Süsteemi Haldamine**
   - Service management (systemctl)
   - Log file management (du)
   - Storage inspection (ls volumes)

4. **Turvalisus**
   - Miks sudo on vajalik
   - Kuidas piirata sudo ligipääsu
   - Defense in depth

5. **Production Realism**
   - Hands-on DevOps administraatori töövoog
   - Tõelised troubleshooting stsenaariumid
   - Industry-standard patterns

---

## Viited

**Documentation:**
- [Ubuntu sudoers manual](https://manpages.ubuntu.com/manpages/noble/man5/sudoers.5.html)
- [lsof manual](https://manpages.ubuntu.com/manpages/noble/man8/lsof.8.html)
- [nmap manual](https://nmap.org/book/man.html)
- [tcpdump manual](https://www.tcpdump.org/manpages/tcpdump.1.html)

**LXD Security:**
- [LXD Security Documentation](https://documentation.ubuntu.com/lxd/en/latest/security/)
- [Unprivileged Containers](https://documentation.ubuntu.com/lxd/en/latest/userns-idmap/)

**Best Practices:**
- [Principle of Least Privilege (OWASP)](https://owasp.org/www-community/Access_Control)
- [Linux Security Best Practices](https://linux-audit.com/linux-security-guide/)

---

**Viimane uuendus:** 2025-11-27
**Versioon:** 1.0
**Staatus:** Aktiivne laborikeskkondades devops-student1, devops-student2, devops-student3
