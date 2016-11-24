defmodule Gateway.Acceptance.Plugins.JWTTest do
  @moduledoc false
  use Gateway.AcceptanceCase

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
    |> assert_status(401)
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
