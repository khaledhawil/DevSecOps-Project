#!/bin/bash

# Update image tags in Kubernetes manifests
# Usage: ./update-images.sh <environment> <service> <tag>

set -e

ENVIRONMENT=${1:-dev}
SERVICE=${2:-}
TAG=${3:-}

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Validate inputs
if [ -z "$SERVICE" ] || [ -z "$TAG" ]; then
    print_error "Service and tag are required"
    echo "Usage: ./update-images.sh <environment> <service> <tag>"
    echo "Example: ./update-images.sh dev user-service v1.2.0"
    exit 1
fi

VALID_ENVS=("dev" "staging" "prod")
if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
    print_error "Invalid environment: ${ENVIRONMENT}"
    echo "Valid environments: ${VALID_ENVS[@]}"
    exit 1
fi

OVERLAY_PATH="04-kubernetes/overlays/${ENVIRONMENT}"

if [ ! -d "$OVERLAY_PATH" ]; then
    print_error "Overlay directory not found: ${OVERLAY_PATH}"
    exit 1
fi

print_info "Updating ${SERVICE} to ${TAG} in ${ENVIRONMENT} environment"

cd $OVERLAY_PATH

# Update kustomization.yaml
kustomize edit set image ${SERVICE}=${TAG}

print_info "Image tag updated in ${OVERLAY_PATH}/kustomization.yaml"

# Commit changes
if [ -n "$(git status --porcelain)" ]; then
    print_info "Committing changes..."
    git add kustomization.yaml
    git commit -m "Update ${SERVICE} image to ${TAG} in ${ENVIRONMENT}"
    
    print_warn "Don't forget to push changes: git push"
else
    print_warn "No changes to commit"
fi

print_info "Done!"
