#!/bin/bash

# Check prerequisites for deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        local version=$($2)
        print_success "$1 ($version)"
        return 0
    else
        print_error "$1 not found"
        return 1
    fi
}

print_header "Prerequisites Check"

FAILED=0

# Docker
if ! check_command "docker" "docker --version"; then
    print_info "Install from: https://docs.docker.com/get-docker/"
    ((FAILED++))
fi

# Docker Compose
if ! check_command "docker-compose" "docker-compose --version"; then
    print_info "Install from: https://docs.docker.com/compose/install/"
    ((FAILED++))
fi

# kubectl
if ! check_command "kubectl" "kubectl version --client --short 2>/dev/null || kubectl version --client"; then
    print_info "Install from: https://kubernetes.io/docs/tasks/tools/"
    ((FAILED++))
fi

# Terraform
if ! check_command "terraform" "terraform version | head -1"; then
    print_info "Install from: https://developer.hashicorp.com/terraform/downloads"
    ((FAILED++))
fi

# AWS CLI
if ! check_command "aws" "aws --version"; then
    print_info "Install from: https://aws.amazon.com/cli/"
    ((FAILED++))
fi

# Helm
if ! check_command "helm" "helm version --short"; then
    print_info "Install from: https://helm.sh/docs/intro/install/"
    ((FAILED++))
fi

# Git
if ! check_command "git" "git --version"; then
    print_info "Install from: https://git-scm.com/downloads"
    ((FAILED++))
fi

# jq
if ! check_command "jq" "jq --version"; then
    print_info "Install from: https://stedolan.github.io/jq/download/"
    ((FAILED++))
fi

echo ""
print_header "System Resources"

# Check disk space
available_disk=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$available_disk" -ge 20 ]; then
    print_success "Disk space: ${available_disk}GB available"
else
    print_error "Disk space: ${available_disk}GB available (20GB recommended)"
    ((FAILED++))
fi

# Check memory
total_memory=$(free -g | awk 'NR==2 {print $2}')
if [ "$total_memory" -ge 8 ]; then
    print_success "Memory: ${total_memory}GB total"
else
    print_error "Memory: ${total_memory}GB total (8GB recommended)"
    ((FAILED++))
fi

echo ""
if [ $FAILED -eq 0 ]; then
    print_success "All prerequisites met! ✨"
    exit 0
else
    print_error "$FAILED prerequisite(s) missing"
    exit 1
fi
