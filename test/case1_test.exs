defmodule Gateway.Acceptance.Controllers.APITest do
  @moduledoc false
  use Gateway.AcceptanceCase, async: true

  describe "apis/:api_id/" do
    test "PUT" do
      body = create_api() |> get_body()

      id = get_in(body, ["data", "id"])

      get_in(body, ["data", "name"]) |> IO.inspect

      require Logger
      Logger.debug("Test process #{inspect self()} sees API_id=#{id}")

      "apis/#{id}"
      |> put_management_url()
      |> put!(%{name: "updated-name"})
      |> assert_status(200)

      body = "apis/#{id}"
      |> put_management_url()
      |> get!()
      |> assert_status(200)
      |> get_body()

      assert "updated-name" == get_in(body, ["data", "name"])
    end
  end
end
