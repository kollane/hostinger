#!/bin/bash

# ==========================================================================
# Lab 4 Setup Script - Kubernetes Advanced Features
# ==========================================================================
# Purpose: Quick setup and verification for Lab 4 exercises
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh [command]
#
# Commands:
#   check      - Check prerequisites
#   install    - Install missing components
#   verify     - Verify Lab 3 state
#   clean      - Clean up Lab 4 resources
# ==========================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==========================================================================
# Check Prerequisites
# ==========================================================================
check_prerequisites() {
    info "Checking prerequisites for Lab 4..."
    
    local all_ok=true
    
    # Check kubectl
    if command -v kubectl &> /dev/null; then
        local kubectl_version=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)
        info "✓ kubectl installed: $kubectl_version"
    else
        error "✗ kubectl not found"
        all_ok=false
    fi
    
    # Check Helm
    if command -v helm &> /dev/null; then
        local helm_version=$(helm version --short)
        info "✓ Helm installed: $helm_version"
    else
        warn "✗ Helm not found (required for Exercise 5)"
        all_ok=false
    fi
    
    # Check cluster connection
    if kubectl cluster-info &> /dev/null; then
        info "✓ Kubernetes cluster reachable"
    else
        error "✗ Cannot connect to Kubernetes cluster"
        all_ok=false
    fi
    
    # Check available resources
    local node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    if [ "$node_count" -gt 0 ]; then
        info "✓ Cluster has $node_count node(s)"
    else
        error "✗ No nodes found in cluster"
        all_ok=false
    fi
    
    # Check free RAM
    local free_ram=$(free -g | awk '/^Mem:/{print $7}')
    if [ "$free_ram" -ge 4 ]; then
        info "✓ Free RAM: ${free_ram}GB (sufficient)"
    else
        warn "⚠ Free RAM: ${free_ram}GB (recommend 4GB+)"
    fi
    
    if [ "$all_ok" = true ]; then
        info "All prerequisites met! ✅"
        return 0
    else
        error "Some prerequisites are missing! ❌"
        return 1
    fi
}

# ==========================================================================
# Install Missing Components
# ==========================================================================
install_components() {
    info "Installing missing components..."
    
    # Install Helm if missing
    if ! command -v helm &> /dev/null; then
        info "Installing Helm 3..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        info "✓ Helm installed"
    fi
    
    info "All components installed! ✅"
}

# ==========================================================================
# Verify Lab 3 State
# ==========================================================================
verify_lab3() {
    info "Verifying Lab 3 deployments..."
    
    local all_ok=true
    
    # Check deployments
    local deployments=$(kubectl get deployments --no-headers 2>/dev/null | awk '{print $1}')
    
    if echo "$deployments" | grep -q "frontend"; then
        info "✓ frontend deployment found"
    else
        warn "⚠ frontend deployment not found"
        all_ok=false
    fi
    
    if echo "$deployments" | grep -q "user-service"; then
        info "✓ user-service deployment found"
    else
        warn "⚠ user-service deployment not found"
        all_ok=false
    fi
    
    if echo "$deployments" | grep -q "todo-service"; then
        info "✓ todo-service deployment found"
    else
        warn "⚠ todo-service deployment not found"
        all_ok=false
    fi
    
    # Check StatefulSets
    local statefulsets=$(kubectl get statefulsets --no-headers 2>/dev/null | awk '{print $1}')
    
    if echo "$statefulsets" | grep -q "postgres"; then
        info "✓ PostgreSQL StatefulSet found"
    else
        warn "⚠ PostgreSQL StatefulSet not found"
        all_ok=false
    fi
    
    # Check services
    local services=$(kubectl get services --no-headers 2>/dev/null | awk '{print $1}')
    
    if echo "$services" | grep -q "frontend"; then
        info "✓ frontend service found"
    else
        warn "⚠ frontend service not found"
        all_ok=false
    fi
    
    if [ "$all_ok" = true ]; then
        info "Lab 3 state looks good! ✅"
        info "You can proceed with Lab 4 exercises."
        return 0
    else
        warn "Lab 3 seems incomplete! ⚠"
        warn "Please complete Lab 3 before starting Lab 4."
        warn "See: ../03-kubernetes-basics-lab/README.md"
        return 1
    fi
}

# ==========================================================================
# Clean Up Lab 4 Resources
# ==========================================================================
clean_lab4() {
    info "Cleaning up Lab 4 resources..."
    
    # Remove Ingress
    kubectl delete ingress --all 2>/dev/null || true
    info "✓ Ingress resources removed"
    
    # Remove HPA
    kubectl delete hpa --all 2>/dev/null || true
    info "✓ HPA resources removed"
    
    # Remove ResourceQuota
    kubectl delete resourcequota --all 2>/dev/null || true
    info "✓ ResourceQuota removed"
    
    # Remove LimitRange
    kubectl delete limitrange --all 2>/dev/null || true
    info "✓ LimitRange removed"
    
    # Remove Helm releases (if any)
    if command -v helm &> /dev/null; then
        local releases=$(helm list --short 2>/dev/null)
        if [ -n "$releases" ]; then
            echo "$releases" | xargs -r helm uninstall
            info "✓ Helm releases removed"
        fi
    fi
    
    # Remove Ingress Controller (optional - uncomment if needed)
    # kubectl delete namespace ingress-nginx 2>/dev/null || true
    # info "✓ Ingress Controller removed"
    
    info "Lab 4 cleanup complete! ✅"
}

# ==========================================================================
# Main Command Handler
# ==========================================================================
case "${1:-check}" in
    check)
        check_prerequisites
        ;;
    install)
        install_components
        ;;
    verify)
        verify_lab3
        ;;
    clean)
        clean_lab4
        ;;
    *)
        echo "Usage: $0 {check|install|verify|clean}"
        echo ""
        echo "Commands:"
        echo "  check      - Check prerequisites"
        echo "  install    - Install missing components (Helm)"
        echo "  verify     - Verify Lab 3 state"
        echo "  clean      - Clean up Lab 4 resources"
        exit 1
        ;;
esac
