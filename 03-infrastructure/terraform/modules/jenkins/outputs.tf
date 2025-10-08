output "jenkins_instance_id" {
  description = "Jenkins EC2 instance ID"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Jenkins EC2 public IP address"
  value       = aws_eip.jenkins.public_ip
}

output "jenkins_private_ip" {
  description = "Jenkins EC2 private IP address"
  value       = aws_instance.jenkins.private_ip
}

output "jenkins_security_group_id" {
  description = "Security group ID for Jenkins"
  value       = aws_security_group.jenkins.id
}

output "jenkins_iam_role_arn" {
  description = "IAM role ARN for Jenkins"
  value       = aws_iam_role.jenkins.arn
}

output "jenkins_url" {
  description = "Jenkins access URL"
  value       = "http://${aws_eip.jenkins.public_ip}:8080"
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins"
  value       = "ssh -i ~/.ssh/jenkins-key.pem ec2-user@${aws_eip.jenkins.public_ip}"
}

output "jenkins_log_group" {
  description = "CloudWatch log group for Jenkins"
  value       = aws_cloudwatch_log_group.jenkins.name
}

output "jenkins_private_key_path" {
  description = "Path to Jenkins SSH private key"
  value       = local_file.jenkins_private_key.filename
}

output "jenkins_public_key_path" {
  description = "Path to Jenkins SSH public key"
  value       = local_file.jenkins_public_key.filename
}

output "jenkins_private_key_pem" {
  description = "Jenkins SSH private key content (sensitive)"
  value       = tls_private_key.jenkins.private_key_pem
  sensitive   = true
}
