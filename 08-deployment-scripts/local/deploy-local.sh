#!/bin/bash

# Deploy DevSecOps Platform Locally
# This script deploys all services locally using Docker Compose

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../helpers/common-functions.sh"

print_header "DevSecOps Platform - Local Deployment"

# Check prerequisites
print_info "Checking prerequisites..."
check_command "docker" "Docker is required. Install from https://docs.docker.com/get-docker/"
check_command "docker-compose" "Docker Compose is required. Install from https://docs.docker.com/compose/install/"

# Check Docker daemon
if ! docker info > /dev/null 2>&1; then
    print_error "Docker daemon is not running. Please start Docker."
    exit 1
fi

print_success "Prerequisites check passed"

# Create .env.local if it doesn't exist
print_info "Setting up environment variables..."
if [ ! -f "$PROJECT_ROOT/.env.local" ]; then
    cat > "$PROJECT_ROOT/.env.local" << 'EOF'
# PostgreSQL Configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=devsecops
POSTGRES_PASSWORD=local_dev_password
POSTGRES_DB=devsecops

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT Configuration
JWT_ACCESS_SECRET=local-jwt-access-secret-change-in-production
JWT_REFRESH_SECRET=local-jwt-refresh-secret-change-in-production
JWT_EXPIRY=1h
JWT_REFRESH_EXPIRY=7d

# SMTP Configuration (for notifications)
SMTP_HOST=mailhog
SMTP_PORT=1025
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM=noreply@devsecops.local

# Twilio Configuration (optional)
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# Service URLs
USER_SERVICE_URL=http://user-service:8080
AUTH_SERVICE_URL=http://auth-service:3001
NOTIFICATION_SERVICE_URL=http://notification-service:5000
ANALYTICS_SERVICE_URL=http://analytics-service:8081

# Environment
NODE_ENV=development
GO_ENV=development
FLASK_ENV=development
SPRING_PROFILES_ACTIVE=development
EOF
    print_success "Created .env.local"
else
    print_info ".env.local already exists"
fi

# Create docker-compose.local.yml
print_info "Creating docker-compose.local.yml..."
cat > "$PROJECT_ROOT/docker-compose.local.yml" << 'EOF'
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15.5
    container_name: devsecops-postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - devsecops-network

  # Redis Cache
  redis:
    image: redis:7.2-alpine
    container_name: devsecops-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - devsecops-network

  # MailHog (Email testing)
  mailhog:
    image: mailhog/mailhog:v1.0.1
    container_name: devsecops-mailhog
    ports:
      - "1025:1025"  # SMTP
      - "8025:8025"  # Web UI
    networks:
      - devsecops-network

  # User Service (Go)
  user-service:
    build:
      context: ./02-services/user-service
      dockerfile: Dockerfile
    container_name: devsecops-user-service
    environment:
      - DB_HOST=${POSTGRES_HOST}
      - DB_PORT=${POSTGRES_PORT}
      - DB_USER=${POSTGRES_USER}
      - DB_PASSWORD=${POSTGRES_PASSWORD}
      - DB_NAME=${POSTGRES_DB}
      - REDIS_HOST=${REDIS_HOST}
      - REDIS_PORT=${REDIS_PORT}
      - JWT_SECRET=${JWT_ACCESS_SECRET}
      - PORT=8080
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - devsecops-network

  # Auth Service (Node.js)
  auth-service:
    build:
      context: ./02-services/auth-service
      dockerfile: Dockerfile
    container_name: devsecops-auth-service
    environment:
      - NODE_ENV=${NODE_ENV}
      - DB_HOST=${POSTGRES_HOST}
      - DB_PORT=${POSTGRES_PORT}
      - DB_USER=${POSTGRES_USER}
      - DB_PASSWORD=${POSTGRES_PASSWORD}
      - DB_NAME=${POSTGRES_DB}
      - REDIS_HOST=${REDIS_HOST}
      - REDIS_PORT=${REDIS_PORT}
      - JWT_ACCESS_SECRET=${JWT_ACCESS_SECRET}
      - JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}
      - JWT_EXPIRY=${JWT_EXPIRY}
      - JWT_REFRESH_EXPIRY=${JWT_REFRESH_EXPIRY}
      - PORT=3001
    ports:
      - "3001:3001"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - devsecops-network

  # Notification Service (Python)
  notification-service:
    build:
      context: ./02-services/notification-service
      dockerfile: Dockerfile
    container_name: devsecops-notification-service
    environment:
      - FLASK_ENV=${FLASK_ENV}
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
      - REDIS_URL=redis://${REDIS_HOST}:${REDIS_PORT}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USER=${SMTP_USER}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
      - SMTP_FROM=${SMTP_FROM}
      - TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID}
      - TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN}
      - TWILIO_PHONE_NUMBER=${TWILIO_PHONE_NUMBER}
    ports:
      - "5000:5000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      mailhog:
        condition: service_started
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - devsecops-network

  # Celery Worker (for notification service)
  celery-worker:
    build:
      context: ./02-services/notification-service
      dockerfile: Dockerfile
    container_name: devsecops-celery-worker
    command: celery -A app.celery worker --loglevel=info
    environment:
      - FLASK_ENV=${FLASK_ENV}
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
      - REDIS_URL=redis://${REDIS_HOST}:${REDIS_PORT}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
    depends_on:
      redis:
        condition: service_healthy
      notification-service:
        condition: service_started
    networks:
      - devsecops-network

  # Analytics Service (Java)
  analytics-service:
    build:
      context: ./02-services/analytics-service
      dockerfile: Dockerfile
    container_name: devsecops-analytics-service
    environment:
      - SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE}
      - SPRING_DATASOURCE_URL=jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
      - SPRING_DATASOURCE_USERNAME=${POSTGRES_USER}
      - SPRING_DATASOURCE_PASSWORD=${POSTGRES_PASSWORD}
      - SPRING_REDIS_HOST=${REDIS_HOST}
      - SPRING_REDIS_PORT=${REDIS_PORT}
    ports:
      - "8081:8081"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8081/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - devsecops-network

  # Frontend (React)
  frontend:
    build:
      context: ./02-services/frontend
      dockerfile: Dockerfile
      args:
        - VITE_USER_SERVICE_URL=http://localhost:8080
        - VITE_AUTH_SERVICE_URL=http://localhost:3001
        - VITE_NOTIFICATION_SERVICE_URL=http://localhost:5000
        - VITE_ANALYTICS_SERVICE_URL=http://localhost:8081
    container_name: devsecops-frontend
    ports:
      - "3000:80"
    depends_on:
      - user-service
      - auth-service
      - notification-service
      - analytics-service
    networks:
      - devsecops-network

