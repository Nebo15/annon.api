defmodule Gateway.Acceptance.Plugins.UARestrictionTest do
  @moduledoc false
  use Gateway.AcceptanceCase, async: false

  setup do
    api_path = "/my_ua_filtered_api-" <> Ecto.UUID.generate() <> "/"
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

  describe "settings validation" do
    test "invalid settings", %{api_id: api_id, api_path: api_path} do
      ua_restriction_plugin = :ua_restriction_plugin
      |> build_factory_params(%{settings: %{
        blacklist: ["*"],
        whitelist: ["a*"]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(ua_restriction_plugin)
      |> assert_status(201)

      expected_result = [%{"entry" => "settings", "entry_type" => "json_data_property", "rules" => ["invalid"]}]

      actual_result = api_path
      |> put_public_url()
      |> get!()
      |> assert_status(422)
      |> get_body()
      |> get_in(["error", "invalid"])

      assert expected_result == actual_result
    end

    test "valid settings", %{api_id: api_id, api_path: api_path} do
      ua_restriction_plugin = :ua_restriction_plugin
      |> build_factory_params(%{settings: %{
        blacklist: ["a*"],
        whitelist: ["a*"]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(ua_restriction_plugin)
      |> assert_status(201)

      api_path
      |> put_public_url()
      |> get!()
      |> assert_status(404)
    end
  end
end
