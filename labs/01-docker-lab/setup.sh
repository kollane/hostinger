#!/bin/bash

# Labor 1: Docker Põhitõed - Automaatne Seadistus (Setup) Script
# Kontrollib ja seadistab kõik eeldused
# Katab MÕLEMAD teenused (services): User Teenus (Service) (Node.js) ja Todo Teenus (Service) (Java)

set -e  # Exit on error

echo "========================================="
echo "  Labor 1: Docker Põhitõed - Seadistus (Setup)"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# MULTI-USER SUPPORT CHECK
# ============================================================================
# Kontrolli, kas multi-user environment on seadistatud
if [ -f ~/.env-lab ]; then
    source ~/.env-lab
    echo -e "${GREEN}✅ Multi-user keskkond tuvastatud${NC}"
    echo -e "   Kasutaja: ${YELLOW}${USER_PREFIX}${NC}"
    echo -e "   Pordid: PostgreSQL ${YELLOW}${POSTGRES_PORT}${NC}, Backend ${YELLOW}${BACKEND_PORT}${NC}, Frontend ${YELLOW}${FRONTEND_PORT}${NC}"
    echo ""
    echo -e "${YELLOW}💡 Kasutatavad aliased:${NC}"
    echo "   dc-up      - Start services (docker compose)"
    echo "   dc-down    - Stop services"
    echo "   dc-ps      - Check status"
    echo "   dc-logs    - View logs"
    echo "   d-cleanup  - Full cleanup (SAFE - ainult sinu ressursid)"
    echo ""
    echo -e "${YELLOW}⚠️  OLULINE: Multi-user keskkonnas:${NC}"
    echo "   - Kasuta 'dc-up' ja 'dc-down' aliaseid"
    echo "   - Cleanup: kasuta 'd-cleanup' (MITTE 'bash reset.sh')"
    echo "   - reset.sh kustutab KÕIGI kasutajate ressursid!"
    echo ""
    MULTIUSER_MODE=true
else
    echo -e "${YELLOW}ℹ️  Single-user režiim${NC}"
    echo ""
    echo -e "${YELLOW}💡 Multi-user keskkonna jaoks:${NC}"
    echo "   1. Käivita: source labs/multi-user-setup.sh"
    echo "   2. Reload: source ~/.bashrc"
    echo "   3. Kasuta aliaseid: dc-up, dc-down, d-cleanup"
    echo ""
    MULTIUSER_MODE=false
fi
echo ""

# Loo ajutine kataloog logide jaoks (mitme kasutaja tugi)
LOGDIR=$(mktemp -d /tmp/docker-lab.XXXXXX)
CLEANUP_LOGS=true

# Puhastamise funktsioon
cleanup() {
    if [ "$CLEANUP_LOGS" = "true" ]; then
        rm -rf "$LOGDIR"
    else
        echo -e "${YELLOW}ℹ️  Logid säilitatud: $LOGDIR${NC}"
    fi
}
trap cleanup EXIT

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
if [ "$AVAILABLE_SPACE" -ge 5 ]; then
    echo -e "${GREEN}✅ Vaba kettaruum: ${AVAILABLE_SPACE}GB (piisav)${NC}"
else
    warn "Vaba kettaruum: ${AVAILABLE_SPACE}GB (soovitatud vähemalt 5GB mõlema teenuse (service) jaoks)"
fi
echo ""

# 5. Check RAM
echo "5️⃣  Kontrollin vaba RAM-i..."
AVAILABLE_RAM=$(free -g | awk 'NR==2 {print $7}')
if [ "$AVAILABLE_RAM" -ge 2 ]; then
    echo -e "${GREEN}✅ Vaba RAM: ${AVAILABLE_RAM}GB${NC}"
else
    warn "Vaba RAM: ${AVAILABLE_RAM}GB (soovitatud vähemalt 2GB mitmete konteinerite jaoks)"
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

# 7. Check apps directory - MÕLEMAD teenused (services)
echo "7️⃣  Kontrollin rakenduste (applications) kättesaadavust..."

