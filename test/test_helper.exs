# Start mock server
{:ok, _} = Plug.Adapters.Cowboy.http Annon.MockServer, [], port: Confex.get_map(:annon_api, :acceptance)[:mock][:port]

# Start Factory service
{:ok, _} = Application.ensure_all_started(:ex_machina)

# Switch SQL sandbox to manual mode
Ecto.Adapters.SQL.Sandbox.mode(Annon.DB.Configs.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Annon.DB.Logger.Repo, :manual)

# Start tests
ExUnit.start(exclude: [:pending])
