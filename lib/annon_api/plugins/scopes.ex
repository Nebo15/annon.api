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
  alias Annon.Plugins.Scopes.OAuth2Strategy
  alias Annon.Helpers.Response
  alias EView.Views.Error, as: ErrorView

  @doc """
  Settings validator delegate.
  """
  defdelegate validate_settings(changeset), to: Annon.Plugins.Scopes.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.Scopes.SettingsValidator

  def call(%Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opts)
    when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> do_execute(conn)
  end
  def call(conn, _), do: conn

  defp get_scopes(conn, %{"strategy" => "jwt"}) do
    scopes =
      conn.private[:jwt_token]
      |> JWTStrategy.get_scopes()

    Conn.put_private(conn, :scopes, scopes)
  end
  # TODO: refactor this method into a Plug of it's own, designing it after plugins/jwt.ex
  defp get_scopes(conn, %{"strategy" => "oauth2", "url_template" => url_template}) do
    case Conn.get_req_header(conn, "authorization") do
      [token] ->
        token_attributes =
          token
          |> (fn("Bearer " <> string) -> string end).()
          |> OAuth2Strategy.token_attributes(url_template)

        if token_attributes do
          scopes =
            token_attributes
            |> get_in(["data", "details", "scope"])
            |> String.split(",")

          consumer_id = get_in(token_attributes, ["data", "user_id"])

          conn
          |> Conn.put_private(:scopes, scopes)
          |> Conn.put_private(:consumer_id, consumer_id)
        else
          return_401(conn, "access_token does not exist.")
        end
      _ ->
        return_401(conn, "access_token was not provided.")
    end
  end
  defp get_scopes(conn, %{"strategy" => "pcm", "url_template" => url_template}) do
    scopes =
      conn.private
      |> Map.get(:consumer_id)
      |> PCMStrategy.get_scopes(url_template)

    Conn.put_private(conn, :scopes, scopes)
  end
  defp get_scopes(_, _), do: []

  defp do_execute(%Plugin{settings: settings}, conn) do
    conn
    |> get_scopes(settings)
  end
  defp do_execute(_, conn), do: conn

  defp return_401(conn, message) do
    "401.json"
    |> ErrorView.render(%{
      message: message,
      invalid: [%{
        entry_type: "header",
        entry: "Authorization",
        description: message,
        rules: []
      }]
    })
    |> Response.send(conn, 401)
    |> Response.halt()
  end
end
