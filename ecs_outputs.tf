output "ecs_cluster_id" {
  description = "The ARN of the ECS cluster hosting Refinery"
  value       = aws_ecs_cluster.cluster.arn
}
