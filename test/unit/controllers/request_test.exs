defmodule Gateway.Controllers.RequestTest do
  @moduledoc false
  use Gateway.UnitCase, async: true


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

  describe "/requests (pagination)" do
    setup do
      logs = for _ <- 1..10 do
        attributes = %{id: Ecto.UUID.generate(), response: %{}, status_code: 200}

        %Gateway.DB.Schemas.Log{}
        |> Gateway.DB.Schemas.Log.changeset(attributes)
        |> Gateway.DB.Logger.Repo.insert!()
      end

      {:ok, %{logs: logs}}
    end

    test "GET /requests?starting_after=2&limit=5", %{logs: logs} do
      id = Enum.at(logs, 2).id

      conn = "/requests?starting_after=#{id}&limit=5"
      |> call_get()
      |> assert_conn_status()

      expected_records =
        logs
        |> Enum.slice(3, 5)
        |> Enum.map(&Map.get(&1, :id))

      actual_records =
        Poison.decode!(conn.resp_body)["data"]
        |> Enum.map(&Map.get(&1, "id"))

      assert expected_records == actual_records
    end

    test "GET /requests?ending_before=7&limit=4", %{logs: logs} do
      id = Enum.at(logs, 7).id

      conn = "/requests?ending_before=#{id}&limit=4"
      |> call_get()
      |> assert_conn_status()

      expected_records =
        logs
        |> Enum.slice(3, 4)
        |> Enum.map(&Map.get(&1, :id))

      actual_records =
        Poison.decode!(conn.resp_body)["data"]
        |> Enum.map(&Map.get(&1, "id"))

      assert expected_records == actual_records
    end

    test "GET /requests?ending_before=3&limit=5", %{logs: logs} do
      id = Enum.at(logs, 3).id

      conn = "/requests?ending_before=#{id}&limit=4"
      |> call_get()
      |> assert_conn_status()

      expected_records =
        logs
        |> Enum.slice(0, 3)
        |> Enum.map(&Map.get(&1, :id))

      actual_records =
        Poison.decode!(conn.resp_body)["data"]
        |> Enum.map(&Map.get(&1, "id"))

      assert expected_records == actual_records
    end
  end

  describe "/requests" do
    test "GET empty list" do
      conn = "/requests"
      |> call_get()
      |> assert_conn_status()

      assert 0 == conn.resp_body
      |> Poison.decode!()
      |> Map.fetch!("data")
      |> length()
    end

    test "GET" do
      create_requests(3)

      conn = "/requests"
      |> call_get()
      |> assert_conn_status()

      assert 3 == conn.resp_body
      |> Poison.decode!()
      |> Map.fetch!("data")
      |> length()
    end
  end

  describe "/requests/:request_id" do
    test "GET 404" do
      "/requests/not_exists"
      |> call_get()
      |> assert_conn_status(404)
    end

    test "GET" do
      id = create_request()
      |> get_resp_header("x-request-id")
      |> Enum.at(0) || ""

      conn = "/requests/#{id}"
      |> call_get()
      |> assert_conn_status()

      assert %{"data" => %{"id" => ^id}} = Poison.decode!(conn.resp_body)
    end

    test "DELETE" do
      id = create_request()
      |> get_resp_header("x-request-id")
      |> Enum.at(0) || ""

      "/requests/#{id}"
      |> call_delete()
      |> assert_conn_status()
      |> assert_response_body(%{})

      "/requests/#{id}"
      |> call_get()
      |> assert_conn_status(404)
    end
  end
end
