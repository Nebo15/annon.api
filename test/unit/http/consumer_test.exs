defmodule Gateway.HTTP.ConsumerTest do
  use Gateway.UnitCase
  alias Gateway.Test.Helper

  test "GET /consumers" do
    consumer1 = get_consumer_data() |> Gateway.DB.Schemas.Consumer.create()
    consumer2 = get_consumer_data() |> Gateway.DB.Schemas.Consumer.create()

    data =
      [
        consumer1,
        consumer2
      ]
      |> Enum.map(fn({:ok, e}) -> e end)

    conn = :get
      |> conn("/consumers")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    expected_resp = EView.wrap_body(data, conn)

    assert 200 == conn.status
    assert Poison.encode!(expected_resp) == conn.resp_body
  end

  test "GET /consumers/:external_id" do
    {:ok, data} =
      get_consumer_data()
      |> Gateway.DB.Schemas.Consumer.create()

    conn = :get
      |> conn("consumers/#{data.external_id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    expected_resp = %{
      meta: EView.Renders.Meta.render("object", conn),
      data: data
    }

    assert 200 == conn.status
    assert Poison.encode!(expected_resp) == Gateway.Test.Helper.remove_type(conn.resp_body)
  end

  test "POST /consumers" do
    contents = get_consumer_data()

    conn = :post
      |> conn("/consumers", Poison.encode!(contents))
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    assert conn.status == 201
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["external_id"] == contents[:external_id]
    assert resp["updated_at"]
    assert resp["inserted_at"]
    assert resp["metadata"] == contents[:metadata]
  end

  test "PUT /consumers/:external_id" do
    {:ok, data} =
      get_consumer_data()
      |> Gateway.DB.Schemas.Consumer.create()

    new_contents = %{
      external_id: Helper.random_string(32),
      metadata: %{
        existing_key: "new_value",
        new_key: "another_value"
      }
    }

    conn = :put
      |> conn("/consumers/#{data.external_id}", Poison.encode!(new_contents))
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    assert conn.status == 200
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["updated_at"]
    assert new_contents[:external_id] == resp["external_id"]
    assert "another_value" == resp["metadata"]["new_key"]
    assert "new_value" == resp["metadata"]["existing_key"]
  end

  test "DELETE /consumers/:external_id" do
    {:ok, data} =
      get_consumer_data()
      |> Gateway.DB.Schemas.Consumer.create()

    conn = :delete
      |> conn("/consumers/#{data.external_id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    assert 200 == conn.status
  end
end
