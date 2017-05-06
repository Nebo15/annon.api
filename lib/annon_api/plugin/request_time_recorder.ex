defmodule Annon.Plugin.RequestTimeRecorder do
  @moduledoc """
  This plugin writes request start time to conn.assigns.
  """
  alias Plug.Conn

  def init(opts),
    do: opts

  def call(conn, _opts) do
    Conn.assign(conn, :request_start_time, System.monotonic_time())
  end
end
