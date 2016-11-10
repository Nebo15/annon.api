use Mix.Config

config :gateway, Gateway.DB.Configs.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_TEST_DATABASE") || "gateway_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :gateway, Gateway.DB.Logger.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_LOGGER_TEST_DATABASE") || "gateway_logger_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :gateway, :acceptance,
  management: [
    port: {:system, :integer, "MIX_TEST_MANAGEMENT_PORT", 5001},
    host: {:system, "MIX_TEST_HOST", "localhost"}
  ],
  public: [
    port: {:system, :integer, "MIX_TEST_PUBLIC_PORT", 5000},
    host: {:system, "MIX_TEST_HOST", "localhost"}
  ]

config :gateway, :public_http,
  port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 5000}

config :gateway, :management_http,
  port: {:system, :integer, "GATEWAY_MANAGEMENT_PORT", 5001}

config :logger, level: :debug

config :ex_unit, capture_log: true

config :gateway, sql_sandbox: true
