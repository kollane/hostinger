#!/bin/bash
#
# LXD DevOps Lab Automated Installation Script
# Version: 1.0
# Date: 2025-01-28
#
# This script automates the installation of LXD-based DevOps lab environment
# on a fresh Ubuntu 24.04 server or laptop.
#
# Usage: sudo bash install-lxd-devops.sh
#

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables (will be set by user input)
DEPLOYMENT_TYPE=""
NUM_STUDENTS=3
RAM_PER_STUDENT="2560MiB"
CPU_PER_STUDENT="1"
SSH_PORT_START=2201
WEB_PORT_START=8080
API1_PORT_START=3000
API2_PORT_START=8081
INSTALL_GIT_REPO="n"
GIT_REPO_URL=""
INSTALL_FAIL2BAN="y"
SWAP_SIZE_GB=4
ADMIN_USER=$(logname 2>/dev/null || echo $SUDO_USER)

# Log file
LOG_FILE="/tmp/lxd-devops-install-$(date +%Y%m%d-%H%M%S).log"

# Functions
log() {
  echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

success() {
  echo -e "${GREEN}✅ $*${NC}" | tee -a "$LOG_FILE"
}

warning() {
  echo -e "${YELLOW}⚠️  $*${NC}" | tee -a "$LOG_FILE"
}

error() {
  echo -e "${RED}❌ ERROR: $*${NC}" | tee -a "$LOG_FILE"
  exit 1
}

info() {
  echo -e "${BLUE}ℹ️  $*${NC}"
}

# Banner
show_banner() {
  clear
  cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║        LXD DevOps Lab Automated Installation Script           ║
║                      Version 1.0                               ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

This script will install and configure:
  • LXD container platform
  • UFW firewall
  • DevOps lab profile
  • Template image with Docker
  • Student containers
  • Labs file synchronization

Estimated time: 30-60 minutes

EOF
}

# Check prerequisites
check_prerequisites() {
  log "Checking prerequisites..."

  # Root check
  if [ "$EUID" -ne 0 ]; then
    error "Please run as root (sudo bash $0)"
  fi

  # OS check
  if [ ! -f /etc/lsb-release ]; then
    error "This script is designed for Ubuntu"
  fi

  source /etc/lsb-release
  if [ "$DISTRIB_ID" != "Ubuntu" ] || [ "$DISTRIB_RELEASE" != "24.04" ]; then
    warning "This script is designed for Ubuntu 24.04, you have $DISTRIB_ID $DISTRIB_RELEASE"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi

  # CPU cores check
  CPU_CORES=$(nproc)
  if [ "$CPU_CORES" -lt 2 ]; then
    error "Minimum 2 CPU cores required (found: $CPU_CORES)"
  fi
  success "CPU cores: $CPU_CORES"

  # RAM check
  RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
  if [ "$RAM_GB" -lt 6 ]; then
    warning "Recommended minimum 8GB RAM (found: ${RAM_GB}GB)"
  fi
  success "RAM: ${RAM_GB}GB"

  # Disk space check
  DISK_GB=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
  if [ "$DISK_GB" -lt 30 ]; then
    error "Minimum 30GB free disk space required (found: ${DISK_GB}GB)"
  fi
  success "Disk space: ${DISK_GB}GB free"

  # Virtualization check
  if ! egrep -c '(vmx|svm)' /proc/cpuinfo > /dev/null; then
    error "Hardware virtualization not enabled in BIOS"
  fi
  success "Virtualization: Enabled"

  # Internet connectivity
  if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    error "No internet connectivity"
  fi
  success "Internet: Connected"

  log "All prerequisites met!"
}

# Interactive configuration
interactive_config() {
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║                    CONFIGURATION                               ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""

  # Deployment type
  echo "Select deployment type:"
  echo "  1) VPS (Production - Static IP, 24/7)"
  echo "  2) Laptop (Development - Localhost, Portable)"
  read -p "Enter choice [1-2]: " deploy_choice

  case $deploy_choice in
    1)
      DEPLOYMENT_TYPE="vps"
      info "VPS deployment selected"
      ;;
    2)
      DEPLOYMENT_TYPE="laptop"
      info "Laptop deployment selected"
      warning "Port forwarding will use localhost (127.0.0.1)"
      ;;
    *)
      error "Invalid choice"
      ;;
  esac

  # Number of students
  echo ""
  read -p "Number of students/containers [default: 3]: " num_input
  NUM_STUDENTS=${num_input:-3}

  # Validate number
  if ! [[ "$NUM_STUDENTS" =~ ^[0-9]+$ ]] || [ "$NUM_STUDENTS" -lt 1 ] || [ "$NUM_STUDENTS" -gt 10 ]; then
    error "Number of students must be between 1 and 10"
  fi

  # RAM per student
  echo ""
  echo "RAM per student container:"
  echo "  1) 2GB (Minimum)"
  echo "  2) 2.5GB (Recommended)"
  echo "  3) 3GB (Comfortable)"
  read -p "Enter choice [1-3, default: 2]: " ram_choice
  case ${ram_choice:-2} in
    1) RAM_PER_STUDENT="2048MiB" ;;
    2) RAM_PER_STUDENT="2560MiB" ;;
    3) RAM_PER_STUDENT="3072MiB" ;;
    *) RAM_PER_STUDENT="2560MiB" ;;
  esac

  # CPU per student
  echo ""
  read -p "CPU cores per student [default: 1]: " cpu_input
  CPU_PER_STUDENT=${cpu_input:-1}

  # Resource calculation
  echo ""
  info "Resource calculation:"
  RAM_TOTAL=$((NUM_STUDENTS * ${RAM_PER_STUDENT%MiB} / 1024))
  CPU_TOTAL=$((NUM_STUDENTS * CPU_PER_STUDENT))
  info "  Total RAM needed: ~${RAM_TOTAL}GB + 1GB (host) = $((RAM_TOTAL + 1))GB"
  info "  Total CPU: ${CPU_TOTAL} cores (shared)"
  info "  Total Disk: ~$((NUM_STUDENTS * 15 + 20))GB"

  if [ $((RAM_TOTAL + 1)) -gt "$RAM_GB" ]; then
    warning "RAM may be insufficient! Consider reducing students or RAM per student"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi

  # Ports configuration
  echo ""
  info "Port configuration (defaults should be fine):"
  read -p "SSH port start [default: 2201]: " ssh_port_input
  SSH_PORT_START=${ssh_port_input:-2201}

  if [ "$DEPLOYMENT_TYPE" = "laptop" ]; then
    warning "Laptop mode: Using localhost (127.0.0.1) for all port forwarding"
  fi

  # Git repository
  echo ""
  read -p "Install Git repository with labs? (y/n) [default: n]: " git_input
  INSTALL_GIT_REPO=${git_input:-n}

  if [[ "$INSTALL_GIT_REPO" =~ ^[Yy]$ ]]; then
    read -p "Git repository URL: " GIT_REPO_URL
    if [ -z "$GIT_REPO_URL" ]; then
      warning "No URL provided, skipping Git installation"
      INSTALL_GIT_REPO="n"
    fi
  fi

  # fail2ban
  if [ "$DEPLOYMENT_TYPE" = "vps" ]; then
    echo ""
    read -p "Install fail2ban SSH protection? (y/n) [default: y]: " f2b_input
    INSTALL_FAIL2BAN=${f2b_input:-y}
  else
    INSTALL_FAIL2BAN="n"
  fi

  # Swap size
  echo ""
  read -p "Swap size in GB [default: 4]: " swap_input
  SWAP_SIZE_GB=${swap_input:-4}

  # Confirmation
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║                    CONFIGURATION SUMMARY                       ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Deployment type:     $DEPLOYMENT_TYPE"
  echo "Number of students:  $NUM_STUDENTS"
  echo "RAM per student:     $RAM_PER_STUDENT"
  echo "CPU per student:     $CPU_PER_STUDENT"
  echo "SSH port start:      $SSH_PORT_START"
  echo "Git repository:      ${INSTALL_GIT_REPO}"
  if [[ "$INSTALL_GIT_REPO" =~ ^[Yy]$ ]]; then
    echo "Git URL:             $GIT_REPO_URL"
  fi
  echo "fail2ban:            $INSTALL_FAIL2BAN"
  echo "Swap size:           ${SWAP_SIZE_GB}GB"
  echo ""

  read -p "Proceed with installation? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 0
  fi
}

