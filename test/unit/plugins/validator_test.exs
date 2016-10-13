defmodule Gateway.Plugins.ValidatorTest do
  use Gateway.HTTPTestHelper

  test "user is redirected when current_user is not assigned" do
    conn = conn(:get, "/", %{})
    |> Gateway.Plugins.Validator.call(%{})

  end

end