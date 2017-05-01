defmodule Annon.Plugins.Scopes do
  @moduledoc """
  This plugin receives user scopes from PCM by party_id.
  """
  use Annon.Plugin,
    plugin_name: "scopes"

  alias Plug.Conn
  alias Annon.Configuration.Schemas.Plugin
  alias Annon.Configuration.Schemas.API, as: APISchema
  alias Annon.Plugins.Scopes.JWTStrategy
  alias Annon.Plugins.Scopes.PCMStrategy

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
end
