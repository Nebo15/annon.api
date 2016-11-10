defmodule Gateway.Acceptance.Plug.IdempotencyTest do
  use Gateway.AcceptanceCase
  alias Gateway.Test.Helper

  @idempotency_key Helper.random_string(32)

  test "test idempotency POST request" do

    api_data = "POST"
    |> api_idempotency_data("/idempotency")

    http_api_create(api_data)

    api_data = api_data
    |> put_in([:request, :port], 3001)
    |> Map.put("name", "idempotency test api")
    |> Poison.encode!()

    Gateway.AutoClustering.do_reload_config

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
    |> Map.fetch!("data")
    |> Enum.count()
  end

  def api_idempotency_data(method, path) do
    get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: path, port: get_port(:public), scheme: "http", method: [method]})
    |> Map.put(:plugins, get_plugins())
  end

  def get_plugins do
    [%{name: "idempotency", is_enabled: true, settings: %{"key" => 100}},
     %{name: "proxy", is_enabled: true, settings: %{
        host: get_host(:private),
        path: "/apis",
        port: get_port(:private),
        scheme: "http"
     }}
    ]
  end
end
