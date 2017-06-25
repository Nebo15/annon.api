use Mix.Config
# This file configures Annon's monitoring and tracing systems.

config :annon_api, :metrics_collector,
  enabled?: {:system, :boolean, "METRICS_COLLECTOR_ENABLED", true},
  send_tags: {:system, :boolean, "METRICS_COLLECTOR_SEND_TAGS", true},
  host: {:system, :string, "METRICS_COLLECTOR_HOST", "localhost"},
  port: {:system, :integer, "METRICS_COLLECTOR_PORT", 8125},
  namespace: {:system, :string, "METRICS_COLLECTOR_NAMESPACE", "annon"},
  sample_rate: {:system, :float, "METRICS_COLLECTOR_SAMPLE_RATE", 0.25}
