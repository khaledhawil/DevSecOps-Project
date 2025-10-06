#!/bin/bash

# Deploy AWS Infrastructure using Terraform

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../helpers/common-functions.sh"

# Get environment
ENV=$(get_environment "${1:-dev}")

print_header "Deploying AWS Infrastructure"
print_info "Environment: $ENV"

# Check prerequisites
print_info "Checking prerequisites..."
check_command "terraform" "Install from https://developer.hashicorp.com/terraform/downloads"
check_command "aws" "Install from https://aws.amazon.com/cli/"

# Check AWS credentials
if ! check_aws_credentials; then
    exit 1
fi

# Navigate to infrastructure directory
INFRA_DIR="$PROJECT_ROOT/03-infrastructure/environments/$ENV"

if [ ! -d "$INFRA_DIR" ]; then
    print_error "Infrastructure directory not found: $INFRA_DIR"
    exit 1
fi

cd "$INFRA_DIR"

# Initialize Terraform
print_info "Initializing Terraform..."
terraform init -upgrade

# Validate configuration
print_info "Validating Terraform configuration..."
terraform validate

if [ $? -ne 0 ]; then
    print_error "Terraform validation failed"
    exit 1
fi

# Plan infrastructure changes
print_info "Planning infrastructure changes..."
terraform plan -out=tfplan

# Confirm deployment
echo ""
if ! confirm "Apply the above Terraform plan to create AWS resources?"; then
    print_info "Deployment cancelled"
    rm -f tfplan
    exit 0
fi

# Apply Terraform
print_info "Applying Terraform configuration..."
print_warning "This will take approximately 15-20 minutes..."

terraform apply tfplan
rm -f tfplan

print_success "Infrastructure deployment complete!"

# Display outputs
echo ""
print_info "=== Infrastructure Outputs ==="
echo ""
terraform output

# Save outputs to file
OUTPUT_FILE="$PROJECT_ROOT/infrastructure-outputs-$ENV.json"
terraform output -json > "$OUTPUT_FILE"
print_info "Outputs saved to: $OUTPUT_FILE"

echo ""
print_info "=== Next Steps ==="
echo ""
echo "  1. Configure kubectl:"
echo "     ./aws/update-kubeconfig.sh $ENV"
echo ""
echo "  2. Deploy Kubernetes resources:"
echo "     ./aws/deploy-kubernetes.sh $ENV"
echo ""
echo "  3. Or deploy full stack:"
echo "     ./aws/deploy-full-stack.sh $ENV"
echo ""

print_success "AWS Infrastructure is ready! ✨"
