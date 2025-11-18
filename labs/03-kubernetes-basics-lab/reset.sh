#!/bin/bash

# Lab 3 Reset Script
# Puhastab kõik Lab 3 (Kubernetes Basics) ressursid ja taastab algseis

echo "=================================================="
echo "Lab 3 (Kubernetes Basics) - Süsteemi Taastamine"
echo "=================================================="
echo ""

# Värvilised väljundid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kontrolli, kas kubectl on saadaval
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl ei ole paigaldatud!${NC}"
    echo "Paigalda kubectl esmalt:"
    echo "  curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    echo "  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
    exit 1
fi

# Kontrolli, kas Kubernetes cluster töötab
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Kubernetes cluster ei ole kättesaadav!${NC}"
    echo "Palun veendu, et K8s cluster töötab (Minikube, K3s, või muu)"
    exit 1
fi

echo -e "${YELLOW}🗑️  Eemaldame Lab 3 Kubernetes ressursid...${NC}"

# Namespace'id, mida kasutatakse Lab 3's
NAMESPACES=("default" "lab3" "development" "production")

for ns in "${NAMESPACES[@]}"; do
    # Kontrolli, kas namespace eksisteerib
    if kubectl get namespace "$ns" &> /dev/null; then
        echo ""
        echo -e "${YELLOW}📦 Namespace: $ns${NC}"

        # Eemalda Deployments
        deployments=$(kubectl get deployments -n "$ns" -o name 2>/dev/null | grep -E "(user-service|postgres|frontend|todo)" || true)
        if [ ! -z "$deployments" ]; then
            echo "$deployments" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Deployments eemaldatud${NC}"
        fi

        # Eemalda StatefulSets
        statefulsets=$(kubectl get statefulsets -n "$ns" -o name 2>/dev/null | grep -E "(postgres|database)" || true)
        if [ ! -z "$statefulsets" ]; then
            echo "$statefulsets" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ StatefulSets eemaldatud${NC}"
        fi

        # Eemalda Services
        services=$(kubectl get services -n "$ns" -o name 2>/dev/null | grep -E "(user-service|postgres|frontend|todo)" || true)
        if [ ! -z "$services" ]; then
            echo "$services" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Services eemaldatud${NC}"
        fi

        # Eemalda ConfigMaps
        configmaps=$(kubectl get configmaps -n "$ns" -o name 2>/dev/null | grep -E "(user-service|postgres|app)" || true)
        if [ ! -z "$configmaps" ]; then
            echo "$configmaps" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ ConfigMaps eemaldatud${NC}"
        fi

        # Eemalda Secrets
        secrets=$(kubectl get secrets -n "$ns" -o name 2>/dev/null | grep -E "(user-service|postgres|db|jwt)" || true)
        if [ ! -z "$secrets" ]; then
            echo "$secrets" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Secrets eemaldatud${NC}"
        fi

        # Eemalda PersistentVolumeClaims
        pvcs=$(kubectl get pvc -n "$ns" -o name 2>/dev/null | grep -E "(postgres|database|data)" || true)
        if [ ! -z "$pvcs" ]; then
            echo "$pvcs" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ PersistentVolumeClaims eemaldatud${NC}"
        fi

        # Eemalda Pods (kui on jäänud)
        pods=$(kubectl get pods -n "$ns" -o name 2>/dev/null | grep -E "(user-service|postgres|frontend|todo)" || true)
        if [ ! -z "$pods" ]; then
            echo "$pods" | xargs -r kubectl delete -n "$ns" --force --grace-period=0 2>/dev/null
            echo -e "${GREEN}  ✓ Pods eemaldatud${NC}"
        fi
    fi
done

echo ""
echo -e "${YELLOW}💾 Eemaldame PersistentVolumes (kui on)...${NC}"

# Eemalda PersistentVolumes
pvs=$(kubectl get pv -o name 2>/dev/null | grep -E "(postgres|database|lab3)" || true)
if [ ! -z "$pvs" ]; then
    echo "$pvs" | xargs -r kubectl delete 2>/dev/null
    echo -e "${GREEN}  ✓ PersistentVolumes eemaldatud${NC}"
fi

# Eemalda lab3 namespace, kui see loodi
if kubectl get namespace lab3 &> /dev/null; then
    echo ""
    echo -e "${YELLOW}🗑️  Eemaldame 'lab3' namespace...${NC}"
    kubectl delete namespace lab3 2>/dev/null
    echo -e "${GREEN}  ✓ lab3 namespace eemaldatud${NC}"
fi

echo ""
echo -e "${YELLOW}🧹 Ootame, kuni ressursid on täielikult eemaldatud...${NC}"
sleep 3

echo ""
echo -e "${GREEN}✅ Lab 3 süsteem on taastatud!${NC}"
echo ""
echo "Saad nüüd alustada Lab 3 harjutustega algusest:"
echo "  1. cd 03-kubernetes-basics-lab"
echo "  2. Jätka exercises/ kaustas olevate harjutustega"
echo ""
echo "Kubernetes cluster staatus:"
kubectl cluster-info
echo ""
echo "=================================================="
