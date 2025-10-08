# Infrastructure Destruction Guide

## Overview

The `destroy-infrastructure.sh` script safely destroys all AWS infrastructure resources created by Terraform.

## ⚠️ WARNING

**This action is IRREVERSIBLE!** Make sure you:
- Have backups of all important data
- Understand what will be destroyed
- Have confirmed with your team (for shared environments)
- Are destroying the correct environment

## What Gets Destroyed

### AWS Resources
- ✅ **EKS Cluster** - Kubernetes cluster and all workloads
- ✅ **RDS Database** - PostgreSQL instances (snapshot created by default)
- ✅ **ElastiCache** - Redis clusters
- ✅ **VPC** - Virtual Private Cloud and all networking components
- ✅ **Jenkins** - EC2 instance with all configurations
- ✅ **S3 Buckets** - All project buckets (can be preserved with --keep-s3)
- ✅ **IAM Roles** - All service roles and policies
- ✅ **CloudWatch** - Logs, alarms, and metrics
- ✅ **KMS Keys** - Encryption keys (30-day deletion window)
- ✅ **Secrets Manager** - All secrets (7-day recovery window)
- ✅ **Security Groups** - All firewall rules
- ✅ **Load Balancers** - Application and Network load balancers
- ✅ **Elastic IPs** - Public IP addresses
- ✅ **NAT Gateways** - NAT instances for private subnets

### Kubernetes Resources
- ✅ **Deployments** - All application deployments
- ✅ **Services** - Load balancers and service endpoints
- ✅ **ConfigMaps** - Application configurations
- ✅ **Secrets** - Kubernetes secrets
- ✅ **PersistentVolumes** - Storage volumes and claims
- ✅ **Namespaces** - Application, monitoring, security namespaces
- ✅ **Ingress** - Ingress controllers and routes
- ✅ **HPA/PDB** - Auto-scaling and pod disruption budgets

## Usage

### Basic Usage

```bash
./destroy-infrastructure.sh <environment>
```

**Examples:**
```bash
# Destroy development environment
./destroy-infrastructure.sh dev

# Destroy staging environment
./destroy-infrastructure.sh staging

# Destroy production environment (requires additional confirmation)
./destroy-infrastructure.sh prod
```

### Advanced Options

#### Dry Run (Recommended First!)
See what would be destroyed without making changes:
```bash
./destroy-infrastructure.sh dev --dry-run
```

#### Skip Database Backup
Skip creating final RDS snapshot (not recommended):
```bash
./destroy-infrastructure.sh dev --skip-backup
```

#### Keep S3 Buckets
Preserve S3 buckets and their contents:
```bash
./destroy-infrastructure.sh dev --keep-s3
```

#### Force Mode
Skip all confirmations (⚠️ DANGEROUS):
```bash
./destroy-infrastructure.sh dev --force
```

#### Combined Options
```bash
./destroy-infrastructure.sh staging --skip-backup --keep-s3
./destroy-infrastructure.sh dev --dry-run
```

## Destruction Process

### Step-by-Step Process

1. **Prerequisites Check**
   - Validates terraform, kubectl, aws CLI are installed
   - Checks environment name is valid

2. **Confirmation Prompts**
   - Displays list of resources to be destroyed
   - Requires typing environment name
   - Production requires additional "DESTROY PRODUCTION" confirmation
   - Final yes/no confirmation

3. **Database Backup**
   - Creates final RDS snapshot (unless --skip-backup)
   - Snapshot is retained for disaster recovery
   - Named: `devsecops-{env}-final-snapshot-{timestamp}`

4. **Kubernetes Cleanup**
   - Deletes application resources in namespace
   - Removes monitoring namespace
   - Removes security namespaces (Falco, Vault)
   - Removes GitOps namespaces (ArgoCD, Flux)
   - Deletes main namespace

