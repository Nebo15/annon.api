defmodule Gateway.Plugins.Monitoring do
  @moduledoc """
  This plugin measures or receives performance metrics from other parts of Annon and sends them to StatsD server.

  It is enabled by default and can not be disabled without rebuilding Annon container.

  It can be used with [DataDog agent](http://datadoghq.com).
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "monitoring"

  alias Plug.Conn
  import Gateway.Helpers.Latency

  @doc false
  def call(%Conn{path_info: path_info} = conn, _opts) do
    request_size_metric_name = path_info
    |> metric_name("request_size")

    conn
    |> get_request_size()
    |> ExStatsD.histogram(request_size_metric_name)

    path_info
    |> metric_name("request_count")
    |> ExStatsD.increment

    conn
    |> Conn.register_before_send(&write_metrics(&1))
  end

  defp write_metrics(%Conn{request_path: request_path} = conn) do
    client_req_start_time = Map.get(conn.assigns, :client_req_start_time)
    conn = write_latency(conn, :latencies_client, client_req_start_time)
    request_duration = conn.assigns.latencies_client - Map.get(conn.assigns, :latencies_upstream, 0)

    metric_name = request_path
    |> metric_name("latency")

    request_duration
    |> ExStatsD.timer(metric_name)

    request_path
    |> metric_name("status_count_" <> to_string(conn.status))
    |> ExStatsD.increment

    conn
    |> Conn.assign(:latencies_gateway, request_duration)
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

  defp get_request_size(conn) do
    get_headers_size(conn) + get_body_size(conn) + get_query_string_size(conn)
  end

  defp get_headers_size(%Conn{req_headers: req_headers}) do
    req_headers
    |> Enum.map(&Tuple.to_list(&1))
    |> List.flatten
    |> Enum.join
    |> byte_size
  end

  defp get_body_size(conn) do
    conn
    |> Conn.read_body
    |> elem(1)
    |> byte_size
  end

  defp get_query_string_size(%Conn{query_string: query_string}) do
    query_string
    |> byte_size
  end
end
