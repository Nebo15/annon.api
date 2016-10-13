defmodule Gateway.Plugins.Validator do
  @moduledoc """
  Plugin which validates request based on ex_json_schema
  See more https://github.com/jonasschmidt/ex_json_schema
  """
  import Plug.Conn

  # when compile
  def init(opts), do: opts

  # when run
  def call(conn, _) do
    if valid?(get_body(conn), get_schema(conn)) do
      conn
    else
      conn |> halt
    end
  end

  def valid?(body, schema) do
    ExJsonSchema.Validator.valid?(schema, body)
  end

  def get_schema(%Plug.Conn{assigns: %{schema: %{} = schema}}), do: schema
  def get_body(%Plug.Conn{assigns: %{body: %{} = body}}), do: body

end