defmodule Gateway.SmokeTests.Scenario1 do
  use Gateway.AcceptanceCase

  test "Smoke test: scenario #1" do
    setup_backend()

    api_url = "#{get_host(:public)}:#{get_port(:public)}"

    response =
      "http://#{api_url}/httpbin?my_param=my_value"
      |> HTTPoison.get!
      |> Map.get(:body)
      |> Poison.decode!

    assert "my_value" == response["args"]["my_param"]
  end

  defp setup_backend() do
    {:ok, api} = Gateway.DB.Schemas.API.create(%{
      name: "An HTTPBin service endpoint",
      request: %{
        method: "GET",
        scheme: "http",
        host: "localhost",
        port: get_port(:public),
        path: "/httpbin",
      }
    })

    Gateway.DB.Schemas.Plugin.create(api.id, %{
      name: "proxy",
      is_enabled: true,
      settings: %{
        "method" => "GET",
        "scheme" => "http",
        "host" => "httpbin.org",
        "port" => 80,
        "path" => "/get"
      }
    })

    # Gateway.DB.Schemas.Plugin.create(api.id, %{
    #   name: "proxy",
    #   is_enabled: true,
    #   settings: %{
    #     "method" => "POST",
    #     "scheme" => "http",
    #     "host" => "httpbin.org",
    #     "port" => 80,
    #     "path" => "/"
    #   }
    # })

    Gateway.AutoClustering.do_reload_config()
  end
end
