#!/bin/bash

################################################################################
# DevSecOps Project - Start Local Development Environment
################################################################################
#
# Purpose: Start all services locally using Docker Compose
#
# This script:
#   1. Validates prerequisites
#   2. Starts all microservices
#   3. Initializes databases
#   4. Waits for services to be healthy
#   5. Displays access URLs
#
# Usage: ./01-start-local.sh
#
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SERVICES_DIR="${PROJECT_ROOT}/02-services"
COMPOSE_FILE="${SERVICES_DIR}/docker-compose.yml"

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

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARN:${NC} $*"
}

log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $*"
}

print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║              DevSecOps Local Development Environment                 ║
║                                                                      ║
║                    Starting all services...                          ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log "✓ All prerequisites met"
}

check_ports() {
    log "Checking if ports are available..."
    
    local ports=(3000 5432 6379 8081 8082 8083 8084 8025)
    local port_in_use=false
    
    for port in "${ports[@]}"; do
        if lsof -Pi :${port} -sTCP:LISTEN -t >/dev/null 2>&1; then
            log_warn "Port ${port} is already in use"
            port_in_use=true
        fi
    done
    
    if [[ "${port_in_use}" == "true" ]]; then
        read -p "Some ports are in use. Continue anyway? (y/n): " confirm
        if [[ "${confirm}" != "y" ]]; then
            log "Cancelled by user"
            exit 0
        fi
    fi
}

start_services() {
    log "Starting services with Docker Compose..."
    
    cd "${SERVICES_DIR}"
    
    # Pull latest images
    log_info "Pulling latest images..."
    docker compose pull
    
    # Start services
    log_info "Starting containers..."
    docker compose up -d
    
    log "✓ Services started"
}

wait_for_services() {
    log "Waiting for services to be healthy..."
    
    local max_attempts=60
    local attempt=0
    
    cd "${SERVICES_DIR}"
    
    while [[ ${attempt} -lt ${max_attempts} ]]; do
        local healthy_count=$(docker compose ps --format json | jq -r '.Health' | grep -c "healthy" || true)
        local total_services=$(docker compose ps --format json | wc -l)
        
        log_info "Healthy services: ${healthy_count}/${total_services}"
        
        if [[ ${healthy_count} -eq ${total_services} ]]; then
            log "✓ All services are healthy"
            return 0
        fi
        
        sleep 5
        ((attempt++))
    done
    
    log_warn "Timeout waiting for services to be healthy"
    log_info "Checking service status..."
    docker compose ps
}

show_service_urls() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}Services Ready!${NC}                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Frontend:${NC}              http://localhost:3000                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}User Service:${NC}          http://localhost:8081                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Auth Service:${NC}          http://localhost:8082                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Notification Service:${NC}  http://localhost:8083                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Analytics Service:${NC}     http://localhost:8084                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}MailHog UI:${NC}            http://localhost:8025                        ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}PostgreSQL:${NC}            localhost:5432                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Database: ${GREEN}devsecops${NC}                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Username: ${GREEN}postgres${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Password: ${GREEN}postgres123${NC}                                            ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Redis:${NC}                 localhost:6379                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   Password: ${GREEN}redis123${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_useful_commands() {
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo ""
    echo "  View logs (all):        docker compose -f ${COMPOSE_FILE} logs -f"
    echo "  View logs (service):    docker compose -f ${COMPOSE_FILE} logs -f <service>"
    echo "  Check status:           docker compose -f ${COMPOSE_FILE} ps"
    echo "  Stop services:          ./stop-local.sh"
    echo "  Run tests:              ./02-run-tests.sh"
    echo "  Check health:           ./health-check.sh"
    echo ""
}

# Main execution
main() {
    print_banner
    check_prerequisites
    check_ports
    start_services
    wait_for_services
    show_service_urls
    show_useful_commands
    
    log "✅ Local development environment is ready!"
}

# Trap errors
trap 'log_error "Failed to start local environment"; exit 1' ERR

# Run main
main "$@"
