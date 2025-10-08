#!/bin/bash

# Script to configure Kubernetes services to use RDS and ElastiCache
# This script fetches Terraform outputs and updates Kubernetes ConfigMaps

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="../../03-infrastructure/terraform"
K8S_BASE_DIR="../base"
ENVIRONMENT="${1:-dev}"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}║  Configure Apps to Use RDS and ElastiCache               ║${NC}"
echo -e "${BLUE}║                                                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if Terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    print_error "Terraform directory not found: $TERRAFORM_DIR"
    exit 1
fi

# Navigate to Terraform directory
cd "$TERRAFORM_DIR"

echo -e "${YELLOW}Step 1: Fetching Terraform Outputs...${NC}"
echo ""

# Check if Terraform state exists
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    print_error "Terraform state not found. Please run 'terraform apply' first."
    exit 1
fi

# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "")
RDS_PORT=$(terraform output -raw rds_port 2>/dev/null || echo "5432")
RDS_DATABASE=$(terraform output -raw rds_database_name 2>/dev/null || echo "devsecops_${ENVIRONMENT}")
RDS_USERNAME=$(terraform output -raw rds_username 2>/dev/null || echo "")

# Get ElastiCache endpoint
REDIS_ENDPOINT=$(terraform output -raw redis_primary_endpoint 2>/dev/null || echo "")
REDIS_PORT=$(terraform output -raw redis_port 2>/dev/null || echo "6379")

# Get AWS region
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

# Get secrets from AWS Secrets Manager
RDS_PASSWORD_SECRET_ARN=$(terraform output -raw rds_password_secret_arn 2>/dev/null || echo "")

if [ -z "$RDS_ENDPOINT" ] || [ -z "$REDIS_ENDPOINT" ]; then
    print_error "Could not retrieve RDS or ElastiCache endpoints from Terraform"
    echo ""
    echo "Please ensure:"
    echo "  1. Infrastructure is deployed: cd $TERRAFORM_DIR && terraform apply"
    echo "  2. Terraform state is accessible"
    exit 1
fi

print_status "RDS Endpoint: $RDS_ENDPOINT"
print_status "RDS Port: $RDS_PORT"
print_status "RDS Database: $RDS_DATABASE"
print_status "Redis Endpoint: $REDIS_ENDPOINT"
print_status "Redis Port: $REDIS_PORT"
echo ""

echo -e "${YELLOW}Step 2: Retrieving Secrets from AWS Secrets Manager...${NC}"
echo ""

