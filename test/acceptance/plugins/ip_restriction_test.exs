defmodule Annon.Acceptance.Plugins.IPRestrictionTest do
  @moduledoc false
  use Annon.AcceptanceCase, async: true

  setup do
    api_path = "/my_ip_filtered_api-" <> Ecto.UUID.generate() <> "/"
    api = :api
    |> build_factory_params(%{
      request: %{
        methods: ["GET", "POST", "PUT", "DELETE"],
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

  describe "IPRestriction Plugin" do
    test "create whitelist", %{api_id: api_id} do
      ip_restriction = :ip_restriction_plugin
      |> build_factory_params(%{settings: %{whitelist: ["127.0.0.1"]}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(ip_restriction)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "ip_restriction",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create blacklist", %{api_id: api_id} do
      ip_restriction = :ip_restriction_plugin
      |> build_factory_params(%{settings: %{blacklist: ["127.0.0.1"]}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(ip_restriction)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "ip_restriction",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create whitelist and blacklist", %{api_id: api_id} do
      ip_restriction = :ip_restriction_plugin
      |> build_factory_params(%{settings: %{whitelist: ["127.0.0.1"], blacklist: ["127.0.0.1"]}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(ip_restriction)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "ip_restriction",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create with invalid settings", %{api_id: api_id} do
      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{})
      |> assert_status(422)

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(build_invalid_plugin("ip_restriction"))
      |> assert_status(422)

      %{
        "error" => %{
          "invalid" => [%{"entry" => "$.settings.blacklist", "rules" => [%{"rule" => "cast"}]}]
          # TODO: Test "params"
          # "invalid" => [%{"entry" => "$.settings.ip_whitelis", "rules" => [%{"rule" => "format"}]}]
          # TODO: different fields should not be merged together in one `entry`
        }
      } = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{
        name: "ip_restriction",
        is_enabled: false,
        settings: %{"blacklist" => 100} # , "whitelist" => ["127.0.0.256"]
      })
      |> assert_status(422)
      |> get_body()
    end
  end

  test "blacklists ipv4 addresses", %{api_id: api_id, api_path: api_path} do
    ip_restriction_plugin = :ip_restriction_plugin
    |> build_factory_params(%{settings: %{
      blacklist: ["127.0.0.*"],
      whitelist: ["128.30.50.245"]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(ip_restriction_plugin)
    |> assert_status(201)

    assert %{
      "error" => %{"message" => "You has been blocked from accessing this resource", "type" => "forbidden"}
    } = api_path
    |> put_public_url()
    |> get!()
    |> assert_status(403)
    |> get_body()
  end

  test "whitelist allows blacklistsed addresses", %{api_id: api_id, api_path: api_path} do
    ip_restriction_plugin = :ip_restriction_plugin
    |> build_factory_params(%{settings: %{
      blacklist: ["255.255.255.1", "127.0.0.*"],
      whitelist: ["192.168.0.1", "127.0.0.1"]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(ip_restriction_plugin)
    |> assert_status(201)

    api_path
    |> put_public_url()
    |> get!()
    |> assert_status(404)
  end
end
