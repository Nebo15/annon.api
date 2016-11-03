defmodule Gateway.Acceptance.Plug.IPRestrictionTest do
  use Gateway.AcceptanceCase

  @request %{
    host: "localhost",
    method: "GET",
    path: "/random_path",
    port: 5000,
    scheme: "http"
  }

  test "check blacklist" do

    %{"ip_blacklist" => Poison.encode!(["127.0.0.*"]), "ip_whitelist" => "[]"}
    |> api_ip_restriction_data()
    |> http_api_create()

    @request.path
    |> String.replace_prefix("/", "")
    |> get(:public)
    |> assert_status(400)
  end

  test "check blacklist + whitelist" do

    %{"ip_blacklist" => Poison.encode!(["127.0.0.*"]), "ip_whitelist" => Poison.encode!(["127.0.0.1"])}
    |> api_ip_restriction_data()
    |> http_api_create()

    @request.path
    |> String.replace_prefix("/", "")
    |> get(:public)
    |> assert_status(404)
  end

  def api_ip_restriction_data(settings) when is_map(settings) do
    get_api_model_data()
    |> Map.put(:request, @request)
    |> Map.put(:plugins, [
      %{name: "IPRestriction", is_enabled: true, settings: settings},
    ])
  end
end
