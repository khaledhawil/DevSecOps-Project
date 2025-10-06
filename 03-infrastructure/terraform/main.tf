# Local variables for resource naming
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(
    var.additional_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  name_prefix            = local.name_prefix
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  enable_flow_logs      = var.enable_vpc_flow_logs

  tags = local.common_tags
}

# Security Groups Module
module "security" {
  source = "./modules/security"

  name_prefix          = local.name_prefix
  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  allowed_cidr_blocks = var.allowed_cidr_blocks

  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  name_prefix  = local.name_prefix
  environment = var.environment

  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  name_prefix          = local.name_prefix
  cluster_version     = var.eks_cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size

  cluster_security_group_id = module.security.eks_cluster_security_group_id
  node_security_group_id    = module.security.eks_node_security_group_id

  tags = local.common_tags
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  name_prefix              = local.name_prefix
  instance_class           = var.rds_instance_class
  allocated_storage        = var.rds_allocated_storage
  engine_version           = var.rds_engine_version
  database_name            = var.rds_database_name
  username                 = var.rds_username
  multi_az                 = var.rds_multi_az
  backup_retention_period  = var.rds_backup_retention_period
  
  vpc_id                   = module.vpc.vpc_id
  database_subnet_ids      = module.vpc.database_subnet_ids
  security_group_id        = module.security.rds_security_group_id
  
  enable_enhanced_monitoring = var.enable_enhanced_monitoring
  monitoring_role_arn       = module.iam.rds_monitoring_role_arn

  tags = local.common_tags
}

# ElastiCache Module
module "elasticache" {
  source = "./modules/elasticache"

  name_prefix              = local.name_prefix
  node_type                = var.redis_node_type
  num_cache_nodes          = var.redis_num_cache_nodes
  parameter_group_family   = var.redis_parameter_group_family
  engine_version           = var.redis_engine_version
  
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  security_group_id        = module.security.redis_security_group_id

  tags = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  name_prefix           = local.name_prefix
  environment          = var.environment
  log_retention_days   = var.log_retention_days
  
  vpc_id               = module.vpc.vpc_id
  eks_cluster_name     = module.eks.cluster_name
  rds_instance_id      = module.rds.instance_id
  elasticache_cluster_id = module.elasticache.cluster_id

  tags = local.common_tags
}

# Store secrets in AWS Secrets Manager
resource "aws_secretsmanager_secret" "rds_password" {
  name_prefix             = "${local.name_prefix}-rds-password-"
  recovery_window_in_days = 7
  
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = module.rds.master_password
}

# KMS key for encryption
resource "aws_kms_key" "main" {
  description             = "${local.name_prefix} encryption key"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.main.key_id
}
