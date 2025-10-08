# Terraform Configuration Fixes

## Overview

This document details all the issues encountered during Terraform validation and the solutions implemented to resolve them. These fixes ensure that all module calls align with their respective variable definitions and AWS Terraform provider requirements.

---

## 1. RDS Module Configuration Issues

### Problem 1.1: Circular Dependency in Secrets Manager

**Error:**
```
The aws_secretsmanager_secret_version resource was trying to reference module.rds.master_password,
but the RDS module required the secret ARN as input, creating a circular dependency.
```

**Root Cause:**
The Secrets Manager secret version was attempting to store a password from the RDS module output, while the RDS module itself needed the secret ARN to retrieve the password. This created an impossible dependency loop.

**Solution:**
Created a separate `random_password` resource to generate the database password before both the secret and the RDS instance are created.

**Implementation:**
```terraform
# Generate random password for RDS
resource "random_password" "rds_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store secrets in AWS Secrets Manager
resource "aws_secretsmanager_secret" "rds_password" {
  name_prefix             = "${local.name_prefix}-rds-password-"
  recovery_window_in_days = 7
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.rds_password.result
}
```

**Explanation:**
By generating the password independently using `random_password`, we break the circular dependency. The password is generated first, stored in Secrets Manager, and then the RDS module can reference the secret ARN.

---

### Problem 1.2: Missing Required Parameters

**Errors:**
```
The argument "database_password_secret_arn" is required, but no definition was found.
The argument "database_username" is required, but no definition was found.
The argument "max_allocated_storage" is required, but no definition was found.
The argument "subnet_ids" is required, but no definition was found.
The argument "kms_key_id" is required, but no definition was found.
```

**Root Cause:**
The RDS module call in `main.tf` was missing several parameters that were defined as required in the module's `variables.tf` file.

**Solution:**
Added all required parameters to the RDS module call.

**Implementation:**
```terraform
module "rds" {
  source = "./modules/rds"

  name_prefix                  = local.name_prefix
  instance_class               = var.rds_instance_class
  allocated_storage            = var.rds_allocated_storage
  max_allocated_storage        = var.rds_max_allocated_storage
  engine_version               = var.rds_engine_version
  database_name                = var.rds_database_name
  database_username            = var.rds_username
  database_password_secret_arn = aws_secretsmanager_secret.rds_password.arn
  multi_az                     = var.rds_multi_az
  backup_retention_period      = var.rds_backup_retention_period
  
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = module.vpc.database_subnet_ids
  security_group_id            = module.security.rds_security_group_id
  kms_key_id                   = aws_kms_key.main.arn
  
  monitoring_role_arn          = module.iam.rds_monitoring_role_arn

  tags = local.common_tags
}
```

**Explanation:**
- `database_password_secret_arn`: References the Secrets Manager secret ARN where the password is stored
- `database_username`: Changed from `username` to match module's expected parameter name
- `max_allocated_storage`: Enables RDS storage autoscaling up to this limit
- `subnet_ids`: Changed from `database_subnet_ids` to match module's expected parameter name
- `kms_key_id`: References the KMS key ARN for encryption at rest

---

### Problem 1.3: Incorrect Parameter Names

**Errors:**
```
An argument named "username" is not expected here.
An argument named "database_subnet_ids" is not expected here.
```

**Root Cause:**
The parameter names used in the module call did not match the names defined in the module's variables file.

**Solution:**
Renamed parameters to match module expectations:
- `username` → `database_username`
- `database_subnet_ids` → `subnet_ids`

**Explanation:**
Terraform modules require exact parameter name matches. The module's `variables.tf` defined these parameters with specific names, and the module call must use those exact names.

---

### Problem 1.4: Unsupported Argument

**Error:**
```
An argument named "enable_enhanced_monitoring" is not expected here.
```

**Root Cause:**
The RDS module does not accept an `enable_enhanced_monitoring` parameter. Enhanced monitoring is implicitly enabled when a `monitoring_role_arn` is provided.

