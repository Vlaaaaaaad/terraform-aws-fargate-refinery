locals {
  filled_config_file = templatefile(
    "${path.module}/templates/config.toml.tpl",
    {
      accepted_api_keys          = var.refinery_accepted_api_keys
      send_delay                 = var.refinery_send_delay
      trace_timeout              = var.refinery_trace_timeout
      send_ticker                = var.refinery_send_ticker
      cache_capacity             = var.refinery_cache_capacity
      max_alloc                  = var.refinery_max_alloc
      upstream_buffer_size       = var.refinery_upstream_buffer_size
      peer_buffer_size           = var.refinery_peer_buffer_size
      logger_option              = var.refinery_logger_option
      log_level                  = var.refinery_log_level
      logger_api_key             = var.refinery_logger_api_key
      logger_dataset_name        = var.refinery_logger_dataset_name
      metrics_api_key            = var.refinery_metrics_api_key
      metrics_dataset            = var.refinery_metrics_dataset
      metrics_reporting_interval = var.refinery_metrics_reporting_interval
      metrics_option             = var.refinery_metrics_option
      redis_host = join(
        ":",
        [
          aws_elasticache_replication_group.redis.primary_endpoint_address,
          var.redis_port,
        ],
      )
    }
  )

  filled_rules_file = templatefile(
    "${path.module}/templates/rules.toml.tpl",
    {
      dry_run            = var.refiery_sampler_dry_run,
      dry_run_field_name = var.refinery_dry_run_field_name,
      samplers           = var.refinery_sampler_configs,
    }
  )
}

resource "aws_ssm_parameter" "config" {
  name        = "/${var.name}/config"
  description = "The Base64-encoded Refinery configuration"

  type  = "SecureString"
  tier  = "Advanced"
  value = base64encode(local.filled_config_file)

  tags = local.tags
}

resource "aws_ssm_parameter" "rules" {
  name        = "/${var.name}/rules"
  description = "The Base64-encoded Refinery rules"

  type  = "SecureString"
  tier  = "Advanced"
  value = base64encode(local.filled_rules_file)

  tags = local.tags
}
