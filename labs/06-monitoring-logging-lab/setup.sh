#!/bin/bash

# ==========================================================================
# Lab 6: Monitoring & Logging - Setup Script
# ==========================================================================
# This script validates your environment for Lab 6
# Prerequisites: Lab 1-5 completed, especially Lab 5 (CI/CD)
# ==========================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Lab 6: Monitoring & Logging - Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ==========================================================================
# Function: Check command exists
# ==========================================================================
check_command() {
  local cmd=$1
  local required=$2

  if command -v "$cmd" &> /dev/null; then
    local version=$($cmd --version 2>&1 | head -n1)
    echo -e "${GREEN}✓${NC} $cmd is installed: $version"
    return 0
  else
    if [[ "$required" == "true" ]]; then
      echo -e "${RED}✗${NC} $cmd is NOT installed (REQUIRED)"
      return 1
    else
      echo -e "${YELLOW}⚠${NC} $cmd is NOT installed (optional)"
      return 0
    fi
  fi
}

# ==========================================================================
# 1. Check Prerequisites
# ==========================================================================
echo -e "${BLUE}1. Checking Prerequisites...${NC}"
echo ""

PREREQ_OK=true

# Required tools
check_command "kubectl" "true" || PREREQ_OK=false
check_command "helm" "true" || PREREQ_OK=false
check_command "jq" "false"
check_command "curl" "true" || PREREQ_OK=false

echo ""

if [[ "$PREREQ_OK" == "false" ]]; then
  echo -e "${RED}✗ Missing required prerequisites!${NC}"
  echo ""
  echo "Install missing tools:"
  echo "  - kubectl: curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  echo "  - helm: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
  exit 1
fi

# ==========================================================================
# 2. Check Kubernetes Cluster
# ==========================================================================
echo -e "${BLUE}2. Checking Kubernetes Cluster...${NC}"
echo ""

if kubectl cluster-info &> /dev/null; then
  echo -e "${GREEN}✓${NC} Kubernetes cluster is reachable"

  CONTEXT=$(kubectl config current-context)
  echo "  Current context: $CONTEXT"

  NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  echo "  Nodes: $NODE_COUNT"
else
  echo -e "${RED}✗${NC} Cannot connect to Kubernetes cluster"
  echo ""
  echo "Make sure:"
  echo "  1. Kubernetes cluster is running"
  echo "  2. kubectl is configured (~/.kube/config)"
  echo "  3. You have permissions to access the cluster"
  exit 1
fi

echo ""

# ==========================================================================
# 3. Check Helm
# ==========================================================================
echo -e "${BLUE}3. Checking Helm...${NC}"
echo ""

HELM_VERSION=$(helm version --short 2>/dev/null || echo "")

if [[ -n "$HELM_VERSION" ]]; then
  echo -e "${GREEN}✓${NC} Helm is installed: $HELM_VERSION"
else
  echo -e "${RED}✗${NC} Helm is NOT installed"
  echo ""
  echo "Install Helm 3:"
  echo "  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
  exit 1
fi

echo ""

# ==========================================================================
# 4. Check Lab 5 Prerequisites
# ==========================================================================
echo -e "${BLUE}4. Checking Lab 5 Prerequisites (Deployed Applications)...${NC}"
echo ""

LAB5_OK=true

# Check namespaces
for ns in development staging production; do
  if kubectl get namespace "$ns" &> /dev/null; then
    echo -e "${GREEN}✓${NC} Namespace '$ns' exists"

    # Check if user-service is deployed
    if kubectl get deployment user-service -n "$ns" &> /dev/null; then
      REPLICAS=$(kubectl get deployment user-service -n "$ns" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
      if [[ "$REPLICAS" -gt 0 ]]; then
        echo -e "  ${GREEN}✓${NC} user-service deployed ($REPLICAS replicas)"
      else
        echo -e "  ${YELLOW}⚠${NC} user-service exists but no replicas available"
        LAB5_OK=false
      fi
    else
      echo -e "  ${RED}✗${NC} user-service NOT found in $ns"
      LAB5_OK=false
    fi
  else
    echo -e "${RED}✗${NC} Namespace '$ns' does NOT exist"
    LAB5_OK=false
  fi
done

echo ""

if [[ "$LAB5_OK" == "false" ]]; then
  echo -e "${YELLOW}⚠ Lab 5 applications not fully deployed${NC}"
  echo ""
  echo "Lab 6 requires user-service deployed in all environments (dev, staging, prod)."
  echo "Please complete Lab 5 first, or at minimum deploy user-service to all namespaces."
  echo ""
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# ==========================================================================
# 5. Check Available Resources
# ==========================================================================
echo -e "${BLUE}5. Checking Available Resources...${NC}"
echo ""

# Check memory
TOTAL_MEM=$(kubectl top nodes 2>/dev/null | awk 'NR>1 {sum+=$5} END {print sum}' || echo "0")

if [[ "$TOTAL_MEM" != "0" ]]; then
  echo -e "${GREEN}✓${NC} Metrics server is available"
  echo "  Cluster memory usage can be monitored"
else
  echo -e "${YELLOW}⚠${NC} Metrics server not available (kubectl top nodes fails)"
  echo "  Install metrics-server for resource monitoring:"
  echo "  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
fi

echo ""

# ==========================================================================
# 6. Create Monitoring Namespace
# ==========================================================================
echo -e "${BLUE}6. Creating Monitoring Namespace...${NC}"
echo ""

if kubectl get namespace monitoring &> /dev/null; then
  echo -e "${YELLOW}⚠${NC} Namespace 'monitoring' already exists"
  echo "  Checking for existing Prometheus/Grafana..."

  if kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus &> /dev/null 2>&1; then
    PROM_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers | wc -l)
    if [[ "$PROM_PODS" -gt 0 ]]; then
      echo -e "  ${YELLOW}⚠${NC} Prometheus may already be installed ($PROM_PODS pods)"
    fi
  fi

  if kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana &> /dev/null 2>&1; then
    GRAFANA_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers | wc -l)
    if [[ "$GRAFANA_PODS" -gt 0 ]]; then
      echo -e "  ${YELLOW}⚠${NC} Grafana may already be installed ($GRAFANA_PODS pods)"
    fi
  fi
