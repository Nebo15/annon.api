defmodule Gateway.Plugins.MonitoringTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  test "metrics work properly" do
    make_connection()
    assert check_statsd("counters", "os.gateway.get_request_count")
    assert check_statsd("counters", "os.gateway.get_status_count_200")
    assert check_statsd("timers", "os.gateway.get_latency")
  end

  defp make_connection do
    api = Gateway.Factory.insert(:api, %{
      name: "Montoring Test api",
      request: %{
        methods: ["GET"],
        host: "localhost",
        port: 5000,
        scheme: "http",
        path: "/"
      }
    })

    Gateway.Factory.insert(:proxy_plugin, %{
      api: api,
      name: "proxy",
      is_enabled: true,
      settings: %{
        scheme: "http",
        host: "httpbin.org",
        port: 80,
        path: "/"
      }
    })

    Gateway.AutoClustering.do_reload_config()

    HTTPoison.get("#{get_public_url()}/get")
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
