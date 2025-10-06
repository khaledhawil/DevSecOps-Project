#!/bin/bash

################################################################################
# DevSecOps Project - Health Check
################################################################################
#
# Purpose: Check health of all services
#
# Usage: ./health-check.sh [environment]
# Example: ./health-check.sh          # Check local services
#          ./health-check.sh dev      # Check Kubernetes services
#
################################################################################

set -euo pipefail

# Configuration
ENVIRONMENT="${1:-local}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $*"
}

check_url() {
    local name=$1
    local url=$2
    
    if curl -f -s -o /dev/null "${url}"; then
        echo -e "  ${GREEN}✓${NC} ${name}: ${GREEN}Healthy${NC}"
        return 0
    else
        echo -e "  ${RED}✗${NC} ${name}: ${RED}Unhealthy${NC}"
        return 1
    fi
}

check_local() {
    log "Checking local services..."
    
    echo ""
    check_url "User Service" "http://localhost:8081/health"
    check_url "Auth Service" "http://localhost:8082/health"
    check_url "Notification Service" "http://localhost:8083/health"
    check_url "Analytics Service" "http://localhost:8084/actuator/health"
    check_url "Frontend" "http://localhost:3000"
    echo ""
}

check_kubernetes() {
    log "Checking Kubernetes services in environment: ${ENVIRONMENT}"
    
    local namespace="devsecops-${ENVIRONMENT}"
    
    echo ""
    log_info "Pod status:"
    kubectl get pods -n "${namespace}" 2>/dev/null || log_error "Namespace ${namespace} not found"
    
    echo ""
    log_info "Service status:"
    kubectl get svc -n "${namespace}" 2>/dev/null
    
    echo ""
}

main() {
    if [[ "${ENVIRONMENT}" == "local" ]]; then
        check_local
    else
        check_kubernetes
    fi
}

main "$@"
