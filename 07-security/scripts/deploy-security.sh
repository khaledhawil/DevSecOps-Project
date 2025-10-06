#!/bin/bash

# Security Stack Deployment Script
# Deploy all security components for the DevSecOps platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Deploy Gatekeeper
deploy_gatekeeper() {
    print_info "Deploying Gatekeeper..."
    
    kubectl apply -f 07-security/gatekeeper/install.yaml
    
    print_info "Waiting for Gatekeeper to be ready..."
    kubectl wait --for=condition=Ready pod \
        -l control-plane=controller-manager \
        -n gatekeeper-system \
        --timeout=300s
    
    print_info "Applying constraint templates..."
    kubectl apply -f 07-security/gatekeeper/constraint-templates/
    
    sleep 10
    
    print_info "Applying constraints..."
    kubectl apply -f 07-security/gatekeeper/constraints/
    
    print_success "Gatekeeper deployed successfully"
}

# Deploy Falco
deploy_falco() {
    print_info "Deploying Falco..."
    
    kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl apply -f 07-security/falco/rules/
    kubectl apply -f 07-security/falco/daemonset.yaml
    kubectl apply -f 07-security/falco/falcosidekick/
    
    print_info "Waiting for Falco to be ready..."
    kubectl wait --for=condition=Ready pod \
        -l app=falco \
        -n falco \
        --timeout=300s
    
    print_success "Falco deployed successfully"
}

# Deploy Vault
deploy_vault() {
    print_info "Deploying Vault..."
    
    kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl apply -f 07-security/vault/deployment.yaml
    
    print_info "Waiting for Vault to be ready..."
    kubectl wait --for=condition=Ready pod \
        -l app=vault \
        -n vault \
        --timeout=300s
    
    print_warning "Vault requires initialization. Run:"
    print_warning "  kubectl exec -n vault vault-0 -- vault operator init"
    print_warning "Save the unseal keys and root token securely!"
    
    print_success "Vault deployed successfully"
}

# Deploy Trivy Operator
deploy_trivy() {
    print_info "Deploying Trivy Operator..."
    
    kubectl create namespace trivy-system --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl apply -f 07-security/trivy/operator.yaml
    kubectl apply -f 07-security/trivy/policies/
    
    print_info "Waiting for Trivy Operator to be ready..."
    kubectl wait --for=condition=Ready pod \
        -l app=trivy-operator \
        -n trivy-system \
        --timeout=300s
    
    print_success "Trivy Operator deployed successfully"
}

# Deploy SonarQube
deploy_sonarqube() {
    print_info "Deploying SonarQube..."
    
    kubectl create namespace sonarqube --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl apply -f 07-security/sonarqube/deployment.yaml
    
    print_info "Waiting for PostgreSQL to be ready..."
    kubectl wait --for=condition=Ready pod \
        -l app=postgresql \
        -n sonarqube \
        --timeout=300s
    
    print_info "Waiting for SonarQube to be ready (this may take a few minutes)..."
    kubectl wait --for=condition=Ready pod \
        -l app=sonarqube \
        -n sonarqube \
        --timeout=600s
    
    print_success "SonarQube deployed successfully"
    print_warning "Default credentials: admin/admin (change immediately)"
}

# Verify deployment
verify_deployment() {
    print_info "Verifying security stack deployment..."
    
    echo ""
    print_info "Gatekeeper status:"
    kubectl get pods -n gatekeeper-system
    
    echo ""
    print_info "Falco status:"
    kubectl get pods -n falco
    
    echo ""
    print_info "Vault status:"
    kubectl get pods -n vault
    
    echo ""
    print_info "Trivy Operator status:"
    kubectl get pods -n trivy-system
    
    echo ""
    print_info "SonarQube status:"
    kubectl get pods -n sonarqube
    
    echo ""
    print_info "Constraint Templates:"
    kubectl get constrainttemplates
    
    echo ""
    print_info "Constraints:"
    kubectl get constraints
    
    print_success "Verification complete"
}

# Print access information
print_access_info() {
    echo ""
    print_info "=== Security Stack Access Information ==="
    echo ""
    
    print_info "SonarQube:"
    echo "  kubectl port-forward -n sonarqube svc/sonarqube 9000:9000"
    echo "  Open: http://localhost:9000"
    echo "  Default credentials: admin/admin"
    echo ""
    
    print_info "Vault:"
    echo "  kubectl port-forward -n vault svc/vault 8200:8200"
    echo "  Open: http://localhost:8200"
    echo "  Requires initialization and unsealing"
    echo ""
    
    print_info "Falco Logs:"
    echo "  kubectl logs -n falco -l app=falco --tail=50 -f"
    echo ""
    
    print_info "Gatekeeper Audit:"
    echo "  kubectl get constraints"
    echo "  kubectl describe constraint <constraint-name>"
    echo ""
    
    print_info "Trivy Reports:"
    echo "  kubectl get vulnerabilityreports -A"
    echo "  kubectl get configauditreports -A"
    echo ""
}

# Main deployment
main() {
    echo ""
    print_info "========================================="
    print_info "Security Stack Deployment"
    print_info "========================================="
    echo ""
    
    check_prerequisites
    
    # Deploy components
    deploy_gatekeeper
    echo ""
    
    deploy_falco
    echo ""
    
    deploy_vault
    echo ""
    
    deploy_trivy
    echo ""
    
    deploy_sonarqube
    echo ""
    
    # Verify
    verify_deployment
    
    # Print access info
    print_access_info
    
    echo ""
    print_success "========================================="
    print_success "Security stack deployment complete! 🔒"
    print_success "========================================="
    echo ""
}

# Run main function
main