# User Teenus (Service) (Node.js) - Harjutus 1a
if [ -d "../apps/backend-nodejs" ]; then
    echo -e "${GREEN}✅ User Teenus (Service) rakendus (application) on kättesaadav:${NC}"
    echo "   - ../apps/backend-nodejs/ (Harjutus 1a: Üksik Konteiner (Single Container) - Node.js)"

    if [ -f "../apps/backend-nodejs/package.json" ]; then
        echo -e "${GREEN}   ✓ package.json on olemas${NC}"
    else
        warn "   package.json puudub - rakendus (application) ei pruugi töötada"
    fi

    if [ -f "../apps/backend-nodejs/server.js" ]; then
        echo -e "${GREEN}   ✓ server.js on olemas${NC}"
    else
        warn "   server.js puudub"
    fi
else
    echo -e "${RED}❌ User Teenus (Service) rakendus (application) pole kättesaadav!${NC}"
    echo "Kontrolli, et oled õiges kataloogis:"
    echo "  cd labs/01-docker-lab"
    exit 1
fi
echo ""

# Todo Teenus (Service) (Java) - Harjutus 1b
if [ -d "../apps/backend-java-spring" ]; then
    echo -e "${GREEN}✅ Todo Teenus (Service) rakendus (application) on kättesaadav:${NC}"
    echo "   - ../apps/backend-java-spring/ (Harjutus 1b: Üksik Konteiner (Single Container) - Java)"

    if [ -f "../apps/backend-java-spring/gradlew" ]; then
        echo -e "${GREEN}   ✓ Gradle wrapper on olemas (JAR ehitamiseks (build))${NC}"
    else
        warn "   gradlew puudub - võid vajada manuaalset Gradle paigaldust"
    fi

    if [ -f "../apps/backend-java-spring/build.gradle" ]; then
        echo -e "${GREEN}   ✓ build.gradle on olemas${NC}"
    else
        warn "   build.gradle puudub"
    fi
else
    echo -e "${RED}❌ Todo Teenus (Service) rakendus (application) pole kättesaadav!${NC}"
    echo "Kontrolli, et oled õiges kataloogis:"
    echo "  cd labs/01-docker-lab"
    exit 1
fi
echo ""

# 8. Check for Java (needed for Harjutus 1b)
echo "8️⃣  Kontrollin Java olemasolu (Todo Teenuse (Service) ehitamiseks (build))..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
    echo -e "${GREEN}✅ Java on paigaldatud (versioon: $JAVA_VERSION)${NC}"
else
    warn "Java pole paigaldatud - Harjutus 1b (Todo Teenus (Service)) vajab Java 17+"
    echo "Paigalda Java:"
    echo "  sudo apt update"
    echo "  sudo apt install -y openjdk-17-jdk"
fi
echo ""

# 9. Check for Node.js (needed for Harjutus 1a)
echo "9️⃣  Kontrollin Node.js olemasolu (User Teenuse (Service) jaoks)..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js on paigaldatud (versioon: $NODE_VERSION)${NC}"
else
    warn "Node.js pole paigaldatud - Harjutus 1a (User Teenus (Service)) vajab Node.js 18+"
    echo "Paigalda Node.js:"
    echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
    echo "  sudo apt install -y nodejs"
fi
echo ""

