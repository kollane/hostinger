#!/bin/bash

# Lab 1 Reset Script
# Puhastab kõik Lab 1 ressursid ja taastab algseis

echo "======================================"
echo "Lab 1 (Docker) - Süsteemi Taastamine"
echo "======================================"
echo ""

# Värvilised väljundid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kontrolli, kas Docker töötab
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker ei tööta! Palun käivita Docker esmalt.${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  HOIATUS: See kustutab KÕIK Lab 1 ressursid:${NC}"
echo "  - Containerid: todo-service*, postgres-todo*"
echo "  - Image'd: todo-service:*"
echo "  - Network'id: todo-network, app-network"
echo "  - Volume'd: postgres-*-data"
echo ""
read -p "Kas oled kindel, et soovid jätkata? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Tühistatud."
    exit 0
fi
echo ""

echo -e "${YELLOW}📦 Peatame ja eemaldame Lab 1 containerid...${NC}"

# Eemalda Todo Service containerid
for container in todo-service todo-service-opt todo-service-test; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container"
        echo -e "${GREEN}  ✓ $container container eemaldatud${NC}"
    fi
done

# Eemalda PostgreSQL containerid (mitu võimalikku nime)
for container in postgres-todo postgres todo-postgres; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container"
        echo -e "${GREEN}  ✓ $container container eemaldatud${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🗑️  Eemaldame Lab 1 Docker image'd...${NC}"

# Eemalda todo-service image'd
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:'; then
    docker rmi -f $(docker images --format '{{.Repository}}:{{.Tag}}' | grep '^todo-service:') 2>/dev/null
    echo -e "${GREEN}  ✓ todo-service image'd eemaldatud${NC}"
fi

echo ""
echo -e "${YELLOW}🔌 Eemaldame Lab 1 network'id...${NC}"

# Eemalda todo-network ja app-network
for network in todo-network app-network; do
    if docker network ls --format '{{.Name}}' | grep -q "^${network}$"; then
        docker network rm "$network" 2>/dev/null
        echo -e "${GREEN}  ✓ $network eemaldatud${NC}"
    fi
done

echo ""
echo -e "${YELLOW}💾 Eemaldame Lab 1 volume'd...${NC}"

# Eemalda PostgreSQL volume'd
for volume in postgres-todos-data postgres-todo-data todo-postgres-data postgres-data; do
    if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
        docker volume rm "$volume" 2>/dev/null
        echo -e "${GREEN}  ✓ $volume volume eemaldatud${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🧹 Puhastame kasutamata ressursse...${NC}"

# Puhasta kõik kasutamata ressursid
docker system prune -f > /dev/null 2>&1
echo -e "${GREEN}  ✓ Kasutamata ressursid eemaldatud${NC}"

echo ""
echo -e "${YELLOW}🗂️  Eemaldame harjutuste failid apps kaustast...${NC}"

# Eemalda Dockerfile'id ja .dockerignore apps/backend-java-spring kaustast
APP_DIR="../apps/backend-java-spring"
if [ -d "$APP_DIR" ]; then
    for file in Dockerfile Dockerfile.optimized .dockerignore; do
        if [ -f "$APP_DIR/$file" ]; then
            rm -f "$APP_DIR/$file"
            echo -e "${GREEN}  ✓ $file eemaldatud apps/backend-java-spring/ kaustast${NC}"
        fi
    done
else
    echo -e "${YELLOW}  ⚠ $APP_DIR kausta ei leitud${NC}"
fi

echo ""
echo -e "${GREEN}✅ Lab 1 süsteem on taastatud!${NC}"
echo ""
echo "Saad nüüd alustada Lab 1 harjutustega algusest:"
echo "  1. cd apps/backend-java-spring"
echo "  2. Jätka 01-docker-lab/exercises/01-single-container.md juhiste järgi"
echo ""
echo "======================================"
