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
    |> Map.put(:plugins, [get_plugin_data(api_model.id, "JWT"), get_plugin_data(api_model.id, "Validator")])
  end

  def get_plugin_data(api_id, name \\ "JWT") do
    Plugin
    |> EctoFixtures.ecto_fixtures()
    |> Map.put(:api_id, api_id)
    |> Map.put(:name, name)
  end

end
