variable "vpc_alb_subnets" {
  description = "If using a pre-exiting VPC, subnet IDs to be used for the ALBs"
  type        = list(string)
  default     = []
}

variable "alb_internal" {
  description = "Whether the load balancer is internal or external"
  type        = bool
  default     = false
}

variable "alb_additional_sgs" {
  description = "A list of additional Security Groups to attach to the ALB"
  type        = list(string)
  default     = []
}

variable "alb_logging_enabled" {
  description = "Whether if the ALB will log requests to S3"
  type        = bool
  default     = false
}

variable "alb_log_bucket_name" {
  description = "The name of the S3 bucket (externally created) for storing load balancer access logs. Required if `alb_logging_enabled` is true"
  type        = string
  default     = ""
}

variable "alb_log_location_prefix" {
  description = "The S3 prefix within the `log_bucket_name` under which logs are stored"
  type        = string
  default     = ""
}
