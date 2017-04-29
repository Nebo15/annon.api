defmodule Annon.Acceptance.Plugins.ACLTest do
  @moduledoc false
  use Annon.AcceptanceCase

  @jwt_secret "secret"

  setup_all do
    pcm_mock_port = Confex.get_map(:gateway, :acceptance)[:pcm_mock][:port]
    {:ok, _} = Plug.Adapters.Cowboy.http Annon.PCMMockServer, [], port: pcm_mock_port
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
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^.*", scopes: ["api:access"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      scopes_plugin = build_factory_params(:scopes_plugin, %{settings: %{"strategy": "jwt"}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(scopes_plugin)
      |> assert_status(201)

      token_data = %{
        "app_metadata" => %{"scopes" => ["api:access"]},
        "aud" => "wQjijHbg3UszGURQKIshwi03ho4NcVKl",
        "iat" => 1479225057,
        "iss" => "https://nebo15.eu.auth0.com/",
        "sub" => "auth0|582a0e210e8ef1fa16b4a4b0"
      }
      token = build_jwt_token(token_data, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      api_path
      |> put_public_url()
      |> get!(headers)
      |> assert_status(404)
      |> get_body()
    end

    test "Auth0 Flow is supported when scopes is string", %{api_id: api_id, api_path: api_path} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^.*", scopes: ["api:access"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      scopes_plugin = build_factory_params(:scopes_plugin, %{settings: %{"strategy": "jwt"}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(scopes_plugin)
      |> assert_status(201)

      token_data = %{
        "app_metadata" => %{"scopes" => "api:access,api:delete"},
        "aud" => "wQjijHbg3UszGURQKIshwi03ho4NcVKl",
        "iat" => 1479225057,
        "iss" => "https://nebo15.eu.auth0.com/",
        "sub" => "auth0|582a0e210e8ef1fa16b4a4b0"
      }
      token = build_jwt_token(token_data, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      api_path
      |> put_public_url()
      |> get!(headers)
      |> assert_status(404)
      |> get_body()
    end

    test "token MUST have scopes", %{api_id: api_id, api_path: api_path} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^.*", scopes: ["api:access"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      scopes_plugin = build_factory_params(:scopes_plugin, %{settings: %{"strategy": "jwt"}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(scopes_plugin)
      |> assert_status(201)

      token_without_scopes = build_jwt_token(%{"name" => "Alice"}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token_without_scopes}"}]

      response = api_path
      |> put_public_url()
      |> get!(headers)
      |> get_body()

      assert 501 == response["meta"]["code"]
    end

    test "token MUST have all scopes", %{api_id: api_id, api_path: api_path} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^.*", scopes: ["api:access", "api:request"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      scopes_plugin = build_factory_params(:scopes_plugin, %{settings: %{"strategy": "jwt"}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(scopes_plugin)
      |> assert_status(201)

      token = build_jwt_token(%{"scopes" => ["api:access"]}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      response = api_path
      |> put_public_url()
      |> get!(headers)
      |> get_body()

      assert 403 == response["meta"]["code"]
      assert "Your scopes does not allow to access this resource. Missing scopes: api:request."
        = response["error"]["message"]

      token = build_jwt_token(%{"scopes" => ["api:access", "api:request"]}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      api_path
      |> put_public_url()
      |> get!(headers)
      |> assert_status(404)
    end

    test "multiple rules can be applied", %{api_id: api_id, api_path: api_path} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET", "POST"], path: "^.*", scopes: ["super_scope"]},
          %{methods: ["GET"], path: "^.*", scopes: ["api:access", "api:request"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      scopes_plugin = build_factory_params(:scopes_plugin, %{settings: %{"strategy": "jwt"}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(scopes_plugin)
      |> assert_status(201)

      token = build_jwt_token(%{"scopes" => ["api:access", "api:request"]}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      api_path
      |> put_public_url()
      |> get!(headers)
      |> assert_status(404)
    end

    test "rules is filtered by method", %{api_id: api_id, api_path: api_path} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET", "POST"], path: "^.*", scopes: ["super_scope"]},
          %{methods: ["PUT"], path: "^.*", scopes: ["api:access", "api:request"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      scopes_plugin = build_factory_params(:scopes_plugin, %{settings: %{"strategy": "jwt"}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(scopes_plugin)
      |> assert_status(201)

      token = build_jwt_token(%{"scopes" => ["api:access", "api:request"]}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      api_path
      |> put_public_url()
      |> get!(headers)
      |> assert_status(403)
    end

    test "rules is filtered by path", %{api_id: api_id, api_path: api_path} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^/foo$", scopes: ["super_scope"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      scopes_plugin = build_factory_params(:scopes_plugin, %{settings: %{"strategy": "jwt"}})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(scopes_plugin)
      |> assert_status(201)

      token = build_jwt_token(%{"scopes" => ["super_scope"]}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      "#{api_path}/foo"
      |> put_public_url()
      |> get!(headers)
      |> assert_status(404)
    end

    test "token settings validator", %{api_id: api_id} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
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

  describe "PCM Strategy" do
    test "Auth0 Flow is supported", %{api_id: api_id, api_path: api_path} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^/foo$", scopes: ["api:access"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      pcm_mock_host = Confex.get_map(:gateway, :acceptance)[:pcm_mock][:host]
      pcm_mock_port = Confex.get_map(:gateway, :acceptance)[:pcm_mock][:port]

      scopes_plugin = build_factory_params(:scopes_plugin, %{
        settings: %{
          "strategy": "pcm",
          "url_template": "http://#{pcm_mock_host}:#{pcm_mock_port}/scopes"
        }
      })

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(scopes_plugin)
      |> assert_status(201)

      token = build_jwt_token(%{"app_metadata" => %{"party_id" => "random_party_id"}}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      "#{api_path}/foo"
      |> put_public_url()
      |> get!(headers)
      |> assert_status(404)
    end

    test "Empty scopes", %{api_id: api_id, api_path: api_path} do
      acl_plugin = build_factory_params(:acl_plugin, %{settings: %{
        rules: [
          %{methods: ["GET"], path: "^/foo$", scopes: ["api:access"]},
        ]
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(acl_plugin)
      |> assert_status(201)

      pcm_mock_host = Confex.get_map(:gateway, :acceptance)[:pcm_mock][:host]
      pcm_mock_port = Confex.get_map(:gateway, :acceptance)[:pcm_mock][:port]

      scopes_plugin = build_factory_params(:scopes_plugin, %{
        settings: %{
          "strategy": "pcm",
          "url_template": "http://#{pcm_mock_host}:#{pcm_mock_port}/empty_scopes"
        }
      })

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(scopes_plugin)
      |> assert_status(201)

      token = build_jwt_token(%{"app_metadata" => %{"party_id" => "random_party_id"}}, @jwt_secret)
      headers = [{"authorization", "Bearer #{token}"}]

      expected_result = "Your scopes does not allow to access this resource. Missing scopes: api:access."

      actual_result = "#{api_path}/foo"
      |> put_public_url()
      |> get!(headers)
      |> assert_status(403)
      |> get_body()
      |> get_in(["error", "message"])

      assert expected_result == actual_result
    end
  end
end
