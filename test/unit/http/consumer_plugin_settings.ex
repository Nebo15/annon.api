defmodule Gateway.HTTP.ConsumerPluginSettingsTest do
  @plugin_url "/"

  use Gateway.HTTPTestHelper

  alias Gateway.DB.Repo
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Model.ConsumerPluginSettings

  setup do
    {:ok, consumer} = EctoFixtures.ecto_fixtures(Gateway.DB.Consumer) |> Gateway.DB.Consumer.create
    {:ok, api}      = EctoFixtures.ecto_fixtures(Gateway.DB.Models.API) |> Gateway.DB.Models.API.create

    {:ok, %{external_id: consumer.external_id, api: api}}
  end

  test "GET /consumers/:external_id/plugins", %{external_id: external_id, api: api} do
    plugin_params =
      Gateway.DB.Models.Plugin
      |> EctoFixtures.ecto_fixtures()
      |> Map.put(:api_id, api.id)

    { :ok, plugin } = Gateway.DB.Models.Plugin.create(%Gateway.DB.Models.API{}, plugin_params)

    Gateway.DB.Models.ConsumerPluginSettings.create(external_id, %{plugin_id: plugin.id})

    conn = :get
    |> conn("/consumers/#{external_id}/plugins")
    |> put_req_header("content-type", "application/json")
    |> Gateway.HTTP.Models.Consumers.call([])

    assert Enum.count(Poison.decode!(conn.resp_body)["data"]) == Enum.count(1)
  end

  test "GET /consumers/:external_id/plugins/:name" do
  end

  test "PUT /consumers/:external_id/plugins/:name" do
  end

  test "POST /consumers/:external_id/plugins" do
  end

  test "DELETE /consumers/:external_id/plugins/:name" do
  end
end
