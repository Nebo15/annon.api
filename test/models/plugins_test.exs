defmodule Gateway.Models.PluginTest do
  use Gateway.API.ModelCase

  test "create plugin" do
    assert {:ok, %Plugin{}} = Repo.insert(Plugin.changeset(%Plugin{}, get_plugin_fixture()))
  end
end
