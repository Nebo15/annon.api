defmodule Gateway.Plugins.Validator do
  @moduledoc """
  [JSON Schema Validation plugin](http://docs.annon.apiary.io/#reference/plugins/validator) allows you to
  set validation rules for a path relative to an API.

  It's response structure described in
  our [API Manifest](http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors).
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "validator"

  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema
  alias EView.Views.ValidationError, as: ValidationErrorView
  alias Gateway.Helpers.Response

  @doc false
  def call(%Plug.Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
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
    |> Response.send(conn, 422)
    |> Response.halt()
  end
end
