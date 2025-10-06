# Deployment Scripts

This directory contains scripts for deploying the DevSecOps platform both locally and to AWS infrastructure.

## Directory Structure

```
08-deployment-scripts/
├── README.md                          # This file
├── local/                             # Local deployment scripts
│   ├── deploy-local.sh               # Main local deployment script
│   ├── start-services.sh             # Start all services locally
│   ├── stop-services.sh              # Stop all services
│   ├── clean-local.sh                # Clean up local environment
│   └── check-health.sh               # Health check all services
├── aws/                              # AWS infrastructure deployment
│   ├── deploy-infrastructure.sh      # Deploy AWS infrastructure
│   ├── deploy-kubernetes.sh          # Deploy to EKS
│   ├── deploy-full-stack.sh          # Complete deployment
│   ├── destroy-infrastructure.sh     # Destroy infrastructure
│   └── update-kubeconfig.sh          # Update kubectl config
└── helpers/                          # Helper utilities
    ├── check-prerequisites.sh        # Check required tools
    ├── setup-environment.sh          # Setup environment variables
    └── common-functions.sh           # Shared functions
```

## Quick Start

### Local Deployment

Deploy all services locally using Docker Compose:

```bash
./local/deploy-local.sh
```

This will:
- Check prerequisites (Docker, Docker Compose)
- Build all service images
- Start PostgreSQL, Redis, and all microservices
- Display service URLs and health status

### AWS Infrastructure Deployment

Deploy complete platform to AWS:

```bash
./aws/deploy-full-stack.sh dev
```

This will:
- Deploy AWS infrastructure (VPC, EKS, RDS, ElastiCache)
- Configure kubectl for EKS
- Deploy Kubernetes resources
- Deploy monitoring stack
- Deploy security stack
- Deploy all microservices

## Local Deployment

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 8GB RAM minimum
- 20GB disk space

### Commands

**Deploy Everything**:
```bash
cd local
./deploy-local.sh
```

**Start Services**:
```bash
./start-services.sh
```

**Stop Services**:
```bash
./stop-services.sh
```

**Health Check**:
```bash
./check-health.sh
```

**Clean Up**:
```bash
./clean-local.sh
```

### Service URLs (Local)

- **Frontend**: http://localhost:3000
- **User Service**: http://localhost:8080
- **Auth Service**: http://localhost:3001
- **Notification Service**: http://localhost:5000
- **Analytics Service**: http://localhost:8081
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

## AWS Deployment

### Prerequisites

- AWS CLI configured
- Terraform 1.6+
- kubectl 1.28+
- Helm 3.0+
- eksctl (optional)

### Environment Selection

Choose environment: `dev`, `staging`, or `prod`

```bash
export ENV=dev  # or staging, prod
```

### Deployment Steps

#### 1. Deploy Infrastructure Only

```bash
./aws/deploy-infrastructure.sh dev
```

This deploys:
- VPC with public/private subnets
- EKS cluster
- RDS PostgreSQL
- ElastiCache Redis
- IAM roles and security groups

#### 2. Deploy Kubernetes Resources

```bash
./aws/deploy-kubernetes.sh dev
```

This deploys:
- All Kubernetes manifests
- Monitoring stack
- Security stack
- All microservices

#### 3. Full Stack Deployment

```bash
./aws/deploy-full-stack.sh dev
```

This runs both infrastructure and Kubernetes deployment in sequence.

#### 4. Update kubectl Config

```bash
./aws/update-kubeconfig.sh dev
```

Updates kubectl configuration to connect to EKS cluster.

#### 5. Destroy Infrastructure

```bash
./aws/destroy-infrastructure.sh dev
```

⚠️ **Warning**: This will destroy all AWS resources in the specified environment.

## Environment Variables

### Local Environment

Create `.env.local`:

```bash
# Database
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=devsecops
POSTGRES_PASSWORD=change_me_in_production
POSTGRES_DB=devsecops

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_SECRET=your-local-secret-key
JWT_EXPIRY=1h

# Services
USER_SERVICE_URL=http://localhost:8080
AUTH_SERVICE_URL=http://localhost:3001
NOTIFICATION_SERVICE_URL=http://localhost:5000
ANALYTICS_SERVICE_URL=http://localhost:8081
```

### AWS Environment

Create `.env.dev`, `.env.staging`, `.env.prod`:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012

# EKS
EKS_CLUSTER_NAME=devsecops-dev
EKS_NODE_GROUP_SIZE=3

# RDS
RDS_INSTANCE_CLASS=db.t3.medium
RDS_ALLOCATED_STORAGE=100

# ElastiCache
ELASTICACHE_NODE_TYPE=cache.t3.micro

# Domain
DOMAIN_NAME=devsecops.example.com
CERTIFICATE_ARN=arn:aws:acm:...

