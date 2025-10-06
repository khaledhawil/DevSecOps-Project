#!/bin/bash

################################################################################
# DevSecOps Project - Stop Local Services
################################################################################
#
# Purpose: Stop all local Docker Compose services
#
# Usage: ./stop-local.sh
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICES_DIR="${PROJECT_ROOT}/02-services"
COMPOSE_FILE="${SERVICES_DIR}/docker-compose.yml"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $*"
}

log "Stopping local services..."

cd "${SERVICES_DIR}"

# Stop services
docker compose down

log "✅ All services stopped"
log_info "Data volumes are preserved. To remove them, run: ./clean-all.sh"
