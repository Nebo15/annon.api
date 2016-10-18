defmodule Gateway.Plugins.Jwt do
  @moduledoc """
    Plugin for JWT verifying and decoding
  """
  import Plug.Conn
  import Joken
  alias Joken.Token

  def init([]), do: false

  def call(conn, _opts) do
    conn
    |> parse_auth(get_req_header(conn, "authorization"))
  end

  defp parse_auth(conn, ["Bearer " <> incoming_token]) do

    verified_token = incoming_token
    |> token()
    |> with_signer(hs256("secret"))
    |> verify()

    evaluate(conn, verified_token)
  end
  defp parse_auth(conn, _header), do: send_401(conn, "unauthorized")

  defp evaluate(conn, %Token{error: nil} = token), do: assign(conn, :joken_token, token)
  defp evaluate(conn, %Token{error: message}), do: send_401(conn, message)

  defp send_401(conn, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, create_json_response(message))
    |> halt
  end

  defp create_json_response(message) do
    Poison.encode!(%{
      meta: %{
        code: 401,
        error: message
      }
    })
  end
end
