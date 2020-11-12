variable "refinery_accepted_api_keys" {
  description = "The list of Honeycomb API keys that the proxy will accept"
  type        = list(string)
  default = [
    "*",
  ]
}

variable "refinery_send_delay" {
  description = "The delay to wait after a trace is complete, before sending"
  default     = "2s"
}

variable "refinery_trace_timeout" {
  description = "The amount of time to wait for a trace to be completed before sending"
  default     = "60s"
}

variable "refinery_log_level" {
  description = "The Refinery log level"
  default     = "debug"
}

variable "refinery_upstream_buffer_size" {
  description = "The number of events to buffer before sending to Honeycomb"
  default     = 10000
}

variable "refinery_peer_buffer_size" {
  description = "The number of events to buffer before seding to peers"
  default     = 10000
}

variable "refinery_send_ticker" {
  description = "The duration to use to check for traces to send"
  default     = "100ms"
}

variable "refinery_cache_capacity" {
  description = "The number of spans to cache"
  default     = 1000
}

variable "refinery_max_alloc" {
  description = "The maximum memory to use"
  default     = 0
}

variable "refinery_logger_option" {
  description = "The loger option for refinery"
  default     = "logrus"

  validation {
    condition = (
      var.refinery_logger_option == "honeycomb"
      || var.refinery_logger_option == "logrus"
    )
    error_message = "The refinery_logger_option value must be \"honeycomb\" or \"logrus\"."
  }
}

variable "refinery_logger_api_key" {
  description = "The API key to use to send Refinery logs to Honeycomb"
  default     = ""
}

variable "refinery_logger_dataset_name" {
  description = "The dataset to which to send Refinery logs to"
  default     = "Refinery Logs"
}

variable "refinery_metrics_api_key" {
  description = "The API key used to send Refinery metrics to Honeycomb"
  default     = ""
}

variable "refinery_metrics_option" {
  description = "The metrics option for refinery"
  default     = "prometheus"

  validation {
    condition = (
      var.refinery_metrics_option == "honeycomb"
      || var.refinery_metrics_option == "prometheus"
    )
    error_message = "The refinery_metrics_option value must be \"honeycomb\" or \"prometheus\"."
  }
}

variable "refinery_metrics_dataset" {
  description = "The dataset to which to send Refinery metrics to"
  default     = "Refinery Metrics"
}

variable "refinery_metrics_reporting_interval" {
  description = "The interval (in seconds) to wait between sending metrics to Honeycomb"
  default     = 3
}

variable "refiery_sampler_dry_run" {
  description = "The flag to enable DryRun mode for Refinery"
  type        = bool
  default     = false
}

variable "refinery_dry_run_field_name" {
  description = "The key to add to each event when in DryRun mode"
  default     = "refinery_kept"
}

variable "refinery_default_sample_rate" {
  description = "The sampler rate for the default sampler"
  default     = 1
}

variable "refinery_sampler_configs" {
  description = "The Refinery sampling rules configuration"
  type = list(
    object(
      {
        dataset_name = string
        options      = list(map(string))
      }
    )
  )

  default = [
    {
      dataset_name = "_default",
      options = [
        {
          "name"  = "Sampler"
          "value" = "DynamicSampler"
        },
        {
          "name"  = "SampleRate"
          "value" = 1
        },
      ]
    },
  ]
}
