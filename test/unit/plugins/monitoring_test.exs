defmodule Gateway.MonitoringTest do
  use ExUnit.Case
  use Gateway.UnitCase

  @apis "apis"

  test "metrics work properly" do
    make_connection()
    assert check_statsd("counters", "os.gateway.apis_request_count")
    assert check_statsd("counters", "os.gateway.apis_status_count_200")
    assert check_statsd("timers", "os.gateway.apis_latency")
  end

  defp make_connection do
    { :ok, api } = create_api_endpoint()
    create_proxy_plugin(api)

    :get
    |> conn("/apis")
    |> put_req_header("content-type", "application/json")
    |> Gateway.PublicRouter.call([])

    :timer.sleep(50)
  end

  defp check_statsd(metric_type, metric_name) do
    {:ok, socket} = :gen_tcp.connect('localhost', 8126, [:list, {:active, false}])
    :ok = :gen_tcp.send(socket, metric_type)

    socket
    |> :gen_tcp.recv(0)
    |> elem(1)
    |> to_string
    |> String.contains?(metric_name)
  end

  defp create_api_endpoint do
    Gateway.DB.Models.API.create(%{
      name: "Test api",
      request: %{
        method: "GET",
        scheme: "http",
        host: "www.example.com",
        port: 80,
        path: "/apis",
      }
    })
  end

  defp create_proxy_plugin(api) do
    Gateway.DB.Models.Plugin.create(api, %{
    name: "Proxy",
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
