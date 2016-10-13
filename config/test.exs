use Mix.Config

# Configure your database
config :gateway, Gateway.DB.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  database: "gateway_test"
