defmodule Annon.Plugins.Scopes do
  @moduledoc """
  This plugin receives user scopes from PCM by party_id.
  """
  use Annon.Plugin, plugin_name: :scopes
  alias Annon.Plugins.Scopes.JWTStrategy
  alias Annon.Plugins.Scopes.PCMStrategy
  alias Annon.Plugins.Scopes.OAuth2Strategy
  alias Annon.Helpers.Response
  alias EView.Views.Error, as: ErrorView

  defdelegate validate_settings(changeset), to: Annon.Plugins.Scopes.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.Scopes.SettingsValidator

  def execute(%Conn{} = conn, _request, settings) do
    get_scopes(conn, settings)
  end

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
        extract_token_value = fn
          "Bearer " <> string -> string
          _ -> nil
        end

        token_attributes =
          token
          |> extract_token_value.()
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