networks:
  devsecops-network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
EOF

print_success "Created docker-compose.local.yml"

# Create init-db.sql script
print_info "Creating database initialization script..."
mkdir -p "$PROJECT_ROOT/scripts"
cat > "$PROJECT_ROOT/scripts/init-db.sql" << 'EOF'
-- Initialize databases for all services
CREATE DATABASE IF NOT EXISTS devsecops;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE devsecops TO devsecops;

-- Create schemas if needed
\c devsecops;
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS notifications;
CREATE SCHEMA IF NOT EXISTS analytics;
EOF

print_success "Created init-db.sql"

# Build services
print_info "Building Docker images (this may take a few minutes)..."
cd "$PROJECT_ROOT"
docker-compose -f docker-compose.local.yml build --parallel

print_success "Images built successfully"

# Start services
print_info "Starting all services..."
docker-compose -f docker-compose.local.yml up -d

print_success "Services started"

# Wait for services to be healthy
print_info "Waiting for services to be healthy (this may take 1-2 minutes)..."
sleep 10

# Check health
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HEALTHY_COUNT=0
    
    # Check each service
    if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
        ((HEALTHY_COUNT++))
    fi
    
    if curl -sf http://localhost:3001/health > /dev/null 2>&1; then
        ((HEALTHY_COUNT++))
    fi
    
    if curl -sf http://localhost:5000/health > /dev/null 2>&1; then
        ((HEALTHY_COUNT++))
    fi
    
    if curl -sf http://localhost:8081/actuator/health > /dev/null 2>&1; then
        ((HEALTHY_COUNT++))
    fi
    
    if [ $HEALTHY_COUNT -eq 4 ]; then
        break
    fi
    
    ((RETRY_COUNT++))
    echo -n "."
    sleep 2
done

echo ""

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    print_warning "Some services may not be fully healthy yet. Check logs with: docker-compose -f docker-compose.local.yml logs"
else
    print_success "All services are healthy"
fi

# Display service information
print_header "Deployment Complete!"

echo ""
print_info "=== Service URLs ==="
echo ""
echo -e "  ${GREEN}Frontend:${NC}              http://localhost:3000"
echo -e "  ${GREEN}User Service:${NC}          http://localhost:8080"
echo -e "  ${GREEN}Auth Service:${NC}          http://localhost:3001"
echo -e "  ${GREEN}Notification Service:${NC}  http://localhost:5000"
echo -e "  ${GREEN}Analytics Service:${NC}     http://localhost:8081"
echo ""
echo -e "  ${BLUE}PostgreSQL:${NC}            localhost:5432"
echo -e "  ${BLUE}Redis:${NC}                 localhost:6379"
echo -e "  ${BLUE}MailHog UI:${NC}            http://localhost:8025"
echo ""

print_info "=== Useful Commands ==="
echo ""
echo "  View logs:           docker-compose -f docker-compose.local.yml logs -f"
echo "  Stop services:       docker-compose -f docker-compose.local.yml stop"
echo "  Restart services:    docker-compose -f docker-compose.local.yml restart"
echo "  Clean up:            docker-compose -f docker-compose.local.yml down -v"
echo "  Check health:        ./local/check-health.sh"
echo ""

print_success "Local deployment complete! 🚀"
