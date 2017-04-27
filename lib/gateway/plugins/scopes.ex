defmodule Gateway.Plugins.Scopes do
  @moduledoc """
  This plugin receives user scopes from PCM by party_id.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "scopes"

  alias Plug.Conn
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema
  alias Gateway.Helpers.Scopes.JWTStrategy
  alias Gateway.Helpers.Scopes.PCMStrategy
  alias Gateway.Helpers.Scopes.OAuth2Strategy

  def call(%Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opts)
    when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp save_scopes(scopes, conn) do
    conn
    |> Conn.put_private(:scopes, scopes)
  end

  defp get_scopes(_conn, token, %{"strategy" => "jwt"}) do
    token
    |> JWTStrategy.get_scopes()
  end
  defp get_scopes(conn, _token, %{"strategy" => "oauth2", "url_template" => url_template}) do
    Conn.get_req_header(conn, "authorization")
    |> (fn("Bearer " <> string) -> string end).()
    |> OAuth2Strategy.get_scopes(url_template)
  end
  defp get_scopes(conn, _token, %{"strategy" => "pcm", "url_template" => url_template}) do
    conn.private
    |> Map.get(:consumer_id)
    |> PCMStrategy.get_scopes(url_template)
  end
  defp get_scopes(_conn, _token, _), do: []

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{settings: settings}, %Conn{private: %{jwt_token: token}} = conn) do
    conn
    |> get_scopes(token, settings)
    |> save_scopes(conn)
  end
  defp execute(%Plugin{settings: _}, %Conn{private: _} = conn), do: conn
end
