defmodule Annon.Configuration.Matcher do
  @moduledoc """
  This module is responsible for configuration lookups for each request.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(opts) do
    adapter = Keyword.get(opts, :adapter)

    unless adapter do
      raise "Configuration cache adapter is not set, expected module, got: #{inspect adapter}."
    end

    {:ok, %{adapter: adapter}, 0}
  end

  @doc """
  Notifies cache adapter about configuration change.
  """
  def config_change do
    GenServer.call(__MODULE__, :config_change)
  end

  @doc """
  Returns API and associated Plugins by a request parameters.

  This function receives adapter by casting GenServer and applies
  match in calling process context to reduce single-process bottleneck.

  Adapter should expect their match functions to be read-concurrent from other processes.
  """
  def match_request(scheme, method, host, port, path) do
    adapter = GenServer.call(__MODULE__, :get_adapter)
    adapter.match_request(scheme, method, host, port, path)
  end

  # Initializes cache adapter after GenServer is started.
  @doc false
  def handle_info(:timeout, %{adapter: adapter} = state) do
    :ok = adapter.init()
    {:noreply, state}
  end

  # Reloads configuration for a cache adapter
  @doc false
  def handle_call(:config_change, _from, %{adapter: adapter} = state) do
    :ok = adapter.config_change()
    {:reply, :ok, state}
  end

  # Reloads configuration for a cache adapter
  @doc false
  def handle_call(:get_adapter, _from, %{adapter: adapter} = state) do
    {:reply, adapter, state}
  end
end
