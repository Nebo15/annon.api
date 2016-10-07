use Mix.Config

# Configure your database
config :gateway, Gateway.DB.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: System.get_env("MIX_TEST_DATABASE") || "gateway_test"
