defmodule Gateway.ClusterConfigReloaderTest do
  use Gateway.UnitCase

  @tag cluster: true
  test "correct communication between processes" do
    # spawns two nodes with "private" ports
    # at 6001 and 6003 respectively
    Gateway.Cluster.spawn()

    {:ok, api} =
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
      |> Gateway.DB.Models.API.create()

    Process.sleep(1000)

    assert "Test api" == check_api_on_node(api.id, :name, :'node1@127.0.0.1')
    assert "Test api" == check_api_on_node(api.id, :name, :'node2@127.0.0.1')

    update_api(api.id, "name", "New name")

    Process.sleep(1000)

    assert "New name" == check_api_on_node(api.id, :name, :'node1@127.0.0.1')
    assert "New name" == check_api_on_node(api.id, :name, :'node2@127.0.0.1')

    Gateway.DB.Models.API
    |> Gateway.DB.Repo.delete_all()
  end

  defp check_api_on_node(api_id, field, node) do
    [{_, api}] = :rpc.block_call(node, :ets, :lookup, [:config, {:api, api_id}])

    Map.get(api, field)
  end

  defp update_api(api_id, field, value) do
    :put
    |> conn("/apis/#{api_id}", Poison.encode!(%{field => value}))
    |> put_req_header("content-type", "application/json")
    |> Gateway.PrivateRouter.call([])
  end
end
