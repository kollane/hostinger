#!/bin/bash

# Lab 1 Multi-User Reset Script
# Puhastab AINULT SINU kasutaja Lab 1 ressursid (user-safe!)
# Katab MÕLEMAD teenused (services): User Teenus (Service) (Node.js) ja Todo Teenus (Service) (Java)

echo "======================================"
echo "Lab 1 (Docker) - Multi-User Reset"
echo "======================================"
echo ""

# Värvilised väljundid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Kontrolli, kas multi-user environment on seadistatud
if [ ! -f ~/.env-lab ]; then
    echo -e "${RED}❌ Multi-user keskkond pole seadistatud!${NC}"
    echo ""
    echo "See skript vajab multi-user keskkonda."
    echo "Palun käivita esmalt:"
    echo "  source labs/multi-user-setup.sh"
    echo ""
    echo "Single-user keskkonna jaoks kasuta:"
    echo "  bash reset.sh"
    exit 1
fi

# Lae multi-user keskkonna muutujad
source ~/.env-lab

echo -e "${BLUE}Multi-User Reset${NC}"
echo ""
echo -e "${GREEN}Kasutaja: ${YELLOW}${USER_PREFIX}${NC}"
echo -e "${GREEN}Pordid: ${YELLOW}PostgreSQL ${POSTGRES_PORT}, Backend ${BACKEND_PORT}, Frontend ${FRONTEND_PORT}${NC}"
echo ""