5. **S3 Bucket Cleanup**
   - Empties all versions and delete markers
   - Removes all objects recursively
   - Prepares buckets for deletion (unless --keep-s3)

6. **Terraform Destruction**
   - Initializes Terraform
   - Creates destruction plan
   - Shows preview of changes
   - Applies destruction (after confirmation)

7. **Local State Cleanup**
   - Removes kubectl context
   - Cleans up kubeconfig entries

8. **Report Generation**
   - Creates detailed destruction report
   - Saves to: `destruction-report-{env}-{timestamp}.txt`
   - Displays summary

## Safety Features

### Multiple Confirmations
1. Type environment name to proceed
2. Production requires "DESTROY PRODUCTION"
3. Final yes/no confirmation before destruction
4. Terraform plan review before applying

### Automatic Backups
- RDS snapshot created by default
- Snapshot retained after destruction
- Can restore database from snapshot later

### Dry Run Mode
- See exactly what would be destroyed
- No actual changes made
- Safe way to validate

### Production Protection
- Extra confirmation required
- Must type "DESTROY PRODUCTION"
- Clear warnings displayed

## Confirmation Examples

### Development/Staging
```
⚠️  DANGER: You are about to DESTROY infrastructure!

Environment: dev
This will destroy:
  • EKS Cluster and all workloads
  • RDS Database instances
  • ElastiCache Redis clusters
  ...

Type 'dev' to confirm: dev
Final confirmation - proceed with destruction? (yes/no): yes
```

### Production
```
⚠️  DANGER: You are about to DESTROY infrastructure!

Environment: prod
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  WARNING: PRODUCTION ENVIRONMENT!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type 'prod' to confirm: prod
Type 'DESTROY PRODUCTION' to proceed: DESTROY PRODUCTION
Final confirmation - proceed with destruction? (yes/no): yes
```

## Destruction Report

After completion, a detailed report is generated:

```
DevSecOps Infrastructure Destruction Report
============================================

Environment: dev
Date: 2025-10-08 14:23:45
User: spider

Destroyed Resources:
-------------------
✓ Kubernetes resources (namespace: devsecops-dev)
✓ Monitoring namespace
✓ Security namespaces (Falco, Vault)
✓ GitOps namespaces (ArgoCD/Flux)
✓ EKS Cluster: devsecops-dev-cluster
✓ RDS Database: devsecops-dev-postgres
✓ ElastiCache Redis: devsecops-dev-redis
✓ Jenkins EC2 Instance
✓ VPC and Networking
✓ IAM Roles and Policies
✓ CloudWatch Logs and Alarms
✓ KMS Keys (scheduled for deletion)
✓ Secrets Manager Secrets (scheduled for deletion)
✓ S3 Buckets emptied and deleted

Database Snapshot: devsecops-dev-final-snapshot-20251008

Notes:
------
- KMS keys will be deleted after 30-day waiting period
- Secrets Manager secrets will be deleted after 7-day recovery window
- CloudWatch logs may have retention periods
- Database snapshot created and retained

To restore from backup (if created):
-----------------------------------
1. Deploy new infrastructure
2. Restore from snapshot
3. Update connection strings
```

## Timings

Typical destruction times:
- **Dev environment**: 10-15 minutes
- **Staging environment**: 15-20 minutes
- **Production environment**: 20-30 minutes

Factors affecting time:
- Number of Kubernetes resources
- RDS instance size
- Number of S3 objects
- EKS node count

## Cost Impact

### Immediate Savings
After destruction, you stop paying for:
- EKS cluster (~$73/month base + nodes)
- RDS instances (~$50-500/month depending on size)
- ElastiCache (~$50-200/month)
- Jenkins EC2 (~$30-100/month)
- NAT Gateways (~$32/month each)
- Data transfer charges

### Remaining Costs
Small costs for retained resources:
- RDS snapshots (~$0.095/GB/month)
- S3 buckets (if kept with --keep-s3)
- CloudWatch logs (during retention period)

