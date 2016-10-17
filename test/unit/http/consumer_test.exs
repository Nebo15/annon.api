defmodule Gateway.HTTP.ConsumerTest do
  use Gateway.HTTPTestHelper

  test "GET /consumers" do
    data =
      [
        Gateway.DB.Models.Consumer.create(%{ external_id: "123e4567-4321-12d3-a456-426655440000", metadata: %{}}),
        Gateway.DB.Models.Consumer.create(%{ external_id: "321e4567-4321-12d3-a456-426655440000", metadata: %{}})
      ]
      |> Enum.map(fn({:ok, e}) -> e end)

    conn =
      :get
      |> conn("/consumers")
      |> put_req_header("content-type", "application/json")
      |> Gateway.Router.call([])

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
      Gateway.DB.Models.Consumer.create(%{ external_id: "123e4567-4321-12d3-a456-426655440000", metadata: %{}})

    conn =
      :get
      |> conn("/consumers/#{data.external_id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.Router.call([])

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
    contents = %{
      external_id: "321e4567-4321-12d3-a456-426655440000",
      metadata: %{
        existing_key: "some_value"
      }
    }

    conn =
      :post
      |> conn("/consumers", Poison.encode!(contents))
      |> put_req_header("content-type", "application/json")
      |> Gateway.Router.call([])

    expected_resp = %{
      meta: %{
        code: 201,
      },
      data: contents
    }

    assert conn.status == 201
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["external_id"]
    assert resp["updated_at"]
    assert resp["inserted_at"]
    assert resp["metadata"]["existing_key"] == "some_value"
  end

  test "PUT /consumers/:external_id" do
    external_id = "123e4567-e89b-12d3-a456-426655440000"

    { :ok, data } =
      Gateway.DB.Models.Consumer.create(%{ external_id: external_id, metadata: %{ existing_key: "some_value" }})

    new_contents = %{
      external_id: "123e4567-4321-12d3-a456-426655440000",
      metadata: %{
        existing_key: "new_value",
        new_key: "another_value"
      }
    }

    conn =
      :put
      |> conn("/consumers/#{data.external_id}", Poison.encode!(new_contents))
      |> put_req_header("content-type", "application/json")
      |> Gateway.Router.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: new_contents
    }

    assert conn.status == 200
    resp = Poison.decode!(conn.resp_body)["data"]

    assert resp["updated_at"]
    assert resp["external_id"] == "123e4567-4321-12d3-a456-426655440000"
    assert resp["metadata"]["new_key"] == "another_value"
    assert resp["metadata"]["existing_key"] == "new_value"
  end

  test "DELETE /consumers/:external_id" do
    { :ok, data } =
      Gateway.DB.Models.Consumer.create(%{ external_id: "321e4567-4321-12d3-a456-426655440000", metadata: %{}})

    conn =
      :delete
      |> conn("/consumers/#{data.external_id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.Router.call([])

    resp = Poison.decode!(conn.resp_body)

    assert conn.status == 200
    assert resp["data"]["external_id"] == data.external_id
    assert resp["meta"]["description"] == "Resource was deleted"
  end
end