# Kontrolli, kas Docker töötab
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker ei tööta! Palun käivita Docker esmalt.${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  HOIATUS: See kustutab SINU (${USER_PREFIX}) Lab 1 ressursid:${NC}"
echo "  - Konteinerid: ${USER_PREFIX}-user-service*, ${USER_PREFIX}-todo-service*, ${USER_PREFIX}-postgres-*"
echo "  - Pildid (images): ${USER_PREFIX}-user-service:*, ${USER_PREFIX}-todo-service:*"
echo "  - Võrgud (networks): ${USER_PREFIX}-todo-network"
echo "  - Andmehoidlad (volumes): ${USER_PREFIX}_postgres-*-data"
echo "  - Apps failid: Dockerfile, Dockerfile.optimized, .dockerignore"
echo ""
echo -e "${GREEN}✅ TEISED KASUTAJAD ei ole mõjutatud (nende ressursid jäävad alles)${NC}"
echo ""
read -p "Kas oled kindel, et soovid jätkata? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Tühistatud."
    exit 0
fi
echo ""

# Küsi, kas kustutada ka Docker pildid (images)
echo -e "${YELLOW}📦 Docker Piltide (Images) Kustutamine${NC}"
echo ""
echo "Kas soovid kustutada ka Docker pildid (images)?"
echo "  [N] Ei, jäta baaspildid (base images) alles (${USER_PREFIX}-user-service:1.0, ${USER_PREFIX}-todo-service:1.0)"
echo "      → Saad alustada otse Harjutus 2'st ilma uuesti ehitamata (build)"
echo "  [Y] Jah, kustuta KÕIK pildid (images) (täielik reset)"
echo "      → Pead alustama Harjutus 1'st ja ehitama (build) pildid (images) uuesti"
echo ""
read -p "Vali [N/y]: " -n 1 -r DELETE_IMAGES
echo ""

# Vaikimisi on N (kui kasutaja vajutab lihtsalt Enter või midagi muud kui Y/y)
if [[ ! $DELETE_IMAGES =~ ^[Yy]$ ]]; then
    DELETE_IMAGES="n"
fi
echo ""

echo -e "${YELLOW}📦 Peatame ja eemaldame SINU (${USER_PREFIX}) konteinerid...${NC}"

# Eemalda User Teenuse (Service) konteinerid (Harjutus 1a, 3, 5)
CONTAINERS_REMOVED=0
for container in ${USER_PREFIX}-user-service ${USER_PREFIX}-user-service-opt ${USER_PREFIX}-user-service-test; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container" 2>/dev/null
        echo -e "${GREEN}  ✓ $container konteiner eemaldatud${NC}"
        CONTAINERS_REMOVED=1
    fi
done

# Eemalda Todo Teenuse (Service) konteinerid (Harjutus 1b, 3, 5)
for container in ${USER_PREFIX}-todo-service ${USER_PREFIX}-todo-service-opt ${USER_PREFIX}-todo-service-test; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container" 2>/dev/null
        echo -e "${GREEN}  ✓ $container konteiner eemaldatud${NC}"
        CONTAINERS_REMOVED=1
    fi
done

# Eemalda PostgreSQL konteinerid (Harjutus 2, 3, 4)
for container in ${USER_PREFIX}-postgres-user ${USER_PREFIX}-postgres-todo; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container" 2>/dev/null
        echo -e "${GREEN}  ✓ $container konteiner eemaldatud${NC}"
        CONTAINERS_REMOVED=1
    fi
done

# Eemalda Compose-created konteinerid (kui dc-up kasutatud)
# Compose creates containers with format: <project>-<service>-<number>
for pattern in "${USER_PREFIX}-postgres-1" "${USER_PREFIX}-backend-1" "${USER_PREFIX}-frontend-1" \
               "${USER_PREFIX}_postgres_1" "${USER_PREFIX}_backend_1" "${USER_PREFIX}_frontend_1"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${pattern}$"; then
        docker rm -f "$pattern" 2>/dev/null
        echo -e "${GREEN}  ✓ $pattern konteiner eemaldatud${NC}"
        CONTAINERS_REMOVED=1
    fi
done

if [ $CONTAINERS_REMOVED -eq 0 ]; then
    echo -e "${GREEN}  ✓ Konteinereid ei leitud (juba puhas)${NC}"
fi

echo ""
echo -e "${YELLOW}🗑️  Eemaldame SINU (${USER_PREFIX}) Docker pildid (images)...${NC}"

IMAGES_REMOVED=0
if [[ $DELETE_IMAGES =~ ^[Yy]$ ]]; then
    # Täielik reset - kustuta KÕIK sinu pildid (images)
    # Eemalda user-service pildid (images) (Harjutus 1a, 5)
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${USER_PREFIX}-user-service:"; then
        docker rmi -f $(docker images --format '{{.Repository}}:{{.Tag}}' | grep "^${USER_PREFIX}-user-service:") 2>/dev/null
        echo -e "${GREEN}  ✓ Kõik ${USER_PREFIX}-user-service pildid (images) eemaldatud${NC}"
        IMAGES_REMOVED=1
    fi

    # Eemalda todo-service pildid (images) (Harjutus 1b, 5)
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${USER_PREFIX}-todo-service:"; then
        docker rmi -f $(docker images --format '{{.Repository}}:{{.Tag}}' | grep "^${USER_PREFIX}-todo-service:") 2>/dev/null
        echo -e "${GREEN}  ✓ Kõik ${USER_PREFIX}-todo-service pildid (images) eemaldatud${NC}"
        IMAGES_REMOVED=1
    fi
else
    # Osaline reset - kustuta AINULT optimeeritud pildid (images), säilita baaspildid (base images)
    # Eemalda user-service optimeeritud pilt (image) (Harjutus 5)
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${USER_PREFIX}-user-service:1.0-optimized$"; then
        docker rmi -f ${USER_PREFIX}-user-service:1.0-optimized 2>/dev/null
        echo -e "${GREEN}  ✓ ${USER_PREFIX}-user-service:1.0-optimized eemaldatud${NC}"
        IMAGES_REMOVED=1
    fi

    # Eemalda todo-service optimeeritud pilt (image) (Harjutus 5)
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${USER_PREFIX}-todo-service:1.0-optimized$"; then
        docker rmi -f ${USER_PREFIX}-todo-service:1.0-optimized 2>/dev/null
        echo -e "${GREEN}  ✓ ${USER_PREFIX}-todo-service:1.0-optimized eemaldatud${NC}"
        IMAGES_REMOVED=1
    fi

    # Kontrolli, kas baaspildid (base images) on olemas
    BASE_IMAGES_EXIST=0
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${USER_PREFIX}-user-service:1.0$"; then
        echo -e "${YELLOW}  ℹ  ${USER_PREFIX}-user-service:1.0 säilitatud (Harjutuste 2-5 jaoks)${NC}"
        BASE_IMAGES_EXIST=1
    fi
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${USER_PREFIX}-todo-service:1.0$"; then
        echo -e "${YELLOW}  ℹ  ${USER_PREFIX}-todo-service:1.0 säilitatud (Harjutuste 2-5 jaoks)${NC}"
        BASE_IMAGES_EXIST=1
    fi

    if [ $BASE_IMAGES_EXIST -eq 0 ]; then
        echo -e "${YELLOW}  ℹ  Baaspildid (base images) ei leitud (pead looma Harjutus 1'es)${NC}"
    fi
fi

if [ $IMAGES_REMOVED -eq 0 ]; then
    echo -e "${GREEN}  ✓ Pilte ei leitud (juba puhas)${NC}"
fi

echo ""
echo -e "${YELLOW}🔌 Eemaldame SINU (${USER_PREFIX}) võrgud (networks)...${NC}"

# Eemalda todo-network (Harjutus 3)
NETWORKS_REMOVED=0
if docker network ls --format '{{.Name}}' | grep -q "^${USER_PREFIX}-todo-network$"; then
    docker network rm "${USER_PREFIX}-todo-network" 2>/dev/null
    echo -e "${GREEN}  ✓ ${USER_PREFIX}-todo-network eemaldatud${NC}"
    NETWORKS_REMOVED=1
fi

# Eemalda Compose-created network
if docker network ls --format '{{.Name}}' | grep -q "^${USER_PREFIX}_default$"; then
    docker network rm "${USER_PREFIX}_default" 2>/dev/null
    echo -e "${GREEN}  ✓ ${USER_PREFIX}_default eemaldatud${NC}"
    NETWORKS_REMOVED=1
fi

if [ $NETWORKS_REMOVED -eq 0 ]; then
    echo -e "${GREEN}  ✓ Võrke ei leitud (juba puhas)${NC}"
fi

echo ""
echo -e "${YELLOW}💾 Eemaldame SINU (${USER_PREFIX}) andmehoidlad (volumes)...${NC}"

# Eemalda PostgreSQL andmehoidlad (volumes) (Harjutus 4)
VOLUMES_REMOVED=0
for volume in ${USER_PREFIX}_postgres-user-data ${USER_PREFIX}_postgres-todo-data; do
    if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
        docker volume rm "$volume" 2>/dev/null
        echo -e "${GREEN}  ✓ $volume andmehoidla (volume) eemaldatud${NC}"
        VOLUMES_REMOVED=1
    fi
done

# Eemalda Compose-created volumes
for volume in ${USER_PREFIX}_postgres-data; do
    if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
        docker volume rm "$volume" 2>/dev/null
        echo -e "${GREEN}  ✓ $volume andmehoidla (volume) eemaldatud${NC}"
        VOLUMES_REMOVED=1
    fi
done

if [ $VOLUMES_REMOVED -eq 0 ]; then
    echo -e "${GREEN}  ✓ Volume'id ei leitud (juba puhas)${NC}"
fi

echo ""
echo -e "${YELLOW}🧹 Puhastame SINU kasutamata ressursse...${NC}"

# Puhasta ainult kasutamata ressursid (ei mõjuta teisi kasutajaid)
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
                # Kontrolli, kas fail on sinu loodud (ei ole originaal)
                # Kuna need on harjutuse osaks, kustutame need
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
echo -e "${GREEN}✅ Lab 1 süsteem on taastatud (kasutaja: ${USER_PREFIX})!${NC}"
echo ""

# Näita erinevat sõnumit sõltuvalt sellest, kas pildid (images) säilitati
if [[ $DELETE_IMAGES =~ ^[Yy]$ ]]; then
    echo "📚 Harjutuste ülevaade:"
    echo "  1. Harjutus 1a: Üksik Konteiner (Single Container) (User Teenus (Service) - Node.js)"
    echo "  2. Harjutus 1b: Üksik Konteiner (Single Container) (Todo Teenus (Service) - Java)"
    echo "  3. Harjutus 2: Mitme-Konteineri (Multi-Container) (PostgreSQL + Backend)"
    echo "  4. Harjutus 3: Võrgundus (Networking) (Kohandatud Silla (Bridge) Võrk (Network))"
    echo "  5. Harjutus 4: Andmehoidlad (Volumes) (Andmete Püsivus (Data Persistence))"
    echo "  6. Harjutus 5: Optimeerimine (Optimization) (Mitme-sammulised (multi-stage) Buildid)"
    echo ""
    echo "Alusta harjutustega:"
    echo "  cd exercises/"
    echo "  cat 01a-single-container-nodejs.md"
else
    echo -e "${YELLOW}💡 Baaspildid (base images) (${USER_PREFIX}-user-service:1.0, ${USER_PREFIX}-todo-service:1.0) on säilitatud!${NC}"
    echo ""
    echo "Saad nüüd:"
    echo "  ✓ Alustada otse Harjutus 2'st (Mitme-Konteineri (Multi-Container))"
    echo "  ✓ Jätkata Harjutus 3'ga (Võrgundus (Networking))"
    echo "  ✓ Jätkata Harjutus 4'ga (Andmehoidlad (Volumes))"
    echo "  ✓ Alustada Harjutus 5't (Optimeerimine (Optimization)) uuesti"
    echo ""
    echo "Kui soovid täielikku reset'i (sh pildid (images)):"
    echo "  bash reset-multiuser.sh (ja vali Y piltide (images) kustutamisel)"
    echo ""
    echo "📚 Harjutuste ülevaade:"
    echo "  1. Harjutus 1a: Üksik Konteiner (Single Container) (User Teenus (Service) - Node.js) - pilt (image) olemas ✓"
    echo "  2. Harjutus 1b: Üksik Konteiner (Single Container) (Todo Teenus (Service) - Java) - pilt (image) olemas ✓"
    echo "  3. Harjutus 2: Mitme-Konteineri (Multi-Container) (PostgreSQL + Backend)"
    echo "  4. Harjutus 3: Võrgundus (Networking) (Kohandatud Silla (Bridge) Võrk (Network))"
    echo "  5. Harjutus 4: Andmehoidlad (Volumes) (Andmete Püsivus (Data Persistence))"
    echo "  6. Harjutus 5: Optimeerimine (Optimization) (Mitme-sammulised (multi-stage) Buildid)"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Teiste kasutajate ressursid on PUUTUMATA ✓${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
