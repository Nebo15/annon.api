use Mix.Config

config :gateway, Gateway.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_TEST_DATABASE") || "trader_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warn

config :gateway, sql_sandbox: true

memory_stats = ~w(atom binary ets processes total)a

config(:exometer_core, report: [reporters: [{Gateway.Monitoring.TestReporter, []}]])

config(:elixometer, update_frequency: 20,
       reporter: Gateway.Monitoring.TestReporter,
       env: Mix.env,
       metric_prefix: "os.gateway")

config :exometer,
   report: [
     reporters: [{Gateway.Monitoring.TestReporter, []}]
   ]
