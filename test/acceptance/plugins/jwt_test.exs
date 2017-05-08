defmodule Annon.Acceptance.Plugins.JWTTest do
  @moduledoc false
  use Annon.AcceptanceCase, async: true

  @jwt_secret "secret"

  setup do
    api_path = "/my_jwt_authorized_api-" <> Ecto.UUID.generate() <> "/"
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

  describe "JWT Plugin" do
    test "create", %{api_id: api_id} do
      jwt_plugin = :jwt_plugin
      |> build_factory_params()

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(jwt_plugin)
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "jwt",
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
      |> post!(build_invalid_plugin("jwt"))
      |> assert_status(422)

      %{
        "error" => %{
          "invalid" => [%{"entry" => "$.settings.signature", "rules" => [
            %{"rule" => "cast", "params" => ["string" | _]} # TODO: Get rid from tail in params
          ]}]
        }
      } = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{name: "jwt", is_enabled: false, settings: %{"signature" => 1000}})
      |> assert_status(422)
      |> get_body()
    end

    test "create with invalid signature", %{api_id: api_id} do
      %{
        "error" => %{
          "invalid" => [%{"entry" => "$.settings.signature", "rules" => [
            %{"rule" => "cast", "description" => "is not Base64 encoded"}
          ]}]
        }
      } = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(%{name: "jwt", is_enabled: false, settings: %{"signature" => "not_encoded_string"}})
      |> assert_status(422)
      |> get_body()
    end

    test "create duplicates", %{api_id: api_id} do
      jwt_plugin = :jwt_plugin
      |> build_factory_params()

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(jwt_plugin)
      |> assert_status(201)

      actual_result = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(jwt_plugin)
      |> assert_status(422)
      |> get_body()
      |> get_in(["error", "invalid"])

      expected_result = [%{
        "entry" => "$.name",
        "entry_type" => "json_data_property",
        "rules" => [%{
          "description" => "has already been taken",
          "params" => [],
          "rule" => nil # TODO: Fix EView/Ecto to set "unique" in this case
        }]
      }]

      assert expected_result == actual_result
    end
  end

  test "token must be valid", %{api_id: api_id, api_path: api_path} do
    jwt_plugin = :jwt_plugin
    |> build_factory_params(%{settings: %{signature: build_jwt_signature(@jwt_secret)}})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(jwt_plugin)
    |> assert_status(201)

    auth_token = build_jwt_token(%{"scopes" => ["httpbin:read"]}, "a_secret_signature")

    assert %{
      "error" => %{"message" => "Your JWT token is invalid."}
    } = api_path
    |> put_public_url()
    |> get!([{"authorization", "Bearer #{auth_token}"}])
    |> assert_status(422)
    |> get_body()
  end

  test "settings is validated", %{api_id: api_id} do
    jwt_plugin = :jwt_plugin
    |> build_factory_params(%{settings: %{signature: %{}}})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(jwt_plugin)
    |> assert_status(422)
  end
end
