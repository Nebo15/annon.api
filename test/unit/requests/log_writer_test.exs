defmodule Annon.Requests.LogWriterTest do
  use Annon.DataCase, async: true
  alias Annon.Requests.LogWriter
  alias Annon.Requests.Request

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

      assert {:ok, %Request{} = request} = LogWriter.create_request(create_attrs)

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
      assert {:error, %Ecto.Changeset{}} = LogWriter.create_request(%{})
    end
  end

  describe "create_request_async/1" do
    setup do
      LogWriter.subscribe(self())
      low_writer_pid = Process.whereis(Annon.Requests.LogWriter)
      Ecto.Adapters.SQL.Sandbox.allow(Annon.Requests.Repo, self(), low_writer_pid)
      on_exit fn ->
        LogWriter.unsubscribe(self())
      end
      :ok
    end

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

      assert :ok = LogWriter.create_request_async(create_attrs)
      assert_receive {:ok, %Request{} = request}

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
      assert {:error, %Ecto.Changeset{}} = LogWriter.create_request_async(%{})
    end
  end
end
