#!/bin/bash

# ==========================================================================
# Lab 10: Infrastructure as Code - Setup Script
# ==========================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Lab 10: Infrastructure as Code${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ==========================================================================
# 1. Check Prerequisites
# ==========================================================================
echo -e "${BLUE}1. Checking Prerequisites...${NC}"
echo ""

PREREQ_OK=true

check_command() {
  local cmd=$1
  if command -v "$cmd" &> /dev/null; then
    echo -e "${GREEN}✓${NC} $cmd is installed"
  else
    echo -e "${RED}✗${NC} $cmd is NOT installed"
    return 1
  fi
}

check_command "kubectl" || PREREQ_OK=false
check_command "git" || PREREQ_OK=false

echo ""

# ==========================================================================
# 2. Check Kubernetes Cluster
# ==========================================================================
echo -e "${BLUE}2. Checking Kubernetes Cluster...${NC}"
echo ""

if kubectl cluster-info &> /dev/null; then
  echo -e "${GREEN}✓${NC} Kubernetes cluster is reachable"
else
  echo -e "${RED}✗${NC} Cannot connect to Kubernetes cluster"
  exit 1
fi

echo ""

# ==========================================================================
# 3. Check Terraform CLI
# ==========================================================================
echo -e "${BLUE}3. Checking Terraform CLI...${NC}"
echo ""

if command -v terraform &> /dev/null; then
  TERRAFORM_VERSION=$(terraform version | head -n1)
  echo -e "${GREEN}✓${NC} Terraform is installed: $TERRAFORM_VERSION"
else
  echo -e "${YELLOW}⚠${NC} Terraform CLI is NOT installed"
  echo ""
  echo "Install Terraform:"
  echo "  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg"
  echo "  echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list"
  echo "  sudo apt update && sudo apt install terraform"
  echo ""
  read -p "Do you want to install Terraform now? (y/n) " -n 1 -r
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform -y
    echo -e "${GREEN}✓${NC} Terraform installed"
  fi
fi

echo ""

# ==========================================================================
# 4. Summary
# ==========================================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}✓${NC} Kubernetes cluster accessible"

if command -v terraform &> /dev/null; then
  echo -e "${GREEN}✓${NC} Terraform CLI installed"
else
  echo -e "${YELLOW}⚠${NC} Terraform CLI not installed (install in Exercise 1)"
fi

echo ""

echo -e "${YELLOW}Lab 10 Structure:${NC}"
echo "  Exercise 1: Terraform Basics & Kubernetes Provider (60 min)"
echo "  Exercise 2: Provision Kubernetes Resources (60 min)"
echo "  Exercise 3: Terraform Modules & DRY (60 min)"
echo "  Exercise 4: Terraform State Management (60 min)"
echo "  Exercise 5: GitOps for Infrastructure (60 min)"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Start with Exercise 1:"
echo "   cat exercises/01-terraform-basics.md"
echo ""
echo "2. Follow exercises 1-5 in order."
echo ""

echo -e "${GREEN}Ready to start Lab 10 - FINAL LAB! 🚀🎓${NC}"
echo ""
