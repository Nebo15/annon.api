use Mix.Config

config :gateway, Gateway.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_TEST_DATABASE") || "trader_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn

config :gateway, sql_sandbox: true
