defmodule Gateway.PlugValidatorAcceptanceTest do
  use Gateway.AcceptanceCase, async: true

  @api_url "apis"

  test "post hook with empty data" do
    @api_url
    |> post!(Poison.encode!(%{}))
  end

end
