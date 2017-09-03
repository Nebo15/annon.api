defmodule Annon.Requests.LogTest do
  @moduledoc false
  use Annon.DataCase, async: true
  alias Annon.Requests.Log
  alias Annon.Requests.Request
  alias Annon.Factories.Requests, as: RequestsFactory
  alias Ecto.Paging
  alias Ecto.Paging.Cursors

  describe "list_requests/1" do
    test "returns all requests" do
      assert {[], _paging} = Log.list_requests()
      assert {[], _paging} = Log.list_requests(%{})
      request = RequestsFactory.insert(:request)
      assert {[^request], _paging} = Log.list_requests()
    end

    test "filters by idempotency key" do
      request1 = RequestsFactory.insert(:request, idempotency_key: "my_idempotency_key_one")
      request2 = RequestsFactory.insert(:request, idempotency_key: "my_idempotency_key_two")

      assert {[^request2, ^request1], _paging} = Log.list_requests(%{"idempotency_key" => nil})
      assert {[], _paging} = Log.list_requests(%{"idempotency_key" => "unknown idempotency_key"})
      assert {[^request1], _paging} = Log.list_requests(%{"idempotency_key" => "my_idempotency_key_one"})
      assert {[^request2], _paging} = Log.list_requests(%{"idempotency_key" => "my_idempotency_key_two"})
    end

    test "filters by API IDs" do
      request1 = RequestsFactory.insert(:request, api: RequestsFactory.build(:api, id: "my_api_1"))
      request2 = RequestsFactory.insert(:request, api: RequestsFactory.build(:api, id: "my_api_2"))
      request3 = RequestsFactory.insert(:request, api: RequestsFactory.build(:api, id: "my_api_3"))

      assert {[^request3, ^request2, ^request1], _paging} = Log.list_requests(%{"api_ids" => nil})
      assert {[], _paging} = Log.list_requests(%{"api_ids" => "unknown_api_id"})
      assert {[^request2], _paging} = Log.list_requests(%{"api_ids" => "my_api_2"})
      assert {[^request3, ^request2], _paging} = Log.list_requests(%{"api_ids" => "my_api_2,my_api_3"})
    end

    test "filters by status codes" do
      request1 = RequestsFactory.insert(:request, status_code: 200)
      request2 = RequestsFactory.insert(:request, status_code: 201)
      request3 = RequestsFactory.insert(:request, status_code: 202)

      assert {[^request3, ^request2, ^request1], _paging} = Log.list_requests(%{"status_codes" => nil})
      assert {[], _paging} = Log.list_requests(%{"status_codes" => "404"})
      assert {[^request2], _paging} = Log.list_requests(%{"status_codes" => "201"})
      assert {[^request3, ^request2], _paging} = Log.list_requests(%{"status_codes" => "201,202"})
    end

    test "filters by IP addresses" do
      request1 = RequestsFactory.insert(:request, ip_address: "127.0.0.1")
      request2 = RequestsFactory.insert(:request, ip_address: "127.0.0.2")
      request3 = RequestsFactory.insert(:request, ip_address: "127.0.0.3")

      assert {[^request3, ^request2, ^request1], _paging} = Log.list_requests(%{"ip_addresses" => nil})
      assert {[], _paging} = Log.list_requests(%{"ip_addresses" => "127.0.0.255"})
      assert {[^request2], _paging} = Log.list_requests(%{"ip_addresses" => "127.0.0.2"})
      assert {[^request3, ^request2], _paging} = Log.list_requests(%{"ip_addresses" => "127.0.0.2,127.0.0.3"})
    end

    test "paginates results" do
      request1_id = RequestsFactory.insert(:request, id: "1").id
      request2_id = RequestsFactory.insert(:request, id: "2").id
      request3_id = RequestsFactory.insert(:request, id: "3").id
      request4_id = RequestsFactory.insert(:request, id: "4").id
      request5_id = RequestsFactory.insert(:request, id: "5").id

      {first_page, _paging} = Log.list_requests(%{}, %Paging{limit: nil})
      assert [^request5_id, ^request4_id, ^request3_id, ^request2_id, ^request1_id] = Enum.map(first_page, &(&1.id))

      {page, _paging} = Log.list_requests(%{}, %Paging{limit: 1})
      assert [^request5_id] = Enum.map(page, &(&1.id))

      {page, _paging} = Log.list_requests(%{}, %Paging{limit: 2})
      assert [^request5_id, ^request4_id] = Enum.map(page, &(&1.id))

      {page, _paging} = Log.list_requests(%{}, %Paging{limit: 2, cursors: %Cursors{starting_after: request4_id}})
      assert [^request3_id, ^request2_id] = Enum.map(page, &(&1.id))

      {page, _paging} = Log.list_requests(%{}, %Paging{limit: 2, cursors: %Cursors{ending_before: request1_id}})
      assert [^request3_id, ^request2_id] = Enum.map(page, &(&1.id))
    end

    test "paginates with filters" do
      request1_id = RequestsFactory.insert(:request,
        api: RequestsFactory.build(:api, id: "my_api_1"), status_code: 202).id
      RequestsFactory.insert(:request,
        api: RequestsFactory.build(:api, id: "my_api_1"), status_code: 201)
      request3_id =
        RequestsFactory.insert(:request,
          api: RequestsFactory.build(:api, id: "my_api_1"), status_code: 202).id
      request4_id =
        RequestsFactory.insert(:request,
          api: RequestsFactory.build(:api, id: "my_api_1"), ip_address: "127.0.0.1").id
      request5_id =
        RequestsFactory.insert(:request,
          api: RequestsFactory.build(:api, id: "my_api_1"), idempotency_key: "my_idempotency_key_one").id

      {page, _paging} =
        Log.list_requests(
          %{"api_ids" => "my_api_1"},
          %Paging{limit: 2, cursors: %Cursors{ending_before: request3_id}}
        )
      assert [^request5_id, ^request4_id] = Enum.map(page, &(&1.id))

      {page, _paging} =
        Log.list_requests(
          %{"idempotency_key" => "my_idempotency_key_one"},
          %Paging{limit: 2, cursors: %Cursors{ending_before: request1_id}}
        )
      assert [^request5_id] = Enum.map(page, &(&1.id))

      {page, _paging} =
        Log.list_requests(
          %{"status_codes" => "202"},
          %Paging{limit: 1, cursors: %Cursors{ending_before: request1_id}}
        )
      assert [^request3_id] = Enum.map(page, &(&1.id))
    end
  end

  describe "get_request/1" do
    test "returns the request with given id" do
      request = RequestsFactory.insert(:request)
      assert {:ok, %Request{} = ^request} = Log.get_request(request.id)
    end

    test "with invalid request id returns error" do
      assert {:error, :not_found} = Log.get_request(Ecto.UUID.generate())
    end
  end

  describe "create_request/1" do
    test "with valid data creates a request" do
      create_attrs = %{
        id: "6f40ea08-00f9-4912-9472-4cd789facfa1",
        idempotency_key: "cc9b19a8-4e6d-4237-9bb0-1137ab0d9f82",
        ip_address: "129.168.1.10",
        status_code: 200,
        api: %{
          id: "01",
          name: "An API #01",
          request: %{
            host: "www.example01.com",
            path: "/my_api/",
            port: 80,
            scheme: "http"
          }
        },
        latencies: %{
          client_request: 102,
          gateway: 2,
          upstream: 100
        },
        request: %{
          body: "{}",
          headers: %{"content-type" => "application/json"},
          method: "GET",
          query: %{"key" => "value"},
          uri: "/my_api/"
        },
        response: %{
          body: "{}",
          headers: %{"content-type" => "application/json"},
          status_code: 200
        }
      }

      assert {:ok, %Request{} = request} = Log.create_request(create_attrs)

      assert request.api.id == create_attrs.api.id
      assert request.latencies.client_request == create_attrs.latencies.client_request
      assert request.request.body == create_attrs.request.body
      assert request.response.body == create_attrs.response.body
      assert request.id == create_attrs.id
      assert request.idempotency_key == create_attrs.idempotency_key
      assert request.ip_address == create_attrs.ip_address
      assert request.status_code == create_attrs.status_code
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Log.create_request(%{})
    end
  end

  describe "insert_request/1" do
    test "with valid changeset creates a request" do
      create_attrs = %{
        id: "6f40ea08-00f9-4912-9472-4cd789facfa1",
        idempotency_key: "cc9b19a8-4e6d-4237-9bb0-1137ab0d9f82",
        ip_address: "129.168.1.10",
        status_code: 200,
        api: %{
          id: "01",
          name: "An API #01",
          request: %{
            host: "www.example01.com",
            path: "/my_api/",
            port: 80,
            scheme: "http"
          }
        },
        latencies: %{
          client_request: 102,
          gateway: 2,
          upstream: 100
        },
        request: %{
          body: "{}",
          headers: %{"content-type" => "application/json"},
          method: "GET",
          query: %{"key" => "value"},
          uri: "/my_api/"
        },
        response: %{
          body: "{}",
          headers: %{"content-type" => "application/json"},
          status_code: 200
        }
      }
      create_changeset = Log.change_request(create_attrs)

      assert {:ok, %Request{} = request} = Log.insert_request(create_changeset)

      assert request.api.id == create_attrs.api.id
      assert request.latencies.client_request == create_attrs.latencies.client_request
      assert request.request.body == create_attrs.request.body
      assert request.response.body == create_attrs.response.body
      assert request.id == create_attrs.id
      assert request.idempotency_key == create_attrs.idempotency_key
      assert request.ip_address == create_attrs.ip_address
      assert request.status_code == create_attrs.status_code
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Log.create_request(%{})
    end
  end

  test "delete_request/1 deletes the request" do
    request = RequestsFactory.insert(:request)
    assert {:ok, %Request{}} = Log.delete_request(request)
    assert {:error, :not_found} = Log.get_request(request.id)
  end
end
