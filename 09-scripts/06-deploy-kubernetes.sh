#!/bin/bash

################################################################################
# DevSecOps Project - Deploy Kubernetes Resources
################################################################################
#
# Purpose: Deploy all Kubernetes resources using Kustomize
#
# This script:
#   1. Validates Kubernetes connection
#   2. Creates namespaces
#   3. Deploys base resources
#   4. Deploys environment-specific overlays
#   5. Waits for deployments to be ready
#
# Usage: ./06-deploy-kubernetes.sh <environment>
# Example: ./06-deploy-kubernetes.sh dev
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
K8S_DIR="${PROJECT_ROOT}/04-kubernetes"
ENVIRONMENT="${1:-dev}"
NAMESPACE="devsecops-${ENVIRONMENT}"

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
║            DevSecOps - Kubernetes Deployment                         ║
║                                                                      ║
║              Deploying applications to Kubernetes                    ║
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
        log_info "Run: ./05-deploy-infrastructure.sh ${ENVIRONMENT}"
        exit 1
    fi
    
    local context=$(kubectl config current-context)
    log_info "Current context: ${context}"
    
    # Check kustomize
    if ! command -v kustomize &> /dev/null; then
        log_warn "kustomize not found, using kubectl kustomize"
    fi
    
    log "✓ All prerequisites met"
}

confirm_deployment() {
    echo ""
    log_warn "You are about to deploy to Kubernetes environment: ${ENVIRONMENT}"
    log_info "Namespace: ${NAMESPACE}"
    
    if [[ "${ENVIRONMENT}" == "prod" ]]; then
        log_warn "⚠️  This is PRODUCTION!"
        read -p "Type 'yes' to continue: " confirm
        if [[ "${confirm}" != "yes" ]]; then
            log "Deployment cancelled"
            exit 0
        fi
    else
        read -p "Continue? (y/n): " confirm
        if [[ "${confirm}" != "y" ]]; then
            log "Deployment cancelled"
            exit 0
        fi
    fi
}

create_namespace() {
    log "Creating namespace: ${NAMESPACE}"
    
    if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
        log_info "Namespace already exists"
    else
        kubectl create namespace "${NAMESPACE}"
        log "✓ Namespace created"
    fi
    
    # Label namespace
    kubectl label namespace "${NAMESPACE}" \
        environment="${ENVIRONMENT}" \
        managed-by="devsecops" \
        --overwrite
}

create_secrets() {
    log "Creating secrets..."
    
    # Check if secrets exist in AWS Secrets Manager
    if command -v aws &> /dev/null; then
        log_info "Retrieving secrets from AWS Secrets Manager..."
        
        # RDS password
        local rds_password=$(aws secretsmanager get-secret-value \
            --secret-id "devsecops-${ENVIRONMENT}-rds-password" \
            --query SecretString --output text 2>/dev/null || echo "")
        
        if [[ -n "${rds_password}" ]]; then
            kubectl create secret generic rds-credentials \
                --from-literal=username=dbadmin \
                --from-literal=password="${rds_password}" \
                --namespace="${NAMESPACE}" \
                --dry-run=client -o yaml | kubectl apply -f -
            log "✓ RDS credentials created"
        else
            log_warn "RDS password not found in Secrets Manager"
        fi
        
        # Redis auth token
        local redis_token=$(aws secretsmanager get-secret-value \
            --secret-id "devsecops-${ENVIRONMENT}-redis-auth-token" \
            --query SecretString --output text 2>/dev/null || echo "")
        
        if [[ -n "${redis_token}" ]]; then
            kubectl create secret generic redis-credentials \
                --from-literal=auth-token="${redis_token}" \
                --namespace="${NAMESPACE}" \
                --dry-run=client -o yaml | kubectl apply -f -
            log "✓ Redis credentials created"
        else
            log_warn "Redis token not found in Secrets Manager"
        fi
    else
        log_warn "AWS CLI not available, skipping secret creation from Secrets Manager"
    fi
}

preview_deployment() {
    log "Previewing deployment..."
    
    cd "${K8S_DIR}/overlays/${ENVIRONMENT}"
    
    log_info "Resources to be deployed:"
    kubectl kustomize . | kubectl apply --dry-run=client -f - | head -20
    
    echo ""
    read -p "Proceed with deployment? (y/n): " proceed
    if [[ "${proceed}" != "y" ]]; then
        log "Deployment cancelled"
        exit 0
    fi
}

