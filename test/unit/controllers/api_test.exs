defmodule Gateway.Controllers.APITest do
  use Gateway.ControllerUnitCase,
    controller: Gateway.Controllers.API

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
      |> send_post(api)
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
      |> send_put(api_description)
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
end
