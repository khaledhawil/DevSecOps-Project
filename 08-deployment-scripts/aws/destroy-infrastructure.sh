#!/bin/bash

# Destroy AWS Infrastructure

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../helpers/common-functions.sh"

# Get environment
ENV=$(get_environment "${1:-dev}")

print_header "Destroying AWS Infrastructure"
print_info "Environment: $ENV"

# Strong warning for production
if [ "$ENV" = "prod" ]; then
    echo ""
    print_error "⚠️  WARNING: YOU ARE ABOUT TO DESTROY PRODUCTION INFRASTRUCTURE ⚠️"
    echo ""
    print_warning "This action will:"
    echo "  - Delete all production data"
    echo "  - Remove all production resources"
    echo "  - Terminate all production services"
    echo "  - THIS CANNOT BE UNDONE"
    echo ""
    
    if ! confirm "Type 'DESTROY PRODUCTION' to confirm"; then
        print_info "Destruction cancelled"
        exit 0
    fi
    
    read -p "Enter the environment name to confirm (must type 'prod'): " confirmation
    if [ "$confirmation" != "prod" ]; then
        print_error "Confirmation failed. Destruction cancelled."
        exit 1
    fi
else
    echo ""
    print_warning "This will destroy all AWS resources in the $ENV environment"
    print_warning "All data will be permanently lost"
    echo ""
    
    if ! confirm "Destroy infrastructure in $ENV environment?"; then
        print_info "Destruction cancelled"
        exit 0
    fi
fi

# Check prerequisites
check_command "terraform" "Install from https://developer.hashicorp.com/terraform/downloads"
check_command "kubectl" "Install from https://kubernetes.io/docs/tasks/tools/"
check_command "aws" "Install from https://aws.amazon.com/cli/"

# Check AWS credentials
if ! check_aws_credentials; then
    exit 1
fi

# Get cluster information
INFRA_DIR="$PROJECT_ROOT/03-infrastructure/environments/$ENV"

if [ -d "$INFRA_DIR" ]; then
    cd "$INFRA_DIR"
    
    EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "devsecops-$ENV")
    AWS_REGION=$(terraform output -raw region 2>/dev/null || aws configure get region)
else
    print_error "Infrastructure directory not found: $INFRA_DIR"
    exit 1
fi

print_info "Cluster: $EKS_CLUSTER_NAME"
print_info "Region: $AWS_REGION"

# Step 1: Delete Kubernetes resources
print_header "Step 1/3: Cleaning up Kubernetes resources"

# Update kubeconfig
print_info "Updating kubeconfig..."
aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION" 2>/dev/null || true

if kubectl cluster-info &> /dev/null; then
    print_info "Deleting all LoadBalancer services..."
    kubectl get svc --all-namespaces -o json | \
        jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace) \(.metadata.name)"' | \
        while read namespace name; do
            print_info "Deleting LoadBalancer: $name in $namespace"
            kubectl delete svc "$name" -n "$namespace" --wait=false 2>/dev/null || true
        done
    
    print_info "Deleting persistent volume claims..."
    kubectl delete pvc --all --all-namespaces --wait=false 2>/dev/null || true
    
    print_info "Waiting for resources to be cleaned up (30 seconds)..."
    sleep 30
    
    print_success "Kubernetes resources deleted"
else
    print_warning "Could not connect to cluster, skipping Kubernetes cleanup"
fi

# Step 2: Delete EKS managed node groups
print_header "Step 2/3: Deleting EKS node groups"

print_info "Listing node groups..."
NODE_GROUPS=$(aws eks list-nodegroups --cluster-name "$EKS_CLUSTER_NAME" --region "$AWS_REGION" --query 'nodegroups[]' --output text 2>/dev/null || echo "")

if [ -n "$NODE_GROUPS" ]; then
    for ng in $NODE_GROUPS; do
        print_info "Deleting node group: $ng"
        aws eks delete-nodegroup --cluster-name "$EKS_CLUSTER_NAME" --nodegroup-name "$ng" --region "$AWS_REGION" --no-cli-pager 2>/dev/null || true
    done
    
    print_info "Waiting for node groups to be deleted (this may take 5-10 minutes)..."
    for ng in $NODE_GROUPS; do
        aws eks wait nodegroup-deleted --cluster-name "$EKS_CLUSTER_NAME" --nodegroup-name "$ng" --region "$AWS_REGION" 2>/dev/null || true
    done
    
    print_success "Node groups deleted"
else
    print_info "No node groups found"
fi

# Step 3: Destroy infrastructure with Terraform
print_header "Step 3/3: Destroying infrastructure with Terraform"

cd "$INFRA_DIR"

print_info "Planning destruction..."
terraform plan -destroy -out=destroy-plan

print_warning "About to destroy all resources shown above"
if ! confirm "Proceed with infrastructure destruction?"; then
    print_info "Destruction cancelled"
    rm -f destroy-plan
    exit 0
fi

print_info "Destroying infrastructure (this may take 10-15 minutes)..."
terraform apply destroy-plan
rm -f destroy-plan

print_success "Infrastructure destroyed"

# Cleanup outputs file
OUTPUT_FILE="$PROJECT_ROOT/infrastructure-outputs-$ENV.json"
if [ -f "$OUTPUT_FILE" ]; then
    rm -f "$OUTPUT_FILE"
    print_info "Removed outputs file"
fi

DEPLOYMENT_INFO_FILE="$PROJECT_ROOT/deployment-info-$ENV.txt"
if [ -f "$DEPLOYMENT_INFO_FILE" ]; then
    rm -f "$DEPLOYMENT_INFO_FILE"
    print_info "Removed deployment info file"
fi

# Final summary
print_header "Destruction Complete"

echo ""
print_success "All AWS resources in $ENV environment have been destroyed"
echo ""
print_info "What was destroyed:"
echo "  • EKS Cluster and node groups"
echo "  • RDS database instances"
echo "  • ElastiCache clusters"
echo "  • VPC and networking resources"
echo "  • IAM roles and policies"
echo "  • Security groups"
echo "  • Load balancers"
echo "  • All associated resources"
echo ""
print_warning "Some resources may take a few minutes to fully terminate"
print_info "Check AWS Console to verify all resources are deleted"
echo ""
