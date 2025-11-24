#!/bin/bash

# =============================================================================
# Lab 2 (Docker Compose) - Setup Script
# =============================================================================
# Interaktiivne skript Lab 2 kiireks alustamiseks
#
# Funktsioonid:
# - Kontrollib Lab 1 eeldusi (images, volumes, network)
# - Loob puuduvad ressursid (network, volumes)
# - Võimaldab valida andmebaasi automaatset initsialiseermist
# - Loob ressursid harjutuste jaoks (EI käivita stack'i!)
#
# Kasutamine:
#   ./setup.sh
#
# Märkus: See skript on mugavuse huvides - harjutused õpetavad käsitsi!
# =============================================================================

# =============================================================================
# Banner
# =============================================================================
clear
echo "=============================================="
echo "  Lab 2: Docker Compose - Setup Skript"
echo "=============================================="
echo ""
echo "See skript aitab sul Lab 2 kiiresti käivitada."
echo "Harjutused õpetavad käsitsi - see on mugavuse huvides!"
echo ""

# =============================================================================
# Samm 1: Kontrolli Eeldusi
# =============================================================================
echo "[1/4] Kontrollin eeldusi..."
echo "=========================================="
echo ""

# Kontrolli Docker
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker ei tööta! Palun käivita Docker esmalt."
    exit 1
fi
echo "✓ Docker töötab"

# Kontrolli Docker Compose
if ! docker compose version > /dev/null 2>&1; then
    echo "❌ Docker Compose ei ole saadaval!"
    exit 1
fi
echo "✓ Docker Compose saadaval"

# Kontrolli Lab 1 Docker Image'id
echo ""
echo "Kontrollin Lab 1 Docker image'id..."

missing_images=0

if docker images | grep -q "user-service.*1.0-optimized"; then
    echo "✓ user-service:1.0-optimized olemas"
else
    echo "⚠ user-service:1.0-optimized puudub"
    missing_images=$((missing_images + 1))
fi

if docker images | grep -q "todo-service.*1.0-optimized"; then
    echo "✓ todo-service:1.0-optimized olemas"
else
    echo "⚠ todo-service:1.0-optimized puudub"
    missing_images=$((missing_images + 1))
fi

if [ $missing_images -gt 0 ]; then
    echo ""
    echo "⚠️  ${missing_images} Docker image puudub!"
    echo ""
    echo "Valikud:"
    echo "  1) Ehita image'd AUTOMAATSELT (${missing_images} image'd, ~5-10 min)"
    echo "     - Kasutab Lab 1 solutions kataloogi Dockerfile.optimized faile"
    echo "     - Ehitab user-service:1.0-optimized ja todo-service:1.0-optimized"
    echo "     - Soovitatav, kui soovid kiiresti alustada"
    echo ""
    echo "  2) Lõpeta Lab 1 harjutused (pedagoogiline)"
    echo "     - Õpid Docker multi-stage builds'e"
    echo "     - Õpid image optimeermist"
    echo "     - Soovitatav, kui soovid õppida"
    echo ""
    echo "  3) Jätka ilma image'ideta"
    echo "     - Stack ei käivitu, aga saad setup skripti testida"
    echo ""
    read -p "Vali variant (1/2/3) [2]: " image_choice
    image_choice=${image_choice:-2}

    if [ "$image_choice" == "1" ]; then
        echo ""
        echo "Ehitan Docker image'd automaatselt..."
        echo "See võib võtta 5-10 minutit (multi-stage builds)"
        echo ""

        # Ehita user-service:1.0-optimized
        if ! docker images | grep -q "user-service.*1.0-optimized"; then
            echo "[1/2] Ehitan user-service:1.0-optimized..."
            cd ../apps/backend-nodejs
            docker build -f ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized -t user-service:1.0-optimized . > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "✓ user-service:1.0-optimized ehitatud edukalt"
            else
                echo "❌ user-service ehitamine ebaõnnestus"
                echo "Vaata logisid käsitsi:"
                echo "  cd ../apps/backend-nodejs"
                echo "  docker build -f ../../01-docker-lab/solutions/backend-nodejs/Dockerfile.optimized -t user-service:1.0-optimized ."
                exit 1
            fi
            cd ../../02-docker-compose-lab
        fi

        # Ehita todo-service:1.0-optimized
        if ! docker images | grep -q "todo-service.*1.0-optimized"; then
            echo "[2/2] Ehitan todo-service:1.0-optimized..."
            cd ../apps/backend-java-spring
            docker build -f ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized -t todo-service:1.0-optimized . > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "✓ todo-service:1.0-optimized ehitatud edukalt"
            else
                echo "❌ todo-service ehitamine ebaõnnestus"
                echo "Vaata logisid käsitsi:"
                echo "  cd ../apps/backend-java-spring"
                echo "  docker build -f ../../01-docker-lab/solutions/backend-java-spring/Dockerfile.optimized -t todo-service:1.0-optimized ."
                exit 1
            fi
            cd ../../02-docker-compose-lab
        fi

        echo ""
        echo "✓ Kõik image'd ehitatud edukalt!"

    elif [ "$image_choice" == "2" ]; then
        echo ""
        echo "Setup katkestatud. Lõpeta Lab 1 või vali variant 1."
        echo ""
        echo "Lab 1 asukoht: cd ../01-docker-lab"
        exit 0

    elif [ "$image_choice" == "3" ]; then
        echo ""
        echo "⚠ Jätkan ilma image'ideta"
        echo "  Märkus: docker compose up failib!"
    else
        echo "❌ Vigane valik. Setup katkestatud."
        exit 1
    fi
