defmodule Annon.ManagementAPI.Controllers.RequestTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.Factories.Requests, as: RequestsFactory

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    %{conn: conn}
  end

  describe "on index" do
    test "lists all requests in descending order", %{conn: conn} do
      assert [] ==
        conn
        |> get(requests_path())
        |> json_response(200)
        |> Map.get("data")

      request1_id = RequestsFactory.insert(:request).id
      request2_id = RequestsFactory.insert(:request).id

      resp =
        conn
        |> get(requests_path())
        |> json_response(200)
        |> Map.get("data")

      assert [%{"id" => ^request2_id}, %{"id" => ^request1_id}] = resp
    end

    test "limits results", %{conn: conn} do
      requests = RequestsFactory.insert_list(10, :request)

      pagination_query = URI.encode_query(%{
        "limit" => 2
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == Enum.at(requests, 9).id
      assert Enum.at(resp, 1)["id"] == Enum.at(requests, 8).id
      assert length(resp) == 2
    end

    test "lists all requests when limit is nil", %{conn: conn} do
      RequestsFactory.insert_list(10, :request)

      pagination_query = URI.encode_query(%{
        "limit" => nil
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert length(resp) == 10
    end

    test "lists all requests when limit is invalid", %{conn: conn} do
      RequestsFactory.insert_list(10, :request)

      pagination_query = URI.encode_query(%{
        "limit" => "not_a_number"
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert length(resp) == 10
    end

    test "filters results by idempotency key", %{conn: conn} do
      _request = RequestsFactory.insert(:request, idempotency_key: "my_idempotency_key_one")
      request2 = RequestsFactory.insert(:request, idempotency_key: "my_idempotency_key_two")

      filter_query = URI.encode_query(%{
        "idempotency_key" => "not_known_idempotency_key"
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert [] == resp

      filter_query = URI.encode_query(%{
        "idempotency_key" => "my_idempotency_key_two"
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == request2.id
      assert length(resp) == 1
    end

    test "filters results by API ID's", %{conn: conn} do
      request1 = RequestsFactory.insert(:request)
      _request = RequestsFactory.insert(:request)
      request3 = RequestsFactory.insert(:request)

      # Tolerates invalid id's
      filter_query = URI.encode_query(%{
        "api_ids" => "not_known_api_id"
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert [] == resp

      # Returns single record
      filter_query = URI.encode_query(%{
        "api_ids" => request1.api.id
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == request1.id
      assert length(resp) == 1

      # Returns multiple records
      filter_query = URI.encode_query(%{
        "api_ids" => "#{request1.api.id},#{request3.api.id},not_known_api_id"
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == request3.id
      assert Enum.at(resp, 1)["id"] == request1.id
      assert length(resp) == 2
    end

    test "filters results by status codes", %{conn: conn} do
      request1 = RequestsFactory.insert(:request, status_code: 200)
      _request = RequestsFactory.insert(:request, status_code: 201)
      request3 = RequestsFactory.insert(:request, status_code: 202)

      # Tolerates query with invalid codes
      filter_query = URI.encode_query(%{
        "status_codes" => "not_a_number"
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert length(resp) == 0

      # Returns single record
      filter_query = URI.encode_query(%{
        "status_codes" => request1.status_code
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == request1.id
      assert length(resp) == 1

      # Returns multiple records
      filter_query = URI.encode_query(%{
        "status_codes" => "#{request1.status_code},#{request3.status_code},not_a_number"
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == request3.id
      assert Enum.at(resp, 1)["id"] == request1.id
      assert length(resp) == 2
    end

    test "filters results by IP addresses", %{conn: conn} do
      request1 = RequestsFactory.insert(:request, ip_address: "127.0.1.1")
      _request = RequestsFactory.insert(:request, ip_address: "127.0.1.2")
      request3 = RequestsFactory.insert(:request, ip_address: "127.0.1.3")

      # Ignores invalid ip addresses
      filter_query = URI.encode_query(%{
        "ip_addresses" => "not_an_ip_address"
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert length(resp) == 0

      # Returns single record
      filter_query = URI.encode_query(%{
        "ip_addresses" => request1.ip_address
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == request1.id
      assert length(resp) == 1

      # Returns multiple records
      filter_query = URI.encode_query(%{
        "ip_addresses" => "#{request1.ip_address},#{request3.ip_address},indalid_address"
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == request3.id
      assert Enum.at(resp, 1)["id"] == request1.id
      assert length(resp) == 2
    end

    # TODO: https://github.com/Nebo15/ecto_paging/issues/14
    @tag :pending
    test "paginates results", %{conn: conn} do
      # Ending Before
      requests = RequestsFactory.insert_list(10, :request)

      pagination_query = URI.encode_query(%{
        "limit" => 2,
        "ending_before" => Enum.at(requests, 0).id
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == Enum.at(requests, 1).id
      assert Enum.at(resp, 1)["id"] == Enum.at(requests, 2).id
      assert length(resp) == 2

      # Without Limit
      pagination_query = URI.encode_query(%{
        "ending_before" => Enum.at(requests, 0).id
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == Enum.at(requests, 9).id
      assert Enum.at(resp, 1)["id"] == Enum.at(requests, 8).id
      assert length(resp) == 9

      # Starting After
      pagination_query = URI.encode_query(%{
        "limit" => 2,
        "starting_after" => Enum.at(requests, 9).id
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == Enum.at(requests, 8).id
      assert Enum.at(resp, 1)["id"] == Enum.at(requests, 7).id
      assert length(resp) == 2

      # Without Limit
      pagination_query = URI.encode_query(%{
        "starting_after" => Enum.at(requests, 9).id
      })

      resp =
        conn
        |> get(requests_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == Enum.at(requests, 8).id
      assert Enum.at(resp, 1)["id"] == Enum.at(requests, 7).id
      assert length(resp) == 9
    end
  end

  describe "on read" do
    test "returns 404 when request does not exist", %{conn: conn} do
      conn
      |> get(request_path(Ecto.UUID.generate()))
      |> json_response(404)
    end

    test "returns request in valid structure", %{conn: conn} do
      request = RequestsFactory.insert(:request)

      resp =
        conn
        |> get(request_path(request.id))
        |> json_response(200)
        |> Map.get("data")

      id = request.id
      idempotency_key = request.idempotency_key
      api_id = request.api.id
      api_name = request.api.name
      api_host = request.api.request.host
      inserted_at = DateTime.to_iso8601(request.inserted_at)
      updated_at = DateTime.to_iso8601(request.updated_at)

      assert %{
        "api" => %{
          "id" => ^api_id,
          "name" => ^api_name,
          "request" => %{
            "host" => ^api_host,
            "path" => "/my_api/",
            "port" => 80,
            "scheme" => "http"
          }
        },
        "id" => ^id,
        "idempotency_key" => ^idempotency_key,
        "inserted_at" => ^inserted_at,
        "ip_address" => "129.168.1.10",
        "latencies" => %{"client_request" => 102, "gateway" => 2, "upstream" => 100},
        "request" => %{
          "body" => "{}",
          "headers" => [%{"content-type" => "application/json"}],
          "method" => "GET",
          "query" => %{"key" => "value"},
          "uri" => "/my_api/"
        },
        "response" => %{
          "body" => "",
          "headers" => [%{"content-type" => "application/json"}],
          "status_code" => 200
        },
        "status_code" => 200,
        "updated_at" => ^updated_at
      } = resp
    end
  end

  describe "on delete" do
    test "returns no content when request does not exist", %{conn: conn} do
      resp =
        conn
        |> delete(request_path(Ecto.UUID.generate()))
        |> response(204)

      assert "" = resp
    end

    test "returns no content when request is deleted", %{conn: conn} do
      request = RequestsFactory.insert(:request)

      resp =
        conn
        |> delete(request_path(request.id))
        |> response(204)

      assert "" = resp

      conn
      |> get(request_path(request.id))
      |> json_response(404)
    end
  end
end
