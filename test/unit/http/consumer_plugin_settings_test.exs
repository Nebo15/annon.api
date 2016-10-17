defmodule Gateway.HTTP.ConsumerPluginSettingsTest do
  use Gateway.HTTPTestHelper

  alias Gateway.DB.Repo
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Model.ConsumerPluginSettings

  setup do
    consumer = create_fixture(Gateway.DB.Models.Consumer)
    api      = create_fixture(Gateway.DB.Models.API)

    {:ok, %{external_id: consumer.external_id, api: api}}
  end

  test "GET /consumers/:external_id/plugins", %{external_id: external_id, api: api} do
    plugin_params1 =
      Gateway.DB.Models.Plugin
      |> EctoFixtures.ecto_fixtures()
      |> Map.put(:api_id, api.id)

    plugin_params2 =
      Gateway.DB.Models.Plugin
      |> EctoFixtures.ecto_fixtures()
      |> Map.put(:api_id, api.id)

    { :ok, plugin1 } = Gateway.DB.Models.Plugin.create(%Gateway.DB.Models.API{}, plugin_params1)
    { :ok, plugin2 } = Gateway.DB.Models.Plugin.create(%Gateway.DB.Models.API{}, plugin_params2)

    Gateway.DB.Models.ConsumerPluginSettings.create(external_id, %{plugin_id: plugin1.id})
    Gateway.DB.Models.ConsumerPluginSettings.create(external_id, %{plugin_id: plugin2.id})

    conn = :get
    |> conn("/consumers/#{external_id}/plugins")
    |> put_req_header("content-type", "application/json")
    |> Gateway.HTTP.Consumers.call([])

    x =
      Poison.decode!(conn.resp_body)["data"]

    assert Enum.count(x) == 2
  end

  test "GET /consumers/:external_id/plugins/:name" do
  end

  test "PUT /consumers/:external_id/plugins/:name" do
  end

  test "POST /consumers/:external_id/plugins" do
  end

  test "DELETE /consumers/:external_id/plugins/:name" do
  end

  defp create_fixture(module) do
    {:ok, entity} =
      module
      |> EctoFixtures.ecto_fixtures()
      |> module.create

    entity
  end
end
