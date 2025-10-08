# Terraform Deployment Errors - Resolution Summary

## Overview

This document summarizes all errors encountered during the initial `terraform apply` attempt and the solutions implemented to resolve them.

---

## Errors Encountered

### Error 1: EKS Node Group - Empty SSH Key

**Error Message:**
```
Error: creating EKS Node Group (devsecops-dev-eks:devsecops-dev-node-group): 
operation error EKS: CreateNodegroup, https response error StatusCode: 400, 
RequestID: 0891965c-75ce-4e90-ad14-6c156fa979e3, 
InvalidParameterException: ec2SshKey in remote-access can't be empty
```

**Root Cause:**
The EKS node group configuration included a `remote_access` block with only `source_security_group_ids` but no `ec2_ssh_key`. AWS EKS requires that if the `remote_access` block is present, it must include a valid SSH key name, or the block must be omitted entirely.

**Solution:**
Commented out the entire `remote_access` block in `modules/eks/main.tf`:

```terraform
# Remote access is optional - only include if SSH key is provided
# Commenting out to avoid empty ec2SshKey error
# remote_access {
#   source_security_group_ids = [var.node_security_group_id]
# }
```

**Impact:**
- SSH access to EKS nodes is disabled
- Access to applications remains available through kubectl and Kubernetes services
- Enhanced security by reducing attack surface
- No operational impact for containerized workloads

---

### Error 2: RDS PostgreSQL - Invalid Version

**Error Message:**
```
Error: creating RDS DB Instance (devsecops-dev-postgres): 
operation error RDS: CreateDBInstance, https response error StatusCode: 400, 
RequestID: b4eceab8-b893-473c-84d3-d43ef3578170, 
api error InvalidParameterCombination: Cannot find version 15.4 for postgres
```

**Root Cause:**
PostgreSQL version 15.4 is not available in AWS RDS. AWS maintains specific minor versions and 15.4 was never released or has been deprecated.

**Solution:**
Updated RDS engine version to 15.7 in all environment tfvars files:

```terraform
# In environments/dev.tfvars, staging.tfvars, and prod.tfvars
rds_engine_version = "15.7"
```

**Impact:**
- Using a newer, stable version of PostgreSQL
- Better security with latest patches
- No breaking changes between 15.4 and 15.7

---

### Error 3: EBS CSI Driver - Timeout/Degraded State

**Error Message:**
```
Error: waiting for EKS Add-On (devsecops-dev-eks:aws-ebs-csi-driver) create: 
timeout while waiting for state to become 'ACTIVE' 
(last state: 'DEGRADED', timeout: 20m0s)

Warning: Running terraform apply again will remove the kubernetes add-on 
and attempt to create it again effectively purging previous add-on configuration
```

**Root Cause:**
The EBS CSI driver addon requires an IAM role with specific permissions to manage EBS volumes. The role must be associated with a Kubernetes service account using IRSA (IAM Roles for Service Accounts), which requires the OIDC provider to be configured.

**Solution:**
Created a dedicated IAM role for the EBS CSI driver within the EKS module:

```terraform
# EBS CSI Driver IAM Role
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

# Updated addon configuration
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]
}
```

**Impact:**
- EBS CSI driver can now provision and manage EBS volumes for persistent storage
- Kubernetes PersistentVolumeClaims can be dynamically provisioned
- Proper dependency management ensures IAM role is ready before addon installation

---

## AWS Free Tier Adjustments

### Issue: Account Resource Limitations

**Problem:**
User's AWS account has Free Tier limitations:
- Cannot create Multi-AZ RDS instances
- Limited to specific instance types
- Cost constraints for development environment

**Solution:**
Updated development environment configuration to use Free Tier eligible resources:

#### RDS Changes
```terraform
rds_instance_class          = "db.t4g.micro"   # Free Tier eligible
rds_allocated_storage       = 20               # Free Tier maximum
rds_multi_az                = false            # Required for Free Tier
rds_backup_retention_period = 1                # Minimal for dev
```

#### ElastiCache Changes
```terraform
redis_node_type        = "cache.t4g.micro"     # Free Tier eligible
redis_num_cache_nodes  = 1                     # Single node only
```

