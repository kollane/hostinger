#!/bin/bash

# Lab 1 Reset Script
# Puhastab kõik Lab 1 ressursid ja taastab algseis
# Katab MÕLEMAD teenused: User Service (Node.js) ja Todo Service (Java)

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
echo "  - Containerid: user-service*, todo-service*, postgres-user, postgres-todo"
echo "  - Image'd: user-service:*, todo-service:*"
echo "  - Network'id: todo-network"
echo "  - Volume'd: postgres-user-data, postgres-todo-data"
echo "  - Apps failid: Dockerfile, Dockerfile.optimized, .dockerignore"
echo ""
read -p "Kas oled kindel, et soovid jätkata? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Tühistatud."
    exit 0
fi
echo ""

echo -e "${YELLOW}📦 Peatame ja eemaldame Lab 1 containerid...${NC}"

# Eemalda User Service containerid (Harjutus 1a, 3, 5)
for container in user-service user-service-opt user-service-test; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container"
        echo -e "${GREEN}  ✓ $container container eemaldatud${NC}"
    fi
done

# Eemalda Todo Service containerid (Harjutus 1b, 3, 5)
for container in todo-service todo-service-opt todo-service-test; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container"
        echo -e "${GREEN}  ✓ $container container eemaldatud${NC}"
    fi
done

# Eemalda PostgreSQL containerid (Harjutus 2, 3, 4)
for container in postgres-user postgres-todo; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container"
        echo -e "${GREEN}  ✓ $container container eemaldatud${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🗑️  Eemaldame Lab 1 Docker image'd...${NC}"

# Eemalda user-service image'd (Harjutus 1a, 5)
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:'; then
    docker rmi -f $(docker images --format '{{.Repository}}:{{.Tag}}' | grep '^user-service:') 2>/dev/null
    echo -e "${GREEN}  ✓ user-service image'd eemaldatud${NC}"
fi

# Eemalda todo-service image'd (Harjutus 1b, 5)
if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:'; then
    docker rmi -f $(docker images --format '{{.Repository}}:{{.Tag}}' | grep '^todo-service:') 2>/dev/null
    echo -e "${GREEN}  ✓ todo-service image'd eemaldatud${NC}"
fi

echo ""
echo -e "${YELLOW}🔌 Eemaldame Lab 1 network'id...${NC}"

# Eemalda todo-network (Harjutus 3)
if docker network ls --format '{{.Name}}' | grep -q "^todo-network$"; then
    docker network rm "todo-network" 2>/dev/null
    echo -e "${GREEN}  ✓ todo-network eemaldatud${NC}"
fi

echo ""
echo -e "${YELLOW}💾 Eemaldame Lab 1 volume'd...${NC}"

# Eemalda PostgreSQL volume'd (Harjutus 4)
for volume in postgres-user-data postgres-todo-data; do
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
echo -e "${YELLOW}🗂️  Eemaldame harjutuste failid apps kaustadest...${NC}"

# Eemalda Dockerfile'id ja .dockerignore MÕLEMAST apps kaustast
for APP_DIR in "../apps/backend-nodejs" "../apps/backend-java-spring"; do
    if [ -d "$APP_DIR" ]; then
        APP_NAME=$(basename "$APP_DIR")
        FILES_REMOVED=0

        for file in Dockerfile Dockerfile.optimized .dockerignore healthcheck.js; do
            if [ -f "$APP_DIR/$file" ]; then
                rm -f "$APP_DIR/$file"
                echo -e "${GREEN}  ✓ $file eemaldatud $APP_NAME/ kaustast${NC}"
                FILES_REMOVED=1
            fi
        done

        if [ $FILES_REMOVED -eq 0 ]; then
            echo -e "${GREEN}  ✓ $APP_NAME kaust on juba puhas${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠ $APP_DIR kausta ei leitud${NC}"
    fi
done

echo ""
echo -e "${GREEN}✅ Lab 1 süsteem on taastatud!${NC}"
echo ""
echo "📚 Harjutuste ülevaade:"
echo "  1. Harjutus 1a: Single Container (User Service - Node.js)"
echo "  2. Harjutus 1b: Single Container (Todo Service - Java)"
echo "  3. Harjutus 2: Multi-Container (PostgreSQL + Backend)"
echo "  4. Harjutus 3: Networking (Custom Bridge Network)"
echo "  5. Harjutus 4: Volumes (Data Persistence)"
echo "  6. Harjutus 5: Optimization (Multi-stage Builds)"
echo ""
echo "Alusta harjutustega:"
echo "  cd exercises/"
echo "  cat 01-single-container-user_service.md"
echo ""
echo "======================================"
