defmodule Gateway.Plugins.APILoader do
  @moduledoc """
  This plugin should be first in plugs pipeline,
  because it's used to fetch all settings and decide which ones should be applied for current consumer request.
  """
  use Gateway.Helpers.Plugin,
    plugin_name: "api_loader"

  import Plug.Conn

  @doc false
  def call(conn, _opts) do
    put_private(conn, :api_config, Gateway.CacheAdapters.ETS.find_api_by(conn))
  end
end
