module "refinery" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.46.0"

  container_name         = "refinery"
  container_image        = "${var.image_repository}:${var.image_tag}"
  repository_credentials = var.image_repository_credentials

  container_cpu                = var.ecs_task_cpu
  container_memory             = var.ecs_task_memory
  container_memory_reservation = var.ecs_container_memory_reservation

  port_mappings = [
    {
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    },
    {
      containerPort = 8081
      hostPort      = 8081
      protocol      = "tcp"
    },
  ]

  log_configuration = {
    logDriver = "awslogs"

    options = {
      awslogs-region        = data.aws_region.current.name
      awslogs-group         = aws_cloudwatch_log_group.refinery.name
      awslogs-stream-prefix = "ecs"
    }
  }
  firelens_configuration = var.firelens_configuration

  environment = [
    {
      name = "SAMPROXY_REDIS_HOST"
      value = join(
        ":",
        [
          aws_elasticache_replication_group.redis.primary_endpoint_address,
          var.redis_port,
        ],
      )
    },
    {
      # Hacky hack to replace containers in case of config change
      name  = "CONFIG_FILE_SHA"
      value = sha512(local.filled_rules_file)
    },
    {
      # Hacky hack to replace containers in case of rules change
      name  = "RULES_FILE_SHA"
      value = sha512(local.filled_config_file)
    },
  ]

  secrets = [
    # Hacky hack to get the config file in the Fargate container
    #  see https://github.com/aws/containers-roadmap/issues/56
    {
      name      = "ENCODED_CONFIG"
      valueFrom = aws_ssm_parameter.config.arn
    },
    {
      name      = "ENCODED_RULES"
      valueFrom = aws_ssm_parameter.rules.arn
    },
  ]

  entrypoint = [
    "bash",
    "-c",
    "set -ueo pipefail; unset AWS_CONTAINER_CREDENTIALS_RELATIVE_URI; unset AWS_EXECUTION_ENV; mkdir /etc/refinery; echo $ENCODED_CONFIG | base64 -d > /etc/refinery/refinery.toml; echo $ENCODED_RULES | base64 -d > /etc/refinery/rules.toml; /usr/bin/refinery -c /etc/refinery/refinery.toml -r /etc/refinery/rules.toml"
  ]
}

resource "aws_security_group" "refinery" {
  vpc_id = local.vpc_id

  name        = var.name
  description = "${var.name} SG for Fargate taks"

  tags = merge(
    var.tags,
    {
      "Name" = var.name
    },
  )
}

resource "aws_security_group_rule" "refinery_alb_in" {
  security_group_id = aws_security_group.refinery.id
  description       = "Allow Refinery to receive traffic from the ALB"

  type      = "ingress"
  from_port = "8080"
  to_port   = "8080"
  protocol  = "tcp"

  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "refinery_alb_out" {
  security_group_id = aws_security_group.refinery.id
  description       = "Allow Refinery to send traffic to the ALB"

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"

  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "refinery_redis_in" {
  security_group_id = aws_security_group.refinery.id
  description       = "Allow Refinery to receive traffic from Redis"

  type      = "ingress"
  from_port = var.redis_port
  to_port   = var.redis_port
  protocol  = "tcp"

  source_security_group_id = aws_security_group.redis.id
}

resource "aws_security_group_rule" "refinery_redis_out" {
  security_group_id = aws_security_group.refinery.id
  description       = "Allow Refinery to send traffic to Redis"

  type      = "egress"
  from_port = var.redis_port
  to_port   = var.redis_port
  protocol  = "tcp"

  source_security_group_id = aws_security_group.redis.id
}

resource "aws_security_group_rule" "refinery_out" {
  security_group_id = aws_security_group.refinery.id
  description       = "Allow Refinery to send traffic out to the world"

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS007
}

resource "aws_security_group_rule" "refinery_peers_in" {
  security_group_id = aws_security_group.refinery.id
  description       = "Allow Refinery peers to send data to eachother"

  type      = "ingress"
  from_port = "8081"
  to_port   = "8081"
  protocol  = "tcp"

  source_security_group_id = aws_security_group.refinery.id
}

resource "aws_security_group_rule" "refinery_peers_out" {
  security_group_id = aws_security_group.refinery.id
  description       = "Allow Refinery peers to receive data from eachother"

  type      = "egress"
  from_port = "8081"
  to_port   = "8081"
  protocol  = "tcp"

  source_security_group_id = aws_security_group.refinery.id
}