**Solution:**
Removed the `enable_enhanced_monitoring` parameter from the module call.

**Explanation:**
AWS RDS enhanced monitoring is controlled by the presence of a monitoring role ARN. If you provide `monitoring_role_arn`, enhanced monitoring is automatically enabled. The separate boolean parameter was redundant and not defined in the module.

---

### Problem 1.5: Missing Variable Definition

**Error:**
```
Variable 'var.rds_max_allocated_storage' referenced but not defined.
```

**Root Cause:**
The `rds_max_allocated_storage` variable was required by the RDS module but not defined in the root module's `variables.tf`.

**Solution:**
Added the variable definition:
```terraform
variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GB"
  type        = number
  default     = 200
}
```

**Explanation:**
RDS storage autoscaling allows the database to automatically increase its allocated storage when running out of space. The `max_allocated_storage` parameter sets the upper limit for this automatic scaling. Setting it to 200 GB (2x the initial 100 GB allocation) provides room for growth while preventing unlimited scaling costs.

---

## 2. EKS Module Configuration Issues

### Problem 2.1: Missing Required Parameters

**Errors:**
```
The argument "node_role_arn" is required, but no definition was found.
The argument "cluster_role_arn" is required, but no definition was found.
The argument "node_disk_size" is required, but no definition was found.
```

**Root Cause:**
The EKS module call was missing IAM role ARNs and node disk size configuration.

**Solution:**
Added the missing parameters to the EKS module call and created the corresponding variable.

**Implementation:**
```terraform
# In variables.tf
variable "eks_node_disk_size" {
  description = "Disk size in GiB for EKS nodes"
  type        = number
  default     = 50
}

# In main.tf
module "eks" {
  source = "./modules/eks"

  name_prefix          = local.name_prefix
  cluster_version      = var.eks_cluster_version
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  
  cluster_role_arn     = module.iam.eks_cluster_role_arn
  node_role_arn        = module.iam.eks_node_role_arn
  
  node_instance_types  = var.eks_node_instance_types
  node_disk_size       = var.eks_node_disk_size
  node_desired_size    = var.eks_node_desired_size
  node_min_size        = var.eks_node_min_size
  node_max_size        = var.eks_node_max_size

  cluster_security_group_id = module.security.eks_cluster_security_group_id
  node_security_group_id    = module.security.eks_node_security_group_id

  tags = local.common_tags
}
```

**Explanation:**
- `cluster_role_arn`: IAM role that grants the EKS control plane permissions to manage AWS resources
- `node_role_arn`: IAM role that grants EKS worker nodes permissions to interact with AWS services
- `node_disk_size`: Specifies the EBS volume size for each worker node (default 50 GB is suitable for most workloads)

---

## 3. ElastiCache Module Configuration Issues

### Problem 3.1: Incorrect Argument Name

**Error:**
```
An argument named "replication_group_description" is not expected here.
The argument "description" is required, but no definition was found.
```

**Root Cause:**
The AWS Terraform provider for ElastiCache replication groups uses `description` as the parameter name, not `replication_group_description`.

**Solution:**
Changed the parameter name in the ElastiCache module's `main.tf`:
```terraform
resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.name_prefix}-redis"
  description          = "Redis cluster for ${var.name_prefix}"
  # ... rest of configuration
}
```

**Explanation:**
The AWS Terraform provider documentation specifies `description` as the required parameter for describing the replication group. Using the incorrect parameter name caused validation to fail.

---

### Problem 3.2: Unsupported Authentication Parameter

**Error:**
```
An argument named "auth_token_enabled" is not expected here.
```

**Root Cause:**
The `auth_token_enabled` parameter does not exist in the AWS Terraform provider. Authentication is enabled automatically when an `auth_token` value is provided.

**Solution:**
Removed `auth_token_enabled` and provided the actual `auth_token`:
```terraform
resource "aws_elasticache_replication_group" "main" {
  # ... other configuration
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result
  # ... rest of configuration
}
```

**Explanation:**
AWS ElastiCache automatically enables authentication when it detects a non-empty `auth_token` parameter. The separate boolean flag was unnecessary and not supported by the provider.

