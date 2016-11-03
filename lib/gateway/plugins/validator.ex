defmodule Gateway.Plugins.Validator do
  @moduledoc """
  Plugin which validates request based on ex_json_schema.
  See more https://github.com/nebo15/nex_json_schema
  """
  use Gateway.Helpers.Plugin,
    plugin_name: :validator

  alias Plug.Conn

  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APIModel
  alias Gateway.HTTPHelpers.Response
  alias EView.Views.ValidationError, as: ValidationErrorView

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp execute(%Plugin{settings: %{"schema" => schema}}, %Plug.Conn{body_params: %{} = body} = conn) do
    schema
    |> Poison.decode!()
    |> NExJsonSchema.Validator.validate(body)
    |> normalize_validation(conn)
  end
  defp execute(_, conn), do: conn

  defp normalize_validation(:ok, conn), do: conn
  defp normalize_validation({:error, errors}, conn) do
    "422.json"
    |> ValidationErrorView.render(%{schema: errors})
    |> Response.render_response(conn, 422)
    |> Conn.halt
  end
end
