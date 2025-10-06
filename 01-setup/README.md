# Step 1: Tool Installation Guide

## 📋 Overview

This directory contains scripts to install all required tools for the DevSecOps platform. Every tool is explained with its purpose and usage.

## 🛠️ Tools to Install

### Core Development Tools
- **Docker**: Container runtime for building and running services
- **Docker Compose**: Multi-container orchestration for local development  
- **Git**: Version control system
- **kubectl**: Kubernetes command-line tool
- **Helm**: Kubernetes package manager

### Cloud & Infrastructure Tools
- **AWS CLI**: Command-line interface for AWS services
- **eksctl**: CLI for creating/managing EKS clusters
- **Terraform**: Infrastructure as Code tool for provisioning AWS resources
- **Ansible**: Configuration management and automation

### Security Tools
- **Trivy**: Vulnerability scanner for containers and filesystems
- **Syft**: Software Bill of Materials (SBOM) generator
- **Cosign**: Container image signing and verification
- **Grype**: Vulnerability scanner for container images

### CI/CD Tools
- **ArgoCD CLI**: GitOps continuous delivery tool
- **GitHub CLI**: Command-line tool for GitHub operations

## 📝 Installation Steps

### Step 1: Run the Installation Script

```bash
# Make script executable
chmod +x install-tools.sh

# Run installation (requires sudo)
./install-tools.sh

# Installation takes 10-15 minutes
```

### Step 2: Verify Installation

```bash
# Make verification script executable
chmod +x verify-installation.sh

# Run verification
./verify-installation.sh
```

### Step 3: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Enter your credentials:
# AWS Access Key ID: [Your access key]
# AWS Secret Access Key: [Your secret key]
# Default region name: us-west-2
# Default output format: json
```

### Step 4: Configure Docker (Optional)

```bash
# Add user to docker group (to run docker without sudo)
sudo usermod -aG docker $USER

# Log out and log back in for changes to take effect
# Or run: newgrp docker
```

## ✅ Expected Output

After successful installation, you should see:

```
✅ Docker installed: Docker version 24.0.5
✅ Docker Compose installed: v2.20.0
✅ Git installed: git version 2.34.1
✅ kubectl installed: v1.28.2
✅ Helm installed: v3.12.3
✅ AWS CLI installed: aws-cli/2.13.0
✅ eksctl installed: 0.157.0
✅ Terraform installed: v1.5.7
✅ Ansible installed: 2.15.3
✅ Trivy installed: 0.45.0
✅ Syft installed: 0.90.0
✅ Cosign installed: v2.2.0
✅ Grype installed: 0.68.0
✅ ArgoCD CLI installed: v2.8.3
✅ GitHub CLI installed: gh version 2.32.1

🎉 All tools successfully installed!
```

## 🔧 Troubleshooting

### Docker Installation Issues

```bash
# If Docker fails to start
sudo systemctl start docker
sudo systemctl enable docker

# Check Docker status
sudo systemctl status docker
```

### Permission Denied Errors

```bash
# Fix permission issues
sudo chmod +x install-tools.sh verify-installation.sh
```

### AWS CLI Configuration

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Should return your AWS account info
```

## 📚 Next Steps

After successful installation, proceed to:
1. `02-services/` - Start building microservices
2. `09-scripts/local-dev/` - Set up local development environment
3. `03-infrastructure/` - Deploy AWS infrastructure

## 🆘 Support

If you encounter issues:
1. Check the tool's official documentation
2. Verify system requirements (Ubuntu 20.04+, 8GB RAM, 50GB disk)
3. Ensure you have sudo privileges
4. Check internet connectivity for package downloads
