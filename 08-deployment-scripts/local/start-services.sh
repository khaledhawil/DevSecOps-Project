#!/bin/bash

# Start local services

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../helpers/common-functions.sh"

print_header "Starting Local Services"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi

# Check if docker-compose file exists
if [ ! -f "$PROJECT_ROOT/docker-compose.local.yml" ]; then
    print_error "docker-compose.local.yml not found"
    print_info "Please run deployment first: ./local/deploy-local.sh"
    exit 1
fi

cd "$PROJECT_ROOT"

print_info "Starting all services..."
docker-compose -f docker-compose.local.yml up -d

print_success "Services started"

echo ""
print_info "Waiting for services to be ready..."
sleep 10

# Run health check
"$SCRIPT_DIR/check-health.sh"
