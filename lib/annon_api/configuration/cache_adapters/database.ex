defmodule Annon.Configuration.CacheAdapters.Database do
  @moduledoc """
  Adapter to access cache using RDBMS.
  """
  @behaviour Annon.Configuration.CacheAdapter
  alias Annon.Configuration.API

  def init,
    do: :ok

  def match_request(scheme, method, host, port, path) do
    API.find_api(scheme, method, host, port, path)
  end

  def config_change,
    do: :ok
end
