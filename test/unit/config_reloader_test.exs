defmodule Annon.ManagementAPI.ConfigReloaderPlugTest do
  @moduledoc false
  use Annon.UnitCase

  import ExUnit.CaptureLog

  setup do
    saved_config = Application.get_env(:annon_api, :cache_storage)
    Application.put_env(:annon_api, :cache_storage, {:system, :module, "CACHE_STORAGE", Annon.Cache.EtsAdapter})

    on_exit fn ->
      Application.put_env(:annon_api, :cache_storage, saved_config)
    end

    :ok
  end

  test "reload the config cache if it changes" do
    api_model = Annon.Factory.insert(:api)
    Annon.Factory.insert(:acl_plugin, api: api_model)

    new_contents = %{
      "name" => "New name"
    }

    update_config = fn ->
      :put
      |> conn("/apis/#{api_model.id}", Poison.encode!(new_contents))
      |> put_req_header("content-type", "application/json")
      |> Annon.ManagementAPI.Router.call([])
    end

    assert capture_log(update_config) =~ "config cache was warmed up"

    [{_, api}] = :ets.lookup(:config, {:api, api_model.id})

    assert api.name == "New name"
  end
end
