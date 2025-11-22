#!/bin/bash

# ==========================================================================
# Lab 5: CI/CD Pipeline - Setup Script
# ==========================================================================
# This script validates your environment for Lab 5
# Prerequisites: Lab 1-4 completed, GitHub account, Docker Hub account
# ==========================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Lab 5: CI/CD Pipeline - Setup${NC}"
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
check_command "git" "true" || PREREQ_OK=false
check_command "kubectl" "true" || PREREQ_OK=false
check_command "helm" "true" || PREREQ_OK=false
check_command "docker" "true" || PREREQ_OK=false

# Optional tools
check_command "jq" "false"
check_command "yq" "false"

echo ""

if [[ "$PREREQ_OK" == "false" ]]; then
  echo -e "${RED}✗ Missing required prerequisites!${NC}"
  echo ""
  echo "Install missing tools:"
  echo "  - kubectl: curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  echo "  - helm: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
  echo "  - docker: curl -fsSL https://get.docker.com | sh"
  exit 1
fi

# ==========================================================================
# 2. Check Kubernetes Cluster
# ==========================================================================
echo -e "${BLUE}2. Checking Kubernetes Cluster...${NC}"
echo ""

if kubectl cluster-info &> /dev/null; then
  echo -e "${GREEN}✓${NC} Kubernetes cluster is reachable"

  # Show cluster info
  CONTEXT=$(kubectl config current-context)
  echo "  Current context: $CONTEXT"

  # Check nodes
  NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  echo "  Nodes: $NODE_COUNT"

  # Check namespaces for Lab 5
  for ns in development staging production; do
    if kubectl get namespace "$ns" &> /dev/null; then
      echo -e "  ${GREEN}✓${NC} Namespace '$ns' exists"
    else
      echo -e "  ${YELLOW}⚠${NC} Namespace '$ns' does not exist (will be created by CD workflow)"
    fi
  done
else
  echo -e "${RED}✗${NC} Cannot connect to Kubernetes cluster"
  echo ""
  echo "Make sure:"
  echo "  1. Kubernetes cluster is running (minikube/kind/Docker Desktop/cloud)"
  echo "  2. kubectl is configured (~/.kube/config)"
  echo "  3. You have permissions to access the cluster"
  exit 1
fi

echo ""

# ==========================================================================
# 3. Check Lab 4 Prerequisites
# ==========================================================================
echo -e "${BLUE}3. Checking Lab 4 Prerequisites...${NC}"
echo ""

LAB4_OK=true

# Check Helm chart exists
HELM_CHART_PATH="../04-kubernetes-advanced-lab/solutions/helm/user-service"

if [[ -d "$HELM_CHART_PATH" ]]; then
  echo -e "${GREEN}✓${NC} Lab 4 Helm chart found: $HELM_CHART_PATH"

  # Check values files
  for env in dev staging prod; do
    VALUES_FILE="$HELM_CHART_PATH/values-$env.yaml"
    if [[ -f "$VALUES_FILE" ]]; then
      echo -e "  ${GREEN}✓${NC} values-$env.yaml exists"
    else
      echo -e "  ${RED}✗${NC} values-$env.yaml NOT found (REQUIRED for Lab 5)"
      LAB4_OK=false
    fi
  done
else
  echo -e "${RED}✗${NC} Lab 4 Helm chart NOT found at: $HELM_CHART_PATH"
  echo ""
  echo "Please complete Lab 4 first!"
  LAB4_OK=false
fi

echo ""

if [[ "$LAB4_OK" == "false" ]]; then
  echo -e "${RED}✗ Lab 4 prerequisites missing!${NC}"
  echo "Complete Lab 4 before starting Lab 5."
  exit 1
fi

# ==========================================================================
# 4. GitHub Repository Setup
# ==========================================================================
echo -e "${BLUE}4. GitHub Repository Setup${NC}"
echo ""

if git remote get-url origin &> /dev/null; then
  REPO_URL=$(git remote get-url origin)
  echo -e "${GREEN}✓${NC} Git repository configured: $REPO_URL"

  # Extract GitHub username/repo
  if [[ "$REPO_URL" =~ github.com[:/]([^/]+)/([^/.]+) ]]; then
    GH_USER="${BASH_REMATCH[1]}"
    GH_REPO="${BASH_REMATCH[2]}"
    echo "  GitHub User: $GH_USER"
    echo "  Repository: $GH_REPO"
  fi
else
  echo -e "${YELLOW}⚠${NC} No git remote configured"
  echo ""
  echo "To use GitHub Actions, you need to:"
  echo "  1. Create a GitHub repository"
  echo "  2. Add it as remote: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
  echo "  3. Push code: git push -u origin main"
