defmodule Gateway.Plugins.Validator do
  @moduledoc """
  Plugin which validates request based on ex_json_schema
  See more https://github.com/jonasschmidt/ex_json_schema
  """
  import Plug.Conn

  # when compile
  def init(opts), do: opts

  # when run
  def call(conn, opts) do
    conn
    |> Plug.Conn.read_body
    |> IO.inspect

    conn
  end

end