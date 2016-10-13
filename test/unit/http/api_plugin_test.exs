defmodule Gateway.HTTP.PluginTest do

  @plugin_url "/"

  use Gateway.HTTPTestHelper

  test "GET /apisas" do
#    data =
#      [
#        Gateway.DB.Models.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }}),
#        Gateway.DB.Models.API.create(%{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }})
#      ]
#      |> Enum.map(fn({:ok, e}) -> e end)

    conn =
      conn(:get, "/apis/123/plugins")
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.API.call([])

    IO.inspect conn
#
#    expected_resp = %{
#      meta: %{
#        code: 200,
#      },
#      data: data
#    }
#
#    assert conn.status == 200
#    assert conn.resp_body == Poison.encode!(expected_resp)
  end

end