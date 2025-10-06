# Quick Deployment Guide

## 🚀 Choose Your Deployment Method

### Option 1: Local Development (Fastest)

Deploy everything on your local machine using Docker:

```bash
# Check prerequisites
./08-deployment-scripts/helpers/check-prerequisites.sh

# Deploy locally
./08-deployment-scripts/local/deploy-local.sh

# Access services
# Frontend:     http://localhost:3000
# User API:     http://localhost:8080
# Auth API:     http://localhost:3001
# Notify API:   http://localhost:5000
# Analytics:    http://localhost:8081
# MailHog UI:   http://localhost:8025

# Check health
./08-deployment-scripts/local/check-health.sh

# Stop services
./08-deployment-scripts/local/stop-services.sh

# Clean up
./08-deployment-scripts/local/clean-local.sh
```

**Requirements:**
- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM minimum
- 20GB disk space

**Time:** ~10 minutes

---

### Option 2: AWS Full Stack (Production)

Deploy complete platform to AWS with all enterprise features:

```bash
# Check prerequisites
./08-deployment-scripts/helpers/check-prerequisites.sh

# Deploy everything (infrastructure + K8s + monitoring + security + apps)
./08-deployment-scripts/aws/deploy-full-stack.sh dev

# Or deploy step-by-step:

# 1. Deploy infrastructure only
./08-deployment-scripts/aws/deploy-infrastructure.sh dev

# 2. Update kubectl config
./08-deployment-scripts/aws/update-kubeconfig.sh dev

# 3. Deploy Kubernetes resources
kubectl apply -k 04-kubernetes/overlays/dev/

# 4. Deploy monitoring
./06-monitoring/scripts/deploy-monitoring.sh

# 5. Deploy security
./07-security/scripts/deploy-security.sh

# 6. Initialize Vault
./07-security/scripts/vault-setup.sh

# 7. Deploy applications
kubectl apply -f 05-cicd/argocd/applications/dev/
```

**Requirements:**
- AWS Account with appropriate permissions
- AWS CLI configured
- Terraform 1.6+
- kubectl 1.28+
- Helm 3.0+

**Time:** ~30-40 minutes

**Cost:** ~$210/month for dev environment

---

## 📋 Prerequisites Check

Run this first to ensure you have everything installed:

```bash
./08-deployment-scripts/helpers/check-prerequisites.sh
```

This checks for:
- Docker & Docker Compose (for local)
- AWS CLI (for AWS)
- Terraform (for infrastructure)
- kubectl (for Kubernetes)
- Helm (for Kubernetes packages)
- Git, jq (utilities)
- System resources (disk space, memory)

---

## 🎯 Quick Start by Use Case

### For Development & Testing
```bash
./08-deployment-scripts/local/deploy-local.sh
```

### For Staging Environment
```bash
./08-deployment-scripts/aws/deploy-full-stack.sh staging
```

### For Production
```bash
./08-deployment-scripts/aws/deploy-full-stack.sh prod
```

---

## 🛠️ Script Overview

### Local Deployment Scripts

| Script | Purpose | Time |
|--------|---------|------|
| `deploy-local.sh` | Deploy all services locally | ~10 min |
| `start-services.sh` | Start stopped services | ~1 min |
| `stop-services.sh` | Stop running services | ~30 sec |
| `check-health.sh` | Check service health | ~10 sec |
| `clean-local.sh` | Remove all containers/volumes | ~1 min |

### AWS Deployment Scripts

| Script | Purpose | Time |
|--------|---------|------|
| `deploy-full-stack.sh` | Deploy everything to AWS | ~30 min |
| `deploy-infrastructure.sh` | Deploy AWS infrastructure only | ~20 min |
| `update-kubeconfig.sh` | Configure kubectl for EKS | ~10 sec |
| `destroy-infrastructure.sh` | Destroy all AWS resources | ~15 min |

### Helper Scripts

| Script | Purpose |
|--------|---------|
| `check-prerequisites.sh` | Verify required tools installed |
| `common-functions.sh` | Shared utility functions |

---

## 📦 What Gets Deployed

### Local Deployment

- **Services:** All 5 microservices (Go, Node.js, Python, Java, React)
- **Database:** PostgreSQL 15.5
- **Cache:** Redis 7.2
- **Email Testing:** MailHog
- **Total Containers:** 9

### AWS Deployment

**Infrastructure (Terraform):**
- VPC with public/private subnets across 3 AZs
- EKS cluster with managed node groups
- RDS PostgreSQL (Multi-AZ in production)
- ElastiCache Redis cluster
- IAM roles and security groups
- CloudWatch logging and monitoring

**Kubernetes Resources:**
- 5 microservice deployments
- HorizontalPodAutoscalers
- PodDisruptionBudgets
- NetworkPolicies
- Ingress controllers
- ConfigMaps and Secrets

**Monitoring Stack:**
- Prometheus (metrics collection)
- Grafana (visualization)
- AlertManager (alerting)
- Fluent Bit (log aggregation)

**Security Stack:**
- Gatekeeper (policy enforcement)
- Falco (runtime security)
- Vault (secret management)
- Trivy (vulnerability scanning)
- SonarQube (code quality)

**CI/CD:**
- ArgoCD (GitOps deployment)
- GitHub Actions workflows
- Image signing with Cosign
- SBOM generation

