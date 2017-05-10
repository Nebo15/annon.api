defmodule Annon.AutoClustering do
  @moduledoc """
  This module implements
  [Annons cache invalidation](http://docs.annon.apiary.io/#introduction/general-features/caching-and-perfomance)
  based on different cluster discovery strategies.
  """
  use GenServer
  require Logger
  alias Annon.Configuration.Matcher

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def reload_config do
    __MODULE__.do_reload_config()

    Enum.each(Node.list(), fn(remote_node) ->
      send({__MODULE__, remote_node}, :reload_config)
    end)
  end

  # Server code
  def init(_opts) do
    Cluster.Events.subscribe(self())

    case Confex.get(:skycluster, :strategy) do
      Cluster.Strategy.Epmd ->
        :net_adm.world_list([:'127.0.0.1'])
      Cluster.Strategy.Kubernetes = s ->
        send(s, :load)
    end

    do_reload_config()

    {:ok, []}
  end

  def handle_info(:reload_config, state) do
    do_reload_config()

    {:noreply, state}
  end

  def handle_info({:nodeup, _}, state) do
    do_reload_config()

    {:noreply, state}
  end

  def handle_info({:nodedown, _}, state) do
    {:noreply, state}
  end

  def do_reload_config do
    :ok = Matcher.config_change()
    Logger.info fn -> "Node #{node()}: config cache was warmed up." end
  end
end
