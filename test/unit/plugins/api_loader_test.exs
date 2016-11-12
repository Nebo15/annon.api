defmodule Gateway.Plugins.APILoaderTest do
  @moduledoc false
  use Gateway.UnitCase

  describe "writes config to conn.private" do
    test "with plugins" do
      %{request: request} = api = Gateway.Factory.insert(:api)
      Gateway.Factory.insert(:jwt_plugin, api: api)
      Gateway.Factory.insert(:acl_plugin, api: api)

      Gateway.AutoClustering.do_reload_config()

      %{private: %{api_config: %{} = config}} =
        :get
        |> conn(request.path, Poison.encode!(%{}))
        |> Map.put(:host, request.host)
        |> Map.put(:port, request.port)
        |> Map.put(:method, request.method |> hd())
        |> Map.put(:scheme, request.scheme)
        |> Gateway.Plugins.APILoader.call([])

      assert config.id == api.id
      assert config.request == request
      assert length(config.plugins) == 2
    end

    test "without plugins" do
      %{request: request} = Gateway.Factory.insert(:api)

      Gateway.AutoClustering.do_reload_config()

      %{private: %{api_config: nil}} =
        :get
        |> conn(request.path, Poison.encode!(%{}))
        |> Map.put(:host, request.host)
        |> Map.put(:port, request.port)
        |> Map.put(:method, request.method |> hd())
        |> Map.put(:scheme, request.scheme)
        |> Gateway.Plugins.APILoader.call([])
    end
  end

  describe "find API by request" do
    test "with matching by path" do
      api = Gateway.Factory.insert(:api, %{
        name: "API loader Test api",
        request: Gateway.Factory.build(:request, %{
          method: ["GET"],
          scheme: "http",
          host: "www.example.com",
          port: 80,
          path: "/mockbin",
        })
      })

      Gateway.Factory.insert(:proxy_plugin, %{
        name: "proxy",
        is_enabled: true,
        api: api,
        settings: %{
          strip_request_path: false,
          method: "GET",
          scheme: "http",
          host: "localhost",
          port: 4040,
          path: "/apis"
        }
      })

      Gateway.AutoClustering.do_reload_config()

      assert 404 == call_public_router("/some_path").status
      assert 200 == call_public_router("/mockbin").status
      assert 200 == call_public_router("/mockbin/path").status

      assert "http://localhost:4040/apis/mockbin" == "/mockbin"
      |> call_public_router()
      |> get_from_body(["meta", "url"])

      assert "http://localhost:4040/apis/mockbin/path" == "/mockbin/path"
      |> call_public_router()
      |> get_from_body(["meta", "url"])
    end
  end

  defp get_from_body(response, what_to_get) do
    response
    |> Map.get(:resp_body)
    |> Poison.decode!()
    |> get_in(what_to_get)
  end
end
