defmodule Gateway.Plugins.JWT do
  @moduledoc """
  [JWT Tokens authorization](http://docs.annon.apiary.io/#reference/plugins/jwt-authentification) plugin.

  It's implemented mainly to be used with [Auth0](https://auth0.com/),
  but it should support any JWT-based authentication providers.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "jwt"

  require Logger

  import Joken

  alias Plug.Conn
  alias Joken.Token
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema
  alias EView.Views.Error, as: ErrorView
  alias Gateway.Helpers.Response

  @doc false
  def call(%Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opts) when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{settings: %{"signature" => signature}}, conn) do
    conn
    |> parse_auth(Conn.get_req_header(conn, "authorization"), Base.decode64(signature))
  end
  defp execute(_plugin, conn) do
    Logger.error("JWT tokens decryption key is not set")
    conn
    |> Response.send_error(:internal_error)
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
