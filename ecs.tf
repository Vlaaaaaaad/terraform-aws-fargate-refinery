resource "aws_ecs_cluster" "cluster" {
  name = var.name

  capacity_providers = var.ecs_capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.ecs_default_capacity_provider_strategy

    content {
      capacity_provider = lookup(default_capacity_provider_strategy.value, "capacity_provider", null)
      weight            = lookup(default_capacity_provider_strategy.value, "weight", null)
      base              = lookup(default_capacity_provider_strategy.value, "base", null)
    }
  }

  dynamic "setting" {
    for_each = var.ecs_settings

    content {
      name  = lookup(setting.value, "name", null)
      value = lookup(setting.value, "value", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_ecs_task_definition" "refinery" {
  family = var.name

  execution_role_arn = var.ecs_execution_role == "" ? aws_iam_role.fargate_execution[0].arn : var.ecs_execution_role
  task_role_arn      = var.ecs_task_role == "" ? null : var.ecs_task_role

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.ecs_task_cpu
  memory = var.ecs_task_memory

  container_definitions = module.refinery.json_map_encoded_list

  tags = local.tags
}

resource "aws_ecs_service" "refinery" {
  name    = var.name
  cluster = aws_ecs_cluster.cluster.id

  launch_type     = "FARGATE"
  task_definition = "${aws_ecs_task_definition.refinery.family}:${aws_ecs_task_definition.refinery.revision}"

  desired_count                      = var.ecs_service_desired_count
  deployment_maximum_percent         = var.ecs_service_deployment_maximum_percent
  deployment_minimum_healthy_percent = var.ecs_service_deployment_minimum_healthy_percent

  network_configuration {
    assign_public_ip = var.ecs_service_assign_public_ip

    subnets = length(var.ecs_service_subnets) == 0 ? module.vpc[0].public_subnets : var.ecs_service_subnets
    security_groups = flatten([
      aws_security_group.refinery.id,
      var.ecs_service_additional_sgs
    ])
  }

  load_balancer {
    container_name   = var.name
    container_port   = 8080
    target_group_arn = element(module.alb.target_group_arns, 0)
  }

  tags = var.ecs_use_new_arn_format ? local.tags : null
}

resource "aws_cloudwatch_log_group" "refinery" {
  name              = var.name
  retention_in_days = var.ecs_cloudwatch_log_retention_in_days

  tags = local.tags
}
