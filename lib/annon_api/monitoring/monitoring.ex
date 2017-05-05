defmodule Annon.Monitoring do
  def get_status do
    cluster_nodes = :erlang.nodes()
    cluster_strategy = get_cluster_strategy()
    nodes_info = [get_node_status(:erlang.node())] # TODO: Return other nodes info

    %{
      cluster_size: length(cluster_nodes) + 1,
      cluster_strategy: cluster_strategy,
      nodes: nodes_info,
      open_ports: [] # TODO: List open ports
    }
  end

  def get_node_status(erl_node) do
    node = Atom.to_string(erl_node)
    otp_release = to_string(:erlang.system_info(:otp_release))
    run_queue = :erlang.statistics(:run_queue)
    process_count = :erlang.system_info(:process_count)
    process_limit = :erlang.system_info(:process_limit)
    {wall_clock, _} = :erlang.statistics(:wall_clock)
    node_uptime = wall_clock / 1000

    %{
      name: node,
      otp_release: otp_release,
      run_queue: run_queue,
      process_count: process_count,
      process_limit: process_limit,
      uptime: node_uptime
    }
  end

  defp get_cluster_strategy do
    case Confex.get(:skycluster, :strategy) do
      Cluster.Strategy.Epmd -> "epmd"
      Cluster.Strategy.Kubernetes -> "kubernetes"
      Cluster.Strategy.Gossip -> "gossip"
    end
  end
end
