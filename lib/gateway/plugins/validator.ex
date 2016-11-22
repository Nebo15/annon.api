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
  alias Gateway.Helpers.Response

  @doc false
  def call(%Plug.Conn{private: %{api_config: %APISchema{plugins: plugins, request: %{path: api_path}}}} = conn, _opt)
    when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(api_path, conn)
  end
  def call(conn, _), do: conn

  defp execute(%Plugin{settings: %{"rules" => rules}}, api_path, %Plug.Conn{body_params: body} = conn) do
    request_path = String.trim_leading(conn.request_path, api_path)

    rules
    |> Enum.find_value(fn(rule) ->
       method_matches? = conn.method in rule["methods"]
       path_matches? = request_path =~ ~r"#{rule["path"]}"

       if method_matches? && path_matches? do
         rule["schema"]
       end
     end)
    |> validate_request(body, conn)
  end
  defp execute(_, _api_path, conn), do: conn

  defp validate_request(nil, _body, conn), do: conn
  defp validate_request(schema, body, conn) do
    schema
    |> NExJsonSchema.Validator.validate(body)
    |> process_validator_result(conn)
  end

  defp process_validator_result(:ok, conn), do: conn
  defp process_validator_result({:error, invalid}, conn), do: conn |> Response.send_validation_error(invalid)
end
