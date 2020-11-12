variable "ecs_execution_role" {
  description = "The ARN of an existing IAM Role that will be used ECS to start the Tasks"
  type        = string
  default     = ""
}

variable "ecs_task_role" {
  description = "The ARN of an existin IAM Role that will be used by the Refinery Task"
  type        = string
  default     = ""
}

variable "execution_policies_arn" {
  description = "A list of ARN of the policies to attach to the execution role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
  ]
}
