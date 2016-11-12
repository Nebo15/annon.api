defmodule Gateway.Acceptance.Controllers.APITest do
  @moduledoc false
  use Gateway.AcceptanceCase

  describe "apis/:api_id/" do
    test "PUT" do
      body = create_api() |> get_body()

      id = get_in(body, ["data", "id"])

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

    test "PUT when model does not exist" do
      "apis/1000"
      |> put_management_url()
      |> put(%{name: "updated-name"})
      |> assert_status(404)
    end

    test "DELETE" do
      body = create_api() |> get_body()

      id = get_in(body, ["data", "id"])

      "apis/#{id}"
      |> put_management_url()
      |> delete()
      |> assert_status(200)

      "apis/#{id}"
      |> put_management_url()
      |> get()
      |> assert_status(404)
    end

    test "DELETE when model does not exist" do
      "apis/1000"
      |> put_management_url()
      |> delete()
      |> assert_status(404)
    end
  end
end
