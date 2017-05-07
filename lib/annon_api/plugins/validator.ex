defmodule Annon.Plugins.Validator do
  @moduledoc """
  [JSON Schema Validation plugin](http://docs.annon.apiary.io/#reference/plugins/validator) allows you to
  set validation rules for a path relative to an API.

  It's response structure described in
  our [API Manifest](http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors).
  """
  use Annon.Plugin, plugin_name: "validator"
  alias Annon.Helpers.Response

  defdelegate validate_settings(changeset), to: Annon.Plugins.Validator.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.Validator.SettingsValidator

  def execute(%Conn{body_params: body} = conn, %{api: %{request: %{path: api_path}}}, settings) do
    %{"rules" => rules} = settings

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
  def execute(conn, _request, _settings),
    do: conn

  defp validate_request(nil, _body, conn),
    do: conn
  defp validate_request(schema, body, conn) do
    schema
    |> NExJsonSchema.Validator.validate(body)
    |> process_validator_result(conn)
  end

  defp process_validator_result(:ok, conn),
    do: conn
  defp process_validator_result({:error, invalid}, conn),
    do: Response.send_validation_error(conn, invalid)
end
