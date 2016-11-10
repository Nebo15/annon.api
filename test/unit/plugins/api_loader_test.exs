defmodule Gateway.Plugins.APILoaderTest do
  @moduledoc """
  Testing Gateway.Plugins.APILoader
  """

  use Gateway.UnitCase
  alias Gateway.DB.Schemas.API, as: APISchema

  test "correctly set config into private part" do

    data = get_api_model_data()
    {:ok, %APISchema{request: request} = model} = APISchema.create(data)

    Gateway.AutoClustering.do_reload_config()

    %{private: %{api_config: %{} = config}} = :get
    |> conn(request.path, Poison.encode!(%{}))
    |> Map.put(:host, request.host)
    |> Map.put(:port, request.port)
    |> Map.put(:method, request.method)
    |> Map.put(:scheme, request.scheme)
    |> Gateway.Plugins.APILoader.call(%{})

    assert config.id == model.id
    assert config.request == request
    assert length(config.plugins) == 2
  end

  test "matching API by path" do
    {:ok, api} = create_api_endpoint(false)
    create_proxy_plugin(api)
    Gateway.AutoClustering.do_reload_config()

    assert 404 == make_call("/some_path").status
    assert 200 == make_call("/mockbin").status
    assert 200 == make_call("/mockbin/path").status

    assert "http://localhost:5001/apis" == get_from_body(make_call("/mockbin"), ["meta", "url"])
    assert "http://localhost:5001/apis" == get_from_body(make_call("/mockbin/path"), ["meta", "url"])
  end

  defp get_from_body(response, what_to_get) do
    response
    |> Map.get(:resp_body)
    |> Poison.decode!()
    |> get_in(what_to_get)
  end

  defp make_call(path) do
    :get
    |> conn(path)
    |> put_req_header("content-type", "application/json")
    |> Gateway.PublicRouter.call([])
  end

  defp create_api_endpoint(strip_request_path) do
    Gateway.DB.Schemas.API.create(%{
      name: "Montoring Test api",
      strip_request_path: strip_request_path,
      request: %{
        method: ["GET"],
        scheme: "http",
        host: "www.example.com",
        port: 80,
        path: "/mockbin",
      }
    })
  end

  defp create_proxy_plugin(api) do
    Gateway.DB.Schemas.Plugin.create(api.id, %{
      name: "proxy",
      is_enabled: true,
      settings: %{
        "method" => "GET",
        "scheme" => "http",
        "host" => "localhost",
        "port" => 5001,
        "path" => "/apis"
      }
    })
  end
end
