#!/bin/bash

# Lab 1 Reset Script
# Puhastab kõik Lab 1 ressursid ja taastab algseis
# Katab MÕLEMAD teenused (services): User Teenus (Service) (Node.js) ja Todo Teenus (Service) (Java)

echo "======================================"
echo "Lab 1 (Docker) - Süsteemi Taastamine"
echo "======================================"
echo ""

# Värvilised väljundid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# MULTI-USER ENVIRONMENT WARNING
# ============================================================================
if [ -f ~/.env-lab ]; then
    source ~/.env-lab
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  MULTI-USER KESKKOND TUVASTATUD  ⚠️                       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}HOIATUS: See skript (reset.sh) on mõeldud SINGLE-USER keskkonnale!${NC}"
    echo ""
    echo -e "${RED}❌ OHTLIK: reset.sh kustutab KÕIGI kasutajate ressursid:${NC}"
    echo "   - Kõigi kasutajate konteinerid (user-service, todo-service, postgres-*)"
    echo "   - Kõigi kasutajate image'id (user-service:*, todo-service:*)"
    echo "   - Kõigi kasutajate võrgud (todo-network)"
    echo "   - Kõigi kasutajate volumes (postgres-*-data) - ANDMED KADUVAD!"
    echo ""
    echo -e "${GREEN}✅ TURVALINE: Multi-user keskkonnas kasuta selle asemel:${NC}"
    echo "   d-cleanup           - Kustutab AINULT sinu (${USER_PREFIX}) ressursid"
    echo "   dc-down             - Peatab sinu teenused (andmed säilivad)"
    echo "   bash reset-multiuser.sh  - User-safe reset (kui olemas)"
    echo ""
    echo -e "${YELLOW}Sinu kasutaja: ${USER_PREFIX}${NC}"
    echo -e "${YELLOW}Sinu pordid: PostgreSQL ${POSTGRES_PORT}, Backend ${BACKEND_PORT}${NC}"
    echo ""
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    read -p "Kas oled KINDEL, et soovid jätkata ja kustutada KÕIGI ressursid? (yes/NO) " -r CONFIRM_MULTIUSER
    echo ""

    if [[ ! "$CONFIRM_MULTIUSER" == "yes" ]]; then
        echo -e "${GREEN}✅ Tühistatud. Kasuta 'd-cleanup' turvaliseks cleanup'iks.${NC}"
        exit 0
    fi

    echo -e "${YELLOW}⚠️  Jätkame hard reset'iga (KÕIK kasutajad mõjutatud!)...${NC}"
    echo ""
fi

