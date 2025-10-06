# Development Environment Variables
aws_region  = "us-east-1"
environment = "dev"
owner       = "devops-team"

# VPC Configuration
vpc_cidr               = "10.0.0.0/16"
availability_zones     = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.11.0/24", "10.0.12.0/24"]
database_subnet_cidrs  = ["10.0.21.0/24", "10.0.22.0/24"]
enable_vpc_flow_logs   = true

# EKS Configuration
eks_cluster_version    = "1.28"
eks_node_instance_types = ["t3.medium"]
eks_node_disk_size     = 50
eks_node_desired_size  = 2
eks_node_min_size      = 1
eks_node_max_size      = 4

# RDS Configuration
rds_engine_version          = "15.4"
rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_max_allocated_storage   = 50
rds_multi_az                = false
rds_backup_retention_period = 3
rds_database_name           = "devsecops_dev"
rds_master_username         = "dbadmin"

# ElastiCache Configuration
redis_engine_version = "7.0"
redis_node_type      = "cache.t3.micro"
redis_num_nodes      = 1

# Monitoring Configuration
cloudwatch_log_retention = 7
alarm_email              = "devops-team@example.com"

# Security Configuration
allowed_cidr_blocks = ["0.0.0.0/0"]

# Tags
additional_tags = {
  CostCenter = "development"
  Terraform  = "true"
}
