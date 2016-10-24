defmodule Gateway.Acceptance.Plug.IdempotencyTest do
  use Gateway.AcceptanceCase

  @idempotency_key UUID.uuid1()

  test "test idempotency DELETE request" do
    "DELETE"
    |> api_idempotency_data("/idempotency")
    |> http_api_create()

    "idempotency"
    |> delete(:public, [{"x-idempotency-key", @idempotency_key}])
    |> assert_status(200)
  end

  def api_idempotency_data(method, path) do
    get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: path, port: get_port(:public), scheme: "http", method: method})
    |> Map.put(:plugins, [
      %{name: "Idempotency", is_enabled: true, settings: %{"key" => 100}},
    ])
  end
end
