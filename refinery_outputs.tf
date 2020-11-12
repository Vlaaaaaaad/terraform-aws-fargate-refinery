output "refinery_url" {
  description = "The URL to use for Refinery"
  value       = local.refinery_url
}

output "refinery_execution_role_arn" {
  description = "The IAM Role used to create the Refinery tasks"
  value       = aws_ecs_task_definition.refinery.execution_role_arn
}

output "refinery_task_role_arn" {
  description = "The Atlantis ECS task role name"
  value       = aws_ecs_task_definition.refinery.task_role_arn
}

output "refinery_ecs_task_definition" {
  description = "The task definition for the Refinery ECS service"
  value       = aws_ecs_service.refinery.task_definition
}

output "refinery_ecs_security_group" {
  description = "The ID of the Security group assigned to the Refinery ECS Service"
  value       = aws_security_group.refinery.id
}
