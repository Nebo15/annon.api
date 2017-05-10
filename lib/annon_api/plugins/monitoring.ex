defmodule Annon.Plugins.Monitoring do
  @moduledoc """
  This plugin measures or receives performance metrics from other parts of Annon and sends them to StatsD server.

  It is enabled by default and can not be disabled without rebuilding Annon container.

  It can be used with [DataDog agent](http://datadoghq.com).
  """
  use Annon.Plugin, plugin_name: :monitoring
  alias Plug.Conn

  def validate_settings(changeset),
    do: changeset

  def settings_validation_schema,
    do: %{}

  def execute(%Conn{} = conn, %{api: api, start_time: request_start_time}, _settings) do
    api_tags = tags(conn, api)

    conn
    |> get_request_size()
    |> ExStatsD.histogram("request_size", tags: api_tags)

    ExStatsD.increment("request_count", tags: api_tags)

    conn
    |> Conn.register_before_send(&write_metrics(&1, api))
    |> Conn.register_before_send(&assign_latencies(&1, request_start_time))
  end

  defp assign_latencies(conn, request_start_time) do
    request_end_time = System.monotonic_time()
    latencies_client = System.convert_time_unit(request_end_time - request_start_time, :native, :micro_seconds)
    request_duration = latencies_client - Map.get(conn.assigns, :latencies_upstream, 0)

    conn
    |> Conn.assign(:latencies_gateway, request_duration)
    |> Conn.assign(:latencies_client, latencies_client)
  end

  defp write_metrics(%Conn{} = conn, api) do
    api_tags = tags(conn, api) ++ ["http_status:#{to_string conn.status}"]
    ExStatsD.timer(conn.assigns.latencies_client, "latency", tags: api_tags)
    ExStatsD.increment("response_count", tags: api_tags)
    conn
  end

  defp tags(%Conn{host: host, method: method, port: port} = conn, api),
    do: ["http_host:#{to_string host}",
         "http_method:#{to_string method}",
         "http_port:#{to_string port}"] ++ api_tags(api) ++ get_request_id(conn)

  defp api_tags(%{name: api_name, id: api_id}),
    do: ["api_name:#{to_string api_name}", "api_id:#{to_string api_id}"]
  defp api_tags(_),
    do: ["api_name:unknown", "api_id:unknown"]

  defp get_request_id(conn) do
    id = conn
    |> Conn.get_resp_header("x-request-id")
    |> Enum.at(0)

    ["request_id:#{to_string id}"]
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
