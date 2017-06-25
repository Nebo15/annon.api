use Mix.Config
# This file configures Annon's clustering subsystem.

config :skycluster,
  strategy: {:system, :module, "SKYCLUSTER_STRATEGY", Cluster.Strategy.Kubernetes},
  kubernetes_selector: {:system, "SKYCLUSTER_KUBERNETES_SELECTOR", "app=annon,component=api"},
  kubernetes_node_basename: {:system, "SKYCLUSTER_NODE_NAME", "annon_api"}
