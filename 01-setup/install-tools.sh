#!/bin/bash

################################################################################
# DevSecOps Platform - Tool Installation Script
################################################################################
#
# Purpose: Installs all required tools for the DevSecOps platform
# Author: DevSecOps Team
# Date: October 2025
#
# This script installs:
#   - Docker & Docker Compose (Container runtime)
#   - Kubernetes tools (kubectl, Helm, k9s)
#   - AWS tools (AWS CLI, eksctl)
#   - Infrastructure tools (Terraform, Ansible)
#   - Security tools (Trivy, Syft, Cosign, Grype)
#   - CI/CD tools (ArgoCD CLI, GitHub CLI)
#
# Requirements:
#   - Ubuntu 20.04 or later
#   - Sudo privileges
#   - Internet connection
#   - 8GB RAM minimum
#   - 50GB disk space
#
# Usage:
#   chmod +x install-tools.sh
#   ./install-tools.sh
#
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    log_error "Please do not run this script as root"
    log_info "Run as regular user with sudo privileges"
    exit 1
fi

log_info "========================================="
log_info "DevSecOps Platform - Tool Installation"
log_info "========================================="
echo ""

################################################################################
# Step 1: Update System Packages
################################################################################

log_info "Step 1/10: Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
log_success "System packages updated"
echo ""

################################################################################
# Step 2: Install Essential Dependencies
################################################################################

log_info "Step 2/10: Installing essential dependencies..."
sudo apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    unzip \
    jq \
    tree \
    htop \
    net-tools \
    build-essential

log_success "Essential dependencies installed"
echo ""

################################################################################
# Step 3: Install Docker
################################################################################

log_info "Step 3/10: Installing Docker..."

# Remove old versions
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update -qq
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

log_success "Docker installed: $(docker --version)"
log_warning "You need to log out and log back in for docker group changes to take effect"
echo ""

################################################################################
# Step 4: Install Kubernetes Tools
################################################################################

log_info "Step 4/10: Installing Kubernetes tools..."

# Install kubectl
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k9s (optional but helpful)
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
wget -q "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
tar -xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/
rm k9s_Linux_amd64.tar.gz LICENSE README.md

log_success "kubectl installed: $(kubectl version --client --short 2>/dev/null | head -n1)"
log_success "Helm installed: $(helm version --short)"
log_success "k9s installed: $(k9s version --short)"
echo ""

################################################################################
# Step 5: Install AWS CLI and eksctl
################################################################################

log_info "Step 5/10: Installing AWS tools..."

# Install AWS CLI v2
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip

# Install eksctl
EKSCTL_VERSION=$(curl -s https://api.github.com/repos/weaveworks/eksctl/releases/latest | jq -r .tag_name)
curl -sL "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

log_success "AWS CLI installed: $(aws --version)"
log_success "eksctl installed: $(eksctl version)"
echo ""

################################################################################
# Step 6: Install Terraform
################################################################################

log_info "Step 6/10: Installing Terraform..."

# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
sudo apt-get update -qq
sudo apt-get install -y terraform

log_success "Terraform installed: $(terraform version | head -n1)"
echo ""

################################################################################
# Step 7: Install Ansible
################################################################################

log_info "Step 7/10: Installing Ansible..."

# Add Ansible PPA
sudo apt-add-repository --yes --update ppa:ansible/ansible

# Install Ansible
sudo apt-get install -y ansible

log_success "Ansible installed: $(ansible --version | head -n1)"
echo ""

################################################################################
# Step 8: Install Security Tools
################################################################################

log_info "Step 8/10: Installing security tools..."

# Install Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
    sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -qq
sudo apt-get install -y trivy

# Install Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Install Cosign
COSIGN_VERSION=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | jq -r .tag_name)
wget -q "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Install Grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

log_success "Trivy installed: $(trivy --version | head -n1)"
log_success "Syft installed: $(syft version | head -n1)"
log_success "Cosign installed: $(cosign version 2>&1 | head -n1)"
log_success "Grype installed: $(grype version | head -n1)"
echo ""

################################################################################
# Step 9: Install ArgoCD CLI
################################################################################

log_info "Step 9/10: Installing ArgoCD CLI..."

ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | jq -r .tag_name)
curl -sSL -o argocd-linux-amd64 "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

log_success "ArgoCD CLI installed: $(argocd version --client --short)"
echo ""

################################################################################
# Step 10: Install GitHub CLI
################################################################################

log_info "Step 10/10: Installing GitHub CLI..."

curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y gh

log_success "GitHub CLI installed: $(gh --version | head -n1)"
echo ""

################################################################################
# Installation Complete
################################################################################

log_success "========================================="
log_success "✅ Installation Complete!"
log_success "========================================="
echo ""
log_info "All tools have been successfully installed."
log_info "Run './verify-installation.sh' to verify all installations."
echo ""
log_warning "IMPORTANT: Log out and log back in for Docker group changes to take effect"
log_warning "Or run: newgrp docker"
echo ""
log_info "Next steps:"
log_info "1. Configure AWS: aws configure"
log_info "2. Verify tools: ./verify-installation.sh"
log_info "3. Start development: cd ../02-services"
echo ""
