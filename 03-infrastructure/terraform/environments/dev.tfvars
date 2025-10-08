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
eks_cluster_version     = "1.28"
eks_node_instance_types = ["t3.small"]
eks_node_disk_size      = 20
eks_node_desired_size   = 1
eks_node_min_size       = 1
eks_node_max_size       = 2

# RDS Configuration
rds_engine_version          = "15.7"
rds_instance_class          = "db.t4g.micro"
rds_allocated_storage       = 20
rds_max_allocated_storage   = 50
rds_multi_az                = false
rds_backup_retention_period = 1
rds_database_name           = "devsecops_dev"
rds_username                = "dbadmin"

# ElastiCache Configuration
redis_engine_version   = "7.0"
redis_node_type        = "cache.t4g.micro"
redis_num_cache_nodes  = 1

# Monitoring Configuration
log_retention_days = 7
alarm_email        = "khaledhawil91@gmail.com"

# Security Configuration
allowed_cidr_blocks = ["0.0.0.0/0"]

# Jenkins Configuration
jenkins_instance_type            = "t3.small"  # Free tier eligible
jenkins_root_volume_size         = 20
jenkins_data_volume_size         = 30
jenkins_allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]  # Restrict this in production
jenkins_allowed_cidr_blocks      = ["0.0.0.0/0"]  # Restrict this in production
jenkins_artifacts_bucket         = "devsecops-dev-jenkins-artifacts"

# Tags
additional_tags = {
  CostCenter = "development"
  Terraform  = "true"
}
