defmodule Gateway.HTTP.ConsumerTest do
  use Gateway.UnitCase

  test "GET /consumers" do
    data =
      [
        get_consumer_data() |> Gateway.DB.Models.Consumer.create(),
        get_consumer_data() |> Gateway.DB.Models.Consumer.create()
      ]
      |> Enum.map(fn({:ok, e}) -> e end)

    conn = :get
      |> conn("/consumers")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: data
    }

    assert conn.status == 200
    assert conn.resp_body == Poison.encode!(expected_resp)
  end

  test "GET /consumers/:external_id" do
    { :ok, data } =
      get_consumer_data()
      |> Gateway.DB.Models.Consumer.create()

    conn = :get
      |> conn("/consumers/#{data.external_id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: data
    }

    assert conn.status == 200
    assert conn.resp_body == Poison.encode!(expected_resp)
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
    { :ok, data } =
      get_consumer_data()
      |> Gateway.DB.Models.Consumer.create()

    new_contents = %{
      external_id: random_string(32),
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
    assert resp["external_id"] == new_contents[:external_id]
    assert resp["metadata"]["new_key"] == "another_value"
    assert resp["metadata"]["existing_key"] == "new_value"
  end

  test "DELETE /consumers/:external_id" do
    { :ok, data } =
      get_consumer_data()
      |> Gateway.DB.Models.Consumer.create()

    conn = :delete
      |> conn("/consumers/#{data.external_id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.PrivateRouter.call([])

    resp = Poison.decode!(conn.resp_body)

    assert 200 == conn.status
    assert "Resource was deleted" == resp["meta"]["description"]
  end
end
