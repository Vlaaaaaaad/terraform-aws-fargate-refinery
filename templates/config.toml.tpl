# Refinery Config
ListenAddr = "0.0.0.0:8080"
PeerListenAddr = "0.0.0.0:8081"
APIKeys = [
  %{ for api_key in accepted_api_keys ~}
  "${api_key}",
  %{ endfor ~}
]
HoneycombAPI = "https://api.honeycomb.io"
SendDelay = "${send_delay}"
TraceTimeout = "${trace_timeout}"
SendTicker = "${send_ticker}"
LoggingLevel = "${log_level}"
UpstreamBufferSize = ${upstream_buffer_size}
PeerBufferSize = ${peer_buffer_size}

# Implementation Choices
Collector = "InMemCollector"
Logger = "${logger_option}"
Metrics = "${metrics_option}"

[PeerManagement]
Type = "redis"
RedisHost = "${redis_host}"

[InMemCollector]
CacheCapacity = ${cache_capacity}
MaxAlloc = ${max_alloc}

[LogrusLogger]
# logrus logger currently has no options!

[HoneycombLogger]
LoggerHoneycombAPI = "https://api.honeycomb.io"
LoggerAPIKey = "${logger_api_key}"
LoggerDataset = "${logger_dataset_name}"

[HoneycombMetrics]
MetricsHoneycombAPI = "https://api.honeycomb.io"
MetricsAPIKey = "${metrics_api_key}"
MetricsDataset = "${metrics_dataset}"
MetricsReportingInterval = ${metrics_reporting_interval}

[PrometheusMetrics]
MetricsListenAddr = "localhost:2112"
