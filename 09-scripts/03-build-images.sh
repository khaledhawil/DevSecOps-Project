#!/bin/bash

################################################################################
# DevSecOps Project - Build All Docker Images
################################################################################
#
# Purpose: Build Docker images for all microservices
#
# This script:
#   1. Builds images for all services
#   2. Tags with version and latest
#   3. Uses build caching for efficiency
#   4. Generates build reports
#
# Usage: ./03-build-images.sh [service]
# Example: ./03-build-images.sh              # Build all images
#          ./03-build-images.sh user-service # Build specific service
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICES_DIR="${PROJECT_ROOT}/02-services"
DOCKER_USERNAME="${DOCKER_USERNAME:-khaledhawil}"
VERSION="${VERSION:-$(git rev-parse --short HEAD 2>/dev/null || echo 'latest')}"
SERVICE="${1:-all}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Build stats
TOTAL_BUILDS=0
SUCCESSFUL_BUILDS=0
FAILED_BUILDS=0

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

log_build() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] BUILD:${NC} $*"
}

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                DevSecOps - Docker Image Builder                      ║
║                                                                      ║
║                  Building all Docker images...                       ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

build_image() {
    local service_name=$1
    local service_dir=$2
    local dockerfile="${3:-Dockerfile}"
    
    log_build "Building ${service_name}..."
    
    TOTAL_BUILDS=$((TOTAL_BUILDS + 1))
    
    # Check if Dockerfile exists
    if [[ ! -f "${service_dir}/${dockerfile}" ]]; then
        log_error "Dockerfile not found: ${service_dir}/${dockerfile}"
        FAILED_BUILDS=$((FAILED_BUILDS + 1))
        return 1
    fi
    
    # Build image
    local image_name="${DOCKER_USERNAME}/${service_name}"
    
    log_info "Building ${image_name}:${VERSION}..."
    
    if docker build \
        -t "${image_name}:${VERSION}" \
        -t "${image_name}:latest" \
        -f "${service_dir}/${dockerfile}" \
        "${service_dir}"; then
        
        log "✓ ${service_name} built successfully"
        SUCCESSFUL_BUILDS=$((SUCCESSFUL_BUILDS + 1))
        
        # Show image size
        local size=$(docker images "${image_name}:${VERSION}" --format "{{.Size}}")
        log_info "Image size: ${size}"
        
        return 0
    else
        log_error "✗ ${service_name} build failed"
        FAILED_BUILDS=$((FAILED_BUILDS + 1))
        return 1
    fi
}

build_user_service() {
    log_build "Building User Service (Go)..."
    build_image "user-service" "${SERVICES_DIR}/user-service" "Dockerfile"
}

build_auth_service() {
    log_build "Building Auth Service (Node.js)..."
    build_image "auth-service" "${SERVICES_DIR}/auth-service" "Dockerfile"
}

build_notification_service() {
    log_build "Building Notification Service (Python)..."
    build_image "notification-service" "${SERVICES_DIR}/notification-service" "Dockerfile"
}

build_analytics_service() {
    log_build "Building Analytics Service (Java)..."
    build_image "analytics-service" "${SERVICES_DIR}/analytics-service" "Dockerfile"
}

build_frontend() {
    log_build "Building Frontend (React)..."
    build_image "frontend" "${SERVICES_DIR}/frontend" "Dockerfile"
}

print_summary() {
    local success_rate=0
    if [[ ${TOTAL_BUILDS} -gt 0 ]]; then
        success_rate=$(( (SUCCESSFUL_BUILDS * 100) / TOTAL_BUILDS ))
    fi
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                     ${GREEN}Build Summary${NC}                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Total Builds:    ${YELLOW}${TOTAL_BUILDS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Successful:      ${GREEN}${SUCCESSFUL_BUILDS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Failed:          ${RED}${FAILED_BUILDS}${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Success Rate:    ${YELLOW}${success_rate}%${NC}                                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Version Tag:     ${YELLOW}${VERSION}${NC}                                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Registry:        ${YELLOW}${DOCKER_USERNAME}${NC}                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

list_images() {
    log_info "Built images:"
    echo ""
    docker images | grep "${DOCKER_USERNAME}" | head -20
    echo ""
}

# Main execution
main() {
    print_banner
    
    log "Starting Docker image builds..."
    log "Version: ${VERSION}"
    log "Docker Username: ${DOCKER_USERNAME}"
    log "Service filter: ${SERVICE}"
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker is not running"
        exit 1
    fi
    
    # Build images
    if [[ "${SERVICE}" == "all" ]]; then
        build_user_service || true
        build_auth_service || true
        build_notification_service || true
        build_analytics_service || true
        build_frontend || true
    else
        case "${SERVICE}" in
            user-service)
                build_user_service
                ;;
            auth-service)
                build_auth_service
                ;;
            notification-service)
                build_notification_service
                ;;
            analytics-service)
                build_analytics_service
                ;;
            frontend)
                build_frontend
                ;;
            *)
                log_error "Unknown service: ${SERVICE}"
                echo "Valid services: user-service, auth-service, notification-service, analytics-service, frontend, all"
                exit 1
                ;;
        esac
    fi
    
    print_summary
    list_images
    
    if [[ ${FAILED_BUILDS} -gt 0 ]]; then
        log_error "Some builds failed!"
        exit 1
    fi
    
    log "✅ All images built successfully!"
    log "Next steps:"
    log "  1. Scan images: ./04-scan-security.sh"
    log "  2. Push images: ./push-images.sh ${DOCKER_USERNAME}"
}

# Trap errors
trap 'log_error "Build process failed"; exit 1' ERR

# Run main
main "$@"
