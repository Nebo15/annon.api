defmodule Gateway.Acceptance.Private.APITest do
  use Gateway.AcceptanceCase

  test "update model API" do
    %HTTPoison.Response{body: body} = get_api_model_data()
    |> http_api_create()

    id = body
    |> Poison.decode!()
    |> get_in(["data", "id"])

    "apis/#{id}"
    |> put(~s({"name": "updated-name"}), :private)
    |> assert_status(200)

    %HTTPoison.Response{body: body} = "apis/#{id}"
    |> get(:private)
    |> assert_status(200)

    assert "updated-name" == body
    |> Poison.decode!()
    |> get_in(["data", "name"])
  end

  test "update non-existent model API" do
    "apis/1000"
    |> put(~s({"name": "new"}), :private)
    |> assert_status(404)
  end

  test "delete model API" do
    %HTTPoison.Response{body: body} = get_api_model_data()
    |> http_api_create()

    id = body
    |> Poison.decode!()
    |> get_in(["data", "id"])

    "apis/#{id}"
    |> delete(:private)
    |> assert_status(200)

    "apis/#{id}"
    |> get(:private)
    |> assert_status(404)
  end

  test "delete non-existent model API" do
    "apis/1000"
    |> delete(:private)
    |> assert_status(404)
  end
end
