use Mix.Config

config :annon_api, Annon.Configuration.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "annon_api_configs",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  priv: "priv/repos/configuration",
  pool_size: 10

config :annon_api, Annon.Requests.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "annon_api_logger",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  priv: "priv/repos/requests",
  pool_size: 10

config :annon_api, ecto_repos: [Annon.Configuration.Repo, Annon.Requests.Repo]

config :ex_statsd,
       host: "localhost",
       port: 8125,
       namespace: "annon"

config :logger, level: :debug

config :annon_api, :public_http,
  port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 4000}

config :annon_api, :private_http,
  port: {:system, :integer, "GATEWAY_PRIVATE_PORT", 8000}

config :annon_api, :management_http,
  port: {:system, :integer, "GATEWAY_MANAGEMENT_PORT", 4001}

config :annon_api,
  protected_headers: ["x-consumer-id", "x-consumer-scopes"]

config :skycluster,
  strategy: {:system, :module, "SKYCLUSTER_STRATEGY", Cluster.Strategy.Epmd}

config :annon_api,
  sql_sandbox: {:system, :boolean, "SQL_SANDBOX", false}

config :annon_api,
  cache_storage: {:system, :module, "CACHE_STORAGE", Annon.Cache.EtsAdapter}

import_config "#{Mix.env}.exs"
