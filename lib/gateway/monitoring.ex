defmodule Gateway.Monitoring do
  @moduledoc """
    Monitoring data reporting to statsd
"""
  import Plug.Conn
  use Elixometer

  @unit :milli_seconds

  def init(opts) do
        opts
  end

  def call(conn, opts) do
    request_size = headers_size(conn) + body_size(conn) + query_string_size(conn)

    conn.path_info
    |> metric_name("request_size")
    |> update_histogram(request_size)

    conn.path_info
    |> metric_name("request_count")
    |> update_counter(1)

    IO.inspect :exometer_report.list_metrics

    req_start_time = :erlang.monotonic_time(@unit)
    conn = Plug.Conn.register_before_send conn, fn conn ->
      request_duration = :erlang.monotonic_time(@unit) - req_start_time

    conn.request_path
    |> metric_name("latency")
    |> update_histogram(request_duration)

    conn = assign(conn, :latencies_gateway, request_duration)

    conn.request_path
    |> metric_name("status_count_" <> to_string(conn.status))
    |> update_counter(1)
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
    |> Enum.map(fn(x) -> Tuple.to_list(x) end)
    |> List.flatten
    |> Enum.join("")
    |> byte_size
  end

  defp body_size(conn) do
    {:ok, body, conn} = read_body(conn)
    body
    |> byte_size
  end

  defp query_string_size(conn) do
    conn = fetch_query_params(conn)
    conn.query_params
    |> Map.to_list
    |> Enum.map(fn(x) -> Tuple.to_list(x) end)
    |> Enum.join("")
    |> byte_size
  end
end