# System update
system_update() {
  log "Updating system packages..."
  apt-get update >> "$LOG_FILE" 2>&1
  apt-get upgrade -y >> "$LOG_FILE" 2>&1
  apt-get install -y curl wget git vim htop net-tools ca-certificates gnupg lsb-release >> "$LOG_FILE" 2>&1
  success "System packages updated"
}

# Setup swap
setup_swap() {
  log "Configuring swap (${SWAP_SIZE_GB}GB)..."

  # Check if swap already exists
  if swapon --show | grep -q /swapfile; then
    warning "Swap file already exists, skipping creation"
    return
  fi

  if [ -f /swapfile ]; then
    warning "/swapfile exists but not activated, removing..."
    swapoff /swapfile 2>/dev/null || true
    rm /swapfile
  fi

  # Create swap
  fallocate -l ${SWAP_SIZE_GB}G /swapfile || dd if=/dev/zero of=/swapfile bs=1G count=$SWAP_SIZE_GB
  chmod 600 /swapfile
  mkswap /swapfile >> "$LOG_FILE" 2>&1
  swapon /swapfile

  # Make persistent
  if ! grep -q '/swapfile' /etc/fstab; then
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
  fi

  # Set swappiness
  sysctl vm.swappiness=10 >> "$LOG_FILE" 2>&1
  if ! grep -q 'vm.swappiness' /etc/sysctl.conf; then
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
  fi

  success "Swap configured: ${SWAP_SIZE_GB}GB"
}

