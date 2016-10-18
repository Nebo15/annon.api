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

config :logger, level: :warn

config :gateway, :http,
  port: { :system, "GATEWAY_PORT", 4000 }

config :cassandra,
  hostname: "127.0.0.1",
  port: 9042,
  keyspace: "gateway"

import_config "#{Mix.env}.exs"
