defmodule Gateway.Plugins.MonitoringTest do
  @moduledoc false
  use Gateway.UnitCase, async: true

  test "metrics work properly" do
    make_connection()
    assert check_statsd("counters", "os.gateway.request_count")
    assert check_statsd("counters", "os.gateway.status_count")
    assert check_statsd("timers", "os.gateway.latency")
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

    "/apis"
    |> call_public_router()
  end

  defp check_statsd(metric_type, metric_name) do
    {:ok, socket} = :gen_tcp.connect('localhost', 8126, [:list, {:active, false}])
    :ok = :gen_tcp.send(socket, metric_type)

    socket
    |> gather_result()
    |> String.contains?(metric_name)
  end

  def gather_result(socket, acc \\ "")
  def gather_result(socket, acc) do
    {:ok, data} = :gen_tcp.recv(socket, 0)

    result = acc <> to_string(data)

    cond do
      String.ends_with?(result, "END\n\n") -> result
      true -> gather_result(socket, result)
    end
  end
end