# 10. Check exercises directory
echo "🔟 Kontrollin harjutuste kättesaadavust..."
if [ -d "exercises" ]; then
    EXERCISE_COUNT=$(ls exercises/*.md 2>/dev/null | wc -l)
    echo -e "${GREEN}✅ Harjutused on kättesaadavad ($EXERCISE_COUNT harjutust)${NC}"

    # Näita harjutuste nimekiri
    echo ""
    echo "📚 Lab 1 harjutused:"
    [ -f "exercises/01a-single-container-nodejs.md" ] && echo "   ✓ Harjutus 1a: Üksik Konteiner (Single Container) (User Teenus (Service) - Node.js)"
    [ -f "exercises/01b-single-container-java.md" ] && echo "   ✓ Harjutus 1b: Üksik Konteiner (Single Container) (Todo Teenus (Service) - Java)"
    [ -f "exercises/02-multi-container.md" ] && echo "   ✓ Harjutus 2: Mitme-Konteineri (Multi-Container) (PostgreSQL + Backend)"
    [ -f "exercises/03-networking.md" ] && echo "   ✓ Harjutus 3: Võrgundus (Networking) (Kohandatud Silla (Bridge) Võrk (Network))"
    [ -f "exercises/04-volumes.md" ] && echo "   ✓ Harjutus 4: Andmehoidlad (Volumes) (Andmete Püsivus (Data Persistence))"
    [ -f "exercises/05-optimization.md" ] && echo "   ✓ Harjutus 5: Optimeerimine (Optimization) (Mitme-sammulised (multi-stage) Buildid)"
else
    warn "Harjutuste kaust puudub"
fi
echo ""

# 11. Check solutions directory - MÕLEMAD teenused (services)
echo "1️⃣1️⃣  Kontrollin näidislahenduste kättesaadavust..."
SOLUTIONS_FOUND=0

# User Teenuse (Service) lahendused
if [ -d "solutions/backend-nodejs" ]; then
    echo -e "${GREEN}✅ User Teenuse (Service) näidislahendused on kättesaadavad:${NC}"

    [ -f "solutions/backend-nodejs/Dockerfile" ] && echo "   ✓ solutions/backend-nodejs/Dockerfile"
    [ -f "solutions/backend-nodejs/Dockerfile.optimized" ] && echo "   ✓ solutions/backend-nodejs/Dockerfile.optimized"
    [ -f "solutions/backend-nodejs/.dockerignore" ] && echo "   ✓ solutions/backend-nodejs/.dockerignore"
    [ -f "solutions/backend-nodejs/healthcheck.js" ] && echo "   ✓ solutions/backend-nodejs/healthcheck.js"

    SOLUTIONS_FOUND=1
fi
echo ""

# Todo Teenuse (Service) lahendused
if [ -d "solutions/backend-java-spring" ]; then
    echo -e "${GREEN}✅ Todo Teenuse (Service) näidislahendused on kättesaadavad:${NC}"

    [ -f "solutions/backend-java-spring/Dockerfile" ] && echo "   ✓ solutions/backend-java-spring/Dockerfile"
    [ -f "solutions/backend-java-spring/Dockerfile.optimized" ] && echo "   ✓ solutions/backend-java-spring/Dockerfile.optimized"
    [ -f "solutions/backend-java-spring/.dockerignore" ] && echo "   ✓ solutions/backend-java-spring/.dockerignore"

    SOLUTIONS_FOUND=1
fi

if [ $SOLUTIONS_FOUND -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}💡 Vaata lahendusi vajaduse korral:${NC}"
    echo "   cat solutions/backend-nodejs/Dockerfile"
    echo "   cat solutions/backend-java-spring/Dockerfile"
else
    warn "Näidislahenduste kaust puudub"
fi
echo ""

# 12. Ensure apps directories are clean (no Dockerfiles that would spoil the exercise)
echo "1️⃣2️⃣  Kontrollin, et apps kaustad on harjutuse jaoks valmis..."
FOUND_FILES=0

# Kontrolli mõlemaid rakendusi (applications)
for APP_DIR in "../apps/backend-nodejs" "../apps/backend-java-spring"; do
    APP_NAME=$(basename "$APP_DIR")

    for file in Dockerfile Dockerfile.optimized .dockerignore healthcheck.js; do
        if [ -f "$APP_DIR/$file" ]; then
            warn "Leitud: $APP_DIR/$file (see tuleks kustutada harjutuse jaoks)"
            FOUND_FILES=1
        fi
    done
done

if [ $FOUND_FILES -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}💡 Soovitus: Käivita reset.sh, et puhastada apps kaustad:${NC}"
    echo "   ./reset.sh"
else
    echo -e "${GREEN}✅ Apps kaustad on puhtad (Dockerfile'e pole, nagu peab olema)${NC}"
fi
echo ""

# 13. Küsi, kas ehitada (build) baaspildid (base images) (harjutuste 2-5 jaoks)
echo "1️⃣3️⃣  Kontrollin Docker piltide (images) olemasolu..."

# Kontrolli, kas baaspildid (base images) on juba olemas
USER_IMAGE_EXISTS=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:1.0$' && echo "yes" || echo "no")
TODO_IMAGE_EXISTS=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:1.0$' && echo "yes" || echo "no")

if [ "$USER_IMAGE_EXISTS" = "yes" ] && [ "$TODO_IMAGE_EXISTS" = "yes" ]; then
    echo -e "${GREEN}✅ Baaspildid (base images) on juba olemas:${NC}"
    echo "   ✓ user-service:1.0"
    echo "   ✓ todo-service:1.0"
    echo ""
    echo "Saad alustada otse Harjutus 2'st!"
elif [ "$USER_IMAGE_EXISTS" = "yes" ] || [ "$TODO_IMAGE_EXISTS" = "yes" ]; then
    echo -e "${YELLOW}⚠️  Osaliselt olemas:${NC}"
    [ "$USER_IMAGE_EXISTS" = "yes" ] && echo "   ✓ user-service:1.0"
    [ "$TODO_IMAGE_EXISTS" = "yes" ] && echo "   ✓ todo-service:1.0"
    echo ""
    echo -e "${YELLOW}💡 Soovitus: Ehita (build) puuduvad pildid (images) Harjutus 1'es${NC}"
else
    echo -e "${YELLOW}⚠️  Baaspildid (base images) ei leitud${NC}"
    echo ""
    echo "🚀 Kas soovid ehitada (build) baaspildid (base images) KOHE?"
    echo "   (user-service:1.0 ja todo-service:1.0)"
    echo ""
    echo "  [Y] Jah, ehita (build) mõlemad pildid (images) nüüd"
    echo "      → Saad otse alustada Harjutus 2'st"
    echo "      → Kulub ~2-5 minutit (sõltuvalt süsteemist)"
    echo "  [N] Ei, teen Harjutus 1 käsitsi (soovitatud õppimiseks)"
    echo "      → Õpid Dockerfile'i loomist algusest"
    echo ""
    read -p "Vali [y/N]: " -n 1 -r BUILD_IMAGES
    echo ""
    echo ""

    if [[ $BUILD_IMAGES =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}📦 Ehitan baaspilte (base images)...${NC}"
        echo ""

        # Ehita (build) User Teenuse (Service) pilt (image)
        echo "1/2: Ehitan user-service:1.0..."
        if [ -f "solutions/backend-nodejs/Dockerfile" ]; then
            cd ../apps/backend-nodejs
            cp ../../01-docker-lab/solutions/backend-nodejs/Dockerfile .
            cp ../../01-docker-lab/solutions/backend-nodejs/.dockerignore .

            if docker build -t user-service:1.0 . > "$LOGDIR/user-service-build.log" 2>&1; then
                echo -e "${GREEN}   ✓ user-service:1.0 ehitatud edukalt!${NC}"
            else
                echo -e "${RED}   ✗ user-service:1.0 ehitamine (build) ebaõnnestus${NC}"
                echo "   Logi: cat $LOGDIR/user-service-build.log"
                CLEANUP_LOGS=false
            fi

            rm -f Dockerfile .dockerignore
            cd ../../01-docker-lab
        else
            echo -e "${RED}   ✗ Dockerfile lahendust ei leitud${NC}"
        fi
        echo ""

        # Ehita (build) Todo Teenuse (Service) pilt (image)
        echo "2/2: Ehitan todo-service:1.0..."
        if [ -f "solutions/backend-java-spring/Dockerfile" ]; then
            cd ../apps/backend-java-spring
            cp ../../01-docker-lab/solutions/backend-java-spring/Dockerfile .
            cp ../../01-docker-lab/solutions/backend-java-spring/.dockerignore .

            # Esmalt ehita (build) JAR fail
            echo "   Building JAR file..."
            if ./gradlew clean bootJar > "$LOGDIR/todo-gradle-build.log" 2>&1; then
                echo -e "${GREEN}   ✓ JAR file ehitatud${NC}"

                if docker build -t todo-service:1.0 . > "$LOGDIR/todo-service-build.log" 2>&1; then
                    echo -e "${GREEN}   ✓ todo-service:1.0 ehitatud edukalt!${NC}"
                else
                    echo -e "${RED}   ✗ todo-service:1.0 ehitamine (build) ebaõnnestus${NC}"
                    echo "   Logi: cat $LOGDIR/todo-service-build.log"
                    CLEANUP_LOGS=false
                fi
            else
                echo -e "${RED}   ✗ JAR ehitamine (build) ebaõnnestus${NC}"
                echo "   Logi: cat $LOGDIR/todo-gradle-build.log"
                CLEANUP_LOGS=false
            fi

            rm -f Dockerfile .dockerignore
            cd ../../01-docker-lab
        else
            echo -e "${RED}   ✗ Dockerfile lahendust ei leitud${NC}"
        fi
        echo ""

        # Kontrolli tulemust
        USER_IMAGE_BUILT=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:1.0$' && echo "yes" || echo "no")
        TODO_IMAGE_BUILT=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:1.0$' && echo "yes" || echo "no")

        if [ "$USER_IMAGE_BUILT" = "yes" ] && [ "$TODO_IMAGE_BUILT" = "yes" ]; then
            echo -e "${GREEN}✅ Mõlemad pildid (images) on valmis!${NC}"
            echo ""
            echo "Saad nüüd alustada otse:"
            echo "  → Harjutus 2: Mitme-Konteineri (Multi-Container)"
            echo "  → Harjutus 3: Võrgundus (Networking)"
            echo "  → Harjutus 4: Andmehoidlad (Volumes)"
        else
            echo -e "${YELLOW}⚠️  Mõned pildid (images) ebaõnnestusid${NC}"
            echo "Soovitus: Tee Harjutus 1 käsitsi, et õppida Dockerfile'i loomist"
        fi
    else
        echo -e "${GREEN}✅ OK, alusta Harjutus 1'st!${NC}"
        echo ""
        echo "Harjutus 1 õpetab sulle:"
        echo "  → Kuidas kirjutada Dockerfile'i"
        echo "  → Kuidas optimeerida pildi (image) suurust"
        echo "  → Kuidas kasutada .dockerignore faili"
    fi
fi
echo ""

# Summary
echo "========================================="
echo "  ✅ Seadistus (Setup) Valmis!"
echo "========================================="
echo ""

# Kontroll, kas pildid (images) on olemas ja näita vastavat sõnumit
FINAL_USER_IMAGE=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:1.0$' && echo "yes" || echo "no")
FINAL_TODO_IMAGE=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:1.0$' && echo "yes" || echo "no")

if [ "$FINAL_USER_IMAGE" = "yes" ] && [ "$FINAL_TODO_IMAGE" = "yes" ]; then
    echo "Kõik eeldused on täidetud JA baaspildid (base images) on olemas!"
    echo ""
    echo "📚 Võid alustada järgmistest harjutustest:"
    echo "  1. ✓ Harjutus 1a: Üksik Konteiner (Single Container) (User Teenus (Service)) - pilt (image) olemas"
    echo "  2. ✓ Harjutus 1b: Üksik Konteiner (Single Container) (Todo Teenus (Service)) - pilt (image) olemas"
    echo "  3. → Harjutus 2: Mitme-Konteineri (Multi-Container) (PostgreSQL + Backend)"
    echo "  4. → Harjutus 3: Võrgundus (Networking) (Kohandatud Silla (Bridge) Võrk (Network), 4 konteinerit)"
    echo "  5. → Harjutus 4: Andmehoidlad (Volumes) (Andmete Püsivus (Data Persistence), 2 andmehoidlat (volumes))"
    echo "  6. → Harjutus 5: Optimeerimine (Optimization) (Mitme-sammulised (multi-stage) Buildid, 2 teenust (services))"
    echo ""
    echo "Järgmised sammud:"
    echo "  Alusta Harjutus 2'st:"
    echo "     cat exercises/02-multi-container.md"
else
    echo "Kõik eeldused on täidetud! Võid alustada laboriga."
    echo ""
    echo "📚 Lab 1 harjutuste progressioon:"
    echo "  1. Harjutus 1a: Üksik Konteiner (Single Container) (User Teenus (Service) - Node.js)"
    echo "  2. Harjutus 1b: Üksik Konteiner (Single Container) (Todo Teenus (Service) - Java)"
    echo "  3. Harjutus 2: Mitme-Konteineri (Multi-Container) (PostgreSQL + Backend)"
    echo "  4. Harjutus 3: Võrgundus (Networking) (Kohandatud Silla (Bridge) Võrk (Network), 4 konteinerit)"
    echo "  5. Harjutus 4: Andmehoidlad (Volumes) (Andmete Püsivus (Data Persistence), 2 andmehoidlat (volumes))"
    echo "  6. Harjutus 5: Optimeerimine (Optimization) (Mitme-sammulised (multi-stage) Buildid, 2 teenust (services))"
    echo ""
    echo "Järgmised sammud:"
    echo "  1. Alusta User Teenusega (Service) (Harjutus 1a):"
    echo "     cat exercises/01a-single-container-nodejs.md"
    echo ""
    echo "  2. Või alusta Todo Teenusega (Service) (Harjutus 1b):"
    echo "     cat exercises/01b-single-container-java.md"
    echo ""
    echo "  3. Või vaata kõiki harjutusi:"
    echo "     ls exercises/"
fi
echo ""
echo "Edu laboriga! 🚀"
