defmodule Gateway.Plugins.CORS do
  @moduledoc """
  This plugin controls cross-origin resource sharing.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "cors"

  alias Plug.Conn
  alias Gateway.DB.Schemas.Plugin
  alias Gateway.DB.Schemas.API, as: APISchema

  def call(%Conn{private: %{api_config: %APISchema{plugins: plugins}}} = conn, _opts)
    when is_list(plugins) do
    plugins
    |> find_plugin_settings()
    |> execute(conn)
  end
  def call(conn, _), do: conn

  defp init_settings(settings) do
    settings
    |> Enum.map(fn({key, value}) -> {String.to_atom(key), value} end)
    |> CORSPlug.init()
  end

  defp execute(nil, conn), do: conn
  defp execute(%Plugin{settings: settings}, conn) do
    conn
    |> CORSPlug.call(init_settings(settings))
  end
end
