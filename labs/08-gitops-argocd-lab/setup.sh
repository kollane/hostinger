#!/bin/bash

# ==========================================================================
# Lab 8: GitOps with ArgoCD - Setup Script
# ==========================================================================
# This script validates your environment for Lab 8
# Prerequisites: Lab 5, 6, 7 completed
# ==========================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Lab 8: GitOps with ArgoCD - Setup${NC}"
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
check_command "git" "true" || PREREQ_OK=false

echo ""

if [[ "$PREREQ_OK" == "false" ]]; then
  echo -e "${RED}✗ Missing required prerequisites!${NC}"
  echo ""
  echo "Install missing tools:"
  echo "  - kubectl: curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  echo "  - helm: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
  echo "  - git: sudo apt install git"
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
# 4. Check Lab 5, 6, 7 Prerequisites
# ==========================================================================
echo -e "${BLUE}4. Checking Lab 5, 6, 7 Prerequisites...${NC}"
echo ""

LAB_OK=true

# Check namespaces (Lab 5)
for ns in development staging production monitoring; do
  if kubectl get namespace "$ns" &> /dev/null; then
    echo -e "${GREEN}✓${NC} Namespace '$ns' exists"
  else
    echo -e "${YELLOW}⚠${NC} Namespace '$ns' does NOT exist (Lab 5 prerequisite)"
    LAB_OK=false
  fi
done

# Check Prometheus (Lab 6)
if kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus &> /dev/null 2>&1; then
  PROM_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers | wc -l)
  if [[ "$PROM_PODS" -gt 0 ]]; then
    echo -e "${GREEN}✓${NC} Prometheus is installed ($PROM_PODS pods)"
  else
    echo -e "${YELLOW}⚠${NC} Prometheus not running (Lab 6 prerequisite)"
    LAB_OK=false
  fi
else
  echo -e "${YELLOW}⚠${NC} Prometheus not found (Lab 6 prerequisite)"
  LAB_OK=false
fi

# Check Sealed Secrets controller (Lab 7)
if kubectl get pods -n kube-system -l name=sealed-secrets-controller &> /dev/null 2>&1; then
  SEALED_PODS=$(kubectl get pods -n kube-system -l name=sealed-secrets-controller --no-headers | wc -l)
  if [[ "$SEALED_PODS" -gt 0 ]]; then
    echo -e "${GREEN}✓${NC} Sealed Secrets controller installed ($SEALED_PODS pods)"
  else
    echo -e "${YELLOW}⚠${NC} Sealed Secrets not running (Lab 7 prerequisite)"
    LAB_OK=false
  fi
else
  echo -e "${YELLOW}⚠${NC} Sealed Secrets not found (Lab 7 prerequisite)"
  LAB_OK=false
fi

echo ""

if [[ "$LAB_OK" == "false" ]]; then
  echo -e "${YELLOW}⚠ Lab 5, 6, 7 not fully completed${NC}"
  echo ""
  echo "Lab 8 builds on Lab 5 (CI/CD), Lab 6 (Monitoring), and Lab 7 (Security)."
  echo "Please complete those labs first for the best experience."
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

# Check if metrics-server is available
if kubectl top nodes &> /dev/null; then
  echo -e "${GREEN}✓${NC} Metrics server is available"
  
  # Get total memory
  TOTAL_MEM=$(kubectl top nodes 2>/dev/null | awk 'NR>1 {print $5}' | head -1)
  echo "  Cluster resources can be monitored"
else
  echo -e "${YELLOW}⚠${NC} Metrics server not available"
  echo "  Install metrics-server for resource monitoring:"
  echo "  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
fi

echo ""

# ==========================================================================
# 6. Create ArgoCD Namespace
# ==========================================================================
echo -e "${BLUE}6. Creating ArgoCD Namespace...${NC}"
echo ""

if kubectl get namespace argocd &> /dev/null; then
  echo -e "${YELLOW}⚠${NC} Namespace 'argocd' already exists"
  
  # Check if ArgoCD is already installed
  if kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server &> /dev/null 2>&1; then
    ARGOCD_PODS=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server --no-headers | wc -l)
    if [[ "$ARGOCD_PODS" -gt 0 ]]; then
      echo -e "${YELLOW}⚠${NC} ArgoCD may already be installed ($ARGOCD_PODS server pods)"
    fi
  fi
else
  kubectl create namespace argocd
  echo -e "${GREEN}✓${NC} Namespace 'argocd' created"
  
  # Label namespace for Prometheus monitoring (Lab 6 integration)
  kubectl label namespace argocd monitoring=prometheus
  echo -e "${GREEN}✓${NC} Namespace labeled for Prometheus monitoring"
fi

echo ""

# ==========================================================================
# 7. Add Helm Repositories
# ==========================================================================
echo -e "${BLUE}7. Adding Helm Repositories...${NC}"
echo ""

