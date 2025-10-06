#!/bin/bash

################################################################################
# DevSecOps Project - Setup GitOps with ArgoCD
################################################################################
#
# Purpose: Install and configure ArgoCD for GitOps deployment
#
# This script:
#   1. Installs ArgoCD
#   2. Configures ArgoCD
#   3. Creates applications
#   4. Sets up repositories
#   5. Configures sync policies
#
# Usage: ./07-setup-gitops.sh <environment>
# Example: ./07-setup-gitops.sh dev
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARGOCD_DIR="${PROJECT_ROOT}/05-cicd/argocd"
ENVIRONMENT="${1:-dev}"
ARGOCD_NAMESPACE="argocd"
GITHUB_USERNAME="${GITHUB_USERNAME:-khaledhawil}"
GITHUB_REPO="${GITHUB_REPO:-devsecops-project}"

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

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN:${NC} $*"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $*"
}

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                DevSecOps - GitOps Setup                              ║
║                                                                      ║
║              Installing and configuring ArgoCD                       ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

validate_environment() {
    local valid_envs=("dev" "staging" "prod")
    if [[ ! " ${valid_envs[@]} " =~ " ${ENVIRONMENT} " ]]; then
        log_error "Invalid environment: ${ENVIRONMENT}"
        echo "Valid environments: ${valid_envs[@]}"
        exit 1
    fi
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        log_warn "Helm not installed. Installing ArgoCD with kubectl..."
    fi
    
    log "✓ All prerequisites met"
}

install_argocd() {
    log "Installing ArgoCD..."
    
    # Create namespace
    if ! kubectl get namespace "${ARGOCD_NAMESPACE}" &> /dev/null; then
        kubectl create namespace "${ARGOCD_NAMESPACE}"
        log "✓ Namespace created"
    else
        log_info "Namespace already exists"
    fi
    
    # Install ArgoCD
    if ! kubectl get deployment argocd-server -n "${ARGOCD_NAMESPACE}" &> /dev/null; then
        log_info "Installing ArgoCD manifests..."
        kubectl apply -n "${ARGOCD_NAMESPACE}" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # Wait for deployments
        log_info "Waiting for ArgoCD to be ready..."
        kubectl wait --for=condition=available --timeout=300s \
            deployment/argocd-server \
            deployment/argocd-repo-server \
            deployment/argocd-application-controller \
            -n "${ARGOCD_NAMESPACE}"
        
        log "✓ ArgoCD installed"
    else
        log_info "ArgoCD already installed"
    fi
}

configure_argocd() {
    log "Configuring ArgoCD..."
    
    # Apply custom configuration if exists
    if [[ -f "${ARGOCD_DIR}/argocd-config.yaml" ]]; then
        kubectl apply -f "${ARGOCD_DIR}/argocd-config.yaml" -n "${ARGOCD_NAMESPACE}"
        log "✓ Custom configuration applied"
    fi
}

