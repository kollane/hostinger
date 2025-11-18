#!/bin/bash

# Labor 6: Monitoring & Logging - Automaatne Setup Script

set -e

echo "========================================="
echo "  Labor 6: Monitoring & Logging - Setup"
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

# 1. Check kubectl
echo "1️⃣  Kontrollin kubectl..."
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✅ kubectl on paigaldatud${NC}"
else
    echo -e "${RED}❌ kubectl pole paigaldatud!${NC}"
    echo "Käivita Lab 3 setup esmalt."
    exit 1
fi
echo ""

# 2. Check cluster
echo "2️⃣  Kontrollin Kubernetes cluster'i..."
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ Cluster on kättesaadav${NC}"
    kubectl get nodes
else
    echo -e "${RED}❌ Cluster pole kättesaadav!${NC}"
    echo "Käivita Lab 3 setup:"
    echo "  cd ../03-kubernetes-basics-lab && ./setup.sh"
    exit 1
fi
echo ""

# 3. Check running applications
echo "3️⃣  Kontrollin töötavaid rakendusi..."
DEPLOYMENTS=$(kubectl get deployments 2>/dev/null | wc -l)

if [ $DEPLOYMENTS -gt 1 ]; then
    echo -e "${GREEN}✅ Rakendused töötavad cluster'is${NC}"
    kubectl get deployments
else
    warn "Rakendused puuduvad cluster'is"
    echo ""
    read -p "Kas soovid Lab 3 komponendid deploy'da? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd ../03-kubernetes-basics-lab
        ./setup.sh
        cd ../06-monitoring-logging-lab
    else
        warn "Ilma rakendusteta pole midagi monitoorida!"
        echo "Deploy rakendused hiljem käsitsi."
    fi
fi
echo ""

# 4. Check Helm
echo "4️⃣  Kontrollin Helm'i..."
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
        echo "Paigalda Helm käsitsi (vajalik Prometheus/Grafana jaoks):"
        echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
        exit 1
    fi
fi
echo ""

# 5. Check RAM
echo "5️⃣  Kontrollin vaba RAM-i..."
AVAILABLE_RAM=$(free -g | awk 'NR==2 {print $7}')
if [ "$AVAILABLE_RAM" -ge 2 ]; then
    echo -e "${GREEN}✅ Vaba RAM: ${AVAILABLE_RAM}GB (piisav)${NC}"
else
    warn "Vaba RAM: ${AVAILABLE_RAM}GB"
    echo "Prometheus + Grafana võib vajada 2GB+ RAM-i"
    echo "Kaaluge monitoring stack'i lightweight versiooni."
fi
echo ""

# 6. Add Helm repos
echo "6️⃣  Lisan Helm repositooriumid..."
if command -v helm &> /dev/null; then
    info "Lisan prometheus-community repo..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true

    info "Lisan grafana repo..."
    helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true

    helm repo update
    echo -e "${GREEN}✅ Helm repod lisatud${NC}"
fi
echo ""

# Summary
echo "========================================="
echo "  ✅ Setup Valmis!"
echo "========================================="
echo ""
echo "Kõik eeldused on täidetud!"
echo ""
echo "Monitoring stack komponendid on valmis paigaldamiseks:"
echo "  - Prometheus (metrics collection)"
echo "  - Grafana (visualization)"
echo "  - Alertmanager (alerting)"
echo ""
echo "Järgmised sammud:"
echo "  1. Alusta harjutus 1'st (Prometheus):"
echo "     cat exercises/01-prometheus-setup.md"
echo ""
echo "  2. Kiirpaigaldus (preview):"
echo "     helm install prometheus prometheus-community/kube-prometheus-stack"
echo ""
echo "Edu laboriga! 🚀"
