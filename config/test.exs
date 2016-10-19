use Mix.Config

config :gateway, Gateway.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_TEST_DATABASE") || "trader_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn

config :gateway, sql_sandbox: true

memory_stats = ~w(atom binary ets processes total)a

config :exometer,
   report: [
     reporters: [{Gateway.Monitoring.TestReporter, []}]
   ]
