defmodule Gateway.Fixtures do
  @moduledoc """
    Fixtures fo tests
  """
  use ExUnit.CaseTemplate
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  def get_api_model_data do
    api_model = APIModel
    |> EctoFixtures.ecto_fixtures()

    api_model
    |> Map.put(:plugins, [get_plugin_data(api_model.id, "JWT"), get_plugin_data(api_model.id, "ACL")])
  end

  def get_plugin_data(api_id, "JWT") do
    %{api_id: api_id, name: "JWT", is_enabled: true, settings: %{"signature" => "secret-sign"}}
  end

  def get_plugin_data(api_id, "ACL") do
    %{api_id: api_id, name: "ACL", is_enabled: true, settings: %{"scope" => "read"}}
  end

  def get_consumer_data do
    Gateway.DB.Models.Consumer
    |> EctoFixtures.ecto_fixtures()
  end
end