# Install LXD
install_lxd() {
  log "Installing LXD..."

  # Check if already installed
  if command -v lxd > /dev/null 2>&1; then
    warning "LXD already installed, skipping..."
    return
  fi

  snap install lxd >> "$LOG_FILE" 2>&1

  # Add user to lxd group
  usermod -aG lxd "$ADMIN_USER"

  success "LXD installed"
}

# Initialize LXD
initialize_lxd() {
  log "Initializing LXD..."

  # Preseed configuration
  cat <<EOF | lxd init --preseed
config: {}
networks:
- config:
    ipv4.address: auto
    ipv4.nat: "true"
    ipv6.address: none
  description: ""
  name: lxdbr0
  type: ""
  project: default
storage_pools:
- config: {}
  description: ""
  name: default
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
projects: []
cluster: null
EOF

  success "LXD initialized"
}

# Setup UFW firewall
setup_ufw() {
  if [ "$DEPLOYMENT_TYPE" != "vps" ]; then
    info "Skipping UFW setup (not VPS deployment)"
    return
  fi

  log "Setting up UFW firewall..."

  apt-get install -y ufw >> "$LOG_FILE" 2>&1

  # Allow SSH first (critical!)
  ufw allow 22/tcp comment 'SSH' >> "$LOG_FILE" 2>&1

  # LXD bridge traffic
  ufw allow in on lxdbr0 >> "$LOG_FILE" 2>&1
  ufw route allow in on lxdbr0 >> "$LOG_FILE" 2>&1
  ufw route allow out on lxdbr0 >> "$LOG_FILE" 2>&1
  ufw default allow routed >> "$LOG_FILE" 2>&1

  # Student SSH ports (rate limited)
  END_SSH_PORT=$((SSH_PORT_START + NUM_STUDENTS - 1))
  ufw limit ${SSH_PORT_START}:${END_SSH_PORT}/tcp comment 'SSH students rate limited' >> "$LOG_FILE" 2>&1

  # Web ports
  WEB_PORT_END=$((WEB_PORT_START + (NUM_STUDENTS - 1) * 100))
  ufw allow ${WEB_PORT_START}:${WEB_PORT_END}/tcp comment 'Web services' >> "$LOG_FILE" 2>&1

  # API ports
  API1_PORT_END=$((API1_PORT_START + (NUM_STUDENTS - 1) * 100))
  ufw allow ${API1_PORT_START}:${API1_PORT_END}/tcp comment 'API services 1' >> "$LOG_FILE" 2>&1

  API2_PORT_END=$((API2_PORT_START + (NUM_STUDENTS - 1) * 100))
  ufw allow ${API2_PORT_START}:${API2_PORT_END}/tcp comment 'API services 2' >> "$LOG_FILE" 2>&1

  # Enable UFW
  echo "y" | ufw enable >> "$LOG_FILE" 2>&1

  success "UFW firewall configured"
}

