#!/bin/bash

##############################################################################
# Kubernetes Multi-User Lab Setup Script
# Purpose: Create user-specific Kind cluster for K8s labs (Lab 3-10)
# Usage: bash labs/k8s-multi-user-setup.sh [create|delete|status]
##############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CURRENT_USER=$(whoami)
CLUSTER_NAME="${CURRENT_USER}-k8s-lab"
KUBECONFIG_DIR="${HOME}/.kube"
KUBECONFIG_FILE="${KUBECONFIG_DIR}/config-${CURRENT_USER}"

# Calculate user-specific ports
USER_ID=$(id -u)
USER_PORT_OFFSET=$((USER_ID % 1000))
API_SERVER_PORT=$((6443 + USER_PORT_OFFSET))
HTTP_PORT=$((30080 + USER_PORT_OFFSET))
HTTPS_PORT=$((30443 + USER_PORT_OFFSET))

##############################################################################
# Functions
##############################################################################

show_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}Kubernetes Multi-User Lab Setup${NC}                        ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Docker installed${NC}"

    # Check Kind
    if ! command -v kind &> /dev/null; then
        echo -e "${YELLOW}⚠️  Kind not found. Installing...${NC}"
        install_kind
    else
        echo -e "${GREEN}✅ Kind installed ($(kind version))${NC}"
    fi

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${YELLOW}⚠️  kubectl not found. Installing...${NC}"
        install_kubectl
    else
        echo -e "${GREEN}✅ kubectl installed ($(kubectl version --client -o json | grep gitVersion | head -1))${NC}"
    fi

    echo ""
}

install_kind() {
    echo -e "${YELLOW}Installing Kind...${NC}"

    # Download Kind binary
    curl -Lo /tmp/kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x /tmp/kind
    sudo mv /tmp/kind /usr/local/bin/kind

    echo -e "${GREEN}✅ Kind installed successfully${NC}"
}

install_kubectl() {
    echo -e "${YELLOW}Installing kubectl...${NC}"

    # Download kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/kubectl

    echo -e "${GREEN}✅ kubectl installed successfully${NC}"
}

create_cluster() {
    echo -e "${GREEN}Creating Kind cluster: ${YELLOW}${CLUSTER_NAME}${NC}"
    echo ""

    # Create Kind configuration
    KIND_CONFIG="/tmp/kind-config-${CURRENT_USER}.yaml"
    cat > "${KIND_CONFIG}" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}
networking:
  apiServerAddress: "127.0.0.1"
  apiServerPort: ${API_SERVER_PORT}
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "user=${CURRENT_USER}"
    extraPortMappings:
      # HTTP traffic (NodePort services)
      - containerPort: 30080
        hostPort: ${HTTP_PORT}
        protocol: TCP
      # HTTPS traffic (NodePort services)
      - containerPort: 30443
        hostPort: ${HTTPS_PORT}
        protocol: TCP
      # Ingress HTTP
      - containerPort: 80
        hostPort: $((8080 + USER_PORT_OFFSET))
        protocol: TCP
      # Ingress HTTPS
      - containerPort: 443
        hostPort: $((8443 + USER_PORT_OFFSET))
        protocol: TCP
  - role: worker
    labels:
      user: ${CURRENT_USER}
EOF

    echo -e "${YELLOW}Configuration:${NC}"
    echo -e "   Cluster name:    ${YELLOW}${CLUSTER_NAME}${NC}"
    echo -e "   API server port: ${YELLOW}${API_SERVER_PORT}${NC}"
    echo -e "   HTTP port:       ${YELLOW}${HTTP_PORT}${NC}"
    echo -e "   HTTPS port:      ${YELLOW}${HTTPS_PORT}${NC}"
    echo ""

    # Create cluster
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "${YELLOW}⚠️  Cluster ${CLUSTER_NAME} already exists${NC}"
        echo -e "   Use '${YELLOW}bash $0 delete${NC}' to remove it first"
        return 1
    fi

    kind create cluster --config="${KIND_CONFIG}"

    # Export kubeconfig
    mkdir -p "${KUBECONFIG_DIR}"
    kind export kubeconfig --name="${CLUSTER_NAME}" --kubeconfig="${KUBECONFIG_FILE}"

    echo ""
    echo -e "${GREEN}✅ Cluster created successfully!${NC}"
    echo ""

    # Create user-specific kubectl config
    create_kubectl_config

    # Show cluster info
    show_cluster_info

    # Create user-specific namespace
    create_user_namespace

    # Cleanup
    rm -f "${KIND_CONFIG}"
}

create_kubectl_config() {
    # Add to main kubeconfig if it exists
    MAIN_KUBECONFIG="${KUBECONFIG_DIR}/config"

    if [ -f "${MAIN_KUBECONFIG}" ]; then
        echo -e "${YELLOW}Merging kubeconfig...${NC}"
        KUBECONFIG="${MAIN_KUBECONFIG}:${KUBECONFIG_FILE}" kubectl config view --flatten > /tmp/merged-config
        mv /tmp/merged-config "${MAIN_KUBECONFIG}"
        chmod 600 "${MAIN_KUBECONFIG}"
    else
        cp "${KUBECONFIG_FILE}" "${MAIN_KUBECONFIG}"
        chmod 600 "${MAIN_KUBECONFIG}"
    fi

    # Set current context
    kubectl config use-context "kind-${CLUSTER_NAME}"

    echo -e "${GREEN}✅ Kubeconfig updated${NC}"
}

