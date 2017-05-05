defmodule Annon.Configuration.CacheAdapters.Database do
  @moduledoc """
  Adapter to access cache using RDBMS.
  """
  @behaviour Annon.Configuration.CacheAdapter
  alias Annon.Configuration.API

  def init(_opts),
    do: :ok

  def match_request(scheme, method, host, port, path, _opts) do
    API.find_api(scheme, method, host, port, path)
  end

  def config_change(_opts),
    do: :ok
end
