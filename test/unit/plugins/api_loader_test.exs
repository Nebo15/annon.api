defmodule Annon.Plugins.APILoaderTest do
  @moduledoc false
  use Annon.UnitCase

  describe "ETS adapter is working" do
    setup do
      saved_config = Application.get_env(:annon_api, :cache_storage)
      Application.put_env(:annon_api, :cache_storage, {:system, :module, "CACHE_STORAGE", Annon.Cache.EtsAdapter})

      on_exit fn ->
        Application.put_env(:annon_api, :cache_storage, saved_config)
      end
      %{request: request} = api = Annon.Factory.insert(:api)
      Annon.Factory.insert(:jwt_plugin, api: api)
      Annon.Factory.insert(:acl_plugin, api: api)

      {:ok, %{request: request, api: api}}
    end

    test "succesffully reads from ETS storage", %{request: request, api: api} do
      Annon.AutoClustering.do_reload_config()

      %{private: %{api_config: %{} = config}} =
        :get
        |> conn(request.path, Poison.encode!(%{}))
        |> Map.put(:host, request.host)
        |> Map.put(:port, request.port)
        |> Map.put(:method, request.methods |> hd())
        |> Map.put(:scheme, request.scheme)
        |> Annon.Plugins.APILoader.call([])

      assert config.id == api.id
      assert config.request == request
      assert length(config.plugins) == 2
    end

    test "succesffully reads from ETS storage when host is '*'", %{request: request, api: api} do
      %{request: new_request} = new_api = Annon.Factory.insert(:api, %{
        request: Annon.Factory.build(:api_request, %{
          host: "*",
        })
      })
      Annon.Factory.insert(:jwt_plugin, api: new_api)

      Annon.AutoClustering.do_reload_config()

      %{private: %{api_config: %{} = config}} =
        :get
        |> conn(request.path, Poison.encode!(%{}))
        |> Map.put(:host, request.host)
        |> Map.put(:port, new_request.port)
        |> Map.put(:method, new_request.methods |> Kernel.hd())
        |> Map.put(:scheme, new_request.scheme)
        |> Annon.Plugins.APILoader.call([])

      assert config.id == api.id
      assert config.request == request
      assert length(config.plugins) == 2


      %{private: %{api_config: %{} = config}} =
        :get
        |> conn(request.path, Poison.encode!(%{}))
        |> Map.put(:host, "some_other_host")
        |> Map.put(:port, new_request.port)
        |> Map.put(:method, new_request.methods |> Kernel.hd())
        |> Map.put(:scheme, new_request.scheme)
        |> Annon.Plugins.APILoader.call([])

      assert config.id == new_api.id
      assert config.request == new_request
      assert length(config.plugins) == 1
    end
  end

  describe "writes config to conn.private" do
    test "with plugins" do
      %{request: request} = api = Annon.Factory.insert(:api)
      Annon.Factory.insert(:jwt_plugin, api: api)
      Annon.Factory.insert(:acl_plugin, api: api)

      %{private: %{api_config: %{} = config}} =
        :get
        |> conn(request.path, Poison.encode!(%{}))
        |> Map.put(:host, request.host)
        |> Map.put(:port, request.port)
        |> Map.put(:method, request.methods |> hd())
        |> Map.put(:scheme, request.scheme)
        |> Annon.Plugins.APILoader.call([])

      assert config.id == api.id
      assert config.request == request
      assert length(config.plugins) == 2
    end

    test "without plugins" do
      %{request: request} = Annon.Factory.insert(:api)

      %{private: %{api_config: nil}} =
        :get
        |> conn(request.path, Poison.encode!(%{}))
        |> Map.put(:host, request.host)
        |> Map.put(:port, request.port)
        |> Map.put(:method, request.methods |> hd())
        |> Map.put(:scheme, request.scheme)
        |> Annon.Plugins.APILoader.call([])
    end
  end

  describe "find API by request" do
    test "with matching by path" do
      api = Annon.Factory.insert(:api, %{
        name: "API loader Test api",
        request: Annon.Factory.build(:api_request, %{
          methods: ["GET"],
          scheme: "http",
          host: "www.example.com",
          port: 80,
          path: "/mockbin",
        })
      })

      Annon.Factory.insert(:proxy_plugin, %{
        name: "proxy",
        is_enabled: true,
        api: api,
        settings: %{
          strip_api_path: false,
          method: "GET",
          scheme: "http",
          host: "localhost",
          port: 4040,
          path: "/apis"
        }
      })

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

    test "with matching by overrided host" do
      api = Annon.Factory.insert(:api, %{
        name: "API loader Test api",
        request: Annon.Factory.build(:api_request, %{
          methods: ["GET"],
          scheme: "http",
          host: "www.example.com",
          port: 80,
          path: "/mockbin",
        })
      })

      Annon.Factory.insert(:proxy_plugin, %{
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

      resp = :get
      |> conn("/mockbin")
      |> put_req_header("content-type", "application/json")
      |> Map.put(:host, "other_host")
      |> Annon.PublicRouter.call([])

      assert 404 == resp.status

      resp = :get
      |> conn("/mockbin")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-host-override", "www.example.com")
      |> Map.put(:host, "other_host")
      |> Annon.PublicRouter.call([])

      assert 200 == resp.status
    end
  end

  defp get_from_body(response, what_to_get) do
    response
    |> Map.get(:resp_body)
    |> Poison.decode!()
    |> get_in(what_to_get)
  end
end
