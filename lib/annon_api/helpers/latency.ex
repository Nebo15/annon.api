defmodule Annon.Helpers.Latency do
  @moduledoc """
  Helper for tracing client latency.
  """
  alias Plug.Conn

  @unit :milli_seconds

  def get_time do
    :erlang.monotonic_time(@unit)
  end

  def write_latency(conn, key, start_time) do
    end_time = get_time()
    latency = end_time - start_time
    Conn.assign(conn, key, latency)
  end
end
