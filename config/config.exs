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

config :gateway, :public_http,
  port: { :system, "GATEWAY_PORT", 4000 }

config :gateway, :private_http,
  port: { :system, "GATEWAY_PORT", 4001 }

import_config "#{Mix.env}.exs"