create_user_namespace() {
    echo ""
    echo -e "${YELLOW}Creating user namespace...${NC}"

    # Create default namespace for user
    kubectl create namespace "${CURRENT_USER}-default" --dry-run=client -o yaml | kubectl apply -f -
    kubectl label namespace "${CURRENT_USER}-default" user="${CURRENT_USER}"

    # Set as default namespace
    kubectl config set-context --current --namespace="${CURRENT_USER}-default"

    echo -e "${GREEN}✅ Namespace created: ${YELLOW}${CURRENT_USER}-default${NC}"
    echo ""
}

show_cluster_info() {
    echo -e "${GREEN}=== Cluster Information ===${NC}"
    echo ""

    # Cluster details
    echo -e "${YELLOW}Cluster:${NC}"
    kubectl cluster-info --context "kind-${CLUSTER_NAME}" | head -3
    echo ""

    # Nodes
    echo -e "${YELLOW}Nodes:${NC}"
    kubectl get nodes --context "kind-${CLUSTER_NAME}"
    echo ""

    # Context
    echo -e "${YELLOW}Current context:${NC}"
    kubectl config current-context
    echo ""

    # Ports
    echo -e "${YELLOW}Exposed ports:${NC}"
    echo -e "   API Server:  ${YELLOW}https://127.0.0.1:${API_SERVER_PORT}${NC}"
    echo -e "   HTTP:        ${YELLOW}http://localhost:${HTTP_PORT}${NC}"
    echo -e "   HTTPS:       ${YELLOW}https://localhost:${HTTPS_PORT}${NC}"
    echo -e "   Ingress HTTP:  ${YELLOW}http://localhost:$((8080 + USER_PORT_OFFSET))${NC}"
    echo -e "   Ingress HTTPS: ${YELLOW}https://localhost:$((8443 + USER_PORT_OFFSET))${NC}"
    echo ""
}

delete_cluster() {
    echo -e "${YELLOW}Deleting cluster: ${CLUSTER_NAME}${NC}"

    if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "${RED}❌ Cluster ${CLUSTER_NAME} does not exist${NC}"
        return 1
    fi

    # Delete cluster
    kind delete cluster --name="${CLUSTER_NAME}"

    # Remove kubeconfig
    if [ -f "${KUBECONFIG_FILE}" ]; then
        rm -f "${KUBECONFIG_FILE}"
    fi

    # Remove context from main kubeconfig
    kubectl config delete-context "kind-${CLUSTER_NAME}" 2>/dev/null || true
    kubectl config delete-cluster "kind-${CLUSTER_NAME}" 2>/dev/null || true

    echo -e "${GREEN}✅ Cluster deleted successfully${NC}"
}

show_status() {
    echo -e "${GREEN}=== Cluster Status ===${NC}"
    echo ""

    # Check if cluster exists
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        echo -e "${GREEN}✅ Cluster ${YELLOW}${CLUSTER_NAME}${GREEN} is running${NC}"
        echo ""

        # Show nodes
        echo -e "${YELLOW}Nodes:${NC}"
        kubectl get nodes --context "kind-${CLUSTER_NAME}"
        echo ""

        # Show namespaces
        echo -e "${YELLOW}User namespaces:${NC}"
        kubectl get namespaces --context "kind-${CLUSTER_NAME}" -l "user=${CURRENT_USER}"
        echo ""

        # Show pods
        echo -e "${YELLOW}Running pods:${NC}"
        kubectl get pods -A --context "kind-${CLUSTER_NAME}" | grep -v "kube-system" || echo "   No user pods running"
        echo ""
    else
        echo -e "${RED}❌ Cluster ${CLUSTER_NAME} does not exist${NC}"
        echo -e "   Use '${YELLOW}bash $0 create${NC}' to create it"
        echo ""
    fi
}

create_lab_helpers() {
    echo -e "${YELLOW}Creating Kubernetes lab helpers...${NC}"

    # Create kubectl aliases
    cat >> "${HOME}/.lab-aliases.sh" <<EOF

# Kubernetes multi-user aliases
alias k='kubectl --context kind-${CLUSTER_NAME}'
alias kns='kubectl config set-context --current --namespace'
alias kgp='kubectl get pods --context kind-${CLUSTER_NAME}'
alias kgs='kubectl get services --context kind-${CLUSTER_NAME}'
alias kgn='kubectl get namespaces --context kind-${CLUSTER_NAME} -l user=${CURRENT_USER}'
alias kdp='kubectl describe pod --context kind-${CLUSTER_NAME}'
alias kl='kubectl logs --context kind-${CLUSTER_NAME}'
alias kx='kubectl exec -it --context kind-${CLUSTER_NAME}'

# Lab-specific helpers
export LAB_CLUSTER="${CLUSTER_NAME}"
export LAB_NAMESPACE="${CURRENT_USER}-default"
export LAB_USER="${CURRENT_USER}"
EOF

    echo -e "${GREEN}✅ Kubernetes aliases created${NC}"
    echo -e "   Reload: ${YELLOW}source ~/.bashrc${NC}"
}

show_usage() {
    echo ""
    echo "Usage: bash $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  create   - Create user-specific Kind cluster"
    echo "  delete   - Delete user-specific Kind cluster"
    echo "  status   - Show cluster status"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  bash $0 create"
    echo "  bash $0 status"
    echo "  bash $0 delete"
    echo ""
}

##############################################################################
# Main
##############################################################################

show_header

case "${1:-help}" in
    create)
        check_prerequisites
        create_cluster
        create_lab_helpers
        echo -e "${GREEN}=== Setup Complete! ===${NC}"
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  1. Reload shell: ${YELLOW}source ~/.bashrc${NC}"
        echo "  2. Verify cluster: ${YELLOW}k get nodes${NC}"
        echo "  3. Start labs: ${YELLOW}cd labs/03-kubernetes-basics-lab${NC}"
        echo ""
        ;;
    delete)
        delete_cluster
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac
