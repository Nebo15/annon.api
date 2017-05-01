defmodule Annon.RoutersTest do
  @moduledoc false
  use Annon.UnitCase, async: true

  describe "default match works" do
    test "on public router" do
      conn = :get
      |> conn("/foo")
      |> put_req_header("content-type", "application/json")
      |> Annon.PublicRouter.call([])

      assert 404 == conn.status
    end

    test "on management router" do
      conn = :get
      |> conn("/foo")
      |> put_req_header("content-type", "application/json")
      |> Annon.ManagementAPI.Router.call([])

      assert 404 == conn.status
    end

    test "on private router" do
      conn = :get
      |> conn("/foo")
      |> put_req_header("content-type", "application/json")
      |> Annon.PrivateRouter.call([])

      assert 404 == conn.status
    end
  end

  describe "error match works" do
    test "on management router" do
      conn = :get
      |> conn("/apis/binary_id")
      |> put_req_header("content-type", "application/bson")

      assert_raise Ecto.Query.CastError, fn ->
        Annon.ManagementAPI.Router.call(conn, [])
      end

      assert {400, _headers, _body} = sent_resp(conn)
    end
  end
end
