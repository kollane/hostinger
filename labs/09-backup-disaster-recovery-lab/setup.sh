#!/bin/bash

# ==========================================================================
# Lab 9: Backup & Disaster Recovery - Setup Script
# ==========================================================================
# This script validates your environment for Lab 9
# Prerequisites: Lab 1-8 completed, Kubernetes cluster running
# ==========================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Lab 9: Backup & Disaster Recovery${NC}"
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
check_command "curl" "true" || PREREQ_OK=false
check_command "jq" "false"

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
# 3. Check Previous Labs
# ==========================================================================
echo -e "${BLUE}3. Checking Previous Labs (1-8)...${NC}"
echo ""

LAB_OK=true

# Check namespaces
for ns in development staging production monitoring argocd; do
  if kubectl get namespace "$ns" &> /dev/null; then
    echo -e "${GREEN}✓${NC} Namespace '$ns' exists"
  else
    echo -e "${YELLOW}⚠${NC} Namespace '$ns' missing (Lab 5/6/8 prerequisite)"
    LAB_OK=false
  fi
done

echo ""

if [[ "$LAB_OK" == "false" ]]; then
  echo -e "${YELLOW}⚠ Lab 1-8 not fully completed${NC}"
  echo ""
  echo "Lab 9 builds on previous labs. For best experience, complete Labs 1-8 first."
  echo ""
  read -p "Continue anyway? (y/n) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# ==========================================================================
# 4. Check Velero CLI
# ==========================================================================
echo -e "${BLUE}4. Checking Velero CLI...${NC}"
echo ""

if command -v velero &> /dev/null; then
  VELERO_VERSION=$(velero version --client-only 2>&1 | head -n1)
  echo -e "${GREEN}✓${NC} Velero CLI is installed: $VELERO_VERSION"
else
  echo -e "${YELLOW}⚠${NC} Velero CLI is NOT installed"
  echo ""
  echo "Install Velero CLI:"
  echo "  wget https://github.com/vmware-tanzu/velero/releases/latest/download/velero-<version>-linux-amd64.tar.gz"
  echo "  tar -xvf velero-<version>-linux-amd64.tar.gz"
  echo "  sudo mv velero-<version>-linux-amd64/velero /usr/local/bin/velero"
  echo ""
  read -p "Do you want to install Velero CLI now? (y/n) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Velero CLI..."
    VELERO_VERSION="v1.13.0"
    wget https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz
    tar -xvf velero-${VELERO_VERSION}-linux-amd64.tar.gz
    sudo mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/velero
    rm -rf velero-${VELERO_VERSION}-linux-amd64*
    echo -e "${GREEN}✓${NC} Velero CLI installed"
  fi
fi

echo ""

# ==========================================================================
# 5. Check Velero Server
# ==========================================================================
echo -e "${BLUE}5. Checking Velero Server...${NC}"
echo ""

if kubectl get namespace velero &> /dev/null; then
  echo -e "${YELLOW}⚠${NC} Velero namespace already exists"

  if kubectl get pods -n velero -l component=velero &> /dev/null 2>&1; then
    VELERO_PODS=$(kubectl get pods -n velero -l component=velero --no-headers | wc -l)
    if [[ "$VELERO_PODS" -gt 0 ]]; then
      echo -e "${YELLOW}⚠${NC} Velero server may already be installed ($VELERO_PODS pods)"
    fi
  fi
else
  echo -e "${GREEN}✓${NC} Velero namespace not found (will be created in Exercise 1)"
fi

echo ""

# ==========================================================================
# 6. Check Helm
# ==========================================================================
echo -e "${BLUE}6. Checking Helm...${NC}"
echo ""

HELM_VERSION=$(helm version --short 2>/dev/null || echo "")

if [[ -n "$HELM_VERSION" ]]; then
  echo -e "${GREEN}✓${NC} Helm is installed: $HELM_VERSION"

  # Add Velero Helm repo
  echo "Adding VMware Tanzu Helm repo..."
  helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts &> /dev/null || true
  helm repo update &> /dev/null
  echo -e "${GREEN}✓${NC} Helm repositories configured"
else
  echo -e "${RED}✗${NC} Helm is NOT installed"
  exit 1
fi

echo ""

# ==========================================================================
# 7. Check Storage
# ==========================================================================
echo -e "${BLUE}7. Checking Storage...${NC}"
echo ""

# Check if StorageClass exists
SC_COUNT=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)

if [[ "$SC_COUNT" -gt 0 ]]; then
  echo -e "${GREEN}✓${NC} StorageClass available ($SC_COUNT found)"
  kubectl get storageclass --no-headers | awk '{print "  - " $1}'
else
  echo -e "${YELLOW}⚠${NC} No StorageClass found"
  echo "  MinIO will use emptyDir (data lost on pod restart)"
fi

echo ""

# ==========================================================================
# 8. Check MinIO
# ==========================================================================
echo -e "${BLUE}8. Checking MinIO...${NC}"
echo ""

if kubectl get namespace minio &> /dev/null; then
  echo -e "${YELLOW}⚠${NC} MinIO namespace already exists"

  if kubectl get pods -n minio -l app=minio &> /dev/null 2>&1; then
    MINIO_PODS=$(kubectl get pods -n minio -l app=minio --no-headers | wc -l)
    if [[ "$MINIO_PODS" -gt 0 ]]; then
      echo -e "${YELLOW}⚠${NC} MinIO may already be installed ($MINIO_PODS pods)"
    fi
  fi
else
  echo -e "${GREEN}✓${NC} MinIO namespace not found (will be created in Exercise 1)"
fi

echo ""

# ==========================================================================
# 9. Check Available Resources
# ==========================================================================
echo -e "${BLUE}9. Checking Available Resources...${NC}"
echo ""

if kubectl top nodes &> /dev/null; then
  echo -e "${GREEN}✓${NC} Metrics server is available"

  echo ""
  echo "Cluster resource usage:"
  kubectl top nodes
else
  echo -e "${YELLOW}⚠${NC} Metrics server not available"
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
echo -e "${GREEN}✓${NC} kubectl and helm installed"

if command -v velero &> /dev/null; then
  echo -e "${GREEN}✓${NC} Velero CLI installed"
else
  echo -e "${YELLOW}⚠${NC} Velero CLI not installed (install in Exercise 1)"
fi

if [[ "$LAB_OK" == "true" ]]; then
  echo -e "${GREEN}✓${NC} Lab 1-8 prerequisites met"
else
  echo -e "${YELLOW}⚠${NC} Lab 1-8 partially completed (can continue)"
fi

echo ""

echo -e "${YELLOW}Lab 9 Structure:${NC}"
echo "  Exercise 1: Velero Setup & Installation (60 min)"
echo "  Exercise 2: Application Backups (60 min)"
echo "  Exercise 3: Scheduled Backups & Retention (60 min)"
echo "  Exercise 4: Disaster Recovery Drill (60 min)"
echo "  Exercise 5: Advanced Scenarios (60 min)"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Start with Exercise 1:"
echo "   cat exercises/01-velero-setup.md"
echo ""
echo "2. Install Velero CLI (if not installed):"
echo "   wget https://github.com/vmware-tanzu/velero/releases/latest/download/velero-v1.13.0-linux-amd64.tar.gz"
echo "   tar -xvf velero-v1.13.0-linux-amd64.tar.gz"
echo "   sudo mv velero-v1.13.0-linux-amd64/velero /usr/local/bin/velero"
echo ""
echo "3. Follow exercises 1-5 in order."
echo ""

echo -e "${GREEN}Ready to start Lab 9! 🚀💾${NC}"
echo ""
