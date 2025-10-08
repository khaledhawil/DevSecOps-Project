# Terraform Variable Naming Fixes

## Overview

This document details the variable naming inconsistencies found between the environment tfvars files and the root module's variable definitions, and the corrections made to resolve them.

---

## Issues Identified

During terraform plan execution, three warnings were generated indicating that values were provided for undeclared variables:

1. `redis_num_nodes` - Used in tfvars but not declared in variables.tf
2. `rds_master_username` - Used in tfvars but not declared in variables.tf
3. `cloudwatch_log_retention` - Used in tfvars but not declared in variables.tf

---

## Root Cause Analysis

### Issue 1: ElastiCache Node Count Variable Mismatch

**Problem:**
The environment tfvars files used `redis_num_nodes` to specify the number of Redis cache nodes, but the root module's variables.tf defined this parameter as `redis_num_cache_nodes`.

**Impact:**
- Terraform ignored the `redis_num_nodes` value from tfvars files
- The default value from variables.tf was used instead (2 nodes)
- Development environment intended to use 1 node for cost savings but would have deployed 2

**Variable Definition in variables.tf:**
```terraform
variable "redis_num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 2
}
```

**Incorrect Usage in tfvars:**
```terraform
redis_num_nodes = 1
```

**Correct Usage in tfvars:**
```terraform
redis_num_cache_nodes = 1
```

**Explanation:**
The ElastiCache module expects `num_cache_nodes` as a parameter, and the root module variable was correctly named `redis_num_cache_nodes` to match this. The tfvars files were using an abbreviated name that did not exist.

---

### Issue 2: RDS Username Variable Mismatch

**Problem:**
The environment tfvars files used `rds_master_username` to specify the database master username, but the root module's variables.tf defined this parameter as `rds_username`.

**Impact:**
- Terraform ignored the `rds_master_username` value from tfvars files
- The default value from variables.tf was used instead ("postgres")
- All environments would have used "postgres" as username instead of "dbadmin"

**Variable Definition in variables.tf:**
```terraform
variable "rds_username" {
  description = "Master username for RDS"
  type        = string
  default     = "postgres"
}
```

**Incorrect Usage in tfvars:**
```terraform
rds_master_username = "dbadmin"
```

**Correct Usage in tfvars:**
```terraform
rds_username = "dbadmin"
```

**Explanation:**
While AWS RDS refers to this as the "master username" in its documentation, the root module simplified the variable name to `rds_username` since the "master" designation is implicit for the initial administrative user. The tfvars files used the AWS terminology rather than the module's variable name.

---

### Issue 3: CloudWatch Log Retention Variable Mismatch

**Problem:**
The environment tfvars files used `cloudwatch_log_retention` to specify log retention days, but the root module's variables.tf defined this parameter as `log_retention_days`.

**Impact:**
- Terraform ignored the `cloudwatch_log_retention` value from tfvars files
- The default value from variables.tf was used instead (30 days)
- Development intended 7 days retention, staging 14 days, but both would use 30 days
- Increased CloudWatch Logs storage costs due to longer retention

**Variable Definition in variables.tf:**
```terraform
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}
```

**Incorrect Usage in tfvars:**
```terraform
cloudwatch_log_retention = 7
```

**Correct Usage in tfvars:**
```terraform
log_retention_days = 7
```

**Explanation:**
The variable name `log_retention_days` is more generic and can apply to any log retention configuration (VPC Flow Logs, Application Logs, etc.), not just CloudWatch. The tfvars files used a more specific name that was not defined in the module.

---

## Resolution

All three environment tfvars files were updated to use the correct variable names as defined in the root module's variables.tf:

### Development Environment (environments/dev.tfvars)

**Changes Made:**
```terraform
# Before
rds_master_username         = "dbadmin"
redis_num_nodes             = 1
cloudwatch_log_retention    = 7

# After
rds_username                = "dbadmin"
redis_num_cache_nodes       = 1
log_retention_days          = 7
```

### Staging Environment (environments/staging.tfvars)

**Changes Made:**
```terraform
# Before
rds_master_username         = "dbadmin"
redis_num_nodes             = 2
cloudwatch_log_retention    = 14

# After
rds_username                = "dbadmin"
redis_num_cache_nodes       = 2
log_retention_days          = 14
```

### Production Environment (environments/prod.tfvars)

**Changes Made:**
```terraform
# Before
rds_master_username         = "dbadmin"
redis_num_nodes             = 3
cloudwatch_log_retention    = 30

# After
rds_username                = "dbadmin"
redis_num_cache_nodes       = 3
log_retention_days          = 30
```

