defmodule Gateway.Acceptance.Plug.IdempotencyTest do
  use Gateway.AcceptanceCase

  @idempotency_key random_string(32)

  test "test idempotency POST request" do

    api_data = "POST"
    |> api_idempotency_data("/idempotency", true)

    http_api_create(api_data)
    api_data = Poison.encode!(api_data)

    "idempotency"
    |> post(api_data, :public, [{"x-idempotency-key", @idempotency_key}])
    |> assert_status(201)

    "idempotency"
    |> post(api_data, :public, [{"x-idempotency-key", @idempotency_key}])
    |> assert_status(201)

    "idempotency"
    |> post(api_data, :public, [{"x-idempotency-key", @idempotency_key}])
    |> assert_status(201)

    "idempotency"
    |> post(~s({"name": "start"}), :public, [{"x-idempotency-key", @idempotency_key}])
    |> assert_status(409)

    %HTTPoison.Response{body: body} = "apis"
    |> get(:private)
    |> assert_status(200)

    assert 2 == body
    |> Poison.decode!()
    |> Map.fetch("data")
    |> elem(1)
    |> Enum.count()
  end

  def api_idempotency_data(method, path, with_proxy \\ false) do
    get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: path, port: get_port(:public), scheme: "http", method: method})
    |> Map.put(:plugins, get_plugins(with_proxy))
  end

  def get_plugins(_with_proxy = false) do
    [%{name: "Idempotency", is_enabled: true, settings: %{"key" => 100}}]
  end

  def get_plugins(_with_proxy = true) do
    [%{name: "Idempotency", is_enabled: true, settings: %{"key" => 100}},
     %{name: "Proxy", is_enabled: true, settings: %{
        "proxy_to" => Poison.encode!(%{
          host: get_host(:private),
          path: "/apis",
          port: get_port(:private),
          scheme: "http"
        })
     }}
    ]
  end
end
