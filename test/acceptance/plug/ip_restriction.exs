defmodule Gateway.Acceptance.Plug.IPRestriction do
  use Gateway.AcceptanceCase

  @request %{
    host: "localhost",
    method: "GET",
    path: "/random_path",
    port: 5000,
    scheme: "http"
  }

  defp create_api do
    {:ok, result} = Gateway.DB.Models.API
    |> EctoFixtures.ecto_fixtures()
    |> Map.put(:request, @request)
    |> Gateway.DB.Models.API.create()
    result
  end

  defp create_plugin(api, settings) do
    model = Gateway.DB.Models.Plugin
    |> EctoFixtures.ecto_fixtures()
    |> Map.put(:name, :IPRestriction)
    |> Map.put(:api_id, api.id)
    |> Map.put(:is_enabled, true)
    |> Map.put(:settings, settings)

    api
    |> Gateway.DB.Models.Plugin.create(model)
  end

  test "check blacklist" do
    create_api
    |> create_plugin(%{"ip_blacklist" => ["127.0.0.*"]})

    {:ok, response} = @request.path
    |> String.replace_prefix("/", "")
    |> get(:public)

    body = Poison.decode! response.body

    assert 400 === body["meta"]["code"]
    assert "blacklisted" === body["meta"]["description"]
  end

  test "check blacklist + whitelist" do
    create_api
    |> create_plugin(%{"ip_blacklist" => ["127.0.0.*"], "ip_whitelist" => ["127.0.0.1"]})

    {:ok, response} = @request.path
    |> String.replace_prefix("/", "")
    |> get(:public)

    body = Poison.decode! response.body

    assert "blacklisted" !== body["meta"]["description"]
  end
end
