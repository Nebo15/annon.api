defmodule Gateway.ConfigGuardian do
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

    # Auto-discover existing nodes. To be replaced
    :net_adm.names
    |> elem(1)
    |> Enum.map(fn({vm, _port}) ->
      (vm ++ '@localhost')
      |> List.to_atom
    end)
    |> Enum.filter(fn(vm) -> vm != node() end)
    |> Cluster.Strategy.connect_nodes()

    {:ok, []}
  end

  def handle_info(:reload_config, state) do
    Gateway.ConfigGuardian.do_reload_config()

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
