defmodule Gateway.Controllers.ConsumerTest do
  @moduledoc false
  use Gateway.ControllerUnitCase,
    controller: Gateway.Controllers.Consumer

  describe "/consumers" do
    test "GET" do
      consumer_data = Gateway.Factory.insert_pair(:consumer)

      conn = "/"
      |> send_get()
      |> assert_conn_status()

      expected_resp = EView.wrap_body(consumer_data, conn)
      assert Poison.encode!(expected_resp) == conn.resp_body
    end

    test "POST /consumers" do
      consumer_data = Gateway.Factory.build(:consumer)
      external_id = consumer_data.external_id
      metadata = consumer_data.metadata

      conn = "/"
      |> send_post(consumer_data)
      |> assert_conn_status(201)

      assert %{
        "external_id" => ^external_id,
        "metadata" => ^metadata,
        "updated_at" => _,
        "inserted_at" => _
      } = Poison.decode!(conn.resp_body)["data"]
    end
  end

  describe "/consumers/:external_id" do
    test "GET 404" do
      "not_exist"
      |> send_get()
      |> assert_conn_status(404)
    end

    test "GET" do
      consumer = Gateway.Factory.insert(:consumer)

      consumer.external_id
      |> send_get()
      |> assert_conn_status()
      |> assert_response_body(consumer)
    end

    test "PUT" do
      consumer = Gateway.Factory.insert(:consumer)
      consumer_update = Gateway.Factory.build(:consumer, %{metadata: %{foo: "bar"}})

      conn = consumer.external_id
      |> send_put(consumer_update)
      |> assert_conn_status()

      assert %{
        "inserted_at" => _,
        "updated_at" => _,
        "external_id" => external_id,
        "metadata" => %{"foo" => "bar"}
      } = Poison.decode!(conn.resp_body)["data"]

      assert external_id == consumer_update.external_id
    end

    test "DELETE" do
      consumer = Gateway.Factory.insert(:consumer)

      consumer.external_id
      |> send_delete()
      |> assert_conn_status()

      consumer.external_id
      |> send_get()
      |> assert_conn_status(404)
    end
  end
end
