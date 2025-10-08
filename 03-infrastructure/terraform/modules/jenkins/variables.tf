variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Jenkins will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Jenkins EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 30
}

variable "jenkins_data_volume_size" {
  description = "Size of Jenkins data volume in GB"
  type        = number
  default     = 50
}

variable "allowed_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to Jenkins"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_jenkins_cidr_blocks" {
  description = "CIDR blocks allowed to access Jenkins web interface"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "artifacts_bucket" {
  description = "S3 bucket name for build artifacts"
  type        = string
  default     = "jenkins-artifacts"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