echo "Adding argo repo..."
helm repo add argo https://argoproj.github.io/argo-helm &> /dev/null || true

echo "Updating helm repos..."
helm repo update &> /dev/null

echo -e "${GREEN}✓${NC} Helm repositories added and updated"

echo ""

# ==========================================================================
# 8. Check ArgoCD CLI
# ==========================================================================
echo -e "${BLUE}8. Checking ArgoCD CLI...${NC}"
echo ""

if command -v argocd &> /dev/null; then
  ARGOCD_VERSION=$(argocd version --client 2>&1 | head -n1)
  echo -e "${GREEN}✓${NC} ArgoCD CLI is installed: $ARGOCD_VERSION"
else
  echo -e "${YELLOW}⚠${NC} ArgoCD CLI is NOT installed"
  echo ""
  echo "Install ArgoCD CLI:"
  echo "  curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
  echo "  chmod +x argocd"
  echo "  sudo mv argocd /usr/local/bin/argocd"
fi

echo ""

# ==========================================================================
# 9. Check kubectl argo rollouts plugin
# ==========================================================================
echo -e "${BLUE}9. Checking kubectl-argo-rollouts plugin...${NC}"
echo ""

if command -v kubectl-argo-rollouts &> /dev/null; then
  ROLLOUTS_VERSION=$(kubectl argo rollouts version 2>&1 | head -n1)
  echo -e "${GREEN}✓${NC} kubectl-argo-rollouts is installed: $ROLLOUTS_VERSION"
else
  echo -e "${YELLOW}⚠${NC} kubectl-argo-rollouts is NOT installed (optional)"
  echo ""
  echo "Install kubectl-argo-rollouts plugin:"
  echo "  curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64"
  echo "  chmod +x kubectl-argo-rollouts-linux-amd64"
  echo "  sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts"
fi

echo ""

# ==========================================================================
# 10. Summary
# ==========================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}✓${NC} Kubernetes cluster is accessible"
echo -e "${GREEN}✓${NC} Helm is installed and ready"
echo -e "${GREEN}✓${NC} ArgoCD namespace is ready"
echo -e "${GREEN}✓${NC} Helm repositories configured"

if [[ "$LAB_OK" == "true" ]]; then
  echo -e "${GREEN}✓${NC} Lab 5, 6, 7 prerequisites are met"
else
  echo -e "${YELLOW}⚠${NC} Lab 5, 6, 7 partially completed (can continue)"
fi

echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Start with Exercise 1: ArgoCD Setup"
echo "   cat exercises/01-argocd-setup.md"
echo ""
echo "2. Install ArgoCD:"
echo "   helm install argocd argo/argo-cd \\"
echo "     --namespace argocd \\"
echo "     --values <your-values.yaml>"
echo ""
echo "3. Follow exercises 1-5 in order:"
echo "   - Exercise 1: ArgoCD Setup & Installation (60 min)"
echo "   - Exercise 2: First Application Deployment (60 min)"
echo "   - Exercise 3: Multi-Environment Deployments (60 min)"
echo "   - Exercise 4: Advanced GitOps Workflows (60 min)"
echo "   - Exercise 5: GitOps Security & Best Practices (60 min)"
echo ""

echo -e "${GREEN}Ready to start Lab 8! 🚀🔄${NC}"
echo ""

# ==========================================================================
# 11. Optional: Quick Install
# ==========================================================================
echo -e "${YELLOW}Optional: Quick Install${NC}"
echo ""
read -p "Do you want to install ArgoCD now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  echo "Installing ArgoCD..."
  echo ""

  # Create basic values file
  cat > /tmp/argocd-values.yaml <<YAML
global:
  domain: argocd.local

server:
  replicas: 1
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring

controller:
  replicas: 1
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 1Gi
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring

repoServer:
  replicas: 1
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 512Mi
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring

redis:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi

dex:
  enabled: false

notifications:
  enabled: false

applicationSet:
  enabled: true
  replicas: 1
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
YAML

  helm install argocd argo/argo-cd \
    --namespace argocd \
    --values /tmp/argocd-values.yaml \
    --version 7.0.0 \
    --wait \
    --timeout 10m

  echo ""
  echo -e "${GREEN}✓${NC} ArgoCD installed!"
  echo ""
  
  # Get admin password
  ADMIN_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
  
  echo "Access ArgoCD UI:"
  echo "  kubectl port-forward -n argocd svc/argocd-server 8080:80"
  echo "  Open: http://localhost:8080"
  echo "  Username: admin"
  echo "  Password: $ADMIN_PASSWORD"
  echo ""
  echo "Install ArgoCD CLI (if not installed):"
  echo "  curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
  echo "  chmod +x argocd"
  echo "  sudo mv argocd /usr/local/bin/argocd"
  echo ""
fi

echo ""
echo -e "${GREEN}Setup complete! Start with exercises/01-argocd-setup.md${NC}"

