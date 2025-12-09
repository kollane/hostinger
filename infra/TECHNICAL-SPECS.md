# Tehnilised Spetsifikatsioonid - LXD DevOps Laborikeskkond

## Süsteemi Ülevaade

**Deployment kuupäev:** 2025-11-25
**Versioon:** 1.0
**Platform:** LXD konteinerid Ubuntu 24.04 VPS-il

---

## Host Süsteem

### Riistvara ja OS

#### Docker Laboritele (Lab 1-2)

```yaml
Operating System: Ubuntu 24.04 LTS
Kernel: Linux 6.8.0-87-generic
Architecture: x86_64
CPU: 2 cores (AMD with SVM virtualization)
RAM: 7.8GB physical
Swap: 4GB (file-based, /swapfile)
Disk: 96GB total
Network: 1 external IPv4 address
```

#### Kubernetes Laboritele (Lab 3-10)

```yaml
Operating System: Ubuntu 24.04 LTS
Kernel: Linux 6.8.0-87-generic
Architecture: x86_64
CPU: 6+ cores (AMD with SVM virtualization)
RAM: 24GB physical (soovitatav)
Swap: 8GB (file-based, /swapfile)
Disk: 120GB+ total (SSD soovitatav)
Network: 1 external IPv4 address
```

### CPU Võimekused

```bash
# Virtualization support
AMD-V (SVM): ✓ Enabled
Nested virtualization: ✓ Enabled

# CPU flags (relevant)
svm, vmx, lm, pae, sse4_2, avx, avx2
```

### Memory Configuration

```yaml
Total RAM: 7.8GB (8047896 KB)
Swap: 4GB (4194304 KB)
Swap file: /swapfile
Swappiness: 60 (default)

Memory allocation:
  - Host system: ~800MB
  - LXD daemon: ~100MB
  - 3 containers: ~750MB idle, ~4-6GB under load
  - Available for spikes: 5.9GB + 4GB swap
```

### Filesystem

```yaml
Root filesystem: ext4
Mount point: /
Total: 96GB
Used: ~20GB (OS + LXD images + containers)
Available: ~76GB

LXD storage:
  Pool: default
  Driver: dir (directory-backed)
  Location: /var/snap/lxd/common/lxd/storage-pools/default
```

---

## LXD Konfiguratsioon

### LXD Version

```bash
LXD version: Latest from snap (Ubuntu 24.04)
Installation method: snap
Snap channel: latest/stable

# Check version
snap info lxd
```

### LXD Network (lxdbr0)

```yaml
Bridge name: lxdbr0
Type: bridge
IPv4 address: 10.67.86.1/24
IPv4 DHCP: enabled
IPv4 DHCP range: 10.67.86.2 - 10.67.86.254
IPv4 NAT: enabled
IPv6: disabled

MTU: 1500
State: UP
```

**Network configuration:**
```bash
# View bridge config
ip addr show lxdbr0
# Output:
# 4: lxdbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
#     inet 10.67.86.1/24 brd 10.67.86.255 scope global lxdbr0
```

**NAT Rules (iptables):**
```bash
# NAT for container outbound traffic
iptables -t nat -A POSTROUTING -s 10.67.86.0/24 -j MASQUERADE

# Port forwarding rules (LXD manages these automatically via proxy devices)
```

### LXD Storage Pool

```yaml
Name: default
Driver: dir
Source: /var/snap/lxd/common/lxd/storage-pools/default
Size: No fixed size (uses host filesystem)
Used by: 4 instances (3 containers + 1 template image)

Features:
  - Thin provisioning: No (dir driver)
  - Snapshots: Supported
  - Live migration: Not supported (dir driver)
```

### LXD Profiles

**Profile: default**
```yaml
name: default
config: {}
devices:
  eth0:
    name: eth0
    network: lxdbr0
    type: nic
  root:
    path: /
    pool: default
    type: disk
```

