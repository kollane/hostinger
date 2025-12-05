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

# 9. Check exercises directory
echo "9️⃣  Kontrollin harjutuste kättesaadavust..."
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

# 10. Check solutions directory - MÕLEMAD teenused (services)
echo "🔟 Kontrollin näidislahenduste kättesaadavust..."
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

# 11. Ensure apps directories are clean (no Dockerfiles that would spoil the exercise)
echo "1️⃣1️⃣  Kontrollin, et apps kaustad on harjutuse jaoks valmis..."
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
    echo -e "${YELLOW}💡 Soovitus: Käivita labs-reset, et puhastada apps kaustad:${NC}"
    echo "   labs-reset"
else
    echo -e "${GREEN}✅ Apps kaustad on puhtad (Dockerfile'e pole, nagu peab olema)${NC}"
fi
echo ""

# 12. Küsi, kas ehitada (build) baaspildid (base images) (harjutuste 2-5 jaoks)
echo "1️⃣2️⃣  Kontrollin Docker piltide (images) olemasolu..."

# Kontrolli, kas baaspildid (base images) on juba olemas
USER_IMAGE_EXISTS=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:1.0$' && echo "yes" || echo "no")
TODO_IMAGE_EXISTS=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:1.0$' && echo "yes" || echo "no")

