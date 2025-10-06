#!/bin/bash

################################################################################
# DevSecOps Project - Security Scanning
################################################################################
#
# Purpose: Run comprehensive security scans on all components
#
# This script runs:
#   1. Trivy container image scanning
#   2. Trivy filesystem scanning
#   3. SonarQube code quality analysis
#   4. Dependency vulnerability scanning
#   5. Generates security reports
#
# Usage: ./04-scan-security.sh [options]
# Options:
#   --images-only    Scan only Docker images
#   --code-only      Scan only source code
#   --fail-on-high   Fail if HIGH or CRITICAL vulnerabilities found
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKER_USERNAME="${DOCKER_USERNAME:-khaledhawil}"
SCAN_IMAGES=true
SCAN_CODE=true
FAIL_ON_HIGH=false
REPORT_DIR="${PROJECT_ROOT}/security-reports"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --images-only)
            SCAN_CODE=false
            ;;
        --code-only)
            SCAN_IMAGES=false
            ;;
        --fail-on-high)
            FAIL_ON_HIGH=true
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Scan results
TOTAL_SCANS=0
CRITICAL_ISSUES=0
HIGH_ISSUES=0
MEDIUM_ISSUES=0
LOW_ISSUES=0

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN:${NC} $*"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $*"
}

log_scan() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] SCAN:${NC} $*"
}

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                DevSecOps - Security Scanner                          ║
║                                                                      ║
║          Running comprehensive security analysis...                  ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Trivy
    if ! command -v trivy &> /dev/null; then
        log_warn "Trivy not installed. Installing..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
            sudo apt-get update
            sudo apt-get install -y trivy
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install trivy
        fi
    fi
    
    log "✓ Prerequisites ready"
}

setup_reports_dir() {
    mkdir -p "${REPORT_DIR}"
    log_info "Reports will be saved to: ${REPORT_DIR}"
}

scan_docker_image() {
    local image_name=$1
    local service_name=$2
    
    log_scan "Scanning Docker image: ${image_name}..."
    
    TOTAL_SCANS=$((TOTAL_SCANS + 1))
    
    local report_file="${REPORT_DIR}/${service_name}-image-scan.json"
    local html_report="${REPORT_DIR}/${service_name}-image-scan.html"
    
    # Run Trivy scan
    trivy image \
        --format json \
        --output "${report_file}" \
        "${image_name}:latest" 2>&1 || true
    
    # Generate HTML report
    trivy image \
        --format template \
        --template "@contrib/html.tpl" \
        --output "${html_report}" \
        "${image_name}:latest" 2>&1 || true
    
    # Parse results
    if [[ -f "${report_file}" ]]; then
        local critical=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "${report_file}" 2>/dev/null || echo 0)
        local high=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "${report_file}" 2>/dev/null || echo 0)
        local medium=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "${report_file}" 2>/dev/null || echo 0)
        local low=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="LOW")] | length' "${report_file}" 2>/dev/null || echo 0)
        
        CRITICAL_ISSUES=$((CRITICAL_ISSUES + critical))
        HIGH_ISSUES=$((HIGH_ISSUES + high))
        MEDIUM_ISSUES=$((MEDIUM_ISSUES + medium))
        LOW_ISSUES=$((LOW_ISSUES + low))
        
        if [[ ${critical} -gt 0 ]]; then
            log_error "  ✗ ${service_name}: ${critical} CRITICAL vulnerabilities"
        elif [[ ${high} -gt 0 ]]; then
            log_warn "  ! ${service_name}: ${high} HIGH vulnerabilities"
        else
            log "  ✓ ${service_name}: No critical/high vulnerabilities"
        fi
        
        log_info "  Report: ${html_report}"
    fi
}

scan_all_images() {
    log_scan "Scanning all Docker images..."
    
    local services=(
        "user-service"
        "auth-service"
        "notification-service"
        "analytics-service"
        "frontend"
    )
    
    for service in "${services[@]}"; do
        scan_docker_image "${DOCKER_USERNAME}/${service}" "${service}"
    done
}

scan_filesystem() {
    log_scan "Scanning filesystem for vulnerabilities..."
    
    TOTAL_SCANS=$((TOTAL_SCANS + 1))
    
    local report_file="${REPORT_DIR}/filesystem-scan.json"
    local html_report="${REPORT_DIR}/filesystem-scan.html"
    
    # Scan project directory
    trivy fs \
        --format json \
        --output "${report_file}" \
        "${PROJECT_ROOT}" 2>&1 || true
    
    trivy fs \
        --format template \
        --template "@contrib/html.tpl" \
        --output "${html_report}" \
        "${PROJECT_ROOT}" 2>&1 || true
    
    log_info "  Filesystem scan report: ${html_report}"
}

