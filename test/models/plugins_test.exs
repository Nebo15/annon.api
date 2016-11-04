defmodule Gateway.Schemas.PluginTest do
  use Gateway.API.ModelCase

  test "create plugin" do
    assert {:ok, %Plugin{}} = Repo.insert(Plugin.changeset(%Plugin{}, get_plugin_data(1, "jwt")))
  end
end
