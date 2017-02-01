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
  def call(%Conn{} = conn, _opts) do
    api_tags = tags(conn)

    conn
    |> get_request_size()
    |> ExStatsD.histogram("request_size", tags: api_tags)

    ExStatsD.increment("request_count", tags: api_tags)

    conn
    |> Conn.register_before_send(&write_metrics(&1))
  end

  defp write_metrics(%Conn{} = conn) do
    client_req_start_time = Map.get(conn.assigns, :client_req_start_time)
    conn = write_latency(conn, :latencies_client, client_req_start_time)
    request_duration = conn.assigns.latencies_client - Map.get(conn.assigns, :latencies_upstream, 0)
    api_tags = tags(conn)

    ExStatsD.timer(request_duration, "latency", tags: api_tags)
    ExStatsD.increment("response_count", tags: api_tags ++ ["http_status:#{to_string conn.status}"])

    conn
    |> Conn.assign(:latencies_gateway, request_duration)
  end

  defp tags(%Conn{host: host, method: method, port: port} = conn),
    do: ["http_host:#{to_string host}",
         "http_method:#{to_string method}",
         "http_port:#{to_string port}"] ++ api_tags(conn)

  defp api_tags(%Conn{private: %{api_config: api_name, id: api_id}}),
    do: ["api_name:#{to_string api_name}", "api_id:#{to_string api_id}"]
  defp api_tags(_),
    do: ["api_name:unknown", "api_id:unknown"]

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
