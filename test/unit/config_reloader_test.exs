defmodule ConfigReloaderTest do
  use Gateway.UnitCase

  test "reload the config cache if it changes" do
    data = get_api_model_data()
    {:ok, api_model} = APIModel.create(data)

    # check the config

    :get
    |> conn("/#{api_model.id}/plugins")
    |> Gateway.PrivateRouter.call([])

    # check the config once again, confirm it's changed
  end

  test "does not reload the config cache during GET requests" do
  end
end
