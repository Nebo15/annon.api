defmodule Annon.Plugins.ClientLatency do
  @moduledoc """
  This plugin writes request start time to conn.assigns.
  """
  alias Plug.Conn
  import Annon.Helpers.Latency

  def init(opts), do: opts

  def call(conn, _opts) do
    req_start_time = get_time()
    Conn.assign(conn, :client_req_start_time, req_start_time)
  end
end
