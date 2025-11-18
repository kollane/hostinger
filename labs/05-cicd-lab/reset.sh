#!/bin/bash

# Lab 5 Reset Script
# Puhastab kõik Lab 5 (CI/CD) ressursid ja taastab algseis

echo "========================================"
echo "Lab 5 (CI/CD) - Süsteemi Taastamine"
echo "========================================"
echo ""

# Värvilised väljundid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kontrolli, kas kubectl on saadaval
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl ei ole paigaldatud!${NC}"
    exit 1
fi

# Kontrolli, kas Kubernetes cluster töötab
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Kubernetes cluster ei ole kättesaadav!${NC}"
    exit 1
fi

echo -e "${YELLOW}🗑️  Eemaldame Lab 5 Kubernetes ressursid...${NC}"

# Namespace'id, mida kasutatakse Lab 5's (dev, staging, production)
NAMESPACES=("default" "lab5" "dev" "development" "staging" "production")

for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        echo ""
        echo -e "${YELLOW}📦 Namespace: $ns${NC}"

        # Eemalda kõik ressursid namespace'is
        # (CI/CD lab võib luua erinevaid ressursse)

        # Deployments
        deployments=$(kubectl get deployments -n "$ns" -o name 2>/dev/null)
        if [ ! -z "$deployments" ]; then
            echo "$deployments" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Deployments eemaldatud${NC}"
        fi

        # Services
        services=$(kubectl get services -n "$ns" -o name 2>/dev/null | grep -v "kubernetes" || true)
        if [ ! -z "$services" ]; then
            echo "$services" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Services eemaldatud${NC}"
        fi

        # ConfigMaps
        configmaps=$(kubectl get configmaps -n "$ns" -o name 2>/dev/null)
        if [ ! -z "$configmaps" ]; then
            echo "$configmaps" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ ConfigMaps eemaldatud${NC}"
        fi

        # Secrets
        secrets=$(kubectl get secrets -n "$ns" -o name 2>/dev/null | grep -v "default-token" || true)
        if [ ! -z "$secrets" ]; then
            echo "$secrets" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Secrets eemaldatud${NC}"
        fi

        # Pods
        pods=$(kubectl get pods -n "$ns" -o name 2>/dev/null)
        if [ ! -z "$pods" ]; then
            echo "$pods" | xargs -r kubectl delete -n "$ns" --force --grace-period=0 2>/dev/null
            echo -e "${GREEN}  ✓ Pods eemaldatud${NC}"
        fi
    fi
done

# Eemalda CI/CD spetsiifilised namespace'd
for ns in lab5 dev staging; do
    if kubectl get namespace "$ns" &> /dev/null; then
        echo ""
        echo -e "${YELLOW}🗑️  Eemaldame '$ns' namespace...${NC}"
        kubectl delete namespace "$ns" 2>/dev/null
        echo -e "${GREEN}  ✓ $ns namespace eemaldatud${NC}"
    fi
done

# Puhasta Docker ressursid (CI/CD builds)
if docker info > /dev/null 2>&1; then
    echo ""
    echo -e "${YELLOW}🐳 Puhastame Docker ressursse...${NC}"

    # Eemalda CI/CD build image'd
    images=$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E "^(user-service|frontend|todo-service):" || true)
    if [ ! -z "$images" ]; then
        echo "$images" | xargs -r docker rmi -f 2>/dev/null
        echo -e "${GREEN}  ✓ CI/CD build image'd eemaldatud${NC}"
    fi

    # Puhasta dangling image'd
    docker image prune -f > /dev/null 2>&1
    echo -e "${GREEN}  ✓ Dangling image'd eemaldatud${NC}"
fi

# GitHub Actions workflow failide info
echo ""
echo -e "${YELLOW}ℹ️  GitHub Actions workflow failid${NC}"
if [ -d ".github/workflows" ]; then
    echo -e "${YELLOW}  .github/workflows/ kaust eksisteerib${NC}"
    echo "  Kui soovid eemaldada workflow faile:"
    echo "    rm -rf .github/workflows/*"
else
    echo -e "${GREEN}  ✓ Workflow faile ei leitud${NC}"
fi

echo ""
echo -e "${YELLOW}🧹 Ootame, kuni ressursid on täielikult eemaldatud...${NC}"
sleep 2

echo ""
echo -e "${GREEN}✅ Lab 5 süsteem on taastatud!${NC}"
echo ""
echo "Saad nüüd alustada Lab 5 harjutustega algusest:"
echo "  1. cd 05-cicd-lab"
echo "  2. Jätka exercises/ kaustas olevate harjutustega"
echo ""
echo -e "${YELLOW}⚠️  Märkus: GitHub Actions workflow'd${NC}"
echo "  - Workflow failid .github/workflows/ kaustas jäävad alles"
echo "  - GitHub Secrets tuleb seadistada GitHubi veebiliideses"
echo "  - Docker Registry credentials tuleb uuesti sisestada"
echo ""
echo "========================================"
