defmodule Gateway.ConfigReloaderTest do
  @moduledoc false
  use Gateway.UnitCase

  import ExUnit.CaptureLog

  test "reload the config cache if it changes" do
    api_model = Gateway.Factory.insert(:api)
    Gateway.Factory.insert(:acl_plugin, api: api_model)

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
