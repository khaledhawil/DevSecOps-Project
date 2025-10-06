#!/bin/bash

################################################################################
# DevSecOps Platform - Installation Verification Script
################################################################################
#
# Purpose: Verifies that all required tools are properly installed
# Author: DevSecOps Team
# Date: October 2025
#
# This script checks:
#   - Tool installation and versions
#   - Command availability
#   - Minimum version requirements
#   - Configuration status
#
# Usage:
#   chmod +x verify-installation.sh
#   ./verify-installation.sh
#
################################################################################

set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Logging functions
log_header() {
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=========================================${NC}"
}

log_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}[✗]${NC} $1"
    ((FAILED++))
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
    ((WARNINGS++))
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Version comparison (returns 0 if version >= required)
version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

echo ""
log_header "DevSecOps Platform - Verification"
echo ""

################################################################################
# 1. Docker Verification
################################################################################

log_header "1. Docker"
log_check "Checking Docker installation..."

if command_exists docker; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    log_pass "Docker is installed: $DOCKER_VERSION"
    
    # Check Docker daemon
    if docker info >/dev/null 2>&1; then
        log_pass "Docker daemon is running"
    else
        log_fail "Docker daemon is not running or user lacks permissions"
        log_info "Run: sudo systemctl start docker"
        log_info "Add user to docker group: sudo usermod -aG docker \$USER"
    fi
    
    # Check Docker Compose plugin
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version --short)
        log_pass "Docker Compose plugin: $COMPOSE_VERSION"
    else
        log_fail "Docker Compose plugin not found"
    fi
else
    log_fail "Docker is not installed"
fi

echo ""

################################################################################
# 2. Kubernetes Tools
################################################################################

log_header "2. Kubernetes Tools"

# kubectl
log_check "Checking kubectl..."
if command_exists kubectl; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3)
    log_pass "kubectl is installed: $KUBECTL_VERSION"
else
    log_fail "kubectl is not installed"
fi

# Helm
log_check "Checking Helm..."
if command_exists helm; then
    HELM_VERSION=$(helm version --short | cut -d'+' -f1)
    log_pass "Helm is installed: $HELM_VERSION"
else
    log_fail "Helm is not installed"
fi

# k9s
log_check "Checking k9s..."
if command_exists k9s; then
    K9S_VERSION=$(k9s version --short 2>/dev/null | head -n1 || echo "installed")
    log_pass "k9s is installed: $K9S_VERSION"
else
    log_warn "k9s is not installed (optional)"
fi

echo ""

################################################################################
# 3. AWS Tools
################################################################################

log_header "3. AWS Tools"

# AWS CLI
log_check "Checking AWS CLI..."
if command_exists aws; then
    AWS_VERSION=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
    log_pass "AWS CLI is installed: $AWS_VERSION"
    
    # Check AWS configuration
    if aws sts get-caller-identity >/dev/null 2>&1; then
        log_pass "AWS credentials are configured"
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        AWS_REGION=$(aws configure get region || echo "not set")
        log_info "Account: $AWS_ACCOUNT, Region: $AWS_REGION"
    else
        log_warn "AWS credentials not configured"
        log_info "Run: aws configure"
    fi
else
    log_fail "AWS CLI is not installed"
fi

# eksctl
log_check "Checking eksctl..."
if command_exists eksctl; then
    EKSCTL_VERSION=$(eksctl version)
    log_pass "eksctl is installed: $EKSCTL_VERSION"
else
    log_fail "eksctl is not installed"
fi

echo ""

################################################################################
# 4. Infrastructure Tools
################################################################################

log_header "4. Infrastructure Tools"

# Terraform
log_check "Checking Terraform..."
if command_exists terraform; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_pass "Terraform is installed: $TERRAFORM_VERSION"
    
    # Check minimum version (1.0.0)
    if version_ge "$TERRAFORM_VERSION" "1.0.0"; then
        log_pass "Terraform version is compatible (>= 1.0.0)"
    else
        log_warn "Terraform version should be >= 1.0.0"
    fi
else
    log_fail "Terraform is not installed"
fi

# Ansible
log_check "Checking Ansible..."
if command_exists ansible; then
    ANSIBLE_VERSION=$(ansible --version | head -n1 | cut -d' ' -f3 | tr -d ']')
    log_pass "Ansible is installed: $ANSIBLE_VERSION"
else
    log_fail "Ansible is not installed"
fi

echo ""

################################################################################
# 5. Security Tools
################################################################################

log_header "5. Security Tools"

# Trivy
log_check "Checking Trivy..."
if command_exists trivy; then
    TRIVY_VERSION=$(trivy --version | head -n1 | cut -d' ' -f2)
    log_pass "Trivy is installed: $TRIVY_VERSION"
else
    log_fail "Trivy is not installed"
fi

