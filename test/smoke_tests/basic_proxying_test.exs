defmodule Gateway.SmokeTests.BasicProxy do
  use Gateway.AcceptanceCase

  setup do
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

    :ok
  end

  test "A request from user reaches upstream" do
    api_endpoint = "#{get_host(:public)}:#{get_port(:public)}"

    response =
      "http://#{api_endpoint}/httpbin?my_param=my_value"
      |> HTTPoison.get!
      |> Map.get(:body)
      |> Poison.decode!

    assert "my_value" == response["args"]["my_param"]
  end
end
