defmodule Gateway.Monitoring.ElixometerTest do
  use ExUnit.Case
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

  defp to_elixometer_name(metric_name) when is_bitstring(metric_name) do
    metric_name
    |> String.split(".")
    |> Enum.map(&String.to_atom/1)
  end

  def metric_exists(metric_name) when is_bitstring(metric_name) do
    metric_name |> to_elixometer_name |> metric_exists
  end

  def metric_exists(metric_name) when is_list(metric_name) do
    wait_for_messages
    metric_name in Reporter.metric_names
  end

  test "a gauge registers its name" do
#    update_gauge("register", 10)

    conn = :get
    |> conn("/")
    |> put_req_header("content-type", "application/json")
    |> Gateway.HTTP.API.call([])

    assert metric_exists Confex.get(:elixometer, :metric_prefix) <> "." <> to_string(Confex.get(:elixometer, :env)) <>
                                                                    ".counters." <> @apis <> "_request_count.value"
  end
end
