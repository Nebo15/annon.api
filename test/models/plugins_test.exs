defmodule Gateway.Models.PluginTest do
  use Gateway.API.ModelCase

  test "create plugin" do
    assert %Plugin{} = Repo.insert!(Plugin, get_plugin_fixture())
  end
end
