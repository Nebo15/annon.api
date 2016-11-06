defmodule Gateway.Controllers.APITest do
  use Gateway.UnitCase

  @correct_api_data %{
    name: "Sample",
    request: %{
      path: "/",
      port: 3000,
      scheme: "https",
      host: "sample.com",
      method: "GET"
      }
    }

  test "GET /apis" do
    data =
      [
        Gateway.DB.Schemas.API.create(put_in(%{@correct_api_data | name: "Sample one"}, [:request, :port], 3000)),
        Gateway.DB.Schemas.API.create(put_in(%{@correct_api_data | name: "Sample two"}, [:request, :port], 3001))
      ]
      |> Enum.map(fn({:ok, e}) -> e end)

    conn = :get
    |> conn("/")
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.API.call([])

    expected_resp = EView.wrap_body(data, conn)

    assert 200 == conn.status
    assert Poison.encode!(expected_resp) == conn.resp_body
  end

  test "GET /apis/:api_id" do
    {:ok, data} = Gateway.DB.Schemas.API.create(@correct_api_data)

    conn = :get
    |> conn("/#{data.id}")
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.API.call([])

    expected_resp = EView.wrap_body(data, conn)

    assert 200 == conn.status
    assert Poison.encode!(expected_resp) == Gateway.Test.Helper.remove_type(conn.resp_body)
  end

  test "POST /apis" do
    contents = %{
      name: "Sample",
      request: %{
        host: "example.com",
        port: 4000,
        path: "/a/b/c",
        scheme: "http",
        method: "POST"
      }
    }

    conn = :post
    |> conn("/", Poison.encode!(contents))
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.API.call([])

    assert conn.status == 201
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["id"]
    assert resp["updated_at"]
    assert resp["inserted_at"]

    assert "Sample" == resp["name"]
    assert "example.com" == resp["request"]["host"]
    assert 4000 == resp["request"]["port"]
    assert "/a/b/c" == resp["request"]["path"]
    assert "http" == resp["request"]["scheme"]
  end

  test "PUT /apis/:api_id" do
    {:ok, data} = Gateway.DB.Schemas.API.create(@correct_api_data)

    new_contents = %{
      name: "New name",
      request: %{
        host: "newhost.com",
        port: 4000,
        path: "/new/path/",
        scheme: "https",
        method: "POST"
      }
    }

    conn = :put
    |> conn("/#{data.id}", Poison.encode!(new_contents))
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.API.call([])

    assert conn.status == 200
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["id"]
    assert resp["updated_at"]

    assert "New name" == resp["name"]
    assert "newhost.com" == resp["request"]["host"]
    assert 4000 == resp["request"]["port"]
    assert "/new/path/" == resp["request"]["path"]
    assert "https" == resp["request"]["scheme"]
    assert "POST" == resp["request"]["method"]
  end

  test "DELETE /apis/:api_id" do
    {:ok, data} = Gateway.DB.Schemas.API.create(@correct_api_data)

    conn = :delete
    |> conn("/#{data.id}")
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.API.call([])

    Poison.decode!(conn.resp_body)

    assert 200 == conn.status

    # ToDo: bug https://finstar.atlassian.net/browse/OSL-502
#    conn = :delete
#    |> conn("/#{data.id}")
#    |> put_req_header("content-type", "application/json")
#    |> Gateway.Controllers.API.call([])
#    assert 404 == conn.status
  end
end
