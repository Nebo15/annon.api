use Mix.Config

config :gateway, Gateway.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_TEST_DATABASE") || "gateway_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :gateway, :acceptance,
  private: [
    port: { :system, :integer, "MIX_TEST_PRIVATE_PORT", 4001 },
    host: { :system, "MIX_TEST_HOST", "localhost" }
  ],
  public: [
    port: { :system, :integer, "MIX_TEST_PUBLIC_PORT", 4000 },
    host: { :system, "MIX_TEST_HOST", "localhost" }
  ]

config :logger, level: :debug

config :ex_unit, capture_log: true

config :gateway, sql_sandbox: true
