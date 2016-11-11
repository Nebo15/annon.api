defmodule Gateway.DB.Schemas.PluginTest do
  @moduledoc false
  use Gateway.UnitCase, async: true

  describe "Factories" do
    test "proxy plugin factory returns correct record" do
      params = Gateway.Factory.params_for(:proxy_plugin)
      changeset = Gateway.DB.Schemas.Plugin.changeset(%Gateway.DB.Schemas.Plugin{}, params)

      assert [] == changeset.errors
    end
  end
end
