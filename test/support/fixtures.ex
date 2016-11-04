defmodule Gateway.Fixtures do
  @moduledoc """
    Fixtures fo tests
  """
  use ExUnit.CaseTemplate
  alias Gateway.DB.Schemas.API, as: APISchema

  def get_api_model_data do
    api_model = APISchema
    |> EctoFixtures.ecto_fixtures()

    api_model
    |> Map.put(:plugins, [get_plugin_data(api_model.id, "jwt"), get_plugin_data(api_model.id, "acl")])
  end

  def get_plugin_data(api_id, "jwt") do
    %{api_id: api_id, name: "jwt", is_enabled: true, settings: %{"signature" => "secret-sign"}}
  end

  def get_plugin_data(api_id, "acl") do
    %{api_id: api_id, name: "acl", is_enabled: true, settings: %{"scope" => "read"}}
  end

  def get_consumer_data do
    Gateway.DB.Schemas.Consumer
    |> EctoFixtures.ecto_fixtures()
  end
end
