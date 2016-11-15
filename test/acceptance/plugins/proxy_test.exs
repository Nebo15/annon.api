defmodule Gateway.Acceptance.Plugins.ProxyTest do
  @moduledoc false
  use Gateway.AcceptanceCase

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
        strip_request_path: "hello",
        additional_headers: "string"
      }})

      "apis/#{api_id}/plugins"
      |> put_management_url()
      |> post!(params)
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

  test "supports additional headers", %{api_id: api_id, api_path: api_path} do
    api_id
    |> create_proxy_to_mock(%{
      additional_headers: [%{"hello" => "world"}]
    })

    assert %{"request" => %{
      "headers" => [%{"hello" => "world"} | _]
    }} = api_path
    |> put_public_url()
    |> get!()
    |> get_body()
    |> get_mock_response()
  end

  test "preserves original headers", %{api_id: api_id, api_path: api_path} do
    api_id
    |> create_proxy_to_mock()

    assert %{"request" => %{
      "headers" => [%{"foo" => "bar"} | _] # There might be issues with headers order in here
    }} = api_path
    |> put_public_url()
    |> get!([{"foo", "bar"}])
    |> get_body()
    |> get_mock_response()
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
    test "when `strip_request_path` is false and proxy path is `/`", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_request_path: false
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert api_path == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}/foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert api_path <> "/foo" == uri
    end

    test "when `strip_request_path` is false and proxy path is not set", %{api_id: api_id, api_path: api_path} do
      api_id
      |> create_proxy_to_mock(%{
        scheme: "http",
        strip_request_path: false
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert api_path == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}/foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert api_path <> "/foo" == uri
    end

    test "when `strip_request_path` is false and proxy path is set", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/proxy"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_request_path: false
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert proxy_path <> api_path == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}/foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert proxy_path <> api_path <> "/foo" == uri
    end

    test "when `strip_request_path` is true and proxy path is /", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_request_path: true
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert "/" == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}/foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert "/foo" == uri
    end

    test "when `strip_request_path` is true and proxy path is not set", %{api_id: api_id, api_path: api_path} do
      api_id
      |> create_proxy_to_mock(%{
        scheme: "http",
        strip_request_path: true
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert "/" == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}/foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert "/foo" == uri
    end

    test "when `strip_request_path` is true and proxy path is set", %{api_id: api_id, api_path: api_path} do
      proxy_path = "/proxy"

      api_id
      |> create_proxy_to_mock(%{
        path: proxy_path,
        scheme: "http",
        strip_request_path: true
      })

      assert %{"request" => %{"uri" => uri}} = api_path
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert proxy_path == uri

      assert %{"request" => %{"uri" => uri}} = "#{api_path}/foo"
      |> put_public_url()
      |> get!()
      |> get_body()
      |> get_mock_response()

      assert proxy_path <> "/foo" == uri
    end
  end
end