# Kontrolli, kas Docker töötab
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker ei tööta! Palun käivita Docker esmalt.${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  HOIATUS: See kustutab KÕIK Lab 1 ressursid:${NC}"
echo "  - Konteinerid: user-service*, todo-service*, postgres-user, postgres-todo"
echo "  - Pildid (images): user-service:*, todo-service:*"
echo "  - Võrgud (networks): todo-network"
echo "  - Andmehoidlad (volumes): postgres-user-data, postgres-todo-data"
echo "  - Apps failid: Dockerfile, Dockerfile.optimized, .dockerignore"
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
echo "  [N] Ei, jäta baaspildid (base images) alles (user-service:1.0, todo-service:1.0)"
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

echo -e "${YELLOW}📦 Peatame ja eemaldame Lab 1 konteinerid...${NC}"

# Eemalda User Teenuse (Service) konteinerid (Harjutus 1a, 3, 5)
for container in user-service user-service-opt user-service-test; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container"
        echo -e "${GREEN}  ✓ $container konteiner eemaldatud${NC}"
    fi
done

# Eemalda Todo Teenuse (Service) konteinerid (Harjutus 1b, 3, 5)
for container in todo-service todo-service-opt todo-service-test; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container"
        echo -e "${GREEN}  ✓ $container konteiner eemaldatud${NC}"
    fi
done

# Eemalda PostgreSQL konteinerid (Harjutus 2, 3, 4)
for container in postgres-user postgres-todo; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container"
        echo -e "${GREEN}  ✓ $container konteiner eemaldatud${NC}"
    fi
done

echo ""
echo -e "${YELLOW}🗑️  Eemaldame Lab 1 Docker pildid (images)...${NC}"

if [[ $DELETE_IMAGES =~ ^[Yy]$ ]]; then
    # Täielik reset - kustuta KÕIK pildid (images)
    # Eemalda user-service pildid (images) (Harjutus 1a, 5)
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:'; then
        docker rmi -f $(docker images --format '{{.Repository}}:{{.Tag}}' | grep '^user-service:') 2>/dev/null
        echo -e "${GREEN}  ✓ Kõik user-service pildid (images) eemaldatud${NC}"
    fi

    # Eemalda todo-service pildid (images) (Harjutus 1b, 5)
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:'; then
        docker rmi -f $(docker images --format '{{.Repository}}:{{.Tag}}' | grep '^todo-service:') 2>/dev/null
        echo -e "${GREEN}  ✓ Kõik todo-service pildid (images) eemaldatud${NC}"
    fi
else
    # Osaline reset - kustuta AINULT optimeeritud pildid (images), säilita baaspildid (base images)
    # Eemalda user-service optimeeritud pilt (image) (Harjutus 5)
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:1.0-optimized$'; then
        docker rmi -f user-service:1.0-optimized 2>/dev/null
        echo -e "${GREEN}  ✓ user-service:1.0-optimized eemaldatud${NC}"
    fi

    # Eemalda todo-service optimeeritud pilt (image) (Harjutus 5)
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:1.0-optimized$'; then
        docker rmi -f todo-service:1.0-optimized 2>/dev/null
        echo -e "${GREEN}  ✓ todo-service:1.0-optimized eemaldatud${NC}"
    fi

    # Kontrolli, kas baaspildid (base images) on olemas
    BASE_IMAGES_EXIST=0
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:1.0$'; then
        echo -e "${YELLOW}  ℹ  user-service:1.0 säilitatud (Harjutuste 2-5 jaoks)${NC}"
        BASE_IMAGES_EXIST=1
    fi
    if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:1.0$'; then
        echo -e "${YELLOW}  ℹ  todo-service:1.0 säilitatud (Harjutuste 2-5 jaoks)${NC}"
        BASE_IMAGES_EXIST=1
    fi

    if [ $BASE_IMAGES_EXIST -eq 0 ]; then
        echo -e "${YELLOW}  ℹ  Baaspildid (base images) ei leitud (pead looma Harjutus 1'es)${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}🔌 Eemaldame Lab 1 võrgud (networks)...${NC}"

# Eemalda todo-network (Harjutus 3)
if docker network ls --format '{{.Name}}' | grep -q "^todo-network$"; then
    docker network rm "todo-network" 2>/dev/null
    echo -e "${GREEN}  ✓ todo-network eemaldatud${NC}"
fi

echo ""
echo -e "${YELLOW}💾 Eemaldame Lab 1 andmehoidlad (volumes)...${NC}"

# Eemalda PostgreSQL andmehoidlad (volumes) (Harjutus 4)
for volume in postgres-user-data postgres-todo-data; do
    if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
        docker volume rm "$volume" 2>/dev/null
        echo -e "${GREEN}  ✓ $volume andmehoidla (volume) eemaldatud${NC}"
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
    echo -e "${YELLOW}💡 Baaspildid (base images) (user-service:1.0, todo-service:1.0) on säilitatud!${NC}"
    echo ""
    echo "Saad nüüd:"
    echo "  ✓ Alustada otse Harjutus 2'st (Mitme-Konteineri (Multi-Container))"
    echo "  ✓ Jätkata Harjutus 3'ga (Võrgundus (Networking))"
    echo "  ✓ Jätkata Harjutus 4'ga (Andmehoidlad (Volumes))"
    echo "  ✓ Alustada Harjutus 5't (Optimeerimine (Optimization)) uuesti"
    echo ""
    echo "Kui soovid täielikku reset'i (sh pildid (images)):"
    echo "  ./reset.sh (ja vali Y piltide (images) kustutamisel)"
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
echo "======================================"
