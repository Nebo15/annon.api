use Mix.Config

config :gateway, Gateway.DB.Configs.Repo,
  adapter: Ecto.Adapters.Postgres,
  priv: "priv/repos/gateway",
  database: "gateway",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10

config :gateway, Gateway.DB.Logger.Repo,
  adapter: Ecto.Adapters.Postgres,
  priv: "priv/repos/logger",
  database: "gateway_logger",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10

config :gateway, ecto_repos: [Gateway.DB.Configs.Repo, Gateway.DB.Logger.Repo]

config :ex_statsd,
       host: "localhost",
       port: 8125,
       namespace: "os.gateway"

config :logger, level: :debug

config :gateway, :public_http,
  port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 4000}

config :gateway, :private_http,
  port: {:system, :integer, "GATEWAY_PRIVATE_PORT", 4001}

config :skycluster,
  strategy: {:system, :module, "SKYCLUSTER_STRATEGY", Cluster.Strategy.Epmd}

import_config "#{Mix.env}.exs"
