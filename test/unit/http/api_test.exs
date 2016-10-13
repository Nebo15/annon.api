defmodule Gateway.HTTP.APITest do
  use Gateway.HTTPTestHelper

  @correct_api_data %{ name: "Sample", request: %{ path: "/", port: "3000", scheme: "https", host: "sample.com" }}

  test "GET /apis" do
    data =
      [
        Gateway.DB.API.create(@correct_api_data),
        Gateway.DB.API.create(@correct_api_data)
      ]
      |> Enum.map(fn({:ok, e}) -> e end)

    conn =
      :get
      |> conn("/")
      |> put_req_header("content-type", "application/json")
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

  test "GET /apis/:api_id" do
    { :ok, data } =
      Gateway.DB.API.create(@correct_api_data)

    conn =
      :get
      |> conn("/#{data.id}")
      |> put_req_header("content-type", "application/json")
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

  test "POST /apis" do
    contents = %{
      name: "Sample",
      request: %{
        host: "example.com",
        port: "4000",
        path: "/a/b/c",
        scheme: "http"
      }
    }

    conn =
      :post
      |> conn("/", Poison.encode!(contents))
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.API.call([])

    assert conn.status == 201
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["id"]
    assert resp["updated_at"]
    assert resp["inserted_at"]

    assert resp["name"] == "Sample"
    assert resp["request"]["host"] == "example.com"
    assert resp["request"]["port"] == "4000"
    assert resp["request"]["path"] == "/a/b/c"
    assert resp["request"]["scheme"] == "http"
  end

  test "PUT /apis/:api_id" do
    { :ok, data } =
      Gateway.DB.API.create(@correct_api_data)

    new_contents = %{
      name: "New name",
      request: %{
        host: "newhost.com",
        port: "4000",
        path: "/new/path/",
        scheme: "https"
      }
    }

    conn =
      :put
      |> conn("/#{data.id}", Poison.encode!(new_contents))
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.API.call([])

    assert conn.status == 200
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["id"]
    assert resp["updated_at"]

    assert resp["name"] == "New name"
    assert resp["request"]["host"] == "newhost.com"
    assert resp["request"]["port"] == "4000"
    assert resp["request"]["path"] == "/new/path/"
    assert resp["request"]["scheme"] == "https"
  end

  test "DELETE /apis/:api_id" do
    { :ok, data } =
      Gateway.DB.API.create(@correct_api_data)

    conn =
      :delete
      |> conn("/#{data.id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.API.call([])

    resp = Poison.decode!(conn.resp_body)

    assert conn.status == 200
    assert resp["data"]["id"] == data.id
    assert resp["meta"]["description"] == "Resource was deleted"
  end
end
