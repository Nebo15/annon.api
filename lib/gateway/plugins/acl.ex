defmodule Gateway.Plugins.ACL do
  @moduledoc """
  [Access Control Layer (ACL) plugin](http://docs.annon.apiary.io/#reference/plugins/acl).

  It allows to set list of scopes that is required for path relative to an API.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "acl"

  alias Plug.Conn
  alias Joken.Token
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema
  alias EView.Views.Error, as: ErrorView
  alias Gateway.Helpers.Response

  @doc false
  def call(%Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opts) when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(conn)
    |> send_response(conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, _conn), do: :ok
  defp execute(%Plugin{settings: %{"scope" => plugin_scope}},
               %Conn{private: %{jwt_token: %Token{claims: %{"scopes" => token_scopes}}}}) do
    plugin_scope
    |> validate_scopes(token_scopes)
  end
  defp execute(%Plugin{settings: %{"scope" => _}}, _conn), do: {:error, :forbidden}
  defp execute(_plugin, _conn), do: {:error, :no_scopes_is_set}

  defp validate_scopes(scope, scopes) when is_list(scopes) do
    case Enum.member?(scopes, scope) do
      true -> :ok
      false -> {:error, :forbidden}
    end
  end
  defp validate_scopes(_scope, _scopes), do: {:error, :invalid_scopes_type}

  defp send_response(:ok, conn), do: conn
  defp send_response({:error, :forbidden}, conn) do
    "403.json"
    |> ErrorView.render(%{
      message: "Your scopes does not allow to access this resource.",
      invalid: [%{
        entry_type: "header",
        entry: "Authorization",
        rules: []
      }]
    })
    |> Response.send(conn, 403)
    |> Response.halt()
  end
  defp send_response({:error, :no_scopes_is_set}, conn) do
    Logger.error("Required field scope in Plugin.settings is not found!")
    conn
    |> Response.send_error(:internal_error)
  end
  defp send_response({:error, :invalid_scopes_type}, conn) do
    Logger.error("JWT.scopes must be a list!")
    conn
    |> Response.send_error(:internal_error)
  end
end
