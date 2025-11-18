#!/bin/bash

# Lab 6 Reset Script
# Puhastab kõik Lab 6 (Monitoring & Logging) ressursid ja taastab algseis

echo "====================================================="
echo "Lab 6 (Monitoring & Logging) - Süsteemi Taastamine"
echo "====================================================="
echo ""

# Värvilised väljundid
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kontrolli, kas kubectl on saadaval
KUBECTL_AVAILABLE=false
if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    KUBECTL_AVAILABLE=true
fi

# Kontrolli, kas Docker on saadaval
DOCKER_AVAILABLE=false
if docker info > /dev/null 2>&1; then
    DOCKER_AVAILABLE=true
fi

# Kontrolli, kas Helm on saadaval
HELM_AVAILABLE=false
if command -v helm &> /dev/null; then
    HELM_AVAILABLE=true
fi

echo -e "${YELLOW}🗑️  Eemaldame Lab 6 Monitoring & Logging ressursid...${NC}"

# Kubernetes ressursid
if [ "$KUBECTL_AVAILABLE" = true ]; then
    echo ""
    echo -e "${YELLOW}☸️  Kubernetes ressursid${NC}"

    # Namespace'id
    NAMESPACES=("default" "lab6" "monitoring" "logging")

    for ns in "${NAMESPACES[@]}"; do
        if kubectl get namespace "$ns" &> /dev/null; then
            echo ""
            echo -e "${YELLOW}📦 Namespace: $ns${NC}"

            # Eemalda kõik ressursid
            kubectl delete all --all -n "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ Kõik ressursid namespace'is eemaldatud${NC}"

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
                echo -e "${GREEN}  ✓ PVCs eemaldatud${NC}"
            fi
        fi
    done

    # Eemalda Helm releases
    if [ "$HELM_AVAILABLE" = true ]; then
        echo ""
        echo -e "${YELLOW}📦 Helm releases${NC}"

        # Prometheus
        if helm list -n monitoring 2>/dev/null | grep -q prometheus; then
            helm uninstall prometheus -n monitoring 2>/dev/null
            echo -e "${GREEN}  ✓ Prometheus Helm release eemaldatud${NC}"
        fi

        # Grafana
        if helm list -n monitoring 2>/dev/null | grep -q grafana; then
            helm uninstall grafana -n monitoring 2>/dev/null
            echo -e "${GREEN}  ✓ Grafana Helm release eemaldatud${NC}"
        fi

        # Loki
        if helm list -n logging 2>/dev/null | grep -q loki; then
            helm uninstall loki -n logging 2>/dev/null
            echo -e "${GREEN}  ✓ Loki Helm release eemaldatud${NC}"
        fi

        # Promtail
        if helm list -n logging 2>/dev/null | grep -q promtail; then
            helm uninstall promtail -n logging 2>/dev/null
            echo -e "${GREEN}  ✓ Promtail Helm release eemaldatud${NC}"
        fi
    fi

    # Eemalda namespace'd
    for ns in lab6 monitoring logging; do
        if kubectl get namespace "$ns" &> /dev/null; then
            echo ""
            echo -e "${YELLOW}🗑️  Eemaldame '$ns' namespace...${NC}"
            kubectl delete namespace "$ns" 2>/dev/null
            echo -e "${GREEN}  ✓ $ns namespace eemaldatud${NC}"
        fi
    done

    # Eemalda PVs
    echo ""
    echo -e "${YELLOW}💾 PersistentVolumes${NC}"
    pvs=$(kubectl get pv -o name 2>/dev/null | grep -E "(prometheus|grafana|loki)" || true)
    if [ ! -z "$pvs" ]; then
        echo "$pvs" | xargs -r kubectl delete 2>/dev/null
        echo -e "${GREEN}  ✓ Monitoring/Logging PVs eemaldatud${NC}"
    fi
fi

# Docker Compose monitoring stack
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo ""
    echo -e "${YELLOW}🐳 Docker Compose monitoring stack${NC}"

    # Kontrolli, kas monitoring stack töötab
    if docker ps --format '{{.Names}}' | grep -qE "(prometheus|grafana|loki|promtail)"; then

        # Peata ja eemalda containerid
        for service in prometheus grafana loki promtail node-exporter cadvisor alertmanager; do
            if docker ps -a --format '{{.Names}}' | grep -q "^${service}$"; then
                docker rm -f "$service" 2>/dev/null
                echo -e "${GREEN}  ✓ $service container eemaldatud${NC}"
            fi
        done

        # Eemalda volume'd
        for volume in prometheus-data grafana-data loki-data; do
            if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
                docker volume rm "$volume" 2>/dev/null
                echo -e "${GREEN}  ✓ $volume volume eemaldatud${NC}"
            fi
        done

        # Eemalda network
        if docker network ls --format '{{.Name}}' | grep -q "^monitoring$"; then
            docker network rm monitoring 2>/dev/null
            echo -e "${GREEN}  ✓ monitoring network eemaldatud${NC}"
        fi
    else
        echo -e "${GREEN}  ✓ Docker monitoring stack ei ole käivitatud${NC}"
    fi
fi

# Config failid
echo ""
echo -e "${YELLOW}📝 Config failid${NC}"
if [ -d "configs" ]; then
    echo "  configs/ kaust eksisteerib (jäetakse alles)"
    echo "  Kui soovid puhastada: rm -rf configs/*"
fi

echo ""
echo -e "${YELLOW}🧹 Ootame, kuni ressursid on täielikult eemaldatud...${NC}"
sleep 3

echo ""
echo -e "${GREEN}✅ Lab 6 süsteem on taastatud!${NC}"
echo ""
echo "Saad nüüd alustada Lab 6 harjutustega algusest:"
echo "  1. cd 06-monitoring-logging-lab"
echo "  2. Jätka exercises/ kaustas olevate harjutustega"
echo ""

if [ "$KUBECTL_AVAILABLE" = false ]; then
    echo -e "${YELLOW}⚠️  Märkus: kubectl ei ole saadaval või K8s cluster ei tööta${NC}"
fi

if [ "$HELM_AVAILABLE" = false ]; then
    echo -e "${YELLOW}⚠️  Märkus: Helm ei ole paigaldatud${NC}"
    echo "Paigalda Helm:"
    echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    echo ""
fi

echo "====================================================="