fi

# =============================================================================
# Samm 2: Võrgu (Network) Initsialiseermine
# =============================================================================
echo ""
echo "[2/4] Võrgu initsialiseermine"
echo "=========================================="
echo ""

if docker network ls | grep -q "^todo-network"; then
    echo "✓ Võrk 'todo-network' on juba olemas"
else
    echo "⚠ Võrk 'todo-network' puudub"
    echo ""
    echo "Seda võrku vajavad:"
    echo "  ✓ Harjutus 1 - Compose Basics (docker-compose.yml)"
    echo "  ✓ Harjutus 2 - Add Frontend"
    echo "  ✗ Harjutus 3 - Network Segmentation (loob ise 3 uut võrku)"
    echo ""
    echo "Ilma selle võrguta failivad Harjutused 1-2!"
    echo ""
    read -p "Kas luua 'todo-network' nüüd? (Y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "⚠ Võrgu loomine vahele jäetud"
        echo "  Märkus: Harjutused 1-2 FAILIVAD ilma selle võrguta!"
        echo "  Loo võrk käsitsi: docker network create todo-network"
    else
        echo "Loon võrgu 'todo-network'..."
        if docker network create todo-network > /dev/null 2>&1; then
            echo "✓ Võrk 'todo-network' loodud edukalt"
        else
            echo "❌ Võrgu loomine ebaõnnestus"
            exit 1
        fi
    fi
fi

# =============================================================================
# Samm 3: Volume'ide Initsialiseermine
# =============================================================================
echo ""
echo "[3/4] Andmehoidlate (volumes) initsialiseermine"
echo "=========================================="
echo ""

missing_volumes=0

# Kontrolli postgres-user-data
if docker volume ls | grep -q "^postgres-user-data"; then
    echo "✓ Volume 'postgres-user-data' on olemas"
else
    echo "⚠ Volume 'postgres-user-data' puudub"
    missing_volumes=$((missing_volumes + 1))
fi

# Kontrolli postgres-todo-data
if docker volume ls | grep -q "^postgres-todo-data"; then
    echo "✓ Volume 'postgres-todo-data' on olemas"
else
    echo "⚠ Volume 'postgres-todo-data' puudub"
    missing_volumes=$((missing_volumes + 1))
fi

if [ $missing_volumes -gt 0 ]; then
    echo ""
    echo "⚠️  ${missing_volumes} volume puudub!"
    echo ""
    echo "Need volume'd luuakse tavaliselt Lab 1's."
    echo ""
    echo "Neid volume'sid vajavad:"
    echo "  ✓ Harjutus 1 - Compose Basics"
    echo "  ✓ Harjutus 2 - Add Frontend"
    echo "  ✓ Harjutus 3 - Network Segmentation"
    echo "  ✓ Kõik harjutused - PostgreSQL andmed salvestatakse volume'idesse"
    echo ""
    echo "Ilma nende volume'ideta luuakse uued tühjad andmebaasid!"
    echo ""
    read -p "Kas luua puuduvad volume'd nüüd? (Y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "⚠ Volume'ide loomine vahele jäetud"
        echo "  Märkus: Luuakse uued tühjad volume'd esimesel käivitamisel"
    else
        echo "Loon puuduvad volume'd..."

        if ! docker volume ls | grep -q "^postgres-user-data"; then
            docker volume create postgres-user-data > /dev/null
            echo "✓ postgres-user-data loodud"
        fi

        if ! docker volume ls | grep -q "^postgres-todo-data"; then
            docker volume create postgres-todo-data > /dev/null
            echo "✓ postgres-todo-data loodud"
        fi
    fi
fi

