# Quick Start Guide

Get your DevSecOps platform running in minutes!

## For Local Development (10 Minutes)

### Step 1: Start Local Environment

```bash
cd 09-scripts
./01-start-local.sh
```

This will:

- Start all services with Docker Compose
- Initialize databases
- Set up networking
- Wait for services to be healthy

### Step 2: Access Services

Once started, access your services at:

**Frontend:** http://localhost:3000
**Auth Service:** http://localhost:3001
**User Service:** http://localhost:3002
**Analytics Service:** http://localhost:3003
**Notification Service:** http://localhost:3004

### Step 3: Run Tests

```bash
./02-run-tests.sh
```

This verifies all services are working correctly.

### Step 4: Stop Services

```bash
./stop-local.sh
```

---

## For AWS Deployment (45 Minutes)

### One Command Deployment

```bash
./00-deploy-all.sh dev
```

This single command will:

1. Build all Docker images
2. Run security scans
3. Push images to Docker Hub
4. Deploy AWS infrastructure
5. Deploy Kubernetes resources
6. Setup monitoring and security
7. Configure GitOps
8. Run smoke tests

### Step-by-Step Deployment

If you prefer to deploy step by step:

#### Step 1: Build Images

```bash
./03-build-images.sh
```

#### Step 2: Security Scan

```bash
./04-scan-security.sh
```

#### Step 3: Push Images

```bash
./push-images.sh khaledhawil
```

#### Step 4: Deploy Infrastructure

```bash
./05-deploy-infrastructure.sh dev
```

#### Step 5: Deploy Kubernetes

```bash
./06-deploy-kubernetes.sh dev
```

#### Step 6: Setup GitOps

```bash
./07-setup-gitops.sh dev
```

#### Step 7: Run Smoke Tests

```bash
./run-smoke-tests.sh dev
```

---

## Prerequisites

### Before You Start

**Required Tools:**

- Docker 20.10+
- Docker Compose 2.0+
- Terraform 1.6+
- kubectl 1.28+
- AWS CLI 2.0+
- Git 2.0+

**Install All Tools:**

```bash
./setup-prerequisites.sh
```

**Configure AWS:**

```bash
aws configure
```

**Configure Docker Hub:**

```bash
docker login
```

---

## Environment Variables

Create a `.env` file:

```bash
# Docker Hub / GitHub
DOCKER_USERNAME=khaledhawil
GITHUB_USERNAME=khaledhawil

# AWS
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=your-account-id

# Environment
ENVIRONMENT=dev

# Secrets
DB_PASSWORD=your-secure-password
REDIS_PASSWORD=your-redis-password
JWT_SECRET=your-jwt-secret
```

---

## Verification

### Check Local Services

```bash
./health-check.sh
```

### Check Kubernetes Services

```bash
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
kubectl get ingress --all-namespaces
```

### Check ArgoCD

```bash
kubectl get applications -n argocd
```

---

## Common Tasks

### View Logs

```bash
# Local logs
./view-logs.sh

# Kubernetes logs
kubectl logs -f deployment/service-name -n namespace
```

### Clean Up

```bash
# Stop local services
./stop-local.sh

# Clean all resources
./clean-all.sh
```

### Update Configuration

```bash
# Edit configuration
vi .env

# Restart services
./stop-local.sh
./01-start-local.sh
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
docker ps

# Check ports
sudo lsof -i :3000-3004

# View logs
./view-logs.sh
```

### Deployment Fails

```bash
# Check prerequisites
./setup-prerequisites.sh --check-only

# Validate AWS credentials
aws sts get-caller-identity

# Check Terraform state
cd ../03-infrastructure/terraform
terraform state list
```

### Need Help?

```bash
# Display help
./help.sh

# Validate project
./validate-project.sh

# Check logs
ls -la logs/
```

---

## Next Steps

After successful deployment:

1. [✓] Configure monitoring dashboards
2. [✓] Setup alerting rules
3. [✓] Configure CI/CD pipelines
4. [✓] Review security policies
5. [✓] Setup backups
6. [✓] Configure domain and SSL

---

## Useful Commands

```bash
# Check all script options
./00-deploy-all.sh --help

# Run in debug mode
export DEBUG=true
./01-start-local.sh

# Run specific tests
./02-run-tests.sh --service auth-service

# Build specific image
./03-build-images.sh --service frontend

# Scan specific image
./04-scan-security.sh --image khaledhawil/frontend
```

---

## Support Resources

- Main README: [../README.md](../README.md)
- Scripts README: [README.md](README.md)
- Scripts Summary: [SCRIPTS-SUMMARY.md](SCRIPTS-SUMMARY.md)
- Infrastructure Guide: [../03-infrastructure/README.md](../03-infrastructure/README.md)
- Kubernetes Guide: [../04-kubernetes/README.md](../04-kubernetes/README.md)

---

That's it! You're ready to deploy your DevSecOps platform.

Username configured: khaledhawil
