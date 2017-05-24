defmodule Annon.Monitoring.ClusterStatus do
  @moduledoc """
  This module provides functions to collects status from all nodes in Annon cluster.
  """
  require Logger

  def get_cluster_status do
    cluster_nodes = :erlang.nodes()
    cluster_strategy = get_cluster_strategy()
    nodes_status =
      Enum.reduce(Node.list(), [get_node_status()], fn remote_node, acc ->
        case :rpc.call(remote_node, Annon.Monitoring, :get_node_status, []) do
          {:badrpc, reason} ->
            Logger.error("Unable to fetch status of remote node #{inspect remote_node}, reason: #{inspect reason}")
            acc
          remote_node_status ->
            [remote_node_status] ++ acc
        end
      end)

    %{
      cluster_size: length(cluster_nodes) + 1,
      cluster_strategy: cluster_strategy,
      nodes: nodes_status,
      open_ports: [] # TODO: List open ports
    }
  end

  def get_node_status do
    node = Atom.to_string(:erlang.node())
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