# Get RDS password from Secrets Manager
if [ -n "$RDS_PASSWORD_SECRET_ARN" ]; then
    RDS_PASSWORD=$(aws secretsmanager get-secret-value \
        --secret-id "$RDS_PASSWORD_SECRET_ARN" \
        --region "$AWS_REGION" \
        --query 'SecretString' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$RDS_PASSWORD" ]; then
        print_status "Retrieved RDS password from Secrets Manager"
    else
        print_warning "Could not retrieve RDS password from Secrets Manager"
        read -sp "Enter RDS password manually: " RDS_PASSWORD
        echo ""
    fi
else
    print_warning "RDS password secret ARN not found"
    read -sp "Enter RDS password: " RDS_PASSWORD
    echo ""
fi

# Note: ElastiCache without auth_token doesn't need password
# If you enabled auth_token, retrieve it here
REDIS_AUTH_TOKEN=""
print_warning "ElastiCache auth_token not configured (optional)"
echo ""

echo -e "${YELLOW}Step 3: Updating Kubernetes ConfigMaps and Secrets...${NC}"
echo ""

# Navigate back to script directory
cd - > /dev/null

# Function to update ConfigMap
update_configmap() {
    local SERVICE=$1
    local CONFIG_FILE="${K8S_BASE_DIR}/${SERVICE}"
    
    if [ -f "${CONFIG_FILE}/configmap.yaml" ]; then
        print_status "Updating ${SERVICE} ConfigMap..."
        
        # Update ConfigMap file
        sed -i "s|db-host:.*|db-host: \"${RDS_ENDPOINT}\"|g" "${CONFIG_FILE}/configmap.yaml"
        sed -i "s|db-port:.*|db-port: \"${RDS_PORT}\"|g" "${CONFIG_FILE}/configmap.yaml"
        sed -i "s|db-name:.*|db-name: \"${RDS_DATABASE}\"|g" "${CONFIG_FILE}/configmap.yaml"
        sed -i "s|redis-host:.*|redis-host: \"${REDIS_ENDPOINT}\"|g" "${CONFIG_FILE}/configmap.yaml"
        sed -i "s|redis-port:.*|redis-port: \"${REDIS_PORT}\"|g" "${CONFIG_FILE}/configmap.yaml"
    fi
    
    if [ -f "${CONFIG_FILE}/manifests.yaml" ]; then
        print_status "Updating ${SERVICE} manifests..."
        
        # Update manifests file (for services with combined manifests)
        sed -i "s|db-host:.*|db-host: \"${RDS_ENDPOINT}\"|g" "${CONFIG_FILE}/manifests.yaml"
        sed -i "s|db-port:.*|db-port: \"${RDS_PORT}\"|g" "${CONFIG_FILE}/manifests.yaml"
        sed -i "s|db-name:.*|db-name: \"${RDS_DATABASE}\"|g" "${CONFIG_FILE}/manifests.yaml"
        sed -i "s|redis-host:.*|redis-host: \"${REDIS_ENDPOINT}\"|g" "${CONFIG_FILE}/manifests.yaml"
        sed -i "s|redis-port:.*|redis-port: \"${REDIS_PORT}\"|g" "${CONFIG_FILE}/manifests.yaml"
    fi
}

# Update all services
update_configmap "user-service"
update_configmap "auth-service"
update_configmap "notification-service"
update_configmap "analytics-service"

echo ""
echo -e "${YELLOW}Step 4: Creating/Updating Shared Secrets...${NC}"
echo ""

# Create/Update shared secrets file
cat > "${K8S_BASE_DIR}/shared-secrets.yaml" << EOF
# Shared Secrets Configuration
# Auto-generated by configure-rds-redis.sh

apiVersion: v1
kind: Secret
metadata:
  name: rds-credentials
  namespace: devsecops
type: Opaque
stringData:
  username: ${RDS_USERNAME}
  password: ${RDS_PASSWORD}

---
apiVersion: v1
kind: Secret
metadata:
  name: redis-credentials
  namespace: devsecops
type: Opaque
stringData:
  auth-token: "${REDIS_AUTH_TOKEN}"

EOF

print_status "Created shared secrets configuration"
echo ""

echo -e "${YELLOW}Step 5: Creating Kubernetes Secret from AWS Secrets Manager...${NC}"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &>/dev/null; then
    print_warning "kubectl not configured. Skipping Kubernetes secret creation."
    print_warning "Run the following command after configuring kubectl:"
    echo ""
    echo "  kubectl create namespace devsecops --dry-run=client -o yaml | kubectl apply -f -"
    echo "  kubectl apply -f ${K8S_BASE_DIR}/shared-secrets.yaml"
    echo ""
else
    # Create namespace if it doesn't exist
    kubectl create namespace devsecops --dry-run=client -o yaml | kubectl apply -f -
    print_status "Namespace 'devsecops' ready"
    
    # Apply shared secrets
    kubectl apply -f "${K8S_BASE_DIR}/shared-secrets.yaml"
    print_status "Secrets applied to Kubernetes cluster"
    echo ""
fi

echo -e "${YELLOW}Step 6: Generating Configuration Summary...${NC}"
echo ""

# Create summary file
SUMMARY_FILE="rds-redis-configuration-${ENVIRONMENT}.txt"
cat > "$SUMMARY_FILE" << EOF
═══════════════════════════════════════════════════════════════
  RDS and ElastiCache Configuration Summary
═══════════════════════════════════════════════════════════════

Environment: ${ENVIRONMENT}
Generated: $(date)

RDS (PostgreSQL) Configuration:
────────────────────────────────────────────────────────────────
  Endpoint:  ${RDS_ENDPOINT}
  Port:      ${RDS_PORT}
  Database:  ${RDS_DATABASE}
  Username:  ${RDS_USERNAME}
  Password:  ${RDS_PASSWORD:0:3}*** (masked)

ElastiCache (Redis) Configuration:
────────────────────────────────────────────────────────────────
  Endpoint:  ${REDIS_ENDPOINT}
  Port:      ${REDIS_PORT}
  Auth:      ${REDIS_AUTH_TOKEN:-Not configured}

Services Configured:
────────────────────────────────────────────────────────────────
  ✓ user-service
  ✓ auth-service
  ✓ notification-service
  ✓ analytics-service

Kubernetes Resources:
────────────────────────────────────────────────────────────────
  • ConfigMaps updated with RDS/Redis endpoints
  • Secrets created for credentials
  • Namespace: devsecops

Next Steps:
────────────────────────────────────────────────────────────────
1. Deploy services to Kubernetes:
   cd ../overlays/${ENVIRONMENT}
   kubectl apply -k .

2. Verify pods are connecting to RDS/Redis:
   kubectl get pods -n devsecops
   kubectl logs -n devsecops <pod-name>

3. Test database connectivity:
   kubectl exec -it -n devsecops <pod-name> -- /bin/sh
   # Then test connection to RDS/Redis

4. Monitor service health:
   kubectl get pods -n devsecops -w

Connection Strings (for reference):
────────────────────────────────────────────────────────────────
PostgreSQL:
  postgresql://${RDS_USERNAME}:${RDS_PASSWORD}@${RDS_ENDPOINT}:${RDS_PORT}/${RDS_DATABASE}

Redis:
  redis://${REDIS_ENDPOINT}:${REDIS_PORT}

═══════════════════════════════════════════════════════════════
EOF

print_status "Configuration summary saved to: $SUMMARY_FILE"
echo ""

# Display summary
cat "$SUMMARY_FILE"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║  ✅ Configuration Complete!                               ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║  All services are now configured to use:                 ║${NC}"
echo -e "${GREEN}║  • RDS PostgreSQL: ${RDS_ENDPOINT:0:30}... ║${NC}"
echo -e "${GREEN}║  • ElastiCache Redis: ${REDIS_ENDPOINT:0:27}...║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Next: Deploy your services with:${NC}"
echo -e "  ${YELLOW}cd overlays/${ENVIRONMENT}${NC}"
echo -e "  ${YELLOW}kubectl apply -k .${NC}"
echo ""
