#!/bin/bash

# Cleanup script for Kubernetes resources
# Usage: ./cleanup.sh <environment>
# Example: ./cleanup.sh dev

set -e

ENVIRONMENT=${1:-dev}
VALID_ENVS=("dev" "staging" "prod")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

print_warn "This will delete all resources in environment: ${ENVIRONMENT}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_info "Cleanup cancelled"
    exit 0
fi

# Additional confirmation for production
if [ "$ENVIRONMENT" == "prod" ]; then
    print_error "WARNING: You are about to delete PRODUCTION resources!"
    read -p "Type 'DELETE PRODUCTION' to confirm: " PROD_CONFIRM
    if [ "$PROD_CONFIRM" != "DELETE PRODUCTION" ]; then
        print_info "Cleanup cancelled"
        exit 0
    fi
fi

NAMESPACE="devsecops-${ENVIRONMENT}"

# Check if namespace exists
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    print_warn "Namespace ${NAMESPACE} does not exist"
    exit 0
fi

# Navigate to the overlays directory
cd "$(dirname "$0")/../overlays/${ENVIRONMENT}"

# Delete resources
print_info "Deleting Kubernetes resources..."
kubectl delete -k . || true

# Delete namespace
print_info "Deleting namespace: ${NAMESPACE}"
kubectl delete namespace ${NAMESPACE} || true

# Wait for namespace to be deleted
print_info "Waiting for namespace to be fully deleted..."
kubectl wait --for=delete namespace/${NAMESPACE} --timeout=300s || true

print_info "Cleanup completed successfully!"
