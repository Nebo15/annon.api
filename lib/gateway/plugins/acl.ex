defmodule Gateway.Plugins.ACL do
  @moduledoc """
    Plugin for JWT verifying and decoding
  """
  import Plug.Conn

  alias Joken.Token
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  def init([]), do: false

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> get_enabled()
    |> execute(conn)
    |> normalize_resp(conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, _conn), do: true
  defp execute(%Plugin{settings: %{"scope" => plugin_scope}},
               %Plug.Conn{private: %{jwt_token: %Token{claims: %{"scopes" => token_scopes}}}}) do
    plugin_scope
    |> validate_scopes(token_scopes)
  end
  defp execute(%Plugin{settings: %{"scope" => _}}, _conn), do: {:error, 403, "forbidden"}

  def validate_scopes(scope, scopes) when is_list(scopes), do: Enum.member?(scopes, scope)
  def validate_scopes(_scope, _scopes), do: {:error, 501, "JWT.scopes must be a list"}

  def normalize_resp(true, conn), do: conn
  def normalize_resp(false, conn), do: conn |> send_halt(403, "forbidden")
  def normalize_resp({:error, code, msg}, conn), do: conn |> send_halt(code, msg)

  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end
  defp filter_plugin(%Plugin{name: :ACL, is_enabled: true}), do: true
  defp filter_plugin(_), do: false

  # TODO: use Gateway.HTTPHelpers.Response
  defp send_halt(conn, code, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(code, create_json_response(code, message))
    |> halt
  end

  defp create_json_response(code, message) do
    Poison.encode!(%{
      meta: %{
        code: code,
        error: message
      }
    })
  end
end
