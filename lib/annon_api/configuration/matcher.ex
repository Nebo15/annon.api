defmodule Annon.Configuration.Matcher do
  @moduledoc """
  This module is responsible for configuration lookups for each request.
  """
  use GenServer

  def start_link(opts, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, opts, [name: name])
  end

  @doc """
  Initializes matcher state.

  It accepts two options:
    * `adapter` - cache adapter.
    * `cache_space` - unique cache space key if multiple matcher processes are started.
  """
  def init(config) do
    {:ok, configure(config), 0}
  end

  defp configure(config) do
    {:ok, opts} = Annon.load_from_system_env(config)

    adapter = Keyword.get(opts, :adapter)

    unless adapter do
      raise "Configuration cache adapter is not set, expected module, got: #{inspect adapter}."
    end

    %{adapter: adapter, opts: opts, config: config}
  end

  @doc """
  Notifies cache adapter about configuration change.
  """
  def config_change(pid \\ __MODULE__) do
    GenServer.call(pid, :config_change)
  end

  @doc """
  Returns API and associated Plugins by a request parameters.

  This function receives adapter by casting GenServer and applies
  match in calling process context to reduce single-process bottleneck.

  Adapter should expect their match functions to be read-concurrent from other processes.
  """
  def match_request(pid \\ __MODULE__, scheme, method, host, port, path) do
    {adapter, opts} = GenServer.call(pid, :get_adapter)
    adapter.match_request(scheme, method, host, port, path, opts)
  end

  # Initializes cache adapter after GenServer is started.
  @doc false
  def handle_info(:timeout, state) do
    %{adapter: adapter, opts: opts} = state
    :ok = adapter.init(opts)
    {:noreply, state}
  end

  # Reloads configuration for a cache adapter
  @doc false
  def handle_call(:config_change, _from, state) do
    %{adapter: adapter, opts: opts} = state
    :ok = adapter.config_change(opts)
    {:reply, :ok, state}
  end

  # Reloads configuration for a cache adapter
  @doc false
  def handle_call(:get_adapter, _from, state) do
    %{adapter: adapter, opts: opts} = state
    {:reply, {adapter, opts}, state}
  end
end
