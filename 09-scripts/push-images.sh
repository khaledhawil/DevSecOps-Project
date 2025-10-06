#!/bin/bash

################################################################################
# DevSecOps Project - Push Docker Images
################################################################################
#
# Purpose: Push all Docker images to Docker Hub
#
# Usage: ./push-images.sh [username]
# Example: ./push-images.sh khaledhawil
#
################################################################################

set -euo pipefail

# Configuration
DOCKER_USERNAME="${1:-${DOCKER_USERNAME:-khaledhawil}}"
VERSION="${VERSION:-$(git rev-parse --short HEAD 2>/dev/null || echo 'latest')}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $*"
}

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║              DevSecOps - Push Docker Images                          ║
║                                                                      ║
║                  Pushing images to Docker Hub...                     ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

docker_login() {
    log "Logging in to Docker Hub..."
    
    if [[ -n "${DOCKER_PASSWORD:-}" ]]; then
        echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
    else
        docker login -u "${DOCKER_USERNAME}"
    fi
    
    log "✓ Logged in to Docker Hub"
}

push_image() {
    local service=$1
    local image="${DOCKER_USERNAME}/${service}"
    
    log "Pushing ${service}..."
    
    # Push versioned tag
    if docker push "${image}:${VERSION}"; then
        log "  ✓ Pushed ${image}:${VERSION}"
    else
        log_error "  ✗ Failed to push ${image}:${VERSION}"
        return 1
    fi
    
    # Push latest tag
    if docker push "${image}:latest"; then
        log "  ✓ Pushed ${image}:latest"
    else
        log_error "  ✗ Failed to push ${image}:latest"
        return 1
    fi
}

main() {
    print_banner
    
    log "Pushing images for user: ${DOCKER_USERNAME}"
    log "Version: ${VERSION}"
    
    docker_login
    
    # Push all service images
    push_image "user-service"
    push_image "auth-service"
    push_image "notification-service"
    push_image "analytics-service"
    push_image "frontend"
    
    log "✅ All images pushed successfully!"
    log "View at: https://hub.docker.com/u/${DOCKER_USERNAME}"
}

main "$@"
