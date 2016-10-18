defmodule Gateway.Plugins.GetterTest do
  @moduledoc """
  Testing Gateway.Plugins.Getter
  """

  use Gateway.HTTPTestHelper
  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  test "correctly set config into private part" do

    APIModel
    |> EctoFixtures.ecto_fixtures()
    |> APIModel.create()

    data = get_api_model_data()
    {:ok, %Gateway.DB.Models.API{request: request} = model} = APIModel.create(data)

    %{private: %{api_config: %{} = config}} = :get
    |> conn(request.path, Poison.encode!(%{}))
    |> Map.put(:host, request.host)
    |> Map.put(:port, request.port)
    |> Map.put(:method, request.method)
    |> Map.put(:scheme, request.scheme)
    |> Gateway.Plugins.Getter.call(%{})

    assert config.id == model.id
    assert config.request == request
    assert length(config.plugins) == 2
  end

end
