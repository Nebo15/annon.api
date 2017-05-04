defmodule Annon.ManagementAPI.Controllers.APIPluginTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.ConfigurationFactory

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    %{
      conn: conn,
      api: Annon.ConfigurationFactory.insert(:api)
    }
  end

  describe "on index" do
    test "lists all plugins", %{conn: conn, api: api} do
      assert [] ==
        conn
        |> get(plugins_path(api.id))
        |> json_response(200)
        |> Map.get("data")

      plugin1_id = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id).id
      plugin2_id = ConfigurationFactory.insert(:scopes_plugin, api_id: api.id).id

      resp =
        conn
        |> get(plugins_path(api.id))
        |> json_response(200)
        |> Map.get("data")

      assert [%{"id" => ^plugin1_id}, %{"id" => ^plugin2_id}] = resp
    end
  end

  describe "on read" do
    test "returns 404 when plugin does not exist", %{conn: conn, api: api} do
      conn
      |> get(plugin_path(api.id, "proxy"))
      |> json_response(404)
    end

    test "returns 404 when plugin name is not known", %{conn: conn, api: api} do
      conn
      |> get(plugin_path(api.id, "unknown_plugin"))
      |> json_response(404)
    end

    test "returns plugin in valid structure", %{conn: conn, api: api} do
      plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

      resp =
        conn
        |> get(plugin_path(api.id, plugin.name))
        |> json_response(200)
        |> Map.get("data")

      assert resp["name"] == plugin.name
      assert resp["settings"] == plugin.settings
      assert resp["is_enabled"] == plugin.is_enabled
    end
  end

  describe "on create or update" do
    test "creates plugin when plugin does not exist", %{conn: conn, api: api} do
      create_attrs = ConfigurationFactory.params_for(:proxy_plugin, api_id: api.id)

      resp =
        conn
        |> put_json(plugin_path(api.id, create_attrs.name), create_attrs)
        |> json_response(201)
        |> Map.get("data")

      assert resp["name"] == create_attrs.name
      assert resp["api_id"] == create_attrs.api_id
      assert resp["settings"] == create_attrs.settings
      assert resp["is_enabled"] == create_attrs.is_enabled

      assert ^resp =
        conn
        |> get(plugin_path(api.id, create_attrs.name))
        |> json_response(200)
        |> Map.get("data")
    end

    test "updates plugin when it is exists", %{conn: conn, api: api} do
      plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)
      update_overrides = [api_id: api.id, is_enabled: false, settings: %{"host" => "mydomain.com", "port" => 1234}]
      update_attrs = ConfigurationFactory.params_for(:proxy_plugin, update_overrides)

      resp =
        conn
        |> put_json(plugin_path(api.id, update_attrs.name), update_attrs)
        |> json_response(200)
        |> Map.get("data")

      assert plugin.id == resp["id"]
      assert DateTime.to_iso8601(plugin.inserted_at) == resp["inserted_at"]
      assert plugin.name == update_attrs.name
      assert update_attrs.api_id == resp["api_id"]
      assert update_attrs.is_enabled == resp["is_enabled"]
      assert update_attrs.settings["host"] == resp["settings"]["host"]
      assert update_attrs.settings["port"] == resp["settings"]["port"]

      assert ^resp =
        conn
        |> get(plugin_path(api.id, update_attrs.name))
        |> json_response(200)
        |> Map.get("data")
    end

    test "requires all fields to be present on update", %{conn: conn, api: api} do
      plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)
      update_attrs = %{name: plugin.name}

      conn
      |> put_json(plugin_path(api.id, update_attrs.name), update_attrs)
      |> json_response(422)
    end

    test "uses name from path as plugin name", %{conn: conn, api: api} do
      create_attrs = ConfigurationFactory.params_for(:proxy_plugin, api_id: api.id, name: "other_plugin_name")

      resp =
        conn
        |> put_json(plugin_path(api.id, "proxy"), create_attrs)
        |> json_response(201)

      assert %{"data" => %{"name" => "proxy"}} = resp
    end

    test "returns not found error when api does not exist", %{conn: conn, api: api} do
      create_attrs = ConfigurationFactory.params_for(:proxy_plugin, api_id: api.id)

      resp =
        conn
        |> put_json(plugin_path(Ecto.UUID.generate(), create_attrs.name), create_attrs)
        |> json_response(404)

      assert %{"meta" => %{"code" => 404}} = resp
    end
  end

  describe "on delete" do
    test "returns not found error when api does not exist", %{conn: conn, api: api} do
      create_attrs = ConfigurationFactory.params_for(:proxy_plugin, api_id: api.id)

      resp =
        conn
        |> put_json(plugin_path(Ecto.UUID.generate(), create_attrs.name), create_attrs)
        |> json_response(404)

      assert %{"meta" => %{"code" => 404}} = resp
    end

    test "returns no content when plugin does not exist", %{conn: conn, api: api} do
      plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

      resp =
        conn
        |> delete(plugin_path(api.id, plugin.name))
        |> response(204)

      assert "" = resp
    end

    test "returns no content when plugin is deleted", %{conn: conn, api: api} do
      plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

      resp =
        conn
        |> delete(plugin_path(api.id, plugin.name))
        |> response(204)

      assert "" = resp

      conn
      |> get(plugin_path(api.id, plugin.name))
      |> json_response(404)
    end
  end
end
