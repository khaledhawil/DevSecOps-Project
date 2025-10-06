#!/bin/bash

#######################################
# Deploy with ArgoCD GitOps
# Author: DevSecOps Team
# Description: Deploy services using ArgoCD for continuous GitOps delivery
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
LOG_FILE="${LOG_DIR}/deploy-with-argocd.log"
ENVIRONMENT="${1:-dev}"

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
║              Deploy with ArgoCD GitOps                           ║
║                                                                  ║
║  Continuous deployment using ArgoCD for GitOps workflows         ║
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

# Check if ArgoCD is installed
check_argocd() {
    log "Checking ArgoCD installation..."
    
    if ! kubectl get namespace argocd &> /dev/null; then
        log_error "ArgoCD namespace not found"
        log_info "Run: ./07-setup-gitops.sh ${ENVIRONMENT}"
        exit 1
    fi
    
    if ! kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server &> /dev/null; then
        log_error "ArgoCD server not found"
        log_info "Run: ./07-setup-gitops.sh ${ENVIRONMENT}"
        exit 1
    fi
    
    log "ArgoCD is installed and running"
}

# Sync ArgoCD applications
sync_applications() {
    log "Syncing ArgoCD applications..."
    
    local APPS=(
        "frontend-${ENVIRONMENT}"
        "auth-service-${ENVIRONMENT}"
        "user-service-${ENVIRONMENT}"
        "analytics-service-${ENVIRONMENT}"
        "notification-service-${ENVIRONMENT}"
    )
    
    for app in "${APPS[@]}"; do
        log_info "Syncing application: ${app}"
        
        if kubectl get application "${app}" -n argocd &> /dev/null; then
            kubectl patch application "${app}" -n argocd \
                --type merge \
                --patch '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
            
            argocd app sync "${app}" --prune
            argocd app wait "${app}" --health --timeout 600
            
            log "Application ${app} synced successfully"
        else
            log_error "Application ${app} not found in ArgoCD"
        fi
    done
}

# Create ArgoCD applications if they don't exist
create_applications() {
    log "Creating ArgoCD applications..."
    
    local GITHUB_USER="${GITHUB_USERNAME:-khaledhawil}"
    local GITHUB_REPO="${GITHUB_REPO:-devsecops-project}"
    
    # Frontend application
    cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend-${ENVIRONMENT}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/${GITHUB_USER}/${GITHUB_REPO}
    targetRevision: main
    path: 04-kubernetes/overlays/${ENVIRONMENT}/frontend
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ENVIRONMENT}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
    
    # Auth Service application
    cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: auth-service-${ENVIRONMENT}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/${GITHUB_USER}/${GITHUB_REPO}
    targetRevision: main
    path: 04-kubernetes/overlays/${ENVIRONMENT}/auth-service
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ENVIRONMENT}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
    
    # User Service application
    cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: user-service-${ENVIRONMENT}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/${GITHUB_USER}/${GITHUB_REPO}
    targetRevision: main
    path: 04-kubernetes/overlays/${ENVIRONMENT}/user-service
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ENVIRONMENT}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
    
    # Analytics Service application
    cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: analytics-service-${ENVIRONMENT}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/${GITHUB_USER}/${GITHUB_REPO}
    targetRevision: main
    path: 04-kubernetes/overlays/${ENVIRONMENT}/analytics-service
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ENVIRONMENT}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
    
    # Notification Service application
    cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: notification-service-${ENVIRONMENT}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/${GITHUB_USER}/${GITHUB_REPO}
    targetRevision: main
    path: 04-kubernetes/overlays/${ENVIRONMENT}/notification-service
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ENVIRONMENT}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
    
    log "ArgoCD applications created"
}

# Check deployment status
check_status() {
    log "Checking deployment status..."
    
    echo ""
    echo "ArgoCD Applications:"
    argocd app list
    
    echo ""
    echo "Application Health:"
    kubectl get applications -n argocd -o wide
    
    echo ""
    echo "Pods in ${ENVIRONMENT} namespace:"
    kubectl get pods -n "${ENVIRONMENT}"
}

# Display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "ArgoCD Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Environment: ${ENVIRONMENT}"
    echo ""
    echo "Access ArgoCD UI:"
    echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "  URL: https://localhost:8080"
    echo ""
    echo "Get admin password:"
    echo "  kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d"
    echo ""
    echo "Useful Commands:"
    echo "  List apps:    argocd app list"
    echo "  Get app:      argocd app get <app-name>"
    echo "  Sync app:     argocd app sync <app-name>"
    echo "  Watch app:    argocd app get <app-name> --refresh"
    echo "  Logs:         argocd app logs <app-name>"
    echo "=========================================="
}

# Main function
main() {
    print_banner
    log "Starting ArgoCD deployment for environment: ${ENVIRONMENT}"
    
    validate_environment
    check_argocd
    create_applications
    sync_applications
    check_status
    display_summary
    
    log "ArgoCD deployment completed successfully!"
}

# Run main
main "$@"
