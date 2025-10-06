#!/bin/bash

################################################################################
# DevSecOps Project - Clean All Resources
################################################################################
#
# Purpose: Clean up all local resources including volumes
#
# Usage: ./clean-all.sh
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICES_DIR="${PROJECT_ROOT}/02-services"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN:${NC} $*"
}

log_warn "⚠️  This will remove all containers, volumes, and data!"
read -p "Are you sure? (yes/no): " confirm

if [[ "${confirm}" != "yes" ]]; then
    log "Cancelled"
    exit 0
fi

log "Cleaning up all resources..."

cd "${SERVICES_DIR}"

# Stop and remove everything
docker compose down -v --remove-orphans

# Remove dangling images
docker image prune -f

# Remove dangling volumes
docker volume prune -f

log "✅ All resources cleaned up"
