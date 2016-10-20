defmodule Gateway.Monitoring.ElixometerTest do
  use ExUnit.Case, async: false
  use Gateway.HTTPTestHelper

  use Elixometer
  alias Gateway.Monitoring.TestReporter, as: Reporter

  @apis "apis"

  setup do
    :ok
  end

  defp wait_for_messages do
    :timer.sleep 10
  end

  test "metrics work properly" do
    make_connection()
    assert {:ok, [value: 1, ms_since_reset: _]} =
      Elixometer.get_metric_value("os.gateway.test.counters.apis_request_count")
    make_connection()
    assert {:ok, [value: 2, ms_since_reset: _]} =
      Elixometer.get_metric_value("os.gateway.test.counters.apis_status_count_200")
    make_connection()
    IO.inspect Reporter.metric_names
    assert {:ok, _} =
      Elixometer.get_metric_value("os.gateway.test.histograms.apis_request_size")
    make_connection()
    assert {:ok, _} =
      Elixometer.get_metric_value("os.gateway.test.histograms.apis_latency")
  end

  defp make_connection do
    :get
    |> conn("/apis")
    |> put_req_header("content-type", "application/json")
    |> Gateway.Router.call([])

    :timer.sleep(50)
  end
end