---

## 4. Output Configuration Issues

### Problem 4.1: Mismatched Output References

**Errors:**
```
This object does not have an attribute named "endpoint".
This object does not have an attribute named "cluster_id".
```

**Root Cause:**
The root module's `outputs.tf` was referencing output attributes that did not exist in the ElastiCache module. The ElastiCache module outputs `primary_endpoint_address`, `reader_endpoint_address`, and `replication_group_id` instead.

**Solution:**
Updated the output references to match the actual module outputs:
```terraform
# ElastiCache Outputs
output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = module.elasticache.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "ElastiCache Redis reader endpoint"
  value       = module.elasticache.reader_endpoint_address
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = module.elasticache.port
}

output "redis_replication_group_id" {
  description = "ElastiCache replication group ID"
  value       = module.elasticache.replication_group_id
}
```

**Explanation:**
Redis replication groups provide two endpoints:
- `primary_endpoint_address`: Used for write operations
- `reader_endpoint_address`: Used for read operations (load balanced across read replicas)

The output names were updated to reflect these specific endpoints and to use the correct `replication_group_id` attribute.

---

## 5. Monitoring Module Configuration Issues

### Problem 5.1: Missing and Incorrect Parameters

**Errors:**
```
The argument "alarm_email" is required, but no definition was found.
An argument named "environment" is not expected here.
An argument named "vpc_id" is not expected here.
An argument named "elasticache_cluster_id" is not expected here.
```

**Root Cause:**
The monitoring module call was using incorrect parameter names and missing the required `alarm_email` parameter.

**Solution:**
Added the `alarm_email` variable and corrected parameter names:
```terraform
# In variables.tf
variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "alerts@example.com"
}

# In main.tf
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix                = local.name_prefix
  alarm_email                = var.alarm_email
  eks_cluster_name           = module.eks.cluster_name
  rds_instance_id            = module.rds.instance_id
  redis_replication_group_id = module.elasticache.replication_group_id

  tags = local.common_tags
}
```

**Explanation:**
- `alarm_email`: Required for SNS topic subscription to receive CloudWatch alarm notifications
- `redis_replication_group_id`: Changed from `elasticache_cluster_id` to match the actual resource type (replication group)
- Removed `environment` and `vpc_id` as they were not defined in the monitoring module's variables

---

## Summary of Changes

### Files Modified

1. **03-infrastructure/terraform/main.tf**
   - Added `random_password` resource for RDS
   - Fixed RDS module parameters
   - Fixed EKS module parameters
   - Fixed ElastiCache module call parameters
   - Fixed Monitoring module parameters

2. **03-infrastructure/terraform/variables.tf**
   - Added `rds_max_allocated_storage` variable
   - Added `eks_node_disk_size` variable
   - Added `alarm_email` variable

3. **03-infrastructure/terraform/modules/elasticache/main.tf**
   - Changed `replication_group_description` to `description`
   - Changed `auth_token_enabled` to `auth_token` with value

4. **03-infrastructure/terraform/outputs.tf**
   - Updated ElastiCache output references to match module outputs
   - Split single endpoint into primary and reader endpoints

### Best Practices Applied

1. **Module Interface Consistency**: Ensured all module calls use parameter names that exactly match the module's variable definitions.

2. **Dependency Management**: Broke circular dependencies by creating independent resources for shared values (like passwords).

3. **Security**: Used Secrets Manager for sensitive data (passwords) and enabled encryption at rest with KMS.

4. **Provider Compliance**: Aligned all resource configurations with AWS Terraform provider documentation requirements.

5. **Scalability**: Added autoscaling parameters (max_allocated_storage) to allow resources to grow with demand.

6. **Observability**: Properly configured monitoring module with required notification endpoints.

### Validation Result

After implementing all fixes:
```bash
terraform validate
# Success: The configuration is valid.
```

All modules now properly reference required parameters, use correct parameter names, and align with AWS Terraform provider specifications.
