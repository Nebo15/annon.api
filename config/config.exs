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

config :ex_statsd,
       host: "localhost",
       port: 8125,
       namespace: "os.gateway"

config :logger, level: :debug

config :gateway, :public_http,
  port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 4000}

config :gateway, :private_http,
  port: {:system, :integer, "GATEWAY_PRIVATE_PORT", 4001}

config :cassandra, :connection,
  hostname: {:system, "CASSANDRA_DB_HOST", "localhost"},
  port: {:system, :integer, "CASSANDRA_DB_PORT", 9042}

import_config "#{Mix.env}.exs"
