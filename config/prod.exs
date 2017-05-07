use Mix.Config

config :ex_statsd,
  host: "${STATSD_HOST}",
  port: 8125,
  namespace: "gateway"

config :skycluster,
  strategy: {:system, :module, "SKYCLUSTER_STRATEGY", Cluster.Strategy.Kubernetes},
  kubernetes_selector: {:system, "SKYCLUSTER_KUBERNETES_SELECTOR", "app=annon,component=api"},
  kubernetes_node_basename: {:system, "SKYCLUSTER_NODE_NAME", "annon_api"}

# Do not print debug messages in production
# and handle all other reports by Elixir Logger with JSON back-end
# SASL reports turned off because of their verbosity.
config :logger,
  backends: [LoggerJSON],
  level: :info,
  # handle_sasl_reports: true,
  handle_otp_reports: true
