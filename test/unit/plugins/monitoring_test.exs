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
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        string = to_string(data)

        cond do
          String.ends_with?(string, "END\n\n") -> acc <> string
          true -> gather_result(socket, acc <> string)
        end
      {:error, :closed} ->
        to_string(acc)
    end
  end
end
