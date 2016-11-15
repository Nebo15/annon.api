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

  defp get_url(party_id, url_template), do: String.replace(url_template, "{party_id}", party_id)

  defp get_scopes(url) do
    url
    |> HTTPoison.get!
    |> Map.get(:body)
    |> Poison.decode!
    |> get_in(["data", "scopes"])
  end

  defp save_scopes(scopes, conn) do
    conn
    |> Conn.put_private(:scopes, scopes)
  end

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{settings: %{"url_template" => url_template}}, %Conn{private: %{jwt_token: token}} = conn) do
    token
    |> extract_party_id()
    |> get_url(url_template)
    |> get_scopes()
    |> save_scopes(conn)
  end
end
