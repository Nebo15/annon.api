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
  protected_headers: {:system, :list, "PROTECTED_HEADERS", [
    "x-consumer-id", "x-consumer-scope", "x-consumer-token", "x-consumer-token-id"
  ]}

config :skycluster,
  strategy: {:system, :module, "SKYCLUSTER_STRATEGY", Cluster.Strategy.Epmd}

config :annon_api,
  sql_sandbox: {:system, :boolean, "SQL_SANDBOX", false}

config :annon_api, :metrics_collector,
  enabled?: {:system, :boolean, "METRICS_COLLECTOR_ENABLED", true},
  send_tags: {:system, :boolean, "METRICS_COLLECTOR_SEND_TAGS", true},
  host: {:system, :string, "METRICS_COLLECTOR_HOST", "localhost"},
  port: {:system, :number, "METRICS_COLLECTOR_PORT", 32768},
  namespace: {:system, :string, "METRICS_COLLECTOR_NAMESPACE", "annon"},
  sample_rate: {:system, :float, "METRICS_COLLECTOR_SAMPLE_RATE", 0.25}

import_config "plugins.exs"
import_config "#{Mix.env}.exs"
