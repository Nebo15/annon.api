defmodule Gateway.Plugins.MonitoringTest do
  @moduledoc false
  use Gateway.UnitCase

  @apis "apis"

  test "metrics work properly" do
    make_connection()
    assert check_statsd("counters", "os.gateway.apis_request_count")
    assert check_statsd("counters", "os.gateway.apis_status_count_200")
    assert check_statsd("timers", "os.gateway.apis_latency")
  end

  defp make_connection do
    api = Gateway.Factory.insert(:api, %{
      name: "Montoring Test api",
      request: Gateway.Factory.build(:request, %{host: "www.example.com", path: "/apis"})
    })

    Gateway.Factory.insert(:proxy_plugin, %{
      name: "proxy",
      is_enabled: true,
      api: api,
      settings: %{
        scheme: "http",
        host: "localhost",
        port: 4040,
        path: "/apis"
      }
    })

    Gateway.AutoClustering.do_reload_config()

    "/apis"
    |> call_public_router()
  end

  defp check_statsd(metric_type, metric_name) do
    {:ok, socket} = :gen_tcp.connect('localhost', 8126, [:list, {:active, false}])
    :ok = :gen_tcp.send(socket, metric_type)

    :timer.sleep(100)

    socket
    |> :gen_tcp.recv(0)
    |> elem(1)
    |> to_string
    |> String.contains?(metric_name)
  end
end
