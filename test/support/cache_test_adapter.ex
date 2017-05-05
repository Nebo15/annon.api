defmodule Annon.CacheTestAdapter do
  @moduledoc false
  @behaviour Annon.Configuration.CacheAdapter
  require Logger

  def init do
    Logger.debug("Adapter initialized")
    :ok
  end

  def match_request(_scheme, _method, _host, _port, _path) do
    Logger.debug("Match called")
    {:ok, :i_am_api}
  end

  def config_change do
    Logger.debug("Config changed")
    :ok
  end
end
