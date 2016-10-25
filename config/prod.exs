use Mix.Config

config :gateway, Gateway.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "${DB_NAME}",
  username: "${DB_USER}",
  password: "${DB_PASSWORD}",
  hostname: "${DB_HOST}",
  port: "${DB_PORT}"

config :libcluster,
  strategy: Cluster.Strategy.Kubernetes,
  kubernetes_selector: "app=myapp",
  kubernetes_node_basename: "myapp"
