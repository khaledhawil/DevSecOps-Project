#!/bin/bash

################################################################################
# DevSecOps Project - Run All Tests
################################################################################
#
# Purpose: Execute all tests across all services
#
# This script runs:
#   1. Unit tests for each service
#   2. Integration tests
#   3. API tests
#   4. End-to-end tests
#   5. Generates coverage reports
#
# Usage: ./02-run-tests.sh [service]
# Example: ./02-run-tests.sh              # Run all tests
#          ./02-run-tests.sh user-service # Run tests for specific service
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICES_DIR="${PROJECT_ROOT}/02-services"
SERVICE="${1:-all}"

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

log_test() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] TEST:${NC} $*"
}

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                  DevSecOps - Test Suite Runner                       ║
║                                                                      ║
║                     Running all tests...                             ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

test_user_service() {
    log_test "Running User Service tests (Go)..."
    
    cd "${SERVICES_DIR}/user-service"
    
    # Run Go tests with coverage
    if go test -v -coverprofile=coverage.out ./... 2>&1 | tee test-output.log; then
        log "✓ User Service tests passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "✗ User Service tests failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # Generate coverage report
    go tool cover -html=coverage.out -o coverage.html 2>/dev/null || true
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

test_auth_service() {
    log_test "Running Auth Service tests (Node.js)..."
    
    cd "${SERVICES_DIR}/auth-service"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        npm install
    fi
    
    # Run npm tests
    if npm test 2>&1 | tee test-output.log; then
        log "✓ Auth Service tests passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "✗ Auth Service tests failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

test_notification_service() {
    log_test "Running Notification Service tests (Python)..."
    
    cd "${SERVICES_DIR}/notification-service"
    
    # Create virtual environment if needed
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install dependencies
    pip install -q -r requirements.txt
    pip install -q pytest pytest-cov
    
    # Run pytest with coverage
    if pytest --cov=app --cov-report=html --cov-report=term 2>&1 | tee test-output.log; then
        log "✓ Notification Service tests passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "✗ Notification Service tests failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    deactivate
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

test_analytics_service() {
    log_test "Running Analytics Service tests (Java)..."
    
    cd "${SERVICES_DIR}/analytics-service"
    
    # Run Maven tests
    if mvn test 2>&1 | tee test-output.log; then
        log "✓ Analytics Service tests passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "✗ Analytics Service tests failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

test_frontend() {
    log_test "Running Frontend tests (React)..."
    
    cd "${SERVICES_DIR}/frontend"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        npm install
    fi
    
    # Run npm tests
    if npm test -- --watchAll=false 2>&1 | tee test-output.log; then
        log "✓ Frontend tests passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "✗ Frontend tests failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

run_integration_tests() {
    log_test "Running Integration Tests..."
    
    # Check if services are running
    if ! docker compose -f "${SERVICES_DIR}/docker-compose.yml" ps | grep -q "Up"; then
        log_info "Services not running. Starting services..."
        bash "${SCRIPT_DIR}/01-start-local.sh"
    fi
    
    # Run API tests
    log_info "Running API endpoint tests..."
    
    local endpoints=(
        "http://localhost:8081/health:User Service"
        "http://localhost:8082/health:Auth Service"
        "http://localhost:8083/health:Notification Service"
        "http://localhost:8084/actuator/health:Analytics Service"
    )
    
    for endpoint_info in "${endpoints[@]}"; do
        local endpoint="${endpoint_info%%:*}"
        local name="${endpoint_info##*:}"
        
        log_info "Testing ${name}..."
        if curl -f -s "${endpoint}" > /dev/null; then
            log "  ✓ ${name} is healthy"
        else
            log_error "  ✗ ${name} is not responding"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    done
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

print_summary() {
    local success_rate=0
    if [[ ${TOTAL_TESTS} -gt 0 ]]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                      ${GREEN}Test Summary${NC}                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Total Tests:     ${YELLOW}${TOTAL_TESTS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Passed:          ${GREEN}${PASSED_TESTS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Failed:          ${RED}${FAILED_TESTS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Success Rate:    ${YELLOW}${success_rate}%${NC}                                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main execution
main() {
    print_banner
    
    log "Starting test execution..."
    log "Service filter: ${SERVICE}"
    
    if [[ "${SERVICE}" == "all" ]]; then
        test_user_service
        test_auth_service
        test_notification_service
        test_analytics_service
        test_frontend
        run_integration_tests
    else
        case "${SERVICE}" in
            user-service)
                test_user_service
                ;;
            auth-service)
                test_auth_service
                ;;
            notification-service)
                test_notification_service
                ;;
            analytics-service)
                test_analytics_service
                ;;
            frontend)
                test_frontend
                ;;
            *)
                log_error "Unknown service: ${SERVICE}"
                echo "Valid services: user-service, auth-service, notification-service, analytics-service, frontend, all"
                exit 1
                ;;
        esac
    fi
    
    print_summary
    
    if [[ ${FAILED_TESTS} -gt 0 ]]; then
        log_error "Some tests failed!"
        exit 1
    fi
    
    log "✅ All tests passed!"
}

# Trap errors
trap 'log_error "Test execution failed"; exit 1' ERR

# Run main
main "$@"
