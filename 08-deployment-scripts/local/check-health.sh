#!/bin/bash

# Check health of all locally running services

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/../helpers/common-functions.sh"

print_header "Health Check - Local Services"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi

# Check if services are running
SERVICES=(
    "devsecops-postgres:PostgreSQL:5432"
    "devsecops-redis:Redis:6379"
    "devsecops-user-service:User Service:8080"
    "devsecops-auth-service:Auth Service:3001"
    "devsecops-notification-service:Notification Service:5000"
    "devsecops-analytics-service:Analytics Service:8081"
    "devsecops-frontend:Frontend:3000"
    "devsecops-mailhog:MailHog:8025"
)

ALL_HEALTHY=true

for service in "${SERVICES[@]}"; do
    IFS=':' read -r container_name service_name port <<< "$service"
    
    # Check if container is running
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        # Check container health status
        health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")
        
        if [ "$health_status" = "healthy" ]; then
            print_success "$service_name is running and healthy"
        elif [ "$health_status" = "unknown" ]; then
            # No health check defined, check if running
            if docker ps --filter "name=${container_name}" --filter "status=running" | grep -q "$container_name"; then
                print_success "$service_name is running"
            else
                print_error "$service_name is not running properly"
                ALL_HEALTHY=false
            fi
        else
            print_warning "$service_name is running but health status is: $health_status"
            ALL_HEALTHY=false
        fi
    else
        print_error "$service_name is not running"
        ALL_HEALTHY=false
    fi
done

echo ""
print_header "Service Endpoints"

# Test HTTP endpoints
ENDPOINTS=(
    "http://localhost:8080/health:User Service"
    "http://localhost:3001/health:Auth Service"
    "http://localhost:5000/health:Notification Service"
    "http://localhost:8081/actuator/health:Analytics Service"
    "http://localhost:3000:Frontend"
)

for endpoint in "${ENDPOINTS[@]}"; do
    IFS=':' read -r url service_name <<< "$endpoint"
    
    if curl -sf "$url" > /dev/null 2>&1; then
        print_success "$service_name endpoint is accessible: $url"
    else
        print_error "$service_name endpoint is not accessible: $url"
        ALL_HEALTHY=false
    fi
done

echo ""
print_header "Container Stats"

# Display resource usage
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
    devsecops-postgres \
    devsecops-redis \
    devsecops-user-service \
    devsecops-auth-service \
    devsecops-notification-service \
    devsecops-analytics-service \
    devsecops-frontend \
    2>/dev/null || print_warning "Could not retrieve container stats"

echo ""
if [ "$ALL_HEALTHY" = true ]; then
    print_success "All services are healthy! ✨"
    echo ""
    print_info "Access the application:"
    echo "  Frontend:     http://localhost:3000"
    echo "  User API:     http://localhost:8080"
    echo "  Auth API:     http://localhost:3001"
    echo "  Notify API:   http://localhost:5000"
    echo "  Analytics API: http://localhost:8081"
    echo "  MailHog UI:   http://localhost:8025"
    exit 0
else
    print_error "Some services are unhealthy"
    echo ""
    print_info "Troubleshooting commands:"
    echo "  View logs:    docker-compose -f docker-compose.local.yml logs -f [service-name]"
    echo "  Restart:      docker-compose -f docker-compose.local.yml restart [service-name]"
    echo "  Rebuild:      docker-compose -f docker-compose.local.yml up -d --build [service-name]"
    exit 1
fi
