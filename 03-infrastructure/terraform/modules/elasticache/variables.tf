variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
}

variable "num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
}

variable "subnet_ids" {
  description = "Subnet IDs for ElastiCache"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ElastiCache"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