# =============================================================================
# Samm 4: Andmebaasi Initsialiseermine
# =============================================================================
echo ""
echo "[4/5] Andmebaasi initsialiseermine"
echo "=========================================="
echo ""

echo "Andmebaasi skeemi (users ja todos tabelid) vajavad:"
echo "  ✓ Harjutus 1 - Compose Basics"
echo "  ✓ Harjutus 2 - Add Frontend"
echo "  ✓ Harjutus 3 - Network Segmentation"
echo "  ✓ Kõik harjutused - Rakendused ei tööta ilma tabeliteta!"
echo ""
echo "Vali andmebaasi seadistamise viis:"
echo ""
echo "  1) Käsitsi seadistamine (pedagoogiline)"
echo "     - Järgid harjutuste juhiseid"
echo "     - Õpid docker exec, psql, SQL käske"
echo "     - Soovitatav õppimiseks!"
echo ""
echo "  2) Automaatne initsialiseermine (mugavus)"
echo "     - PostgreSQL init skriptid loodavad skeemi automaatselt"
echo "     - Sisaldab testimisandmeid (4 kasutajat, 8 todo'd)"
echo "     - Kiire start, aga vähem õpetlik"
echo ""

# Vaikimisi valik: käsitsi (1)
read -p "Vali variant (1/2) [1]: " db_choice
db_choice=${db_choice:-1}

if [ "$db_choice" == "2" ]; then
    DB_INIT_MODE="auto"
    echo ""
    echo "✓ Valitud: Automaatne initsialiseermine"
    echo "  Andmebaasi tabelid ja testimisandmed luuakse automaatselt"
else
    DB_INIT_MODE="manual"
    echo ""
    echo "✓ Valitud: Käsitsi seadistamine"
    echo "  Järgi harjutuste juhiseid andmebaasi seadistamiseks"
fi

# =============================================================================
# Samm 4: Ressursside Kokkuvõte
# =============================================================================
echo ""
echo "[4/4] Ressursside kokkuvõte"
echo "=========================================="
echo ""

echo "✓ Loodud ressursid:"
echo "  - Docker image'd: user-service:1.0-optimized, todo-service:1.0-optimized"
echo "  - Võrk: todo-network"
echo "  - Volume'd: postgres-user-data, postgres-todo-data"
if [ "$DB_INIT_MODE" == "auto" ]; then
    echo "  - DB init režiim: Automaatne (testimisandmetega)"
else
    echo "  - DB init režiim: Käsitsi (järgi harjutuste juhiseid)"
fi
echo ""

# =============================================================================
# Lõppsõnum
# =============================================================================
echo "=============================================="
echo "✅ Lab 2 setup lõpetatud!"
echo "=============================================="
echo ""

echo "JÄRGMISED SAMMUD - Stack'i käivitamine:"
echo ""

if [ "$DB_INIT_MODE" == "auto" ]; then
    echo "VARIANT A: Käivita stack koos automaatse DB init'iga:"
    echo "  cd compose-project"
    echo "  docker compose -f docker-compose.yml -f docker-compose.init.yml up -d"
    echo ""
    echo "Andmebaas luuakse automaatselt:"
    echo "  - 4 kasutajat (admin@example.com, john@example.com, jane@example.com, bob@example.com)"
    echo "  - 5 näidis todo'd"
    echo ""
else
    echo "VARIANT A: Käsitsi DB seadistamine (soovitatud õppimiseks):"
    echo "  cd compose-project"
    echo "  docker compose up -d"
    echo "  # Seejärel järgi Harjutus 1 juhiseid andmebaasi loomiseks"
    echo ""
    echo "VARIANT B: Kui soovid kiire start automaatse DB init'iga:"
    echo "  cd compose-project"
    echo "  docker compose -f docker-compose.yml -f docker-compose.init.yml up -d"
    echo ""
fi

echo "Kasulikud käsud pärast käivitamist:"
echo "  docker compose ps              - Vaata teenuste olekut"
echo "  docker compose logs -f         - Vaata logisid"
echo "  docker compose down            - Peata teenused"
echo ""

echo "Testimine:"
echo "  curl http://localhost:8080                 - Frontend"
echo "  curl http://localhost:3000/health          - User Service"
echo "  curl http://localhost:8081/health          - Todo Service"
echo ""

echo "Harjutused:"
echo "  1. Loe README.md Lab 2 ülevaadet"
echo "  2. Alusta Harjutus 1'st: exercises/01-compose-basics.md"
echo "  3. Järgi harjutusi järjest"
echo ""

echo "=============================================="
echo "Head õppimist! 🚀"
echo "=============================================="
echo ""
