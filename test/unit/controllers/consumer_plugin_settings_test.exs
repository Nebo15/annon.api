defmodule Gateway.Controllers.Consumer.PluginSettingsTest do
  use Gateway.ControllerUnitCase,
    controller: Gateway.Controllers.Consumer.PluginSettings

  setup do
    consumer = Gateway.Factory.insert(:consumer)
    api = Gateway.Factory.insert(:api)
    plugin = Gateway.Factory.insert(:acl_plugin, api: api)

    {:ok, %{consumer: consumer, api: api, plugin: plugin}}
  end

  describe "/consumers/:external_id/plugins" do
    test "GET", %{consumer: consumer, api: api, plugin: plugin2} do
      plugin1 = Gateway.Factory.insert(:idempotency_plugin, api: api)

      Gateway.Factory.insert(:consumer_plugin_settings, consumer: consumer, plugin: plugin1)
      Gateway.Factory.insert(:consumer_plugin_settings, consumer: consumer, plugin: plugin2)

      conn = "/#{consumer.external_id}/plugins"
      |> send_get()
      |> assert_conn_status()

      assert 2 == Enum.count(Poison.decode!(conn.resp_body)["data"])
    end

    test "POST", %{consumer: consumer, plugin: plugin} do
      overrides = %{
        plugin_id: plugin.id,
        settings: %{
          "a" => 1,
          "b" => 2
        }
      }

      conn = "/#{consumer.external_id}/plugins"
      |> send_post(overrides)
      |> assert_conn_status(201)

      assert %{
        "external_id" => external_id,
        "updated_at" => _,
        "inserted_at" => _,
        "plugin_id" => plugin_id,
        "settings" => settings
      } = Poison.decode!(conn.resp_body)["data"]

      assert external_id == consumer.external_id
      assert plugin.id == plugin_id
      assert overrides[:settings] == settings
    end
  end

  describe "/consumers/:external_id/plugins/:name" do
    test "GET /consumers/:external_id/plugins/:name", %{consumer: consumer, plugin: plugin} do
      cust_plugin1 = Gateway.Factory.insert(:consumer_plugin_settings, consumer: consumer, plugin: plugin)

      conn = "/#{consumer.external_id}/plugins/#{plugin.name}"
      |> send_get()
      |> assert_conn_status()

      assert %{
        "id" => id,
        "external_id" => external_id,
        "updated_at" => _,
        "inserted_at" => _,
        "plugin_id" => plugin_id,
        "settings" => settings
      } = Poison.decode!(conn.resp_body)["data"]

      assert cust_plugin1.id == id
      assert cust_plugin1.external_id == external_id
      assert cust_plugin1.plugin_id == plugin_id
      assert cust_plugin1.settings == settings
    end

    test "PUT", %{consumer: consumer, plugin: plugin} do
      cust_plugin1 = Gateway.Factory.insert(:consumer_plugin_settings, %{
        consumer: consumer,
        plugin: plugin,
        settings: %{"a" => 10, "b" => 20}
      })

      overrides = %{
        settings: %{
          "a" => 1,
          "b" => 2
        }
      }

      conn = "/#{consumer.external_id}/plugins/#{plugin.name}"
      |> send_put(overrides)
      |> assert_conn_status()

      assert %{
        "id" => id,
        "external_id" => external_id,
        "updated_at" => _,
        "inserted_at" => _,
        "plugin_id" => plugin_id,
        "settings" => settings
      } = Poison.decode!(conn.resp_body)["data"]

      assert cust_plugin1.id == id
      assert cust_plugin1.external_id == external_id
      assert cust_plugin1.plugin_id == plugin_id
      assert overrides.settings == settings
    end

    test "DELETE", %{consumer: consumer, plugin: plugin} do
      Gateway.Factory.insert(:consumer_plugin_settings, plugin: plugin, consumer: consumer)

      "/#{consumer.external_id}/plugins/#{plugin.name}"
      |> send_delete()
      |> assert_conn_status()

      "/#{consumer.external_id}/plugins/#{plugin.name}"
      |> send_get()
      |> assert_conn_status(404)
    end
  end
end
