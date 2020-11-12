variable "redis_node_type" {
  description = "The instance type used for the Redis cache cluster. See [all available values on the AWS website](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html)"
  default     = "cache.t2.micro"
}

variable "redis_port" {
  description = "The Redis port"
  default     = "6379"
}

variable "redis_version" {
  description = "The Redis version"
  default     = "5.0.6"
}

variable "redis_subnets" {
  description = "If using a pre-exiting VPC, subnet IDs to be used for Redis"
  type        = list(string)
  default     = []
}