# Syft
log_check "Checking Syft..."
if command_exists syft; then
    SYFT_VERSION=$(syft version | head -n1 | cut -d' ' -f3)
    log_pass "Syft is installed: $SYFT_VERSION"
else
    log_fail "Syft is not installed"
fi

# Cosign
log_check "Checking Cosign..."
if command_exists cosign; then
    COSIGN_VERSION=$(cosign version 2>&1 | head -n1 | grep -oP 'v\d+\.\d+\.\d+' || echo "installed")
    log_pass "Cosign is installed: $COSIGN_VERSION"
else
    log_fail "Cosign is not installed"
fi

# Grype
log_check "Checking Grype..."
if command_exists grype; then
    GRYPE_VERSION=$(grype version | head -n1 | cut -d' ' -f3)
    log_pass "Grype is installed: $GRYPE_VERSION"
else
    log_fail "Grype is not installed"
fi

echo ""

################################################################################
# 6. CI/CD Tools
################################################################################

log_header "6. CI/CD Tools"

# ArgoCD CLI
log_check "Checking ArgoCD CLI..."
if command_exists argocd; then
    ARGOCD_VERSION=$(argocd version --client --short 2>/dev/null | cut -d':' -f2 | tr -d ' ' || echo "installed")
    log_pass "ArgoCD CLI is installed: $ARGOCD_VERSION"
else
    log_fail "ArgoCD CLI is not installed"
fi

# GitHub CLI
log_check "Checking GitHub CLI..."
if command_exists gh; then
    GH_VERSION=$(gh --version | head -n1 | cut -d' ' -f3)
    log_pass "GitHub CLI is installed: $GH_VERSION"
    
    # Check GitHub authentication
    if gh auth status >/dev/null 2>&1; then
        log_pass "GitHub CLI is authenticated"
    else
        log_warn "GitHub CLI is not authenticated"
        log_info "Run: gh auth login"
    fi
else
    log_fail "GitHub CLI is not installed"
fi

echo ""

################################################################################
# 7. Essential Utilities
################################################################################

log_header "7. Essential Utilities"

# Git
log_check "Checking Git..."
if command_exists git; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    log_pass "Git is installed: $GIT_VERSION"
else
    log_fail "Git is not installed"
fi

# jq
log_check "Checking jq..."
if command_exists jq; then
    JQ_VERSION=$(jq --version | cut -d'-' -f2)
    log_pass "jq is installed: $JQ_VERSION"
else
    log_fail "jq is not installed"
fi

# curl
log_check "Checking curl..."
if command_exists curl; then
    CURL_VERSION=$(curl --version | head -n1 | cut -d' ' -f2)
    log_pass "curl is installed: $CURL_VERSION"
else
    log_fail "curl is not installed"
fi

# wget
log_check "Checking wget..."
if command_exists wget; then
    WGET_VERSION=$(wget --version | head -n1 | cut -d' ' -f3)
    log_pass "wget is installed: $WGET_VERSION"
else
    log_fail "wget is not installed"
fi

echo ""

################################################################################
# 8. System Requirements
################################################################################

log_header "8. System Requirements"

# RAM
log_check "Checking RAM..."
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -ge 7 ]; then
    log_pass "RAM: ${TOTAL_RAM}GB (minimum 8GB recommended)"
else
    log_warn "RAM: ${TOTAL_RAM}GB (minimum 8GB recommended for production)"
fi

# Disk Space
log_check "Checking disk space..."
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | tr -d 'G')
if [ "$AVAILABLE_SPACE" -ge 50 ]; then
    log_pass "Disk space: ${AVAILABLE_SPACE}GB available"
else
    log_warn "Disk space: ${AVAILABLE_SPACE}GB (minimum 50GB recommended)"
fi

# CPU
log_check "Checking CPU..."
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -ge 4 ]; then
    log_pass "CPU cores: $CPU_CORES"
else
    log_warn "CPU cores: $CPU_CORES (minimum 4 cores recommended)"
fi

echo ""

################################################################################
# Summary
################################################################################

log_header "Verification Summary"
echo ""
echo -e "✅ ${GREEN}Passed:${NC} $PASSED"
echo -e "⚠️  ${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "❌ ${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 All checks passed! System is ready for DevSecOps development.${NC}"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "1. Configure AWS if not done: aws configure"
        echo "2. Authenticate GitHub CLI: gh auth login"
        echo "3. Start building services: cd ../02-services"
        echo ""
        exit 0
    else
        echo -e "${YELLOW}⚠️  System is mostly ready, but some optional tools or configurations are missing.${NC}"
        echo -e "${BLUE}Review warnings above and configure as needed.${NC}"
        echo ""
        exit 0
    fi
else
    echo -e "${RED}❌ Some required tools are missing. Please install them before proceeding.${NC}"
    echo -e "${BLUE}Run ./install-tools.sh to install missing tools.${NC}"
    echo ""
    exit 1
fi
