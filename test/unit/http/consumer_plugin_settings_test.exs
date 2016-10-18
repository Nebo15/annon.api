defmodule Gateway.HTTP.ConsumerPluginSettingsTest do
  use Gateway.HTTPTestHelper

  setup do
    consumer = create_fixture(Gateway.DB.Models.Consumer)
    api      = create_fixture(Gateway.DB.Models.API)
    plugin   = create_plugin(api.id)

    {:ok, %{external_id: consumer.external_id, api: api, plugin: plugin}}
  end

  test "GET /consumers/:external_id/plugins", %{external_id: external_id, api: api} do
    plugin1 = create_plugin(api.id)
    plugin2 = create_plugin(api.id)

    Gateway.DB.Models.ConsumerPluginSettings.create(external_id, %{plugin_id: plugin1.id})
    Gateway.DB.Models.ConsumerPluginSettings.create(external_id, %{plugin_id: plugin2.id})

    conn = :get
    |> conn("/consumers/#{external_id}/plugins")
    |> put_req_header("content-type", "application/json")
    |> Gateway.HTTP.Consumers.call([])

    result =
      Poison.decode!(conn.resp_body)["data"]

    assert Enum.count(result) == 2
  end

  test "GET /consumers/:external_id/plugins/:name", %{external_id: external_id, plugin: plugin} do
    { :ok, cust_plugin1 } = Gateway.DB.Models.ConsumerPluginSettings.create(external_id, %{plugin_id: plugin.id})

    conn = :get
    |> conn("/consumers/#{external_id}/plugins")
    |> put_req_header("content-type", "application/json")
    |> Gateway.HTTP.Consumers.call([])

    [result] =
      Poison.decode!(conn.resp_body)["data"]

    assert result["id"] == cust_plugin1.id
    assert result["external_id"] == cust_plugin1.external_id
    assert result["plugin_id"] == cust_plugin1.plugin_id
    assert result["settings"] == cust_plugin1.settings
    assert result["inserted_at"]
    assert result["updated_at"]
  end

  test "PUT /consumers/:external_id/plugins/:name", %{external_id: external_id, plugin: plugin} do
    { :ok, cust_plugin1 } = Gateway.DB.Models.ConsumerPluginSettings.create(external_id, %{plugin_id: plugin.id, settings: %{ "a" => 10, "b" => 20}})

    contents = %{
      settings: %{
        "a" => 1,
        "b" => 2
      }
    }

    conn = :put
    |> conn("/consumers/#{external_id}/plugins/#{plugin.name}", Poison.encode!(contents))
    |> put_req_header("content-type", "application/json")
    |> Gateway.HTTP.Consumers.call([])

    result =
      Poison.decode!(conn.resp_body)["data"]

    assert result["id"] == cust_plugin1.id
    assert result["external_id"] == cust_plugin1.external_id
    assert result["plugin_id"] == cust_plugin1.plugin_id
    assert result["settings"] == contents[:settings]
  end

  test "POST /consumers/:external_id/plugins", %{external_id: external_id, plugin: plugin} do
    contents = %{
      plugin_id: plugin.id,
      settings: %{
        "a" => 1,
        "b" => 2
      }
    }

    conn = :post
    |> conn("/consumers/#{external_id}/plugins", Poison.encode!(contents))
    |> put_req_header("content-type", "application/json")
    |> Gateway.HTTP.Consumers.call([])

    result =
      Poison.decode!(conn.resp_body)["data"]

    assert result["id"]
    assert result["external_id"] == external_id
    assert result["plugin_id"] == plugin.id
    assert result["settings"] == contents[:settings]
    assert result["inserted_at"]
    assert result["updated_at"]
  end

  test "DELETE /consumers/:external_id/plugins/:name", %{external_id: external_id, plugin: plugin} do
    Gateway.DB.Models.ConsumerPluginSettings.create(external_id, %{plugin_id: plugin.id, settings: %{ "a" => 10, "b" => 20}})

    conn = :delete
    |> conn("/consumers/#{external_id}/plugins/#{plugin.name}")
    |> put_req_header("content-type", "application/json")
    |> Gateway.HTTP.Consumers.call([])

    result =
      Poison.decode!(conn.resp_body)

    assert result["meta"]["description"] == "Resource was deleted"
  end

  defp create_fixture(module) do
    {:ok, entity} =
      module
      |> EctoFixtures.ecto_fixtures()
      |> module.create

    entity
  end

  defp create_plugin(api_id) do
    params =
      Gateway.DB.Models.Plugin
      |> EctoFixtures.ecto_fixtures()
      |> Map.put(:api_id, api_id)

    %Gateway.DB.Models.API{}
    |> Gateway.DB.Models.Plugin.create(params)
    |> elem(1)
  end
end
