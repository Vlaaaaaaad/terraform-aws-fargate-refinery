output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = module.alb.this_lb_dns_name
}

output "alb_zone_id" {
  description = "The ID of the Route53 zone containing the ALB record"
  value       = module.alb.this_lb_zone_id
}

output "alb_sg" {
  description = "The ID of the Security Group attached to the ALB"
  value       = aws_security_group.alb.id
}