**Profile: devops-lab** (Docker laboritele)
```yaml
name: devops-lab
config:
  limits.cpu: "1"
  limits.memory: 2560MiB
  limits.memory.enforce: soft
  security.nesting: "true"
  security.privileged: "false"
  security.syscalls.intercept.mknod: "true"
  security.syscalls.intercept.setxattr: "true"
description: DevOps Lab Profile - 2.5GB RAM, 1 CPU, Docker support
devices:
  root:
    path: /
    pool: default
    type: disk
used_by:
  - devops-student1
  - devops-student2
  - devops-student3
```

**Security settings explained (Docker profile):**
- `security.nesting: true` - Allows running containers inside containers (needed for Docker)
- `security.privileged: false` - Container runs as unprivileged (more secure)
- `security.syscalls.intercept.mknod: true` - Allows device creation in container
- `security.syscalls.intercept.setxattr: true` - Allows extended attributes (needed for Docker overlay2)

**Profile: devops-lab-k8s** (Kubernetes laboritele)
```yaml
name: devops-lab-k8s
config:
  limits.cpu: "2"
  limits.memory: 5120MiB
  limits.memory.enforce: soft
  security.nesting: "true"
  security.privileged: "false"
  security.syscalls.intercept.mknod: "true"
  security.syscalls.intercept.setxattr: "true"
  linux.kernel_modules: ip_tables,ip6_tables,nf_nat,overlay,br_netfilter
  raw.lxc: |
    lxc.apparmor.profile=unconfined
    lxc.cap.drop=
    lxc.cgroup.devices.allow=a
    lxc.mount.auto=proc:rw sys:rw cgroup:rw
description: DevOps Lab K8s Profile - 5GB RAM, 2 CPU, Kubernetes support
devices:
  root:
    path: /
    pool: default
    type: disk
  kmsg:
    path: /dev/kmsg
    source: /dev/kmsg
    type: unix-char
used_by:
  - devops-k8s-student1
  - devops-k8s-student2
  - devops-k8s-student3
```

**Security settings explained (Kubernetes profile):**
- `limits.cpu: 2` - 2 CPU cores for Kubernetes components
- `limits.memory: 5120MiB` - 5GB RAM for kubelet, kube-proxy, and pods
- `linux.kernel_modules` - Required Kubernetes network modules (iptables, overlay, br_netfilter)
- `raw.lxc: lxc.apparmor.profile=unconfined` - Less restrictive AppArmor (K8s requires more access)
- `raw.lxc: lxc.cap.drop=` - Empty (keeps all capabilities for K8s)
- `raw.lxc: lxc.mount.auto=proc:rw sys:rw cgroup:rw` - K8s needs write access to /proc and /sys
- `kmsg device` - Kubernetes needs access to kernel messages for logging

**Turvalisuse kompromiss:** Kubernetes profil on vähem piiratud kui Docker profil, kuna Kubernetes vajab rohkem süsteemitaseme juurdepääsu. Siiski on see turvalisem kui täielikult privileged konteiner.

---

## Template Image

### devops-lab-base Image

```yaml
Alias: devops-lab-base
Fingerprint: b36d81cae5b6eab9f3948ffe6706887c017d892cfad15b05a9de0ae7dccd0ad1
Architecture: x86_64
Type: container
Size: 494.69MB (compressed)
Created: 2025-11-25 18:20 UTC
Description: DevOps Lab Template: Ubuntu 24.04 + Docker + Labs

Base:
  Distribution: ubuntu
  Release: 24.04 (Noble Numbat)
  Architecture: amd64
  Variant: default

Properties:
  os: ubuntu
  release: noble
  architecture: amd64
  description: Ubuntu 24.04 LTS amd64 (release) (20251123)
```

### Installed Software

