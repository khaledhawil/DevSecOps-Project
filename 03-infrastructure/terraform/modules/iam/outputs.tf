output "eks_cluster_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_role_arn" {
  description = "EKS node IAM role ARN"
  value       = aws_iam_role.eks_nodes.arn
}

output "rds_monitoring_role_arn" {
  description = "RDS monitoring IAM role ARN"
  value       = aws_iam_role.rds_monitoring.arn
}

output "service_account_role_arns" {
  description = "Service account IAM role ARNs"
  value = {
    for service, role in aws_iam_role.service_account_role :
    service => role.arn
  }
}