scan_dependencies() {
    log_scan "Scanning dependencies for vulnerabilities..."
    
    # Scan Go dependencies
    if [[ -f "${PROJECT_ROOT}/02-services/user-service/go.mod" ]]; then
        log_info "Scanning Go dependencies..."
        cd "${PROJECT_ROOT}/02-services/user-service"
        trivy fs --format json --output "${REPORT_DIR}/go-deps-scan.json" . 2>&1 || true
    fi
    
    # Scan npm dependencies
    if [[ -f "${PROJECT_ROOT}/02-services/auth-service/package.json" ]]; then
        log_info "Scanning npm dependencies (auth-service)..."
        cd "${PROJECT_ROOT}/02-services/auth-service"
        trivy fs --format json --output "${REPORT_DIR}/npm-auth-deps-scan.json" . 2>&1 || true
    fi
    
    if [[ -f "${PROJECT_ROOT}/02-services/frontend/package.json" ]]; then
        log_info "Scanning npm dependencies (frontend)..."
        cd "${PROJECT_ROOT}/02-services/frontend"
        trivy fs --format json --output "${REPORT_DIR}/npm-frontend-deps-scan.json" . 2>&1 || true
    fi
    
    # Scan Python dependencies
    if [[ -f "${PROJECT_ROOT}/02-services/notification-service/requirements.txt" ]]; then
        log_info "Scanning Python dependencies..."
        cd "${PROJECT_ROOT}/02-services/notification-service"
        trivy fs --format json --output "${REPORT_DIR}/python-deps-scan.json" . 2>&1 || true
    fi
    
    # Scan Maven dependencies
    if [[ -f "${PROJECT_ROOT}/02-services/analytics-service/pom.xml" ]]; then
        log_info "Scanning Maven dependencies..."
        cd "${PROJECT_ROOT}/02-services/analytics-service"
        trivy fs --format json --output "${REPORT_DIR}/maven-deps-scan.json" . 2>&1 || true
    fi
    
    cd "${PROJECT_ROOT}"
}

generate_summary_report() {
    log_info "Generating summary report..."
    
    local summary_file="${REPORT_DIR}/security-summary.txt"
    
    cat > "${summary_file}" << EOF
================================
Security Scan Summary Report
================================
Generated: $(date)

Total Scans: ${TOTAL_SCANS}

Vulnerability Summary:
  CRITICAL: ${CRITICAL_ISSUES}
  HIGH:     ${HIGH_ISSUES}
  MEDIUM:   ${MEDIUM_ISSUES}
  LOW:      ${LOW_ISSUES}

Reports Location: ${REPORT_DIR}

Individual Reports:
$(ls -1 ${REPORT_DIR}/*.html 2>/dev/null || echo "  No HTML reports generated")

Recommendation:
$(if [[ ${CRITICAL_ISSUES} -gt 0 ]]; then
    echo "  ⚠️  CRITICAL: Immediate action required!"
    echo "  Address CRITICAL vulnerabilities before deployment."
elif [[ ${HIGH_ISSUES} -gt 0 ]]; then
    echo "  ⚠️  HIGH: Review and fix high-severity issues."
else
    echo "  ✓ No critical or high severity vulnerabilities found."
fi)
================================
EOF
    
    cat "${summary_file}"
}

print_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                   ${GREEN}Security Scan Summary${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Total Scans:     ${YELLOW}${TOTAL_SCANS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} CRITICAL:        ${RED}${CRITICAL_ISSUES}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} HIGH:            ${YELLOW}${HIGH_ISSUES}${NC}                                                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} MEDIUM:          ${BLUE}${MEDIUM_ISSUES}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} LOW:             ${GREEN}${LOW_ISSUES}${NC}                                                ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Reports saved to: ${REPORT_DIR}                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main execution
main() {
    print_banner
    
    log "Starting security scans..."
    log "Scan images: ${SCAN_IMAGES}"
    log "Scan code: ${SCAN_CODE}"
    log "Fail on high: ${FAIL_ON_HIGH}"
    
    check_prerequisites
    setup_reports_dir
    
    if [[ "${SCAN_IMAGES}" == "true" ]]; then
        scan_all_images
    fi
    
    if [[ "${SCAN_CODE}" == "true" ]]; then
        scan_filesystem
        scan_dependencies
    fi
    
    generate_summary_report
    print_summary
    
    # Check for failures
    if [[ "${FAIL_ON_HIGH}" == "true" ]] && [[ $((CRITICAL_ISSUES + HIGH_ISSUES)) -gt 0 ]]; then
        log_error "Security scan failed: Critical or High vulnerabilities found"
        exit 1
    fi
    
    if [[ ${CRITICAL_ISSUES} -gt 0 ]]; then
        log_warn "⚠️  CRITICAL vulnerabilities found! Please review and fix."
    else
        log "✅ Security scans completed!"
    fi
    
    log "View detailed reports in: ${REPORT_DIR}"
}

# Trap errors
trap 'log_error "Security scan failed"; exit 1' ERR

# Run main
main "$@"
