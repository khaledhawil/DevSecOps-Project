#!/bin/bash

# Deploy complete DevSecOps platform to AWS

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../helpers/common-functions.sh"

# Get environment
ENV=$(get_environment "${1:-dev}")

print_header "DevSecOps Platform - AWS Full Stack Deployment"
print_info "Environment: $ENV"

# Confirm deployment
if [ "$ENV" = "prod" ]; then
    if ! confirm "You are about to deploy to PRODUCTION. This will create real AWS resources and incur costs. Continue?"; then
        print_info "Deployment cancelled"
        exit 0
    fi
fi

# Check prerequisites
print_info "Checking prerequisites..."
check_command "terraform" "Install from https://developer.hashicorp.com/terraform/downloads"
check_command "kubectl" "Install from https://kubernetes.io/docs/tasks/tools/"
check_command "helm" "Install from https://helm.sh/docs/intro/install/"
check_command "aws" "Install from https://aws.amazon.com/cli/"

# Check AWS credentials
if ! check_aws_credentials; then
    exit 1
fi

print_success "Prerequisites check passed"

# Load environment variables
ENV_FILE="$PROJECT_ROOT/.env.$ENV"
if [ -f "$ENV_FILE" ]; then
    load_env "$ENV_FILE"
else
    print_warning "Environment file not found: $ENV_FILE"
    print_info "Using default values"
fi

# Step 1: Deploy Infrastructure
print_header "Step 1/6: Deploying AWS Infrastructure"

cd "$PROJECT_ROOT/03-infrastructure/environments/$ENV"

print_info "Initializing Terraform..."
terraform init -upgrade

print_info "Planning infrastructure changes..."
terraform plan -out=tfplan

if ! confirm "Apply the above Terraform plan?"; then
    print_info "Deployment cancelled"
    exit 0
fi

print_info "Applying Terraform configuration (this may take 15-20 minutes)..."
terraform apply tfplan
rm -f tfplan

print_success "Infrastructure deployed"

# Get infrastructure outputs
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "devsecops-$ENV")
AWS_REGION=$(terraform output -raw region 2>/dev/null || aws configure get region)

print_info "EKS Cluster: $EKS_CLUSTER_NAME"
print_info "Region: $AWS_REGION"

# Step 2: Configure kubectl
print_header "Step 2/6: Configuring kubectl"

print_info "Updating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION"

if ! kubectl cluster-info &> /dev/null; then
    print_error "Failed to connect to Kubernetes cluster"
    exit 1
fi

print_success "kubectl configured"

# Step 3: Deploy Kubernetes Base Resources
print_header "Step 3/6: Deploying Kubernetes Resources"

cd "$PROJECT_ROOT"

print_info "Deploying base Kubernetes resources..."
kubectl apply -k "04-kubernetes/overlays/$ENV/"

print_info "Waiting for namespaces to be created..."
sleep 5

print_success "Kubernetes resources deployed"

# Step 4: Deploy Monitoring Stack
print_header "Step 4/6: Deploying Monitoring Stack"

if [ -f "$PROJECT_ROOT/06-monitoring/scripts/deploy-monitoring.sh" ]; then
    print_info "Deploying Prometheus, Grafana, and Fluent Bit..."
    bash "$PROJECT_ROOT/06-monitoring/scripts/deploy-monitoring.sh"
    print_success "Monitoring stack deployed"
else
    print_warning "Monitoring deployment script not found, skipping..."
fi

# Step 5: Deploy Security Stack
print_header "Step 5/6: Deploying Security Stack"

if [ -f "$PROJECT_ROOT/07-security/scripts/deploy-security.sh" ]; then
    print_info "Deploying Gatekeeper, Falco, Vault, Trivy, and SonarQube..."
    bash "$PROJECT_ROOT/07-security/scripts/deploy-security.sh"
    print_success "Security stack deployed"
else
    print_warning "Security deployment script not found, skipping..."
fi

# Step 6: Deploy Applications via ArgoCD
print_header "Step 6/6: Deploying Applications"

print_info "Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

print_info "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

print_info "Deploying ArgoCD applications..."
kubectl apply -f "$PROJECT_ROOT/05-cicd/argocd/applications/$ENV/"

print_success "Applications deployed"

# Display deployment summary
print_header "Deployment Complete! 🎉"

echo ""
print_info "=== Cluster Information ==="
echo ""
echo "  Cluster Name:    $EKS_CLUSTER_NAME"
echo "  Region:          $AWS_REGION"
echo "  Environment:     $ENV"
echo ""

print_info "=== Access ArgoCD ==="
echo ""
echo "  Port-forward ArgoCD:"
echo "    kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "  Get admin password:"
echo "    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "  ArgoCD URL: https://localhost:8080"
echo ""

print_info "=== Access Grafana ==="
echo ""
echo "  Port-forward Grafana:"
echo "    kubectl port-forward -n monitoring svc/grafana 3000:80"
echo ""
echo "  Grafana URL: http://localhost:3000"
echo "  Default credentials: admin/admin"
echo ""

print_info "=== View Logs ==="
echo ""
echo "  All pods:           kubectl get pods -A"
echo "  Service logs:       kubectl logs -f -n <namespace> -l app=<service-name>"
echo "  ArgoCD apps:        kubectl get applications -n argocd"
echo ""

print_info "=== Next Steps ==="
echo ""
echo "  1. Initialize Vault:"
echo "     ./07-security/scripts/vault-setup.sh"
echo ""
echo "  2. Configure secrets in AWS Secrets Manager or Vault"
echo ""
echo "  3. Run security scans:"
echo "     ./07-security/scripts/scan-all.sh"
echo ""
echo "  4. Monitor application health in ArgoCD and Grafana"
echo ""
echo "  5. Set up DNS records for ingress endpoints"
echo ""

print_success "Full stack deployment complete! ✨"

# Save deployment info
DEPLOYMENT_INFO_FILE="$PROJECT_ROOT/deployment-info-$ENV.txt"
cat > "$DEPLOYMENT_INFO_FILE" << EOF
Deployment Information
======================

Deployed: $(date)
Environment: $ENV
Cluster: $EKS_CLUSTER_NAME
Region: $AWS_REGION

ArgoCD:
  kubectl port-forward svc/argocd-server -n argocd 8080:443
  Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

Grafana:
  kubectl port-forward -n monitoring svc/grafana 3000:80
  Default: admin/admin

Vault:
  kubectl port-forward -n vault svc/vault 8200:8200
  Initialize: ./07-security/scripts/vault-setup.sh

Useful Commands:
  kubectl get pods -A
  kubectl get svc -A
  kubectl get ingress -A
  kubectl logs -f -n <namespace> <pod-name>

To destroy:
  ./aws/destroy-infrastructure.sh $ENV
EOF

print_info "Deployment information saved to: $DEPLOYMENT_INFO_FILE"
