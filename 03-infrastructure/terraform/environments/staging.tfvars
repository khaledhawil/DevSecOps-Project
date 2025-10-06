# Staging Environment Variables
aws_region  = "us-east-1"
environment = "staging"
owner       = "devops-team"

# VPC Configuration
vpc_cidr               = "10.1.0.0/16"
availability_zones     = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs    = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs   = ["10.1.11.0/24", "10.1.12.0/24", "10.1.13.0/24"]
database_subnet_cidrs  = ["10.1.21.0/24", "10.1.22.0/24", "10.1.23.0/24"]
enable_vpc_flow_logs   = true

# EKS Configuration
eks_cluster_version    = "1.28"
eks_node_instance_types = ["t3.large"]
eks_node_disk_size     = 100
eks_node_desired_size  = 3
eks_node_min_size      = 2
eks_node_max_size      = 6

# RDS Configuration
rds_engine_version          = "15.4"
rds_instance_class          = "db.t3.medium"
rds_allocated_storage       = 100
rds_max_allocated_storage   = 200
rds_multi_az                = true
rds_backup_retention_period = 7
rds_database_name           = "devsecops_staging"
rds_master_username         = "dbadmin"

# ElastiCache Configuration
redis_engine_version = "7.0"
redis_node_type      = "cache.t3.medium"
redis_num_nodes      = 2

# Monitoring Configuration
cloudwatch_log_retention = 14
alarm_email              = "devops-team@example.com"

# Security Configuration
allowed_cidr_blocks = ["10.0.0.0/8"]

# Tags
additional_tags = {
  CostCenter = "staging"
  Terraform  = "true"
}
