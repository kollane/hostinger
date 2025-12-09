#!/bin/bash

# Laborite Täielik Reset Skript
# Asendab kõik Lab 1-10 reset.sh skriptid ja nuclear-cleanup käsu
# Kustutab KÕIK Docker ressursid + apps/ failid

echo "======================================"
echo "Laborid - Täielik Süsteemi Reset"
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

echo -e "${YELLOW}⚠️  HOIATUS: See kustutab KÕIK Docker ressursid süsteemis:${NC}"
echo "  - KÕIK konteinerid (töötavad ja peatatud)"
echo "  - KÕIK Docker võrgud (networks) (välja arvatud bridge, host, none)"
echo "  - KÕIK andmehoidlad (volumes)"
echo "  - Pildid (images): vastavalt valikule (küsime järgmisena)"
echo "  - Apps failid: Dockerfile, Dockerfile.optimized, .dockerignore, healthcheck.js"
echo "  - Lab 2 compose-project/ kataloog"
echo ""
echo -e "${RED}⚠️  NB! Kui Sul on teisi Docker projekte, need kaovad ka!${NC}"
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
echo "  [N] Ei, säilita Lab 1 baaspildid (user-service:1.0, todo-service:1.0)"
echo "      → Kustutan ülejäänud pildid, aga säilitan Lab 1 baaspildid"
echo "  [Y] Jah, kustuta KÕIK pildid (images) (täielik reset)"
echo "      → Pead ehitama Lab 1 pildid uuesti"
echo ""
read -p "Vali [N/y]: " -n 1 -r DELETE_IMAGES
echo ""

if [[ ! $DELETE_IMAGES =~ ^[Yy]$ ]]; then
    DELETE_IMAGES="n"
fi
echo ""

# 1. KONTEINERID
echo -e "${YELLOW}📦 Peatame ja eemaldame KÕIK konteinerid...${NC}"
if [ $(docker ps -aq 2>/dev/null | wc -l) -gt 0 ]; then
    docker stop $(docker ps -aq) 2>/dev/null
    docker rm $(docker ps -aq) 2>/dev/null
    echo -e "${GREEN}  ✓ Kõik konteinerid eemaldatud${NC}"
else
    echo -e "${GREEN}  ✓ Konteinereid ei leitud${NC}"
fi
echo ""

# 2. PILDID (IMAGES)
echo -e "${YELLOW}🗑️  Eemaldame Docker pildid (images)...${NC}"
if [[ $DELETE_IMAGES =~ ^[Yy]$ ]]; then
    # Kustuta KÕIK pildid
    if [ $(docker images -q 2>/dev/null | wc -l) -gt 0 ]; then
        docker rmi -f $(docker images -q) 2>/dev/null
        echo -e "${GREEN}  ✓ Kõik pildid (images) eemaldatud${NC}"
    else
        echo -e "${GREEN}  ✓ Pilte (images) ei leitud${NC}"
    fi
else
    # Säilita Lab 1 baaspildid, kustuta ülejäänud
    TOTAL_IMAGES=$(docker images -q 2>/dev/null | wc -l)
    if [ $TOTAL_IMAGES -gt 0 ]; then
        docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | \
            grep -v '^user-service:1\.0$' | \
            grep -v '^todo-service:1\.0$' | \
            xargs -r docker rmi -f 2>/dev/null
        echo -e "${GREEN}  ✓ Ülejäänud pildid (images) eemaldatud${NC}"
    fi

    # Kontrolli baaspildid
    if docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -q '^user-service:1\.0$'; then
        echo -e "${YELLOW}  ℹ  user-service:1.0 säilitatud${NC}"
    fi
    if docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep -q '^todo-service:1\.0$'; then
        echo -e "${YELLOW}  ℹ  todo-service:1.0 säilitatud${NC}"
    fi
fi
echo ""

# 3. VÕRGUD (NETWORKS)
echo -e "${YELLOW}🔌 Eemaldame KÕIK kohandatud võrgud (networks)...${NC}"
CUSTOM_NETWORKS=$(docker network ls --format '{{.Name}}' 2>/dev/null | grep -v '^bridge$' | grep -v '^host$' | grep -v '^none$')
if [ -n "$CUSTOM_NETWORKS" ]; then
    echo "$CUSTOM_NETWORKS" | xargs -r docker network rm 2>/dev/null
    echo -e "${GREEN}  ✓ Kõik kohandatud võrgud (networks) eemaldatud${NC}"
else
    echo -e "${GREEN}  ✓ Kohandatud võrke (networks) ei leitud${NC}"
fi
echo ""

# 4. ANDMEHOIDLAD (VOLUMES)
echo -e "${YELLOW}💾 Eemaldame KÕIK andmehoidlad (volumes)...${NC}"
if [ $(docker volume ls -q 2>/dev/null | wc -l) -gt 0 ]; then
    docker volume rm $(docker volume ls -q) 2>/dev/null
    echo -e "${GREEN}  ✓ Kõik andmehoidlad (volumes) eemaldatud${NC}"
else
    echo -e "${GREEN}  ✓ Andmehoidlaid (volumes) ei leitud${NC}"
fi
echo ""

# 5. SYSTEM PRUNE
echo -e "${YELLOW}🧹 Puhastame kasutamata ressursse...${NC}"
docker system prune -af --volumes > /dev/null 2>&1
echo -e "${GREEN}  ✓ Kasutamata ressursid eemaldatud${NC}"
echo ""

# 6. APPS/ FAILID
echo -e "${YELLOW}🗂️  Eemaldame Lab 1 failid apps/ kaust(ad)est...${NC}"
APPS_BASE="$HOME/labs/apps"
if [ ! -d "$APPS_BASE" ]; then
    echo -e "${YELLOW}  ⚠ apps/ kausta ei leitud ($APPS_BASE)${NC}"
else
    for APP_DIR in "$APPS_BASE/backend-nodejs" "$APPS_BASE/backend-java-spring"; do
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
        fi
    done
fi
echo ""

# 7. LAB 2 COMPOSE-PROJECT KATALOOG
echo -e "${YELLOW}🗂️  Eemaldame Lab 2 compose-project/ kataloogi...${NC}"
LAB2_COMPOSE="$HOME/labs/02-docker-compose-lab/compose-project"
if [ -d "$LAB2_COMPOSE" ]; then
    rm -rf "$LAB2_COMPOSE"
    echo -e "${GREEN}  ✓ compose-project/ kataloog eemaldatud${NC}"
else
    echo -e "${GREEN}  ✓ compose-project/ kataloog puudub (juba puhas)${NC}"
fi
echo ""

echo -e "${GREEN}✅ Laborid on täielikult resetitud!${NC}"
echo ""

if [[ $DELETE_IMAGES =~ ^[Yy]$ ]]; then
    echo "📚 Alusta Lab 1 harjutust 1'st (ehita pildid uuesti)"
else
    echo -e "${YELLOW}💡 Lab 1 baaspildid säilitatud - saad jätkata harjutustest 2-6${NC}"
fi
echo ""

echo -e "${YELLOW}💡 Kasulikud käsud:${NC}"
echo "  check-resources    - Detailne ressursside ülevaade"
echo "  lab1-setup         - Lab 1 seadistus (Docker images)"
echo "  lab2-setup         - Lab 2 seadistus (Docker Compose)"
echo "  labs-reset         - Täielik laborite reset (KÕIK Docker ressursid)"
echo ""
