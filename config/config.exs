use Mix.Config

config :annon_api, Annon.Configuration.Repo,
  adapter: Ecto.Adapters.Postgres,
  priv: "priv/repos/configuration",
  database: {:system, "DB_NAME", "annon_api_configs"},
  username: {:system, "DB_USER", "postgres"},
  password: {:system, "DB_PASSWORD", "postgres"},
  hostname: {:system, "DB_HOST", "localhost"},
  port: {:system, :integer, "DB_PORT", 5432},
  pool_size: 10

config :annon_api, Annon.Requests.Repo,
  adapter: Ecto.Adapters.Postgres,
  priv: "priv/repos/requests",
  database: {:system, "DB_NAME", "annon_api_logger"},
  username: {:system, "DB_USER", "postgres"},
  password: {:system, "DB_PASSWORD", "postgres"},
  hostname: {:system, "DB_HOST", "localhost"},
  port: {:system, :integer, "DB_PORT", 5432},
  pool_size: 50

config :annon_api,
  ecto_repos: [Annon.Configuration.Repo, Annon.Requests.Repo]

config :annon_api, :configuration_cache,
  adapter: {:system, :module, "CONFIGURATION_CACHE_ADAPTER", Annon.Configuration.CacheAdapters.ETS},
  cache_space: :configuration

# TODO: Replace with statix
config :ex_statsd,
  host: "localhost",
  port: 8125,
  namespace: "annon"

# Configure Elixir logger
config :logger,
  level: :debug

# Configure JSON Logger back-end
config :logger_json, :backend,
  on_init: {Annon, :load_from_system_env, []},
  json_encoder: Poison,
  metadata: :all

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

import_config "#{Mix.env}.exs"