**System packages:**
```yaml
Core utilities:
  - curl: 8.5.0
  - wget: 1.21.4
  - git: 2.43.0
  - vim: 9.0
  - nano: 7.2
  - jq: 1.7
  - netstat: 2.10
  - htop: 3.3.0
  - ca-certificates
  - gnupg
  - lsb-release

Network diagnostics:
  - nmap: 7.94 (port scanner)
  - tcpdump: 4.99.4 (packet analyzer)
  - netcat-openbsd: 1.219 (TCP/UDP testing)
  - dnsutils: bind9-tools (dig, nslookup)
  - net-tools: (netstat, ifconfig, route)
  - iproute2: (ip, ss - modern network tools)

Development tools:
  - build-essential (gcc, g++, make)
  - python3: 3.12.3
  - python3-pip: 24.0

Java (for backend-java-spring):
  - openjdk-21-jdk: 21.0.x

Node.js (for backend-nodejs):
  - nodejs: 20.x LTS (via NodeSource)
  - npm: 10.x

Docker:
  - docker-ce: 29.0.4
  - docker-ce-cli: 29.0.4
  - containerd.io: 1.7.28-1 (LOCKED - see Known Issues)
  - docker-buildx-plugin: latest
  - docker-compose-plugin: 2.40.3

SSH:
  - openssh-server: 1:9.6p1-3ubuntu13.14
  - openssh-client: 1:9.6p1-3ubuntu13.14
```

**Docker configuration:**
```yaml
Docker daemon:
  Storage driver: overlay2
  Logging driver: json-file
  Cgroup driver: systemd
  Cgroup version: v2

Docker Compose:
  Version: v2.40.3
  Type: Plugin (docker compose)

Docker service:
  Status: enabled
  Started: automatic on boot
```

**Known Issues and Workarounds:**

⚠️ **CRITICAL: containerd.io 2.1.x sysctl bug**

