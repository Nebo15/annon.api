defmodule Gateway.AutoClustering do
  @moduledoc """
  The module is in charge of reloading the config across the cluster
  """

  require Logger

  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def reload_config do
    Gateway.AutoClustering.do_reload_config()

    Enum.each(Node.list(), fn(remote_node) ->
      send({Gateway.AutoClustering, remote_node}, :reload_config)
    end)
  end

  # Server code

  def init(_opts) do
    Cluster.Events.subscribe(self())

    :ets.new(:config, [:set, :public, :named_table])

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
    Gateway.AutoClustering.do_reload_config()

    {:noreply, state}
  end

  def handle_info({:nodeup, _}, state) do
    Gateway.AutoClustering.do_reload_config()

    {:noreply, state}
  end

  def handle_info({:nodedown, _}, state) do
    {:noreply, state}
  end

  import Ecto.Query, only: [from: 2]

  def do_reload_config do
    query = from a in Gateway.DB.Schemas.API,
            join: Gateway.DB.Schemas.Plugin,
            preload: [:plugins]

    apis = query
    |> Gateway.DB.Configs.Repo.all()
    |> Enum.map(fn api -> {{:api, api.id}, api} end)

    :ets.insert(:config, apis)

    Logger.debug("Node #{node()}: config cache was warmed up.")
  end
end
