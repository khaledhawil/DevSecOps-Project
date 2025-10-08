output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

# EKS Outputs
output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.security.eks_cluster_security_group_id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider for EKS"
  value       = module.eks.oidc_provider_arn
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.instance_id
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.database_name
}

output "rds_username" {
  description = "RDS master username"
  value       = module.rds.username
  sensitive   = true
}

output "rds_password_secret_arn" {
  description = "ARN of Secrets Manager secret containing RDS password"
  value       = aws_secretsmanager_secret.rds_password.arn
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.port
}

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

# Security Outputs
output "eks_node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.security.eks_node_security_group_id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.security.rds_security_group_id
}

output "redis_security_group_id" {
  description = "Redis security group ID"
  value       = module.security.redis_security_group_id
}

# IAM Outputs
output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "EKS node IAM role ARN"
  value       = module.iam.eks_node_role_arn
}

# KMS Outputs
output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.main.arn
}

# Region and Environment
output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# kubectl config command
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

# Jenkins Outputs
output "jenkins_instance_id" {
  description = "Jenkins EC2 instance ID"
  value       = module.jenkins.jenkins_instance_id
}

output "jenkins_public_ip" {
  description = "Jenkins public IP address"
  value       = module.jenkins.jenkins_public_ip
}

output "jenkins_private_ip" {
  description = "Jenkins private IP address"
  value       = module.jenkins.jenkins_private_ip
}

output "jenkins_url" {
  description = "Jenkins access URL"
  value       = module.jenkins.jenkins_url
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins"
  value       = module.jenkins.jenkins_ssh_command
}

output "jenkins_private_key_path" {
  description = "Path to Jenkins SSH private key"
  value       = module.jenkins.jenkins_private_key_path
}

output "jenkins_setup_complete" {
  description = "Instructions to access Jenkins"
  value = <<-EOT
    ========================================
    Jenkins Deployment Complete!
    ========================================
    
    Jenkins URL: ${module.jenkins.jenkins_url}
    SSH Command: ${module.jenkins.jenkins_ssh_command}
    Private Key: ${module.jenkins.jenkins_private_key_path}
    
    To get initial admin password:
    ssh -i ${module.jenkins.jenkins_private_key_path} ec2-user@${module.jenkins.jenkins_public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
    
    Next steps:
    1. Wait 2-3 minutes for EC2 to fully boot
    2. Run Ansible playbook to configure Jenkins:
       cd ../ansible
       ./deploy-jenkins.sh dev
    
    Or manually configure Jenkins by accessing the URL above.
    ========================================
  EOT
}
