resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name = var.name

  subnet_ids = length(var.redis_subnets) == 0 ? module.vpc[0].public_subnets : var.redis_subnets
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = var.name
  replication_group_description = "Refinery peer discovery Redis"
  number_cache_clusters         = 1
  node_type                     = var.redis_node_type
  engine_version                = var.redis_version
  port                          = var.redis_port

  subnet_group_name = aws_elasticache_subnet_group.redis_subnet_group.id
  security_group_ids = [
    aws_security_group.redis.id,
  ]

  # Refinery does not support Redis with TLS
  #  see https://github.com/honeycombio/refinery/issues/103
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  tags = local.tags
}

resource "aws_security_group" "redis" {
  vpc_id = local.vpc_id

  name        = "${var.name}-redis"
  description = "${var.name} Peer Discovery Redis"

  tags = merge(
    var.tags,
    {
      "Name" = "${var.name}-redis"
    },
  )
}

resource "aws_security_group_rule" "redis_ingress" {
  security_group_id = aws_security_group.redis.id
  description       = "Allow Redis to receive traffic from Refinery"

  type      = "ingress"
  from_port = var.redis_port
  to_port   = var.redis_port
  protocol  = "tcp"

  source_security_group_id = aws_security_group.refinery.id
}

resource "aws_security_group_rule" "redis_egress" {
  security_group_id = aws_security_group.redis.id
  description       = "Allow Redis to send traffic to Refinery"

  type      = "egress"
  from_port = var.redis_port
  to_port   = var.redis_port
  protocol  = "tcp"

  source_security_group_id = aws_security_group.refinery.id
}