deploy_resources() {
    log "Deploying Kubernetes resources..."
    
    cd "${K8S_DIR}/overlays/${ENVIRONMENT}"
    
    # Apply kustomization
    kubectl apply -k .
    
    log "✓ Resources deployed"
}

wait_for_deployments() {
    log "Waiting for deployments to be ready..."
    
    local deployments=(
        "user-service"
        "auth-service"
        "notification-service"
        "analytics-service"
        "frontend"
    )
    
    for deployment in "${deployments[@]}"; do
        log_info "Waiting for ${deployment}..."
        
        if kubectl wait --for=condition=available --timeout=300s \
            deployment/${deployment} -n "${NAMESPACE}" 2>/dev/null; then
            log "  ✓ ${deployment} is ready"
        else
            log_warn "  ! ${deployment} is not ready yet"
        fi
    done
}

check_pod_status() {
    log "Checking pod status..."
    
    echo ""
    kubectl get pods -n "${NAMESPACE}"
    echo ""
    
    # Check for failed pods
    local failed_pods=$(kubectl get pods -n "${NAMESPACE}" \
        --field-selector=status.phase!=Running,status.phase!=Succeeded \
        -o jsonpath='{.items[*].metadata.name}' || echo "")
    
    if [[ -n "${failed_pods}" ]]; then
        log_warn "Some pods are not running:"
        for pod in ${failed_pods}; do
            log_error "  ✗ ${pod}"
            kubectl describe pod "${pod}" -n "${NAMESPACE}" | tail -20
        done
    fi
}

check_services() {
    log "Checking services..."
    
    echo ""
    kubectl get svc -n "${NAMESPACE}"
    echo ""
}

check_ingress() {
    log "Checking ingress..."
    
    if kubectl get ingress -n "${NAMESPACE}" &> /dev/null; then
        echo ""
        kubectl get ingress -n "${NAMESPACE}"
        echo ""
    else
        log_info "No ingress resources found"
    fi
}

show_access_info() {
    log_info "Access information:"
    
    echo ""
    echo "Port forwarding examples:"
    echo "  kubectl port-forward -n ${NAMESPACE} svc/frontend 3000:80"
    echo "  kubectl port-forward -n ${NAMESPACE} svc/user-service 8081:8080"
    echo "  kubectl port-forward -n ${NAMESPACE} svc/auth-service 8082:8080"
    echo ""
    
    echo "View logs:"
    echo "  kubectl logs -f -n ${NAMESPACE} deployment/user-service"
    echo "  kubectl logs -f -n ${NAMESPACE} deployment/auth-service"
    echo ""
    
    echo "Scale deployments:"
    echo "  kubectl scale deployment/user-service -n ${NAMESPACE} --replicas=3"
    echo ""
}

show_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                   ${GREEN}Deployment Summary${NC}                               ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    
    local pod_count=$(kubectl get pods -n "${NAMESPACE}" --no-headers | wc -l)
    local running_count=$(kubectl get pods -n "${NAMESPACE}" --field-selector=status.phase=Running --no-headers | wc -l || echo 0)
    
    echo -e "${CYAN}║${NC} Environment:      ${YELLOW}${ENVIRONMENT}${NC}                                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Namespace:        ${YELLOW}${NAMESPACE}${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Total Pods:       ${YELLOW}${pod_count}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Running Pods:     ${GREEN}${running_count}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main execution
main() {
    print_banner
    
    log "Starting Kubernetes deployment for: ${ENVIRONMENT}"
    
    validate_environment
    check_prerequisites
    confirm_deployment
    create_namespace
    create_secrets
    preview_deployment
    deploy_resources
    wait_for_deployments
    check_pod_status
    check_services
    check_ingress
    show_access_info
    show_summary
    
    log "✅ Kubernetes deployment completed successfully!"
    log ""
    log "Next steps:"
    log "  1. Setup GitOps: ./07-setup-gitops.sh ${ENVIRONMENT}"
    log "  2. Check health: ./health-check.sh"
    log "  3. View logs: kubectl logs -f -n ${NAMESPACE} -l app=user-service"
}

# Trap errors
trap 'log_error "Kubernetes deployment failed at line $LINENO"; exit 1' ERR

# Run main
main "$@"
