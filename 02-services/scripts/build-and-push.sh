#!/bin/bash

################################################################################
# DevSecOps Project - Build and Push Docker Images
################################################################################
#
# Purpose: Build all microservices and push to DockerHub
#
# Usage: ./build-and-push.sh [options]
#
# Options:
#   --tag <tag>          Specify image tag (default: latest)
#   --service <name>     Build specific service only
#   --no-push            Build only, don't push to DockerHub
#   --no-cache           Build without using cache
#   --latest             Also tag as 'latest' (in addition to version tag)
#   --dry-run            Show what would be built without building
#
# Examples:
#   ./build-and-push.sh                           # Build all with 'latest' tag
#   ./build-and-push.sh --tag v1.0.0              # Build all with 'v1.0.0' tag
#   ./build-and-push.sh --service user-service    # Build only user-service
#   ./build-and-push.sh --no-push                 # Build locally only
#   ./build-and-push.sh --tag v1.0.0 --latest     # Tag as both v1.0.0 and latest
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKERHUB_USERNAME="khaledhawil"

# Default values
IMAGE_TAG="latest"
SPECIFIC_SERVICE=""
NO_PUSH=false
NO_CACHE=false
TAG_LATEST=false
DRY_RUN=false

# Service definitions
declare -A SERVICES=(
    ["frontend"]="frontend"
    ["user-service"]="user-service"
    ["auth-service"]="auth-service"
    ["notification-service"]="notification-service"
    ["analytics-service"]="analytics-service"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

################################################################################
# Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_separator() {
    echo -e "${CYAN}----------------------------------------${NC}"
}

usage() {
    cat << EOF
Usage: $0 [options]

Build all microservices and push to DockerHub (${DOCKERHUB_USERNAME})

Options:
  --tag <tag>          Specify image tag (default: latest)
  --service <name>     Build specific service only
  --no-push            Build only, don't push to DockerHub
  --no-cache           Build without using cache
  --latest             Also tag as 'latest' (in addition to version tag)
  --dry-run            Show what would be built without building
  -h, --help           Show this help message

Available Services:
  - frontend
  - user-service
  - auth-service
  - notification-service
  - analytics-service

Examples:
  $0                                    # Build all with 'latest' tag
  $0 --tag v1.0.0                       # Build all with 'v1.0.0' tag
  $0 --service user-service             # Build only user-service
  $0 --no-push                          # Build locally only
  $0 --tag v1.0.0 --latest              # Tag as both v1.0.0 and latest
  $0 --tag v1.0.0 --no-cache --latest   # Clean build with dual tags

EOF
    exit 1
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    # Check DockerHub login (unless --no-push)
    if [ "$NO_PUSH" = false ] && [ "$DRY_RUN" = false ]; then
        if ! docker info | grep -q "Username: ${DOCKERHUB_USERNAME}"; then
            log_warn "Not logged into DockerHub as ${DOCKERHUB_USERNAME}"
            log_info "Attempting to log in..."
            
            if ! docker login; then
                log_error "DockerHub login failed"
                log_info "Please run: docker login"
                exit 1
            fi
        else
            log_success "Already logged into DockerHub as ${DOCKERHUB_USERNAME}"
        fi
    fi
    
    log_success "All prerequisites met"
}

