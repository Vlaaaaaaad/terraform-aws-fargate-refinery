variable "ecs_capacity_providers" {
  description = "A list of short names or full Amazon Resource Names (ARNs) of one or more capacity providers to associate with the cluster. Valid values also include `FARGATE` and `FARGATE_SPOT`"
  type        = list(string)
  default = [
    "FARGATE_SPOT",
  ]
}

variable "ecs_default_capacity_provider_strategy" {
  description = "The capacity provider strategy to use by default for the cluster. Can be one or more. List of map with corresponding items in docs. See [Terraform Docs](https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html#default_capacity_provider_strategy)"
  type        = list(any)
  default = [
    {
      capacity_provider = "FARGATE_SPOT"
    },
  ]
}

variable "ecs_settings" {
  description = "A list of maps with cluster settings. For example, this can be used to enable CloudWatch Container Insights for a cluster. See [Terraform Docs](https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html#setting)"
  type        = list(any)
  default = [
    {
      name  = "containerInsights"
      value = "enabled"
    },
  ]
}

variable "image_repository" {
  description = "The Refinery image repository"
  default     = "public.ecr.aws/vlaaaaaaad/refinery-fargate-image"
}

variable "image_tag" {
  description = "The Refinery image tag to use"
  default     = "1.4.0"
}

variable "image_repository_credentials" {
  description = "The container repository credentials; required when using a private repo.  This map currently supports a single key; `\"credentialsParameter\"`, which should be the ARN of a Secrets Manager's secret holding the credentials"
  type        = map(string)
  default     = null
}

variable "firelens_configuration" {
  description = "The FireLens configuration for the Refinery container. This is used to specify and configure a log router for container logs. See [AWS Docs](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_FirelensConfiguration.html)"
  type = object({
    type    = string
    options = map(string)
  })
  default = null
}

variable "ecs_task_cpu" {
  description = "The number of CPU units to be used by Refinery"
  default     = 2048

}
variable "ecs_task_memory" {
  description = "The amount of memory (in MiB) to be used by Samprixy"
  default     = 4096

}
variable "ecs_container_memory_reservation" {
  description = "The amount of memory (in MiB) to reserve for Refinery"
  default     = 4096
}

variable "ecs_service_desired_count" {
  description = "The number of instances of the task definition to place and keep running"
  type        = number

  default = 2
}

variable "ecs_service_deployment_maximum_percent" {
  description = "The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment"
  type        = number
  default     = 300
}

variable "ecs_service_deployment_minimum_healthy_percent" {
  description = "The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment"
  type        = number
  default     = 100
}

variable "ecs_service_assign_public_ip" {
  description = "Whether the ECS Tasks should be assigned a public IP. Should be true, if ECS service is using public subnets. See [AWS Docs](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_cannot_pull_image.html)"
  type        = bool
  default     = true
}

variable "ecs_service_additional_sgs" {
  description = "A list of additional Security Groups to attach to the ECS Service"
  type        = list(string)
  default     = []
}

variable "ecs_service_subnets" {
  description = "If using a pre-existing VPC, subnet IDs to be used for the ECS Service"
  type        = list(string)
  default     = []
}

variable "ecs_use_new_arn_format" {
  type        = bool
  description = "Whether the AWS Account has opted in to the new longer ARN format which allows tagging ECS"
  default     = false
}

variable "ecs_cloudwatch_log_retention_in_days" {
  description = "The retention time for CloudWatch Logs"
  type        = number
  default     = 30
}
