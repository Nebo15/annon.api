defmodule Gateway.Plugins.JWT do
  @moduledoc """
    Plugin for JWT verifying and decoding
  """
  import Joken
  import Plug.Conn
  import Ecto.Query, only: [from: 2]

  alias Joken.Token
  alias Gateway.DB.Repo
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.Consumer
  alias Gateway.DB.Models.API, as: APIModel
  alias Gateway.DB.Models.ConsumerPluginSettings
  require Logger

  def init([]), do: false

  def call(%Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, _opt) when is_list(plugins) do
    plugins
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
  defp execute(%Plugin{settings: %{"signature" => signature}}, conn) do
    conn
    |> parse_auth(get_req_header(conn, "authorization"), signature)
  end
  defp execute(_plugin, conn) do
    conn
    |> send_halt(501, "required field signature in Plugin.settings")
  end

  defp parse_auth(conn, ["Bearer " <> incoming_token], signature) do
    incoming_token
    |> token()
    |> with_signer(hs256(signature))
    |> verify()
    |> evaluate(conn)
  end
  defp parse_auth(conn, _header, _signature), do: send_halt(conn, 401, "unauthorized")

  defp evaluate(%Token{error: nil} = token, conn) do
    conn
    |> merge_consumer_settings(token)
    |> put_private(:jwt_token, token)
  end
  defp evaluate(%Token{error: message}, conn), do: send_halt(conn, 401, message)

  defp merge_consumer_settings(
    %Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, %Token{claims: %{"id" => id}}) do

    Logger.warn id
    query = from c in Consumer,
            where: c.external_id == ^id,
            join: s in assoc(c, :plugins),
            where: s.is_enabled == true,
            preload: [plugins: s]
    a = Repo.all(query)
    Logger.warn(inspect a)

    conn
  end
  defp merge_consumer_settings(conn, _token), do: conn

  defp send_halt(conn, code, message) do
    conn
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