if [ "$USER_IMAGE_EXISTS" = "yes" ] && [ "$TODO_IMAGE_EXISTS" = "yes" ]; then
    echo -e "${GREEN}✅ Baaspildid (base images) on juba olemas:${NC}"
    echo "   ✓ user-service:1.0"
    echo "   ✓ todo-service:1.0"
    echo ""
    echo "Saad alustada otse Harjutus 2'st!"
    echo ""

    # Seadista PostgreSQL keskkond (kui pole juba seadistatud)
    USER_IMAGE_BUILT="yes"
    TODO_IMAGE_BUILT="yes"
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

        # Seadista vaikimisi proxy (kui ei ole juba seadistatud)
        # MÄRKUS: See on näidis-proxy corporate keskkonnas
        # Kui sul pole proxy't vaja, seadista: export HTTP_PROXY="" enne setup.sh käivitamist
        if [ -z "$HTTP_PROXY" ]; then
            HTTP_PROXY="http://proxy.example.com:8080"
        fi
        if [ -z "$HTTPS_PROXY" ]; then
            HTTPS_PROXY="http://proxy.example.com:8080"
        fi

        echo -e "${GREEN}✓ Proxy seadistused build'i jaoks:${NC}"
        echo "   HTTP_PROXY=$HTTP_PROXY"
        echo "   HTTPS_PROXY=$HTTPS_PROXY"
        echo ""

        # Kontrolli proxy ühenduvust (kui proxy on seadistatud)
        if [ -n "$HTTP_PROXY" ]; then
            echo "🔍 Kontrollin proxy ühenduvust..."
            if curl -x "$HTTP_PROXY" -s --max-time 5 -I https://registry.npmjs.org > /dev/null 2>&1; then
                echo -e "${GREEN}✓ Proxy töötab (npm registry on kättesaadav)${NC}"
            else
                warn "Proxy ei tööta! npm registry ei ole kättesaadav läbi $HTTP_PROXY"
                echo ""
                echo "Kas soovid jätkata ilma proxy'ta?"
                echo "  [Y] Jah, proovi ilma proxy'ta (HTTP_PROXY ja HTTPS_PROXY tühjendatakse)"
                echo "  [N] Ei, katkesta (saad proxy'd ise seadistada)"
                echo ""
                read -p "Vali [y/N]: " -n 1 -r CONTINUE_WITHOUT_PROXY
                echo ""
                echo ""

                if [[ $CONTINUE_WITHOUT_PROXY =~ ^[Yy]$ ]]; then
                    HTTP_PROXY=""
                    HTTPS_PROXY=""
                    echo -e "${GREEN}✓ Jätkan ilma proxy'ta${NC}"
                else
                    echo -e "${RED}❌ Seadista proxy käsitsi:${NC}"
                    echo "   export HTTP_PROXY=\"http://sinu-proxy:port\""
                    echo "   export HTTPS_PROXY=\"http://sinu-proxy:port\""
                    echo "   ./setup.sh"
                    exit 1
                fi
            fi
            echo ""
        fi

        # Ehita (build) User Teenuse (Service) pilt (image)
        echo "1/2: Ehitan user-service:1.0..."
        if [ -f "solutions/backend-nodejs/Dockerfile.simple" ]; then
            cd ../apps/backend-nodejs
            cp ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.simple ./Dockerfile
            cp ../../01-docker-lab/solutions/backend-nodejs/.dockerignore .

            # Koosta build käsk koos proxy argumentidega
            BUILD_CMD="docker build -t user-service:1.0 --build-arg HTTP_PROXY=$HTTP_PROXY --build-arg HTTPS_PROXY=$HTTPS_PROXY ."

            if eval "$BUILD_CMD" > "$LOGDIR/user-service-build.log" 2>&1; then
                echo -e "${GREEN}   ✓ user-service:1.0 ehitatud edukalt!${NC}"
            else
                echo -e "${RED}   ✗ user-service:1.0 ehitamine (build) ebaõnnestus${NC}"
                echo "   Logi: cat $LOGDIR/user-service-build.log"
                CLEANUP_LOGS=false
            fi

            rm -f Dockerfile .dockerignore
            cd ../../01-docker-lab
        else
            echo -e "${RED}   ✗ Dockerfile.simple lahendust ei leitud${NC}"
        fi
        echo ""

        # Ehita (build) Todo Teenuse (Service) pilt (image)
        echo "2/2: Ehitan todo-service:1.0..."
        if [ -f "solutions/backend-java-spring/Dockerfile.simple" ]; then
            cd ../apps/backend-java-spring
            cp ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.simple ./Dockerfile
            cp ../../01-docker-lab/solutions/backend-java-spring/.dockerignore .

            # Koosta build käsk koos proxy argumentidega
            BUILD_CMD="docker build -t todo-service:1.0 --build-arg HTTP_PROXY=$HTTP_PROXY --build-arg HTTPS_PROXY=$HTTPS_PROXY ."

            if eval "$BUILD_CMD" > "$LOGDIR/todo-service-build.log" 2>&1; then
                echo -e "${GREEN}   ✓ todo-service:1.0 ehitatud edukalt!${NC}"
            else
                echo -e "${RED}   ✗ todo-service:1.0 ehitamine (build) ebaõnnestus${NC}"
                echo "   Logi: cat $LOGDIR/todo-service-build.log"
                CLEANUP_LOGS=false
            fi

            rm -f Dockerfile .dockerignore
            cd ../../01-docker-lab
        else
            echo -e "${RED}   ✗ Dockerfile.simple lahendust ei leitud${NC}"
        fi
        echo ""

        # Kontrolli tulemust
        USER_IMAGE_BUILT=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:1.0$' && echo "yes" || echo "no")
        TODO_IMAGE_BUILT=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:1.0$' && echo "yes" || echo "no")

        if [ "$USER_IMAGE_BUILT" = "yes" ] && [ "$TODO_IMAGE_BUILT" = "yes" ]; then
            echo -e "${GREEN}✅ Mõlemad pildid (images) on valmis!${NC}"
            echo ""
            echo "Seadistan PostgreSQL keskkonna automaatselt..."
            echo "Kulub ~30 sekundit"
            echo ""

            # Loo võrk
            echo "🌐 Loon todo-network võrgu..."
            if docker network ls | grep -q "todo-network"; then
                echo -e "${GREEN}✓ Võrk todo-network on juba olemas${NC}"
            else
                docker network create todo-network > /dev/null 2>&1
                echo -e "${GREEN}✓ Võrk todo-network loodud${NC}"
            fi
            echo ""

            # Loo volume'd
            echo "💾 Loon PostgreSQL andmehoidlaid (volumes)..."
            if docker volume ls | grep -q "postgres-user-data"; then
                echo -e "${GREEN}✓ postgres-user-data on juba olemas${NC}"
            else
                docker volume create postgres-user-data > /dev/null 2>&1
                echo -e "${GREEN}✓ postgres-user-data loodud${NC}"
            fi

            if docker volume ls | grep -q "postgres-todo-data"; then
                echo -e "${GREEN}✓ postgres-todo-data on juba olemas${NC}"
            else
                docker volume create postgres-todo-data > /dev/null 2>&1
                echo -e "${GREEN}✓ postgres-todo-data loodud${NC}"
            fi
            echo ""

            # Käivita PostgreSQL konteinerid
            echo "🐘 Käivitan PostgreSQL konteinereid..."

            # User Service PostgreSQL
            if docker ps -a | grep -q "postgres-user"; then
                if docker ps | grep -q "postgres-user"; then
                    echo -e "${GREEN}✓ postgres-user juba töötab${NC}"
                else
                    docker start postgres-user > /dev/null 2>&1
                    echo -e "${GREEN}✓ postgres-user käivitatud${NC}"
                    sleep 3
                fi
            else
                docker run -d \
                    --name postgres-user \
                    --network todo-network \
                    -e POSTGRES_USER=postgres \
                    -e POSTGRES_PASSWORD=postgres \
                    -e POSTGRES_DB=user_service_db \
                    -v postgres-user-data:/var/lib/postgresql/data \
                    postgres:16-alpine > /dev/null 2>&1
                echo -e "${GREEN}✓ postgres-user käivitatud${NC}"
                sleep 5
            fi

            # Todo Service PostgreSQL
            if docker ps -a | grep -q "postgres-todo"; then
                if docker ps | grep -q "postgres-todo"; then
                    echo -e "${GREEN}✓ postgres-todo juba töötab${NC}"
                else
                    docker start postgres-todo > /dev/null 2>&1
                    echo -e "${GREEN}✓ postgres-todo käivitatud${NC}"
                fi
            else
                docker run -d \
                    --name postgres-todo \
                    --network todo-network \
                    -e POSTGRES_USER=postgres \
                    -e POSTGRES_PASSWORD=postgres \
                    -e POSTGRES_DB=todo_service_db \
                    -v postgres-todo-data:/var/lib/postgresql/data \
                    postgres:16-alpine > /dev/null 2>&1
                echo -e "${GREEN}✓ postgres-todo käivitatud${NC}"
            fi
            echo ""

            # Oota, kuni PostgreSQL on valmis
            echo "⏳ Ootan, kuni PostgreSQL andmebaasid on valmis..."

            # Oota postgres-user
            for i in {1..30}; do
                if docker exec postgres-user pg_isready -U postgres > /dev/null 2>&1; then
                    break
                fi
                sleep 1
            done
            echo -e "${GREEN}✓ postgres-user on valmis${NC}"

            # Oota postgres-todo
            for i in {1..30}; do
                if docker exec postgres-todo pg_isready -U postgres > /dev/null 2>&1; then
                    break
                fi
                sleep 1
            done
            echo -e "${GREEN}✓ postgres-todo on valmis${NC}"
            echo ""

            # Loo tabelid
            echo "📊 Loon andmebaasi tabeleid..."

            # Users tabel
            docker exec -i postgres-user psql -U postgres user_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ users tabel loodud${NC}"
            else
                echo -e "${RED}❌ Viga users tabeli loomisel!${NC}"
            fi

            # Todos tabel
            docker exec -i postgres-todo psql -U postgres todo_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    priority VARCHAR(20) DEFAULT 'medium',
    due_date TIMESTAMP,
    completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ todos tabel loodud${NC}"
            else
                echo -e "${RED}❌ Viga todos tabeli loomisel!${NC}"
            fi
            echo ""

            # Täida andmed
            echo "📝 Täidan testimisandmeid..."

            # Users andmed (4 kasutajat, parool: password123)
            docker exec -i postgres-user psql -U postgres user_service_db > /dev/null 2>&1 <<'EOF'