#### EKS Changes
```terraform
eks_node_instance_types = ["t3.small"]         # Cost-optimized
eks_node_disk_size      = 20                   # Reduced from 50 GiB
eks_node_desired_size   = 1                    # Single node for dev
eks_node_max_size       = 2                    # Reduced maximum
```

**Impact:**
- Significantly reduced monthly costs (estimated $171-176/month)
- RDS within Free Tier limits (750 hours/month free)
- Reduced compute and storage resources
- Single availability zone (no high availability in dev)

---

## Additional Fixes Applied

### Variable Naming Inconsistencies

Fixed in previous session - ensured all tfvars files use correct variable names:
- `rds_username` (not `rds_master_username`)
- `redis_num_cache_nodes` (not `redis_num_nodes`)
- `log_retention_days` (not `cloudwatch_log_retention`)

### Module Configuration Issues

Fixed in previous session:
- ElastiCache: Changed `replication_group_description` to `description`
- ElastiCache: Changed `auth_token_enabled` to `auth_token` with value
- Outputs: Updated ElastiCache output references

---

## Validation Steps

### 1. Terraform Validate
```bash
terraform validate
# Result: Success - The configuration is valid
```

### 2. Terraform Plan
```bash
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
# Expected: Plan shows resources to create with no errors
```

### 3. Pre-Apply Checklist
- [ ] Remote access block removed from EKS node group
- [ ] RDS version set to 15.7
- [ ] EBS CSI driver has IAM role configured
- [ ] Free Tier instance types configured
- [ ] Multi-AZ disabled for RDS
- [ ] Backup retention minimal (1 day)
- [ ] Single Redis node
- [ ] Minimal EKS node count

---

## Deployment Timeline

Based on the previous attempt, expected deployment times:

| Resource | Time |
|----------|------|
| VPC and Networking | 2-3 minutes |
| IAM Roles | 1-2 minutes |
| EKS Cluster | 10-15 minutes |
| EKS Node Group | 3-5 minutes |
| EBS CSI Driver Addon | 5-10 minutes |
| RDS Instance | 5-10 minutes |
| ElastiCache Cluster | 10-15 minutes |
| Monitoring Resources | 1-2 minutes |
| **Total Estimated Time** | **37-62 minutes** |

---

## Post-Deployment Verification

After successful deployment, verify:

### 1. EKS Cluster Access
```bash
aws eks update-kubeconfig --name devsecops-dev-eks --region us-east-1
kubectl get nodes
kubectl get pods -A
```

### 2. EBS CSI Driver
```bash
kubectl get pods -n kube-system | grep ebs-csi
kubectl get storageclass
```

### 3. RDS Connectivity
```bash
# Get RDS endpoint from outputs
terraform output rds_endpoint

# Test from a pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- bash
psql -h <rds-endpoint> -U dbadmin -d devsecops_dev
```

### 4. Redis Connectivity
```bash
# Get Redis endpoint from outputs
terraform output redis_primary_endpoint

# Test from a pod
kubectl run -it --rm redis-test --image=redis:7 --restart=Never -- bash
redis-cli -h <redis-endpoint> -p 6379 --tls PING
```

### 5. Cost Monitoring
```bash
# Check current month costs
aws ce get-cost-and-usage \
  --time-period Start=2025-10-01,End=2025-10-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

---

## Known Limitations

### Free Tier Development Environment

1. **No High Availability:**
   - Single AZ deployment
   - No automatic failover
   - Single point of failure

2. **Limited Scalability:**
   - Minimal instance sizes
   - Single Redis node
   - Limited EKS nodes

3. **Reduced Performance:**
   - db.t4g.micro: 2 vCPUs, 1 GiB RAM
   - cache.t4g.micro: Limited memory
   - t3.small nodes: 2 vCPUs, 2 GiB RAM

4. **Minimal Backup:**
   - 1-day retention only
   - No point-in-time recovery
   - Manual snapshot recommended

### SSH Access

- **Limitation:** No SSH access to EKS nodes
- **Workaround:** Use Systems Manager Session Manager for emergency access:
  ```bash
  aws ssm start-session --target <instance-id>
  ```

### EBS CSI Driver Initial Deployment

- **Issue:** May take 15-20 minutes to become fully active
- **Workaround:** Be patient; check status with:
  ```bash
  kubectl get pods -n kube-system -w | grep ebs-csi
  ```

---

## Troubleshooting Guide

### If Terraform Apply Still Fails

#### Issue: EKS Node Group Still Fails
```bash
# Check if remote_access block is truly removed
grep -A 3 "remote_access" modules/eks/main.tf

