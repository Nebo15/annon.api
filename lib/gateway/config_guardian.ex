defmodule Gateway.ConfigGuardian do
  @moduledoc """
  The module is in charge of reloading the config across the cluster
  """

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def reload_config() do
    Gateway.ConfigGuardian.do_reload_config()
    Cluster.Events.publish(:reload_config)
  end

  # Server code

  def init(_) do
    Cluster.Events.subscribe(self())

    :ets.new(:config, [:set, :public, :named_table])

    case Confex.get(:libcluster, :strategy) do
      Cluster.Strategy.Epmd ->
        :net_adm.world_list([:'127.0.0.1'])
      Cluster.Strategy.Kubernetes = s ->
        send(s, :load)
    end

    send(self(), :reload_config)

    {:ok, []}
  end

  def handle_info(:reload_config, state) do
    Gateway.ConfigGuardian.do_reload_config()

    {:noreply, state}
  end

  def handle_info({:nodeup, _}, state) do
    Gateway.ConfigGuardian.do_reload_config()

    {:noreply, state}
  end

  def handle_info({:nodedown, _}, state) do
    {:noreply, state}
  end

  def do_reload_config() do
    apis =
      Gateway.DB.Models.API
      |> Gateway.DB.Repo.all()
      |> Enum.map(fn api -> {{:api, api.id}, api} end)

    :ets.insert(:config, apis)
  end
end
