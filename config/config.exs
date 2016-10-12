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

import_config "#{Mix.env}.exs"