# Setup fail2ban
setup_fail2ban() {
  if [[ ! "$INSTALL_FAIL2BAN" =~ ^[Yy]$ ]]; then
    info "Skipping fail2ban installation"
    return
  fi

  log "Setting up fail2ban..."

  apt-get install -y fail2ban >> "$LOG_FILE" 2>&1

  # Create custom configuration
  END_SSH_PORT=$((SSH_PORT_START + NUM_STUDENTS - 1))
  cat > /etc/fail2ban/jail.d/sshd-custom.conf <<EOF
[sshd]
enabled = true
port = 22,${SSH_PORT_START}:${END_SSH_PORT}
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

  systemctl restart fail2ban >> "$LOG_FILE" 2>&1

  success "fail2ban configured"
}

# Create devops-lab profile
create_lab_profile() {
  log "Creating devops-lab profile..."

  # Check if already exists
  if lxc profile list | grep -q devops-lab; then
    warning "devops-lab profile already exists, skipping..."
    return
  fi

  lxc profile create devops-lab

  cat <<EOF | lxc profile edit devops-lab
config:
  limits.cpu: "$CPU_PER_STUDENT"
  limits.memory: $RAM_PER_STUDENT
  limits.memory.enforce: soft
  security.nesting: "true"
  security.privileged: "false"
  security.syscalls.intercept.mknod: "true"
  security.syscalls.intercept.setxattr: "true"
description: DevOps Lab Profile - $RAM_PER_STUDENT RAM, $CPU_PER_STUDENT CPU, Docker support
devices:
  root:
    path: /
    pool: default
    type: disk
name: devops-lab
EOF

  success "devops-lab profile created"
}

