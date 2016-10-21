defmodule Gateway.Plugins.ACL do
  @moduledoc """
    Plugin for JWT verifying and decoding
  """
  import Plug.Conn

  alias Joken.Token
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel
require Logger
  def init([]), do: false

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
    |> get_enabled()
    |> execute(conn)
    |> normalize_resp(conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, _conn), do: true
  defp execute(%Plugin{settings: %{"scope" => scope}},
               %Plug.Conn{private: %{jwt_token: %Token{claims: %{"scopes" => t_scopes}}}}) do
    scope
    |> validate_scopes(t_scopes)
  end
  defp execute(%Plugin{settings: %{"scope" => _}}, _conn), do: {:error, 403, "forbidden"}
  defp execute(_plugin, _conn), do: {:error, 501, "required field scope in Plugin.settings"}


  def validate_scopes(scope, scopes) when is_list(scopes) do
    Enum.member?(scopes, scope)
  end
  def validate_scopes(_scope, _scopes) do
   {:error, 501, "Plugin.settings.scopes and JWT.scopes must be a list"}
  end

  def normalize_resp(true, conn), do: conn
  def normalize_resp(false, conn), do: conn |> send_halt(403, "forbidden")
  def normalize_resp({:error, code, msg}, conn), do: conn |> send_halt(code, msg)

  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end
  defp filter_plugin(%Plugin{name: :ACL, is_enabled: true}), do: true
  defp filter_plugin(_), do: false

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
