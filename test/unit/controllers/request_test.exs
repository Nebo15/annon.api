defmodule Gateway.Controllers.RequestTest do
  @moduledoc false
  use Gateway.ControllerUnitCase,
    controller: Gateway.Controllers.Request

  @random_url "random_url"
  @random_data %{"data" => "random"}

  defp create_request do
    :post
    |> conn(@random_url, Poison.encode!(@random_data))
    |> put_req_header("content-type", "application/json")
    |> Gateway.PublicRouter.call([])
  end

  defp create_requests(1), do: create_request()
  defp create_requests(count) do
    create_request()
    create_requests(count - 1)
  end

  describe "/requests" do
    test "GET empty list" do
      conn = "/"
      |> send_get()
      |> assert_conn_status()

      assert 0 == conn.resp_body
      |> Poison.decode!()
      |> Map.fetch!("data")
      |> length()
    end

    test "GET" do
      create_requests(3)

      conn = "/"
      |> send_get()
      |> assert_conn_status()

      assert 3 == conn.resp_body
      |> Poison.decode!()
      |> Map.fetch!("data")
      |> length()
    end
  end

  describe "/requests/:request_id" do
    test "GET 404" do
      "/not_exists"
      |> send_get()
      |> assert_conn_status(404)
    end

    test "GET" do
      id = create_request()
      |> get_resp_header("x-request-id")
      |> Enum.at(0) || ""

      conn = "/#{id}"
      |> send_get()
      |> assert_conn_status()

      assert %{"data" => %{"id" => ^id}} = Poison.decode!(conn.resp_body)
    end

    test "DELETE" do
      id = create_request()
      |> get_resp_header("x-request-id")
      |> Enum.at(0) || ""

      conn = "/#{id}"
      |> send_delete()
      |> assert_conn_status()

      expected_resp = EView.wrap_body(%{}, conn)
      assert Poison.encode!(expected_resp) == conn.resp_body

      "/#{id}"
      |> send_get()
      |> assert_conn_status(404)
    end
  end
end
