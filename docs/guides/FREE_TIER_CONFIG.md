# AWS Free Tier Configuration Guide

## Overview

This document outlines the configuration adjustments made to ensure the DevSecOps infrastructure works within AWS Free Tier limitations and account resource constraints.

---

## AWS Free Tier Limitations

### General Constraints

- No Multi-AZ deployments for RDS
- Limited instance types available
- Reduced storage and compute resources
- Fewer availability zones
- Restricted backup retention periods

### Specific Service Limits

#### RDS (Relational Database Service)
- Instance Class: db.t4g.micro only (Free Tier eligible)
- vCPUs: 2
- RAM: 1 GiB
- Storage: 20 GiB maximum for Free Tier
- Multi-AZ: Not available
- Backup Retention: Minimal (1 day recommended for dev)
- Cost: 0.019 USD/hour

#### ElastiCache (Redis)
- Node Type: cache.t4g.micro (Free Tier eligible)
- Single node only (no replication)
- Limited memory capacity

#### EKS (Elastic Kubernetes Service)
- Node Instance Types: t3.small (cost-optimized)
- Minimum nodes: 1
- Reduced disk size: 20 GiB per node
- Note: EKS control plane is NOT Free Tier (approximately 0.10 USD/hour)

---

## Configuration Changes Applied

### Development Environment (environments/dev.tfvars)

#### RDS Configuration
```terraform
rds_engine_version          = "15.7"           # Latest stable PostgreSQL version
rds_instance_class          = "db.t4g.micro"   # Free Tier eligible (was db.t3.micro)
rds_allocated_storage       = 20               # Free Tier maximum
rds_max_allocated_storage   = 50               # Autoscaling limit
rds_multi_az                = false            # Required: not available in Free Tier
rds_backup_retention_period = 1                # Reduced from 3 days
rds_database_name           = "devsecops_dev"
rds_username                = "dbadmin"
```

**Changes Made:**
- Changed instance class from `db.t3.micro` to `db.t4g.micro` (Free Tier eligible)
- Reduced backup retention from 3 days to 1 day
- Confirmed Multi-AZ is disabled (required for Free Tier)
- Storage remains at 20 GiB (Free Tier limit)

#### ElastiCache Configuration
```terraform
redis_engine_version   = "7.0"
redis_node_type        = "cache.t4g.micro"     # Free Tier eligible (was cache.t3.micro)
redis_num_cache_nodes  = 1                     # Single node only
```

**Changes Made:**
- Changed node type from `cache.t3.micro` to `cache.t4g.micro` (Free Tier eligible)
- Confirmed single node configuration (no replication)

#### EKS Configuration
```terraform
eks_cluster_version     = "1.28"
eks_node_instance_types = ["t3.small"]         # Cost-optimized (was t3.medium)
eks_node_disk_size      = 20                   # Reduced from 50 GiB
eks_node_desired_size   = 1                    # Reduced from 2
eks_node_min_size       = 1
eks_node_max_size       = 2                    # Reduced from 4
```

**Changes Made:**
- Reduced node instance type from `t3.medium` to `t3.small` for cost savings
- Reduced disk size from 50 GiB to 20 GiB per node
- Reduced desired nodes from 2 to 1
- Reduced maximum nodes from 4 to 2

---

## Module-Level Fixes

### EKS Node Group (modules/eks/main.tf)

**Issue:** 
The `remote_access` block with empty `ec2SshKey` caused node group creation to fail.

**Fix:**
Commented out the `remote_access` block entirely:
```terraform
# Remote access is optional - only include if SSH key is provided
# Commenting out to avoid empty ec2_ssh_key error
# remote_access {
#   source_security_group_ids = [var.node_security_group_id]
# }
```

**Explanation:**
SSH access to EKS nodes is optional. Without an SSH key, the block must be omitted entirely. Access to applications can still be achieved through kubectl and Kubernetes services.

### RDS PostgreSQL Version

**Issue:**
PostgreSQL version 15.4 was not available in the AWS RDS service.

**Fix:**
Updated all environment files to use version 15.7:
```terraform
rds_engine_version = "15.7"
```

**Explanation:**
AWS RDS PostgreSQL supports specific minor versions. Version 15.7 is the current stable release in the 15.x series.

### EBS CSI Driver IAM Role (modules/eks/main.tf)

**Issue:**
EBS CSI driver addon was timing out due to missing IAM permissions.

**Fix:**
Created dedicated IAM role for EBS CSI driver within the EKS module:
```terraform
resource "aws_iam_role" "ebs_csi_driver" {
  name = "${var.name_prefix}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}
```

**Explanation:**
The EBS CSI driver requires specific IAM permissions to create and manage EBS volumes for Kubernetes persistent storage. The role uses OIDC-based authentication (IRSA - IAM Roles for Service Accounts).

---

## Cost Estimation for Free Tier Configuration

### Monthly Costs (Development Environment)

