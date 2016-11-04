ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Configs.Repo, {:shared, self()})
Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, {:shared, self()})
