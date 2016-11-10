defmodule Gateway.Controllers.APITest do
  @moduledoc false
  use Gateway.UnitCase, async: true

  describe "/apis" do
    test "GET empty list" do
      conn = "/apis"
      |> send_get()
      |> assert_conn_status()

      assert 0 = Enum.count(Poison.decode!(conn.resp_body)["data"])
    end

    test "GET" do
      apis = Gateway.Factory.insert_pair(:api)

      conn = "/apis"
      |> send_get()
      |> assert_conn_status()

      expected_resp = EView.wrap_body(apis, conn)
      assert Poison.encode!(expected_resp) == conn.resp_body
    end

    test "POST" do
      api = Gateway.Factory.build(:api)

      conn = "/apis"
      |> send_post(api)
      |> assert_conn_status(201)

      assert %{
        "id" => _,
        "updated_at" => _,
        "inserted_at" => _,
        "name" => api_name,
        "request" => %{
          "host" => api_request_host,
          "port" => api_request_port,
          "path" => api_request_path,
          "scheme" => api_request_scheme,
          "method" => api_request_methods
        }
      } = Poison.decode!(conn.resp_body)["data"]

      assert api_name == api.name
      assert api_request_host == api.request.host
      assert api_request_port == api.request.port
      assert api_request_path == api.request.path
      assert api_request_scheme == api.request.scheme
      assert api_request_methods == api.request.method # TODO: rename method to methods?
    end
  end

  describe "/apis/:api_id" do
    test "GET 404" do
      "/apis/0"
      |> send_get()
      |> assert_conn_status(404)
    end

    test "GET" do
      api = Gateway.Factory.insert(:api)

      "/apis/#{api.id}"
      |> send_get()
      |> assert_conn_status()
      |> assert_response_body(api)
    end

    test "PUT" do
      api = Gateway.Factory.insert(:api)
      api_update = Gateway.Factory.build(:api)

      conn = "/apis/#{api.id}"
      |> send_put(api_update)
      |> assert_conn_status()

      assert %{
        "id" => _,
        "updated_at" => _,
        "inserted_at" => _,
        "name" => api_name,
        "request" => %{
          "host" => api_request_host,
          "port" => api_request_port,
          "path" => api_request_path,
          "scheme" => api_request_scheme,
          "method" => api_request_methods
        }
      } = Poison.decode!(conn.resp_body)["data"]

      assert api_name == api_update.name
      assert api_request_host == api_update.request.host
      assert api_request_port == api_update.request.port
      assert api_request_path == api_update.request.path
      assert api_request_scheme == api_update.request.scheme
      assert api_request_methods == api_update.request.method
    end

    test "DELETE" do
      data = Gateway.Factory.insert(:api)

      "/apis/#{data.id}"
      |> send_delete()
      |> assert_conn_status()

      "/apis/#{data.id}"
      |> send_delete()
      |> assert_conn_status(404)
    end
  end
end
