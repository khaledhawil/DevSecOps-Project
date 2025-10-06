#!/bin/bash

# Deployment script for Kubernetes manifests
# Usage: ./deploy.sh <environment>
# Example: ./deploy.sh dev

set -e

ENVIRONMENT=${1:-dev}
VALID_ENVS=("dev" "staging" "prod")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate environment
if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
    print_error "Invalid environment: ${ENVIRONMENT}"
    echo "Valid environments: ${VALID_ENVS[@]}"
    exit 1
fi

print_info "Deploying to environment: ${ENVIRONMENT}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if kustomize is available
if ! command -v kustomize &> /dev/null; then
    print_warn "kustomize not found, using kubectl kustomize"
fi

# Check cluster connectivity
print_info "Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    print_info "Please run: aws eks update-kubeconfig --region us-east-1 --name devsecops-${ENVIRONMENT}-eks"
    exit 1
fi

# Get current context
CONTEXT=$(kubectl config current-context)
print_info "Current context: ${CONTEXT}"

# Confirmation for production
if [ "$ENVIRONMENT" == "prod" ]; then
    print_warn "You are about to deploy to PRODUCTION!"
    read -p "Are you sure you want to continue? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        print_info "Deployment cancelled"
        exit 0
    fi
fi

# Navigate to the overlays directory
cd "$(dirname "$0")/../overlays/${ENVIRONMENT}"

# Create namespace if it doesn't exist
NAMESPACE="devsecops-${ENVIRONMENT}"
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    print_info "Creating namespace: ${NAMESPACE}"
    kubectl create namespace ${NAMESPACE}
fi

# Create secrets from AWS Secrets Manager
print_info "Creating secrets from AWS Secrets Manager..."

# RDS credentials
print_info "Creating RDS credentials secret..."
RDS_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id devsecops-${ENVIRONMENT}-rds-password \
    --query SecretString --output text 2>/dev/null || echo "")

if [ -n "$RDS_PASSWORD" ]; then
    kubectl create secret generic rds-credentials \
        --from-literal=username=dbadmin \
        --from-literal=password="${RDS_PASSWORD}" \
        --namespace=${NAMESPACE} \
        --dry-run=client -o yaml | kubectl apply -f -
else
    print_warn "Could not retrieve RDS password from Secrets Manager"
fi

# Redis credentials
print_info "Creating Redis credentials secret..."
REDIS_TOKEN=$(aws secretsmanager get-secret-value \
    --secret-id devsecops-${ENVIRONMENT}-redis-auth-token \
    --query SecretString --output text 2>/dev/null || echo "")

if [ -n "$REDIS_TOKEN" ]; then
    kubectl create secret generic redis-credentials \
        --from-literal=auth-token="${REDIS_TOKEN}" \
        --namespace=${NAMESPACE} \
        --dry-run=client -o yaml | kubectl apply -f -
else
    print_warn "Could not retrieve Redis auth token from Secrets Manager"
fi

# Preview changes
print_info "Previewing changes..."
kubectl kustomize . | head -50

read -p "Continue with deployment? (yes/no): " CONTINUE
if [ "$CONTINUE" != "yes" ]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Apply configuration
print_info "Applying Kubernetes manifests..."
kubectl apply -k .

# Wait for deployments to be ready
print_info "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/user-service-${ENVIRONMENT} \
    deployment/auth-service-${ENVIRONMENT} \
    deployment/notification-service-${ENVIRONMENT} \
    deployment/analytics-service-${ENVIRONMENT} \
    deployment/frontend-${ENVIRONMENT} \
    -n ${NAMESPACE}

# Get deployment status
print_info "Deployment status:"
kubectl get all -n ${NAMESPACE}

# Get ingress information
print_info "Ingress information:"
kubectl get ingress -n ${NAMESPACE}

# Check pod logs for errors
print_info "Checking for pod errors..."
PODS=$(kubectl get pods -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
    if kubectl get pod $POD -n ${NAMESPACE} -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' | grep -q "Error\|CrashLoopBackOff"; then
        print_error "Pod $POD has errors:"
        kubectl logs $POD -n ${NAMESPACE} --tail=20
    fi
done

print_info "Deployment completed successfully!"
print_info "To check status: kubectl get all -n ${NAMESPACE}"
print_info "To view logs: kubectl logs -f deployment/user-service-${ENVIRONMENT} -n ${NAMESPACE}"
