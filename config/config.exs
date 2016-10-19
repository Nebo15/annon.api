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

<<<<<<< HEAD
config :exometer,  
=======
config :exometer,
>>>>>>> origin/OSL-381
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

<<<<<<< HEAD
config :elixometer,  
  reporter: :exometer_report_statsd,
    env: Mix.env,
    metric_prefix: "myapp"
=======
config :elixometer,
  reporter: :exometer_report_statsd,
    env: Mix.env,
    metric_prefix: "os.gateway"
>>>>>>> origin/OSL-381

config :exometer_core, report: [
  reporters: [
    exometer_report_statsd: [
      host: "localhost",
      port: 8125
    ]
  ]
<<<<<<< HEAD
]    

config :logger, level: :warn
=======
]

config :logger, level: :debug

config :gateway, :http,
  port: { :system, "GATEWAY_PORT", 4000 }
>>>>>>> origin/OSL-381

import_config "#{Mix.env}.exs"