---

## Verification

After making the corrections, terraform plan was executed with no warnings:

```bash
terraform plan -var-file="environments/dev.tfvars" -compact-warnings
```

**Result:**
- No warnings about undeclared variables
- All variable values from tfvars files are correctly recognized
- Plan shows intended configuration for each environment

---

## Best Practices for Variable Naming

To prevent similar issues in the future, follow these guidelines:

### 1. Consistent Naming Convention

Use a consistent pattern across all variable names:
- Format: `<resource>_<attribute>` (e.g., `rds_username`, `eks_cluster_version`)
- Avoid redundant prefixes (e.g., use `username` not `master_username` when context is clear)
- Be consistent with abbreviations (e.g., always use `redis` not sometimes `elasticache`)

### 2. Variable Documentation

Document variables clearly in variables.tf:
```terraform
variable "rds_username" {
  description = "Master username for RDS database (administrative user)"
  type        = string
  default     = "postgres"
}
```

### 3. Validation Before Use

Always validate variable names before creating tfvars files:
1. Check variables.tf for exact variable names
2. Use IDE autocomplete when possible
3. Run `terraform validate` after adding new tfvars values

### 4. Module Interface Consistency

When creating modules, ensure variable names match AWS resource parameters:
```terraform
# Module variables should align with AWS resource attributes
variable "num_cache_nodes" {  # Matches aws_elasticache_replication_group.num_cache_clusters
  description = "Number of cache nodes in the replication group"
  type        = number
}
```

### 5. Environment-Specific Files Review

When copying tfvars files between environments:
1. Review all variable names against variables.tf
2. Do not assume variable names from AWS documentation
3. Test with `terraform plan` before committing

---

## Impact Analysis

### Cost Impact

**Before Fixes:**
- Development: Would have used 2 Redis nodes instead of 1 (100% cost increase for ElastiCache)
- Development: Would have retained logs for 30 days instead of 7 (4x CloudWatch Logs cost)
- Staging: Would have retained logs for 30 days instead of 14 (2x CloudWatch Logs cost)

**Estimated Monthly Savings After Fixes:**
- Development ElastiCache: ~$15/month (saved by using 1 node instead of 2)
- Development CloudWatch Logs: ~$5/month (reduced retention)
- Staging CloudWatch Logs: ~$3/month (reduced retention)
- Total: ~$23/month in unnecessary costs avoided

### Security Impact

**Database Username:**
- Before: Would have used default "postgres" username (common target for attacks)
- After: Uses "dbadmin" as intended (less predictable)
- Recommendation: Consider using unique usernames per environment for additional security

---

## Related Files Modified

1. `03-infrastructure/terraform/environments/dev.tfvars`
   - Line 28: `rds_master_username` → `rds_username`
   - Line 33: `redis_num_nodes` → `redis_num_cache_nodes`
   - Line 36: `cloudwatch_log_retention` → `log_retention_days`

2. `03-infrastructure/terraform/environments/staging.tfvars`
   - Line 28: `rds_master_username` → `rds_username`
   - Line 33: `redis_num_nodes` → `redis_num_cache_nodes`
   - Line 36: `cloudwatch_log_retention` → `log_retention_days`

3. `03-infrastructure/terraform/environments/prod.tfvars`
   - Line 28: `rds_master_username` → `rds_username`
   - Line 33: `redis_num_nodes` → `redis_num_cache_nodes`
   - Line 36: `cloudwatch_log_retention` → `log_retention_days`

---

## Testing Checklist

After applying these fixes, verify the following:

- [ ] Run `terraform validate` - No errors
- [ ] Run `terraform plan -var-file="environments/dev.tfvars"` - No warnings
- [ ] Run `terraform plan -var-file="environments/staging.tfvars"` - No warnings
- [ ] Run `terraform plan -var-file="environments/prod.tfvars"` - No warnings
- [ ] Verify ElastiCache node count in plan output matches tfvars intent
- [ ] Verify RDS username in plan output matches tfvars intent
- [ ] Verify CloudWatch log retention in plan output matches tfvars intent

---

## Summary

Variable naming consistency between the root module's variable definitions and environment-specific tfvars files is critical for correct infrastructure deployment. The mismatches identified would have resulted in:

1. Incorrect resource sizing (2 Redis nodes instead of 1 in development)
2. Excessive log retention and associated costs
3. Using default usernames instead of environment-specific ones

All issues have been resolved by standardizing on the variable names defined in the root module's variables.tf file. Future additions should reference variables.tf as the source of truth for all variable names.
