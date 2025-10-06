#!/bin/bash

# Build all services locally
# Usage: ./build-all.sh [tag]

set -e

TAG=${1:-latest}

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Services to build
SERVICES=("user-service" "auth-service" "notification-service" "analytics-service" "frontend")

print_info "Building all services with tag: ${TAG}"

for SERVICE in "${SERVICES[@]}"; do
    print_info "Building ${SERVICE}..."
    
    SERVICE_PATH="02-services/${SERVICE}"
    
    if [ ! -d "$SERVICE_PATH" ]; then
        print_warn "Service directory not found: ${SERVICE_PATH}, skipping..."
        continue
    fi
    
    docker build \
        -t ${SERVICE}:${TAG} \
        -f ${SERVICE_PATH}/Dockerfile \
        ${SERVICE_PATH}
    
    print_info "${SERVICE} built successfully"
done

print_info "All services built successfully!"
print_info "To push images, run: ./push-all.sh ${TAG}"