#### Services Within Free Tier
- RDS (db.t4g.micro, 750 hours/month free): $0/month (within free tier)
- ElastiCache (cache.t4g.micro, limited hours): ~$10-15/month
- S3 (Terraform state): ~$1/month

#### Services NOT in Free Tier
- EKS Control Plane: ~$73/month (0.10 USD/hour × 730 hours)
- EKS Worker Nodes (1× t3.small): ~$15/month
- NAT Gateway (2× required for private subnets): ~$65/month
- Elastic IPs: ~$7/month (if not attached)
- Data Transfer: Variable (watch for costs)

**Estimated Total: ~$171-176/month**

### Cost Optimization Tips

1. **Stop Resources When Not in Use:**
   ```bash
   # Scale down EKS nodes to 0
   terraform apply -var="eks_node_desired_size=0"
   
   # Stop RDS instance (via AWS Console)
   aws rds stop-db-instance --db-instance-identifier devsecops-dev-postgres
   ```

2. **Use Single NAT Gateway:**
   Modify VPC module to use only one NAT gateway (reduces cost by ~$32/month but sacrifices availability).

3. **Delete When Not Needed:**
   Use `terraform destroy` for development environment when not actively working.

4. **Monitor Costs:**
   ```bash
   # Set up AWS Budget Alerts
   aws budgets create-budget --account-id <account-id> \
     --budget file://budget.json \
     --notifications-with-subscribers file://notifications.json
   ```

---

## Staging and Production Considerations

### Staging Environment
For staging with account limitations:
- Use db.t4g.small if Multi-AZ is unavailable
- Single AZ deployment
- 2-3 EKS nodes with t3.small instances
- Estimated cost: ~$250-300/month

### Production Environment
**NOT RECOMMENDED for Free Tier accounts** due to:
- No Multi-AZ support
- No high availability
- Limited instance types
- Insufficient resources for production workloads

**Recommendations:**
1. Upgrade to a standard AWS account for production
2. Use AWS Organizations for better resource management
3. Request service limit increases
4. Consider AWS Credits for Startups program

---

## Troubleshooting Free Tier Issues

### Issue: "Cannot create Multi-AZ DB instance"

**Solution:**
Ensure `rds_multi_az = false` in all environment tfvars files.

### Issue: "Instance type not available"

**Solution:**
Use Graviton-based instances (t4g family) when possible:
- db.t4g.micro for RDS
- cache.t4g.micro for ElastiCache
- t3 family for EKS nodes (t4g not supported for EKS nodes)

### Issue: "Exceeded quota for NAT Gateways"

**Solution:**
Reduce the number of availability zones in dev environment:
```terraform
availability_zones = ["us-east-1a", "us-east-1b"]  # Instead of 3 AZs
```

### Issue: "EKS cluster too expensive"

**Solution:**
Consider alternatives:
- Use minikube or kind for local development
- Use AWS ECS Fargate (cheaper for small workloads)
- Use k3s on EC2 instances

---

## Validation Checklist

Before deploying with Free Tier configuration:

- [ ] Confirm RDS instance class is `db.t4g.micro`
- [ ] Verify `rds_multi_az = false`
- [ ] Check ElastiCache uses `cache.t4g.micro`
- [ ] Ensure single Redis node (`redis_num_cache_nodes = 1`)
- [ ] Verify EKS node count is minimal (1-2 nodes)
- [ ] Confirm backup retention is minimal (1 day)
- [ ] Review estimated monthly costs
- [ ] Set up billing alerts in AWS Console
- [ ] Test `terraform plan` completes without errors
- [ ] Remove `remote_access` block from EKS node group

---

## Next Steps

1. **Run Terraform Plan:**
   ```bash
   cd 03-infrastructure/terraform
   terraform plan -var-file="environments/dev.tfvars"
   ```

2. **Review Plan Output:**
   - Verify instance types match Free Tier eligible resources
   - Check for any Multi-AZ configurations
   - Confirm node counts are minimal

3. **Apply Configuration:**
   ```bash
   terraform apply -var-file="environments/dev.tfvars"
   ```

4. **Monitor Deployment:**
   - Watch for timeout errors
   - Check CloudWatch logs for issues
   - Verify resources are created successfully

5. **Set Up Cost Monitoring:**
   - Enable AWS Cost Explorer
   - Create billing alarms
   - Review costs daily during initial deployment

---

## Important Notes

- Free Tier has a 12-month limit from account creation
- After 12 months, costs will increase significantly
- Monitor your AWS Billing Dashboard regularly
- Consider using AWS Cost Anomaly Detection
- The EKS control plane is never free (always ~$73/month)
- Some regions have better Free Tier availability than others

---

## Support Resources

- AWS Free Tier FAQs: https://aws.amazon.com/free/
- AWS Cost Management: https://aws.amazon.com/aws-cost-management/
- EKS Pricing: https://aws.amazon.com/eks/pricing/
- RDS Pricing: https://aws.amazon.com/rds/postgresql/pricing/
- ElastiCache Pricing: https://aws.amazon.com/elasticache/pricing/
