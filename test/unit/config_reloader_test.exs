defmodule Gateway.ConfigReloaderTest do
  use Gateway.UnitCase

  test "reload the config cache if it changes" do
    {:ok, api_model} =
      get_api_model_data()
      |> Gateway.DB.Models.API.create()

    # check the config

    new_contents = %{
      "name" => "New name"
    }

    :put
    |> conn("/apis/#{api_model.id}", Poison.encode!(new_contents))
    |> put_req_header("content-type", "application/json")
    |> Gateway.PrivateRouter.call([])

    [{_, api}] = :ets.lookup(:config, {:api, api_model.id})

    assert api.name == "New name"
  end

  test "correct communication between processes" do
    public_config = {:public_http, [port: {:system, :integer, "GATEWAY_PUBLIC_PORT", 5000}]}

    nodes = Gateway.Cluster.spawn()
            |> IO.inspect
  end
end
