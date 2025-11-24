#!/bin/bash

# Lab 2 Reset Script
# Puhastab kõik Lab 2 (Docker Compose) ressursid ja taastab algseis

echo "=============================================="
echo "Lab 2 (Docker Compose) - Süsteemi Taastamine"
echo "=============================================="
echo ""

# Kontrolli, kas Docker töötab
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker ei tööta! Palun käivita Docker esmalt."
    exit 1
fi

# Kontrolli, kas docker compose on saadaval
if ! docker compose version > /dev/null 2>&1; then
    echo "❌ Docker Compose ei ole saadaval!"
    exit 1
fi

echo "⚠️  HOIATUS: See kustutab KÕIK Lab 2 ressursid:"
echo "  - Compose rakendused (kõik docker-compose.yml failid)"
echo "  - Containerid: user-service, frontend, todo-service, postgres"
echo "  - Image'd: user-service:*, frontend:*, todo-service:*"
echo "  - Network'id: app-network, fullstack-network"
echo "  - Volume'd: postgres-data, postgres-*-data"
echo ""
read -p "Kas oled kindel, et soovid jätkata? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Tühistatud."
    exit 0
fi
echo ""

echo "🛑 Peatame kõik Docker Compose rakendused..."

# Peata ja eemalda compose ressursid solutions kaustast
if [ -d "solutions" ]; then
    for compose_dir in solutions/*/; do
        if [ -f "${compose_dir}docker-compose.yml" ]; then
            echo "  Peatame ${compose_dir}..."
            (cd "$compose_dir" && docker compose down -v 2>/dev/null)
        fi
    done
fi

# Kui kasutaja on ise compose faile loonud
for compose_file in docker-compose.yml docker-compose.*.yml; do
    if [ -f "$compose_file" ]; then
        echo "  Peatame $compose_file..."
        docker compose -f "$compose_file" down -v 2>/dev/null
    fi
done

echo ""
echo "🗂️  Eemaldame compose-project kataloogi..."

# Kustuta compose-project kataloog, kuna Harjutus 1 Samm 2 käseb selle luua
if [ -d "compose-project" ]; then
    rm -rf compose-project
    echo "  ✓ compose-project kataloog eemaldatud"
else
    echo "  ⏭  compose-project kataloogi ei leitud (juba puhas)"
fi

echo ""
echo "📦 Eemaldame Lab 2 containerid..."

# Eemalda compose containerid (kasutavad tavaliselt prefixeid)
for prefix in 02-docker-compose fullstack-app backend frontend todos userservice; do
    containers=$(docker ps -a --format '{{.Names}}' | grep "^${prefix}" || true)
    if [ ! -z "$containers" ]; then
        echo "$containers" | xargs -r docker rm -f 2>/dev/null
        echo "  ✓ ${prefix}* containerid eemaldatud"
    fi
done

# Eemalda ka üksikud containerid, mis võivad olla
for container in postgres postgres-todo postgres-user user-service frontend todo-service; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        docker rm -f "$container" 2>/dev/null
        echo "  ✓ $container eemaldatud"
    fi
done

echo ""
echo "🗑️  Kas kustutada ka Docker image'd?"
echo ""
echo "Image'd võtavad ~600MB ruumi, aga nende taasehitamine võtab 5-10 minutit."
echo "(user-service:1.0-optimized, todo-service:1.0-optimized)"
echo ""
read -p "Kas kustutada image'd? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Eemaldame Docker image'd..."

    # Eemalda user-service, frontend, todo-service image'd
    for image_prefix in user-service frontend todo-service fullstack; do
        images=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep "^${image_prefix}" || true)
        if [ ! -z "$images" ]; then
            echo "$images" | xargs -r docker rmi -f 2>/dev/null
            echo "  ✓ ${image_prefix}* image'd eemaldatud"
        fi
    done
else
    echo "⏭  Image'd jäetakse alles (säästab taasehitamise aega)"
fi

echo ""
echo "🔌 Eemaldame Lab 2 network'id..."

# Eemalda compose network'id
for network in todo-network app-network fullstack-network backend-network frontend-network; do
    if docker network ls --format '{{.Name}}' | grep -q "^${network}$"; then
        docker network rm "$network" 2>/dev/null
        echo "  ✓ $network eemaldatud"
    fi
done

# Eemalda compose projektide network'id (tavaliselt algavad projekti nimega)
for prefix in 02-docker-compose fullstack; do
    networks=$(docker network ls --format '{{.Name}}' | grep "^${prefix}" || true)
    if [ ! -z "$networks" ]; then
        echo "$networks" | xargs -r docker network rm 2>/dev/null
        echo "  ✓ ${prefix}* network'id eemaldatud"
    fi
done

echo ""
echo "💾 Eemaldame Lab 2 volume'd..."

# Eemalda named volume'd
for volume in postgres-user-data postgres-todo-data postgres-data postgres-users-data postgres-todos-data db-data; do
    if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
        docker volume rm "$volume" 2>/dev/null
        echo "  ✓ $volume eemaldatud"
    fi
done

# Eemalda compose volume'd (tavaliselt projekti nimega)
for prefix in 02-docker-compose fullstack; do
    volumes=$(docker volume ls --format '{{.Name}}' | grep "^${prefix}" || true)
    if [ ! -z "$volumes" ]; then
        echo "$volumes" | xargs -r docker volume rm 2>/dev/null
        echo "  ✓ ${prefix}* volume'd eemaldatud"
    fi
done

echo ""
echo "🧹 Puhastame kasutamata ressursse..."

docker system prune -f > /dev/null 2>&1
echo "  ✓ Kasutamata ressursid eemaldatud"

echo ""
echo "✅ Lab 2 süsteem on taastatud!"
echo ""
echo "Saad nüüd alustada Lab 2 harjutustega algusest:"
echo "  1. cd 02-docker-compose-lab"
echo "  2. Jätka exercises/ kaustas olevate harjutustega"
echo ""
echo "=============================================="
