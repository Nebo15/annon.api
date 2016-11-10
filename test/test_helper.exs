ExUnit.start(exclude: [:pending])
Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Configs.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)
