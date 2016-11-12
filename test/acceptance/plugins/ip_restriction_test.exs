defmodule Gateway.Acceptance.Plugin.IPRestrictionTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  setup do
    api_path = "/my_ip_filtered_api"
    api = :api
    |> build_factory_params(%{
      request: %{
        method: ["GET", "POST", "PUT", "DELETE"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: api_path
      }
    })
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    %{api_id: api_id, api_path: api_path}
  end

  test "blacklists ipv4 addresses", %{api_id: api_id, api_path: api_path} do
    ip_restriction_plugin = :ip_restriction_plugin
    |> build_factory_params(%{settings: %{
      ip_blacklist: ["127.0.0.*"],
      ip_whitelist: ["128.30.50.245"]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(ip_restriction_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config

    assert %{
      "error" => %{"message" => "You has been blocked from accessing this resource.", "type" => "forbidden"}
    } = api_path
    |> put_public_url()
    |> get!()
    |> assert_status(403)
    |> get_body()
  end

  test "whitelist allows blacklistsed addresses", %{api_id: api_id, api_path: api_path} do
    ip_restriction_plugin = :ip_restriction_plugin
    |> build_factory_params(%{settings: %{
      ip_blacklist: ["255.255.255.1", "127.0.0.*"],
      ip_whitelist: ["192.168.0.1", "127.0.0.1"]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(ip_restriction_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config

    api_path
    |> put_public_url()
    |> get!()
    |> assert_status(404)
  end
end
