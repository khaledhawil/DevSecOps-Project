#!/bin/bash

# Clean up local deployment

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../helpers/common-functions.sh"

print_header "Cleaning Up Local Environment"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi

# Confirm cleanup
if ! confirm "This will remove all containers and volumes. All data will be lost. Continue?"; then
    print_info "Cleanup cancelled"
    exit 0
fi

# Check if docker-compose file exists
if [ -f "$PROJECT_ROOT/docker-compose.local.yml" ]; then
    cd "$PROJECT_ROOT"
    
    print_info "Stopping and removing containers..."
    docker-compose -f docker-compose.local.yml down
    
    print_info "Removing volumes..."
    docker-compose -f docker-compose.local.yml down -v
    
    print_success "Containers and volumes removed"
else
    print_warning "docker-compose.local.yml not found, cleaning up by container names..."
    
    # Remove containers by name
    CONTAINERS=(
        "devsecops-postgres"
        "devsecops-redis"
        "devsecops-mailhog"
        "devsecops-user-service"
        "devsecops-auth-service"
        "devsecops-notification-service"
        "devsecops-celery-worker"
        "devsecops-analytics-service"
        "devsecops-frontend"
    )
    
    for container in "${CONTAINERS[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            print_info "Removing container: $container"
            docker rm -f "$container" 2>/dev/null || true
        fi
    done
fi

# Remove dangling images
print_info "Removing dangling images..."
docker image prune -f

print_success "Local environment cleaned up!"

echo ""
print_info "To deploy again: ./local/deploy-local.sh"
