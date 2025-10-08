dd# Infrastructure Deployment Guide

This guide provides step-by-step instructions for deploying the DevSecOps infrastructure to AWS using Terraform.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Backend Configuration](#backend-configuration)
- [Deployment Steps](#deployment-steps)
- [Environment-Specific Deployment](#environment-specific-deployment)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## Prerequisites

Before deploying, ensure you have:

1. **AWS CLI configured** with appropriate credentials:
   ```bash
   aws configure
   # Or use environment variables:
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

2. **Terraform installed** (version >= 1.6.0):
   ```bash
   terraform --version
   ```

3. **kubectl installed** for EKS cluster access:
   ```bash
   kubectl version --client
   ```

4. **Required AWS permissions**:
   - VPC and networking (subnets, route tables, NAT gateways)
   - EKS cluster and node group creation
   - RDS instance creation
   - ElastiCache cluster creation
   - IAM roles and policies
   - KMS keys
   - Secrets Manager
   - CloudWatch logs and alarms
   - S3 (for Terraform state)
   - DynamoDB (for state locking)

## Initial Setup

1. **Navigate to the terraform directory**:
   ```bash
   cd 03-infrastructure/terraform
   ```

2. **Review the configuration**:
   - Check `variables.tf` for available configuration options
   - Review `environments/*.tfvars` for environment-specific values
   - Modify values as needed for your deployment

## Backend Configuration

Before initializing Terraform, you need to create the S3 bucket and DynamoDB table for state management:

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket devsecops-terraform-state-2001 \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket devsecops-terraform-state-2001 \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket devsecops-terraform-state-2001 \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state-2001 locking
aws dynamodb create-table \
  --table-name terraform-state-2001-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Deployment Steps

### Step 1: Initialize Terraform

Initialize Terraform to download providers and set up the backend:

```bash
terraform init
```

Expected output:
```
Initializing the backend...
Successfully configured the backend "s3"!

Initializing provider plugins...
- terraform.io/builtin/terraform
- hashicorp/aws ~> 5.0
- hashicorp/kubernetes ~> 2.23
- hashicorp/helm ~> 2.11
- hashicorp/random ~> 3.5
- hashicorp/tls

Terraform has been successfully initialized!
```

### Step 2: Validate Configuration

Validate the Terraform configuration:

```bash
terraform validate
```

### Step 3: Plan Deployment

Generate an execution plan for your desired environment:

```bash
# For development
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan

# For staging
terraform plan -var-file="environments/staging.tfvars" -out=staging.tfplan

# For production
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
```

Review the plan carefully to ensure it matches your expectations.

### Step 4: Apply Configuration

Apply the Terraform configuration:

```bash
# For development
terraform apply dev.tfplan

# For staging
terraform apply staging.tfplan

# For production
terraform apply prod.tfplan
```

**Note**: The deployment will take approximately 15-20 minutes. The EKS cluster creation is the longest operation.

## Environment-Specific Deployment

### Development Environment

Optimized for cost and quick iterations:

```bash
terraform workspace new dev
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

Characteristics:
- Smaller instance types (t3.micro, t3.medium)
- Single AZ for some resources
- Shorter backup retention (3 days)
- Fewer nodes (2 EKS nodes)

### Staging Environment

Production-like environment for testing:

```bash
terraform workspace new staging
terraform plan -var-file="environments/staging.tfvars"
terraform apply -var-file="environments/staging.tfvars"
```

Characteristics:
- Medium instance types (t3.medium, t3.large)
- Multi-AZ for critical resources
- 7-day backup retention
- 3 EKS nodes

### Production Environment

Optimized for high availability and performance:

```bash
terraform workspace new prod
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

Characteristics:
- Large instance types (t3.xlarge, r6g.large)
- Multi-AZ for all critical resources
- 30-day backup retention
- 4+ EKS nodes with auto-scaling

## Verification

After successful deployment, verify the infrastructure:

### 1. Check Terraform Outputs

```bash
terraform output
```

### 2. Configure kubectl

```bash
# Get the kubectl configuration command from outputs
aws eks update-kubeconfig --region us-east-1 --name devsecops-dev-eks

# Verify cluster access
kubectl get nodes
kubectl get pods -A
```

### 3. Verify RDS Instance

```bash
# Get RDS endpoint
terraform output rds_endpoint

# Test connection (from a pod or bastion)
psql -h <rds-endpoint> -U dbadmin -d devsecops_dev
```

### 4. Verify ElastiCache

```bash
# Get Redis endpoint
terraform output redis_endpoint

# Test connection (from a pod)
redis-cli -h <redis-endpoint> -p 6379 --tls
```

### 5. Check CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups --log-group-name-prefix /aws

# View EKS logs
aws logs tail /aws/eks/devsecops-dev-eks/cluster --follow
```

### 6. Verify Alarms

```bash
# List CloudWatch alarms
aws cloudwatch describe-alarms --alarm-name-prefix devsecops
```

## Troubleshooting

### Issue: Terraform Init Fails

**Solution**: Ensure the S3 bucket and DynamoDB table exist:
```bash
aws s3 ls s3://devsecops-terraform-state-2001
aws dynamodb describe-table --table-name terraform-state-2001-lock
```

### Issue: EKS Cluster Not Accessible

**Solution**: Update kubeconfig and check IAM permissions:
```bash
aws eks update-kubeconfig --region us-east-1 --name devsecops-dev-eks
kubectl get nodes
```

### Issue: RDS Connection Timeout

**Solution**: Check security groups and network connectivity:
```bash
# Verify security group rules
aws ec2 describe-security-groups --group-ids <rds-sg-id>

# Test from EKS pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- bash
psql -h <rds-endpoint> -U dbadmin -d devsecops_dev
```

### Issue: High Costs

**Solution**: Check for idle resources:
```bash
# Review running resources
aws eks describe-cluster --name devsecops-dev-eks
aws rds describe-db-instances
aws elasticache describe-replication-groups

# Scale down development environment when not in use
terraform plan -var-file="environments/dev.tfvars" -var="eks_node_desired_size=0"
terraform apply
```

### Issue: State Lock

**Solution**: If state-2001 is locked, check DynamoDB:
```bash
# List locks
aws dynamodb scan --table-name terraform-state-2001-lock

# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

## Cleanup

To destroy the infrastructure (be careful with production!):

### Development Environment

```bash
terraform destroy -var-file="environments/dev.tfvars"
```

### Staging Environment

```bash
terraform destroy -var-file="environments/staging.tfvars"
```

### Production Environment

**Warning**: This will delete all production data!

```bash
# First, disable deletion protection on RDS
aws rds modify-db-instance \
  --db-instance-identifier devsecops-prod-postgres \
  --no-deletion-protection

# Then destroy
terraform destroy -var-file="environments/prod.tfvars"
```

### Clean Up State Backend

After destroying all environments:

```bash
# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-state-2001-lock

# Empty and delete S3 bucket
aws s3 rm s3://devsecops-terraform-state-2001 --recursive
aws s3api delete-bucket --bucket devsecops-terraform-state-2001
```

## Cost Estimation

Approximate monthly costs by environment:

### Development
- EKS: ~$73/month (cluster) + ~$30/month (2 t3.medium nodes)
- RDS: ~$15/month (db.t3.micro)
- ElastiCache: ~$15/month (cache.t3.micro)
- Networking: ~$40/month (NAT gateways)
- **Total**: ~$173/month

### Staging
- EKS: ~$73/month (cluster) + ~$90/month (3 t3.large nodes)
- RDS: ~$60/month (db.t3.medium, Multi-AZ)
- ElastiCache: ~$60/month (cache.t3.medium, Multi-AZ)
- Networking: ~$120/month (3 NAT gateways)
- **Total**: ~$403/month

### Production
- EKS: ~$73/month (cluster) + ~$300/month (4 t3.xlarge nodes)
- RDS: ~$400/month (db.r6g.large, Multi-AZ)
- ElastiCache: ~$400/month (cache.r6g.large, Multi-AZ)
- Networking: ~$120/month (3 NAT gateways)
- **Total**: ~$1,293/month

**Note**: Actual costs may vary based on usage, data transfer, and additional AWS services.

## Next Steps

After infrastructure is deployed:

1. **Deploy Kubernetes manifests** (see `04-kubernetes/`)
2. **Set up CI/CD pipelines** (see `05-cicd/`)
3. **Configure monitoring** (see `06-monitoring/`)
4. **Implement security policies** (see `07-security/`)

## Support

For issues or questions:
- Check Terraform logs: `terraform show`
- Review AWS CloudWatch logs
- Check EKS cluster events: `kubectl get events -A`
- Review module READMEs in `modules/` directory
