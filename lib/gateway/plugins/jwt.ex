defmodule Gateway.Plugins.JWT do
  @moduledoc """
    Plugin for JWT verifying and decoding
  """
  import Plug.Conn
  import Joken
  alias Joken.Token
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  def init([]), do: false

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugin = plugins
    |> get_enabled()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp get_enabled(plugins) when is_list(plugins) do
    plugins
    |> Enum.find(&filter_plugin/1)
  end
  defp filter_plugin(%Plugin{name: :JWT, is_enabled: true}), do: true
  defp filter_plugin(_), do: false

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{settings: %{"signature" => signature}} = plugin, conn) do
    conn
    |> parse_auth(get_req_header(conn, "authorization"), signature)
  end
  defp execute(plugin, conn) do
    conn
    |> send_halt(501, "required field signature in Plugin.settings")
  end

  defp parse_auth(conn, ["Bearer " <> incoming_token], signature) do

    verified_token = incoming_token
    |> token()
    |> with_signer(hs256(signature))
    |> verify()

    evaluate(conn, verified_token)
  end
  defp parse_auth(conn, _header, _signature), do: send_halt(conn, 401, "unauthorized")

  defp evaluate(conn, %Token{error: nil} = token), do: put_private(conn, :jwt_token, token)
  defp evaluate(conn, %Token{error: message}), do: send_halt(conn, 401, message)

  defp send_halt(conn, code, message) do
    conn = conn
    |> put_resp_content_type("application/json")
    |> send_resp(code, create_json_response(code, message))
    |> halt
  end

  defp create_json_response(code, message) do
    Poison.encode!(%{
      meta: %{
        code: code,
        error: message
      }
    })
  end
end
