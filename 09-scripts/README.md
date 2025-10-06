# DevSecOps Project - Master Scripts Directory

This directory contains all essential scripts for managing the complete DevSecOps platform lifecycle.

## Table of Contents

- [Quick Start](#quick-start)
- [Script Categories](#script-categories)
- [Usage Examples](#usage-examples)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Script Details](#script-details)
- [Troubleshooting](#troubleshooting)
- [Success Checklist](#success-checklist)
- [Support](#support)

---

## Quick Start

### Local Development

```bash
# Start everything locally
./01-start-local.sh

# Run tests
./02-run-tests.sh

# Build all images
./03-build-images.sh

# Stop local services
./stop-local.sh
```

### Full Production Deployment

```bash
# Deploy entire project to AWS
./00-deploy-all.sh dev

# Or deploy step by step:
./04-scan-security.sh
./05-deploy-infrastructure.sh dev
./06-deploy-kubernetes.sh dev
./07-setup-gitops.sh dev
./08-setup-jenkins.sh
./09-setup-flux.sh dev

# Or choose your CI/CD method:
./deploy-with-argocd.sh dev      # ArgoCD GitOps
./deploy-with-flux.sh dev         # Flux CD
./deploy-with-github-actions.sh dev  # GitHub Actions
./deploy-with-jenkins.sh dev      # Jenkins
```

---

## Script Categories

### Core Deployment Scripts

These are the main scripts for deployment and development:

| Script | Purpose | Time |
|--------|---------|------|
| `00-deploy-all.sh` | Deploy entire project (all stages) | ~60 min |
| `01-start-local.sh` | Start local development environment | ~10 min |
| `02-run-tests.sh` | Run all tests (unit, integration, e2e) | ~5 min |
| `03-build-images.sh` | Build all Docker images | ~15 min |
| `04-scan-security.sh` | Run security scans (Trivy) | ~10 min |
| `05-deploy-infrastructure.sh` | Deploy AWS infrastructure with Terraform | ~20 min |
| `06-deploy-kubernetes.sh` | Deploy Kubernetes manifests | ~15 min |
| `07-setup-gitops.sh` | Setup ArgoCD and GitOps | ~10 min |
| `08-setup-jenkins.sh` | Setup Jenkins CI/CD server | ~12 min |
| `09-setup-flux.sh` | Setup Flux CD for GitOps | ~10 min |

### Management Scripts

These scripts help you manage and monitor your deployment:

| Script | Purpose |
|--------|---------|
| `stop-local.sh` | Stop local services |
| `clean-all.sh` | Clean up all resources |
| `health-check.sh` | Check health of all services |
| `view-logs.sh` | View logs from all services |

### Utility Scripts

Additional helper scripts:

| Script | Purpose |
|--------|---------|  
| `setup-prerequisites.sh` | Install all required tools |
| `push-images.sh` | Push images to Docker Hub |
| `run-smoke-tests.sh` | Run smoke tests post-deployment |
| `validate-project.sh` | Validate project setup |
| `help.sh` | Display quick reference guide |

### CI/CD Deployment Methods

Choose your deployment method:

| Script | Method | Use Case |
|--------|--------|----------|
| `deploy-with-argocd.sh` | ArgoCD GitOps | Web UI, visualization, RBAC |
| `deploy-with-flux.sh` | Flux CD | Automated images, CLI, lightweight |
| `deploy-with-github-actions.sh` | GitHub Actions | GitHub integration, cloud-native |
| `deploy-with-jenkins.sh` | Jenkins Pipelines | Enterprise, complex workflows |

---

## Usage Examples

### Example 1: Fresh Local Setup

```bash
# Install prerequisites
./setup-prerequisites.sh

# Start local environment
./01-start-local.sh

# Run tests to verify
./02-run-tests.sh
```

### Example 2: Build and Scan

```bash
# Build all images
./03-build-images.sh

# Run security scans
./04-scan-security.sh

# Push to registry if scans pass
./push-images.sh khaledhawil
```

### Example 3: Full AWS Deployment

```bash
# Deploy infrastructure
./05-deploy-infrastructure.sh dev

# Deploy Kubernetes resources
./06-deploy-kubernetes.sh dev

# Setup GitOps
./07-setup-gitops.sh dev

# Run smoke tests
./run-smoke-tests.sh dev
```

### Example 4: Complete Automation

```bash
# Deploy everything in one command
./00-deploy-all.sh staging

# This automatically runs:
# 1. Prerequisites check
# 2. Build images
# 3. Security scanning
# 4. Infrastructure deployment
# 5. Kubernetes deployment
# 6. GitOps setup
# 7. Monitoring and security tools
# 8. Smoke tests
```

---

## Prerequisites

### Required Tools

You need to install these tools before running the scripts:

- **Docker** 20.10+
- **Docker Compose** 2.0+
- **Terraform** 1.6+
- **kubectl** 1.28+
- **Helm** 3.0+
- **AWS CLI** 2.0+
- **Git** 2.0+
- **jq** 1.6+

### Optional Tools

- **Trivy** (security scanning)
- **k9s** (Kubernetes management)
- **kubectx/kubens** (context switching)

### Installation

```bash
# Run automated setup
./setup-prerequisites.sh

# Or check if tools are installed
./setup-prerequisites.sh --check-only
```

---

## Configuration

### Environment Variables

Create a `.env` file in the project root with these settings:

```bash
# Docker Hub / GitHub
DOCKER_USERNAME=khaledhawil
GITHUB_USERNAME=khaledhawil

# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=your-account-id

# Environment
ENVIRONMENT=dev  # dev, staging, prod

# Application Configuration
PROJECT_NAME=devsecops
DOMAIN=example.com

# Database
DB_PASSWORD=your-secure-password

# Redis
REDIS_PASSWORD=your-redis-password

# JWT Secret
JWT_SECRET=your-jwt-secret
```

### AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
export AWS_DEFAULT_REGION=us-east-1
```

---

## Script Details

### 00-deploy-all.sh

**Purpose:** Complete automated deployment of the entire platform

**What it does:**

- Validates prerequisites
- Builds all Docker images
- Runs security scans
- Pushes images to Docker Hub
- Deploys AWS infrastructure
- Deploys Kubernetes resources
- Sets up monitoring and security
- Configures GitOps
- Runs smoke tests
- Generates summary report

**Usage:**

```bash
./00-deploy-all.sh <environment>
# environment: dev, staging, prod
```

### 01-start-local.sh

**Purpose:** Start local development environment with Docker Compose

**What it does:**

- Checks prerequisites
- Validates port availability
- Starts Docker Compose services
- Initializes databases
- Waits for services to be healthy
- Displays access URLs

### 02-run-tests.sh

**Purpose:** Run comprehensive test suite

**What it does:**

- Go tests (user-service)
- Node.js tests (auth-service)
- Python tests (notification-service)
- Java tests (analytics-service)
- React tests (frontend)
- Integration tests
- Generates coverage reports

### 03-build-images.sh

**Purpose:** Build all Docker images

**What it does:**

- Builds all service images
- Tags with version (git commit hash) and latest
- Uses multi-stage builds for efficiency
- Leverages build caching
- Reports image sizes
- Provides build statistics

### 04-scan-security.sh

**Purpose:** Security scanning with Trivy

**What it does:**

- Container image scanning
- Filesystem vulnerability scanning
- Dependency vulnerability checks
- Generates JSON and HTML reports
- Reports vulnerabilities by severity
- Optional fail-on-high mode

### 05-deploy-infrastructure.sh

**Purpose:** Deploy AWS infrastructure using Terraform

**What it does:**

- Initializes Terraform
- Manages workspaces
- Validates configuration
- Generates and applies plan
- Creates VPC and networking
- Provisions EKS cluster
- Sets up RDS and ElastiCache
- Configures IAM roles
- Updates kubeconfig

### 06-deploy-kubernetes.sh

**Purpose:** Deploy applications to Kubernetes

**What it does:**

- Creates namespaces
- Manages secrets from AWS Secrets Manager
- Applies manifests with Kustomize
- Deploys all services
- Configures ingress
- Sets up autoscaling
- Waits for deployments
- Verifies pod status

### 07-setup-gitops.sh

**Purpose:** Setup ArgoCD for GitOps deployment

**What it does:**

- Installs ArgoCD
- Applies configuration
- Creates projects
- Deploys applications
- Configures repositories
- Sets up auto-sync
- Retrieves admin password
- Provides UI access instructions

---

## Troubleshooting

### Common Issues

**Permission denied:**

```bash
chmod +x *.sh
```

**Docker not running:**

```bash
sudo systemctl start docker
```

**AWS credentials not found:**

```bash
aws configure
# Or
export AWS_PROFILE=your-profile
```

**Port already in use:**

```bash
./stop-local.sh
# Or manually:
sudo lsof -i :PORT
sudo kill -9 PID
```

### Debug Mode

Enable verbose output for any script:

```bash
export DEBUG=true
./script-name.sh
```

### View Logs

All scripts log to the `logs/` directory:

```text
logs/
├── deploy-all.log
├── build-images.log
├── security-scan.log
└── ...
```

---

## Success Checklist

### After Local Deployment

Verify the following:

- [✓] All containers running
- [✓] Health checks passing
- [✓] Services accessible
- [✓] Tests passing

### After AWS Deployment

Verify the following:

- [✓] Terraform apply successful
- [✓] EKS cluster healthy
- [✓] All pods running
- [✓] Ingress configured
- [✓] Monitoring active
- [✓] Security tools deployed
- [✓] ArgoCD synced

---

## Related Documentation

- [Project README](../README.md)
- [Setup Guide](../01-setup/README.md)
- [Services Documentation](../02-services/README.md)
- [Infrastructure Guide](../03-infrastructure/README.md)
- [Kubernetes Guide](../04-kubernetes/README.md)
- [CI/CD Guide](../05-cicd/README.md)
- [Monitoring Guide](../06-monitoring/README.md)
- [Security Guide](../07-security/README.md)
- [Quick Start Guide](QUICKSTART.md)

---

## Support

For issues or questions:

1. Check troubleshooting section above
2. Review logs in `logs/` directory
3. Run health check: `./health-check.sh`
4. Run validation: `./validate-project.sh`
5. Review component README files

---

**All scripts are configured for username: khaledhawil**

**Ready to Deploy!**
