#!/bin/bash

# Labor 1: Docker Põhitõed - Automaatne Setup Script
# Kontrollib ja seadistab kõik eeldused

set -e  # Exit on error

echo "========================================="
echo "  Labor 1: Docker Põhitõed - Setup"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check function
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        exit 1
    fi
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 1. Check Docker installation
echo "1️⃣  Kontrollin Docker'i paigaldust..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "${GREEN}✅ Docker on paigaldatud (versioon: $DOCKER_VERSION)${NC}"
else
    echo -e "${RED}❌ Docker pole paigaldatud!${NC}"
    echo ""
    echo "Paigalda Docker järgmiste käskudega:"
    echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "  sudo sh get-docker.sh"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    exit 1
fi
echo ""

# 2. Check Docker daemon
echo "2️⃣  Kontrollin Docker daemon'i..."
if docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Docker daemon töötab${NC}"
else
    echo -e "${RED}❌ Docker daemon ei tööta!${NC}"
    echo ""
    echo "Käivita Docker daemon:"
    echo "  sudo systemctl start docker"
    echo "  sudo systemctl enable docker"
    exit 1
fi
echo ""

# 3. Check Docker permissions
echo "3️⃣  Kontrollin Docker õigusi..."
if docker ps &> /dev/null; then
    echo -e "${GREEN}✅ Docker töötab ilma sudo'ta${NC}"
else
    warn "Docker vajab sudo õigusi"
    echo "Lisa ennast docker gruppi:"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
fi
echo ""

# 4. Check disk space
echo "4️⃣  Kontrollin vaba kettaruumi..."
AVAILABLE_SPACE=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -ge 4 ]; then
    echo -e "${GREEN}✅ Vaba kettaruum: ${AVAILABLE_SPACE}GB (piisav)${NC}"
else
    warn "Vaba kettaruum: ${AVAILABLE_SPACE}GB (soovitatud vähemalt 4GB)"
fi
echo ""

# 5. Check RAM
echo "5️⃣  Kontrollin vaba RAM-i..."
AVAILABLE_RAM=$(free -g | awk 'NR==2 {print $7}')
if [ "$AVAILABLE_RAM" -ge 2 ]; then
    echo -e "${GREEN}✅ Vaba RAM: ${AVAILABLE_RAM}GB${NC}"
else
    warn "Vaba RAM: ${AVAILABLE_RAM}GB (soovitatud vähemalt 2GB)"
fi
echo ""

# 6. Test Docker with hello-world
echo "6️⃣  Testin Docker'i (hello-world)..."
if docker run --rm hello-world &> /dev/null; then
    echo -e "${GREEN}✅ Docker test õnnestus${NC}"
else
    echo -e "${RED}❌ Docker test ebaõnnestus${NC}"
    exit 1
fi
echo ""

# 7. Check apps directory
echo "7️⃣  Kontrollin rakenduste kättesaadavust..."
if [ -d "../apps/backend-nodejs" ] && [ -d "../apps/frontend" ]; then
    echo -e "${GREEN}✅ Rakendused on kättesaadavad:${NC}"
    echo "   - ../apps/backend-nodejs/"
    echo "   - ../apps/frontend/"
else
    echo -e "${RED}❌ Rakendused pole kättesaadavad!${NC}"
    echo "Kontrolli, et oled õiges kataloogis:"
    echo "  cd /home/janek/projects/hostinger/labs/01-docker-lab"
    exit 1
fi
echo ""

# 8. Check exercises directory
echo "8️⃣  Kontrollin harjutuste kättesaadavust..."
if [ -d "exercises" ]; then
    EXERCISE_COUNT=$(ls exercises/*.md 2>/dev/null | wc -l)
    echo -e "${GREEN}✅ Harjutused on kättesaadavad ($EXERCISE_COUNT harjutust)${NC}"
else
    warn "Harjutuste kaust puudub (luuakse hiljem)"
fi
echo ""

# Summary
echo "========================================="
echo "  ✅ Setup Valmis!"
echo "========================================="
echo ""
echo "Kõik eeldused on täidetud! Võid alustada laboriga."
echo ""
echo "Järgmised sammud:"
echo "  1. Alusta harjutus 1'st:"
echo "     cat exercises/01-single-container.md"
echo ""
echo "  2. Või vaata kõiki harjutusi:"
echo "     ls exercises/"
echo ""
echo "Edu laboriga! 🚀"
