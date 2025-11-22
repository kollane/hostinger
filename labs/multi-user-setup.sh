#!/bin/bash

##############################################################################
# Multi-User Lab Setup Script
# Purpose: Generate user-specific configuration for Docker labs (Lab 1-2)
# Usage: source labs/multi-user-setup.sh
##############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Multi-User Lab Setup ===${NC}"
echo ""

# 1. Detect current user
CURRENT_USER=$(whoami)
USER_ID=$(id -u)
echo -e "👤 Current user: ${YELLOW}${CURRENT_USER}${NC} (UID: ${USER_ID})"

# 2. Calculate user-specific port offset
# Use last 3 digits of UID to generate unique port offset
USER_PORT_OFFSET=$((USER_ID % 1000))
echo -e "📊 Port offset: ${YELLOW}${USER_PORT_OFFSET}${NC}"

# 3. Generate user-specific ports
export USER_PREFIX="${CURRENT_USER}"
export POSTGRES_PORT=$((5432 + USER_PORT_OFFSET))
export BACKEND_PORT=$((3000 + USER_PORT_OFFSET))
export FRONTEND_PORT=$((8080 + USER_PORT_OFFSET))

echo ""
echo -e "${GREEN}✅ User-Specific Configuration:${NC}"
echo -e "   PREFIX:        ${YELLOW}${USER_PREFIX}${NC}"
echo -e "   PostgreSQL:    ${YELLOW}localhost:${POSTGRES_PORT}${NC}"
echo -e "   Backend API:   ${YELLOW}localhost:${BACKEND_PORT}${NC}"
echo -e "   Frontend:      ${YELLOW}localhost:${FRONTEND_PORT}${NC}"
echo ""

# 4. Create user-specific .env file
ENV_FILE="${HOME}/.env-lab"
cat > "${ENV_FILE}" <<EOF
# Multi-User Lab Configuration
# Generated for user: ${CURRENT_USER}
# Generated at: $(date)

USER_PREFIX=${USER_PREFIX}
POSTGRES_PORT=${POSTGRES_PORT}
BACKEND_PORT=${BACKEND_PORT}
FRONTEND_PORT=${FRONTEND_PORT}

# Database configuration
DB_HOST=${USER_PREFIX}-postgres
DB_PORT=5432
DB_NAME=userdb
DB_USER=postgres
DB_PASSWORD=postgres

# Application configuration
API_URL=http://localhost:${BACKEND_PORT}
NODE_ENV=development
EOF

echo -e "${GREEN}✅ Created: ${YELLOW}${ENV_FILE}${NC}"
echo ""

# 5. Docker Compose helpers
cat > "${HOME}/.lab-aliases.sh" <<'EOF'
# Lab aliases for multi-user setup

# Docker Compose with user prefix
alias dc-up='docker compose -p $(whoami) --env-file ~/.env-lab up -d'
alias dc-down='docker compose -p $(whoami) --env-file ~/.env-lab down'
alias dc-logs='docker compose -p $(whoami) --env-file ~/.env-lab logs -f'
alias dc-ps='docker compose -p $(whoami) --env-file ~/.env-lab ps'
alias dc-restart='docker compose -p $(whoami) --env-file ~/.env-lab restart'

# Docker commands with user prefix
alias d-ps='docker ps --filter "name=$(whoami)-"'
alias d-logs='docker logs $(whoami)-'
alias d-exec='docker exec -it $(whoami)-'
alias d-stop-all='docker stop $(docker ps -q --filter "name=$(whoami)-")'
alias d-rm-all='docker rm $(docker ps -aq --filter "name=$(whoami)-")'

# Network and volume helpers
alias d-network-ls='docker network ls --filter "name=$(whoami)"'
alias d-volume-ls='docker volume ls --filter "name=$(whoami)"'

# Cleanup
alias d-cleanup='docker stop $(docker ps -q --filter "name=$(whoami)-"); docker rm $(docker ps -aq --filter "name=$(whoami)-"); docker network prune -f; docker volume prune -f'
EOF

echo -e "${GREEN}✅ Created: ${YELLOW}${HOME}/.lab-aliases.sh${NC}"
echo ""

# 6. Add to .bashrc if not already present
if ! grep -q ".lab-aliases.sh" "${HOME}/.bashrc" 2>/dev/null; then
    echo "" >> "${HOME}/.bashrc"
    echo "# Lab multi-user setup" >> "${HOME}/.bashrc"
    echo "source ${HOME}/.lab-aliases.sh" >> "${HOME}/.bashrc"
    echo -e "${GREEN}✅ Added aliases to .bashrc${NC}"
else
    echo -e "${YELLOW}⚠️  Aliases already in .bashrc${NC}"
fi

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo -e "📝 ${YELLOW}Next steps:${NC}"
echo -e "   1. Reload shell: ${YELLOW}source ~/.bashrc${NC}"
echo -e "   2. Navigate to lab: ${YELLOW}cd labs/01-docker-lab${NC}"
echo -e "   3. Start services: ${YELLOW}dc-up${NC}"
echo -e "   4. Check status: ${YELLOW}dc-ps${NC}"
echo ""
echo -e "📚 ${YELLOW}Available aliases:${NC}"
echo -e "   dc-up, dc-down, dc-logs, dc-ps, dc-restart"
echo -e "   d-ps, d-logs, d-exec, d-stop-all, d-cleanup"
echo ""
echo -e "🔗 ${YELLOW}Your service URLs:${NC}"
echo -e "   Backend:  http://localhost:${BACKEND_PORT}"
echo -e "   Frontend: http://localhost:${FRONTEND_PORT}"
echo ""
