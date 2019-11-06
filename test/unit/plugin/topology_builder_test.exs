defmodule Plugin.Topology do
  alias :digraph, as: Digraph
  alias :digraph_utils, as: DigraphUtils

  def sort(plugins) do
    graph = Digraph.new()

    Enum.each(plugins, fn {plugin, opts} ->
      deps = Keyword.fetch!(opts, :deps)

      Digraph.add_vertex(graph, plugin)

      Enum.each(deps, fn dep ->
        add_dependency(graph, plugin, dep)
      end)
    end)

    case DigraphUtils.is_acyclic(graph) do
      false ->
        circular_path =
          Enum.each(Digraph.vertices(graph), fn vertix ->
            if vs = Digraph.get_short_cycle(graph, vertix), do: Enum.join(vs, " -> ")
          end)

        raise "Plugins dependencies are containing circular dependencies: #{circular_path}"
      true ->
        DigraphUtils.topsort(graph)
    end
  end

  defp add_dependency(_graph, plugin, dep) when plugin == dep,
    do: :ok
  defp add_dependency(graph, plugin, dep) do
    Digraph.add_vertex(graph, plugin)
    Digraph.add_edge(graph, plugin, dep)
  end
end

defmodule Annon.Plugin.TopologyBuilderTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "builds ordered topology" do
    assert [:plugin1, :plugin2, :plugin3, :plugin4] ==
      [
        {:plugin1, deps: [:plugin2]},
        {:plugin2, deps: [:plugin3]},
        {:plugin3, deps: [:plugin4]},
        {:plugin4, deps: [:plugin6]},
      ]
      |> Plugin.Topology.sort()

    assert [:plugin1, :plugin2, :plugin3, :plugin4] ==
      [
        {:plugin2, deps: [:plugin3]},
        {:plugin1, deps: [:plugin3]},
        {:plugin4, deps: [:plugin4]},
        {:plugin3, deps: [:plugin4]},
      ]
      |> Plugin.Topology.sort()

    assert [:plugin3, :plugin4, :plugin2, :plugin1] ==
      [
        {:plugin1, deps: [:plugin2, :plugin3]},
        {:plugin2, deps: [:plugin1]},
        {:plugin3, deps: [:plugin1]},
        {:plugin4, deps: [:plugin2]},
      ]
      |> Plugin.Topology.sort()
  end


  def build_topology() do
    Application.get_env(:annon_api, :plugins_deps) |> Plugin.Topology.sort()
  end
end
