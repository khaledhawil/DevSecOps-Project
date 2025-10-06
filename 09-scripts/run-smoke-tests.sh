#!/bin/bash

################################################################################
# DevSecOps Project - Run Smoke Tests
################################################################################
#
# Purpose: Run smoke tests after deployment
#
# Usage: ./run-smoke-tests.sh [environment]
# Example: ./run-smoke-tests.sh dev
#
################################################################################

set -euo pipefail

# Configuration
ENVIRONMENT="${1:-local}"
NAMESPACE="devsecops-${ENVIRONMENT}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                 DevSecOps - Smoke Tests                              ║
║                                                                      ║
║              Running post-deployment validation...                   ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    log_info "Testing ${name}..."
    
    local status=$(curl -s -o /dev/null -w "%{http_code}" "${url}" || echo "000")
    
    if [[ "${status}" == "${expected_status}" ]]; then
        log "  ✓ ${name}: ${status}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "  ✗ ${name}: ${status} (expected ${expected_status})"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

test_local() {
    log "Running smoke tests for local environment..."
    
    test_endpoint "User Service Health" "http://localhost:8081/health"
    test_endpoint "Auth Service Health" "http://localhost:8082/health"
    test_endpoint "Notification Service Health" "http://localhost:8083/health"
    test_endpoint "Analytics Service Health" "http://localhost:8084/actuator/health"
    test_endpoint "Frontend" "http://localhost:3000"
}

test_kubernetes() {
    log "Running smoke tests for Kubernetes environment: ${ENVIRONMENT}"
    
    # Check if pods are running
    log_info "Checking pod status..."
    local pod_count=$(kubectl get pods -n "${NAMESPACE}" --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [[ ${pod_count} -gt 0 ]]; then
        log "  ✓ ${pod_count} pods running"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "  ✗ No pods running"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Check services
    log_info "Checking services..."
    local services=(user-service auth-service notification-service analytics-service frontend)
    
    for service in "${services[@]}"; do
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if kubectl get svc "${service}" -n "${NAMESPACE}" &> /dev/null; then
            log "  ✓ Service ${service} exists"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            log_error "  ✗ Service ${service} not found"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    done
}

print_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}Smoke Test Summary${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Environment:     ${YELLOW}${ENVIRONMENT}${NC}                                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Total Tests:     ${YELLOW}${TOTAL_TESTS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Passed:          ${GREEN}${PASSED_TESTS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Failed:          ${RED}${FAILED_TESTS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

main() {
    print_banner
    
    if [[ "${ENVIRONMENT}" == "local" ]]; then
        test_local
    else
        test_kubernetes
    fi
    
    print_summary
    
    if [[ ${FAILED_TESTS} -gt 0 ]]; then
        log_error "Some smoke tests failed!"
        exit 1
    fi
    
    log "✅ All smoke tests passed!"
}

main "$@"
