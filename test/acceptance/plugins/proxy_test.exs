defmodule Annon.Acceptance.Plugins.ProxyTest do
  @moduledoc false
  use Annon.AcceptanceCase, async: true

  setup do
    api_path = "/my_proxied_api-" <> Ecto.UUID.generate() <> "/"

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

    %{api_id: api_id, api_path: api_path, api: api}
  end

  describe "Proxy Plugin" do
    test "create", %{api_id: api_id} do
      proxy = :proxy_plugin
      |> build_factory_params(%{settings: %{host: "host.com"}})

      "apis/#{api_id}/plugins/proxy"
      |> put_management_url()
      |> put!(%{"plugin" => proxy})
      |> assert_status(201)

      %{
        "data" => [%{
          "name" => "proxy",
          "api_id" => ^api_id
        }
      ]} = "apis/#{api_id}/plugins"
      |> put_management_url()
      |> get!()
      |> get_body()
    end

    test "create with invalid settings", %{api_id: api_id} do
      "apis/#{api_id}/plugins/proxy"
      |> put_management_url()
      |> put!(%{"plugin" => %{}})
      |> assert_status(422)

      "apis/#{api_id}/plugins/proxy"
      |> put_management_url()
      |> put!(%{"plugin" => build_invalid_plugin("proxy")})
      |> assert_status(422)

      %{
        "error" => %{
          "invalid" => [
            %{"entry" => "$.settings.host", "rules" => [%{"rule" => "schemata"}]},
            %{"entry" => "$.settings.path", "rules" => [%{"rule" => "cast"}]},
          ]
        }
      } = "apis/#{api_id}/plugins/proxy"
      |> put_management_url()
      |> put!(%{"plugin" => %{name: "proxy", is_enabled: false, settings: %{host: "localhost", path: 100}}})
      |> assert_status(422)
      |> get_body()
    end
  end

  describe "proxy settings validator" do
    test "allows only host and port", %{api_id: api_id, api_path: api_path} do
      api_id
      |> create_proxy_to_mock()

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert api_path == uri
    end

    test "validates data", %{api_id: api_id} do
      params = :proxy_plugin
      |> build_factory_params(%{settings: %{
        path: 123,
        scheme: "httpd",
        strip_api_path: "hello",
        additional_headers: "string"
      }})

      "apis/#{api_id}/plugins/proxy"
      |> put_management_url()
      |> put!(%{"plugin" => params})
      |> assert_status(422) # TODO: Check response structure. And it should have ALL errors, not first one!
    end
  end

  describe "preserves HTTP method, body and query params" do
    test "GET", %{api_id: api_id, api_path: api_path} do
      api_id
      |> create_proxy_to_mock()

      assert %{"request" => %{
        "method" => "GET",
        "query" => %{"hello" => "world"}
      }} = "#{api_path}?hello=world"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()
    end

    test "POST", %{api_id: api_id, api_path: api_path} do
      api_id
      |> create_proxy_to_mock()

      assert %{"request" => %{
        "method" => "POST",
        "body" => %{"foo" => "bar"},
        "query" => %{"hello" => "world"}
      }} = "#{api_path}?hello=world"
      |> put_public_url()
      |> post!(%{foo: "bar"})
      |> get_body()
      |> get_mock_response()
    end

    test "PUT", %{api_id: api_id, api_path: api_path} do
      api_id
      |> create_proxy_to_mock()

      assert %{"request" => %{
        "method" => "PUT",
        "body" => %{"foo" => "bar"},
        "query" => %{"hello" => "world"}
      }} = "#{api_path}?hello=world"
      |> put_public_url()
      |> put!(%{foo: "bar"})
      |> get_body()
      |> get_mock_response()
    end

    test "DELETE", %{api_id: api_id, api_path: api_path} do
      api_id
      |> create_proxy_to_mock()

      assert %{"request" => %{
        "method" => "DELETE",
        "query" => %{"hello" => "world"}
      }} = "#{api_path}?hello=world"
      |> put_public_url()
      |> delete!()
      |> get_body()
      |> get_mock_response()
    end
  end

  test "works when upstream does not exist", %{api_id: api_id, api_path: api_path} do
    proxy = :proxy_plugin
    |> build_factory_params(%{settings: %{host: "exampleabcdewqasdftrewq-does-not-exist.com"}})

    "apis/#{api_id}/plugins/proxy"
    |> put_management_url()
    |> put!(%{"plugin" => proxy})
    |> assert_status(201)

    %{
      "message" => "Upstream is unavailable with reason :nxdomain",
      "type" => "upstream_error"
    } = api_path
    |> put_public_url()
    |> get!()
    |> assert_status(502)
    |> get_body()
  end

  test "supports additional headers", %{api_id: api_id, api_path: api_path} do
    api_id
    |> create_proxy_to_mock(%{
      additional_headers: [%{"hello" => "world"}]
    })

    assert %{"request" => %{
      "headers" => headers
    }} = api_path
    |> put_public_url()
    |> get!()
    |> get_body()
    |> get_mock_response()

    assert %{"hello" => "world"} in headers
  end

  test "preserves original headers", %{api_id: api_id, api_path: api_path} do
    api_id
    |> create_proxy_to_mock()

    assert %{"request" => %{
      "headers" => headers
    }} = api_path
    |> put_public_url()
    |> get!([{"foo", "bar"}])
    |> get_body()
    |> get_mock_response()

    assert %{"foo" => "bar"} in headers
  end

  test "returns upstream headers", %{api_id: api_id, api_path: api_path} do
    api_id
    |> create_proxy_to_mock()

    assert %{headers: headers} = api_path
    |> put_public_url()
    |> get!()

    assert Enum.find(headers, fn
      {"server", "Cowboy"} -> true
      _ -> false
    end)
  end

  describe "builds valid upstream path" do
    test "when `strip_api_path` is false and proxy path is `/`", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_api_path: false
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert api_path == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert api_path <> "foo" == uri
    end

    test "when `strip_api_path` is false and proxy path is not set", %{api_id: api_id, api_path: api_path} do
      api_id
      |> create_proxy_to_mock(%{
        scheme: "http",
        strip_api_path: false
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert api_path == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert api_path <> "foo" == uri
    end

    test "when `strip_api_path` is false and proxy path is set", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/proxy"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_api_path: false
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert proxy_path <> api_path == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert proxy_path <> api_path <> "foo" == uri
    end

    test "when `strip_api_path` is true and proxy path is /", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_api_path: true
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert "/" == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert "/foo" == uri
    end

    test "when `strip_api_path` is true and proxy path is not set", %{api_id: api_id, api_path: api_path} do
      api_id
      |> create_proxy_to_mock(%{
        scheme: "http",
        strip_api_path: true
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert "/" == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert "/foo" == uri
    end

    test "when `strip_api_path` is true and proxy path is set", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/proxy"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_api_path: true
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert proxy_path == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert proxy_path <> "foo" == uri
    end
  end

  describe "additional headers" do
    test "x-consumer-id and x-consumer-scope are set correctly", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/proxy"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_api_path: true
      })

      auth_plugin = :auth_plugin_with_jwt
      |> build_factory_params()

      secret = Base.decode64!(auth_plugin.settings["secret"])

      "apis/#{api_id}/plugins/auth"
      |> put_management_url()
      |> put!(%{"plugin" => auth_plugin})
      |> assert_status(201)

      expected_scopes = ["scope1", "scope2"]
      expected_consumer_id = "random_consumer_id"

      token_data = %{
        "app_metadata" => %{
          "consumer_id" => expected_consumer_id,
          "consumer_scope" => Enum.join(expected_scopes, " ")
        }
      }
      token = build_jwt_token(token_data, secret)
      headers = [{"authorization", "Bearer #{token}"}]

      headers =
        api_path
        |> put_public_url()
        |> get!(headers)
        |> get_body()
        |> get_in(["data", "request", "headers"])

      actual_scope =
        headers
        |> Enum.filter(fn(x) -> Map.has_key?(x, "x-consumer-scope") end)
        |> Enum.map(&(Map.get(&1, "x-consumer-scope")))
        |> Enum.at(0)
        |> String.split(" ")

      assert expected_scopes == actual_scope

      actual_party_id =
        headers
        |> Enum.filter(fn(x) -> Map.has_key?(x, "x-consumer-id") end)
        |> Enum.map(&(Map.get(&1, "x-consumer-id")))
        |> Enum.at(0)

      assert expected_consumer_id == actual_party_id
    end

    test "protected headers cannot be overridden", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/proxy"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_api_path: true
      })

      protected_headers = Confex.get_env(:annon_api, :protected_headers)

      headers = Enum.map(protected_headers, fn x -> {x, "111"} end)

      headers = api_path
      |> put_public_url()
      |> get!(headers)
      |> get_body()
      |> get_in(["data", "request", "headers"])

      assert "" ==
        headers
        |> Enum.filter(fn x -> Enum.at(Map.keys(x), 0) in protected_headers end)
        |> Enum.map(&(Map.get(&1, Enum.at(Map.keys(&1), 0))))
        |> Enum.join("")
    end
  end
end
