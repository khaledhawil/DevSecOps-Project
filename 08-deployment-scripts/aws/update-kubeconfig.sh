#!/bin/bash

# Update kubectl configuration for EKS cluster

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../helpers/common-functions.sh"

# Get environment
ENV=$(get_environment "${1:-dev}")

print_header "Updating kubectl Configuration"
print_info "Environment: $ENV"

# Check prerequisites
check_command "kubectl" "Install from https://kubernetes.io/docs/tasks/tools/"
check_command "aws" "Install from https://aws.amazon.com/cli/"

# Check AWS credentials
if ! check_aws_credentials; then
    exit 1
fi

# Get cluster name and region from Terraform outputs
INFRA_DIR="$PROJECT_ROOT/03-infrastructure/environments/$ENV"

if [ -d "$INFRA_DIR" ]; then
    cd "$INFRA_DIR"
    
    EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "")
    AWS_REGION=$(terraform output -raw region 2>/dev/null || echo "")
fi

# Fallback to defaults if not found
if [ -z "$EKS_CLUSTER_NAME" ]; then
    EKS_CLUSTER_NAME="devsecops-$ENV"
    print_warning "Could not get cluster name from Terraform, using default: $EKS_CLUSTER_NAME"
fi

if [ -z "$AWS_REGION" ]; then
    AWS_REGION=$(aws configure get region)
    print_warning "Could not get region from Terraform, using AWS CLI default: $AWS_REGION"
fi

print_info "Cluster Name: $EKS_CLUSTER_NAME"
print_info "Region: $AWS_REGION"

# Update kubeconfig
print_info "Updating kubeconfig..."
aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION"

# Test connection
print_info "Testing connection to cluster..."
if kubectl cluster-info &> /dev/null; then
    print_success "Successfully connected to cluster"
    
    echo ""
    kubectl cluster-info
    
    echo ""
    print_info "Cluster nodes:"
    kubectl get nodes
    
    echo ""
    print_info "Current context:"
    kubectl config current-context
    
    print_success "kubectl configuration updated successfully! ✨"
else
    print_error "Failed to connect to cluster"
    exit 1
fi
