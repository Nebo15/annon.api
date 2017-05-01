use Mix.Config

config :ex_statsd,
  host: "${STATSD_HOST}",
  port: 8125,
  namespace: "gateway"

config :skycluster,
  strategy: {:system, :module, "SKYCLUSTER_STRATEGY", Cluster.Strategy.Kubernetes},
  kubernetes_selector: {:system, "SKYCLUSTER_KUBERNETES_SELECTOR", "app=annon,component=api"},
  kubernetes_node_basename: {:system, "SKYCLUSTER_KUBERNETES_NODE_BASENAME", "gateway"}
