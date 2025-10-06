# Infrastructure as Code (Terraform)

This directory contains Terraform configurations for provisioning AWS infrastructure for the DevSecOps platform.

## Overview

The infrastructure is organized into reusable modules that provision and manage AWS resources including networking, compute, databases, caching, and security components.

## Architecture

```
AWS Cloud
├── VPC (10.0.0.0/16)
│   ├── Public Subnets (3 AZs)
│   ├── Private Subnets (3 AZs)
│   ├── Database Subnets (3 AZs)
│   └── Internet Gateway + NAT Gateways
│
├── EKS Cluster
│   ├── Control Plane
│   ├── Node Groups (t3.medium)
│   └── IRSA (IAM Roles for Service Accounts)
│
├── RDS PostgreSQL
│   ├── Multi-AZ Deployment
│   ├── Automated Backups
│   └── Enhanced Monitoring
│
├── ElastiCache Redis
│   ├── Cluster Mode Enabled
│   └── Automatic Failover
│
├── Security
│   ├── IAM Roles & Policies
│   ├── Security Groups
│   ├── AWS Secrets Manager
│   └── KMS Keys
│
└── Monitoring
    ├── CloudWatch Logs
    ├── CloudWatch Alarms
    └── SNS Topics
```

## Directory Structure

```
03-infrastructure/
├── terraform/
│   ├── modules/                # Reusable Terraform modules
│   │   ├── vpc/               # VPC, subnets, routing
│   │   ├── eks/               # EKS cluster
│   │   ├── rds/               # RDS PostgreSQL
│   │   ├── elasticache/       # Redis cluster
│   │   ├── iam/               # IAM roles and policies
│   │   ├── security/          # Security groups
│   │   └── monitoring/        # CloudWatch resources
│   │
│   ├── environments/           # Environment-specific configs
│   │   ├── dev/               # Development environment
│   │   ├── staging/           # Staging environment
│   │   └── prod/              # Production environment
│   │
│   ├── main.tf                # Root module
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output values
│   ├── providers.tf           # Provider configuration
│   ├── backend.tf             # Remote state backend
│   └── terraform.tfvars       # Variable values
│
└── ansible/                    # Configuration management
    ├── playbooks/             # Ansible playbooks
    ├── roles/                 # Ansible roles
    └── inventory/             # Inventory files
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.6.0
- kubectl
- helm
- eksctl (optional)

## Usage

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Plan Infrastructure Changes

```bash
terraform plan -var-file="environments/dev/terraform.tfvars"
```

### 3. Apply Infrastructure

```bash
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### 4. Configure kubectl

```bash
aws eks update-kubeconfig --name devsecops-dev-eks --region us-east-1
```

### 5. Verify Cluster Access

```bash
kubectl get nodes
kubectl get namespaces
```

## Modules

### VPC Module

Creates a VPC with public, private, and database subnets across multiple availability zones.

**Resources:**
- VPC with DNS support
- Internet Gateway
- NAT Gateways (one per AZ)
- Route Tables
- Subnets (public, private, database)

### EKS Module

Provisions an EKS cluster with managed node groups.

**Resources:**
- EKS Cluster
- EKS Node Groups
- IAM Roles for cluster and nodes
- Security Groups
- IRSA (IAM Roles for Service Accounts)

### RDS Module

Creates a highly available PostgreSQL database.

**Resources:**
- RDS PostgreSQL instance
- DB Subnet Group
- DB Parameter Group
- DB Security Group
- Enhanced Monitoring

### ElastiCache Module

Sets up a Redis cluster for caching.

**Resources:**
- ElastiCache Redis Cluster
- Subnet Group
- Parameter Group
- Security Group

## Environment Configuration

### Development
- Smaller instance types
- Single AZ for cost savings
- Minimal node counts

### Staging
- Production-like setup
- Multi-AZ for testing
- Moderate resources

### Production
- Multi-AZ high availability
- Auto-scaling enabled
- Enhanced monitoring
- Automated backups

## State Management

Terraform state is stored in S3 with DynamoDB locking:

```hcl
terraform {
  backend "s3" {
    bucket         = "devsecops-terraform-state"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Security Best Practices

- ✅ All resources in private subnets where possible
- ✅ Security groups with least privilege
- ✅ Encryption at rest and in transit
- ✅ IAM roles with minimal permissions
- ✅ Secrets stored in AWS Secrets Manager
- ✅ VPC Flow Logs enabled
- ✅ CloudTrail logging enabled

## Cost Optimization

- Use spot instances for dev/test
- Auto-scaling for dynamic workloads
- Reserved instances for production
- S3 lifecycle policies
- Delete unused resources

## Outputs

After applying, Terraform outputs important values:

```bash
terraform output -json
```

Key outputs:
- VPC ID
- EKS cluster endpoint
- RDS endpoint
- ElastiCache endpoint
- Security group IDs

## Troubleshooting

### Common Issues

1. **Insufficient IAM permissions**
   - Ensure your AWS user has admin access or specific permissions

2. **Resource limits**
   - Check AWS service quotas for your region

3. **State lock errors**
   - Use `terraform force-unlock` if needed

4. **EKS connection issues**
   - Update kubeconfig: `aws eks update-kubeconfig`

## Maintenance

### Updating Infrastructure

```bash
# Review changes
terraform plan

# Apply updates
terraform apply

# View current state
terraform show
```

### Destroying Infrastructure

```bash
# Destroy specific environment
terraform destroy -var-file="environments/dev/terraform.tfvars"

# WARNING: This will delete all resources!
```

## Monitoring

- CloudWatch dashboards for infrastructure metrics
- SNS alerts for critical events
- Cost and usage monitoring
- Resource tagging for cost allocation

## License

MIT License