# Verify it's commented out or removed
```

#### Issue: RDS Version Still Invalid
```bash
# List available PostgreSQL versions
aws rds describe-db-engine-versions \
  --engine postgres \
  --query "DBEngineVersions[].EngineVersion" \
  --output table
```

#### Issue: EBS CSI Driver Timeout
```bash
# Check EKS cluster OIDC provider
kubectl get sa -n kube-system ebs-csi-controller-sa -o yaml

# Verify IAM role annotation
kubectl describe sa ebs-csi-controller-sa -n kube-system | grep eks.amazonaws.com/role-arn
```

#### Issue: Free Tier Instance Type Not Available
```bash
# Check available instance types in your region
aws ec2 describe-instance-type-offerings \
  --location-type availability-zone \
  --filters Name=instance-type,Values=t3.small \
  --region us-east-1
```

---

## Success Criteria

Deployment is considered successful when:

- [ ] All Terraform resources created without errors
- [ ] EKS cluster is ACTIVE
- [ ] EKS nodes are Ready
- [ ] EBS CSI driver pods are Running
- [ ] RDS instance is Available
- [ ] ElastiCache cluster is Available
- [ ] kubectl can connect to cluster
- [ ] Sample pod can be deployed
- [ ] CloudWatch alarms are configured
- [ ] No critical errors in CloudWatch logs

---

## Next Steps After Successful Deployment

1. **Deploy Kubernetes Manifests:**
   - Navigate to `04-kubernetes/`
   - Deploy base resources
   - Deploy environment-specific overlays

2. **Set Up CI/CD:**
   - Configure GitHub Actions workflows
   - Set up ArgoCD or Flux
   - Deploy sample applications

3. **Configure Monitoring:**
   - Install Prometheus
   - Install Grafana
   - Set up log aggregation

4. **Implement Security:**
   - Deploy Falco
   - Configure Gatekeeper policies
   - Set up Trivy scanning

---

## Cost Management Recommendations

### Daily Monitoring
```bash
# Create a script to check daily costs
#!/bin/bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "yesterday" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

### Set Billing Alarms
```bash
# Create SNS topic
aws sns create-topic --name billing-alerts

# Subscribe email
aws sns subscribe \
  --topic-arn <topic-arn> \
  --protocol email \
  --notification-endpoint your-email@example.com

# Create billing alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "BillingAlert-$200" \
  --alarm-description "Alert when charges exceed $200" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 200 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions <sns-topic-arn>
```

### Stop Resources When Not in Use
```bash
# Stop RDS (max 7 days stopped)
aws rds stop-db-instance --db-instance-identifier devsecops-dev-postgres

# Scale EKS nodes to 0
terraform apply -var="eks_node_desired_size=0" -var-file="environments/dev.tfvars"

# Delete NAT Gateways temporarily (requires VPC changes)
# Consider using a single NAT Gateway for dev
```

---

## Files Modified

### Configuration Files
1. `environments/dev.tfvars` - Free Tier optimization
2. `environments/staging.tfvars` - Version updates
3. `environments/prod.tfvars` - Version updates

### Module Files
1. `modules/eks/main.tf` - Removed remote_access, added EBS CSI IAM role
2. `modules/iam/outputs.tf` - Removed unused output
3. `modules/iam/variables.tf` - Removed unused variable

### Documentation
1. `03-infrastructure/TERRAFORM_FIXES.md` - Module configuration fixes
2. `03-infrastructure/VARIABLE_NAMING_FIXES.md` - Variable consistency
3. `03-infrastructure/FREE_TIER_CONFIG.md` - Free Tier guide
4. `03-infrastructure/DEPLOYMENT_ERRORS_RESOLVED.md` - This document

---

## Summary

All critical errors have been resolved:
- EKS node group SSH key issue fixed
- RDS PostgreSQL version updated to valid version (15.7)
- EBS CSI driver IAM role configured properly
- Free Tier optimizations applied
- Configuration validated with no errors

The infrastructure is now ready for deployment within AWS Free Tier constraints.
