module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "v5.10.0"

  name = format(
    "%.32s",
    lower(
      replace(
        var.name,
        "_",
        "-",
      ),
    ),
  )

  internal = var.alb_internal
  vpc_id   = local.vpc_id
  subnets  = length(var.vpc_alb_subnets) == 0 ? module.vpc[0].public_subnets : var.vpc_alb_subnets

  security_groups = flatten([
    aws_security_group.alb.id,
    var.alb_additional_sgs,
  ])

  access_logs = {
    enabled = var.alb_logging_enabled
    bucket  = var.alb_log_bucket_name
    prefix  = var.alb_log_location_prefix
  }

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    },
  ]

  https_listeners = [
    {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = local.certificate_arn
    },
  ]

  target_groups = [
    {
      name                 = var.name
      backend_protocol     = "HTTP"
      backend_port         = 8080
      target_type          = "ip"
      deregistration_delay = 10
    },
  ]

  tags = local.tags
}

resource "aws_security_group" "alb" {
  vpc_id = local.vpc_id

  name        = "${var.name}-alb"
  description = "ALB SG for ${var.name}"

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-alb"
    },
  )
}

resource "aws_security_group_rule" "alb_in_80" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow the ALB to receive HTTP traffic from everywhere"

  type      = "ingress"
  from_port = "0"
  to_port   = "80"
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS006
}

resource "aws_security_group_rule" "alb_in_443" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow the ALB to receive HTTPS traffic from everywhere"

  type      = "ingress"
  from_port = "0"
  to_port   = "443"
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS006
}

resource "aws_security_group_rule" "alb_out" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow the ALB to send traffic to everywhere"

  type      = "egress"
  from_port = "0"
  to_port   = "65535"
  protocol  = "tcp"

  cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:AWS007
}
