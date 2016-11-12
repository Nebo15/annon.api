defmodule Gateway.ClusterConfigReloaderTest do
  @moduledoc false
  # Integration test to check that the config cache is reloaded across cluster after a config change
  use Gateway.AcceptanceCase
  require Logger

  setup do
    Gateway.DB.Schemas.API
    |> Gateway.DB.Configs.Repo.delete_all()

    on_exit(fn ->
      Gateway.DB.Schemas.API
      |> Gateway.DB.Configs.Repo.delete_all()
    end)
  end

  @tag pending: true
  @tag cluster: true
  test "correct communication between processes" do
    # spawns two nodes:
    # node1@127.0.0.1 and node2@127.0.0.1
    Gateway.Cluster.spawn()

    api_id = create_api() |> get_body() |> get_in(["data", "id"])

    ensure_the_change_is_visible_on(:'node1@127.0.0.1')
    ensure_the_change_is_visible_on(:'node2@127.0.0.1')

    assert "Test api" == check_api_on_node(api_id, :name, :'node1@127.0.0.1')
    assert "Test api" == check_api_on_node(api_id, :name, :'node2@127.0.0.1')

    update_api(api_id, "name", "New name")

    ensure_the_change_is_visible_on(:'node1@127.0.0.1')
    ensure_the_change_is_visible_on(:'node2@127.0.0.1')

    assert "New name" == check_api_on_node(api_id, :name, :'node1@127.0.0.1')
    assert "New name" == check_api_on_node(api_id, :name, :'node2@127.0.0.1')
  end

  defp ensure_the_change_is_visible_on(nodename, iteration \\ 1)
  defp ensure_the_change_is_visible_on(_nodename, iteration) when iteration > 5,
    do: flunk "Changes is not distributed to other nodes"
  defp ensure_the_change_is_visible_on(nodename, iteration) do
    case :rpc.block_call(nodename, Gateway.DB.Configs.Repo, :all, [Gateway.DB.Schemas.API]) do
      [] ->
        Logger.debug("Changes not visible, retry in 1 second..")
        :timer.sleep(1000)
        ensure_the_change_is_visible_on(nodename, iteration + 1)
      apis ->
        apis
    end
  end

  defp check_api_on_node(api_id, field, nodename) do
    node_cache = nodename
    |> :rpc.block_call(:ets, :lookup, [:config, {:api, api_id}])

    case node_cache do
      [] -> flunk "Changes is not distributed to node #{nodename}"
      list ->
        list
        |> List.first()
        |> elem(1)
        |> Map.get(field)
    end
  end

  defp update_api(api_id, field, value) do
    "apis/#{api_id}"
    |> put_management_url()
    |> post!(%{field => value})
    |> assert_status(200)
  end
end
