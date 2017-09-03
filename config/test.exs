use Mix.Config

# Configure autoclustering
config :skycluster,
  strategy: {:system, :module, "SKYCLUSTER_STRATEGY", Cluster.Strategy.Epmd}

config :annon_api,
  sql_sandbox: true,
  enable_ssl?: false

config :annon_api, Annon.Configuration.Repo,
  database: "annon_api_configs_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :annon_api, Annon.Requests.Repo,
  database: "annon_api_logger_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :annon_api, :metrics_collector,
  sink: [],
  namespace: "test",
  sample_rate: 1

config :annon_api, :acceptance,
  management: [
    port: {:system, :integer, "MIX_TEST_MANAGEMENT_PORT", 5001},
    host: {:system, "MIX_TEST_HOST", "localhost"}
  ],
  public: [
    port: {:system, :integer, "MIX_TEST_PUBLIC_PORT", 5000},
    host: {:system, "MIX_TEST_HOST", "localhost"}
  ],
  public_https: [
    port: {:system, :integer, "MIX_TEST_PUBLIC_HTTPS_PORT", 5443},
    host: {:system, "MIX_TEST_HOST", "localhost"}
  ],
  private: [
    port: {:system, :integer, "MIX_TEST_PUBLIC_PORT", 5002},
    host: {:system, "MIX_TEST_HOST", "localhost"}
  ],
  mock: [
    port: {:system, :integer, "TEST_MOCK_PORT", 4040},
    host: {:system, "TEST_MOCK_HOST", "127.0.0.1"}
  ]

config :annon_api, :public_http,
  port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 5000}

config :annon_api, :public_https,
  port: {:system, :integer, "GATEWAY_PUBLIC_SSL_PORT", 5443},
  keyfile: "priv/ssl/localhost.key",
  certfile: "priv/ssl/localhost.cert",
  dhfile: "priv/ssl/dhparam.pem",
  cacertfile: "priv/ssl/localhost_ca.cert"

config :annon_api, :private_http,
  port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 5002}

config :annon_api, :management_http,
  port: {:system, :integer, "GATEWAY_MANAGEMENT_PORT", 5001}

config :annon_api, :plugin_pipeline,
  # TODO: Improve tests to run without forced log consistency
  default_features: [:log_consistency]

config :logger,
  backends: [:console],
  level: :debug

config :ex_unit, capture_log: true

config :hackney, use_default_pool: false

config :annon_api, :configuration_cache,
  adapter: {:system, :module, "CONFIGURATION_CACHE_ADAPTER", Annon.Configuration.CacheAdapters.Database},
  cache_space: :configuration
