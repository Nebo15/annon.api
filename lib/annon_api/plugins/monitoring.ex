defmodule Annon.Plugins.Monitoring do
  @moduledoc """
  This plugin measures or receives performance metrics from other parts of Annon and sends them to StatsD server.

  It is enabled by default and can not be disabled without rebuilding Annon container.

  It can be used with [DataDog agent](http://datadoghq.com).
  """
  use Annon.Plugin, plugin_name: :monitoring
  alias Plug.Conn
  alias Annon.Monitoring.MetricsCollector
  alias Annon.Monitoring.Latencies

  def validate_settings(changeset),
    do: changeset

  def settings_validation_schema,
    do: %{}

  def execute(%Conn{} = conn, %{api: api, start_time: request_start_time}, _settings) do
    content_length = get_content_length(conn, nil)

    sample_rate =
      :annon_api
      |> Application.get_env(:metrics_collector)
      |> Keyword.get(:sample_rate, 1)
      |> Confex.process_env()

    collector_opts = [
      tags: tags(conn, api),
      sample_rate: sample_rate
    ]

    request_id = get_request_id(conn, nil)

    MetricsCollector.track_request(request_id, content_length, collector_opts)

    conn
    |> Conn.register_before_send(&track_latencies(&1, request_id, request_start_time, collector_opts))
  end

  defp track_latencies(conn, request_id, request_start_time, collector_opts) do
    request_end_time = System.monotonic_time()
    latencies_client = System.convert_time_unit(request_end_time - request_start_time, :native, :micro_seconds)
    latencies_upstream = Map.get(conn.assigns, :latencies_upstream, 0)
    latencies_gateway = latencies_client - latencies_upstream

    latencies = %Latencies{
      client: latencies_client,
      upstream: latencies_upstream,
      gateway: latencies_gateway
    }

    status = conn |> get_conn_status(0) |> Integer.to_string()

    MetricsCollector.track_response(request_id, latencies, [
      tags: ["http_status:#{status}"] ++ collector_opts[:tags],
      sample_rate: collector_opts[:sample_rate]
    ])

    conn
    |> Conn.assign(:latencies_gateway, latencies_gateway)
    |> Conn.assign(:latencies_client, latencies_client)
    |> Conn.assign(:latencies, latencies)
  end

  defp tags(%Conn{host: host, method: method, port: port} = conn, nil) do
    port = Integer.to_string(port)
    request_id = get_request_id(conn, "unknown")

    ["http_host:#{host}", "http_method:#{method}", "http_port:#{port}",
     "api_name:unknown", "api_id:unknown", "request_id:#{request_id}"]
  end
  defp tags(%Conn{host: host, method: method, port: port} = conn, api) do
    port = Integer.to_string(port)
    request_id = get_request_id(conn, "unknown")
    %{id: api_id, name: api_name} = api

    ["http_host:#{host}", "http_method:#{method}", "http_port:#{port}",
     "api_name:#{api_name}", "api_id:#{api_id}", "request_id:#{request_id}"]
  end

  defp get_request_id(conn, default) do
    case Conn.get_resp_header(conn, "x-request-id") do
      [] -> default
      [id | _] -> id
    end
  end

  defp get_content_length(conn, default) do
    case Conn.get_resp_header(conn, "content-length") do
      [] -> default
      [id | _] -> id
    end
  end

  def get_conn_status(%{status: nil}, default),
    do: default
  def get_conn_status(%{status: status}, _default),
    do: status
end
