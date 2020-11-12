variable "name" {
  description = "The name to use on all resources created (VPC, ALB, etc)"
  type        = string
  default     = "refinery"
}

variable "azs" {
  description = "A list of availability zones that you want to use from the Region"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}
