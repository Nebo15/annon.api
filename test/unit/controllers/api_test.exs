defmodule Gateway.Controllers.APITest do
  use Gateway.UnitCase

  describe "/apis" do
    test "GET empty list" do
      conn = "/"
      |> send_get()
      |> assert_conn_status()

      assert 0 = Enum.count(Poison.decode!(conn.resp_body)["data"])
    end

    test "GET" do
      data = Gateway.Factory.insert_pair(:api)

      conn = "/"
      |> send_get()
      |> assert_conn_status()

      expected_resp = EView.wrap_body(data, conn)
      assert Poison.encode!(expected_resp) == conn.resp_body
    end

    test "POST" do
      api = %{
        name: "Sample",
        request: %{
          host: "example.com",
          port: 4000,
          path: "/a/b/c",
          scheme: "http",
          method: ["POST"]
        }
      }

      conn = "/"
      |> send_data(api)
      |> assert_conn_status(201)

      assert %{
        "id" => _,
        "updated_at" => _,
        "inserted_at" => _,
        "name" => "Sample",
        "request" => %{
          "host" => "example.com",
          "port" => 4000,
          "path" => "/a/b/c",
          "scheme" => "http",
          "method" => ["POST"]
        }
      } = Poison.decode!(conn.resp_body)["data"]
    end
  end

  describe "/apis/:api_id" do
    test "GET 404" do
      "/0"
      |> send_get()
      |> assert_conn_status(404)
    end

    test "GET" do
      api = Gateway.Factory.insert(:api)

      conn = "/#{api.id}"
      |> send_get()
      |> assert_conn_status()

      expected_resp = EView.wrap_body(api, conn)

      assert Poison.encode!(expected_resp) == Gateway.Test.Helper.remove_type(conn.resp_body)
    end

    test "PUT" do
      api = Gateway.Factory.insert(:api)

      api_description = %{
        name: "New name",
        request: %{
          host: "newhost.com",
          port: 4000,
          path: "/new/path/",
          scheme: "https",
          method: ["POST"]
        }
      }

      conn = "/#{api.id}"
      |> send_data(api_description, :put)
      |> assert_conn_status()

      assert %{
        "id" => _,
        "updated_at" => _,
        "inserted_at" => _,
        "name" => "New name",
        "request" => %{
          "host" => "newhost.com",
          "port" => 4000,
          "path" => "/new/path/",
          "scheme" => "https",
          "method" => ["POST"]
        }
      } = Poison.decode!(conn.resp_body)["data"]
    end

    test "DELETE" do
      data = Gateway.Factory.insert(:api)

      "/#{data.id}"
      |> send_delete()
      |> assert_conn_status()

      "/#{data.id}"
      |> send_delete()
      |> assert_conn_status(404)
    end
  end

  def assert_conn_status(conn, code \\ 200) do
    assert code == conn.status
    conn
  end

  def send_get(path) do
    :get
    |> conn(path)
    |> prepare_conn
  end

  def send_delete(path) do
    :delete
    |> conn(path)
    |> prepare_conn
  end

  def send_data(path, data, method \\ :post) do
    method
    |> conn(path, Poison.encode!(data))
    |> prepare_conn
  end

  defp prepare_conn(conn) do
    conn
    |> put_req_header("content-type", "application/json")
    |> Gateway.Controllers.API.call([])
  end
end
