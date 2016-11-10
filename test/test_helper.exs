# Setup fake server
FakeServer.Status.create(:status200, %{response_code: 200, response_body: "Hello World"})
{:ok, address} = FakeServer.run(:external_server, [], %{port: 9090})

# Write it's url to env
Application.put_env(:gateway, :fake_server_url, address)

# Start Factory service
{:ok, _} = Application.ensure_all_started(:ex_machina)

# Switch SQL sandbox to manual mode
Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Configs.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, :manual)

# Start tests
ExUnit.start(exclude: [:pending])
