defmodule Annon.Plugin.LatencyRecorder do
  @moduledoc """
  This plug calculates and assigns request latencies after request was sent to the Consumer.
  """
  alias Plug.Conn

  def init(opts),
    do: opts

  def call(conn, _opts) do
    Conn.register_before_send(conn, &assign_latencies(&1))
  end

  def assign_latencies(conn) do
    request_end_time = System.monotonic_time()
    request_start_time = Map.get(conn.assigns, :request_start_time)
    latencies_client = System.convert_time_unit(request_end_time - request_start_time, :native, :micro_seconds)
    request_duration = latencies_client - Map.get(conn.assigns, :latencies_upstream, 0)

    conn
    |> Conn.assign(:latencies_gateway, request_duration)
    |> Conn.assign(:latencies_client, latencies_client)
  end
end
