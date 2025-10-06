#!/bin/bash

################################################################################
# DevSecOps Project - Setup Prerequisites
################################################################################
#
# Purpose: Install and verify all required tools
#
# This script installs:
#   - Docker & Docker Compose
#   - Terraform
#   - kubectl
#   - Helm
#   - AWS CLI
#   - Trivy
#   - ArgoCD CLI
#   - Other utilities
#
# Usage: ./setup-prerequisites.sh [--check-only]
#
################################################################################

set -euo pipefail

# Configuration
CHECK_ONLY=false

# Parse arguments
for arg in "$@"; do
    if [[ "$arg" == "--check-only" ]]; then
        CHECK_ONLY=true
    fi
done

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
║            DevSecOps - Prerequisites Setup                           ║
║                                                                      ║
║              Installing required tools...                            ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

check_tool() {
    local tool=$1
    local install_func=$2
    
    if command -v "${tool}" &> /dev/null; then
        local version=$("${tool}" --version 2>&1 | head -1)
        log "✓ ${tool} is installed: ${version}"
        return 0
    else
        if [[ "${CHECK_ONLY}" == "true" ]]; then
            log_error "✗ ${tool} is not installed"
            return 1
        else
            log_warn "${tool} is not installed. Installing..."
            ${install_func}
            return $?
        fi
    fi
}

install_docker() {
    log "Installing Docker..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Remove old versions
        sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # Install dependencies
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        
        # Add Docker's official GPG key
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        
        # Set up repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Add current user to docker group
        sudo usermod -aG docker $USER
        
        log "✓ Docker installed. Please log out and log back in for group changes to take effect."
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "Please install Docker Desktop for Mac from: https://www.docker.com/products/docker-desktop"
    fi
}

install_terraform() {
    log "Installing Terraform..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt-get update && sudo apt-get install -y terraform
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
    fi
    
    log "✓ Terraform installed"
}

install_kubectl() {
    log "Installing kubectl..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install kubectl
    fi
    
    log "✓ kubectl installed"
}

install_helm() {
    log "Installing Helm..."
    
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    log "✓ Helm installed"
}

install_aws_cli() {
    log "Installing AWS CLI..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip -q awscliv2.zip
        sudo ./aws/install --update
        rm -rf aws awscliv2.zip
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install awscli
    fi
    
    log "✓ AWS CLI installed"
}

install_trivy() {
    log "Installing Trivy..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y wget apt-transport-https gnupg lsb-release
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install -y trivy
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install trivy
    fi
    
    log "✓ Trivy installed"
}

install_argocd_cli() {
    log "Installing ArgoCD CLI..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 /tmp/argocd /usr/local/bin/argocd
        rm /tmp/argocd
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install argocd
    fi
    
    log "✓ ArgoCD CLI installed"
}

install_jq() {
    log "Installing jq..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y jq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    fi
    
    log "✓ jq installed"
}

install_git() {
    log "Installing git..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y git
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install git
    fi
    
    log "✓ git installed"
}

check_system_resources() {
    log "Checking system resources..."
    
    # Check disk space
    local available_space=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    if [[ ${available_space} -lt 20 ]]; then
        log_warn "Low disk space: ${available_space}GB available. Recommend at least 20GB."
    else
        log "✓ Disk space: ${available_space}GB available"
    fi
    
    # Check memory
    local total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [[ ${total_mem} -lt 8 ]]; then
        log_warn "Low memory: ${total_mem}GB total. Recommend at least 8GB."
    else
        log "✓ Memory: ${total_mem}GB total"
    fi
}

print_summary() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                  ${GREEN}Prerequisites Summary${NC}                             ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    
    local tools=(docker terraform kubectl helm aws trivy argocd jq git)
    
    for tool in "${tools[@]}"; do
        if command -v "${tool}" &> /dev/null; then
            echo -e "${CYAN}║${NC} ${GREEN}✓${NC} ${tool}                                                          ${CYAN}║${NC}"
        else
            echo -e "${CYAN}║${NC} ${RED}✗${NC} ${tool}                                                          ${CYAN}║${NC}"
        fi
    done
    
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

main() {
    print_banner
    
    if [[ "${CHECK_ONLY}" == "true" ]]; then
        log "Checking prerequisites (no installation)..."
    else
        log "Installing prerequisites..."
    fi
    
    check_system_resources
    
    check_tool "docker" install_docker || true
    check_tool "terraform" install_terraform || true
    check_tool "kubectl" install_kubectl || true
    check_tool "helm" install_helm || true
    check_tool "aws" install_aws_cli || true
    check_tool "trivy" install_trivy || true
    check_tool "argocd" install_argocd_cli || true
    check_tool "jq" install_jq || true
    check_tool "git" install_git || true
    
    print_summary
    
    if [[ "${CHECK_ONLY}" == "true" ]]; then
        log "✅ Prerequisites check complete"
    else
        log "✅ Prerequisites installation complete"
        log ""
        log "Next steps:"
        log "  1. Configure AWS: aws configure"
        log "  2. Start local services: ./01-start-local.sh"
        log "  3. Or deploy to AWS: ./00-deploy-all.sh dev"
    fi
}

main "$@"