**Total monthly savings**: $200-1000+ depending on configuration

## Disaster Recovery

### Restoring from Backup

If you need to restore after destruction:

1. **Deploy New Infrastructure**
   ```bash
   cd 03-infrastructure/terraform
   terraform apply -var-file="environments/dev.tfvars"
   ```

2. **Restore RDS from Snapshot**
   ```bash
   # Via AWS Console:
   RDS → Snapshots → Select snapshot → Actions → Restore

   # Via CLI:
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier devsecops-dev-postgres-restored \
     --db-snapshot-identifier devsecops-dev-final-snapshot-20251008
   ```

3. **Update Connection Strings**
   ```bash
   cd 04-kubernetes/scripts
   ./configure-rds-redis.sh dev
   ```

4. **Deploy Applications**
   ```bash
   cd 04-kubernetes/overlays/dev
   kubectl apply -k .
   ```

### Backup Retention

- **RDS Snapshots**: Retained indefinitely until manually deleted
- **S3 Buckets**: Retained if --keep-s3 flag used
- **Terraform State**: Stored in S3 backend (if configured)

## Troubleshooting

### Script Fails to Find Resources

**Problem**: Resources already deleted or never existed
```
[WARN] Database instance not found, skipping backup
[WARN] Namespace devsecops-dev does not exist
```

**Solution**: This is normal if resources were already deleted. Script will skip missing resources.

### Terraform Destruction Fails

**Problem**: Dependencies prevent destruction
```
Error: Error deleting VPC: DependencyViolation
```

**Solution**: 
1. Manually check AWS console for lingering resources
2. Delete dependent resources first
3. Run script again

### S3 Bucket Not Empty

**Problem**: Bucket has objects that can't be deleted
```
Error: The bucket you tried to delete is not empty
```

**Solution**:
```bash
# Manually empty the bucket
aws s3 rm s3://bucket-name --recursive

# Force delete all versions
aws s3api delete-objects --bucket bucket-name \
  --delete "$(aws s3api list-object-versions --bucket bucket-name \
  --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
```

### kubectl Context Not Found

**Problem**: Cluster already destroyed, kubectl can't connect
```
[WARN] kubectl not configured or cluster not accessible
```

**Solution**: This is expected. Script will skip Kubernetes cleanup and proceed with Terraform destruction.

### KMS Key In Use

**Problem**: KMS key still in use by other resources
```
Error: Cannot delete KMS key: still in use
```

**Solution**: Wait a few minutes for AWS to clean up resource dependencies, then run terraform destroy again.

## Best Practices

### Before Destruction

1. ✅ **Run dry-run first**
   ```bash
   ./destroy-infrastructure.sh dev --dry-run
   ```

2. ✅ **Export important data**
   - Database dumps
   - Configuration backups
   - S3 bucket contents
   - SSL certificates

3. ✅ **Notify team members**
   - Send advance notice
   - Schedule maintenance window
   - Document destruction plan

4. ✅ **Review Terraform state**
   ```bash
   cd 03-infrastructure/terraform
   terraform show
   ```

5. ✅ **Check for manual resources**
   - Manually created resources not in Terraform
   - Resources in other regions
   - External dependencies

### During Destruction

1. ✅ **Monitor the process**
   - Watch for errors
   - Check AWS console
   - Save destruction report

2. ✅ **Don't interrupt**
   - Let script complete
   - Interrupting can leave orphaned resources
   - If interrupted, run again to clean up

### After Destruction

1. ✅ **Verify in AWS Console**
   - Check all resources are deleted
   - Verify snapshots exist
   - Check for orphaned resources

2. ✅ **Review costs**
   - Check AWS billing dashboard
   - Verify charges stop
   - Monitor for unexpected costs

3. ✅ **Clean up local state**
   - Remove local kubeconfig entries
   - Clean up SSH keys
   - Archive terraform state

