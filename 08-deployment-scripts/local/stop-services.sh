#!/bin/bash

# Stop all locally running services

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../helpers/common-functions.sh"

print_header "Stopping Local Services"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi

# Check if docker-compose file exists
if [ ! -f "$PROJECT_ROOT/docker-compose.local.yml" ]; then
    print_error "docker-compose.local.yml not found"
    print_info "Have you deployed locally yet? Run: ./local/deploy-local.sh"
    exit 1
fi

cd "$PROJECT_ROOT"

print_info "Stopping all services..."
docker-compose -f docker-compose.local.yml stop

print_success "All services stopped"

echo ""
print_info "=== Service Status ==="
docker-compose -f docker-compose.local.yml ps

echo ""
print_info "To start services again: ./local/start-services.sh"
print_info "To remove containers: ./local/clean-local.sh"
