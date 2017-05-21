defmodule Annon.Acceptance.Plugins.IdempotencyTest do
  @moduledoc false
  use Annon.AcceptanceCase, async: true

  @idempotency_key Ecto.UUID.generate()

  setup do
    api_path = "/my_idempotent_api-" <> Ecto.UUID.generate() <> "/"
    api = :api
    |> build_factory_params(%{
      request: %{
        methods: ["GET", "POST", "PUT", "DELETE"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: api_path
      }
    })
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    api_id
    |> create_proxy_to_mock()

    idempotency_plugin = :idempotency_plugin
    |> build_factory_params()

    "apis/#{api_id}/plugins/idempotency"
    |> put_management_url()
    |> put!(idempotency_plugin)
    |> assert_status(201)

    %{api_id: api_id, api_path: api_path, api: api}
  end

  test "test idempotency POST request", %{api_path: api_path} do
    req1_id = api_path
    |> put_public_url()
    |> post!(%{foo: "bar"}, [{"x-idempotency-key", @idempotency_key}])
    |> get_body()
    |> get_mock_response()
    |> get_request_id

    req2_id = api_path
    |> put_public_url()
    |> post!(%{foo: "bar"}, [{"x-idempotency-key", @idempotency_key}])
    |> get_body()
    |> get_mock_response()
    |> get_request_id

    req3_id = api_path
    |> put_public_url()
    |> post!(%{foo: "bar"}, [{"x-idempotency-key", @idempotency_key}])
    |> get_body()
    |> get_mock_response()
    |> get_request_id

    req4_id = api_path
    |> put_public_url()
    |> post!(%{foo: "bar"}, [{"x-idempotency-key", "some_other_idempotency_key"}])
    |> get_body()
    |> get_mock_response()
    |> get_request_id

    assert req3_id == req2_id
    assert req2_id == req1_id
    assert req4_id != req1_id
  end

  test "test idempotency validates request equality", %{api_path: api_path} do
    api_path
    |> put_public_url()
    |> post!(%{foo: "bar"}, [{"x-idempotency-key", @idempotency_key}])
    |> get_body()
    |> get_mock_response()
    |> get_request_id

    assert %{
      "error" => %{"message" => "You sent duplicate idempotency key but request params was different."}
    } = api_path
    |> put_public_url()
    |> post!(%{foo: "baz"}, [{"x-idempotency-key", @idempotency_key}])
    |> assert_status(409)
    |> get_body()
  end

  defp get_request_id(%{"response" => %{"headers" => headers}}) do
    headers
    |> Enum.find_value(fn
      %{"x-request-id" => request_id} -> request_id
      _ -> false
    end)
  end
end
