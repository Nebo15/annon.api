defmodule Gateway.Acceptance.Controllers.APITest do
  @moduledoc false
  use Gateway.AcceptanceCase

  test "update model API" do
    %HTTPoison.Response{body: body} = :api
    |> build_factory_params()
    |> http_api_create()

    id = body
    |> Poison.decode!()
    |> get_in(["data", "id"])

    "apis/#{id}"
    |> put(~s({"name": "updated-name"}), :management)
    |> assert_status(200)

    %HTTPoison.Response{body: body} = "apis/#{id}"
    |> get(:management)
    |> assert_status(200)

    assert "updated-name" == body
    |> Poison.decode!()
    |> get_in(["data", "name"])
  end

  test "update non-existent model API" do
    "apis/1000"
    |> put(~s({"name": "new"}), :management)
    |> assert_status(404)
  end

  test "delete model API" do
    %HTTPoison.Response{body: body} = :api
    |> build_factory_params()
    |> http_api_create()

    id = body
    |> Poison.decode!()
    |> get_in(["data", "id"])

    "apis/#{id}"
    |> delete(:management)
    |> assert_status(200)

    "apis/#{id}"
    |> get(:management)
    |> assert_status(404)
  end

  test "delete non-existent model API" do
    "apis/1000"
    |> delete(:management)
    |> assert_status(404)
  end
end
