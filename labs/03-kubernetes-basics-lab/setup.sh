#!/bin/bash

# Labor 3: Kubernetes Alused - Automaatne Setup Script
# Seadistab K8s cluster'i ja laeb Lab 1 image'd

set -e  # Exit on error

echo "========================================="
echo "  Labor 3: Kubernetes Alused - Setup"
echo "========================================="
echo ""

# Colors
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
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | grep "Client Version" | awk '{print $3}')
    echo -e "${GREEN}✅ kubectl on paigaldatud${NC}"
else
    echo -e "${RED}❌ kubectl pole paigaldatud!${NC}"
    echo ""
    echo "Paigalda kubectl:"
    echo '  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"'
    echo '  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl'
    exit 1
fi
echo ""

# 2. Check for existing cluster
echo "2️⃣  Kontrollin Kubernetes cluster'i..."

CLUSTER_TYPE=""
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    CLUSTER_TYPE="minikube"
    echo -e "${GREEN}✅ Minikube cluster on juba käivitatud${NC}"
elif command -v k3s &> /dev/null; then
    CLUSTER_TYPE="k3s"
    echo -e "${GREEN}✅ K3s on paigaldatud${NC}"
elif kubectl cluster-info &> /dev/null; then
    CLUSTER_TYPE="other"
    echo -e "${GREEN}✅ Kubernetes cluster on kättesaadav${NC}"
else
    warn "Kubernetes cluster pole käivitatud"
    echo ""
    echo "Vali Kubernetes platvorm:"
    echo "  1) Minikube (soovitatud algajatele)"
    echo "  2) K3s (lightweight, VPS-is)"
    echo "  3) Mul on juba cluster (jätka)"
    echo ""
    read -p "Vali variant (1/2/3): " -n 1 -r
    echo ""

    case $REPLY in
        1)
            CLUSTER_TYPE="minikube"
            info "Käivitan Minikube..."

            if ! command -v minikube &> /dev/null; then
                echo "Paigaldan Minikube..."
                curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
                sudo install minikube-linux-amd64 /usr/local/bin/minikube
                rm minikube-linux-amd64
            fi

            minikube start --cpus=2 --memory=4096
            echo -e "${GREEN}✅ Minikube käivitatud${NC}"
            ;;
        2)
            CLUSTER_TYPE="k3s"
            info "Paigaldan K3s..."

            curl -sfL https://get.k3s.io | sh -

            # Setup kubeconfig
            mkdir -p ~/.kube
            sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
            sudo chown $USER ~/.kube/config

            echo -e "${GREEN}✅ K3s paigaldatud ja konfigureeritud${NC}"
            ;;
        3)
            CLUSTER_TYPE="other"
            echo -e "${GREEN}✅ Kasutan olemasolevat cluster'it${NC}"
            ;;
        *)
            echo -e "${RED}❌ Vigane valik${NC}"
            exit 1
            ;;
    esac
fi
echo ""

# 3. Verify cluster is accessible
echo "3️⃣  Kontrollin cluster'i ühendust..."
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}✅ Cluster on kättesaadav${NC}"
    kubectl get nodes
else
    echo -e "${RED}❌ Cluster pole kättesaadav!${NC}"
    exit 1
fi
echo ""

# 4. Check Lab 1 images locally
echo "4️⃣  Kontrollin Lab 1 image'ite olemasolu..."
MISSING_IMAGES=()

if ! docker images | grep -q "user-service.*1.0"; then
    MISSING_IMAGES+=("user-service:1.0")
fi

if ! docker images | grep -q "frontend.*1.0"; then
    MISSING_IMAGES+=("frontend:1.0")
fi

if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
    warn "Puuduvad image'd lokaalselt: ${MISSING_IMAGES[*]}"
    echo ""

    read -p "Kas soovid puuduvaid image'e build'ida? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Build missing images
        if [[ " ${MISSING_IMAGES[@]} " =~ "user-service:1.0" ]]; then
            echo "📦 Build'in user-service:1.0..."
            cd ../apps/backend-nodejs
            docker build -t user-service:1.0 .
            cd - > /dev/null
        fi

        if [[ " ${MISSING_IMAGES[@]} " =~ "frontend:1.0" ]]; then
            echo "📦 Build'in frontend:1.0..."
            cd ../apps/frontend
            docker build -t frontend:1.0 .
            cd - > /dev/null
        fi

        echo -e "${GREEN}✅ Image'd build'itud${NC}"
    else
        echo -e "${RED}Image'd on vajalikud. Palun build'i need käsitsi.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Kõik vajalikud image'd on olemas lokaalselt${NC}"
fi
echo ""

# 5. Load images into cluster
echo "5️⃣  Laen image'd Kubernetes cluster'isse..."

case $CLUSTER_TYPE in
    minikube)
        info "Laen image'd Minikube'sse..."
        eval $(minikube docker-env)

        # Rebuild images in Minikube environment
        cd ../apps/backend-nodejs
        docker build -t user-service:1.0 . &> /dev/null
        cd ../frontend
        docker build -t frontend:1.0 . &> /dev/null
        cd - > /dev/null

        eval $(minikube docker-env -u)
        echo -e "${GREEN}✅ Image'd laetud Minikube'sse${NC}"
        ;;

    k3s)
        info "Importen image'd K3s'i..."

        # Save and import images
        docker save user-service:1.0 > /tmp/user-service-1.0.tar
        sudo k3s ctr images import /tmp/user-service-1.0.tar
        rm /tmp/user-service-1.0.tar

        docker save frontend:1.0 > /tmp/frontend-1.0.tar
        sudo k3s ctr images import /tmp/frontend-1.0.tar
        rm /tmp/frontend-1.0.tar

        echo -e "${GREEN}✅ Image'd imporditud K3s'i${NC}"
        ;;

    other)
        warn "Kasutad custom cluster'it - image'd peavad olema registry's"
        echo "Kui kasutad local registry't, lae image'd sinna käsitsi."
        ;;
esac
echo ""

# 6. Test cluster with simple pod
echo "6️⃣  Testin cluster'it nginx pod'iga..."
kubectl run test-nginx --image=nginx --restart=Never --dry-run=client -o yaml | kubectl apply -f - &> /dev/null || true
sleep 3

if kubectl get pod test-nginx &> /dev/null; then
    echo -e "${GREEN}✅ Test pod loodud edukalt${NC}"
    kubectl delete pod test-nginx &> /dev/null || true
else
    warn "Test pod'i loomine ebaõnnestus (see võib olla normaalne)"
fi
echo ""

# Summary
echo "========================================="
echo "  ✅ Setup Valmis!"
echo "========================================="
echo ""
echo "Kubernetes cluster on valmis!"
echo ""
echo "Cluster info:"
kubectl cluster-info
echo ""
echo "Nodes:"
kubectl get nodes
echo ""
echo "Järgmised sammud:"
echo "  1. Alusta harjutus 1'st (Pods):"
echo "     cat exercises/01-pods.md"
echo ""
echo "  2. Kiirsõnumid:"
echo "     kubectl get nodes          # Vaata node'e"
echo "     kubectl get pods           # Vaata pod'e"
echo "     kubectl get all            # Vaata kõiki ressursse"
echo ""
echo "Edu laboriga! 🚀"
