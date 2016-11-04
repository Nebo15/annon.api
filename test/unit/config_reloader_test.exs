defmodule Gateway.ConfigReloaderTest do
  use Gateway.UnitCase

  import ExUnit.CaptureLog

  test "reload the config cache if it changes" do
    {:ok, api_model} =
      get_api_model_data()
      |> Gateway.DB.Schemas.API.create()

    new_contents = %{
      "name" => "New name"
    }

    update_config = fn ->
      :put
      |> conn("/apis/#{api_model.id}", Poison.encode!(new_contents))
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])
    end

    assert capture_log(update_config) =~ "config cache was warmed up"

    [{_, api}] = :ets.lookup(:config, {:api, api_model.id})

    assert api.name == "New name"
  end
end
