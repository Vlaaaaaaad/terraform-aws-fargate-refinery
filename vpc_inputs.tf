variable "vpc_id" {
  description = "The ID of an existing VPC where resources will be created"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC which will be created if `vpc_id` is not specified"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vpc_public_subnets" {
  description = "A list of public subnets inside the VPC"
  type        = list(string)
  default = [
    "172.16.0.0/18",
    "172.16.64.0/18",
    "172.16.128.0/18",
  ]
}
