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

  def merge_consumer_settings(
    %Plug.Conn{private: %{api_config: %APIModel{plugins: plugins}}} = conn, %Token{claims: %{"id" => id}}) do

    id
    |> get_consumer_settings()
    |> merge_plugins(plugins)
    |> put_api_to_conn(conn)
  end
  def merge_consumer_settings(conn, _token), do: conn

  def merge_plugins(consumer, default) when is_list(consumer) and length(consumer) > 0
                                        and is_list(default) and length(default) > 0 do
    default
    |> Enum.map_reduce([], fn(d_plugin, acc) ->

      mergerd_plugin = consumer
      |> Enum.filter(fn({c_id, _}) -> c_id == d_plugin.id end)
      |> merge_plugin(d_plugin)

      {nil, List.insert_at(acc, -1, mergerd_plugin)}
    end)
    |> elem(1)
  end

  def merge_plugins(_consumer, _default), do: nil

  def merge_plugin([{_, consumer_settings}], %Plugin{} = plugin) do
    plugin
    |> Map.merge(%{settings: consumer_settings, is_enabled: true})
  end
  def merge_plugin(_, plugin), do: plugin

  def put_api_to_conn(nil, conn), do: conn
  def put_api_to_conn(plugins, %Plug.Conn{private: %{api_config: %APIModel{} = api}} = conn) when is_list(plugins) do
    conn
    |> put_private(:api_config, Map.put(api, :plugins, plugins))
  end

  def get_consumer_settings(external_id) do
    query = from c in Consumer,
            where: c.external_id == ^external_id,
            join: s in assoc(c, :plugins),
            where: s.is_enabled == true,
            select: {s.plugin_id, s.settings}
    Repo.all(query)
  end

  # TODO: Use Gateway.HTTPHelpers.Response
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
