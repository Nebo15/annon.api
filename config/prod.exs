use Mix.Config

config :gateway, Gateway.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "${DB_NAME}",
  username: "${DB_USER}",
  password: "${DB_PASSWORD}",
  hostname: "${DB_HOST}",
  port: "${DB_PORT}"

config :gateway, Gateway.DB.Logger.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "${DB_NAME}",
  username: "${DB_USER}",
  password: "${DB_PASSWORD}",
  hostname: "${DB_HOST}",
  port: "${DB_PORT}"

config :libcluster,
  strategy: {:system, :module, "LIBCLUSTER_STRATEGY", Cluster.Strategy.Kubernetes},
  kubernetes_selector: {:system, "LIBCLUSTER_KUBERNATES_SELECTOR", "app=gateway"},
  kubernetes_node_basename: {:system, "LIBCLUSTER_KUBERNATES_NODE_BASENAME", "gateway"}