get_build_info() {
    local service=$1
    local service_dir="${SERVICES_DIR}/${service}"
    
    # Get git info if available
    local git_commit="unknown"
    local git_branch="unknown"
    
    if command -v git &> /dev/null && [ -d "${SERVICES_DIR}/.git" ] || [ -d "$(cd "${SERVICES_DIR}/../.git" 2>/dev/null && pwd)" ]; then
        git_commit=$(git -C "${SERVICES_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unknown")
        git_branch=$(git -C "${SERVICES_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    fi
    
    echo "commit=${git_commit} branch=${git_branch}"
}

build_service() {
    local service=$1
    local service_dir="${SERVICES_DIR}/${service}"
    local image_name="${DOCKERHUB_USERNAME}/${service}"
    local full_image="${image_name}:${IMAGE_TAG}"
    
    print_separator
    log_info "Building ${service}..."
    log_info "Image: ${full_image}"
    log_info "Directory: ${service_dir}"
    
    if [ ! -d "${service_dir}" ]; then
        log_error "Service directory not found: ${service_dir}"
        return 1
    fi
    
    if [ ! -f "${service_dir}/Dockerfile" ]; then
        log_error "Dockerfile not found: ${service_dir}/Dockerfile"
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would build: ${full_image}"
        if [ "$TAG_LATEST" = true ] && [ "$IMAGE_TAG" != "latest" ]; then
            log_info "[DRY-RUN] Would also tag as: ${image_name}:latest"
        fi
        if [ "$NO_PUSH" = false ]; then
            log_info "[DRY-RUN] Would push to DockerHub"
        fi
        return 0
    fi
    
    # Get build info
    local build_info=$(get_build_info "${service}")
    
    # Build arguments
    local build_args=(
        "docker" "build"
        "-t" "${full_image}"
        "--label" "version=${IMAGE_TAG}"
        "--label" "service=${service}"
        "--label" "build.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        "--label" "build.${build_info}"
    )
    
    # Add no-cache flag if specified
    if [ "$NO_CACHE" = true ]; then
        build_args+=("--no-cache")
    fi
    
    # Add context
    build_args+=("-f" "${service_dir}/Dockerfile" "${service_dir}")
    
    # Execute build
    log_info "Executing: ${build_args[*]}"
    
    local start_time=$(date +%s)
    
    if "${build_args[@]}"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Built ${service} in ${duration}s"
    else
        log_error "Failed to build ${service}"
        return 1
    fi
    
    # Tag as latest if requested
    if [ "$TAG_LATEST" = true ] && [ "$IMAGE_TAG" != "latest" ]; then
        log_info "Tagging as latest..."
        docker tag "${full_image}" "${image_name}:latest"
        log_success "Tagged as ${image_name}:latest"
    fi
    
    # Show image info
    log_info "Image details:"
    docker images "${image_name}" | grep -E "REPOSITORY|${IMAGE_TAG}|latest" || true
    
    return 0
}

push_service() {
    local service=$1
    local image_name="${DOCKERHUB_USERNAME}/${service}"
    local full_image="${image_name}:${IMAGE_TAG}"
    
    if [ "$NO_PUSH" = true ]; then
        log_info "Skipping push for ${service} (--no-push flag)"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would push: ${full_image}"
        return 0
    fi
    
    print_separator
    log_info "Pushing ${service} to DockerHub..."
    log_info "Pushing: ${full_image}"
    
    local start_time=$(date +%s)
    
    if docker push "${full_image}"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Pushed ${full_image} in ${duration}s"
    else
        log_error "Failed to push ${service}"
        return 1
    fi
    
    # Push latest tag if it exists
    if [ "$TAG_LATEST" = true ] && [ "$IMAGE_TAG" != "latest" ]; then
        log_info "Pushing: ${image_name}:latest"
        if docker push "${image_name}:latest"; then
            log_success "Pushed ${image_name}:latest"
        else
            log_error "Failed to push latest tag"
            return 1
        fi
    fi
    
    return 0
}

display_summary() {
    local success_count=$1
    local total_count=$2
    local failed_services=$3
    
    print_header "Build Summary"
    
    echo "Total Services: ${total_count}"
    echo "Successful: ${success_count}"
    echo "Failed: $((total_count - success_count))"
    echo ""
    echo "Docker Hub: ${DOCKERHUB_USERNAME}"
    echo "Image Tag: ${IMAGE_TAG}"
    
    if [ "$TAG_LATEST" = true ]; then
        echo "Also Tagged: latest"
    fi
    
    if [ "$NO_PUSH" = true ]; then
        echo "Push: Skipped (--no-push)"
    else
        echo "Push: Enabled"
    fi
    
    if [ "$NO_CACHE" = true ]; then
        echo "Cache: Disabled (--no-cache)"
    fi
    
    echo ""
    
    if [ ${success_count} -eq ${total_count} ]; then
        log_success "All services built successfully! ✅"
    else
        log_error "Some services failed to build:"
        echo -e "${RED}${failed_services}${NC}"
    fi
    
    if [ "$NO_PUSH" = false ] && [ ${success_count} -eq ${total_count} ]; then
        echo ""
        log_info "Images available on DockerHub:"
        for service in "${!SERVICES[@]}"; do
            echo "  • docker pull ${DOCKERHUB_USERNAME}/${service}:${IMAGE_TAG}"
        done
    fi
    
    print_separator
}

################################################################################
# Main Execution
################################################################################

main() {
    # Parse arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --tag)
                IMAGE_TAG="$2"
                shift 2
                ;;
            --service)
                SPECIFIC_SERVICE="$2"
                shift 2
                ;;
            --no-push)
                NO_PUSH=true
                shift
                ;;
            --no-cache)
                NO_CACHE=true
                shift
                ;;
            --latest)
                TAG_LATEST=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Display banner
    print_header "DevSecOps Docker Build & Push"
    
    echo "Configuration:"
    echo "  DockerHub Username: ${DOCKERHUB_USERNAME}"
    echo "  Image Tag: ${IMAGE_TAG}"
    echo "  Specific Service: ${SPECIFIC_SERVICE:-all}"
    echo "  No Push: ${NO_PUSH}"
    echo "  No Cache: ${NO_CACHE}"
    echo "  Tag Latest: ${TAG_LATEST}"
    echo "  Dry Run: ${DRY_RUN}"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Determine which services to build
    local services_to_build=()
    
    if [ -n "$SPECIFIC_SERVICE" ]; then
        if [[ -v "SERVICES[$SPECIFIC_SERVICE]" ]]; then
            services_to_build=("$SPECIFIC_SERVICE")
        else
            log_error "Unknown service: ${SPECIFIC_SERVICE}"
            echo "Available services: ${!SERVICES[@]}"
            exit 1
        fi
    else
        services_to_build=("${!SERVICES[@]}")
    fi
    
    # Build and push services
    local start_time=$(date +%s)
    local success_count=0
    local total_count=${#services_to_build[@]}
    local failed_services=""
    
    print_header "Building Services"
    
    for service in "${services_to_build[@]}"; do
        if build_service "${service}"; then
            if push_service "${service}"; then
                ((success_count++))
            else
                failed_services+="  • ${service} (push failed)\n"
            fi
        else
            failed_services+="  • ${service} (build failed)\n"
        fi
    done
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    # Display summary
    display_summary "${success_count}" "${total_count}" "${failed_services}"
    
    echo "Total Time: ${total_duration}s"
    
    # Exit with appropriate code
    if [ ${success_count} -eq ${total_count} ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
