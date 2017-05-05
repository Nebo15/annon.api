defmodule Annon.CacheTestAdapter do
  @moduledoc false
  @behaviour Annon.Configuration.CacheAdapter
  require Logger

  def init(opts) do
    pid = Keyword.fetch!(opts, :test_pid)
    send(pid, :initialized)
    :ok
  end

  def match_request(_scheme, _method, _host, _port, _path, opts) do
    pid = Keyword.fetch!(opts, :test_pid)
    send(pid, :match_called)
    {:ok, :i_am_api}
  end

  def config_change(opts) do
    pid = Keyword.fetch!(opts, :test_pid)
    send(pid, :config_changed)
    :ok
  end
end
