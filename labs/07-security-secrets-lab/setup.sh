#!/bin/bash

# ==========================================================================
# Lab 7: Security & Secrets Management - Setup Script
# ==========================================================================
# This script validates your environment for Lab 7
# Prerequisites: Lab 1-6 completed
# ==========================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Lab 7: Security & Secrets - Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ==========================================================================
# Function: Check command exists
# ==========================================================================
check_command() {
  local cmd=$1
  local required=$2

  if command -v "$cmd" &> /dev/null; then
    local version=$($cmd --version 2>&1 | head -n1 || echo "installed")
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
check_command "curl" "true" || PREREQ_OK=false
check_command "jq" "false"

# Security tools (will install later)
check_command "trivy" "false"
check_command "kubeseal" "false"

echo ""

if [[ "$PREREQ_OK" == "false" ]]; then
  echo -e "${RED}✗ Missing required prerequisites!${NC}"
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
  exit 1
fi

echo ""

# ==========================================================================
# 3. Check Lab 5 and Lab 6 Prerequisites
# ==========================================================================
echo -e "${BLUE}3. Checking Lab 5/6 Prerequisites...${NC}"
echo ""

LAB_OK=true

# Check production namespace
if kubectl get namespace production &> /dev/null; then
  echo -e "${GREEN}✓${NC} Production namespace exists"

  # Check user-service
  if kubectl get deployment user-service -n production &> /dev/null; then
    REPLICAS=$(kubectl get deployment user-service -n production -o jsonpath='{.status.availableReplicas}' 2>/dev/null || echo "0")
    if [[ "$REPLICAS" -gt 0 ]]; then
      echo -e "  ${GREEN}✓${NC} user-service deployed ($REPLICAS replicas)"
    else
      echo -e "  ${YELLOW}⚠${NC} user-service exists but no replicas available"
      LAB_OK=false
    fi
  else
    echo -e "  ${YELLOW}⚠${NC} user-service NOT found"
    LAB_OK=false
  fi
else
  echo -e "${RED}✗${NC} Production namespace NOT found"
  LAB_OK=false
fi

# Check monitoring namespace (Lab 6)
if kubectl get namespace monitoring &> /dev/null; then
  echo -e "${GREEN}✓${NC} Monitoring namespace exists"

  # Check Prometheus
  if kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus &> /dev/null 2>&1; then
    PROM_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [[ "$PROM_PODS" -gt 0 ]]; then
      echo -e "  ${GREEN}✓${NC} Prometheus running"
    else
      echo -e "  ${YELLOW}⚠${NC} Prometheus not running"
    fi
  fi
else
  echo -e "${YELLOW}⚠${NC} Monitoring namespace NOT found (Lab 6 not complete)"
fi

echo ""

if [[ "$LAB_OK" == "false" ]]; then
  echo -e "${YELLOW}⚠ Lab 5/6 not fully complete${NC}"
  echo ""
  echo "Lab 7 works best with Lab 5 and Lab 6 components deployed."
  echo ""
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# ==========================================================================
# 4. Check CNI Support for Network Policies
# ==========================================================================
echo -e "${BLUE}4. Checking Network Policy Support...${NC}"
echo ""

if kubectl api-resources | grep -q networkpolicies; then
  echo -e "${GREEN}✓${NC} NetworkPolicy CRD available"

  # Try to determine CNI
  CNI_PODS=$(kubectl get pods -n kube-system -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | grep -E 'calico|cilium|weave' | head -1 || echo "")

  if [[ -n "$CNI_PODS" ]]; then
    echo "  CNI: ${CNI_PODS}"
  else
    echo -e "  ${YELLOW}⚠${NC} Cannot determine CNI (may not support NetworkPolicies)"
    echo "    Ensure your cluster CNI supports NetworkPolicies"
    echo "    (Calico, Cilium, Weave Net, etc.)"
  fi
else
  echo -e "${YELLOW}⚠${NC} NetworkPolicy CRD not found"
  echo "  Your CNI may not support NetworkPolicies"
  echo "  Exercise 3 may not work"
fi

echo ""

# ==========================================================================
# 5. Create Vault Namespace
# ==========================================================================
echo -e "${BLUE}5. Creating Vault Namespace...${NC}"
echo ""

if kubectl get namespace vault &> /dev/null; then
  echo -e "${YELLOW}⚠${NC} Namespace 'vault' already exists"
else
  kubectl create namespace vault
  echo -e "${GREEN}✓${NC} Namespace 'vault' created"
fi

echo ""

# ==========================================================================
# 6. Add Helm Repositories
# ==========================================================================
echo -e "${BLUE}6. Adding Helm Repositories...${NC}"
echo ""

echo "Adding HashiCorp repo..."
helm repo add hashicorp https://helm.releases.hashicorp.com &> /dev/null || true

echo "Updating helm repos..."
helm repo update &> /dev/null

echo -e "${GREEN}✓${NC} Helm repositories added and updated"

echo ""

# ==========================================================================
# 7. Check/Install Trivy
# ==========================================================================
echo -e "${BLUE}7. Checking Trivy Installation...${NC}"
echo ""

if command -v trivy &> /dev/null; then
  TRIVY_VERSION=$(trivy --version | head -1)
  echo -e "${GREEN}✓${NC} Trivy already installed: $TRIVY_VERSION"
else
  echo -e "${YELLOW}⚠${NC} Trivy not installed"
  echo ""
  read -p "Install Trivy now? (y/n) " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Trivy..."

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add - 2>/dev/null || true
      echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
      sudo apt-get update -qq
      sudo apt-get install -y trivy
    else
      echo "Please install Trivy manually: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
    fi

    if command -v trivy &> /dev/null; then
      echo -e "${GREEN}✓${NC} Trivy installed successfully"
    fi
  else
    echo "Skipping Trivy installation. Install manually for Exercise 4."
  fi
fi

echo ""

# ==========================================================================
# 8. Check/Install kubeseal
# ==========================================================================
echo -e "${BLUE}8. Checking kubeseal Installation...${NC}"
echo ""

if command -v kubeseal &> /dev/null; then
  KUBESEAL_VERSION=$(kubeseal --version 2>&1 | head -1)
  echo -e "${GREEN}✓${NC} kubeseal already installed: $KUBESEAL_VERSION"
else
  echo -e "${YELLOW}⚠${NC} kubeseal not installed"
  echo ""
  read -p "Install kubeseal now? (y/n) " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing kubeseal..."

    KUBESEAL_VERSION="0.24.0"
    wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz
    tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz
    sudo install -m 755 kubeseal /usr/local/bin/kubeseal
    rm kubeseal kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz

    if command -v kubeseal &> /dev/null; then
      echo -e "${GREEN}✓${NC} kubeseal installed successfully"
    fi
  else
    echo "Skipping kubeseal installation. Install manually for Exercise 5."
  fi
fi

echo ""

# ==========================================================================
# 9. Security Checklist
# ==========================================================================
echo -e "${BLUE}9. Security Checklist...${NC}"
echo ""

echo "Checking current security posture:"
echo ""

# Check for cluster-admin usage
CLUSTER_ADMIN_USERS=$(kubectl get clusterrolebindings -o json 2>/dev/null | \
  jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .subjects[]? | select(.kind=="User") | .name' 2>/dev/null | \
  wc -l || echo "0")

if [[ "$CLUSTER_ADMIN_USERS" -eq 0 ]]; then
  echo -e "${GREEN}✓${NC} No cluster-admin users found (good!)"
else
  echo -e "${YELLOW}⚠${NC} $CLUSTER_ADMIN_USERS user(s) with cluster-admin role"
  echo "  Recommendation: Remove cluster-admin, use namespace-scoped Roles"
fi

# Check for default ServiceAccount usage
DEFAULT_SA_USAGE=$(kubectl get pods -A -o json 2>/dev/null | \
  jq -r '.items[] | select(.spec.serviceAccountName=="default") | .metadata.namespace + "/" + .metadata.name' 2>/dev/null | \
  wc -l || echo "0")

if [[ "$DEFAULT_SA_USAGE" -eq 0 ]]; then
  echo -e "${GREEN}✓${NC} No pods using default ServiceAccount (good!)"
else
  echo -e "${YELLOW}⚠${NC} $DEFAULT_SA_USAGE pod(s) using default ServiceAccount"
  echo "  Recommendation: Create dedicated ServiceAccounts"
fi

# Check for Network Policies
NP_COUNT=$(kubectl get networkpolicies -A 2>/dev/null | wc -l || echo "0")

if [[ "$NP_COUNT" -gt 1 ]]; then
  echo -e "${GREEN}✓${NC} Network Policies configured ($NP_COUNT policies)"
else
  echo -e "${YELLOW}⚠${NC} No Network Policies found"
  echo "  Recommendation: Implement Network Policies (Exercise 3)"
fi

echo ""

# ==========================================================================
# Summary
# ==========================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}✓${NC} Kubernetes cluster is accessible"
echo -e "${GREEN}✓${NC} Helm is installed and ready"
echo -e "${GREEN}✓${NC} Vault namespace created"
echo -e "${GREEN}✓${NC} Helm repositories configured"

echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Start with Exercise 1: HashiCorp Vault Setup"
echo "   cat exercises/01-vault-setup.md"
echo ""
echo "2. Follow exercises 1-5 in order:"
echo "   - Exercise 1: Vault Setup (60 min)"
echo "   - Exercise 2: Kubernetes RBAC (60 min)"
echo "   - Exercise 3: Network Policies (60 min)"
echo "   - Exercise 4: Security Scanning (60 min)"
echo "   - Exercise 5: Sealed Secrets (60 min)"
echo ""
echo "3. Total lab time: 5 hours"
echo ""

echo -e "${GREEN}Ready to start Lab 7! 🔒🛡️${NC}"
echo ""

# ==========================================================================
# Optional: Quick Install
# ==========================================================================
echo -e "${YELLOW}Optional: Quick Install Components${NC}"
echo ""
read -p "Install Vault now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  echo "Installing HashiCorp Vault..."

  cat > /tmp/vault-values.yaml <<EOF
server:
  dev:
    enabled: true
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
injector:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
ui:
  enabled: true
global:
  tlsDisable: true
EOF

  helm install vault hashicorp/vault \
    --namespace vault \
    --values /tmp/vault-values.yaml \
    --wait \
    --timeout 5m

  echo ""
  echo -e "${GREEN}✓${NC} Vault installed!"
  echo ""
  echo "Access Vault UI:"
  echo "  kubectl port-forward -n vault svc/vault 8200:8200"
  echo "  Open: http://localhost:8200"
  echo "  Token: root (dev mode)"
  echo ""
fi

echo ""
echo -e "${GREEN}Setup complete! Start with exercises/01-vault-setup.md${NC}"
