locals {
  filled_config_file = templatefile(
    "${path.module}/templates/config.toml.tpl",
    {
      compress_peer_communication = var.refinery_compress_peer_communication
      accepted_api_keys           = var.refinery_accepted_api_keys
      send_delay                  = var.refinery_send_delay
      trace_timeout               = var.refinery_trace_timeout
      send_ticker                 = var.refinery_send_ticker
      cache_capacity              = var.refinery_cache_capacity
      max_alloc                   = var.refinery_max_alloc
      upstream_buffer_size        = var.refinery_upstream_buffer_size
      peer_buffer_size            = var.refinery_peer_buffer_size
      logger_option               = var.refinery_logger_option
      log_level                   = var.refinery_log_level
      logger_api_key              = var.refinery_logger_api_key
      logger_dataset_name         = var.refinery_logger_dataset_name
      logger_sampler_enabled      = var.refinery_logger_sampler_enabled
      logger_sampler_throughput   = var.refinery_logger_sampler_throughput
      metrics_api_key             = var.refinery_metrics_api_key
      metrics_dataset             = var.refinery_metrics_dataset
      metrics_reporting_interval  = var.refinery_metrics_reporting_interval
      metrics_option              = var.refinery_metrics_option
      redis_host = join(
        ":",
        [
          aws_elasticache_replication_group.redis.primary_endpoint_address,
          var.redis_port,
        ],
      )
      redis_password = random_string.redis_password.result,
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
