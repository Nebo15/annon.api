defmodule Annon.Configuration.PluginTest do
  @moduledoc false
  use Annon.DataCase, async: true
  alias Annon.Configuration.Plugin
  alias Annon.Configuration.Schemas.Plugin, as: PluginSchema
  alias Annon.ConfigurationFactory

  setup do
    %{api: ConfigurationFactory.insert(:api)}
  end

  describe "list_plugins/1" do
    test "returns all plugins", %{api: api} do
      assert [] = Plugin.list_plugins(api.id)
      plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)
      assert [^plugin] = Plugin.list_plugins(api.id)
    end

    test "returns empty list if API does not exists" do
      assert [] = Plugin.list_plugins(Ecto.UUID.generate())
    end
  end

  describe "get_plugin/1" do
    test "returns the plugin with given name", %{api: api} do
      plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)
      assert {:ok, %PluginSchema{} = ^plugin} = Plugin.get_plugin(api.id, plugin.name)
    end

    test "with invalid plugin name returns error", %{api: api} do
      assert {:error, :not_found} = Plugin.get_plugin(api.id, "unkown_plugin")
    end
  end

  describe "create_or_update_plugin/2" do
    test "with valid data creates a new plugin", %{api: api} do
      create_attrs = ConfigurationFactory.params_for(:proxy_plugin, api_id: api.id)
      assert {:ok, %PluginSchema{} = plugin} = Plugin.create_or_update_plugin(api, create_attrs)

      assert plugin.name == create_attrs.name
      assert plugin.is_enabled == create_attrs.is_enabled
      assert plugin.settings["host"] == create_attrs.settings["host"]
      assert plugin.settings["port"] == create_attrs.settings["port"]
      assert plugin.api_id == create_attrs.api_id
    end

    test "updates existing plugin", %{api: api} do
      old_plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)
      update_overrides = [api_id: api.id, name: old_plugin.name, is_enabled: false]
      update_attrs = ConfigurationFactory.params_for(:proxy_plugin, update_overrides)
      assert {:ok, %PluginSchema{} = plugin} = Plugin.create_or_update_plugin(api, update_attrs)

      assert plugin.name == update_attrs.name
      assert plugin.is_enabled == update_attrs.is_enabled
      assert plugin.settings["host"] == update_attrs.settings["host"]
      assert plugin.settings["port"] == update_attrs.settings["port"]
      assert plugin.api_id == update_attrs.api_id
    end

    test "with mismatched names returns error changeset", %{api: api} do
      attrs = %{"name" => "other_unkown_plugin"}
      assert {:error, %Ecto.Changeset{} = ch} = Plugin.create_or_update_plugin(api, "unkown_plugin", attrs)

      assert [
        name: {"name conflicts with request parameters", [validation: :inclusion]},
        name: {"is invalid", [validation: :inclusion]}
      ] == changeset_errors(ch)
    end

    test "with invalid plugin name returns error changeset", %{api: api} do
      attrs = %{"name" => "unkown_plugin"}
      assert {:error, %Ecto.Changeset{}} = Plugin.create_or_update_plugin(api, "unkown_plugin", attrs)
    end

    test "with invalid data returns error changeset", %{api: api} do
      assert {:error, %Ecto.Changeset{}} = Plugin.create_or_update_plugin(api, "proxy", %{})
    end

    test "without plugin name returns error changeset", %{api: api} do
      assert {:error, %Ecto.Changeset{}} = Plugin.create_or_update_plugin(api, %{})
    end
  end

  test "delete_plugin/1 deletes the plugin", %{api: api} do
    plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)
    assert {:ok, %PluginSchema{}} = Plugin.delete_plugin(plugin)
    assert {:error, :not_found} = Plugin.get_plugin(api.id, plugin.name)
  end
end