---

## 🔍 Post-Deployment Verification

### Local Deployment

```bash
# Check health
./08-deployment-scripts/local/check-health.sh

# View logs
docker-compose -f docker-compose.local.yml logs -f

# Check specific service
curl http://localhost:8080/health
```

### AWS Deployment

```bash
# Check all pods
kubectl get pods -A

# Check services
kubectl get svc -A

# Check ingress
kubectl get ingress -A

# View application logs
kubectl logs -f -n user-service -l app=user-service

# Check ArgoCD applications
kubectl get applications -n argocd
```

---

## 🌐 Access Deployed Services

### Local

Direct access via localhost ports (see above)

### AWS

```bash
# ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080
# Get password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Grafana UI
kubectl port-forward -n monitoring svc/grafana 3000:80
# Open: http://localhost:3000
# Default: admin/admin

# Vault UI
kubectl port-forward -n vault svc/vault 8200:8200
# Open: http://localhost:8200

# SonarQube UI
kubectl port-forward -n sonarqube svc/sonarqube 9000:9000
# Open: http://localhost:9000
# Default: admin/admin
```

---

## 🔐 Security Setup

### Local

All secrets are in `.env.local` (auto-generated)

### AWS

1. **Initialize Vault:**
   ```bash
   ./07-security/scripts/vault-setup.sh
   ```

2. **Configure secrets in Vault:**
   - Database credentials
   - JWT secrets
   - API keys
   - SMTP configuration

3. **Run security scans:**
   ```bash
   ./07-security/scripts/scan-all.sh
   ```

---

## 🧹 Cleanup

### Local

```bash
# Stop services (keeps data)
./08-deployment-scripts/local/stop-services.sh

# Complete cleanup (removes data)
./08-deployment-scripts/local/clean-local.sh
```

### AWS

```bash
# Destroy all infrastructure
./08-deployment-scripts/aws/destroy-infrastructure.sh dev

# ⚠️ WARNING: This is IRREVERSIBLE!
# All data will be permanently deleted
```

---

## 🐛 Troubleshooting

### Local Issues

**Port conflicts:**
```bash
# Find what's using the port
sudo lsof -i :8080
# Kill the process
sudo kill -9 <PID>
```

**Services not starting:**
```bash
# View logs
docker-compose -f docker-compose.local.yml logs -f <service-name>

# Rebuild specific service
docker-compose -f docker-compose.local.yml up -d --build <service-name>

# Restart service
docker-compose -f docker-compose.local.yml restart <service-name>
```

**Database issues:**
```bash
# Access PostgreSQL
docker-compose -f docker-compose.local.yml exec postgres psql -U devsecops

# Check Redis
docker-compose -f docker-compose.local.yml exec redis redis-cli ping
```

### AWS Issues

**Terraform errors:**
```bash
cd 03-infrastructure/environments/dev
terraform init -upgrade
terraform state list
# Force unlock if needed
terraform force-unlock <lock-id>
```

**kubectl connection issues:**
```bash
# Update kubeconfig
./08-deployment-scripts/aws/update-kubeconfig.sh dev

# Test connection
kubectl get nodes

# Check AWS credentials
aws sts get-caller-identity
```

**Pod failures:**
```bash
# Check pod status
kubectl get pods -A

# Describe pod
kubectl describe pod -n <namespace> <pod-name>

# View logs
kubectl logs -f -n <namespace> <pod-name>

# Delete and recreate
kubectl delete pod -n <namespace> <pod-name>
```

---

## 💰 Cost Estimation

### Local Deployment
- **Cost:** FREE (uses local resources)
- **Resources:** ~4GB RAM, ~10GB disk

### AWS Dev Environment
- EKS: ~$73/month (cluster) + $30/month (t3.medium nodes)
- RDS: ~$60/month (db.t3.medium)
- ElastiCache: ~$15/month (cache.t3.micro)
- NAT Gateway: ~$32/month
- **Total: ~$210/month**

### AWS Production Environment
- EKS: ~$73/month (cluster) + $200/month (larger nodes)
- RDS: ~$300/month (multi-AZ, backups)
- ElastiCache: ~$100/month (cluster mode)
- Load Balancers: ~$20/month
- **Total: ~$700-1000/month**

---

## 📚 Additional Resources

- **Main README:** [README.md](../README.md)
- **Project Complete:** [PROJECT_COMPLETE.md](../PROJECT_COMPLETE.md)
- **Infrastructure Guide:** [03-infrastructure/README.md](../03-infrastructure/README.md)
- **Kubernetes Guide:** [04-kubernetes/README.md](../04-kubernetes/README.md)
- **Monitoring Guide:** [06-monitoring/README.md](../06-monitoring/README.md)
- **Security Guide:** [07-security/README.md](../07-security/README.md)

---

## 🎯 Next Steps

1. ✅ Choose deployment method (local or AWS)
2. ✅ Run prerequisites check
3. ✅ Deploy the platform
4. ✅ Verify all services are running
5. ✅ Configure secrets (AWS only)
6. ✅ Run security scans (AWS only)
7. ✅ Set up monitoring alerts
8. ✅ Configure DNS (AWS only)
9. ✅ Run load tests
10. ✅ Document any customizations

---

**Happy Deploying! 🚀**
