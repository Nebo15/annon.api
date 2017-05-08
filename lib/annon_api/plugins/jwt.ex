defmodule Annon.Plugins.JWT do
  @moduledoc """
  [JWT Tokens authorization](http://docs.annon.apiary.io/#reference/plugins/jwt-authentification) plugin.

  It's implemented mainly to be used with [Auth0](https://auth0.com/),
  but it should support any JWT-based authentication providers.
  """
  use Annon.Plugin, plugin_name: :jwt
  import Joken
  alias Joken.Token
  alias Annon.Helpers.Response
  require Logger

  defdelegate validate_settings(changeset), to: Annon.Plugins.JWT.SettingsValidator
  defdelegate settings_validation_schema(), to: Annon.Plugins.JWT.SettingsValidator

  def execute(%Conn{} = conn, _request, %{"signature" => signature}) do
    case fetch_bearer_token(conn) do
      {:ok, encoded_token} ->
        {:ok, decoded_signature} = Base.decode64(signature)

        encoded_token
        |> token()
        |> with_signer(hs256(decoded_signature))
        |> verify()
        |> evaluate(conn)
      :error ->
        conn
    end
  end

  defp fetch_bearer_token(conn) do
    case Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> encoded_token | _] -> {:ok, encoded_token}
      _ -> :error
    end
  end

  defp evaluate(%Token{error: nil} = token, conn) do
    conn
    |> Conn.put_private(:jwt_token, token)
    |> Conn.put_private(:consumer_id, get_consumer_id(token))
  end
  defp evaluate(%Token{error: message}, conn) do
    %{
      type: :validation_failed,
      message: "Your JWT token is invalid.",
      invalid: [%{
        entry_type: "header",
        entry: "Authorization",
        description: message,
        rules: []
      }]
    }
    |> Response.send(conn, 422)
    |> Response.halt()
  end

  defp get_consumer_id(%{"app_metadata" => %{"party_id" => party_id}}) do
    Logger.warn("Using party_id for Consumer ID in JWT tokens is deprecated. Use `consumer_id` instead.")
    party_id
  end
  defp get_consumer_id(%{"app_metadata" => %{"consumer_id" => consumer_id}}),
    do: consumer_id
  defp get_consumer_id(%Token{claims: token_claims}),
    do: get_consumer_id(token_claims)
  defp get_consumer_id(_),
    do: nil
end
