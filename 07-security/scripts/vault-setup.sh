#!/bin/bash

# Vault Setup Script
# Initialize and configure Vault for the DevSecOps platform

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

# Check if Vault is running
check_vault() {
    print_info "Checking Vault status..."
    
    if ! kubectl get pods -n vault -l app=vault | grep -q Running; then
        print_error "Vault is not running. Deploy Vault first."
        exit 1
    fi
    
    print_success "Vault is running"
}

# Initialize Vault
init_vault() {
    print_info "Initializing Vault..."
    
    # Check if already initialized
    if kubectl exec -n vault vault-0 -- vault status 2>&1 | grep -q "Initialized.*true"; then
        print_warning "Vault is already initialized"
        return 0
    fi
    
    print_info "Running vault operator init..."
    INIT_OUTPUT=$(kubectl exec -n vault vault-0 -- vault operator init -key-shares=5 -key-threshold=3)
    
    # Save output to file
    echo "$INIT_OUTPUT" > vault-init-keys.txt
    
    print_success "Vault initialized successfully"
    print_warning "Unseal keys and root token saved to: vault-init-keys.txt"
    print_warning "STORE THIS FILE SECURELY AND DELETE IT AFTER BACKING UP!"
    
    # Extract keys
    UNSEAL_KEY_1=$(echo "$INIT_OUTPUT" | grep "Unseal Key 1:" | awk '{print $NF}')
    UNSEAL_KEY_2=$(echo "$INIT_OUTPUT" | grep "Unseal Key 2:" | awk '{print $NF}')
    UNSEAL_KEY_3=$(echo "$INIT_OUTPUT" | grep "Unseal Key 3:" | awk '{print $NF}')
    ROOT_TOKEN=$(echo "$INIT_OUTPUT" | grep "Initial Root Token:" | awk '{print $NF}')
    
    export VAULT_TOKEN=$ROOT_TOKEN
}

# Unseal Vault
unseal_vault() {
    print_info "Unsealing Vault..."
    
    # Check if sealed
    if ! kubectl exec -n vault vault-0 -- vault status 2>&1 | grep -q "Sealed.*true"; then
        print_warning "Vault is already unsealed"
        return 0
    fi
    
    # Read keys from file if they exist
    if [ -f "vault-init-keys.txt" ]; then
        UNSEAL_KEY_1=$(grep "Unseal Key 1:" vault-init-keys.txt | awk '{print $NF}')
        UNSEAL_KEY_2=$(grep "Unseal Key 2:" vault-init-keys.txt | awk '{print $NF}')
        UNSEAL_KEY_3=$(grep "Unseal Key 3:" vault-init-keys.txt | awk '{print $NF}')
    else
        print_error "vault-init-keys.txt not found. Cannot unseal Vault."
        print_info "Manually unseal with: kubectl exec -n vault vault-0 -- vault operator unseal <key>"
        exit 1
    fi
    
    kubectl exec -n vault vault-0 -- vault operator unseal "$UNSEAL_KEY_1"
    kubectl exec -n vault vault-0 -- vault operator unseal "$UNSEAL_KEY_2"
    kubectl exec -n vault vault-0 -- vault operator unseal "$UNSEAL_KEY_3"
    
    print_success "Vault unsealed successfully"
}

# Configure Vault
configure_vault() {
    print_info "Configuring Vault..."
    
    # Get root token
    if [ -f "vault-init-keys.txt" ]; then
        ROOT_TOKEN=$(grep "Initial Root Token:" vault-init-keys.txt | awk '{print $NF}')
    else
        print_error "Root token not found. Cannot configure Vault."
        exit 1
    fi
    
    # Enable secrets engine
    print_info "Enabling KV secrets engine..."
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault secrets enable -version=2 -path=secret kv || true
    
    # Enable Kubernetes auth
    print_info "Enabling Kubernetes auth..."
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault auth enable kubernetes || true
    
    # Configure Kubernetes auth
    print_info "Configuring Kubernetes auth..."
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault write auth/kubernetes/config \
        kubernetes_host="https://\$KUBERNETES_PORT_443_TCP_ADDR:443" || true
    
    # Create policies
    print_info "Creating Vault policies..."
    
    # Copy policies to Vault pod
    kubectl cp 07-security/vault/policies/app-policy.hcl vault/vault-0:/tmp/app-policy.hcl
    kubectl cp 07-security/vault/policies/admin-policy.hcl vault/vault-0:/tmp/admin-policy.hcl
    
    # Apply policies
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault policy write app /tmp/app-policy.hcl
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault policy write admin /tmp/admin-policy.hcl
    
    print_success "Vault configured successfully"
}

# Create sample secrets
create_sample_secrets() {
    print_info "Creating sample secrets..."
    
    if [ -f "vault-init-keys.txt" ]; then
        ROOT_TOKEN=$(grep "Initial Root Token:" vault-init-keys.txt | awk '{print $NF}')
    else
        print_error "Root token not found."
        exit 1
    fi
    
    # Database credentials
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault kv put secret/database/postgres \
        username=devsecops_user \
        password=change_me_in_production \
        connection_string="postgresql://devsecops_user:change_me_in_production@postgres:5432/devsecops"
    
    # JWT secrets
    JWT_ACCESS_SECRET=$(openssl rand -base64 32)
    JWT_REFRESH_SECRET=$(openssl rand -base64 32)
    
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault kv put secret/jwt/tokens \
        access_token_secret="$JWT_ACCESS_SECRET" \
        refresh_token_secret="$JWT_REFRESH_SECRET"
    
    # Redis credentials
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault kv put secret/redis/credentials \
        password=change_me_in_production \
        connection_string="redis://redis:6379"
    
    print_success "Sample secrets created"
}

# Create Kubernetes roles
create_k8s_roles() {
    print_info "Creating Kubernetes auth roles..."
    
    if [ -f "vault-init-keys.txt" ]; then
        ROOT_TOKEN=$(grep "Initial Root Token:" vault-init-keys.txt | awk '{print $NF}')
    else
        print_error "Root token not found."
        exit 1
    fi
    
    # Create role for user-service
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault write auth/kubernetes/role/user-service \
        bound_service_account_names=user-service \
        bound_service_account_namespaces=user-service \
        policies=app \
        ttl=24h
    
    # Create role for auth-service
    kubectl exec -n vault vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault write auth/kubernetes/role/auth-service \
        bound_service_account_names=auth-service \
        bound_service_account_namespaces=auth-service \
        policies=app \
        ttl=24h
    
    print_success "Kubernetes roles created"
}

# Main function
main() {
    echo ""
    print_info "========================================="
    print_info "Vault Setup"
    print_info "========================================="
    echo ""
    
    check_vault
    init_vault
    unseal_vault
    configure_vault
    create_sample_secrets
    create_k8s_roles
    
    echo ""
    print_success "========================================="
    print_success "Vault setup complete! 🔐"
    print_success "========================================="
    echo ""
    
    print_warning "IMPORTANT: Backup vault-init-keys.txt and store it securely!"
    print_warning "Delete this file after backing up."
    echo ""
    
    print_info "Access Vault UI:"
    echo "  kubectl port-forward -n vault svc/vault 8200:8200"
    echo "  Open: http://localhost:8200"
    echo "  Token: (from vault-init-keys.txt)"
    echo ""
}

# Run main function
main
