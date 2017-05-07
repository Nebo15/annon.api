defmodule Annon.Acceptance.Plugins.UARestrictionTest do
  @moduledoc false
  use Annon.AcceptanceCase, async: false

  @user_agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"

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
    # TODO: Move to creation changeset
    # test "invalid settings", %{api_id: api_id, api_path: api_path} do
    #   ua_restriction_plugin = :ua_restriction_plugin
    #   |> build_factory_params(%{settings: %{
    #     blacklist: ["*"],
    #     whitelist: ["a*"]
    #   }})

    #   "apis/#{api_id}/plugins"
    #   |> put_management_url()
    #   |> post!(ua_restriction_plugin)
    #   |> assert_status(201)

    #   expected_result = [%{"entry" => "settings", "entry_type" => "json_data_property", "rules" => ["invalid"]}]

    #   actual_result = api_path
    #   |> put_public_url()
    #   |> get!()
    #   |> assert_status(422)
    #   |> get_body()
    #   |> get_in(["error", "invalid"])

    #   assert expected_result == actual_result
    # end

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

  test "blacklists chrome requests", %{api_id: api_id, api_path: api_path} do
    ua_restriction_plugin = :ua_restriction_plugin
    |> build_factory_params(%{settings: %{
      blacklist: ["Chrome"]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(ua_restriction_plugin)
    |> assert_status(201)

    actual_result = api_path
    |> put_public_url()
    |> get!([{"user-agent", @user_agent}])
    |> assert_status(403)
    |> get_body()
    |> Map.get("error")

    expected_result = %{"message" => "You have been blocked from accessing this resource.", "type" => "forbidden"}
    assert expected_result == actual_result
  end

  test "whitelist allows blacklisted user agents", %{api_id: api_id, api_path: api_path} do
    ua_restriction_plugin = :ua_restriction_plugin
    |> build_factory_params(%{settings: %{
      blacklist: ["Linux"],
      whitelist: ["Chrome"]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(ua_restriction_plugin)
    |> assert_status(201)

    api_path
    |> put_public_url()
    |> get!([{"user-agent", @user_agent}])
    |> assert_status(404)
  end
end
