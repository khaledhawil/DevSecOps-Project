#!/bin/bash

################################################################################
# DevSecOps Project - Quick Destroy Script
################################################################################
#
# Purpose: Quick destruction without backups (for dev/testing)
#
# Usage: ./quick-destroy.sh <environment>
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENT=${1:-dev}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

echo "========================================"
echo "Quick Infrastructure Destruction"
echo "Environment: ${ENVIRONMENT}"
echo "========================================"
echo ""

log_warn "⚠️  This will destroy ALL resources in ${ENVIRONMENT} environment!"
log_warn "⚠️  No backups will be created!"
echo ""
read -p "Type '${ENVIRONMENT}' to confirm: " confirm

if [ "$confirm" != "${ENVIRONMENT}" ]; then
    log "Cancelled"
    exit 0
fi

# Run full destroy script with force options
"${SCRIPT_DIR}/destroy-infrastructure.sh" "${ENVIRONMENT}" --skip-backup --force

log "✅ Destruction complete!"
