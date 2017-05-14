defmodule Annon.Plugins.Validator do
  @moduledoc """
  [JSON Schema Validation plugin](http://docs.annon.apiary.io/#reference/plugins/validator) allows you to
  set validation rules for a path relative to an API.

  It's response structure described in
  our [API Manifest](http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors).
  """
  use Annon.Plugin, plugin_name: :validator
  alias Annon.Helpers.Response

  defdelegate validate_settings(changeset), to: Annon.Plugins.Validator.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.Validator.SettingsValidator

  def execute(conn, %{api: %{request: %{path: api_path}}}, %{"rules" => rules}) do
    %Conn{body_params: req_body_params, method: req_method, request_path: request_path} = conn
    api_relative_path = String.trim_leading(request_path, String.trim_trailing(api_path, "/"))

    with {:ok, schema} <- find_schema(rules, req_method, api_relative_path),
         :ok <- NExJsonSchema.Validator.validate(schema, req_body_params) do
      conn
    else
      {:error, :no_matching_schema} -> conn
      {:error, invalid} -> Response.send_validation_error(conn, invalid)
    end
  end

  defp find_schema(rules, req_method, api_relative_path) do
    schema =
      Enum.find_value(rules, fn %{"path" => rule_path, "schema" => schema, "methods" => methods} ->
        method_matches? = req_method in methods
        path_matches? = api_relative_path =~ ~r"^#{rule_path}"

        if method_matches? && path_matches? do
          {:ok, schema}
        end
      end)

    if is_nil(schema), do: {:error, :no_matching_schema}, else: schema
  end
end
