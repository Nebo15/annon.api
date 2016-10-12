defmodule Gateway.HTTP.ConsumerTest do
  use Gateway.HTTPTestHelper

  test "GET /consumers" do
    data =
      [
        Gateway.DB.Consumer.create(%{ external_id: "SampleID1", metadata: %{}}),
        Gateway.DB.Consumer.create(%{ external_id: "SampleID2", metadata: %{}})
      ]
      |> Enum.map(fn({:ok, e}) -> e end)

    conn =
      conn(:get, "/")
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.Consumer.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: data
    }

    assert conn.status == 200
    assert conn.resp_body == Poison.encode!(expected_resp)
  end

  test "GET /consumers/:consumer_id" do
    { :ok, data } =
      Gateway.DB.Consumer.create(%{ external_id: "SampleID1", metadata: %{}})

    conn =
      conn(:get, "/#{data.id}")
      |> put_req_header("content-type", "application/json")
      |> Gateway.HTTP.Consumer.call([])

    expected_resp = %{
      meta: %{
        code: 200,
      },
      data: data
    }

    assert conn.status == 200
    assert conn.resp_body == Poison.encode!(expected_resp)
  end
end
