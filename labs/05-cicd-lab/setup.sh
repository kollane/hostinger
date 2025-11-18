#!/bin/bash

# Labor 5: CI/CD Pipeline - Automaatne Setup Script

set -e

echo "========================================="
echo "  Labor 5: CI/CD Pipeline - Setup"
echo "========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. Check Git
echo "1️⃣  Kontrollin Git'i..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo -e "${GREEN}✅ Git on paigaldatud (versioon: $GIT_VERSION)${NC}"
else
    echo -e "${RED}❌ Git pole paigaldatud!${NC}"
    echo "Paigalda Git: sudo apt install git"
    exit 1
fi
echo ""

# 2. Check kubectl
echo "2️⃣  Kontrollin kubectl..."
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✅ kubectl on paigaldatud${NC}"
else
    echo -e "${RED}❌ kubectl pole paigaldatud!${NC}"
    echo "Käivita Lab 3 setup esmalt."
    exit 1
fi
echo ""

# 3. Check Kubernetes cluster
echo "3️⃣  Kontrollin Kubernetes cluster'i..."
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ Cluster on kättesaadav${NC}"
else
    warn "Cluster pole kättesaadav (vajalik harjutus 3 jaoks)"
    echo "Käivita Lab 3 setup: cd ../03-kubernetes-basics-lab && ./setup.sh"
fi
echo ""

# 4. Check Lab 1 Dockerfile
echo "4️⃣  Kontrollin Lab 1 Dockerfile'i..."
if [ -f "../apps/backend-nodejs/Dockerfile" ]; then
    echo -e "${GREEN}✅ Dockerfile on olemas${NC}"
else
    echo -e "${RED}❌ Dockerfile puudub!${NC}"
    echo "Tee Lab 1 harjutused esmalt."
    exit 1
fi
echo ""

# 5. Check Lab 3 manifests (optional)
echo "5️⃣  Kontrollin Lab 3 Kubernetes manifeste..."
if [ -d "../03-kubernetes-basics-lab/manifests" ] || [ -d "../03-kubernetes-basics-lab/solutions" ]; then
    echo -e "${GREEN}✅ K8s manifests on kättesaadavad${NC}"
else
    warn "K8s manifests puuduvad (vajalik harjutus 3 jaoks)"
fi
echo ""

# 6. GitHub/GitLab instructions
echo "6️⃣  GitHub/GitLab setup..."
info "CI/CD jaoks vajad:"
echo "  - GitHub konto: https://github.com/signup"
echo "  - Või GitLab konto: https://gitlab.com/users/sign_up"
echo "  - Docker Hub konto: https://hub.docker.com/signup"
echo ""
warn "Need tuleb käsitsi seadistada labori käigus"
echo ""

# 7. Create sample repo structure (optional)
echo "7️⃣  Näidis repo struktuur..."
read -p "Kas soovid luua näidis repo struktuuri? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p sample-repo/.github/workflows
    mkdir -p sample-repo/k8s

    # Copy Dockerfile
    cp ../apps/backend-nodejs/Dockerfile sample-repo/ 2>/dev/null || true

    # Create sample workflow
    cat > sample-repo/.github/workflows/ci.yml << 'EOF'
name: CI Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker image
        run: docker build -t user-service:latest .
EOF

    echo -e "${GREEN}✅ Näidis repo struktuur loodud: sample-repo/${NC}"
    echo "Näidis failid:"
    tree sample-repo 2>/dev/null || find sample-repo -type f
fi
echo ""

# Summary
echo "========================================="
echo "  ✅ Setup Valmis!"
echo "========================================="
echo ""
echo "Eeldused on kontrollitud!"
echo ""
echo "JÄRGMISED SAMMUD (käsitsi):"
echo ""
echo "  1. Loo GitHub konto ja repository"
echo "  2. Loo Docker Hub konto"
echo "  3. Alusta harjutus 1'st:"
echo "     cat exercises/01-github-actions-basics.md"
echo ""
echo "Edu laboriga! 🚀"
