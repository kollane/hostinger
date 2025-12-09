#!/bin/bash
#
# Labs Sync Script
# Syncs labs folder from host to LXD container(s)
#
# Usage:
#   ./sync-labs.sh                    # Sync to all containers
#   ./sync-labs.sh devops-k8s-student1  # Sync to specific container
#

set -e

# Configuration - adjust this path if needed
LABS_SOURCE="${LABS_SOURCE:-$(dirname "$0")/../labs}"
LABS_SOURCE=$(realpath "$LABS_SOURCE")

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

sync_to_container() {
  local container="$1"

  echo -e "${BLUE}Syncing labs to $container...${NC}"

  # Check if container exists and is running
  if ! lxc list --format csv -c n,s | grep -q "^${container},RUNNING"; then
    echo -e "${YELLOW}Warning: $container is not running, skipping${NC}"
    return 1
  fi

  # Create backup of existing labs (optional)
  lxc exec "$container" -- bash -c "
    if [ -d /home/labuser/labs ]; then
      tar czf /tmp/labs-backup-\$(date +%Y%m%d-%H%M%S).tar.gz -C /home/labuser labs 2>/dev/null || true
    fi
  "

  # Sync labs folder
  lxc file push -r "$LABS_SOURCE/" "$container/home/labuser/"

  # Fix permissions
  lxc exec "$container" -- chown -R labuser:labuser /home/labuser/labs
  lxc exec "$container" -- find /home/labuser/labs -name '*.sh' -exec chmod +x {} \;

  echo -e "${GREEN}$container synced successfully${NC}"
}

# Main
if [ ! -d "$LABS_SOURCE" ]; then
  echo "Error: Labs directory not found: $LABS_SOURCE"
  echo "Set LABS_SOURCE environment variable or run from infra/ folder"
  exit 1
fi

echo "Labs source: $LABS_SOURCE"
echo ""

if [ -n "$1" ]; then
  # Sync to specific container
  sync_to_container "$1"
else
  # Sync to all devops containers
  echo "Syncing to all devops containers..."
  echo ""

  containers=$(lxc list --format csv -c n | grep -E "^devops-(student|k8s-student)" || true)

  if [ -z "$containers" ]; then
    echo "No devops containers found"
    exit 0
  fi

  for container in $containers; do
    sync_to_container "$container" || true
  done
fi

echo ""
echo -e "${GREEN}Sync complete!${NC}"
