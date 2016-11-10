ExUnit.start(exclude: [:pending])
Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Configs.Repo, {:shared, self()})
Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, {:shared, self()})
{:ok, _} = Application.ensure_all_started(:ex_machina)
