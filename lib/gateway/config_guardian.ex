defmodule Gateway.ConfigGuardian do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def reload_config() do
    send(__MODULE__, :reload_config)
    Cluster.Events.publish(:reload_config)
  end

  def init(_) do
    IO.inspect self()
    Cluster.Events.subscribe(self())

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
    IO.puts("#{inspect node()} is going to reload the config now!")

    #   api = Gateway.DB.Models.API.get(1)
    #   :ets.insert(:config, {{:apis, }}, )

    {:noreply, state}
  end
end