# Monitoring
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
PAGERDUTY_ROUTING_KEY=...
```

## Troubleshooting

### Local Deployment Issues

**Services not starting**:
```bash
# Check Docker logs
docker-compose logs -f <service-name>

# Restart specific service
docker-compose restart <service-name>

# Rebuild and restart
docker-compose up -d --build <service-name>
```

**Port conflicts**:
```bash
# Find process using port
sudo lsof -i :8080

# Kill process
sudo kill -9 <PID>
```

**Database connection issues**:
```bash
# Access PostgreSQL
docker-compose exec postgres psql -U devsecops

# Check Redis
docker-compose exec redis redis-cli ping
```

### AWS Deployment Issues

**Terraform errors**:
```bash
# Re-initialize Terraform
cd 03-infrastructure/environments/dev
terraform init -upgrade

# Check state
terraform state list

# Force unlock if needed
terraform force-unlock <lock-id>
```

**kubectl connection issues**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --name devsecops-dev --region us-east-1

# Test connection
kubectl get nodes

# Check credentials
aws sts get-caller-identity
```

**Pod failures**:
```bash
# Check pod status
kubectl get pods -A

# View pod logs
kubectl logs -n <namespace> <pod-name>

# Describe pod
kubectl describe pod -n <namespace> <pod-name>

# Delete and recreate
kubectl delete pod -n <namespace> <pod-name>
```

## Advanced Usage

### Custom Configuration

**Override default values**:
```bash
# Local deployment with custom compose file
./local/deploy-local.sh -f docker-compose.custom.yml

# AWS deployment with custom variables
./aws/deploy-infrastructure.sh dev --var-file=custom.tfvars
```

### Selective Deployment

**Deploy specific services only**:
```bash
# Local
docker-compose up -d user-service auth-service

# Kubernetes
kubectl apply -k 04-kubernetes/overlays/dev/user-service/
```

### Scaling

**Scale services locally**:
```bash
docker-compose up -d --scale user-service=3
```

**Scale on Kubernetes**:
```bash
kubectl scale deployment user-service -n user-service --replicas=5
```

### Monitoring Deployment

**Check deployment status**:
```bash
# Local
./local/check-health.sh

# AWS
kubectl get pods -A
kubectl get svc -A
kubectl get ingress -A
```

**View logs**:
```bash
# Local
docker-compose logs -f --tail=100

# AWS
kubectl logs -f -n user-service -l app=user-service
```

## CI/CD Integration

These scripts can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions usage
- name: Deploy to Dev
  run: |
    ./08-deployment-scripts/aws/deploy-full-stack.sh dev
```

## Best Practices

1. **Always test locally first** before deploying to AWS
2. **Use environment-specific configurations** (dev/staging/prod)
3. **Run health checks** after deployment
4. **Monitor logs** during and after deployment
5. **Keep backups** of Terraform state files
6. **Use Terraform workspaces** for environment isolation
7. **Tag resources** for cost tracking and management
8. **Set up alerts** for deployment failures
9. **Document custom configurations**
10. **Test disaster recovery** procedures

## Cost Estimation

### Local Deployment
- **Cost**: Free (uses local resources)
- **Resources**: ~4GB RAM, ~10GB disk

### AWS Deployment (Dev)
- **EKS**: ~$73/month (cluster) + $30/month (nodes)
- **RDS**: ~$60/month (db.t3.medium)
- **ElastiCache**: ~$15/month (cache.t3.micro)
- **NAT Gateway**: ~$32/month
- **Total**: ~$210/month

### AWS Deployment (Production)
- **EKS**: ~$73/month (cluster) + $200/month (nodes)
- **RDS**: ~$300/month (multi-AZ, backups)
- **ElastiCache**: ~$100/month (cluster mode)
- **Load Balancers**: ~$20/month
- **Total**: ~$700-1000/month

## Security Notes

- Never commit `.env` files to version control
- Use AWS Secrets Manager or Vault for production secrets
- Rotate credentials regularly
- Enable encryption at rest and in transit
- Use IAM roles instead of access keys
- Enable CloudTrail for audit logging
- Set up AWS Config for compliance
- Use private subnets for databases
- Enable VPC Flow Logs
- Implement network policies

## Next Steps

1. Review and customize environment variables
2. Test local deployment
3. Configure AWS credentials
4. Deploy to dev environment
5. Run smoke tests
6. Set up monitoring and alerts
7. Deploy to staging
8. Perform load testing
9. Plan production deployment
10. Set up disaster recovery

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review service-specific READMEs
3. Check logs for error messages
4. Consult AWS/Kubernetes documentation
5. Open an issue in the project repository

---

**Last Updated**: October 6, 2025  
**Maintained By**: DevSecOps Team