fi

echo ""

# ==========================================================================
# 5. GitHub Secrets Instructions
# ==========================================================================
echo -e "${BLUE}5. GitHub Secrets Setup${NC}"
echo ""

echo "You need to configure these secrets in GitHub:"
echo "  Settings → Secrets and variables → Actions → New repository secret"
echo ""

echo -e "${YELLOW}Required Secrets:${NC}"
echo ""

# Docker Hub
echo "1. DOCKER_USERNAME"
echo "   - Your Docker Hub username"
echo "   - Example: myusername"
echo ""

echo "2. DOCKER_PASSWORD"
echo "   - Docker Hub access token (NOT your password!)"
echo "   - Create at: https://hub.docker.com/settings/security"
echo "   - Click 'New Access Token', copy the token"
echo ""

# Kubeconfig
echo "3. KUBECONFIG"
echo "   - Base64 encoded kubeconfig"
echo "   - Generate with: cat ~/.kube/config | base64 -w 0"
echo "   - Copy the output and paste into GitHub Secret"
echo ""

# Optional: Slack
echo -e "${YELLOW}Optional Secrets:${NC}"
echo ""
echo "4. SLACK_WEBHOOK (optional)"
echo "   - Slack incoming webhook URL for notifications"
echo "   - Create at: https://api.slack.com/messaging/webhooks"
echo ""

# Generate kubeconfig secret
echo -e "${BLUE}Generate KUBECONFIG secret:${NC}"
echo ""
echo "Run this command and copy the output:"
echo -e "${GREEN}cat ~/.kube/config | base64 -w 0${NC}"
echo ""

# ==========================================================================
# 6. GitHub Environments Setup
# ==========================================================================
echo -e "${BLUE}6. GitHub Environments Setup${NC}"
echo ""

echo "Create three environments in GitHub:"
echo "  Settings → Environments → New environment"
echo ""

echo "1. development"
echo "   - No protection rules"
echo "   - Auto-deploy on push to 'develop' branch"
echo ""

echo "2. staging"
echo "   - No protection rules"
echo "   - Auto-deploy on push to 'staging' branch"
echo ""

echo "3. production"
echo "   - ✓ Required reviewers: Add yourself or team"
echo "   - ✓ Wait timer: 0 minutes (or add delay if needed)"
echo "   - Manual approval required for deployment"
echo ""

# ==========================================================================
# 7. Docker Hub Repository
# ==========================================================================
echo -e "${BLUE}7. Docker Hub Repository${NC}"
echo ""

echo "Create a repository on Docker Hub:"
echo "  1. Go to: https://hub.docker.com/repositories"
echo "  2. Click 'Create Repository'"
echo "  3. Name: user-service (or your app name)"
echo "  4. Visibility: Public (or Private with Pro account)"
echo ""

# ==========================================================================
# 8. Branch Setup
# ==========================================================================
echo -e "${BLUE}8. Git Branch Setup${NC}"
echo ""

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "N/A")
echo "Current branch: $CURRENT_BRANCH"
echo ""

echo "Lab 5 uses three branches for multi-environment deployment:"
echo "  - develop → development namespace (auto-deploy)"
echo "  - staging → staging namespace (auto-deploy)"
echo "  - main → production namespace (manual approval)"
echo ""

echo "Create branches if they don't exist:"
echo -e "${GREEN}git checkout -b develop${NC}"
echo -e "${GREEN}git checkout -b staging${NC}"
echo -e "${GREEN}git push -u origin develop${NC}"
echo -e "${GREEN}git push -u origin staging${NC}"
echo ""

# ==========================================================================
# Summary
# ==========================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}✓${NC} All prerequisites are installed"
echo -e "${GREEN}✓${NC} Kubernetes cluster is accessible"
echo -e "${GREEN}✓${NC} Lab 4 Helm chart is ready"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Set up GitHub Secrets (DOCKER_USERNAME, DOCKER_PASSWORD, KUBECONFIG)"
echo "2. Create GitHub Environments (development, staging, production)"
echo "3. Create branches (develop, staging, main)"
echo "4. Copy workflows to .github/workflows/"
echo "5. Push code to GitHub to trigger CI/CD pipeline"
echo ""

echo "Read the exercises:"
echo "  - exercises/01-github-actions-basics.md"
echo "  - exercises/02-ci-pipeline.md"
echo "  - exercises/03-helm-deployment.md"
echo "  - exercises/04-quality-gates.md"
echo "  - exercises/05-production-pipeline.md"
echo ""

echo -e "${GREEN}Ready to start Lab 5! 🚀${NC}"
