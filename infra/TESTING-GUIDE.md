# LXD DevOps Laborikeskkonna Testimisjuhend

## Ülevaade

See juhend on mõeldud LXD laborikeskkonna **testimiseks ERALDI TESTMASINAS** pärast paigaldust.

**⚠️ TÄHTIS:**
- Ära testi paigaldusprotsessi ajal tootmismasinas!
- Kasuta eraldi testarvutit või VM'i
- Testimine toimub PÄRAST täielikku paigaldust

**Testimise eeldused:**
- LXD on paigaldatud ja seadistatud ([INSTALLATION.md](INSTALLATION.md) järgi)
- Template image (devops-lab-base) on loodud
- Vähemalt 1 õpilaskonteiner on käivitatud

---

## Sisukord

1. [Testimise Ettevalmistus](#1-testimise-ettevalmistus)
2. [Host Süsteemi Testid](#2-host-süsteemi-testid)
3. [LXD Funktsionaalsuse Testid](#3-lxd-funktsionaalsuse-testid)
4. [Konteineri Sisemised Testid](#4-konteineri-sisemised-testid)
5. [Docker Funktsionaalsuse Testid](#5-docker-funktsionaalsuse-testid)
6. [Võrgu Testid](#6-võrgu-testid)
7. [Port Forwarding Testid](#7-port-forwarding-testid)
8. [Labs Failide Testid](#8-labs-failide-testid)
9. [Koormustestid](#9-koormustestid)
10. [Turvalisuse Testid](#10-turvalisuse-testid)
11. [Testimise Checklist](#11-testimise-checklist)

---

## 1. Testimise Ettevalmistus

### 1.1 Testimismasina Nõuded

**Miinimum testimiseks:**
- Sama OS nagu tootmissüsteemis (Ubuntu 24.04)
- 8GB RAM
- 2 CPU cores
- 40GB disk
- Võrguühendus

**Testimisstsenaariumi valikud:**

| Stsenaarium | Kirjeldus | Kus testida |
|-------------|-----------|-------------|
| **A) VM testimine** | VirtualBox/VMware VM | Kohalik arvuti |
| **B) Eraldi füüsiline arvuti** | Vana laptop/desktop | Kohalik võrk |
| **C) Odav VPS** | DigitalOcean/Hetzner $5/kuu | Internet |

### 1.2 Testimise Töövoog

```
1. Paigalda LXD testmasinas (INSTALLATION.md)
   ↓
2. Käivita põhitestid (Test Suite 1)
   ↓
3. Testi Docker'it (Test Suite 2)
   ↓
4. Testi võrku ja port forwarding'ut (Test Suite 3)
   ↓
5. Testi labs faile (Test Suite 4)
   ↓
6. Koormustestid (Test Suite 5)
   ↓
7. Dokumenteeri tulemused
   ↓
8. Kui kõik OK → paigalda tootmisse
```

### 1.3 Testimise Logimise Seadistamine

```bash
# Loo testimise kataloog
mkdir -p ~/devops-lab-tests
cd ~/devops-lab-tests

# Loo log fail
cat > test-log.txt << 'EOF'
# LXD DevOps Lab Testing Log
# Date: $(date +%Y-%m-%d)
# Tester: $(whoami)
# Machine: $(hostname)

=====================================
EOF

# Funktsioon testide logimiseks
test_log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a test-log.txt
}

# Funktsioon testide tulemuste jaoks
test_result() {
  local test_name="$1"
  local result="$2"
  local details="$3"

  if [ "$result" = "PASS" ]; then
    echo "✅ PASS: $test_name" | tee -a test-log.txt
  else
    echo "❌ FAIL: $test_name - $details" | tee -a test-log.txt
  fi
}
```

---

## 2. Host Süsteemi Testid

### Test 2.1: Süsteeminõuded

```bash
#!/bin/bash
# Test: System Requirements Check

test_log "=== Test 2.1: System Requirements ==="

# CPU cores
CPU_CORES=$(nproc)
test_log "CPU cores: $CPU_CORES"
if [ "$CPU_CORES" -ge 2 ]; then
  test_result "CPU cores" "PASS" "Found $CPU_CORES cores"
else
  test_result "CPU cores" "FAIL" "Only $CPU_CORES cores (need 2+)"
fi

# RAM
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
test_log "RAM: ${RAM_GB}GB"
if [ "$RAM_GB" -ge 6 ]; then
  test_result "RAM" "PASS" "Found ${RAM_GB}GB"
else
  test_result "RAM" "FAIL" "Only ${RAM_GB}GB (need 6+ GB)"
fi

# Virtualization
if egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
  test_result "Virtualization" "PASS" "AMD-V or VT-x enabled"
else
  test_result "Virtualization" "FAIL" "No virtualization support"
fi

# Disk space
DISK_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
test_log "Free disk: ${DISK_GB}GB"
if [ "$DISK_GB" -ge 30 ]; then
  test_result "Disk space" "PASS" "Found ${DISK_GB}GB free"
else
  test_result "Disk space" "FAIL" "Only ${DISK_GB}GB free (need 30+ GB)"
fi

# OS version
OS_VERSION=$(lsb_release -rs)
test_log "OS version: Ubuntu $OS_VERSION"
if [ "$OS_VERSION" = "24.04" ]; then
  test_result "OS version" "PASS" "Ubuntu 24.04"
else
  test_result "OS version" "FAIL" "Not Ubuntu 24.04 (found $OS_VERSION)"
fi
```

### Test 2.2: Swap Konfiguratsioon

```bash
#!/bin/bash
# Test: Swap Configuration

test_log "=== Test 2.2: Swap Configuration ==="

SWAP_SIZE=$(free -g | awk '/^Swap:/{print $2}')
test_log "Swap size: ${SWAP_SIZE}GB"

if [ "$SWAP_SIZE" -ge 4 ]; then
  test_result "Swap size" "PASS" "Found ${SWAP_SIZE}GB swap"
else
  test_result "Swap size" "FAIL" "Only ${SWAP_SIZE}GB swap (need 4+ GB)"
fi

# Swappiness check
SWAPPINESS=$(cat /proc/sys/vm/swappiness)
test_log "Swappiness: $SWAPPINESS"
if [ "$SWAPPINESS" -le 60 ]; then
  test_result "Swappiness" "PASS" "Swappiness is $SWAPPINESS"
else
  test_result "Swappiness" "FAIL" "Swappiness too high: $SWAPPINESS"
fi
```

### Test 2.3: Võrgu Konfiguratsioon

```bash
#!/bin/bash
# Test: Network Configuration

test_log "=== Test 2.3: Network Configuration ==="

# Internet connectivity
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
  test_result "Internet connectivity" "PASS" "Can reach 8.8.8.8"
else
  test_result "Internet connectivity" "FAIL" "Cannot reach 8.8.8.8"
fi

# DNS resolution
if ping -c 3 google.com > /dev/null 2>&1; then
  test_result "DNS resolution" "PASS" "Can resolve google.com"
else
  test_result "DNS resolution" "FAIL" "Cannot resolve google.com"
fi

# IP forwarding
IP_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward)
test_log "IP forwarding: $IP_FORWARD"
if [ "$IP_FORWARD" = "1" ]; then
  test_result "IP forwarding" "PASS" "Enabled"
else
  test_result "IP forwarding" "FAIL" "Disabled (need to enable)"
fi
```

---

## 3. LXD Funktsionaalsuse Testid

### Test 3.1: LXD Installatsioon

```bash
#!/bin/bash
# Test: LXD Installation

test_log "=== Test 3.1: LXD Installation ==="

# LXD installed
if command -v lxd > /dev/null 2>&1; then
  LXD_VERSION=$(lxd --version)
  test_result "LXD installed" "PASS" "Version: $LXD_VERSION"
else
  test_result "LXD installed" "FAIL" "LXD not found"
  exit 1
fi

# LXD service running
if systemctl is-active --quiet snap.lxd.daemon; then
  test_result "LXD service" "PASS" "Running"
else
  test_result "LXD service" "FAIL" "Not running"
fi

# User in lxd group
if groups | grep -q lxd; then
  test_result "User in lxd group" "PASS" "$(whoami) is in lxd group"
else
  test_result "User in lxd group" "FAIL" "$(whoami) not in lxd group"
fi
```

### Test 3.2: lxdbr0 Bridge

```bash
#!/bin/bash
# Test: lxdbr0 Bridge Configuration

test_log "=== Test 3.2: lxdbr0 Bridge ==="

# Bridge exists
if ip link show lxdbr0 > /dev/null 2>&1; then
  test_result "lxdbr0 exists" "PASS" "Bridge found"
else
  test_result "lxdbr0 exists" "FAIL" "Bridge not found"
  exit 1
fi

# Bridge has IP
BRIDGE_IP=$(ip addr show lxdbr0 | grep 'inet ' | awk '{print $2}')
test_log "lxdbr0 IP: $BRIDGE_IP"
if [ -n "$BRIDGE_IP" ]; then
  test_result "lxdbr0 IP" "PASS" "IP: $BRIDGE_IP"
else
  test_result "lxdbr0 IP" "FAIL" "No IP assigned"
fi

# Bridge is UP
BRIDGE_STATE=$(ip link show lxdbr0 | grep 'state UP')
if [ -n "$BRIDGE_STATE" ]; then
  test_result "lxdbr0 state" "PASS" "UP"
else
  test_result "lxdbr0 state" "FAIL" "Not UP"
fi

# NAT rules exist
if sudo iptables -t nat -L -n | grep -q lxdbr0; then
  test_result "NAT rules" "PASS" "Found NAT rules for lxdbr0"
else
  test_result "NAT rules" "FAIL" "No NAT rules for lxdbr0"
fi
```

### Test 3.3: Storage Pool

```bash
#!/bin/bash
# Test: LXD Storage Pool

test_log "=== Test 3.3: Storage Pool ==="

# Default pool exists
if lxc storage list | grep -q default; then
  test_result "Default pool" "PASS" "Exists"
else
  test_result "Default pool" "FAIL" "Not found"
  exit 1
fi

# Storage driver
STORAGE_DRIVER=$(lxc storage show default | grep 'driver:' | awk '{print $2}')
test_log "Storage driver: $STORAGE_DRIVER"
test_result "Storage driver" "PASS" "Driver: $STORAGE_DRIVER"

# Storage space
STORAGE_USED=$(lxc storage info default | grep 'space used:' | awk '{print $3}')
test_log "Storage used: $STORAGE_USED"
```

### Test 3.4: Template Image

```bash
#!/bin/bash
# Test: Template Image Exists

test_log "=== Test 3.4: Template Image ==="

# Check if template exists
if lxc image list | grep -q devops-lab-base; then
  IMAGE_SIZE=$(lxc image list | grep devops-lab-base | awk '{print $5}')
  test_result "Template image" "PASS" "devops-lab-base exists (size: $IMAGE_SIZE)"
else
  test_result "Template image" "FAIL" "devops-lab-base not found"
  exit 1
fi

# Image fingerprint
IMAGE_FP=$(lxc image list | grep devops-lab-base | awk '{print $2}')
test_log "Template fingerprint: $IMAGE_FP"
```

### Test 3.5: devops-lab Profile

```bash
#!/bin/bash
# Test: devops-lab Profile

test_log "=== Test 3.5: devops-lab Profile ==="

# Profile exists
if lxc profile list | grep -q devops-lab; then
  test_result "devops-lab profile" "PASS" "Exists"
else
  test_result "devops-lab profile" "FAIL" "Not found"
  exit 1
fi

# Check security.nesting
NESTING=$(lxc profile show devops-lab | grep 'security.nesting:' | awk '{print $2}')
test_log "security.nesting: $NESTING"
if [ "$NESTING" = "\"true\"" ]; then
  test_result "security.nesting" "PASS" "Enabled"
else
  test_result "security.nesting" "FAIL" "Disabled (need true)"
fi

# Check RAM limit
RAM_LIMIT=$(lxc profile show devops-lab | grep 'limits.memory:' | awk '{print $2}')
test_log "RAM limit: $RAM_LIMIT"
test_result "RAM limit" "PASS" "Set to $RAM_LIMIT"
```

---

## 4. Konteineri Sisemised Testid

### Test 4.1: Konteineri Käivitamine

```bash
#!/bin/bash
# Test: Container Launch

test_log "=== Test 4.1: Container Launch ==="

# Launch test container
test_log "Launching test container..."
lxc launch devops-lab-base test-container -p default -p devops-lab

# Wait for IP
sleep 10

# Check if running
if lxc list test-container | grep -q RUNNING; then
  test_result "Container launch" "PASS" "test-container is RUNNING"
else
  test_result "Container launch" "FAIL" "test-container not running"
  exit 1
fi

# Check IP assignment
CONTAINER_IP=$(lxc list test-container -c 4 --format csv | cut -d' ' -f1)
test_log "Container IP: $CONTAINER_IP"
if [ -n "$CONTAINER_IP" ]; then
  test_result "Container IP" "PASS" "IP: $CONTAINER_IP"
else
  test_result "Container IP" "FAIL" "No IP assigned"
fi
```

### Test 4.2: Konteineri Internet Ühendus

```bash
#!/bin/bash
# Test: Container Internet Connectivity

test_log "=== Test 4.2: Container Internet ==="

# Ping 8.8.8.8
if lxc exec test-container -- ping -c 3 8.8.8.8 > /dev/null 2>&1; then
  test_result "Container internet" "PASS" "Can reach 8.8.8.8"
else
  test_result "Container internet" "FAIL" "Cannot reach 8.8.8.8"
fi

# DNS resolution
if lxc exec test-container -- ping -c 3 google.com > /dev/null 2>&1; then
  test_result "Container DNS" "PASS" "Can resolve google.com"
else
  test_result "Container DNS" "FAIL" "Cannot resolve google.com"
fi
```

### Test 4.3: Kasutaja ja Õigused

```bash
#!/bin/bash
# Test: User and Permissions

test_log "=== Test 4.3: User and Permissions ==="

# labuser exists
if lxc exec test-container -- id labuser > /dev/null 2>&1; then
  USER_INFO=$(lxc exec test-container -- id labuser)
  test_result "labuser exists" "PASS" "$USER_INFO"
else
  test_result "labuser exists" "FAIL" "User not found"
  exit 1
fi

# labuser in docker group
if lxc exec test-container -- groups labuser | grep -q docker; then
  test_result "labuser in docker group" "PASS" "Member of docker group"
else
  test_result "labuser in docker group" "FAIL" "Not in docker group"
fi

# Home directory
if lxc exec test-container -- test -d /home/labuser; then
  test_result "labuser home" "PASS" "/home/labuser exists"
else
  test_result "labuser home" "FAIL" "/home/labuser not found"
fi

# Labs directory
if lxc exec test-container -- test -d /home/labuser/labs; then
  test_result "labs directory" "PASS" "/home/labuser/labs exists"
else
  test_result "labs directory" "FAIL" "/home/labuser/labs not found"
fi
```

### Test 4.4: Sudo Õigused

```bash
#!/bin/bash
# Test: Sudo Permissions

test_log "=== Test 4.4: Sudo Permissions ==="

# Sudoers file exists
if lxc exec test-container -- test -f /etc/sudoers.d/labuser-devops; then
  test_result "Sudoers file" "PASS" "/etc/sudoers.d/labuser-devops exists"
else
  test_result "Sudoers file" "FAIL" "Sudoers file not found"
fi

# lsof works without password
if lxc exec test-container -- su - labuser -c 'sudo lsof -i :22' > /dev/null 2>&1; then
  test_result "Sudo lsof" "PASS" "lsof works without password"
else
  test_result "Sudo lsof" "FAIL" "lsof requires password or fails"
fi

# apt-get requires password (security check)
if lxc exec test-container -- su - labuser -c 'timeout 2 sudo apt-get update 2>&1 | grep -q password'; then
  test_result "Sudo security" "PASS" "apt-get requires password (good!)"
else
  test_result "Sudo security" "FAIL" "apt-get doesn't require password (security risk!)"
fi
```

### Test 4.5: SSH Server

```bash
#!/bin/bash
# Test: SSH Server

test_log "=== Test 4.5: SSH Server ==="

# SSH service exists
if lxc exec test-container -- systemctl list-unit-files | grep -q ssh.service; then
  test_result "SSH service" "PASS" "ssh.service exists"
else
  test_result "SSH service" "FAIL" "ssh.service not found"
fi

# SSH is enabled
if lxc exec test-container -- systemctl is-enabled ssh > /dev/null 2>&1; then
  test_result "SSH enabled" "PASS" "SSH will start on boot"
else
  test_result "SSH enabled" "FAIL" "SSH not enabled"
fi

# SSH is running
if lxc exec test-container -- systemctl is-active ssh > /dev/null 2>&1; then
  test_result "SSH running" "PASS" "SSH is active"
else
  # Try to start it
  lxc exec test-container -- systemctl start ssh
  sleep 2
  if lxc exec test-container -- systemctl is-active ssh > /dev/null 2>&1; then
    test_result "SSH running" "PASS" "SSH started successfully"
  else
    test_result "SSH running" "FAIL" "SSH not running"
  fi
fi

# SSH port 22 listening
if lxc exec test-container -- netstat -tuln | grep -q ':22'; then
  test_result "SSH port" "PASS" "Port 22 listening"
else
  test_result "SSH port" "FAIL" "Port 22 not listening"
fi
```

---

## 5. Docker Funktsionaalsuse Testid

### Test 5.1: Docker Installatsioon

```bash
#!/bin/bash
# Test: Docker Installation

test_log "=== Test 5.1: Docker Installation ==="

# Docker installed
if lxc exec test-container -- docker --version > /dev/null 2>&1; then
  DOCKER_VERSION=$(lxc exec test-container -- docker --version)
  test_result "Docker installed" "PASS" "$DOCKER_VERSION"
else
  test_result "Docker installed" "FAIL" "Docker not found"
  exit 1
fi

# Docker Compose installed
if lxc exec test-container -- docker compose version > /dev/null 2>&1; then
  COMPOSE_VERSION=$(lxc exec test-container -- docker compose version)
  test_result "Docker Compose" "PASS" "$COMPOSE_VERSION"
else
  test_result "Docker Compose" "FAIL" "Docker Compose not found"
fi

# containerd version check
CONTAINERD_VERSION=$(lxc exec test-container -- containerd --version | awk '{print $3}')
test_log "containerd version: $CONTAINERD_VERSION"
if [[ "$CONTAINERD_VERSION" == "1.7.28" ]]; then
  test_result "containerd version" "PASS" "Version 1.7.28 (correct!)"
else
  test_result "containerd version" "FAIL" "Version $CONTAINERD_VERSION (should be 1.7.28!)"
fi

# containerd is on hold
if lxc exec test-container -- apt-mark showhold | grep -q containerd.io; then
  test_result "containerd hold" "PASS" "Version locked"
else
  test_result "containerd hold" "FAIL" "Version NOT locked (security risk!)"
fi
```

### Test 5.2: Docker Service

```bash
#!/bin/bash
# Test: Docker Service

test_log "=== Test 5.2: Docker Service ==="

# Docker daemon running
if lxc exec test-container -- systemctl is-active docker > /dev/null 2>&1; then
  test_result "Docker daemon" "PASS" "Running"
else
  test_result "Docker daemon" "FAIL" "Not running"
  exit 1
fi

# Docker socket exists
if lxc exec test-container -- test -S /var/run/docker.sock; then
  test_result "Docker socket" "PASS" "/var/run/docker.sock exists"
else
  test_result "Docker socket" "FAIL" "Socket not found"
fi

# Docker socket permissions
SOCKET_PERMS=$(lxc exec test-container -- stat -c %a /var/run/docker.sock)
test_log "Docker socket permissions: $SOCKET_PERMS"
if [ "$SOCKET_PERMS" = "660" ]; then
  test_result "Socket permissions" "PASS" "660 (correct)"
else
  test_result "Socket permissions" "FAIL" "$SOCKET_PERMS (should be 660)"
fi
```

### Test 5.3: Docker Hello World

```bash
#!/bin/bash
# Test: Docker Hello World

test_log "=== Test 5.3: Docker Hello World ==="

# Run hello-world
test_log "Running: docker run --rm hello-world"
HELLO_OUTPUT=$(lxc exec test-container -- su - labuser -c 'docker run --rm hello-world 2>&1')

if echo "$HELLO_OUTPUT" | grep -q "Hello from Docker"; then
  test_result "Docker hello-world" "PASS" "Container ran successfully"
else
  test_result "Docker hello-world" "FAIL" "Failed to run container"
  test_log "Output: $HELLO_OUTPUT"
fi
```

### Test 5.4: Docker Alpine (sysctl Bug Test)

```bash
#!/bin/bash
# Test: Docker Alpine (sysctl bug)

test_log "=== Test 5.4: Docker Alpine (sysctl bug test) ==="

# Run alpine echo test
test_log "Running: docker run --rm alpine:3.16 echo 'OK'"
ALPINE_OUTPUT=$(lxc exec test-container -- su - labuser -c 'docker run --rm alpine:3.16 echo OK 2>&1')

if echo "$ALPINE_OUTPUT" | grep -q "OK"; then
  test_result "Docker alpine" "PASS" "No sysctl error"
else
  test_result "Docker alpine" "FAIL" "sysctl permission denied error"
  test_log "Output: $ALPINE_OUTPUT"
fi
```

### Test 5.5: Docker PostgreSQL 16

```bash
#!/bin/bash
# Test: Docker PostgreSQL 16-alpine

test_log "=== Test 5.5: Docker PostgreSQL 16-alpine ==="

# Run PostgreSQL version check
test_log "Running: docker run --rm postgres:16-alpine postgres --version"
PG_OUTPUT=$(lxc exec test-container -- su - labuser -c 'docker run --rm -e POSTGRES_PASSWORD=test postgres:16-alpine postgres --version 2>&1')

if echo "$PG_OUTPUT" | grep -q "PostgreSQL 16"; then
  test_result "PostgreSQL 16" "PASS" "PostgreSQL container works"
else
  test_result "PostgreSQL 16" "FAIL" "PostgreSQL failed to run"
  test_log "Output: $PG_OUTPUT"
fi
```

### Test 5.6: Docker Images ja Volumes

```bash
#!/bin/bash
# Test: Docker Images and Volumes

test_log "=== Test 5.6: Docker Images and Volumes ==="

# List images
IMAGE_COUNT=$(lxc exec test-container -- su - labuser -c 'docker images -q' | wc -l)
test_log "Docker images: $IMAGE_COUNT"
test_result "Docker images" "PASS" "$IMAGE_COUNT images found"

# Create volume
lxc exec test-container -- su - labuser -c 'docker volume create test-volume' > /dev/null 2>&1
if lxc exec test-container -- su - labuser -c 'docker volume ls | grep -q test-volume'; then
  test_result "Docker volume create" "PASS" "Volume created"
  # Cleanup
  lxc exec test-container -- su - labuser -c 'docker volume rm test-volume' > /dev/null 2>&1
else
  test_result "Docker volume create" "FAIL" "Failed to create volume"
fi
```

---

## 6. Võrgu Testid

### Test 6.1: Konteineri Võrk

```bash
#!/bin/bash
# Test: Container Network

test_log "=== Test 6.1: Container Network ==="

# eth0 exists
if lxc exec test-container -- ip link show eth0 > /dev/null 2>&1; then
  test_result "eth0 interface" "PASS" "Exists"
else
  test_result "eth0 interface" "FAIL" "Not found"
fi

# IP on eth0
CONTAINER_IP=$(lxc exec test-container -- ip addr show eth0 | grep 'inet ' | awk '{print $2}')
test_log "Container IP: $CONTAINER_IP"
if [ -n "$CONTAINER_IP" ]; then
  test_result "eth0 IP" "PASS" "IP: $CONTAINER_IP"
else
  test_result "eth0 IP" "FAIL" "No IP assigned"
fi

# Default route
if lxc exec test-container -- ip route | grep -q default; then
  DEFAULT_GW=$(lxc exec test-container -- ip route | grep default | awk '{print $3}')
  test_result "Default route" "PASS" "Gateway: $DEFAULT_GW"
else
  test_result "Default route" "FAIL" "No default route"
fi

# DNS servers
DNS_SERVERS=$(lxc exec test-container -- cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
test_log "DNS servers: $DNS_SERVERS"
test_result "DNS configured" "PASS" "Nameservers: $DNS_SERVERS"
```

### Test 6.2: Docker Võrk

```bash
#!/bin/bash
# Test: Docker Network

test_log "=== Test 6.2: Docker Network ==="

# docker0 bridge exists
if lxc exec test-container -- ip link show docker0 > /dev/null 2>&1; then
  test_result "docker0 bridge" "PASS" "Exists"
else
  test_result "docker0 bridge" "FAIL" "Not found"
fi

# docker0 has IP
DOCKER0_IP=$(lxc exec test-container -- ip addr show docker0 | grep 'inet ' | awk '{print $2}')
test_log "docker0 IP: $DOCKER0_IP"
if [ -n "$DOCKER0_IP" ]; then
  test_result "docker0 IP" "PASS" "IP: $DOCKER0_IP"
else
  test_result "docker0 IP" "FAIL" "No IP assigned"
fi

# List docker networks
DOCKER_NETWORKS=$(lxc exec test-container -- su - labuser -c 'docker network ls --format "{{.Name}}"')
test_log "Docker networks: $DOCKER_NETWORKS"
if echo "$DOCKER_NETWORKS" | grep -q bridge; then
  test_result "Docker networks" "PASS" "Default networks exist"
else
  test_result "Docker networks" "FAIL" "Default networks missing"
fi
```

---

## 7. Port Forwarding Testid

**MÄRKUS:** Seda testi saab teha ainult kui konteineril on proxy devices seadistatud.

### Test 7.1: SSH Port Forwarding

```bash
#!/bin/bash
# Test: SSH Port Forwarding

test_log "=== Test 7.1: SSH Port Forwarding ==="

# Add SSH proxy device
lxc config device add test-container ssh-proxy proxy \
  listen=tcp:0.0.0.0:2299 \
  connect=tcp:127.0.0.1:22 \
  nat=true

sleep 5

# Check if port is listening on host
if netstat -tuln | grep -q ':2299'; then
  test_result "SSH port listening" "PASS" "Port 2299 listening on host"
else
  test_result "SSH port listening" "FAIL" "Port 2299 not listening"
fi

# Try to connect via SSH (will fail auth, but connection should work)
# This test requires sshpass or manual SSH test
test_log "Manual test: ssh labuser@localhost -p 2299 (password: temppassword)"
```

### Test 7.2: Port Forwarding Cleanup

```bash
#!/bin/bash
# Test: Port Forwarding Cleanup

test_log "Cleaning up test port forwarding..."
lxc config device remove test-container ssh-proxy || true
```

---

## 8. Labs Failide Testid

### Test 8.1: Labs Kataloog

```bash
#!/bin/bash
# Test: Labs Directory Structure

test_log "=== Test 8.1: Labs Directory ==="

# labs directory exists
if lxc exec test-container -- test -d /home/labuser/labs; then
  test_result "labs directory" "PASS" "Exists"
else
  test_result "labs directory" "FAIL" "Not found"
  exit 1
fi

# Check ownership
LABS_OWNER=$(lxc exec test-container -- stat -c '%U:%G' /home/labuser/labs)
test_log "labs ownership: $LABS_OWNER"
if [ "$LABS_OWNER" = "labuser:labuser" ]; then
  test_result "labs ownership" "PASS" "labuser:labuser"
else
  test_result "labs ownership" "FAIL" "$LABS_OWNER (should be labuser:labuser)"
fi

# Count lab directories
LAB_COUNT=$(lxc exec test-container -- find /home/labuser/labs -maxdepth 1 -type d -name '*-lab' | wc -l)
test_log "Lab directories found: $LAB_COUNT"
if [ "$LAB_COUNT" -ge 1 ]; then
  test_result "Lab directories" "PASS" "Found $LAB_COUNT labs"
else
  test_result "Lab directories" "FAIL" "No lab directories found"
fi
```

### Test 8.2: Bash Aliases

```bash
#!/bin/bash
# Test: Bash Aliases

test_log "=== Test 8.2: Bash Aliases ==="

# Check .bashrc
if lxc exec test-container -- test -f /home/labuser/.bashrc; then
  test_result ".bashrc exists" "PASS" "File found"
else
  test_result ".bashrc exists" "FAIL" "Not found"
  exit 1
fi

# Check if aliases are defined
if lxc exec test-container -- grep -q 'alias docker-stop-all' /home/labuser/.bashrc; then
  test_result "docker-stop-all alias" "PASS" "Defined in .bashrc"
else
  test_result "docker-stop-all alias" "FAIL" "Not defined"
fi

if lxc exec test-container -- grep -q 'alias check-resources' /home/labuser/.bashrc; then
  test_result "check-resources alias" "PASS" "Defined in .bashrc"
else
  test_result "check-resources alias" "FAIL" "Not defined"
fi

# Check JAVA_HOME
if lxc exec test-container -- grep -q 'JAVA_HOME' /home/labuser/.bashrc; then
  test_result "JAVA_HOME" "PASS" "Defined in .bashrc"
else
  test_result "JAVA_HOME" "FAIL" "Not defined"
fi
```

---

## 9. Koormustestid

### Test 9.1: Ressursside Kasutus (Idle)

```bash
#!/bin/bash
# Test: Resource Usage (Idle)

test_log "=== Test 9.1: Resource Usage (Idle) ==="

# Container memory usage
MEM_USAGE=$(lxc list test-container -c 4M --format csv | awk '{print $2}')
test_log "Container memory (idle): $MEM_USAGE"

# Extract number (remove MiB suffix)
MEM_NUM=$(echo $MEM_USAGE | sed 's/MiB//')
if [ "$MEM_NUM" -lt 500 ]; then
  test_result "Idle memory" "PASS" "$MEM_USAGE (under 500MiB)"
else
  test_result "Idle memory" "FAIL" "$MEM_USAGE (over 500MiB)"
fi

# Docker containers running
DOCKER_COUNT=$(lxc exec test-container -- su - labuser -c 'docker ps -q' | wc -l)
test_log "Running Docker containers: $DOCKER_COUNT"
if [ "$DOCKER_COUNT" -eq 0 ]; then
  test_result "Docker containers" "PASS" "No containers running (idle)"
else
  test_result "Docker containers" "FAIL" "$DOCKER_COUNT containers running (should be 0)"
fi
```

### Test 9.2: Stress Test

```bash
#!/bin/bash
# Test: Stress Test with Docker

test_log "=== Test 9.2: Stress Test ==="

# Run 3 nginx containers simultaneously
test_log "Starting 3 nginx containers..."
lxc exec test-container -- su - labuser -c 'for i in 1 2 3; do docker run -d --name nginx-test-$i nginx:alpine; done'

sleep 10

# Check if all running
NGINX_COUNT=$(lxc exec test-container -- su - labuser -c 'docker ps --filter name=nginx-test -q' | wc -l)
test_log "Running nginx containers: $NGINX_COUNT"

if [ "$NGINX_COUNT" -eq 3 ]; then
  test_result "Stress test" "PASS" "All 3 nginx containers running"
else
  test_result "Stress test" "FAIL" "Only $NGINX_COUNT/3 containers running"
fi

# Check memory under load
MEM_LOAD=$(lxc list test-container -c 4M --format csv | awk '{print $2}')
test_log "Container memory (under load): $MEM_LOAD"

# Cleanup
test_log "Cleaning up stress test..."
lxc exec test-container -- su - labuser -c 'docker stop nginx-test-1 nginx-test-2 nginx-test-3' > /dev/null 2>&1
lxc exec test-container -- su - labuser -c 'docker rm nginx-test-1 nginx-test-2 nginx-test-3' > /dev/null 2>&1
```

---

## 10. Turvalisuse Testid

### Test 10.1: Unprivileged Container

```bash
#!/bin/bash
# Test: Unprivileged Container

test_log "=== Test 10.1: Unprivileged Container ==="

# Check security.privileged
PRIVILEGED=$(lxc config show test-container | grep 'security.privileged:' | awk '{print $2}')
test_log "security.privileged: $PRIVILEGED"

if [ "$PRIVILEGED" = "\"false\"" ] || [ -z "$PRIVILEGED" ]; then
  test_result "Unprivileged container" "PASS" "Container is unprivileged"
else
  test_result "Unprivileged container" "FAIL" "Container is privileged (security risk!)"
fi

# Check UID mapping
UID_MAP=$(lxc config show test-container | grep 'uid:')
test_log "UID mapping: $UID_MAP"
```

### Test 10.2: AppArmor Profile

```bash
#!/bin/bash
# Test: AppArmor Profile

test_log "=== Test 10.2: AppArmor Profile ==="

# Check if AppArmor is enabled
if sudo aa-status > /dev/null 2>&1; then
  test_result "AppArmor" "PASS" "AppArmor is enabled on host"
else
  test_result "AppArmor" "FAIL" "AppArmor not enabled"
fi

# Container's AppArmor profile
CONTAINER_PROFILE=$(sudo aa-status 2>/dev/null | grep lxc-test-container || echo "none")
test_log "Container AppArmor profile: $CONTAINER_PROFILE"
```

### Test 10.3: Root Access

```bash
#!/bin/bash
# Test: Root Access

test_log "=== Test 10.3: Root Access ==="

# labuser cannot become root without password
if lxc exec test-container -- su - labuser -c 'timeout 2 su -' 2>&1 | grep -q 'Password:'; then
  test_result "Root access" "PASS" "labuser cannot su without password"
else
  test_result "Root access" "FAIL" "labuser can become root (security risk!)"
fi
```

---

## 11. Testimise Checklist

### Cleanup ja Lõplik Raport

```bash
#!/bin/bash
# Cleanup Test Container

test_log "=== Cleanup ==="

# Stop and delete test container
lxc delete --force test-container

test_log "Test container deleted"

# Final summary
test_log "================================="
test_log "TESTING COMPLETED"
test_log "================================="
test_log "Review test-log.txt for full results"

# Count results
PASS_COUNT=$(grep "✅ PASS" test-log.txt | wc -l)
FAIL_COUNT=$(grep "❌ FAIL" test-log.txt | wc -l)

echo ""
echo "================================="
echo "FINAL RESULTS"
echo "================================="
echo "✅ Passed: $PASS_COUNT"
echo "❌ Failed: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "🎉 ALL TESTS PASSED!"
  echo "✅ System ready for production deployment"
else
  echo "⚠️  SOME TESTS FAILED"
  echo "❌ Review test-log.txt and fix issues before production"
fi

echo ""
echo "Log file: test-log.txt"
```

### Testimise Checklist (Manuaalne)

Märgi ära pärast iga testi:

- [ ] **Test 2.1** - Süsteeminõuded (CPU, RAM, Disk, Virtualization)
- [ ] **Test 2.2** - Swap konfiguratsioon
- [ ] **Test 2.3** - Võrgu konfiguratsioon (Internet, DNS, IP forwarding)
- [ ] **Test 3.1** - LXD installatsioon
- [ ] **Test 3.2** - lxdbr0 bridge (IP, NAT, state UP)
- [ ] **Test 3.3** - Storage pool (default exists, driver)
- [ ] **Test 3.4** - Template image (devops-lab-base)
- [ ] **Test 3.5** - devops-lab profile (nesting, RAM limit)
- [ ] **Test 4.1** - Konteineri käivitamine (RUNNING, IP)
- [ ] **Test 4.2** - Konteineri internet (ping, DNS)
- [ ] **Test 4.3** - Kasutaja ja õigused (labuser, docker group, home, labs)
- [ ] **Test 4.4** - Sudo õigused (lsof works, apt-get requires password)
- [ ] **Test 4.5** - SSH server (enabled, running, port 22)
- [ ] **Test 5.1** - Docker installatsioon (version, Compose, containerd 1.7.28)
- [ ] **Test 5.2** - Docker service (running, socket, permissions)
- [ ] **Test 5.3** - Docker hello-world
- [ ] **Test 5.4** - Docker Alpine (sysctl bug test)
- [ ] **Test 5.5** - Docker PostgreSQL 16-alpine
- [ ] **Test 5.6** - Docker images ja volumes
- [ ] **Test 6.1** - Konteineri võrk (eth0, IP, default route, DNS)
- [ ] **Test 6.2** - Docker võrk (docker0, networks)
- [ ] **Test 7.1** - SSH port forwarding
- [ ] **Test 8.1** - Labs kataloog (exists, ownership, count)
- [ ] **Test 8.2** - Bash aliases (docker-stop-all, check-resources, JAVA_HOME)
- [ ] **Test 9.1** - Ressursside kasutus (idle memory < 500MiB)
- [ ] **Test 9.2** - Stress test (3 nginx containers)
- [ ] **Test 10.1** - Unprivileged container (security.privileged: false)
- [ ] **Test 10.2** - AppArmor profile
- [ ] **Test 10.3** - Root access (labuser cannot su without password)

---

## Järgmised Sammud Pärast Testimist

### Kui Kõik Testid Läbitud (PASS)

1. **Dokumenteeri tulemused:**
   ```bash
   cp test-log.txt ~/devops-lab-test-results-$(date +%Y%m%d).txt
   ```

2. **Arhiveeri testmasina konfiguratsioon:**
   ```bash
   lxc image list > ~/lxd-images-snapshot.txt
   lxc profile list > ~/lxd-profiles-snapshot.txt
   ```

3. **Paigalda tootmissüsteemi:**
   - Kasuta sama INSTALLATION.md juhend
   - Rakenda samad seadistused
   - Loo sama arv õpilaskonteinereid

4. **Tee tootmissüsteemi backup:**
   ```bash
   lxc image export devops-lab-base ~/devops-lab-base-production-$(date +%Y%m%d).tar.gz
   ```

### Kui Mõned Testid Ebaõnnestusid (FAIL)

1. **Analüüsi test-log.txt:**
   ```bash
   grep "❌ FAIL" test-log.txt
   ```

2. **Paranda probleemid:**
   - Vaata [INSTALLATION.md Troubleshooting](INSTALLATION.md#12-troubleshooting)
   - Vaata ADMIN-GUIDE.md "Probleemide lahendamine"
   - Küsi abi foorum'ist või support'ist

3. **Käivita testid uuesti:**
   ```bash
   # Puhasta eelmine log
   rm test-log.txt
   # Alusta testimist uuesti
   ```

4. **Dokumenteeri lahendused:**
   - Lisa lahendused INSTALLATION.md või TESTING-GUIDE.md
   - Jaga kogemusega teiste IT administratoritega

---

## Lisainfo

**Täiendavad ressursid:**
- [INSTALLATION.md](INSTALLATION.md) - Paigaldusjuhend
- [ADMIN-GUIDE.md](ADMIN-GUIDE.md) - Administraatori juhend
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Probleemide lahendamine (kui eksisteerib)

**Abi ja tugi:**
- LXD Foorum: https://discuss.linuxcontainers.org/
- Docker Foorum: https://forums.docker.com/
- Ubuntu Community: https://askubuntu.com/

---

**Autor:** DevOps Lab Testing Team
**Versioon:** 1.0
**Viimane uuendus:** 2025-01-28
**Tagasiside:** https://github.com/yourusername/devops-labs/issues
