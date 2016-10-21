defmodule Gateway.Plugins.Monitoring do
  @moduledoc """
  Monitoring data reporting to statsd
  """
  import Plug.Conn

  @unit :milli_seconds

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    request_size = headers_size(conn) + body_size(conn) + query_string_size(conn)

    metric_name = conn.path_info
    |> metric_name("request_size")

    ExStatsD.histogram(request_size, metric_name)

    conn.path_info
    |> metric_name("request_count")
    |> ExStatsD.increment

    req_start_time = :erlang.monotonic_time(@unit)
    Plug.Conn.register_before_send conn, fn conn ->
      request_duration = :erlang.monotonic_time(@unit) - req_start_time

      metric_name = conn.request_path
      |> metric_name("latency")

      request_duration
      |> ExStatsD.timer(metric_name)

      conn = assign(conn, :latencies_gateway, request_duration)

      conn.request_path
      |> metric_name("status_count_" <> to_string(conn.status))
      |> ExStatsD.increment

      conn
    end
  end

  defp metric_name(path, type) when is_list(path) do
    data = path
    |> Enum.join("_")

    data <> "_" <> type
  end

  defp metric_name(path, type) when is_bitstring(path) do
    data = path
    |> String.split("/")
    |> Enum.drop_while(fn(x) -> String.length(x) == 0 end)
    |> Enum.join("_")

    data <> "_" <> type
  end

  defp headers_size(conn) do
    conn.req_headers
    |> Enum.map(&Tuple.to_list(&1))
    |> List.flatten
    |> Enum.join
    |> byte_size
  end

  defp body_size(conn) do
    conn
    |> read_body
    |> elem(1)
    |> byte_size
  end

  defp query_string_size(conn) do
    conn
    |> Map.get(:query_string)
    |> byte_size
  end
end
