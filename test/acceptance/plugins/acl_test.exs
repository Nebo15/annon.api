defmodule Annon.Acceptance.Plugins.ACLTest do
  @moduledoc false
  use Annon.AcceptanceCase

  setup do
    api_path = "/my_jwt_authorized_api-" <> Ecto.UUID.generate() <> "/"
    api_settings = %{
      request: %{
        methods: ["GET", "POST", "PUT", "DELETE"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: api_path
      }
    }
    api = :api
    |> build_factory_params(api_settings)
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    auth_plugin = :auth_plugin_with_jwt
    |> build_factory_params()

    secret = Base.decode64!(auth_plugin.settings["secret"])

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(auth_plugin)
    |> assert_status(201)

    %{api_id: api_id, api_path: api_path, secret: secret}
  end

  describe "JWT Strategy" do
    test "Auth0 Flow is supported", %{api_id: api_id, api_path: api_path, secret: secret} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^.*", scopes: ["api:access"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      token_data = %{
        "app_metadata" => %{"consumer_id" => "bob", "consumer_scope" => ["api:access"]},
        "aud" => "wQjijHbg3UszGURQKIshwi03ho4NcVKl",
        "iat" => 1479225057,
        "iss" => "https://nebo15.eu.auth0.com/",
        "sub" => "auth0|582a0e210e8ef1fa16b4a4b0"
      }
      token = build_jwt_token(token_data, secret)
      headers = [{"authorization", "Bearer #{token}"}]

      api_path
      |> put_public_url()
      |> get!(headers)
      |> assert_status(404)
      |> get_body()
    end

    test "Auth0 Flow is supported when scopes is string", %{api_id: api_id, api_path: api_path, secret: secret} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^.*", scopes: ["api:access"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      token_data = %{
        "app_metadata" => %{"consumer_id" => "bob", "consumer_scope" => "api:access api:delete"},
        "aud" => "wQjijHbg3UszGURQKIshwi03ho4NcVKl",
        "iat" => 1479225057,
        "iss" => "https://nebo15.eu.auth0.com/",
        "sub" => "auth0|582a0e210e8ef1fa16b4a4b0"
      }
      token = build_jwt_token(token_data, secret)
      headers = [{"authorization", "Bearer #{token}"}]

      api_path
      |> put_public_url()
      |> get!(headers)
      |> assert_status(404)
      |> get_body()
    end

    test "token MUST have scopes", %{api_id: api_id, api_path: api_path, secret: secret} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^.*", scopes: ["api:access"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      token_without_scopes = build_jwt_token(%{"name" => "Alice"}, secret)
      headers = [{"authorization", "Bearer #{token_without_scopes}"}]

      response = api_path
      |> put_public_url()
      |> get!(headers)
      |> get_body()

      assert 401 == response["meta"]["code"]
      assert "JWT token does not contain Consumer ID" == response["error"]["message"]
    end
  end
end
