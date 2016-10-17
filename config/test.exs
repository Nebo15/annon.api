use Mix.Config

config :gateway, Gateway.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_TEST_DATABASE") || "trader_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :gateway, :http,
  port: { :system, "GATEWAY_PORT", 4000 }

config :gateway, :acceptance,
  port: { :system, "MIX_TEST_PORT", 4000 },
  host: { :system, "MIX_TEST_HOST", "localhost" }

config :logger, level: :warn

config :gateway, sql_sandbox: true
