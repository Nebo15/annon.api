defmodule Gateway.Plugins.Scopes do
  @moduledoc """
  This plugin receives user scopes from PCM by party_id.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "scopes"

  alias Plug.Conn
  alias Joken.Token
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema
  alias Gateway.Helpers.Scopes.JWTStrategy
  alias Gateway.Helpers.Scopes.PCMStrategy

  def call(%Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opts)
    when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp extract_party_id(%Token{claims: token_claims}), do: extract_party_id(token_claims)
  defp extract_party_id(%{"user_metadata" => %{"party_id" => party_id}}), do: party_id
  defp extract_party_id(_), do: nil

  defp save_scopes(scopes, conn) do
    conn
    |> Conn.put_private(:scopes, scopes)
  end

  defp get_scopes(token, %{"strategy" => "jwt"}) do
    token
    |> JWTStrategy.get_scopes()
  end
  defp get_scopes(token, %{"strategy" => "pcm", "url_template" => url_template}) do
    token
    |> extract_party_id()
    |> PCMStrategy.get_scopes(url_template)
  end
  defp get_scopes(_token, _), do: []

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{settings: settings}, %Conn{private: %{jwt_token: token}} = conn) do
    token
    |> get_scopes(settings)
    |> save_scopes(conn)
  end
end
