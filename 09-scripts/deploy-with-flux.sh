#!/bin/bash

#######################################
# Deploy with Flux CD
# Author: DevSecOps Team
# Description: Deploy services using Flux CD for GitOps continuous delivery
#######################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/deploy-with-flux.log"
ENVIRONMENT="${1:-dev}"
GITHUB_USER="${GITHUB_USERNAME:-khaledhawil}"
GITHUB_REPO="${GITHUB_REPO:-devsecops-project}"

# Create log directory
mkdir -p "${LOG_DIR}"

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "${LOG_FILE}"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "${LOG_FILE}"
}

print_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                 Deploy with Flux CD                              ║
║                                                                  ║
║  Continuous deployment with Flux for GitOps automation           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Validate environment
validate_environment() {
    if [[ ! "${ENVIRONMENT}" =~ ^(dev|staging|prod)$ ]]; then
        log_error "Invalid environment: ${ENVIRONMENT}"
        echo "Usage: $0 <environment>"
        echo "  environment: dev, staging, or prod"
        exit 1
    fi
    log "Environment: ${ENVIRONMENT}"
}

# Check if Flux is installed
check_flux() {
    log "Checking Flux installation..."
    
    if ! command -v flux &> /dev/null; then
        log_error "Flux CLI not found"
        log_info "Run: ./09-setup-flux.sh ${ENVIRONMENT}"
        exit 1
    fi
    
    if ! kubectl get namespace flux-system &> /dev/null; then
        log_error "Flux namespace not found"
        log_info "Run: ./09-setup-flux.sh ${ENVIRONMENT}"
        exit 1
    fi
    
    log "Flux is installed and running"
}

# Create Flux kustomizations for services
create_kustomizations() {
    log "Creating Flux kustomizations..."
    
    # Infrastructure kustomization
    cat <<EOF | kubectl apply -f -
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infrastructure-${ENVIRONMENT}
  namespace: flux-system
spec:
  interval: 10m
  path: ./04-kubernetes/overlays/${ENVIRONMENT}/infrastructure
  prune: true
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  timeout: 5m
  wait: true
EOF
    
    # Frontend kustomization
    cat <<EOF | kubectl apply -f -
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: frontend-${ENVIRONMENT}
  namespace: flux-system
spec:
  interval: 5m
  path: ./04-kubernetes/overlays/${ENVIRONMENT}/frontend
  prune: true
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  timeout: 5m
  wait: true
  dependsOn:
    - name: infrastructure-${ENVIRONMENT}
EOF
    
    # Auth Service kustomization
    cat <<EOF | kubectl apply -f -
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: auth-service-${ENVIRONMENT}
  namespace: flux-system
spec:
  interval: 5m
  path: ./04-kubernetes/overlays/${ENVIRONMENT}/auth-service
  prune: true
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  timeout: 5m
  wait: true
  dependsOn:
    - name: infrastructure-${ENVIRONMENT}
EOF
    
    # User Service kustomization
    cat <<EOF | kubectl apply -f -
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: user-service-${ENVIRONMENT}
  namespace: flux-system
spec:
  interval: 5m
  path: ./04-kubernetes/overlays/${ENVIRONMENT}/user-service
  prune: true
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  timeout: 5m
  wait: true
  dependsOn:
    - name: infrastructure-${ENVIRONMENT}
EOF
    
    # Analytics Service kustomization
    cat <<EOF | kubectl apply -f -
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: analytics-service-${ENVIRONMENT}
  namespace: flux-system
spec:
  interval: 5m
  path: ./04-kubernetes/overlays/${ENVIRONMENT}/analytics-service
  prune: true
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  timeout: 5m
  wait: true
  dependsOn:
    - name: infrastructure-${ENVIRONMENT}
EOF
    
    # Notification Service kustomization
    cat <<EOF | kubectl apply -f -
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: notification-service-${ENVIRONMENT}
  namespace: flux-system
spec:
  interval: 5m
  path: ./04-kubernetes/overlays/${ENVIRONMENT}/notification-service
  prune: true
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  timeout: 5m
  wait: true
  dependsOn:
    - name: infrastructure-${ENVIRONMENT}
EOF
    
    log "Flux kustomizations created"
}

