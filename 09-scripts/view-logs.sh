#!/bin/bash

################################################################################
# DevSecOps Project - View Logs
################################################################################
#
# Purpose: View logs from services
#
# Usage: ./view-logs.sh [environment] [service]
# Example: ./view-logs.sh local              # All local services
#          ./view-logs.sh local user-service  # Specific local service
#          ./view-logs.sh dev user-service    # Kubernetes service
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICES_DIR="${PROJECT_ROOT}/02-services"
ENVIRONMENT="${1:-local}"
SERVICE="${2:-}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

view_local_logs() {
    cd "${SERVICES_DIR}"
    
    if [[ -n "${SERVICE}" ]]; then
        log_info "Viewing logs for ${SERVICE}..."
        docker compose logs -f "${SERVICE}"
    else
        log_info "Viewing logs for all services..."
        docker compose logs -f
    fi
}

view_kubernetes_logs() {
    local namespace="devsecops-${ENVIRONMENT}"
    
    if [[ -n "${SERVICE}" ]]; then
        log_info "Viewing logs for ${SERVICE} in ${namespace}..."
        kubectl logs -f -n "${namespace}" -l "app=${SERVICE}"
    else
        log_info "Viewing logs for all services in ${namespace}..."
        kubectl logs -f -n "${namespace}" --all-containers=true --max-log-requests=10
    fi
}

main() {
    if [[ "${ENVIRONMENT}" == "local" ]]; then
        view_local_logs
    else
        view_kubernetes_logs
    fi
}

main "$@"
