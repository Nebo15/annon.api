defmodule Gateway.HTTP.APITest do
  use Gateway.HTTPTestHelper

  test "GET /apis" do
    data =
      [
        Gateway.DB.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }}),
        Gateway.DB.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }})
      ]
      |> Enum.map(fn({:ok, e}) -> e end)

    conn =
      conn(:get, "/")
      |> Gateway.HTTP.API.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: data
    }

    assert conn.status == 200
    assert conn.resp_body == Poison.encode!(expected_resp)
  end
end
