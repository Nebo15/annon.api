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

memory_stats = ~w(atom binary ets processes total)a

config :exometer,
   predefined: [
     {
       ~w(erlang memory)a,
       {:function, :erlang, :memory, [], :proplist, memory_stats},
       []
     }
   ],
   report: [
     reporters: [{:exometer_report_statsd, []}],
     subscribers: [
       {
         :exometer_report_statsd,
         [:erlang, :memory], memory_stats, 1_000, true
       }
     ]
   ]

config :elixometer,
 reporter: :exometer_report_statsd,
   env: Mix.env,
   metric_prefix: "os.gateway"

config :exometer_core, report: [
  reporters: [
    exometer_report_statsd: [
      host: "localhost",
      port: 8125
    ]
  ]
]

config :logger, level: :debug

config :gateway, :http,
  port: { :system, "GATEWAY_PORT", 4000 }

import_config "#{Mix.env}.exs"