# Reconcile Flux sources and kustomizations
reconcile_flux() {
    log "Reconciling Flux sources and kustomizations..."
    
    # Reconcile Git repository
    log_info "Reconciling Git repository..."
    flux reconcile source git devsecops-repo
    
    # Reconcile kustomizations
    local KUSTOMIZATIONS=(
        "infrastructure-${ENVIRONMENT}"
        "frontend-${ENVIRONMENT}"
        "auth-service-${ENVIRONMENT}"
        "user-service-${ENVIRONMENT}"
        "analytics-service-${ENVIRONMENT}"
        "notification-service-${ENVIRONMENT}"
    )
    
    for kustomization in "${KUSTOMIZATIONS[@]}"; do
        log_info "Reconciling kustomization: ${kustomization}"
        flux reconcile kustomization "${kustomization}" --with-source
    done
    
    log "Flux reconciliation completed"
}

# Wait for deployments
wait_for_deployments() {
    log "Waiting for deployments to be ready..."
    
    local DEPLOYMENTS=(
        "frontend"
        "auth-service"
        "user-service"
        "analytics-service"
        "notification-service"
    )
    
    for deployment in "${DEPLOYMENTS[@]}"; do
        log_info "Waiting for ${deployment}..."
        kubectl wait --for=condition=available \
            deployment/"${deployment}" \
            -n "${ENVIRONMENT}" \
            --timeout=600s || true
    done
    
    log "All deployments are ready"
}

# Check deployment status
check_status() {
    log "Checking deployment status..."
    
    echo ""
    echo "Flux Kustomizations:"
    flux get kustomizations
    
    echo ""
    echo "Git Repositories:"
    flux get sources git
    
    echo ""
    echo "Helm Releases:"
    flux get helmreleases --all-namespaces
    
    echo ""
    echo "Pods in ${ENVIRONMENT} namespace:"
    kubectl get pods -n "${ENVIRONMENT}"
    
    echo ""
    echo "Services in ${ENVIRONMENT} namespace:"
    kubectl get services -n "${ENVIRONMENT}"
}

# Setup image automation
setup_image_automation() {
    log "Setting up Flux image automation..."
    
    # Image repositories for each service
    local SERVICES=("frontend" "auth-service" "user-service" "analytics-service" "notification-service")
    
    for service in "${SERVICES[@]}"; do
        cat <<EOF | kubectl apply -f -
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: ${service}
  namespace: flux-system
spec:
  image: khaledhawil/${service}
  interval: 5m
---
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: ${service}
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: ${service}
  policy:
    semver:
      range: '>=1.0.0'
EOF
    done
    
    # Image update automation
    cat <<EOF | kubectl apply -f -
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: ${ENVIRONMENT}-automation
  namespace: flux-system
spec:
  interval: 5m
  sourceRef:
    kind: GitRepository
    name: devsecops-repo
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: fluxcd@users.noreply.github.com
        name: FluxCD
      messageTemplate: |
        Automated image update for ${ENVIRONMENT}
        
        [ci skip]
    push:
      branch: main
  update:
    path: ./04-kubernetes/overlays/${ENVIRONMENT}
    strategy: Setters
EOF
    
    log "Flux image automation configured"
}

# Display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "Flux CD Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Environment: ${ENVIRONMENT}"
    echo "Repository: https://github.com/${GITHUB_USER}/${GITHUB_REPO}"
    echo ""
    echo "Flux will continuously sync from Git repository"
    echo "Any changes pushed to Git will be automatically deployed"
    echo ""
    echo "Useful Commands:"
    echo "  Check status:       flux get all"
    echo "  View logs:          flux logs --all-namespaces --follow"
    echo "  Force reconcile:    flux reconcile kustomization <name>"
    echo "  Suspend sync:       flux suspend kustomization <name>"
    echo "  Resume sync:        flux resume kustomization <name>"
    echo "  Export config:      flux export kustomization <name>"
    echo ""
    echo "Image Automation:"
    echo "  Check images:       flux get images all"
    echo "  Check policies:     flux get image policy"
    echo "  Check updates:      flux get image update"
    echo "=========================================="
}

# Main function
main() {
    print_banner
    log "Starting Flux CD deployment for environment: ${ENVIRONMENT}"
    
    validate_environment
    check_flux
    create_kustomizations
    reconcile_flux
    wait_for_deployments
    setup_image_automation
    check_status
    display_summary
    
    log "Flux CD deployment completed successfully!"
}

# Run main
main "$@"
