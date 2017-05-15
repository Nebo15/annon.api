defmodule Annon.Plugins.ACL do
  @moduledoc """
  [Access Control Layer (ACL) plugin](http://docs.annon.apiary.io/#reference/plugins/acl).

  It allows to set list of scopes that is required for path relative to an API.
  """
  use Annon.Plugin, plugin_name: :acl
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response
  alias Annon.PublicAPI.Consumer
  require Logger

  defdelegate validate_settings(changeset), to: Annon.Plugins.ACL.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.ACL.SettingsValidator

  def execute(%Conn{} = conn, %{api: %{request: %{path: api_path}}}, %{"rules" => rules}) do
    %Conn{method: request_method, request_path: request_path} = conn
    api_relative_path = String.trim_leading(request_path, String.trim_trailing(api_path, "/"))

    with {:ok, consumer_scope} <- fetch_scope(conn),
         {:ok, rule} <- find_rule(rules, request_method, api_relative_path),
         :ok <- validate_scope(rule, consumer_scope) do
      conn
    else
      {:error, :scope_not_set} -> send_forbidden(conn)
      {:error, :no_matching_rule} -> send_forbidden(conn)
      {:error, :forbidden, missing_scopes} -> send_forbidden(conn, missing_scopes)
    end
  end

  defp fetch_scope(%Conn{assigns: %{consumer: %Consumer{scope: scope}}}),
    do: {:ok, scope}
  defp fetch_scope(_),
    do: {:error, :scope_not_set}

  defp find_rule(rules, request_method, api_relative_path) do
    rule =
      Enum.find_value(rules, fn %{"path" => rule_path, "methods" => methods} = rule ->
        method_matches? = request_method in methods
        path_matches? = api_relative_path =~ ~r"^#{rule_path}"

        if method_matches? && path_matches? do
          {:ok, rule}
        end
      end)

    if is_nil(rule), do: {:error, :no_matching_rule}, else: rule
  end

  defp validate_scope(%{"scopes" => required_scopes}, []),
    do: {:error, :forbidden, required_scopes}
  defp validate_scope(%{"scopes" => required_scopes}, scope) do
    consumer_scope = split_scope(scope)

    missing_scope =
      Enum.reject(required_scopes, fn required_scope ->
        required_scope in consumer_scope
      end)

    case missing_scope do
      [] -> :ok
      missing_scope -> {:error, :forbidden, missing_scope}
    end
  end

  defp split_scope(scope) when is_binary(scope),
    do: String.split(scope, " ", trim: true)

  defp send_forbidden(conn, missing_scopes \\ nil) do
    "403.json"
    |> ErrorView.render(%{
      message: get_message(missing_scopes),
      invalid: [%{
        entry_type: "header",
        entry: "Authorization",
        rules: get_rules(missing_scopes)
      }]
    })
    |> Response.send(conn, 403)
    |> Response.halt()
  end

  defp get_message(nil),
    do: "You are not authorized or your token can not be resolved to scope"
  defp get_message(missing_scopes) when is_list(missing_scopes) do
    missing_scopes = Enum.join(missing_scopes, ", ")
    "Your scope does not allow to access this resource. Missing allowances: #{missing_scopes}"
  end

  defp get_rules(nil),
    do: []
  defp get_rules(missing_scopes),
    do: %{scopes: missing_scopes}
end