# Create template image
create_template() {
  log "Creating template image (this takes 10-15 minutes)..."

  # Check if already exists
  if lxc image list | grep -q devops-lab-base; then
    warning "Template image already exists, skipping creation..."
    return
  fi

  # Launch base container
  log "  Launching base container..."
  lxc launch ubuntu:24.04 devops-template -p default -p devops-lab >> "$LOG_FILE" 2>&1
  sleep 20

  # Update and install packages
  log "  Installing base packages..."
  lxc exec devops-template -- bash -c "apt-get update && apt-get upgrade -y" >> "$LOG_FILE" 2>&1
  lxc exec devops-template -- apt-get install -y curl wget git vim nano htop ca-certificates gnupg lsb-release software-properties-common >> "$LOG_FILE" 2>&1

  # Install Docker
  log "  Installing Docker..."
  lxc exec devops-template -- bash <<'DOCKERINSTALL' >> "$LOG_FILE" 2>&1
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
DOCKERINSTALL

  # CRITICAL: containerd downgrade
  log "  Applying containerd 1.7.28 downgrade fix..."
  lxc exec devops-template -- bash <<'CONTAINERDFIX' >> "$LOG_FILE" 2>&1
systemctl stop docker
apt-get install -y --allow-downgrades containerd.io=1.7.28-1~ubuntu.24.04~noble
apt-mark hold containerd.io
systemctl restart containerd
systemctl restart docker
CONTAINERDFIX

  # Install diagnostic tools
  log "  Installing diagnostic tools..."
  lxc exec devops-template -- apt-get install -y jq nmap tcpdump netcat-openbsd dnsutils net-tools iproute2 build-essential python3 python3-pip >> "$LOG_FILE" 2>&1

  # Install Java 21
  log "  Installing Java 21..."
  lxc exec devops-template -- apt-get install -y openjdk-21-jdk >> "$LOG_FILE" 2>&1

  # Install Node.js 20
  log "  Installing Node.js 20..."
  lxc exec devops-template -- bash <<'NODEINSTALL' >> "$LOG_FILE" 2>&1
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
NODEINSTALL

  # Create labuser
  log "  Creating labuser..."
  lxc exec devops-template -- bash <<'LABUSER' >> "$LOG_FILE" 2>&1
useradd -m -s /bin/bash -u 1000 labuser
usermod -aG docker labuser
echo "labuser:temppassword" | chpasswd
LABUSER

  # Install SSH server
  log "  Installing SSH server..."
  lxc exec devops-template -- bash <<'SSHINSTALL' >> "$LOG_FILE" 2>&1
apt-get install -y openssh-server
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/99-security.conf <<EOF
MaxAuthTries 3
LoginGraceTime 30
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
PermitEmptyPasswords no
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
systemctl enable ssh
SSHINSTALL

  # Setup sudo permissions
  log "  Configuring sudo permissions..."
  lxc exec devops-template -- bash <<'SUDOCONFIG' >> "$LOG_FILE" 2>&1
cat > /etc/sudoers.d/labuser-devops <<EOF
Defaults:labuser !requiretty
labuser ALL=(ALL) NOPASSWD: /usr/bin/lsof
labuser ALL=(ALL) NOPASSWD: /usr/bin/nmap
labuser ALL=(ALL) NOPASSWD: /usr/sbin/tcpdump
labuser ALL=(ALL) NOPASSWD: /bin/systemctl restart docker
labuser ALL=(ALL) NOPASSWD: /bin/systemctl status docker
labuser ALL=(ALL) NOPASSWD: /bin/ls /var/lib/docker/volumes/
labuser ALL=(ALL) NOPASSWD: /bin/ls /var/lib/docker/volumes/*
labuser ALL=(ALL) NOPASSWD: /usr/bin/du /var/lib/docker/containers/*
EOF
chmod 0440 /etc/sudoers.d/labuser-devops
chown root:root /etc/sudoers.d/labuser-devops
visudo -c -f /etc/sudoers.d/labuser-devops
SUDOCONFIG

  # Configure .bashrc
  log "  Configuring bash aliases..."
  lxc exec devops-template -- su - labuser -c 'cat >> /home/labuser/.bashrc' <<'BASHRC'

# Java Environment
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Docker Aliases
alias docker-stop-all="docker stop \$(docker ps -aq) 2>/dev/null || echo 'No containers running'"
alias check-resources="echo '=== RAM ===' && free -h && echo && echo '=== DISK ===' && df -h / && echo && echo '=== DOCKER ===' && docker ps -a && docker images"

# Lab Aliases
alias labs-reset="~/labs/labs-reset.sh"
alias lab1-setup="cd ~/labs/01-docker-lab && ./setup.sh"
BASHRC

  # Create labs directory
  log "  Creating labs directory..."
  lxc exec devops-template -- bash <<'LABSDIR' >> "$LOG_FILE" 2>&1
mkdir -p /home/labuser/labs
chown -R labuser:labuser /home/labuser/labs
cat > /home/labuser/README.md <<'READMEEOF'
# DevOps Laborikeskkond

Tere tulemast DevOps laborikeskkonda!

## Kiirstart

1. Kontrolli ressursse: check-resources
2. Loe labori juhendeid: cd ~/labs/
3. Alusta Lab 1'ga: cd ~/labs/01-docker-lab/

Edu!
READMEEOF
chown labuser:labuser /home/labuser/README.md
LABSDIR

  # Cleanup
  log "  Cleaning up..."
  lxc exec devops-template -- bash <<'CLEANUP' >> "$LOG_FILE" 2>&1
apt-get clean
apt-get autoremove -y
rm -rf /tmp/*
rm -rf /var/tmp/*
history -c
CLEANUP

  # Publish template
  log "  Publishing template..."
  lxc stop devops-template >> "$LOG_FILE" 2>&1
  lxc publish devops-template --alias devops-lab-base \
    description="DevOps Lab Template: Ubuntu 24.04 + Docker + containerd 1.7.28" >> "$LOG_FILE" 2>&1
  lxc delete devops-template >> "$LOG_FILE" 2>&1

  success "Template image created: devops-lab-base"
}

# Create student containers
create_students() {
  log "Creating student containers..."

  local listen_ip="0.0.0.0"
  if [ "$DEPLOYMENT_TYPE" = "laptop" ]; then
    listen_ip="127.0.0.1"
    info "Using localhost (127.0.0.1) for port forwarding"
  fi

  for i in $(seq 1 $NUM_STUDENTS); do
    local container_name="devops-student$i"
    local password="student$i"
    local ssh_port=$((SSH_PORT_START + i - 1))
    local web_port=$((WEB_PORT_START + (i - 1) * 100))
    local api1_port=$((API1_PORT_START + (i - 1) * 100))
    local api2_port=$((API2_PORT_START + (i - 1) * 100))

    log "  Creating $container_name..."

    # Launch container
    lxc launch devops-lab-base $container_name -p default -p devops-lab >> "$LOG_FILE" 2>&1
    sleep 5

    # Set password
    lxc exec $container_name -- bash -c "echo 'labuser:$password' | chpasswd" >> "$LOG_FILE" 2>&1

    # Add port forwarding
    lxc config device add $container_name ssh-proxy proxy \
      listen=tcp:${listen_ip}:${ssh_port} connect=tcp:127.0.0.1:22 nat=true >> "$LOG_FILE" 2>&1

    lxc config device add $container_name web-proxy proxy \
      listen=tcp:${listen_ip}:${web_port} connect=tcp:127.0.0.1:8080 nat=true >> "$LOG_FILE" 2>&1

    lxc config device add $container_name user-api-proxy proxy \
      listen=tcp:${listen_ip}:${api1_port} connect=tcp:127.0.0.1:3000 nat=true >> "$LOG_FILE" 2>&1

    lxc config device add $container_name todo-api-proxy proxy \
      listen=tcp:${listen_ip}:${api2_port} connect=tcp:127.0.0.1:8081 nat=true >> "$LOG_FILE" 2>&1

    success "  $container_name created (SSH: $ssh_port)"
  done

  success "All student containers created"
}

# Install Git repository
install_git_repo() {
  if [[ ! "$INSTALL_GIT_REPO" =~ ^[Yy]$ ]]; then
    info "Skipping Git repository installation"
    return
  fi

  log "Installing Git repository..."

  local git_dir="/home/$ADMIN_USER/projects/hostinger"

  # Clone as admin user
  su - "$ADMIN_USER" -c "
    mkdir -p ~/projects
    cd ~/projects
    if [ ! -d hostinger ]; then
      git clone $GIT_REPO_URL hostinger
    else
      cd hostinger && git pull
    fi
  " >> "$LOG_FILE" 2>&1

  if [ -d "$git_dir/labs" ]; then
    success "Git repository cloned"

    # Create sync scripts
    log "Creating sync scripts..."
    mkdir -p "/home/$ADMIN_USER/scripts"

    # sync-labs.sh
    cat > "/home/$ADMIN_USER/scripts/sync-labs.sh" <<'SYNCSCRIPT'
#!/bin/bash
set -e
CONTAINER="$1"
SOURCE_DIR="/home/USERNAME/projects/hostinger/labs"
if [ -z "$CONTAINER" ]; then
  echo "Usage: $0 <container-name>"
  exit 1
fi
echo "📦 Syncing labs to $CONTAINER..."
lxc exec $CONTAINER -- bash -c "tar czf /tmp/labs-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /home/labuser labs 2>/dev/null || true"
lxc file push -r "$SOURCE_DIR/" "$CONTAINER/home/labuser/"
lxc exec $CONTAINER -- chown -R labuser:labuser /home/labuser/labs
lxc exec $CONTAINER -- find /home/labuser/labs -type f -name '*.sh' -exec chmod 755 {} \;
echo "✅ $CONTAINER updated!"
SYNCSCRIPT

    sed -i "s/USERNAME/$ADMIN_USER/g" "/home/$ADMIN_USER/scripts/sync-labs.sh"
    chmod +x "/home/$ADMIN_USER/scripts/sync-labs.sh"

    # Sync to all containers
    log "Syncing labs to containers..."
    for i in $(seq 1 $NUM_STUDENTS); do
      bash "/home/$ADMIN_USER/scripts/sync-labs.sh" "devops-student$i" >> "$LOG_FILE" 2>&1
    done

    success "Labs synced to all containers"
  else
    warning "Labs directory not found in repository"
  fi
}

# Generate final report
generate_report() {
  local report_file="/home/$ADMIN_USER/devops-lab-install-report.txt"

  cat > "$report_file" <<EOF
╔════════════════════════════════════════════════════════════════╗
║       LXD DevOps Lab Installation Complete!                   ║
╚════════════════════════════════════════════════════════════════╝

Installation Date: $(date)
Deployment Type: $DEPLOYMENT_TYPE
Number of Students: $NUM_STUDENTS

STUDENT ACCESS INFORMATION
═══════════════════════════════════════════════════════════════

EOF

  local server_ip="<SERVER-IP>"
  if [ "$DEPLOYMENT_TYPE" = "laptop" ]; then
    server_ip="localhost"
  fi

  for i in $(seq 1 $NUM_STUDENTS); do
    local ssh_port=$((SSH_PORT_START + i - 1))
    local web_port=$((WEB_PORT_START + (i - 1) * 100))
    local api1_port=$((API1_PORT_START + (i - 1) * 100))
    local api2_port=$((API2_PORT_START + (i - 1) * 100))

    cat >> "$report_file" <<EOF
Student $i (devops-student$i)
─────────────────────────────────────────────────────────────
SSH Access:
  ssh labuser@${server_ip} -p ${ssh_port}
  Password: student$i

Web Services (when running):
  Frontend:       http://${server_ip}:${web_port}
  User API:       http://${server_ip}:${api1_port}/api
  Todo API:       http://${server_ip}:${api2_port}/api

EOF
  done

  cat >> "$report_file" <<EOF

NEXT STEPS
═══════════════════════════════════════════════════════════════

1. Test SSH Access:
   ssh labuser@${server_ip} -p ${SSH_PORT_START}
   (Password: student1)

2. Test Docker:
   docker run --rm hello-world

3. View Resources:
   lxc list -c ns4M

4. Read Documentation:
   - INSTALLATION.md - Full installation guide
   - ADMIN-GUIDE.md - Container management
   - TESTING-GUIDE.md - Testing procedures

5. Backup Template:
   lxc image export devops-lab-base ~/devops-lab-base-backup.tar.gz

IMPORTANT SECURITY NOTES
═══════════════════════════════════════════════════════════════

⚠️  Change default passwords (student1, student2, etc.)
⚠️  Review UFW firewall rules
⚠️  Enable fail2ban monitoring
⚠️  Setup regular backups

FILES CREATED
═══════════════════════════════════════════════════════════════

- Installation log: $LOG_FILE
- This report: $report_file
- Sync scripts: /home/$ADMIN_USER/scripts/

SUPPORT
═══════════════════════════════════════════════════════════════

Documentation: /home/$ADMIN_USER/projects/hostinger/infra/
LXD Docs: https://documentation.ubuntu.com/lxd/
Docker Docs: https://docs.docker.com/

═══════════════════════════════════════════════════════════════

Installation completed successfully! 🎉

EOF

  chown "$ADMIN_USER:$ADMIN_USER" "$report_file"

  success "Installation complete!"
  echo ""
  cat "$report_file"
  echo ""
  info "Full report saved to: $report_file"
  info "Installation log: $LOG_FILE"
}

# Main installation flow
main() {
  show_banner
  check_prerequisites
  interactive_config

  echo ""
  log "Starting installation..."
  echo ""

  system_update
  setup_swap
  install_lxd
  initialize_lxd
  setup_ufw
  setup_fail2ban
  create_lab_profile
  create_template
  create_students
  install_git_repo

  generate_report
}

# Run main
main "$@"
