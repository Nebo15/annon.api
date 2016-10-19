use Mix.Config

config :gateway, Gateway.DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  priv: "priv/repos",
  database: "gateway",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool_size: 10

config :gateway, ecto_repos: [Gateway.DB.Repo]

config :logger, level: :debug

config :gateway, :http,
  port: { :system, "GATEWAY_PORT", 4000 }

config :cassandra, :connection,
  hostname: "localhost",
  port: 9042,
  keyspace: "system"

import_config "#{Mix.env}.exs"
