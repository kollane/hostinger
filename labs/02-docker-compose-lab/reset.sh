#!/bin/bash

# Lab 2 Reset Script
# Puhastab kõik Lab 2 (Docker Compose) ressursid ja taastab algseis

echo "=============================================="
echo "Lab 2 (Docker Compose) - Süsteemi Taastamine"
echo "=============================================="
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

# Kontrolli, kas docker compose on saadaval
if ! docker compose version > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker Compose ei ole saadaval!${NC}"
    exit 1
fi

echo -e "${YELLOW}🛑 Peatame kõik Docker Compose rakendused...${NC}"

# Peata ja eemalda compose ressursid solutions kaustast
if [ -d "02-docker-compose-lab/solutions" ]; then
    cd 02-docker-compose-lab/solutions

    for compose_dir in */; do
        if [ -f "${compose_dir}docker-compose.yml" ]; then
            echo -e "${YELLOW}  Peatame ${compose_dir}...${NC}"
            (cd "$compose_dir" && docker compose down -v 2>/dev/null)
        fi
    done

    # Tagasi peakausta
    cd ../..
fi

# Kui kasutaja on ise compose faile loonud
for compose_file in docker-compose.yml docker-compose.*.yml; do
    if [ -f "$compose_file" ]; then
        echo -e "${YELLOW}  Peatame $compose_file...${NC}"
        docker compose -f "$compose_file" down -v 2>/dev/null
    fi
done

echo ""
echo -e "${YELLOW}📦 Eemaldame Lab 2 containerid...${NC}"

# Eemalda compose containerid (kasutavad tavaliselt prefixeid)
for prefix in 02-docker-compose fullstack-app backend frontend todos userservice; do
    containers=$(docker ps -a --format '{{.Names}}' | grep "^${prefix}" || true)
    if [ ! -z "$containers" ]; then
        echo "$containers" | xargs -r docker rm -f 2>/dev/null
        echo -e "${GREEN}  ✓ ${prefix}* containerid eemaldatud${NC}"
    fi
done

# Eemalda ka üksikud containerid, mis võivad olla
for container in postgres user-service frontend todo-service; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container" 2>/dev/null
        echo -e "${GREEN}  ✓ $container eemaldatud${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🗑️  Eemaldame Lab 2 Docker image'd...${NC}"

# Eemalda user-service, frontend, todo-service image'd
for image_prefix in user-service frontend todo-service fullstack; do
    images=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep "^${image_prefix}" || true)
    if [ ! -z "$images" ]; then
        echo "$images" | xargs -r docker rmi -f 2>/dev/null
        echo -e "${GREEN}  ✓ ${image_prefix}* image'd eemaldatud${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🔌 Eemaldame Lab 2 network'id...${NC}"

# Eemalda compose network'id
for network in app-network fullstack-network backend-network frontend-network; do
    if docker network ls --format '{{.Name}}' | grep -q "^${network}$"; then
        docker network rm "$network" 2>/dev/null
        echo -e "${GREEN}  ✓ $network eemaldatud${NC}"
    fi
done

# Eemalda compose projektide network'id (tavaliselt algavad projekti nimega)
for prefix in 02-docker-compose fullstack; do
    networks=$(docker network ls --format '{{.Name}}' | grep "^${prefix}" || true)
    if [ ! -z "$networks" ]; then
        echo "$networks" | xargs -r docker network rm 2>/dev/null
        echo -e "${GREEN}  ✓ ${prefix}* network'id eemaldatud${NC}"
    fi
done

echo ""
echo -e "${YELLOW}💾 Eemaldame Lab 2 volume'd...${NC}"

# Eemalda named volume'd
for volume in postgres-data postgres-users-data postgres-todos-data db-data; do
    if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
        docker volume rm "$volume" 2>/dev/null
        echo -e "${GREEN}  ✓ $volume eemaldatud${NC}"
    fi
done

# Eemalda compose volume'd (tavaliselt projekti nimega)
for prefix in 02-docker-compose fullstack; do
    volumes=$(docker volume ls --format '{{.Name}}' | grep "^${prefix}" || true)
    if [ ! -z "$volumes" ]; then
        echo "$volumes" | xargs -r docker volume rm 2>/dev/null
        echo -e "${GREEN}  ✓ ${prefix}* volume'd eemaldatud${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🧹 Puhastame kasutamata ressursse...${NC}"

docker system prune -f > /dev/null 2>&1
echo -e "${GREEN}  ✓ Kasutamata ressursid eemaldatud${NC}"

echo ""
echo -e "${GREEN}✅ Lab 2 süsteem on taastatud!${NC}"
echo ""
echo "Saad nüüd alustada Lab 2 harjutustega algusest:"
echo "  1. cd 02-docker-compose-lab"
echo "  2. Jätka exercises/ kaustas olevate harjutustega"
echo ""
echo "=============================================="
