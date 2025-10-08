# Production Environment Variables
aws_region  = "us-east-1"
environment = "prod"
owner       = "devops-team"

# VPC Configuration
vpc_cidr               = "10.2.0.0/16"
availability_zones     = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs    = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
private_subnet_cidrs   = ["10.2.11.0/24", "10.2.12.0/24", "10.2.13.0/24"]
database_subnet_cidrs  = ["10.2.21.0/24", "10.2.22.0/24", "10.2.23.0/24"]
enable_vpc_flow_logs   = true

# EKS Configuration
eks_cluster_version    = "1.28"
eks_node_instance_types = ["t3.xlarge"]
eks_node_disk_size     = 200
eks_node_desired_size  = 4
eks_node_min_size      = 3
eks_node_max_size      = 10

# RDS Configuration
rds_engine_version          = "15.7"
rds_instance_class          = "db.r6g.large"
rds_allocated_storage       = 200
rds_max_allocated_storage   = 500
rds_multi_az                = true
rds_backup_retention_period = 30
rds_database_name           = "devsecops_prod"
rds_username                = "dbadmin"

# ElastiCache Configuration
redis_engine_version   = "7.0"
redis_node_type        = "cache.r6g.large"
redis_num_cache_nodes  = 3

# Monitoring Configuration
log_retention_days = 30
alarm_email        = "devops-alerts@example.com"

# Security Configuration
allowed_cidr_blocks = ["10.0.0.0/8"]

# Tags
additional_tags = {
  CostCenter  = "production"
  Terraform   = "true"
  Compliance  = "required"
}
