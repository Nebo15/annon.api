defmodule Gateway.Plugins.APILoaderTest do
  @moduledoc """
  Testing Gateway.Plugins.APILoader
  """

  use Gateway.UnitCase
  alias Gateway.DB.Models.API, as: APIModel

  test "correctly set config into private part" do

    data = get_api_model_data()
    {:ok, %APIModel{request: request} = model} = APIModel.create(data)

    %{private: %{api_config: %{} = config}} = :get
    |> conn(request.path, Poison.encode!(%{}))
    |> Map.put(:host, request.host)
    |> Map.put(:port, request.port)
    |> Map.put(:method, request.method)
    |> Map.put(:scheme, request.scheme)
    |> Gateway.Plugins.APILoader.call(%{})

    assert config.id == model.id
    assert config.request == request
    assert length(config.plugins) == 2
  end

end
