defmodule Gateway.ConfigReloaderTest do
  use Gateway.UnitCase

  import ExUnit.CaptureLog

  test "reload the config cache if it changes" do
    api_model = Gateway.Factory.insert(:api_with_default_plugins)

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
