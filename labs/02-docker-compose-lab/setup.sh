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

            # Kontrolli ja kopeeri healthcheck.js Lab 1 lahendusest kui puudub
            if [ ! -f "healthcheck.js" ]; then
                echo "  → Kopeerin healthcheck.js Lab 1 lahendusest..."
                if [ -f "../../01-docker-lab/solutions/backend-nodejs/healthcheck.js" ]; then
                    cp ../../01-docker-lab/solutions/backend-nodejs/healthcheck.js .
                    echo "  ✓ healthcheck.js kopeeritud"
                else
                    echo "  ⚠ Lab 1 lahendus puudub, loon healthcheck.js inline'ina..."
                    cat > healthcheck.js <<'HEALTHCHECK_EOF'
const http = require('http');

const options = {
  host: 'localhost',
  port: 3000,
  path: '/health',
  timeout: 2000
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

req.on('error', () => process.exit(1));
req.end();
HEALTHCHECK_EOF
                    echo "  ✓ healthcheck.js loodud"
                fi
            fi

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

# Vaikimisi valik: automaatne (2)
read -p "Vali variant (1/2) [2]: " db_choice
db_choice=${db_choice:-2}

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
echo "[4/7] Ressursside kokkuvõte"
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

# Kasutame solutions kausta docker-compose.yml faili
COMPOSE_DIR="solutions/01-compose-basics"

# =============================================================================
# Samm 5: Stack'i Ajutine Käivitamine (AINULT automaatse režiimi korral)
# =============================================================================
if [ "$DB_INIT_MODE" == "auto" ]; then
    echo ""
    echo "[5/7] PostgreSQL konteinrite käivitamine"
    echo "=========================================="
    echo ""
    echo "Käivitan AINULT PostgreSQL konteinerid (mitte backend teenuseid)..."
    echo "See võtab ~10-15 sekundit"
    echo ""

    cd "$COMPOSE_DIR"

    # Käivita AINULT PostgreSQL konteinerid (postgres-user ja postgres-todo)
    # Kasuta ainult docker-compose.yml (ignoreeri automaatset override faili)
    docker compose -f docker-compose.yml up -d postgres-user postgres-todo > /dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "❌ PostgreSQL konteinrite käivitamine ebaõnnestus!"
        echo "Proovi käsitsi: cd $COMPOSE_DIR && docker compose -f docker-compose.yml up -d postgres-user postgres-todo"
        cd ../..
        exit 1
    fi

    echo "✓ PostgreSQL konteinerid käivitatud"
    echo ""

    # =============================================================================
    # Samm 6: Oota PostgreSQL Konteinrite Valmimist
    # =============================================================================
    echo "[6/7] PostgreSQL konteinrite valmimise ootamine"
    echo "=========================================="
    echo ""
    echo "Ootan, kuni PostgreSQL konteinerid on healthy..."
    echo -n "Ootan"

    # Oota kuni PostgreSQL konteinerid on healthy (max 30s)
    max_wait=30
    waited=0
    all_healthy=false

    while [ $waited -lt $max_wait ]; do
        user_health=$(docker inspect --format='{{.State.Health.Status}}' postgres-user 2>/dev/null || echo "starting")
        todo_health=$(docker inspect --format='{{.State.Health.Status}}' postgres-todo 2>/dev/null || echo "starting")

        if [ "$user_health" = "healthy" ] && [ "$todo_health" = "healthy" ]; then
            all_healthy=true
            break
        fi

        echo -n "."
        sleep 2
        waited=$((waited + 2))
    done
    echo ""

    if [ "$all_healthy" = false ]; then
        echo "⚠️  PostgreSQL konteinerid ei jõudnud healthy staatusesse 30s jooksul"
        echo "   Proovin andmeid siiski täita..."
        echo ""
    else
        echo "✓ PostgreSQL konteinerid on healthy (${waited}s)"
        echo ""
    fi

    # =============================================================================
    # Samm 7: Tabelite Loomine ja Testimisandmete Täitmine
    # =============================================================================
    echo "[7/7] Tabelite loomine ja testimisandmete täitmine"
    echo "=========================================="
    echo ""

    # 1. Loo users tabel
    echo "Loon users tabeli..."
    docker exec -i postgres-user psql -U postgres -d user_service_db > /dev/null 2>&1 <<'EOF'
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
        echo "✓ users tabel loodud"
    else
        echo "❌ users tabeli loomine ebaõnnestus"
    fi

    # 2. Loo todos tabel
    echo "Loon todos tabeli..."
    docker exec -i postgres-todo psql -U postgres -d todo_service_db > /dev/null 2>&1 <<'EOF'
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
        echo "✓ todos tabel loodud"
    else
        echo "❌ todos tabeli loomine ebaõnnestus"
    fi

    echo ""

    # 3. Täida users andmed (4 kasutajat: admin, john, jane, bob)
    echo "Täidan users andmed..."
    docker exec -i postgres-user psql -U postgres -d user_service_db > /dev/null 2>&1 <<'EOF'
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

    if [ $? -eq 0 ]; then
        echo "✓ users andmed täidetud (4 kasutajat)"
    else
        echo "❌ users andmete täitmine ebaõnnestus"
    fi

    # 4. Täida todos andmed (8 TODO'd - kõrge, keskmine, madal prioriteet)
    echo "Täidan todos andmed..."
    docker exec -i postgres-todo psql -U postgres -d todo_service_db > /dev/null 2>&1 <<'EOF'
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
INSERT INTO todos (user_id, title, description, priority, due_date, completed, created_at, updated_at) VALUES
-- Kõrge prioriteet (3 TODO'd)
(1, 'Õpi Docker põhitõed', 'Läbi töötada Lab 1 harjutused ja õppida konteinerte. Fookuseks on multi-stage builds ja image optimeerimine.', 'high', '2025-11-20 18:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Seadista PostgreSQL', 'Paigalda ja konfigureeri PostgreSQL andmebaas VPS serverisse. Loo varukoopia strateegia.', 'high', '2025-11-18 12:00:00', true, CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(1, 'Implementeeri JWT autentimine', 'Lisa JWT token-põhine autentimine kasutajate jaoks. Kontrolli token expiration ja refresh tokeni.', 'high', '2025-11-19 10:00:00', true, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days'),

-- Keskmine prioriteet (3 TODO'd)
(1, 'Loo REST API', 'Välja töötada Node.js backend koos Express raamistikuga. Implementeeri CRUD operatsioonid.', 'medium', '2025-11-22 15:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Kirjuta dokumentatsioon', 'API dokumentatsioon OpenAPI/Swagger spetsifikatsioonis. Lisa kasutusjuhendid.', 'medium', '2025-11-25 17:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Testi rakendust', 'Ühik- ja integratsioonitestid. Jest raamistik Node.js jaoks, JUnit Java jaoks.', 'medium', '2025-11-23 14:00:00', false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),

-- Madal prioriteet (2 TODO'd)
(1, 'Paigalda Kubernetes', 'Õpi Kubernetes põhitõed ja paigalda esimene klaster. Deploymentid, Services, ConfigMaps.', 'low', NULL, false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
(1, 'Deploy production serverisse', 'Seadista CI/CD pipeline GitHub Actions abil. Automaatne deployment pärast merge main branchi.', 'low', NULL, false, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
EOF

    if [ $? -eq 0 ]; then
        echo "✓ todos andmed täidetud (8 TODO'd)"
    else
        echo "❌ todos andmete täitmine ebaõnnestus"
    fi

    echo ""
    echo "=========================================="
    echo "Andmete kontroll (kas jäid püsima?):"
    echo "=========================================="
    echo ""

    user_count=$(docker exec postgres-user psql -U postgres -d user_service_db -tAc "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
    todo_count=$(docker exec postgres-todo psql -U postgres -d todo_service_db -tAc "SELECT COUNT(*) FROM todos;" 2>/dev/null || echo "0")

    if [ "$user_count" -gt 0 ]; then
        echo "✓ users: $user_count rida (andmed salvestatud volume'i)"
    else
        echo "❌ users: 0 rida (andmed ei jäänud püsima!)"
    fi

    if [ "$todo_count" -gt 0 ]; then
        echo "✓ todos: $todo_count rida (andmed salvestatud volume'i)"
    else
        echo "❌ todos: 0 rida (andmed ei jäänud püsima!)"
    fi

    echo ""
    echo "=========================================="
    echo "PostgreSQL konteinrite peatamine"
    echo "=========================================="
    echo ""
    echo "Peatan PostgreSQL konteinerid..."
    echo "Volume'd jäävad alles koos andmetega!"
    echo ""

    # Peata ja eemalda AINULT PostgreSQL konteinerid (mitte tervet stack'i)
    # -s flag peatab konteinerid, -f eemaldab isegi kui töötavad
    cd "$COMPOSE_DIR"
    docker compose -f docker-compose.yml rm -sf postgres-user postgres-todo > /dev/null 2>&1
    exitcode=$?
    cd ../..

    if [ $exitcode -eq 0 ]; then
        echo "✓ PostgreSQL konteinerid peatatud ja eemaldatud"
        echo "✓ Volume'd on alles: postgres-user-data, postgres-todo-data"
    else
        echo "⚠️  PostgreSQL konteinrite eemaldamine ebaõnnestus (exitcode: $exitcode)"
        echo "   Võimalik, et konteinerid ei eksisteeri või on juba eemaldatud"
    fi
    echo ""
fi

# =============================================================================
# Lõppsõnum
# =============================================================================
echo ""
echo "=============================================="
echo "✅ Lab 2 setup lõpetatud!"
echo "=============================================="
echo ""

if [ "$DB_INIT_MODE" == "auto" ]; then
    echo "✅ VALMIS! Volume'd on täidetud andmetega!"
    echo ""
    echo "Volume'id sisaldavad nüüd:"
    echo "  ✓ postgres-user-data - users tabel koos 4 kasutajaga"
    echo "  ✓ postgres-todo-data - todos tabel koos 8 todo'ga"
    echo ""
    echo "JÄRGMISED SAMMUD - Alusta harjutusi:"
    echo ""
    echo "1. Käivita stack käsitsi (pedagoogiline):"
    echo "   cd compose-project"
    echo "   docker compose up -d"
    echo ""
    echo "2. Kontrolli teenuste olekut:"
    echo "   docker compose ps"
    echo "   docker compose logs -f"
    echo ""
    echo "3. Testi rakendust:"
    echo "   curl http://localhost:8080                 - Frontend"
    echo "   curl http://localhost:3000/health          - User Service"
    echo "   curl http://localhost:8081/health          - Todo Service"
    echo ""
    echo "4. Vaata andmeid:"
    echo "   docker exec postgres-user psql -U postgres -d user_service_db -c 'SELECT * FROM users;'"
    echo "   docker exec postgres-todo psql -U postgres -d todo_service_db -c 'SELECT * FROM todos;'"
    echo ""
    echo "5. Alusta Harjutus 1'st:"
    echo "   cat exercises/01-compose-basics.md"
    echo ""
else
    echo "JÄRGMISED SAMMUD - Stack'i käivitamine:"
    echo ""
    echo "VARIANT A: Käsitsi DB seadistamine (soovitatud õppimiseks):"
    echo "  cd compose-project"
    echo "  docker compose up -d"
    echo "  # Seejärel järgi Harjutus 1 juhiseid andmebaasi loomiseks"
    echo ""
    echo "VARIANT B: Kui soovid kiire start automaatse DB init'iga:"
    echo "  cd compose-project"
    echo "  docker compose -f docker-compose.yml -f docker-compose.init.yml up -d"
    echo ""
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
fi

echo "=============================================="
echo "Head õppimist! 🚀"
echo "=============================================="
echo ""
