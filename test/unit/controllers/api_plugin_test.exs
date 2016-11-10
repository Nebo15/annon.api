defmodule Gateway.Controllers.API.PluginTest do
  @moduledoc false
  use Gateway.UnitCase, async: true

  describe "/apis/:api_id/plugins" do
    test "GET empty list" do
      api_model = Gateway.Factory.insert(:api)

      conn = "/apis/#{api_model.id}/plugins"
      |> send_get()
      |> assert_conn_status()

      assert 0 = Enum.count(Poison.decode!(conn.resp_body)["data"])
    end

    test "GET" do
      api_model = Gateway.Factory.insert(:api)
      Gateway.Factory.insert(:acl_plugin, api: api_model)
      Gateway.Factory.insert(:jwt_plugin, api: api_model)

      conn = "/apis/#{api_model.id}/plugins"
      |> send_get()
      |> assert_conn_status()

      assert 2 = Enum.count(Poison.decode!(conn.resp_body)["data"])
    end

    test "POST" do
      api_model = Gateway.Factory.insert(:api)
      plugin_data = Gateway.Factory.build(:acl_plugin, api: api_model)

      conn = "/apis/#{api_model.id}/plugins"
      |> send_post(plugin_data)
      |> assert_conn_status(201)

      resp = Poison.decode!(conn.resp_body)["data"]

      assert resp["name"] == plugin_data.name
      assert resp["settings"] == plugin_data.settings
    end
  end

  describe "/apis/:api_id/plugins/:name" do
    test "GET with invalid id" do
      api_model = Gateway.Factory.insert(:api)
      Gateway.Factory.insert(:acl_plugin, api: api_model)

      "/apis/#{api_model.id}/plugins/unknown_plugin"
      |> send_get()
      |> assert_conn_status(404)
    end

    test "GET" do
      api_model = Gateway.Factory.insert(:api)
      p1 = Gateway.Factory.insert(:acl_plugin, api: api_model)
      p2 = Gateway.Factory.insert(:jwt_plugin, api: api_model)

      conn = "/apis/#{api_model.id}/plugins/#{p1.name}"
      |> send_get()
      |> assert_conn_status()

      assert Poison.decode!(conn.resp_body)["data"]["settings"] == p1.settings

      conn = "/apis/#{api_model.id}/plugins/#{p2.name}"
      |> send_get()
      |> assert_conn_status()

      assert Poison.decode!(conn.resp_body)["data"]["settings"] == p2.settings
    end

    test "PUT" do
      api_model = Gateway.Factory.insert(:api)
      p1 = Gateway.Factory.insert(:jwt_plugin, api: api_model)

      plugin_data = %{name: "validator", settings: %{"schema" => "{}"}}

      conn = "/apis/#{api_model.id}/plugins/#{p1.name}"
      |> send_put(plugin_data)
      |> assert_conn_status()

      resp = Poison.decode!(conn.resp_body)["data"]
      assert resp["name"] == plugin_data.name

      "/apis/#{api_model.id}/plugins/validator"
      |> send_get()
      |> assert_conn_status()

      # Name can be read from uri params
      plugin_data = %{settings: %{"schema" => "{}"}}
      "/apis/#{api_model.id}/plugins/validator"
      |> send_put(plugin_data)
      |> assert_conn_status()

      plugin_data = %{name: "validator", settings: %{"schema" => "{}"}}
      conn = "/apis/#{api_model.id}/plugins/validator"
      |> send_put(plugin_data)
      |> assert_conn_status()

      resp = Poison.decode!(conn.resp_body)["data"]
      assert resp["settings"] == plugin_data.settings
    end

    test "DELETE" do
      api_model = Gateway.Factory.insert(:api)
      acl_plugin = Gateway.Factory.insert(:acl_plugin, api: api_model)
      jwt_plugin = Gateway.Factory.insert(:jwt_plugin, api: api_model)

      "/apis/#{api_model.id}/plugins/#{acl_plugin.name}"
      |> send_get()
      |> assert_conn_status()

      "/apis/#{api_model.id}/plugins/#{acl_plugin.name}"
      |> send_delete()
      |> assert_conn_status()

      "/apis/#{api_model.id}/plugins/#{acl_plugin.name}"
      |> send_get()
      |> assert_conn_status(404)

      "/apis/#{api_model.id}/plugins/#{jwt_plugin.name}"
      |> send_get()
      |> assert_conn_status()
    end
  end
end