4. ✅ **Document the process**
   - Save destruction report
   - Note any issues
   - Update team wiki

## Alternative Methods

### Manual Terraform Destroy

If you prefer manual control:

```bash
cd 03-infrastructure/terraform

# Initialize
terraform init

# Create destruction plan
terraform plan -destroy -var-file="environments/dev.tfvars" -out=destroy.tfplan

# Review plan
terraform show destroy.tfplan

# Apply destruction
terraform apply destroy.tfplan
```

### AWS Console

You can also delete resources via AWS Console:
1. EKS → Delete cluster
2. RDS → Delete database (create snapshot)
3. VPC → Delete VPC (deletes subnets, routes, etc.)
4. IAM → Delete roles
5. S3 → Empty and delete buckets

**Note**: Console method is more error-prone and time-consuming.

## Common Scenarios

### Scenario 1: Temporary Cost Savings

**Goal**: Destroy dev environment over weekend to save costs

```bash
# Friday evening
./destroy-infrastructure.sh dev

# Monday morning
cd 03-infrastructure/terraform
terraform apply -var-file="environments/dev.tfvars"
```

**Savings**: ~$50-100 per weekend

### Scenario 2: Clean Slate Rebuild

**Goal**: Start fresh with new infrastructure

```bash
# Destroy old infrastructure
./destroy-infrastructure.sh dev

# Wait for completion (10-15 min)

# Deploy new infrastructure
cd 03-infrastructure/terraform
terraform apply -var-file="environments/dev.tfvars"

# Configure and deploy apps
cd ../../04-kubernetes/scripts
./configure-rds-redis.sh dev
cd ../overlays/dev
kubectl apply -k .
```

### Scenario 3: Migration to New Region

**Goal**: Move to different AWS region

```bash
# 1. Backup everything
aws rds create-db-snapshot --db-instance-identifier devsecops-dev-postgres \
  --db-snapshot-identifier migration-snapshot

aws s3 sync s3://devsecops-dev-artifacts s3://backup-bucket

# 2. Destroy old infrastructure
./destroy-infrastructure.sh dev --keep-s3

# 3. Update terraform variables with new region
vim 03-infrastructure/terraform/environments/dev.tfvars

# 4. Deploy in new region
cd 03-infrastructure/terraform
terraform apply -var-file="environments/dev.tfvars"

# 5. Restore data
# Copy snapshot to new region and restore
# Sync S3 buckets
```

## Options Reference

| Option | Description | Use Case |
|--------|-------------|----------|
| `--dry-run` | Show what would be destroyed without doing it | Testing, validation |
| `--skip-backup` | Don't create RDS snapshot | Dev environment, data not needed |
| `--keep-s3` | Preserve S3 buckets and contents | Important artifacts, logs |
| `--force` | Skip all confirmations | Automation, CI/CD pipelines |

## Environment Variables

The script supports these environment variables:

```bash
# Skip backup (alternative to --skip-backup)
export SKIP_BACKUP=true

# Force mode (alternative to --force)
export FORCE_DESTROY=true

# Keep S3 buckets (alternative to --keep-s3)
export KEEP_S3=true
```

## Related Scripts

- `05-deploy-infrastructure.sh` - Deploy infrastructure
- `clean-all.sh` - Clean local Docker resources
- `04-kubernetes/scripts/cleanup.sh` - Clean only Kubernetes resources

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review destruction report for errors
3. Check AWS CloudTrail for API errors
4. Review Terraform state for inconsistencies

## Checklist

Use this checklist before running destruction:

```
□ Backed up all important data
□ Exported database if needed
□ Saved S3 bucket contents
□ Notified team members
□ Ran dry-run to preview changes
□ Verified correct environment
□ Checked for manual resources
□ Scheduled maintenance window (if production)
□ Have access to AWS console for verification
□ Have backup of Terraform state
```

---

**Remember**: Destruction is permanent! Always run `--dry-run` first and ensure you have backups of critical data.
