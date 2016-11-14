defmodule Gateway.Acceptance.Plugins.ACLTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  @jwt_secret "secret"

  setup do
    api_path = "/my_jwt_authorized_api-" <> Ecto.UUID.generate() <> "/"
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

    jwt_plugin = :jwt_plugin
    |> build_factory_params(%{settings: %{signature: @jwt_secret}})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(jwt_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    %{api_id: api_id, api_path: api_path}
  end

  test "token MUST have scopes", %{api_id: api_id, api_path: api_path} do
    acl_plugin = :acl_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["GET"], path: "^.*", scopes: ["api:access"]},
      ]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(acl_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    token_without_scopes = build_jwt_token(%{"name" => "Alice"}, @jwt_secret)
    headers = [{"authorization", "Bearer #{token_without_scopes}"}]

    assert %{
      "error" => %{"message" => "Your scopes does not allow to access this resource."}
    } = api_path
    |> put_public_url()
    |> get!(headers)
    |> assert_status(403)
    |> get_body()
  end

  test "token MUST have all scopes", %{api_id: api_id, api_path: api_path} do
    acl_plugin = :acl_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["GET"], path: "^.*", scopes: ["api:access", "api:request"]},
      ]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(acl_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    token = build_jwt_token(%{"scopes" => ["api:access"]}, @jwt_secret)
    headers = [{"authorization", "Bearer #{token}"}]

    assert %{
      "error" => %{"message" => "Your scopes does not allow to access this resource."}
    } = api_path
    |> put_public_url()
    |> get!(headers)
    |> assert_status(403)
    |> get_body()

    token = build_jwt_token(%{"scopes" => ["api:access", "api:request"]}, @jwt_secret)
    headers = [{"authorization", "Bearer #{token}"}]

    api_path
    |> put_public_url()
    |> get!(headers)
    |> assert_status(404)
  end

  test "multiple rules can be applied", %{api_id: api_id, api_path: api_path} do
    acl_plugin = :acl_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["GET", "POST"], path: "^.*", scopes: ["super_scope"]},
        %{methods: ["GET"], path: "^.*", scopes: ["api:access", "api:request"]},
      ]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(acl_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    token = build_jwt_token(%{"scopes" => ["api:access", "api:request"]}, @jwt_secret)
    headers = [{"authorization", "Bearer #{token}"}]

    api_path
    |> put_public_url()
    |> get!(headers)
    |> assert_status(404)
  end

  describe "rules is filtered" do
    test "by method", %{api_id: api_id, api_path: api_path} do
      acl_plugin = :acl_plugin
      |> build_factory_params(%{settings: %{
        rules: [
          %{methods: ["GET", "POST"], path: "^.*", scopes: ["super_scope"]},
          %{methods: ["PUT"], path: "^.*", scopes: ["api:access", "api:request"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      Gateway.AutoClustering.do_reload_config()

      token = build_jwt_token(%{"scopes" => ["api:access", "api:request"]}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      api_path
      |> put_public_url()
      |> get!(headers)
      |> assert_status(403)
    end

    test "by path", %{api_id: api_id, api_path: api_path} do
      acl_plugin = :acl_plugin
      |> build_factory_params(%{settings: %{
        rules: [
          %{methods: ["GET"], path: "^/foo$", scopes: ["super_scope"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      Gateway.AutoClustering.do_reload_config()

      token = build_jwt_token(%{"scopes" => ["super_scope"]}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      "#{api_path}/foo"
      |> put_public_url()
      |> get!(headers)
      |> assert_status(404)
    end
  end

  test "token settings validator", %{api_id: api_id} do
    acl_plugin = :acl_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["OTHER"], path: 123, scopes: "string"},
      ]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(acl_plugin)
    |> assert_status(422)
    |> get_body()
  end
end
