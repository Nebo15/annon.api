defmodule Annon.Cluster do
  @moduledoc false
  # Holds a single public function spawn/0, that spawns a cluster
  # of two nodes: 'node1@127.0.0.1', 'node2@127.0.0.1'

  def spawn do
    # Turn node into a distributed node with the given long name
    :net_kernel.start([:"primary@127.0.0.1"])

    # Allow spawned nodes to fetch all code from this node
    :erl_boot_server.start([])
    allow_boot '127.0.0.1'

    nodes = [:'node1@127.0.0.1', :'node2@127.0.0.1']

    nodes
    |> Enum.map(&Task.async(fn -> spawn_node(&1) end))
    |> Enum.map(&Task.await(&1, 30_000))
  end

  defp spawn_node(node_host) do
    {:ok, new_node} = :slave.start(to_charlist("127.0.0.1"), node_name(node_host), inet_loader_args())
    add_code_paths(new_node)
    transfer_configuration(new_node)
    apply_additional_configuration(new_node)
    ensure_applications_started(new_node)
    {:ok, new_node}
  end

  defp rpc(new_node, module, method, args) do
    :rpc.block_call(new_node, module, method, args)
  end

  defp inet_loader_args do
    to_charlist("-loader inet -hosts 127.0.0.1 -setcookie #{:erlang.get_cookie()}")
  end

  defp allow_boot(host) do
    {:ok, ipv4} = :inet.parse_ipv4_address(host)
    :erl_boot_server.add_slave(ipv4)
  end

  defp add_code_paths(new_node) do
    :rpc.block_call(new_node, :code, :add_paths, [:code.get_path()])
  end

  defp transfer_configuration(node) do
    for {app_name, _, _} <- Application.loaded_applications do
      for {key, val} <- Application.get_all_env(app_name) do
        rpc(node, Application, :put_env, [app_name, key, val])
      end
    end
  end

  defp apply_additional_configuration(new_node) do
    config =
      case new_node do
        :'node1@127.0.0.1' ->
          [
            {:public_http, [port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 6000}]},
            {:management_http, [port: {:system, :integer, "GATEWAY_MANAGEMENT_PORT", 6001}]},
            {:sql_sandbox, false}
          ]
        :'node2@127.0.0.1' ->
          [
            {:public_http, [port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 6002}]},
            {:management_http, [port: {:system, :integer, "GATEWAY_MANAGEMENT_PORT", 6003}]},
            {:sql_sandbox, false}
          ]
      end

    Enum.each(config, fn({key, val}) ->
      rpc(new_node, Application, :put_env, [:annon_api, key, val])
    end)
  end

  defp ensure_applications_started(new_node) do
    rpc(new_node, Application, :ensure_all_started, [:mix])
    rpc(new_node, Mix, :env, [Mix.env()])
    for {app_name, _, _} <- Application.loaded_applications do
      rpc(new_node, Application, :ensure_all_started, [app_name])
    end
  end

  defp node_name(node_host) do
    node_host
    |> to_string
    |> String.split("@")
    |> Enum.at(0)
    |> String.to_atom
  end
end
