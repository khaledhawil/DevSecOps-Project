#!/bin/bash

################################################################################
# DevSecOps Project - Complete Deployment Script
################################################################################
#
# Purpose: Deploy the entire DevSecOps platform end-to-end
#
# This script orchestrates:
#   1. Prerequisites validation
#   2. Docker image building
#   3. Security scanning
#   4. Infrastructure deployment (Terraform)
#   5. Kubernetes deployment
#   6. Monitoring stack deployment
#   7. Security tools deployment
#   8. GitOps setup (ArgoCD)
#   9. Jenkins CI/CD setup
#   10. Flux CD setup
#   11. Smoke tests
#
# Usage: ./00-deploy-all.sh <environment>
# Example: ./00-deploy-all.sh dev
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENVIRONMENT="${1:-dev}"
DOCKER_USERNAME="${DOCKER_USERNAME:-khaledhawil}"
GITHUB_USERNAME="${GITHUB_USERNAME:-khaledhawil}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
LOG_DIR="${PROJECT_ROOT}/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/deploy-all-$(date +%Y%m%d-%H%M%S).log"

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*" | tee -a "${LOG_FILE}"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN:${NC} $*" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $*" | tee -a "${LOG_FILE}"
}

log_step() {
    echo -e "${MAGENTA}[$(date +'%Y-%m-%d %H:%M:%S')] ▶${NC} $*" | tee -a "${LOG_FILE}"
}

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║              DevSecOps Platform - Full Deployment                    ║
║                                                                      ║
║  Complete automation for infrastructure, services, and monitoring    ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_summary() {
    local start_time=$1
    local end_time=$2
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}Deployment Summary${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Environment:              ${YELLOW}${ENVIRONMENT}${NC}                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Total Duration:           ${YELLOW}${minutes}m ${seconds}s${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Docker Username:          ${YELLOW}${DOCKER_USERNAME}${NC}                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Log File:                 ${YELLOW}${LOG_FILE}${NC}  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}✓ Deployment Complete!${NC}                          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

validate_environment() {
    local valid_envs=("dev" "staging" "prod")
    if [[ ! " ${valid_envs[@]} " =~ " ${ENVIRONMENT} " ]]; then
        log_error "Invalid environment: ${ENVIRONMENT}"
        echo "Valid environments: ${valid_envs[@]}"
        exit 1
    fi
}

confirm_deployment() {
    if [[ "${ENVIRONMENT}" == "prod" ]]; then
        echo ""
        log_warn "⚠️  You are about to deploy to PRODUCTION!"
        echo ""
        read -p "Are you absolutely sure? Type 'yes' to continue: " confirm
        if [[ "${confirm}" != "yes" ]]; then
            log_info "Deployment cancelled"
            exit 0
        fi
    fi
}

# Main deployment stages
stage_1_prerequisites() {
    log_step "Stage 1/9: Validating Prerequisites"
    if [[ -f "${SCRIPT_DIR}/setup-prerequisites.sh" ]]; then
        bash "${SCRIPT_DIR}/setup-prerequisites.sh" --check-only
    else
        log_warn "Prerequisites script not found, skipping validation"
    fi
}

stage_2_build_images() {
    log_step "Stage 2/9: Building Docker Images"
    bash "${SCRIPT_DIR}/03-build-images.sh"
}

stage_3_security_scan() {
    log_step "Stage 3/9: Running Security Scans"
    bash "${SCRIPT_DIR}/04-scan-security.sh"
}

stage_4_push_images() {
    log_step "Stage 4/9: Pushing Images to Registry"
    bash "${SCRIPT_DIR}/push-images.sh" "${DOCKER_USERNAME}"
}

stage_5_deploy_infrastructure() {
    log_step "Stage 5/9: Deploying Infrastructure (Terraform)"
    bash "${SCRIPT_DIR}/05-deploy-infrastructure.sh" "${ENVIRONMENT}"
}

stage_6_deploy_kubernetes() {
    log_step "Stage 6/9: Deploying Kubernetes Resources"
    bash "${SCRIPT_DIR}/06-deploy-kubernetes.sh" "${ENVIRONMENT}"
}

stage_7_deploy_monitoring() {
    log_step "Stage 7/9: Deploying Monitoring Stack"
    if [[ -f "${PROJECT_ROOT}/06-monitoring/scripts/deploy-monitoring.sh" ]]; then
        bash "${PROJECT_ROOT}/06-monitoring/scripts/deploy-monitoring.sh"
    else
        log_warn "Monitoring deployment script not found, skipping"
    fi
}

stage_8_deploy_security() {
    log_step "Stage 8/9: Deploying Security Tools"
    if [[ -f "${PROJECT_ROOT}/07-security/scripts/deploy-security.sh" ]]; then
        bash "${PROJECT_ROOT}/07-security/scripts/deploy-security.sh"
    else
        log_warn "Security deployment script not found, skipping"
    fi
}

stage_9_setup_gitops() {
    log_step "Stage 9/12: Setting up GitOps (ArgoCD)"
    bash "${SCRIPT_DIR}/07-setup-gitops.sh" "${ENVIRONMENT}"
}

stage_10_setup_jenkins() {
    log_step "Stage 10/12: Setting up Jenkins CI/CD"
    if [[ -f "${SCRIPT_DIR}/08-setup-jenkins.sh" ]]; then
        bash "${SCRIPT_DIR}/08-setup-jenkins.sh"
    else
        log_warn "Jenkins setup script not found, skipping"
    fi
}

stage_11_setup_flux() {
    log_step "Stage 11/12: Setting up Flux CD"
    if [[ -f "${SCRIPT_DIR}/09-setup-flux.sh" ]]; then
        bash "${SCRIPT_DIR}/09-setup-flux.sh" "${ENVIRONMENT}"
    else
        log_warn "Flux setup script not found, skipping"
    fi
}

stage_12_smoke_tests() {
    log_step "Stage 12/12: Running Smoke Tests"
    bash "${SCRIPT_DIR}/run-smoke-tests.sh" "${ENVIRONMENT}"
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    print_banner
    log "Starting complete deployment for environment: ${ENVIRONMENT}"
    log "Docker Username: ${DOCKER_USERNAME}"
    log "GitHub Username: ${GITHUB_USERNAME}"
    log "Log file: ${LOG_FILE}"
    
    validate_environment
    confirm_deployment
    
    # Execute all stages
    stage_1_prerequisites
    stage_2_build_images
    stage_3_security_scan
    stage_4_push_images
    stage_5_deploy_infrastructure
    stage_6_deploy_kubernetes
    stage_7_deploy_monitoring
    stage_8_deploy_security
    stage_9_setup_gitops
    stage_10_setup_jenkins
    stage_11_setup_flux
    stage_12_smoke_tests
    
    local end_time=$(date +%s)
    print_summary "${start_time}" "${end_time}"
    
    log "✅ Full deployment completed successfully!"
    log "Next steps:"
    log "  1. Check service health: ./health-check.sh"
    log "  2. View logs: ./view-logs.sh ${ENVIRONMENT}"
    log "  3. Access ArgoCD: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    log "  4. Access Jenkins: kubectl port-forward svc/jenkins -n jenkins 8080:8080"
    log "  5. Access Grafana: kubectl port-forward -n monitoring svc/grafana 3000:80"
    log "  6. Check Flux: flux get kustomizations"
}

# Trap errors
trap 'log_error "Deployment failed at line $LINENO. Check log file: ${LOG_FILE}"; exit 1' ERR

# Run main
main "$@"
