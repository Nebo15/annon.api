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

    %{"ip_blacklist" => ["127.0.0.*"], "ip_whitelist" => ["128.30.50.245"]}
    |> api_ip_restriction_data()
    |> http_api_create()

    Gateway.AutoClustering.do_reload_config

    @request.path
    |> String.replace_prefix("/", "")
    |> get(:public)
    |> assert_status(400)
  end

  test "check blacklist + whitelist" do

    %{"ip_blacklist" => ["255.255.255.1", "127.0.0.*"], "ip_whitelist" => ["192.168.0.1", "127.0.0.1"]}
    |> api_ip_restriction_data()
    |> http_api_create()

    Gateway.AutoClustering.do_reload_config()

    @request.path
    |> String.replace_prefix("/", "")
    |> get(:public)
    |> assert_status(404)
  end

  def api_ip_restriction_data(settings) when is_map(settings) do
    get_api_model_data()
    |> Map.put(:request, @request)
    |> Map.put(:plugins, [
      %{name: "ip_restriction", is_enabled: true, settings: settings},
    ])
  end
end
