use Mix.Config

config :gateway, Gateway.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: System.get_env("MIX_TEST_DATABASE") || "gateway_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :gateway, :http,
  port: { :system, "GATEWAY_PORT", 4000 }

config :gateway, :acceptance,
  port: { :system, :integer, "MIX_TEST_PORT", 4000 },
  host: { :system, "MIX_TEST_HOST", "localhost" }

config :logger, level: :debug

config :ex_unit, capture_log: true

config :gateway, sql_sandbox: true

memory_stats = ~w(atom binary ets processes total)a

config :exometer,
  report: [
    reporters: [{Gateway.Monitoring.TestReporter, []}]
   ]
