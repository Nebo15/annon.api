defmodule Gateway.Plugins.Validator do
  @moduledoc """
  Plugin which validates request based on ex_json_schema
  See more https://github.com/jonasschmidt/ex_json_schema
  """
  import Plug.Conn

  # TODO: Get data from the model, when we would know api_id

  def init(opts), do: opts

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

  # TODO: replace when we would know api_id
  def get_schema(_), do: %{}
  def get_body(%Plug.Conn{body_params: %{} = body}), do: body

end
