defmodule Gateway.ClusterConfigReloaderTest do
  @moduledoc """
  Integration test to check that the config cache is reloaded
  across cluster after a config change
  """

  use Gateway.AcceptanceCase

  @tag cluster: true
  test "correct communication between processes" do
    # spawns two nodes:
    # node1@127.0.0.1 and node2@127.0.0.1
    Gateway.Cluster.spawn()

    api_id = create_api()

    Process.sleep(1000)

    assert "Test api" == check_api_on_node(api_id, :name, :'node1@127.0.0.1')
    assert "Test api" == check_api_on_node(api_id, :name, :'node2@127.0.0.1')

    update_api(api_id, "name", "New name")

    Process.sleep(1000)

    assert "New name" == check_api_on_node(api_id, :name, :'node1@127.0.0.1')
    assert "New name" == check_api_on_node(api_id, :name, :'node2@127.0.0.1')

    Gateway.DB.Models.API
    |> Gateway.DB.Repo.delete_all()
  end

  defp check_api_on_node(api_id, field, node) do
    node
    |> :rpc.block_call(:ets, :lookup, [:config, {:api, api_id}])
    |> hd()
    |> elem(1)
    |> Map.get(field)
  end

  defp update_api(api_id, field, value) do
    "http://localhost:5001/apis/#{api_id}"
    |> HTTPoison.put!(Poison.encode!(%{field => value}), [{"content-type", "application/json"}])
  end

  defp create_api do
    map =
      %{
        name: "Test api",
        request: %{
          scheme: "HTTP",
          host: "example.com",
          port: "80",
          path: "/",
          method: "GET"
        }
      }

    "http://localhost:5001/apis"
    |> HTTPoison.post!(Poison.encode!(map), [{"content-type", "application/json"}])
    |> Map.get(:body)
    |> Poison.decode!
    |> Map.get("data")
    |> Map.get("id")
  end
end
