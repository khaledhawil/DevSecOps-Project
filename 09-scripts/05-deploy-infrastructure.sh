#!/bin/bash

################################################################################
# DevSecOps Project - Deploy Infrastructure
################################################################################
#
# Purpose: Deploy AWS infrastructure using Terraform
#
# This script:
#   1. Initializes Terraform
#   2. Validates configuration
#   3. Plans infrastructure changes
#   4. Applies infrastructure
#   5. Outputs connection information
#
# Usage: ./05-deploy-infrastructure.sh <environment>
# Example: ./05-deploy-infrastructure.sh dev
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/03-infrastructure/terraform"
ENVIRONMENT="${1:-dev}"

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
║            DevSecOps - Infrastructure Deployment                     ║
║                                                                      ║
║                   Deploying to AWS with Terraform                    ║
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
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi
    
    local tf_version=$(terraform version -json | jq -r '.terraform_version')
    log_info "Terraform version: ${tf_version}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    local aws_account=$(aws sts get-caller-identity --query Account --output text)
    local aws_user=$(aws sts get-caller-identity --query Arn --output text)
    log_info "AWS Account: ${aws_account}"
    log_info "AWS User: ${aws_user}"
    
    log "✓ All prerequisites met"
}

confirm_deployment() {
    echo ""
    log_warn "You are about to deploy infrastructure to ${ENVIRONMENT}"
    
    if [[ "${ENVIRONMENT}" == "prod" ]]; then
        log_warn "⚠️  This is PRODUCTION! Changes may affect live services."
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

init_terraform() {
    log "Initializing Terraform..."
    
    cd "${TERRAFORM_DIR}"
    
    # Initialize with backend configuration
    terraform init \
        -backend-config="key=devsecops/${ENVIRONMENT}/terraform.tfstate" \
        -reconfigure
    
    log "✓ Terraform initialized"
}

select_workspace() {
    log "Selecting Terraform workspace: ${ENVIRONMENT}"
    
    cd "${TERRAFORM_DIR}"
    
    # Create workspace if it doesn't exist
    if ! terraform workspace select "${ENVIRONMENT}" 2>/dev/null; then
        terraform workspace new "${ENVIRONMENT}"
    fi
    
    local current_workspace=$(terraform workspace show)
    log_info "Current workspace: ${current_workspace}"
}

validate_terraform() {
    log "Validating Terraform configuration..."
    
    cd "${TERRAFORM_DIR}"
    
    terraform validate
    
    log "✓ Configuration is valid"
}

plan_infrastructure() {
    log "Planning infrastructure changes..."
    
    cd "${TERRAFORM_DIR}"
    
    # Create plan file
    terraform plan \
        -var="environment=${ENVIRONMENT}" \
        -out="tfplan-${ENVIRONMENT}.out"
    
    log "✓ Plan created"
    
    # Show plan summary
    log_info "Review the plan above carefully"
}

apply_infrastructure() {
    log "Applying infrastructure changes..."
    
    cd "${TERRAFORM_DIR}"
    
    # Apply the plan
    terraform apply "tfplan-${ENVIRONMENT}.out"
    
    # Remove plan file
    rm -f "tfplan-${ENVIRONMENT}.out"
    
    log "✓ Infrastructure deployed"
}

save_outputs() {
    log "Saving Terraform outputs..."
    
    cd "${TERRAFORM_DIR}"
    
    # Save outputs to file
    local output_file="${PROJECT_ROOT}/terraform-outputs-${ENVIRONMENT}.json"
    terraform output -json > "${output_file}"
    
    log_info "Outputs saved to: ${output_file}"
}

update_kubeconfig() {
    log "Updating kubeconfig for EKS cluster..."
    
    cd "${TERRAFORM_DIR}"
    
    local cluster_name=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "")
    local region=$(terraform output -raw region 2>/dev/null || echo "us-east-1")
    
    if [[ -n "${cluster_name}" ]]; then
        aws eks update-kubeconfig \
            --region "${region}" \
            --name "${cluster_name}"
        
        log "✓ Kubeconfig updated"
        log_info "Cluster: ${cluster_name}"
        
        # Test connection
        if kubectl cluster-info &> /dev/null; then
            log "✓ Successfully connected to cluster"
        else
            log_warn "Could not connect to cluster. It may still be initializing."
        fi
    else
        log_warn "EKS cluster name not found in outputs"
    fi
}

show_summary() {
    log "Infrastructure deployment complete!"
    
    cd "${TERRAFORM_DIR}"
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                  ${GREEN}Infrastructure Summary${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Display key outputs
    local vpc_id=$(terraform output -raw vpc_id 2>/dev/null || echo "N/A")
    local eks_cluster=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "N/A")
    local rds_endpoint=$(terraform output -raw rds_endpoint 2>/dev/null || echo "N/A")
    local redis_endpoint=$(terraform output -raw redis_endpoint 2>/dev/null || echo "N/A")
    
    echo -e "${CYAN}║${NC} Environment:      ${YELLOW}${ENVIRONMENT}${NC}                                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} VPC ID:           ${YELLOW}${vpc_id}${NC}                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} EKS Cluster:      ${YELLOW}${eks_cluster}${NC}        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} RDS Endpoint:     ${YELLOW}${rds_endpoint:0:40}${NC}... ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Redis Endpoint:   ${YELLOW}${redis_endpoint:0:40}${NC}... ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main execution
main() {
    print_banner
    
    log "Starting infrastructure deployment for: ${ENVIRONMENT}"
    
    validate_environment
    check_prerequisites
    confirm_deployment
    init_terraform
    select_workspace
    validate_terraform
    plan_infrastructure
    apply_infrastructure
    save_outputs
    update_kubeconfig
    show_summary
    
    log "✅ Infrastructure deployment completed successfully!"
    log ""
    log "Next steps:"
    log "  1. Deploy Kubernetes resources: ./06-deploy-kubernetes.sh ${ENVIRONMENT}"
    log "  2. Setup GitOps: ./07-setup-gitops.sh ${ENVIRONMENT}"
    log "  3. Check cluster: kubectl get nodes"
}

# Trap errors
trap 'log_error "Infrastructure deployment failed at line $LINENO"; exit 1' ERR

# Run main
main "$@"
