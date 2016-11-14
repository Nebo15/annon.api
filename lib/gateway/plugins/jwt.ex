defmodule Gateway.Plugins.JWT do
  @moduledoc """
  [JWT Tokens authorization](http://docs.annon.apiary.io/#reference/plugins/jwt-authentification) plugin.

  It's implemented mainly to be used with [Auth0](https://auth0.com/),
  but it should support any JWT-based authentication providers.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "jwt"

  import Joken
  import Ecto.Query, only: [from: 2]

  alias Plug.Conn
  alias Joken.Token
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.Consumer
  alias Gateway.DB.Schemas.API, as: APISchema
  alias Gateway.DB.Configs.Repo
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
    |> parse_auth(Conn.get_req_header(conn, "authorization"), signature)
  end
  defp execute(_plugin, conn) do
    Logger.error("JWT tokens decryption key is not set")

    conn
    |> Response.send_error(:internal_error)
  end

  defp parse_auth(conn, ["Bearer " <> incoming_token | _], signature) do
    incoming_token
    |> token()
    |> with_signer(hs256(signature))
    |> verify()
    |> evaluate(conn)
  end
  defp parse_auth(conn, _header, _signature) do
    # TODO: This plugin should not authorize, only authentificate
    # so simply return conn. This should be discussed with team (!)
    "401.json"
    |> ErrorView.render(%{
      message: "You need to use JWT token to access this resource.",
      invalid: [%{
        entry_type: "header",
        entry: "Authorization",
        rules: []
      }]
    })
    |> Response.send(conn, 401)
    |> Response.halt()
  end

  defp evaluate(%Token{error: nil} = token, conn) do
    conn
    |> merge_consumer_settings(token)
    |> Conn.put_private(:jwt_token, token)
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

  def merge_consumer_settings(%Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn,
                              %Token{claims: %{"id" => id}}) do
    id
    |> get_consumer_settings()
    |> merge_plugins(plugins)
    |> put_api_to_conn(conn)
  end
  def merge_consumer_settings(conn, _token), do: conn

  # TODO: Read if from cache
  # TODO: Move consumer and api settings merge to a separate plugin to support different auth strategies
  def get_consumer_settings(external_id) do
    Repo.all from c in Consumer,
      where: c.external_id == ^external_id,
      join: s in assoc(c, :plugins),
      where: s.is_enabled == true,
      select: {s.plugin_id, s.settings}
  end

  def merge_plugins(consumer, default)
      when is_list(consumer) and length(consumer) > 0 and is_list(default) and length(default) > 0 do
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
  def put_api_to_conn(plugins, %Conn{private: %{api_config: %APISchema{} = api}} = conn) when is_list(plugins) do
    conn
    |> Conn.put_private(:api_config, Map.put(api, :plugins, plugins))
  end
end