**Problem:**
- containerd.io versions 1.7.29+ and 2.x have a bug with LXD unprivileged containers
- Symptoms: `Error: unable to start container process: open sysctl net.ipv4.ip_unprivileged_port_start file: permission denied`
- Affects: ALL Docker containers (PostgreSQL, nginx, etc.)
- Ubuntu 24.04 + LXD + Docker combination triggers this AppArmor/sysctl conflict
- Bug reports: [LP#2131008](https://bugs.launchpad.net/ubuntu/+source/apparmor/+bug/2131008)

**Solution applied (2025-11-26):**
```bash
# In each LXD container, downgrade containerd:
apt install -y --allow-downgrades containerd.io=1.7.28-1~ubuntu.24.04~noble
apt-mark hold containerd.io

# Verify version:
containerd --version
# Output: containerd containerd.io 1.7.28 ...

# Restart Docker:
systemctl restart docker
```

**Verification:**
```bash
# Test if containers work:
docker run --rm alpine:3.16 echo "OK"
# Should print "OK" without sysctl errors

# Test PostgreSQL 16-alpine:
docker run --rm -e POSTGRES_PASSWORD=test postgres:16-alpine postgres --version
# Should print version without errors
```

**Important:**
- Version is LOCKED with `apt-mark hold containerd.io`
- Do NOT run `apt upgrade` without checking containerd version first
- When rebuilding template image, apply this fix BEFORE publishing
- Monitor upstream bug for resolution (expected fix in containerd 2.2+)

### File Structure

```
/home/labuser/
├── .bashrc                    # Bash configuration with aliases
├── .profile                   # Shell profile
├── README.md                  # User welcome guide (1.2KB)
└── labs/                      # Lab exercises
    ├── 01-docker-lab/         # 6 exercises
    ├── 02-docker-compose-lab/ # 6 exercises
    ├── 03-kubernetes-basics-lab/ # 6 exercises
    ├── 04-kubernetes-advanced-lab/ # 5 exercises
    ├── 05-cicd-lab/           # 5 exercises
    ├── 06-monitoring-logging-lab/ # 5 exercises
    ├── 07-security-secrets-lab/   # 5 exercises
    ├── 08-gitops-argocd-lab/      # 5 exercises
    ├── 09-backup-disaster-recovery-lab/ # 5 exercises
    ├── 10-terraform-iac-lab/      # 5 exercises
    ├── apps/                      # 3 microservices
    │   ├── backend-nodejs/        # User Service
    │   ├── backend-java-spring/   # Todo Service
    │   ├── frontend/              # Web UI
    │   ├── learning-materials/
    │   └── docker-compose.yml     # Full stack setup
    ├── README.md                  # Labs overview
    └── CLAUDE.md                  # AI assistant guide

Total size: ~2.1GB (includes apps source code)
```

### User Configuration

```yaml
Username: labuser
UID: 1000
GID: 1000
Home: /home/labuser
Shell: /bin/bash
Groups:
  - labuser (primary)
  - docker
Password: Set per container (student1, student2, student3)
Sudo access: Limited (passwordless for diagnostic commands only)
  - lsof (port checking)
  - nmap (port scanning)
  - tcpdump (packet capture)
  - systemctl restart/status docker
  - ls /var/lib/docker/volumes/* (read-only)
  - du /var/lib/docker/containers/* (read-only)
Sudoers file: /etc/sudoers.d/labuser-devops (mode 0440)
```

**Bash configuration (in .bashrc):**
```bash
# Java environment
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Aliases
alias docker-stop-all="docker stop \$(docker ps -aq) 2>/dev/null || echo No containers running"
alias check-resources="echo === RAM === && free -h && echo && echo === DISK === && df -h / && echo && echo === DOCKER === && docker ps -a && docker images"

# Laborite täielik reset skript
alias labs-reset="~/labs/labs-reset.sh"

# Lab setup aliased
alias lab1-setup="cd ~/labs/01-docker-lab && ./setup.sh"
alias lab2-setup="cd ~/labs/02-docker-compose-lab && ./setup.sh"
```

**labs-reset skript** (`~/labs/labs-reset.sh`):
- **Asukoht:** `/home/labuser/labs/labs-reset.sh` (executable bash skript)
- **Käivitamine:** Otse käsurealt: `labs-reset` (alias .bashrc'is)
- Peatab ja kustutab **KÕIK Docker konteinerid**
- **Küsib kasutajalt**: Kas kustutada kõik image'd või säilitada Lab 1 base image'd (user-service:1.0, todo-service:1.0)
- Kustutab **KÕIK Docker network'id** (välja arvatud defaults: bridge, host, none)
- Kustutab **KÕIK Docker volume'd**
- Koristab apps/ kaust(ad)est Lab 1 failid (Dockerfile, Dockerfile.optimized, .dockerignore, healthcheck.js)
- **Asendab:** Kõik Lab 1-10 reset.sh skriptid ja nuclear-cleanup käsu
- **HOIATUS:** Kustutab ka teiste projektide Docker ressursid!

---

## Container Instances

### Container Configuration

**Common settings (all 3 containers):**
```yaml
Base image: devops-lab-base
Architecture: x86_64
Type: container
Profiles:
  - default
  - devops-lab

Resources:
  limits.cpu: "1"
  limits.memory: 2560MiB
  limits.memory.enforce: soft

Security:
  security.nesting: "true"
  security.privileged: "false"
  security.idmap.isolated: false
  security.idmap.base: 1000000
  security.idmap.size: 1000000

Network:
  eth0:
    type: nic
    network: lxdbr0
    hwaddr: auto-generated
    ipv4.address: dhcp
    ipv6.address: none

Storage:
  root:
    type: disk
    path: /
    pool: default
    size: ~20GB (thin provisioned)
```

### devops-student1

```yaml
Name: devops-student1
Status: RUNNING
IPv4: 10.67.86.225
IPv6: fd42:1624:5e7b:cd2f:216:3eff:fe96:c3d4
MAC: 00:16:3e:96:c3:d4

Processes: 44
CPU usage: 18 seconds total
Memory usage: 262.92MiB (10.3% of 2.5GB limit)

Proxy devices (port forwarding):
  ssh-proxy:
    type: proxy
    listen: tcp:0.0.0.0:2201
    connect: tcp:127.0.0.1:22
    nat: true

  web-proxy:
    type: proxy
    listen: tcp:0.0.0.0:8080
    connect: tcp:127.0.0.1:8080
    nat: true

  user-api-proxy:
    type: proxy
    listen: tcp:0.0.0.0:3000
    connect: tcp:127.0.0.1:3000
    nat: true

  todo-api-proxy:
    type: proxy
    listen: tcp:0.0.0.0:8081
    connect: tcp:127.0.0.1:8081
    nat: true

User credentials:
  Username: labuser
  Password: student1
```

### devops-student2

```yaml
Name: devops-student2
Status: RUNNING
IPv4: 10.67.86.115
IPv6: fd42:1624:5e7b:cd2f:216:3eff:fe53:edd4
MAC: 00:16:3e:53:ed:d4

Processes: ~44
Memory usage: ~400MiB (15.8% of 2.5GB limit)

Proxy devices (port forwarding):
  ssh-proxy: 2202 → 22
  web-proxy: 8180 → 8080
  user-api-proxy: 3100 → 3000
  todo-api-proxy: 8181 → 8081

User credentials:
  Username: labuser
  Password: student2
```

### devops-student3

```yaml
Name: devops-student3
Status: RUNNING
IPv4: 10.67.86.175
IPv6: fd42:1624:5e7b:cd2f:216:3eff:fe8e:709d
MAC: 00:16:3e:8e:70:9d

Processes: ~44
Memory usage: ~340MiB (13.3% of 2.5GB limit)

Proxy devices (port forwarding):
  ssh-proxy: 2203 → 22
  web-proxy: 8280 → 8080
  user-api-proxy: 3200 → 3000
  todo-api-proxy: 8281 → 8081

User credentials:
  Username: labuser
  Password: student3
```

### devops-k8s-student1 (Kubernetes konteiner)

```yaml
Name: devops-k8s-student1
Status: RUNNING
IPv4: 10.67.86.XXX
Profile: devops-lab-k8s

Processes: ~80 (Kubernetes komponendid töötavad)
CPU usage: 2 cores allocated
Memory usage: ~1.5GB idle, ~3-4GB under load (max 5GB)

Proxy devices (port forwarding):
  ssh-proxy:
    type: proxy
    listen: tcp:0.0.0.0:2211
    connect: tcp:127.0.0.1:22
    nat: true

  k8s-api-proxy:
    type: proxy
    listen: tcp:0.0.0.0:6443
    connect: tcp:127.0.0.1:6443
    nat: true

  ingress-http-proxy:
    type: proxy
    listen: tcp:0.0.0.0:30080
    connect: tcp:127.0.0.1:30080
    nat: true

  ingress-https-proxy:
    type: proxy
    listen: tcp:0.0.0.0:30443
    connect: tcp:127.0.0.1:30443
    nat: true

User credentials:
  Username: labuser
  Password: student1
```

### devops-k8s-student2 (Kubernetes konteiner)

```yaml
Name: devops-k8s-student2
Status: RUNNING
IPv4: 10.67.86.XXX
Profile: devops-lab-k8s

Processes: ~80
Memory usage: ~1.5GB idle, ~3-4GB under load (max 5GB)

Proxy devices (port forwarding):
  ssh-proxy: 2212 → 22
  k8s-api-proxy: 6444 → 6443
  ingress-http-proxy: 30180 → 30080
  ingress-https-proxy: 30543 → 30443

User credentials:
  Username: labuser
  Password: student2
```

### devops-k8s-student3 (Kubernetes konteiner)

```yaml
Name: devops-k8s-student3
Status: RUNNING
IPv4: 10.67.86.XXX
Profile: devops-lab-k8s

Processes: ~80
Memory usage: ~1.5GB idle, ~3-4GB under load (max 5GB)

Proxy devices (port forwarding):
  ssh-proxy: 2213 → 22
  k8s-api-proxy: 6445 → 6443
  ingress-http-proxy: 30280 → 30080
  ingress-https-proxy: 30643 → 30443

User credentials:
  Username: labuser
  Password: student3
```

---

## Network Architecture

### Port Mapping Table (Docker Mode)

| Service | Internal Port | Student 1 | Student 2 | Student 3 |
|---------|--------------|-----------|-----------|-----------|
| SSH | 22 | 2201 | 2202 | 2203 |
| Frontend | 8080 | 8080 | 8180 | 8280 |
| User Service API | 3000 | 3000 | 3100 | 3200 |
| Todo Service API | 8081 | 8081 | 8181 | 8281 |

### Port Mapping Table (Kubernetes Mode)

| Service | Internal Port | Student 1 | Student 2 | Student 3 |
|---------|--------------|-----------|-----------|-----------|
| SSH | 22 | 2211 | 2212 | 2213 |
| K8s API Server | 6443 | 6443 | 6444 | 6445 |
| Ingress HTTP | 30080 | 30080 | 30180 | 30280 |
| Ingress HTTPS | 30443 | 30443 | 30543 | 30643 |

**Märkus:** Kubernetes režiimis kasutatakse NodePort vahemikku 30000-32767 teenuste avaldamiseks.

### Network Flow

```
External Client
      ↓
   <vps-ip>:2201
      ↓
Host iptables/LXD proxy
      ↓
lxdbr0 (10.67.86.1)
      ↓
devops-student1 (10.67.86.225:22)
      ↓
SSH Server (OpenSSH)
```

**Outbound traffic:**
```
Container (10.67.86.225)
      ↓
lxdbr0 (10.67.86.1)
      ↓
Host iptables NAT (MASQUERADE)
      ↓
External IP (<vps-ip>)
      ↓
Internet
```

### Firewall Configuration (UFW)

```yaml
Status: active
Default policies:
  incoming: deny
  outgoing: allow
  routed: allow (modified for LXD)

Rules:
  # LXD bridge traffic (CRITICAL)
  - to: any
    on: lxdbr0
    action: allow
    direction: in

  - to: any
    on: lxdbr0
    action: allow
    direction: out

  - to: any
    on: lxdbr0
    action: allow
    direction: route

  # External SSH (if configured)
  - to: 22/tcp
    from: any
    action: allow

  # Student ports (if specifically allowed)
  - to: 2201-2203/tcp
    from: any
    action: allow
    comment: SSH for students

  # Web ports (if specifically allowed)
  - to: 8080-8281/tcp
    from: any
    action: allow
    comment: Web services for students
```

**Critical UFW commands (for reference):**
```bash
# These were run to enable LXD networking
sudo ufw allow in on lxdbr0
sudo ufw route allow in on lxdbr0
sudo ufw route allow out on lxdbr0
sudo ufw default allow routed
```

---

## Resource Limits and Quotas

### Memory Limits (Docker Mode)

```yaml
Per container:
  Hard limit: 2560MiB (2.5GB)
  Enforcement: soft
  OOM killer: enabled if hard limit exceeded
  Swap: shared host swap (4GB)

Total theoretical (3 containers):
  3 containers × 2.5GB = 7.5GB
  Host available: 7.8GB + 4GB swap = 11.8GB
  Safety margin: 4.3GB
```

**Memory enforcement:**
- Soft limit: Container can exceed if host has free memory
- Hard limit: Container is OOM-killed if exceeds hard limit
- Cgroup v2 memory controller used

### Memory Limits (Kubernetes Mode)

```yaml
Per container:
  Hard limit: 5120MiB (5GB)
  Enforcement: soft
  OOM killer: enabled if hard limit exceeded
  Swap: shared host swap (8GB recommended)

Total theoretical (3 containers):
  3 containers × 5GB = 15GB
  Host required: 15GB + 2GB host = 17GB minimum
  Host recommended: 24GB + 8GB swap = 32GB

Memory breakdown per Kubernetes container:
  - Kubernetes components (kubelet, kube-proxy): ~500MB
  - Docker daemon: ~200MB
  - Control plane (single-node): ~1-1.5GB
  - Workload pods (apps, monitoring): ~2-3GB
  - OS + cache: ~500MB
  TOTAL: ~4.5-6GB under load
```

**Kubernetes memory requirements:**
- Higher memory needed for Kubernetes system components
- Additional memory for monitoring (Prometheus, Grafana)
- Swap recommended to handle temporary spikes

### CPU Limits (Docker Mode)

```yaml
Per container:
  CPU quota: 1 core
  CPU shares: 1024 (default)
  Scheduler: CFS (Completely Fair Scheduler)

Total (3 containers):
  3 containers × 1 core = 3 cores requested
  Host available: 2 cores
  Result: Time-sliced (each gets fair share)
```

**CPU enforcement:**
- Uses cgroup v2 CPU controller
- Fair scheduling across all containers
- Burst allowed if other containers idle

### CPU Limits (Kubernetes Mode)

```yaml
Per container:
  CPU quota: 2 cores
  CPU shares: 2048
  Scheduler: CFS (Completely Fair Scheduler)

Total (3 containers):
  3 containers × 2 cores = 6 cores requested
  Host minimum: 4 cores (heavily time-sliced)
  Host recommended: 6-8 cores
  Result: Fair scheduling with potential CPU pressure
```

**Kubernetes CPU requirements:**
- 2 cores needed for Kubernetes components + workloads
- kubelet and kube-proxy consume ~0.5-1 core combined
- Remaining cores for application pods
- More cores recommended for monitoring workloads

### Disk Quotas

```yaml
Per container:
  Quota: None (dir storage driver doesn't support quotas)
  Actual usage: ~3-5GB per container (with Docker images)
  Monitoring: Manual via 'df -h' in container

Best practice:
  Monitor disk usage regularly
  Use 'docker system prune' to clean up
  Set up alerting for disk usage > 80%
```

---

## Security Configuration

### Container Isolation

```yaml
Namespace isolation:
  PID: Separate PID namespace per container
  Network: Separate network namespace per container
  Mount: Separate mount namespace per container
  IPC: Separate IPC namespace per container
  UTS: Separate hostname per container
  User: UID/GID mapping (unprivileged)

User namespace mapping:
  Container UID 0 → Host UID 1000000
  Container UID 1000 → Host UID 1001000
  Range: 1000000 - 1999999

AppArmor:
  Profile: lxc-container-default-cgns (with nesting)
  Status: enforcing
  Nesting allowed: yes

Seccomp:
  Profile: default
  Syscall filtering: enabled
  Syscall interception: mknod, setxattr (for Docker)

Capabilities:
  Dropped: CAP_SYS_ADMIN (partially), CAP_NET_ADMIN (host-level), etc.
  Added: None (unprivileged)
```

### SSH Security

```yaml
OpenSSH Server config (/etc/ssh/sshd_config):
  PermitRootLogin: no (implicit, root login disabled)
  PasswordAuthentication: yes (for lab simplicity)
  PubkeyAuthentication: yes
  ChallengeResponseAuthentication: no
  UsePAM: yes
  X11Forwarding: yes (useful for GUI apps)
  PrintMotd: no
  AcceptEnv: LANG LC_*
  Subsystem sftp: /usr/lib/openssh/sftp-server

Password strength:
  Current: weak (student1, student2, student3)
  Recommendation: Change to stronger in production

Recommended improvements:
  - Disable PasswordAuthentication
  - Use SSH keys only
  - Enable fail2ban
  - Limit SSH access by IP
```

### Docker Security

```yaml
Docker daemon:
  Rootless mode: No (requires privileged or rootless LXD)
  User namespaces: No (uses host Docker namespace)
  Seccomp: Enabled (default profile)
  AppArmor: Enabled (docker-default profile)

Docker socket:
  Path: /var/run/docker.sock
  Owner: root:docker
  Permissions: 660
  Group access: docker group (labuser is member)

Security recommendations:
  - Don't run untrusted images
  - Don't mount host paths carelessly
  - Use Docker Content Trust in production
  - Scan images with Trivy (taught in Lab 7)
```

---

## Monitoring and Logging

### System Monitoring

**Host level:**
```bash
# CPU and memory
htop

# Disk usage
df -h

# Network
iftop -i lxdbr0

# LXD operations
journalctl -u lxd -f
```

**Container level:**
```bash
# Resource usage
lxc list -c ns4M

# Detailed info
lxc info <container-name>

# Logs
lxc info <container-name> --show-log

# Enter container
lxc exec <container-name> -- bash
```

### Log Locations

**Host logs:**
```yaml
LXD daemon: /var/log/lxd/lxd.log
Systemd journal: journalctl -u lxd
UFW logs: /var/log/ufw.log
System logs: /var/log/syslog

Container logs (host view):
  /var/snap/lxd/common/lxd/logs/<container-name>/
```

**Container logs (inside container):**
```yaml
System: /var/log/syslog
Auth: /var/log/auth.log
Docker: journalctl -u docker
SSH: /var/log/auth.log
```

### Metrics

**Key metrics to monitor:**
```yaml
Host:
  - CPU usage (should be < 80% sustained)
  - Memory usage (should have >1GB free + swap)
  - Disk usage (should be < 80%)
  - Network bandwidth (check for anomalies)
  - Swap usage (> 1GB swap used indicates memory pressure)

Container:
  - Memory usage per container (should be < 2GB)
  - CPU usage per container (should be fair-shared)
  - Disk usage per container (should be < 15GB)
  - Docker resource usage (containers, images, volumes)

Network:
  - lxdbr0 traffic (in/out bytes)
  - Port forwarding connectivity
  - DNS resolution success rate
```

---

## Backup and Recovery

### Backup Strategy

**Snapshot-based:**
```bash
# Daily snapshots (automated)
lxc snapshot <container> daily-$(date +%Y%m%d)

# Keep last 7 days
lxc info <container> | grep Snapshots
lxc delete <container>/<snapshot-name>  # Delete old
```

**Image-based:**
```bash
# Weekly full backups (automated)
lxc publish <container> --alias backup-$(date +%Y%m%d)
lxc image export backup-$(date +%Y%m%d) /backup/
```

### Recovery Procedures

**From snapshot:**
```bash
# List snapshots
lxc info devops-student1 | grep -A 10 Snapshots

# Restore
lxc restore devops-student1 <snapshot-name>
```

**From image backup:**
```bash
# Import image
lxc image import /backup/image.tar.gz --alias recovered

# Create new container
lxc launch recovered devops-student1-recovered -p default -p devops-lab

# Reconfigure (passwords, proxy devices)
```

**Complete rebuild:**
```bash
# Delete old container
lxc delete --force devops-student1

# Launch new from template
lxc launch devops-lab-base devops-student1 -p default -p devops-lab

# Reconfigure (see ADMIN-GUIDE.md)
```

---

## Performance Tuning

### Recommended Optimizations

**Memory:**
```bash
# Adjust swappiness (lower = less swap usage)
sudo sysctl vm.swappiness=10

# Enable zswap (compressed swap in RAM)
# Add to /etc/default/grub:
# GRUB_CMDLINE_LINUX="zswap.enabled=1"
```

**Disk I/O:**
```bash
# Use ZFS or Btrfs for LXD storage (instead of dir)
# Provides better performance and features
lxc storage create zfs-pool zfs size=50GB
lxc profile device set default root pool=zfs-pool
```

**Network:**
```bash
# Increase lxdbr0 MTU (if supported by host network)
lxc network set lxdbr0 bridge.mtu 9000

# Enable TCP BBR congestion control (host)
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
```

---

## Maintenance Schedule

### Daily

- Monitor disk usage (`df -h`)
- Check container status (`lxc list`)
- Review system logs for errors

### Weekly

- Create image backups
- Prune old Docker images/containers in labs
- Review resource usage trends
- Update security patches

### Monthly

- Full system backup (export all containers)
- Review and rotate logs
- Test recovery procedures
- Update template image if needed

---

**Viimane uuendus:** 2025-12-01
**Versioon:** 1.2
**Vastutav:** VPS Admin
**Järgmine ülevaatus:** 2025-12-28
**Muudatuste logi:**
- 2025-12-01: Lisatud lab2-setup alias dokumentatsioon
- 2025-11-26: Lisa containerd.io 1.7.28 downgrade info ja sysctl bug workaround
- 2025-11-25: Esialgne versioon
