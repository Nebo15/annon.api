defmodule Gateway.SmokeTests.Scenario1 do
  use Gateway.AcceptanceCase

  test "Smoke test: scenario #1" do
    setup_backend()

    response = HTTPoison.get("http://#{get_host(:public)}:#{get_port(:public)}/httpbin")
    |> IO.inspect

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

    Gateway.AutoClustering.do_reload_config()

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
  end
end

