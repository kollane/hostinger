#!/bin/bash

# Labor 4: Kubernetes Täiustatud - Automaatne Setup Script

set -e

echo "========================================="
echo "  Labor 4: Kubernetes Täiustatud - Setup"
echo "========================================="
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. Check cluster
echo "1️⃣  Kontrollin Kubernetes cluster'i..."
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ Cluster on kättesaadav${NC}"
    kubectl get nodes
else
    echo -e "${RED}❌ Cluster pole kättesaadav!${NC}"
    echo "Käivita esmalt Lab 3 setup:"
    echo "  cd ../03-kubernetes-basics-lab"
    echo "  ./setup.sh"
    exit 1
fi
echo ""

# 2. Check Lab 3 deployments
echo "2️⃣  Kontrollin Lab 3 deploymente..."
DEPLOYMENTS=$(kubectl get deployments 2>/dev/null | wc -l)

if [ $DEPLOYMENTS -gt 1 ]; then
    echo -e "${GREEN}✅ Lab 3 deployments on olemas${NC}"
    kubectl get deployments
else
    warn "Lab 3 deployments puuduvad"
    echo ""
    read -p "Kas soovid Lab 3 setup'i käivitada? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd ../03-kubernetes-basics-lab
        ./setup.sh
        cd ../04-kubernetes-advanced-lab
    else
        echo "Jätka käsitsi."
    fi
fi
echo ""

# 3. Check Helm
echo "3️⃣  Kontrollin Helm'i..."
if command -v helm &> /dev/null; then
    HELM_VERSION=$(helm version --short)
    echo -e "${GREEN}✅ Helm on paigaldatud ($HELM_VERSION)${NC}"
else
    warn "Helm pole paigaldatud"
    echo ""
    read -p "Kas soovid Helm'i paigaldada? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Paigaldan Helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        echo -e "${GREEN}✅ Helm paigaldatud${NC}"
    else
        echo "Paigalda Helm käsitsi:"
        echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
        exit 1
    fi
fi
echo ""

# 4. Choose learning path
echo "4️⃣  Vali õppetee..."
echo ""
echo "Selles laboris on kaks õppeteed:"
echo ""
echo "  Path A (6h): Algaja - DNS + Nginx + K8s Ingress + SSL + Helm + HPA"
echo "  Path B (4h): Kogenud - K8s Ingress + SSL + Helm + HPA"
echo ""
read -p "Vali path (A/B): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Aa]$ ]]; then
    info "Valisid Path A - Algaja tee (6h)"
    echo "Alusta harjutus 01-st: cat exercises/01-dns-nginx-proxy.md"
elif [[ $REPLY =~ ^[Bb]$ ]]; then
    info "Valisid Path B - Kogenud tee (4h)"
    echo "Alusta harjutus 02-st: cat exercises/02-kubernetes-ingress.md"
else
    warn "Vigane valik. Vali hiljem käsitsi."
fi
echo ""

# Summary
echo "========================================="
echo "  ✅ Setup Valmis!"
echo "========================================="
echo ""
echo "Eeldused on täidetud!"
echo ""
echo "Järgmised sammud:"
echo "  Path A: cat exercises/01-dns-nginx-proxy.md"
echo "  Path B: cat exercises/02-kubernetes-ingress.md"
echo ""
echo "Edu laboriga! 🚀"
