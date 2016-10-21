defmodule Gateway.Monitoring.ElixometerTest do
  use ExUnit.Case, async: false
  use Gateway.UnitCase

  @apis "apis"

  setup do
    :ok
  end

  test "metrics work properly" do
    make_connection()
    assert check_statsd("counters", "os.gateway.apis_request_count")
    assert check_statsd("counters", "os.gateway.apis_status_count_200")
    assert check_statsd("timers", "os.gateway.apis_latency")
  end

  defp make_connection do
    :get
    |> conn("/apis")
    |> put_req_header("content-type", "application/json")
    |> Gateway.PrivateRouter.call([])

    :timer.sleep(50)
  end

  defp check_statsd(metric_type, metric_name) do
    {:ok, socket} = :gen_tcp.connect('localhost', 8126, [:list, {:active, false}])
    :ok = :gen_tcp.send(socket, metric_type)
    {:ok, _ = response} = :gen_tcp.recv(socket, 0)
    response = List.to_string(response)
    String.contains?(response, metric_name)
  end
end
