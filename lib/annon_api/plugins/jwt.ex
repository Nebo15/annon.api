defmodule Annon.Plugins.JWT do
  @moduledoc """
  [JWT Tokens authorization](http://docs.annon.apiary.io/#reference/plugins/jwt-authentification) plugin.

  It's implemented mainly to be used with [Auth0](https://auth0.com/),
  but it should support any JWT-based authentication providers.
  """
  use Annon.Plugin, plugin_name: "jwt"
  import Joken
  alias Joken.Token
  alias EView.Views.Error, as: ErrorView
  alias Annon.Helpers.Response
  require Logger

  defdelegate validate_settings(changeset), to: Annon.Plugins.JWT.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.JWT.SettingsValidator

  def execute(%Conn{} = conn, _request, %{"signature" => signature}) do
    parse_auth(conn, Conn.get_req_header(conn, "authorization"), Base.decode64(signature))
  end
  def execute(conn, _request, _settings) do
    Logger.error("JWT tokens decryption key is not set")
    Response.send_error(conn, :internal_error)
  end

  defp parse_auth(conn, _, :error) do
    Logger.error("Your JWT token secret MUST be base64 encoded")
    conn
    |> Response.send_error(:internal_error)
  end
  defp parse_auth(conn, ["Bearer " <> incoming_token | _], {:ok, signature}) do
    incoming_token
    |> token()
    |> with_signer(hs256(signature))
    |> verify()
    |> evaluate(conn)
  end
  defp parse_auth(conn, _header, _signature), do: conn

  defp get_consumer_id(%Token{claims: token_claims}), do: get_consumer_id(token_claims)
  defp get_consumer_id(%{"app_metadata" => %{"party_id" => party_id}}), do: party_id
  defp get_consumer_id(_), do: nil

  defp evaluate(%Token{error: nil} = token, conn) do
    conn
    |> Conn.put_private(:jwt_token, token)
    |> Conn.put_private(:consumer_id, get_consumer_id(token))
  end
  defp evaluate(%Token{error: message}, conn) do
    # TODO: Simply 422 error, because token is invalid
    "401.json"
    |> ErrorView.render(%{
      message: "Your JWT token is invalid.",
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
