#!/bin/bash

# Lab 4 Reset Script
# Puhastab kõik Lab 4 (Kubernetes Advanced) ressursid ja taastab algseis

echo "====================================================="
echo "Lab 4 (Kubernetes Advanced) - Süsteemi Taastamine"
echo "====================================================="
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

# Kontrolli, kas Helm on paigaldatud
HELM_INSTALLED=false
if command -v helm &> /dev/null; then
    HELM_INSTALLED=true
fi

echo -e "${YELLOW}🗑️  Eemaldame Lab 4 Kubernetes ressursid...${NC}"

# Namespace'id, mida kasutatakse Lab 4's
NAMESPACES=("default" "lab4" "production" "staging")

for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &> /dev/null; then
        echo ""
        echo -e "${YELLOW}📦 Namespace: $ns${NC}"

        # Eemalda HorizontalPodAutoscalers
        hpas=$(kubectl get hpa -n "$ns" -o name 2>/dev/null | grep -E "(user-service|frontend|backend)" || true)
        if [ ! -z "$hpas" ]; then
            echo "$hpas" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ HorizontalPodAutoscalers eemaldatud${NC}"
        fi

        # Eemalda Ingresses
        ingresses=$(kubectl get ingress -n "$ns" -o name 2>/dev/null)
        if [ ! -z "$ingresses" ]; then
            echo "$ingresses" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Ingresses eemaldatud${NC}"
        fi

        # Eemalda Deployments
        deployments=$(kubectl get deployments -n "$ns" -o name 2>/dev/null)
        if [ ! -z "$deployments" ]; then
            echo "$deployments" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Deployments eemaldatud${NC}"
        fi

        # Eemalda StatefulSets
        statefulsets=$(kubectl get statefulsets -n "$ns" -o name 2>/dev/null)
        if [ ! -z "$statefulsets" ]; then
            echo "$statefulsets" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ StatefulSets eemaldatud${NC}"
        fi

        # Eemalda Services
        services=$(kubectl get services -n "$ns" -o name 2>/dev/null | grep -v "kubernetes" || true)
        if [ ! -z "$services" ]; then
            echo "$services" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Services eemaldatud${NC}"
        fi

        # Eemalda ConfigMaps
        configmaps=$(kubectl get configmaps -n "$ns" -o name 2>/dev/null)
        if [ ! -z "$configmaps" ]; then
            echo "$configmaps" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ ConfigMaps eemaldatud${NC}"
        fi

        # Eemalda Secrets
        secrets=$(kubectl get secrets -n "$ns" -o name 2>/dev/null | grep -v "default-token" || true)
        if [ ! -z "$secrets" ]; then
            echo "$secrets" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Secrets eemaldatud${NC}"
        fi

        # Eemalda PVCs
        pvcs=$(kubectl get pvc -n "$ns" -o name 2>/dev/null)
        if [ ! -z "$pvcs" ]; then
            echo "$pvcs" | xargs -r kubectl delete -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ PersistentVolumeClaims eemaldatud${NC}"
        fi

        # Eemalda Pods
        pods=$(kubectl get pods -n "$ns" -o name 2>/dev/null)
        if [ ! -z "$pods" ]; then
            echo "$pods" | xargs -r kubectl delete -n "$ns" --force --grace-period=0 2>/dev/null
            echo -e "${GREEN}  ✓ Pods eemaldatud${NC}"
        fi
    fi
done

# Eemalda Helm releases, kui Helm on paigaldatud
if [ "$HELM_INSTALLED" = true ]; then
    echo ""
    echo -e "${YELLOW}📦 Eemaldame Helm releases...${NC}"

    for ns in "${NAMESPACES[@]}"; do
        releases=$(helm list -n "$ns" -q 2>/dev/null || true)
        if [ ! -z "$releases" ]; then
            echo "$releases" | xargs -r -I {} helm uninstall {} -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Helm releases namespace'is $ns eemaldatud${NC}"
        fi
    done
fi

# Eemalda PersistentVolumes
echo ""
echo -e "${YELLOW}💾 Eemaldame PersistentVolumes...${NC}"
pvs=$(kubectl get pv -o name 2>/dev/null | grep -E "(lab4|app)" || true)
if [ ! -z "$pvs" ]; then
    echo "$pvs" | xargs -r kubectl delete 2>/dev/null
    echo -e "${GREEN}  ✓ PersistentVolumes eemaldatud${NC}"
fi

# Eemalda lab4 namespace
if kubectl get namespace lab4 &> /dev/null; then
    echo ""
    echo -e "${YELLOW}🗑️  Eemaldame 'lab4' namespace...${NC}"
    kubectl delete namespace lab4 2>/dev/null
    echo -e "${GREEN}  ✓ lab4 namespace eemaldatud${NC}"
fi

# Eemalda staging namespace
if kubectl get namespace staging &> /dev/null; then
    echo ""
    echo -e "${YELLOW}🗑️  Eemaldame 'staging' namespace...${NC}"
    kubectl delete namespace staging 2>/dev/null
    echo -e "${GREEN}  ✓ staging namespace eemaldatud${NC}"
fi

echo ""
echo -e "${YELLOW}🧹 Ootame, kuni ressursid on täielikult eemaldatud...${NC}"
sleep 3

echo ""
echo -e "${GREEN}✅ Lab 4 süsteem on taastatud!${NC}"
echo ""
echo "Saad nüüd alustada Lab 4 harjutustega algusest:"
echo "  1. cd 04-kubernetes-advanced-lab"
echo "  2. Jätka exercises/ kaustas olevate harjutustega"
echo ""
if [ "$HELM_INSTALLED" = false ]; then
    echo -e "${YELLOW}⚠️  Märkus: Helm ei ole paigaldatud. Lab 4 vajab Helm'i.${NC}"
    echo "Paigalda Helm:"
    echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    echo ""
fi
echo "====================================================="
