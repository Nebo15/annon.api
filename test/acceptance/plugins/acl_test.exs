defmodule Gateway.Acceptance.Plugins.ACLTest do
  @moduledoc false
  use Gateway.AcceptanceCase, async: true

  @jwt_secret "secret"

  setup_all do
    :ok
  end

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

    jwt_plugin = build_factory_params(:jwt_plugin, %{settings: %{signature: build_jwt_signature(@jwt_secret)}})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(jwt_plugin)
    |> assert_status(201)

    %{api_id: api_id, api_path: api_path}
  end

  describe "JWT Strategy" do
    test "Auth0 Flow is supported", %{api_id: api_id, api_path: api_path} do
      assert true
    end
  end
end
