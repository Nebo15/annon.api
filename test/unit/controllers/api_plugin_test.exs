defmodule Annon.ManagementAPI.Controllers.API.PluginTest do
  @moduledoc false
  use Annon.UnitCase, async: true

  describe "/apis/:api_id/plugins" do
    test "GET empty list" do
      api_model = Annon.ConfigurationFactory.insert(:api)

      conn = "/apis/#{api_model.id}/plugins"
      |> call_get()
      |> assert_conn_status()

      assert 0 = Enum.count(Poison.decode!(conn.resp_body)["data"])
    end

    test "GET" do
      api_model = Annon.ConfigurationFactory.insert(:api)
      Annon.ConfigurationFactory.insert(:acl_plugin, api: api_model)
      Annon.ConfigurationFactory.insert(:jwt_plugin, api: api_model)

      conn = "/apis/#{api_model.id}/plugins"
      |> call_get()
      |> assert_conn_status()

      assert 2 = Enum.count(Poison.decode!(conn.resp_body)["data"])
    end

    test "POST" do
      api_model = Annon.ConfigurationFactory.insert(:api)
      plugin_data = Annon.ConfigurationFactory.build(:acl_plugin, api: api_model)

      conn = "/apis/#{api_model.id}/plugins"
      |> call_post(plugin_data)
      |> assert_conn_status(201)

      resp = Poison.decode!(conn.resp_body)["data"]

      assert resp["name"] == plugin_data.name
      assert resp["settings"] == plugin_data.settings
    end
  end

  describe "/apis/:api_id/plugins/:name" do
    test "GET with invalid id" do
      api_model = Annon.ConfigurationFactory.insert(:api)
      Annon.ConfigurationFactory.insert(:acl_plugin, api: api_model)

      "/apis/#{api_model.id}/plugins/unknown_plugin"
      |> call_get()
      |> assert_conn_status(404)
    end

    test "GET" do
      api_model = Annon.ConfigurationFactory.insert(:api)
      p1 = Annon.ConfigurationFactory.insert(:acl_plugin, api: api_model)
      p2 = Annon.ConfigurationFactory.insert(:jwt_plugin, api: api_model)

      conn = "/apis/#{api_model.id}/plugins/#{p1.name}"
      |> call_get()
      |> assert_conn_status()

      assert Poison.decode!(conn.resp_body)["data"]["settings"] == p1.settings

      conn = "/apis/#{api_model.id}/plugins/#{p2.name}"
      |> call_get()
      |> assert_conn_status()

      assert Poison.decode!(conn.resp_body)["data"]["settings"] == p2.settings
    end

    test "PUT" do
      api_model = Annon.ConfigurationFactory.insert(:api)
      p1 = Annon.ConfigurationFactory.insert(:validator_plugin, api: api_model)

      settings = %{
        "rules" => [
          %{"methods" => ["PUT"], "path" => ".*", "schema" => %{"some_field" => "some_value"}},
        ]
      }
      plugin_data = %{name: "validator", settings: settings}

      conn = "/apis/#{api_model.id}/plugins/#{p1.name}"
      |> call_put(plugin_data)
      |> assert_conn_status()

      resp = Poison.decode!(conn.resp_body)["data"]
      assert resp["name"] == plugin_data.name

      "/apis/#{api_model.id}/plugins/validator"
      |> call_get()
      |> assert_conn_status()

      # Name can be read from uri params
      plugin_data = %{settings: settings}
      "/apis/#{api_model.id}/plugins/validator"
      |> call_put(plugin_data)
      |> assert_conn_status()

      plugin_data = %{name: "validator", settings: settings}
      conn = "/apis/#{api_model.id}/plugins/validator"
      |> call_put(plugin_data)
      |> assert_conn_status()

      assert %{
        "settings" => %{
          "rules" => [%{"methods" => ["PUT"], "path" => ".*", "schema" => %{"some_field" => "some_value"}}],
        }
      } = Poison.decode!(conn.resp_body)["data"]
    end

    test "PUT (renaming a plugin)" do
      api_model = Annon.ConfigurationFactory.insert(:api)
      p1 = Annon.ConfigurationFactory.insert(:jwt_plugin, api: api_model)

      settings = %{
        "rules" => [
          %{"methods" => ["PUT"], "path" => ".*", "schema" => %{"some_field" => "some_value"}},
        ]
      }

      plugin_data = %{name: "validator", settings: settings}

      conn = "/apis/#{api_model.id}/plugins/#{p1.name}"
      |> call_put(plugin_data)

      assert %{
        "type" => "validation_failed"
      } = Poison.decode!(conn.resp_body)["error"]
    end

    test "DELETE" do
      api_model = Annon.ConfigurationFactory.insert(:api)
      acl_plugin = Annon.ConfigurationFactory.insert(:acl_plugin, api: api_model)
      jwt_plugin = Annon.ConfigurationFactory.insert(:jwt_plugin, api: api_model)

      "/apis/#{api_model.id}/plugins/#{acl_plugin.name}"
      |> call_get()
      |> assert_conn_status()

      "/apis/#{api_model.id}/plugins/#{acl_plugin.name}"
      |> call_delete()
      |> assert_conn_status(204)

      "/apis/#{api_model.id}/plugins/#{acl_plugin.name}"
      |> call_get()
      |> assert_conn_status(404)

      assert [%{name: "jwt"}] = Annon.Configuration.Plugin.list_plugins(api_model.id)

      "/apis/#{api_model.id}/plugins/#{jwt_plugin.name}"
      |> call_get()
      |> assert_conn_status()
    end
  end
end
