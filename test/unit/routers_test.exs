defmodule Gateway.RoutersTest do
  @moduledoc false
  use Gateway.UnitCase
  use Plug.Test

  describe "default match works" do
    test "on public router" do
      conn = :get
      |> conn("/foo")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PublicRouter.call([])

      assert 404 == conn.status
    end

    test "on private router" do
      conn = :get
      |> conn("/foo")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

      assert 404 == conn.status
    end
  end

  describe "error match works" do
    test "on private router" do
      conn = :get
      |> conn("/apis/binary_id")
      |> put_req_header("content-type", "application/bson")

      assert_raise Ecto.Query.CastError, fn ->
        Gateway.PrivateRouter.call(conn, [])
      end

      assert {500, _headers, _body} = sent_resp(conn)
    end
  end
end