get_argocd_password() {
    log "Retrieving ArgoCD admin password..."
    
    local password=$(kubectl -n "${ARGOCD_NAMESPACE}" get secret argocd-initial-admin-secret \
        -o jsonpath="{.data.password}" | base64 -d)
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                  ${GREEN}ArgoCD Access Information${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Username: ${YELLOW}admin${NC}                                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Password: ${YELLOW}${password}${NC}                                    ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Access UI:                                                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   kubectl port-forward svc/argocd-server -n argocd 8080:443     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Open: https://localhost:8080                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

create_argocd_projects() {
    log "Creating ArgoCD projects..."
    
    if [[ -f "${ARGOCD_DIR}/projects.yaml" ]]; then
        kubectl apply -f "${ARGOCD_DIR}/projects.yaml" -n "${ARGOCD_NAMESPACE}"
        log "✓ Projects created"
    else
        log_warn "Projects file not found, skipping"
    fi
}

create_applications() {
    log "Creating ArgoCD applications for ${ENVIRONMENT}..."
    
    local apps_dir="${ARGOCD_DIR}/applications/${ENVIRONMENT}"
    
    if [[ -d "${apps_dir}" ]]; then
        kubectl apply -f "${apps_dir}/" -n "${ARGOCD_NAMESPACE}"
        log "✓ Applications created"
    else
        log_warn "Applications directory not found: ${apps_dir}"
    fi
    
    # Apply app-of-apps if exists
    if [[ -f "${ARGOCD_DIR}/app-of-apps.yaml" ]]; then
        # Update with environment
        sed "s/ENVIRONMENT/${ENVIRONMENT}/g" "${ARGOCD_DIR}/app-of-apps.yaml" | \
            kubectl apply -f - -n "${ARGOCD_NAMESPACE}"
        log "✓ App-of-apps created"
    fi
}

configure_repository() {
    log "Configuring Git repository..."
    
    local repo_url="https://github.com/${GITHUB_USERNAME}/${GITHUB_REPO}"
    
    log_info "Repository: ${repo_url}"
    
    # Check if argocd CLI is available
    if command -v argocd &> /dev/null; then
        log_info "Adding repository via ArgoCD CLI..."
        
        # Port forward if needed
        local port_forward_pid=""
        if ! curl -k https://localhost:8080 &> /dev/null; then
            kubectl port-forward svc/argocd-server -n "${ARGOCD_NAMESPACE}" 8080:443 &
            port_forward_pid=$!
            sleep 5
        fi
        
        # Login
        local password=$(kubectl -n "${ARGOCD_NAMESPACE}" get secret argocd-initial-admin-secret \
            -o jsonpath="{.data.password}" | base64 -d)
        argocd login localhost:8080 --username admin --password "${password}" --insecure
        
        # Add repository
        argocd repo add "${repo_url}" --upsert
        
        # Kill port forward if we started it
        if [[ -n "${port_forward_pid}" ]]; then
            kill "${port_forward_pid}" 2>/dev/null || true
        fi
        
        log "✓ Repository configured"
    else
        log_warn "ArgoCD CLI not available. Configure repository manually via UI."
    fi
}

sync_applications() {
    log "Syncing applications..."
    
    if command -v argocd &> /dev/null; then
        # Get all applications
        local apps=$(kubectl get applications -n "${ARGOCD_NAMESPACE}" -o jsonpath='{.items[*].metadata.name}')
        
        for app in ${apps}; do
            log_info "Syncing ${app}..."
            argocd app sync "${app}" --grpc-web || true
        done
        
        log "✓ Applications synced"
    else
        log_info "Sync applications manually via UI or install ArgoCD CLI"
    fi
}

show_application_status() {
    log "Application status:"
    
    echo ""
    kubectl get applications -n "${ARGOCD_NAMESPACE}"
    echo ""
}

show_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}GitOps Setup Complete${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Environment:      ${YELLOW}${ENVIRONMENT}${NC}                                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} GitHub:           ${YELLOW}${GITHUB_USERNAME}/${GITHUB_REPO}${NC}               ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Useful Commands:                                                 ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Port forward:                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}     kubectl port-forward svc/argocd-server -n argocd 8080:443   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Get password:                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}     kubectl -n argocd get secret argocd-initial-admin-secret \\  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       -o jsonpath=\"{.data.password}\" | base64 -d                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   View applications:                                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}     kubectl get applications -n argocd                           ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main execution
main() {
    print_banner
    
    log "Starting GitOps setup for: ${ENVIRONMENT}"
    
    validate_environment
    check_prerequisites
    install_argocd
    configure_argocd
    get_argocd_password
    create_argocd_projects
    create_applications
    configure_repository
    show_application_status
    show_summary
    
    log "✅ GitOps setup completed successfully!"
    log ""
    log "Next steps:"
    log "  1. Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    log "  2. Run smoke tests: ./run-smoke-tests.sh ${ENVIRONMENT}"
    log "  3. Monitor applications in ArgoCD dashboard"
}

# Trap errors
trap 'log_error "GitOps setup failed at line $LINENO"; exit 1' ERR

# Run main
main "$@"
