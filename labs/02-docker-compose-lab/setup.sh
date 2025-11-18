#!/bin/bash

# Labor 2: Docker Compose - Automaatne Setup Script
# Kontrollib eeldusi ja build'ib Lab 1 image'd kui vaja

set -e  # Exit on error

echo "========================================="
echo "  Labor 2: Docker Compose - Setup"
echo "========================================="
echo ""

# Colors
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

# 1. Check Docker
echo "1️⃣  Kontrollin Docker'i..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker pole paigaldatud!${NC}"
    echo "Paigalda Docker ja käivita Lab 1 setup esmalt."
    exit 1
fi
echo -e "${GREEN}✅ Docker on paigaldatud${NC}"
echo ""

# 2. Check Docker Compose
echo "2️⃣  Kontrollin Docker Compose..."
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short)
    echo -e "${GREEN}✅ Docker Compose on paigaldatud (versioon: $COMPOSE_VERSION)${NC}"
else
    echo -e "${RED}❌ Docker Compose pole paigaldatud!${NC}"
    echo ""
    echo "Paigalda Docker Compose:"
    echo "  sudo apt update"
    echo "  sudo apt install docker-compose-plugin"
    exit 1
fi
echo ""

# 3. Check Lab 1 image (todo-service)
echo "3️⃣  Kontrollin Lab 1 image'i (todo-service)..."
if ! docker images | grep -q "todo-service.*1.0"; then
    echo -e "${RED}❌ todo-service:1.0 puudub!${NC}"
    echo ""
    echo "Todo Service on Lab 1 KOHUSTUSLIK tulemus!"
    echo "Build'i see esmalt:"
    echo "  cd ../apps/backend-java-spring"
    echo "  docker build -t todo-service:1.0 ."
    exit 1
fi
echo -e "${GREEN}✅ todo-service:1.0 on olemas (Lab 1'st)${NC}"
echo ""

# 4. Check Lab 2 additional images
echo "4️⃣  Kontrollin Lab 2 täiendavaid image'e..."
MISSING_IMAGES=()

if ! docker images | grep -q "user-service.*1.0"; then
    MISSING_IMAGES+=("user-service:1.0")
fi

if ! docker images | grep -q "frontend.*1.0"; then
    MISSING_IMAGES+=("frontend:1.0")
fi

if [ ${#MISSING_IMAGES[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ Kõik vajalikud image'd on olemas:${NC}"
    docker images | grep -E "user-service|frontend" | head -2
else
    warn "Puuduvad image'd: ${MISSING_IMAGES[*]}"
    echo ""

    # Ask user if they want to build missing images
    read -p "Kas soovid puuduvaid image'e automaatselt build'ida? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        info "Build'in puuduvaid image'e..."
        echo ""

        # Build user-service if missing
        if [[ " ${MISSING_IMAGES[@]} " =~ "user-service:1.0" ]]; then
            echo "📦 Build'in user-service:1.0..."
            cd ../apps/backend-nodejs
            if docker build -t user-service:1.0 .; then
                echo -e "${GREEN}✅ user-service:1.0 build õnnestus${NC}"
            else
                echo -e "${RED}❌ user-service:1.0 build ebaõnnestus${NC}"
                exit 1
            fi
            cd - > /dev/null
            echo ""
        fi

        # Build frontend if missing
        if [[ " ${MISSING_IMAGES[@]} " =~ "frontend:1.0" ]]; then
            echo "📦 Build'in frontend:1.0..."
            cd ../apps/frontend
            if docker build -t frontend:1.0 .; then
                echo -e "${GREEN}✅ frontend:1.0 build õnnestus${NC}"
            else
                echo -e "${RED}❌ frontend:1.0 build ebaõnnestus${NC}"
                exit 1
            fi
            cd - > /dev/null
            echo ""
        fi

        echo -e "${GREEN}✅ Kõik image'd on nüüd olemas${NC}"
    else
        echo ""
        echo -e "${YELLOW}Build'i image'd käsitsi:${NC}"
        echo ""
        echo "# User Service"
        echo "cd ../apps/backend-nodejs"
        echo "docker build -t user-service:1.0 ."
        echo ""
        echo "# Frontend"
        echo "cd ../apps/frontend"
        echo "docker build -t frontend:1.0 ."
        exit 1
    fi
fi
echo ""

# 5. Check exercises directory
echo "5️⃣  Kontrollin harjutusi..."
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
echo "Kõik kolm teenust on valmis Lab 2 jaoks!"
echo ""
echo "Olemasolevad Docker image'd:"
docker images | grep -E "REPOSITORY|todo-service|user-service|frontend"
echo ""
echo "Järgmised sammud:"
echo "  1. Alusta harjutus 1'st (Basic Compose):"
echo "     cat exercises/01-basic-compose.md"
echo ""
echo "  2. Või vaata näidis docker-compose.yml:"
echo "     cat solutions/docker-compose.yml"
echo ""
echo "Lab 2 lõpuks on sul valmis täielik mikroteenuste süsteem!"
echo "Edu laboriga! 🚀"
