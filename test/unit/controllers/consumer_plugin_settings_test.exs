defmodule Gateway.Controllers.ConsumerPluginSettingsTest do
  use Gateway.UnitCase

  setup do
    consumer = Gateway.Factory.insert(:consumer)
    api = Gateway.Factory.insert(:api)
    plugin = Gateway.Factory.insert(:acl_plugin, api: api)

    {:ok, %{consumer: consumer, api: api, plugin: plugin}}
  end

  test "GET /consumers/:external_id/plugins", %{consumer: consumer, api: api, plugin: plugin2} do
    plugin1 = Gateway.Factory.insert(:idempotency_plugin, api: api)

    Gateway.Factory.insert(:consumer_plugin_settings, consumer: consumer, plugin: plugin1)
    Gateway.Factory.insert(:consumer_plugin_settings, consumer: consumer, plugin: plugin2)

    conn = :get
    |> conn("/#{consumer.external_id}/plugins")
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.Consumers.call([])

    result = Poison.decode!(conn.resp_body)["data"]
    assert 2 == Enum.count(result)
  end

  test "GET /consumers/:external_id/plugins/:name", %{consumer: consumer, plugin: plugin} do
    cust_plugin1 = Gateway.Factory.insert(:consumer_plugin_settings, consumer: consumer, plugin: plugin)

    conn = :get
    |> conn("/#{consumer.external_id}/plugins/#{plugin.name}")
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.Consumers.call([])

    result = Poison.decode!(conn.resp_body)["data"]

    assert cust_plugin1.id == result["id"]
    assert cust_plugin1.external_id == result["external_id"]
    assert cust_plugin1.plugin_id == result["plugin_id"]
    assert cust_plugin1.settings == result["settings"]
    assert result["inserted_at"]
    assert result["updated_at"]
  end

  test "PUT /consumers/:external_id/plugins/:name", %{consumer: consumer, plugin: plugin} do
    params = %{consumer: consumer, plugin: plugin, settings: %{ "a" => 10, "b" => 20}}
    cust_plugin1 = Gateway.Factory.insert(:consumer_plugin_settings, params)

    contents = %{
      settings: %{
        "a" => 1,
        "b" => 2
      }
    }

    conn = :put
    |> conn("/#{consumer.external_id}/plugins/#{plugin.name}", Poison.encode!(contents))
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.Consumers.call([])

    result =
      Poison.decode!(conn.resp_body)["data"]

    assert cust_plugin1.id == result["id"]
    assert cust_plugin1.external_id == result["external_id"]
    assert cust_plugin1.plugin_id == result["plugin_id"]
    assert contents[:settings] == result["settings"]
  end

  test "POST /consumers/:external_id/plugins", %{consumer: consumer, plugin: plugin} do
    contents = %{
      plugin_id: plugin.id,
      settings: %{
        "a" => 1,
        "b" => 2
      }
    }

    conn = :post
    |> conn("/#{consumer.external_id}/plugins", Poison.encode!(contents))
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.Consumers.call([])

    result = Poison.decode!(conn.resp_body)["data"]

    assert result["id"]
    assert consumer.external_id == result["external_id"]
    assert plugin.id == result["plugin_id"]
    assert contents[:settings] == result["settings"]
    assert result["inserted_at"]
    assert result["updated_at"]
  end

  test "DELETE /consumers/:external_id/plugins/:name", %{consumer: consumer, plugin: plugin} do
    Gateway.Factory.insert(:consumer_plugin_settings, plugin: plugin, consumer: consumer)

    conn = :delete
    |> conn("/#{consumer.external_id}/plugins/#{plugin.name}")
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.Consumers.call([])

    assert 200 == conn.status
  end
end