else
  kubectl create namespace monitoring
  echo -e "${GREEN}✓${NC} Namespace 'monitoring' created"
fi

echo ""

# ==========================================================================
# 7. Add Helm Repositories
# ==========================================================================
echo -e "${BLUE}7. Adding Helm Repositories...${NC}"
echo ""

echo "Adding prometheus-community repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts &> /dev/null || true

echo "Adding grafana repo..."
helm repo add grafana https://grafana.github.io/helm-charts &> /dev/null || true

echo "Updating helm repos..."
helm repo update &> /dev/null

echo -e "${GREEN}✓${NC} Helm repositories added and updated"

echo ""

# ==========================================================================
# 8. Summary
# ==========================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}✓${NC} Kubernetes cluster is accessible"
echo -e "${GREEN}✓${NC} Helm is installed and ready"
echo -e "${GREEN}✓${NC} Monitoring namespace is ready"
echo -e "${GREEN}✓${NC} Helm repositories configured"

if [[ "$LAB5_OK" == "true" ]]; then
  echo -e "${GREEN}✓${NC} Lab 5 applications are deployed"
else
  echo -e "${YELLOW}⚠${NC} Lab 5 applications partially deployed (can continue)"
fi

echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Start with Exercise 1: Prometheus Setup"
echo "   cat exercises/01-prometheus-setup.md"
echo ""
echo "2. Install Prometheus + Grafana:"
echo "   helm install prometheus prometheus-community/kube-prometheus-stack \\"
echo "     --namespace monitoring \\"
echo "     --values <your-values.yaml>"
echo ""
echo "3. Follow exercises 1-5 in order:"
echo "   - Exercise 1: Prometheus Setup (60 min)"
echo "   - Exercise 2: Application Metrics (60 min)"
echo "   - Exercise 3: Grafana Dashboards (60 min)"
echo "   - Exercise 4: Alerting (60 min)"
echo "   - Exercise 5: Log Aggregation (60 min)"
echo ""

echo -e "${GREEN}Ready to start Lab 6! 🚀📊${NC}"
echo ""

# ==========================================================================
# 9. Optional: Quick Install
# ==========================================================================
echo -e "${YELLOW}Optional: Quick Install${NC}"
echo ""
read -p "Do you want to install Prometheus + Grafana now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  echo "Installing kube-prometheus-stack..."
  echo ""

  # Create basic values file
  cat > /tmp/prometheus-values.yaml <<EOF
prometheus:
  prometheusSpec:
    retention: 7d
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
grafana:
  adminPassword: admin123
  persistence:
    enabled: false
alertmanager:
  enabled: true
EOF

  helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --values /tmp/prometheus-values.yaml \
    --wait \
    --timeout 10m

  echo ""
  echo -e "${GREEN}✓${NC} Prometheus + Grafana installed!"
  echo ""
  echo "Access Grafana:"
  echo "  kubectl port-forward -n monitoring svc/prometheus-grafana 3001:80"
  echo "  Open: http://localhost:3001"
  echo "  Username: admin"
  echo "  Password: admin123"
  echo ""
  echo "Access Prometheus:"
  echo "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
  echo "  Open: http://localhost:9090"
  echo ""
fi

echo ""
echo -e "${GREEN}Setup complete! Start with exercises/01-prometheus-setup.md${NC}"