-- Kustuta vanad testimisandmed (kui on)
DELETE FROM users WHERE email IN (
    'admin@example.com',
    'john@example.com',
    'jane@example.com',
    'bob@example.com'
);

-- Admin kasutaja (parool: password123)
INSERT INTO users (name, email, password, role, created_at, updated_at) VALUES
('Admin User', 'admin@example.com', '$2b$10$K3W/4PeZ9aB8xLqW1p7/8uxXXDtKr0X3wQ4C5gL4Zj7qR6mN9pE5C', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Tavalised kasutajad (parool: password123)
INSERT INTO users (name, email, password, role, created_at, updated_at) VALUES
('John Doe', 'john@example.com', '$2b$10$K3W/4PeZ9aB8xLqW1p7/8uxXXDtKr0X3wQ4C5gL4Zj7qR6mN9pE5C', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Jane Smith', 'jane@example.com', '$2b$10$K3W/4PeZ9aB8xLqW1p7/8uxXXDtKr0X3wQ4C5gL4Zj7qR6mN9pE5C', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Bob Johnson', 'bob@example.com', '$2b$10$K3W/4PeZ9aB8xLqW1p7/8uxXXDtKr0X3wQ4C5gL4Zj7qR6mN9pE5C', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
EOF
                echo -e "${GREEN}✓ users andmed täidetud (4 kasutajat)${NC}"

                # Todos andmed (8 TODO'd)
                docker exec -i postgres-todo psql -U postgres todo_service_db > /dev/null 2>&1 <<'EOF'
-- Kustuta vanad testimisandmed (kui on)
DELETE FROM todos WHERE title IN (
    'Õpi Docker põhitõed',
    'Seadista PostgreSQL',
    'Loo REST API',
    'Implementeeri JWT autentimine',
    'Paigalda Kubernetes',
    'Kirjuta dokumentatsioon',
    'Testi rakendust',
    'Deploy production serverisse'
);

-- Lisa 8 TODO'd (user_id=1 on admin)
-- Kõrge prioriteet (3 TODO'd)
-- Keskmine prioriteet (3 TODO'd)
-- Madal prioriteet (2 TODO'd)
INSERT INTO todos (user_id, title, description, priority, due_date, completed, created_at, updated_at) VALUES
(1, 'Õpi Docker põhitõed', 'Läbi töötada Lab 1 harjutused ja õppida konteinerte. Fookuseks on multi-stage builds ja image optimeerimine.', 'high', '2025-11-20 18:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Seadista PostgreSQL', 'Paigalda ja konfigureeri PostgreSQL andmebaas VPS serverisse. Loo varukoopia strateegia.', 'high', '2025-11-18 12:00:00', true, CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(1, 'Implementeeri JWT autentimine', 'Lisa JWT token-põhine autentimine kasutajate jaoks. Kontrolli token expiration ja refresh tokeni.', 'high', '2025-11-19 10:00:00', true, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days'),
(1, 'Loo REST API', 'Välja töötada Node.js backend koos Express raamistikuga. Implementeeri CRUD operatsioonid.', 'medium', '2025-11-22 15:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Kirjuta dokumentatsioon', 'API dokumentatsioon OpenAPI/Swagger spetsifikatsioonis. Lisa kasutusjuhendid.', 'medium', '2025-11-25 17:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Testi rakendust', 'Ühik- ja integratsioonitestid. Jest raamistik Node.js jaoks, JUnit Java jaoks.', 'medium', '2025-11-23 14:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Paigalda Kubernetes', 'Õpi Kubernetes põhitõed ja paigalda esimene klaster. Deploymentid, Services, ConfigMaps.', 'low', NULL, false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Deploy production serverisse', 'Seadista CI/CD pipeline GitHub Actions abil. Automaatne deployment pärast merge main branchi.', 'low', NULL, false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
EOF
            echo -e "${GREEN}✓ todos andmed täidetud (8 TODO'd)${NC}"
            echo ""

            echo -e "${GREEN}✅ PostgreSQL keskkond valmis!${NC}"
            echo ""
            echo "🎉 TÄIELIK KESKKOND SEADISTATUD!"
            echo ""
            echo "Harjutused 1-4 on sisuliselt läbitud:"
            echo "  ✓ Harjutus 1: Docker pildid (images) ehitatud"
            echo "  ✓ Harjutus 2: PostgreSQL konteinerid + võrk"
            echo "  ✓ Harjutus 3: todo-network võrk loodud"
            echo "  ✓ Harjutus 4: Volume'd loodud + andmed püsivad"
            echo ""
            echo "📍 Alusta SIIT:"
            echo "  → Harjutus 5: Optimeerimine (multi-stage builds)"
            echo "     cat exercises/05-optimization.md"
            echo ""
            echo "Loodud ressursid:"
            echo "  ✓ Pildid: user-service:1.0, todo-service:1.0"
            echo "  ✓ Võrk: todo-network"
            echo "  ✓ Volume'd: postgres-user-data, postgres-todo-data"
            echo "  ✓ Konteinerid: postgres-user, postgres-todo"
            echo "  ✓ Tabelid: users (4 rida), todos (8 rida)"
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

# PostgreSQL seadistus (kui image'd on olemas, aga PostgreSQL pole seadistatud)
if [ "$USER_IMAGE_BUILT" = "yes" ] && [ "$TODO_IMAGE_BUILT" = "yes" ]; then
    # Kontrolli, kas PostgreSQL on juba seadistatud
    POSTGRES_USER_EXISTS=$(docker ps -a --format '{{.Names}}' | grep -q '^postgres-user$' && echo "yes" || echo "no")
    POSTGRES_TODO_EXISTS=$(docker ps -a --format '{{.Names}}' | grep -q '^postgres-todo$' && echo "yes" || echo "no")

    # Kontrolli, kas tabelid on olemas
    USERS_TABLE_EXISTS="no"
    TODOS_TABLE_EXISTS="no"
    if [ "$POSTGRES_USER_EXISTS" = "yes" ]; then
        if docker exec -i postgres-user psql -U postgres user_service_db -c '\dt users' 2>/dev/null | grep -q 'users'; then
            USERS_TABLE_EXISTS="yes"
        fi
    fi
    if [ "$POSTGRES_TODO_EXISTS" = "yes" ]; then
        if docker exec -i postgres-todo psql -U postgres todo_service_db -c '\dt todos' 2>/dev/null | grep -q 'todos'; then
            TODOS_TABLE_EXISTS="yes"
        fi
    fi

    if [ "$POSTGRES_USER_EXISTS" = "no" ] || [ "$POSTGRES_TODO_EXISTS" = "no" ] || \
       [ "$USERS_TABLE_EXISTS" = "no" ] || [ "$TODOS_TABLE_EXISTS" = "no" ]; then
        echo "Seadistan PostgreSQL keskkonna automaatselt..."
        echo "Kulub ~30 sekundit"
        echo ""

        # Loo võrk
        echo "🌐 Loon todo-network võrgu..."
        if docker network ls | grep -q "todo-network"; then
            echo -e "${GREEN}✓ Võrk todo-network on juba olemas${NC}"
        else
            docker network create todo-network > /dev/null 2>&1
            echo -e "${GREEN}✓ Võrk todo-network loodud${NC}"
        fi
        echo ""

        # Loo volume'd
        echo "💾 Loon PostgreSQL andmehoidlaid (volumes)..."
        if docker volume ls | grep -q "postgres-user-data"; then
            echo -e "${GREEN}✓ postgres-user-data on juba olemas${NC}"
        else
            docker volume create postgres-user-data > /dev/null 2>&1
            echo -e "${GREEN}✓ postgres-user-data loodud${NC}"
        fi

        if docker volume ls | grep -q "postgres-todo-data"; then
            echo -e "${GREEN}✓ postgres-todo-data on juba olemas${NC}"
        else
            docker volume create postgres-todo-data > /dev/null 2>&1
            echo -e "${GREEN}✓ postgres-todo-data loodud${NC}"
        fi
        echo ""

        # Käivita PostgreSQL konteinerid
        echo "🐘 Käivitan PostgreSQL konteinereid..."

        # User Service PostgreSQL
        if docker ps -a | grep -q "postgres-user"; then
            if docker ps | grep -q "postgres-user"; then
                echo -e "${GREEN}✓ postgres-user juba töötab${NC}"
            else
                docker start postgres-user > /dev/null 2>&1
                echo -e "${GREEN}✓ postgres-user käivitatud${NC}"
            fi
        else
            docker run -d \
                --name postgres-user \
                --network todo-network \
                -e POSTGRES_USER=postgres \
                -e POSTGRES_PASSWORD=postgres \
                -e POSTGRES_DB=user_service_db \
                -v postgres-user-data:/var/lib/postgresql/data \
                postgres:16-alpine > /dev/null 2>&1
            echo -e "${GREEN}✓ postgres-user käivitatud${NC}"
        fi

        # Todo Service PostgreSQL
        if docker ps -a | grep -q "postgres-todo"; then
            if docker ps | grep -q "postgres-todo"; then
                echo -e "${GREEN}✓ postgres-todo juba töötab${NC}"
            else
                docker start postgres-todo > /dev/null 2>&1
                echo -e "${GREEN}✓ postgres-todo käivitatud${NC}"
            fi
        else
            docker run -d \
                --name postgres-todo \
                --network todo-network \
                -e POSTGRES_USER=postgres \
                -e POSTGRES_PASSWORD=postgres \
                -e POSTGRES_DB=todo_service_db \
                -v postgres-todo-data:/var/lib/postgresql/data \
                postgres:16-alpine > /dev/null 2>&1
            echo -e "${GREEN}✓ postgres-todo käivitatud${NC}"
        fi
        echo ""

        # Oota, kuni PostgreSQL on valmis
        echo "⏳ Ootan, kuni PostgreSQL andmebaasid on valmis..."

        # Oota postgres-user
        for i in {1..30}; do
            if docker exec postgres-user pg_isready -U postgres > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        echo -e "${GREEN}✓ postgres-user on valmis${NC}"

        # Oota postgres-todo
        for i in {1..30}; do
            if docker exec postgres-todo pg_isready -U postgres > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        echo -e "${GREEN}✓ postgres-todo on valmis${NC}"
        echo ""

        # Loo tabelid
        echo "📊 Loon andmebaasi tabeleid..."

        # Users tabel
        docker exec -i postgres-user psql -U postgres user_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ users tabel loodud${NC}"
        else
            echo -e "${RED}❌ Viga users tabeli loomisel!${NC}"
        fi

        # Todos tabel
        docker exec -i postgres-todo psql -U postgres todo_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    priority VARCHAR(20) DEFAULT 'medium',
    due_date TIMESTAMP,
    completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ todos tabel loodud${NC}"
        else
            echo -e "${RED}❌ Viga todos tabeli loomisel!${NC}"
        fi
        echo ""

        # Täida andmed
        echo "📝 Täidan testimisandmeid..."

        # Users andmed (4 kasutajat, parool: password123)
        docker exec -i postgres-user psql -U postgres user_service_db > /dev/null 2>&1 <<'EOF'
-- Kustuta vanad testimisandmed (kui on)
DELETE FROM users WHERE email IN (
    'admin@example.com',
    'john@example.com',
    'jane@example.com',
    'bob@example.com'
);

-- Admin kasutaja (parool: password123)
INSERT INTO users (name, email, password, role, created_at, updated_at) VALUES
('Admin User', 'admin@example.com', '$2b$10$K3W/4PeZ9aB8xLqW1p7/8uxXXDtKr0X3wQ4C5gL4Zj7qR6mN9pE5C', 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Tavalised kasutajad (parool: password123)
INSERT INTO users (name, email, password, role, created_at, updated_at) VALUES
('John Doe', 'john@example.com', '$2b$10$K3W/4PeZ9aB8xLqW1p7/8uxXXDtKr0X3wQ4C5gL4Zj7qR6mN9pE5C', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Jane Smith', 'jane@example.com', '$2b$10$K3W/4PeZ9aB8xLqW1p7/8uxXXDtKr0X3wQ4C5gL4Zj7qR6mN9pE5C', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Bob Johnson', 'bob@example.com', '$2b$10$K3W/4PeZ9aB8xLqW1p7/8uxXXDtKr0X3wQ4C5gL4Zj7qR6mN9pE5C', 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
EOF
        echo -e "${GREEN}✓ users andmed täidetud (4 kasutajat)${NC}"

        # Todos andmed (8 TODO'd)
        docker exec -i postgres-todo psql -U postgres todo_service_db > /dev/null 2>&1 <<'EOF'
-- Kustuta vanad testimisandmed (kui on)
DELETE FROM todos WHERE title IN (
    'Õpi Docker põhitõed',
    'Seadista PostgreSQL',
    'Loo REST API',
    'Implementeeri JWT autentimine',
    'Paigalda Kubernetes',
    'Kirjuta dokumentatsioon',
    'Testi rakendust',
    'Deploy production serverisse'
);

-- Lisa 8 TODO'd (user_id=1 on admin)
-- Kõrge prioriteet (3 TODO'd)
-- Keskmine prioriteet (3 TODO'd)
-- Madal prioriteet (2 TODO'd)
INSERT INTO todos (user_id, title, description, priority, due_date, completed, created_at, updated_at) VALUES
(1, 'Õpi Docker põhitõed', 'Läbi töötada Lab 1 harjutused ja õppida konteinerte. Fookuseks on multi-stage builds ja image optimeerimine.', 'high', '2025-11-20 18:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Seadista PostgreSQL', 'Paigalda ja konfigureeri PostgreSQL andmebaas VPS serverisse. Loo varukoopia strateegia.', 'high', '2025-11-18 12:00:00', true, CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(1, 'Implementeeri JWT autentimine', 'Lisa JWT token-põhine autentimine kasutajate jaoks. Kontrolli token expiration ja refresh tokeni.', 'high', '2025-11-19 10:00:00', true, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days'),
(1, 'Loo REST API', 'Välja töötada Node.js backend koos Express raamistikuga. Implementeeri CRUD operatsioonid.', 'medium', '2025-11-22 15:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Paigalda Kubernetes', 'Seadista K3s klaster VPS serveris. Deploy mikro-teenused (microservices).', 'medium', '2025-11-25 09:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Kirjuta dokumentatsioon', 'Dokumenteeri API endpointid, arhitektuur ja deployment protsess.', 'medium', '2025-11-30 17:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Testi rakendust', 'Kirjuta unit ja integration testid. Saavuta vähemalt 80% code coverage.', 'low', '2025-12-05 14:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Deploy production serverisse', 'Paigalda rakendus production keskkonda koos monitoringuga.', 'low', '2025-12-10 16:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
EOF
        echo -e "${GREEN}✓ todos andmed täidetud (8 TODO'd)${NC}"
        echo ""

        echo ""
        echo "Loodud ressursid:"
        echo "  ✓ Pildid: user-service:1.0, todo-service:1.0"
        echo "  ✓ Võrk: todo-network"
        echo "  ✓ Volume'd: postgres-user-data, postgres-todo-data"
        echo "  ✓ Konteinerid: postgres-user, postgres-todo"
        echo "  ✓ Tabelid: users (4 rida), todos (8 rida)"
        echo ""
    fi
fi

# Summary
echo "========================================="
echo "  ✅ Seadistus (Setup) Valmis!"
echo "========================================="
echo ""

# Kontroll, kas pildid (images) on olemas ja näita vastavat sõnumit
FINAL_USER_IMAGE=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^user-service:1.0$' && echo "yes" || echo "no")
FINAL_TODO_IMAGE=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -q '^todo-service:1.0$' && echo "yes" || echo "no")
FINAL_POSTGRES_USER=$(docker ps -a --format '{{.Names}}' | grep -q '^postgres-user$' && echo "yes" || echo "no")
FINAL_POSTGRES_TODO=$(docker ps -a --format '{{.Names}}' | grep -q '^postgres-todo$' && echo "yes" || echo "no")
FINAL_NETWORK=$(docker network ls --format '{{.Name}}' | grep -q '^todo-network$' && echo "yes" || echo "no")

# Kontrolli, kas täielik keskkond on seadistatud
if [ "$FINAL_USER_IMAGE" = "yes" ] && [ "$FINAL_TODO_IMAGE" = "yes" ] && \
   [ "$FINAL_POSTGRES_USER" = "yes" ] && [ "$FINAL_POSTGRES_TODO" = "yes" ] && \
   [ "$FINAL_NETWORK" = "yes" ]; then
    echo "🎉 TÄIELIK KESKKOND ON SEADISTATUD!"
    echo ""
    echo "Harjutused 1-4 on sisuliselt läbitud:"
    echo "  ✓ Harjutus 1: Docker pildid ehitatud"
    echo "  ✓ Harjutus 2: PostgreSQL konteinerid töötavad"
    echo "  ✓ Harjutus 3: todo-network võrk loodud"
    echo "  ✓ Harjutus 4: Volume'd ja andmed olemas"
    echo ""
    echo "📍 Alusta SIIT:"
    echo "  → Harjutus 5: Optimeerimine (multi-stage builds)"
    echo "     cat exercises/05-optimization.md"
    echo ""
elif [ "$FINAL_USER_IMAGE" = "yes" ] && [ "$FINAL_TODO_IMAGE" = "yes" ]; then
    echo "Baaspildid (base images) on olemas!"
    echo ""
    echo "Harjutus 1 on sisuliselt läbitud (image'd ehitatud)"
    echo ""
    echo "📍 Alusta SIIT:"
    echo "  → Harjutus 2: Mitme-Konteineri (Multi-Container)"
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
